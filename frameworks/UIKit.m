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
extern void iosim_fb_clear(unsigned color);
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
extern void iosim_fb_push_clip(int x, int y, int w, int h);
extern void iosim_fb_pop_clip(void);
extern double iosim_now(void);
extern int  iosim_foundation_tick(void);
extern int  iosim_dispatch_drain_main(void);
extern const char *iosim_string_cstr(id string);
extern int  strcmp(const char *a, const char *b);
extern unsigned long strlen(const char *s);
extern void *memcpy(void *dst, const void *src, unsigned long n);
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
    UIColor *_shadowColor;
    double _shadowOpacity;
    double _shadowRadius;
    CGSize _shadowOffset;
    double _borderWidth;
    UIColor *_borderColor;
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
}
- (id)init;
- (id)title;
- (void)setTitle:(id)title;
- (id)navigationController;
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

@interface UINavigationController : UIViewController {
@public
    id _stack[32];
    int _stackCount;
    UIView *_navBar;
    UILabel *_navTitleLabel;
    BOOL _navBarHidden;
    UIView *_contentView;
}
- (id)initWithRootViewController:(UIViewController *)root;
- (UIViewController *)topViewController;
- (NSArray *)viewControllers;
- (void)pushViewController:(UIViewController *)controller animated:(BOOL)animated;
- (UIViewController *)popViewControllerAnimated:(BOOL)animated;
- (void)setNavigationBarHidden:(BOOL)hidden animated:(BOOL)animated;
- (BOOL)isNavigationBarHidden;
@end

enum {
    UIControlStateNormal = 0,
    UIControlStateHighlighted = 1
};

enum {
    UIControlEventTouchUpInside = 1 << 6,
    UIControlEventEditingChanged = 1 << 17
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


@interface UIScrollView : UIView {
@public
    CGSize _contentSize;
    CGPoint _contentOffset;
    BOOL _scrollEnabled;
    BOOL _showsVerticalScrollIndicator;
    BOOL _bounces;
}
- (CGSize)contentSize;
- (void)setContentSize:(CGSize)size;
- (CGPoint)contentOffset;
- (void)setContentOffset:(CGPoint)offset;
- (void)setContentOffset:(CGPoint)offset animated:(BOOL)animated;
- (BOOL)isScrollEnabled;
- (void)setScrollEnabled:(BOOL)enabled;
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
    id _delegate;
    double _rowHeight;
    long _selectedRow;
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

@interface UIWindow : UIView {
@public
    UIViewController *_rootViewController;
    UIScrollView *_dragScroll;
    CGPoint _dragStartContent;
    CGPoint _dragStartPoint;
    UIView *_touchHit;
    UIPanGestureRecognizer *_activePan;
}
- (id)initWithWindowScene:(UIWindowScene *)scene;
- (void)setRootViewController:(UIViewController *)controller;
- (UIViewController *)rootViewController;
- (void)dispatchTapX:(int)x y:(int)y;
- (void)dispatchTouchDownX:(int)x y:(int)y;
- (void)dispatchTouchMoveX:(int)x y:(int)y;
- (void)dispatchTouchUpX:(int)x y:(int)y;
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
- (long)applicationState;
- (unsigned long)beginBackgroundTaskWithExpirationHandler:(void (^)(void))handler;
- (void)endBackgroundTask:(unsigned long)task;
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
        _animatingAlpha = YES;
        animation_mark_active(g_animDuration, 0);
    }
    _alpha = alpha;
}
- (double)alpha { return _alpha; }
- (id)superview { return _superview; }
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

static UITextField *g_firstResponder;

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
    _navTitleLabel->_text = top->_title;
    _view->_needsLayout = YES;
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
    long rows = 0;
    if (_dataSource &&
        [_dataSource respondsToSelector:
            @selector(tableView:numberOfRowsInSection:)])
    {
        SEL sel = @selector(tableView:numberOfRowsInSection:);
        rows = ((long (*)(id, void *, id, long))objc_msgSend)(
            _dataSource, (void *)sel, self, 0);
    }
    _contentSize = CGSizeMake(_frame.size.width, rows * _rowHeight);
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
    long row = (long)(point.y / _rowHeight);
    if (row < 0)
        return;
    _selectedRow = row;
    if (_delegate &&
        [_delegate respondsToSelector:@selector(tableView:didSelectRowAtIndexPath:)])
    {
        NSIndexPath *path = [NSIndexPath indexPathForRow:row inSection:0];
        [_delegate tableView:self didSelectRowAtIndexPath:path];
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
        }
    }
    if (_dragScroll)
        _dragStartContent = _dragScroll->_contentOffset;
    if (getenv("IOSIM_DEBUG_TOUCH"))
        printf("[touch] down hit=%p scroll=%p pan=%p\n", _touchHit,
               _dragScroll, _activePan);
}
- (void)dispatchTouchMoveX:(int)x y:(int)y
{
    double scale = [[UIScreen mainScreen] scale];
    if (scale <= 0)
        scale = 1.0;
    CGPoint point = CGPointMake(x / scale, y / scale);
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
        if (getenv("IOSIM_DEBUG_TOUCH"))
            printf("[touch] move offset=%.1f,%.1f max=%.1f,%.1f\n",
                   _dragScroll->_contentOffset.x,
                   _dragScroll->_contentOffset.y, maxX, maxY);
    }
}
- (void)dispatchTouchUpX:(int)x y:(int)y
{
    double scale = [[UIScreen mainScreen] scale];
    if (scale <= 0)
        scale = 1.0;
    CGPoint point = CGPointMake(x / scale, y / scale);
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
    _touchHit = nil;
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
    for (UIView *tv = hit; tv; tv = [tv superview])
        if ([tv isKindOfClass:[UITextField class]])
        {
            [(UITextField *)tv becomeFirstResponder];
            break;
        }
    if (hit && [hit isKindOfClass:[UIControl class]])
        [(UIControl *)hit sendActionsForControlEvents:UIControlEventTouchUpInside];
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

    CGAffineTransform tf = view->_transform;
    if (tf.a != 1.0 || tf.b != 0.0 || tf.c != 0.0 || tf.d != 1.0 ||
        tf.tx != 0.0 || tf.ty != 0.0)
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
    {
        iosim_fb_push_clip(x, y, w, h);
        clipped = 1;
    }

    if (view->_layer && view->_layer->_shadowOpacity > 0.001 &&
        w > 0 && h > 0)
    {
        double radius = view->_layer->_shadowRadius * scale;
        if (radius < 1)
            radius = 1;
        int ox = (int)(view->_layer->_shadowOffset.width * scale);
        int oy = (int)(view->_layer->_shadowOffset.height * scale);
        int corner = view->_layer ? (int)(view->_layer->_cornerRadius * scale + 0.5) : 0;
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
        double radius = view->_layer ? view->_layer->_cornerRadius : 0;
        if (radius > 0)
            iosim_fb_fill_round_rect(x, y, w, h, (int)(radius * scale + 0.5),
                                     color);
        else
            iosim_fb_fill_rect(x, y, w, h, color);
        iosim_fb_set_opacity(alpha);
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


    if ([view isKindOfClass:[UITableView class]])
    {
        UITableView *table = (UITableView *)view;
        long rows = 0;
        if (table->_dataSource &&
            [table->_dataSource respondsToSelector:
                @selector(tableView:numberOfRowsInSection:)])
        {
            SEL sel = @selector(tableView:numberOfRowsInSection:);
            rows = ((long (*)(id, void *, id, long))objc_msgSend)(
                table->_dataSource, (void *)sel, table, 0);
        }
        double rowHeight = table->_rowHeight;
        double tableScrollY = table->_contentOffset.y;
        for (long i = 0; i < rows; i++)
        {
            NSIndexPath *path = [NSIndexPath indexPathForRow:i inSection:0];
            if (table->_delegate &&
                [table->_delegate respondsToSelector:
                    @selector(tableView:heightForRowAtIndexPath:)])
            {
                SEL sel = @selector(tableView:heightForRowAtIndexPath:);
                rowHeight = ((double (*)(id, void *, id, id))objc_msgSend)(
                    table->_delegate, (void *)sel, table, path);
            }
            int ry = y + (int)((i * rowHeight - tableScrollY) * scale + 0.5);
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
                cell->_frame = CGRectMake(0, i * rowHeight - tableScrollY,
                                          frame.size.width, rowHeight);
                [cell setFrame:cell->_frame];
                UIColor *savedBackground = cell->_backgroundColor;
                if (i == table->_selectedRow)
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
        }
        iosim_fb_set_opacity(1.0);
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
        int tx = x + (int)(12 * scale);
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
            iosim_fb_font_text(tx, baseline, placeholder, style, points, scale,
                               0x8e8e93);
            textWidth = iosim_fb_font_text_width(placeholder, style, points,
                                                 scale);
        }
        if (field->_firstResponder)
        {
            int caretX = tx + textWidth + (int)(1 * scale);
            int caretH = (int)(22 * scale);
            iosim_fb_fill_rect(caretX, baseline - ascent, (int)(2 * scale),
                               caretH, 0x0a84ff);
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
            iosim_fb_fill_round_rect((int)((277.5 + i * 5.667) * scale),
                                     (int)((42.0 - (3 + i * 2)) * scale),
                                     (int)(3.0 * scale),
                                     (int)((3 + i * 2) * scale),
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
        double boltX[7] = {344.5, 349.5, 347.0, 351.0, 344.0, 347.5, 344.5};
        double boltY[7] = {28.0, 28.0, 32.0, 32.0, 37.0, 33.0, 33.0};
        for (int i = 0; i < 7; i++)
        {
            boltX[i] *= scale;
            boltY[i] *= scale;
        }
        iosim_fb_fill_polygon(boltX, boltY, 7, 0xffffff);
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
    return g_firstResponder != 0;
}

static void keyboard_row_1(int fbW, double scale, int y, int h, int special)
{
    (void)special;
    double margin = 3, gap = 6;
    double kw = ((double)fbW / scale - 2 * margin - 9 * gap) / 10.0;
    static const char *letters = "QWERTYUIOP";
    for (int i = 0; i < 10; i++)
    {
        int x = (int)((margin + i * (kw + gap)) * scale + 0.5);
        int w = (int)(kw * scale + 0.5);
        iosim_fb_fill_round_rect(x, y, w, h, (int)(5 * scale), 0x6b6b6d);
        char label[2] = { letters[i], 0 };
        int lw = iosim_fb_font_text_width(label, IOSIM_FONT_REGULAR, 22, scale);
        int asc = 0, desc = 0, lh = 0;
        iosim_fb_font_metrics(IOSIM_FONT_REGULAR, 22, scale, &asc, &desc, &lh);
        iosim_fb_font_text(x + (w - lw) / 2, y + (h - lh) / 2 + asc, label,
                           IOSIM_FONT_REGULAR, 22, scale, 0xffffff);
    }
}

static void keyboard_row_2(int fbW, double scale, int y, int h)
{
    double margin = 3, gap = 6;
    double kw = ((double)fbW / scale - 2 * margin - 9 * gap) / 10.0;
    static const char *letters = "ASDFGHJKL";
    for (int i = 0; i < 9; i++)
    {
        int x = (int)((margin + (kw + gap) / 2 + i * (kw + gap)) * scale + 0.5);
        int w = (int)(kw * scale + 0.5);
        iosim_fb_fill_round_rect(x, y, w, h, (int)(5 * scale), 0x6b6b6d);
        char label[2] = { letters[i], 0 };
        int lw = iosim_fb_font_text_width(label, IOSIM_FONT_REGULAR, 22, scale);
        int asc = 0, desc = 0, lh = 0;
        iosim_fb_font_metrics(IOSIM_FONT_REGULAR, 22, scale, &asc, &desc, &lh);
        iosim_fb_font_text(x + (w - lw) / 2, y + (h - lh) / 2 + asc, label,
                           IOSIM_FONT_REGULAR, 22, scale, 0xffffff);
    }
}

static void keyboard_row_3(int fbW, double scale, int y, int h)
{
    double margin = 3, gap = 6;
    double kw = ((double)fbW / scale - 2 * margin - 9 * gap) / 10.0;
    int shiftW = (int)(42 * scale);
    iosim_fb_fill_round_rect((int)(margin * scale), y, shiftW, h,
                             (int)(5 * scale), 0x4a4a4d);
    iosim_fb_font_text((int)(margin * scale) + shiftW / 2 -
                           (int)(7 * scale), y + h / 2 + (int)(7 * scale),
                       "⇧", IOSIM_FONT_REGULAR, 20, scale, 0xffffff);
    static const char *letters = "ZXCVBNM";
    for (int i = 0; i < 7; i++)
    {
        int x = (int)((margin + 42 + gap + i * (kw + gap)) * scale + 0.5);
        int w = (int)(kw * scale + 0.5);
        iosim_fb_fill_round_rect(x, y, w, h, (int)(5 * scale), 0x6b6b6d);
        char label[2] = { letters[i], 0 };
        int lw = iosim_fb_font_text_width(label, IOSIM_FONT_REGULAR, 22, scale);
        int asc = 0, desc = 0, lh = 0;
        iosim_fb_font_metrics(IOSIM_FONT_REGULAR, 22, scale, &asc, &desc, &lh);
        iosim_fb_font_text(x + (w - lw) / 2, y + (h - lh) / 2 + asc, label,
                           IOSIM_FONT_REGULAR, 22, scale, 0xffffff);
    }
    int delW = (int)(42 * scale);
    int delX = fbW - (int)(margin * scale) - delW;
    iosim_fb_fill_round_rect(delX, y, delW, h, (int)(5 * scale), 0x4a4a4d);
    int dw = iosim_fb_font_text_width("⌫", IOSIM_FONT_REGULAR, 20, scale);
    iosim_fb_font_text(delX + (delW - dw) / 2,
                       y + h / 2 + (int)(7 * scale), "⌫",
                       IOSIM_FONT_REGULAR, 20, scale, 0xffffff);
}

static void keyboard_row_4(int fbW, double scale, int y, int h)
{
    double margin = 3, gap = 6;
    int numW = (int)(87 * scale);
    int globeW = (int)(34 * scale);
    int retW = (int)(84 * scale);
    iosim_fb_fill_round_rect((int)(margin * scale), y, numW, h,
                             (int)(5 * scale), 0x4a4a4d);
    int nw = iosim_fb_font_text_width("123", IOSIM_FONT_REGULAR, 16, scale);
    iosim_fb_font_text((int)(margin * scale) + (numW - nw) / 2,
                       y + h / 2 + (int)(6 * scale), "123",
                       IOSIM_FONT_REGULAR, 16, scale, 0xffffff);
    int globeX = (int)(margin * scale) + numW + (int)(gap * scale);
    iosim_fb_fill_round_rect(globeX, y, globeW, h, (int)(5 * scale), 0x4a4a4d);
    int gcx = globeX + globeW / 2, gcy = y + h / 2;
    int gr = (int)(9 * scale);
    iosim_fb_fill_circle(gcx, gcy, gr, 0xffffff);
    iosim_fb_fill_circle(gcx, gcy, gr - (int)(2 * scale), 0x4a4a4d);
    iosim_fb_fill_rect(gcx - (int)(1 * scale), gcy - gr + (int)(2 * scale),
                       (int)(2 * scale), gr * 2 - (int)(4 * scale), 0xffffff);
    iosim_fb_fill_rect(gcx - gr + (int)(2 * scale), gcy - (int)(1 * scale),
                       gr * 2 - (int)(4 * scale), (int)(2 * scale), 0xffffff);
    int spaceX = globeX + globeW + (int)(gap * scale);
    int retX = fbW - (int)(margin * scale) - retW;
    int spaceW = retX - (int)(gap * scale) - spaceX;
    iosim_fb_fill_round_rect(spaceX, y, spaceW, h, (int)(5 * scale),
                             0x6b6b6d);
    iosim_fb_fill_round_rect(retX, y, retW, h, (int)(5 * scale), 0x4a4a4d);
    int rw = iosim_fb_font_text_width("return", IOSIM_FONT_REGULAR, 16, scale);
    iosim_fb_font_text(retX + (retW - rw) / 2,
                       y + h / 2 + (int)(6 * scale), "return",
                       IOSIM_FONT_REGULAR, 16, scale, 0xffffff);
}

static int keyboard_handle_tap(int px, int py, int fbW, int fbH,
                               double scale)
{
    if (!keyboard_visible() || scale <= 0)
        return 0;
    double x = px / scale, y = py / scale;
    double W = fbW / scale, H = fbH / scale;
    const char *hEnv = getenv("IOSIM_KEYBOARD_HEIGHT");
    double kbH = hEnv ? atof(hEnv) : 291.0;
    double top = H - kbH;
    if (y < top)
        return 0;
    double rowsTop = top + 50, rowH = 43, gap = 12;
    int row = (int)((y - rowsTop) / (rowH + gap));
    double localY = y - (rowsTop + row * (rowH + gap));
    if (row < 0 || row > 3 || localY > rowH)
        return 1;
    double margin = 3, keyGap = 6;
    double kw = (W - 2 * margin - 9 * keyGap) / 10.0;
    char buf[8];
    if (row == 0)
    {
        int i = (int)((x - margin) / (kw + keyGap));
        if (i >= 0 && i < 10)
        {
            buf[0] = "QWERTYUIOP"[i];
            buf[1] = 0;
            [g_firstResponder insertText:[NSString stringWithUTF8String:buf]];
            return 1;
        }
    }
    else if (row == 1)
    {
        int i = (int)((x - margin - (kw + keyGap) / 2) / (kw + keyGap));
        if (i >= 0 && i < 9)
        {
            buf[0] = "ASDFGHJKL"[i];
            buf[1] = 0;
            [g_firstResponder insertText:[NSString stringWithUTF8String:buf]];
            return 1;
        }
    }
    else if (row == 2)
    {
        if (x < margin + 42)
            return 1;
        int i = (int)((x - margin - 42 - keyGap) / (kw + keyGap));
        if (i >= 0 && i < 7)
        {
            buf[0] = "ZXCVBNM"[i];
            buf[1] = 0;
            [g_firstResponder insertText:[NSString stringWithUTF8String:buf]];
            return 1;
        }
        if (x > W - margin - 42)
        {
            [g_firstResponder deleteBackward];
            return 1;
        }
    }
    else
    {
        if (x < margin + 87)
            return 1;
        if (x < margin + 87 + keyGap + 34)
            return 1;
        if (x > W - margin - 84)
        {
            [(UITextField *)g_firstResponder
                sendActionsForControlEvents:1 << 18];
            return 1;
        }
        [g_firstResponder insertText:[NSString stringWithUTF8String:" "]];
        return 1;
    }
    return 1;
}

static void draw_keyboard(int fbW, int fbH, double scale)
{
    if (!keyboard_visible() || scale <= 0)
        return;
    double widthPt = fbW / scale, heightPt = fbH / scale;
    const char *hEnv = getenv("IOSIM_KEYBOARD_HEIGHT");
    double kbH = hEnv ? atof(hEnv) : 291.0;
    double topPt = heightPt - kbH;
    int top = (int)(topPt * scale + 0.5);
    iosim_fb_set_opacity(1.0);
    iosim_fb_fill_rect(0, top, fbW, fbH - top, 0x1c1c1e);
    double rowsTopPt = topPt + 50;
    int rowH = (int)(43 * scale);
    int gap = (int)(12 * scale);
    int y0 = (int)(rowsTopPt * scale + 0.5);
    keyboard_row_1(fbW, scale, y0, rowH, 0);
    keyboard_row_2(fbW, scale, y0 + rowH + gap, rowH);
    keyboard_row_3(fbW, scale, y0 + 2 * (rowH + gap), rowH);
    keyboard_row_4(fbW, scale, y0 + 3 * (rowH + gap), rowH);
    int hw = (int)(134 * scale);
    iosim_fb_fill_round_rect((fbW - hw) / 2, fbH - (int)(13 * scale), hw,
                             (int)(5 * scale), (int)(2.5 * scale),
                             0xffffff);
}

/* -------------------------------------------------------- springboard UI */

static const char *shell_names[12] = {
    "Calendar", "Photos", "Camera", "Mail", "Maps", "Weather",
    "Clock", "Notes", "Settings", "App Store", "Files", "Health"
};

static void shell_tile(int x, int y, int size, unsigned top, unsigned bottom,
                       double scale, int radius)
{
    iosim_fb_fill_linear_gradient_round_rect(x, y, size, size,
                                             (int)(radius * scale), top,
                                             bottom, 0.5, 0.0, 0.5, 1.0);
}

static void shell_glyph(int index, int x, int y, int size, double scale)
{
    int cx = x + size / 2, cy = y + size / 2;
    double u = size / 60.0;
    switch (index)
    {
    case 0: /* Calendar */
        iosim_fb_font_text(cx - (int)(13 * u), cy + (int)(8 * u), "20",
                           IOSIM_FONT_REGULAR, 22, scale, 0x111111);
        break;
    case 1: /* Photos */
    {
        static const unsigned petals[8] = {
            0xffd60a, 0xff9f0a, 0xff453a, 0xbf5af2,
            0x0a84ff, 0x64d2ff, 0x30d158, 0xff2d55
        };
        for (int i = 0; i < 8; i++)
        {
            double a = 2 * 3.14159265358979323846 * i / 8.0;
            iosim_fb_fill_circle((int)(cx + __builtin_cos(a) * size * 0.18),
                                 (int)(cy + __builtin_sin(a) * size * 0.18),
                                 (int)(size * 0.125), petals[i]);
        }
        iosim_fb_fill_circle(cx, cy, (int)(size * 0.06), 0xffffff);
        break;
    }
    case 2: /* Camera */
        iosim_fb_fill_circle(cx, cy, (int)(size * 0.29), 0x1c1c1e);
        iosim_fb_fill_circle(cx, cy, (int)(size * 0.20), 0x0a84ff);
        iosim_fb_fill_circle(cx - (int)(size * 0.05),
                             cy - (int)(size * 0.05), (int)(size * 0.05),
                             0xffffff);
        break;
    case 3: /* Mail */
        iosim_fb_fill_round_rect(x + (int)(size * 0.18), y + (int)(size * 0.30),
                                 (int)(size * 0.64), (int)(size * 0.40),
                                 (int)(size * 0.06), 0xffffff);
        iosim_fb_draw_line(x + (int)(size * 0.18), y + (int)(size * 0.30),
                           cx, y + (int)(size * 0.55), (int)(2 * u), 0x2f8cff);
        iosim_fb_draw_line(cx, y + (int)(size * 0.55),
                           x + (int)(size * 0.82), y + (int)(size * 0.30),
                           (int)(2 * u), 0x2f8cff);
        break;
    case 4: /* Maps */
        iosim_fb_draw_line(x + (int)(size * 0.05), y + (int)(size * 0.68),
                           x + (int)(size * 0.95), y + (int)(size * 0.32),
                           (int)(5 * u), 0xffffff);
        iosim_fb_draw_line(x + (int)(size * 0.30), y + (int)(size * 0.05),
                           x + (int)(size * 0.58), y + (int)(size * 0.95),
                           (int)(3 * u), 0xffd60a);
        iosim_fb_fill_circle(x + (int)(size * 0.62), y + (int)(size * 0.40),
                             (int)(size * 0.09), 0xff453a);
        break;
    case 5: /* Weather */
        iosim_fb_fill_circle(x + (int)(size * 0.34), y + (int)(size * 0.36),
                             (int)(size * 0.15), 0xffd60a);
        iosim_fb_fill_circle(x + (int)(size * 0.45), y + (int)(size * 0.60),
                             (int)(size * 0.16), 0xffffff);
        iosim_fb_fill_circle(x + (int)(size * 0.62), y + (int)(size * 0.60),
                             (int)(size * 0.20), 0xffffff);
        iosim_fb_fill_round_rect(x + (int)(size * 0.30),
                                 y + (int)(size * 0.58),
                                 (int)(size * 0.48), (int)(size * 0.18),
                                 (int)(size * 0.09), 0xffffff);
        break;
    case 6: /* Clock */
    {
        for (int i = 0; i < 48; i++)
        {
            double a = 2 * 3.14159265358979323846 * i / 48.0;
            double x0 = cx + __builtin_cos(a) * size * 0.37;
            double y0 = cy + __builtin_sin(a) * size * 0.37;
            iosim_fb_fill_circle((int)x0, (int)y0, (int)(1.6 * u), 0xffffff);
        }
        iosim_fb_draw_line(cx, cy, cx, cy - (int)(size * 0.24),
                           (int)(3 * u), 0xffffff);
        iosim_fb_draw_line(cx, cy, cx + (int)(size * 0.18), cy,
                           (int)(3 * u), 0xffffff);
        break;
    }
    case 7: /* Notes */
        iosim_fb_fill_rect(x + (int)(size * 0.16), y + (int)(size * 0.12),
                           (int)(size * 0.68), (int)(size * 0.13), 0xffd60a);
        for (int i = 0; i < 3; i++)
            iosim_fb_fill_round_rect(x + (int)(size * 0.20),
                                     y + (int)(size * (0.40 + i * 0.13)),
                                     (int)(size * 0.60), (int)(3 * u),
                                     (int)(1.5 * u), 0xc7c7cc);
        break;
    case 8: /* Settings */
    {
        iosim_fb_fill_circle(cx, cy, (int)(size * 0.19), 0xffffff);
        iosim_fb_fill_circle(cx, cy, (int)(size * 0.10), 0x636366);
        for (int i = 0; i < 8; i++)
        {
            double a = 2 * 3.14159265358979323846 * i / 8.0;
            iosim_fb_draw_line((int)(cx + __builtin_cos(a) * size * 0.24),
                               (int)(cy + __builtin_sin(a) * size * 0.24),
                               (int)(cx + __builtin_cos(a) * size * 0.36),
                               (int)(cy + __builtin_sin(a) * size * 0.36),
                               (int)(7 * u), 0xffffff);
        }
        break;
    }
    case 9: /* App Store */
        iosim_fb_font_text(cx - (int)(9 * u), cy + (int)(9 * u), "A",
                           IOSIM_FONT_SEMIBOLD, 22, scale, 0xffffff);
        break;
    case 10: /* Files */
        iosim_fb_fill_round_rect(x + (int)(size * 0.16),
                                 y + (int)(size * 0.28),
                                 (int)(size * 0.68), (int)(size * 0.46),
                                 (int)(size * 0.07), 0x0a84ff);
        iosim_fb_fill_round_rect(x + (int)(size * 0.16),
                                 y + (int)(size * 0.20),
                                 (int)(size * 0.34), (int)(size * 0.18),
                                 (int)(size * 0.05), 0x0a84ff);
        break;
    case 11: /* Health */
    {
        iosim_fb_fill_circle(cx - (int)(size * 0.10),
                             cy - (int)(size * 0.06), (int)(size * 0.14),
                             0xff2d55);
        iosim_fb_fill_circle(cx + (int)(size * 0.10),
                             cy - (int)(size * 0.06), (int)(size * 0.14),
                             0xff2d55);
        double xs[3] = {cx - (double)(size * 0.22), cx + (double)(size * 0.22),
                        cx};
        double ys[3] = {cy - (double)(size * 0.02), cy - (double)(size * 0.02),
                        cy + (double)(size * 0.24)};
        iosim_fb_fill_polygon(xs, ys, 3, 0xff2d55);
        break;
    }
    }
}

static void shell_draw(int fbWidth, int fbHeight, double scale, int launched)
{
    iosim_fb_clear(0x05070d);
    iosim_fb_fill_linear_gradient(0, 0, fbWidth, fbHeight, 0x1c3f78, 0x05070d,
                                  0.3, 0.0, 0.7, 1.0);
    iosim_fb_set_opacity(0.10);
    iosim_fb_fill_circle((int)(70 * scale), (int)(210 * scale),
                         (int)(175 * scale), 0x3f8cff);
    iosim_fb_fill_circle((int)(360 * scale), (int)(640 * scale),
                         (int)(165 * scale), 0x8e5cff);
    iosim_fb_set_opacity(1.0);

    int icon = (int)(60 * scale);
    int step = (int)(87 * scale);
    int left = (int)(40.5 * scale);
    for (int i = 0; i < 12; i++)
    {
        int row = i / 4, col = i % 4;
        int x = left + col * step;
        int y = (int)((116 + row * 98) * scale);
        unsigned top = 0x2c2c2e, bottom = 0x1c1c1e;
        switch (i)
        {
        case 0: top = 0xffffff; bottom = 0xe9e9ee; break;
        case 1: top = 0xffffff; bottom = 0xf2f2f7; break;
        case 2: top = 0x4a4a4c; bottom = 0x1c1c1e; break;
        case 3: top = 0x2f8cff; bottom = 0x0a64d8; break;
        case 4: top = 0xa8e0a0; bottom = 0x6fc3ff; break;
        case 5: top = 0x2f9bff; bottom = 0x0a5bd6; break;
        case 6: top = 0x2c2c2e; bottom = 0x000000; break;
        case 7: top = 0xffffff; bottom = 0xf7f7f7; break;
        case 8: top = 0x8e8e93; bottom = 0x48484a; break;
        case 9: top = 0x1e9bff; bottom = 0x0a64d8; break;
        case 10: top = 0xffffff; bottom = 0xf0f0f5; break;
        case 11: top = 0xffffff; bottom = 0xf8f8fa; break;
        }
        shell_tile(x, y, icon, top, bottom, scale, 14);
        shell_glyph(i, x, y, icon, scale);
        const char *name = shell_names[i];
        int tw = iosim_fb_font_text_width(name, IOSIM_FONT_REGULAR, 11,
                                          scale);
        iosim_fb_font_text(x + icon / 2 - tw / 2,
                           y + icon + (int)(16 * scale), name,
                           IOSIM_FONT_REGULAR, 11, scale, 0xffffff);
    }

    /* Weather-style widget. */
    int wx = (int)(24 * scale), wy = (int)(430 * scale);
    int ww = fbWidth - (int)(48 * scale), wh = (int)(144 * scale);
    iosim_fb_fill_linear_gradient_round_rect(wx, wy, ww, wh,
                                             (int)(20 * scale), 0x2f6fe0,
                                             0x173a7a, 0.0, 0.0, 1.0, 1.0);
    iosim_fb_font_text(wx + (int)(18 * scale), wy + (int)(30 * scale),
                       "Cupertino", IOSIM_FONT_SEMIBOLD, 15, scale, 0xffffff);
    iosim_fb_font_text(wx + (int)(16 * scale), wy + (int)(92 * scale), "68\xc2\xb0",
                       IOSIM_FONT_REGULAR, 44, scale, 0xffffff);
    iosim_fb_font_text(wx + (int)(150 * scale), wy + (int)(92 * scale), "Sunny",
                       IOSIM_FONT_REGULAR, 16, scale, 0xeaf2ff);
    iosim_fb_font_text(wx + (int)(150 * scale), wy + (int)(112 * scale),
                       "H:71\xc2\xb0  L:52\xc2\xb0", IOSIM_FONT_REGULAR, 14,
                       scale, 0xeaf2ff);

    /* Search pill and page dots. */
    iosim_fb_set_opacity(0.16);
    iosim_fb_fill_round_rect((int)(94 * scale), (int)(716 * scale),
                             (int)(214 * scale), (int)(32 * scale),
                             (int)(16 * scale), 0xffffff);
    iosim_fb_set_opacity(1.0);
    int sw = iosim_fb_font_text_width("Search", IOSIM_FONT_REGULAR, 14, scale);
    iosim_fb_font_text((int)(201 * scale) - sw / 2, (int)(737 * scale),
                       "Search", IOSIM_FONT_REGULAR, 14, scale, 0x3a4150);
    iosim_fb_fill_circle((int)(188 * scale), (int)(697 * scale),
                         (int)(3.5 * scale), 0xffffff);
    iosim_fb_fill_circle((int)(214 * scale), (int)(697 * scale),
                         (int)(3.5 * scale), 0x6b7485);

    /* Dock. */
    iosim_fb_set_opacity(0.12);
    iosim_fb_fill_round_rect((int)(12 * scale), (int)(752 * scale),
                             fbWidth - (int)(24 * scale),
                             (int)(96 * scale), (int)(30 * scale), 0xffffff);
    iosim_fb_set_opacity(1.0);
    int dockIcon = (int)(58 * scale);
    int dockLeft = (int)(34 * scale);
    int dockStep = (int)(92 * scale);
    static const unsigned dockTop[4] = {0x4cd964, 0x0a84ff, 0x33d158, 0xfa5c78};
    static const unsigned dockBottom[4] = {0x22a94a, 0x0064d8, 0x0f9d3a, 0xb03050};
    for (int i = 0; i < 4; i++)
    {
        int x = dockLeft + i * dockStep, y = (int)(772 * scale);
        shell_tile(x, y, dockIcon, dockTop[i], dockBottom[i], scale, 14);
        if (i == 0)
        {
            iosim_fb_fill_circle(x + dockIcon / 2, y + dockIcon / 2,
                                 (int)(dockIcon * 0.24), 0xffffff);
        }
        else if (i == 1)
        {
            iosim_fb_fill_circle(x + dockIcon / 2, y + dockIcon / 2,
                                 (int)(dockIcon * 0.32), 0xffffff);
            iosim_fb_fill_circle(x + dockIcon / 2, y + dockIcon / 2,
                                 (int)(dockIcon * 0.27), 0x0a84ff);
            iosim_fb_fill_polygon(
                (double[]){x + dockIcon * 0.5, x + dockIcon * 0.68,
                           x + dockIcon * 0.5},
                (double[]){y + dockIcon * 0.5, y + dockIcon * 0.5,
                           y + dockIcon * 0.30}, 3, 0xff453a);
        }
        else if (i == 2)
        {
            iosim_fb_fill_round_rect(x + (int)(dockIcon * 0.16),
                                     y + (int)(dockIcon * 0.20),
                                     (int)(dockIcon * 0.68),
                                     (int)(dockIcon * 0.52),
                                     (int)(dockIcon * 0.26), 0xffffff);
        }
        else
        {
            int nx = x + (int)(dockIcon * 0.60), ny = y + (int)(dockIcon * 0.30);
            iosim_fb_draw_line(nx, ny, nx, y + (int)(dockIcon * 0.66),
                               (int)(3 * scale), 0xffffff);
            iosim_fb_fill_circle(nx, y + (int)(dockIcon * 0.66),
                                 (int)(dockIcon * 0.08), 0xffffff);
            iosim_fb_fill_circle(x + (int)(dockIcon * 0.32),
                                 y + (int)(dockIcon * 0.54),
                                 (int)(dockIcon * 0.10), 0xffffff);
        }
    }

    iosim_fb_set_opacity(0.85);
    iosim_fb_fill_round_rect((int)(134 * scale), (int)(856 * scale),
                             (int)(134 * scale), (int)(5 * scale),
                             (int)(2.5 * scale), 0xffffff);
    iosim_fb_set_opacity(1.0);

    draw_device_chrome(fbWidth, scale);
    for (int i = 0; i < 4; i++)
        iosim_fb_fill_round_rect((int)((277.5 + i * 5.667) * scale),
                                 (int)((42.0 - (3 + i * 2)) * scale),
                                 (int)(3.0 * scale),
                                 (int)((3 + i * 2) * scale),
                                 (int)(1.0 * scale), 0xffffff);

    if (launched >= 0 && launched < 12)
    {
        iosim_fb_set_opacity(0.62);
        iosim_fb_fill_rect(0, 0, fbWidth, fbHeight, 0x000000);
        iosim_fb_set_opacity(1.0);
        int cx = fbWidth / 2, cy = (int)(400 * scale);
        int cardW = (int)(300 * scale), cardH = (int)(330 * scale);
        iosim_fb_fill_round_rect(cx - cardW / 2, cy - cardH / 2, cardW, cardH,
                                 (int)(26 * scale), 0x1c1c1e);
        int big = (int)(96 * scale);
        shell_tile(cx - big / 2, cy - cardH / 2 + (int)(40 * scale), big,
                   0x2f8cff, 0x0a64d8, scale, 20);
        shell_glyph(launched, cx - big / 2,
                    cy - cardH / 2 + (int)(40 * scale), big, scale);
        int nw = iosim_fb_font_text_width(shell_names[launched],
                                          IOSIM_FONT_SEMIBOLD, 24, scale);
        iosim_fb_font_text(cx - nw / 2, cy + (int)(30 * scale),
                           shell_names[launched], IOSIM_FONT_SEMIBOLD, 24,
                           scale, 0xffffff);
        const char *hint = "Tap anywhere to return";
        int hw = iosim_fb_font_text_width(hint, IOSIM_FONT_REGULAR, 14, scale);
        iosim_fb_font_text(cx - hw / 2, cy + (int)(66 * scale), hint,
                           IOSIM_FONT_REGULAR, 14, scale, 0x9aa5b8);
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

    int launched = -1;
    shell_draw(fbWidth, fbHeight, scale, launched);
    const char *path = getenv("IOSIM_SCREENSHOT_PATH");
    if (path && *path)
        iosim_fb_present(path);
    printf("[SpringBoard-lite] home screen rendered at %.1fx\n", scale);

    const char *fifo = getenv("IOSIM_EVENT_FIFO");
    if (!fifo || !*fifo)
        return 0;

    int type = 0, x = 0, y = 0, r;
    while ((r = iosim_event_next(&type, &x, &y)) != 0)
    {
        if (r != 1 || type != 1)
            continue;
        double px = x / scale, py = y / scale;
        int changed = 0;
        if (launched >= 0)
        {
            launched = -1;
            changed = 1;
        }
        else
        {
            int icon = 60, step = 87, left = 40;
            for (int i = 0; i < 12; i++)
            {
                int gx = left + (i % 4) * step;
                int gy = 116 + (i / 4) * 98;
                if (px >= gx && px < gx + icon && py >= gy && py < gy + icon)
                {
                    launched = i;
                    changed = 1;
                    printf("[SpringBoard-lite] launch %s\n", shell_names[i]);
                    break;
                }
            }
            if (!changed)
            {
                for (int i = 0; i < 4; i++)
                {
                    int gx = 34 + i * 92, gy = 772;
                    if (px >= gx && px < gx + 58 && py >= gy && py < gy + 58)
                    {
                        launched = i;
                        changed = 1;
                        printf("[SpringBoard-lite] dock launch %d\n", i);
                        break;
                    }
                }
            }
        }
        if (!changed)
            continue;
        shell_draw(fbWidth, fbHeight, scale, launched);
        if (path && *path)
            iosim_fb_present(path);
    }
    return 0;
}

int UIApplicationMain(int argc, char **argv, id principal, id delegateName)
{
    (void)principal;
    (void)argv;
    const char *shellMode = getenv("IOSIM_SHELL");
    if (shellMode && *shellMode)
        return run_springboard();

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
    render_view(window, 0, 0, scale, 1.0);

    draw_device_chrome(fbWidth, scale);
    draw_keyboard(fbWidth, fbHeight, scale);

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
                if (keyboard_handle_tap(x, y, fbWidth, fbHeight, scale))
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
                [window dispatchTouchUpX:x y:y];
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
            draw_device_chrome(fbWidth, scale);
            draw_keyboard(fbWidth, fbHeight, scale);
            if (path && *path)
                iosim_fb_present(path);
        }
    }
    return 0;
}
