/* CAGradientLayer multi-stop fills: explicit locations, default even
 * spacing and the rounded-corner offscreen path. Colors are CGColorRefs in
 * the first and third layers (the UIKit contract) and UIColor objects in the
 * second, which the renderer also accepts. */
#include "UIKitStub.h"

extern int printf(const char *fmt, ...);
extern int fflush(void *stream);
extern int iosim_fb_present(const char *path);
extern char *getenv(const char *name);
extern void exit(int status);

@interface GradientCaptureView : UIView
@end

@implementation GradientCaptureView
- (void)drawRect:(CGRect)rect
{
    (void)rect;
    const char *path = getenv("IOSIM_TEST_PNG");
    if (!path)
        return;
    iosim_fb_present(path);
    printf("[grad] png written\n");
    fflush(0);
    exit(0);
}
@end

@interface GradientController : UIViewController
@end

@implementation GradientController
- (void)loadView
{
    UIView *root =
        [[UIView alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    root.backgroundColor =
        [UIColor colorWithRed:0.04 green:0.06 blue:0.12 alpha:1.0];

    /* Explicit stop locations: red at 0, green at 0.25, blue at 1. */
    CAGradientLayer *explicit = [[CAGradientLayer alloc] init];
    explicit.frame = CGRectMake(30, 100, 300, 60);
    explicit.colors = @[
        (id)[UIColor colorWithRed:1.0 green:0.0 blue:0.0 alpha:1.0].CGColor,
        (id)[UIColor colorWithRed:0.0 green:1.0 blue:0.0 alpha:1.0].CGColor,
        (id)[UIColor colorWithRed:0.0 green:0.0 blue:1.0 alpha:1.0].CGColor,
    ];
    explicit.locations = @[ @0.0, @0.25, @1.0 ];
    explicit.startPoint = CGPointMake(0.0, 0.5);
    explicit.endPoint = CGPointMake(1.0, 0.5);
    [root.layer addSublayer:explicit];

    /* Default even spacing, vertical axis, UIColor entries. */
    CAGradientLayer *even = [[CAGradientLayer alloc] init];
    even.frame = CGRectMake(30, 240, 300, 90);
    even.colors = @[
        [UIColor colorWithRed:1.0 green:0.0 blue:0.0 alpha:1.0],
        [UIColor colorWithRed:1.0 green:1.0 blue:0.0 alpha:1.0],
        [UIColor colorWithRed:0.0 green:0.0 blue:1.0 alpha:1.0],
    ];
    [root.layer addSublayer:even];

    /* Rounded corners run through the offscreen mask path. */
    CAGradientLayer *rounded = [[CAGradientLayer alloc] init];
    rounded.frame = CGRectMake(30, 380, 200, 100);
    rounded.cornerRadius = 30;
    rounded.colors = @[
        (id)[UIColor colorWithRed:1.0 green:0.0 blue:0.0 alpha:1.0].CGColor,
        (id)[UIColor colorWithRed:0.0 green:1.0 blue:0.0 alpha:1.0].CGColor,
        (id)[UIColor colorWithRed:0.0 green:0.0 blue:1.0 alpha:1.0].CGColor,
    ];
    rounded.startPoint = CGPointMake(0.0, 0.5);
    rounded.endPoint = CGPointMake(1.0, 0.5);
    [root.layer addSublayer:rounded];

    printf("[grad] colors %lu locations %lu\n",
           (unsigned long)[explicit.colors count],
           (unsigned long)[explicit.locations count]);

    GradientCaptureView *capture = [[GradientCaptureView alloc]
        initWithFrame:[[UIScreen mainScreen] bounds]];
    capture.backgroundColor = [UIColor clearColor];
    [root addSubview:capture];
    self.view = root;
}
@end

@interface GradientSceneDelegate : UIResponder <UIWindowSceneDelegate>
@property(nonatomic, retain) UIWindow *window;
@end

@interface GradientAppDelegate : UIResponder <UIApplicationDelegate>
@end

@implementation GradientAppDelegate
- (UISceneConfiguration *)application:(UIApplication *)application
    configurationForConnectingSceneSession:(UISceneSession *)session
    options:(UISceneConnectionOptions *)options
{
    (void)application; (void)session; (void)options;
    UISceneConfiguration *configuration = [[UISceneConfiguration alloc]
        initWithName:@"Default Configuration"
         sessionRole:UIWindowSceneSessionRoleApplication];
    configuration.delegateClass = [GradientSceneDelegate class];
    return configuration;
}
@end

@implementation GradientSceneDelegate
- (void)scene:(UIScene *)scene
    willConnectToSession:(UISceneSession *)session
                 options:(UISceneConnectionOptions *)connectionOptions
{
    (void)session; (void)connectionOptions;
    self.window = [[UIWindow alloc] initWithWindowScene:(UIWindowScene *)scene];
    self.window.frame = [[UIScreen mainScreen] bounds];
    self.window.rootViewController = [[GradientController alloc] init];
    [self.window makeKeyAndVisible];
}
@end

int main(int argc, char **argv)
{
    @autoreleasepool
    {
        return UIApplicationMain(argc, argv, nil, @"GradientAppDelegate");
    }
}
