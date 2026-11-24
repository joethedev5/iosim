/* NSByteCountFormatter and NSDateComponentsFormatter outputs. */
#include "foundation_lite.h"

extern int printf(const char *fmt, ...);
extern int fflush(void *stream);

int main(void)
{
    printf("[bcf] file %s\n",
           [[NSByteCountFormatter stringFromByteCount:999
                                          countStyle:NSByteCountFormatterCountStyleFile]
               UTF8String]);
    printf("[bcf] kilo %s\n",
           [[NSByteCountFormatter stringFromByteCount:1000
                                          countStyle:NSByteCountFormatterCountStyleFile]
               UTF8String]);
    printf("[bcf] half %s\n",
           [[NSByteCountFormatter stringFromByteCount:1536
                                          countStyle:NSByteCountFormatterCountStyleFile]
               UTF8String]);
    printf("[bcf] mega %s\n",
           [[NSByteCountFormatter stringFromByteCount:1500000
                                          countStyle:NSByteCountFormatterCountStyleFile]
               UTF8String]);
    printf("[bcf] memory %s\n",
           [[NSByteCountFormatter stringFromByteCount:1048576
                                          countStyle:NSByteCountFormatterCountStyleMemory]
               UTF8String]);
    printf("[bcf] decimal %s\n",
           [[NSByteCountFormatter stringFromByteCount:1500
                                          countStyle:NSByteCountFormatterCountStyleDecimal]
               UTF8String]);
    printf("[bcf] binary %s\n",
           [[NSByteCountFormatter stringFromByteCount:1536
                                          countStyle:NSByteCountFormatterCountStyleBinary]
               UTF8String]);

    NSByteCountFormatter *bytes = [[NSByteCountFormatter alloc] init];
    [bytes setCountStyle:NSByteCountFormatterCountStyleFile];
    [bytes setAllowedUnits:NSByteCountFormatterUseKB];
    printf("[bcf] mask %s\n",
           [[bytes stringFromByteCount:1500000] UTF8String]);
    [bytes setIncludesUnit:NO];
    printf("[bcf] count %s\n", [[bytes stringFromByteCount:1536] UTF8String]);
    [bytes setIncludesUnit:YES];
    [bytes setIncludesCount:NO];
    printf("[bcf] unit %s\n", [[bytes stringFromByteCount:1536] UTF8String]);
    [bytes setIncludesCount:YES];
    [bytes setAllowedUnits:NSByteCountFormatterUseDefault];
    [bytes setIncludesActualByteCount:YES];
    printf("[bcf] actual %s\n",
           [[bytes stringFromByteCount:1536] UTF8String]);
    [bytes setIncludesActualByteCount:NO];
    [bytes setZeroPadsFractionDigits:YES];
    printf("[bcf] pad %s\n", [[bytes stringFromByteCount:2048] UTF8String]);
    printf("[bcf] zero %s\n", [[bytes stringFromByteCount:0] UTF8String]);

    NSDateComponentsFormatter *times =
        [[NSDateComponentsFormatter alloc] init];
    [times setUnitsStyle:NSDateComponentsFormatterUnitsStylePositional];
    printf("[dcf] pos %s\n",
           [[times stringFromTimeInterval:3661] UTF8String]);
    printf("[dcf] pos2 %s\n",
           [[times stringFromTimeInterval:61] UTF8String]);
    printf("[dcf] hours %s\n",
           [[times stringFromTimeInterval:3600] UTF8String]);
    [times setUnitsStyle:NSDateComponentsFormatterUnitsStyleAbbreviated];
    printf("[dcf] abbr %s\n",
           [[times stringFromTimeInterval:3661] UTF8String]);
    [times setUnitsStyle:NSDateComponentsFormatterUnitsStyleShort];
    printf("[dcf] short %s\n",
           [[times stringFromTimeInterval:90061] UTF8String]);
    [times setUnitsStyle:NSDateComponentsFormatterUnitsStyleFull];
    printf("[dcf] full %s\n",
           [[times stringFromTimeInterval:90061] UTF8String]);
    [times setMaximumUnitCount:2];
    printf("[dcf] max %s\n",
           [[times stringFromTimeInterval:90061] UTF8String]);
    [times setMaximumUnitCount:0];
    [times setUnitsStyle:NSDateComponentsFormatterUnitsStyleShort];
    [times setAllowedUnits:NSCalendarUnitHour | NSCalendarUnitMinute |
                            NSCalendarUnitSecond];
    printf("[dcf] allhours %s\n",
           [[times stringFromTimeInterval:90061] UTF8String]);
    [times setAllowedUnits:NSCalendarUnitHour | NSCalendarUnitMinute];
    [times setIncludesTimeRemainingPhrase:YES];
    printf("[dcf] remain %s\n",
           [[times stringFromTimeInterval:3700] UTF8String]);
    [times setIncludesTimeRemainingPhrase:NO];
    [times setIncludesApproximationPhrase:YES];
    printf("[dcf] about %s\n",
           [[times stringFromTimeInterval:3700] UTF8String]);
    [times setIncludesApproximationPhrase:NO];
    NSDateComponents *parts = [[NSDateComponents alloc] init];
    [parts setHour:2];
    [parts setMinute:5];
    printf("[dcf] comps %s\n",
           [[times stringFromDateComponents:parts] UTF8String]);
    [times setUnitsStyle:NSDateComponentsFormatterUnitsStylePositional];
    [times setAllowedUnits:NSCalendarUnitYear | NSCalendarUnitMonth |
                            NSCalendarUnitWeekOfYear | NSCalendarUnitDay |
                            NSCalendarUnitHour | NSCalendarUnitMinute |
                            NSCalendarUnitSecond];
    NSDate *start = [NSDate dateWithTimeIntervalSince1970:0];
    NSDate *end = [NSDate dateWithTimeIntervalSince1970:3661];
    printf("[dcf] dates %s\n",
           [[times stringFromDate:start toDate:end] UTF8String]);
    printf("[dcf] delta %.0f\n", [end timeIntervalSinceDate:start]);
    fflush(0);
    return 0;
}
