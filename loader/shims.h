#ifndef IOSIM_SHIMS_H
#define IOSIM_SHIMS_H

#include <stdint.h>

struct iosim_shim {
    const char *name;
    void       *addr;
};

void *iosim_lookup_shim(const char *name);

extern int    iosim_argc;
extern char **iosim_argv;
extern char **iosim_environ;
extern char   iosim_exec_path[1024];
extern char  *iosim_progname;

#endif
