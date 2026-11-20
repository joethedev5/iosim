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

static void *lookup_in_methods(const void *list_ptr, const char *sel)
{
    const struct method_min *m = lookup_method_entry(list_ptr, sel);
    return m ? m->imp : NULL;
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

static void *lookup_instance_method(struct objc_class_min *cls, const char *sel)
{
    for (int depth = 0; cls && depth < 64; depth++)
    {
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
    struct class_entry *ce = find_class_entry(obj);
    if (ce)
        return lookup_class_method(ce->cls, (const char *)sel) != NULL;
    return lookup_instance_method(
               (struct objc_class_min *)iosim_objc_class_of(obj),
               (const char *)sel) != NULL;
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
    {
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
    if (!dc || !sel || !imp)
        return 0;
    const char *name = (const char *)sel;
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

void *class_getInstanceMethod(void *cls, void *sel)
{
    if (!cls || !sel)
        return NULL;
    const char *name = (const char *)sel;
    for (int depth = 0; cls && depth < 64; depth++)
    {
        struct objc_class_min *c = cls;
        struct class_ro_min *ro = class_ro(c);
        const struct method_min *m =
            lookup_method_entry(ro ? ro->baseMethods : NULL, name);
        if (m)
            return (void *)m;
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
    return method ? ((const struct method_min *)method)->imp : NULL;
}

void *method_setImplementation(void *method, void *imp)
{
    if (!method)
        return NULL;
    struct method_min *m = method;
    void *old = m->imp;
    m->imp = imp;
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
