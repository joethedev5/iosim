/* CAGradientLayer type = radial: red center fading to blue at the radius,
 * including a rounded variant. */
#include "UIKitStub.h"

extern int printf(const char *fmt, ...);
extern int fflush(void *stream);

@interface RadialController : UIViewController
- (void)checkScene;
@end

@implementation RadialController
- (void)loadView
{
    UIView *root =
        [[UIView alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    root.backgroundColor = [UIColor blackColor];

    CAGradientLayer *radial = [[CAGradientLayer alloc] init];
    radial.frame = CGRectMake(100, 300, 200, 200);
    radial.type = @"radial";
    radial.startPoint = CGPointMake(0.5, 0.5);
    radial.endPoint = CGPointMake(1.0, 0.5);
    radial.colors = [NSArray arrayWithObjects:
        (id)[UIColor redColor].CGColor,
        (id)[UIColor blueColor].CGColor, nil];
    [root.layer addSublayer:radial];

    CAGradientLayer *rounded = [[CAGradientLayer alloc] init];
    rounded.frame = CGRectMake(100, 550, 200, 200);
    rounded.type = @"radial";
    rounded.cornerRadius = 40;
    rounded.startPoint = CGPointMake(0.5, 0.5);
    rounded.endPoint = CGPointMake(1.0, 0.5);
    rounded.colors = [NSArray arrayWithObjects:
        (id)[UIColor yellowColor].CGColor,
        (id)[UIColor purpleColor].CGColor, nil];
    [root.layer addSublayer:rounded];

    self.view = root;
    [NSTimer scheduledTimerWithTimeInterval:0.2 target:self
        selector:@selector(checkScene) userInfo:nil repeats:NO];
    printf("[radial] ready\n");
    fflush(0);
}
- (void)checkScene
{
    UIApplication *app = [UIApplication sharedApplication];
    UIWindow *window = [UIWindow keyWindow];
    window.windowLevel = UIWindowLevelAlert;
    printf("[radial] scene %d windows %lu key %d scenes %lu level %.0f\n",
           [window windowScene] != nil,
           (unsigned long)[[app windows] count],
           [app keyWindow] == window,
           (unsigned long)[[app connectedScenes] count],
           window.windowLevel);
    fflush(0);
}
@end

@interface RadialSceneDelegate : UIResponder <UIWindowSceneDelegate>
@property(nonatomic, retain) UIWindow *window;
@end

@interface RadialAppDelegate : UIResponder <UIApplicationDelegate>
@end

@implementation RadialAppDelegate
- (UISceneConfiguration *)application:(UIApplication *)application
    configurationForConnectingSceneSession:(UISceneSession *)session
    options:(UISceneConnectionOptions *)connectionOptions
{
    (void)application; (void)session; (void)connectionOptions;
    UISceneConfiguration *configuration = [[UISceneConfiguration alloc]
        initWithName:@"Default Configuration"
         sessionRole:UIWindowSceneSessionRoleApplication];
    configuration.delegateClass = [RadialSceneDelegate class];
    return configuration;
}
@end

@implementation RadialSceneDelegate
- (void)scene:(UIScene *)scene
    willConnectToSession:(UISceneSession *)session
                 options:(UISceneConnectionOptions *)connectionOptions
{
    (void)session; (void)connectionOptions;
    self.window = [[UIWindow alloc] initWithWindowScene:(UIWindowScene *)scene];
    self.window.frame = [[UIScreen mainScreen] bounds];
    self.window.rootViewController = [[RadialController alloc] init];
    [self.window makeKeyAndVisible];
}
@end

int main(int argc, char **argv)
{
    @autoreleasepool
    {
        return UIApplicationMain(argc, argv, nil, @"RadialAppDelegate");
    }
}
