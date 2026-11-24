/* UIKit-lite: a real Objective-C UIKit subset for the iosim runtime.
 *
 * Built as an x86_64 Mach-O dylib at the canonical install name. Classes are
 * registered by the iosim Objective-C runtime like any app class. The frame
 * is rendered through the loader's software framebuffer.
 *
 * Supported: UIApplicationMain, UIApplication, UIWindow, UIView, UILabel,
 * UIColor, UIFont, UIScreen, CALayer (cornerRadius), UIResponder. */

#include "foundation_lite.h"
#include "coregraphics_lite.h"

extern int printf(const char *fmt, ...);
extern int fflush(void *stream);
extern int fprintf(void *stream, const char *fmt, ...);
extern void *stderr;
extern char *getenv(const char *name);
extern int atoi(const char *s);
extern double atof(const char *s);
extern double pow(double base, double exponent);
void UIAccessibilityPostNotification(unsigned int notification, id argument)
{
    (void)notification;
    (void)argument;
}
BOOL UIAccessibilityIsVoiceOverRunning(void) { return NO; }
BOOL UIAccessibilityIsReduceMotionEnabled(void) { return NO; }
BOOL UIAccessibilityIsReduceTransparencyEnabled(void) { return NO; }
BOOL UIAccessibilityIsSwitchControlRunning(void) { return NO; }
BOOL UIAccessibilityIsBoldTextEnabled(void) { return NO; }
BOOL UIAccessibilityIsInvertColorsEnabled(void) { return NO; }
BOOL UIAccessibilityIsGrayscaleEnabled(void) { return NO; }
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
extern int  iosim_fb_width(void);
extern int  iosim_fb_height(void);
extern int  iosim_event_next(int *type, int *x, int *y);
extern void iosim_event_second_point(int *x, int *y);
extern int  iosim_event_touch_id(void);
extern int  iosim_event_open(void);
extern void iosim_fb_set_opacity(double opacity);
extern int iosim_fb_push_clip(int x, int y, int w, int h);
extern void iosim_fb_pop_clip(void);
extern int iosim_fb_push_clip_alpha(const unsigned char *alpha, int w,
                                    int h, int x, int y);
extern void iosim_fb_pop_clip_mask(void);
extern double iosim_now(void);
extern int usleep(unsigned int usec);
extern int  iosim_foundation_tick(void);
extern int  iosim_dispatch_drain_main(void);
extern const char *iosim_string_cstr(id string);
extern int  strcmp(const char *a, const char *b);
extern int  strncmp(const char *a, const char *b, unsigned long n);
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
extern int  iosim_fs_remove(const char *path);
extern int  iosim_fs_list(const char *path, char *out, unsigned long cap);
extern double iosim_wall_time(void);
static void shell_badge_store(const char *bundle, int count);
extern int  iosim_png_load(const char *path, unsigned char **out_rgba,
                           int *out_width, int *out_height);
extern int  iosim_png_load_memory(const unsigned char *bytes,
                                  unsigned long length,
                                  unsigned char **out_rgba,
                           int *out_width, int *out_height);
extern void *_Block_copy(void *block);
extern void _Block_release(void *block);
extern void iosim_fb_fill_ellipse(int cx, int cy, int rx, int ry,
                                  unsigned color);
extern void iosim_fb_draw_line(int x0, int y0, int x1, int y1, int thickness,
                               unsigned color);
extern void iosim_fb_fill_polygon(const double *xs, const double *ys,
                                  int count, unsigned color);
extern void iosim_fb_stroke_polyline(const double *xs, const double *ys,
                                     int count, int closed, double start,
                                     double end, double width,
                                     unsigned color, int cap, int join,
                                     double miter_limit, const double *dash,
                                     int dash_count, double dash_phase);
extern void iosim_fb_fill_linear_gradient(int x, int y, int w, int h,
                                          unsigned start_color,
                                          unsigned end_color,
                                          double sx, double sy,
                                          double ex, double ey);
extern void iosim_fb_fill_gradient_stops(int x, int y, int w, int h,
                                         const unsigned *colors,
                                         const double *locations, int count,
                                         double ax, double ay, double bx,
                                         double by);
extern void iosim_fb_fill_gradient_stops_alpha(int x, int y, int w, int h,
                                               const unsigned *colors,
                                               const unsigned char *alphas,
                                               const double *locations,
                                               int count, double ax,
                                               double ay, double bx,
                                               double by);
extern void *iosim_fb_begin_offscreen(unsigned width, unsigned height);
extern unsigned *iosim_fb_end_offscreen(void *state, int *out_w, int *out_h);
extern void iosim_fb_stroke_circle(int cx, int cy, int radius, int thickness,
                                   unsigned color);
extern void iosim_fb_mask_round_rect(int x, int y, int w, int h, int radius);
extern void iosim_fb_mask_round_rect_corners(int x, int y, int w, int h,
                                             int radius, unsigned corners);
extern void iosim_fb_blit_affine(const unsigned *src, int sw, int sh,
                                 double fa, double fb, double fc, double fd,
                                 double ftx, double fty, double opacity);
extern void iosim_fb_blit_homography(const unsigned *src, int sw, int sh,
                                     double h11, double h12, double h13,
                                     double h21, double h22, double h23,
                                     double h31, double h32, double h33,
                                     double opacity);
extern void iosim_fb_free_offscreen(unsigned *buf);
extern void iosim_fb_blit_rgba_scaled(int x, int y, int w, int h,
                                      const unsigned char *rgba,
                                      int sw, int sh, int stride);
extern void iosim_fb_blit_rgba(int x, int y, int w, int h,
                               const unsigned char *rgba, int stride);
extern void iosim_fb_capture(int x, int y, int w, int h, unsigned *out);
extern void iosim_fb_fill_linear_gradient_round_rect(int x, int y, int w,
                                                     int h, int radius,
                                                     unsigned start_color,
                                                     unsigned end_color,
                                                     double sx, double sy,
                                                     double ex, double ey);

@class UIView;
@class UIWindowScene;

@class UIColor;
@class CAAnimation;

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
    id calcMode;
    id timingFunctions;
    CGPathRef path;
    id timingFunction;
    id key;
    id animation;
    double start;
    double duration;
    double repeatCount;
    double delay;
    double speed;
    double timeOffset;
    int autoreverses;
    id fillMode;
    double seq;
    int spring;
    double mass;
    double stiffness;
    double damping;
    double initialVelocity;
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
    CGPoint _anchorPoint;
    id _contents;
    CGRect _contentsRect;
    id _contentsGravity;
    double _contentsScale;
    id _mask;
    CATransform3D _transform;
    id _shadowPath;
    BOOL _shouldRasterize;
    double _rasterizationScale;
    id _cornerCurve;
    unsigned long _maskedCorners;
    double _speed;
    double _timeOffset;
    double _beginTime;
    id _name;
}
- (double)cornerRadius;
- (void)setCornerRadius:(double)radius;
- (CGRect)frame;
- (void)setFrame:(CGRect)frame;
- (CGRect)bounds;
- (void)setBounds:(CGRect)bounds;
- (CGPoint)position;
- (void)setPosition:(CGPoint)position;
- (CGPoint)anchorPoint;
- (void)setAnchorPoint:(CGPoint)anchorPoint;
- (void)setContents:(id)contents;
- (id)contents;
- (void)setMask:(CALayer *)mask;
- (CALayer *)mask;
- (void)setTransform:(CATransform3D)transform;
- (CATransform3D)transform;
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
- (void)removeAllAnimations;
- (NSArray *)animationKeys;
- (CAAnimation *)animationForKey:(id)key;
- (CALayer *)presentationLayer;
- (CALayer *)modelLayer;
- (CGPoint)convertPoint:(CGPoint)point fromLayer:(CALayer *)layer;
- (CGPoint)convertPoint:(CGPoint)point toLayer:(CALayer *)layer;
- (CGRect)convertRect:(CGRect)rect fromLayer:(CALayer *)layer;
- (CGRect)convertRect:(CGRect)rect toLayer:(CALayer *)layer;
- (double)convertTime:(double)time fromLayer:(CALayer *)layer;
- (double)convertTime:(double)time toLayer:(CALayer *)layer;
- (CGRect)contentsRect;
- (void)setContentsRect:(CGRect)rect;
- (id)contentsGravity;
- (void)setContentsGravity:(id)gravity;
- (double)contentsScale;
- (void)setContentsScale:(double)scale;
- (id)shadowPath;
- (void)setShadowPath:(id)path;
- (BOOL)shouldRasterize;
- (void)setShouldRasterize:(BOOL)rasterize;
- (double)rasterizationScale;
- (void)setRasterizationScale:(double)scale;
- (id)cornerCurve;
- (void)setCornerCurve:(id)curve;
- (unsigned long)maskedCorners;
- (void)setMaskedCorners:(unsigned long)corners;
- (double)speed;
- (void)setSpeed:(double)speed;
- (double)timeOffset;
- (void)setTimeOffset:(double)offset;
- (double)beginTime;
- (void)setBeginTime:(double)time;
- (id)name;
- (void)setName:(id)name;
@end


@class UIBezierPath, UIImage;

@interface CAShapeLayer : CALayer {
@public
    id _path;
    id _fillColor;
    id _strokeColor;
    double _lineWidth;
    double _strokeStart;
    double _strokeEnd;
    int _lineCap;
    int _lineJoin;
    id _lineDashPattern;
    double _lineDashPhase;
    double _miterLimit;
    CGPathRef _cgPath;
    CGColorRef _cgFillColor;
    CGColorRef _cgStrokeColor;
}
- (void)setPath:(id)path;
- (id)path;
- (void)setFillColor:(id)color;
- (id)fillColor;
- (void)setStrokeColor:(id)color;
- (id)strokeColor;
- (void)setLineWidth:(double)width;
- (double)lineWidth;
- (void)setStrokeStart:(double)start;
- (double)strokeStart;
- (void)setStrokeEnd:(double)end;
- (double)strokeEnd;
- (void)setLineCap:(int)cap;
- (int)lineCap;
- (void)setLineJoin:(int)join;
- (int)lineJoin;
- (NSArray *)lineDashPattern;
- (void)setLineDashPattern:(NSArray *)pattern;
- (double)lineDashPhase;
- (void)setLineDashPhase:(double)phase;
- (double)miterLimit;
- (void)setMiterLimit:(double)limit;
@end

@interface CAGradientLayer : CALayer {
@public
    NSArray *_colors;
    NSArray *_locations;
    CGPoint _startPoint;
    CGPoint _endPoint;
    id _type;
}
- (void)setColors:(NSArray *)colors;
- (NSArray *)colors;
- (void)setLocations:(NSArray *)locations;
- (NSArray *)locations;
- (void)setStartPoint:(CGPoint)point;
- (CGPoint)startPoint;
- (void)setEndPoint:(CGPoint)point;
- (CGPoint)endPoint;
- (void)setType:(id)type;
- (id)type;
@end

@interface CATextLayer : CALayer {
@public
    id _string;
    id _font;
    double _fontSize;
    id _foregroundColor;
    long _alignmentMode;
    BOOL _wrapped;
}
- (id)string;
- (void)setString:(id)string;
- (id)font;
- (void)setFont:(id)font;
- (double)fontSize;
- (void)setFontSize:(double)size;
- (id)foregroundColor;
- (void)setForegroundColor:(id)color;
- (long)alignmentMode;
- (void)setAlignmentMode:(long)mode;
- (BOOL)isWrapped;
- (void)setWrapped:(BOOL)wrapped;
@end

@interface UIBezierPath : NSObject {
@public
    double _xs[512];
    double _ys[512];
    int _count;
    int _shape;
    CGRect _rect;
    double _cornerRadius;
    int _closed;
}
+ (id)bezierPath;
+ (id)bezierPathWithRect:(CGRect)rect;
+ (id)bezierPathWithRoundedRect:(CGRect)rect cornerRadius:(double)radius;
+ (id)bezierPathWithOvalInRect:(CGRect)rect;
- (void)moveToPoint:(CGPoint)point;
- (void)addLineToPoint:(CGPoint)point;
- (void)addQuadCurveToPoint:(CGPoint)point controlPoint:(CGPoint)control;
- (void)addCurveToPoint:(CGPoint)point controlPoint1:(CGPoint)control1
           controlPoint2:(CGPoint)control2;
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
    CGImageRef _cgImage;
}
+ (id)imageNamed:(id)name;
+ (id)imageWithContentsOfFile:(id)path;
+ (id)imageWithData:(id)data;
+ (id)imageWithCGImage:(CGImageRef)image;
- (int)width;
- (int)height;
- (CGImageRef)CGImage;
@end

@interface CAMediaTimingFunction : NSObject {
@public
    int _kind;
    int _custom;
    double _cx1, _cy1, _cx2, _cy2;
}
+ (id)functionWithName:(id)name;
+ (id)functionWithControlPoints:(float)c1x :(float)c1y :(float)c2x
                                :(float)c2y;
- (void)getControlPointAtIndex:(unsigned long)index values:(float *)values;
- (double)evaluate:(double)t;
@end

extern id kCAMediaTimingFunctionLinear;
extern id kCAMediaTimingFunctionEaseIn;
extern id kCAMediaTimingFunctionEaseOut;
extern id kCAMediaTimingFunctionEaseInEaseOut;

@class CAAnimation;
@protocol CAAnimationDelegate
@optional
- (void)animationDidStart:(CAAnimation *)anim;
- (void)animationDidStop:(CAAnimation *)anim finished:(BOOL)finished;
@end

@interface CAAnimation : NSObject {
@public
    id _delegate;
    id _keyPath;
    id _fromValue;
    id _toValue;
    double _duration;
    double _repeatCount;
    id _timingFunction;
    double _beginTime;
    double _speed;
    double _timeOffset;
    BOOL _autoreverses;
    BOOL _removedOnCompletion;
    id _fillMode;
}
+ (id)animationWithKeyPath:(id)path;
- (void)setFromValue:(id)value;
- (void)setToValue:(id)value;
- (void)setDuration:(double)duration;
- (double)duration;
- (void)setRepeatCount:(double)count;
- (double)repeatCount;
- (void)setTimingFunction:(id)function;
- (id)timingFunction;
- (id)fromValue;
- (id)toValue;
- (void)setBeginTime:(double)time;
- (double)beginTime;
- (void)setSpeed:(double)speed;
- (double)speed;
- (void)setTimeOffset:(double)offset;
- (double)timeOffset;
- (void)setAutoreverses:(BOOL)autoreverses;
- (BOOL)autoreverses;
- (void)setRemovedOnCompletion:(BOOL)removed;
- (BOOL)removedOnCompletion;
- (void)setFillMode:(id)fillMode;
- (id)fillMode;
- (void)setDelegate:(id)delegate;
- (id)delegate;
@end

@interface CABasicAnimation : CAAnimation
@end

@interface CAKeyframeAnimation : CAAnimation {
@public
    id _values;
    id _keyTimes;
    id _calculationMode;
    id _timingFunctions;
    CGPathRef _path;
}
- (void)setValues:(id)values;
- (void)setKeyTimes:(id)keyTimes;
- (void)setCalculationMode:(id)mode;
- (id)calculationMode;
- (void)setTimingFunctions:(id)functions;
- (id)timingFunctions;
- (void)setPath:(CGPathRef)path;
- (CGPathRef)path;
@end

@interface CASpringAnimation : CAAnimation {
@public
    double _mass;
    double _stiffness;
    double _damping;
    double _initialVelocity;
    double _settlingDuration;
}
- (void)setMass:(double)mass;
- (void)setStiffness:(double)stiffness;
- (void)setDamping:(double)damping;
- (void)setInitialVelocity:(double)velocity;
- (double)settlingDuration;
@end

/* A group expands into one layer-animation slot per child when it is added,
 * sharing the group's duration/timing when a child leaves them unset. */
@interface CAAnimationGroup : CAAnimation {
@public
    NSArray *_animations;
}
- (void)setAnimations:(NSArray *)animations;
- (NSArray *)animations;
@end

@interface CATransition : CAAnimation {
@public
    id _type;
    id _subtype;
    float _startProgress;
    float _endProgress;
    id _filter;
}
- (id)type;
- (void)setType:(id)type;
- (id)subtype;
- (void)setSubtype:(id)subtype;
- (float)startProgress;
- (void)setStartProgress:(float)progress;
- (float)endProgress;
- (void)setEndProgress:(float)progress;
- (id)filter;
- (void)setFilter:(id)filter;
@end

@interface CATransformLayer : CALayer
@end

@interface CATransaction : NSObject
+ (void)begin;
+ (void)commit;
+ (void)flush;
+ (void)setAnimationDuration:(double)duration;
+ (double)animationDuration;
+ (void)setDisableActions:(BOOL)disable;
+ (BOOL)disableActions;
+ (void)setCompletionBlock:(void (^)(void))block;
+ (void (^)(void))completionBlock;
+ (void)lock;
+ (void)unlock;
@end

/* Replicates its sublayers instanceCount times, applying instanceTransform
 * cumulatively. instanceColor tints the copies and the channel offsets shift
 * each successive copy; instanceDelay is accepted but copies render in the
 * same animation phase. */
@interface CAReplicatorLayer : CALayer {
@public
    long _instanceCount;
    double _instanceDelay;
    CATransform3D _instanceTransform;
    id _instanceColor;
    float _instanceRedOffset;
    float _instanceGreenOffset;
    float _instanceBlueOffset;
    float _instanceAlphaOffset;
    BOOL _preservesDepth;
}
- (long)instanceCount;
- (void)setInstanceCount:(long)count;
- (double)instanceDelay;
- (void)setInstanceDelay:(double)delay;
- (CATransform3D)instanceTransform;
- (void)setInstanceTransform:(CATransform3D)transform;
- (id)instanceColor;
- (void)setInstanceColor:(id)color;
- (float)instanceRedOffset;
- (void)setInstanceRedOffset:(float)offset;
- (float)instanceGreenOffset;
- (void)setInstanceGreenOffset:(float)offset;
- (float)instanceBlueOffset;
- (void)setInstanceBlueOffset:(float)offset;
- (float)instanceAlphaOffset;
- (void)setInstanceAlphaOffset:(float)offset;
- (BOOL)preservesDepth;
- (void)setPreservesDepth:(BOOL)value;
@end

@interface CAEmitterCell : NSObject {
@public
    id _contents;
    id _color;
    float _birthRate;
    float _lifetime;
    float _velocity;
    float _velocityRange;
    float _emissionRange;
    float _scale;
    float _scaleRange;
    float _spin;
    float _spinRange;
    float _alphaSpeed;
    float _alphaRange;
    float _redSpeed, _greenSpeed, _blueSpeed;
    float _redRange, _greenRange, _blueRange;
    float _xAcceleration, _yAcceleration;
    BOOL _enabled;
    id _name;
}
- (void)setContents:(id)contents;
- (id)contents;
- (void)setColor:(id)color;
- (id)color;
- (void)setBirthRate:(float)rate;
- (float)birthRate;
- (void)setLifetime:(float)lifetime;
- (float)lifetime;
- (void)setVelocity:(float)velocity;
- (float)velocity;
- (void)setVelocityRange:(float)range;
- (float)velocityRange;
- (void)setEmissionRange:(float)range;
- (float)emissionRange;
- (void)setScale:(float)scale;
- (float)scale;
- (void)setScaleRange:(float)range;
- (float)scaleRange;
- (void)setSpin:(float)spin;
- (float)spin;
- (void)setSpinRange:(float)range;
- (float)spinRange;
- (void)setAlphaSpeed:(float)speed;
- (float)alphaSpeed;
- (void)setAlphaRange:(float)range;
- (float)alphaRange;
- (void)setRedSpeed:(float)speed;
- (float)redSpeed;
- (void)setGreenSpeed:(float)speed;
- (float)greenSpeed;
- (void)setBlueSpeed:(float)speed;
- (float)blueSpeed;
- (void)setRedRange:(float)range;
- (float)redRange;
- (void)setGreenRange:(float)range;
- (float)greenRange;
- (void)setBlueRange:(float)range;
- (float)blueRange;
- (void)setXAcceleration:(float)acceleration;
- (float)xAcceleration;
- (void)setYAcceleration:(float)acceleration;
- (float)yAcceleration;
- (void)setEnabled:(BOOL)enabled;
- (BOOL)isEnabled;
- (void)setName:(id)name;
- (id)name;
@end

@interface CAEmitterLayer : CALayer {
@public
    NSArray *_emitterCells;
    float _birthRate;
    float _lifetime;
    CGPoint _emitterPosition;
    CGSize _emitterSize;
    id _emitterShape;
    id _renderMode;
    unsigned _seed;
    float _scale;
    float _velocity;
    float _spin;
}
- (void)setEmitterCells:(NSArray *)cells;
- (NSArray *)emitterCells;
- (void)setBirthRate:(float)rate;
- (float)birthRate;
- (void)setLifetime:(float)lifetime;
- (float)lifetime;
- (void)setEmitterPosition:(CGPoint)position;
- (CGPoint)emitterPosition;
- (void)setEmitterSize:(CGSize)size;
- (CGSize)emitterSize;
- (void)setEmitterShape:(id)shape;
- (id)emitterShape;
- (void)setRenderMode:(id)mode;
- (id)renderMode;
- (void)setSeed:(unsigned)seed;
- (unsigned)seed;
- (void)setScale:(float)scale;
- (float)scale;
- (void)setVelocity:(float)velocity;
- (float)velocity;
- (void)setSpin:(float)spin;
- (float)spin;
@end

@interface CADisplayLink : NSObject {
@public
    id _target;
    SEL _selector;
    double _timestamp;
    double _duration;
    double _targetTimestamp;
    long _frameInterval;
    long _preferredFramesPerSecond;
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
- (long)preferredFramesPerSecond;
- (void)setPreferredFramesPerSecond:(long)rate;
- (BOOL)isValid;
- (long)frameInterval;
- (void)setFrameInterval:(long)interval;
@end

enum {
    UIUserInterfaceStyleUnspecified = 0,
    UIUserInterfaceStyleLight = 1,
    UIUserInterfaceStyleDark = 2
};

enum {
    UIUserInterfaceSizeClassUnspecified = 0,
    UIUserInterfaceSizeClassCompact = 1,
    UIUserInterfaceSizeClassRegular = 2
};

@class UITraitCollection;

@interface UITraitCollection : NSObject {
@public
    long _userInterfaceStyle;
    double _displayScale;
    long _horizontalSizeClass;
    long _verticalSizeClass;
}
+ (UITraitCollection *)traitCollectionWithUserInterfaceStyle:(long)style;
- (long)userInterfaceStyle;
- (double)displayScale;
- (long)horizontalSizeClass;
- (long)verticalSizeClass;
- (BOOL)containsTraitsInCollection:(UITraitCollection *)other;
@end

@interface UIColor : NSObject {
@public
    double _r, _g, _b, _a;
    double _dark_r, _dark_g, _dark_b, _dark_a;
    BOOL _dynamic;
    BOOL _displayP3;
    void *_provider;
}
+ (UIColor *)colorWithRed:(double)r green:(double)g blue:(double)b
                    alpha:(double)a;
+ (UIColor *)colorWithWhite:(double)white alpha:(double)alpha;
+ (UIColor *)colorWithHue:(double)hue saturation:(double)saturation
               brightness:(double)brightness alpha:(double)alpha;
+ (UIColor *)colorWithDisplayP3Red:(double)r green:(double)g blue:(double)b
                             alpha:(double)a;
- (UIColor *)colorWithAlphaComponent:(double)alpha;
- (BOOL)getRed:(double *)red green:(double *)green blue:(double *)blue
         alpha:(double *)alpha;
- (BOOL)getWhite:(double *)white alpha:(double *)alpha;
- (BOOL)getHue:(double *)hue saturation:(double *)saturation
    brightness:(double *)brightness alpha:(double *)alpha;
+ (UIColor *)colorWithDynamicProvider:(id (^)(UITraitCollection *traits))provider;
+ (UIColor *)whiteColor;
+ (UIColor *)blackColor;
+ (UIColor *)clearColor;
+ (UIColor *)redColor;
+ (UIColor *)greenColor;
+ (UIColor *)blueColor;
+ (UIColor *)orangeColor;
+ (UIColor *)yellowColor;
+ (UIColor *)purpleColor;
+ (UIColor *)brownColor;
+ (UIColor *)cyanColor;
+ (UIColor *)magentaColor;
+ (UIColor *)grayColor;
+ (UIColor *)darkGrayColor;
+ (UIColor *)lightGrayColor;
+ (UIColor *)systemBlueColor;
+ (UIColor *)tintColor;
+ (UIColor *)systemRedColor;
+ (UIColor *)systemGreenColor;
+ (UIColor *)systemOrangeColor;
+ (UIColor *)systemYellowColor;
+ (UIColor *)systemPurpleColor;
+ (UIColor *)systemPinkColor;
+ (UIColor *)systemTealColor;
+ (UIColor *)systemIndigoColor;
+ (UIColor *)systemBrownColor;
+ (UIColor *)systemGrayColor;
+ (UIColor *)systemGray2Color;
+ (UIColor *)systemGray3Color;
+ (UIColor *)systemGray4Color;
+ (UIColor *)systemGray5Color;
+ (UIColor *)systemGray6Color;
+ (UIColor *)systemBackgroundColor;
+ (UIColor *)secondarySystemBackgroundColor;
+ (UIColor *)tertiarySystemBackgroundColor;
+ (UIColor *)systemGroupedBackgroundColor;
+ (UIColor *)secondarySystemGroupedBackgroundColor;
+ (UIColor *)labelColor;
+ (UIColor *)secondaryLabelColor;
+ (UIColor *)tertiaryLabelColor;
+ (UIColor *)quaternaryLabelColor;
+ (UIColor *)separatorColor;
+ (UIColor *)opaqueSeparatorColor;
+ (UIColor *)linkColor;
+ (UIColor *)ui_colorWithLightRed:(double)lr lightGreen:(double)lg
                        lightBlue:(double)lb lightAlpha:(double)la
                          darkRed:(double)dr darkGreen:(double)dg
                         darkBlue:(double)db darkAlpha:(double)da;
- (void)ui_components:(double *)components;
- (UIColor *)resolvedColorWithTraitCollection:(UITraitCollection *)traits;
- (CGColorRef)CGColor;
@end

#define UIFontWeightUltraLight (-0.8)
#define UIFontWeightThin (-0.6)
#define UIFontWeightLight (-0.4)
#define UIFontWeightRegular (0.0)
#define UIFontWeightMedium (0.23)
#define UIFontWeightSemibold (0.3)
#define UIFontWeightBold (0.4)
#define UIFontWeightHeavy (0.56)
#define UIFontWeightBlack (0.62)

@class UIFontDescriptor;

@interface UIFont : NSObject {
@public
    double _size;
    BOOL _bold;
    id _name;
}
+ (UIFont *)systemFontOfSize:(double)size;
+ (UIFont *)systemFontOfSize:(double)size weight:(double)weight;
+ (UIFont *)boldSystemFontOfSize:(double)size;
+ (UIFont *)italicSystemFontOfSize:(double)size;
+ (UIFont *)monospacedSystemFontOfSize:(double)size weight:(double)weight;
+ (UIFont *)fontWithName:(id)name size:(double)size;
+ (UIFont *)fontWithDescriptor:(UIFontDescriptor *)descriptor
                          size:(double)size;
+ (UIFont *)preferredFontForTextStyle:(id)style;
+ (UIFont *)preferredFontForTextStyle:(id)style
              compatibleWithTraitCollection:(UITraitCollection *)traits;
- (double)pointSize;
- (id)fontName;
- (id)familyName;
- (UIFont *)fontWithSize:(double)size;
- (UIFontDescriptor *)fontDescriptor;
@end

@interface UIFontDescriptor : NSObject {
@public
    double _size;
    id _name;
}
+ (UIFontDescriptor *)preferredFontDescriptorWithTextStyle:(id)style;
- (UIFontDescriptor *)fontDescriptorWithSize:(double)size;
- (UIFontDescriptor *)fontDescriptorWithSymbolicTraits:(unsigned long)traits;
- (double)pointSize;
- (id)fontAttributes;
@end

@interface UIScreen : NSObject {
@public
    double _brightness;
}
+ (UIScreen *)mainScreen;
- (CGRect)bounds;
- (CGRect)nativeBounds;
- (double)scale;
- (double)nativeScale;
- (double)brightness;
- (void)setBrightness:(double)brightness;
- (BOOL)isCaptured;
@end

extern NSString *UIDeviceOrientationDidChangeNotification;

@interface UIDevice : NSObject {
@public
    long _orientation;
    long _batteryState;
    double _batteryLevel;
    BOOL _proximityMonitoringEnabled;
    BOOL _generatingOrientationNotifications;
}
+ (UIDevice *)currentDevice;
- (id)name;
- (id)model;
- (id)localizedModel;
- (id)systemName;
- (id)systemVersion;
- (id)identifierForVendor;
- (long)userInterfaceIdiom;
- (long)orientation;
- (void)setOrientation:(long)orientation;
- (long)batteryState;
- (double)batteryLevel;
- (BOOL)isProximityMonitoringEnabled;
- (void)setProximityMonitoringEnabled:(BOOL)enabled;
- (BOOL)isMultitaskingSupported;
- (BOOL)isGeneratingDeviceOrientationNotifications;
- (void)beginGeneratingDeviceOrientationNotifications;
- (void)endGeneratingDeviceOrientationNotifications;
- (void)playInputClick;
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
    NSMutableArray *_touches;
    NSSet *_changedTouches;
}
- (id)initWithTouch:(UITouch *)touch;
- (id)initWithTouches:(NSArray *)touches changed:(NSSet *)changed;
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
    id _identifier;
}
- (id)owningView;
- (id)identifier;
- (void)setIdentifier:(id)identifier;
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
    BOOL _delaysTouchesBegan;
    BOOL _delaysTouchesEnded;
    BOOL _cancelsTouchesInView;
    unsigned long _numberOfTouches;
    id _delegate;
    id _allowedTouchTypes;
}
- (id)initWithTarget:(id)target action:(SEL)action;
- (void)addTarget:(id)target action:(SEL)action;
- (long)state;
- (id)view;
- (CGPoint)locationInView:(UIView *)view;
- (void)setEnabled:(BOOL)enabled;
- (BOOL)isEnabled;
- (id)delegate;
- (void)setDelegate:(id)delegate;
- (void)requireGestureRecognizerToFail:(UIGestureRecognizer *)other;
- (unsigned long)numberOfTouches;
- (BOOL)delaysTouchesBegan;
- (void)setDelaysTouchesBegan:(BOOL)delays;
- (BOOL)delaysTouchesEnded;
- (void)setDelaysTouchesEnded:(BOOL)delays;
- (BOOL)cancelsTouchesInView;
- (void)setCancelsTouchesInView:(BOOL)cancels;
- (NSArray *)allowedTouchTypes;
- (void)setAllowedTouchTypes:(NSArray *)types;
@end

@interface UITapGestureRecognizer : UIGestureRecognizer {
@public
    int _numberOfTapsRequired;
    int _numberOfTouchesRequired;
}
- (void)setNumberOfTapsRequired:(int)count;
- (int)numberOfTapsRequired;
- (void)setNumberOfTouchesRequired:(int)count;
- (int)numberOfTouchesRequired;
@end

@interface UIPanGestureRecognizer : UIGestureRecognizer {
@public
    CGPoint _panVelocity;
    unsigned long _minimumNumberOfTouches;
    unsigned long _maximumNumberOfTouches;
}
- (CGPoint)translationInView:(UIView *)view;
- (CGPoint)velocityInView:(UIView *)view;
- (void)setTranslation:(CGPoint)translation inView:(UIView *)view;
- (unsigned long)minimumNumberOfTouches;
- (void)setMinimumNumberOfTouches:(unsigned long)count;
- (unsigned long)maximumNumberOfTouches;
- (void)setMaximumNumberOfTouches:(unsigned long)count;
@end

typedef enum {
    UIRectEdgeNone = 0,
    UIRectEdgeTop = 1 << 0,
    UIRectEdgeLeft = 1 << 1,
    UIRectEdgeBottom = 1 << 2,
    UIRectEdgeRight = 1 << 3,
    UIRectEdgeAll = UIRectEdgeTop | UIRectEdgeLeft |
                    UIRectEdgeBottom | UIRectEdgeRight
} UIRectEdge;

@interface UIScreenEdgePanGestureRecognizer : UIPanGestureRecognizer {
@public
    UIRectEdge _edges;
}
- (UIRectEdge)edges;
- (void)setEdges:(UIRectEdge)edges;
@end

@interface UIPinchGestureRecognizer : UIGestureRecognizer {
@public
    double _scale;
    double _velocity;
}
- (double)scale;
- (void)setScale:(double)scale;
- (double)velocity;
@end

@interface UIRotationGestureRecognizer : UIGestureRecognizer {
@public
    double _rotation;
    double _velocity;
}
- (double)rotation;
- (void)setRotation:(double)rotation;
- (double)velocity;
@end

@interface UISwipeGestureRecognizer : UIGestureRecognizer {
@public
    long _direction;
    int _numberOfTouchesRequired;
}
- (void)setDirection:(long)direction;
- (long)direction;
- (void)setNumberOfTouchesRequired:(int)count;
- (int)numberOfTouchesRequired;
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

typedef enum {
    UIViewContentModeScaleToFill = 0,
    UIViewContentModeScaleAspectFit = 1,
    UIViewContentModeScaleAspectFill = 2,
    UIViewContentModeRedraw = 3,
    UIViewContentModeCenter = 4,
    UIViewContentModeTop = 5,
    UIViewContentModeBottom = 6,
    UIViewContentModeLeft = 7,
    UIViewContentModeRight = 8,
    UIViewContentModeTopLeft = 9,
    UIViewContentModeTopRight = 10,
    UIViewContentModeBottomLeft = 11,
    UIViewContentModeBottomRight = 12
} UIViewContentMode;

typedef enum {
    UIViewAutoresizingNone = 0,
    UIViewAutoresizingFlexibleLeftMargin = 1 << 0,
    UIViewAutoresizingFlexibleWidth = 1 << 1,
    UIViewAutoresizingFlexibleRightMargin = 1 << 2,
    UIViewAutoresizingFlexibleTopMargin = 1 << 3,
    UIViewAutoresizingFlexibleHeight = 1 << 4,
    UIViewAutoresizingFlexibleBottomMargin = 1 << 5
} UIViewAutoresizing;

@interface UIView : UIResponder {
@public
    CGRect _frame;
    UIColor *_backgroundColor;
    UIColor *_tintColor;
    long _tintAdjustmentMode;
    long _overrideUserInterfaceStyle;
    id _subviews[32];
    int _subviewCount;
    BOOL _hidden;
    BOOL _userInteractionEnabled;
    BOOL _opaque;
    long _contentMode;
    BOOL _clearsContextBeforeDrawing;
    BOOL _exclusiveTouch;
    BOOL _multipleTouchEnabled;
    BOOL _autoresizesSubviews;
    unsigned long _autoresizingMask;
    double _alpha;
    CALayer *_layer;
    BOOL _animatingAlpha;
    double _animAlphaFrom, _animAlphaTo;
    BOOL _animatingFrame;
    CGRect _animFrameFrom, _animFrameTo;
    BOOL _animatingTransform;
    CGAffineTransform _animTransformFrom, _animTransformTo;
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
    UIEdgeInsets _layoutMargins;
    UIEdgeInsets _additionalSafeAreaInsets;
    UILayoutGuide *_layoutMarginsGuide;
    UILayoutGuide *_readableGuide;
    BOOL _preservesSuperviewLayoutMargins;
    BOOL _needsConstraintsUpdate;
    id _gestureRecognizers[8];
    int _gestureRecognizerCount;
    BOOL _clipsToBounds;
    UIView *_maskView;
    id _interactions[8];
    int _interactionCount;
    BOOL _isAccessibilityElement;
    id _accessibilityLabel;
    id _accessibilityIdentifier;
    id _accessibilityHint;
    id _accessibilityValue;
    unsigned long long _accessibilityTraits;
    BOOL _accessibilityElementsHidden;
    BOOL _accessibilityViewIsModal;
    BOOL _shouldGroupAccessibilityChildren;
    id _accessibilityElements;
    CGRect _accessibilityFrame;
    long _semanticContentAttribute;
    double _contentScaleFactor;
}
- (id)initWithFrame:(CGRect)frame;
- (CGRect)frame;
- (void)setFrame:(CGRect)frame;
- (CGRect)bounds;
- (void)setBounds:(CGRect)bounds;
- (CGPoint)center;
- (void)setCenter:(CGPoint)center;
- (CGPoint)convertPoint:(CGPoint)point toView:(UIView *)view;
- (CGPoint)convertPoint:(CGPoint)point fromView:(UIView *)view;
- (CGRect)convertRect:(CGRect)rect toView:(UIView *)view;
- (CGRect)convertRect:(CGRect)rect fromView:(UIView *)view;
- (void)setBackgroundColor:(UIColor *)color;
- (UIColor *)backgroundColor;
- (UIColor *)tintColor;
- (void)setTintColor:(UIColor *)color;
- (void)tintColorDidChange;
- (long)tintAdjustmentMode;
- (void)setTintAdjustmentMode:(long)mode;
- (UITraitCollection *)traitCollection;
- (long)overrideUserInterfaceStyle;
- (void)setOverrideUserInterfaceStyle:(long)style;
- (void)traitCollectionDidChange:(UITraitCollection *)previous;
- (void)addSubview:(UIView *)view;
- (void)didAddSubview:(UIView *)subview;
- (void)willRemoveSubview:(UIView *)subview;
- (void)willMoveToSuperview:(UIView *)newSuperview;
- (void)didMoveToSuperview;
- (void)willMoveToWindow:(id)window;
- (void)didMoveToWindow;
- (NSArray *)subviews;
- (void)insertSubview:(UIView *)view atIndex:(long)index;
- (void)bringSubviewToFront:(UIView *)view;
- (void)sendSubviewToBack:(UIView *)view;
- (void)removeFromSuperview;
- (void)addInteraction:(id)interaction;
- (void)removeInteraction:(id)interaction;
- (NSArray *)interactions;
- (BOOL)isAccessibilityElement;
- (void)setIsAccessibilityElement:(BOOL)element;
- (id)accessibilityLabel;
- (void)setAccessibilityLabel:(id)label;
- (id)accessibilityIdentifier;
- (void)setAccessibilityIdentifier:(id)identifier;
- (id)accessibilityHint;
- (void)setAccessibilityHint:(id)hint;
- (id)accessibilityValue;
- (void)setAccessibilityValue:(id)value;
- (unsigned long long)accessibilityTraits;
- (void)setAccessibilityTraits:(unsigned long long)traits;
- (BOOL)accessibilityElementsHidden;
- (void)setAccessibilityElementsHidden:(BOOL)hidden;
- (BOOL)accessibilityViewIsModal;
- (void)setAccessibilityViewIsModal:(BOOL)modal;
- (BOOL)shouldGroupAccessibilityChildren;
- (void)setShouldGroupAccessibilityChildren:(BOOL)group;
- (NSArray *)accessibilityElements;
- (void)setAccessibilityElements:(NSArray *)elements;
- (CGRect)accessibilityFrame;
- (void)setAccessibilityFrame:(CGRect)frame;
+ (Class)layerClass;
- (CALayer *)layer;
- (void)setHidden:(BOOL)hidden;
- (BOOL)isHidden;
- (BOOL)isUserInteractionEnabled;
- (void)setUserInteractionEnabled:(BOOL)enabled;
- (BOOL)isOpaque;
- (void)setOpaque:(BOOL)opaque;
- (long)contentMode;
- (void)setContentMode:(long)mode;
- (long)semanticContentAttribute;
- (void)setSemanticContentAttribute:(long)attribute;
+ (long)userInterfaceLayoutDirectionForSemanticContentAttribute:(long)attribute;
- (long)effectiveUserInterfaceLayoutDirection;
- (BOOL)clearsContextBeforeDrawing;
- (void)setClearsContextBeforeDrawing:(BOOL)clears;
- (BOOL)isExclusiveTouch;
- (void)setExclusiveTouch:(BOOL)exclusive;
- (BOOL)isMultipleTouchEnabled;
- (void)setMultipleTouchEnabled:(BOOL)enabled;
- (BOOL)autoresizesSubviews;
- (void)setAutoresizesSubviews:(BOOL)resizes;
- (unsigned long)autoresizingMask;
- (void)setAutoresizingMask:(unsigned long)mask;
- (double)contentScaleFactor;
- (void)setContentScaleFactor:(double)scale;
- (void)setAlpha:(double)alpha;
- (double)alpha;
- (BOOL)pointInside:(CGPoint)point;
- (UIView *)hitTest:(CGPoint)point;
- (UIView *)snapshotViewAfterScreenUpdates:(BOOL)afterUpdates;
- (BOOL)drawViewHierarchyInRect:(CGRect)rect
             afterScreenUpdates:(BOOL)afterUpdates;
- (id)superview;
- (UIWindow *)window;
- (CGAffineTransform)transform;
- (void)setTransform:(CGAffineTransform)transform;
- (void)layoutSubviews;
- (void)setNeedsLayout;
- (void)setNeedsDisplay;
- (void)setNeedsDisplayInRect:(CGRect)rect;
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
- (UIEdgeInsets)safeAreaInsets;
- (void)safeAreaInsetsDidChange;
- (UIEdgeInsets)layoutMargins;
- (void)setLayoutMargins:(UIEdgeInsets)margins;
- (UILayoutGuide *)layoutMarginsGuide;
- (UILayoutGuide *)readableContentGuide;
- (BOOL)preservesSuperviewLayoutMargins;
- (void)setPreservesSuperviewLayoutMargins:(BOOL)preserves;
- (void)setClipsToBounds:(BOOL)clips;
- (BOOL)clipsToBounds;
- (UIView *)maskView;
- (void)setMaskView:(UIView *)view;
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
+ (BOOL)areAnimationsEnabled;
+ (void)setAnimationsEnabled:(BOOL)enabled;
+ (void)performWithoutAnimation:(void (^)(void))actionsWithoutAnimation;
+ (void)animateKeyframesWithDuration:(double)duration delay:(double)delay
                             options:(unsigned long)options
                          animations:(void (^)(void))animations
                          completion:(void (^)(BOOL finished))completion;
+ (void)addKeyframeWithRelativeStartTime:(double)start
                        relativeDuration:(double)duration
                              animations:(void (^)(void))animations;
+ (void)transitionWithView:(UIView *)view duration:(double)duration
                   options:(unsigned long)options
                animations:(void (^)(void))animations
                completion:(void (^)(BOOL finished))completion;
+ (void)transitionFromView:(UIView *)fromView toView:(UIView *)toView
                  duration:(double)duration
                   options:(unsigned long)options
                completion:(void (^)(BOOL finished))completion;
@end

typedef enum {
    UIViewAnimatingStateInactive = 0,
    UIViewAnimatingStateActive = 1,
    UIViewAnimatingStateStopped = 2
} UIViewAnimatingState;

typedef enum {
    UIViewAnimatingPositionEnd = 0,
    UIViewAnimatingPositionStart = 1,
    UIViewAnimatingPositionCurrent = 2
} UIViewAnimatingPosition;

typedef enum {
    UIViewAnimationCurveEaseInOut = 0,
    UIViewAnimationCurveEaseIn = 1,
    UIViewAnimationCurveEaseOut = 2,
    UIViewAnimationCurveLinear = 3
} UIViewAnimationCurve;

@interface UIViewPropertyAnimator : NSObject {
@public
    double _duration;
    double _fractionComplete;
    BOOL _reversed;
    BOOL _interruptible;
    BOOL _userInteractionEnabled;
    BOOL _scrubsLinearly;
    BOOL _pausesOnCompletion;
    BOOL _completed;
    long _state;
    id _animations;
    id _completions;
}
- (id)initWithDuration:(double)duration
                 curve:(long)curve
            animations:(void (^)(void))animations;
- (id)initWithDuration:(double)duration
          dampingRatio:(double)ratio
            animations:(void (^)(void))animations;
- (id)initWithDuration:(double)duration
         controlPoint1:(CGPoint)point1
         controlPoint2:(CGPoint)point2
            animations:(void (^)(void))animations;
- (double)duration;
- (double)fractionComplete;
- (void)setFractionComplete:(double)fraction;
- (BOOL)isReversed;
- (void)setReversed:(BOOL)reversed;
- (long)state;
- (BOOL)isRunning;
- (BOOL)isInterruptible;
- (void)setInterruptible:(BOOL)interruptible;
- (BOOL)isUserInteractionEnabled;
- (void)setUserInteractionEnabled:(BOOL)enabled;
- (BOOL)scrubsLinearly;
- (void)setScrubsLinearly:(BOOL)linear;
- (BOOL)pausesOnCompletion;
- (void)setPausesOnCompletion:(BOOL)pauses;
- (void)addAnimations:(void (^)(void))animations;
- (void)addAnimations:(void (^)(void))animations delayFactor:(double)factor;
- (void)addCompletion:(void (^)(long position))completion;
- (void)startAnimation;
- (void)startAnimationAfterDelay:(double)delay;
- (void)pauseAnimation;
- (void)stopAnimation:(BOOL)withoutFinishing;
- (void)finishAnimationAtPosition:(long)position;
- (void)continueAnimationWithTimingParameters:(id)parameters
                                durationFactor:(double)factor;
@end

@interface UIAccessibilityElement : NSObject {
@public
    id _accessibilityContainer;
    id _accessibilityLabel;
    id _accessibilityIdentifier;
    id _accessibilityHint;
    id _accessibilityValue;
    unsigned long long _accessibilityTraits;
    CGRect _accessibilityFrame;
    BOOL _isAccessibilityElement;
}
- (id)initWithAccessibilityContainer:(id)container;
- (id)accessibilityContainer;
- (BOOL)isAccessibilityElement;
- (void)setIsAccessibilityElement:(BOOL)element;
- (id)accessibilityLabel;
- (void)setAccessibilityLabel:(id)label;
- (id)accessibilityIdentifier;
- (void)setAccessibilityIdentifier:(id)identifier;
- (id)accessibilityHint;
- (void)setAccessibilityHint:(id)hint;
- (id)accessibilityValue;
- (void)setAccessibilityValue:(id)value;
- (unsigned long long)accessibilityTraits;
- (void)setAccessibilityTraits:(unsigned long long)traits;
- (CGRect)accessibilityFrame;
- (void)setAccessibilityFrame:(CGRect)frame;
@end

@interface UILabel : UIView {
@public
    id _text;
    id _attributedText;
    UIColor *_textColor;
    UIFont *_font;
    int _textAlignment;
    int _numberOfLines;
    long _lineBreakMode;
    double _preferredMaxLayoutWidth;
    BOOL _adjustsFontSizeToFitWidth;
    double _minimumScaleFactor;
}
- (void)setText:(id)text;
- (id)text;
- (void)setAttributedText:(id)text;
- (id)attributedText;
- (void)setTextColor:(UIColor *)color;
- (UIColor *)textColor;
- (void)setFont:(UIFont *)font;
- (UIFont *)font;
- (void)setTextAlignment:(int)alignment;
- (int)textAlignment;
- (void)setNumberOfLines:(int)n;
- (int)numberOfLines;
- (long)lineBreakMode;
- (void)setLineBreakMode:(long)mode;
- (double)preferredMaxLayoutWidth;
- (void)setPreferredMaxLayoutWidth:(double)width;
- (BOOL)adjustsFontSizeToFitWidth;
- (void)setAdjustsFontSizeToFitWidth:(BOOL)adjusts;
- (double)minimumScaleFactor;
- (void)setMinimumScaleFactor:(double)scale;
- (CGSize)intrinsicContentSize;
- (CGSize)sizeThatFits:(CGSize)size;
@end

@interface UITextView : UIView {
@public
    id _text;
    id _attributedText;
    UIColor *_textColor;
    UIFont *_font;
    BOOL _editable;
    NSRange _selectedRange;
    double _lastTapTime;
    unsigned long _lastTapIndex;
    unsigned long _dragAnchor;
    BOOL _dragging;
    int _dragHandle;
    CGPoint _pressPoint;
    double _pressStartTime;
    unsigned long _pressIndex;
    BOOL _pressPending;
}
- (id)text;
- (void)setText:(id)text;
- (void)setAttributedText:(id)text;
- (id)attributedText;
- (NSRange)selectedRange;
- (void)setSelectedRange:(NSRange)range;
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
- (void)copy:(id)sender;
- (void)paste:(id)sender;
@end

/* The text view holding a touch that may become a long-press selection;
 * the UI loop promotes it once the press duration elapses. */
static UITextView *g_pendingPressEditor;

@interface UIImageView : UIView {
@public
    UIImage *_image;
}
- (id)initWithImage:(UIImage *)image;
- (void)setImage:(UIImage *)image;
- (UIImage *)image;
- (void)setContentMode:(int)mode;
- (int)contentMode;
@end

@interface UIGraphicsImageRendererFormat : NSObject {
@public
    double _scale;
    BOOL _opaque;
}
+ (id)defaultFormat;
- (double)scale;
- (void)setScale:(double)scale;
- (BOOL)opaque;
- (void)setOpaque:(BOOL)opaque;
@end

@interface UIGraphicsImageRendererContext : NSObject {
@public
    CGContextRef _context;
}
- (CGContextRef)CGContext;
@end

@interface UIGraphicsImageRenderer : NSObject {
@public
    CGSize _size;
    UIGraphicsImageRendererFormat *_format;
}
- (id)initWithSize:(CGSize)size;
- (id)initWithSize:(CGSize)size
            format:(UIGraphicsImageRendererFormat *)format;
- (UIImage *)imageWithActions:(void (^)(UIGraphicsImageRendererContext *context))actions;
- (NSData *)PNGDataWithActions:(void (^)(UIGraphicsImageRendererContext *context))actions;
@end

enum {
    UIBlurEffectStyleExtraLight = 0,
    UIBlurEffectStyleLight = 1,
    UIBlurEffectStyleDark = 2,
    UIBlurEffectStyleSystemUltraThinMaterial = 3,
    UIBlurEffectStyleSystemThinMaterial = 4,
    UIBlurEffectStyleSystemMaterial = 5,
    UIBlurEffectStyleSystemThickMaterial = 6,
    UIBlurEffectStyleSystemChromeMaterial = 7
};

@interface UIBlurEffect : NSObject {
@public
    long _style;
}
+ (UIBlurEffect *)effectWithStyle:(long)style;
@end

/* A backdrop-blurring container: its render pass captures the pixels behind
 * it, box-blurs them with the effect's tint and draws its contentView on top. */
enum {
    UIImpactFeedbackStyleLight = 0,
    UIImpactFeedbackStyleMedium = 1,
    UIImpactFeedbackStyleHeavy = 2,
    UIImpactFeedbackStyleSoft = 3,
    UIImpactFeedbackStyleRigid = 4
};

enum {
    UINotificationFeedbackTypeSuccess = 0,
    UINotificationFeedbackTypeWarning = 1,
    UINotificationFeedbackTypeError = 2
};

@interface UIFeedbackGenerator : NSObject
- (void)prepare;
@end

@interface UIImpactFeedbackGenerator : UIFeedbackGenerator {
@public
    long _style;
}
- (id)initWithStyle:(long)style;
- (void)impactOccurred;
- (void)impactOccurredWithIntensity:(double)intensity;
@end

@interface UISelectionFeedbackGenerator : UIFeedbackGenerator
- (void)selectionChanged;
@end

@interface UINotificationFeedbackGenerator : UIFeedbackGenerator
- (void)notificationOccurred:(long)type;
@end

@interface UIVisualEffectView : UIView {
@public
    UIBlurEffect *_effect;
    UIView *_contentView;
}
- (id)initWithEffect:(UIBlurEffect *)effect;
- (UIBlurEffect *)effect;
- (UIView *)contentView;
@end

@interface UIPresentationController : NSObject {
@public
    id _presentedViewController;
    id _presentingViewController;
    UIView *_containerView;
    UIView *_presentedView;
    id _overrideTraitCollection;
}
- (id)presentedViewController;
- (id)presentingViewController;
- (UIView *)containerView;
- (UIView *)presentedView;
- (CGRect)frameOfPresentedViewInContainerView;
- (long)presentationStyle;
- (void)presentationTransitionWillBegin;
- (void)presentationTransitionDidEnd:(BOOL)completed;
- (void)dismissalTransitionWillBegin;
- (void)dismissalTransitionDidEnd:(BOOL)completed;
- (void)containerViewWillLayoutSubviews;
- (void)containerViewDidLayoutSubviews;
- (BOOL)shouldRemovePresentersView;
- (BOOL)shouldPresentInFullscreen;
@end

@interface UIPopoverPresentationController : UIPresentationController {
@public
    UIView *_sourceView;
    CGRect _sourceRect;
    id _barButtonItem;
    long _permittedArrowDirections;
    id _delegate;
    UIEdgeInsets _popoverLayoutMargins;
}
- (UIView *)sourceView;
- (void)setSourceView:(UIView *)view;
- (CGRect)sourceRect;
- (void)setSourceRect:(CGRect)rect;
- (id)barButtonItem;
- (void)setBarButtonItem:(id)item;
- (long)permittedArrowDirections;
- (void)setPermittedArrowDirections:(long)directions;
- (id)delegate;
- (void)setDelegate:(id)delegate;
- (UIEdgeInsets)popoverLayoutMargins;
- (void)setPopoverLayoutMargins:(UIEdgeInsets)insets;
@end

@interface UISheetPresentationControllerDetent : NSObject {
@public
    id _identifier;
}
+ (id)mediumDetent;
+ (id)largeDetent;
+ (id)customDetentWithIdentifier:(id)identifier
                        resolver:(double (^)(id))resolver;
- (id)identifier;
@end

@interface UISheetPresentationController : UIPresentationController {
@public
    NSArray *_detents;
    BOOL _prefersGrabberVisible;
    double _preferredCornerRadius;
    id _largestUndimmedDetentIdentifier;
    BOOL _prefersScrollingExpandsWhenScrolledToEdge;
}
- (NSArray *)detents;
- (void)setDetents:(NSArray *)detents;
- (BOOL)prefersGrabberVisible;
- (void)setPrefersGrabberVisible:(BOOL)visible;
- (double)preferredCornerRadius;
- (void)setPreferredCornerRadius:(double)radius;
- (id)largestUndimmedDetentIdentifier;
- (void)setLargestUndimmedDetentIdentifier:(id)identifier;
- (BOOL)prefersScrollingExpandsWhenScrolledToEdge;
- (void)setPrefersScrollingExpandsWhenScrolledToEdge:(BOOL)expands;
@end

@class UIViewController;

extern NSString *const UITransitionContextFromViewControllerKey;
extern NSString *const UITransitionContextToViewControllerKey;
extern NSString *const UITransitionContextFromViewKey;
extern NSString *const UITransitionContextToViewKey;

@protocol UIViewControllerContextTransitioning
- (UIView *)containerView;
- (UIViewController *)viewControllerForKey:(NSString *)key;
- (UIView *)viewForKey:(NSString *)key;
- (CGRect)initialFrameForViewController:(UIViewController *)controller;
- (CGRect)finalFrameForViewController:(UIViewController *)controller;
- (BOOL)isAnimated;
- (BOOL)isInteractive;
- (long)presentationStyle;
- (BOOL)transitionWasCancelled;
- (void)completeTransition:(BOOL)didComplete;
- (void)updateInteractiveTransition:(double)percentComplete;
- (void)finishInteractiveTransition;
- (void)cancelInteractiveTransition;
- (void)pauseInteractiveTransition;
@end

@protocol UIViewControllerAnimatedTransitioning
- (double)transitionDuration:
    (id<UIViewControllerContextTransitioning>)context;
- (void)animateTransition:
    (id<UIViewControllerContextTransitioning>)context;
@optional
- (void)animationEnded:(BOOL)transitionCompleted;
@end

@protocol UIViewControllerInteractiveTransitioning
- (void)startInteractiveTransition:
    (id<UIViewControllerContextTransitioning>)context;
@optional
- (double)completionSpeed;
- (long)completionCurve;
@end

@protocol UIViewControllerTransitioningDelegate
@optional
- (id<UIViewControllerAnimatedTransitioning>)
    animationControllerForPresentedController:(UIViewController *)presented
                         presentingController:(UIViewController *)presenting
                             sourceController:(UIViewController *)source;
- (id<UIViewControllerAnimatedTransitioning>)
    animationControllerForDismissedController:(UIViewController *)dismissed;
- (id<UIViewControllerInteractiveTransitioning>)
    interactionControllerForPresentation:
        (id<UIViewControllerAnimatedTransitioning>)animator;
- (id<UIViewControllerInteractiveTransitioning>)
    interactionControllerForDismissal:
        (id<UIViewControllerAnimatedTransitioning>)animator;
- (UIPresentationController *)
    presentationControllerForPresentedViewController:(UIViewController *)presented
                            presentingViewController:(UIViewController *)presenting
                                sourceViewController:(UIViewController *)source;
@end

@interface UIPercentDrivenInteractiveTransition : NSObject
    <UIViewControllerInteractiveTransitioning> {
@public
    double _percentComplete;
    double _completionSpeed;
    long _completionCurve;
    id _animator;
    id _context;
}
- (double)percentComplete;
- (void)setPercentComplete:(double)percent;
- (double)completionSpeed;
- (void)setCompletionSpeed:(double)speed;
- (long)completionCurve;
- (void)setCompletionCurve:(long)curve;
- (void)updateInteractiveTransition:(double)percentComplete;
- (void)cancelInteractiveTransition;
- (void)finishInteractiveTransition;
- (void)pauseInteractiveTransition;
@end

@interface _UIViewControllerTransitionContext : NSObject
    <UIViewControllerContextTransitioning> {
@public
    UIView *_containerView;
    UIViewController *_fromController;
    UIViewController *_toController;
    BOOL _animated;
    BOOL _interactive;
    BOOL _cancelled;
    long _presentationStyle;
    void (^_completion)(BOOL completed);
}
- (id)initWithContainerView:(UIView *)container
           fromController:(UIViewController *)from
             toController:(UIViewController *)to
                 animated:(BOOL)animated
        presentationStyle:(long)style
               completion:(void (^)(BOOL completed))completion;
@end

@protocol UIContentContainer
- (CGSize)preferredContentSize;
- (void)preferredContentSizeDidChangeForChildContentContainer:
    (id<UIContentContainer>)container;
- (void)systemLayoutFittingSizeDidChangeForChildContentContainer:
    (id<UIContentContainer>)container;
@end

@protocol UIViewControllerTransitionCoordinatorContext
- (BOOL)isAnimated;
- (BOOL)isInteractive;
- (BOOL)isCancelled;
- (double)transitionDuration;
- (double)percentComplete;
- (long)completionCurve;
- (double)completionVelocity;
- (UIView *)containerView;
- (UIViewController *)viewControllerForKey:(NSString *)key;
- (UIView *)viewForKey:(NSString *)key;
- (CGAffineTransform)targetTransform;
- (long)presentationStyle;
@end

@protocol UIViewControllerTransitionCoordinator
    <UIViewControllerTransitionCoordinatorContext>
- (BOOL)animateAlongsideTransition:
    (void (^)(id<UIViewControllerTransitionCoordinatorContext> context))animation
                       completion:
    (void (^)(id<UIViewControllerTransitionCoordinatorContext> context))completion;
- (BOOL)animateAlongsideTransitionInView:(UIView *)view
                               animation:
    (void (^)(id<UIViewControllerTransitionCoordinatorContext> context))animation
                              completion:
    (void (^)(id<UIViewControllerTransitionCoordinatorContext> context))completion;
- (void)notifyWhenInteractionChangesUsingBlock:
    (void (^)(id<UIViewControllerTransitionCoordinatorContext> context))handler;
- (void)notifyWhenInteractionEndsUsingBlock:
    (void (^)(id<UIViewControllerTransitionCoordinatorContext> context))handler;
@end

@interface _UIViewControllerTransitionCoordinator : NSObject
    <UIViewControllerTransitionCoordinator> {
@public
    UIView *_containerView;
    UIViewController *_fromController;
    UIViewController *_toController;
    BOOL _animated;
    BOOL _interactive;
    BOOL _cancelled;
    double _duration;
    double _percentComplete;
    CGSize _targetSize;
    id _targetTraitCollection;
}
- (id)initWithContainerView:(UIView *)container
             fromController:(UIViewController *)from
               toController:(UIViewController *)to
                   animated:(BOOL)animated
                   duration:(double)duration;
@end

@interface UIViewController : NSObject <UIContentContainer> {
@public
    UIView *_view;
    BOOL _viewLoaded;
    id _title;
    id _navigationController;
    id _presentedController;
    id _tabBarItem;
    id _navigationItem;
    long _modalPresentationStyle;
    long _modalTransitionStyle;
    BOOL _modalPresentationCapturesStatusBarAppearance;
    BOOL _hidesBottomBarWhenPushed;
    id _toolbarItems;
    UIEdgeInsets _additionalSafeAreaInsets;
    id _parentController;
    id _popoverPresentationController;
    id _sheetPresentationController;
    id _presentationController;
    id _children[16];
    int _childCount;
    unsigned long _edgesForExtendedLayout;
    BOOL _extendedLayoutIncludesOpaqueBars;
    BOOL _automaticallyAdjustsScrollViewInsets;
    BOOL _definesPresentationContext;
    BOOL _modalInPresentation;
    id _restorationIdentifier;
    CGSize _preferredContentSize;
    id _transitioningDelegate;
    id _transitionContext;
    id _transitionAnimator;
    id _transitionCoordinator;
    CGSize _lastTransitionSize;
    BOOL _beingPresented;
    BOOL _beingDismissed;
}
- (id)init;
- (id)title;
- (id<UIViewControllerTransitioningDelegate>)transitioningDelegate;
- (void)setTransitioningDelegate:
    (id<UIViewControllerTransitioningDelegate>)delegate;
- (UIPopoverPresentationController *)popoverPresentationController;
- (UISheetPresentationController *)sheetPresentationController;
- (UIPresentationController *)presentationController;
- (long)modalPresentationStyle;
- (void)setModalPresentationStyle:(long)style;
- (long)modalTransitionStyle;
- (void)setModalTransitionStyle:(long)style;
- (BOOL)modalPresentationCapturesStatusBarAppearance;
- (void)setModalPresentationCapturesStatusBarAppearance:(BOOL)captures;
- (BOOL)hidesBottomBarWhenPushed;
- (void)setHidesBottomBarWhenPushed:(BOOL)hides;
- (NSArray *)toolbarItems;
- (void)setToolbarItems:(NSArray *)items;
- (void)setToolbarItems:(NSArray *)items animated:(BOOL)animated;
- (void)setTitle:(id)title;
- (id)navigationController;
- (id)tabBarController;
- (id)tabBarItem;
- (void)setTabBarItem:(id)item;
- (id)navigationItem;
- (UIView *)view;
- (UIView *)viewIfLoaded;
- (BOOL)isViewLoaded;
- (void)setView:(UIView *)view;
- (void)loadViewIfNeeded;
- (BOOL)isBeingPresented;
- (BOOL)isBeingDismissed;
- (BOOL)isMovingFromParentViewController;
- (BOOL)isMovingToParentViewController;
- (BOOL)shouldAutorotate;
- (unsigned long)supportedInterfaceOrientations;
- (unsigned long)edgesForExtendedLayout;
- (void)setEdgesForExtendedLayout:(unsigned long)edges;
- (BOOL)extendedLayoutIncludesOpaqueBars;
- (void)setExtendedLayoutIncludesOpaqueBars:(BOOL)includes;
- (BOOL)automaticallyAdjustsScrollViewInsets;
- (void)setAutomaticallyAdjustsScrollViewInsets:(BOOL)adjusts;
- (BOOL)definesPresentationContext;
- (void)setDefinesPresentationContext:(BOOL)defines;
- (BOOL)isModalInPresentation;
- (void)setModalInPresentation:(BOOL)modal;
- (id)restorationIdentifier;
- (void)setRestorationIdentifier:(id)identifier;
- (CGSize)preferredContentSize;
- (void)setPreferredContentSize:(CGSize)size;
- (void)preferredContentSizeDidChangeForChildContentContainer:
    (id<UIContentContainer>)container;
- (void)systemLayoutFittingSizeDidChangeForChildContentContainer:
    (id<UIContentContainer>)container;
- (id<UIViewControllerTransitionCoordinator>)transitionCoordinator;
- (void)viewWillTransitionToSize:(CGSize)size
       withTransitionCoordinator:
    (id<UIViewControllerTransitionCoordinator>)coordinator;
- (void)willTransitionToTraitCollection:(UITraitCollection *)newCollection
              withTransitionCoordinator:
    (id<UIViewControllerTransitionCoordinator>)coordinator;
- (UIViewController *)parentViewController;
- (NSArray *)children;
- (void)addChildViewController:(UIViewController *)controller;
- (void)removeFromParentViewController;
- (void)willMoveToParentViewController:(UIViewController *)parent;
- (void)didMoveToParentViewController:(UIViewController *)parent;
- (void)transitionFromViewController:(UIViewController *)fromViewController
                    toViewController:(UIViewController *)toViewController
                            duration:(double)duration
                             options:(unsigned long)options
                          animations:(void (^)(void))animations
                          completion:(void (^)(BOOL finished))completion;
- (void)loadView;
- (void)viewDidLoad;
- (void)viewWillAppear:(BOOL)animated;
- (void)viewDidAppear:(BOOL)animated;
- (long)preferredStatusBarStyle;
- (BOOL)prefersStatusBarHidden;
- (UIViewController *)childForStatusBarStyle;
- (UIViewController *)childForStatusBarHidden;
- (void)setNeedsStatusBarAppearanceUpdate;
- (void)viewWillDisappear:(BOOL)animated;
- (void)viewDidDisappear:(BOOL)animated;
- (void)viewWillLayoutSubviews;
- (void)viewDidLayoutSubviews;
- (void)presentViewController:(UIViewController *)controller animated:(BOOL)animated
                   completion:(void (^)(void))completion;
- (void)showViewController:(UIViewController *)controller sender:(id)sender;
- (void)showDetailViewController:(UIViewController *)controller sender:(id)sender;
- (void)dismissViewControllerAnimated:(BOOL)animated
                           completion:(void (^)(void))completion;
- (UIViewController *)presentedViewController;
- (UITraitCollection *)traitCollection;
- (long)overrideUserInterfaceStyle;
- (void)setOverrideUserInterfaceStyle:(long)style;
- (void)traitCollectionDidChange:(UITraitCollection *)previous;
- (UIEdgeInsets)additionalSafeAreaInsets;
- (void)setAdditionalSafeAreaInsets:(UIEdgeInsets)insets;
- (void)viewSafeAreaInsetsDidChange;
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
    id _image;
    BOOL _enabled;
    void (^_handler)(UIAlertAction *);
}
+ (id)actionWithTitle:(id)title style:(long)style
              handler:(void (^)(UIAlertAction *action))handler;
- (id)title;
- (long)style;
- (UIImage *)image;
- (void)setImage:(UIImage *)image;
- (BOOL)isEnabled;
- (void)setEnabled:(BOOL)enabled;
- (void (^)(UIAlertAction *))handler;
@end

@class UITextField;

@interface UIAlertController : UIViewController {
@public
    id _message;
    id _actions[8];
    int _actionCount;
    long _preferredStyle;
    id _textFields;
    id _preferredAction;
}
+ (id)alertControllerWithTitle:(id)title message:(id)message
                 preferredStyle:(long)style;
- (void)addAction:(UIAlertAction *)action;
- (id)message;
- (long)preferredStyle;
- (NSArray *)actions;
- (NSArray *)textFields;
- (void)addTextFieldWithConfigurationHandler:
    (void (^)(UITextField *textField))configurationHandler;
- (UIAlertAction *)preferredAction;
- (void)setPreferredAction:(UIAlertAction *)action;
@end

/* ---------------------------------------------------------- activities */

typedef id UIActivityType;

enum {
    UIActivityCategoryAction = 0,
    UIActivityCategoryShare = 1
};

@class UIActivityViewController;

@protocol UIActivityItemSource
- (id)activityViewControllerPlaceholderItem:(UIActivityViewController *)activityViewController;
- (id)activityViewController:(UIActivityViewController *)activityViewController
        itemForActivityType:(UIActivityType)activityType;
@optional
- (id)activityViewController:(UIActivityViewController *)activityViewController
        subjectForActivityType:(UIActivityType)activityType;
- (UIImage *)activityViewController:(UIActivityViewController *)activityViewController
    thumbnailImageForActivityType:(UIActivityType)activityType
                     suggestedSize:(CGSize)size;
- (id)activityViewController:(UIActivityViewController *)activityViewController
    dataTypeIdentifierForActivityType:(UIActivityType)activityType;
@end

@interface UIActivity : NSObject
+ (long)activityCategory;
- (UIActivityType)activityType;
- (id)activityTitle;
- (UIImage *)activityImage;
- (BOOL)canPerformWithActivityItems:(NSArray *)activityItems;
- (void)prepareWithActivityItems:(NSArray *)activityItems;
- (UIViewController *)activityViewController;
- (void)performActivity;
- (void)activityDidFinish:(BOOL)completed;
@end

@interface UIActivityViewController : UIViewController {
@public
    id _activityItems;
    id _applicationActivities;
    id _excludedActivityTypes;
    id _availableActivities;
    void (^_completionWithItemsHandler)(id, BOOL, id, id);
    void (^_completionHandler)(id, BOOL);
}
- (id)initWithActivityItems:(NSArray *)activityItems
       applicationActivities:(NSArray *)applicationActivities;
- (NSArray *)activityItems;
- (NSArray *)applicationActivities;
- (void)setExcludedActivityTypes:(NSArray *)excludedActivityTypes;
- (NSArray *)excludedActivityTypes;
- (void)setCompletionWithItemsHandler:(void (^)(id activityType,
                                               BOOL completed,
                                               id returnedItems,
                                               id error))handler;
- (void (^)(id, BOOL, id, id))completionWithItemsHandler;
- (void)setCompletionHandler:(void (^)(id activityType,
                                       BOOL completed))handler;
- (void (^)(id, BOOL))completionHandler;
- (NSArray *)_availableActivities;
- (void)_activityDidFinish:(UIActivity *)activity completed:(BOOL)completed;
@end

/* ---------------------------------------------------- context menus */

typedef id UIActionIdentifier;

enum {
    UIMenuElementAttributesDisabled = 1 << 0,
    UIMenuElementAttributesDestructive = 1 << 1,
    UIMenuElementAttributesHidden = 1 << 2,
    UIMenuElementAttributesKeepsMenuPresented = 1 << 3
};

enum {
    UIMenuOptionsDisplayInline = 1 << 0,
    UIMenuOptionsDestructive = 1 << 1,
    UIMenuOptionsSingleSelection = 1 << 2,
    UIMenuOptionsDisplayAsPalette = 1 << 3
};

@class UIMenu, UIAction, UIContextMenuConfiguration;
@class UIContextMenuInteraction;

@interface UIMenuElement : NSObject {
@public
    id _title;
    UIImage *_image;
    long _attributes;
}
- (id)title;
- (UIImage *)image;
- (long)attributes;
@end

@interface UIAction : UIMenuElement {
@public
    id _identifier;
    void (^_handler)(UIAction *);
    long _state;
}
+ (id)actionWithTitle:(id)title image:(UIImage *)image
           identifier:(id)identifier
              handler:(void (^)(UIAction *action))handler;
- (id)identifier;
- (long)state;
- (void)setState:(long)state;
- (void)setAttributes:(long)attributes;
@end

@interface UIMenu : UIMenuElement {
@public
    id _identifier;
    id _children;
    long _options;
}
+ (id)menuWithTitle:(id)title children:(NSArray *)children;
+ (id)menuWithTitle:(id)title image:(UIImage *)image identifier:(id)identifier
            options:(long)options children:(NSArray *)children;
- (NSArray *)children;
- (id)identifier;
- (long)options;
@end

@interface UIContextMenuConfiguration : NSObject {
@public
    id _identifier;
    UIViewController *(^_previewProvider)(void);
    UIMenu *(^_actionProvider)(NSArray *);
}
+ (id)configurationWithIdentifier:(id)identifier
                  previewProvider:(UIViewController *(^)(void))previewProvider
                   actionProvider:(UIMenu *(^)(NSArray *))actionProvider;
- (id)identifier;
- (UIViewController *(^)(void))previewProvider;
- (UIMenu *(^)(NSArray *))actionProvider;
@end

@interface UIContextMenuInteraction : NSObject {
@public
    id _delegate;
    UIView *_view;
    CGPoint _location;
}
- (id)initWithDelegate:(id)delegate;
- (id)delegate;
- (CGPoint)locationInView:(UIView *)view;
- (UIView *)view;
- (void)willMoveToView:(UIView *)view;
- (void)didMoveToView:(UIView *)view;
@end

@protocol UIContextMenuInteractionDelegate
- (UIContextMenuConfiguration *)contextMenuInteraction:
    (UIContextMenuInteraction *)interaction
    configurationForMenuAtLocation:(CGPoint)location;
@optional
- (void)contextMenuInteraction:(UIContextMenuInteraction *)interaction
    willDisplayMenuForConfiguration:(UIContextMenuConfiguration *)configuration
                            animator:(id)animator;
- (void)contextMenuInteraction:(UIContextMenuInteraction *)interaction
    willEndForConfiguration:(UIContextMenuConfiguration *)configuration
                   animator:(id)animator;
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
    UIImage *_image;
    UIColor *_tintColor;
    id _customView;
    double _width;
    BOOL _enabled;
}
- (id)initWithTitle:(id)title style:(long)style target:(id)target
             action:(SEL)action;
- (id)initWithImage:(UIImage *)image style:(long)style target:(id)target
             action:(SEL)action;
- (id)initWithCustomView:(UIView *)view;
- (UIImage *)image;
- (void)setImage:(UIImage *)image;
- (UIColor *)tintColor;
- (void)setTintColor:(UIColor *)color;
- (id)customView;
- (double)width;
- (void)setWidth:(double)width;
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
    id _backButtonTitle;
    id _leftBarButtonItems;
    id _rightBarButtonItems;
    id _prompt;
    id _searchController;
    long _largeTitleDisplayMode;
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
- (id)backButtonTitle;
- (void)setBackButtonTitle:(id)title;
- (NSArray *)leftBarButtonItems;
- (void)setLeftBarButtonItems:(NSArray *)items;
- (void)setLeftBarButtonItems:(NSArray *)items animated:(BOOL)animated;
- (NSArray *)rightBarButtonItems;
- (void)setRightBarButtonItems:(NSArray *)items;
- (void)setRightBarButtonItems:(NSArray *)items animated:(BOOL)animated;
- (id)prompt;
- (void)setPrompt:(id)prompt;
- (id)searchController;
- (void)setSearchController:(id)controller;
- (long)largeTitleDisplayMode;
- (void)setLargeTitleDisplayMode:(long)mode;
@end

@interface UINavigationBar : UIView {
@public
    id _items;
    UINavigationItem *_topItem;
    UILabel *_titleLabel;
    UIView *_leftControl;
    UIView *_rightControl;
    UIColor *_barTintColor;
    id _titleTextAttributes;
    id _largeTitleTextAttributes;
    long _barStyle;
    BOOL _prefersLargeTitles;
    BOOL _translucent;
}
- (void)setItems:(NSArray *)items animated:(BOOL)animated;
- (NSArray *)items;
- (UINavigationItem *)topItem;
- (void)pushNavigationItem:(UINavigationItem *)item animated:(BOOL)animated;
- (UINavigationItem *)popNavigationItemAnimated:(BOOL)animated;
- (void)setBarTintColor:(UIColor *)color;
- (UIColor *)barTintColor;
- (long)barStyle;
- (void)setBarStyle:(long)style;
- (BOOL)prefersLargeTitles;
- (void)setPrefersLargeTitles:(BOOL)prefers;
- (BOOL)isTranslucent;
- (void)setTranslucent:(BOOL)translucent;
- (id)titleTextAttributes;
- (void)setTitleTextAttributes:(id)attributes;
- (id)largeTitleTextAttributes;
- (void)setLargeTitleTextAttributes:(id)attributes;
@end

@interface UIToolbar : UIView {
@public
    id _items;
    UIColor *_barTintColor;
    int _barStyle;
    BOOL _translucent;
    UIView *_controls[16];
    int _controlCount;
}
- (void)setItems:(NSArray *)items animated:(BOOL)animated;
- (NSArray *)items;
- (void)setBarTintColor:(UIColor *)color;
- (UIColor *)barTintColor;
- (void)setTintColor:(UIColor *)color;
- (UIColor *)tintColor;
- (void)setBarStyle:(int)style;
- (int)barStyle;
- (void)setTranslucent:(BOOL)translucent;
- (BOOL)isTranslucent;
@end

@interface UINavigationController : UIViewController {
@public
    id _stack[32];
    int _stackCount;
    UIView *_navBar;
    UILabel *_navTitleLabel;
    BOOL _navBarHidden;
    UIToolbar *_navToolbar;
    BOOL _toolbarHidden;
    UIView *_contentView;
    id _leftButton;
    id _rightButton;
    UIPanGestureRecognizer *_interactivePopGesture;
    id _delegate;
}
- (id)delegate;
- (void)setDelegate:(id)delegate;
- (id)initWithRootViewController:(UIViewController *)root;
- (UINavigationBar *)navigationBar;
- (UIViewController *)topViewController;
- (NSArray *)viewControllers;
- (void)setViewControllers:(NSArray *)controllers animated:(BOOL)animated;
- (void)pushViewController:(UIViewController *)controller animated:(BOOL)animated;
- (UIViewController *)popViewControllerAnimated:(BOOL)animated;
- (void)setNavigationBarHidden:(BOOL)hidden animated:(BOOL)animated;
- (BOOL)isNavigationBarHidden;
- (BOOL)navigationBarHidden;
- (void)setNavigationBarHidden:(BOOL)hidden;
- (UIToolbar *)toolbar;
- (void)setToolbarHidden:(BOOL)hidden animated:(BOOL)animated;
- (void)setToolbarHidden:(BOOL)hidden;
- (BOOL)isToolbarHidden;
- (UIGestureRecognizer *)interactivePopGestureRecognizer;
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
    id _delegate;
}
- (id)delegate;
- (void)setDelegate:(id)delegate;
- (void)setViewControllers:(NSArray *)controllers;
- (void)setViewControllers:(NSArray *)controllers animated:(BOOL)animated;
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

#define REFRESH_CONTROL_HEIGHT 60.0

/* Pull-to-refresh control. The scroll view owns it, positions it above the
 * content and sends ValueChanged when a pull passes the threshold. */
@interface UIRefreshControl : UIControl {
@public
    BOOL _refreshing;
    double _pullProgress;
    id _scrollView;
    id _attributedTitle;
}
- (BOOL)isRefreshing;
- (void)beginRefreshing;
- (void)endRefreshing;
- (id)attributedTitle;
- (void)setAttributedTitle:(id)title;
@end

typedef enum {
    UIButtonConfigurationCornerStyleFixed = 0,
    UIButtonConfigurationCornerStyleDynamic = 1,
    UIButtonConfigurationCornerStyleCapsule = 2,
    UIButtonConfigurationCornerStyleLarge = 3
} UIButtonConfigurationCornerStyle;

@interface UIButtonConfiguration : NSObject {
@public
    id _title;
    id _subtitle;
    UIImage *_image;
    UIColor *_baseForegroundColor;
    UIColor *_baseBackgroundColor;
    long _cornerStyle;
    UIEdgeInsets _contentInsets;
    double _imagePadding;
}
+ (id)plainButtonConfiguration;
+ (id)filledButtonConfiguration;
+ (id)grayButtonConfiguration;
+ (id)tintedButtonConfiguration;
+ (id)borderedButtonConfiguration;
+ (id)borderlessButtonConfiguration;
+ (id)configurationWithTitle:(id)title;
- (id)title;
- (void)setTitle:(id)title;
- (id)subtitle;
- (void)setSubtitle:(id)subtitle;
- (UIImage *)image;
- (void)setImage:(UIImage *)image;
- (UIColor *)baseForegroundColor;
- (void)setBaseForegroundColor:(UIColor *)color;
- (UIColor *)baseBackgroundColor;
- (void)setBaseBackgroundColor:(UIColor *)color;
- (long)cornerStyle;
- (void)setCornerStyle:(long)style;
- (UIEdgeInsets)contentInsets;
- (void)setContentInsets:(UIEdgeInsets)insets;
- (double)imagePadding;
- (void)setImagePadding:(double)padding;
@end

@interface UIButton : UIControl {
@public
    id _title;
    id _attributedTitle;
    UIImage *_image;
    UIImageView *_imageView;
    UIColor *_titleColor;
    UILabel *_titleLabel;
    UIButtonConfiguration *_configuration;
    UIEdgeInsets _contentEdgeInsets;
    UIEdgeInsets _titleEdgeInsets;
    UIEdgeInsets _imageEdgeInsets;
    BOOL _titleColorCustom;
}
+ (id)buttonWithType:(int)type;
- (UIButtonConfiguration *)configuration;
- (void)setConfiguration:(UIButtonConfiguration *)configuration;
- (void)setNeedsUpdateConfiguration;
- (void)updateConfiguration;
- (void)setImage:(UIImage *)image forState:(unsigned long)state;
- (UIImage *)imageForState:(unsigned long)state;
- (UIImageView *)imageView;
- (void)setTitle:(id)title forState:(unsigned long)state;
- (void)setAttributedTitle:(id)title forState:(unsigned long)state;
- (id)attributedTitleForState:(unsigned long)state;
- (void)setTitleColor:(UIColor *)color forState:(unsigned long)state;
- (UIEdgeInsets)contentEdgeInsets;
- (void)setContentEdgeInsets:(UIEdgeInsets)insets;
- (UIEdgeInsets)titleEdgeInsets;
- (void)setTitleEdgeInsets:(UIEdgeInsets)insets;
- (UIEdgeInsets)imageEdgeInsets;
- (void)setImageEdgeInsets:(UIEdgeInsets)insets;
@end


@class UITextField;

@protocol UITextFieldDelegate
@optional
- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField;
- (void)textFieldDidBeginEditing:(UITextField *)textField;
- (BOOL)textFieldShouldEndEditing:(UITextField *)textField;
- (void)textFieldDidEndEditing:(UITextField *)textField;
- (BOOL)textField:(UITextField *)textField
    shouldChangeCharactersInRange:(NSRange)range
                replacementString:(NSString *)string;
- (BOOL)textFieldShouldReturn:(UITextField *)textField;
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
    int _borderStyle;
    BOOL _clearsOnBeginEditing;
    id _leftView;
    id _rightView;
    long _leftViewMode;
    long _rightViewMode;
    long _clearButtonMode;
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
- (int)borderStyle;
- (void)setBorderStyle:(int)style;
- (BOOL)clearsOnBeginEditing;
- (void)setClearsOnBeginEditing:(BOOL)clears;
- (id)leftView;
- (void)setLeftView:(id)view;
- (id)rightView;
- (void)setRightView:(id)view;
- (long)leftViewMode;
- (void)setLeftViewMode:(long)mode;
- (long)rightViewMode;
- (void)setRightViewMode:(long)mode;
- (long)clearButtonMode;
- (void)setClearButtonMode:(long)mode;
- (void)setDelegate:(id)delegate;
- (id)delegate;
- (BOOL)becomeFirstResponder;
- (BOOL)resignFirstResponder;
- (BOOL)isFirstResponder;
- (BOOL)hasText;
- (void)insertText:(id)text;
- (void)deleteBackward;
- (void)handleReturnKey;
- (CGSize)intrinsicContentSize;
@end

@interface UISearchBar : UIView {
@public
    id _delegate;
    id _field;
    id _cancelButton;
    id _placeholder;
    id _scopeButtonTitles;
    id _barTintColor;
    id _backgroundImage;
    long _selectedScopeButtonIndex;
    long _searchBarStyle;
    BOOL _showsCancelButton;
    BOOL _showsScopeBar;
}
- (void)setDelegate:(id)delegate;
- (id)delegate;
- (id)text;
- (void)setText:(id)text;
- (id)placeholder;
- (void)setPlaceholder:(id)text;
- (BOOL)showsCancelButton;
- (void)setShowsCancelButton:(BOOL)shows animated:(BOOL)animated;
- (NSArray *)scopeButtonTitles;
- (void)setScopeButtonTitles:(NSArray *)titles;
- (long)selectedScopeButtonIndex;
- (void)setSelectedScopeButtonIndex:(long)index;
- (BOOL)showsScopeBar;
- (void)setShowsScopeBar:(BOOL)shows;
- (UIColor *)barTintColor;
- (void)setBarTintColor:(UIColor *)color;
- (long)searchBarStyle;
- (void)setSearchBarStyle:(long)style;
- (UIImage *)backgroundImage;
- (void)setBackgroundImage:(UIImage *)image;
- (void)searchButtonClicked;
@end

@class UISearchController;
@protocol UISearchResultsUpdating
- (void)updateSearchResultsForSearchController:
    (UISearchController *)searchController;
@end

@interface UISearchController : UIViewController {
@public
    id _searchResultsUpdater;
    id _searchResultsController;
    id _delegate;
    UISearchBar *_searchBar;
    BOOL _active;
    BOOL _obscuresBackgroundDuringPresentation;
    BOOL _dimsBackgroundDuringPresentation;
    BOOL _hidesNavigationBarDuringPresentation;
}
- (id)initWithSearchResultsController:(UIViewController *)controller;
- (UISearchBar *)searchBar;
- (id)searchResultsUpdater;
- (void)setSearchResultsUpdater:(id)updater;
- (id)delegate;
- (void)setDelegate:(id)delegate;
- (UIViewController *)searchResultsController;
- (BOOL)isActive;
- (void)setActive:(BOOL)active;
- (void)setActive:(BOOL)active animated:(BOOL)animated;
- (BOOL)obscuresBackgroundDuringPresentation;
- (void)setObscuresBackgroundDuringPresentation:(BOOL)value;
- (BOOL)dimsBackgroundDuringPresentation;
- (void)setDimsBackgroundDuringPresentation:(BOOL)value;
- (BOOL)hidesNavigationBarDuringPresentation;
- (void)setHidesNavigationBarDuringPresentation:(BOOL)value;
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

@interface UIStepper : UIControl {
@public
    double _value;
    double _minimumValue;
    double _maximumValue;
    double _stepValue;
    BOOL _continuous;
    BOOL _autorepeat;
    BOOL _wraps;
    id _plusButton;
    id _minusButton;
    id _divider;
}
- (double)value;
- (void)setValue:(double)value;
- (double)minimumValue;
- (void)setMinimumValue:(double)value;
- (double)maximumValue;
- (void)setMaximumValue:(double)value;
- (double)stepValue;
- (void)setStepValue:(double)value;
- (BOOL)isContinuous;
- (void)setContinuous:(BOOL)continuous;
- (BOOL)autorepeats;
- (void)setAutorepeats:(BOOL)repeats;
- (BOOL)wraps;
- (void)setWraps:(BOOL)wraps;
@end

#define PICKER_MAX_COMPONENTS 8
#define PICKER_ROW_HEIGHT 32.0

@interface UIPickerView : UIView {
@public
    id _dataSource;
    id _delegate;
    long _selectedRows[PICKER_MAX_COMPONENTS];
    double _rowOffsets[PICKER_MAX_COMPONENTS];
    long _dragComponent;
    double _dragStartOffset;
    CGPoint _dragStartPoint;
    BOOL _dragging;
}
- (void)setDataSource:(id)dataSource;
- (id)dataSource;
- (void)setDelegate:(id)delegate;
- (id)delegate;
- (long)numberOfComponents;
- (long)numberOfRowsInComponent:(long)component;
- (long)selectedRowInComponent:(long)component;
- (void)selectRow:(long)row inComponent:(long)component animated:(BOOL)animated;
- (void)reloadAllComponents;
- (void)reloadComponent:(long)component;
@end

enum {
    UIDatePickerModeTime = 0,
    UIDatePickerModeDate = 1,
    UIDatePickerModeDateAndTime = 2,
    UIDatePickerModeCountDownTimer = 3
};

enum {
    UIDatePickerStyleAutomatic = 0,
    UIDatePickerStyleWheels = 1,
    UIDatePickerStyleCompact = 2,
    UIDatePickerStyleInline = 3
};

@interface UIDatePicker : UIControl {
@public
    long _mode;
    long _style;
    double _dateInterval;
    double _countdownDuration;
    UIPickerView *_pickerView;
    NSCalendar *_calendar;
    BOOL _settingUp;
}
- (NSDate *)date;
- (void)setDate:(NSDate *)date;
- (void)setDate:(NSDate *)date animated:(BOOL)animated;
- (long)datePickerMode;
- (void)setDatePickerMode:(long)mode;
- (long)preferredDatePickerStyle;
- (void)setPreferredDatePickerStyle:(long)style;
- (NSCalendar *)calendar;
- (void)setCalendar:(NSCalendar *)calendar;
- (double)countDownDuration;
- (void)setCountDownDuration:(double)duration;
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

enum {
    UIPageViewControllerNavigationDirectionForward = 0,
    UIPageViewControllerNavigationDirectionReverse = 1
};

enum {
    UIPageViewControllerTransitionStylePageCurl = 0,
    UIPageViewControllerTransitionStyleScroll = 1
};

enum {
    UIPageViewControllerNavigationOrientationHorizontal = 0,
    UIPageViewControllerNavigationOrientationVertical = 1
};

enum {
    UIPageViewControllerSpineLocationMin = 1,
    UIPageViewControllerSpineLocationMid = 2,
    UIPageViewControllerSpineLocationMax = 3
};

#define UIPageViewControllerOptionInterPageSpacingKey \
    ((id)@"UIPageViewControllerOptionInterPageSpacingKey")
#define UIPageViewControllerOptionSpineLocationKey \
    ((id)@"UIPageViewControllerOptionSpineLocationKey")

@class UIPageViewController;

@protocol UIPageViewControllerDelegate
@optional
- (void)pageViewController:(UIPageViewController *)pageViewController
    didFinishAnimating:(BOOL)finished
   previousViewControllers:(NSArray *)previousViewControllers
       transitionCompleted:(BOOL)completed;
@end

@protocol UIPageViewControllerDataSource
- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController
      viewControllerBeforeViewController:(UIViewController *)viewController;
- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController
       viewControllerAfterViewController:(UIViewController *)viewController;
@end

@interface UIPageViewController : UIViewController {
@public
    id _pageDelegate;
    id _dataSource;
    NSArray *_pageControllers;
    long _transitionStyle;
    long _navigationOrientation;
    long _spineLocation;
    BOOL _doubleSided;
}
- (id)initWithTransitionStyle:(long)style
        navigationOrientation:(long)orientation
                      options:(id)options;
- (void)setViewControllers:(NSArray *)viewControllers
                 direction:(long)direction
                  animated:(BOOL)animated
                completion:(void (^)(BOOL finished))completion;
- (NSArray *)viewControllers;
- (id)delegate;
- (void)setDelegate:(id)delegate;
- (id)dataSource;
- (void)setDataSource:(id)dataSource;
- (long)transitionStyle;
- (long)navigationOrientation;
- (long)spineLocation;
- (BOOL)isDoubleSided;
- (void)setDoubleSided:(BOOL)doubleSided;
- (void)installCurrentPage;
@end

enum {
    UISplitViewControllerStyleAutomatic = 0,
    UISplitViewControllerStyleDoubleColumn = 1,
    UISplitViewControllerStyleTripleColumn = 2
};

enum {
    UISplitViewControllerColumnPrimary = 0,
    UISplitViewControllerColumnSupplementary = 1,
    UISplitViewControllerColumnSecondary = 2,
    UISplitViewControllerColumnCompact = 3
};

enum {
    UISplitViewControllerDisplayModeAutomatic = 0,
    UISplitViewControllerDisplayModeSecondaryOnly = 1,
    UISplitViewControllerDisplayModePrimaryHidden = 1,
    UISplitViewControllerDisplayModeOneBesideSecondary = 2,
    UISplitViewControllerDisplayModeAllVisible = 2,
    UISplitViewControllerDisplayModeOneOverSecondary = 3,
    UISplitViewControllerDisplayModePrimaryOverlay = 3,
    UISplitViewControllerDisplayModeTwoBesideSecondary = 4,
    UISplitViewControllerDisplayModeTwoOverSecondary = 5,
    UISplitViewControllerDisplayModeTwoDisplaceSecondary = 6
};

@class UISplitViewController;

@protocol UISplitViewControllerDelegate
@optional
- (BOOL)splitViewController:(UISplitViewController *)splitViewController
    collapseSecondaryViewController:(UIViewController *)secondaryViewController
        ontoPrimaryViewController:(UIViewController *)primaryViewController;
- (UIViewController *)primaryViewControllerForCollapsingSplitViewController:
    (UISplitViewController *)splitViewController;
- (UIViewController *)primaryViewControllerForExpandingSplitViewController:
    (UISplitViewController *)splitViewController;
- (void)splitViewController:(UISplitViewController *)splitViewController
       willChangeToDisplayMode:(long)displayMode;
- (long)splitViewController:(UISplitViewController *)splitViewController
    displayModeForExpandingToProposedDisplayMode:(long)proposedDisplayMode;
- (long)targetDisplayModeForActionInSplitViewController:
    (UISplitViewController *)splitViewController;
- (BOOL)splitViewController:(UISplitViewController *)splitViewController
       showDetailViewController:(UIViewController *)viewController
                         sender:(id)sender;
- (BOOL)splitViewController:(UISplitViewController *)splitViewController
           showViewController:(UIViewController *)viewController
                         sender:(id)sender;
@end

@interface UISplitViewController : UIViewController {
@public
    UIViewController *_splitPrimary;
    UIViewController *_splitSupplementary;
    UIViewController *_splitSecondary;
    id _splitDelegate;
    long _splitStyle;
    long _preferredDisplayMode;
    double _preferredPrimaryColumnWidthFraction;
    double _minimumPrimaryColumnWidth;
    double _maximumPrimaryColumnWidth;
    double _supplementaryColumnWidth;
}
- (id)initWithStyle:(long)style;
- (NSArray *)viewControllers;
- (void)setViewControllers:(NSArray *)viewControllers;
- (id)delegate;
- (void)setDelegate:(id)delegate;
- (long)style;
- (long)preferredDisplayMode;
- (void)setPreferredDisplayMode:(long)mode;
- (long)displayMode;
- (BOOL)isCollapsed;
- (UIViewController *)primaryViewController;
- (UIViewController *)secondaryViewController;
- (void)setViewController:(UIViewController *)viewController
                 forColumn:(long)column;
- (UIViewController *)viewControllerForColumn:(long)column;
- (double)preferredPrimaryColumnWidthFraction;
- (void)setPreferredPrimaryColumnWidthFraction:(double)fraction;
- (double)primaryColumnWidth;
- (double)minimumPrimaryColumnWidth;
- (void)setMinimumPrimaryColumnWidth:(double)width;
- (double)maximumPrimaryColumnWidth;
- (void)setMaximumPrimaryColumnWidth:(double)width;
- (double)supplementaryColumnWidth;
- (void)setSupplementaryColumnWidth:(double)width;
- (BOOL)showsSecondaryOnlyButton;
- (void)toggleMasterVisible:(id)sender;
- (void)installControllers;
- (void)layoutColumns;
@end

@class UIScrollView;

@protocol UIScrollViewDelegate
@optional
- (void)scrollViewDidScroll:(UIScrollView *)scrollView;
- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView;
- (void)scrollViewWillEndDragging:(UIScrollView *)scrollView
                     withVelocity:(CGPoint)velocity
              targetContentOffset:(CGPoint *)targetContentOffset;
- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView
                  willDecelerate:(BOOL)decelerate;
- (void)scrollViewWillBeginDecelerating:(UIScrollView *)scrollView;
- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView;
@end

@interface UIScrollView : UIView {
@public
    CGSize _contentSize;
    CGPoint _contentOffset;
    UIEdgeInsets _contentInset;
    double _zoomScale;
    double _minimumZoomScale;
    double _maximumZoomScale;
    double _pinchStartZoom;
    UIView *_zoomView;
    CGSize _zoomBaseSize;
    BOOL _zoomViewResolved;
    BOOL _scrollEnabled;
    BOOL _showsVerticalScrollIndicator;
    BOOL _showsHorizontalScrollIndicator;
    BOOL _bounces;
    BOOL _pagingEnabled;
    BOOL _alwaysBounceVertical;
    BOOL _alwaysBounceHorizontal;
    BOOL _dragging;
    BOOL _decelerating;
    BOOL _offsetAnimating;
    BOOL _hasDecelerationTarget;
    double _decelerationRate;
    double _decelerationStartTime;
    double _lastScrollTick;
    double _offsetAnimationStartTime;
    double _offsetAnimationDuration;
    CGPoint _decelerationVelocity;
    CGPoint _decelerationTarget;
    CGPoint _offsetAnimationStart;
    CGPoint _offsetAnimationTarget;
    id _delegate;
    UIRefreshControl *_refreshControl;
    long _keyboardDismissMode;
    long _indicatorStyle;
    BOOL _scrollsToTop;
}
- (CGSize)contentSize;
- (void)setContentSize:(CGSize)size;
- (CGPoint)contentOffset;
- (double)zoomScale;
- (void)setZoomScale:(double)scale;
- (void)setZoomScale:(double)scale animated:(BOOL)animated;
- (double)minimumZoomScale;
- (void)setMinimumZoomScale:(double)scale;
- (double)maximumZoomScale;
- (void)setMaximumZoomScale:(double)scale;
- (void)zoomToRect:(CGRect)rect animated:(BOOL)animated;
- (BOOL)isZooming;
- (BOOL)isZoomBouncing;
- (void)beginPinchZoom;
- (void)applyPinchScale:(double)factor;
- (void)setContentOffset:(CGPoint)offset;
- (void)setContentOffset:(CGPoint)offset animated:(BOOL)animated;
- (UIEdgeInsets)contentInset;
- (void)setContentInset:(UIEdgeInsets)insets;
- (BOOL)isScrollEnabled;
- (void)setScrollEnabled:(BOOL)enabled;
- (BOOL)isPagingEnabled;
- (void)setPagingEnabled:(BOOL)enabled;
- (BOOL)isDragging;
- (BOOL)isDecelerating;
- (BOOL)isTracking;
- (BOOL)alwaysBounceVertical;
- (void)setAlwaysBounceVertical:(BOOL)value;
- (BOOL)alwaysBounceHorizontal;
- (void)setAlwaysBounceHorizontal:(BOOL)value;
- (double)decelerationRate;
- (void)setDecelerationRate:(double)rate;
- (long)keyboardDismissMode;
- (void)setKeyboardDismissMode:(long)mode;
- (long)indicatorStyle;
- (void)setIndicatorStyle:(long)style;
- (BOOL)scrollsToTop;
- (void)setScrollsToTop:(BOOL)scrolls;
- (void)setDelegate:(id)delegate;
- (id)delegate;
- (BOOL)showsVerticalScrollIndicator;
- (void)setShowsVerticalScrollIndicator:(BOOL)shows;
- (BOOL)showsHorizontalScrollIndicator;
- (void)setShowsHorizontalScrollIndicator:(BOOL)shows;
- (UIRefreshControl *)refreshControl;
- (void)setRefreshControl:(UIRefreshControl *)control;
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
    BOOL _editing;
    long _swipeRow;
    long _swipeSection;
    long _separatorStyle;
    UIColor *_separatorColor;
    UIEdgeInsets _separatorInset;
    id _tableHeaderView;
    id _tableFooterView;
    id _backgroundView;
    id _prefetchDataSource;
    id _dragDelegate;
    id _dropDelegate;
    BOOL _allowsSelection;
    BOOL _allowsMultipleSelection;
    BOOL _allowsSelectionDuringEditing;
    BOOL _allowsMultipleSelectionDuringEditing;
    BOOL _dragInteractionEnabled;
    BOOL _cellLayoutMarginsFollowReadableWidth;
    BOOL _insetsContentViewsToSafeArea;
    double _estimatedRowHeight;
    double _estimatedSectionHeaderHeight;
    double _estimatedSectionFooterHeight;
    double _sectionHeaderHeight;
    double _sectionFooterHeight;
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
- (void)handleSwipeFromPoint:(CGPoint)start toPoint:(CGPoint)end;
- (void)setEditing:(BOOL)editing;
- (void)setEditing:(BOOL)editing animated:(BOOL)animated;
- (BOOL)isEditing;
- (void)deleteRowsAtIndexPaths:(NSArray *)indexPaths
           withRowAnimation:(long)animation;
- (long)separatorStyle;
- (void)setSeparatorStyle:(long)style;
- (UIColor *)separatorColor;
- (void)setSeparatorColor:(UIColor *)color;
- (UIEdgeInsets)separatorInset;
- (void)setSeparatorInset:(UIEdgeInsets)inset;
- (UIView *)tableHeaderView;
- (void)setTableHeaderView:(UIView *)view;
- (UIView *)tableFooterView;
- (void)setTableFooterView:(UIView *)view;
- (UIView *)backgroundView;
- (void)setBackgroundView:(UIView *)view;
- (id)prefetchDataSource;
- (void)setPrefetchDataSource:(id)source;
- (id)dragDelegate;
- (void)setDragDelegate:(id)delegate;
- (id)dropDelegate;
- (void)setDropDelegate:(id)delegate;
- (UIRefreshControl *)refreshControl;
- (void)setRefreshControl:(UIRefreshControl *)control;
- (BOOL)allowsSelection;
- (void)setAllowsSelection:(BOOL)allows;
- (BOOL)allowsMultipleSelection;
- (void)setAllowsMultipleSelection:(BOOL)allows;
- (BOOL)allowsSelectionDuringEditing;
- (void)setAllowsSelectionDuringEditing:(BOOL)allows;
- (BOOL)allowsMultipleSelectionDuringEditing;
- (void)setAllowsMultipleSelectionDuringEditing:(BOOL)allows;
- (BOOL)dragInteractionEnabled;
- (void)setDragInteractionEnabled:(BOOL)enabled;
- (BOOL)cellLayoutMarginsFollowReadableWidth;
- (void)setCellLayoutMarginsFollowReadableWidth:(BOOL)follows;
- (BOOL)insetsContentViewsToSafeArea;
- (void)setInsetsContentViewsToSafeArea:(BOOL)insets;
- (double)estimatedRowHeight;
- (void)setEstimatedRowHeight:(double)height;
- (double)estimatedSectionHeaderHeight;
- (void)setEstimatedSectionHeaderHeight:(double)height;
- (double)estimatedSectionFooterHeight;
- (void)setEstimatedSectionFooterHeight:(double)height;
- (double)sectionHeaderHeight;
- (void)setSectionHeaderHeight:(double)height;
- (double)sectionFooterHeight;
- (void)setSectionFooterHeight:(double)height;
@end

enum {
    UITableViewCellEditingStyleNone = 0,
    UITableViewCellEditingStyleDelete = 1,
    UITableViewCellEditingStyleInsert = 2
};

enum {
    UITableViewRowAnimationFade = 0,
    UITableViewRowAnimationRight = 1,
    UITableViewRowAnimationLeft = 2,
    UITableViewRowAnimationTop = 3,
    UITableViewRowAnimationBottom = 4,
    UITableViewRowAnimationNone = 5,
    UITableViewRowAnimationMiddle = 6,
    UITableViewRowAnimationAutomatic = 100
};

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
id UICollectionElementKindSectionHeader = @"UICollectionElementKindSectionHeader";
id UICollectionElementKindSectionFooter = @"UICollectionElementKindSectionFooter";

@interface UICollectionViewLayout : NSObject
@end

@interface UICollectionViewFlowLayout : UICollectionViewLayout {
@public
    CGSize _itemSize;
    double _minimumInteritemSpacing;
    double _minimumLineSpacing;
    UIEdgeInsets _sectionInset;
    long _scrollDirection;
    CGSize _headerReferenceSize;
    CGSize _footerReferenceSize;
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
- (CGSize)headerReferenceSize;
- (void)setHeaderReferenceSize:(CGSize)size;
- (CGSize)footerReferenceSize;
- (void)setFooterReferenceSize:(CGSize)size;
@end

@interface UICollectionReusableView : UIView {
@public
    id _reuseIdentifier;
}
- (id)reuseIdentifier;
- (void)prepareForReuse;
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
    id _supplementaryClasses;
    id _supplementaryViews;
    long _selectedItem;
    long _selectedSection;
    id _prefetchDataSource;
    id _dragDelegate;
    id _dropDelegate;
    id _backgroundView;
    BOOL _allowsSelection;
    BOOL _allowsMultipleSelection;
    BOOL _dragInteractionEnabled;
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
- (void)registerClass:(Class)viewClass
    forSupplementaryViewOfKind:(id)kind
           withReuseIdentifier:(id)identifier;
- (id)dequeueReusableSupplementaryViewOfKind:(id)kind
                         withReuseIdentifier:(id)identifier
                                forIndexPath:(NSIndexPath *)indexPath;
- (void)reloadData;
- (void)handleTapAtPoint:(CGPoint)point;
- (id)prefetchDataSource;
- (void)setPrefetchDataSource:(id)source;
- (id)dragDelegate;
- (void)setDragDelegate:(id)delegate;
- (id)dropDelegate;
- (void)setDropDelegate:(id)delegate;
- (UIView *)backgroundView;
- (void)setBackgroundView:(UIView *)view;
- (BOOL)allowsSelection;
- (void)setAllowsSelection:(BOOL)allows;
- (BOOL)allowsMultipleSelection;
- (void)setAllowsMultipleSelection:(BOOL)allows;
- (BOOL)dragInteractionEnabled;
- (void)setDragInteractionEnabled:(BOOL)enabled;
- (NSArray *)visibleCells;
- (NSArray *)indexPathsForVisibleItems;
- (long)numberOfSections;
- (long)numberOfItemsInSection:(long)section;
@end

enum {
    UIWindowLevelNormal = 0,
    UIWindowLevelStatusBar = 1000,
    UIWindowLevelAlert = 2000
};

@interface UIWindow : UIView {
@public
    UIViewController *_rootViewController;
    double _windowLevel;
    id _windowScene;
    UIScrollView *_dragScroll;
    CGPoint _dragStartContent;
    CGPoint _dragStartPoint;
    CGPoint _dragVelocity;
    CGPoint _lastMovePoint;
    double _dragStartTime;
    double _lastMoveTime;
    BOOL _dragMoved;
    UIView *_touchHit;
    UIPanGestureRecognizer *_activePan;
    UIScreenEdgePanGestureRecognizer *_edgePan;
    BOOL _edgePanPending;
    CGPoint _panVelocity;
    UITouch *_touch;
    UIGestureRecognizer *_longPress;
    CGPoint _pressStartPoint;
    double _pressStartTime;
    id _twoFingerTargets[8];
    int _twoFingerTargetCount;
    double _pinchStartDistance;
    double _pinchStartAngle;
    double _pinchLastDistance;
    double _pinchLastAngle;
    double _pinchLastTime;
    BOOL _pinchRotationOnly;
    UIScrollView *_pinchScroll;
    NSMutableDictionary *_multiTouches;
    UIView *_contextHit;
    CGPoint _contextStartPoint;
    double _contextStartTime;
    BOOL _contextCandidate;
}
- (id)initWithWindowScene:(UIWindowScene *)scene;
- (UIWindowScene *)windowScene;
- (double)windowLevel;
- (void)setWindowLevel:(double)level;
- (void)setRootViewController:(UIViewController *)controller;
- (UIViewController *)rootViewController;
- (void)dispatchTapX:(int)x y:(int)y;
- (void)dispatchTouchDownX:(int)x y:(int)y;
- (void)dispatchTouchMoveX:(int)x y:(int)y;
- (void)dispatchTouchUpX:(int)x y:(int)y;
- (int)tickGestureRecognizers;
- (void)beginTwoFingerX1:(double)x1 y1:(double)y1 x2:(double)x2 y2:(double)y2
           rotationOnly:(BOOL)rotationOnly;
- (void)moveTwoFingerX1:(double)x1 y1:(double)y1 x2:(double)x2 y2:(double)y2;
- (void)endTwoFingerX1:(double)x1 y1:(double)y1 x2:(double)x2 y2:(double)y2;
- (void)beginMultiTouch:(int)ident atPoint:(CGPoint)point;
- (void)moveMultiTouch:(int)ident toPoint:(CGPoint)point;
- (void)endMultiTouch:(int)ident atPoint:(CGPoint)point cancelled:(BOOL)cancelled;
- (void)makeKeyAndVisible;
- (void)makeKeyWindow;
- (BOOL)isKeyWindow;
+ (UIWindow *)keyWindow;
@end

enum {
    UIApplicationStateActive = 0,
    UIApplicationStateInactive = 1,
    UIApplicationStateBackground = 2
};

enum {
    UIStatusBarStyleDefault = 0,
    UIStatusBarStyleLightContent = 1,
    UIStatusBarStyleDarkContent = 3
};

@interface UIApplication : UIResponder {
@public
    id _delegate;
    long _state;
    long _iconBadgeNumber;
    BOOL _idleTimerDisabled;
    id _backgroundTasks;
    unsigned long _nextBackgroundTask;
    double _backgroundTaskDeadline;
}
+ (UIApplication *)sharedApplication;
- (void)setDelegate:(id)delegate;
- (id)delegate;
- (long)applicationState;
- (long)statusBarStyle;
- (void)setStatusBarStyle:(long)style animated:(BOOL)animated;
- (BOOL)isStatusBarHidden;
- (void)setStatusBarHidden:(BOOL)hidden animated:(BOOL)animated;
- (double)backgroundTimeRemaining;
- (unsigned long)beginBackgroundTaskWithExpirationHandler:(void (^)(void))handler;
- (void)endBackgroundTask:(unsigned long)task;
- (BOOL)canOpenURL:(id)url;
- (BOOL)openURL:(id)url;
- (void)openURL:(id)url options:(id)options
    completionHandler:(void (^)(BOOL success))completion;
- (BOOL)isIdleTimerDisabled;
- (void)setIdleTimerDisabled:(BOOL)disabled;
- (void)registerForRemoteNotifications;
- (void)unregisterForRemoteNotifications;
- (BOOL)isRegisteredForRemoteNotifications;
- (NSArray *)windows;
- (UIWindow *)keyWindow;
- (NSArray *)connectedScenes;
@end

/* The system pasteboard lives in the device's shared resources directory so
 * every guest process reads and writes the same contents. */
@interface UIPasteboard : NSObject {
@public
    id _items;
    long _changeCount;
}
extern id UIPasteboardTypeListString;
extern id UIPasteboardTypeListImage;
extern id UIPasteboardTypeListURL;
extern id UIPasteboardTypeListColor;

+ (UIPasteboard *)generalPasteboard;
- (id)string;
- (void)setString:(id)string;
- (BOOL)hasStrings;
- (id)strings;
- (void)setStrings:(id)strings;
- (id)image;
- (void)setImage:(id)image;
- (id)images;
- (void)setImages:(id)images;
- (BOOL)hasImages;
- (id)URL;
- (void)setURL:(id)url;
- (id)URLs;
- (void)setURLs:(id)urls;
- (id)color;
- (void)setColor:(id)color;
- (id)colors;
- (void)setColors:(id)colors;
- (id)types;
- (BOOL)containsPasteboardTypes:(id)types;
- (id)items;
- (void)setItems:(id)items;
- (long)changeCount;
- (id)dataForPasteboardType:(id)type;
- (void)setData:(id)data forPasteboardType:(id)type;
- (long)numberOfItems;
@end

@interface UIMenuItem : NSObject {
@public
    id _title;
    SEL _action;
}
- (id)initWithTitle:(id)title action:(SEL)action;
- (id)title;
- (SEL)action;
@end

@interface UIMenuController : NSObject {
@public
    BOOL _menuVisible;
    CGRect _targetRect;
    UIView *_targetView;
    NSArray *_items;
}
+ (UIMenuController *)sharedMenuController;
- (void)setMenuItems:(NSArray *)items;
- (NSArray *)menuItems;
- (void)setTargetRect:(CGRect)rect inView:(UIView *)view;
- (void)setMenuVisible:(BOOL)visible;
- (void)setMenuVisible:(BOOL)visible animated:(BOOL)animated;
- (BOOL)isMenuVisible;
@end

@class UISceneSession;

@interface UIScene : NSObject {
@public
    id _delegate;
    id _session;
    long _activationState;
}
- (void)setDelegate:(id)delegate;
- (id)delegate;
- (UISceneSession *)session;
- (long)activationState;
@end

@interface UIWindowScene : UIScene {
@public
    id _windows;
}
- (NSArray *)windows;
- (UIWindow *)keyWindow;
- (UIScreen *)screen;
- (long)interfaceOrientation;
@end

@interface UISceneSession : NSObject {
@public
    id _persistentIdentifier;
    id _role;
    id _configuration;
}
- (id)persistentIdentifier;
- (id)role;
- (id)configuration;
- (void)setConfiguration:(id)configuration;
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
static CGAffineTransform current_transform(UIView *view);
static int layer_animated_position(CALayer *layer, CGPoint base,
                                   CGPoint *out);
static CGPoint view_untransform_point(UIView *view, CGPoint point);
static double layer_key_value(CALayer *layer, const char *key, double base);

/* CAAnimationDelegate callbacks are queued when an animation is added and
 * fired from the run-loop animation tick, so a delegate sees start before
 * the first animated frame and stop once the duration has elapsed. */
#define MAX_ANIM_DELEGATES 32
struct anim_delegate_event {
    int used;
    id delegate;
    id animation;
    CALayer *layer;
    id key;
    double startDue;
    double stopDue;
    int started;
    int infinite;
};
static struct anim_delegate_event g_animDelegates[MAX_ANIM_DELEGATES];

static void anim_delegate_call_start(id delegate, id animation)
{
    if (delegate && [delegate respondsToSelector:@selector(animationDidStart:)])
        [delegate animationDidStart:(CAAnimation *)animation];
}

static void anim_delegate_call_stop(id delegate, id animation, BOOL finished)
{
    if (delegate && [delegate respondsToSelector:
        @selector(animationDidStop:finished:)])
        [delegate animationDidStop:(CAAnimation *)animation
                          finished:finished];
}

static void anim_delegate_cancel_key(CALayer *layer, id key)
{
    const char *wanted = key ? iosim_string_cstr(key) : 0;
    if (!wanted)
        return;
    unsigned long wlen = strlen(wanted);
    for (int i = 0; i < MAX_ANIM_DELEGATES; i++)
    {
        struct anim_delegate_event *event = &g_animDelegates[i];
        if (!event->used || event->layer != layer || !event->key)
            continue;
        const char *held = iosim_string_cstr(event->key);
        if (!held)
            continue;
        int match = strcmp(held, wanted) == 0 ||
                    (strncmp(held, wanted, wlen) == 0 && held[wlen] == ':');
        if (!match)
            continue;
        if (event->started)
            anim_delegate_call_stop(event->delegate, event->animation, NO);
        memset(event, 0, sizeof(*event));
    }
}

static void anim_delegate_add(CALayer *layer, CAAnimation *animation, id key,
                              double delay)
{
    if (!animation->_delegate)
        return;
    int slot = -1;
    for (int i = 0; i < MAX_ANIM_DELEGATES && slot < 0; i++)
        if (!g_animDelegates[i].used)
            slot = i;
    if (slot < 0)
        return;
    struct anim_delegate_event *event = &g_animDelegates[slot];
    memset(event, 0, sizeof(*event));
    event->used = 1;
    event->delegate = animation->_delegate;
    event->animation = animation;
    event->layer = layer;
    event->key = key;
    event->startDue = iosim_now() + delay;
    double repeat = animation->_repeatCount;
    event->infinite = repeat < 0;
    double span = animation->_duration > 0 ? animation->_duration : 0.25;
    event->stopDue = event->startDue + span * (repeat > 1 ? repeat : 1);
}

static int anim_delegate_tick(double now)
{
    int fired = 0;
    for (int i = 0; i < MAX_ANIM_DELEGATES; i++)
    {
        struct anim_delegate_event *event = &g_animDelegates[i];
        if (!event->used)
            continue;
        if (!event->started && now >= event->startDue)
        {
            event->started = 1;
            anim_delegate_call_start(event->delegate, event->animation);
            fired = 1;
        }
        if (event->started && !event->infinite && now >= event->stopDue)
        {
            id delegate = event->delegate;
            id animation = event->animation;
            memset(event, 0, sizeof(*event));
            anim_delegate_call_stop(delegate, animation, YES);
            fired = 1;
        }
    }
    return fired;
}

static int anim_delegates_pending(void)
{
    for (int i = 0; i < MAX_ANIM_DELEGATES; i++)
        if (g_animDelegates[i].used)
            return 1;
    return 0;
}

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
        _anchorPoint = CGPointMake(0.5, 0.5);
        _transform = CATransform3DIdentityValue();
        _contentsRect = CGRectMake(0, 0, 1, 1);
        _contentsGravity = @"resize";
        _contentsScale = 1.0;
        _cornerCurve = @"circular";
        _maskedCorners = 15u;
        _speed = 1.0;
    }
    return self;
}
- (CGRect)contentsRect { return _contentsRect; }
- (void)setContentsRect:(CGRect)rect { _contentsRect = rect; }
- (id)contentsGravity { return _contentsGravity; }
- (void)setContentsGravity:(id)gravity { _contentsGravity = gravity; }
- (double)contentsScale { return _contentsScale; }
- (void)setContentsScale:(double)scale { _contentsScale = scale; }
- (id)shadowPath { return _shadowPath; }
- (void)setShadowPath:(id)path { _shadowPath = path; }
- (BOOL)shouldRasterize { return _shouldRasterize; }
- (void)setShouldRasterize:(BOOL)rasterize { _shouldRasterize = rasterize; }
- (double)rasterizationScale { return _rasterizationScale; }
- (void)setRasterizationScale:(double)scale { _rasterizationScale = scale; }
- (id)cornerCurve { return _cornerCurve; }
- (void)setCornerCurve:(id)curve { _cornerCurve = curve; }
- (unsigned long)maskedCorners { return _maskedCorners; }
- (void)setMaskedCorners:(unsigned long)corners { _maskedCorners = corners; }
- (double)speed { return _speed; }
- (void)setSpeed:(double)speed { _speed = speed; }
- (double)timeOffset { return _timeOffset; }
- (void)setTimeOffset:(double)offset { _timeOffset = offset; }
- (double)beginTime { return _beginTime; }
- (void)setBeginTime:(double)time { _beginTime = time; }
- (id)name { return _name; }
- (void)setName:(id)name { _name = name; }
- (double)cornerRadius { return _cornerRadius; }
- (void)setCornerRadius:(double)radius { _cornerRadius = radius; }
- (void)setMasksToBounds:(BOOL)masks { _masksToBounds = masks; }
- (BOOL)masksToBounds { return _masksToBounds; }
- (void)setMask:(CALayer *)mask { _mask = mask; }
- (CALayer *)mask { return (CALayer *)_mask; }
- (void)setTransform:(CATransform3D)transform { _transform = transform; }
- (CATransform3D)transform { return _transform; }
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
- (CGRect)bounds
{
    return CGRectMake(0, 0, _frame.size.width, _frame.size.height);
}
- (CGPoint)position
{
    return CGPointMake(_frame.origin.x + _anchorPoint.x * _frame.size.width,
                       _frame.origin.y + _anchorPoint.y * _frame.size.height);
}
- (void)setPosition:(CGPoint)position
{
    _frame.origin.x = position.x - _anchorPoint.x * _frame.size.width;
    _frame.origin.y = position.y - _anchorPoint.y * _frame.size.height;
}
- (void)setBounds:(CGRect)bounds
{
    CGPoint position = [self position];
    _frame.size = bounds.size;
    [self setPosition:position];
}
- (CGPoint)anchorPoint { return _anchorPoint; }
- (void)setAnchorPoint:(CGPoint)anchorPoint
{
    CGPoint position = [self position];
    _anchorPoint = anchorPoint;
    [self setPosition:position];
}
- (void)setContents:(id)contents { _contents = contents; }
- (id)contents { return _contents; }
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
    if ([anim isKindOfClass:[CAAnimationGroup class]])
    {
        CAAnimationGroup *group = (CAAnimationGroup *)anim;
        NSArray *children = group->_animations;
        unsigned long n = children ? [children count] : 0;
        for (unsigned long i = 0; i < n; i++)
        {
            CAAnimation *child = (CAAnimation *)[children objectAtIndex:i];
            if (!child)
                continue;
            if (child->_duration <= 0.0)
                child->_duration = group->_duration;
            if (!child->_timingFunction)
                child->_timingFunction = group->_timingFunction;
            if (child->_repeatCount == 0.0)
                child->_repeatCount = group->_repeatCount;
            id childKey =
                key ? [NSString stringWithFormat:@"%@:%lu", key, i] : nil;
            [self addAnimation:child forKey:childKey];
        }
        return;
    }
    if (key)
        anim_delegate_cancel_key(self, key);
    BOOL keyframe = [anim isKindOfClass:[CAKeyframeAnimation class]];
    BOOL spring = [anim isKindOfClass:[CASpringAnimation class]];
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
    entry->calcMode = keyframe
                          ? ((CAKeyframeAnimation *)anim)->_calculationMode
                          : nil;
    entry->timingFunctions =
        keyframe ? ((CAKeyframeAnimation *)anim)->_timingFunctions : nil;
    entry->path = keyframe ? ((CAKeyframeAnimation *)anim)->_path : 0;
    if (spring)
    {
        CASpringAnimation *sa = (CASpringAnimation *)anim;
        entry->spring = 1;
        entry->mass = sa->_mass > 0 ? sa->_mass : 1.0;
        entry->stiffness = sa->_stiffness > 0 ? sa->_stiffness : 100.0;
        entry->damping = sa->_damping > 0 ? sa->_damping : 10.0;
        entry->initialVelocity = sa->_initialVelocity;
    }
    entry->timingFunction = anim->_timingFunction;
    entry->key = key;
    entry->animation = anim;
    entry->duration = anim->_duration;
    entry->repeatCount = anim->_repeatCount;
    entry->start = iosim_now();
    entry->delay = anim->_beginTime > 0 ? anim->_beginTime - entry->start : 0;
    if (entry->delay < 0)
        entry->delay = 0;
    entry->speed = anim->_speed > 0 ? anim->_speed : 1.0;
    entry->timeOffset = anim->_timeOffset;
    entry->autoreverses = anim->_autoreverses;
    entry->fillMode = anim->_fillMode;
    entry->seq = ++_animSeq;
    entry->infinite = anim->_repeatCount < 0;
    if (entry->duration <= 0)
        entry->duration = 0.25;
    animation_mark_active(entry->delay + entry->duration, entry->repeatCount);
    anim_delegate_add(self, anim, key, entry->delay);
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
        if (!held)
            continue;
        /* Group children are keyed `key:index`, so removing a group clears
         * every expanded child as well. */
        unsigned long wlen = strlen(wanted);
        int match = strcmp(held, wanted) == 0 ||
                    (strncmp(held, wanted, wlen) == 0 && held[wlen] == ':');
        if (!match)
            continue;
        anim_delegate_cancel_key(self, key);
        if (entry->infinite)
            animation_unmark_infinite();
        memset(entry, 0, sizeof(*entry));
    }
}
- (void)removeAllAnimations
{
    for (int i = 0; i < LAYER_ANIM_SLOTS; i++)
    {
        struct layer_anim *entry = &_anims[i];
        if (!entry->used)
            continue;
        if (entry->key)
            anim_delegate_cancel_key(self, entry->key);
        if (entry->infinite)
            animation_unmark_infinite();
        memset(entry, 0, sizeof(*entry));
    }
}
- (NSArray *)animationKeys
{
    NSMutableArray *keys = [NSMutableArray array];
    for (int i = 0; i < LAYER_ANIM_SLOTS; i++)
        if (_anims[i].used && _anims[i].key)
            [keys addObject:_anims[i].key];
    return keys;
}
- (CAAnimation *)animationForKey:(id)key
{
    if (!key)
        return nil;
    const char *wanted = iosim_string_cstr(key);
    for (int i = 0; i < LAYER_ANIM_SLOTS; i++)
    {
        struct layer_anim *entry = &_anims[i];
        if (!entry->used || !entry->key)
            continue;
        const char *held = iosim_string_cstr(entry->key);
        if (held && wanted && strcmp(held, wanted) == 0)
            return (CAAnimation *)entry->animation;
    }
    return nil;
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
    else
    {
        CGPoint base = CGPointMake(
            frame.origin.x + _anchorPoint.x * frame.size.width,
            frame.origin.y + _anchorPoint.y * frame.size.height);
        CGPoint position;
        if (layer_animated_position(self, base, &position))
        {
            frame.origin.x =
                position.x - _anchorPoint.x * frame.size.width;
            frame.origin.y =
                position.y - _anchorPoint.y * frame.size.height;
        }
    }
    presentation->_frame = frame;
    presentation->_opacity = layer_key_value(self, "opacity", opacity);
    presentation->_cornerRadius =
        layer_key_value(self, "cornerRadius", _cornerRadius);
    presentation->_backgroundColor = _backgroundColor;
    return presentation;
}
- (CALayer *)modelLayer { return self; }
- (CGPoint)convertPoint:(CGPoint)point fromLayer:(CALayer *)layer
{
    (void)layer;
    return point;
}
- (CGPoint)convertPoint:(CGPoint)point toLayer:(CALayer *)layer
{
    (void)layer;
    return point;
}
- (CGRect)convertRect:(CGRect)rect fromLayer:(CALayer *)layer
{
    (void)layer;
    return rect;
}
- (CGRect)convertRect:(CGRect)rect toLayer:(CALayer *)layer
{
    (void)layer;
    return rect;
}
- (double)convertTime:(double)time fromLayer:(CALayer *)layer
{
    (void)layer;
    return time;
}
- (double)convertTime:(double)time toLayer:(CALayer *)layer
{
    (void)layer;
    return time;
}
@end

@implementation CATransformLayer
@end

@implementation CAReplicatorLayer
- (id)init
{
    self = [super init];
    if (self)
    {
        _instanceCount = 1;
        _instanceTransform = CATransform3DIdentityValue();
    }
    return self;
}
- (long)instanceCount { return _instanceCount; }
- (void)setInstanceCount:(long)count { _instanceCount = count; }
- (double)instanceDelay { return _instanceDelay; }
- (void)setInstanceDelay:(double)delay { _instanceDelay = delay; }
- (CATransform3D)instanceTransform { return _instanceTransform; }
- (void)setInstanceTransform:(CATransform3D)transform
{
    _instanceTransform = transform;
}
- (id)instanceColor { return _instanceColor; }
- (void)setInstanceColor:(id)color { _instanceColor = color; }
- (float)instanceRedOffset { return _instanceRedOffset; }
- (void)setInstanceRedOffset:(float)offset { _instanceRedOffset = offset; }
- (float)instanceGreenOffset { return _instanceGreenOffset; }
- (void)setInstanceGreenOffset:(float)offset
{
    _instanceGreenOffset = offset;
}
- (float)instanceBlueOffset { return _instanceBlueOffset; }
- (void)setInstanceBlueOffset:(float)offset { _instanceBlueOffset = offset; }
- (float)instanceAlphaOffset { return _instanceAlphaOffset; }
- (void)setInstanceAlphaOffset:(float)offset
{
    _instanceAlphaOffset = offset;
}
- (BOOL)preservesDepth { return _preservesDepth; }
- (void)setPreservesDepth:(BOOL)value { _preservesDepth = value; }
@end

@implementation CAEmitterCell
- (id)init
{
    self = [super init];
    if (self)
    {
        _birthRate = 1.0f;
        _lifetime = 1.0f;
        _scale = 0.1f;
        _enabled = YES;
        _color = [UIColor whiteColor];
    }
    return self;
}
- (void)setContents:(id)contents { _contents = contents; }
- (id)contents { return _contents; }
- (void)setColor:(id)color { _color = color; }
- (id)color { return _color; }
- (void)setBirthRate:(float)rate { _birthRate = rate; }
- (float)birthRate { return _birthRate; }
- (void)setLifetime:(float)lifetime { _lifetime = lifetime; }
- (float)lifetime { return _lifetime; }
- (void)setVelocity:(float)velocity { _velocity = velocity; }
- (float)velocity { return _velocity; }
- (void)setVelocityRange:(float)range { _velocityRange = range; }
- (float)velocityRange { return _velocityRange; }
- (void)setEmissionRange:(float)range { _emissionRange = range; }
- (float)emissionRange { return _emissionRange; }
- (void)setScale:(float)scale { _scale = scale; }
- (float)scale { return _scale; }
- (void)setScaleRange:(float)range { _scaleRange = range; }
- (float)scaleRange { return _scaleRange; }
- (void)setSpin:(float)spin { _spin = spin; }
- (float)spin { return _spin; }
- (void)setSpinRange:(float)range { _spinRange = range; }
- (float)spinRange { return _spinRange; }
- (void)setAlphaSpeed:(float)speed { _alphaSpeed = speed; }
- (float)alphaSpeed { return _alphaSpeed; }
- (void)setAlphaRange:(float)range { _alphaRange = range; }
- (float)alphaRange { return _alphaRange; }
- (void)setRedSpeed:(float)speed { _redSpeed = speed; }
- (float)redSpeed { return _redSpeed; }
- (void)setGreenSpeed:(float)speed { _greenSpeed = speed; }
- (float)greenSpeed { return _greenSpeed; }
- (void)setBlueSpeed:(float)speed { _blueSpeed = speed; }
- (float)blueSpeed { return _blueSpeed; }
- (void)setRedRange:(float)range { _redRange = range; }
- (float)redRange { return _redRange; }
- (void)setGreenRange:(float)range { _greenRange = range; }
- (float)greenRange { return _greenRange; }
- (void)setBlueRange:(float)range { _blueRange = range; }
- (float)blueRange { return _blueRange; }
- (void)setXAcceleration:(float)acceleration { _xAcceleration = acceleration; }
- (float)xAcceleration { return _xAcceleration; }
- (void)setYAcceleration:(float)acceleration { _yAcceleration = acceleration; }
- (float)yAcceleration { return _yAcceleration; }
- (void)setEnabled:(BOOL)enabled { _enabled = enabled; }
- (BOOL)isEnabled { return _enabled; }
- (void)setName:(id)name { _name = name; }
- (id)name { return _name; }
@end

@implementation CAEmitterLayer
- (id)init
{
    self = [super init];
    if (self)
    {
        _birthRate = 1.0f;
        _lifetime = 1.0f;
        _emitterShape = @"point";
        _renderMode = @"unordered";
        _scale = 1.0f;
    }
    return self;
}
- (void)setEmitterCells:(NSArray *)cells { _emitterCells = cells; }
- (NSArray *)emitterCells { return _emitterCells; }
- (void)setBirthRate:(float)rate { _birthRate = rate; }
- (float)birthRate { return _birthRate; }
- (void)setLifetime:(float)lifetime { _lifetime = lifetime; }
- (float)lifetime { return _lifetime; }
- (void)setEmitterPosition:(CGPoint)position { _emitterPosition = position; }
- (CGPoint)emitterPosition { return _emitterPosition; }
- (void)setEmitterSize:(CGSize)size { _emitterSize = size; }
- (CGSize)emitterSize { return _emitterSize; }
- (void)setEmitterShape:(id)shape { _emitterShape = shape; }
- (id)emitterShape { return _emitterShape; }
- (void)setRenderMode:(id)mode { _renderMode = mode; }
- (id)renderMode { return _renderMode; }
- (void)setSeed:(unsigned)seed { _seed = seed; }
- (unsigned)seed { return _seed; }
- (void)setScale:(float)scale { _scale = scale; }
- (float)scale { return _scale; }
- (void)setVelocity:(float)velocity { _velocity = velocity; }
- (float)velocity { return _velocity; }
- (void)setSpin:(float)spin { _spin = spin; }
- (float)spin { return _spin; }
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
    if (strcmp(s, "linear") == 0)
    {
        f->_kind = 0;
        f->_cx1 = 0.0; f->_cy1 = 0.0; f->_cx2 = 1.0; f->_cy2 = 1.0;
    }
    else if (strcmp(s, "easeIn") == 0)
    {
        f->_kind = 1;
        f->_cx1 = 0.42; f->_cy1 = 0.0; f->_cx2 = 1.0; f->_cy2 = 1.0;
    }
    else if (strcmp(s, "easeOut") == 0)
    {
        f->_kind = 2;
        f->_cx1 = 0.0; f->_cy1 = 0.0; f->_cx2 = 0.58; f->_cy2 = 1.0;
    }
    else
    {
        f->_kind = 3;
        f->_cx1 = 0.42; f->_cy1 = 0.0; f->_cx2 = 0.58; f->_cy2 = 1.0;
    }
    return f;
}
+ (id)functionWithControlPoints:(float)c1x :(float)c1y :(float)c2x
                                :(float)c2y
{
    CAMediaTimingFunction *f = [[self alloc] init];
    f->_custom = 1;
    f->_cx1 = c1x;
    f->_cy1 = c1y;
    f->_cx2 = c2x;
    f->_cy2 = c2y;
    return f;
}
- (void)getControlPointAtIndex:(unsigned long)index values:(float *)values
{
    if (!values)
        return;
    double x = 0.0, y = 0.0;
    if (index == 1)
    {
        x = _cx1;
        y = _cy1;
    }
    else if (index == 2)
    {
        x = _cx2;
        y = _cy2;
    }
    else if (index == 3)
    {
        x = 1.0;
        y = 1.0;
    }
    values[0] = (float)x;
    values[1] = (float)y;
}
- (double)evaluate:(double)t
{
    if (t < 0) t = 0;
    if (t > 1) t = 1;
    if (_custom)
    {
        double cx1 = _cx1, cx2 = _cx2;
        if (cx1 < 0) cx1 = 0;
        if (cx1 > 1) cx1 = 1;
        if (cx2 < 0) cx2 = 0;
        if (cx2 > 1) cx2 = 1;
        double low = 0.0, high = 1.0;
        for (int i = 0; i < 30; i++)
        {
            double mid = (low + high) / 2.0;
            double x = 3.0 * (1.0 - mid) * (1.0 - mid) * mid * cx1 +
                       3.0 * (1.0 - mid) * mid * mid * cx2 +
                       mid * mid * mid;
            if (x < t)
                low = mid;
            else
                high = mid;
        }
        double u = (low + high) / 2.0;
        return 3.0 * (1.0 - u) * (1.0 - u) * u * _cy1 +
               3.0 * (1.0 - u) * u * u * _cy2 + u * u * u;
    }
    if (_kind == 1) return t * t;
    if (_kind == 2) return 1 - (1 - t) * (1 - t);
    if (_kind == 3) return t * t * (3 - 2 * t);
    return t;
}
@end

@implementation CAAnimation
- (id)init
{
    self = [super init];
    if (self)
    {
        _speed = 1.0;
        _removedOnCompletion = YES;
    }
    return self;
}
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
- (double)duration { return _duration; }
- (void)setRepeatCount:(double)count { _repeatCount = count; }
- (double)repeatCount { return _repeatCount; }
- (void)setTimingFunction:(id)function { _timingFunction = function; }
- (id)timingFunction { return _timingFunction; }
- (id)fromValue { return _fromValue; }
- (id)toValue { return _toValue; }
- (void)setBeginTime:(double)time { _beginTime = time; }
- (double)beginTime { return _beginTime; }
- (void)setSpeed:(double)speed { _speed = speed; }
- (double)speed { return _speed; }
- (void)setTimeOffset:(double)offset { _timeOffset = offset; }
- (double)timeOffset { return _timeOffset; }
- (void)setAutoreverses:(BOOL)autoreverses { _autoreverses = autoreverses; }
- (BOOL)autoreverses { return _autoreverses; }
- (void)setRemovedOnCompletion:(BOOL)removed { _removedOnCompletion = removed; }
- (BOOL)removedOnCompletion { return _removedOnCompletion; }
- (void)setFillMode:(id)fillMode { _fillMode = fillMode; }
- (id)fillMode { return _fillMode; }
- (void)setDelegate:(id)delegate { _delegate = delegate; }
- (id)delegate { return _delegate; }
@end

double CACurrentMediaTime(void)
{
    return iosim_now();
}

@implementation CABasicAnimation
@end

@implementation CAKeyframeAnimation
- (void)setValues:(id)values { _values = values; }
- (void)setKeyTimes:(id)keyTimes { _keyTimes = keyTimes; }
- (void)setCalculationMode:(id)mode { _calculationMode = mode; }
- (id)calculationMode
{
    return _calculationMode ? _calculationMode : @"linear";
}
- (void)setTimingFunctions:(id)functions
{
    _timingFunctions = functions;
}
- (id)timingFunctions { return _timingFunctions; }
- (void)setPath:(CGPathRef)path { _path = path; }
- (CGPathRef)path { return _path; }
@end

@implementation CASpringAnimation
- (void)setMass:(double)mass { _mass = mass; }
- (void)setStiffness:(double)stiffness { _stiffness = stiffness; }
- (void)setDamping:(double)damping { _damping = damping; }
- (void)setInitialVelocity:(double)velocity { _initialVelocity = velocity; }
- (double)settlingDuration
{
    double m = _mass > 0 ? _mass : 1.0;
    double k = _stiffness > 0 ? _stiffness : 100.0;
    double c = _damping > 0 ? _damping : 10.0;
    double w0 = __builtin_sqrt(k / m);
    double zeta = c / (2.0 * __builtin_sqrt(k * m));
    if (w0 <= 0)
        return 0.25;
    if (zeta <= 0)
        return 4.0;
    return 4.0 / (zeta * w0);
}
@end

@implementation CAAnimationGroup
- (void)setAnimations:(NSArray *)animations { _animations = animations; }
- (NSArray *)animations { return _animations; }
@end

@implementation CATransition
- (id)type { return _type; }
- (void)setType:(id)type { _type = type; }
- (id)subtype { return _subtype; }
- (void)setSubtype:(id)subtype { _subtype = subtype; }
- (float)startProgress { return _startProgress; }
- (void)setStartProgress:(float)progress { _startProgress = progress; }
- (float)endProgress { return _endProgress; }
- (void)setEndProgress:(float)progress { _endProgress = progress; }
- (id)filter { return _filter; }
- (void)setFilter:(id)filter { _filter = filter; }
@end

/* CATransaction groups layer changes and carries the animation duration and
 * a completion block. The renderer has no implicit animations, so a
 * transaction only needs to track nesting and run the block when the
 * outermost commit lands. */
static int g_transactionDepth;
static double g_transactionDuration = 0.25;
static BOOL g_transactionDisable;
static id g_transactionCompletion;

@implementation CATransaction
+ (void)begin { g_transactionDepth++; }
+ (void)commit
{
    if (g_transactionDepth > 0)
        g_transactionDepth--;
    if (g_transactionDepth > 0)
        return;
    id block = g_transactionCompletion;
    g_transactionCompletion = nil;
    if (block)
    {
        ((void (^)(void))block)();
    }
}
+ (void)flush { }
+ (void)setAnimationDuration:(double)duration
{
    if (duration > 0)
        g_transactionDuration = duration;
}
+ (double)animationDuration { return g_transactionDuration; }
+ (void)setDisableActions:(BOOL)disable { g_transactionDisable = disable; }
+ (BOOL)disableActions { return g_transactionDisable; }
+ (void)setCompletionBlock:(void (^)(void))block
{
    g_transactionCompletion = block ? (id)_Block_copy(block) : nil;
}
+ (void (^)(void))completionBlock
{
    return (void (^)(void))g_transactionCompletion;
}
+ (void)lock { }
+ (void)unlock { }
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
        link->_preferredFramesPerSecond = 0;
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
- (long)preferredFramesPerSecond
{
    return _preferredFramesPerSecond;
}
- (void)setPreferredFramesPerSecond:(long)rate
{
    if (rate < 0)
        rate = 0;
    if (rate > 60)
        rate = 60;
    _preferredFramesPerSecond = rate;
    _duration = rate > 0 ? 1.0 / rate : 1.0 / 60.0;
}
@end

/* ------------------------------------------------------------ appearance */

/* The appearance is device-wide: SpringBoard owns
 * Library/SpringBoard/appearance.txt and every app reads it. g_ui_style
 * caches the last value this process resolved. */
static int g_ui_style = -1;

static int ui_appearance_read_file(void)
{
    const char *shared = getenv("SIMULATOR_SHARED_RESOURCES_DIRECTORY");
    if (!shared || !*shared)
        return 0;
    char path[1100];
    snprintf(path, sizeof(path), "%s/Library/SpringBoard/appearance.txt",
             shared);
    unsigned char *bytes = 0;
    unsigned long length = 0;
    if (iosim_fs_read(path, &bytes, &length) != 0 || !bytes)
        return 0;
    int dark = length > 0 && (bytes[0] == 'd' || bytes[0] == 'D');
    free(bytes);
    return dark;
}

static void ui_appearance_write_file(int dark)
{
    const char *shared = getenv("SIMULATOR_SHARED_RESOURCES_DIRECTORY");
    if (!shared || !*shared)
        return;
    char dir[1000];
    snprintf(dir, sizeof(dir), "%s/Library/SpringBoard", shared);
    iosim_fs_mkdir(dir, 1);
    char path[1100];
    snprintf(path, sizeof(path), "%s/appearance.txt", dir);
    const char *text = dark ? "dark\n" : "light\n";
    iosim_fs_write(path, text, dark ? 5 : 6);
}

static int ui_style_current(void)
{
    if (g_ui_style >= 0)
        return g_ui_style;
    const char *env = getenv("IOSIM_USER_INTERFACE_STYLE");
    if (env && *env)
        g_ui_style = (env[0] == 'd' || env[0] == 'D') ? 1 : 0;
    else
        g_ui_style = ui_appearance_read_file();
    return g_ui_style;
}

static UITraitCollection *ui_trait_for_style(int dark)
{
    return [UITraitCollection
        traitCollectionWithUserInterfaceStyle:
            (dark ? UIUserInterfaceStyleDark : UIUserInterfaceStyleLight)];
}

NSString *const UITraitCollectionDidChangeNotification =
    @"UITraitCollectionDidChangeNotification";

/* ---------------------------------------------------------------- colors */

@implementation UITraitCollection
+ (UITraitCollection *)traitCollectionWithUserInterfaceStyle:(long)style
{
    UITraitCollection *traits = [[self alloc] init];
    traits->_userInterfaceStyle = style;
    traits->_displayScale = 3.0;
    traits->_horizontalSizeClass = UIUserInterfaceSizeClassCompact;
    traits->_verticalSizeClass = UIUserInterfaceSizeClassRegular;
    return traits;
}
- (long)userInterfaceStyle { return _userInterfaceStyle; }
- (double)displayScale { return _displayScale; }
- (long)horizontalSizeClass { return _horizontalSizeClass; }
- (long)verticalSizeClass { return _verticalSizeClass; }
- (BOOL)containsTraitsInCollection:(UITraitCollection *)other
{
    if (!other)
        return NO;
    if (other->_userInterfaceStyle &&
        other->_userInterfaceStyle != _userInterfaceStyle)
        return NO;
    if (other->_displayScale > 0 &&
        other->_displayScale != _displayScale)
        return NO;
    if (other->_horizontalSizeClass &&
        other->_horizontalSizeClass != _horizontalSizeClass)
        return NO;
    if (other->_verticalSizeClass &&
        other->_verticalSizeClass != _verticalSizeClass)
        return NO;
    return YES;
}
@end

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
+ (UIColor *)colorWithHue:(double)hue saturation:(double)saturation
               brightness:(double)brightness alpha:(double)alpha
{
    if (saturation <= 0)
        return [self colorWithWhite:brightness alpha:alpha];
    double h = hue - (double)(long)hue;
    if (h < 0)
        h += 1;
    h *= 6;
    int sector = (int)h;
    double f = h - sector;
    double p = brightness * (1 - saturation);
    double q = brightness * (1 - f * saturation);
    double t = brightness * (1 - (1 - f) * saturation);
    double r = 0, g = 0, b = 0;
    switch (sector % 6)
    {
    case 0: r = brightness; g = t; b = p; break;
    case 1: r = q; g = brightness; b = p; break;
    case 2: r = p; g = brightness; b = t; break;
    case 3: r = p; g = q; b = brightness; break;
    case 4: r = t; g = p; b = brightness; break;
    default: r = brightness; g = p; b = q; break;
    }
    return [self colorWithRed:r green:g blue:b alpha:alpha];
}
+ (UIColor *)colorWithDisplayP3Red:(double)r green:(double)g blue:(double)b
                             alpha:(double)a
{
    UIColor *color = [self colorWithRed:r green:g blue:b alpha:a];
    color->_displayP3 = YES;
    return color;
}
- (UIColor *)colorWithAlphaComponent:(double)alpha
{
    UIColor *color = [[self class] colorWithRed:_r green:_g blue:_b
                                          alpha:alpha];
    color->_displayP3 = _displayP3;
    return color;
}
+ (UIColor *)ui_colorWithLightRed:(double)lr lightGreen:(double)lg
                        lightBlue:(double)lb lightAlpha:(double)la
                          darkRed:(double)dr darkGreen:(double)dg
                         darkBlue:(double)db darkAlpha:(double)da
{
    UIColor *c = [[self alloc] init];
    c->_r = lr;
    c->_g = lg;
    c->_b = lb;
    c->_a = la;
    c->_dark_r = dr;
    c->_dark_g = dg;
    c->_dark_b = db;
    c->_dark_a = da;
    c->_dynamic = YES;
    return c;
}
+ (UIColor *)colorWithDynamicProvider:
    (id (^)(UITraitCollection *traits))provider
{
    UIColor *c = [[self alloc] init];
    c->_dynamic = NO;
    c->_provider = provider ? _Block_copy(provider) : 0;
    return c;
}
+ (UIColor *)whiteColor { return [self colorWithRed:1 green:1 blue:1 alpha:1]; }
+ (UIColor *)blackColor { return [self colorWithRed:0 green:0 blue:0 alpha:1]; }
+ (UIColor *)clearColor { return [self colorWithRed:0 green:0 blue:0 alpha:0]; }
+ (UIColor *)colorWithWhite:(double)white alpha:(double)alpha
{
    return [self colorWithRed:white green:white blue:white alpha:alpha];
}
- (BOOL)getRed:(double *)red green:(double *)green blue:(double *)blue
         alpha:(double *)alpha
{
    if (red) *red = _r;
    if (green) *green = _g;
    if (blue) *blue = _b;
    if (alpha) *alpha = _a;
    return YES;
}
- (BOOL)getWhite:(double *)white alpha:(double *)alpha
{
    if (_r != _g || _r != _b)
        return NO;
    if (white) *white = _r;
    if (alpha) *alpha = _a;
    return YES;
}
- (BOOL)getHue:(double *)hue saturation:(double *)saturation
    brightness:(double *)brightness alpha:(double *)alpha
{
    double maximum = _r > _g ? (_r > _b ? _r : _b) : (_g > _b ? _g : _b);
    double minimum = _r < _g ? (_r < _b ? _r : _b) : (_g < _b ? _g : _b);
    double delta = maximum - minimum;
    double h = 0;
    if (delta > 0)
    {
        if (maximum == _r)
            h = (_g - _b) / delta;
        else if (maximum == _g)
            h = 2 + (_b - _r) / delta;
        else
            h = 4 + (_r - _g) / delta;
        h /= 6;
        if (h < 0)
            h += 1;
    }
    if (hue) *hue = h;
    if (saturation) *saturation = maximum > 0 ? delta / maximum : 0;
    if (brightness) *brightness = maximum;
    if (alpha) *alpha = _a;
    return YES;
}
+ (UIColor *)redColor { return [self colorWithRed:1 green:0 blue:0 alpha:1]; }
+ (UIColor *)greenColor { return [self colorWithRed:0 green:1 blue:0 alpha:1]; }
+ (UIColor *)blueColor { return [self colorWithRed:0 green:0 blue:1 alpha:1]; }
+ (UIColor *)orangeColor
{
    return [self colorWithRed:1 green:0.5 blue:0 alpha:1];
}
+ (UIColor *)yellowColor { return [self colorWithRed:1 green:1 blue:0 alpha:1]; }
+ (UIColor *)purpleColor
{
    return [self colorWithRed:0.5 green:0 blue:0.5 alpha:1];
}
+ (UIColor *)brownColor
{
    return [self colorWithRed:0.6 green:0.4 blue:0.2 alpha:1];
}
+ (UIColor *)cyanColor { return [self colorWithRed:0 green:1 blue:1 alpha:1]; }
+ (UIColor *)magentaColor { return [self colorWithRed:1 green:0 blue:1 alpha:1]; }
+ (UIColor *)grayColor { return [self colorWithRed:0.5 green:0.5 blue:0.5 alpha:1]; }
+ (UIColor *)darkGrayColor
{
    return [self colorWithRed:0.3333 green:0.3333 blue:0.3333 alpha:1];
}
+ (UIColor *)lightGrayColor
{
    return [self colorWithRed:0.6667 green:0.6667 blue:0.6667 alpha:1];
}
+ (UIColor *)systemBlueColor
{
    return [self ui_colorWithLightRed:0.0 lightGreen:0.4784 lightBlue:1.0
                           lightAlpha:1.0 darkRed:0.0392 darkGreen:0.5176
                             darkBlue:1.0 darkAlpha:1.0];
}
+ (UIColor *)tintColor { return [self systemBlueColor]; }
+ (UIColor *)systemRedColor
{
    return [self ui_colorWithLightRed:1.0 lightGreen:0.2314 lightBlue:0.1882
                           lightAlpha:1.0 darkRed:1.0 darkGreen:0.2706
                             darkBlue:0.2275 darkAlpha:1.0];
}
+ (UIColor *)systemGreenColor
{
    return [self ui_colorWithLightRed:0.2039 lightGreen:0.7804 lightBlue:0.3490
                           lightAlpha:1.0 darkRed:0.1882 darkGreen:0.8196
                             darkBlue:0.3451 darkAlpha:1.0];
}
+ (UIColor *)systemOrangeColor
{
    return [self ui_colorWithLightRed:1.0 lightGreen:0.5843 lightBlue:0.0
                           lightAlpha:1.0 darkRed:1.0 darkGreen:0.6235
                             darkBlue:0.0392 darkAlpha:1.0];
}
+ (UIColor *)systemYellowColor
{
    return [self ui_colorWithLightRed:1.0 lightGreen:0.8 lightBlue:0.0
                           lightAlpha:1.0 darkRed:1.0 darkGreen:0.8392
                             darkBlue:0.0392 darkAlpha:1.0];
}
+ (UIColor *)systemPurpleColor
{
    return [self ui_colorWithLightRed:0.6863 lightGreen:0.3216 lightBlue:0.8706
                           lightAlpha:1.0 darkRed:0.7490 darkGreen:0.3529
                             darkBlue:0.9490 darkAlpha:1.0];
}
+ (UIColor *)systemPinkColor
{
    return [self ui_colorWithLightRed:1.0 lightGreen:0.1765 lightBlue:0.3333
                           lightAlpha:1.0 darkRed:1.0 darkGreen:0.2157
                             darkBlue:0.3725 darkAlpha:1.0];
}
+ (UIColor *)systemTealColor
{
    return [self ui_colorWithLightRed:0.1882 lightGreen:0.6902 lightBlue:0.7804
                           lightAlpha:1.0 darkRed:0.3922 darkGreen:0.8235
                             darkBlue:1.0 darkAlpha:1.0];
}
+ (UIColor *)systemIndigoColor
{
    return [self ui_colorWithLightRed:0.3451 lightGreen:0.3373 lightBlue:0.8392
                           lightAlpha:1.0 darkRed:0.3686 darkGreen:0.3608
                             darkBlue:0.9020 darkAlpha:1.0];
}
+ (UIColor *)systemBrownColor
{
    return [self ui_colorWithLightRed:0.6353 lightGreen:0.5176 lightBlue:0.3686
                           lightAlpha:1.0 darkRed:0.6745 darkGreen:0.5569
                             darkBlue:0.4078 darkAlpha:1.0];
}
+ (UIColor *)systemGrayColor
{
    return [self ui_colorWithLightRed:0.5569 lightGreen:0.5569 lightBlue:0.5765
                           lightAlpha:1.0 darkRed:0.5569 darkGreen:0.5569
                             darkBlue:0.5765 darkAlpha:1.0];
}
+ (UIColor *)systemGray2Color
{
    return [self ui_colorWithLightRed:0.6824 lightGreen:0.6824 lightBlue:0.6980
                           lightAlpha:1.0 darkRed:0.3882 darkGreen:0.3882
                             darkBlue:0.4000 darkAlpha:1.0];
}
+ (UIColor *)systemGray3Color
{
    return [self ui_colorWithLightRed:0.7804 lightGreen:0.7804 lightBlue:0.8
                           lightAlpha:1.0 darkRed:0.2824 darkGreen:0.2824
                             darkBlue:0.2902 darkAlpha:1.0];
}
+ (UIColor *)systemGray4Color
{
    return [self ui_colorWithLightRed:0.8196 lightGreen:0.8196 lightBlue:0.8392
                           lightAlpha:1.0 darkRed:0.2275 darkGreen:0.2275
                             darkBlue:0.2353 darkAlpha:1.0];
}
+ (UIColor *)systemGray5Color
{
    return [self ui_colorWithLightRed:0.8980 lightGreen:0.8980 lightBlue:0.9176
                           lightAlpha:1.0 darkRed:0.1725 darkGreen:0.1725
                             darkBlue:0.1804 darkAlpha:1.0];
}
+ (UIColor *)systemGray6Color
{
    return [self ui_colorWithLightRed:0.9490 lightGreen:0.9490 lightBlue:0.9686
                           lightAlpha:1.0 darkRed:0.1098 darkGreen:0.1098
                             darkBlue:0.1176 darkAlpha:1.0];
}
+ (UIColor *)systemBackgroundColor
{
    return [self ui_colorWithLightRed:1.0 lightGreen:1.0 lightBlue:1.0
                           lightAlpha:1.0 darkRed:0.0 darkGreen:0.0
                             darkBlue:0.0 darkAlpha:1.0];
}
+ (UIColor *)secondarySystemBackgroundColor
{
    return [self ui_colorWithLightRed:0.9490 lightGreen:0.9490 lightBlue:0.9686
                           lightAlpha:1.0 darkRed:0.1098 darkGreen:0.1098
                             darkBlue:0.1176 darkAlpha:1.0];
}
+ (UIColor *)tertiarySystemBackgroundColor
{
    return [self ui_colorWithLightRed:1.0 lightGreen:1.0 lightBlue:1.0
                           lightAlpha:1.0 darkRed:0.1725 darkGreen:0.1725
                             darkBlue:0.1804 darkAlpha:1.0];
}
+ (UIColor *)systemGroupedBackgroundColor
{
    return [self ui_colorWithLightRed:0.9490 lightGreen:0.9490 lightBlue:0.9686
                           lightAlpha:1.0 darkRed:0.0 darkGreen:0.0
                             darkBlue:0.0 darkAlpha:1.0];
}
+ (UIColor *)secondarySystemGroupedBackgroundColor
{
    return [self ui_colorWithLightRed:1.0 lightGreen:1.0 lightBlue:1.0
                           lightAlpha:1.0 darkRed:0.1098 darkGreen:0.1098
                             darkBlue:0.1176 darkAlpha:1.0];
}
+ (UIColor *)labelColor
{
    return [self ui_colorWithLightRed:0.0 lightGreen:0.0 lightBlue:0.0
                           lightAlpha:1.0 darkRed:1.0 darkGreen:1.0
                             darkBlue:1.0 darkAlpha:1.0];
}
+ (UIColor *)secondaryLabelColor
{
    return [self ui_colorWithLightRed:0.2353 lightGreen:0.2353 lightBlue:0.2627
                           lightAlpha:0.6 darkRed:0.9216 darkGreen:0.9216
                             darkBlue:0.9608 darkAlpha:0.6];
}
+ (UIColor *)tertiaryLabelColor
{
    return [self ui_colorWithLightRed:0.2353 lightGreen:0.2353 lightBlue:0.2627
                           lightAlpha:0.3 darkRed:0.9216 darkGreen:0.9216
                             darkBlue:0.9608 darkAlpha:0.3];
}
+ (UIColor *)quaternaryLabelColor
{
    return [self ui_colorWithLightRed:0.2353 lightGreen:0.2353 lightBlue:0.2627
                           lightAlpha:0.18 darkRed:0.9216 darkGreen:0.9216
                             darkBlue:0.9608 darkAlpha:0.18];
}
+ (UIColor *)separatorColor
{
    return [self ui_colorWithLightRed:0.2353 lightGreen:0.2353 lightBlue:0.2627
                           lightAlpha:0.29 darkRed:0.5451 darkGreen:0.5451
                             darkBlue:0.5608 darkAlpha:0.65];
}
+ (UIColor *)opaqueSeparatorColor
{
    return [self ui_colorWithLightRed:0.7765 lightGreen:0.7765 lightBlue:0.7843
                           lightAlpha:1.0 darkRed:0.2196 darkGreen:0.2196
                             darkBlue:0.2275 darkAlpha:1.0];
}
+ (UIColor *)linkColor
{
    return [self ui_colorWithLightRed:0.0 lightGreen:0.4784 lightBlue:1.0
                           lightAlpha:1.0 darkRed:0.0392 darkGreen:0.5176
                             darkBlue:1.0 darkAlpha:1.0];
}
static double displayp3_to_linear(double value)
{
    return value <= 0.04045 ? value / 12.92
                            : pow((value + 0.055) / 1.055, 2.4);
}

static double linear_to_srgb(double value)
{
    if (value <= 0.0031308)
        return 12.92 * value;
    return 1.055 * pow(value, 1.0 / 2.4) - 0.055;
}

static void displayp3_components_to_srgb(double *components)
{
    double r = displayp3_to_linear(components[0]);
    double g = displayp3_to_linear(components[1]);
    double b = displayp3_to_linear(components[2]);
    double sr = 1.2249401 * r - 0.2249404 * g;
    double sg = -0.0420569 * r + 1.0420571 * g;
    double sb = -0.0196376 * r - 0.0786361 * g + 1.0982735 * b;
    if (sr < 0) sr = 0; if (sr > 1) sr = 1;
    if (sg < 0) sg = 0; if (sg > 1) sg = 1;
    if (sb < 0) sb = 0; if (sb > 1) sb = 1;
    components[0] = linear_to_srgb(sr);
    components[1] = linear_to_srgb(sg);
    components[2] = linear_to_srgb(sb);
}

- (void)ui_components:(double *)components
{
    if (_provider)
    {
        UITraitCollection *traits = ui_trait_for_style(ui_style_current());
        id resolved = ((id (^)(id))_provider)(traits);
        if (resolved && resolved != (id)self &&
            [resolved isKindOfClass:[UIColor class]])
        {
            [(UIColor *)resolved ui_components:components];
            return;
        }
    }
    if (_dynamic && ui_style_current())
    {
        components[0] = _dark_r;
        components[1] = _dark_g;
        components[2] = _dark_b;
        components[3] = _dark_a;
        if (_displayP3)
            displayp3_components_to_srgb(components);
        return;
    }
    components[0] = _r;
    components[1] = _g;
    components[2] = _b;
    components[3] = _a;
    if (_displayP3)
        displayp3_components_to_srgb(components);
}
- (UIColor *)resolvedColorWithTraitCollection:(UITraitCollection *)traits
{
    int dark = traits &&
        traits->_userInterfaceStyle == UIUserInterfaceStyleDark;
    if (_provider)
    {
        id resolved = ((id (^)(id))_provider)(traits);
        if (resolved && [resolved isKindOfClass:[UIColor class]])
            return (UIColor *)resolved;
    }
    if (_dynamic && dark)
        return [UIColor colorWithRed:_dark_r green:_dark_g blue:_dark_b
                              alpha:_dark_a];
    return [UIColor colorWithRed:_r green:_g blue:_b alpha:_a];
}
- (CGColorRef)CGColor
{
    double components[4];
    [self ui_components:components];
    return CGColorCreateGenericRGB(components[0], components[1],
                                   components[2], components[3]);
}
@end

id NSFontAttributeName = @"NSFontAttributeName";
id NSForegroundColorAttributeName = @"NSForegroundColorAttributeName";
id NSBackgroundColorAttributeName = @"NSBackgroundColorAttributeName";

static unsigned text_color_rgb(UIColor *color)
{
    if (!color)
        return 0x000000;
    double components[4];
    [color ui_components:components];
    int r = (int)(components[0] * 255.0 + 0.5);
    int g = (int)(components[1] * 255.0 + 0.5);
    int b = (int)(components[2] * 255.0 + 0.5);
    if (r < 0) r = 0; if (r > 255) r = 255;
    if (g < 0) g = 0; if (g > 255) g = 255;
    if (b < 0) b = 0; if (b > 255) b = 255;
    return ((unsigned)r << 16) | ((unsigned)g << 8) | (unsigned)b;
}

static UIFont *drawing_font(NSDictionary *attributes)
{
    id font = attributes ? [attributes objectForKey:NSFontAttributeName] : nil;
    if (font && [font isKindOfClass:[UIFont class]])
        return (UIFont *)font;
    return [UIFont systemFontOfSize:17];
}

#define TEXT_MAX_LINES 64
#define TEXT_LINE_CHARS 256

static int text_wrap_lines(const char *text, double max_width, UIFont *font,
                           double scale, char lines[][TEXT_LINE_CHARS],
                           double *out_width)
{
    int count = 0;
    double widest = 0;
    const char *p = text;
    int style = font->_bold ? IOSIM_FONT_SEMIBOLD : IOSIM_FONT_REGULAR;
    while (*p && count < TEXT_MAX_LINES)
    {
        char line[TEXT_LINE_CHARS];
        int line_len = 0;
        double line_width = 0;
        line[0] = 0;
        while (*p && *p != '\n')
        {
            while (*p == ' ')
                p++;
            if (!*p || *p == '\n')
                break;
            const char *word = p;
            while (*p && *p != ' ' && *p != '\n')
                p++;
            int word_len = (int)(p - word);
            if (word_len > TEXT_LINE_CHARS - 2)
                word_len = TEXT_LINE_CHARS - 2;
            char candidate[TEXT_LINE_CHARS * 2];
            int candidate_len = 0;
            for (int i = 0; i < line_len && candidate_len < 500; i++)
                candidate[candidate_len++] = line[i];
            if (line_len > 0 && candidate_len < 500)
                candidate[candidate_len++] = ' ';
            for (int i = 0; i < word_len && candidate_len < 500; i++)
                candidate[candidate_len++] = word[i];
            candidate[candidate_len] = 0;
            double candidate_width = iosim_fb_font_text_width(
                candidate, style, font->_size, scale);
            if (line_len > 0 && candidate_width > max_width)
            {
                if (count < TEXT_MAX_LINES)
                {
                    for (int i = 0; i <= line_len; i++)
                        lines[count][i] = line[i];
                    count++;
                }
                if (line_width > widest)
                    widest = line_width;
                line_len = 0;
                line[0] = 0;
                line_width = 0;
                for (int i = 0; i < word_len; i++)
                    line[line_len++] = word[i];
                line[line_len] = 0;
                line_width = iosim_fb_font_text_width(line, style,
                                                      font->_size, scale);
            }
            else
            {
                for (int i = 0; i < candidate_len; i++)
                    line[i] = candidate[i];
                line_len = candidate_len;
                line_width = candidate_width;
            }
        }
        if (count < TEXT_MAX_LINES)
        {
            for (int i = 0; i <= line_len; i++)
                lines[count][i] = line[i];
            count++;
        }
        if (line_width > widest)
            widest = line_width;
        if (*p == '\n')
            p++;
    }
    if (out_width)
        *out_width = widest;
    return count;
}

@interface NSString (UIKitDrawing)
- (CGSize)sizeWithAttributes:(NSDictionary *)attributes;
- (void)drawAtPoint:(CGPoint)point withAttributes:(NSDictionary *)attributes;
- (void)drawInRect:(CGRect)rect withAttributes:(NSDictionary *)attributes;
- (CGRect)boundingRectWithSize:(CGSize)size
                       options:(unsigned long)options
                    attributes:(NSDictionary *)attributes
                       context:(id)context;
@end

@implementation NSString (UIKitDrawing)
- (CGSize)sizeWithAttributes:(NSDictionary *)attributes
{
    const char *text = iosim_string_cstr(self);
    if (!text)
        return CGSizeMake(0, 0);
    UIFont *font = drawing_font(attributes);
    double scale = [[UIScreen mainScreen] scale];
    if (scale <= 0)
        scale = 1.0;
    int width = iosim_fb_font_text_width(
        text, font->_bold ? IOSIM_FONT_SEMIBOLD : IOSIM_FONT_REGULAR,
        font->_size, scale);
    int ascent = 0, descent = 0, lineHeight = 0;
    iosim_fb_font_metrics(font->_bold ? IOSIM_FONT_SEMIBOLD
                                      : IOSIM_FONT_REGULAR,
                          font->_size, scale, &ascent, &descent, &lineHeight);
    return CGSizeMake(width / scale, lineHeight / scale);
}
- (void)drawAtPoint:(CGPoint)point withAttributes:(NSDictionary *)attributes
{
    const char *text = iosim_string_cstr(self);
    if (!text)
        return;
    UIFont *font = drawing_font(attributes);
    UIColor *color = attributes
        ? (UIColor *)[attributes objectForKey:NSForegroundColorAttributeName]
        : nil;
    double scale = [[UIScreen mainScreen] scale];
    if (scale <= 0)
        scale = 1.0;
    int ascent = 0, descent = 0, lineHeight = 0;
    iosim_fb_font_metrics(font->_bold ? IOSIM_FONT_SEMIBOLD
                                      : IOSIM_FONT_REGULAR,
                          font->_size, scale, &ascent, &descent, &lineHeight);
    iosim_cg_draw_text(iosim_cg_current(), text, point.x,
                       point.y + ascent / scale, font->_size,
                       font->_bold, text_color_rgb(color));
}
- (void)drawInRect:(CGRect)rect withAttributes:(NSDictionary *)attributes
{
    const char *text = iosim_string_cstr(self);
    if (!text)
        return;
    UIFont *font = drawing_font(attributes);
    UIColor *color = attributes
        ? (UIColor *)[attributes objectForKey:NSForegroundColorAttributeName]
        : nil;
    double scale = [[UIScreen mainScreen] scale];
    if (scale <= 0)
        scale = 1.0;
    int ascent = 0, descent = 0, lineHeight = 0;
    int style = font->_bold ? IOSIM_FONT_SEMIBOLD : IOSIM_FONT_REGULAR;
    iosim_fb_font_metrics(style, font->_size, scale, &ascent, &descent,
                          &lineHeight);
    char lines[TEXT_MAX_LINES][TEXT_LINE_CHARS];
    int count = text_wrap_lines(text, rect.size.width, font, scale, lines, 0);
    if (count <= 0 || lineHeight <= 0)
        return;
    CGContextRef context = iosim_cg_current();
    if (context)
    {
        CGContextSaveGState(context);
        CGContextClipToRect(context, rect);
    }
    unsigned text_color = text_color_rgb(color);
    for (int i = 0; i < count; i++)
    {
        double baseline = rect.origin.y + (ascent + i * lineHeight) / scale;
        if (baseline > rect.origin.y + rect.size.height + 1)
            break;
        iosim_cg_draw_text(context, lines[i], rect.origin.x, baseline,
                           font->_size, font->_bold, text_color);
    }
    if (context)
        CGContextRestoreGState(context);
}
- (CGRect)boundingRectWithSize:(CGSize)size
                       options:(unsigned long)options
                    attributes:(NSDictionary *)attributes
                       context:(id)context
{
    (void)options;
    (void)context;
    const char *text = iosim_string_cstr(self);
    if (!text)
        return CGRectMake(0, 0, 0, 0);
    UIFont *font = drawing_font(attributes);
    double scale = [[UIScreen mainScreen] scale];
    if (scale <= 0)
        scale = 1.0;
    int ascent = 0, descent = 0, lineHeight = 0;
    int style = font->_bold ? IOSIM_FONT_SEMIBOLD : IOSIM_FONT_REGULAR;
    iosim_fb_font_metrics(style, font->_size, scale, &ascent, &descent,
                          &lineHeight);
    char lines[TEXT_MAX_LINES][TEXT_LINE_CHARS];
    double width = 0;
    int count = text_wrap_lines(text, size.width, font, scale, lines, &width);
    double result_width = width / scale;
    double result_height = count * lineHeight / scale;
    if (size.width > 0 && result_width > size.width)
        result_width = size.width;
    if (size.height > 0 && result_height > size.height)
        result_height = size.height;
    return CGRectMake(0, 0, result_width, result_height);
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
+ (UIFont *)systemFontOfSize:(double)size weight:(double)weight
{
    UIFont *f = [[self alloc] init];
    f->_size = size;
    f->_bold = weight >= UIFontWeightSemibold;
    return f;
}
+ (UIFont *)boldSystemFontOfSize:(double)size
{
    UIFont *f = [[self alloc] init];
    f->_size = size;
    f->_bold = YES;
    return f;
}
+ (UIFont *)italicSystemFontOfSize:(double)size
{
    return [self systemFontOfSize:size];
}
+ (UIFont *)monospacedSystemFontOfSize:(double)size weight:(double)weight
{
    UIFont *f = [self systemFontOfSize:size weight:weight];
    f->_name = @"Menlo";
    return f;
}
+ (UIFont *)fontWithName:(id)name size:(double)size
{
    UIFont *f = [[self alloc] init];
    f->_size = size;
    f->_name = name;
    return f;
}
- (double)pointSize { return _size; }
- (id)fontName { return _name ? _name : @"System"; }
- (id)familyName { return _name ? _name : @"System"; }
- (UIFont *)fontWithSize:(double)size
{
    UIFont *f = [[[self class] alloc] init];
    f->_size = size;
    f->_bold = _bold;
    f->_name = _name;
    return f;
}
+ (UIFont *)fontWithDescriptor:(UIFontDescriptor *)descriptor
                          size:(double)size
{
    UIFont *f = [[self alloc] init];
    f->_size = size > 0 ? size : (descriptor ? descriptor->_size : 12);
    f->_name = descriptor ? descriptor->_name : nil;
    return f;
}
+ (UIFont *)preferredFontForTextStyle:(id)style
{
    (void)style;
    return [self systemFontOfSize:17];
}
+ (UIFont *)preferredFontForTextStyle:(id)style
              compatibleWithTraitCollection:(UITraitCollection *)traits
{
    (void)traits;
    return [self preferredFontForTextStyle:style];
}
- (UIFontDescriptor *)fontDescriptor
{
    UIFontDescriptor *descriptor = [[UIFontDescriptor alloc] init];
    descriptor->_size = _size;
    descriptor->_name = _name;
    return descriptor;
}
@end

@implementation UIFontDescriptor
+ (UIFontDescriptor *)preferredFontDescriptorWithTextStyle:(id)style
{
    (void)style;
    UIFontDescriptor *descriptor = [[self alloc] init];
    descriptor->_size = 17;
    return descriptor;
}
- (UIFontDescriptor *)fontDescriptorWithSize:(double)size
{
    UIFontDescriptor *descriptor = [[[self class] alloc] init];
    descriptor->_size = size;
    descriptor->_name = _name;
    return descriptor;
}
- (UIFontDescriptor *)fontDescriptorWithSymbolicTraits:(unsigned long)traits
{
    (void)traits;
    return [self fontDescriptorWithSize:_size];
}
- (double)pointSize { return _size; }
- (id)fontAttributes { return [NSDictionary dictionary]; }
@end

/* --------------------------------------------------------------- screens */

NSString *UIDeviceOrientationDidChangeNotification;
__attribute__((constructor)) static void iosim_ui_device_notification(void)
{
    UIDeviceOrientationDidChangeNotification =
        @"UIDeviceOrientationDidChangeNotification";
}

@implementation UIDevice
+ (UIDevice *)currentDevice
{
    static UIDevice *device;
    if (!device)
        device = [[UIDevice alloc] init];
    return device;
}
- (id)init
{
    self = [super init];
    if (self)
    {
        _orientation = 1;
        _batteryState = 0;
        _batteryLevel = -1.0;
    }
    return self;
}
- (id)name { return @"iPhone"; }
- (id)model { return @"iPhone"; }
- (id)localizedModel { return @"iPhone"; }
- (id)systemName { return @"iOS"; }
- (id)systemVersion { return @"18.0"; }
- (id)identifierForVendor
{
    static NSUUID *vendor;
    if (!vendor)
        vendor = [NSUUID UUID];
    return vendor;
}
- (long)userInterfaceIdiom { return 0; }
- (long)orientation { return _orientation; }
- (void)setOrientation:(long)orientation { _orientation = orientation; }
- (long)batteryState { return _batteryState; }
- (double)batteryLevel { return _batteryLevel; }
- (BOOL)isProximityMonitoringEnabled { return _proximityMonitoringEnabled; }
- (void)setProximityMonitoringEnabled:(BOOL)enabled
{
    _proximityMonitoringEnabled = enabled;
}
- (BOOL)isMultitaskingSupported { return YES; }
- (BOOL)isGeneratingDeviceOrientationNotifications
{
    return _generatingOrientationNotifications;
}
- (void)beginGeneratingDeviceOrientationNotifications
{
    _generatingOrientationNotifications = YES;
}
- (void)endGeneratingDeviceOrientationNotifications
{
    _generatingOrientationNotifications = NO;
}
- (void)playInputClick { }
@end

@implementation UIScreen
+ (UIScreen *)mainScreen
{
    static UIScreen *screen;
    if (!screen)
        screen = [[self alloc] init];
    return screen;
}
- (id)init
{
    self = [super init];
    if (self)
        _brightness = 1.0;
    return self;
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
- (CGRect)nativeBounds
{
    const char *w = getenv("SIMULATOR_MAINSCREEN_WIDTH");
    const char *h = getenv("SIMULATOR_MAINSCREEN_HEIGHT");
    return CGRectMake(0, 0, w ? atoi(w) : 1206, h ? atoi(h) : 2622);
}
- (double)nativeScale { return [self scale]; }
- (double)brightness { return _brightness; }
- (void)setBrightness:(double)brightness
{
    if (brightness < 0) brightness = 0;
    if (brightness > 1) brightness = 1;
    _brightness = brightness;
}
- (BOOL)isCaptured { return NO; }
@end

/* ---------------------------------------------------------------- views */

static BOOL g_animating;
static BOOL g_animationsEnabled = YES;
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

/* UIView keyframe animations are queued at their relative start times and
 * then run as ordinary UIView animation blocks, so each segment interpolates
 * from the previous segment's settled model values. */
#define MAX_UI_KEYFRAMES 16
struct ui_keyframe {
    int used;
    double due;
    double duration;
    void (^block)(void);
};
static struct ui_keyframe g_keyframes[MAX_UI_KEYFRAMES];
static int g_keyframeCount;
static int g_keyframeActive;
static double g_keyframeDuration;
static double g_keyframeDelay;

static void keyframe_add(double start, double relativeDuration,
                         void (^block)(void))
{
    if (!block || g_keyframeCount >= MAX_UI_KEYFRAMES)
        return;
    struct ui_keyframe *entry = &g_keyframes[g_keyframeCount];
    entry->used = 1;
    entry->due = iosim_now() + g_keyframeDelay +
                 start * g_keyframeDuration;
    entry->duration = relativeDuration * g_keyframeDuration;
    entry->block = (void (^)(void))_Block_copy(block);
    g_keyframeCount++;
}

/* Fire animations that have reached their end. The run loop calls this on
 * every tick, so a completion block observes the settled model values. */
int iosim_animation_tick(void)
{
    int fired = 0;
    double now = iosim_now();
    fired |= anim_delegate_tick(now);
    int k = 0;
    while (k < g_keyframeCount)
    {
        struct ui_keyframe *entry = &g_keyframes[k];
        if (entry->used && now >= entry->due)
        {
            double duration = entry->duration;
            void (^block)(void) = entry->block;
            g_keyframes[k] = g_keyframes[g_keyframeCount - 1];
            g_keyframeCount--;
            if (block)
                [UIView animateWithDuration:duration animations:block
                                 completion:nil];
            fired = 1;
        }
        else
            k++;
    }
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
           g_completionCount > 0 || g_keyframeCount > 0 ||
           anim_delegates_pending() || display_links_active();
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

/* Window-point to view-local conversion along the view hierarchy. Descending
 * from the window, each step removes the view's frame origin, inverts its
 * (possibly animating) transform around the box center, and adds a scroll
 * view's content offset before entering its content. */
static CGPoint touch_point_in_view(UIView *view, CGPoint point)
{
    UIView *chain[64];
    int n = 0;
    for (UIView *v = view; v && n < 64; v = (UIView *)v->_superview)
        chain[n++] = v;
    CGPoint p = point;
    for (int i = n - 1; i >= 0; i--)
    {
        UIView *v = chain[i];
        p = CGPointMake(p.x - v->_frame.origin.x,
                        p.y - v->_frame.origin.y);
        p = view_untransform_point(v, p);
        if ([v isKindOfClass:[UIScrollView class]])
        {
            UIScrollView *scroll = (UIScrollView *)v;
            p.x += scroll->_contentOffset.x;
            p.y += scroll->_contentOffset.y;
        }
    }
    return p;
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
    {
        _touch = touch;
        _touches = [[NSMutableArray alloc] init];
        if (touch)
        {
            [_touches addObject:touch];
            _changedTouches = [NSSet setWithObject:touch];
        }
    }
    return self;
}
- (id)initWithTouches:(NSArray *)touches changed:(NSSet *)changed
{
    self = [super init];
    if (self)
    {
        _touches = [[NSMutableArray alloc] init];
        for (unsigned long i = 0; i < [touches count]; i++)
            [_touches addObject:[touches objectAtIndex:i]];
        _touch = [touches count] ? [touches objectAtIndex:0] : nil;
        _changedTouches = changed;
    }
    return self;
}
- (NSSet *)allTouches
{
    if (!_touches)
        return [NSSet set];
    return [NSSet setWithArray:_touches];
}
- (NSSet *)touchesForView:(UIView *)view
{
    NSMutableSet *set = [[NSMutableSet alloc] init];
    if (!_touches)
        return set;
    for (unsigned long i = 0; i < [_touches count]; i++)
    {
        UITouch *touch = [_touches objectAtIndex:i];
        if ((id)touch->_view == (id)view)
            [set addObject:touch];
    }
    return set;
}
- (NSSet *)touchesForWindow:(UIWindow *)window
{
    NSMutableSet *set = [[NSMutableSet alloc] init];
    if (!_touches)
        return set;
    for (unsigned long i = 0; i < [_touches count]; i++)
    {
        UITouch *touch = [_touches objectAtIndex:i];
        if ((id)touch->_window == (id)window)
            [set addObject:touch];
    }
    return set;
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
- (id)identifier { return _identifier; }
- (void)setIdentifier:(id)identifier { _identifier = identifier; }
- (double)layoutFrameX { return _leftInset; }
- (double)layoutFrameY { return _topInset; }
- (double)layoutFrameWidth
{
    UIView *owner = (UIView *)_owningView;
    double width = owner ? owner->_frame.size.width : 0;
    width -= _leftInset + _rightInset;
    return width > 0 ? width : 0;
}
- (double)layoutFrameHeight
{
    UIView *owner = (UIView *)_owningView;
    double height = owner ? owner->_frame.size.height : 0;
    height -= _topInset + _bottomInset;
    return height > 0 ? height : 0;
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
        _delaysTouchesBegan = YES;
        _delaysTouchesEnded = YES;
        _cancelsTouchesInView = YES;
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
- (id)delegate { return _delegate; }
- (void)setDelegate:(id)delegate { _delegate = delegate; }
- (void)requireGestureRecognizerToFail:(UIGestureRecognizer *)other
{
    (void)other;
}
- (unsigned long)numberOfTouches { return _numberOfTouches; }
- (BOOL)delaysTouchesBegan { return _delaysTouchesBegan; }
- (void)setDelaysTouchesBegan:(BOOL)delays
{
    _delaysTouchesBegan = delays;
}
- (BOOL)delaysTouchesEnded { return _delaysTouchesEnded; }
- (void)setDelaysTouchesEnded:(BOOL)delays
{
    _delaysTouchesEnded = delays;
}
- (BOOL)cancelsTouchesInView { return _cancelsTouchesInView; }
- (void)setCancelsTouchesInView:(BOOL)cancels
{
    _cancelsTouchesInView = cancels;
}
- (NSArray *)allowedTouchTypes { return _allowedTouchTypes; }
- (void)setAllowedTouchTypes:(NSArray *)types
{
    _allowedTouchTypes = types;
}
@end

@implementation UITapGestureRecognizer
- (id)initWithTarget:(id)target action:(SEL)action
{
    self = [super initWithTarget:target action:action];
    if (self)
    {
        _numberOfTapsRequired = 1;
        _numberOfTouchesRequired = 1;
    }
    return self;
}
- (void)setNumberOfTapsRequired:(int)count { _numberOfTapsRequired = count; }
- (int)numberOfTapsRequired { return _numberOfTapsRequired; }
- (void)setNumberOfTouchesRequired:(int)count
{
    _numberOfTouchesRequired = count;
}
- (int)numberOfTouchesRequired { return _numberOfTouchesRequired; }
@end

@implementation UIPanGestureRecognizer
- (id)initWithTarget:(id)target action:(SEL)action
{
    self = [super initWithTarget:target action:action];
    if (self)
    {
        _minimumNumberOfTouches = 1;
        _maximumNumberOfTouches = 2;
    }
    return self;
}
- (CGPoint)translationInView:(UIView *)view
{
    (void)view;
    return _translation;
}
- (CGPoint)velocityInView:(UIView *)view
{
    (void)view;
    return _panVelocity;
}
- (void)setTranslation:(CGPoint)translation inView:(UIView *)view
{
    (void)view;
    _translation = translation;
}
- (unsigned long)minimumNumberOfTouches { return _minimumNumberOfTouches; }
- (void)setMinimumNumberOfTouches:(unsigned long)count
{
    _minimumNumberOfTouches = count;
}
- (unsigned long)maximumNumberOfTouches { return _maximumNumberOfTouches; }
- (void)setMaximumNumberOfTouches:(unsigned long)count
{
    _maximumNumberOfTouches = count;
}
@end

@implementation UIScreenEdgePanGestureRecognizer
- (UIRectEdge)edges { return _edges; }
- (void)setEdges:(UIRectEdge)edges { _edges = edges; }
@end

@implementation UIPinchGestureRecognizer
- (id)initWithTarget:(id)target action:(SEL)action
{
    self = [super initWithTarget:target action:action];
    if (self)
        _scale = 1.0;
    return self;
}
- (double)scale { return _scale; }
- (void)setScale:(double)scale { _scale = scale; }
- (double)velocity { return _velocity; }
@end

@implementation UIRotationGestureRecognizer
- (double)rotation { return _rotation; }
- (void)setRotation:(double)rotation { _rotation = rotation; }
- (double)velocity { return _velocity; }
@end

@implementation UISwipeGestureRecognizer
- (id)initWithTarget:(id)target action:(SEL)action
{
    self = [super initWithTarget:target action:action];
    if (self)
        _numberOfTouchesRequired = 1;
    return self;
}
- (void)setDirection:(long)direction { _direction = direction; }
- (long)direction { return _direction; }
- (void)setNumberOfTouchesRequired:(int)count
{
    _numberOfTouchesRequired = count;
}
- (int)numberOfTouchesRequired { return _numberOfTouchesRequired; }
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

static int ui_view_style_with_global(UIView *view, int global)
{
    if (view->_overrideUserInterfaceStyle == UIUserInterfaceStyleDark)
        return 1;
    if (view->_overrideUserInterfaceStyle == UIUserInterfaceStyleLight)
        return 0;
    if (view->_superview)
        return ui_view_style_with_global((UIView *)view->_superview, global);
    return global;
}

/* Notifies the subtree that its effective style changed. Each child with its
 * own override keeps that style and is left alone. */
static void ui_trait_children(UIView *view, int oldParent, int newParent)
{
    for (int i = 0; i < view->_subviewCount; i++)
    {
        UIView *child = (UIView *)view->_subviews[i];
        int oldStyle = child->_overrideUserInterfaceStyle ==
                               UIUserInterfaceStyleDark ? 1 :
                       child->_overrideUserInterfaceStyle ==
                               UIUserInterfaceStyleLight ? 0 : oldParent;
        int newStyle = child->_overrideUserInterfaceStyle ==
                               UIUserInterfaceStyleDark ? 1 :
                       child->_overrideUserInterfaceStyle ==
                               UIUserInterfaceStyleLight ? 0 : newParent;
        if (oldStyle != newStyle)
            [child traitCollectionDidChange:ui_trait_for_style(oldStyle)];
        ui_trait_children(child, oldStyle, newStyle);
    }
}

@implementation UIView
+ (Class)layerClass { return [CALayer class]; }
- (id)initWithFrame:(CGRect)frame
{
    self = [super init];
    if (self)
    {
        _frame = frame;
        _alpha = 1.0;
        _hidden = NO;
        _userInteractionEnabled = YES;
        _opaque = YES;
        _clearsContextBeforeDrawing = YES;
        _autoresizesSubviews = YES;
        _layer = [[[self class] layerClass] alloc];
        _layer = [_layer init];
        _layer->_frame = CGRectMake(0, 0, frame.size.width, frame.size.height);
        _layer->_ownerView = self;
        _transform = CGAffineTransformIdentityValue();
        _translatesAutoresizingMaskIntoConstraints = YES;
        _layoutMargins = UIEdgeInsetsMake(8, 8, 8, 8);
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
- (void)setBounds:(CGRect)bounds
{
    _frame.size = bounds.size;
    if (_layer)
        _layer->_frame = CGRectMake(0, 0, bounds.size.width,
                                    bounds.size.height);
}
- (CGPoint)center
{
    return CGPointMake(_frame.origin.x + _frame.size.width / 2.0,
                       _frame.origin.y + _frame.size.height / 2.0);
}
- (void)setCenter:(CGPoint)center
{
    CGRect frame = _frame;
    frame.origin.x = center.x - frame.size.width / 2.0;
    frame.origin.y = center.y - frame.size.height / 2.0;
    [self setFrame:frame];
}

/* Coordinate conversion walks the superview chain, adding each frame origin
 * and subtracting a scroll ancestor's contentOffset, exactly as hit-testing
 * does. These are translations; view transforms are not folded in. */
static CGPoint window_point_for_view(UIView *view, CGPoint point)
{
    CGPoint result = point;
    for (UIView *v = view; v; v = [v superview])
    {
        result.x += v->_frame.origin.x;
        result.y += v->_frame.origin.y;
        UIView *parent = [v superview];
        if (parent && [parent isKindOfClass:[UIScrollView class]])
        {
            UIScrollView *scroll = (UIScrollView *)parent;
            result.x -= scroll->_contentOffset.x;
            result.y -= scroll->_contentOffset.y;
        }
    }
    return result;
}

- (CGPoint)convertPoint:(CGPoint)point toView:(UIView *)view
{
    CGPoint window = window_point_for_view(self, point);
    if (!view)
        return window;
    CGPoint target = window_point_for_view(view, CGPointMake(0, 0));
    return CGPointMake(window.x - target.x, window.y - target.y);
}

- (CGPoint)convertPoint:(CGPoint)point fromView:(UIView *)view
{
    CGPoint window = view ? window_point_for_view(view, point) : point;
    CGPoint self_origin = window_point_for_view(self, CGPointMake(0, 0));
    return CGPointMake(window.x - self_origin.x, window.y - self_origin.y);
}

- (CGRect)convertRect:(CGRect)rect toView:(UIView *)view
{
    CGPoint origin = [self convertPoint:rect.origin toView:view];
    return CGRectMake(origin.x, origin.y, rect.size.width, rect.size.height);
}

- (CGRect)convertRect:(CGRect)rect fromView:(UIView *)view
{
    CGPoint origin = [self convertPoint:rect.origin fromView:view];
    return CGRectMake(origin.x, origin.y, rect.size.width, rect.size.height);
}
- (void)setBackgroundColor:(UIColor *)color { _backgroundColor = color; }
- (UIColor *)backgroundColor { return _backgroundColor; }
- (UIColor *)tintColor
{
    if (_tintColor)
        return _tintColor;
    if (_superview)
        return [(UIView *)_superview tintColor];
    return [UIColor systemBlueColor];
}
- (void)setTintColor:(UIColor *)color
{
    _tintColor = color;
    [self tintColorDidChange];
    for (int i = 0; i < _subviewCount; i++)
        [(UIView *)_subviews[i] tintColorDidChange];
}
- (void)tintColorDidChange { }
- (long)tintAdjustmentMode { return _tintAdjustmentMode; }
- (void)setTintAdjustmentMode:(long)mode
{
    _tintAdjustmentMode = mode;
    [self tintColorDidChange];
    for (int i = 0; i < _subviewCount; i++)
        [(UIView *)_subviews[i] tintColorDidChange];
}
- (UITraitCollection *)traitCollection
{
    int style = ui_view_style_with_global(self, ui_style_current());
    return ui_trait_for_style(style);
}
- (long)overrideUserInterfaceStyle { return _overrideUserInterfaceStyle; }
- (void)traitCollectionDidChange:(UITraitCollection *)previous
{
    (void)previous;
}
- (void)setOverrideUserInterfaceStyle:(long)style
{
    if (_overrideUserInterfaceStyle == style)
        return;
    int oldStyle = ui_view_style_with_global(self, ui_style_current());
    _overrideUserInterfaceStyle = style;
    int newStyle = ui_view_style_with_global(self, ui_style_current());
    if (oldStyle == newStyle)
        return;
    [self traitCollectionDidChange:ui_trait_for_style(oldStyle)];
    ui_trait_children(self, oldStyle, newStyle);
}
- (void)setClipsToBounds:(BOOL)clips { _clipsToBounds = clips; }
- (BOOL)clipsToBounds { return _clipsToBounds; }
- (UIView *)maskView { return _maskView; }
- (void)setMaskView:(UIView *)view
{
    _maskView = view;
    if (view && view->_layer)
        view->_layer->_backgroundColor = view->_backgroundColor;
    if (_layer)
        _layer->_mask = view ? view->_layer : nil;
}
- (void)addSubview:(UIView *)view
{
    if (!view)
        return;
    [view willMoveToSuperview:self];
    view->_superview = self;
    if (_subviewCount < 32)
        _subviews[_subviewCount++] = view;
    [view didMoveToSuperview];
    [self didAddSubview:view];
    [view tintColorDidChange];
}
- (void)didAddSubview:(UIView *)subview { (void)subview; }
- (void)willRemoveSubview:(UIView *)subview { (void)subview; }
- (void)willMoveToSuperview:(UIView *)newSuperview { (void)newSuperview; }
- (void)didMoveToSuperview { }
- (void)willMoveToWindow:(id)window { (void)window; }
- (void)didMoveToWindow { }
- (NSArray *)subviews
{
    NSMutableArray *array = [NSMutableArray array];
    for (int i = 0; i < _subviewCount; i++)
        [array addObject:_subviews[i]];
    return array;
}
- (void)addInteraction:(id)interaction
{
    if (!interaction)
        return;
    for (int i = 0; i < _interactionCount; i++)
        if (_interactions[i] == interaction)
            return;
    if (_interactionCount >= 8)
        return;
    _interactions[_interactionCount++] = interaction;
    if ([interaction respondsToSelector:@selector(didMoveToView:)])
        [interaction didMoveToView:self];
}
- (void)removeInteraction:(id)interaction
{
    for (int i = 0; i < _interactionCount; i++)
    {
        if (_interactions[i] != interaction)
            continue;
        if ([interaction respondsToSelector:@selector(willMoveToView:)])
            [interaction willMoveToView:nil];
        for (int j = i; j + 1 < _interactionCount; j++)
            _interactions[j] = _interactions[j + 1];
        _interactionCount--;
        return;
    }
}
- (NSArray *)interactions
{
    return [NSArray arrayWithObjects:_interactions
                                count:(unsigned long)_interactionCount];
}
- (BOOL)isAccessibilityElement { return _isAccessibilityElement; }
- (void)setIsAccessibilityElement:(BOOL)element
{
    _isAccessibilityElement = element;
}
- (id)accessibilityLabel { return _accessibilityLabel; }
- (void)setAccessibilityLabel:(id)label { _accessibilityLabel = label; }
- (id)accessibilityIdentifier { return _accessibilityIdentifier; }
- (void)setAccessibilityIdentifier:(id)identifier
{
    _accessibilityIdentifier = identifier;
}
- (id)accessibilityHint { return _accessibilityHint; }
- (void)setAccessibilityHint:(id)hint { _accessibilityHint = hint; }
- (id)accessibilityValue { return _accessibilityValue; }
- (void)setAccessibilityValue:(id)value { _accessibilityValue = value; }
- (unsigned long long)accessibilityTraits { return _accessibilityTraits; }
- (void)setAccessibilityTraits:(unsigned long long)traits
{
    _accessibilityTraits = traits;
}
- (BOOL)accessibilityElementsHidden { return _accessibilityElementsHidden; }
- (void)setAccessibilityElementsHidden:(BOOL)hidden
{
    _accessibilityElementsHidden = hidden;
}
- (BOOL)accessibilityViewIsModal { return _accessibilityViewIsModal; }
- (void)setAccessibilityViewIsModal:(BOOL)modal
{
    _accessibilityViewIsModal = modal;
}
- (BOOL)shouldGroupAccessibilityChildren
{
    return _shouldGroupAccessibilityChildren;
}
- (void)setShouldGroupAccessibilityChildren:(BOOL)group
{
    _shouldGroupAccessibilityChildren = group;
}
- (NSArray *)accessibilityElements { return _accessibilityElements; }
- (void)setAccessibilityElements:(NSArray *)elements
{
    _accessibilityElements = elements;
}
- (CGRect)accessibilityFrame
{
    if (_accessibilityFrame.size.width != 0 ||
        _accessibilityFrame.size.height != 0)
        return _accessibilityFrame;
    CGRect frame = _frame;
    UIView *parent = _superview;
    while (parent)
    {
        frame.origin.x += parent->_frame.origin.x;
        frame.origin.y += parent->_frame.origin.y;
        parent = parent->_superview;
    }
    return frame;
}
- (void)setAccessibilityFrame:(CGRect)frame
{
    _accessibilityFrame = frame;
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
    [view tintColorDidChange];
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
    [parent willRemoveSubview:self];
    [self willMoveToSuperview:nil];
    for (int i = 0; i < parent->_subviewCount; i++)
        if (parent->_subviews[i] == self)
        {
            for (int j = i; j + 1 < parent->_subviewCount; j++)
                parent->_subviews[j] = parent->_subviews[j + 1];
            parent->_subviewCount--;
            break;
        }
    _superview = nil;
    [self didMoveToSuperview];
}
- (CALayer *)layer { return _layer; }
- (void)setHidden:(BOOL)hidden { _hidden = hidden; }
- (BOOL)isHidden { return _hidden; }
- (BOOL)isUserInteractionEnabled { return _userInteractionEnabled; }
- (void)setUserInteractionEnabled:(BOOL)enabled
{
    _userInteractionEnabled = enabled;
}
- (BOOL)isOpaque { return _opaque; }
- (void)setOpaque:(BOOL)opaque { _opaque = opaque; }
- (long)contentMode { return _contentMode; }
- (void)setContentMode:(long)mode { _contentMode = mode; }
- (long)semanticContentAttribute { return _semanticContentAttribute; }
- (void)setSemanticContentAttribute:(long)attribute
{
    _semanticContentAttribute = attribute;
}
+ (long)userInterfaceLayoutDirectionForSemanticContentAttribute:(long)attribute
{
    (void)attribute;
    return 0;
}
- (long)effectiveUserInterfaceLayoutDirection
{
    return [[self class] userInterfaceLayoutDirectionForSemanticContentAttribute:
        _semanticContentAttribute];
}
- (BOOL)clearsContextBeforeDrawing { return _clearsContextBeforeDrawing; }
- (void)setClearsContextBeforeDrawing:(BOOL)clears
{
    _clearsContextBeforeDrawing = clears;
}
- (BOOL)isExclusiveTouch { return _exclusiveTouch; }
- (void)setExclusiveTouch:(BOOL)exclusive { _exclusiveTouch = exclusive; }
- (BOOL)isMultipleTouchEnabled { return _multipleTouchEnabled; }
- (void)setMultipleTouchEnabled:(BOOL)enabled
{
    _multipleTouchEnabled = enabled;
}
- (BOOL)autoresizesSubviews { return _autoresizesSubviews; }
- (void)setAutoresizesSubviews:(BOOL)resizes
{
    _autoresizesSubviews = resizes;
}
- (unsigned long)autoresizingMask { return _autoresizingMask; }
- (void)setAutoresizingMask:(unsigned long)mask { _autoresizingMask = mask; }
- (double)contentScaleFactor
{
    return _contentScaleFactor > 0 ? _contentScaleFactor
                                   : [[UIScreen mainScreen] scale];
}
- (void)setContentScaleFactor:(double)scale
{
    _contentScaleFactor = scale;
}
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
- (UIWindow *)window
{
    UIView *view = self;
    while (view)
    {
        if ([view isKindOfClass:[UIWindow class]])
            return (UIWindow *)view;
        view = (UIView *)view->_superview;
    }
    return nil;
}
- (UIResponder *)nextResponder { return _superview; }
- (CGAffineTransform)transform { return _transform; }
- (void)setTransform:(CGAffineTransform)transform
{
    if (g_animating)
    {
        _animTransformFrom = current_transform(self);
        _animTransformTo = transform;
        _animStart = g_animStart;
        _animDuration = g_animDuration;
        _animDelay = g_animateDelay;
        _animInfinite = g_animateInfinite;
        _animAutoreverse = g_animateAutoreverse;
        _animCurve = g_animateCurve;
        _animatingTransform = YES;
        animation_mark_active(g_animDuration + g_animateDelay,
                              g_animateInfinite ? -1 : 0);
    }
    _transform = transform;
}
- (void)layoutSubviews { }
- (void)drawRect:(CGRect)rect { (void)rect; }
- (void)setNeedsLayout { _needsLayout = YES; }
- (void)setNeedsDisplay { }
- (void)setNeedsDisplayInRect:(CGRect)rect { (void)rect; }
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
    }
    UIEdgeInsets insets = [self safeAreaInsets];
    _safeAreaGuide->_topInset = insets.top;
    _safeAreaGuide->_bottomInset = insets.bottom;
    _safeAreaGuide->_leftInset = insets.left;
    _safeAreaGuide->_rightInset = insets.right;
    return _safeAreaGuide;
}
- (UIEdgeInsets)safeAreaInsets
{
    UIEdgeInsets base = UIEdgeInsetsMake(0, 0, 0, 0);
    if (!_superview)
    {
        const char *top = getenv("IOSIM_SAFE_TOP");
        const char *bottom = getenv("IOSIM_SAFE_BOTTOM");
        base = UIEdgeInsetsMake(top ? atof(top) : 62.0, 0,
                                bottom ? atof(bottom) : 34.0, 0);
    }
    return UIEdgeInsetsMake(base.top + _additionalSafeAreaInsets.top,
                            base.left + _additionalSafeAreaInsets.left,
                            base.bottom + _additionalSafeAreaInsets.bottom,
                            base.right + _additionalSafeAreaInsets.right);
}
- (void)safeAreaInsetsDidChange { }
- (UIEdgeInsets)layoutMargins
{
    if (_preservesSuperviewLayoutMargins && _superview)
    {
        UIEdgeInsets parent = [(UIView *)_superview layoutMargins];
        return UIEdgeInsetsMake(parent.top, parent.left, parent.bottom,
                                parent.right);
    }
    return _layoutMargins;
}
- (void)setLayoutMargins:(UIEdgeInsets)margins
{
    _layoutMargins = margins;
}
- (UILayoutGuide *)layoutMarginsGuide
{
    if (!_layoutMarginsGuide)
    {
        _layoutMarginsGuide = [[UILayoutGuide alloc] init];
        _layoutMarginsGuide->_owningView = self;
    }
    UIEdgeInsets margins = [self layoutMargins];
    _layoutMarginsGuide->_topInset = margins.top;
    _layoutMarginsGuide->_bottomInset = margins.bottom;
    _layoutMarginsGuide->_leftInset = margins.left;
    _layoutMarginsGuide->_rightInset = margins.right;
    return _layoutMarginsGuide;
}
- (UILayoutGuide *)readableContentGuide
{
    if (!_readableGuide)
    {
        _readableGuide = [[UILayoutGuide alloc] init];
        _readableGuide->_owningView = self;
        _readableGuide->_leftInset = 16;
        _readableGuide->_rightInset = 16;
        _readableGuide->_identifier = @"ReadableContentGuide";
    }
    return _readableGuide;
}
- (BOOL)preservesSuperviewLayoutMargins
{
    return _preservesSuperviewLayoutMargins;
}
- (void)setPreservesSuperviewLayoutMargins:(BOOL)preserves
{
    _preservesSuperviewLayoutMargins = preserves;
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
    if (_hidden || !_userInteractionEnabled || current_alpha(self) < 0.01)
        return nil;
    /* The point arrives in this view's frame box; invert the (possibly
     * animating) transform around the box center to reach the untransformed
     * coordinate space that bounds and subview frames are laid out in. */
    CGPoint local = view_untransform_point(self, point);
    if (![self pointInside:local])
        return nil;
    for (int i = _subviewCount - 1; i >= 0; i--)
    {
        UIView *sub = (UIView *)_subviews[i];
        CGPoint subPoint = CGPointMake(local.x - sub->_frame.origin.x,
                                       local.y - sub->_frame.origin.y);
        UIView *hit = [sub hitTest:subPoint];
        if (hit)
            return hit;
    }
    return self;
}
+ (BOOL)areAnimationsEnabled { return g_animationsEnabled; }
+ (void)setAnimationsEnabled:(BOOL)enabled { g_animationsEnabled = enabled; }
+ (void)performWithoutAnimation:(void (^)(void))actionsWithoutAnimation
{
    if (!actionsWithoutAnimation)
        return;
    BOOL previous = g_animationsEnabled;
    g_animationsEnabled = NO;
    actionsWithoutAnimation();
    g_animationsEnabled = previous;
}
+ (void)animateKeyframesWithDuration:(double)duration delay:(double)delay
                             options:(unsigned long)options
                          animations:(void (^)(void))animations
                          completion:(void (^)(BOOL finished))completion
{
    (void)options;
    if (!animations)
        return;
    if (!g_animationsEnabled)
    {
        animations();
        if (completion)
            completion(YES);
        return;
    }
    g_keyframeActive = 1;
    g_keyframeDuration = duration > 0 ? duration : 0.25;
    g_keyframeDelay = delay;
    animations();
    g_keyframeActive = 0;
    if (completion)
        animation_add_completion(delay + g_keyframeDuration, completion);
}
+ (void)addKeyframeWithRelativeStartTime:(double)start
                        relativeDuration:(double)duration
                              animations:(void (^)(void))animations
{
    if (!g_keyframeActive)
        return;
    keyframe_add(start, duration, animations);
}
+ (void)transitionWithView:(UIView *)view duration:(double)duration
                   options:(unsigned long)options
                animations:(void (^)(void))animations
                completion:(void (^)(BOOL finished))completion
{
    (void)view;
    (void)duration;
    (void)options;
    if (animations)
        animations();
    if (completion)
        completion(YES);
}
+ (void)transitionFromView:(UIView *)fromView toView:(UIView *)toView
                  duration:(double)duration
                   options:(unsigned long)options
                completion:(void (^)(BOOL finished))completion
{
    (void)duration;
    (void)options;
    UIView *parent = [fromView superview];
    if (parent && toView)
    {
        [toView setFrame:[fromView frame]];
        [fromView removeFromSuperview];
        [parent addSubview:toView];
    }
    if (completion)
        completion(YES);
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
    if (!g_animationsEnabled)
    {
        animations();
        if (!repeat && completion)
            completion(YES);
        return;
    }
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

@implementation UIViewPropertyAnimator
- (id)initWithDuration:(double)duration
                 curve:(long)curve
            animations:(void (^)(void))animations
{
    self = [super init];
    if (self)
    {
        _duration = duration;
        _state = UIViewAnimatingStateInactive;
        _interruptible = YES;
        _userInteractionEnabled = YES;
        _scrubsLinearly = YES;
        _animations = [NSMutableArray array];
        _completions = [NSMutableArray array];
        (void)curve;
        [self addAnimations:animations];
    }
    return self;
}
- (id)initWithDuration:(double)duration
          dampingRatio:(double)ratio
            animations:(void (^)(void))animations
{
    (void)ratio;
    return [self initWithDuration:duration
                            curve:UIViewAnimationCurveEaseInOut
                       animations:animations];
}
- (id)initWithDuration:(double)duration
         controlPoint1:(CGPoint)point1
         controlPoint2:(CGPoint)point2
            animations:(void (^)(void))animations
{
    (void)point1;
    (void)point2;
    return [self initWithDuration:duration
                            curve:UIViewAnimationCurveEaseInOut
                       animations:animations];
}
- (double)duration { return _duration; }
- (double)fractionComplete { return _fractionComplete; }
- (void)setFractionComplete:(double)fraction
{
    if (fraction < 0)
        fraction = 0;
    if (fraction > 1)
        fraction = 1;
    _fractionComplete = fraction;
    if (fraction > 0 && _state == UIViewAnimatingStateInactive && !_completed)
    {
        [self runAnimations];
        _state = UIViewAnimatingStateActive;
    }
}
- (BOOL)isReversed { return _reversed; }
- (void)setReversed:(BOOL)reversed { _reversed = reversed; }
- (long)state { return _state; }
- (BOOL)isRunning { return _state == UIViewAnimatingStateActive; }
- (BOOL)isInterruptible { return _interruptible; }
- (void)setInterruptible:(BOOL)interruptible
{
    _interruptible = interruptible;
}
- (BOOL)isUserInteractionEnabled { return _userInteractionEnabled; }
- (void)setUserInteractionEnabled:(BOOL)enabled
{
    _userInteractionEnabled = enabled;
}
- (BOOL)scrubsLinearly { return _scrubsLinearly; }
- (void)setScrubsLinearly:(BOOL)linear { _scrubsLinearly = linear; }
- (BOOL)pausesOnCompletion { return _pausesOnCompletion; }
- (void)setPausesOnCompletion:(BOOL)pauses { _pausesOnCompletion = pauses; }
- (void)addAnimations:(void (^)(void))animations
{
    if (!animations)
        return;
    [(NSMutableArray *)_animations
        addObject:(id)_Block_copy((void *)animations)];
}
- (void)addAnimations:(void (^)(void))animations delayFactor:(double)factor
{
    (void)factor;
    [self addAnimations:animations];
}
- (void)addCompletion:(void (^)(long position))completion
{
    if (!completion)
        return;
    [(NSMutableArray *)_completions
        addObject:(id)_Block_copy((void *)completion)];
}
- (void)runAnimations
{
    for (unsigned long i = 0; i < [(NSArray *)_animations count]; i++)
    {
        void (^block)(void) =
            (void (^)(void))[(NSArray *)_animations objectAtIndex:i];
        block();
    }
}
- (void)completeWithPosition:(long)position
{
    if (_completed)
        return;
    _completed = YES;
    _state = UIViewAnimatingStateInactive;
    _fractionComplete =
        position == UIViewAnimatingPositionStart ? 0 : 1;
    for (unsigned long i = 0; i < [(NSArray *)_completions count]; i++)
    {
        void (^block)(long) =
            (void (^)(long))[(NSArray *)_completions objectAtIndex:i];
        block(position);
    }
}
- (void)startAnimation
{
    [self startAnimationAfterDelay:0];
}
- (void)startAnimationAfterDelay:(double)delay
{
    if (_state != UIViewAnimatingStateInactive || _completed)
        return;
    _state = UIViewAnimatingStateActive;
    if ([(NSArray *)_animations count] == 0)
    {
        [self completeWithPosition:UIViewAnimatingPositionEnd];
        return;
    }
    void (^run)(void) = ^{ [self runAnimations]; };
    [UIView animateWithDuration:_duration
                          delay:delay
                        options:0
                     animations:run
                     completion:^(BOOL finished) {
        [self completeWithPosition:finished
            ? UIViewAnimatingPositionEnd : UIViewAnimatingPositionCurrent];
    }];
}
- (void)pauseAnimation
{
    if (_state == UIViewAnimatingStateActive)
        _state = UIViewAnimatingStateActive;
}
- (void)stopAnimation:(BOOL)withoutFinishing
{
    (void)withoutFinishing;
    _state = UIViewAnimatingStateStopped;
    [self completeWithPosition:UIViewAnimatingPositionCurrent];
}
- (void)finishAnimationAtPosition:(long)position
{
    if (_completed)
        return;
    if (_state == UIViewAnimatingStateInactive)
        [self runAnimations];
    [self completeWithPosition:position];
}
- (void)continueAnimationWithTimingParameters:(id)parameters
                                durationFactor:(double)factor
{
    (void)parameters;
    (void)factor;
}
@end

@implementation UIAccessibilityElement
- (id)initWithAccessibilityContainer:(id)container
{
    self = [super init];
    if (self)
    {
        _accessibilityContainer = container;
        _isAccessibilityElement = YES;
    }
    return self;
}
- (id)accessibilityContainer { return _accessibilityContainer; }
- (BOOL)isAccessibilityElement { return _isAccessibilityElement; }
- (void)setIsAccessibilityElement:(BOOL)element
{
    _isAccessibilityElement = element;
}
- (id)accessibilityLabel { return _accessibilityLabel; }
- (void)setAccessibilityLabel:(id)label { _accessibilityLabel = label; }
- (id)accessibilityIdentifier { return _accessibilityIdentifier; }
- (void)setAccessibilityIdentifier:(id)identifier
{
    _accessibilityIdentifier = identifier;
}
- (id)accessibilityHint { return _accessibilityHint; }
- (void)setAccessibilityHint:(id)hint { _accessibilityHint = hint; }
- (id)accessibilityValue { return _accessibilityValue; }
- (void)setAccessibilityValue:(id)value { _accessibilityValue = value; }
- (unsigned long long)accessibilityTraits { return _accessibilityTraits; }
- (void)setAccessibilityTraits:(unsigned long long)traits
{
    _accessibilityTraits = traits;
}
- (CGRect)accessibilityFrame { return _accessibilityFrame; }
- (void)setAccessibilityFrame:(CGRect)frame
{
    _accessibilityFrame = frame;
}
@end

/* Label text fitting helpers. A single-line label either shrinks when
 * adjustsFontSizeToFitWidth is set or truncates according to its line
 * break mode; clipping keeps the whole string. */

static int label_next_byte(const char *text, int index)
{
    index++;
    while (text[index] && ((unsigned char)text[index] & 0xC0) == 0x80)
        index++;
    return index;
}

static int label_prev_byte(const char *text, int index)
{
    if (index <= 0)
        return 0;
    index--;
    while (index > 0 && ((unsigned char)text[index] & 0xC0) == 0x80)
        index--;
    return index;
}

/* Shrink a label's font to fit maxWidth pixels, bounded by
 * minimumScaleFactor. Returns the effective point size and reports the
 * measured width. */
static double label_shrunk_points(UILabel *label, const char *text,
                                  int style, double scale, int maxWidth,
                                  int *outWidth)
{
    double basePoints = label->_font ? label->_font->_size : 17.0;
    double points = basePoints;
    int width = iosim_fb_font_text_width(text, style, points, scale);
    if (label->_adjustsFontSizeToFitWidth && maxWidth > 0)
    {
        double minScale = label->_minimumScaleFactor;
        if (minScale > 1.0)
            minScale = 1.0;
        if (minScale < 0.0)
            minScale = 0.0;
        double floorPoints =
            minScale > 0.0 ? basePoints * minScale : 1.0;
        while (width > maxWidth && points > floorPoints)
        {
            points -= 0.5;
            if (points < floorPoints)
                points = floorPoints;
            width = iosim_fb_font_text_width(text, style, points, scale);
        }
    }
    if (outWidth)
        *outWidth = width;
    return points;
}

/* Copy text into out, truncating for maxWidth pixels. Modes 3, 4 and 5
 * insert an ellipsis at the head, tail and middle; mode 2 clips. */
static void label_ellipsized(const char *text, int style, double points,
                             double scale, int maxWidth, long mode,
                             char *out, int outSize)
{
    if (outSize <= 0)
        return;
    int len = text ? (int)strlen(text) : 0;
    int n = 0;
    while (n < len && n < outSize - 1)
    {
        out[n] = text[n];
        n++;
    }
    out[n] = 0;
    if (!text || n == 0 || maxWidth <= 0 || mode == 2)
        return;
    if (iosim_fb_font_text_width(out, style, points, scale) <= maxWidth)
        return;
    const char *dots = "...";
    if (iosim_fb_font_text_width(dots, style, points, scale) > maxWidth)
    {
        out[0] = 0;
        return;
    }
    char cand[256];
    if (mode == 3 || mode == 5)
    {
        int head = 0, tail = 0;
        if (mode == 5)
        {
            head = len / 2;
            tail = len / 2;
        }
        for (;;)
        {
            n = 0;
            if (mode == 3)
            {
                cand[n++] = '.';
                cand[n++] = '.';
                cand[n++] = '.';
            }
            for (int i = 0; i < head && n < 255; i++)
                cand[n++] = text[i];
            if (mode == 5)
            {
                cand[n++] = '.';
                cand[n++] = '.';
                cand[n++] = '.';
            }
            for (int i = tail; i < len && n < 255; i++)
                cand[n++] = text[i];
            cand[n] = 0;
            if (iosim_fb_font_text_width(cand, style, points, scale) <=
                maxWidth)
                break;
            if (mode == 3)
            {
                if (tail >= len)
                {
                    cand[0] = 0;
                    break;
                }
                tail = label_next_byte(text, tail);
            }
            else if (head >= len - tail)
            {
                if (head <= 0)
                {
                    cand[0] = 0;
                    break;
                }
                head = label_prev_byte(text, head);
            }
            else if (tail < len)
                tail = label_next_byte(text, tail);
            else
            {
                cand[0] = 0;
                break;
            }
        }
        n = 0;
        while (cand[n] && n < outSize - 1)
        {
            out[n] = cand[n];
            n++;
        }
        out[n] = 0;
        return;
    }
    /* Word wrapping, character wrapping and truncating tail keep the
     * leading text and append an ellipsis. */
    int keep = len;
    for (;;)
    {
        n = 0;
        for (int i = 0; i < keep && n < 255; i++)
            cand[n++] = text[i];
        cand[n++] = '.';
        cand[n++] = '.';
        cand[n++] = '.';
        cand[n] = 0;
        if (iosim_fb_font_text_width(cand, style, points, scale) <= maxWidth)
            break;
        if (keep <= 0)
        {
            cand[0] = '.';
            cand[1] = '.';
            cand[2] = '.';
            cand[3] = 0;
            break;
        }
        keep = label_prev_byte(text, keep);
    }
    n = 0;
    while (cand[n] && n < outSize - 1)
    {
        out[n] = cand[n];
        n++;
    }
    out[n] = 0;
}

@implementation UILabel
- (id)init
{
    self = [super init];
    if (self)
    {
        _numberOfLines = 1;
        _lineBreakMode = 4;
        _accessibilityTraits = 64;
    }
    return self;
}
- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        _numberOfLines = 1;
        _lineBreakMode = 4;
        _accessibilityTraits = 64;
    }
    return self;
}
- (BOOL)isAccessibilityElement { return YES; }
- (id)accessibilityLabel
{
    return _accessibilityLabel ? _accessibilityLabel : _text;
}
- (void)setText:(id)text { _text = text; _attributedText = nil; }
- (id)text { return _text; }
- (void)setAttributedText:(id)text
{
    _attributedText = text;
    _text = [text string];
    NSRange range;
    id attributes = [text attributesAtIndex:0 effectiveRange:&range];
    id font = [attributes objectForKey:NSFontAttributeName];
    if (font)
        _font = font;
    id color = [attributes objectForKey:NSForegroundColorAttributeName];
    if (color)
        _textColor = color;
}
- (id)attributedText { return _attributedText; }
- (void)setTextColor:(UIColor *)color { _textColor = color; }
- (UIColor *)textColor { return _textColor; }
- (void)setFont:(UIFont *)font { _font = font; }
- (UIFont *)font { return _font; }
- (void)setTextAlignment:(int)alignment { _textAlignment = alignment; }
- (int)textAlignment { return _textAlignment; }
- (void)setNumberOfLines:(int)n { _numberOfLines = n; }
- (int)numberOfLines { return _numberOfLines; }
- (long)lineBreakMode { return _lineBreakMode; }
- (void)setLineBreakMode:(long)mode { _lineBreakMode = mode; }
- (double)preferredMaxLayoutWidth { return _preferredMaxLayoutWidth; }
- (void)setPreferredMaxLayoutWidth:(double)width
{
    _preferredMaxLayoutWidth = width;
}
- (BOOL)adjustsFontSizeToFitWidth { return _adjustsFontSizeToFitWidth; }
- (void)setAdjustsFontSizeToFitWidth:(BOOL)adjusts
{
    _adjustsFontSizeToFitWidth = adjusts;
}
- (double)minimumScaleFactor { return _minimumScaleFactor; }
- (void)setMinimumScaleFactor:(double)scale { _minimumScaleFactor = scale; }
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
- (CGRect)textRectForBounds:(CGRect)bounds
     limitedToNumberOfLines:(int)numberOfLines
{
    const char *text = iosim_string_cstr(_text);
    if (!text || !*text)
        return CGRectMake(0, 0, 0, 0);
    double scale = [[UIScreen mainScreen] scale];
    int style = _font && _font->_bold ? IOSIM_FONT_BOLD : IOSIM_FONT_REGULAR;
    int maxWidth = (int)(bounds.size.width * scale + 0.5);
    if (maxWidth < 0)
        maxWidth = 0;
    if (numberOfLines == 1)
    {
        int width = 0;
        double points =
            label_shrunk_points(self, text, style, scale, maxWidth, &width);
        char fitted[256];
        if (maxWidth > 0 && width > maxWidth)
        {
            label_ellipsized(text, style, points, scale, maxWidth,
                             _lineBreakMode, fitted, sizeof fitted);
            text = fitted;
            width = iosim_fb_font_text_width(text, style, points, scale);
        }
        int ascent = 0, descent = 0, lineHeight = 0;
        iosim_fb_font_metrics(style, points, scale, &ascent, &descent,
                              &lineHeight);
        return CGRectMake(bounds.origin.x, bounds.origin.y, width / scale,
                          lineHeight / scale);
    }
    double points = _font ? _font->_size : 17.0;
    int ascent = 0, descent = 0, lineHeight = 0;
    iosim_fb_font_metrics(style, points, scale, &ascent, &descent,
                          &lineHeight);
    if (maxWidth <= 0)
        return CGRectMake(bounds.origin.x, bounds.origin.y,
                          [self intrinsicContentSize].width,
                          lineHeight / scale);
    char lines[IOSIM_MAX_WRAP_LINES][256];
    int maxLines = numberOfLines > 1 ? numberOfLines : IOSIM_MAX_WRAP_LINES;
    int count = wrap_text_lines(text, style, points, scale, maxWidth, lines,
                                maxLines);
    int maxLineWidth = 0;
    for (int i = 0; i < count; i++)
    {
        int lineWidth =
            iosim_fb_font_text_width(lines[i], style, points, scale);
        if (lineWidth > maxLineWidth)
            maxLineWidth = lineWidth;
    }
    return CGRectMake(bounds.origin.x, bounds.origin.y, maxLineWidth / scale,
                      (double)count * lineHeight / scale);
}
@end

static id g_firstResponder;

/* Editable multiline text view: text is appended at the end, wrapped with
 * spaces preserved, and drawn with a caret while first responder. */
@implementation UITextView
static unsigned long text_byte_length(id text)
{
    const char *s = text ? iosim_string_cstr(text) : 0;
    return s ? strlen(s) : 0;
}

static int text_ascii_alnum(char c)
{
    return (c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z') ||
           (c >= '0' && c <= '9') || c == '_';
}

static NSRange text_word_range(const char *text, unsigned long index)
{
    unsigned long length = text ? strlen(text) : 0;
    if (!text || length == 0)
        return NSMakeRange(0, 0);
    if (index > length)
        index = length;
    unsigned long start = index;
    unsigned long end = index;
    while (start > 0 && text_ascii_alnum(text[start - 1]))
        start--;
    while (end < length && text_ascii_alnum(text[end]))
        end++;
    if (start == end && start > 0)
        start--;
    if (start == end && end < length)
        end++;
    return NSMakeRange(start, end - start);
}

static unsigned long text_index_at_point(UITextView *editor, CGPoint point)
{
    const char *text = editor->_text ? iosim_string_cstr(editor->_text) : "";
    if (!text)
        return 0;
    unsigned long length = strlen(text);
    double scale = [[UIScreen mainScreen] scale];
    if (scale <= 0)
        scale = 1.0;
    double points = editor->_font ? editor->_font->_size : 17.0;
    int style = editor->_font && editor->_font->_bold ? IOSIM_FONT_BOLD
                                                       : IOSIM_FONT_REGULAR;
    int ascent = 0, descent = 0, lineHeight = 0;
    iosim_fb_font_metrics(style, points, scale, &ascent, &descent,
                          &lineHeight);
    double line_height_pts = lineHeight / scale;
    if (line_height_pts <= 0)
        return length;
    double width = editor->_frame.size.width - 24.0;
    if (width <= 0)
        return length;
    char lines[IOSIM_MAX_WRAP_LINES][256];
    int count = wrap_editable_lines(text, style, points, scale,
                                   (int)(width * scale + 0.5), lines,
                                   IOSIM_MAX_WRAP_LINES);
    if (count <= 0)
        return 0;
    int line = (int)((point.y - 12.0) / line_height_pts);
    if (line < 0)
        return 0;
    if (line >= count)
        return length;
    unsigned long start = 0;
    for (int i = 0; i < line; i++)
        start += strlen(lines[i]) + 1;
    if (start > length)
        start = length;
    const char *line_text = lines[line];
    double target = point.x - 12.0;
    unsigned long prefix = 0;
    char probe[256];
    while (line_text[prefix])
    {
        int n = (int)prefix + 1;
        if (n > 255)
            break;
        memcpy(probe, line_text, (unsigned long)n);
        probe[n] = 0;
        int width_px = iosim_fb_font_text_width(probe, style, points, scale);
        if (width_px / scale > target)
            break;
        prefix++;
    }
    unsigned long index = start + prefix;
    return index > length ? length : index;
}

/* Convert a byte index into the top-left pixel position of the glyph run on
 * its wrapped line. Used for the caret and the selection handle stems. */
static void text_index_line_position(const char (*lines)[256], int n,
                                     int style, double points, double scale,
                                     int inset, int x, int y, int lineHeight,
                                     unsigned long index, int *out_x,
                                     int *out_y)
{
    unsigned long remaining = index;
    for (int i = 0; i < n; i++)
    {
        int length = (int)strlen(lines[i]);
        if (remaining <= (unsigned long)length || i == n - 1)
        {
            int offset = (int)(remaining > (unsigned long)length
                                   ? (unsigned long)length
                                   : remaining);
            char prefix[256];
            if (offset > 255)
                offset = 255;
            memcpy(prefix, lines[i], (unsigned long)offset);
            prefix[offset] = 0;
            *out_x = x + inset + iosim_fb_font_text_width(prefix, style,
                                                          points, scale);
            *out_y = y + inset + i * lineHeight;
            return;
        }
        remaining -= (unsigned long)length;
        if (remaining > 0)
            remaining--;
    }
    *out_x = x + inset;
    *out_y = y + inset;
}

/* Byte index to a point in the text view's own coordinate space: x at the
 * glyph run and y at the bottom of its line. */
static void text_index_point_in_view(UITextView *editor,
                                     unsigned long index, CGPoint *out)
{
    const char *text = editor->_text ? iosim_string_cstr(editor->_text) : "";
    if (!text)
        text = "";
    unsigned long length = strlen(text);
    if (index > length)
        index = length;
    double scale = [[UIScreen mainScreen] scale];
    if (scale <= 0)
        scale = 1.0;
    double points = editor->_font ? editor->_font->_size : 17.0;
    int style = editor->_font && editor->_font->_bold ? IOSIM_FONT_BOLD
                                                       : IOSIM_FONT_REGULAR;
    int ascent = 0, descent = 0, lineHeight = 0;
    iosim_fb_font_metrics(style, points, scale, &ascent, &descent,
                          &lineHeight);
    double line_height_pts = lineHeight / scale;
    if (line_height_pts <= 0)
        line_height_pts = points * 1.2;
    double width = editor->_frame.size.width - 24.0;
    if (width <= 0)
    {
        out->x = 12.0;
        out->y = 12.0 + line_height_pts;
        return;
    }
    char lines[IOSIM_MAX_WRAP_LINES][256];
    int count = wrap_editable_lines(text, style, points, scale,
                                    (int)(width * scale + 0.5), lines,
                                    IOSIM_MAX_WRAP_LINES);
    int px = 0, py = 0;
    if (count <= 0)
    {
        out->x = 12.0;
        out->y = 12.0 + line_height_pts;
        return;
    }
    text_index_line_position((const char (*)[256])lines, count, style,
                             points, scale, 0, 0, 0, lineHeight, index,
                             &px, &py);
    out->x = 12.0 + px / scale;
    out->y = 12.0 + py / scale + line_height_pts;
}

/* Place the edit menu above the selected text. */
static void text_view_show_edit_menu(UITextView *editor)
{
    NSRange selection = editor->_selectedRange;
    if (selection.length == 0)
        return;
    CGPoint start, end;
    text_index_point_in_view(editor, selection.location, &start);
    text_index_point_in_view(editor, selection.location + selection.length,
                             &end);
    double scale = [[UIScreen mainScreen] scale];
    if (scale <= 0)
        scale = 1.0;
    double points = editor->_font ? editor->_font->_size : 17.0;
    int style = editor->_font && editor->_font->_bold ? IOSIM_FONT_BOLD
                                                       : IOSIM_FONT_REGULAR;
    int ascent = 0, descent = 0, lineHeight = 0;
    iosim_fb_font_metrics(style, points, scale, &ascent, &descent,
                          &lineHeight);
    double line_height_pts = lineHeight / scale;
    if (line_height_pts <= 0)
        line_height_pts = points * 1.2;
    CGRect rect;
    if (__builtin_fabs(end.y - start.y) < 0.5)
        rect = CGRectMake(start.x, start.y - line_height_pts,
                          end.x - start.x, line_height_pts);
    else
        rect = CGRectMake(0, start.y - line_height_pts,
                          editor->_frame.size.width, end.y - start.y);
    [[UIMenuController sharedMenuController] setTargetRect:rect
                                                    inView:editor];
    [[UIMenuController sharedMenuController] setMenuVisible:YES];
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        _text = [NSString stringWithUTF8String:@""];
        _font = [UIFont systemFontOfSize:17];
        _textColor = [UIColor whiteColor];
        _editable = YES;
        _selectedRange = NSMakeRange(0, 0);
    }
    return self;
}
- (id)text { return _text; }
- (void)setText:(id)text
{
    _text = text;
    _attributedText = nil;
    _selectedRange = NSMakeRange(text_byte_length(text), 0);
    _needsLayout = YES;
}
- (void)setAttributedText:(id)text
{
    _attributedText = text;
    _text = [text string];
    _selectedRange = NSMakeRange(text_byte_length(_text), 0);
    _needsLayout = YES;
}
- (id)attributedText { return _attributedText; }
- (NSRange)selectedRange { return _selectedRange; }
- (void)setSelectedRange:(NSRange)range
{
    unsigned long length = text_byte_length(_text);
    if (range.location > length)
        range.location = length;
    if (range.length > length - range.location)
        range.length = length - range.location;
    _selectedRange = range;
    _needsLayout = YES;
}
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
    (void)event;
    UITouch *touch = [touches anyObject];
    CGPoint point = touch ? [touch locationInView:self] : CGPointMake(0, 0);
    [[UIMenuController sharedMenuController] setMenuVisible:NO];
    const char *text = _text ? iosim_string_cstr(_text) : "";
    unsigned long index = text_index_at_point(self, point);
    if (_selectedRange.length > 0)
    {
        CGPoint start_pt, end_pt;
        unsigned long selection_start = _selectedRange.location;
        unsigned long selection_end = selection_start + _selectedRange.length;
        text_index_point_in_view(self, selection_start, &start_pt);
        text_index_point_in_view(self, selection_end, &end_pt);
        start_pt.y += 6.0;
        end_pt.y += 6.0;
        double ds = (point.x - start_pt.x) * (point.x - start_pt.x) +
                    (point.y - start_pt.y) * (point.y - start_pt.y);
        double de = (point.x - end_pt.x) * (point.x - end_pt.x) +
                    (point.y - end_pt.y) * (point.y - end_pt.y);
        if (ds <= 196.0 || de <= 196.0)
        {
            _dragHandle = ds <= de ? 1 : 2;
            _dragAnchor = _dragHandle == 1 ? selection_end : selection_start;
            _dragging = YES;
            if (_editable)
                [self becomeFirstResponder];
            _needsLayout = YES;
            return;
        }
    }
    _dragHandle = 0;
    double now = iosim_now();
    _pressPoint = point;
    _pressStartTime = now;
    _pressIndex = index;
    _pressPending = YES;
    g_pendingPressEditor = self;
    if (now - _lastTapTime < 0.35)
    {
        NSRange word = text_word_range(text, index);
        if (word.length > 0)
        {
            [self setSelectedRange:word];
            _lastTapIndex = index;
            _dragAnchor = word.location;
            _dragging = YES;
            text_view_show_edit_menu(self);
        }
        else
        {
            [self setSelectedRange:NSMakeRange(index, 0)];
            _dragAnchor = index;
            _dragging = NO;
        }
    }
    else
    {
        [self setSelectedRange:NSMakeRange(index, 0)];
        _lastTapIndex = index;
        _dragAnchor = index;
        _dragging = NO;
    }
    _lastTapTime = now;
    if (_editable)
        [self becomeFirstResponder];
    _needsLayout = YES;
}
- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    (void)event;
    UITouch *touch = [touches anyObject];
    CGPoint point = touch ? [touch locationInView:self] : CGPointMake(0, 0);
    if (_pressPending)
    {
        double dx = point.x - _pressPoint.x;
        double dy = point.y - _pressPoint.y;
        if (dx * dx + dy * dy > 100.0)
        {
            _pressPending = NO;
            if (g_pendingPressEditor == self)
                g_pendingPressEditor = 0;
        }
    }
    unsigned long index;
    if (_dragHandle == 1 || _dragHandle == 2)
    {
        /* The knob sits below its line; sample the index on that line. */
        CGPoint anchor_pt;
        text_index_point_in_view(self, _dragAnchor, &anchor_pt);
        index = text_index_at_point(
            self, CGPointMake(point.x, anchor_pt.y - 1.0));
    }
    else
    {
        index = text_index_at_point(self, point);
    }
    if (_dragHandle == 1)
    {
        unsigned long end = _dragAnchor;
        unsigned long start = index > end ? end : index;
        [self setSelectedRange:NSMakeRange(start, end - start)];
        return;
    }
    if (_dragHandle == 2)
    {
        unsigned long start = _dragAnchor;
        unsigned long finish = index < start ? start : index;
        [self setSelectedRange:NSMakeRange(start, finish - start)];
        return;
    }
    if (!_dragging)
    {
        if (index == _dragAnchor)
            return;
        _dragging = YES;
    }
    unsigned long start = _dragAnchor < index ? _dragAnchor : index;
    unsigned long end = _dragAnchor < index ? index : _dragAnchor;
    [self setSelectedRange:NSMakeRange(start, end - start)];
}
- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    (void)touches;
    (void)event;
    _dragging = NO;
    _dragHandle = 0;
    _pressPending = NO;
    if (g_pendingPressEditor == self)
        g_pendingPressEditor = 0;
}
- (void)insertText:(id)text
{
    if (!text)
        return;
    const char *add = iosim_string_cstr(text);
    if (!add)
        return;
    const char *current = _text ? iosim_string_cstr(_text) : "";
    if (!current)
        current = "";
    unsigned long length = strlen(current);
    unsigned long location = _selectedRange.location;
    unsigned long selected = _selectedRange.length;
    if (location > length)
        location = length;
    if (selected > length - location)
        selected = length - location;
    unsigned long add_len = strlen(add);
    char *copy = malloc(length - selected + add_len + 1);
    if (!copy)
        return;
    memcpy(copy, current, location);
    memcpy(copy + location, add, add_len);
    memcpy(copy + location + add_len, current + location + selected,
           length - location - selected);
    copy[length - selected + add_len] = 0;
    _text = [NSString stringWithUTF8String:copy];
    free(copy);
    _selectedRange = NSMakeRange(location + add_len, 0);
    _needsLayout = YES;
}
- (void)deleteBackward
{
    const char *current = _text ? iosim_string_cstr(_text) : "";
    if (!current)
        return;
    unsigned long length = strlen(current);
    unsigned long location = _selectedRange.location;
    unsigned long selected = _selectedRange.length;
    if (location > length)
        location = length;
    if (selected > length - location)
        selected = length - location;
    if (selected == 0)
    {
        if (location == 0)
            return;
        location--;
        selected = 1;
    }
    char *copy = malloc(length - selected + 1);
    if (!copy)
        return;
    memcpy(copy, current, location);
    memcpy(copy + location, current + location + selected,
           length - location - selected);
    copy[length - selected] = 0;
    _text = [NSString stringWithUTF8String:copy];
    free(copy);
    _selectedRange = NSMakeRange(location, 0);
    _needsLayout = YES;
}
- (void)copy:(id)sender
{
    (void)sender;
    const char *text = _text ? iosim_string_cstr(_text) : "";
    if (!text)
        return;
    unsigned long length = strlen(text);
    unsigned long location = _selectedRange.location;
    unsigned long count = _selectedRange.length;
    if (location > length)
        location = length;
    if (count > length - location)
        count = length - location;
    if (count == 0)
        return;
    char *copy = malloc(count + 1);
    if (!copy)
        return;
    memcpy(copy, text + location, count);
    copy[count] = 0;
    [[UIPasteboard generalPasteboard]
        setString:[NSString stringWithUTF8String:copy]];
    free(copy);
    _needsLayout = YES;
}
- (void)paste:(id)sender
{
    (void)sender;
    id string = [[UIPasteboard generalPasteboard] string];
    if (string)
        [self insertText:string];
}
@end

/* Once a held touch passes the long-press duration, select the word under
 * the original index. Called from the UI loop; returns 1 when the selection
 * changed so the caller redraws. */
static int iosim_text_press_tick(void)
{
    UITextView *editor = g_pendingPressEditor;
    if (!editor || !editor->_pressPending)
        return 0;
    if (iosim_now() - editor->_pressStartTime < 0.5)
        return 0;
    editor->_pressPending = NO;
    g_pendingPressEditor = 0;
    const char *text = editor->_text ? iosim_string_cstr(editor->_text) : "";
    if (!text)
        text = "";
    NSRange word = text_word_range(text, editor->_pressIndex);
    if (word.length > 0)
    {
        [editor setSelectedRange:word];
        editor->_dragAnchor = word.location;
        editor->_dragging = YES;
        editor->_dragHandle = 0;
        text_view_show_edit_menu(editor);
    }
    else
    {
        [editor setSelectedRange:NSMakeRange(editor->_pressIndex, 0)];
    }
    editor->_needsLayout = YES;
    return 1;
}

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
- (BOOL)isAccessibilityElement { return YES; }
- (id)accessibilityValue
{
    return _accessibilityValue ? _accessibilityValue : _text;
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
- (int)borderStyle { return _borderStyle; }
- (void)setBorderStyle:(int)style { _borderStyle = style; }
- (BOOL)clearsOnBeginEditing { return _clearsOnBeginEditing; }
- (void)setClearsOnBeginEditing:(BOOL)clears
{
    _clearsOnBeginEditing = clears;
}
- (id)leftView { return _leftView; }
- (void)setLeftView:(id)view { _leftView = view; }
- (id)rightView { return _rightView; }
- (void)setRightView:(id)view { _rightView = view; }
- (long)leftViewMode { return _leftViewMode; }
- (void)setLeftViewMode:(long)mode { _leftViewMode = mode; }
- (long)rightViewMode { return _rightViewMode; }
- (void)setRightViewMode:(long)mode { _rightViewMode = mode; }
- (long)clearButtonMode { return _clearButtonMode; }
- (void)setClearButtonMode:(long)mode { _clearButtonMode = mode; }
- (void)setDelegate:(id)delegate { _delegate = delegate; }
- (id)delegate { return _delegate; }
- (BOOL)becomeFirstResponder
{
    if (_delegate && [_delegate respondsToSelector:
            @selector(textFieldShouldBeginEditing:)])
    {
        if (!((BOOL (*)(id, SEL, id))objc_msgSend)(
                _delegate, @selector(textFieldShouldBeginEditing:), self))
            return NO;
    }
    if (g_firstResponder && g_firstResponder != self)
        [g_firstResponder resignFirstResponder];
    g_firstResponder = self;
    _firstResponder = YES;
    _needsLayout = YES;
    [self sendActionsForControlEvents:UIControlEventEditingDidBegin];
    if (_delegate && [_delegate respondsToSelector:
            @selector(textFieldDidBeginEditing:)])
        [(_delegate) textFieldDidBeginEditing:self];
    return YES;
}
- (BOOL)resignFirstResponder
{
    if (_delegate && [_delegate respondsToSelector:
            @selector(textFieldShouldEndEditing:)])
    {
        if (!((BOOL (*)(id, SEL, id))objc_msgSend)(
                _delegate, @selector(textFieldShouldEndEditing:), self))
            return NO;
    }
    int was = _firstResponder;
    if (g_firstResponder == self)
        g_firstResponder = 0;
    _firstResponder = NO;
    _needsLayout = YES;
    if (was)
    {
        [self sendActionsForControlEvents:UIControlEventEditingDidEnd];
        if (_delegate && [_delegate respondsToSelector:
                @selector(textFieldDidEndEditing:)])
            [(_delegate) textFieldDidEndEditing:self];
    }
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
    if (add[0] == '\n' && add[1] == 0)
    {
        [self handleReturnKey];
        return;
    }
    const char *cur = iosim_string_cstr(_text);
    NSRange range;
    range.location = cur ? strlen(cur) : 0;
    range.length = 0;
    if (_delegate && [_delegate respondsToSelector:
            @selector(textField:shouldChangeCharactersInRange:
                      replacementString:)])
    {
        BOOL allow = ((BOOL (*)(id, SEL, id, NSRange, id))objc_msgSend)(
            _delegate,
            @selector(textField:shouldChangeCharactersInRange:
                      replacementString:),
            self, range, text);
        if (!allow)
            return;
    }
    char buf[512];
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
    unsigned long end = strlen(cur);
    unsigned long n = end;
    while (n > 0 && ((unsigned char)cur[n - 1] & 0xc0) == 0x80)
        n--;
    if (n > 0)
        n--;
    NSRange range;
    range.location = n;
    range.length = end - n;
    if (_delegate && [_delegate respondsToSelector:
            @selector(textField:shouldChangeCharactersInRange:
                      replacementString:)])
    {
        BOOL allow = ((BOOL (*)(id, SEL, id, NSRange, id))objc_msgSend)(
            _delegate,
            @selector(textField:shouldChangeCharactersInRange:
                      replacementString:),
            self, range, [NSString stringWithUTF8String:""]);
        if (!allow)
            return;
    }
    char buf[512];
    if (n >= sizeof(buf))
        n = sizeof(buf) - 1;
    memcpy(buf, cur, n);
    buf[n] = 0;
    _text = [NSString stringWithUTF8String:buf];
    [self sendActionsForControlEvents:UIControlEventEditingChanged];
    _needsLayout = YES;
}
- (void)handleReturnKey
{
    BOOL allow = YES;
    if (_delegate && [_delegate respondsToSelector:
            @selector(textFieldShouldReturn:)])
        allow = ((BOOL (*)(id, SEL, id))objc_msgSend)(
            _delegate, @selector(textFieldShouldReturn:), self);
    if (allow)
        [self sendActionsForControlEvents:UIControlEventEditingDidEndOnExit];
}
- (CGSize)intrinsicContentSize
{
    return CGSizeMake(160, 34);
}
@end

/* The search field is a real UITextField so focus, the software keyboard
 * and hardware keys work; Return asks the bar to invoke its search action
 * instead of inserting a newline. */
@interface UISearchBarField : UITextField {
@public
    id _bar;
}
@end

@implementation UISearchBarField
- (void)insertText:(id)text
{
    const char *s = iosim_string_cstr(text);
    if (s && s[0] == '\n' && s[1] == 0)
    {
        if (_bar)
            [(UISearchBar *)_bar searchButtonClicked];
        return;
    }
    [super insertText:text];
}
- (void)handleReturnKey
{
    if (_bar)
        [(UISearchBar *)_bar searchButtonClicked];
}
@end

@implementation UISearchBar
- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        _placeholder = @"Search";
        [self setBackgroundColor:
            [UIColor colorWithRed:0.09 green:0.10 blue:0.13 alpha:0.95]];
        [[self layer] setCornerRadius:12];

        UISearchBarField *field = [[UISearchBarField alloc]
            initWithFrame:CGRectMake(8, 6, frame.size.width - 16,
                                     frame.size.height - 12)];
        field->_bar = self;
        field->_placeholder = _placeholder;
        field->_font = [UIFont systemFontOfSize:16];
        field->_textColor = [UIColor whiteColor];
        [field addTarget:self action:@selector(fieldChanged)
         forControlEvents:UIControlEventEditingChanged];
        [self addSubview:field];
        _field = field;

        UIControl *cancel = [[UIControl alloc] initWithFrame:
            CGRectMake(frame.size.width - 64, 6, 56,
                       frame.size.height - 12)];
        UILabel *label = [[UILabel alloc] initWithFrame:
            CGRectMake(0, 0, 56, frame.size.height - 12)];
        label->_text = @"Cancel";
        label->_font = [UIFont systemFontOfSize:15];
        label->_textColor = [UIColor whiteColor];
        label->_textAlignment = 1;
        [cancel addSubview:label];
        [cancel addTarget:self action:@selector(cancelTapped)
         forControlEvents:UIControlEventTouchUpInside];
        cancel->_hidden = YES;
        [self addSubview:cancel];
        _cancelButton = cancel;
        _needsLayout = YES;
    }
    return self;
}
- (void)setFrame:(CGRect)frame
{
    [super setFrame:frame];
    _needsLayout = YES;
}
- (void)setDelegate:(id)delegate { _delegate = delegate; }
- (id)delegate { return _delegate; }
- (id)text { return _field ? [(UITextField *)_field text] : nil; }
- (void)setText:(id)text
{
    if (_field)
        [(UITextField *)_field setText:text];
}
- (id)placeholder { return _placeholder; }
- (void)setPlaceholder:(id)text
{
    _placeholder = text;
    if (_field)
        [(UITextField *)_field setPlaceholder:text];
}
- (BOOL)showsCancelButton { return _showsCancelButton; }
- (NSArray *)scopeButtonTitles { return _scopeButtonTitles; }
- (void)setScopeButtonTitles:(NSArray *)titles
{
    _scopeButtonTitles = titles;
}
- (long)selectedScopeButtonIndex { return _selectedScopeButtonIndex; }
- (void)setSelectedScopeButtonIndex:(long)index
{
    _selectedScopeButtonIndex = index;
}
- (BOOL)showsScopeBar { return _showsScopeBar; }
- (void)setShowsScopeBar:(BOOL)shows
{
    _showsScopeBar = shows;
    _needsLayout = YES;
}
- (UIColor *)barTintColor { return _barTintColor; }
- (void)setBarTintColor:(UIColor *)color { _barTintColor = color; }
- (long)searchBarStyle { return _searchBarStyle; }
- (void)setSearchBarStyle:(long)style { _searchBarStyle = style; }
- (UIImage *)backgroundImage { return _backgroundImage; }
- (void)setBackgroundImage:(UIImage *)image { _backgroundImage = image; }
- (void)setShowsCancelButton:(BOOL)shows animated:(BOOL)animated
{
    (void)animated;
    _showsCancelButton = shows;
    if (_cancelButton)
        ((UIView *)_cancelButton)->_hidden = !shows;
    _needsLayout = YES;
}
- (void)layoutSubviews
{
    double width = _frame.size.width;
    double height = _frame.size.height;
    double fieldWidth = width - 16 - (_showsCancelButton ? 64 : 0);
    if (fieldWidth < 40)
        fieldWidth = 40;
    if (_field)
        ((UIView *)_field)->_frame =
            CGRectMake(8, 6, fieldWidth, height - 12);
    if (_cancelButton)
        ((UIView *)_cancelButton)->_frame =
            CGRectMake(width - 64, 6, 56, height - 12);
}
- (void)fieldChanged
{
    if (_delegate &&
        [_delegate respondsToSelector:@selector(searchBar:textDidChange:)])
        [_delegate searchBar:self textDidChange:[self text]];
}
- (void)cancelTapped
{
    if (_delegate &&
        [_delegate respondsToSelector:
            @selector(searchBarCancelButtonClicked:)])
        [_delegate searchBarCancelButtonClicked:self];
    [self setText:@""];
    if (_field)
        [(UITextField *)_field resignFirstResponder];
}
- (void)searchButtonClicked
{
    if (_delegate &&
        [_delegate respondsToSelector:
            @selector(searchBarSearchButtonClicked:)])
        [_delegate searchBarSearchButtonClicked:self];
}
@end

@implementation UISearchController
- (id)initWithSearchResultsController:(UIViewController *)controller
{
    self = [super init];
    if (self)
    {
        _searchResultsController = controller;
        _searchBar = [[UISearchBar alloc] initWithFrame:
            CGRectMake(0, 0, 320, 44)];
        _obscuresBackgroundDuringPresentation = YES;
        _hidesNavigationBarDuringPresentation = YES;
    }
    return self;
}
- (UISearchBar *)searchBar { return _searchBar; }
- (id)searchResultsUpdater { return _searchResultsUpdater; }
- (void)setSearchResultsUpdater:(id)updater
{
    _searchResultsUpdater = updater;
}
- (id)delegate { return _delegate; }
- (void)setDelegate:(id)delegate { _delegate = delegate; }
- (UIViewController *)searchResultsController
{
    return _searchResultsController;
}
- (BOOL)isActive { return _active; }
- (void)setActive:(BOOL)active
{
    [self setActive:active animated:NO];
}
- (void)setActive:(BOOL)active animated:(BOOL)animated
{
    (void)animated;
    _active = active;
    if (_searchResultsUpdater &&
        [_searchResultsUpdater respondsToSelector:
            @selector(updateSearchResultsForSearchController:)])
        [_searchResultsUpdater
            updateSearchResultsForSearchController:self];
}
- (BOOL)obscuresBackgroundDuringPresentation
{
    return _obscuresBackgroundDuringPresentation;
}
- (void)setObscuresBackgroundDuringPresentation:(BOOL)value
{
    _obscuresBackgroundDuringPresentation = value;
}
- (BOOL)dimsBackgroundDuringPresentation
{
    return _dimsBackgroundDuringPresentation;
}
- (void)setDimsBackgroundDuringPresentation:(BOOL)value
{
    _dimsBackgroundDuringPresentation = value;
}
- (BOOL)hidesNavigationBarDuringPresentation
{
    return _hidesNavigationBarDuringPresentation;
}
- (void)setHidesNavigationBarDuringPresentation:(BOOL)value
{
    _hidesNavigationBarDuringPresentation = value;
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

@implementation UIPageViewController
- (id)initWithTransitionStyle:(long)style
        navigationOrientation:(long)orientation
                      options:(id)options
{
    self = [super init];
    if (self)
    {
        _transitionStyle = style;
        _navigationOrientation = orientation;
        _spineLocation = UIPageViewControllerSpineLocationMin;
        (void)options;
    }
    return self;
}
- (void)loadView
{
    UIView *root =
        [[UIView alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    root.backgroundColor = [UIColor clearColor];
    self.view = root;
    [self installCurrentPage];
}
- (void)viewDidLoad
{
    [self installCurrentPage];
}
- (void)installCurrentPage
{
    if (!_view)
        return;
    NSArray *existing = [_view subviews];
    for (unsigned long i = 0; i < [existing count]; i++)
        [[existing objectAtIndex:i] removeFromSuperview];
    if (!_pageControllers || [_pageControllers count] == 0)
        return;
    UIViewController *current = [_pageControllers objectAtIndex:0];
    [self addChildViewController:current];
    UIView *page = [current view];
    page.frame = _view.bounds;
    [_view addSubview:page];
}
- (void)setViewControllers:(NSArray *)viewControllers
                 direction:(long)direction
                  animated:(BOOL)animated
                completion:(void (^)(BOOL finished))completion
{
    (void)direction;
    (void)animated;
    _pageControllers = viewControllers;
    [self installCurrentPage];
    if (completion)
        completion(YES);
}
- (NSArray *)viewControllers { return _pageControllers; }
- (id)delegate { return _pageDelegate; }
- (void)setDelegate:(id)delegate { _pageDelegate = delegate; }
- (id)dataSource { return _dataSource; }
- (void)setDataSource:(id)dataSource { _dataSource = dataSource; }
- (long)transitionStyle { return _transitionStyle; }
- (long)navigationOrientation { return _navigationOrientation; }
- (long)spineLocation { return _spineLocation; }
- (BOOL)isDoubleSided { return _doubleSided; }
- (void)setDoubleSided:(BOOL)doubleSided { _doubleSided = doubleSided; }
@end

@interface UISplitContainerView : UIView {
@public
    UISplitViewController *_split;
}
@end

@implementation UISplitContainerView
- (void)layoutSubviews
{
    [super layoutSubviews];
    if (_split)
        [_split layoutColumns];
}
@end

@implementation UISplitViewController
- (id)init
{
    return [self initWithStyle:UISplitViewControllerStyleAutomatic];
}
- (id)initWithStyle:(long)style
{
    self = [super init];
    if (self)
    {
        _splitStyle = style;
        _preferredDisplayMode = UISplitViewControllerDisplayModeAutomatic;
        _preferredPrimaryColumnWidthFraction = 0.3;
        _minimumPrimaryColumnWidth = 0;
        _maximumPrimaryColumnWidth = 1000000;
        _supplementaryColumnWidth = 0;
    }
    return self;
}
- (void)loadView
{
    UISplitContainerView *root = [[UISplitContainerView alloc]
        initWithFrame:[[UIScreen mainScreen] bounds]];
    root->_split = self;
    root.backgroundColor = [UIColor clearColor];
    self.view = root;
    [self installControllers];
}
- (NSArray *)viewControllers
{
    NSMutableArray *controllers = [NSMutableArray array];
    if (_splitPrimary)
        [controllers addObject:_splitPrimary];
    if (_splitSupplementary)
        [controllers addObject:_splitSupplementary];
    if (_splitSecondary)
        [controllers addObject:_splitSecondary];
    return controllers;
}
- (void)setViewControllers:(NSArray *)viewControllers
{
    _splitPrimary = [viewControllers count] > 0
        ? [viewControllers objectAtIndex:0] : nil;
    if ([viewControllers count] > 2)
    {
        _splitSupplementary = [viewControllers objectAtIndex:1];
        _splitSecondary = [viewControllers objectAtIndex:2];
    }
    else
    {
        _splitSupplementary = nil;
        _splitSecondary = [viewControllers count] > 1
            ? [viewControllers objectAtIndex:1] : nil;
    }
    if ([self isViewLoaded])
        [self installControllers];
}
- (id)delegate { return _splitDelegate; }
- (void)setDelegate:(id)delegate { _splitDelegate = delegate; }
- (long)style { return _splitStyle; }
- (long)preferredDisplayMode { return _preferredDisplayMode; }
- (void)setPreferredDisplayMode:(long)mode
{
    if (_preferredDisplayMode == mode)
        return;
    long previous = [self displayMode];
    _preferredDisplayMode = mode;
    long current = [self displayMode];
    if (previous != current && _splitDelegate &&
        [_splitDelegate respondsToSelector:
            @selector(splitViewController:willChangeToDisplayMode:)])
        [_splitDelegate splitViewController:self
                       willChangeToDisplayMode:current];
    if ([self isViewLoaded])
        [self layoutColumns];
}
- (long)displayMode
{
    if (_preferredDisplayMode != UISplitViewControllerDisplayModeAutomatic)
        return _preferredDisplayMode;
    return UISplitViewControllerDisplayModeAllVisible;
}
- (BOOL)isCollapsed
{
    if (!_view)
        return NO;
    return _view.bounds.size.width < 700;
}
- (UIViewController *)primaryViewController { return _splitPrimary; }
- (UIViewController *)secondaryViewController { return _splitSecondary; }
- (void)setViewController:(UIViewController *)viewController
                forColumn:(long)column
{
    if (column == UISplitViewControllerColumnPrimary)
        _splitPrimary = viewController;
    else if (column == UISplitViewControllerColumnSupplementary)
        _splitSupplementary = viewController;
    else if (column == UISplitViewControllerColumnSecondary)
        _splitSecondary = viewController;
    if ([self isViewLoaded])
        [self installControllers];
}
- (UIViewController *)viewControllerForColumn:(long)column
{
    if (column == UISplitViewControllerColumnPrimary)
        return _splitPrimary;
    if (column == UISplitViewControllerColumnSupplementary)
        return _splitSupplementary;
    if (column == UISplitViewControllerColumnSecondary)
        return _splitSecondary;
    return nil;
}
- (double)preferredPrimaryColumnWidthFraction
{
    return _preferredPrimaryColumnWidthFraction;
}
- (void)setPreferredPrimaryColumnWidthFraction:(double)fraction
{
    if (fraction < 0)
        fraction = 0;
    if (fraction > 1)
        fraction = 1;
    _preferredPrimaryColumnWidthFraction = fraction;
    if ([self isViewLoaded])
        [self layoutColumns];
}
- (double)primaryColumnWidth
{
    double width = _view ? _view.bounds.size.width
                         : [[UIScreen mainScreen] bounds].size.width;
    double column = width * _preferredPrimaryColumnWidthFraction;
    if (column < _minimumPrimaryColumnWidth)
        column = _minimumPrimaryColumnWidth;
    if (column > _maximumPrimaryColumnWidth)
        column = _maximumPrimaryColumnWidth;
    if (column > width)
        column = width;
    return column;
}
- (double)minimumPrimaryColumnWidth { return _minimumPrimaryColumnWidth; }
- (void)setMinimumPrimaryColumnWidth:(double)width
{
    _minimumPrimaryColumnWidth = width;
    if ([self isViewLoaded])
        [self layoutColumns];
}
- (double)maximumPrimaryColumnWidth { return _maximumPrimaryColumnWidth; }
- (void)setMaximumPrimaryColumnWidth:(double)width
{
    _maximumPrimaryColumnWidth = width;
    if ([self isViewLoaded])
        [self layoutColumns];
}
- (double)supplementaryColumnWidth
{
    if (_supplementaryColumnWidth > 0)
        return _supplementaryColumnWidth;
    double width = _view ? _view.bounds.size.width
                         : [[UIScreen mainScreen] bounds].size.width;
    return width * _preferredPrimaryColumnWidthFraction;
}
- (void)setSupplementaryColumnWidth:(double)width
{
    _supplementaryColumnWidth = width < 0 ? 0 : width;
    if ([self isViewLoaded])
        [self layoutColumns];
}
- (BOOL)showsSecondaryOnlyButton { return NO; }
- (void)toggleMasterVisible:(id)sender
{
    (void)sender;
    _preferredDisplayMode = ([self displayMode] ==
        UISplitViewControllerDisplayModeSecondaryOnly)
        ? UISplitViewControllerDisplayModeAllVisible
        : UISplitViewControllerDisplayModeSecondaryOnly;
    if ([self isViewLoaded])
        [self layoutColumns];
}
- (void)installControllers
{
    if (!_view)
        return;
    NSArray *subviews = [_view subviews];
    for (unsigned long i = 0; i < [subviews count]; i++)
        [[subviews objectAtIndex:i] removeFromSuperview];
    NSArray *existing = [self children];
    for (unsigned long i = 0; i < [existing count]; i++)
    {
        UIViewController *child = [existing objectAtIndex:i];
        [child willMoveToParentViewController:nil];
        [child removeFromParentViewController];
        [child didMoveToParentViewController:nil];
    }
    if (_splitPrimary)
    {
        [self addChildViewController:_splitPrimary];
        [_splitPrimary willMoveToParentViewController:self];
        [_view addSubview:[_splitPrimary view]];
        [_splitPrimary didMoveToParentViewController:self];
    }
    if (_splitSupplementary)
    {
        [self addChildViewController:_splitSupplementary];
        [_splitSupplementary willMoveToParentViewController:self];
        [_view addSubview:[_splitSupplementary view]];
        [_splitSupplementary didMoveToParentViewController:self];
    }
    if (_splitSecondary)
    {
        [self addChildViewController:_splitSecondary];
        [_splitSecondary willMoveToParentViewController:self];
        [_view addSubview:[_splitSecondary view]];
        [_splitSecondary didMoveToParentViewController:self];
    }
    [self layoutColumns];
}
- (void)layoutColumns
{
    if (!_view)
        return;
    CGRect bounds = _view.bounds;
    UIView *primary = _splitPrimary ? [_splitPrimary view] : nil;
    UIView *supplementary =
        _splitSupplementary ? [_splitSupplementary view] : nil;
    UIView *secondary = _splitSecondary ? [_splitSecondary view] : nil;
    if ([self isCollapsed])
    {
        if (primary)
        {
            primary.hidden = secondary != nil;
            primary.frame = bounds;
        }
        if (supplementary)
            supplementary.hidden = YES;
        if (secondary)
        {
            secondary.hidden = NO;
            secondary.frame = bounds;
        }
        return;
    }
    long mode = [self displayMode];
    if (mode == UISplitViewControllerDisplayModeSecondaryOnly)
    {
        if (primary)
            primary.hidden = YES;
        if (supplementary)
            supplementary.hidden = YES;
        if (secondary)
        {
            secondary.hidden = NO;
            secondary.frame = bounds;
        }
        return;
    }
    if (!secondary)
    {
        if (primary)
        {
            primary.hidden = NO;
            primary.frame = bounds;
        }
        return;
    }
    double width = [self primaryColumnWidth];
    if (primary)
    {
        primary.hidden = NO;
        primary.frame = CGRectMake(0, 0, width, bounds.size.height);
    }
    if (supplementary)
    {
        double supplement = [self supplementaryColumnWidth];
        if (supplement > bounds.size.width - width)
            supplement = bounds.size.width - width;
        supplementary.hidden = NO;
        supplementary.frame = CGRectMake(width, 0, supplement,
                                         bounds.size.height);
        width += supplement;
    }
    secondary.hidden = NO;
    secondary.frame = CGRectMake(width, 0, bounds.size.width - width,
                                 bounds.size.height);
}
- (void)viewWillLayoutSubviews
{
    [self layoutColumns];
}
- (void)showViewController:(UIViewController *)viewController sender:(id)sender
{
    (void)sender;
    _splitPrimary = viewController;
    if ([self isViewLoaded])
        [self installControllers];
}
- (void)showDetailViewController:(UIViewController *)viewController
                          sender:(id)sender
{
    (void)sender;
    _splitSecondary = viewController;
    if ([self isViewLoaded])
        [self installControllers];
}
@end

@implementation UIStepper
- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        _value = 0;
        _minimumValue = 0;
        _maximumValue = 100;
        _stepValue = 1;
        _continuous = YES;
        [self setBackgroundColor:
            [UIColor colorWithRed:0.16 green:0.17 blue:0.19 alpha:1.0]];
        [[self layer] setCornerRadius:8];

        double half = frame.size.width / 2;
        double height = frame.size.height;

        UIControl *minus = [[UIControl alloc]
            initWithFrame:CGRectMake(0, 0, half, height)];
        UILabel *minusLabel = [[UILabel alloc]
            initWithFrame:CGRectMake(0, 0, half, height)];
        minusLabel->_text = @"\xe2\x88\x92";
        minusLabel->_font = [UIFont systemFontOfSize:20];
        minusLabel->_textColor = [UIColor whiteColor];
        minusLabel->_textAlignment = 1;
        [minus addSubview:minusLabel];
        [minus addTarget:self action:@selector(minusTapped)
         forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:minus];
        _minusButton = minus;

        UIControl *plus = [[UIControl alloc]
            initWithFrame:CGRectMake(half, 0, half, height)];
        UILabel *plusLabel = [[UILabel alloc]
            initWithFrame:CGRectMake(0, 0, half, height)];
        plusLabel->_text = @"+";
        plusLabel->_font = [UIFont systemFontOfSize:20];
        plusLabel->_textColor = [UIColor whiteColor];
        plusLabel->_textAlignment = 1;
        [plus addSubview:plusLabel];
        [plus addTarget:self action:@selector(plusTapped)
         forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:plus];
        _plusButton = plus;

        UIView *divider = [[UIView alloc] initWithFrame:
            CGRectMake(half, 5, 1, height - 10)];
        divider->_backgroundColor =
            [UIColor colorWithRed:0.35 green:0.36 blue:0.38 alpha:1.0];
        [self addSubview:divider];
        _divider = divider;
        _needsLayout = YES;
    }
    return self;
}
- (void)layoutSubviews
{
    double width = _frame.size.width;
    double height = _frame.size.height;
    if (_minusButton)
        ((UIView *)_minusButton)->_frame =
            CGRectMake(0, 0, width / 2, height);
    if (_plusButton)
        ((UIView *)_plusButton)->_frame =
            CGRectMake(width / 2, 0, width / 2, height);
    if (_divider)
        ((UIView *)_divider)->_frame =
            CGRectMake(width / 2, 5, 1, height - 10);
}
- (double)value { return _value; }
- (void)setValue:(double)value
{
    if (value < _minimumValue)
        value = _minimumValue;
    if (value > _maximumValue)
        value = _maximumValue;
    _value = value;
}
- (double)minimumValue { return _minimumValue; }
- (void)setMinimumValue:(double)value { _minimumValue = value; }
- (double)maximumValue { return _maximumValue; }
- (void)setMaximumValue:(double)value { _maximumValue = value; }
- (double)stepValue { return _stepValue; }
- (void)setStepValue:(double)value
{
    _stepValue = value > 0 ? value : 1;
}
- (BOOL)isContinuous { return _continuous; }
- (void)setContinuous:(BOOL)continuous { _continuous = continuous; }
- (BOOL)autorepeats { return _autorepeat; }
- (void)setAutorepeats:(BOOL)repeats { _autorepeat = repeats; }
- (BOOL)wraps { return _wraps; }
- (void)setWraps:(BOOL)wraps { _wraps = wraps; }
- (void)plusTapped
{
    double value = _value + _stepValue;
    if (_wraps && value > _maximumValue)
        value = _minimumValue;
    if (value > _maximumValue)
        value = _maximumValue;
    if (value == _value)
        return;
    _value = value;
    [self sendActionsForControlEvents:UIControlEventValueChanged];
}
- (void)minusTapped
{
    double value = _value - _stepValue;
    if (_wraps && value < _minimumValue)
        value = _maximumValue;
    if (value < _minimumValue)
        value = _minimumValue;
    if (value == _value)
        return;
    _value = value;
    [self sendActionsForControlEvents:UIControlEventValueChanged];
}
- (CGSize)intrinsicContentSize { return CGSizeMake(94, 32); }
@end

/* ------------------------------------------------------------- pickers */

static unsigned color_rgb(UIColor *color);
static double color_alpha(UIColor *color);

static long picker_components(UIPickerView *picker)
{
    if (picker->_dataSource &&
        [picker->_dataSource respondsToSelector:
            @selector(numberOfComponentsInPickerView:)])
    {
        SEL sel = @selector(numberOfComponentsInPickerView:);
        long n = ((long (*)(id, void *, id))objc_msgSend)(
            picker->_dataSource, (void *)sel, picker);
        if (n < 1)
            n = 1;
        if (n > PICKER_MAX_COMPONENTS)
            n = PICKER_MAX_COMPONENTS;
        return n;
    }
    return 1;
}

static long picker_rows(UIPickerView *picker, long component)
{
    if (!picker->_dataSource ||
        ![picker->_dataSource respondsToSelector:
            @selector(pickerView:numberOfRowsInComponent:)])
        return 0;
    SEL sel = @selector(pickerView:numberOfRowsInComponent:);
    long n = ((long (*)(id, void *, id, long))objc_msgSend)(
        picker->_dataSource, (void *)sel, picker, component);
    return n > 0 ? n : 0;
}

static id picker_title(UIPickerView *picker, long row, long component)
{
    if (!picker->_delegate ||
        ![picker->_delegate respondsToSelector:
            @selector(pickerView:titleForRow:forComponent:)])
        return nil;
    SEL sel = @selector(pickerView:titleForRow:forComponent:);
    return ((id (*)(id, void *, id, long, long))objc_msgSend)(
        picker->_delegate, (void *)sel, picker, row, component);
}

static void picker_report(UIPickerView *picker, long row, long component)
{
    if (!picker->_delegate ||
        ![picker->_delegate respondsToSelector:
            @selector(pickerView:didSelectRow:inComponent:)])
        return;
    SEL sel = @selector(pickerView:didSelectRow:inComponent:);
    ((void (*)(id, void *, id, long, long))objc_msgSend)(
        picker->_delegate, (void *)sel, picker, row, component);
}

/* A wheel has no fill of its own; its text follows the surface it sits on,
 * like the real picker's use of the label color for the current style. */
static unsigned picker_text_color(UIView *view)
{
    for (UIView *v = view; v; v = [v superview])
    {
        UIColor *color = v->_backgroundColor;
        if (!color || color_alpha(color) <= 0.5)
            continue;
        unsigned rgb = color_rgb(color);
        double luminance = (0.299 * (((rgb >> 16) & 0xff) / 255.0) +
                            0.587 * (((rgb >> 8) & 0xff) / 255.0) +
                            0.114 * ((rgb & 0xff) / 255.0));
        return luminance > 0.55 ? 0x000000 : 0xffffff;
    }
    return 0xffffff;
}

@implementation UIPickerView
- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        _dragComponent = -1;
        _dragging = NO;
        [self setBackgroundColor:[UIColor clearColor]];
    }
    return self;
}
- (void)setDataSource:(id)dataSource
{
    _dataSource = dataSource;
    [self reloadAllComponents];
}
- (id)dataSource { return _dataSource; }
- (void)setDelegate:(id)delegate { _delegate = delegate; }
- (id)delegate { return _delegate; }
- (long)numberOfComponents { return picker_components(self); }
- (long)numberOfRowsInComponent:(long)component
{
    return picker_rows(self, component);
}
- (long)selectedRowInComponent:(long)component
{
    if (component < 0 || component >= PICKER_MAX_COMPONENTS)
        return 0;
    long rows = picker_rows(self, component);
    long row = _selectedRows[component];
    if (row < 0)
        row = 0;
    if (rows > 0 && row >= rows)
        row = rows - 1;
    return row;
}
- (void)selectRow:(long)row inComponent:(long)component animated:(BOOL)animated
{
    (void)animated;
    long components = picker_components(self);
    if (component < 0 || component >= components)
        return;
    long rows = picker_rows(self, component);
    if (row < 0)
        row = 0;
    if (rows > 0 && row >= rows)
        row = rows - 1;
    _selectedRows[component] = row;
    _rowOffsets[component] = row;
}
- (void)reloadAllComponents
{
    long components = picker_components(self);
    for (long c = 0; c < components; c++)
    {
        long rows = picker_rows(self, c);
        long row = _selectedRows[c];
        if (row < 0)
            row = 0;
        if (rows > 0 && row >= rows)
            row = rows - 1;
        if (rows <= 0)
            row = 0;
        _selectedRows[c] = row;
        _rowOffsets[c] = row;
    }
}
- (void)reloadComponent:(long)component
{
    long components = picker_components(self);
    if (component < 0 || component >= components)
        return;
    long rows = picker_rows(self, component);
    long row = _selectedRows[component];
    if (row < 0)
        row = 0;
    if (rows > 0 && row >= rows)
        row = rows - 1;
    if (rows <= 0)
        row = 0;
    _selectedRows[component] = row;
    _rowOffsets[component] = row;
}
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    (void)event;
    UITouch *touch = [touches anyObject];
    CGPoint point = [touch locationInView:self];
    long components = picker_components(self);
    double componentWidth = _frame.size.width / components;
    long component = 0;
    if (componentWidth > 0)
        component = (long)(point.x / componentWidth);
    if (component < 0)
        component = 0;
    if (component >= components)
        component = components - 1;
    _dragComponent = component;
    _dragging = YES;
    _dragStartPoint = point;
    _dragStartOffset = _rowOffsets[component];
}
- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    (void)event;
    if (!_dragging || _dragComponent < 0)
        return;
    UITouch *touch = [touches anyObject];
    CGPoint point = [touch locationInView:self];
    long component = _dragComponent;
    long rows = picker_rows(self, component);
    double low = 0;
    double high = rows - 1;
    if (high < low)
        high = low;
    double offset = _dragStartOffset -
                    (point.y - _dragStartPoint.y) / PICKER_ROW_HEIGHT;
    if (offset < low)
        offset = low;
    if (offset > high)
        offset = high;
    _rowOffsets[component] = offset;
}
- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    (void)event;
    if (!_dragging || _dragComponent < 0)
        return;
    UITouch *touch = [touches anyObject];
    CGPoint point = [touch locationInView:self];
    long component = _dragComponent;
    long rows = picker_rows(self, component);
    long row;
    if (__builtin_fabs(point.y - _dragStartPoint.y) < 3.0)
    {
        /* A tap lands on the row under the finger. */
        double center = _frame.size.height / 2.0;
        row = (long)__builtin_floor(
            (point.y - center) / PICKER_ROW_HEIGHT +
            _rowOffsets[component] + 0.5);
    }
    else
        row = (long)__builtin_floor(_rowOffsets[component] + 0.5);
    if (row < 0)
        row = 0;
    if (rows > 0 && row >= rows)
        row = rows - 1;
    if (rows <= 0)
        row = 0;
    long previous = _selectedRows[component];
    _selectedRows[component] = row;
    _rowOffsets[component] = row;
    _dragging = NO;
    _dragComponent = -1;
    if (row != previous)
        picker_report(self, row, component);
}
- (CGSize)intrinsicContentSize { return CGSizeMake(320, 216); }
@end

/* ----------------------------------------------------------- date picker */

#define DATEPICKER_FIRST_YEAR 1900
#define DATEPICKER_YEAR_COUNT 201

static long datepicker_days_in_month(long year, long month)
{
    static const long monthDays[12] = {
        31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31
    };
    if (month < 1 || month > 12)
        return 31;
    if (month == 2)
    {
        long leap = (year % 4 == 0 && year % 100 != 0) || year % 400 == 0;
        return 28 + leap;
    }
    return monthDays[month - 1];
}

static long datepicker_component_count(long mode)
{
    if (mode == UIDatePickerModeDate)
        return 3;
    if (mode == UIDatePickerModeDateAndTime)
        return 6;
    if (mode == UIDatePickerModeCountDownTimer)
        return 2;
    return 3;
}

/* The component layout is: date modes start with month/day/year; time
 * modes use hour/minute/AM-PM (offset after the date part when combined). */
static int datepicker_is_date_component(long mode, long component)
{
    return (mode == UIDatePickerModeDate ||
            mode == UIDatePickerModeDateAndTime) && component < 3;
}

static long datepicker_rows_for(UIDatePicker *picker, long component)
{
    long mode = picker->_mode;
    if (datepicker_is_date_component(mode, component))
    {
        if (component == 0)
            return 12;
        if (component == 1)
        {
            /* Read the wheel state directly: selectedRowInComponent: queries
             * the data source, which is this picker and would recurse. */
            long month = picker->_pickerView->_selectedRows[0] + 1;
            long year = DATEPICKER_FIRST_YEAR +
                        picker->_pickerView->_selectedRows[2];
            return datepicker_days_in_month(year, month);
        }
        return DATEPICKER_YEAR_COUNT;
    }
    if (mode == UIDatePickerModeCountDownTimer)
        return component == 0 ? 24 : 60;
    long timeComponent = component - (mode == UIDatePickerModeDateAndTime ? 3 : 0);
    if (timeComponent == 0)
        return 12;
    if (timeComponent == 1)
        return 60;
    return 2;
}

@implementation UIDatePicker
- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        _mode = UIDatePickerModeDateAndTime;
        _style = UIDatePickerStyleAutomatic;
        _dateInterval = [[NSDate date] timeIntervalSince1970];
        _countdownDuration = 0;
        [self setBackgroundColor:[UIColor clearColor]];

        _pickerView = [[UIPickerView alloc]
            initWithFrame:CGRectMake(0, 0, frame.size.width,
                                     frame.size.height)];
        _pickerView->_dataSource = self;
        _pickerView->_delegate = self;
        [_pickerView reloadAllComponents];
        [self addSubview:_pickerView];
        [self refreshWheelsFromDate];
    }
    return self;
}
- (void)layoutSubviews
{
    if (_pickerView)
        _pickerView->_frame =
            CGRectMake(0, 0, _frame.size.width, _frame.size.height);
}
- (NSDate *)date
{
    return [NSDate dateWithTimeIntervalSince1970:_dateInterval];
}
- (void)setDate:(NSDate *)date
{
    [self setDate:date animated:NO];
}
- (void)setDate:(NSDate *)date animated:(BOOL)animated
{
    (void)animated;
    if (!date)
        date = [NSDate date];
    _dateInterval = [date timeIntervalSince1970];
    [self refreshWheelsFromDate];
}
- (long)datePickerMode { return _mode; }
- (void)setDatePickerMode:(long)mode
{
    _mode = mode;
    _settingUp = YES;
    [_pickerView reloadAllComponents];
    _settingUp = NO;
    [self refreshWheelsFromDate];
}
- (long)preferredDatePickerStyle { return _style; }
- (void)setPreferredDatePickerStyle:(long)style { _style = style; }
- (NSCalendar *)calendar
{
    return _calendar ? _calendar : [NSCalendar currentCalendar];
}
- (void)setCalendar:(NSCalendar *)calendar { _calendar = calendar; }
- (double)countDownDuration { return _countdownDuration; }
- (void)setCountDownDuration:(double)duration
{
    _countdownDuration = duration > 0 ? duration : 0;
    [self refreshWheelsFromDate];
}
- (void)refreshWheelsFromDate
{
    if (!_pickerView)
        return;
    NSCalendar *calendar = self.calendar;
    NSDate *date = [NSDate dateWithTimeIntervalSince1970:_dateInterval];
    NSDateComponents *comp = [calendar components:
        NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay |
        NSCalendarUnitHour | NSCalendarUnitMinute | NSCalendarUnitSecond
        fromDate:date];
    _settingUp = YES;
    if (_mode == UIDatePickerModeDate ||
        _mode == UIDatePickerModeDateAndTime)
    {
        long year = comp->_year;
        if (year < DATEPICKER_FIRST_YEAR)
            year = DATEPICKER_FIRST_YEAR;
        if (year >= DATEPICKER_FIRST_YEAR + DATEPICKER_YEAR_COUNT)
            year = DATEPICKER_FIRST_YEAR + DATEPICKER_YEAR_COUNT - 1;
        long month = comp->_month;
        if (month < 1)
            month = 1;
        if (month > 12)
            month = 12;
        [_pickerView selectRow:month - 1 inComponent:0 animated:NO];
        [_pickerView selectRow:year - DATEPICKER_FIRST_YEAR
                    inComponent:2 animated:NO];
        [_pickerView reloadComponent:1];
        long day = comp->_day;
        long rows = datepicker_days_in_month(year, month);
        if (day > rows)
            day = rows;
        if (day < 1)
            day = 1;
        [_pickerView selectRow:day - 1 inComponent:1 animated:NO];
    }
    long timeBase =
        _mode == UIDatePickerModeDateAndTime ? 3 :
        (_mode == UIDatePickerModeTime ? 0 : -1);
    if (timeBase >= 0)
    {
        long hour = comp->_hour % 12;
        if (hour == 0)
            hour = 12;
        [_pickerView selectRow:hour - 1 inComponent:timeBase animated:NO];
        [_pickerView selectRow:comp->_minute inComponent:timeBase + 1
                     animated:NO];
        [_pickerView selectRow:comp->_hour >= 12 ? 1 : 0
                    inComponent:timeBase + 2 animated:NO];
    }
    else if (_mode == UIDatePickerModeCountDownTimer)
    {
        long total = (long)_countdownDuration;
        [_pickerView selectRow:(total / 3600) % 24 inComponent:0 animated:NO];
        [_pickerView selectRow:(total / 60) % 60 inComponent:1 animated:NO];
    }
    _settingUp = NO;
}
- (long)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
    (void)pickerView;
    return datepicker_component_count(_mode);
}
- (long)pickerView:(UIPickerView *)pickerView
    numberOfRowsInComponent:(long)component
{
    (void)pickerView;
    return datepicker_rows_for(self, component);
}
- (id)pickerView:(UIPickerView *)pickerView titleForRow:(long)row
    forComponent:(long)component
{
    (void)pickerView;
    char buf[32];
    static const char *months[12] = {
        "January", "February", "March", "April", "May", "June",
        "July", "August", "September", "October", "November", "December"
    };
    if (datepicker_is_date_component(_mode, component))
    {
        if (component == 0)
            return row >= 0 && row < 12
                       ? [NSString stringWithUTF8String:months[row]]
                       : nil;
        if (component == 1)
        {
            snprintf(buf, sizeof buf, "%ld", (long)(row + 1));
            return [NSString stringWithUTF8String:buf];
        }
        snprintf(buf, sizeof buf, "%ld",
                 (long)(DATEPICKER_FIRST_YEAR + row));
        return [NSString stringWithUTF8String:buf];
    }
    if (_mode == UIDatePickerModeCountDownTimer)
    {
        if (component == 0)
            snprintf(buf, sizeof buf, "%ld", (long)row);
        else
            snprintf(buf, sizeof buf, "%02ld", (long)row);
        return [NSString stringWithUTF8String:buf];
    }
    long timeComponent =
        component - (_mode == UIDatePickerModeDateAndTime ? 3 : 0);
    if (timeComponent == 0)
    {
        long hour = row == 0 ? 12 : (long)row;
        snprintf(buf, sizeof buf, "%ld", hour);
    }
    else if (timeComponent == 1)
        snprintf(buf, sizeof buf, "%02ld", (long)row);
    else
        snprintf(buf, sizeof buf, "%s", row == 0 ? "AM" : "PM");
    return [NSString stringWithUTF8String:buf];
}
- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(long)row
    inComponent:(long)component
{
    (void)pickerView;
    (void)row;
    if (_settingUp)
        return;
    if (datepicker_is_date_component(_mode, component) && component != 1)
    {
        /* Month or year changed: the day wheel's row count follows. */
        long month = [_pickerView selectedRowInComponent:0] + 1;
        long year = DATEPICKER_FIRST_YEAR +
                    [_pickerView selectedRowInComponent:2];
        long dayRow = [_pickerView selectedRowInComponent:1];
        long rows = datepicker_days_in_month(year, month);
        if (dayRow >= rows)
            dayRow = rows - 1;
        if (dayRow < 0)
            dayRow = 0;
        [_pickerView reloadComponent:1];
        [_pickerView selectRow:dayRow inComponent:1 animated:NO];
    }
    [self updateDateFromWheels];
    [self sendActionsForControlEvents:UIControlEventValueChanged];
}
- (void)updateDateFromWheels
{
    NSCalendar *calendar = self.calendar;
    NSDate *current = [NSDate dateWithTimeIntervalSince1970:_dateInterval];
    NSDateComponents *comp = [calendar components:
        NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay |
        NSCalendarUnitHour | NSCalendarUnitMinute | NSCalendarUnitSecond
        fromDate:current];
    long year = comp->_year;
    long month = comp->_month;
    long day = comp->_day;
    long hour = comp->_hour;
    long minute = comp->_minute;
    if (_mode == UIDatePickerModeDate ||
        _mode == UIDatePickerModeDateAndTime)
    {
        month = [_pickerView selectedRowInComponent:0] + 1;
        year = DATEPICKER_FIRST_YEAR +
               [_pickerView selectedRowInComponent:2];
        long rows = datepicker_days_in_month(year, month);
        day = [_pickerView selectedRowInComponent:1] + 1;
        if (day > rows)
            day = rows;
        if (day < 1)
            day = 1;
    }
    if (_mode == UIDatePickerModeCountDownTimer)
    {
        long hours = [_pickerView selectedRowInComponent:0];
        long minutes = [_pickerView selectedRowInComponent:1];
        _countdownDuration = (double)(hours * 3600 + minutes * 60);
        return;
    }
    long timeBase =
        _mode == UIDatePickerModeDateAndTime ? 3 :
        (_mode == UIDatePickerModeTime ? 0 : -1);
    if (timeBase >= 0)
    {
        long hour12 = [_pickerView selectedRowInComponent:timeBase] + 1;
        minute = [_pickerView selectedRowInComponent:timeBase + 1];
        long pm = [_pickerView selectedRowInComponent:timeBase + 2];
        hour = (hour12 % 12) + (pm ? 12 : 0);
    }
    NSDateComponents *out = [[NSDateComponents alloc] init];
    out->_year = year;
    out->_month = month;
    out->_day = day;
    out->_hour = hour;
    out->_minute = minute;
    out->_second = comp->_second;
    NSDate *date = [calendar dateFromComponents:out];
    if (date)
        _dateInterval = [date timeIntervalSince1970];
}
- (CGSize)intrinsicContentSize { return CGSizeMake(320, 216); }
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
    const double two_pi = 6.28318530717958647692;
    double delta = end - start;
    if (clockwise)
    {
        while (delta < 0.0)
            delta += two_pi;
        while (delta >= two_pi)
            delta -= two_pi;
    }
    else
    {
        while (delta > 0.0)
            delta -= two_pi;
        while (delta <= -two_pi)
            delta += two_pi;
    }
    int steps = (int)(__builtin_fabs(delta) * radius / 2.0) + 1;
    if (steps < 4)
        steps = 4;
    if (steps > 256)
        steps = 256;
    for (int i = 0; i <= steps; i++)
    {
        double angle = start + delta * ((double)i / steps);
        CGPoint point =
            CGPointMake(center.x + radius * __builtin_cos(angle),
                        center.y + radius * __builtin_sin(angle));
        if (i == 0 && _count == 0)
            [self moveToPoint:point];
        else
            [self addLineToPoint:point];
    }
}
- (void)addQuadCurveToPoint:(CGPoint)point controlPoint:(CGPoint)control
{
    double x0 = _count > 0 ? _xs[_count - 1] : 0;
    double y0 = _count > 0 ? _ys[_count - 1] : 0;
    int steps = iosim_cg_quad_segments(x0, y0, control.x, control.y,
                                       point.x, point.y);
    for (int i = 1; i <= steps; i++)
    {
        double t = (double)i / steps;
        double u = 1.0 - t;
        [self addLineToPoint:CGPointMake(
            u * u * x0 + 2 * u * t * control.x + t * t * point.x,
            u * u * y0 + 2 * u * t * control.y + t * t * point.y)];
    }
}
- (void)addCurveToPoint:(CGPoint)point controlPoint1:(CGPoint)control1
           controlPoint2:(CGPoint)control2
{
    double x0 = _count > 0 ? _xs[_count - 1] : 0;
    double y0 = _count > 0 ? _ys[_count - 1] : 0;
    int steps = iosim_cg_cubic_segments(x0, y0, control1.x, control1.y,
                                        control2.x, control2.y, point.x,
                                        point.y);
    for (int i = 1; i <= steps; i++)
    {
        double t = (double)i / steps;
        double u = 1.0 - t;
        [self addLineToPoint:CGPointMake(
            u * u * u * x0 + 3 * u * u * t * control1.x +
                3 * u * t * t * control2.x + t * t * t * point.x,
            u * u * u * y0 + 3 * u * u * t * control1.y +
                3 * u * t * t * control2.y + t * t * t * point.y)];
    }
}
- (void)closePath { _closed = 1; }
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
- (void)addRect:(CGRect)rect
{
    [self moveToPoint:CGPointMake(rect.origin.x, rect.origin.y)];
    [self addLineToPoint:CGPointMake(rect.origin.x + rect.size.width,
                                     rect.origin.y)];
    [self addLineToPoint:CGPointMake(rect.origin.x + rect.size.width,
                                     rect.origin.y + rect.size.height)];
    [self addLineToPoint:CGPointMake(rect.origin.x,
                                     rect.origin.y + rect.size.height)];
    [self closePath];
}
- (void)addOvalInRect:(CGRect)rect
{
    double cx = rect.origin.x + rect.size.width / 2;
    double cy = rect.origin.y + rect.size.height / 2;
    double rx = rect.size.width / 2;
    double ry = rect.size.height / 2;
    [self moveToPoint:CGPointMake(cx + rx, cy)];
    for (int i = 1; i <= 64; i++)
    {
        double a = 2 * 3.14159265358979323846 * i / 64.0;
        [self addLineToPoint:CGPointMake(cx + rx * __builtin_cos(a),
                                         cy + ry * __builtin_sin(a))];
    }
    [self closePath];
}
- (void)addRoundedRect:(CGRect)rect cornerRadius:(double)radius
{
    (void)radius;
    [self addRect:rect];
}
- (CGPathRef)CGPath
{
    CGPathRef path = CGPathCreateMutable();
    if (!path)
        return 0;
    if (_shape == 1)
    {
        CGPathAddRect(path, 0, _rect);
    }
    else if (_shape == 2)
    {
        double r = _cornerRadius;
        if (r <= 0)
        {
            CGPathAddRect(path, 0, _rect);
        }
        else
        {
            double x0 = _rect.origin.x, y0 = _rect.origin.y;
            double x1 = x0 + _rect.size.width;
            double y1 = y0 + _rect.size.height;
            CGPathMoveToPoint(path, 0, x0 + r, y0);
            CGPathAddLineToPoint(path, 0, x1 - r, y0);
            for (int i = 1; i <= 8; i++)
            {
                double a = -1.5707963267948966 + 1.5707963267948966 * i / 8;
                CGPathAddLineToPoint(path, 0, x1 - r + r * __builtin_cos(a),
                                     y0 + r + r * __builtin_sin(a));
            }
            CGPathAddLineToPoint(path, 0, x1, y1 - r);
            for (int i = 1; i <= 8; i++)
            {
                double a = 1.5707963267948966 * i / 8;
                CGPathAddLineToPoint(path, 0, x1 - r + r * __builtin_cos(a),
                                     y1 - r + r * __builtin_sin(a));
            }
            CGPathAddLineToPoint(path, 0, x0 + r, y1);
            for (int i = 1; i <= 8; i++)
            {
                double a = 1.5707963267948966 + 1.5707963267948966 * i / 8;
                CGPathAddLineToPoint(path, 0, x0 + r + r * __builtin_cos(a),
                                     y1 - r + r * __builtin_sin(a));
            }
            CGPathAddLineToPoint(path, 0, x0, y0 + r);
            for (int i = 1; i <= 8; i++)
            {
                double a = 3.14159265358979323846 + 1.5707963267948966 * i / 8;
                CGPathAddLineToPoint(path, 0, x0 + r + r * __builtin_cos(a),
                                     y0 + r + r * __builtin_sin(a));
            }
            CGPathCloseSubpath(path);
        }
    }
    else if (_shape == 3)
    {
        CGPathAddEllipseInRect(path, 0, _rect);
    }
    else if (_count > 0)
    {
        CGPathMoveToPoint(path, 0, _xs[0], _ys[0]);
        for (int i = 1; i < _count; i++)
            CGPathAddLineToPoint(path, 0, _xs[i], _ys[i]);
        if (_closed)
            CGPathCloseSubpath(path);
    }
    return path;
}
@end

struct cg_to_bezier_context {
    UIBezierPath *path;
};

static UIColor *ui_color_from_cgcolor(CGColorRef color)
{
    const double *components = CGColorGetComponents(color);
    if (!components)
        return nil;
    return [UIColor colorWithRed:components[0] green:components[1]
                            blue:components[2] alpha:CGColorGetAlpha(color)];
}

static void cg_to_bezier_applier(void *info, const CGPathElement *element)
{
    struct cg_to_bezier_context *context = info;
    if (!context || !context->path || !element)
        return;
    switch (element->type)
    {
    case kCGPathElementMoveToPoint:
        [context->path moveToPoint:element->points[0]];
        break;
    case kCGPathElementAddLineToPoint:
        [context->path addLineToPoint:element->points[0]];
        break;
    case kCGPathElementCloseSubpath:
        [context->path closePath];
        break;
    default:
        if (element->points)
            [context->path addLineToPoint:element->points[0]];
        break;
    }
}

@implementation CAShapeLayer
- (id)init
{
    self = [super init];
    if (self)
    {
        _lineWidth = 1.0;
        _strokeStart = 0.0;
        _strokeEnd = 1.0;
        _lineCap = 0;
        _lineJoin = 0;
    }
    return self;
}
- (void)setPath:(id)path
{
    if (iosim_cgpath_is_valid(path))
    {
        UIBezierPath *converted = [UIBezierPath bezierPath];
        struct cg_to_bezier_context context;
        context.path = converted;
        CGPathApply((CGPathRef)path, &context, cg_to_bezier_applier);
        _path = converted;
        CGPathRelease(_cgPath);
        _cgPath = CGPathRetain((CGPathRef)path);
    }
    else
    {
        CGPathRelease(_cgPath);
        _cgPath = 0;
        _path = path;
    }
}
- (id)path { return _path; }
- (void)setFillColor:(id)color
{
    CGColorRelease(_cgFillColor);
    _cgFillColor = 0;
    if (iosim_cgcolor_is_valid(color))
    {
        _cgFillColor = CGColorRetain((CGColorRef)color);
        _fillColor = ui_color_from_cgcolor((CGColorRef)color);
    }
    else
    {
        _fillColor = color;
    }
}
- (id)fillColor { return _cgFillColor ? (id)_cgFillColor : _fillColor; }
- (void)setStrokeColor:(id)color
{
    CGColorRelease(_cgStrokeColor);
    _cgStrokeColor = 0;
    if (iosim_cgcolor_is_valid(color))
    {
        _cgStrokeColor = CGColorRetain((CGColorRef)color);
        _strokeColor = ui_color_from_cgcolor((CGColorRef)color);
    }
    else
    {
        _strokeColor = color;
    }
}
- (id)strokeColor { return _cgStrokeColor ? (id)_cgStrokeColor : _strokeColor; }
- (void)setLineWidth:(double)width { _lineWidth = width; }
- (double)lineWidth { return _lineWidth; }
- (void)setStrokeStart:(double)start { _strokeStart = start; }
- (double)strokeStart { return _strokeStart; }
- (void)setStrokeEnd:(double)end { _strokeEnd = end; }
- (double)strokeEnd { return _strokeEnd; }
- (void)setLineCap:(int)cap { _lineCap = cap; }
- (int)lineCap { return _lineCap; }
- (void)setLineJoin:(int)join { _lineJoin = join; }
- (int)lineJoin { return _lineJoin; }
- (NSArray *)lineDashPattern { return _lineDashPattern; }
- (void)setLineDashPattern:(NSArray *)pattern { _lineDashPattern = pattern; }
- (double)lineDashPhase { return _lineDashPhase; }
- (void)setLineDashPhase:(double)phase { _lineDashPhase = phase; }
- (double)miterLimit { return _miterLimit; }
- (void)setMiterLimit:(double)limit { _miterLimit = limit; }
@end

@implementation CAGradientLayer
- (id)init
{
    self = [super init];
    if (self)
    {
        _startPoint = CGPointMake(0.5, 0.0);
        _endPoint = CGPointMake(0.5, 1.0);
        _type = @"axial";
    }
    return self;
}
- (void)setColors:(NSArray *)colors { _colors = colors; }
- (NSArray *)colors { return _colors; }
- (void)setLocations:(NSArray *)locations { _locations = locations; }
- (NSArray *)locations { return _locations; }
- (void)setStartPoint:(CGPoint)point { _startPoint = point; }
- (CGPoint)startPoint { return _startPoint; }
- (void)setEndPoint:(CGPoint)point { _endPoint = point; }
- (CGPoint)endPoint { return _endPoint; }
- (void)setType:(id)type { _type = type; }
- (id)type { return _type; }
@end

@implementation CATextLayer
- (id)init
{
    self = [super init];
    if (self)
    {
        _fontSize = 36;
        _foregroundColor = [UIColor whiteColor];
        _alignmentMode = 0;
    }
    return self;
}
- (id)string { return _string; }
- (void)setString:(id)string { _string = string; }
- (id)font { return _font; }
- (void)setFont:(id)font { _font = font; }
- (double)fontSize { return _fontSize; }
- (void)setFontSize:(double)size { _fontSize = size; }
- (id)foregroundColor { return _foregroundColor; }
- (void)setForegroundColor:(id)color { _foregroundColor = color; }
- (long)alignmentMode { return _alignmentMode; }
- (void)setAlignmentMode:(long)mode { _alignmentMode = mode; }
- (BOOL)isWrapped { return _wrapped; }
- (void)setWrapped:(BOOL)wrapped { _wrapped = wrapped; }
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
+ (id)imageWithData:(id)data
{
    if (!data || [data length] == 0)
        return nil;
    unsigned char *rgba = 0;
    int w = 0, h = 0;
    if (iosim_png_load_memory([data bytes], [data length], &rgba, &w, &h) != 0)
        return nil;
    UIImage *image = [[self alloc] init];
    image->_rgba = rgba;
    image->_width = w;
    image->_height = h;
    return image;
}
+ (id)imageWithCGImage:(CGImageRef)cgImage
{
    int w = 0, h = 0;
    const unsigned char *rgba = iosim_cgimage_data(cgImage, &w, &h);
    if (!rgba || w <= 0 || h <= 0)
        return nil;
    UIImage *image = [[self alloc] init];
    image->_rgba = malloc((unsigned long)w * h * 4);
    if (!image->_rgba)
        return nil;
    memcpy(image->_rgba, rgba, (unsigned long)w * h * 4);
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
- (CGImageRef)CGImage
{
    if (_cgImage && !iosim_cgimage_is_valid(_cgImage))
        _cgImage = 0;
    if (!_cgImage)
        _cgImage = CGImageCreateWithRGBA(_rgba, _width, _height);
    return _cgImage;
}
- (void)drawInRect:(CGRect)rect
{
    iosim_cg_draw_image(0, _rgba, _width, _height, rect);
}
- (void)drawAtPoint:(CGPoint)point
{
    [self drawInRect:CGRectMake(point.x, point.y, _width, _height)];
}
@end

#define MAX_IMAGE_CONTEXTS 8
static CGContextRef g_image_contexts[MAX_IMAGE_CONTEXTS];
static int g_image_context_count;
static void *g_graphics_stack[MAX_IMAGE_CONTEXTS];
static int g_graphics_stack_depth;

void UIGraphicsBeginImageContextWithOptions(CGSize size, BOOL opaque,
                                            double scale)
{
    (void)opaque;
    if (scale <= 0)
        scale = [[UIScreen mainScreen] scale];
    if (scale <= 0)
        scale = 1.0;
    int w = (int)(size.width * scale + 0.5);
    int h = (int)(size.height * scale + 0.5);
    CGContextRef context = iosim_cg_begin_image(w, h, scale);
    if (!context || g_image_context_count >= MAX_IMAGE_CONTEXTS)
        return;
    g_image_contexts[g_image_context_count++] = context;
}

void UIGraphicsBeginImageContext(CGSize size)
{
    UIGraphicsBeginImageContextWithOptions(size, NO, 1.0);
}

CGContextRef UIGraphicsGetCurrentContext(void)
{
    CGContextRef context = iosim_cg_current();
    if (context)
        return context;
    if (g_image_context_count > 0)
        return g_image_contexts[g_image_context_count - 1];
    return 0;
}

void UIGraphicsPushContext(CGContextRef context)
{
    if (!context || g_graphics_stack_depth >= MAX_IMAGE_CONTEXTS)
        return;
    void *token = iosim_cg_push_context(context);
    if (token)
        g_graphics_stack[g_graphics_stack_depth++] = token;
}

void UIGraphicsPopContext(void)
{
    if (g_graphics_stack_depth <= 0)
        return;
    iosim_cg_pop_context(g_graphics_stack[--g_graphics_stack_depth]);
}

UIImage *UIGraphicsGetImageFromCurrentImageContext(void)
{
    CGContextRef context = UIGraphicsGetCurrentContext();
    if (!context)
        return nil;
    unsigned char *rgba = 0;
    int w = 0, h = 0;
    if (iosim_cg_image_data(context, &rgba, &w, &h) != 0 || !rgba)
        return nil;
    UIImage *image = [[UIImage alloc] init];
    image->_rgba = malloc((unsigned long)w * h * 4);
    if (image->_rgba)
        memcpy(image->_rgba, rgba, (unsigned long)w * h * 4);
    image->_width = w;
    image->_height = h;
    return image;
}

void UIGraphicsEndImageContext(void)
{
    if (g_image_context_count <= 0)
        return;
    CGContextRef context = g_image_contexts[--g_image_context_count];
    iosim_cg_end_image(context);
}

/* PNG encoding with stored (uncompressed) deflate blocks, so no zlib is
 * needed. The output is a standards-compliant RGBA PNG. */
static unsigned png_crc_table[256];
static int png_crc_ready;

static unsigned png_crc32(const unsigned char *data, unsigned long length)
{
    if (!png_crc_ready)
    {
        for (unsigned n = 0; n < 256; n++)
        {
            unsigned c = n;
            for (int k = 0; k < 8; k++)
                c = (c & 1) ? 0xedb88320u ^ (c >> 1) : c >> 1;
            png_crc_table[n] = c;
        }
        png_crc_ready = 1;
    }
    unsigned c = 0xffffffffu;
    for (unsigned long i = 0; i < length; i++)
        c = png_crc_table[(c ^ data[i]) & 255] ^ (c >> 8);
    return c ^ 0xffffffffu;
}

static void png_be32(unsigned char *out, unsigned value)
{
    out[0] = (unsigned char)(value >> 24);
    out[1] = (unsigned char)(value >> 16);
    out[2] = (unsigned char)(value >> 8);
    out[3] = (unsigned char)value;
}

static unsigned char *png_emit_chunk(unsigned char *out, const char *type,
                                     const unsigned char *data,
                                     unsigned long length)
{
    png_be32(out, (unsigned)length);
    memcpy(out + 4, type, 4);
    if (data && length)
        memcpy(out + 8, data, length);
    unsigned crc = png_crc32(out + 4, length + 4);
    png_be32(out + 8 + length, crc);
    return out + 12 + length;
}

static unsigned png_adler32(const unsigned char *data, unsigned long length)
{
    unsigned a = 1, b = 0;
    for (unsigned long i = 0; i < length; i++)
    {
        a = (a + data[i]) % 65521u;
        b = (b + a) % 65521u;
    }
    return (b << 16) | a;
}

static NSData *png_encode_rgba(const unsigned char *rgba, int width, int height)
{
    if (!rgba || width <= 0 || height <= 0)
        return nil;
    unsigned long stride = (unsigned long)width * 4 + 1;
    unsigned long raw_size = stride * (unsigned long)height;
    unsigned char *raw = malloc(raw_size);
    if (!raw)
        return nil;
    for (int y = 0; y < height; y++)
    {
        unsigned char *row = raw + (unsigned long)y * stride;
        row[0] = 0; /* no filter */
        memcpy(row + 1, rgba + (unsigned long)y * width * 4,
               (unsigned long)width * 4);
    }
    unsigned long blocks = (raw_size + 65534) / 65535;
    if (blocks == 0)
        blocks = 1;
    unsigned long zlib_size = 2 + raw_size + blocks * 5 + 4;
    unsigned long total = 8 + 25 + 12 + zlib_size + 12;
    unsigned char *out = malloc(total);
    if (!out)
    {
        free(raw);
        return nil;
    }
    static const unsigned char signature[8] =
        { 0x89, 'P', 'N', 'G', '\r', '\n', 0x1a, '\n' };
    memcpy(out, signature, 8);
    unsigned char *p = out + 8;
    unsigned char ihdr[13];
    png_be32(ihdr, (unsigned)width);
    png_be32(ihdr + 4, (unsigned)height);
    ihdr[8] = 8;   /* bit depth */
    ihdr[9] = 6;   /* RGBA */
    ihdr[10] = 0;  /* deflate */
    ihdr[11] = 0;  /* adaptive filtering */
    ihdr[12] = 0;  /* no interlace */
    p = png_emit_chunk(p, "IHDR", ihdr, 13);
    unsigned char *zlib = malloc(zlib_size);
    if (!zlib)
    {
        free(out);
        free(raw);
        return nil;
    }
    unsigned long zpos = 0;
    zlib[zpos++] = 0x78;
    zlib[zpos++] = 0x01;
    unsigned long offset = 0;
    do
    {
        unsigned long chunk = raw_size - offset;
        if (chunk > 65535)
            chunk = 65535;
        int final = offset + chunk >= raw_size;
        zlib[zpos++] = (unsigned char)(final ? 1 : 0);
        zlib[zpos++] = (unsigned char)(chunk & 255);
        zlib[zpos++] = (unsigned char)((chunk >> 8) & 255);
        unsigned nlen = (unsigned)(~chunk) & 0xffffu;
        zlib[zpos++] = (unsigned char)(nlen & 255);
        zlib[zpos++] = (unsigned char)((nlen >> 8) & 255);
        memcpy(zlib + zpos, raw + offset, chunk);
        zpos += chunk;
        offset += chunk;
    } while (offset < raw_size);
    unsigned adler = png_adler32(raw, raw_size);
    zlib[zpos++] = (unsigned char)(adler >> 24);
    zlib[zpos++] = (unsigned char)(adler >> 16);
    zlib[zpos++] = (unsigned char)(adler >> 8);
    zlib[zpos++] = (unsigned char)adler;
    p = png_emit_chunk(p, "IDAT", zlib, zpos);
    p = png_emit_chunk(p, "IEND", 0, 0);
    free(zlib);
    free(raw);
    NSData *data = [NSData dataWithBytes:out length:(unsigned long)(p - out)];
    free(out);
    return data;
}

NSData *UIImagePNGRepresentation(UIImage *image)
{
    if (!image || !image->_rgba || image->_width <= 0 || image->_height <= 0)
        return nil;
    return png_encode_rgba(image->_rgba, image->_width, image->_height);
}

@implementation UIGraphicsImageRendererFormat
- (id)init
{
    self = [super init];
    if (self)
    {
        _scale = [[UIScreen mainScreen] scale];
        if (_scale <= 0)
            _scale = 1.0;
        _opaque = NO;
    }
    return self;
}
+ (id)defaultFormat { return [[self alloc] init]; }
- (double)scale { return _scale; }
- (void)setScale:(double)scale { _scale = scale > 0 ? scale : 1.0; }
- (BOOL)opaque { return _opaque; }
- (void)setOpaque:(BOOL)opaque { _opaque = opaque; }
@end

@implementation UIGraphicsImageRendererContext
- (CGContextRef)CGContext { return _context; }
@end

@implementation UIGraphicsImageRenderer
- (id)initWithSize:(CGSize)size
{
    return [self initWithSize:size
                       format:[[UIGraphicsImageRendererFormat alloc] init]];
}
- (id)initWithSize:(CGSize)size
            format:(UIGraphicsImageRendererFormat *)format
{
    self = [super init];
    if (self)
    {
        _size = size;
        _format = format ? format
                         : [[UIGraphicsImageRendererFormat alloc] init];
    }
    return self;
}
- (UIImage *)imageWithActions:(void (^)(UIGraphicsImageRendererContext *))actions
{
    UIGraphicsBeginImageContextWithOptions(_size, _format->_opaque,
                                           _format->_scale);
    UIGraphicsImageRendererContext *context =
        [[UIGraphicsImageRendererContext alloc] init];
    context->_context = UIGraphicsGetCurrentContext();
    if (actions)
        actions(context);
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}
- (NSData *)PNGDataWithActions:(void (^)(UIGraphicsImageRendererContext *))actions
{
    return UIImagePNGRepresentation([self imageWithActions:actions]);
}
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
@end

@implementation UIBlurEffect
+ (UIBlurEffect *)effectWithStyle:(long)style
{
    UIBlurEffect *effect = [[self alloc] init];
    effect->_style = style;
    return effect;
}
@end

@implementation UIFeedbackGenerator
- (void)prepare { }
@end

@implementation UIImpactFeedbackGenerator
- (id)initWithStyle:(long)style
{
    self = [super init];
    if (self)
        _style = style;
    return self;
}
- (void)impactOccurred { }
- (void)impactOccurredWithIntensity:(double)intensity
{
    (void)intensity;
}
@end

@implementation UISelectionFeedbackGenerator
- (void)selectionChanged { }
@end

@implementation UINotificationFeedbackGenerator
- (void)notificationOccurred:(long)type { (void)type; }
@end

@implementation UIVisualEffectView
- (id)initWithEffect:(UIBlurEffect *)effect
{
    self = [super initWithFrame:CGRectMake(0, 0, 0, 0)];
    if (self)
    {
        _effect = effect;
        _contentView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 0, 0)];
        [self addSubview:_contentView];
    }
    return self;
}
- (UIBlurEffect *)effect { return _effect; }
- (UIView *)contentView { return _contentView; }
@end

/* Animated modal presentation state. The presenting sheet slides up from
 * the bottom over a dimming backdrop; dismissal slides it back down after
 * the controller has already left the presentation stack. */
static int g_modal_animating; /* 1 presenting, -1 dismissing */
static double g_modal_anim_start;
static double g_modal_anim_duration = 0.35;
static void *g_modal_anim_controller;
static void *g_modal_dismissing_controller;

static double modal_progress(void)
{
    if (!g_modal_animating)
        return 1.0;
    double t = (iosim_now() - g_modal_anim_start) / g_modal_anim_duration;
    if (t < 0)
        t = 0;
    if (t > 1)
        t = 1;
    return t;
}

/* Returns 1 while a modal slide is in flight so the UI loop redraws. */
static int iosim_modal_tick(void)
{
    if (!g_modal_animating)
        return 0;
    if (modal_progress() >= 1.0)
    {
        g_modal_animating = 0;
        g_modal_anim_controller = 0;
        g_modal_dismissing_controller = 0;
    }
    return 1;
}

/* Application-wide status bar overrides set through UIApplication. -1 means
 * follow the view controller hierarchy. */
static long g_status_bar_style_override = -1;
static int g_status_bar_hidden_override = -1;
static int g_status_bar_dirty;
static int app_status_bar_hidden(void);

NSString *const UITransitionContextFromViewControllerKey =
    @"UITransitionContextFromViewControllerKey";
NSString *const UITransitionContextToViewControllerKey =
    @"UITransitionContextToViewControllerKey";
NSString *const UITransitionContextFromViewKey =
    @"UITransitionContextFromViewKey";
NSString *const UITransitionContextToViewKey =
    @"UITransitionContextToViewKey";

@implementation _UIViewControllerTransitionContext
- (id)initWithContainerView:(UIView *)container
           fromController:(UIViewController *)from
             toController:(UIViewController *)to
                 animated:(BOOL)animated
        presentationStyle:(long)style
               completion:(void (^)(BOOL completed))completion
{
    self = [super init];
    if (self)
    {
        _containerView = container;
        _fromController = from;
        _toController = to;
        _animated = animated;
        _presentationStyle = style;
        _completion = _Block_copy(completion);
    }
    return self;
}
- (UIView *)containerView { return _containerView; }
- (UIViewController *)viewControllerForKey:(NSString *)key
{
    if (key == UITransitionContextFromViewControllerKey)
        return _fromController;
    if (key == UITransitionContextToViewControllerKey)
        return _toController;
    return nil;
}
- (UIView *)viewForKey:(NSString *)key
{
    if (key == UITransitionContextFromViewKey)
        return _fromController ? _fromController.view : nil;
    if (key == UITransitionContextToViewKey)
        return _toController ? _toController.view : nil;
    return nil;
}
- (CGRect)initialFrameForViewController:(UIViewController *)controller
{
    (void)controller;
    return _containerView ? _containerView->_frame : CGRectMake(0, 0, 0, 0);
}
- (CGRect)finalFrameForViewController:(UIViewController *)controller
{
    (void)controller;
    return _containerView ? _containerView->_frame : CGRectMake(0, 0, 0, 0);
}
- (BOOL)isAnimated { return _animated; }
- (BOOL)isInteractive { return _interactive; }
- (long)presentationStyle { return _presentationStyle; }
- (BOOL)transitionWasCancelled { return _cancelled; }
- (void)completeTransition:(BOOL)didComplete
{
    if (!didComplete)
        _cancelled = YES;
    void (^completion)(BOOL) = _completion;
    _completion = 0;
    if (completion)
        completion(didComplete);
}
- (void)updateInteractiveTransition:(double)percentComplete
{
    (void)percentComplete;
    _interactive = YES;
}
- (void)finishInteractiveTransition { }
- (void)cancelInteractiveTransition { _cancelled = YES; }
- (void)pauseInteractiveTransition { }
@end

@implementation UIPercentDrivenInteractiveTransition
- (id)init
{
    self = [super init];
    if (self)
    {
        _completionSpeed = 1.0;
        _completionCurve = 0;
    }
    return self;
}
- (double)percentComplete { return _percentComplete; }
- (void)setPercentComplete:(double)percent { _percentComplete = percent; }
- (double)completionSpeed { return _completionSpeed; }
- (void)setCompletionSpeed:(double)speed { _completionSpeed = speed; }
- (long)completionCurve { return _completionCurve; }
- (void)setCompletionCurve:(long)curve { _completionCurve = curve; }
- (void)startInteractiveTransition:
    (id<UIViewControllerContextTransitioning>)context
{
    _context = context;
    if (_animator &&
        [(id)_animator respondsToSelector:@selector(animateTransition:)])
        [(id)_animator animateTransition:context];
}
- (void)updateInteractiveTransition:(double)percentComplete
{
    _percentComplete = percentComplete;
    if (_context &&
        [(id)_context respondsToSelector:
            @selector(updateInteractiveTransition:)])
        [(id)_context updateInteractiveTransition:percentComplete];
}
- (void)cancelInteractiveTransition
{
    if (_context &&
        [(id)_context respondsToSelector:@selector(cancelInteractiveTransition)])
        [(id)_context cancelInteractiveTransition];
    if (_context &&
        [(id)_context respondsToSelector:@selector(completeTransition:)])
        [(id)_context completeTransition:NO];
}
- (void)finishInteractiveTransition
{
    if (_context &&
        [(id)_context respondsToSelector:@selector(finishInteractiveTransition)])
        [(id)_context finishInteractiveTransition];
    if (_context &&
        [(id)_context respondsToSelector:@selector(completeTransition:)])
        [(id)_context completeTransition:YES];
}
- (void)pauseInteractiveTransition
{
    if (_context &&
        [(id)_context respondsToSelector:@selector(pauseInteractiveTransition)])
        [(id)_context pauseInteractiveTransition];
}
@end

@implementation UIPresentationController
- (id)presentedViewController { return _presentedViewController; }
- (id)presentingViewController { return _presentingViewController; }
- (UIView *)containerView { return _containerView; }
- (UIView *)presentedView
{
    if (_presentedView)
        return _presentedView;
    if (_presentedViewController)
        return [(UIViewController *)_presentedViewController view];
    return nil;
}
- (CGRect)frameOfPresentedViewInContainerView
{
    if (_containerView)
        return _containerView->_frame;
    return CGRectMake(0, 0, 390, 844);
}
- (long)presentationStyle
{
    if (_presentedViewController)
        return [(UIViewController *)_presentedViewController
            modalPresentationStyle];
    return -2;
}
- (void)presentationTransitionWillBegin { }
- (void)presentationTransitionDidEnd:(BOOL)completed { (void)completed; }
- (void)dismissalTransitionWillBegin { }
- (void)dismissalTransitionDidEnd:(BOOL)completed { (void)completed; }
- (void)containerViewWillLayoutSubviews { }
- (void)containerViewDidLayoutSubviews { }
- (BOOL)shouldRemovePresentersView { return NO; }
- (BOOL)shouldPresentInFullscreen { return YES; }
@end

@implementation UIPopoverPresentationController
- (UIView *)sourceView { return _sourceView; }
- (void)setSourceView:(UIView *)view { _sourceView = view; }
- (CGRect)sourceRect { return _sourceRect; }
- (void)setSourceRect:(CGRect)rect { _sourceRect = rect; }
- (id)barButtonItem { return _barButtonItem; }
- (void)setBarButtonItem:(id)item { _barButtonItem = item; }
- (long)permittedArrowDirections { return _permittedArrowDirections; }
- (void)setPermittedArrowDirections:(long)directions
{
    _permittedArrowDirections = directions;
}
- (id)delegate { return _delegate; }
- (void)setDelegate:(id)delegate { _delegate = delegate; }
- (UIEdgeInsets)popoverLayoutMargins { return _popoverLayoutMargins; }
- (void)setPopoverLayoutMargins:(UIEdgeInsets)insets
{
    _popoverLayoutMargins = insets;
}
@end

@implementation UISheetPresentationControllerDetent
+ (id)mediumDetent
{
    UISheetPresentationControllerDetent *detent = [[self alloc] init];
    detent->_identifier = @"com.apple.UIKit.medium";
    return detent;
}
+ (id)largeDetent
{
    UISheetPresentationControllerDetent *detent = [[self alloc] init];
    detent->_identifier = @"com.apple.UIKit.large";
    return detent;
}
+ (id)customDetentWithIdentifier:(id)identifier
                        resolver:(double (^)(id))resolver
{
    (void)resolver;
    UISheetPresentationControllerDetent *detent = [[self alloc] init];
    detent->_identifier = identifier;
    return detent;
}
- (id)identifier { return _identifier; }
@end

@implementation UISheetPresentationController
- (NSArray *)detents
{
    if (!_detents)
        _detents = @[ [UISheetPresentationControllerDetent largeDetent] ];
    return _detents;
}
- (void)setDetents:(NSArray *)detents { _detents = detents; }
- (BOOL)prefersGrabberVisible { return _prefersGrabberVisible; }
- (void)setPrefersGrabberVisible:(BOOL)visible
{
    _prefersGrabberVisible = visible;
}
- (double)preferredCornerRadius { return _preferredCornerRadius; }
- (void)setPreferredCornerRadius:(double)radius
{
    _preferredCornerRadius = radius;
}
- (id)largestUndimmedDetentIdentifier
{
    return _largestUndimmedDetentIdentifier;
}
- (void)setLargestUndimmedDetentIdentifier:(id)identifier
{
    _largestUndimmedDetentIdentifier = identifier;
}
- (BOOL)prefersScrollingExpandsWhenScrolledToEdge
{
    return _prefersScrollingExpandsWhenScrolledToEdge;
}
- (void)setPrefersScrollingExpandsWhenScrolledToEdge:(BOOL)expands
{
    _prefersScrollingExpandsWhenScrolledToEdge = expands;
}
@end

@implementation _UIViewControllerTransitionCoordinator
- (id)initWithContainerView:(UIView *)container
             fromController:(UIViewController *)from
               toController:(UIViewController *)to
                   animated:(BOOL)animated
                   duration:(double)duration
{
    self = [super init];
    if (self)
    {
        _containerView = container;
        _fromController = from;
        _toController = to;
        _animated = animated;
        _duration = duration;
    }
    return self;
}
- (BOOL)isAnimated { return _animated; }
- (BOOL)isInteractive { return _interactive; }
- (BOOL)isCancelled { return _cancelled; }
- (double)transitionDuration { return _duration; }
- (double)percentComplete { return _percentComplete; }
- (long)completionCurve { return 0; }
- (double)completionVelocity { return 1.0; }
- (UIView *)containerView { return _containerView; }
- (UIViewController *)viewControllerForKey:(NSString *)key
{
    if (key == UITransitionContextFromViewControllerKey)
        return _fromController;
    if (key == UITransitionContextToViewControllerKey)
        return _toController;
    return nil;
}
- (UIView *)viewForKey:(NSString *)key
{
    if (key == UITransitionContextFromViewKey)
        return _fromController ? _fromController.view : nil;
    if (key == UITransitionContextToViewKey)
        return _toController ? _toController.view : nil;
    return nil;
}
- (CGAffineTransform)targetTransform
{
    return CGAffineTransformIdentityValue();
}
- (long)presentationStyle
{
    return _toController ? [_toController modalPresentationStyle] : -2;
}
- (BOOL)animateAlongsideTransition:
    (void (^)(id<UIViewControllerTransitionCoordinatorContext> context))animation
                       completion:
    (void (^)(id<UIViewControllerTransitionCoordinatorContext> context))completion
{
    if (animation)
        animation(self);
    if (completion)
        completion(self);
    return YES;
}
- (BOOL)animateAlongsideTransitionInView:(UIView *)view
                               animation:
    (void (^)(id<UIViewControllerTransitionCoordinatorContext> context))animation
                              completion:
    (void (^)(id<UIViewControllerTransitionCoordinatorContext> context))completion
{
    (void)view;
    return [self animateAlongsideTransition:animation completion:completion];
}
- (void)notifyWhenInteractionChangesUsingBlock:
    (void (^)(id<UIViewControllerTransitionCoordinatorContext> context))handler
{
    (void)handler;
}
- (void)notifyWhenInteractionEndsUsingBlock:
    (void (^)(id<UIViewControllerTransitionCoordinatorContext> context))handler
{
    (void)handler;
}
@end

@implementation UIViewController
- (id)init
{
    self = [super init];
    if (self)
    {
        _modalPresentationStyle = -2; /* automatic: page sheet on iPhone */
        _edgesForExtendedLayout = 15;
        _automaticallyAdjustsScrollViewInsets = YES;
    }
    return self;
}
- (id<UIViewControllerTransitioningDelegate>)transitioningDelegate
{
    return _transitioningDelegate;
}
- (void)setTransitioningDelegate:
    (id<UIViewControllerTransitioningDelegate>)delegate
{
    _transitioningDelegate = delegate;
}
- (unsigned long)edgesForExtendedLayout { return _edgesForExtendedLayout; }
- (void)setEdgesForExtendedLayout:(unsigned long)edges
{
    _edgesForExtendedLayout = edges;
}
- (BOOL)extendedLayoutIncludesOpaqueBars
{
    return _extendedLayoutIncludesOpaqueBars;
}
- (void)setExtendedLayoutIncludesOpaqueBars:(BOOL)includes
{
    _extendedLayoutIncludesOpaqueBars = includes;
}
- (BOOL)automaticallyAdjustsScrollViewInsets
{
    return _automaticallyAdjustsScrollViewInsets;
}
- (void)setAutomaticallyAdjustsScrollViewInsets:(BOOL)adjusts
{
    _automaticallyAdjustsScrollViewInsets = adjusts;
}
- (BOOL)definesPresentationContext { return _definesPresentationContext; }
- (void)setDefinesPresentationContext:(BOOL)defines
{
    _definesPresentationContext = defines;
}
- (BOOL)isModalInPresentation { return _modalInPresentation; }
- (void)setModalInPresentation:(BOOL)modal { _modalInPresentation = modal; }
- (id)restorationIdentifier { return _restorationIdentifier; }
- (void)setRestorationIdentifier:(id)identifier
{
    _restorationIdentifier = identifier;
}
- (CGSize)preferredContentSize { return _preferredContentSize; }
- (void)setPreferredContentSize:(CGSize)size
{
    _preferredContentSize = size;
    if (_parentController &&
        [_parentController respondsToSelector:
            @selector(preferredContentSizeDidChangeForChildContentContainer:)])
        [_parentController
            preferredContentSizeDidChangeForChildContentContainer:self];
}
- (void)preferredContentSizeDidChangeForChildContentContainer:
    (id<UIContentContainer>)container
{
    (void)container;
}
- (void)systemLayoutFittingSizeDidChangeForChildContentContainer:
    (id<UIContentContainer>)container
{
    (void)container;
}
- (id)title { return _title; }
- (UIPopoverPresentationController *)popoverPresentationController
{
    if (!_popoverPresentationController)
    {
        _popoverPresentationController = [[UIPopoverPresentationController alloc] init];
        ((UIPopoverPresentationController *)_popoverPresentationController)->_presentedViewController = self;
    }
    return _popoverPresentationController;
}
- (UISheetPresentationController *)sheetPresentationController
{
    if (!_sheetPresentationController)
    {
        _sheetPresentationController = [[UISheetPresentationController alloc] init];
        ((UISheetPresentationController *)_sheetPresentationController)->_presentedViewController = self;
    }
    return _sheetPresentationController;
}
- (UIPresentationController *)presentationController
{
    if (_presentationController)
        return _presentationController;
    if (_modalPresentationStyle == 7)
        return [self sheetPresentationController];
    return [self popoverPresentationController];
}
- (long)modalPresentationStyle { return _modalPresentationStyle; }
- (void)setModalPresentationStyle:(long)style
{
    _modalPresentationStyle = style;
}
- (long)modalTransitionStyle { return _modalTransitionStyle; }
- (void)setModalTransitionStyle:(long)style
{
    _modalTransitionStyle = style;
}
- (BOOL)modalPresentationCapturesStatusBarAppearance
{
    return _modalPresentationCapturesStatusBarAppearance;
}
- (void)setModalPresentationCapturesStatusBarAppearance:(BOOL)captures
{
    _modalPresentationCapturesStatusBarAppearance = captures;
}
- (BOOL)hidesBottomBarWhenPushed { return _hidesBottomBarWhenPushed; }
- (void)setHidesBottomBarWhenPushed:(BOOL)hides
{
    _hidesBottomBarWhenPushed = hides;
}
- (NSArray *)toolbarItems
{
    return _toolbarItems ? _toolbarItems : @[];
}
- (void)setToolbarItems:(NSArray *)items
{
    _toolbarItems = items;
}
- (void)setToolbarItems:(NSArray *)items animated:(BOOL)animated
{
    (void)animated;
    _toolbarItems = items;
}
- (void)setTitle:(id)title
{
    _title = title;
    UINavigationController *nav = (UINavigationController *)_navigationController;
    if (nav && nav->_navTitleLabel)
        nav->_navTitleLabel->_text = title;
}
- (id)navigationController { return _navigationController; }
- (id)tabBarController
{
    if (_parentController &&
        [_parentController isKindOfClass:[UITabBarController class]])
        return _parentController;
    return nil;
}
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
- (UITraitCollection *)traitCollection
{
    if (_view)
        return [_view traitCollection];
    return ui_trait_for_style(ui_style_current());
}
- (long)overrideUserInterfaceStyle
{
    return _view ? [_view overrideUserInterfaceStyle] :
                   UIUserInterfaceStyleUnspecified;
}
- (void)setOverrideUserInterfaceStyle:(long)style
{
    [self view];
    if (_view)
        [_view setOverrideUserInterfaceStyle:style];
}
- (void)traitCollectionDidChange:(UITraitCollection *)previous
{
    (void)previous;
}
- (long)preferredStatusBarStyle
{
    return UIStatusBarStyleDefault;
}
- (BOOL)prefersStatusBarHidden
{
    return NO;
}
- (UIViewController *)childForStatusBarStyle
{
    return nil;
}
- (UIViewController *)childForStatusBarHidden
{
    return nil;
}
- (void)setNeedsStatusBarAppearanceUpdate
{
    g_status_bar_dirty = 1;
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
- (UIView *)viewIfLoaded { return _view; }
- (BOOL)isViewLoaded { return _view != nil; }
- (void)loadViewIfNeeded { (void)[self view]; }
- (BOOL)isBeingPresented { return _beingPresented; }
- (BOOL)isBeingDismissed { return _beingDismissed; }
- (BOOL)isMovingFromParentViewController { return NO; }
- (BOOL)isMovingToParentViewController { return NO; }
- (BOOL)shouldAutorotate { return YES; }
- (unsigned long)supportedInterfaceOrientations { return 0x1e; }
- (UIViewController *)parentViewController { return _parentController; }
- (NSArray *)children
{
    NSMutableArray *array = [NSMutableArray array];
    for (int i = 0; i < _childCount; i++)
        [array addObject:_children[i]];
    return array;
}
- (void)addChildViewController:(UIViewController *)controller
{
    if (!controller || controller->_parentController == self)
        return;
    if (_childCount < 16)
        _children[_childCount++] = controller;
    controller->_parentController = self;
}
- (void)removeFromParentViewController
{
    UIViewController *parent = _parentController;
    if (!parent)
        return;
    for (int i = 0; i < parent->_childCount; i++)
    {
        if (parent->_children[i] == self)
        {
            for (int j = i; j + 1 < parent->_childCount; j++)
                parent->_children[j] = parent->_children[j + 1];
            parent->_childCount--;
            break;
        }
    }
    _parentController = nil;
}
- (void)willMoveToParentViewController:(UIViewController *)parent
{
    (void)parent;
}
- (void)transitionFromViewController:(UIViewController *)fromViewController
                    toViewController:(UIViewController *)toViewController
                            duration:(double)duration
                             options:(unsigned long)options
                          animations:(void (^)(void))animations
                          completion:(void (^)(BOOL finished))completion
{
    (void)duration;
    (void)options;
    UIView *fromView = [fromViewController view];
    UIView *toView = [toViewController view];
    if (toView)
        [toView setFrame:[fromView frame]];
    if (animations)
        animations();
    [fromView removeFromSuperview];
    if (toView)
        [[self view] addSubview:toView];
    if (completion)
        completion(YES);
}
- (void)didMoveToParentViewController:(UIViewController *)parent
{
    (void)parent;
}
- (void)setView:(UIView *)view
{
    _view = view;
    if (_view)
    {
        _view->_additionalSafeAreaInsets = _additionalSafeAreaInsets;
        _lastTransitionSize = _view->_frame.size;
    }
    if (_view && !_viewLoaded)
    {
        _viewLoaded = YES;
        [self viewDidLoad];
    }
}
- (UIEdgeInsets)additionalSafeAreaInsets
{
    return _additionalSafeAreaInsets;
}
- (void)setAdditionalSafeAreaInsets:(UIEdgeInsets)insets
{
    _additionalSafeAreaInsets = insets;
    if (_view)
    {
        _view->_additionalSafeAreaInsets = insets;
        [_view safeAreaInsetsDidChange];
        [self viewSafeAreaInsetsDidChange];
    }
}
- (void)viewSafeAreaInsetsDidChange { }
- (void)viewWillAppear:(BOOL)animated { (void)animated; }
- (void)viewDidAppear:(BOOL)animated { (void)animated; }
- (void)viewWillDisappear:(BOOL)animated { (void)animated; }
- (void)viewDidDisappear:(BOOL)animated { (void)animated; }
- (void)viewWillLayoutSubviews
{
    if (!_view)
        return;
    CGSize size = _view->_frame.size;
    if (size.width <= 0 || size.height <= 0)
        return;
    if (size.width == _lastTransitionSize.width &&
        size.height == _lastTransitionSize.height)
        return;
    _lastTransitionSize = size;
    _UIViewControllerTransitionCoordinator *coordinator =
        [[_UIViewControllerTransitionCoordinator alloc]
            initWithContainerView:_view
                   fromController:self
                     toController:self
                         animated:NO
                         duration:0.0];
    _transitionCoordinator = coordinator;
    [self viewWillTransitionToSize:size
           withTransitionCoordinator:coordinator];
    _transitionCoordinator = nil;
}
- (void)viewDidLayoutSubviews { }
- (id<UIViewControllerTransitionCoordinator>)transitionCoordinator
{
    return _transitionCoordinator;
}
- (void)viewWillTransitionToSize:(CGSize)size
       withTransitionCoordinator:
    (id<UIViewControllerTransitionCoordinator>)coordinator
{
    for (int i = 0; i < _childCount; i++)
        [_children[i] viewWillTransitionToSize:size
                       withTransitionCoordinator:coordinator];
}
- (void)willTransitionToTraitCollection:(UITraitCollection *)newCollection
              withTransitionCoordinator:
    (id<UIViewControllerTransitionCoordinator>)coordinator
{
    for (int i = 0; i < _childCount; i++)
        [_children[i] willTransitionToTraitCollection:newCollection
                              withTransitionCoordinator:coordinator];
}
- (void)viewDidLoad
{
}
- (void)presentViewController:(UIViewController *)controller animated:(BOOL)animated
                   completion:(void (^)(void))completion
{
    if (!controller)
        return;
    id<UIViewControllerTransitioningDelegate> delegate =
        controller.transitioningDelegate;
    id animator = nil;
    if ([delegate respondsToSelector:@selector(animationControllerForPresentedController:presentingController:sourceController:)])
        animator = [delegate animationControllerForPresentedController:controller
                                                 presentingController:self
                                                     sourceController:self];
    if (animator &&
        [animator respondsToSelector:@selector(animateTransition:)])
    {
        _transitionContext = nil;
        _transitionAnimator = nil;
        UIView *container = [self view];
        UIPresentationController *presentationController = nil;
        if ([delegate respondsToSelector:@selector(presentationControllerForPresentedViewController:presentingViewController:sourceViewController:)])
            presentationController =
                [delegate presentationControllerForPresentedViewController:
                    controller
                    presentingViewController:self
                    sourceViewController:self];
        if (!presentationController)
            presentationController = [[UIPresentationController alloc] init];
        presentationController->_presentedViewController = controller;
        presentationController->_presentingViewController = self;
        presentationController->_containerView = container;
        controller->_presentationController = presentationController;
        [presentationController presentationTransitionWillBegin];
        [presentationController containerViewWillLayoutSubviews];
        UIView *toView = [presentationController presentedView];
        if (!toView)
            toView = [controller view];
        toView.frame =
            [presentationController frameOfPresentedViewInContainerView];
        if (toView.superview && toView.superview != container)
            [toView removeFromSuperview];
        if (!toView.superview)
            [container addSubview:toView];
        [presentationController containerViewDidLayoutSubviews];
        _presentedController = controller;
        controller->_beingPresented = YES;
        [controller viewWillAppear:animated];
        _UIViewControllerTransitionContext *context =
            [[_UIViewControllerTransitionContext alloc]
                initWithContainerView:container
                       fromController:self
                         toController:controller
                             animated:animated
                    presentationStyle:[controller modalPresentationStyle]
                           completion:^(BOOL completed) {
            controller->_beingPresented = NO;
            if (completed)
                [controller viewDidAppear:animated];
            else
            {
                [toView removeFromSuperview];
                if (_presentedController == controller)
                    _presentedController = nil;
                controller->_presentationController = nil;
            }
            [presentationController presentationTransitionDidEnd:completed];
            if ([animator respondsToSelector:@selector(animationEnded:)])
                [(id)animator animationEnded:completed];
            if (completion)
                completion();
        }];
        _transitionContext = context;
        _transitionAnimator = animator;
        id interactive = nil;
        if ([delegate respondsToSelector:@selector(interactionControllerForPresentation:)])
            interactive = [delegate interactionControllerForPresentation:animator];
        if (interactive &&
            [interactive respondsToSelector:@selector(startInteractiveTransition:)])
            [interactive startInteractiveTransition:context];
        else
            [animator animateTransition:context];
        return;
    }
    _presentedController = controller;
    controller->_beingPresented = YES;
    (void)[controller view];
    [controller viewWillAppear:animated];
    [controller viewDidAppear:animated];
    controller->_beingPresented = NO;
    if (animated && ![controller isKindOfClass:[UIAlertController class]])
    {
        g_modal_animating = 1;
        g_modal_anim_start = iosim_now();
        g_modal_anim_controller = controller;
        g_modal_dismissing_controller = 0;
    }
    if (completion)
        completion();
}
- (void)showViewController:(UIViewController *)controller sender:(id)sender
{
    (void)sender;
    [self presentViewController:controller animated:YES completion:nil];
}
- (void)showDetailViewController:(UIViewController *)controller sender:(id)sender
{
    (void)sender;
    [self presentViewController:controller animated:YES completion:nil];
}
- (void)dismissViewControllerAnimated:(BOOL)animated
                           completion:(void (^)(void))completion
{
    UIViewController *controller = (UIViewController *)_presentedController;
    if (!controller)
    {
        if (completion)
            completion();
        return;
    }
    id<UIViewControllerTransitioningDelegate> delegate =
        controller.transitioningDelegate;
    id animator = nil;
    if ([delegate respondsToSelector:@selector(animationControllerForDismissedController:)])
        animator = [delegate animationControllerForDismissedController:
            controller];
    if (animator &&
        [animator respondsToSelector:@selector(animateTransition:)])
    {
        _transitionContext = nil;
        _transitionAnimator = nil;
        UIView *container = [self view];
        UIView *fromView = [controller view];
        (void)container;
        UIPresentationController *presentationController =
            (UIPresentationController *)controller->_presentationController;
        [presentationController dismissalTransitionWillBegin];
        controller->_beingDismissed = YES;
        [controller viewWillDisappear:animated];
        _UIViewControllerTransitionContext *context =
            [[_UIViewControllerTransitionContext alloc]
                initWithContainerView:container
                       fromController:controller
                         toController:self
                             animated:animated
                    presentationStyle:[controller modalPresentationStyle]
                           completion:^(BOOL completed) {
            controller->_beingDismissed = NO;
            if (completed)
            {
                [fromView removeFromSuperview];
                [controller viewDidDisappear:animated];
                if (_presentedController == controller)
                    _presentedController = nil;
            }
            [presentationController dismissalTransitionDidEnd:completed];
            if (completed)
                controller->_presentationController = nil;
            if ([animator respondsToSelector:@selector(animationEnded:)])
                [(id)animator animationEnded:completed];
            if (completion)
                completion();
        }];
        _transitionContext = context;
        _transitionAnimator = animator;
        id interactive = nil;
        if ([delegate respondsToSelector:@selector(interactionControllerForDismissal:)])
            interactive = [delegate interactionControllerForDismissal:animator];
        if (interactive &&
            [interactive respondsToSelector:@selector(startInteractiveTransition:)])
            [interactive startInteractiveTransition:context];
        else
            [animator animateTransition:context];
        return;
    }
    controller->_beingDismissed = YES;
    [controller viewWillDisappear:animated];
    [controller viewDidDisappear:animated];
    controller->_beingDismissed = NO;
    _presentedController = nil;
    if (animated &&
        ![controller isKindOfClass:[UIAlertController class]])
    {
        g_modal_animating = -1;
        g_modal_anim_start = iosim_now();
        g_modal_dismissing_controller = controller;
    }
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
    action->_enabled = YES;
    if (handler)
        action->_handler = (void (^)(UIAlertAction *))_Block_copy(handler);
    return action;
}
- (id)title { return _title; }
- (long)style { return _style; }
- (UIImage *)image { return _image; }
- (void)setImage:(UIImage *)image { _image = image; }
- (BOOL)isEnabled { return _enabled; }
- (void)setEnabled:(BOOL)enabled { _enabled = enabled; }
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
- (NSArray *)textFields
{
    return _textFields ? _textFields : @[];
}
- (void)addTextFieldWithConfigurationHandler:
    (void (^)(UITextField *textField))configurationHandler
{
    if (!_textFields)
        _textFields = [NSMutableArray array];
    UITextField *field = [[UITextField alloc]
        initWithFrame:CGRectMake(0, 0, 240, 30)];
    if (configurationHandler)
        configurationHandler(field);
    [(NSMutableArray *)_textFields addObject:field];
}
- (UIAlertAction *)preferredAction { return _preferredAction; }
- (void)setPreferredAction:(UIAlertAction *)action
{
    _preferredAction = action;
}
@end

/* --------------------------------------------------------- activities */

id UIActivityTypePostToFacebook = @"com.apple.UIKit.activity.PostToFacebook";
id UIActivityTypePostToTwitter = @"com.apple.UIKit.activity.PostToTwitter";
id UIActivityTypePostToWeibo = @"com.apple.UIKit.activity.PostToWeibo";
id UIActivityTypeMessage = @"com.apple.UIKit.activity.Message";
id UIActivityTypeMail = @"com.apple.UIKit.activity.Mail";
id UIActivityTypePrint = @"com.apple.UIKit.activity.Print";
id UIActivityTypeCopyToPasteboard = @"com.apple.UIKit.activity.CopyToPasteboard";
id UIActivityTypeAssignToContact = @"com.apple.UIKit.activity.AssignToContact";
id UIActivityTypeSaveToCameraRoll = @"com.apple.UIKit.activity.SaveToCameraRoll";
id UIActivityTypeAddToReadingList = @"com.apple.UIKit.activity.AddToReadingList";
id UIActivityTypePostToFlickr = @"com.apple.UIKit.activity.PostToFlickr";
id UIActivityTypePostToVimeo = @"com.apple.UIKit.activity.PostToVimeo";
id UIActivityTypePostToTencentWeibo = @"com.apple.UIKit.activity.PostToTencentWeibo";
id UIActivityTypeAirDrop = @"com.apple.UIKit.activity.AirDrop";
id UIActivityTypeOpenIniOSApp = @"com.apple.UIKit.activity.OpenIniOSApp";
id UIActivityTypeMarkupAsPDF = @"com.apple.UIKit.activity.MarkupAsPDF";

/* The activity controller that owns the sheet currently on screen. An
 * activity reports completion through this pointer, which lets a custom
 * asynchronous activity finish long after its row was tapped. */
static UIActivityViewController *g_active_share_controller;
static UIViewController *g_share_presenter;

@implementation UIActivity
+ (long)activityCategory { return UIActivityCategoryAction; }
- (UIActivityType)activityType { return nil; }
- (id)activityTitle { return nil; }
- (UIImage *)activityImage { return nil; }
- (BOOL)canPerformWithActivityItems:(NSArray *)activityItems
{
    (void)activityItems;
    return YES;
}
- (void)prepareWithActivityItems:(NSArray *)activityItems
{
    (void)activityItems;
}
- (UIViewController *)activityViewController { return nil; }
- (void)performActivity
{
    [self activityDidFinish:YES];
}
- (void)activityDidFinish:(BOOL)completed
{
    UIActivityViewController *controller = g_active_share_controller;
    if (controller)
        [controller _activityDidFinish:self completed:completed];
}
@end

static id share_item_for_activity_type(UIActivityViewController *controller,
                                       id type)
{
    if (!controller || !controller->_activityItems ||
        [controller->_activityItems count] == 0)
        return nil;
    id item = [controller->_activityItems objectAtIndex:0];
    if ([item respondsToSelector:@selector(activityViewController:itemForActivityType:)])
        return [(id<UIActivityItemSource>)item
            activityViewController:controller itemForActivityType:type];
    return item;
}

static id share_string_for_item(id item)
{
    if (!item)
        return nil;
    if ([item isKindOfClass:[NSString class]])
        return item;
    if ([item respondsToSelector:@selector(absoluteString)])
        return [(NSURL *)item absoluteString];
    return [item description];
}

@interface UIActivityCopy : UIActivity
@end

@implementation UIActivityCopy
- (id)activityType { return UIActivityTypeCopyToPasteboard; }
- (id)activityTitle { return @"Copy"; }
- (void)performActivity
{
    id item = share_item_for_activity_type(g_active_share_controller,
                                           UIActivityTypeCopyToPasteboard);
    id string = share_string_for_item(item);
    if (string)
        [[UIPasteboard generalPasteboard] setString:string];
    [self activityDidFinish:YES];
}
@end

@implementation UIActivityViewController
- (id)initWithActivityItems:(NSArray *)activityItems
       applicationActivities:(NSArray *)applicationActivities
{
    self = [super init];
    if (self)
    {
        _activityItems = activityItems;
        _applicationActivities = applicationActivities;
    }
    return self;
}
- (NSArray *)activityItems { return _activityItems; }
- (NSArray *)applicationActivities { return _applicationActivities; }
- (void)setExcludedActivityTypes:(NSArray *)excludedActivityTypes
{
    _excludedActivityTypes = excludedActivityTypes;
    _availableActivities = nil;
}
- (NSArray *)excludedActivityTypes { return _excludedActivityTypes; }
- (void)setCompletionWithItemsHandler:(void (^)(id, BOOL, id, id))handler
{
    _completionWithItemsHandler =
        handler ? (void (^)(id, BOOL, id, id))_Block_copy(handler) : 0;
}
- (void (^)(id, BOOL, id, id))completionWithItemsHandler
{
    return _completionWithItemsHandler;
}
- (void)setCompletionHandler:(void (^)(id, BOOL))handler
{
    _completionHandler = handler ? (void (^)(id, BOOL))_Block_copy(handler) : 0;
}
- (void (^)(id, BOOL))completionHandler { return _completionHandler; }

/* The sheet lists every application activity that accepts the items plus
 * the built-in Copy action, filtered by excludedActivityTypes. The list is
 * built once per configuration so drawing and hit testing share it. */
- (NSArray *)_availableActivities
{
    if (_availableActivities)
        return _availableActivities;
    NSMutableArray *list = [NSMutableArray array];
    unsigned long count =
        _applicationActivities ? [_applicationActivities count] : 0;
    for (unsigned long i = 0; i < count && i < 16; i++)
    {
        UIActivity *activity =
            (UIActivity *)[_applicationActivities objectAtIndex:i];
        if (!activity)
            continue;
        if (_excludedActivityTypes && [activity activityType] &&
            [_excludedActivityTypes containsObject:[activity activityType]])
            continue;
        if ([activity canPerformWithActivityItems:_activityItems])
            [list addObject:activity];
    }
    if (!(_excludedActivityTypes &&
          [_excludedActivityTypes containsObject:UIActivityTypeCopyToPasteboard]))
        [list addObject:[[UIActivityCopy alloc] init]];
    _availableActivities = list;
    return list;
}

- (void)_activityDidFinish:(UIActivity *)activity completed:(BOOL)completed
{
    id type = [activity activityType];
    if (_completionWithItemsHandler)
        _completionWithItemsHandler(type, completed, nil, nil);
    else if (_completionHandler)
        _completionHandler(type, completed);
    UIViewController *presenter = g_share_presenter;
    g_share_presenter = nil;
    g_active_share_controller = nil;
    if (presenter && presenter->_presentedController == self)
        [presenter dismissViewControllerAnimated:YES completion:nil];
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
- (id)initWithImage:(UIImage *)image style:(long)style target:(id)target
             action:(SEL)action
{
    self = [self initWithTitle:nil style:style target:target action:action];
    if (self)
        _image = image;
    return self;
}
- (id)initWithCustomView:(UIView *)view
{
    self = [super init];
    if (self)
    {
        _customView = view;
        _enabled = YES;
    }
    return self;
}
- (id)title { return _title; }
- (void)setTitle:(id)title { _title = title; }
- (long)style { return _style; }
- (void)setStyle:(long)style { _style = style; }
- (long)systemItem { return _systemItem; }
- (id)target { return _target; }
- (SEL)action { return _action; }
- (UIImage *)image { return _image; }
- (void)setImage:(UIImage *)image { _image = image; }
- (UIColor *)tintColor { return _tintColor; }
- (void)setTintColor:(UIColor *)color { _tintColor = color; }
- (id)customView { return _customView; }
- (double)width { return _width; }
- (void)setWidth:(double)width { _width = width; }
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
- (void)setLeftBarButtonItem:(id)item
{
    _leftBarButtonItem = item;
    _leftBarButtonItems = nil;
}
- (id)rightBarButtonItem { return _rightBarButtonItem; }
- (void)setRightBarButtonItem:(id)item
{
    _rightBarButtonItem = item;
    _rightBarButtonItems = nil;
}
- (id)backBarButtonItem { return _backBarButtonItem; }
- (void)setBackBarButtonItem:(id)item { _backBarButtonItem = item; }
- (BOOL)hidesBackButton { return _hidesBackButton; }
- (void)setHidesBackButton:(BOOL)hidden { _hidesBackButton = hidden; }
- (id)backButtonTitle { return _backButtonTitle; }
- (void)setBackButtonTitle:(id)title { _backButtonTitle = title; }
- (NSArray *)leftBarButtonItems
{
    if (_leftBarButtonItems)
        return _leftBarButtonItems;
    return _leftBarButtonItem ? @[ _leftBarButtonItem ] : @[];
}
- (void)setLeftBarButtonItems:(NSArray *)items
{
    _leftBarButtonItems = items;
    _leftBarButtonItem = [items count] ? [items objectAtIndex:0] : nil;
}
- (void)setLeftBarButtonItems:(NSArray *)items animated:(BOOL)animated
{
    (void)animated;
    [self setLeftBarButtonItems:items];
}
- (NSArray *)rightBarButtonItems
{
    if (_rightBarButtonItems)
        return _rightBarButtonItems;
    return _rightBarButtonItem ? @[ _rightBarButtonItem ] : @[];
}
- (void)setRightBarButtonItems:(NSArray *)items
{
    _rightBarButtonItems = items;
    _rightBarButtonItem = [items count] ? [items objectAtIndex:0] : nil;
}
- (void)setRightBarButtonItems:(NSArray *)items animated:(BOOL)animated
{
    (void)animated;
    [self setRightBarButtonItems:items];
}
- (id)prompt { return _prompt; }
- (void)setPrompt:(id)prompt { _prompt = prompt; }
- (id)searchController { return _searchController; }
- (void)setSearchController:(id)controller
{
    _searchController = controller;
}
- (long)largeTitleDisplayMode { return _largeTitleDisplayMode; }
- (void)setLargeTitleDisplayMode:(long)mode
{
    _largeTitleDisplayMode = mode;
}
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
    if (item && item->_image)
    {
        label->_text = nil;
        UIImageView *imageView = [[UIImageView alloc] initWithImage:item->_image];
        double size = 24;
        imageView->_frame = CGRectMake(alignRight ? frame.size.width - size : 0,
                                       (frame.size.height - size) / 2,
                                       size, size);
        [control addSubview:imageView];
    }
    else
        [control addSubview:label];
    if (item)
        [control addTarget:item->_target action:item->_action
         forControlEvents:UIControlEventTouchUpInside];
    return control;
}

/* --------------------------------------------------- interactive nav pop */

/* The interactive pop keeps both controllers' views on screen: the previous
 * controller's view slides in from a 30% left parallax under a dark overlay
 * that fades with progress, while the top view tracks the finger and casts a
 * left-edge shadow. Releasing past halfway (or with a rightward flick)
 * animates to completion; otherwise the views return and the stack stays. */
static struct {
    int active;
    int animating; /* 1 finishing, -1 cancelling */
    double animStart, animDuration;
    double animFrom, animTo;
    UINavigationController *nav;
    UIView *fromView;
    UIView *toView;
    UIView *dimView;
    double savedShadowOpacity, savedShadowRadius;
    CGSize savedShadowOffset;
    UIColor *savedShadowColor;
} g_nav_transition;

static void nav_transition_apply(double progress)
{
    if (!g_nav_transition.nav || !g_nav_transition.nav->_view)
        return;
    if (progress < 0.0)
        progress = 0.0;
    if (progress > 1.0)
        progress = 1.0;
    double width = g_nav_transition.nav->_view->_frame.size.width;
    if (g_nav_transition.toView)
        g_nav_transition.toView->_frame.origin.x =
            -0.3 * width * (1.0 - progress);
    if (g_nav_transition.fromView)
        g_nav_transition.fromView->_frame.origin.x = width * progress;
    if (g_nav_transition.dimView)
        g_nav_transition.dimView->_alpha = 0.47 * (1.0 - progress);
}

static void nav_transition_cleanup(void)
{
    if (g_nav_transition.dimView)
        [g_nav_transition.dimView removeFromSuperview];
    if (g_nav_transition.toView)
        [g_nav_transition.toView removeFromSuperview];
    UIView *fromView = g_nav_transition.fromView;
    if (fromView)
    {
        CGRect frame = fromView->_frame;
        frame.origin.x = 0;
        fromView->_frame = frame;
        if (fromView->_layer)
        {
            fromView->_layer->_shadowOpacity =
                g_nav_transition.savedShadowOpacity;
            fromView->_layer->_shadowRadius =
                g_nav_transition.savedShadowRadius;
            fromView->_layer->_shadowOffset =
                g_nav_transition.savedShadowOffset;
            fromView->_layer->_shadowColor =
                g_nav_transition.savedShadowColor;
        }
    }
    g_nav_transition.active = 0;
    g_nav_transition.animating = 0;
    g_nav_transition.nav = nil;
    g_nav_transition.fromView = nil;
    g_nav_transition.toView = nil;
    g_nav_transition.dimView = nil;
}

static void nav_transition_begin(UINavigationController *nav)
{
    if (!nav || nav->_stackCount <= 1 || nav->_navBarHidden)
        return;
    if (g_nav_transition.active || g_nav_transition.animating)
        return;
    UIViewController *from =
        (UIViewController *)nav->_stack[nav->_stackCount - 1];
    UIViewController *to =
        (UIViewController *)nav->_stack[nav->_stackCount - 2];
    UIView *fromView = [from view];
    UIView *toView = [to view];
    if (!fromView || !toView || !nav->_view)
        return;
    double navHeight = nav->_navBarHidden ? 0 : 100;
    CGRect bounds = nav->_view->_frame;
    CGRect content = CGRectMake(0, navHeight, bounds.size.width,
                                bounds.size.height - navHeight);
    toView->_frame = content;
    toView->_hidden = NO;
    toView->_alpha = 1.0;
    [nav->_view insertSubview:toView atIndex:0];
    UIView *dim = [[UIView alloc] initWithFrame:content];
    dim->_backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:1.0];
    dim->_alpha = 0.47;
    [nav->_view insertSubview:dim atIndex:1];

    g_nav_transition.savedShadowOpacity = fromView->_layer->_shadowOpacity;
    g_nav_transition.savedShadowRadius = fromView->_layer->_shadowRadius;
    g_nav_transition.savedShadowOffset = fromView->_layer->_shadowOffset;
    g_nav_transition.savedShadowColor = fromView->_layer->_shadowColor;
    fromView->_layer->_shadowColor = [UIColor blackColor];
    fromView->_layer->_shadowOpacity = 0.35;
    fromView->_layer->_shadowRadius = 12.0;
    fromView->_layer->_shadowOffset = CGSizeMake(-10.0, 0.0);

    g_nav_transition.active = 1;
    g_nav_transition.animating = 0;
    g_nav_transition.nav = nav;
    g_nav_transition.fromView = fromView;
    g_nav_transition.toView = toView;
    g_nav_transition.dimView = dim;
    nav_transition_apply(0.0);
}

static void nav_transition_update(double progress)
{
    if (!g_nav_transition.active || g_nav_transition.animating)
        return;
    nav_transition_apply(progress);
}

static void nav_transition_end(double progress, CGPoint velocity)
{
    if (!g_nav_transition.active || g_nav_transition.animating)
        return;
    int finish = progress > 0.5 || velocity.x > 500.0;
    g_nav_transition.animating = finish ? 1 : -1;
    g_nav_transition.animFrom = progress;
    g_nav_transition.animTo = finish ? 1.0 : 0.0;
    double distance = __builtin_fabs(g_nav_transition.animTo - progress);
    g_nav_transition.animDuration = 0.35 * distance;
    if (g_nav_transition.animDuration < 0.001)
        g_nav_transition.animDuration = 0.001;
    g_nav_transition.animStart = iosim_now();
}

static int iosim_nav_tick(void)
{
    if (!g_nav_transition.animating)
        return 0;
    double t = (iosim_now() - g_nav_transition.animStart) /
               g_nav_transition.animDuration;
    if (t < 0.0)
        t = 0.0;
    if (t > 1.0)
        t = 1.0;
    if (t >= 1.0)
    {
        int finishing = g_nav_transition.animating == 1;
        UINavigationController *nav = g_nav_transition.nav;
        nav_transition_cleanup();
        if (finishing && nav)
            [nav popViewControllerAnimated:NO];
        return 1;
    }
    double e = 1.0 - (1.0 - t) * (1.0 - t);
    nav_transition_apply(g_nav_transition.animFrom +
                         (g_nav_transition.animTo -
                          g_nav_transition.animFrom) * e);
    return 1;
}

@implementation UINavigationController
- (id)delegate { return _delegate; }
- (void)setDelegate:(id)delegate { _delegate = delegate; }
- (void)notifyShowViewController:(UIViewController *)controller
                        animated:(BOOL)animated
                            will:(BOOL)will
{
    SEL selector = will
        ? @selector(navigationController:willShowViewController:animated:)
        : @selector(navigationController:didShowViewController:animated:);
    if (_delegate && [(_delegate) respondsToSelector:selector])
    {
        if (will)
            [_delegate navigationController:self
                     willShowViewController:controller animated:animated];
        else
            [_delegate navigationController:self
                      didShowViewController:controller animated:animated];
    }
}
- (UINavigationBar *)navigationBar
{
    (void)[self view];
    return (UINavigationBar *)_navBar;
}
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
- (void)setViewControllers:(NSArray *)controllers animated:(BOOL)animated
{
    (void)animated;
    _stackCount = 0;
    for (unsigned long i = 0;
         controllers && i < [controllers count] && _stackCount < 32; i++)
    {
        UIViewController *controller = [controllers objectAtIndex:i];
        _stack[_stackCount++] = controller;
        controller->_navigationController = self;
    }
    if (_viewLoaded)
    {
        UIViewController *top = [self topViewController];
        [self notifyShowViewController:top animated:animated will:YES];
        [self installTopViewController];
        [self notifyShowViewController:top animated:animated will:NO];
    }
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
        _navBar = [[UINavigationBar alloc] initWithFrame:CGRectMake(0, 0, bounds.size.width,
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
        _navToolbar = [[UIToolbar alloc] initWithFrame:
            CGRectMake(0, bounds.size.height - 49, bounds.size.width, 49)];
        _navToolbar.hidden = YES;
        [_view addSubview:_navToolbar];
        (void)color;
        [self installTopViewController];
        _interactivePopGesture = [[UIScreenEdgePanGestureRecognizer alloc]
            initWithTarget:self action:@selector(handleInteractivePop:)];
        [(UIScreenEdgePanGestureRecognizer *)_interactivePopGesture
            setEdges:UIRectEdgeLeft];
        [_view addGestureRecognizer:_interactivePopGesture];
    }
}
- (UIGestureRecognizer *)interactivePopGestureRecognizer
{
    (void)[self view];
    return _interactivePopGesture;
}
- (UIToolbar *)toolbar
{
    (void)[self view];
    return _navToolbar;
}
- (void)setToolbarHidden:(BOOL)hidden animated:(BOOL)animated
{
    (void)animated;
    _toolbarHidden = hidden;
    if (_navToolbar)
    {
        _navToolbar.hidden = hidden;
        [self installTopViewController];
    }
}
- (void)setToolbarHidden:(BOOL)hidden
{
    [self setToolbarHidden:hidden animated:NO];
}
- (BOOL)isToolbarHidden { return _toolbarHidden; }
- (void)handleInteractivePop:(UIScreenEdgePanGestureRecognizer *)gesture
{
    if (_stackCount <= 1 || _navBarHidden)
        return;
    double width = _view ? _view->_frame.size.width : 0;
    if (width <= 0)
        width = 1;
    double progress = [gesture translationInView:_view].x / width;
    long state = [gesture state];
    if (getenv("IOSIM_DEBUG_NAV"))
        fprintf(stderr, "[navdbg] state=%ld t=%.1f p=%.2f v=%.0f now=%.3f\n",
                state, [gesture translationInView:_view].x, progress,
                [gesture velocityInView:_view].x, iosim_now());
    if (state == UIGestureRecognizerStateBegan)
    {
        nav_transition_begin(self);
        nav_transition_update(progress);
    }
    else if (state == UIGestureRecognizerStateChanged)
        nav_transition_update(progress);
    else if (state == UIGestureRecognizerStateEnded)
        nav_transition_end(progress, [gesture velocityInView:_view]);
    else if (state == UIGestureRecognizerStateCancelled ||
             state == UIGestureRecognizerStateFailed)
        nav_transition_end(progress, CGPointMake(0, 0));
}
- (void)installTopViewController
{
    UIViewController *top = [self topViewController];
    if (!top || !_view)
        return;
    if (_contentView)
        [_contentView removeFromSuperview];
    double navHeight = _navBarHidden ? 0 : 100;
    double toolbarHeight = (_toolbarHidden || !_navToolbar) ? 0 : 49;
    CGRect bounds = _view->_frame;
    if (_navToolbar)
    {
        _navToolbar.frame = CGRectMake(0, bounds.size.height - 49,
                                       bounds.size.width, 49);
        _navToolbar.hidden = _toolbarHidden;
        [_navToolbar setItems:[top toolbarItems] animated:NO];
    }
    UIView *content = [top view];
    content->_frame = CGRectMake(0, navHeight, bounds.size.width,
                                 bounds.size.height - navHeight - toolbarHeight);
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
    if (_interactivePopGesture)
        _interactivePopGesture->_enabled =
            (_stackCount > 1 && !_navBarHidden);
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
    [self notifyShowViewController:controller animated:animated will:YES];
    [self installTopViewController];
    [controller viewWillAppear:NO];
    [controller viewDidAppear:NO];
    [self notifyShowViewController:controller animated:animated will:NO];
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
    [self notifyShowViewController:top animated:animated will:YES];
    [self installTopViewController];
    [top viewWillAppear:NO];
    [top viewDidAppear:NO];
    [self notifyShowViewController:top animated:animated will:NO];
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
- (BOOL)navigationBarHidden { return _navBarHidden; }
- (void)setNavigationBarHidden:(BOOL)hidden
{
    [self setNavigationBarHidden:hidden animated:NO];
}
@end

/* ------------------------------------------------------- standalone bars */

static UIControl *toolbar_text_control(UIBarButtonItem *item, CGRect frame,
                                       UIColor *color)
{
    UIControl *control = [[UIControl alloc] initWithFrame:frame];
    UILabel *label = [[UILabel alloc]
        initWithFrame:CGRectMake(0, 0, frame.size.width, frame.size.height)];
    label->_text = item ? item->_title : @"";
    label->_font = [UIFont systemFontOfSize:17];
    label->_textColor = color ? color
                              : [UIColor colorWithRed:0.04 green:0.52
                                                 blue:1.0 alpha:1.0];
    label->_textAlignment = 1;
    [control addSubview:label];
    if (item)
        [control addTarget:item->_target action:item->_action
         forControlEvents:UIControlEventTouchUpInside];
    return control;
}

@implementation UINavigationBar
- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        _backgroundColor = [UIColor colorWithRed:0.11 green:0.11 blue:0.12
                                             alpha:0.96];
        _titleLabel = [[UILabel alloc]
            initWithFrame:CGRectMake(0, 0, frame.size.width,
                                     frame.size.height)];
        _titleLabel->_textAlignment = 1;
        _titleLabel->_font = [UIFont systemFontOfSize:17];
        _titleLabel->_textColor = [UIColor whiteColor];
        [self addSubview:_titleLabel];
    }
    return self;
}
- (void)setItems:(NSArray *)items animated:(BOOL)animated
{
    (void)animated;
    _items = items;
    _topItem = items && [items count] > 0
        ? (UINavigationItem *)[items objectAtIndex:[items count] - 1]
        : nil;
    [self setNeedsLayout];
}
- (NSArray *)items { return _items; }
- (UINavigationItem *)topItem { return _topItem; }
- (void)pushNavigationItem:(UINavigationItem *)item animated:(BOOL)animated
{
    (void)animated;
    if (!item)
        return;
    NSMutableArray *items = [NSMutableArray arrayWithArray:_items];
    [items addObject:item];
    _items = items;
    _topItem = item;
    [self setNeedsLayout];
}
- (UINavigationItem *)popNavigationItemAnimated:(BOOL)animated
{
    (void)animated;
    if (!_items || [_items count] <= 1)
        return nil;
    NSMutableArray *items = [NSMutableArray arrayWithArray:_items];
    UINavigationItem *old = _topItem;
    [items removeObjectAtIndex:[items count] - 1];
    _items = items;
    _topItem = (UINavigationItem *)[items objectAtIndex:[items count] - 1];
    [self setNeedsLayout];
    return old;
}
- (void)setBarTintColor:(UIColor *)color
{
    _barTintColor = color;
    if (color)
        _backgroundColor = color;
}
- (UIColor *)barTintColor { return _barTintColor; }
- (long)barStyle { return _barStyle; }
- (void)setBarStyle:(long)style { _barStyle = style; }
- (BOOL)prefersLargeTitles { return _prefersLargeTitles; }
- (void)setPrefersLargeTitles:(BOOL)prefers
{
    _prefersLargeTitles = prefers;
    [self setNeedsLayout];
}
- (BOOL)isTranslucent { return _translucent; }
- (void)setTranslucent:(BOOL)translucent { _translucent = translucent; }
- (id)titleTextAttributes { return _titleTextAttributes; }
- (void)setTitleTextAttributes:(id)attributes
{
    _titleTextAttributes = attributes;
}
- (id)largeTitleTextAttributes { return _largeTitleTextAttributes; }
- (void)setLargeTitleTextAttributes:(id)attributes
{
    _largeTitleTextAttributes = attributes;
}
- (void)layoutSubviews
{
    double width = _frame.size.width;
    double height = _frame.size.height;
    if (_titleLabel)
    {
        _titleLabel->_frame = CGRectMake(70, (height - 24) / 2, width - 140, 24);
        _titleLabel->_text = _topItem ? _topItem->_title : nil;
        _titleLabel->_needsLayout = YES;
    }
    if (_leftControl)
        [(UIView *)_leftControl removeFromSuperview];
    if (_rightControl)
        [(UIView *)_rightControl removeFromSuperview];
    _leftControl = nil;
    _rightControl = nil;
    if (_topItem && _topItem->_leftBarButtonItem)
    {
        _leftControl = nav_bar_control(
            (UIBarButtonItem *)_topItem->_leftBarButtonItem,
            CGRectMake(8, (height - 32) / 2, 120, 32), 0);
        [self addSubview:_leftControl];
    }
    if (_topItem && _topItem->_rightBarButtonItem)
    {
        _rightControl = nav_bar_control(
            (UIBarButtonItem *)_topItem->_rightBarButtonItem,
            CGRectMake(width - 128, (height - 32) / 2, 120, 32), 2);
        [self addSubview:_rightControl];
    }
}
- (void)drawRect:(CGRect)rect
{
    (void)rect;
    CGContextRef context = 0;
    CGContextSetRGBFillColor(context, 1, 1, 1, 0.08);
    CGContextFillRect(context, CGRectMake(0, _frame.size.height - 1,
                                          _frame.size.width, 1));
}
@end

@implementation UIToolbar
- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        _backgroundColor = [UIColor colorWithRed:0.11 green:0.11 blue:0.12
                                             alpha:0.96];
        _barStyle = 0;
        _translucent = YES;
    }
    return self;
}
- (void)setItems:(NSArray *)items animated:(BOOL)animated
{
    (void)animated;
    _items = items;
    [self setNeedsLayout];
}
- (NSArray *)items { return _items; }
- (void)setBarTintColor:(UIColor *)color
{
    _barTintColor = color;
    if (color)
        _backgroundColor = color;
}
- (UIColor *)barTintColor { return _barTintColor; }
- (void)setTintColor:(UIColor *)color { _tintColor = color; }
- (UIColor *)tintColor { return _tintColor; }
- (void)setBarStyle:(int)style { _barStyle = style; }
- (int)barStyle { return _barStyle; }
- (void)setTranslucent:(BOOL)translucent { _translucent = translucent; }
- (BOOL)isTranslucent { return _translucent; }
- (void)layoutSubviews
{
    for (int i = 0; i < _controlCount; i++)
        if (_controls[i])
            [(UIView *)_controls[i] removeFromSuperview];
    _controlCount = 0;
    int count = _items ? (int)[_items count] : 0;
    if (count > 16)
        count = 16;
    if (count <= 0)
        return;
    double widths[16];
    double total = 0;
    double padding = 24.0;
    double gap = 16.0;
    for (int i = 0; i < count; i++)
    {
        UIBarButtonItem *item = (UIBarButtonItem *)[_items objectAtIndex:i];
        const char *title = item && item->_title ? iosim_string_cstr(item->_title)
                                                 : "";
        widths[i] = iosim_fb_font_text_width(title, IOSIM_FONT_REGULAR, 17.0,
                                             1.0) + 2 * padding;
        total += widths[i];
        if (i > 0)
            total += gap;
    }
    double width = _frame.size.width;
    double height = _frame.size.height;
    double x = (width - total) / 2;
    if (x < 8)
        x = 8;
    for (int i = 0; i < count; i++)
    {
        UIBarButtonItem *item = (UIBarButtonItem *)[_items objectAtIndex:i];
        _controls[i] = toolbar_text_control(
            item, CGRectMake(x, (height - 32) / 2, widths[i], 32),
            _tintColor);
        [self addSubview:_controls[i]];
        _controlCount++;
        x += widths[i] + gap;
    }
}
- (void)drawRect:(CGRect)rect
{
    (void)rect;
    CGContextRef context = 0;
    CGContextSetRGBFillColor(context, 1, 1, 1, 0.08);
    CGContextFillRect(context, CGRectMake(0, 0, _frame.size.width, 1));
}
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
- (id)delegate { return _delegate; }
- (void)setDelegate:(id)delegate { _delegate = delegate; }
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
- (void)setViewControllers:(NSArray *)controllers animated:(BOOL)animated
{
    (void)animated;
    [self setViewControllers:controllers];
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
    if (_delegate && selected &&
        [_delegate respondsToSelector:
            @selector(tabBarController:didSelectViewController:)])
        [_delegate tabBarController:self didSelectViewController:selected];
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

@implementation UIButtonConfiguration
+ (id)plainButtonConfiguration { return [[self alloc] init]; }
+ (id)filledButtonConfiguration
{
    UIButtonConfiguration *config = [[self alloc] init];
    config->_baseBackgroundColor = [UIColor systemBlueColor];
    config->_baseForegroundColor = [UIColor whiteColor];
    config->_cornerStyle = UIButtonConfigurationCornerStyleDynamic;
    return config;
}
+ (id)grayButtonConfiguration
{
    UIButtonConfiguration *config = [[self alloc] init];
    config->_baseBackgroundColor = [UIColor colorWithWhite:0.5 alpha:0.25];
    config->_cornerStyle = UIButtonConfigurationCornerStyleDynamic;
    return config;
}
+ (id)tintedButtonConfiguration
{
    UIButtonConfiguration *config = [[self alloc] init];
    config->_baseForegroundColor = [UIColor systemBlueColor];
    config->_cornerStyle = UIButtonConfigurationCornerStyleDynamic;
    return config;
}
+ (id)borderedButtonConfiguration
{
    UIButtonConfiguration *config = [[self alloc] init];
    config->_cornerStyle = UIButtonConfigurationCornerStyleDynamic;
    return config;
}
+ (id)borderlessButtonConfiguration { return [[self alloc] init]; }
+ (id)configurationWithTitle:(id)title
{
    UIButtonConfiguration *config = [[self alloc] init];
    config->_title = title;
    return config;
}
- (id)title { return _title; }
- (void)setTitle:(id)title { _title = title; }
- (id)subtitle { return _subtitle; }
- (void)setSubtitle:(id)subtitle { _subtitle = subtitle; }
- (UIImage *)image { return _image; }
- (void)setImage:(UIImage *)image { _image = image; }
- (UIColor *)baseForegroundColor { return _baseForegroundColor; }
- (void)setBaseForegroundColor:(UIColor *)color { _baseForegroundColor = color; }
- (UIColor *)baseBackgroundColor { return _baseBackgroundColor; }
- (void)setBaseBackgroundColor:(UIColor *)color { _baseBackgroundColor = color; }
- (long)cornerStyle { return _cornerStyle; }
- (void)setCornerStyle:(long)style { _cornerStyle = style; }
- (UIEdgeInsets)contentInsets { return _contentInsets; }
- (void)setContentInsets:(UIEdgeInsets)insets { _contentInsets = insets; }
- (double)imagePadding { return _imagePadding; }
- (void)setImagePadding:(double)padding { _imagePadding = padding; }
@end

@implementation UIButton
- (UIButtonConfiguration *)configuration { return _configuration; }
- (void)setConfiguration:(UIButtonConfiguration *)configuration
{
    _configuration = configuration;
    if (!configuration)
        return;
    [self setTitle:configuration->_title forState:0];
    if (configuration->_image)
        [self setImage:configuration->_image forState:0];
    if (configuration->_baseForegroundColor)
        [self setTitleColor:configuration->_baseForegroundColor forState:0];
    if (configuration->_baseBackgroundColor)
        [self setBackgroundColor:configuration->_baseBackgroundColor];
    if (configuration->_cornerStyle == UIButtonConfigurationCornerStyleCapsule)
        [[self layer] setCornerRadius:_frame.size.height / 2];
    else if (configuration->_cornerStyle != 0)
        [[self layer] setCornerRadius:8];
}
- (void)setNeedsUpdateConfiguration { }
- (void)updateConfiguration { }
- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        UILabel *label =
            [[UILabel alloc] initWithFrame:CGRectMake(0, 0, frame.size.width,
                                                      frame.size.height)];
        label->_textAlignment = 1;
        label->_font = [UIFont systemFontOfSize:17];
        label->_textColor = [self tintColor];
        [self addSubview:label];
        _titleLabel = label;
        _isAccessibilityElement = YES;
        _accessibilityTraits = 1;
    }
    return self;
}
+ (id)buttonWithType:(int)type
{
    (void)type;
    return [[self alloc] initWithFrame:CGRectMake(0, 0, 0, 0)];
}
- (void)layoutTitle
{
    double inset = 0;
    if (_imageView && _image)
    {
        double iw = _image->_width / 3.0;
        double ih = _image->_height / 3.0;
        if (iw <= 0 || ih <= 0)
        {
            iw = _image->_width;
            ih = _image->_height;
        }
        double x = 0;
        if (_title && [_title length] > 0)
        {
            x = 12;
            inset = iw + 20;
        }
        else
        {
            x = (_frame.size.width - iw) / 2;
        }
        _imageView->_frame = CGRectMake(x, (_frame.size.height - ih) / 2,
                                        iw, ih);
    }
    if (_titleLabel)
        _titleLabel->_frame = CGRectMake(inset + _contentEdgeInsets.left,
                                         _contentEdgeInsets.top,
                                         _frame.size.width - inset -
                                             _contentEdgeInsets.left -
                                             _contentEdgeInsets.right,
                                         _frame.size.height -
                                             _contentEdgeInsets.top -
                                             _contentEdgeInsets.bottom);
}
- (UIEdgeInsets)contentEdgeInsets { return _contentEdgeInsets; }
- (void)setContentEdgeInsets:(UIEdgeInsets)insets
{
    _contentEdgeInsets = insets;
    [self layoutTitle];
}
- (UIEdgeInsets)titleEdgeInsets { return _titleEdgeInsets; }
- (void)setTitleEdgeInsets:(UIEdgeInsets)insets { _titleEdgeInsets = insets; }
- (UIEdgeInsets)imageEdgeInsets { return _imageEdgeInsets; }
- (void)setImageEdgeInsets:(UIEdgeInsets)insets { _imageEdgeInsets = insets; }
- (void)setImage:(UIImage *)image forState:(unsigned long)state
{
    (void)state;
    _image = image;
    if (!_imageView)
    {
        _imageView = [[UIImageView alloc] initWithImage:image];
        [self addSubview:_imageView];
    }
    else
        [_imageView setImage:image];
    [self layoutTitle];
}
- (UIImage *)imageForState:(unsigned long)state
{
    (void)state;
    return _image;
}
- (UIImageView *)imageView { return _imageView; }
- (void)setFrame:(CGRect)frame
{
    [super setFrame:frame];
    [self layoutTitle];
}
- (void)setTitle:(id)title forState:(unsigned long)state
{
    (void)state;
    _title = title;
    _attributedTitle = nil;
    if (_titleLabel)
        _titleLabel->_text = title;
}
- (void)setAttributedTitle:(id)title forState:(unsigned long)state
{
    _attributedTitle = title;
    [self setTitle:[title string] forState:state];
    _attributedTitle = title;
    if (_titleLabel)
        [_titleLabel setAttributedText:title];
}
- (id)attributedTitleForState:(unsigned long)state
{
    (void)state;
    return _attributedTitle;
}
- (UILabel *)titleLabel { return _titleLabel; }
- (void)setTitleColor:(UIColor *)color forState:(unsigned long)state
{
    (void)state;
    _titleColor = color;
    _titleColorCustom = color != nil;
    if (_titleLabel)
        _titleLabel->_textColor = color ? color : [self tintColor];
}
- (void)tintColorDidChange
{
    if (_titleLabel && !_titleColorCustom)
        _titleLabel->_textColor = [self tintColor];
}
- (CGSize)intrinsicContentSize
{
    CGSize titleSize = _titleLabel ? [_titleLabel intrinsicContentSize]
                                   : CGSizeMake(80, 22);
    return CGSizeMake(titleSize.width + 32, 44);
}
@end


static void scroll_anim_add(UIScrollView *scroll);
static void scroll_anim_remove(UIScrollView *scroll);
static void scroll_stop_for_touch(UIScrollView *scroll);
static void scroll_finish_deceleration(UIScrollView *scroll);

static double clamp_scroll(double value, double low, double high);

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
        _decelerationRate = 0.998;
        _zoomScale = 1.0;
        _minimumZoomScale = 1.0;
        _maximumZoomScale = 1.0;
    }
    return self;
}
- (CGSize)contentSize { return _contentSize; }
- (void)setDelegate:(id)delegate { _delegate = delegate; }
- (id)delegate { return _delegate; }
- (void)setContentSize:(CGSize)size { _contentSize = size; }
- (CGPoint)contentOffset { return _contentOffset; }
- (void)setContentOffset:(CGPoint)offset
{
    scroll_anim_remove(self);
    _offsetAnimating = NO;
    _decelerating = NO;
    _contentOffset = offset;
}
- (void)setContentOffset:(CGPoint)offset animated:(BOOL)animated
{
    if (!animated)
    {
        [self setContentOffset:offset];
        return;
    }
    scroll_anim_remove(self);
    _decelerating = NO;
    _offsetAnimating = YES;
    _offsetAnimationStart = _contentOffset;
    _offsetAnimationTarget = offset;
    _offsetAnimationStartTime = iosim_now();
    _offsetAnimationDuration = 0.3;
    scroll_anim_add(self);
}
- (UIEdgeInsets)contentInset { return _contentInset; }
- (void)setContentInset:(UIEdgeInsets)insets { _contentInset = insets; }
- (double)zoomScale { return _zoomScale; }
- (double)minimumZoomScale { return _minimumZoomScale; }
- (void)setMinimumZoomScale:(double)scale { _minimumZoomScale = scale; }
- (double)maximumZoomScale { return _maximumZoomScale; }
- (void)setMaximumZoomScale:(double)scale { _maximumZoomScale = scale; }
- (BOOL)isZooming { return _pinchStartZoom > 0; }
- (BOOL)isZoomBouncing { return NO; }
- (UIView *)zoomDelegateView
{
    id delegate = _delegate;
    if (delegate && [delegate respondsToSelector:
                        @selector(viewForZoomingInScrollView:)])
        return ((UIView * (*)(id, SEL, id))objc_msgSend)(
            delegate, @selector(viewForZoomingInScrollView:), self);
    return nil;
}
- (void)applyZoomScale:(double)scale
{
    if (_minimumZoomScale > 0 && scale < _minimumZoomScale)
        scale = _minimumZoomScale;
    if (_maximumZoomScale > 0 && scale > _maximumZoomScale)
        scale = _maximumZoomScale;
    UIView *zoomView = [self zoomDelegateView];
    if (!zoomView)
        zoomView = _zoomView;
    if (!zoomView)
        return;
    if (!_zoomViewResolved || _zoomView != zoomView)
    {
        _zoomView = zoomView;
        _zoomBaseSize = zoomView->_frame.size;
        _zoomViewResolved = YES;
    }
    double oldScale = _zoomScale > 0 ? _zoomScale : 1.0;
    double baseCenterX = _zoomBaseSize.width / 2;
    double baseCenterY = _zoomBaseSize.height / 2;
    double pointX = (_contentOffset.x + _frame.size.width / 2 - baseCenterX) /
                        oldScale + baseCenterX;
    double pointY = (_contentOffset.y + _frame.size.height / 2 - baseCenterY) /
                        oldScale + baseCenterY;
    _zoomScale = scale;
    zoomView->_transform = CGAffineTransformMakeScale(scale, scale);
    _contentSize = CGSizeMake(_zoomBaseSize.width * scale,
                              _zoomBaseSize.height * scale);
    double maxX = _contentSize.width - _frame.size.width;
    double maxY = _contentSize.height - _frame.size.height;
    if (maxX < 0)
        maxX = 0;
    if (maxY < 0)
        maxY = 0;
    _contentOffset.x = clamp_scroll(
        baseCenterX + (pointX - baseCenterX) * scale -
            _frame.size.width / 2, 0, maxX);
    _contentOffset.y = clamp_scroll(
        baseCenterY + (pointY - baseCenterY) * scale -
            _frame.size.height / 2, 0, maxY);
    _needsLayout = YES;
    zoomView->_needsLayout = YES;
}
- (void)setZoomScale:(double)scale { [self applyZoomScale:scale]; }
- (void)setZoomScale:(double)scale animated:(BOOL)animated
{
    (void)animated;
    [self applyZoomScale:scale];
}
- (void)zoomToRect:(CGRect)rect animated:(BOOL)animated
{
    (void)animated;
    double sx = rect.size.width > 0 ? _frame.size.width / rect.size.width
                                    : _zoomScale;
    double sy = rect.size.height > 0 ? _frame.size.height / rect.size.height
                                     : _zoomScale;
    double scale = sx < sy ? sx : sy;
    [self applyZoomScale:scale];
    double maxX = _contentSize.width - _frame.size.width;
    double maxY = _contentSize.height - _frame.size.height;
    if (maxX < 0)
        maxX = 0;
    if (maxY < 0)
        maxY = 0;
    double baseCenterX = _zoomBaseSize.width / 2;
    double baseCenterY = _zoomBaseSize.height / 2;
    _contentOffset.x = clamp_scroll(
        baseCenterX +
            (rect.origin.x + rect.size.width / 2 - baseCenterX) * _zoomScale -
            _frame.size.width / 2, 0, maxX);
    _contentOffset.y = clamp_scroll(
        baseCenterY +
            (rect.origin.y + rect.size.height / 2 - baseCenterY) * _zoomScale -
            _frame.size.height / 2, 0, maxY);
    _needsLayout = YES;
}
- (void)beginPinchZoom
{
    _pinchStartZoom = _zoomScale > 0 ? _zoomScale : 1.0;
}
- (void)applyPinchScale:(double)factor
{
    if (_pinchStartZoom <= 0)
        _pinchStartZoom = _zoomScale > 0 ? _zoomScale : 1.0;
    [self applyZoomScale:_pinchStartZoom * factor];
}
- (BOOL)isScrollEnabled { return _scrollEnabled; }
- (void)setScrollEnabled:(BOOL)enabled { _scrollEnabled = enabled; }
- (BOOL)isPagingEnabled { return _pagingEnabled; }
- (void)setPagingEnabled:(BOOL)enabled { _pagingEnabled = enabled; }
- (BOOL)isDragging { return _dragging; }
- (BOOL)isDecelerating { return _decelerating; }
- (BOOL)isTracking { return _dragging; }
- (BOOL)alwaysBounceVertical { return _alwaysBounceVertical; }
- (void)setAlwaysBounceVertical:(BOOL)value { _alwaysBounceVertical = value; }
- (BOOL)alwaysBounceHorizontal { return _alwaysBounceHorizontal; }
- (void)setAlwaysBounceHorizontal:(BOOL)value { _alwaysBounceHorizontal = value; }
- (double)decelerationRate { return _decelerationRate; }
- (void)setDecelerationRate:(double)rate { _decelerationRate = rate; }
- (long)keyboardDismissMode { return _keyboardDismissMode; }
- (void)setKeyboardDismissMode:(long)mode
{
    _keyboardDismissMode = mode;
}
- (long)indicatorStyle { return _indicatorStyle; }
- (void)setIndicatorStyle:(long)style { _indicatorStyle = style; }
- (BOOL)scrollsToTop { return _scrollsToTop; }
- (void)setScrollsToTop:(BOOL)scrolls { _scrollsToTop = scrolls; }
- (BOOL)showsVerticalScrollIndicator { return _showsVerticalScrollIndicator; }
- (void)setShowsVerticalScrollIndicator:(BOOL)shows
{ _showsVerticalScrollIndicator = shows; }
- (BOOL)showsHorizontalScrollIndicator { return _showsHorizontalScrollIndicator; }
- (void)setShowsHorizontalScrollIndicator:(BOOL)shows
{ _showsHorizontalScrollIndicator = shows; }
- (UIRefreshControl *)refreshControl { return _refreshControl; }
- (void)setRefreshControl:(UIRefreshControl *)control
{
    if (_refreshControl == control)
        return;
    if (_refreshControl)
        [(UIView *)_refreshControl removeFromSuperview];
    _refreshControl = control;
    if (control)
    {
        control->_scrollView = self;
        control->_frame = CGRectMake(0, -REFRESH_CONTROL_HEIGHT,
                                     _frame.size.width,
                                     REFRESH_CONTROL_HEIGHT);
        [self addSubview:control];
    }
}
@end

@implementation UIRefreshControl
- (id)init
{
    /* UIView's alpha/layer defaults live in initWithFrame:, not in a plain
     * NSObject init, so the control must start there. */
    return [self initWithFrame:CGRectMake(0, 0, 0, REFRESH_CONTROL_HEIGHT)];
}
- (BOOL)isRefreshing { return _refreshing; }
- (void)beginRefreshing
{
    _refreshing = YES;
    _pullProgress = 1.0;
    animation_mark_active(1.0, -1);
    if (_scrollView)
    {
        UIScrollView *scroll = (UIScrollView *)_scrollView;
        scroll->_contentOffset.y = -REFRESH_CONTROL_HEIGHT;
    }
}
- (void)endRefreshing
{
    if (!_refreshing)
        return;
    _refreshing = NO;
    animation_unmark_infinite();
    if (_scrollView)
    {
        UIScrollView *scroll = (UIScrollView *)_scrollView;
        if (scroll->_contentOffset.y < 0)
            scroll->_contentOffset.y = 0;
    }
}
- (id)attributedTitle { return _attributedTitle; }
- (void)setAttributedTitle:(id)title { _attributedTitle = title; }
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

static int table_row_at_point(UITableView *table, CGPoint point,
                              long *outSection, long *outRow)
{
    double cursor = 0;
    long sections = table_sections(table);
    for (long s = 0; s < sections; s++)
    {
        cursor += table_header_height(table, s);
        long rows = table_rows(table, s);
        for (long r = 0; r < rows; r++)
        {
            NSIndexPath *path = [NSIndexPath indexPathForRow:r inSection:s];
            double height = table_row_height(table, path);
            if (point.y >= cursor && point.y < cursor + height)
            {
                if (outSection)
                    *outSection = s;
                if (outRow)
                    *outRow = r;
                return 1;
            }
            cursor += height;
        }
    }
    return 0;
}

static int table_can_edit_row(UITableView *table, long section, long row)
{
    if (table->_dataSource &&
        [table->_dataSource respondsToSelector:
            @selector(tableView:canEditRowAtIndexPath:)])
    {
        NSIndexPath *path = [NSIndexPath indexPathForRow:row inSection:section];
        SEL sel = @selector(tableView:canEditRowAtIndexPath:);
        signed char allowed = ((signed char (*)(id, void *, id, id))
            objc_msgSend)(table->_dataSource, (void *)sel, table, path);
        return allowed ? 1 : 0;
    }
    return table->_dataSource &&
           [table->_dataSource respondsToSelector:
               @selector(tableView:commitEditingStyle:forRowAtIndexPath:)];
}

@implementation UITableView
- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        _rowHeight = 44.0;
        _selectedRow = -1;
        _selectedSection = -1;
        _swipeRow = -1;
        _swipeSection = -1;
        _separatorStyle = 1;
        _allowsSelection = YES;
        _dragInteractionEnabled = YES;
        _cellLayoutMarginsFollowReadableWidth = YES;
        _insetsContentViewsToSafeArea = YES;
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
- (long)separatorStyle { return _separatorStyle; }
- (void)setSeparatorStyle:(long)style { _separatorStyle = style; }
- (UIColor *)separatorColor { return _separatorColor; }
- (void)setSeparatorColor:(UIColor *)color { _separatorColor = color; }
- (UIEdgeInsets)separatorInset { return _separatorInset; }
- (void)setSeparatorInset:(UIEdgeInsets)inset { _separatorInset = inset; }
- (UIView *)tableHeaderView { return _tableHeaderView; }
- (void)setTableHeaderView:(UIView *)view { _tableHeaderView = view; }
- (UIView *)tableFooterView { return _tableFooterView; }
- (void)setTableFooterView:(UIView *)view { _tableFooterView = view; }
- (UIView *)backgroundView { return _backgroundView; }
- (void)setBackgroundView:(UIView *)view { _backgroundView = view; }
- (id)prefetchDataSource { return _prefetchDataSource; }
- (void)setPrefetchDataSource:(id)source { _prefetchDataSource = source; }
- (id)dragDelegate { return _dragDelegate; }
- (void)setDragDelegate:(id)delegate { _dragDelegate = delegate; }
- (id)dropDelegate { return _dropDelegate; }
- (void)setDropDelegate:(id)delegate { _dropDelegate = delegate; }
- (UIRefreshControl *)refreshControl { return _refreshControl; }
- (void)setRefreshControl:(UIRefreshControl *)control
{
    [super setRefreshControl:control];
}
- (BOOL)allowsSelection { return _allowsSelection; }
- (void)setAllowsSelection:(BOOL)allows { _allowsSelection = allows; }
- (BOOL)allowsMultipleSelection { return _allowsMultipleSelection; }
- (void)setAllowsMultipleSelection:(BOOL)allows
{
    _allowsMultipleSelection = allows;
}
- (BOOL)allowsSelectionDuringEditing
{
    return _allowsSelectionDuringEditing;
}
- (void)setAllowsSelectionDuringEditing:(BOOL)allows
{
    _allowsSelectionDuringEditing = allows;
}
- (BOOL)allowsMultipleSelectionDuringEditing
{
    return _allowsMultipleSelectionDuringEditing;
}
- (void)setAllowsMultipleSelectionDuringEditing:(BOOL)allows
{
    _allowsMultipleSelectionDuringEditing = allows;
}
- (BOOL)dragInteractionEnabled { return _dragInteractionEnabled; }
- (void)setDragInteractionEnabled:(BOOL)enabled
{
    _dragInteractionEnabled = enabled;
}
- (BOOL)cellLayoutMarginsFollowReadableWidth
{
    return _cellLayoutMarginsFollowReadableWidth;
}
- (void)setCellLayoutMarginsFollowReadableWidth:(BOOL)follows
{
    _cellLayoutMarginsFollowReadableWidth = follows;
}
- (BOOL)insetsContentViewsToSafeArea
{
    return _insetsContentViewsToSafeArea;
}
- (void)setInsetsContentViewsToSafeArea:(BOOL)insets
{
    _insetsContentViewsToSafeArea = insets;
}
- (double)estimatedRowHeight { return _estimatedRowHeight; }
- (void)setEstimatedRowHeight:(double)height
{
    _estimatedRowHeight = height;
}
- (double)estimatedSectionHeaderHeight
{
    return _estimatedSectionHeaderHeight;
}
- (void)setEstimatedSectionHeaderHeight:(double)height
{
    _estimatedSectionHeaderHeight = height;
}
- (double)estimatedSectionFooterHeight
{
    return _estimatedSectionFooterHeight;
}
- (void)setEstimatedSectionFooterHeight:(double)height
{
    _estimatedSectionFooterHeight = height;
}
- (double)sectionHeaderHeight { return _sectionHeaderHeight; }
- (void)setSectionHeaderHeight:(double)height
{
    _sectionHeaderHeight = height;
}
- (double)sectionFooterHeight { return _sectionFooterHeight; }
- (void)setSectionFooterHeight:(double)height
{
    _sectionFooterHeight = height;
}
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
/* A horizontal drag on an editable row reveals its Delete control. The
 * window calls this once the touch ends, with table-local coordinates. */
- (void)handleSwipeFromPoint:(CGPoint)start toPoint:(CGPoint)end
{
    if (end.x - start.x > -50)
        return;
    long section = -1, row = -1;
    if (!table_row_at_point(self, start, &section, &row))
        return;
    if (!table_can_edit_row(self, section, row))
        return;
    _swipeSection = section;
    _swipeRow = row;
    printf("[table] delete revealed %ld\n", row);
    fflush(0);
}

- (void)deleteRowAtSwipe
{
    if (_swipeRow < 0)
        return;
    long section = _swipeSection;
    long row = _swipeRow;
    _swipeRow = -1;
    _swipeSection = -1;
    if (_dataSource &&
        [_dataSource respondsToSelector:
            @selector(tableView:commitEditingStyle:forRowAtIndexPath:)])
    {
        NSIndexPath *path = [NSIndexPath indexPathForRow:row inSection:section];
        SEL sel = @selector(tableView:commitEditingStyle:forRowAtIndexPath:);
        ((void (*)(id, void *, id, long, id))objc_msgSend)(
            _dataSource, (void *)sel, self,
            (long)UITableViewCellEditingStyleDelete, path);
    }
    [self reloadData];
}

- (void)setEditing:(BOOL)editing
{
    _editing = editing;
    _swipeRow = -1;
    _swipeSection = -1;
}
- (void)setEditing:(BOOL)editing animated:(BOOL)animated
{
    (void)animated;
    [self setEditing:editing];
}
- (BOOL)isEditing { return _editing; }
- (void)deleteRowsAtIndexPaths:(NSArray *)indexPaths
           withRowAnimation:(long)animation
{
    (void)indexPaths;
    (void)animation;
    [self reloadData];
}

- (void)handleTapAtPoint:(CGPoint)point
{
    if (point.y < 0)
        return;
    long section = -1, row = -1;
    if (!table_row_at_point(self, point, &section, &row))
    {
        _swipeRow = -1;
        _swipeSection = -1;
        return;
    }
    if (_swipeRow >= 0)
    {
        if (section == _swipeSection && row == _swipeRow &&
            point.x >= _frame.size.width - 80.0)
        {
            [self deleteRowAtSwipe];
            return;
        }
        _swipeRow = -1;
        _swipeSection = -1;
    }
    if (_editing && point.x < 44.0 &&
        table_can_edit_row(self, section, row))
    {
        _swipeSection = section;
        _swipeRow = row;
        printf("[table] delete revealed %ld\n", row);
        fflush(0);
        return;
    }
    _selectedSection = section;
    _selectedRow = row;
    if (_delegate &&
        [_delegate respondsToSelector:
            @selector(tableView:didSelectRowAtIndexPath:)])
    {
        NSIndexPath *path = [NSIndexPath indexPathForRow:row inSection:section];
        [_delegate tableView:self didSelectRowAtIndexPath:path];
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
- (CGSize)headerReferenceSize { return _headerReferenceSize; }
- (void)setHeaderReferenceSize:(CGSize)size { _headerReferenceSize = size; }
- (CGSize)footerReferenceSize { return _footerReferenceSize; }
- (void)setFooterReferenceSize:(CGSize)size { _footerReferenceSize = size; }
@end

@implementation UICollectionReusableView
- (id)reuseIdentifier { return _reuseIdentifier; }
- (void)prepareForReuse { }
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

static long collection_sections(UICollectionView *collectionView)
{
    if (collectionView->_dataSource &&
        [collectionView->_dataSource respondsToSelector:
            @selector(numberOfSectionsInCollectionView:)])
    {
        SEL sel = @selector(numberOfSectionsInCollectionView:);
        long sections = ((long (*)(id, void *, id))objc_msgSend)(
            collectionView->_dataSource, (void *)sel, collectionView);
        return sections > 0 ? sections : 1;
    }
    return 1;
}

static long collection_items_in_section(UICollectionView *collectionView,
                                        long section)
{
    if (collectionView->_dataSource &&
        [collectionView->_dataSource respondsToSelector:
            @selector(collectionView:numberOfItemsInSection:)])
    {
        SEL sel = @selector(collectionView:numberOfItemsInSection:);
        return ((long (*)(id, void *, id, long))objc_msgSend)(
            collectionView->_dataSource, (void *)sel, collectionView, section);
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
        _supplementaryClasses = [NSMutableDictionary dictionary];
        _supplementaryViews = [NSMutableArray array];
        _selectedItem = -1;
        _selectedSection = -1;
        _allowsSelection = YES;
        _dragInteractionEnabled = YES;
        [self setBackgroundColor:[UIColor clearColor]];
    }
    return self;
}
- (id)prefetchDataSource { return _prefetchDataSource; }
- (void)setPrefetchDataSource:(id)source { _prefetchDataSource = source; }
- (id)dragDelegate { return _dragDelegate; }
- (void)setDragDelegate:(id)delegate { _dragDelegate = delegate; }
- (id)dropDelegate { return _dropDelegate; }
- (void)setDropDelegate:(id)delegate { _dropDelegate = delegate; }
- (UIView *)backgroundView { return _backgroundView; }
- (void)setBackgroundView:(UIView *)view { _backgroundView = view; }
- (BOOL)allowsSelection { return _allowsSelection; }
- (void)setAllowsSelection:(BOOL)allows { _allowsSelection = allows; }
- (BOOL)allowsMultipleSelection { return _allowsMultipleSelection; }
- (void)setAllowsMultipleSelection:(BOOL)allows
{
    _allowsMultipleSelection = allows;
}
- (BOOL)dragInteractionEnabled { return _dragInteractionEnabled; }
- (void)setDragInteractionEnabled:(BOOL)enabled
{
    _dragInteractionEnabled = enabled;
}
- (NSArray *)visibleCells
{
    NSMutableArray *cells = [NSMutableArray array];
    for (unsigned long i = 0; i < [_cells count]; i++)
    {
        id cell = [_cells objectAtIndex:i];
        if (cell != [NSNull null])
            [cells addObject:cell];
    }
    return cells;
}
- (NSArray *)indexPathsForVisibleItems { return @[]; }
- (long)numberOfSections { return 1; }
- (long)numberOfItemsInSection:(long)section
{
    (void)section;
    if (_dataSource &&
        [_dataSource respondsToSelector:
            @selector(collectionView:numberOfItemsInSection:)])
    {
        SEL sel = @selector(collectionView:numberOfItemsInSection:);
        return ((long (*)(id, void *, id, long))objc_msgSend)(
            _dataSource, (void *)sel, self, 0);
    }
    return 0;
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
- (void)registerClass:(Class)viewClass
    forSupplementaryViewOfKind:(id)kind
           withReuseIdentifier:(id)identifier
{
    if (kind && viewClass)
        [_supplementaryClasses setObject:viewClass forKey:kind];
    (void)identifier;
}
- (id)dequeueReusableSupplementaryViewOfKind:(id)kind
                         withReuseIdentifier:(id)identifier
                                forIndexPath:(NSIndexPath *)indexPath
{
    (void)indexPath;
    Class cls = kind ? (Class)[_supplementaryClasses objectForKey:kind] : 0;
    if (!cls)
        cls = (Class)objc_getClass("UICollectionReusableView");
    UICollectionReusableView *view =
        [[cls alloc] initWithFrame:CGRectMake(0, 0, 0, 0)];
    view->_reuseIdentifier = identifier;
    return view;
}
- (UICollectionReusableView *)supplementaryViewOfKind:(id)kind
                                              section:(long)section
{
    NSIndexPath *path = [NSIndexPath indexPathForRow:0 inSection:section];
    UICollectionReusableView *view = nil;
    if (_dataSource &&
        [_dataSource respondsToSelector:
            @selector(collectionView:viewForSupplementaryElementOfKind:atIndexPath:)])
    {
        SEL sel = @selector(collectionView:viewForSupplementaryElementOfKind:atIndexPath:);
        view = (UICollectionReusableView *)((id (*)(id, void *, id, id, id))
            objc_msgSend)(_dataSource, (void *)sel, self, kind, path);
    }
    if (!view)
        view = (UICollectionReusableView *)[self
            dequeueReusableSupplementaryViewOfKind:kind
                               withReuseIdentifier:kind
                                      forIndexPath:path];
    return view;
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
    for (unsigned long i = 0; i < [_supplementaryViews count]; i++)
    {
        id view = [_supplementaryViews objectAtIndex:i];
        if ([view isKindOfClass:[UIView class]])
            [(UIView *)view removeFromSuperview];
    }
    [_supplementaryViews removeAllObjects];

    double itemW, itemH, interitem, line, left, right, top, bottom;
    collection_metrics(self, &itemW, &itemH, &interitem, &line,
                       &left, &right, &top, &bottom);
    int columns = collection_columns(_frame.size.width, itemW, interitem,
                                     left, right);
    long sections = collection_sections(self);
    UICollectionViewFlowLayout *flow =
        _collectionLayout &&
                [_collectionLayout isKindOfClass:[UICollectionViewFlowLayout class]]
            ? (UICollectionViewFlowLayout *)_collectionLayout
            : nil;
    double headerH = flow ? flow->_headerReferenceSize.height : 0.0;
    double footerH = flow ? flow->_footerReferenceSize.height : 0.0;
    double cursor = 0;
    for (long section = 0; section < sections; section++)
    {
        long count = collection_items_in_section(self, section);
        cursor += top;
        if (headerH > 0)
        {
            UICollectionReusableView *header = [self
                supplementaryViewOfKind:UICollectionElementKindSectionHeader
                                section:section];
            if (header)
            {
                [header setFrame:CGRectMake(0, cursor, _frame.size.width,
                                            headerH)];
                [self addSubview:header];
                [_supplementaryViews addObject:header];
            }
            cursor += headerH;
        }
        for (long i = 0; i < count; i++)
        {
            NSIndexPath *path =
                [NSIndexPath indexPathForRow:i inSection:section];
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
                double y = cursor + row * (itemH + line);
                [cell setFrame:CGRectMake(x, y, itemW, itemH)];
                [cell setSelected:(section == _selectedSection &&
                                  i == _selectedItem)
                         animated:NO];
                [self addSubview:cell];
                [_cells addObject:cell];
            }
            else
                [_cells addObject:[NSNull null]];
        }
        long rows = (count + columns - 1) / columns;
        if (rows > 0)
            cursor += rows * itemH + (rows - 1) * line;
        if (footerH > 0)
        {
            UICollectionReusableView *footer = [self
                supplementaryViewOfKind:UICollectionElementKindSectionFooter
                                section:section];
            if (footer)
            {
                [footer setFrame:CGRectMake(0, cursor, _frame.size.width,
                                            footerH)];
                [self addSubview:footer];
                [_supplementaryViews addObject:footer];
            }
            cursor += footerH;
        }
        cursor += bottom;
        if (section + 1 < sections)
            cursor += line;
    }
    _contentSize = CGSizeMake(_frame.size.width, cursor);
}
static long collection_flat_index(UICollectionView *collectionView,
                                  long section, long item)
{
    long flat = item;
    for (long s = 0; s < section; s++)
        flat += collection_items_in_section(collectionView, s);
    return flat;
}
- (void)handleTapAtPoint:(CGPoint)point
{
    double itemW, itemH, interitem, line, left, right, top, bottom;
    collection_metrics(self, &itemW, &itemH, &interitem, &line,
                       &left, &right, &top, &bottom);
    int columns = collection_columns(_frame.size.width, itemW, interitem,
                                     left, right);
    long sections = collection_sections(self);
    UICollectionViewFlowLayout *flow =
        _collectionLayout &&
                [_collectionLayout isKindOfClass:[UICollectionViewFlowLayout class]]
            ? (UICollectionViewFlowLayout *)_collectionLayout
            : nil;
    double headerH = flow ? flow->_headerReferenceSize.height : 0.0;
    double footerH = flow ? flow->_footerReferenceSize.height : 0.0;
    double cursor = 0;
    for (long section = 0; section < sections; section++)
    {
        long count = collection_items_in_section(self, section);
        cursor += top;
        cursor += headerH;
        for (long i = 0; i < count; i++)
        {
            int column = (int)(i % columns), row = (int)(i / columns);
            double x = left + column * (itemW + interitem);
            double y = cursor + row * (itemH + line);
            if (point.x < x || point.x >= x + itemW || point.y < y ||
                point.y >= y + itemH)
                continue;
            long previousSection = _selectedSection;
            long previousItem = _selectedItem;
            _selectedSection = section;
            _selectedItem = i;
            if (previousSection >= 0)
            {
                long previous = collection_flat_index(self, previousSection,
                                                      previousItem);
                if (previous >= 0 && previous < (long)[_cells count])
                {
                    id cell =
                        [_cells objectAtIndex:(unsigned long)previous];
                    if ([cell isKindOfClass:[UICollectionViewCell class]])
                        [(UICollectionViewCell *)cell setSelected:NO
                                                         animated:NO];
                }
            }
            long flat = collection_flat_index(self, section, i);
            if (flat >= 0 && flat < (long)[_cells count])
            {
                id cell = [_cells objectAtIndex:(unsigned long)flat];
                if ([cell isKindOfClass:[UICollectionViewCell class]])
                    [(UICollectionViewCell *)cell setSelected:YES
                                                     animated:NO];
            }
            if (_delegate &&
                [_delegate respondsToSelector:
                    @selector(collectionView:didSelectItemAtIndexPath:)])
            {
                NSIndexPath *path =
                    [NSIndexPath indexPathForRow:i inSection:section];
                SEL sel = @selector(collectionView:didSelectItemAtIndexPath:);
                ((void (*)(id, void *, id, id))objc_msgSend)(
                    _delegate, (void *)sel, self, path);
            }
            return;
        }
        long rows = (count + columns - 1) / columns;
        if (rows > 0)
            cursor += rows * itemH + (rows - 1) * line;
        cursor += footerH;
        cursor += bottom;
        if (section + 1 < sections)
            cursor += line;
    }
}
@end

static UIWindow *g_keyWindow;
static NSMutableArray *g_connectedScenes;
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

/* A screen-edge pan recognizes only when the touch starts inside the 20 pt
 * strip along one of its enabled screen edges. */
static int iosim_edge_pan_matches(UIScreenEdgePanGestureRecognizer *gesture,
                                  CGPoint point)
{
    if (!gesture)
        return 0;
    CGRect screen = [[UIScreen mainScreen] bounds];
    double margin = 20.0;
    long edges = gesture->_edges;
    if ((edges & UIRectEdgeLeft) && point.x <= margin)
        return 1;
    if ((edges & UIRectEdgeRight) && point.x >= screen.size.width - margin)
        return 1;
    if ((edges & UIRectEdgeTop) && point.y <= margin)
        return 1;
    if ((edges & UIRectEdgeBottom) && point.y >= screen.size.height - margin)
        return 1;
    return 0;
}

static double clamp_scroll(double value, double low, double high)
{
    if (value < low)
        return low;
    if (value > high)
        return high;
    return value;
}

/* Exact scrollable bounds after contentInset. Refresh controls add their own
 * pull area below the top bound. */
static void scroll_bounds(UIScrollView *scroll,
                          double *minX, double *maxX,
                          double *minY, double *maxY)
{
    double lowX = -scroll->_contentInset.left;
    double lowY = -scroll->_contentInset.top;
    double highX = scroll->_contentSize.width - scroll->_frame.size.width +
                   scroll->_contentInset.right;
    double highY = scroll->_contentSize.height - scroll->_frame.size.height +
                   scroll->_contentInset.bottom;
    if (highX < lowX)
        highX = lowX;
    if (highY < lowY)
        highY = lowY;
    *minX = lowX;
    *maxX = highX;
    *minY = lowY;
    *maxY = highY;
}

#define MAX_SCROLL_ANIMATIONS 32
static UIScrollView *g_scroll_animations[MAX_SCROLL_ANIMATIONS];
static int g_scroll_animation_count;

static void scroll_anim_add(UIScrollView *scroll)
{
    for (int i = 0; i < g_scroll_animation_count; i++)
        if (g_scroll_animations[i] == scroll)
            return;
    if (g_scroll_animation_count < MAX_SCROLL_ANIMATIONS)
        g_scroll_animations[g_scroll_animation_count++] = scroll;
}

static void scroll_anim_remove(UIScrollView *scroll)
{
    for (int i = 0; i < g_scroll_animation_count; i++)
        if (g_scroll_animations[i] == scroll)
        {
            for (int j = i; j + 1 < g_scroll_animation_count; j++)
                g_scroll_animations[j] = g_scroll_animations[j + 1];
            g_scroll_animation_count--;
            return;
        }
}

static void scroll_notify_did_scroll(UIScrollView *scroll)
{
    if (scroll->_delegate && [scroll->_delegate respondsToSelector:
            @selector(scrollViewDidScroll:)])
        [scroll->_delegate scrollViewDidScroll:scroll];
}

static void scroll_finish_deceleration(UIScrollView *scroll)
{
    if (!scroll->_decelerating)
    {
        scroll_anim_remove(scroll);
        return;
    }
    scroll->_decelerating = NO;
    scroll_anim_remove(scroll);
    if (scroll->_delegate && [scroll->_delegate respondsToSelector:
            @selector(scrollViewDidEndDecelerating:)])
        [scroll->_delegate scrollViewDidEndDecelerating:scroll];
}

static void scroll_stop_for_touch(UIScrollView *scroll)
{
    if (scroll->_decelerating)
        scroll_finish_deceleration(scroll);
    if (scroll->_offsetAnimating)
    {
        scroll->_offsetAnimating = NO;
        scroll_anim_remove(scroll);
    }
}

static void scroll_start_deceleration(UIScrollView *scroll, CGPoint velocity,
                                      CGPoint target, BOOL has_target)
{
    scroll->_decelerating = YES;
    scroll->_decelerationVelocity = velocity;
    scroll->_decelerationTarget = target;
    scroll->_hasDecelerationTarget = has_target;
    scroll->_decelerationStartTime = iosim_now();
    scroll->_lastScrollTick = scroll->_decelerationStartTime;
    scroll_anim_add(scroll);
}

/* Advance scroll offset animations and momentum. Called once per UI loop; the
 * return value requests a redraw. */
int iosim_scroll_tick(void)
{
    int redraw = 0;
    for (int i = 0; i < g_scroll_animation_count; )
    {
        UIScrollView *scroll = g_scroll_animations[i];
        double now = iosim_now();
        if (scroll->_offsetAnimating)
        {
            double elapsed = now - scroll->_offsetAnimationStartTime;
            double duration = scroll->_offsetAnimationDuration;
            if (duration <= 0)
                duration = 0.3;
            double t = elapsed / duration;
            if (t >= 1.0)
                t = 1.0;
            double eased = t * t * (3.0 - 2.0 * t);
            CGPoint offset = CGPointMake(
                scroll->_offsetAnimationStart.x +
                    (scroll->_offsetAnimationTarget.x -
                     scroll->_offsetAnimationStart.x) * eased,
                scroll->_offsetAnimationStart.y +
                    (scroll->_offsetAnimationTarget.y -
                     scroll->_offsetAnimationStart.y) * eased);
            if (offset.x != scroll->_contentOffset.x ||
                offset.y != scroll->_contentOffset.y)
            {
                scroll->_contentOffset = offset;
                scroll_notify_did_scroll(scroll);
                redraw = 1;
            }
            if (t >= 1.0)
            {
                scroll->_contentOffset = scroll->_offsetAnimationTarget;
                scroll->_offsetAnimating = NO;
                scroll_anim_remove(scroll);
                if (scroll->_delegate && [scroll->_delegate respondsToSelector:
                        @selector(scrollViewDidEndScrollingAnimation:)])
                    [scroll->_delegate scrollViewDidEndScrollingAnimation:scroll];
                continue;
            }
        }
        else if (scroll->_decelerating)
        {
            double dt = now - scroll->_lastScrollTick;
            scroll->_lastScrollTick = now;
            if (dt <= 0)
                dt = 1.0 / 60.0;
            if (dt > 0.1)
                dt = 0.1;
            double minX, maxX, minY, maxY;
            scroll_bounds(scroll, &minX, &maxX, &minY, &maxY);
            double vx = scroll->_decelerationVelocity.x;
            double vy = scroll->_decelerationVelocity.y;
            double nx = scroll->_contentOffset.x + vx * dt;
            double ny = scroll->_contentOffset.y + vy * dt;
            nx = clamp_scroll(nx, minX, maxX);
            ny = clamp_scroll(ny, minY, maxY);
            if (scroll->_hasDecelerationTarget)
            {
                if ((vx > 0 && nx > scroll->_decelerationTarget.x) ||
                    (vx < 0 && nx < scroll->_decelerationTarget.x))
                    nx = scroll->_decelerationTarget.x;
                if ((vy > 0 && ny > scroll->_decelerationTarget.y) ||
                    (vy < 0 && ny < scroll->_decelerationTarget.y))
                    ny = scroll->_decelerationTarget.y;
            }
            if (nx != scroll->_contentOffset.x ||
                ny != scroll->_contentOffset.y)
            {
                scroll->_contentOffset = CGPointMake(nx, ny);
                scroll_notify_did_scroll(scroll);
                redraw = 1;
            }
            int steps = (int)(dt * 1000.0);
            if (steps < 1)
                steps = 1;
            if (steps > 100)
                steps = 100;
            double decay = 1.0;
            for (int step = 0; step < steps; step++)
                decay *= scroll->_decelerationRate > 0
                             ? scroll->_decelerationRate : 0.998;
            vx *= decay;
            vy *= decay;
            scroll->_decelerationVelocity = CGPointMake(vx, vy);
            double speed = vx < 0 ? -vx : vx;
            double speedy = vy < 0 ? -vy : vy;
            if (speedy > speed)
                speed = speedy;
            BOOL at_target = scroll->_hasDecelerationTarget &&
                             nx == scroll->_decelerationTarget.x &&
                             ny == scroll->_decelerationTarget.y;
            if (speed < 25.0 || at_target ||
                now - scroll->_decelerationStartTime > 5.0)
            {
                scroll_finish_deceleration(scroll);
                continue;
            }
        }
        else
        {
            scroll_anim_remove(scroll);
            continue;
        }
        i++;
    }
    return redraw;
}

/* ---------------------------------------------------- context menus */

@implementation UIMenuElement
- (id)title { return _title; }
- (UIImage *)image { return _image; }
- (long)attributes { return _attributes; }
@end

@implementation UIAction
+ (id)actionWithTitle:(id)title image:(UIImage *)image
           identifier:(id)identifier
              handler:(void (^)(UIAction *))handler
{
    UIAction *action = [[self alloc] init];
    action->_title = title;
    action->_image = image;
    action->_identifier = identifier;
    if (handler)
        action->_handler = (void (^)(UIAction *))_Block_copy(handler);
    return action;
}
- (id)identifier { return _identifier; }
- (long)state { return _state; }
- (void)setState:(long)state { _state = state; }
- (void)setAttributes:(long)attributes { _attributes = attributes; }
@end

@implementation UIMenu
+ (id)menuWithTitle:(id)title children:(NSArray *)children
{
    return [self menuWithTitle:title image:nil identifier:nil options:0
                      children:children];
}
+ (id)menuWithTitle:(id)title image:(UIImage *)image identifier:(id)identifier
            options:(long)options children:(NSArray *)children
{
    UIMenu *menu = [[self alloc] init];
    menu->_title = title;
    menu->_image = image;
    menu->_identifier = identifier;
    menu->_options = options;
    menu->_children = children;
    return menu;
}
- (NSArray *)children { return _children; }
- (id)identifier { return _identifier; }
- (long)options { return _options; }
@end

@implementation UIContextMenuConfiguration
+ (id)configurationWithIdentifier:(id)identifier
                  previewProvider:(UIViewController *(^)(void))previewProvider
                   actionProvider:(UIMenu *(^)(NSArray *))actionProvider
{
    UIContextMenuConfiguration *configuration = [[self alloc] init];
    configuration->_identifier = identifier;
    if (previewProvider)
        configuration->_previewProvider =
            (UIViewController *(^)(void))_Block_copy(previewProvider);
    if (actionProvider)
        configuration->_actionProvider =
            (UIMenu *(^)(NSArray *))_Block_copy(actionProvider);
    return configuration;
}
- (id)identifier { return _identifier; }
- (UIViewController *(^)(void))previewProvider { return _previewProvider; }
- (UIMenu *(^)(NSArray *))actionProvider { return _actionProvider; }
@end

@implementation UIContextMenuInteraction
- (id)initWithDelegate:(id)delegate
{
    self = [super init];
    if (self)
        _delegate = delegate;
    return self;
}
- (id)delegate { return _delegate; }
- (UIView *)view { return _view; }
- (CGPoint)locationInView:(UIView *)view
{
    if (!_view || !view)
        return _location;
    return [_view convertPoint:_location toView:view];
}
- (void)willMoveToView:(UIView *)view { (void)view; }
- (void)didMoveToView:(UIView *)view { _view = view; }
@end

#define CTX_MAX_ENTRIES 24

typedef struct {
    UIAction *action; /* nil for a section header */
    id header;
} ctx_entry;

typedef struct {
    int active;
    UIView *sourceView;
    UIContextMenuInteraction *interaction;
    UIContextMenuConfiguration *configuration;
    UITableView *table;
    UICollectionView *collection;
    UIView *cell;
    CGRect sourceRect;      /* screen points */
    CGPoint touchPoint;
    UIViewController *previewController;
    int previewKind;        /* 0 snapshot, 1 view controller, 2 cell */
    unsigned *snapshot;
    int snapshotW, snapshotH;
    ctx_entry entries[CTX_MAX_ENTRIES];
    int entryCount;
    CGRect previewFrame;    /* screen points */
    CGRect menuFrame;       /* screen points */
    int rowRects[CTX_MAX_ENTRIES][4]; /* device pixels */
    int rowEntries[CTX_MAX_ENTRIES];
    int rowCount;
    int ignoreUp; /* the lift that ends the opening long press */
} ctx_state;

static ctx_state g_ctx;

static void ctx_screen_origin(UIView *view, double *ox, double *oy)
{
    double x = 0, y = 0;
    for (UIView *v = view; v; v = [v superview])
    {
        x += v->_frame.origin.x;
        y += v->_frame.origin.y;
        UIView *parent = [v superview];
        if (parent && [parent isKindOfClass:[UIScrollView class]])
        {
            UIScrollView *scroll = (UIScrollView *)parent;
            x -= scroll->_contentOffset.x;
            y -= scroll->_contentOffset.y;
        }
    }
    *ox = x;
    *oy = y;
}

static double ctx_menu_height(void)
{
    double height = 16;
    for (int i = 0; i < g_ctx.entryCount; i++)
        height += g_ctx.entries[i].action ? 46.0 : 28.0;
    return height;
}

static void ctx_compute_frames(double screenWidth, double screenHeight)
{
    double sourceW = g_ctx.sourceRect.size.width;
    double sourceH = g_ctx.sourceRect.size.height;
    double previewW = sourceW > 0 ? sourceW : 260;
    if (previewW > screenWidth - 24)
        previewW = screenWidth - 24;
    double previewH = sourceH > 0 ? sourceH * previewW / sourceW : 160;
    if (previewH < 44)
        previewH = 44;
    if (previewH > screenHeight * 0.55)
        previewH = screenHeight * 0.55;
    double menuW = previewW < 250 ? 250 : previewW;
    if (menuW > screenWidth - 24)
        menuW = screenWidth - 24;
    double menuH = ctx_menu_height();
    double total = previewH + 10 + menuH;
    double top = g_ctx.touchPoint.y - previewH / 2.0;
    if (top + total > screenHeight - 48)
        top = screenHeight - 48 - total;
    if (top < 70)
        top = 70;
    g_ctx.previewFrame = CGRectMake((screenWidth - previewW) / 2, top,
                                    previewW, previewH);
    g_ctx.menuFrame = CGRectMake((screenWidth - menuW) / 2,
                                 top + previewH + 10, menuW, menuH);
}

static void ctx_add_entry(UIAction *action, id header)
{
    if (g_ctx.entryCount >= CTX_MAX_ENTRIES)
        return;
    ctx_entry *entry = &g_ctx.entries[g_ctx.entryCount++];
    entry->action = action;
    entry->header = header;
}

static void ctx_flatten_menu(UIMenu *menu, int depth, int inlined)
{
    if (!menu || depth > 3)
        return;
    NSArray *children = menu->_children;
    if (!children)
        return;
    if (menu->_title && !inlined)
        ctx_add_entry(nil, menu->_title);
    unsigned long count = [children count];
    for (unsigned long i = 0; i < count; i++)
    {
        id child = [children objectAtIndex:i];
        if ([child isKindOfClass:[UIAction class]])
        {
            UIAction *action = (UIAction *)child;
            if (action->_attributes & UIMenuElementAttributesHidden)
                continue;
            ctx_add_entry(action, nil);
        }
        else if ([child isKindOfClass:[UIMenu class]])
        {
            UIMenu *submenu = (UIMenu *)child;
            int inlineChildren =
                (submenu->_options & UIMenuOptionsDisplayInline) != 0;
            ctx_flatten_menu(submenu, depth + 1, inlineChildren);
        }
    }
}

static long table_section_count(UITableView *table)
{
    long count = table_sections(table);
    if (count > 64)
        count = 64;
    return count;
}

static CGRect ctx_table_row_rect(UITableView *table, NSIndexPath *path)
{
    long section = [path section];
    long row = [path row];
    double cursor = 0;
    long sections = table_section_count(table);
    for (long s = 0; s < sections; s++)
    {
        cursor += table_header_height(table, s);
        long rows = table_rows(table, s);
        if (s == section)
        {
            for (long r = 0; r < row && r < rows; r++)
            {
                NSIndexPath *p = [NSIndexPath indexPathForRow:r inSection:s];
                cursor += table_row_height(table, p);
            }
            NSIndexPath *p = [NSIndexPath indexPathForRow:row inSection:s];
            double height = table_row_height(table, p);
            double ox = 0, oy = 0;
            ctx_screen_origin(table, &ox, &oy);
            return CGRectMake(ox, oy + cursor - table->_contentOffset.y,
                              table->_frame.size.width, height);
        }
        for (long r = 0; r < rows; r++)
        {
            NSIndexPath *p = [NSIndexPath indexPathForRow:r inSection:s];
            cursor += table_row_height(table, p);
        }
    }
    return CGRectMake(0, 0, 0, 0);
}

static UIView *ctx_table_cell(UITableView *table, NSIndexPath *path)
{
    if (!table->_dataSource ||
        ![table->_dataSource respondsToSelector:
            @selector(tableView:cellForRowAtIndexPath:)])
        return nil;
    SEL sel = @selector(tableView:cellForRowAtIndexPath:);
    return (UIView *)((id (*)(id, void *, id, id))objc_msgSend)(
        table->_dataSource, (void *)sel, table, path);
}

static int ctx_collection_item_at(UICollectionView *view, CGPoint point,
                                  long *outSection, long *outItem,
                                  CGRect *outFrame)
{
    double itemW, itemH, interitem, line, left, right, top, bottom;
    collection_metrics(view, &itemW, &itemH, &interitem, &line, &left,
                       &right, &top, &bottom);
    int columns = collection_columns(view->_frame.size.width, itemW,
                                     interitem, left, right);
    long sections = collection_sections(view);
    double cursor = 0;
    for (long s = 0; s < sections; s++)
    {
        long count = collection_items_in_section(view, s);
        cursor += top;
        for (long i = 0; i < count; i++)
        {
            int column = (int)(i % columns), row = (int)(i / columns);
            double x = left + column * (itemW + interitem);
            double y = cursor + row * (itemH + line);
            if (point.x >= x && point.x < x + itemW && point.y >= y &&
                point.y < y + itemH)
            {
                *outSection = s;
                *outItem = i;
                *outFrame = CGRectMake(x, y, itemW, itemH);
                return 1;
            }
        }
        long rows = (count + columns - 1) / columns;
        if (rows > 0)
            cursor += rows * itemH + (rows - 1) * line;
        cursor += bottom;
        if (s + 1 < sections)
            cursor += line;
    }
    return 0;
}

static int context_menu_begin_at(UIWindow *window, CGPoint point)
{
    if (g_ctx.active)
        return 1;
    UIView *hit = [window hitTest:point];
    if (!hit)
        return 0;
    UIContextMenuConfiguration *configuration = nil;
    UIContextMenuInteraction *interaction = nil;
    UIView *sourceView = nil;
    UITableView *table = nil;
    UICollectionView *collection = nil;
    NSIndexPath *path = nil;
    CGRect collectionItemFrame = CGRectMake(0, 0, 0, 0);

    for (UIView *v = hit; v && !configuration; v = [v superview])
    {
        for (int i = 0; i < v->_interactionCount; i++)
        {
            id candidate = v->_interactions[i];
            if (![candidate isKindOfClass:[UIContextMenuInteraction class]])
                continue;
            UIContextMenuInteraction *menuInteraction =
                (UIContextMenuInteraction *)candidate;
            if (!menuInteraction->_delegate ||
                ![menuInteraction->_delegate respondsToSelector:
                    @selector(contextMenuInteraction:configurationForMenuAtLocation:)])
                continue;
            CGPoint local = [v convertPoint:point fromView:nil];
            SEL sel = @selector(contextMenuInteraction:configurationForMenuAtLocation:);
            configuration = (UIContextMenuConfiguration *)
                ((id (*)(id, void *, id, CGPoint))objc_msgSend)(
                    menuInteraction->_delegate, (void *)sel, menuInteraction,
                    local);
            if (configuration)
            {
                interaction = menuInteraction;
                sourceView = v;
                menuInteraction->_location = local;
                break;
            }
        }
    }
    if (!configuration)
    {
        for (UIView *v = hit; v && !configuration; v = [v superview])
        {
            if (![v isKindOfClass:[UITableView class]])
                continue;
            UITableView *candidate = (UITableView *)v;
            CGPoint local = [candidate convertPoint:point fromView:nil];
            long section = 0, row = 0;
            if (!table_row_at_point(candidate, local, &section, &row))
                continue;
            id delegate = candidate->_delegate;
            if (!delegate ||
                ![delegate respondsToSelector:
                    @selector(tableView:contextMenuConfigurationForRowAtIndexPath:point:)])
                continue;
            NSIndexPath *indexPath =
                [NSIndexPath indexPathForRow:row inSection:section];
            SEL sel = @selector(tableView:contextMenuConfigurationForRowAtIndexPath:point:);
            configuration = (UIContextMenuConfiguration *)
                ((id (*)(id, void *, id, id, CGPoint))objc_msgSend)(
                    delegate, (void *)sel, candidate, indexPath, local);
            if (configuration)
            {
                table = candidate;
                path = indexPath;
            }
        }
    }
    if (!configuration)
    {
        for (UIView *v = hit; v && !configuration; v = [v superview])
        {
            if (![v isKindOfClass:[UICollectionView class]])
                continue;
            UICollectionView *candidate = (UICollectionView *)v;
            CGPoint local = [candidate convertPoint:point fromView:nil];
            long section = 0, item = 0;
            CGRect itemFrame = CGRectMake(0, 0, 0, 0);
            if (!ctx_collection_item_at(candidate, local, &section, &item,
                                        &itemFrame))
                continue;
            id delegate = candidate->_delegate;
            if (!delegate ||
                ![delegate respondsToSelector:
                    @selector(collectionView:contextMenuConfigurationForItemAtIndexPath:point:)])
                continue;
            NSIndexPath *indexPath =
                [NSIndexPath indexPathForRow:item inSection:section];
            SEL sel = @selector(collectionView:contextMenuConfigurationForItemAtIndexPath:point:);
            configuration = (UIContextMenuConfiguration *)
                ((id (*)(id, void *, id, id, CGPoint))objc_msgSend)(
                    delegate, (void *)sel, candidate, indexPath, local);
            if (configuration)
            {
                collection = candidate;
                path = indexPath;
                collectionItemFrame = itemFrame;
            }
        }
    }
    if (!configuration)
        return 0;

    memset(&g_ctx, 0, sizeof(g_ctx));
    g_ctx.active = 1;
    g_ctx.ignoreUp = 1;
    g_ctx.configuration = configuration;
    g_ctx.interaction = interaction;
    g_ctx.sourceView = sourceView;
    g_ctx.table = table;
    g_ctx.collection = collection;
    g_ctx.touchPoint = point;

    if (table && path)
    {
        g_ctx.sourceRect = ctx_table_row_rect(table, path);
        g_ctx.cell = ctx_table_cell(table, path);
        g_ctx.previewKind = 2;
    }
    else if (collection && path)
    {
        long section = [path section], item = [path row];
        double ox = 0, oy = 0;
        ctx_screen_origin(collection, &ox, &oy);
        g_ctx.sourceRect = CGRectMake(
            ox + collectionItemFrame.origin.x - collection->_contentOffset.x,
            oy + collectionItemFrame.origin.y - collection->_contentOffset.y,
            collectionItemFrame.size.width, collectionItemFrame.size.height);
        long flat = collection_flat_index(collection, section, item);
        if (flat >= 0 && flat < (long)[collection->_cells count])
        {
            id cell = [collection->_cells objectAtIndex:(unsigned long)flat];
            if ([cell isKindOfClass:[UIView class]])
                g_ctx.cell = (UIView *)cell;
        }
        g_ctx.previewKind = 2;
    }
    else if (sourceView)
    {
        double ox = 0, oy = 0;
        ctx_screen_origin(sourceView, &ox, &oy);
        g_ctx.sourceRect = CGRectMake(ox, oy,
                                      sourceView->_frame.size.width,
                                      sourceView->_frame.size.height);
        g_ctx.previewKind = 0;
    }

    if (configuration->_previewProvider)
    {
        UIViewController *preview = configuration->_previewProvider();
        if (preview)
        {
            (void)[preview view];
            g_ctx.previewController = preview;
            g_ctx.previewKind = 1;
        }
    }
    if (configuration->_actionProvider)
    {
        UIMenu *menu = configuration->_actionProvider(nil);
        if (menu)
            ctx_flatten_menu(menu, 0, 0);
    }
    CGRect screen = [[UIScreen mainScreen] bounds];
    ctx_compute_frames(screen.size.width, screen.size.height);

    if (g_ctx.previewKind == 0)
    {
        double scale = [[UIScreen mainScreen] scale];
        if (scale <= 0)
            scale = 1.0;
        int px = (int)(g_ctx.sourceRect.origin.x * scale + 0.5);
        int py = (int)(g_ctx.sourceRect.origin.y * scale + 0.5);
        int pw = (int)(g_ctx.sourceRect.size.width * scale + 0.5);
        int ph = (int)(g_ctx.sourceRect.size.height * scale + 0.5);
        int fw = (int)(screen.size.width * scale + 0.5);
        int fh = (int)(screen.size.height * scale + 0.5);
        if (px < 0) { pw += px; px = 0; }
        if (py < 0) { ph += py; py = 0; }
        if (px + pw > fw)
            pw = fw - px;
        if (py + ph > fh)
            ph = fh - py;
        if (pw > 0 && ph > 0)
        {
            g_ctx.snapshot = malloc((unsigned long)pw * ph * sizeof(unsigned));
            if (g_ctx.snapshot)
            {
                iosim_fb_capture(px, py, pw, ph, g_ctx.snapshot);
                g_ctx.snapshotW = pw;
                g_ctx.snapshotH = ph;
            }
        }
    }
    if (interaction && interaction->_delegate &&
        [interaction->_delegate respondsToSelector:
            @selector(contextMenuInteraction:willDisplayMenuForConfiguration:animator:)])
    {
        SEL sel = @selector(contextMenuInteraction:willDisplayMenuForConfiguration:animator:);
        ((void (*)(id, void *, id, id, id))objc_msgSend)(
            interaction->_delegate, (void *)sel, interaction, configuration,
            nil);
    }
    return 1;
}

static void context_menu_dismiss(void)
{
    if (!g_ctx.active)
        return;
    if (g_ctx.interaction && g_ctx.interaction->_delegate &&
        [g_ctx.interaction->_delegate respondsToSelector:
            @selector(contextMenuInteraction:willEndForConfiguration:animator:)])
    {
        SEL sel = @selector(contextMenuInteraction:willEndForConfiguration:animator:);
        ((void (*)(id, void *, id, id, id))objc_msgSend)(
            g_ctx.interaction->_delegate, (void *)sel, g_ctx.interaction,
            g_ctx.configuration, nil);
    }
    if (g_ctx.snapshot)
        free(g_ctx.snapshot);
    memset(&g_ctx, 0, sizeof(g_ctx));
}

static int context_menu_handle_tap(int px, int py)
{
    if (!g_ctx.active)
        return 0;
    for (int i = 0; i < g_ctx.rowCount; i++)
    {
        if (px < g_ctx.rowRects[i][0] || px >= g_ctx.rowRects[i][2] ||
            py < g_ctx.rowRects[i][1] || py >= g_ctx.rowRects[i][3])
            continue;
        int index = g_ctx.rowEntries[i];
        if (index < 0 || index >= g_ctx.entryCount)
            return 1;
        UIAction *action = g_ctx.entries[index].action;
        if (!action)
            return 1;
        if (action->_attributes & UIMenuElementAttributesDisabled)
            return 1;
        void (^handler)(UIAction *) = action->_handler;
        context_menu_dismiss();
        if (handler)
            handler(action);
        return 1;
    }
    context_menu_dismiss();
    return 1;
}

@implementation UIWindow
- (id)initWithWindowScene:(UIWindowScene *)scene
{
    self = [self initWithFrame:[[UIScreen mainScreen] bounds]];
    if (self)
    {
        _windowScene = scene;
        if (scene)
        {
            if (!scene->_windows)
                scene->_windows = [NSMutableArray array];
            [(NSMutableArray *)scene->_windows addObject:self];
        }
    }
    return self;
}
- (UIWindowScene *)windowScene { return (UIWindowScene *)_windowScene; }
- (double)windowLevel { return _windowLevel; }
- (void)setWindowLevel:(double)level { _windowLevel = level; }
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
- (void)beginMultiTouch:(int)ident atPoint:(CGPoint)point
{
    if (!_multiTouches)
        _multiTouches = [[NSMutableDictionary alloc] init];
    UIView *hit = [self hitTest:point];
    UITouch *touch = [[UITouch alloc] init];
    touch->_location = point;
    touch->_previousLocation = point;
    touch->_phase = UITouchPhaseBegan;
    touch->_timestamp = iosim_now();
    touch->_view = hit;
    touch->_window = self;
    touch->_tapCount = 1;
    [_multiTouches setObject:touch forKey:[NSNumber numberWithInt:ident]];
    if (hit)
    {
        UIEvent *event = [[UIEvent alloc]
            initWithTouches:[_multiTouches allValues]
                    changed:[NSSet setWithObject:touch]];
        [hit touchesBegan:[NSSet setWithObject:touch] withEvent:event];
    }
}
- (void)moveMultiTouch:(int)ident toPoint:(CGPoint)point
{
    UITouch *touch = [_multiTouches objectForKey:[NSNumber numberWithInt:ident]];
    if (!touch)
        return;
    touch->_previousLocation = touch->_location;
    touch->_location = point;
    touch->_phase = UITouchPhaseMoved;
    touch->_timestamp = iosim_now();
    if (touch->_view)
    {
        UIEvent *event = [[UIEvent alloc]
            initWithTouches:[_multiTouches allValues]
                    changed:[NSSet setWithObject:touch]];
        [touch->_view touchesMoved:[NSSet setWithObject:touch] withEvent:event];
    }
}
- (void)endMultiTouch:(int)ident atPoint:(CGPoint)point cancelled:(BOOL)cancelled
{
    UITouch *touch = [_multiTouches objectForKey:[NSNumber numberWithInt:ident]];
    if (!touch)
        return;
    touch->_previousLocation = touch->_location;
    touch->_location = point;
    touch->_phase = cancelled ? UITouchPhaseCancelled : UITouchPhaseEnded;
    touch->_timestamp = iosim_now();
    NSSet *changed = [NSSet setWithObject:touch];
    if (touch->_view)
    {
        UIEvent *event = [[UIEvent alloc]
            initWithTouches:[_multiTouches allValues]
                    changed:changed];
        if (cancelled)
            [touch->_view touchesCancelled:changed withEvent:event];
        else
            [touch->_view touchesEnded:changed withEvent:event];
    }
    [_multiTouches removeObjectForKey:[NSNumber numberWithInt:ident]];
}
- (void)dispatchTouchDownX:(int)x y:(int)y
{
    double scale = [[UIScreen mainScreen] scale];
    if (scale <= 0)
        scale = 1.0;
    CGPoint point = CGPointMake(x / scale, y / scale);
    _dragStartPoint = point;
    _dragStartTime = iosim_now();
    _dragStartContent = CGPointMake(0, 0);
    _dragScroll = nil;
    _activePan = nil;
    _edgePan = nil;
    _edgePanPending = NO;
    _panVelocity = CGPointMake(0, 0);
    _longPress = nil;
    _touchHit = [self hitTest:point];
    _contextHit = _touchHit;
    _contextStartPoint = point;
    _contextStartTime = iosim_now();
    _contextCandidate = 1;
    /* A screen-edge pan takes priority over ordinary pans and scroll views;
     * it stays possible until the finger moves past the pan threshold. */
    for (UIView *v = _touchHit; v && !_edgePan; v = [v superview])
    {
        for (int i = 0; i < v->_gestureRecognizerCount; i++)
        {
            UIGestureRecognizer *g = v->_gestureRecognizers[i];
            if (g && g->_enabled &&
                [g isKindOfClass:[UIScreenEdgePanGestureRecognizer class]] &&
                iosim_edge_pan_matches(
                    (UIScreenEdgePanGestureRecognizer *)g, point))
            {
                _edgePan = (UIScreenEdgePanGestureRecognizer *)g;
                break;
            }
        }
    }
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
                if (_edgePan)
                {
                    if (g != (UIGestureRecognizer *)_edgePan)
                        continue;
                    _activePan = _edgePan;
                    _edgePanPending = YES;
                    g->_location = point;
                    g->_translation = CGPointMake(0, 0);
                    g->_state = UIGestureRecognizerStatePossible;
                    continue;
                }
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
    {
        scroll_stop_for_touch(_dragScroll);
        _dragStartContent = _dragScroll->_contentOffset;
    }
    _dragVelocity = CGPointMake(0, 0);
    _dragMoved = NO;
    _lastMovePoint = point;
    _lastMoveTime = iosim_now();
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
    if (_contextCandidate)
    {
        double ctxDx = point.x - _contextStartPoint.x;
        double ctxDy = point.y - _contextStartPoint.y;
        if (ctxDx * ctxDx + ctxDy * ctxDy > 100.0)
            _contextCandidate = 0;
    }
    double move_time = iosim_now();
    double move_dt = move_time - _lastMoveTime;
    if (move_dt > 0.001)
    {
        CGPoint instant = CGPointMake(-(point.x - _lastMovePoint.x) / move_dt,
                                      -(point.y - _lastMovePoint.y) / move_dt);
        CGPoint finger = CGPointMake((point.x - _lastMovePoint.x) / move_dt,
                                     (point.y - _lastMovePoint.y) / move_dt);
        if (_dragMoved)
        {
            _dragVelocity = CGPointMake(
                _dragVelocity.x * 0.7 + instant.x * 0.3,
                _dragVelocity.y * 0.7 + instant.y * 0.3);
            _panVelocity = CGPointMake(
                _panVelocity.x * 0.7 + finger.x * 0.3,
                _panVelocity.y * 0.7 + finger.y * 0.3);
        }
        else
        {
            _dragVelocity = instant;
            _panVelocity = finger;
        }
    }
    _lastMovePoint = point;
    _lastMoveTime = move_time;
    _dragMoved = YES;
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
    int edgePending = 0;
    if (_activePan && _edgePanPending &&
        _activePan == (UIPanGestureRecognizer *)_edgePan)
    {
        double dx = point.x - _dragStartPoint.x;
        double dy = point.y - _dragStartPoint.y;
        if (dx * dx + dy * dy >= 100.0)
        {
            if (__builtin_fabs(dx) > __builtin_fabs(dy))
            {
                _edgePanPending = NO;
                _dragScroll = nil;
                _activePan->_location = point;
                _activePan->_translation = CGPointMake(dx, dy);
                _activePan->_panVelocity = _panVelocity;
                send_gesture_action(_activePan, UIGestureRecognizerStateBegan);
            }
            else
            {
                _edgePanPending = NO;
                _activePan->_state = UIGestureRecognizerStateFailed;
                _activePan = nil;
                _edgePan = nil;
            }
        }
        else
            edgePending = 1;
    }
    if (_activePan && !edgePending)
    {
        _activePan->_location = point;
        _activePan->_translation =
            CGPointMake(point.x - _dragStartPoint.x,
                        point.y - _dragStartPoint.y);
        _activePan->_panVelocity = _panVelocity;
        send_gesture_action(_activePan, UIGestureRecognizerStateChanged);
    }
    if (_dragScroll && !edgePending && _dragScroll->_scrollEnabled)
    {
        UIScrollView *scroll = _dragScroll;
        if (!scroll->_dragging)
        {
            scroll->_dragging = YES;
            if (scroll->_delegate && [scroll->_delegate respondsToSelector:
                    @selector(scrollViewWillBeginDragging:)])
                [scroll->_delegate scrollViewWillBeginDragging:scroll];
        }
        double minX, maxX, minY, maxY;
        scroll_bounds(scroll, &minX, &maxX, &minY, &maxY);
        double bounceX = (scroll->_bounces || scroll->_alwaysBounceHorizontal)
                             ? 30 : 0;
        double bounceY = (scroll->_bounces || scroll->_alwaysBounceVertical)
                             ? 30 : 0;
        minX -= bounceX;
        maxX += bounceX;
        minY -= bounceY;
        maxY += bounceY;
        if (scroll->_refreshControl)
            minY -= REFRESH_CONTROL_HEIGHT;
        double nx = _dragStartContent.x - (point.x - _dragStartPoint.x);
        double ny = _dragStartContent.y - (point.y - _dragStartPoint.y);
        _dragScroll->_contentOffset =
            CGPointMake(clamp_scroll(nx, minX, maxX),
                        clamp_scroll(ny, minY, maxY));
        if (_dragScroll->_refreshControl)
        {
            UIRefreshControl *rc = _dragScroll->_refreshControl;
            if (!rc->_refreshing)
            {
                double pull = -_dragScroll->_contentOffset.y;
                rc->_pullProgress =
                    pull <= 0 ? 0
                              : (pull >= REFRESH_CONTROL_HEIGHT
                                     ? 1.0
                                     : pull / REFRESH_CONTROL_HEIGHT);
            }
        }
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
    _contextCandidate = 0;
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
        if (_edgePanPending)
        {
            /* The finger lifted before the edge pan reached its threshold. */
            _activePan->_state = UIGestureRecognizerStateFailed;
            _edgePanPending = NO;
            _activePan = nil;
            _edgePan = nil;
            _dragScroll = nil;
        }
        else
        {
            if (iosim_now() - _lastMoveTime > 0.1)
                _panVelocity = CGPointMake(0, 0);
            _activePan->_location = point;
            _activePan->_translation =
                CGPointMake(point.x - _dragStartPoint.x,
                            point.y - _dragStartPoint.y);
            _activePan->_panVelocity = _panVelocity;
            send_gesture_action(_activePan, UIGestureRecognizerStateEnded);
            _activePan = nil;
        }
    }
    if (_dragScroll)
    {
        UIScrollView *scroll = _dragScroll;
        double minX, maxX, minY, maxY;
        scroll_bounds(scroll, &minX, &maxX, &minY, &maxY);
        double offX = clamp_scroll(scroll->_contentOffset.x, minX, maxX);
        double offY = clamp_scroll(scroll->_contentOffset.y, minY, maxY);
        CGPoint velocity = _dragMoved ? _dragVelocity : CGPointMake(0, 0);

        if (scroll->_pagingEnabled)
        {
            if (scroll->_contentSize.width > scroll->_frame.size.width + 0.5 &&
                scroll->_frame.size.width > 0)
            {
                double page = __builtin_floor(
                    (offX + velocity.x * 0.25 - scroll->_contentInset.left) /
                        scroll->_frame.size.width + 0.5);
                offX = scroll->_contentInset.left +
                       page * scroll->_frame.size.width;
                offX = clamp_scroll(offX, minX, maxX);
            }
            else if (scroll->_contentSize.height >
                         scroll->_frame.size.height + 0.5 &&
                     scroll->_frame.size.height > 0)
            {
                double page = __builtin_floor(
                    (offY + velocity.y * 0.25 - scroll->_contentInset.top) /
                        scroll->_frame.size.height + 0.5);
                offY = scroll->_contentInset.top +
                       page * scroll->_frame.size.height;
                offY = clamp_scroll(offY, minY, maxY);
            }
        }

        CGPoint target = CGPointMake(offX, offY);
        BOOL constrained_target = scroll->_pagingEnabled;
        if (scroll->_delegate && [scroll->_delegate respondsToSelector:
                @selector(scrollViewWillEndDragging:withVelocity:
                          targetContentOffset:)])
            ((void (*)(id, SEL, id, CGPoint, CGPoint *))objc_msgSend)(
                scroll->_delegate,
                @selector(scrollViewWillEndDragging:withVelocity:
                          targetContentOffset:),
                scroll, velocity, &target);
        if (scroll->_delegate && [scroll->_delegate respondsToSelector:
                @selector(scrollViewWillEndDragging:withVelocity:
                          targetContentOffset:)])
            constrained_target = YES;
        target.x = clamp_scroll(target.x, minX, maxX);
        target.y = clamp_scroll(target.y, minY, maxY);

        if (scroll->_refreshControl)
        {
            UIRefreshControl *rc = scroll->_refreshControl;
            if (rc->_refreshing)
                target.y = -REFRESH_CONTROL_HEIGHT;
            else if (scroll->_contentOffset.y <=
                     -(REFRESH_CONTROL_HEIGHT * 0.8))
            {
                [rc beginRefreshing];
                [rc sendActionsForControlEvents:UIControlEventValueChanged];
                target.y = -REFRESH_CONTROL_HEIGHT;
            }
            rc->_pullProgress = rc->_refreshing ? 1.0 : 0.0;
        }

        double speed = velocity.x < 0 ? -velocity.x : velocity.x;
        double speedy = velocity.y < 0 ? -velocity.y : velocity.y;
        if (speedy > speed)
            speed = speedy;
        BOOL decelerate = speed > 50.0;
        if (scroll->_refreshControl && scroll->_refreshControl->_refreshing)
            decelerate = NO;
        if (decelerate)
        {
            if (scroll->_dragging)
            {
                scroll->_dragging = NO;
                if (scroll->_delegate && [scroll->_delegate respondsToSelector:
                        @selector(scrollViewDidEndDragging:willDecelerate:)])
                    [scroll->_delegate scrollViewDidEndDragging:scroll
                                                 willDecelerate:YES];
            }
            scroll_start_deceleration(scroll, velocity, target,
                                      constrained_target);
        }
        else
        {
            BOOL moved = target.x != scroll->_contentOffset.x ||
                         target.y != scroll->_contentOffset.y;
            scroll->_contentOffset = target;
            if (moved && scroll->_delegate &&
                [scroll->_delegate respondsToSelector:
                    @selector(scrollViewDidScroll:)])
                [scroll->_delegate scrollViewDidScroll:scroll];
            if (scroll->_dragging)
            {
                scroll->_dragging = NO;
                scroll->_decelerating = NO;
                if (scroll->_delegate && [scroll->_delegate respondsToSelector:
                        @selector(scrollViewDidEndDragging:willDecelerate:)])
                    [scroll->_delegate scrollViewDidEndDragging:scroll
                                                 willDecelerate:NO];
            }
        }
        _dragScroll = nil;
    }
    double dx = point.x - _dragStartPoint.x;
    double dy = point.y - _dragStartPoint.y;
    UIView *swipeTable = _touchHit;
    while (swipeTable && ![swipeTable isKindOfClass:[UITableView class]])
        swipeTable = [swipeTable superview];
    if (swipeTable && dx < -50 && -dx > __builtin_fabs(dy) * 1.5)
    {
        double ox = 0, oy = 0;
        UIView *anc = swipeTable;
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
        [(UITableView *)swipeTable
            handleSwipeFromPoint:CGPointMake(_dragStartPoint.x - ox,
                                             _dragStartPoint.y - oy)
                         toPoint:CGPointMake(point.x - ox, point.y - oy)];
    }
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
/* Two-finger gestures bypass the single-touch path: the centroid hit-tests
 * to a view and every pinch/rotation recognizer on its ancestor chain gets
 * Began/Changed/Ended with the measured distance and angle. A zooming
 * UIScrollView on the chain follows the same scale. */
static double two_finger_distance(double x1, double y1, double x2, double y2)
{
    double dx = x2 - x1;
    double dy = y2 - y1;
    return __builtin_sqrt(dx * dx + dy * dy);
}

static double two_finger_angle(double x1, double y1, double x2, double y2)
{
    return __builtin_atan2(y2 - y1, x2 - x1);
}

- (void)beginTwoFingerX1:(double)x1 y1:(double)y1 x2:(double)x2 y2:(double)y2
           rotationOnly:(BOOL)rotationOnly
{
    _twoFingerTargetCount = 0;
    _pinchScroll = 0;
    _pinchRotationOnly = rotationOnly;
    _pinchStartDistance = two_finger_distance(x1, y1, x2, y2);
    if (_pinchStartDistance < 1.0)
        _pinchStartDistance = 1.0;
    _pinchStartAngle = two_finger_angle(x1, y1, x2, y2);
    _pinchLastDistance = _pinchStartDistance;
    _pinchLastAngle = _pinchStartAngle;
    _pinchLastTime = iosim_now();
    CGPoint centroid = CGPointMake((x1 + x2) / 2, (y1 + y2) / 2);
    UIView *hit = [self hitTest:centroid];
    for (UIView *v = hit; v; v = [v superview])
    {
        if (!_pinchScroll && [v isKindOfClass:[UIScrollView class]])
        {
            UIScrollView *scroll = (UIScrollView *)v;
            if ([scroll zoomDelegateView])
            {
                _pinchScroll = scroll;
                [scroll beginPinchZoom];
            }
        }
        for (int i = 0; i < v->_gestureRecognizerCount; i++)
        {
            UIGestureRecognizer *g = v->_gestureRecognizers[i];
            if (!g || !g->_enabled || _twoFingerTargetCount >= 8)
                continue;
            BOOL pinch = [g isKindOfClass:[UIPinchGestureRecognizer class]];
            BOOL rotation = [g isKindOfClass:[UIRotationGestureRecognizer class]];
            if (!pinch && !rotation)
                continue;
            if (rotationOnly && !rotation)
                continue;
            g->_location = centroid;
            if (pinch)
                ((UIPinchGestureRecognizer *)g)->_scale = 1.0;
            if (rotation)
                ((UIRotationGestureRecognizer *)g)->_rotation = 0.0;
            _twoFingerTargets[_twoFingerTargetCount++] = g;
            send_gesture_action(g, UIGestureRecognizerStateBegan);
        }
    }
}

- (void)moveTwoFingerX1:(double)x1 y1:(double)y1 x2:(double)x2 y2:(double)y2
{
    double distance = two_finger_distance(x1, y1, x2, y2);
    if (distance < 1.0)
        distance = 1.0;
    double angle = two_finger_angle(x1, y1, x2, y2);
    double now = iosim_now();
    double dt = now - _pinchLastTime;
    if (dt <= 0.0001)
        dt = 0.0001;
    double scale = distance / _pinchStartDistance;
    double rotation = angle - _pinchStartAngle;
    double scale_velocity =
        (distance - _pinchLastDistance) / dt / _pinchStartDistance;
    double rotation_velocity = (angle - _pinchLastAngle) / dt;
    CGPoint centroid = CGPointMake((x1 + x2) / 2, (y1 + y2) / 2);
    for (int i = 0; i < _twoFingerTargetCount; i++)
    {
        UIGestureRecognizer *g = (UIGestureRecognizer *)_twoFingerTargets[i];
        if (!g)
            continue;
        g->_location = centroid;
        if ([g isKindOfClass:[UIPinchGestureRecognizer class]])
        {
            UIPinchGestureRecognizer *pinch = (UIPinchGestureRecognizer *)g;
            pinch->_scale = scale;
            pinch->_velocity = scale_velocity;
        }
        else if ([g isKindOfClass:[UIRotationGestureRecognizer class]])
        {
            UIRotationGestureRecognizer *rotate =
                (UIRotationGestureRecognizer *)g;
            rotate->_rotation = rotation;
            rotate->_velocity = rotation_velocity;
        }
        send_gesture_action(g, UIGestureRecognizerStateChanged);
    }
    if (_pinchScroll)
    {
        [_pinchScroll applyPinchScale:scale];
        if (_pinchScroll->_delegate && [_pinchScroll->_delegate
                respondsToSelector:@selector(scrollViewDidZoom:)])
            [_pinchScroll->_delegate scrollViewDidZoom:_pinchScroll];
    }
    _pinchLastDistance = distance;
    _pinchLastAngle = angle;
    _pinchLastTime = now;
}

- (void)endTwoFingerX1:(double)x1 y1:(double)y1 x2:(double)x2 y2:(double)y2
{
    double distance = two_finger_distance(x1, y1, x2, y2);
    if (distance < 1.0)
        distance = 1.0;
    double angle = two_finger_angle(x1, y1, x2, y2);
    double scale = distance / _pinchStartDistance;
    double rotation = angle - _pinchStartAngle;
    CGPoint centroid = CGPointMake((x1 + x2) / 2, (y1 + y2) / 2);
    for (int i = 0; i < _twoFingerTargetCount; i++)
    {
        UIGestureRecognizer *g = (UIGestureRecognizer *)_twoFingerTargets[i];
        if (!g)
            continue;
        g->_location = centroid;
        if ([g isKindOfClass:[UIPinchGestureRecognizer class]])
            ((UIPinchGestureRecognizer *)g)->_scale = scale;
        else if ([g isKindOfClass:[UIRotationGestureRecognizer class]])
            ((UIRotationGestureRecognizer *)g)->_rotation = rotation;
        send_gesture_action(g, UIGestureRecognizerStateEnded);
    }
    if (_pinchScroll)
        [_pinchScroll applyPinchScale:scale];
    _twoFingerTargetCount = 0;
    _pinchScroll = 0;
}

/* Called once per run-loop frame while a touch is down: a long press whose
 * minimum duration has elapsed becomes Began without needing another event. */
- (int)tickGestureRecognizers
{
    int redraw = 0;
    if (_longPress && _longPress->_state == UIGestureRecognizerStatePossible)
    {
        UILongPressGestureRecognizer *press =
            (UILongPressGestureRecognizer *)_longPress;
        if (iosim_now() - _pressStartTime >= press->_minimumPressDuration)
        {
            press->_location = _pressStartPoint;
            send_gesture_action(press, UIGestureRecognizerStateBegan);
            _contextCandidate = 0;
            redraw = 1;
        }
    }
    /* A stationary touch held for half a second opens a context menu when
     * the hit view (or a table/collection row) provides a configuration. */
    if (_contextCandidate && !g_ctx.active && !_dragMoved && !_activePan &&
        iosim_now() - _contextStartTime >= 0.5)
    {
        _contextCandidate = 0;
        if (context_menu_begin_at(self, _contextStartPoint))
            redraw = 1;
    }
    return redraw;
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
- (void)makeKeyWindow { g_keyWindow = self; }
- (BOOL)isKeyWindow { return g_keyWindow == self; }
+ (UIWindow *)keyWindow { return g_keyWindow; }
@end

/* Applies a device-wide appearance change and tells the window tree, its
 * root controller and any presented controllers about it. */
static void ui_apply_style(int dark)
{
    int old = ui_style_current();
    if (old == dark)
    {
        g_ui_style = dark;
        return;
    }
    g_ui_style = dark;
    UIWindow *window = [UIWindow keyWindow];
    if (window)
    {
        int oldStyle = ui_view_style_with_global(window, old);
        int newStyle = ui_view_style_with_global(window, dark);
        if (oldStyle != newStyle)
            [window traitCollectionDidChange:ui_trait_for_style(oldStyle)];
        ui_trait_children(window, oldStyle, newStyle);
        UIViewController *controller = [window rootViewController];
        while (controller)
        {
            UIView *view = [controller view];
            int oldController =
                view ? ui_view_style_with_global(view, old) : old;
            int newController =
                view ? ui_view_style_with_global(view, dark) : dark;
            if (oldController != newController)
                [controller
                    traitCollectionDidChange:ui_trait_for_style(oldController)];
            controller = [controller presentedViewController];
        }
    }
    [[NSNotificationCenter defaultCenter]
        postNotificationName:UITraitCollectionDidChangeNotification
                      object:nil];
}

/* Polls the shared appearance file from an app's run loop. Returns 1 when a
 * repaint is needed. */
int iosim_ui_appearance_tick(void)
{
    static double next_check = 0;
    double now = iosim_now();
    if (now < next_check)
        return 0;
    next_check = now + 0.5;
    int dark = ui_appearance_read_file();
    if (dark == ui_style_current())
        return 0;
    ui_apply_style(dark);
    return 1;
}

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
- (long)statusBarStyle
{
    return g_status_bar_style_override >= 0 ? g_status_bar_style_override
                                            : UIStatusBarStyleDefault;
}
- (void)setStatusBarStyle:(long)style animated:(BOOL)animated
{
    (void)animated;
    g_status_bar_style_override = style;
    g_status_bar_dirty = 1;
}
- (BOOL)isStatusBarHidden
{
    return app_status_bar_hidden() ? YES : NO;
}
- (void)setStatusBarHidden:(BOOL)hidden animated:(BOOL)animated
{
    (void)animated;
    g_status_bar_hidden_override = hidden ? 1 : 0;
    g_status_bar_dirty = 1;
}
- (long)applicationIconBadgeNumber { return _iconBadgeNumber; }
- (void)setApplicationIconBadgeNumber:(long)value
{
    _iconBadgeNumber = value;
    id bundle = [[NSBundle mainBundle] bundleIdentifier];
    if (bundle)
        shell_badge_store(iosim_string_cstr(bundle), (int)value);
}
- (double)backgroundTimeRemaining
{
    if (!_backgroundTasks || [_backgroundTasks count] == 0)
        return 0;
    double remaining = _backgroundTaskDeadline - iosim_now();
    return remaining > 0 ? remaining : 0;
}
- (unsigned long)beginBackgroundTaskWithExpirationHandler:(void (^)(void))handler
{
    if (!_backgroundTasks)
        _backgroundTasks = [NSMutableArray array];
    unsigned long token = ++_nextBackgroundTask;
    id stored = handler ? (id)_Block_copy(handler) : [NSNull null];
    [_backgroundTasks addObject:[NSArray arrayWithObjects:
        [NSNumber numberWithLongLong:(long long)token], stored, nil]];
    if (_state == UIApplicationStateBackground && _backgroundTaskDeadline <= 0)
        _backgroundTaskDeadline = iosim_now() + 5.0;
    return token;
}
- (void)endBackgroundTask:(unsigned long)task
{
    if (!_backgroundTasks)
        return;
    for (unsigned long i = 0; i < [_backgroundTasks count]; i++)
    {
        NSArray *entry = [_backgroundTasks objectAtIndex:i];
        if ([(NSNumber *)[entry objectAtIndex:0] longLongValue] !=
            (long long)task)
            continue;
        id handler = [entry objectAtIndex:1];
        if (handler != [NSNull null])
            _Block_release((void *)handler);
        [(NSMutableArray *)_backgroundTasks removeObjectAtIndex:i];
        break;
    }
    if ([_backgroundTasks count] == 0)
        _backgroundTaskDeadline = 0;
}
- (BOOL)canOpenURL:(id)url { (void)url; return YES; }
- (BOOL)openURL:(id)url { (void)url; return NO; }
- (void)openURL:(id)url options:(id)options
    completionHandler:(void (^)(BOOL success))completion
{
    (void)url;
    (void)options;
    if (completion)
        completion(NO);
}
- (BOOL)isIdleTimerDisabled { return _idleTimerDisabled; }
- (void)setIdleTimerDisabled:(BOOL)disabled { _idleTimerDisabled = disabled; }
- (void)registerForRemoteNotifications { }
- (void)unregisterForRemoteNotifications { }
- (BOOL)isRegisteredForRemoteNotifications { return NO; }
- (NSArray *)windows
{
    if (g_keyWindow)
        return [NSArray arrayWithObject:g_keyWindow];
    return [NSArray array];
}
- (UIWindow *)keyWindow { return g_keyWindow; }
- (NSArray *)connectedScenes
{
    return g_connectedScenes ? g_connectedScenes : [NSArray array];
}
@end

static id g_pasteboard_text_type;
static id g_pasteboard_text_type_value(void)
{
    if (!g_pasteboard_text_type)
        g_pasteboard_text_type = @"public.utf8-plain-text";
    return g_pasteboard_text_type;
}

id UIPasteboardTypeListString;
id UIPasteboardTypeListImage;
id UIPasteboardTypeListURL;
id UIPasteboardTypeListColor;
id UIPasteboardChangedNotification;
id UIPasteboardRemovedNotification;

__attribute__((constructor)) static void iosim_pasteboard_types(void)
{
    UIPasteboardTypeListString = [NSArray arrayWithObjects:
        @"public.utf8-plain-text", @"public.utf16-plain-text",
        @"public.text", nil];
    UIPasteboardTypeListImage = [NSArray arrayWithObjects:
        @"public.image", @"public.png", @"public.jpeg", @"public.tiff", nil];
    UIPasteboardTypeListURL = [NSArray arrayWithObjects:
        @"public.url", @"public.file-url", nil];
    UIPasteboardTypeListColor =
        [NSArray arrayWithObject:@"com.apple.uikit.color"];
    UIPasteboardChangedNotification =
        @"UIPasteboardChangedNotification";
    UIPasteboardRemovedNotification =
        @"UIPasteboardRemovedNotification";
}

static id pasteboard_color_data(id color)
{
    double red = 0, green = 0, blue = 0, alpha = 0;
    if (!color ||
        ![color getRed:&red green:&green blue:&blue alpha:&alpha])
        return nil;
    double values[4] = { red, green, blue, alpha };
    return [NSData dataWithBytes:values length:sizeof(values)];
}

static id pasteboard_color_from_data(id data)
{
    if (!data || [data length] < sizeof(double) * 4)
        return nil;
    double values[4];
    memcpy(values, [data bytes], sizeof(values));
    return [UIColor colorWithRed:values[0] green:values[1]
                           blue:values[2] alpha:values[3]];
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

/* Last changeCount this process saw or wrote; the UI loop polls the shared
 * file and posts UIPasteboardChangedNotification on an external change. */
static long g_pasteboard_notified = -1;

@implementation UIPasteboard
+ (UIPasteboard *)generalPasteboard
{
    static UIPasteboard *board;
    if (!board)
    {
        board = [[self alloc] init];
        [board reload];
        g_pasteboard_notified = board->_changeCount;
    }
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
    {
        [data writeToFile:[NSString stringWithUTF8String:path]
               atomically:YES];
        g_pasteboard_notified = _changeCount;
    }
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
- (id)strings
{
    NSMutableArray *strings = [NSMutableArray array];
    id items = [self items];
    id type = g_pasteboard_text_type_value();
    for (unsigned long i = 0; i < [items count]; i++)
    {
        id item = [items objectAtIndex:i];
        if (![item isKindOfClass:[NSDictionary class]])
            continue;
        id value = [(NSDictionary *)item objectForKey:type];
        if ([value isKindOfClass:[NSString class]])
            [strings addObject:value];
    }
    return strings;
}
- (void)setStrings:(id)strings
{
    NSMutableArray *items = [NSMutableArray array];
    if (strings && [strings isKindOfClass:[NSArray class]])
    {
        for (unsigned long i = 0; i < [strings count]; i++)
        {
            id value = [strings objectAtIndex:i];
            if (![value isKindOfClass:[NSString class]])
                continue;
            NSMutableDictionary *item = [NSMutableDictionary dictionary];
            [item setObject:value forKey:g_pasteboard_text_type_value()];
            [items addObject:item];
        }
    }
    _items = items;
    _changeCount++;
    [self save];
}
- (id)image
{
    id data = [self dataForPasteboardType:@"public.png"];
    return data ? [UIImage imageWithData:data] : nil;
}
- (void)setImage:(id)image
{
    NSMutableArray *items = [NSMutableArray array];
    NSData *data = image ? UIImagePNGRepresentation(image) : nil;
    if (data)
    {
        NSMutableDictionary *item = [NSMutableDictionary dictionary];
        [item setObject:data forKey:@"public.png"];
        [items addObject:item];
    }
    _items = items;
    _changeCount++;
    [self save];
}
- (id)images
{
    NSMutableArray *images = [NSMutableArray array];
    id items = [self items];
    for (unsigned long i = 0; i < [items count]; i++)
    {
        id item = [items objectAtIndex:i];
        if (![item isKindOfClass:[NSDictionary class]])
            continue;
        id data = [(NSDictionary *)item objectForKey:@"public.png"];
        id image = data ? [UIImage imageWithData:data] : nil;
        if (image)
            [images addObject:image];
    }
    return images;
}
- (void)setImages:(id)images
{
    NSMutableArray *items = [NSMutableArray array];
    if (images && [images isKindOfClass:[NSArray class]])
    {
        for (unsigned long i = 0; i < [images count]; i++)
        {
            NSData *data = UIImagePNGRepresentation([images objectAtIndex:i]);
            if (!data)
                continue;
            NSMutableDictionary *item = [NSMutableDictionary dictionary];
            [item setObject:data forKey:@"public.png"];
            [items addObject:item];
        }
    }
    _items = items;
    _changeCount++;
    [self save];
}
- (BOOL)hasImages
{
    return [self image] != nil;
}
- (id)URL
{
    id items = [self items];
    for (unsigned long i = 0; i < [items count]; i++)
    {
        id item = [items objectAtIndex:i];
        if (![item isKindOfClass:[NSDictionary class]])
            continue;
        id value = [(NSDictionary *)item objectForKey:@"public.url"];
        if ([value isKindOfClass:[NSString class]])
            return [NSURL URLWithString:value];
    }
    return nil;
}
- (void)setURL:(id)url
{
    NSMutableArray *items = [NSMutableArray array];
    if (url)
    {
        NSMutableDictionary *item = [NSMutableDictionary dictionary];
        [item setObject:[url absoluteString] forKey:@"public.url"];
        [items addObject:item];
    }
    _items = items;
    _changeCount++;
    [self save];
}
- (id)URLs
{
    NSMutableArray *urls = [NSMutableArray array];
    id items = [self items];
    for (unsigned long i = 0; i < [items count]; i++)
    {
        id item = [items objectAtIndex:i];
        if (![item isKindOfClass:[NSDictionary class]])
            continue;
        id value = [(NSDictionary *)item objectForKey:@"public.url"];
        if ([value isKindOfClass:[NSString class]])
            [urls addObject:[NSURL URLWithString:value]];
    }
    return urls;
}
- (void)setURLs:(id)urls
{
    NSMutableArray *items = [NSMutableArray array];
    if (urls && [urls isKindOfClass:[NSArray class]])
    {
        for (unsigned long i = 0; i < [urls count]; i++)
        {
            id url = [urls objectAtIndex:i];
            if (!url)
                continue;
            NSMutableDictionary *item = [NSMutableDictionary dictionary];
            [item setObject:[url absoluteString] forKey:@"public.url"];
            [items addObject:item];
        }
    }
    _items = items;
    _changeCount++;
    [self save];
}
- (id)color
{
    id items = [self items];
    for (unsigned long i = 0; i < [items count]; i++)
    {
        id item = [items objectAtIndex:i];
        if (![item isKindOfClass:[NSDictionary class]])
            continue;
        id value = [(NSDictionary *)item objectForKey:@"com.apple.uikit.color"];
        id color = pasteboard_color_from_data(value);
        if (color)
            return color;
    }
    return nil;
}
- (void)setColor:(id)color
{
    NSMutableArray *items = [NSMutableArray array];
    id data = pasteboard_color_data(color);
    if (data)
    {
        NSMutableDictionary *item = [NSMutableDictionary dictionary];
        [item setObject:data forKey:@"com.apple.uikit.color"];
        [items addObject:item];
    }
    _items = items;
    _changeCount++;
    [self save];
}
- (id)colors
{
    NSMutableArray *colors = [NSMutableArray array];
    id items = [self items];
    for (unsigned long i = 0; i < [items count]; i++)
    {
        id item = [items objectAtIndex:i];
        if (![item isKindOfClass:[NSDictionary class]])
            continue;
        id value = [(NSDictionary *)item objectForKey:@"com.apple.uikit.color"];
        id color = pasteboard_color_from_data(value);
        if (color)
            [colors addObject:color];
    }
    return colors;
}
- (void)setColors:(id)colors
{
    NSMutableArray *items = [NSMutableArray array];
    if (colors && [colors isKindOfClass:[NSArray class]])
    {
        for (unsigned long i = 0; i < [colors count]; i++)
        {
            id data = pasteboard_color_data([colors objectAtIndex:i]);
            if (!data)
                continue;
            NSMutableDictionary *item = [NSMutableDictionary dictionary];
            [item setObject:data forKey:@"com.apple.uikit.color"];
            [items addObject:item];
        }
    }
    _items = items;
    _changeCount++;
    [self save];
}
- (id)types
{
    NSMutableArray *types = [NSMutableArray array];
    id items = [self items];
    for (unsigned long i = 0; i < [items count]; i++)
    {
        id item = [items objectAtIndex:i];
        if (![item isKindOfClass:[NSDictionary class]])
            continue;
        id keys = [(NSDictionary *)item allKeys];
        for (unsigned long j = 0; j < [keys count]; j++)
        {
            id key = [keys objectAtIndex:j];
            if (![types containsObject:key])
                [types addObject:key];
        }
    }
    return types;
}
- (BOOL)containsPasteboardTypes:(id)types
{
    if (!types)
        return NO;
    id available = [self types];
    for (unsigned long i = 0; i < [types count]; i++)
        if (![available containsObject:[types objectAtIndex:i]])
            return NO;
    return YES;
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

void iosim_pasteboard_tick(void)
{
    UIPasteboard *board = [UIPasteboard generalPasteboard];
    long change = [board changeCount];
    if (g_pasteboard_notified < 0)
    {
        g_pasteboard_notified = change;
        return;
    }
    if (change == g_pasteboard_notified)
        return;
    g_pasteboard_notified = change;
    [[NSNotificationCenter defaultCenter]
        postNotificationName:UIPasteboardChangedNotification
                      object:board];
}

@implementation UIMenuItem
- (id)initWithTitle:(id)title action:(SEL)action
{
    self = [super init];
    if (self)
    {
        _title = title;
        _action = action;
    }
    return self;
}
- (id)title { return _title; }
- (SEL)action { return _action; }
@end

@implementation UIMenuController
+ (UIMenuController *)sharedMenuController
{
    static UIMenuController *controller;
    if (!controller)
    {
        controller = [[UIMenuController alloc] init];
        UIMenuItem *copy =
            [[UIMenuItem alloc] initWithTitle:@"Copy" action:@selector(copy:)];
        UIMenuItem *paste =
            [[UIMenuItem alloc] initWithTitle:@"Paste" action:@selector(paste:)];
        id items[2] = { copy, paste };
        controller->_items = [NSArray arrayWithObjects:items count:2];
    }
    return controller;
}
- (void)setMenuItems:(NSArray *)items { _items = items; }
- (NSArray *)menuItems { return _items; }
- (void)setTargetRect:(CGRect)rect inView:(UIView *)view
{
    _targetRect = rect;
    _targetView = view;
}
- (void)setMenuVisible:(BOOL)visible { _menuVisible = visible; }
- (void)setMenuVisible:(BOOL)visible animated:(BOOL)animated
{
    (void)animated;
    _menuVisible = visible;
}
- (BOOL)isMenuVisible { return _menuVisible; }
@end

/* ---------------------------------------------------------------- scenes */

@implementation UISceneConnectionOptions
@end

@implementation UIScene
- (void)setDelegate:(id)delegate { _delegate = delegate; }
- (id)delegate { return _delegate; }
- (UISceneSession *)session
{
    if (!_session)
        _session = [[UISceneSession alloc] init];
    return _session;
}
- (long)activationState { return _activationState; }
@end

@implementation UIWindowScene
- (NSArray *)windows
{
    if (!_windows)
        _windows = [NSMutableArray array];
    return _windows;
}
- (UIWindow *)keyWindow
{
    if (g_keyWindow && g_keyWindow->_windowScene == self)
        return g_keyWindow;
    return nil;
}
- (UIScreen *)screen { return [UIScreen mainScreen]; }
- (long)interfaceOrientation { return 1; }
@end

@implementation UISceneSession
- (id)persistentIdentifier
{
    if (!_persistentIdentifier)
        _persistentIdentifier = @"iosim-scene-session";
    return _persistentIdentifier;
}
- (id)role
{
    if (!_role)
        _role = UIWindowSceneSessionRoleApplication;
    return _role;
}
- (id)configuration { return _configuration; }
- (void)setConfiguration:(id)configuration
{
    _configuration = configuration;
}
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
    double components[4];
    [color ui_components:components];
    int r = (int)(components[0] * 255.0 + 0.5);
    int g = (int)(components[1] * 255.0 + 0.5);
    int b = (int)(components[2] * 255.0 + 0.5);
    if (r < 0) r = 0; if (r > 255) r = 255;
    if (g < 0) g = 0; if (g > 255) g = 255;
    if (b < 0) b = 0; if (b > 255) b = 255;
    return ((unsigned)r << 16) | ((unsigned)g << 8) | (unsigned)b;
}

static double color_alpha(UIColor *color)
{
    if (!color)
        return 0;
    double components[4];
    [color ui_components:components];
    return components[3];
}

/* CAGradientLayer.colors holds CGColorRefs in UIKit, but this runtime also
 * accepts UIColor objects in fixtures. Both forms resolve to XRGB. */
static unsigned gradient_entry_rgb(id value)
{
    if (value && iosim_cgcolor_is_valid((CGColorRef)value))
    {
        const double *c = CGColorGetComponents((CGColorRef)value);
        if (c)
        {
            int r = (int)(c[0] * 255.0 + 0.5);
            int g = (int)(c[1] * 255.0 + 0.5);
            int b = (int)(c[2] * 255.0 + 0.5);
            if (r < 0) r = 0; if (r > 255) r = 255;
            if (g < 0) g = 0; if (g > 255) g = 255;
            if (b < 0) b = 0; if (b > 255) b = 255;
            return ((unsigned)r << 16) | ((unsigned)g << 8) | (unsigned)b;
        }
    }
    return color_rgb((UIColor *)value);
}

static unsigned char gradient_entry_alpha(id value)
{
    double a = 1.0;
    if (value && iosim_cgcolor_is_valid((CGColorRef)value))
        a = CGColorGetAlpha((CGColorRef)value);
    else if (value)
        a = ((UIColor *)value)->_a;
    if (a < 0) a = 0;
    if (a > 1) a = 1;
    return (unsigned char)(a * 255.0 + 0.5);
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
    CGRect frame = view->_frame;
    if (view->_animatingFrame)
    {
        int finished = 0;
        double e = view_animation_progress(view, &finished);
        if (finished)
        {
            view->_animatingFrame = NO;
            frame = view->_frame = view->_animFrameTo;
        }
        else
        {
            CGRect a = view->_animFrameFrom, b = view->_animFrameTo;
            frame = CGRectMake(
                a.origin.x + (b.origin.x - a.origin.x) * e,
                a.origin.y + (b.origin.y - a.origin.y) * e,
                a.size.width + (b.size.width - a.size.width) * e,
                a.size.height + (b.size.height - a.size.height) * e);
        }
    }
    /* A CAAnimation on the backing layer's position moves the view around
     * the layer's anchor point. The presentation layer reads the same
     * value, so rendering, hit-testing and reported frames agree. */
    if (view->_layer)
    {
        CGPoint base = CGPointMake(
            frame.origin.x + view->_layer->_anchorPoint.x * frame.size.width,
            frame.origin.y +
                view->_layer->_anchorPoint.y * frame.size.height);
        CGPoint position;
        if (layer_animated_position(view->_layer, base, &position))
        {
            frame.origin.x =
                position.x -
                view->_layer->_anchorPoint.x * frame.size.width;
            frame.origin.y =
                position.y -
                view->_layer->_anchorPoint.y * frame.size.height;
        }
    }
    return frame;
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

#define IOSIM_PI 3.14159265358979323846

/* Interpolates two affine transforms by decomposing them into rotation,
 * scale and translation, mirroring CoreAnimation: a rotation animation
 * sweeps the angle along the shorter arc instead of collapsing through a
 * scaled intermediate. Skew is not representable in this decomposition and
 * resolves to the nearest rotation plus scale. */
static CGAffineTransform transform_lerp(CGAffineTransform a,
                                        CGAffineTransform b, double t)
{
    if (t <= 0.0)
        return a;
    if (t >= 1.0)
        return b;
    double angleA = __builtin_atan2(a.b, a.a);
    double angleB = __builtin_atan2(b.b, b.a);
    double sxA = __builtin_sqrt(a.a * a.a + a.b * a.b);
    double sxB = __builtin_sqrt(b.a * b.a + b.b * b.b);
    double syA = __builtin_sqrt(a.c * a.c + a.d * a.d);
    double syB = __builtin_sqrt(b.c * b.c + b.d * b.d);
    if (a.a * a.d - a.b * a.c < 0.0)
        syA = -syA;
    if (b.a * b.d - b.b * b.c < 0.0)
        syB = -syB;
    double delta = angleB - angleA;
    while (delta > IOSIM_PI)
        delta -= 2.0 * IOSIM_PI;
    while (delta < -IOSIM_PI)
        delta += 2.0 * IOSIM_PI;
    double angle = angleA + delta * t;
    double sx = sxA + (sxB - sxA) * t;
    double sy = syA + (syB - syA) * t;
    double c = __builtin_cos(angle), s = __builtin_sin(angle);
    CGAffineTransform r;
    r.a = c * sx;
    r.b = s * sx;
    r.c = -s * sy;
    r.d = c * sy;
    r.tx = a.tx + (b.tx - a.tx) * t;
    r.ty = a.ty + (b.ty - a.ty) * t;
    return r;
}

static CGAffineTransform current_transform(UIView *view)
{
    if (view->_animatingTransform)
    {
        int finished = 0;
        double e = view_animation_progress(view, &finished);
        if (finished)
        {
            view->_animatingTransform = NO;
            view->_transform = view->_animTransformTo;
        }
        else
            return transform_lerp(view->_animTransformFrom,
                                  view->_animTransformTo, e);
    }
    return view->_transform;
}

/* Maps a point from a view's transformed frame-box space back into the
 * untransformed local space its bounds and subviews live in. */
static CGPoint view_untransform_point(UIView *view, CGPoint point)
{
    CGAffineTransform tf = current_transform(view);
    if (tf.a == 1.0 && tf.b == 0.0 && tf.c == 0.0 && tf.d == 1.0 &&
        tf.tx == 0.0 && tf.ty == 0.0)
        return point;
    CGRect frame = current_frame(view);
    double cx = frame.size.width / 2.0;
    double cy = frame.size.height / 2.0;
    double det = tf.a * tf.d - tf.b * tf.c;
    if (det == 0.0 || det != det)
        return point;
    double x = point.x - cx - tf.tx;
    double y = point.y - cy - tf.ty;
    return CGPointMake(cx + (tf.d * x - tf.c * y) / det,
                       cy + (-tf.b * x + tf.a * y) / det);
}

static double number_value(id value, double fallback)
{
    if (!value)
        return fallback;
    return ((double (*)(id, SEL))objc_msgSend)(value, @selector(doubleValue));
}

static double keyframe_timing(id functions, int segment, double f)
{
    if (!functions)
        return f;
    int count = (int)[functions count];
    if (count <= 0)
        return f;
    int index = segment < count ? segment : count - 1;
    id function = [functions objectAtIndex:(unsigned long)index];
    if (!function ||
        ![function respondsToSelector:@selector(evaluate:)])
        return f;
    return ((double (*)(id, SEL, double))objc_msgSend)(
        function, @selector(evaluate:), f);
}

/* Evaluate keyframe values at progress t. Linear is the default; discrete
 * holds each value until the next key time, paced distributes time by the
 * distance between values, and cubic runs a Catmull-Rom spline through the
 * values. timingFunctions apply per segment except in paced modes. */
static double layer_keyframe_value(id values, id keyTimes, id calcMode,
                                   id timingFunctions, double t)
{
    int n = values ? (int)[values count] : 0;
    if (n <= 0)
        return 0.0;
    if (n > 1024)
        n = 1024;
    double vals[1024];
    for (int i = 0; i < n; i++)
        vals[i] = number_value([values objectAtIndex:(unsigned long)i],
                               0.0);
    if (n == 1 || t <= 0.0)
        return vals[0];
    if (t >= 1.0)
        return vals[n - 1];
    const char *mode = calcMode ? iosim_string_cstr(calcMode) : "linear";
    int discrete = mode && strcmp(mode, "discrete") == 0;
    int paced = mode && (strcmp(mode, "paced") == 0 ||
                         strcmp(mode, "cubicPaced") == 0);
    int cubic = mode && (strcmp(mode, "cubic") == 0 ||
                         strcmp(mode, "cubicPaced") == 0);
    if (paced)
    {
        double total = 0.0;
        for (int i = 0; i + 1 < n; i++)
            total += __builtin_fabs(vals[i + 1] - vals[i]);
        if (total <= 0.0)
            return vals[0];
        double target = t * total;
        double acc = 0.0;
        for (int i = 0; i + 1 < n; i++)
        {
            double len = __builtin_fabs(vals[i + 1] - vals[i]);
            if (target <= acc + len || i == n - 2)
            {
                double f = len > 0 ? (target - acc) / len : 1.0;
                if (f < 0)
                    f = 0;
                if (f > 1)
                    f = 1;
                return vals[i] + (vals[i + 1] - vals[i]) * f;
            }
            acc += len;
        }
        return vals[n - 1];
    }
    double times[1024];
    for (int i = 0; i < n; i++)
        times[i] = keyTimes
            ? number_value([keyTimes objectAtIndex:(unsigned long)i],
                           (double)i / (n - 1))
            : (double)i / (n - 1);
    for (int i = 0; i + 1 < n; i++)
    {
        double t0 = times[i], t1 = times[i + 1];
        int inSegment = discrete ? (t < t1) : (t <= t1);
        if (inSegment || i == n - 2)
        {
            if (t1 <= t0)
                return vals[i + 1];
            double f = (t - t0) / (t1 - t0);
            if (f < 0)
                f = 0;
            if (f > 1)
                f = 1;
            if (discrete)
                return vals[i];
            if (cubic)
            {
                double m0, m1;
                if (i == 0)
                    m0 = vals[1] - vals[0];
                else
                    m0 = (vals[i + 1] - vals[i - 1]) / 2.0;
                if (i + 2 >= n)
                    m1 = vals[n - 1] - vals[n - 2];
                else
                    m1 = (vals[i + 2] - vals[i]) / 2.0;
                f = keyframe_timing(timingFunctions, i, f);
                double f2 = f * f;
                double f3 = f2 * f;
                double h00 = 2.0 * f3 - 3.0 * f2 + 1.0;
                double h10 = f3 - 2.0 * f2 + f;
                double h01 = -2.0 * f3 + 3.0 * f2;
                double h11 = f3 - f2;
                return h00 * vals[i] + h10 * m0 + h01 * vals[i + 1] +
                       h11 * m1;
            }
            f = keyframe_timing(timingFunctions, i, f);
            return vals[i] + (vals[i + 1] - vals[i]) * f;
        }
    }
    return vals[n - 1];
}

static int layer_point_value(id value, CGPoint *point)
{
    if (!value || ![value respondsToSelector:@selector(CGPointValue)])
        return 0;
    *point = ((CGPoint (*)(id, SEL))objc_msgSend)(value,
                                                 @selector(CGPointValue));
    return 1;
}

/* Normalized progress of a layer animation, with fill-mode handling and
 * the same repeat/autoreverse rules as scalar key paths. Returns 0 when a
 * fill-backwards animation has not started yet. */
static int layer_progress(struct layer_anim *anim, double *outT)
{
    double elapsed = (iosim_now() - anim->start - anim->delay) *
                         anim->speed +
                     anim->timeOffset;
    if (elapsed < 0)
    {
        const char *fill =
            anim->fillMode ? iosim_string_cstr(anim->fillMode) : 0;
        int backwards =
            fill && (strstr(fill, "backward") || strstr(fill, "both"));
        if (!backwards)
            return 0;
        elapsed = 0;
    }
    double duration = anim->duration > 0 ? anim->duration : 0.25;
    double t = elapsed / duration;
    double repeat = anim->repeatCount;
    if (repeat < 0)
        t = t - (long)t;
    else if (repeat > 1 && t >= repeat)
        t = 1.0;
    else if (t >= 1.0)
        t = 1.0;
    if (anim->autoreverses)
    {
        if (t >= 1.0)
            t = 0.0;
        else if (t < 0.5)
            t *= 2.0;
        else
            t = (1.0 - t) * 2.0;
    }
    *outT = t;
    return 1;
}

static CGPoint layer_keyframe_point(id values, id keyTimes,
                                    id timingFunctions, CGPoint base,
                                    double t)
{
    int n = values ? (int)[values count] : 0;
    if (n <= 0)
        return base;
    if (n > 256)
        n = 256;
    CGPoint points[256];
    for (int i = 0; i < n; i++)
    {
        if (!layer_point_value([values objectAtIndex:(unsigned long)i],
                               &points[i]))
            points[i] = base;
    }
    if (n == 1 || t <= 0.0)
        return points[0];
    if (t >= 1.0)
        return points[n - 1];
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
            if (t1 <= t0)
                return points[i + 1];
            double f = (t - t0) / (t1 - t0);
            if (f < 0)
                f = 0;
            if (f > 1)
                f = 1;
            f = keyframe_timing(timingFunctions, i, f);
            return CGPointMake(
                points[i].x + (points[i + 1].x - points[i].x) * f,
                points[i].y + (points[i + 1].y - points[i].y) * f);
        }
    }
    return points[n - 1];
}

struct layer_path_points {
    CGPoint points[512];
    int count;
    CGPoint start;
    int have_start;
};

static void layer_path_add(struct layer_path_points *builder, double x,
                           double y)
{
    if (builder->count >= 512)
        return;
    CGPoint point = CGPointMake(x, y);
    if (builder->count > 0)
    {
        CGPoint last = builder->points[builder->count - 1];
        if (last.x == point.x && last.y == point.y)
            return;
    }
    builder->points[builder->count++] = point;
}

static void layer_path_element(void *info, const CGPathElement *element)
{
    struct layer_path_points *builder = info;
    switch (element->type)
    {
    case kCGPathElementMoveToPoint:
        builder->start = element->points[0];
        builder->have_start = 1;
        layer_path_add(builder, element->points[0].x, element->points[0].y);
        break;
    case kCGPathElementAddLineToPoint:
        layer_path_add(builder, element->points[0].x, element->points[0].y);
        break;
    case kCGPathElementAddQuadCurveToPoint:
    case kCGPathElementAddCurveToPoint:
    {
        CGPoint from = builder->count
                           ? builder->points[builder->count - 1]
                           : element->points[0];
        int quad = element->type == kCGPathElementAddQuadCurveToPoint;
        int steps = quad ? 12 : 24;
        for (int i = 1; i <= steps; i++)
        {
            double u = (double)i / steps;
            double m = 1.0 - u;
            double x, y;
            if (quad)
            {
                x = m * m * from.x + 2 * m * u * element->points[0].x +
                    u * u * element->points[1].x;
                y = m * m * from.y + 2 * m * u * element->points[0].y +
                    u * u * element->points[1].y;
            }
            else
            {
                x = m * m * m * from.x +
                    3 * m * m * u * element->points[0].x +
                    3 * m * u * u * element->points[1].x +
                    u * u * u * element->points[2].x;
                y = m * m * m * from.y +
                    3 * m * m * u * element->points[0].y +
                    3 * m * u * u * element->points[1].y +
                    u * u * u * element->points[2].y;
            }
            layer_path_add(builder, x, y);
        }
        break;
    }
    case kCGPathElementCloseSubpath:
        if (builder->have_start)
            layer_path_add(builder, builder->start.x, builder->start.y);
        break;
    }
}

/* Point at fraction t of a path's total arc length. CGPath stores curves as
 * flattened line segments, so straight-line accumulation matches the
 * geometry that CGContext draws. */
static int layer_path_point(CGPathRef path, double t, CGPoint *out)
{
    if (!path)
        return 0;
    struct layer_path_points builder;
    memset(&builder, 0, sizeof(builder));
    CGPathApply(path, &builder, layer_path_element);
    if (builder.count <= 0)
        return 0;
    if (builder.count == 1 || t <= 0.0)
    {
        *out = builder.points[0];
        return 1;
    }
    if (t >= 1.0)
    {
        *out = builder.points[builder.count - 1];
        return 1;
    }
    double total = 0.0;
    for (int i = 1; i < builder.count; i++)
    {
        double dx = builder.points[i].x - builder.points[i - 1].x;
        double dy = builder.points[i].y - builder.points[i - 1].y;
        total += __builtin_sqrt(dx * dx + dy * dy);
    }
    if (total <= 0.0)
    {
        *out = builder.points[0];
        return 1;
    }
    double target = t * total;
    double acc = 0.0;
    for (int i = 1; i < builder.count; i++)
    {
        double dx = builder.points[i].x - builder.points[i - 1].x;
        double dy = builder.points[i].y - builder.points[i - 1].y;
        double length = __builtin_sqrt(dx * dx + dy * dy);
        if (target <= acc + length || i == builder.count - 1)
        {
            double f = length > 0 ? (target - acc) / length : 1.0;
            if (f < 0)
                f = 0;
            if (f > 1)
                f = 1;
            *out = CGPointMake(builder.points[i - 1].x + dx * f,
                               builder.points[i - 1].y + dy * f);
            return 1;
        }
        acc += length;
    }
    *out = builder.points[builder.count - 1];
    return 1;
}

static int layer_animated_position(CALayer *layer, CGPoint base,
                                   CGPoint *out)
{
    struct layer_anim *anim = 0;
    for (int i = 0; i < LAYER_ANIM_SLOTS; i++)
    {
        struct layer_anim *entry = &layer->_anims[i];
        if (!entry->used || !entry->keyPath)
            continue;
        const char *path = iosim_string_cstr(entry->keyPath);
        if (!path || strcmp(path, "position") != 0)
            continue;
        if (!anim || entry->seq > anim->seq)
            anim = entry;
    }
    if (!anim)
        return 0;
    double t = 0.0;
    if (!layer_progress(anim, &t))
        return 0;
    if (anim->path)
        return layer_path_point(anim->path, t, out);
    if (anim->values)
    {
        *out = layer_keyframe_point(anim->values, anim->keyTimes,
                                    anim->timingFunctions, base, t);
        return 1;
    }
    CGPoint from = base, to = base;
    int haveFrom = layer_point_value(anim->fromValue, &from);
    int haveTo = layer_point_value(anim->toValue, &to);
    if (!haveFrom && !haveTo)
        return 0;
    if (!haveFrom)
        from = to;
    if (!haveTo)
        to = from;
    double e = t;
    if (anim->timingFunction)
        e = ((double (*)(id, SEL, double))objc_msgSend)(
            anim->timingFunction, @selector(evaluate:), t);
    *out = CGPointMake(from.x + (to.x - from.x) * e,
                       from.y + (to.y - from.y) * e);
    return 1;
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
    double elapsed =
        (iosim_now() - anim->start - anim->delay) * anim->speed +
        anim->timeOffset;
    if (elapsed < 0)
    {
        const char *fill = anim->fillMode ? iosim_string_cstr(anim->fillMode)
                                          : 0;
        int backwards =
            fill && (strstr(fill, "backward") || strstr(fill, "both"));
        if (!backwards)
            return base;
        elapsed = 0;
    }
    double t = elapsed / anim->duration;
    double repeat = anim->repeatCount;
    int finished = 0;
    if (repeat < 0)
        t = t - (long)t;
    else if (repeat > 1 && t >= repeat)
    {
        t = 1.0;
        finished = 1;
    }
    else if (repeat > 1)
        t = t - (long)t;
    else if (t >= 1.0)
    {
        t = 1.0;
        finished = 1;
    }
    if (anim->autoreverses)
    {
        if (finished)
            t = 0.0;
        else if (t < 0.5)
            t *= 2.0;
        else
            t = (1.0 - t) * 2.0;
    }
    if (finished && !anim->autoreverses)
    {
        if (anim->values)
            return layer_keyframe_value(anim->values, anim->keyTimes,
                                        anim->calcMode,
                                        anim->timingFunctions, 1.0);
        return number_value(anim->toValue, base);
    }
    if (anim->values)
        return layer_keyframe_value(anim->values, anim->keyTimes,
                                    anim->calcMode, anim->timingFunctions,
                                    t);
    double from = number_value(anim->fromValue, base);
    double to = number_value(anim->toValue, base);
    if (anim->spring)
    {
        double m = anim->mass > 0 ? anim->mass : 1.0;
        double k = anim->stiffness > 0 ? anim->stiffness : 100.0;
        double c = anim->damping > 0 ? anim->damping : 10.0;
        double w0 = __builtin_sqrt(k / m);
        double zeta = c / (2.0 * __builtin_sqrt(k * m));
        double dt = t * anim->duration;
        double x;
        if (zeta < 1.0)
        {
            double wd = w0 * __builtin_sqrt(1.0 - zeta * zeta);
            double decay = __builtin_exp(-zeta * w0 * dt);
            x = 1.0 - decay *
                (__builtin_cos(wd * dt) +
                 ((zeta * w0 - anim->initialVelocity) / wd) *
                     __builtin_sin(wd * dt));
        }
        else
        {
            x = 1.0 - __builtin_exp(-w0 * dt) * (1.0 + w0 * dt);
        }
        return from + (to - from) * x;
    }
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

/* Stroke the portion of a polyline between strokeStart and strokeEnd
 * (fractions of its length) and optionally round-cap the trimmed ends. */
static void stroke_polyline_trimmed(const double *px, const double *py,
                                    int count, int closed, double start,
                                    double end, int thickness,
                                    unsigned color, int lineCap,
                                    int lineJoin, const double *dash,
                                    int dashCount, double dashPhase)
{
    if (count < 2)
        return;
    iosim_fb_stroke_polyline(px, py, count, closed, start, end,
                             (double)thickness, color, lineCap, lineJoin,
                             10.0, dash, dashCount, dashPhase);
}

static void render_shape_path(UIBezierPath *path, int x, int y, int w, int h,
                              double scale, UIColor *fill, UIColor *stroke,
                              double lineWidth, double strokeStart,
                              double strokeEnd, int lineCap, int lineJoin,
                              const double *dash, int dashCount,
                              double dashPhase)
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
            if (path->_shape == 2)
            {
                double rad = path->_cornerRadius * scale;
                double limit = (rw < rh ? rw : rh) / 2.0;
                if (rad > limit)
                    rad = limit;
                if (rad < 0)
                    rad = 0;
                double px[4 * 9], py[4 * 9];
                int n = 0;
                double centers[4][2] = {
                    {rx + rad, ry + rad},
                    {rx + rw - rad, ry + rad},
                    {rx + rw - rad, ry + rh - rad},
                    {rx + rad, ry + rh - rad}
                };
                double starts[4] = {3.14159265358979323846,
                                    1.5 * 3.14159265358979323846, 0.0,
                                    0.5 * 3.14159265358979323846};
                for (int c = 0; c < 4; c++)
                    for (int i = 0; i <= 8; i++)
                    {
                        double a = starts[c] + (i / 8.0) *
                                   (0.5 * 3.14159265358979323846);
                        px[n] = centers[c][0] + rad * __builtin_cos(a);
                        py[n] = centers[c][1] + rad * __builtin_sin(a);
                        n++;
                    }
                stroke_polyline_trimmed(px, py, n, 1, strokeStart,
                                        strokeEnd, thickness, stroke_color,
                                        lineCap, lineJoin, dash, dashCount,
                                        dashPhase);
            }
            else
            {
                double px[5] = {rx, rx + rw, rx + rw, rx, rx};
                double py[5] = {ry, ry, ry + rh, ry + rh, ry};
                stroke_polyline_trimmed(px, py, 5, 1, strokeStart,
                                        strokeEnd, thickness, stroke_color,
                                        lineCap, lineJoin, dash, dashCount,
                                        dashPhase);
            }
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
            double px[64], py[64];
            for (int i = 0; i < 64; i++)
            {
                double t = 2 * 3.14159265358979323846 * i / 64.0;
                px[i] = cx + ax * __builtin_cos(t);
                py[i] = cy + ay * __builtin_sin(t);
            }
            stroke_polyline_trimmed(px, py, 64, 1, strokeStart, strokeEnd,
                                    thickness, stroke_color, lineCap,
                                    lineJoin, dash, dashCount, dashPhase);
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
        double px[512], py[512];
        for (int i = 0; i < count; i++)
        {
            px[i] = x + path->_xs[i] * scale;
            py[i] = y + path->_ys[i] * scale;
        }
        stroke_polyline_trimmed(px, py, count, path->_closed, strokeStart,
                                strokeEnd, thickness, stroke_color,
                                lineCap, lineJoin, dash, dashCount,
                                dashPhase);
    }
}

static void blit_layer_contents(CALayer *layer, int x, int y, int w, int h,
                                const unsigned char *rgba, int image_w,
                                int image_h, double alpha)
{
    CGRect rect = layer->_contentsRect;
    if (rect.size.width <= 0 || rect.size.height <= 0)
        rect = CGRectMake(0, 0, 1, 1);
    if (rect.origin.x < 0) rect.origin.x = 0;
    if (rect.origin.y < 0) rect.origin.y = 0;
    if (rect.origin.x + rect.size.width > 1)
        rect.size.width = 1 - rect.origin.x;
    if (rect.origin.y + rect.size.height > 1)
        rect.size.height = 1 - rect.origin.y;
    int sx = (int)(rect.origin.x * image_w);
    int sy = (int)(rect.origin.y * image_h);
    int sw = (int)(rect.size.width * image_w + 0.5);
    int sh = (int)(rect.size.height * image_h + 0.5);
    if (sw < 1) sw = 1;
    if (sh < 1) sh = 1;
    if (sx + sw > image_w) sw = image_w - sx;
    if (sy + sh > image_h) sh = image_h - sy;
    const char *gravity = layer->_contentsGravity
        ? iosim_string_cstr(layer->_contentsGravity) : 0;
    int dx = x, dy = y, dw = w, dh = h;
    if (gravity && strcmp(gravity, "resizeAspect") == 0)
    {
        double fit = (double)w / sw;
        if ((double)h / sh < fit)
            fit = (double)h / sh;
        dw = (int)(sw * fit + 0.5);
        dh = (int)(sh * fit + 0.5);
        dx = x + (w - dw) / 2;
        dy = y + (h - dh) / 2;
    }
    else if (gravity && strcmp(gravity, "resizeAspectFill") == 0)
    {
        double target = (double)w / h;
        double source = (double)sw / sh;
        if (source > target)
        {
            int new_sw = (int)(sh * target + 0.5);
            sx += (sw - new_sw) / 2;
            sw = new_sw;
        }
        else if (source < target)
        {
            int new_sh = (int)(sw / target + 0.5);
            sy += (sh - new_sh) / 2;
            sh = new_sh;
        }
    }
    else if (gravity && strcmp(gravity, "center") == 0)
    {
        dw = sw;
        dh = sh;
        dx = x + (w - dw) / 2;
        dy = y + (h - dh) / 2;
    }
    if (sx == 0 && sy == 0 && sw == image_w && sh == image_h)
    {
        iosim_fb_blit_rgba_scaled(dx, dy, dw, dh, rgba, sw, sh, sw * 4);
    }
    else
    {
        unsigned char *crop = malloc((unsigned long)sw * sh * 4);
        if (crop)
        {
            for (int row = 0; row < sh; row++)
                memcpy(crop + (unsigned long)row * sw * 4,
                       rgba + ((unsigned long)(sy + row) * image_w + sx) * 4,
                       (unsigned long)sw * 4);
            iosim_fb_blit_rgba_scaled(dx, dy, dw, dh, crop, sw, sh, sw * 4);
            free(crop);
        }
    }
    iosim_fb_set_opacity(alpha);
}

static void render_layer_contents(CALayer *layer, int x, int y, int w,
                                  int h, double alpha)
{
    if (!layer || !layer->_contents || w <= 0 || h <= 0)
        return;
    if (iosim_cgimage_is_valid(layer->_contents))
    {
        int image_w = 0, image_h = 0;
        const unsigned char *rgba =
            iosim_cgimage_data((CGImageRef)layer->_contents, &image_w,
                               &image_h);
        if (rgba && image_w > 0 && image_h > 0)
            blit_layer_contents(layer, x, y, w, h, rgba, image_w, image_h,
                                alpha);
    }
    else if ([layer->_contents isKindOfClass:[UIImage class]])
    {
        UIImage *image = (UIImage *)layer->_contents;
        if (image->_rgba && image->_width > 0 && image->_height > 0)
            blit_layer_contents(layer, x, y, w, h, image->_rgba,
                                image->_width, image->_height, alpha);
    }
}

static void gradient_sample(const unsigned *colors,
                            const unsigned char *alphas,
                            const double *locations, int count, double t,
                            unsigned *rgb, unsigned char *a)
{
    if (t < 0) t = 0;
    if (t > 1) t = 1;
    int index = 0;
    while (index + 1 < count && t > locations[index + 1])
        index++;
    int next = index + 1 < count ? index + 1 : index;
    double span = locations[next] - locations[index];
    double f = span > 0 ? (t - locations[index]) / span : 0;
    if (f < 0) f = 0;
    if (f > 1) f = 1;
    unsigned ca = colors[index], cb = colors[next];
    int r = (int)(((ca >> 16) & 255) +
                  (((int)((cb >> 16) & 255) - (int)((ca >> 16) & 255)) * f));
    int gg = (int)(((ca >> 8) & 255) +
                   (((int)((cb >> 8) & 255) - (int)((ca >> 8) & 255)) * f));
    int b = (int)((ca & 255) + ((int)(cb & 255) - (int)(ca & 255)) * f);
    *rgb = ((unsigned)r << 16) | ((unsigned)gg << 8) | (unsigned)b;
    *a = (unsigned char)(alphas[index] +
        (alphas[next] - alphas[index]) * f);
}

static void render_gradient_layer(CAGradientLayer *g, int x, int y, int w,
                                  int h, double scale, double alpha,
                                  double cornerRadius)
{
    long total = g->_colors ? (long)g->_colors->_count : 0;
    if (total <= 0 || w <= 0 || h <= 0)
        return;
    enum { MAX_STOPS = 32 };
    unsigned colors[MAX_STOPS];
    unsigned char alphas[MAX_STOPS];
    double locations[MAX_STOPS];
    int count = total < MAX_STOPS ? (int)total : MAX_STOPS;
    long loc_count = g->_locations ? (long)g->_locations->_count : 0;
    int explicit_locations = loc_count == total;
    for (int i = 0; i < count; i++)
    {
        id entry = [g->_colors objectAtIndex:i];
        colors[i] = gradient_entry_rgb(entry);
        alphas[i] = gradient_entry_alpha(entry);
        if (explicit_locations)
            locations[i] = number_value([g->_locations objectAtIndex:i], 0.0);
        else
            locations[i] = total > 1 ? (double)i / (double)(total - 1) : 0.0;
    }
    const char *type = g->_type ? iosim_string_cstr(g->_type) : 0;
    if (type && strcmp(type, "radial") == 0)
    {
        double cx = g->_startPoint.x * w;
        double cy = g->_startPoint.y * h;
        double rx = (g->_endPoint.x - g->_startPoint.x) * w;
        double ry = (g->_endPoint.y - g->_startPoint.y) * h;
        double radius = __builtin_sqrt(rx * rx + ry * ry);
        if (radius <= 0)
            radius = (w > h ? w : h) / 2.0;
        unsigned char *pixels = malloc((unsigned long)w * h * 4);
        if (!pixels)
            return;
        for (int py = 0; py < h; py++)
        {
            double dy = py - cy;
            for (int px = 0; px < w; px++)
            {
                double dx = px - cx;
                double t = __builtin_sqrt(dx * dx + dy * dy) / radius;
                unsigned rgb = 0;
                unsigned char a = 0;
                gradient_sample(colors, alphas, locations, count, t, &rgb, &a);
                unsigned char *out = pixels + ((unsigned long)py * w + px) * 4;
                out[0] = (unsigned char)((rgb >> 16) & 255);
                out[1] = (unsigned char)((rgb >> 8) & 255);
                out[2] = (unsigned char)(rgb & 255);
                out[3] = a;
            }
        }
        if (cornerRadius > 0)
        {
            int radius_px = (int)(cornerRadius * scale + 0.5);
            void *state = iosim_fb_begin_offscreen((unsigned)w, (unsigned)h);
            if (state)
            {
                iosim_fb_blit_rgba_scaled(0, 0, w, h, pixels, w, h, w * 4);
                iosim_fb_mask_round_rect(0, 0, w, h, radius_px);
                int bw = 0, bh = 0;
                unsigned *buf = iosim_fb_end_offscreen(state, &bw, &bh);
                if (buf)
                {
                    iosim_fb_blit_affine(buf, bw, bh, 1.0, 0.0, 0.0, 1.0,
                                         x, y, alpha);
                    iosim_fb_free_offscreen(buf);
                }
            }
        }
        else
        {
            iosim_fb_set_opacity(alpha);
            iosim_fb_blit_rgba_scaled(x, y, w, h, pixels, w, h, w * 4);
        }
        free(pixels);
        return;
    }
    if (cornerRadius > 0)
    {
        int radius = (int)(cornerRadius * scale + 0.5);
        void *state = iosim_fb_begin_offscreen((unsigned)w, (unsigned)h);
        if (state)
        {
            iosim_fb_fill_gradient_stops_alpha(
                0, 0, w, h, colors, alphas, locations, count,
                g->_startPoint.x * w, g->_startPoint.y * h,
                g->_endPoint.x * w, g->_endPoint.y * h);
            iosim_fb_mask_round_rect(0, 0, w, h, radius);
            int bw = 0, bh = 0;
            unsigned *buf = iosim_fb_end_offscreen(state, &bw, &bh);
            if (buf)
            {
                iosim_fb_blit_affine(buf, bw, bh, 1.0, 0.0, 0.0, 1.0, x, y,
                                     alpha);
                iosim_fb_free_offscreen(buf);
            }
        }
    }
    else
    {
        iosim_fb_fill_gradient_stops_alpha(
            x, y, w, h, colors, alphas, locations, count,
            x + g->_startPoint.x * w, y + g->_startPoint.y * h,
            x + g->_endPoint.x * w, y + g->_endPoint.y * h);
    }
}

static void render_layer(CALayer *layer, double parentX, double parentY,
                         double scale, double parentAlpha);
static void render_replicator(CAReplicatorLayer *rep, int x, int y, int w,
                              int h, double scale, double alpha,
                              CGRect frame);
static void render_emitter(CAEmitterLayer *emitter, int x, int y, int w,
                           int h, double scale, double alpha, CGRect frame);
static int g_render_offscreen;
static UIView *g_no_transform_view;
static UIView *g_no_round_clip_view;
static CALayer *g_no_transform_layer;
static int g_mask_render_depth;

/* Render a layer's mask into an offscreen pass and push its alpha channel
 * as a coverage mask positioned at the layer's screen origin. Coordinates
 * inside the mask layer are relative to the masked layer's top-left,
 * matching CALayer's mask frame semantics. */
static int push_layer_mask(CALayer *layer, int x, int y, int w, int h,
                           double scale)
{
    if (!layer || !layer->_mask || w <= 0 || h <= 0)
        return 0;
    if (g_mask_render_depth >= 4)
        return 0;
    void *state = iosim_fb_begin_offscreen((unsigned)w, (unsigned)h);
    if (!state)
        return 0;
    g_mask_render_depth++;
    render_layer((CALayer *)layer->_mask, 0, 0, scale, 1.0);
    g_mask_render_depth--;
    int bw = 0, bh = 0;
    unsigned *buf = iosim_fb_end_offscreen(state, &bw, &bh);
    if (!buf || bw <= 0 || bh <= 0)
    {
        if (buf)
            iosim_fb_free_offscreen(buf);
        return 0;
    }
    unsigned char *alpha = malloc((unsigned long)bw * (unsigned long)bh);
    if (!alpha)
    {
        iosim_fb_free_offscreen(buf);
        return 0;
    }
    for (int i = 0; i < bw * bh; i++)
        alpha[i] = (unsigned char)(buf[i] >> 24);
    int pushed = iosim_fb_push_clip_alpha(alpha, bw, bh, x, y);
    free(alpha);
    iosim_fb_free_offscreen(buf);
    return pushed;
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
    CATransform3D tf = layer->_transform;
    int transformed = layer != g_no_transform_layer &&
        (tf.m11 != 1.0 || tf.m12 != 0.0 || tf.m21 != 0.0 ||
         tf.m22 != 1.0 || tf.m41 != 0.0 || tf.m42 != 0.0 ||
         tf.m13 != 0.0 || tf.m23 != 0.0 || tf.m31 != 0.0 ||
         tf.m32 != 0.0 || tf.m33 != 1.0 || tf.m34 != 0.0 ||
         tf.m43 != 0.0 || tf.m44 != 1.0 || tf.m14 != 0.0 ||
         tf.m24 != 0.0);
    int perspective = tf.m13 != 0.0 || tf.m23 != 0.0 || tf.m31 != 0.0 ||
        tf.m32 != 0.0 || tf.m33 != 1.0 || tf.m34 != 0.0 ||
        tf.m43 != 0.0 || tf.m44 != 1.0 || tf.m14 != 0.0 ||
        tf.m24 != 0.0;
    if (transformed && w > 0 && h > 0)
    {
        void *state = iosim_fb_begin_offscreen((unsigned)w, (unsigned)h);
        if (state)
        {
            CALayer *saved = g_no_transform_layer;
            g_no_transform_layer = layer;
            g_render_offscreen++;
            render_layer(layer, -frame.origin.x, -frame.origin.y, scale, 1.0);
            g_render_offscreen--;
            g_no_transform_layer = saved;
            int bw = 0, bh = 0;
            unsigned *buf = iosim_fb_end_offscreen(state, &bw, &bh);
            if (buf)
            {
                double cx = w / 2.0, cy = h / 2.0;
                double ftx = x + cx - (tf.m11 * cx + tf.m21 * cy) +
                             tf.m41 * scale;
                double fty = y + cy - (tf.m12 * cx + tf.m22 * cy) +
                             tf.m42 * scale;
                if (perspective)
                {
                    double h11 = tf.m11;
                    double h12 = tf.m21;
                    double h13 = ftx;
                    double h21 = tf.m12;
                    double h22 = tf.m22;
                    double h23 = fty;
                    double h31 = tf.m14 + tf.m34 * tf.m13;
                    double h32 = tf.m24 + tf.m34 * tf.m23;
                    double h33 = tf.m44 +
                        tf.m34 * (tf.m43 * scale - tf.m13 * cx - tf.m23 * cy) -
                        tf.m14 * cx - tf.m24 * cy;
                    iosim_fb_blit_homography(buf, bw, bh, h11, h12, h13,
                                             h21, h22, h23, h31, h32, h33,
                                             alpha);
                }
                else
                    iosim_fb_blit_affine(buf, bw, bh, tf.m11, tf.m12, tf.m21,
                                         tf.m22, ftx, fty, alpha);
                iosim_fb_free_offscreen(buf);
            }
            return;
        }
    }
    iosim_fb_set_opacity(alpha);
    int masked = push_layer_mask(layer, x, y, w, h, scale);
    if (layer->_backgroundColor && color_alpha(layer->_backgroundColor) > 0.001 &&
        w > 0 && h > 0)
    {
        unsigned color = color_rgb(layer->_backgroundColor);
        iosim_fb_set_opacity(alpha * color_alpha(layer->_backgroundColor));
        double radius = layer_key_value(layer, "cornerRadius",
                                        layer->_cornerRadius);
        if (radius > 0)
            iosim_fb_fill_round_rect(x, y, w, h, (int)(radius * scale + 0.5),
                                     color);
        else
            iosim_fb_fill_rect(x, y, w, h, color);
        iosim_fb_set_opacity(alpha);
    }
    render_layer_contents(layer, x, y, w, h, alpha);
    if ([layer isKindOfClass:[CAGradientLayer class]])
        render_gradient_layer((CAGradientLayer *)layer, x, y, w, h, scale,
                              alpha, layer->_cornerRadius);
    else if ([layer isKindOfClass:[CAShapeLayer class]])
    {
        CAShapeLayer *sl = (CAShapeLayer *)layer;
        double dash_values[16];
        int dash_count = 0;
        NSArray *dash_pattern = (NSArray *)sl->_lineDashPattern;
        if (dash_pattern)
        {
            unsigned long count = [dash_pattern count];
            if (count > 16)
                count = 16;
            for (unsigned long i = 0; i < count; i++)
                dash_values[i] =
                    [[dash_pattern objectAtIndex:i] doubleValue] * scale;
            dash_count = (int)count;
        }
        render_shape_path((UIBezierPath *)sl->_path, x, y, w, h, scale,
                          (UIColor *)sl->_fillColor,
                          (UIColor *)sl->_strokeColor, sl->_lineWidth,
                          layer_key_value(sl, "strokeStart",
                                          sl->_strokeStart),
                          layer_key_value(sl, "strokeEnd", sl->_strokeEnd),
                          sl->_lineCap, sl->_lineJoin, dash_values,
                          dash_count,
                          layer_key_value(sl, "lineDashPhase",
                                          sl->_lineDashPhase) * scale);
    }
    else if ([layer isKindOfClass:[CATextLayer class]])
    {
        CATextLayer *tl = (CATextLayer *)layer;
        const char *text = string_cstr(tl->_string);
        if (text && *text && w > 0 && h > 0)
        {
            double points = tl->_fontSize;
            int style = IOSIM_FONT_REGULAR;
            if (tl->_font && [tl->_font isKindOfClass:[UIFont class]])
            {
                UIFont *font = (UIFont *)tl->_font;
                points = font->_size;
                style = font->_bold ? IOSIM_FONT_BOLD : IOSIM_FONT_REGULAR;
            }
            int ascent = 0, descent = 0, lineHeight = 0;
            iosim_fb_font_metrics(style, points, scale, &ascent, &descent,
                                  &lineHeight);
            int width = iosim_fb_font_text_width(text, style, points, scale);
            int tx = x;
            if (tl->_alignmentMode == 1)
                tx = x + w - width;
            else if (tl->_alignmentMode == 2)
                tx = x + (w - width) / 2;
            unsigned color = tl->_foregroundColor
                ? color_rgb((UIColor *)tl->_foregroundColor) : 0xffffff;
            iosim_fb_font_text(tx, y + ascent, text, style, points, scale,
                               color);
        }
    }

    if ([layer isKindOfClass:[CAReplicatorLayer class]])
    {
        render_replicator((CAReplicatorLayer *)layer, x, y, w, h, scale,
                          alpha, frame);
        if (masked)
            iosim_fb_pop_clip_mask();
        iosim_fb_set_opacity(1.0);
        return;
    }
    if ([layer isKindOfClass:[CAEmitterLayer class]])
        render_emitter((CAEmitterLayer *)layer, x, y, w, h, scale, alpha,
                       frame);
    for (int i = 0; i < layer->_sublayerCount; i++)
        render_layer((CALayer *)layer->_sublayers[i], parentX + frame.origin.x,
                     parentY + frame.origin.y, scale, alpha);
    if (masked)
        iosim_fb_pop_clip_mask();
    iosim_fb_set_opacity(1.0);
}

static void replicator_shift_color(unsigned *pixels, long count, float dr,
                                   float dg, float db, float da)
{
    int ir = (int)(dr * 255.0f + 0.5f);
    int ig = (int)(dg * 255.0f + 0.5f);
    int ib = (int)(db * 255.0f + 0.5f);
    int ia = (int)(da * 255.0f + 0.5f);
    if (!ir && !ig && !ib && !ia)
        return;
    for (long i = 0; i < count; i++)
    {
        unsigned p = pixels[i];
        int a = (int)((p >> 24) & 255) + ia;
        int r = (int)((p >> 16) & 255) + ir;
        int g = (int)((p >> 8) & 255) + ig;
        int b = (int)(p & 255) + ib;
        if (a < 0) a = 0; if (a > 255) a = 255;
        if (r < 0) r = 0; if (r > 255) r = 255;
        if (g < 0) g = 0; if (g > 255) g = 255;
        if (b < 0) b = 0; if (b > 255) b = 255;
        pixels[i] = ((unsigned)a << 24) | ((unsigned)r << 16) |
                    ((unsigned)g << 8) | (unsigned)b;
    }
}

static void render_replicator(CAReplicatorLayer *rep, int x, int y, int w,
                              int h, double scale, double alpha, CGRect frame)
{
    long count = rep->_instanceCount;
    if (count < 1)
        count = 1;
    if (count > 64)
        count = 64;
    if (w <= 0 || h <= 0 || rep->_sublayerCount == 0)
        return;
    void *state = iosim_fb_begin_offscreen((unsigned)w, (unsigned)h);
    if (!state)
        return;
    g_render_offscreen++;
    for (int i = 0; i < rep->_sublayerCount; i++)
        render_layer((CALayer *)rep->_sublayers[i], 0, 0, scale, 1.0);
    g_render_offscreen--;
    int bw = 0, bh = 0;
    unsigned *buf = iosim_fb_end_offscreen(state, &bw, &bh);
    if (!buf || bw <= 0 || bh <= 0)
    {
        if (buf)
            iosim_fb_free_offscreen(buf);
        return;
    }
    unsigned *work = malloc((unsigned long)bw * (unsigned long)bh *
                            sizeof(unsigned));
    if (!work)
    {
        iosim_fb_free_offscreen(buf);
        return;
    }
    memcpy(work, buf, (unsigned long)bw * (unsigned long)bh *
                       sizeof(unsigned));
    if (rep->_instanceColor)
    {
        unsigned tint = gradient_entry_rgb(rep->_instanceColor);
        double tint_alpha =
            gradient_entry_alpha(rep->_instanceColor) / 255.0;
        int tr = (int)((tint >> 16) & 255);
        int tg = (int)((tint >> 8) & 255);
        int tb = (int)(tint & 255);
        for (int i = 0; i < bw * bh; i++)
        {
            unsigned p = work[i];
            int a = (int)(((p >> 24) & 255) * tint_alpha);
            int r = (int)(((p >> 16) & 255) * tr / 255.0);
            int g = (int)(((p >> 8) & 255) * tg / 255.0);
            int b = (int)((p & 255) * tb / 255.0);
            work[i] = ((unsigned)a << 24) | ((unsigned)r << 16) |
                      ((unsigned)g << 8) | (unsigned)b;
        }
    }
    CATransform3D t = rep->_instanceTransform;
    double a = 1, b = 0, c = 0, d = 1, tx = 0, ty = 0;
    for (long i = 0; i < count; i++)
    {
        double cx = w / 2.0, cy = h / 2.0;
        double ftx = x + cx - (a * cx + c * cy) + tx * scale;
        double fty = y + cy - (b * cx + d * cy) + ty * scale;
        iosim_fb_blit_affine(work, bw, bh, a, b, c, d, ftx, fty, alpha);
        if (i + 1 < count)
        {
            double na = a * t.m11 + c * t.m12;
            double nb = b * t.m11 + d * t.m12;
            double nc = a * t.m21 + c * t.m22;
            double nd = b * t.m21 + d * t.m22;
            double ntx = a * t.m41 + c * t.m42 + tx;
            double nty = b * t.m41 + d * t.m42 + ty;
            a = na; b = nb; c = nc; d = nd; tx = ntx; ty = nty;
            replicator_shift_color(work, (long)bw * bh,
                                   rep->_instanceRedOffset,
                                   rep->_instanceGreenOffset,
                                   rep->_instanceBlueOffset,
                                   rep->_instanceAlphaOffset);
        }
    }
    free(work);
    iosim_fb_free_offscreen(buf);
}

/* Deterministic particle field. Each cell's particles are placed on a
 * repeating lifetime ring, so the emitter reaches a steady state without
 * retaining per-frame state; a small LCG supplies per-particle variation. */
static double emitter_rand(unsigned seed)
{
    seed = seed * 1664525u + 1013904223u;
    return (double)((seed >> 8) & 0xffffff) / 16777216.0;
}

static double emitter_wrap(double value, double period)
{
    if (period <= 0.0)
        return 0.0;
    double cycles = value / period;
    return (cycles - (double)(long long)cycles) * period;
}

static void render_emitter(CAEmitterLayer *emitter, int x, int y, int w,
                           int h, double scale, double alpha, CGRect frame)
{
    (void)frame;
    if (!emitter || !emitter->_emitterCells || w <= 0 || h <= 0)
        return;
    static double epoch = -1.0;
    double now = iosim_now();
    if (epoch < 0.0)
        epoch = now;
    unsigned long cellCount = [emitter->_emitterCells count];
    double ex = x + emitter->_emitterPosition.x * scale;
    double ey = y + emitter->_emitterPosition.y * scale;
    for (unsigned long c = 0; c < cellCount; c++)
    {
        CAEmitterCell *cell =
            (CAEmitterCell *)[emitter->_emitterCells objectAtIndex:c];
        if (!cell || !cell->_enabled)
            continue;
        double rate = (double)cell->_birthRate * emitter->_birthRate;
        if (rate <= 0.0)
            continue;
        double lifetime = cell->_lifetime > 0.0f ? cell->_lifetime
                                                 : emitter->_lifetime;
        if (lifetime <= 0.0)
            lifetime = 1.0;
        int count = (int)(rate * lifetime + 0.5);
        if (count < 1)
            count = 1;
        if (count > 128)
            count = 128;
        double cycle = emitter_wrap(now - epoch, lifetime);
        if (cycle < 0.0)
            cycle += lifetime;
        double base[4] = { 1.0, 1.0, 1.0, 1.0 };
        if (cell->_color)
            [cell->_color ui_components:base];
        for (int i = 0; i < count; i++)
        {
            unsigned seed = emitter->_seed + (unsigned)c * 0x9e3779b9u +
                            (unsigned)i * 0x85ebca6bu;
            double age = emitter_wrap(cycle + (double)i / count * lifetime,
                                      lifetime);
            double angle = cell->_emissionRange > 0.0f
                ? (emitter_rand(seed) - 0.5) * cell->_emissionRange : 0.0;
            double speed = cell->_velocity +
                cell->_velocityRange * (emitter_rand(seed ^ 0x51u) - 0.5);
            double px = ex + cos(angle) * speed * age * scale +
                        0.5 * cell->_xAcceleration * age * age * scale;
            double py = ey + sin(angle) * speed * age * scale +
                        0.5 * cell->_yAcceleration * age * age * scale;
            if (px < x || px >= x + w || py < y || py >= y + h)
                continue;
            double size = 12.0 * (double)cell->_scale *
                (1.0 + cell->_scaleRange *
                 (emitter_rand(seed ^ 0xa7u) - 0.5)) * scale;
            if (size < 1.0)
                size = 1.0;
            if (size > 256.0)
                size = 256.0;
            double red = base[0] + cell->_redSpeed * age +
                cell->_redRange * (emitter_rand(seed ^ 0x1bu) - 0.5);
            double green = base[1] + cell->_greenSpeed * age +
                cell->_greenRange * (emitter_rand(seed ^ 0x2du) - 0.5);
            double blue = base[2] + cell->_blueSpeed * age +
                cell->_blueRange * (emitter_rand(seed ^ 0x3fu) - 0.5);
            double particleAlpha = base[3] + cell->_alphaSpeed * age +
                cell->_alphaRange * (emitter_rand(seed ^ 0x4eu) - 0.5);
            if (particleAlpha < 0.0)
                particleAlpha = 0.0;
            if (particleAlpha > 1.0)
                particleAlpha = 1.0;
            if (particleAlpha <= 0.001)
                continue;
            int r = (int)(red * 255.0 + 0.5);
            int g = (int)(green * 255.0 + 0.5);
            int b = (int)(blue * 255.0 + 0.5);
            if (r < 0) r = 0; if (r > 255) r = 255;
            if (g < 0) g = 0; if (g > 255) g = 255;
            if (b < 0) b = 0; if (b > 255) b = 255;
            unsigned color = ((unsigned)r << 16) | ((unsigned)g << 8) |
                             (unsigned)b;
            iosim_fb_set_opacity(alpha * particleAlpha);
            int radius = (int)(size / 2.0 + 0.5);
            iosim_fb_fill_round_rect((int)(px - size / 2.0 + 0.5),
                                     (int)(py - size / 2.0 + 0.5),
                                     (int)(size + 0.5), (int)(size + 0.5),
                                     radius, color);
        }
    }
    iosim_fb_set_opacity(alpha);
}

/* Separable box blur over an XRGB rectangle. Two passes approximate the
 * Gaussian backdrop blur UIVisualEffectView applies behind its content. */
static void blur_box_xrgb(unsigned *pix, int w, int h, int radius, int passes)
{
    if (!pix || w <= 0 || h <= 0 || radius < 1 || passes < 1)
        return;
    unsigned *tmp = malloc((unsigned long)w * h * sizeof(unsigned));
    if (!tmp)
        return;
    int span = 2 * radius + 1;
    for (int pass = 0; pass < passes; pass++)
    {
        for (int y = 0; y < h; y++)
        {
            unsigned *row = pix + (unsigned long)y * w;
            unsigned *out = tmp + (unsigned long)y * w;
            long r = 0, g = 0, b = 0;
            for (int k = -radius; k <= radius; k++)
            {
                int x = k < 0 ? 0 : (k >= w ? w - 1 : k);
                unsigned c = row[x];
                r += (c >> 16) & 255;
                g += (c >> 8) & 255;
                b += c & 255;
            }
            for (int x = 0; x < w; x++)
            {
                out[x] = ((unsigned)(r / span) << 16) |
                         ((unsigned)(g / span) << 8) | (unsigned)(b / span);
                int add = x + radius + 1;
                if (add >= w)
                    add = w - 1;
                int sub = x - radius;
                if (sub < 0)
                    sub = 0;
                unsigned ca = row[add], cs = row[sub];
                r += (long)((ca >> 16) & 255) - (long)((cs >> 16) & 255);
                g += (long)((ca >> 8) & 255) - (long)((cs >> 8) & 255);
                b += (long)(ca & 255) - (long)(cs & 255);
            }
        }
        for (int x = 0; x < w; x++)
        {
            long r = 0, g = 0, b = 0;
            for (int k = -radius; k <= radius; k++)
            {
                int y = k < 0 ? 0 : (k >= h ? h - 1 : k);
                unsigned c = tmp[(unsigned long)y * w + x];
                r += (c >> 16) & 255;
                g += (c >> 8) & 255;
                b += c & 255;
            }
            for (int y = 0; y < h; y++)
            {
                pix[(unsigned long)y * w + x] =
                    ((unsigned)(r / span) << 16) |
                    ((unsigned)(g / span) << 8) | (unsigned)(b / span);
                int add = y + radius + 1;
                if (add >= h)
                    add = h - 1;
                int sub = y - radius;
                if (sub < 0)
                    sub = 0;
                unsigned ca = tmp[(unsigned long)add * w + x];
                unsigned cs = tmp[(unsigned long)sub * w + x];
                r += (long)((ca >> 16) & 255) - (long)((cs >> 16) & 255);
                g += (long)((ca >> 8) & 255) - (long)((cs >> 8) & 255);
                b += (long)(ca & 255) - (long)(cs & 255);
            }
        }
    }
    free(tmp);
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

    CGAffineTransform tf = current_transform(view);
    int transformed = (tf.a != 1.0 || tf.b != 0.0 || tf.c != 0.0 ||
                       tf.d != 1.0 || tf.tx != 0.0 || tf.ty != 0.0);
    if (transformed && view != g_no_transform_view && w > 0 && h > 0)
    {
        /* A transformed view is rendered into an offscreen pass and then
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

    /* A clipping view with a corner radius renders its whole subtree into
     * an offscreen, masks the four corners and composites the result. The
     * guard stops the same view from entering the wrapper again. */
    double clip_radius = view->_layer
        ? layer_key_value(view->_layer, "cornerRadius",
                          view->_layer->_cornerRadius)
        : 0.0;
    int clips = view->_clipsToBounds ||
        (view->_layer && view->_layer->_masksToBounds) ||
        [view isKindOfClass:[UIScrollView class]];
    if (clips && clip_radius > 0 && w > 0 && h > 0 &&
        view != g_no_round_clip_view)
    {
        void *state = iosim_fb_begin_offscreen((unsigned)w, (unsigned)h);
        if (state)
        {
            UIView *saved = g_no_round_clip_view;
            g_no_round_clip_view = view;
            g_render_offscreen++;
            render_view(view, -frame.origin.x, -frame.origin.y, scale,
                        parentAlpha);
            g_render_offscreen--;
            g_no_round_clip_view = saved;
            iosim_fb_mask_round_rect_corners(
                0, 0, w, h, (int)(clip_radius * scale + 0.5),
                view->_layer ? view->_layer->_maskedCorners : 15u);
            int bw = 0, bh = 0;
            unsigned *buf = iosim_fb_end_offscreen(state, &bw, &bh);
            if (buf)
            {
                iosim_fb_blit_affine(buf, bw, bh, 1.0, 0.0, 0.0, 1.0,
                                     x, y, 1.0);
                iosim_fb_free_offscreen(buf);
            }
            return;
        }
    }

    int masked = 0;
    if (view->_layer)
        masked = push_layer_mask(view->_layer, x, y, w, h, scale);

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

    if (view->_backgroundColor && color_alpha(view->_backgroundColor) > 0.001 &&
        w > 0 && h > 0 &&
        ![view isKindOfClass:[UIVisualEffectView class]])
    {
        unsigned color = color_rgb(view->_backgroundColor);
        iosim_fb_set_opacity(alpha * color_alpha(view->_backgroundColor));
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
        render_layer_contents(view->_layer, x, y, w, h, alpha);
    if (view->_layer &&
        [view->_layer isKindOfClass:[CAGradientLayer class]])
        render_gradient_layer((CAGradientLayer *)view->_layer, x, y, w, h,
                              scale, alpha,
                              layer_key_value(view->_layer, "cornerRadius",
                                              view->_layer->_cornerRadius));

    if (w > 0 && h > 0)
    {
        CGContextRef context = iosim_cg_begin_view(x, y, w, h, scale, alpha);
        if (context)
        {
            [view drawRect:[view bounds]];
            iosim_cg_end_view(context);
        }
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
            int swiped = section == table->_swipeSection &&
                         i == table->_swipeRow;
            if (cell)
            {
                double shift = swiped ? -80.0 : (table->_editing ? 32.0 : 0.0);
                double cellWidth =
                    frame.size.width - (shift > 0 ? shift : 0);
                cell->_frame = CGRectMake(shift, cursor - tableScrollY,
                                          cellWidth, rowHeight);
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
            if (swiped)
            {
                int bw = (int)(80 * scale + 0.5);
                int bx = x + w - bw;
                iosim_fb_set_opacity(alpha);
                iosim_fb_fill_rect(bx, ry, bw, rh, 0xff3b30);
                int asc = 0, desc = 0, lh = 0;
                iosim_fb_font_metrics(IOSIM_FONT_SEMIBOLD, 17, scale, &asc,
                                      &desc, &lh);
                const char *label = "Delete";
                int tw = iosim_fb_font_text_width(label, IOSIM_FONT_SEMIBOLD,
                                                  17, scale);
                iosim_fb_font_text(bx + (bw - tw) / 2,
                                   ry + (rh - lh) / 2 + asc, label,
                                   IOSIM_FONT_SEMIBOLD, 17, scale, 0xffffff);
            }
            else if (table->_editing)
            {
                int cx = x + (int)(22 * scale);
                int cy = ry + rh / 2;
                iosim_fb_fill_circle(cx, cy, (int)(12 * scale), 0xff3b30);
                iosim_fb_fill_rect(cx - (int)(6 * scale),
                                   cy - (int)(1.2 * scale + 0.5),
                                   (int)(12 * scale),
                                   (int)(2.4 * scale + 0.5), 0xffffff);
            }
            if (!swiped)
            {
                iosim_fb_set_opacity(alpha);
                iosim_fb_fill_rect(x + (int)(16 * scale), ry + rh - 1,
                                   w - (int)(16 * scale), 1, 0x38383a);
            }
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

    if ([view isKindOfClass:[UIRefreshControl class]])
    {
        UIRefreshControl *rc = (UIRefreshControl *)view;
        double progress = rc->_refreshing ? 1.0 : rc->_pullProgress;
        if (progress > 0.02)
        {
            int cx = x + w / 2, cy = y + h / 2;
            int inner = (int)(5 * scale), outer = (int)(13 * scale),
                thick = (int)(2.5 * scale);
            double phase = rc->_refreshing
                               ? iosim_now() - (long)iosim_now() : 0;
            for (int i = 0; i < 8; i++)
            {
                double a =
                    (i * 45.0 - 90.0) * 3.14159265358979323846 / 180.0;
                double fade = progress;
                if (rc->_refreshing)
                {
                    double tail = i + 8 - phase * 8.0;
                    while (tail >= 8)
                        tail -= 8;
                    fade = 0.18 + 0.82 * (tail / 8.0);
                }
                iosim_fb_set_opacity(alpha * fade);
                iosim_fb_draw_line(cx + (int)(__builtin_cos(a) * inner),
                                   cy + (int)(__builtin_sin(a) * inner),
                                   cx + (int)(__builtin_cos(a) * outer),
                                   cy + (int)(__builtin_sin(a) * outer),
                                   thick, 0x8e8e93);
            }
            iosim_fb_set_opacity(alpha);
        }
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
    else if ([view isKindOfClass:[UIPickerView class]])
    {
        UIPickerView *picker = (UIPickerView *)view;
        long components = picker_components(picker);
        unsigned textColor = picker_text_color(view);
        int bandH = (int)(PICKER_ROW_HEIGHT * scale + 0.5);
        int centerY = y + h / 2;
        int clippedPicker = iosim_fb_push_clip(x, y, w, h);
        /* Selection band: a tinted lozenge inside two hairlines. */
        iosim_fb_set_opacity(alpha * (textColor == 0x000000 ? 0.06 : 0.10));
        iosim_fb_fill_round_rect(x, centerY - bandH / 2, w, bandH,
                                 (int)(6 * scale + 0.5), textColor);
        iosim_fb_set_opacity(alpha * (textColor == 0x000000 ? 0.12 : 0.22));
        iosim_fb_fill_rect(x, centerY - bandH / 2, w, 1, textColor);
        iosim_fb_fill_rect(x, centerY + bandH / 2 - 1, w, 1, textColor);
        iosim_fb_set_opacity(alpha);
        for (long c = 0; c < components; c++)
        {
            long rows = picker_rows(picker, c);
            double componentWidth = (double)w / components;
            int cx = x + (int)((c + 0.5) * componentWidth + 0.5);
            int ascent = 0, descent = 0, lineHeight = 0;
            double points = 21.0;
            iosim_fb_font_metrics(IOSIM_FONT_REGULAR, points, scale, &ascent,
                                  &descent, &lineHeight);
            double offset = picker->_rowOffsets[c];
            for (long r = 0; r < rows; r++)
            {
                double dy = ((double)r - offset) * PICKER_ROW_HEIGHT;
                double rowCenter = centerY + dy * scale;
                if (rowCenter < y - PICKER_ROW_HEIGHT * scale ||
                    rowCenter > y + h + PICKER_ROW_HEIGHT * scale)
                    continue;
                id title = picker_title(picker, r, c);
                const char *text = iosim_string_cstr(title);
                if (!text)
                    continue;
                double half = h > 0 ? h / 2.0 : 1.0;
                double distance = __builtin_fabs(dy) / half;
                if (distance > 1)
                    distance = 1;
                double fade = 1.0 - 0.7 * distance * distance;
                int tw = iosim_fb_font_text_width(text, IOSIM_FONT_REGULAR,
                                                  points, scale);
                int baseline =
                    (int)(rowCenter + 0.5) + ascent - lineHeight / 2;
                iosim_fb_set_opacity(alpha * fade);
                iosim_fb_font_text(cx - tw / 2, baseline, text,
                                   IOSIM_FONT_REGULAR, points, scale,
                                   textColor);
            }
        }
        iosim_fb_set_opacity(alpha);
        if (clippedPicker)
            iosim_fb_pop_clip();
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
        if (field->_borderStyle != 0)
        {
            int radius = field->_borderStyle == 3 ? (int)(8 * scale) : 0;
            iosim_fb_fill_round_rect(x, y, w, h, radius, 0x1c1c1e);
        }
        int tx = x + (field->_borderStyle != 0 ? (int)(8 * scale) : 0);
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
                char fitted[256];
                int textWidth = 0;
                double fittedPoints = label_shrunk_points(
                    label, text, style, scale, w, &textWidth);
                if (fittedPoints != points)
                {
                    points = fittedPoints;
                    iosim_fb_font_metrics(style, points, scale, &ascent,
                                          &descent, &lineHeight);
                }
                if (w > 0 && textWidth > w)
                {
                    label_ellipsized(text, style, points, scale, w,
                                     label->_lineBreakMode, fitted,
                                     sizeof fitted);
                    text = fitted;
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
        NSRange selection = editor->_selectedRange;
        unsigned long text_length = text ? strlen(text) : 0;
        if (selection.location > text_length)
            selection.location = text_length;
        if (selection.length > text_length - selection.location)
            selection.length = text_length - selection.location;
        unsigned long selection_start = selection.location;
        unsigned long selection_end = selection.location + selection.length;

        unsigned long line_start = 0;
        for (int i = 0; i < n; i++)
        {
            int length = (int)strlen(lines[i]);
            unsigned long line_end = line_start + (unsigned long)length;
            unsigned long highlight_start =
                selection_start > line_start ? selection_start : line_start;
            unsigned long highlight_end =
                selection_end < line_end ? selection_end : line_end;
            if (selection.length > 0 && highlight_end > highlight_start)
            {
                int prefix = (int)(highlight_start - line_start);
                int span = (int)(highlight_end - highlight_start);
                char before[256], selected_text[256];
                if (prefix > 255) prefix = 255;
                if (span > 255) span = 255;
                memcpy(before, lines[i], (unsigned long)prefix);
                before[prefix] = 0;
                memcpy(selected_text, lines[i] + prefix, (unsigned long)span);
                selected_text[span] = 0;
                int before_width = iosim_fb_font_text_width(
                    before, style, points, scale);
                int span_width = iosim_fb_font_text_width(
                    selected_text, style, points, scale);
                iosim_fb_fill_rect(x + inset + before_width,
                                   y + inset + i * lineHeight,
                                   span_width, lineHeight, 0x33507a);
            }
            line_start = line_end + 1;
        }

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
        if (selection.length > 0 || selection.location != text_length)
        {
            unsigned long caret_index =
                selection.location + selection.length;
            unsigned long remaining = caret_index;
            line_start = 0;
            for (int i = 0; i < n; i++)
            {
                int length = (int)strlen(lines[i]);
                if (remaining <= (unsigned long)length || i == n - 1)
                {
                    int offset = (int)(remaining > (unsigned long)length
                                           ? (unsigned long)length
                                           : remaining);
                    char prefix[256];
                    if (offset > 255) offset = 255;
                    memcpy(prefix, lines[i], (unsigned long)offset);
                    prefix[offset] = 0;
                    caretX = x + inset + iosim_fb_font_text_width(
                        prefix, style, points, scale);
                    caretBaseline = y + inset + i * lineHeight + ascent;
                    break;
                }
                remaining -= (unsigned long)length;
                if (remaining > 0)
                    remaining--;
            }
        }
        if (g_firstResponder == editor)
            iosim_fb_fill_rect(caretX + (int)(1 * scale),
                               caretBaseline - ascent, (int)(2 * scale),
                               lineHeight, 0x426bf2);
        if (selection.length > 0)
        {
            int start_x = 0, start_y = 0, end_x = 0, end_y = 0;
            text_index_line_position((const char (*)[256])lines, n, style,
                                     points, scale, inset, x, y, lineHeight,
                                     selection_start, &start_x, &start_y);
            text_index_line_position((const char (*)[256])lines, n, style,
                                     points, scale, inset, x, y, lineHeight,
                                     selection_end, &end_x, &end_y);
            int stem = (int)(6 * scale + 0.5);
            int radius = (int)(5 * scale + 0.5);
            int width = (int)(2 * scale + 0.5);
            if (stem < 2)
                stem = 2;
            if (radius < 2)
                radius = 2;
            if (width < 1)
                width = 1;
            iosim_fb_fill_rect(start_x - width / 2, start_y + lineHeight,
                               width, stem + radius, 0x426bf2);
            iosim_fb_fill_rect(end_x - width / 2, end_y + lineHeight, width,
                               stem + radius, 0x426bf2);
            iosim_fb_fill_circle(start_x, start_y + lineHeight + stem,
                                 radius, 0x426bf2);
            iosim_fb_fill_circle(end_x, end_y + lineHeight + stem, radius,
                                 0x426bf2);
        }
    }

    if ([view isKindOfClass:[UIVisualEffectView class]])
    {
        UIVisualEffectView *ve = (UIVisualEffectView *)view;
        if (ve->_contentView)
            ((UIView *)ve->_contentView)->_frame =
                CGRectMake(0, 0, frame.size.width, frame.size.height);
        long style =
            ve->_effect ? ve->_effect->_style : UIBlurEffectStyleLight;
        if (w > 0 && h > 0)
        {
            unsigned long count = (unsigned long)w * h;
            unsigned *cap = malloc(count * sizeof(unsigned));
            if (cap)
            {
                iosim_fb_capture(x, y, w, h, cap);
                blur_box_xrgb(cap, w, h, (int)(24 * scale + 0.5), 2);
                unsigned tint;
                double tint_alpha;
                if (style == UIBlurEffectStyleDark)
                {
                    tint = 0x101014;
                    tint_alpha = 0.45;
                }
                else if (style == UIBlurEffectStyleExtraLight)
                {
                    tint = 0xffffff;
                    tint_alpha = 0.55;
                }
                else if (style >= UIBlurEffectStyleSystemUltraThinMaterial)
                {
                    /* System materials follow the device appearance. */
                    double thickness =
                        (double)(style - UIBlurEffectStyleSystemUltraThinMaterial);
                    if (ui_style_current() == 1)
                    {
                        tint = 0x1c1c1e;
                        tint_alpha = 0.50 + thickness * 0.05;
                    }
                    else
                    {
                        tint = 0xf2f2f7;
                        tint_alpha = 0.28 + thickness * 0.04;
                    }
                }
                else
                {
                    tint = 0xf2f2f7;
                    tint_alpha = 0.35;
                }
                unsigned char *rgba = malloc(count * 4);
                if (rgba)
                {
                    double radius_pt =
                        view->_layer
                            ? layer_key_value(view->_layer, "cornerRadius",
                                              view->_layer->_cornerRadius)
                            : 0.0;
                    int rr = (int)(radius_pt * scale + 0.5);
                    if (rr * 2 > w)
                        rr = w / 2;
                    if (rr * 2 > h)
                        rr = h / 2;
                    double cx = w / 2.0, cy = h / 2.0;
                    double exr = w / 2.0 - rr, eyr = h / 2.0 - rr;
                    unsigned tr = (tint >> 16) & 255;
                    unsigned tg = (tint >> 8) & 255;
                    unsigned tb = tint & 255;
                    for (int yy = 0; yy < h; yy++)
                    {
                        unsigned char *out = rgba + (unsigned long)yy * w * 4;
                        for (int xx = 0; xx < w; xx++)
                        {
                            unsigned c = cap[(unsigned long)yy * w + xx];
                            double ir = (1.0 - tint_alpha) *
                                            ((c >> 16) & 255) +
                                        tr * tint_alpha;
                            double ig = (1.0 - tint_alpha) *
                                            ((c >> 8) & 255) +
                                        tg * tint_alpha;
                            double ib =
                                (1.0 - tint_alpha) * (c & 255) + tb * tint_alpha;
                            double px = xx + 0.5 - cx, py = yy + 0.5 - cy;
                            double qx = __builtin_fabs(px) - exr;
                            double qy = __builtin_fabs(py) - eyr;
                            double axr = qx > 0 ? qx : 0;
                            double ayr = qy > 0 ? qy : 0;
                            double outside =
                                __builtin_sqrt(axr * axr + ayr * ayr);
                            double inside = qx > qy ? qx : qy;
                            double dist =
                                outside + (inside < 0 ? inside : 0) - rr;
                            double cov = 0.5 - dist;
                            unsigned a;
                            if (cov <= 0)
                                a = 0;
                            else if (cov >= 1)
                                a = 255;
                            else
                                a = (unsigned)(cov * 255.0 + 0.5);
                            out[xx * 4] = (unsigned char)(ir + 0.5);
                            out[xx * 4 + 1] = (unsigned char)(ig + 0.5);
                            out[xx * 4 + 2] = (unsigned char)(ib + 0.5);
                            out[xx * 4 + 3] = (unsigned char)a;
                        }
                    }
                    iosim_fb_blit_rgba(x, y, w, h, rgba, w * 4);
                    free(rgba);
                }
                free(cap);
            }
        }
    }

    double scrollX = 0, scrollY = 0;
    if ([view isKindOfClass:[UIScrollView class]])
    {
        UIScrollView *scroll = (UIScrollView *)view;
        scrollX = scroll->_contentOffset.x;
        scrollY = scroll->_contentOffset.y;
        if (scroll->_refreshControl)
        {
            UIView *rc = (UIView *)scroll->_refreshControl;
            rc->_frame = CGRectMake(0, -REFRESH_CONTROL_HEIGHT,
                                    frame.size.width, REFRESH_CONTROL_HEIGHT);
        }
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
    if (masked)
        iosim_fb_pop_clip_mask();
    iosim_fb_set_opacity(1.0);
}

/* Right side of the status bar: cellular, Wi-Fi and battery. The lock screen
 * draws these without the time, which it shows at display size. */
static void draw_status_icons(int fbWidth, double scale, unsigned color)
{
    /* Cellular signal placeholders, Wi-Fi and battery, measured from the
     * iPhone 18 Pro status bar. IOSIM_STATUS_SIGNAL=bars draws the override
     * style; IOSIM_STATUS_BATTERY=charging draws the green battery. */
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
                                     (int)(1.0 * scale), color);
    }
    else
    {
        for (int i = 0; i < 4; i++)
            iosim_fb_fill_circle((int)((278.83 + i * 5.667) * scale),
                                 (int)(37.83 * scale), (int)(1.85 * scale),
                                 color);
    }
    for (int i = 0; i < 51; i++)
    {
        double angle = (-140.0 + i * 2.0) * 3.14159265358979323846 / 180.0;
        int x = (int)((315.33 + 11.08 * __builtin_cos(angle)) * scale);
        int y = (int)((38.0 + 11.08 * __builtin_sin(angle)) * scale);
        iosim_fb_fill_circle(x, y, (int)(1.03 * scale), color);
        x = (int)((315.33 + 7.08 * __builtin_cos(angle)) * scale);
        y = (int)((38.0 + 7.08 * __builtin_sin(angle)) * scale);
        iosim_fb_fill_circle(x, y, (int)(1.03 * scale), color);
    }
    iosim_fb_fill_circle((int)(315.33 * scale), (int)(36.67 * scale),
                         (int)(2.67 * scale), color);
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
                                 (int)(4.0 * scale), color);
        iosim_fb_fill_round_rect((int)(360.0 * scale), (int)(29.67 * scale),
                                 (int)(2.0 * scale), (int)(5.0 * scale),
                                 (int)(1.0 * scale), color);
    }
}

static int g_shell_active;
static int g_sb_overlay_guard;
static UIViewController *g_app_root_controller;
static void shell_draw_notification_overlays(int fbWidth, double scale);

/* Walk down through navigation and tab containers (and any explicit
 * childForStatusBarStyle/Hidden) to the controller that owns the status bar. */
static UIViewController *app_status_bar_controller(void)
{
    UIViewController *vc = g_app_root_controller;
    while (vc)
    {
        UIViewController *child = [vc childForStatusBarStyle];
        if (!child && [vc isKindOfClass:[UINavigationController class]])
            child = [(UINavigationController *)vc topViewController];
        else if (!child && [vc isKindOfClass:[UITabBarController class]])
            child = [(UITabBarController *)vc selectedViewController];
        if (!child || child == vc)
            break;
        vc = child;
    }
    return vc;
}

static int app_status_bar_hidden(void)
{
    if (g_status_bar_hidden_override >= 0)
        return g_status_bar_hidden_override;
    UIViewController *vc = g_app_root_controller;
    while (vc)
    {
        if ([vc prefersStatusBarHidden])
            return 1;
        UIViewController *child = [vc childForStatusBarHidden];
        if (!child && [vc isKindOfClass:[UINavigationController class]])
            child = [(UINavigationController *)vc topViewController];
        else if (!child && [vc isKindOfClass:[UITabBarController class]])
            child = [(UITabBarController *)vc selectedViewController];
        if (!child || child == vc)
            break;
        vc = child;
    }
    return 0;
}

/* Status bar glyphs are white over SpringBoard's wallpaper and follow the
 * foreground app's style otherwise. An explicit UIApplication style wins;
 * then the deepest controller's preferredStatusBarStyle; a plain default
 * style picks the color that reads against the root view's background. */
static unsigned app_status_bar_color(void)
{
    long style = g_status_bar_style_override;
    if (style < 0)
    {
        UIViewController *controller = app_status_bar_controller();
        if (controller)
            style = [controller preferredStatusBarStyle];
    }
    if (style == UIStatusBarStyleLightContent)
        return 0xffffff;
    if (style == UIStatusBarStyleDarkContent)
        return 0x000000;
    UIView *view = g_app_root_controller ? [g_app_root_controller view] : nil;
    UIColor *background = view ? view->_backgroundColor : nil;
    if (background)
    {
        unsigned rgb = color_rgb(background);
        double luminance = (0.299 * (((rgb >> 16) & 0xff) / 255.0) +
                            0.587 * (((rgb >> 8) & 0xff) / 255.0) +
                            0.114 * ((rgb & 0xff) / 255.0));
        if (luminance < 0.5)
            return 0xffffff;
    }
    return 0x000000;
}

/* Info.plist can set the application-wide status bar before any controller
 * asks for its own; a later UIApplication call still wins. */
static void apply_status_bar_plist(void)
{
    NSBundle *bundle = [NSBundle mainBundle];
    NSDictionary *info = bundle ? [bundle infoDictionary] : nil;
    if (!info)
        return;
    id based = [info objectForKey:@"UIViewControllerBasedStatusBarAppearance"];
    BOOL controllerBased = based ? [based boolValue] : YES;
    id hidden = [info objectForKey:@"UIStatusBarHidden"];
    if (hidden && [hidden boolValue])
        g_status_bar_hidden_override = 1;
    if (!controllerBased)
    {
        id style = [info objectForKey:@"UIStatusBarStyle"];
        const char *name = style ? iosim_string_cstr(style) : 0;
        if (name && strstr(name, "LightContent"))
            g_status_bar_style_override = UIStatusBarStyleLightContent;
        else if (name && strstr(name, "DarkContent"))
            g_status_bar_style_override = UIStatusBarStyleDarkContent;
    }
}

static void draw_device_chrome(int fbWidth, double scale)
{
    if (!g_shell_active && app_status_bar_hidden())
        return;
    unsigned chrome = g_shell_active ? 0xffffff : app_status_bar_color();
    (void)fbWidth;
    /* Status bar: time, cellular, Wi-Fi and battery. */
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
                       IOSIM_FONT_SEMIBOLD, timeSize, scale, chrome);
    draw_status_icons(fbWidth, scale, chrome);
    if (g_shell_active && !g_sb_overlay_guard)
        shell_draw_notification_overlays(fbWidth, scale);
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
        else if ([g_firstResponder respondsToSelector:
                     @selector(handleReturnKey)])
            [g_firstResponder handleReturnKey];
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
extern void iosim_on_lock_request(void (*handler)(void));
extern int iosim_request_lock(void);
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
    int badge;   /* icon badge count from the shared badge store */
};

static struct shell_app g_shell_apps[SHELL_MAX_APPS];
static int g_shell_app_count;
static int g_home_page;

#define SHELL_MAX_FOLDERS 16
#define SHELL_FOLDER_MAX_APPS 12
struct shell_folder {
    char name[64];
    char bundles[SHELL_FOLDER_MAX_APPS][128];
    int count;
};
static struct shell_folder g_folders[SHELL_MAX_FOLDERS];
static int g_folder_count;
static int g_open_folder = -1;

struct shell_grid_entry {
    int app;
    int folder;
};

static int shell_grid_entries(struct shell_grid_entry *out, int cap);

/* Pages follow grid entries, not raw apps: a folder occupies one slot no
 * matter how many apps it holds. */
static int shell_page_count(void)
{
    int grid = shell_grid_entries(0, SHELL_MAX_APPS + SHELL_MAX_FOLDERS);
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

/* --------------------------------------------------------------- folders
 *
 * A folder groups installed apps by bundle id. Creating one by dropping an
 * icon onto another removes both tiles from the grid and draws a folder at
 * the first app's position. The grouping is written to the device data
 * container so it survives SpringBoard restarts. Stock apps (no bundle id)
 * cannot be grouped because their identity is not persisted. */

static int shell_folder_for_bundle(const char *bundle)
{
    if (!bundle || !*bundle)
        return -1;
    for (int f = 0; f < g_folder_count; f++)
        for (int k = 0; k < g_folders[f].count; k++)
            if (strcmp(g_folders[f].bundles[k], bundle) == 0)
                return f;
    return -1;
}

static int shell_folder_for_app(int index)
{
    if (index < 0 || index >= g_shell_app_count)
        return -1;
    return shell_folder_for_bundle(g_shell_apps[index].bundle);
}

static int shell_folder_member_app(int folder, int member)
{
    if (folder < 0 || folder >= g_folder_count)
        return -1;
    if (member < 0 || member >= g_folders[folder].count)
        return -1;
    const char *bundle = g_folders[folder].bundles[member];
    for (int i = 0; i < g_shell_app_count; i++)
        if (g_shell_apps[i].bundle[0] &&
            strcmp(g_shell_apps[i].bundle, bundle) == 0)
            return i;
    return -1;
}

/* True when this app is the tile that represents its folder on the grid. */
static int shell_folder_app_is_first(int index)
{
    int folder = shell_folder_for_app(index);
    if (folder < 0)
        return 0;
    for (int j = 0; j < index; j++)
        if (!g_shell_apps[j].dock && shell_folder_for_app(j) == folder)
            return 0;
    return 1;
}

static void shell_folders_path(char *out, unsigned long cap)
{
    const char *shared = getenv("SIMULATOR_SHARED_RESOURCES_DIRECTORY");
    out[0] = 0;
    if (!shared || !*shared)
        return;
    snprintf(out, cap, "%s/Library/SpringBoard/folders.txt", shared);
}

static void shell_folders_save(void)
{
    char path[1024];
    shell_folders_path(path, sizeof path);
    if (!path[0])
        return;
    int slash = -1;
    for (int i = 0; path[i]; i++)
        if (path[i] == '/')
            slash = i;
    if (slash > 0)
    {
        char dir[1024];
        memcpy(dir, path, (unsigned long)slash);
        dir[slash] = 0;
        iosim_fs_mkdir(dir, 1);
    }
    static char buf[8192];
    unsigned long o = 0;
    for (int f = 0; f < g_folder_count && o < sizeof(buf) - 2; f++)
    {
        o += (unsigned long)snprintf(buf + o, sizeof(buf) - o, "%s|",
                                     g_folders[f].name);
        for (int k = 0; k < g_folders[f].count && o < sizeof(buf) - 2; k++)
            o += (unsigned long)snprintf(buf + o, sizeof(buf) - o, "%s%s",
                                         k ? "," : "",
                                         g_folders[f].bundles[k]);
        if (o < sizeof(buf) - 1)
            buf[o++] = '\n';
    }
    iosim_fs_write(path, buf, o);
}

static void shell_folders_load(void)
{
    char path[1024];
    shell_folders_path(path, sizeof path);
    if (!path[0])
        return;
    unsigned char *bytes = 0;
    unsigned long len = 0;
    if (iosim_fs_read(path, &bytes, &len) != 0 || !bytes)
        return;
    char *text = (char *)bytes;
    unsigned long i = 0;
    while (i < len && g_folder_count < SHELL_MAX_FOLDERS)
    {
        unsigned long start = i;
        while (i < len && text[i] != '\n')
            i++;
        unsigned long end = i;
        if (i < len)
            i++;
        if (start >= end || text[start] == '#')
            continue;
        struct shell_folder *f = &g_folders[g_folder_count];
        f->count = 0;
        unsigned long bar = start;
        while (bar < end && text[bar] != '|')
            bar++;
        unsigned long nlen = bar - start;
        if (nlen > sizeof(f->name) - 1)
            nlen = sizeof(f->name) - 1;
        memcpy(f->name, text + start, nlen);
        f->name[nlen] = 0;
        if (!f->name[0])
            shell_copy(f->name, (int)sizeof(f->name), "Folder");
        unsigned long p = bar < end ? bar + 1 : end;
        while (p < end && f->count < SHELL_FOLDER_MAX_APPS)
        {
            unsigned long bs = p;
            while (p < end && text[p] != ',')
                p++;
            unsigned long be = p;
            if (p < end)
                p++;
            if (be <= bs)
                continue;
            unsigned long blen = be - bs;
            if (blen > sizeof(f->bundles[0]) - 1)
                blen = sizeof(f->bundles[0]) - 1;
            memcpy(f->bundles[f->count], text + bs, blen);
            f->bundles[f->count][blen] = 0;
            f->count++;
        }
        if (f->count > 0)
            g_folder_count++;
    }
    free(bytes);
}

/* Drop members whose bundle is no longer installed and folders that became
 * empty; the grid and the saved state both follow. */
static void shell_folders_prune(void)
{
    for (int f = 0; f < g_folder_count; f++)
    {
        int kept = 0;
        for (int k = 0; k < g_folders[f].count; k++)
        {
            int found = 0;
            for (int i = 0; i < g_shell_app_count; i++)
                if (g_shell_apps[i].bundle[0] &&
                    strcmp(g_shell_apps[i].bundle, g_folders[f].bundles[k]) ==
                        0)
                {
                    found = 1;
                    break;
                }
            if (!found)
                continue;
            if (kept != k)
                shell_copy(g_folders[f].bundles[kept],
                           (int)sizeof(g_folders[f].bundles[0]),
                           g_folders[f].bundles[k]);
            kept++;
        }
        g_folders[f].count = kept;
    }
    int out = 0;
    for (int f = 0; f < g_folder_count; f++)
    {
        if (g_folders[f].count <= 0)
            continue;
        if (out != f)
            g_folders[out] = g_folders[f];
        out++;
    }
    g_folder_count = out;
    if (g_open_folder >= g_folder_count)
        g_open_folder = -1;
    shell_folders_save();
}

static int shell_folder_create(int add_app, int into_folder, int other_app)
{
    int folder = into_folder;
    if (folder < 0)
    {
        if (g_folder_count >= SHELL_MAX_FOLDERS)
            return -1;
        folder = g_folder_count++;
        struct shell_folder *f = &g_folders[folder];
        f->count = 0;
        shell_copy(f->name, (int)sizeof(f->name), "Folder");
        const char *first = g_shell_apps[other_app].bundle;
        if (first[0])
            shell_copy(f->bundles[f->count++],
                       (int)sizeof(f->bundles[0]), first);
    }
    struct shell_folder *f = &g_folders[folder];
    const char *bundle = g_shell_apps[add_app].bundle;
    if (!bundle[0] || f->count >= SHELL_FOLDER_MAX_APPS)
        return folder;
    for (int k = 0; k < f->count; k++)
        if (strcmp(f->bundles[k], bundle) == 0)
            return folder;
    shell_copy(f->bundles[f->count++], (int)sizeof(f->bundles[0]), bundle);
    shell_folders_save();
    if (into_folder >= 0)
        printf("[SpringBoard] folder added %s (%d apps)\n",
               g_shell_apps[add_app].name, f->count);
    else
        printf("[SpringBoard] folder created name=%s (%d apps)\n", f->name,
               f->count);
    fflush(0);
    return folder;
}

static int shell_grid_entries(struct shell_grid_entry *out, int cap)
{
    int n = 0;
    for (int i = 0; i < g_shell_app_count && n < cap; i++)
    {
        struct shell_app *a = &g_shell_apps[i];
        if (a->dock)
            continue;
        int folder = shell_folder_for_app(i);
        if (folder >= 0)
        {
            if (!shell_folder_app_is_first(i))
                continue;
            if (out)
            {
                out[n].app = -1;
                out[n].folder = folder;
            }
        }
        else if (out)
        {
            out[n].app = i;
            out[n].folder = -1;
        }
        n++;
    }
    return n;
}

/* Which grid entry, if any, sits under a home-screen point. */
static int shell_grid_entry_at(double px, double py, double W, double scale,
                               int *out_app, int *out_folder)
{
    double pitch = (W - 2 * SHELL_MARGIN_PT - SHELL_ICON_PT) / 3.0;
    struct shell_grid_entry entries[SHELL_MAX_APPS + SHELL_MAX_FOLDERS];
    int count = shell_grid_entries(entries, SHELL_MAX_APPS + SHELL_MAX_FOLDERS);
    for (int e = 0; e < count; e++)
    {
        int page = e / 16;
        if (page != g_home_page)
            continue;
        int slot = e % 16;
        int col = slot % 4, row = slot / 4;
        double cx = SHELL_MARGIN_PT + SHELL_ICON_PT / 2 + col * pitch;
        double cy = shell_row_center[row];
        if (px >= cx - 34 && px < cx + 34 && py >= cy - 34 && py < cy + 50)
        {
            if (out_app)
                *out_app = entries[e].app;
            if (out_folder)
                *out_folder = entries[e].folder;
            return 1;
        }
    }
    (void)scale;
    return 0;
}

static void shell_label(const char *name, int cx, int baseline, double scale)
{
    int tw = iosim_fb_font_text_width(name, IOSIM_FONT_REGULAR, 12, scale);
    int x = cx - tw / 2;
    iosim_fb_font_text(x, baseline, name, IOSIM_FONT_REGULAR, 12, scale,
                       0xffffff);
}

static void shell_draw_badge(int cx, int cy, int count, double scale)
{
    char text[8];
    double size = count > 99 ? 10.0 : 12.0;
    if (count > 99)
        snprintf(text, sizeof(text), "99+");
    else
        snprintf(text, sizeof(text), "%d", count);
    iosim_fb_fill_circle(cx, cy, (int)(11 * scale + 0.5), 0xff3b30);
    int asc = 0, desc = 0, lh = 0;
    iosim_fb_font_metrics(IOSIM_FONT_SEMIBOLD, size, scale, &asc, &desc, &lh);
    int tw = iosim_fb_font_text_width(text, IOSIM_FONT_SEMIBOLD, size, scale);
    iosim_fb_font_text(cx - tw / 2, cy - lh / 2 + asc, text,
                       IOSIM_FONT_SEMIBOLD, size, scale, 0xffffff);
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

/* A folder tile: the glass backplate with up to four mini app icons. */
static void shell_folder_icon(int folder, int cx, int cy, int s, double scale)
{
    int x = cx - s / 2, y = cy - s / 2;
    int r = (int)(s * 0.2237 + 0.5);
    iosim_fb_fill_round_rect(x, y, s, s, r, 0x3a3a3c);
    struct shell_folder *f = &g_folders[folder];
    int mini = (int)(s * 0.34 + 0.5);
    int gap = (int)(s * 0.06 + 0.5);
    int startx = x + (s - (2 * mini + gap)) / 2;
    int starty = y + (s - (2 * mini + gap)) / 2;
    for (int k = 0; k < f->count && k < 4; k++)
    {
        int app = shell_folder_member_app(folder, k);
        int mx = startx + (k % 2) * (mini + gap);
        int my = starty + (k / 2) * (mini + gap);
        if (app >= 0)
            shell_stock_icon(g_shell_apps[app].stock, mx, my, mini, scale);
        else
            iosim_fb_fill_round_rect(mx, my, mini, mini,
                                     (int)(mini * 0.22 + 0.5), 0x55555a);
    }
}

static void shell_draw_folder(int fbWidth, int fbHeight, double scale,
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
    iosim_fb_set_opacity(0.58);
    iosim_fb_fill_rect(0, 0, fbWidth, fbHeight, 0x000000);
    iosim_fb_set_opacity(1.0);

    double W = fbWidth / scale;
    if (g_open_folder >= 0 && g_open_folder < g_folder_count)
    {
        int tw = iosim_fb_font_text_width(g_folders[g_open_folder].name,
                                          IOSIM_FONT_SEMIBOLD, 22, scale);
        iosim_fb_font_text((fbWidth - tw) / 2, (int)(92 * scale),
                           g_folders[g_open_folder].name,
                           IOSIM_FONT_SEMIBOLD, 22, scale, 0xffffff);
        iosim_fb_set_opacity(0.90);
        iosim_fb_fill_round_rect((int)(24 * scale), (int)(120 * scale),
                                 (int)((W - 48) * scale),
                                 (int)(332 * scale), (int)(36 * scale),
                                 0x1c1c1e);
        iosim_fb_set_opacity(1.0);
        double cellW = (W - 48) / 4.0;
        int iconSize = (int)(56 * scale + 0.5);
        for (int k = 0; k < g_folders[g_open_folder].count &&
                        k < SHELL_FOLDER_MAX_APPS;
             k++)
        {
            int app = shell_folder_member_app(g_open_folder, k);
            if (app < 0)
                continue;
            int col = k % 4, row = k / 4;
            int cx = (int)((24 + cellW * (col + 0.5)) * scale + 0.5);
            int cy = (int)((190 + row * 96) * scale + 0.5);
            shell_stock_icon(g_shell_apps[app].stock, cx - iconSize / 2,
                             cy - iconSize / 2, iconSize, scale);
            shell_label(g_shell_apps[app].name, cx,
                        cy + iconSize / 2 + (int)(16.1 * scale + 0.5),
                        scale);
        }
    }
    draw_device_chrome(fbWidth, scale);
    if (path && *path)
        iosim_fb_present(path);
}

/* Member row under a point in the open folder overlay, or -1. */
static int shell_folder_member_at(double px, double py, double W)
{
    if (g_open_folder < 0 || g_open_folder >= g_folder_count)
        return -1;
    double cellW = (W - 48) / 4.0;
    for (int k = 0; k < g_folders[g_open_folder].count; k++)
    {
        int col = k % 4, row = k / 4;
        double cx = 24 + cellW * (col + 0.5);
        double cy = 190 + row * 96;
        if (px >= cx - 32 && px < cx + 32 && py >= cy - 32 && py < cy + 44)
            return k;
    }
    return -1;
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
    struct shell_grid_entry entries[SHELL_MAX_APPS + SHELL_MAX_FOLDERS];
    int entry_count =
        shell_grid_entries(entries, SHELL_MAX_APPS + SHELL_MAX_FOLDERS);
    for (int e = 0; e < entry_count; e++)
    {
        int page = e / 16;
        int page_slot = e % 16;
        if (page != g_home_page)
            continue;
        int col = page_slot % 4, row = page_slot / 4;
        int cx = (int)((SHELL_MARGIN_PT + SHELL_ICON_PT / 2 + col * pitch) *
                       scale + 0.5);
        int cy = (int)(shell_row_center[row] * scale + 0.5);
        int baseline = cy + s / 2 + (int)(16.1 * scale + 0.5);
        if (entries[e].folder >= 0)
        {
            shell_folder_icon(entries[e].folder, cx, cy, s, scale);
            shell_label(g_folders[entries[e].folder].name, cx, baseline,
                        scale);
        }
        else
        {
            struct shell_app *a = &g_shell_apps[entries[e].app];
            shell_stock_icon(a->stock, cx - s / 2, cy - s / 2, s, scale);
            if (a->badge > 0)
                shell_draw_badge(cx + s / 2 - (int)(4 * scale + 0.5),
                                 cy - s / 2 + (int)(4 * scale + 0.5),
                                 a->badge, scale);
            shell_label(a->name, cx, baseline, scale);
        }
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
    if (ui_style_current() == 1)
    {
        /* The glass darkens with the device appearance. */
        iosim_fb_set_opacity(0.55);
        iosim_fb_fill_round_rect(dx, dy, dw, dh, dr, 0x1c1c1e);
        iosim_fb_set_opacity(1.0);
    }
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
    int dark_style = ui_style_current() == 1;
    if (dark_style)
    {
        iosim_fb_set_opacity(0.82);
        iosim_fb_fill_round_rect(sx, sy, sw, sh, sr, 0x1c1c1e);
        iosim_fb_set_opacity(1.0);
    }
    unsigned glyph = dark_style ? 0xaeaeb2 : 0xd6d3de;
    unsigned placeholder = dark_style ? 0xe5e5ea : 0xd8d5e0;
    int mx = sx + (int)(12 * scale), my = sy + sh / 2;
    iosim_fb_stroke_circle(mx, my, (int)(4.5 * scale),
                           (int)(1.4 * scale + 0.5), glyph);
    iosim_fb_draw_line(mx + (int)(3 * scale), my + (int)(3 * scale),
                       mx + (int)(6 * scale), my + (int)(6 * scale),
                       (int)(1.4 * scale + 0.5), glyph);
    int swidth = iosim_fb_font_text_width("Search", IOSIM_FONT_REGULAR, 13,
                                          scale);
    iosim_fb_font_text(sx + (sw - swidth) / 2 + (int)(7 * scale),
                       my + (int)(5 * scale), "Search", IOSIM_FONT_REGULAR,
                       13, scale, placeholder);

    draw_device_chrome(fbWidth, scale);
}

/* --------------------------------------------------- system notifications
 *
 * UserNotifications writes one request file per scheduled notification into
 * the shared device data. While SpringBoard owns the screen it scans that
 * directory, presents due requests as banners, keeps them in Notification
 * Center, and hands a tapped notification back to its app through a response
 * file that the app's UNUserNotificationCenter polls. */

#define SB_NOTIFICATION_MAX 16

struct sb_notification {
    char bundle[128];
    char identifier[128];
    char title[512];
    char subtitle[512];
    char body[2048];
    char category[128];
    char badge[64];
    double fire;
    double interval;
    int repeats;
};

static struct sb_notification g_sb_delivered[SB_NOTIFICATION_MAX];
static double g_sb_delivered_time[SB_NOTIFICATION_MAX];
static int g_sb_delivered_count;
static struct sb_notification g_sb_banner;
static int g_sb_banner_active;
static double g_sb_banner_start;
static int g_notification_center;
static double g_sb_last_notification_scan;
static unsigned *g_sb_nc_backdrop;
static int g_sb_nc_backdrop_w, g_sb_nc_backdrop_h;

static void share_text_ellipsis(const char *text, int style, double size,
                                double scale, int maxWidth, char *out,
                                unsigned long outSize);
static void shell_launch(int index, int fbWidth, int fbHeight, double scale,
                         const char *path);
static void shell_refresh_all(int fbWidth, int fbHeight, double scale,
                              const char *path);

static int shell_shared_dir(char *out, unsigned long cap)
{
    const char *shared = getenv("SIMULATOR_SHARED_RESOURCES_DIRECTORY");
    if (!shared || !*shared)
    {
        out[0] = 0;
        return 0;
    }
    snprintf(out, cap, "%s", shared);
    return 1;
}

static int shell_notifications_dir(char *out, unsigned long cap)
{
    char shared[900];
    if (!shell_shared_dir(shared, sizeof(shared)))
    {
        out[0] = 0;
        return 0;
    }
    snprintf(out, cap, "%s/Library/SpringBoard/notifications", shared);
    return 1;
}

static void sb_unescape(const char *in, char *out, unsigned long cap)
{
    unsigned long o = 0;
    while (*in && o + 1 < cap)
    {
        if (in[0] == '\\' && in[1] == 'n')
        {
            out[o++] = '\n';
            in += 2;
        }
        else if (in[0] == '\\' && in[1] == 'r')
        {
            out[o++] = '\r';
            in += 2;
        }
        else if (in[0] == '\\' && in[1] == '\\')
        {
            out[o++] = '\\';
            in += 2;
        }
        else
            out[o++] = *in++;
    }
    out[o] = 0;
}

static void sb_escape(const char *in, char *out, unsigned long cap)
{
    unsigned long o = 0;
    if (!in)
        in = "";
    for (; *in && o + 3 < cap; in++)
    {
        if (*in == '\n')
        {
            out[o++] = '\\';
            out[o++] = 'n';
        }
        else if (*in == '\r')
        {
            out[o++] = '\\';
            out[o++] = 'r';
        }
        else if (*in == '\\')
        {
            out[o++] = '\\';
            out[o++] = '\\';
        }
        else
            out[o++] = *in;
    }
    out[o] = 0;
}

/* Matches "key=" at the start of a line and unescapes its value. */
static int sb_field(const char *line, unsigned long len, const char *key,
                    char *out, unsigned long cap)
{
    unsigned long k = strlen(key);
    if (len < k || strncmp(line, key, k) != 0)
        return 0;
    char tmp[2200];
    unsigned long n = len - k;
    if (n >= sizeof(tmp))
        n = sizeof(tmp) - 1;
    memcpy(tmp, line + k, n);
    tmp[n] = 0;
    sb_unescape(tmp, out, cap);
    return 1;
}

static int sb_parse_notification(const char *buf, struct sb_notification *out)
{
    memset(out, 0, sizeof(*out));
    int fields = 0;
    const char *p = buf;
    while (*p)
    {
        const char *line = p;
        while (*p && *p != '\n')
            p++;
        unsigned long len = (unsigned long)(p - line);
        if (sb_field(line, len, "bundle=", out->bundle,
                     sizeof(out->bundle)))
            fields++;
        else if (sb_field(line, len, "id=", out->identifier,
                          sizeof(out->identifier)))
            fields++;
        else if (sb_field(line, len, "title=", out->title,
                          sizeof(out->title)))
            fields++;
        else if (sb_field(line, len, "subtitle=", out->subtitle,
                          sizeof(out->subtitle)))
            fields++;
        else if (sb_field(line, len, "body=", out->body, sizeof(out->body)))
            fields++;
        else if (sb_field(line, len, "category=", out->category,
                          sizeof(out->category)))
            fields++;
        else if (sb_field(line, len, "badge=", out->badge,
                          sizeof(out->badge)))
            fields++;
        else if (len > 5 && strncmp(line, "fire=", 5) == 0)
        {
            char tmp[64];
            unsigned long n = len - 5;
            if (n >= sizeof(tmp))
                n = sizeof(tmp) - 1;
            memcpy(tmp, line + 5, n);
            tmp[n] = 0;
            out->fire = atof(tmp);
        }
        else if (len > 8 && strncmp(line, "repeats=", 8) == 0)
            out->repeats = atoi(line + 8);
        else if (len > 9 && strncmp(line, "interval=", 9) == 0)
            out->interval = atof(line + 9);
        if (*p)
            p++;
    }
    return fields >= 2;
}

static int sb_read_notification(const char *path, struct sb_notification *out)
{
    unsigned char *bytes = 0;
    unsigned long length = 0;
    if (iosim_fs_read(path, &bytes, &length) != 0 || !bytes)
        return 0;
    char buf[4200];
    if (length >= sizeof(buf))
        length = sizeof(buf) - 1;
    memcpy(buf, bytes, length);
    buf[length] = 0;
    free(bytes);
    return sb_parse_notification(buf, out);
}

/* Category definitions registered by an app, reloaded from the shared file
 * so an expanded banner can offer its action buttons. */
#define SB_ACTION_MAX 6
#define SB_CATEGORY_MAX 12

struct sb_action {
    char identifier[128];
    char title[128];
    unsigned long options;
};

struct sb_category {
    char identifier[128];
    int action_count;
    struct sb_action actions[SB_ACTION_MAX];
};

static struct sb_category g_sb_categories[SB_CATEGORY_MAX];
static int g_sb_category_count;
static int g_sb_banner_expanded;
static int g_sb_nc_expanded;

static void sb_unescape_pipe(const char *in, char *out, unsigned long cap)
{
    unsigned long o = 0;
    while (*in && o + 1 < cap)
    {
        if (in[0] == '\\' && in[1] == 'n')
        {
            out[o++] = '\n';
            in += 2;
        }
        else if (in[0] == '\\' && in[1] == 'r')
        {
            out[o++] = '\r';
            in += 2;
        }
        else if (in[0] == '\\' && in[1] == 'p')
        {
            out[o++] = '|';
            in += 2;
        }
        else if (in[0] == '\\' && in[1] == '\\')
        {
            out[o++] = '\\';
            in += 2;
        }
        else
            out[o++] = *in++;
    }
    out[o] = 0;
}

static void shell_notification_categories_load(void)
{
    g_sb_category_count = 0;
    char shared[900], path[1100];
    if (!shell_shared_dir(shared, sizeof(shared)))
        return;
    snprintf(path, sizeof(path), "%s/Library/SpringBoard/"
             "notification-categories.txt", shared);
    unsigned char *bytes = 0;
    unsigned long length = 0;
    if (iosim_fs_read(path, &bytes, &length) != 0 || !bytes)
        return;
    char buf[8000];
    if (length >= sizeof(buf))
        length = sizeof(buf) - 1;
    memcpy(buf, bytes, length);
    buf[length] = 0;
    free(bytes);
    const char *p = buf;
    int current = -1;
    while (*p)
    {
        const char *line = p;
        while (*p && *p != '\n')
            p++;
        unsigned long len = (unsigned long)(p - line);
        if (len > 9 && strncmp(line, "category=", 9) == 0)
        {
            current = -1;
            if (g_sb_category_count < SB_CATEGORY_MAX)
            {
                current = g_sb_category_count++;
                memset(&g_sb_categories[current], 0,
                       sizeof(g_sb_categories[current]));
                char tmp[300];
                unsigned long n = len - 9;
                if (n >= sizeof(tmp))
                    n = sizeof(tmp) - 1;
                memcpy(tmp, line + 9, n);
                tmp[n] = 0;
                sb_unescape_pipe(tmp, g_sb_categories[current].identifier,
                                 sizeof(g_sb_categories[current].identifier));
            }
        }
        else if (len > 7 && strncmp(line, "action=", 7) == 0 && current >= 0 &&
                 g_sb_categories[current].action_count < SB_ACTION_MAX)
        {
            char tmp[700];
            unsigned long n = len - 7;
            if (n >= sizeof(tmp))
                n = sizeof(tmp) - 1;
            memcpy(tmp, line + 7, n);
            tmp[n] = 0;
            char *parts[3] = {tmp, 0, 0};
            int part = 0;
            for (char *q = tmp; *q && part < 2; q++)
            {
                if (*q == '\\' && q[1])
                {
                    q++;
                    continue;
                }
                if (*q == '|')
                {
                    *q = 0;
                    parts[++part] = q + 1;
                }
            }
            if (part == 2)
            {
                struct sb_action *action =
                    &g_sb_categories[current]
                         .actions[g_sb_categories[current].action_count];
                sb_unescape_pipe(parts[0], action->identifier,
                                 sizeof(action->identifier));
                sb_unescape_pipe(parts[1], action->title,
                                 sizeof(action->title));
                action->options = (unsigned long)atoi(parts[2]);
                g_sb_categories[current].action_count++;
            }
        }
        if (*p)
            p++;
    }
}

static struct sb_category *shell_category_for(const char *identifier)
{
    if (!identifier || !*identifier)
        return 0;
    for (int i = 0; i < g_sb_category_count; i++)
        if (strcmp(g_sb_categories[i].identifier, identifier) == 0)
            return &g_sb_categories[i];
    return 0;
}

static int shell_app_index_for_bundle(const char *bundle);

/* Badge counts live in one shared line per bundle; the app's UIApplication
 * setter and the notification delivery path both write it, and the home
 * screen reads it back. */
static void shell_badges_path(char *out, unsigned long cap)
{
    char shared[900];
    if (!shell_shared_dir(shared, sizeof(shared)))
    {
        out[0] = 0;
        return;
    }
    snprintf(out, cap, "%s/Library/SpringBoard/badges.txt", shared);
}

static void shell_badges_load(void)
{
    for (int i = 0; i < g_shell_app_count; i++)
        g_shell_apps[i].badge = 0;
    char path[1100];
    shell_badges_path(path, sizeof(path));
    if (!path[0])
        return;
    unsigned char *bytes = 0;
    unsigned long length = 0;
    if (iosim_fs_read(path, &bytes, &length) != 0 || !bytes)
        return;
    char buf[4000];
    if (length >= sizeof(buf))
        length = sizeof(buf) - 1;
    memcpy(buf, bytes, length);
    buf[length] = 0;
    free(bytes);
    const char *p = buf;
    while (*p)
    {
        const char *line = p;
        while (*p && *p != '\n')
            p++;
        unsigned long len = (unsigned long)(p - line);
        unsigned long bar = 0;
        while (bar < len && line[bar] != '|')
            bar++;
        if (bar < len && bar < 200)
        {
            char bundle[200];
            memcpy(bundle, line, bar);
            bundle[bar] = 0;
            int count = atoi(line + bar + 1);
            int index = shell_app_index_for_bundle(bundle);
            if (index >= 0)
                g_shell_apps[index].badge = count;
        }
        if (*p)
            p++;
    }
}

static void shell_badge_store(const char *bundle, int count)
{
    if (!bundle || !*bundle)
        return;
    char path[1100];
    shell_badges_path(path, sizeof(path));
    if (!path[0])
        return;
    char out[4000];
    int n = 0;
    unsigned char *bytes = 0;
    unsigned long length = 0;
    if (iosim_fs_read(path, &bytes, &length) == 0 && bytes)
    {
        const char *p = (const char *)bytes;
        const char *end = p + length;
        while (p < end)
        {
            const char *line = p;
            while (p < end && *p != '\n')
                p++;
            unsigned long len = (unsigned long)(p - line);
            if (len > 0 && n < 3800)
            {
                unsigned long bar = 0;
                while (bar < len && line[bar] != '|')
                    bar++;
                int same = 0;
                if (bar < len && bar < 200)
                {
                    char held[200];
                    memcpy(held, line, bar);
                    held[bar] = 0;
                    same = strcmp(held, bundle) == 0;
                }
                if (!same)
                {
                    unsigned long copy = len < 300 ? len : 300;
                    memcpy(out + n, line, copy);
                    n += (int)copy;
                    out[n++] = '\n';
                }
            }
            if (p < end)
                p++;
        }
        free(bytes);
    }
    if (count > 0 && n < 3900)
        n += snprintf(out + n, sizeof(out) - (unsigned long)n, "%s|%d\n",
                      bundle, count);
    iosim_fs_write(path, out, (unsigned long)n);
    int index = shell_app_index_for_bundle(bundle);
    if (index >= 0)
        g_shell_apps[index].badge = count;
}

static void sb_write_notification(const char *path,
                                  struct sb_notification *n, double fire)
{
    char bundle[300], identifier[300], title[600], subtitle[600], body[2400];
    char category[300], badge[100];
    sb_escape(n->bundle, bundle, sizeof(bundle));
    sb_escape(n->identifier, identifier, sizeof(identifier));
    sb_escape(n->title, title, sizeof(title));
    sb_escape(n->subtitle, subtitle, sizeof(subtitle));
    sb_escape(n->body, body, sizeof(body));
    sb_escape(n->category, category, sizeof(category));
    sb_escape(n->badge, badge, sizeof(badge));
    char buf[4200];
    int len = snprintf(buf, sizeof(buf),
                       "bundle=%s\nid=%s\nfire=%.6f\nrepeats=%d\n"
                       "interval=%.6f\ntitle=%s\nsubtitle=%s\nbody=%s\n"
                       "category=%s\nbadge=%s\n",
                       bundle, identifier, fire, n->repeats, n->interval,
                       title, subtitle, body, category, badge);
    if (len > 0)
        iosim_fs_write(path, buf, (unsigned long)len);
}

static int shell_app_index_for_bundle(const char *bundle)
{
    if (!bundle || !*bundle)
        return -1;
    for (int i = 0; i < g_shell_app_count; i++)
        if (g_shell_apps[i].bundle[0] &&
            strcmp(g_shell_apps[i].bundle, bundle) == 0)
            return i;
    return -1;
}

static void shell_notification_app_name(struct sb_notification *n, char *out,
                                        unsigned long cap)
{
    int index = shell_app_index_for_bundle(n->bundle);
    if (index >= 0)
        snprintf(out, cap, "%s", g_shell_apps[index].name);
    else if (n->bundle[0])
        snprintf(out, cap, "%s", n->bundle);
    else
        snprintf(out, cap, "Notifications");
}

static int shell_notification_stock(struct sb_notification *n)
{
    int index = shell_app_index_for_bundle(n->bundle);
    return index >= 0 ? g_shell_apps[index].stock : -1;
}

static void shell_relative_time(double when, char *out, unsigned long cap)
{
    double delta = iosim_wall_time() - when;
    if (delta < 60.0)
        snprintf(out, cap, "now");
    else if (delta < 3600.0)
        snprintf(out, cap, "%dm", (int)(delta / 60.0));
    else if (delta < 86400.0)
        snprintf(out, cap, "%dh", (int)(delta / 3600.0));
    else
        snprintf(out, cap, "%dd", (int)(delta / 86400.0));
}

static void shell_date_string(char *out, unsigned long cap)
{
    static const char *week[] = {
        "Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday",
        "Saturday"
    };
    static const char *months[] = {
        "January", "February", "March", "April", "May", "June", "July",
        "August", "September", "October", "November", "December"
    };
    double now = iosim_wall_time();
    long long days = (long long)(now / 86400.0);
    long long z = days + 719468;
    long long era = (z >= 0 ? z : z - 146096) / 146097;
    unsigned long long doe = (unsigned long long)(z - era * 146097);
    unsigned long long yoe =
        (doe - doe / 1460 + doe / 36524 - doe / 146096) / 365;
    long long year = (long long)yoe + era * 400;
    unsigned long long doy = doe - (365 * yoe + yoe / 4 - yoe / 100);
    unsigned long long mp = (5 * doy + 2) / 153;
    unsigned long long day = doy - (153 * mp + 2) / 5 + 1;
    unsigned long long month = mp + (mp < 10 ? 3 : -9);
    year += (month <= 2);
    (void)year;
    int weekday = (int)((days + 4) % 7);
    if (weekday < 0)
        weekday += 7;
    snprintf(out, cap, "%s, %s %d", week[weekday], months[month - 1],
             (int)day);
}

static void shell_draw_notification_card(struct sb_notification *n,
                                         int px, int py, int pw, int ph,
                                         double scale, const char *when,
                                         int blur)
{
    if (blur)
    {
        unsigned *cap = malloc((unsigned long)pw * (unsigned long)ph *
                               sizeof(unsigned));
        if (cap)
        {
            iosim_fb_capture(px, py, pw, ph, cap);
            blur_box_xrgb(cap, pw, ph, (int)(16 * scale + 0.5), 2);
            iosim_fb_blit_xrgb_scaled(cap, pw, ph, px, py, pw, ph, 1.0);
            free(cap);
        }
    }
    int radius = (int)(24 * scale + 0.5);
    iosim_fb_set_opacity(0.30);
    iosim_fb_fill_round_rect(px + 2, py + 5, pw - 4, ph, radius, 0x000000);
    iosim_fb_set_opacity(1.0);
    iosim_fb_fill_round_rect(px, py, pw, ph, radius, 0x2a2a32);
    iosim_fb_fill_round_rect(px + 1, py + 1, pw - 2, ph - 2, radius - 1,
                             0x35353e);
    int iconSize = (int)(38 * scale + 0.5);
    int ix = px + (int)(14 * scale + 0.5);
    int iy = py + (int)(14 * scale + 0.5);
    int stock = shell_notification_stock(n);
    if (stock >= 0)
        shell_stock_icon(stock, ix, iy, iconSize, scale);
    else
        shell_placeholder_icon(ix, iy, iconSize, scale);
    int textX = ix + iconSize + (int)(12 * scale + 0.5);
    int maxText = px + pw - (int)(14 * scale + 0.5) - textX;
    char name[300], shown[600];
    shell_notification_app_name(n, name, sizeof(name));
    share_text_ellipsis(name, IOSIM_FONT_SEMIBOLD, 13, scale,
                        maxText - (int)(56 * scale + 0.5), shown,
                        sizeof(shown));
    iosim_fb_font_text(textX, py + (int)(28 * scale + 0.5), shown,
                       IOSIM_FONT_SEMIBOLD, 13, scale, 0xb9b9c0);
    int whenWidth =
        iosim_fb_font_text_width(when, IOSIM_FONT_REGULAR, 13, scale);
    iosim_fb_font_text(px + pw - (int)(14 * scale + 0.5) - whenWidth,
                       py + (int)(28 * scale + 0.5), when,
                       IOSIM_FONT_REGULAR, 13, scale, 0xb9b9c0);
    share_text_ellipsis(n->title, IOSIM_FONT_SEMIBOLD, 16, scale, maxText,
                        shown, sizeof(shown));
    iosim_fb_font_text(textX, py + (int)(51 * scale + 0.5), shown,
                       IOSIM_FONT_SEMIBOLD, 16, scale, 0xffffff);
    if (n->body[0])
    {
        share_text_ellipsis(n->body, IOSIM_FONT_REGULAR, 14, scale, maxText,
                            shown, sizeof(shown));
        iosim_fb_font_text(textX, py + (int)(73 * scale + 0.5), shown,
                           IOSIM_FONT_REGULAR, 14, scale, 0xdedee3);
    }
}

static int shell_notification_action_count(struct sb_notification *n)
{
    struct sb_category *category = shell_category_for(n->category);
    return category ? category->action_count : 0;
}

static void shell_banner_final_frame(int fbWidth, double scale, int *outX,
                                     int *outY, int *outW, int *outH)
{
    double W = fbWidth / scale;
    *outX = (int)(8 * scale + 0.5);
    *outY = (int)(58 * scale + 0.5);
    *outW = (int)((W - 16) * scale + 0.5);
    double base = g_sb_banner.body[0] ? 92.0 : 74.0;
    if (g_sb_banner_expanded)
        base += 44.0 * shell_notification_action_count(&g_sb_banner);
    *outH = (int)(base * scale + 0.5);
}

static int shell_banner_action_hit(double px, double py, int fbWidth,
                                   double scale)
{
    if (!g_sb_banner_active || !g_sb_banner_expanded)
        return -1;
    int bx, by, bw, bh;
    shell_banner_final_frame(fbWidth, scale, &bx, &by, &bw, &bh);
    if (px < bx / scale || px >= (bx + bw) / scale)
        return -1;
    int base = (int)((g_sb_banner.body[0] ? 92.0 : 74.0) * scale + 0.5);
    int y0 = by + base;
    if (py * scale < y0 || py * scale >= by + bh)
        return -1;
    int row = (int)((py * scale - y0) / (44 * scale));
    if (row < 0 || row >= shell_notification_action_count(&g_sb_banner))
        return -1;
    return row;
}

static void shell_draw_banner(int fbWidth, double scale)
{
    int x, y, w, h;
    shell_banner_final_frame(fbWidth, scale, &x, &y, &w, &h);
    double p = (iosim_now() - g_sb_banner_start) / 0.28;
    if (p < 0)
        p = 0;
    if (p > 1)
        p = 1;
    p = 1 - (1 - p) * (1 - p);
    int oy = y - (int)((1.0 - p) * (h + 20));
    shell_draw_notification_card(&g_sb_banner, x, oy, w, h, scale, "now",
                                 1);
    if (g_sb_banner_expanded)
    {
        struct sb_category *category = shell_category_for(g_sb_banner.category);
        if (!category)
            return;
        int base = (int)((g_sb_banner.body[0] ? 92.0 : 74.0) * scale + 0.5);
        int rowH = (int)(44 * scale + 0.5);
        for (int i = 0; i < category->action_count; i++)
        {
            int ry = oy + base + i * rowH;
            iosim_fb_fill_rect(x + (int)(16 * scale + 0.5), ry,
                               w - (int)(32 * scale + 0.5),
                               (int)(scale + 0.5), 0x4a4a52);
            int asc = 0, desc = 0, lh = 0;
            iosim_fb_font_metrics(IOSIM_FONT_SEMIBOLD, 16, scale, &asc,
                                  &desc, &lh);
            int tw = iosim_fb_font_text_width(category->actions[i].title,
                                              IOSIM_FONT_SEMIBOLD, 16, scale);
            unsigned color = (category->actions[i].options & 2)
                                 ? 0xff453a
                                 : 0x0a84ff;
            iosim_fb_font_text(x + (w - tw) / 2,
                               ry + rowH / 2 - lh / 2 + asc,
                               category->actions[i].title,
                               IOSIM_FONT_SEMIBOLD, 16, scale, color);
        }
    }
}

static void shell_build_nc_backdrop(int fbWidth, int fbHeight, double scale)
{
    free(g_sb_nc_backdrop);
    g_sb_nc_backdrop = malloc((unsigned long)fbWidth *
                              (unsigned long)fbHeight * sizeof(unsigned));
    if (!g_sb_nc_backdrop)
        return;
    iosim_fb_capture(0, 0, fbWidth, fbHeight, g_sb_nc_backdrop);
    blur_box_xrgb(g_sb_nc_backdrop, fbWidth, fbHeight,
                  (int)(26 * scale + 0.5), 2);
    g_sb_nc_backdrop_w = fbWidth;
    g_sb_nc_backdrop_h = fbHeight;
}

static int shell_notification_card_height(struct sb_notification *n)
{
    return n->body[0] ? 86 : 70;
}

static int shell_nc_card_top(int index, double scale)
{
    int y = (int)(198 * scale + 0.5);
    for (int i = 0; i < index && i < g_sb_delivered_count; i++)
        y += (int)(shell_notification_card_height(&g_sb_delivered[i]) *
                   scale + 0.5) +
             (int)(8 * scale + 0.5);
    return y;
}

static int shell_nc_action_sheet(int fbWidth, double scale, int *outX,
                                 int *outY, int *outW, int *outH,
                                 struct sb_category **outCategory)
{
    *outX = *outY = *outW = *outH = 0;
    if (outCategory)
        *outCategory = 0;
    if (g_sb_nc_expanded < 0 || g_sb_nc_expanded >= g_sb_delivered_count)
        return 0;
    struct sb_notification *n = &g_sb_delivered[g_sb_nc_expanded];
    struct sb_category *category = shell_category_for(n->category);
    if (!category || category->action_count <= 0)
        return 0;
    double W = fbWidth / scale;
    *outX = (int)(16 * scale + 0.5);
    *outY = shell_nc_card_top(g_sb_nc_expanded, scale) +
            (int)(shell_notification_card_height(n) * scale + 0.5) +
            (int)(8 * scale + 0.5);
    *outW = (int)((W - 32) * scale + 0.5);
    *outH = (int)(44.0 * category->action_count * scale + 0.5);
    if (outCategory)
        *outCategory = category;
    return 1;
}

static int shell_nc_action_hit(double px, double py, int fbWidth,
                               double scale)
{
    int x, y, w, h;
    struct sb_category *category = 0;
    if (!shell_nc_action_sheet(fbWidth, scale, &x, &y, &w, &h, &category))
        return -1;
    if (px < x / scale || px >= (x + w) / scale || py * scale < y ||
        py * scale >= y + h)
        return -1;
    int row = (int)((py * scale - y) / (44 * scale));
    return row >= 0 && row < category->action_count ? row : -1;
}

static void shell_draw_nc_actions(int fbWidth, double scale)
{
    int x, y, w, h;
    struct sb_category *category = 0;
    if (!shell_nc_action_sheet(fbWidth, scale, &x, &y, &w, &h, &category))
        return;
    iosim_fb_set_opacity(0.30);
    iosim_fb_fill_round_rect(x + 2, y + 5, w - 4, h,
                             (int)(20 * scale + 0.5), 0x000000);
    iosim_fb_set_opacity(1.0);
    iosim_fb_fill_round_rect(x, y, w, h, (int)(20 * scale + 0.5), 0x2a2a32);
    iosim_fb_fill_round_rect(x + 1, y + 1, w - 2, h - 2,
                             (int)(19 * scale + 0.5), 0x35353e);
    int rowH = (int)(44 * scale + 0.5);
    for (int i = 0; i < category->action_count; i++)
    {
        int ry = y + i * rowH;
        if (i > 0)
            iosim_fb_fill_rect(x + (int)(16 * scale + 0.5), ry,
                               w - (int)(32 * scale + 0.5),
                               (int)(scale + 0.5), 0x4a4a52);
        int asc = 0, desc = 0, lh = 0;
        iosim_fb_font_metrics(IOSIM_FONT_SEMIBOLD, 16, scale, &asc, &desc,
                              &lh);
        int tw = iosim_fb_font_text_width(category->actions[i].title,
                                          IOSIM_FONT_SEMIBOLD, 16, scale);
        unsigned color =
            (category->actions[i].options & 2) ? 0xff453a : 0x0a84ff;
        iosim_fb_font_text(x + (w - tw) / 2, ry + rowH / 2 - lh / 2 + asc,
                           category->actions[i].title,
                           IOSIM_FONT_SEMIBOLD, 16, scale, color);
    }
}

static void shell_draw_notification_center(int fbWidth, int fbHeight,
                                           double scale)
{
    double W = fbWidth / scale;
    if (g_sb_nc_backdrop && g_sb_nc_backdrop_w == fbWidth &&
        g_sb_nc_backdrop_h == fbHeight)
        iosim_fb_paste_xrgb(g_sb_nc_backdrop);
    else
        iosim_fb_clear(0x11131a);
    iosim_fb_set_opacity(0.42);
    iosim_fb_fill_rect(0, 0, fbWidth, fbHeight, 0x000000);
    iosim_fb_set_opacity(1.0);

    const char *timeText = getenv("IOSIM_STATUS_TIME");
    if (!timeText || !*timeText)
        timeText = "9:41";
    int timeWidth =
        iosim_fb_font_text_width(timeText, IOSIM_FONT_SEMIBOLD, 62, scale);
    iosim_fb_font_text((int)(24 * scale + 0.5), (int)(122 * scale + 0.5),
                       timeText, IOSIM_FONT_SEMIBOLD, 62, scale, 0xffffff);
    (void)timeWidth;
    char date[128];
    shell_date_string(date, sizeof(date));
    iosim_fb_font_text((int)(26 * scale + 0.5), (int)(162 * scale + 0.5),
                       date, IOSIM_FONT_REGULAR, 17, scale, 0xd5d5dc);

    int y = (int)(198 * scale + 0.5);
    if (g_sb_delivered_count == 0)
    {
        const char *none = "No Notifications";
        int tw = iosim_fb_font_text_width(none, IOSIM_FONT_SEMIBOLD, 17,
                                          scale);
        iosim_fb_font_text((fbWidth - tw) / 2, (int)(300 * scale + 0.5),
                           none, IOSIM_FONT_SEMIBOLD, 17, scale, 0x8f8f99);
    }
    for (int i = 0; i < g_sb_delivered_count && i < 6; i++)
    {
        int ch = (int)(shell_notification_card_height(&g_sb_delivered[i]) *
                       scale + 0.5);
        char when[32];
        shell_relative_time(g_sb_delivered_time[i], when, sizeof(when));
        shell_draw_notification_card(&g_sb_delivered[i],
                                     (int)(16 * scale + 0.5), y,
                                     (int)((W - 32) * scale + 0.5), ch,
                                     scale, when, 0);
        y += ch + (int)(8 * scale + 0.5);
    }
    shell_draw_nc_actions(fbWidth, scale);
    g_sb_overlay_guard = 1;
    draw_device_chrome(fbWidth, scale);
    g_sb_overlay_guard = 0;
}

static void shell_open_notification_center(int fbWidth, int fbHeight,
                                           double scale, const char *path)
{
    if (g_notification_center)
        return;
    g_notification_center = 1;
    g_sb_banner_active = 0;
    g_sb_banner_expanded = 0;
    g_sb_nc_expanded = -1;
    shell_build_nc_backdrop(fbWidth, fbHeight, scale);
    printf("[SpringBoard] notification center opened\n");
    fflush(0);
    shell_draw_notification_center(fbWidth, fbHeight, scale);
    if (path && *path)
        iosim_fb_present(path);
}

static void shell_close_notification_center(int fbWidth, int fbHeight,
                                            double scale, const char *path)
{
    (void)fbWidth;
    (void)fbHeight;
    (void)scale;
    (void)path;
    if (!g_notification_center)
        return;
    g_notification_center = 0;
    g_sb_nc_expanded = -1;
    printf("[SpringBoard] notification center closed\n");
    fflush(0);
}

static int shell_notification_center_hit(double px, double py, int fbWidth,
                                         double scale)
{
    double W = fbWidth / scale;
    int y = 198;
    if (px < 16.0 || px > W - 16.0)
        return -1;
    for (int i = 0; i < g_sb_delivered_count && i < 6; i++)
    {
        int ch = shell_notification_card_height(&g_sb_delivered[i]);
        if (py >= y && py < y + ch)
            return i;
        y += ch + 8;
    }
    return -1;
}

static int shell_lock_notification_hit(double px, double py, int fbWidth,
                                       double scale)
{
    double W = fbWidth / scale;
    int y = 470;
    if (px < 16.0 || px > W - 16.0)
        return -1;
    for (int i = 0; i < g_sb_delivered_count && i < 3; i++)
    {
        int ch = shell_notification_card_height(&g_sb_delivered[i]);
        if (py >= y && py < y + ch)
            return i;
        y += ch + 8;
    }
    return -1;
}

static void shell_write_notification_response(struct sb_notification *n,
                                              const char *action)
{
    char shared[900];
    if (!shell_shared_dir(shared, sizeof(shared)))
        return;
    char dir[1000];
    snprintf(dir, sizeof(dir), "%s/Library/SpringBoard", shared);
    iosim_fs_mkdir(dir, 1);
    char path[1100];
    snprintf(path, sizeof(path), "%s/notification-response.txt", dir);
    char bundle[300], identifier[300], title[600], body[2400], act[128];
    sb_escape(n->bundle, bundle, sizeof(bundle));
    sb_escape(n->identifier, identifier, sizeof(identifier));
    sb_escape(n->title, title, sizeof(title));
    sb_escape(n->body, body, sizeof(body));
    sb_escape(action, act, sizeof(act));
    char buf[4200];
    int len = snprintf(buf, sizeof(buf),
                       "bundle=%s\nid=%s\naction=%s\ntitle=%s\nbody=%s\n",
                       bundle, identifier, act, title, body);
    if (len > 0)
        iosim_fs_write(path, buf, (unsigned long)len);
}

static void shell_forget_delivered(struct sb_notification *n)
{
    for (int i = 0; i < g_sb_delivered_count; i++)
    {
        if (strcmp(g_sb_delivered[i].bundle, n->bundle) == 0 &&
            strcmp(g_sb_delivered[i].identifier, n->identifier) == 0)
        {
            for (int j = i; j + 1 < g_sb_delivered_count; j++)
            {
                g_sb_delivered[j] = g_sb_delivered[j + 1];
                g_sb_delivered_time[j] = g_sb_delivered_time[j + 1];
            }
            g_sb_delivered_count--;
            return;
        }
    }
}

static void shell_open_notification(struct sb_notification *n, int fbWidth,
                                    int fbHeight, double scale,
                                    const char *path)
{
    shell_write_notification_response(n,
        "com.apple.UNNotificationDefaultActionIdentifier");
    printf("[SpringBoard] notification opened %s (%s)\n", n->title,
           n->bundle);
    fflush(0);
    g_sb_banner_active = 0;
    g_sb_banner_expanded = 0;
    g_notification_center = 0;
    g_sb_nc_expanded = -1;
    shell_forget_delivered(n);
    int index = shell_app_index_for_bundle(n->bundle);
    if (index >= 0)
    {
        shell_launch(index, fbWidth, fbHeight, scale, path);
        return;
    }
    printf("[SpringBoard] notification app not installed (%s)\n", n->bundle);
    fflush(0);
    shell_refresh_all(fbWidth, fbHeight, scale, path);
}

static void shell_open_notification_action(struct sb_notification *n,
                                           const char *action, int fbWidth,
                                           int fbHeight, double scale,
                                           const char *path)
{
    shell_write_notification_response(n, action);
    printf("[SpringBoard] notification action %s (%s)\n", action, n->title);
    fflush(0);
    g_sb_banner_active = 0;
    g_sb_banner_expanded = 0;
    g_notification_center = 0;
    g_sb_nc_expanded = -1;
    shell_forget_delivered(n);
    int index = shell_app_index_for_bundle(n->bundle);
    if (index >= 0)
    {
        shell_launch(index, fbWidth, fbHeight, scale, path);
        return;
    }
    shell_refresh_all(fbWidth, fbHeight, scale, path);
}

static void shell_add_delivered(struct sb_notification *n, double when)
{
    if (g_sb_delivered_count >= SB_NOTIFICATION_MAX)
        g_sb_delivered_count = SB_NOTIFICATION_MAX - 1;
    for (int i = g_sb_delivered_count; i > 0; i--)
    {
        g_sb_delivered[i] = g_sb_delivered[i - 1];
        g_sb_delivered_time[i] = g_sb_delivered_time[i - 1];
    }
    g_sb_delivered[0] = *n;
    g_sb_delivered_time[0] = when;
    g_sb_delivered_count++;
}

/* Scans the shared schedule; returns 1 when a banner or list changed. */
static int shell_notification_tick(int fbWidth, int fbHeight, double scale,
                                   const char *path)
{
    (void)fbWidth;
    (void)fbHeight;
    (void)scale;
    (void)path;
    int redraw = 0;
    double now = iosim_now();
    if (g_sb_banner_active && now - g_sb_banner_start >= 5.0)
    {
        g_sb_banner_active = 0;
        redraw = 1;
    }
    /* The shell otherwise draws only in response to events, so drive the
     * banner's slide-in from the tick. A full redraw takes tens of
     * milliseconds, which paces the animation at a handful of frames. */
    if (g_sb_banner_active && now - g_sb_banner_start < 0.5)
        redraw = 1;
    if (now - g_sb_last_notification_scan < 0.20)
        return redraw;
    g_sb_last_notification_scan = now;
    shell_notification_categories_load();
    char dir[900];
    if (!shell_notifications_dir(dir, sizeof(dir)))
        return redraw;
    char list[4096];
    int count = iosim_fs_list(dir, list, sizeof(list));
    if (count <= 0)
        return redraw;
    const char *p = list;
    while (*p)
    {
        char name[256];
        unsigned long len = 0;
        while (p[len] && p[len] != '\n' && len + 1 < sizeof(name))
        {
            name[len] = p[len];
            len++;
        }
        name[len] = 0;
        while (*p && *p != '\n')
            p++;
        if (*p)
            p++;
        if (len < 6 || strcmp(name + len - 6, ".notif") != 0)
            continue;
        char file[1100];
        snprintf(file, sizeof(file), "%s/%s", dir, name);
        struct sb_notification n;
        if (!sb_read_notification(file, &n))
            continue;
        double wall = iosim_wall_time();
        if (n.fire > wall)
            continue;
        if (n.repeats && n.interval > 0.05)
        {
            n.fire = wall + n.interval;
            sb_write_notification(file, &n, n.fire);
        }
        else
            iosim_fs_remove(file);
        if (n.badge[0])
            shell_badge_store(n.bundle, atoi(n.badge));
        shell_add_delivered(&n, wall);
        if (!g_notification_center && !g_sb_banner_active)
        {
            g_sb_banner = n;
            g_sb_banner_active = 1;
            g_sb_banner_start = now;
            printf("[SpringBoard] notification banner %s (%s)\n", n.title,
                   n.bundle);
            fflush(0);
        }
        else if (g_notification_center)
        {
            printf("[SpringBoard] notification listed %s (%s)\n", n.title,
                   n.bundle);
            fflush(0);
        }
        redraw = 1;
        break;
    }
    return redraw;
}

static void shell_draw_notification_overlays(int fbWidth, double scale)
{
    if (g_notification_center)
    {
        shell_draw_notification_center(fbWidth, iosim_fb_height(), scale);
        return;
    }
    if (g_sb_banner_active)
        shell_draw_banner(fbWidth, scale);
}

static int g_switcher;
static int g_switcher_index;
static volatile int g_switcher_requested;
static int g_sb_down;
static double g_sb_down_x, g_sb_down_y;
/* A home-screen icon drag starts only after the finger rests long enough for
 * the long press; a quick swipe that happens to start on an icon still pages. */
static double g_sb_down_time;
static int g_sb_moved;
static int g_sb_icon_hold;
#define SHELL_ICON_HOLD_SECONDS 0.30
static int g_search;
static char g_search_query[64];
static UITextField *g_search_field;
static int g_control_center;
/* Lock screen state. g_lock_requested is set by SIGUSR2 from a foreground
 * app that received a lock event and stopped itself; SpringBoard then shows
 * the lock screen instead of the home screen. */
static int g_locked;
static volatile int g_lock_requested;
static int g_lock_resume_app = -1;
static int g_fg_app = -1;
/* airplane, cellular, wifi, bluetooth */
static int g_cc_toggles[4] = {0, 1, 1, 0};
static double g_cc_brightness = 0.62;
static double g_cc_volume = 0.45;

static void shell_repaint(int fbWidth, int fbHeight, double scale,
                          const char *path, int switcher);

static void shell_switcher_requested(void)
{
    g_switcher_requested = 1;
}

static void shell_lock_requested(void)
{
    g_lock_requested = 1;
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

/* ------------------------------------------------------- Control Center */

static void shell_cc_arc(int cx, int cy, int radius, double a0, double a1,
                         int thickness, unsigned color)
{
    double lx = 0, ly = 0;
    for (int i = 0; i <= 24; i++)
    {
        double a = a0 + (a1 - a0) * i / 24.0;
        double px = cx + radius * __builtin_cos(a);
        double py = cy + radius * __builtin_sin(a);
        if (i)
            iosim_fb_draw_line((int)lx, (int)ly, (int)px, (int)py, thickness,
                               color);
        lx = px;
        ly = py;
    }
}

static void shell_cc_airplane_icon(int cx, int cy, double scale,
                                   unsigned color)
{
    static const double xs[16] = {
        0, -2, -12, -12, -3, -2, -5, -5, 0, 5, 5, 2, 3, 12, 12, 2
    };
    static const double ys[16] = {
        -13, -6, -1, 2, 4, 7, 10, 12, 10, 12, 10, 7, 4, 2, -1, -6
    };
    double px[16], py[16];
    for (int i = 0; i < 16; i++)
    {
        px[i] = cx + xs[i] * scale;
        py[i] = cy + ys[i] * scale;
    }
    iosim_fb_fill_polygon(px, py, 16, color);
}

static void shell_cc_cellular_icon(int cx, int cy, double scale,
                                   unsigned color)
{
    int barW = (int)(4 * scale + 0.5);
    int gap = (int)(2 * scale + 0.5);
    int base = cy + (int)(11 * scale + 0.5);
    int start = cx - (4 * barW + 3 * gap) / 2;
    for (int i = 0; i < 4; i++)
    {
        int h = (int)((5 + i * 4) * scale + 0.5);
        iosim_fb_fill_rect(start + i * (barW + gap), base - h, barW, h,
                           color);
    }
}

static void shell_cc_wifi_icon(int cx, int cy, double scale, unsigned color)
{
    int t = (int)(2.2 * scale + 0.5);
    if (t < 1)
        t = 1;
    int by = cy + (int)(9 * scale + 0.5);
    iosim_fb_fill_circle(cx, by, (int)(2.4 * scale), color);
    shell_cc_arc(cx, by, (int)(8 * scale), -2.75, -0.39, t, color);
    shell_cc_arc(cx, by, (int)(14 * scale), -2.75, -0.39, t, color);
    shell_cc_arc(cx, by, (int)(20 * scale), -2.75, -0.39, t, color);
}

static void shell_cc_bluetooth_icon(int cx, int cy, double scale,
                                    unsigned color)
{
    int t = (int)(2 * scale + 0.5);
    if (t < 1)
        t = 1;
    int w = (int)(6 * scale + 0.5);
    int top = cy - (int)(12 * scale + 0.5);
    int bottom = cy + (int)(12 * scale + 0.5);
    int h = (int)(10 * scale + 0.5);
    int h4 = (int)(4 * scale + 0.5);
    int h2 = (int)(2 * scale + 0.5);
    iosim_fb_draw_line(cx, top, cx, bottom, t, color);
    iosim_fb_draw_line(cx - w, cy - h, cx + w, cy - h4, t, color);
    iosim_fb_draw_line(cx + w, cy - h4, cx - w, cy + h2, t, color);
    iosim_fb_draw_line(cx - w, cy - h2, cx + w, cy + h4, t, color);
    iosim_fb_draw_line(cx + w, cy + h4, cx - w, cy + h, t, color);
}

static void shell_cc_sun_icon(int cx, int cy, double scale, unsigned color)
{
    int t = (int)(2 * scale + 0.5);
    if (t < 1)
        t = 1;
    iosim_fb_stroke_circle(cx, cy, (int)(6 * scale + 0.5), t, color);
    for (int i = 0; i < 8; i++)
    {
        double a = i * 0.7853981634;
        int r0 = (int)(10 * scale), r1 = (int)(14 * scale);
        iosim_fb_draw_line(cx + (int)(__builtin_cos(a) * r0),
                           cy + (int)(__builtin_sin(a) * r0),
                           cx + (int)(__builtin_cos(a) * r1),
                           cy + (int)(__builtin_sin(a) * r1), t, color);
    }
}

static void shell_cc_speaker_icon(int cx, int cy, double scale,
                                  unsigned color)
{
    double xs[5] = {-10, -4, 1, 1, -4};
    double ys[5] = {2, 2, -5, 9, 2};
    double px[5], py[5];
    for (int i = 0; i < 5; i++)
    {
        px[i] = cx + xs[i] * scale;
        py[i] = cy + ys[i] * scale;
    }
    iosim_fb_fill_polygon(px, py, 5, color);
    int t = (int)(2 * scale + 0.5);
    if (t < 1)
        t = 1;
    shell_cc_arc(cx + (int)(1 * scale), cy + (int)(2 * scale),
                 (int)(6 * scale), -0.8, 0.8, t, color);
    shell_cc_arc(cx + (int)(1 * scale), cy + (int)(2 * scale),
                 (int)(11 * scale), -0.8, 0.8, t, color);
}

static void shell_cc_toggle_center(int index, double *outX, double *outY)
{
    static const double xs[4] = {60, 148, 60, 148};
    static const double ys[4] = {148, 148, 232, 232};
    *outX = xs[index];
    *outY = ys[index];
}

static int shell_cc_toggle_at(double px, double py)
{
    for (int i = 0; i < 4; i++)
    {
        double cx, cy;
        shell_cc_toggle_center(i, &cx, &cy);
        double dx = px - cx, dy = py - cy;
        if (dx * dx + dy * dy <= 30 * 30)
            return i;
    }
    return -1;
}

#define CC_PX(v) ((int)((v) * scale + 0.5))

static void shell_draw_control_center(int fbWidth, int fbHeight,
                                      double scale, const char *path)
{
    shell_wallpaper_build(fbWidth, fbHeight);
    if (g_shell_wallpaper)
        iosim_fb_paste_xrgb(g_shell_wallpaper);
    else
    {
        iosim_fb_set_opacity(1.0);
        iosim_fb_fill_rect(0, 0, fbWidth, fbHeight, 0x0b1020);
    }
    iosim_fb_set_opacity(0.42);
    iosim_fb_fill_rect(0, 0, fbWidth, fbHeight, 0x000000);
    iosim_fb_set_opacity(1.0);

    /* Glass tiles: connectivity, media, brightness, volume. */
    iosim_fb_set_opacity(0.86);
    iosim_fb_fill_round_rect(CC_PX(16), CC_PX(100), CC_PX(184), CC_PX(184),
                             CC_PX(32), 0x1c1c1e);
    iosim_fb_fill_round_rect(CC_PX(208), CC_PX(100), CC_PX(178), CC_PX(184),
                             CC_PX(32), 0x1c1c1e);
    iosim_fb_fill_round_rect(CC_PX(16), CC_PX(300), CC_PX(88), CC_PX(210),
                             CC_PX(32), 0x1c1c1e);
    iosim_fb_fill_round_rect(CC_PX(112), CC_PX(300), CC_PX(88), CC_PX(210),
                             CC_PX(32), 0x1c1c1e);
    for (int i = 0; i < 4; i++)
        iosim_fb_fill_circle(CC_PX(54 + i * 98), CC_PX(560), CC_PX(27),
                             0x1c1c1e);
    iosim_fb_set_opacity(1.0);

    for (int i = 0; i < 4; i++)
    {
        double cxpt, cypt;
        shell_cc_toggle_center(i, &cxpt, &cypt);
        int cx = CC_PX(cxpt), cy = CC_PX(cypt);
        int on = g_cc_toggles[i];
        unsigned fill = on ? (i == 1 ? 0x30d158 : 0x0a84ff) : 0x3a3a3c;
        unsigned fg = on ? 0xffffff : 0xd8d5e0;
        iosim_fb_fill_circle(cx, cy, CC_PX(26), fill);
        if (i == 0)
            shell_cc_airplane_icon(cx, cy, scale, fg);
        else if (i == 1)
            shell_cc_cellular_icon(cx, cy, scale, fg);
        else if (i == 2)
            shell_cc_wifi_icon(cx, cy, scale, fg);
        else
            shell_cc_bluetooth_icon(cx, cy, scale, fg);
    }

    /* Media module. */
    int mx = CC_PX(208), my = CC_PX(100);
    int dcx = mx + CC_PX(38), dcy = my + CC_PX(42);
    iosim_fb_fill_circle(dcx, dcy, CC_PX(25), 0x3a3a3c);
    iosim_fb_draw_line(dcx, dcy - CC_PX(11), dcx, dcy + CC_PX(8),
                       CC_PX(2), 0xffffff);
    iosim_fb_fill_circle(dcx - CC_PX(4), dcy + CC_PX(9), CC_PX(4),
                         0xffffff);
    iosim_fb_draw_line(dcx, dcy - CC_PX(11), dcx + CC_PX(8), dcy - CC_PX(15),
                       CC_PX(2), 0xffffff);
    iosim_fb_font_text(mx + CC_PX(16), my + CC_PX(126), "Not Playing",
                       IOSIM_FONT_SEMIBOLD, 16, scale, 0xffffff);
    iosim_fb_font_text(mx + CC_PX(16), my + CC_PX(150), "Music",
                       IOSIM_FONT_REGULAR, 13, scale, 0x9a9aa0);

    /* Brightness and volume sliders. */
    double levels[2] = {g_cc_brightness, g_cc_volume};
    for (int i = 0; i < 2; i++)
    {
        int sx = CC_PX(16 + i * 96), sy = CC_PX(300);
        int trackX = sx + CC_PX(34), trackY = sy + CC_PX(22);
        int trackW = CC_PX(20), trackH = CC_PX(136);
        iosim_fb_fill_round_rect(trackX, trackY, trackW, trackH,
                                 CC_PX(10), 0x3a3a3c);
        int fillH = (int)(trackH * levels[i]);
        if (fillH > 0)
            iosim_fb_fill_round_rect(trackX, trackY + trackH - fillH,
                                     trackW, fillH, CC_PX(10), 0xffffff);
        if (i == 0)
            shell_cc_sun_icon(sx + CC_PX(44), sy + CC_PX(186), scale,
                              0xd8d5e0);
        else
            shell_cc_speaker_icon(sx + CC_PX(44), sy + CC_PX(186), scale,
                                  0xd8d5e0);
    }

    /* Utility row: flashlight, timer, calculator, camera. */
    for (int i = 0; i < 4; i++)
    {
        int cx = CC_PX(54 + i * 98), cy = CC_PX(560);
        unsigned fg = 0xffffff;
        if (i == 0)
        {
            static const double bx[7] = {1, -5, 0, -2, 5, 2, 6};
            static const double by[7] = {-11, -1, -1, 11, 1, 1, -11};
            double px[7], py[7];
            for (int k = 0; k < 7; k++)
            {
                px[k] = cx + bx[k] * scale;
                py[k] = cy + by[k] * scale;
            }
            iosim_fb_fill_polygon(px, py, 7, fg);
        }
        else if (i == 1)
        {
            iosim_fb_stroke_circle(cx, cy, CC_PX(10), CC_PX(2), fg);
            iosim_fb_draw_line(cx, cy - CC_PX(7), cx, cy, CC_PX(2), fg);
            iosim_fb_draw_line(cx, cy, cx + CC_PX(6), cy + CC_PX(3),
                               CC_PX(2), fg);
        }
        else if (i == 2)
        {
            for (int r = 0; r < 3; r++)
                for (int c = 0; c < 3; c++)
                    iosim_fb_fill_circle(cx + (c - 1) * CC_PX(9),
                                         cy + (r - 1) * CC_PX(9),
                                         CC_PX(2), fg);
        }
        else
        {
            iosim_fb_fill_round_rect(cx - CC_PX(12), cy - CC_PX(9),
                                     CC_PX(24), CC_PX(18), CC_PX(4), fg);
            iosim_fb_fill_circle(cx, cy, CC_PX(6), 0x1c1c1e);
            iosim_fb_fill_circle(cx, cy, CC_PX(3), fg);
        }
    }

    draw_device_chrome(fbWidth, scale);
    if (path && *path)
        iosim_fb_present(path);
}

#undef CC_PX

static void shell_open_control_center(int fbWidth, int fbHeight,
                                      double scale, const char *path)
{
    g_control_center = 1;
    printf("[SpringBoard] control center opened\n");
    fflush(0);
    shell_draw_control_center(fbWidth, fbHeight, scale, path);
}

static void shell_close_control_center(int fbWidth, int fbHeight,
                                       double scale, const char *path)
{
    g_control_center = 0;
    printf("[SpringBoard] control center closed\n");
    fflush(0);
    shell_draw(fbWidth, fbHeight, scale);
    if (path && *path)
        iosim_fb_present(path);
}

/* Toggling a connectivity control redraws the panel and reports the state. */
static void shell_cc_toggle(int index, int fbWidth, int fbHeight,
                            double scale, const char *path)
{
    static const char *names[4] = {"airplane", "cellular", "wifi",
                                   "bluetooth"};
    g_cc_toggles[index] = !g_cc_toggles[index];
    printf("[SpringBoard] control center %s %s\n", names[index],
           g_cc_toggles[index] ? "on" : "off");
    fflush(0);
    shell_draw_control_center(fbWidth, fbHeight, scale, path);
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

/* The lock screen: the wallpaper at full brightness, the real date and the
 * big status time, and the bottom utility glass. */
static void shell_draw_lock(int fbWidth, int fbHeight, double scale,
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

    NSDate *now = [NSDate date];
    NSCalendar *cal = [NSCalendar currentCalendar];
    NSDateComponents *parts =
        [cal components:(NSCalendarUnitMonth | NSCalendarUnitDay |
                         NSCalendarUnitWeekday)
              fromDate:now];
    static const char *weekdays[8] = {"", "Sunday", "Monday", "Tuesday",
                                      "Wednesday", "Thursday", "Friday",
                                      "Saturday"};
    static const char *months[13] = {"", "January", "February", "March",
                                     "April", "May", "June", "July", "August",
                                     "September", "October", "November",
                                     "December"};
    long wd = [parts weekday], mo = [parts month], day = [parts day];
    char date[64];
    if (wd >= 1 && wd <= 7 && mo >= 1 && mo <= 12)
        snprintf(date, sizeof date, "%s, %s %ld", weekdays[wd], months[mo],
                 day);
    else
        shell_copy(date, (int)sizeof date, "Lock Screen");
    int dw = iosim_fb_font_text_width(date, IOSIM_FONT_SEMIBOLD, 17, scale);
    iosim_fb_font_text((fbWidth - dw) / 2, (int)(78 * scale), date,
                       IOSIM_FONT_SEMIBOLD, 17, scale, 0xffffff);

    const char *statusTime = getenv("IOSIM_STATUS_TIME");
    if (!statusTime || !*statusTime)
        statusTime = "9:41";
    int tw = iosim_fb_font_text_width(statusTime, IOSIM_FONT_SEMIBOLD, 76,
                                      scale);
    iosim_fb_font_text((fbWidth - tw) / 2, (int)(186 * scale), statusTime,
                       IOSIM_FONT_SEMIBOLD, 76, scale, 0xffffff);

    double W = fbWidth / scale;
    double H = fbHeight / scale;
    int ny = (int)(470 * scale + 0.5);
    for (int i = 0; i < g_sb_delivered_count && i < 3; i++)
    {
        int ch = (int)(shell_notification_card_height(&g_sb_delivered[i]) *
                       scale + 0.5);
        char when[32];
        shell_relative_time(g_sb_delivered_time[i], when, sizeof(when));
        shell_draw_notification_card(&g_sb_delivered[i],
                                     (int)(16 * scale + 0.5), ny,
                                     (int)((W - 32) * scale + 0.5), ch,
                                     scale, when, 1);
        ny += ch + (int)(8 * scale + 0.5);
    }
    for (int side = 0; side < 2; side++)
    {
        double cx = side == 0 ? 62.0 : W - 62.0;
        double cy = H - 92.0;
        iosim_fb_set_opacity(0.55);
        iosim_fb_fill_circle((int)(cx * scale), (int)(cy * scale),
                             (int)(24 * scale), 0x2c2c2e);
        iosim_fb_set_opacity(1.0);
        if (side == 0)
        {
            /* Flashlight: a head over a handle. */
            iosim_fb_fill_round_rect((int)((cx - 7) * scale),
                                     (int)((cy - 12) * scale),
                                     (int)(14 * scale), (int)(8 * scale),
                                     (int)(3 * scale), 0xffffff);
            iosim_fb_fill_round_rect((int)((cx - 3) * scale),
                                     (int)((cy - 5) * scale),
                                     (int)(6 * scale), (int)(16 * scale),
                                     (int)(2 * scale), 0xffffff);
        }
        else
        {
            /* Camera: body, viewfinder bump and a lens. */
            iosim_fb_fill_round_rect((int)((cx - 11) * scale),
                                     (int)((cy - 6) * scale),
                                     (int)(22 * scale), (int)(15 * scale),
                                     (int)(4 * scale), 0xffffff);
            iosim_fb_fill_round_rect((int)((cx - 11) * scale),
                                     (int)((cy - 10) * scale),
                                     (int)(8 * scale), (int)(4 * scale),
                                     (int)(2 * scale), 0xffffff);
            iosim_fb_fill_circle((int)(cx * scale),
                                 (int)((cy + 1.5) * scale),
                                 (int)(5 * scale), 0x2c2c2e);
            iosim_fb_fill_circle((int)(cx * scale),
                                 (int)((cy + 1.5) * scale),
                                 (int)(3.2 * scale), 0xffffff);
        }
    }
    iosim_fb_set_opacity(0.85);
    iosim_fb_fill_round_rect((int)((W / 2.0 - 69.5) * scale),
                             (int)((H - 13) * scale), (int)(139 * scale),
                             (int)(5 * scale), (int)(2.5 * scale), 0xffffff);
    iosim_fb_set_opacity(1.0);

    draw_status_icons(fbWidth, scale, 0xffffff);
    if (path && *path)
        iosim_fb_present(path);
}

/* Lock from the home screen or the switcher. An app-originated lock goes
 * through shell_after_app_stop, which keeps the app index to resume. */
static void shell_lock(int fbWidth, int fbHeight, double scale,
                       const char *path, int resume_app)
{
    g_locked = 1;
    g_lock_resume_app = resume_app;
    g_switcher = 0;
    g_control_center = 0;
    g_notification_center = 0;
    g_sb_nc_expanded = -1;
    g_sb_banner_expanded = 0;
    g_open_folder = -1;
    if (g_search)
    {
        g_search = 0;
        if (g_search_field)
            [g_search_field resignFirstResponder];
    }
    printf("[SpringBoard] locked\n");
    fflush(0);
    shell_draw_lock(fbWidth, fbHeight, scale, path);
}

static void shell_after_app_stop(int fbWidth, int fbHeight, double scale,
                                 const char *path)
{
    /* The app may have changed its icon badge or notification categories
     * while it was foreground. */
    shell_badges_load();
    shell_notification_categories_load();
    /* Appearance events are consumed by whichever process is foreground, so
     * pick up the shared value again when SpringBoard gets the screen back. */
    g_ui_style = ui_appearance_read_file();
    if (g_lock_requested)
    {
        g_lock_requested = 0;
        shell_lock(fbWidth, fbHeight, scale, path, g_fg_app);
        return;
    }
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
    g_fg_app = index;
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

/* Unlock resumes the app that was foreground when the lock happened, or
 * returns to the home screen. */
static void shell_unlock(int fbWidth, int fbHeight, double scale,
                         const char *path)
{
    if (!g_locked)
        return;
    g_locked = 0;
    int app = g_lock_resume_app;
    g_lock_resume_app = -1;
    printf("[SpringBoard] unlocked\n");
    fflush(0);
    if (app >= 0 && app < g_shell_app_count && g_shell_apps[app].pid > 0)
    {
        shell_launch(app, fbWidth, fbHeight, scale, path);
        return;
    }
    shell_repaint(fbWidth, fbHeight, scale, path, 0);
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

/* Redraws whichever system surface currently owns the screen. */
static void shell_refresh_all(int fbWidth, int fbHeight, double scale,
                              const char *path)
{
    if (g_locked)
        shell_draw_lock(fbWidth, fbHeight, scale, path);
    else if (g_notification_center)
    {
        shell_draw_notification_center(fbWidth, fbHeight, scale);
        if (path && *path)
            iosim_fb_present(path);
    }
    else if (g_switcher)
        shell_draw_switcher(fbWidth, fbHeight, scale, path);
    else if (g_control_center)
        shell_draw_control_center(fbWidth, fbHeight, scale, path);
    else if (g_search)
        shell_draw_search(fbWidth, fbHeight, scale, path);
    else if (g_open_folder >= 0)
        shell_draw_folder(fbWidth, fbHeight, scale, path);
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
    g_ui_style = ui_appearance_read_file();
    if (iosim_fb_begin((unsigned)fbWidth, (unsigned)fbHeight) != 0)
        return 1;

    iosim_on_switcher_request(shell_switcher_requested);
    iosim_on_lock_request(shell_lock_requested);
    shell_load_apps();
    shell_folders_load();
    shell_folders_prune();
    shell_badges_load();
    shell_notification_categories_load();
    g_shell_active = 1;
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
        if (shell_notification_tick(fbWidth, fbHeight, scale, path))
        {
            shell_refresh_all(fbWidth, fbHeight, scale, path);
            continue;
        }
        if (r == 1 && type == 18)
        {
            /* The device manager switched light/dark appearance. */
            int dark = x != 0;
            g_ui_style = dark;
            ui_appearance_write_file(dark);
            shell_refresh_all(fbWidth, fbHeight, scale, path);
            /* Log after the repaint so a waiting harness can screenshot. */
            printf("[SpringBoard] appearance %s\n", dark ? "dark" : "light");
            fflush(0);
            continue;
        }
        if (r == 1 && type == 8)
        {
            /* The set of installed apps changed: rebuild the home screen. */
            g_switcher = 0;
            g_open_folder = -1;
            shell_load_apps();
            shell_folders_prune();
            shell_badges_load();
            if (g_home_page >= shell_page_count())
                g_home_page = shell_page_count() - 1;
            if (g_home_page < 0)
                g_home_page = 0;
            if (g_locked)
            {
                shell_draw_lock(fbWidth, fbHeight, scale, path);
                continue;
            }
            if (g_control_center)
            {
                shell_draw_control_center(fbWidth, fbHeight, scale, path);
                continue;
            }
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
            if (g_locked)
                continue;
            if (g_notification_center)
            {
                shell_close_notification_center(fbWidth, fbHeight, scale,
                                                path);
                shell_refresh_all(fbWidth, fbHeight, scale, path);
                continue;
            }
            if (g_open_folder >= 0)
            {
                g_open_folder = -1;
                printf("[SpringBoard] folder closed\n");
                fflush(0);
                shell_draw(fbWidth, fbHeight, scale);
                if (path && *path)
                    iosim_fb_present(path);
                continue;
            }
            if (g_control_center)
            {
                shell_close_control_center(fbWidth, fbHeight, scale, path);
                continue;
            }
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
        if (r == 1 && type == 10)
        {
            if (!g_locked)
                shell_lock(fbWidth, fbHeight, scale, path, -1);
            continue;
        }
        if (r == 1 && type == 11)
        {
            if (g_locked)
                shell_unlock(fbWidth, fbHeight, scale, path);
            continue;
        }
        if (r == 1 && type == 2)
        {
            g_sb_down = 1;
            g_sb_down_x = x / scale;
            g_sb_down_y = y / scale;
            g_sb_down_time = iosim_now();
            g_sb_moved = 0;
            g_sb_icon_hold = 0;
            continue;
        }
        if (r == 1 && type == 3)
        {
            double px = x / scale, py = y / scale;
            if (g_sb_down && !g_sb_moved)
            {
                double mdx = px - g_sb_down_x, mdy = py - g_sb_down_y;
                if (__builtin_fabs(mdx) + __builtin_fabs(mdy) > 10)
                {
                    g_sb_moved = 1;
                    if (iosim_now() - g_sb_down_time >=
                        SHELL_ICON_HOLD_SECONDS)
                        g_sb_icon_hold = 1;
                }
            }
            continue;
        }
        if (r == 1 && type == 4)
        {
            double px = x / scale, py = y / scale;
            double dx = px - g_sb_down_x, dy = py - g_sb_down_y;
            int down = g_sb_down;
            int icon_hold = g_sb_icon_hold;
            g_sb_down = 0;
            g_sb_icon_hold = 0;
            if (!down)
                continue;
            if (g_sb_banner_active)
            {
                int bx, by, bw, bh;
                shell_banner_final_frame(fbWidth, scale, &bx, &by, &bw, &bh);
                if (dy < -25 && g_sb_down_x >= bx / scale &&
                    g_sb_down_x < (bx + bw) / scale &&
                    g_sb_down_y >= by / scale &&
                    g_sb_down_y < (by + bh) / scale)
                {
                    g_sb_banner_active = 0;
                    g_sb_banner_expanded = 0;
                    printf("[SpringBoard] notification banner dismissed\n");
                    fflush(0);
                    shell_refresh_all(fbWidth, fbHeight, scale, path);
                    continue;
                }
                int inside = g_sb_down_x >= bx / scale &&
                             g_sb_down_x < (bx + bw) / scale &&
                             g_sb_down_y >= by / scale &&
                             g_sb_down_y < (by + bh) / scale;
                if (!g_sb_moved && inside && !g_sb_banner_expanded &&
                    iosim_now() - g_sb_down_time >= 0.45 &&
                    shell_notification_action_count(&g_sb_banner) > 0)
                {
                    g_sb_banner_expanded = 1;
                    printf("[SpringBoard] notification actions %s\n",
                           g_sb_banner.title);
                    fflush(0);
                    shell_refresh_all(fbWidth, fbHeight, scale, path);
                    continue;
                }
                if (g_sb_banner_expanded)
                {
                    int action =
                        shell_banner_action_hit(px, py, fbWidth, scale);
                    struct sb_category *category =
                        shell_category_for(g_sb_banner.category);
                    if (!g_sb_moved && action >= 0 && category &&
                        action < category->action_count)
                    {
                        shell_open_notification_action(
                            &g_sb_banner,
                            category->actions[action].identifier, fbWidth,
                            fbHeight, scale, path);
                        continue;
                    }
                    if (!g_sb_moved)
                    {
                        g_sb_banner_expanded = 0;
                        printf("[SpringBoard] notification actions closed\n");
                        fflush(0);
                        shell_refresh_all(fbWidth, fbHeight, scale, path);
                        continue;
                    }
                }
            }
            if (g_locked)
            {
                /* Swiping up anywhere on the lock screen unlocks, the same
                 * gesture a Face ID phone accepts. */
                if (dy < -80)
                    shell_unlock(fbWidth, fbHeight, scale, path);
                continue;
            }
            if (g_notification_center)
            {
                if (g_sb_nc_expanded >= 0)
                {
                    if (!g_sb_moved)
                    {
                        int action =
                            shell_nc_action_hit(px, py, fbWidth, scale);
                        int ax, ay, aw, ah;
                        struct sb_category *category = 0;
                        shell_nc_action_sheet(fbWidth, scale, &ax, &ay, &aw,
                                              &ah, &category);
                        if (action >= 0 && category)
                        {
                            shell_open_notification_action(
                                &g_sb_delivered[g_sb_nc_expanded],
                                category->actions[action].identifier, fbWidth,
                                fbHeight, scale, path);
                            continue;
                        }
                        g_sb_nc_expanded = -1;
                        printf("[SpringBoard] notification actions closed\n");
                        fflush(0);
                        shell_refresh_all(fbWidth, fbHeight, scale, path);
                    }
                    continue;
                }
                if (!g_sb_moved && iosim_now() - g_sb_down_time >= 0.45)
                {
                    int index = shell_notification_center_hit(
                        g_sb_down_x, g_sb_down_y, fbWidth, scale);
                    if (index >= 0 &&
                        shell_notification_action_count(
                            &g_sb_delivered[index]) > 0)
                    {
                        g_sb_nc_expanded = index;
                        printf("[SpringBoard] notification actions %s\n",
                               g_sb_delivered[index].title);
                        fflush(0);
                        shell_refresh_all(fbWidth, fbHeight, scale, path);
                        continue;
                    }
                }
                if (dy < -90)
                {
                    shell_close_notification_center(fbWidth, fbHeight, scale,
                                                    path);
                    shell_refresh_all(fbWidth, fbHeight, scale, path);
                }
                continue;
            }
            if (g_control_center)
            {
                if (dy < -90)
                    shell_close_control_center(fbWidth, fbHeight, scale,
                                               path);
                continue;
            }
            if (g_open_folder >= 0)
            {
                if (dy < -90 || dy > 90)
                {
                    g_open_folder = -1;
                    printf("[SpringBoard] folder closed\n");
                    fflush(0);
                    shell_draw(fbWidth, fbHeight, scale);
                    if (path && *path)
                        iosim_fb_present(path);
                }
                continue;
            }
            if (!g_switcher && !g_search && g_sb_down_y < 60 &&
                g_sb_down_x > fbWidth / scale - 120 && dy > 90)
            {
                /* A downward drag from the top-right corner opens the
                 * Control Center, like the real system gesture. */
                shell_open_control_center(fbWidth, fbHeight, scale, path);
                continue;
            }
            if (!g_switcher && !g_search && !g_control_center &&
                g_open_folder < 0 && g_sb_down_y < 60 &&
                g_sb_down_x <= fbWidth / scale - 120 && dy > 90)
            {
                /* A downward drag from the rest of the top edge opens
                 * Notification Center. */
                shell_open_notification_center(fbWidth, fbHeight, scale,
                                               path);
                continue;
            }
            if (!g_switcher && !g_search && !g_control_center &&
                g_open_folder < 0 && icon_hold &&
                __builtin_fabs(dx) + __builtin_fabs(dy) > 40)
            {
                /* Dropping an icon onto another groups them into a folder;
                 * dropping it onto a folder adds it there. */
                int start_app = -1, start_folder = -1;
                int end_app = -1, end_folder = -1;
                if (shell_grid_entry_at(g_sb_down_x, g_sb_down_y, fbWidth / scale,
                                        scale, &start_app, &start_folder) &&
                    shell_grid_entry_at(px, py, fbWidth / scale, scale,
                                        &end_app, &end_folder) &&
                    start_app >= 0 && g_shell_apps[start_app].bundle[0])
                {
                    if (end_folder >= 0 && end_folder != start_folder)
                    {
                        shell_folder_create(start_app, end_folder, -1);
                        shell_repaint(fbWidth, fbHeight, scale, path, 0);
                        continue;
                    }
                    if (end_app >= 0 && end_app != start_app &&
                        g_shell_apps[end_app].bundle[0])
                    {
                        shell_folder_create(start_app, -1, end_app);
                        shell_repaint(fbWidth, fbHeight, scale, path, 0);
                        continue;
                    }
                }
            }
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
            else if (!g_switcher && !icon_hold && (dx > 80 || dx < -80) &&
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
            if (g_locked)
            {
                shell_unlock(fbWidth, fbHeight, scale, path);
                continue;
            }
            if (g_notification_center)
            {
                shell_close_notification_center(fbWidth, fbHeight, scale,
                                                path);
                shell_refresh_all(fbWidth, fbHeight, scale, path);
                continue;
            }
            if (g_open_folder >= 0)
            {
                g_open_folder = -1;
                printf("[SpringBoard] folder closed\n");
                fflush(0);
                shell_draw(fbWidth, fbHeight, scale);
                if (path && *path)
                    iosim_fb_present(path);
                continue;
            }
            if (g_control_center)
            {
                shell_close_control_center(fbWidth, fbHeight, scale, path);
                continue;
            }
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
        if (g_sb_banner_active)
        {
            if (g_sb_banner_expanded)
            {
                int action =
                    shell_banner_action_hit(px, py, fbWidth, scale);
                struct sb_category *category =
                    shell_category_for(g_sb_banner.category);
                if (action >= 0 && category && action < category->action_count)
                {
                    shell_open_notification_action(
                        &g_sb_banner, category->actions[action].identifier,
                        fbWidth, fbHeight, scale, path);
                    continue;
                }
                g_sb_banner_expanded = 0;
                printf("[SpringBoard] notification actions closed\n");
                fflush(0);
                shell_refresh_all(fbWidth, fbHeight, scale, path);
                continue;
            }
            int bx, by, bw, bh;
            shell_banner_final_frame(fbWidth, scale, &bx, &by, &bw, &bh);
            if (px >= bx / scale && px < (bx + bw) / scale &&
                py >= by / scale && py < (by + bh) / scale)
            {
                shell_open_notification(&g_sb_banner, fbWidth, fbHeight,
                                        scale, path);
                continue;
            }
            g_sb_banner_active = 0;
            printf("[SpringBoard] notification banner dismissed\n");
            fflush(0);
            shell_refresh_all(fbWidth, fbHeight, scale, path);
            continue;
        }
        if (g_locked)
        {
            int index =
                shell_lock_notification_hit(px, py, fbWidth, scale);
            if (index >= 0)
            {
                g_locked = 0;
                g_lock_resume_app = -1;
                printf("[SpringBoard] unlocked\n");
                fflush(0);
                shell_open_notification(&g_sb_delivered[index], fbWidth,
                                        fbHeight, scale, path);
            }
            continue;
        }
        if (g_notification_center)
        {
            if (g_sb_nc_expanded >= 0)
            {
                int action = shell_nc_action_hit(px, py, fbWidth, scale);
                int ax, ay, aw, ah;
                struct sb_category *category = 0;
                shell_nc_action_sheet(fbWidth, scale, &ax, &ay, &aw, &ah,
                                      &category);
                if (action >= 0 && category)
                {
                    shell_open_notification_action(
                        &g_sb_delivered[g_sb_nc_expanded],
                        category->actions[action].identifier, fbWidth,
                        fbHeight, scale, path);
                    continue;
                }
                g_sb_nc_expanded = -1;
                printf("[SpringBoard] notification actions closed\n");
                fflush(0);
                shell_refresh_all(fbWidth, fbHeight, scale, path);
                continue;
            }
            int index =
                shell_notification_center_hit(px, py, fbWidth, scale);
            if (index >= 0)
                shell_open_notification(&g_sb_delivered[index], fbWidth,
                                        fbHeight, scale, path);
            continue;
        }
        if (g_control_center)
        {
            int toggle = shell_cc_toggle_at(px, py);
            if (toggle >= 0)
                shell_cc_toggle(toggle, fbWidth, fbHeight, scale, path);
            else if (py > 620.0)
                shell_close_control_center(fbWidth, fbHeight, scale, path);
            continue;
        }
        if (g_open_folder >= 0)
        {
            int member = shell_folder_member_at(px, py, W);
            if (member >= 0)
            {
                int app = shell_folder_member_app(g_open_folder, member);
                g_open_folder = -1;
                if (app >= 0)
                    shell_launch(app, fbWidth, fbHeight, scale, path);
                else
                {
                    shell_draw(fbWidth, fbHeight, scale);
                    if (path && *path)
                        iosim_fb_present(path);
                }
                continue;
            }
            if (py > 470.0 || py < 100.0 || px < 24.0 || px > W - 24.0)
            {
                g_open_folder = -1;
                printf("[SpringBoard] folder closed\n");
                fflush(0);
                shell_draw(fbWidth, fbHeight, scale);
                if (path && *path)
                    iosim_fb_present(path);
            }
            continue;
        }
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
        int hit = -1, folder_hit = -1;
        if (shell_grid_entry_at(px, py, W, scale, &hit, &folder_hit) &&
            folder_hit >= 0)
        {
            g_open_folder = folder_hit;
            printf("[SpringBoard] folder opened name=%s (%d apps)\n",
                   g_folders[folder_hit].name, g_folders[folder_hit].count);
            fflush(0);
            shell_draw_folder(fbWidth, fbHeight, scale, path);
            continue;
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

#define ALERT_MAX_ACTIONS 8

struct alert_layout {
    int sheet;
    double width;
    double group_x, group_y, group_h;
    double title_h, message_h;
    int row_count;
    int row_action[ALERT_MAX_ACTIONS];
    double row_x[ALERT_MAX_ACTIONS], row_y[ALERT_MAX_ACTIONS];
    double row_w[ALERT_MAX_ACTIONS], row_h;
    int cancel_action;
    double cancel_x, cancel_y, cancel_w, cancel_h;
};

static double alert_text_height(id text, int bold, double size, int maxLines,
                                double textW, double scale)
{
    if (!text)
        return 0;
    const char *t = iosim_string_cstr(text);
    char lines[IOSIM_MAX_WRAP_LINES][256];
    int n = wrap_text_lines(t, bold ? IOSIM_FONT_BOLD : IOSIM_FONT_REGULAR,
                            size, scale, (int)(textW * scale), lines,
                            maxLines);
    int asc = 0, desc = 0, lh = 0;
    iosim_fb_font_metrics(bold ? IOSIM_FONT_BOLD : IOSIM_FONT_REGULAR, size,
                          scale, &asc, &desc, &lh);
    return (n > 0 ? n : 1) * lh / scale;
}

/* Lay out an alert or action sheet once; both drawing and hit testing use
 * the resulting row rectangles. */
static void alert_compute_layout(UIAlertController *alert, int fbW, int fbH,
                                 double scale, struct alert_layout *out)
{
    memset(out, 0, sizeof(*out));
    out->cancel_action = -1;
    double W = fbW / scale, H = fbH / scale;
    int sheet = alert->_preferredStyle == UIAlertControllerStyleActionSheet;
    out->sheet = sheet;
    double width = sheet ? W - 16 : W - 82;
    if (sheet)
    {
        if (width > 500)
            width = 500;
    }
    else if (width > 320)
        width = 320;
    if (width < 200)
        width = 200;
    out->width = width;
    double textW = width - (sheet ? 48 : 64);
    double th = alert_text_height(alert->_title, 1, 17, 4, textW, scale);
    double mh = alert_text_height(alert->_message, 0, 15, 8, textW, scale);
    out->title_h = th;
    out->message_h = mh;
    int count = alert->_actionCount;
    if (count > ALERT_MAX_ACTIONS)
        count = ALERT_MAX_ACTIONS;
    int cancel = -1;
    for (int i = 0; i < count; i++)
    {
        UIAlertAction *action = (UIAlertAction *)alert->_actions[i];
        if (action && action->_style == UIAlertActionStyleCancel)
            cancel = i;
    }

    if (sheet)
    {
        double row_h = 47, gap = 8;
        int group_rows = count - (cancel >= 0 ? 1 : 0);
        double text_block = th + (mh > 0 ? 7 + mh : 0);
        double top = text_block > 0 ? 16 + text_block + 14 : 8;
        double group_h = top +
                         (group_rows > 0
                              ? group_rows * row_h + (group_rows - 1) * gap
                              : 0) +
                         8;
        double bottom = H - 10;
        double cancel_y = 0, cancel_h = 0;
        if (cancel >= 0)
        {
            cancel_h = 47;
            cancel_y = bottom - cancel_h;
            bottom = cancel_y - gap;
        }
        double group_y = bottom - group_h;
        out->group_x = (W - width) / 2;
        out->group_y = group_y;
        out->group_h = group_h;
        out->row_h = row_h;
        int r = 0;
        for (int i = 0; i < count; i++)
        {
            if (i == cancel)
                continue;
            out->row_action[r] = i;
            out->row_x[r] = out->group_x + 8;
            out->row_y[r] = group_y + top + r * (row_h + gap);
            out->row_w[r] = width - 16;
            r++;
        }
        out->row_count = r;
        if (cancel >= 0)
        {
            out->cancel_action = cancel;
            out->cancel_x = out->group_x;
            out->cancel_y = cancel_y;
            out->cancel_w = width;
            out->cancel_h = cancel_h;
        }
        return;
    }

    double buttons;
    if (count == 2)
        buttons = 47;
    else
        buttons =
            count * 47 + (count > 1 ? (count - 1) * 8 : 0);
    double h = 22 + th + (mh > 0 ? 7 + mh : 0) + 20.5 + buttons + 17;
    double x = (W - width) / 2, y = (H - h) / 2 + 14;
    out->group_x = x;
    out->group_y = y;
    out->group_h = h;
    out->row_h = 47;
    if (count == 2)
    {
        double gap = 8.3;
        double bw = (width - 32 - gap) / 2;
        double by = y + h - 17 - 47;
        for (int i = 0; i < 2; i++)
        {
            out->row_action[i] = i;
            out->row_x[i] = x + 16 + i * (bw + gap);
            out->row_y[i] = by;
            out->row_w[i] = bw;
        }
        out->row_count = 2;
    }
    else if (count > 0)
    {
        double by = y + h - 17 - 47;
        double start = by - (count - 1) * (47 + 8);
        for (int i = 0; i < count; i++)
        {
            out->row_action[i] = i;
            out->row_x[i] = x + 16;
            out->row_y[i] = start + i * (47 + 8);
            out->row_w[i] = width - 32;
        }
        out->row_count = count;
    }
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

static void alert_draw_button(UIAlertAction *action, double x, double y,
                              double w, double h, double scale)
{
    if (!action)
        return;
    int bx = (int)(x * scale + 0.5);
    int by = (int)(y * scale + 0.5);
    int bw = (int)(w * scale + 0.5);
    int bh = (int)(h * scale + 0.5);
    iosim_fb_fill_round_rect(bx, by, bw, bh, bh / 2, 0x404149);
    const char *title = iosim_string_cstr(action->_title);
    if (!title)
        return;
    unsigned color = action->_style == UIAlertActionStyleDestructive
                         ? 0xff6b6f : 0xffffff;
    int tw = iosim_fb_font_text_width(title, IOSIM_FONT_SEMIBOLD, 17, scale);
    int asc = 0, desc = 0, lh = 0;
    iosim_fb_font_metrics(IOSIM_FONT_SEMIBOLD, 17, scale, &asc, &desc, &lh);
    iosim_fb_font_text(bx + (bw - tw) / 2,
                       by + bh / 2 - lh / 2 + asc +
                           (int)(0.7 * scale + 0.5),
                       title, IOSIM_FONT_SEMIBOLD, 17, scale, color);
}

static void draw_alert(UIAlertController *alert, int fbW, int fbH,
                       double scale)
{
    iosim_fb_set_opacity(0.47);
    iosim_fb_fill_rect(0, 0, fbW, fbH, 0x000000);
    iosim_fb_set_opacity(1.0);
    /* The system status bar lives above the alert's dimming view. */
    draw_device_chrome(fbW, scale);
    struct alert_layout layout;
    alert_compute_layout(alert, fbW, fbH, scale, &layout);
    int gx = (int)(layout.group_x * scale + 0.5);
    int gy = (int)(layout.group_y * scale + 0.5);
    int gw = (int)(layout.width * scale + 0.5);
    int gh = (int)(layout.group_h * scale + 0.5);
    iosim_fb_fill_round_rect(gx, gy, gw, gh,
                             (int)((layout.sheet ? 28 : 33.7) * scale),
                             0x23242d);
    if (layout.cancel_action >= 0)
        iosim_fb_fill_round_rect(
            (int)(layout.cancel_x * scale + 0.5),
            (int)(layout.cancel_y * scale + 0.5),
            (int)(layout.cancel_w * scale + 0.5),
            (int)(layout.cancel_h * scale + 0.5), (int)(23.5 * scale),
            0x404149);

    double textW = layout.width - (layout.sheet ? 48 : 64);
    int cursor = gy + (int)((layout.sheet ? 16 : 22) * scale);
    int textX = gx + (int)((layout.sheet ? 24 : 30) * scale);
    if (alert->_title)
    {
        alert_draw_wrapped(alert->_title, textW, scale, textX, cursor,
                           0xffffff, 1, 17, 4);
        cursor += (int)(layout.title_h * scale) + (int)(7 * scale);
    }
    if (alert->_message)
    {
        alert_draw_wrapped(alert->_message, textW, scale, textX, cursor,
                           0x71727a, 0, 15, 8);
        cursor += (int)(layout.message_h * scale) + (int)(20.5 * scale);
    }
    for (int r = 0; r < layout.row_count; r++)
        alert_draw_button(alert->_actions[layout.row_action[r]],
                          layout.row_x[r], layout.row_y[r], layout.row_w[r],
                          layout.row_h, scale);
    if (layout.cancel_action >= 0)
        alert_draw_button(alert->_actions[layout.cancel_action],
                          layout.cancel_x, layout.cancel_y, layout.cancel_w,
                          layout.cancel_h, scale);
}

/* Edit menu drawing and hit testing. The menu is laid out at draw time in
 * device pixels; the item rectangles feed the next tap. */
static int g_edit_menu_rects[8][4];
static int g_edit_menu_item_count;

static void menu_screen_origin(UIView *view, double *ox, double *oy)
{
    double x = 0, y = 0;
    for (UIView *v = view; v; v = (UIView *)v->_superview)
    {
        x += v->_frame.origin.x;
        y += v->_frame.origin.y;
        if (v && [v isKindOfClass:[UIScrollView class]])
        {
            UIScrollView *scroll = (UIScrollView *)v;
            x -= scroll->_contentOffset.x;
            y -= scroll->_contentOffset.y;
        }
    }
    *ox = x;
    *oy = y;
}

static void draw_edit_menu(int fbW, double scale)
{
    g_edit_menu_item_count = 0;
    UIMenuController *menu = [UIMenuController sharedMenuController];
    if (!menu || !menu->_menuVisible || !menu->_items ||
        menu->_items->_count == 0)
        return;
    int count = (int)menu->_items->_count;
    if (count > 8)
        count = 8;
    int widths[8];
    int total = 0;
    int pad = (int)(15.0 * scale + 0.5);
    int panelH = (int)(38.0 * scale + 0.5);
    for (int i = 0; i < count; i++)
    {
        UIMenuItem *item = (UIMenuItem *)[menu->_items objectAtIndex:i];
        const char *title = item && item->_title ? iosim_string_cstr(item->_title)
                                                 : "";
        widths[i] = iosim_fb_font_text_width(title, IOSIM_FONT_REGULAR, 17.0,
                                             scale) + 2 * pad;
        total += widths[i];
    }
    double viewX = 0, viewY = 0;
    if (menu->_targetView)
        menu_screen_origin(menu->_targetView, &viewX, &viewY);
    double originX = viewX + menu->_targetRect.origin.x;
    double originY = viewY + menu->_targetRect.origin.y;
    int panelW = total;
    int px = (int)((originX + menu->_targetRect.size.width / 2) * scale + 0.5) -
             panelW / 2;
    int py = (int)(originY * scale + 0.5) - (int)(8.0 * scale + 0.5) - panelH;
    if (py < (int)(40.0 * scale))
        py = (int)((originY + menu->_targetRect.size.height) * scale + 0.5) +
             (int)(8.0 * scale + 0.5);
    if (px < 0)
        px = 0;
    if (px + panelW > fbW)
        px = fbW - panelW;
    iosim_fb_fill_round_rect(px, py, panelW, panelH,
                             (int)(9.0 * scale + 0.5), 0x2c2c2e);
    int ascent = 0, descent = 0, lineHeight = 0;
    iosim_fb_font_metrics(IOSIM_FONT_REGULAR, 17.0, scale, &ascent, &descent,
                          &lineHeight);
    int baseline = py + (panelH - lineHeight) / 2 + ascent;
    int cx = px;
    for (int i = 0; i < count; i++)
    {
        UIMenuItem *item = (UIMenuItem *)[menu->_items objectAtIndex:i];
        const char *title = item && item->_title ? iosim_string_cstr(item->_title)
                                                 : "";
        iosim_fb_font_text(cx + pad, baseline, title, IOSIM_FONT_REGULAR, 17.0,
                           scale, 0xffffff);
        g_edit_menu_rects[i][0] = cx;
        g_edit_menu_rects[i][1] = py;
        g_edit_menu_rects[i][2] = cx + widths[i];
        g_edit_menu_rects[i][3] = py + panelH;
        cx += widths[i];
    }
    g_edit_menu_item_count = count;
}

/* Returns 1 when the tap belonged to the menu (an item or the dismissal
 * area), which also swallows the tap from the view hierarchy. */
static int edit_menu_handle_tap(int px, int py)
{
    UIMenuController *menu = [UIMenuController sharedMenuController];
    if (!menu || !menu->_menuVisible)
        return 0;
    menu->_menuVisible = NO;
    for (int i = 0; i < g_edit_menu_item_count; i++)
    {
        if (px >= g_edit_menu_rects[i][0] && px < g_edit_menu_rects[i][2] &&
            py >= g_edit_menu_rects[i][1] && py < g_edit_menu_rects[i][3])
        {
            UIMenuItem *item = (UIMenuItem *)[menu->_items objectAtIndex:i];
            id target = g_firstResponder;
            if (!target)
                target = (id)menu->_targetView;
            if (item && target && [target respondsToSelector:item->_action])
                ((void (*)(id, SEL, id))objc_msgSend)(target, item->_action, nil);
            break;
        }
    }
    return 1;
}

/* ------------------------------------------------------- share sheet */

/* The share sheet is laid out when it is drawn; the row and button
 * rectangles feed the next tap, the same model as the edit menu. */
static int g_share_sheet_rect[4];
static int g_share_cancel_rect[4];
static int g_share_close_rect[4];
static int g_share_row_rects[16][4];
static int g_share_row_count;
static UIActivityViewController *g_share_drawn_controller;

static void share_text_ellipsis(const char *text, int style, double size,
                                double scale, int maxWidth, char *out,
                                unsigned long outSize)
{
    snprintf(out, outSize, "%s", text ? text : "");
    if (iosim_fb_font_text_width(out, style, size, scale) <= maxWidth)
        return;
    unsigned long len = strlen(out);
    while (len > 0)
    {
        out[len - 1] = 0;
        char candidate[256];
        snprintf(candidate, sizeof(candidate), "%s...", out);
        if (iosim_fb_font_text_width(candidate, style, size, scale) <= maxWidth)
        {
            snprintf(out, outSize, "%s", candidate);
            return;
        }
        len--;
    }
    snprintf(out, outSize, "...");
}

static void share_draw_preview(id item, int tx, int ty, int size, double scale)
{
    if ([item isKindOfClass:[UIImage class]])
    {
        UIImage *image = (UIImage *)item;
        iosim_fb_fill_round_rect(tx, ty, size, size,
                                 (int)(8 * scale + 0.5), 0xffffff);
        if (image->_rgba && image->_width > 0 && image->_height > 0)
        {
            int inset = (int)(2 * scale + 0.5);
            iosim_fb_blit_rgba_scaled(tx + inset, ty + inset,
                                      size - 2 * inset, size - 2 * inset,
                                      image->_rgba, image->_width,
                                      image->_height, image->_width * 4);
        }
        return;
    }
    iosim_fb_fill_round_rect(tx, ty, size, size, (int)(8 * scale + 0.5),
                             0xffffff);
    int inset = (int)(10 * scale + 0.5);
    int lineH = (int)(2 * scale + 0.5);
    int top = ty + (int)(13 * scale + 0.5);
    int step = (int)(7 * scale + 0.5);
    int lineW = size - 2 * inset;
    unsigned lineColor = 0xa8a8ae;
    int isURL = [item respondsToSelector:@selector(absoluteString)];
    for (int i = 0; i < 3; i++)
    {
        int w = lineW;
        if (i == 2)
            w = lineW * 2 / 3;
        unsigned color = (i == 0 && isURL) ? 0x0a84ff : lineColor;
        iosim_fb_fill_rect(tx + inset, top + i * step, w, lineH, color);
    }
}

static void share_draw_activity_icon(UIActivity *activity, int tx, int ty,
                                     int size, double scale)
{
    UIImage *image = [activity activityImage];
    if (image && image->_rgba && image->_width > 0 && image->_height > 0)
    {
        int inset = (int)(3 * scale + 0.5);
        iosim_fb_blit_rgba_scaled(tx + inset, ty + inset, size - 2 * inset,
                                  size - 2 * inset, image->_rgba,
                                  image->_width, image->_height,
                                  image->_width * 4);
        return;
    }
    id type = [activity activityType];
    int isCopy = type && [type isEqual:UIActivityTypeCopyToPasteboard];
    Class cls = [activity class];
    long category = [cls activityCategory];
    unsigned tile = isCopy ? 0x5b5b61
                           : (category == UIActivityCategoryShare ? 0x2f6df0
                                                                  : 0x5b5b61);
    iosim_fb_fill_round_rect(tx, ty, size, size, (int)(8 * scale + 0.5),
                             tile);
    if (isCopy)
    {
        int bw = (int)(9 * scale + 0.5);
        int bh = (int)(11 * scale + 0.5);
        int pad = (int)(2 * scale + 0.5);
        int unit = (int)(scale + 0.5);
        int backX = tx + size - bw - (int)(9 * scale + 0.5);
        int backY = ty + (int)(8 * scale + 0.5);
        iosim_fb_fill_round_rect(backX, backY, bw, bh, 2 * unit, 0xffffff);
        int frontX = tx + (int)(7 * scale + 0.5);
        int frontY = ty + (int)(12 * scale + 0.5);
        iosim_fb_fill_round_rect(frontX - pad, frontY - pad, bw + 2 * pad,
                                 bh + 2 * pad, 2 * unit, tile);
        iosim_fb_fill_round_rect(frontX, frontY, bw, bh, 2 * unit, 0xffffff);
        return;
    }
    const char *title = iosim_string_cstr([activity activityTitle]);
    char letter[2];
    letter[0] = (title && *title) ? title[0] : '?';
    letter[1] = 0;
    int asc = 0, desc = 0, lh = 0;
    iosim_fb_font_metrics(IOSIM_FONT_BOLD, 16, scale, &asc, &desc, &lh);
    int tw = iosim_fb_font_text_width(letter, IOSIM_FONT_BOLD, 16, scale);
    iosim_fb_font_text(tx + (size - tw) / 2,
                       ty + size / 2 - lh / 2 + asc, letter, IOSIM_FONT_BOLD,
                       16, scale, 0xffffff);
}

static void draw_activity_sheet(UIActivityViewController *controller,
                                int fbW, int fbH, double scale,
                                double progress)
{
    double W = fbW / scale, H = fbH / scale;
    NSArray *activities = [controller _availableActivities];
    int rows = activities ? (int)[activities count] : 0;
    if (rows > 16)
        rows = 16;
    double sheetW = W - 16;
    double sheetH = 182.0 + 58.0 * rows;
    int ix = (int)(8 * scale + 0.5);
    int iw = (int)(sheetW * scale + 0.5);
    int ih = (int)(sheetH * scale + 0.5);
    int iy = (int)((H - 8.0 - sheetH + (1.0 - progress) * sheetH) * scale + 0.5);
    g_share_drawn_controller = controller;
    g_share_sheet_rect[0] = ix;
    g_share_sheet_rect[1] = iy;
    g_share_sheet_rect[2] = ix + iw;
    g_share_sheet_rect[3] = iy + ih;

    iosim_fb_set_opacity(0.47 * progress);
    iosim_fb_fill_rect(0, 0, fbW, fbH, 0x000000);
    iosim_fb_set_opacity(1.0);
    draw_device_chrome(fbW, scale);

    int radius = (int)(34 * scale + 0.5);
    iosim_fb_fill_round_rect(ix, iy, iw, ih, radius, 0x3b3c45);
    iosim_fb_fill_round_rect(ix + 1, iy + 1, iw - 2, ih - 2, radius - 1,
                             0x23242d);
    int grabW = (int)(36 * scale + 0.5);
    int grabH = (int)(5 * scale + 0.5);
    iosim_fb_fill_round_rect(ix + (iw - grabW) / 2,
                             iy + (int)(10 * scale + 0.5), grabW, grabH,
                             grabH / 2, 0x6b6c72);

    id item = nil;
    if (controller->_activityItems &&
        [controller->_activityItems count] > 0)
        item = [controller->_activityItems objectAtIndex:0];
    if ([item respondsToSelector:@selector(activityViewControllerPlaceholderItem:)])
        item = [(id<UIActivityItemSource>)item
            activityViewControllerPlaceholderItem:controller];

    int headerTop = (int)(30 * scale + 0.5);
    int headerH = (int)(64 * scale + 0.5);
    int tileSize = (int)(44 * scale + 0.5);
    int tileX = ix + (int)(20 * scale + 0.5);
    int tileY = iy + headerTop + (headerH - tileSize) / 2;
    share_draw_preview(item, tileX, tileY, tileSize, scale);

    int titleX = ix + (int)(76 * scale + 0.5);
    int titleMax = iw - (int)(76 * scale + 0.5) - (int)(56 * scale + 0.5);
    id titleItem = [item isKindOfClass:[UIImage class]]
                       ? (id)@"Image" : share_string_for_item(item);
    char titleText[256];
    share_text_ellipsis(iosim_string_cstr(titleItem), IOSIM_FONT_SEMIBOLD, 17,
                        scale, titleMax, titleText, sizeof(titleText));
    const char *kind = "Text";
    if ([item isKindOfClass:[UIImage class]])
        kind = "Image";
    else if ([item respondsToSelector:@selector(absoluteString)])
        kind = "URL";
    else if (!item)
        kind = "Item";
    int asc17 = 0, desc17 = 0, lh17 = 0;
    int asc13 = 0, desc13 = 0, lh13 = 0;
    iosim_fb_font_metrics(IOSIM_FONT_SEMIBOLD, 17, scale, &asc17, &desc17,
                          &lh17);
    iosim_fb_font_metrics(IOSIM_FONT_REGULAR, 13, scale, &asc13, &desc13,
                          &lh13);
    int blockH = lh17 + (int)(2 * scale + 0.5) + lh13;
    int blockY = tileY + (tileSize - blockH) / 2;
    iosim_fb_font_text(titleX, blockY + asc17, titleText,
                       IOSIM_FONT_SEMIBOLD, 17, scale, 0xffffff);
    iosim_fb_font_text(titleX,
                       blockY + lh17 + (int)(2 * scale + 0.5) + asc13, kind,
                       IOSIM_FONT_REGULAR, 13, scale, 0x9a9aa1);

    int closeR = (int)(14 * scale + 0.5);
    int closeX = ix + iw - (int)(30 * scale + 0.5);
    int closeY = iy + headerTop + headerH / 2;
    iosim_fb_fill_circle(closeX, closeY, closeR, 0x3a3b44);
    int arm = (int)(4.5 * scale + 0.5);
    int stroke = (int)(1.8 * scale + 0.5);
    if (stroke < 1)
        stroke = 1;
    iosim_fb_draw_line(closeX - arm, closeY - arm, closeX + arm,
                       closeY + arm, stroke, 0xd0d0d6);
    iosim_fb_draw_line(closeX - arm, closeY + arm, closeX + arm,
                       closeY - arm, stroke, 0xd0d0d6);
    g_share_close_rect[0] = closeX - closeR;
    g_share_close_rect[1] = closeY - closeR;
    g_share_close_rect[2] = closeX + closeR;
    g_share_close_rect[3] = closeY + closeR;

    int rowsTop = iy + (int)(106 * scale + 0.5);
    int rowH = (int)(58 * scale + 0.5);
    int iconSize = (int)(32 * scale + 0.5);
    int iconX = ix + (int)(20 * scale + 0.5);
    g_share_row_count = rows;
    for (int i = 0; i < rows; i++)
    {
        UIActivity *activity = (UIActivity *)[activities objectAtIndex:i];
        int ry = rowsTop + i * rowH;
        if (i > 0)
            iosim_fb_fill_rect(ix + (int)(64 * scale + 0.5), ry,
                               iw - (int)(84 * scale + 0.5),
                               (int)(scale + 0.5), 0x3b3c43);
        int iconY = ry + (rowH - iconSize) / 2;
        share_draw_activity_icon(activity, iconX, iconY, iconSize, scale);
        char rowTitle[192];
        share_text_ellipsis(iosim_string_cstr([activity activityTitle]),
                            IOSIM_FONT_REGULAR, 17, scale,
                            iw - (int)(100 * scale + 0.5), rowTitle,
                            sizeof(rowTitle));
        int asc = 0, desc = 0, lh = 0;
        iosim_fb_font_metrics(IOSIM_FONT_REGULAR, 17, scale, &asc, &desc,
                              &lh);
        iosim_fb_font_text(ix + (int)(64 * scale + 0.5),
                           ry + rowH / 2 - lh / 2 + asc, rowTitle,
                           IOSIM_FONT_REGULAR, 17, scale, 0xffffff);
        g_share_row_rects[i][0] = ix;
        g_share_row_rects[i][1] = ry;
        g_share_row_rects[i][2] = ix + iw;
        g_share_row_rects[i][3] = ry + rowH;
    }

    int cancelH = (int)(50 * scale + 0.5);
    int cancelY = iy + (int)((120 + 58 * rows) * scale + 0.5);
    int cancelX = ix + (int)(16 * scale + 0.5);
    int cancelW = iw - (int)(32 * scale + 0.5);
    iosim_fb_fill_round_rect(cancelX, cancelY, cancelW, cancelH,
                             cancelH / 2, 0x404149);
    int asc = 0, desc = 0, lh = 0;
    iosim_fb_font_metrics(IOSIM_FONT_SEMIBOLD, 17, scale, &asc, &desc, &lh);
    int tw = iosim_fb_font_text_width("Cancel", IOSIM_FONT_SEMIBOLD, 17,
                                      scale);
    iosim_fb_font_text(cancelX + (cancelW - tw) / 2,
                       cancelY + cancelH / 2 - lh / 2 + asc, "Cancel",
                       IOSIM_FONT_SEMIBOLD, 17, scale, 0xffffff);
    g_share_cancel_rect[0] = cancelX;
    g_share_cancel_rect[1] = cancelY;
    g_share_cancel_rect[2] = cancelX + cancelW;
    g_share_cancel_rect[3] = cancelY + cancelH;
}

/* ------------------------------------------------- context menu draw */

/* Replaces the pixels outside a preview card's rounded corners with the
 * blurred backdrop captured before the card was drawn. */
static void ctx_clear_preview_corners(unsigned *bg, int fbW, int fbH,
                                      int x, int y, int w, int h,
                                      int radius)
{
    if (!bg || w <= 0 || h <= 0)
        return;
    unsigned *current =
        malloc((unsigned long)fbW * (unsigned long)fbH * sizeof(unsigned));
    if (!current)
        return;
    iosim_fb_capture(0, 0, fbW, fbH, current);
    double exr = w / 2.0 - radius, eyr = h / 2.0 - radius;
    for (int yy = 0; yy < h; yy++)
    {
        int dy = y + yy;
        if (dy < 0 || dy >= fbH)
            continue;
        for (int xx = 0; xx < w; xx++)
        {
            int dx = x + xx;
            if (dx < 0 || dx >= fbW)
                continue;
            double px = xx + 0.5 - w / 2.0;
            double py = yy + 0.5 - h / 2.0;
            double qx = __builtin_fabs(px) - exr;
            double qy = __builtin_fabs(py) - eyr;
            double ax = qx > 0 ? qx : 0, ay = qy > 0 ? qy : 0;
            double outside = __builtin_sqrt(ax * ax + ay * ay);
            double inside = qx > qy ? qx : qy;
            double d = outside + (inside < 0 ? inside : 0) - radius;
            if (d > 0.0)
                current[(unsigned long)dy * fbW + dx] =
                    bg[(unsigned long)dy * fbW + dx];
        }
    }
    iosim_fb_paste_xrgb(current);
    free(current);
}

static void draw_context_menu(int fbW, int fbH, double scale)
{
    if (!g_ctx.active)
        return;
    double W = fbW / scale, H = fbH / scale;
    ctx_compute_frames(W, H);

    unsigned *bg =
        malloc((unsigned long)fbW * (unsigned long)fbH * sizeof(unsigned));
    if (bg)
    {
        iosim_fb_capture(0, 0, fbW, fbH, bg);
        blur_box_xrgb(bg, fbW, fbH, (int)(20 * scale + 0.5), 2);
        iosim_fb_paste_xrgb(bg);
        iosim_fb_set_opacity(0.22);
        iosim_fb_fill_rect(0, 0, fbW, fbH, 0);
        iosim_fb_set_opacity(1.0);
        iosim_fb_capture(0, 0, fbW, fbH, bg);
    }
    draw_device_chrome(fbW, scale);

    CGRect preview = g_ctx.previewFrame;
    int px = (int)(preview.origin.x * scale + 0.5);
    int py = (int)(preview.origin.y * scale + 0.5);
    int pw = (int)(preview.size.width * scale + 0.5);
    int ph = (int)(preview.size.height * scale + 0.5);
    int previewRadius = (int)(14 * scale + 0.5);
    int shadowOffset = (int)(4 * scale + 0.5);
    iosim_fb_set_opacity(0.32);
    iosim_fb_fill_round_rect(px + shadowOffset / 2, py + shadowOffset,
                             pw - shadowOffset, ph, previewRadius,
                             0x000000);
    iosim_fb_set_opacity(1.0);
    iosim_fb_fill_round_rect(px, py, pw, ph, previewRadius, 0x1c1c1e);

    if (g_ctx.previewKind == 1 && g_ctx.previewController)
    {
        UIView *view = [g_ctx.previewController view];
        if (view)
        {
            view->_frame = CGRectMake(0, 0, preview.size.width,
                                      preview.size.height);
            render_view(view, preview.origin.x, preview.origin.y, scale, 1.0);
        }
    }
    else if (g_ctx.previewKind == 2 && g_ctx.cell)
    {
        UIView *cell = g_ctx.cell;
        CGRect savedFrame = cell->_frame;
        UIColor *savedBackground = cell->_backgroundColor;
        cell->_frame = CGRectMake(0, 0, preview.size.width,
                                  preview.size.height);
        if (!savedBackground)
            cell->_backgroundColor =
                [UIColor colorWithRed:0.11 green:0.11 blue:0.12 alpha:1.0];
        render_view(cell, preview.origin.x, preview.origin.y, scale, 1.0);
        cell->_backgroundColor = savedBackground;
        cell->_frame = savedFrame;
    }
    else if (g_ctx.snapshot)
    {
        iosim_fb_blit_xrgb_scaled(g_ctx.snapshot, g_ctx.snapshotW,
                                  g_ctx.snapshotH, px, py, pw, ph, 1.0);
    }
    if (bg)
        ctx_clear_preview_corners(bg, fbW, fbH, px, py, pw, ph,
                                  previewRadius);

    CGRect menu = g_ctx.menuFrame;
    int mx = (int)(menu.origin.x * scale + 0.5);
    int my = (int)(menu.origin.y * scale + 0.5);
    int mw = (int)(menu.size.width * scale + 0.5);
    int mh = (int)(menu.size.height * scale + 0.5);
    int menuRadius = (int)(22 * scale + 0.5);
    iosim_fb_fill_round_rect(mx, my, mw, mh, menuRadius, 0x3f4048);
    iosim_fb_fill_round_rect(mx + 1, my + 1, mw - 2, mh - 2, menuRadius - 1,
                             0x23242d);

    int cursor = my + (int)(8 * scale + 0.5);
    int rowH = (int)(46 * scale + 0.5);
    int headerH = (int)(28 * scale + 0.5);
    int textX = mx + (int)(18 * scale + 0.5);
    g_ctx.rowCount = 0;
    int previousWasAction = 0;
    for (int i = 0; i < g_ctx.entryCount; i++)
    {
        ctx_entry *entry = &g_ctx.entries[i];
        if (!entry->action)
        {
            const char *header = iosim_string_cstr(entry->header);
            int asc = 0, desc = 0, lh = 0;
            iosim_fb_font_metrics(IOSIM_FONT_REGULAR, 13, scale, &asc, &desc,
                                  &lh);
            iosim_fb_font_text(textX, cursor + headerH / 2 - lh / 2 + asc,
                               header, IOSIM_FONT_REGULAR, 13, scale,
                               0x9a9aa1);
            cursor += headerH;
            previousWasAction = 0;
            continue;
        }
        UIAction *action = entry->action;
        int rowY = cursor;
        if (previousWasAction)
            iosim_fb_fill_rect(textX, rowY, mw - 2 * (textX - mx),
                               (int)(scale + 0.5), 0x3a3b42);
        int titleX = textX;
        UIImage *image = action->_image;
        if (image && image->_rgba && image->_width > 0)
        {
            int iconSize = (int)(24 * scale + 0.5);
            iosim_fb_blit_rgba_scaled(mx + (int)(16 * scale + 0.5),
                                      rowY + (rowH - iconSize) / 2, iconSize,
                                      iconSize, image->_rgba, image->_width,
                                      image->_height, image->_width * 4);
            titleX = mx + (int)(52 * scale + 0.5);
        }
        unsigned color = 0xffffff;
        if (action->_attributes & UIMenuElementAttributesDestructive)
            color = 0xff453a;
        else if (action->_attributes & UIMenuElementAttributesDisabled)
            color = 0x7c7c82;
        char title[192];
        share_text_ellipsis(iosim_string_cstr(action->_title),
                            IOSIM_FONT_REGULAR, 17, scale,
                            mx + mw - (int)(16 * scale + 0.5) - titleX,
                            title, sizeof(title));
        int asc = 0, desc = 0, lh = 0;
        iosim_fb_font_metrics(IOSIM_FONT_REGULAR, 17, scale, &asc, &desc,
                              &lh);
        iosim_fb_font_text(titleX, rowY + rowH / 2 - lh / 2 + asc, title,
                           IOSIM_FONT_REGULAR, 17, scale, color);
        if (g_ctx.rowCount < CTX_MAX_ENTRIES)
        {
            g_ctx.rowRects[g_ctx.rowCount][0] = mx;
            g_ctx.rowRects[g_ctx.rowCount][1] = rowY;
            g_ctx.rowRects[g_ctx.rowCount][2] = mx + mw;
            g_ctx.rowRects[g_ctx.rowCount][3] = rowY + rowH;
            g_ctx.rowEntries[g_ctx.rowCount] = i;
            g_ctx.rowCount++;
        }
        cursor += rowH;
        previousWasAction = 1;
    }
    if (bg)
        free(bg);
}

static void draw_modals(UIViewController *root, int fbW, int fbH,
                        double scale)
{
    draw_edit_menu(fbW, scale);
    double screen_height = fbH / scale;
    if (g_modal_animating == -1 && g_modal_dismissing_controller)
    {
        double progress = modal_progress();
        if ([(UIViewController *)g_modal_dismissing_controller
                isKindOfClass:[UIActivityViewController class]])
        {
            g_share_presenter = root;
            draw_activity_sheet(
                (UIActivityViewController *)g_modal_dismissing_controller,
                fbW, fbH, scale, 1.0 - progress);
            return;
        }
        UIView *view = [(UIViewController *)g_modal_dismissing_controller view];
        if (view)
        {
            iosim_fb_set_opacity(0.47 * (1.0 - progress));
            iosim_fb_fill_rect(0, 0, fbW, fbH, 0);
            iosim_fb_set_opacity(1.0);
            render_view(view, 0, progress * screen_height, scale, 1.0);
        }
        return;
    }
    if (!root || !root->_presentedController)
        return;
    UIViewController *top = top_presented(root);
    if (!top)
        return;
    if ([top isKindOfClass:[UIAlertController class]])
        draw_alert((UIAlertController *)top, fbW, fbH, scale);
    else if ([top isKindOfClass:[UIActivityViewController class]])
    {
        double progress = 1.0;
        if (g_modal_animating == 1 && g_modal_anim_controller == top)
            progress = modal_progress();
        g_share_presenter = root;
        draw_activity_sheet((UIActivityViewController *)top, fbW, fbH, scale,
                            progress);
    }
    else
    {
        UIView *view = [top view];
        if (!view)
            return;
        double progress = 1.0;
        if (g_modal_animating == 1 && g_modal_anim_controller == top)
            progress = modal_progress();
        if (top->_modalPresentationStyle != 0 /* not full screen */)
        {
            iosim_fb_set_opacity(0.47 * progress);
            iosim_fb_fill_rect(0, 0, fbW, fbH, 0);
            iosim_fb_set_opacity(1.0);
        }
        render_view(view, 0, (1.0 - progress) * screen_height, scale, 1.0);
    }
}

static int alert_handle_tap(UIViewController *root, int px, int py, int fbW,
                            int fbH, double scale)
{
    if (!root || !root->_presentedController)
        return 0;
    UIViewController *top = top_presented(root);
    if (!top || ![top isKindOfClass:[UIAlertController class]])
        return 0;
    UIAlertController *alert = (UIAlertController *)top;
    struct alert_layout layout;
    alert_compute_layout(alert, fbW, fbH, scale, &layout);
    double tapX = px / scale, tapY = py / scale;
    int action = -1;
    for (int r = 0; r < layout.row_count; r++)
    {
        if (tapX >= layout.row_x[r] &&
            tapX <= layout.row_x[r] + layout.row_w[r] &&
            tapY >= layout.row_y[r] &&
            tapY <= layout.row_y[r] + layout.row_h)
            action = layout.row_action[r];
    }
    if (action < 0 && layout.cancel_action >= 0 &&
        tapX >= layout.cancel_x &&
        tapX <= layout.cancel_x + layout.cancel_w &&
        tapY >= layout.cancel_y &&
        tapY <= layout.cancel_y + layout.cancel_h)
        action = layout.cancel_action;
    if (action >= 0 && action < alert->_actionCount)
    {
        UIAlertAction *a = alert->_actions[action];
        if (a && a->_handler)
            a->_handler(a);
        [root dismissViewControllerAnimated:NO completion:nil];
        return 1;
    }
    int inside_group =
        tapX >= layout.group_x && tapX <= layout.group_x + layout.width &&
        tapY >= layout.group_y && tapY <= layout.group_y + layout.group_h;
    int inside_cancel =
        layout.cancel_action >= 0 && tapX >= layout.cancel_x &&
        tapX <= layout.cancel_x + layout.cancel_w &&
        tapY >= layout.cancel_y && tapY <= layout.cancel_y + layout.cancel_h;
    if (layout.sheet && !inside_group && !inside_cancel)
        [root dismissViewControllerAnimated:NO completion:nil];
    return 1;
}

static void share_dismiss_cancel(UIActivityViewController *controller,
                                 UIViewController *presenter)
{
    if (controller->_completionWithItemsHandler)
        controller->_completionWithItemsHandler(nil, NO, nil, nil);
    else if (controller->_completionHandler)
        controller->_completionHandler(nil, NO);
    g_active_share_controller = nil;
    g_share_presenter = nil;
    if (presenter && presenter->_presentedController == controller)
        [presenter dismissViewControllerAnimated:YES completion:nil];
}

/* Returns 1 when the tap belonged to the share sheet (a row, the cancel or
 * close button, the card itself, or the dimmed area that cancels it). */
static int activity_sheet_handle_tap(UIViewController *root, int px, int py,
                                     int fbW, int fbH, double scale)
{
    (void)fbW;
    (void)fbH;
    (void)scale;
    if (g_modal_animating == -1 && g_modal_dismissing_controller &&
        [(UIViewController *)g_modal_dismissing_controller
            isKindOfClass:[UIActivityViewController class]])
        return 1;
    if (!root || !root->_presentedController)
        return 0;
    UIViewController *top = top_presented(root);
    if (!top || ![top isKindOfClass:[UIActivityViewController class]])
        return 0;
    UIActivityViewController *controller = (UIActivityViewController *)top;
    g_share_presenter = root;
    if (g_share_drawn_controller == controller)
    {
        if (px >= g_share_close_rect[0] && px < g_share_close_rect[2] &&
            py >= g_share_close_rect[1] && py < g_share_close_rect[3])
        {
            share_dismiss_cancel(controller, root);
            return 1;
        }
        if (px >= g_share_cancel_rect[0] && px < g_share_cancel_rect[2] &&
            py >= g_share_cancel_rect[1] && py < g_share_cancel_rect[3])
        {
            share_dismiss_cancel(controller, root);
            return 1;
        }
        for (int i = 0; i < g_share_row_count; i++)
        {
            if (px >= g_share_row_rects[i][0] &&
                px < g_share_row_rects[i][2] &&
                py >= g_share_row_rects[i][1] &&
                py < g_share_row_rects[i][3])
            {
                UIActivity *activity = (UIActivity *)
                    [[controller _availableActivities] objectAtIndex:i];
                if (!activity)
                    return 1;
                g_active_share_controller = controller;
                [activity prepareWithActivityItems:controller->_activityItems];
                [activity performActivity];
                return 1;
            }
        }
        if (px >= g_share_sheet_rect[0] && px < g_share_sheet_rect[2] &&
            py >= g_share_sheet_rect[1] && py < g_share_sheet_rect[3])
            return 1;
    }
    share_dismiss_cancel(controller, root);
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
                                 int requestSwitcher, int requestLock)
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

    if (app->_backgroundTasks && [app->_backgroundTasks count] > 0)
    {
        app->_backgroundTaskDeadline = iosim_now() + 5.0;
        printf("[UIKit-lite] background task window open\n");
        fflush(0);
        while ([app->_backgroundTasks count] > 0 &&
               iosim_now() < app->_backgroundTaskDeadline)
            usleep(20000);
        if ([app->_backgroundTasks count] > 0)
        {
            NSArray *pending =
                [NSArray arrayWithArray:app->_backgroundTasks];
            for (unsigned long i = 0; i < [pending count]; i++)
            {
                id handler = [[pending objectAtIndex:i] objectAtIndex:1];
                if (handler != [NSNull null])
                    ((void (^)(void))handler)();
            }
            [(NSMutableArray *)app->_backgroundTasks removeAllObjects];
        }
        app->_backgroundTaskDeadline = 0;
        printf("[UIKit-lite] background task window closed\n");
        fflush(0);
    }
    printf("[UIKit-lite] backgrounded by the system; suspending\n");
    fflush(0);
    if (requestSwitcher)
        iosim_request_switcher();
    if (requestLock)
        iosim_request_lock();
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

@implementation UIView (IOSIMSnapshot)
- (UIView *)snapshotViewAfterScreenUpdates:(BOOL)afterUpdates
{
    (void)afterUpdates;
    CGRect frame = [self frame];
    double scale = [[UIScreen mainScreen] scale];
    if (scale <= 0)
        scale = 1.0;
    int w = (int)(frame.size.width * scale + 0.5);
    int h = (int)(frame.size.height * scale + 0.5);
    if (w <= 0 || h <= 0)
        return nil;
    void *state = iosim_fb_begin_offscreen((unsigned)w, (unsigned)h);
    if (!state)
        return nil;
    render_view(self, -frame.origin.x, -frame.origin.y, scale, 1.0);
    int bw = 0, bh = 0;
    unsigned *buf = iosim_fb_end_offscreen(state, &bw, &bh);
    if (!buf || bw <= 0 || bh <= 0)
    {
        if (buf)
            iosim_fb_free_offscreen(buf);
        return nil;
    }
    unsigned char *rgba = malloc((unsigned long)bw * (unsigned long)bh * 4);
    if (!rgba)
    {
        iosim_fb_free_offscreen(buf);
        return nil;
    }
    for (int i = 0; i < bw * bh; i++)
    {
        unsigned pixel = buf[i];
        rgba[i * 4 + 0] = (unsigned char)((pixel >> 16) & 255);
        rgba[i * 4 + 1] = (unsigned char)((pixel >> 8) & 255);
        rgba[i * 4 + 2] = (unsigned char)(pixel & 255);
        rgba[i * 4 + 3] = (unsigned char)((pixel >> 24) & 255);
    }
    iosim_fb_free_offscreen(buf);
    CGImageRef image = CGImageCreateWithRGBA(rgba, bw, bh);
    free(rgba);
    if (!image)
        return nil;
    UIImage *ui_image = [UIImage imageWithCGImage:image];
    CGImageRelease(image);
    if (!ui_image)
        return nil;
    UIImageView *snapshot = [[UIImageView alloc] initWithImage:ui_image];
    snapshot.frame = CGRectMake(0, 0, frame.size.width, frame.size.height);
    snapshot.layer.contentsScale = scale;
    snapshot.userInteractionEnabled = NO;
    return snapshot;
}
- (BOOL)drawViewHierarchyInRect:(CGRect)rect
             afterScreenUpdates:(BOOL)afterUpdates
{
    (void)afterUpdates;
    CGContextRef context = iosim_cg_current();
    if (!context)
        return NO;
    CGRect frame = [self frame];
    double scale = [[UIScreen mainScreen] scale];
    if (scale <= 0)
        scale = 1.0;
    int w = (int)(frame.size.width * scale + 0.5);
    int h = (int)(frame.size.height * scale + 0.5);
    if (w <= 0 || h <= 0)
        return NO;
    void *state = iosim_fb_begin_offscreen((unsigned)w, (unsigned)h);
    if (!state)
        return NO;
    render_view(self, -frame.origin.x, -frame.origin.y, scale, 1.0);
    int bw = 0, bh = 0;
    unsigned *buf = iosim_fb_end_offscreen(state, &bw, &bh);
    if (!buf || bw <= 0 || bh <= 0)
    {
        if (buf)
            iosim_fb_free_offscreen(buf);
        return NO;
    }
    unsigned char *rgba = malloc((unsigned long)bw * (unsigned long)bh * 4);
    if (!rgba)
    {
        iosim_fb_free_offscreen(buf);
        return NO;
    }
    for (int i = 0; i < bw * bh; i++)
    {
        unsigned pixel = buf[i];
        rgba[i * 4 + 0] = (unsigned char)((pixel >> 16) & 255);
        rgba[i * 4 + 1] = (unsigned char)((pixel >> 8) & 255);
        rgba[i * 4 + 2] = (unsigned char)(pixel & 255);
        rgba[i * 4 + 3] = (unsigned char)((pixel >> 24) & 255);
    }
    iosim_fb_free_offscreen(buf);
    CGImageRef image = CGImageCreateWithRGBA(rgba, bw, bh);
    free(rgba);
    if (!image)
        return NO;
    CGContextDrawImage(context, rect, image);
    CGImageRelease(image);
    return YES;
}
@end

int UIApplicationMain(int argc, char **argv, id principal, id delegateName)
{
    (void)principal;
    (void)argv;
    const char *shellMode = getenv("IOSIM_SHELL");
    if (shellMode && *shellMode)
        return run_springboard();

    /* The device appearance is shared with SpringBoard; resolve it before
     * any view is built so dynamic colors draw with the right style. */
    g_ui_style = ui_appearance_read_file();
    apply_status_bar_plist();

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
    if (!g_connectedScenes)
        g_connectedScenes = [NSMutableArray array];
    [g_connectedScenes addObject:scene];
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
    g_app_root_controller = rootController;
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
    draw_context_menu(fbWidth, fbHeight, scale);

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
        int contextSwallowedDown = 0;
        int requestSwitcher = 0;
        double screenHeightPt = fbHeight / scale;
        while ((r = iosim_event_next(&type, &x, &y)) != 0)
        {
            int redraw = 0;
            if (g_status_bar_dirty)
            {
                g_status_bar_dirty = 0;
                redraw = 1;
            }
            if (r == 1 && type == 1)
            {
                if (context_menu_handle_tap(x, y))
                    redraw = 1;
                else if (edit_menu_handle_tap(x, y))
                    redraw = 1;
                else if (alert_handle_tap(rootController, x, y, fbWidth, fbHeight,
                                     scale))
                    redraw = 1;
                else if (activity_sheet_handle_tap(rootController, x, y, fbWidth,
                                                   fbHeight, scale))
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
            else if (r == 1 && type == 18)
            {
                /* The foreground app owns the event stream, so it records
                 * the new device appearance for SpringBoard and itself. */
                int dark = x != 0;
                ui_appearance_write_file(dark);
                ui_apply_style(dark);
                redraw = 1;
            }
            else if (r == 1 && type >= 20 && type <= 23)
            {
                int ident = iosim_event_touch_id();
                CGPoint point = CGPointMake(x / scale, y / scale);
                if (type == 20)
                    [window beginMultiTouch:ident atPoint:point];
                else if (type == 21)
                    [window moveMultiTouch:ident toPoint:point];
                else
                    [window endMultiTouch:ident atPoint:point
                                 cancelled:type == 23];
                redraw = 1;
            }
            else if (r == 1 && type >= 12 && type <= 17)
            {
                int secondX = 0, secondY = 0;
                iosim_event_second_point(&secondX, &secondY);
                double x1 = x / scale;
                double y1 = y / scale;
                double x2 = secondX / scale;
                double y2 = secondY / scale;
                BOOL rotationOnly = type >= 15;
                if (type == 12 || type == 15)
                    [window beginTwoFingerX1:x1 y1:y1 x2:x2 y2:y2
                               rotationOnly:rotationOnly];
                else if (type == 13 || type == 16)
                    [window moveTwoFingerX1:x1 y1:y1 x2:x2 y2:y2];
                else
                    [window endTwoFingerX1:x1 y1:y1 x2:x2 y2:y2];
                redraw = 1;
            }
            else if (r == 1 && type == 2)
            {
                if (g_ctx.active)
                {
                    /* A touch outside the menu dismisses it; the touch is
                     * consumed rather than reaching the view beneath. */
                    context_menu_dismiss();
                    contextSwallowedDown = 1;
                    haveTouchDown = 0;
                    redraw = 1;
                }
                else
                {
                    touchDownX = x / scale;
                    touchDownY = y / scale;
                    haveTouchDown = 1;
                    [window dispatchTouchDownX:x y:y];
                    redraw = 1;
                }
            }
            else if (r == 1 && type == 3)
            {
                if (!g_ctx.active && !contextSwallowedDown)
                {
                    [window dispatchTouchMoveX:x y:y];
                    redraw = 1;
                }
            }
            else if (r == 1 && type == 4)
            {
                if (g_ctx.active && g_ctx.ignoreUp)
                {
                    g_ctx.ignoreUp = 0;
                    [window dispatchTouchUpX:x y:y];
                    redraw = 1;
                    continue;
                }
                if (g_ctx.active || contextSwallowedDown)
                {
                    context_menu_dismiss();
                    contextSwallowedDown = 0;
                    redraw = 1;
                    continue;
                }
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
                app_enter_background(sceneDelegate, scene, 0, 0);
                redraw = 1;
            }
            else if (r == 1 && type == 10)
            {
                /* The device locked while this app was foreground: the
                 * system background it and shows the lock screen. */
                haveTouchDown = 0;
                requestSwitcher = 0;
                app_enter_background(sceneDelegate, scene, 0, 1);
                redraw = 1;
            }
            if (requestSwitcher)
            {
                requestSwitcher = 0;
                app_enter_background(sceneDelegate, scene, 1, 0);
                redraw = 1;
            }
            if ([window tickGestureRecognizers])
                redraw = 1;
            if (iosim_text_press_tick())
                redraw = 1;
            if (iosim_foundation_tick())
                redraw = 1;
            iosim_pasteboard_tick();
            if (iosim_dispatch_drain_main())
                redraw = 1;
            if (iosim_display_link_tick())
                redraw = 1;
            if (iosim_animation_tick())
                redraw = 1;
            if (iosim_ui_appearance_tick())
                redraw = 1;
            if (iosim_modal_tick())
                redraw = 1;
            if (iosim_nav_tick())
                redraw = 1;
            if (iosim_scroll_tick())
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
            draw_context_menu(fbWidth, fbHeight, scale);
            if (path && *path)
                iosim_fb_present(path);
        }
    }
    return 0;
}
