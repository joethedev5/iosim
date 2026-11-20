#if __has_include(<UIKit/UIKit.h>)
#import <UIKit/UIKit.h>
#else
#import "UIKitStub.h"
#endif

extern int printf(const char *fmt, ...);
extern int fflush(void *stream);

/* A floating tab bar with two pages: tapping an item swaps the content view
 * and retints the items. */

@interface SceneDelegate : UIResponder <UIWindowSceneDelegate>
@property(nonatomic, retain) UIWindow *window;
@end

@interface AppDelegate : UIResponder <UIApplicationDelegate>
@end

@implementation AppDelegate
- (UISceneConfiguration *)application:(UIApplication *)application
    configurationForConnectingSceneSession:(UISceneSession *)session
    options:(UISceneConnectionOptions *)options
{
    (void)application; (void)session; (void)options;
    UISceneConfiguration *configuration = [[UISceneConfiguration alloc]
        initWithName:@"Default Configuration"
         sessionRole:UIWindowSceneSessionRoleApplication];
    configuration.delegateClass = [SceneDelegate class];
    return configuration;
}
@end

@interface TabPageController : UIViewController {
    int _which;
}
- (id)initWithWhich:(int)which;
@end

@implementation TabPageController
- (id)initWithWhich:(int)which
{
    self = [super init];
    if (self)
        _which = which;
    return self;
}
- (void)loadView
{
    UIView *view =
        [[UIView alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    if (_which == 0)
        view.backgroundColor =
            [UIColor colorWithRed:0.85 green:0.20 blue:0.20 alpha:1.0];
    else
        view.backgroundColor =
            [UIColor colorWithRed:0.20 green:0.80 blue:0.30 alpha:1.0];
    self.view = view;
}
@end

@implementation SceneDelegate
- (void)scene:(UIScene *)scene
    willConnectToSession:(UISceneSession *)session
                 options:(UISceneConnectionOptions *)connectionOptions
{
    (void)session; (void)connectionOptions;
    self.window = [[UIWindow alloc] initWithWindowScene:(UIWindowScene *)scene];
    self.window.frame = [[UIScreen mainScreen] bounds];

    TabPageController *red = [[TabPageController alloc] initWithWhich:0];
    red.title = @"Red";
    red.tabBarItem = [[UITabBarItem alloc] initWithTitle:@"Red" image:nil tag:0];
    TabPageController *green = [[TabPageController alloc] initWithWhich:1];
    green.title = @"Green";
    green.tabBarItem = [[UITabBarItem alloc] initWithTitle:@"Green" image:nil
                                                       tag:1];

    UITabBarController *tabs = [[UITabBarController alloc] init];
    [tabs setViewControllers:[NSArray arrayWithObjects:(const id[]){red, green}
                                                  count:2]];
    printf("[tab] ready count=%lu selected=%d\n",
           [[tabs viewControllers] count], [tabs selectedIndex]);
    fflush(0);

    self.window.rootViewController = tabs;
    [self.window makeKeyAndVisible];
}
@end

int main(int argc, char **argv)
{
    @autoreleasepool { return UIApplicationMain(argc, argv, nil, @"AppDelegate"); }
}
