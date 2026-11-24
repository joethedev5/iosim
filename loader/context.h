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
    int    prefer_arm64;   /* load the arm64 slice of the main executable */
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

/* Loads an additional dylib into the context (for an arm64 main executable
 * whose link-time framework is not present as an arm64 binary). */
struct iosim_image *iosim_context_load_dylib(struct iosim_context *ctx,
                                             const char *path,
                                             char *err, size_t errlen);

/* Applies fixups to every loaded image. */
int iosim_context_apply_fixups(struct iosim_context *ctx,
                               char *err, size_t errlen);

/* Runs Mach-O initializer pointers (__DATA,__mod_init_func), dependencies
 * first, the way dyld runs image initializers before main. C++ tools rely on
 * these constructors to register command-line options, locales and globals. */
void iosim_context_run_initializers(struct iosim_context *ctx);

/* Rewrites Darwin pthread static initializers in writable data to host
 * pthread layouts. Must run before initializers and main. */
void iosim_normalize_pthread_objects(struct iosim_context *ctx);

/* Installs per-image thread-local thunks and lazy initial content. */
void iosim_tlv_setup_image(struct iosim_image *img);

/* Resolver implementation that sees all loaded images. */
void *iosim_context_resolve(struct iosim_resolver *r, struct iosim_image *img,
                            const char *name, int lib_ordinal, int weak);

#endif
