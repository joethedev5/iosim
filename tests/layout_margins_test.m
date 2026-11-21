/* UIView layoutMargins and layoutMarginsGuide: a child pinned to the guide
 * sits inset from its container by the configured margins. */
#include "UIKitStub.h"

extern int printf(const char *fmt, ...);
extern int fflush(void *stream);

@interface MarginsController : UIViewController
@end

@implementation MarginsController
- (void)loadView
{
    UIView *root =
        [[UIView alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    root.backgroundColor = [UIColor blackColor];

    UIView *container =
        [[UIView alloc] initWithFrame:CGRectMake(50, 300, 200, 200)];
    container.backgroundColor = [UIColor darkGrayColor];
    container.layoutMargins = UIEdgeInsetsMake(20, 20, 20, 20);
    [root addSubview:container];

    UIView *child = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 10, 10)];
    child.backgroundColor = [UIColor greenColor];
    child.translatesAutoresizingMaskIntoConstraints = NO;
    [container addSubview:child];

    UILayoutGuide *guide = container.layoutMarginsGuide;
    [NSLayoutConstraint activateConstraints:[NSArray arrayWithObjects:
        [child.leadingAnchor constraintEqualToAnchor:guide.leadingAnchor],
        [child.trailingAnchor constraintEqualToAnchor:guide.trailingAnchor],
        [child.topAnchor constraintEqualToAnchor:guide.topAnchor],
        [child.bottomAnchor constraintEqualToAnchor:guide.bottomAnchor],
        nil]];

    UIEdgeInsets margins = container.layoutMargins;
    printf("[margins] edges %.0f %.0f %.0f %.0f\n", margins.top,
           margins.left, margins.bottom, margins.right);
    printf("[margins] guide %.0f %.0f %.0f %.0f\n", guide.layoutFrameX,
           guide.layoutFrameY, guide.layoutFrameWidth,
           guide.layoutFrameHeight);

    self.view = root;
    self.additionalSafeAreaInsets = UIEdgeInsetsMake(10, 0, 12, 0);
    UIEdgeInsets safe = root.safeAreaInsets;
    printf("[margins] safe %.0f %.0f\n", safe.top, safe.bottom);
    UILayoutGuide *safeGuide = root.safeAreaLayoutGuide;
    printf("[margins] safeguide %.0f %.0f %.0f %.0f\n",
           safeGuide.layoutFrameX, safeGuide.layoutFrameY,
           safeGuide.layoutFrameWidth, safeGuide.layoutFrameHeight);

    double red = 0, green = 0, blue = 0, alpha = 0;
    UIColor *orange = [UIColor orangeColor];
    BOOL hasRGB = [orange getRed:&red green:&green blue:&blue alpha:&alpha];
    double white = 0;
    BOOL hasWhite = [[UIColor colorWithWhite:0.25 alpha:0.5]
        getWhite:&white alpha:&alpha];
    printf("[margins] color %d %.0f %.0f %.0f %d %.2f\n", hasRGB ? 1 : 0,
           red * 255, green * 255, blue * 255, hasWhite ? 1 : 0, white);

    printf("[margins] ready\n");
    fflush(0);
}
@end

@interface MarginsSceneDelegate : UIResponder <UIWindowSceneDelegate>
@property(nonatomic, retain) UIWindow *window;
@end

@interface MarginsAppDelegate : UIResponder <UIApplicationDelegate>
@end

@implementation MarginsAppDelegate
- (UISceneConfiguration *)application:(UIApplication *)application
    configurationForConnectingSceneSession:(UISceneSession *)session
    options:(UISceneConnectionOptions *)connectionOptions
{
    (void)application; (void)session; (void)connectionOptions;
    UISceneConfiguration *configuration = [[UISceneConfiguration alloc]
        initWithName:@"Default Configuration"
         sessionRole:UIWindowSceneSessionRoleApplication];
    configuration.delegateClass = [MarginsSceneDelegate class];
    return configuration;
}
@end

@implementation MarginsSceneDelegate
- (void)scene:(UIScene *)scene
    willConnectToSession:(UISceneSession *)session
                 options:(UISceneConnectionOptions *)connectionOptions
{
    (void)session; (void)connectionOptions;
    self.window = [[UIWindow alloc] initWithWindowScene:(UIWindowScene *)scene];
    self.window.frame = [[UIScreen mainScreen] bounds];
    self.window.rootViewController = [[MarginsController alloc] init];
    [self.window makeKeyAndVisible];
}
@end

int main(int argc, char **argv)
{
    @autoreleasepool
    {
        return UIApplicationMain(argc, argv, nil, @"MarginsAppDelegate");
    }
}
