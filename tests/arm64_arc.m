/* An arm64 main compiled with ARC: an autorelease pool, Foundation
 * objects, a copied string, and a block with a __block capture whose
 * copy helper is arm64 code invoked from the native block runtime.
 * Prints "v=82 w=77 r=85", then returns 244. */
@protocol ArcCalls
+ (id)stringWithUTF8String:(const char *)s;
- (int)intValue;
+ (id)numberWithInt:(int)v;
- (id)copy;
@end

extern void *objc_getClass(const char *name);
extern int printf(const char *fmt, ...);

int main(void)
{
    @autoreleasepool
    {
        id strCls = (__bridge id)objc_getClass("NSString");
        id numCls = (__bridge id)objc_getClass("NSNumber");
        id s = [(id<ArcCalls>)strCls stringWithUTF8String:"77"];
        id n = [(id<ArcCalls>)numCls numberWithInt:5];
        int v = [(id<ArcCalls>)s intValue] + [(id<ArcCalls>)n intValue];
        id copy = [(id<ArcCalls>)s copy];
        int w = [(id<ArcCalls>)copy intValue];
        __block int captures = 3;
        int (^add)(int) = ^(int x) { captures += x; return captures; };
        int r = add(v);
        printf("v=%d w=%d r=%d\n", v, w, r);
        return v + w + r; /* 82 + 77 + 85 = 244 */
    }
}
