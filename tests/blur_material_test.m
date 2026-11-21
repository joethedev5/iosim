/* A system material card over a uniform gray field. The material's tint
 * follows the device appearance, so light and dark screenshots differ. */
#include "UIKitStub.h"

extern int printf(const char *fmt, ...);
extern int fflush(void *stream);

@interface BlurMaterialController : UIViewController
@end

@implementation BlurMaterialController
- (void)loadView
{
    UIView *root =
        [[UIView alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    root.backgroundColor =
        [UIColor colorWithRed:0.5 green:0.5 blue:0.5 alpha:1.0];
    UIVisualEffectView *card = [[UIVisualEffectView alloc]
        initWithEffect:[UIBlurEffect
            effectWithStyle:UIBlurEffectStyleSystemMaterial]];
    card.frame = CGRectMake(40, 250, 322, 200);
    card.layer.cornerRadius = 28;
    [root addSubview:card];
    self.view = root;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    printf("[blur-material] ready\n");
    fflush(0);
}

- (void)traitCollectionDidChange:(UITraitCollection *)previous
{
    (void)previous;
    printf("[blur-material] style %ld\n",
           (long)[self.traitCollection userInterfaceStyle]);
    fflush(0);
}
@end

@interface BlurMaterialSceneDelegate : UIResponder <UIWindowSceneDelegate>
@property(nonatomic, retain) UIWindow *window;
@end

@interface BlurMaterialAppDelegate : UIResponder <UIApplicationDelegate>
@end

@implementation BlurMaterialAppDelegate
- (UISceneConfiguration *)application:(UIApplication *)application
    configurationForConnectingSceneSession:(UISceneSession *)session
    options:(UISceneConnectionOptions *)connectionOptions
{
    (void)application; (void)session; (void)connectionOptions;
    UISceneConfiguration *configuration = [[UISceneConfiguration alloc]
        initWithName:@"Default Configuration"
         sessionRole:UIWindowSceneSessionRoleApplication];
    configuration.delegateClass = [BlurMaterialSceneDelegate class];
    return configuration;
}
@end

@implementation BlurMaterialSceneDelegate
- (void)scene:(UIScene *)scene
    willConnectToSession:(UISceneSession *)session
                 options:(UISceneConnectionOptions *)connectionOptions
{
    (void)session; (void)connectionOptions;
    self.window = [[UIWindow alloc] initWithWindowScene:(UIWindowScene *)scene];
    self.window.frame = [[UIScreen mainScreen] bounds];
    self.window.rootViewController = [[BlurMaterialController alloc] init];
    [self.window makeKeyAndVisible];
}
@end

int main(int argc, char **argv)
{
    @autoreleasepool
    {
        return UIApplicationMain(argc, argv, nil,
                                 @"BlurMaterialAppDelegate");
    }
}
