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

#endif
