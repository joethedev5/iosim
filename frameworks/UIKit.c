/* UIKit-lite: the first reimplemented iOS Simulator framework.
 *
 * Built as an x86_64 Mach-O dylib with the canonical install name and loaded
 * from the iosim runtime root exactly like Apple's UIKit would be. It renders
 * a device-sized screen through the loader's software framebuffer shims. */

extern int printf(const char *fmt, ...);
extern char *getenv(const char *name);
extern int atoi(const char *s);

extern int  iosim_fb_begin(unsigned width, unsigned height);
extern void iosim_fb_clear(unsigned color);
extern void iosim_fb_fill_rect(int x, int y, int w, int h, unsigned color);
extern void iosim_fb_fill_round_rect(int x, int y, int w, int h, int radius,
                                     unsigned color);
extern void iosim_fb_text(int x, int y, int scale, unsigned color,
                          const char *text);
extern int  iosim_fb_text_width(const char *text, int scale);
extern int  iosim_fb_present(const char *path);

#define C_BG     0x0B1020u
#define C_BG2    0x141C33u
#define C_CARD   0x1B2440u
#define C_ACCENT 0x3B82F6u
#define C_GREEN  0x22C55Eu
#define C_WHITE  0xF8FAFCu
#define C_GRAY   0x94A3B8u
#define C_DIM    0x64748Bu

static int U;

static int pt(int v) { return v * U; }

static void centered_text(int cx, int y, int scale, unsigned color,
                          const char *text)
{
    int w = iosim_fb_text_width(text, scale);
    iosim_fb_text(cx - w / 2, y, scale, color, text);
}

static void row(int x, int y, const char *label)
{
    iosim_fb_fill_round_rect(x, y + pt(4), pt(7), pt(7), pt(3), C_GREEN);
    iosim_fb_text(x + pt(14), y, 2 * U, C_WHITE, label);
}

int UIApplicationMain(int argc, char **argv, void *principalClass,
                      void *delegateClassName)
{
    const char *ws = getenv("SIMULATOR_MAINSCREEN_WIDTH");
    const char *hs = getenv("SIMULATOR_MAINSCREEN_HEIGHT");
    int width = ws ? atoi(ws) : 1206;
    int height = hs ? atoi(hs) : 2622;
    if (width <= 0 || height <= 0)
    {
        width = 1206;
        height = 2622;
    }
    U = width / 402;
    if (U < 1)
        U = 1;

    if (iosim_fb_begin((unsigned)width, (unsigned)height) != 0)
    {
        printf("[UIKit-lite] framebuffer allocation failed\n");
        return 1;
    }

    /* Background with a soft vertical gradient. */
    for (int y = 0; y < height; y++)
    {
        int t = y * 255 / (height > 1 ? height - 1 : 1);
        int r = ((C_BG >> 16) & 0xff) * (255 - t) / 255 +
                ((C_BG2 >> 16) & 0xff) * t / 255;
        int g = ((C_BG >> 8) & 0xff) * (255 - t) / 255 +
                ((C_BG2 >> 8) & 0xff) * t / 255;
        int b = (C_BG & 0xff) * (255 - t) / 255 + (C_BG2 & 0xff) * t / 255;
        iosim_fb_fill_rect(0, y, width, 1, (unsigned)((r << 16) | (g << 8) | b));
    }

    int margin = pt(24);

    /* Status bar */
    iosim_fb_text(margin, pt(14), 5, C_WHITE, "9:41");
    int right = width - margin;
    int battery_w = pt(26);
    int battery_h = pt(12);
    int bx = right - battery_w - pt(8);
    int by = pt(17);
    iosim_fb_fill_round_rect(bx, by, battery_w, battery_h, pt(3), C_WHITE);
    iosim_fb_fill_round_rect(bx + pt(2), by + pt(2), battery_w - pt(4),
                             battery_h - pt(4), pt(2), C_BG);
    iosim_fb_fill_round_rect(bx + pt(3), by + pt(3), pt(14), pt(6), pt(1),
                             C_GREEN);
    iosim_fb_fill_rect(bx + battery_w + pt(2), by + pt(4), pt(2), pt(4),
                       C_WHITE);
    int text5g_w = iosim_fb_text_width("5G", 4);
    iosim_fb_text(bx - pt(12) - text5g_w, pt(15), 4, C_WHITE, "5G");
    for (int i = 0; i < 4; i++)
        iosim_fb_fill_rect(bx - pt(12) - text5g_w - pt(84) + i * pt(15),
                           pt(25) - i * pt(3), pt(9), pt(7) + i * pt(3),
                           C_WHITE);

    /* Hero */
    iosim_fb_text(margin, pt(62), 7 * U, C_WHITE, "iosim");
    iosim_fb_text(margin, pt(140), 4, C_GRAY,
                  "native x86_64 iOS simulator");

    int pill_w = iosim_fb_text_width("Apple binary  ->  iosim runtime",
                                     3) + pt(28);
    iosim_fb_fill_round_rect(margin, pt(188), pill_w, pt(38), pt(19), C_ACCENT);
    iosim_fb_text(margin + pt(14), pt(202), 3, C_WHITE,
                  "Apple binary  ->  iosim runtime");

    /* Status card */
    int card_x = margin;
    int card_y = pt(250);
    int card_w = width - margin * 2;
    int card_h = pt(210);
    iosim_fb_fill_round_rect(card_x, card_y, card_w, card_h, pt(18), C_CARD);
    iosim_fb_text(card_x + pt(18), card_y + pt(18), 4, C_WHITE,
                  "System status");
    int rx = card_x + pt(18);
    int ry = card_y + pt(62);
    row(rx, ry + pt(0), "Mach-O loader  OK");
    row(rx, ry + pt(34), "dyld fixups  OK");
    row(rx, ry + pt(68), "objc_msgSend  OK");
    row(rx, ry + pt(102), "UIKit  available");

    /* Action button */
    int btn_y = pt(500);
    int btn_h = pt(56);
    iosim_fb_fill_round_rect(margin, btn_y, width - margin * 2, btn_h,
                             pt(16), C_ACCENT);
    centered_text(width / 2, btn_y + pt(18), 5, C_WHITE, "Launch app");

    /* Footer */
    iosim_fb_text(margin, pt(790), 3, C_DIM,
                  "hello_uikit_x86_64 - Apple clang 27.1");
    iosim_fb_text(margin, pt(816), 3, C_DIM,
                  "iosim 1.0 - framebuffer proof");

    /* Home indicator */
    iosim_fb_fill_round_rect(width / 2 - pt(67), height - pt(16), pt(134),
                             pt(5), pt(3), C_GRAY);

    const char *path = getenv("IOSIM_SCREENSHOT_PATH");
    if (path && *path)
        iosim_fb_present(path);

    printf("[UIKit-lite] UIApplicationMain argc=%d principal=%p delegate=%p\n",
           argc, principalClass, delegateClassName);
    printf("[UIKit-lite] rendered %dx%d (%d status rows) and captured frame\n",
           width, height, 4);
    return 0;
}
