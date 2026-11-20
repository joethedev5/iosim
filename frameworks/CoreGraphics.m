/* CoreGraphics-lite: a direct framebuffer CGContext used by UIView's
 * drawRect: bridge. Coordinates are points; the context translates them to
 * device pixels at the owning view's origin. */

#include "coregraphics_lite.h"

extern void *malloc(unsigned long size);
extern void *calloc(unsigned long n, unsigned long size);
extern void free(void *ptr);

extern void iosim_fb_fill_rect(int x, int y, int w, int h, unsigned color);
extern void iosim_fb_fill_ellipse(int cx, int cy, int rx, int ry,
                                  unsigned color);
extern void iosim_fb_draw_line(int x0, int y0, int x1, int y1, int thickness,
                               unsigned color);
extern void iosim_fb_fill_polygon(const double *xs, const double *ys,
                                  int count, unsigned color);
extern void iosim_fb_set_opacity(double opacity);

#define CG_MAX_POINTS 512
#define CG_MAX_STATES 8

struct CGColor {
    double r, g, b, a;
};

struct cg_state {
    double tx, ty;
    double sx, sy;
    double alpha;
    struct CGColor fill;
    struct CGColor stroke;
    double line_width;
};

struct CGContext {
    int x, y, w, h;
    double scale;
    double base_alpha;
    struct cg_state state;
    struct cg_state stack[CG_MAX_STATES];
    int depth;
    double xs[CG_MAX_POINTS];
    double ys[CG_MAX_POINTS];
    int count;
    int closed;
};

static CGContextRef g_current_context;

static double cg_clamp(double value)
{
    if (value < 0)
        return 0;
    if (value > 1)
        return 1;
    return value;
}

static unsigned cg_rgb(struct CGColor color)
{
    int r = (int)(cg_clamp(color.r) * 255.0 + 0.5);
    int g = (int)(cg_clamp(color.g) * 255.0 + 0.5);
    int b = (int)(cg_clamp(color.b) * 255.0 + 0.5);
    return ((unsigned)r << 16) | ((unsigned)g << 8) | (unsigned)b;
}

static void cg_apply_opacity(CGContextRef context, struct CGColor color)
{
    iosim_fb_set_opacity(context->base_alpha * context->state.alpha *
                         cg_clamp(color.a));
}

static void cg_transform(CGContextRef context, double x, double y,
                         double *px, double *py)
{
    *px = context->x +
          (x * context->state.sx + context->state.tx) * context->scale;
    *py = context->y +
          (y * context->state.sy + context->state.ty) * context->scale;
}

static int cg_thickness(CGContextRef context)
{
    int thickness = (int)(context->state.line_width * context->scale + 0.5);
    return thickness < 1 ? 1 : thickness;
}

CGContextRef iosim_cg_begin_view(int x, int y, int w, int h, double scale,
                                 double alpha)
{
    CGContextRef context = calloc(1, sizeof(*context));
    if (!context)
        return 0;
    context->x = x;
    context->y = y;
    context->w = w;
    context->h = h;
    context->scale = scale > 0 ? scale : 1.0;
    context->base_alpha = alpha;
    context->state.sx = 1;
    context->state.sy = 1;
    context->state.alpha = 1;
    context->state.fill.r = 0;
    context->state.fill.g = 0;
    context->state.fill.b = 0;
    context->state.fill.a = 1;
    context->state.stroke.r = 0;
    context->state.stroke.g = 0;
    context->state.stroke.b = 0;
    context->state.stroke.a = 1;
    context->state.line_width = 1.0;
    g_current_context = context;
    return context;
}

void iosim_cg_end_view(CGContextRef context)
{
    if (!context)
        return;
    if (g_current_context == context)
        g_current_context = 0;
    iosim_fb_set_opacity(1.0);
    free(context);
}

void CGContextSetRGBFillColor(CGContextRef context, double r, double g,
                              double b, double a)
{
    if (!context)
        context = g_current_context;
    if (!context)
        return;
    context->state.fill.r = r;
    context->state.fill.g = g;
    context->state.fill.b = b;
    context->state.fill.a = a;
}

void CGContextSetRGBStrokeColor(CGContextRef context, double r, double g,
                                double b, double a)
{
    if (!context)
        context = g_current_context;
    if (!context)
        return;
    context->state.stroke.r = r;
    context->state.stroke.g = g;
    context->state.stroke.b = b;
    context->state.stroke.a = a;
}

void CGContextSetFillColorWithColor(CGContextRef context, CGColorRef color)
{
    struct CGColor *value = (struct CGColor *)color;
    if (!value)
        return;
    CGContextSetRGBFillColor(context, value->r, value->g, value->b,
                             value->a);
}

void CGContextSetStrokeColorWithColor(CGContextRef context, CGColorRef color)
{
    struct CGColor *value = (struct CGColor *)color;
    if (!value)
        return;
    CGContextSetRGBStrokeColor(context, value->r, value->g, value->b,
                               value->a);
}

void CGContextSetLineWidth(CGContextRef context, double width)
{
    if (!context)
        context = g_current_context;
    if (context)
        context->state.line_width = width > 0 ? width : 1.0;
}

void CGContextSetAlpha(CGContextRef context, double alpha)
{
    if (!context)
        context = g_current_context;
    if (context)
        context->state.alpha = cg_clamp(alpha);
}

void CGContextFillRect(CGContextRef context, CGRect rect)
{
    if (!context)
        context = g_current_context;
    if (!context)
        return;
    double x0, y0, x1, y1;
    cg_transform(context, rect.origin.x, rect.origin.y, &x0, &y0);
    cg_transform(context, rect.origin.x + rect.size.width,
                 rect.origin.y + rect.size.height, &x1, &y1);
    int px = (int)(x0 + 0.5), py = (int)(y0 + 0.5);
    int pw = (int)(x1 - x0 + 0.5), ph = (int)(y1 - y0 + 0.5);
    if (pw <= 0 || ph <= 0)
        return;
    cg_apply_opacity(context, context->state.fill);
    iosim_fb_fill_rect(px, py, pw, ph, cg_rgb(context->state.fill));
}

void CGContextStrokeRect(CGContextRef context, CGRect rect)
{
    if (!context)
        context = g_current_context;
    if (!context)
        return;
    double x0, y0, x1, y1;
    cg_transform(context, rect.origin.x, rect.origin.y, &x0, &y0);
    cg_transform(context, rect.origin.x + rect.size.width,
                 rect.origin.y + rect.size.height, &x1, &y1);
    cg_apply_opacity(context, context->state.stroke);
    int thickness = cg_thickness(context);
    unsigned color = cg_rgb(context->state.stroke);
    iosim_fb_draw_line((int)x0, (int)y0, (int)x1, (int)y0, thickness, color);
    iosim_fb_draw_line((int)x1, (int)y0, (int)x1, (int)y1, thickness, color);
    iosim_fb_draw_line((int)x1, (int)y1, (int)x0, (int)y1, thickness, color);
    iosim_fb_draw_line((int)x0, (int)y1, (int)x0, (int)y0, thickness, color);
}

void CGContextFillEllipseInRect(CGContextRef context, CGRect rect)
{
    if (!context)
        context = g_current_context;
    if (!context)
        return;
    double cx, cy;
    cg_transform(context, rect.origin.x + rect.size.width / 2,
                 rect.origin.y + rect.size.height / 2, &cx, &cy);
    int rx = (int)(rect.size.width / 2 * context->state.sx *
                       context->scale + 0.5);
    int ry = (int)(rect.size.height / 2 * context->state.sy *
                       context->scale + 0.5);
    if (rx <= 0 || ry <= 0)
        return;
    cg_apply_opacity(context, context->state.fill);
    iosim_fb_fill_ellipse((int)cx, (int)cy, rx, ry,
                          cg_rgb(context->state.fill));
}

void CGContextStrokeEllipseInRect(CGContextRef context, CGRect rect)
{
    if (!context)
        context = g_current_context;
    if (!context)
        return;
    if (rect.size.width <= 0 || rect.size.height <= 0)
        return;
    double cx, cy;
    cg_transform(context, rect.origin.x + rect.size.width / 2,
                 rect.origin.y + rect.size.height / 2, &cx, &cy);
    double rx = rect.size.width / 2 * context->state.sx * context->scale;
    double ry = rect.size.height / 2 * context->state.sy * context->scale;
    cg_apply_opacity(context, context->state.stroke);
    int thickness = cg_thickness(context);
    unsigned color = cg_rgb(context->state.stroke);
    double px = cx + rx, py = cy;
    for (int i = 1; i <= 64; i++)
    {
        double angle = 2.0 * 3.14159265358979323846 * i / 64.0;
        double nx = cx + rx * __builtin_cos(angle);
        double ny = cy + ry * __builtin_sin(angle);
        iosim_fb_draw_line((int)px, (int)py, (int)nx, (int)ny, thickness,
                           color);
        px = nx;
        py = ny;
    }
}

void CGContextClearRect(CGContextRef context, CGRect rect)
{
    if (!context)
        context = g_current_context;
    if (!context)
        return;
    double x0, y0, x1, y1;
    cg_transform(context, rect.origin.x, rect.origin.y, &x0, &y0);
    cg_transform(context, rect.origin.x + rect.size.width,
                 rect.origin.y + rect.size.height, &x1, &y1);
    iosim_fb_set_opacity(1.0);
    iosim_fb_fill_rect((int)x0, (int)y0, (int)(x1 - x0 + 0.5),
                       (int)(y1 - y0 + 0.5), 0x000000);
}

void CGContextBeginPath(CGContextRef context)
{
    if (!context)
        context = g_current_context;
    if (!context)
        return;
    context->count = 0;
    context->closed = 0;
}

void CGContextMoveToPoint(CGContextRef context, double x, double y)
{
    if (!context)
        context = g_current_context;
    if (!context || context->count >= CG_MAX_POINTS)
        return;
    context->xs[context->count] = x;
    context->ys[context->count] = y;
    context->count++;
}

void CGContextAddLineToPoint(CGContextRef context, double x, double y)
{
    CGContextMoveToPoint(context, x, y);
}

void CGContextAddRect(CGContextRef context, CGRect rect)
{
    CGContextMoveToPoint(context, rect.origin.x, rect.origin.y);
    CGContextAddLineToPoint(context, rect.origin.x + rect.size.width,
                            rect.origin.y);
    CGContextAddLineToPoint(context, rect.origin.x + rect.size.width,
                            rect.origin.y + rect.size.height);
    CGContextAddLineToPoint(context, rect.origin.x,
                            rect.origin.y + rect.size.height);
    CGContextClosePath(context);
}

void CGContextAddEllipseInRect(CGContextRef context, CGRect rect)
{
    if (!context)
        context = g_current_context;
    if (!context)
        return;
    double cx = rect.origin.x + rect.size.width / 2;
    double cy = rect.origin.y + rect.size.height / 2;
    double rx = rect.size.width / 2;
    double ry = rect.size.height / 2;
    for (int i = 0; i <= 64; i++)
    {
        double angle = 2.0 * 3.14159265358979323846 * i / 64.0;
        CGContextMoveToPoint(context, cx + rx * __builtin_cos(angle),
                             cy + ry * __builtin_sin(angle));
    }
}

void CGContextClosePath(CGContextRef context)
{
    if (!context)
        context = g_current_context;
    if (context)
        context->closed = 1;
}

void CGContextFillPath(CGContextRef context)
{
    if (!context)
        context = g_current_context;
    if (!context || context->count < 3)
        return;
    double xs[CG_MAX_POINTS], ys[CG_MAX_POINTS];
    for (int i = 0; i < context->count; i++)
        cg_transform(context, context->xs[i], context->ys[i], &xs[i],
                     &ys[i]);
    cg_apply_opacity(context, context->state.fill);
    iosim_fb_fill_polygon(xs, ys, context->count,
                          cg_rgb(context->state.fill));
}

void CGContextStrokePath(CGContextRef context)
{
    if (!context)
        context = g_current_context;
    if (!context || context->count < 2)
        return;
    cg_apply_opacity(context, context->state.stroke);
    int thickness = cg_thickness(context);
    unsigned color = cg_rgb(context->state.stroke);
    for (int i = 0; i + 1 < context->count; i++)
    {
        double x0, y0, x1, y1;
        cg_transform(context, context->xs[i], context->ys[i], &x0, &y0);
        cg_transform(context, context->xs[i + 1], context->ys[i + 1], &x1,
                     &y1);
        iosim_fb_draw_line((int)x0, (int)y0, (int)x1, (int)y1, thickness,
                           color);
    }
    if (context->closed)
    {
        double x0, y0, x1, y1;
        cg_transform(context, context->xs[context->count - 1],
                     context->ys[context->count - 1], &x0, &y0);
        cg_transform(context, context->xs[0], context->ys[0], &x1, &y1);
        iosim_fb_draw_line((int)x0, (int)y0, (int)x1, (int)y1, thickness,
                           color);
    }
}

void CGContextSaveGState(CGContextRef context)
{
    if (!context)
        context = g_current_context;
    if (!context || context->depth >= CG_MAX_STATES)
        return;
    context->stack[context->depth++] = context->state;
}

void CGContextRestoreGState(CGContextRef context)
{
    if (!context)
        context = g_current_context;
    if (!context || context->depth <= 0)
        return;
    context->state = context->stack[--context->depth];
}

void CGContextTranslateCTM(CGContextRef context, double tx, double ty)
{
    if (!context)
        context = g_current_context;
    if (!context)
        return;
    context->state.tx += tx * context->state.sx;
    context->state.ty += ty * context->state.sy;
}

void CGContextScaleCTM(CGContextRef context, double sx, double sy)
{
    if (!context)
        context = g_current_context;
    if (!context)
        return;
    context->state.sx *= sx;
    context->state.sy *= sy;
}

CGColorRef CGColorCreateGenericRGB(double r, double g, double b, double a)
{
    struct CGColor *color = calloc(1, sizeof(*color));
    if (!color)
        return 0;
    color->r = r;
    color->g = g;
    color->b = b;
    color->a = a;
    return (CGColorRef)color;
}

void CGColorRelease(CGColorRef color)
{
    free(color);
}
