#define _GNU_SOURCE
#include "macho.h"
#include "shims.h"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <errno.h>
#include <dlfcn.h>
#include <sys/mman.h>
#include <unistd.h>

void iosim_missing_named(const char *name)
{
    fprintf(stderr, "iosim: fatal: called unimplemented Darwin symbol %s\n",
            name ? name : "(null)");
    _exit(127);
}

/* Emit a tiny trampoline that reports the missing symbol name when called. */
static void *make_missing_stub(const char *name)
{
    char *copy = strdup(name ? name : "<null>");
    if (!copy)
        return NULL;

    uint8_t *code = mmap(NULL, 4096, PROT_READ | PROT_WRITE,
                         MAP_PRIVATE | MAP_ANONYMOUS, -1, 0);
    if (code == MAP_FAILED)
    {
        free(copy);
        return NULL;
    }

    /* movabs $copy, %rdi ; movabs $iosim_missing_named, %rax ; jmp *%rax */
    uint8_t *p = code;
    *p++ = 0x48; *p++ = 0xBF;
    uint64_t imm = (uint64_t)(uintptr_t)copy;
    memcpy(p, &imm, 8); p += 8;
    *p++ = 0x48; *p++ = 0xB8;
    imm = (uint64_t)(uintptr_t)&iosim_missing_named;
    memcpy(p, &imm, 8); p += 8;
    *p++ = 0xFF; *p++ = 0xE0;

    if (mprotect(code, 4096, PROT_READ | PROT_EXEC) != 0)
    {
        munmap(code, 4096);
        free(copy);
        return NULL;
    }
    return code;
}

static const char *skip_underscore(const char *name)
{
    return (name && name[0] == '_') ? name + 1 : name;
}

void *iosim_default_resolve(struct iosim_resolver *res, struct iosim_image *img,
                            const char *macho_name, int lib_ordinal, int weak)
{
    (void)res;

    void *self = iosim_find_defined_symbol(img, macho_name);
    if (self)
        return self;

    const char *name = skip_underscore(macho_name);

    /* Darwin data symbols that map onto glibc variables. */
    if (strcmp(name, "__stdoutp") == 0)
        return dlsym(RTLD_DEFAULT, "stdout");
    if (strcmp(name, "__stderrp") == 0)
        return dlsym(RTLD_DEFAULT, "stderr");
    if (strcmp(name, "__stdinp") == 0)
        return dlsym(RTLD_DEFAULT, "stdin");
    if (strcmp(name, "__progname") == 0)
        return &iosim_progname;

    void *shim = iosim_lookup_shim(name);
    if (shim)
        return shim;

    void *sym = dlsym(RTLD_DEFAULT, name);
    if (sym)
        return sym;

    /* Some Darwin private symbols have two leading underscores in C. */
    if (name[0] == '_')
    {
        sym = dlsym(RTLD_DEFAULT, name + 1);
        if (sym)
            return sym;
    }

    if (weak)
        return NULL;

    return make_missing_stub(macho_name);
}
