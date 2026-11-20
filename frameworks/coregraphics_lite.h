#ifndef IOSIM_COREGRAPHICS_LITE_H
#define IOSIM_COREGRAPHICS_LITE_H

#include "objc_lite.h"

typedef struct CGContext *CGContextRef;
typedef void *CGColorRef;
typedef const void *CGPathRef;

/* Direct framebuffer context used by the UIView drawRect: bridge. The
 * context's origin is in device pixels; drawing coordinates are points. */
CGContextRef iosim_cg_begin_view(int x, int y, int w, int h, double scale,
                                 double alpha);
void iosim_cg_end_view(CGContextRef context);

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
void CGContextClosePath(CGContextRef context);
void CGContextFillPath(CGContextRef context);
void CGContextStrokePath(CGContextRef context);
void CGContextSaveGState(CGContextRef context);
void CGContextRestoreGState(CGContextRef context);
void CGContextTranslateCTM(CGContextRef context, double tx, double ty);
void CGContextScaleCTM(CGContextRef context, double sx, double sy);

CGColorRef CGColorCreateGenericRGB(double r, double g, double b, double a);
void CGColorRelease(CGColorRef color);

#endif
