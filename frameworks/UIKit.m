/* UIKit-lite: a real Objective-C UIKit subset for the iosim runtime.
 *
 * Built as an x86_64 Mach-O dylib at the canonical install name. Classes are
 * registered by the iosim Objective-C runtime like any app class. The frame
 * is rendered through the loader's software framebuffer.
 *
 * Supported: UIApplicationMain, UIApplication, UIWindow, UIView, UILabel,
 * UIColor, UIFont, UIScreen, CALayer (cornerRadius), UIResponder. */

#include "foundation_lite.h"

extern int printf(const char *fmt, ...);
extern char *getenv(const char *name);
extern int atoi(const char *s);
extern double atof(const char *s);
extern void *objc_getClass(const char *name);
extern void *objc_msgSend(void *self, void *sel, ...);

extern int  iosim_fb_begin(unsigned width, unsigned height);
extern void iosim_fb_fill_rect(int x, int y, int w, int h, unsigned color);
extern void iosim_fb_fill_round_rect(int x, int y, int w, int h, int radius,
                                     unsigned color);
extern void iosim_fb_text(int x, int y, int scale, unsigned color,
                          const char *text);
extern int  iosim_fb_text_width(const char *text, int scale);
extern int  iosim_fb_present(const char *path);

@class UIView;

@interface CALayer : NSObject {
@public
    double _cornerRadius;
}
- (double)cornerRadius;
- (void)setCornerRadius:(double)radius;
@end

@interface UIColor : NSObject {
@public
    double _r, _g, _b, _a;
}
+ (UIColor *)colorWithRed:(double)r green:(double)g blue:(double)b
                    alpha:(double)a;
+ (UIColor *)whiteColor;
+ (UIColor *)blackColor;
+ (UIColor *)clearColor;
+ (UIColor *)systemBlueColor;
@end

@interface UIFont : NSObject {
@public
    double _size;
    BOOL _bold;
}
+ (UIFont *)systemFontOfSize:(double)size;
+ (UIFont *)boldSystemFontOfSize:(double)size;
@end

@interface UIScreen : NSObject
+ (UIScreen *)mainScreen;
- (CGRect)bounds;
- (double)scale;
@end

@interface UIResponder : NSObject
@end

@interface UIView : UIResponder {
@public
    CGRect _frame;
    UIColor *_backgroundColor;
    id _subviews[32];
    int _subviewCount;
    BOOL _hidden;
    double _alpha;
    CALayer *_layer;
}
- (id)initWithFrame:(CGRect)frame;
- (CGRect)frame;
- (void)setFrame:(CGRect)frame;
- (CGRect)bounds;
- (void)setBackgroundColor:(UIColor *)color;
- (UIColor *)backgroundColor;
- (void)addSubview:(UIView *)view;
- (CALayer *)layer;
- (void)setHidden:(BOOL)hidden;
- (BOOL)isHidden;
- (void)setAlpha:(double)alpha;
- (double)alpha;
@end

@interface UILabel : UIView {
@public
    id _text;
    UIColor *_textColor;
    UIFont *_font;
    int _textAlignment;
    int _numberOfLines;
}
- (void)setText:(id)text;
- (id)text;
- (void)setTextColor:(UIColor *)color;
- (UIColor *)textColor;
- (void)setFont:(UIFont *)font;
- (UIFont *)font;
- (void)setTextAlignment:(int)alignment;
- (int)textAlignment;
- (void)setNumberOfLines:(int)n;
- (int)numberOfLines;
@end

@interface UIWindow : UIView
- (void)makeKeyAndVisible;
+ (UIWindow *)keyWindow;
@end

@interface UIApplication : UIResponder {
@public
    id _delegate;
}
+ (UIApplication *)sharedApplication;
- (void)setDelegate:(id)delegate;
- (id)delegate;
@end

extern int UIApplicationMain(int argc, char **argv, id principal,
                             id delegateName);

/* ---------------------------------------------------------------- layers */

@implementation CALayer
- (double)cornerRadius { return _cornerRadius; }
- (void)setCornerRadius:(double)radius { _cornerRadius = radius; }
@end

/* ---------------------------------------------------------------- colors */

@implementation UIColor
+ (UIColor *)colorWithRed:(double)r green:(double)g blue:(double)b
                    alpha:(double)a
{
    UIColor *c = [[self alloc] init];
    c->_r = r;
    c->_g = g;
    c->_b = b;
    c->_a = a;
    return c;
}
+ (UIColor *)whiteColor { return [self colorWithRed:1 green:1 blue:1 alpha:1]; }
+ (UIColor *)blackColor { return [self colorWithRed:0 green:0 blue:0 alpha:1]; }
+ (UIColor *)clearColor { return [self colorWithRed:0 green:0 blue:0 alpha:0]; }
+ (UIColor *)systemBlueColor
{
    return [self colorWithRed:0.231 green:0.510 blue:0.965 alpha:1];
}
@end

/* ----------------------------------------------------------------- fonts */

@implementation UIFont
+ (UIFont *)systemFontOfSize:(double)size
{
    UIFont *f = [[self alloc] init];
    f->_size = size;
    f->_bold = NO;
    return f;
}
+ (UIFont *)boldSystemFontOfSize:(double)size
{
    UIFont *f = [[self alloc] init];
    f->_size = size;
    f->_bold = YES;
    return f;
}
@end

/* --------------------------------------------------------------- screens */

@implementation UIScreen
+ (UIScreen *)mainScreen
{
    static UIScreen *screen;
    if (!screen)
        screen = [[self alloc] init];
    return screen;
}
- (double)scale
{
    const char *s = getenv("SIMULATOR_MAINSCREEN_SCALE");
    return s ? atof(s) : 3.0;
}
- (CGRect)bounds
{
    const char *w = getenv("SIMULATOR_MAINSCREEN_WIDTH");
    const char *h = getenv("SIMULATOR_MAINSCREEN_HEIGHT");
    double width = w ? atoi(w) : 1206;
    double height = h ? atoi(h) : 2622;
    double scale = [self scale];
    if (scale <= 0)
        scale = 3.0;
    return CGRectMake(0, 0, width / scale, height / scale);
}
@end

/* ---------------------------------------------------------------- views */

@implementation UIResponder
@end

@implementation UIView
- (id)initWithFrame:(CGRect)frame
{
    self = [super init];
    if (self)
    {
        _frame = frame;
        _alpha = 1.0;
        _hidden = NO;
        _layer = [[CALayer alloc] init];
    }
    return self;
}
- (CGRect)frame { return _frame; }
- (void)setFrame:(CGRect)frame { _frame = frame; }
- (CGRect)bounds
{
    return CGRectMake(0, 0, _frame.size.width, _frame.size.height);
}
- (void)setBackgroundColor:(UIColor *)color { _backgroundColor = color; }
- (UIColor *)backgroundColor { return _backgroundColor; }
- (void)addSubview:(UIView *)view
{
    if (view && _subviewCount < 32)
        _subviews[_subviewCount++] = view;
}
- (CALayer *)layer { return _layer; }
- (void)setHidden:(BOOL)hidden { _hidden = hidden; }
- (BOOL)isHidden { return _hidden; }
- (void)setAlpha:(double)alpha { _alpha = alpha; }
- (double)alpha { return _alpha; }
@end

@implementation UILabel
- (void)setText:(id)text { _text = text; }
- (id)text { return _text; }
- (void)setTextColor:(UIColor *)color { _textColor = color; }
- (UIColor *)textColor { return _textColor; }
- (void)setFont:(UIFont *)font { _font = font; }
- (UIFont *)font { return _font; }
- (void)setTextAlignment:(int)alignment { _textAlignment = alignment; }
- (int)textAlignment { return _textAlignment; }
- (void)setNumberOfLines:(int)n { _numberOfLines = n; }
- (int)numberOfLines { return _numberOfLines; }
@end

static UIWindow *g_keyWindow;

@implementation UIWindow
- (void)makeKeyAndVisible { g_keyWindow = self; }
+ (UIWindow *)keyWindow { return g_keyWindow; }
@end

/* --------------------------------------------------------- applications */

@implementation UIApplication
+ (UIApplication *)sharedApplication
{
    static UIApplication *app;
    if (!app)
        app = [[self alloc] init];
    return app;
}
- (void)setDelegate:(id)delegate { _delegate = delegate; }
- (id)delegate { return _delegate; }
@end

/* -------------------------------------------------------------- renderer */

struct cf_constant_string {
    void *isa;
    unsigned int flags;
    unsigned int pad;
    const char *cstr;
    unsigned long length;
};

static const char *string_cstr(id object)
{
    if (!object)
        return 0;
    struct cf_constant_string *cs = (struct cf_constant_string *)object;
    if (cs->flags == 0x7c8 && cs->cstr)
        return cs->cstr;
    return 0;
}

static unsigned color_rgb(UIColor *color)
{
    if (!color)
        return 0;
    int r = (int)(color->_r * 255.0 + 0.5);
    int g = (int)(color->_g * 255.0 + 0.5);
    int b = (int)(color->_b * 255.0 + 0.5);
    if (r < 0) r = 0; if (r > 255) r = 255;
    if (g < 0) g = 0; if (g > 255) g = 255;
    if (b < 0) b = 0; if (b > 255) b = 255;
    return ((unsigned)r << 16) | ((unsigned)g << 8) | (unsigned)b;
}

static void render_view(UIView *view, double originX, double originY,
                        double scale)
{
    if (!view || view->_hidden)
        return;

    CGRect frame = view->_frame;
    int x = (int)((originX + frame.origin.x) * scale + 0.5);
    int y = (int)((originY + frame.origin.y) * scale + 0.5);
    int w = (int)(frame.size.width * scale + 0.5);
    int h = (int)(frame.size.height * scale + 0.5);
    if (w < 0) w = 0;
    if (h < 0) h = 0;

    if (view->_backgroundColor && w > 0 && h > 0)
    {
        unsigned color = color_rgb(view->_backgroundColor);
        double radius = view->_layer ? view->_layer->_cornerRadius : 0;
        if (radius > 0)
            iosim_fb_fill_round_rect(x, y, w, h, (int)(radius * scale + 0.5),
                                     color);
        else
            iosim_fb_fill_rect(x, y, w, h, color);
    }

    if ([view isKindOfClass:[UILabel class]])
    {
        UILabel *label = (UILabel *)view;
        const char *text = string_cstr(label->_text);
        if (text)
        {
            double points = label->_font ? label->_font->_size : 17.0;
            int fontScale = (int)(points * scale / 12.0 + 0.5);
            if (fontScale < 1)
                fontScale = 1;
            while (fontScale > 1 && w > 0 &&
                   iosim_fb_text_width(text, fontScale) > w)
                fontScale--;
            int textWidth = iosim_fb_text_width(text, fontScale);
            int tx = x;
            if (label->_textAlignment == 1)
                tx = x + (w - textWidth) / 2;
            else if (label->_textAlignment == 2)
                tx = x + w - textWidth;
            int textHeight = 8 * fontScale;
            int ty = y + (h - textHeight) / 2;
            unsigned color = label->_textColor ? color_rgb(label->_textColor)
                                               : 0xffffff;
            iosim_fb_text(tx, ty, fontScale, color, text);
        }
    }

    for (int i = 0; i < view->_subviewCount; i++)
    {
        UIView *sub = (UIView *)view->_subviews[i];
        render_view(sub, originX + frame.origin.x, originY + frame.origin.y,
                    scale);
    }
}

int UIApplicationMain(int argc, char **argv, id principal, id delegateName)
{
    (void)principal;
    (void)argv;

    const char *name = string_cstr(delegateName);
    Class delegateClass = name ? (Class)objc_getClass(name) : 0;
    id delegate = delegateClass ? [[delegateClass alloc] init] : nil;

    UIApplication *app = [UIApplication sharedApplication];
    [app setDelegate:delegate];

    SEL launch = @selector(application:didFinishLaunchingWithOptions:);
    if (delegate && [delegate respondsToSelector:launch])
        [delegate application:app didFinishLaunchingWithOptions:nil];

    UIWindow *window = [UIWindow keyWindow];
    SEL windowSel = @selector(window);
    if (!window && delegate && [delegate respondsToSelector:windowSel])
        window = ((UIWindow * (*)(id, SEL))objc_msgSend)(delegate, windowSel);
    if (!window)
        window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];

    double scale = [[UIScreen mainScreen] scale];
    if (scale <= 0)
        scale = 3.0;

    const char *pw = getenv("SIMULATOR_MAINSCREEN_WIDTH");
    const char *ph = getenv("SIMULATOR_MAINSCREEN_HEIGHT");
    int fbWidth = pw ? atoi(pw) : 1206;
    int fbHeight = ph ? atoi(ph) : 2622;
    iosim_fb_begin((unsigned)fbWidth, (unsigned)fbHeight);
    render_view(window, 0, 0, scale);

    /* Simulated device chrome: status bar, Dynamic Island, home indicator. */
    int margin = (int)(24 * scale);
    int right = fbWidth - margin;
    iosim_fb_text(margin, (int)(14 * scale), 5, 0xffffff, "9:41");
    int bw = (int)(26 * scale), bh = (int)(12 * scale);
    int bx = right - bw - (int)(8 * scale);
    int by = (int)(17 * scale);
    iosim_fb_fill_round_rect(bx, by, bw, bh, (int)(3 * scale), 0xffffff);
    iosim_fb_fill_round_rect(bx + (int)(2 * scale), by + (int)(2 * scale),
                             bw - (int)(4 * scale), bh - (int)(4 * scale),
                             (int)(2 * scale), 0x0b1020);
    iosim_fb_fill_round_rect(bx + (int)(3 * scale), by + (int)(3 * scale),
                             (int)(14 * scale), (int)(6 * scale),
                             (int)(1 * scale), 0x22c55e);
    iosim_fb_fill_rect(bx + bw + (int)(2 * scale), by + (int)(4 * scale),
                       (int)(2 * scale), (int)(4 * scale), 0xffffff);
    iosim_fb_text(right - (int)(118 * scale), (int)(15 * scale), 4, 0xffffff,
                  "5G");
    for (int i = 0; i < 4; i++)
        iosim_fb_fill_rect(right - (int)(200 * scale) + i * (int)(15 * scale),
                           (int)(25 * scale) - i * (int)(3 * scale),
                           (int)(9 * scale),
                           (int)(7 * scale) + i * (int)(3 * scale), 0xffffff);
    iosim_fb_fill_round_rect(fbWidth / 2 - (int)(63 * scale) / 2,
                             (int)(11 * scale), (int)(63 * scale),
                             (int)(34 * scale), (int)(17 * scale), 0x000000);
    iosim_fb_fill_round_rect(fbWidth / 2 - (int)(67 * scale),
                             fbHeight - (int)(16 * scale),
                             (int)(134 * scale), (int)(5 * scale),
                             (int)(3 * scale), 0x94a3b8);

    const char *path = getenv("IOSIM_SCREENSHOT_PATH");
    if (path && *path)
        iosim_fb_present(path);

    printf("[UIKit-lite] UIApplicationMain argc=%d delegate=%p window=%p\n",
           argc, delegate, window);
    printf("[UIKit-lite] rendered app frame at %.1fx scale\n", scale);
    return 0;
}
