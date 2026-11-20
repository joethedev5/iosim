#ifndef IOSIM_COREGRAPHICS_LITE_H
#define IOSIM_COREGRAPHICS_LITE_H

#include "objc_lite.h"

typedef struct CGContext *CGContextRef;
typedef void *CGColorRef;
typedef const void *CGPathRef;
typedef struct CGImage *CGImageRef;

typedef enum CGPathElementType {
    kCGPathElementMoveToPoint,
    kCGPathElementAddLineToPoint,
    kCGPathElementAddQuadCurveToPoint,
    kCGPathElementAddCurveToPoint,
    kCGPathElementCloseSubpath
} CGPathElementType;

typedef struct CGPathElement {
    CGPathElementType type;
    CGPoint *points;
} CGPathElement;

typedef void (*CGPathApplierFunction)(void *info,
                                      const CGPathElement *element);

/* Direct framebuffer context used by the UIView drawRect: bridge. The
 * context's origin is in device pixels; drawing coordinates are points. */
CGContextRef iosim_cg_begin_view(int x, int y, int w, int h, double scale,
                                 double alpha);
void iosim_cg_end_view(CGContextRef context);
CGContextRef iosim_cg_current(void);
CGContextRef iosim_cg_swap_current(CGContextRef context);
void *iosim_cg_push_context(CGContextRef context);
void iosim_cg_pop_context(void *token);
CGContextRef iosim_cg_begin_image(int w, int h, double scale);
int iosim_cg_image_data(CGContextRef context, unsigned char **out_rgba,
                        int *out_w, int *out_h);
void iosim_cg_end_image(CGContextRef context);
void iosim_cg_draw_image(CGContextRef context, const unsigned char *rgba,
                         int w, int h, CGRect rect);

void CGContextSetRGBFillColor(CGContextRef context, double r, double g,
                              double b, double a);
void CGContextSetRGBStrokeColor(CGContextRef context, double r, double g,
                                double b, double a);
void CGContextSetFillColorWithColor(CGContextRef context, CGColorRef color);
void CGContextSetStrokeColorWithColor(CGContextRef context, CGColorRef color);
void CGContextSetLineWidth(CGContextRef context, double width);
void CGContextSetAlpha(CGContextRef context, double alpha);
void CGContextFillRect(CGContextRef context, CGRect rect);
void CGContextStrokeRect(CGContextRef context, CGRect rect);
void CGContextFillEllipseInRect(CGContextRef context, CGRect rect);
void CGContextStrokeEllipseInRect(CGContextRef context, CGRect rect);
void CGContextClearRect(CGContextRef context, CGRect rect);
void CGContextBeginPath(CGContextRef context);
void CGContextMoveToPoint(CGContextRef context, double x, double y);
void CGContextAddLineToPoint(CGContextRef context, double x, double y);
void CGContextAddRect(CGContextRef context, CGRect rect);
void CGContextAddEllipseInRect(CGContextRef context, CGRect rect);
void CGContextAddPath(CGContextRef context, CGPathRef path);
void CGContextClosePath(CGContextRef context);void CGContextClip(CGContextRef context);
void CGContextClipToRect(CGContextRef context, CGRect rect);
void CGContextResetClip(CGContextRef context);
void CGContextFillPath(CGContextRef context);
void CGContextStrokePath(CGContextRef context);
void CGContextSaveGState(CGContextRef context);
void CGContextRestoreGState(CGContextRef context);
void CGContextTranslateCTM(CGContextRef context, double tx, double ty);
void CGContextScaleCTM(CGContextRef context, double sx, double sy);
void iosim_cg_draw_text(CGContextRef context, const char *text, double x,
                        double baseline, double size_pt, int bold,
                        unsigned color);
double iosim_cg_text_width(CGContextRef context, const char *text,
                           double size_pt, int bold);

CGColorRef CGColorCreateGenericRGB(double r, double g, double b, double a);
CGColorRef CGColorRetain(CGColorRef color);
void CGColorRelease(CGColorRef color);
const double *CGColorGetComponents(CGColorRef color);
double CGColorGetAlpha(CGColorRef color);
int CGColorEqualToColor(CGColorRef a, CGColorRef b);
int iosim_cgcolor_is_valid(const void *color);

CGPathRef CGPathCreateMutable(void);
CGPathRef CGPathRetain(CGPathRef path);
void CGPathRelease(CGPathRef path);
void CGPathMoveToPoint(CGPathRef path, const void *transform, double x,
                       double y);
void CGPathAddLineToPoint(CGPathRef path, const void *transform, double x,
                          double y);
void CGPathAddRect(CGPathRef path, const void *transform, CGRect rect);
void CGPathAddEllipseInRect(CGPathRef path, const void *transform, CGRect rect);
void CGPathCloseSubpath(CGPathRef path);
void CGPathAddPath(CGPathRef path, const void *transform, CGPathRef other);
void CGPathApply(CGPathRef path, void *info, CGPathApplierFunction function);
int iosim_cgpath_is_valid(const void *path);

CGImageRef CGImageCreateWithRGBA(const unsigned char *rgba, int w, int h);
CGImageRef CGImageRetain(CGImageRef image);
void CGImageRelease(CGImageRef image);
int CGImageGetWidth(CGImageRef image);
int CGImageGetHeight(CGImageRef image);
const unsigned char *iosim_cgimage_data(CGImageRef image, int *out_w,
                                        int *out_h);
int iosim_cgimage_is_valid(const void *image);
void CGContextDrawImage(CGContextRef context, CGRect rect, CGImageRef image);

#endif
