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
extern void iosim_fb_stroke_polyline(const double *xs, const double *ys,
                                     int count, int closed, double start,
                                     double end, double width,
                                     unsigned color, int cap, int join,
                                     double miter_limit, const double *dash,
                                     int dash_count, double dash_phase);
extern void iosim_fb_fill_polygon(const double *xs, const double *ys,
                                  int count, unsigned color);
extern void iosim_fb_set_opacity(double opacity);
extern void iosim_fb_set_blend_mode(int mode);
extern int iosim_fb_push_clip(int x, int y, int w, int h);
extern void iosim_fb_pop_clip(void);
extern int iosim_fb_push_clip_polygon(const double *xs, const double *ys,
                                      int count);
extern void iosim_fb_pop_clip_mask(void);
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
extern void iosim_fb_fill_gradient_stops(int x, int y, int w, int h,
                                         const unsigned *colors,
                                         const double *locations, int count,
                                         double ax, double ay, double bx,
                                         double by);
extern void iosim_fb_fill_gradient_stops_alpha(int x, int y, int w, int h,
                                               const unsigned *colors,
                                               const unsigned char *alphas,
                                               const double *locations,
                                               int count, double ax,
                                               double ay, double bx,
                                               double by);
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

struct CGGradient {
    int refs;
    unsigned count;
    double *components;
    double *locations;
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
    int blend_mode;
    struct CGColor fill;
    struct CGColor stroke;
    double line_width;
    int line_cap;
    int line_join;
    double miter_limit;
    double dash[16];
    int dash_count;
    double dash_phase;
    int clips;
    int masks;
};

struct CGContext {
    int x, y, w, h;
    double scale;
    double base_alpha;
    struct cg_state state;
    struct cg_state stack[CG_MAX_STATES];
    int depth;
    int clips;
    int masks;
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
    iosim_fb_set_blend_mode(context->state.blend_mode);
}

static void cg_transform(CGContextRef context, double x, double y,
                         double *px, double *py)
{
    *px = context->x +
          (x * context->state.sx + context->state.tx) * context->scale;
    *py = context->y +
          (y * context->state.sy + context->state.ty) * context->scale;
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
    context->state.miter_limit = 10.0;
    iosim_fb_set_blend_mode(kCGBlendModeNormal);
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
    context->state.miter_limit = 10.0;
    iosim_fb_set_blend_mode(kCGBlendModeNormal);
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
    while (context->masks > 0)
    {
        iosim_fb_pop_clip_mask();
        context->masks--;
    }
    while (context->clips > 0)
    {
        iosim_fb_pop_clip();
        context->clips--;
    }
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
    iosim_fb_set_blend_mode(kCGBlendModeNormal);
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
    iosim_fb_set_blend_mode(kCGBlendModeNormal);
    iosim_fb_blit_rgba_scaled(px, py, pw, ph, rgba, w, h, w * 4);
}

void iosim_cg_end_view(CGContextRef context)
{
    if (!context)
        return;
    while (context->masks > 0)
    {
        iosim_fb_pop_clip_mask();
        context->masks--;
    }
    while (context->clips > 0)
    {
        iosim_fb_pop_clip();
        context->clips--;
    }
    if (g_current_context == context)
        g_current_context = context->previous;
    iosim_fb_set_opacity(1.0);
    iosim_fb_set_blend_mode(kCGBlendModeNormal);
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

void CGContextSetLineCap(CGContextRef context, int cap)
{
    if (!context)
        context = g_current_context;
    if (context)
        context->state.line_cap = cap;
}

int CGContextGetLineCap(CGContextRef context)
{
    if (!context)
        context = g_current_context;
    return context ? context->state.line_cap : 0;
}

void CGContextSetLineJoin(CGContextRef context, int join)
{
    if (!context)
        context = g_current_context;
    if (context)
        context->state.line_join = join;
}

int CGContextGetLineJoin(CGContextRef context)
{
    if (!context)
        context = g_current_context;
    return context ? context->state.line_join : 0;
}

void CGContextSetMiterLimit(CGContextRef context, double limit)
{
    if (!context)
        context = g_current_context;
    if (context)
        context->state.miter_limit = limit > 1.0 ? limit : 1.0;
}

void CGContextSetLineDash(CGContextRef context, double phase,
                          const double *lengths, unsigned long count)
{
    if (!context)
        context = g_current_context;
    if (!context)
        return;
    if (!lengths || count == 0)
    {
        context->state.dash_count = 0;
        return;
    }
    if (count > 16)
        count = 16;
    for (unsigned long i = 0; i < count; i++)
        context->state.dash[i] = lengths[i];
    context->state.dash_count = (int)count;
    context->state.dash_phase = phase;
}

void CGContextSetAlpha(CGContextRef context, double alpha)
{
    if (!context)
        context = g_current_context;
    if (context)
        context->state.alpha = cg_clamp(alpha);
}

void CGContextSetBlendMode(CGContextRef context, int mode)
{
    if (!context)
        context = g_current_context;
    if (!context)
        return;
    if (mode < kCGBlendModeNormal || mode > kCGBlendModePlusLighter)
        mode = kCGBlendModeNormal;
    context->state.blend_mode = mode;
}

int CGContextGetBlendMode(CGContextRef context)
{
    if (!context)
        context = g_current_context;
    return context ? context->state.blend_mode : kCGBlendModeNormal;
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

/* Stroke already-transformed device-space points with the context's
 * current line width, cap, join, miter limit and dash pattern. */
static void cg_stroke_points(CGContextRef context, const double *xs,
                             const double *ys, int count, int closed)
{
    if (!context || !xs || !ys || count < 2)
        return;
    cg_apply_opacity(context, context->state.stroke);
    double width = context->state.line_width * context->scale;
    if (width < 1.0)
        width = 1.0;
    iosim_fb_stroke_polyline(
        xs, ys, count, closed, 0.0, 1.0, width,
        cg_rgb(context->state.stroke), context->state.line_cap,
        context->state.line_join, context->state.miter_limit,
        context->state.dash_count > 0 ? context->state.dash : 0,
        context->state.dash_count, context->state.dash_phase);
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
    double xs[5] = { x0, x1, x1, x0, x0 };
    double ys[5] = { y0, y0, y1, y1, y0 };
    cg_stroke_points(context, xs, ys, 5, 1);
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
    double cx = rect.origin.x + rect.size.width / 2;
    double cy = rect.origin.y + rect.size.height / 2;
    double rx = rect.size.width / 2, ry = rect.size.height / 2;
    double xs[64], ys[64];
    for (int i = 0; i < 64; i++)
    {
        double angle = 2.0 * 3.14159265358979323846 * i / 64.0;
        cg_transform(context, cx + rx * __builtin_cos(angle),
                     cy + ry * __builtin_sin(angle), &xs[i], &ys[i]);
    }
    cg_stroke_points(context, xs, ys, 64, 1);
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

#define CG_ARC_MAX_STEPS 256

/* Angles use the view coordinate system: x to the right, y down, so a
 * positive sweep is clockwise on screen. The endpoint is normalized into
 * [0, 2*pi) for a clockwise arc and (-2*pi, 0] otherwise. */
static int cg_arc_points(double cx, double cy, double radius,
                         double start, double end, int clockwise,
                         double *xs, double *ys, int capacity)
{
    const double two_pi = 6.28318530717958647692;
    if (radius <= 0.0 || capacity < 2)
        return 0;
    double delta = end - start;
    if (clockwise)
    {
        while (delta < 0.0)
            delta += two_pi;
        while (delta >= two_pi)
            delta -= two_pi;
    }
    else
    {
        while (delta > 0.0)
            delta -= two_pi;
        while (delta <= -two_pi)
            delta += two_pi;
    }
    int steps = (int)(__builtin_fabs(delta) * radius / 2.0) + 1;
    if (steps < 4)
        steps = 4;
    if (steps > CG_ARC_MAX_STEPS)
        steps = CG_ARC_MAX_STEPS;
    if (steps + 1 > capacity)
        steps = capacity - 1;
    for (int i = 0; i <= steps; i++)
    {
        double angle = start + delta * ((double)i / steps);
        xs[i] = cx + radius * __builtin_cos(angle);
        ys[i] = cy + radius * __builtin_sin(angle);
    }
    return steps + 1;
}

/* Tangent points and center of the rounded corner between p0->p1->p2.
 * Returns 0 for a degenerate corner; the caller then just draws to p1. */
static int cg_arc_to_params(double x0, double y0, double x1, double y1,
                            double x2, double y2, double radius,
                            double *tx1, double *ty1, double *tx2,
                            double *ty2, double *cx, double *cy,
                            int *clockwise)
{
    if (radius <= 0.0)
        return 0;
    double v1x = x0 - x1, v1y = y0 - y1;
    double v2x = x2 - x1, v2y = y2 - y1;
    double l1 = __builtin_sqrt(v1x * v1x + v1y * v1y);
    double l2 = __builtin_sqrt(v2x * v2x + v2y * v2y);
    if (l1 < 1e-9 || l2 < 1e-9)
        return 0;
    v1x /= l1; v1y /= l1;
    v2x /= l2; v2y /= l2;
    double dot = v1x * v2x + v1y * v2y;
    if (dot < -1.0)
        dot = -1.0;
    if (dot > 1.0)
        dot = 1.0;
    double theta = __builtin_acos(dot);
    if (theta < 1e-6 || __builtin_fabs(theta - 3.14159265358979323846) < 1e-6)
        return 0;
    double tangent = radius / __builtin_tan(theta / 2.0);
    *tx1 = x1 + v1x * tangent;
    *ty1 = y1 + v1y * tangent;
    *tx2 = x1 + v2x * tangent;
    *ty2 = y1 + v2y * tangent;
    double bx = v1x + v2x, by = v1y + v2y;
    double bl = __builtin_sqrt(bx * bx + by * by);
    if (bl < 1e-9)
        return 0;
    double distance = radius / __builtin_sin(theta / 2.0);
    *cx = x1 + bx / bl * distance;
    *cy = y1 + by / bl * distance;
    /* In the y-down view space a negative cross product is a screen-
     * clockwise turn, which cg_arc_points expresses as increasing angles. */
    *clockwise = (v1x * v2y - v1y * v2x) < 0.0;
    return 1;
}

void CGContextAddArc(CGContextRef context, double cx, double cy,
                     double radius, double startAngle, double endAngle,
                     int clockwise)
{
    if (!context)
        context = g_current_context;
    if (!context)
        return;
    double xs[CG_ARC_MAX_STEPS + 1];
    double ys[CG_ARC_MAX_STEPS + 1];
    int count = cg_arc_points(cx, cy, radius, startAngle, endAngle, clockwise,
                              xs, ys, CG_ARC_MAX_STEPS + 1);
    if (count <= 0)
        return;
    if (context->count == 0)
        CGContextMoveToPoint(context, xs[0], ys[0]);
    else
        CGContextAddLineToPoint(context, xs[0], ys[0]);
    for (int i = 1; i < count; i++)
        CGContextAddLineToPoint(context, xs[i], ys[i]);
}

void CGContextAddArcToPoint(CGContextRef context, double x1, double y1,
                            double x2, double y2, double radiusOfCorner)
{
    if (!context)
        context = g_current_context;
    if (!context)
        return;
    double x0 = context->count ? context->xs[context->count - 1] : 0.0;
    double y0 = context->count ? context->ys[context->count - 1] : 0.0;
    double tx1, ty1, tx2, ty2, cx, cy;
    int clockwise = 0;
    if (!cg_arc_to_params(x0, y0, x1, y1, x2, y2, radiusOfCorner,
                          &tx1, &ty1, &tx2, &ty2, &cx, &cy, &clockwise))
    {
        CGContextAddLineToPoint(context, x1, y1);
        return;
    }
    CGContextAddLineToPoint(context, tx1, ty1);
    double xs[CG_ARC_MAX_STEPS + 1];
    double ys[CG_ARC_MAX_STEPS + 1];
    double start = __builtin_atan2(ty1 - cy, tx1 - cx);
    double end = __builtin_atan2(ty2 - cy, tx2 - cx);
    int count = cg_arc_points(cx, cy, radiusOfCorner, start, end, clockwise,
                              xs, ys, CG_ARC_MAX_STEPS + 1);
    for (int i = 1; i < count; i++)
        CGContextAddLineToPoint(context, xs[i], ys[i]);
}

void CGContextAddQuadCurveToPoint(CGContextRef context, double cpx,
                                  double cpy, double x, double y)
{
    if (!context)
        context = g_current_context;
    if (!context)
        return;
    double x0 = context->count > 0 ? context->xs[context->count - 1] : 0;
    double y0 = context->count > 0 ? context->ys[context->count - 1] : 0;
    int steps = iosim_cg_quad_segments(x0, y0, cpx, cpy, x, y);
    for (int i = 1; i <= steps; i++)
    {
        double t = (double)i / steps;
        double u = 1.0 - t;
        CGContextAddLineToPoint(context,
                                u * u * x0 + 2 * u * t * cpx + t * t * x,
                                u * u * y0 + 2 * u * t * cpy + t * t * y);
    }
}

void CGContextAddCurveToPoint(CGContextRef context, double cp1x, double cp1y,
                              double cp2x, double cp2y, double x, double y)
{
    if (!context)
        context = g_current_context;
    if (!context)
        return;
    double x0 = context->count > 0 ? context->xs[context->count - 1] : 0;
    double y0 = context->count > 0 ? context->ys[context->count - 1] : 0;
    int steps = iosim_cg_cubic_segments(x0, y0, cp1x, cp1y, cp2x, cp2y, x, y);
    for (int i = 1; i <= steps; i++)
    {
        double t = (double)i / steps;
        double u = 1.0 - t;
        CGContextAddLineToPoint(
            context,
            u * u * u * x0 + 3 * u * u * t * cp1x +
                3 * u * t * t * cp2x + t * t * t * x,
            u * u * u * y0 + 3 * u * u * t * cp1y +
                3 * u * t * t * cp2y + t * t * t * y);
    }
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
    double xs[CG_MAX_POINTS], ys[CG_MAX_POINTS];
    for (int i = 0; i < context->count; i++)
        cg_transform(context, context->xs[i], context->ys[i], &xs[i],
                     &ys[i]);
    if (iosim_fb_push_clip_polygon(xs, ys, context->count))
    {
        context->masks++;
        context->state.masks = context->masks;
    }
}

void CGContextResetClip(CGContextRef context)
{
    if (!context)
        context = g_current_context;
    if (!context)
        return;
    while (context->masks > 0)
    {
        iosim_fb_pop_clip_mask();
        context->masks--;
    }
    while (context->clips > 0)
    {
        iosim_fb_pop_clip();
        context->clips--;
    }
    context->state.clips = 0;
    context->state.masks = 0;
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
    double xs[CG_MAX_POINTS], ys[CG_MAX_POINTS];
    for (int i = 0; i < context->count; i++)
        cg_transform(context, context->xs[i], context->ys[i], &xs[i],
                     &ys[i]);
    cg_stroke_points(context, xs, ys, context->count, context->closed);
}

void CGContextSaveGState(CGContextRef context)
{
    if (!context)
        context = g_current_context;
    if (!context || context->depth >= CG_MAX_STATES)
        return;
    context->state.clips = context->clips;
    context->state.masks = context->masks;
    context->stack[context->depth++] = context->state;
}

void CGContextRestoreGState(CGContextRef context)
{
    if (!context)
        context = g_current_context;
    if (!context || context->depth <= 0)
        return;
    context->state = context->stack[--context->depth];
    while (context->masks > context->state.masks)
    {
        iosim_fb_pop_clip_mask();
        context->masks--;
    }
    context->masks = context->state.masks;
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
    iosim_fb_set_blend_mode(kCGBlendModeNormal);
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

CGGradientRef CGGradientCreateWithColorComponents(
    CGColorSpaceRef space, const double *components, const double *locations,
    unsigned long count)
{
    if (!space || !components || count < 2)
        return 0;
    struct CGGradient *gradient = calloc(1, sizeof(*gradient));
    if (!gradient)
        return 0;
    gradient->components = malloc(sizeof(double) * count * 4);
    gradient->locations = malloc(sizeof(double) * count);
    if (!gradient->components || !gradient->locations)
    {
        free(gradient->components);
        free(gradient->locations);
        free(gradient);
        return 0;
    }
    memcpy(gradient->components, components, sizeof(double) * count * 4);
    for (unsigned long i = 0; i < count; i++)
        gradient->locations[i] = locations
            ? locations[i]
            : (count > 1 ? (double)i / (double)(count - 1) : 0.0);
    gradient->count = (unsigned)count;
    gradient->refs = 1;
    return (CGGradientRef)gradient;
}

CGGradientRef CGGradientRetain(CGGradientRef gradientRef)
{
    struct CGGradient *gradient = (struct CGGradient *)gradientRef;
    if (gradient)
        gradient->refs++;
    return gradientRef;
}

void CGGradientRelease(CGGradientRef gradientRef)
{
    struct CGGradient *gradient = (struct CGGradient *)gradientRef;
    if (!gradient)
        return;
    if (--gradient->refs > 0)
        return;
    free(gradient->components);
    free(gradient->locations);
    free(gradient);
}

void CGContextDrawLinearGradient(CGContextRef context, CGGradientRef gradientRef,
                                 CGPoint start, CGPoint end,
                                 unsigned options)
{
    (void)options;
    struct CGGradient *gradient = (struct CGGradient *)gradientRef;
    if (!context)
        context = g_current_context;
    if (!context || !gradient || gradient->count < 2)
        return;
    unsigned *colors = malloc(sizeof(unsigned) * gradient->count);
    unsigned char *alphas =
        malloc(sizeof(unsigned char) * gradient->count);
    if (!colors || !alphas)
    {
        free(colors);
        free(alphas);
        return;
    }
    for (unsigned i = 0; i < gradient->count; i++)
    {
        const double *c = gradient->components + i * 4;
        int r = (int)(cg_clamp(c[0]) * 255.0 + 0.5);
        int g = (int)(cg_clamp(c[1]) * 255.0 + 0.5);
        int b = (int)(cg_clamp(c[2]) * 255.0 + 0.5);
        colors[i] = ((unsigned)r << 16) | ((unsigned)g << 8) | (unsigned)b;
        alphas[i] = (unsigned char)(cg_clamp(c[3]) * 255.0 + 0.5);
    }
    double ax, ay, bx, by;
    cg_transform(context, start.x, start.y, &ax, &ay);
    cg_transform(context, end.x, end.y, &bx, &by);
    iosim_fb_set_opacity(context->base_alpha * context->state.alpha);
    iosim_fb_set_blend_mode(context->state.blend_mode);
    iosim_fb_fill_gradient_stops_alpha(
        context->x, context->y, context->w, context->h, colors, alphas,
        gradient->locations, (int)gradient->count, ax, ay, bx, by);
    iosim_fb_set_opacity(1.0);
    iosim_fb_set_blend_mode(kCGBlendModeNormal);
    free(colors);
    free(alphas);
}

void CGContextDrawRadialGradient(CGContextRef context, CGGradientRef gradientRef,
                                 CGPoint startCenter, double startRadius,
                                 CGPoint endCenter, double endRadius,
                                 unsigned options)
{
    (void)startRadius;
    (void)options;
    CGContextDrawLinearGradient(
        context, gradientRef, startCenter,
        CGPointMake(endCenter.x + endRadius, endCenter.y), 0);
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

static void cg_path_current_point(struct CGPath *path, double *x, double *y)
{
    int i = path ? path->count - 1 : -1;
    while (i >= 0 && path->ops[i] == 2)
        i--;
    if (i >= 0)
    {
        *x = path->xs[i];
        *y = path->ys[i];
    }
    else
    {
        *x = 0;
        *y = 0;
    }
}

void CGPathAddQuadCurveToPoint(CGPathRef pathRef, const void *transform,
                               double cpx, double cpy, double x, double y)
{
    (void)transform;
    struct CGPath *path = (struct CGPath *)pathRef;
    if (!path)
        return;
    double x0, y0;
    cg_path_current_point(path, &x0, &y0);
    int steps = iosim_cg_quad_segments(x0, y0, cpx, cpy, x, y);
    for (int i = 1; i <= steps; i++)
    {
        double t = (double)i / steps;
        double u = 1.0 - t;
        double px = u * u * x0 + 2 * u * t * cpx + t * t * x;
        double py = u * u * y0 + 2 * u * t * cpy + t * t * y;
        cg_path_append(path, 1, px, py);
    }
}

void CGPathAddCurveToPoint(CGPathRef pathRef, const void *transform,
                           double cp1x, double cp1y, double cp2x,
                           double cp2y, double x, double y)
{
    (void)transform;
    struct CGPath *path = (struct CGPath *)pathRef;
    if (!path)
        return;
    double x0, y0;
    cg_path_current_point(path, &x0, &y0);
    int steps = iosim_cg_cubic_segments(x0, y0, cp1x, cp1y, cp2x, cp2y, x, y);
    for (int i = 1; i <= steps; i++)
    {
        double t = (double)i / steps;
        double u = 1.0 - t;
        double px = u * u * u * x0 + 3 * u * u * t * cp1x +
                    3 * u * t * t * cp2x + t * t * t * x;
        double py = u * u * u * y0 + 3 * u * u * t * cp1y +
                    3 * u * t * t * cp2y + t * t * t * y;
        cg_path_append(path, 1, px, py);
    }
}

void CGPathAddArc(CGPathRef pathRef, const void *transform, double cx,
                  double cy, double radius, double startAngle,
                  double endAngle, int clockwise)
{
    (void)transform;
    struct CGPath *path = (struct CGPath *)pathRef;
    if (!path)
        return;
    double xs[CG_ARC_MAX_STEPS + 1];
    double ys[CG_ARC_MAX_STEPS + 1];
    int count = cg_arc_points(cx, cy, radius, startAngle, endAngle, clockwise,
                              xs, ys, CG_ARC_MAX_STEPS + 1);
    if (count <= 0)
        return;
    cg_path_append(path, path->count == 0 ? 0 : 1, xs[0], ys[0]);
    for (int i = 1; i < count; i++)
        cg_path_append(path, 1, xs[i], ys[i]);
}

void CGPathAddArcToPoint(CGPathRef pathRef, const void *transform, double x1,
                         double y1, double x2, double y2,
                         double radiusOfCorner)
{
    (void)transform;
    struct CGPath *path = (struct CGPath *)pathRef;
    if (!path)
        return;
    double x0, y0;
    cg_path_current_point(path, &x0, &y0);
    double tx1, ty1, tx2, ty2, cx, cy;
    int clockwise = 0;
    if (!cg_arc_to_params(x0, y0, x1, y1, x2, y2, radiusOfCorner,
                          &tx1, &ty1, &tx2, &ty2, &cx, &cy, &clockwise))
    {
        cg_path_append(path, 1, x1, y1);
        return;
    }
    cg_path_append(path, 1, tx1, ty1);
    double xs[CG_ARC_MAX_STEPS + 1];
    double ys[CG_ARC_MAX_STEPS + 1];
    double start = __builtin_atan2(ty1 - cy, tx1 - cx);
    double end = __builtin_atan2(ty2 - cy, tx2 - cx);
    int count = cg_arc_points(cx, cy, radiusOfCorner, start, end, clockwise,
                              xs, ys, CG_ARC_MAX_STEPS + 1);
    for (int i = 1; i < count; i++)
        cg_path_append(path, 1, xs[i], ys[i]);
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
