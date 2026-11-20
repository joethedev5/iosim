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

    CGImageRef red_cg = [red CGImage];
    UIImage *from_cg = [UIImage imageWithCGImage:red_cg];
    printf("[uig] cgimage %d %d ", from_cg->_width, from_cg->_height);
    pixel(from_cg, 10, 10);
    printf("\n");
    CGImageRelease(red_cg);

    UIGraphicsBeginImageContextWithOptions(CGSizeMake(10, 10), NO, 1.0);
    CGContextRef outer = UIGraphicsGetCurrentContext();
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(5, 5), NO, 1.0);
    CGContextRef inner = UIGraphicsGetCurrentContext();
    UIGraphicsEndImageContext();
    printf("[uig] restored %d\n", UIGraphicsGetCurrentContext() == outer);

    UIGraphicsBeginImageContextWithOptions(CGSizeMake(5, 5), NO, 1.0);
    inner = UIGraphicsGetCurrentContext();
    UIGraphicsPushContext(outer);
    printf("[uig] pushed %d\n", UIGraphicsGetCurrentContext() == outer);
    CGContextSetRGBFillColor(UIGraphicsGetCurrentContext(), 1, 0, 0, 1);
    CGContextFillRect(UIGraphicsGetCurrentContext(),
                      CGRectMake(0, 0, 10, 10));
    UIImage *pushed = UIGraphicsGetImageFromCurrentImageContext();
    printf("[uig] pushed image ");
    pixel(pushed, 5, 5);
    printf("\n");
    UIGraphicsPopContext();
    printf("[uig] popped %d\n", UIGraphicsGetCurrentContext() == inner);
    UIGraphicsEndImageContext();
    UIGraphicsEndImageContext();
    return 0;
}
