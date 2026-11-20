#include "foundation_lite.h"

int main(void)
{
    @autoreleasepool
    {
        NSString *s = [NSString stringWithFormat:@"value=%d %@", 42,
                       [NSNumber numberWithInt:7]];
        NSLog(@"%@", s);
        NSLog(@"NSString length=%lu upper=%@", [s length],
              [s uppercaseString]);

        NSMutableArray *a = [NSMutableArray array];
        [a addObject:[NSString stringWithUTF8String:"alpha"]];
        [a addObject:[NSString stringWithUTF8String:"beta"]];
        NSLog(@"array=%@ count=%lu first=%@", a, [a count], [a firstObject]);

        NSMutableDictionary *d = [NSMutableDictionary dictionary];
        [d setObject:[NSNumber numberWithInt:123]
              forKey:[NSString stringWithUTF8String:"number"]];
        [d setObject:[NSString stringWithUTF8String:"text"]
              forKey:[NSString stringWithUTF8String:"string"]];
        NSLog(@"dict number=%@ string=%@ count=%lu",
              [d objectForKey:[NSString stringWithUTF8String:"number"]],
              [d objectForKey:[NSString stringWithUTF8String:"string"]],
              [d count]);

        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        [defaults setObject:[NSString stringWithUTF8String:"hello"]
                     forKey:[NSString stringWithUTF8String:"string"]];
        [defaults setObject:[NSNumber numberWithInt:9]
                     forKey:[NSString stringWithUTF8String:"number"]];
        NSLog(@"defaults string=%@ number=%ld",
              [defaults stringForKey:[NSString stringWithUTF8String:"string"]],
              [defaults integerForKey:[NSString stringWithUTF8String:"number"]]);
        NSBundle *bundle = [NSBundle mainBundle];
        NSLog(@"bundle resource=%@",
              [bundle pathForResource:[NSString stringWithUTF8String:"badge"]
                               ofType:[NSString stringWithUTF8String:"png"]]);

        NSArray *parts = [[NSString stringWithUTF8String:"a,b,c"]
            componentsSeparatedByString:[NSString stringWithUTF8String:","]];
        NSLog(@"parts=%@ count=%lu", parts, [parts count]);

        [[NSNotificationCenter defaultCenter]
            postNotificationName:[NSString stringWithUTF8String:"TestNote"]
                          object:nil];
        NSLog(@"done");
    }
    return 0;
}
