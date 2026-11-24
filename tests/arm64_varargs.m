/* printf-family variadic calls from arm64 app code. Darwin arm64 places
 * anonymous variadic arguments on the stack, so each function needs a
 * gate that renders the format and hands back its own return value. */
#include "UIKitStub.h"

extern int printf(const char *fmt, ...);
extern int snprintf(char *buf, unsigned long size, const char *fmt, ...);
extern int sprintf(char *buf, const char *fmt, ...);
extern int fprintf(void *stream, const char *fmt, ...);
extern void *stderr;
extern void NSLog(id format, ...);

int main(void)
{
    char buf[64];
    int n1 = snprintf(buf, sizeof buf, "%s=%d", "x", 7);
    printf("snprintf %d %s\n", n1, buf);
    int n2 = sprintf(buf, "%.1f %c", 2.5, 'k');
    printf("sprintf %d %s\n", n2, buf);
    int n3 = snprintf(buf, 4, "%s", "abcdef");
    printf("trunc %d %s\n", n3, buf);
    fprintf(stderr, "fprintf %d %s\n", 42, "err");
    NSLog(@"NSLog %@ %d", @"value", 9);

    snprintf(buf, sizeof buf, "%08.3f", 2.5);
    printf("fmt %s\n", buf);
    snprintf(buf, sizeof buf, "%+d", 7);
    printf("sign %s\n", buf);
    snprintf(buf, sizeof buf, "[%-6d]", 42);
    printf("left %s\n", buf);
    snprintf(buf, sizeof buf, "%.2s", "abcdef");
    printf("prec %s\n", buf);
    snprintf(buf, sizeof buf, "%*d", 5, 42);
    printf("star %s\n", buf);
    snprintf(buf, sizeof buf, "%.*s", 3, "abcdef");
    printf("starp %s\n", buf);
    snprintf(buf, sizeof buf, "%#x", 255);
    printf("hex %s\n", buf);
    snprintf(buf, sizeof buf, "%zu", (unsigned long)99);
    printf("size %s\n", buf);
    snprintf(buf, sizeof buf, "%ld", 123456789L);
    printf("long %s\n", buf);
    snprintf(buf, sizeof buf, "%lld", -5LL);
    printf("llong %s\n", buf);
    snprintf(buf, sizeof buf, "[%6.2f]", 3.14159);
    printf("width %s\n", buf);
    NSLog(@"%@ %5.1f", @"nslog", 2.25);
    return 0;
}
