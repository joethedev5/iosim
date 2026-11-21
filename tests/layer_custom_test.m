/* +[UIView layerClass] backing a view with CAGradientLayer, plus
 * animationKeys / animationForKey: / removeAllAnimations. */
#include "UIKitStub.h"

extern int printf(const char *fmt, ...);
extern int fflush(void *stream);

@interface GradientView : UIView
@end

@implementation GradientView
+ (Class)layerClass { return [CAGradientLayer class]; }
@end

@interface CustomLayerController : UIViewController
@end

@implementation CustomLayerController
- (void)loadView
{
    UIView *root =
        [[UIView alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    root.backgroundColor = [UIColor blackColor];

    GradientView *gradient =
        [[GradientView alloc] initWithFrame:CGRectMake(50, 300, 200, 100)];
    CAGradientLayer *layer = (CAGradientLayer *)gradient.layer;
    layer.colors = [NSArray arrayWithObjects:
        (id)[UIColor redColor].CGColor,
        (id)[UIColor blueColor].CGColor, nil];
    layer.startPoint = CGPointMake(0, 0.5);
    layer.endPoint = CGPointMake(1, 0.5);
    [root addSubview:gradient];
    printf("[layer] custom %d colors %lu\n",
           [gradient.layer isKindOfClass:[CAGradientLayer class]] ? 1 : 0,
           (unsigned long)[layer.colors count]);

    UIView *box = [[UIView alloc] initWithFrame:CGRectMake(50, 450, 100, 100)];
    box.backgroundColor = [UIColor greenColor];
    [root addSubview:box];

    CAAnimation *fade = [CABasicAnimation animationWithKeyPath:@"opacity"];
    fade.duration = 2.0;
    fade.fromValue = [NSNumber numberWithDouble:1.0];
    fade.toValue = [NSNumber numberWithDouble:0.5];
    [box.layer addAnimation:fade forKey:@"fade"];
    CAAnimation *move = [CABasicAnimation animationWithKeyPath:@"position"];
    move.duration = 2.0;
    [box.layer addAnimation:move forKey:@"move"];
    printf("[layer] keys %lu %d\n",
           (unsigned long)[[box.layer animationKeys] count],
           [box.layer animationForKey:@"fade"] != nil ? 1 : 0);
    [box.layer removeAllAnimations];
    printf("[layer] after %lu %d\n",
           (unsigned long)[[box.layer animationKeys] count],
           [box.layer animationForKey:@"fade"] == nil ? 1 : 0);

    self.view = root;
    printf("[layer] ready\n");
    fflush(0);
}
@end

@interface CustomLayerSceneDelegate : UIResponder <UIWindowSceneDelegate>
@property(nonatomic, retain) UIWindow *window;
@end

@interface CustomLayerAppDelegate : UIResponder <UIApplicationDelegate>
@end

@implementation CustomLayerAppDelegate
- (UISceneConfiguration *)application:(UIApplication *)application
    configurationForConnectingSceneSession:(UISceneSession *)session
    options:(UISceneConnectionOptions *)connectionOptions
{
    (void)application; (void)session; (void)connectionOptions;
    UISceneConfiguration *configuration = [[UISceneConfiguration alloc]
        initWithName:@"Default Configuration"
         sessionRole:UIWindowSceneSessionRoleApplication];
    configuration.delegateClass = [CustomLayerSceneDelegate class];
    return configuration;
}
@end

@implementation CustomLayerSceneDelegate
- (void)scene:(UIScene *)scene
    willConnectToSession:(UISceneSession *)session
                 options:(UISceneConnectionOptions *)connectionOptions
{
    (void)session; (void)connectionOptions;
    self.window = [[UIWindow alloc] initWithWindowScene:(UIWindowScene *)scene];
    self.window.frame = [[UIScreen mainScreen] bounds];
    self.window.rootViewController = [[CustomLayerController alloc] init];
    [self.window makeKeyAndVisible];
}
@end

int main(int argc, char **argv)
{
    @autoreleasepool
    {
        return UIApplicationMain(argc, argv, nil, @"CustomLayerAppDelegate");
    }
}
