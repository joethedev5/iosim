/* Delivery of -forwardInvocation: from the message-send trampoline: a proxy
 * that reports method signatures for absent selectors receives the captured
 * arguments and supplies the return value through its NSInvocation. */
#include "foundation_lite.h"

extern int printf(const char *fmt, ...);
extern int fflush(void *stream);
extern int strcmp(const char *a, const char *b);

@interface ForwardProxy : NSObject
@end

@interface ForwardProxy (Forwarded)
- (int)addA:(int)a b:(int)b;
- (id)greet;
@end

@implementation ForwardProxy
- (NSMethodSignature *)methodSignatureForSelector:(SEL)sel
{
    if (strcmp((const char *)sel, "addA:b:") == 0)
        return [NSMethodSignature signatureWithObjCTypes:"i@:ii"];
    if (strcmp((const char *)sel, "greet") == 0)
        return [NSMethodSignature signatureWithObjCTypes:"@@:"];
    return nil;
}
- (void)forwardInvocation:(NSInvocation *)invocation
{
    SEL sel = [invocation selector];
    if (strcmp((const char *)sel, "addA:b:") == 0)
    {
        int a = 0, b = 0;
        [invocation getArgument:&a atIndex:2];
        [invocation getArgument:&b atIndex:3];
        printf("[fwd2] args %d %d\n", a, b);
        int sum = a + b;
        [invocation setReturnValue:&sum];
    }
    else if (strcmp((const char *)sel, "greet") == 0)
    {
        id greeting = [NSString stringWithUTF8String:"proxy-greeting"];
        [invocation setReturnValue:&greeting];
    }
}
@end

int main(void)
{
    ForwardProxy *proxy = [[ForwardProxy alloc] init];
    int sum = [proxy addA:19 b:23];
    printf("[fwd2] return %d\n", sum);
    id greeting = [proxy greet];
    printf("[fwd2] object %s\n", [(NSString *)greeting UTF8String]);
    printf("[fwd2] done\n");
    fflush(0);
    return 0;
}
