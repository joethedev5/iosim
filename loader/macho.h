#ifndef IOSIM_MACHO_H
#define IOSIM_MACHO_H

#include <stdint.h>
#include <stddef.h>
#include <stdio.h>

/* Minimal self-contained Mach-O definitions (LP64, little-endian). */

#define MH_MAGIC_64      0xfeedfacfu
#define MH_CIGAM_64      0xcffaedfeu
#define FAT_MAGIC        0xcafebabeu
#define FAT_MAGIC_64     0xcafebabfu

#define CPU_ARCH_ABI64   0x01000000u
#define CPU_TYPE_X86_64  (CPU_ARCH_ABI64 | 7)

#define MH_EXECUTE       0x2u
#define MH_DYLIB         0x6u

#define LC_REQ_DYLD      0x80000000u

#define LC_SEGMENT_64            0x19u
#define LC_SYMTAB                0x02u
#define LC_DYSYMTAB              0x0bu
#define LC_LOAD_DYLIB            0x0cu
#define LC_ID_DYLIB              0x0du
#define LC_LOAD_DYLINKER         0x0eu
#define LC_UUID                  0x1bu
#define LC_UNIXTHREAD            0x05u
#define LC_LAZY_LOAD_DYLIB       0x20u
#define LC_DYLD_INFO             0x22u
#define LC_DYLD_INFO_ONLY        (0x22u | LC_REQ_DYLD)
#define LC_LOAD_WEAK_DYLIB       (0x18u | LC_REQ_DYLD)
#define LC_REEXPORT_DYLIB        (0x1fu | LC_REQ_DYLD)
#define LC_LOAD_UPWARD_DYLIB     (0x23u | LC_REQ_DYLD)
#define LC_MAIN                  (0x28u | LC_REQ_DYLD)
#define LC_BUILD_VERSION         0x32u
#define LC_DYLD_EXPORTS_TRIE     (0x33u | LC_REQ_DYLD)
#define LC_DYLD_CHAINED_FIXUPS   (0x34u | LC_REQ_DYLD)

#define VM_PROT_READ     0x1
#define VM_PROT_WRITE    0x2
#define VM_PROT_EXECUTE  0x4

#define N_STAB  0xe0
#define N_PEXT  0x10
#define N_TYPE  0x0e
#define N_EXT   0x01
#define N_UNDF  0x0
#define N_ABS   0x2
#define N_SECT  0xe
#define N_INDR  0xa

#define BIND_SYMBOL_FLAGS_WEAK_IMPORT 0x1
#define BIND_SYMBOL_FLAGS_NON_WEAK_DEFINITION 0x8

struct mach_header_64 {
    uint32_t magic;
    int32_t  cputype;
    int32_t  cpusubtype;
    uint32_t filetype;
    uint32_t ncmds;
    uint32_t sizeofcmds;
    uint32_t flags;
    uint32_t reserved;
};

struct load_command {
    uint32_t cmd;
    uint32_t cmdsize;
};

struct segment_command_64 {
    uint32_t cmd;
    uint32_t cmdsize;
    char     segname[16];
    uint64_t vmaddr;
    uint64_t vmsize;
    uint64_t fileoff;
    uint64_t filesize;
    int32_t  maxprot;
    int32_t  initprot;
    uint32_t nsects;
    uint32_t flags;
};

struct section_64 {
    char     sectname[16];
    char     segname[16];
    uint64_t addr;
    uint64_t size;
    uint32_t offset;
    uint32_t align;
    uint32_t reloff;
    uint32_t nreloc;
    uint32_t flags;
    uint32_t reserved1;
    uint32_t reserved2;
    uint32_t reserved3;
};

struct dylib_command {
    uint32_t cmd;
    uint32_t cmdsize;
    uint32_t name_offset;
    uint32_t timestamp;
    uint32_t current_version;
    uint32_t compatibility_version;
};

struct linkedit_data_command {
    uint32_t cmd;
    uint32_t cmdsize;
    uint32_t dataoff;
    uint32_t datasize;
};

struct dyld_info_command {
    uint32_t cmd;
    uint32_t cmdsize;
    uint32_t rebase_off;
    uint32_t rebase_size;
    uint32_t bind_off;
    uint32_t bind_size;
    uint32_t weak_bind_off;
    uint32_t weak_bind_size;
    uint32_t lazy_bind_off;
    uint32_t lazy_bind_size;
    uint32_t export_off;
    uint32_t export_size;
};

struct symtab_command {
    uint32_t cmd;
    uint32_t cmdsize;
    uint32_t symoff;
    uint32_t nsyms;
    uint32_t stroff;
    uint32_t strsize;
};

struct entry_point_command {
    uint32_t cmd;
    uint32_t cmdsize;
    uint64_t entryoff;
    uint64_t stacksize;
};

struct build_version_command {
    uint32_t cmd;
    uint32_t cmdsize;
    uint32_t platform;
    uint32_t minos;
    uint32_t sdk;
    uint32_t ntools;
};

struct uuid_command {
    uint32_t cmd;
    uint32_t cmdsize;
    uint8_t  uuid[16];
};

struct nlist_64 {
    uint32_t n_strx;
    uint8_t  n_type;
    uint8_t  n_sect;
    uint16_t n_desc;
    uint64_t n_value;
};

struct fat_header {
    uint32_t magic;
    uint32_t nfat_arch;
};

struct fat_arch {
    int32_t  cputype;
    int32_t  cpusubtype;
    uint32_t offset;
    uint32_t size;
    uint32_t align;
};

struct fat_arch_64 {
    int32_t  cputype;
    int32_t  cpusubtype;
    uint64_t offset;
    uint64_t size;
    uint32_t align;
    uint32_t reserved;
};

struct x86_thread_state64 {
    uint64_t rax, rbx, rcx, rdx, rdi, rsi, rbp, rsp;
    uint64_t r8, r9, r10, r11, r12, r13, r14, r15;
    uint64_t rip, rflags, cs, fs, gs;
};

/* Chained fixups */
struct dyld_chained_fixups_header {
    uint32_t fixups_version;
    uint32_t starts_offset;
    uint32_t imports_offset;
    uint32_t symbols_offset;
    uint32_t imports_count;
    uint32_t imports_format;
    uint32_t symbols_format;
};

struct dyld_chained_starts_in_image {
    uint32_t seg_count;
    uint32_t seg_info_offset[1];
};

struct dyld_chained_starts_in_segment {
    uint32_t size;
    uint16_t page_size;
    uint16_t pointer_format;
    uint64_t segment_offset;
    uint32_t max_valid_pointer;
    uint16_t page_count;
    uint16_t page_start[1];
};

struct dyld_chained_import {
    uint32_t lib_ordinal : 8,
             weak_import : 1,
             name_offset : 23;
};

struct dyld_chained_import_addend {
    uint32_t lib_ordinal : 8,
             weak_import : 1,
             name_offset : 23;
    int32_t  addend;
};

struct dyld_chained_import_addend64 {
    uint64_t lib_ordinal : 16,
             weak_import : 1,
             reserved    : 15,
             name_offset : 32;
    uint64_t addend;
};

enum {
    DYLD_CHAINED_PTR_ARM64E              = 1,
    DYLD_CHAINED_PTR_64                  = 2,
    DYLD_CHAINED_PTR_32                  = 3,
    DYLD_CHAINED_PTR_32_CACHE            = 4,
    DYLD_CHAINED_PTR_32_FIRMWARE         = 5,
    DYLD_CHAINED_PTR_64_OFFSET           = 6,
    DYLD_CHAINED_PTR_ARM64E_KERNEL       = 7,
    DYLD_CHAINED_PTR_64_KERNEL_CACHE     = 8,
    DYLD_CHAINED_PTR_ARM64E_USERLAND     = 9,
    DYLD_CHAINED_PTR_ARM64E_FIRMWARE     = 10,
    DYLD_CHAINED_PTR_X86_64_KERNEL_CACHE = 11,
    DYLD_CHAINED_PTR_ARM64E_USERLAND24   = 12
};

enum {
    DYLD_CHAINED_PTR_START_NONE  = 0xFFFF,
    DYLD_CHAINED_PTR_START_MULTI = 0x8000,
    DYLD_CHAINED_PTR_START_LAST  = 0x8000
};

enum {
    DYLD_CHAINED_IMPORT          = 1,
    DYLD_CHAINED_IMPORT_ADDEND   = 2,
    DYLD_CHAINED_IMPORT_ADDEND64 = 3
};

#define IOSIM_MAX_SEGS    32
#define IOSIM_MAX_SECTS   256
#define IOSIM_MAX_DYLIBS  64
#define IOSIM_MAX_IMPORTS 65536

struct iosim_section {
    char     segname[17];
    char     sectname[17];
    uint64_t addr;
    uint64_t size;
    uint32_t offset;
    uint32_t flags;
};

struct iosim_segment {
    char     name[17];
    uint64_t vmaddr;
    uint64_t vmsize;
    uint64_t fileoff;
    uint64_t filesize;
    int32_t  maxprot;
    int32_t  initprot;
    int      mapped;
};

struct iosim_image;

struct iosim_dylib {
    char     path[1024];
    uint32_t ordinal;
    int      weak;
    struct iosim_image *image;   /* resolved loaded image, if any */
};

struct iosim_import {
    char    *name;           /* Mach-O symbol name (with leading underscore) */
    int      lib_ordinal;
    int      weak;
    int64_t  addend;
};

struct iosim_image {
    char     path[1024];
    char     install_name[1024];
    uint8_t *file;
    size_t   file_len;

    const struct mach_header_64 *hdr;
    uint64_t preferred_base;
    intptr_t slide;
    int      verbose;

    struct iosim_segment segs[IOSIM_MAX_SEGS];
    int      nsegs;
    struct iosim_section sects[IOSIM_MAX_SECTS];
    int      nsects;
    struct iosim_dylib   dylibs[IOSIM_MAX_DYLIBS];
    int      ndylibs;

    uint64_t entry_addr;         /* unslid vmaddr */
    char     entry_name[256];
    int      entry_is_main;

    const struct dyld_info_command *dyld_info;
    const struct symtab_command    *symtab;
    const uint8_t *chained_fixups;
    uint32_t chained_fixups_size;

    uint32_t platform;
    uint32_t minos;
    uint32_t sdk;
    uint8_t  uuid[16];
    int      has_uuid;
};

/* A symbol resolver: returns the runtime address for a Mach-O symbol name. */
struct iosim_resolver {
    void *ctx;
    void *(*resolve)(struct iosim_resolver *r, struct iosim_image *img,
                     const char *name, int lib_ordinal, int weak);
};

void *iosim_default_resolve(struct iosim_resolver *r, struct iosim_image *img,
                            const char *name, int lib_ordinal, int weak);

int  iosim_image_load(const char *path, struct iosim_image *img,
                      char *err, size_t errlen);
void iosim_image_unmap(struct iosim_image *img);

/* Returns address of a symbol defined in this image, or NULL. */
void *iosim_find_defined_symbol(struct iosim_image *img, const char *name);

/* Apply LC_DYLD_CHAINED_FIXUPS and/or LC_DYLD_INFO rebase/bind opcodes.
 * Returns number of errors. */
int iosim_apply_fixups(struct iosim_image *img, struct iosim_resolver *res,
                       char *err, size_t errlen);

/* Number of imports available for diagnosis (chained tables only). */
int iosim_describe_imports(struct iosim_image *img, FILE *out);

const char *iosim_platform_name(uint32_t platform);

#endif
