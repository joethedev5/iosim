/* UIView maskView and userInteractionEnabled hit-testing. */
#include "UIKitStub.h"

extern int printf(const char *fmt, ...);
extern int fflush(void *stream);

@interface MaskController : UIViewController
@end

@implementation MaskController
- (void)loadView
{
    UIView *root =
        [[UIView alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    root.backgroundColor = [UIColor blackColor];

    UIView *bottom = [[UIView alloc] initWithFrame:CGRectMake(100, 300, 200, 100)];
    bottom.backgroundColor = [UIColor greenColor];
    [root addSubview:bottom];

    UIView *disabled =
        [[UIView alloc] initWithFrame:CGRectMake(100, 300, 200, 100)];
    disabled.backgroundColor = [UIColor redColor];
    disabled.userInteractionEnabled = NO;
    [root addSubview:disabled];

    UIView *masked =
        [[UIView alloc] initWithFrame:CGRectMake(100, 450, 200, 100)];
    masked.backgroundColor = [UIColor blueColor];
    UIView *mask = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 100, 100)];
    mask.backgroundColor = [UIColor whiteColor];
    masked.maskView = mask;
    [root addSubview:masked];

    UIView *hit = [root hitTest:CGPointMake(200, 350)];
    printf("[mask] hit %d enabled %d\n", hit == bottom ? 1 : 0,
           disabled.userInteractionEnabled ? 1 : 0);

    self.view = root;
    printf("[mask] ready\n");
    fflush(0);
}
@end

@interface MaskSceneDelegate : UIResponder <UIWindowSceneDelegate>
@property(nonatomic, retain) UIWindow *window;
@end

@interface MaskAppDelegate : UIResponder <UIApplicationDelegate>
@end

@implementation MaskAppDelegate
- (UISceneConfiguration *)application:(UIApplication *)application
    configurationForConnectingSceneSession:(UISceneSession *)session
    options:(UISceneConnectionOptions *)connectionOptions
{
    (void)application; (void)session; (void)connectionOptions;
    UISceneConfiguration *configuration = [[UISceneConfiguration alloc]
        initWithName:@"Default Configuration"
         sessionRole:UIWindowSceneSessionRoleApplication];
    configuration.delegateClass = [MaskSceneDelegate class];
    return configuration;
}
@end

@implementation MaskSceneDelegate
- (void)scene:(UIScene *)scene
    willConnectToSession:(UISceneSession *)session
                 options:(UISceneConnectionOptions *)connectionOptions
{
    (void)session; (void)connectionOptions;
    self.window = [[UIWindow alloc] initWithWindowScene:(UIWindowScene *)scene];
    self.window.frame = [[UIScreen mainScreen] bounds];
    self.window.rootViewController = [[MaskController alloc] init];
    [self.window makeKeyAndVisible];
}
@end

int main(int argc, char **argv)
{
    @autoreleasepool
    {
        return UIApplicationMain(argc, argv, nil, @"MaskAppDelegate");
    }
}
