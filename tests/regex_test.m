/* NSRegularExpression: capture groups, match ranges, case-insensitive
 * matching and template replacement through the loader's regex shim. */
#include "foundation_lite.h"

extern int printf(const char *fmt, ...);

int main(void)
{
    NSString *text = @"abc 123 xyz 45";
    NSRegularExpression *re = [NSRegularExpression
        regularExpressionWithPattern:@"([A-Za-z]+) (\\d+)"
                             options:0
                               error:0];
    NSArray *matches = [re matchesInString:text
                                   options:0
                                     range:NSMakeRange(0, [text length])];
    printf("[regex] matches=%lu groups=%lu\n", [matches count],
           [re numberOfCaptureGroups]);
    NSTextCheckingResult *first = [matches objectAtIndex:0];
    NSRange whole = [first range];
    NSRange word = [first rangeAtIndex:1];
    NSRange numberRange = [first rangeAtIndex:2];
    printf("[regex] first %lu %lu %s %s\n", whole.location, whole.length,
           [[text substringWithRange:word] UTF8String],
           [[text substringWithRange:numberRange] UTF8String]);
    NSTextCheckingResult *second = [matches objectAtIndex:1];
    NSRange secondWord = [second rangeAtIndex:1];
    printf("[regex] second %s\n",
           [[text substringWithRange:secondWord] UTF8String]);

    NSRegularExpression *digits =
        [NSRegularExpression regularExpressionWithPattern:@"\\d+"
                                                   options:0
                                                     error:0];
    matches = [digits matchesInString:@"a1 b22 c333"
                              options:0
                                range:NSMakeRange(0, 11)];
    NSTextCheckingResult *third = [matches objectAtIndex:2];
    NSRange thirdRange = [third range];
    printf("[regex] digits=%lu third=%lu,%lu\n", [matches count],
           thirdRange.location, thirdRange.length);

    NSRegularExpression *folded =
        [NSRegularExpression regularExpressionWithPattern:@"abc"
                                                   options:
            NSRegularExpressionCaseInsensitive
                                                     error:0];
    printf("[regex] ci=%lu\n",
           [[folded matchesInString:@"ABC"
                            options:0
                              range:NSMakeRange(0, 3)] count]);

    NSRegularExpression *numberPattern =
        [NSRegularExpression regularExpressionWithPattern:@"([0-9]+)"
                                                   options:0
                                                     error:0];
    NSString *replaced = [numberPattern
        stringByReplacingMatchesInString:@"a1b22"
                                 options:0
                                   range:NSMakeRange(0, 5)
                            withTemplate:@"<$1>"];
    printf("[regex] replace=%s\n", [replaced UTF8String]);
    return 0;
}
