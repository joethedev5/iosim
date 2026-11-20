#if __has_include(<UIKit/UIKit.h>)
#import <UIKit/UIKit.h>
#else
#import "UIKitStub.h"
#endif

extern int printf(const char *fmt, ...);
extern int fflush(void *stream);

/* Lock fixture: the device locks while this app is foreground, so its
 * lifecycle line sequence proves the app was backgrounded and then resumed
 * in place after the unlock. */

@interface LockViewController : UIViewController
@end

@interface LockSceneDelegate : UIResponder <UIWindowSceneDelegate>
@property(nonatomic, retain) UIWindow *window;
@end

@interface LockAppDelegate : UIResponder <UIApplicationDelegate>
@end

@implementation LockAppDelegate
- (BOOL)application:(UIApplication *)application
    didFinishLaunchingWithOptions:(id)options
{
    (void)options;
    printf("[lockapp] launch state=%ld\n",
           (long)[application applicationState]);
    fflush(0);
    return YES;
}
- (UISceneConfiguration *)application:(UIApplication *)application
    configurationForConnectingSceneSession:(UISceneSession *)session
    options:(UISceneConnectionOptions *)options
{
    (void)application;
    (void)session;
    (void)options;
    UISceneConfiguration *configuration = [[UISceneConfiguration alloc]
        initWithName:@"Default Configuration"
         sessionRole:UIWindowSceneSessionRoleApplication];
    configuration.delegateClass = [LockSceneDelegate class];
    return configuration;
}
- (void)applicationWillResignActive:(UIApplication *)application
{
    printf("[lockapp] resign state=%ld\n",
           (long)[application applicationState]);
    fflush(0);
}
- (void)applicationDidEnterBackground:(UIApplication *)application
{
    printf("[lockapp] background state=%ld\n",
           (long)[application applicationState]);
    fflush(0);
}
- (void)applicationWillEnterForeground:(UIApplication *)application
{
    printf("[lockapp] foreground state=%ld\n",
           (long)[application applicationState]);
    fflush(0);
}
- (void)applicationDidBecomeActive:(UIApplication *)application
{
    printf("[lockapp] active state=%ld\n",
           (long)[application applicationState]);
    fflush(0);
}
@end

@implementation LockSceneDelegate
- (void)scene:(UIScene *)scene
    willConnectToSession:(UISceneSession *)session
                 options:(UISceneConnectionOptions *)connectionOptions
{
    (void)session;
    (void)connectionOptions;
    self.window = [[UIWindow alloc] initWithWindowScene:(UIWindowScene *)scene];
    self.window.frame = [[UIScreen mainScreen] bounds];
    self.window.backgroundColor =
        [UIColor colorWithRed:0.043 green:0.063 blue:0.125 alpha:1.0];
    self.window.rootViewController = [[LockViewController alloc] init];
    [self.window makeKeyAndVisible];
    printf("[lockapp] scene connected\n");
    fflush(0);
}
@end

@implementation LockViewController
- (void)loadView
{
    UIView *view =
        [[UIView alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    view.backgroundColor =
        [UIColor colorWithRed:0.043 green:0.063 blue:0.125 alpha:1.0];
    self.view = view;
}
- (void)viewDidLoad
{
    [super viewDidLoad];
    UILabel *label = [[UILabel alloc]
        initWithFrame:CGRectMake(40, 180, 322, 60)];
    label.text = @"Lock Fixture";
    label.textColor = [UIColor whiteColor];
    label.font = [UIFont systemFontOfSize:28];
    [self.view addSubview:label];
    printf("[lockapp] ready state=%ld\n",
           (long)[[UIApplication sharedApplication] applicationState]);
    fflush(0);
}
@end

int main(int argc, char **argv)
{
    @autoreleasepool
    {
        return UIApplicationMain(argc, argv, nil, @"LockAppDelegate");
    }
}
