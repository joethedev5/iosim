/* NSMeasurement unit conversion, arithmetic and formatting. */
#include "foundation_lite.h"

extern int printf(const char *fmt, ...);
extern int fflush(void *stream);

static void show_conversion(const char *label, NSMeasurement *measurement,
                            NSUnit *unit)
{
    NSMeasurement *converted =
        [measurement measurementByConvertingToUnit:unit];
    printf("[meas] %s %.4f\n", label, [converted doubleValue]);
    fflush(0);
}

int main(void)
{
    NSMeasurement *km = [[NSMeasurement alloc] initWithDoubleValue:1.5
                                                               unit:[NSUnitLength kilometers]];
    show_conversion("km-m", km, [NSUnitLength meters]);

    NSMeasurement *metricMile = [[NSMeasurement alloc] initWithDoubleValue:1609.344
                                                                      unit:[NSUnitLength meters]];
    show_conversion("m-mi", metricMile, [NSUnitLength miles]);

    NSMeasurement *fahrenheit = [[NSMeasurement alloc] initWithDoubleValue:32.0
                                                                      unit:[NSUnitTemperature fahrenheit]];
    show_conversion("f-c", fahrenheit, [NSUnitTemperature celsius]);

    NSMeasurement *kelvin = [[NSMeasurement alloc] initWithDoubleValue:300.0
                                                                  unit:[NSUnitTemperature kelvin]];
    show_conversion("k-c", kelvin, [NSUnitTemperature celsius]);

    NSMeasurement *hours = [[NSMeasurement alloc] initWithDoubleValue:1.5
                                                                 unit:[NSUnitDuration hours]];
    show_conversion("h-s", hours, [NSUnitDuration seconds]);

    NSMeasurement *speed = [[NSMeasurement alloc] initWithDoubleValue:100.0
                                                                 unit:[NSUnitSpeed kilometersPerHour]];
    show_conversion("kmh-ms", speed, [NSUnitSpeed metersPerSecond]);

    NSMeasurement *gallon = [[NSMeasurement alloc] initWithDoubleValue:1.0
                                                                  unit:[NSUnitVolume gallons]];
    show_conversion("gal-l", gallon, [NSUnitVolume liters]);

    NSMeasurement *oneMeter = [[NSMeasurement alloc] initWithDoubleValue:1.0
                                                                   unit:[NSUnitLength meters]];
    NSMeasurement *fiftyCm = [[NSMeasurement alloc] initWithDoubleValue:50.0
                                                                  unit:[NSUnitLength centimeters]];
    NSMeasurement *sum = [oneMeter measurementByAddingMeasurement:fiftyCm];
    printf("[meas] add %.4f\n", [sum doubleValue]);
    fflush(0);

    NSMeasurement *thousandM =
        [[NSMeasurement alloc] initWithDoubleValue:1000.0
                                             unit:[NSUnitLength meters]];
    NSMeasurement *oneKm =
        [[NSMeasurement alloc] initWithDoubleValue:1.0
                                             unit:[NSUnitLength kilometers]];
    printf("[meas] equal %d\n", [thousandM isEqualToMeasurement:oneKm] ? 1 : 0);
    printf("[meas] uneq %d\n",
           [thousandM isEqualToMeasurement:
               [[NSMeasurement alloc] initWithDoubleValue:1.0
                                                    unit:[NSUnitLength miles]]]
               ? 1 : 0);
    fflush(0);

    NSMeasurementFormatter *formatter =
        [[NSMeasurementFormatter alloc] init];
    NSMeasurement *fifteenHundredM =
        [[NSMeasurement alloc] initWithDoubleValue:1500.0
                                             unit:[NSUnitLength meters]];
    printf("[meas] nat %s\n",
           [[formatter stringFromMeasurement:fifteenHundredM] UTF8String]);
    [formatter setUnitStyle:NSFormattingUnitStyleShort];
    printf("[meas] short %s\n",
           [[formatter stringFromMeasurement:fifteenHundredM] UTF8String]);
    [formatter setUnitStyle:NSFormattingUnitStyleMedium];
    [formatter setUnitOptions:NSMeasurementFormatterUnitOptionsProvidedUnit];
    printf("[meas] provided %s\n",
           [[formatter stringFromMeasurement:fifteenHundredM] UTF8String]);
    printf("[meas] unit %s\n",
           [[formatter stringFromUnit:[NSUnitLength kilometers]] UTF8String]);
    [formatter setUnitOptions:NSMeasurementFormatterUnitOptionsNaturalScale];
    printf("[meas] temp %s\n",
           [[formatter stringFromMeasurement:fahrenheit] UTF8String]);
    [formatter setUnitOptions:
        NSMeasurementFormatterUnitOptionsProvidedUnit |
        NSMeasurementFormatterUnitOptionsTemperatureWithoutUnit];
    printf("[meas] tempnounit %s\n",
           [[formatter stringFromMeasurement:fahrenheit] UTF8String]);
    [formatter setUnitOptions:NSMeasurementFormatterUnitOptionsNaturalScale];
    NSMeasurement *small =
        [[NSMeasurement alloc] initWithDoubleValue:0.02
                                             unit:[NSUnitLength meters]];
    printf("[meas] small %s\n",
           [[formatter stringFromMeasurement:small] UTF8String]);
    NSMeasurement *grams =
        [[NSMeasurement alloc] initWithDoubleValue:500.0
                                             unit:[NSUnitMass grams]];
    printf("[meas] grams %s\n",
           [[formatter stringFromMeasurement:grams] UTF8String]);
    printf("[meas] done\n");
    fflush(0);
    return 0;
}
