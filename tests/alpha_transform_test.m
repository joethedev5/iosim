/* Transformed and layered views must composite their alpha once. Four red
 * regions at effective alpha 0.5 sit on the same dark root: an untransformed
 * plain view, a transformed view, a transformed view with layer opacity, and
 * a standalone transformed sublayer. All four centres must match the plain
 * view, and the transformed extents must still be scaled. */
#include "UIKitStub.h"

extern int printf(const char *fmt, ...);
extern int fflush(void *stream);
extern int iosim_fb_present(const char *path);
extern char *getenv(const char *name);
extern void exit(int status);
extern unsigned long long dispatch_time(unsigned long long when,
                                        long long delta);
extern void dispatch_after(unsigned long long when, void *queue,
                           void (^block)(void));
extern void *dispatch_get_main_queue(void);

@interface AlphaController : UIViewController
@end

@implementation AlphaController
- (void)loadView
{
    UIView *root =
        [[UIView alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    root.backgroundColor =
        [UIColor colorWithRed:0.05 green:0.06 blue:0.09 alpha:1.0];
    self.view = root;

    UIView *plain =
        [[UIView alloc] initWithFrame:CGRectMake(40, 200, 100, 100)];
    plain.backgroundColor = [UIColor redColor];
    plain.alpha = 0.5;
    [root addSubview:plain];

    UIView *scaled =
        [[UIView alloc] initWithFrame:CGRectMake(200, 200, 100, 100)];
    scaled.backgroundColor = [UIColor redColor];
    scaled.alpha = 0.5;
    scaled.transform = CGAffineTransformMakeScale(1.4, 1.4);
    [root addSubview:scaled];

    UIView *layered =
        [[UIView alloc] initWithFrame:CGRectMake(40, 400, 100, 100)];
    layered.backgroundColor = [UIColor redColor];
    layered.transform = CGAffineTransformMakeScale(1.4, 1.4);
    layered.layer.opacity = 0.5;
    [root addSubview:layered];

    CALayer *sublayer = [[CALayer alloc] init];
    sublayer.frame = CGRectMake(200, 400, 100, 100);
    sublayer.backgroundColor = [UIColor redColor];
    sublayer.opacity = 0.5;
    sublayer.transform = CATransform3DMakeScale(1.4, 1.4, 1.0);
    [root.layer addSublayer:sublayer];

    printf("[at] ready\n");
    fflush(0);

    dispatch_after(dispatch_time(0, 200 * 1000000LL),
                   dispatch_get_main_queue(), ^{
        const char *path = getenv("IOSIM_TEST_PNG");
        if (path)
            iosim_fb_present(path);
        printf("[at] captured\n");
        printf("[at] done\n");
        fflush(0);
        exit(0);
    });
}
@end

@interface AlphaSceneDelegate : UIResponder <UIWindowSceneDelegate>
@property(nonatomic, retain) UIWindow *window;
@end

@interface AlphaAppDelegate : UIResponder <UIApplicationDelegate>
@end

@implementation AlphaAppDelegate
- (UISceneConfiguration *)application:(UIApplication *)application
    configurationForConnectingSceneSession:(UISceneSession *)session
    options:(UISceneConnectionOptions *)connectionOptions
{
    (void)application; (void)session; (void)connectionOptions;
    UISceneConfiguration *configuration = [[UISceneConfiguration alloc]
        initWithName:@"Default Configuration"
         sessionRole:UIWindowSceneSessionRoleApplication];
    configuration.delegateClass = [AlphaSceneDelegate class];
    return configuration;
}
@end

@implementation AlphaSceneDelegate
- (void)scene:(UIScene *)scene
    willConnectToSession:(UISceneSession *)session
                 options:(UISceneConnectionOptions *)connectionOptions
{
    (void)session; (void)connectionOptions;
    self.window = [[UIWindow alloc] initWithWindowScene:(UIWindowScene *)scene];
    self.window.frame = [[UIScreen mainScreen] bounds];
    self.window.rootViewController = [[AlphaController alloc] init];
    [self.window makeKeyAndVisible];
}
@end

int main(int argc, char **argv)
{
    @autoreleasepool
    {
        return UIApplicationMain(argc, argv, nil, @"AlphaAppDelegate");
    }
}
