#define _GNU_SOURCE
#include "context.h"
#include "shims.h"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <limits.h>
#include <sys/stat.h>

void iosim_context_init(struct iosim_context *ctx)
{
    memset(ctx, 0, sizeof(*ctx));
}

void iosim_context_free(struct iosim_context *ctx)
{
    for (int i = 0; i < ctx->nimages; i++)
    {
        iosim_image_unmap(ctx->images[i]);
        free(ctx->images[i]);
    }
    free(ctx->images);
    for (int i = 0; i < ctx->npaths; i++)
        free(ctx->search_paths[i]);
    memset(ctx, 0, sizeof(*ctx));
}

void iosim_context_add_path(struct iosim_context *ctx, const char *dir)
{
    if (!dir || !*dir || ctx->npaths >= 64)
        return;
    ctx->search_paths[ctx->npaths++] = strdup(dir);
}

static void dir_of(const char *path, char *out, size_t outlen)
{
    const char *slash = strrchr(path, '/');
    if (!slash)
    {
        snprintf(out, outlen, ".");
        return;
    }
    size_t len = (size_t)(slash - path);
    if (len == 0)
        len = 1; /* root */
    if (len >= outlen)
        len = outlen - 1;
    memcpy(out, path, len);
    out[len] = 0;
}

static struct iosim_image *find_loaded(struct iosim_context *ctx,
                                       const char *ident)
{
    for (int i = 0; i < ctx->nimages; i++)
    {
        struct iosim_image *im = ctx->images[i];
        if (strcmp(im->path, ident) == 0)
            return im;
        if (im->install_name[0] && strcmp(im->install_name, ident) == 0)
            return im;
    }
    return NULL;
}

static int file_exists(const char *path)
{
    struct stat st;
    return stat(path, &st) == 0 && S_ISREG(st.st_mode);
}

static int join_path(char *out, size_t outlen, const char *dir,
                     const char *name)
{
    int n;
    if (dir && *dir && strcmp(dir, "/") != 0)
        n = snprintf(out, outlen, "%s/%s", dir, name);
    else
        n = snprintf(out, outlen, "/%s", name);
    return n > 0 && (size_t)n < outlen;
}

static int try_dir(char *out, size_t outlen, const char *dir,
                   const char *name)
{
    char cand[PATH_MAX];
    if (!join_path(cand, sizeof(cand), dir, name))
        return 0;
    if (file_exists(cand))
    {
        snprintf(out, outlen, "%s", cand);
        return 1;
    }
    return 0;
}

static int resolve_dep(struct iosim_context *ctx, struct iosim_image *loader,
                       const char *name, char *out, size_t outlen)
{
    char loader_dir[PATH_MAX];
    dir_of(loader->path, loader_dir, sizeof(loader_dir));

    if (strncmp(name, "@loader_path/", 13) == 0)
        return try_dir(out, outlen, loader_dir, name + 13);
    if (strncmp(name, "@executable_path/", 17) == 0)
        return try_dir(out, outlen, ctx->main_dir, name + 17);
    if (strncmp(name, "@rpath/", 7) == 0)
    {
        const char *rest = name + 7;
        if (try_dir(out, outlen, loader_dir, rest))
            return 1;
        if (try_dir(out, outlen, ctx->main_dir, rest))
            return 1;
        for (int i = 0; i < ctx->npaths; i++)
            if (try_dir(out, outlen, ctx->search_paths[i], rest))
                return 1;
        return 0;
    }
    if (name[0] == '/')
    {
        /* dyld_sim root-path substitution: an install name such as
         * /System/Library/Frameworks/UIKit.framework/UIKit is satisfied
         * from $DYLD_ROOT_PATH when a simulator runtime root is active. */
        const char *root = getenv("DYLD_ROOT_PATH");
        if (root && *root)
        {
            char cand[PATH_MAX];
            int n = snprintf(cand, sizeof(cand), "%s%s", root, name);
            if (n > 0 && (size_t)n < sizeof(cand) && file_exists(cand))
            {
                snprintf(out, outlen, "%s", cand);
                return 1;
            }
        }
        if (file_exists(name))
        {
            snprintf(out, outlen, "%s", name);
            return 1;
        }
        /* Fall back to basename in our search paths. */
        const char *base = strrchr(name, '/') + 1;
        if (try_dir(out, outlen, loader_dir, base))
            return 1;
        if (try_dir(out, outlen, ctx->main_dir, base))
            return 1;
        for (int i = 0; i < ctx->npaths; i++)
            if (try_dir(out, outlen, ctx->search_paths[i], base))
                return 1;
        return 0;
    }
    if (try_dir(out, outlen, loader_dir, name))
        return 1;
    if (try_dir(out, outlen, ctx->main_dir, name))
        return 1;
    for (int i = 0; i < ctx->npaths; i++)
        if (try_dir(out, outlen, ctx->search_paths[i], name))
            return 1;
    return 0;
}

static struct iosim_image *load_one(struct iosim_context *ctx,
                                    const char *path, int is_main,
                                    char *err, size_t errlen)
{
    struct iosim_image *existing = find_loaded(ctx, path);
    if (existing)
        return existing;

    struct iosim_image *img = calloc(1, sizeof(*img));
    if (!img)
    {
        snprintf(err, errlen, "out of memory");
        return NULL;
    }
    if (iosim_image_load(path, img, is_main && ctx->prefer_arm64,
                         err, errlen) != 0)
    {
        free(img);
        return NULL;
    }

    if (ctx->nimages == ctx->cap)
    {
        int ncap = ctx->cap ? ctx->cap * 2 : 8;
        struct iosim_image **ni = realloc(ctx->images,
                                          (size_t)ncap * sizeof(*ni));
        if (!ni)
        {
            iosim_image_unmap(img);
            free(img);
            snprintf(err, errlen, "out of memory");
            return NULL;
        }
        ctx->images = ni;
        ctx->cap = ncap;
    }
    ctx->images[ctx->nimages++] = img;

    if (is_main)
        dir_of(img->path, ctx->main_dir, sizeof(ctx->main_dir));

    for (int i = 0; i < img->ndylibs; i++)
    {
        struct iosim_dylib *d = &img->dylibs[i];
        char dep_path[PATH_MAX] = {0};

        struct iosim_image *dep = find_loaded(ctx, d->path);
        if (dep)
        {
            d->image = dep;
            continue;
        }
        if (!resolve_dep(ctx, img, d->path, dep_path, sizeof(dep_path)))
        {
            if (!d->weak)
                fprintf(stderr, "iosim: warning: cannot locate dylib %s\n",
                        d->path);
            continue;
        }
        dep = load_one(ctx, dep_path, 0, err, errlen);
        d->image = dep;
    }

    return img;
}

struct iosim_image *iosim_context_load(struct iosim_context *ctx,
                                       const char *path,
                                       char *err, size_t errlen)
{
    char real[PATH_MAX];
    const char *use = path;
    if (realpath(path, real))
        use = real;
    return load_one(ctx, use, 1, err, errlen);
}

struct iosim_image *iosim_context_load_dylib(struct iosim_context *ctx,
                                             const char *path,
                                             char *err, size_t errlen)
{
    char real[PATH_MAX];
    const char *use = path;
    if (realpath(path, real))
        use = real;
    return load_one(ctx, use, 0, err, errlen);
}

void iosim_context_preload_frameworks(struct iosim_context *ctx)
{
    /* A thin arm64 fixture links with -undefined dynamic_lookup, so its
     * load commands do not name the frameworks it imports. The device
     * manager starts such an app with a framework search directory but no
     * --load-dylib list; open the standard frameworks from the simulator
     * runtime root so its imports resolve. An app that already loaded one
     * (through a load command or an explicit list) is left alone, and
     * frameworks missing from this runtime are skipped. */
    static const char *const names[] = {
        "/System/Library/Frameworks/Foundation.framework/Foundation",
        "/System/Library/Frameworks/UIKit.framework/UIKit",
        "/System/Library/Frameworks/QuartzCore.framework/QuartzCore",
        "/System/Library/Frameworks/UserNotifications.framework/UserNotifications",
    };
    const char *root = getenv("DYLD_ROOT_PATH");
    char err[512];

    for (size_t i = 0; i < sizeof(names) / sizeof(names[0]); i++)
    {
        if (find_loaded(ctx, names[i]))
            continue;
        char path[PATH_MAX];
        if (root && *root)
            snprintf(path, sizeof(path), "%s%s", root, names[i]);
        else
            snprintf(path, sizeof(path), "%s", names[i]);
        if (!file_exists(path))
            continue;
        iosim_context_load_dylib(ctx, path, err, sizeof(err));
    }
}

/* Records symbols an arm64 image imports from native framework images so
 * the arm64 call gate can call them by address. */
static void note_arm64_native_symbol(struct iosim_image *img,
                                     struct iosim_image *provider,
                                     const char *name, void *sym)
{
    if (img->is_arm64 && provider && !provider->is_arm64)
        iosim_native_symbol_note(sym, name);
}

void *iosim_context_resolve(struct iosim_resolver *r, struct iosim_image *img,
                            const char *name, int lib_ordinal, int weak)
{
    struct iosim_context *ctx = r->ctx;

    if (lib_ordinal > 0 && (size_t)lib_ordinal <= (size_t)img->ndylibs)
    {
        struct iosim_image *dep = img->dylibs[lib_ordinal - 1].image;
        if (dep)
        {
            void *sym = iosim_find_defined_symbol(dep, name);
            if (sym)
            {
                note_arm64_native_symbol(img, dep, name, sym);
                return sym;
            }
        }
    }

    void *self = iosim_find_defined_symbol(img, name);
    if (self)
        return self;

    for (int i = 0; i < ctx->nimages; i++)
    {
        if (ctx->images[i] == img)
            continue;
        void *sym = iosim_find_defined_symbol(ctx->images[i], name);
        if (sym)
        {
            note_arm64_native_symbol(img, ctx->images[i], name, sym);
            return sym;
        }
    }

    return iosim_default_resolve(r, img, name, lib_ordinal, weak);
}

int iosim_context_apply_fixups(struct iosim_context *ctx,
                               char *err, size_t errlen)
{
    struct iosim_resolver res = { .ctx = ctx, .resolve = iosim_context_resolve };
    /* Dependencies have lower indexes only if loaded depth-first after the
     * main image; address resolution does not require relocation order, so
     * any order is correct. */
    for (int i = 0; i < ctx->nimages; i++)
    {
        char one_err[512] = {0};
        if (iosim_apply_fixups(ctx->images[i], &res, one_err, sizeof(one_err)) != 0)
        {
            snprintf(err, errlen, "%s: %s", ctx->images[i]->path, one_err);
            return -1;
        }
    }
    return 0;
}

void iosim_context_run_initializers(struct iosim_context *ctx)
{    if (getenv("IOSIM_SKIP_INITIALIZERS"))
        return;

    /* Images are loaded depth-first with the main executable at index 0 and
     * its dependencies appended afterwards, so reverse order initializes
     * leaves of the dependency graph before their dependents and main last. */
    for (int i = ctx->nimages - 1; i >= 0; i--)
    {
        struct iosim_image *img = ctx->images[i];
        /* arm64 initializer functions are arm64 code and wait for the
         * translation layer. */
        if (img->is_arm64)
            continue;
        for (int s = 0; s < img->nsects; s++)
        {
            struct iosim_section *sec = &img->sects[s];
            if (strcmp(sec->sectname, "__init_offsets") == 0)
            {
                /* Modern linked images store 32-bit initializer offsets
                 * relative to the image's preferred base instead of pointer
                 * arrays. */
                uint64_t count = sec->size / sizeof(int32_t);
                int32_t *offsets =
                    (int32_t *)(uintptr_t)(sec->addr + img->slide);
                for (uint64_t n = 0; n < count; n++)
                {
                    int32_t off = offsets[n];
                    if (!off)
                        continue;
                    void (*fn)(void) = (void (*)(void))(uintptr_t)
                        ((int64_t)img->preferred_base + img->slide + off);
                    if (img->verbose)
                        fprintf(stderr, "iosim: init offset %s[%llu] = %p\n",
                                img->path, (unsigned long long)n, fn);
                    fn();
                }
                continue;
            }
            if (strcmp(sec->sectname, "__mod_init_func") != 0)
                continue;
            uint64_t count = sec->size / sizeof(void *);
            void **entries =
                (void **)(uintptr_t)(sec->addr + img->slide);
            for (uint64_t n = 0; n < count; n++)
            {
                if (entries[n])
                {
                    if (img->verbose)
                        fprintf(stderr, "iosim: init %s[%llu] = %p\n",
                                img->path, (unsigned long long)n,
                                entries[n]);
                    ((void (*)(void))entries[n])();
                }
            }
        }
    }
}
