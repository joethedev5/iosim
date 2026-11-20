#define _GNU_SOURCE
#include "macho.h"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <errno.h>
#include <sys/mman.h>
#include <unistd.h>

/* ---------- classic dyld opcode constants ---------- */

#define REBASE_OPCODE_MASK          0xF0
#define REBASE_IMMEDIATE_MASK       0x0F
#define REBASE_OPCODE_DONE                          0x00
#define REBASE_OPCODE_SET_TYPE_IMM                  0x10
#define REBASE_OPCODE_SET_SEGMENT_AND_OFFSET_ULEB   0x20
#define REBASE_OPCODE_ADD_ADDR_ULEB                 0x30
#define REBASE_OPCODE_ADD_ADDR_IMM_SCALED           0x40
#define REBASE_OPCODE_DO_REBASE_IMM_TIMES           0x50
#define REBASE_OPCODE_DO_REBASE_ULEB_TIMES          0x60
#define REBASE_OPCODE_DO_REBASE_ADD_ADDR_ULEB       0x70
#define REBASE_OPCODE_DO_REBASE_ULEB_TIMES_SKIPPING_ULEB 0x80

#define REBASE_TYPE_POINTER         1

#define BIND_OPCODE_MASK            0xF0
#define BIND_IMMEDIATE_MASK         0x0F
#define BIND_OPCODE_DONE                            0x00
#define BIND_OPCODE_SET_DYLIB_ORDINAL_IMM           0x10
#define BIND_OPCODE_SET_DYLIB_ORDINAL_ULEB          0x20
#define BIND_OPCODE_SET_DYLIB_SPECIAL_IMM           0x30
#define BIND_OPCODE_SET_SYMBOL_TRAILING_FLAGS_IMM   0x40
#define BIND_OPCODE_SET_TYPE_IMM                    0x50
#define BIND_OPCODE_SET_ADDEND_SLEB                 0x60
#define BIND_OPCODE_SET_SEGMENT_AND_OFFSET_ULEB     0x70
#define BIND_OPCODE_ADD_ADDR_ULEB                   0x80
#define BIND_OPCODE_DO_BIND                         0x90
#define BIND_OPCODE_DO_BIND_ADD_ADDR_ULEB           0xA0
#define BIND_OPCODE_DO_BIND_ADD_ADDR_IMM_SCALED     0xB0
#define BIND_OPCODE_DO_BIND_ULEB_TIMES_SKIPPING_ULEB 0xC0
#define BIND_OPCODE_THREADED                        0xD0

#define BIND_TYPE_POINTER           1
#define BIND_SPECIAL_DYLIB_FLAT_LOOKUP  (-2)
#define BIND_SPECIAL_DYLIB_WEAK_LOOKUP  (-3)
#define BIND_SYMBOL_FLAGS_WEAK_IMPORT 0x1

static uint64_t read_uleb(const uint8_t **pp, const uint8_t *end, int *ok)
{
    uint64_t result = 0;
    int shift = 0;
    const uint8_t *p = *pp;
    while (p < end)
    {
        uint8_t b = *p++;
        if (shift < 64)
            result |= (uint64_t)(b & 0x7f) << shift;
        shift += 7;
        if ((b & 0x80) == 0)
        {
            *pp = p;
            return result;
        }
    }
    *ok = 0;
    return 0;
}

static int64_t read_sleb(const uint8_t **pp, const uint8_t *end, int *ok)
{
    int64_t result = 0;
    int shift = 0;
    uint8_t b = 0;
    const uint8_t *p = *pp;
    do
    {
        if (p >= end)
        {
            *ok = 0;
            return 0;
        }
        b = *p++;
        if (shift < 64)
            result |= (int64_t)(b & 0x7f) << shift;
        shift += 7;
    } while (b & 0x80);
    if (shift < 64 && (b & 0x40))
        result |= (int64_t)(~0ULL << shift);
    *pp = p;
    return result;
}

static uint8_t *segment_host_addr(struct iosim_image *img, int seg_index,
                                  uint64_t offset)
{
    struct iosim_segment *s = &img->segs[seg_index];
    return (uint8_t *)(uintptr_t)(s->vmaddr + img->slide + offset);
}

/* ---------- chained imports ---------- */

struct chained_imports {
    struct iosim_import *items;
    uint32_t count;
    void **targets;
};

static int build_chained_imports(struct iosim_image *img,
                                 struct iosim_resolver *res,
                                 struct chained_imports *ci,
                                 char *err, size_t errlen)
{
    const struct dyld_chained_fixups_header *fh =
        (const void *)img->chained_fixups;
    const uint8_t *blob = img->chained_fixups;
    uint32_t blob_size = img->chained_fixups_size;

    memset(ci, 0, sizeof(*ci));

    if (fh->symbols_offset > blob_size || fh->imports_offset > blob_size ||
        fh->starts_offset > blob_size)
    {
        snprintf(err, errlen, "chained fixups offsets out of bounds");
        return -1;
    }
    if (fh->symbols_format != 0)
    {
        snprintf(err, errlen, "chained fixups use unsupported compressed symbols");
        return -1;
    }
    if (fh->imports_count > IOSIM_MAX_IMPORTS)
    {
        snprintf(err, errlen, "too many chained imports (%u)", fh->imports_count);
        return -1;
    }

    const char *symbols = (const char *)(blob + fh->symbols_offset);
    uint32_t symbols_size = blob_size - fh->symbols_offset;

    ci->count = fh->imports_count;
    ci->items = calloc(ci->count ? ci->count : 1, sizeof(*ci->items));
    ci->targets = calloc(ci->count ? ci->count : 1, sizeof(*ci->targets));
    if (!ci->items || !ci->targets)
    {
        snprintf(err, errlen, "out of memory");
        return -1;
    }

    for (uint32_t i = 0; i < ci->count; i++)
    {
        struct iosim_import *im = &ci->items[i];
        const char *name = NULL;
        uint64_t name_off = 0;

        if (fh->imports_format == DYLD_CHAINED_IMPORT)
        {
            const struct dyld_chained_import *e =
                (const void *)(blob + fh->imports_offset +
                               (size_t)i * sizeof(*e));
            im->lib_ordinal = (int8_t)e->lib_ordinal;
            im->weak = e->weak_import;
            im->addend = 0;
            name_off = e->name_offset;
        }
        else if (fh->imports_format == DYLD_CHAINED_IMPORT_ADDEND)
        {
            const struct dyld_chained_import_addend *e =
                (const void *)(blob + fh->imports_offset +
                               (size_t)i * sizeof(*e));
            im->lib_ordinal = (int8_t)e->lib_ordinal;
            im->weak = e->weak_import;
            im->addend = e->addend;
            name_off = e->name_offset;
        }
        else if (fh->imports_format == DYLD_CHAINED_IMPORT_ADDEND64)
        {
            const struct dyld_chained_import_addend64 *e =
                (const void *)(blob + fh->imports_offset +
                               (size_t)i * sizeof(*e));
            im->lib_ordinal = (int16_t)e->lib_ordinal;
            im->weak = e->weak_import;
            im->addend = (int64_t)e->addend;
            name_off = e->name_offset;
        }
        else
        {
            snprintf(err, errlen, "unknown chained imports format %u",
                     fh->imports_format);
            return -1;
        }

        if (name_off >= symbols_size)
        {
            snprintf(err, errlen, "chained import %u name offset out of range", i);
            return -1;
        }
        name = symbols + name_off;
        size_t maxlen = symbols_size - name_off;
        size_t n = strnlen(name, maxlen);
        if (n == maxlen)
        {
            snprintf(err, errlen, "unterminated chained import name %u", i);
            return -1;
        }
        im->name = strdup(name);
        if (!im->name)
        {
            snprintf(err, errlen, "out of memory");
            return -1;
        }

        void *base = iosim_find_defined_symbol(img, name);
        if (!base && res && res->resolve)
            base = res->resolve(res, img, name, im->lib_ordinal, im->weak);
        if (!base)
        {
            if (!im->weak && img->verbose)
                fprintf(stderr, "iosim: unresolved import %s (lib %d)\n",
                        name, im->lib_ordinal);
            base = NULL;
        }
        ci->targets[i] = (uint8_t *)base + (base ? im->addend : 0);
    }

    return 0;
}

static void free_chained_imports(struct chained_imports *ci)
{
    if (ci->items)
    {
        for (uint32_t i = 0; i < ci->count; i++)
            free(ci->items[i].name);
        free(ci->items);
    }
    free(ci->targets);
}

static int apply_one_chain(struct iosim_image *img, struct chained_imports *ci,
                           uint8_t *chain_start, uint16_t pointer_format,
                           char *err, size_t errlen)
{
    uint8_t *loc = chain_start;

    for (;;)
    {
        uint64_t raw;
        memcpy(&raw, loc, sizeof(raw));

        int bind;
        uint64_t next_stride;
        uint64_t new_value = 0;
        int is_bind = 0;
        uint32_t ordinal = 0;

        switch (pointer_format)
        {
        case DYLD_CHAINED_PTR_64:
        case DYLD_CHAINED_PTR_64_OFFSET: {
            bind = (int)(raw >> 63);
            uint64_t next = (raw >> 51) & 0xFFF;
            next_stride = next * 4;
            if (bind)
            {
                ordinal = (uint32_t)(raw & 0xFFFFFF);
                uint64_t addend = (raw >> 24) & 0xFF;
                if (ordinal >= ci->count)
                {
                    snprintf(err, errlen, "bind ordinal %u out of range", ordinal);
                    return -1;
                }
                new_value = (uint64_t)(uintptr_t)ci->targets[ordinal] + addend;
                is_bind = 1;
            }
            else
            {
                uint64_t target = raw & 0xFFFFFFFFFULL; /* 36 bits */
                uint64_t high8 = (raw >> 36) & 0xFF;
                uint64_t host;
                if (pointer_format == DYLD_CHAINED_PTR_64)
                    host = target + (uint64_t)img->slide;
                else
                    host = img->preferred_base + (uint64_t)img->slide + target;
                host = (host & 0x00FFFFFFFFFFFFFFULL) | (high8 << 56);
                new_value = host;
            }
            break;
        }
        case DYLD_CHAINED_PTR_ARM64E:
        case DYLD_CHAINED_PTR_ARM64E_USERLAND:
        case DYLD_CHAINED_PTR_ARM64E_USERLAND24: {
            /* Not needed for x86_64 targets; accept only non-auth forms. */
            uint64_t auth = raw >> 63;
            bind = (int)((raw >> 62) & 1);
            uint64_t next = (raw >> 51) & 0x7FF;
            next_stride = next * 8;
            if (auth)
            {
                snprintf(err, errlen, "authenticated arm64e pointer in x86_64 image");
                return -1;
            }
            if (bind)
            {
                uint32_t max_ord = (pointer_format == DYLD_CHAINED_PTR_ARM64E_USERLAND24)
                                       ? 0xFFFFFF : 0xFFFF;
                ordinal = (uint32_t)(raw & max_ord);
                if (ordinal >= ci->count)
                {
                    snprintf(err, errlen, "bind ordinal %u out of range", ordinal);
                    return -1;
                }
                new_value = (uint64_t)(uintptr_t)ci->targets[ordinal];
                is_bind = 1;
            }
            else
            {
                uint64_t target = raw & 0x7FFFFFFFFFFULL; /* 43 bits */
                uint8_t high8 = (uint8_t)((raw >> 43) & 0xFF);
                uint64_t host;
                if (pointer_format == DYLD_CHAINED_PTR_ARM64E)
                    host = target + (uint64_t)img->slide;
                else
                    host = img->preferred_base + (uint64_t)img->slide + target;
                new_value = (host & 0x00FFFFFFFFFFFFFFULL) | ((uint64_t)high8 << 56);
            }
            break;
        }
        default:
            snprintf(err, errlen, "unsupported chained pointer format %u",
                     pointer_format);
            return -1;
        }

        memcpy(loc, &new_value, sizeof(new_value));
        (void)is_bind;

        if (next_stride == 0)
            break;
        loc += next_stride;
    }

    return 0;
}

static int apply_chained_fixups(struct iosim_image *img,
                                struct iosim_resolver *res,
                                char *err, size_t errlen)
{
    const struct dyld_chained_fixups_header *fh =
        (const void *)img->chained_fixups;

    struct chained_imports ci;
    if (build_chained_imports(img, res, &ci, err, errlen) != 0)
    {
        free_chained_imports(&ci);
        return -1;
    }

    if (fh->fixups_version != 0)
    {
        snprintf(err, errlen, "unsupported chained fixups version %u",
                 fh->fixups_version);
        free_chained_imports(&ci);
        return -1;
    }

    const struct dyld_chained_starts_in_image *starts =
        (const void *)(img->chained_fixups + fh->starts_offset);
    uint32_t seg_count = starts->seg_count;
    if (seg_count > (uint32_t)img->nsegs && img->verbose)
        fprintf(stderr, "iosim: warning: chained seg_count %u > %d segments\n",
                seg_count, img->nsegs);
    if (seg_count > (uint32_t)img->nsegs)
        seg_count = (uint32_t)img->nsegs;

    uint8_t *hdr_host =
        (uint8_t *)(uintptr_t)(img->preferred_base + img->slide);

    int rc = 0;
    for (uint32_t si = 0; si < seg_count; si++)
    {
        uint32_t off = starts->seg_info_offset[si];
        if (off == 0)
            continue;
        const struct dyld_chained_starts_in_segment *ss =
            (const void *)((const uint8_t *)starts + off);
        if (ss->page_size < sizeof(uint64_t) || ss->page_count == 0)
            continue;

        uint8_t *seg_host = hdr_host + ss->segment_offset;

        for (uint32_t page = 0; page < ss->page_count; page++)
        {
            uint16_t ps = ss->page_start[page];
            if (ps == DYLD_CHAINED_PTR_START_NONE)
                continue;

            if (ps & DYLD_CHAINED_PTR_START_MULTI)
            {
                uint32_t idx = ps & ~DYLD_CHAINED_PTR_START_MULTI;
                int last = 0;
                while (!last)
                {
                    uint16_t ent = ss->page_start[idx];
                    last = (ent & DYLD_CHAINED_PTR_START_LAST) != 0;
                    uint16_t start_off = ent & ~DYLD_CHAINED_PTR_START_LAST;
                    uint8_t *chain = seg_host + (uint64_t)page * ss->page_size +
                                     start_off;
                    if (apply_one_chain(img, &ci, chain, ss->pointer_format,
                                        err, errlen) != 0)
                        rc = -1;
                    idx++;
                }
            }
            else
            {
                uint8_t *chain = seg_host + (uint64_t)page * ss->page_size + ps;
                if (apply_one_chain(img, &ci, chain, ss->pointer_format,
                                    err, errlen) != 0)
                    rc = -1;
            }
            if (rc != 0)
                break;
        }
        if (rc != 0)
            break;
    }

    free_chained_imports(&ci);
    return rc;
}

/* ---------- classic LC_DYLD_INFO opcodes ---------- */

static int apply_classic_fixups(struct iosim_image *img,
                                struct iosim_resolver *res,
                                char *err, size_t errlen)
{
    const struct dyld_info_command *di = img->dyld_info;
    int errors = 0;

    /* rebases */
    if (di->rebase_size)
    {
        const uint8_t *p = img->file + di->rebase_off;
        const uint8_t *end = p + di->rebase_size;
        int seg = -1;
        uint64_t off = 0;
        int type = REBASE_TYPE_POINTER;

        while (p < end)
        {
            uint8_t byte = *p++;
            uint8_t opcode = byte & REBASE_OPCODE_MASK;
            uint8_t imm = byte & REBASE_IMMEDIATE_MASK;
            int ok = 1;
            switch (opcode)
            {
            case REBASE_OPCODE_DONE:
                p = end;
                break;
            case REBASE_OPCODE_SET_TYPE_IMM:
                type = imm;
                break;
            case REBASE_OPCODE_SET_SEGMENT_AND_OFFSET_ULEB:
                seg = imm;
                off = read_uleb(&p, end, &ok);
                break;
            case REBASE_OPCODE_ADD_ADDR_ULEB:
                off += read_uleb(&p, end, &ok);
                break;
            case REBASE_OPCODE_ADD_ADDR_IMM_SCALED:
                off += (uint64_t)imm * sizeof(void *);
                break;
            case REBASE_OPCODE_DO_REBASE_IMM_TIMES:
                for (int i = 0; i < imm && seg >= 0 && seg < img->nsegs; i++)
                {
                    uint64_t *loc = (uint64_t *)segment_host_addr(img, seg, off);
                    if (type == REBASE_TYPE_POINTER)
                        *loc += (uint64_t)img->slide;
                    off += sizeof(void *);
                }
                break;
            case REBASE_OPCODE_DO_REBASE_ULEB_TIMES: {
                uint64_t count = read_uleb(&p, end, &ok);
                for (uint64_t i = 0; i < count && seg >= 0 && seg < img->nsegs; i++)
                {
                    uint64_t *loc = (uint64_t *)segment_host_addr(img, seg, off);
                    if (type == REBASE_TYPE_POINTER)
                        *loc += (uint64_t)img->slide;
                    off += sizeof(void *);
                }
                break;
            }
            case REBASE_OPCODE_DO_REBASE_ADD_ADDR_ULEB: {
                uint64_t skip = read_uleb(&p, end, &ok);
                if (seg >= 0 && seg < img->nsegs)
                {
                    uint64_t *loc = (uint64_t *)segment_host_addr(img, seg, off);
                    if (type == REBASE_TYPE_POINTER)
                        *loc += (uint64_t)img->slide;
                }
                off += skip + sizeof(void *);
                break;
            }
            case REBASE_OPCODE_DO_REBASE_ULEB_TIMES_SKIPPING_ULEB: {
                uint64_t count = read_uleb(&p, end, &ok);
                uint64_t skip = read_uleb(&p, end, &ok);
                for (uint64_t i = 0; i < count && seg >= 0 && seg < img->nsegs; i++)
                {
                    uint64_t *loc = (uint64_t *)segment_host_addr(img, seg, off);
                    if (type == REBASE_TYPE_POINTER)
                        *loc += (uint64_t)img->slide;
                    off += skip + sizeof(void *);
                }
                break;
            }
            default:
                snprintf(err, errlen, "unknown rebase opcode 0x%02x", opcode);
                return -1;
            }
            if (!ok)
            {
                snprintf(err, errlen, "truncated rebase opcode stream");
                return -1;
            }
        }
    }

    /* binds (normal, weak and lazy are all bound eagerly) */
    struct bind_stream {
        uint32_t off, size;
        int weak;
    } streams[3] = {
        { di->bind_off, di->bind_size, 0 },
        { di->weak_bind_off, di->weak_bind_size, 1 },
        { di->lazy_bind_off, di->lazy_bind_size, 0 }
    };

    for (int s = 0; s < 3; s++)
    {
        if (!streams[s].size)
            continue;
        const uint8_t *p = img->file + streams[s].off;
        const uint8_t *end = p + streams[s].size;
        int seg = -1;
        uint64_t off = 0;
        int type = BIND_TYPE_POINTER;
        int lib_ordinal = 0;
        int64_t addend = 0;
        char symbol[512] = {0};
        int weak = streams[s].weak;

        while (p < end)
        {
            uint8_t byte = *p++;
            uint8_t opcode = byte & BIND_OPCODE_MASK;
            uint8_t imm = byte & BIND_IMMEDIATE_MASK;
            int ok = 1;

            switch (opcode)
            {
            case BIND_OPCODE_DONE:
                if (s == 2) /* lazy stream: continue after DONE */
                    break;
                p = end;
                break;
            case BIND_OPCODE_SET_DYLIB_ORDINAL_IMM:
                lib_ordinal = imm;
                break;
            case BIND_OPCODE_SET_DYLIB_ORDINAL_ULEB:
                lib_ordinal = (int)read_uleb(&p, end, &ok);
                break;
            case BIND_OPCODE_SET_DYLIB_SPECIAL_IMM:
                lib_ordinal = imm ? (int8_t)(BIND_OPCODE_MASK | imm) : 0;
                break;
            case BIND_OPCODE_SET_SYMBOL_TRAILING_FLAGS_IMM: {
                size_t n = 0;
                while (p < end && *p && n < sizeof(symbol) - 1)
                    symbol[n++] = (char)*p++;
                symbol[n] = 0;
                if (p < end && *p == 0)
                    p++;
                weak = weak || (imm & BIND_SYMBOL_FLAGS_WEAK_IMPORT);
                break;
            }
            case BIND_OPCODE_SET_TYPE_IMM:
                type = imm;
                break;
            case BIND_OPCODE_SET_ADDEND_SLEB:
                addend = read_sleb(&p, end, &ok);
                break;
            case BIND_OPCODE_SET_SEGMENT_AND_OFFSET_ULEB:
                seg = imm;
                off = read_uleb(&p, end, &ok);
                break;
            case BIND_OPCODE_ADD_ADDR_ULEB:
                off += read_uleb(&p, end, &ok);
                break;
            case BIND_OPCODE_DO_BIND:
            case BIND_OPCODE_DO_BIND_ADD_ADDR_ULEB:
            case BIND_OPCODE_DO_BIND_ADD_ADDR_IMM_SCALED:
            case BIND_OPCODE_DO_BIND_ULEB_TIMES_SKIPPING_ULEB: {
                uint64_t skip = 0, count = 1;
                if (opcode == BIND_OPCODE_DO_BIND_ADD_ADDR_ULEB)
                    skip = read_uleb(&p, end, &ok) + sizeof(void *);
                else if (opcode == BIND_OPCODE_DO_BIND_ADD_ADDR_IMM_SCALED)
                    skip = (uint64_t)imm * sizeof(void *) + sizeof(void *);
                else if (opcode == BIND_OPCODE_DO_BIND_ULEB_TIMES_SKIPPING_ULEB)
                {
                    count = read_uleb(&p, end, &ok);
                    skip = read_uleb(&p, end, &ok) + sizeof(void *);
                }
                else
                    skip = sizeof(void *);

                void *target = NULL;
                if (symbol[0])
                {
                    target = iosim_find_defined_symbol(img, symbol);
                    if (!target && res && res->resolve)
                        target = res->resolve(res, img, symbol, lib_ordinal, weak);
                    if (!target && img->verbose)
                        fprintf(stderr, "iosim: unresolved bind %s\n", symbol);
                }

                for (uint64_t i = 0; i < count && seg >= 0 && seg < img->nsegs; i++)
                {
                    uint64_t *loc = (uint64_t *)segment_host_addr(img, seg, off);
                    if (type == BIND_TYPE_POINTER)
                        *loc = (uint64_t)(uintptr_t)target + (uint64_t)addend;
                    off += skip;
                }
                break;
            }
            case BIND_OPCODE_THREADED:
                /* arm64e-only thread binding; nothing to do for x86_64. */
                break;
            default:
                snprintf(err, errlen, "unknown bind opcode 0x%02x", opcode);
                errors++;
                p = end;
                break;
            }
            if (!ok)
            {
                snprintf(err, errlen, "truncated bind opcode stream");
                return -1;
            }
        }
    }

    return errors ? -1 : 0;
}

static void protect_segments(struct iosim_image *img)
{
    for (int i = 0; i < img->nsegs; i++)
    {
        struct iosim_segment *s = &img->segs[i];
        if (!s->mapped)
            continue;
        int prot = 0;
        if (s->initprot & VM_PROT_READ)
            prot |= PROT_READ;
        if (s->initprot & VM_PROT_WRITE)
            prot |= PROT_WRITE;
        if (s->initprot & VM_PROT_EXECUTE)
            prot |= PROT_EXEC;
        if (prot == 0)
            prot = PROT_READ;
        uint64_t start = (s->vmaddr + img->slide) & ~(uint64_t)0xfff;
        uint64_t end = (s->vmaddr + img->slide + s->vmsize + 0xfff) & ~(uint64_t)0xfff;
        if (end > start)
            mprotect((void *)(uintptr_t)start, end - start, prot);
    }
}

int iosim_apply_fixups(struct iosim_image *img, struct iosim_resolver *res,
                       char *err, size_t errlen)
{
    int rc = 0;
    if (err && errlen)
        err[0] = 0;

    if (img->chained_fixups)
    {
        if (apply_chained_fixups(img, res, err, errlen) != 0)
            rc = -1;
    }
    if (img->dyld_info && (img->dyld_info->rebase_size ||
                           img->dyld_info->bind_size ||
                           img->dyld_info->weak_bind_size ||
                           img->dyld_info->lazy_bind_size))
    {
        if (apply_classic_fixups(img, res, err, errlen) != 0)
            rc = -1;
    }

    protect_segments(img);
    return rc;
}
