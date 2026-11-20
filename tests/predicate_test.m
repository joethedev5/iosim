/* NSPredicate format parsing and NSArray filtering. */
#include "foundation_lite.h"

extern int printf(const char *fmt, ...);

static NSMutableDictionary *record(const char *name, int price)
{
    NSMutableDictionary *d = [NSMutableDictionary dictionary];
    [d setObject:[NSString stringWithUTF8String:name] forKey:@"name"];
    [d setObject:[NSNumber numberWithInt:price] forKey:@"price"];
    return d;
}

static NSArray *matches(NSArray *records, NSString *format)
{
    NSPredicate *predicate = [NSPredicate predicateWithFormat:format];
    return [records filteredArrayUsingPredicate:predicate];
}

int main(void)
{
    NSMutableArray *records = [NSMutableArray array];
    [records addObject:record("Amy", 25)];
    [records addObject:record("Bob", 10)];
    [records addObject:record("Cara", 5)];

    printf("[pred] contains=%lu\n",
           [matches(records, @"price < 20 AND name CONTAINS 'o'") count]);
    printf("[pred] notor=%lu\n",
           [matches(records, @"NOT (price < 10) OR name == 'Cara'") count]);
    printf("[pred] like=%lu\n",
           [matches(records, @"name LIKE 'A*'") count]);
    printf("[pred] range=%lu\n",
           [matches(records, @"price >= 10 AND price <= 25") count]);
    printf("[pred] in=%lu\n",
           [matches(records, @"name IN {'Amy', 'Cara'}") count]);
    printf("[pred] nonnil=%lu\n",
           [matches(records, @"name != nil") count]);

    NSMutableArray *words = [NSMutableArray array];
    [words addObject:@"pear"];
    [words addObject:@"apple"];
    [words addObject:@"fig"];
    printf("[pred] self=%lu\n",
           [matches(words, @"SELF BEGINSWITH 'p'") count]);

    NSMutableArray *copy = [NSMutableArray arrayWithArray:records];
    [copy filterUsingPredicate:
        [NSPredicate predicateWithFormat:@"price > 10"]];
    printf("[pred] filtered=%lu\n", [copy count]);
    printf("[pred] true=%d false=%d\n",
           [[NSPredicate predicateWithValue:YES]
               evaluateWithObject:records],
           [[NSPredicate predicateWithValue:NO]
               evaluateWithObject:records]);
    return 0;
}
