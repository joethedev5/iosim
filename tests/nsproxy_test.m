/* NSProxy is a second root class: a subclass that forwards an absent
 * selector through methodSignatureForSelector:/forwardInvocation: answers
 * 64 without being an NSObject subclass. */
#include "foundation_lite.h"

extern int printf(const char *fmt, ...);
extern int fflush(void *stream);
extern int strcmp(const char *a, const char *b);

@interface ValueProxy : NSProxy {
@public
    id target;
}
@end

@interface ValueProxy (Forwarded)
- (int)value;
@end

@implementation ValueProxy
- (NSMethodSignature *)methodSignatureForSelector:(SEL)sel
{
    if (strcmp((const char *)sel, "value") == 0)
        return [NSMethodSignature signatureWithObjCTypes:"i@:"];
    return nil;
}
- (void)forwardInvocation:(NSInvocation *)invocation
{
    int value = 64;
    [invocation setReturnValue:&value];
    printf("[proxy] forwarded %s\n", (const char *)[invocation selector]);
}
@end

int main(void)
{
    ValueProxy *proxy = [[ValueProxy alloc] init];
    printf("[proxy] isProxy %d\n", [proxy isProxy]);
    printf("[proxy] kind %d\n", [proxy isKindOfClass:[NSProxy class]]);
    int value = [proxy value];
    printf("[proxy] value %d\n", value);
    printf("[proxy] done\n");
    fflush(0);
    return 0;
}
