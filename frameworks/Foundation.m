/* Foundation-lite: the collection, string, notification and timer surface
 * used by simulator apps. Built as an x86_64 Mach-O dylib at the canonical
 * install name. */

#include "foundation_lite.h"
#include <stdarg.h>

/* Empty collection literals (`@[]`, `@{}`) reference these globals instead
 * of sending a factory message. Foundation exports them on Apple platforms. */
id __NSArray0__;
id __NSDictionary0__;

__attribute__((constructor)) static void iosim_foundation_literal_globals(void)
{
    __NSArray0__ = [NSArray array];
    __NSDictionary0__ = [NSDictionary dictionary];
}

extern void *iosim_objc_alloc(void *cls);
extern void *iosim_objc_class_of(void *obj);
extern void *iosim_objc_superclass(void *cls);
extern int   iosim_objc_is_kind_of(void *obj, void *cls);
extern int   iosim_objc_responds(void *obj, void *sel);
extern void  iosim_nslog(const char *message);
extern int   iosim_dispatch_drain_main(void);
extern double iosim_now(void);
extern double iosim_wall_time(void);
extern int usleep(unsigned int usec);
extern long strtol(const char *s, char **end, int base);
extern double strtod(const char *s, char **end);
extern int pthread_main_np(void);
extern void *_Block_copy(void *block);
extern void _Block_release(void *block);
extern void *objc_msgSend(void *self, void *sel, ...);
extern void *objc_getClass(const char *name);
extern char *getenv(const char *name);
extern void *object_getClass(void *obj);
extern void *object_setClass(void *obj, void *cls);
extern void *objc_allocateClassPair(void *superclass, const char *name,
                                    unsigned long extraBytes);
extern void objc_registerClassPair(void *cls);
extern int class_addMethod(void *cls, void *sel, void *imp, const char *types);
extern void *class_getInstanceMethod(void *cls, void *sel);
extern void *class_getMethodImplementation(void *cls, void *sel);
extern const char *method_getTypeEncoding(void *method);
extern void *class_getSuperclass(void *cls);
extern void *sel_registerName(const char *name);
extern void *dispatch_get_global_queue(long priority, unsigned long flags);
extern void dispatch_async_f(void *queue, void *context,
                             void (*function)(void *));
extern int iosim_http_request(const char *url, const char *method,
                              const char *extra_headers, const void *body,
                              unsigned long body_len,
                              unsigned char **out_data,
                              unsigned long *out_len, int *out_status,
                              char **out_headers, char **out_error);
extern void iosim_http_free(void *pointer);
extern int iosim_regex_search(const char *pattern, const char *text,
                              int options, unsigned long **out_ranges,
                              unsigned long *out_matches,
                              unsigned long *out_groups, char **out_error);
extern void iosim_regex_free(void *pointer);

extern void *malloc(unsigned long size);
extern void free(void *pointer);
extern void *calloc(unsigned long n, unsigned long size);
extern void *realloc(void *ptr, unsigned long size);
extern void  free(void *ptr);
extern int   snprintf(char *buf, unsigned long size, const char *fmt, ...);
extern double strtod(const char *s, char **end);
extern long long strtoll(const char *s, char **end, int base);
extern char *strstr(const char *haystack, const char *needle);
extern int   iosim_fs_exists(const char *path);
extern int   iosim_fs_is_dir(const char *path);
extern long  iosim_fs_size(const char *path);
extern int   iosim_fs_read(const char *path, unsigned char **out,
                           unsigned long *out_len);
extern int   iosim_fs_write(const char *path, const void *bytes,
                            unsigned long len);
extern int   iosim_fs_remove(const char *path);
extern int   iosim_fs_rename(const char *from, const char *to);
extern int   iosim_fs_mkdir(const char *path, int intermediates);
extern int   iosim_fs_list(const char *path, char *out, unsigned long cap);
extern int   open(const char *path, int flags, ...);
extern long  read(int fd, void *buf, unsigned long count);
extern long  write(int fd, const void *buf, unsigned long count);
extern long long lseek(int fd, long long offset, int whence);
extern int   close(int fd);
extern int   fsync(int fd);
extern int   ftruncate(int fd, long long length);
extern unsigned long strlen(const char *s);
extern int   strcmp(const char *a, const char *b);
extern char *strcpy(char *dst, const char *src);
extern int   strncmp(const char *a, const char *b, unsigned long n);
extern char *strchr(const char *s, int c);
extern char *strrchr(const char *s, int c);
extern void *memcpy(void *dst, const void *src, unsigned long n);
extern int memcmp(const void *a, const void *b, unsigned long n);
extern int strcmp(const char *a, const char *b);
extern void *memchr(const void *s, int c, unsigned long n);
extern void *memset(void *dst, int c, unsigned long n);
extern int   memcmp(const void *a, const void *b, unsigned long n);
extern char *strstr(const char *haystack, const char *needle);

struct cf_constant_string {
    void *isa;
    unsigned int flags;
    unsigned int pad;
    const char *cstr;
    unsigned long length;
};

extern void *objc_getClass(const char *name);
extern const char *class_getName(void *cls);
extern char *getenv(const char *name);

static NSTimer *g_timers[64];
static int g_timer_count;


static char *iosim_utf16_to_utf8(const unsigned short *s, unsigned long n)
{
    if (!s)
        return (char *)"";
    char *out = malloc(n * 4 + 1);
    if (!out)
        return (char *)"";
    char *p = out;
    for (unsigned long i = 0; i < n; i++)
    {
        unsigned int c = s[i];
        if (c >= 0xD800 && c <= 0xDBFF && i + 1 < n)
        {
            unsigned int lo = s[i + 1];
            if (lo >= 0xDC00 && lo <= 0xDFFF)
            {
                c = 0x10000 + ((c - 0xD800) << 10) + (lo - 0xDC00);
                i++;
            }
        }
        if (c < 0x80)
            *p++ = (char)c;
        else if (c < 0x800)
        {
            *p++ = (char)(0xC0 | (c >> 6));
            *p++ = (char)(0x80 | (c & 0x3F));
        }
        else if (c < 0x10000)
        {
            *p++ = (char)(0xE0 | (c >> 12));
            *p++ = (char)(0x80 | ((c >> 6) & 0x3F));
            *p++ = (char)(0x80 | (c & 0x3F));
        }
        else
        {
            *p++ = (char)(0xF0 | (c >> 18));
            *p++ = (char)(0x80 | ((c >> 12) & 0x3F));
            *p++ = (char)(0x80 | ((c >> 6) & 0x3F));
            *p++ = (char)(0x80 | (c & 0x3F));
        }
    }
    *p = 0;
    return out;
}

const char *iosim_string_cstr(id string)
{
    if (!string)
        return "";
    struct cf_constant_string *cs = (struct cf_constant_string *)string;
    if (cs->flags == 0x7c8 && cs->cstr)
        return cs->cstr;
    if (cs->flags == 0x7d0 && cs->cstr)
        return iosim_utf16_to_utf8((const unsigned short *)cs->cstr,
                                   cs->length);
    if (((Class)iosim_objc_class_of(string)) &&
        iosim_objc_is_kind_of(string, objc_getClass("NSString")))
    {
        NSString *s = (NSString *)string;
        return s->_cstr ? s->_cstr : "";
    }
    return "";
}

static const char *obj_cstr(id obj)
{
    if (!obj)
        return "(null)";
    struct cf_constant_string *cs = (struct cf_constant_string *)obj;
    if (cs->flags == 0x7c8 && cs->cstr)
        return cs->cstr;
    if (cs->flags == 0x7d0 && cs->cstr)
        return iosim_utf16_to_utf8((const unsigned short *)cs->cstr,
                                   cs->length);
    if (iosim_objc_is_kind_of(obj, objc_getClass("NSString")))
        return ((NSString *)obj)->_cstr ? ((NSString *)obj)->_cstr : "";
    id desc = [obj description];
    if (desc && desc != obj)
        return obj_cstr(desc);
    return "?";
}

static int objects_equal(id a, id b)
{
    if (a == b)
        return 1;
    if (!a || !b)
        return 0;
    struct cf_constant_string *ca = (struct cf_constant_string *)a;
    struct cf_constant_string *cb = (struct cf_constant_string *)b;
    if (ca->flags == 0x7c8 && cb->flags == 0x7c8)
        return strcmp(ca->cstr, cb->cstr) == 0;
    if (iosim_objc_is_kind_of(a, objc_getClass("NSString")) ||
        iosim_objc_is_kind_of(b, objc_getClass("NSString")))
        return strcmp(iosim_string_cstr(a), iosim_string_cstr(b)) == 0;
    return [a isEqual:b] ? 1 : 0;
}


/* ---------------------------------------------------- key-value coding/observing */

id NSKeyValueChangeKindKey = @"NSKeyValueChangeKindKey";
id NSKeyValueChangeNewKey = @"NSKeyValueChangeNewKey";
id NSKeyValueChangeOldKey = @"NSKeyValueChangeOldKey";
id NSKeyValueChangeIndexesKey = @"NSKeyValueChangeIndexesKey";
id NSKeyValueChangeNotificationIsPriorKey = @"NSKeyValueChangeNotificationIsPriorKey";

#define KVC_KEY_MAX 192

static void kvc_capitalize(const char *key, char *out, unsigned long cap)
{
    unsigned long i = 0;
    if (!cap)
        return;
    for (; key && key[i] && i + 1 < cap; i++)
    {
        char c = key[i];
        if (i == 0 && c >= 'a' && c <= 'z')
            c = (char)(c - 'a' + 'A');
        out[i] = c;
    }
    out[i] = 0;
}

static id kvc_getter_value(id obj, SEL sel, const char *types)
{
    if (!types || !*types)
        return ((id (*)(id, SEL))objc_msgSend)(obj, sel);
    switch (types[0])
    {
    case '@':
    case '#':
        return ((id (*)(id, SEL))objc_msgSend)(obj, sel);
    case 'B':
        return [NSNumber numberWithBool:
            ((BOOL (*)(id, SEL))objc_msgSend)(obj, sel)];
    case 'c':
        return [NSNumber numberWithInt:
            ((signed char (*)(id, SEL))objc_msgSend)(obj, sel)];
    case 'C':
        return [NSNumber numberWithInt:
            ((unsigned char (*)(id, SEL))objc_msgSend)(obj, sel)];
    case 's':
        return [NSNumber numberWithInt:
            ((short (*)(id, SEL))objc_msgSend)(obj, sel)];
    case 'S':
        return [NSNumber numberWithInt:
            ((unsigned short (*)(id, SEL))objc_msgSend)(obj, sel)];
    case 'i':
        return [NSNumber numberWithInt:
            ((int (*)(id, SEL))objc_msgSend)(obj, sel)];
    case 'I':
        return [NSNumber numberWithLongLong:
            ((unsigned int (*)(id, SEL))objc_msgSend)(obj, sel)];
    case 'l':
    case 'q':
        return [NSNumber numberWithLongLong:
            ((long long (*)(id, SEL))objc_msgSend)(obj, sel)];
    case 'L':
    case 'Q':
        return [NSNumber numberWithLongLong:
            ((unsigned long long (*)(id, SEL))objc_msgSend)(obj, sel)];
    case 'f':
        return [NSNumber numberWithFloat:
            ((float (*)(id, SEL))objc_msgSend)(obj, sel)];
    case 'd':
        return [NSNumber numberWithDouble:
            ((double (*)(id, SEL))objc_msgSend)(obj, sel)];
    default:
        return nil;
    }
}

static SEL kvc_getter_sel(id obj, const char *key)
{
    char cap[KVC_KEY_MAX], buf[KVC_KEY_MAX + 16];
    kvc_capitalize(key, cap, sizeof(cap));
    snprintf(buf, sizeof(buf), "get%s", cap);
    if (iosim_objc_responds(obj, sel_registerName(buf)))
        return sel_registerName(buf);
    snprintf(buf, sizeof(buf), "%s", key);
    if (iosim_objc_responds(obj, sel_registerName(buf)))
        return sel_registerName(buf);
    snprintf(buf, sizeof(buf), "is%s", cap);
    if (iosim_objc_responds(obj, sel_registerName(buf)))
        return sel_registerName(buf);
    return 0;
}

static SEL kvc_setter_sel(id obj, const char *key)
{
    char cap[KVC_KEY_MAX], buf[KVC_KEY_MAX + 16];
    kvc_capitalize(key, cap, sizeof(cap));
    snprintf(buf, sizeof(buf), "set%s:", cap);
    if (iosim_objc_responds(obj, sel_registerName(buf)))
        return sel_registerName(buf);
    snprintf(buf, sizeof(buf), "_set%s:", cap);
    if (iosim_objc_responds(obj, sel_registerName(buf)))
        return sel_registerName(buf);
    return 0;
}

static const char *method_arg_type(const char *types)
{
    if (!types)
        return 0;
    const char *arg = strrchr(types, ':');
    if (!arg)
        return types;
    arg++;
    while (*arg >= '0' && *arg <= '9')
        arg++;
    return arg;
}

static void kvc_apply_setter(id obj, SEL sel, const char *types, id value)
{
    const char *arg = method_arg_type(types);
    char t = arg && *arg ? *arg : '@';
    if (t == '@' || t == '#')
    {
        ((void (*)(id, SEL, id))objc_msgSend)(obj, sel, value);
        return;
    }
    if (!value)
        return;
    switch (t)
    {
    case 'B':
        ((void (*)(id, SEL, BOOL))objc_msgSend)(obj, sel, [value boolValue]);
        break;
    case 'c':
    case 'C':
    case 's':
    case 'S':
    case 'i':
        ((void (*)(id, SEL, int))objc_msgSend)(obj, sel, [value intValue]);
        break;
    case 'I':
        ((void (*)(id, SEL, unsigned int))objc_msgSend)(obj, sel,
            (unsigned int)[value longLongValue]);
        break;
    case 'l':
    case 'q':
        ((void (*)(id, SEL, long long))objc_msgSend)(obj, sel,
            [value longLongValue]);
        break;
    case 'L':
    case 'Q':
        ((void (*)(id, SEL, unsigned long long))objc_msgSend)(obj, sel,
            (unsigned long long)[value longLongValue]);
        break;
    case 'f':
        ((void (*)(id, SEL, float))objc_msgSend)(obj, sel,
            [value floatValue]);
        break;
    case 'd':
        ((void (*)(id, SEL, double))objc_msgSend)(obj, sel,
            [value doubleValue]);
        break;
    default:
        break;
    }
}

/* KVO notification bookkeeping. Guest objects are not reference counted in
 * this runtime, so observation records are process-lifetime like the
 * associated objects Foundation installs. */
#define MAX_KVO_OBSERVATIONS 256
#define MAX_KVO_PENDING 64
#define MAX_KVO_SUBCLASSES 64
#define MAX_KVO_SETTERS 256

struct kvo_observation {
    void *object;
    void *observer;
    NSString *keyPath;
    NSString *key;
    void *context;
    unsigned long options;
    int active;
};
static struct kvo_observation g_kvo_observations[MAX_KVO_OBSERVATIONS];
static int g_kvo_nobservations;

struct kvo_pending {
    void *object;
    char key[KVC_KEY_MAX];
    id oldValue;
    int active;
};
static struct kvo_pending g_kvo_pending[MAX_KVO_PENDING];

struct kvo_subclass {
    void *original;
    void *subclass;
};
static struct kvo_subclass g_kvo_subclasses[MAX_KVO_SUBCLASSES];
static int g_kvo_nsubclasses;

struct kvo_setter {
    void *subclass;
    const char *selector;
    NSString *key;
};
static struct kvo_setter g_kvo_setters[MAX_KVO_SETTERS];
static int g_kvo_nsetters;

static struct kvo_pending *kvo_pending_find(void *object, const char *key)
{
    for (int i = MAX_KVO_PENDING - 1; i >= 0; i--)
    {
        struct kvo_pending *p = &g_kvo_pending[i];
        if (p->active && p->object == object && strcmp(p->key, key) == 0)
            return p;
    }
    return 0;
}

static struct kvo_pending *kvo_pending_push(void *object, const char *key,
                                            id oldValue)
{
    struct kvo_pending *p = kvo_pending_find(object, key);
    if (p)
        return p;
    for (int i = 0; i < MAX_KVO_PENDING; i++)
    {
        p = &g_kvo_pending[i];
        if (p->active)
            continue;
        p->active = 1;
        p->object = object;
        p->oldValue = oldValue;
        snprintf(p->key, sizeof(p->key), "%s", key);
        return p;
    }
    return 0;
}

static NSString *kvo_key_for_selector(void *subclass, void *sel)
{
    const char *name = (const char *)sel;
    for (int i = 0; i < g_kvo_nsetters; i++)
        if (g_kvo_setters[i].subclass == subclass &&
            strcmp(g_kvo_setters[i].selector, name) == 0)
            return g_kvo_setters[i].key;
    return nil;
}

static void kvo_remember_setter(void *subclass, void *sel, NSString *key)
{
    const char *name = (const char *)sel;
    for (int i = 0; i < g_kvo_nsetters; i++)
        if (g_kvo_setters[i].subclass == subclass &&
            strcmp(g_kvo_setters[i].selector, name) == 0)
            return;
    if (g_kvo_nsetters >= MAX_KVO_SETTERS)
        return;
    g_kvo_setters[g_kvo_nsetters].subclass = subclass;
    g_kvo_setters[g_kvo_nsetters].selector = name;
    g_kvo_setters[g_kvo_nsetters].key = key;
    g_kvo_nsetters++;
}

static void kvo_notify(void *object, NSString *key, id oldValue, id newValue,
                       int prior)
{
    const char *key_c = [key UTF8String];
    if (!key_c)
        return;
    for (int i = 0; i < g_kvo_nobservations; i++)
    {
        struct kvo_observation *o = &g_kvo_observations[i];
        if (!o->active || o->object != object)
            continue;
        if (prior && !(o->options & NSKeyValueObservingOptionPrior))
            continue;
        const char *kp = [o->keyPath UTF8String];
        if (!kp)
            continue;
        unsigned long n = 0;
        while (kp[n] && kp[n] != '.')
            n++;
        if (strlen(key_c) != n || strncmp(kp, key_c, n) != 0)
            continue;

        NSMutableDictionary *change = [NSMutableDictionary dictionary];
        [change setObject:[NSNumber numberWithInt:NSKeyValueChangeSetting]
                  forKey:NSKeyValueChangeKindKey];
        if (prior)
        {
            [change setObject:[NSNumber numberWithBool:YES]
                      forKey:NSKeyValueChangeNotificationIsPriorKey];
            if (o->options & NSKeyValueObservingOptionOld)
                [change setObject:(oldValue ? oldValue : (id)[NSNull null])
                          forKey:NSKeyValueChangeOldKey];
        }
        else
        {
            if (o->options & NSKeyValueObservingOptionNew)
                [change setObject:(newValue ? newValue : (id)[NSNull null])
                          forKey:NSKeyValueChangeNewKey];
            if (o->options & NSKeyValueObservingOptionOld)
                [change setObject:(oldValue ? oldValue : (id)[NSNull null])
                          forKey:NSKeyValueChangeOldKey];
        }
        void *observeSel =
            sel_registerName("observeValueForKeyPath:ofObject:change:context:");
        if (!iosim_objc_responds(o->observer, observeSel))
            continue;
        ((void (*)(id, SEL, id, id, id, void *))objc_msgSend)(
            o->observer, observeSel, o->keyPath, object, change, o->context);
    }
}

static void *kvo_class_imp(void *self, void *sel)
{
    (void)sel;
    return iosim_objc_superclass(iosim_objc_class_of(self));
}

static void *kvo_subclass_for(void *original)
{
    for (int i = 0; i < g_kvo_nsubclasses; i++)
        if (g_kvo_subclasses[i].original == original)
            return g_kvo_subclasses[i].subclass;
    if (g_kvo_nsubclasses >= MAX_KVO_SUBCLASSES)
        return original;
    char name[KVC_KEY_MAX];
    snprintf(name, sizeof(name), "NSKVONotifying_%s", class_getName(original));
    void *sub = objc_allocateClassPair(original, name, 0);
    if (!sub)
        return original;
    class_addMethod(sub, sel_registerName("class"), (void *)kvo_class_imp, "#@:");
    objc_registerClassPair(sub);
    g_kvo_subclasses[g_kvo_nsubclasses].original = original;
    g_kvo_subclasses[g_kvo_nsubclasses].subclass = sub;
    g_kvo_nsubclasses++;
    return sub;
}

#define KVO_SETTER_PROLOGUE(self_, cmd_)                                      \
    NSString *kvo_key_ = kvo_key_for_selector(iosim_objc_class_of(self_),     \
                                              cmd_);                          \
    ((void (*)(id, SEL, id))objc_msgSend)(self_,                              \
        sel_registerName("willChangeValueForKey:"), kvo_key_)

#define KVO_SETTER_EPILOGUE(self_, cmd_)                                      \
    ((void (*)(id, SEL, id))objc_msgSend)(self_,                              \
        sel_registerName("didChangeValueForKey:"), kvo_key_)

static void *kvo_original_setter(id self, SEL _cmd)
{
    return class_getMethodImplementation(
        iosim_objc_superclass(iosim_objc_class_of(self)), _cmd);
}

static void kvo_set_object(id self, SEL _cmd, id value)
{
    KVO_SETTER_PROLOGUE(self, _cmd);
    void *imp = kvo_original_setter(self, _cmd);
    ((void (*)(id, SEL, id))imp)(self, _cmd, value);
    KVO_SETTER_EPILOGUE(self, _cmd);
}

static void kvo_set_int(id self, SEL _cmd, int value)
{
    KVO_SETTER_PROLOGUE(self, _cmd);
    void *imp = kvo_original_setter(self, _cmd);
    ((void (*)(id, SEL, int))imp)(self, _cmd, value);
    KVO_SETTER_EPILOGUE(self, _cmd);
}

static void kvo_set_longlong(id self, SEL _cmd, long long value)
{
    KVO_SETTER_PROLOGUE(self, _cmd);
    void *imp = kvo_original_setter(self, _cmd);
    ((void (*)(id, SEL, long long))imp)(self, _cmd, value);
    KVO_SETTER_EPILOGUE(self, _cmd);
}

static void kvo_set_bool(id self, SEL _cmd, BOOL value)
{
    KVO_SETTER_PROLOGUE(self, _cmd);
    void *imp = kvo_original_setter(self, _cmd);
    ((void (*)(id, SEL, BOOL))imp)(self, _cmd, value);
    KVO_SETTER_EPILOGUE(self, _cmd);
}

static void kvo_set_float(id self, SEL _cmd, float value)
{
    KVO_SETTER_PROLOGUE(self, _cmd);
    void *imp = kvo_original_setter(self, _cmd);
    ((void (*)(id, SEL, float))imp)(self, _cmd, value);
    KVO_SETTER_EPILOGUE(self, _cmd);
}

static void kvo_set_double(id self, SEL _cmd, double value)
{
    KVO_SETTER_PROLOGUE(self, _cmd);
    void *imp = kvo_original_setter(self, _cmd);
    ((void (*)(id, SEL, double))imp)(self, _cmd, value);
    KVO_SETTER_EPILOGUE(self, _cmd);
}

static void kvo_set_point(id self, SEL _cmd, CGPoint value)
{
    KVO_SETTER_PROLOGUE(self, _cmd);
    void *imp = kvo_original_setter(self, _cmd);
    ((void (*)(id, SEL, CGPoint))imp)(self, _cmd, value);
    KVO_SETTER_EPILOGUE(self, _cmd);
}

static void kvo_set_size(id self, SEL _cmd, CGSize value)
{
    KVO_SETTER_PROLOGUE(self, _cmd);
    void *imp = kvo_original_setter(self, _cmd);
    ((void (*)(id, SEL, CGSize))imp)(self, _cmd, value);
    KVO_SETTER_EPILOGUE(self, _cmd);
}

static void kvo_set_rect(id self, SEL _cmd, CGRect value)
{
    KVO_SETTER_PROLOGUE(self, _cmd);
    void *imp = kvo_original_setter(self, _cmd);
    ((void (*)(id, SEL, CGRect))imp)(self, _cmd, value);
    KVO_SETTER_EPILOGUE(self, _cmd);
}

static void *kvo_wrapper_for_types(const char *types)
{
    const char *arg = method_arg_type(types);
    char t = arg && *arg ? *arg : '@';
    switch (t)
    {
    case '@':
    case '#':
        return (void *)kvo_set_object;
    case 'B':
    case 'c':
        return (void *)kvo_set_bool;
    case 'C':
    case 's':
    case 'S':
    case 'i':
    case 'I':
        return (void *)kvo_set_int;
    case 'l':
    case 'q':
    case 'L':
    case 'Q':
        return (void *)kvo_set_longlong;
    case 'f':
        return (void *)kvo_set_float;
    case 'd':
        return (void *)kvo_set_double;
    case '{':
        if (strncmp(arg, "{CGPoint", 8) == 0)
            return (void *)kvo_set_point;
        if (strncmp(arg, "{CGSize", 7) == 0)
            return (void *)kvo_set_size;
        if (strncmp(arg, "{CGRect", 7) == 0)
            return (void *)kvo_set_rect;
        return (void *)kvo_set_object;
    default:
        return (void *)kvo_set_object;
    }
}

static void kvo_install_setter(void *subclass, void *original, SEL setter,
                                NSString *key)
{
    void *method = class_getInstanceMethod(original, setter);
    if (!method)
        return;
    const char *types = method_getTypeEncoding(method);
    class_addMethod(subclass, setter, kvo_wrapper_for_types(types), types);
    kvo_remember_setter(subclass, setter, key);
}

static double kvc_operator_double(id value)
{
    if (!value)
        return 0;
    if ([value isKindOfClass:[NSNumber class]])
        return [value doubleValue];
    if (iosim_objc_responds(value, sel_registerName("doubleValue")))
        return ((double (*)(id, SEL))objc_msgSend)(
            value, sel_registerName("doubleValue"));
    return 0;
}

static void kvc_operator_unique_add(NSMutableArray *array, id value)
{
    if (!value)
        return;
    if (![array containsObject:value])
        [array addObject:value];
}

/* ------------------------------------------------------------- NSObject */

@implementation NSObject

+ (id)alloc { return iosim_objc_alloc(self); }
+ (id)new { return [[self alloc] init]; }
+ (Class)class { return self; }
- (id)init { return self; }
- (void)dealloc { }
- (id)retain { return self; }
- (void)release { }
- (id)autorelease { return self; }
- (unsigned long)retainCount { return 1; }
- (Class)class { return iosim_objc_class_of(self); }
- (Class)superclass { return iosim_objc_superclass(iosim_objc_class_of(self)); }
- (BOOL)isKindOfClass:(Class)cls { return (BOOL)iosim_objc_is_kind_of(self, cls); }
- (BOOL)isMemberOfClass:(Class)cls { return iosim_objc_class_of(self) == cls; }
- (BOOL)respondsToSelector:(SEL)sel { return (BOOL)iosim_objc_responds(self, sel); }
- (BOOL)isEqual:(id)other { return self == other; }
- (unsigned long)hash { return (unsigned long)(long)self; }
- (id)description { return [NSString stringWithUTF8String:"<NSObject>"]; }
- (void)performSelector:(SEL)selector withObject:(id)argument
{
    if (!selector)
        return;
    ((void (*)(id, SEL, id))objc_msgSend)(self, selector, argument);
}
- (void)performSelector:(SEL)selector withObject:(id)argument
             afterDelay:(double)delay
{
    if (!selector)
        return;
    NSTimer *timer = [NSTimer scheduledTimerWithTimeInterval:delay
                                                      target:self
                                                    selector:selector
                                                    userInfo:nil
                                                     repeats:NO];
    timer->_isPerform = YES;
    timer->_performArgument = argument;
}
+ (void)cancelPreviousPerformRequestsWithTarget:(id)target
                                       selector:(SEL)selector
                                         object:(id)argument
{
    for (int i = 0; i < g_timer_count; i++)
    {
        NSTimer *timer = g_timers[i];
        if (!timer || !timer->_isPerform || timer->_target != target)
            continue;
        if (selector && timer->_selector != selector)
            continue;
        if (argument && timer->_performArgument != argument)
            continue;
        [timer invalidate];
    }
}
+ (void)cancelPreviousPerformRequestsWithTarget:(id)target
{
    [self cancelPreviousPerformRequestsWithTarget:target
                                         selector:0
                                           object:0];
}

- (id)valueForKey:(NSString *)key
{
    const char *k = [key UTF8String];
    if (!k)
        return nil;
    if (strcmp(k, "self") == 0)
        return self;
    SEL getter = kvc_getter_sel(self, k);
    if (!getter)
        return nil;
    void *method = class_getInstanceMethod(iosim_objc_class_of(self), getter);
    const char *types = method ? method_getTypeEncoding(method) : 0;
    return kvc_getter_value(self, getter, types);
}

- (void)setValue:(id)value forKey:(NSString *)key
{
    const char *k = [key UTF8String];
    if (!k)
        return;
    SEL setter = kvc_setter_sel(self, k);
    if (!setter)
        return;
    void *method = class_getInstanceMethod(iosim_objc_class_of(self), setter);
    const char *types = method ? method_getTypeEncoding(method) : 0;
    kvc_apply_setter(self, setter, types, value);
}

- (id)valueForKeyPath:(NSString *)keyPath
{
    const char *p = [keyPath UTF8String];
    if (!p)
        return nil;
    if (p[0] == '@')
    {
        const char *dot = strchr(p, '.');
        unsigned long n = dot ? (unsigned long)(dot - p) : strlen(p);
        char op[64];
        if (n >= sizeof(op))
            return nil;
        memcpy(op, p, n);
        op[n] = 0;
        if (strcmp(op, "@count") == 0)
        {
            SEL countSel = sel_registerName("count");
            if (iosim_objc_responds(self, countSel))
                return [NSNumber numberWithLongLong:
                    ((unsigned long (*)(id, SEL))objc_msgSend)(self, countSel)];
            return [NSNumber numberWithInt:0];
        }
        if (!iosim_objc_responds(self, @selector(countByEnumeratingWithState:
                                                 objects:count:)))
            return nil;
        const char *rest = dot ? dot + 1 : 0;
        NSString *restKey = rest ? [NSString stringWithUTF8String:rest] : nil;
        NSMutableArray *values = [NSMutableArray array];
        for (id item in self)
        {
            id value = restKey ? [item valueForKeyPath:restKey] : item;
            if (value)
                [values addObject:value];
        }
        if (strcmp(op, "@sum") == 0 || strcmp(op, "@avg") == 0)
        {
            double sum = 0;
            for (id value in values)
                sum += kvc_operator_double(value);
            if (strcmp(op, "@avg") == 0)
                sum = [values count] ? sum / (double)[values count] : 0;
            return [NSNumber numberWithDouble:sum];
        }
        if (strcmp(op, "@max") == 0 || strcmp(op, "@min") == 0)
        {
            id best = nil;
            double bestValue = 0;
            BOOL wantMax = strcmp(op, "@max") == 0;
            for (id value in values)
            {
                double number = kvc_operator_double(value);
                if (!best || (wantMax ? number > bestValue
                                      : number < bestValue))
                {
                    best = value;
                    bestValue = number;
                }
            }
            return best;
        }
        if (strcmp(op, "@distinctUnionOfObjects") == 0)
        {
            NSMutableArray *result = [NSMutableArray array];
            for (id value in values)
                kvc_operator_unique_add(result, value);
            return result;
        }
        if (strcmp(op, "@unionOfArrays") == 0 ||
            strcmp(op, "@distinctUnionOfArrays") == 0)
        {
            BOOL distinct = op[1] == 'd';
            NSMutableArray *result = [NSMutableArray array];
            for (id value in values)
            {
                if (![value isKindOfClass:[NSArray class]])
                    continue;
                for (id element in (NSArray *)value)
                {
                    if (distinct)
                        kvc_operator_unique_add(result, element);
                    else
                        [result addObject:element];
                }
            }
            return result;
        }
        return nil;
    }
    const char *dot = strchr(p, '.');
    if (!dot)
        return [self valueForKey:keyPath];
    unsigned long n = (unsigned long)(dot - p);
    if (n >= KVC_KEY_MAX)
        return nil;
    char first[KVC_KEY_MAX];
    memcpy(first, p, n);
    first[n] = 0;
    id value = [self valueForKey:[NSString stringWithUTF8String:first]];
    if (!value)
        return nil;
    return [value valueForKeyPath:[NSString stringWithUTF8String:dot + 1]];
}

- (void)setValue:(id)value forKeyPath:(NSString *)keyPath
{
    const char *p = [keyPath UTF8String];
    if (!p)
        return;
    const char *dot = strchr(p, '.');
    if (!dot)
    {
        [self setValue:value forKey:keyPath];
        return;
    }
    unsigned long n = (unsigned long)(dot - p);
    if (n >= KVC_KEY_MAX)
        return;
    char first[KVC_KEY_MAX];
    memcpy(first, p, n);
    first[n] = 0;
    id target = [self valueForKey:[NSString stringWithUTF8String:first]];
    if (!target)
        return;
    [target setValue:value
          forKeyPath:[NSString stringWithUTF8String:dot + 1]];
}

- (id)dictionaryWithValuesForKeys:(NSArray *)keys
{
    NSMutableDictionary *result = [NSMutableDictionary dictionary];
    for (id key in keys)
    {
        id value = [self valueForKey:key];
        [result setObject:(value ? value : (id)[NSNull null]) forKey:key];
    }
    return result;
}

- (void)setValuesForKeysWithDictionary:(NSDictionary *)keyedValues
{
    for (id key in keyedValues)
        [self setValue:[keyedValues objectForKey:key] forKey:key];
}

- (void)addObserver:(NSObject *)observer forKeyPath:(NSString *)keyPath
            options:(NSKeyValueObservingOptions)options context:(void *)context
{
    if (!observer || !keyPath)
        return;
    const char *p = [keyPath UTF8String];
    if (!p)
        return;
    unsigned long n = 0;
    while (p[n] && p[n] != '.')
        n++;
    if (n >= KVC_KEY_MAX)
        return;
    char root[KVC_KEY_MAX];
    memcpy(root, p, n);
    root[n] = 0;
    NSString *key = [NSString stringWithUTF8String:root];

    void *cls = iosim_objc_class_of(self);
    if (strncmp(class_getName(cls), "NSKVONotifying_", 15) == 0)
        cls = iosim_objc_superclass(cls);
    void *sub = kvo_subclass_for(cls);
    if (iosim_objc_class_of(self) != sub)
        object_setClass(self, sub);
    SEL setter = kvc_setter_sel(self, root);
    if (setter)
        kvo_install_setter(sub, cls, setter, key);

    struct kvo_observation *o = 0;
    for (int i = 0; i < MAX_KVO_OBSERVATIONS; i++)
    {
        if (!g_kvo_observations[i].active)
        {
            o = &g_kvo_observations[i];
            break;
        }
    }
    if (!o)
        return;
    o->object = self;
    o->observer = observer;
    o->keyPath = keyPath;
    o->key = key;
    o->context = context;
    o->options = options;
    o->active = 1;
    if (g_kvo_nobservations < MAX_KVO_OBSERVATIONS)
        g_kvo_nobservations++;

    if (options & NSKeyValueObservingOptionInitial)
        kvo_notify(self, key, nil, [self valueForKey:key], 0);
}

- (void)removeObserver:(NSObject *)observer forKeyPath:(NSString *)keyPath
{
    for (int i = 0; i < g_kvo_nobservations; i++)
    {
        struct kvo_observation *o = &g_kvo_observations[i];
        if (o->active && o->object == self && o->observer == observer &&
            [o->keyPath isEqual:keyPath])
            o->active = 0;
    }
}

- (void)removeObserver:(NSObject *)observer forKeyPath:(NSString *)keyPath
               context:(void *)context
{
    for (int i = 0; i < g_kvo_nobservations; i++)
    {
        struct kvo_observation *o = &g_kvo_observations[i];
        if (o->active && o->object == self && o->observer == observer &&
            o->context == context && [o->keyPath isEqual:keyPath])
            o->active = 0;
    }
}

- (void)willChangeValueForKey:(NSString *)key
{
    const char *k = [key UTF8String];
    if (!k)
        return;
    struct kvo_pending *p = kvo_pending_find(self, k);
    if (!p)
        p = kvo_pending_push(self, k, [self valueForKey:key]);
    if (p)
        kvo_notify(self, key, p->oldValue, nil, 1);
}

- (void)didChangeValueForKey:(NSString *)key
{
    const char *k = [key UTF8String];
    if (!k)
        return;
    struct kvo_pending *p = kvo_pending_find(self, k);
    if (!p)
    {
        id current = [self valueForKey:key];
        kvo_notify(self, key, current, current, 0);
        return;
    }
    id newValue = [self valueForKey:key];
    p->active = 0;
    kvo_notify(self, key, p->oldValue, newValue, 0);
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object
                        change:(NSDictionary *)change context:(void *)context
{
    (void)keyPath;
    (void)object;
    (void)change;
    (void)context;
}

+ (BOOL)automaticallyNotifiesObserversForKey:(NSString *)key
{
    (void)key;
    return YES;
}
@end

/* ------------------------------------------------------------- NSString */

static char *copy_cstr(const char *s, unsigned long *length)
{
    if (!s)
        s = "";
    unsigned long n = strlen(s);
    char *out = malloc(n + 1);
    if (!out)
        return 0;
    memcpy(out, s, n + 1);
    if (length)
        *length = n;
    return out;
}

static void append_bytes(char **buf, unsigned long *cap, unsigned long *len,
                         const char *s, unsigned long n)
{
    if (*len + n + 1 > *cap)
    {
        unsigned long next = *cap ? *cap : 128;
        while (next < *len + n + 1)
            next *= 2;
        char *grown = realloc(*buf, next);
        if (!grown)
            return;
        *buf = grown;
        *cap = next;
    }
    memcpy(*buf + *len, s, n);
    *len += n;
    (*buf)[*len] = 0;
}

static char *format_va(const char *fmt, va_list ap)
{
    char *out = 0;
    unsigned long cap = 0, len = 0;
    append_bytes(&out, &cap, &len, "", 0);
    const char *p = fmt;
    while (*p)
    {
        if (*p != '%')
        {
            append_bytes(&out, &cap, &len, p, 1);
            p++;
            continue;
        }
        if (p[1] == '%')
        {
            append_bytes(&out, &cap, &len, "%", 1);
            p += 2;
            continue;
        }
        const char *start = p;
        p++;
        while (*p && !( *p == '@' || *p == 's' || *p == 'd' || *p == 'i' ||
                        *p == 'u' || *p == 'o' || *p == 'x' || *p == 'X' ||
                        *p == 'f' || *p == 'e' || *p == 'g' || *p == 'c' ||
                        *p == 'p'))
            p++;
        char conv = *p ? *p : 'd';
        if (*p)
            p++;
        char spec[32];
        unsigned long sn = (unsigned long)(p - start);
        if (sn >= sizeof(spec))
            sn = sizeof(spec) - 1;
        memcpy(spec, start, sn);
        spec[sn] = 0;
        char tmp[256];
        tmp[0] = 0;
        if (conv == '@')
        {
            id obj = va_arg(ap, id);
            const char *s = obj_cstr(obj);
            append_bytes(&out, &cap, &len, s, strlen(s));
        }
        else if (conv == 's')
        {
            const char *s = va_arg(ap, const char *);
            snprintf(tmp, sizeof(tmp), "%s", s ? s : "(null)");
            append_bytes(&out, &cap, &len, tmp, strlen(tmp));
        }
        else if (conv == 'd' || conv == 'i')
        {
            if (spec[sn - 1] == 'd' || spec[sn - 1] == 'i')
            {
                /* pick the argument type from the length modifier */
            }
            long long v;
            if (strncmp(spec, "%%lld", 5) == 0 || strncmp(spec, "%lld", 4) == 0)
                v = va_arg(ap, long long);
            else if (spec[1] == 'l')
                v = va_arg(ap, long);
            else
                v = va_arg(ap, int);
            snprintf(tmp, sizeof(tmp), spec, v);
            append_bytes(&out, &cap, &len, tmp, strlen(tmp));
        }
        else if (conv == 'f' || conv == 'e' || conv == 'g')
        {
            double v = va_arg(ap, double);
            snprintf(tmp, sizeof(tmp), spec, v);
            append_bytes(&out, &cap, &len, tmp, strlen(tmp));
        }
        else if (conv == 'c')
        {
            int v = va_arg(ap, int);
            snprintf(tmp, sizeof(tmp), spec, v);
            append_bytes(&out, &cap, &len, tmp, strlen(tmp));
        }
        else
        {
            void *v = va_arg(ap, void *);
            snprintf(tmp, sizeof(tmp), spec, v);
            append_bytes(&out, &cap, &len, tmp, strlen(tmp));
        }
    }
    return out;
}

@implementation NSString
+ (id)stringWithUTF8String:(const char *)s
{
    return [[[self alloc] initWithUTF8String:s] autorelease];
}
+ (id)stringWithString:(id)other
{
    return [[[self alloc] initWithUTF8String:iosim_string_cstr(other)] autorelease];
}
+ (id)stringWithFormat:(id)format, ...
{
    va_list ap;
    va_start(ap, format);
    char *buf = format_va(iosim_string_cstr(format), ap);
    va_end(ap);
    NSString *s = [[self alloc] initWithUTF8String:buf ? buf : ""];
    free(buf);
    return s;
}
- (id)initWithUTF8String:(const char *)s
{
    self = [super init];
    if (self)
        _cstr = copy_cstr(s, &_length);
    return self;
}
- (id)initWithFormat:(id)format, ...
{
    va_list ap;
    va_start(ap, format);
    char *buf = format_va(iosim_string_cstr(format), ap);
    va_end(ap);
    self = [self initWithUTF8String:buf ? buf : ""];
    free(buf);
    return self;
}
- (const char *)UTF8String { return iosim_string_cstr(self); }
- (unsigned long)length { return strlen(iosim_string_cstr(self)); }
- (unsigned short)characterAtIndex:(unsigned long)index
{
    const char *chars = iosim_string_cstr(self);
    unsigned long len = strlen(chars);
    if (index >= len)
        return 0;
    return (unsigned short)(unsigned char)chars[index];
}
- (BOOL)isEqual:(id)other
{
    if (other == self)
        return YES;
    if (!other)
        return NO;
    return (BOOL)(strcmp(iosim_string_cstr(self), iosim_string_cstr(other)) == 0);
}
- (BOOL)isEqualToString:(id)other { return [self isEqual:other]; }
- (long)compare:(NSString *)other
{
    const char *a = [self UTF8String];
    const char *b = [other UTF8String];
    int result = strcmp(a ? a : "", b ? b : "");
    return result < 0 ? NSOrderedAscending
                      : (result > 0 ? NSOrderedDescending : NSOrderedSame);
}
- (long)caseInsensitiveCompare:(NSString *)other
{
    const char *a = [self UTF8String];
    const char *b = [other UTF8String];
    a = a ? a : "";
    b = b ? b : "";
    while (*a && *b)
    {
        int ca = *a, cb = *b;
        if (ca >= 'A' && ca <= 'Z')
            ca += 'a' - 'A';
        if (cb >= 'A' && cb <= 'Z')
            cb += 'a' - 'A';
        if (ca != cb)
            return ca < cb ? NSOrderedAscending : NSOrderedDescending;
        a++;
        b++;
    }
    return *a == *b ? NSOrderedSame
                    : (*a ? NSOrderedDescending : NSOrderedAscending);
}
- (unsigned long)hash
{
    const char *chars = iosim_string_cstr(self);
    unsigned long len = strlen(chars);
    unsigned long h = 5381;
    for (unsigned long i = 0; i < len; i++)
        h = (h * 33) + (unsigned char)chars[i];
    return h;
}
- (id)description { return self; }
- (id)stringByAppendingString:(id)other
{
    const char *a = iosim_string_cstr(self);
    const char *b = iosim_string_cstr(other);
    unsigned long na = strlen(a), nb = strlen(b);
    char *buf = malloc(na + nb + 1);
    if (!buf)
        return [NSString stringWithUTF8String:a];
    memcpy(buf, a, na);
    memcpy(buf + na, b, nb + 1);
    NSString *s = [[NSString alloc] initWithUTF8String:buf];
    free(buf);
    return s;
}
- (id)uppercaseString
{
    char *buf = copy_cstr(iosim_string_cstr(self), 0);
    if (!buf)
        return self;
    for (char *p = buf; *p; p++)
        if (*p >= 'a' && *p <= 'z')
            *p -= 32;
    return [[[NSString alloc] initWithUTF8String:buf] autorelease];
}
- (id)lowercaseString
{
    char *buf = copy_cstr(iosim_string_cstr(self), 0);
    if (!buf)
        return self;
    for (char *p = buf; *p; p++)
        if (*p >= 'A' && *p <= 'Z')
            *p += 32;
    return [[[NSString alloc] initWithUTF8String:buf] autorelease];
}
- (id)substringToIndex:(unsigned long)index
{
    const char *chars = iosim_string_cstr(self);
    unsigned long len = strlen(chars);
    if (index > len)
        index = len;
    char *buf = malloc(index + 1);
    if (!buf)
        return self;
    memcpy(buf, chars, index);
    buf[index] = 0;
    NSString *s = [[NSString alloc] initWithUTF8String:buf];
    free(buf);
    return s;
}
- (id)substringFromIndex:(unsigned long)index
{
    const char *chars = iosim_string_cstr(self);
    unsigned long len = strlen(chars);
    if (index > len)
        index = len;
    return [NSString stringWithUTF8String:chars + index];
}
- (id)substringWithRange:(NSRange)range
{
    const char *chars = iosim_string_cstr(self);
    unsigned long len = strlen(chars);
    if (range.location > len)
        return @"";
    unsigned long length = range.length;
    if (range.location + length > len)
        length = len - range.location;
    char *buffer = malloc(length + 1);
    if (!buffer)
        return @"";
    memcpy(buffer, chars + range.location, length);
    buffer[length] = 0;
    NSString *result = [NSString stringWithUTF8String:buffer];
    free(buffer);
    return result;
}
- (BOOL)hasPrefix:(id)prefix
{
    const char *p = iosim_string_cstr(prefix);
    unsigned long n = strlen(p);
    const char *chars = iosim_string_cstr(self);
    return (BOOL)(n <= strlen(chars) && strncmp(chars, p, n) == 0);
}
- (BOOL)hasSuffix:(id)suffix
{
    const char *s = iosim_string_cstr(suffix);
    unsigned long n = strlen(s);
    const char *chars = iosim_string_cstr(self);
    unsigned long len = strlen(chars);
    return (BOOL)(n <= len && strcmp(chars + len - n, s) == 0);
}
- (id)componentsSeparatedByString:(id)separator
{
    const char *sep = iosim_string_cstr(separator);
    unsigned long sn = strlen(sep);
    NSMutableArray *result = [NSMutableArray array];
    if (!sn)
    {
        [result addObject:self];
        return result;
    }
    const char *chars = iosim_string_cstr(self);
    const char *start = chars;
    for (const char *p = chars; ; p++)
    {
        if (strncmp(p, sep, sn) == 0)
        {
            unsigned long n = (unsigned long)(p - start);
            char *tmp = malloc(n + 1);
            memcpy(tmp, start, n);
            tmp[n] = 0;
            NSString *piece = [[NSString alloc] initWithUTF8String:tmp];
            free(tmp);
            [result addObject:piece];
            start = p + sn;
            p += sn - 1;
        }
        else if (!*p)
        {
            [result addObject:[NSString stringWithUTF8String:start]];
            break;
        }
    }
    return result;
}
- (id)stringByReplacingOccurrencesOfString:(id)target withString:(id)replacement
{
    const char *t = iosim_string_cstr(target);
    const char *r = iosim_string_cstr(replacement);
    unsigned long tn = strlen(t), rn = strlen(r);
    if (!tn)
        return self;
    char *out = 0;
    unsigned long cap = 0, len = 0;
    const char *p = iosim_string_cstr(self);
    while (*p)
    {
        if (strncmp(p, t, tn) == 0)
        {
            append_bytes(&out, &cap, &len, r, rn);
            p += tn;
        }
        else
        {
            append_bytes(&out, &cap, &len, p, 1);
            p++;
        }
    }
    NSString *s = [[NSString alloc] initWithUTF8String:out ? out : ""];
    free(out);
    return s;
}
- (id)stringByAppendingPathComponent:(id)component
{
    const char *base = iosim_string_cstr(self);
    const char *comp = iosim_string_cstr(component);
    unsigned long bn = strlen(base), cn = strlen(comp);
    char *buf = malloc(bn + cn + 2);
    if (!buf)
        return self;
    memcpy(buf, base, bn);
    unsigned long n = bn;
    while (n > 1 && buf[n - 1] == '/')
        n--;
    if (n && buf[n - 1] != '/')
        buf[n++] = '/';
    memcpy(buf + n, comp, cn);
    n += cn;
    buf[n] = 0;
    NSString *path = [[NSString alloc] initWithUTF8String:buf];
    free(buf);
    return path;
}
- (id)stringByAppendingPathExtension:(id)extension
{
    const char *base = iosim_string_cstr(self);
    const char *ext = iosim_string_cstr(extension);
    if (!ext || !ext[0])
        return self;
    unsigned long bn = strlen(base), en = strlen(ext);
    char *buf = malloc(bn + en + 2);
    if (!buf)
        return self;
    memcpy(buf, base, bn);
    unsigned long n = bn;
    if (n == 0 || buf[n - 1] != '.')
        buf[n++] = '.';
    memcpy(buf + n, ext, en);
    n += en;
    buf[n] = 0;
    NSString *path = [[NSString alloc] initWithUTF8String:buf];
    free(buf);
    return path;
}
- (id)lastPathComponent
{
    const char *s = iosim_string_cstr(self);
    unsigned long n = strlen(s);
    while (n > 1 && s[n - 1] == '/')
        n--;
    unsigned long start = n;
    while (start > 0 && s[start - 1] != '/')
        start--;
    char buf[1024];
    unsigned long len = n - start;
    if (len >= sizeof(buf))
        len = sizeof(buf) - 1;
    memcpy(buf, s + start, len);
    buf[len] = 0;
    return [NSString stringWithUTF8String:buf];
}
- (id)pathExtension
{
    const char *name = iosim_string_cstr([self lastPathComponent]);
    const char *dot = 0;
    for (const char *p = name; *p; p++)
        if (*p == '.')
            dot = p;
    if (!dot || dot == name)
        return @"";
    return [NSString stringWithUTF8String:dot + 1];
}
- (id)stringByDeletingLastPathComponent
{
    const char *s = iosim_string_cstr(self);
    unsigned long n = strlen(s);
    while (n > 1 && s[n - 1] == '/')
        n--;
    while (n > 0 && s[n - 1] != '/')
        n--;
    while (n > 1 && s[n - 1] == '/')
        n--;
    char buf[1024];
    if (n >= sizeof(buf))
        n = sizeof(buf) - 1;
    memcpy(buf, s, n);
    buf[n] = 0;
    if (n == 0)
        return @"";
    return [NSString stringWithUTF8String:buf];
}
- (id)stringByDeletingPathExtension
{
    const char *s = iosim_string_cstr(self);
    unsigned long n = strlen(s);
    unsigned long slash = n;
    for (unsigned long i = n; i > 0; i--)
        if (s[i - 1] == '/')
        {
            slash = i - 1;
            break;
        }
    unsigned long dot = n;
    for (unsigned long i = n; i > slash + 1; i--)
        if (s[i - 1] == '.')
        {
            dot = i - 1;
            break;
        }
    if (dot == n)
        return self;
    char buf[1024];
    unsigned long len = dot;
    if (len >= sizeof(buf))
        len = sizeof(buf) - 1;
    memcpy(buf, s, len);
    buf[len] = 0;
    return [NSString stringWithUTF8String:buf];
}
- (id)dataUsingEncoding:(unsigned long)encoding
{
    (void)encoding;
    const char *chars = iosim_string_cstr(self);
    return [NSData dataWithBytes:chars length:strlen(chars)];
}
- (id)initWithData:(id)data encoding:(unsigned long)encoding
{
    (void)encoding;
    self = [super init];
    if (self && data)
    {
        const char *bytes = (const char *)[data bytes];
        _cstr = copy_cstr(bytes, &_length);
    }
    return self;
}
- (BOOL)containsString:(id)needle
{
    const char *n = iosim_string_cstr(needle);
    if (!n || !*n)
        return NO;
    return strstr(iosim_string_cstr(self), n) != 0;
}
- (id)stringByTrimmingCharactersInSet:(NSCharacterSet *)set
{
    const char *s = iosim_string_cstr(self);
    unsigned long len = strlen(s);
    unsigned long start = 0, end = len;
    while (start < end && [set characterIsMember:(unsigned short)(unsigned char)s[start]])
        start++;
    while (end > start &&
           [set characterIsMember:(unsigned short)(unsigned char)s[end - 1]])
        end--;
    char *buf = malloc(end - start + 1);
    if (!buf)
        return self;
    memcpy(buf, s + start, end - start);
    buf[end - start] = 0;
    id result = [[[NSString alloc] initWithUTF8String:buf] autorelease];
    free(buf);
    return result;
}
- (id)stringByReplacingCharactersInRange:(NSRange)range withString:(id)replacement
{
    const char *s = iosim_string_cstr(self);
    const char *r = iosim_string_cstr(replacement);
    unsigned long len = strlen(s);
    if (range.location > len)
        range.location = len;
    if (range.location + range.length > len)
        range.length = len - range.location;
    unsigned long rlen = r ? strlen(r) : 0;
    char *buf = malloc(len - range.length + rlen + 1);
    if (!buf)
        return self;
    memcpy(buf, s, range.location);
    if (rlen)
        memcpy(buf + range.location, r, rlen);
    strcpy(buf + range.location + rlen, s + range.location + range.length);
    id result = [[[NSString alloc] initWithUTF8String:buf] autorelease];
    free(buf);
    return result;
}
- (NSRange)rangeOfString:(id)needle
{
    const char *s = iosim_string_cstr(self);
    const char *n = iosim_string_cstr(needle);
    if (!n || !*n)
        return NSMakeRange(NSNotFound, 0);
    const char *found = strstr(s, n);
    if (!found)
        return NSMakeRange(NSNotFound, 0);
    return NSMakeRange((unsigned long)(found - s), strlen(n));
}
- (id)capitalizedString
{
    char *buf = copy_cstr(iosim_string_cstr(self), 0);
    if (!buf)
        return self;
    int start = 1;
    for (char *p = buf; *p; p++)
    {
        char c = *p;
        if (c >= 'A' && c <= 'Z')
            c += 32;
        if (start && c >= 'a' && c <= 'z')
            c -= 32;
        *p = c;
        start = (c < 'a' || c > 'z') && (c < 'A' || c > 'Z');
    }
    id result = [[[NSString alloc] initWithUTF8String:buf] autorelease];
    free(buf);
    return result;
}
static int hex_digit(char c)
{
    if (c >= '0' && c <= '9')
        return c - '0';
    if (c >= 'a' && c <= 'f')
        return c - 'a' + 10;
    if (c >= 'A' && c <= 'F')
        return c - 'A' + 10;
    return -1;
}
- (id)stringByRemovingPercentEncoding
{
    const char *s = iosim_string_cstr(self);
    unsigned long len = strlen(s);
    char *buf = malloc(len + 1);
    if (!buf)
        return self;
    unsigned long out = 0;
    for (unsigned long i = 0; i < len; i++)
    {
        if (s[i] == '%' && i + 2 < len)
        {
            int hi = hex_digit(s[i + 1]), lo = hex_digit(s[i + 2]);
            if (hi >= 0 && lo >= 0)
            {
                buf[out++] = (char)((hi << 4) | lo);
                i += 2;
                continue;
            }
        }
        buf[out++] = s[i];
    }
    buf[out] = 0;
    id result = [[[NSString alloc] initWithUTF8String:buf] autorelease];
    free(buf);
    return result;
}
- (id)stringByAddingPercentEncodingWithAllowedCharacters:
    (NSCharacterSet *)allowedCharacters
{
    const unsigned char *s = (const unsigned char *)iosim_string_cstr(self);
    unsigned long len = strlen((const char *)s);
    char *buf = malloc(len * 3 + 1);
    if (!buf)
        return self;
    static const char digits[] = "0123456789ABCDEF";
    unsigned long out = 0;
    for (unsigned long i = 0; i < len; i++)
    {
        unsigned char c = s[i];
        if (c >= 0x80 ||
            (allowedCharacters && [allowedCharacters characterIsMember:c]))
        {
            if (c >= 0x80)
            {
                buf[out++] = '%';
                buf[out++] = digits[c >> 4];
                buf[out++] = digits[c & 15];
            }
            else
                buf[out++] = (char)c;
        }
        else
        {
            buf[out++] = '%';
            buf[out++] = digits[c >> 4];
            buf[out++] = digits[c & 15];
        }
    }
    buf[out] = 0;
    id result = [[[NSString alloc] initWithUTF8String:buf] autorelease];
    free(buf);
    return result;
}
- (id)stringByAddingPercentEscapesUsingEncoding:(unsigned long)encoding
{
    (void)encoding;
    return [self stringByAddingPercentEncodingWithAllowedCharacters:
        [NSCharacterSet URLQueryAllowedCharacterSet]];
}
- (id)stringByReplacingPercentEscapesUsingEncoding:(unsigned long)encoding
{
    (void)encoding;
    return [self stringByRemovingPercentEncoding];
}
- (long)integerValue { return strtol(iosim_string_cstr(self), 0, 10); }
- (int)intValue { return (int)[self integerValue]; }
- (double)doubleValue { return strtod(iosim_string_cstr(self), 0); }
- (float)floatValue { return (float)[self doubleValue]; }
- (BOOL)boolValue
{
    const char *s = iosim_string_cstr(self);
    while (*s == ' ' || *s == '\t' || *s == '\n' || *s == '\r')
        s++;
    if (*s == 'Y' || *s == 'y' || *s == 'T' || *s == 't')
        return YES;
    return *s >= '1' && *s <= '9';
}
@end

static id character_set_from_cstr(const char *chars)
{
    NSCharacterSet *set = [[NSCharacterSet alloc] init];
    set->_cstr = copy_cstr(chars, &set->_length);
    return [set autorelease];
}

@implementation NSCharacterSet
+ (id)whitespaceCharacterSet { return character_set_from_cstr(" \t"); }
+ (id)whitespaceAndNewlineCharacterSet { return character_set_from_cstr(" \t\n\r\v\f"); }
+ (id)newlineCharacterSet { return character_set_from_cstr("\n\r"); }
+ (id)alphanumericCharacterSet
{
    char chars[63];
    int n = 0;
    for (char c = 'a'; c <= 'z'; c++) chars[n++] = c;
    for (char c = 'A'; c <= 'Z'; c++) chars[n++] = c;
    for (char c = '0'; c <= '9'; c++) chars[n++] = c;
    chars[n] = 0;
    return character_set_from_cstr(chars);
}
+ (id)decimalDigitCharacterSet { return character_set_from_cstr("0123456789"); }
+ (id)letterCharacterSet
{
    char chars[53];
    int n = 0;
    for (char c = 'a'; c <= 'z'; c++) chars[n++] = c;
    for (char c = 'A'; c <= 'Z'; c++) chars[n++] = c;
    chars[n] = 0;
    return character_set_from_cstr(chars);
}
+ (id)characterSetWithCharactersInString:(id)string
{
    return character_set_from_cstr(iosim_string_cstr(string));
}
+ (id)URLQueryAllowedCharacterSet
{
    return character_set_from_cstr(
        "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"
        "0123456789-._~!$&'()*+,;=:@/?");
}
+ (id)URLPathAllowedCharacterSet
{
    return character_set_from_cstr(
        "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"
        "0123456789-._~!$&'()*+,;=:@/");
}
+ (id)URLHostAllowedCharacterSet
{
    return character_set_from_cstr(
        "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"
        "0123456789-._~!$&'()*+,;=:");
}
+ (id)URLFragmentAllowedCharacterSet
{
    return character_set_from_cstr(
        "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"
        "0123456789-._~!$&'()*+,;=:@/?");
}
+ (id)URLUserAllowedCharacterSet
{
    return character_set_from_cstr(
        "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"
        "0123456789-._~!$&'()*+,;=");
}
+ (id)URLPasswordAllowedCharacterSet
{
    return character_set_from_cstr(
        "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"
        "0123456789-._~!$&'()*+,;=:");
}
- (BOOL)characterIsMember:(unsigned short)character
{
    if (character == 0)
        return NO;
    return _cstr && strchr(_cstr, (int)character) != 0;
}
- (id)mutableCopy
{
    NSMutableCharacterSet *copy = [[NSMutableCharacterSet alloc] init];
    copy->_cstr = _cstr ? copy_cstr(_cstr, &copy->_length) : 0;
    return copy;
}
@end

@implementation NSMutableCharacterSet
- (void)addCharactersInString:(id)string
{
    const char *add = iosim_string_cstr(string);
    if (!add)
        return;
    unsigned long alen = strlen(add);
    unsigned long old = _cstr ? strlen(_cstr) : 0;
    char *buf = malloc(old + alen + 1);
    if (!buf)
        return;
    if (_cstr)
        memcpy(buf, _cstr, old);
    unsigned long out = old;
    for (unsigned long i = 0; i < alen; i++)
        if (!_cstr || !strchr(_cstr, add[i]))
            buf[out++] = add[i];
    buf[out] = 0;
    free(_cstr);
    _cstr = buf;
    _length = out;
}
- (void)removeCharactersInString:(id)string
{
    const char *remove = iosim_string_cstr(string);
    if (!_cstr || !remove)
        return;
    unsigned long out = 0;
    for (unsigned long i = 0; _cstr[i]; i++)
        if (!strchr(remove, _cstr[i]))
            _cstr[out++] = _cstr[i];
    _cstr[out] = 0;
    _length = out;
}
@end

@implementation NSAttributedString
- (id)initWithString:(id)string
{
    self = [super init];
    if (self)
        _string = string;
    return self;
}
- (id)initWithString:(id)string attributes:(id)attributes
{
    self = [self initWithString:string];
    if (self)
        _attributes = attributes;
    return self;
}
- (id)string { return _string; }
- (unsigned long)length { return _string ? [_string length] : 0; }
- (id)attributesAtIndex:(unsigned long)index effectiveRange:(NSRange *)range
{
    (void)index;
    if (range)
        *range = NSMakeRange(0, [self length]);
    return _attributes ? _attributes : [NSDictionary dictionary];
}
@end

static id mutable_attribute_copy(id attributes)
{
    NSMutableDictionary *copy = [NSMutableDictionary dictionary];
    if (!attributes)
        return copy;
    NSArray *keys = [attributes allKeys];
    for (unsigned long i = 0; i < [keys count]; i++)
    {
        id key = [keys objectAtIndex:i];
        [copy setObject:[attributes objectForKey:key] forKey:key];
    }
    return copy;
}

@implementation NSMutableAttributedString
- (id)initWithString:(id)string
{
    self = [super initWithString:string];
    if (self)
        _attributes = [NSMutableDictionary dictionary];
    return self;
}
- (id)initWithString:(id)string attributes:(id)attributes
{
    self = [super initWithString:string];
    if (self)
        _attributes = mutable_attribute_copy(attributes);
    return self;
}
- (void)addAttribute:(id)name value:(id)value range:(NSRange)range
{
    (void)range;
    if (!_attributes)
        _attributes = [NSMutableDictionary dictionary];
    [(NSMutableDictionary *)_attributes setObject:value forKey:name];
}
- (void)addAttributes:(id)attributes range:(NSRange)range
{
    (void)range;
    if (!_attributes)
        _attributes = [NSMutableDictionary dictionary];
    NSArray *keys = [attributes allKeys];
    for (unsigned long i = 0; i < [keys count]; i++)
    {
        id key = [keys objectAtIndex:i];
        [(NSMutableDictionary *)_attributes
            setObject:[attributes objectForKey:key] forKey:key];
    }
}
- (void)setAttributes:(id)attributes range:(NSRange)range
{
    (void)range;
    _attributes = mutable_attribute_copy(attributes);
}
- (void)replaceCharactersInRange:(NSRange)range withString:(id)string
{
    _string = [_string stringByReplacingCharactersInRange:range
                                               withString:string];
}
- (void)appendAttributedString:(id)other
{
    if (!other)
        return;
    _string = _string ? [_string stringByAppendingString:[other string]]
                      : [other string];
}
@end

@implementation NSScanner
+ (id)scannerWithString:(id)string
{
    return [[[self alloc] initWithString:string] autorelease];
}
- (id)initWithString:(id)string
{
    self = [super init];
    if (self)
    {
        _string = string;
        _caseSensitive = YES;
        _skipsWhitespace = YES;
    }
    return self;
}
- (id)string { return _string; }
- (unsigned long)scanLocation { return _location; }
- (void)setScanLocation:(unsigned long)location
{
    const char *text = [_string UTF8String];
    unsigned long length = text ? strlen(text) : 0;
    _location = location > length ? length : location;
}
- (BOOL)isAtEnd
{
    const char *text = [_string UTF8String];
    if (!text)
        return YES;
    unsigned long i = _location;
    if (_skipsWhitespace)
        while (text[i] == ' ' || text[i] == '\t' || text[i] == '\n' ||
               text[i] == '\r')
            i++;
    return text[i] == 0;
}
- (BOOL)scanString:(id)string intoString:(id *)result
{
    const char *text = [_string UTF8String];
    const char *needle = [string UTF8String];
    if (!text || !needle)
        return NO;
    unsigned long i = _location;
    if (_skipsWhitespace)
        while (text[i] == ' ' || text[i] == '\t' || text[i] == '\n' ||
               text[i] == '\r')
            i++;
    unsigned long n = strlen(needle);
    if (strncmp(text + i, needle, n) != 0)
        return NO;
    _location = i + n;
    if (result)
        *result = string;
    return YES;
}
- (BOOL)scanLongLong:(long long *)result
{
    const char *text = [_string UTF8String];
    if (!text)
        return NO;
    unsigned long i = _location;
    if (_skipsWhitespace)
        while (text[i] == ' ' || text[i] == '\t' || text[i] == '\n' ||
               text[i] == '\r')
            i++;
    char *end = 0;
    long long value = strtoll(text + i, &end, 10);
    if (end == text + i)
        return NO;
    _location = (unsigned long)(end - text);
    if (result)
        *result = value;
    return YES;
}
- (BOOL)scanInt:(int *)result
{
    long long value = 0;
    if (![self scanLongLong:&value])
        return NO;
    if (result)
        *result = (int)value;
    return YES;
}
- (BOOL)scanDouble:(double *)result
{
    const char *text = [_string UTF8String];
    if (!text)
        return NO;
    unsigned long i = _location;
    if (_skipsWhitespace)
        while (text[i] == ' ' || text[i] == '\t' || text[i] == '\n' ||
               text[i] == '\r')
            i++;
    char *end = 0;
    double value = strtod(text + i, &end);
    if (end == text + i)
        return NO;
    _location = (unsigned long)(end - text);
    if (result)
        *result = value;
    return YES;
}
- (BOOL)scanUpToString:(id)stop intoString:(id *)result
{
    const char *text = [_string UTF8String];
    const char *needle = [stop UTF8String];
    if (!text || !needle)
        return NO;
    unsigned long i = _location;
    if (_skipsWhitespace)
        while (text[i] == ' ' || text[i] == '\t' || text[i] == '\n' ||
               text[i] == '\r')
            i++;
    const char *found = strstr(text + i, needle);
    unsigned long end = found ? (unsigned long)(found - text) : strlen(text);
    if (end == i)
        return NO;
    char *buffer = malloc(end - i + 1);
    if (!buffer)
        return NO;
    memcpy(buffer, text + i, end - i);
    buffer[end - i] = 0;
    _location = end;
    if (result)
        *result = [NSString stringWithUTF8String:buffer];
    free(buffer);
    return YES;
}
@end

@implementation NSMutableString
+ (id)string { return [[[self alloc] init] autorelease]; }
- (void)appendString:(id)string
{
    const char *s = iosim_string_cstr(string);
    unsigned long n = strlen(s);
    char *buf = malloc(_length + n + 1);
    memcpy(buf, _cstr ? _cstr : "", _length);
    memcpy(buf + _length, s, n + 1);
    free(_cstr);
    _cstr = buf;
    _length += n;
}
- (void)setString:(id)string
{
    free(_cstr);
    _cstr = copy_cstr(iosim_string_cstr(string), &_length);
}
@end

/* ------------------------------------------------------------- NSNumber */

@implementation NSIndexPath
+ (id)indexPathForRow:(long)row inSection:(long)section
{
    NSIndexPath *path = [[self alloc] init];
    path->_row = row;
    path->_section = section;
    path->_indexes[0] = section;
    path->_indexes[1] = row;
    path->_length = 2;
    return path;
}
+ (id)indexPathForItem:(long)item inSection:(long)section
{
    return [self indexPathForRow:item inSection:section];
}
- (long)row
{
    return _length >= 2 ? _indexes[_length - 1] : _row;
}
- (long)section
{
    return _length >= 1 ? _indexes[0] : _section;
}
- (long)item { return [self row]; }
- (long)length { return _length > 0 ? _length : 2; }
- (long)indexAtPosition:(unsigned long)position
{
    if (position < (unsigned long)[self length])
        return _indexes[position];
    return 0;
}
- (id)indexPathByAddingIndex:(long)index
{
    NSIndexPath *path = [[NSIndexPath alloc] init];
    int length = (int)[self length];
    if (length > 8)
        length = 8;
    for (int i = 0; i < length; i++)
        path->_indexes[i] = _indexes[i];
    if (length < 8)
    {
        path->_indexes[length] = index;
        length++;
    }
    path->_length = length;
    return path;
}
- (id)indexPathByRemovingLastIndex
{
    NSIndexPath *path = [[NSIndexPath alloc] init];
    int length = (int)[self length];
    if (length > 0)
        length--;
    for (int i = 0; i < length; i++)
        path->_indexes[i] = _indexes[i];
    path->_length = length;
    return path;
}
- (long)compare:(NSIndexPath *)other
{
    long leftLength = [self length];
    long rightLength = other ? [other length] : 0;
    long common = leftLength < rightLength ? leftLength : rightLength;
    for (long i = 0; i < common; i++)
    {
        long left = [self indexAtPosition:i];
        long right = [other indexAtPosition:i];
        if (left < right)
            return -1;
        if (left > right)
            return 1;
    }
    if (leftLength < rightLength)
        return -1;
    if (leftLength > rightLength)
        return 1;
    return 0;
}
- (void)getIndexes:(long *)indexes
{
    if (!indexes)
        return;
    for (int i = 0; i < [self length]; i++)
        indexes[i] = _indexes[i];
}
- (BOOL)isEqual:(id)other
{
    if (!other || ![other isKindOfClass:[NSIndexPath class]])
        return NO;
    return [self compare:other] == 0;
}
- (unsigned long)hash
{
    unsigned long hash = 5381;
    for (int i = 0; i < [self length]; i++)
        hash = hash * 33 + (unsigned long)_indexes[i];
    return hash;
}
- (id)description
{
    return [NSString stringWithFormat:
        @"<NSIndexPath: %p> {length = %ld, path = %ld - %ld}",
        self, [self length], [self section], [self row]];
}
@end

@implementation NSNumber
+ (id)numberWithInt:(int)value { return [self numberWithLongLong:value]; }
+ (id)numberWithInteger:(long)value { return [self numberWithLongLong:value]; }
+ (id)numberWithLongLong:(long long)value
{
    NSNumber *n = [[self alloc] init];
    n->_ival = value;
    n->_kind = 0;
    return n;
}
+ (id)numberWithBool:(BOOL)value
{
    NSNumber *n = [[self alloc] init];
    n->_ival = value ? 1 : 0;
    n->_kind = 2;
    return n;
}
+ (id)numberWithFloat:(float)value { return [self numberWithDouble:value]; }
+ (id)numberWithDouble:(double)value
{
    NSNumber *n = [[self alloc] init];
    n->_dval = value;
    n->_kind = 1;
    return n;
}
- (int)intValue { return self->_kind == 1 ? (int)_dval : (int)_ival; }
- (long)integerValue { return self->_kind == 1 ? (long)_dval : (long)_ival; }
- (long long)longLongValue { return self->_kind == 1 ? (long long)_dval : _ival; }
- (BOOL)boolValue { return [self intValue] != 0; }
- (float)floatValue { return self->_kind == 1 ? (float)_dval : (float)_ival; }
- (double)doubleValue { return self->_kind == 1 ? _dval : (double)_ival; }
- (id)stringValue
{
    char buf[64];
    if (_kind == 1)
        snprintf(buf, sizeof(buf), "%g", _dval);
    else
        snprintf(buf, sizeof(buf), "%lld", _ival);
    return [NSString stringWithUTF8String:buf];
}
- (id)description { return [self stringValue]; }
- (BOOL)isEqual:(id)other
{
    if (!other || ![other isKindOfClass:[NSNumber class]])
        return NO;
    return ((NSNumber *)other)->_kind == 1 ? [self doubleValue] == [(NSNumber *)other doubleValue]
                                           : [self longLongValue] == [(NSNumber *)other longLongValue];
}
- (unsigned long)hash { return (unsigned long)[self longLongValue]; }
@end

/* -------------------------------------------------------------- NSArray */

@implementation NSSortDescriptor
+ (id)sortDescriptorWithKey:(id)key ascending:(BOOL)ascending
{
    return [[[self alloc] initWithKey:key ascending:ascending] autorelease];
}
+ (id)sortDescriptorWithKey:(id)key ascending:(BOOL)ascending
                   selector:(SEL)selector
{
    NSSortDescriptor *descriptor =
        [[[self alloc] initWithKey:key ascending:ascending] autorelease];
    descriptor->_selector = selector;
    return descriptor;
}
- (id)initWithKey:(id)key ascending:(BOOL)ascending
{
    self = [super init];
    if (self)
    {
        _key = key;
        _ascending = ascending;
    }
    return self;
}
- (id)key { return _key; }
- (BOOL)ascending { return _ascending; }
- (SEL)selector { return _selector; }
- (long)compareObject:(id)first toObject:(id)second
{
    id a = _key ? [first valueForKey:_key] : first;
    id b = _key ? [second valueForKey:_key] : second;
    if (_selector)
        return ((long (*)(id, SEL, id))objc_msgSend)(a, _selector, b);
    if ([a isKindOfClass:[NSString class]] &&
        [b isKindOfClass:[NSString class]])
        return [(NSString *)a compare:(NSString *)b];
    if ([a isKindOfClass:[NSNumber class]] &&
        [b isKindOfClass:[NSNumber class]])
    {
        double da = [a doubleValue], db = [b doubleValue];
        return da < db ? NSOrderedAscending
                       : (da > db ? NSOrderedDescending : NSOrderedSame);
    }
    if (iosim_objc_responds(a, @selector(compare:)))
        return ((long (*)(id, SEL, id))objc_msgSend)(a, @selector(compare:), b);
    return NSOrderedSame;
}
@end

static long sort_descriptors_compare(id first, id second, NSArray *descriptors)
{
    for (unsigned long i = 0; i < [descriptors count]; i++)
    {
        NSSortDescriptor *descriptor = [descriptors objectAtIndex:i];
        long result = [descriptor compareObject:first toObject:second];
        if (result != NSOrderedSame)
            return [descriptor ascending] ? result : -result;
    }
    return NSOrderedSame;
}

static void sort_array_descriptors(NSMutableArray *array, NSArray *descriptors)
{
    for (unsigned long i = 1; i < array->_count; i++)
    {
        id item = array->_items[i];
        long j = (long)i - 1;
        while (j >= 0 &&
               sort_descriptors_compare(array->_items[j], item, descriptors) >
                   NSOrderedSame)
        {
            array->_items[j + 1] = array->_items[j];
            j--;
        }
        array->_items[j + 1] = item;
    }
}

static void sort_array_selector(NSMutableArray *array, SEL selector)
{
    for (unsigned long i = 1; i < array->_count; i++)
    {
        id item = array->_items[i];
        long j = (long)i - 1;
        while (j >= 0 && ((long (*)(id, SEL, id))objc_msgSend)(
                             array->_items[j], selector, item) > NSOrderedSame)
        {
            array->_items[j + 1] = array->_items[j];
            j--;
        }
        array->_items[j + 1] = item;
    }
}

/* ---------------------------------------------------------- regular expressions */

static NSString *regex_string_from_bytes(const char *text, unsigned long start,
                                         unsigned long length)
{
    char *buffer = malloc(length + 1);
    if (!buffer)
        return @"";
    if (text && length)
        memcpy(buffer, text + start, length);
    buffer[length] = 0;
    NSString *string = [NSString stringWithUTF8String:buffer];
    free(buffer);
    return string;
}

@implementation NSTextCheckingResult
+ (id)resultWithRanges:(NSRange *)ranges count:(unsigned long)count
{
    NSTextCheckingResult *result = [[self alloc] init];
    result->_ranges = malloc(sizeof(NSRange) * count);
    if (result->_ranges && ranges)
        memcpy(result->_ranges, ranges, sizeof(NSRange) * count);
    result->_rangeCount = count;
    return result;
}
- (NSRange)range { return [self rangeAtIndex:0]; }
- (NSRange)rangeAtIndex:(unsigned long)index
{
    if (!_ranges || index >= _rangeCount)
        return NSMakeRange((unsigned long)-1, 0);
    return _ranges[index];
}
- (unsigned long)numberOfRanges { return _rangeCount; }
@end

@implementation NSRegularExpression
+ (id)regularExpressionWithPattern:(id)pattern options:(unsigned long)options
                             error:(id *)error
{
    return [[self alloc] initWithPattern:pattern options:options error:error];
}
- (id)initWithPattern:(id)pattern options:(unsigned long)options
                error:(id *)error
{
    self = [super init];
    if (self)
    {
        _pattern = pattern;
        _options = options;
        _groups = 0;
        if (error)
            *error = nil;
    }
    return self;
}
- (id)pattern { return _pattern; }
- (unsigned long)options { return _options; }
- (unsigned long)numberOfCaptureGroups
{
    return _groups > 0 ? _groups - 1 : 0;
}
- (id)matchesInString:(id)string options:(unsigned long)options
                range:(NSRange)range
{
    const char *text = [string UTF8String];
    unsigned long text_length = text ? strlen(text) : 0;
    if (!text || range.location > text_length)
        return [NSArray array];
    unsigned long offset = range.location;
    unsigned long *raw = 0;
    unsigned long matches = 0, groups = 0;
    char *service_error = 0;
    if (iosim_regex_search([_pattern UTF8String], text + offset,
                           (int)(_options | options), &raw, &matches, &groups,
                           &service_error) != 0)
    {
        if (service_error)
            iosim_regex_free(service_error);
        return [NSArray array];
    }
    if (groups)
        _groups = groups;
    NSMutableArray *results = [NSMutableArray array];
    for (unsigned long m = 0; m < matches; m++)
    {
        NSRange *ranges = malloc(sizeof(NSRange) * groups);
        for (unsigned long g = 0; g < groups; g++)
        {
            unsigned long location = raw[(m * groups + g) * 2];
            unsigned long length = raw[(m * groups + g) * 2 + 1];
            ranges[g] = location == (unsigned long)-1
                            ? NSMakeRange((unsigned long)-1, 0)
                            : NSMakeRange(offset + location, length);
        }
        [results addObject:[NSTextCheckingResult resultWithRanges:ranges
                                                            count:groups]];
        free(ranges);
    }
    iosim_regex_free(raw);
    if (service_error)
        iosim_regex_free(service_error);
    return results;
}
- (id)firstMatchInString:(id)string options:(unsigned long)options
                   range:(NSRange)range
{
    NSArray *matches = [self matchesInString:string options:options
                                       range:range];
    return [matches count] ? [matches objectAtIndex:0] : nil;
}
- (id)stringByReplacingMatchesInString:(id)string options:(unsigned long)options
                                 range:(NSRange)range
                          withTemplate:(id)template
{
    const char *text = [string UTF8String];
    if (!text)
        return string;
    unsigned long text_length = strlen(text);
    unsigned long offset = range.location < text_length ? range.location : 0;
    unsigned long *raw = 0;
    unsigned long matches = 0, groups = 0;
    char *service_error = 0;
    if (iosim_regex_search([_pattern UTF8String], text + offset,
                           (int)(_options | options), &raw, &matches, &groups,
                           &service_error) != 0)
    {
        if (service_error)
            iosim_regex_free(service_error);
        return string;
    }
    if (groups)
        _groups = groups;
    const char *templ = [template UTF8String];
    NSMutableString *output = [NSMutableString string];
    unsigned long cursor = 0;
    for (unsigned long m = 0; m < matches; m++)
    {
        unsigned long match_start = raw[(m * groups) * 2];
        unsigned long match_length = raw[(m * groups) * 2 + 1];
        if (match_start < cursor)
            continue;
        [output appendString:regex_string_from_bytes(text, cursor,
                                                     match_start - cursor)];
        for (const char *p = templ; p && *p; )
        {
            if (*p == '\\' && p[1])
            {
                [output appendString:regex_string_from_bytes(p + 1, 0, 1)];
                p += 2;
                continue;
            }
            if (*p == '$' && p[1] >= '0' && p[1] <= '9')
            {
                unsigned long group = (unsigned long)(p[1] - '0');
                if (group < groups)
                {
                    unsigned long location = raw[(m * groups + group) * 2];
                    unsigned long length = raw[(m * groups + group) * 2 + 1];
                    if (location != (unsigned long)-1)
                        [output appendString:regex_string_from_bytes(
                                                 text, location, length)];
                }
                p += 2;
                continue;
            }
            [output appendString:regex_string_from_bytes(p, 0, 1)];
            p++;
        }
        cursor = match_start + match_length;
    }
    [output appendString:regex_string_from_bytes(text, cursor,
                                                 text_length - cursor)];
    iosim_regex_free(raw);
    if (service_error)
        iosim_regex_free(service_error);
    return output;
}
@end

/* ------------------------------------------------------------ predicates */

typedef struct {
    const char *p;
    id object;
} pred_parser;

typedef struct {
    id value;
    int is_nil;
    int valid;
} pred_value;

static void pred_skip(pred_parser *parser)
{
    while (*parser->p == ' ' || *parser->p == '\t' || *parser->p == '\n' ||
           *parser->p == '\r')
        parser->p++;
}

static int pred_word(pred_parser *parser, const char *word)
{
    pred_skip(parser);
    const char *p = parser->p;
    for (const char *w = word; *w; w++, p++)
    {
        char a = *p, b = *w;
        if (a >= 'A' && a <= 'Z')
            a += 'a' - 'A';
        if (b >= 'A' && b <= 'Z')
            b += 'a' - 'A';
        if (a != b)
            return 0;
    }
    if ((*p >= 'a' && *p <= 'z') || (*p >= 'A' && *p <= 'Z') ||
        (*p >= '0' && *p <= '9') || *p == '_')
        return 0;
    parser->p = p;
    return 1;
}

static pred_value pred_invalid_value(void)
{
    pred_value value;
    value.value = nil;
    value.is_nil = 1;
    value.valid = 0;
    return value;
}

static pred_value pred_parse_operand(pred_parser *parser);

static pred_value pred_parse_operand(pred_parser *parser)
{
    pred_skip(parser);
    pred_value result = pred_invalid_value();
    if (*parser->p == '\'' || *parser->p == '"')
    {
        char quote = *parser->p++;
        unsigned long cap = 32, length = 0;
        char *buffer = malloc(cap);
        while (*parser->p && *parser->p != quote)
        {
            char c = *parser->p++;
            if (c == '\\' && *parser->p)
                c = *parser->p++;
            if (length + 2 > cap)
            {
                cap *= 2;
                buffer = realloc(buffer, cap);
            }
            buffer[length++] = c;
        }
        if (*parser->p == quote)
            parser->p++;
        if (!buffer)
            return result;
        buffer[length] = 0;
        result.value = [NSString stringWithUTF8String:buffer];
        result.is_nil = 0;
        result.valid = 1;
        free(buffer);
        return result;
    }
    if (*parser->p == '{')
    {
        parser->p++;
        NSMutableArray *items = [NSMutableArray array];
        for (;;)
        {
            pred_value item = pred_parse_operand(parser);
            if (!item.valid)
                return pred_invalid_value();
            [items addObject:item.is_nil ? [NSNull null] : item.value];
            pred_skip(parser);
            if (*parser->p == ',')
            {
                parser->p++;
                continue;
            }
            if (*parser->p == '}')
            {
                parser->p++;
                break;
            }
            return pred_invalid_value();
        }
        result.value = items;
        result.is_nil = 0;
        result.valid = 1;
        return result;
    }
    if ((*parser->p >= '0' && *parser->p <= '9') ||
        (*parser->p == '-' && parser->p[1] >= '0' && parser->p[1] <= '9') ||
        (*parser->p == '.' && parser->p[1] >= '0' && parser->p[1] <= '9'))
    {
        char *end = 0;
        double number = strtod(parser->p, &end);
        if (end == parser->p)
            return result;
        parser->p = end;
        result.value = [NSNumber numberWithDouble:number];
        result.is_nil = 0;
        result.valid = 1;
        return result;
    }
    const char *start = parser->p;
    while (*parser->p && *parser->p != ' ' && *parser->p != '\t' &&
           *parser->p != '\n' && *parser->p != '\r' && *parser->p != '(' &&
           *parser->p != ')' && *parser->p != ',' && *parser->p != '}' &&
           *parser->p != '=' && *parser->p != '!' && *parser->p != '<' &&
           *parser->p != '>')
        parser->p++;
    unsigned long length = (unsigned long)(parser->p - start);
    if (!length)
        return result;
    char name[256];
    if (length >= sizeof(name))
        return result;
    memcpy(name, start, length);
    name[length] = 0;
    if (strcmp(name, "nil") == 0 || strcmp(name, "NULL") == 0)
    {
        result.is_nil = 1;
        result.valid = 1;
        return result;
    }
    if (strcmp(name, "YES") == 0 || strcmp(name, "TRUE") == 0 ||
        strcmp(name, "true") == 0)
    {
        result.value = [NSNumber numberWithBool:YES];
        result.is_nil = 0;
        result.valid = 1;
        return result;
    }
    if (strcmp(name, "NO") == 0 || strcmp(name, "FALSE") == 0 ||
        strcmp(name, "false") == 0)
    {
        result.value = [NSNumber numberWithBool:NO];
        result.is_nil = 0;
        result.valid = 1;
        return result;
    }
    if (strcmp(name, "SELF") == 0)
    {
        result.value = parser->object;
        result.is_nil = parser->object == nil;
        result.valid = 1;
        return result;
    }
    NSString *key = [NSString stringWithUTF8String:name];
    result.value = [parser->object valueForKeyPath:key];
    result.is_nil = result.value == nil;
    result.valid = 1;
    return result;
}

static int pred_is_number(pred_value value, double *out)
{
    if (value.is_nil || ![value.value isKindOfClass:[NSNumber class]])
        return 0;
    if (out)
        *out = [value.value doubleValue];
    return 1;
}

static BOOL pred_equal_values(pred_value first, pred_value second)
{
    if (first.is_nil || second.is_nil)
        return first.is_nil && second.is_nil;
    if ([first.value isKindOfClass:[NSString class]] &&
        [second.value isKindOfClass:[NSString class]])
        return [(NSString *)first.value
            isEqualToString:(NSString *)second.value];
    if ([first.value isKindOfClass:[NSNumber class]] &&
        [second.value isKindOfClass:[NSNumber class]])
        return [first.value doubleValue] == [second.value doubleValue];
    if ([first.value isKindOfClass:[NSArray class]] &&
        [second.value isKindOfClass:[NSArray class]])
    {
        NSArray *a = (NSArray *)first.value;
        NSArray *b = (NSArray *)second.value;
        if ([a count] != [b count])
            return NO;
        for (unsigned long i = 0; i < [a count]; i++)
            if (![[a objectAtIndex:i] isEqual:[b objectAtIndex:i]])
                return NO;
        return YES;
    }
    return first.value == second.value;
}

static BOOL pred_like_match(const char *text, const char *pattern)
{
    if (!*pattern)
        return *text == 0;
    if (*pattern == '*')
    {
        while (*pattern == '*')
            pattern++;
        if (!*pattern)
            return 1;
        for (const char *p = text; ; p++)
        {
            if (pred_like_match(p, pattern))
                return 1;
            if (!*p)
                return 0;
        }
    }
    if (*pattern == '?')
        return *text && pred_like_match(text + 1, pattern + 1);
    if (*text != *pattern)
        return 0;
    return pred_like_match(text + 1, pattern + 1);
}

static int pred_parse_or(pred_parser *parser);

static int pred_parse_atom(pred_parser *parser)
{
    pred_skip(parser);
    if (pred_word(parser, "TRUEPREDICATE"))
        return 1;
    if (pred_word(parser, "FALSEPREDICATE"))
        return 0;
    if (*parser->p == '(')
    {
        parser->p++;
        int value = pred_parse_or(parser);
        pred_skip(parser);
        if (*parser->p == ')')
            parser->p++;
        return value;
    }
    pred_value left = pred_parse_operand(parser);
    if (!left.valid)
        return 0;
    pred_skip(parser);
    char op[16];
    int is_word = 0;
    if (parser->p[0] == '=' && parser->p[1] == '=')
        strcpy(op, "=="), parser->p += 2;
    else if (parser->p[0] == '!' && parser->p[1] == '=')
        strcpy(op, "!="), parser->p += 2;
    else if (parser->p[0] == '<' && parser->p[1] == '>')
        strcpy(op, "!="), parser->p += 2;
    else if (parser->p[0] == '<' && parser->p[1] == '=')
        strcpy(op, "<="), parser->p += 2;
    else if (parser->p[0] == '>' && parser->p[1] == '=')
        strcpy(op, ">="), parser->p += 2;
    else if (parser->p[0] == '<')
        strcpy(op, "<"), parser->p++;
    else if (parser->p[0] == '>')
        strcpy(op, ">"), parser->p++;
    else if (parser->p[0] == '=')
        strcpy(op, "=="), parser->p++;
    else if (pred_word(parser, "CONTAINS"))
        strcpy(op, "CONTAINS"), is_word = 1;
    else if (pred_word(parser, "BEGINSWITH"))
        strcpy(op, "BEGINSWITH"), is_word = 1;
    else if (pred_word(parser, "ENDSWITH"))
        strcpy(op, "ENDSWITH"), is_word = 1;
    else if (pred_word(parser, "LIKE"))
        strcpy(op, "LIKE"), is_word = 1;
    else if (pred_word(parser, "IN"))
        strcpy(op, "IN"), is_word = 1;
    else
        return 0;
    (void)is_word;
    pred_value right = pred_parse_operand(parser);
    if (!right.valid)
        return 0;
    if (strcmp(op, "==") == 0)
        return pred_equal_values(left, right) ? 1 : 0;
    if (strcmp(op, "!=") == 0)
        return pred_equal_values(left, right) ? 0 : 1;
    if (strcmp(op, "IN") == 0)
    {
        if (![right.value isKindOfClass:[NSArray class]])
            return 0;
        if (left.is_nil)
            return 0;
        return [(NSArray *)right.value containsObject:left.value] ? 1 : 0;
    }
    if (strcmp(op, "CONTAINS") == 0)
    {
        if (left.is_nil || right.is_nil)
            return 0;
        if ([left.value isKindOfClass:[NSString class]] &&
            [right.value isKindOfClass:[NSString class]])
            return strstr([left.value UTF8String],
                          [right.value UTF8String]) != 0;
        if ([left.value isKindOfClass:[NSArray class]])
            return [left.value containsObject:right.value] ? 1 : 0;
        return 0;
    }
    if (strcmp(op, "BEGINSWITH") == 0 ||
        strcmp(op, "ENDSWITH") == 0)
    {
        if (left.is_nil || right.is_nil ||
            ![left.value isKindOfClass:[NSString class]] ||
            ![right.value isKindOfClass:[NSString class]])
            return 0;
        const char *text = [left.value UTF8String];
        const char *part = [right.value UTF8String];
        unsigned long text_len = strlen(text), part_len = strlen(part);
        if (strcmp(op, "BEGINSWITH") == 0)
            return strncmp(text, part, part_len) == 0;
        return text_len >= part_len &&
               strcmp(text + text_len - part_len, part) == 0;
    }
    if (strcmp(op, "LIKE") == 0)
    {
        if (left.is_nil || right.is_nil ||
            ![left.value isKindOfClass:[NSString class]] ||
            ![right.value isKindOfClass:[NSString class]])
            return 0;
        return pred_like_match([left.value UTF8String],
                               [right.value UTF8String]);
    }
    double a = 0, b = 0;
    int left_number = pred_is_number(left, &a);
    int right_number = pred_is_number(right, &b);
    if (left_number && right_number)
    {
        if (strcmp(op, "<") == 0)
            return a < b;
        if (strcmp(op, "<=") == 0)
            return a <= b;
        if (strcmp(op, ">") == 0)
            return a > b;
        return a >= b;
    }
    if (!left.is_nil && !right.is_nil &&
        [left.value isKindOfClass:[NSString class]] &&
        [right.value isKindOfClass:[NSString class]])
    {
        long comparison = [(NSString *)left.value
            compare:(NSString *)right.value];
        if (strcmp(op, "<") == 0)
            return comparison < 0;
        if (strcmp(op, "<=") == 0)
            return comparison <= 0;
        if (strcmp(op, ">") == 0)
            return comparison > 0;
        return comparison >= 0;
    }
    return 0;
}

static int pred_parse_not(pred_parser *parser)
{
    if (pred_word(parser, "NOT"))
        return !pred_parse_not(parser);
    return pred_parse_atom(parser);
}

static int pred_parse_and(pred_parser *parser)
{
    int value = pred_parse_not(parser);
    while (pred_word(parser, "AND"))
    {
        int right = pred_parse_not(parser);
        value = value && right;
    }
    return value;
}

static int pred_parse_or(pred_parser *parser)
{
    int value = pred_parse_and(parser);
    while (pred_word(parser, "OR"))
    {
        int right = pred_parse_and(parser);
        value = value || right;
    }
    return value;
}

@implementation NSPredicate
+ (id)predicateWithFormat:(id)format, ...
{
    NSPredicate *predicate = [[self alloc] init];
    va_list ap;
    va_start(ap, format);
    char *buffer = format_va(iosim_string_cstr(format), ap);
    va_end(ap);
    predicate->_format = [[NSString alloc] initWithUTF8String:
        buffer ? buffer : ""];
    free(buffer);
    return predicate;
}
+ (id)predicateWithValue:(BOOL)value
{
    return [self predicateWithFormat:
        value ? @"TRUEPREDICATE" : @"FALSEPREDICATE"];
}
- (BOOL)evaluateWithObject:(id)object
{
    pred_parser parser;
    parser.p = iosim_string_cstr(_format);
    parser.object = object;
    int value = pred_parse_or(&parser);
    return value ? YES : NO;
}
- (id)predicateFormat { return _format; }
@end

@implementation NSArray
+ (id)array { return [[[self alloc] init] autorelease]; }
+ (id)arrayWithObject:(id)object
{
    NSMutableArray *a = [NSMutableArray array];
    [a addObject:object];
    return a;
}
+ (id)arrayWithArray:(id)array
{
    NSMutableArray *a = [NSMutableArray array];
    for (unsigned long i = 0; i < [array count]; i++)
        [a addObject:[array objectAtIndex:i]];
    return a;
}
+ (id)arrayWithObjects:(const id *)objects count:(unsigned long)count
{
    NSMutableArray *a = [NSMutableArray array];
    for (unsigned long i = 0; i < count; i++)
        [a addObject:objects[i]];
    return a;
}
+ (id)arrayWithObjects:(id)first, ...
{
    NSMutableArray *a = [NSMutableArray array];
    va_list ap;
    va_start(ap, first);
    id obj = first;
    while (obj)
    {
        [a addObject:obj];
        obj = va_arg(ap, id);
    }
    va_end(ap);
    return a;
}
- (id)initWithObjects:(id)first, ...
{
    self = [super init];
    if (self)
    {
        va_list ap;
        va_start(ap, first);
        id obj = first;
        while (obj)
        {
            id *items = realloc(_items, (_count + 1) * sizeof(id));
            if (!items)
                break;
            _items = items;
            _items[_count++] = obj;
            obj = va_arg(ap, id);
        }
        va_end(ap);
    }
    return self;
}
- (unsigned long)count { return _count; }
- (id)objectAtIndex:(unsigned long)index
{
    if (index >= _count)
        return nil;
    return _items[index];
}
- (id)firstObject { return _count ? _items[0] : nil; }
- (id)lastObject { return _count ? _items[_count - 1] : nil; }
- (BOOL)containsObject:(id)object { return [self indexOfObject:object] != (unsigned long)-1; }
- (unsigned long)indexOfObject:(id)object
{
    for (unsigned long i = 0; i < _count; i++)
        if (objects_equal(_items[i], object))
            return i;
    return (unsigned long)-1;
}
- (id)objectAtIndexedSubscript:(unsigned long)index
{
    return [self objectAtIndex:index];
}
- (unsigned long)countByEnumeratingWithState:(NSFastEnumerationState *)state
                                     objects:(id *)buffer
                                       count:(unsigned long)len
{
    (void)buffer;
    (void)len;
    if (state->state != 0)
        return 0;
    state->state = 1;
    state->itemsPtr = _items;
    state->mutationsPtr = &state->extra[0];
    return _count;
}
- (id)sortedArrayUsingDescriptors:(id)descriptors
{
    NSMutableArray *copy = [NSMutableArray arrayWithArray:self];
    [copy sortUsingDescriptors:descriptors];
    return copy;
}
- (id)sortedArrayUsingSelector:(SEL)selector
{
    NSMutableArray *copy = [NSMutableArray arrayWithArray:self];
    [copy sortUsingSelector:selector];
    return copy;
}
- (id)filteredArrayUsingPredicate:(id)predicate
{
    NSMutableArray *result = [NSMutableArray array];
    for (unsigned long i = 0; i < _count; i++)
        if ([predicate evaluateWithObject:_items[i]])
            [result addObject:_items[i]];
    return result;
}
- (id)description
{
    NSMutableString *s = [NSMutableString string];
    [s appendString:@"("];
    for (unsigned long i = 0; i < _count; i++)
    {
        if (i)
            [s appendString:@", "];
        [s appendString:[NSString stringWithUTF8String:obj_cstr(_items[i])]];
    }
    [s appendString:@")"];
    return s;
}
@end

@implementation NSMutableArray
+ (id)array { return [[[self alloc] init] autorelease]; }
- (void)addObject:(id)object
{
    if (!object)
        return;
    id *items = realloc(_items, (_count + 1) * sizeof(id));
    if (!items)
        return;
    _items = items;
    _items[_count++] = object;
}
- (void)insertObject:(id)object atIndex:(unsigned long)index
{
    if (index > _count)
        index = _count;
    id *items = realloc(_items, (_count + 1) * sizeof(id));
    if (!items)
        return;
    _items = items;
    for (unsigned long i = _count; i > index; i--)
        _items[i] = _items[i - 1];
    _items[index] = object;
    _count++;
}
- (void)removeObjectAtIndex:(unsigned long)index
{
    if (index >= _count)
        return;
    for (unsigned long i = index; i + 1 < _count; i++)
        _items[i] = _items[i + 1];
    _count--;
}
- (void)removeAllObjects { _count = 0; }
- (void)removeObject:(id)object
{
    unsigned long i = [self indexOfObject:object];
    if (i != (unsigned long)-1)
        [self removeObjectAtIndex:i];
}
- (void)setObject:(id)object atIndexedSubscript:(unsigned long)index
{
    if (!object)
        return;
    if (index < _count)
        _items[index] = object;
    else if (index == _count)
        [self addObject:object];
}
- (void)sortUsingDescriptors:(id)descriptors
{
    sort_array_descriptors(self, descriptors);
}
- (void)sortUsingSelector:(SEL)selector
{
    sort_array_selector(self, selector);
}
- (void)exchangeObjectAtIndex:(unsigned long)first
        withObjectAtIndex:(unsigned long)second
{
    if (first >= _count || second >= _count || first == second)
        return;
    id item = _items[first];
    _items[first] = _items[second];
    _items[second] = item;
}
- (void)filterUsingPredicate:(id)predicate
{
    unsigned long kept = 0;
    for (unsigned long i = 0; i < _count; i++)
        if ([predicate evaluateWithObject:_items[i]])
            _items[kept++] = _items[i];
    _count = kept;
}
@end

/* --------------------------------------------------------------- NSSet */

@implementation NSSet
+ (id)set { return [[[self alloc] init] autorelease]; }
+ (id)setWithObject:(id)object
{
    NSMutableSet *s = [NSMutableSet set];
    [s addObject:object];
    return s;
}
+ (id)setWithObjects:(const id *)objects count:(unsigned long)count
{
    NSMutableSet *s = [NSMutableSet set];
    for (unsigned long i = 0; i < count; i++)
        [s addObject:objects[i]];
    return s;
}
+ (id)setWithObjects:(id)first, ...
{
    NSMutableSet *s = [NSMutableSet set];
    va_list ap;
    va_start(ap, first);
    id obj = first;
    while (obj)
    {
        [s addObject:obj];
        obj = va_arg(ap, id);
    }
    va_end(ap);
    return s;
}
+ (id)setWithArray:(id)array
{
    NSMutableSet *s = [NSMutableSet set];
    for (unsigned long i = 0; i < [array count]; i++)
        [s addObject:[array objectAtIndex:i]];
    return s;
}
- (unsigned long)count { return _count; }
- (id)anyObject { return _count ? _items[0] : nil; }
- (id)allObjects
{
    return [NSArray arrayWithObjects:_items count:_count];
}
- (BOOL)containsObject:(id)object
{
    return [self member:object] != nil;
}
- (id)member:(id)object
{
    for (unsigned long i = 0; i < _count; i++)
        if (objects_equal(_items[i], object))
            return _items[i];
    return nil;
}
- (unsigned long)countByEnumeratingWithState:(NSFastEnumerationState *)state
                                     objects:(id *)buffer
                                       count:(unsigned long)len
{
    (void)buffer;
    (void)len;
    if (state->state != 0)
        return 0;
    state->state = 1;
    state->itemsPtr = _items;
    state->mutationsPtr = &state->extra[0];
    return _count;
}
- (id)description
{
    NSMutableString *s = [NSMutableString string];
    [s appendString:@"{("];
    for (unsigned long i = 0; i < _count; i++)
    {
        if (i)
            [s appendString:@", "];
        [s appendString:[NSString stringWithUTF8String:obj_cstr(_items[i])]];
    }
    [s appendString:@")}"];
    return s;
}
@end

@implementation NSMutableSet
+ (id)set { return [[[self alloc] init] autorelease]; }
- (void)addObject:(id)object
{
    if (!object || [self containsObject:object])
        return;
    id *items = realloc(_items, (_count + 1) * sizeof(id));
    if (!items)
        return;
    _items = items;
    _items[_count++] = object;
}
- (void)removeObject:(id)object
{
    for (unsigned long i = 0; i < _count; i++)
    {
        if (objects_equal(_items[i], object))
        {
            for (unsigned long j = i; j + 1 < _count; j++)
                _items[j] = _items[j + 1];
            _count--;
            return;
        }
    }
}
- (void)removeAllObjects { _count = 0; }
@end

/* --------------------------------------------------------- NSCountedSet */

@implementation NSCountedSet
+ (id)countedSetWithArray:(id)array
{
    NSCountedSet *set = [[[self alloc] init] autorelease];
    for (unsigned long i = 0; i < [array count]; i++)
        [set addObject:[array objectAtIndex:i]];
    return set;
}
- (void)addObject:(id)object
{
    if (!object)
        return;
    for (unsigned long i = 0; i < _count; i++)
    {
        if (objects_equal(_items[i], object))
        {
            _counts[i]++;
            return;
        }
    }
    id *items = realloc(_items, (_count + 1) * sizeof(id));
    if (!items)
        return;
    _items = items;
    unsigned long *counts = realloc(_counts, (_count + 1) * sizeof(unsigned long));
    if (!counts)
        return;
    _counts = counts;
    _items[_count] = object;
    _counts[_count] = 1;
    _count++;
}
- (void)removeObject:(id)object
{
    for (unsigned long i = 0; i < _count; i++)
    {
        if (!objects_equal(_items[i], object))
            continue;
        if (_counts[i] > 1)
        {
            _counts[i]--;
            return;
        }
        for (unsigned long j = i; j + 1 < _count; j++)
        {
            _items[j] = _items[j + 1];
            _counts[j] = _counts[j + 1];
        }
        _count--;
        return;
    }
}
- (void)removeAllObjects
{
    _count = 0;
}
- (unsigned long)countForObject:(id)object
{
    for (unsigned long i = 0; i < _count; i++)
        if (objects_equal(_items[i], object))
            return _counts[i];
    return 0;
}
@end

/* --------------------------------------------------------- NSOrderedSet */

@implementation NSOrderedSet
+ (id)orderedSet { return [[[self alloc] init] autorelease]; }
+ (id)orderedSetWithObject:(id)object
{
    NSMutableOrderedSet *set = [NSMutableOrderedSet orderedSet];
    [set addObject:object];
    return set;
}
+ (id)orderedSetWithObjects:(const id *)objects count:(unsigned long)count
{
    NSMutableOrderedSet *set = [NSMutableOrderedSet orderedSet];
    for (unsigned long i = 0; i < count; i++)
        [set addObject:objects[i]];
    return set;
}
+ (id)orderedSetWithObjects:(id)first, ...
{
    NSMutableOrderedSet *set = [NSMutableOrderedSet orderedSet];
    va_list ap;
    va_start(ap, first);
    id object = first;
    while (object)
    {
        [set addObject:object];
        object = va_arg(ap, id);
    }
    va_end(ap);
    return set;
}
+ (id)orderedSetWithArray:(id)array
{
    NSMutableOrderedSet *set = [NSMutableOrderedSet orderedSet];
    for (unsigned long i = 0; i < [array count]; i++)
        [set addObject:[array objectAtIndex:i]];
    return set;
}
+ (id)orderedSetWithSet:(id)source
{
    NSMutableOrderedSet *set = [NSMutableOrderedSet orderedSet];
    NSArray *objects = [source respondsToSelector:@selector(allObjects)]
                           ? [source allObjects]
                           : nil;
    for (unsigned long i = 0; i < [objects count]; i++)
        [set addObject:[objects objectAtIndex:i]];
    return set;
}
- (unsigned long)count { return _count; }
- (id)objectAtIndex:(unsigned long)index
{
    return index < _count ? _items[index] : nil;
}
- (id)firstObject { return _count ? _items[0] : nil; }
- (id)lastObject { return _count ? _items[_count - 1] : nil; }
- (unsigned long)indexOfObject:(id)object
{
    for (unsigned long i = 0; i < _count; i++)
        if (objects_equal(_items[i], object))
            return i;
    return NSNotFound;
}
- (BOOL)containsObject:(id)object
{
    return [self indexOfObject:object] != NSNotFound;
}
- (id)array { return [NSArray arrayWithObjects:_items count:_count]; }
- (id)set { return [NSSet setWithArray:[self array]]; }
- (unsigned long)countByEnumeratingWithState:(NSFastEnumerationState *)state
                                     objects:(id *)buffer
                                       count:(unsigned long)len
{
    (void)buffer;
    (void)len;
    if (state->state != 0)
        return 0;
    state->state = 1;
    state->itemsPtr = _items;
    state->mutationsPtr = &state->extra[0];
    return _count;
}
- (id)description
{
    NSMutableString *string = [NSMutableString string];
    [string appendString:@"{("];
    for (unsigned long i = 0; i < _count; i++)
    {
        if (i)
            [string appendString:@", "];
        [string appendString:
            [NSString stringWithUTF8String:obj_cstr(_items[i])]];
    }
    [string appendString:@")}"];
    return string;
}
@end

@implementation NSMutableOrderedSet
+ (id)orderedSet { return [[[self alloc] init] autorelease]; }
- (void)addObject:(id)object
{
    if (!object || [self containsObject:object])
        return;
    id *items = realloc(_items, (_count + 1) * sizeof(id));
    if (!items)
        return;
    _items = items;
    _items[_count++] = object;
}
- (void)insertObject:(id)object atIndex:(unsigned long)index
{
    if (!object || index > _count || [self containsObject:object])
        return;
    id *items = realloc(_items, (_count + 1) * sizeof(id));
    if (!items)
        return;
    _items = items;
    for (unsigned long i = _count; i > index; i--)
        _items[i] = _items[i - 1];
    _items[index] = object;
    _count++;
}
- (void)removeObject:(id)object
{
    unsigned long index = [self indexOfObject:object];
    if (index != NSNotFound)
        [self removeObjectAtIndex:index];
}
- (void)removeObjectAtIndex:(unsigned long)index
{
    if (index >= _count)
        return;
    for (unsigned long i = index; i + 1 < _count; i++)
        _items[i] = _items[i + 1];
    _count--;
}
- (void)replaceObjectAtIndex:(unsigned long)index withObject:(id)object
{
    if (index >= _count || !object)
        return;
    _items[index] = object;
}
- (void)setObject:(id)object atIndexedSubscript:(unsigned long)index
{
    [self replaceObjectAtIndex:index withObject:object];
}
- (void)removeAllObjects { _count = 0; }
@end

/* --------------------------------------------------------- NSDictionary */

@implementation NSDictionary
+ (id)dictionary { return [[[self alloc] init] autorelease]; }
+ (id)dictionaryWithObject:(id)object forKey:(id)key
{
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
    [dictionary setObject:object forKey:key];
    return dictionary;
}
+ (id)dictionaryWithObjects:(const id *)objects
                    forKeys:(const id *)keys
                      count:(unsigned long)count
{
    NSMutableDictionary *d = [NSMutableDictionary dictionary];
    for (unsigned long i = 0; i < count; i++)
        [d setObject:objects[i] forKey:keys[i]];
    return d;
}
+ (id)dictionaryWithObjects:(id)firstObject forKeys:(id)firstKey, ...
{
    NSMutableDictionary *d = [NSMutableDictionary dictionary];
    va_list ap;
    va_start(ap, firstKey);
    id obj = firstObject, key = firstKey;
    while (obj && key)
    {
        [d setObject:obj forKey:key];
        obj = va_arg(ap, id);
        key = va_arg(ap, id);
    }
    va_end(ap);
    return d;
}
+ (id)dictionaryWithObjectsAndKeys:(id)firstObject, ...
{
    NSMutableDictionary *d = [NSMutableDictionary dictionary];
    va_list ap;
    va_start(ap, firstObject);
    id obj = firstObject;
    while (obj)
    {
        id key = va_arg(ap, id);
        if (!key)
            break;
        [d setObject:obj forKey:key];
        obj = va_arg(ap, id);
    }
    va_end(ap);
    return d;
}
- (unsigned long)count { return _count; }
- (id)objectForKey:(id)key
{
    for (unsigned long i = 0; i < _count; i++)
        if (objects_equal(_keys[i], key))
            return _values[i];
    return nil;
}
- (id)allKeys
{
    NSMutableArray *a = [NSMutableArray array];
    for (unsigned long i = 0; i < _count; i++)
        [a addObject:_keys[i]];
    return a;
}
- (id)allValues
{
    NSMutableArray *a = [NSMutableArray array];
    for (unsigned long i = 0; i < _count; i++)
        [a addObject:_values[i]];
    return a;
}
- (id)objectForKeyedSubscript:(id)key
{
    return [self objectForKey:key];
}
- (id)valueForKey:(NSString *)key
{
    const char *k = [key UTF8String];
    if (!k || k[0] == '@')
        return [super valueForKey:key];
    return [self objectForKey:key];
}
- (unsigned long)countByEnumeratingWithState:(NSFastEnumerationState *)state
                                     objects:(id *)buffer
                                       count:(unsigned long)len
{
    (void)buffer;
    (void)len;
    if (state->state != 0)
        return 0;
    state->state = 1;
    state->itemsPtr = _keys;
    state->mutationsPtr = &state->extra[0];
    return _count;
}
@end

@implementation NSMutableDictionary
+ (id)dictionary { return [[[self alloc] init] autorelease]; }
- (void)setObject:(id)object forKey:(id)key
{
    if (!object || !key)
        return;
    for (unsigned long i = 0; i < _count; i++)
    {
        if (objects_equal(_keys[i], key))
        {
            _values[i] = object;
            return;
        }
    }
    id *keys = realloc(_keys, (_count + 1) * sizeof(id));
    id *values = realloc(_values, (_count + 1) * sizeof(id));
    if (!keys || !values)
        return;
    _keys = keys;
    _values = values;
    _keys[_count] = key;
    _values[_count] = object;
    _count++;
}
- (void)removeObjectForKey:(id)key
{
    for (unsigned long i = 0; i < _count; i++)
    {
        if (objects_equal(_keys[i], key))
        {
            for (unsigned long j = i; j + 1 < _count; j++)
            {
                _keys[j] = _keys[j + 1];
                _values[j] = _values[j + 1];
            }
            _count--;
            return;
        }
    }
}
- (void)removeAllObjects { _count = 0; }
- (void)setObject:(id)object forKeyedSubscript:(id)key
{
    if (!object)
        [self removeObjectForKey:key];
    else
        [self setObject:object forKey:key];
}
@end

/* --------------------------------------------------------------- NSData */


/* --------------------------------------------------------------- bundles */

@implementation NSBundle
+ (NSBundle *)mainBundle
{
    static NSBundle *bundle;
    if (!bundle)
        bundle = [[self alloc] init];
    return bundle;
}
- (id)resourcePath
{
    const char *dir = getenv("IOSIM_BUNDLE_DIR");
    if (!dir || !*dir)
        dir = ".";
    return [NSString stringWithUTF8String:dir];
}
- (id)bundlePath { return [self resourcePath]; }
- (id)infoDictionary
{
    if (_infoDictionary)
        return _infoDictionary;
    const char *dir = getenv("IOSIM_BUNDLE_DIR");
    if (!dir || !*dir)
        dir = ".";
    char path[1024];
    snprintf(path, sizeof(path), "%s/Info.plist", dir);
    NSData *data =
        [NSData dataWithContentsOfFile:[NSString stringWithUTF8String:path]];
    if (!data)
        return nil;
    id plist = [NSPropertyListSerialization propertyListWithData:data
                                                         options:0
                                                          format:0
                                                           error:0];
    if (plist && [plist isKindOfClass:[NSDictionary class]])
        _infoDictionary = plist;
    return _infoDictionary;
}
- (id)bundleIdentifier
{
    const char *env = getenv("IOSIM_BUNDLE_ID");
    if (env && *env)
        return [NSString stringWithUTF8String:env];
    id plist = [self infoDictionary];
    id value = plist ? [plist objectForKey:@"CFBundleIdentifier"] : nil;
    return [value isKindOfClass:[NSString class]] ? value : nil;
}
- (id)pathForResource:(id)name ofType:(id)type
{
    const char *n = iosim_string_cstr(name);
    const char *t = iosim_string_cstr(type);
    const char *dir = getenv("IOSIM_BUNDLE_DIR");
    if (!dir || !*dir)
        dir = ".";
    char buf[1024];
    if (t && *t)
        snprintf(buf, sizeof(buf), "%s/%s.%s", dir, n, t);
    else
        snprintf(buf, sizeof(buf), "%s/%s", dir, n);
    if (iosim_fs_exists(buf) != 1)
        return nil;
    return [NSString stringWithUTF8String:buf];
}
@end

/* ---------------------------------------------------------- user defaults */

/* Preference domain: the app's bundle id from XPC_SERVICE_NAME when the
 * system UI launched it, otherwise the launchd spawn domain. Apps see their
 * domain through $HOME/Library/Preferences/<domain>.plist, which is where
 * cfprefsd keeps them on the simulator. */
static void defaults_path(char *out, unsigned long cap)
{
    const char *home = getenv("HOME");
    if (!home || !*home)
        home = "/tmp";
    char domain[128];
    snprintf(domain, sizeof(domain), "%s", "com.iosim.defaults");
    const char *service = getenv("XPC_SERVICE_NAME");
    if (service && *service)
    {
        const char *colon = 0;
        const char *bracket = 0;
        for (const char *q = service; *q; q++)
        {
            if (*q == ':' && !colon)
                colon = q;
            if (*q == '[' && colon)
            {
                bracket = q;
                break;
            }
        }
        if (colon)
        {
            const char *begin = colon + 1;
            const char *end = bracket ? bracket : begin + strlen(begin);
            unsigned long n = (unsigned long)(end - begin);
            if (n > 0 && n < sizeof(domain))
            {
                memcpy(domain, begin, n);
                domain[n] = 0;
            }
        }
    }
    snprintf(out, cap, "%s/Library/Preferences/%s.plist", home, domain);
}

@implementation NSUserDefaults
+ (NSUserDefaults *)standardUserDefaults
{
    static NSUserDefaults *defaults;
    if (!defaults)
        defaults = [[self alloc] init];
    return defaults;
}
- (id)init
{
    self = [super init];
    if (self)
    {
        _store = [NSMutableDictionary dictionary];
        char path[1024];
        defaults_path(path, sizeof(path));
        unsigned char *bytes = 0;
        unsigned long length = 0;
        if (iosim_fs_read(path, &bytes, &length) == 0)
        {
            NSData *data = [[NSData alloc] initWithBytes:bytes length:length];
            id plist = [NSPropertyListSerialization
                propertyListWithData:data options:0 format:0 error:0];
            if (plist && [plist isKindOfClass:[NSDictionary class]])
            {
                NSArray *keys = [plist allKeys];
                for (unsigned long i = 0; i < [keys count]; i++)
                {
                    id key = [keys objectAtIndex:i];
                    [_store setObject:[plist objectForKey:key] forKey:key];
                }
            }
            free(bytes);
        }
    }
    return self;
}
- (void)setObject:(id)value forKey:(id)key
{
    if (!key)
        return;
    if (value)
        [_store setObject:value forKey:key];
    else
        [_store removeObjectForKey:key];
    [self synchronize];
}
- (id)objectForKey:(id)key { return key ? [_store objectForKey:key] : nil; }
- (void)removeObjectForKey:(id)key
{
    if (!key)
        return;
    [_store removeObjectForKey:key];
    [self synchronize];
}
- (id)stringForKey:(id)key
{
    id value = [self objectForKey:key];
    return value && [value isKindOfClass:[NSString class]] ? value : nil;
}
- (BOOL)boolForKey:(id)key
{
    id value = [self objectForKey:key];
    return value && [value respondsToSelector:@selector(boolValue)]
               ? [value boolValue] : NO;
}
- (long)integerForKey:(id)key
{
    id value = [self objectForKey:key];
    return value && [value respondsToSelector:@selector(integerValue)]
               ? [value integerValue] : 0;
}
- (void)synchronize
{
    char path[1024];
    defaults_path(path, sizeof(path));
    char dir[1024];
    snprintf(dir, sizeof(dir), "%s", path);
    char *slash = 0;
    for (char *q = dir; *q; q++)
        if (*q == '/')
            slash = q;
    if (slash)
    {
        *slash = 0;
        iosim_fs_mkdir(dir, 1);
    }
    NSData *data = [NSPropertyListSerialization
        dataWithPropertyList:_store format:NSPropertyListXMLFormat_v1_0
        options:0 error:0];
    if (data)
        [data writeToFile:[NSString stringWithUTF8String:path] atomically:YES];
}
@end

@implementation NSValue
+ (id)valueWithBytes:(const void *)value objCType:(const char *)type
{
    NSValue *result = [[self alloc] init];
    unsigned long n = 0;
    if (type)
    {
        const char *p = type;
        while (*p && *p != '}' && n < sizeof(result->_storage))
        {
            if (*p == 'd' || *p == 'f' || *p == 'i' || *p == 'I' ||
                *p == 'q' || *p == 'Q' || *p == 'B' || *p == 'c' ||
                *p == 's' || *p == 'S' || *p == 'l' || *p == 'L')
                n += (*p == 'd' || *p == 'q' || *p == 'Q') ? 8 : 4;
            p++;
        }
    }
    if (n == 0)
        n = 8;
    if (n > sizeof(result->_storage))
        n = sizeof(result->_storage);
    memcpy(result->_storage, value, n);
    result->_size = n;
    if (type)
    {
        unsigned long i = 0;
        while (type[i] && i < sizeof(result->_type) - 1)
        {
            result->_type[i] = type[i];
            i++;
        }
        result->_type[i] = 0;
    }
    return [result autorelease];
}
+ (id)value:(const void *)value withObjCType:(const char *)type
{
    return [self valueWithBytes:value objCType:type];
}
+ (id)valueWithCGPoint:(CGPoint)point
{
    return [self valueWithBytes:&point objCType:"{CGPoint=dd}"];
}
+ (id)valueWithCGSize:(CGSize)size
{
    return [self valueWithBytes:&size objCType:"{CGSize=dd}"];
}
+ (id)valueWithCGRect:(CGRect)rect
{
    return [self valueWithBytes:&rect objCType:"{CGRect={CGPoint=dd}{CGSize=dd}}"];
}
+ (id)valueWithCGAffineTransform:(CGAffineTransform)transform
{
    return [self valueWithBytes:&transform
                       objCType:"{CGAffineTransform=dddddd}"];
}
+ (id)valueWithCATransform3D:(CATransform3D)transform
{
    return [self valueWithBytes:&transform
                       objCType:"{CATransform3D=dddddddddddddddd}"];
}
+ (id)valueWithUIEdgeInsets:(UIEdgeInsets)insets
{
    return [self valueWithBytes:&insets
                       objCType:"{UIEdgeInsets=dddd}"];
}
+ (id)valueWithRange:(NSRange)range
{
    return [self valueWithBytes:&range objCType:"{_NSRange=QQ}"];
}
+ (id)valueWithNonretainedObject:(id)object
{
    return [self valueWithBytes:&object objCType:"@"];
}
+ (id)valueWithPointer:(const void *)pointer
{
    return [self valueWithBytes:&pointer objCType:"^v"];
}
- (void)getValue:(void *)value size:(unsigned long)size
{
    if (!value)
        return;
    unsigned long n = size < _size ? size : _size;
    memcpy(value, _storage, n);
}
- (const char *)objCType { return _type; }
- (CGPoint)CGPointValue
{
    CGPoint point = { 0, 0 };
    if (_size >= sizeof(point))
        memcpy(&point, _storage, sizeof(point));
    return point;
}
- (CGSize)CGSizeValue
{
    CGSize size = { 0, 0 };
    if (_size >= sizeof(size))
        memcpy(&size, _storage, sizeof(size));
    return size;
}
- (CGRect)CGRectValue
{
    CGRect rect = { { 0, 0 }, { 0, 0 } };
    if (_size >= sizeof(rect))
        memcpy(&rect, _storage, sizeof(rect));
    return rect;
}
- (CGAffineTransform)CGAffineTransformValue
{
    CGAffineTransform transform = CGAffineTransformMake(1, 0, 0, 1, 0, 0);
    if (_size >= sizeof(transform))
        memcpy(&transform, _storage, sizeof(transform));
    return transform;
}
- (CATransform3D)CATransform3DValue
{
    CATransform3D transform = CATransform3DIdentityValue();
    if (_size >= sizeof(transform))
        memcpy(&transform, _storage, sizeof(transform));
    return transform;
}
- (UIEdgeInsets)UIEdgeInsetsValue
{
    UIEdgeInsets insets = { 0, 0, 0, 0 };
    if (_size >= sizeof(insets))
        memcpy(&insets, _storage, sizeof(insets));
    return insets;
}
- (NSRange)rangeValue
{
    NSRange range = { 0, 0 };
    if (_size >= sizeof(range))
        memcpy(&range, _storage, sizeof(range));
    return range;
}
- (id)nonretainedObjectValue
{
    id object = nil;
    if (_size >= sizeof(object))
        memcpy(&object, _storage, sizeof(object));
    return object;
}
- (void *)pointerValue
{
    void *pointer = 0;
    if (_size >= sizeof(pointer))
        memcpy(&pointer, _storage, sizeof(pointer));
    return pointer;
}
- (BOOL)isEqualToValue:(id)other
{
    if (!other || ![other isKindOfClass:[NSValue class]])
        return NO;
    NSValue *value = (NSValue *)other;
    return _size == value->_size &&
           strcmp(_type, value->_type) == 0 &&
           memcmp(_storage, value->_storage, _size) == 0;
}
@end

@implementation NSIndexSet
+ (id)indexSet { return [[[self alloc] init] autorelease]; }
+ (id)indexSetWithIndex:(unsigned long)index
{
    NSMutableIndexSet *set = [NSMutableIndexSet indexSet];
    [set addIndex:index];
    return set;
}
+ (id)indexSetWithIndexesInRange:(NSRange)range
{
    NSMutableIndexSet *set = [NSMutableIndexSet indexSet];
    [set addIndexesInRange:range];
    return set;
}
- (unsigned long)count { return _count; }
- (unsigned long)firstIndex { return _count ? _indexes[0] : NSNotFound; }
- (unsigned long)lastIndex
{
    return _count ? _indexes[_count - 1] : NSNotFound;
}
- (BOOL)containsIndex:(unsigned long)index
{
    for (unsigned long i = 0; i < _count; i++)
        if (_indexes[i] == index)
            return YES;
    return NO;
}
- (unsigned long)indexGreaterThanIndex:(unsigned long)index
{
    for (unsigned long i = 0; i < _count; i++)
        if (_indexes[i] > index)
            return _indexes[i];
    return NSNotFound;
}
- (unsigned long)indexLessThanIndex:(unsigned long)index
{
    for (unsigned long i = _count; i > 0; i--)
        if (_indexes[i - 1] < index)
            return _indexes[i - 1];
    return NSNotFound;
}
- (unsigned long)indexGreaterThanOrEqualToIndex:(unsigned long)index
{
    for (unsigned long i = 0; i < _count; i++)
        if (_indexes[i] >= index)
            return _indexes[i];
    return NSNotFound;
}
- (void)enumerateIndexesUsingBlock:(void (^)(unsigned long, BOOL *))block
{
    if (!block)
        return;
    BOOL stop = NO;
    for (unsigned long i = 0; i < _count && !stop; i++)
        block(_indexes[i], &stop);
}
- (void)enumerateRangesUsingBlock:(void (^)(NSRange, BOOL *))block
{
    if (!block)
        return;
    BOOL stop = NO;
    unsigned long i = 0;
    while (i < _count && !stop)
    {
        unsigned long start = _indexes[i];
        unsigned long end = start;
        while (i + 1 < _count && _indexes[i + 1] == end + 1)
        {
            end = _indexes[++i];
        }
        block(NSMakeRange(start, end - start + 1), &stop);
        i++;
    }
}
@end

@implementation NSMutableIndexSet
- (void)addIndex:(unsigned long)index
{
    if ([self containsIndex:index])
        return;
    if (_count == _capacity)
    {
        unsigned long capacity = _capacity ? _capacity * 2 : 8;
        unsigned long *indexes = malloc(capacity * sizeof(unsigned long));
        if (!indexes)
            return;
        if (_indexes)
        {
            memcpy(indexes, _indexes, _count * sizeof(unsigned long));
            free(_indexes);
        }
        _indexes = indexes;
        _capacity = capacity;
    }
    unsigned long i = _count;
    while (i > 0 && _indexes[i - 1] > index)
    {
        _indexes[i] = _indexes[i - 1];
        i--;
    }
    _indexes[i] = index;
    _count++;
}
- (void)addIndexesInRange:(NSRange)range
{
    for (unsigned long i = 0; i < range.length; i++)
        [self addIndex:range.location + i];
}
- (void)removeIndex:(unsigned long)index
{
    for (unsigned long i = 0; i < _count; i++)
    {
        if (_indexes[i] == index)
        {
            for (unsigned long j = i; j + 1 < _count; j++)
                _indexes[j] = _indexes[j + 1];
            _count--;
            return;
        }
    }
}
- (void)removeAllIndexes { _count = 0; }
@end

static const char iosim_base64_chars[] =
    "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

@implementation NSData
+ (id)data { return [[[self alloc] init] autorelease]; }
+ (id)dataWithBytes:(const void *)bytes length:(unsigned long)length
{
    NSData *d = [[self alloc] init];
    if (d && bytes)
    {
        d->_bytes = malloc(length + 1);
        if (d->_bytes)
        {
            memcpy(d->_bytes, bytes, length);
            ((char *)d->_bytes)[length] = 0;
        }
        d->_length = length;
    }
    return d;
}
+ (id)dataWithContentsOfFile:(id)path
{
    unsigned char *bytes = 0;
    unsigned long length = 0;
    if (iosim_fs_read(iosim_string_cstr(path), &bytes, &length) != 0)
        return nil;
    NSData *d = [[self alloc] init];
    d->_bytes = bytes;
    d->_length = length;
    return d;
}
+ (id)dataWithContentsOfURL:(id)url
{
    return [self dataWithContentsOfFile:[url path]];
}
- (id)initWithBytes:(const void *)bytes length:(unsigned long)length
{
    self = [super init];
    if (self)
    {
        _bytes = malloc(length + 1);
        if (_bytes && bytes)
        {
            memcpy(_bytes, bytes, length);
            ((char *)_bytes)[length] = 0;
        }
        _length = bytes ? length : 0;
    }
    return self;
}
- (id)initWithContentsOfFile:(id)path
{
    unsigned char *bytes = 0;
    unsigned long length = 0;
    if (iosim_fs_read(iosim_string_cstr(path), &bytes, &length) != 0)
        return nil;
    self = [super init];
    if (self)
    {
        _bytes = bytes;
        _length = length;
    }
    return self;
}
- (const void *)bytes { return _bytes; }
- (unsigned long)length { return _length; }
- (BOOL)writeToFile:(id)path atomically:(BOOL)atomically
{
    (void)atomically;
    return iosim_fs_write(iosim_string_cstr(path), _bytes, _length) == 0;
}
- (BOOL)writeToURL:(id)url atomically:(BOOL)atomically
{
    return [self writeToFile:[url path] atomically:atomically];
}
- (id)subdataWithRange:(NSRange)range
{
    if (range.location > _length)
        return [NSData data];
    unsigned long length = range.length;
    if (range.location + length > _length)
        length = _length - range.location;
    return [NSData dataWithBytes:(const char *)_bytes + range.location
                          length:length];
}
- (BOOL)isEqualToData:(id)other
{
    if (!other || ![other isKindOfClass:[NSData class]])
        return NO;
    NSData *data = (NSData *)other;
    return data->_length == _length &&
           (_length == 0 || memcmp(data->_bytes, _bytes, _length) == 0);
}
- (id)base64EncodedStringWithOptions:(unsigned long)options
{
    (void)options;
    if (_length == 0)
        return @"";
    unsigned long outLength = ((_length + 2) / 3) * 4;
    char *out = malloc(outLength + 1);
    if (!out)
        return @"";
    const unsigned char *bytes = (const unsigned char *)_bytes;
    unsigned long in = 0;
    unsigned long pos = 0;
    while (in + 3 <= _length)
    {
        unsigned long value = (bytes[in] << 16) | (bytes[in + 1] << 8) |
                              bytes[in + 2];
        out[pos++] = iosim_base64_chars[(value >> 18) & 63];
        out[pos++] = iosim_base64_chars[(value >> 12) & 63];
        out[pos++] = iosim_base64_chars[(value >> 6) & 63];
        out[pos++] = iosim_base64_chars[value & 63];
        in += 3;
    }
    if (in < _length)
    {
        unsigned long value = bytes[in] << 16;
        if (in + 1 < _length)
            value |= bytes[in + 1] << 8;
        out[pos++] = iosim_base64_chars[(value >> 18) & 63];
        out[pos++] = iosim_base64_chars[(value >> 12) & 63];
        out[pos++] = in + 1 < _length ?
            iosim_base64_chars[(value >> 6) & 63] : '=';
        out[pos++] = '=';
    }
    out[pos] = 0;
    id result = [NSString stringWithUTF8String:out];
    free(out);
    return result;
}
- (id)initWithBase64EncodedString:(id)string options:(unsigned long)options
{
    (void)options;
    self = [self init];
    if (!self)
        return nil;
    const char *text = iosim_string_cstr(string);
    unsigned long length = 0;
    unsigned char *out = malloc((text ? strlen(text) : 0) + 1);
    if (!out)
        return self;
    unsigned long accumulator = 0;
    int bits = 0;
    for (const char *p = text; p && *p; p++)
    {
        int value = -1;
        if (*p >= 'A' && *p <= 'Z')
            value = *p - 'A';
        else if (*p >= 'a' && *p <= 'z')
            value = *p - 'a' + 26;
        else if (*p >= '0' && *p <= '9')
            value = *p - '0' + 52;
        else if (*p == '+')
            value = 62;
        else if (*p == '/')
            value = 63;
        else
            continue;
        accumulator = (accumulator << 6) | (unsigned long)value;
        bits += 6;
        if (bits >= 8)
        {
            bits -= 8;
            out[length++] = (unsigned char)(accumulator >> bits);
        }
    }
    free(_bytes);
    _bytes = out;
    _length = length;
    return self;
}
- (id)description
{
    return [NSString stringWithFormat:@"<NSData: %lu bytes>", _length];
}
@end

@implementation NSMutableData
+ (id)dataWithCapacity:(unsigned long)capacity
{
    return [[self alloc] initWithCapacity:capacity];
}
- (id)initWithCapacity:(unsigned long)capacity
{
    self = [super init];
    if (self)
    {
        _capacity = capacity < 16 ? 16 : capacity;
        _bytes = malloc(_capacity + 1);
        if (!_bytes)
            _capacity = 0;
        else
            ((char *)_bytes)[0] = 0;
    }
    return self;
}
- (void)appendBytes:(const void *)bytes length:(unsigned long)length
{
    if (!bytes || !length)
        return;
    if (_length + length > _capacity)
    {
        unsigned long capacity = _capacity ? _capacity : 16;
        while (capacity < _length + length)
            capacity *= 2;
        void *grown = realloc(_bytes, capacity + 1);
        if (!grown)
            return;
        _bytes = grown;
        _capacity = capacity;
    }
    memcpy((char *)_bytes + _length, bytes, length);
    _length += length;
    ((char *)_bytes)[_length] = 0;
}
- (void)appendData:(id)data
{
    if (data)
        [self appendBytes:[data bytes] length:[data length]];
}
- (void *)mutableBytes { return _bytes; }
- (void)setLength:(unsigned long)length
{
    if (length > _capacity)
    {
        unsigned long capacity = _capacity ? _capacity : 16;
        while (capacity < length)
            capacity *= 2;
        void *grown = realloc(_bytes, capacity + 1);
        if (!grown)
            return;
        _bytes = grown;
        _capacity = capacity;
    }
    if (_bytes && length > _length)
        memset((char *)_bytes + _length, 0, length - _length);
    _length = length;
    if (_bytes)
        ((char *)_bytes)[_length] = 0;
}
@end

/* ---------------------------------------------------------- files & URLs */

/* NSFileHandle sits on real host descriptors so reads, writes, seeks and
 * truncation share one offset. The open flags are the host's (Linux) values,
 * since the descriptor crosses into the host through the symbol fallback. */
#define FHO_RDONLY 0
#define FHO_WRONLY 1
#define FHO_RDWR   2
#define FHO_CREAT  64
#define FHO_TRUNC  512

@implementation NSFileHandle
- (id)initWithFileDescriptor:(int)fd
{
    self = [super init];
    if (self)
    {
        _fd = fd;
        _closed = fd < 0;
    }
    return self;
}
+ (id)fileHandleForReadingAtPath:(NSString *)path
{
    int fd = open(iosim_string_cstr(path), FHO_RDONLY);
    if (fd < 0)
        return nil;
    return [[self alloc] initWithFileDescriptor:fd];
}
+ (id)fileHandleForWritingAtPath:(NSString *)path
{
    int fd = open(iosim_string_cstr(path),
                  FHO_WRONLY | FHO_CREAT | FHO_TRUNC, 0666);
    if (fd < 0)
        return nil;
    return [[self alloc] initWithFileDescriptor:fd];
}
+ (id)fileHandleForUpdatingAtPath:(NSString *)path
{
    int fd = open(iosim_string_cstr(path), FHO_RDWR | FHO_CREAT);
    if (fd < 0)
        return nil;
    return [[self alloc] initWithFileDescriptor:fd];
}
+ (id)fileHandleWithStandardInput
{
    return [[self alloc] initWithFileDescriptor:0];
}
+ (id)fileHandleWithStandardOutput
{
    return [[self alloc] initWithFileDescriptor:1];
}
+ (id)fileHandleWithStandardError
{
    return [[self alloc] initWithFileDescriptor:2];
}
+ (id)fileHandleWithNullDevice
{
    int fd = open("/dev/null", FHO_RDWR);
    if (fd < 0)
        return nil;
    return [[self alloc] initWithFileDescriptor:fd];
}
- (NSData *)readDataOfLength:(unsigned long)length
{
    if (_closed || _fd < 0 || length == 0)
        return [NSData data];
    unsigned char *buf = malloc(length);
    if (!buf)
        return [NSData data];
    unsigned long got = 0;
    while (got < length)
    {
        long n = read(_fd, buf + got, length - got);
        if (n <= 0)
            break;
        got += (unsigned long)n;
    }
    NSData *data = [NSData dataWithBytes:buf length:got];
    free(buf);
    return data;
}
- (NSData *)readDataToEndOfFile
{
    if (_closed || _fd < 0)
        return [NSData data];
    unsigned long cap = 4096, len = 0;
    unsigned char *buf = malloc(cap);
    if (!buf)
        return [NSData data];
    for (;;)
    {
        if (len == cap)
        {
            unsigned long grown = cap * 2;
            unsigned char *next = realloc(buf, grown);
            if (!next)
                break;
            buf = next;
            cap = grown;
        }
        long n = read(_fd, buf + len, cap - len);
        if (n <= 0)
            break;
        len += (unsigned long)n;
    }
    NSData *data = [NSData dataWithBytes:buf length:len];
    free(buf);
    return data;
}
- (void)writeData:(NSData *)data
{
    if (_closed || _fd < 0 || !data)
        return;
    const unsigned char *bytes = (const unsigned char *)data->_bytes;
    unsigned long len = data->_length;
    unsigned long put = 0;
    while (put < len)
    {
        long n = write(_fd, bytes + put, len - put);
        if (n <= 0)
            break;
        put += (unsigned long)n;
    }
}
- (unsigned long long)offsetInFile
{
    if (_closed || _fd < 0)
        return 0;
    long long off = lseek(_fd, 0, 1);
    return off < 0 ? 0 : (unsigned long long)off;
}
- (unsigned long long)seekToEndOfFile
{
    if (_closed || _fd < 0)
        return 0;
    long long off = lseek(_fd, 0, 2);
    return off < 0 ? 0 : (unsigned long long)off;
}
- (void)seekToFileOffset:(unsigned long long)offset
{
    if (_closed || _fd < 0)
        return;
    lseek(_fd, (long long)offset, 0);
}
- (void)truncateFileAtOffset:(unsigned long long)offset
{
    if (_closed || _fd < 0)
        return;
    ftruncate(_fd, (long long)offset);
}
- (void)synchronizeFile
{
    if (_closed || _fd < 0)
        return;
    fsync(_fd);
}
- (int)fileDescriptor { return _closed ? -1 : _fd; }
- (void)closeFile
{
    if (!_closed && _fd >= 0)
        close(_fd);
    _closed = YES;
}
@end

@implementation NSFileManager
+ (NSFileManager *)defaultManager
{
    static NSFileManager *manager;
    if (!manager)
        manager = [[self alloc] init];
    return manager;
}
- (BOOL)fileExistsAtPath:(id)path
{
    return iosim_fs_exists(iosim_string_cstr(path));
}
- (BOOL)fileExistsAtPath:(id)path isDirectory:(BOOL *)isDirectory
{
    const char *c = iosim_string_cstr(path);
    BOOL exists = iosim_fs_exists(c);
    if (isDirectory)
        *isDirectory = exists && iosim_fs_is_dir(c);
    return exists;
}
- (BOOL)createDirectoryAtPath:(id)path
    withIntermediateDirectories:(BOOL)createIntermediates
                     attributes:(id)attributes error:(id *)error
{
    (void)attributes;
    int rc = iosim_fs_mkdir(iosim_string_cstr(path),
                            createIntermediates ? 1 : 0);
    if (rc != 0 && error)
        *error = [NSError errorWithDomain:@"NSCocoaErrorDomain" code:513
                                   userInfo:nil];
    return rc == 0;
}
- (id)contentsOfDirectoryAtPath:(id)path error:(id *)error
{
    char buf[16384];
    int n = iosim_fs_list(iosim_string_cstr(path), buf, sizeof(buf));
    if (n < 0)
    {
        if (error)
            *error = [NSError errorWithDomain:@"NSCocoaErrorDomain" code:260
                                       userInfo:nil];
        return nil;
    }
    NSMutableArray *items = [NSMutableArray array];
    char *line = buf;
    while (*line)
    {
        char *end = line;
        while (*end && *end != '\n')
            end++;
        char saved = *end;
        *end = 0;
        [items addObject:[NSString stringWithUTF8String:line]];
        *end = saved;
        line = saved ? end + 1 : end;
    }
    return items;
}
- (BOOL)removeItemAtPath:(id)path error:(id *)error
{
    int rc = iosim_fs_remove(iosim_string_cstr(path));
    if (rc != 0 && error)
        *error = [NSError errorWithDomain:@"NSCocoaErrorDomain" code:4
                                   userInfo:nil];
    return rc == 0;
}
- (BOOL)moveItemAtPath:(id)fromPath toPath:(id)toPath error:(id *)error
{
    int rc = iosim_fs_rename(iosim_string_cstr(fromPath),
                             iosim_string_cstr(toPath));
    if (rc != 0 && error)
        *error = [NSError errorWithDomain:@"NSCocoaErrorDomain" code:4
                                   userInfo:nil];
    return rc == 0;
}
- (BOOL)copyItemAtPath:(id)fromPath toPath:(id)toPath error:(id *)error
{
    NSData *data = [NSData dataWithContentsOfFile:fromPath];
    if (!data || ![data writeToFile:toPath atomically:NO])
    {
        if (error)
            *error = [NSError errorWithDomain:@"NSCocoaErrorDomain" code:4
                                       userInfo:nil];
        return NO;
    }
    return YES;
}
- (id)contentsAtPath:(id)path
{
    return [NSData dataWithContentsOfFile:path];
}
- (BOOL)createFileAtPath:(id)path contents:(id)contents attributes:(id)attrs
{
    (void)attrs;
    NSData *data = contents ? contents : [NSData data];
    return [data writeToFile:path atomically:NO];
}
- (id)currentDirectoryPath
{
    const char *home = getenv("HOME");
    return [NSString stringWithUTF8String:home && *home ? home : "."];
}
@end

static id url_string_between(const char *start, const char *end)
{
    if (!start || !end || end <= start)
        return nil;
    unsigned long n = (unsigned long)(end - start);
    if (n >= 500)
        n = 499;
    char buf[512];
    memcpy(buf, start, n);
    buf[n] = 0;
    return [NSString stringWithUTF8String:buf];
}

@implementation NSURL
+ (id)fileURLWithPath:(id)path
{
    NSURL *url = [[self alloc] init];
    url->_path = path;
    url->_scheme = @"file";
    url->_fileURL = YES;
    const char *c = iosim_string_cstr(path);
    char buf[1024];
    snprintf(buf, sizeof(buf), "file://%s", c);
    url->_string = [NSString stringWithUTF8String:buf];
    return url;
}
+ (id)URLWithString:(id)string
{
    NSURL *url = [[self alloc] init];
    url->_string = string;
    const char *c = iosim_string_cstr(string);
    url->_fileURL = strncmp(c, "file://", 7) == 0;
    if (url->_fileURL)
    {
        url->_path = [NSString stringWithUTF8String:c + 7];
        url->_scheme = @"file";
        return url;
    }
    const char *colon = strchr(c, ':');
    if (colon)
    {
        url->_scheme = url_string_between(c, colon);
        if (colon[1] == '/' && colon[2] == '/')
        {
            const char *auth = colon + 3;
            const char *end = auth;
            while (*end && *end != '/' && *end != '?' && *end != '#')
                end++;
            const char *at = auth;
            while (at < end && *at != '@')
                at++;
            const char *hp = at < end ? at + 1 : auth;
            const char *hcolon = hp;
            while (hcolon < end && *hcolon != ':')
                hcolon++;
            url->_host = url_string_between(hp, hcolon);
            if (hcolon < end)
                url->_port = (int)strtol(hcolon + 1, 0, 10);
            if (end < c + strlen(c))
            {
                const char *pathEnd = end;
                while (*pathEnd && *pathEnd != '?' && *pathEnd != '#')
                    pathEnd++;
                url->_path = url_string_between(end, pathEnd);
                if (*pathEnd == '?')
                {
                    const char *qend = pathEnd + 1;
                    while (*qend && *qend != '#')
                        qend++;
                    url->_query = url_string_between(pathEnd + 1, qend);
                }
            }
        }
        else
        {
            const char *q = strchr(colon + 1, '?');
            if (q)
                url->_query = [NSString stringWithUTF8String:q + 1];
            url->_path = url_string_between(colon + 1,
                                            q ? q : c + strlen(c));
        }
    }
    return url;
}
- (id)path { return _path; }
- (id)absolutePath { return _path; }
- (id)scheme { return _scheme; }
- (id)host { return _host; }
- (id)query { return _query; }
- (int)port { return _port; }
- (id)absoluteString { return _string; }
- (BOOL)isFileURL { return _fileURL; }
- (id)lastPathComponent { return [_path lastPathComponent]; }
- (id)pathExtension { return [_path pathExtension]; }
- (id)URLByAppendingPathComponent:(id)component
{
    return [NSURL fileURLWithPath:
        [_path stringByAppendingPathComponent:component]];
}
- (id)URLByAppendingPathComponent:(id)component isDirectory:(BOOL)isDirectory
{
    (void)isDirectory;
    return [self URLByAppendingPathComponent:component];
}
- (id)URLByDeletingLastPathComponent
{
    return [NSURL fileURLWithPath:[_path stringByDeletingLastPathComponent]];
}
- (id)URLByAppendingPathExtension:(id)extension
{
    char buf[1024];
    snprintf(buf, sizeof(buf), "%s.%s", iosim_string_cstr(_path),
             iosim_string_cstr(extension));
    return [NSURL fileURLWithPath:[NSString stringWithUTF8String:buf]];
}
- (id)URLByDeletingPathExtension
{
    return [NSURL fileURLWithPath:[_path stringByDeletingPathExtension]];
}
- (id)URLByStandardizingPath { return self; }
- (id)URLByResolvingSymlinksInPath { return self; }
- (NSArray *)pathComponents
{
    if (!_path)
        return @[];
    return [_path componentsSeparatedByString:@"/"];
}
- (id)description { return _string; }
@end

@implementation NSProcessInfo
+ (NSProcessInfo *)processInfo
{
    static NSProcessInfo *info;
    if (!info)
        info = [[NSProcessInfo alloc] init];
    return info;
}
- (NSDictionary *)environment { return @{}; }
- (NSArray *)arguments { return @[]; }
- (id)processName { return @"iosim"; }
- (id)globallyUniqueString
{
    return [[NSUUID UUID] UUIDString];
}
- (id)operatingSystemVersionString { return @"iOS 18.0"; }
- (unsigned long long)physicalMemory { return 4ULL * 1024 * 1024 * 1024; }
- (unsigned long)processorCount { return 4; }
- (unsigned long)activeProcessorCount { return 4; }
- (double)systemUptime { return iosim_now(); }
- (id)hostName { return @"localhost"; }
- (BOOL)isLowPowerModeEnabled { return NO; }
@end

@implementation NSUUID
+ (id)UUID
{
    return [[[self alloc] init] autorelease];
}
- (id)init
{
    self = [super init];
    if (self)
    {
        static unsigned long counter;
        unsigned long seed = (unsigned long)self ^ (counter++ * 2654435761u);
        for (int i = 0; i < 16; i++)
        {
            seed = seed * 6364136223846793005ULL + 1442695040888963407ULL;
            _bytes[i] = (unsigned char)(seed >> 56);
        }
        _bytes[6] = (unsigned char)((_bytes[6] & 0x0f) | 0x40);
        _bytes[8] = (unsigned char)((_bytes[8] & 0x3f) | 0x80);
    }
    return self;
}
- (id)initWithUUIDString:(id)string
{
    self = [self init];
    if (!self)
        return nil;
    const char *text = iosim_string_cstr(string);
    int nibble = 0;
    for (const char *p = text; *p && nibble < 32; p++)
    {
        int value = -1;
        if (*p >= '0' && *p <= '9')
            value = *p - '0';
        else if (*p >= 'a' && *p <= 'f')
            value = *p - 'a' + 10;
        else if (*p >= 'A' && *p <= 'F')
            value = *p - 'A' + 10;
        if (value < 0)
            continue;
        if (nibble % 2 == 0)
            _bytes[nibble / 2] = (unsigned char)(value << 4);
        else
            _bytes[nibble / 2] |= (unsigned char)value;
        nibble++;
    }
    return self;
}
- (BOOL)isEqual:(id)other
{
    if (!other || ![other isKindOfClass:[NSUUID class]])
        return NO;
    return memcmp(_bytes, ((NSUUID *)other)->_bytes, 16) == 0;
}
- (unsigned long)hash
{
    unsigned long value = 0;
    for (int i = 0; i < 16; i++)
        value = value * 31 + _bytes[i];
    return value;
}
- (id)UUIDString
{
    static const char digits[] = "0123456789ABCDEF";
    char text[37];
    int out = 0;
    for (int i = 0; i < 16; i++)
    {
        if (i == 4 || i == 6 || i == 8 || i == 10)
            text[out++] = '-';
        text[out++] = digits[_bytes[i] >> 4];
        text[out++] = digits[_bytes[i] & 15];
    }
    text[out] = 0;
    return [NSString stringWithUTF8String:text];
}
@end

@implementation NSURLQueryItem
+ (id)queryItemWithName:(id)name value:(id)value
{
    return [[[self alloc] initWithName:name value:value] autorelease];
}
- (id)initWithName:(id)name value:(id)value
{
    self = [super init];
    if (self)
    {
        _name = name;
        _value = value;
    }
    return self;
}
- (id)name { return _name; }
- (id)value { return _value; }
@end

@implementation NSURLComponents
+ (id)componentsWithString:(id)string
{
    NSURL *url = [NSURL URLWithString:string];
    if (!url)
        return nil;
    return [self componentsWithURL:url resolvingAgainstBaseURL:NO];
}
+ (id)componentsWithURL:(id)url resolvingAgainstBaseURL:(BOOL)resolve
{
    (void)resolve;
    NSURLComponents *components = [[self alloc] init];
    components->_scheme = [url scheme];
    components->_host = [url host];
    components->_path = [url path];
    components->_query = [url query];
    components->_port = [url port];
    return components;
}
- (id)string
{
    const char *scheme = iosim_string_cstr(_scheme);
    const char *host = iosim_string_cstr(_host);
    const char *path = iosim_string_cstr(_path);
    const char *query = iosim_string_cstr(_query);
    const char *fragment = iosim_string_cstr(_fragment);
    char buf[2048];
    unsigned long used = 0;
    if (scheme && *scheme)
        used += (unsigned long)snprintf(buf + used, sizeof(buf) - used,
                                        "%s:", scheme);
    if (host && *host)
    {
        if (_port > 0)
            used += (unsigned long)snprintf(buf + used, sizeof(buf) - used,
                                            "//%s:%d", host, _port);
        else
            used += (unsigned long)snprintf(buf + used, sizeof(buf) - used,
                                            "//%s", host);
    }
    if (path && *path)
        used += (unsigned long)snprintf(buf + used, sizeof(buf) - used,
                                        "%s%s", host && *host &&
                                        *path != '/' ? "/" : "", path);
    if (query)
        used += (unsigned long)snprintf(buf + used, sizeof(buf) - used,
                                        "?%s", query);
    if (fragment)
        used += (unsigned long)snprintf(buf + used, sizeof(buf) - used,
                                        "#%s", fragment);
    return [NSString stringWithUTF8String:buf];
}
- (NSURL *)URL { return [NSURL URLWithString:[self string]]; }
- (id)scheme { return _scheme; }
- (void)setScheme:(id)scheme { _scheme = scheme; }
- (id)host { return _host; }
- (void)setHost:(id)host { _host = host; }
- (id)path { return _path; }
- (void)setPath:(id)path { _path = path; }
- (id)query { return _query; }
- (void)setQuery:(id)query { _query = query; }
- (NSArray *)queryItems
{
    if (!_query || [_query length] == 0)
        return @[];
    NSMutableArray *items = [NSMutableArray array];
    NSArray *parts = [_query componentsSeparatedByString:@"&"];
    for (unsigned long i = 0; i < [parts count]; i++)
    {
        id part = [parts objectAtIndex:i];
        NSRange equals = [part rangeOfString:@"="];
        if (equals.location == NSNotFound)
            [items addObject:[NSURLQueryItem queryItemWithName:part value:nil]];
        else
            [items addObject:[NSURLQueryItem queryItemWithName:
                [part substringToIndex:equals.location]
                value:[part substringFromIndex:equals.location + 1]]];
    }
    return items;
}
- (void)setQueryItems:(NSArray *)items
{
    if (!items || [items count] == 0)
    {
        _query = nil;
        return;
    }
    NSMutableString *query = [NSMutableString string];
    for (unsigned long i = 0; i < [items count]; i++)
    {
        NSURLQueryItem *item = (NSURLQueryItem *)[items objectAtIndex:i];
        if (i > 0)
            [query appendString:@"&"];
        [query appendString:[item name]];
        if ([item value])
        {
            [query appendString:@"="];
            [query appendString:[item value]];
        }
    }
    _query = query;
}
- (id)percentEncodedQuery { return _query; }
- (void)setPercentEncodedQuery:(id)query { _query = query; }
- (id)percentEncodedPath { return _path; }
- (void)setPercentEncodedPath:(id)path { _path = path; }
- (id)fragment { return _fragment; }
- (void)setFragment:(id)fragment { _fragment = fragment; }
- (int)port { return _port; }
- (void)setPort:(int)port { _port = port; }
@end

/* ------------------------------------------------------- Notifications */

/* A block observer is stored in the center's table with a nil selector; the
 * token keeps the heap-copied block and doubles as the removal handle. */
@interface NSNotificationBlockToken : NSObject {
@public
    void *_block;
}
@end

@implementation NSNotificationBlockToken
@end

@implementation NSNotification
+ (id)notificationWithName:(id)name object:(id)object
{
    return [self notificationWithName:name object:object userInfo:nil];
}
+ (id)notificationWithName:(id)name object:(id)object userInfo:(id)userInfo
{
    NSNotification *n = [[self alloc] init];
    n->_name = name;
    n->_object = object;
    n->_userInfo = userInfo;
    return n;
}
- (id)name { return _name; }
- (id)object { return _object; }
- (id)userInfo { return _userInfo; }
@end

@implementation NSNotificationCenter
+ (id)defaultCenter
{
    static NSNotificationCenter *center;
    if (!center)
        center = [[self alloc] init];
    return center;
}
- (void)addObserver:(id)observer selector:(SEL)selector
               name:(id)name object:(id)object
{
    if (_count >= 64)
        return;
    _observers[_count] = observer;
    _selectors[_count] = selector;
    _names[_count] = name;
    _objects[_count] = object;
    _count++;
}
- (id)addObserverForName:(id)name object:(id)object queue:(id)queue
              usingBlock:(void (^)(NSNotification *note))block
{
    (void)queue;
    if (_count >= 64 || !block)
        return nil;
    NSNotificationBlockToken *token =
        [[NSNotificationBlockToken alloc] init];
    token->_block = _Block_copy((void *)block);
    _observers[_count] = token;
    _selectors[_count] = (SEL)0;
    _names[_count] = name;
    _objects[_count] = object;
    _count++;
    return token;
}
static void notification_center_remove(NSNotificationCenter *center, int i)
{
    for (int j = i; j + 1 < center->_count; j++)
    {
        center->_observers[j] = center->_observers[j + 1];
        center->_selectors[j] = center->_selectors[j + 1];
        center->_names[j] = center->_names[j + 1];
        center->_objects[j] = center->_objects[j + 1];
    }
    center->_count--;
}
- (void)removeObserver:(id)observer
{
    for (int i = 0; i < _count; i++)
        if (_observers[i] == observer)
        {
            notification_center_remove(self, i);
            i--;
        }
}
- (void)removeObserver:(id)observer name:(id)name object:(id)object
{
    for (int i = 0; i < _count; i++)
    {
        if (observer && _observers[i] != observer)
            continue;
        if (name && !(_names[i] && objects_equal(_names[i], name)))
            continue;
        if (object && _objects[i] != object)
            continue;
        notification_center_remove(self, i);
        i--;
    }
}
- (void)postNotification:(NSNotification *)note
{
    if (!note)
        return;
    id name = note->_name, object = note->_object;
    for (int i = 0; i < _count; i++)
    {
        if (_names[i] && !objects_equal(_names[i], name))
            continue;
        if (_objects[i] && _objects[i] != object)
            continue;
        if (_selectors[i])
        {
            void (*imp)(id, SEL, id) = (void (*)(id, SEL, id))objc_msgSend;
            imp(_observers[i], _selectors[i], note);
        }
        else
        {
            NSNotificationBlockToken *token = _observers[i];
            if (token && token->_block)
                ((void (^)(id))token->_block)(note);
        }
    }
}
- (void)postNotificationName:(id)name object:(id)object
{
    [self postNotificationName:name object:object userInfo:nil];
}
- (void)postNotificationName:(id)name object:(id)object userInfo:(id)userInfo
{
    [self postNotification:
        [NSNotification notificationWithName:name object:object
                                    userInfo:userInfo]];
}
@end

/* ---------------------------------------------------------------- Timer */

@implementation NSTimer
+ (id)scheduledTimerWithTimeInterval:(double)interval target:(id)target
    selector:(SEL)selector userInfo:(id)userInfo repeats:(BOOL)repeats
{
    NSTimer *timer = [[self alloc] init];
    timer->_interval = interval;
    timer->_target = target;
    timer->_selector = selector;
    timer->_userInfo = userInfo;
    timer->_repeats = repeats;
    timer->_valid = YES;
    timer->_nextFire = iosim_now() + interval;
    if (g_timer_count < 64)
        g_timers[g_timer_count++] = timer;
    return timer;
}
- (void)invalidate { _valid = NO; }
- (void)fire
{
    if (!_valid || !_target)
        return;
    void (*imp)(id, SEL, id) = (void (*)(id, SEL, id))objc_msgSend;
    if (_isPerform)
        imp(_target, _selector, _performArgument);
    else
        imp(_target, _selector, self);
    if (_repeats)
        _nextFire = iosim_now() + _interval;
    else
        _valid = NO;
}
@end

int iosim_foundation_tick(void)
{
    double now = iosim_now();
    int fired = 0;
    for (int i = 0; i < g_timer_count; i++)
    {
        NSTimer *timer = g_timers[i];
        if (timer && timer->_valid && now >= timer->_nextFire)
        {
            [timer fire];
            fired++;
        }
    }
    return fired;
}

/* ------------------------------------------------------- run loop & threads */

id NSDefaultRunLoopMode = @"NSDefaultRunLoopMode";

@implementation NSRunLoop
+ (NSRunLoop *)currentRunLoop
{
    static NSRunLoop *loop;
    if (!loop)
        loop = [[self alloc] init];
    return loop;
}
+ (NSRunLoop *)mainRunLoop { return [self currentRunLoop]; }
- (void)addTimer:(NSTimer *)timer forMode:(id)mode
{
    (void)timer;
    (void)mode;
}
- (BOOL)runMode:(id)mode beforeDate:(NSDate *)limitDate
{
    (void)mode;
    double limit = limitDate ? [limitDate timeIntervalSince1970]
                             : iosim_wall_time() + 1.0;
    while (iosim_wall_time() < limit)
    {
        if (iosim_dispatch_drain_main() > 0)
            return YES;
        if (iosim_foundation_tick() > 0)
            return YES;
        usleep(2000);
    }
    return NO;
}
- (void)runUntilDate:(NSDate *)limitDate
{
    double limit = limitDate ? [limitDate timeIntervalSince1970]
                             : iosim_wall_time();
    while (iosim_wall_time() < limit)
    {
        iosim_dispatch_drain_main();
        iosim_foundation_tick();
        usleep(2000);
    }
}
- (void)run
{
    for (;;)
    {
        iosim_dispatch_drain_main();
        iosim_foundation_tick();
        usleep(2000);
    }
}
@end

@implementation NSThread
+ (NSThread *)currentThread
{
    static NSThread *thread;
    if (!thread)
        thread = [[self alloc] init];
    return thread;
}
+ (NSThread *)mainThread { return [self currentThread]; }
+ (BOOL)isMainThread { return pthread_main_np() ? YES : NO; }
+ (void)sleepForTimeInterval:(double)interval
{
    if (interval > 0)
        usleep((unsigned int)(interval * 1000000.0));
}
@end

/* ---------------------------------------------------------------- NSLog */

void NSLog(id format, ...)
{
    const char *fmt = iosim_string_cstr(format);
    va_list ap;
    va_start(ap, format);
    char *text = format_va(fmt, ap);
    va_end(ap);
    iosim_nslog(text ? text : "(null)");
    free(text);
}

/* ------------------------------------------------------------ dates */

extern double iosim_wall_time(void);

static void iosim_civil_from_days(long long z, int *year, int *month, int *day)
{
    z += 719468;
    long long era = (z >= 0 ? z : z - 146096) / 146097;
    unsigned long long doe = (unsigned long long)(z - era * 146097);
    unsigned long long yoe =
        (doe - doe / 1460 + doe / 36524 - doe / 146096) / 365;
    long long y = (long long)yoe + era * 400;
    unsigned long long doy =
        doe - (365 * yoe + yoe / 4 - yoe / 100);
    unsigned long long mp = (5 * doy + 2) / 153;
    unsigned long long d = doy - (153 * mp + 2) / 5 + 1;
    unsigned long long m = mp < 10 ? mp + 3 : mp - 9;
    *year = (int)(y + (m <= 2));
    *month = (int)m;
    *day = (int)d;
}

@implementation NSDate
+ (id)date
{
    return [[self alloc] initWithTimeIntervalSince1970:iosim_wall_time()];
}
+ (id)dateWithTimeIntervalSince1970:(double)interval
{
    return [[self alloc] initWithTimeIntervalSince1970:interval];
}
+ (id)dateWithTimeIntervalSinceNow:(double)interval
{
    return [[self alloc] initWithTimeIntervalSince1970:
                iosim_wall_time() + interval];
}
- (id)initWithTimeIntervalSince1970:(double)interval
{
    self = [super init];
    if (self)
        _timeIntervalSince1970 = interval;
    return self;
}
- (double)timeIntervalSince1970 { return _timeIntervalSince1970; }
- (double)timeIntervalSinceNow
{
    return _timeIntervalSince1970 - iosim_wall_time();
}
@end

static long long days_from_civil(long long y, int m, int d);

@implementation NSDateFormatter
- (void)setDateFormat:(id)format { _dateFormat = format; }
- (id)dateFormat { return _dateFormat; }
- (id)stringFromDate:(NSDate *)date
{
    if (!date)
        return @"";
    const char *fmt = iosim_string_cstr(_dateFormat);
    if (!fmt)
        fmt = "yyyy-MM-dd HH:mm:ss";
    double seconds = date->_timeIntervalSince1970;
    long long isecs = (long long)seconds;
    if (seconds < 0 && seconds != (double)isecs)
        isecs--;
    long long days = isecs / 86400;
    long long sod = isecs % 86400;
    if (sod < 0)
    {
        sod += 86400;
        days--;
    }
    int year = 1970, month = 1, day = 1;
    iosim_civil_from_days(days, &year, &month, &day);
    int hour = (int)(sod / 3600);
    int minute = (int)((sod % 3600) / 60);
    int second = (int)(sod % 60);
    char out[192];
    int o = 0;
    for (int i = 0; fmt[i] && o < 180;)
    {
        char c = fmt[i];
        int run = 1;
        while (fmt[i + run] == c)
            run++;
        if (c == 'y')
        {
            if (run >= 4)
                o += snprintf(out + o, sizeof(out) - (unsigned long)o, "%04d",
                              year);
            else
                o += snprintf(out + o, sizeof(out) - (unsigned long)o, "%02d",
                              year % 100);
        }
        else if (c == 'M')
        {
            if (run >= 2)
                o += snprintf(out + o, sizeof(out) - (unsigned long)o, "%02d",
                              month);
            else
                o += snprintf(out + o, sizeof(out) - (unsigned long)o, "%d",
                              month);
        }
        else if (c == 'd')
        {
            if (run >= 2)
                o += snprintf(out + o, sizeof(out) - (unsigned long)o, "%02d",
                              day);
            else
                o += snprintf(out + o, sizeof(out) - (unsigned long)o, "%d",
                              day);
        }
        else if (c == 'H')
        {
            if (run >= 2)
                o += snprintf(out + o, sizeof(out) - (unsigned long)o, "%02d",
                              hour);
            else
                o += snprintf(out + o, sizeof(out) - (unsigned long)o, "%d",
                              hour);
        }
        else if (c == 'm')
        {
            if (run >= 2)
                o += snprintf(out + o, sizeof(out) - (unsigned long)o, "%02d",
                              minute);
            else
                o += snprintf(out + o, sizeof(out) - (unsigned long)o, "%d",
                              minute);
        }
        else if (c == 's')
        {
            if (run >= 2)
                o += snprintf(out + o, sizeof(out) - (unsigned long)o, "%02d",
                              second);
            else
                o += snprintf(out + o, sizeof(out) - (unsigned long)o, "%d",
                              second);
        }
        else
        {
            int n = run;
            while (n-- > 0 && o < 180)
                out[o++] = c;
        }
        i += run;
    }
    out[o] = 0;
    return [NSString stringWithUTF8String:out];
}
- (NSDate *)dateFromString:(id)string
{
    const char *fmt = iosim_string_cstr(_dateFormat);
    const char *text = iosim_string_cstr(string);
    if (!fmt || !text)
        return nil;
    int year = 1970, month = 1, day = 1;
    int hour = 0, minute = 0, second = 0;
    int i = 0, p = 0;
    while (fmt[i])
    {
        char c = fmt[i];
        int run = 1;
        while (fmt[i + run] == c)
            run++;
        if (c == 'y' || c == 'M' || c == 'd' || c == 'H' || c == 'm' ||
            c == 's')
        {
            int value = 0, digits = 0;
            int limit = run >= 4 ? 4 : 2;
            while (text[p] >= '0' && text[p] <= '9' && digits < limit)
            {
                value = value * 10 + (text[p] - '0');
                p++;
                digits++;
            }
            if (digits == 0)
                return nil;
            if (c == 'y')
            {
                if (run == 2)
                    year = value < 69 ? 2000 + value : 1900 + value;
                else
                    year = value;
            }
            else if (c == 'M')
                month = value;
            else if (c == 'd')
                day = value;
            else if (c == 'H')
                hour = value;
            else if (c == 'm')
                minute = value;
            else
                second = value;
        }
        else if (c == ' ')
        {
            while (text[p] == ' ')
                p++;
        }
        else
        {
            while (text[p] == ' ')
                p++;
            if (text[p] == c)
                p++;
            else if (text[p] && strchr("/-:.", c) &&
                     strchr("/-:.", text[p]))
                p++;
            else if (text[p] != 0)
                return nil;
        }
        i += run;
    }
    if (month < 1 || month > 12 || day < 1 || day > 31 || hour > 23 ||
        minute > 59 || second > 59)
        return nil;
    long long seconds = days_from_civil(year, month, day) * 86400 +
                        (long long)hour * 3600 + minute * 60 + second;
    return [NSDate dateWithTimeIntervalSince1970:(double)seconds];
}
@end

static double number_formatter_pow10(int digits)
{
    double value = 1.0;
    for (int i = 0; i < digits; i++)
        value *= 10.0;
    return value;
}

@implementation NSISO8601DateFormatter
- (unsigned long)formatOptions { return _formatOptions; }
- (void)setFormatOptions:(unsigned long)options { _formatOptions = options; }
- (id)timeZone { return _timeZone; }
- (void)setTimeZone:(id)zone { _timeZone = zone; }
- (id)stringFromDate:(NSDate *)date
{
    NSDateFormatter *formatter = [[[NSDateFormatter alloc] init] autorelease];
    [formatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ssZ"];
    return [formatter stringFromDate:date];
}
- (NSDate *)dateFromString:(id)string
{
    NSDateFormatter *formatter = [[[NSDateFormatter alloc] init] autorelease];
    [formatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ssZ"];
    return [formatter dateFromString:string];
}
@end

@implementation NSNumberFormatter
- (id)init
{
    self = [super init];
    if (self)
    {
        _numberStyle = NSNumberFormatterNoStyle;
        _maximumFractionDigits = 3;
        _minimumFractionDigits = 0;
        _usesGroupingSeparator = YES;
    }
    return self;
}
- (void)setNumberStyle:(long)style { _numberStyle = style; }
- (long)numberStyle { return _numberStyle; }
- (void)setMaximumFractionDigits:(long)digits
{
    _maximumFractionDigits = digits > 0 ? digits : 0;
}
- (long)maximumFractionDigits { return _maximumFractionDigits; }
- (void)setMinimumFractionDigits:(long)digits
{
    _minimumFractionDigits = digits > 0 ? digits : 0;
}
- (long)minimumFractionDigits { return _minimumFractionDigits; }
- (void)setUsesGroupingSeparator:(BOOL)uses
{
    _usesGroupingSeparator = uses ? YES : NO;
}
- (BOOL)usesGroupingSeparator { return _usesGroupingSeparator; }
- (void)setCurrencySymbol:(id)symbol { _currencySymbol = symbol; }
- (id)currencySymbol { return _currencySymbol ? _currencySymbol : @"$"; }
- (id)stringFromNumber:(NSNumber *)number
{
    if (!number)
        return @"";
    double value = [number doubleValue];
    long maxDigits = _maximumFractionDigits;
    long minDigits = _minimumFractionDigits;
    if (_numberStyle == NSNumberFormatterCurrencyStyle)
    {
        if (maxDigits <= 0)
            maxDigits = 2;
        if (minDigits <= 0)
            minDigits = 2;
    }
    else if (_numberStyle == NSNumberFormatterPercentStyle)
        value *= 100.0;
    else if (_numberStyle == NSNumberFormatterNoStyle)
    {
        maxDigits = 0;
        minDigits = 0;
    }
    if (maxDigits > 9)
        maxDigits = 9;
    if (minDigits > maxDigits)
        minDigits = maxDigits;
    int negative = value < 0;
    if (negative)
        value = -value;
    double intPart = __builtin_floor(value);
    double frac = value - intPart;
    long long scaled =
        (long long)(frac * number_formatter_pow10((int)maxDigits) + 0.5);
    if (scaled >= (long long)number_formatter_pow10((int)maxDigits))
    {
        intPart += 1;
        scaled = 0;
    }
    unsigned long long ip = (unsigned long long)intPart;
    char intStr[32];
    int ilen = 0;
    if (ip == 0)
        intStr[ilen++] = '0';
    while (ip && ilen < 31)
    {
        intStr[ilen++] = (char)('0' + (int)(ip % 10));
        ip /= 10;
    }
    for (int i = 0; i < ilen / 2; i++)
    {
        char tmp = intStr[i];
        intStr[i] = intStr[ilen - 1 - i];
        intStr[ilen - 1 - i] = tmp;
    }
    int fracDigits = (int)maxDigits;
    while (fracDigits > minDigits && fracDigits > 0 && scaled % 10 == 0)
    {
        scaled /= 10;
        fracDigits--;
    }
    char out[96];
    int o = 0;
    if (negative)
        out[o++] = '-';
    if (_numberStyle == NSNumberFormatterCurrencyStyle)
    {
        const char *symbol = iosim_string_cstr(self.currencySymbol);
        for (int i = 0; symbol && symbol[i] && o < 88; i++)
            out[o++] = symbol[i];
    }
    for (int i = 0; i < ilen && o < 88; i++)
    {
        if (_usesGroupingSeparator &&
            _numberStyle != NSNumberFormatterNoStyle && i > 0 &&
            (ilen - i) % 3 == 0)
            out[o++] = ',';
        out[o++] = intStr[i];
    }
    if (fracDigits > 0 && o < 88)
    {
        char fbuf[16];
        snprintf(fbuf, sizeof fbuf, "%0*lld", fracDigits, scaled);
        out[o++] = '.';
        for (int i = 0; fbuf[i] && o < 92; i++)
            out[o++] = fbuf[i];
    }
    if (_numberStyle == NSNumberFormatterPercentStyle && o < 94)
        out[o++] = '%';
    out[o] = 0;
    return [NSString stringWithUTF8String:out];
}
- (NSNumber *)numberFromString:(NSString *)string
{
    const char *s = iosim_string_cstr(string);
    if (!s)
        return nil;
    int negative = 0;
    int seen = 0, fracDigits = 0, inFrac = 0;
    double value = 0;
    const char *p = s;
    while (*p == ' ' || *p == '$')
        p++;
    if (*p == '-')
    {
        negative = 1;
        p++;
    }
    else if (*p == '+')
        p++;
    for (; *p; p++)
    {
        if (*p >= '0' && *p <= '9')
        {
            seen = 1;
            value = value * 10 + (*p - '0');
            if (inFrac)
                fracDigits++;
        }
        else if (*p == '.')
            inFrac = 1;
        else if (*p == ',' || *p == ' ')
            continue;
        else if (*p == '%' || *p == '$')
            continue;
        else
            return nil;
    }
    if (!seen)
        return nil;
    while (fracDigits-- > 0)
        value /= 10.0;
    if (_numberStyle == NSNumberFormatterPercentStyle)
        value /= 100.0;
    if (negative)
        value = -value;
    return [NSNumber numberWithDouble:value];
}
@end

@implementation NSError
+ (id)errorWithDomain:(id)domain code:(long)code userInfo:(id)userInfo
{
    NSError *error = [[self alloc] init];
    error->_domain = domain;
    error->_code = code;
    error->_userInfo = userInfo;
    return error;
}
- (id)domain { return _domain; }
- (long)code { return _code; }
- (id)userInfo { return _userInfo; }
- (id)localizedDescription
{
    if (_userInfo &&
        [(id)_userInfo respondsToSelector:@selector(objectForKey:)])
        return [(id)_userInfo objectForKey:@"NSLocalizedDescription"];
    return @"";
}
@end

/* ------------------------------------------------------- URL loading */

static NSMutableDictionary *url_headers_from_raw(const char *raw)
{
    NSMutableDictionary *headers = [NSMutableDictionary dictionary];
    while (raw && *raw)
    {
        const char *line = raw;
        const char *newline = strchr(raw, '\n');
        unsigned long length = newline ? (unsigned long)(newline - raw)
                                       : strlen(raw);
        raw = newline ? newline + 1 : raw + strlen(raw);
        if (length && line[length - 1] == '\r')
            length--;
        if (!length)
            break;
        const char *colon = memchr(line, ':', length);
        if (!colon)
            continue;
        unsigned long key_length = (unsigned long)(colon - line);
        while (key_length && line[key_length - 1] == ' ')
            key_length--;
        const char *value = colon + 1;
        const char *value_end = line + length;
        while (value < value_end && (*value == ' ' || *value == '\t'))
            value++;
        while (value_end > value && (value_end[-1] == ' ' ||
                                     value_end[-1] == '\r'))
            value_end--;
        char key[256], text[2048];
        unsigned long value_length = (unsigned long)(value_end - value);
        if (key_length >= sizeof(key) || value_length >= sizeof(text))
            continue;
        memcpy(key, line, key_length);
        key[key_length] = 0;
        memcpy(text, value, value_length);
        text[value_length] = 0;
        [headers setObject:[NSString stringWithUTF8String:text]
                    forKey:[NSString stringWithUTF8String:key]];
    }
    return headers;
}

@implementation NSURLRequest
+ (id)requestWithURL:(id)url
{
    NSURLRequest *request = [[self alloc] init];
    request->_URL = url;
    request->_timeoutInterval = 60.0;
    request->_HTTPMethod = @"GET";
    return request;
}
- (id)URL { return _URL; }
- (void)setURL:(id)url { _URL = url; }
- (double)timeoutInterval { return _timeoutInterval; }
- (void)setTimeoutInterval:(double)timeout { _timeoutInterval = timeout; }
- (id)HTTPMethod { return _HTTPMethod ? _HTTPMethod : @"GET"; }
- (void)setHTTPMethod:(id)method { _HTTPMethod = method; }
- (id)HTTPBody { return _HTTPBody; }
- (void)setHTTPBody:(id)body { _HTTPBody = body; }
- (id)allHTTPHeaderFields { return _allHTTPHeaderFields; }
- (void)setAllHTTPHeaderFields:(id)fields { _allHTTPHeaderFields = fields; }
- (id)valueForHTTPHeaderField:(id)field
{
    return _allHTTPHeaderFields ? [_allHTTPHeaderFields objectForKey:field] : nil;
}
@end

@implementation NSURLResponse
- (id)initWithURL:(id)url statusCode:(long)status headers:(id)headers
{
    self = [super init];
    if (self)
    {
        _URL = url;
        _statusCode = status;
        _allHeaderFields = headers;
    }
    return self;
}
- (id)URL { return _URL; }
- (long)statusCode { return _statusCode; }
- (id)allHeaderFields { return _allHeaderFields; }
@end

@implementation NSHTTPURLResponse
@end

struct url_task_ctx {
    id task;
    id url;
    id url_string_object;
    id method_object;
    id headers_object;
    const char *url_string;
    const char *method;
    const char *headers;
    const void *body;
    unsigned long body_length;
};

static void url_task_main(void *raw)
{
    struct url_task_ctx *ctx = raw;
    NSURLSessionDataTask *task = ctx->task;
    unsigned char *bytes = 0;
    char *raw_headers = 0, *service_error = 0;
    unsigned long length = 0;
    int status = 0;
    NSData *data = nil;
    NSURLResponse *response = nil;
    NSError *error = nil;
    if (task->_canceled)
    {
        error = [NSError errorWithDomain:@"NSURLErrorDomain" code:-999
                                    userInfo:nil];
    }
    else if (iosim_http_request(ctx->url_string, ctx->method, ctx->headers,
                                ctx->body, ctx->body_length, &bytes, &length,
                                &status, &raw_headers, &service_error) == 0)
    {
        data = [NSData dataWithBytes:bytes length:length];
        response = [[NSHTTPURLResponse alloc]
            initWithURL:ctx->url
             statusCode:status
                headers:url_headers_from_raw(raw_headers)];
    }
    else
    {
        NSDictionary *info = [NSDictionary
            dictionaryWithObject:[NSString stringWithUTF8String:
                service_error ? service_error : "request failed"]
                          forKey:@"NSLocalizedDescription"];
        error = [NSError errorWithDomain:@"NSURLErrorDomain" code:-1004
                                    userInfo:info];
    }
    if (bytes)
        iosim_http_free(bytes);
    if (raw_headers)
        iosim_http_free(raw_headers);
    if (service_error)
        iosim_http_free(service_error);
    void (^handler)(id, id, id) = (void (^)(id, id, id))task->_completion;
    if (handler)
        handler(data, response, error);
    if (task->_completion)
    {
        _Block_release(task->_completion);
        task->_completion = 0;
    }
    task->_context = 0;
    free(ctx);
}

@implementation NSURLSessionDataTask
- (void)resume
{
    if (_resumed)
        return;
    _resumed = 1;
    NSURLRequest *request = (NSURLRequest *)_request;
    struct url_task_ctx *ctx = calloc(1, sizeof(*ctx));
    if (!ctx)
        return;
    ctx->task = self;
    ctx->url = [request URL];
    ctx->url_string_object = [ctx->url absoluteString];
    ctx->url_string = [ctx->url_string_object UTF8String];
    ctx->method_object = [request HTTPMethod];
    ctx->method = [ctx->method_object UTF8String];
    id headers = [request allHTTPHeaderFields];
    if (headers && [headers count])
    {
        NSMutableString *raw = [NSMutableString string];
        for (id key in headers)
        {
            [raw appendString:key];
            [raw appendString:@": "];
            [raw appendString:[headers objectForKey:key]];
            [raw appendString:@"\r\n"];
        }
        ctx->headers_object = raw;
        ctx->headers = [raw UTF8String];
    }
    id body = [request HTTPBody];
    if (body)
    {
        if ([body isKindOfClass:[NSData class]])
        {
            ctx->body = [body bytes];
            ctx->body_length = [body length];
        }
        else if ([body isKindOfClass:[NSString class]])
        {
            ctx->body = [body UTF8String];
            ctx->body_length = strlen([body UTF8String]);
        }
    }
    _context = ctx;
    dispatch_async_f(dispatch_get_global_queue(0, 0), ctx, url_task_main);
}
- (void)cancel { _canceled = 1; }
@end

@implementation NSURLSession
+ (id)sharedSession
{
    static id shared;
    if (!shared)
        shared = [[NSURLSession alloc] init];
    return shared;
}
- (NSURLSessionDataTask *)dataTaskWithURL:(id)url
                        completionHandler:(NSURLSessionCompletionHandler)handler
{
    return [self dataTaskWithRequest:[NSURLRequest requestWithURL:url]
                   completionHandler:handler];
}
- (NSURLSessionDataTask *)dataTaskWithRequest:(id)request
                            completionHandler:(NSURLSessionCompletionHandler)handler
{
    NSURLSessionDataTask *task = [[NSURLSessionDataTask alloc] init];
    task->_request = request;
    task->_completion = handler ? _Block_copy((void *)handler) : 0;
    return task;
}
@end

/* ---------------------------------------------------- JSON serialization */

static BOOL json_write_indent(NSMutableString *out, BOOL pretty, int depth)
{
    if (!pretty)
        return YES;
    [out appendString:@"\n"];
    for (int i = 0; i < depth; i++)
        [out appendString:@"  "];
    return YES;
}

static void json_write_string(NSMutableString *out, const char *s)
{
    [out appendString:@"\""];
    char buf[16];
    for (const unsigned char *p = (const unsigned char *)(s ? s : ""); *p; p++)
    {
        if (*p == '"')
            [out appendString:@"\\\""];
        else if (*p == '\\')
            [out appendString:@"\\\\"];
        else if (*p == '\n')
            [out appendString:@"\\n"];
        else if (*p == '\r')
            [out appendString:@"\\r"];
        else if (*p == '\t')
            [out appendString:@"\\t"];
        else if (*p < 0x20)
        {
            snprintf(buf, sizeof(buf), "\\u%04x", *p);
            [out appendString:[NSString stringWithUTF8String:buf]];
        }
        else
        {
            char one[2] = {(char)*p, 0};
            [out appendString:[NSString stringWithUTF8String:one]];
        }
    }
    [out appendString:@"\""];
}

static BOOL json_write_value(NSMutableString *out, id value, BOOL pretty,
                             int depth)
{
    if (!value || [value isKindOfClass:[NSNull class]])
    {
        [out appendString:@"null"];
        return YES;
    }
    if ([value isKindOfClass:[NSString class]])
    {
        json_write_string(out, iosim_string_cstr(value));
        return YES;
    }
    if ([value isKindOfClass:[NSNumber class]])
    {
        NSNumber *number = (NSNumber *)value;
        char buf[64];
        if (number->_kind == 2)
            [out appendString:number->_ival ? @"true" : @"false"];
        else if (number->_kind == 1)
        {
            snprintf(buf, sizeof(buf), "%.15g", number->_dval);
            [out appendString:[NSString stringWithUTF8String:buf]];
        }
        else
        {
            snprintf(buf, sizeof(buf), "%lld", number->_ival);
            [out appendString:[NSString stringWithUTF8String:buf]];
        }
        return YES;
    }
    if ([value isKindOfClass:[NSArray class]])
    {
        NSArray *array = (NSArray *)value;
        unsigned long count = [array count];
        if (count == 0)
        {
            [out appendString:@"[]"];
            return YES;
        }
        [out appendString:@"["];
        for (unsigned long i = 0; i < count; i++)
        {
            if (i)
                [out appendString:@","];
            json_write_indent(out, pretty, depth + 1);
            if (!json_write_value(out, [array objectAtIndex:i], pretty,
                                  depth + 1))
                return NO;
        }
        json_write_indent(out, pretty, depth);
        [out appendString:@"]"];
        return YES;
    }
    if ([value isKindOfClass:[NSDictionary class]])
    {
        NSDictionary *dict = (NSDictionary *)value;
        NSArray *keys = [dict allKeys];
        unsigned long count = [keys count];
        if (count == 0)
        {
            [out appendString:@"{}"];
            return YES;
        }
        [out appendString:@"{"];
        for (unsigned long i = 0; i < count; i++)
        {
            id key = [keys objectAtIndex:i];
            if (![key isKindOfClass:[NSString class]])
                return NO;
            if (i)
                [out appendString:@","];
            json_write_indent(out, pretty, depth + 1);
            json_write_string(out, iosim_string_cstr(key));
            [out appendString:pretty ? @": " : @":"];
            if (!json_write_value(out, [dict objectForKey:key], pretty,
                                  depth + 1))
                return NO;
        }
        json_write_indent(out, pretty, depth);
        [out appendString:@"}"];
        return YES;
    }
    return NO;
}

struct json_state {
    const char *s;
    unsigned long i;
    unsigned long n;
    int error;
};

static void json_skip_ws(struct json_state *p)
{
    while (p->i < p->n)
    {
        char c = p->s[p->i];
        if (c != ' ' && c != '\t' && c != '\n' && c != '\r')
            break;
        p->i++;
    }
}

static id json_parse_string(struct json_state *p)
{
    if (p->i >= p->n || p->s[p->i] != '"')
    {
        p->error = 1;
        return nil;
    }
    p->i++;
    char *buf = malloc(p->n - p->i + 1);
    unsigned long len = 0;
    while (p->i < p->n && p->s[p->i] != '"')
    {
        unsigned char c = (unsigned char)p->s[p->i++];
        if (c == '\\')
        {
            if (p->i >= p->n)
                break;
            c = (unsigned char)p->s[p->i++];
            if (c == 'n') c = '\n';
            else if (c == 't') c = '\t';
            else if (c == 'r') c = '\r';
            else if (c == 'b') c = '\b';
            else if (c == 'f') c = '\f';
            else if (c == 'u')
            {
                unsigned int code = 0;
                for (int k = 0; k < 4; k++)
                {
                    if (p->i >= p->n)
                    {
                        p->error = 1;
                        break;
                    }
                    char h = p->s[p->i++];
                    unsigned int v = 0;
                    if (h >= '0' && h <= '9') v = (unsigned int)(h - '0');
                    else if (h >= 'a' && h <= 'f')
                        v = (unsigned int)(h - 'a' + 10);
                    else if (h >= 'A' && h <= 'F')
                        v = (unsigned int)(h - 'A' + 10);
                    else
                        p->error = 1;
                    code = code * 16 + v;
                }
                if (code < 0x80)
                    buf[len++] = (char)code;
                else if (code < 0x800)
                {
                    buf[len++] = (char)(0xC0 | (code >> 6));
                    buf[len++] = (char)(0x80 | (code & 0x3F));
                }
                else
                {
                    buf[len++] = (char)(0xE0 | (code >> 12));
                    buf[len++] = (char)(0x80 | ((code >> 6) & 0x3F));
                    buf[len++] = (char)(0x80 | (code & 0x3F));
                }
                continue;
            }
            else if (c != '"' && c != '\\' && c != '/')
            {
                p->error = 1;
                break;
            }
        }
        else if (c < 0x20)
        {
            p->error = 1;
            break;
        }
        buf[len++] = (char)c;
    }
    if (p->i >= p->n || p->s[p->i] != '"')
        p->error = 1;
    else
        p->i++;
    if (p->error)
    {
        free(buf);
        return nil;
    }
    buf[len] = 0;
    NSString *string = [NSString stringWithUTF8String:buf];
    free(buf);
    return string;
}

static id json_parse_value(struct json_state *p, int depth)
{
    if (depth > 64)
    {
        p->error = 1;
        return nil;
    }
    json_skip_ws(p);
    if (p->i >= p->n)
    {
        p->error = 1;
        return nil;
    }
    char c = p->s[p->i];
    if (c == '"')
        return json_parse_string(p);
    if (c == '{')
    {
        p->i++;
        NSMutableDictionary *dict = [NSMutableDictionary dictionary];
        json_skip_ws(p);
        if (p->i < p->n && p->s[p->i] == '}')
        {
            p->i++;
            return dict;
        }
        while (!p->error)
        {
            json_skip_ws(p);
            id key = json_parse_string(p);
            if (!key)
                break;
            json_skip_ws(p);
            if (p->i >= p->n || p->s[p->i] != ':')
            {
                p->error = 1;
                break;
            }
            p->i++;
            id value = json_parse_value(p, depth + 1);
            if (!value)
                break;
            [dict setObject:value forKey:key];
            json_skip_ws(p);
            if (p->i < p->n && p->s[p->i] == ',')
            {
                p->i++;
                continue;
            }
            if (p->i < p->n && p->s[p->i] == '}')
            {
                p->i++;
                return dict;
            }
            p->error = 1;
            break;
        }
        return nil;
    }
    if (c == '[')
    {
        p->i++;
        NSMutableArray *array = [NSMutableArray array];
        json_skip_ws(p);
        if (p->i < p->n && p->s[p->i] == ']')
        {
            p->i++;
            return array;
        }
        while (!p->error)
        {
            id value = json_parse_value(p, depth + 1);
            if (!value)
                break;
            [array addObject:value];
            json_skip_ws(p);
            if (p->i < p->n && p->s[p->i] == ',')
            {
                p->i++;
                continue;
            }
            if (p->i < p->n && p->s[p->i] == ']')
            {
                p->i++;
                return array;
            }
            p->error = 1;
            break;
        }
        return nil;
    }
    if (c == 't' && p->n - p->i >= 4 && strncmp(p->s + p->i, "true", 4) == 0)
    {
        p->i += 4;
        return [NSNumber numberWithBool:YES];
    }
    if (c == 'f' && p->n - p->i >= 5 &&
        strncmp(p->s + p->i, "false", 5) == 0)
    {
        p->i += 5;
        return [NSNumber numberWithBool:NO];
    }
    if (c == 'n' && p->n - p->i >= 4 &&
        strncmp(p->s + p->i, "null", 4) == 0)
    {
        p->i += 4;
        return [NSNull null];
    }
    if (c == '-' || (c >= '0' && c <= '9'))
    {
        char *end = 0;
        double value = strtod(p->s + p->i, &end);
        if (!end || end == p->s + p->i)
        {
            p->error = 1;
            return nil;
        }
        unsigned long start = p->i;
        int integral = 1;
        for (const char *q = p->s + start; q < end; q++)
            if (*q == '.' || *q == 'e' || *q == 'E')
                integral = 0;
        p->i = (unsigned long)(end - p->s);
        if (integral)
            return [NSNumber numberWithLongLong:(long long)value];
        return [NSNumber numberWithDouble:value];
    }
    p->error = 1;
    return nil;
}

/* ------------------------------------------------- xml property lists */

static void plist_write_escaped(NSMutableString *out, const char *text)
{
    if (!text)
        text = "";
    char chunk[64];
    int used = 0;
    for (const char *p = text; ; p++)
    {
        char c = *p;
        if (c == 0 || c == '&' || c == '<' || c == '>' || c == '"' || c == '\'')
        {
            if (used)
            {
                chunk[used] = 0;
                [out appendString:[NSString stringWithUTF8String:chunk]];
                used = 0;
            }
            if (c == 0)
                break;
            if (c == '&') [out appendString:@"&amp;"];
            else if (c == '<') [out appendString:@"&lt;"];
            else if (c == '>') [out appendString:@"&gt;"];
            else if (c == '"') [out appendString:@"&quot;"];
            else [out appendString:@"&apos;"];
            continue;
        }
        chunk[used++] = c;
        if (used == (int)sizeof(chunk) - 1)
        {
            chunk[used] = 0;
            [out appendString:[NSString stringWithUTF8String:chunk]];
            used = 0;
        }
    }
}

static void plist_indent(NSMutableString *out, int depth)
{
    [out appendString:@"\n"];
    for (int i = 0; i < depth; i++)
        [out appendString:@"\t"];
}

static void civil_from_days(long long z, long long *out_year, int *out_month,
                            int *out_day)
{
    z += 719468;
    long long era = (z >= 0 ? z : z - 146096) / 146097;
    unsigned long doe = (unsigned long)(z - era * 146097);
    unsigned long yoe = (doe - doe / 1460 + doe / 36524 - doe / 146096) / 365;
    long long year = (long long)yoe + era * 400;
    unsigned long doy = doe - (365 * yoe + yoe / 4 - yoe / 100);
    unsigned long mp = (5 * doy + 2) / 153;
    unsigned long day = doy - (153 * mp + 2) / 5 + 1;
    unsigned long month = mp + (mp < 10 ? 3 : (unsigned long)-9);
    year += (month <= 2);
    *out_year = year;
    *out_month = (int)month;
    *out_day = (int)day;
}

static long long days_from_civil(long long y, int m, int d)
{
    y -= m <= 2;
    long long era = (y >= 0 ? y : y - 399) / 400;
    unsigned long yoe = (unsigned long)(y - era * 400);
    unsigned long doy =
        (unsigned long)((153 * (m + (m > 2 ? -3 : 9)) + 2) / 5 + d - 1);
    unsigned long doe = yoe * 365 + yoe / 4 - yoe / 100 + doy;
    return era * 146097 + (long long)doe - 719468;
}

static const char base64_chars[] =
    "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

static void plist_write_base64(NSMutableString *out, const unsigned char *bytes,
                               unsigned long length)
{
    char quad[5];
    for (unsigned long i = 0; i < length; i += 3)
    {
        unsigned long v = (unsigned long)bytes[i] << 16;
        if (i + 1 < length)
            v |= (unsigned long)bytes[i + 1] << 8;
        if (i + 2 < length)
            v |= bytes[i + 2];
        quad[0] = base64_chars[(v >> 18) & 63];
        quad[1] = base64_chars[(v >> 12) & 63];
        quad[2] = i + 1 < length ? base64_chars[(v >> 6) & 63] : '=';
        quad[3] = i + 2 < length ? base64_chars[v & 63] : '=';
        quad[4] = 0;
        [out appendString:[NSString stringWithUTF8String:quad]];
    }
}

static BOOL plist_write_value(NSMutableString *out, id value, int depth)
{
    if (!value || [value isKindOfClass:[NSNull class]])
        return NO;
    if ([value isKindOfClass:[NSString class]])
    {
        [out appendString:@"<string>"];
        plist_write_escaped(out, iosim_string_cstr(value));
        [out appendString:@"</string>"];
        return YES;
    }
    if ([value isKindOfClass:[NSNumber class]])
    {
        NSNumber *number = (NSNumber *)value;
        char buf[64];
        if (number->_kind == 2)
            [out appendString:number->_ival ? @"<true/>" : @"<false/>"];
        else if (number->_kind == 1)
        {
            snprintf(buf, sizeof(buf), "<real>%.15g</real>", number->_dval);
            [out appendString:[NSString stringWithUTF8String:buf]];
        }
        else
        {
            snprintf(buf, sizeof(buf), "<integer>%lld</integer>",
                     number->_ival);
            [out appendString:[NSString stringWithUTF8String:buf]];
        }
        return YES;
    }
    if ([value isKindOfClass:[NSDate class]])
    {
        double interval = [(NSDate *)value timeIntervalSince1970];
        long long secs = (long long)interval;
        if (secs < 0)
            secs = 0;
        long long days = secs / 86400;
        long long rem = secs % 86400;
        long long year;
        int month, day;
        civil_from_days(days, &year, &month, &day);
        char buf[64];
        snprintf(buf, sizeof(buf), "<date>%04lld-%02d-%02dT%02lld:%02lld:%02lldZ</date>",
                 year, month, day, rem / 3600, (rem / 60) % 60, rem % 60);
        [out appendString:[NSString stringWithUTF8String:buf]];
        return YES;
    }
    if ([value isKindOfClass:[NSData class]])
    {
        NSData *data = (NSData *)value;
        [out appendString:@"<data>"];
        plist_write_base64(out, (const unsigned char *)[data bytes],
                           [data length]);
        [out appendString:@"</data>"];
        return YES;
    }
    if ([value isKindOfClass:[NSArray class]])
    {
        NSArray *array = (NSArray *)value;
        unsigned long count = [array count];
        if (count == 0)
        {
            [out appendString:@"<array/>"];
            return YES;
        }
        [out appendString:@"<array>"];
        for (unsigned long i = 0; i < count; i++)
        {
            plist_indent(out, depth + 1);
            if (!plist_write_value(out, [array objectAtIndex:i], depth + 1))
                return NO;
        }
        plist_indent(out, depth);
        [out appendString:@"</array>"];
        return YES;
    }
    if ([value isKindOfClass:[NSDictionary class]])
    {
        NSDictionary *dict = (NSDictionary *)value;
        NSArray *keys = [dict allKeys];
        unsigned long count = [keys count];
        if (count == 0)
        {
            [out appendString:@"<dict/>"];
            return YES;
        }
        [out appendString:@"<dict>"];
        for (unsigned long i = 0; i < count; i++)
        {
            id key = [keys objectAtIndex:i];
            if (![key isKindOfClass:[NSString class]])
                return NO;
            plist_indent(out, depth + 1);
            [out appendString:@"<key>"];
            plist_write_escaped(out, iosim_string_cstr(key));
            [out appendString:@"</key>"];
            plist_indent(out, depth + 1);
            if (!plist_write_value(out, [dict objectForKey:key], depth + 1))
                return NO;
        }
        plist_indent(out, depth);
        [out appendString:@"</dict>"];
        return YES;
    }
    return NO;
}

struct plist_state {
    const char *s;
    unsigned long i;
    unsigned long n;
    int error;
};

static int plist_has(struct plist_state *p, const char *tag)
{
    unsigned long len = strlen(tag);
    if (p->i + len > p->n)
        return 0;
    return memcmp(p->s + p->i, tag, len) == 0;
}

static void plist_skip_misc(struct plist_state *p)
{
    for (;;)
    {
        while (p->i < p->n)
        {
            char c = p->s[p->i];
            if (c != ' ' && c != '\t' && c != '\n' && c != '\r')
                break;
            p->i++;
        }
        if (p->i + 2 <= p->n && p->s[p->i] == '<' && p->s[p->i + 1] == '?')
        {
            while (p->i + 1 < p->n &&
                   !(p->s[p->i] == '?' && p->s[p->i + 1] == '>'))
                p->i++;
            p->i += 2;
            continue;
        }
        if (p->i + 4 <= p->n && memcmp(p->s + p->i, "<!--", 4) == 0)
        {
            while (p->i + 2 < p->n &&
                   !(p->s[p->i] == '-' && p->s[p->i + 1] == '-' &&
                     p->s[p->i + 2] == '>'))
                p->i++;
            p->i += 3;
            continue;
        }
        if (p->i + 9 <= p->n && memcmp(p->s + p->i, "<!DOCTYPE", 9) == 0)
        {
            while (p->i < p->n && p->s[p->i] != '>')
                p->i++;
            if (p->i < p->n)
                p->i++;
            continue;
        }
        break;
    }
}

static NSString *plist_unescape(const char *s, unsigned long len)
{
    char *buf = malloc(len + 1);
    if (!buf)
        return nil;
    unsigned long o = 0;
    for (unsigned long i = 0; i < len; i++)
    {
        if (s[i] != '&')
        {
            buf[o++] = s[i];
            continue;
        }
        if (i + 5 <= len && memcmp(s + i, "&amp;", 5) == 0)
        {
            buf[o++] = '&';
            i += 4;
        }
        else if (i + 4 <= len && memcmp(s + i, "&lt;", 4) == 0)
        {
            buf[o++] = '<';
            i += 3;
        }
        else if (i + 4 <= len && memcmp(s + i, "&gt;", 4) == 0)
        {
            buf[o++] = '>';
            i += 3;
        }
        else if (i + 6 <= len && memcmp(s + i, "&quot;", 6) == 0)
        {
            buf[o++] = '"';
            i += 5;
        }
        else if (i + 6 <= len && memcmp(s + i, "&apos;", 6) == 0)
        {
            buf[o++] = '\'';
            i += 5;
        }
        else
            buf[o++] = '&';
    }
    buf[o] = 0;
    NSString *text = [NSString stringWithUTF8String:buf];
    free(buf);
    return text;
}

static int plist_raw_until(struct plist_state *p, const char *close,
                           const char **out, unsigned long *out_len)
{
    unsigned long clen = strlen(close);
    unsigned long start = p->i;
    while (p->i + clen <= p->n && memcmp(p->s + p->i, close, clen) != 0)
        p->i++;
    if (p->i + clen > p->n)
    {
        p->error = 1;
        return -1;
    }
    *out = p->s + start;
    *out_len = p->i - start;
    p->i += clen;
    return 0;
}

static long long plist_parse_integer(const char *s, unsigned long len)
{
    unsigned long i = 0;
    int negative = 0;
    long long value = 0;
    while (i < len && (s[i] == ' ' || s[i] == '\t' || s[i] == '\n'))
        i++;
    if (i < len && (s[i] == '-' || s[i] == '+'))
    {
        negative = s[i] == '-';
        i++;
    }
    while (i < len && s[i] >= '0' && s[i] <= '9')
    {
        value = value * 10 + (s[i] - '0');
        i++;
    }
    return negative ? -value : value;
}

static double plist_parse_date(const char *s, unsigned long len)
{
    if (len < 19)
        return 0;
    long long year = plist_parse_integer(s, 4);
    int month = (int)plist_parse_integer(s + 5, 2);
    int day = (int)plist_parse_integer(s + 8, 2);
    int hour = (int)plist_parse_integer(s + 11, 2);
    int minute = (int)plist_parse_integer(s + 14, 2);
    int second = (int)plist_parse_integer(s + 17, 2);
    if (year < 1 || month < 1 || month > 12 || day < 1 || day > 31)
        return 0;
    return (double)(days_from_civil(year, month, day) * 86400 +
                    hour * 3600 + minute * 60 + second);
}

static int base64_value(char c)
{
    if (c >= 'A' && c <= 'Z') return c - 'A';
    if (c >= 'a' && c <= 'z') return c - 'a' + 26;
    if (c >= '0' && c <= '9') return c - '0' + 52;
    if (c == '+') return 62;
    if (c == '/') return 63;
    return -1;
}

static NSData *plist_base64_decode(const char *s, unsigned long len)
{
    unsigned char *bytes = malloc(len / 4 * 3 + 4);
    if (!bytes)
        return nil;
    unsigned long o = 0;
    int quad[4];
    int q = 0, pad = 0;
    for (unsigned long i = 0; i < len; i++)
    {
        char c = s[i];
        if (c == ' ' || c == '\t' || c == '\n' || c == '\r')
            continue;
        if (c == '=')
        {
            quad[q++] = -2;
            pad++;
        }
        else
        {
            int v = base64_value(c);
            if (v < 0)
            {
                free(bytes);
                return nil;
            }
            quad[q++] = v;
        }
        if (q == 4)
        {
            long v = ((long)quad[0] << 18) | ((long)quad[1] << 12) |
                     ((long)(quad[2] < 0 ? 0 : quad[2]) << 6) |
                     (long)(quad[3] < 0 ? 0 : quad[3]);
            bytes[o++] = (unsigned char)((v >> 16) & 255);
            if (pad < 2)
                bytes[o++] = (unsigned char)((v >> 8) & 255);
            if (pad < 1)
                bytes[o++] = (unsigned char)(v & 255);
            q = 0;
            pad = 0;
        }
    }
    NSData *data = [[NSData alloc] initWithBytes:bytes length:o];
    free(bytes);
    return data;
}

static id plist_parse_value(struct plist_state *p, int depth)
{
    if (depth > 64)
    {
        p->error = 1;
        return nil;
    }
    plist_skip_misc(p);
    if (plist_has(p, "<dict/>"))
    {
        p->i += 7;
        return [NSMutableDictionary dictionary];
    }
    if (plist_has(p, "<dict>"))
    {
        p->i += 6;
        NSMutableDictionary *dict = [NSMutableDictionary dictionary];
        for (;;)
        {
            plist_skip_misc(p);
            if (plist_has(p, "</dict>"))
            {
                p->i += 7;
                return dict;
            }
            if (!plist_has(p, "<key>"))
            {
                p->error = 1;
                return nil;
            }
            p->i += 5;
            const char *raw = 0;
            unsigned long raw_len = 0;
            if (plist_raw_until(p, "</key>", &raw, &raw_len) != 0)
                return nil;
            NSString *key = plist_unescape(raw, raw_len);
            id value = plist_parse_value(p, depth + 1);
            if (!key || !value)
                return nil;
            [dict setObject:value forKey:key];
        }
    }
    if (plist_has(p, "<array/>"))
    {
        p->i += 8;
        return [NSMutableArray array];
    }
    if (plist_has(p, "<array>"))
    {
        p->i += 7;
        NSMutableArray *array = [NSMutableArray array];
        for (;;)
        {
            plist_skip_misc(p);
            if (plist_has(p, "</array>"))
            {
                p->i += 8;
                return array;
            }
            id value = plist_parse_value(p, depth + 1);
            if (!value)
                return nil;
            [array addObject:value];
        }
    }
    if (plist_has(p, "<string/>"))
    {
        p->i += 9;
        return [NSString stringWithUTF8String:""];
    }
    if (plist_has(p, "<string>"))
    {
        p->i += 8;
        const char *raw = 0;
        unsigned long raw_len = 0;
        if (plist_raw_until(p, "</string>", &raw, &raw_len) != 0)
            return nil;
        return plist_unescape(raw, raw_len);
    }
    if (plist_has(p, "<integer>"))
    {
        p->i += 9;
        const char *raw = 0;
        unsigned long raw_len = 0;
        if (plist_raw_until(p, "</integer>", &raw, &raw_len) != 0)
            return nil;
        return [NSNumber numberWithLongLong:plist_parse_integer(raw, raw_len)];
    }
    if (plist_has(p, "<real>"))
    {
        p->i += 6;
        const char *raw = 0;
        unsigned long raw_len = 0;
        if (plist_raw_until(p, "</real>", &raw, &raw_len) != 0)
            return nil;
        char buf[64];
        unsigned long n = raw_len < sizeof(buf) - 1 ? raw_len : sizeof(buf) - 1;
        memcpy(buf, raw, n);
        buf[n] = 0;
        return [NSNumber numberWithDouble:strtod(buf, 0)];
    }
    if (plist_has(p, "<true/>"))
    {
        p->i += 7;
        return [NSNumber numberWithBool:YES];
    }
    if (plist_has(p, "<false/>"))
    {
        p->i += 8;
        return [NSNumber numberWithBool:NO];
    }
    if (plist_has(p, "<true>"))
    {
        p->i += 6;
        if (!plist_has(p, "</true>"))
        {
            p->error = 1;
            return nil;
        }
        p->i += 7;
        return [NSNumber numberWithBool:YES];
    }
    if (plist_has(p, "<false>"))
    {
        p->i += 7;
        if (!plist_has(p, "</false>"))
        {
            p->error = 1;
            return nil;
        }
        p->i += 8;
        return [NSNumber numberWithBool:NO];
    }
    if (plist_has(p, "<data>"))
    {
        p->i += 6;
        const char *raw = 0;
        unsigned long raw_len = 0;
        if (plist_raw_until(p, "</data>", &raw, &raw_len) != 0)
            return nil;
        return plist_base64_decode(raw, raw_len);
    }
    if (plist_has(p, "<date>"))
    {
        p->i += 6;
        const char *raw = 0;
        unsigned long raw_len = 0;
        if (plist_raw_until(p, "</date>", &raw, &raw_len) != 0)
            return nil;
        return [NSDate dateWithTimeIntervalSince1970:
                    plist_parse_date(raw, raw_len)];
    }
    p->error = 1;
    return nil;
}

@implementation NSPropertyListSerialization
+ (id)dataWithPropertyList:(id)plist format:(unsigned long)format
                   options:(unsigned long)options error:(id *)error
{
    (void)format;
    (void)options;
    NSMutableString *text = [NSMutableString string];
    [text appendString:
        @"<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n"
        @"<!DOCTYPE plist PUBLIC \"-//Apple//DTD PLIST 1.0//EN\" "
        @"\"http://www.apple.com/DTDs/PropertyList-1.0.dtd\">\n"
        @"<plist version=\"1.0\">"];
    if (!plist)
    {
        if (error)
            *error = [NSError errorWithDomain:@"NSCocoaErrorDomain" code:3840
                                       userInfo:nil];
        return nil;
    }
    [text appendString:@"\n"];
    if (!plist_write_value(text, plist, 0))
    {
        if (error)
            *error = [NSError errorWithDomain:@"NSCocoaErrorDomain" code:3840
                                       userInfo:nil];
        return nil;
    }
    [text appendString:@"\n</plist>\n"];
    return [text dataUsingEncoding:4];
}
+ (id)propertyListWithData:(id)data options:(unsigned long)options
                    format:(unsigned long *)format error:(id *)error
{
    (void)options;
    if (!data || [data length] == 0)
    {
        if (error)
            *error = [NSError errorWithDomain:@"NSCocoaErrorDomain" code:3840
                                       userInfo:nil];
        return nil;
    }
    struct plist_state p;
    p.s = (const char *)[data bytes];
    p.i = 0;
    p.n = [data length];
    p.error = 0;
    plist_skip_misc(&p);
    if (!plist_has(&p, "<plist"))
    {
        if (error)
            *error = [NSError errorWithDomain:@"NSCocoaErrorDomain" code:3840
                                       userInfo:nil];
        return nil;
    }
    while (p.i < p.n && p.s[p.i] != '>')
        p.i++;
    if (p.i < p.n)
        p.i++;
    id value = plist_parse_value(&p, 0);
    plist_skip_misc(&p);
    if (!value || p.error || !plist_has(&p, "</plist>"))
    {
        if (error)
            *error = [NSError errorWithDomain:@"NSCocoaErrorDomain" code:3840
                                       userInfo:nil];
        return nil;
    }
    if (format)
        *format = NSPropertyListXMLFormat_v1_0;
    return value;
}
@end

@implementation NSJSONSerialization
+ (BOOL)isValidJSONObject:(id)object
{
    NSMutableString *scratch = [NSMutableString string];
    return object && json_write_value(scratch, object, NO, 0);
}
+ (id)dataWithJSONObject:(id)object options:(unsigned long)options
                   error:(id *)error
{
    (void)options;
    NSMutableString *text = [NSMutableString string];
    if (!object || !json_write_value(text, object, NO, 0))
    {
        if (error)
            *error = [NSError errorWithDomain:@"NSCocoaErrorDomain" code:3840
                                       userInfo:nil];
        return nil;
    }
    return [text dataUsingEncoding:4];
}
+ (id)JSONObjectWithData:(id)data options:(unsigned long)options
                   error:(id *)error
{
    (void)options;
    if (!data)
        return nil;
    struct json_state p;
    p.s = (const char *)[data bytes];
    p.i = 0;
    p.n = [data length];
    p.error = 0;
    id value = json_parse_value(&p, 0);
    json_skip_ws(&p);
    if (!value || p.error || p.i != p.n)
    {
        if (error)
            *error = [NSError errorWithDomain:@"NSCocoaErrorDomain" code:3840
                                       userInfo:nil];
        return nil;
    }
    return value;
}
@end

@implementation NSNull
+ (id)null
{
    static NSNull *null;
    if (!null)
        null = [[self alloc] init];
    return null;
}
- (BOOL)isEqual:(id)other { return other == self; }
- (unsigned long)hash { return 0; }
- (id)description { return @"<null>"; }
@end

/* ------------------------------------------------------ keyed archiving */

@implementation NSCoder
- (void)encodeObject:(id)object forKey:(id)key { (void)object; (void)key; }
- (void)encodeInteger:(long)value forKey:(id)key { (void)value; (void)key; }
- (void)encodeInt:(int)value forKey:(id)key { (void)value; (void)key; }
- (void)encodeBool:(BOOL)value forKey:(id)key { (void)value; (void)key; }
- (void)encodeFloat:(float)value forKey:(id)key { (void)value; (void)key; }
- (void)encodeDouble:(double)value forKey:(id)key { (void)value; (void)key; }
- (BOOL)containsValueForKey:(id)key { (void)key; return NO; }
- (id)decodeObjectForKey:(id)key { (void)key; return nil; }
- (long)decodeIntegerForKey:(id)key { (void)key; return 0; }
- (int)decodeIntForKey:(id)key { (void)key; return 0; }
- (BOOL)decodeBoolForKey:(id)key { (void)key; return NO; }
- (float)decodeFloatForKey:(id)key { (void)key; return 0; }
- (double)decodeDoubleForKey:(id)key { (void)key; return 0; }
@end

/* A UID reference in the archive plist: <dict><key>CF$UID</key><integer>N
 * </integer></dict>, the same shape Foundation writes. */
static id keyed_uid(long index)
{
    NSMutableDictionary *ref = [NSMutableDictionary dictionary];
    [ref setObject:[NSNumber numberWithInteger:index] forKey:@"CF$UID"];
    return ref;
}

static long keyed_uid_value(id value)
{
    if (!value || ![value isKindOfClass:[NSDictionary class]])
        return -1;
    NSDictionary *ref = (NSDictionary *)value;
    if ([ref count] != 1)
        return -1;
    id index = [ref objectForKey:@"CF$UID"];
    if (!index || ![index isKindOfClass:[NSNumber class]])
        return -1;
    return [index integerValue];
}

/* Append a class description ("$classname" plus its "$classes" chain) to
 * $objects once per name and return its index. */
static long keyed_class(NSKeyedArchiver *archiver, const char *name,
                        const char *superName)
{
    NSString *key = [NSString stringWithUTF8String:name];
    id known = [archiver->_classMap objectForKey:key];
    if (known)
        return [known integerValue];
    NSMutableArray *chain = [NSMutableArray array];
    [chain addObject:key];
    if (superName && *superName && strcmp(superName, name) != 0 &&
        strcmp(superName, "NSObject") != 0)
        [chain addObject:[NSString stringWithUTF8String:superName]];
    [chain addObject:@"NSObject"];
    NSMutableDictionary *entry = [NSMutableDictionary dictionary];
    [entry setObject:key forKey:@"$classname"];
    [entry setObject:chain forKey:@"$classes"];
    long index = (long)[archiver->_objects count];
    [archiver->_objects addObject:entry];
    [archiver->_classMap setObject:[NSNumber numberWithInteger:index]
                            forKey:key];
    return index;
}

static id keyed_archive_object(NSKeyedArchiver *archiver, id object);
static long keyed_find(NSKeyedArchiver *archiver, id object)
{
    unsigned long count = [archiver->_objects count];
    for (unsigned long i = 1; i < count; i++)
        if ([archiver->_objects objectAtIndex:i] == object)
            return (long)i;
    return -1;
}

static id keyed_append(NSKeyedArchiver *archiver, id entry)
{
    long index = (long)[archiver->_objects count];
    [archiver->_objects addObject:entry];
    return keyed_uid(index);
}

static id keyed_archive_object(NSKeyedArchiver *archiver, id object)
{
    if (!object)
        return keyed_uid(0);
    long found = keyed_find(archiver, object);
    if (found >= 0)
        return keyed_uid(found);

    /* Strings, numbers, data and dates live directly in $objects. */
    if ([object isKindOfClass:[NSString class]] ||
        [object isKindOfClass:[NSNumber class]] ||
        [object isKindOfClass:[NSData class]] ||
        [object isKindOfClass:[NSDate class]])
        return keyed_append(archiver, object);

    if ([object isKindOfClass:[NSNull class]])
    {
        NSMutableDictionary *entry = [NSMutableDictionary dictionary];
        [entry setObject:keyed_uid(keyed_class(archiver, "NSNull", "NSObject"))
                  forKey:@"$class"];
        return keyed_append(archiver, entry);
    }

    if ([object isKindOfClass:[NSArray class]])
    {
        const char *name =
            [object isKindOfClass:[NSMutableArray class]] ? "NSMutableArray"
                                                          : "NSArray";
        NSMutableDictionary *entry = [NSMutableDictionary dictionary];
        [entry setObject:keyed_uid(keyed_class(archiver, name, "NSArray"))
                  forKey:@"$class"];
        NSMutableArray *refs = [NSMutableArray array];
        [entry setObject:refs forKey:@"NS.objects"];
        /* Reserve the entry before encoding children so cycles resolve. */
        id ref = keyed_append(archiver, entry);
        NSArray *array = (NSArray *)object;
        for (unsigned long i = 0; i < [array count]; i++)
            [refs addObject:keyed_archive_object(archiver,
                                                 [array objectAtIndex:i])];
        return ref;
    }

    if ([object isKindOfClass:[NSDictionary class]])
    {
        const char *name = [object isKindOfClass:[NSMutableDictionary class]]
                               ? "NSMutableDictionary"
                               : "NSDictionary";
        NSMutableDictionary *entry = [NSMutableDictionary dictionary];
        [entry setObject:keyed_uid(keyed_class(archiver, name, "NSDictionary"))
                  forKey:@"$class"];
        NSMutableArray *keyRefs = [NSMutableArray array];
        NSMutableArray *valueRefs = [NSMutableArray array];
        [entry setObject:keyRefs forKey:@"NS.keys"];
        [entry setObject:valueRefs forKey:@"NS.objects"];
        id ref = keyed_append(archiver, entry);
        NSDictionary *dict = (NSDictionary *)object;
        NSArray *keys = [dict allKeys];
        for (unsigned long i = 0; i < [keys count]; i++)
        {
            id key = [keys objectAtIndex:i];
            [keyRefs addObject:keyed_archive_object(archiver, key)];
            [valueRefs addObject:keyed_archive_object(
                                     archiver, [dict objectForKey:key])];
        }
        return ref;
    }

    if ([object isKindOfClass:[NSSet class]])
    {
        const char *name = [object isKindOfClass:[NSMutableSet class]]
                               ? "NSMutableSet"
                               : "NSSet";
        NSMutableDictionary *entry = [NSMutableDictionary dictionary];
        [entry setObject:keyed_uid(keyed_class(archiver, name, "NSSet"))
                  forKey:@"$class"];
        NSMutableArray *refs = [NSMutableArray array];
        [entry setObject:refs forKey:@"NS.objects"];
        id ref = keyed_append(archiver, entry);
        NSArray *items = [(NSSet *)object allObjects];
        for (unsigned long i = 0; i < [items count]; i++)
            [refs addObject:keyed_archive_object(archiver,
                                                 [items objectAtIndex:i])];
        return ref;
    }

    /* Any other object encodes through NSCoding: the entry collects the
     * keys encodeWithCoder: writes while it is the current container. */
    void *cls = iosim_objc_class_of(object);
    const char *name = cls ? class_getName(cls) : 0;
    if (!name || !*name)
        return keyed_uid(0);
    void *super = iosim_objc_superclass(cls);
    const char *superName = super ? class_getName(super) : 0;
    NSMutableDictionary *entry = [NSMutableDictionary dictionary];
    [entry setObject:keyed_uid(keyed_class(archiver, name, superName))
              forKey:@"$class"];
    id ref = keyed_append(archiver, entry);
    if ([object respondsToSelector:@selector(encodeWithCoder:)])
    {
        id saved = archiver->_current;
        archiver->_current = entry;
        [object encodeWithCoder:archiver];
        archiver->_current = saved;
    }
    return ref;
}

@implementation NSKeyedArchiver
- (id)initForWritingWithMutableData:(id)data
{
    self = [super init];
    if (self)
    {
        _out = data;
        _objects = [NSMutableArray array];
        [_objects addObject:@"$null"];
        _top = [NSMutableDictionary dictionary];
        _classMap = [NSMutableDictionary dictionary];
    }
    return self;
}
- (id)init
{
    return [self initForWritingWithMutableData:[NSMutableData data]];
}
- (void)encodeObject:(id)object forKey:(id)key
{
    if (!key)
        return;
    id target = _current ? _current : _top;
    [target setObject:keyed_archive_object(self, object) forKey:key];
}
- (void)encodeInteger:(long)value forKey:(id)key
{
    if (key)
        [(id)(_current ? _current : _top)
            setObject:[NSNumber numberWithInteger:value]
            forKey:key];
}
- (void)encodeInt:(int)value forKey:(id)key
{
    [self encodeInteger:(long)value forKey:key];
}
- (void)encodeBool:(BOOL)value forKey:(id)key
{
    if (key)
        [(id)(_current ? _current : _top)
            setObject:[NSNumber numberWithBool:value]
            forKey:key];
}
- (void)encodeFloat:(float)value forKey:(id)key
{
    [self encodeDouble:(double)value forKey:key];
}
- (void)encodeDouble:(double)value forKey:(id)key
{
    if (key)
        [(id)(_current ? _current : _top)
            setObject:[NSNumber numberWithDouble:value]
            forKey:key];
}
- (void)finishEncoding
{
    NSMutableDictionary *archive = [NSMutableDictionary dictionary];
    [archive setObject:@"NSKeyedArchiver" forKey:@"$archiver"];
    [archive setObject:[NSNumber numberWithInteger:100000] forKey:@"$version"];
    [archive setObject:_top ? _top : [NSMutableDictionary dictionary]
                forKey:@"$top"];
    [archive setObject:_objects ? _objects : [NSMutableArray array]
                forKey:@"$objects"];
    id data = [NSPropertyListSerialization
        dataWithPropertyList:archive format:NSPropertyListXMLFormat_v1_0
        options:0 error:0];
    if (!data)
        return;
    if (_out)
        [_out appendData:data];
    else
        _out = data;
}
+ (id)archivedDataWithRootObject:(id)rootObject
{
    NSMutableData *out = [NSMutableData data];
    NSKeyedArchiver *archiver =
        [[self alloc] initForWritingWithMutableData:out];
    [archiver encodeObject:rootObject forKey:@"root"];
    [archiver finishEncoding];
    return out;
}
+ (id)archivedDataWithRootObject:(id)rootObject
             requiringSecureCoding:(BOOL)requiringSecureCoding
                             error:(id *)error
{
    (void)requiringSecureCoding;
    (void)error;
    return [self archivedDataWithRootObject:rootObject];
}
+ (BOOL)archiveRootObject:(id)rootObject toFile:(id)path
{
    id data = [self archivedDataWithRootObject:rootObject];
    return data ? [data writeToFile:path atomically:YES] : NO;
}
@end

static id keyed_resolve(NSKeyedUnarchiver *unarchiver, long index)
{
    if (index <= 0 || (unsigned long)index >= unarchiver->_objectCount)
        return nil;
    if (unarchiver->_state[index] == 2)
        return unarchiver->_resolved[index];
    if (unarchiver->_state[index] == 1)
        return unarchiver->_resolved[index];

    id entry = [unarchiver->_objects objectAtIndex:(unsigned long)index];
    if (!entry)
        return nil;
    if ([entry isKindOfClass:[NSString class]] ||
        [entry isKindOfClass:[NSNumber class]] ||
        [entry isKindOfClass:[NSData class]] ||
        [entry isKindOfClass:[NSDate class]])
    {
        unarchiver->_state[index] = 2;
        unarchiver->_resolved[index] = entry;
        return entry;
    }
    if (![entry isKindOfClass:[NSDictionary class]])
    {
        unarchiver->_state[index] = 2;
        unarchiver->_resolved[index] = entry;
        return entry;
    }

    long indirect = keyed_uid_value(entry);
    if (indirect >= 0)
    {
        id value = keyed_resolve(unarchiver, indirect);
        unarchiver->_state[index] = 2;
        unarchiver->_resolved[index] = value;
        return value;
    }

    long classIndex = keyed_uid_value([entry objectForKey:@"$class"]);
    id classEntry =
        classIndex > 0 && (unsigned long)classIndex < unarchiver->_objectCount
            ? [unarchiver->_objects objectAtIndex:(unsigned long)classIndex]
            : nil;
    id className = [classEntry isKindOfClass:[NSDictionary class]]
                       ? [(NSDictionary *)classEntry objectForKey:@"$classname"]
                       : nil;
    const char *name = iosim_string_cstr(className);

    if (strcmp(name, "NSNull") == 0)
    {
        id value = [NSNull null];
        unarchiver->_state[index] = 2;
        unarchiver->_resolved[index] = value;
        return value;
    }
    if (strcmp(name, "NSArray") == 0 || strcmp(name, "NSMutableArray") == 0)
    {
        NSMutableArray *array = [NSMutableArray array];
        unarchiver->_state[index] = 1;
        unarchiver->_resolved[index] = array;
        id refs = [entry objectForKey:@"NS.objects"];
        for (unsigned long i = 0; refs && i < [refs count]; i++)
        {
            long ref = keyed_uid_value([refs objectAtIndex:i]);
            id value = ref >= 0 ? keyed_resolve(unarchiver, ref)
                                : [refs objectAtIndex:i];
            [array addObject:value ? value : [NSNull null]];
        }
        unarchiver->_state[index] = 2;
        return array;
    }
    if (strcmp(name, "NSDictionary") == 0 ||
        strcmp(name, "NSMutableDictionary") == 0)
    {
        NSMutableDictionary *dict = [NSMutableDictionary dictionary];
        unarchiver->_state[index] = 1;
        unarchiver->_resolved[index] = dict;
        id keyRefs = [entry objectForKey:@"NS.keys"];
        id valueRefs = [entry objectForKey:@"NS.objects"];
        for (unsigned long i = 0; keyRefs && valueRefs && i < [keyRefs count] &&
                                   i < [valueRefs count]; i++)
        {
            long keyRef = keyed_uid_value([keyRefs objectAtIndex:i]);
            long valueRef = keyed_uid_value([valueRefs objectAtIndex:i]);
            id key = keyRef >= 0 ? keyed_resolve(unarchiver, keyRef)
                                 : [keyRefs objectAtIndex:i];
            id value = valueRef >= 0 ? keyed_resolve(unarchiver, valueRef)
                                     : [valueRefs objectAtIndex:i];
            if (key)
                [dict setObject:value ? value : [NSNull null] forKey:key];
        }
        unarchiver->_state[index] = 2;
        return dict;
    }
    if (strcmp(name, "NSSet") == 0 || strcmp(name, "NSMutableSet") == 0)
    {
        NSMutableSet *set = [NSMutableSet set];
        unarchiver->_state[index] = 1;
        unarchiver->_resolved[index] = set;
        id refs = [entry objectForKey:@"NS.objects"];
        for (unsigned long i = 0; refs && i < [refs count]; i++)
        {
            long ref = keyed_uid_value([refs objectAtIndex:i]);
            id value = ref >= 0 ? keyed_resolve(unarchiver, ref)
                                : [refs objectAtIndex:i];
            if (value)
                [set addObject:value];
        }
        unarchiver->_state[index] = 2;
        return set;
    }

    Class cls = (Class)objc_getClass(name);
    if (!cls)
        return nil;
    id object = [cls alloc];
    unarchiver->_state[index] = 1;
    unarchiver->_resolved[index] = object;
    if ([object respondsToSelector:@selector(initWithCoder:)])
    {
        id saved = unarchiver->_current;
        unarchiver->_current = entry;
        id decoded = [object initWithCoder:unarchiver];
        unarchiver->_current = saved;
        if (decoded)
            object = decoded;
    }
    unarchiver->_state[index] = 2;
    unarchiver->_resolved[index] = object;
    return object;
}

@implementation NSKeyedUnarchiver
- (id)initForReadingWithData:(id)data
{
    self = [super init];
    if (!self)
        return nil;
    id plist = [NSPropertyListSerialization
        propertyListWithData:data options:0 format:0 error:0];
    if (!plist || ![plist isKindOfClass:[NSDictionary class]])
        return nil;
    id objects = [plist objectForKey:@"$objects"];
    if (!objects || ![objects isKindOfClass:[NSArray class]])
        return nil;
    _objects = objects;
    _top = [plist objectForKey:@"$top"];
    _objectCount = [objects count];
    _resolved = calloc(_objectCount ? _objectCount : 1, sizeof(id));
    _state = calloc(_objectCount ? _objectCount : 1, 1);
    if (!_resolved || !_state)
        return nil;
    return self;
}
- (BOOL)containsValueForKey:(id)key
{
    id container = _current ? _current : _top;
    return key && container &&
           [(NSDictionary *)container objectForKey:key] != nil;
}
- (id)decodeObjectForKey:(id)key
{
    id container = _current ? _current : _top;
    if (!key || !container)
        return nil;
    id value = [(NSDictionary *)container objectForKey:key];
    if (!value)
        return nil;
    long ref = keyed_uid_value(value);
    if (ref >= 0)
        return keyed_resolve(self, ref);
    return value;
}
- (long)decodeIntegerForKey:(id)key
{
    id value = [self decodeObjectForKey:key];
    return value && [value respondsToSelector:@selector(integerValue)]
               ? [value integerValue]
               : 0;
}
- (int)decodeIntForKey:(id)key
{
    return (int)[self decodeIntegerForKey:key];
}
- (BOOL)decodeBoolForKey:(id)key
{
    id value = [self decodeObjectForKey:key];
    return value && [value respondsToSelector:@selector(boolValue)]
               ? [value boolValue]
               : NO;
}
- (float)decodeFloatForKey:(id)key
{
    return (float)[self decodeDoubleForKey:key];
}
- (double)decodeDoubleForKey:(id)key
{
    id value = [self decodeObjectForKey:key];
    return value && [value respondsToSelector:@selector(doubleValue)]
               ? [value doubleValue]
               : 0;
}
- (void)finishDecoding { }
+ (id)unarchiveObjectWithData:(id)data
{
    if (!data)
        return nil;
    NSKeyedUnarchiver *unarchiver =
        [[self alloc] initForReadingWithData:data];
    if (!unarchiver)
        return nil;
    id object = [unarchiver decodeObjectForKey:@"root"];
    [unarchiver finishDecoding];
    return object;
}
+ (id)unarchiveObjectWithFile:(id)path
{
    return [self unarchiveObjectWithData:[NSData dataWithContentsOfFile:path]];
}
+ (id)unarchivedObjectOfClass:(Class)cls fromData:(id)data error:(id *)error
{
    id object = [self unarchiveObjectWithData:data];
    if (cls && object && ![object isKindOfClass:cls])
    {
        if (error)
            *error = [NSError errorWithDomain:@"NSCocoaErrorDomain" code:4864
                                       userInfo:nil];
        return nil;
    }
    return object;
}
@end

/* ------------------------------------------------------------ calendars */

id NSCalendarIdentifierGregorian = @"NSCalendarIdentifierGregorian";

@implementation NSDateComponents
- (long)era { return _era; }
- (void)setEra:(long)value { _era = value; }
- (long)year { return _year; }
- (void)setYear:(long)value { _year = value; }
- (long)month { return _month; }
- (void)setMonth:(long)value { _month = value; }
- (long)day { return _day; }
- (void)setDay:(long)value { _day = value; }
- (long)hour { return _hour; }
- (void)setHour:(long)value { _hour = value; }
- (long)minute { return _minute; }
- (void)setMinute:(long)value { _minute = value; }
- (long)second { return _second; }
- (void)setSecond:(long)value { _second = value; }
- (long)nanosecond { return _nanosecond; }
- (void)setNanosecond:(long)value { _nanosecond = value; }
- (long)weekday { return _weekday; }
- (void)setWeekday:(long)value { _weekday = value; }
- (long)weekOfYear { return _weekOfYear; }
- (void)setWeekOfYear:(long)value { _weekOfYear = value; }
@end

@implementation NSCalendar
+ (NSCalendar *)currentCalendar
{
    static NSCalendar *calendar;
    if (!calendar)
        calendar = [[self alloc]
            initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
    return calendar;
}
+ (NSCalendar *)calendarWithIdentifier:(id)identifier
{
    return [[self alloc] initWithCalendarIdentifier:identifier];
}
- (id)initWithCalendarIdentifier:(id)identifier
{
    self = [super init];
    if (self)
        _identifier = identifier;
    return self;
}
- (id)calendarIdentifier { return _identifier; }
- (NSDateComponents *)components:(unsigned long)unitFlags
                        fromDate:(NSDate *)date
{
    NSDateComponents *components = [[NSDateComponents alloc] init];
    if (!date)
        return components;
    double seconds = [date timeIntervalSince1970];
    long long whole = (long long)seconds;
    if (seconds < 0 && seconds != (double)whole)
        whole--;
    long long days = whole / 86400;
    long long sod = whole % 86400;
    if (sod < 0)
    {
        sod += 86400;
        days--;
    }
    long long year;
    int month, day;
    civil_from_days(days, &year, &month, &day);
    long long weekday = ((days % 7) + 7 + 4) % 7 + 1;
    if (unitFlags & NSCalendarUnitEra)
        components->_era = 1;
    if (unitFlags & NSCalendarUnitYear)
        components->_year = (long)year;
    if (unitFlags & NSCalendarUnitMonth)
        components->_month = month;
    if (unitFlags & NSCalendarUnitDay)
        components->_day = day;
    if (unitFlags & NSCalendarUnitHour)
        components->_hour = (long)(sod / 3600);
    if (unitFlags & NSCalendarUnitMinute)
        components->_minute = (long)((sod / 60) % 60);
    if (unitFlags & NSCalendarUnitSecond)
        components->_second = (long)(sod % 60);
    if (unitFlags & NSCalendarUnitWeekday)
        components->_weekday = (long)weekday;
    if (unitFlags & NSCalendarUnitWeekOfYear)
    {
        long long iso = (weekday + 5) % 7 + 1; /* Monday = 1 */
        components->_weekOfYear = (long)((days - iso + 10) / 7);
    }
    if (unitFlags & NSCalendarUnitNanosecond)
    {
        double fraction = seconds - (double)whole;
        if (fraction < 0)
            fraction += 1.0;
        components->_nanosecond = (long)(fraction * 1e9);
    }
    return components;
}
- (NSDate *)dateFromComponents:(NSDateComponents *)components
{
    if (!components)
        return nil;
    long long year = components->_year ? components->_year : 1970;
    int month = components->_month > 0 ? (int)components->_month : 1;
    int day = components->_day > 0 ? (int)components->_day : 1;
    long long seconds = days_from_civil(year, month, day) * 86400 +
                        (long long)components->_hour * 3600 +
                        (long long)components->_minute * 60 +
                        components->_second;
    double value = (double)seconds;
    if (components->_nanosecond > 0)
        value += components->_nanosecond / 1e9;
    return [NSDate dateWithTimeIntervalSince1970:value];
}
@end

/* ----------------------------------------------------------- operations */

extern void *dispatch_get_global_queue(long identifier, unsigned long flags);
extern void *dispatch_get_main_queue(void);
extern void *dispatch_group_create(void);
extern void dispatch_group_async(void *group, void *queue, void *block);
extern long dispatch_group_wait(void *group, unsigned long long timeout);

@implementation NSOperation
- (void)start
{
    if (_cancelled || _finished)
        return;
    [self main];
    _finished = YES;
    if (_completionBlock)
        ((void (^)(void))_completionBlock)();
}
- (void)main { }
- (void)cancel { _cancelled = YES; }
- (BOOL)isCancelled { return _cancelled; }
- (BOOL)isFinished { return _finished; }
- (void)setCompletionBlock:(void (^)(void))block
{
    _completionBlock = block ? (id)_Block_copy((void *)block) : nil;
}
@end

@implementation NSBlockOperation
+ (id)blockOperationWithBlock:(void (^)(void))block
{
    NSBlockOperation *operation = [[self alloc] init];
    operation->_blocks = [NSMutableArray array];
    if (block)
        [(NSMutableArray *)operation->_blocks
            addObject:(id)_Block_copy((void *)block)];
    return operation;
}
- (void)addExecutionBlock:(void (^)(void))block
{
    if (!_blocks)
        _blocks = [NSMutableArray array];
    if (block)
        [(NSMutableArray *)_blocks addObject:(id)_Block_copy((void *)block)];
}
- (void)main
{
    if (!_blocks)
        return;
    for (unsigned long i = 0; i < [(NSArray *)_blocks count]; i++)
    {
        if (_cancelled)
            return;
        void (^block)(void) =
            (void (^)(void))[(NSArray *)_blocks objectAtIndex:i];
        block();
    }
}
@end

@implementation NSOperationQueue
+ (NSOperationQueue *)mainQueue
{
    static NSOperationQueue *queue;
    if (!queue)
    {
        queue = [[self alloc] init];
        queue->_queue = dispatch_get_main_queue();
    }
    return queue;
}
- (id)init
{
    self = [super init];
    if (self)
    {
        _group = dispatch_group_create();
        _queue = dispatch_get_global_queue(0, 0);
        _operations = [NSMutableArray array];
        _maxConcurrent = -1;
    }
    return self;
}
- (void)dispatchOperation:(NSOperation *)operation
{
    if (!operation || operation->_dispatched)
        return;
    operation->_dispatched = YES;
    _pending++;
    void (^run)(void) = ^{
        [operation start];
        _pending--;
    };
    dispatch_group_async(_group, _queue, (void *)run);
}
- (void)addOperation:(NSOperation *)operation
{
    if (!operation)
        return;
    [(NSMutableArray *)_operations addObject:operation];
    if (!_suspended)
        [self dispatchOperation:operation];
}
- (void)addOperationWithBlock:(void (^)(void))block
{
    [self addOperation:[NSBlockOperation blockOperationWithBlock:block]];
}
- (void)waitUntilAllOperationsAreFinished
{
    dispatch_group_wait(_group, ~0UL);
}
- (long)operationCount { return _pending; }
- (void)setMaxConcurrentOperationCount:(long)count { _maxConcurrent = count; }
- (long)maxConcurrentOperationCount { return _maxConcurrent; }
- (void)setSuspended:(BOOL)suspended
{
    _suspended = suspended;
    if (suspended)
        return;
    for (unsigned long i = 0; i < [(NSArray *)_operations count]; i++)
        [self dispatchOperation:
            (NSOperation *)[(NSArray *)_operations objectAtIndex:i]];
}
- (BOOL)isSuspended { return _suspended; }
- (void)cancelAllOperations
{
    for (unsigned long i = 0; i < [(NSArray *)_operations count]; i++)
        [(NSOperation *)[(NSArray *)_operations objectAtIndex:i] cancel];
}
@end
