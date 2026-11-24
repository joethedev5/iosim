/* An arm64 app calling native Foundation through real message sends. The
 * protocol declares the selectors, objc_getClass finds the x86_64
 * Foundation class loaded with --load-dylib, and the interpreter marshals
 * both sends by their type encodings. */
@protocol Arm64StringCalls
+ (id)stringWithUTF8String:(const char *)s;
- (unsigned long)length;
@end

extern void *objc_getClass(const char *name);

int main(void)
{
    id cls = (id)objc_getClass("NSString");
    id str = [(id<Arm64StringCalls>)cls stringWithUTF8String:"hello"];
    return (int)[(id<Arm64StringCalls>)str length];
}
