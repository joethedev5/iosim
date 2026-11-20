#ifndef IOSIM_UIKIT_STUB_H
#define IOSIM_UIKIT_STUB_H

#include "../frameworks/objc_lite.h"

__attribute__((objc_root_class))
@interface NSObject
+ (id)alloc;
- (id)init;
- (id)retain;
- (void)release;
- (id)autorelease;
@end

@interface UIResponder : NSObject
@end

@protocol UIApplicationDelegate
@end

@interface CALayer : NSObject
@property double cornerRadius;
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
@property(nonatomic) UIColor *backgroundColor;
@property(readonly) CALayer *layer;
- (void)addSubview:(UIView *)view;
@end

@interface UILabel : UIView
@property(nonatomic) id text;
@property(nonatomic) UIColor *textColor;
@property(nonatomic) UIFont *font;
@property int textAlignment;
@end

@interface UIWindow : UIView
- (void)makeKeyAndVisible;
@end

@interface UIApplication : UIResponder
@end

extern int UIApplicationMain(int argc, char **argv, id principal,
                             id delegateName);

#endif
