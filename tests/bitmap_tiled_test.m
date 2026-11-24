/* CoreGraphics bitmap contexts and tiled images: an 8-bit RGBA bitmap
 * context renders shapes, returns its data and makes a CGImage; tiled image
 * drawing repeats a 2x2 tile across a rect and honors clipping. */
#include "UIKitStub.h"

extern int printf(const char *fmt, ...);
extern int fflush(void *stream);
extern int iosim_fb_begin(unsigned width, unsigned height);
extern void iosim_fb_capture(int x, int y, int w, int h, unsigned *out);
extern void *malloc(unsigned long size);
extern void free(void *ptr);
extern void *memset(void *dst, int value, unsigned long count);

#define W 300
#define H 300

static unsigned *g_fb;

static unsigned px(int x, int y)
{
    return g_fb[(unsigned long)y * W + x] & 0xffffff;
}

static int is(unsigned color, int r, int g, int b)
{
    return (int)((color >> 16) & 255) == r &&
           (int)((color >> 8) & 255) == g &&
           (int)(color & 255) == b;
}

static void snap(void)
{
    iosim_fb_capture(0, 0, W, H, g_fb);
}

int main(void)
{
    unsigned char tile[2 * 2 * 4] = {
        255, 0, 0, 255,     0, 255, 0, 255,
        0, 0, 255, 255,     255, 255, 0, 255
    };
    CGImageRef image = CGImageCreateWithRGBA(tile, 2, 2);
    iosim_fb_begin(W, H);
    CGContextRef context = iosim_cg_begin_view(0, 0, W, H, 1.0, 1.0);
    CGContextSetRGBFillColor(context, 0.1, 0.1, 0.1, 1);
    CGContextFillRect(context, CGRectMake(0, 0, W, H));
    CGContextDrawTiledImage(context, CGRectMake(20, 20, 60, 60), image);
    g_fb = malloc((unsigned long)W * H * sizeof(unsigned));
    snap();
    printf("[cg] tiled colors %d %d %d %d\n",
           is(px(20, 20), 255, 0, 0), is(px(21, 20), 0, 255, 0),
           is(px(20, 21), 0, 0, 255), is(px(21, 21), 255, 255, 0));
    printf("[cg] tiled edge %d %d\n", is(px(79, 79), 255, 255, 0),
           is(px(80, 20), 26, 26, 26));
    CGContextSaveGState(context);
    CGContextClipToRect(context, CGRectMake(120, 20, 30, 60));
    CGContextDrawTiledImage(context, CGRectMake(120, 20, 60, 60), image);
    CGContextRestoreGState(context);
    snap();
    printf("[cg] tiled clip %d %d\n", is(px(125, 25), 255, 255, 0),
           is(px(155, 25), 26, 26, 26));

    unsigned char data[8 * 8 * 4];
    memset(data, 0, sizeof(data));
    CGContextRef bitmap = CGBitmapContextCreate(data, 8, 8, 8, 32, 0, 0);
    CGContextSetRGBFillColor(bitmap, 1, 0, 0, 1);
    CGContextFillRect(bitmap, CGRectMake(0, 0, 8, 8));
    CGContextSetRGBFillColor(bitmap, 0, 1, 0, 1);
    CGContextFillRect(bitmap, CGRectMake(2, 2, 4, 4));
    CGImageRef bitmapImage = CGBitmapContextCreateImage(bitmap);
    printf("[cg] bitmap size %lu %lu %d %d\n",
           CGBitmapContextGetWidth(bitmap),
           CGBitmapContextGetHeight(bitmap),
           bitmapImage ? CGImageGetWidth(bitmapImage) : 0,
           bitmapImage ? CGImageGetHeight(bitmapImage) : 0);
    unsigned char *got = CGBitmapContextGetData(bitmap);
    printf("[cg] bitmap pixels %d %d\n",
           got == data && got[0] == 255 && got[1] == 0 && got[2] == 0,
           got && got[(2 * 8 + 2) * 4 + 0] == 0 &&
               got[(2 * 8 + 2) * 4 + 1] == 255);
    /* End the bitmap context to restore the main framebuffer target
     * before drawing its image back through the view context. */
    iosim_cg_end_image(bitmap);
    CGContextDrawImage(context, CGRectMake(20, 120, 16, 16), bitmapImage);
    snap();
    printf("[cg] bitmap drawn %d %d\n", is(px(22, 122), 255, 0, 0),
           is(px(26, 126), 0, 255, 0));

    CGImageRelease(bitmapImage);
    iosim_cg_end_view(context);
    CGImageRelease(image);
    free(g_fb);
    fflush(0);
    return 0;
}
