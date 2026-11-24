/* UIView flip transitions: the old snapshot squashes along the flip axis
 * during the first half over an opaque backdrop, and the new snapshot opens
 * during the second half. Timed captures of both halves and of a vertical
 * transitionFromView: flip prove the geometry; the completion reports the
 * duration and the cleanup leaves only the destination view. */
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

static double g_flip_start;
static double g_flip_done_at;
static volatile int g_flip_done;
static double g_swap_start;
static double g_swap_done_at;
static volatile int g_swap_done;
static UIView *g_panel;
static UIView *g_root;

@interface FlipController : UIViewController
@end

@implementation FlipController
- (void)loadView
{
    g_root = [[UIView alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    g_root.backgroundColor =
        [UIColor colorWithRed:0.05 green:0.06 blue:0.09 alpha:1.0];
    self.view = g_root;

    g_panel = [[UIView alloc] initWithFrame:CGRectMake(81, 287, 240, 300)];
    g_panel.backgroundColor =
        [UIColor colorWithRed:0.10 green:0.25 blue:0.90 alpha:1.0];
    [g_root addSubview:g_panel];

    printf("[flip] ready\n");
    fflush(0);

    dispatch_after(dispatch_time(0, 100 * 1000000LL),
                   dispatch_get_main_queue(), ^{
        g_flip_start = CACurrentMediaTime();
        [UIView transitionWithView:g_panel duration:0.8
            options:UIViewAnimationOptionTransitionFlipFromLeft
            animations:^{
                g_panel.backgroundColor =
                    [UIColor colorWithRed:0.10 green:0.80 blue:0.30
                                    alpha:1.0];
            }
            completion:^(BOOL finished) {
                g_flip_done = 1;
                g_flip_done_at = CACurrentMediaTime();
                printf("[flip] done %d\n", finished ? 1 : 0);
                fflush(0);
            }];
        printf("[flip] start\n");
        fflush(0);
    });

    dispatch_after(dispatch_time(0, 250 * 1000000LL),
                   dispatch_get_main_queue(), ^{
        const char *path = getenv("IOSIM_TEST_PNG_FIRST");
        if (path)
            iosim_fb_present(path);
        printf("[flip] first\n");
        fflush(0);
    });

    dispatch_after(dispatch_time(0, 600 * 1000000LL),
                   dispatch_get_main_queue(), ^{
        const char *path = getenv("IOSIM_TEST_PNG_SECOND");
        if (path)
            iosim_fb_present(path);
        printf("[flip] stage %d\n", (int)g_panel.subviews.count);
        fflush(0);
    });

    dispatch_after(dispatch_time(0, 1050 * 1000000LL),
                   dispatch_get_main_queue(), ^{
        printf("[flip] settle %d %d %d\n", g_flip_done ? 1 : 0,
               (int)g_panel.subviews.count, (int)g_root.subviews.count);
        printf("[flip] elapsed %d\n",
               (int)((g_flip_done_at - g_flip_start) * 1000.0 + 0.5));
        fflush(0);

        UIView *next =
            [[UIView alloc] initWithFrame:CGRectMake(81, 287, 240, 300)];
        next.backgroundColor =
            [UIColor colorWithRed:0.95 green:0.85 blue:0.10 alpha:1.0];
        g_swap_start = CACurrentMediaTime();
        [UIView transitionFromView:g_panel toView:next duration:0.6
            options:UIViewAnimationOptionTransitionFlipFromTop
            completion:^(BOOL finished) {
                g_swap_done = 1;
                g_swap_done_at = CACurrentMediaTime();
                printf("[swap] done %d\n", finished ? 1 : 0);
                fflush(0);
            }];
        printf("[swap] start\n");
        fflush(0);
    });

    dispatch_after(dispatch_time(0, 1500 * 1000000LL),
                   dispatch_get_main_queue(), ^{
        const char *path = getenv("IOSIM_TEST_PNG_SWAP");
        if (path)
            iosim_fb_present(path);
        printf("[swap] stage %d\n", (int)g_root.subviews.count);
        fflush(0);
    });

    dispatch_after(dispatch_time(0, 2300 * 1000000LL),
                   dispatch_get_main_queue(), ^{
        printf("[swap] settle %d %d\n", g_swap_done ? 1 : 0,
               (int)g_root.subviews.count);
        printf("[swap] elapsed %d\n",
               (int)((g_swap_done_at - g_swap_start) * 1000.0 + 0.5));
        printf("[swap] end\n");
        fflush(0);
        exit(0);
    });
}
@end

@interface FlipSceneDelegate : UIResponder <UIWindowSceneDelegate>
@property(nonatomic, retain) UIWindow *window;
@end

@interface FlipAppDelegate : UIResponder <UIApplicationDelegate>
@end

@implementation FlipAppDelegate
- (UISceneConfiguration *)application:(UIApplication *)application
    configurationForConnectingSceneSession:(UISceneSession *)session
    options:(UISceneConnectionOptions *)connectionOptions
{
    (void)application; (void)session; (void)connectionOptions;
    UISceneConfiguration *configuration = [[UISceneConfiguration alloc]
        initWithName:@"Default Configuration"
         sessionRole:UIWindowSceneSessionRoleApplication];
    configuration.delegateClass = [FlipSceneDelegate class];
    return configuration;
}
@end

@implementation FlipSceneDelegate
- (void)scene:(UIScene *)scene
    willConnectToSession:(UISceneSession *)session
                 options:(UISceneConnectionOptions *)connectionOptions
{
    (void)session; (void)connectionOptions;
    self.window = [[UIWindow alloc] initWithWindowScene:(UIWindowScene *)scene];
    self.window.frame = [[UIScreen mainScreen] bounds];
    self.window.rootViewController = [[FlipController alloc] init];
    [self.window makeKeyAndVisible];
}
@end

int main(int argc, char **argv)
{
    @autoreleasepool
    {
        return UIApplicationMain(argc, argv, nil, @"FlipAppDelegate");
    }
}
