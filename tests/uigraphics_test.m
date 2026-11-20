/* UIGraphics image contexts: offscreen fill, image extraction and drawing a
 * UIImage back into a second context. */
#include "UIKitStub.h"

extern int printf(const char *fmt, ...);

static void pixel(UIImage *image, int x, int y)
{
    unsigned char *p = image->_rgba + ((unsigned long)y * image->_width + x) * 4;
    printf("%d %d %d %d", p[0], p[1], p[2], p[3]);
}

int main(void)
{
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(10, 10), NO, 2.0);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetRGBFillColor(context, 1, 0, 0, 1);
    CGContextFillRect(context, CGRectMake(0, 0, 10, 10));
    UIImage *red = UIGraphicsGetImageFromCurrentImageContext();
    printf("[uig] size %d %d red ", red->_width, red->_height);
    pixel(red, 10, 10);
    printf("\n");
    UIGraphicsEndImageContext();

    UIGraphicsBeginImageContextWithOptions(CGSizeMake(10, 10), NO, 1.0);
    context = UIGraphicsGetCurrentContext();
    CGContextSetRGBFillColor(context, 0, 0, 1, 1);
    CGContextFillRect(context, CGRectMake(0, 0, 10, 10));
    [red drawInRect:CGRectMake(0, 0, 10, 10)];
    UIImage *drawn = UIGraphicsGetImageFromCurrentImageContext();
    printf("[uig] drawn ");
    pixel(drawn, 5, 5);
    printf("\n");
    UIGraphicsEndImageContext();
    return 0;
}
