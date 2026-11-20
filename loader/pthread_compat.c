/* Darwin pthread static-initializer normalization.
 *
 * Darwin pthread objects are opaque, 64-bit-aligned structures whose static
 * initializers embed a signature word (for example PTHREAD_MUTEX_INITIALIZER
 * starts with 0x32AAABA7). glibc instead expects its own zero-initialized
 * layout and treats a Darwin-initialized mutex as already locked, which
 * deadlocks host libc++ the first time a guest's static std::mutex is used.
 *
 * At load time we scan writable data sections for those exact initializer
 * patterns (signature followed by zeroed opaque bytes) and re-initialize the
 * objects in place with the host pthread library. The guest treats the objects
 * as opaque, so the host layout fits inside the Darwin allocation.
 */
#define _GNU_SOURCE
#include "context.h"

#include <pthread.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define DARWIN_MUTEX_SIG        0x32AAABA7UL
#define DARWIN_ERRORCHECK_SIG   0x32AAABA1UL
#define DARWIN_RECURSIVE_SIG    0x32AAABA2UL
#define DARWIN_FIRSTFIT_SIG     0x32AAABA3UL
#define DARWIN_COND_SIG         0x3CB0B1BBUL
#define DARWIN_ONCE_SIG         0x30B1BCBAUL
#define DARWIN_RWLOCK_SIG       0x2DA8B3B4UL

#define DARWIN_MUTEX_BYTES   64
#define DARWIN_COND_BYTES    48
#define DARWIN_ONCE_BYTES    16
#define DARWIN_RWLOCK_BYTES  200

static int bytes_zero(const uint8_t *p, size_t n)
{
    for (size_t i = 0; i < n; i++)
        if (p[i])
            return 0;
    return 1;
}

static int segment_is_writable(struct iosim_image *img, const char *name)
{
    for (int i = 0; i < img->nsegs; i++)
    {
        struct iosim_segment *seg = &img->segs[i];
        if (strcmp(seg->name, name) != 0)
            continue;
        return (seg->initprot & 2) != 0 || (seg->maxprot & 2) != 0;
    }
    return 0;
}

static void init_mutex(void *addr, int recursive)
{
    pthread_mutexattr_t attr;
    pthread_mutexattr_init(&attr);
    if (recursive)
        pthread_mutexattr_settype(&attr, PTHREAD_MUTEX_RECURSIVE);
    pthread_mutex_init((pthread_mutex_t *)addr, &attr);
    pthread_mutexattr_destroy(&attr);
}

void iosim_normalize_pthread_objects(struct iosim_context *ctx)
{
    int debug = getenv("IOSIM_DEBUG_PTHREAD") != NULL;
    int normalized = 0;

    for (int i = 0; i < ctx->nimages; i++)
    {
        struct iosim_image *img = ctx->images[i];
        for (int s = 0; s < img->nsects; s++)
        {
            struct iosim_section *sec = &img->sects[s];
            if (!segment_is_writable(img, sec->segname))
                continue;
            if (!sec->size || !sec->offset)
                continue;
            if ((uint64_t)sec->offset + sec->size > img->file_len)
                continue;
            uint8_t *bytes = img->file + sec->offset;
            uint64_t addr_base = sec->addr + img->slide;

            for (uint64_t off = 0; off + 8 <= sec->size; off += 8)
            {
                uint64_t word;
                memcpy(&word, bytes + off, sizeof(word));
                uint8_t *runtime = (uint8_t *)(uintptr_t)(addr_base + off);
                if ((word == DARWIN_MUTEX_SIG ||
                     word == DARWIN_FIRSTFIT_SIG) &&
                    off + DARWIN_MUTEX_BYTES <= sec->size &&
                    bytes_zero(bytes + off + 8, DARWIN_MUTEX_BYTES - 8))
                {
                    init_mutex(runtime, 0);
                    normalized++;
                    if (debug)
                        fprintf(stderr, "iosim: normalized mutex at %p\n",
                                runtime);
                }
                else if (word == DARWIN_RECURSIVE_SIG &&
                         off + DARWIN_MUTEX_BYTES <= sec->size &&
                         bytes_zero(bytes + off + 8,
                                    DARWIN_MUTEX_BYTES - 8))
                {
                    init_mutex(runtime, 1);
                    normalized++;
                    if (debug)
                        fprintf(stderr,
                                "iosim: normalized recursive mutex at %p\n",
                                runtime);
                }
                else if (word == DARWIN_ERRORCHECK_SIG &&
                         off + DARWIN_MUTEX_BYTES <= sec->size &&
                         bytes_zero(bytes + off + 8,
                                    DARWIN_MUTEX_BYTES - 8))
                {
                    pthread_mutexattr_t attr;
                    pthread_mutexattr_init(&attr);
                    pthread_mutexattr_settype(&attr,
                                              PTHREAD_MUTEX_ERRORCHECK);
                    pthread_mutex_init((pthread_mutex_t *)runtime, &attr);
                    pthread_mutexattr_destroy(&attr);
                    normalized++;
                }
                else if (word == DARWIN_COND_SIG &&
                         off + DARWIN_COND_BYTES <= sec->size &&
                         bytes_zero(bytes + off + 8, DARWIN_COND_BYTES - 8))
                {
                    pthread_cond_init((pthread_cond_t *)runtime, NULL);
                    normalized++;
                    if (debug)
                        fprintf(stderr, "iosim: normalized cond at %p\n",
                                runtime);
                }
                else if (word == DARWIN_ONCE_SIG &&
                         off + DARWIN_ONCE_BYTES <= sec->size &&
                         bytes_zero(bytes + off + 8, DARWIN_ONCE_BYTES - 8))
                {
                    memset(runtime, 0, DARWIN_ONCE_BYTES);
                    normalized++;
                }
                else if (word == DARWIN_RWLOCK_SIG &&
                         off + DARWIN_RWLOCK_BYTES <= sec->size &&
                         bytes_zero(bytes + off + 8,
                                    DARWIN_RWLOCK_BYTES - 8))
                {
                    pthread_rwlock_init((pthread_rwlock_t *)runtime, NULL);
                    normalized++;
                }
            }
        }
    }
    if (debug)
        fprintf(stderr, "iosim: normalized %d pthread object(s)\n",
                normalized);
}
