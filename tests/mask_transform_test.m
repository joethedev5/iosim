/* Masks on transformed content: a 1.2x view with a left-half maskView and a
 * 1.2x standalone layer with a left-half mask must show only the left half,
 * with the boundary at the transformed center. */
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

@interface MaskController : UIViewController
@end

@implementation MaskController
- (void)loadView
{
    UIView *root =
        [[UIView alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    root.backgroundColor =
        [UIColor colorWithRed:0.05 green:0.06 blue:0.09 alpha:1.0];
    self.view = root;

    UIView *viewMasked =
        [[UIView alloc] initWithFrame:CGRectMake(40, 200, 100, 100)];
    viewMasked.backgroundColor = [UIColor redColor];
    viewMasked.transform = CGAffineTransformMakeScale(1.2, 1.2);
    UIView *mask = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 50, 100)];
    mask.backgroundColor = [UIColor whiteColor];
    viewMasked.maskView = mask;
    [root addSubview:viewMasked];

    CALayer *layerMasked = [[CALayer alloc] init];
    layerMasked.frame = CGRectMake(240, 200, 100, 100);
    layerMasked.backgroundColor = [UIColor redColor];
    layerMasked.transform = CATransform3DMakeScale(1.2, 1.2, 1.0);
    CALayer *layerMask = [[CALayer alloc] init];
    layerMask.frame = CGRectMake(0, 0, 50, 100);
    layerMask.backgroundColor = [UIColor whiteColor];
    layerMasked.mask = layerMask;
    [root.layer addSublayer:layerMasked];

    printf("[mt] ready\n");
    fflush(0);

    dispatch_after(dispatch_time(0, 200 * 1000000LL),
                   dispatch_get_main_queue(), ^{
        const char *path = getenv("IOSIM_TEST_PNG");
        if (path)
            iosim_fb_present(path);
        printf("[mt] captured\n");
        printf("[mt] done\n");
        fflush(0);
        exit(0);
    });
}
@end

@interface MaskSceneDelegate : UIResponder <UIWindowSceneDelegate>
@property(nonatomic, retain) UIWindow *window;
@end

@interface MaskAppDelegate : UIResponder <UIApplicationDelegate>
@end

@implementation MaskAppDelegate
- (UISceneConfiguration *)application:(UIApplication *)application
    configurationForConnectingSceneSession:(UISceneSession *)session
    options:(UISceneConnectionOptions *)connectionOptions
{
    (void)application; (void)session; (void)connectionOptions;
    UISceneConfiguration *configuration = [[UISceneConfiguration alloc]
        initWithName:@"Default Configuration"
         sessionRole:UIWindowSceneSessionRoleApplication];
    configuration.delegateClass = [MaskSceneDelegate class];
    return configuration;
}
@end

@implementation MaskSceneDelegate
- (void)scene:(UIScene *)scene
    willConnectToSession:(UISceneSession *)session
                 options:(UISceneConnectionOptions *)connectionOptions
{
    (void)session; (void)connectionOptions;
    self.window = [[UIWindow alloc] initWithWindowScene:(UIWindowScene *)scene];
    self.window.frame = [[UIScreen mainScreen] bounds];
    self.window.rootViewController = [[MaskController alloc] init];
    [self.window makeKeyAndVisible];
}
@end

int main(int argc, char **argv)
{
    @autoreleasepool
    {
        return UIApplicationMain(argc, argv, nil, @"MaskAppDelegate");
    }
}
