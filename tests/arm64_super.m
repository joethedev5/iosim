/* An arm64 main that calls a superclass method and several plain C
 * functions. The super send goes through objc_msgSendSuper2 and the C
 * calls go through the generic shim gate: strlen, calloc/free, strtod
 * (a double return) and strncmp. */
extern int printf(const char *fmt, ...);
extern unsigned long strlen(const char *s);
extern void *calloc(unsigned long n, unsigned long size);
extern void free(void *p);
extern double strtod(const char *s, char **end);
extern int strncmp(const char *a, const char *b, unsigned long n);

__attribute__((objc_root_class))
@interface GenBase {
    Class isa;
}
+ (int)value;
+ (int)viaSuper;
@end

@implementation GenBase
+ (int)value { return 7; }
+ (int)viaSuper { return 11; }
@end

@interface GenSub : GenBase
@end

@implementation GenSub
+ (int)value { return 9; }
+ (int)viaSuper { return [super value] + 1; }
@end

int main(void)
{
    int a = [GenSub value];
    int b = [GenSub viaSuper];
    unsigned long n = strlen("abcd");
    void *p = calloc(2, 8);
    *(unsigned long *)p = 30;
    free(p);
    double d = strtod("2.5", 0);
    int cmp = strncmp("abc", "ab", 2);
    printf("a=%d b=%d n=%lu d=%d cmp=%d\n", a, b, n, (int)(d * 2), cmp);
    return a + b + (int)n + cmp + (int)(d * 2);
}
