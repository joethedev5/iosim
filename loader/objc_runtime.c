#define _GNU_SOURCE
#include "objc_runtime.h"
#include "macho.h"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

/*
 * A minimal Objective-C runtime for x86_64 simulator binaries.
 *
 * This is deliberately small but follows the real objc4 structure:
 *   objc_class { isa, superclass, cache, class_data_bits_t bits }
 *   class_ro_t { flags, instanceStart, instanceSize, reserved,
 *                ivarLayout, name, baseMethods, baseProtocols,
 *                ivars, weakIvarLayout, baseProperties }
 *   method_list_t { entsizeAndFlags, count, method_t[] }
 *
 * Selectors in the Darwin ABI are pointers to their name string, so
 * dispatch can compare C strings. Method lists and classes are read
 * directly out of the loaded Mach-O images.
 */

struct objc_class_min {
    void *isa;
    void *superclass;
    uint64_t cache[2];
    uintptr_t bits;
};

struct class_ro_min {
    uint32_t flags;
    uint32_t instanceStart;
    uint32_t instanceSize;
    uint32_t reserved;
    const void *ivarLayout;
    const char *name;
    const void *baseMethods;
    const void *baseProtocols;
    const void *ivars;
    const void *weakIvarLayout;
    const void *baseProperties;
};

struct method_list_min {
    uint32_t entsizeAndFlags;
    uint32_t count;
};

struct method_min {
    void *name;
    const char *types;
    void *imp;
};

#define FAST_DATA_MASK 0x00007ffffffffff8ULL
#define MAX_CLASSES 8192

struct class_entry {
    struct objc_class_min *cls;
    const char *name;
    uint32_t instance_size;
};

struct ivar_list_min {
    uint32_t entsize;
    uint32_t count;
};

struct ivar_min {
    uint64_t *offset;
    const char *name;
    const char *type;
    uint32_t alignment;
    uint32_t size;
};

static struct class_entry g_classes[MAX_CLASSES];
static int g_nclasses;
static int g_registered_images;

/* Categories are resolved by name at lookup time instead of rewriting the
 * class's read-only method lists. */
#define MAX_CATEGORIES 512
struct category_entry {
    const char *class_name;
    const void *instance_methods;
    const void *class_methods;
};
static struct category_entry g_categories[MAX_CATEGORIES];
static int g_ncategories;

struct category_min {
    const char *name;
    void *cls;
    const void *instance_methods;
    const void *class_methods;
};

/* Classes created at runtime (KVO notifying subclasses, NSKVONotifying_Foo
 * and friends). The class and metaclass are allocated here; method lists are
 * fixed-size and grow until the class is registered. */
#define MAX_DYNAMIC_CLASSES 128
#define DYNAMIC_METHODS 32
struct dynamic_methods {
    uint32_t entsizeAndFlags;
    uint32_t count;
    struct method_min methods[DYNAMIC_METHODS];
};
struct dynamic_class {
    struct objc_class_min cls;
    struct objc_class_min meta;
    struct class_ro_min ro;
    struct class_ro_min meta_ro;
    struct dynamic_methods methods;
    char name[160];
    int registered;
};
static struct dynamic_class *g_dynamic[MAX_DYNAMIC_CLASSES];
static int g_ndynamic;

/* A zeroed cache object used for newly formed classes. */
char _objc_empty_cache[32];

const char *objc_sel_name(void *sel)
{
    return (const char *)sel;
}

static struct class_ro_min *class_ro(struct objc_class_min *cls)
{
    if (!cls)
        return NULL;
    uintptr_t bits = cls->bits;
    return (struct class_ro_min *)(bits & FAST_DATA_MASK);
}

static struct objc_class_min *class_isa(struct objc_class_min *cls)
{
    return cls ? (struct objc_class_min *)cls->isa : NULL;
}

static const char *ro_name(struct class_ro_min *ro)
{
    return (ro && ro->name) ? ro->name : "<anonymous>";
}

static void register_class(struct objc_class_min *cls, const char *name)
{
    for (int i = 0; i < g_nclasses; i++)
        if (g_classes[i].cls == cls)
            return;
    if (g_nclasses >= MAX_CLASSES)
        return;
    g_classes[g_nclasses].cls = cls;
    g_classes[g_nclasses].name = name;
    g_nclasses++;
}

static const char *category_class_name(struct iosim_image *img,
                                       void *category_addr, char *buffer,
                                       size_t buffer_size)
{
    if (!img || !img->symtab || !img->file)
        return NULL;
    const struct symtab_command *symtab = img->symtab;
    const struct nlist_64 *symbols =
        (const void *)(img->file + symtab->symoff);
    const char *strings = (const char *)(img->file + symtab->stroff);
    for (uint32_t i = 0; i < symtab->nsyms; i++)
    {
        uint64_t value = symbols[i].n_value;
        if (value != (uint64_t)(uintptr_t)category_addr &&
            value + img->slide != (uint64_t)(uintptr_t)category_addr)
            continue;
        if (symbols[i].n_strx >= symtab->strsize)
            continue;
        const char *name = strings + symbols[i].n_strx;
        const char *marker = strstr(name, "CATEGORY_");
        if (!marker)
            continue;
        marker += strlen("CATEGORY_");
        const char *end = strstr(marker, "_$_");
        if (!end || end == marker)
            continue;
        size_t length = (size_t)(end - marker);
        if (length >= buffer_size)
            length = buffer_size - 1;
        memcpy(buffer, marker, length);
        buffer[length] = 0;
        return buffer;
    }
    return NULL;
}

void iosim_objc_register_image(struct iosim_image *img)
{
    g_registered_images++;
    for (int s = 0; s < img->nsects; s++)
    {
        struct iosim_section *sec = &img->sects[s];
        if (strcmp(sec->sectname, "__objc_catlist") == 0 ||
            strcmp(sec->sectname, "__objc_catlist2") == 0)
        {
            void **list = (void **)(uintptr_t)(sec->addr + img->slide);
            size_t count = sec->size / sizeof(void *);
            for (size_t i = 0; i < count; i++)
            {
                struct category_min *category = list[i];
                if (!category || !category->name)
                    continue;
                if (g_ncategories >= MAX_CATEGORIES)
                    break;
                char class_name[160];
                const char *resolved = category_class_name(
                    img, category, class_name, sizeof(class_name));
                g_categories[g_ncategories].class_name =
                    resolved ? strdup(resolved) : category->name;
                g_categories[g_ncategories].instance_methods =
                    category->instance_methods;
                g_categories[g_ncategories].class_methods =
                    category->class_methods;
                g_ncategories++;
            }
            continue;
        }
        if (strcmp(sec->sectname, "__objc_classlist") != 0)
            continue;

        void **list = (void **)(uintptr_t)(sec->addr + img->slide);
        size_t count = sec->size / sizeof(void *);
        for (size_t i = 0; i < count; i++)
        {
            struct objc_class_min *cls = list[i];
            if (!cls)
                continue;
            struct class_ro_min *ro = class_ro(cls);
            if (!ro || !ro->name)
                continue;
            register_class(cls, ro->name);
        }
    }
}

static struct class_entry *find_class_entry(void *ptr);

static uint32_t align_up(uint32_t value, uint32_t alignment)
{
    if (alignment <= 1)
        return value;
    return (value + alignment - 1) & ~(alignment - 1);
}

/* Lay out ivars exactly like objc4's moveIvars(): a root class starts at
 * sizeof(void*) (the isa), and each ivar's offset variable is written back
 * into __objc_ivar. Clang emits those variables as zero. */
static uint32_t class_instance_size(struct objc_class_min *cls)
{
    if (!cls)
        return 0;
    struct class_entry *entry = find_class_entry(cls);
    if (entry && entry->instance_size)
        return entry->instance_size;

    uint32_t base = cls->superclass
                        ? class_instance_size((struct objc_class_min *)cls->superclass)
                        : (uint32_t)sizeof(void *);
    struct class_ro_min *ro = class_ro(cls);

    if (!cls->superclass && ro && ro->ivars)
    {
        /* A root class that declares an explicit isa ivar starts its layout
         * at offset 0, exactly like Apple's NSObject. */
        const struct ivar_list_min *list = ro->ivars;
        uint32_t entsize = list->entsize ? list->entsize : 32;
        if (entsize < sizeof(struct ivar_min))
            entsize = sizeof(struct ivar_min);
        const struct ivar_min *first =
            (const struct ivar_min *)((const uint8_t *)list + sizeof(*list));
        if (first->name && strcmp(first->name, "isa") == 0)
            base = 0;
    }

    if (ro && ro->ivars)
    {
        const struct ivar_list_min *list = ro->ivars;
        uint32_t entsize = list->entsize ? list->entsize : 32;
        if (entsize < sizeof(struct ivar_min))
            entsize = sizeof(struct ivar_min);
        const uint8_t *p = (const uint8_t *)list + sizeof(*list);
        for (uint32_t i = 0; i < list->count; i++)
        {
            const struct ivar_min *iv =
                (const struct ivar_min *)(p + (size_t)i * entsize);
            uint32_t alignment = iv->alignment ? (1u << iv->alignment) : 1u;
            base = align_up(base, alignment);
            if (getenv("IOSIM_OBJC_DEBUG"))
                fprintf(stderr,
                        "objc: ivar %s.%s entsize=%u align=%u size=%u -> %u\n",
                        ro_name(ro), iv->name ? iv->name : "?",
                        entsize, alignment, iv->size, base);
            if (iv->offset)
                *iv->offset = base;
            base += iv->size;
        }
    }

    uint32_t size = align_up(base, 8);
    if (entry)
        entry->instance_size = size;
    return size;
}

static const struct method_min *lookup_method_entry(const void *list_ptr,
                                                    const char *sel)
{
    if (!list_ptr)
        return NULL;
    const struct method_list_min *list = list_ptr;
    uint32_t entsize = list->entsizeAndFlags & 0xFFFC;
    if (list->entsizeAndFlags & 0x80000000u)
    {
        /* Relative method lists are used by newer runtimes; not yet
         * supported by this minimal runtime. */
        return NULL;
    }
    if (entsize < sizeof(struct method_min))
        entsize = sizeof(struct method_min);

    const uint8_t *base = (const uint8_t *)list + sizeof(*list);
    for (uint32_t i = 0; i < list->count; i++)
    {
        const struct method_min *m =
            (const struct method_min *)(base + (size_t)i * entsize);
        if (m->name && strcmp((const char *)m->name, sel) == 0)
            return m;
    }
    return NULL;
}

/* Swizzling cannot rewrite method lists that clang places in read-only
 * Mach-O sections, so method_setImplementation, method_exchangeImplementations
 * and class_replaceMethod record an override keyed by the method_t pointer
 * and every dispatch path resolves the effective implementation through it. */
struct method_override {
    void *method;
    void *imp;
    struct method_override *next;
};
static struct method_override *g_method_overrides;

static void *method_effective_imp(const struct method_min *m)
{
    if (!m)
        return NULL;
    for (struct method_override *o = g_method_overrides; o; o = o->next)
        if (o->method == (void *)m)
            return o->imp;
    return m->imp;
}

static void set_method_override(void *method, void *imp)
{
    for (struct method_override *o = g_method_overrides; o; o = o->next)
        if (o->method == method)
        {
            o->imp = imp;
            return;
        }
    struct method_override *o = calloc(1, sizeof(*o));
    if (!o)
        return;
    o->method = method;
    o->imp = imp;
    o->next = g_method_overrides;
    g_method_overrides = o;
}

static void *lookup_in_methods(const void *list_ptr, const char *sel)
{
    const struct method_min *m = lookup_method_entry(list_ptr, sel);
    return m ? method_effective_imp(m) : NULL;
}

static struct class_ro_min *metaclass_ro(struct objc_class_min *cls)
{
    struct objc_class_min *meta = class_isa(cls);
    if (!meta || meta == cls)
        return class_ro(cls);
    return class_ro(meta);
}

static void *lookup_category_method(const char *class_name, const char *sel,
                                    int class_methods)
{
    if (!class_name)
        return NULL;
    for (int i = 0; i < g_ncategories; i++)
    {
        if (strcmp(g_categories[i].class_name, class_name) != 0)
            continue;
        const void *list = class_methods ? g_categories[i].class_methods
                                         : g_categories[i].instance_methods;
        void *imp = lookup_in_methods(list, sel);
        if (imp)
            return imp;
    }
    return NULL;
}

static const struct method_min *lookup_category_method_entry(
    const char *class_name, const char *sel, int class_methods)
{
    if (!class_name)
        return NULL;
    for (int i = 0; i < g_ncategories; i++)
    {
        if (strcmp(g_categories[i].class_name, class_name) != 0)
            continue;
        const void *list = class_methods ? g_categories[i].class_methods
                                         : g_categories[i].instance_methods;
        const struct method_min *m = lookup_method_entry(list, sel);
        if (m)
            return m;
    }
    return NULL;
}

/* Methods added at runtime to classes that are already loaded (for example
 * by +resolveInstanceMethod:). They are kept in an injection list instead of
 * rewriting the image's read-only method lists; lookup checks the list for
 * each class while walking the superclass chain. */
struct injected_method {
    struct method_min method;
    void *cls;
    int class_method;
    struct injected_method *next;
};
#define MAX_INJECTED_METHODS 256
static struct injected_method *g_injected_methods;
static int g_ninjected_methods;

static struct injected_method *find_injected_method(void *cls,
                                                    const char *sel,
                                                    int class_method)
{
    for (struct injected_method *m = g_injected_methods; m; m = m->next)
        if (m->cls == cls && m->class_method == class_method &&
            m->method.name && strcmp((const char *)m->method.name, sel) == 0)
            return m;
    return NULL;
}

static void *lookup_instance_method(struct objc_class_min *cls, const char *sel)
{
    for (int depth = 0; cls && depth < 64; depth++)
    {
        struct injected_method *injected =
            find_injected_method(cls, sel, 0);
        if (injected)
            return method_effective_imp(&injected->method);
        struct class_ro_min *ro = class_ro(cls);
        void *imp = lookup_in_methods(ro ? ro->baseMethods : NULL, sel);
        if (imp)
            return imp;
        imp = lookup_category_method(ro_name(ro), sel, 0);
        if (imp)
            return imp;
        cls = (struct objc_class_min *)cls->superclass;
    }
    return NULL;
}

static void *lookup_class_method(struct objc_class_min *cls, const char *sel)
{
    for (int depth = 0; cls && depth < 64; depth++)
    {
        struct injected_method *injected =
            find_injected_method(cls, sel, 1);
        if (injected)
            return method_effective_imp(&injected->method);
        struct class_ro_min *ro = metaclass_ro(cls);
        void *imp = lookup_in_methods(ro ? ro->baseMethods : NULL, sel);
        if (imp)
            return imp;
        imp = lookup_category_method(ro_name(ro), sel, 1);
        if (imp)
            return imp;
        cls = (struct objc_class_min *)cls->superclass;
    }
    return NULL;
}

/* +resolveInstanceMethod: and +resolveClassMethod: get one chance per class
 * and selector, like objc4. A YES answer is expected to have installed the
 * method with class_addMethod; the lookup below picks it up. */
#define MAX_RESOLVE_ATTEMPTS 2048
struct resolve_attempt {
    void *cls;
    void *sel;
    int class_method;
};
static struct resolve_attempt g_resolve_attempts[MAX_RESOLVE_ATTEMPTS];
static int g_nresolve_attempts;

static int resolve_attempted(void *cls, void *sel, int class_method)
{
    for (int i = 0; i < g_nresolve_attempts; i++)
        if (g_resolve_attempts[i].cls == cls &&
            g_resolve_attempts[i].sel == sel &&
            g_resolve_attempts[i].class_method == class_method)
            return 1;
    return 0;
}

static void mark_resolve_attempted(void *cls, void *sel, int class_method)
{
    if (g_nresolve_attempts >= MAX_RESOLVE_ATTEMPTS)
        return;
    struct resolve_attempt *attempt =
        &g_resolve_attempts[g_nresolve_attempts++];
    attempt->cls = cls;
    attempt->sel = sel;
    attempt->class_method = class_method;
}

static void *resolve_method(void *cls, void *sel, int class_method)
{
    if (resolve_attempted(cls, sel, class_method))
        return NULL;
    mark_resolve_attempted(cls, sel, class_method);
    const char *resolver_name =
        class_method ? "resolveClassMethod:" : "resolveInstanceMethod:";
    void *resolver = lookup_class_method((struct objc_class_min *)cls,
                                         resolver_name);
    if (!resolver)
        return NULL;
    int (*resolve_fn)(void *, void *, void *) = resolver;
    if (!resolve_fn(cls, sel_registerName(resolver_name), sel))
        return NULL;
    return class_method
               ? lookup_class_method((struct objc_class_min *)cls,
                                     (const char *)sel)
               : lookup_instance_method((struct objc_class_min *)cls,
                                        (const char *)sel);
}

static struct class_entry *find_class_entry(void *ptr)
{
    for (int i = 0; i < g_nclasses; i++)
        if (g_classes[i].cls == ptr)
            return &g_classes[i];
    return NULL;
}

void *objc_lookup_super_imp(void *super_ptr, void *sel)
{
    struct objc_super_min {
        void *receiver;
        void *super_class;
    };
    struct objc_super_min *sup = super_ptr;
    if (!sup || !sel)
    {
        fprintf(stderr, "objc: invalid objc_super or selector\n");
        _exit(1);
    }
    /* [super message] to a nil receiver returns zero without a lookup. */
    if (!sup->receiver)
        return NULL;
    /* msgSendSuper2 passes the class that defined the method; lookup starts
     * at its superclass. */
    struct objc_class_min *cls = (struct objc_class_min *)sup->super_class;
    if (cls)
        cls = (struct objc_class_min *)cls->superclass;
    void *imp = lookup_instance_method(cls, (const char *)sel);
    if (getenv("IOSIM_OBJC_DEBUG"))
        fprintf(stderr, "objc: super receiver=%p class=%p sel=%s -> %p\n",
                sup->receiver, sup->super_class, (const char *)sel, imp);
    if (!imp)
    {
        fprintf(stderr, "objc: super lookup failed for selector %s\n",
                (const char *)sel);
        _exit(1);
    }
    return imp;
}

void *iosim_objc_alloc(void *cls)
{
    return objc_alloc(cls);
}

/* Constant CFStrings carry a marker in their flags word instead of a real
 * class pointer. Route their messages and class checks to NSString. */
static void *constant_string_class(void *obj)
{
    if (!obj)
        return NULL;
    uint32_t flags = 0;
    memcpy(&flags, (const char *)obj + 8, sizeof(flags));
    if (flags != 0x7c8 && flags != 0x7d0)
        return NULL;
    return objc_getClass("NSString");
}

void *iosim_objc_class_of(void *obj)
{
    void *cls = (obj && *(void **)obj) ? *(void **)obj : NULL;
    if (cls && !find_class_entry(cls))
    {
        void *stringClass = constant_string_class(obj);
        if (stringClass)
            return stringClass;
    }
    return cls;
}

void *iosim_objc_superclass(void *cls)
{
    return cls ? ((struct objc_class_min *)cls)->superclass : NULL;
}

int iosim_objc_is_kind_of(void *obj, void *cls)
{
    if (!obj || !cls)
        return 0;
    struct objc_class_min *c =
        (struct objc_class_min *)iosim_objc_class_of(obj);
    for (int depth = 0; c && depth < 64; depth++)
    {
        if (c == cls)
            return 1;
        c = (struct objc_class_min *)c->superclass;
    }
    return 0;
}

static void set_property(void *self, void *value, long offset)
{
    if (self && offset >= (long)sizeof(void *))
        *(void **)((char *)self + offset) = value;
}

void *iosim_objc_normalize_class(void *ptr)
{
    if (!ptr)
        return NULL;
    struct class_entry *entry = find_class_entry(ptr);
    if (entry)
        return entry->cls;
    for (int i = 0; i < g_nclasses; i++)
    {
        struct objc_class_min *cls = g_classes[i].cls;
        if (class_isa(cls) == ptr)
            return cls;
    }
    return iosim_objc_class_of(ptr);
}

void objc_setProperty_nonatomic(void *self, void *sel, void *value, long offset)
{
    (void)sel;
    set_property(self, value, offset);
}

void objc_setProperty_nonatomic_copy(void *self, void *sel, void *value,
                                     long offset)
{
    (void)sel;
    set_property(self, value, offset);
}

void objc_setProperty_atomic(void *self, void *sel, void *value, long offset)
{
    (void)sel;
    set_property(self, value, offset);
}

void objc_setProperty_atomic_copy(void *self, void *sel, void *value,
                                  long offset)
{
    (void)sel;
    set_property(self, value, offset);
}

int iosim_objc_responds(void *obj, void *sel)
{
    if (!obj || !sel)
        return 0;
    const char *name = (const char *)sel;
    struct class_entry *ce = find_class_entry(obj);
    if (ce)
        return lookup_class_method(ce->cls, name) != NULL ||
               resolve_method((void *)ce->cls, sel, 1) != NULL;
    struct objc_class_min *cls =
        (struct objc_class_min *)iosim_objc_class_of(obj);
    return lookup_instance_method(cls, name) != NULL ||
           resolve_method((void *)cls, sel, 0) != NULL;
}

static void *lookup_imp_internal(void *obj, void *sel)
{
    if (!obj || !sel)
        return NULL;
    const char *name = (const char *)sel;
    struct class_entry *ce = find_class_entry(obj);
    void *imp = NULL;
    struct objc_class_min *cls = NULL;
    if (ce)
        imp = lookup_class_method(ce->cls, name);
    else
    {
        cls = (struct objc_class_min *)(*(void **)obj);
        imp = lookup_instance_method(cls, name);
    }
    if (!imp && !ce)
    {
        void *stringClass = constant_string_class(obj);
        if (stringClass)
            imp = lookup_instance_method(
                (struct objc_class_min *)stringClass, name);
    }
    if (!imp)
        imp = resolve_method(ce ? (void *)ce->cls : (void *)cls, sel,
                             ce ? 1 : 0);
    return imp;
}

void *objc_lookup_imp(void *obj, void *sel)
{
    if (!sel)
    {
        fprintf(stderr, "objc: nil selector\n");
        _exit(1);
    }
    /* Objective-C messaging nil is a no-op returning zero. The trampolines
     * treat a null IMP as that case and return without calling anything. */
    if (!obj)
        return NULL;
    const char *name = (const char *)sel;
    void *imp = lookup_imp_internal(obj, sel);
    if (!imp)
    {
        struct class_entry *ce = find_class_entry(obj);
        struct objc_class_min *cls =
            ce ? NULL : (struct objc_class_min *)(*(void **)obj);
        struct class_ro_min *ro = ce ? class_ro(ce->cls) : class_ro(cls);
        fprintf(stderr,
                "objc: no IMP for '%s' on %p (class %p %s, %s receiver)\n",
                name, obj, ce ? (void *)ce->cls : (void *)cls,
                ro ? ro_name(ro) : "?", ce ? "class" : "instance");
        _exit(1);
    }
    if (getenv("IOSIM_OBJC_DEBUG"))
        fprintf(stderr, "objc: msgSend obj=%p sel=%s -> %p\n", obj, name, imp);
    return imp;
}

/* Lookup used by the objc_msgSend trampoline: on a miss it runs the two
 * forwarding stages this runtime implements and reports the receiver the
 * method must be invoked with, because -forwardingTargetForSelector: can
 * replace it. A null IMP with the original receiver means "return zero", as
 * for nil. */
#define OBJC_FORWARDED_IMP ((void *)(uintptr_t)-1)

/* Frame offsets of the argument registers saved by the objc_msgSend
 * trampoline. frame points at the pushed r9 slot; the return address sits
 * at 0xB0 and the caller's stack arguments start at 0xB8. */
#define OBJC_FRAME_GP5 0x00
#define OBJC_FRAME_GP4 0x08
#define OBJC_FRAME_GP3 0x10
#define OBJC_FRAME_GP2 0x18
#define OBJC_FRAME_SSE0 0x30
#define OBJC_FRAME_STACK 0xB8

static const char *frame_skip_qualifiers(const char *p)
{
    while (*p && strchr("rnNoORVAg", *p))
        p++;
    return p;
}

/* Build an NSInvocation from the saved argument frame and deliver it to
 * -forwardInvocation:. The guest's own -methodSignatureForSelector: decides
 * whether the selector is forwardable; a nil signature means no. Struct and
 * array arguments are not captured, and the caller then falls back to
 * -doesNotRecognizeSelector:. */
static int forward_invocation(void *obj, void *sel, void *frame,
                              void *result_out)
{
    void *sig_sel = sel_registerName("methodSignatureForSelector:");
    void *sig_imp = lookup_imp_internal(obj, sig_sel);
    if (!sig_imp)
        return 0;
    void *sig = ((void *(*)(void *, void *, void *))sig_imp)(obj, sig_sel,
                                                             sel);
    if (!sig)
        return 0;

    void *inv_class = objc_getClass("NSInvocation");
    if (!inv_class)
        return 0;
    void *make_sel = sel_registerName("invocationWithMethodSignature:");
    void *make_imp = lookup_class_method(
        (struct objc_class_min *)inv_class,
        "invocationWithMethodSignature:");
    if (!make_imp)
        return 0;
    void *inv = ((void *(*)(void *, void *, void *))make_imp)(
        inv_class, make_sel, sig);
    if (!inv)
        return 0;

    void *set_target_sel = sel_registerName("setTarget:");
    void *set_target_imp = lookup_imp_internal(inv, set_target_sel);
    if (set_target_imp)
        ((void (*)(void *, void *, void *))set_target_imp)(inv,
                                                           set_target_sel,
                                                           obj);
    void *set_selector_sel = sel_registerName("setSelector:");
    void *set_selector_imp = lookup_imp_internal(inv, set_selector_sel);
    if (set_selector_imp)
        ((void (*)(void *, void *, void *))set_selector_imp)(inv,
                                                             set_selector_sel,
                                                             sel);

    unsigned long nargs = 0;
    {
        void *count_sel = sel_registerName("numberOfArguments");
        void *count_imp = lookup_imp_internal(sig, count_sel);
        if (count_imp)
            nargs = ((unsigned long (*)(void *, void *))count_imp)(sig,
                                                                   count_sel);
    }
    const char *gp_slots[4] = {
        (const char *)frame + OBJC_FRAME_GP2,
        (const char *)frame + OBJC_FRAME_GP3,
        (const char *)frame + OBJC_FRAME_GP4,
        (const char *)frame + OBJC_FRAME_GP5,
    };
    unsigned long gp_used = 0, sse_used = 0, stack_used = 0;
    for (unsigned long i = 2; i < nargs; i++)
    {
        const char *type = NULL;
        {
            void *type_sel = sel_registerName("getArgumentTypeAtIndex:");
            void *type_imp = lookup_imp_internal(sig, type_sel);
            if (type_imp)
                type = ((const char *(*)(void *, void *, unsigned long))
                            type_imp)(sig, type_sel, i);
        }
        if (!type)
            return 0;
        const char *tp = frame_skip_qualifiers(type);
        if (*tp == '{' || *tp == '[' || *tp == '(')
            return 0;
        const void *src;
        if (*tp == 'f' || *tp == 'd')
        {
            if (sse_used < 8)
            {
                src = (const char *)frame + OBJC_FRAME_SSE0 + 16 * sse_used;
                sse_used++;
            }
            else
            {
                src = (const char *)frame + OBJC_FRAME_STACK + 8 * stack_used;
                stack_used++;
            }
        }
        else
        {
            if (gp_used < 4)
            {
                src = gp_slots[gp_used];
                gp_used++;
            }
            else
            {
                src = (const char *)frame + OBJC_FRAME_STACK + 8 * stack_used;
                stack_used++;
            }
        }
        unsigned char value[8];
        memcpy(value, src, sizeof(value));
        void *arg_sel = sel_registerName("setArgument:atIndex:");
        void *arg_imp = lookup_imp_internal(inv, arg_sel);
        if (!arg_imp)
            return 0;
        ((void (*)(void *, void *, void *, unsigned long))arg_imp)(
            inv, arg_sel, value, i);
    }

    void *forward_sel = sel_registerName("forwardInvocation:");
    void *forward_imp = lookup_imp_internal(obj, forward_sel);
    if (!forward_imp)
        return 0;
    memset(result_out, 0, 32);
    ((void (*)(void *, void *, void *))forward_imp)(obj, forward_sel, inv);

    const char *return_type = NULL;
    {
        void *rt_sel = sel_registerName("methodReturnType");
        void *rt_imp = lookup_imp_internal(sig, rt_sel);
        if (rt_imp)
            return_type = ((const char *(*)(void *, void *))rt_imp)(
                sig, rt_sel);
    }
    const char *rp = return_type ? frame_skip_qualifiers(return_type) : NULL;
    void *ret_sel = sel_registerName("getReturnValue:");
    void *ret_imp = lookup_imp_internal(inv, ret_sel);
    if (ret_imp)
    {
        if (rp && (*rp == 'f' || *rp == 'd'))
            ((void (*)(void *, void *, void *))ret_imp)(
                inv, ret_sel, (char *)result_out + 8);
        else
            ((void (*)(void *, void *, void *))ret_imp)(
                inv, ret_sel, result_out);
    }
    return 1;
}

void *objc_msgSend_lookup(void *obj, void *sel, void **receiver_out,
                          void *frame, void *result_out)
{
    if (receiver_out)
        *receiver_out = obj;
    if (!sel)
    {
        fprintf(stderr, "objc: nil selector\n");
        _exit(1);
    }
    if (!obj)
        return NULL;
    void *imp = lookup_imp_internal(obj, sel);
    if (imp)
        return imp;

    /* Stage 1: an object may hand the message to another receiver. Chains
     * are followed a few hops, exactly like resending the message. Class
     * receivers do not take this path. */
    struct class_entry *ce = find_class_entry(obj);
    if (!ce)
    {
        struct objc_class_min *cls =
            (struct objc_class_min *)(*(void **)obj);
        for (int depth = 0; depth < 4; depth++)
        {
            void *forward = lookup_instance_method(
                cls, "forwardingTargetForSelector:");
            if (!forward)
                break;
            void *forward_sel =
                sel_registerName("forwardingTargetForSelector:");
            void *target = ((void *(*)(void *, void *, void *))forward)(
                obj, forward_sel, sel);
            if (!target || target == obj)
                break;
            obj = target;
            if (receiver_out)
                *receiver_out = obj;
            imp = lookup_imp_internal(obj, sel);
            if (imp)
                return imp;
            ce = find_class_entry(obj);
            if (ce)
                break;
            cls = (struct objc_class_min *)(*(void **)obj);
        }
    }

    /* Stage 3: -forwardInvocation: with an NSInvocation built from the
     * saved argument frame. The trampoline passes the frame and a result
     * buffer and treats the sentinel IMP as "the invocation returned". */
    if (!ce && frame && result_out)
    {
        if (forward_invocation(obj, sel, frame, result_out))
            return OBJC_FORWARDED_IMP;
    }

    /* Stage 2: -doesNotRecognizeSelector:. NSObject answers it by
     * terminating with the real runtime's message; a custom override may
     * return, in which case the send yields zero like a nil receiver. */
    void *dnr = NULL;
    if (ce)
    {
        dnr = lookup_class_method(ce->cls, "doesNotRecognizeSelector:");
        if (!dnr)
            dnr = lookup_instance_method(ce->cls,
                                         "doesNotRecognizeSelector:");
    }
    else
    {
        struct objc_class_min *cls =
            (struct objc_class_min *)(*(void **)obj);
        dnr = lookup_instance_method(cls, "doesNotRecognizeSelector:");
        if (!dnr)
            dnr = lookup_class_method(cls, "doesNotRecognizeSelector:");
    }
    if (dnr)
    {
        ((void (*)(void *, void *, void *))dnr)(
            obj, sel_registerName("doesNotRecognizeSelector:"), sel);
        return NULL;
    }
    {
        struct class_ro_min *ro =
            ce ? class_ro(ce->cls)
               : class_ro((struct objc_class_min *)(*(void **)obj));
        fprintf(stderr,
                "objc: no IMP for '%s' on %p (class %p %s, %s receiver)\n",
                (const char *)sel, obj,
                ce ? (void *)ce->cls : (void *)*(void **)obj,
                ro ? ro_name(ro) : "?", ce ? "class" : "instance");
        _exit(1);
    }
}

/* Called by clang's fast-enumeration codegen when the mutations pointer of a
 * collection changes mid-loop. None of the Foundation-lite collections hand out
 * a live mutations counter, so this is a no-op that keeps the loop running. */
void objc_enumerationMutation(void *obj)
{
    (void)obj;
}

void *objc_alloc_init(void *class_ptr)
{
    struct objc_class_min *cls = class_ptr;
    struct class_ro_min *ro = class_ro(cls);
    if (!ro)
        return NULL;

    size_t size = class_instance_size(cls);
    if (size < 16)
        size = 16;
    void *obj = calloc(1, size);
    if (!obj)
        return NULL;
    *(void **)obj = cls;

    static char init_sel[] = "init";
    void *imp = lookup_instance_method(cls, init_sel);
    if (getenv("IOSIM_OBJC_DEBUG"))
        fprintf(stderr, "objc: alloc_init cls=%p size=%zu obj=%p init=%p\n",
                class_ptr, size, obj, imp);
    if (imp)
    {
        void *(*init_fn)(void *, void *) = imp;
        obj = init_fn(obj, init_sel);
    }
    if (getenv("IOSIM_OBJC_DEBUG"))
        fprintf(stderr, "objc: after init obj=%p isa=%p\n", obj, *(void **)obj);
    return obj;
}

void *objc_alloc(void *class_ptr)
{
    struct objc_class_min *cls = class_ptr;
    size_t size = class_instance_size(cls);
    if (size < 16)
        size = 16;
    void *obj = calloc(1, size);
    if (obj)
        *(void **)obj = cls;
    if (getenv("IOSIM_OBJC_DEBUG"))
        fprintf(stderr, "objc: alloc class=%p (%s) size=%zu obj=%p\n",
                class_ptr, ro_name(class_ro(cls)), size, obj);
    return obj;
}

void *objc_autorelease(void *obj)
{
    return obj;
}

void *objc_autoreleasePoolPush(void)
{
    static uintptr_t token;
    return &token;
}

void objc_autoreleasePoolPop(void *pool)
{
    (void)pool;
}

void *objc_retain(void *obj) { return obj; }
void objc_release(void *obj) { (void)obj; }

/* ARC entry points. Objects are never freed by this runtime and retain and
 * release are no-ops, so the ownership-family calls preserve identity. The
 * weak family stores and loads the pointer in place; a slot is cleared only
 * when it is assigned nil, because there is no deallocation to observe. */
extern void *_Block_copy(void *block);

void *objc_retainAutoreleasedReturnValue(void *obj) { return obj; }
void *objc_autoreleaseReturnValue(void *obj) { return obj; }
void *objc_claimAutoreleasedReturnValue(void *obj) { return obj; }
void *objc_unsafeClaimAutoreleasedReturnValue(void *obj) { return obj; }
void *objc_retainAutorelease(void *obj) { return obj; }
void *objc_retainAutoreleaseReturnValue(void *obj) { return obj; }
void *objc_retainBlock(void *block)
{
    return block ? _Block_copy(block) : NULL;
}

void objc_storeStrong(void **location, void *obj)
{
    if (location)
        *location = obj;
}

void *objc_storeWeak(void **location, void *obj)
{
    if (location)
        *location = obj;
    return obj;
}

void *objc_loadWeak(void **location)
{
    return location ? *location : NULL;
}

void *objc_loadWeakRetained(void **location)
{
    return location ? *location : NULL;
}

void *objc_initWeak(void **location, void *obj)
{
    if (location)
        *location = obj;
    return location;
}

void objc_destroyWeak(void **location)
{
    if (location)
        *location = NULL;
}

void objc_moveWeak(void **dest, void **src)
{
    if (dest && src)
    {
        *dest = *src;
        *src = NULL;
    }
}

void objc_copyWeak(void **dest, void **src)
{
    if (dest && src)
        *dest = *src;
}

int objc_opt_isKindOfClass(void *obj, void *cls)
{
    return iosim_objc_is_kind_of(obj, cls);
}

int objc_opt_respondsToSelector(void *obj, void *sel)
{
    return iosim_objc_responds(obj, sel);
}

void *objc_opt_self(void *obj) { return obj; }

/* --------------------------------------------------- dynamic class creation */

static struct dynamic_class *find_dynamic_class(void *cls)
{
    for (int i = 0; i < g_ndynamic; i++)
        if (&g_dynamic[i]->cls == cls)
            return g_dynamic[i];
    return NULL;
}

void *objc_allocateClassPair(void *superclass, const char *name,
                             unsigned long extraBytes)
{
    (void)extraBytes;
    if (!superclass || !name || g_ndynamic >= MAX_DYNAMIC_CLASSES)
        return NULL;
    struct dynamic_class *dc = calloc(1, sizeof(*dc));
    if (!dc)
        return NULL;
    snprintf(dc->name, sizeof(dc->name), "%s", name);
    dc->ro.flags = 0;
    dc->ro.name = dc->name;
    dc->ro.baseMethods = &dc->methods;
    dc->meta_ro.flags = 1; /* RO_META */
    dc->meta_ro.name = dc->name;

    struct objc_class_min *meta = (struct objc_class_min *)superclass;
    dc->cls.isa = &dc->meta;
    dc->cls.superclass = superclass;
    dc->cls.bits = (uintptr_t)&dc->ro;
    dc->meta.isa = &dc->meta;
    dc->meta.superclass = meta->isa;
    dc->meta.bits = (uintptr_t)&dc->meta_ro;
    dc->methods.entsizeAndFlags = (uint32_t)sizeof(struct method_min);

    g_dynamic[g_ndynamic++] = dc;
    if (getenv("IOSIM_OBJC_DEBUG"))
        fprintf(stderr, "objc: allocated class %s super=%s at %p\n",
                dc->name, class_getName(superclass), (void *)&dc->cls);
    return &dc->cls;
}

void objc_registerClassPair(void *cls)
{
    struct dynamic_class *dc = find_dynamic_class(cls);
    if (!dc || dc->registered)
        return;
    dc->registered = 1;
    register_class((struct objc_class_min *)cls, dc->name);
}

int class_addMethod(void *cls, void *sel, void *imp, const char *types)
{
    struct dynamic_class *dc = find_dynamic_class(cls);
    if (!sel || !imp)
        return 0;
    const char *name = (const char *)sel;
    if (dc)
    {
        for (uint32_t i = 0; i < dc->methods.count; i++)
            if (dc->methods.methods[i].name &&
                strcmp((const char *)dc->methods.methods[i].name, name) == 0)
                return 0;
        if (dc->methods.count >= DYNAMIC_METHODS)
            return 0;
        char *types_copy = NULL;
        if (types)
        {
            size_t n = strlen(types) + 1;
            types_copy = malloc(n);
            if (types_copy)
                memcpy(types_copy, types, n);
        }
        struct method_min *m = &dc->methods.methods[dc->methods.count++];
        m->name = sel;
        m->types = types_copy;
        m->imp = imp;
        if (getenv("IOSIM_OBJC_DEBUG"))
            fprintf(stderr, "objc: class_addMethod %s %s imp=%p\n",
                    dc->name, name, imp);
        return 1;
    }
    /* A loaded class, or its metaclass for a class method. */
    int class_method = 0;
    struct class_entry *entry = find_class_entry(cls);
    if (!entry)
    {
        for (int i = 0; i < g_nclasses; i++)
            if (class_isa(g_classes[i].cls) == cls)
            {
                entry = &g_classes[i];
                class_method = 1;
                break;
            }
    }
    if (!entry)
        return 0;
    struct class_ro_min *target_ro =
        class_method ? metaclass_ro(entry->cls) : class_ro(entry->cls);
    if (lookup_in_methods(target_ro ? target_ro->baseMethods : NULL, name))
        return 0;
    if (lookup_category_method(ro_name(target_ro), name, class_method))
        return 0;
    if (find_injected_method(entry->cls, name, class_method))
        return 0;
    if (g_ninjected_methods >= MAX_INJECTED_METHODS)
        return 0;
    char *types_copy = NULL;
    if (types)
    {
        size_t n = strlen(types) + 1;
        types_copy = malloc(n);
        if (types_copy)
            memcpy(types_copy, types, n);
    }
    struct injected_method *injected = calloc(1, sizeof(*injected));
    if (!injected)
        return 0;
    injected->method.name = sel;
    injected->method.types = types_copy;
    injected->method.imp = imp;
    injected->cls = entry->cls;
    injected->class_method = class_method;
    injected->next = g_injected_methods;
    g_injected_methods = injected;
    g_ninjected_methods++;
    if (getenv("IOSIM_OBJC_DEBUG"))
        fprintf(stderr, "objc: class_addMethod %s %s imp=%p (injected)\n",
                entry->name, name, imp);
    return 1;
}

void *class_getClassMethod(void *cls, void *sel)
{
    if (!cls || !sel)
        return NULL;
    const char *name = (const char *)sel;
    for (int depth = 0; cls && depth < 64; depth++)
    {
        struct objc_class_min *c = cls;
        struct injected_method *injected =
            find_injected_method(cls, name, 1);
        if (injected)
            return &injected->method;
        struct class_ro_min *ro = metaclass_ro(c);
        const struct method_min *m =
            lookup_method_entry(ro ? ro->baseMethods : NULL, name);
        if (m)
            return (void *)m;
        const struct method_min *category =
            lookup_category_method_entry(ro_name(ro), name, 1);
        if (category)
            return (void *)category;
        cls = c->superclass;
    }
    return NULL;
}

void *class_replaceMethod(void *cls, void *sel, void *imp, const char *types)
{
    if (!cls || !sel || !imp)
        return NULL;
    const char *name = (const char *)sel;
    int class_method = 0;
    struct class_entry *entry = find_class_entry(cls);
    if (!entry)
    {
        for (int i = 0; i < g_nclasses; i++)
            if (class_isa(g_classes[i].cls) == cls)
            {
                entry = &g_classes[i];
                class_method = 1;
                break;
            }
    }
    if (!entry)
        return NULL;
    struct class_ro_min *target_ro =
        class_method ? metaclass_ro(entry->cls) : class_ro(entry->cls);
    struct injected_method *injected =
        find_injected_method(entry->cls, name, class_method);
    if (injected)
    {
        void *old = method_effective_imp(&injected->method);
        set_method_override(&injected->method, imp);
        return old;
    }
    const struct method_min *own = lookup_method_entry(
        target_ro ? target_ro->baseMethods : NULL, name);
    if (own)
    {
        void *old = method_effective_imp(own);
        set_method_override((void *)own, imp);
        return old;
    }
    const struct method_min *category =
        lookup_category_method_entry(ro_name(target_ro), name, class_method);
    if (category)
    {
        void *old = method_effective_imp(category);
        set_method_override((void *)category, imp);
        return old;
    }
    class_addMethod(cls, sel, imp, types);
    return NULL;
}

void method_exchangeImplementations(void *first, void *second)
{
    if (!first || !second)
        return;
    void *first_imp = method_effective_imp(first);
    void *second_imp = method_effective_imp(second);
    set_method_override(first, second_imp);
    set_method_override(second, first_imp);
}

int class_respondsToSelector(void *cls, void *sel)
{
    if (!cls || !sel)
        return 0;
    if (lookup_instance_method((struct objc_class_min *)cls,
                               (const char *)sel))
        return 1;
    return resolve_method(cls, sel, 0) != NULL;
}

static unsigned int method_list_count(const void *list_ptr)
{
    if (!list_ptr)
        return 0;
    const struct method_list_min *list = list_ptr;
    if (list->entsizeAndFlags & 0x80000000u)
        return 0;
    return list->count;
}

static unsigned int append_methods(const void *list_ptr, void **out,
                                   unsigned int index)
{
    if (!list_ptr)
        return index;
    const struct method_list_min *list = list_ptr;
    if (list->entsizeAndFlags & 0x80000000u)
        return index;
    uint32_t entsize = list->entsizeAndFlags & 0xFFFC;
    if (entsize < sizeof(struct method_min))
        entsize = sizeof(struct method_min);
    const uint8_t *base = (const uint8_t *)list + sizeof(*list);
    for (uint32_t i = 0; i < list->count; i++)
        out[index++] = (void *)(base + (size_t)i * entsize);
    return index;
}

void **class_copyMethodList(void *cls, unsigned int *out_count)
{
    if (out_count)
        *out_count = 0;
    struct class_entry *entry = find_class_entry(cls);
    if (!entry)
        return NULL;
    struct class_ro_min *ro = class_ro(entry->cls);
    const char *name = ro_name(ro);
    unsigned int total = method_list_count(ro ? ro->baseMethods : NULL);
    for (int i = 0; i < g_ncategories; i++)
        if (strcmp(g_categories[i].class_name, name) == 0)
            total += method_list_count(g_categories[i].instance_methods);
    for (struct injected_method *m = g_injected_methods; m; m = m->next)
        if (m->cls == entry->cls && !m->class_method)
            total++;
    if (total == 0)
        return NULL;
    void **out = malloc(total * sizeof(void *));
    if (!out)
        return NULL;
    unsigned int index = 0;
    index = append_methods(ro ? ro->baseMethods : NULL, out, index);
    for (int i = 0; i < g_ncategories; i++)
        if (strcmp(g_categories[i].class_name, name) == 0)
            index = append_methods(g_categories[i].instance_methods, out,
                                   index);
    for (struct injected_method *m = g_injected_methods; m; m = m->next)
        if (m->cls == entry->cls && !m->class_method)
            out[index++] = &m->method;
    if (out_count)
        *out_count = index;
    return out;
}

void *class_getInstanceMethod(void *cls, void *sel)
{
    if (!cls || !sel)
        return NULL;
    const char *name = (const char *)sel;
    for (int depth = 0; cls && depth < 64; depth++)
    {
        struct objc_class_min *c = cls;
        struct injected_method *injected =
            find_injected_method(cls, name, 0);
        if (injected)
            return &injected->method;
        struct class_ro_min *ro = class_ro(c);
        const struct method_min *m =
            lookup_method_entry(ro ? ro->baseMethods : NULL, name);
        if (m)
            return (void *)m;
        const struct method_min *category =
            lookup_category_method_entry(ro_name(ro), name, 0);
        if (category)
            return (void *)category;
        cls = c->superclass;
    }
    return NULL;
}

void *class_getMethodImplementation(void *cls, void *sel)
{
    return lookup_instance_method((struct objc_class_min *)cls,
                                  (const char *)sel);
}

const char *method_getTypeEncoding(void *method)
{
    return method ? ((const struct method_min *)method)->types : NULL;
}

void *method_getImplementation(void *method)
{
    return method ? method_effective_imp(method) : NULL;
}

void *method_setImplementation(void *method, void *imp)
{
    if (!method)
        return NULL;
    void *old = method_effective_imp(method);
    set_method_override(method, imp);
    return old;
}

void *class_getSuperclass(void *cls)
{
    return cls ? ((struct objc_class_min *)cls)->superclass : NULL;
}

unsigned long class_getInstanceSize(void *cls)
{
    return class_instance_size((struct objc_class_min *)cls);
}

void *object_getClass(void *obj)
{
    return iosim_objc_class_of(obj);
}

void *object_setClass(void *obj, void *cls)
{
    if (!obj)
        return NULL;
    void *old = *(void **)obj;
    *(void **)obj = cls;
    return old;
}

void *sel_getUid(const char *name)
{
    return sel_registerName(name);
}

void *objc_getClass(const char *name)
{
    for (int i = 0; i < g_nclasses; i++)
        if (strcmp(g_classes[i].name, name) == 0)
            return g_classes[i].cls;
    return NULL;
}

const char *class_getName(void *cls)
{
    struct class_entry *ce = find_class_entry(cls);
    if (ce)
        return ce->name;
    return ro_name(class_ro(cls));
}

const char *object_getClassName(void *obj)
{
    if (!obj)
        return "nil";
    struct class_entry *ce = find_class_entry(obj);
    if (ce)
        return ce->name;
    return class_getName(*(void **)obj);
}

#define MAX_SELECTORS 8192
static char *g_selectors[MAX_SELECTORS];
static int g_nselectors;

/* Selector names are interned in process memory. Apple's runtime hashes them;
 * the string itself is the selector here, so callers may pass stack buffers
 * and still get a stable selector back. */
void *sel_registerName(const char *name)
{
    if (!name)
        return NULL;
    for (int i = 0; i < g_nselectors; i++)
        if (strcmp(g_selectors[i], name) == 0)
            return g_selectors[i];
    size_t n = strlen(name) + 1;
    char *copy = malloc(n);
    if (!copy)
        return NULL;
    memcpy(copy, name, n);
    if (g_nselectors < MAX_SELECTORS)
        g_selectors[g_nselectors++] = copy;
    return copy;
}

const char *sel_getName(void *sel)
{
    return (const char *)sel;
}

void iosim_objc_dump(void)
{
    for (int i = 0; i < g_nclasses; i++)
        fprintf(stderr, "objc: class %s at %p\n",
                g_classes[i].name, (void *)g_classes[i].cls);
}

/* ------------------------------------------------------- associated objects
 *
 * Keys are the addresses callers pass; values are stored for the life of the
 * process (objects are never freed by this runtime). Copy policies send
 * -copy so a mutable value cannot change behind the association, while
 * assign and retain keep the pointer they were given. */
struct objc_association {
    void *object;
    const void *key;
    void *value;
    unsigned long policy;
    struct objc_association *next;
};
static struct objc_association *g_associations;

void objc_setAssociatedObject(void *object, const void *key, void *value,
                              unsigned long policy)
{
    if (!object || !key)
        return;
    struct objc_association **link = &g_associations;
    while (*link)
    {
        struct objc_association *entry = *link;
        if (entry->object == object && entry->key == key)
        {
            if (!value)
            {
                *link = entry->next;
                free(entry);
                return;
            }
            entry->value = value;
            entry->policy = policy;
            return;
        }
        link = &entry->next;
    }
    if (!value)
        return;
    if (policy == 2 || policy == 4)
    {
        void *sel = sel_registerName("copy");
        void *(*copy_imp)(void *, void *) = objc_lookup_imp(value, sel);
        if (copy_imp)
            value = copy_imp(value, sel);
    }
    struct objc_association *entry = calloc(1, sizeof(*entry));
    if (!entry)
        return;
    entry->object = object;
    entry->key = key;
    entry->value = value;
    entry->policy = policy;
    entry->next = g_associations;
    g_associations = entry;
}

void *objc_getAssociatedObject(void *object, const void *key)
{
    for (struct objc_association *entry = g_associations; entry;
         entry = entry->next)
        if (entry->object == object && entry->key == key)
            return entry->value;
    return NULL;
}

void objc_removeAssociatedObjects(void *object)
{
    struct objc_association **link = &g_associations;
    while (*link)
    {
        struct objc_association *entry = *link;
        if (entry->object == object)
        {
            *link = entry->next;
            free(entry);
        }
        else
            link = &entry->next;
    }
}
