/* NSSortDescriptor and array sorting, string comparison and exchange. */
#include "foundation_lite.h"

extern int printf(const char *fmt, ...);

@interface Person : NSObject {
    int _age;
}
- (id)initWithAge:(int)age;
- (int)age;
- (long)compareAge:(Person *)other;
@end

@implementation Person
- (id)initWithAge:(int)age
{
    self = [super init];
    _age = age;
    return self;
}
- (int)age { return _age; }
- (long)compareAge:(Person *)other { return _age - [other age]; }
@end

static NSMutableDictionary *record(const char *name, int price)
{
    NSMutableDictionary *d = [NSMutableDictionary dictionary];
    [d setObject:[NSString stringWithUTF8String:name] forKey:@"name"];
    [d setObject:[NSNumber numberWithInt:price] forKey:@"price"];
    return d;
}

int main(void)
{
    NSMutableArray *words = [NSMutableArray array];
    [words addObject:@"pear"];
    [words addObject:@"apple"];
    [words addObject:@"fig"];
    NSArray *sorted = [words sortedArrayUsingSelector:@selector(compare:)];
    printf("[sort] strings %s %s %s\n",
           [[sorted objectAtIndex:0] UTF8String],
           [[sorted objectAtIndex:1] UTF8String],
           [[sorted objectAtIndex:2] UTF8String]);

    NSMutableArray *numbers = [NSMutableArray array];
    [numbers addObject:[NSNumber numberWithInt:3]];
    [numbers addObject:[NSNumber numberWithInt:1]];
    [numbers addObject:[NSNumber numberWithInt:2]];
    NSSortDescriptor *numberOrder =
        [NSSortDescriptor sortDescriptorWithKey:nil ascending:YES];
    sorted = [numbers sortedArrayUsingDescriptors:
        [NSArray arrayWithObject:numberOrder]];
    printf("[sort] numbers %d %d %d\n",
           [[sorted objectAtIndex:0] intValue],
           [[sorted objectAtIndex:1] intValue],
           [[sorted objectAtIndex:2] intValue]);

    NSMutableArray *records = [NSMutableArray array];
    [records addObject:record("Cara", 5)];
    [records addObject:record("Amy", 25)];
    [records addObject:record("Bob", 10)];
    NSSortDescriptor *byName =
        [NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES];
    NSSortDescriptor *byPrice =
        [NSSortDescriptor sortDescriptorWithKey:@"price" ascending:NO];
    sorted = [records sortedArrayUsingDescriptors:
        [NSArray arrayWithObjects:byName, byPrice, nil]];
    printf("[sort] names %s %s %s prices %d %d %d\n",
           [[[sorted objectAtIndex:0] objectForKey:@"name"] UTF8String],
           [[[sorted objectAtIndex:1] objectForKey:@"name"] UTF8String],
           [[[sorted objectAtIndex:2] objectForKey:@"name"] UTF8String],
           [[[sorted objectAtIndex:0] objectForKey:@"price"] intValue],
           [[[sorted objectAtIndex:1] objectForKey:@"price"] intValue],
           [[[sorted objectAtIndex:2] objectForKey:@"price"] intValue]);

    NSMutableArray *people = [NSMutableArray array];
    [people addObject:[[Person alloc] initWithAge:30]];
    [people addObject:[[Person alloc] initWithAge:18]];
    [people addObject:[[Person alloc] initWithAge:41]];
    sorted = [people sortedArrayUsingSelector:@selector(compareAge:)];
    printf("[sort] ages %d %d %d\n",
           [[sorted objectAtIndex:0] age], [[sorted objectAtIndex:1] age],
           [[sorted objectAtIndex:2] age]);

    NSMutableArray *swap = [NSMutableArray array];
    [swap addObject:[NSNumber numberWithInt:1]];
    [swap addObject:[NSNumber numberWithInt:2]];
    [swap exchangeObjectAtIndex:0 withObjectAtIndex:1];
    printf("[sort] swapped %d %d\n", [[swap objectAtIndex:0] intValue],
           [[swap objectAtIndex:1] intValue]);

    NSString *hello = @"hello";
    printf("[sort] ci %ld\n",
           [hello caseInsensitiveCompare:@"HELLO"]);
    return 0;
}
