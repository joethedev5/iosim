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
    int cgpath_elements = g_element_count;
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

    unsigned char cg_pixels[2 * 2 * 4];
    for (int i = 0; i < 4; i++)
    {
        cg_pixels[i * 4 + 0] = 255;
        cg_pixels[i * 4 + 1] = 255;
        cg_pixels[i * 4 + 2] = 0;
        cg_pixels[i * 4 + 3] = 255;
    }
    CGImageRef cg_image = CGImageCreateWithRGBA(cg_pixels, 2, 2);
    printf("[cg] cgimage %d %d valid %d\n", CGImageGetWidth(cg_image),
           CGImageGetHeight(cg_image), iosim_cgimage_is_valid(cg_image));
    CGContextDrawImage(context, CGRectMake(180, 150, 40, 40), cg_image);
    CGImageRelease(cg_image);

    CGContextSaveGState(context);
    CGContextClipToRect(context, CGRectMake(240, 10, 50, 40));
    CGContextSetRGBFillColor(context, 0, 1, 0, 1);
    CGContextFillRect(context, CGRectMake(0, 0, 300, 300));
    CGContextRestoreGState(context);
    CGContextSetRGBFillColor(context, 0, 0, 1, 1);
    CGContextFillRect(context, CGRectMake(240, 220, 40, 40));

    CGContextSaveGState(context);
    CGContextBeginPath(context);
    CGContextMoveToPoint(context, 30, 250);
    CGContextAddLineToPoint(context, 90, 250);
    CGContextAddLineToPoint(context, 60, 290);
    CGContextClosePath(context);
    CGContextClip(context);
    CGContextSetRGBFillColor(context, 0, 1, 0, 1);
    CGContextFillRect(context, CGRectMake(0, 0, 300, 300));
    CGContextRestoreGState(context);
    iosim_cg_end_view(context);

    CGColorSpaceRef rgb_space = CGColorSpaceCreateDeviceRGB();
    CGColorSpaceRef gray_space = CGColorSpaceCreateDeviceGray();
    double components[4] = { 0.25, 0.5, 0.75, 1.0 };
    CGColorRef space_color = CGColorCreate(rgb_space, components);
    printf("[cg] colorspace rgb=%d gray=%d color=%d comps %.2f %.2f %.2f "
           "alpha %.2f same=%d\n",
           CGColorSpaceGetModel(rgb_space), CGColorSpaceGetModel(gray_space),
           CGColorSpaceGetModel(CGColorGetColorSpace(space_color)),
           CGColorGetComponents(space_color)[0],
           CGColorGetComponents(space_color)[1],
           CGColorGetComponents(space_color)[2],
           CGColorGetAlpha(space_color),
           CGColorGetColorSpace(space_color) == rgb_space);
    CGColorRelease(space_color);
    CGColorSpaceRelease(rgb_space);
    CGColorSpaceRelease(gray_space);

    CGPathRef rect_path = CGPathCreateWithRect(CGRectMake(10, 10, 20, 20), 0);
    CGRect box = CGPathGetBoundingBox(rect_path);
    printf("[cg] pathbox %.0f %.0f %.0f %.0f inside=%d outside=%d\n",
           box.origin.x, box.origin.y, box.size.width, box.size.height,
           CGPathContainsPoint(rect_path, 0, CGPointMake(15, 15), 0),
           CGPathContainsPoint(rect_path, 0, CGPointMake(100, 100), 0));
    CGPathRef path_copy = CGPathCreateCopy(rect_path);
    printf("[cg] pathcopy inside=%d\n",
           CGPathContainsPoint(path_copy, 0, CGPointMake(20, 20), 0));
    CGPathRelease(path_copy);
    CGPathRelease(rect_path);

    CGPathRef curve_path = CGPathCreateMutable();
    CGPathMoveToPoint(curve_path, 0, 10, 10);
    CGPathAddCurveToPoint(curve_path, 0, 30, 0, 70, 60, 90, 10);
    g_element_count = 0;
    CGPathApply(curve_path, 0, count_element);
    printf("[cg] curve elements %d\n", g_element_count);
    CGPathRelease(curve_path);
    CGPathRef quad_path = CGPathCreateMutable();
    CGPathMoveToPoint(quad_path, 0, 10, 10);
    CGPathAddQuadCurveToPoint(quad_path, 0, 50, 0, 90, 10);
    g_element_count = 0;
    CGPathApply(quad_path, 0, count_element);
    printf("[cg] quad elements %d\n", g_element_count);
    CGPathRelease(quad_path);

    unsigned pixels[300 * 300];
    iosim_fb_capture(0, 0, 300, 300, pixels);
    printf("[cg] rect %06x\n", pixel(pixels, 50, 50));
    printf("[cg] ellipse %06x\n", pixel(pixels, 180, 30));
    printf("[cg] stroke %06x\n", pixel(pixels, 80, 100));
    printf("[cg] path %06x\n", pixel(pixels, 35, 170));
    printf("[cg] translate %06x\n", pixel(pixels, 15, 15));
    printf("[cg] cgpath %06x\n", pixel(pixels, 120, 240));
    printf("[cg] cgpath elements %d\n", cgpath_elements);
    printf("[cg] released %d\n", iosim_cgpath_is_valid(path));
    printf("[cg] uicolor %06x\n", pixel(pixels, 200, 240));
    printf("[cg] cgimage draw %06x\n", pixel(pixels, 190, 160));
    printf("[cg] clip %06x\n", pixel(pixels, 260, 30));
    printf("[cg] clip outside %06x\n", pixel(pixels, 50, 50));
    printf("[cg] clip restored %06x\n", pixel(pixels, 250, 240));
    printf("[cg] clip path inside %06x outside %06x\n",
           pixel(pixels, 60, 270), pixel(pixels, 50, 50));
    return 0;
}
