#define _GNU_SOURCE
#include "macho.h"

#include <stdio.h>
#include <stdarg.h>
#include <stdlib.h>
#include <string.h>
#include <errno.h>
#include <fcntl.h>
#include <unistd.h>
#include <sys/mman.h>
#include <sys/stat.h>

#ifndef MAP_FIXED_NOREPLACE
#define MAP_FIXED_NOREPLACE 0x100000
#endif

#ifndef MAP_ANONYMOUS
#define MAP_ANONYMOUS MAP_ANON
#endif

static uint64_t page_down(uint64_t v) { return v & ~(uint64_t)0xfff; }
static uint64_t page_up(uint64_t v)   { return (v + 0xfff) & ~(uint64_t)0xfff; }

static void set_err(char *err, size_t errlen, const char *fmt, ...)
{
    if (!err || !errlen)
        return;
    va_list ap;
    va_start(ap, fmt);
    vsnprintf(err, errlen, fmt, ap);
    va_end(ap);
}

const char *iosim_platform_name(uint32_t platform)
{
    switch (platform) {
    case 1: return "macOS";
    case 2: return "iOS";
    case 3: return "tvOS";
    case 4: return "watchOS";
    case 5: return "bridgeOS";
    case 6: return "Mac Catalyst";
    case 7: return "iOS Simulator";
    case 8: return "tvOS Simulator";
    case 9: return "watchOS Simulator";
    case 10: return "DriverKit";
    case 11: return "visionOS";
    case 12: return "visionOS Simulator";
    default: return "unknown";
    }
}

static uint32_t read_be32(const uint8_t *p)
{
    return ((uint32_t)p[0] << 24) | ((uint32_t)p[1] << 16) |
           ((uint32_t)p[2] << 8) | (uint32_t)p[3];
}

/* Returns 1 if the buffer is a fat Mach-O and the requested slice was
 * found, 0 for a thin Mach-O and -1 on error. The main executable can ask
 * for arm64; every dylib keeps the x86_64 slice because the reimplemented
 * frameworks are x86_64 images. */
static int find_fat_slice(const uint8_t *buf, size_t len, int prefer_arm64,
                          size_t *slice_off, size_t *slice_len,
                          char *err, size_t errlen)
{
    if (len < 8)
        return 0;
    uint32_t magic = read_be32(buf);
    if (magic != FAT_MAGIC && magic != FAT_MAGIC_64)
    {
        /* A thin little-endian Mach-O starts with CF FA ED FE on disk. */
        return 0;
    }

    uint32_t narch = read_be32(buf + 4);
    if (narch > 64)
    {
        set_err(err, errlen, "fat Mach-O has implausible nfat_arch=%u", narch);
        return -1;
    }

    size_t entsize = (magic == FAT_MAGIC_64) ? sizeof(struct fat_arch_64)
                                             : sizeof(struct fat_arch);
    if (8 + entsize * narch > len)
    {
        set_err(err, errlen, "fat Mach-O arch table out of bounds");
        return -1;
    }

    for (uint32_t i = 0; i < narch; i++)
    {
        const uint8_t *p = buf + 8 + i * entsize;
        int32_t cputype = (int32_t)read_be32(p);
        uint64_t off, size;
        if (magic == FAT_MAGIC_64)
        {
            off  = ((uint64_t)read_be32(p + 8) << 32) | read_be32(p + 12);
            size = ((uint64_t)read_be32(p + 16) << 32) | read_be32(p + 20);
        }
        else
        {
            off  = read_be32(p + 8);
            size = read_be32(p + 12);
        }
        int32_t wanted = prefer_arm64 ? (int32_t)CPU_TYPE_ARM64
                                      : (int32_t)CPU_TYPE_X86_64;
        if (cputype == wanted)
        {
            if (off > len || size > len - off)
            {
                set_err(err, errlen, "fat %s slice out of bounds",
                        prefer_arm64 ? "arm64" : "x86_64");
                return -1;
            }
            *slice_off = (size_t)off;
            *slice_len = (size_t)size;
            return 1;
        }
    }

    set_err(err, errlen, "fat Mach-O has no %s slice",
            prefer_arm64 ? "arm64" : "x86_64");
    return -1;
}

static int read_file(const char *path, uint8_t **out, size_t *out_len,
                     char *err, size_t errlen)
{
    int fd = open(path, O_RDONLY | O_CLOEXEC);
    if (fd < 0)
    {
        set_err(err, errlen, "cannot open %s: %s", path, strerror(errno));
        return -1;
    }
    struct stat st;
    if (fstat(fd, &st) != 0 || st.st_size <= 0)
    {
        set_err(err, errlen, "cannot stat %s: %s", path, strerror(errno));
        close(fd);
        return -1;
    }
    size_t len = (size_t)st.st_size;
    uint8_t *buf = malloc(len);
    if (!buf)
    {
        set_err(err, errlen, "out of memory reading %s", path);
        close(fd);
        return -1;
    }
    size_t done = 0;
    while (done < len)
    {
        ssize_t n = read(fd, buf + done, len - done);
        if (n <= 0)
        {
            set_err(err, errlen, "read %s failed: %s", path, strerror(errno));
            free(buf);
            close(fd);
            return -1;
        }
        done += (size_t)n;
    }
    close(fd);
    *out = buf;
    *out_len = len;
    return 0;
}

static int map_segment_at(struct iosim_image *img, struct iosim_segment *seg,
                          uint64_t slide)
{
    if (seg->vmaddr == 0 && seg->filesize == 0)
        return 0; /* __PAGEZERO: keep unmapped as a guard */

    if (seg->filesize > seg->vmsize)
    {
        return -1;
    }

    uint64_t start = page_down(seg->vmaddr + slide);
    uint64_t end   = page_up(seg->vmaddr + seg->vmsize + slide);
    uint64_t size  = end - start;
    if (size == 0)
        return 0;

    void *want = (void *)(uintptr_t)start;
    void *got = mmap(want, size, PROT_READ | PROT_WRITE,
                     MAP_PRIVATE | MAP_ANONYMOUS | MAP_FIXED_NOREPLACE, -1, 0);
    if (got == MAP_FAILED)
        return -1;
    if (got != want)
    {
        munmap(got, size);
        return -1;
    }

    if (seg->filesize)
        memcpy((void *)(uintptr_t)(seg->vmaddr + slide),
               img->file + seg->fileoff, seg->filesize);

    seg->mapped = 1;
    return 0;
}

static void unmap_segments(struct iosim_image *img)
{
    for (int i = 0; i < img->nsegs; i++)
    {
        struct iosim_segment *s = &img->segs[i];
        if (!s->mapped)
            continue;
        uint64_t start = page_down(s->vmaddr + img->slide);
        uint64_t end   = page_up(s->vmaddr + s->vmsize + img->slide);
        munmap((void *)(uintptr_t)start, end - start);
        s->mapped = 0;
    }
}

static int parse_load_commands(struct iosim_image *img, char *err, size_t errlen)
{
    const struct mach_header_64 *hdr = img->hdr;
    const uint8_t *p = (const uint8_t *)hdr + sizeof(*hdr);
    const uint8_t *end = p + hdr->sizeofcmds;
    const uint8_t *file_end = img->file + img->file_len;

    if (end > file_end)
    {
        set_err(err, errlen, "load commands exceed file size");
        return -1;
    }

    for (uint32_t i = 0; i < hdr->ncmds; i++)
    {
        if (p + sizeof(struct load_command) > end)
        {
            set_err(err, errlen, "truncated load command %u", i);
            return -1;
        }
        const struct load_command *lc = (const struct load_command *)p;
        if (lc->cmdsize < sizeof(struct load_command) || p + lc->cmdsize > end)
        {
            set_err(err, errlen, "bad cmdsize in load command %u", i);
            return -1;
        }

        switch (lc->cmd)
        {
        case LC_SEGMENT_64: {
            if (lc->cmdsize < sizeof(struct segment_command_64))
            {
                set_err(err, errlen, "short LC_SEGMENT_64");
                return -1;
            }
            const struct segment_command_64 *sc = (const void *)p;
            if (img->nsegs >= IOSIM_MAX_SEGS)
            {
                set_err(err, errlen, "too many segments");
                return -1;
            }
            struct iosim_segment *s = &img->segs[img->nsegs++];
            memset(s, 0, sizeof(*s));
            memcpy(s->name, sc->segname, 16);
            s->name[16] = 0;
            s->vmaddr   = sc->vmaddr;
            s->vmsize   = sc->vmsize;
            s->fileoff  = sc->fileoff;
            s->filesize = sc->filesize;
            s->maxprot  = sc->maxprot;
            s->initprot = sc->initprot;

            if (sc->fileoff > img->file_len ||
                sc->filesize > img->file_len - sc->fileoff)
            {
                set_err(err, errlen, "segment %s file range out of bounds",
                        s->name);
                return -1;
            }

            const struct section_64 *sec =
                (const struct section_64 *)(p + sizeof(*sc));
            for (uint32_t j = 0; j < sc->nsects; j++)
            {
                if ((const uint8_t *)(sec + j + 1) > p + lc->cmdsize)
                {
                    set_err(err, errlen, "section table out of bounds");
                    return -1;
                }
                if (img->nsects >= IOSIM_MAX_SECTS)
                    break;
                struct iosim_section *is = &img->sects[img->nsects++];
                memcpy(is->sectname, sec[j].sectname, 16);
                is->sectname[16] = 0;
                memcpy(is->segname, sec[j].segname, 16);
                is->segname[16] = 0;
                is->addr   = sec[j].addr;
                is->size   = sec[j].size;
                is->offset = sec[j].offset;
                is->flags  = sec[j].flags;
            }
            break;
        }

        case LC_ID_DYLIB: {
            if (lc->cmdsize < sizeof(struct dylib_command))
                break;
            const struct dylib_command *dc = (const void *)p;
            if (dc->name_offset < lc->cmdsize)
            {
                const char *name = (const char *)p + dc->name_offset;
                size_t n = strnlen(name, lc->cmdsize - dc->name_offset);
                if (n >= sizeof(img->install_name))
                    n = sizeof(img->install_name) - 1;
                memcpy(img->install_name, name, n);
                img->install_name[n] = 0;
            }
            break;
        }

        case LC_LOAD_DYLIB:
        case LC_LOAD_WEAK_DYLIB:
        case LC_REEXPORT_DYLIB:
        case LC_LAZY_LOAD_DYLIB:
        case LC_LOAD_UPWARD_DYLIB: {
            if (lc->cmdsize < sizeof(struct dylib_command))
                break;
            const struct dylib_command *dc = (const void *)p;
            if (dc->name_offset >= lc->cmdsize ||
                img->ndylibs >= IOSIM_MAX_DYLIBS)
                break;
            struct iosim_dylib *d = &img->dylibs[img->ndylibs];
            const char *name = (const char *)p + dc->name_offset;
            size_t maxlen = lc->cmdsize - dc->name_offset;
            size_t n = strnlen(name, maxlen);
            if (n >= sizeof(d->path))
                n = sizeof(d->path) - 1;
            memcpy(d->path, name, n);
            d->path[n] = 0;
            d->ordinal = (uint32_t)img->ndylibs + 1;
            d->weak = (lc->cmd == LC_LOAD_WEAK_DYLIB);
            img->ndylibs++;
            break;
        }

        case LC_MAIN: {
            if (lc->cmdsize < sizeof(struct entry_point_command))
                break;
            const struct entry_point_command *ec = (const void *)p;
            /* entryoff is a file offset relative to the start of the
             * __TEXT segment (which normally has fileoff 0). */
            uint64_t off = ec->entryoff;
            int found = 0;
            for (int k = 0; k < img->nsegs; k++)
            {
                struct iosim_segment *s = &img->segs[k];
                if (off >= s->fileoff && off < s->fileoff + s->filesize)
                {
                    img->entry_addr = s->vmaddr + (off - s->fileoff);
                    found = 1;
                    break;
                }
            }
            if (!found)
            {
                set_err(err, errlen, "LC_MAIN entryoff 0x%llx not in any segment",
                        (unsigned long long)off);
                return -1;
            }
            break;
        }

        case LC_UNIXTHREAD: {
            if (lc->cmdsize < 16 + sizeof(struct x86_thread_state64))
                break;
            /* flavor, count, then x86_thread_state64 */
            const uint8_t *state = p + 16;
            const struct x86_thread_state64 *ts = (const void *)state;
            img->entry_addr = ts->rip;
            break;
        }

        case LC_DYLD_CHAINED_FIXUPS: {
            if (lc->cmdsize < sizeof(struct linkedit_data_command))
                break;
            const struct linkedit_data_command *ldc = (const void *)p;
            if (ldc->dataoff <= img->file_len &&
                ldc->datasize <= img->file_len - ldc->dataoff)
            {
                img->chained_fixups = img->file + ldc->dataoff;
                img->chained_fixups_size = ldc->datasize;
            }
            break;
        }

        case LC_DYLD_INFO:
        case LC_DYLD_INFO_ONLY:
            if (lc->cmdsize >= sizeof(struct dyld_info_command))
                img->dyld_info = (const void *)p;
            break;

        case LC_SYMTAB:
            if (lc->cmdsize >= sizeof(struct symtab_command))
                img->symtab = (const void *)p;
            break;

        case LC_BUILD_VERSION:
            if (lc->cmdsize >= sizeof(struct build_version_command)) {
                const struct build_version_command *bc = (const void *)p;
                img->platform = bc->platform;
                img->minos = bc->minos;
                img->sdk = bc->sdk;
            }
            break;

        case LC_UUID:
            if (lc->cmdsize >= sizeof(struct uuid_command)) {
                const struct uuid_command *uc = (const void *)p;
                memcpy(img->uuid, uc->uuid, 16);
                img->has_uuid = 1;
            }
            break;

        default:
            break;
        }

        p += lc->cmdsize;
    }

    return 0;
}

static void resolve_entry_name(struct iosim_image *img)
{
    if (!img->symtab)
        return;
    const struct nlist_64 *syms =
        (const void *)(img->file + img->symtab->symoff);
    const char *strs = (const char *)(img->file + img->symtab->stroff);
    if (img->symtab->symoff > img->file_len ||
        (uint64_t)img->symtab->nsyms * sizeof(*syms) >
            img->file_len - img->symtab->symoff)
        return;
    if (img->symtab->stroff > img->file_len)
        return;

    for (uint32_t i = 0; i < img->symtab->nsyms; i++)
    {
        if ((syms[i].n_type & N_STAB) != 0)
            continue;
        if ((syms[i].n_type & N_TYPE) != N_SECT)
            continue;
        if (syms[i].n_value != img->entry_addr)
            continue;
        if (syms[i].n_strx < img->symtab->strsize)
        {
            const char *name = strs + syms[i].n_strx;
            size_t maxlen = img->symtab->strsize - syms[i].n_strx;
            size_t n = strnlen(name, maxlen);
            if (n >= sizeof(img->entry_name))
                n = sizeof(img->entry_name) - 1;
            memcpy(img->entry_name, name, n);
            img->entry_name[n] = 0;
            img->entry_is_main = (strcmp(img->entry_name, "_main") == 0);
        }
        break;
    }
}

void *iosim_find_defined_symbol(struct iosim_image *img, const char *name)
{
    if (!img->symtab || !name)
        return NULL;
    const struct nlist_64 *syms =
        (const void *)(img->file + img->symtab->symoff);
    const char *strs = (const char *)(img->file + img->symtab->stroff);
    if (img->symtab->symoff > img->file_len ||
        (uint64_t)img->symtab->nsyms * sizeof(*syms) >
            img->file_len - img->symtab->symoff)
        return NULL;
    if (img->symtab->stroff > img->file_len)
        return NULL;

    for (uint32_t i = 0; i < img->symtab->nsyms; i++)
    {
        if ((syms[i].n_type & N_STAB) != 0)
            continue;
        uint8_t type = syms[i].n_type & N_TYPE;
        if (type != N_SECT && type != N_ABS)
            continue;
        if (syms[i].n_strx >= img->symtab->strsize)
            continue;
        const char *sname = strs + syms[i].n_strx;
        size_t maxlen = img->symtab->strsize - syms[i].n_strx;
        if (strncmp(sname, name, maxlen) == 0 &&
            strlen(name) == strnlen(sname, maxlen))
        {
            if (type == N_ABS)
                return (void *)(uintptr_t)syms[i].n_value;
            return (void *)(uintptr_t)(syms[i].n_value + img->slide);
        }
    }
    return NULL;
}

int iosim_image_load(const char *path, struct iosim_image *img,
                     int prefer_arm64, char *err, size_t errlen)
{
    memset(img, 0, sizeof(*img));
    snprintf(img->path, sizeof(img->path), "%s", path);

    uint8_t *buf = NULL;
    size_t len = 0;
    if (read_file(path, &buf, &len, err, errlen) != 0)
        return -1;

    size_t slice_off = 0, slice_len = 0;
    int fat = find_fat_slice(buf, len, prefer_arm64, &slice_off,
                             &slice_len, err, errlen);
    if (fat < 0)
    {
        free(buf);
        return -1;
    }
    if (fat == 1)
    {
        uint8_t *slice = malloc(slice_len);
        if (!slice)
        {
            set_err(err, errlen, "out of memory");
            free(buf);
            return -1;
        }
        memcpy(slice, buf + slice_off, slice_len);
        free(buf);
        buf = slice;
        len = slice_len;
    }

    img->file = buf;
    img->file_len = len;

    if (len < sizeof(struct mach_header_64))
    {
        set_err(err, errlen, "%s: too small to be Mach-O", path);
        goto fail;
    }

    img->hdr = (const struct mach_header_64 *)buf;
    if (img->hdr->magic != MH_MAGIC_64)
    {
        set_err(err, errlen, "%s: not a little-endian 64-bit Mach-O (magic 0x%08x)",
                path, img->hdr->magic);
        goto fail;
    }
    if (img->hdr->cputype == (int32_t)CPU_TYPE_ARM64)
        img->is_arm64 = 1;
    else if (img->hdr->cputype != (int32_t)CPU_TYPE_X86_64)
    {
        set_err(err, errlen,
                "%s: unsupported cputype 0x%x (need x86_64 or arm64)",
                path, (unsigned)img->hdr->cputype);
        goto fail;
    }
    if (img->hdr->filetype != MH_EXECUTE && img->hdr->filetype != MH_DYLIB)
    {
        set_err(err, errlen, "%s: unsupported filetype %u", path,
                img->hdr->filetype);
        goto fail;
    }

    if (parse_load_commands(img, err, errlen) != 0)
        goto fail;

    /* Preferred base: lowest non-PAGEZERO segment vmaddr. */
    uint64_t pref = UINT64_MAX;
    for (int i = 0; i < img->nsegs; i++)
    {
        struct iosim_segment *s = &img->segs[i];
        if (s->vmaddr == 0 && s->filesize == 0)
            continue;
        if (s->vmaddr < pref)
            pref = s->vmaddr;
    }
    if (pref == UINT64_MAX)
    {
        set_err(err, errlen, "%s: no loadable segments", path);
        goto fail;
    }
    img->preferred_base = pref;

    /* Map at the preferred address; fall back to slides if occupied. */
    static const uint64_t slides[] = {
        0, 0x1000000000ULL, 0x2000000000ULL, 0x4000000000ULL,
        0x7000000000ULL, 0x10000000000ULL
    };
    int mapped = 0;
    for (size_t si = 0; si < sizeof(slides) / sizeof(slides[0]); si++)
    {
        img->slide = (intptr_t)slides[si];
        int ok = 1;
        for (int i = 0; i < img->nsegs; i++)
        {
            if (map_segment_at(img, &img->segs[i], slides[si]) != 0)
            {
                ok = 0;
                break;
            }
        }
        if (ok)
        {
            mapped = 1;
            break;
        }
        unmap_segments(img);
    }
    if (!mapped)
    {
        set_err(err, errlen, "%s: could not map segments: %s", path,
                strerror(errno));
        goto fail;
    }

    resolve_entry_name(img);

    if (img->hdr->filetype == MH_EXECUTE && img->entry_addr == 0)
    {
        set_err(err, errlen, "%s: no entry point (no LC_MAIN/LC_UNIXTHREAD)",
                path);
        goto fail;
    }

    return 0;

fail:
    unmap_segments(img);
    free(img->file);
    memset(img, 0, sizeof(*img));
    return -1;
}

void iosim_image_unmap(struct iosim_image *img)
{
    if (!img->file)
        return;
    unmap_segments(img);
    free(img->file);
    img->file = NULL;
}


int iosim_describe_imports(struct iosim_image *img, FILE *out)
{
    if (!img->chained_fixups)
    {
        fprintf(out, "  (no LC_DYLD_CHAINED_FIXUPS)\n");
        return 0;
    }
    const struct dyld_chained_fixups_header *fh =
        (const void *)img->chained_fixups;
    const uint8_t *blob = img->chained_fixups;
    const char *symbols = (const char *)blob + fh->symbols_offset;

    fprintf(out, "  chained imports: %u (format %u)\n",
            fh->imports_count, fh->imports_format);

    for (uint32_t i = 0; i < fh->imports_count; i++)
    {
        const char *name = NULL;
        int lib = 0, weak = 0;
        int64_t addend = 0;
        if (fh->imports_format == DYLD_CHAINED_IMPORT)
        {
            const struct dyld_chained_import *im =
                (const void *)(blob + fh->imports_offset +
                               i * sizeof(*im));
            lib = (int8_t)im->lib_ordinal;
            weak = im->weak_import;
            name = symbols + im->name_offset;
        }
        else if (fh->imports_format == DYLD_CHAINED_IMPORT_ADDEND)
        {
            const struct dyld_chained_import_addend *im =
                (const void *)(blob + fh->imports_offset +
                               i * sizeof(*im));
            lib = (int8_t)im->lib_ordinal;
            weak = im->weak_import;
            addend = im->addend;
            name = symbols + im->name_offset;
        }
        else if (fh->imports_format == DYLD_CHAINED_IMPORT_ADDEND64)
        {
            const struct dyld_chained_import_addend64 *im =
                (const void *)(blob + fh->imports_offset +
                               i * sizeof(*im));
            lib = (int16_t)im->lib_ordinal;
            weak = im->weak_import;
            addend = (int64_t)im->addend;
            name = symbols + im->name_offset;
        }
        else
        {
            fprintf(out, "  unknown imports format\n");
            return -1;
        }
        fprintf(out, "  [%3u] lib=%3d weak=%d addend=%lld %s\n",
                i, lib, weak, (long long)addend, name ? name : "<bad>");
    }
    return 0;
}
