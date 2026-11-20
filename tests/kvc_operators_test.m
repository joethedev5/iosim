/* KVC collection operators: @count, @sum, @avg, @max, @min,
 * @distinctUnionOfObjects, @unionOfArrays and @distinctUnionOfArrays, plus
 * NSDictionary's valueForKey: mapping to objectForKey:. */
#include "foundation_lite.h"

extern int printf(const char *fmt, ...);

static NSMutableDictionary *entry(int price, NSString *category)
{
    NSMutableDictionary *d = [NSMutableDictionary dictionary];
    [d setObject:[NSNumber numberWithInt:price] forKey:@"price"];
    [d setObject:category forKey:@"category"];
    return d;
}

int main(void)
{
    NSMutableArray *numbers = [NSMutableArray array];
    for (int i = 1; i <= 4; i++)
        [numbers addObject:[NSNumber numberWithInt:i]];
    printf("[kvcop] numbers %d %.0f %.1f %d %d\n",
           [[numbers valueForKeyPath:@"@count"] intValue],
           [[numbers valueForKeyPath:@"@sum"] doubleValue],
           [[numbers valueForKeyPath:@"@avg"] doubleValue],
           [[numbers valueForKeyPath:@"@max"] intValue],
           [[numbers valueForKeyPath:@"@min"] intValue]);

    NSMutableArray *entries = [NSMutableArray array];
    [entries addObject:entry(10, @"a")];
    [entries addObject:entry(25, @"b")];
    [entries addObject:entry(5, @"a")];
    printf("[kvcop] prices %.0f %.1f %d %d\n",
           [[entries valueForKeyPath:@"@sum.price"] doubleValue],
           [[entries valueForKeyPath:@"@avg.price"] doubleValue],
           [[entries valueForKeyPath:@"@max.price"] intValue],
           [[entries valueForKeyPath:@"@min.price"] intValue]);

    NSArray *categories =
        [entries valueForKeyPath:@"@distinctUnionOfObjects.category"];
    printf("[kvcop] categories %lu %s %s\n", [categories count],
           [[categories objectAtIndex:0] UTF8String],
           [[categories objectAtIndex:1] UTF8String]);

    NSMutableArray *left = [NSMutableArray array];
    [left addObject:[NSNumber numberWithInt:1]];
    [left addObject:[NSNumber numberWithInt:2]];
    NSMutableArray *right = [NSMutableArray array];
    [right addObject:[NSNumber numberWithInt:2]];
    [right addObject:[NSNumber numberWithInt:3]];
    NSMutableArray *pairs = [NSMutableArray array];
    [pairs addObject:left];
    [pairs addObject:right];
    printf("[kvcop] union %lu distinct %lu\n",
           [[pairs valueForKeyPath:@"@unionOfArrays"] count],
           [[pairs valueForKeyPath:@"@distinctUnionOfArrays"] count]);

    NSDictionary *one = [entries objectAtIndex:0];
    printf("[kvcop] dict %d\n", [[one valueForKey:@"price"] intValue]);
    return 0;
}
