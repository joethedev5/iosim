#include "framebuffer.h"
#include <stdio.h>
#include <stdlib.h>

int main(void)
{
    const char *strings[] = {
        "Hello from iOS", "Same source. Two runtimes.", "Mach-O loader: OK",
        "chained fixups: OK", "objc_msgSend: OK", "UIKit.framework: OK",
        "Continue", "iosim x86_64", "9:41",
        "ABCDEFGHIJKLMNOPQRSTUVWXYZ", "abcdefghijklmnopqrstuvwxyz",
        "0123456789"
    };
    iosim_fb_begin(64, 64);
    for (int size = 8; size <= 96; size++)
        for (int bold = 0; bold < 2; bold++)
        {
            int style = bold ? IOSIM_FONT_BOLD : IOSIM_FONT_REGULAR;
            for (int i = 0; i < 12; i++)
                printf("U %d %d\t%s\t%d\n", size, bold, strings[i],
                       iosim_fb_font_text_width_untracked(strings[i], style,
                                                          size, 3.0));
        }
    return 0;
}
