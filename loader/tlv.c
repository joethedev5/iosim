/* Mach-O thread-local variable support.
 *
 * A TLV thunk in __DATA,__thread_vars is three pointers: a getter function,
 * a slot the runtime owns, and the variable's offset into the image's initial
 * content (the concatenation of __thread_data and __thread_bss). dyld normally
 * rewrites the thunk and lazily allocates one block per thread per image; this
 * loader does the same, keeping the per-image metadata on the host side.
 *
 * The getter is called with the Darwin "preserve all registers except rax"
 * convention, so it is compiled with no_caller_saved_registers.
 */
#define _GNU_SOURCE
#include "context.h"

#include <pthread.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

struct tlv_meta {
    uintptr_t       thunk;
    pthread_key_t   key;
    size_t          offset;
    size_t          size;
    const uint8_t  *initial;
};

static struct tlv_meta *tlv_metas;
static size_t tlv_count;
static size_t tlv_cap;

static int add_meta(const struct tlv_meta *meta)
{
    if (tlv_count == tlv_cap)
    {
        size_t cap = tlv_cap ? tlv_cap * 2 : 16;
        struct tlv_meta *n = realloc(tlv_metas, cap * sizeof(*n));
        if (!n)
            return -1;
        tlv_metas = n;
        tlv_cap = cap;
    }
    tlv_metas[tlv_count++] = *meta;
    return 0;
}

static struct tlv_meta *find_meta(uintptr_t thunk)
{
    for (size_t i = 0; i < tlv_count; i++)
        if (tlv_metas[i].thunk == thunk)
            return &tlv_metas[i];
    return NULL;
}

void *iosim_tlv_get_addr(void *thunk);

/* The register-preserving entry point is in tlv.S; this is its ordinary C
 * body, where the compiler may freely use SSE and call libc. */
void *iosim_tlv_get_addr_slow(void *thunk)
{
    struct tlv_meta *meta = find_meta((uintptr_t)thunk);
    if (!meta)
        return NULL;

    void *base = pthread_getspecific(meta->key);
    if (!base)
    {
        size_t size = meta->size ? meta->size : 1;
        base = calloc(1, size);
        if (!base)
            return NULL;
        if (meta->initial && meta->size)
            memcpy(base, meta->initial, meta->size);
        pthread_setspecific(meta->key, base);
    }
    return (uint8_t *)base + meta->offset;
}

/* Fallback if a thunk is called before setup ran; setup rewrites every thunk
 * to iosim_tlv_get_addr, so this only matters for malformed images. */
void *iosim_tlv_bootstrap(void *thunk)
{
    return iosim_tlv_get_addr(thunk);
}
void iosim_tlv_setup_image(struct iosim_image *img)
{
    int thunk_sections = 0;
    for (int s = 0; s < img->nsects; s++)
        if (strcmp(img->sects[s].sectname, "__thread_vars") == 0)
            thunk_sections++;
    if (!thunk_sections)
        return;

    /* Concatenate the initial content in load-command order: regular thread
     * data first, then zero-fill. Thunk offsets index this combined block. */
    size_t total = 0;
    for (int s = 0; s < img->nsects; s++)
    {
        struct iosim_section *sec = &img->sects[s];
        if (strcmp(sec->sectname, "__thread_data") == 0 ||
            strcmp(sec->sectname, "__thread_bss") == 0)
            total += (size_t)sec->size;
    }
    uint8_t *initial = calloc(1, total ? total : 1);
    if (!initial)
        return;
    size_t cursor = 0;
    for (int s = 0; s < img->nsects; s++)
    {
        struct iosim_section *sec = &img->sects[s];
        if (strcmp(sec->sectname, "__thread_data") == 0)
        {
            if ((uint64_t)sec->offset + sec->size <= img->file_len)
                memcpy(initial + cursor, img->file + sec->offset,
                       (size_t)sec->size);
            cursor += (size_t)sec->size;
        }
        else if (strcmp(sec->sectname, "__thread_bss") == 0)
        {
            cursor += (size_t)sec->size;
        }
    }

    /* One pthread key per image, exactly like dyld: all TLVs of the image
     * share one lazily allocated per-thread block of initial content. */
    pthread_key_t key;
    if (pthread_key_create(&key, free) != 0)
    {
        free(initial);
        return;
    }

    for (int s = 0; s < img->nsects; s++)
    {
        struct iosim_section *sec = &img->sects[s];
        if (strcmp(sec->sectname, "__thread_vars") != 0)
            continue;
        if ((uint64_t)sec->offset + sec->size > img->file_len)
            continue;
        uint8_t *file_bytes = img->file + sec->offset;
        size_t thunks = (size_t)sec->size / 24;
        for (size_t i = 0; i < thunks; i++)
        {
            uint8_t *disk = file_bytes + i * 24;
            uint8_t *runtime = (uint8_t *)(uintptr_t)
                (sec->addr + img->slide + i * 24);
            uint64_t offset;
            memcpy(&offset, disk + 16, sizeof(offset));
            if (offset > total)
                offset = 0;

            struct tlv_meta meta = {
                .thunk = (uintptr_t)runtime,
                .key = key,
                .offset = (size_t)offset,
                .size = total,
                .initial = initial,
            };
            if (add_meta(&meta) != 0)
                continue;
            void *getter = (void *)(uintptr_t)&iosim_tlv_get_addr;
            /* An arm64 image's thunk was bound to the native tlv_bootstrap
             * gate by the chained fixups. Calling it through the arm64
             * bridge already preserves every guest register except x0, so
             * the x86_64 register-preserving stub is not installed there. */
            if (!img->is_arm64)
                memcpy(runtime, &getter, sizeof(getter));
            if (getenv("IOSIM_DEBUG_TLV"))
                fprintf(stderr, "iosim: tlv %s thunk=%p offset=%zu size=%zu\n",
                        img->path, runtime, meta.offset, meta.size);
        }
    }
}
