/* NSCalendar fixture: decompose a known date and build one back from
 * NSDateComponents, then decompose the result again. */
#include "foundation_lite.h"

extern int printf(const char *fmt, ...);
extern int fflush(void *stream);

static unsigned long all_units(void)
{
    return NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay |
           NSCalendarUnitHour | NSCalendarUnitMinute | NSCalendarUnitSecond |
           NSCalendarUnitWeekday;
}

int main(void)
{
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDate *epoch = [NSDate dateWithTimeIntervalSince1970:0];
    NSDateComponents *parts =
        [calendar components:all_units() fromDate:epoch];
    printf("[cal] epoch %04ld-%02ld-%02ld %02ld:%02ld:%02ld wd=%ld\n",
           [parts year], [parts month], [parts day], [parts hour],
           [parts minute], [parts second], [parts weekday]);

    NSDateComponents *built = [[NSDateComponents alloc] init];
    [built setYear:2024];
    [built setMonth:2];
    [built setDay:29];
    [built setHour:12];
    [built setMinute:34];
    [built setSecond:56];
    NSDate *date = [calendar dateFromComponents:built];
    NSDateComponents *back =
        [calendar components:all_units() fromDate:date];
    printf("[cal] back %04ld-%02ld-%02ld %02ld:%02ld:%02ld wd=%ld "
           "epoch=%.0f\n",
           [back year], [back month], [back day], [back hour],
           [back minute], [back second], [back weekday],
           [date timeIntervalSince1970]);
    printf("[cal] id=%s\n",
           [[calendar calendarIdentifier] UTF8String]);
    fflush(0);
    return 0;
}
