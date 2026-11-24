/* An arm64 main that formats through NSString's variadic constructors.
 * Their type encoding stops at the named arguments, so without the
 * bridge's rendering the native va_list would read empty slots. The
 * x86_64 build calls the native implementations with a real va_list and
 * prints the same four lines. */
@protocol StrFormat
+ (id)alloc;
+ (id)stringWithFormat:(id)fmt, ...;
- (id)initWithFormat:(id)fmt, ...;
- (const char *)UTF8String;
@end

extern void *objc_getClass(const char *name);
extern int printf(const char *, ...);

int main(void)
{
    id cls = (id)objc_getClass("NSString");
    id s1 = [(id<StrFormat>)cls stringWithFormat:@"%d-%@", 42, @"x"];
    id s2 = [(id<StrFormat>)cls stringWithFormat:@"%@ %.2f %s",
                                              @"pi", 3.14159, "ok"];
    id s3 = [[(id<StrFormat>)cls alloc] initWithFormat:@"%ld/%zu",
             123456789L, (unsigned long)7];
    id s4 = [(id<StrFormat>)cls stringWithFormat:@"%5.1f|%-4d|", 2.25, 7];
    printf("fmt1 %s\n", [(id<StrFormat>)s1 UTF8String]);
    printf("fmt2 %s\n", [(id<StrFormat>)s2 UTF8String]);
    printf("fmt3 %s\n", [(id<StrFormat>)s3 UTF8String]);
    printf("fmt4 %s\n", [(id<StrFormat>)s4 UTF8String]);
    return 0;
}
