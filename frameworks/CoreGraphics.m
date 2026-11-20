/* CoreGraphics-lite: a direct framebuffer CGContext used by UIView's
 * drawRect: bridge. Coordinates are points; the context translates them to
 * device pixels at the owning view's origin. */

#include "coregraphics_lite.h"

extern void *malloc(unsigned long size);
extern void *calloc(unsigned long n, unsigned long size);
extern void free(void *ptr);
extern void *memcpy(void *dst, const void *src, unsigned long n);

extern void iosim_fb_fill_rect(int x, int y, int w, int h, unsigned color);
extern void iosim_fb_fill_ellipse(int cx, int cy, int rx, int ry,
                                  unsigned color);
extern void iosim_fb_draw_line(int x0, int y0, int x1, int y1, int thickness,
                               unsigned color);
extern void iosim_fb_fill_polygon(const double *xs, const double *ys,
                                  int count, unsigned color);
extern void iosim_fb_set_opacity(double opacity);
extern int iosim_fb_push_clip(int x, int y, int w, int h);
extern void iosim_fb_pop_clip(void);
extern int iosim_fb_font_text_width(const char *text, int style,
                                    double size_pt, double scale);
extern void iosim_fb_font_text(int x, int baseline_y, const char *text,
                               int style, double size_pt, double scale,
                               unsigned color);
extern void iosim_fb_font_metrics(int style, double size_pt, double scale,
                                  int *ascent, int *descent, int *line_height);

#define IOSIM_FONT_REGULAR 0
#define IOSIM_FONT_BOLD 1
#define IOSIM_FONT_SEMIBOLD 2
extern void iosim_fb_blit_rgba_scaled(int x, int y, int w, int h,
                                      const unsigned char *rgba,
                                      int source_w, int source_h,
                                      int source_stride);
extern void *iosim_fb_begin_offscreen(unsigned width, unsigned height);
extern unsigned *iosim_fb_end_offscreen(void *state, int *out_w, int *out_h);
extern unsigned *iosim_fb_offscreen_pixels(void *state, int *out_w,
                                           int *out_h);
extern void *iosim_fb_activate_offscreen(void *state);
extern void iosim_fb_restore_target(void *state);
extern void iosim_fb_free_offscreen(unsigned *buf);

#define CG_MAX_POINTS 512
#define CG_MAX_STATES 8

struct CGColor {
    int refs;
    unsigned magic;
    double r, g, b, a;
    struct CGColorSpace *space;
};

struct CGColorSpace {
    int refs;
    CGColorSpaceModel model;
};

static struct CGColorSpace g_rgb_space = { 1, kCGColorSpaceModelRGB };
static struct CGColorSpace g_gray_space = { 1, kCGColorSpaceModelMonochrome };

#define CG_COLOR_MAGIC 0x4347434fu
#define CG_IMAGE_MAGIC 0x4347494du

struct CGImage {
    int refs;
    unsigned magic;
    int w, h;
    unsigned char *rgba;
};

#define CG_MAX_PATH_POINTS 1024
#define CG_MAX_PATHS 128

struct CGPath {
    int refs;
    int count;
    unsigned char ops[CG_MAX_PATH_POINTS];
    double xs[CG_MAX_PATH_POINTS];
    double ys[CG_MAX_PATH_POINTS];
};

static struct CGPath *g_paths[CG_MAX_PATHS];

struct cg_state {
    double tx, ty;
    double sx, sy;
    double alpha;
    struct CGColor fill;
    struct CGColor stroke;
    double line_width;
    int clips;
};

struct CGContext {
    int x, y, w, h;
    double scale;
    double base_alpha;
    struct cg_state state;
    struct cg_state stack[CG_MAX_STATES];
    int depth;
    int clips;
    double xs[CG_MAX_POINTS];
    double ys[CG_MAX_POINTS];
    int count;
    int closed;
    int image;
    void *offscreen;
    unsigned char *rgba;
    CGContextRef previous;
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
    context->previous = g_current_context;
    g_current_context = context;
    return context;
}

CGContextRef iosim_cg_current(void)
{
    return g_current_context;
}

CGContextRef iosim_cg_swap_current(CGContextRef context)
{
    CGContextRef previous = g_current_context;
    g_current_context = context;
    return previous;
}

struct cg_push_token {
    CGContextRef previous;
    void *fb_target;
};

void *iosim_cg_push_context(CGContextRef context)
{
    if (!context)
        return 0;
    struct cg_push_token *token = calloc(1, sizeof(*token));
    if (!token)
        return 0;
    token->previous = g_current_context;
    if (g_current_context != context && context->image && context->offscreen)
        token->fb_target = iosim_fb_activate_offscreen(context->offscreen);
    g_current_context = context;
    return token;
}

void iosim_cg_pop_context(void *tokenPtr)
{
    struct cg_push_token *token = tokenPtr;
    if (!token)
        return;
    g_current_context = token->previous;
    if (token->fb_target)
        iosim_fb_restore_target(token->fb_target);
    free(token);
}

CGContextRef iosim_cg_begin_image(int w, int h, double scale)
{
    if (w <= 0 || h <= 0)
        return 0;
    CGContextRef context = calloc(1, sizeof(*context));
    if (!context)
        return 0;
    void *offscreen = iosim_fb_begin_offscreen((unsigned)w, (unsigned)h);
    if (!offscreen)
    {
        free(context);
        return 0;
    }
    context->w = w;
    context->h = h;
    context->scale = scale > 0 ? scale : 1.0;
    context->base_alpha = 1.0;
    context->image = 1;
    context->offscreen = offscreen;
    context->state.sx = 1;
    context->state.sy = 1;
    context->state.alpha = 1;
    context->state.fill.a = 1;
    context->state.stroke.a = 1;
    context->state.line_width = 1.0;
    context->previous = g_current_context;
    g_current_context = context;
    return context;
}

int iosim_cg_image_data(CGContextRef context, unsigned char **out_rgba,
                        int *out_w, int *out_h)
{
    if (!context || !context->image)
        return -1;
    if (!context->rgba)
    {
        int width = 0, height = 0;
        unsigned *pixels = 0;
        if (context->offscreen)
            pixels = iosim_fb_offscreen_pixels(context->offscreen, &width,
                                               &height);
        if (!pixels || width <= 0 || height <= 0)
            return -1;
        unsigned char *rgba = malloc((unsigned long)width * height * 4);
        if (!rgba)
            return -1;
        for (int y = 0; y < height; y++)
            for (int x = 0; x < width; x++)
            {
                unsigned color = pixels[(unsigned long)y * width + x];
                unsigned char *dst = rgba + ((unsigned long)y * width + x) * 4;
                dst[0] = (unsigned char)((color >> 16) & 255);
                dst[1] = (unsigned char)((color >> 8) & 255);
                dst[2] = (unsigned char)(color & 255);
                dst[3] = 255;
            }
        context->rgba = rgba;
    }
    if (out_rgba)
        *out_rgba = context->rgba;
    if (out_w)
        *out_w = context->w;
    if (out_h)
        *out_h = context->h;
    return 0;
}

void iosim_cg_end_image(CGContextRef context)
{
    if (!context)
        return;
    if (context->offscreen)
    {
        int width = 0, height = 0;
        unsigned *pixels = iosim_fb_end_offscreen(context->offscreen, &width,
                                                  &height);
        if (pixels)
            iosim_fb_free_offscreen(pixels);
        context->offscreen = 0;
    }
    free(context->rgba);
    if (g_current_context == context)
        g_current_context = context->previous;
    iosim_fb_set_opacity(1.0);
    free(context);
}

void iosim_cg_draw_image(CGContextRef context, const unsigned char *rgba,
                         int w, int h, CGRect rect)
{
    if (!context)
        context = g_current_context;
    if (!context || !rgba || w <= 0 || h <= 0)
        return;
    double x0, y0, x1, y1;
    cg_transform(context, rect.origin.x, rect.origin.y, &x0, &y0);
    cg_transform(context, rect.origin.x + rect.size.width,
                 rect.origin.y + rect.size.height, &x1, &y1);
    int px = (int)(x0 + 0.5), py = (int)(y0 + 0.5);
    int pw = (int)(x1 - x0 + 0.5), ph = (int)(y1 - y0 + 0.5);
    if (pw <= 0 || ph <= 0)
        return;
    iosim_fb_set_opacity(context->base_alpha * context->state.alpha);
    iosim_fb_blit_rgba_scaled(px, py, pw, ph, rgba, w, h, w * 4);
}

void iosim_cg_end_view(CGContextRef context)
{
    if (!context)
        return;
    while (context->clips > 0)
    {
        iosim_fb_pop_clip();
        context->clips--;
    }
    if (g_current_context == context)
        g_current_context = context->previous;
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

void CGContextClipToRect(CGContextRef context, CGRect rect)
{
    if (!context)
        context = g_current_context;
    if (!context)
        return;
    double x0, y0, x1, y1;
    cg_transform(context, rect.origin.x, rect.origin.y, &x0, &y0);
    cg_transform(context, rect.origin.x + rect.size.width,
                 rect.origin.y + rect.size.height, &x1, &y1);
    int w = (int)(x1 - x0 + 0.5);
    int h = (int)(y1 - y0 + 0.5);
    if (w < 0)
    {
        x0 -= w;
        w = -w;
    }
    if (h < 0)
    {
        y0 -= h;
        h = -h;
    }
    if (iosim_fb_push_clip((int)x0, (int)y0, w, h))
    {
        context->clips++;
        context->state.clips = context->clips;
    }
}

void CGContextClip(CGContextRef context)
{
    if (!context)
        context = g_current_context;
    if (!context || context->count < 3)
        return;
    double minx = context->xs[0], maxx = minx;
    double miny = context->ys[0], maxy = miny;
    for (int i = 1; i < context->count; i++)
    {
        if (context->xs[i] < minx) minx = context->xs[i];
        if (context->xs[i] > maxx) maxx = context->xs[i];
        if (context->ys[i] < miny) miny = context->ys[i];
        if (context->ys[i] > maxy) maxy = context->ys[i];
    }
    CGContextClipToRect(context, CGRectMake(minx, miny, maxx - minx,
                                           maxy - miny));
}

void CGContextResetClip(CGContextRef context)
{
    if (!context)
        context = g_current_context;
    if (!context)
        return;
    while (context->clips > 0)
    {
        iosim_fb_pop_clip();
        context->clips--;
    }
    context->state.clips = 0;
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
    context->state.clips = context->clips;
    context->stack[context->depth++] = context->state;
}

void CGContextRestoreGState(CGContextRef context)
{
    if (!context)
        context = g_current_context;
    if (!context || context->depth <= 0)
        return;
    context->state = context->stack[--context->depth];
    while (context->clips > context->state.clips)
    {
        iosim_fb_pop_clip();
        context->clips--;
    }
    context->clips = context->state.clips;
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

void iosim_cg_draw_text(CGContextRef context, const char *text, double x,
                        double baseline, double size_pt, int bold,
                        unsigned color)
{
    if (!context)
        context = g_current_context;
    if (!context || !text)
        return;
    double px, py;
    cg_transform(context, x, baseline, &px, &py);
    iosim_fb_set_opacity(context->base_alpha * context->state.alpha);
    iosim_fb_font_text((int)(px + 0.5), (int)(py + 0.5), text,
                       bold ? IOSIM_FONT_SEMIBOLD : IOSIM_FONT_REGULAR,
                       size_pt, context->scale, color);
    iosim_fb_set_opacity(1.0);
}

double iosim_cg_text_width(CGContextRef context, const char *text,
                           double size_pt, int bold)
{
    if (!context)
        context = g_current_context;
    if (!context || !text)
        return 0;
    int pixels = iosim_fb_font_text_width(
        text, bold ? IOSIM_FONT_SEMIBOLD : IOSIM_FONT_REGULAR, size_pt,
        context->scale);
    return context->scale > 0 ? pixels / context->scale : pixels;
}

CGColorSpaceRef CGColorSpaceCreateDeviceRGB(void)
{
    g_rgb_space.refs++;
    return &g_rgb_space;
}

CGColorSpaceRef CGColorSpaceCreateDeviceGray(void)
{
    g_gray_space.refs++;
    return &g_gray_space;
}

CGColorSpaceRef CGColorSpaceRetain(CGColorSpaceRef space)
{
    if (space)
        space->refs++;
    return space;
}

void CGColorSpaceRelease(CGColorSpaceRef space)
{
    if (space && space->refs > 1)
        space->refs--;
}

CGColorSpaceModel CGColorSpaceGetModel(CGColorSpaceRef space)
{
    return space ? space->model : kCGColorSpaceModelUnknown;
}

CGColorRef CGColorCreate(CGColorSpaceRef space, const double *components)
{
    if (!space || !components)
        return 0;
    double r, g, b, a;
    if (space->model == kCGColorSpaceModelMonochrome)
    {
        r = g = b = components[0];
        a = components[1];
    }
    else
    {
        r = components[0];
        g = components[1];
        b = components[2];
        a = components[3];
    }
    CGColorRef color = CGColorCreateGenericRGB(r, g, b, a);
    if (color)
        ((struct CGColor *)color)->space = space;
    return color;
}

CGColorSpaceRef CGColorGetColorSpace(CGColorRef colorRef)
{
    struct CGColor *color = (struct CGColor *)colorRef;
    if (!color)
        return 0;
    return color->space ? color->space : &g_rgb_space;
}

CGColorRef CGColorCreateGenericRGB(double r, double g, double b, double a)
{
    struct CGColor *color = calloc(1, sizeof(*color));
    if (!color)
        return 0;
    color->refs = 1;
    color->magic = CG_COLOR_MAGIC;
    color->r = r;
    color->g = g;
    color->b = b;
    color->a = a;
    color->space = &g_rgb_space;
    return (CGColorRef)color;
}

CGColorRef CGColorRetain(CGColorRef colorRef)
{
    struct CGColor *color = (struct CGColor *)colorRef;
    if (color)
        color->refs++;
    return colorRef;
}

void CGColorRelease(CGColorRef colorRef)
{
    struct CGColor *color = (struct CGColor *)colorRef;
    if (!color)
        return;
    if (--color->refs > 0)
        return;
    color->magic = 0;
    free(color);
}

int iosim_cgcolor_is_valid(const void *colorRef)
{
    struct CGColor *color = (struct CGColor *)colorRef;
    if (!color || color->magic != CG_COLOR_MAGIC || color->refs <= 0)
        return 0;
    return 1;
}

const double *CGColorGetComponents(CGColorRef colorRef)
{
    struct CGColor *color = (struct CGColor *)colorRef;
    return color ? &color->r : 0;
}

double CGColorGetAlpha(CGColorRef colorRef)
{
    struct CGColor *color = (struct CGColor *)colorRef;
    return color ? color->a : 0;
}

int CGColorEqualToColor(CGColorRef a, CGColorRef b)
{
    struct CGColor *ca = (struct CGColor *)a;
    struct CGColor *cb = (struct CGColor *)b;
    if (ca == cb)
        return 1;
    if (!ca || !cb)
        return 0;
    return ca->r == cb->r && ca->g == cb->g && ca->b == cb->b &&
           ca->a == cb->a;
}

/* ----------------------------------------------------------------- images */

CGImageRef CGImageCreateWithRGBA(const unsigned char *rgba, int w, int h)
{
    if (!rgba || w <= 0 || h <= 0)
        return 0;
    struct CGImage *image = calloc(1, sizeof(*image));
    if (!image)
        return 0;
    image->rgba = malloc((unsigned long)w * h * 4);
    if (!image->rgba)
    {
        free(image);
        return 0;
    }
    memcpy(image->rgba, rgba, (unsigned long)w * h * 4);
    image->refs = 1;
    image->magic = CG_IMAGE_MAGIC;
    image->w = w;
    image->h = h;
    return (CGImageRef)image;
}

CGImageRef CGImageRetain(CGImageRef imageRef)
{
    struct CGImage *image = (struct CGImage *)imageRef;
    if (image)
        image->refs++;
    return imageRef;
}

void CGImageRelease(CGImageRef imageRef)
{
    struct CGImage *image = (struct CGImage *)imageRef;
    if (!image)
        return;
    if (--image->refs > 0)
        return;
    image->magic = 0;
    free(image->rgba);
    free(image);
}

int CGImageGetWidth(CGImageRef imageRef)
{
    struct CGImage *image = (struct CGImage *)imageRef;
    return image ? image->w : 0;
}

int CGImageGetHeight(CGImageRef imageRef)
{
    struct CGImage *image = (struct CGImage *)imageRef;
    return image ? image->h : 0;
}

const unsigned char *iosim_cgimage_data(CGImageRef imageRef, int *out_w,
                                        int *out_h)
{
    struct CGImage *image = (struct CGImage *)imageRef;
    if (!image)
        return 0;
    if (out_w) *out_w = image->w;
    if (out_h) *out_h = image->h;
    return image->rgba;
}

int iosim_cgimage_is_valid(const void *imageRef)
{
    struct CGImage *image = (struct CGImage *)imageRef;
    if (!image || image->magic != CG_IMAGE_MAGIC || image->refs <= 0)
        return 0;
    return 1;
}

void CGContextDrawImage(CGContextRef context, CGRect rect, CGImageRef imageRef)
{
    struct CGImage *image = (struct CGImage *)imageRef;
    if (!image)
        return;
    iosim_cg_draw_image(context, image->rgba, image->w, image->h, rect);
}

/* ------------------------------------------------------------------ paths */

static struct CGPath *cg_path_alloc(void)
{
    struct CGPath *path = calloc(1, sizeof(*path));
    if (!path)
        return 0;
    path->refs = 1;
    for (int i = 0; i < CG_MAX_PATHS; i++)
    {
        if (!g_paths[i])
        {
            g_paths[i] = path;
            return path;
        }
    }
    free(path);
    return 0;
}

CGPathRef CGPathCreateMutable(void)
{
    return (CGPathRef)cg_path_alloc();
}

CGPathRef CGPathRetain(CGPathRef pathRef)
{
    struct CGPath *path = (struct CGPath *)pathRef;
    if (path)
        path->refs++;
    return pathRef;
}

void CGPathRelease(CGPathRef pathRef)
{
    struct CGPath *path = (struct CGPath *)pathRef;
    if (!path)
        return;
    if (--path->refs > 0)
        return;
    for (int i = 0; i < CG_MAX_PATHS; i++)
    {
        if (g_paths[i] == path)
        {
            g_paths[i] = 0;
            free(path);
            return;
        }
    }
}

int iosim_cgpath_is_valid(const void *pathRef)
{
    if (!pathRef)
        return 0;
    for (int i = 0; i < CG_MAX_PATHS; i++)
    {
        if (g_paths[i] == pathRef && g_paths[i]->refs > 0)
            return 1;
    }
    return 0;
}

static void cg_path_append(struct CGPath *path, unsigned char op, double x,
                           double y)
{
    if (!path || path->count >= CG_MAX_PATH_POINTS)
        return;
    path->ops[path->count] = op;
    path->xs[path->count] = x;
    path->ys[path->count] = y;
    path->count++;
}

void CGPathMoveToPoint(CGPathRef pathRef, const void *transform, double x,
                       double y)
{
    (void)transform;
    cg_path_append((struct CGPath *)pathRef, 0, x, y);
}

void CGPathAddLineToPoint(CGPathRef pathRef, const void *transform, double x,
                          double y)
{
    (void)transform;
    cg_path_append((struct CGPath *)pathRef, 1, x, y);
}

void CGPathAddRect(CGPathRef pathRef, const void *transform, CGRect rect)
{
    (void)transform;
    CGPathMoveToPoint(pathRef, 0, rect.origin.x, rect.origin.y);
    CGPathAddLineToPoint(pathRef, 0, rect.origin.x + rect.size.width,
                         rect.origin.y);
    CGPathAddLineToPoint(pathRef, 0,
                         rect.origin.x + rect.size.width,
                         rect.origin.y + rect.size.height);
    CGPathAddLineToPoint(pathRef, 0, rect.origin.x,
                         rect.origin.y + rect.size.height);
    CGPathCloseSubpath(pathRef);
}

void CGPathAddEllipseInRect(CGPathRef pathRef, const void *transform,
                            CGRect rect)
{
    (void)transform;
    double cx = rect.origin.x + rect.size.width / 2;
    double cy = rect.origin.y + rect.size.height / 2;
    double rx = rect.size.width / 2;
    double ry = rect.size.height / 2;
    CGPathMoveToPoint(pathRef, 0, cx + rx, cy);
    for (int i = 1; i <= 64; i++)
    {
        double angle = 2.0 * 3.14159265358979323846 * i / 64.0;
        CGPathAddLineToPoint(pathRef, 0, cx + rx * __builtin_cos(angle),
                             cy + ry * __builtin_sin(angle));
    }
    CGPathCloseSubpath(pathRef);
}

void CGPathCloseSubpath(CGPathRef pathRef)
{
    cg_path_append((struct CGPath *)pathRef, 2, 0, 0);
}

void CGPathAddPath(CGPathRef pathRef, const void *transform, CGPathRef otherRef)
{
    (void)transform;
    struct CGPath *path = (struct CGPath *)pathRef;
    struct CGPath *other = (struct CGPath *)otherRef;
    if (!path || !other)
        return;
    for (int i = 0; i < other->count; i++)
        cg_path_append(path, other->ops[i], other->xs[i], other->ys[i]);
}

CGPathRef CGPathCreateWithRect(CGRect rect, const void *transform)
{
    CGPathRef path = CGPathCreateMutable();
    if (path)
        CGPathAddRect(path, transform, rect);
    return path;
}

CGPathRef CGPathCreateCopy(CGPathRef pathRef)
{
    CGPathRef copy = CGPathCreateMutable();
    if (copy)
        CGPathAddPath(copy, 0, pathRef);
    return copy;
}

CGPathRef CGPathCreateMutableCopy(CGPathRef pathRef)
{
    return CGPathCreateCopy(pathRef);
}

CGRect CGPathGetBoundingBox(CGPathRef pathRef)
{
    struct CGPath *path = (struct CGPath *)pathRef;
    if (!path || path->count <= 0)
        return CGRectMake(0, 0, 0, 0);
    double minx = path->xs[0], maxx = minx;
    double miny = path->ys[0], maxy = miny;
    for (int i = 1; i < path->count; i++)
    {
        if (path->ops[i] == 2)
            continue;
        if (path->xs[i] < minx) minx = path->xs[i];
        if (path->xs[i] > maxx) maxx = path->xs[i];
        if (path->ys[i] < miny) miny = path->ys[i];
        if (path->ys[i] > maxy) maxy = path->ys[i];
    }
    return CGRectMake(minx, miny, maxx - minx, maxy - miny);
}

int CGPathContainsPoint(CGPathRef pathRef, const void *transform,
                        CGPoint point, int evenOdd)
{
    (void)transform;
    (void)evenOdd;
    struct CGPath *path = (struct CGPath *)pathRef;
    if (!path || path->count < 3)
        return 0;
    int inside = 0;
    for (int i = 0, j = path->count - 1; i < path->count; j = i++)
    {
        if (path->ops[i] == 2 || path->ops[j] == 2)
            continue;
        double xi = path->xs[i], yi = path->ys[i];
        double xj = path->xs[j], yj = path->ys[j];
        if (((yi > point.y) != (yj > point.y)) &&
            (point.x < (xj - xi) * (point.y - yi) / (yj - yi) + xi))
            inside = !inside;
    }
    return inside;
}

void CGPathApply(CGPathRef pathRef, void *info, CGPathApplierFunction function)
{
    struct CGPath *path = (struct CGPath *)pathRef;
    if (!path || !function)
        return;
    for (int i = 0; i < path->count; i++)
    {
        CGPoint points[3];
        points[0].x = path->xs[i];
        points[0].y = path->ys[i];
        points[1].x = 0;
        points[1].y = 0;
        points[2].x = 0;
        points[2].y = 0;
        CGPathElement element;
        element.points = points;
        switch (path->ops[i])
        {
        case 0:
            element.type = kCGPathElementMoveToPoint;
            break;
        case 2:
            element.type = kCGPathElementCloseSubpath;
            element.points = 0;
            break;
        default:
            element.type = kCGPathElementAddLineToPoint;
            break;
        }
        function(info, &element);
    }
}

void CGContextAddPath(CGContextRef context, CGPathRef pathRef)
{
    struct CGPath *path = (struct CGPath *)pathRef;
    if (!context)
        context = g_current_context;
    if (!context || !path)
        return;
    if (context->count == 0)
        context->closed = 0;
    for (int i = 0; i < path->count; i++)
    {
        switch (path->ops[i])
        {
        case 0:
            if (context->count == 0)
                CGContextMoveToPoint(context, path->xs[i], path->ys[i]);
            else
                CGContextAddLineToPoint(context, path->xs[i], path->ys[i]);
            break;
        case 2:
            CGContextClosePath(context);
            break;
        default:
            CGContextAddLineToPoint(context, path->xs[i], path->ys[i]);
            break;
        }
    }
}
