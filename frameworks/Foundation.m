/* Foundation-lite: NSObject and NSLog for the iosim Objective-C runtime.
 * Built as an x86_64 Mach-O dylib with the canonical install name. */

#include "foundation_lite.h"

extern void *iosim_objc_alloc(void *cls);
extern void *iosim_objc_class_of(void *obj);
extern void *iosim_objc_superclass(void *cls);
extern int   iosim_objc_is_kind_of(void *obj, void *cls);
extern int   iosim_objc_responds(void *obj, void *sel);
extern void  iosim_nslog(const char *message);

@implementation NSObject

+ (id)alloc
{
    return iosim_objc_alloc(self);
}

+ (id)new
{
    return [[self alloc] init];
}

+ (Class)class
{
    return self;
}

- (id)init
{
    return self;
}

- (void)dealloc
{
}

- (id)retain
{
    return self;
}

- (void)release
{
}

- (id)autorelease
{
    return self;
}

- (unsigned long)retainCount
{
    return 1;
}

- (Class)class
{
    return iosim_objc_class_of(self);
}

- (Class)superclass
{
    return iosim_objc_superclass(iosim_objc_class_of(self));
}

- (BOOL)isKindOfClass:(Class)cls
{
    return (BOOL)iosim_objc_is_kind_of(self, cls);
}

- (BOOL)isMemberOfClass:(Class)cls
{
    return iosim_objc_class_of(self) == cls;
}

- (BOOL)respondsToSelector:(SEL)sel
{
    return (BOOL)iosim_objc_responds(self, sel);
}

@end

struct cf_constant_string {
    void *isa;
    unsigned int flags;
    unsigned int pad;
    const char *cstr;
    unsigned long length;
};

void NSLog(void *format, ...)
{
    const char *text = 0;
    if (format)
    {
        struct cf_constant_string *cs = format;
        if (cs->flags == 0x7c8 && cs->cstr)
            text = cs->cstr;
    }
    iosim_nslog(text ? text : "(NSLog format object)");
}
