/* Animated UIView transforms: a square scales about its center and a bar
 * rotates 90 degrees. Timed captures prove the intermediate frames are
 * interpolated rather than snapping to the model value. */
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

@interface TransformController : UIViewController
@end

@implementation TransformController
- (void)loadView
{
    UIView *root =
        [[UIView alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    root.backgroundColor =
        [UIColor colorWithRed:0.043 green:0.055 blue:0.102 alpha:1.0];
    self.view = root;

    UIView *square = [[UIView alloc] initWithFrame:
        CGRectMake(151, 170, 100, 100)];
    square.backgroundColor =
        [UIColor colorWithRed:0.10 green:0.80 blue:0.30 alpha:1.0];
    [root addSubview:square];

    UIView *bar = [[UIView alloc] initWithFrame:
        CGRectMake(141, 610, 120, 20)];
    bar.backgroundColor =
        [UIColor colorWithRed:0.10 green:0.80 blue:0.30 alpha:1.0];
    [root addSubview:bar];

    dispatch_after(dispatch_time(0, 50 * 1000000LL),
                   dispatch_get_main_queue(), ^{
        [UIView animateWithDuration:0.8
                              delay:0.0
                            options:UIViewAnimationOptionCurveLinear
                         animations:^{
            square.transform = CGAffineTransformMakeScale(2.0, 2.0);
            bar.transform = CGAffineTransformMakeRotation(
                1.5707963267948966);
        } completion:nil];
        printf("[tx] started\n");
        fflush(0);
    });

    dispatch_after(dispatch_time(0, 450 * 1000000LL),
                   dispatch_get_main_queue(), ^{
        const char *path = getenv("IOSIM_TEST_PNG_MID");
        if (path)
            iosim_fb_present(path);
        fflush(0);
    });

    dispatch_after(dispatch_time(0, 1000 * 1000000LL),
                   dispatch_get_main_queue(), ^{
        /* At the final 2x scale the square's hit area extends to x=101,
         * so (110,220) hits it while (95,220) falls outside. */
        UIView *hit = [root hitTest:CGPointMake(110, 220)];
        UIView *miss = [root hitTest:CGPointMake(95, 220)];
        printf("[tx] hit %d %d\n", hit == square, miss == root);
        fflush(0);
    });

    dispatch_after(dispatch_time(0, 1200 * 1000000LL),
                   dispatch_get_main_queue(), ^{
        const char *path = getenv("IOSIM_TEST_PNG_END");
        if (path)
            iosim_fb_present(path);
        printf("[tx] png written\n");
        fflush(0);
        exit(0);
    });
}
@end

@interface TransformSceneDelegate : UIResponder <UIWindowSceneDelegate>
@property(nonatomic, retain) UIWindow *window;
@end

@interface TransformAppDelegate : UIResponder <UIApplicationDelegate>
@end

@implementation TransformAppDelegate
- (UISceneConfiguration *)application:(UIApplication *)application
    configurationForConnectingSceneSession:(UISceneSession *)session
    options:(UISceneConnectionOptions *)connectionOptions
{
    (void)application; (void)session; (void)connectionOptions;
    UISceneConfiguration *configuration = [[UISceneConfiguration alloc]
        initWithName:@"Default Configuration"
         sessionRole:UIWindowSceneSessionRoleApplication];
    configuration.delegateClass = [TransformSceneDelegate class];
    return configuration;
}
@end

@implementation TransformSceneDelegate
- (void)scene:(UIScene *)scene
    willConnectToSession:(UISceneSession *)session
                 options:(UISceneConnectionOptions *)connectionOptions
{
    (void)session; (void)connectionOptions;
    self.window = [[UIWindow alloc] initWithWindowScene:(UIWindowScene *)scene];
    self.window.frame = [[UIScreen mainScreen] bounds];
    self.window.rootViewController = [[TransformController alloc] init];
    [self.window makeKeyAndVisible];
}
@end

int main(int argc, char **argv)
{
    @autoreleasepool
    {
        return UIApplicationMain(argc, argv, nil, @"TransformAppDelegate");
    }
}
