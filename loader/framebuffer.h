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
void iosim_fb_fill_ellipse_gradient(int cx, int cy, int rx, int ry, uint32_t top_color, uint32_t bottom_color);
void iosim_fb_fill_ellipse_ring_gradient(int cx, int cy, int rx, int ry, int thickness, const uint32_t *colors, const double *stops, int nstops);
void iosim_fb_fill_arc_gradient(int cx, int cy, int radius, int thickness, double start_deg, double sweep_deg, const uint32_t *colors, const double *stops, int nstops);
void iosim_fb_fill_circle_gradient(int cx, int cy, int radius, uint32_t top_color, uint32_t bottom_color);
void iosim_fb_fill_circle(int cx, int cy, int radius, uint32_t color);
void iosim_fb_stroke_circle(int cx, int cy, int radius, int thickness,
                            uint32_t color);
void iosim_fb_fill_squircle(int x, int y, int w, int h, uint32_t color);
void iosim_fb_fill_squircle_gradient(int x, int y, int w, int h,
                                     uint32_t top, uint32_t bottom);
void iosim_fb_set_opacity(double opacity);
int iosim_fb_push_clip(int x, int y, int w, int h);
void iosim_fb_pop_clip(void);
int iosim_fb_push_clip_polygon(const double *xs, const double *ys, int count);
/* Push an 8-bit coverage mask positioned at (x, y). Values below 255 make
 * subsequent drawing partially transparent (used for CALayer masks). */
int iosim_fb_push_clip_alpha(const uint8_t *alpha, int w, int h, int x, int y);
void iosim_fb_pop_clip_mask(void);
void iosim_fb_text(int x, int y, int scale, uint32_t color, const char *text);
int  iosim_fb_text_width(const char *text, int scale);
int  iosim_fb_present(const char *path);
void iosim_fb_draw_line(int x0, int y0, int x1, int y1, int thickness,
                        uint32_t color);
void iosim_fb_fill_ellipse(int cx, int cy, int rx, int ry, uint32_t color);
void iosim_fb_fill_polygon(const double *xs, const double *ys, int count,
                           uint32_t color);
void iosim_fb_fill_linear_gradient(int x, int y, int w, int h,
                                   uint32_t start_color, uint32_t end_color,
                                   double sx, double sy, double ex, double ey);
void iosim_fb_fill_gradient_stops(int x, int y, int w, int h,
                                  const uint32_t *colors,
                                  const double *locations, int count,
                                  double ax, double ay, double bx, double by);
/* Same as above with an 8-bit alpha per stop; NULL alphas means opaque. */
void iosim_fb_fill_gradient_stops_alpha(int x, int y, int w, int h,
                                        const uint32_t *colors,
                                        const uint8_t *alphas,
                                        const double *locations, int count,
                                        double ax, double ay, double bx,
                                        double by);
void iosim_fb_fill_linear_gradient_round_rect(int x, int y, int w, int h,
                                              int radius,
                                              uint32_t start_color,
                                              uint32_t end_color,
                                              double sx, double sy,
                                              double ex, double ey);
void iosim_fb_blit_rgba(int x, int y, int w, int h, const uint8_t *rgba,
                        int stride);
void iosim_fb_blit_rgba_scaled(int x, int y, int w, int h,
                               const uint8_t *rgba, int sw, int sh,
                               int stride);
int  iosim_fb_width(void);
int  iosim_fb_height(void);

/* System-font text (FreeType). Sizes are in UIKit points; scale converts to
 * device pixels. style: 0 regular, 1 bold, 2 semibold. */
#define IOSIM_FONT_REGULAR  0
#define IOSIM_FONT_BOLD     1
#define IOSIM_FONT_SEMIBOLD 2
int  iosim_fb_font_text_width(const char *text, int style, double size_pt,
                              double scale);
int  iosim_fb_font_text_width_untracked(const char *text, int style,
                                       double size_pt, double scale);
void iosim_fb_font_text(int x, int baseline_y, const char *text, int style,
                        double size_pt, double scale, uint32_t color);
void iosim_fb_font_metrics(int style, double size_pt, double scale,
                           int *ascent, int *descent, int *line_height);

#endif

/* Offscreen targets for transformed content. Pixels are premultiplied
 * ARGB while an offscreen target is active. */
void *iosim_fb_begin_offscreen(unsigned width, unsigned height);
uint32_t *iosim_fb_end_offscreen(void *state, int *out_w, int *out_h);
uint32_t *iosim_fb_offscreen_pixels(void *state, int *out_w, int *out_h);
void *iosim_fb_activate_offscreen(void *state);
void iosim_fb_restore_target(void *state);
void iosim_fb_free_offscreen(uint32_t *buf);
void iosim_fb_paste_xrgb(const uint32_t *src);
void iosim_fb_capture(int x, int y, int w, int h, uint32_t *out);
void iosim_fb_fill_field(int x, int y, int w, int h, int radius,
                         const uint32_t *grid, int gw, int gh);
void iosim_fb_blit_xrgb_scaled(const uint32_t *src, int sw, int sh,
                               int x, int y, int w, int h,
                               double opacity);
void iosim_fb_mask_round_rect(int x, int y, int w, int h, int radius);
void iosim_fb_blit_affine(const uint32_t *src, int sw, int sh,
                          double fa, double fb, double fc, double fd,
                          double ftx, double fty, double opacity);
void iosim_fb_blit_homography(const uint32_t *src, int sw, int sh,
                              double h11, double h12, double h13,
                              double h21, double h22, double h23,
                              double h31, double h32, double h33,
                              double opacity);
