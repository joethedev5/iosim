/* UIView cross-dissolve transition: the old snapshot fades over the new
 * colors, sampled halfway and after completion. */
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

static int g_phase;

@interface TransitionCapture : UIView
@end

@implementation TransitionCapture
- (void)drawRect:(CGRect)rect
{
    (void)rect;
    if (g_phase == 1)
    {
        const char *path = getenv("IOSIM_TEST_PNG_MID");
        if (path)
            iosim_fb_present(path);
        printf("[trans] mid\n");
        fflush(0);
        g_phase = 2;
    }
    else if (g_phase == 3)
    {
        const char *path = getenv("IOSIM_TEST_PNG_END");
        if (path)
            iosim_fb_present(path);
        printf("[trans] end\n");
        fflush(0);
        exit(0);
    }
}
@end

@interface TransitionController : UIViewController {
@public
    UIView *_target;
    UIView *_chip;
    TransitionCapture *_capture;
}
@end

@implementation TransitionController
- (void)loadView
{
    UIView *root =
        [[UIView alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    root.backgroundColor = [UIColor blackColor];
    self.view = root;

    _target = [[UIView alloc] initWithFrame:CGRectMake(40, 280, 200, 120)];
    _target.backgroundColor = [UIColor redColor];
    [root addSubview:_target];
    _chip = [[UIView alloc] initWithFrame:CGRectMake(60, 20, 40, 40)];
    _chip.backgroundColor = [UIColor yellowColor];
    [_target addSubview:_chip];

    _capture = [[TransitionCapture alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    _capture.backgroundColor = [UIColor clearColor];
    [root addSubview:_capture];

    printf("[trans] ready\n");
    fflush(0);

    [UIView transitionWithView:_target duration:0.6
        options:UIViewAnimationOptionTransitionCrossDissolve
        animations:^{
            _target.backgroundColor = [UIColor blueColor];
            _chip.backgroundColor = [UIColor greenColor];
        }
        completion:^(BOOL finished) {
            printf("[trans] done %d\n", finished ? 1 : 0);
            fflush(0);
        }];

    dispatch_after(dispatch_time(0, 300 * 1000000LL),
                   dispatch_get_main_queue(), ^{
        g_phase = 1;
        [_capture setNeedsDisplay];
    });
    dispatch_after(dispatch_time(0, 900 * 1000000LL),
                   dispatch_get_main_queue(), ^{
        g_phase = 3;
        [_capture setNeedsDisplay];
    });
}
@end

@interface TransitionSceneDelegate : UIResponder <UIWindowSceneDelegate>
@property(nonatomic, retain) UIWindow *window;
@end

@interface TransitionAppDelegate : UIResponder <UIApplicationDelegate>
@end

@implementation TransitionAppDelegate
- (UISceneConfiguration *)application:(UIApplication *)application
    configurationForConnectingSceneSession:(UISceneSession *)session
    options:(UISceneConnectionOptions *)connectionOptions
{
    (void)application; (void)session; (void)connectionOptions;
    UISceneConfiguration *configuration = [[UISceneConfiguration alloc]
        initWithName:@"Default Configuration"
         sessionRole:UIWindowSceneSessionRoleApplication];
    configuration.delegateClass = [TransitionSceneDelegate class];
    return configuration;
}
@end

@implementation TransitionSceneDelegate
- (void)scene:(UIScene *)scene
    willConnectToSession:(UISceneSession *)session
                 options:(UISceneConnectionOptions *)connectionOptions
{
    (void)session; (void)connectionOptions;
    self.window = [[UIWindow alloc] initWithWindowScene:(UIWindowScene *)scene];
    self.window.frame = [[UIScreen mainScreen] bounds];
    self.window.rootViewController = [[TransitionController alloc] init];
    [self.window makeKeyAndVisible];
}
@end

int main(int argc, char **argv)
{
    @autoreleasepool
    {
        return UIApplicationMain(argc, argv, nil, @"TransitionAppDelegate");
    }
}
