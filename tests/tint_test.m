/* Tint inheritance: two containers set red and green tints, and their
 * buttons take those colors for their titles. A third button keeps the
 * window's default blue tint. */
#include "UIKitStub.h"

extern int printf(const char *fmt, ...);
extern int fflush(void *stream);

@interface TintController : UIViewController
@end

@implementation TintController
- (UIButton *)buttonAtY:(double)y title:(id)title tint:(UIColor *)tint
{
    UIView *container = [[UIView alloc] initWithFrame:CGRectMake(40, y, 320, 120)];
    container.backgroundColor = [UIColor colorWithRed:0.2 green:0.2 blue:0.2
                                                 alpha:1.0];
    if (tint)
        container.tintColor = tint;
    UIButton *button = [UIButton buttonWithType:0];
    button.frame = CGRectMake(0, 0, 320, 120);
    [button setTitle:title forState:0];
    button.titleLabel.font = [UIFont boldSystemFontOfSize:44];
    [container addSubview:button];
    [self.view addSubview:container];
    return button;
}

- (void)loadView
{
    UIView *root =
        [[UIView alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    root.backgroundColor = [UIColor whiteColor];
    self.view = root;

    UIColor *red = [UIColor colorWithRed:1.0 green:0.0 blue:0.0 alpha:1.0];
    UIColor *green = [UIColor colorWithRed:0.0 green:1.0 blue:0.0 alpha:1.0];
    UIButton *redButton = [self buttonAtY:180 title:@"RED" tint:red];
    UIButton *greenButton = [self buttonAtY:380 title:@"GREEN" tint:green];
    [self buttonAtY:580 title:@"BLUE" tint:nil];

    printf("[tint] inherited %d %d\n",
           redButton.tintColor == red ? 1 : 0,
           greenButton.tintColor == green ? 1 : 0);
    printf("[tint] ready\n");
    fflush(0);
}
@end

@interface TintSceneDelegate : UIResponder <UIWindowSceneDelegate>
@property(nonatomic, retain) UIWindow *window;
@end

@interface TintAppDelegate : UIResponder <UIApplicationDelegate>
@end

@implementation TintAppDelegate
- (UISceneConfiguration *)application:(UIApplication *)application
    configurationForConnectingSceneSession:(UISceneSession *)session
    options:(UISceneConnectionOptions *)connectionOptions
{
    (void)application; (void)session; (void)connectionOptions;
    UISceneConfiguration *configuration = [[UISceneConfiguration alloc]
        initWithName:@"Default Configuration"
         sessionRole:UIWindowSceneSessionRoleApplication];
    configuration.delegateClass = [TintSceneDelegate class];
    return configuration;
}
@end

@implementation TintSceneDelegate
- (void)scene:(UIScene *)scene
    willConnectToSession:(UISceneSession *)session
                 options:(UISceneConnectionOptions *)connectionOptions
{
    (void)session; (void)connectionOptions;
    self.window = [[UIWindow alloc] initWithWindowScene:(UIWindowScene *)scene];
    self.window.frame = [[UIScreen mainScreen] bounds];
    self.window.rootViewController = [[TintController alloc] init];
    [self.window makeKeyAndVisible];
}
@end

int main(int argc, char **argv)
{
    @autoreleasepool
    {
        return UIApplicationMain(argc, argv, nil, @"TintAppDelegate");
    }
}
