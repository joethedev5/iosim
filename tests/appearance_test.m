/* An app that draws with dynamic system colors and reports the appearance
 * the device hands it, so switching light/dark is observable from outside. */
#include "UIKitStub.h"

extern int printf(const char *fmt, ...);
extern int fflush(void *stream);

@interface AppearanceController : UIViewController
@property(nonatomic, retain) UILabel *label;
@end

@implementation AppearanceController
- (void)loadView
{
    UIView *root =
        [[UIView alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    root.backgroundColor = [UIColor systemBackgroundColor];
    self.view = root;
    UILabel *label =
        [[UILabel alloc] initWithFrame:CGRectMake(60, 360, 280, 80)];
    [label setText:@"Light"];
    [label setTextColor:[UIColor labelColor]];
    [root addSubview:label];
    self.label = label;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    printf("[appearance] initial %ld\n",
           (long)[self.traitCollection userInterfaceStyle]);
    fflush(0);
}

- (void)traitCollectionDidChange:(UITraitCollection *)previous
{
    (void)previous;
    long style = (long)[self.traitCollection userInterfaceStyle];
    printf("[appearance] style %ld\n", style);
    fflush(0);
    [self.view setBackgroundColor:[UIColor systemBackgroundColor]];
    [self.label setTextColor:[UIColor labelColor]];
    [self.label setText:style == UIUserInterfaceStyleDark ? @"Dark" : @"Light"];
    [self setNeedsStatusBarAppearanceUpdate];
}

- (long)preferredStatusBarStyle
{
    return [self.traitCollection userInterfaceStyle] == UIUserInterfaceStyleDark
               ? UIStatusBarStyleLightContent
               : UIStatusBarStyleDarkContent;
}
@end

@interface AppearanceSceneDelegate : UIResponder <UIWindowSceneDelegate>
@property(nonatomic, retain) UIWindow *window;
@end

@interface AppearanceAppDelegate : UIResponder <UIApplicationDelegate>
@end

@implementation AppearanceAppDelegate
- (UISceneConfiguration *)application:(UIApplication *)application
    configurationForConnectingSceneSession:(UISceneSession *)session
    options:(UISceneConnectionOptions *)connectionOptions
{
    (void)application; (void)session; (void)connectionOptions;
    UISceneConfiguration *configuration = [[UISceneConfiguration alloc]
        initWithName:@"Default Configuration"
         sessionRole:UIWindowSceneSessionRoleApplication];
    configuration.delegateClass = [AppearanceSceneDelegate class];
    return configuration;
}
@end

@implementation AppearanceSceneDelegate
- (void)scene:(UIScene *)scene
    willConnectToSession:(UISceneSession *)session
                 options:(UISceneConnectionOptions *)connectionOptions
{
    (void)session; (void)connectionOptions;
    self.window = [[UIWindow alloc] initWithWindowScene:(UIWindowScene *)scene];
    self.window.frame = [[UIScreen mainScreen] bounds];
    AppearanceController *controller = [[AppearanceController alloc] init];
    self.window.rootViewController = controller;
    [self.window makeKeyAndVisible];
}
@end

int main(int argc, char **argv)
{
    @autoreleasepool
    {
        return UIApplicationMain(argc, argv, nil, @"AppearanceAppDelegate");
    }
}
