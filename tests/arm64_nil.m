/* An arm64 main that messages a nil receiver. Object, integer and
 * floating-point results must all read zero, the same as the x86_64
 * build of this source. */
@protocol NilCalls
- (const char *)UTF8String;
- (int)value;
- (double)ratio;
@end

extern void *objc_getClass(const char *name);
extern int printf(const char *, ...);

int main(void)
{
    id n = (id)objc_getClass("NoSuchClass");
    const char *s = [(id<NilCalls>)n UTF8String];
    int v = [(id<NilCalls>)n value];
    double d = [(id<NilCalls>)n ratio];
    printf("nil %d %d %.1f\n", s == 0, v, d);
    return 0;
}
