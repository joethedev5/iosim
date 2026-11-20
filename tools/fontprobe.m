/* Runs inside the simulator (simctl spawn) and reports the metrics UIFont
 * actually uses. The output calibrates the iosim FreeType text stack. */
#import <UIKit/UIKit.h>
#import <CoreText/CoreText.h>
#include <stdio.h>

int main(void)
{
    @autoreleasepool
    {
        NSArray *strings = @[
            @"Hello from iOS",
            @"Same source. Two runtimes.",
            @"Mach-O loader: OK",
            @"chained fixups: OK",
            @"objc_msgSend: OK",
            @"UIKit.framework: OK",
            @"Continue",
            @"iosim x86_64",
            @"9:41",
            @"ABCDEFGHIJKLMNOPQRSTUVWXYZ",
            @"abcdefghijklmnopqrstuvwxyz",
            @"0123456789",
        ];
        for (int size = 8; size <= 96; size++)
        {
            for (int bold = 0; bold < 2; bold++)
            {
                UIFont *font = bold ? [UIFont boldSystemFontOfSize:size]
                                    : [UIFont systemFontOfSize:size];
                printf("F %d %d %s %s %.6f %.6f %.6f %.6f %.6f %.6f %.6f\n",
                       size, bold, [[font fontName] UTF8String],
                       [[font familyName] UTF8String],
                       font.ascender, font.descender, font.leading,
                       font.lineHeight, font.capHeight, font.xHeight,
                       font.pointSize);
                for (NSString *s in strings)
                {
                    CGSize sz = [s sizeWithAttributes:@{NSFontAttributeName: font}];
                    printf("W %d %d %s\t%.6f\t%.6f\n", size, bold,
                           [s UTF8String], sz.width, sz.height);
                }
            }
        }
        fflush(stdout);
    }
    return 0;
}
