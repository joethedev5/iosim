/* Dynamic method resolution and forwarding targets: +resolveInstanceMethod:
 * installs a missing instance method once, +resolveClassMethod: installs a
 * class method, -forwardingTargetForSelector: redirects a send (including a
 * chain), and an unresolved selector reaches -doesNotRecognizeSelector:. */
#include "foundation_lite.h"

extern int printf(const char *fmt, ...);
extern int fflush(void *stream);
extern int strcmp(const char *a, const char *b);
extern void *object_getClass(void *obj);
extern int class_addMethod(void *cls, void *sel, void *imp, const char *types);

static int g_resolve_calls;

static int magic_value_imp(id self, SEL _cmd)
{
    (void)self;
    (void)_cmd;
    return 42;
}

@interface ResolveHost : NSObject
@end

@interface ResolveHost (Dynamic)
- (int)magicValue;
@end

@implementation ResolveHost
+ (BOOL)resolveInstanceMethod:(SEL)sel
{
    if (strcmp((const char *)sel, "magicValue") == 0)
    {
        g_resolve_calls++;
        class_addMethod(self, sel, (void *)magic_value_imp, "i@:");
        return YES;
    }
    return NO;
}
@end

static int class_magic_imp(id self, SEL _cmd)
{
    (void)self;
    (void)_cmd;
    return 77;
}

@interface ClassResolve : NSObject
@end

@interface ClassResolve (Dynamic)
+ (int)classMagic;
@end

@implementation ClassResolve
+ (BOOL)resolveClassMethod:(SEL)sel
{
    if (strcmp((const char *)sel, "classMagic") == 0)
    {
        class_addMethod(object_getClass(self), sel, (void *)class_magic_imp,
                        "i@:");
        return YES;
    }
    return NO;
}
@end

@interface Backend : NSObject
- (int)compute;
- (id)greet;
@end

@implementation Backend
- (int)compute { return 123; }
- (id)greet { return [NSString stringWithUTF8String:"backend"]; }
@end

@interface Forwarder : NSObject {
@public
    Backend *backend;
}
@end

@interface Forwarder (Forwarded)
- (int)compute;
- (id)greet;
@end

@implementation Forwarder
- (id)forwardingTargetForSelector:(SEL)sel
{
    if (strcmp((const char *)sel, "compute") == 0 ||
        strcmp((const char *)sel, "greet") == 0)
        return backend;
    return nil;
}
@end

@interface ChainTwo : NSObject {
@public
    Backend *backend;
}
@end

@implementation ChainTwo
- (id)forwardingTargetForSelector:(SEL)sel
{
    (void)sel;
    return backend;
}
@end

@interface ChainOne : NSObject {
@public
    ChainTwo *next;
}
@end

@interface ChainOne (Forwarded)
- (int)compute;
@end

@implementation ChainOne
- (id)forwardingTargetForSelector:(SEL)sel
{
    (void)sel;
    return next;
}
@end

@interface StrictHost : NSObject
@end

@interface StrictHost (Unknown)
- (void)bogus;
@end

@implementation StrictHost
- (void)doesNotRecognizeSelector:(SEL)sel
{
    printf("[fwd] dnr %s\n", (const char *)sel);
    fflush(0);
}
@end

int main(void)
{
    ResolveHost *host = [[ResolveHost alloc] init];
    int first = [host magicValue];
    int second = [host magicValue];
    printf("[fwd] resolve %d %d calls %d\n", first, second, g_resolve_calls);

    int direct = [ClassResolve classMagic];
    int again = [ClassResolve classMagic];
    printf("[fwd] class resolve %d %d\n", direct, again);

    Backend *backend = [[Backend alloc] init];
    Forwarder *forwarder = [[Forwarder alloc] init];
    forwarder->backend = backend;
    int sum = [forwarder compute];
    NSString *word = [forwarder greet];
    printf("[fwd] target %d %s\n", sum, [word UTF8String]);

    ChainTwo *two = [[ChainTwo alloc] init];
    two->backend = backend;
    ChainOne *one = [[ChainOne alloc] init];
    one->next = two;
    printf("[fwd] chain %d\n", [one compute]);

    printf("[fwd] responds %d\n",
           [host respondsToSelector:@selector(magicValue)]);

    StrictHost *strict = [[StrictHost alloc] init];
    [strict bogus];

    printf("[fwd] done\n");
    fflush(0);
    return 0;
}
