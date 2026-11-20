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

static int g_element_count;

static void count_element(void *info, const CGPathElement *element)
{
    (void)info;
    (void)element;
    g_element_count++;
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

    CGPathRef path = CGPathCreateMutable();
    CGPathAddRect(path, 0, CGRectMake(100, 220, 40, 40));
    CGPathApply(path, 0, count_element);
    CGContextSetRGBFillColor(context, 1, 0, 1, 1);
    CGContextBeginPath(context);
    CGContextAddPath(context, path);
    CGContextFillPath(context);
    CGPathRelease(path);

    UIColor *purple = [UIColor colorWithRed:0.5 green:0 blue:1 alpha:1];
    CGColorRef color = [purple CGColor];
    printf("[cg] cgcolor alpha %.2f equal %d red %.1f valid %d\n",
           CGColorGetAlpha(color), CGColorEqualToColor(color, color),
           CGColorGetComponents(color)[0], iosim_cgcolor_is_valid(color));
    CGContextSetFillColorWithColor(context, color);
    CGContextFillRect(context, CGRectMake(180, 220, 40, 40));
    CGColorRelease(color);

    CGContextSaveGState(context);
    CGContextClipToRect(context, CGRectMake(240, 10, 50, 40));
    CGContextSetRGBFillColor(context, 0, 1, 0, 1);
    CGContextFillRect(context, CGRectMake(0, 0, 300, 300));
    CGContextRestoreGState(context);
    CGContextSetRGBFillColor(context, 0, 0, 1, 1);
    CGContextFillRect(context, CGRectMake(240, 220, 40, 40));
    iosim_cg_end_view(context);

    unsigned pixels[300 * 300];
    iosim_fb_capture(0, 0, 300, 300, pixels);
    printf("[cg] rect %06x\n", pixel(pixels, 50, 50));
    printf("[cg] ellipse %06x\n", pixel(pixels, 180, 30));
    printf("[cg] stroke %06x\n", pixel(pixels, 80, 100));
    printf("[cg] path %06x\n", pixel(pixels, 35, 170));
    printf("[cg] translate %06x\n", pixel(pixels, 15, 15));
    printf("[cg] cgpath %06x\n", pixel(pixels, 120, 240));
    printf("[cg] cgpath elements %d\n", g_element_count);
    printf("[cg] released %d\n", iosim_cgpath_is_valid(path));
    printf("[cg] uicolor %06x\n", pixel(pixels, 200, 240));
    printf("[cg] clip %06x\n", pixel(pixels, 260, 30));
    printf("[cg] clip outside %06x\n", pixel(pixels, 50, 50));
    printf("[cg] clip restored %06x\n", pixel(pixels, 250, 240));
    return 0;
}
