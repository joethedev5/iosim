/* NSScanner: integers, doubles, string matching and scan-up-to with real
 * scan locations. */
#include "foundation_lite.h"

extern int printf(const char *fmt, ...);

int main(void)
{
    NSScanner *scanner = [NSScanner scannerWithString:
        @"42 -3.5 name=value rest"];
    int number = 0;
    double fraction = 0;
    NSString *word = nil;
    BOOL ok = [scanner scanInt:&number];
    printf("[scan] int=%d value=%d at=%lu\n", ok, number,
           [scanner scanLocation]);
    ok = [scanner scanDouble:&fraction];
    printf("[scan] double=%d value=%.1f\n", ok, fraction);
    ok = [scanner scanUpToString:@"=" intoString:&word];
    printf("[scan] up=%d word=%s\n", ok, word ? [word UTF8String] : "(nil)");
    printf("[scan] equals=%d\n", [scanner scanString:@"=" intoString:0]);
    printf("[scan] value=%d\n", [scanner scanString:@"value" intoString:0]);
    ok = [scanner scanUpToString:@"!" intoString:&word];
    printf("[scan] rest=%d string=%s end=%d\n", ok,
           word ? [word UTF8String] : "(nil)", [scanner isAtEnd]);
    return 0;
}
