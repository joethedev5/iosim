#define _GNU_SOURCE
#include "framebuffer.h"
#include "font8x8_basic.h"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <errno.h>
#include <unistd.h>
#include <sys/stat.h>
#include <zlib.h>

/* Mirrors CGBlendMode from frameworks/coregraphics_lite.h; the loader does
 * not include framework headers. */
enum {
    kCGBlendModeNormal = 0,
    kCGBlendModeMultiply = 1,
    kCGBlendModeScreen = 2,
    kCGBlendModeOverlay = 3,
    kCGBlendModeDarken = 4,
    kCGBlendModeLighten = 5,
    kCGBlendModeColorDodge = 6,
    kCGBlendModeColorBurn = 7,
    kCGBlendModeHardLight = 8,
    kCGBlendModeSoftLight = 9,
    kCGBlendModeDifference = 10,
    kCGBlendModeExclusion = 11,
    kCGBlendModeHue = 12,
    kCGBlendModeSaturation = 13,
    kCGBlendModeColor = 14,
    kCGBlendModeLuminosity = 15,
    kCGBlendModeClear = 16,
    kCGBlendModeCopy = 17,
    kCGBlendModeSourceIn = 18,
    kCGBlendModeSourceOut = 19,
    kCGBlendModeSourceAtop = 20,
    kCGBlendModeDestinationOver = 21,
    kCGBlendModeDestinationIn = 22,
    kCGBlendModeDestinationOut = 23,
    kCGBlendModeDestinationAtop = 24,
    kCGBlendModeXOR = 25,
    kCGBlendModePlusDarker = 26,
    kCGBlendModePlusLighter = 27
};

static uint32_t *fb_pixels;
static double fb_opacity = 1.0;
static int fb_blend_mode;

void iosim_fb_set_blend_mode(int mode)
{
    fb_blend_mode = mode;
}

/* PDF blend functions used by CGBlendMode. All colour channels are
 * normalized to 0..1; the caller lerps the blended result over the
 * destination by the source alpha. */
static double fb_blend_lum(double r, double g, double b)
{
    return 0.3 * r + 0.59 * g + 0.11 * b;
}

static double fb_blend_sat(double r, double g, double b)
{
    double max = r > g ? r : g;
    if (b > max) max = b;
    double min = r < g ? r : g;
    if (b < min) min = b;
    return max - min;
}

static void fb_blend_clip(double *r, double *g, double *b)
{
    double l = fb_blend_lum(*r, *g, *b);
    double n = *r < *g ? *r : *g;
    if (*b < n) n = *b;
    double x = *r > *g ? *r : *g;
    if (*b > x) x = *b;
    if (n < 0)
    {
        double d = l - n;
        if (d > 0)
        {
            *r = l + (*r - l) * l / d;
            *g = l + (*g - l) * l / d;
            *b = l + (*b - l) * l / d;
        }
    }
    if (x > 1)
    {
        double d = x - l;
        if (d > 0)
        {
            *r = l + (*r - l) * (1 - l) / d;
            *g = l + (*g - l) * (1 - l) / d;
            *b = l + (*b - l) * (1 - l) / d;
        }
    }
}

static void fb_blend_set_lum(double *r, double *g, double *b, double l)
{
    double d = l - fb_blend_lum(*r, *g, *b);
    *r += d;
    *g += d;
    *b += d;
    fb_blend_clip(r, g, b);
}

static void fb_blend_set_sat(double *r, double *g, double *b, double s)
{
    double *low = r, *mid = g, *high = b;
    if (*low > *mid) { double *t = low; low = mid; mid = t; }
    if (*mid > *high) { double *t = mid; mid = high; high = t; }
    if (*low > *mid) { double *t = low; low = mid; mid = t; }
    if (*high > *low)
    {
        *mid = (*mid - *low) * s / (*high - *low);
        *high = s;
    }
    else
    {
        *mid = 0;
        *high = 0;
    }
    *low = 0;
}

static double fb_blend_channel(int mode, double s, double d)
{
    switch (mode)
    {
    case kCGBlendModeMultiply:
        return s * d;
    case kCGBlendModeScreen:
        return s + d - s * d;
    case kCGBlendModeOverlay:
        return d <= 0.5 ? 2.0 * s * d : 1.0 - 2.0 * (1.0 - s) * (1.0 - d);
    case kCGBlendModeDarken:
        return s < d ? s : d;
    case kCGBlendModeLighten:
        return s > d ? s : d;
    case kCGBlendModeColorDodge:
        if (d >= 0.999) return 1.0;
        return s / (1.0 - d) > 1.0 ? 1.0 : s / (1.0 - d);
    case kCGBlendModeColorBurn:
        if (d <= 0.001) return 0.0;
        return 1.0 - ((1.0 - s) / d > 1.0 ? 1.0 : (1.0 - s) / d);
    case kCGBlendModeHardLight:
        return s <= 0.5 ? 2.0 * s * d
                        : 1.0 - 2.0 * (1.0 - s) * (1.0 - d);
    case kCGBlendModeSoftLight:
    {
        if (s <= 0.5)
            return d - (1.0 - 2.0 * s) * d * (1.0 - d);
        double g = d <= 0.25 ? ((16.0 * d - 12.0) * d + 4.0) * d
                             : __builtin_sqrt(d);
        return d + (2.0 * s - 1.0) * (g - d);
    }
    case kCGBlendModeDifference:
        return s > d ? s - d : d - s;
    case kCGBlendModeExclusion:
        return s + d - 2.0 * s * d;
    default:
        return s;
    }
}

static void fb_blend_color(int mode, uint32_t src, uint32_t dst, double f,
                           unsigned *out_r, unsigned *out_g, unsigned *out_b)
{
    double s[3] = { ((src >> 16) & 0xFF) / 255.0,
                    ((src >> 8) & 0xFF) / 255.0,
                    (src & 0xFF) / 255.0 };
    double d[3] = { ((dst >> 16) & 0xFF) / 255.0,
                    ((dst >> 8) & 0xFF) / 255.0,
                    (dst & 0xFF) / 255.0 };
    double out[3];
    if (mode >= kCGBlendModeHue && mode <= kCGBlendModeLuminosity)
    {
        double r0 = s[0], g0 = s[1], b0 = s[2];
        double r1 = d[0], g1 = d[1], b1 = d[2];
        if (mode == kCGBlendModeHue)
        {
            fb_blend_set_sat(&r0, &g0, &b0, fb_blend_sat(r1, g1, b1));
            fb_blend_set_lum(&r0, &g0, &b0, fb_blend_lum(r1, g1, b1));
        }
        else if (mode == kCGBlendModeSaturation)
        {
            fb_blend_set_sat(&r1, &g1, &b1, fb_blend_sat(r0, g0, b0));
            fb_blend_set_lum(&r1, &g1, &b1, fb_blend_lum(d[0], d[1], d[2]));
        }
        else if (mode == kCGBlendModeColor)
        {
            fb_blend_set_lum(&r0, &g0, &b0, fb_blend_lum(r1, g1, b1));
        }
        else
        {
            fb_blend_set_lum(&r1, &g1, &b1, fb_blend_lum(r0, g0, b0));
        }
        if (mode == kCGBlendModeSaturation || mode == kCGBlendModeLuminosity)
        {
            out[0] = r1;
            out[1] = g1;
            out[2] = b1;
        }
        else
        {
            out[0] = r0;
            out[1] = g0;
            out[2] = b0;
        }
        for (int i = 0; i < 3; i++)
            out[i] = d[i] + (out[i] - d[i]) * f;
    }
    else if (mode == kCGBlendModeClear || mode == kCGBlendModeSourceOut)
    {
        for (int i = 0; i < 3; i++)
            out[i] = d[i] * (1.0 - f);
    }
    else if (mode == kCGBlendModeDestinationOver ||
             mode == kCGBlendModeDestinationAtop)
    {
        out[0] = d[0];
        out[1] = d[1];
        out[2] = d[2];
    }
    else if (mode == kCGBlendModeDestinationIn)
    {
        for (int i = 0; i < 3; i++)
            out[i] = d[i] * f;
    }
    else if (mode == kCGBlendModeDestinationOut || mode == kCGBlendModeXOR)
    {
        for (int i = 0; i < 3; i++)
            out[i] = d[i] * (1.0 - f);
    }
    else if (mode == kCGBlendModePlusDarker)
    {
        for (int i = 0; i < 3; i++)
        {
            double b = d[i] + s[i] - 1.0;
            if (b < 0) b = 0;
            out[i] = d[i] + (b - d[i]) * f;
        }
    }
    else if (mode == kCGBlendModePlusLighter)
    {
        for (int i = 0; i < 3; i++)
        {
            double b = d[i] + s[i];
            if (b > 1) b = 1;
            out[i] = d[i] + (b - d[i]) * f;
        }
    }
    else
    {
        for (int i = 0; i < 3; i++)
        {
            double v = d[i] + (fb_blend_channel(mode, s[i], d[i]) - d[i]) * f;
            out[i] = v < 0 ? 0 : (v > 1 ? 1 : v);
        }
    }
    *out_r = (unsigned)(out[0] * 255.0 + 0.5);
    *out_g = (unsigned)(out[1] * 255.0 + 0.5);
    *out_b = (unsigned)(out[2] * 255.0 + 0.5);
}

/* Offscreen targets store premultiplied ARGB so the result can be
 * composited with an arbitrary affine transform. In the normal (screen)
 * buffer the alpha byte is unused. */
static int fb_alpha;

static inline uint32_t fb_full(uint32_t color)
{
    return fb_alpha ? (0xFF000000u | color) : color;
}

static inline uint32_t fb_pack(uint32_t dst, unsigned r, unsigned g,
                               unsigned b, unsigned a)
{
    uint32_t rgb = (r << 16) | (g << 8) | b;
    if (!fb_alpha)
        return rgb;
    unsigned da = dst >> 24;
    unsigned oa = a + (unsigned)((da * (255u - a) + 127) / 255);
    if (oa > 255)
        oa = 255;
    return (oa << 24) | rgb;
}
static void fb_blend_pixel(int x, int y, uint32_t color, double coverage);
static unsigned fb_width;
static unsigned fb_height;

#define FB_MAX_CLIP 16
static int fb_clip_rects[FB_MAX_CLIP][4];
static int fb_clip_depth;
static uint8_t *fb_clip_mask;
static int fb_clip_mask_w;
static int fb_clip_mask_h;

#define FB_MAX_CLIP_MASKS 8
struct fb_mask_state {
    uint8_t *mask;
    int width, height;
};
static struct fb_mask_state fb_mask_stack[FB_MAX_CLIP_MASKS];
static int fb_mask_depth;

/* Active clip masks are 8-bit coverage values: 0 transparent, 255 opaque.
 * Polygon masks only produce 0/255; layer masks carry antialiased coverage. */
static int fb_mask_coverage(int x, int y)
{
    if (!fb_clip_mask)
        return 255;
    if (x < 0 || y < 0 || x >= fb_clip_mask_w || y >= fb_clip_mask_h)
        return 0;
    return fb_clip_mask[(size_t)y * fb_clip_mask_w + x];
}

int iosim_fb_push_clip_polygon(const double *xs, const double *ys, int count)
{
    if (!fb_pixels || count < 3 || fb_mask_depth >= FB_MAX_CLIP_MASKS)
        return 0;
    int width = (int)fb_width, height = (int)fb_height;
    if (width <= 0 || height <= 0)
        return 0;
    uint8_t *mask = calloc((size_t)width * height, 1);
    double *crossings = malloc(sizeof(double) * (size_t)count);
    if (!mask || !crossings)
    {
        free(mask);
        free(crossings);
        return 0;
    }
    for (int y = 0; y < height; y++)
    {
        double scan = y + 0.5;
        int n = 0;
        for (int i = 0, j = count - 1; i < count; j = i++)
        {
            double yi = ys[i], yj = ys[j];
            if ((yi > scan) == (yj > scan))
                continue;
            double xi = xs[i], xj = xs[j];
            crossings[n++] = xi + (scan - yi) * (xj - xi) / (yj - yi);
        }
        for (int a = 1; a < n; a++)
        {
            double key = crossings[a];
            int b = a - 1;
            while (b >= 0 && crossings[b] > key)
            {
                crossings[b + 1] = crossings[b];
                b--;
            }
            crossings[b + 1] = key;
        }
        uint8_t *row = mask + (size_t)y * width;
        for (int a = 0; a + 1 < n; a += 2)
        {
            int x0 = (int)(crossings[a] + 0.5);
            int x1 = (int)(crossings[a + 1] + 0.5);
            if (x0 < 0) x0 = 0;
            if (x1 > width) x1 = width;
            for (int x = x0; x < x1; x++)
                row[x] = 255;
        }
    }
    free(crossings);
    if (fb_clip_mask && fb_clip_mask_w == width && fb_clip_mask_h == height)
    {
        for (size_t i = 0; i < (size_t)width * height; i++)
            mask[i] &= fb_clip_mask[i];
    }
    struct fb_mask_state *state = &fb_mask_stack[fb_mask_depth++];
    state->mask = fb_clip_mask;
    state->width = fb_clip_mask_w;
    state->height = fb_clip_mask_h;
    fb_clip_mask = mask;
    fb_clip_mask_w = width;
    fb_clip_mask_h = height;
    return 1;
}

void iosim_fb_pop_clip_mask(void)
{
    if (fb_mask_depth <= 0)
        return;
    free(fb_clip_mask);
    struct fb_mask_state *state = &fb_mask_stack[--fb_mask_depth];
    fb_clip_mask = state->mask;
    fb_clip_mask_w = state->width;
    fb_clip_mask_h = state->height;
}

int iosim_fb_push_clip_alpha(const uint8_t *alpha, int w, int h, int x, int y)
{
    if (!fb_pixels || !alpha || w <= 0 || h <= 0 ||
        fb_mask_depth >= FB_MAX_CLIP_MASKS)
        return 0;
    int width = (int)fb_width, height = (int)fb_height;
    if (width <= 0 || height <= 0)
        return 0;
    uint8_t *mask = calloc((size_t)width * height, 1);
    if (!mask)
        return 0;
    int x0 = x < 0 ? 0 : x, y0 = y < 0 ? 0 : y;
    int x1 = x + w > width ? width : x + w;
    int y1 = y + h > height ? height : y + h;
    int same = fb_clip_mask && fb_clip_mask_w == width &&
               fb_clip_mask_h == height;
    for (int yy = y0; yy < y1; yy++)
    {
        uint8_t *row = mask + (size_t)yy * width;
        const uint8_t *src = alpha + (size_t)(yy - y) * w;
        for (int xx = x0; xx < x1; xx++)
        {
            unsigned a = src[xx - x];
            if (!a)
                continue;
            if (same)
                a = (a * fb_clip_mask[(size_t)yy * width + xx] + 127) / 255;
            row[xx] = (uint8_t)a;
        }
    }
    struct fb_mask_state *state = &fb_mask_stack[fb_mask_depth++];
    state->mask = fb_clip_mask;
    state->width = fb_clip_mask_w;
    state->height = fb_clip_mask_h;
    fb_clip_mask = mask;
    fb_clip_mask_w = width;
    fb_clip_mask_h = height;
    return 1;
}

static void fb_reset_clip_masks(void)
{
    free(fb_clip_mask);
    fb_clip_mask = NULL;
    fb_clip_mask_w = fb_clip_mask_h = 0;
    while (fb_mask_depth > 0)
        free(fb_mask_stack[--fb_mask_depth].mask);
}

static void fb_clip_reset(void)
{
    fb_clip_depth = 0;
    fb_clip_rects[0][0] = 0;
    fb_clip_rects[0][1] = 0;
    fb_clip_rects[0][2] = (int)fb_width;
    fb_clip_rects[0][3] = (int)fb_height;
}

int iosim_fb_push_clip(int x, int y, int w, int h)
{
    if (fb_clip_depth + 1 >= FB_MAX_CLIP)
        return 0;
    int *cur = fb_clip_rects[fb_clip_depth];
    int *next = fb_clip_rects[fb_clip_depth + 1];
    next[0] = x > cur[0] ? x : cur[0];
    next[1] = y > cur[1] ? y : cur[1];
    int x1 = x + w < cur[2] ? x + w : cur[2];
    int y1 = y + h < cur[3] ? y + h : cur[3];
    next[2] = x1 > next[0] ? x1 : next[0];
    next[3] = y1 > next[1] ? y1 : next[1];
    fb_clip_depth++;
    return 1;
}

void iosim_fb_pop_clip(void)
{
    if (fb_clip_depth > 0)
        fb_clip_depth--;
}

static int fb_clip_x0(void) { return fb_clip_rects[fb_clip_depth][0]; }
static int fb_clip_y0(void) { return fb_clip_rects[fb_clip_depth][1]; }
static int fb_clip_x1(void) { return fb_clip_rects[fb_clip_depth][2]; }
static int fb_clip_y1(void) { return fb_clip_rects[fb_clip_depth][3]; }

int iosim_fb_begin(unsigned width, unsigned height)
{
    if (width == 0 || height == 0 || width > 8192 || height > 8192)
        return -1;
    uint32_t *pixels = calloc((size_t)width * height, sizeof(uint32_t));
    if (!pixels)
        return -1;
    free(fb_pixels);
    fb_pixels = pixels;
    fb_width = width;
    fb_height = height;
    fb_clip_reset();
    fb_reset_clip_masks();
    return 0;
}

void iosim_fb_release(void)
{
    free(fb_pixels);
    fb_pixels = NULL;
    fb_width = fb_height = 0;
    fb_reset_clip_masks();
}

/* --------------------------------------------------- offscreen targets */

#define FB_STATE_STACK 4

struct fb_saved_state {
    uint32_t *pixels;
    unsigned width, height;
    int clip_depth;
    int clip[FB_MAX_CLIP][4];
    double opacity;
    int alpha;
    uint8_t *mask;
    int mask_width, mask_height;
    uint32_t *owned_pixels;
    unsigned owned_width, owned_height;
};

static struct fb_saved_state *fb_saved[FB_STATE_STACK];
static int fb_saved_depth;

void *iosim_fb_begin_offscreen(unsigned width, unsigned height)
{
    if (fb_saved_depth >= FB_STATE_STACK || width == 0 || height == 0 ||
        width > 4096 || height > 4096)
        return NULL;
    struct fb_saved_state *st = calloc(1, sizeof *st);
    if (!st)
        return NULL;
    st->pixels = fb_pixels;
    st->width = fb_width;
    st->height = fb_height;
    st->clip_depth = fb_clip_depth;
    for (int i = 0; i < FB_MAX_CLIP; i++)
        for (int k = 0; k < 4; k++)
            st->clip[i][k] = fb_clip_rects[i][k];
    st->opacity = fb_opacity;
    st->alpha = fb_alpha;
    st->mask = fb_clip_mask;
    st->mask_width = fb_clip_mask_w;
    st->mask_height = fb_clip_mask_h;
    uint32_t *buf = calloc((size_t)width * height, sizeof(uint32_t));
    if (!buf)
    {
        free(st);
        return NULL;
    }
    st->owned_pixels = buf;
    st->owned_width = width;
    st->owned_height = height;
    fb_saved[fb_saved_depth++] = st;
    fb_pixels = buf;
    fb_width = width;
    fb_height = height;
    fb_clip_reset();
    fb_opacity = 1.0;
    fb_alpha = 1;
    fb_clip_mask = NULL;
    fb_clip_mask_w = fb_clip_mask_h = 0;
    return st;
}

uint32_t *iosim_fb_end_offscreen(void *state, int *out_w, int *out_h)
{
    if (!state || fb_saved_depth <= 0)
        return NULL;
    struct fb_saved_state *st = fb_saved[--fb_saved_depth];
    uint32_t *buf = st->owned_pixels;
    if (out_w) *out_w = (int)fb_width;
    if (out_h) *out_h = (int)fb_height;
    fb_pixels = st->pixels;
    fb_width = st->width;
    fb_height = st->height;
    fb_clip_depth = st->clip_depth;
    for (int i = 0; i < FB_MAX_CLIP; i++)
        for (int k = 0; k < 4; k++)
            fb_clip_rects[i][k] = st->clip[i][k];
    fb_opacity = st->opacity;
    fb_alpha = st->alpha;
    fb_clip_mask = st->mask;
    fb_clip_mask_w = st->mask_width;
    fb_clip_mask_h = st->mask_height;
    free(st);
    return buf;
}

uint32_t *iosim_fb_offscreen_pixels(void *state, int *out_w, int *out_h)
{
    struct fb_saved_state *st = state;
    if (!st)
        return NULL;
    if (out_w) *out_w = (int)st->owned_width;
    if (out_h) *out_h = (int)st->owned_height;
    return st->owned_pixels;
}

static struct fb_saved_state *fb_snapshot_target(void)
{
    struct fb_saved_state *st = calloc(1, sizeof *st);
    if (!st)
        return NULL;
    st->pixels = fb_pixels;
    st->width = fb_width;
    st->height = fb_height;
    st->clip_depth = fb_clip_depth;
    for (int i = 0; i < FB_MAX_CLIP; i++)
        for (int k = 0; k < 4; k++)
            st->clip[i][k] = fb_clip_rects[i][k];
    st->opacity = fb_opacity;
    st->alpha = fb_alpha;
    st->mask = fb_clip_mask;
    st->mask_width = fb_clip_mask_w;
    st->mask_height = fb_clip_mask_h;
    return st;
}

void *iosim_fb_activate_offscreen(void *state)
{
    struct fb_saved_state *st = state;
    if (!st || !st->owned_pixels)
        return NULL;
    struct fb_saved_state *saved = fb_snapshot_target();
    if (!saved)
        return NULL;
    fb_pixels = st->owned_pixels;
    fb_width = st->owned_width;
    fb_height = st->owned_height;
    fb_clip_reset();
    fb_opacity = 1.0;
    fb_alpha = 1;
    fb_clip_mask = NULL;
    fb_clip_mask_w = fb_clip_mask_h = 0;
    return saved;
}

void iosim_fb_restore_target(void *state)
{
    struct fb_saved_state *st = state;
    if (!st)
        return;
    fb_pixels = st->pixels;
    fb_width = st->width;
    fb_height = st->height;
    fb_clip_depth = st->clip_depth;
    for (int i = 0; i < FB_MAX_CLIP; i++)
        for (int k = 0; k < 4; k++)
            fb_clip_rects[i][k] = st->clip[i][k];
    fb_opacity = st->opacity;
    fb_alpha = st->alpha;
    fb_clip_mask = st->mask;
    fb_clip_mask_w = st->mask_width;
    fb_clip_mask_h = st->mask_height;
    free(st);
}

void iosim_fb_free_offscreen(uint32_t *buf)
{
    free(buf);
}

static uint32_t field_sample(const uint32_t *grid, int gw, int gh,
                             double u, double v)
{
    double fx = u * gw - 0.5, fy = v * gh - 0.5;
    int x0 = (int)__builtin_floor(fx), y0 = (int)__builtin_floor(fy);
    double tx = fx - x0, ty = fy - y0;
    int x1 = x0 + 1, y1 = y0 + 1;
    if (x0 < 0) x0 = 0;
    if (x0 >= gw) x0 = gw - 1;
    if (x1 < 0) x1 = 0;
    if (x1 >= gw) x1 = gw - 1;
    if (y0 < 0) y0 = 0;
    if (y0 >= gh) y0 = gh - 1;
    if (y1 < 0) y1 = 0;
    if (y1 >= gh) y1 = gh - 1;
    uint32_t c00 = grid[y0 * gw + x0], c10 = grid[y0 * gw + x1];
    uint32_t c01 = grid[y1 * gw + x0], c11 = grid[y1 * gw + x1];
    unsigned r = (unsigned)((((c00 >> 16) & 0xFF) * (1 - tx) +
                             ((c10 >> 16) & 0xFF) * tx) * (1 - ty) +
                            (((c01 >> 16) & 0xFF) * (1 - tx) +
                             ((c11 >> 16) & 0xFF) * tx) * ty + 0.5);
    unsigned g = (unsigned)((((c00 >> 8) & 0xFF) * (1 - tx) +
                             ((c10 >> 8) & 0xFF) * tx) * (1 - ty) +
                            (((c01 >> 8) & 0xFF) * (1 - tx) +
                             ((c11 >> 8) & 0xFF) * tx) * ty + 0.5);
    unsigned b = (unsigned)(((c00 & 0xFF) * (1 - tx) + (c10 & 0xFF) * tx) *
                                (1 - ty) +
                            ((c01 & 0xFF) * (1 - tx) + (c11 & 0xFF) * tx) *
                                ty + 0.5);
    return (r << 16) | (g << 8) | b;
}

/* Apple's icon mask is a continuous-corner squircle; a superellipse with
 * exponent 5 matches the captured boundary to a fraction of a pixel. */
static double squircle_coverage(double u, double v, double rx)
{
    double au = __builtin_fabs(u), av = __builtin_fabs(v);
    double au2 = au * au, av2 = av * av;
    double sum = au2 * au2 * au + av2 * av2 * av;
    double d = (sum - 1.0) * rx / 5.0;
    return 0.5 - d;
}

void iosim_fb_fill_squircle(int x, int y, int w, int h, uint32_t color)
{
    if (!fb_pixels || w <= 0 || h <= 0)
        return;
    double cx = x + w / 2.0, cy = y + h / 2.0;
    double rx = w / 2.0, ry = h / 2.0;
    int fg_r = (color >> 16) & 0xFF, fg_g = (color >> 8) & 0xFF,
        fg_b = color & 0xFF;
    for (int yy = y; yy < y + h; yy++)
    {
        if (yy < fb_clip_y0() || yy >= fb_clip_y1())
            continue;
        uint32_t *row = fb_pixels + (size_t)yy * fb_width;
        double v = (yy + 0.5 - cy) / ry;
        for (int xx = x; xx < x + w; xx++)
        {
            if (xx < fb_clip_x0() || xx >= fb_clip_x1())
                continue;
            double u = (xx + 0.5 - cx) / rx;
            double coverage = squircle_coverage(u, v, rx) * fb_opacity;
            if (coverage <= 0)
                continue;
            if (coverage > fb_opacity)
                coverage = fb_opacity;
            if (coverage >= 1)
            {
                row[xx] = fb_full(color);
                continue;
            }
            unsigned a = (unsigned)(coverage * 255.0 + 0.5);
            uint32_t dst = row[xx];
            unsigned r = (fg_r * a + ((dst >> 16) & 0xFF) * (255 - a) + 127) / 255;
            unsigned g = (fg_g * a + ((dst >> 8) & 0xFF) * (255 - a) + 127) / 255;
            unsigned b = (fg_b * a + (dst & 0xFF) * (255 - a) + 127) / 255;
            row[xx] = fb_pack(dst, r, g, b, a);
        }
    }
}

void iosim_fb_fill_squircle_gradient(int x, int y, int w, int h,
                                     uint32_t top, uint32_t bottom)
{
    if (!fb_pixels || w <= 0 || h <= 0)
        return;
    double cx = x + w / 2.0, cy = y + h / 2.0;
    double rx = w / 2.0, ry = h / 2.0;
    int tr = (top >> 16) & 0xFF, tg = (top >> 8) & 0xFF, tb = top & 0xFF;
    int br = (bottom >> 16) & 0xFF, bg2 = (bottom >> 8) & 0xFF,
        bb = bottom & 0xFF;
    for (int yy = y; yy < y + h; yy++)
    {
        if (yy < fb_clip_y0() || yy >= fb_clip_y1())
            continue;
        uint32_t *row = fb_pixels + (size_t)yy * fb_width;
        double v = (yy + 0.5 - cy) / ry;
        double t = (yy + 0.5 - y) / h;
        if (t < 0) t = 0;
        if (t > 1) t = 1;
        unsigned fr = (unsigned)(tr + (br - tr) * t + 0.5);
        unsigned fg = (unsigned)(tg + (bg2 - tg) * t + 0.5);
        unsigned fb = (unsigned)(tb + (bb - tb) * t + 0.5);
        for (int xx = x; xx < x + w; xx++)
        {
            if (xx < fb_clip_x0() || xx >= fb_clip_x1())
                continue;
            double u = (xx + 0.5 - cx) / rx;
            double coverage = squircle_coverage(u, v, rx) * fb_opacity;
            if (coverage <= 0)
                continue;
            if (coverage > fb_opacity)
                coverage = fb_opacity;
            if (coverage >= 1)
            {
                row[xx] = fb_full((fr << 16) | (fg << 8) | fb);
                continue;
            }
            unsigned a = (unsigned)(coverage * 255.0 + 0.5);
            uint32_t dst = row[xx];
            unsigned r = (fr * a + ((dst >> 16) & 0xFF) * (255 - a) + 127) / 255;
            unsigned g = (fg * a + ((dst >> 8) & 0xFF) * (255 - a) + 127) / 255;
            unsigned b = (fb * a + (dst & 0xFF) * (255 - a) + 127) / 255;
            row[xx] = fb_pack(dst, r, g, b, a);
        }
    }
}

void iosim_fb_fill_field(int x, int y, int w, int h, int radius,
                         const uint32_t *grid, int gw, int gh)
{
    if (!fb_pixels || !grid || gw <= 0 || gh <= 0 || w <= 0 || h <= 0)
        return;
    if (radius > w / 2) radius = w / 2;
    if (radius > h / 2) radius = h / 2;
    double cx = x + w / 2.0, cy = y + h / 2.0;
    double ex = w / 2.0 - radius, ey = h / 2.0 - radius;
    for (int yy = y; yy < y + h; yy++)
    {
        double py = yy + 0.5 - cy;
        double qy = __builtin_fabs(py) - ey;
        for (int xx = x; xx < x + w; xx++)
        {
            if (xx < fb_clip_x0() || xx >= fb_clip_x1() ||
                yy < fb_clip_y0() || yy >= fb_clip_y1())
                continue;
            double px = xx + 0.5 - cx;
            double qx = __builtin_fabs(px) - ex;
            double ax = qx > 0 ? qx : 0, ay = qy > 0 ? qy : 0;
            double outside = __builtin_sqrt(ax * ax + ay * ay);
            double inside = qx > qy ? qx : qy;
            double d = outside + (inside < 0 ? inside : 0) - radius;
            double coverage = 0.5 - d;
            if (coverage <= 0)
                continue;
            if (coverage > 1)
                coverage = 1;
            uint32_t c = field_sample(grid, gw, gh, (xx + 0.5 - x) / w,
                                      (yy + 0.5 - y) / h);
            fb_blend_pixel(xx, yy, c, coverage);
        }
    }
}

void iosim_fb_paste_xrgb(const uint32_t *src)
{
    if (!fb_pixels || !src)
        return;
    size_t n = (size_t)fb_width * fb_height;
    for (size_t i = 0; i < n; i++)
        fb_pixels[i] = src[i];
}

/* Copy a rectangle of the current render target (the framebuffer or an
 * offscreen pass) for backdrop effects; out-of-bounds pixels are zero. */
void iosim_fb_capture(int x, int y, int w, int h, uint32_t *out)
{
    if (!fb_pixels || !out || w <= 0 || h <= 0)
        return;
    for (int yy = 0; yy < h; yy++)
    {
        int sy = y + yy;
        for (int xx = 0; xx < w; xx++)
        {
            int sx = x + xx;
            uint32_t c = 0;
            if (sx >= 0 && sx < (int)fb_width && sy >= 0 &&
                sy < (int)fb_height)
                c = fb_pixels[(size_t)sy * fb_width + sx];
            out[(size_t)yy * w + xx] = c;
        }
    }
}

void iosim_fb_blit_xrgb_scaled(const uint32_t *src, int sw, int sh,
                               int x, int y, int w, int h, double opacity)
{
    if (!fb_pixels || !src || sw <= 0 || sh <= 0 || w <= 0 || h <= 0)
        return;
    if (w == sw && h == sh)
    {
        for (int yy = 0; yy < h; yy++)
        {
            int dy = y + yy;
            if (dy < fb_clip_y0() || dy >= fb_clip_y1())
                continue;
            uint32_t *row = fb_pixels + (size_t)dy * fb_width;
            const uint32_t *srow = src + (size_t)yy * sw;
            for (int xx = 0; xx < w; xx++)
            {
                int dx = x + xx;
                if (dx < fb_clip_x0() || dx >= fb_clip_x1())
                    continue;
                row[dx] = srow[xx];
            }
        }
        return;
    }
    for (int yy = 0; yy < h; yy++)
    {
        int dy = y + yy;
        if (dy < fb_clip_y0() || dy >= fb_clip_y1())
            continue;
        double fy = ((yy + 0.5) * sh / h) - 0.5;
        int y0 = (int)__builtin_floor(fy);
        double ty = fy - y0;
        int y0c = y0 < 0 ? 0 : (y0 >= sh ? sh - 1 : y0);
        int y1c = y0 + 1 < 0 ? 0 : (y0 + 1 >= sh ? sh - 1 : y0 + 1);
        uint32_t *row = fb_pixels + (size_t)dy * fb_width;
        for (int xx = 0; xx < w; xx++)
        {
            int dx = x + xx;
            if (dx < fb_clip_x0() || dx >= fb_clip_x1())
                continue;
            double fx = ((xx + 0.5) * sw / w) - 0.5;
            int x0 = (int)__builtin_floor(fx);
            double tx = fx - x0;
            int x0c = x0 < 0 ? 0 : (x0 >= sw ? sw - 1 : x0);
            int x1c = x0 + 1 < 0 ? 0 : (x0 + 1 >= sw ? sw - 1 : x0 + 1);
            uint32_t p00 = src[(size_t)y0c * sw + x0c];
            uint32_t p10 = src[(size_t)y0c * sw + x1c];
            uint32_t p01 = src[(size_t)y1c * sw + x0c];
            uint32_t p11 = src[(size_t)y1c * sw + x1c];
            unsigned r = (unsigned)((((p00 >> 16) & 0xFF) * (1 - tx) + ((p10 >> 16) & 0xFF) * tx) * (1 - ty) + (((p01 >> 16) & 0xFF) * (1 - tx) + ((p11 >> 16) & 0xFF) * tx) * ty + 0.5);
            unsigned g = (unsigned)((((p00 >> 8) & 0xFF) * (1 - tx) + ((p10 >> 8) & 0xFF) * tx) * (1 - ty) + (((p01 >> 8) & 0xFF) * (1 - tx) + ((p11 >> 8) & 0xFF) * tx) * ty + 0.5);
            unsigned b = (unsigned)(((p00 & 0xFF) * (1 - tx) + (p10 & 0xFF) * tx) * (1 - ty) + ((p01 & 0xFF) * (1 - tx) + (p11 & 0xFF) * tx) * ty + 0.5);
            if (opacity < 0.999)
            {
                uint32_t dst = row[dx];
                r = (unsigned)(r * opacity + ((dst >> 16) & 0xFF) * (1 - opacity) + 0.5);
                g = (unsigned)(g * opacity + ((dst >> 8) & 0xFF) * (1 - opacity) + 0.5);
                b = (unsigned)(b * opacity + (dst & 0xFF) * (1 - opacity) + 0.5);
            }
            row[dx] = (r << 16) | (g << 8) | b;
        }
    }
}

/* Multiply the alpha of an offscreen layer by a rounded-rect mask. The
 * colour channels are left untouched, so compositing the layer later
 * produces the same antialiased edge the shape would have drawn. */
void iosim_fb_mask_round_rect_corners(int x, int y, int w, int h,
                                      int radius, unsigned corners)
{
    if (!fb_pixels || !fb_alpha || w <= 0 || h <= 0)
        return;
    if (radius < 0) radius = 0;
    if (radius * 2 > w) radius = w / 2;
    if (radius * 2 > h) radius = h / 2;
    double cx = x + w / 2.0, cy = y + h / 2.0;
    double exr = w / 2.0 - radius, eyr = h / 2.0 - radius;
    for (int yy = 0; yy < (int)fb_height; yy++)
    {
        uint32_t *row = fb_pixels + (size_t)yy * fb_width;
        double py = yy + 0.5 - cy;
        double qy = __builtin_fabs(py) - eyr;
        for (int xx = 0; xx < (int)fb_width; xx++)
        {
            double px = xx + 0.5 - cx;
            /* Corner bits: 1 top-left, 2 top-right, 4 bottom-left,
             * 8 bottom-right. Unselected corners keep square alpha. */
            unsigned corner = py < 0
                ? (px < 0 ? 1u : 2u)
                : (px < 0 ? 4u : 8u);
            if (!(corners & corner))
                continue;
            double qx = __builtin_fabs(px) - exr;
            double axr = qx > 0 ? qx : 0, ayr = qy > 0 ? qy : 0;
            double outside = __builtin_sqrt(axr * axr + ayr * ayr);
            double inside = qx > qy ? qx : qy;
            double d = outside + (inside < 0 ? inside : 0) - radius;
            double coverage = 0.5 - d;
            if (coverage <= 0)
            {
                row[xx] = 0;
                continue;
            }
            if (coverage >= 1)
                continue;
            unsigned a = row[xx] >> 24;
            unsigned na = (unsigned)(a * coverage + 0.5);
            if (na > 255) na = 255;
            row[xx] = (na << 24) | (row[xx] & 0x00FFFFFFu);
        }
    }
}

void iosim_fb_mask_round_rect(int x, int y, int w, int h, int radius)
{
    iosim_fb_mask_round_rect_corners(x, y, w, h, radius, 15u);
}

void iosim_fb_blit_affine(const uint32_t *src, int sw, int sh,
                          double fa, double fb, double fc, double f_d,
                          double ftx, double fty, double opacity)
{
    if (!fb_pixels || !src || sw <= 0 || sh <= 0 || opacity <= 0)
        return;
    double det = fa * f_d - fb * fc;
    if (__builtin_fabs(det) < 1e-12)
        return;
    /* Inverse of the forward affine, for destination -> source lookups. */
    double ia = f_d / det, ib = -fb / det;
    double ic = -fc / det, id = fa / det;
    double itx = -(ia * ftx + ic * fty);
    double ity = -(ib * ftx + id * fty);
    double corners_x[4] = {0, sw, 0, sw};
    double corners_y[4] = {0, 0, sh, sh};
    double minx = 1e18, maxx = -1e18, miny = 1e18, maxy = -1e18;
    for (int i = 0; i < 4; i++)
    {
        double X = fa * corners_x[i] + fc * corners_y[i] + ftx;
        double Y = fb * corners_x[i] + f_d * corners_y[i] + fty;
        if (X < minx) minx = X;
        if (X > maxx) maxx = X;
        if (Y < miny) miny = Y;
        if (Y > maxy) maxy = Y;
    }
    int x0 = (int)__builtin_floor(minx), x1 = (int)__builtin_ceil(maxx);
    int y0 = (int)__builtin_floor(miny), y1 = (int)__builtin_ceil(maxy);
    if (x0 < 0) x0 = 0;
    if (y0 < 0) y0 = 0;
    if (x1 > (int)fb_width) x1 = (int)fb_width;
    if (y1 > (int)fb_height) y1 = (int)fb_height;
    for (int y = y0; y < y1; y++)
    {
        if (y < fb_clip_y0() || y >= fb_clip_y1())
            continue;
        uint32_t *row = fb_pixels + (size_t)y * fb_width;
        double Y = y + 0.5;
        for (int x = x0; x < x1; x++)
        {
            if (x < fb_clip_x0() || x >= fb_clip_x1())
                continue;
            int mcov = fb_mask_coverage(x, y);
            if (!mcov)
                continue;
            double X = x + 0.5;
            double u = ia * X + ic * Y + itx - 0.5;
            double v = ib * X + id * Y + ity - 0.5;
            if (u < -1.0 || v < -1.0 || u > sw || v > sh)
                continue;
            int u0 = (int)__builtin_floor(u), v0 = (int)__builtin_floor(v);
            double tu = u - u0, tv = v - v0;
            int u1 = u0 + 1, v1 = v0 + 1;
            int u0c = u0 < 0 ? 0 : (u0 >= sw ? sw - 1 : u0);
            int u1c = u1 < 0 ? 0 : (u1 >= sw ? sw - 1 : u1);
            int v0c = v0 < 0 ? 0 : (v0 >= sh ? sh - 1 : v0);
            int v1c = v1 < 0 ? 0 : (v1 >= sh ? sh - 1 : v1);
            uint32_t p00 = src[(size_t)v0c * sw + u0c];
            uint32_t p10 = src[(size_t)v0c * sw + u1c];
            uint32_t p01 = src[(size_t)v1c * sw + u0c];
            uint32_t p11 = src[(size_t)v1c * sw + u1c];
            double w00 = (1 - tu) * (1 - tv), w10 = tu * (1 - tv);
            double w01 = (1 - tu) * tv, w11 = tu * tv;
            double a00 = (p00 >> 24) & 0xFF, a10 = (p10 >> 24) & 0xFF,
                   a01 = (p01 >> 24) & 0xFF, a11 = (p11 >> 24) & 0xFF;
            double sa = a00 * w00 + a10 * w10 + a01 * w01 + a11 * w11;
            if (sa <= 0.5)
                continue;
            /* Weight colour by alpha so transparent neighbours do not bleed
             * black into the edge of a composited layer. */
            double sr = (((p00 >> 16) & 0xFF) * a00 * w00 +
                         ((p10 >> 16) & 0xFF) * a10 * w10 +
                         ((p01 >> 16) & 0xFF) * a01 * w01 +
                         ((p11 >> 16) & 0xFF) * a11 * w11) / sa;
            double sg = (((p00 >> 8) & 0xFF) * a00 * w00 +
                         ((p10 >> 8) & 0xFF) * a10 * w10 +
                         ((p01 >> 8) & 0xFF) * a01 * w01 +
                         ((p11 >> 8) & 0xFF) * a11 * w11) / sa;
            double sb = ((p00 & 0xFF) * a00 * w00 + (p10 & 0xFF) * a10 * w10 +
                         (p01 & 0xFF) * a01 * w01 +
                         (p11 & 0xFF) * a11 * w11) / sa;
            double f = (sa / 255.0) * opacity * (mcov / 255.0);
            if (f <= 0.0005)
                continue;
            uint32_t dst = row[x];
            unsigned dr = (dst >> 16) & 0xFF, dg = (dst >> 8) & 0xFF,
                     db = dst & 0xFF;
            unsigned r = (unsigned)(sr * f + dr * (1 - f) + 0.5);
            unsigned g = (unsigned)(sg * f + dg * (1 - f) + 0.5);
            unsigned b = (unsigned)(sb * f + db * (1 - f) + 0.5);
            if (fb_alpha)
            {
                unsigned da = dst >> 24;
                unsigned oa = (unsigned)(sa * opacity + da * (1 - f) + 0.5);
                if (oa > 255) oa = 255;
                row[x] = (oa << 24) | (r << 16) | (g << 8) | b;
            }
            else
                row[x] = (r << 16) | (g << 8) | b;
        }
    }
}

void iosim_fb_blit_homography(const uint32_t *src, int sw, int sh,
                              double h11, double h12, double h13,
                              double h21, double h22, double h23,
                              double h31, double h32, double h33,
                              double opacity)
{
    if (!fb_pixels || !src || sw <= 0 || sh <= 0 || opacity <= 0)
        return;
    double det = h11 * (h22 * h33 - h23 * h32) -
                 h12 * (h21 * h33 - h23 * h31) +
                 h13 * (h21 * h32 - h22 * h31);
    if (__builtin_fabs(det) < 1e-12)
        return;
    double i11 = (h22 * h33 - h23 * h32) / det;
    double i12 = (h13 * h32 - h12 * h33) / det;
    double i13 = (h12 * h23 - h13 * h22) / det;
    double i21 = (h23 * h31 - h21 * h33) / det;
    double i22 = (h11 * h33 - h13 * h31) / det;
    double i23 = (h13 * h21 - h11 * h23) / det;
    double i31 = (h21 * h32 - h22 * h31) / det;
    double i32 = (h12 * h31 - h11 * h32) / det;
    double i33 = (h11 * h22 - h12 * h21) / det;
    double corners_x[4] = {0, sw, 0, sw};
    double corners_y[4] = {0, 0, sh, sh};
    double minx = 1e18, maxx = -1e18, miny = 1e18, maxy = -1e18;
    for (int i = 0; i < 4; i++)
    {
        double W = h31 * corners_x[i] + h32 * corners_y[i] + h33;
        if (W <= 1e-9)
            continue;
        double X = (h11 * corners_x[i] + h12 * corners_y[i] + h13) / W;
        double Y = (h21 * corners_x[i] + h22 * corners_y[i] + h23) / W;
        if (X < minx) minx = X;
        if (X > maxx) maxx = X;
        if (Y < miny) miny = Y;
        if (Y > maxy) maxy = Y;
    }
    if (minx > maxx || miny > maxy)
        return;
    int x0 = (int)__builtin_floor(minx), x1 = (int)__builtin_ceil(maxx);
    int y0 = (int)__builtin_floor(miny), y1 = (int)__builtin_ceil(maxy);
    if (x0 < 0) x0 = 0;
    if (y0 < 0) y0 = 0;
    if (x1 > (int)fb_width) x1 = (int)fb_width;
    if (y1 > (int)fb_height) y1 = (int)fb_height;
    for (int y = y0; y < y1; y++)
    {
        if (y < fb_clip_y0() || y >= fb_clip_y1())
            continue;
        uint32_t *row = fb_pixels + (size_t)y * fb_width;
        double Y = y + 0.5;
        for (int x = x0; x < x1; x++)
        {
            if (x < fb_clip_x0() || x >= fb_clip_x1())
                continue;
            int mcov = fb_mask_coverage(x, y);
            if (!mcov)
                continue;
            double X = x + 0.5;
            double denom = i31 * X + i32 * Y + i33;
            if (__builtin_fabs(denom) < 1e-12)
                continue;
            double u = (i11 * X + i12 * Y + i13) / denom - 0.5;
            double v = (i21 * X + i22 * Y + i23) / denom - 0.5;
            if (u < -1.0 || v < -1.0 || u > sw || v > sh)
                continue;
            int u0 = (int)__builtin_floor(u), v0 = (int)__builtin_floor(v);
            double tu = u - u0, tv = v - v0;
            int u1 = u0 + 1, v1 = v0 + 1;
            int u0c = u0 < 0 ? 0 : (u0 >= sw ? sw - 1 : u0);
            int u1c = u1 < 0 ? 0 : (u1 >= sw ? sw - 1 : u1);
            int v0c = v0 < 0 ? 0 : (v0 >= sh ? sh - 1 : v0);
            int v1c = v1 < 0 ? 0 : (v1 >= sh ? sh - 1 : v1);
            uint32_t p00 = src[(size_t)v0c * sw + u0c];
            uint32_t p10 = src[(size_t)v0c * sw + u1c];
            uint32_t p01 = src[(size_t)v1c * sw + u0c];
            uint32_t p11 = src[(size_t)v1c * sw + u1c];
            double w00 = (1 - tu) * (1 - tv), w10 = tu * (1 - tv);
            double w01 = (1 - tu) * tv, w11 = tu * tv;
            double a00 = (p00 >> 24) & 0xFF, a10 = (p10 >> 24) & 0xFF,
                   a01 = (p01 >> 24) & 0xFF, a11 = (p11 >> 24) & 0xFF;
            double sa = a00 * w00 + a10 * w10 + a01 * w01 + a11 * w11;
            if (sa <= 0.5)
                continue;
            double sr = (((p00 >> 16) & 0xFF) * a00 * w00 +
                         ((p10 >> 16) & 0xFF) * a10 * w10 +
                         ((p01 >> 16) & 0xFF) * a01 * w01 +
                         ((p11 >> 16) & 0xFF) * a11 * w11) / sa;
            double sg = (((p00 >> 8) & 0xFF) * a00 * w00 +
                         ((p10 >> 8) & 0xFF) * a10 * w10 +
                         ((p01 >> 8) & 0xFF) * a01 * w01 +
                         ((p11 >> 8) & 0xFF) * a11 * w11) / sa;
            double sb = ((p00 & 0xFF) * a00 * w00 + (p10 & 0xFF) * a10 * w10 +
                         (p01 & 0xFF) * a01 * w01 +
                         (p11 & 0xFF) * a11 * w11) / sa;
            double f = (sa / 255.0) * opacity * (mcov / 255.0);
            if (f <= 0.0005)
                continue;
            uint32_t dst = row[x];
            unsigned dr = (dst >> 16) & 0xFF, dg = (dst >> 8) & 0xFF,
                     db = dst & 0xFF;
            unsigned r = (unsigned)(sr * f + dr * (1 - f) + 0.5);
            unsigned g = (unsigned)(sg * f + dg * (1 - f) + 0.5);
            unsigned b = (unsigned)(sb * f + db * (1 - f) + 0.5);
            if (fb_alpha)
            {
                unsigned da = dst >> 24;
                unsigned oa = (unsigned)(sa * opacity + da * (1 - f) + 0.5);
                if (oa > 255) oa = 255;
                row[x] = (oa << 24) | (r << 16) | (g << 8) | b;
            }
            else
                row[x] = (r << 16) | (g << 8) | b;
        }
    }
}

void iosim_fb_set_opacity(double opacity)
{
    if (opacity < 0)
        opacity = 0;
    if (opacity > 1)
        opacity = 1;
    fb_opacity = opacity;
}

static uint32_t blend_color(uint32_t color, double alpha)
{
    if (alpha >= 0.999)
        return color;
    if (alpha <= 0)
        return 0;
    unsigned a = (unsigned)(alpha * 255.0 + 0.5);
    unsigned r = ((color >> 16) & 0xFF) * a / 255;
    unsigned g = ((color >> 8) & 0xFF) * a / 255;
    unsigned b = (color & 0xFF) * a / 255;
    return (r << 16) | (g << 8) | b;
}

void iosim_fb_clear(uint32_t color)
{
    if (!fb_pixels)
        return;
    size_t n = (size_t)fb_width * fb_height;
    for (size_t i = 0; i < n; i++)
        fb_pixels[i] = color;
}

void iosim_fb_fill_rect(int x, int y, int w, int h, uint32_t color)
{
    if (!fb_pixels || w <= 0 || h <= 0)
        return;
    int x0 = x < fb_clip_x0() ? fb_clip_x0() : x;
    int y0 = y < fb_clip_y0() ? fb_clip_y0() : y;
    int x1 = x + w > fb_clip_x1() ? fb_clip_x1() : x + w;
    int y1 = y + h > fb_clip_y1() ? fb_clip_y1() : y + h;
    if (x0 >= x1 || y0 >= y1)
        return;
    unsigned fr = (color >> 16) & 0xFF, fg = (color >> 8) & 0xFF,
             fb = color & 0xFF;
    if (fb_opacity >= 0.999)
    {
        for (int yy = y0; yy < y1; yy++)
        {
            uint32_t *row = fb_pixels + (size_t)yy * fb_width;
            for (int xx = x0; xx < x1; xx++)
            {
                int cov = fb_mask_coverage(xx, yy);
                if (!cov)
                    continue;
                if (cov == 255 && !fb_blend_mode)
                {
                    row[xx] = fb_full(color);
                    continue;
                }
                uint32_t dst = row[xx];
                unsigned r, g, b;
                if (fb_blend_mode)
                    fb_blend_color(fb_blend_mode, color, dst,
                                   cov / 255.0, &r, &g, &b);
                else
                {
                    r = (fr * cov + ((dst >> 16) & 0xFF) * (255 - cov) + 127) / 255;
                    g = (fg * cov + ((dst >> 8) & 0xFF) * (255 - cov) + 127) / 255;
                    b = (fb * cov + (dst & 0xFF) * (255 - cov) + 127) / 255;
                }
                row[xx] = fb_pack(dst, r, g, b, cov);
            }
        }
        return;
    }
    unsigned base = (unsigned)(fb_opacity * 255.0 + 0.5);
    for (int yy = y0; yy < y1; yy++)
    {
        uint32_t *row = fb_pixels + (size_t)yy * fb_width;
        for (int xx = x0; xx < x1; xx++)
        {
            unsigned fa = (base * (unsigned)fb_mask_coverage(xx, yy) + 127) / 255;
            if (!fa)
                continue;
            uint32_t dst = row[xx];
            unsigned r, g, b;
            if (fb_blend_mode)
                fb_blend_color(fb_blend_mode, color, dst, fa / 255.0,
                               &r, &g, &b);
            else
            {
                r = (fr * fa + ((dst >> 16) & 0xFF) * (255 - fa) + 127) / 255;
                g = (fg * fa + ((dst >> 8) & 0xFF) * (255 - fa) + 127) / 255;
                b = (fb * fa + (dst & 0xFF) * (255 - fa) + 127) / 255;
            }
            row[xx] = fb_pack(dst, r, g, b, fa);
        }
    }
}

void iosim_fb_fill_round_rect(int x, int y, int w, int h, int radius,
                              uint32_t color)
{
    if (!fb_pixels || w <= 0 || h <= 0)
        return;
    if (radius <= 0)
    {
        iosim_fb_fill_rect(x, y, w, h, color);
        return;
    }
    if (radius * 2 > w)
        radius = w / 2;
    if (radius * 2 > h)
        radius = h / 2;

    int x0 = x < fb_clip_x0() ? fb_clip_x0() : x;
    int y0 = y < fb_clip_y0() ? fb_clip_y0() : y;
    int x1 = x + w > fb_clip_x1() ? fb_clip_x1() : x + w;
    int y1 = y + h > fb_clip_y1() ? fb_clip_y1() : y + h;
    if (x0 >= x1 || y0 >= y1)
        return;
    int fg_r = (color >> 16) & 0xFF, fg_g = (color >> 8) & 0xFF,
        fg_b = color & 0xFF;
    double cx = x + w / 2.0, cy = y + h / 2.0;
    double ex = w / 2.0 - radius, ey = h / 2.0 - radius;

    for (int yy = y0; yy < y1; yy++)
    {
        uint32_t *row = fb_pixels + (size_t)yy * fb_width;
        double py = yy + 0.5 - cy;
        for (int xx = x0; xx < x1; xx++)
        {
            int mcov = fb_mask_coverage(xx, yy);
            if (!mcov)
                continue;
            double mask = mcov / 255.0;
            double px = xx + 0.5 - cx;
            double qx = __builtin_fabs(px) - ex;
            double qy = __builtin_fabs(py) - ey;
            double ax = qx > 0 ? qx : 0, ay = qy > 0 ? qy : 0;
            double outside = __builtin_sqrt(ax * ax + ay * ay);
            double inside = qx > qy ? qx : qy;
            double d = outside + (inside < 0 ? inside : 0) - radius;
            double top = fb_opacity * mask;
            double coverage = (0.5 - d) * top;
            if (coverage <= 0)
                continue;
            if (coverage > top)
                coverage = top;
            if (coverage >= 1)
            {
                row[xx] = fb_full(color);
                continue;
            }
            unsigned a = (unsigned)(coverage * 255.0 + 0.5);
            uint32_t dst = row[xx];
            unsigned r = (fg_r * a + ((dst >> 16) & 0xFF) * (255 - a) + 127) / 255;
            unsigned g = (fg_g * a + ((dst >> 8) & 0xFF) * (255 - a) + 127) / 255;
            unsigned b = (fg_b * a + (dst & 0xFF) * (255 - a) + 127) / 255;
            row[xx] = fb_pack(dst, r, g, b, a);
        }
    }
}

void iosim_fb_fill_circle_gradient(int cx, int cy, int radius,
                                   uint32_t top_color, uint32_t bottom_color)
{
    if (!fb_pixels || radius <= 0)
        return;
    int x0 = cx - radius - 1, x1 = cx + radius + 2;
    int y0 = cy - radius - 1, y1 = cy + radius + 2;
    if (x0 < fb_clip_x0()) x0 = fb_clip_x0();
    if (y0 < fb_clip_y0()) y0 = fb_clip_y0();
    if (x1 > fb_clip_x1()) x1 = fb_clip_x1();
    if (y1 > fb_clip_y1()) y1 = fb_clip_y1();
    int tr = (top_color >> 16) & 0xFF, tg = (top_color >> 8) & 0xFF,
        tb = top_color & 0xFF;
    int br = (bottom_color >> 16) & 0xFF, bg = (bottom_color >> 8) & 0xFF,
        bb = bottom_color & 0xFF;
    for (int y = y0; y < y1; y++)
    {
        double dy = y + 0.5 - cy;
        double t = (y + 0.5 - (cy - radius)) / (2.0 * radius);
        if (t < 0) t = 0;
        if (t > 1) t = 1;
        unsigned r = (unsigned)(tr + (br - tr) * t + 0.5);
        unsigned g = (unsigned)(tg + (bg - tg) * t + 0.5);
        unsigned b = (unsigned)(tb + (bb - tb) * t + 0.5);
        for (int x = x0; x < x1; x++)
        {
            double dx = x + 0.5 - cx;
            double d = __builtin_sqrt(dx * dx + dy * dy) - radius;
            double coverage = (0.5 - d) * fb_opacity;
            if (coverage <= 0)
                continue;
            if (coverage > fb_opacity)
                coverage = fb_opacity;
            fb_blend_pixel(x, y, (r << 16) | (g << 8) | b, coverage);
        }
    }
}

void iosim_fb_fill_ellipse_gradient(int cx, int cy, int rx, int ry,
                                    uint32_t top_color, uint32_t bottom_color)
{
    if (!fb_pixels || rx <= 0 || ry <= 0)
        return;
    int x0 = cx - rx - 1, x1 = cx + rx + 2;
    int y0 = cy - ry - 1, y1 = cy + ry + 2;
    if (x0 < fb_clip_x0()) x0 = fb_clip_x0();
    if (y0 < fb_clip_y0()) y0 = fb_clip_y0();
    if (x1 > fb_clip_x1()) x1 = fb_clip_x1();
    if (y1 > fb_clip_y1()) y1 = fb_clip_y1();
    int tr = (top_color >> 16) & 0xFF, tg = (top_color >> 8) & 0xFF,
        tb = top_color & 0xFF;
    int br = (bottom_color >> 16) & 0xFF, bg = (bottom_color >> 8) & 0xFF,
        bb = bottom_color & 0xFF;
    double irx = 1.0 / rx, iry = 1.0 / ry;
    for (int y = y0; y < y1; y++)
    {
        double dy = (y + 0.5 - cy) * iry;
        double t = (y + 0.5 - (cy - ry)) / (2.0 * ry);
        if (t < 0) t = 0;
        if (t > 1) t = 1;
        unsigned r = (unsigned)(tr + (br - tr) * t + 0.5);
        unsigned g = (unsigned)(tg + (bg - tg) * t + 0.5);
        unsigned b = (unsigned)(tb + (bb - tb) * t + 0.5);
        for (int x = x0; x < x1; x++)
        {
            double dx = (x + 0.5 - cx) * irx;
            double dist = __builtin_sqrt(dx * dx + dy * dy);
            double d = (dist - 1.0) * (rx < ry ? rx : ry);
            double coverage = (0.5 - d) * fb_opacity;
            if (coverage <= 0)
                continue;
            if (coverage > fb_opacity)
                coverage = fb_opacity;
            fb_blend_pixel(x, y, (r << 16) | (g << 8) | b, coverage);
        }
    }
}

/* A stroked circular arc with a colour ramp along its length. start_deg
 * begins at the positive x axis (clockwise, as screen y grows downward);
 * sweep_deg is the arc length. Colours are interpolated across stops in
 * [0,1] along the arc. Used for the activity rings. */
void iosim_fb_fill_arc_gradient(int cx, int cy, int radius, int thickness,
                                double start_deg, double sweep_deg,
                                const uint32_t *colors, const double *stops,
                                int nstops)
{
    if (!fb_pixels || radius <= 0 || thickness <= 0 || nstops <= 0 ||
        sweep_deg <= 0)
        return;
    double half = thickness / 2.0;
    int range = radius + (int)(half + 2.0);
    int x0 = cx - range, x1 = cx + range + 1;
    int y0 = cy - range, y1 = cy + range + 1;
    if (x0 < fb_clip_x0()) x0 = fb_clip_x0();
    if (y0 < fb_clip_y0()) y0 = fb_clip_y0();
    if (x1 > fb_clip_x1()) x1 = fb_clip_x1();
    if (y1 > fb_clip_y1()) y1 = fb_clip_y1();
    for (int y = y0; y < y1; y++)
    {
        double dy = y + 0.5 - cy;
        for (int x = x0; x < x1; x++)
        {
            double dx = x + 0.5 - cx;
            double dist = __builtin_sqrt(dx * dx + dy * dy);
            double d = __builtin_fabs(dist - radius) - half;
            double coverage = (0.5 - d) * fb_opacity;
            if (coverage <= 0)
                continue;
            double ang = __builtin_atan2(dy, dx) * 57.29577951308232;
            double t = ang - start_deg;
            while (t < 0) t += 360.0;
            while (t >= 360.0) t -= 360.0;
            if (t > sweep_deg)
                continue;
            t /= sweep_deg;
            if (t < 0) t = 0;
            if (t > 1) t = 1;
            int k = 0;
            while (k < nstops - 2 && t > stops[k + 1])
                k++;
            double span = stops[k + 1] - stops[k];
            double f = span > 1e-9 ? (t - stops[k]) / span : 0;
            if (f < 0) f = 0;
            if (f > 1) f = 1;
            unsigned c0 = colors[k], c1 = colors[k + 1];
            int cr0 = (c0 >> 16) & 0xFF, cg0 = (c0 >> 8) & 0xFF,
                cb0 = c0 & 0xFF;
            int cr1 = (c1 >> 16) & 0xFF, cg1 = (c1 >> 8) & 0xFF,
                cb1 = c1 & 0xFF;
            unsigned r = (unsigned)(cr0 + (cr1 - cr0) * f + 0.5);
            unsigned g = (unsigned)(cg0 + (cg1 - cg0) * f + 0.5);
            unsigned b = (unsigned)(cb0 + (cb1 - cb0) * f + 0.5);
            if (coverage > fb_opacity)
                coverage = fb_opacity;
            fb_blend_pixel(x, y, (r << 16) | (g << 8) | b, coverage);
        }
    }
}

/* A stroked ellipse with a colour ramp around it (0 = east, clockwise).
 * Distances are measured in ellipse-normalised space scaled back by the
 * smaller radius, which tracks the true ring closely for mild ellipses. */
void iosim_fb_fill_ellipse_ring_gradient(int cx, int cy, int rx, int ry,
                                         int thickness,
                                         const uint32_t *colors,
                                         const double *stops, int nstops)
{
    if (!fb_pixels || rx <= 0 || ry <= 0 || thickness <= 0 || nstops <= 0)
        return;
    double half = thickness / 2.0;
    int x0 = cx - rx - 2, x1 = cx + rx + 3;
    int y0 = cy - ry - 2, y1 = cy + ry + 3;
    if (x0 < fb_clip_x0()) x0 = fb_clip_x0();
    if (y0 < fb_clip_y0()) y0 = fb_clip_y0();
    if (x1 > fb_clip_x1()) x1 = fb_clip_x1();
    if (y1 > fb_clip_y1()) y1 = fb_clip_y1();
    double minr = rx < ry ? rx : ry;
    for (int y = y0; y < y1; y++)
    {
        double ny = (y + 0.5 - cy) / ry;
        for (int x = x0; x < x1; x++)
        {
            double nx = (x + 0.5 - cx) / rx;
            double d = (__builtin_sqrt(nx * nx + ny * ny) - 1.0) * minr;
            double dd = __builtin_fabs(d) - half;
            double coverage = (0.5 - dd) * fb_opacity;
            if (coverage <= 0)
                continue;
            double ang = __builtin_atan2(ny, nx) * 0.15915494309189535;
            if (ang < 0) ang += 1.0;
            int k = 0;
            while (k < nstops - 2 && ang > stops[k + 1])
                k++;
            double span = stops[k + 1] - stops[k];
            double f = span > 1e-9 ? (ang - stops[k]) / span : 0;
            if (f < 0) f = 0;
            if (f > 1) f = 1;
            unsigned c0 = colors[k], c1 = colors[k + 1];
            int cr0 = (c0 >> 16) & 0xFF, cg0 = (c0 >> 8) & 0xFF,
                cb0 = c0 & 0xFF;
            int cr1 = (c1 >> 16) & 0xFF, cg1 = (c1 >> 8) & 0xFF,
                cb1 = c1 & 0xFF;
            unsigned r = (unsigned)(cr0 + (cr1 - cr0) * f + 0.5);
            unsigned g = (unsigned)(cg0 + (cg1 - cg0) * f + 0.5);
            unsigned b = (unsigned)(cb0 + (cb1 - cb0) * f + 0.5);
            if (coverage > fb_opacity)
                coverage = fb_opacity;
            fb_blend_pixel(x, y, (r << 16) | (g << 8) | b, coverage);
        }
    }
}

void iosim_fb_fill_circle(int cx, int cy, int radius, uint32_t color)
{
    if (!fb_pixels || radius <= 0)
        return;
    int fg_r = (color >> 16) & 0xFF, fg_g = (color >> 8) & 0xFF,
        fg_b = color & 0xFF;
    int x0 = cx - radius - 1, x1 = cx + radius + 2;
    int y0 = cy - radius - 1, y1 = cy + radius + 2;
    if (x0 < fb_clip_x0()) x0 = fb_clip_x0();
    if (y0 < fb_clip_y0()) y0 = fb_clip_y0();
    if (x1 > fb_clip_x1()) x1 = fb_clip_x1();
    if (y1 > fb_clip_y1()) y1 = fb_clip_y1();
    for (int y = y0; y < y1; y++)
    {
        uint32_t *row = fb_pixels + (size_t)y * fb_width;
        double dy = y + 0.5 - cy;
        for (int x = x0; x < x1; x++)
        {
            int mcov = fb_mask_coverage(x, y);
            if (!mcov)
                continue;
            double mask = mcov / 255.0;
            double dx = x + 0.5 - cx;
            double d = __builtin_sqrt(dx * dx + dy * dy) - radius;
            double top = fb_opacity * mask;
            double coverage = (0.5 - d) * top;
            if (coverage <= 0)
                continue;
            if (coverage > top)
                coverage = top;
            if (coverage >= 1)
            {
                row[x] = fb_full(color);
                continue;
            }
            unsigned a = (unsigned)(coverage * 255.0 + 0.5);
            uint32_t dst = row[x];
            unsigned r = (fg_r * a + ((dst >> 16) & 0xFF) * (255 - a) + 127) / 255;
            unsigned g = (fg_g * a + ((dst >> 8) & 0xFF) * (255 - a) + 127) / 255;
            unsigned b = (fg_b * a + (dst & 0xFF) * (255 - a) + 127) / 255;
            row[x] = fb_pack(dst, r, g, b, a);
        }
    }
}

void iosim_fb_text(int x, int y, int scale, uint32_t color, const char *text)
{
    if (!fb_pixels || !text || scale < 1)
        return;
    int cx = x, cy = y;
    for (const unsigned char *p = (const unsigned char *)text; *p; p++)
    {
        if (*p == '\n')
        {
            cx = x;
            cy += 8 * scale + 2 * scale;
            continue;
        }
        unsigned ch = (*p) & 0x7f;
        for (int row = 0; row < 8; row++)
        {
            unsigned char bits = (unsigned char)font8x8_basic[ch][row];
            for (int col = 0; col < 8; col++)
            {
                if (bits & (1u << col))
                    iosim_fb_fill_rect(cx + col * scale, cy + row * scale,
                                       scale, scale, color);
            }
        }
        cx += 9 * scale;
    }
}

int iosim_fb_text_width(const char *text, int scale)
{
    if (!text || scale < 1)
        return 0;
    int best = 0, cur = 0;
    for (const unsigned char *p = (const unsigned char *)text; *p; p++)
    {
        if (*p == '\n')
        {
            if (cur > best)
                best = cur;
            cur = 0;
        }
        else
        {
            cur += 9 * scale;
        }
    }
    if (cur > best)
        best = cur;
    return best > 0 ? best - scale : 0;
}

static void put_be32(uint8_t *p, uint32_t v)
{
    p[0] = (uint8_t)(v >> 24);
    p[1] = (uint8_t)(v >> 16);
    p[2] = (uint8_t)(v >> 8);
    p[3] = (uint8_t)v;
}

static int write_chunk(FILE *f, const char *type, const uint8_t *data,
                       uint32_t len)
{
    uint8_t buf[4];
    put_be32(buf, len);
    if (fwrite(buf, 1, 4, f) != 4)
        return -1;
    if (fwrite(type, 1, 4, f) != 4)
        return -1;
    if (len && fwrite(data, 1, len, f) != len)
        return -1;
    uLong crc = crc32(0L, Z_NULL, 0);
    crc = crc32(crc, (const Bytef *)type, 4);
    if (len)
        crc = crc32(crc, data, len);
    put_be32(buf, (uint32_t)crc);
    if (fwrite(buf, 1, 4, f) != 4)
        return -1;
    return 0;
}

static void mkdir_parents(const char *path)
{
    char tmp[1024];
    if (strlen(path) >= sizeof(tmp))
        return;
    strcpy(tmp, path);
    char *slash = strrchr(tmp, '/');
    if (!slash)
        return;
    *slash = 0;
    for (char *p = tmp + 1; *p; p++)
    {
        if (*p == '/')
        {
            *p = 0;
            mkdir(tmp, 0755);
            *p = '/';
        }
    }
    mkdir(tmp, 0755);
}

int iosim_fb_present(const char *path)
{
    if (!fb_pixels || !path)
        return -1;

    size_t stride = (size_t)fb_width * 4 + 1;
    size_t raw_len = stride * fb_height;
    uint8_t *raw = malloc(raw_len);
    if (!raw)
        return -1;

    for (unsigned y = 0; y < fb_height; y++)
    {
        uint8_t *row = raw + y * stride;
        row[0] = 0; /* filter: none */
        for (unsigned x = 0; x < fb_width; x++)
        {
            uint32_t c = fb_pixels[(size_t)y * fb_width + x];
            uint8_t *px = row + 1 + (size_t)x * 4;
            px[0] = (uint8_t)(c >> 16);
            px[1] = (uint8_t)(c >> 8);
            px[2] = (uint8_t)c;
            px[3] = 255;
        }
    }

    uLongf comp_len = compressBound((uLong)raw_len);
    uint8_t *comp = malloc(comp_len);
    if (!comp || compress2(comp, &comp_len, raw, (uLong)raw_len,
                           Z_BEST_SPEED) != Z_OK)
    {
        free(raw);
        free(comp);
        return -1;
    }
    free(raw);

    mkdir_parents(path);
    /* Write beside the target and rename, so a reader that copies the
     * framebuffer while the UI repaints never sees a half-written PNG. */
    size_t tmplen = strlen(path) + 40;
    char *tmp_path = malloc(tmplen);
    if (!tmp_path)
    {
        free(comp);
        return -1;
    }
    snprintf(tmp_path, tmplen, "%s.tmp.%ld", path, (long)getpid());
    FILE *f = fopen(tmp_path, "wb");
    if (!f)
    {
        free(tmp_path);
        free(comp);
        return -1;
    }

    static const uint8_t sig[8] = { 0x89, 'P', 'N', 'G', '\r', '\n', 0x1a, '\n' };
    fwrite(sig, 1, 8, f);

    uint8_t ihdr[13];
    put_be32(ihdr + 0, fb_width);
    put_be32(ihdr + 4, fb_height);
    ihdr[8] = 8;   /* bit depth */
    ihdr[9] = 6;   /* RGBA */
    ihdr[10] = 0;  /* compression */
    ihdr[11] = 0;  /* filter */
    ihdr[12] = 0;  /* interlace */
    int rc = write_chunk(f, "IHDR", ihdr, sizeof(ihdr));
    if (rc == 0)
    {
        static const uint8_t srgb_intent = 0;
        rc = write_chunk(f, "sRGB", &srgb_intent, 1);
    }
    if (rc == 0)
        rc = write_chunk(f, "IDAT", comp, (uint32_t)comp_len);
    if (rc == 0)
        rc = write_chunk(f, "IEND", NULL, 0);
    if (fclose(f) != 0)
        rc = -1;
    free(comp);

    if (rc == 0 && rename(tmp_path, path) != 0)
        rc = -1;
    if (rc != 0)
        remove(tmp_path);
    free(tmp_path);

    if (rc == 0)
        fprintf(stderr, "iosim: framebuffer %ux%u written to %s\n",
                fb_width, fb_height, path);
    return rc;
}

/* ----------------------------------------------------------------- fonts */

#include <ft2build.h>
#include FT_FREETYPE_H
#include FT_MULTIPLE_MASTERS_H

#include <dirent.h>
#include <sys/stat.h>

typedef struct {
    FT_Face face;
    char path[1024];
    int tried;
    int variable;
} iosim_face;

static FT_Library g_ft;
static iosim_face g_faces[3];

static const char *font_env_names[3] = {
    "IOSIM_FONT_REGULAR", "IOSIM_FONT_BOLD", "IOSIM_FONT_SEMIBOLD"
};

static const char *font_candidates[3][12] = {
    {
        "SFProText-Regular.ttf", "SFProText-Regular.otf",
        "SFProDisplay-Regular.ttf", "SFProDisplay-Regular.otf",
        "SFPro-Regular.ttf", "SFPro-Regular.otf",
        "SF-Pro-Text-Regular.otf", "SF-Pro-Display-Regular.otf",
        "SFUIText-Regular.ttf", "SFUIDisplay-Regular.ttf",
        "SFUI.ttf", "SFPro.ttf", "SFNS.ttf"
    },
    {
        "SFProText-Bold.ttf", "SFProText-Bold.otf",
        "SFProDisplay-Bold.ttf", "SFProDisplay-Bold.otf",
        "SFPro-Bold.ttf", "SFPro-Bold.otf",
        "SF-Pro-Text-Bold.otf", "SF-Pro-Display-Bold.otf",
        "SFUIText-Bold.ttf", "SFUIDisplay-Bold.ttf",
        "SFUI.ttf", "SFPro.ttf", "SFNS.ttf"
    },
    {
        "SFProText-Semibold.ttf", "SFProText-Semibold.otf",
        "SFProDisplay-Semibold.ttf", "SFProDisplay-Semibold.otf",
        "SFPro-Semibold.ttf", "SFPro-Semibold.otf",
        "SF-Pro-Text-Semibold.otf", "SF-Pro-Display-Semibold.otf",
        "SFUIText-Semibold.ttf", "SFUIDisplay-Semibold.ttf",
        "SFUI.ttf", "SFPro.ttf", "SFNS.ttf"
    }
};

static const char *fallback_fonts[2] = {
    "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf",
    "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf"
};

static int path_exists(const char *path)
{
    struct stat st;
    return path && stat(path, &st) == 0 && S_ISREG(st.st_mode);
}

static int find_file_recursive(const char *dir, const char *name, char *out,
                               size_t out_size, int depth)
{
    if (!dir || depth < 0)
        return 0;
    DIR *d = opendir(dir);
    if (!d)
        return 0;
    struct dirent *ent;
    int found = 0;
    while (!found && (ent = readdir(d)) != NULL)
    {
        if (strcmp(ent->d_name, ".") == 0 || strcmp(ent->d_name, "..") == 0)
            continue;
        char path[1200];
        snprintf(path, sizeof(path), "%s/%s", dir, ent->d_name);
        struct stat st;
        if (stat(path, &st) != 0)
            continue;
        if (S_ISDIR(st.st_mode))
        {
            if (depth > 0 && find_file_recursive(path, name, out, out_size,
                                                 depth - 1))
                found = 1;
        }
        else if (S_ISREG(st.st_mode) && strcmp(ent->d_name, name) == 0)
        {
            snprintf(out, out_size, "%s", path);
            found = 1;
        }
    }
    closedir(d);
    return found;
}

static int resolve_font_path(int style, char *out, size_t out_size)
{
    const char *explicit_path = getenv(font_env_names[style]);
    if (path_exists(explicit_path))
    {
        snprintf(out, out_size, "%s", explicit_path);
        return 1;
    }
    const char *dir = getenv("IOSIM_FONT_DIR");
    if (dir)
    {
        for (int i = 0; i < 12; i++)
        {
            char direct[1200];
            snprintf(direct, sizeof(direct), "%s/%s", dir, font_candidates[style][i]);
            if (path_exists(direct))
            {
                snprintf(out, out_size, "%s", direct);
                return 1;
            }
            if (find_file_recursive(dir, font_candidates[style][i], out,
                                    out_size, 3))
                return 1;
        }
        /* A variable SF Pro font can serve every style. */
        static const char *variable_names[] = {
            "SFUI.ttf", "SFPro.ttf", "SFPro.otf", "SF-Pro.ttf", "SFNS.ttf",
            "SFProText.ttf", "SFProDisplay.ttf"
        };
        for (size_t i = 0; i < sizeof(variable_names) / sizeof(variable_names[0]); i++)
        {
            if (find_file_recursive(dir, variable_names[i], out, out_size, 3))
                return 1;
        }
    }
    if (path_exists(fallback_fonts[style == IOSIM_FONT_REGULAR ? 0 : 1]))
    {
        snprintf(out, out_size, "%s",
                 fallback_fonts[style == IOSIM_FONT_REGULAR ? 0 : 1]);
        return 1;
    }
    return 0;
}

static FT_Face get_face(int style, double size_pt)
{
    if (style < 0 || style > 2)
        style = IOSIM_FONT_REGULAR;
    if (!g_ft && FT_Init_FreeType(&g_ft) != 0)
        return NULL;
    iosim_face *entry = &g_faces[style];
    if (!entry->tried)
    {
        entry->tried = 1;
        if (!resolve_font_path(style, entry->path, sizeof(entry->path)))
            return NULL;
        if (FT_New_Face(g_ft, entry->path, 0, &entry->face) != 0)
        {
            entry->face = NULL;
            return NULL;
        }
        FT_MM_Var *mm = NULL;
        if (FT_Get_MM_Var(entry->face, &mm) == 0 && mm)
        {
            entry->variable = 1;
            FT_Done_MM_Var(g_ft, mm);
        }
    }
    if (!entry->face)
        return NULL;

    if (entry->variable)
    {
        FT_MM_Var *mm = NULL;
        if (FT_Get_MM_Var(entry->face, &mm) == 0 && mm)
        {
            FT_Fixed *coords = calloc(mm->num_axis, sizeof(FT_Fixed));
            if (coords)
            {
                int bold_weight = 600;
                int semibold_weight = 600;
                const char *bw = getenv("IOSIM_BOLD_WEIGHT");
                const char *sw = getenv("IOSIM_SEMIBOLD_WEIGHT");
                if (bw)
                    bold_weight = atoi(bw);
                if (sw)
                    semibold_weight = atoi(sw);
                FT_Fixed weight = style == IOSIM_FONT_BOLD
                                      ? bold_weight * 65536
                                      : style == IOSIM_FONT_SEMIBOLD
                                            ? semibold_weight * 65536
                                            : 400 * 65536;
                for (FT_UInt i = 0; i < mm->num_axis; i++)
                {
                    FT_Var_Axis *axis = &mm->axis[i];
                    FT_Fixed value = axis->def;
                    if (axis->tag == FT_MAKE_TAG('w', 'g', 'h', 't'))
                        value = weight;
                    else if (axis->tag == FT_MAKE_TAG('o', 'p', 's', 'z'))
                        value = (FT_Fixed)((double)size_pt * 65536.0);
                    else if (axis->tag == FT_MAKE_TAG('w', 'd', 't', 'h'))
                        value = (FT_Fixed)(100.0 * 65536.0);
                    else if (axis->tag == FT_MAKE_TAG('G', 'R', 'A', 'D'))
                        value = (FT_Fixed)(400.0 * 65536.0);
                    if (value < axis->minimum) value = axis->minimum;
                    if (value > axis->maximum) value = axis->maximum;
                    coords[i] = value;
                }
                FT_Set_Var_Design_Coordinates(entry->face, mm->num_axis, coords);
                free(coords);
            }
            FT_Done_MM_Var(g_ft, mm);
        }
    }

    int pixel_size = (int)(size_pt * 3.0 + 0.5); /* caller may override scale */
    (void)pixel_size;
    return entry->face;
}

static int set_face_pixels(int style, double size_pt, double scale)
{
    FT_Face face = get_face(style, size_pt);
    if (!face)
        return 0;
    int px = (int)(size_pt * scale + 0.5);
    if (px < 1)
        px = 1;
    if (FT_Set_Pixel_Sizes(face, 0, (FT_UInt)px) != 0)
        return 0;
    return 1;
}

static uint32_t utf8_next(const unsigned char **pp)
{
    const unsigned char *p = *pp;
    uint32_t cp = *p++;
    if (cp >= 0xF0)
    {
        cp = ((cp & 7) << 18) | ((p[0] & 0x3F) << 12) |
             ((p[1] & 0x3F) << 6) | (p[2] & 0x3F);
        p += 3;
    }
    else if (cp >= 0xE0)
    {
        cp = ((cp & 0xF) << 12) | ((p[0] & 0x3F) << 6) | (p[1] & 0x3F);
        p += 2;
    }
    else if (cp >= 0xC0)
    {
        cp = ((cp & 0x1F) << 6) | (p[0] & 0x3F);
        p += 1;
    }
    *pp = p;
    return cp;
}

static double system_tracking_pt(int style, double size_pt)
{
    const char *env_override = NULL;
    if (style == IOSIM_FONT_REGULAR && size_pt >= 16.5 && size_pt <= 17.5)
        env_override = getenv("IOSIM_TRACK_REG17");
    else if (style == IOSIM_FONT_REGULAR && size_pt >= 15.5 && size_pt <= 16.5)
        env_override = getenv("IOSIM_TRACK_REG16");
    else if (style == IOSIM_FONT_BOLD && size_pt >= 33 && size_pt <= 35)
        env_override = getenv("IOSIM_TRACK_BOLD34");
    else if (style == IOSIM_FONT_BOLD && size_pt >= 17.5 && size_pt <= 18.5)
        env_override = getenv("IOSIM_TRACK_BOLD18");
    if (env_override)
        return atof(env_override);
    static const double sizes[] = { 10, 11, 12, 13, 14, 15, 16, 17, 18, 20, 24, 28, 32, 36, 48, 64, 96 };
    static const double regular[] = { 0.12, 0.06, 0.00, -0.12, -0.303, -0.32, -0.38, -0.54, -0.52, -0.46, -0.30, -0.20, -0.30, -0.25, -0.20, -0.15, -0.10 };
    static const double bold[]    = { 0.20, 0.15, 0.10, 0.00, -0.20, -0.35, -0.50, -0.55, -0.571, -0.40, -0.10, 0.10, 0.22, 0.30, 0.40, 0.40, 0.40 };
    static const double semibold[]= { 0.14, 0.08, 0.02, -0.10, -0.28, -0.30, -0.35, -0.70, -0.76, -0.50, -0.30, -0.20, -0.15, -0.12, -0.09, -0.07, -0.05 };
    const double *table = style == IOSIM_FONT_BOLD ? bold
                          : style == IOSIM_FONT_SEMIBOLD ? semibold : regular;
    int n = (int)(sizeof(sizes) / sizeof(sizes[0]));
    if (size_pt <= sizes[0])
        return table[0];
    for (int i = 1; i < n; i++)
    {
        if (size_pt <= sizes[i])
        {
            double t = (size_pt - sizes[i - 1]) / (sizes[i] - sizes[i - 1]);
            return table[i - 1] + t * (table[i] - table[i - 1]);
        }
    }
    return table[n - 1];
}

int iosim_fb_font_text_width(const char *text, int style, double size_pt,
                             double scale)
{
    if (!text || !*text)
        return 0;
    if (!set_face_pixels(style, size_pt, scale))
        return iosim_fb_text_width(text, (int)(size_pt * scale / 12.0 + 0.5));
    FT_Face face = g_faces[style].face;
    FT_UInt prev = 0;
    int64_t pen = 0;
    const unsigned char *p = (const unsigned char *)text;
    while (*p)
    {
        uint32_t cp = utf8_next(&p);
        if (cp == '\n')
            continue;
        FT_UInt glyph = FT_Get_Char_Index(face, cp);
        if (!glyph)
            glyph = FT_Get_Char_Index(face, '?');
        if (prev)
        {
            FT_Vector kern;
            if (FT_Get_Kerning(face, prev, glyph, FT_KERNING_UNFITTED, &kern) == 0)
                pen += kern.x;
        }
        if (FT_Load_Glyph(face, glyph, FT_LOAD_NO_HINTING | FT_LOAD_NO_BITMAP) == 0)
            pen += face->glyph->advance.x;
        if (prev)
            pen += (FT_Pos)(system_tracking_pt(style, size_pt) * scale * 64.0);
        prev = glyph;
    }
    return (int)((pen + 32) >> 6);
}

int iosim_fb_font_text_width_untracked(const char *text, int style,
                                       double size_pt, double scale)
{
    if (!text || !*text)
        return 0;
    if (!set_face_pixels(style, size_pt, scale))
        return iosim_fb_text_width(text, (int)(size_pt * scale / 12.0 + 0.5));
    FT_Face face = g_faces[style].face;
    FT_UInt prev = 0;
    int64_t pen = 0;
    const unsigned char *p = (const unsigned char *)text;
    while (*p)
    {
        uint32_t cp = utf8_next(&p);
        if (cp == '\n')
            continue;
        FT_UInt glyph = FT_Get_Char_Index(face, cp);
        if (!glyph)
            glyph = FT_Get_Char_Index(face, '?');
        if (prev)
        {
            FT_Vector kern;
            if (FT_Get_Kerning(face, prev, glyph, FT_KERNING_UNFITTED, &kern) == 0)
                pen += kern.x;
        }
        if (FT_Load_Glyph(face, glyph, FT_LOAD_NO_HINTING | FT_LOAD_NO_BITMAP) == 0)
            pen += face->glyph->advance.x;
        prev = glyph;
    }
    return (int)((pen + 32) >> 6);
}

void iosim_fb_font_text(int x, int baseline_y, const char *text, int style,
                        double size_pt, double scale, uint32_t color)
{
    if (!fb_pixels || !text || !*text)
        return;
    if (!set_face_pixels(style, size_pt, scale))
    {
        iosim_fb_text(x, baseline_y - (int)(size_pt * scale * 0.75), 
                      (int)(size_pt * scale / 12.0 + 0.5), color, text);
        return;
    }
    FT_Face face = g_faces[style].face;
    int64_t pen = 0;
    FT_UInt prev = 0;
    const unsigned char *p = (const unsigned char *)text;
    int fg_r = (color >> 16) & 0xFF;
    int fg_g = (color >> 8) & 0xFF;
    int fg_b = color & 0xFF;

    while (*p)
    {
        uint32_t cp = utf8_next(&p);
        if (cp == '\n')
        {
            pen = 0;
            prev = 0;
            continue;
        }
        FT_UInt glyph = FT_Get_Char_Index(face, cp);
        if (!glyph)
            glyph = FT_Get_Char_Index(face, '?');
        if (prev)
        {
            FT_Vector kern;
            if (FT_Get_Kerning(face, prev, glyph, FT_KERNING_UNFITTED, &kern) == 0)
                pen += kern.x;
        }
        int64_t rounded = (pen + 32) >> 6;
        FT_Vector delta;
        delta.x = (FT_Pos)(pen - (rounded << 6));
        delta.y = 0;
        if (getenv("IOSIM_SUBPIXEL"))
            FT_Set_Transform(face, NULL, &delta);
        else
            FT_Set_Transform(face, NULL, NULL);
        if (FT_Load_Glyph(face, glyph, FT_LOAD_NO_HINTING | FT_LOAD_NO_BITMAP) != 0)
        {
            prev = glyph;
            continue;
        }
        if (FT_Render_Glyph(face->glyph, FT_RENDER_MODE_NORMAL) != 0)
        {
            prev = glyph;
            continue;
        }
        FT_GlyphSlot slot = face->glyph;
        int gx = x + (int)rounded + slot->bitmap_left;
        int gy = baseline_y - slot->bitmap_top;
        for (unsigned row = 0; row < slot->bitmap.rows; row++)
        {
            int yy = gy + (int)row;
            if (yy < 0 || yy >= (int)fb_height)
                continue;
            const unsigned char *src = slot->bitmap.buffer +
                                       (size_t)row * slot->bitmap.pitch;
            uint32_t *dst = fb_pixels + (size_t)yy * fb_width;
            for (unsigned col = 0; col < slot->bitmap.width; col++)
            {
                int xx = gx + (int)col;
                if (xx < fb_clip_x0() || xx >= fb_clip_x1() ||
                    yy < fb_clip_y0() || yy >= fb_clip_y1())
                    continue;
                int mcov = fb_mask_coverage(xx, yy);
                if (!mcov)
                    continue;
                unsigned a = (unsigned)(src[col] * fb_opacity *
                                        (mcov / 255.0) + 0.5);
                if (!a)
                    continue;
                uint32_t d = dst[xx];
                unsigned r, g, b;
                if (fb_blend_mode)
                    fb_blend_color(fb_blend_mode,
                                   ((uint32_t)fg_r << 16) |
                                       ((uint32_t)fg_g << 8) |
                                       (uint32_t)fg_b,
                                   d, a / 255.0, &r, &g, &b);
                else
                {
                    unsigned dr = (d >> 16) & 0xFF;
                    unsigned dg = (d >> 8) & 0xFF;
                    unsigned db = d & 0xFF;
                    r = (fg_r * a + dr * (255 - a) + 127) / 255;
                    g = (fg_g * a + dg * (255 - a) + 127) / 255;
                    b = (fg_b * a + db * (255 - a) + 127) / 255;
                }
                dst[xx] = fb_pack(d, r, g, b, a);
            }
        }
        pen += slot->advance.x;
        if (prev)
            pen += (FT_Pos)(system_tracking_pt(style, size_pt) * scale * 64.0);
        prev = glyph;
    }
}

void iosim_fb_font_metrics(int style, double size_pt, double scale,
                           int *ascent, int *descent, int *line_height)
{
    int a = 0, d = 0, h = 0;
    if (set_face_pixels(style, size_pt, scale))
    {
        FT_Size_Metrics *m = &g_faces[style].face->size->metrics;
        a = (int)((m->ascender + 63) >> 6);
        d = (int)((-m->descender + 63) >> 6);
        h = (int)((m->height + 63) >> 6);
        if (h < a + d)
            h = a + d;
    }
    if (ascent) *ascent = a;
    if (descent) *descent = d;
    if (line_height) *line_height = h;
}

/* ---------------------------------------------------- extended drawing */

static void fb_blend_pixel(int x, int y, uint32_t color, double coverage)
{
    if (x < 0 || y < 0 || x >= (int)fb_width || y >= (int)fb_height)
        return;
    if (x < fb_clip_x0() || x >= fb_clip_x1() ||
        y < fb_clip_y0() || y >= fb_clip_y1())
        return;
    int mcov = fb_mask_coverage(x, y);
    if (!mcov)
        return;
    coverage *= fb_opacity * (mcov / 255.0);
    if (coverage <= 0)
        return;
    uint32_t *row = fb_pixels + (size_t)y * fb_width;
    if (!fb_blend_mode && coverage >= 0.999)
    {
        row[x] = fb_full(color);
        return;
    }
    unsigned a = (unsigned)(coverage * 255.0 + 0.5);
    uint32_t dst = row[x];
    unsigned r, g, b;
    if (fb_blend_mode)
        fb_blend_color(fb_blend_mode, color, dst, coverage, &r, &g, &b);
    else
    {
        r = (((color >> 16) & 0xFF) * a + ((dst >> 16) & 0xFF) * (255 - a) + 127) / 255;
        g = (((color >> 8) & 0xFF) * a + ((dst >> 8) & 0xFF) * (255 - a) + 127) / 255;
        b = ((color & 0xFF) * a + (dst & 0xFF) * (255 - a) + 127) / 255;
    }
    row[x] = fb_pack(dst, r, g, b, a);
}

/* ---------------------------------------------------- stroked polylines */

#define IOSIM_STROKE_PI 3.14159265358979323846

static void stroke_disc(double cx, double cy, double radius, uint32_t color)
{
    if (radius <= 0)
        return;
    double xs[24], ys[24];
    int count = radius >= 4.0 ? 20 : (radius >= 1.5 ? 12 : 8);
    for (int i = 0; i < count; i++)
    {
        double angle = 2.0 * IOSIM_STROKE_PI * i / count;
        xs[i] = cx + radius * __builtin_cos(angle);
        ys[i] = cy + radius * __builtin_sin(angle);
    }
    iosim_fb_fill_polygon(xs, ys, count, color);
}

static void stroke_segment(double ax, double ay, double bx, double by,
                           double half, uint32_t color)
{
    double dx = bx - ax, dy = by - ay;
    double len = __builtin_sqrt(dx * dx + dy * dy);
    if (len < 1e-9)
        return;
    double nx = -dy / len * half, ny = dx / len * half;
    double xs[4] = { ax + nx, bx + nx, bx - nx, ax - nx };
    double ys[4] = { ay + ny, by + ny, by - ny, ay - ny };
    iosim_fb_fill_polygon(xs, ys, 4, color);
}

/* Fill the wedge on the outside of a corner. join: 0 miter, 1 round,
 * 2 bevel. */
static void stroke_join(double ax, double ay, double bx, double by,
                        double cx, double cy, double half, uint32_t color,
                        int join, double miter_limit)
{
    double d1x = bx - ax, d1y = by - ay;
    double d2x = cx - bx, d2y = cy - by;
    double l1 = __builtin_sqrt(d1x * d1x + d1y * d1y);
    double l2 = __builtin_sqrt(d2x * d2x + d2y * d2y);
    if (l1 < 1e-9 || l2 < 1e-9)
        return;
    d1x /= l1; d1y /= l1;
    d2x /= l2; d2y /= l2;
    double cross = d1x * d2y - d1y * d2x;
    if (__builtin_fabs(cross) < 1e-9)
        return; /* collinear: the segment quads already cover the joint */
    double n1x = -d1y, n1y = d1x;
    double n2x = -d2y, n2y = d2x;
    double o1x = cross > 0 ? -n1x : n1x;
    double o1y = cross > 0 ? -n1y : n1y;
    double o2x = cross > 0 ? -n2x : n2x;
    double o2y = cross > 0 ? -n2y : n2y;
    double p1x = bx + o1x * half, p1y = by + o1y * half;
    double p2x = bx + o2x * half, p2y = by + o2y * half;
    if (join == 1)
    {
        stroke_disc(bx, by, half, color);
        return;
    }
    double mx = o1x + o2x, my = o1y + o2y;
    double mlen = __builtin_sqrt(mx * mx + my * my);
    double dot = o1x * o2x + o1y * o2y;
    if (join == 0 && mlen > 1e-9 && dot > -1.0)
    {
        double cos_half = __builtin_sqrt((1.0 + dot) / 2.0);
        double miter = half / cos_half;
        if (miter <= miter_limit * half + 1e-6)
        {
            mx /= mlen;
            my /= mlen;
            double xs[4] = { p1x, p2x, bx + mx * miter, bx + mx * miter };
            double ys[4] = { p1y, p2y, by + my * miter, by + my * miter };
            iosim_fb_fill_polygon(xs, ys, 4, color);
            return;
        }
    }
    double xs[3] = { p1x, p2x, bx };
    double ys[3] = { p1y, p2y, by };
    iosim_fb_fill_polygon(xs, ys, 3, color);
}

/* Stroke an open polyline. Square caps lengthen the first and last
 * segments; round caps add discs. */
static void stroke_core(const double *px, const double *py, int count,
                        int closed, double width, uint32_t color, int cap,
                        int join, double miter_limit)
{
    if (count < 2 || width <= 0)
        return;
    double half = width / 2.0;
    int segments = closed ? count : count - 1;
    double head_dx = 0, head_dy = 0, tail_dx = 0, tail_dy = 0;
    if (!closed && cap == 2)
    {
        double l0 = __builtin_sqrt((px[1] - px[0]) * (px[1] - px[0]) +
                                   (py[1] - py[0]) * (py[1] - py[0]));
        double ln = __builtin_sqrt((px[count - 1] - px[count - 2]) *
                                       (px[count - 1] - px[count - 2]) +
                                   (py[count - 1] - py[count - 2]) *
                                       (py[count - 1] - py[count - 2]));
        if (l0 > 1e-9)
        {
            head_dx = (px[1] - px[0]) / l0 * half;
            head_dy = (py[1] - py[0]) / l0 * half;
        }
        if (ln > 1e-9)
        {
            tail_dx = (px[count - 1] - px[count - 2]) / ln * half;
            tail_dy = (py[count - 1] - py[count - 2]) / ln * half;
        }
    }
    for (int i = 0; i < segments; i++)
    {
        int j = (i + 1) % count;
        double ax = px[i], ay = py[i], bx = px[j], by = py[j];
        if (i == 0)
        {
            ax -= head_dx;
            ay -= head_dy;
        }
        if (i == segments - 1)
        {
            bx += tail_dx;
            by += tail_dy;
        }
        stroke_segment(ax, ay, bx, by, half, color);
    }
    if (closed)
    {
        for (int i = 0; i < count; i++)
            stroke_join(px[(i + count - 1) % count],
                        py[(i + count - 1) % count], px[i], py[i],
                        px[(i + 1) % count], py[(i + 1) % count], half, color,
                        join, miter_limit);
    }
    else
    {
        for (int i = 1; i + 1 < count; i++)
            stroke_join(px[i - 1], py[i - 1], px[i], py[i], px[i + 1],
                        py[i + 1], half, color, join, miter_limit);
        if (cap == 1)
        {
            stroke_disc(px[0], py[0], half, color);
            stroke_disc(px[count - 1], py[count - 1], half, color);
        }
    }
}

static void stroke_path_point(const double *xs, const double *ys, int count,
                              int closed, double dist, double *out_x,
                              double *out_y)
{
    int segments = closed ? count : count - 1;
    double walked = 0;
    for (int i = 0; i < segments; i++)
    {
        int j = (i + 1) % count;
        double dx = xs[j] - xs[i], dy = ys[j] - ys[i];
        double len = __builtin_sqrt(dx * dx + dy * dy);
        if (len <= 1e-9)
            continue;
        if (dist <= walked + len)
        {
            double t = (dist - walked) / len;
            if (t < 0) t = 0;
            if (t > 1) t = 1;
            *out_x = xs[i] + dx * t;
            *out_y = ys[i] + dy * t;
            return;
        }
        walked += len;
    }
    *out_x = xs[closed ? 0 : count - 1];
    *out_y = ys[closed ? 0 : count - 1];
}

/* Gather the part of the polyline between distances a and b into an open
 * point list and stroke it. */
static void stroke_portion(const double *xs, const double *ys, int count,
                           int closed, double a, double b, double width,
                           uint32_t color, int cap, int join,
                           double miter_limit)
{
    int segments = closed ? count : count - 1;
    double *px = malloc(sizeof(double) * (count + 2));
    double *py = malloc(sizeof(double) * (count + 2));
    if (!px || !py)
    {
        free(px);
        free(py);
        return;
    }
    int n = 0;
    double walked = 0;
    for (int i = 0; i < segments; i++)
    {
        int j = (i + 1) % count;
        double ax = xs[i], ay = ys[i], bx = xs[j], by = ys[j];
        double len = __builtin_sqrt((bx - ax) * (bx - ax) +
                                    (by - ay) * (by - ay));
        if (len < 1e-9)
            continue;
        double seg_start = walked, seg_end = walked + len;
        walked = seg_end;
        if (seg_end <= a || seg_start >= b)
            continue;
        double t0 = (a - seg_start) / len, t1 = (b - seg_start) / len;
        if (t0 < 0) t0 = 0;
        if (t1 > 1) t1 = 1;
        double p0x = ax + (bx - ax) * t0, p0y = ay + (by - ay) * t0;
        double p1x = ax + (bx - ax) * t1, p1y = ay + (by - ay) * t1;
        if (n == 0 || __builtin_fabs(px[n - 1] - p0x) > 1e-9 ||
            __builtin_fabs(py[n - 1] - p0y) > 1e-9)
        {
            px[n] = p0x;
            py[n] = p0y;
            n++;
        }
        if (__builtin_fabs(px[n - 1] - p1x) > 1e-9 ||
            __builtin_fabs(py[n - 1] - p1y) > 1e-9)
        {
            px[n] = p1x;
            py[n] = p1y;
            n++;
        }
    }
    stroke_core(px, py, n, 0, width, color, cap, join, miter_limit);
    free(px);
    free(py);
}

void iosim_fb_stroke_polyline(const double *xs, const double *ys, int count,
                              int closed, double start, double end,
                              double width, uint32_t color, int cap,
                              int join, double miter_limit,
                              const double *dash, int dash_count,
                              double dash_phase)
{
    if (!fb_pixels || !xs || !ys || count < 2 || width <= 0)
        return;
    int segments = closed ? count : count - 1;
    double total = 0;
    for (int i = 0; i < segments; i++)
    {
        int j = (i + 1) % count;
        double dx = xs[j] - xs[i], dy = ys[j] - ys[i];
        total += __builtin_sqrt(dx * dx + dy * dy);
    }
    if (total <= 1e-9)
    {
        if (cap == 1)
            stroke_disc(xs[0], ys[0], width / 2.0, color);
        return;
    }
    if (miter_limit < 1.0)
        miter_limit = 1.0;
    double s0 = start * total, s1 = end * total;
    if (s0 < 0) s0 = 0;
    if (s0 > total) s0 = total;
    if (s1 < 0) s1 = 0;
    if (s1 > total) s1 = total;
    if (s1 <= s0)
        return;

    double pattern[32];
    int pattern_count = 0;
    if (dash && dash_count > 0)
    {
        if (dash_count > 16)
            dash_count = 16;
        int valid = 1;
        for (int i = 0; i < dash_count; i++)
        {
            if (dash[i] < 0)
                valid = 0;
            pattern[i] = dash[i];
        }
        if (valid)
        {
            pattern_count = dash_count;
            if (pattern_count & 1)
            {
                for (int i = 0; i < pattern_count &&
                                pattern_count * 2 <= 32; i++)
                    pattern[pattern_count + i] = pattern[i];
                if (pattern_count * 2 <= 32)
                    pattern_count *= 2;
            }
        }
    }
    double pattern_len = 0;
    for (int i = 0; i < pattern_count; i++)
        pattern_len += pattern[i];
    if (pattern_len <= 1e-9)
        pattern_count = 0;

    if (pattern_count == 0)
    {
        if (closed && s0 <= 1e-9 && s1 >= total - 1e-9)
            stroke_core(xs, ys, count, 1, width, color, cap, join,
                        miter_limit);
        else
            stroke_portion(xs, ys, count, closed, s0, s1, width, color, cap,
                           join, miter_limit);
        return;
    }

    double phase = __builtin_fmod(dash_phase, pattern_len);
    if (phase < 0)
        phase += pattern_len;
    /* Consume the phase offset, then walk the repeating on/off pattern
     * along the path. */
    int index = 0;
    while (phase >= pattern[index] && phase > 0)
    {
        phase -= pattern[index];
        index = (index + 1) % pattern_count;
    }
    double len = pattern[index] - phase;
    int on = (index & 1) == 0;
    double pos = 0;
    while (pos < total)
    {
        double next = pos + len;
        if (on)
        {
            if (len <= 1e-9)
            {
                if (cap == 1 && pos >= s0 - 1e-9 && pos <= s1 + 1e-9)
                {
                    double dot_x, dot_y;
                    stroke_path_point(xs, ys, count, closed, pos, &dot_x,
                                      &dot_y);
                    stroke_disc(dot_x, dot_y, width / 2.0, color);
                }
            }
            else
            {
                double a = pos > s0 ? pos : s0;
                double b = next < s1 ? next : s1;
                if (b > a)
                    stroke_portion(xs, ys, count, closed, a, b, width, color,
                                   cap, join, miter_limit);
            }
        }
        pos = next;
        index = (index + 1) % pattern_count;
        on = !on;
        len = pattern[index];
    }
}

void iosim_fb_draw_line(int x0, int y0, int x1, int y1, int thickness,
                        uint32_t color)
{
    if (thickness < 1)
        thickness = 1;
    int dx = x1 - x0, dy = y1 - y0;
    int steps = (dx < 0 ? -dx : dx) > (dy < 0 ? -dy : dy)
                    ? (dx < 0 ? -dx : dx) : (dy < 0 ? -dy : dy);
    if (steps == 0)
    {
        if (thickness <= 1)
            fb_blend_pixel(x0, y0, color, 1.0);
        else
            iosim_fb_fill_circle(x0, y0, thickness / 2, color);
        return;
    }
    double r = thickness / 2.0;
    for (int i = 0; i <= steps; i++)
    {
        double t = (double)i / steps;
        double px = x0 + dx * t, py = y0 + dy * t;
        int cx = (int)(px + 0.5), cy = (int)(py + 0.5);
        if (thickness <= 1)
            fb_blend_pixel(cx, cy, color, 1.0);
        else
            iosim_fb_fill_circle(cx, cy, (int)(r + 0.5), color);
    }
}

void iosim_fb_stroke_circle(int cx, int cy, int radius, int thickness,
                            uint32_t color)
{
    if (!fb_pixels || radius <= 0 || thickness <= 0)
        return;
    double half = thickness / 2.0;
    int range = radius + (int)(half + 2.0);
    int x0 = cx - range, x1 = cx + range + 1;
    int y0 = cy - range, y1 = cy + range + 1;
    if (x0 < fb_clip_x0()) x0 = fb_clip_x0();
    if (y0 < fb_clip_y0()) y0 = fb_clip_y0();
    if (x1 > fb_clip_x1()) x1 = fb_clip_x1();
    if (y1 > fb_clip_y1()) y1 = fb_clip_y1();
    int fg_r = (color >> 16) & 0xFF, fg_g = (color >> 8) & 0xFF,
        fg_b = color & 0xFF;
    for (int y = y0; y < y1; y++)
    {
        uint32_t *row = fb_pixels + (size_t)y * fb_width;
        double dy = y + 0.5 - cy;
        for (int x = x0; x < x1; x++)
        {
            double dx = x + 0.5 - cx;
            double d = __builtin_fabs(__builtin_sqrt(dx * dx + dy * dy) -
                                      radius) - half;
            double coverage = (0.5 - d) * fb_opacity;
            if (coverage <= 0)
                continue;
            if (coverage > fb_opacity)
                coverage = fb_opacity;
            if (coverage >= 1)
            {
                row[x] = fb_full(color);
                continue;
            }
            unsigned a = (unsigned)(coverage * 255.0 + 0.5);
            uint32_t dst = row[x];
            unsigned r = (fg_r * a + ((dst >> 16) & 0xFF) * (255 - a) + 127) / 255;
            unsigned g = (fg_g * a + ((dst >> 8) & 0xFF) * (255 - a) + 127) / 255;
            unsigned b = (fg_b * a + (dst & 0xFF) * (255 - a) + 127) / 255;
            row[x] = fb_pack(dst, r, g, b, a);
        }
    }
}

void iosim_fb_fill_ellipse(int cx, int cy, int rx, int ry, uint32_t color)
{
    if (rx <= 0 || ry <= 0)
        return;
    int x0 = cx - rx - 1, x1 = cx + rx + 2;
    int y0 = cy - ry - 1, y1 = cy + ry + 2;
    if (x0 < 0) x0 = 0;
    if (y0 < 0) y0 = 0;
    if (x1 > (int)fb_width) x1 = (int)fb_width;
    if (y1 > (int)fb_height) y1 = (int)fb_height;
    int fg_r = (color >> 16) & 0xFF, fg_g = (color >> 8) & 0xFF,
        fg_b = color & 0xFF;
    double scale = rx < ry ? rx : ry;
    for (int y = y0; y < y1; y++)
    {
        double dy = (y + 0.5 - cy) / ry;
        for (int x = x0; x < x1; x++)
        {
            int mcov = fb_mask_coverage(x, y);
            if (!mcov)
                continue;
            double mask = mcov / 255.0;
            double dx = (x + 0.5 - cx) / rx;
            double d = (__builtin_sqrt(dx * dx + dy * dy) - 1.0) * scale;
            double top = fb_opacity * mask;
            double coverage = (0.5 - d) * top;
            if (coverage <= 0)
                continue;
            if (coverage > top)
                coverage = top;
            uint32_t *row = fb_pixels + (size_t)y * fb_width;
            if (coverage >= 1)
            {
                row[x] = fb_full(color);
                continue;
            }
            unsigned a = (unsigned)(coverage * 255.0 + 0.5);
            uint32_t dst = row[x];
            unsigned r = (fg_r * a + ((dst >> 16) & 0xFF) * (255 - a) + 127) / 255;
            unsigned g = (fg_g * a + ((dst >> 8) & 0xFF) * (255 - a) + 127) / 255;
            unsigned b = (fg_b * a + (dst & 0xFF) * (255 - a) + 127) / 255;
            row[x] = fb_pack(dst, r, g, b, a);
        }
    }
}

void iosim_fb_fill_polygon(const double *xs, const double *ys, int count,
                           uint32_t color)
{
    if (!fb_pixels || count < 3 || !xs || !ys)
        return;
    double minY = ys[0], maxY = ys[0];
    for (int i = 1; i < count; i++)
    {
        if (ys[i] < minY) minY = ys[i];
        if (ys[i] > maxY) maxY = ys[i];
    }
    int y0 = (int)minY - 1, y1 = (int)maxY + 2;
    if (y0 < 0) y0 = 0;
    if (y1 > (int)fb_height) y1 = (int)fb_height;
    double *cov = malloc(sizeof(double) * fb_width);
    double *cross = malloc(sizeof(double) * count);
    if (!cov || !cross)
    {
        free(cov); free(cross);
        return;
    }
    const int SUB = 4;
    for (int y = y0; y < y1; y++)
    {
        memset(cov, 0, sizeof(double) * fb_width);
        for (int s = 0; s < SUB; s++)
        {
            double sy = y + (s + 0.5) / SUB;
            int n = 0;
            for (int i = 0, j = count - 1; i < count; j = i++)
            {
                if ((ys[i] > sy) != (ys[j] > sy))
                {
                    double t = (sy - ys[i]) / (ys[j] - ys[i]);
                    cross[n++] = xs[i] + t * (xs[j] - xs[i]);
                }
            }
            for (int a = 1; a < n; a++)
            {
                double v = cross[a];
                int b = a - 1;
                while (b >= 0 && cross[b] > v)
                {
                    cross[b + 1] = cross[b];
                    b--;
                }
                cross[b + 1] = v;
            }
            for (int a = 0; a + 1 < n; a += 2)
            {
                double xa = cross[a], xb = cross[a + 1];
                if (xb <= 0 || xa >= (double)fb_width)
                    continue;
                if (xa < 0) xa = 0;
                if (xb > (double)fb_width) xb = (double)fb_width;
                int ia = (int)xa, ib = (int)(xb + 0.999);
                for (int x = ia; x < ib && x < (int)fb_width; x++)
                {
                    double left = x > xa ? x : xa;
                    double right = x + 1 < xb ? x + 1 : xb;
                    if (right > left)
                        cov[x] += (right - left) / SUB;
                }
            }
        }
        for (int x = 0; x < (int)fb_width; x++)
            if (cov[x] > 0)
                fb_blend_pixel(x, y, color, cov[x] > 1 ? 1 : cov[x]);
    }
    free(cov);
    free(cross);
}

void iosim_fb_fill_linear_gradient(int x, int y, int w, int h,
                                   uint32_t start_color, uint32_t end_color,
                                   double sx, double sy, double ex, double ey)
{
    if (!fb_pixels || w <= 0 || h <= 0)
        return;
    double ax = x + sx * w, ay = y + sy * h;
    double bx = x + ex * w, by = y + ey * h;
    double dx = bx - ax, dy = by - ay;
    double len2 = dx * dx + dy * dy;
    if (len2 < 1e-9)
    {
        iosim_fb_fill_rect(x, y, w, h, start_color);
        return;
    }
    int x0 = x < 0 ? 0 : x, y0 = y < 0 ? 0 : y;
    int x1 = x + w > (int)fb_width ? (int)fb_width : x + w;
    int y1 = y + h > (int)fb_height ? (int)fb_height : y + h;
    int sr = (start_color >> 16) & 0xFF, sg = (start_color >> 8) & 0xFF,
        sb = start_color & 0xFF;
    int er = (end_color >> 16) & 0xFF, eg = (end_color >> 8) & 0xFF,
        eb = end_color & 0xFF;
    for (int yy = y0; yy < y1; yy++)
    {
        uint32_t *row = fb_pixels + (size_t)yy * fb_width;
        for (int xx = x0; xx < x1; xx++)
        {
            double t = ((xx + 0.5 - ax) * dx + (yy + 0.5 - ay) * dy) / len2;
            if (t < 0) t = 0;
            if (t > 1) t = 1;
            unsigned r = (unsigned)(sr + (er - sr) * t + 0.5);
            unsigned g = (unsigned)(sg + (eg - sg) * t + 0.5);
            unsigned b = (unsigned)(sb + (eb - sb) * t + 0.5);
            fb_blend_pixel(xx, yy, (r << 16) | (g << 8) | b, 1.0);
        }
    }
}

void iosim_fb_fill_gradient_stops_alpha(int x, int y, int w, int h,
                                        const uint32_t *colors,
                                        const uint8_t *alphas,
                                        const double *locations, int count,
                                        double ax, double ay, double bx,
                                        double by)
{
    if (!fb_pixels || w <= 0 || h <= 0 || !colors || count <= 0)
        return;
    double dx = bx - ax, dy = by - ay;
    double len2 = dx * dx + dy * dy;
    if (len2 < 1e-9)
    {
        unsigned a = alphas ? alphas[count - 1] : 255;
        if (!a)
            return;
        int x0 = x < 0 ? 0 : x, y0 = y < 0 ? 0 : y;
        int x1 = x + w > (int)fb_width ? (int)fb_width : x + w;
        int y1 = y + h > (int)fb_height ? (int)fb_height : y + h;
        for (int yy = y0; yy < y1; yy++)
            for (int xx = x0; xx < x1; xx++)
                fb_blend_pixel(xx, yy, colors[count - 1], a / 255.0);
        return;
    }
    int x0 = x < 0 ? 0 : x, y0 = y < 0 ? 0 : y;
    int x1 = x + w > (int)fb_width ? (int)fb_width : x + w;
    int y1 = y + h > (int)fb_height ? (int)fb_height : y + h;
    for (int yy = y0; yy < y1; yy++)
    {
        for (int xx = x0; xx < x1; xx++)
        {
            double t = ((xx + 0.5 - ax) * dx + (yy + 0.5 - ay) * dy) / len2;
            if (t < 0) t = 0;
            if (t > 1) t = 1;
            int segment = 0;
            while (segment + 2 < count && t > locations[segment + 1])
                segment++;
            int next = segment + 1 < count ? segment + 1 : segment;
            double t0 = locations[segment];
            double t1 = locations[next];
            double f = t1 > t0 ? (t - t0) / (t1 - t0) : 0;
            if (f < 0) f = 0;
            if (f > 1) f = 1;
            uint32_t ca = colors[segment];
            uint32_t cb = colors[next];
            int ar = (int)((ca >> 16) & 0xFF);
            int ag = (int)((ca >> 8) & 0xFF);
            int ab = (int)(ca & 0xFF);
            int br = (int)((cb >> 16) & 0xFF);
            int bg = (int)((cb >> 8) & 0xFF);
            int bb = (int)(cb & 0xFF);
            unsigned r = (unsigned)(ar + (br - ar) * f + 0.5);
            unsigned g = (unsigned)(ag + (bg - ag) * f + 0.5);
            unsigned b = (unsigned)(ab + (bb - ab) * f + 0.5);
            unsigned aa = 255;
            if (alphas)
            {
                int a0 = alphas[segment], a1 = alphas[next];
                aa = (unsigned)(a0 + (a1 - a0) * f + 0.5);
            }
            if (!aa)
                continue;
            fb_blend_pixel(xx, yy, (r << 16) | (g << 8) | b, aa / 255.0);
        }
    }
}

void iosim_fb_fill_gradient_stops(int x, int y, int w, int h,
                                  const uint32_t *colors,
                                  const double *locations, int count,
                                  double ax, double ay, double bx, double by)
{
    iosim_fb_fill_gradient_stops_alpha(x, y, w, h, colors, 0, locations,
                                       count, ax, ay, bx, by);
}

void iosim_fb_blit_rgba(int x, int y, int w, int h, const uint8_t *rgba,
                        int stride)
{
    if (!fb_pixels || !rgba || w <= 0 || h <= 0)
        return;
    if (stride <= 0)
        stride = w * 4;
    for (int yy = 0; yy < h; yy++)
    {
        int dy = y + yy;
        if (dy < 0 || dy >= (int)fb_height)
            continue;
        const uint8_t *src = rgba + (size_t)yy * stride;
        uint32_t *row = fb_pixels + (size_t)dy * fb_width;
        for (int xx = 0; xx < w; xx++)
        {
            int dx = x + xx;
            if (dx < 0 || dx >= (int)fb_width)
                continue;
            if (dx < fb_clip_x0() || dx >= fb_clip_x1() ||
                dy < fb_clip_y0() || dy >= fb_clip_y1())
                continue;
            int mcov = fb_mask_coverage(dx, dy);
            if (!mcov)
                continue;
            unsigned sa = src[xx * 4 + 3];
            if (!sa)
                continue;
            double a = (sa / 255.0) * fb_opacity * (mcov / 255.0);
            uint32_t fg = ((unsigned)src[xx * 4] << 16) |
                          ((unsigned)src[xx * 4 + 1] << 8) |
                          src[xx * 4 + 2];
            uint32_t dst = row[dx];
            unsigned ia = (unsigned)(a * 255.0 + 0.5);
            unsigned r = (((fg >> 16) & 0xFF) * ia + ((dst >> 16) & 0xFF) * (255 - ia) + 127) / 255;
            unsigned g = (((fg >> 8) & 0xFF) * ia + ((dst >> 8) & 0xFF) * (255 - ia) + 127) / 255;
            unsigned b = ((fg & 0xFF) * ia + (dst & 0xFF) * (255 - ia) + 127) / 255;
            row[dx] = fb_pack(dst, r, g, b, ia);
        }
    }
}

int iosim_fb_width(void) { return (int)fb_width; }
int iosim_fb_height(void) { return (int)fb_height; }

void iosim_fb_blit_rgba_scaled(int x, int y, int w, int h,
                               const uint8_t *rgba, int sw, int sh,
                               int stride)
{
    if (!fb_pixels || !rgba || w <= 0 || h <= 0 || sw <= 0 || sh <= 0)
        return;
    if (stride <= 0)
        stride = sw * 4;
    for (int yy = 0; yy < h; yy++)
    {
        int dy = y + yy;
        if (dy < 0 || dy >= (int)fb_height)
            continue;
        double fy = ((yy + 0.5) * sh / h) - 0.5;
        int y0 = (int)__builtin_floor(fy);
        double ty = fy - y0;
        int y0c = y0 < 0 ? 0 : (y0 >= sh ? sh - 1 : y0);
        int y1c = y0 + 1 < 0 ? 0 : (y0 + 1 >= sh ? sh - 1 : y0 + 1);
        uint32_t *row = fb_pixels + (size_t)dy * fb_width;
        for (int xx = 0; xx < w; xx++)
        {
            int dx = x + xx;
            if (dx < 0 || dx >= (int)fb_width)
                continue;
            if (dx < fb_clip_x0() || dx >= fb_clip_x1() ||
                dy < fb_clip_y0() || dy >= fb_clip_y1())
                continue;
            int mcov = fb_mask_coverage(dx, dy);
            if (!mcov)
                continue;
            double fx = ((xx + 0.5) * sw / w) - 0.5;
            int x0 = (int)__builtin_floor(fx);
            double tx = fx - x0;
            int x0c = x0 < 0 ? 0 : (x0 >= sw ? sw - 1 : x0);
            int x1c = x0 + 1 < 0 ? 0 : (x0 + 1 >= sw ? sw - 1 : x0 + 1);
            const uint8_t *p00 = rgba + (size_t)y0c * stride + x0c * 4;
            const uint8_t *p10 = rgba + (size_t)y0c * stride + x1c * 4;
            const uint8_t *p01 = rgba + (size_t)y1c * stride + x0c * 4;
            const uint8_t *p11 = rgba + (size_t)y1c * stride + x1c * 4;
            double c[4];
            for (int k = 0; k < 4; k++)
            {
                double top = p00[k] * (1 - tx) + p10[k] * tx;
                double bot = p01[k] * (1 - tx) + p11[k] * tx;
                c[k] = top * (1 - ty) + bot * ty;
            }
            double a = (c[3] / 255.0) * fb_opacity * (mcov / 255.0);
            if (a <= 0)
                continue;
            uint32_t dst = row[dx];
            unsigned ia = (unsigned)(a * 255.0 + 0.5);
            unsigned r, g, b;
            if (fb_blend_mode)
            {
                uint32_t src = ((unsigned)(c[0] + 0.5) << 16) |
                               ((unsigned)(c[1] + 0.5) << 8) |
                               (unsigned)(c[2] + 0.5);
                fb_blend_color(fb_blend_mode, src, dst, a, &r, &g, &b);
            }
            else
            {
                r = ((unsigned)(c[0] + 0.5) * ia + ((dst >> 16) & 0xFF) * (255 - ia) + 127) / 255;
                g = ((unsigned)(c[1] + 0.5) * ia + ((dst >> 8) & 0xFF) * (255 - ia) + 127) / 255;
                b = ((unsigned)(c[2] + 0.5) * ia + (dst & 0xFF) * (255 - ia) + 127) / 255;
            }
            row[dx] = fb_pack(dst, r, g, b, ia);
        }
    }
}

void iosim_fb_fill_linear_gradient_round_rect(int x, int y, int w, int h,
                                              int radius, uint32_t start_color,
                                              uint32_t end_color, double sx,
                                              double sy, double ex, double ey)
{
    if (!fb_pixels || w <= 0 || h <= 0)
        return;
    if (radius <= 0)
    {
        iosim_fb_fill_linear_gradient(x, y, w, h, start_color, end_color,
                                      sx, sy, ex, ey);
        return;
    }
    if (radius * 2 > w) radius = w / 2;
    if (radius * 2 > h) radius = h / 2;
    double ax = x + sx * w, ay = y + sy * h;
    double bx = x + ex * w, by = y + ey * h;
    double dx = bx - ax, dy = by - ay;
    double len2 = dx * dx + dy * dy;
    if (len2 < 1e-9) len2 = 1.0;
    int x0 = x < 0 ? 0 : x, y0 = y < 0 ? 0 : y;
    int x1 = x + w > (int)fb_width ? (int)fb_width : x + w;
    int y1 = y + h > (int)fb_height ? (int)fb_height : y + h;
    int sr = (start_color >> 16) & 0xFF, sg = (start_color >> 8) & 0xFF,
        sb = start_color & 0xFF;
    int er = (end_color >> 16) & 0xFF, eg = (end_color >> 8) & 0xFF,
        eb = end_color & 0xFF;
    double cx = x + w / 2.0, cy = y + h / 2.0;
    double exr = w / 2.0 - radius, eyr = h / 2.0 - radius;
    for (int yy = y0; yy < y1; yy++)
    {
        double py = yy + 0.5 - cy;
        double qy = __builtin_fabs(py) - eyr;
        for (int xx = x0; xx < x1; xx++)
        {
            double px = xx + 0.5 - cx;
            double qx = __builtin_fabs(px) - exr;
            double axr = qx > 0 ? qx : 0, ayr = qy > 0 ? qy : 0;
            double outside = __builtin_sqrt(axr * axr + ayr * ayr);
            double inside = qx > qy ? qx : qy;
            double d = outside + (inside < 0 ? inside : 0) - radius;
            double coverage = (0.5 - d) * fb_opacity;
            if (coverage <= 0)
                continue;
            if (coverage > 1) coverage = 1;
            double t = ((xx + 0.5 - ax) * dx + (yy + 0.5 - ay) * dy) / len2;
            if (t < 0) t = 0;
            if (t > 1) t = 1;
            unsigned r = (unsigned)(sr + (er - sr) * t + 0.5);
            unsigned g = (unsigned)(sg + (eg - sg) * t + 0.5);
            unsigned b = (unsigned)(sb + (eb - sb) * t + 0.5);
            double save = fb_opacity;
            fb_opacity = 1.0;
            fb_blend_pixel(xx, yy, (r << 16) | (g << 8) | b, coverage);
            fb_opacity = save;
        }
    }
}
