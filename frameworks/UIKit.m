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
extern int fprintf(void *stream, const char *fmt, ...);
extern void *stderr;
extern char *getenv(const char *name);
extern int atoi(const char *s);
extern double atof(const char *s);
extern void *objc_getClass(const char *name);
extern void *objc_msgSend(void *self, void *sel, ...);

extern int  iosim_fb_begin(unsigned width, unsigned height);
extern void iosim_fb_fill_rect(int x, int y, int w, int h, unsigned color);
extern void iosim_fb_fill_round_rect(int x, int y, int w, int h, int radius,
                                     unsigned color);
extern void iosim_fb_fill_circle(int cx, int cy, int radius, unsigned color);
extern void iosim_fb_text(int x, int y, int scale, unsigned color,
                          const char *text);
extern int  iosim_fb_text_width(const char *text, int scale);
#define IOSIM_FONT_REGULAR  0
#define IOSIM_FONT_BOLD     1
#define IOSIM_FONT_SEMIBOLD 2

extern int  iosim_fb_font_text_width(const char *text, int style,
                                     double size_pt, double scale);
extern void iosim_fb_font_text(int x, int baseline_y, const char *text,
                               int style, double size_pt, double scale,
                               unsigned color);
extern void iosim_fb_font_metrics(int style, double size_pt, double scale,
                                  int *ascent, int *descent,
                                  int *line_height);
extern int  iosim_fb_present(const char *path);

@class UIView;
@class UIWindowScene;

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
- (id)initWithWindowScene:(UIWindowScene *)scene;
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

@interface UIScene : NSObject {
@public
    id _delegate;
}
- (void)setDelegate:(id)delegate;
- (id)delegate;
@end

@interface UIWindowScene : UIScene
@end

@interface UISceneSession : NSObject
@end

@interface UISceneConnectionOptions : NSObject
@end

@interface UISceneConfiguration : NSObject {
@public
    id _name;
    id _role;
    Class _delegateClass;
}
- (id)initWithName:(id)name sessionRole:(id)role;
- (Class)delegateClass;
- (void)setDelegateClass:(Class)cls;
@end

id UIWindowSceneSessionRoleApplication = 0;

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
    return [self colorWithRed:0.0 green:0.5686 blue:1.0 alpha:1];
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
- (id)initWithWindowScene:(UIWindowScene *)scene
{
    (void)scene;
    return [self initWithFrame:[[UIScreen mainScreen] bounds]];
}
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

/* ---------------------------------------------------------------- scenes */

@implementation UIScene
- (void)setDelegate:(id)delegate { _delegate = delegate; }
- (id)delegate { return _delegate; }
@end

@implementation UIWindowScene
@end

@implementation UISceneSession
@end

@implementation UISceneConnectionOptions
@end

@implementation UISceneConfiguration
- (id)initWithName:(id)name sessionRole:(id)role
{
    self = [super init];
    if (self)
    {
        _name = name;
        _role = role;
    }
    return self;
}
- (Class)delegateClass { return _delegateClass; }
- (void)setDelegateClass:(Class)cls { _delegateClass = cls; }
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
            int style = label->_font && label->_font->_bold
                            ? IOSIM_FONT_BOLD : IOSIM_FONT_REGULAR;
            int ascent = 0, descent = 0, lineHeight = 0;
            iosim_fb_font_metrics(style, points, scale, &ascent, &descent,
                                  &lineHeight);
            int textWidth = iosim_fb_font_text_width(text, style, points,
                                                     scale);
            while (textWidth > w && points > 8 && w > 0)
            {
                points -= 0.5;
                iosim_fb_font_metrics(style, points, scale, &ascent, &descent,
                                      &lineHeight);
                textWidth = iosim_fb_font_text_width(text, style, points,
                                                     scale);
            }
            int tx = x;
            if (label->_textAlignment == 1)
                tx = x + (w - textWidth) / 2;
            else if (label->_textAlignment == 2)
                tx = x + w - textWidth;
            int baseline = y + (h - lineHeight) / 2 + ascent;
            unsigned color = label->_textColor ? color_rgb(label->_textColor)
                                               : 0xffffff;
            iosim_fb_font_text(tx, baseline, text, style, points, scale,
                               color);
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

    /* iOS 27 requires the scene lifecycle, so ask the app delegate for a
     * scene configuration and drive the scene delegate ourselves. */
    UISceneConfiguration *configuration = nil;
    UISceneSession *session = [[UISceneSession alloc] init];
    UISceneConnectionOptions *connectionOptions =
        [[UISceneConnectionOptions alloc] init];
    SEL configSel = @selector(application:configurationForConnectingSceneSession:options:);
    if (delegate && [delegate respondsToSelector:configSel])
        configuration = ((UISceneConfiguration * (*)(id, SEL, id, id, id))
            objc_msgSend)(delegate, configSel, app, session, connectionOptions);

    Class sceneClass = configuration ? [configuration delegateClass] : nil;
    id sceneDelegate = sceneClass ? [[sceneClass alloc] init] : nil;
    if (getenv("IOSIM_UIAPP_DEBUG"))
        fprintf(stderr, "uiapp: config=%p sceneClass=%p expected=%p sceneDelegate=%p\n",
                configuration, sceneClass, objc_getClass("SceneDelegate"),
                sceneDelegate);
    UIWindowScene *scene = [[UIWindowScene alloc] init];
    if (sceneDelegate)
        [scene setDelegate:sceneDelegate];
    SEL willConnect = @selector(scene:willConnectToSession:options:);
    if (getenv("IOSIM_UIAPP_DEBUG"))
        fprintf(stderr, "uiapp: responds=%d sceneDelegate=%p\n",
                sceneDelegate && [sceneDelegate respondsToSelector:willConnect],
                sceneDelegate);
    if (sceneDelegate && [sceneDelegate respondsToSelector:willConnect])
        ((void (*)(id, SEL, id, id, id))objc_msgSend)(sceneDelegate, willConnect,
                                                      scene, session,
                                                      connectionOptions);

    UIWindow *window = [UIWindow keyWindow];
    SEL windowSel = @selector(window);
    if (!window && sceneDelegate &&
        [sceneDelegate respondsToSelector:windowSel])
        window = ((UIWindow * (*)(id, SEL))objc_msgSend)(sceneDelegate,
                                                          windowSel);
    if (!window && delegate && [delegate respondsToSelector:windowSel])
        window = ((UIWindow * (*)(id, SEL))objc_msgSend)(delegate, windowSel);
    if (!window)
        window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    if (getenv("IOSIM_UIAPP_DEBUG"))
        fprintf(stderr, "uiapp: window=%p sceneDelegate=%p\n", window,
                sceneDelegate);

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
    double timeSize = getenv("IOSIM_TIME_SIZE") ? atof(getenv("IOSIM_TIME_SIZE"))
                                                : 18.0;
    double timeBaseline = getenv("IOSIM_TIME_BASELINE")
                              ? atof(getenv("IOSIM_TIME_BASELINE")) : 38.9;
    int timeWidth = iosim_fb_font_text_width("9:41", IOSIM_FONT_SEMIBOLD,
                                             timeSize, scale);
    iosim_fb_font_text((int)(80.67 * scale) - timeWidth / 2,
                       (int)(timeBaseline * scale), "9:41",
                       IOSIM_FONT_SEMIBOLD, timeSize, scale, 0xffffff);
    /* Cellular signal placeholders, Wi-Fi and battery, measured from the
     * iPhone 18 Pro status bar. */
    for (int i = 0; i < 4; i++)
        iosim_fb_fill_circle((int)((278.83 + i * 5.667) * scale),
                             (int)(37.83 * scale), (int)(1.85 * scale),
                             0x484c58);
    for (int i = 0; i < 51; i++)
    {
        double angle = (-140.0 + i * 2.0) * 3.14159265358979323846 / 180.0;
        int x = (int)((315.33 + 11.08 * __builtin_cos(angle)) * scale);
        int y = (int)((38.0 + 11.08 * __builtin_sin(angle)) * scale);
        iosim_fb_fill_circle(x, y, (int)(1.03 * scale), 0xffffff);
        x = (int)((315.33 + 7.08 * __builtin_cos(angle)) * scale);
        y = (int)((38.0 + 7.08 * __builtin_sin(angle)) * scale);
        iosim_fb_fill_circle(x, y, (int)(1.03 * scale), 0xffffff);
    }
    iosim_fb_fill_circle((int)(315.33 * scale), (int)(36.67 * scale),
                         (int)(2.67 * scale), 0xffffff);
    iosim_fb_fill_round_rect((int)(333.0 * scale), (int)(25.33 * scale),
                             (int)(26.33 * scale), (int)(13.67 * scale),
                             (int)(4.0 * scale), 0xffffff);
    iosim_fb_fill_round_rect((int)(360.0 * scale), (int)(29.67 * scale),
                             (int)(2.0 * scale), (int)(5.0 * scale),
                             (int)(1.0 * scale), 0xffffff);

    const char *path = getenv("IOSIM_SCREENSHOT_PATH");
    if (path && *path)
        iosim_fb_present(path);

    printf("[UIKit-lite] UIApplicationMain argc=%d delegate=%p window=%p\n",
           argc, delegate, window);
    printf("[UIKit-lite] rendered app frame at %.1fx scale\n", scale);
    return 0;
}
