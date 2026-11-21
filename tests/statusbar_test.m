/* A gray app whose button toggles prefersStatusBarHidden. The status bar
 * must disappear and return when setNeedsStatusBarAppearanceUpdate is sent. */
#include "UIKitStub.h"

extern int printf(const char *fmt, ...);
extern int fflush(void *stream);

@interface StatusBarController : UIViewController
@property(nonatomic) BOOL hidden;
@end

@implementation StatusBarController
- (void)loadView
{
    UIView *root =
        [[UIView alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    root.backgroundColor =
        [UIColor colorWithRed:0.5 green:0.5 blue:0.5 alpha:1.0];
    UIButton *button =
        [[UIButton alloc] initWithFrame:CGRectMake(60, 300, 280, 80)];
    [button setTitle:@"Toggle Status" forState:UIControlStateNormal];
    [button addTarget:self action:@selector(toggle:)
     forControlEvents:UIControlEventTouchUpInside];
    [root addSubview:button];
    self.view = root;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    printf("[statusbar] ready\n");
    fflush(0);
}

- (BOOL)prefersStatusBarHidden
{
    return self.hidden;
}

- (long)preferredStatusBarStyle
{
    return UIStatusBarStyleDarkContent;
}

- (void)toggle:(id)sender
{
    (void)sender;
    self.hidden = !self.hidden;
    printf("[statusbar] hidden %d\n", self.hidden ? 1 : 0);
    fflush(0);
    [self setNeedsStatusBarAppearanceUpdate];
}
@end

@interface StatusBarSceneDelegate : UIResponder <UIWindowSceneDelegate>
@property(nonatomic, retain) UIWindow *window;
@end

@interface StatusBarAppDelegate : UIResponder <UIApplicationDelegate>
@end

@implementation StatusBarAppDelegate
- (UISceneConfiguration *)application:(UIApplication *)application
    configurationForConnectingSceneSession:(UISceneSession *)session
    options:(UISceneConnectionOptions *)connectionOptions
{
    (void)application; (void)session; (void)connectionOptions;
    UISceneConfiguration *configuration = [[UISceneConfiguration alloc]
        initWithName:@"Default Configuration"
         sessionRole:UIWindowSceneSessionRoleApplication];
    configuration.delegateClass = [StatusBarSceneDelegate class];
    return configuration;
}
@end

@implementation StatusBarSceneDelegate
- (void)scene:(UIScene *)scene
    willConnectToSession:(UISceneSession *)session
                 options:(UISceneConnectionOptions *)connectionOptions
{
    (void)session; (void)connectionOptions;
    self.window = [[UIWindow alloc] initWithWindowScene:(UIWindowScene *)scene];
    self.window.frame = [[UIScreen mainScreen] bounds];
    self.window.rootViewController = [[StatusBarController alloc] init];
    [self.window makeKeyAndVisible];
}
@end

int main(int argc, char **argv)
{
    @autoreleasepool
    {
        return UIApplicationMain(argc, argv, nil, @"StatusBarAppDelegate");
    }
}
