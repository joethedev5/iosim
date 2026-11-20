#define _GNU_SOURCE
#include "shims.h"
#include "macho.h"
#include "objc_runtime.h"
#include "framebuffer.h"
#include "events.h"
#include "services.h"
#include "image.h"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <errno.h>
#include <malloc.h>
#include <time.h>
#include <unistd.h>
#include <math.h>
#include <time.h>
#include <stdarg.h>

void  *objc_opt_class(void *obj);
double iosim_now(void);
void *_Block_copy(void *block);
void _Block_release(void *block);
void _Block_object_assign(void *dest, const void *object, int flags);
void _Block_object_dispose(const void *object, int flags);
struct iosim_sincos_result { double sin_value; double cos_value; };
struct iosim_sincos_result __sincos_stret(double x);

int    iosim_argc = 0;
char **iosim_argv = NULL;
char **iosim_environ = NULL;
char   iosim_exec_path[1024] = "/";
char  *iosim_progname = (char *)"";

/* ---------- dyld / libSystem ---------- */

static void shim_dyld_stub_binder(void)
{
    fprintf(stderr, "iosim: unexpected call to dyld_stub_binder\n");
    _exit(126);
}

static int *shim_NSGetArgc(void) { return &iosim_argc; }
static char ***shim_NSGetArgv(void) { return &iosim_argv; }
static char ***shim_NSGetEnviron(void) { return &iosim_environ; }
static char **shim_NSGetProgname(void) { return &iosim_progname; }

static int shim_NSGetExecutablePath(char *buf, uint32_t *bufsize)
{
    size_t need = strlen(iosim_exec_path) + 1;
    if (!buf || !bufsize)
        return -1;
    if (*bufsize < need)
    {
        *bufsize = (uint32_t)need;
        return -1;
    }
    memcpy(buf, iosim_exec_path, need);
    return 0;
}

static const char *shim_getprogname(void) { return iosim_progname; }
static void shim_setprogname(const char *name) { iosim_progname = (char *)name; }
static int *shim___error(void) { return __errno_location(); }

/* ---------- malloc -------- */

static size_t shim_malloc_size(const void *p) { return malloc_usable_size((void *)p); }

static void *shim_malloc_default_zone(void)
{
    static int zone_token;
    return &zone_token;
}

static void *shim_malloc_create_zone(size_t start_size, unsigned flags)
{
    (void)start_size; (void)flags;
    return shim_malloc_default_zone();
}

static void *shim_malloc_zone_malloc(void *zone, size_t size)
{
    (void)zone;
    return malloc(size);
}

static void *shim_malloc_zone_calloc(void *zone, size_t n, size_t size)
{
    (void)zone;
    return calloc(n, size);
}

static void *shim_malloc_zone_realloc(void *zone, void *p, size_t size)
{
    (void)zone;
    return realloc(p, size);
}

static void shim_malloc_zone_free(void *zone, void *p)
{
    (void)zone;
    free(p);
}

static void shim_malloc_zone_destroy(void *zone) { (void)zone; }

/* ---------- mach time ---------- */

static uint64_t shim_mach_absolute_time(void)
{
    struct timespec ts;
    clock_gettime(CLOCK_MONOTONIC, &ts);
    return (uint64_t)ts.tv_sec * 1000000000ull + (uint64_t)ts.tv_nsec;
}

struct mach_timebase_info { uint32_t numer; uint32_t denom; };

static int shim_mach_timebase_info(struct mach_timebase_info *info)
{
    if (info)
    {
        info->numer = 1;
        info->denom = 1;
    }
    return 0;
}

/* ---------- os_log ---------- */

typedef void *os_log_t;

static os_log_t shim_os_log_create(const char *subsystem, const char *category)
{
    (void)subsystem; (void)category;
    return (os_log_t)1;
}

static int shim_os_log_type_enabled(os_log_t log, uint8_t type)
{
    (void)log; (void)type;
    return 0;
}

static void os_log_emit(const char *kind, os_log_t log, const char *format)
{
    (void)log;
    fprintf(stderr, "os_log(%s): %s\n", kind, format ? format : "(null)");
}

static void shim__os_log_impl(void *dso, os_log_t log, const char *format,
                              uint8_t *buf, unsigned size)
{
    (void)dso; (void)buf; (void)size;
    os_log_emit("default", log, format);
}

static void shim__os_log_error_impl(void *dso, os_log_t log, const char *format,
                                    uint8_t *buf, unsigned size)
{
    (void)dso; (void)buf; (void)size;
    os_log_emit("error", log, format);
}

static void shim__os_log_fault_impl(void *dso, os_log_t log, const char *format,
                                    uint8_t *buf, unsigned size)
{
    (void)dso; (void)buf; (void)size;
    os_log_emit("fault", log, format);
}

static void shim__os_log_debug_impl(void *dso, os_log_t log, const char *format,
                                    uint8_t *buf, unsigned size)
{
    (void)dso; (void)buf; (void)size;
    os_log_emit("debug", log, format);
}

static void shim__os_log(void *log, const char *format)
{
    os_log_emit("default", log, format);
}

static void *shim_os_retain(void *obj) { return obj; }
static void shim_os_release(void *obj) { (void)obj; }

/* ---------- Foundation / UIKit lite ---------- */

static void shim_iosim_nslog(const char *message)
{
    fprintf(stderr, "NSLog: %s\n", message ? message : "(null)");
}

struct cf_constant_string_min {
    void *isa;
    uint32_t flags;
    uint32_t pad;
    const char *cstr;
    uint64_t length;
};

static int shim_NSLog(void *format, ...)
{
    const char *s = NULL;
    if (format)
    {
        const struct cf_constant_string_min *cs = format;
        if (cs->flags == 0x7c8 && cs->cstr)
            s = cs->cstr;
    }
    shim_iosim_nslog(s ? s : "(NSLog format object)");
    return 0;
}

static int shim_UIApplicationMain(int argc, char **argv, void *principalClass,
                                  void *delegateClassName)
{
    (void)argv;
    printf("[UIKit-lite] UIApplicationMain argc=%d principal=%p delegate=%p\n",
           argc, principalClass, delegateClassName);
    printf("[UIKit-lite] no window server attached yet; returning.\n");
    return 0;
}

static char shim_CFConstantStringClassReference[8];
static char shim_NSConcreteStackBlock[64];
static char shim_NSConcreteGlobalBlock[64];
static char shim_NSConcreteMallocBlock[64];

/* ---------- sysctl (small subset used by startup code) ---------- */

static int shim_sysctlbyname(const char *name, void *oldp, size_t *oldlenp,
                             void *newp, size_t newlen)
{
    (void)newp; (void)newlen;

    static char osversion[128];
    static char model[128] = "iosim-x86_64";
    static char machine[128] = "x86_64";
    static uint64_t memsize;
    static uint32_t ncpu;

    if (!name || !oldlenp)
        return EINVAL;

    const void *src = NULL;
    size_t srclen = 0;

    if (strcmp(name, "hw.memsize") == 0 ||
        strcmp(name, "hw.memsize_usable") == 0)
    {
        long pages = sysconf(_SC_PHYS_PAGES);
        long psize = sysconf(_SC_PAGESIZE);
        memsize = (pages > 0 && psize > 0) ? (uint64_t)pages * (uint64_t)psize
                                           : (uint64_t)4 << 30;
        src = &memsize;
        srclen = sizeof(memsize);
    }
    else if (strcmp(name, "hw.ncpu") == 0 ||
             strcmp(name, "hw.logicalcpu") == 0 ||
             strcmp(name, "hw.physicalcpu") == 0 ||
             strcmp(name, "hw.availablecpu") == 0)
    {
        long n = sysconf(_SC_NPROCESSORS_ONLN);
        ncpu = n > 0 ? (uint32_t)n : 1;
        src = &ncpu;
        srclen = sizeof(ncpu);
    }
    else if (strcmp(name, "kern.osversion") == 0)
    {
        snprintf(osversion, sizeof(osversion), "iosim 1.0");
        src = osversion;
        srclen = strlen(osversion) + 1;
    }
    else if (strcmp(name, "hw.model") == 0)
    {
        src = model;
        srclen = strlen(model) + 1;
    }
    else if (strcmp(name, "hw.machine") == 0 ||
             strcmp(name, "hw.product") == 0)
    {
        src = machine;
        srclen = strlen(machine) + 1;
    }
    else
    {
        return ENOENT;
    }

    if (!oldp)
    {
        *oldlenp = srclen;
        return 0;
    }
    if (*oldlenp < srclen)
    {
        *oldlenp = srclen;
        return ENOMEM;
    }
    memcpy(oldp, src, srclen);
    *oldlenp = srclen;
    return 0;
}

/* ---------- table ---------- */

#define SHIM(fn) { #fn, (void *)(uintptr_t)&shim_##fn }
#define SHIM_ALIAS(nm, fn) { nm, (void *)(uintptr_t)&shim_##fn }
#define SHIM_DIRECT(nm) { #nm, (void *)(uintptr_t)&nm }

static const struct iosim_shim shims[] = {
    SHIM(dyld_stub_binder),
    SHIM_ALIAS("_NSGetArgc", NSGetArgc),
    SHIM_ALIAS("_NSGetArgv", NSGetArgv),
    SHIM_ALIAS("_NSGetEnviron", NSGetEnviron),
    SHIM_ALIAS("_NSGetProgname", NSGetProgname),
    SHIM_ALIAS("_NSGetExecutablePath", NSGetExecutablePath),
    SHIM_ALIAS("getprogname", getprogname),
    SHIM_ALIAS("setprogname", setprogname),
    SHIM_ALIAS("__error", __error),
    SHIM_ALIAS("malloc_size", malloc_size),
    SHIM_ALIAS("malloc_default_zone", malloc_default_zone),
    SHIM_ALIAS("malloc_create_zone", malloc_create_zone),
    SHIM_ALIAS("malloc_zone_malloc", malloc_zone_malloc),
    SHIM_ALIAS("malloc_zone_calloc", malloc_zone_calloc),
    SHIM_ALIAS("malloc_zone_realloc", malloc_zone_realloc),
    SHIM_ALIAS("malloc_zone_free", malloc_zone_free),
    SHIM_ALIAS("malloc_zone_destroy", malloc_zone_destroy),
    SHIM_ALIAS("mach_absolute_time", mach_absolute_time),
    SHIM_ALIAS("mach_timebase_info", mach_timebase_info),
    SHIM_ALIAS("os_log_create", os_log_create),
    SHIM_ALIAS("os_log_type_enabled", os_log_type_enabled),
    SHIM_ALIAS("_os_log_impl", _os_log_impl),
    SHIM_ALIAS("_os_log_error_impl", _os_log_error_impl),
    SHIM_ALIAS("_os_log_fault_impl", _os_log_fault_impl),
    SHIM_ALIAS("_os_log_debug_impl", _os_log_debug_impl),
    SHIM_ALIAS("_os_log", _os_log),
    SHIM_ALIAS("os_retain", os_retain),
    SHIM_ALIAS("os_release", os_release),
    SHIM_ALIAS("sysctlbyname", sysctlbyname),
    SHIM_ALIAS("iosim_nslog", iosim_nslog),
    SHIM_ALIAS("NSLog", NSLog),
    SHIM_ALIAS("UIApplicationMain", UIApplicationMain),
    SHIM_ALIAS("__CFConstantStringClassReference", CFConstantStringClassReference),
    SHIM_ALIAS("_NSConcreteStackBlock", NSConcreteStackBlock),
    SHIM_ALIAS("_NSConcreteGlobalBlock", NSConcreteGlobalBlock),
    SHIM_ALIAS("_NSConcreteMallocBlock", NSConcreteMallocBlock),
    SHIM_DIRECT(iosim_fb_begin),
    SHIM_DIRECT(iosim_fb_release),
    SHIM_DIRECT(iosim_fb_clear),
    SHIM_DIRECT(iosim_fb_fill_rect),
    SHIM_DIRECT(iosim_fb_fill_round_rect),
    SHIM_DIRECT(iosim_fb_fill_circle),
    SHIM_DIRECT(iosim_fb_draw_line),
    SHIM_DIRECT(iosim_fb_fill_ellipse),
    SHIM_DIRECT(iosim_fb_fill_polygon),
    SHIM_DIRECT(iosim_fb_fill_linear_gradient),
    SHIM_DIRECT(iosim_fb_fill_linear_gradient_round_rect),
    SHIM_DIRECT(iosim_fb_blit_rgba),
    SHIM_DIRECT(iosim_fb_blit_rgba_scaled),
    SHIM_DIRECT(iosim_fb_width),
    SHIM_DIRECT(iosim_fb_height),
    SHIM_DIRECT(iosim_png_load),
    SHIM_DIRECT(iosim_fb_set_opacity),
    SHIM_DIRECT(__sincos_stret),
    SHIM_DIRECT(iosim_fb_text),
    SHIM_DIRECT(iosim_fb_text_width),
    SHIM_DIRECT(iosim_fb_font_text_width),
    SHIM_DIRECT(iosim_fb_font_text),
    SHIM_DIRECT(iosim_fb_font_metrics),
    SHIM_DIRECT(iosim_fb_present),
    SHIM_DIRECT(iosim_event_next),
    SHIM_DIRECT(iosim_dispatch_drain_main),
    SHIM_DIRECT(_Block_copy),
    SHIM_DIRECT(_Block_release),
    SHIM_DIRECT(_Block_object_assign),
    SHIM_DIRECT(_Block_object_dispose),
    SHIM_DIRECT(iosim_now),
    SHIM_DIRECT(malloc),
    SHIM_DIRECT(calloc),
    SHIM_DIRECT(realloc),
    SHIM_DIRECT(free),
    SHIM_DIRECT(strlen),
    SHIM_DIRECT(strcmp),
    SHIM_DIRECT(strncmp),
    SHIM_DIRECT(strcpy),
    SHIM_DIRECT(strncpy),
    SHIM_DIRECT(strcat),
    SHIM_DIRECT(memcpy),
    SHIM_DIRECT(memmove),
    SHIM_DIRECT(memset),
    SHIM_DIRECT(snprintf),
    SHIM_DIRECT(vsnprintf),
    SHIM_DIRECT(strtol),
    SHIM_DIRECT(strtod),
    SHIM_DIRECT(objc_msgSend),
    SHIM_DIRECT(objc_msgSendSuper2),
    SHIM_DIRECT(objc_msgSend_stret),
    SHIM_DIRECT(iosim_objc_alloc),
    SHIM_DIRECT(iosim_objc_class_of),
    SHIM_DIRECT(iosim_objc_superclass),
    SHIM_DIRECT(iosim_objc_is_kind_of),
    SHIM_DIRECT(iosim_objc_responds),
    SHIM_DIRECT(objc_opt_class),
    SHIM_DIRECT(objc_setProperty_nonatomic),
    SHIM_DIRECT(objc_setProperty_nonatomic_copy),
    SHIM_DIRECT(objc_setProperty_atomic),
    SHIM_DIRECT(objc_setProperty_atomic_copy),
    SHIM_DIRECT(objc_alloc_init),
    SHIM_DIRECT(objc_alloc),
    SHIM_DIRECT(objc_autorelease),
    SHIM_DIRECT(objc_retain),
    SHIM_DIRECT(objc_release),
    SHIM_DIRECT(objc_autoreleasePoolPush),
    SHIM_DIRECT(objc_autoreleasePoolPop),
    SHIM_DIRECT(objc_retain),
    SHIM_DIRECT(objc_release),
    SHIM_DIRECT(objc_getClass),
    SHIM_DIRECT(class_getName),
    SHIM_DIRECT(object_getClassName),
    SHIM_DIRECT(sel_registerName),
    SHIM_DIRECT(sel_getName),
    SHIM_DIRECT(_objc_empty_cache),
};

void *iosim_lookup_shim(const char *name)
{
    if (!name)
        return NULL;
    for (size_t i = 0; i < sizeof(shims) / sizeof(shims[0]); i++)
    {
        if (strcmp(shims[i].name, name) == 0)
            return shims[i].addr;
    }
    return iosim_services_lookup(name);
}

void *objc_opt_class(void *obj)
{
    return iosim_objc_normalize_class(obj);
}

struct iosim_sincos_result __sincos_stret(double x)
{
    struct iosim_sincos_result r;
    double s, c;
    sincos(x, &s, &c);
    r.sin_value = s;
    r.cos_value = c;
    return r;
}

double iosim_now(void)
{
    struct timespec ts;
    clock_gettime(CLOCK_MONOTONIC, &ts);
    return (double)ts.tv_sec + ts.tv_nsec / 1e9;
}

struct iosim_block_descriptor {
    unsigned long reserved;
    unsigned long size;
    void (*copy)(void *dst, const void *src);
    void (*dispose)(const void *src);
};

struct iosim_block_layout {
    void *isa;
    int flags;
    int reserved;
    void *invoke;
    struct iosim_block_descriptor *descriptor;
};

#define IOSIM_BLOCK_IS_GLOBAL  (1 << 28)
#define IOSIM_BLOCK_HAS_COPY_DISPOSE (1 << 25)
#define IOSIM_BLOCK_IS_HEAP (1 << 24)

void *_Block_copy(void *block)
{
    struct iosim_block_layout *b = block;
    if (!b)
        return NULL;
    if (b->flags & IOSIM_BLOCK_IS_GLOBAL)
        return block;
    if (b->flags & IOSIM_BLOCK_IS_HEAP)
        return block;
    if (!b->descriptor || b->descriptor->size < sizeof(struct iosim_block_layout))
        return block;
    struct iosim_block_layout *copy = malloc(b->descriptor->size);
    memcpy(copy, b, b->descriptor->size);
    copy->flags |= IOSIM_BLOCK_IS_HEAP;
    if ((b->flags & IOSIM_BLOCK_HAS_COPY_DISPOSE) && b->descriptor->copy)
        b->descriptor->copy(copy, b);
    return copy;
}

void _Block_object_assign(void *dest, const void *object, int flags)
{
    (void)flags;
    if (dest)
        *(const void **)dest = object;
}

void _Block_object_dispose(const void *object, int flags)
{
    (void)object; (void)flags;
}

void _Block_release(void *block)
{
    struct iosim_block_layout *b = block;
    if (!b || (b->flags & IOSIM_BLOCK_IS_GLOBAL) == 0)
    {
        if (!b)
            return;
    }
    if (!(b->flags & IOSIM_BLOCK_IS_HEAP))
        return;
    if ((b->flags & IOSIM_BLOCK_HAS_COPY_DISPOSE) && b->descriptor && b->descriptor->dispose)
        b->descriptor->dispose(b);
    free(b);
}
