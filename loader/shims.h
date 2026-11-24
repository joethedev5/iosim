#ifndef IOSIM_SHIMS_H
#define IOSIM_SHIMS_H

#include <stdint.h>

struct iosim_shim {
    const char *name;
    void       *addr;
};

void *iosim_lookup_shim(const char *name);
/* Finds the shim whose address is addr, for callers that only know a
 * resolved function pointer. Returns 1 and sets *name when found. */
int iosim_shim_lookup_addr(void *addr, const char **name);

/* Native functions resolved from preloaded framework images or host dlsym
 * for an arm64 main. The arm64 call gate uses this reverse map when guest
 * code branches to a framework C function. */
void iosim_native_symbol_note(void *addr, const char *name);
int iosim_native_symbol_lookup(void *addr, const char **name);

extern int    iosim_argc;
extern char **iosim_argv;
extern char **iosim_environ;
extern char   iosim_exec_path[1024];
extern char  *iosim_progname;

#endif
