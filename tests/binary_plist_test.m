/* Binary property-list round trip: dictionaries, arrays, strings (ASCII and
 * non-ASCII), integers, booleans, reals, dates and data. */
#include "UIKitStub.h"
extern int printf(const char *fmt, ...);
extern int fflush(void *stream);
extern int memcmp(const void *a, const void *b, unsigned long n);

int main(void)
{
    @autoreleasepool
    {
        NSMutableDictionary *root = [NSMutableDictionary dictionary];
        [root setObject:@"Hello" forKey:@"text"];
        [root setObject:[NSNumber numberWithInt:42] forKey:@"int"];
        [root setObject:[NSNumber numberWithBool:YES] forKey:@"bool"];
        [root setObject:[NSNumber numberWithDouble:2.5] forKey:@"real"];
        [root setObject:[@"abc" dataUsingEncoding:4] forKey:@"data"];
        [root setObject:[NSArray arrayWithObjects:
            [NSNumber numberWithInt:3], [NSNumber numberWithInt:4], nil]
                 forKey:@"array"];
        [root setObject:[NSDate dateWithTimeIntervalSince1970:1700000000]
                 forKey:@"date"];
        [root setObject:@"café ☃" forKey:@"unicode"];

        unsigned long format = 0;
        NSData *binary = [NSPropertyListSerialization
            dataWithPropertyList:root
            format:NSPropertyListBinaryFormat_v1_0 options:0 error:0];
        printf("[bplist] header %d %d\n",
               binary && memcmp([binary bytes], "bplist00", 8) == 0,
               (int)[binary length] > 40);
        id parsed = [NSPropertyListSerialization
            propertyListWithData:binary options:0 format:&format error:0];
        NSArray *array = [parsed objectForKey:@"array"];
        printf("[bplist] dict %s %d %d %g %lu %ld\n",
               [[parsed objectForKey:@"text"] UTF8String],
               [[parsed objectForKey:@"int"] intValue],
               [[parsed objectForKey:@"bool"] boolValue],
               [[parsed objectForKey:@"real"] doubleValue],
               [[parsed objectForKey:@"data"] length],
               (long)[array count]);
        printf("[bplist] array %d %d\n",
               [[array objectAtIndex:0] intValue],
               [[array objectAtIndex:1] intValue]);
        printf("[bplist] unicode %d\n",
               [[parsed objectForKey:@"unicode"] isEqualToString:
                   @"café ☃"]);
        printf("[bplist] date %.0f format %lu\n",
               [[parsed objectForKey:@"date"] timeIntervalSince1970],
               format);
        fflush(0);
    }
    return 0;
}
