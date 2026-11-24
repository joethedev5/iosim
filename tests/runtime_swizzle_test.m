/* Runtime swizzling: exchange and replace implementations of methods whose
 * lists live in read-only sections, set one directly, override an inherited
 * method on a subclass, enumerate method lists and exchange class methods. */
#include "foundation_lite.h"

extern int printf(const char *fmt, ...);
extern int fflush(void *stream);
extern void *class_getInstanceMethod(void *cls, void *sel);
extern void *class_getClassMethod(void *cls, void *sel);
extern void *class_replaceMethod(void *cls, void *sel, void *imp,
                                 const char *types);
extern void method_exchangeImplementations(void *first, void *second);
extern int class_respondsToSelector(void *cls, void *sel);
extern void **class_copyMethodList(void *cls, unsigned int *out_count);
extern void *method_getImplementation(void *method);
extern void *method_setImplementation(void *method, void *imp);
extern void free(void *ptr);
extern void *sel_registerName(const char *name);

static int imp_nine(id self, SEL _cmd) { (void)self; (void)_cmd; return 9; }
static int imp_eleven(id self, SEL _cmd) { (void)self; (void)_cmd; return 11; }
static int imp_twelve(id self, SEL _cmd) { (void)self; (void)_cmd; return 12; }

@interface SwizzleTarget : NSObject
- (int)value;
- (int)other;
+ (int)classValue;
+ (int)classOther;
@end

@implementation SwizzleTarget
- (int)value { return 1; }
- (int)other { return 2; }
+ (int)classValue { return 5; }
+ (int)classOther { return 6; }
@end

@interface SwizzleSub : SwizzleTarget
@end

@implementation SwizzleSub
@end

int main(void)
{
    SwizzleTarget *target = [[SwizzleTarget alloc] init];
    SwizzleTarget *sub = [[SwizzleSub alloc] init];

    printf("[sw] before %d %d\n", [target value], [target other]);

    method_exchangeImplementations(
        class_getInstanceMethod([SwizzleTarget class], @selector(value)),
        class_getInstanceMethod([SwizzleTarget class], @selector(other)));
    printf("[sw] exchanged %d %d\n", [target value], [target other]);

    void *old = class_replaceMethod([SwizzleTarget class], @selector(value),
                                    (void *)imp_nine, "i@:");
    printf("[sw] replace %d %d\n", old != 0, [target value]);

    void *previous = method_setImplementation(
        class_getInstanceMethod([SwizzleTarget class], @selector(other)),
        (void *)imp_eleven);
    printf("[sw] set %d %d\n", previous != 0, [target other]);

    class_replaceMethod([SwizzleSub class], @selector(other),
                        (void *)imp_twelve, "i@:");
    printf("[sw] override sub %d super %d\n", [sub other], [target other]);

    unsigned int target_count = 0;
    void **target_methods =
        class_copyMethodList([SwizzleTarget class], &target_count);
    int found_eleven = 0;
    for (unsigned int i = 0; i < target_count; i++)
        if (method_getImplementation(target_methods[i]) == (void *)imp_eleven)
            found_eleven = 1;
    printf("[sw] target list %u %d\n", target_count, found_eleven);
    free(target_methods);

    unsigned int sub_count = 0;
    void **sub_methods = class_copyMethodList([SwizzleSub class], &sub_count);
    int found_twelve = 0;
    for (unsigned int i = 0; i < sub_count; i++)
        if (method_getImplementation(sub_methods[i]) == (void *)imp_twelve)
            found_twelve = 1;
    printf("[sw] sub list %u %d\n", sub_count, found_twelve);
    free(sub_methods);

    method_exchangeImplementations(
        class_getClassMethod([SwizzleTarget class], @selector(classValue)),
        class_getClassMethod([SwizzleTarget class], @selector(classOther)));
    printf("[sw] class exchanged %d %d\n", [SwizzleTarget classValue],
           [SwizzleTarget classOther]);

    printf("[sw] responds %d %d %d\n",
           class_respondsToSelector([SwizzleTarget class], @selector(value)),
           [SwizzleTarget instancesRespondToSelector:@selector(other)],
           [SwizzleTarget instancesRespondToSelector:
                                (SEL)sel_registerName("missing")]);

    printf("[sw] done\n");
    fflush(0);
    return 0;
}
