/* NSMethodSignature and NSInvocation: signature inspection, integer,
 * floating-point, object and void invocations, retained arguments, and the
 * missing-signature answer from NSObject. */
#include "foundation_lite.h"

extern int printf(const char *fmt, ...);
extern int fflush(void *stream);

static int g_touched;

@interface InvocationTarget : NSObject
- (int)addA:(int)a b:(int)b;
- (double)scaleX:(double)x;
- (id)echo:(id)value;
- (void)touch;
@end

@implementation InvocationTarget
- (int)addA:(int)a b:(int)b { return a + b; }
- (double)scaleX:(double)x { return x * 2.5; }
- (id)echo:(id)value { return value; }
- (void)touch { g_touched = 1; }
@end

int main(void)
{
    InvocationTarget *target = [[InvocationTarget alloc] init];

    NSMethodSignature *sig =
        [target methodSignatureForSelector:@selector(addA:b:)];
    printf("[inv] sig %lu %c %c %c\n", [sig numberOfArguments],
           [sig getArgumentTypeAtIndex:0][0],
           [sig getArgumentTypeAtIndex:1][0],
           [sig methodReturnType][0]);

    NSInvocation *inv = [NSInvocation invocationWithMethodSignature:sig];
    [inv setTarget:target];
    [inv setSelector:@selector(addA:b:)];
    int a = 7, b = 35;
    [inv setArgument:&a atIndex:2];
    [inv setArgument:&b atIndex:3];
    [inv invoke];
    int sum = 0;
    [inv getReturnValue:&sum];
    printf("[inv] add %d\n", sum);

    NSMethodSignature *scaleSig =
        [target methodSignatureForSelector:@selector(scaleX:)];
    NSInvocation *scale = [NSInvocation invocationWithMethodSignature:scaleSig];
    [scale setSelector:@selector(scaleX:)];
    double x = 4.0;
    [scale setArgument:&x atIndex:2];
    [scale invokeWithTarget:target];
    double scaled = 0;
    [scale getReturnValue:&scaled];
    printf("[inv] double %.1f\n", scaled);

    NSMethodSignature *echoSig =
        [target methodSignatureForSelector:@selector(echo:)];
    NSInvocation *echo = [NSInvocation invocationWithMethodSignature:echoSig];
    [echo setTarget:target];
    [echo setSelector:@selector(echo:)];
    id value = [NSString stringWithUTF8String:"hello"];
    [echo setArgument:&value atIndex:2];
    [echo retainArguments];
    [echo invoke];
    id echoed = nil;
    [echo getReturnValue:&echoed];
    printf("[inv] echo %s\n", [(NSString *)echoed UTF8String]);

    NSMethodSignature *touchSig =
        [target methodSignatureForSelector:@selector(touch)];
    NSInvocation *touch = [NSInvocation invocationWithMethodSignature:touchSig];
    [touch setTarget:target];
    [touch setSelector:@selector(touch)];
    [touch invoke];
    printf("[inv] void %d\n", g_touched);

    printf("[inv] retained %d\n", [echo argumentsRetained]);
    printf("[inv] missing %d\n",
           [target methodSignatureForSelector:
                       @selector(addA:b:)] != nil ? 0 : 1);
    printf("[inv] done\n");
    fflush(0);
    return 0;
}
