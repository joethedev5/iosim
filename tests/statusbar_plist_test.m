/* A gray app with no controller status-bar overrides. Its Info.plist sets
 * UIViewControllerBasedStatusBarAppearance=NO and a light status bar, so the
 * time and glyphs must be white even though the background is light. */
#include "UIKitStub.h"

extern int printf(const char *fmt, ...);
extern int fflush(void *stream);

@interface StatusBarPlistController : UIViewController
@end

@implementation StatusBarPlistController
- (void)loadView
{
    UIView *root =
        [[UIView alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    root.backgroundColor =
        [UIColor colorWithRed:0.5 green:0.5 blue:0.5 alpha:1.0];
    self.view = root;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    printf("[statusbar-plist] ready\n");
    fflush(0);
}
@end

@interface StatusBarPlistSceneDelegate : UIResponder <UIWindowSceneDelegate>
@property(nonatomic, retain) UIWindow *window;
@end

@interface StatusBarPlistAppDelegate : UIResponder <UIApplicationDelegate>
@end

@implementation StatusBarPlistAppDelegate
- (UISceneConfiguration *)application:(UIApplication *)application
    configurationForConnectingSceneSession:(UISceneSession *)session
    options:(UISceneConnectionOptions *)connectionOptions
{
    (void)application; (void)session; (void)connectionOptions;
    UISceneConfiguration *configuration = [[UISceneConfiguration alloc]
        initWithName:@"Default Configuration"
         sessionRole:UIWindowSceneSessionRoleApplication];
    configuration.delegateClass = [StatusBarPlistSceneDelegate class];
    return configuration;
}
@end

@implementation StatusBarPlistSceneDelegate
- (void)scene:(UIScene *)scene
    willConnectToSession:(UISceneSession *)session
                 options:(UISceneConnectionOptions *)connectionOptions
{
    (void)session; (void)connectionOptions;
    self.window = [[UIWindow alloc] initWithWindowScene:(UIWindowScene *)scene];
    self.window.frame = [[UIScreen mainScreen] bounds];
    self.window.rootViewController = [[StatusBarPlistController alloc] init];
    [self.window makeKeyAndVisible];
}
@end

int main(int argc, char **argv)
{
    @autoreleasepool
    {
        return UIApplicationMain(argc, argv, nil,
                                 @"StatusBarPlistAppDelegate");
    }
}
