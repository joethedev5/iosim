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

static int image_pixel(unsigned char *rgba, int width, int x, int y,
                       int r, int g, int b)
{
    unsigned char *p = rgba + (y * width + x) * 4;
    return p[0] == r && p[1] == g && p[2] == b;
}

static int g_element_count;

static double g_points[256][2];
static int g_point_count;

static void count_element(void *info, const CGPathElement *element)
{
    (void)info;
    (void)element;
    g_element_count++;
}

static void collect_curve_point(void *info, const CGPathElement *element)
{
    (void)info;
    if (element->type != kCGPathElementMoveToPoint &&
        element->type != kCGPathElementAddLineToPoint)
        return;
    if (g_point_count >= 256)
        return;
    g_points[g_point_count][0] = element->points[0].x;
    g_points[g_point_count][1] = element->points[0].y;
    g_point_count++;
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

    /* Dash pattern: 10 on, 10 off, width 6. */
    CGContextSetRGBStrokeColor(context, 1, 1, 1, 1);
    CGContextSetLineWidth(context, 6);
    CGContextSetLineCap(context, 0);
    CGContextSetLineJoin(context, 0);
    double dash[2] = { 10, 10 };
    CGContextSetLineDash(context, 0, dash, 2);
    CGContextBeginPath(context);
    CGContextMoveToPoint(context, 10, 225);
    CGContextAddLineToPoint(context, 90, 225);
    CGContextStrokePath(context);
    CGContextSetLineDash(context, 0, 0, 0);

    /* Square cap extends the line by half its width; butt does not. */
    CGContextSetRGBStrokeColor(context, 1, 0, 0, 1);
    CGContextSetLineWidth(context, 8);
    CGContextSetLineCap(context, 2);
    CGContextBeginPath(context);
    CGContextMoveToPoint(context, 40, 205);
    CGContextAddLineToPoint(context, 90, 205);
    CGContextStrokePath(context);
    CGContextSetRGBStrokeColor(context, 0, 1, 0, 1);
    CGContextSetLineCap(context, 0);
    CGContextBeginPath(context);
    CGContextMoveToPoint(context, 40, 215);
    CGContextAddLineToPoint(context, 90, 215);
    CGContextStrokePath(context);

    /* A miter join fills the outer corner square; bevel clips it. */
    CGContextSetRGBStrokeColor(context, 1, 1, 1, 1);
    CGContextSetLineWidth(context, 10);
    CGContextSetLineJoin(context, 0);
    CGContextBeginPath(context);
    CGContextMoveToPoint(context, 60, 265);
    CGContextAddLineToPoint(context, 90, 265);
    CGContextAddLineToPoint(context, 90, 295);
    CGContextStrokePath(context);
    CGContextSetLineJoin(context, 2);
    CGContextBeginPath(context);
    CGContextMoveToPoint(context, 160, 265);
    CGContextAddLineToPoint(context, 190, 265);
    CGContextAddLineToPoint(context, 190, 295);
    CGContextStrokePath(context);

    printf("[cg] lineprops %d %d\n", CGContextGetLineCap(context),
           CGContextGetLineJoin(context));
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
    g_point_count = 0;
    CGPathApply(curve_path, 0, collect_curve_point);
    double worst = 0;
    for (int s = 0; s <= 200; s++)
    {
        double t = (double)s / 200.0, u = 1.0 - t;
        double px = u * u * u * 10 + 3 * u * u * t * 30 +
                    3 * u * t * t * 70 + t * t * t * 90;
        double py = u * u * u * 10 + 0 + 3 * u * t * t * 60 +
                    t * t * t * 10;
        double best = 1e9;
        for (int i = 0; i + 1 < g_point_count; i++)
        {
            double ax = g_points[i][0], ay = g_points[i][1];
            double bx = g_points[i + 1][0], by = g_points[i + 1][1];
            double dx = bx - ax, dy = by - ay;
            double len2 = dx * dx + dy * dy;
            double f = len2 > 0 ? ((px - ax) * dx + (py - ay) * dy) / len2
                                : 0;
            if (f < 0) f = 0;
            if (f > 1) f = 1;
            double qx = ax + f * dx - px, qy = ay + f * dy - py;
            double d = __builtin_sqrt(qx * qx + qy * qy);
            if (d < best)
                best = d;
        }
        if (best > worst)
            worst = best;
    }
    printf("[cg] curve error %d\n",
           worst <= IOSIM_CG_FLATTEN_TOLERANCE + 0.01);
    CGPathRelease(curve_path);
    CGPathRef quad_path = CGPathCreateMutable();
    CGPathMoveToPoint(quad_path, 0, 10, 10);
    CGPathAddQuadCurveToPoint(quad_path, 0, 50, 0, 90, 10);
    g_element_count = 0;
    CGPathApply(quad_path, 0, count_element);
    printf("[cg] quad elements %d\n", g_element_count);
    CGPathRelease(quad_path);
    CGPathRef gentle_path = CGPathCreateMutable();
    CGPathMoveToPoint(gentle_path, 0, 0, 0);
    CGPathAddQuadCurveToPoint(gentle_path, 0, 10, 10, 20, 20);
    g_element_count = 0;
    CGPathApply(gentle_path, 0, count_element);
    printf("[cg] curve gentle %d\n", g_element_count);
    CGPathRelease(gentle_path);
    CGPathRef sharp_path = CGPathCreateMutable();
    CGPathMoveToPoint(sharp_path, 0, 0, 0);
    CGPathAddCurveToPoint(sharp_path, 0, 0, 300, 300, -300, 300, 0);
    g_element_count = 0;
    CGPathApply(sharp_path, 0, count_element);
    printf("[cg] curve sharp %d\n", g_element_count);
    CGPathRelease(sharp_path);

    unsigned pixels[300 * 300];
    iosim_fb_capture(0, 0, 300, 300, pixels);
    printf("[cg] rect %06x\n", pixel(pixels, 50, 50));
    printf("[cg] ellipse %06x\n", pixel(pixels, 180, 30));
    printf("[cg] stroke %06x\n", pixel(pixels, 80, 100));
    printf("[cg] dash on %06x\n", pixel(pixels, 15, 226));
    printf("[cg] dash off %06x\n", pixel(pixels, 25, 226));
    printf("[cg] cap square %06x\n", pixel(pixels, 37, 205));
    printf("[cg] cap butt %06x\n", pixel(pixels, 37, 215));
    printf("[cg] join miter %06x\n", pixel(pixels, 93, 262));
    printf("[cg] join bevel %06x\n", pixel(pixels, 193, 262));
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

    CGColorSpaceRef gradient_space = CGColorSpaceCreateDeviceRGB();
    double gradient_components[8] = { 1, 0, 0, 1, 0, 0, 1, 1 };
    double gradient_locations[2] = { 0, 1 };
    CGGradientRef gradient = CGGradientCreateWithColorComponents(
        gradient_space, gradient_components, gradient_locations, 2);
    CGContextRef gradient_context = iosim_cg_begin_image(100, 20, 1.0);
    CGContextDrawLinearGradient(gradient_context, gradient,
                                CGPointMake(0, 0), CGPointMake(100, 0), 0);
    unsigned char *gradient_rgba = 0;
    int gradient_w = 0, gradient_h = 0;
    iosim_cg_image_data(gradient_context, &gradient_rgba, &gradient_w,
                        &gradient_h);
    unsigned char *left = gradient_rgba + (0 * gradient_w + 0) * 4;
    unsigned char *middle = gradient_rgba + (0 * gradient_w + 50) * 4;
    printf("[cg] gradient %d %d\n",
           left[0] > 240 && left[2] < 15,
           middle[0] > 110 && middle[0] < 145 &&
               middle[2] > 110 && middle[2] < 145);
    iosim_cg_end_image(gradient_context);
    CGGradientRelease(gradient);

    double fade_components[8] = { 1, 0, 0, 1, 1, 0, 0, 0 };
    CGGradientRef fade = CGGradientCreateWithColorComponents(
        gradient_space, fade_components, gradient_locations, 2);
    CGContextRef fade_context = iosim_cg_begin_image(100, 20, 1.0);
    CGContextSetRGBFillColor(fade_context, 1, 1, 1, 1);
    CGContextFillRect(fade_context, CGRectMake(0, 0, 100, 20));
    CGContextDrawLinearGradient(fade_context, fade,
                                CGPointMake(0, 0), CGPointMake(100, 0), 0);
    unsigned char *fade_rgba = 0;
    int fade_w = 0, fade_h = 0;
    iosim_cg_image_data(fade_context, &fade_rgba, &fade_w, &fade_h);
    unsigned char *fade_left = fade_rgba + (0 * fade_w + 0) * 4;
    unsigned char *fade_right = fade_rgba + (0 * fade_w + 95) * 4;
    printf("[cg] gradient fade %d %d\n",
           fade_left[0] > 240 && fade_left[1] < 15 &&
               fade_left[2] < 15,
           fade_right[0] > 230 && fade_right[1] > 230 &&
               fade_right[2] > 230);
    iosim_cg_end_image(fade_context);
    CGGradientRelease(fade);
    CGColorSpaceRelease(gradient_space);

    /* A right half-disc from the top of the circle to the bottom through
     * +x; the left half and the top edge stay unpainted. */
    CGContextRef arc_context = iosim_cg_begin_image(120, 120, 1.0);
    CGContextSetRGBFillColor(arc_context, 1, 0, 0, 1);
    CGContextBeginPath(arc_context);
    CGContextMoveToPoint(arc_context, 60, 60);
    CGContextAddArc(arc_context, 60, 60, 40, -1.5707963267948966,
                    1.5707963267948966, 1);
    CGContextClosePath(arc_context);
    CGContextFillPath(arc_context);
    unsigned char *arc_rgba = 0;
    int arc_w = 0, arc_h = 0;
    iosim_cg_image_data(arc_context, &arc_rgba, &arc_w, &arc_h);
    printf("[cg] arc fill %d %d %d\n",
           image_pixel(arc_rgba, arc_w, 90, 60, 255, 0, 0),
           image_pixel(arc_rgba, arc_w, 20, 60, 255, 0, 0),
           image_pixel(arc_rgba, arc_w, 60, 15, 255, 0, 0));
    iosim_cg_end_image(arc_context);

    /* A 10 pt rounded corner at (100,20): the sharp corner is cut while
     * the arc-side interior remains filled. */
    CGContextRef corner_context = iosim_cg_begin_image(120, 120, 1.0);
    CGContextSetRGBFillColor(corner_context, 0, 0, 1, 1);
    CGContextBeginPath(corner_context);
    CGContextMoveToPoint(corner_context, 20, 20);
    CGContextAddLineToPoint(corner_context, 80, 20);
    CGContextAddArcToPoint(corner_context, 100, 20, 100, 40, 10);
    CGContextAddLineToPoint(corner_context, 100, 80);
    CGContextAddLineToPoint(corner_context, 20, 80);
    CGContextClosePath(corner_context);
    CGContextFillPath(corner_context);
    unsigned char *corner_rgba = 0;
    int corner_w = 0, corner_h = 0;
    iosim_cg_image_data(corner_context, &corner_rgba, &corner_w, &corner_h);
    printf("[cg] arcto fill %d %d %d\n",
           image_pixel(corner_rgba, corner_w, 50, 50, 0, 0, 255),
           image_pixel(corner_rgba, corner_w, 85, 25, 0, 0, 255),
           image_pixel(corner_rgba, corner_w, 98, 22, 0, 0, 255));
    iosim_cg_end_image(corner_context);

    /* CGPathAddArc uses the same angles and fill rule as the context. */
    CGPathRef bottom_arc = CGPathCreateMutable();
    CGPathAddArc(bottom_arc, 0, 50, 50, 30, 0, 3.1415926535897932, 1);
    CGRect arc_box = CGPathGetBoundingBox(bottom_arc);
    printf("[cg] path arc %d %d bbox %.0f %.0f %.0f %.0f\n",
           CGPathContainsPoint(bottom_arc, 0, CGPointMake(50, 70), 0),
           CGPathContainsPoint(bottom_arc, 0, CGPointMake(50, 30), 0),
           arc_box.origin.x, arc_box.origin.y,
           arc_box.size.width, arc_box.size.height);
    CGPathRelease(bottom_arc);

    CGPathRef rounded_path = CGPathCreateMutable();
    CGPathMoveToPoint(rounded_path, 0, 20, 20);
    CGPathAddLineToPoint(rounded_path, 0, 80, 20);
    CGPathAddArcToPoint(rounded_path, 0, 100, 20, 100, 40, 10);
    CGPathAddLineToPoint(rounded_path, 0, 100, 80);
    CGPathAddLineToPoint(rounded_path, 0, 20, 80);
    CGPathCloseSubpath(rounded_path);
    printf("[cg] path arcto %d %d\n",
           CGPathContainsPoint(rounded_path, 0, CGPointMake(50, 50), 0),
           CGPathContainsPoint(rounded_path, 0, CGPointMake(98, 22), 0));
    CGPathRelease(rounded_path);

    /* UIBezierPath honors clockwise: YES for the short bottom-right
     * quadrant and NO for the long way around it. */
    UIBezierPath *arc_cw = [UIBezierPath bezierPath];
    [arc_cw addArcWithCenter:CGPointMake(50, 50) radius:30 startAngle:0
                    endAngle:1.5707963267948966 clockwise:YES];
    UIBezierPath *arc_ccw = [UIBezierPath bezierPath];
    [arc_ccw addArcWithCenter:CGPointMake(50, 50) radius:30 startAngle:0
                     endAngle:1.5707963267948966 clockwise:NO];
    printf("[cg] ui arc cw %d %d\n",
           CGPathContainsPoint([arc_cw CGPath], 0, CGPointMake(65, 72), 0),
           CGPathContainsPoint([arc_cw CGPath], 0, CGPointMake(72, 55), 0));
    printf("[cg] ui arc ccw %d %d\n",
           CGPathContainsPoint([arc_ccw CGPath], 0, CGPointMake(55, 55), 0),
           CGPathContainsPoint([arc_ccw CGPath], 0, CGPointMake(70, 70), 0));
    return 0;
}
