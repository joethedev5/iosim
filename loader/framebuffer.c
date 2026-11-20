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
static double fb_opacity = 1.0;
static unsigned fb_width;
static unsigned fb_height;

#define FB_MAX_CLIP 16
static int fb_clip_rects[FB_MAX_CLIP][4];
static int fb_clip_depth;

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
    return 0;
}

void iosim_fb_release(void)
{
    free(fb_pixels);
    fb_pixels = NULL;
    fb_width = fb_height = 0;
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
    if (fb_opacity >= 0.999)
    {
        for (int yy = y0; yy < y1; yy++)
        {
            uint32_t *row = fb_pixels + (size_t)yy * fb_width;
            for (int xx = x0; xx < x1; xx++)
                row[xx] = color;
        }
        return;
    }
    unsigned fa = (unsigned)(fb_opacity * 255.0 + 0.5);
    unsigned fr = (color >> 16) & 0xFF, fg = (color >> 8) & 0xFF,
             fb = color & 0xFF;
    for (int yy = y0; yy < y1; yy++)
    {
        uint32_t *row = fb_pixels + (size_t)yy * fb_width;
        for (int xx = x0; xx < x1; xx++)
        {
            uint32_t dst = row[xx];
            unsigned r = (fr * fa + ((dst >> 16) & 0xFF) * (255 - fa) + 127) / 255;
            unsigned g = (fg * fa + ((dst >> 8) & 0xFF) * (255 - fa) + 127) / 255;
            unsigned b = (fb * fa + (dst & 0xFF) * (255 - fa) + 127) / 255;
            row[xx] = (r << 16) | (g << 8) | b;
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
            double px = xx + 0.5 - cx;
            double qx = __builtin_fabs(px) - ex;
            double qy = __builtin_fabs(py) - ey;
            double ax = qx > 0 ? qx : 0, ay = qy > 0 ? qy : 0;
            double outside = __builtin_sqrt(ax * ax + ay * ay);
            double inside = qx > qy ? qx : qy;
            double d = outside + (inside < 0 ? inside : 0) - radius;
            double coverage = (0.5 - d) * fb_opacity;
            if (coverage <= 0)
                continue;
            if (coverage >= 1)
            {
                row[xx] = color;
                continue;
            }
            unsigned a = (unsigned)(coverage * 255.0 + 0.5);
            uint32_t dst = row[xx];
            unsigned r = (fg_r * a + ((dst >> 16) & 0xFF) * (255 - a) + 127) / 255;
            unsigned g = (fg_g * a + ((dst >> 8) & 0xFF) * (255 - a) + 127) / 255;
            unsigned b = (fg_b * a + (dst & 0xFF) * (255 - a) + 127) / 255;
            row[xx] = (r << 16) | (g << 8) | b;
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
            double dx = x + 0.5 - cx;
            double d = __builtin_sqrt(dx * dx + dy * dy) - radius;
            double coverage = (0.5 - d) * fb_opacity;
            if (coverage <= 0)
                continue;
            if (coverage >= 1)
            {
                row[x] = color;
                continue;
            }
            unsigned a = (unsigned)(coverage * 255.0 + 0.5);
            uint32_t dst = row[x];
            unsigned r = (fg_r * a + ((dst >> 16) & 0xFF) * (255 - a) + 127) / 255;
            unsigned g = (fg_g * a + ((dst >> 8) & 0xFF) * (255 - a) + 127) / 255;
            unsigned b = (fg_b * a + (dst & 0xFF) * (255 - a) + 127) / 255;
            row[x] = (r << 16) | (g << 8) | b;
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
    {
        static const uint8_t srgb_intent = 0;
        rc = write_chunk(f, "sRGB", &srgb_intent, 1);
    }
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
                unsigned a = (unsigned)(src[col] * fb_opacity + 0.5);
                if (!a)
                    continue;
                uint32_t d = dst[xx];
                unsigned dr = (d >> 16) & 0xFF;
                unsigned dg = (d >> 8) & 0xFF;
                unsigned db = d & 0xFF;
                unsigned r = (fg_r * a + dr * (255 - a) + 127) / 255;
                unsigned g = (fg_g * a + dg * (255 - a) + 127) / 255;
                unsigned b = (fg_b * a + db * (255 - a) + 127) / 255;
                dst[xx] = (r << 16) | (g << 8) | b;
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
    coverage *= fb_opacity;
    if (coverage <= 0)
        return;
    uint32_t *row = fb_pixels + (size_t)y * fb_width;
    if (coverage >= 0.999)
    {
        row[x] = color;
        return;
    }
    unsigned a = (unsigned)(coverage * 255.0 + 0.5);
    uint32_t dst = row[x];
    unsigned r = (((color >> 16) & 0xFF) * a + ((dst >> 16) & 0xFF) * (255 - a) + 127) / 255;
    unsigned g = (((color >> 8) & 0xFF) * a + ((dst >> 8) & 0xFF) * (255 - a) + 127) / 255;
    unsigned b = ((color & 0xFF) * a + (dst & 0xFF) * (255 - a) + 127) / 255;
    row[x] = (r << 16) | (g << 8) | b;
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
            double dx = (x + 0.5 - cx) / rx;
            double d = (__builtin_sqrt(dx * dx + dy * dy) - 1.0) * scale;
            double coverage = (0.5 - d) * fb_opacity;
            if (coverage <= 0)
                continue;
            uint32_t *row = fb_pixels + (size_t)y * fb_width;
            if (coverage >= 1)
            {
                row[x] = color;
                continue;
            }
            unsigned a = (unsigned)(coverage * 255.0 + 0.5);
            uint32_t dst = row[x];
            unsigned r = (fg_r * a + ((dst >> 16) & 0xFF) * (255 - a) + 127) / 255;
            unsigned g = (fg_g * a + ((dst >> 8) & 0xFF) * (255 - a) + 127) / 255;
            unsigned b = (fg_b * a + (dst & 0xFF) * (255 - a) + 127) / 255;
            row[x] = (r << 16) | (g << 8) | b;
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
            unsigned sa = src[xx * 4 + 3];
            if (!sa)
                continue;
            double a = (sa / 255.0) * fb_opacity;
            uint32_t fg = ((unsigned)src[xx * 4] << 16) |
                          ((unsigned)src[xx * 4 + 1] << 8) |
                          src[xx * 4 + 2];
            uint32_t dst = row[dx];
            unsigned ia = (unsigned)(a * 255.0 + 0.5);
            unsigned r = (((fg >> 16) & 0xFF) * ia + ((dst >> 16) & 0xFF) * (255 - ia) + 127) / 255;
            unsigned g = (((fg >> 8) & 0xFF) * ia + ((dst >> 8) & 0xFF) * (255 - ia) + 127) / 255;
            unsigned b = ((fg & 0xFF) * ia + (dst & 0xFF) * (255 - ia) + 127) / 255;
            row[dx] = (r << 16) | (g << 8) | b;
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
            double a = (c[3] / 255.0) * fb_opacity;
            if (a <= 0)
                continue;
            uint32_t dst = row[dx];
            unsigned ia = (unsigned)(a * 255.0 + 0.5);
            unsigned r = ((unsigned)(c[0] + 0.5) * ia + ((dst >> 16) & 0xFF) * (255 - ia) + 127) / 255;
            unsigned g = ((unsigned)(c[1] + 0.5) * ia + ((dst >> 8) & 0xFF) * (255 - ia) + 127) / 255;
            unsigned b = ((unsigned)(c[2] + 0.5) * ia + (dst & 0xFF) * (255 - ia) + 127) / 255;
            row[dx] = (r << 16) | (g << 8) | b;
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
