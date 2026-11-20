#define _GNU_SOURCE
#include "framebuffer.h"
#include "font8x8_basic.h"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <errno.h>
#include <sys/stat.h>
#include <zlib.h>

static uint32_t *fb_pixels;
static unsigned fb_width;
static unsigned fb_height;

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
    return 0;
}

void iosim_fb_release(void)
{
    free(fb_pixels);
    fb_pixels = NULL;
    fb_width = fb_height = 0;
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
    int x0 = x < 0 ? 0 : x;
    int y0 = y < 0 ? 0 : y;
    int x1 = x + w > (int)fb_width ? (int)fb_width : x + w;
    int y1 = y + h > (int)fb_height ? (int)fb_height : y + h;
    for (int yy = y0; yy < y1; yy++)
    {
        uint32_t *row = fb_pixels + (size_t)yy * fb_width;
        for (int xx = x0; xx < x1; xx++)
            row[xx] = color;
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

    for (int yy = 0; yy < h; yy++)
    {
        int dy = 0;
        if (yy < radius)
            dy = radius - yy;
        else if (yy >= h - radius)
            dy = yy - (h - radius - 1);
        int span = w;
        if (dy > 0)
        {
            int dx = radius - (int)(0.5 + __builtin_sqrt((double)(radius * radius - dy * dy)));
            if (dx < 0)
                dx = 0;
            if (dx * 2 >= w)
                continue;
            span = w - dx * 2;
            iosim_fb_fill_rect(x + dx, y + yy, span, 1, color);
        }
        else
        {
            iosim_fb_fill_rect(x, y + yy, span, 1, color);
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
    FILE *f = fopen(path, "wb");
    if (!f)
    {
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
        rc = write_chunk(f, "IDAT", comp, (uint32_t)comp_len);
    if (rc == 0)
        rc = write_chunk(f, "IEND", NULL, 0);
    fclose(f);
    free(comp);

    if (rc == 0)
        fprintf(stderr, "iosim: framebuffer %ux%u written to %s\n",
                fb_width, fb_height, path);
    return rc;
}
