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
extern int fflush(void *stream);
extern int fprintf(void *stream, const char *fmt, ...);
extern void *stderr;
extern char *getenv(const char *name);
extern int atoi(const char *s);
extern double atof(const char *s);
extern void *objc_getClass(const char *name);
extern void *objc_msgSend(void *self, void *sel, ...);

extern int  iosim_fb_begin(unsigned width, unsigned height);
extern void iosim_fb_clear(unsigned color);
extern void iosim_fb_fill_rect(int x, int y, int w, int h, unsigned color);
extern void iosim_fb_fill_round_rect(int x, int y, int w, int h, int radius,
                                     unsigned color);
extern void iosim_fb_fill_circle(int cx, int cy, int radius, unsigned color);
extern void iosim_fb_fill_circle_gradient(int cx, int cy, int radius,
                                          unsigned top, unsigned bottom);
extern void iosim_fb_fill_ellipse_gradient(int cx, int cy, int rx, int ry,
                                           unsigned top, unsigned bottom);
extern void iosim_fb_fill_arc_gradient(int cx, int cy, int radius, int thickness,
                                       double start_deg, double sweep_deg,
                                       const unsigned *colors,
                                       const double *stops, int nstops);
extern void iosim_fb_fill_ellipse_ring_gradient(int cx, int cy, int rx, int ry,
                                                int thickness,
                                                const unsigned *colors,
                                                const double *stops,
                                                int nstops);
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
extern int  iosim_event_open(void);
extern void iosim_fb_set_opacity(double opacity);
extern int iosim_fb_push_clip(int x, int y, int w, int h);
extern void iosim_fb_pop_clip(void);
extern double iosim_now(void);
extern int  iosim_foundation_tick(void);
extern int  iosim_dispatch_drain_main(void);
extern const char *iosim_string_cstr(id string);
extern int  strcmp(const char *a, const char *b);
extern unsigned long strlen(const char *s);
extern char *strstr(const char *haystack, const char *needle);
extern void *malloc(unsigned long size);
extern void  free(void *ptr);
extern void *memcpy(void *dst, const void *src, unsigned long n);
extern void *memset(void *dst, int c, unsigned long n);
extern int  snprintf(char *buf, unsigned long size, const char *fmt, ...);
extern int  iosim_fs_mkdir(const char *path, int intermediates);
extern int  iosim_fs_read(const char *path, unsigned char **out,
                          unsigned long *out_len);
extern int  iosim_fs_write(const char *path, const void *bytes,
                           unsigned long len);
extern int  iosim_png_load(const char *path, unsigned char **out_rgba,
                           int *out_width, int *out_height);
extern void *_Block_copy(void *block);
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
extern void *iosim_fb_begin_offscreen(unsigned width, unsigned height);
extern unsigned *iosim_fb_end_offscreen(void *state, int *out_w, int *out_h);
extern void iosim_fb_stroke_circle(int cx, int cy, int radius, int thickness,
                                   unsigned color);
extern void iosim_fb_mask_round_rect(int x, int y, int w, int h, int radius);
extern void iosim_fb_blit_affine(const unsigned *src, int sw, int sh,
                                 double fa, double fb, double fc, double fd,
                                 double ftx, double fty, double opacity);
extern void iosim_fb_free_offscreen(unsigned *buf);
extern void iosim_fb_blit_rgba_scaled(int x, int y, int w, int h,
                                      const unsigned char *rgba,
                                      int sw, int sh, int stride);
extern void iosim_fb_fill_linear_gradient_round_rect(int x, int y, int w,
                                                     int h, int radius,
                                                     unsigned start_color,
                                                     unsigned end_color,
                                                     double sx, double sy,
                                                     double ex, double ey);

typedef const void *CGPathRef;
typedef void *CGColorRef;

@class UIView;
@class UIWindowScene;

@class UIColor;

/* A layer can carry several explicit animations at once, keyed the way
 * CALayer keys them: adding with an existing key replaces that animation, and
 * adding without a key appends a new one. The most recently added animation
 * for a property wins when the renderer samples it. */
#define LAYER_ANIM_SLOTS 4
struct layer_anim {
    int used;
    int infinite;
    id keyPath;
    id fromValue;
    id toValue;
    id values;
    id keyTimes;
    id timingFunction;
    id key;
    double start;
    double duration;
    double repeatCount;
    double seq;
};

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
    struct layer_anim _anims[LAYER_ANIM_SLOTS];
    double _animSeq;
    id _ownerView;
    UIColor *_shadowColor;
    double _shadowOpacity;
    double _shadowRadius;
    CGSize _shadowOffset;
    double _borderWidth;
    UIColor *_borderColor;
    double _zPosition;
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
- (CALayer *)presentationLayer;
- (CALayer *)modelLayer;
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

@interface CAKeyframeAnimation : CAAnimation {
@public
    id _values;
    id _keyTimes;
}
- (void)setValues:(id)values;
- (void)setKeyTimes:(id)keyTimes;
@end

@interface CADisplayLink : NSObject {
@public
    id _target;
    SEL _selector;
    double _timestamp;
    double _duration;
    double _targetTimestamp;
    long _frameInterval;
    BOOL _paused;
    BOOL _valid;
    BOOL _scheduled;
}
+ (CADisplayLink *)displayLinkWithTarget:(id)target selector:(SEL)selector;
- (void)addToRunLoop:(id)runloop forMode:(id)mode;
- (void)removeFromRunLoop:(id)runloop forMode:(id)mode;
- (void)invalidate;
- (double)timestamp;
- (double)duration;
- (double)targetTimestamp;
- (BOOL)isPaused;
- (void)setPaused:(BOOL)paused;
- (BOOL)isValid;
- (long)frameInterval;
- (void)setFrameInterval:(long)interval;
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

typedef enum {
    UITouchPhaseBegan = 0,
    UITouchPhaseMoved = 1,
    UITouchPhaseStationary = 2,
    UITouchPhaseEnded = 3,
    UITouchPhaseCancelled = 4
} UITouchPhase;

@class UIWindow;

@interface UITouch : NSObject {
@public
    CGPoint _location;
    CGPoint _previousLocation;
    long _phase;
    double _timestamp;
    UIView *_view;
    UIWindow *_window;
    unsigned long _tapCount;
}
- (CGPoint)locationInView:(UIView *)view;
- (CGPoint)previousLocationInView:(UIView *)view;
- (long)phase;
- (double)timestamp;
- (unsigned long)tapCount;
- (UIView *)view;
- (UIWindow *)window;
@end

@interface UIEvent : NSObject {
@public
    UITouch *_touch;
}
- (id)initWithTouch:(UITouch *)touch;
- (NSSet *)allTouches;
- (NSSet *)touchesForView:(UIView *)view;
- (NSSet *)touchesForWindow:(UIWindow *)window;
@end

@interface UIResponder : NSObject
- (UIResponder *)nextResponder;
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event;
- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event;
- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event;
- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event;
@end

enum {
    NSLayoutAttributeNotAnAttribute = 0,
    NSLayoutAttributeLeft = 1,
    NSLayoutAttributeRight = 2,
    NSLayoutAttributeTop = 3,
    NSLayoutAttributeBottom = 4,
    NSLayoutAttributeLeading = 5,
    NSLayoutAttributeTrailing = 6,
    NSLayoutAttributeWidth = 7,
    NSLayoutAttributeHeight = 8,
    NSLayoutAttributeCenterX = 9,
    NSLayoutAttributeCenterY = 10,
    NSLayoutAttributeLastBaseline = 11,
    NSLayoutAttributeFirstBaseline = 12
};

enum {
    NSLayoutRelationLessThanOrEqual = -1,
    NSLayoutRelationEqual = 0,
    NSLayoutRelationGreaterThanOrEqual = 1
};

@class NSLayoutAnchor;
@class NSLayoutConstraint;
@class NSLayoutDimension;
@class UILayoutGuide;

@interface NSLayoutConstraint : NSObject {
@public
    id _firstItem;
    id _secondItem;
    long _firstAttribute;
    long _secondAttribute;
    long _relation;
    double _multiplier;
    double _constant;
    double _priority;
    BOOL _active;
}
+ (id)constraintWithItem:(id)firstItem attribute:(long)firstAttribute
                relatedBy:(long)relation toItem:(id)secondItem
               attribute:(long)secondAttribute multiplier:(double)multiplier
                constant:(double)constant;
+ (void)activateConstraints:(id)constraints;
+ (void)deactivateConstraints:(id)constraints;
- (void)setActive:(BOOL)active;
- (BOOL)isActive;
- (void)setPriority:(double)priority;
- (double)priority;
- (void)setConstant:(double)constant;
- (double)constant;
@end

@interface NSLayoutAnchor : NSObject {
@public
    id _item;
    long _attribute;
}
- (id)initWithItem:(id)item attribute:(long)attribute;
- (id)constraintEqualToAnchor:(NSLayoutAnchor *)anchor;
- (id)constraintEqualToAnchor:(NSLayoutAnchor *)anchor constant:(double)c;
- (id)constraintGreaterThanOrEqualToAnchor:(NSLayoutAnchor *)anchor;
- (id)constraintGreaterThanOrEqualToAnchor:(NSLayoutAnchor *)anchor constant:(double)c;
- (id)constraintLessThanOrEqualToAnchor:(NSLayoutAnchor *)anchor;
- (id)constraintLessThanOrEqualToAnchor:(NSLayoutAnchor *)anchor constant:(double)c;
@end

@interface NSLayoutDimension : NSLayoutAnchor
- (id)constraintEqualToConstant:(double)c;
- (id)constraintGreaterThanOrEqualToConstant:(double)c;
- (id)constraintLessThanOrEqualToConstant:(double)c;
- (id)constraintEqualToAnchor:(NSLayoutAnchor *)anchor multiplier:(double)m;
- (id)constraintEqualToAnchor:(NSLayoutAnchor *)anchor multiplier:(double)m
                     constant:(double)c;
@end

@interface UILayoutGuide : NSObject {
@public
    id _owningView;
    double _topInset;
    double _bottomInset;
    double _leftInset;
    double _rightInset;
}
- (id)owningView;
- (double)layoutFrameX;
- (double)layoutFrameY;
- (double)layoutFrameWidth;
- (double)layoutFrameHeight;
- (NSLayoutAnchor *)leadingAnchor;
- (NSLayoutAnchor *)trailingAnchor;
- (NSLayoutAnchor *)leftAnchor;
- (NSLayoutAnchor *)rightAnchor;
- (NSLayoutAnchor *)topAnchor;
- (NSLayoutAnchor *)bottomAnchor;
- (NSLayoutAnchor *)centerXAnchor;
- (NSLayoutAnchor *)centerYAnchor;
- (NSLayoutDimension *)widthAnchor;
- (NSLayoutDimension *)heightAnchor;
@end

@class UIGestureRecognizer;

typedef enum {
    UIGestureRecognizerStatePossible = 0,
    UIGestureRecognizerStateBegan = 1,
    UIGestureRecognizerStateChanged = 2,
    UIGestureRecognizerStateEnded = 3,
    UIGestureRecognizerStateCancelled = 4,
    UIGestureRecognizerStateFailed = 5,
    UIGestureRecognizerStateRecognized = 3
} UIGestureRecognizerState;

typedef enum {
    UISwipeGestureRecognizerDirectionRight = 1 << 0,
    UISwipeGestureRecognizerDirectionLeft = 1 << 1,
    UISwipeGestureRecognizerDirectionUp = 1 << 2,
    UISwipeGestureRecognizerDirectionDown = 1 << 3
} UISwipeGestureRecognizerDirection;

@interface UIGestureRecognizer : NSObject {
@public
    id _target;
    SEL _action;
    id _view;
    long _state;
    CGPoint _location;
    CGPoint _translation;
    BOOL _enabled;
}
- (id)initWithTarget:(id)target action:(SEL)action;
- (void)addTarget:(id)target action:(SEL)action;
- (long)state;
- (id)view;
- (CGPoint)locationInView:(UIView *)view;
- (void)setEnabled:(BOOL)enabled;
- (BOOL)isEnabled;
@end

@interface UITapGestureRecognizer : UIGestureRecognizer {
@public
    int _numberOfTapsRequired;
}
- (void)setNumberOfTapsRequired:(int)count;
- (int)numberOfTapsRequired;
@end

@interface UIPanGestureRecognizer : UIGestureRecognizer
- (CGPoint)translationInView:(UIView *)view;
- (CGPoint)velocityInView:(UIView *)view;
- (void)setTranslation:(CGPoint)translation inView:(UIView *)view;
@end

@interface UISwipeGestureRecognizer : UIGestureRecognizer {
@public
    long _direction;
}
- (void)setDirection:(long)direction;
- (long)direction;
@end

@interface UILongPressGestureRecognizer : UIGestureRecognizer {
@public
    double _minimumPressDuration;
    double _allowableMovement;
}
- (double)minimumPressDuration;
- (void)setMinimumPressDuration:(double)duration;
- (double)allowableMovement;
- (void)setAllowableMovement:(double)movement;
@end

typedef enum {
    UIViewAnimationOptionLayoutSubviews = 1 << 0,
    UIViewAnimationOptionAllowUserInteraction = 1 << 1,
    UIViewAnimationOptionBeginFromCurrentState = 1 << 2,
    UIViewAnimationOptionRepeat = 1 << 3,
    UIViewAnimationOptionAutoreverse = 1 << 4,
    UIViewAnimationOptionOverrideInheritedDuration = 1 << 5,
    UIViewAnimationOptionOverrideInheritedCurve = 1 << 6,
    UIViewAnimationOptionAllowAnimatedContent = 1 << 7,
    UIViewAnimationOptionShowHideTransitionViews = 1 << 8,
    UIViewAnimationOptionOverrideInheritedOptions = 1 << 9,
    UIViewAnimationOptionCurveEaseInOut = 0 << 16,
    UIViewAnimationOptionCurveEaseIn = 1 << 16,
    UIViewAnimationOptionCurveEaseOut = 2 << 16,
    UIViewAnimationOptionCurveLinear = 3 << 16
} UIViewAnimationOptions;

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
    double _animDelay;
    BOOL _animInfinite;
    BOOL _animAutoreverse;
    int _animCurve;
    id _superview;
    BOOL _needsLayout;
    CGAffineTransform _transform;
    BOOL _translatesAutoresizingMaskIntoConstraints;
    id _constraints[32];
    int _constraintCount;
    UILayoutGuide *_safeAreaGuide;
    BOOL _needsConstraintsUpdate;
    id _gestureRecognizers[8];
    int _gestureRecognizerCount;
    BOOL _clipsToBounds;
}
- (id)initWithFrame:(CGRect)frame;
- (CGRect)frame;
- (void)setFrame:(CGRect)frame;
- (CGRect)bounds;
- (void)setBackgroundColor:(UIColor *)color;
- (UIColor *)backgroundColor;
- (void)addSubview:(UIView *)view;
- (void)insertSubview:(UIView *)view atIndex:(long)index;
- (void)bringSubviewToFront:(UIView *)view;
- (void)sendSubviewToBack:(UIView *)view;
- (void)removeFromSuperview;
- (CALayer *)layer;
- (void)setHidden:(BOOL)hidden;
- (BOOL)isHidden;
- (void)setAlpha:(double)alpha;
- (double)alpha;
- (BOOL)pointInside:(CGPoint)point;
- (UIView *)hitTest:(CGPoint)point;
- (id)superview;
- (CGAffineTransform)transform;
- (void)setTransform:(CGAffineTransform)transform;
- (void)layoutSubviews;
- (void)setNeedsLayout;
- (void)layoutIfNeeded;
- (void)setNeedsUpdateConstraints;
- (void)updateConstraints;
- (void)updateConstraintsIfNeeded;
- (BOOL)translatesAutoresizingMaskIntoConstraints;
- (void)setTranslatesAutoresizingMaskIntoConstraints:(BOOL)value;
- (NSArray *)constraints;
- (void)addConstraint:(NSLayoutConstraint *)constraint;
- (void)removeConstraint:(NSLayoutConstraint *)constraint;
- (NSLayoutAnchor *)leadingAnchor;
- (NSLayoutAnchor *)trailingAnchor;
- (NSLayoutAnchor *)leftAnchor;
- (NSLayoutAnchor *)rightAnchor;
- (NSLayoutAnchor *)topAnchor;
- (NSLayoutAnchor *)bottomAnchor;
- (NSLayoutAnchor *)centerXAnchor;
- (NSLayoutAnchor *)centerYAnchor;
- (NSLayoutDimension *)widthAnchor;
- (NSLayoutDimension *)heightAnchor;
- (UILayoutGuide *)safeAreaLayoutGuide;
- (void)setClipsToBounds:(BOOL)clips;
- (BOOL)clipsToBounds;
- (void)addGestureRecognizer:(UIGestureRecognizer *)recognizer;
- (void)removeGestureRecognizer:(UIGestureRecognizer *)recognizer;
- (NSArray *)gestureRecognizers;
- (CGSize)sizeThatFits:(CGSize)size;
- (CGSize)intrinsicContentSize;
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
- (CGSize)intrinsicContentSize;
- (CGSize)sizeThatFits:(CGSize)size;
@end

@interface UITextView : UIView {
@public
    id _text;
    UIColor *_textColor;
    UIFont *_font;
    BOOL _editable;
}
- (id)text;
- (void)setText:(id)text;
- (UIFont *)font;
- (void)setFont:(UIFont *)font;
- (UIColor *)textColor;
- (void)setTextColor:(UIColor *)color;
- (BOOL)isEditable;
- (void)setEditable:(BOOL)editable;
- (void)insertText:(id)text;
- (void)deleteBackward;
- (BOOL)becomeFirstResponder;
- (BOOL)resignFirstResponder;
- (BOOL)isFirstResponder;
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
    id _title;
    id _navigationController;
    id _presentedController;
    id _tabBarItem;
    id _navigationItem;
}
- (id)init;
- (id)title;
- (void)setTitle:(id)title;
- (id)navigationController;
- (id)tabBarItem;
- (void)setTabBarItem:(id)item;
- (id)navigationItem;
- (UIView *)view;
- (void)setView:(UIView *)view;
- (void)loadView;
- (void)viewDidLoad;
- (void)viewWillAppear:(BOOL)animated;
- (void)viewDidAppear:(BOOL)animated;
- (void)viewWillDisappear:(BOOL)animated;
- (void)viewDidDisappear:(BOOL)animated;
- (void)viewWillLayoutSubviews;
- (void)viewDidLayoutSubviews;
- (void)presentViewController:(UIViewController *)controller animated:(BOOL)animated
                   completion:(void (^)(void))completion;
- (void)dismissViewControllerAnimated:(BOOL)animated
                           completion:(void (^)(void))completion;
- (UIViewController *)presentedViewController;
@end

enum {
    UIAlertControllerStyleActionSheet = 0,
    UIAlertControllerStyleAlert = 1
};

enum {
    UIAlertActionStyleDefault = 0,
    UIAlertActionStyleCancel = 1,
    UIAlertActionStyleDestructive = 2
};

@class UIAlertAction;

@interface UIAlertAction : NSObject {
@public
    id _title;
    long _style;
    void (^_handler)(UIAlertAction *);
}
+ (id)actionWithTitle:(id)title style:(long)style
              handler:(void (^)(UIAlertAction *action))handler;
- (id)title;
- (long)style;
- (void (^)(UIAlertAction *))handler;
@end

@interface UIAlertController : UIViewController {
@public
    id _message;
    id _actions[8];
    int _actionCount;
    long _preferredStyle;
}
+ (id)alertControllerWithTitle:(id)title message:(id)message
                 preferredStyle:(long)style;
- (void)addAction:(UIAlertAction *)action;
- (id)message;
- (long)preferredStyle;
- (NSArray *)actions;
@end

@interface UIStackView : UIView {
@public
    id _arranged[32];
    int _arrangedCount;
    long _axis;
    double _spacing;
    long _distribution;
    long _alignment;
}
- (id)initWithArrangedSubviews:(NSArray *)views;
- (void)addArrangedSubview:(UIView *)view;
- (void)removeArrangedSubview:(UIView *)view;
- (NSArray *)arrangedSubviews;
- (void)setAxis:(long)axis;
- (long)axis;
- (void)setSpacing:(double)spacing;
- (double)spacing;
- (void)setDistribution:(long)distribution;
- (long)distribution;
- (void)setAlignment:(long)alignment;
- (long)alignment;
@end

enum {
    UIBarButtonItemStylePlain = 0,
    UIBarButtonItemStyleBordered = 1,
    UIBarButtonItemStyleDone = 2
};

enum {
    UIBarButtonSystemItemDone = 0,
    UIBarButtonSystemItemCancel = 1,
    UIBarButtonSystemItemEdit = 2,
    UIBarButtonSystemItemSave = 3,
    UIBarButtonSystemItemAdd = 4,
    UIBarButtonSystemItemFlexibleSpace = 5,
    UIBarButtonSystemItemFixedSpace = 6,
    UIBarButtonSystemItemCompose = 7,
    UIBarButtonSystemItemReply = 8,
    UIBarButtonSystemItemSearch = 9,
    UIBarButtonSystemItemClose = 10
};

@interface UIBarButtonItem : NSObject {
@public
    id _title;
    long _style;
    long _systemItem;
    id _target;
    SEL _action;
    BOOL _enabled;
}
- (id)initWithTitle:(id)title style:(long)style target:(id)target
             action:(SEL)action;
- (id)initWithBarButtonSystemItem:(long)item target:(id)target
                           action:(SEL)action;
- (id)title;
- (void)setTitle:(id)title;
- (long)style;
- (void)setStyle:(long)style;
- (long)systemItem;
- (id)target;
- (SEL)action;
- (void)setEnabled:(BOOL)enabled;
- (BOOL)isEnabled;
@end

@interface UINavigationItem : NSObject {
@public
    id _title;
    id _leftBarButtonItem;
    id _rightBarButtonItem;
    id _backBarButtonItem;
    BOOL _hidesBackButton;
}
- (id)initWithTitle:(id)title;
- (id)title;
- (void)setTitle:(id)title;
- (id)leftBarButtonItem;
- (void)setLeftBarButtonItem:(id)item;
- (id)rightBarButtonItem;
- (void)setRightBarButtonItem:(id)item;
- (id)backBarButtonItem;
- (void)setBackBarButtonItem:(id)item;
- (BOOL)hidesBackButton;
- (void)setHidesBackButton:(BOOL)hidden;
@end

@interface UINavigationController : UIViewController {
@public
    id _stack[32];
    int _stackCount;
    UIView *_navBar;
    UILabel *_navTitleLabel;
    BOOL _navBarHidden;
    UIView *_contentView;
    id _leftButton;
    id _rightButton;
}
- (id)initWithRootViewController:(UIViewController *)root;
- (UIViewController *)topViewController;
- (NSArray *)viewControllers;
- (void)pushViewController:(UIViewController *)controller animated:(BOOL)animated;
- (UIViewController *)popViewControllerAnimated:(BOOL)animated;
- (void)setNavigationBarHidden:(BOOL)hidden animated:(BOOL)animated;
- (BOOL)isNavigationBarHidden;
@end

@interface UITabBarItem : NSObject {
@public
    id _title;
    id _image;
    long _tag;
}
- (id)initWithTitle:(id)title image:(id)image tag:(long)tag;
- (id)title;
- (void)setTitle:(id)title;
- (id)image;
- (long)tag;
@end

/* Floating glass tab bar modeled on the iOS 26 design: the bar is inset from
 * the screen edges, sits above the home indicator and carries one control per
 * item, with an optional image above the title. */
@interface UITabBarController : UIViewController {
@public
    id _tabControllers[16];
    int _tabCount;
    int _selectedIndex;
    UIView *_tabBar;
    UIView *_tabContent;
    id _tabItemViews[16];
    id _tabItemLabels[16];
}
- (void)setViewControllers:(NSArray *)controllers;
- (NSArray *)viewControllers;
- (void)setSelectedIndex:(int)index;
- (int)selectedIndex;
- (UIViewController *)selectedViewController;
- (void)setSelectedViewController:(UIViewController *)controller;
@end

enum {
    UIControlStateNormal = 0,
    UIControlStateHighlighted = 1 << 0,
    UIControlStateDisabled = 1 << 1,
    UIControlStateSelected = 1 << 2
};

enum {
    UIControlEventTouchDown = 1 << 0,
    UIControlEventTouchDownRepeat = 1 << 1,
    UIControlEventTouchDragInside = 1 << 2,
    UIControlEventTouchDragOutside = 1 << 3,
    UIControlEventTouchDragEnter = 1 << 4,
    UIControlEventTouchDragExit = 1 << 5,
    UIControlEventTouchUpInside = 1 << 6,
    UIControlEventTouchUpOutside = 1 << 7,
    UIControlEventTouchCancel = 1 << 8,
    UIControlEventValueChanged = 1 << 12,
    UIControlEventEditingDidBegin = 1 << 16,
    UIControlEventEditingChanged = 1 << 17,
    UIControlEventEditingDidEnd = 1 << 18,
    UIControlEventEditingDidEndOnExit = 1 << 19
};

enum {
    UIButtonTypeSystem = 1
};

@interface UIControl : UIView {
@public
    id _target;
    SEL _action;
    unsigned long _controlEvents;
    BOOL _highlighted;
    BOOL _enabled;
    BOOL _selected;
    BOOL _tracking;
    int _touchInside;
}
- (void)addTarget:(id)target action:(SEL)action
    forControlEvents:(unsigned long)events;
- (void)sendActionsForControlEvents:(unsigned long)events;
- (BOOL)isHighlighted;
- (void)setHighlighted:(BOOL)highlighted;
- (BOOL)isEnabled;
- (void)setEnabled:(BOOL)enabled;
- (BOOL)isSelected;
- (void)setSelected:(BOOL)selected;
- (unsigned long)state;
- (BOOL)beginTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event;
- (BOOL)continueTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event;
- (void)endTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event;
- (void)cancelTrackingWithEvent:(UIEvent *)event;
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


@interface UITextField : UIControl {
@public
    id _text;
    id _placeholder;
    UIFont *_font;
    UIColor *_textColor;
    BOOL _secureTextEntry;
    BOOL _firstResponder;
    BOOL _enablesReturnKeyAutomatically;
    int _textAlignment;
    int _keyboardType;
    int _returnKeyType;
    id _delegate;
}
- (void)setText:(id)text;
- (id)text;
- (void)setPlaceholder:(id)text;
- (id)placeholder;
- (void)setTextColor:(UIColor *)color;
- (UIColor *)textColor;
- (void)setFont:(UIFont *)font;
- (UIFont *)font;
- (void)setTextAlignment:(int)alignment;
- (int)textAlignment;
- (void)setSecureTextEntry:(BOOL)secure;
- (BOOL)isSecureTextEntry;
- (void)setKeyboardType:(int)type;
- (int)keyboardType;
- (void)setReturnKeyType:(int)type;
- (int)returnKeyType;
- (void)setDelegate:(id)delegate;
- (id)delegate;
- (BOOL)becomeFirstResponder;
- (BOOL)resignFirstResponder;
- (BOOL)isFirstResponder;
- (BOOL)hasText;
- (void)insertText:(id)text;
- (void)deleteBackward;
- (CGSize)intrinsicContentSize;
@end


@interface UISwitch : UIControl {
@public
    BOOL _on;
    UIColor *_onTintColor;
}
- (void)setOn:(BOOL)on;
- (void)setOn:(BOOL)on animated:(BOOL)animated;
- (BOOL)isOn;
- (void)setOnTintColor:(UIColor *)color;
- (UIColor *)onTintColor;
@end

@interface UISlider : UIControl {
@public
    double _value;
    double _minimumValue;
    double _maximumValue;
    UIColor *_minTrackTintColor;
    UIColor *_maxTrackTintColor;
    UIColor *_thumbTintColor;
}
- (void)updateValueFromPoint:(CGPoint)point;
- (void)setValue:(double)value animated:(BOOL)animated;
- (double)value;
- (void)setMinimumValue:(double)value;
- (double)minimumValue;
- (void)setMaximumValue:(double)value;
- (double)maximumValue;
- (void)setMinimumTrackTintColor:(UIColor *)color;
- (UIColor *)minimumTrackTintColor;
- (void)setMaximumTrackTintColor:(UIColor *)color;
- (UIColor *)maximumTrackTintColor;
- (void)setThumbTintColor:(UIColor *)color;
- (UIColor *)thumbTintColor;
- (void)setValueFromPoint:(CGPoint)point;
@end

@interface UIProgressView : UIView {
@public
    double _progress;
    UIColor *_progressTintColor;
    UIColor *_trackTintColor;
}
- (void)setProgress:(double)progress animated:(BOOL)animated;
- (double)progress;
- (void)setProgressTintColor:(UIColor *)color;
- (UIColor *)progressTintColor;
- (void)setTrackTintColor:(UIColor *)color;
- (UIColor *)trackTintColor;
@end

@interface UISegmentedControl : UIControl {
@public
    id _items[8];
    int _itemCount;
    long _selectedSegmentIndex;
    UIColor *_tintColor;
}
- (id)initWithItems:(NSArray *)items;
- (void)setTitle:(id)title forSegmentAtIndex:(unsigned long)index;
- (id)titleForSegmentAtIndex:(unsigned long)index;
- (void)setSelectedSegmentIndex:(long)index;
- (long)selectedSegmentIndex;
- (void)setTintColor:(UIColor *)color;
- (UIColor *)tintColor;
- (void)selectSegmentAtPoint:(CGPoint)point;
@end

@interface UIActivityIndicatorView : UIView {
@public
    BOOL _animating;
    long _style;
    UIColor *_color;
}
- (id)initWithActivityIndicatorStyle:(long)style;
- (void)startAnimating;
- (void)stopAnimating;
- (BOOL)isAnimating;
- (void)setColor:(UIColor *)color;
- (UIColor *)color;
@end

@interface UIPageControl : UIControl {
@public
    long _numberOfPages;
    long _currentPage;
    UIColor *_pageTintColor;
    UIColor *_currentPageTintColor;
}
- (void)setNumberOfPages:(long)pages;
- (long)numberOfPages;
- (void)setCurrentPage:(long)page;
- (long)currentPage;
- (void)setPageTintColor:(UIColor *)color;
- (UIColor *)pageTintColor;
- (void)setCurrentPageTintColor:(UIColor *)color;
- (UIColor *)currentPageTintColor;
- (void)selectPageAtPoint:(CGPoint)point;
@end

@interface UIScrollView : UIView {
@public
    CGSize _contentSize;
    CGPoint _contentOffset;
    BOOL _scrollEnabled;
    BOOL _showsVerticalScrollIndicator;
    BOOL _bounces;
    id _delegate;
}
- (CGSize)contentSize;
- (void)setContentSize:(CGSize)size;
- (CGPoint)contentOffset;
- (void)setContentOffset:(CGPoint)offset;
- (void)setContentOffset:(CGPoint)offset animated:(BOOL)animated;
- (BOOL)isScrollEnabled;
- (void)setScrollEnabled:(BOOL)enabled;
- (void)setDelegate:(id)delegate;
- (id)delegate;
- (BOOL)showsVerticalScrollIndicator;
- (void)setShowsVerticalScrollIndicator:(BOOL)shows;
@end

@class UITableView;
@class UITableViewCell;
@class NSIndexPath;

@protocol UITableViewDataSource
@optional
- (long)tableView:(UITableView *)tableView numberOfRowsInSection:(long)section;
- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath;
@end

@protocol UITableViewDelegate
@optional
- (double)tableView:(UITableView *)tableView
    heightForRowAtIndexPath:(NSIndexPath *)indexPath;
- (void)tableView:(UITableView *)tableView
    didSelectRowAtIndexPath:(NSIndexPath *)indexPath;
@end

enum {
    UITableViewCellStyleDefault = 0,
    UITableViewCellStyleValue1 = 1,
    UITableViewCellStyleValue2 = 2,
    UITableViewCellStyleSubtitle = 3,
    UITableViewCellAccessoryNone = 0,
    UITableViewCellAccessoryDisclosureIndicator = 1,
    UITableViewCellAccessoryDetailDisclosureButton = 2,
    UITableViewCellAccessoryCheckmark = 3,
    UITableViewCellSelectionStyleNone = 0,
    UITableViewCellSelectionStyleBlue = 1,
    UITableViewCellSelectionStyleGray = 2,
    UITableViewStylePlain = 0,
    UITableViewStyleGrouped = 1
};

@interface UITableViewCell : UIView {
@public
    UILabel *_textLabel;
    UILabel *_detailTextLabel;
    UIImageView *_imageView;
    long _accessoryType;
    long _selectionStyle;
    BOOL _selected;
    id _reuseIdentifier;
    long _style;
}
- (id)initWithStyle:(long)style reuseIdentifier:(id)reuseIdentifier;
- (UILabel *)textLabel;
- (UILabel *)detailTextLabel;
- (UIImageView *)imageView;
- (UIView *)contentView;
- (id)reuseIdentifier;
- (void)setAccessoryType:(long)type;
- (long)accessoryType;
- (void)setSelectionStyle:(long)style;
- (long)selectionStyle;
- (void)setSelected:(BOOL)selected animated:(BOOL)animated;
- (BOOL)isSelected;
- (void)setHighlighted:(BOOL)highlighted animated:(BOOL)animated;
- (void)prepareForReuse;
@end

@interface UITableView : UIScrollView {
@public
    id _dataSource;
    double _rowHeight;
    long _selectedRow;
    long _selectedSection;
    long _style;
    BOOL _needsReload;
}
- (void)setDataSource:(id)dataSource;
- (id)dataSource;
- (void)setDelegate:(id)delegate;
- (id)delegate;
- (void)setRowHeight:(double)height;
- (double)rowHeight;
- (id)initWithFrame:(CGRect)frame style:(long)style;
- (void)reloadData;
- (id)dequeueReusableCellWithIdentifier:(id)identifier;
- (void)handleTapAtPoint:(CGPoint)point;
@end

@class UICollectionView;
@class UICollectionViewCell;
@class UICollectionViewLayout;

@protocol UICollectionViewDataSource
@optional
- (long)collectionView:(UICollectionView *)collectionView
    numberOfItemsInSection:(long)section;
- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView
            cellForItemAtIndexPath:(NSIndexPath *)indexPath;
@end

@protocol UICollectionViewDelegate
@optional
- (void)collectionView:(UICollectionView *)collectionView
    didSelectItemAtIndexPath:(NSIndexPath *)indexPath;
@end

enum {
    UICollectionViewScrollDirectionVertical = 0,
    UICollectionViewScrollDirectionHorizontal = 1
};

@interface UICollectionViewLayout : NSObject
@end

@interface UICollectionViewFlowLayout : UICollectionViewLayout {
@public
    CGSize _itemSize;
    double _minimumInteritemSpacing;
    double _minimumLineSpacing;
    UIEdgeInsets _sectionInset;
    long _scrollDirection;
}
- (CGSize)itemSize;
- (void)setItemSize:(CGSize)size;
- (double)minimumInteritemSpacing;
- (void)setMinimumInteritemSpacing:(double)spacing;
- (double)minimumLineSpacing;
- (void)setMinimumLineSpacing:(double)spacing;
- (UIEdgeInsets)sectionInset;
- (void)setSectionInset:(UIEdgeInsets)insets;
- (long)scrollDirection;
- (void)setScrollDirection:(long)direction;
@end

@interface UICollectionViewCell : UIView {
@public
    id _contentView;
    id _reuseIdentifier;
    BOOL _selected;
}
- (UIView *)contentView;
- (id)reuseIdentifier;
- (void)setSelected:(BOOL)selected animated:(BOOL)animated;
- (BOOL)isSelected;
- (void)prepareForReuse;
@end

@interface UICollectionView : UIScrollView {
@public
    id _dataSource;
    UICollectionViewLayout *_collectionLayout;
    id _cellClasses;
    id _cells;
    long _selectedItem;
}
- (id)initWithFrame:(CGRect)frame
 collectionViewLayout:(UICollectionViewLayout *)layout;
- (void)setDataSource:(id)dataSource;
- (id)dataSource;
- (void)setDelegate:(id)delegate;
- (id)delegate;
- (UICollectionViewLayout *)collectionViewLayout;
- (void)registerClass:(Class)cellClass
    forCellWithReuseIdentifier:(id)identifier;
- (id)dequeueReusableCellWithReuseIdentifier:(id)identifier
                               forIndexPath:(NSIndexPath *)indexPath;
- (void)reloadData;
- (void)handleTapAtPoint:(CGPoint)point;
@end

@interface UIWindow : UIView {
@public
    UIViewController *_rootViewController;
    UIScrollView *_dragScroll;
    CGPoint _dragStartContent;
    CGPoint _dragStartPoint;
    UIView *_touchHit;
    UIPanGestureRecognizer *_activePan;
    UITouch *_touch;
    UIGestureRecognizer *_longPress;
    CGPoint _pressStartPoint;
    double _pressStartTime;
}
- (id)initWithWindowScene:(UIWindowScene *)scene;
- (void)setRootViewController:(UIViewController *)controller;
- (UIViewController *)rootViewController;
- (void)dispatchTapX:(int)x y:(int)y;
- (void)dispatchTouchDownX:(int)x y:(int)y;
- (void)dispatchTouchMoveX:(int)x y:(int)y;
- (void)dispatchTouchUpX:(int)x y:(int)y;
- (int)tickGestureRecognizers;
- (void)makeKeyAndVisible;
+ (UIWindow *)keyWindow;
@end

enum {
    UIApplicationStateActive = 0,
    UIApplicationStateInactive = 1,
    UIApplicationStateBackground = 2
};

@interface UIApplication : UIResponder {
@public
    id _delegate;
    long _state;
}
+ (UIApplication *)sharedApplication;
- (void)setDelegate:(id)delegate;
- (id)delegate;
- (long)applicationState;
- (double)backgroundTimeRemaining;
- (unsigned long)beginBackgroundTaskWithExpirationHandler:(void (^)(void))handler;
- (void)endBackgroundTask:(unsigned long)task;
@end

/* The system pasteboard lives in the device's shared resources directory so
 * every guest process reads and writes the same contents. */
@interface UIPasteboard : NSObject {
@public
    id _items;
    long _changeCount;
}
+ (UIPasteboard *)generalPasteboard;
- (id)string;
- (void)setString:(id)string;
- (BOOL)hasStrings;
- (id)items;
- (void)setItems:(id)items;
- (long)changeCount;
- (id)dataForPasteboardType:(id)type;
- (void)setData:(id)data forPasteboardType:(id)type;
- (long)numberOfItems;
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
static void animation_unmark_infinite(void);
static CGRect current_frame(UIView *view);
static double current_alpha(UIView *view);
static double layer_key_value(CALayer *layer, const char *key, double base);

@implementation CALayer
- (id)init
{
    self = [super init];
    if (self)
    {
        _opacity = 1.0;
        _shadowRadius = 3.0;
        _shadowOffset = CGSizeMake(0, -3);
        _shadowColor = [UIColor blackColor];
    }
    return self;
}
- (double)cornerRadius { return _cornerRadius; }
- (void)setCornerRadius:(double)radius { _cornerRadius = radius; }
- (void)setMasksToBounds:(BOOL)masks { _masksToBounds = masks; }
- (BOOL)masksToBounds { return _masksToBounds; }
- (void)setShadowColor:(UIColor *)color { _shadowColor = color; }
- (UIColor *)shadowColor { return _shadowColor; }
- (void)setShadowOpacity:(double)opacity { _shadowOpacity = opacity; }
- (double)shadowOpacity { return _shadowOpacity; }
- (void)setShadowRadius:(double)radius { _shadowRadius = radius; }
- (double)shadowRadius { return _shadowRadius; }
- (void)setShadowOffset:(CGSize)offset { _shadowOffset = offset; }
- (CGSize)shadowOffset { return _shadowOffset; }
- (void)setBorderWidth:(double)width { _borderWidth = width; }
- (double)borderWidth { return _borderWidth; }
- (void)setBorderColor:(UIColor *)color { _borderColor = color; }
- (UIColor *)borderColor { return _borderColor; }
- (void)setZPosition:(double)z { _zPosition = z; }
- (double)zPosition { return _zPosition; }
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
    CAAnimation *anim = (CAAnimation *)animation;
    BOOL keyframe = [anim isKindOfClass:[CAKeyframeAnimation class]];
    int slot = -1;
    if (key)
    {
        const char *wanted = iosim_string_cstr(key);
        for (int i = 0; i < LAYER_ANIM_SLOTS && slot < 0; i++)
        {
            if (!_anims[i].used || !_anims[i].key)
                continue;
            const char *held = iosim_string_cstr(_anims[i].key);
            if (held && wanted && strcmp(held, wanted) == 0)
                slot = i;
        }
    }
    for (int i = 0; i < LAYER_ANIM_SLOTS && slot < 0; i++)
        if (!_anims[i].used)
            slot = i;
    if (slot < 0)
        slot = 0; /* more animations than slots: replace the first */
    struct layer_anim *entry = &_anims[slot];
    if (entry->used && entry->infinite)
        animation_unmark_infinite();
    memset(entry, 0, sizeof(*entry));
    entry->used = 1;
    entry->keyPath = anim->_keyPath;
    entry->fromValue = keyframe ? nil : anim->_fromValue;
    entry->toValue = keyframe ? nil : anim->_toValue;
    entry->values = keyframe ? ((CAKeyframeAnimation *)anim)->_values : nil;
    entry->keyTimes = keyframe ? ((CAKeyframeAnimation *)anim)->_keyTimes : nil;
    entry->timingFunction = anim->_timingFunction;
    entry->key = key;
    entry->duration = anim->_duration;
    entry->repeatCount = anim->_repeatCount;
    entry->start = iosim_now();
    entry->seq = ++_animSeq;
    entry->infinite = anim->_repeatCount < 0;
    if (entry->duration <= 0)
        entry->duration = 0.25;
    animation_mark_active(entry->duration, entry->repeatCount);
}
- (void)removeAnimationForKey:(id)key
{
    const char *wanted = key ? iosim_string_cstr(key) : 0;
    if (!wanted)
        return;
    for (int i = 0; i < LAYER_ANIM_SLOTS; i++)
    {
        struct layer_anim *entry = &_anims[i];
        if (!entry->used || !entry->key)
            continue;
        const char *held = iosim_string_cstr(entry->key);
        if (!held || strcmp(held, wanted) != 0)
            continue;
        if (entry->infinite)
            animation_unmark_infinite();
        memset(entry, 0, sizeof(*entry));
    }
}
- (CALayer *)presentationLayer
{
    CALayer *presentation = [[CALayer alloc] init];
    CGRect frame = _frame;
    double opacity = _opacity;
    if (_ownerView)
    {
        frame = current_frame((UIView *)_ownerView);
        opacity = current_alpha((UIView *)_ownerView) * _opacity;
    }
    presentation->_frame = frame;
    presentation->_opacity = layer_key_value(self, "opacity", opacity);
    presentation->_cornerRadius =
        layer_key_value(self, "cornerRadius", _cornerRadius);
    presentation->_backgroundColor = _backgroundColor;
    return presentation;
}
- (CALayer *)modelLayer { return self; }
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

@implementation CAKeyframeAnimation
- (void)setValues:(id)values { _values = values; }
- (void)setKeyTimes:(id)keyTimes { _keyTimes = keyTimes; }
@end

/* Display links are driven by the UIApplicationMain run loop, which wakes
 * every 16 ms even when the event stream is idle. */

#define MAX_DISPLAY_LINKS 16
static CADisplayLink *g_displayLinks[MAX_DISPLAY_LINKS];
static int g_displayLinkCount;

static void display_link_remove(CADisplayLink *link)
{
    for (int i = 0; i < g_displayLinkCount; i++)
        if (g_displayLinks[i] == link)
        {
            for (int j = i; j + 1 < g_displayLinkCount; j++)
                g_displayLinks[j] = g_displayLinks[j + 1];
            g_displayLinkCount--;
            return;
        }
}

static int display_links_active(void)
{
    for (int i = 0; i < g_displayLinkCount; i++)
        if (g_displayLinks[i] && g_displayLinks[i]->_valid &&
            !g_displayLinks[i]->_paused)
            return 1;
    return 0;
}

int iosim_display_link_tick(void)
{
    int fired = 0;
    double now = iosim_now();
    int count = g_displayLinkCount;
    for (int i = 0; i < count && i < g_displayLinkCount; i++)
    {
        CADisplayLink *link = g_displayLinks[i];
        if (!link || !link->_valid || link->_paused)
            continue;
        if (now < link->_targetTimestamp)
            continue;
        link->_timestamp = now;
        link->_targetTimestamp = now + link->_duration;
        fired = 1;
        if (link->_target && link->_selector)
        {
            void (*imp)(id, SEL, id) = (void (*)(id, SEL, id))objc_msgSend;
            imp(link->_target, link->_selector, link);
        }
    }
    return fired;
}

@implementation CADisplayLink
+ (CADisplayLink *)displayLinkWithTarget:(id)target selector:(SEL)selector
{
    CADisplayLink *link = [[self alloc] init];
    if (link)
    {
        link->_target = target;
        link->_selector = selector;
        link->_duration = 1.0 / 60.0;
        link->_timestamp = iosim_now();
        link->_targetTimestamp = link->_timestamp;
        link->_frameInterval = 1;
        link->_valid = YES;
    }
    return link;
}
- (void)addToRunLoop:(id)runloop forMode:(id)mode
{
    (void)runloop;
    (void)mode;
    if (!_valid || _scheduled)
        return;
    if (g_displayLinkCount < MAX_DISPLAY_LINKS)
        g_displayLinks[g_displayLinkCount++] = self;
    _scheduled = YES;
}
- (void)removeFromRunLoop:(id)runloop forMode:(id)mode
{
    (void)runloop;
    (void)mode;
    display_link_remove(self);
    _scheduled = NO;
}
- (void)invalidate
{
    _valid = NO;
    _scheduled = NO;
    display_link_remove(self);
}
- (double)timestamp { return _timestamp; }
- (double)duration { return _duration; }
- (double)targetTimestamp { return _targetTimestamp; }
- (BOOL)isPaused { return _paused; }
- (void)setPaused:(BOOL)paused
{
    _paused = paused;
    if (!paused)
        _targetTimestamp = iosim_now() + _duration;
}
- (BOOL)isValid { return _valid; }
- (long)frameInterval { return _frameInterval; }
- (void)setFrameInterval:(long)interval
{
    if (interval < 1)
        interval = 1;
    _frameInterval = interval;
    _duration = interval / 60.0;
}
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
static double g_animateDelay;
static BOOL g_animateInfinite;
static BOOL g_animateAutoreverse;
static int g_animateCurve;
static double g_animActiveUntil;
static int g_animInfiniteCount;

#define MAX_ANIMATION_COMPLETIONS 32
static void (^g_completionBlocks[MAX_ANIMATION_COMPLETIONS])(BOOL);
static double g_completionDue[MAX_ANIMATION_COMPLETIONS];
static int g_completionCount;

static int display_links_active(void);
int iosim_display_link_tick(void);
int iosim_animation_tick(void);

static void animation_mark_active(double duration, double repeat)
{
    if (repeat < 0)
        g_animInfiniteCount++;
    else
    {
        double total = duration * (repeat > 0 ? repeat : 1);
        double until = iosim_now() + total;
        if (until > g_animActiveUntil)
            g_animActiveUntil = until;
    }
}

static void animation_unmark_infinite(void)
{
    if (g_animInfiniteCount > 0)
        g_animInfiniteCount--;
}

static void animation_add_completion(double delay, void (^completion)(BOOL))
{
    if (!completion || g_completionCount >= MAX_ANIMATION_COMPLETIONS)
        return;
    g_completionBlocks[g_completionCount] =
        (void (^)(BOOL))_Block_copy(completion);
    g_completionDue[g_completionCount] = iosim_now() + delay;
    g_completionCount++;
}

/* Fire animations that have reached their end. The run loop calls this on
 * every tick, so a completion block observes the settled model values. */
int iosim_animation_tick(void)
{
    int fired = 0;
    double now = iosim_now();
    int i = 0;
    while (i < g_completionCount)
    {
        if (now >= g_completionDue[i])
        {
            void (^block)(BOOL) = g_completionBlocks[i];
            g_completionBlocks[i] = g_completionBlocks[g_completionCount - 1];
            g_completionDue[i] = g_completionDue[g_completionCount - 1];
            g_completionCount--;
            if (block)
                block(YES);
            fired = 1;
        }
        else
            i++;
    }
    return fired;
}

int iosim_animations_active(void)
{
    return g_animInfiniteCount > 0 || iosim_now() < g_animActiveUntil ||
           g_completionCount > 0 || display_links_active();
}

@implementation UIResponder
- (UIResponder *)nextResponder { return nil; }
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    (void)touches;
    (void)event;
    [[self nextResponder] touchesBegan:touches withEvent:event];
}
- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    (void)touches;
    (void)event;
    [[self nextResponder] touchesMoved:touches withEvent:event];
}
- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    (void)touches;
    (void)event;
    [[self nextResponder] touchesEnded:touches withEvent:event];
}
- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    (void)touches;
    (void)event;
    [[self nextResponder] touchesCancelled:touches withEvent:event];
}
@end

/* ---------------------------------------------------------------- touches */

/* Window-point to view-local conversion along the view hierarchy. Scroll
 * views shift their content, as do the controls that use them. */
static CGPoint touch_point_in_view(UIView *view, CGPoint point)
{
    double ox = 0, oy = 0;
    for (UIView *v = view; v; v = (UIView *)v->_superview)
    {
        ox += v->_frame.origin.x;
        oy += v->_frame.origin.y;
        if ([v isKindOfClass:[UIScrollView class]])
        {
            UIScrollView *scroll = (UIScrollView *)v;
            ox -= scroll->_contentOffset.x;
            oy -= scroll->_contentOffset.y;
        }
    }
    return CGPointMake(point.x - ox, point.y - oy);
}

@implementation UITouch
- (CGPoint)locationInView:(UIView *)view
{
    if (!view || (id)view == (id)_window)
        return _location;
    return touch_point_in_view(view, _location);
}
- (CGPoint)previousLocationInView:(UIView *)view
{
    if (!view || (id)view == (id)_window)
        return _previousLocation;
    return touch_point_in_view(view, _previousLocation);
}
- (long)phase { return _phase; }
- (double)timestamp { return _timestamp; }
- (unsigned long)tapCount { return _tapCount; }
- (UIView *)view { return _view; }
- (UIWindow *)window { return _window; }
@end

@implementation UIEvent
- (id)initWithTouch:(UITouch *)touch
{
    self = [super init];
    if (self)
        _touch = touch;
    return self;
}
- (NSSet *)allTouches
{
    if (!_touch)
        return [NSSet set];
    return [NSSet setWithObject:_touch];
}
- (NSSet *)touchesForView:(UIView *)view
{
    if (_touch && (id)_touch->_view == (id)view)
        return [NSSet setWithObject:_touch];
    return [NSSet set];
}
- (NSSet *)touchesForWindow:(UIWindow *)window
{
    if (_touch && (id)_touch->_window == (id)window)
        return [NSSet setWithObject:_touch];
    return [NSSet set];
}
@end

/* ------------------------------------------------------- auto layout */

#define MAX_ACTIVE_CONSTRAINTS 256
static NSLayoutConstraint *g_activeConstraints[MAX_ACTIVE_CONSTRAINTS];
static int g_activeConstraintCount;

static NSLayoutConstraint *make_layout_constraint(id item1, long attr1,
                                                  long relation, id item2,
                                                  long attr2, double multiplier,
                                                  double constant)
{
    NSLayoutConstraint *c = [[NSLayoutConstraint alloc] init];
    c->_firstItem = item1;
    c->_firstAttribute = attr1;
    c->_relation = relation;
    c->_secondItem = item2;
    c->_secondAttribute = attr2;
    c->_multiplier = multiplier;
    c->_constant = constant;
    c->_priority = 1000.0;
    return c;
}

@implementation NSLayoutConstraint
+ (id)constraintWithItem:(id)firstItem attribute:(long)firstAttribute
                relatedBy:(long)relation toItem:(id)secondItem
               attribute:(long)secondAttribute multiplier:(double)multiplier
                constant:(double)constant
{
    return make_layout_constraint(firstItem, firstAttribute, relation,
                                  secondItem, secondAttribute, multiplier,
                                  constant);
}
+ (void)activateConstraints:(id)constraints
{
    if (!constraints)
        return;
    unsigned long n = [constraints count];
    for (unsigned long i = 0; i < n; i++)
        [(NSLayoutConstraint *)[constraints objectAtIndex:i] setActive:YES];
}
+ (void)deactivateConstraints:(id)constraints
{
    if (!constraints)
        return;
    unsigned long n = [constraints count];
    for (unsigned long i = 0; i < n; i++)
        [(NSLayoutConstraint *)[constraints objectAtIndex:i] setActive:NO];
}
- (void)setActive:(BOOL)active
{
    if (active == _active)
        return;
    if (active)
    {
        if (g_activeConstraintCount < MAX_ACTIVE_CONSTRAINTS)
            g_activeConstraints[g_activeConstraintCount++] = self;
    }
    else
    {
        for (int i = 0; i < g_activeConstraintCount; i++)
            if (g_activeConstraints[i] == self)
            {
                for (int j = i; j + 1 < g_activeConstraintCount; j++)
                    g_activeConstraints[j] = g_activeConstraints[j + 1];
                g_activeConstraintCount--;
                break;
            }
    }
    _active = active;
}
- (BOOL)isActive { return _active; }
- (void)setPriority:(double)priority { _priority = priority; }
- (double)priority { return _priority; }
- (void)setConstant:(double)constant { _constant = constant; }
- (double)constant { return _constant; }
@end

@implementation NSLayoutAnchor
- (id)initWithItem:(id)item attribute:(long)attribute
{
    self = [super init];
    if (self)
    {
        _item = item;
        _attribute = attribute;
    }
    return self;
}
- (id)constraintEqualToAnchor:(NSLayoutAnchor *)anchor
{
    return make_layout_constraint(_item, _attribute, NSLayoutRelationEqual,
                                  anchor->_item, anchor->_attribute, 1.0, 0.0);
}
- (id)constraintEqualToAnchor:(NSLayoutAnchor *)anchor constant:(double)c
{
    return make_layout_constraint(_item, _attribute, NSLayoutRelationEqual,
                                  anchor->_item, anchor->_attribute, 1.0, c);
}
- (id)constraintGreaterThanOrEqualToAnchor:(NSLayoutAnchor *)anchor
{
    return make_layout_constraint(_item, _attribute,
                                  NSLayoutRelationGreaterThanOrEqual,
                                  anchor->_item, anchor->_attribute, 1.0, 0.0);
}
- (id)constraintGreaterThanOrEqualToAnchor:(NSLayoutAnchor *)anchor
                                 constant:(double)c
{
    return make_layout_constraint(_item, _attribute,
                                  NSLayoutRelationGreaterThanOrEqual,
                                  anchor->_item, anchor->_attribute, 1.0, c);
}
- (id)constraintLessThanOrEqualToAnchor:(NSLayoutAnchor *)anchor
{
    return make_layout_constraint(_item, _attribute,
                                  NSLayoutRelationLessThanOrEqual,
                                  anchor->_item, anchor->_attribute, 1.0, 0.0);
}
- (id)constraintLessThanOrEqualToAnchor:(NSLayoutAnchor *)anchor
                              constant:(double)c
{
    return make_layout_constraint(_item, _attribute,
                                  NSLayoutRelationLessThanOrEqual,
                                  anchor->_item, anchor->_attribute, 1.0, c);
}
@end

@implementation NSLayoutDimension
- (id)constraintEqualToConstant:(double)c
{
    return make_layout_constraint(_item, _attribute, NSLayoutRelationEqual,
                                  nil, NSLayoutAttributeNotAnAttribute,
                                  0.0, c);
}
- (id)constraintGreaterThanOrEqualToConstant:(double)c
{
    return make_layout_constraint(_item, _attribute,
                                  NSLayoutRelationGreaterThanOrEqual, nil,
                                  NSLayoutAttributeNotAnAttribute, 0.0, c);
}
- (id)constraintLessThanOrEqualToConstant:(double)c
{
    return make_layout_constraint(_item, _attribute,
                                  NSLayoutRelationLessThanOrEqual, nil,
                                  NSLayoutAttributeNotAnAttribute, 0.0, c);
}
- (id)constraintEqualToAnchor:(NSLayoutAnchor *)anchor multiplier:(double)m
{
    return make_layout_constraint(_item, _attribute, NSLayoutRelationEqual,
                                  anchor->_item, anchor->_attribute, m, 0.0);
}
- (id)constraintEqualToAnchor:(NSLayoutAnchor *)anchor multiplier:(double)m
                     constant:(double)c
{
    return make_layout_constraint(_item, _attribute, NSLayoutRelationEqual,
                                  anchor->_item, anchor->_attribute, m, c);
}
@end

@implementation UILayoutGuide
- (id)owningView { return _owningView; }
- (double)layoutFrameX { return 0; }
- (double)layoutFrameY { return 0; }
- (double)layoutFrameWidth { return 0; }
- (double)layoutFrameHeight { return 0; }
- (NSLayoutAnchor *)leadingAnchor
{
    return [[NSLayoutAnchor alloc] initWithItem:self
                                      attribute:NSLayoutAttributeLeading];
}
- (NSLayoutAnchor *)trailingAnchor
{
    return [[NSLayoutAnchor alloc] initWithItem:self
                                      attribute:NSLayoutAttributeTrailing];
}
- (NSLayoutAnchor *)leftAnchor
{
    return [[NSLayoutAnchor alloc] initWithItem:self
                                      attribute:NSLayoutAttributeLeft];
}
- (NSLayoutAnchor *)rightAnchor
{
    return [[NSLayoutAnchor alloc] initWithItem:self
                                      attribute:NSLayoutAttributeRight];
}
- (NSLayoutAnchor *)topAnchor
{
    return [[NSLayoutAnchor alloc] initWithItem:self
                                      attribute:NSLayoutAttributeTop];
}
- (NSLayoutAnchor *)bottomAnchor
{
    return [[NSLayoutAnchor alloc] initWithItem:self
                                      attribute:NSLayoutAttributeBottom];
}
- (NSLayoutAnchor *)centerXAnchor
{
    return [[NSLayoutAnchor alloc] initWithItem:self
                                      attribute:NSLayoutAttributeCenterX];
}
- (NSLayoutAnchor *)centerYAnchor
{
    return [[NSLayoutAnchor alloc] initWithItem:self
                                      attribute:NSLayoutAttributeCenterY];
}
- (NSLayoutDimension *)widthAnchor
{
    return [[NSLayoutDimension alloc] initWithItem:self
                                         attribute:NSLayoutAttributeWidth];
}
- (NSLayoutDimension *)heightAnchor
{
    return [[NSLayoutDimension alloc] initWithItem:self
                                         attribute:NSLayoutAttributeHeight];
}
@end

@implementation UIGestureRecognizer
- (id)initWithTarget:(id)target action:(SEL)action
{
    self = [super init];
    if (self)
    {
        _target = target;
        _action = action;
        _state = UIGestureRecognizerStatePossible;
        _enabled = YES;
    }
    return self;
}
- (void)addTarget:(id)target action:(SEL)action
{
    _target = target;
    _action = action;
}
- (long)state { return _state; }
- (id)view { return _view; }
- (CGPoint)locationInView:(UIView *)view { (void)view; return _location; }
- (void)setEnabled:(BOOL)enabled { _enabled = enabled; }
- (BOOL)isEnabled { return _enabled; }
@end

@implementation UITapGestureRecognizer
- (void)setNumberOfTapsRequired:(int)count { _numberOfTapsRequired = count; }
- (int)numberOfTapsRequired { return _numberOfTapsRequired; }
@end

@implementation UIPanGestureRecognizer
- (CGPoint)translationInView:(UIView *)view
{
    (void)view;
    return _translation;
}
- (CGPoint)velocityInView:(UIView *)view
{
    (void)view;
    return CGPointMake(0, 0);
}
- (void)setTranslation:(CGPoint)translation inView:(UIView *)view
{
    (void)view;
    _translation = translation;
}
@end

@implementation UISwipeGestureRecognizer
- (void)setDirection:(long)direction { _direction = direction; }
- (long)direction { return _direction; }
@end

@implementation UILongPressGestureRecognizer
- (id)initWithTarget:(id)target action:(SEL)action
{
    self = [super initWithTarget:target action:action];
    if (self)
    {
        _minimumPressDuration = 0.5;
        _allowableMovement = 10.0;
    }
    return self;
}
- (double)minimumPressDuration { return _minimumPressDuration; }
- (void)setMinimumPressDuration:(double)duration
{
    _minimumPressDuration = duration;
}
- (double)allowableMovement { return _allowableMovement; }
- (void)setAllowableMovement:(double)movement
{
    _allowableMovement = movement;
}
@end

static void iosim_layout_apply(UIView *root);

#define IOSIM_MAX_WRAP_LINES 64

/* Greedy word wrap over UTF-8 text, measuring with the framebuffer font.
 * Explicit newlines always start a new line. Returns the line count. */
static int wrap_text_lines(const char *text, int style, double points,
                           double scale, int maxWidth,
                           char lines[][256], int maxLines)
{
    if (!text || !*text)
        return 0;
    if (maxLines <= 0 || maxLines > IOSIM_MAX_WRAP_LINES)
        maxLines = IOSIM_MAX_WRAP_LINES;
    int count = 0;
    const char *p = text;
    char line[256];
    int lineLen = 0;
    line[0] = 0;
    while (*p && count < maxLines)
    {
        if (*p == '\n')
        {
            memcpy(lines[count], line, (unsigned long)lineLen);
            lines[count][lineLen] = 0;
            count++;
            lineLen = 0;
            line[0] = 0;
            p++;
            continue;
        }
        if (*p == ' ' || *p == '\t' || *p == '\r')
        {
            p++;
            continue;
        }
        char word[256];
        int wl = 0;
        while (*p && *p != ' ' && *p != '\t' && *p != '\r' && *p != '\n' &&
               wl < 255)
            word[wl++] = *p++;
        word[wl] = 0;
        if (wl == 0)
        {
            p++;
            continue;
        }
        char cand[256];
        int cl = lineLen;
        if (cl + (cl ? 1 : 0) + wl >= 256)
        {
            memcpy(lines[count], line, (unsigned long)lineLen);
            lines[count][lineLen] = 0;
            count++;
            lineLen = 0;
            line[0] = 0;
            if (count >= maxLines)
                break;
            cl = 0;
        }
        memcpy(cand, line, (unsigned long)cl);
        if (cl)
            cand[cl++] = ' ';
        memcpy(cand + cl, word, (unsigned long)wl + 1);
        cl += wl;
        int width = iosim_fb_font_text_width(cand, style, points, scale);
        if (maxWidth > 0 && lineLen > 0 && width > maxWidth)
        {
            memcpy(lines[count], line, (unsigned long)lineLen);
            lines[count][lineLen] = 0;
            count++;
            if (count >= maxLines)
                break;
            memcpy(line, word, (unsigned long)wl + 1);
            lineLen = wl;
        }
        else
        {
            memcpy(line, cand, (unsigned long)cl + 1);
            lineLen = cl;
        }
    }
    if (count < maxLines && lineLen > 0)
    {
        memcpy(lines[count], line, (unsigned long)lineLen + 1);
        count++;
    }
    /* UIKit avoids a one-word last line by pulling the previous line's
     * final word down when the combined line still fits. Measured against
     * the real simulator this push-out applies to two-line paragraphs
     * (e.g. a body label); longer paragraphs keep the greedy break. */
    if (count == 2 && maxWidth > 0)
    {
        int lastHasSpace = 0;
        for (const char *q = lines[count - 1]; *q; q++)
            if (*q == ' ')
                lastHasSpace = 1;
        char *prev = lines[count - 2];
        char *sp = 0;
        for (char *q = prev; *q; q++)
            if (*q == ' ')
                sp = q;
        if (!lastHasSpace && sp && sp != prev)
        {
            const char *moved = sp + 1;
            char cand[256];
            int n = snprintf(cand, sizeof cand, "%s %s", moved,
                             lines[count - 1]);
            if (n > 0 && n < (int)sizeof cand &&
                iosim_fb_font_text_width(cand, style, points, scale) <=
                    maxWidth)
            {
                *sp = 0;
                memcpy(lines[count - 1], cand, (unsigned long)n + 1);
            }
        }
    }
    return count;
}

/* Wrapping for editable text keeps spaces and breaks at the last space that
 * fits, so the drawn text matches what was typed rather than a label-style
 * word list. */
static int wrap_editable_lines(const char *text, int style, double points,
                               double scale, int maxWidth,
                               char lines[][256], int maxLines)
{
    int count = 0;
    const char *p = text;
    while (*p && count < maxLines)
    {
        int lineLen = 0;
        int lastSpace = -1;
        char line[256];
        while (*p && *p != '\n')
        {
            if (lineLen >= 255)
                break;
            line[lineLen++] = *p;
            if (*p == ' ')
                lastSpace = lineLen - 1;
            p++;
            line[lineLen] = 0;
            if (maxWidth > 0 && lineLen > 1 &&
                iosim_fb_font_text_width(line, style, points, scale) >
                    maxWidth &&
                lastSpace > 0)
            {
                int pushed = lineLen - lastSpace - 1;
                p -= pushed;
                lineLen = lastSpace;
                line[lineLen] = 0;
                break;
            }
        }
        memcpy(lines[count], line, (unsigned long)lineLen + 1);
        count++;
        if (*p == '\n')
            p++;
    }
    return count;
}

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
        _layer->_ownerView = self;
        _transform = CGAffineTransformIdentityValue();
        _translatesAutoresizingMaskIntoConstraints = YES;
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
        _animDelay = g_animateDelay;
        _animInfinite = g_animateInfinite;
        _animAutoreverse = g_animateAutoreverse;
        _animCurve = g_animateCurve;
        _animatingFrame = YES;
        animation_mark_active(g_animDuration + g_animateDelay,
                              g_animateInfinite ? -1 : 0);
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
- (void)setClipsToBounds:(BOOL)clips { _clipsToBounds = clips; }
- (BOOL)clipsToBounds { return _clipsToBounds; }
- (void)addSubview:(UIView *)view
{
    if (!view)
        return;
    view->_superview = self;
    if (_subviewCount < 32)
        _subviews[_subviewCount++] = view;
}
- (void)insertSubview:(UIView *)view atIndex:(long)index
{
    if (!view)
        return;
    if (index < 0)
        index = 0;
    if (index >= _subviewCount || _subviewCount >= 32)
    {
        [self addSubview:view];
        return;
    }
    for (long i = _subviewCount; i > index; i--)
        _subviews[i] = _subviews[i - 1];
    _subviews[index] = view;
    _subviewCount++;
    view->_superview = self;
}
- (void)bringSubviewToFront:(UIView *)view
{
    if (!view)
        return;
    for (int i = 0; i < _subviewCount; i++)
    {
        if (_subviews[i] != view)
            continue;
        for (int j = i; j + 1 < _subviewCount; j++)
            _subviews[j] = _subviews[j + 1];
        _subviews[_subviewCount - 1] = view;
        return;
    }
}
- (void)sendSubviewToBack:(UIView *)view
{
    if (!view)
        return;
    for (int i = 0; i < _subviewCount; i++)
    {
        if (_subviews[i] != view)
            continue;
        for (int j = i; j > 0; j--)
            _subviews[j] = _subviews[j - 1];
        _subviews[0] = view;
        return;
    }
}
- (void)removeFromSuperview
{
    if (!_superview)
        return;
    UIView *parent = (UIView *)_superview;
    for (int i = 0; i < parent->_subviewCount; i++)
        if (parent->_subviews[i] == self)
        {
            for (int j = i; j + 1 < parent->_subviewCount; j++)
                parent->_subviews[j] = parent->_subviews[j + 1];
            parent->_subviewCount--;
            break;
        }
    _superview = nil;
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
        _animDelay = g_animateDelay;
        _animInfinite = g_animateInfinite;
        _animAutoreverse = g_animateAutoreverse;
        _animCurve = g_animateCurve;
        _animatingAlpha = YES;
        animation_mark_active(g_animDuration + g_animateDelay,
                              g_animateInfinite ? -1 : 0);
    }
    _alpha = alpha;
}
- (double)alpha { return _alpha; }
- (id)superview { return _superview; }
- (UIResponder *)nextResponder { return _superview; }
- (CGAffineTransform)transform { return _transform; }
- (void)setTransform:(CGAffineTransform)transform { _transform = transform; }
- (void)layoutSubviews { }
- (void)setNeedsLayout { _needsLayout = YES; }
- (void)layoutIfNeeded
{
    UIView *root = self;
    while (root->_superview)
        root = (UIView *)root->_superview;
    iosim_layout_apply(root);
    if (_needsLayout)
    {
        _needsLayout = NO;
        [self layoutSubviews];
    }
}
- (void)setNeedsUpdateConstraints
{
    _needsConstraintsUpdate = YES;
    _needsLayout = YES;
}
- (void)updateConstraints { }
- (void)updateConstraintsIfNeeded { _needsConstraintsUpdate = NO; }
- (BOOL)translatesAutoresizingMaskIntoConstraints
{
    return _translatesAutoresizingMaskIntoConstraints;
}
- (void)setTranslatesAutoresizingMaskIntoConstraints:(BOOL)value
{
    _translatesAutoresizingMaskIntoConstraints = value;
}
- (NSArray *)constraints
{
    return [NSArray arrayWithObjects:_constraints count:(unsigned long)_constraintCount];
}
- (void)addConstraint:(NSLayoutConstraint *)constraint
{
    if (!constraint)
        return;
    if (_constraintCount < 32)
        _constraints[_constraintCount++] = constraint;
    [constraint setActive:YES];
    _needsLayout = YES;
}
- (void)removeConstraint:(NSLayoutConstraint *)constraint
{
    for (int i = 0; i < _constraintCount; i++)
        if (_constraints[i] == constraint)
        {
            for (int j = i; j + 1 < _constraintCount; j++)
                _constraints[j] = _constraints[j + 1];
            _constraintCount--;
            break;
        }
    [constraint setActive:NO];
}
- (NSLayoutAnchor *)leadingAnchor
{
    return [[NSLayoutAnchor alloc] initWithItem:self
                                      attribute:NSLayoutAttributeLeading];
}
- (NSLayoutAnchor *)trailingAnchor
{
    return [[NSLayoutAnchor alloc] initWithItem:self
                                      attribute:NSLayoutAttributeTrailing];
}
- (NSLayoutAnchor *)leftAnchor
{
    return [[NSLayoutAnchor alloc] initWithItem:self
                                      attribute:NSLayoutAttributeLeft];
}
- (NSLayoutAnchor *)rightAnchor
{
    return [[NSLayoutAnchor alloc] initWithItem:self
                                      attribute:NSLayoutAttributeRight];
}
- (NSLayoutAnchor *)topAnchor
{
    return [[NSLayoutAnchor alloc] initWithItem:self
                                      attribute:NSLayoutAttributeTop];
}
- (NSLayoutAnchor *)bottomAnchor
{
    return [[NSLayoutAnchor alloc] initWithItem:self
                                      attribute:NSLayoutAttributeBottom];
}
- (NSLayoutAnchor *)centerXAnchor
{
    return [[NSLayoutAnchor alloc] initWithItem:self
                                      attribute:NSLayoutAttributeCenterX];
}
- (NSLayoutAnchor *)centerYAnchor
{
    return [[NSLayoutAnchor alloc] initWithItem:self
                                      attribute:NSLayoutAttributeCenterY];
}
- (NSLayoutDimension *)widthAnchor
{
    return [[NSLayoutDimension alloc] initWithItem:self
                                         attribute:NSLayoutAttributeWidth];
}
- (NSLayoutDimension *)heightAnchor
{
    return [[NSLayoutDimension alloc] initWithItem:self
                                         attribute:NSLayoutAttributeHeight];
}
- (UILayoutGuide *)safeAreaLayoutGuide
{
    if (!_safeAreaGuide)
    {
        _safeAreaGuide = [[UILayoutGuide alloc] init];
        _safeAreaGuide->_owningView = self;
        const char *top = getenv("IOSIM_SAFE_TOP");
        const char *bottom = getenv("IOSIM_SAFE_BOTTOM");
        _safeAreaGuide->_topInset = top ? atof(top) : 62.0;
        _safeAreaGuide->_bottomInset = bottom ? atof(bottom) : 34.0;
    }
    return _safeAreaGuide;
}
- (void)addGestureRecognizer:(UIGestureRecognizer *)recognizer
{
    if (!recognizer)
        return;
    recognizer->_view = self;
    if (_gestureRecognizerCount < 8)
        _gestureRecognizers[_gestureRecognizerCount++] = recognizer;
}
- (void)removeGestureRecognizer:(UIGestureRecognizer *)recognizer
{
    for (int i = 0; i < _gestureRecognizerCount; i++)
    {
        if (_gestureRecognizers[i] == recognizer)
        {
            for (int j = i; j + 1 < _gestureRecognizerCount; j++)
                _gestureRecognizers[j] = _gestureRecognizers[j + 1];
            _gestureRecognizerCount--;
            break;
        }
    }
}
- (NSArray *)gestureRecognizers
{
    return [NSArray arrayWithObjects:_gestureRecognizers
                                count:(unsigned long)_gestureRecognizerCount];
}
- (CGSize)sizeThatFits:(CGSize)size
{
    (void)size;
    return CGSizeMake(_frame.size.width, _frame.size.height);
}
- (CGSize)intrinsicContentSize
{
    return CGSizeMake(-1, -1);
}
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
    [self animateWithDuration:duration delay:0.0 options:0
                   animations:animations completion:nil];
}
+ (void)animateWithDuration:(double)duration animations:(void (^)(void))animations
                 completion:(void (^)(BOOL finished))completion
{
    [self animateWithDuration:duration delay:0.0 options:0
                   animations:animations completion:completion];
}
+ (void)animateWithDuration:(double)duration delay:(double)delay
                    options:(unsigned long)options
                 animations:(void (^)(void))animations
                 completion:(void (^)(BOOL finished))completion
{
    if (!animations)
        return;
    BOOL repeat = (options & UIViewAnimationOptionRepeat) != 0;
    g_animating = YES;
    g_animStart = iosim_now();
    g_animDuration = duration;
    g_animateDelay = delay;
    g_animateInfinite = repeat;
    g_animateAutoreverse = (options & UIViewAnimationOptionAutoreverse) != 0;
    g_animateCurve = (int)((options >> 16) & 3);
    animations();
    g_animating = NO;
    g_animateDelay = 0.0;
    g_animateInfinite = NO;
    g_animateAutoreverse = NO;
    g_animateCurve = 0;
    if (!repeat && completion)
        animation_add_completion(delay + duration, completion);
}
@end

@implementation UILabel
- (id)init
{
    self = [super init];
    if (self)
        _numberOfLines = 1;
    return self;
}
- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
        _numberOfLines = 1;
    return self;
}
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
- (CGSize)intrinsicContentSize
{
    const char *text = iosim_string_cstr(_text);
    double points = _font ? _font->_size : 17.0;
    int style = _font && _font->_bold ? IOSIM_FONT_BOLD : IOSIM_FONT_REGULAR;
    double scale = [[UIScreen mainScreen] scale];
    int width = 0, ascent = 0, descent = 0, lineHeight = 0;
    if (text)
        width = iosim_fb_font_text_width(text, style, points, scale);
    iosim_fb_font_metrics(style, points, scale, &ascent, &descent,
                          &lineHeight);
    return CGSizeMake(width / scale, lineHeight / scale);
}
- (CGSize)sizeThatFits:(CGSize)size
{
    const char *text = iosim_string_cstr(_text);
    if (!text || _numberOfLines == 1 || size.width <= 0)
        return [self intrinsicContentSize];
    double points = _font ? _font->_size : 17.0;
    int style = _font && _font->_bold ? IOSIM_FONT_BOLD : IOSIM_FONT_REGULAR;
    double scale = [[UIScreen mainScreen] scale];
    char lines[IOSIM_MAX_WRAP_LINES][256];
    int maxLines = _numberOfLines > 1 ? _numberOfLines : IOSIM_MAX_WRAP_LINES;
    int n = wrap_text_lines(text, style, points, scale,
                            (int)(size.width * scale + 0.5), lines, maxLines);
    int ascent = 0, descent = 0, lineHeight = 0;
    iosim_fb_font_metrics(style, points, scale, &ascent, &descent,
                          &lineHeight);
    int maxWidth = 0;
    for (int i = 0; i < n; i++)
    {
        int w = iosim_fb_font_text_width(lines[i], style, points, scale);
        if (w > maxWidth)
            maxWidth = w;
    }
    return CGSizeMake(maxWidth / scale, (double)n * lineHeight / scale);
}
@end

static id g_firstResponder;

/* Editable multiline text view: text is appended at the end, wrapped with
 * spaces preserved, and drawn with a caret while first responder. */
@implementation UITextView
- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        _text = [NSString stringWithUTF8String:""];
        _font = [UIFont systemFontOfSize:17];
        _textColor = [UIColor whiteColor];
        _editable = YES;
    }
    return self;
}
- (id)text { return _text; }
- (void)setText:(id)text { _text = text; }
- (UIFont *)font { return _font; }
- (void)setFont:(UIFont *)font { _font = font; }
- (UIColor *)textColor { return _textColor; }
- (void)setTextColor:(UIColor *)color { _textColor = color; }
- (BOOL)isEditable { return _editable; }
- (void)setEditable:(BOOL)editable { _editable = editable; }
- (BOOL)becomeFirstResponder
{
    if (g_firstResponder && g_firstResponder != self)
        [g_firstResponder resignFirstResponder];
    g_firstResponder = self;
    return YES;
}
- (BOOL)resignFirstResponder
{
    if (g_firstResponder == self)
        g_firstResponder = 0;
    return YES;
}
- (BOOL)isFirstResponder { return g_firstResponder == self; }
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    (void)touches;
    (void)event;
    if (_editable)
        [self becomeFirstResponder];
}
- (void)insertText:(id)text
{
    if (!text)
        return;
    if (_text)
        _text = [_text stringByAppendingString:text];
    else
        _text = text;
}
- (void)deleteBackward
{
    const char *current = _text ? iosim_string_cstr(_text) : "";
    unsigned long length = strlen(current);
    if (length == 0)
        return;
    char *copy = malloc(length);
    if (!copy)
        return;
    memcpy(copy, current, length - 1);
    copy[length - 1] = 0;
    _text = [NSString stringWithUTF8String:copy];
    free(copy);
}
@end

@implementation UITextField
- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        _font = [UIFont systemFontOfSize:17];
        _textColor = [UIColor whiteColor];
        _textAlignment = 0;
        _returnKeyType = 1;
    }
    return self;
}
- (void)setText:(id)text { _text = text; }
- (id)text { return _text; }
- (void)setPlaceholder:(id)text { _placeholder = text; }
- (id)placeholder { return _placeholder; }
- (void)setTextColor:(UIColor *)color { _textColor = color; }
- (UIColor *)textColor { return _textColor; }
- (void)setFont:(UIFont *)font { _font = font; }
- (UIFont *)font { return _font; }
- (void)setTextAlignment:(int)alignment { _textAlignment = alignment; }
- (int)textAlignment { return _textAlignment; }
- (void)setSecureTextEntry:(BOOL)secure { _secureTextEntry = secure; }
- (BOOL)isSecureTextEntry { return _secureTextEntry; }
- (void)setKeyboardType:(int)type { _keyboardType = type; }
- (int)keyboardType { return _keyboardType; }
- (void)setReturnKeyType:(int)type { _returnKeyType = type; }
- (int)returnKeyType { return _returnKeyType; }
- (void)setDelegate:(id)delegate { _delegate = delegate; }
- (id)delegate { return _delegate; }
- (BOOL)becomeFirstResponder
{
    if (g_firstResponder && g_firstResponder != self)
        [g_firstResponder resignFirstResponder];
    g_firstResponder = self;
    _firstResponder = YES;
    _needsLayout = YES;
    return YES;
}
- (BOOL)resignFirstResponder
{
    if (g_firstResponder == self)
        g_firstResponder = 0;
    _firstResponder = NO;
    _needsLayout = YES;
    return YES;
}
- (BOOL)isFirstResponder { return _firstResponder; }
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    [self becomeFirstResponder];
    [super touchesBegan:touches withEvent:event];
}
- (BOOL)hasText
{
    const char *s = iosim_string_cstr(_text);
    return s && *s;
}
- (void)insertText:(id)text
{
    if (!text)
        return;
    const char *add = iosim_string_cstr(text);
    if (!add)
        return;
    char buf[512];
    const char *cur = iosim_string_cstr(_text);
    if (cur)
        snprintf(buf, sizeof(buf), "%s%s", cur, add);
    else
        snprintf(buf, sizeof(buf), "%s", add);
    _text = [NSString stringWithUTF8String:buf];
    [self sendActionsForControlEvents:UIControlEventEditingChanged];
    _needsLayout = YES;
}
- (void)deleteBackward
{
    const char *cur = iosim_string_cstr(_text);
    if (!cur || !*cur)
        return;
    unsigned long n = strlen(cur);
    while (n > 0 && ((unsigned char)cur[n - 1] & 0xc0) == 0x80)
        n--;
    if (n > 0)
        n--;
    char buf[512];
    if (n >= sizeof(buf))
        n = sizeof(buf) - 1;
    memcpy(buf, cur, n);
    buf[n] = 0;
    _text = [NSString stringWithUTF8String:buf];
    [self sendActionsForControlEvents:UIControlEventEditingChanged];
    _needsLayout = YES;
}
- (CGSize)intrinsicContentSize
{
    return CGSizeMake(160, 34);
}
@end


@implementation UISwitch
- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
        _onTintColor = nil;
    return self;
}
- (void)setOn:(BOOL)on animated:(BOOL)animated
{
    (void)animated;
    _on = on;
    _needsLayout = YES;
}
- (BOOL)isOn { return _on; }
- (void)setOnTintColor:(UIColor *)color { _onTintColor = color; }
- (UIColor *)onTintColor { return _onTintColor; }
- (void)sendActionsForControlEvents:(unsigned long)events
{
    if (events & UIControlEventTouchUpInside)
    {
        [self setOn:!_on animated:YES];
        [super sendActionsForControlEvents:UIControlEventValueChanged];
        return;
    }
    [super sendActionsForControlEvents:events];
}
- (void)setOn:(BOOL)on { [self setOn:on animated:NO]; }
- (CGSize)intrinsicContentSize { return CGSizeMake(63, 28); }
@end

@implementation UIActivityIndicatorView
- (id)initWithActivityIndicatorStyle:(long)style
{
    CGRect frame = style == 2 ? CGRectMake(0, 0, 37, 37)
                              : CGRectMake(0, 0, 20, 20);
    self = [super initWithFrame:frame];
    if (self)
    {
        _style = style;
        /* The style supplies the default ink; -color stays nil. */
        _color = nil;
    }
    return self;
}
- (void)startAnimating
{
    if (_animating)
        return;
    _animating = YES;
    animation_mark_active(1.0, -1);
}
- (void)stopAnimating
{
    if (!_animating)
        return;
    _animating = NO;
    animation_unmark_infinite();
}
- (BOOL)isAnimating { return _animating; }
- (void)setColor:(UIColor *)color { _color = color; }
- (UIColor *)color { return _color; }
@end

@implementation UIPageControl
- (void)setNumberOfPages:(long)pages
{
    _numberOfPages = pages;
    _needsLayout = YES;
}
- (long)numberOfPages { return _numberOfPages; }
- (void)setCurrentPage:(long)page
{
    _currentPage = page;
    _needsLayout = YES;
}
- (long)currentPage { return _currentPage; }
- (void)setPageTintColor:(UIColor *)color { _pageTintColor = color; }
- (UIColor *)pageTintColor { return _pageTintColor; }
- (void)setCurrentPageTintColor:(UIColor *)color
{
    _currentPageTintColor = color;
}
- (UIColor *)currentPageTintColor { return _currentPageTintColor; }
- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *touch = [touches anyObject];
    [self selectPageAtPoint:[touch locationInView:self]];
    [super touchesEnded:touches withEvent:event];
}
- (void)selectPageAtPoint:(CGPoint)point
{
    if (_numberOfPages <= 1)
        return;
    double spacing = 17.5;
    double total = (_numberOfPages - 1) * spacing;
    double start = _frame.size.width / 2 - total / 2;
    long page = (long)((point.x - start) / spacing + 0.5);
    if (page < 0) page = 0;
    if (page >= _numberOfPages) page = _numberOfPages - 1;
    if (page != _currentPage)
    {
        _currentPage = page;
        [self sendActionsForControlEvents:UIControlEventValueChanged];
    }
}
- (CGSize)intrinsicContentSize
{
    return CGSizeMake(_numberOfPages * 17.5, 20);
}
@end

@implementation UISegmentedControl
- (id)initWithItems:(NSArray *)items
{
    self = [super initWithFrame:CGRectMake(0, 0, 0, 32)];
    if (self)
    {
        _itemCount = (int)[items count];
        if (_itemCount > 8)
            _itemCount = 8;
        for (int i = 0; i < _itemCount; i++)
            _items[i] = [items objectAtIndex:(unsigned long)i];
        _selectedSegmentIndex = _itemCount > 0 ? 0 : -1;
    }
    return self;
}
- (void)setTitle:(id)title forSegmentAtIndex:(unsigned long)index
{
    if (index < (unsigned long)_itemCount)
        _items[index] = title;
}
- (id)titleForSegmentAtIndex:(unsigned long)index
{
    return index < (unsigned long)_itemCount ? _items[index] : nil;
}
- (void)setSelectedSegmentIndex:(long)index
{
    _selectedSegmentIndex = index;
    _needsLayout = YES;
}
- (long)selectedSegmentIndex { return _selectedSegmentIndex; }
- (void)setTintColor:(UIColor *)color { _tintColor = color; }
- (UIColor *)tintColor { return _tintColor; }
- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *touch = [touches anyObject];
    [self selectSegmentAtPoint:[touch locationInView:self]];
    [super touchesEnded:touches withEvent:event];
}
- (void)selectSegmentAtPoint:(CGPoint)point
{
    if (_itemCount <= 0 || _frame.size.width <= 0)
        return;
    long index = (long)(point.x / (_frame.size.width / _itemCount));
    if (index < 0) index = 0;
    if (index >= _itemCount) index = _itemCount - 1;
    if (index != _selectedSegmentIndex)
    {
        _selectedSegmentIndex = index;
        [self sendActionsForControlEvents:UIControlEventValueChanged];
    }
}
- (CGSize)intrinsicContentSize { return CGSizeMake(240, 32); }
@end

@implementation UISlider
- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        _minimumValue = 0.0;
        _maximumValue = 1.0;
        _value = 0.0;
        /* Default tints come from the current design's glass palette and
         * are resolved by the renderer; the properties stay nil. */
        _minTrackTintColor = nil;
        _maxTrackTintColor = nil;
        _thumbTintColor = nil;
    }
    return self;
}
- (void)setValue:(double)value animated:(BOOL)animated
{
    (void)animated;
    if (value < _minimumValue) value = _minimumValue;
    if (value > _maximumValue) value = _maximumValue;
    _value = value;
    _needsLayout = YES;
}
- (double)value { return _value; }
- (void)setMinimumValue:(double)value { _minimumValue = value; }
- (double)minimumValue { return _minimumValue; }
- (void)setMaximumValue:(double)value { _maximumValue = value; }
- (double)maximumValue { return _maximumValue; }
- (void)setMinimumTrackTintColor:(UIColor *)color
{
    _minTrackTintColor = color;
}
- (UIColor *)minimumTrackTintColor { return _minTrackTintColor; }
- (void)setMaximumTrackTintColor:(UIColor *)color
{
    _maxTrackTintColor = color;
}
- (UIColor *)maximumTrackTintColor { return _maxTrackTintColor; }
- (void)setThumbTintColor:(UIColor *)color { _thumbTintColor = color; }
- (UIColor *)thumbTintColor { return _thumbTintColor; }
- (void)updateValueFromPoint:(CGPoint)point
{
    double span = _maximumValue - _minimumValue;
    double thumb = 36.3333;
    double usable = _frame.size.width - thumb;
    if (usable <= 0)
        return;
    double t = (point.x - thumb / 2) / usable;
    if (t < 0) t = 0;
    if (t > 1) t = 1;
    double value = _minimumValue + span * t;
    if (value == _value)
        return;
    _value = value;
    _needsLayout = YES;
    [self sendActionsForControlEvents:UIControlEventValueChanged];
}
- (void)setValueFromPoint:(CGPoint)point
{
    [self updateValueFromPoint:point];
}
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *touch = [touches anyObject];
    [self updateValueFromPoint:[touch locationInView:self]];
    [super touchesBegan:touches withEvent:event];
}
- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *touch = [touches anyObject];
    [self updateValueFromPoint:[touch locationInView:self]];
    [super touchesMoved:touches withEvent:event];
}
- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *touch = [touches anyObject];
    [self updateValueFromPoint:[touch locationInView:self]];
    [super touchesEnded:touches withEvent:event];
}
- (CGSize)intrinsicContentSize
{
    return CGSizeMake(_frame.size.width, 31);
}
@end

@implementation UIProgressView
- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        _trackTintColor = nil;
        _progressTintColor = nil;
    }
    return self;
}
- (void)setProgress:(double)progress animated:(BOOL)animated
{
    (void)animated;
    if (progress < 0) progress = 0;
    if (progress > 1) progress = 1;
    _progress = progress;
    _needsLayout = YES;
}
- (double)progress { return _progress; }
- (void)setProgressTintColor:(UIColor *)color { _progressTintColor = color; }
- (UIColor *)progressTintColor { return _progressTintColor; }
- (void)setTrackTintColor:(UIColor *)color { _trackTintColor = color; }
- (UIColor *)trackTintColor { return _trackTintColor; }
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
- (id)title { return _title; }
- (void)setTitle:(id)title
{
    _title = title;
    UINavigationController *nav = (UINavigationController *)_navigationController;
    if (nav && nav->_navTitleLabel)
        nav->_navTitleLabel->_text = title;
}
- (id)navigationController { return _navigationController; }
- (id)tabBarItem
{
    if (!_tabBarItem)
        _tabBarItem = [[UITabBarItem alloc] initWithTitle:_title image:nil
                                                       tag:0];
    return _tabBarItem;
}
- (void)setTabBarItem:(id)item { _tabBarItem = item; }
- (id)navigationItem
{
    if (!_navigationItem)
        _navigationItem = [[UINavigationItem alloc] initWithTitle:_title];
    return _navigationItem;
}
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
- (void)viewWillAppear:(BOOL)animated { (void)animated; }
- (void)viewDidAppear:(BOOL)animated { (void)animated; }
- (void)viewWillDisappear:(BOOL)animated { (void)animated; }
- (void)viewDidDisappear:(BOOL)animated { (void)animated; }
- (void)viewWillLayoutSubviews { }
- (void)viewDidLayoutSubviews { }
- (void)viewDidLoad
{
}
- (void)presentViewController:(UIViewController *)controller animated:(BOOL)animated
                   completion:(void (^)(void))completion
{
    (void)animated;
    if (!controller)
        return;
    _presentedController = controller;
    (void)[controller view];
    [controller viewWillAppear:animated];
    [controller viewDidAppear:animated];
    if (completion)
        completion();
}
- (void)dismissViewControllerAnimated:(BOOL)animated
                           completion:(void (^)(void))completion
{
    (void)animated;
    UIViewController *controller = (UIViewController *)_presentedController;
    if (controller)
    {
        [controller viewWillDisappear:animated];
        [controller viewDidDisappear:animated];
    }
    _presentedController = nil;
    if (completion)
        completion();
}
- (UIViewController *)presentedViewController
{
    return (UIViewController *)_presentedController;
}
@end


/* ------------------------------------------------------------- alerts */

@implementation UIAlertAction
+ (id)actionWithTitle:(id)title style:(long)style
              handler:(void (^)(UIAlertAction *action))handler
{
    UIAlertAction *action = [[self alloc] init];
    action->_title = title;
    action->_style = style;
    if (handler)
        action->_handler = (void (^)(UIAlertAction *))_Block_copy(handler);
    return action;
}
- (id)title { return _title; }
- (long)style { return _style; }
- (void (^)(UIAlertAction *))handler { return _handler; }
@end

@implementation UIAlertController
+ (id)alertControllerWithTitle:(id)title message:(id)message
                 preferredStyle:(long)style
{
    UIAlertController *alert = [[self alloc] init];
    alert->_title = title;
    alert->_message = message;
    alert->_preferredStyle = style;
    return alert;
}
- (void)addAction:(UIAlertAction *)action
{
    if (action && _actionCount < 8)
        _actions[_actionCount++] = action;
}
- (id)message { return _message; }
- (long)preferredStyle { return _preferredStyle; }
- (NSArray *)actions
{
    return [NSArray arrayWithObjects:_actions
                                count:(unsigned long)_actionCount];
}
@end

/* --------------------------------------------------------- stack views */

@implementation UIStackView
- (id)init
{
    self = [super initWithFrame:CGRectMake(0, 0, 0, 0)];
    if (self)
    {
        _axis = 0;
        _spacing = 0;
        _distribution = 0;
        _alignment = 0;
        _needsLayout = YES;
    }
    return self;
}
- (id)initWithArrangedSubviews:(NSArray *)views
{
    self = [self init];
    if (self && views)
        for (unsigned long i = 0; i < [views count] && _arrangedCount < 32; i++)
            [self addArrangedSubview:[views objectAtIndex:i]];
    return self;
}
- (void)addArrangedSubview:(UIView *)view
{
    if (!view)
        return;
    [self addSubview:view];
    if (_arrangedCount < 32)
        _arranged[_arrangedCount++] = view;
    _needsLayout = YES;
}
- (void)removeArrangedSubview:(UIView *)view
{
    for (int i = 0; i < _arrangedCount; i++)
        if (_arranged[i] == view)
        {
            for (int j = i; j + 1 < _arrangedCount; j++)
                _arranged[j] = _arranged[j + 1];
            _arrangedCount--;
            break;
        }
    _needsLayout = YES;
}
- (NSArray *)arrangedSubviews
{
    NSMutableArray *a = [NSMutableArray array];
    for (int i = 0; i < _arrangedCount; i++)
        [a addObject:_arranged[i]];
    return a;
}
- (void)setAxis:(long)axis { _axis = axis; _needsLayout = YES; }
- (long)axis { return _axis; }
- (void)setSpacing:(double)spacing { _spacing = spacing; _needsLayout = YES; }
- (double)spacing { return _spacing; }
- (void)setDistribution:(long)distribution { _distribution = distribution; _needsLayout = YES; }
- (long)distribution { return _distribution; }
- (void)setAlignment:(long)alignment { _alignment = alignment; _needsLayout = YES; }
- (long)alignment { return _alignment; }
- (void)layoutSubviews
{
    if (_arrangedCount == 0)
        return;
    double W = _frame.size.width, H = _frame.size.height;
    double totalSpacing = _spacing * (_arrangedCount - 1);
    if (_axis == 1)
    {
        double equal = _distribution == 1
                           ? (H - totalSpacing) / _arrangedCount : 0;
        double y = 0;
        for (int i = 0; i < _arrangedCount; i++)
        {
            UIView *v = _arranged[i];
            CGSize intrinsic = [v respondsToSelector:@selector(intrinsicContentSize)]
                                   ? [v intrinsicContentSize] : CGSizeMake(0, 0);
            double h = equal > 0 ? equal
                                 : (v->_frame.size.height > 0
                                        ? v->_frame.size.height : intrinsic.height);
            if (h <= 0) h = 44;
            double w = v->_frame.size.width > 0 ? v->_frame.size.width : W;
            double x = 0;
            if (_alignment == 2) x = (W - w) / 2;
            else if (_alignment == 3) x = W - w;
            [v setFrame:CGRectMake(x, y, w, h)];
            [v setNeedsLayout];
            [v layoutIfNeeded];
            y += h + _spacing;
        }
    }
    else
    {
        double equal = _distribution == 1
                           ? (W - totalSpacing) / _arrangedCount : 0;
        double x = 0;
        for (int i = 0; i < _arrangedCount; i++)
        {
            UIView *v = _arranged[i];
            CGSize intrinsic = [v respondsToSelector:@selector(intrinsicContentSize)]
                                   ? [v intrinsicContentSize] : CGSizeMake(0, 0);
            double w = equal > 0 ? equal
                                 : (v->_frame.size.width > 0
                                        ? v->_frame.size.width : intrinsic.width);
            if (w <= 0) w = 80;
            double h = v->_frame.size.height > 0 ? v->_frame.size.height : H;
            double y = 0;
            if (_alignment == 2) y = (H - h) / 2;
            else if (_alignment == 3) y = H - h;
            [v setFrame:CGRectMake(x, y, w, h)];
            [v setNeedsLayout];
            [v layoutIfNeeded];
            x += w + _spacing;
        }
    }
}
@end

/* ----------------------------------------------------- navigation stack */

static id bar_system_title(long item)
{
    switch (item)
    {
    case UIBarButtonSystemItemDone: return @"Done";
    case UIBarButtonSystemItemCancel: return @"Cancel";
    case UIBarButtonSystemItemEdit: return @"Edit";
    case UIBarButtonSystemItemSave: return @"Save";
    case UIBarButtonSystemItemAdd: return @"+";
    case UIBarButtonSystemItemCompose: return @"Compose";
    case UIBarButtonSystemItemReply: return @"Reply";
    case UIBarButtonSystemItemSearch: return @"Search";
    case UIBarButtonSystemItemClose: return @"Close";
    }
    return @"";
}

@implementation UIBarButtonItem
- (id)initWithTitle:(id)title style:(long)style target:(id)target
             action:(SEL)action
{
    self = [super init];
    if (self)
    {
        _title = title;
        _style = style;
        _target = target;
        _action = action;
        _enabled = YES;
    }
    return self;
}
- (id)initWithBarButtonSystemItem:(long)item target:(id)target
                           action:(SEL)action
{
    return [self initWithTitle:bar_system_title(item) style:UIBarButtonItemStylePlain
                        target:target action:action];
}
- (id)title { return _title; }
- (void)setTitle:(id)title { _title = title; }
- (long)style { return _style; }
- (void)setStyle:(long)style { _style = style; }
- (long)systemItem { return _systemItem; }
- (id)target { return _target; }
- (SEL)action { return _action; }
- (void)setEnabled:(BOOL)enabled { _enabled = enabled; }
- (BOOL)isEnabled { return _enabled; }
@end

@implementation UINavigationItem
- (id)init { return [super init]; }
- (id)initWithTitle:(id)title
{
    self = [super init];
    if (self)
        _title = title;
    return self;
}
- (id)title { return _title; }
- (void)setTitle:(id)title { _title = title; }
- (id)leftBarButtonItem { return _leftBarButtonItem; }
- (void)setLeftBarButtonItem:(id)item { _leftBarButtonItem = item; }
- (id)rightBarButtonItem { return _rightBarButtonItem; }
- (void)setRightBarButtonItem:(id)item { _rightBarButtonItem = item; }
- (id)backBarButtonItem { return _backBarButtonItem; }
- (void)setBackBarButtonItem:(id)item { _backBarButtonItem = item; }
- (BOOL)hidesBackButton { return _hidesBackButton; }
- (void)setHidesBackButton:(BOOL)hidden { _hidesBackButton = hidden; }
@end

static UIControl *nav_bar_control(UIBarButtonItem *item, CGRect frame,
                                  int alignRight)
{
    UIControl *control = [[UIControl alloc] initWithFrame:frame];
    UILabel *label = [[UILabel alloc]
        initWithFrame:CGRectMake(0, 0, frame.size.width, frame.size.height)];
    label->_text = item ? item->_title : @"";
    label->_font = [UIFont systemFontOfSize:17];
    label->_textColor = [UIColor colorWithRed:0.04 green:0.52 blue:1.0
                                          alpha:1.0];
    label->_textAlignment = alignRight ? 2 : 0;
    [control addSubview:label];
    if (item)
        [control addTarget:item->_target action:item->_action
         forControlEvents:UIControlEventTouchUpInside];
    return control;
}

@implementation UINavigationController
- (id)initWithRootViewController:(UIViewController *)root
{
    self = [super init];
    if (self && root)
    {
        _stack[0] = root;
        _stackCount = 1;
        _viewLoaded = NO;
        root->_navigationController = self;
    }
    return self;
}
- (UIViewController *)topViewController
{
    return _stackCount > 0 ? (UIViewController *)_stack[_stackCount - 1] : nil;
}
- (NSArray *)viewControllers
{
    NSMutableArray *a = [NSMutableArray array];
    for (int i = 0; i < _stackCount; i++)
        [a addObject:_stack[i]];
    return a;
}
- (void)loadView
{
    _view = [[UIView alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
}
- (void)viewDidLoad
{
    if (_view)
    {
        CGRect bounds = [[UIScreen mainScreen] bounds];
        unsigned color = 0x05070d;
        _view->_backgroundColor = [UIColor colorWithRed:0.02 green:0.03 blue:0.05
                                                  alpha:1.0];
        _navBar = [[UIView alloc] initWithFrame:CGRectMake(0, 0, bounds.size.width,
                                                          100)];
        _navBar->_backgroundColor = [UIColor colorWithRed:0.04 green:0.055
                                                    blue:0.10 alpha:1.0];
        [_view addSubview:_navBar];
        _navTitleLabel = [[UILabel alloc]
            initWithFrame:CGRectMake(60, 45, bounds.size.width - 120, 30)];
        _navTitleLabel->_textAlignment = 1;
        _navTitleLabel->_font = [UIFont systemFontOfSize:17];
        _navTitleLabel->_textColor = [UIColor whiteColor];
        [_navBar addSubview:_navTitleLabel];
        (void)color;
        [self installTopViewController];
    }
}
- (void)installTopViewController
{
    UIViewController *top = [self topViewController];
    if (!top || !_view)
        return;
    if (_contentView)
        [_contentView removeFromSuperview];
    double navHeight = _navBarHidden ? 0 : 100;
    CGRect bounds = _view->_frame;
    UIView *content = [top view];
    content->_frame = CGRectMake(0, navHeight, bounds.size.width,
                                 bounds.size.height - navHeight);
    [_view addSubview:content];
    _contentView = content;

    UINavigationItem *item = (UINavigationItem *)[top navigationItem];
    id title = (item && item->_title) ? item->_title : top->_title;
    _navTitleLabel->_text = title;

    if (_leftButton)
        [(UIView *)_leftButton removeFromSuperview];
    if (_rightButton)
        [(UIView *)_rightButton removeFromSuperview];
    _leftButton = nil;
    _rightButton = nil;

    double width = bounds.size.width;
    UIBarButtonItem *leftItem =
        item ? (UIBarButtonItem *)item->_leftBarButtonItem : nil;
    if (_stackCount > 1 && (!item || !item->_hidesBackButton))
    {
        UIViewController *previous = _stack[_stackCount - 2];
        id previousTitle = previous->_title;
        UINavigationItem *previousItem =
            (UINavigationItem *)[previous navigationItem];
        if (previousItem && previousItem->_title)
            previousTitle = previousItem->_title;
        char backLabel[160];
        snprintf(backLabel, sizeof(backLabel), "\xe2\x80\xb9 %s",
                 iosim_string_cstr(previousTitle));
        UIBarButtonItem *back = [[UIBarButtonItem alloc]
            initWithTitle:[NSString stringWithUTF8String:backLabel]
                    style:UIBarButtonItemStylePlain
                   target:self
                   action:@selector(navBackTapped:)];
        _leftButton = nav_bar_control(back, CGRectMake(8, 50, 160, 36), 0);
    }
    else if (leftItem)
        _leftButton = nav_bar_control(leftItem, CGRectMake(8, 50, 140, 36),
                                      0);
    if (_leftButton)
        [_navBar addSubview:(UIView *)_leftButton];
    if (item && item->_rightBarButtonItem)
    {
        _rightButton = nav_bar_control(
            (UIBarButtonItem *)item->_rightBarButtonItem,
            CGRectMake(width - 148, 50, 140, 36), 1);
        [_navBar addSubview:(UIView *)_rightButton];
    }
    _view->_needsLayout = YES;
}
- (void)navBackTapped:(id)sender
{
    (void)sender;
    [self popViewControllerAnimated:YES];
}
- (void)pushViewController:(UIViewController *)controller animated:(BOOL)animated
{
    (void)animated;
    if (!controller || _stackCount >= 32)
        return;
    UIViewController *old = [self topViewController];
    if (old)
    {
        [old viewWillDisappear:NO];
        [old viewDidDisappear:NO];
    }
    controller->_navigationController = self;
    _stack[_stackCount++] = controller;
    [self installTopViewController];
    [controller viewWillAppear:NO];
    [controller viewDidAppear:NO];
}
- (UIViewController *)popViewControllerAnimated:(BOOL)animated
{
    (void)animated;
    if (_stackCount <= 1)
        return nil;
    UIViewController *old = [self topViewController];
    [old viewWillDisappear:NO];
    [old viewDidDisappear:NO];
    _stackCount--;
    UIViewController *top = [self topViewController];
    [self installTopViewController];
    [top viewWillAppear:NO];
    [top viewDidAppear:NO];
    return old;
}
- (void)setNavigationBarHidden:(BOOL)hidden animated:(BOOL)animated
{
    (void)animated;
    _navBarHidden = hidden;
    _navBar->_hidden = hidden;
    if (_contentView && _view)
    {
        double navHeight = hidden ? 0 : 100;
        CGRect bounds = _view->_frame;
        _contentView->_frame = CGRectMake(0, navHeight, bounds.size.width,
                                          bounds.size.height - navHeight);
    }
}
- (BOOL)isNavigationBarHidden { return _navBarHidden; }
@end

@implementation UITabBarItem
- (id)initWithTitle:(id)title image:(id)image tag:(long)tag
{
    self = [super init];
    if (self)
    {
        _title = title;
        _image = image;
        _tag = tag;
    }
    return self;
}
- (id)title { return _title; }
- (void)setTitle:(id)title { _title = title; }
- (id)image { return _image; }
- (long)tag { return _tag; }
@end

@implementation UITabBarController
- (id)init
{
    self = [super init];
    if (self)
        _selectedIndex = 0;
    return self;
}
- (void)setViewControllers:(NSArray *)controllers
{
    int count = controllers ? (int)[controllers count] : 0;
    if (count > 16)
        count = 16;
    for (int i = 0; i < count; i++)
        _tabControllers[i] = [controllers objectAtIndex:(unsigned long)i];
    for (int i = count; i < _tabCount; i++)
        _tabControllers[i] = nil;
    _tabCount = count;
    if (_selectedIndex >= count)
        _selectedIndex = count > 0 ? count - 1 : 0;
    if (_view)
        [self buildTabBar];
}
- (NSArray *)viewControllers
{
    NSMutableArray *list = [NSMutableArray array];
    for (int i = 0; i < _tabCount; i++)
        [list addObject:_tabControllers[i]];
    return list;
}
- (void)loadView
{
    _view = [[UIView alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
}
- (void)viewDidLoad
{
    if (!_view)
        return;
    _view->_backgroundColor =
        [UIColor colorWithRed:0.02 green:0.03 blue:0.05 alpha:1.0];
    [self buildTabBar];
}
- (void)buildTabBar
{
    if (!_view || _tabCount <= 0)
        return;
    if (_tabBar)
        [_tabBar removeFromSuperview];
    CGRect bounds = [[UIScreen mainScreen] bounds];
    double screenW = bounds.size.width, screenH = bounds.size.height;
    double barHeight = 64.0;
    double margin = 16.0;
    double barY = screenH - 34.0 - 12.0 - barHeight;
    _tabBar = [[UIView alloc] initWithFrame:CGRectMake(margin, barY,
                                                       screenW - margin * 2,
                                                       barHeight)];
    _tabBar->_backgroundColor =
        [UIColor colorWithRed:0.10 green:0.12 blue:0.18 alpha:0.94];
    [_tabBar.layer setCornerRadius:barHeight / 2.0];
    [_view addSubview:_tabBar];
    double slot = (screenW - margin * 2) / (double)_tabCount;
    for (int i = 0; i < _tabCount; i++)
    {
        UIViewController *controller = (UIViewController *)_tabControllers[i];
        UITabBarItem *item = (UITabBarItem *)[controller tabBarItem];
        UIControl *control = [[UIControl alloc]
            initWithFrame:CGRectMake(slot * i, 0, slot, barHeight)];
        [control addTarget:self action:@selector(tabItemTapped:)
          forControlEvents:UIControlEventTouchUpInside];
        double textY = 22.0;
        if (item && item->_image)
        {
            UIImageView *icon = [[UIImageView alloc] initWithImage:item->_image];
            icon->_frame = CGRectMake((slot - 24.0) / 2.0, 10.0, 24.0, 24.0);
            [control addSubview:icon];
            textY = 38.0;
        }
        UILabel *label =
            [[UILabel alloc] initWithFrame:CGRectMake(0, textY, slot, 16.0)];
        label->_text = item ? item->_title : nil;
        label->_textAlignment = 1;
        label->_font = [UIFont systemFontOfSize:12];
        label->_textColor =
            i == _selectedIndex
                ? [UIColor whiteColor]
                : [UIColor colorWithRed:0.55 green:0.57 blue:0.62 alpha:1.0];
        [control addSubview:label];
        [_tabBar addSubview:control];
        _tabItemViews[i] = control;
        _tabItemLabels[i] = label;
    }
    [self installSelectedViewController];
    [self updateTabAppearance];
}
- (void)updateTabAppearance
{
    for (int i = 0; i < _tabCount; i++)
    {
        UILabel *label = (UILabel *)_tabItemLabels[i];
        if (!label)
            continue;
        label->_textColor =
            i == _selectedIndex
                ? [UIColor whiteColor]
                : [UIColor colorWithRed:0.55 green:0.57 blue:0.62 alpha:1.0];
    }
    if (_view)
        _view->_needsLayout = YES;
}
- (void)installSelectedViewController
{
    if (!_view)
        return;
    UIViewController *selected = [self selectedViewController];
    if (!selected)
        return;
    if (_tabContent)
    {
        [_tabContent removeFromSuperview];
        _tabContent = nil;
    }
    CGRect bounds = [[UIScreen mainScreen] bounds];
    UIView *content = [selected view];
    content->_frame = CGRectMake(0, 0, bounds.size.width, bounds.size.height);
    [_view insertSubview:content atIndex:0];
    _tabContent = content;
}
- (void)tabItemTapped:(id)sender
{
    for (int i = 0; i < _tabCount; i++)
    {
        if (_tabItemViews[i] != sender)
            continue;
        [self setSelectedIndex:i];
        return;
    }
}
- (void)setSelectedIndex:(int)index
{
    if (index < 0)
        index = 0;
    if (index >= _tabCount)
        index = _tabCount > 0 ? _tabCount - 1 : 0;
    if (index == _selectedIndex && _tabContent)
    {
        [self updateTabAppearance];
        return;
    }
    UIViewController *old = [self selectedViewController];
    if (old)
    {
        [old viewWillDisappear:NO];
        [old viewDidDisappear:NO];
    }
    _selectedIndex = index;
    UIViewController *selected = [self selectedViewController];
    if (selected)
    {
        [selected viewWillAppear:NO];
        [self installSelectedViewController];
        [selected viewDidAppear:NO];
    }
    printf("[tab] selected %d\n", _selectedIndex);
    fflush(0);
    [self updateTabAppearance];
}
- (int)selectedIndex { return _selectedIndex; }
- (UIViewController *)selectedViewController
{
    return _tabCount > 0
               ? (UIViewController *)_tabControllers[_selectedIndex]
               : nil;
}
- (void)setSelectedViewController:(UIViewController *)controller
{
    for (int i = 0; i < _tabCount; i++)
        if (_tabControllers[i] == controller)
        {
            [self setSelectedIndex:i];
            return;
        }
}
@end

@implementation UIControl
- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
        _enabled = YES;
    return self;
}
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
- (BOOL)isHighlighted { return _highlighted; }
- (void)setHighlighted:(BOOL)highlighted { _highlighted = highlighted; }
- (BOOL)isEnabled { return _enabled; }
- (void)setEnabled:(BOOL)enabled { _enabled = enabled; }
- (BOOL)isSelected { return _selected; }
- (void)setSelected:(BOOL)selected { _selected = selected; }
- (unsigned long)state
{
    unsigned long state = UIControlStateNormal;
    if (_highlighted)
        state |= UIControlStateHighlighted;
    if (!_enabled)
        state |= UIControlStateDisabled;
    if (_selected)
        state |= UIControlStateSelected;
    return state;
}
- (BOOL)beginTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event
{
    (void)touch;
    (void)event;
    return YES;
}
- (BOOL)continueTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event
{
    (void)touch;
    (void)event;
    return YES;
}
- (void)endTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event
{
    (void)touch;
    (void)event;
}
- (void)cancelTrackingWithEvent:(UIEvent *)event { (void)event; }
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    if (!_enabled)
    {
        [super touchesBegan:touches withEvent:event];
        return;
    }
    UITouch *touch = [touches anyObject];
    _tracking = YES;
    _touchInside = 1;
    _highlighted = YES;
    [self beginTrackingWithTouch:touch withEvent:event];
    [self sendActionsForControlEvents:UIControlEventTouchDown];
}
- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    if (!_tracking)
    {
        [super touchesMoved:touches withEvent:event];
        return;
    }
    UITouch *touch = [touches anyObject];
    int inside = [self pointInside:[touch locationInView:self]];
    _highlighted = inside ? YES : NO;
    if (inside && !_touchInside)
        [self sendActionsForControlEvents:UIControlEventTouchDragEnter |
                                         UIControlEventTouchDragInside];
    else if (inside)
        [self sendActionsForControlEvents:UIControlEventTouchDragInside];
    else if (_touchInside)
        [self sendActionsForControlEvents:UIControlEventTouchDragExit |
                                         UIControlEventTouchDragOutside];
    else
        [self sendActionsForControlEvents:UIControlEventTouchDragOutside];
    _touchInside = inside;
    [self continueTrackingWithTouch:touch withEvent:event];
}
- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    if (!_tracking)
    {
        [super touchesEnded:touches withEvent:event];
        return;
    }
    UITouch *touch = [touches anyObject];
    int inside = [self pointInside:[touch locationInView:self]];
    _tracking = NO;
    _highlighted = NO;
    [self endTrackingWithTouch:touch withEvent:event];
    if (!_enabled)
        return;
    [self sendActionsForControlEvents:inside ? UIControlEventTouchUpInside
                                             : UIControlEventTouchUpOutside];
}
- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    _tracking = NO;
    _highlighted = NO;
    [self cancelTrackingWithEvent:event];
    if (_enabled)
        [self sendActionsForControlEvents:UIControlEventTouchCancel];
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
- (UILabel *)titleLabel { return _titleLabel; }
- (void)setTitleColor:(UIColor *)color forState:(unsigned long)state
{
    (void)state;
    _titleColor = color;
    _titleLabel->_textColor = color;
}
- (CGSize)intrinsicContentSize
{
    CGSize titleSize = _titleLabel ? [_titleLabel intrinsicContentSize]
                                   : CGSizeMake(80, 22);
    return CGSizeMake(titleSize.width + 32, 44);
}
@end


@implementation UIScrollView
- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        _clipsToBounds = YES;
        _scrollEnabled = YES;
        _showsVerticalScrollIndicator = YES;
        _bounces = YES;
    }
    return self;
}
- (CGSize)contentSize { return _contentSize; }
- (void)setDelegate:(id)delegate { _delegate = delegate; }
- (id)delegate { return _delegate; }
- (void)setContentSize:(CGSize)size { _contentSize = size; }
- (CGPoint)contentOffset { return _contentOffset; }
- (void)setContentOffset:(CGPoint)offset { _contentOffset = offset; }
- (void)setContentOffset:(CGPoint)offset animated:(BOOL)animated
{
    (void)animated;
    _contentOffset = offset;
}
- (BOOL)isScrollEnabled { return _scrollEnabled; }
- (void)setScrollEnabled:(BOOL)enabled { _scrollEnabled = enabled; }
- (BOOL)showsVerticalScrollIndicator { return _showsVerticalScrollIndicator; }
- (void)setShowsVerticalScrollIndicator:(BOOL)shows
{ _showsVerticalScrollIndicator = shows; }
@end

/* ------------------------------------------------------------ table views */

static long table_sections(UITableView *table)
{
    if (table->_dataSource &&
        [table->_dataSource respondsToSelector:
            @selector(numberOfSectionsInTableView:)])
    {
        SEL sel = @selector(numberOfSectionsInTableView:);
        return ((long (*)(id, void *, id))objc_msgSend)(
            table->_dataSource, (void *)sel, table);
    }
    return 1;
}

static long table_rows(UITableView *table, long section)
{
    if (table->_dataSource &&
        [table->_dataSource respondsToSelector:
            @selector(tableView:numberOfRowsInSection:)])
    {
        SEL sel = @selector(tableView:numberOfRowsInSection:);
        return ((long (*)(id, void *, id, long))objc_msgSend)(
            table->_dataSource, (void *)sel, table, section);
    }
    return 0;
}

static id table_header_title(UITableView *table, long section)
{
    if (table->_delegate &&
        [table->_delegate respondsToSelector:
            @selector(tableView:titleForHeaderInSection:)])
    {
        SEL sel = @selector(tableView:titleForHeaderInSection:);
        return ((id (*)(id, void *, id, long))objc_msgSend)(
            table->_delegate, (void *)sel, table, section);
    }
    return nil;
}

static double table_header_height(UITableView *table, long section)
{
    id title = table_header_title(table, section);
    if (!title)
        return 0;
    if (table->_delegate &&
        [table->_delegate respondsToSelector:
            @selector(tableView:heightForHeaderInSection:)])
    {
        SEL sel = @selector(tableView:heightForHeaderInSection:);
        double height = ((double (*)(id, void *, id, long))objc_msgSend)(
            table->_delegate, (void *)sel, table, section);
        if (height > 0)
            return height;
    }
    return table->_style == UITableViewStyleGrouped ? 32.0 : 28.0;
}

static double table_row_height(UITableView *table, NSIndexPath *path)
{
    if (table->_delegate &&
        [table->_delegate respondsToSelector:
            @selector(tableView:heightForRowAtIndexPath:)])
    {
        SEL sel = @selector(tableView:heightForRowAtIndexPath:);
        double height = ((double (*)(id, void *, id, id))objc_msgSend)(
            table->_delegate, (void *)sel, table, path);
        if (height > 0)
            return height;
    }
    return table->_rowHeight;
}

static double table_total_height(UITableView *table)
{
    double total = 0;
    long sections = table_sections(table);
    for (long s = 0; s < sections; s++)
    {
        total += table_header_height(table, s);
        long rows = table_rows(table, s);
        for (long r = 0; r < rows; r++)
            total += table_row_height(
                table, [NSIndexPath indexPathForRow:r inSection:s]);
    }
    return total;
}

@implementation UITableViewCell
- (id)initWithStyle:(long)style reuseIdentifier:(id)reuseIdentifier
{
    self = [super initWithFrame:CGRectMake(0, 0, 0, 0)];
    if (self)
    {
        _style = style;
        _reuseIdentifier = reuseIdentifier;
        _selectionStyle = UITableViewCellSelectionStyleGray;
        _textLabel = [[UILabel alloc] initWithFrame:CGRectMake(16, 0, 200, 22)];
        _textLabel->_font = [UIFont systemFontOfSize:17];
        _textLabel->_textColor = [UIColor whiteColor];
        [self addSubview:_textLabel];
        if (style == UITableViewCellStyleSubtitle ||
            style == UITableViewCellStyleValue1 ||
            style == UITableViewCellStyleValue2)
        {
            _detailTextLabel =
                [[UILabel alloc] initWithFrame:CGRectMake(16, 22, 200, 18)];
            _detailTextLabel->_font = [UIFont systemFontOfSize:15];
            _detailTextLabel->_textColor =
                [UIColor colorWithRed:0.55 green:0.58 blue:0.64 alpha:1.0];
            [self addSubview:_detailTextLabel];
        }
    }
    return self;
}
- (UILabel *)textLabel { return _textLabel; }
- (UILabel *)detailTextLabel { return _detailTextLabel; }
- (UIImageView *)imageView { return _imageView; }
- (UIView *)contentView { return self; }
- (id)reuseIdentifier { return _reuseIdentifier; }
- (void)setAccessoryType:(long)type { _accessoryType = type; }
- (long)accessoryType { return _accessoryType; }
- (void)setSelectionStyle:(long)style { _selectionStyle = style; }
- (long)selectionStyle { return _selectionStyle; }
- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    (void)animated;
    _selected = selected;
}
- (BOOL)isSelected { return _selected; }
- (void)setHighlighted:(BOOL)highlighted animated:(BOOL)animated
{
    (void)highlighted; (void)animated;
}
- (void)prepareForReuse { }
- (void)setFrame:(CGRect)frame
{
    [super setFrame:frame];
    double w = frame.size.width;
    if (_style == UITableViewCellStyleSubtitle ||
        _style == UITableViewCellStyleValue1 ||
        _style == UITableViewCellStyleValue2)
    {
        _textLabel->_frame = CGRectMake(16, 8, w - 76, 22);
        if (_detailTextLabel)
            _detailTextLabel->_frame = CGRectMake(16, 30, w - 76, 18);
    }
    else
    {
        _textLabel->_frame = CGRectMake(16, (frame.size.height - 22) / 2,
                                        w - 76, 22);
    }
}
@end

@implementation UITableView
- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        _rowHeight = 44.0;
        _selectedRow = -1;
        _selectedSection = -1;
    }
    return self;
}
- (id)initWithFrame:(CGRect)frame style:(long)style
{
    self = [self initWithFrame:frame];
    if (self)
        _style = style;
    return self;
}
- (void)updateContentSize
{
    _contentSize = CGSizeMake(_frame.size.width, table_total_height(self));
}
- (void)setDataSource:(id)dataSource
{
    _dataSource = dataSource;
    [self updateContentSize];
}
- (id)dataSource { return _dataSource; }
- (void)setDelegate:(id)delegate { _delegate = delegate; }
- (id)delegate { return _delegate; }
- (void)setRowHeight:(double)height
{
    _rowHeight = height;
    [self updateContentSize];
}
- (double)rowHeight { return _rowHeight; }
- (void)reloadData
{
    _needsReload = NO;
    [self updateContentSize];
}
- (id)dequeueReusableCellWithIdentifier:(id)identifier
{
    (void)identifier;
    return nil;
}
- (void)handleTapAtPoint:(CGPoint)point
{
    if (point.y < 0)
        return;
    double cursor = 0;
    long sections = table_sections(self);
    for (long s = 0; s < sections; s++)
    {
        cursor += table_header_height(self, s);
        long rows = table_rows(self, s);
        for (long r = 0; r < rows; r++)
        {
            NSIndexPath *path = [NSIndexPath indexPathForRow:r inSection:s];
            double height = table_row_height(self, path);
            if (point.y >= cursor && point.y < cursor + height)
            {
                _selectedSection = s;
                _selectedRow = r;
                if (_delegate &&
                    [_delegate respondsToSelector:
                        @selector(tableView:didSelectRowAtIndexPath:)])
                    [_delegate tableView:self didSelectRowAtIndexPath:path];
                return;
            }
            cursor += height;
        }
    }
}
@end

/* ------------------------------------------------------ collection views */

@implementation UICollectionViewLayout
@end

@implementation UICollectionViewFlowLayout
- (id)init
{
    self = [super init];
    if (self)
    {
        _itemSize = CGSizeMake(50, 50);
        _minimumInteritemSpacing = 10.0;
        _minimumLineSpacing = 10.0;
        _sectionInset = UIEdgeInsetsMake(0, 0, 0, 0);
        _scrollDirection = UICollectionViewScrollDirectionVertical;
    }
    return self;
}
- (CGSize)itemSize { return _itemSize; }
- (void)setItemSize:(CGSize)size { _itemSize = size; }
- (double)minimumInteritemSpacing { return _minimumInteritemSpacing; }
- (void)setMinimumInteritemSpacing:(double)spacing
{
    _minimumInteritemSpacing = spacing;
}
- (double)minimumLineSpacing { return _minimumLineSpacing; }
- (void)setMinimumLineSpacing:(double)spacing
{
    _minimumLineSpacing = spacing;
}
- (UIEdgeInsets)sectionInset { return _sectionInset; }
- (void)setSectionInset:(UIEdgeInsets)insets { _sectionInset = insets; }
- (long)scrollDirection { return _scrollDirection; }
- (void)setScrollDirection:(long)direction { _scrollDirection = direction; }
@end

@implementation UICollectionViewCell
- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        _contentView = [[UIView alloc] initWithFrame:
            CGRectMake(0, 0, frame.size.width, frame.size.height)];
        [(UIView *)_contentView setBackgroundColor:[UIColor clearColor]];
        [self addSubview:(UIView *)_contentView];
    }
    return self;
}
- (UIView *)contentView { return (UIView *)_contentView; }
- (id)reuseIdentifier { return _reuseIdentifier; }
- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    (void)animated;
    _selected = selected;
    UIView *content = (UIView *)_contentView;
    CALayer *layer = content ? [content layer] : 0;
    if (layer)
    {
        layer->_borderWidth = selected ? 3.0 : 0.0;
        layer->_borderColor =
            selected ? [UIColor colorWithRed:0.04 green:0.52 blue:1.0
                                       alpha:1.0]
                     : 0;
    }
}
- (BOOL)isSelected { return _selected; }
- (void)prepareForReuse
{
    _selected = NO;
    if (_contentView)
        [(UIView *)_contentView setBackgroundColor:[UIColor clearColor]];
}
- (void)setFrame:(CGRect)frame
{
    [super setFrame:frame];
    if (_contentView)
        [(UIView *)_contentView setFrame:
            CGRectMake(0, 0, frame.size.width, frame.size.height)];
}
@end

static long collection_count(UICollectionView *collectionView)
{
    if (collectionView->_dataSource &&
        [collectionView->_dataSource respondsToSelector:
            @selector(collectionView:numberOfItemsInSection:)])
    {
        SEL sel = @selector(collectionView:numberOfItemsInSection:);
        return ((long (*)(id, void *, id, long))objc_msgSend)(
            collectionView->_dataSource, (void *)sel, collectionView, 0);
    }
    return 0;
}

static void collection_metrics(UICollectionView *collectionView,
                               double *itemW, double *itemH,
                               double *interitem, double *line,
                               double *left, double *right, double *top,
                               double *bottom)
{
    UICollectionViewFlowLayout *flow =
        collectionView->_collectionLayout &&
                [collectionView->_collectionLayout isKindOfClass:
                    [UICollectionViewFlowLayout class]]
            ? (UICollectionViewFlowLayout *)collectionView->_collectionLayout
            : nil;
    *itemW = flow ? flow->_itemSize.width : 50.0;
    *itemH = flow ? flow->_itemSize.height : 50.0;
    if (*itemW <= 0)
        *itemW = 50.0;
    if (*itemH <= 0)
        *itemH = 50.0;
    *interitem = flow ? flow->_minimumInteritemSpacing : 10.0;
    *line = flow ? flow->_minimumLineSpacing : 10.0;
    *left = flow ? flow->_sectionInset.left : 0.0;
    *right = flow ? flow->_sectionInset.right : 0.0;
    *top = flow ? flow->_sectionInset.top : 0.0;
    *bottom = flow ? flow->_sectionInset.bottom : 0.0;
}

static int collection_columns(double width, double itemW, double interitem,
                              double left, double right)
{
    double available = width - left - right;
    int columns = (int)((available + interitem) / (itemW + interitem));
    if (columns < 1)
        columns = 1;
    return columns;
}

@implementation UICollectionView
- (id)initWithFrame:(CGRect)frame
 collectionViewLayout:(UICollectionViewLayout *)layout
{
    self = [super initWithFrame:frame];
    if (self)
    {
        _collectionLayout = layout;
        _cellClasses = [NSMutableDictionary dictionary];
        _cells = [NSMutableArray array];
        _selectedItem = -1;
        [self setBackgroundColor:[UIColor clearColor]];
    }
    return self;
}
- (void)setDataSource:(id)dataSource { _dataSource = dataSource; }
- (id)dataSource { return _dataSource; }
- (void)setDelegate:(id)delegate { _delegate = delegate; }
- (id)delegate { return _delegate; }
- (UICollectionViewLayout *)collectionViewLayout { return _collectionLayout; }
- (void)registerClass:(Class)cellClass
    forCellWithReuseIdentifier:(id)identifier
{
    if (identifier && cellClass)
        [_cellClasses setObject:cellClass forKey:identifier];
}
- (id)dequeueReusableCellWithReuseIdentifier:(id)identifier
                               forIndexPath:(NSIndexPath *)indexPath
{
    (void)indexPath;
    Class cls = identifier ? (Class)[_cellClasses objectForKey:identifier] : 0;
    if (!cls)
        cls = (Class)objc_getClass("UICollectionViewCell");
    UICollectionViewCell *cell =
        [[cls alloc] initWithFrame:CGRectMake(0, 0, 0, 0)];
    cell->_reuseIdentifier = identifier;
    return cell;
}
- (void)reloadData
{
    for (unsigned long i = 0; i < [_cells count]; i++)
    {
        id cell = [_cells objectAtIndex:i];
        if ([cell isKindOfClass:[UIView class]])
            [(UIView *)cell removeFromSuperview];
    }
    [_cells removeAllObjects];

    long count = collection_count(self);
    double itemW, itemH, interitem, line, left, right, top, bottom;
    collection_metrics(self, &itemW, &itemH, &interitem, &line,
                       &left, &right, &top, &bottom);
    int columns = collection_columns(_frame.size.width, itemW, interitem,
                                     left, right);
    for (long i = 0; i < count; i++)
    {
        NSIndexPath *path = [NSIndexPath indexPathForRow:i inSection:0];
        UICollectionViewCell *cell = nil;
        if (_dataSource &&
            [_dataSource respondsToSelector:
                @selector(collectionView:cellForItemAtIndexPath:)])
        {
            SEL sel = @selector(collectionView:cellForItemAtIndexPath:);
            cell = (UICollectionViewCell *)((id (*)(id, void *, id, id))
                objc_msgSend)(_dataSource, (void *)sel, self, path);
        }
        if (cell)
        {
            int column = (int)(i % columns), row = (int)(i / columns);
            double x = left + column * (itemW + interitem);
            double y = top + row * (itemH + line);
            [cell setFrame:CGRectMake(x, y, itemW, itemH)];
            [cell setSelected:(i == _selectedItem) animated:NO];
            [self addSubview:cell];
            [_cells addObject:cell];
        }
        else
            [_cells addObject:[NSNull null]];
    }
    long rows = (count + columns - 1) / columns;
    double height = rows > 0 ? top + rows * itemH + (rows - 1) * line + bottom
                             : 0;
    _contentSize = CGSizeMake(_frame.size.width, height);
}
- (void)handleTapAtPoint:(CGPoint)point
{
    long count = collection_count(self);
    double itemW, itemH, interitem, line, left, right, top, bottom;
    collection_metrics(self, &itemW, &itemH, &interitem, &line,
                       &left, &right, &top, &bottom);
    int columns = collection_columns(_frame.size.width, itemW, interitem,
                                     left, right);
    for (long i = 0; i < count; i++)
    {
        int column = (int)(i % columns), row = (int)(i / columns);
        double x = left + column * (itemW + interitem);
        double y = top + row * (itemH + line);
        if (point.x < x || point.x >= x + itemW || point.y < y ||
            point.y >= y + itemH)
            continue;
        long previous = _selectedItem;
        _selectedItem = i;
        if (previous >= 0 && previous < (long)[_cells count])
        {
            id cell = [_cells objectAtIndex:(unsigned long)previous];
            if ([cell isKindOfClass:[UICollectionViewCell class]])
                [(UICollectionViewCell *)cell setSelected:NO animated:NO];
        }
        if (i < (long)[_cells count])
        {
            id cell = [_cells objectAtIndex:(unsigned long)i];
            if ([cell isKindOfClass:[UICollectionViewCell class]])
                [(UICollectionViewCell *)cell setSelected:YES animated:NO];
        }
        if (_delegate &&
            [_delegate respondsToSelector:
                @selector(collectionView:didSelectItemAtIndexPath:)])
        {
            NSIndexPath *path = [NSIndexPath indexPathForRow:i inSection:0];
            SEL sel = @selector(collectionView:didSelectItemAtIndexPath:);
            ((void (*)(id, void *, id, id))objc_msgSend)(
                _delegate, (void *)sel, self, path);
        }
        return;
    }
}
@end

static UIWindow *g_keyWindow;
id UIApplicationDidBecomeActiveNotification = @"UIApplicationDidBecomeActiveNotification";
id UIApplicationWillResignActiveNotification = @"UIApplicationWillResignActiveNotification";
id UIApplicationDidEnterBackgroundNotification = @"UIApplicationDidEnterBackgroundNotification";
id UIApplicationWillEnterForegroundNotification = @"UIApplicationWillEnterForegroundNotification";
id UIApplicationDidFinishLaunchingNotification = @"UIApplicationDidFinishLaunchingNotification";

static void send_gesture_action(UIGestureRecognizer *gesture, long state)
{
    if (!gesture || !gesture->_enabled)
        return;
    gesture->_state = state;
    if (gesture->_target && gesture->_action)
        ((void (*)(id, SEL, id))objc_msgSend)(gesture->_target,
                                             gesture->_action, gesture);
}

static double clamp_scroll(double value, double low, double high)
{
    if (value < low)
        return low;
    if (value > high)
        return high;
    return value;
}

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
- (void)beginTouchAtPoint:(CGPoint)point
{
    if (_touch)
        [self endTouchAtPoint:_touch->_location cancelled:YES];
    UITouch *touch = [[UITouch alloc] init];
    touch->_location = point;
    touch->_previousLocation = point;
    touch->_phase = UITouchPhaseBegan;
    touch->_timestamp = iosim_now();
    touch->_view = _touchHit;
    touch->_window = self;
    touch->_tapCount = 1;
    _touch = touch;
    if (_touchHit)
    {
        UIEvent *event = [[UIEvent alloc] initWithTouch:touch];
        [_touchHit touchesBegan:[NSSet setWithObject:touch] withEvent:event];
    }
}
- (void)moveTouchToPoint:(CGPoint)point
{
    if (!_touch)
        return;
    _touch->_previousLocation = _touch->_location;
    _touch->_location = point;
    _touch->_phase = UITouchPhaseMoved;
    _touch->_timestamp = iosim_now();
    if (_touchHit)
    {
        UIEvent *event = [[UIEvent alloc] initWithTouch:_touch];
        [_touchHit touchesMoved:[NSSet setWithObject:_touch] withEvent:event];
    }
}
- (void)endTouchAtPoint:(CGPoint)point cancelled:(BOOL)cancelled
{
    if (!_touch)
        return;
    _touch->_previousLocation = _touch->_location;
    _touch->_location = point;
    _touch->_phase = cancelled ? UITouchPhaseCancelled : UITouchPhaseEnded;
    _touch->_timestamp = iosim_now();
    if (_touchHit)
    {
        NSSet *set = [NSSet setWithObject:_touch];
        UIEvent *event = [[UIEvent alloc] initWithTouch:_touch];
        if (cancelled)
            [_touchHit touchesCancelled:set withEvent:event];
        else
            [_touchHit touchesEnded:set withEvent:event];
    }
    _touch = nil;
}
- (void)dispatchTouchDownX:(int)x y:(int)y
{
    double scale = [[UIScreen mainScreen] scale];
    if (scale <= 0)
        scale = 1.0;
    CGPoint point = CGPointMake(x / scale, y / scale);
    _dragStartPoint = point;
    _dragStartContent = CGPointMake(0, 0);
    _dragScroll = nil;
    _activePan = nil;
    _longPress = nil;
    _touchHit = [self hitTest:point];
    for (UIView *v = _touchHit; v; v = [v superview])
    {
        if (!_dragScroll && [v isKindOfClass:[UIScrollView class]])
            _dragScroll = (UIScrollView *)v;
        for (int i = 0; i < v->_gestureRecognizerCount; i++)
        {
            UIGestureRecognizer *g = v->_gestureRecognizers[i];
            if (!g || !g->_enabled)
                continue;
            if ([g isKindOfClass:[UIPanGestureRecognizer class]] && !_activePan)
            {
                _activePan = (UIPanGestureRecognizer *)g;
                g->_location = point;
                g->_translation = CGPointMake(0, 0);
                send_gesture_action(g, UIGestureRecognizerStateBegan);
            }
            else if ([g isKindOfClass:[UILongPressGestureRecognizer class]] &&
                     !_longPress)
            {
                _longPress = g;
                _pressStartPoint = point;
                _pressStartTime = iosim_now();
                g->_state = UIGestureRecognizerStatePossible;
                g->_location = point;
            }
        }
    }
    if (_dragScroll)
        _dragStartContent = _dragScroll->_contentOffset;
    if (getenv("IOSIM_DEBUG_TOUCH"))
        printf("[touch] down hit=%p scroll=%p pan=%p\n", _touchHit,
               _dragScroll, _activePan);
    [self beginTouchAtPoint:point];
}
- (void)dispatchTouchMoveX:(int)x y:(int)y
{
    double scale = [[UIScreen mainScreen] scale];
    if (scale <= 0)
        scale = 1.0;
    CGPoint point = CGPointMake(x / scale, y / scale);
    if (_longPress)
    {
        UILongPressGestureRecognizer *press =
            (UILongPressGestureRecognizer *)_longPress;
        if (press->_state == UIGestureRecognizerStatePossible)
        {
            double dx = point.x - _pressStartPoint.x;
            double dy = point.y - _pressStartPoint.y;
            if (dx * dx + dy * dy >
                press->_allowableMovement * press->_allowableMovement)
            {
                press->_state = UIGestureRecognizerStateFailed;
                _longPress = nil;
            }
        }
        else if (press->_state == UIGestureRecognizerStateBegan ||
                 press->_state == UIGestureRecognizerStateChanged)
        {
            press->_location = point;
            send_gesture_action(press, UIGestureRecognizerStateChanged);
        }
    }
    if (_activePan)
    {
        _activePan->_location = point;
        _activePan->_translation =
            CGPointMake(point.x - _dragStartPoint.x,
                        point.y - _dragStartPoint.y);
        send_gesture_action(_activePan, UIGestureRecognizerStateChanged);
    }
    if (_dragScroll && _dragScroll->_scrollEnabled)
    {
        double maxX = _dragScroll->_contentSize.width -
                      _dragScroll->_frame.size.width;
        double maxY = _dragScroll->_contentSize.height -
                      _dragScroll->_frame.size.height;
        if (maxX < 0)
            maxX = 0;
        if (maxY < 0)
            maxY = 0;
        double nx = _dragStartContent.x - (point.x - _dragStartPoint.x);
        double ny = _dragStartContent.y - (point.y - _dragStartPoint.y);
        _dragScroll->_contentOffset =
            CGPointMake(clamp_scroll(nx, -30, maxX + 30),
                        clamp_scroll(ny, -30, maxY + 30));
        if (_dragScroll->_delegate && [_dragScroll->_delegate respondsToSelector:
                @selector(scrollViewDidScroll:)])
            [_dragScroll->_delegate scrollViewDidScroll:_dragScroll];
        if (getenv("IOSIM_DEBUG_TOUCH"))
            printf("[touch] move offset=%.1f,%.1f max=%.1f,%.1f\n",
                   _dragScroll->_contentOffset.x,
                   _dragScroll->_contentOffset.y, maxX, maxY);
    }
    [self moveTouchToPoint:point];
}
- (void)dispatchTouchUpX:(int)x y:(int)y
{
    double scale = [[UIScreen mainScreen] scale];
    if (scale <= 0)
        scale = 1.0;
    CGPoint point = CGPointMake(x / scale, y / scale);
    if (_longPress)
    {
        if (_longPress->_state == UIGestureRecognizerStateBegan ||
            _longPress->_state == UIGestureRecognizerStateChanged)
        {
            _longPress->_location = point;
            send_gesture_action(_longPress, UIGestureRecognizerStateEnded);
        }
        else if (_longPress->_state == UIGestureRecognizerStatePossible)
            _longPress->_state = UIGestureRecognizerStateFailed;
        _longPress = nil;
    }
    if (_activePan)
    {
        _activePan->_location = point;
        _activePan->_translation =
            CGPointMake(point.x - _dragStartPoint.x,
                        point.y - _dragStartPoint.y);
        send_gesture_action(_activePan, UIGestureRecognizerStateEnded);
        _activePan = nil;
    }
    if (_dragScroll)
    {
        double maxX = _dragScroll->_contentSize.width -
                      _dragScroll->_frame.size.width;
        double maxY = _dragScroll->_contentSize.height -
                      _dragScroll->_frame.size.height;
        if (maxX < 0)
            maxX = 0;
        if (maxY < 0)
            maxY = 0;
        _dragScroll->_contentOffset =
            CGPointMake(clamp_scroll(_dragScroll->_contentOffset.x, 0, maxX),
                        clamp_scroll(_dragScroll->_contentOffset.y, 0, maxY));
        _dragScroll = nil;
    }
    double dx = point.x - _dragStartPoint.x;
    double dy = point.y - _dragStartPoint.y;
    long direction = 0;
    if (__builtin_fabs(dx) > __builtin_fabs(dy))
        direction = dx > 0 ? UISwipeGestureRecognizerDirectionRight
                           : UISwipeGestureRecognizerDirectionLeft;
    else if (__builtin_fabs(dy) > 0)
        direction = dy > 0 ? UISwipeGestureRecognizerDirectionDown
                           : UISwipeGestureRecognizerDirectionUp;
    if (direction && (__builtin_fabs(dx) > 40 || __builtin_fabs(dy) > 40))
    {
        for (UIView *v = _touchHit; v; v = [v superview])
            for (int i = 0; i < v->_gestureRecognizerCount; i++)
            {
                UIGestureRecognizer *g = v->_gestureRecognizers[i];
                if (!g || !g->_enabled)
                    continue;
                if ([g isKindOfClass:[UISwipeGestureRecognizer class]] &&
                    (((UISwipeGestureRecognizer *)g)->_direction & direction))
                {
                    g->_location = point;
                    send_gesture_action(g, UIGestureRecognizerStateEnded);
                }
            }
    }
    [self endTouchAtPoint:point cancelled:NO];
    _touchHit = nil;
}
/* Called once per run-loop frame while a touch is down: a long press whose
 * minimum duration has elapsed becomes Began without needing another event. */
- (int)tickGestureRecognizers
{
    if (!_longPress || _longPress->_state != UIGestureRecognizerStatePossible)
        return 0;
    UILongPressGestureRecognizer *press =
        (UILongPressGestureRecognizer *)_longPress;
    if (iosim_now() - _pressStartTime < press->_minimumPressDuration)
        return 0;
    press->_location = _pressStartPoint;
    send_gesture_action(press, UIGestureRecognizerStateBegan);
    return 1;
}

- (void)dispatchTapX:(int)x y:(int)y
{
    double scale = [[UIScreen mainScreen] scale];
    if (scale <= 0)
        scale = 1.0;
    CGPoint point = CGPointMake(x / scale, y / scale);
    UIView *hit = [self hitTest:point];
    for (UIView *v = hit; v; v = [v superview])
        for (int i = 0; i < v->_gestureRecognizerCount; i++)
        {
            UIGestureRecognizer *g = v->_gestureRecognizers[i];
            if (!g || !g->_enabled)
                continue;
            if ([g isKindOfClass:[UITapGestureRecognizer class]])
            {
                g->_location = point;
                send_gesture_action(g, UIGestureRecognizerStateEnded);
            }
        }
    _touchHit = hit;
    [self beginTouchAtPoint:point];
    [self endTouchAtPoint:point cancelled:NO];
    _touchHit = nil;
    UIView *tableHit = hit;
    while (tableHit && ![tableHit isKindOfClass:[UITableView class]])
        tableHit = [tableHit superview];
    if (tableHit)
    {
        double ox = 0, oy = 0;
        UIView *anc = tableHit;
        while (anc)
        {
            ox += anc->_frame.origin.x;
            oy += anc->_frame.origin.y;
            if ([anc isKindOfClass:[UIScrollView class]])
            {
                UIScrollView *sc = (UIScrollView *)anc;
                ox -= sc->_contentOffset.x;
                oy -= sc->_contentOffset.y;
            }
            anc = [anc superview];
        }
        [(UITableView *)tableHit
            handleTapAtPoint:CGPointMake(point.x - ox, point.y - oy)];
    }
    UIView *collectionHit = hit;
    while (collectionHit &&
           ![collectionHit isKindOfClass:[UICollectionView class]])
        collectionHit = [collectionHit superview];
    if (collectionHit)
    {
        double ox = 0, oy = 0;
        UIView *anc = collectionHit;
        while (anc)
        {
            ox += anc->_frame.origin.x;
            oy += anc->_frame.origin.y;
            if ([anc isKindOfClass:[UIScrollView class]])
            {
                UIScrollView *sc = (UIScrollView *)anc;
                ox -= sc->_contentOffset.x;
                oy -= sc->_contentOffset.y;
            }
            anc = [anc superview];
        }
        [(UICollectionView *)collectionHit
            handleTapAtPoint:CGPointMake(point.x - ox, point.y - oy)];
    }
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
- (id)init
{
    self = [super init];
    if (self)
        _state = UIApplicationStateActive;
    return self;
}
- (void)setDelegate:(id)delegate { _delegate = delegate; }
- (id)delegate { return _delegate; }
- (long)applicationState { return _state; }
- (double)backgroundTimeRemaining { return 0xFFFFFFFF; }
- (unsigned long)beginBackgroundTaskWithExpirationHandler:(void (^)(void))handler
{
    /* The runtime suspends the process as soon as the scene backgrounds, so
     * no background execution window exists to hand out. */
    (void)handler;
    return 0;
}
- (void)endBackgroundTask:(unsigned long)task { (void)task; }
@end

static id g_pasteboard_text_type;
static id g_pasteboard_text_type_value(void)
{
    if (!g_pasteboard_text_type)
        g_pasteboard_text_type = @"public.utf8-plain-text";
    return g_pasteboard_text_type;
}

static void pasteboard_path(char *out, unsigned long cap)
{
    const char *shared = getenv("SIMULATOR_SHARED_RESOURCES_DIRECTORY");
    if (shared && *shared)
    {
        snprintf(out, cap, "%s/var/run/pasteboard.plist", shared);
        return;
    }
    const char *home = getenv("HOME");
    snprintf(out, cap, "%s/Library/Preferences/pasteboard.plist",
             home && *home ? home : ".");
}

@implementation UIPasteboard
+ (UIPasteboard *)generalPasteboard
{
    static UIPasteboard *board;
    if (!board)
        board = [[self alloc] init];
    return board;
}
- (void)reload
{
    char path[1024];
    pasteboard_path(path, sizeof(path));
    unsigned char *bytes = 0;
    unsigned long length = 0;
    if (iosim_fs_read(path, &bytes, &length) != 0)
        return;
    NSData *data = [[NSData alloc] initWithBytes:bytes length:length];
    free(bytes);
    id plist = [NSPropertyListSerialization propertyListWithData:data
                                                         options:0
                                                          format:0
                                                           error:0];
    if (!plist || ![plist isKindOfClass:[NSDictionary class]])
        return;
    id items = [plist objectForKey:@"items"];
    if (items && [items isKindOfClass:[NSArray class]])
        _items = items;
    id change = [plist objectForKey:@"changeCount"];
    if (change && [change respondsToSelector:@selector(integerValue)])
        _changeCount = [change integerValue];
}
- (void)save
{
    char path[1024];
    pasteboard_path(path, sizeof(path));
    char dir[1024];
    snprintf(dir, sizeof(dir), "%s", path);
    char *slash = 0;
    for (char *q = dir; *q; q++)
        if (*q == '/')
            slash = q;
    if (slash)
    {
        *slash = 0;
        iosim_fs_mkdir(dir, 1);
    }
    NSMutableDictionary *plist = [NSMutableDictionary dictionary];
    if (_items)
        [plist setObject:_items forKey:@"items"];
    [plist setObject:[NSNumber numberWithInteger:_changeCount]
              forKey:@"changeCount"];
    NSData *data = [NSPropertyListSerialization
        dataWithPropertyList:plist format:NSPropertyListXMLFormat_v1_0
        options:0 error:0];
    if (data)
        [data writeToFile:[NSString stringWithUTF8String:path]
               atomically:YES];
}
- (id)items
{
    [self reload];
    return _items ? _items : [NSArray array];
}
- (void)setItems:(id)items
{
    NSMutableArray *copied = [NSMutableArray array];
    if (items && [items isKindOfClass:[NSArray class]])
    {
        for (unsigned long i = 0; i < [items count]; i++)
        {
            id item = [items objectAtIndex:i];
            if (item && [item isKindOfClass:[NSDictionary class]])
                [copied addObject:item];
        }
    }
    _items = copied;
    _changeCount++;
    [self save];
}
- (id)string
{
    id items = [self items];
    id type = g_pasteboard_text_type_value();
    for (unsigned long i = 0; i < [items count]; i++)
    {
        id item = [items objectAtIndex:i];
        if (![item isKindOfClass:[NSDictionary class]])
            continue;
        id value = [(NSDictionary *)item objectForKey:type];
        if (value && [value isKindOfClass:[NSString class]])
            return value;
    }
    return nil;
}
- (void)setString:(id)string
{
    [self reload];
    NSMutableArray *items = [NSMutableArray array];
    if (string)
    {
        NSMutableDictionary *item = [NSMutableDictionary dictionary];
        [item setObject:string forKey:g_pasteboard_text_type_value()];
        [items addObject:item];
    }
    _items = items;
    _changeCount++;
    [self save];
}
- (BOOL)hasStrings
{
    return [self string] != nil;
}
- (long)changeCount
{
    [self reload];
    return _changeCount;
}
- (id)dataForPasteboardType:(id)type
{
    if (!type)
        return nil;
    id items = [self items];
    for (unsigned long i = 0; i < [items count]; i++)
    {
        id item = [items objectAtIndex:i];
        if (![item isKindOfClass:[NSDictionary class]])
            continue;
        id value = [(NSDictionary *)item objectForKey:type];
        if (value)
            return value;
    }
    return nil;
}
- (void)setData:(id)data forPasteboardType:(id)type
{
    [self reload];
    NSMutableArray *items = [NSMutableArray array];
    if (data && type)
    {
        NSMutableDictionary *item = [NSMutableDictionary dictionary];
        [item setObject:data forKey:type];
        [items addObject:item];
    }
    _items = items;
    _changeCount++;
    [self save];
}
- (long)numberOfItems
{
    return (long)[[self items] count];
}
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

static double curve_value(double t, int curve)
{
    if (t < 0)
        t = 0;
    if (t > 1)
        t = 1;
    if (curve == 1)
        return t * t;
    if (curve == 2)
        return 1.0 - (1.0 - t) * (1.0 - t);
    if (curve == 3)
        return t;
    return t * t * (3.0 - 2.0 * t);
}

/* Progress in 0..1 for a view animation, honouring its delay, curve and
 * repeat/autoreverse options. Sets *finished once a finite animation ends. */
static double view_animation_progress(UIView *view, int *finished)
{
    if (finished)
        *finished = 0;
    double elapsed = iosim_now() - view->_animStart - view->_animDelay;
    if (elapsed <= 0.0)
        return 0.0;
    double duration = view->_animDuration;
    if (duration <= 0.0)
    {
        if (finished)
            *finished = 1;
        return 1.0;
    }
    double p = elapsed / duration;
    if (!view->_animInfinite)
    {
        if (p >= 1.0)
        {
            if (finished)
                *finished = 1;
            return 1.0;
        }
        return curve_value(p, view->_animCurve);
    }
    double local;
    if (view->_animAutoreverse)
    {
        double cycle = p - 2.0 * (long)(p / 2.0);
        local = cycle > 1.0 ? 2.0 - cycle : cycle;
    }
    else
        local = p - (long)p;
    return curve_value(local, view->_animCurve);
}

static CGRect current_frame(UIView *view)
{
    if (view->_animatingFrame)
    {
        int finished = 0;
        double e = view_animation_progress(view, &finished);
        if (finished)
        {
            view->_animatingFrame = NO;
            view->_frame = view->_animFrameTo;
        }
        else
        {
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
        int finished = 0;
        double e = view_animation_progress(view, &finished);
        if (finished)
        {
            view->_animatingAlpha = NO;
            view->_alpha = view->_animAlphaTo;
        }
        else
            return view->_animAlphaFrom +
                   (view->_animAlphaTo - view->_animAlphaFrom) * e;
    }
    return view->_alpha;
}

static double number_value(id value, double fallback)
{
    if (!value)
        return fallback;
    return ((double (*)(id, SEL))objc_msgSend)(value, @selector(doubleValue));
}

static double layer_keyframe_value(id values, id keyTimes, double t)
{
    int n = values ? (int)[values count] : 0;
    if (n <= 0)
        return 0.0;
    double first = number_value([values objectAtIndex:0], 0.0);
    if (n == 1 || t <= 0.0)
        return first;
    double last = number_value([values objectAtIndex:(unsigned long)(n - 1)],
                               0.0);
    if (t >= 1.0)
        return last;
    for (int i = 0; i + 1 < n; i++)
    {
        double t0 = keyTimes
            ? number_value([keyTimes objectAtIndex:(unsigned long)i],
                           (double)i / (n - 1))
            : (double)i / (n - 1);
        double t1 = keyTimes
            ? number_value([keyTimes objectAtIndex:(unsigned long)(i + 1)],
                           (double)(i + 1) / (n - 1))
            : (double)(i + 1) / (n - 1);
        if (t <= t1 || i == n - 2)
        {
            double a = number_value([values objectAtIndex:(unsigned long)i],
                                    0.0);
            double b = number_value(
                [values objectAtIndex:(unsigned long)(i + 1)], 0.0);
            if (t1 <= t0)
                return b;
            double f = (t - t0) / (t1 - t0);
            if (f < 0)
                f = 0;
            if (f > 1)
                f = 1;
            return a + (b - a) * f;
        }
    }
    return last;
}

static double layer_key_value(CALayer *layer, const char *key, double base)
{
    struct layer_anim *anim = 0;
    for (int i = 0; i < LAYER_ANIM_SLOTS; i++)
    {
        struct layer_anim *entry = &layer->_anims[i];
        if (!entry->used || !entry->keyPath)
            continue;
        const char *path = iosim_string_cstr(entry->keyPath);
        if (!path || strcmp(path, key) != 0)
            continue;
        if (!anim || entry->seq > anim->seq)
            anim = entry;
    }
    if (!anim)
        return base;
    double t = (iosim_now() - anim->start) / anim->duration;
    double repeat = anim->repeatCount;
    if (t < 0)
        t = 0;
    if (repeat < 0)
        t = t - (long)t;
    else if (repeat > 1 && t >= repeat)
        t = 1.0;
    else if (repeat > 1)
        t = t - (long)t;
    else if (t >= 1.0)
    {
        if (anim->values)
            return layer_keyframe_value(anim->values, anim->keyTimes, 1.0);
        return number_value(anim->toValue, base);
    }
    if (anim->values)
        return layer_keyframe_value(anim->values, anim->keyTimes, t);
    double from = number_value(anim->fromValue, base);
    double to = number_value(anim->toValue, base);
    double e;
    if (anim->timingFunction)
        e = ((double (*)(id, SEL, double))objc_msgSend)(
            anim->timingFunction, @selector(evaluate:), t);
    else
        e = curve_value(t, 3); /* Core Animation defaults to linear. */
    return from + (to - from) * e;
}


/* -------------------------------------------------------- auto layout */

#define MAX_LAYOUT_VIEWS 96

struct layout_entry {
    UIView *view;
    int fixed;
    int lockW, lockH;
    double x, y, w, h;
};

static struct layout_entry *layout_find(struct layout_entry *entries, int count,
                                        id item)
{
    if (!item)
        return 0;
    for (int i = 0; i < count; i++)
        if ((id)entries[i].view == item)
            return &entries[i];
    return 0;
}

static UILayoutGuide *layout_guide(id item)
{
    if (item && [item isKindOfClass:[UILayoutGuide class]])
        return (UILayoutGuide *)item;
    return 0;
}

static double *layout_var_ptr(struct layout_entry *entries, int vi)
{
    struct layout_entry *e = &entries[vi / 4];
    switch (vi % 4)
    {
    case 0: return &e->x;
    case 1: return &e->y;
    case 2: return &e->w;
    default: return &e->h;
    }
}

static int layout_var_free(struct layout_entry *entries, int vi)
{
    struct layout_entry *e = &entries[vi / 4];
    if (e->fixed)
        return 0;
    if ((vi % 4) == 2 && e->lockW)
        return 0;
    if ((vi % 4) == 3 && e->lockH)
        return 0;
    return 1;
}

/* Express an anchor as a linear form over the entries' x, y, w, h slots,
 * plus a constant offset (used by layout guides and baselines). */
static void layout_form(struct layout_entry *entries, int count, id item,
                        long attribute, double *coeff, double *offset)
{
    for (int i = 0; i < count * 4; i++)
        coeff[i] = 0;
    *offset = 0;
    if (!item || attribute == NSLayoutAttributeNotAnAttribute)
        return;
    UILayoutGuide *guide = layout_guide(item);
    UIView *owner = guide ? (UIView *)guide->_owningView : (UIView *)item;
    int index = -1;
    for (int i = 0; i < count; i++)
        if (entries[i].view == owner)
        {
            index = i;
            break;
        }
    if (index < 0)
        return;
    double *c = coeff + index * 4;
    double leftInset = guide ? guide->_leftInset : 0;
    double rightInset = guide ? guide->_rightInset : 0;
    double topInset = guide ? guide->_topInset : 0;
    double bottomInset = guide ? guide->_bottomInset : 0;
    switch (attribute)
    {
    case NSLayoutAttributeLeft:
    case NSLayoutAttributeLeading:
        c[0] = 1;
        *offset = leftInset;
        break;
    case NSLayoutAttributeRight:
    case NSLayoutAttributeTrailing:
        c[0] = 1;
        c[2] = 1;
        *offset = -rightInset;
        break;
    case NSLayoutAttributeTop:
        c[1] = 1;
        *offset = topInset;
        break;
    case NSLayoutAttributeBottom:
        c[1] = 1;
        c[3] = 1;
        *offset = -bottomInset;
        break;
    case NSLayoutAttributeWidth:
        c[2] = 1;
        *offset = -(leftInset + rightInset);
        break;
    case NSLayoutAttributeHeight:
        c[3] = 1;
        *offset = -(topInset + bottomInset);
        break;
    case NSLayoutAttributeCenterX:
        c[0] = 1;
        c[2] = 0.5;
        *offset = (leftInset - rightInset) / 2;
        break;
    case NSLayoutAttributeCenterY:
        c[1] = 1;
        c[3] = 0.5;
        *offset = (topInset - bottomInset) / 2;
        break;
    case NSLayoutAttributeFirstBaseline:
    case NSLayoutAttributeLastBaseline:
        c[1] = 1;
        c[3] = 0.5;
        if (!guide && [owner isKindOfClass:[UILabel class]])
        {
            UILabel *label = (UILabel *)owner;
            double points = label->_font ? label->_font->_size : 17.0;
            int style = label->_font && label->_font->_bold
                            ? IOSIM_FONT_BOLD : IOSIM_FONT_REGULAR;
            double scale = [[UIScreen mainScreen] scale];
            int ascent = 0, descent = 0, lineHeight = 0;
            iosim_fb_font_metrics(style, points, scale, &ascent, &descent,
                                  &lineHeight);
            *offset = ascent / scale - lineHeight / scale / 2;
        }
        else
            c[3] = 0.8;
        break;
    }
}

static void layout_apply_constraint(struct layout_entry *entries, int count,
                                    NSLayoutConstraint *c)
{
    if (!c || !c->_active || c->_firstAttribute == NSLayoutAttributeNotAnAttribute)
        return;
    UIView *owner1 = layout_guide(c->_firstItem)
                         ? (UIView *)((UILayoutGuide *)c->_firstItem)->_owningView
                         : (UIView *)c->_firstItem;
    if (!layout_find(entries, count, owner1))
        return;
    if (c->_secondItem && c->_secondAttribute != NSLayoutAttributeNotAnAttribute)
    {
        UIView *owner2 = layout_guide(c->_secondItem)
                             ? (UIView *)((UILayoutGuide *)c->_secondItem)->_owningView
                             : (UIView *)c->_secondItem;
        if (!layout_find(entries, count, owner2))
            return;
    }

    double f1[MAX_LAYOUT_VIEWS * 4], f2[MAX_LAYOUT_VIEWS * 4];
    double off1 = 0, off2 = 0;
    layout_form(entries, count, c->_firstItem, c->_firstAttribute, f1, &off1);
    if (c->_secondItem)
        layout_form(entries, count, c->_secondItem, c->_secondAttribute, f2,
                    &off2);
    else
        for (int i = 0; i < count * 4; i++)
            f2[i] = 0;

    double a[MAX_LAYOUT_VIEWS * 4];
    double rhs = c->_constant - off1;
    if (c->_secondItem)
        rhs += c->_multiplier * off2;
    for (int i = 0; i < count * 4; i++)
        a[i] = f1[i] - (c->_secondItem ? c->_multiplier * f2[i] : 0);

    double value = 0, norm = 0;
    for (int i = 0; i < count * 4; i++)
    {
        if (a[i] == 0)
            continue;
        value += a[i] * (*layout_var_ptr(entries, i));
        if (layout_var_free(entries, i))
            norm += a[i] * a[i];
    }
    if (norm <= 0)
        return;
    double residual = value - rhs;
    int violates = 0;
    if (c->_relation == NSLayoutRelationEqual)
        violates = __builtin_fabs(residual) > 0.0005;
    else if (c->_relation == NSLayoutRelationGreaterThanOrEqual)
        violates = residual < -0.0005;
    else
        violates = residual > 0.0005;
    if (!violates)
        return;

    double step = c->_priority / 1000.0;
    if (step > 1)
        step = 1;
    if (step <= 0)
        return;
    double correction = -residual * step / norm;
    for (int i = 0; i < count * 4; i++)
    {
        if (a[i] == 0 || !layout_var_free(entries, i))
            continue;
        double *var = layout_var_ptr(entries, i);
        *var += correction * a[i];
        struct layout_entry *e = &entries[i / 4];
        if (e->w < 0)
            e->w = 0;
        if (e->h < 0)
            e->h = 0;
    }
}

static int layout_has_attribute(UIView *view, long attribute)
{
    for (int i = 0; i < g_activeConstraintCount; i++)
    {
        NSLayoutConstraint *c = g_activeConstraints[i];
        if (!c || !c->_active)
            continue;
        if (c->_firstItem == view && c->_firstAttribute == attribute)
            return 1;
        if (c->_secondItem == view && c->_secondAttribute == attribute)
            return 1;
    }
    return 0;
}

static CGSize layout_intrinsic_size(UIView *view, struct layout_entry *e)
{
    CGSize size = [view intrinsicContentSize];
    if ([view isKindOfClass:[UILabel class]])
    {
        UILabel *label = (UILabel *)view;
        if (label->_numberOfLines != 1 && label->_text)
        {
            const char *text = iosim_string_cstr(label->_text);
            double points = label->_font ? label->_font->_size : 17.0;
            int style = label->_font && label->_font->_bold
                            ? IOSIM_FONT_BOLD : IOSIM_FONT_REGULAR;
            double scale = [[UIScreen mainScreen] scale];
            char lines[IOSIM_MAX_WRAP_LINES][256];
            int maxLines = label->_numberOfLines > 1
                               ? label->_numberOfLines : IOSIM_MAX_WRAP_LINES;
            int n = wrap_text_lines(text, style, points, scale,
                                    (int)(e->w * scale + 0.5), lines,
                                    maxLines);
            int ascent = 0, descent = 0, lineHeight = 0;
            iosim_fb_font_metrics(style, points, scale, &ascent, &descent,
                                  &lineHeight);
            if (n > 0)
                size.height = (double)n * lineHeight / scale;
        }
    }
    return size;
}

static int layout_first_item_attribute(UIView *view, long attribute)
{
    for (int i = 0; i < g_activeConstraintCount; i++)
    {
        NSLayoutConstraint *c = g_activeConstraints[i];
        if (c && c->_active && c->_firstItem == view &&
            c->_firstAttribute == attribute)
            return 1;
    }
    return 0;
}

/* Decide which dimensions are fixed by intrinsic size rather than by
 * constraints. A width is intrinsic unless there is a width constraint or
 * both horizontal edges are pinned by constraints on this view; the same
 * rule applies to height. */
static void layout_init_locks(struct layout_entry *entries, int count)
{
    for (int i = 0; i < count; i++)
    {
        struct layout_entry *e = &entries[i];
        e->lockW = e->lockH = 0;
        if (e->fixed)
            continue;
        UIView *view = e->view;
        CGSize intrinsic = [view intrinsicContentSize];
        int hasW = layout_has_attribute(view, NSLayoutAttributeWidth);
        int hasH = layout_has_attribute(view, NSLayoutAttributeHeight);
        int leading = layout_first_item_attribute(view, NSLayoutAttributeLeading) ||
                      layout_first_item_attribute(view, NSLayoutAttributeLeft);
        int trailing = layout_first_item_attribute(view, NSLayoutAttributeTrailing) ||
                       layout_first_item_attribute(view, NSLayoutAttributeRight);
        int top = layout_first_item_attribute(view, NSLayoutAttributeTop);
        int bottom = layout_first_item_attribute(view, NSLayoutAttributeBottom);
        if (!hasW && !(leading && trailing) && intrinsic.width > 0)
        {
            e->lockW = 1;
            if (e->w <= 0)
                e->w = intrinsic.width;
        }
        if (!hasH && !(top && bottom) && intrinsic.height > 0)
        {
            e->lockH = 1;
            if (e->h <= 0)
                e->h = intrinsic.height;
        }
    }
}

static void layout_apply_intrinsic(struct layout_entry *entries, int count,
                                   struct layout_entry *e)
{
    if (!e->lockW && !e->lockH)
        return;
    CGSize intrinsic = layout_intrinsic_size(e->view, e);
    if (e->lockW && intrinsic.width > 0)
        e->w = intrinsic.width;
    if (e->lockH && intrinsic.height > 0)
        e->h = intrinsic.height;
    if (e->w < 0)
        e->w = 0;
    if (e->h < 0)
        e->h = 0;
}

static void layout_collect(UIView *view, struct layout_entry *entries,
                           int *count, double parentX, double parentY)
{
    if (!view || *count >= MAX_LAYOUT_VIEWS)
        return;
    struct layout_entry *e = &entries[*count];
    e->view = view;
    e->x = parentX + view->_frame.origin.x;
    e->y = parentY + view->_frame.origin.y;
    e->w = view->_frame.size.width;
    e->h = view->_frame.size.height;
    e->fixed = view->_translatesAutoresizingMaskIntoConstraints ? 1 : 0;
    (*count)++;
    for (int i = 0; i < view->_subviewCount; i++)
        layout_collect((UIView *)view->_subviews[i], entries, count, e->x,
                       e->y);
}

static void layout_write(UIView *view, struct layout_entry *entries, int count)
{
    struct layout_entry *e = layout_find(entries, count, view);
    if (!e)
        return;
    if (view->_superview && !e->fixed)
    {
        struct layout_entry *parent =
            layout_find(entries, count, view->_superview);
        if (parent)
            [view setFrame:CGRectMake(e->x - parent->x, e->y - parent->y,
                                      e->w, e->h)];
    }
    for (int i = 0; i < view->_subviewCount; i++)
        layout_write((UIView *)view->_subviews[i], entries, count);
}

static void iosim_layout_apply(UIView *root)
{
    if (!root || g_activeConstraintCount == 0)
        return;
    struct layout_entry entries[MAX_LAYOUT_VIEWS];
    int count = 0;
    layout_collect(root, entries, &count, 0, 0);
    if (count == 0)
        return;
    layout_init_locks(entries, count);
    for (int iter = 0; iter < 240; iter++)
    {
        for (int i = 0; i < g_activeConstraintCount; i++)
            layout_apply_constraint(entries, count, g_activeConstraints[i]);
        if ((iter & 1) == 0)
            for (int i = 0; i < count; i++)
                if (!entries[i].fixed)
                    layout_apply_intrinsic(entries, count, &entries[i]);
    }
    if (getenv("IOSIM_DEBUG_LAYOUT"))
    {
        for (int i = 0; i < count; i++)
        {
            UIView *v = entries[i].view;
            const char *cls = "UIView";
            if ([v isKindOfClass:[UILabel class]])
                cls = "UILabel";
            else if ([v isKindOfClass:[UIButton class]])
                cls = "UIButton";
            printf("[layout] %s fixed=%d x=%.1f y=%.1f w=%.1f h=%.1f\n",
                   cls, entries[i].fixed, entries[i].x, entries[i].y,
                   entries[i].w, entries[i].h);
        }
    }
    layout_write(root, entries, count);
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
    if (layer->_backgroundColor && layer->_backgroundColor->_a > 0.001 &&
        w > 0 && h > 0)
    {
        unsigned color = color_rgb(layer->_backgroundColor);
        iosim_fb_set_opacity(alpha * layer->_backgroundColor->_a);
        double radius = layer_key_value(layer, "cornerRadius",
                                        layer->_cornerRadius);
        if (radius > 0)
            iosim_fb_fill_round_rect(x, y, w, h, (int)(radius * scale + 0.5),
                                     color);
        else
            iosim_fb_fill_rect(x, y, w, h, color);
        iosim_fb_set_opacity(alpha);
    }
    if ([layer isKindOfClass:[CAGradientLayer class]])
    {
        CAGradientLayer *g = (CAGradientLayer *)layer;
        unsigned a = 0, b = 0;
        if (g->_colors && g->_colors->_count > 0)
        {
            a = color_rgb((UIColor *)[g->_colors objectAtIndex:0]);
            b = color_rgb((UIColor *)[g->_colors objectAtIndex:g->_colors->_count - 1]);
            if (layer->_cornerRadius > 0)
                iosim_fb_fill_linear_gradient_round_rect(
                    x, y, w, h, (int)(layer->_cornerRadius * scale + 0.5), a,
                    b, g->_startPoint.x, g->_startPoint.y, g->_endPoint.x,
                    g->_endPoint.y);
            else
                iosim_fb_fill_linear_gradient(x, y, w, h, a, b,
                                              g->_startPoint.x,
                                              g->_startPoint.y,
                                              g->_endPoint.x,
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

static int g_render_offscreen;
static UIView *g_no_transform_view;

static void render_view(UIView *view, double originX, double originY,
                        double scale, double parentAlpha)
{
    if (!view || view->_hidden)
        return;

    if (view == (UIView *)g_keyWindow)
        iosim_layout_apply(view);

    if (view->_needsLayout)
    {
        view->_needsLayout = NO;
        [view layoutSubviews];
    }

    double layerOpacity = view->_layer
        ? layer_key_value(view->_layer, "opacity", view->_layer->_opacity)
        : 1.0;
    double alpha = parentAlpha * current_alpha(view) * layerOpacity;
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

    CGAffineTransform tf = view->_transform;
    int rotated = (tf.b != 0.0 || tf.c != 0.0);
    if (rotated && view != g_no_transform_view && w > 0 && h > 0)
    {
        /* A rotated view is rendered into an offscreen pass and then
         * composited with the affine transform around its center. */
        void *state = iosim_fb_begin_offscreen((unsigned)w, (unsigned)h);
        if (state)
        {
            UIView *saved = g_no_transform_view;
            g_no_transform_view = view;
            g_render_offscreen++;
            render_view(view, -frame.origin.x, -frame.origin.y, scale, 1.0);
            g_render_offscreen--;
            g_no_transform_view = saved;
            int bw = 0, bh = 0;
            unsigned *buf = iosim_fb_end_offscreen(state, &bw, &bh);
            if (buf)
            {
                double cx = w / 2.0, cy = h / 2.0;
                double ftx = x + cx - (tf.a * cx + tf.c * cy) + tf.tx * scale;
                double fty = y + cy - (tf.b * cx + tf.d * cy) + tf.ty * scale;
                iosim_fb_blit_affine(buf, bw, bh, tf.a, tf.b, tf.c, tf.d,
                                     ftx, fty, alpha);
                iosim_fb_free_offscreen(buf);
            }
            return;
        }
    }
    if (!g_render_offscreen &&
        (tf.a != 1.0 || tf.b != 0.0 || tf.c != 0.0 || tf.d != 1.0 ||
         tf.tx != 0.0 || tf.ty != 0.0))
    {
        double sx = __builtin_sqrt(tf.a * tf.a + tf.b * tf.b);
        double sy = __builtin_sqrt(tf.c * tf.c + tf.d * tf.d);
        if (sx <= 0) sx = 1;
        if (sy <= 0) sy = 1;
        double cx = x + w / 2.0 + tf.tx * scale;
        double cy = y + h / 2.0 + tf.ty * scale;
        w = (int)(w * sx + 0.5);
        h = (int)(h * sy + 0.5);
        x = (int)(cx - w / 2.0 + 0.5);
        y = (int)(cy - h / 2.0 + 0.5);
    }

    int clipped = 0;
    if ((view->_clipsToBounds || (view->_layer && view->_layer->_masksToBounds) ||
         [view isKindOfClass:[UIScrollView class]]) && w > 0 && h > 0)
        clipped = iosim_fb_push_clip(x, y, w, h);

    if (view->_layer && view->_layer->_shadowOpacity > 0.001 &&
        w > 0 && h > 0)
    {
        double radius = view->_layer->_shadowRadius * scale;
        if (radius < 1)
            radius = 1;
        int ox = (int)(view->_layer->_shadowOffset.width * scale);
        int oy = (int)(view->_layer->_shadowOffset.height * scale);
        int corner = view->_layer
            ? (int)(layer_key_value(view->_layer, "cornerRadius",
                                    view->_layer->_cornerRadius) * scale + 0.5)
            : 0;
        unsigned shadowColor = view->_layer->_shadowColor
                                   ? color_rgb(view->_layer->_shadowColor)
                                   : 0x000000;
        int steps = 8;
        for (int s = steps; s >= 1; s--)
        {
            double t = (double)s / steps;
            int grow = (int)(radius * t + 0.5);
            double shade = view->_layer->_shadowOpacity * 0.16 *
                           (1.0 - t * 0.55);
            iosim_fb_set_opacity(alpha * shade);
            iosim_fb_fill_round_rect(x + ox - grow, y + oy - grow,
                                     w + 2 * grow, h + 2 * grow,
                                     corner + grow, shadowColor);
        }
        iosim_fb_set_opacity(alpha);
    }

    if (view->_backgroundColor && view->_backgroundColor->_a > 0.001 &&
        w > 0 && h > 0)
    {
        unsigned color = color_rgb(view->_backgroundColor);
        iosim_fb_set_opacity(alpha * view->_backgroundColor->_a);
        double radius = view->_layer
            ? layer_key_value(view->_layer, "cornerRadius",
                              view->_layer->_cornerRadius)
            : 0;
        if (radius > 0)
            iosim_fb_fill_round_rect(x, y, w, h, (int)(radius * scale + 0.5),
                                     color);
        else
            iosim_fb_fill_rect(x, y, w, h, color);
        iosim_fb_set_opacity(alpha);
    }

    if (view->_layer)
    {
        int order[16];
        int n = view->_layer->_sublayerCount;
        for (int i = 0; i < n && i < 16; i++)
            order[i] = i;
        for (int i = 1; i < n && i < 16; i++)
        {
            int key = order[i];
            CALayer *keyLayer = (CALayer *)view->_layer->_sublayers[key];
            int j = i - 1;
            while (j >= 0)
            {
                CALayer *other = (CALayer *)view->_layer->_sublayers[order[j]];
                if (other->_zPosition <= keyLayer->_zPosition)
                    break;
                order[j + 1] = order[j];
                j--;
            }
            order[j + 1] = key;
        }
        for (int i = 0; i < n && i < 16; i++)
            render_layer((CALayer *)view->_layer->_sublayers[order[i]],
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


    if ([view isKindOfClass:[UITableView class]])
    {
        UITableView *table = (UITableView *)view;
        double tableScrollY = table->_contentOffset.y;
        double cursor = 0;
        long sections = table_sections(table);
        int headerAscent = 0, headerDescent = 0, headerLine = 0;
        iosim_fb_font_metrics(IOSIM_FONT_REGULAR, 13, scale, &headerAscent,
                              &headerDescent, &headerLine);
        for (long section = 0; section < sections; section++)
        {
            id headerTitle = table_header_title(table, section);
            double headerHeight = table_header_height(table, section);
            if (headerHeight > 0)
            {
                int hy = y + (int)((cursor - tableScrollY) * scale + 0.5);
                int hh = (int)(headerHeight * scale + 0.5);
                if (headerTitle)
                {
                    iosim_fb_set_opacity(alpha);
                    iosim_fb_font_text(x + (int)(16 * scale),
                                       hy + hh / 2 + headerAscent / 2,
                                       iosim_string_cstr(headerTitle),
                                       IOSIM_FONT_REGULAR, 13, scale,
                                       0x8e8e93);
                }
                cursor += headerHeight;
            }
        long rows = table_rows(table, section);
        for (long i = 0; i < rows; i++)
        {
            NSIndexPath *path =
                [NSIndexPath indexPathForRow:i inSection:section];
            double rowHeight = table_row_height(table, path);
            int ry = y + (int)((cursor - tableScrollY) * scale + 0.5);
            int rh = (int)(rowHeight * scale + 0.5);
            UITableViewCell *cell = nil;
            if (table->_dataSource &&
                [table->_dataSource respondsToSelector:
                    @selector(tableView:cellForRowAtIndexPath:)])
            {
                SEL sel = @selector(tableView:cellForRowAtIndexPath:);
                cell = (UITableViewCell *)((id (*)(id, void *, id, id))objc_msgSend)(
                    table->_dataSource, (void *)sel, table, path);
            }
            if (cell)
            {
                cell->_frame = CGRectMake(0, cursor - tableScrollY,
                                          frame.size.width, rowHeight);
                [cell setFrame:cell->_frame];
                UIColor *savedBackground = cell->_backgroundColor;
                if (section == table->_selectedSection &&
                    i == table->_selectedRow)
                    cell->_backgroundColor = [UIColor
                        colorWithRed:0.17 green:0.18 blue:0.20 alpha:1.0];
                render_view(cell, originX + frame.origin.x,
                            originY + frame.origin.y, scale, alpha);
                cell->_backgroundColor = savedBackground;
            }
            iosim_fb_set_opacity(alpha);
            iosim_fb_fill_rect(x + (int)(16 * scale), ry + rh - 1,
                               w - (int)(16 * scale), 1, 0x38383a);
            if (cell && cell->_accessoryType == 1)
            {
                int cx = x + w - (int)(22 * scale);
                int cy = ry + rh / 2;
                iosim_fb_draw_line(cx, cy - (int)(6 * scale),
                                   cx + (int)(6 * scale), cy,
                                   (int)(2 * scale), 0x8e8e93);
                iosim_fb_draw_line(cx + (int)(6 * scale), cy, cx,
                                   cy + (int)(6 * scale), (int)(2 * scale),
                                   0x8e8e93);
            }
            else if (cell && cell->_accessoryType == 3)
            {
                int cx = x + w - (int)(24 * scale);
                int cy = ry + rh / 2;
                iosim_fb_draw_line(cx, cy, cx + (int)(5 * scale),
                                   cy + (int)(6 * scale),
                                   (int)(2.5 * scale), 0x0a84ff);
                iosim_fb_draw_line(cx + (int)(5 * scale), cy + (int)(6 * scale),
                                   cx + (int)(16 * scale),
                                   cy - (int)(6 * scale),
                                   (int)(2.5 * scale), 0x0a84ff);
            }
            cursor += rowHeight;
        }
        }
        iosim_fb_set_opacity(1.0);
    }

    if ([view isKindOfClass:[UIActivityIndicatorView class]])
    {
        UIActivityIndicatorView *spinner = (UIActivityIndicatorView *)view;
        int cx = x + w / 2, cy = y + h / 2;
        int inner, outer, thick;
        unsigned color;
        double fade_scale = 1.0;
        if (spinner->_style == 2)
        {
            /* Deprecated gray style: a 20 pt spinner. On a dark surface it
             * reads as translucent black, so the blades are dimmed. */
            inner = (int)(4.8333 * scale + 0.5);
            outer = (int)(8.5 * scale + 0.5);
            thick = (int)(2.6667 * scale + 0.5);
            color = spinner->_color ? color_rgb(spinner->_color) : 0x000000;
            if (!spinner->_color)
                fade_scale = 0.35;
        }
        else
        {
            inner = (int)(w * 0.22);
            outer = (int)(w * 0.42);
            thick = (int)(3 * scale);
            color = spinner->_color ? color_rgb(spinner->_color) : 0xffffff;
        }
        double phase = spinner->_animating
                           ? iosim_now() - (long)iosim_now() : 0;
        for (int i = 0; i < 8; i++)
        {
            double a = (i * 45.0 - 90.0) * 3.14159265358979323846 / 180.0;
            double tail = (i + 8 - phase * 8.0);
            while (tail >= 8)
                tail -= 8;
            double fade = 0.18 + 0.82 * (tail / 8.0);
            iosim_fb_set_opacity(alpha * fade * fade_scale);
            iosim_fb_draw_line(cx + (int)(__builtin_cos(a) * inner),
                               cy + (int)(__builtin_sin(a) * inner),
                               cx + (int)(__builtin_cos(a) * outer),
                               cy + (int)(__builtin_sin(a) * outer),
                               thick, color);
        }
        iosim_fb_set_opacity(alpha);
    }
    else if ([view isKindOfClass:[UIPageControl class]])
    {
        UIPageControl *pc = (UIPageControl *)view;
        double spacing = (53.0 / 3.0) * scale;
        double total = (pc->_numberOfPages - 1) * spacing;
        double start = x + w / 2.0 + 0.5 - total / 2;
        int r = (int)(4.0 * scale + 0.5);
        int cy = y + h / 2;
        for (long i = 0; i < pc->_numberOfPages; i++)
        {
            int cx = (int)(start + i * spacing + 0.5);
            if (i == pc->_currentPage)
            {
                unsigned color = pc->_currentPageTintColor
                                     ? color_rgb(pc->_currentPageTintColor)
                                     : 0xffffff;
                iosim_fb_fill_circle(cx, cy, r, color);
            }
            else if (pc->_pageTintColor)
            {
                iosim_fb_fill_circle(cx, cy, r,
                                     color_rgb(pc->_pageTintColor));
            }
            else
            {
                /* Unselected dots are 45% white in the current design. */
                iosim_fb_set_opacity(alpha * 0.45);
                iosim_fb_fill_circle(cx, cy, r, 0xffffff);
                iosim_fb_set_opacity(alpha);
            }
        }
    }
    else if ([view isKindOfClass:[UISegmentedControl class]])
    {
        UISegmentedControl *seg = (UISegmentedControl *)view;
        int custom_tint = seg->_tintColor != nil;
        if (custom_tint)
            iosim_fb_fill_round_rect(x, y, w, h, h / 2,
                                     color_rgb(seg->_tintColor));
        else
        {
            /* Glass track; the tint and alpha are measured so the
             * composite lands on the captured color. */
            iosim_fb_set_opacity(alpha * (29.0 / 255.0));
            iosim_fb_fill_round_rect(x, y, w, h, h / 2, 0xe7eaf6);
            iosim_fb_set_opacity(alpha);
        }
        if (seg->_itemCount > 0)
        {
            int segW = w / seg->_itemCount;
            if (seg->_selectedSegmentIndex >= 0)
            {
                int sx = x + (int)(seg->_selectedSegmentIndex * segW);
                if (custom_tint)
                    iosim_fb_fill_round_rect(sx + (int)(2 * scale),
                                             y + (int)(2 * scale),
                                             segW - (int)(4 * scale),
                                             h - (int)(4 * scale),
                                             (h - (int)(4 * scale)) / 2,
                                             0x636366);
                else
                {
                    /* Selected pill over the glass track. */
                    iosim_fb_set_opacity(alpha * (74.0 / 255.0));
                    iosim_fb_fill_round_rect(sx + (int)(2 * scale),
                                             y + (int)(2 * scale),
                                             segW - (int)(4 * scale),
                                             h - (int)(4 * scale),
                                             (h - (int)(4 * scale)) / 2,
                                             0xf3f2fb);
                    iosim_fb_set_opacity(alpha);
                }
            }
            for (int i = 0; i < seg->_itemCount; i++)
            {
                const char *title = iosim_string_cstr(seg->_items[i]);
                if (!title)
                    continue;
                int tw = iosim_fb_font_text_width(title, IOSIM_FONT_REGULAR,
                                                  13, scale);
                int asc = 0, desc = 0, lh = 0;
                iosim_fb_font_metrics(IOSIM_FONT_REGULAR, 13, scale, &asc,
                                      &desc, &lh);
                iosim_fb_font_text(x + i * segW + (segW - tw) / 2,
                                   y + (h - lh) / 2 + asc, title,
                                   IOSIM_FONT_REGULAR, 13, scale, 0xffffff);
            }
        }
    }
    else if ([view isKindOfClass:[UISwitch class]])
    {
        UISwitch *sw = (UISwitch *)view;
        /* The current switch is a 63 x 28 capsule with a 36.33 x 23.33
         * white knob, anchored at the frame origin. */
        int tw = (int)(63.0 * scale + 0.5);
        int th = (int)(28.0 * scale + 0.5);
        int kw = (int)(36.3333 * scale + 0.5);
        int kh = (int)(23.3333 * scale + 0.5);
        int inset = (int)(2.3333 * scale + 0.5);
        if (inset * 2 + kh > th)
            inset = (th - kh) / 2;
        int kx = sw->_on ? x + tw - kw - inset : x + inset;
        int ky = y + inset;
        if (sw->_on)
        {
            unsigned track = sw->_onTintColor
                                 ? color_rgb(sw->_onTintColor)
                                 : 0x30d158;
            iosim_fb_fill_round_rect(x, y, tw, th, th / 2, track);
        }
        else
        {
            /* The off track is a glass fill over the backdrop. */
            iosim_fb_set_opacity(alpha * (74.0 / 255.0));
            iosim_fb_fill_round_rect(x, y, tw, th, th / 2, 0xf2f1fa);
            iosim_fb_set_opacity(alpha);
        }
        iosim_fb_fill_round_rect(kx, ky, kw, kh, kh / 2, 0xffffff);
    }
    else if ([view isKindOfClass:[UISlider class]])
    {
        UISlider *slider = (UISlider *)view;
        int trackH = (int)(5.6667 * scale + 0.5);
        int ty = y + h / 2 - trackH / 2;
        if (!slider->_maxTrackTintColor)
        {
            /* The unfilled track is a glass fill over the backdrop. */
            iosim_fb_set_opacity(alpha * (27.0 / 255.0));
            iosim_fb_fill_round_rect(x, ty, w, trackH, trackH / 2,
                                     0xeef0ea);
            iosim_fb_set_opacity(alpha);
        }
        else
            iosim_fb_fill_round_rect(x, ty, w, trackH, trackH / 2,
                                     color_rgb(slider->_maxTrackTintColor));
        double span = slider->_maximumValue - slider->_minimumValue;
        double t = span > 0 ? (slider->_value - slider->_minimumValue) / span
                            : 0;
        if (t < 0) t = 0;
        if (t > 1) t = 1;
        /* The thumb is a wide glass lozenge, not a circle. */
        int thumbW = (int)(36.3333 * scale + 0.5);
        int thumbH = (int)(23.3333 * scale + 0.5);
        int usable = w - thumbW;
        if (usable < 0)
            usable = 0;
        int cx = x + thumbW / 2 + (int)(usable * t);
        int cy = y + h / 2 + (int)(0.6667 * scale + 0.5);
        unsigned minColor = slider->_minTrackTintColor
                                ? color_rgb(slider->_minTrackTintColor)
                                : 0x0091ff;
        int fillW = thumbW / 2 + (int)(usable * t);
        if (fillW > 0)
            iosim_fb_fill_round_rect(x, ty, fillW, trackH, trackH / 2,
                                     minColor);
        /* The real track sits on a half-pixel boundary; its top and bottom
         * rows carry a quarter-strength edge. */
        int cap = trackH / 2;
        int midW = w - 2 * cap;
        if (midW > 0)
        {
            if (!slider->_maxTrackTintColor)
            {
                iosim_fb_set_opacity(alpha * (27.0 / 255.0) * 0.26);
                iosim_fb_fill_rect(x + cap, ty - 1, midW, 1, 0xeef0ea);
                iosim_fb_fill_rect(x + cap, ty + trackH, midW, 1, 0xeef0ea);
            }
            else
            {
                iosim_fb_set_opacity(alpha * 0.26);
                iosim_fb_fill_rect(x + cap, ty - 1, midW, 1,
                                   color_rgb(slider->_maxTrackTintColor));
                iosim_fb_fill_rect(x + cap, ty + trackH, midW, 1,
                                   color_rgb(slider->_maxTrackTintColor));
            }
            int blueW = fillW - cap;
            if (blueW > midW)
                blueW = midW;
            if (blueW > 0)
            {
                iosim_fb_set_opacity(alpha * 0.26);
                iosim_fb_fill_rect(x + cap, ty - 1, blueW, 1, minColor);
                iosim_fb_fill_rect(x + cap, ty + trackH, blueW, 1, minColor);
            }
            iosim_fb_set_opacity(alpha);
        }
        for (int s = 4; s >= 1; s--)
        {
            int grow = (int)(s * 3.0 * scale / 3.0 + 0.5);
            iosim_fb_set_opacity(alpha * 0.030);
            iosim_fb_fill_round_rect(cx - thumbW / 2 - grow,
                                     cy - thumbH / 2 - grow +
                                         (int)(1.5 * scale + 0.5),
                                     thumbW + 2 * grow, thumbH + 2 * grow,
                                     thumbH / 2 + grow, 0x000000);
        }
        iosim_fb_set_opacity(alpha);
        iosim_fb_fill_round_rect(cx - thumbW / 2, cy - thumbH / 2, thumbW,
                                 thumbH, thumbH / 2,
                                 slider->_thumbTintColor
                                     ? color_rgb(slider->_thumbTintColor)
                                     : 0xffffff);
    }
    else if ([view isKindOfClass:[UIProgressView class]])
    {
        UIProgressView *pv = (UIProgressView *)view;
        int trackH = (int)(4.0 * scale + 0.5);
        /* The bar sits at the top of the view's bounds. */
        int ty = y;
        if (!pv->_trackTintColor)
        {
            /* Unfilled track: a glass fill over the backdrop. */
            iosim_fb_set_opacity(alpha * (41.0 / 255.0));
            iosim_fb_fill_round_rect(x, ty, w, trackH, trackH / 2,
                                     0xf7f5fa);
            iosim_fb_set_opacity(alpha);
        }
        else
            iosim_fb_fill_round_rect(x, ty, w, trackH, trackH / 2,
                                     color_rgb(pv->_trackTintColor));
        unsigned fill = pv->_progressTintColor
                            ? color_rgb(pv->_progressTintColor)
                            : 0x0091ff;
        double p = pv->_progress;
        if (p < 0) p = 0;
        if (p > 1) p = 1;
        int fw = (int)(w * p + 0.5);
        if (fw > 0)
        {
            if (pv->_progressTintColor)
                iosim_fb_fill_round_rect(x, ty, fw, trackH, trackH / 2,
                                         fill);
            else
            {
                /* The default fill carries a slight vertical sheen. */
                iosim_fb_fill_linear_gradient_round_rect(
                    x, ty, fw, trackH, trackH / 2, 0x008df9, 0x0091ff,
                    0.0, 0.0, 0.0, 1.0);
            }
        }
    }

    if ([view isKindOfClass:[UITextField class]])
    {
        UITextField *field = (UITextField *)view;
        const char *text = string_cstr(field->_text);
        const char *placeholder = string_cstr(field->_placeholder);
        double points = field->_font ? field->_font->_size : 17.0;
        int style = field->_font && field->_font->_bold
                        ? IOSIM_FONT_BOLD : IOSIM_FONT_REGULAR;
        int ascent = 0, descent = 0, lineHeight = 0;
        iosim_fb_font_metrics(style, points, scale, &ascent, &descent,
                              &lineHeight);
        int tx = x;
        int baseline = y + (h - lineHeight) / 2 + ascent;
        unsigned color = field->_textColor ? color_rgb(field->_textColor)
                                           : 0xffffff;
        int textWidth = 0;
        if (text && *text)
        {
            if (field->_secureTextEntry)
            {
                unsigned long chars = strlen(text);
                int dot = (int)(4 * scale);
                int spacing = (int)(10 * scale);
                for (unsigned long i = 0; i < chars && i < 40; i++)
                    iosim_fb_fill_circle(tx + (int)(i * spacing) + dot,
                                         baseline - (int)(5 * scale), dot,
                                         color);
                textWidth = (int)(chars * spacing);
            }
            else
            {
                iosim_fb_font_text(tx, baseline, text, style, points, scale,
                                   color);
                textWidth = iosim_fb_font_text_width(text, style, points,
                                                     scale);
            }
        }
        else if (placeholder && *placeholder)
        {
            unsigned bg = field->_backgroundColor
                              ? color_rgb(field->_backgroundColor)
                              : 0x000000;
            double a = 0.28;
            unsigned pr = (unsigned)((((color >> 16) & 0xff) * a) +
                                     (((bg >> 16) & 0xff) * (1 - a)));
            unsigned pg = (unsigned)((((color >> 8) & 0xff) * a) +
                                     (((bg >> 8) & 0xff) * (1 - a)));
            unsigned pb = (unsigned)(((color & 0xff) * a) +
                                     ((bg & 0xff) * (1 - a)));
            iosim_fb_font_text(tx, baseline, placeholder, style, points, scale,
                               (pr << 16) | (pg << 8) | pb);
            textWidth = iosim_fb_font_text_width(placeholder, style, points,
                                                 scale);
        }
        if (field->_firstResponder)
        {
            int caretX = (text && *text)
                             ? tx + textWidth + (int)(1 * scale)
                             : x;
            int caretH = (int)(22 * scale);
            iosim_fb_fill_rect(caretX,
                               baseline - ascent - (int)(0.7 * scale + 0.5),
                               (int)(2 * scale), caretH, 0x426bf2);
        }
    }

    if ([view isKindOfClass:[UILabel class]])
    {
        UILabel *label = (UILabel *)view;
        const char *text = string_cstr(label->_text);
        if (text && getenv("IOSIM_DEBUG_TEXT"))
            printf("[text] %s at %d,%d %dx%d\n", text, x, y, w, h);
        if (text)
        {
            double points = label->_font ? label->_font->_size : 17.0;
            int style = label->_font && label->_font->_bold
                            ? IOSIM_FONT_BOLD : IOSIM_FONT_REGULAR;
            int ascent = 0, descent = 0, lineHeight = 0;
            iosim_fb_font_metrics(style, points, scale, &ascent, &descent,
                                  &lineHeight);
            unsigned color = label->_textColor ? color_rgb(label->_textColor)
                                               : 0xffffff;
            if (label->_numberOfLines != 1 && w > 0)
            {
                char lines[IOSIM_MAX_WRAP_LINES][256];
                int maxLines = label->_numberOfLines > 1
                                   ? label->_numberOfLines
                                   : IOSIM_MAX_WRAP_LINES;
                int n = wrap_text_lines(text, style, points, scale, w, lines,
                                        maxLines);
                int startY = y + (h - n * lineHeight) / 2;
                for (int i = 0; i < n; i++)
                {
                    int lw = iosim_fb_font_text_width(lines[i], style, points,
                                                      scale);
                    int tx = x;
                    if (label->_textAlignment == 1)
                        tx = x + (w - lw) / 2;
                    else if (label->_textAlignment == 2)
                        tx = x + w - lw;
                    iosim_fb_font_text(tx, startY + i * lineHeight + ascent,
                                       lines[i], style, points, scale, color);
                }
            }
            else
            {
                int textWidth = iosim_fb_font_text_width(text, style, points,
                                                         scale);
                while (textWidth > w && points > 8 && w > 0)
                {
                    points -= 0.5;
                    iosim_fb_font_metrics(style, points, scale, &ascent,
                                          &descent, &lineHeight);
                    textWidth = iosim_fb_font_text_width(text, style, points,
                                                         scale);
                }
                int tx = x;
                if (label->_textAlignment == 1)
                    tx = x + (w - textWidth) / 2;
                else if (label->_textAlignment == 2)
                    tx = x + w - textWidth;
                int baseline = y + (h - lineHeight) / 2 + ascent;
                iosim_fb_font_text(tx, baseline, text, style, points, scale,
                                   color);
            }
        }
    }

    if ([view isKindOfClass:[UITextView class]])
    {
        UITextView *editor = (UITextView *)view;
        const char *text = string_cstr(editor->_text);
        double points = editor->_font ? editor->_font->_size : 17.0;
        int style = editor->_font && editor->_font->_bold
                        ? IOSIM_FONT_BOLD : IOSIM_FONT_REGULAR;
        int ascent = 0, descent = 0, lineHeight = 0;
        iosim_fb_font_metrics(style, points, scale, &ascent, &descent,
                              &lineHeight);
        unsigned color = editor->_textColor ? color_rgb(editor->_textColor)
                                            : 0xffffff;
        int inset = (int)(12.0 * scale + 0.5);
        char lines[IOSIM_MAX_WRAP_LINES][256];
        int n = wrap_editable_lines(text ? text : "", style, points, scale,
                                    w - 2 * inset, lines,
                                    IOSIM_MAX_WRAP_LINES);
        int caretX = x + inset;
        int caretBaseline = y + inset + ascent;
        for (int i = 0; i < n; i++)
        {
            int tx = x + inset;
            int baseline = y + inset + i * lineHeight + ascent;
            iosim_fb_font_text(tx, baseline, lines[i], style, points, scale,
                               color);
            caretX = tx + iosim_fb_font_text_width(lines[i], style, points,
                                                   scale);
            caretBaseline = baseline;
        }
        if (g_firstResponder == editor)
            iosim_fb_fill_rect(caretX + (int)(1 * scale),
                               caretBaseline - ascent, (int)(2 * scale),
                               lineHeight, 0x426bf2);
    }

    double scrollX = 0, scrollY = 0;
    if ([view isKindOfClass:[UIScrollView class]])
    {
        UIScrollView *scroll = (UIScrollView *)view;
        scrollX = scroll->_contentOffset.x;
        scrollY = scroll->_contentOffset.y;
    }
    for (int i = 0; i < view->_subviewCount; i++)
    {
        UIView *sub = (UIView *)view->_subviews[i];
        render_view(sub, originX + frame.origin.x - scrollX,
                    originY + frame.origin.y - scrollY, scale, alpha);
    }
    if (view->_layer && view->_layer->_borderWidth > 0.001 &&
        view->_layer->_borderColor && w > 0 && h > 0)
    {
        int thickness = (int)(view->_layer->_borderWidth * scale + 0.5);
        if (thickness < 1)
            thickness = 1;
        int radius = (int)(view->_layer->_cornerRadius * scale + 0.5);
        if (radius * 2 > w)
            radius = w / 2;
        if (radius * 2 > h)
            radius = h / 2;
        unsigned border = color_rgb(view->_layer->_borderColor);
        iosim_fb_set_opacity(alpha * view->_layer->_borderColor->_a);
        if (radius <= 0)
        {
            iosim_fb_fill_rect(x, y, w, thickness, border);
            iosim_fb_fill_rect(x, y + h - thickness, w, thickness, border);
            iosim_fb_fill_rect(x, y, thickness, h, border);
            iosim_fb_fill_rect(x + w - thickness, y, thickness, h, border);
        }
        else
        {
            iosim_fb_fill_rect(x + radius, y, w - 2 * radius, thickness,
                               border);
            iosim_fb_fill_rect(x + radius, y + h - thickness,
                               w - 2 * radius, thickness, border);
            iosim_fb_fill_rect(x, y + radius, thickness, h - 2 * radius,
                               border);
            iosim_fb_fill_rect(x + w - thickness, y + radius, thickness,
                               h - 2 * radius, border);
            double centers[4][2] = {
                {x + radius, y + radius},
                {x + w - radius, y + radius},
                {x + w - radius, y + h - radius},
                {x + radius, y + h - radius}
            };
            double starts[4] = {3.14159265358979323846,
                                1.5 * 3.14159265358979323846,
                                0.0,
                                0.5 * 3.14159265358979323846};
            for (int c = 0; c < 4; c++)
            {
                double lastX = 0, lastY = 0;
                for (int i = 0; i <= 10; i++)
                {
                    double a = starts[c] + (i / 10.0) *
                               (0.5 * 3.14159265358979323846);
                    double px = centers[c][0] + radius * __builtin_cos(a);
                    double py = centers[c][1] + radius * __builtin_sin(a);
                    if (i > 0)
                        iosim_fb_draw_line((int)lastX, (int)lastY, (int)px,
                                           (int)py, thickness, border);
                    lastX = px;
                    lastY = py;
                }
            }
        }
        iosim_fb_set_opacity(alpha);
    }

    if (clipped)
        iosim_fb_pop_clip();
    iosim_fb_set_opacity(1.0);
}

static void draw_device_chrome(int fbWidth, double scale)
{
    (void)fbWidth;
    /* Status bar: time, cellular, Wi-Fi and battery. */
    int margin = (int)(24 * scale);
    int right = fbWidth - margin;
    double timeSize = getenv("IOSIM_TIME_SIZE") ? atof(getenv("IOSIM_TIME_SIZE"))
                                                : 18.0;
    double timeBaseline = getenv("IOSIM_TIME_BASELINE")
                              ? atof(getenv("IOSIM_TIME_BASELINE")) : 38.9;
    const char *statusTime = getenv("IOSIM_STATUS_TIME");
    if (!statusTime || !*statusTime)
        statusTime = "9:41";
    int timeWidth = iosim_fb_font_text_width(statusTime, IOSIM_FONT_SEMIBOLD,
                                             timeSize, scale);
    iosim_fb_font_text((int)(80.67 * scale) - timeWidth / 2,
                       (int)(timeBaseline * scale), statusTime,
                       IOSIM_FONT_SEMIBOLD, timeSize, scale, 0xffffff);
    /* Cellular signal placeholders, Wi-Fi and battery, measured from the
     * iPhone 18 Pro status bar. IOSIM_STATUS_SIGNAL=bars draws the white
     * override style; IOSIM_STATUS_BATTERY=charging draws the green battery. */
    const char *signalStyle = getenv("IOSIM_STATUS_SIGNAL");
    if (signalStyle && strcmp(signalStyle, "bars") == 0)
    {
        for (int i = 0; i < 4; i++)
            iosim_fb_fill_round_rect((int)((277.0 + i * 5.667) * scale +
                                           0.5),
                                     (int)((33.0 - i * 2.333) * scale + 0.5),
                                     (int)(3.33 * scale + 0.5),
                                     (int)((6.333 + i * 2.333) * scale +
                                           0.5),
                                     (int)(1.0 * scale), 0xffffff);
    }
    else
    {
        for (int i = 0; i < 4; i++)
            iosim_fb_fill_circle((int)((278.83 + i * 5.667) * scale),
                                 (int)(37.83 * scale), (int)(1.85 * scale),
                                 0x484c58);
    }
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
    const char *batteryStyle = getenv("IOSIM_STATUS_BATTERY");
    if (batteryStyle && strcmp(batteryStyle, "charging") == 0)
    {
        iosim_fb_fill_round_rect((int)(333.0 * scale), (int)(25.33 * scale),
                                 (int)(26.33 * scale), (int)(13.67 * scale),
                                 (int)(4.0 * scale), 0x34c759);
        iosim_fb_fill_round_rect((int)(360.0 * scale), (int)(29.67 * scale),
                                 (int)(2.0 * scale), (int)(5.0 * scale),
                                 (int)(1.0 * scale), 0x34c759);
        double boltX[6] = {348.0, 342.33, 346.1, 344.0, 349.67, 346.1};
        double boltY[6] = {25.33, 32.0, 32.0, 38.67, 32.0, 32.0};
        for (int i = 0; i < 6; i++)
        {
            boltX[i] *= scale;
            boltY[i] *= scale;
        }
        iosim_fb_fill_polygon(boltX, boltY, 6, 0x85868c);
    }
    else
    {
        iosim_fb_fill_round_rect((int)(333.0 * scale), (int)(25.33 * scale),
                                 (int)(26.33 * scale), (int)(13.67 * scale),
                                 (int)(4.0 * scale), 0xffffff);
        iosim_fb_fill_round_rect((int)(360.0 * scale), (int)(29.67 * scale),
                                 (int)(2.0 * scale), (int)(5.0 * scale),
                                 (int)(1.0 * scale), 0xffffff);
    }
}


/* --------------------------------------------------------- keyboard UI */

static int keyboard_visible(void)
{
    if (getenv("IOSIM_DEBUG_KEYBOARD"))
        printf("[keyboard] firstResponder=%p\n", g_firstResponder);
    return g_firstResponder != 0;
}

static int keyboard_is_number_pad(void)
{
    if (!g_firstResponder ||
        ![g_firstResponder isKindOfClass:[UITextField class]])
        return 0;
    int type = ((UITextField *)g_firstResponder)->_keyboardType;
    return type == 4 || type == 5 || type == 8;
}

static void kb_key_ring(int x, int y, int w, int h, double scale,
                        unsigned color, unsigned ring)
{
    int r = (int)(4.5 * scale);
    iosim_fb_fill_round_rect(x, y, w, h, r, ring);
    iosim_fb_fill_rect(x + 1, y + r, w - 2, h - 2 * r, color);
    iosim_fb_fill_round_rect(x + 1, y, w - 2, h, r - 1, color);
}

static void kb_key(int x, int y, int w, int h, double scale, unsigned color)
{
    kb_key_ring(x, y, w, h, scale, color, 0x2e2e33);
}

static void kb_label(const char *text, int cx, int cy, double size,
                     double scale, unsigned color)
{
    cy -= (int)(1.2 * scale + 0.5);
    int tw = iosim_fb_font_text_width(text, IOSIM_FONT_REGULAR, size, scale);
    int asc = 0, desc = 0, lh = 0;
    iosim_fb_font_metrics(IOSIM_FONT_REGULAR, size, scale, &asc, &desc, &lh);
    iosim_fb_font_text(cx - tw / 2, cy - lh / 2 + asc, text,
                       IOSIM_FONT_REGULAR, size, scale, color);
}

static void kb_label_spaced(const char *text, int cx, int cy, double size,
                            double spacing, double scale, unsigned color)
{
    int n = 0;
    int widths[16];
    const char *p = text;
    while (*p && n < 16)
    {
        char ch[2] = { *p, 0 };
        widths[n++] = iosim_fb_font_text_width(ch, IOSIM_FONT_REGULAR, size,
                                               scale);
        p++;
    }
    int total = 0;
    for (int i = 0; i < n; i++)
        total += widths[i];
    total += (int)((n > 1 ? n - 1 : 0) * spacing * scale);
    int asc = 0, desc = 0, lh = 0;
    iosim_fb_font_metrics(IOSIM_FONT_REGULAR, size, scale, &asc, &desc, &lh);
    int x = cx - total / 2;
    int y = cy - (int)(1.2 * scale + 0.5) - lh / 2 + asc;
    for (int i = 0; i < n; i++)
    {
        char ch[2] = { text[i], 0 };
        iosim_fb_font_text(x, y, ch, IOSIM_FONT_REGULAR, size, scale, color);
        x += widths[i] + (int)(spacing * scale + 0.5);
    }
}

static void kb_shift(int x, int y, int w, int h, double scale)
{
    int cx = x + w / 2, cy = y + h / 2;
    double pts[7][2] = {
        {0.0, -8.0}, {-10.2, 2.7}, {-4.8, 2.7}, {-4.8, 9.0},
        {4.8, 9.0}, {4.8, 2.7}, {10.2, 2.7}
    };
    double xs[7], ys[7];
    for (int i = 0; i < 7; i++)
    {
        xs[i] = cx - 1 + pts[i][0] * scale;
        ys[i] = cy + pts[i][1] * scale;
    }
    iosim_fb_fill_polygon(xs, ys, 7, 0xffffff);
}

static void kb_return(int x, int y, int w, int h, double scale)
{
    /* Apple's return glyph is a bottom shaft with a left arrowhead, a
     * right riser and a short hook back left across the top. Measured
     * from the real iPhone 18 Pro key: shaft at center+1.5pt, 18pt wide,
     * riser at +9pt, hook at -8.5pt, arrowhead barbs 6pt at 45 degrees. */
    int cx = x + w / 2, cy = y + h / 2;
    int t = (int)(1.5 * scale + 0.5);
    if (t < 1) t = 1;
    int base = cy + (int)(1.5 * scale + 0.5);
    int left = cx - (int)(9 * scale + 0.5);
    int right = cx + (int)(9 * scale + 0.5);
    int top = base - (int)(10 * scale + 0.5);
    int barb = (int)(6 * scale + 0.5);
    iosim_fb_draw_line(left, base, right, base, t, 0xffffff);
    iosim_fb_draw_line(right, base, right, top, t, 0xffffff);
    iosim_fb_draw_line(right, top, cx + (int)(1 * scale + 0.5), top, t,
                       0xffffff);
    iosim_fb_draw_line(left, base, left + barb, base - barb, t, 0xffffff);
    iosim_fb_draw_line(left, base, left + barb, base + barb, t, 0xffffff);
}

static void kb_backspace(int x, int y, int w, int h, double scale)
{
    int cx = x + w / 2, cy = y + h / 2;
    int t = (int)(2 * scale + 0.5);
    if (t < 1) t = 1;
    int lx = cx + 1 - (int)(9.2 * scale + 0.5);
    int px = cx + 1 - (int)(2.4 * scale + 0.5);
    int rx = cx + 1 + (int)(9.0 * scale + 0.5);
    int ty = cy - (int)(6.7 * scale + 0.5);
    int by = cy + (int)(8.0 * scale + 0.5);
    int my = cy + (int)(1.0 * scale + 0.5);
    iosim_fb_draw_line(lx, my, px, ty, t, 0xffffff);
    iosim_fb_draw_line(px, ty, rx, ty, t, 0xffffff);
    iosim_fb_draw_line(rx, ty, rx, by, t, 0xffffff);
    iosim_fb_draw_line(rx, by, px, by, t, 0xffffff);
    iosim_fb_draw_line(px, by, lx, my, t, 0xffffff);
    int e = (int)(3.1 * scale + 0.5);
    int q = (int)(3.2 * scale + 0.5);
    int ox = cx + 1 + (int)(1.6 * scale + 0.5);
    iosim_fb_draw_line(ox - e, cy - q, ox + e, cy + q, t, 0xffffff);
    iosim_fb_draw_line(ox - e, cy + q, ox + e, cy - q, t, 0xffffff);
}

static void kb_emoji(int cx, int cy, double scale)
{
    /* Filled smiley measured from the real key: white disc, two eyes,
     * a thick dark smile band, a white teeth crescent and the dark
     * open mouth below it. */
    iosim_fb_fill_circle(cx, cy, (int)(13.5 * scale + 0.5), 0xffffff);
    int ex = (int)(4.17 * scale + 0.5), ey = (int)(3.17 * scale + 0.5);
    int er = (int)(1.5 * scale + 0.5);
    if (er < 1) er = 1;
    iosim_fb_fill_circle(cx - ex, cy - ey, er, 0x202025);
    iosim_fb_fill_circle(cx + ex, cy - ey, er, 0x202025);
    int t = (int)(1.7 * scale + 0.5);
    if (t < 1) t = 1;
    int prevX = 0, prevY = 0;
    for (int i = 0; i <= 32; i++)
    {
        double xx = -8.3 + 16.6 * i / 32.0;
        double yy = 2.3 - 0.0145 * xx * xx;
        int px = cx + (int)(xx * scale);
        int py = cy + (int)(yy * scale);
        if (i > 0)
            iosim_fb_draw_line(prevX, prevY, px, py, t, 0x202025);
        iosim_fb_fill_circle(px, py, (t + 1) / 2, 0x202025);
        prevX = px;
        prevY = py;
    }
    double poly[66][2];
    int n = 0;
    for (int i = 0; i <= 32; i++)
    {
        double xx = -8.3 + 16.6 * i / 32.0;
        poly[n][0] = xx;
        poly[n][1] = 5.5 - 0.046 * xx * xx;
        n++;
    }
    for (int i = 32; i >= 0; i--)
    {
        double xx = -8.3 + 16.6 * i / 32.0;
        poly[n][0] = xx;
        poly[n][1] = 9.3 - 0.086 * xx * xx;
        n++;
    }
    double xs[66], ys[66];
    for (int i = 0; i < n; i++)
    {
        xs[i] = cx + poly[i][0] * scale;
        ys[i] = cy + poly[i][1] * scale;
    }
    iosim_fb_fill_polygon(xs, ys, n, 0x202025);
}

static void kb_mic(int cx, int cy, double scale)
{
    /* Capsule, U-shaped cradle, stem and base from the real key. */
    iosim_fb_fill_round_rect(cx - (int)(4.0 * scale + 0.5),
                             cy - (int)(14.2 * scale + 0.5),
                             (int)(8.0 * scale + 0.5),
                             (int)(16.8 * scale + 0.5),
                             (int)(4.0 * scale + 0.5), 0xffffff);
    int t = (int)(2.3 * scale + 0.5);
    if (t < 1) t = 1;
    int ax = (int)(7.8 * scale + 0.5);
    int ay0 = cy - (int)(3.5 * scale + 0.5);
    int ay1 = cy + (int)(1.0 * scale + 0.5);
    iosim_fb_draw_line(cx - ax, ay0, cx - ax, ay1, t, 0xffffff);
    iosim_fb_draw_line(cx + ax, ay0, cx + ax, ay1, t, 0xffffff);
    int r = (int)(7.8 * scale + 0.5);
    for (int i = 0; i <= 24; i++)
    {
        double a = 3.14159265358979323846 +
                   i * (3.14159265358979323846 / 24.0);
        iosim_fb_fill_circle(cx + (int)(r * __builtin_cos(a)),
                             ay1 - (int)(r * __builtin_sin(a)),
                             (int)(1.15 * scale + 0.5), 0xffffff);
    }
    int sw = (int)(1.0 * scale + 0.5);
    if (sw < 2) sw = 2;
    iosim_fb_fill_rect(cx - sw / 2, cy + (int)(8.3 * scale + 0.5), sw,
                       (int)(4.7 * scale + 0.5), 0xffffff);
    iosim_fb_fill_round_rect(cx - (int)(5.7 * scale + 0.5),
                             cy + (int)(12.7 * scale + 0.5),
                             (int)(11.4 * scale + 0.5),
                             (int)(1.3 * scale + 0.5),
                             (int)(0.7 * scale + 0.5), 0xffffff);
}

static void kb_panel(int fbW, int fbH, double scale, int topPx,
                     unsigned color)
{
    /* iOS 26 keyboard panel: 26 pt top corners, 58 pt bottom corners,
     * flush with the bottom of the screen. */
    enum { N = 12 };
    double pts[4 * N + 4][2];
    int n = 0;
    double r1 = 26.0 * scale, r2 = 58.0 * scale;
    double top = topPx, bot = fbH;
    for (int i = 0; i <= N; i++)
    {
        double a = (180.0 + 90.0 * i / N) * 3.14159265358979323846 / 180.0;
        pts[n][0] = r1 + r1 * __builtin_cos(a);
        pts[n][1] = top + r1 + r1 * __builtin_sin(a);
        n++;
    }
    for (int i = 0; i <= N; i++)
    {
        double a = (270.0 + 90.0 * i / N) * 3.14159265358979323846 / 180.0;
        pts[n][0] = fbW - r1 + r1 * __builtin_cos(a);
        pts[n][1] = top + r1 + r1 * __builtin_sin(a);
        n++;
    }
    for (int i = 0; i <= N; i++)
    {
        double a = (0.0 + 90.0 * i / N) * 3.14159265358979323846 / 180.0;
        pts[n][0] = fbW - r2 + r2 * __builtin_cos(a);
        pts[n][1] = bot - r2 + r2 * __builtin_sin(a);
        n++;
    }
    for (int i = 0; i <= N; i++)
    {
        double a = (90.0 + 90.0 * i / N) * 3.14159265358979323846 / 180.0;
        pts[n][0] = r2 + r2 * __builtin_cos(a);
        pts[n][1] = bot - r2 + r2 * __builtin_sin(a);
        n++;
    }
    double xs[4 * N + 4], ys[4 * N + 4];
    for (int i = 0; i < n; i++)
    {
        xs[i] = pts[i][0];
        ys[i] = pts[i][1];
    }
    iosim_fb_fill_polygon(xs, ys, n, color);
}

static void kb_panel_highlight(int fbW, double scale, int topPx)
{
    /* Measured glass edge: a bright 1 px line, then a short gradient into
     * the panel fill, following the 26 pt top corners. */
    static const int stops[8] = {0, 1, 2, 3, 7, 10, 13, 19};
    static const unsigned cols[8] = {0x3e3f45, 0x36373d, 0x303135, 0x242529,
                                     0x222328, 0x212227, 0x202126, 0x202025};
    int rows = (int)(19 * scale / 3.0 + 0.5);
    if (rows < 4)
        rows = 4;
    double r1 = 26.0 * scale;
    for (int dy = 0; dy < rows; dy++)
    {
        double t = 19.0 * dy / (rows > 1 ? rows - 1 : 1);
        int i = 0;
        while (i < 6 && t > stops[i + 1])
            i++;
        double f = (t - stops[i]) / (stops[i + 1] - stops[i]);
        unsigned c0 = cols[i], c1 = cols[i + 1];
        unsigned rr = (unsigned)(((c0 >> 16 & 0xff) +
                                  ((int)(c1 >> 16 & 0xff) -
                                   (int)(c0 >> 16 & 0xff)) * f) + 0.5);
        unsigned gg = (unsigned)(((c0 >> 8 & 0xff) +
                                  ((int)(c1 >> 8 & 0xff) -
                                   (int)(c0 >> 8 & 0xff)) * f) + 0.5);
        unsigned bb = (unsigned)(((c0 & 0xff) +
                                  ((int)(c1 & 0xff) -
                                   (int)(c0 & 0xff)) * f) + 0.5);
        int inset = 0;
        if (dy < r1)
            inset = (int)(r1 - __builtin_sqrt(r1 * r1 -
                                              (r1 - dy) * (r1 - dy)));
        if (inset < 0)
            inset = 0;
        iosim_fb_fill_rect(inset, topPx + dy, fbW - 2 * inset, 1,
                           (rr << 16) | (gg << 8) | bb);
    }
}

static void draw_qwerty(int fbW, int fbH, double scale)
{
    double W = fbW / scale, H = fbH / scale;
    double top = H - 324.0;
    int topPx = (int)(top * scale + 0.5);
    double panelTop = H - 328.0;
    int panelTopPx = (int)(panelTop * scale + 0.5);
    kb_panel(fbW, fbH, scale, panelTopPx, 0x202025);
    kb_panel_highlight(fbW, scale, panelTopPx);
    int predTop = topPx + (int)(9 * scale);
    int predH = (int)(24 * scale);
    for (int i = 1; i < 3; i++)
        iosim_fb_fill_rect((int)(W * i / 3.0 * scale - 1 * scale), predTop,
                           (int)(1 * scale), predH, 0x313136);
    double rowTop = top + 48.0;
    double rowH = 43.0, rowGap = 11.0;
    double margin = 6.7, keyW = 33.2, keyGap = 6.3;
    static const char *r1 = "QWERTYUIOP";
    for (int i = 0; i < 10; i++)
    {
        int x = (int)((margin + i * (keyW + keyGap)) * scale + 0.5);
        int y = (int)(rowTop * scale + 0.5);
        int w = (int)(keyW * scale + 0.5);
        int h = (int)(rowH * scale + 0.5);
        kb_key(x, y, w, h, scale, 0x444448);
        char label[2] = { r1[i], 0 };
        kb_label(label, x + w / 2, y + h / 2, 22, scale, 0xffffff);
    }
    double row2Top = rowTop + rowH + rowGap;
    double m2 = 26.3, w2 = 33.2, g2 = 6.3;
    static const char *r2 = "ASDFGHJKL";
    for (int i = 0; i < 9; i++)
    {
        int x = (int)((m2 + i * (w2 + g2)) * scale + 0.5);
        int y = (int)(row2Top * scale + 0.5);
        int w = (int)(w2 * scale + 0.5);
        int h = (int)(rowH * scale + 0.5);
        kb_key(x, y, w, h, scale, 0x444448);
        char label[2] = { r2[i], 0 };
        kb_label(label, x + w / 2, y + h / 2, 22, scale, 0xffffff);
    }
    double row3Top = row2Top + rowH + rowGap;
    int y3 = (int)(row3Top * scale + 0.5);
    int h3 = (int)(rowH * scale + 0.5);
    double m3 = 7.0, shiftW = 44.67, delW = 44.67, w3 = 33.0, g3 = 6.5;
    double gBig = (W - 2 * m3 - shiftW - delW - 7 * w3 - 6 * g3) / 2.0;
    int sx = (int)(m3 * scale);
    int sw = (int)(shiftW * scale);
    kb_key(sx, y3, sw, h3, scale, 0x444448);
    kb_shift(sx, y3, sw, h3, scale);
    static const char *r3 = "ZXCVBNM";
    for (int i = 0; i < 7; i++)
    {
        int x = (int)((m3 + shiftW + gBig + i * (w3 + g3)) * scale + 0.5);
        int w = (int)(w3 * scale + 0.5);
        kb_key(x, y3, w, h3, scale, 0x444448);
        char label[2] = { r3[i], 0 };
        kb_label(label, x + w / 2, y3 + h3 / 2, 22, scale, 0xffffff);
    }
    int dx = (int)((W - m3 - delW) * scale);
    int dw = (int)(delW * scale);
    kb_key(dx, y3, dw, h3, scale, 0x444448);
    kb_backspace(dx, y3, dw, h3, scale);
    double row4Top = row3Top + rowH + rowGap;
    int y4 = (int)(row4Top * scale + 0.5);
    int h4 = (int)(rowH * scale + 0.5);
    double m4 = 6.7, numW = 92.7, spaceW = 191.3, retW = 92.7, g4 = 6.0;
    int nx = (int)(m4 * scale);
    int nw = (int)(numW * scale);
    kb_key(nx, y4, nw, h4, scale, 0x444448);
    kb_label("123", nx + nw / 2, y4 + h4 / 2, 17.5, scale, 0xffffff);
    int spx = (int)((m4 + numW + g4) * scale);
    int spw = (int)(spaceW * scale);
    kb_key(spx, y4, spw, h4, scale, 0x444448);
    int rx = (int)((W - m4 - retW) * scale);
    int rw = (int)(retW * scale);
    kb_key(rx, y4, rw, h4, scale, 0x444448);
    kb_return(rx, y4, rw, h4, scale);
    kb_emoji((int)(42.3 * scale + 0.5), (int)(833.8 * scale + 0.5), scale);
    kb_mic((int)(359.2 * scale + 0.5), (int)(833.2 * scale + 0.5), scale);
}

static void kb_delete_icon(int cx, int cy, double scale)
{
    /* Large bare backspace used by the number pad. */
    int t = (int)(2.0 * scale + 0.5);
    if (t < 1) t = 1;
    int lx = cx - (int)(11.0 * scale + 0.5);
    int px = cx - (int)(2.8 * scale + 0.5);
    int rx = cx + (int)(11.7 * scale + 0.5);
    int ty = cy - (int)(9.0 * scale + 0.5);
    int by = cy + (int)(9.0 * scale + 0.5);
    iosim_fb_draw_line(lx, cy, px, ty, t, 0xffffff);
    iosim_fb_draw_line(px, ty, rx, ty, t, 0xffffff);
    iosim_fb_draw_line(rx, ty, rx, by, t, 0xffffff);
    iosim_fb_draw_line(rx, by, px, by, t, 0xffffff);
    iosim_fb_draw_line(px, by, lx, cy, t, 0xffffff);
    int e = (int)(3.5 * scale + 0.5);
    int q = (int)(4.5 * scale + 0.5);
    int ox = cx + (int)(2.2 * scale + 0.5);
    int xt = (int)(1.7 * scale + 0.5);
    if (xt < 1) xt = 1;
    iosim_fb_draw_line(ox - e, cy - q, ox + e, cy + q, xt, 0xffffff);
    iosim_fb_draw_line(ox - e, cy + q, ox + e, cy - q, xt, 0xffffff);
}

static void draw_number_pad(int fbW, int fbH, double scale)
{
    double W = fbW / scale, H = fbH / scale;
    double panelTop = H - 302.0;
    int panelTopPx = (int)(panelTop * scale + 0.5);
    kb_panel(fbW, fbH, scale, panelTopPx, 0x202025);
    kb_panel_highlight(fbW, scale, panelTopPx);
    double m = 4.67, kw = 126.17, gap = 6.33;
    double rowTop = panelTop + 24.0, kh = 48.0, vgap = 6.0;
    static const char *digits[10] = {
        "1", "2", "3", "4", "5", "6", "7", "8", "9", "0"
    };
    static const char *letters[10] = {
        "", "ABC", "DEF", "GHI", "JKL", "MNO", "PQRS", "TUV", "WXYZ", ""
    };
    for (int i = 0; i < 12; i++)
    {
        int row = i / 3, col = i % 3;
        double kx = m + col * (kw + gap);
        double ky = rowTop + row * (kh + vgap);
        int x = (int)(kx * scale + 0.5);
        int y = (int)(ky * scale + 0.5);
        int w = (int)(kw * scale + 0.5);
        int h = (int)(kh * scale + 0.5);
        int isBottom = row == 3;
        int key = i;
        if (isBottom && col == 1)
            key = 9;
        if (isBottom && col == 0)
            continue;
        if (isBottom && col == 2)
        {
            kb_delete_icon(x + w / 2, y + h / 2, scale);
            continue;
        }
        kb_key_ring(x, y, w, h, scale, 0x444448, 0x3c3c40);
        if (isBottom)
        {
            kb_label(digits[key], x + w / 2, y + (int)(20.2 * scale + 0.5),
                     22, scale, 0xffffff);
            continue;
        }
        kb_label(digits[key], x + w / 2, y + (int)(20.2 * scale + 0.5),
                 22, scale, 0xffffff);
        if (letters[key][0])
            kb_label_spaced(letters[key], x + w / 2,
                            y + (int)(39.7 * scale + 0.5), 10, 1.4, scale,
                            0xffffff);
    }
}

static int draw_keyboard(int fbW, int fbH, double scale)
{
    if (!keyboard_visible() || scale <= 0)
        return 0;
    if (keyboard_is_number_pad())
    {
        draw_number_pad(fbW, fbH, scale);
        return 0;
    }
    draw_qwerty(fbW, fbH, scale);
    return 0;
}

static int keyboard_handle_tap(int px, int py, int fbW, int fbH,
                               double scale)
{
    if (!keyboard_visible() || scale <= 0)
        return 0;
    double x = px / scale, y = py / scale;
    double W = fbW / scale, H = fbH / scale;
    if (keyboard_is_number_pad())
    {
        double kbH = 302.0;
        double top = H - kbH;
        if (y < top)
            return 0;
        double m = 4.67, kw = 126.17, gap = 6.33;
        double rowTop = top + 24.0, kh = 48.0, vgap = 6.0;
        int col = (int)((x - m) / (kw + gap));
        int row = (int)((y - rowTop) / (kh + vgap));
        if (col < 0 || col > 2 || row < 0 || row > 3)
            return 1;
        if (row < 3)
        {
            char buf[2];
            buf[0] = "123456789"[row * 3 + col];
            buf[1] = 0;
            [g_firstResponder
                insertText:[NSString stringWithUTF8String:buf]];
        }
        else if (col == 1)
        {
            [g_firstResponder insertText:[NSString stringWithUTF8String:"0"]];
        }
        else if (col == 2)
        {
            [g_firstResponder deleteBackward];
        }
        return 1;
    }
    double top = H - 324.0;
    if (y < top)
        return 0;
    double rowTop = top + 48.0, rowH = 43.0, rowGap = 11.0;
    int row = (int)((y - rowTop) / (rowH + rowGap));
    double localY = y - (rowTop + row * (rowH + rowGap));
    if (row < 0 || row > 3 || localY > rowH)
        return 1;
    char buf[2] = {0, 0};
    if (row == 0)
    {
        double margin = 6.7, kw = 33.2, gap = 6.3;
        int i = (int)((x - margin) / (kw + gap));
        if (i >= 0 && i < 10)
        {
            buf[0] = "QWERTYUIOP"[i];
            [g_firstResponder insertText:[NSString stringWithUTF8String:buf]];
        }
        return 1;
    }
    if (row == 1)
    {
        double m2 = 26.3, w2 = 33.2, g2 = 6.3;
        int i = (int)((x - m2) / (w2 + g2));
        if (i >= 0 && i < 9)
        {
            buf[0] = "ASDFGHJKL"[i];
            [g_firstResponder insertText:[NSString stringWithUTF8String:buf]];
        }
        return 1;
    }
    double m3 = 7.0, shiftW = 44.67, delW = 44.67, w3 = 33.0, g3 = 6.5;
    double gBig = (W - 2 * m3 - shiftW - delW - 7 * w3 - 6 * g3) / 2.0;
    if (row == 2)
    {
        if (x < m3 + shiftW)
            return 1;
        int i = (int)((x - m3 - shiftW - gBig) / (w3 + g3));
        if (i >= 0 && i < 7)
        {
            buf[0] = "ZXCVBNM"[i];
            [g_firstResponder insertText:[NSString stringWithUTF8String:buf]];
            return 1;
        }
        if (x > W - m3 - delW)
        {
            [g_firstResponder deleteBackward];
            return 1;
        }
        return 1;
    }
    double m4 = 6.7, numW = 92.7, spaceW = 191.3, retW = 92.7;
    if (x < m4 + numW)
        return 1;
    if (x > W - m4 - retW)
    {
        if ([g_firstResponder isKindOfClass:[UITextView class]])
            [g_firstResponder insertText:[NSString stringWithUTF8String:"\n"]];
        else
            [g_firstResponder
                sendActionsForControlEvents:UIControlEventEditingDidEndOnExit];
        return 1;
    }
    if (x > m4 + numW + 6.0)
        [g_firstResponder insertText:[NSString stringWithUTF8String:" "]];
    return 1;
}

/* -------------------------------------------------------- springboard UI *//* -------------------------------------------------------- springboard UI */

/* ----------------------------------------------------------- SpringBoard */

#include "shell_wallpaper.h"

extern void *malloc(unsigned long size);
extern void free(void *ptr);
extern void iosim_fb_paste_xrgb(const unsigned *pixels);
extern void iosim_fb_fill_field(int x, int y, int w, int h, int radius,
                                const unsigned *grid, int gw, int gh);
extern void iosim_fb_fill_squircle(int x, int y, int w, int h, unsigned color);
extern void iosim_fb_fill_squircle_gradient(int x, int y, int w, int h,
                                            unsigned top, unsigned bottom);
extern void iosim_fb_blit_xrgb_scaled(const unsigned *src, int sw, int sh,
                                      int x, int y, int w, int h,
                                      double opacity);
extern int open(const char *path, int flags, ...);
extern long read(int fd, void *buf, unsigned long count);
extern int close(int fd);
extern int iosim_spawn_app(const char *exe, const char *bundle, const char *home);
extern int iosim_spawn_wait(int pid);
extern void iosim_suspend_self(void);
extern int iosim_resume_app(int pid);
extern int iosim_terminate_app(int pid);
extern void iosim_on_switcher_request(void (*handler)(void));
extern int iosim_request_switcher(void);
extern void iosim_event_close(void);

#define SHELL_MAX_APPS 40

struct shell_app {
    char name[64];
    char exe[512];
    char bundle[128];
    char home[384];
    char snapshot[1024];   /* last framebuffer captured when suspending */
    int stock;   /* artwork id, -1 for the generic placeholder */
    int dock;
    int pid;     /* suspended process, or 0 */
};

static struct shell_app g_shell_apps[SHELL_MAX_APPS];
static int g_shell_app_count;
static int g_home_page;

static int shell_grid_count(void)
{
    int count = 0;
    for (int i = 0; i < g_shell_app_count; i++)
        if (!g_shell_apps[i].dock)
            count++;
    return count;
}

static int shell_page_count(void)
{
    int grid = shell_grid_count();
    return grid > 0 ? (grid + 15) / 16 : 1;
}
static unsigned *g_shell_wallpaper;
static int g_shell_wallpaper_w, g_shell_wallpaper_h;

/* Measured layout on the 402 pt iPhone 18 Pro home screen. */
#define SHELL_ICON_PT   64.0
#define SHELL_MARGIN_PT (30.0 + 1.0 / 6.0)
#define SHELL_PITCH_PT  92.5556

static const double shell_row_center[4] = {
    121.8333, 222.1667, 322.5, 422.8333
};

static unsigned shell_wallpaper_cell(int gx, int gy)
{
    if (gx < 0) gx = 0;
    if (gx >= SHELL_WALLPAPER_W) gx = SHELL_WALLPAPER_W - 1;
    if (gy < 0) gy = 0;
    if (gy >= SHELL_WALLPAPER_H) gy = SHELL_WALLPAPER_H - 1;
    return shell_wallpaper_grid[gy * SHELL_WALLPAPER_W + gx];
}

static void shell_wallpaper_build(int w, int h)
{
    if (g_shell_wallpaper && g_shell_wallpaper_w == w &&
        g_shell_wallpaper_h == h)
        return;
    free(g_shell_wallpaper);
    g_shell_wallpaper = (unsigned *)malloc((unsigned long)w * h * 4);
    if (!g_shell_wallpaper)
        return;
    g_shell_wallpaper_w = w;
    g_shell_wallpaper_h = h;
    for (int y = 0; y < h; y++)
    {
        double fy = (y + 0.5) * SHELL_WALLPAPER_H / h - 0.5;
        int y0 = (int)__builtin_floor(fy);
        double ty = fy - y0;
        unsigned *row = g_shell_wallpaper + (unsigned long)y * w;
        for (int x = 0; x < w; x++)
        {
            double fx = (x + 0.5) * SHELL_WALLPAPER_W / w - 0.5;
            int x0 = (int)__builtin_floor(fx);
            double tx = fx - x0;
            unsigned c00 = shell_wallpaper_cell(x0, y0);
            unsigned c10 = shell_wallpaper_cell(x0 + 1, y0);
            unsigned c01 = shell_wallpaper_cell(x0, y0 + 1);
            unsigned c11 = shell_wallpaper_cell(x0 + 1, y0 + 1);
            unsigned r = (unsigned)((((c00 >> 16) & 0xFF) * (1 - tx) +
                                     ((c10 >> 16) & 0xFF) * tx) * (1 - ty) +
                                    (((c01 >> 16) & 0xFF) * (1 - tx) +
                                     ((c11 >> 16) & 0xFF) * tx) * ty + 0.5);
            unsigned g = (unsigned)((((c00 >> 8) & 0xFF) * (1 - tx) +
                                     ((c10 >> 8) & 0xFF) * tx) * (1 - ty) +
                                    (((c01 >> 8) & 0xFF) * (1 - tx) +
                                     ((c11 >> 8) & 0xFF) * tx) * ty + 0.5);
            unsigned b = (unsigned)(((c00 & 0xFF) * (1 - tx) +
                                     (c10 & 0xFF) * tx) * (1 - ty) +
                                    ((c01 & 0xFF) * (1 - tx) +
                                     (c11 & 0xFF) * tx) * ty + 0.5);
            row[x] = (r << 16) | (g << 8) | b;
        }
    }
}

static void shell_copy(char *dst, int cap, const char *src)
{
    int i = 0;
    if (src)
        while (src[i] && i < cap - 1)
        {
            dst[i] = src[i];
            i++;
        }
    dst[i] = 0;
}

static void shell_add_app(const char *name, const char *exe, const char *bundle,
                          const char *home, int stock, int dock)
{
    if (g_shell_app_count >= SHELL_MAX_APPS)
        return;
    struct shell_app *a = &g_shell_apps[g_shell_app_count++];
    shell_copy(a->name, (int)sizeof(a->name), name);
    shell_copy(a->exe, (int)sizeof(a->exe), exe);
    shell_copy(a->bundle, (int)sizeof(a->bundle), bundle);
    shell_copy(a->home, (int)sizeof(a->home), home);
    a->stock = stock;
    a->dock = dock;
    a->pid = 0;
    a->snapshot[0] = 0;
}

static void shell_load_apps(void)
{
    static const char *defaults[] = {
        "HelloSim", "GraphicsApp", "ListApp", "AutoLayout",
        "TextInput", "Alert", "NumberPad", "Controls"
    };
    /* Installing an app rewrites the manifest; suspended apps must keep
     * their pid and cached frame so their icons still resume in place. */
    struct saved_app {
        char bundle[128];
        char name[128];
        int pid;
        char snapshot[1024];
    };
    static struct saved_app saved[SHELL_MAX_APPS];
    int saved_count = 0;
    for (int i = 0; i < g_shell_app_count; i++)
    {
        if (g_shell_apps[i].pid <= 0)
            continue;
        struct saved_app *keep = &saved[saved_count++];
        shell_copy(keep->bundle, (int)sizeof(keep->bundle),
                   g_shell_apps[i].bundle);
        shell_copy(keep->name, (int)sizeof(keep->name), g_shell_apps[i].name);
        keep->pid = g_shell_apps[i].pid;
        shell_copy(keep->snapshot, (int)sizeof(keep->snapshot),
                   g_shell_apps[i].snapshot);
    }
    g_shell_app_count = 0;
    shell_add_app("Fitness", "", "", "", 0, 0);
    shell_add_app("Watch", "", "", "", 1, 0);
    shell_add_app("Reminders", "", "", "", 2, 0);
    shell_add_app("Files", "", "", "", 3, 0);
    shell_add_app("Preview", "", "", "", 4, 0);
    shell_add_app("Utilities", "", "", "", 5, 0);
    shell_add_app("Contacts", "", "", "", 6, 0);

    const char *manifest = getenv("IOSIM_SHELL_APPS");
    int loaded = 0;
    if (manifest && *manifest)
    {
        int fd = open(manifest, 0);
        if (fd >= 0)
        {
            static char buf[16384];
            long n = read(fd, buf, sizeof(buf) - 1);
            close(fd);
            if (n > 0)
            {
                buf[n] = 0;
                long i = 0;
                while (i < n)
                {
                    long start = i;
                    while (i < n && buf[i] != '\n')
                        i++;
                    long end = i;
                    if (i < n)
                        i++;
                    while (start < end && (buf[start] == ' ' ||
                                           buf[start] == '\r'))
                        start++;
                    if (start >= end || buf[start] == '#')
                        continue;
                    /* name|executable|bundle-id|data-home */
                    char fields[4][512];
                    int nf = 0;
                    long j = start;
                    while (nf < 4)
                    {
                        long fs = j;
                        while (j < end && buf[j] != '|')
                            j++;
                        long fe = j, k = 0;
                        while (fs < fe && k < 511)
                            fields[nf][k++] = buf[fs++];
                        fields[nf][k] = 0;
                        nf++;
                        if (j < end)
                            j++;
                        else
                            break;
                    }
                    if (fields[0][0])
                    {
                        shell_add_app(fields[0], nf > 1 ? fields[1] : "",
                                      nf > 2 ? fields[2] : "",
                                      nf > 3 ? fields[3] : "", -1, 0);
                        loaded = 1;
                    }
                }
            }
        }
    }
    if (!loaded && (!manifest || !*manifest))
        for (unsigned i = 0; i < sizeof(defaults) / sizeof(defaults[0]); i++)
            shell_add_app(defaults[i], "", "", "", -1, 0);

    shell_add_app("Safari", "", "", "", 7, 1);
    shell_add_app("Messages", "", "", "", 8, 1);

    for (int i = 0; i < g_shell_app_count; i++)
    {
        for (int j = 0; j < saved_count; j++)
        {
            if (saved[j].pid <= 0)
                continue;
            int match;
            if (g_shell_apps[i].bundle[0] && saved[j].bundle[0])
                match = strcmp(g_shell_apps[i].bundle, saved[j].bundle) == 0;
            else
                match = strcmp(g_shell_apps[i].name, saved[j].name) == 0;
            if (!match)
                continue;
            g_shell_apps[i].pid = saved[j].pid;
            shell_copy(g_shell_apps[i].snapshot,
                       (int)sizeof(g_shell_apps[i].snapshot),
                       saved[j].snapshot);
            saved[j].pid = 0;
            break;
        }
    }
    /* A name that vanished from the manifest no longer has a home screen
     * slot; stop its process instead of leaving it suspended forever. */
    for (int j = 0; j < saved_count; j++)
        if (saved[j].pid > 0)
            iosim_terminate_app(saved[j].pid);
}

static void shell_label(const char *name, int cx, int baseline, double scale)
{
    int tw = iosim_fb_font_text_width(name, IOSIM_FONT_REGULAR, 12, scale);
    int x = cx - tw / 2;
    iosim_fb_font_text(x, baseline, name, IOSIM_FONT_REGULAR, 12, scale,
                       0xffffff);
}

static void shell_ring(int cx, int cy, int radius, int thickness,
                       unsigned color)
{
    iosim_fb_set_opacity(1.0);
    iosim_fb_fill_circle(cx, cy, radius, color);
    iosim_fb_fill_circle(cx, cy, radius - thickness, 0x000000);
}

/* Extent of the icon face (a rounded rect of side s and corner radius r)
 * along the column or row c, as continuous coordinates. */
static void shell_face_span(int s, int r, int c, double *lo, double *hi)
{
    double t = c + 0.5;
    *lo = 0;
    *hi = s;
    if (t < r)
        *lo = r - __builtin_sqrt((double)r * r - (r - t) * (r - t));
    if (t > s - r)
        *hi = s - r + __builtin_sqrt((double)r * r - (t - (s - r)) * (t - (s - r)));
}

/* The measured placeholder: a white face with a square grid of hairlines
 * (inset 12 px, at 60 and 131 px, border at 179 px on a 192 px icon), a
 * 2 px light crosshair through the middle, three concentric circles and
 * the square's diagonals. All lines are clipped by the face. */
static void shell_placeholder_icon(int x, int y, int s, double scale)
{
    (void)scale;
    int r = (int)(s * 0.2237 + 0.5);
    iosim_fb_fill_linear_gradient_round_rect(x, y, s, s, r, 0xffffff, 0xededed,
                                             0.0, 0.62, 0.0, 1.0);
    int u = s / 192;
    if (u < 1) u = 1;
    int th = u;
    unsigned line = 0x9a9a9a;
    int m0 = 12 * u, m1 = 60 * u, m2 = 131 * u, m3 = 179 * u;
    int mid = 96 * u;
    int cols[4] = {m0, m1, m2, m3};
    for (int i = 0; i < 4; i++)
    {
        double lo, hi;
        shell_face_span(s, r, cols[i], &lo, &hi);
        if (lo < m0) lo = m0;
        if (hi > m3 + 1) hi = m3 + 1;
        iosim_fb_fill_rect(x + cols[i], y + (int)(lo + 0.5), th,
                           (int)(hi - lo + 0.5), line);
        shell_face_span(s, r, cols[i], &lo, &hi);
        if (lo < m0) lo = m0;
        if (hi > m3 + 1) hi = m3 + 1;
        iosim_fb_fill_rect(x + (int)(lo + 0.5), y + cols[i],
                           (int)(hi - lo + 0.5), th, line);
    }
    double lo, hi;
    shell_face_span(s, r, mid - 1, &lo, &hi);
    iosim_fb_fill_rect(x + mid - 1, y + (int)(lo + 0.5), 2,
                       (int)(hi - lo + 0.5), 0xcdcdcd);
    shell_face_span(s, r, mid - 1, &lo, &hi);
    iosim_fb_fill_rect(x + (int)(lo + 0.5), y + mid - 1,
                       (int)(hi - lo + 0.5), 2, 0xcdcdcd);
    int cx = x + mid, cy = y + mid;
    iosim_fb_stroke_circle(cx, cy, 36 * u, th, line);
    iosim_fb_stroke_circle(cx, cy, 50 * u, th, line);
    iosim_fb_stroke_circle(cx, cy, 84 * u, th, line);
    iosim_fb_draw_line(x + m0 + 1, y + m0 + 1, x + m3, y + m3, th, line);
    iosim_fb_draw_line(x + m3, y + m0 + 1, x + m0 + 1, y + m3, th, line);
}

static void shell_stock_icon_draw(int kind, int x, int y, int s, double scale);

/* Stock icons are composed inside a rounded-rect layer so artwork such as
 * the Safari dial can run to the icon edge and be masked exactly like the
 * real icon composer output. */
static void shell_stock_icon(int kind, int x, int y, int s, double scale)
{
    if (kind < 0)
    {
        shell_stock_icon_draw(kind, x, y, s, scale);
        return;
    }
    int r = (int)(s * 0.2237 + 0.5);
    void *state = iosim_fb_begin_offscreen((unsigned)s, (unsigned)s);
    if (!state)
    {
        shell_stock_icon_draw(kind, x, y, s, scale);
        return;
    }
    shell_stock_icon_draw(kind, 0, 0, s, scale);
    iosim_fb_mask_round_rect(0, 0, s, s, r);
    int bw = 0, bh = 0;
    unsigned *buf = iosim_fb_end_offscreen(state, &bw, &bh);
    if (buf)
    {
        iosim_fb_set_opacity(1.0);
        iosim_fb_blit_affine(buf, bw, bh, 1.0, 0.0, 0.0, 1.0, x, y, 1.0);
        iosim_fb_free_offscreen(buf);
    }
}

static void shell_stock_icon_draw(int kind, int x, int y, int s, double scale)
{
    int cx = x + s / 2, cy = y + s / 2;
    int r = (int)(s * 0.2237 + 0.5);
    (void)scale;
    switch (kind)
    {
    case 0: /* Fitness: measured activity rings on a graphite face */
    {
        iosim_fb_fill_linear_gradient_round_rect(x, y, s, s, r, 0x1f1f1e, 0x0e0e0f,
                                              0.0, 0.0, 0.0, 1.0);
        double u = s / 192.0;
        int ix = x + s / 2, iy = y + s / 2;
        /* Each ring is an arc with a colour ramp and rounded caps. Stops are
         * positions along the arc, measured from the captured ring. */
        static const unsigned outer_colors[] = {0xff1f1f, 0xff0027, 0xff0066,
                                                0xff0092, 0xff0092};
        static const double outer_stops[] = {0.0, 0.21, 0.45, 0.72, 1.0};
        static const unsigned mid_colors[] = {0x84ff00, 0x9bfe00, 0xb6ff00,
                                              0xccff00, 0xccff00};
        static const double mid_stops[] = {0.0, 0.3, 0.55, 0.8, 1.0};
        static const unsigned inner_colors[] = {0x00f1f4, 0x00ffde, 0x00ffab,
                                                0x00ffa0, 0x00ffa0};
        static const double inner_stops[] = {0.0, 0.3, 0.55, 0.8, 1.0};
        iosim_fb_fill_arc_gradient(ix, iy, (int)(68.5 * u + 0.5),
                                   (int)(17 * u + 0.5), 285.0, 353.0,
                                   outer_colors, outer_stops, 5);
        iosim_fb_fill_arc_gradient(ix, iy, (int)(46 * u + 0.5),
                                   (int)(16 * u + 0.5), 294.0, 343.0,
                                   mid_colors, mid_stops, 5);
        iosim_fb_fill_arc_gradient(ix, iy, (int)(25 * u + 0.5),
                                   (int)(14 * u + 0.5), 292.0, 354.0,
                                   inner_colors, inner_stops, 5);
        /* Rounded caps at both ends of each ring. */
        double caps[6][4] = {{285.0 + 353.0, 68.5, 0xff0092, 17},
                             {285.0, 68.5, 0xff1f1f, 17},
                             {294.0 + 343.0, 46.0, 0xccff00, 16},
                             {294.0, 46.0, 0x84ff00, 16},
                             {292.0 + 354.0, 25.0, 0x00ffa0, 14},
                             {292.0, 25.0, 0x00f1f4, 14}};
        for (int i = 0; i < 6; i++)
        {
            double a = caps[i][0] * 3.14159265358979323846 / 180.0;
            iosim_fb_fill_circle(ix + (int)(__builtin_cos(a) * caps[i][1] * u),
                                 iy + (int)(__builtin_sin(a) * caps[i][1] * u),
                                 (int)(caps[i][3] * u / 2 + 0.5),
                                 (unsigned)caps[i][2]);
        }
        break;
    }
    case 1: /* Watch: the measured band loop and case */
    {
        iosim_fb_fill_linear_gradient_round_rect(x, y, s, s, r, 0x1f1f1e, 0x0e0e0f,
                                              0.0, 0.0, 0.0, 1.0);
        double u = s / 192.0;
        int ix = x + s / 2, iy = y + s / 2;
        /* silver band loop, lit from the top */
        static const unsigned band_colors[] = {0xc3c6cc, 0xa2a5aa, 0xd0d3d8,
                                               0xeef2f8, 0xc3c6cc};
        static const double band_stops[] = {0.0, 0.25, 0.5, 0.75, 1.0};
        iosim_fb_fill_ellipse_ring_gradient(ix + (int)(1 * u), iy,
                                            (int)(63 * u + 0.5),
                                            (int)(70 * u + 0.5),
                                            (int)(7 * u + 0.5), band_colors,
                                            band_stops, 5);
        /* case with its vertical metal ramp */
        int cxs = ix + (int)(-65 * u), cys = iy + (int)(-54 * u);
        iosim_fb_fill_linear_gradient_round_rect(cxs, cys, (int)(24 * u),
                                                 (int)(111 * u),
                                                 (int)(12 * u), 0xb6b6b6,
                                                 0x979797, 0.0, 0.0, 0.0, 1.0);
        /* specular highlight near the top of the case */
        iosim_fb_set_opacity(0.55);
        iosim_fb_fill_ellipse(cxs + (int)(15 * u), cys + (int)(13 * u),
                              (int)(6 * u), (int)(11 * u), 0xeef0f4);
        iosim_fb_set_opacity(1.0);
        /* the round crown button */
        iosim_fb_fill_circle(cxs + (int)(13 * u), cys + (int)(37 * u),
                             (int)(8.5 * u + 0.5), 0xdedede);
        iosim_fb_stroke_circle(cxs + (int)(13 * u), cys + (int)(37 * u),
                               (int)(8.5 * u + 0.5), (int)(1.2 * u + 0.5),
                               0xa8a8a8);
        break;
    }
    case 2: /* Reminders */
    {
        iosim_fb_fill_linear_gradient_round_rect(x, y, s, s, r, 0xffffff, 0xf1f1f1,
                                              0.0, 0.0, 0.0, 1.0);
        static const unsigned dots[3] = {0x0a84ff, 0xff453a, 0xff9f0a};
        for (int i = 0; i < 3; i++)
        {
            int dy = y + (int)(s * (0.27 + i * 0.23));
            int dx = x + (int)(s * 0.24);
            iosim_fb_fill_circle(dx, dy, (int)(s * 0.062), dots[i]);
            iosim_fb_fill_circle(dx, dy, (int)(s * 0.030), 0xf7f7f7);
            iosim_fb_fill_round_rect(x + (int)(s * 0.36),
                                     dy - (int)(s * 0.012),
                                     (int)(s * 0.42), (int)(s * 0.024),
                                     (int)(s * 0.012), 0xcfcfd4);
        }
        break;
    }
    case 3: /* Files: the measured folder with its tab and inner sheet */
    {
        iosim_fb_fill_linear_gradient_round_rect(x, y, s, s, r, 0xffffff, 0xf4f4f4,
                                              0.0, 0.0, 0.0, 1.0);
        double u = s / 192.0;
        /* soft shadow under the folder */
        iosim_fb_set_opacity(0.10);
        iosim_fb_fill_round_rect(x + (int)(24 * u), y + (int)(46 * u),
                                 (int)(144 * u), (int)(114 * u),
                                 (int)(20 * u), 0x1b3550);
        iosim_fb_set_opacity(1.0);
        /* back panel + tab */
        iosim_fb_fill_round_rect(x + (int)(24 * u), y + (int)(40 * u),
                                 (int)(144 * u), (int)(112 * u),
                                 (int)(20 * u), 0x00a2ea);
        iosim_fb_fill_round_rect(x + (int)(24 * u), y + (int)(40 * u),
                                 (int)(62 * u), (int)(36 * u),
                                 (int)(14 * u), 0x00b4f7);
        /* the sheet peeking out of the folder */
        iosim_fb_fill_round_rect(x + (int)(33 * u), y + (int)(63 * u),
                                 (int)(126 * u), (int)(12 * u),
                                 (int)(6 * u), 0xfbfcfd);
        /* front panel with a top-to-bottom blue ramp */
        iosim_fb_fill_linear_gradient_round_rect(
            x + (int)(24 * u), y + (int)(70 * u), (int)(144 * u),
            (int)(84 * u), (int)(20 * u), 0x00b3f7, 0x0a7cff, 0.0, 0.0,
            0.0, 1.0);
        /* a faint highlight along the front panel's top edge */
        iosim_fb_set_opacity(0.30);
        iosim_fb_fill_round_rect(x + (int)(27 * u), y + (int)(71 * u),
                                 (int)(138 * u), (int)(3 * u),
                                 (int)(1 * u), 0xc4eeff);
        iosim_fb_set_opacity(1.0);
        break;
    }
    case 4: /* Preview: the photo thumbnail and its lens */
    {
        iosim_fb_fill_linear_gradient_round_rect(x, y, s, s, r, 0xfbfbfb, 0xe9e9ec,
                                              0.0, 0.0, 0.0, 1.0);
        double u = s / 192.0;
        /* the photo: a sky-to-dusk gradient with pink and amber clouds */
        iosim_fb_fill_linear_gradient_round_rect(
            x + (int)(28 * u), y + (int)(27 * u), (int)(130 * u),
            (int)(120 * u), (int)(22 * u), 0x21d2ff, 0x4a7cff, 0.0, 0.0,
            0.0, 0.75);
        iosim_fb_set_opacity(0.75);
        iosim_fb_fill_ellipse(x + (int)(60 * u), y + (int)(112 * u),
                              (int)(46 * u), (int)(34 * u), 0xff9fe6);
        iosim_fb_fill_ellipse(x + (int)(70 * u), y + (int)(146 * u),
                              (int)(40 * u), (int)(22 * u), 0xffb44d);
        iosim_fb_set_opacity(1.0);
        /* the glass dome, with a shadow on the photo and a lit rim */
        int lx = x + (int)(129 * u), ly = y + (int)(128 * u);
        iosim_fb_set_opacity(0.18);
        iosim_fb_fill_circle(lx + (int)(3 * u), ly + (int)(6 * u),
                             (int)(56 * u), 0x1a2440);
        iosim_fb_set_opacity(1.0);
        iosim_fb_fill_circle(lx, ly, (int)(55 * u + 0.5), 0xdfeefb);
        iosim_fb_set_opacity(0.75);
        iosim_fb_fill_circle(lx - (int)(5 * u), ly - (int)(7 * u),
                             (int)(47 * u), 0xa9dcff);
        iosim_fb_set_opacity(1.0);
        iosim_fb_stroke_circle(lx, ly, (int)(54 * u), (int)(2 * u + 0.5),
                               0x9fd6f2);
        iosim_fb_set_opacity(0.9);
        iosim_fb_stroke_circle(lx - (int)(2 * u), ly - (int)(2 * u),
                               (int)(49 * u), (int)(2 * u + 0.5), 0xffffff);
        iosim_fb_set_opacity(1.0);
        /* the lens barrel */
        iosim_fb_fill_circle(lx, ly, (int)(34 * u + 0.5), 0x101012);
        iosim_fb_stroke_circle(lx, ly, (int)(33 * u), (int)(6 * u + 0.5),
                               0x3a3a3d);
        iosim_fb_stroke_circle(lx, ly, (int)(29 * u), (int)(1.5 * u + 0.5),
                               0x6a6a70);
        /* the front element: a violet-pink reflection */
        iosim_fb_fill_circle(lx, ly, (int)(22 * u + 0.5), 0x8d7bf2);
        iosim_fb_set_opacity(0.85);
        iosim_fb_fill_ellipse(lx + (int)(3 * u), ly + (int)(5 * u),
                              (int)(16 * u), (int)(13 * u), 0xff9fe0);
        iosim_fb_fill_ellipse(lx - (int)(7 * u), ly - (int)(8 * u),
                              (int)(10 * u), (int)(8 * u), 0x9fd2ff);
        iosim_fb_set_opacity(1.0);
        /* specular highlights */
        iosim_fb_fill_circle(lx - (int)(24 * u), ly - (int)(23 * u),
                             (int)(3.5 * u + 0.5), 0xffffff);
        iosim_fb_set_opacity(0.9);
        iosim_fb_fill_ellipse(lx + (int)(30 * u), ly - (int)(32 * u),
                              (int)(13 * u), (int)(6 * u), 0xffffff);
        iosim_fb_fill_ellipse(lx + (int)(24 * u), ly + (int)(30 * u),
                              (int)(18 * u), (int)(7 * u), 0xffffff);
        iosim_fb_set_opacity(1.0);
        break;
    }
    case 5: /* Utilities: the brown folder with its two mini apps */
    {
        iosim_fb_fill_linear_gradient_round_rect(x, y, s, s, r, 0x7b5b41, 0x866244,
                                              0.0, 0.0, 0.0, 1.0);
        double u = s / 192.0;
        /* a soft folder bevel just inside the icon edge */
        iosim_fb_set_opacity(0.40);
        iosim_fb_fill_round_rect(x + (int)(4 * u), y + (int)(4 * u),
                                 (int)(184 * u), (int)(184 * u),
                                 (int)(40 * u), 0x9c7a58);
        iosim_fb_set_opacity(1.0);
        iosim_fb_fill_linear_gradient_round_rect(
            x + (int)(6 * u), y + (int)(6 * u), (int)(180 * u),
            (int)(180 * u), (int)(38 * u), 0x7b5b41, 0x866244, 0.0, 0.0,
            0.0, 1.0);
        /* Shortcuts: a violet square with the pink/blue glyph */
        iosim_fb_fill_linear_gradient_round_rect(
            x + (int)(29 * u), y + (int)(30 * u), (int)(39 * u),
            (int)(39 * u), (int)(10 * u), 0x5327d6, 0x8a3bbf, 0.0, 0.0,
            0.0, 1.0);
        double pxs[4] = {x + 48 * u, x + 61 * u, x + 48 * u, x + 35 * u};
        double pys[4] = {y + 33 * u, y + 46 * u, y + 59 * u, y + 46 * u};
        iosim_fb_fill_polygon(pxs, pys, 4, 0xff5fa8);
        double bxs[4] = {x + 48 * u, x + 57 * u, x + 48 * u, x + 39 * u};
        double bys[4] = {y + 44 * u, y + 53 * u, y + 62 * u, y + 53 * u};
        iosim_fb_set_opacity(0.75);
        iosim_fb_fill_polygon(bxs, bys, 4, 0x8a7bff);
        iosim_fb_set_opacity(1.0);
        /* Passwords: the black square with three keys */
        iosim_fb_fill_round_rect(x + (int)(77 * u), y + (int)(31 * u),
                                 (int)(39 * u), (int)(39 * u),
                                 (int)(10 * u), 0x171617);
        iosim_fb_fill_round_rect(x + (int)(76 * u), y + (int)(30 * u),
                                 (int)(41 * u), (int)(41 * u),
                                 (int)(11 * u), 0x8a8a8a);
        iosim_fb_fill_round_rect(x + (int)(77 * u), y + (int)(31 * u),
                                 (int)(39 * u), (int)(39 * u),
                                 (int)(10 * u), 0x171617);
        static const unsigned key_colors[3] = {0xffd60a, 0x30d158, 0x0a84ff};
        for (int k = 0; k < 3; k++)
        {
            int kx = x + (int)((84 + k * 8) * u);
            int ky = y + (int)(44 * u);
            iosim_fb_stroke_circle(kx, ky, (int)(4 * u + 0.5),
                                   (int)(2.5 * u + 0.5), key_colors[k]);
            iosim_fb_fill_rect(kx - (int)(1 * u), ky + (int)(3 * u),
                               (int)(2 * u + 0.5), (int)(11 * u),
                               key_colors[k]);
            iosim_fb_fill_rect(kx + (int)(1 * u), ky + (int)(9 * u),
                               (int)(3 * u), (int)(2 * u), key_colors[k]);
        }
        break;
    }
    case 6: /* Contacts: the avatar disc and the coloured index tabs */
    {
        iosim_fb_fill_linear_gradient_round_rect(x, y, s, s, r, 0xe8e8dc, 0xc9c8bb,
                                              0.0, 0.0, 0.0, 1.0);
        double u = s / 192.0;
        /* the three tabs, clipped by the icon mask on the right */
        iosim_fb_fill_round_rect(x + (int)(160 * u), y + (int)(10 * u),
                                 (int)(60 * u), (int)(60 * u),
                                 (int)(17 * u), 0x00c1f8);
        iosim_fb_fill_round_rect(x + (int)(160 * u), y + (int)(69 * u),
                                 (int)(60 * u), (int)(66 * u),
                                 (int)(17 * u), 0xff8600);
        iosim_fb_fill_round_rect(x + (int)(160 * u), y + (int)(134 * u),
                                 (int)(60 * u), (int)(52 * u),
                                 (int)(17 * u), 0x00dc33);
        /* the avatar disc with its soft lower shadow */
        int dx = x + (int)(85 * u), dy = y + (int)(94 * u);
        iosim_fb_set_opacity(0.25);
        iosim_fb_fill_circle(dx, dy + (int)(3 * u), (int)(60 * u), 0x77746a);
        iosim_fb_set_opacity(1.0);
        iosim_fb_fill_circle(dx, dy, (int)(59 * u + 0.5), 0xa6a399);
        /* head and shoulders */
        iosim_fb_fill_circle(x + (int)(85 * u), y + (int)(80 * u),
                             (int)(24.5 * u + 0.5), 0xffffff);
        iosim_fb_fill_ellipse(x + (int)(84 * u), y + (int)(138 * u),
                              (int)(37 * u), (int)(18 * u), 0xffffff);
        break;
    }
    case 7: /* Safari: the measured compass (dial r 76.5 px of 192) */
    {
        iosim_fb_fill_linear_gradient_round_rect(x, y, s, s, r, 0xffffff, 0xf4f4f4,
                                              0.0, 0.0, 0.0, 1.0);
        double u = s / 192.0;
        int ix = x + s / 2, iy = y + s / 2;
        int dial = (int)(76.5 * u + 0.5);
        iosim_fb_fill_circle_gradient(ix, iy, dial, 0x00b4ff, 0x1e8fff);
        iosim_fb_stroke_circle(ix, iy, dial - (int)(2 * u),
                               (int)(2.5 * u + 0.5), 0x007fe8);
        int th = (int)(2.0 * u + 0.5);
        if (th < 1) th = 1;
        for (int i = 0; i < 32; i++)
        {
            double a = i * 11.25 * 3.14159265358979323846 / 180.0;
            double c = __builtin_cos(a), sn = __builtin_sin(a);
            iosim_fb_draw_line((int)(ix + c * 57.5 * u),
                               (int)(iy + sn * 57.5 * u),
                               (int)(ix + c * 70.5 * u),
                               (int)(iy + sn * 70.5 * u), th, 0x55f7ff);
        }
        double ax = 0.70710678, ay = -0.70710678;
        double halfw = 11.0 * u;
        double b1x = ix + ay * halfw, b1y = iy - ax * halfw;
        double b2x = ix - ay * halfw, b2y = iy + ax * halfw;
        double nxs[3] = {b1x, b2x, ix + ax * 70.0 * u};
        double nys[3] = {b1y, b2y, iy + ay * 70.0 * u};
        iosim_fb_fill_polygon(nxs, nys, 3, 0xff0000);
        double wxs[3] = {b1x, b2x, ix - ax * 70.0 * u};
        double wys[3] = {b1y, b2y, iy - ay * 70.0 * u};
        iosim_fb_fill_polygon(wxs, wys, 3, 0xffffff);
        iosim_fb_fill_circle(ix, iy, (int)(5.5 * u + 0.5), 0xff8b8b);
        break;
    }
    case 8: /* Messages: measured bubble and tail */
    {
        iosim_fb_fill_linear_gradient_round_rect(x, y, s, s, r, 0x54f06c, 0x1fd03d,
                                              0.0, 0.0, 0.0, 1.0);
        double u = s / 192.0;
        int ex = x + (int)(95.5 * u + 0.5);
        int ey = y + (int)(92.0 * u + 0.5);
        int rx = (int)(69.5 * u + 0.5), ry = (int)(57.0 * u + 0.5);
        double txs[3] = {x + 40 * u, x + 26 * u, x + 64 * u};
        double tys[3] = {y + 118 * u, y + 152 * u, y + 142 * u};
        iosim_fb_fill_polygon(txs, tys, 3, 0xddf9e1);
        iosim_fb_set_opacity(0.12);
        iosim_fb_fill_ellipse(ex, ey + (int)(3 * u), rx + 1, ry + 1,
                              0x001000);
        iosim_fb_set_opacity(1.0);
        iosim_fb_fill_ellipse_gradient(ex, ey, rx, ry, 0xf6fef9, 0xdcf8e0);
        break;
    }
    default:
        shell_placeholder_icon(x, y, s, scale);
        break;
    }
}

static void shell_draw(int fbWidth, int fbHeight, double scale)
{
    shell_wallpaper_build(fbWidth, fbHeight);
    if (g_shell_wallpaper)
        iosim_fb_paste_xrgb(g_shell_wallpaper);
    else
        iosim_fb_clear(0x05070d);

    double W = fbWidth / scale;
    double pitch = (W - 2 * SHELL_MARGIN_PT - SHELL_ICON_PT) / 3.0;
    int s = (int)(SHELL_ICON_PT * scale + 0.5);
    int grid_index = 0;
    for (int i = 0; i < g_shell_app_count; i++)
    {
        struct shell_app *a = &g_shell_apps[i];
        if (a->dock)
            continue;
        int page = grid_index / 16;
        int page_slot = grid_index % 16;
        if (page == g_home_page)
        {
            int col = page_slot % 4, row = page_slot / 4;
            int cx = (int)((SHELL_MARGIN_PT + SHELL_ICON_PT / 2 + col * pitch) *
                           scale + 0.5);
            int cy = (int)(shell_row_center[row] * scale + 0.5);
            shell_stock_icon(a->stock, cx - s / 2, cy - s / 2, s, scale);
            int baseline = cy + s / 2 + (int)(16.1 * scale + 0.5);
            shell_label(a->name, cx, baseline, scale);
        }
        grid_index++;
    }

    /* Page dots sit between the grid and the search pill and are hidden for
     * a single page, as on the captured single-page home screen. */
    int pages = shell_page_count();
    if (pages > 1)
    {
        int dot_r = (int)(3.5 * scale + 0.5);
        double pitch_dots = 16.0;
        int dot_y = (int)(686.0 * scale + 0.5);
        int first_x = (int)((W / 2.0 - (pages - 1) * pitch_dots / 2.0) * scale);
        for (int i = 0; i < pages; i++)
        {
            int dot_x = first_x + (int)(i * pitch_dots * scale + 0.5);
            unsigned color = i == g_home_page ? 0xffffff : 0x8e8e93;
            iosim_fb_fill_circle(dot_x, dot_y, dot_r, color);
        }
    }

    /* Dock glass and its two apps. */
    int dx = (int)(18.0 * scale + 0.5), dy = (int)(761.3333 * scale + 0.5);
    int dw = (int)(366.0 * scale + 0.5), dh = (int)(89.0 * scale + 0.5);
    int dr = (int)(44.5 * scale + 0.5);
    iosim_fb_fill_field(dx, dy, dw, dh, dr, shell_dock_grid, SHELL_DOCK_W,
                        SHELL_DOCK_H);
    int dock_center_y = (int)((805.3333) * scale + 0.5);
    int dock_left = (int)((201.0 - 44.0) * scale + 0.5);
    int dock_right = (int)((201.0 + 44.0) * scale + 0.5);
    for (int i = 0; i < g_shell_app_count; i++)
    {
        struct shell_app *a = &g_shell_apps[i];
        if (!a->dock)
            continue;
        int cx = (a->stock == 7) ? dock_left : dock_right;
        shell_stock_icon(a->stock, cx - s / 2, dock_center_y - s / 2, s,
                         scale);
    }

    /* Search pill above the dock. */
    int sx = (int)(164.3333 * scale + 0.5);
    int sy = (int)(704.0 * scale + 0.5);
    int sw = (int)(73.0 * scale + 0.5);
    int sh = (int)(29.0 * scale + 0.5);
    int sr = (int)(14.5 * scale + 0.5);
    iosim_fb_fill_field(sx, sy, sw, sh, sr, shell_search_grid,
                        SHELL_SEARCH_W, SHELL_SEARCH_H);
    int mx = sx + (int)(12 * scale), my = sy + sh / 2;
    iosim_fb_stroke_circle(mx, my, (int)(4.5 * scale),
                           (int)(1.4 * scale + 0.5), 0xd6d3de);
    iosim_fb_draw_line(mx + (int)(3 * scale), my + (int)(3 * scale),
                       mx + (int)(6 * scale), my + (int)(6 * scale),
                       (int)(1.4 * scale + 0.5), 0xd6d3de);
    int swidth = iosim_fb_font_text_width("Search", IOSIM_FONT_REGULAR, 13,
                                          scale);
    iosim_fb_font_text(sx + (sw - swidth) / 2 + (int)(7 * scale),
                       my + (int)(5 * scale), "Search", IOSIM_FONT_REGULAR,
                       13, scale, 0xd8d5e0);

    draw_device_chrome(fbWidth, scale);
}

static int g_switcher;
static int g_switcher_index;
static volatile int g_switcher_requested;
static int g_sb_down;
static double g_sb_down_x, g_sb_down_y;
static int g_search;
static char g_search_query[64];
static UITextField *g_search_field;

static void shell_repaint(int fbWidth, int fbHeight, double scale,
                          const char *path, int switcher);

static void shell_switcher_requested(void)
{
    g_switcher_requested = 1;
}

static int shell_suspended_count(void)
{
    int count = 0;
    for (int i = 0; i < g_shell_app_count; i++)
        if (g_shell_apps[i].pid > 0)
            count++;
    return count;
}

static struct shell_app *shell_suspended_app(int ordinal, int *out_index)
{
    int k = 0;
    for (int i = 0; i < g_shell_app_count; i++)
    {
        if (g_shell_apps[i].pid <= 0)
            continue;
        if (k == ordinal)
        {
            if (out_index)
                *out_index = i;
            return &g_shell_apps[i];
        }
        k++;
    }
    return 0;
}

static void shell_snapshot_dir(char *out, unsigned long cap)
{
    const char *fb = getenv("IOSIM_SCREENSHOT_PATH");
    out[0] = 0;
    if (!fb || !*fb)
        return;
    const char *slash = 0;
    for (const char *p = fb; *p; p++)
        if (*p == '/')
            slash = p;
    unsigned long n = slash ? (unsigned long)(slash - fb) : 0;
    snprintf(out, cap, "%.*s/switcher", (int)n, fb);
}

/* Keep the last rendered frame of a suspended app for the app switcher. */
static void shell_capture_snapshot(struct shell_app *a)
{
    char dir[1024];
    shell_snapshot_dir(dir, sizeof(dir));
    if (!dir[0])
        return;
    iosim_fs_mkdir(dir, 1);
    const char *fb = getenv("IOSIM_SCREENSHOT_PATH");
    unsigned char *bytes = 0;
    unsigned long len = 0;
    if (!fb || iosim_fs_read(fb, &bytes, &len) != 0)
        return;
    const char *key = a->bundle[0] ? a->bundle : a->name;
    char name[160];
    int k = 0;
    for (const char *p = key; *p && k < 150; p++)
    {
        char c = *p;
        if ((c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z') ||
            (c >= '0' && c <= '9') || c == '.' || c == '-' || c == '_')
            name[k++] = c;
        else
            name[k++] = '_';
    }
    name[k] = 0;
    char path[1200];
    snprintf(path, sizeof(path), "%s/%s.png", dir, name);
    if (iosim_fs_write(path, bytes, len) == 0)
    {
        int m = 0;
        for (const char *p = path; *p && m < 1023; p++)
            a->snapshot[m++] = *p;
        a->snapshot[m] = 0;
    }
    free(bytes);
}

static void shell_switcher_geometry(int fbWidth, int fbHeight, double scale,
                                    int ordinal, double *out_x,
                                    double *out_y, double *out_w,
                                    double *out_h)
{
    double W = fbWidth / scale, H = fbHeight / scale;
    double cardW = W * 0.72;
    double cardH = cardW * H / W;
    double gap = 20.0;
    double y = (H - cardH) / 2.0;
    double cx = W / 2.0 + (ordinal - g_switcher_index) * (cardW + gap);
    *out_x = cx - cardW / 2.0;
    *out_y = y;
    *out_w = cardW;
    *out_h = cardH;
}

static void shell_draw_switcher(int fbWidth, int fbHeight, double scale,
                                const char *path)
{
    shell_wallpaper_build(fbWidth, fbHeight);
    if (g_shell_wallpaper)
        iosim_fb_paste_xrgb(g_shell_wallpaper);
    else
    {
        iosim_fb_set_opacity(1.0);
        iosim_fb_fill_rect(0, 0, fbWidth, fbHeight, 0x0b1020);
    }
    iosim_fb_set_opacity(0.55);
    iosim_fb_fill_rect(0, 0, fbWidth, fbHeight, 0x000000);
    iosim_fb_set_opacity(1.0);

    int count = shell_suspended_count();
    if (count == 0)
    {
        const char *text = "No recent apps";
        int tw = iosim_fb_font_text_width(text, IOSIM_FONT_SEMIBOLD, 17,
                                          scale);
        iosim_fb_font_text((fbWidth - tw) / 2,
                           fbHeight / 2, text, IOSIM_FONT_SEMIBOLD, 17,
                           scale, 0xd8d5e0);
        draw_device_chrome(fbWidth, scale);
        if (path && *path)
            iosim_fb_present(path);
        return;
    }
    if (g_switcher_index >= count)
        g_switcher_index = count - 1;
    if (g_switcher_index < 0)
        g_switcher_index = 0;

    int first = g_switcher_index > 0 ? g_switcher_index - 1 : 0;
    int last = g_switcher_index + 1 < count ? g_switcher_index + 1 : count - 1;
    for (int i = first; i <= last; i++)
    {
        struct shell_app *a = shell_suspended_app(i, 0);
        if (!a)
            continue;
        double x, y, w, h;
        shell_switcher_geometry(fbWidth, fbHeight, scale, i, &x, &y, &w, &h);
        int wpx = (int)(w * scale + 0.5);
        int hpx = (int)(h * scale + 0.5);
        int xpx = (int)(x * scale + 0.5);
        int ypx = (int)(y * scale + 0.5);
        if (wpx <= 0 || hpx <= 0)
            continue;

        iosim_fb_set_opacity(0.45);
        iosim_fb_fill_round_rect(xpx - (int)(6 * scale), ypx + (int)(8 * scale),
                                 wpx + (int)(12 * scale), hpx,
                                 (int)(46 * scale), 0x000000);
        iosim_fb_set_opacity(1.0);

        void *state = iosim_fb_begin_offscreen((unsigned)wpx, (unsigned)hpx);
        if (state)
        {
            int drew = 0;
            if (a->snapshot[0])
            {
                unsigned char *rgba = 0;
                int sw = 0, sh = 0;
                if (iosim_png_load(a->snapshot, &rgba, &sw, &sh) == 0 && rgba)
                {
                    iosim_fb_blit_rgba_scaled(0, 0, wpx, hpx, rgba, sw, sh,
                                              sw * 4);
                    free(rgba);
                    drew = 1;
                }
            }
            if (!drew)
                iosim_fb_fill_rect(0, 0, wpx, hpx, 0x1c1c1e);
            iosim_fb_mask_round_rect(0, 0, wpx, hpx, (int)(40 * scale));
            int bw = 0, bh = 0;
            unsigned *buf = iosim_fb_end_offscreen(state, &bw, &bh);
            if (buf)
            {
                iosim_fb_blit_affine(buf, bw, bh, 1.0, 0.0, 0.0, 1.0,
                                     xpx, ypx, 1.0);
                iosim_fb_free_offscreen(buf);
            }
        }
        int tw = iosim_fb_font_text_width(a->name, IOSIM_FONT_SEMIBOLD, 15,
                                          scale);
        iosim_fb_font_text((int)((x + w / 2) * scale) - tw / 2,
                           (int)((y - 22) * scale), a->name,
                           IOSIM_FONT_SEMIBOLD, 15, scale, 0xffffff);
    }
    draw_device_chrome(fbWidth, scale);
    if (path && *path)
        iosim_fb_present(path);
}

/* Spotlight-style search over the installed apps. The search field shares
 * the runtime's text-input role through a hidden UITextField, so both the
 * on-screen keyboard and hardware key records edit the same query. */
static void shell_lower_copy(char *out, const char *in, unsigned long cap)
{
    unsigned long i = 0;
    for (; in && *in && i + 1 < cap; in++)
        out[i++] = (*in >= 'A' && *in <= 'Z')
                       ? (char)(*in - 'A' + 'a')
                       : *in;
    out[i] = 0;
}

static int shell_search_matches(const char *name)
{
    char lowered[128], wanted[64];
    shell_lower_copy(lowered, name, sizeof(lowered));
    shell_lower_copy(wanted, g_search_query, sizeof(wanted));
    if (!wanted[0])
        return 0;
    return strstr(lowered, wanted) != 0;
}

static int shell_search_result_apps(int *out, int cap)
{
    int n = 0;
    for (int i = 0; i < g_shell_app_count && n < cap; i++)
    {
        if (!shell_search_matches(g_shell_apps[i].name))
            continue;
        if (out)
            out[n] = i;
        n++;
    }
    return n;
}

static void shell_refresh_search_query(void)
{
    if (!g_search_field)
        return;
    const char *text = iosim_string_cstr(g_search_field->_text);
    snprintf(g_search_query, sizeof(g_search_query), "%s",
             text ? text : "");
}

static void shell_draw_search(int fbWidth, int fbHeight, double scale,
                              const char *path)
{
    shell_wallpaper_build(fbWidth, fbHeight);
    if (g_shell_wallpaper)
        iosim_fb_paste_xrgb(g_shell_wallpaper);
    else
    {
        iosim_fb_set_opacity(1.0);
        iosim_fb_fill_rect(0, 0, fbWidth, fbHeight, 0x0b1020);
    }
    iosim_fb_set_opacity(0.55);
    iosim_fb_fill_rect(0, 0, fbWidth, fbHeight, 0x000000);
    iosim_fb_set_opacity(1.0);

    double W = fbWidth / scale;
    iosim_fb_font_text((int)(24 * scale), (int)(100 * scale), "Search",
                       IOSIM_FONT_SEMIBOLD, 34, scale, 0xffffff);

    int fx = (int)(24 * scale + 0.5);
    int fy = (int)(160 * scale + 0.5);
    int fw = (int)((W - 48) * scale + 0.5);
    int fh = (int)(52 * scale + 0.5);
    iosim_fb_fill_round_rect(fx, fy, fw, fh, (int)(14 * scale + 0.5),
                             0x1b1f2b);
    const char *shown = g_search_query[0] ? g_search_query : "Search apps";
    unsigned fg = g_search_query[0] ? 0xffffff : 0x7c8291;
    iosim_fb_font_text(fx + (int)(16 * scale),
                       fy + fh / 2 + (int)(6 * scale), shown,
                       IOSIM_FONT_REGULAR, 17, scale, fg);
    int caretX = fx + (int)(16 * scale) +
                 iosim_fb_font_text_width(shown, IOSIM_FONT_REGULAR, 17,
                                          scale);
    iosim_fb_fill_rect(caretX + (int)(2 * scale), fy + (int)(14 * scale),
                       (int)(2 * scale), (int)(24 * scale), 0x426bf2);

    int apps[16];
    int total = shell_search_result_apps(apps, 16);
    int rows = total > 4 ? 4 : total;
    for (int i = 0; i < rows; i++)
    {
        struct shell_app *a = &g_shell_apps[apps[i]];
        int rowY = (int)((240 + i * 64) * scale + 0.5);
        iosim_fb_fill_round_rect((int)(24 * scale), rowY,
                                 (int)((W - 48) * scale),
                                 (int)(56 * scale), (int)(14 * scale),
                                 0x1a1e2a);
        int icon = (int)(40 * scale + 0.5);
        int iconX = (int)(32 * scale + 0.5);
        shell_stock_icon(a->stock, iconX, rowY + (int)(8 * scale), icon,
                         scale);
        iosim_fb_font_text(iconX + icon + (int)(16 * scale),
                           rowY + (int)(36 * scale), a->name,
                           IOSIM_FONT_REGULAR, 17, scale, 0xffffff);
    }
    if (g_search_query[0] && total == 0)
    {
        const char *none = "No Results";
        int tw = iosim_fb_font_text_width(none, IOSIM_FONT_SEMIBOLD, 17,
                                          scale);
        iosim_fb_font_text((fbWidth - tw) / 2, (int)(260 * scale), none,
                           IOSIM_FONT_SEMIBOLD, 17, scale, 0xd8d5e0);
    }
    draw_keyboard(fbWidth, fbHeight, scale);
    draw_device_chrome(fbWidth, scale);
    if (path && *path)
        iosim_fb_present(path);
}

static int shell_search_hit(double px, double py, int fbWidth, double scale)
{
    double W = fbWidth / scale;
    if (px < 24.0 || px > W - 24.0)
        return -1;
    if (py < 240.0 || py >= 240.0 + 4 * 64.0)
        return -1;
    int row = (int)((py - 240.0) / 64.0);
    int apps[16];
    int total = shell_search_result_apps(apps, 16);
    if (row >= 4 || row >= total)
        return -1;
    return apps[row];
}

static void shell_open_search(int fbWidth, int fbHeight, double scale,
                              const char *path)
{
    if (!g_search_field)
    {
        g_search_field = [[UITextField alloc]
            initWithFrame:CGRectMake(24, 160, 354, 52)];
        g_search_field.textColor = [UIColor whiteColor];
        g_search_field.font = [UIFont systemFontOfSize:17];
    }
    g_search_field.text = @"";
    g_search_query[0] = 0;
    g_search = 1;
    [g_search_field becomeFirstResponder];
    printf("[SpringBoard] search opened\n");
    fflush(0);
    shell_draw_search(fbWidth, fbHeight, scale, path);
}

static void shell_close_search(int fbWidth, int fbHeight, double scale,
                               const char *path)
{
    g_search = 0;
    if (g_search_field)
        [g_search_field resignFirstResponder];
    printf("[SpringBoard] search closed\n");
    fflush(0);
    shell_draw(fbWidth, fbHeight, scale);
    if (path && *path)
        iosim_fb_present(path);
}

static int shell_switcher_hit(int xpx, int ypx, int fbWidth, int fbHeight,
                              double scale)
{
    int count = shell_suspended_count();
    for (int i = 0; i < count; i++)
    {
        double x, y, w, h;
        shell_switcher_geometry(fbWidth, fbHeight, scale, i, &x, &y, &w, &h);
        if (xpx >= x * scale && xpx < (x + w) * scale &&
            ypx >= y * scale && ypx < (y + h) * scale)
            return i;
    }
    return -1;
}

static void shell_after_app_stop(int fbWidth, int fbHeight, double scale,
                                 const char *path)
{
    if (g_switcher_requested)
    {
        int count = shell_suspended_count();
        g_switcher_requested = 0;
        g_switcher = 1;
        g_switcher_index = count > 0 ? count - 1 : 0;
        printf("[SpringBoard] app switcher opened (%d suspended)\n", count);
        fflush(0);
        shell_repaint(fbWidth, fbHeight, scale, path, 1);
    }
    else
        shell_repaint(fbWidth, fbHeight, scale, path, 0);
}

/* Force-quit a suspended app from the switcher (a swipe up on its card).
 * The process is continued so the pending SIGTERM is delivered, then reaped;
 * its card disappears and the home screen shows the slot again. */
static void shell_close_app(int index, int fbWidth, int fbHeight, double scale,
                            const char *path)
{
    struct shell_app *a = &g_shell_apps[index];
    if (a->pid <= 0)
        return;
    printf("[SpringBoard] closed %s (pid %d)\n", a->name, a->pid);
    fflush(0);
    iosim_terminate_app(a->pid);
    a->pid = 0;
    a->snapshot[0] = 0;
    int count = shell_suspended_count();
    if (count == 0)
        g_switcher = 0;
    if (g_switcher_index >= count)
        g_switcher_index = count > 0 ? count - 1 : 0;
    shell_repaint(fbWidth, fbHeight, scale, path, g_switcher);
}

static void shell_launch(int index, int fbWidth, int fbHeight, double scale,
                         const char *path)
{
    struct shell_app *a = &g_shell_apps[index];
    if (a->pid > 0)
    {
        /* The app stopped itself from the home event. Hand the event
         * stream back and continue the same process where it left off. */
        printf("[SpringBoard] resuming %s (pid %d)\n", a->name, a->pid);
        fflush(0);
        iosim_event_close();
        if (iosim_resume_app(a->pid) == 0)
        {
            int state = iosim_spawn_wait(a->pid);
            if (state == 0)
            {
                a->pid = 0;
                g_switcher_requested = 0;
                shell_repaint(fbWidth, fbHeight, scale, path, 0);
            }
            else
            {
                shell_capture_snapshot(a);
                shell_after_app_stop(fbWidth, fbHeight, scale, path);
            }
            return;
        }
        printf("[SpringBoard] resume failed for %s\n", a->name);
        a->pid = 0;
    }
    if (!a->exe[0])
    {
        printf("[SpringBoard] %s is a system app with no executable in this "
               "runtime\n", a->name);
        fflush(0);
        return;
    }
    printf("[SpringBoard] launching %s (%s)\n", a->name, a->exe);
    fflush(0);
    iosim_event_close();
    int pid = iosim_spawn_app(a->exe, a->bundle, a->home);
    int stopped = 0;
    if (pid > 0)
    {
        int state = iosim_spawn_wait(pid);
        a->pid = state == 1 ? pid : 0;
        stopped = state == 1;
        if (stopped)
            shell_capture_snapshot(a);
    }
    else
        printf("[SpringBoard] launch failed for %s\n", a->name);
    fflush(0);
    if (stopped)
        shell_after_app_stop(fbWidth, fbHeight, scale, path);
    else
    {
        g_switcher_requested = 0;
        shell_repaint(fbWidth, fbHeight, scale, path, 0);
    }
}

static void shell_repaint(int fbWidth, int fbHeight, double scale,
                          const char *path, int switcher)
{
    if (switcher)
        shell_draw_switcher(fbWidth, fbHeight, scale, path);
    else
    {
        shell_draw(fbWidth, fbHeight, scale);
        if (path && *path)
            iosim_fb_present(path);
    }
}

static int run_springboard(void)
{
    double scale = 3.0;
    const char *scaleEnv = getenv("SIMULATOR_MAINSCREEN_SCALE");
    if (scaleEnv)
        scale = atof(scaleEnv);
    if (scale <= 0)
        scale = 3.0;
    const char *pw = getenv("SIMULATOR_MAINSCREEN_WIDTH");
    const char *ph = getenv("SIMULATOR_MAINSCREEN_HEIGHT");
    int fbWidth = pw ? atoi(pw) : 1206;
    int fbHeight = ph ? atoi(ph) : 2622;
    if (iosim_fb_begin((unsigned)fbWidth, (unsigned)fbHeight) != 0)
        return 1;

    iosim_on_switcher_request(shell_switcher_requested);
    shell_load_apps();
    shell_draw(fbWidth, fbHeight, scale);
    const char *path = getenv("IOSIM_SCREENSHOT_PATH");
    if (path && *path)
        iosim_fb_present(path);
    printf("[SpringBoard] home screen rendered at %.1fx\n", scale);
    fflush(0);

    const char *fifo = getenv("IOSIM_EVENT_FIFO");
    if (!fifo || !*fifo)
        return 0;

    double W = fbWidth / scale;
    double pitch = (W - 2 * SHELL_MARGIN_PT - SHELL_ICON_PT) / 3.0;
    int type = 0, x = 0, y = 0, r;
    while ((r = iosim_event_next(&type, &x, &y)) != 0)
    {
        if (r == 1 && type == 8)
        {
            /* The set of installed apps changed: rebuild the home screen. */
            g_switcher = 0;
            shell_load_apps();
            if (g_home_page >= shell_page_count())
                g_home_page = shell_page_count() - 1;
            if (g_home_page < 0)
                g_home_page = 0;
            if (g_search)
            {
                shell_draw_search(fbWidth, fbHeight, scale, path);
                continue;
            }
            shell_draw(fbWidth, fbHeight, scale);
            if (path && *path)
                iosim_fb_present(path);
            continue;
        }
        if (r == 1 && type == 9)
        {
            if (g_search)
            {
                g_search = 0;
                if (g_search_field)
                    [g_search_field resignFirstResponder];
            }
            int count = shell_suspended_count();
            g_switcher = !g_switcher;
            if (g_switcher)
            {
                g_switcher_index = count > 0 ? count - 1 : 0;
                printf("[SpringBoard] app switcher opened (%d suspended)\n",
                       count);
            }
            else
                printf("[SpringBoard] app switcher closed\n");
            fflush(0);
            shell_repaint(fbWidth, fbHeight, scale, path, g_switcher);
            continue;
        }
        if (r == 1 && type == 2)
        {
            g_sb_down = 1;
            g_sb_down_x = x / scale;
            g_sb_down_y = y / scale;
            continue;
        }
        if (r == 1 && type == 4)
        {
            double px = x / scale, py = y / scale;
            double dx = px - g_sb_down_x, dy = py - g_sb_down_y;
            int down = g_sb_down;
            g_sb_down = 0;
            if (!down)
                continue;
            if (g_search)
            {
                if (g_sb_down_y > fbHeight / scale - 45 && dy < -100)
                    shell_close_search(fbWidth, fbHeight, scale, path);
                continue;
            }
            if (!g_switcher && g_sb_down_y > fbHeight / scale - 45 &&
                dy < -100 && dx > -140 && dx < 140)
            {
                int count = shell_suspended_count();
                g_switcher = 1;
                g_switcher_index = count > 0 ? count - 1 : 0;
                printf("[SpringBoard] app switcher opened (%d suspended)\n",
                       count);
                fflush(0);
                shell_repaint(fbWidth, fbHeight, scale, path, 1);
            }
            else if (g_switcher && dy < -100 && dx > -140 && dx < 140)
            {
                /* A swipe up that starts on a card closes that app. */
                int ordinal = shell_switcher_hit(
                    (int)(g_sb_down_x * scale), (int)(g_sb_down_y * scale),
                    fbWidth, fbHeight, scale);
                int appIndex = -1;
                if (ordinal >= 0)
                    shell_suspended_app(ordinal, &appIndex);
                if (appIndex >= 0)
                    shell_close_app(appIndex, fbWidth, fbHeight, scale, path);
            }
            else if (g_switcher && dy > 90)
            {
                g_switcher = 0;
                printf("[SpringBoard] app switcher closed\n");
                fflush(0);
                shell_repaint(fbWidth, fbHeight, scale, path, 0);
            }
            else if (g_switcher && (dx > 100 || dx < -100))
            {
                int count = shell_suspended_count();
                g_switcher_index += dx < 0 ? 1 : -1;
                if (g_switcher_index < 0)
                    g_switcher_index = 0;
                if (g_switcher_index >= count)
                    g_switcher_index = count > 0 ? count - 1 : 0;
                shell_repaint(fbWidth, fbHeight, scale, path, 1);
            }
            else if (!g_switcher && (dx > 80 || dx < -80) &&
                     dy > -60 && dy < 60)
            {
                int pages = shell_page_count();
                int page = g_home_page + (dx < 0 ? 1 : -1);
                if (page < 0)
                    page = 0;
                if (page >= pages)
                    page = pages - 1;
                if (page != g_home_page)
                {
                    g_home_page = page;
                    printf("[SpringBoard] home page %d of %d\n", page + 1,
                           pages);
                    fflush(0);
                    shell_repaint(fbWidth, fbHeight, scale, path, 0);
                }
            }
            continue;
        }
        if (r == 1 && (type == 5 || type == 6) && g_search)
        {
            if (type == 5)
            {
                char buf[2] = {(char)x, 0};
                [g_search_field
                    insertText:[NSString stringWithUTF8String:buf]];
            }
            else
                [g_search_field deleteBackward];
            shell_refresh_search_query();
            int apps[16];
            int total = shell_search_result_apps(apps, 16);
            printf("[SpringBoard] search results %d\n", total);
            fflush(0);
            shell_draw_search(fbWidth, fbHeight, scale, path);
            continue;
        }
        if (r == 1 && type == 7)
        {
            if (g_search)
            {
                shell_close_search(fbWidth, fbHeight, scale, path);
                continue;
            }
            if (g_switcher)
            {
                g_switcher = 0;
                shell_repaint(fbWidth, fbHeight, scale, path, 0);
                continue;
            }
        }
        if (r != 1 || type != 1)
            continue;
        double px = x / scale, py = y / scale;
        if (g_switcher)
        {
            int ordinal = shell_switcher_hit(x, y, fbWidth, fbHeight, scale);
            if (ordinal >= 0)
            {
                int appIndex = -1;
                struct shell_app *a = shell_suspended_app(ordinal, &appIndex);
                printf("[SpringBoard] switcher selected %s\n",
                       a ? a->name : "?");
                fflush(0);
                g_switcher = 0;
                if (a)
                    shell_launch(appIndex, fbWidth, fbHeight, scale, path);
            }
            else
            {
                int count = shell_suspended_count();
                if (px < 201.0 && g_switcher_index > 0)
                    g_switcher_index--;
                else if (px >= 201.0 && g_switcher_index + 1 < count)
                    g_switcher_index++;
                else
                    g_switcher = 0;
                shell_repaint(fbWidth, fbHeight, scale, path, g_switcher);
            }
            continue;
        }
        if (g_search)
        {
            int appIndex = shell_search_hit(px, py, fbWidth, scale);
            if (appIndex >= 0)
            {
                g_search = 0;
                [g_search_field resignFirstResponder];
                printf("[SpringBoard] search selected %s\n",
                       g_shell_apps[appIndex].name);
                fflush(0);
                shell_launch(appIndex, fbWidth, fbHeight, scale, path);
                continue;
            }
            if (keyboard_handle_tap(x, y, fbWidth, fbHeight, scale))
            {
                shell_refresh_search_query();
                int apps[16];
                int total = shell_search_result_apps(apps, 16);
                printf("[SpringBoard] search results %d\n", total);
                fflush(0);
                shell_draw_search(fbWidth, fbHeight, scale, path);
                continue;
            }
            if (py < 550.0)
            {
                shell_close_search(fbWidth, fbHeight, scale, path);
                continue;
            }
            continue;
        }
        int hit = -1, slot = 0;
        for (int i = 0; i < g_shell_app_count && hit < 0; i++)
        {
            if (g_shell_apps[i].dock)
                continue;
            int page = slot / 16;
            int page_slot = slot % 16;
            if (page == g_home_page)
            {
                int col = page_slot % 4, row = page_slot / 4;
                double cx = SHELL_MARGIN_PT + SHELL_ICON_PT / 2 + col * pitch;
                double cy = shell_row_center[row];
                if (px >= cx - 34 && px < cx + 34 && py >= cy - 34 &&
                    py < cy + 50)
                    hit = i;
            }
            slot++;
        }
        if (hit < 0 && px >= 158.0 && px <= 244.0 && py >= 698.0 &&
            py <= 739.0)
        {
            shell_open_search(fbWidth, fbHeight, scale, path);
            continue;
        }
        if (hit < 0 && px >= 201.0 - 80 && px < 201.0 + 80 &&
            py >= 806.0 - 44 && py < 806.0 + 44)
        {
            int dock_index = 0;
            for (int i = 0; i < g_shell_app_count && hit < 0; i++)
            {
                if (!g_shell_apps[i].dock)
                    continue;
                double cx = dock_index == 0 ? 201.0 - 47.2 : 201.0 + 47.2;
                if (px >= cx - 34 && px < cx + 34 && py >= 806.0 - 34 &&
                    py < 806.0 + 34)
                    hit = i;
                dock_index++;
            }
        }
        if (hit >= 0)
            shell_launch(hit, fbWidth, fbHeight, scale, path);
    }
    return 0;
}

static UIViewController *top_presented(UIViewController *root)
{
    UIViewController *top = root;
    int guard = 0;
    while (top && top->_presentedController && guard++ < 16)
        top = (UIViewController *)top->_presentedController;
    return top;
}

static void alert_metrics(UIAlertController *alert, int fbW, double scale,
                          double *outW, double *outH, double *titleH,
                          double *messageH)
{
    double W = fbW / scale;
    double width = W - 82;
    if (width > 320)
        width = 320;
    if (width < 200)
        width = 200;
    double textW = width - 64;
    double th = 0, mh = 0;
    if (alert->_title)
    {
        const char *t = iosim_string_cstr(alert->_title);
        char lines[IOSIM_MAX_WRAP_LINES][256];
        int n = wrap_text_lines(t, IOSIM_FONT_BOLD, 17, scale,
                                (int)(textW * scale), lines, 4);
        int asc = 0, desc = 0, lh = 0;
        iosim_fb_font_metrics(IOSIM_FONT_BOLD, 17, scale, &asc, &desc, &lh);
        th = (n > 0 ? n : 1) * lh / scale;
    }
    if (alert->_message)
    {
        const char *m = iosim_string_cstr(alert->_message);
        char lines[IOSIM_MAX_WRAP_LINES][256];
        int n = wrap_text_lines(m, IOSIM_FONT_REGULAR, 15, scale,
                                (int)(textW * scale), lines, 8);
        int asc = 0, desc = 0, lh = 0;
        iosim_fb_font_metrics(IOSIM_FONT_REGULAR, 15, scale, &asc, &desc,
                              &lh);
        mh = (n > 0 ? n : 1) * lh / scale;
    }
    double buttons;
    if (alert->_actionCount == 2)
        buttons = 47;
    else
        buttons = alert->_actionCount * 47 +
                  (alert->_actionCount > 1 ? (alert->_actionCount - 1) * 8 : 0);
    double h = 22 + th + (mh > 0 ? 7 + mh : 0) + 20.5 + buttons + 17;
    *outW = width;
    *outH = h;
    *titleH = th;
    *messageH = mh;
}

static void alert_draw_wrapped(id text, double width, double scale, int x,
                               int y, int color, int bold, double size,
                               int maxLines)
{
    const char *t = iosim_string_cstr(text);
    if (!t)
        return;
    char lines[IOSIM_MAX_WRAP_LINES][256];
    int n = wrap_text_lines(t, bold ? IOSIM_FONT_BOLD : IOSIM_FONT_REGULAR,
                            size, scale, (int)(width * scale), lines,
                            maxLines);
    int asc = 0, desc = 0, lh = 0;
    iosim_fb_font_metrics(bold ? IOSIM_FONT_BOLD : IOSIM_FONT_REGULAR, size,
                          scale, &asc, &desc, &lh);
    for (int i = 0; i < n; i++)
    {
        iosim_fb_font_text(x, y + i * lh + asc, lines[i],
                           bold ? IOSIM_FONT_BOLD : IOSIM_FONT_REGULAR, size,
                           scale, color);
    }
}

static void draw_alert(UIAlertController *alert, int fbW, int fbH,
                       double scale)
{
    double W = fbW / scale, H = fbH / scale;
    iosim_fb_set_opacity(0.47);
    iosim_fb_fill_rect(0, 0, fbW, fbH, 0x000000);
    iosim_fb_set_opacity(1.0);
    /* The system status bar lives above the alert's dimming view. */
    draw_device_chrome(fbW, scale);
    double width, height, titleH, messageH;
    alert_metrics(alert, fbW, scale, &width, &height, &titleH, &messageH);
    double x = (W - width) / 2;
    double y = (H - height) / 2 + 14.0;
    int ix = (int)(x * scale + 0.5);
    int iy = (int)(y * scale + 0.5);
    int iw = (int)(width * scale + 0.5);
    int ih = (int)(height * scale + 0.5);
    iosim_fb_fill_round_rect(ix, iy, iw, ih, (int)(33.7 * scale), 0x23242d);
    int cursor = iy + (int)(22 * scale);
    int textX = ix + (int)(30 * scale);
    if (alert->_title)
    {
        alert_draw_wrapped(alert->_title, width - 64, scale, textX, cursor,
                           0xffffff, 1, 17, 4);
        cursor += (int)(titleH * scale) + (int)(7 * scale);
    }
    if (alert->_message)
    {
        alert_draw_wrapped(alert->_message, width - 64, scale, textX, cursor,
                           0x71727a, 0, 15, 8);
        cursor += (int)(messageH * scale) + (int)(20.5 * scale);
    }
    int by = iy + ih - (int)(17 * scale) - (int)(47 * scale);
    int bh = (int)(47 * scale);
    if (alert->_actionCount == 2)
    {
        int gap = (int)(8.3 * scale);
        int bw = (iw - (int)(16 * scale) * 2 - gap) / 2;
        for (int i = 0; i < 2; i++)
        {
            int bx = ix + (int)(16 * scale) + i * (bw + gap);
            iosim_fb_fill_round_rect(bx, by, bw, bh, bh / 2, 0x404149);
            UIAlertAction *action = alert->_actions[i];
            const char *title = iosim_string_cstr(action->_title);
            if (!title)
                continue;
            unsigned color = action->_style == UIAlertActionStyleDestructive
                                 ? 0xff6b6f : 0xffffff;
            int tw = iosim_fb_font_text_width(title, IOSIM_FONT_SEMIBOLD, 17,
                                              scale);
            int asc = 0, desc = 0, lh = 0;
            iosim_fb_font_metrics(IOSIM_FONT_SEMIBOLD, 17, scale, &asc, &desc,
                                  &lh);
            iosim_fb_font_text(bx + (bw - tw) / 2,
                               by + bh / 2 - lh / 2 + asc +
                                   (int)(0.7 * scale + 0.5),
                               title, IOSIM_FONT_SEMIBOLD, 17, scale, color);
        }
    }
    else
    {
        int rowY = by - (alert->_actionCount - 1) * (bh + (int)(8 * scale));
        for (int i = 0; i < alert->_actionCount; i++)
        {
            int bx = ix + (int)(16 * scale);
            int bw = iw - (int)(32 * scale);
            iosim_fb_fill_round_rect(bx, rowY, bw, bh, bh / 2, 0x404149);
            UIAlertAction *action = alert->_actions[i];
            const char *title = iosim_string_cstr(action->_title);
            if (title)
            {
                unsigned color =
                    action->_style == UIAlertActionStyleDestructive
                        ? 0xff6b6f : 0xffffff;
                int tw = iosim_fb_font_text_width(title, IOSIM_FONT_SEMIBOLD,
                                                  17, scale);
                int asc = 0, desc = 0, lh = 0;
                iosim_fb_font_metrics(IOSIM_FONT_SEMIBOLD, 17, scale, &asc,
                                      &desc, &lh);
                iosim_fb_font_text(bx + (bw - tw) / 2,
                                   rowY + bh / 2 - lh / 2 + asc +
                                       (int)(0.7 * scale + 0.5),
                                   title, IOSIM_FONT_SEMIBOLD, 17, scale,
                                   color);
            }
            rowY += bh + (int)(8 * scale);
        }
    }
}

static void draw_modals(UIViewController *root, int fbW, int fbH,
                        double scale)
{
    if (!root || !root->_presentedController)
        return;
    UIViewController *top = top_presented(root);
    if (!top)
        return;
    if ([top isKindOfClass:[UIAlertController class]])
        draw_alert((UIAlertController *)top, fbW, fbH, scale);
    else
    {
        UIView *view = [top view];
        if (view)
            render_view(view, 0, 0, scale, 1.0);
    }
}

static int alert_handle_tap(UIViewController *root, int px, int py, int fbW,
                            int fbH, double scale)
{
    (void)fbH;
    if (!root || !root->_presentedController)
        return 0;
    UIViewController *top = top_presented(root);
    if (!top || ![top isKindOfClass:[UIAlertController class]])
        return 0;
    UIAlertController *alert = (UIAlertController *)top;
    double width, height, titleH, messageH;
    alert_metrics(alert, fbW, scale, &width, &height, &titleH, &messageH);
    double W = fbW / scale;
    double x = (W - width) / 2;
    double H = fbH / scale;
    double topY = (H - height) / 2 + 14.0;
    double tapX = px / scale, tapY = py / scale;
    if (tapX < x || tapX > x + width || tapY < topY || tapY > topY + height)
        return 1;
    double by = topY + height - 17 - 47;
    int action = -1;
    if (alert->_actionCount == 2)
    {
        double gap = 8.3;
        double bw = (width - 32 - gap) / 2;
        if (tapY >= by && tapY <= by + 47)
        {
            if (tapX >= x + 16 && tapX <= x + 16 + bw)
                action = 0;
            else if (tapX >= x + 16 + bw + gap &&
                     tapX <= x + 16 + bw + gap + bw)
                action = 1;
        }
    }
    else if (tapY >= by && tapY <= by + 47)
    {
        if (tapX >= x + 16 && tapX <= x + width - 16)
            action = 0;
    }
    if (action >= 0 && action < alert->_actionCount)
    {
        UIAlertAction *a = alert->_actions[action];
        if (a && a->_handler)
            a->_handler(a);
        [root dismissViewControllerAnimated:NO completion:nil];
    }
    return 1;
}

/* Runs the background lifecycle, releases the event stream and suspends the
 * process until SpringBoard continues it. request_switcher asks the system UI
 * to open the app switcher as it takes over. */
static void app_lifecycle_call(id delegate, SEL selector, id argument)
{
    if (delegate && [delegate respondsToSelector:selector])
        ((void (*)(id, SEL, id))objc_msgSend)(delegate, selector, argument);
}

static void app_enter_background(id sceneDelegate, id scene,
                                 int requestSwitcher)
{
    UIApplication *app = [UIApplication sharedApplication];
    id appDelegate = [app delegate];

    app->_state = UIApplicationStateInactive;
    app_lifecycle_call(appDelegate, @selector(applicationWillResignActive:), app);
    [[NSNotificationCenter defaultCenter]
        postNotificationName:UIApplicationWillResignActiveNotification
                      object:app];
    app_lifecycle_call(sceneDelegate, @selector(sceneWillResignActive:), scene);

    app->_state = UIApplicationStateBackground;
    app_lifecycle_call(appDelegate,
                       @selector(applicationDidEnterBackground:), app);
    [[NSNotificationCenter defaultCenter]
        postNotificationName:UIApplicationDidEnterBackgroundNotification
                      object:app];
    app_lifecycle_call(sceneDelegate, @selector(sceneDidEnterBackground:), scene);

    printf("[UIKit-lite] backgrounded by the system; suspending\n");
    fflush(0);
    if (requestSwitcher)
        iosim_request_switcher();
    iosim_event_close();
    iosim_suspend_self();
    iosim_event_open();

    app->_state = UIApplicationStateInactive;
    app_lifecycle_call(appDelegate,
                       @selector(applicationWillEnterForeground:), app);
    [[NSNotificationCenter defaultCenter]
        postNotificationName:UIApplicationWillEnterForegroundNotification
                      object:app];
    app_lifecycle_call(sceneDelegate, @selector(sceneWillEnterForeground:), scene);

    app->_state = UIApplicationStateActive;
    app_lifecycle_call(appDelegate, @selector(applicationDidBecomeActive:), app);
    [[NSNotificationCenter defaultCenter]
        postNotificationName:UIApplicationDidBecomeActiveNotification
                      object:app];
    app_lifecycle_call(sceneDelegate, @selector(sceneDidBecomeActive:), scene);
    printf("[UIKit-lite] resumed from suspension\n");
    fflush(0);
}

int UIApplicationMain(int argc, char **argv, id principal, id delegateName)
{
    (void)principal;
    (void)argv;
    const char *shellMode = getenv("IOSIM_SHELL");
    if (shellMode && *shellMode)
        return run_springboard();

    /* Open the event stream before the first frame so the system UI can
     * deliver events while the scene is still being built. */
    iosim_event_open();

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
    SEL didBecomeActive = @selector(sceneDidBecomeActive:);
    if (sceneDelegate && [sceneDelegate respondsToSelector:didBecomeActive])
        ((void (*)(id, SEL, id))objc_msgSend)(sceneDelegate, didBecomeActive,
                                              scene);
    app_lifecycle_call(delegate, @selector(applicationDidBecomeActive:), app);
    [[NSNotificationCenter defaultCenter]
        postNotificationName:UIApplicationDidBecomeActiveNotification
                      object:app];

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

    UIViewController *rootController = [window rootViewController];
    if (rootController)
    {
        [rootController viewWillAppear:NO];
        [rootController viewDidAppear:NO];
    }

    double scale = [[UIScreen mainScreen] scale];
    if (scale <= 0)
        scale = 3.0;

    const char *pw = getenv("SIMULATOR_MAINSCREEN_WIDTH");
    const char *ph = getenv("SIMULATOR_MAINSCREEN_HEIGHT");
    int fbWidth = pw ? atoi(pw) : 1206;
    int fbHeight = ph ? atoi(ph) : 2622;
    iosim_fb_begin((unsigned)fbWidth, (unsigned)fbHeight);
    if (rootController)
        [rootController viewWillLayoutSubviews];
    render_view(window, 0, 0, scale, 1.0);
    if (rootController)
        [rootController viewDidLayoutSubviews];

    draw_device_chrome(fbWidth, scale);
    draw_keyboard(fbWidth, fbHeight, scale);
    draw_modals(rootController, fbWidth, fbHeight, scale);

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
        double touchDownX = 0, touchDownY = 0;
        int haveTouchDown = 0;
        int requestSwitcher = 0;
        double screenHeightPt = fbHeight / scale;
        while ((r = iosim_event_next(&type, &x, &y)) != 0)
        {
            int redraw = 0;
            if (r == 1 && type == 1)
            {
                if (alert_handle_tap(rootController, x, y, fbWidth, fbHeight,
                                     scale))
                    redraw = 1;
                else if (keyboard_handle_tap(x, y, fbWidth, fbHeight, scale))
                    redraw = 1;
                else
                {
                    [window dispatchTapX:x y:y];
                    redraw = 1;
                }
            }
            else if (r == 1 && type == 5 && g_firstResponder)
            {
                char buf[8];
                buf[0] = (char)x;
                buf[1] = 0;
                [g_firstResponder
                    insertText:[NSString stringWithUTF8String:buf]];
                redraw = 1;
            }
            else if (r == 1 && type == 6 && g_firstResponder)
            {
                [g_firstResponder deleteBackward];
                redraw = 1;
            }
            else if (r == 1 && type == 2)
            {
                touchDownX = x / scale;
                touchDownY = y / scale;
                haveTouchDown = 1;
                [window dispatchTouchDownX:x y:y];
                redraw = 1;
            }
            else if (r == 1 && type == 3)
            {
                [window dispatchTouchMoveX:x y:y];
                redraw = 1;
            }
            else if (r == 1 && type == 4)
            {
                double upX = x / scale, upY = y / scale;
                [window dispatchTouchUpX:x y:y];
                if (haveTouchDown &&
                    touchDownY > screenHeightPt - 45.0 &&
                    upY - touchDownY < -100.0 &&
                    upX - touchDownX > -140.0 &&
                    upX - touchDownX < 140.0)
                    requestSwitcher = 1;
                haveTouchDown = 0;
                redraw = 1;
            }
            else if (r == 1 && type == 7)
            {
                /* The system asked the app to background. */
                haveTouchDown = 0;
                requestSwitcher = 0;
                app_enter_background(sceneDelegate, scene, 0);
                redraw = 1;
            }
            if (requestSwitcher)
            {
                requestSwitcher = 0;
                app_enter_background(sceneDelegate, scene, 1);
                redraw = 1;
            }
            if ([window tickGestureRecognizers])
                redraw = 1;
            if (iosim_foundation_tick())
                redraw = 1;
            if (iosim_dispatch_drain_main())
                redraw = 1;
            if (iosim_display_link_tick())
                redraw = 1;
            if (iosim_animation_tick())
                redraw = 1;
            if (iosim_animations_active())
                redraw = 1;
            if (!redraw)
                continue;
            iosim_fb_set_opacity(1.0);
            if (rootController)
                [rootController viewWillLayoutSubviews];
            render_view(window, 0, 0, scale, 1.0);
            if (rootController)
                [rootController viewDidLayoutSubviews];
            draw_device_chrome(fbWidth, scale);
            draw_keyboard(fbWidth, fbHeight, scale);
            draw_modals(rootController, fbWidth, fbHeight, scale);
            if (path && *path)
                iosim_fb_present(path);
        }
    }
    return 0;
}
