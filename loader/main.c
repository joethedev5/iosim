#define _GNU_SOURCE
#include "context.h"
#include "macho.h"
#include "shims.h"
#include "objc_runtime.h"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <errno.h>
#include <unistd.h>
#include <limits.h>
#include <sys/mman.h>

#ifndef MAP_STACK
#define MAP_STACK 0
#endif

extern char **environ;

void iosim_jump_to_entry(void *entry, uint64_t argc, char **argv,
                         char **envp, char **apple, void *stack_top)
    __attribute__((noreturn));

static void usage(const char *prog)
{
    fprintf(stderr,
        "usage: %s [options] <macho-executable> [args...]\n"
        "  -v, --verbose        print image details\n"
        "      --imports        list chained imports and exit\n"
        "      --entry          print entry point and exit\n"
        "      --dylib-path DIR add a dylib/framework search directory\n"
        "  -h, --help           this help\n"
        "\n"
        "Environment: IOSIM_DYLIB_PATH (colon-separated search path)\n", prog);
}

static void print_image(struct iosim_image *img)
{
    printf("image: %s\n", img->path);
    if (img->install_name[0])
        printf("  install name: %s\n", img->install_name);
    printf("  platform: %s (%u), minos 0x%x, sdk 0x%x\n",
           iosim_platform_name(img->platform), img->platform,
           img->minos, img->sdk);
    if (img->has_uuid)
    {
        printf("  uuid: ");
        for (int i = 0; i < 16; i++)
            printf("%02x%s", img->uuid[i],
                   (i == 3 || i == 5 || i == 7 || i == 9) ? "-" : "");
        printf("\n");
    }
    printf("  preferred base: 0x%llx, slide: 0x%llx\n",
           (unsigned long long)img->preferred_base,
           (unsigned long long)(uint64_t)img->slide);
    printf("  entry: 0x%llx %s%s\n", (unsigned long long)img->entry_addr,
           img->entry_name[0] ? img->entry_name : "(unknown)",
           img->entry_is_main ? " [main]" : " [crt]");
    printf("  segments:\n");
    for (int i = 0; i < img->nsegs; i++)
    {
        struct iosim_segment *s = &img->segs[i];
        printf("    %-16s vmaddr=0x%09llx vmsize=0x%08llx file=0x%06llx/0x%06llx prot=%d/%d\n",
               s->name,
               (unsigned long long)s->vmaddr,
               (unsigned long long)s->vmsize,
               (unsigned long long)s->fileoff,
               (unsigned long long)s->filesize,
               s->initprot, s->maxprot);
    }
    if (img->ndylibs)
    {
        printf("  dylibs:\n");
        for (int i = 0; i < img->ndylibs; i++)
            printf("    [%u]%s %s%s\n", img->dylibs[i].ordinal,
                   img->dylibs[i].weak ? " weak" : "", img->dylibs[i].path,
                   img->dylibs[i].image ? " (loaded)" : "");
    }
}

/* Darwin initial process stack:
 *   argc, argv[0..argc-1], NULL, envp[0..n-1], NULL, apple[0..m-1], NULL
 */
static void *build_darwin_stack(int argc, char **argv, char **envp,
                                char **apple, void **top_out)
{
    size_t envc = 0;
    while (envp[envc])
        envc++;
    size_t applec = 0;
    while (apple[applec])
        applec++;

    size_t slots = 1 + ((size_t)argc + 1) + (envc + 1) + (applec + 1);
    size_t need = slots * sizeof(uint64_t) + 64;

    void *stack = mmap(NULL, 16 * 1024 * 1024, PROT_READ | PROT_WRITE,
                       MAP_PRIVATE | MAP_ANONYMOUS | MAP_STACK, -1, 0);
    if (stack == MAP_FAILED)
        return NULL;

    uintptr_t top = ((uintptr_t)stack + 16 * 1024 * 1024) & ~(uintptr_t)15;
    top -= need;
    top &= ~(uintptr_t)15;

    uint64_t *p = (uint64_t *)top;
    *p++ = (uint64_t)argc;
    for (int i = 0; i < argc; i++)
        *p++ = (uint64_t)(uintptr_t)argv[i];
    *p++ = 0;
    for (size_t i = 0; i < envc; i++)
        *p++ = (uint64_t)(uintptr_t)envp[i];
    *p++ = 0;
    for (size_t i = 0; i < applec; i++)
        *p++ = (uint64_t)(uintptr_t)apple[i];
    *p++ = 0;

    *top_out = (void *)top;
    return stack;
}

int main(int argc, char **argv)
{
    const char *path = NULL;
    int verbose = 0, list_imports = 0, print_entry_only = 0;
    int first_arg = 0;
    struct iosim_context ctx;
    iosim_context_init(&ctx);

    for (int i = 1; i < argc; i++)
    {
        if (strcmp(argv[i], "-v") == 0 || strcmp(argv[i], "--verbose") == 0)
            verbose = 1;
        else if (strcmp(argv[i], "--imports") == 0)
            list_imports = 1;
        else if (strcmp(argv[i], "--entry") == 0)
            print_entry_only = 1;
        else if (strcmp(argv[i], "--dylib-path") == 0 && i + 1 < argc)
            iosim_context_add_path(&ctx, argv[++i]);
        else if (strcmp(argv[i], "-h") == 0 || strcmp(argv[i], "--help") == 0)
        {
            usage(argv[0]);
            return 0;
        }
        else if (strcmp(argv[i], "--") == 0)
        {
            if (i + 1 < argc)
            {
                path = argv[i + 1];
                first_arg = i + 2;
            }
            break;
        }
        else
        {
            path = argv[i];
            first_arg = i + 1;
            break;
        }
    }

    if (!path)
    {
        usage(argv[0]);
        return 2;
    }

    const char *env_paths = getenv("IOSIM_DYLIB_PATH");
    if (env_paths && *env_paths)
    {
        char *copy = strdup(env_paths);
        char *save = NULL;
        for (char *p = strtok_r(copy, ":", &save); p; p = strtok_r(NULL, ":", &save))
            iosim_context_add_path(&ctx, p);
        free(copy);
    }

    char err[1024] = {0};
    struct iosim_image *img = iosim_context_load(&ctx, path, err, sizeof(err));
    if (!img)
    {
        fprintf(stderr, "iosim: %s\n", err);
        iosim_context_free(&ctx);
        return 1;
    }
    img->verbose = verbose;

    if (verbose)
    {
        for (int i = 0; i < ctx.nimages; i++)
            print_image(ctx.images[i]);
    }

    if (list_imports)
    {
        iosim_describe_imports(img, stdout);
        iosim_context_free(&ctx);
        return 0;
    }
    if (print_entry_only)
    {
        printf("0x%llx %s\n", (unsigned long long)img->entry_addr,
               img->entry_name);
        iosim_context_free(&ctx);
        return 0;
    }

    if (iosim_context_apply_fixups(&ctx, err, sizeof(err)) != 0)
    {
        fprintf(stderr, "iosim: fixups: %s\n", err);
        iosim_context_free(&ctx);
        return 1;
    }

    /* Register Objective-C classes from every loaded image. */
    for (int i = 0; i < ctx.nimages; i++)
        iosim_objc_register_image(ctx.images[i]);
    if (verbose)
        iosim_objc_dump();

    int guest_argc = argc - first_arg + 1;
    char **guest_argv = calloc((size_t)guest_argc + 1, sizeof(char *));
    if (!guest_argv)
    {
        fprintf(stderr, "iosim: out of memory\n");
        return 1;
    }
    guest_argv[0] = (char *)path;
    for (int i = first_arg; i < argc; i++)
        guest_argv[i - first_arg + 1] = argv[i];

    char real[PATH_MAX];
    if (realpath(path, real))
        snprintf(iosim_exec_path, sizeof(iosim_exec_path), "%s", real);
    else
        snprintf(iosim_exec_path, sizeof(iosim_exec_path), "%s", path);

    char *base = strrchr(iosim_exec_path, '/');
    iosim_progname = base ? base + 1 : iosim_exec_path;

    /* An app executable lives inside Foo.app; NSBundle and UIImage resolve
     * resources against that directory. Derive it from the executable, so a
     * child launched by SpringBoard does not inherit the system UI's bundle. */
    if (base)
    {
        char bundle[PATH_MAX];
        snprintf(bundle, sizeof(bundle), "%s", iosim_exec_path);
        char *slash = strrchr(bundle, '/');
        if (slash)
        {
            *slash = 0;
            size_t n = strlen(bundle);
            if (n > 4 && strcmp(bundle + n - 4, ".app") == 0)
                setenv("IOSIM_BUNDLE_DIR", bundle, 1);
        }
    }
    iosim_argc = guest_argc;
    iosim_argv = guest_argv;
    iosim_environ = environ;

    char *apple[2] = { iosim_exec_path, NULL };
    void *entry = (void *)(uintptr_t)(img->entry_addr + img->slide);

    if (img->entry_is_main)
    {
        int (*main_fn)(int, char **, char **, char **) = (void *)entry;
        int rc = main_fn(guest_argc, guest_argv, environ, apple);
        fflush(NULL);
        return rc;
    }

    void *stack_top = NULL;
    void *stack = build_darwin_stack(guest_argc, guest_argv, environ, apple,
                                     &stack_top);
    if (!stack)
    {
        fprintf(stderr, "iosim: cannot allocate guest stack: %s\n",
                strerror(errno));
        return 1;
    }

    if (verbose)
        fprintf(stderr, "iosim: jumping to %p with Darwin stack %p\n",
                entry, stack_top);

    iosim_jump_to_entry(entry, (uint64_t)guest_argc, guest_argv, environ,
                        apple, stack_top);
}
