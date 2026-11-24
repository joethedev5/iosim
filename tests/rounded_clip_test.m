/* Views that clip to bounds and carry a corner radius mask their whole
 * subtree, while an unclipped rounded view lets a subview cover its corner. */
#include "UIKitStub.h"

extern int printf(const char *fmt, ...);
extern int fflush(void *stream);
extern int iosim_fb_present(const char *path);
extern char *getenv(const char *name);
extern void exit(int status);

@interface RoundClipCapture : UIView
@end

@implementation RoundClipCapture
- (void)drawRect:(CGRect)rect
{
    (void)rect;
    const char *path = getenv("IOSIM_TEST_PNG");
    if (!path)
        return;
    iosim_fb_present(path);
    printf("[rclip] png written\n");
    fflush(0);
    exit(0);
}
@end

@interface RoundClipController : UIViewController
@end

@implementation RoundClipController
- (void)loadView
{
    UIView *root = [[UIView alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    root.backgroundColor = [UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:1];
    self.view = root;
    CGRect screen = [[UIScreen mainScreen] bounds];

    UIView *red = [[UIView alloc] initWithFrame:CGRectMake(40, 100, 200, 120)];
    red.backgroundColor = [UIColor colorWithRed:0.0 green:0.0 blue:1.0 alpha:1];
    red.layer.cornerRadius = 20;
    red.clipsToBounds = YES;
    UIView *redFill = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 200, 120)];
    redFill.backgroundColor =
        [UIColor colorWithRed:1.0 green:0.0 blue:0.0 alpha:1];
    [red addSubview:redFill];
    [root addSubview:red];

    UIView *yellow = [[UIView alloc] initWithFrame:CGRectMake(40, 300, 200, 120)];
    yellow.backgroundColor =
        [UIColor colorWithRed:0.1 green:0.1 blue:0.1 alpha:1];
    yellow.layer.cornerRadius = 16;
    yellow.layer.masksToBounds = YES;
    UIView *yellowFill = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 200, 120)];
    yellowFill.backgroundColor =
        [UIColor colorWithRed:1.0 green:0.9 blue:0.0 alpha:1];
    [yellow addSubview:yellowFill];
    [root addSubview:yellow];

    UIView *orange = [[UIView alloc] initWithFrame:CGRectMake(40, 500, 200, 120)];
    orange.backgroundColor =
        [UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:1];
    orange.layer.cornerRadius = 20;
    orange.clipsToBounds = NO;
    UIView *orangeFill = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 200, 120)];
    orangeFill.backgroundColor =
        [UIColor colorWithRed:1.0 green:0.5 blue:0.0 alpha:1];
    [orange addSubview:orangeFill];
    [root addSubview:orange];

    UIView *green = [[UIView alloc] initWithFrame:CGRectMake(40, 700, 200, 120)];
    green.backgroundColor =
        [UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:1];
    green.layer.cornerRadius = 20;
    green.clipsToBounds = YES;
    green.layer.maskedCorners =
        UIRectCornerTopLeft | UIRectCornerTopRight;
    UIView *greenFill = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 200, 120)];
    greenFill.backgroundColor =
        [UIColor colorWithRed:0.0 green:1.0 blue:0.0 alpha:1];
    [green addSubview:greenFill];
    [root addSubview:green];

    RoundClipCapture *capture = [[RoundClipCapture alloc] initWithFrame:screen];
    capture.backgroundColor = [UIColor clearColor];
    [root addSubview:capture];
    self.view = root;
}
@end

@interface RoundClipSceneDelegate : UIResponder <UIWindowSceneDelegate>
@property(nonatomic, retain) UIWindow *window;
@end

@interface RoundClipAppDelegate : UIResponder <UIApplicationDelegate>
@end

@implementation RoundClipAppDelegate
- (UISceneConfiguration *)application:(UIApplication *)application
    configurationForConnectingSceneSession:(UISceneSession *)session
    options:(UISceneConnectionOptions *)connectionOptions
{
    (void)application; (void)session; (void)connectionOptions;
    UISceneConfiguration *configuration = [[UISceneConfiguration alloc]
        initWithName:@"Default Configuration"
         sessionRole:UIWindowSceneSessionRoleApplication];
    configuration.delegateClass = [RoundClipSceneDelegate class];
    return configuration;
}
@end

@implementation RoundClipSceneDelegate
- (void)scene:(UIScene *)scene
    willConnectToSession:(UISceneSession *)session
                 options:(UISceneConnectionOptions *)connectionOptions
{
    (void)session; (void)connectionOptions;
    self.window = [[UIWindow alloc] initWithWindowScene:(UIWindowScene *)scene];
    self.window.frame = [[UIScreen mainScreen] bounds];
    self.window.rootViewController = [[RoundClipController alloc] init];
    [self.window makeKeyAndVisible];
}
@end

int main(int argc, char **argv)
{
    @autoreleasepool
    {
        return UIApplicationMain(argc, argv, nil, @"RoundClipAppDelegate");
    }
}
