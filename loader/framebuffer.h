#ifndef IOSIM_FRAMEBUFFER_H
#define IOSIM_FRAMEBUFFER_H

#include <stdint.h>

/* A tiny software framebuffer used by the reimplemented UIKit. Colors are
 * 0x00RRGGBB and fully opaque. */
int  iosim_fb_begin(unsigned width, unsigned height);
void iosim_fb_release(void);
void iosim_fb_clear(uint32_t color);
void iosim_fb_fill_rect(int x, int y, int w, int h, uint32_t color);
void iosim_fb_fill_round_rect(int x, int y, int w, int h, int radius,
                              uint32_t color);
void iosim_fb_text(int x, int y, int scale, uint32_t color, const char *text);
int  iosim_fb_text_width(const char *text, int scale);
int  iosim_fb_present(const char *path);

/* System-font text (FreeType). Sizes are in UIKit points; scale converts to
 * device pixels. style: 0 regular, 1 bold, 2 semibold. */
#define IOSIM_FONT_REGULAR  0
#define IOSIM_FONT_BOLD     1
#define IOSIM_FONT_SEMIBOLD 2
int  iosim_fb_font_text_width(const char *text, int style, double size_pt,
                              double scale);
void iosim_fb_font_text(int x, int baseline_y, const char *text, int style,
                        double size_pt, double scale, uint32_t color);
void iosim_fb_font_metrics(int style, double size_pt, double scale,
                           int *ascent, int *descent, int *line_height);

#endif
