#ifndef IOSIM_UIKIT_STUB_H
#define IOSIM_UIKIT_STUB_H

#include "../frameworks/objc_lite.h"

__attribute__((objc_root_class))
@interface NSObject
+ (id)alloc;
+ (Class)class;
- (id)init;
- (id)retain;
- (void)release;
- (id)autorelease;
@end

@interface UIResponder : NSObject
@end

@class UIApplication;
@class UISceneConfiguration;
@class UISceneSession;
@class UISceneConnectionOptions;
@class UIScene;
@class UIWindowScene;

@protocol UIApplicationDelegate
@optional
- (UISceneConfiguration *)application:(UIApplication *)application
    configurationForConnectingSceneSession:(UISceneSession *)session
    options:(UISceneConnectionOptions *)options;
@end

@protocol UIWindowSceneDelegate
@optional
- (void)scene:(UIScene *)scene
    willConnectToSession:(UISceneSession *)session
    options:(UISceneConnectionOptions *)connectionOptions;
@end

@interface CALayer : NSObject
@property double cornerRadius;
@property double opacity;
- (void)addSublayer:(CALayer *)layer;
@end

@interface UIColor : NSObject
+ (UIColor *)colorWithRed:(double)r green:(double)g blue:(double)b
                    alpha:(double)a;
+ (UIColor *)whiteColor;
+ (UIColor *)blackColor;
+ (UIColor *)systemBlueColor;
@end

@interface UIFont : NSObject
+ (UIFont *)systemFontOfSize:(double)size;
+ (UIFont *)boldSystemFontOfSize:(double)size;
@end

@interface UIScreen : NSObject
+ (UIScreen *)mainScreen;
- (CGRect)bounds;
@end

@interface UIView : UIResponder
- (id)initWithFrame:(CGRect)frame;
@property CGRect frame;
@property double alpha;
@property(nonatomic, retain) UIColor *backgroundColor;
@property(readonly) CALayer *layer;
- (void)addSubview:(UIView *)view;
+ (void)animateWithDuration:(double)duration animations:(void (^)(void))animations;
@end

@interface UILabel : UIView
@property(nonatomic, retain) id text;
@property(nonatomic, retain) UIColor *textColor;
@property(nonatomic, retain) UIFont *font;
@property int textAlignment;
@end

@interface UIViewController : NSObject
- (id)init;
@property(nonatomic, retain) UIView *view;
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

@interface UIControl : UIView
- (void)addTarget:(id)target action:(SEL)action
    forControlEvents:(unsigned long)events;
@end

@interface UIButton : UIControl
+ (id)buttonWithType:(int)type;
- (void)setTitle:(id)title forState:(unsigned long)state;
- (void)setTitleColor:(UIColor *)color forState:(unsigned long)state;
@end

@interface UIScene : NSObject
@end

@interface UIWindowScene : UIScene
@end

@interface UISceneSession : NSObject
@end

@interface UISceneConnectionOptions : NSObject
@end

@interface UISceneConfiguration : NSObject
- (id)initWithName:(id)name sessionRole:(id)role;
@property(nonatomic) Class delegateClass;
@end

extern id UIWindowSceneSessionRoleApplication;

@interface UIWindow : UIView
@property(nonatomic, retain) UIViewController *rootViewController;
- (id)initWithWindowScene:(UIWindowScene *)scene;
- (void)makeKeyAndVisible;
@end

@interface UIApplication : UIResponder
@end

extern int UIApplicationMain(int argc, char **argv, id principal,
                             id delegateName);

#endif

@interface UIBezierPath : NSObject
+ (instancetype)bezierPath;
- (void)moveToPoint:(CGPoint)point;
- (void)addLineToPoint:(CGPoint)point;
@end

@interface CAShapeLayer : CALayer
@property(nonatomic, retain) UIBezierPath *path;
@property(nonatomic, retain) UIColor *fillColor;
@property(nonatomic, retain) UIColor *strokeColor;
@property double lineWidth;
@end

@interface CAGradientLayer : CALayer
@property(nonatomic, retain) id colors;
@property CGPoint startPoint;
@property CGPoint endPoint;
@end

@interface UIImage : NSObject
+ (UIImage *)imageNamed:(NSString *)name;
@end

@interface UIImageView : UIView
- (instancetype)initWithImage:(UIImage *)image;
@property(nonatomic, retain) UIImage *image;
@property int contentMode;
@end
