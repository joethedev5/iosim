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
    return 0;
}
