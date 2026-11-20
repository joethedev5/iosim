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
extern int  iosim_event_next(int *type, int *x, int *y);
extern void iosim_fb_set_opacity(double opacity);
extern double iosim_now(void);
extern int  iosim_foundation_tick(void);
extern int  iosim_dispatch_drain_main(void);
extern const char *iosim_string_cstr(id string);
extern int  strcmp(const char *a, const char *b);
extern int  snprintf(char *buf, unsigned long size, const char *fmt, ...);
extern int  iosim_png_load(const char *path, unsigned char **out_rgba,
                           int *out_width, int *out_height);
extern void iosim_fb_fill_ellipse(int cx, int cy, int rx, int ry,
                                  unsigned color);
extern void iosim_fb_draw_line(int x0, int y0, int x1, int y1, int thickness,
                               unsigned color);
extern void iosim_fb_fill_polygon(const double *xs, const double *ys,
                                  int count, unsigned color);
extern void iosim_fb_fill_linear_gradient(int x, int y, int w, int h,
                                          unsigned start_color,
                                          unsigned end_color,
                                          double sx, double sy,
                                          double ex, double ey);
extern void iosim_fb_blit_rgba_scaled(int x, int y, int w, int h,
                                      const unsigned char *rgba,
                                      int sw, int sh, int stride);

typedef const void *CGPathRef;
typedef void *CGColorRef;

@class UIView;
@class UIWindowScene;

@class UIColor;

@interface CALayer : NSObject {
@public
    double _cornerRadius;
    CGRect _frame;
    UIColor *_backgroundColor;
    double _opacity;
    BOOL _hidden;
    BOOL _masksToBounds;
    id _sublayers[16];
    int _sublayerCount;
    id _animKeyPath;
    id _animFrom;
    id _animTo;
    double _animStart;
    double _animDuration;
    double _animRepeatCount;
    BOOL _animInfinite;
}
- (double)cornerRadius;
- (void)setCornerRadius:(double)radius;
- (CGRect)frame;
- (void)setFrame:(CGRect)frame;
- (void)setBackgroundColor:(UIColor *)color;
- (UIColor *)backgroundColor;
- (void)setOpacity:(double)opacity;
- (double)opacity;
- (void)setHidden:(BOOL)hidden;
- (BOOL)isHidden;
- (void)addSublayer:(CALayer *)layer;
- (void)removeFromSuperlayer;
- (void)addAnimation:(id)animation forKey:(id)key;
- (void)removeAnimationForKey:(id)key;
@end


@class UIBezierPath, UIImage;

@interface CAShapeLayer : CALayer {
@public
    id _path;
    id _fillColor;
    id _strokeColor;
    double _lineWidth;
}
- (void)setPath:(id)path;
- (id)path;
- (void)setFillColor:(id)color;
- (id)fillColor;
- (void)setStrokeColor:(id)color;
- (id)strokeColor;
- (void)setLineWidth:(double)width;
- (double)lineWidth;
@end

@interface CAGradientLayer : CALayer {
@public
    NSArray *_colors;
    CGPoint _startPoint;
    CGPoint _endPoint;
}
- (void)setColors:(NSArray *)colors;
- (NSArray *)colors;
- (void)setStartPoint:(CGPoint)point;
- (CGPoint)startPoint;
- (void)setEndPoint:(CGPoint)point;
- (CGPoint)endPoint;
@end

@interface UIBezierPath : NSObject {
@public
    double _xs[512];
    double _ys[512];
    int _count;
    int _shape;
    CGRect _rect;
    double _cornerRadius;
}
+ (id)bezierPath;
+ (id)bezierPathWithRect:(CGRect)rect;
+ (id)bezierPathWithRoundedRect:(CGRect)rect cornerRadius:(double)radius;
+ (id)bezierPathWithOvalInRect:(CGRect)rect;
- (void)moveToPoint:(CGPoint)point;
- (void)addLineToPoint:(CGPoint)point;
- (void)addArcWithCenter:(CGPoint)center radius:(double)radius
               startAngle:(double)start endAngle:(double)end
                clockwise:(BOOL)clockwise;
- (void)closePath;
- (void)appendPath:(UIBezierPath *)path;
- (void)addRect:(CGRect)rect;
- (void)addOvalInRect:(CGRect)rect;
- (void)addRoundedRect:(CGRect)rect cornerRadius:(double)radius;
- (CGPathRef)CGPath;
@end

@interface UIImage : NSObject {
@public
    unsigned char *_rgba;
    int _width;
    int _height;
}
+ (id)imageNamed:(id)name;
+ (id)imageWithContentsOfFile:(id)path;
- (int)width;
- (int)height;
@end

@interface CAMediaTimingFunction : NSObject {
@public
    int _kind;
}
+ (id)functionWithName:(id)name;
- (double)evaluate:(double)t;
@end

extern id kCAMediaTimingFunctionLinear;
extern id kCAMediaTimingFunctionEaseIn;
extern id kCAMediaTimingFunctionEaseOut;
extern id kCAMediaTimingFunctionEaseInEaseOut;

@interface CAAnimation : NSObject {
@public
    id _keyPath;
    id _fromValue;
    id _toValue;
    double _duration;
    double _repeatCount;
    id _timingFunction;
}
+ (id)animationWithKeyPath:(id)path;
- (void)setFromValue:(id)value;
- (void)setToValue:(id)value;
- (void)setDuration:(double)duration;
- (void)setRepeatCount:(double)count;
- (void)setTimingFunction:(id)function;
@end

@interface CABasicAnimation : CAAnimation
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
- (CGColorRef)CGColor;
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
    BOOL _animatingAlpha;
    double _animAlphaFrom, _animAlphaTo;
    BOOL _animatingFrame;
    CGRect _animFrameFrom, _animFrameTo;
    double _animStart, _animDuration;
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
- (BOOL)pointInside:(CGPoint)point;
- (UIView *)hitTest:(CGPoint)point;
+ (void)animateWithDuration:(double)duration animations:(void (^)(void))animations;
+ (void)animateWithDuration:(double)duration animations:(void (^)(void))animations
                 completion:(void (^)(BOOL finished))completion;
+ (void)animateWithDuration:(double)duration delay:(double)delay
                    options:(unsigned long)options
                 animations:(void (^)(void))animations
                 completion:(void (^)(BOOL finished))completion;
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

@interface UIImageView : UIView {
@public
    UIImage *_image;
    int _contentMode;
}
- (id)initWithImage:(UIImage *)image;
- (void)setImage:(UIImage *)image;
- (UIImage *)image;
- (void)setContentMode:(int)mode;
- (int)contentMode;
@end

@interface UIViewController : NSObject {
@public
    UIView *_view;
    BOOL _viewLoaded;
}
- (id)init;
- (UIView *)view;
- (void)setView:(UIView *)view;
- (void)loadView;
- (void)viewDidLoad;
@end

enum {
    UIControlStateNormal = 0,
    UIControlStateHighlighted = 1
};

enum {
    UIControlEventTouchUpInside = 1 << 6
};

enum {
    UIButtonTypeSystem = 1
};

@interface UIControl : UIView {
@public
    id _target;
    SEL _action;
    unsigned long _controlEvents;
}
- (void)addTarget:(id)target action:(SEL)action
    forControlEvents:(unsigned long)events;
- (void)sendActionsForControlEvents:(unsigned long)events;
@end

@interface UIButton : UIControl {
@public
    id _title;
    UIColor *_titleColor;
    UILabel *_titleLabel;
}
+ (id)buttonWithType:(int)type;
- (void)setTitle:(id)title forState:(unsigned long)state;
- (void)setTitleColor:(UIColor *)color forState:(unsigned long)state;
@end

@interface UIWindow : UIView {
@public
    UIViewController *_rootViewController;
}
- (id)initWithWindowScene:(UIWindowScene *)scene;
- (void)setRootViewController:(UIViewController *)controller;
- (UIViewController *)rootViewController;
- (void)dispatchTapX:(int)x y:(int)y;
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

static void animation_mark_active(double duration, double repeat);

@implementation CALayer
- (id)init
{
    self = [super init];
    if (self)
        _opacity = 1.0;
    return self;
}
- (double)cornerRadius { return _cornerRadius; }
- (void)setCornerRadius:(double)radius { _cornerRadius = radius; }
- (CGRect)frame { return _frame; }
- (void)setFrame:(CGRect)frame { _frame = frame; }
- (void)setBackgroundColor:(UIColor *)color { _backgroundColor = color; }
- (UIColor *)backgroundColor { return _backgroundColor; }
- (void)setOpacity:(double)opacity { _opacity = opacity; }
- (double)opacity { return _opacity; }
- (void)setHidden:(BOOL)hidden { _hidden = hidden; }
- (BOOL)isHidden { return _hidden; }
- (void)addSublayer:(CALayer *)layer
{
    if (layer && _sublayerCount < 16)
        _sublayers[_sublayerCount++] = layer;
}
- (void)removeFromSuperlayer { }
- (void)addAnimation:(id)animation forKey:(id)key
{
    (void)key;
    CAAnimation *anim = (CAAnimation *)animation;
    _animKeyPath = anim->_keyPath;
    _animFrom = anim->_fromValue;
    _animTo = anim->_toValue;
    _animDuration = anim->_duration;
    _animRepeatCount = anim->_repeatCount;
    _animStart = iosim_now();
    _animInfinite = anim->_repeatCount < 0;
    if (_animDuration <= 0)
        _animDuration = 0.25;
    animation_mark_active(_animDuration, _animRepeatCount);
}
- (void)removeAnimationForKey:(id)key { (void)key; _animKeyPath = nil; }
@end

id kCAMediaTimingFunctionLinear = @"linear";
id kCAMediaTimingFunctionEaseIn = @"easeIn";
id kCAMediaTimingFunctionEaseOut = @"easeOut";
id kCAMediaTimingFunctionEaseInEaseOut = @"easeInEaseOut";

@implementation CAMediaTimingFunction
+ (id)functionWithName:(id)name
{
    CAMediaTimingFunction *f = [[self alloc] init];
    const char *s = iosim_string_cstr(name);
    if (strcmp(s, "linear") == 0) f->_kind = 0;
    else if (strcmp(s, "easeIn") == 0) f->_kind = 1;
    else if (strcmp(s, "easeOut") == 0) f->_kind = 2;
    else f->_kind = 3;
    return f;
}
- (double)evaluate:(double)t
{
    if (t < 0) t = 0;
    if (t > 1) t = 1;
    if (_kind == 1) return t * t;
    if (_kind == 2) return 1 - (1 - t) * (1 - t);
    if (_kind == 3) return t * t * (3 - 2 * t);
    return t;
}
@end

@implementation CAAnimation
+ (id)animationWithKeyPath:(id)path
{
    CAAnimation *a = [[self alloc] init];
    a->_keyPath = path;
    a->_duration = 0.25;
    return a;
}
- (void)setFromValue:(id)value { _fromValue = value; }
- (void)setToValue:(id)value { _toValue = value; }
- (void)setDuration:(double)duration { _duration = duration; }
- (void)setRepeatCount:(double)count { _repeatCount = count; }
- (void)setTimingFunction:(id)function { _timingFunction = function; }
@end

@implementation CABasicAnimation
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
- (CGColorRef)CGColor { return (CGColorRef)self; }
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

static BOOL g_animating;
static double g_animStart, g_animDuration;
static double g_animActiveUntil;
static BOOL g_animInfinite;

static void animation_mark_active(double duration, double repeat)
{
    if (repeat < 0)
        g_animInfinite = YES;
    else
    {
        double total = duration * (repeat > 0 ? repeat : 1);
        double until = iosim_now() + total;
        if (until > g_animActiveUntil)
            g_animActiveUntil = until;
    }
}

int iosim_animations_active(void)
{
    return g_animInfinite || iosim_now() < g_animActiveUntil;
}

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
        _layer->_frame = CGRectMake(0, 0, frame.size.width, frame.size.height);
    }
    return self;
}
- (CGRect)frame { return _frame; }
- (void)setFrame:(CGRect)frame
{
    if (g_animating && _frame.size.width >= 0)
    {
        _animFrameFrom = _frame;
        _animFrameTo = frame;
        _animStart = g_animStart;
        _animDuration = g_animDuration;
        _animatingFrame = YES;
        animation_mark_active(g_animDuration, 0);
    }
    _frame = frame;
    if (_layer)
        _layer->_frame = CGRectMake(0, 0, frame.size.width, frame.size.height);
}
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
- (void)setAlpha:(double)alpha
{
    if (g_animating && alpha != _alpha)
    {
        _animAlphaFrom = _alpha;
        _animAlphaTo = alpha;
        _animStart = g_animStart;
        _animDuration = g_animDuration;
        _animatingAlpha = YES;
        animation_mark_active(g_animDuration, 0);
    }
    _alpha = alpha;
}
- (double)alpha { return _alpha; }
- (BOOL)pointInside:(CGPoint)point
{
    return point.x >= 0 && point.y >= 0 && point.x < _frame.size.width &&
           point.y < _frame.size.height;
}
- (UIView *)hitTest:(CGPoint)point
{
    if (_hidden || _alpha < 0.01 || ![self pointInside:point])
        return nil;
    for (int i = _subviewCount - 1; i >= 0; i--)
    {
        UIView *sub = (UIView *)_subviews[i];
        CGPoint local = CGPointMake(point.x - sub->_frame.origin.x,
                                    point.y - sub->_frame.origin.y);
        UIView *hit = [sub hitTest:local];
        if (hit)
            return hit;
    }
    return self;
}
+ (void)animateWithDuration:(double)duration animations:(void (^)(void))animations
{
    if (!animations)
        return;
    g_animating = YES;
    g_animStart = iosim_now();
    g_animDuration = duration;
    animations();
    g_animating = NO;
    animation_mark_active(duration, 0);
}
+ (void)animateWithDuration:(double)duration animations:(void (^)(void))animations
                 completion:(void (^)(BOOL finished))completion
{
    (void)completion;
    [self animateWithDuration:duration animations:animations];
}
+ (void)animateWithDuration:(double)duration delay:(double)delay
                    options:(unsigned long)options
                 animations:(void (^)(void))animations
                 completion:(void (^)(BOOL finished))completion
{
    (void)delay;
    (void)options;
    (void)completion;
    [self animateWithDuration:duration animations:animations];
}
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
- (UIView *)hitTest:(CGPoint)point
{
    (void)point;
    return nil;
}
@end


/* ------------------------------------------------------- paths and layers */

@implementation UIBezierPath
+ (id)bezierPath
{
    return [[self alloc] init];
}
+ (id)bezierPathWithRect:(CGRect)rect
{
    UIBezierPath *p = [[self alloc] init];
    p->_shape = 1;
    p->_rect = rect;
    return p;
}
+ (id)bezierPathWithRoundedRect:(CGRect)rect cornerRadius:(double)radius
{
    UIBezierPath *p = [[self alloc] init];
    p->_shape = 2;
    p->_rect = rect;
    p->_cornerRadius = radius;
    return p;
}
+ (id)bezierPathWithOvalInRect:(CGRect)rect
{
    UIBezierPath *p = [[self alloc] init];
    p->_shape = 3;
    p->_rect = rect;
    return p;
}
- (void)moveToPoint:(CGPoint)point
{
    if (_count == 0 && _shape == 0)
    {
        _xs[0] = point.x;
        _ys[0] = point.y;
        _count = 1;
    }
}
- (void)addLineToPoint:(CGPoint)point
{
    if (_count < 512)
    {
        _xs[_count] = point.x;
        _ys[_count] = point.y;
        _count++;
    }
}
- (void)addArcWithCenter:(CGPoint)center radius:(double)radius
               startAngle:(double)start endAngle:(double)end
                clockwise:(BOOL)clockwise
{
    int steps = 64;
    for (int i = 0; i <= steps; i++)
    {
        double t = (double)i / steps;
        double a = start + (end - start) * t;
        if (!clockwise)
            a = start + (end - start) * t;
        [self addLineToPoint:CGPointMake(center.x + radius * __builtin_cos(a),
                                         center.y + radius * __builtin_sin(a))];
    }
}
- (void)closePath { }
- (void)appendPath:(UIBezierPath *)path
{
    if (!path)
        return;
    if (path->_shape == 0)
    {
        for (int i = 0; i < path->_count && _count < 512; i++)
            [self addLineToPoint:CGPointMake(path->_xs[i], path->_ys[i])];
    }
}
- (void)addRect:(CGRect)rect { (void)rect; }
- (void)addOvalInRect:(CGRect)rect { (void)rect; }
- (void)addRoundedRect:(CGRect)rect cornerRadius:(double)radius
{ (void)rect; (void)radius; }
- (CGPathRef)CGPath { return (CGPathRef)self; }
@end

@implementation CAShapeLayer
- (id)init
{
    self = [super init];
    if (self)
        _lineWidth = 1.0;
    return self;
}
- (void)setPath:(id)path { _path = path; }
- (id)path { return _path; }
- (void)setFillColor:(id)color { _fillColor = color; }
- (id)fillColor { return _fillColor; }
- (void)setStrokeColor:(id)color { _strokeColor = color; }
- (id)strokeColor { return _strokeColor; }
- (void)setLineWidth:(double)width { _lineWidth = width; }
- (double)lineWidth { return _lineWidth; }
@end

@implementation CAGradientLayer
- (id)init
{
    self = [super init];
    if (self)
    {
        _startPoint = CGPointMake(0.5, 0.0);
        _endPoint = CGPointMake(0.5, 1.0);
    }
    return self;
}
- (void)setColors:(NSArray *)colors { _colors = colors; }
- (NSArray *)colors { return _colors; }
- (void)setStartPoint:(CGPoint)point { _startPoint = point; }
- (CGPoint)startPoint { return _startPoint; }
- (void)setEndPoint:(CGPoint)point { _endPoint = point; }
- (CGPoint)endPoint { return _endPoint; }
@end

/* ------------------------------------------------------------ image views */

@implementation UIImage
+ (id)imageWithContentsOfFile:(id)path
{
    const char *p = iosim_string_cstr(path);
    if (!p)
        return nil;
    unsigned char *rgba = 0;
    int w = 0, h = 0;
    if (iosim_png_load(p, &rgba, &w, &h) != 0)
        return nil;
    UIImage *image = [[self alloc] init];
    image->_rgba = rgba;
    image->_width = w;
    image->_height = h;
    return image;
}
+ (id)imageNamed:(id)name
{
    const char *n = iosim_string_cstr(name);
    const char *dir = getenv("IOSIM_BUNDLE_DIR");
    if (!dir || !*dir)
        dir = ".";
    char path[1024];
    snprintf(path, sizeof(path), "%s/%s", dir, n ? n : "");
    id image = [self imageWithContentsOfFile:[NSString stringWithUTF8String:path]];
    if (image)
        return image;
    snprintf(path, sizeof(path), "%s/%s.png", dir, n ? n : "");
    return [self imageWithContentsOfFile:[NSString stringWithUTF8String:path]];
}
- (int)width { return _width; }
- (int)height { return _height; }
@end

@implementation UIImageView
- (id)initWithImage:(UIImage *)image
{
    self = [super initWithFrame:CGRectMake(0, 0, 0, 0)];
    if (self)
        _image = image;
    return self;
}
- (void)setImage:(UIImage *)image { _image = image; }
- (UIImage *)image { return _image; }
- (void)setContentMode:(int)mode { _contentMode = mode; }
- (int)contentMode { return _contentMode; }
@end

@implementation UIViewController
- (id)init { return [super init]; }
- (void)loadView
{
    _view = [[UIView alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
}
- (UIView *)view
{
    if (!_view)
        [self loadView];
    if (_view && !_viewLoaded)
    {
        _viewLoaded = YES;
        [self viewDidLoad];
    }
    return _view;
}
- (void)setView:(UIView *)view
{
    _view = view;
    if (_view && !_viewLoaded)
    {
        _viewLoaded = YES;
        [self viewDidLoad];
    }
}
- (void)viewDidLoad
{
}
@end

@implementation UIControl
- (void)addTarget:(id)target action:(SEL)action
    forControlEvents:(unsigned long)events
{
    _target = target;
    _action = action;
    _controlEvents = events;
}
- (void)sendActionsForControlEvents:(unsigned long)events
{
    if (_target && _action && (_controlEvents & events))
    {
        void (*imp)(id, SEL, id) = (void (*)(id, SEL, id))objc_msgSend;
        imp(_target, _action, self);
    }
}
@end

@implementation UIButton
+ (id)buttonWithType:(int)type
{
    (void)type;
    UIButton *button = [[self alloc] initWithFrame:CGRectMake(0, 0, 0, 0)];
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 0, 0)];
    label->_textAlignment = 1;
    label->_font = [UIFont systemFontOfSize:17];
    label->_textColor = [UIColor systemBlueColor];
    [button addSubview:label];
    button->_titleLabel = label;
    [button layoutTitle];
    return button;
}
- (void)layoutTitle
{
    if (_titleLabel)
        _titleLabel->_frame = CGRectMake(0, 0, _frame.size.width,
                                         _frame.size.height);
}
- (void)setFrame:(CGRect)frame
{
    [super setFrame:frame];
    [self layoutTitle];
}
- (void)setTitle:(id)title forState:(unsigned long)state
{
    (void)state;
    _title = title;
    _titleLabel->_text = title;
}
- (void)setTitleColor:(UIColor *)color forState:(unsigned long)state
{
    (void)state;
    _titleColor = color;
    _titleLabel->_textColor = color;
}
@end

static UIWindow *g_keyWindow;

@implementation UIWindow
- (id)initWithWindowScene:(UIWindowScene *)scene
{
    (void)scene;
    return [self initWithFrame:[[UIScreen mainScreen] bounds]];
}
- (void)setRootViewController:(UIViewController *)controller
{
    _rootViewController = controller;
    if (controller)
        [self addSubview:[controller view]];
}
- (UIViewController *)rootViewController { return _rootViewController; }
- (void)dispatchTapX:(int)x y:(int)y
{
    double scale = [[UIScreen mainScreen] scale];
    if (scale <= 0)
        scale = 1.0;
    CGPoint point = CGPointMake(x / scale, y / scale);
    UIView *hit = [self hitTest:point];
    if (hit && [hit isKindOfClass:[UIControl class]])
        [(UIControl *)hit sendActionsForControlEvents:UIControlEventTouchUpInside];
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
    const char *s = iosim_string_cstr(object);
    return (s && *s) ? s : 0;
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

static double ease_t(double t)
{
    if (t < 0) t = 0;
    if (t > 1) t = 1;
    return t * t * (3 - 2 * t);
}

static CGRect current_frame(UIView *view)
{
    if (view->_animatingFrame)
    {
        double t = (iosim_now() - view->_animStart) / view->_animDuration;
        if (t >= 1.0)
        {
            view->_animatingFrame = NO;
            view->_frame = view->_animFrameTo;
        }
        else
        {
            double e = ease_t(t);
            CGRect a = view->_animFrameFrom, b = view->_animFrameTo;
            return CGRectMake(a.origin.x + (b.origin.x - a.origin.x) * e,
                              a.origin.y + (b.origin.y - a.origin.y) * e,
                              a.size.width + (b.size.width - a.size.width) * e,
                              a.size.height + (b.size.height - a.size.height) * e);
        }
    }
    return view->_frame;
}

static double current_alpha(UIView *view)
{
    if (view->_animatingAlpha)
    {
        double t = (iosim_now() - view->_animStart) / view->_animDuration;
        if (t >= 1.0)
        {
            view->_animatingAlpha = NO;
            view->_alpha = view->_animAlphaTo;
        }
        else
            return view->_animAlphaFrom +
                   (view->_animAlphaTo - view->_animAlphaFrom) * ease_t(t);
    }
    return view->_alpha;
}

static double number_value(id value, double fallback)
{
    if (!value)
        return fallback;
    return ((double (*)(id, SEL))objc_msgSend)(value, @selector(doubleValue));
}

static double layer_key_value(CALayer *layer, const char *key, double base)
{
    if (!layer->_animKeyPath ||
        strcmp(iosim_string_cstr(layer->_animKeyPath), key) != 0)
        return base;
    double from = number_value(layer->_animFrom, base);
    double to = number_value(layer->_animTo, base);
    double t = (iosim_now() - layer->_animStart) / layer->_animDuration;
    if (layer->_animRepeatCount < 0 || layer->_animRepeatCount > 1)
    {
        double loops = t;
        if (loops < 0) loops = 0;
        t = loops - (long)loops;
    }
    else if (t >= 1.0)
        return to;
    return from + (to - from) * ease_t(t);
}


static void render_shape_path(UIBezierPath *path, int x, int y, int w, int h,
                              double scale, UIColor *fill, UIColor *stroke,
                              double lineWidth)
{
    if (!path)
        return;
    unsigned fill_color = color_rgb(fill);
    unsigned stroke_color = color_rgb(stroke);
    int thickness = (int)(lineWidth * scale + 0.5);
    if (thickness < 1)
        thickness = 1;

    if (path->_shape == 1 || path->_shape == 2)
    {
        int rx = x + (int)(path->_rect.origin.x * scale + 0.5);
        int ry = y + (int)(path->_rect.origin.y * scale + 0.5);
        int rw = (int)(path->_rect.size.width * scale + 0.5);
        int rh = (int)(path->_rect.size.height * scale + 0.5);
        if (fill && rw > 0 && rh > 0)
        {
            if (path->_shape == 2)
                iosim_fb_fill_round_rect(rx, ry, rw, rh,
                                         (int)(path->_cornerRadius * scale + 0.5),
                                         fill_color);
            else
                iosim_fb_fill_rect(rx, ry, rw, rh, fill_color);
        }
        if (stroke)
        {
            iosim_fb_draw_line(rx, ry, rx + rw, ry, thickness, stroke_color);
            iosim_fb_draw_line(rx + rw, ry, rx + rw, ry + rh, thickness, stroke_color);
            iosim_fb_draw_line(rx + rw, ry + rh, rx, ry + rh, thickness, stroke_color);
            iosim_fb_draw_line(rx, ry + rh, rx, ry, thickness, stroke_color);
        }
        return;
    }
    if (path->_shape == 3)
    {
        int rx = x + (int)(path->_rect.origin.x * scale + 0.5);
        int ry = y + (int)(path->_rect.origin.y * scale + 0.5);
        int rw = (int)(path->_rect.size.width * scale + 0.5);
        int rh = (int)(path->_rect.size.height * scale + 0.5);
        if (fill && rw > 0 && rh > 0)
            iosim_fb_fill_ellipse(rx + rw / 2, ry + rh / 2, rw / 2, rh / 2,
                                  fill_color);
        if (stroke && rw > 0 && rh > 0)
        {
            double cx = rx + rw / 2.0, cy = ry + rh / 2.0;
            double ax = rw / 2.0, ay = rh / 2.0;
            double px = cx + ax, py = cy;
            for (int i = 1; i <= 64; i++)
            {
                double t = 2 * 3.14159265358979323846 * i / 64.0;
                double nx = cx + ax * __builtin_cos(t);
                double ny = cy + ay * __builtin_sin(t);
                iosim_fb_draw_line((int)px, (int)py, (int)nx, (int)ny,
                                   thickness, stroke_color);
                px = nx; py = ny;
            }
        }
        return;
    }

    int count = path->_count;
    if (count <= 0)
        return;
    if (fill && count >= 3)
    {
        double xs[512], ys[512];
        for (int i = 0; i < count; i++)
        {
            xs[i] = x + path->_xs[i] * scale;
            ys[i] = y + path->_ys[i] * scale;
        }
        iosim_fb_fill_polygon(xs, ys, count, fill_color);
    }
    if (stroke)
    {
        for (int i = 0; i + 1 < count; i++)
            iosim_fb_draw_line((int)(x + path->_xs[i] * scale),
                               (int)(y + path->_ys[i] * scale),
                               (int)(x + path->_xs[i + 1] * scale),
                               (int)(y + path->_ys[i + 1] * scale),
                               thickness, stroke_color);
    }
}

static void render_layer(CALayer *layer, double parentX, double parentY,
                         double scale, double parentAlpha)
{
    if (!layer || layer->_hidden)
        return;
    double alpha = parentAlpha * layer_key_value(layer, "opacity", layer->_opacity);
    if (alpha <= 0.001)
        return;
    CGRect frame = layer->_frame;
    int x = (int)((parentX + frame.origin.x) * scale + 0.5);
    int y = (int)((parentY + frame.origin.y) * scale + 0.5);
    int w = (int)(frame.size.width * scale + 0.5);
    int h = (int)(frame.size.height * scale + 0.5);
    iosim_fb_set_opacity(alpha);
    if (layer->_backgroundColor && w > 0 && h > 0)
    {
        unsigned color = color_rgb(layer->_backgroundColor);
        double radius = layer_key_value(layer, "cornerRadius",
                                        layer->_cornerRadius);
        if (radius > 0)
            iosim_fb_fill_round_rect(x, y, w, h, (int)(radius * scale + 0.5),
                                     color);
        else
            iosim_fb_fill_rect(x, y, w, h, color);
    }
    if ([layer isKindOfClass:[CAGradientLayer class]])
    {
        CAGradientLayer *g = (CAGradientLayer *)layer;
        unsigned a = 0, b = 0;
        if (g->_colors && g->_colors->_count > 0)
        {
            a = color_rgb((UIColor *)[g->_colors objectAtIndex:0]);
            b = color_rgb((UIColor *)[g->_colors objectAtIndex:g->_colors->_count - 1]);
            iosim_fb_fill_linear_gradient(x, y, w, h, a, b, g->_startPoint.x,
                                          g->_startPoint.y, g->_endPoint.x,
                                          g->_endPoint.y);
        }
    }
    else if ([layer isKindOfClass:[CAShapeLayer class]])
    {
        CAShapeLayer *sl = (CAShapeLayer *)layer;
        render_shape_path((UIBezierPath *)sl->_path, x, y, w, h, scale,
                          (UIColor *)sl->_fillColor,
                          (UIColor *)sl->_strokeColor, sl->_lineWidth);
    }

    for (int i = 0; i < layer->_sublayerCount; i++)
        render_layer((CALayer *)layer->_sublayers[i], parentX + frame.origin.x,
                     parentY + frame.origin.y, scale, alpha);
    iosim_fb_set_opacity(1.0);
}

static void render_view(UIView *view, double originX, double originY,
                        double scale, double parentAlpha)
{
    if (!view || view->_hidden)
        return;

    double alpha = parentAlpha * current_alpha(view);
    if (alpha <= 0.001)
        return;
    iosim_fb_set_opacity(alpha);

    CGRect frame = current_frame(view);
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

    if (view->_layer)
    {
        for (int i = 0; i < view->_layer->_sublayerCount; i++)
            render_layer((CALayer *)view->_layer->_sublayers[i],
                         originX + frame.origin.x, originY + frame.origin.y,
                         scale, alpha);
    }

    if ([view isKindOfClass:[UIImageView class]])
    {
        UIImageView *iv = (UIImageView *)view;
        UIImage *image = iv->_image;
        if (image && image->_rgba && image->_width > 0 && image->_height > 0)
        {
            int dw = w, dh = h, dx = 0, dy = 0;
            if (iv->_contentMode == 1 || iv->_contentMode == 4)
            {
                if (iv->_contentMode == 1)
                {
                    double s = (double)w / image->_width;
                    double sy = (double)h / image->_height;
                    if (sy < s) s = sy;
                    dw = (int)(image->_width * s + 0.5);
                    dh = (int)(image->_height * s + 0.5);
                }
                else
                {
                    dw = image->_width / 3;
                    dh = image->_height / 3;
                    if (dw <= 0) dw = image->_width;
                    if (dh <= 0) dh = image->_height;
                }
                dx = (w - dw) / 2;
                dy = (h - dh) / 2;
            }
            if (dw > 0 && dh > 0)
                iosim_fb_blit_rgba_scaled(x + dx, y + dy, dw, dh,
                                          image->_rgba, image->_width,
                                          image->_height, image->_width * 4);
        }
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
                    scale, alpha);
    }
    iosim_fb_set_opacity(1.0);
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
    render_view(window, 0, 0, scale, 1.0);

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

    iosim_dispatch_drain_main();

    const char *path = getenv("IOSIM_SCREENSHOT_PATH");
    if (path && *path)
        iosim_fb_present(path);

    printf("[UIKit-lite] UIApplicationMain argc=%d delegate=%p window=%p\n",
           argc, delegate, window);
    printf("[UIKit-lite] rendered app frame at %.1fx scale\n", scale);

    if (getenv("IOSIM_EVENT_FIFO") && window)
    {
        int type = 0, x = 0, y = 0;
        int r;
        while ((r = iosim_event_next(&type, &x, &y)) != 0)
        {
            int redraw = 0;
            if (r == 1 && type == 1)
            {
                [window dispatchTapX:x y:y];
                redraw = 1;
            }
            if (iosim_foundation_tick())
                redraw = 1;
            if (iosim_dispatch_drain_main())
                redraw = 1;
            if (iosim_animations_active())
                redraw = 1;
            if (!redraw)
                continue;
            iosim_fb_set_opacity(1.0);
            render_view(window, 0, 0, scale, 1.0);
            if (path && *path)
                iosim_fb_present(path);
        }
    }
    return 0;
}
