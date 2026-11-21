/* Rich pasteboard values: multiple strings, URLs and colors stored as items
 * with their public type identifiers. */
#include "UIKitStub.h"
extern int printf(const char *fmt, ...);
extern int fflush(void *stream);

int main(void)
{
    @autoreleasepool
    {
        UIPasteboard *board = [UIPasteboard generalPasteboard];
        [board setStrings:@[@"one", @"two"]];
        printf("[pb] strings %lu %s %d\n", (unsigned long)[[board strings] count],
               [[[board strings] objectAtIndex:0] UTF8String],
               [board containsPasteboardTypes:
                   @[@"public.utf8-plain-text"]]);
        [board setURLs:@[[NSURL URLWithString:@"https://example.com/a"],
                         [NSURL URLWithString:@"https://example.com/b"]]];
        printf("[pb] urls %lu %s %d\n", (unsigned long)[[board URLs] count],
               [[[[board URLs] objectAtIndex:1] absoluteString] UTF8String],
               [board containsPasteboardTypes:@[@"public.url"]]);
        [board setColor:[UIColor colorWithRed:1.0 green:0.5 blue:0.25 alpha:0.75]];
        UIColor *color = [board color];
        double red = 0, green = 0, blue = 0, alpha = 0;
        [color getRed:&red green:&green blue:&blue alpha:&alpha];
        printf("[pb] color %.2f %.2f %.2f %.2f\n", red, green, blue, alpha);
        printf("[pb] types %lu %d\n", (unsigned long)[[board types] count],
               [board containsPasteboardTypes:
                   @[@"com.apple.uikit.color"]]);
        fflush(0);
    }
    return 0;
}
