#include "foundation_lite.h"

/* Formatter fixture: the same date format string parses and prints, so a
 * parsed date round-trips; number formatters group, round, add currency and
 * percent affixes, and parse formatted output back to a number. */

int main(void)
{
    @autoreleasepool
    {
        NSDateFormatter *dates = [[NSDateFormatter alloc] init];
        [dates setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
        NSDate *parsed = [dates dateFromString:@"2024-02-29 12:34:56"];
        NSLog(@"parsed %lld", (long long)[parsed timeIntervalSince1970]);
        NSDate *round = [dates
            dateFromString:[dates stringFromDate:parsed]];
        NSLog(@"roundtrip %lld", (long long)[round timeIntervalSince1970]);
        NSLog(@"invalid %@",
              [dates dateFromString:@"not a date"] ? @"yes" : @"no");

        NSNumberFormatter *decimal = [[NSNumberFormatter alloc] init];
        [decimal setNumberStyle:NSNumberFormatterDecimalStyle];
        [decimal setMaximumFractionDigits:2];
        NSLog(@"decimal %@",
              [decimal stringFromNumber:[NSNumber numberWithDouble:1234.5]]);
        NSLog(@"parsed number %@",
              [[decimal numberFromString:@"1,234.50"] stringValue]);

        NSNumberFormatter *currency = [[NSNumberFormatter alloc] init];
        [currency setNumberStyle:NSNumberFormatterCurrencyStyle];
        NSLog(@"currency %@",
              [currency stringFromNumber:[NSNumber numberWithDouble:99.5]]);

        NSNumberFormatter *percent = [[NSNumberFormatter alloc] init];
        [percent setNumberStyle:NSNumberFormatterPercentStyle];
        [percent setMaximumFractionDigits:1];
        NSLog(@"percent %@",
              [percent stringFromNumber:[NSNumber numberWithDouble:0.256]]);
    }
    return 0;
}
