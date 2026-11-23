/* NSLocale identifiers and NSLocale key lookup, plus NSTimeZone names,
 * fixed offsets and the system zone selected from TZ. */
#include "foundation_lite.h"

extern int printf(const char *fmt, ...);

int main(void)
{
    NSLocale *current = [NSLocale currentLocale];
    printf("[locale] current %s %s %s\n",
           [[current localeIdentifier] UTF8String],
           [[current languageCode] UTF8String],
           [[current countryCode] UTF8String]);

    NSLocale *french = [NSLocale localeWithLocaleIdentifier:@"fr_FR"];
    printf("[locale] french %s %s %s\n",
           [[french localeIdentifier] UTF8String],
           [[french languageCode] UTF8String],
           [[french countryCode] UTF8String]);
    printf("[locale] keys %s %s %s\n",
           [[french objectForKey:NSLocaleLanguageCode] UTF8String],
           [[french objectForKey:NSLocaleCountryCode] UTF8String],
           [[french objectForKey:NSLocaleIdentifier] UTF8String]);

    NSLocale *dashed = [NSLocale localeWithLocaleIdentifier:@"pt-BR"];
    printf("[locale] dash %s %s\n",
           [[dashed languageCode] UTF8String],
           [[dashed countryCode] UTF8String]);

    NSTimeZone *system = [NSTimeZone systemTimeZone];
    printf("[tz] system %s %ld %d\n", [[system name] UTF8String],
           [system secondsFromGMT], [system isDaylightSavingTime]);

    NSTimeZone *los_angeles =
        [NSTimeZone timeZoneWithName:@"America/Los_Angeles"];
    printf("[tz] la %s %ld\n", [[los_angeles name] UTF8String],
           [los_angeles secondsFromGMT]);

    printf("[tz] unknown %d\n",
           [NSTimeZone timeZoneWithName:@"Mars/Olympus"] == nil);

    NSTimeZone *fixed = [NSTimeZone timeZoneForSecondsFromGMT:5400];
    printf("[tz] fixed %s %ld\n", [[fixed name] UTF8String],
           [fixed secondsFromGMT]);

    printf("[tz] known %lu\n",
           (unsigned long)[[NSTimeZone knownTimeZoneNames] count]);
    return 0;
}
