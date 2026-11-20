/* CoreGraphics-lite: fills, strokes, ellipses, paths, transforms and
 * framebuffer capture, independent of the UIView bridge. */
#include "UIKitStub.h"

extern int printf(const char *fmt, ...);
extern int iosim_fb_begin(unsigned width, unsigned height);
extern void iosim_fb_capture(int x, int y, int w, int h, unsigned *out);

static unsigned pixel(unsigned *pixels, int x, int y)
{
    return pixels[y * 300 + x] & 0xffffff;
}

int main(void)
{
    iosim_fb_begin(300, 300);
    CGContextRef context = iosim_cg_begin_view(0, 0, 300, 300, 1.0, 1.0);
    CGContextSetRGBFillColor(context, 1, 0, 0, 1);
    CGContextFillRect(context, CGRectMake(10, 10, 50, 50));

    CGContextSetRGBFillColor(context, 0, 1, 0, 1);
    CGContextFillEllipseInRect(context, CGRectMake(150, 10, 60, 40));

    CGContextSetRGBStrokeColor(context, 0, 0, 1, 1);
    CGContextSetLineWidth(context, 2);
    CGContextStrokeRect(context, CGRectMake(80, 80, 40, 40));

    CGContextSetRGBFillColor(context, 1, 1, 0, 1);
    CGContextBeginPath(context);
    CGContextMoveToPoint(context, 10, 150);
    CGContextAddLineToPoint(context, 60, 150);
    CGContextAddLineToPoint(context, 35, 200);
    CGContextClosePath(context);
    CGContextFillPath(context);

    CGContextSaveGState(context);
    CGContextTranslateCTM(context, 10, 10);
    CGContextSetRGBFillColor(context, 0, 0, 1, 1);
    CGContextFillRect(context, CGRectMake(0, 0, 20, 20));
    CGContextRestoreGState(context);
    iosim_cg_end_view(context);

    unsigned pixels[300 * 300];
    iosim_fb_capture(0, 0, 300, 300, pixels);
    printf("[cg] rect %06x\n", pixel(pixels, 50, 50));
    printf("[cg] ellipse %06x\n", pixel(pixels, 180, 30));
    printf("[cg] stroke %06x\n", pixel(pixels, 80, 100));
    printf("[cg] path %06x\n", pixel(pixels, 35, 170));
    printf("[cg] translate %06x\n", pixel(pixels, 15, 15));
    return 0;
}
