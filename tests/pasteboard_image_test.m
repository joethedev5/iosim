/* Pasteboard images: PNG data decodes into UIImage and survives a
 * setImage:/image round trip as public.png data. */
#include "UIKitStub.h"
extern int printf(const char *fmt, ...);
extern int fflush(void *stream);

int main(void)
{
    @autoreleasepool
    {
        NSData *png = [NSData dataWithContentsOfFile:@"demo/Assets/badge.png"];
        printf("[pbimg] bytes %lu\n", [png length]);
        UIImage *image = [UIImage imageWithData:png];
        printf("[pbimg] decode %d %d %d\n", image != nil,
               [image width], [image height]);
        UIPasteboard *board = [UIPasteboard generalPasteboard];
        [board setImage:image];
        UIImage *read = [board image];
        printf("[pbimg] image %d %d %d %d\n", read != nil,
               [read width], [read height], [board hasImages]);
        [board setImages:@[image, image]];
        printf("[pbimg] images %lu %d\n",
               (unsigned long)[[board images] count],
               [board containsPasteboardTypes:@[@"public.png"]]);
        fflush(0);
    }
    return 0;
}
