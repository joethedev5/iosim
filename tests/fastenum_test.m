/* Fast-enumeration and collection-subscripting fixture: for-in over an
 * array, a set and a dictionary (keys), plus indexed/keyed subscript get,
 * set, append and removal. */
#include "foundation_lite.h"

extern int printf(const char *fmt, ...);

int main(void)
{
    NSMutableArray *arr = [NSMutableArray array];
    [arr addObject:@"alpha"];
    [arr addObject:@"beta"];
    [arr addObject:@"gamma"];

    NSMutableString *joined = [NSMutableString string];
    for (NSString *s in arr)
        [joined appendString:s];
    printf("[fe] array %s\n", [joined UTF8String]);

    NSMutableArray *nums = [NSMutableArray array];
    for (int i = 1; i <= 4; i++)
        [nums addObject:[NSNumber numberWithInt:i]];
    int sum = 0;
    for (NSNumber *n in nums)
        sum += [n intValue];
    printf("[fe] sum %d\n", sum);

    NSMutableSet *set = [NSMutableSet set];
    [set addObject:@"x"];
    [set addObject:@"y"];
    [set addObject:@"z"];
    NSMutableString *members = [NSMutableString string];
    for (NSString *m in set)
        [members appendString:m];
    printf("[fe] set %s\n", [members UTF8String]);

    NSMutableDictionary *d = [NSMutableDictionary dictionary];
    [d setObject:@"one" forKey:@"k1"];
    [d setObject:@"two" forKey:@"k2"];
    [d setObject:@"three" forKey:@"k3"];
    NSMutableString *keys = [NSMutableString string];
    for (id key in d)
        [keys appendString:key];
    printf("[fe] dict %s\n", [keys UTF8String]);

    printf("[fe] sub %s %s\n",
           [arr[0] UTF8String], [arr[2] UTF8String]);
    arr[1] = @"BETA";
    printf("[fe] replace %s\n", [arr[1] UTF8String]);
    arr[3] = @"delta";
    printf("[fe] append %s\n", [arr[3] UTF8String]);

    printf("[fe] dsub %s %s\n",
           [d[@"k1"] UTF8String], [d[@"k3"] UTF8String]);
    d[@"k2"] = @"TWO";
    printf("[fe] dset %s\n", [d[@"k2"] UTF8String]);
    d[@"k2"] = nil;
    printf("[fe] dremove %lu\n", [d count]);
    printf("[fe] dmiss %s\n", d[@"nope"] ? "yes" : "nil");
    return 0;
}
