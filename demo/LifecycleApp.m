#if __has_include(<UIKit/UIKit.h>)
#import <UIKit/UIKit.h>
#else
#import "UIKitStub.h"
#endif

extern int printf(const char *fmt, ...);
extern int fflush(void *stream);
extern int usleep(unsigned int usec);

/* Lifecycle fixture: prints every application/scene transition with the
 * UIApplication state the runtime reports at that moment. */

@interface LifeViewController : UIViewController
@end

@interface LifeSceneDelegate : UIResponder <UIWindowSceneDelegate>
@property(nonatomic, retain) UIWindow *window;
@end

@interface LifeAppDelegate : UIResponder <UIApplicationDelegate> {
@public
    unsigned long _task;
    BOOL _taskStarted;
}
@end

@implementation LifeAppDelegate
- (BOOL)application:(UIApplication *)application
    didFinishLaunchingWithOptions:(id)options
{
    (void)options;
    printf("[life] launch state=%ld\n",
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
    configuration.delegateClass = [LifeSceneDelegate class];
    return configuration;
}
- (void)applicationWillResignActive:(UIApplication *)application
{
    printf("[life] resign state=%ld\n",
           (long)[application applicationState]);
    fflush(0);
}
- (void)applicationDidEnterBackground:(UIApplication *)application
{
    printf("[life] background state=%ld\n",
           (long)[application applicationState]);
    fflush(0);
    if (_taskStarted)
        return;
    _taskStarted = YES;
    _task = [application beginBackgroundTaskWithExpirationHandler:^{
        printf("[life] bg expired\n");
        fflush(0);
    }];
    printf("[life] bg began %d remaining %.0f\n", _task != 0,
           [application backgroundTimeRemaining]);
    fflush(0);
    NSOperationQueue *queue = [[NSOperationQueue alloc] init];
    [queue addOperationWithBlock:^{
        usleep(300000);
        printf("[life] bg work\n");
        fflush(0);
        [application endBackgroundTask:_task];
    }];
}
- (void)applicationWillEnterForeground:(UIApplication *)application
{
    printf("[life] foreground state=%ld\n",
           (long)[application applicationState]);
    fflush(0);
}
- (void)applicationDidBecomeActive:(UIApplication *)application
{
    printf("[life] active state=%ld\n",
           (long)[application applicationState]);
    fflush(0);
}
@end

@implementation LifeSceneDelegate
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
    self.window.rootViewController = [[LifeViewController alloc] init];
    [self.window makeKeyAndVisible];
    printf("[life] scene connected\n");
    fflush(0);
}
- (void)sceneDidBecomeActive:(UIScene *)scene
{
    (void)scene;
    printf("[life] scene active\n");
    fflush(0);
}
- (void)sceneWillResignActive:(UIScene *)scene
{
    (void)scene;
    printf("[life] scene resign\n");
    fflush(0);
}
- (void)sceneDidEnterBackground:(UIScene *)scene
{
    (void)scene;
    printf("[life] scene background\n");
    fflush(0);
}
- (void)sceneWillEnterForeground:(UIScene *)scene
{
    (void)scene;
    printf("[life] scene foreground\n");
    fflush(0);
}
@end

@implementation LifeViewController
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
    printf("[life] ready state=%ld\n",
           (long)[[UIApplication sharedApplication] applicationState]);
    fflush(0);
}
@end

int main(int argc, char **argv)
{
    @autoreleasepool
    {
        return UIApplicationMain(argc, argv, nil, @"LifeAppDelegate");
    }
}
