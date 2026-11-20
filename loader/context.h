#ifndef IOSIM_CONTEXT_H
#define IOSIM_CONTEXT_H

#include "macho.h"

struct iosim_context {
    struct iosim_image **images;
    int    nimages;
    int    cap;
    char  *search_paths[64];
    int    npaths;
    char   main_dir[1024];
};

void iosim_context_init(struct iosim_context *ctx);
void iosim_context_free(struct iosim_context *ctx);

/* Adds a search directory for dylib lookup. */
void iosim_context_add_path(struct iosim_context *ctx, const char *dir);

/* Loads an executable/dylib and recursively loads its LC_LOAD_DYLIB
 * dependencies. Returns the main image or NULL. */
struct iosim_image *iosim_context_load(struct iosim_context *ctx,
                                       const char *path,
                                       char *err, size_t errlen);

/* Applies fixups to every loaded image. */
int iosim_context_apply_fixups(struct iosim_context *ctx,
                               char *err, size_t errlen);

/* Resolver implementation that sees all loaded images. */
void *iosim_context_resolve(struct iosim_resolver *r, struct iosim_image *img,
                            const char *name, int lib_ordinal, int weak);

#endif
