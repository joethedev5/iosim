#define _GNU_SOURCE
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

void iosim_objc_register_image(struct iosim_image *img)
{
    g_registered_images++;
    for (int s = 0; s < img->nsects; s++)
    {
        struct iosim_section *sec = &img->sects[s];
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
            if (iv->offset)
                *iv->offset = base;
            base += iv->size;
        }
    }

    uint32_t size = align_up(base, 16);
    if (entry)
        entry->instance_size = size;
    return size;
}

static void *lookup_in_methods(const void *list_ptr, const char *sel)
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
            return m->imp;
    }
    return NULL;
}

static struct class_ro_min *metaclass_ro(struct objc_class_min *cls)
{
    struct objc_class_min *meta = class_isa(cls);
    if (!meta || meta == cls)
        return class_ro(cls);
    return class_ro(meta);
}

static void *lookup_instance_method(struct objc_class_min *cls, const char *sel)
{
    for (int depth = 0; cls && depth < 64; depth++)
    {
        struct class_ro_min *ro = class_ro(cls);
        void *imp = lookup_in_methods(ro ? ro->baseMethods : NULL, sel);
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

void *objc_lookup_imp(void *obj, void *sel)
{
    if (!obj || !sel)
    {
        fprintf(stderr, "objc: nil receiver or selector\n");
        _exit(1);
    }
    const char *name = (const char *)sel;

    struct class_entry *ce = find_class_entry(obj);
    if (ce)
        return lookup_class_method(ce->cls, name);

    if (getenv("IOSIM_OBJC_DEBUG"))
        fprintf(stderr, "objc: msgSend obj=%p isa=%p sel=%s\n",
                obj, *(void **)obj, name);
    struct objc_class_min *cls = (struct objc_class_min *)(*(void **)obj);
    return lookup_instance_method(cls, name);
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

void *sel_registerName(const char *name)
{
    return (void *)name;
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
