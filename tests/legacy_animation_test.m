/* Legacy UIView animation blocks: beginAnimations/commitAnimations capture
 * frame, alpha and transform changes, setAnimationDuration/Curve/Delegate
 * drive them, setAnimationRepeatCount repeats the pass, and
 * setAnimationTransition stages a flip. Hit tests probe the interpolated
 * frame, screenshots probe alpha, and the delegate reports each stop. */
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

static UIView *g_root;
static UIView *g_panel;
static UIView *g_box;
static UIView *g_stage;
static UIView *g_card;
static UIView *g_fade;
static int g_did7;
static int g_did8;
static int g_did9;

@interface LegacyController : UIViewController
@end

@implementation LegacyController
- (void)animationWillStart:(NSString *)animationID context:(void *)context
{
    (void)animationID;
    printf("[legacy] will %d\n", (int)(long)context);
    fflush(0);
}
- (void)animationDidStop:(NSString *)animationID finished:(NSNumber *)finished
                 context:(void *)context
{
    (void)animationID;
    int ctx = (int)(long)context;
    if (ctx == 7) g_did7++;
    if (ctx == 8) g_did8++;
    if (ctx == 9) g_did9++;
    printf("[legacy] stop %d %d\n", ctx, finished ? [finished boolValue] : 0);
    fflush(0);
}

- (void)loadView
{
    g_root = [[UIView alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    g_root.backgroundColor =
        [UIColor colorWithRed:0.05 green:0.06 blue:0.09 alpha:1.0];
    self.view = g_root;

    g_panel = [[UIView alloc] initWithFrame:CGRectMake(60, 260, 200, 180)];
    g_panel.backgroundColor = [UIColor redColor];
    [g_root addSubview:g_panel];

    g_box = [[UIView alloc] initWithFrame:CGRectMake(40, 560, 40, 60)];
    g_box.backgroundColor =
        [UIColor colorWithRed:0.15 green:0.45 blue:0.95 alpha:1.0];
    [g_root addSubview:g_box];

    g_stage = [[UIView alloc] initWithFrame:CGRectMake(60, 40, 200, 120)];
    [g_root addSubview:g_stage];
    g_card = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 200, 120)];
    g_card.backgroundColor =
        [UIColor colorWithRed:0.10 green:0.25 blue:0.90 alpha:1.0];
    [g_stage addSubview:g_card];

    g_fade = [[UIView alloc] initWithFrame:CGRectMake(300, 80, 60, 60)];
    g_fade.backgroundColor =
        [UIColor colorWithRed:0.15 green:0.45 blue:0.95 alpha:1.0];
    [g_root addSubview:g_fade];

    printf("[legacy] ready\n");
    fflush(0);

    dispatch_after(dispatch_time(0, 100 * 1000000LL),
                   dispatch_get_main_queue(), ^{
        [UIView beginAnimations:@"move" context:(void *)(long)7];
        [UIView setAnimationDuration:0.6];
        [UIView setAnimationCurve:UIViewAnimationCurveLinear];
        [UIView setAnimationDelegate:self];
        [UIView setAnimationWillStartSelector:
            @selector(animationWillStart:context:)];
        [UIView setAnimationDidStopSelector:
            @selector(animationDidStop:finished:context:)];
        g_panel.frame = CGRectMake(140, 300, 260, 140);
        g_panel.transform = CGAffineTransformMakeScale(1.2, 1.2);
        g_fade.alpha = 0.4;
        [UIView commitAnimations];
        printf("[legacy] start\n");
        fflush(0);
    });

    dispatch_after(dispatch_time(0, 400 * 1000000LL),
                   dispatch_get_main_queue(), ^{
        const char *path = getenv("IOSIM_TEST_PNG_MID");
        if (path)
            iosim_fb_present(path);
        UIView *inside = [g_root hitTest:CGPointMake(320, 420)];
        UIView *outside = [g_root hitTest:CGPointMake(350, 450)];
        printf("[legacy] mid %d %d\n", inside == g_panel,
               outside == g_panel);
        fflush(0);
    });

    dispatch_after(dispatch_time(0, 800 * 1000000LL),
                   dispatch_get_main_queue(), ^{
        UIView *a = [g_root hitTest:CGPointMake(320, 420)];
        UIView *b = [g_root hitTest:CGPointMake(350, 450)];
        printf("[legacy] end %d %d\n", a == g_panel, b == g_panel);
        printf("[legacy] model %d %d %d\n",
               (int)(g_panel.frame.origin.x + 0.5),
               (int)(g_panel.alpha * 100.0 + 0.5),
               (int)(g_panel.transform.a * 100.0 + 0.5));
        printf("[legacy] fade %d\n", (int)(g_fade.alpha * 100.0 + 0.5));
        printf("[legacy] did7 %d\n", g_did7);
        fflush(0);

        [UIView beginAnimations:@"repeat" context:(void *)(long)8];
        [UIView setAnimationDuration:1.0];
        [UIView setAnimationCurve:UIViewAnimationCurveLinear];
        [UIView setAnimationRepeatCount:1];
        [UIView setAnimationDelegate:self];
        [UIView setAnimationWillStartSelector:
            @selector(animationWillStart:context:)];
        [UIView setAnimationDidStopSelector:
            @selector(animationDidStop:finished:context:)];
        g_box.frame = CGRectMake(200, 560, 40, 60);
        [UIView commitAnimations];
        fflush(0);
    });

    dispatch_after(dispatch_time(0, 1300 * 1000000LL),
                   dispatch_get_main_queue(), ^{
        const char *path = getenv("IOSIM_TEST_PNG_REP1");
        if (path)
            iosim_fb_present(path);
        printf("[legacy] rep1\n");
        fflush(0);
    });

    dispatch_after(dispatch_time(0, 2300 * 1000000LL),
                   dispatch_get_main_queue(), ^{
        const char *path = getenv("IOSIM_TEST_PNG_REP2");
        if (path)
            iosim_fb_present(path);
        printf("[legacy] rep2\n");
        fflush(0);
    });

    dispatch_after(dispatch_time(0, 3300 * 1000000LL),
                   dispatch_get_main_queue(), ^{
        printf("[legacy] box model %d\n",
               (int)(g_box.frame.origin.x + 0.5));
        printf("[legacy] did8 %d\n", g_did8);
        fflush(0);

        [UIView beginAnimations:@"swap" context:(void *)(long)9];
        [UIView setAnimationDuration:0.5];
        [UIView setAnimationCurve:UIViewAnimationCurveLinear];
        [UIView setAnimationDelegate:self];
        [UIView setAnimationWillStartSelector:
            @selector(animationWillStart:context:)];
        [UIView setAnimationDidStopSelector:
            @selector(animationDidStop:finished:context:)];
        [UIView setAnimationTransition:UIViewAnimationTransitionFlipFromLeft
                               forView:g_card cache:NO];
        g_card.backgroundColor =
            [UIColor colorWithRed:0.10 green:0.80 blue:0.30 alpha:1.0];
        [UIView commitAnimations];
        fflush(0);
    });

    dispatch_after(dispatch_time(0, 3550 * 1000000LL),
                   dispatch_get_main_queue(), ^{
        const char *path = getenv("IOSIM_TEST_PNG_END");
        if (path)
            iosim_fb_present(path);
        printf("[legacy] stage %d\n", (int)g_stage.subviews.count);
        fflush(0);
    });

    dispatch_after(dispatch_time(0, 4000 * 1000000LL),
                   dispatch_get_main_queue(), ^{
        printf("[legacy] transition end %d %d\n",
               (int)g_stage.subviews.count, g_did9);
        printf("[legacy] done\n");
        fflush(0);
        exit(0);
    });
}
@end

@interface LegacySceneDelegate : UIResponder <UIWindowSceneDelegate>
@property(nonatomic, retain) UIWindow *window;
@end

@interface LegacyAppDelegate : UIResponder <UIApplicationDelegate>
@end

@implementation LegacyAppDelegate
- (UISceneConfiguration *)application:(UIApplication *)application
    configurationForConnectingSceneSession:(UISceneSession *)session
    options:(UISceneConnectionOptions *)connectionOptions
{
    (void)application; (void)session; (void)connectionOptions;
    UISceneConfiguration *configuration = [[UISceneConfiguration alloc]
        initWithName:@"Default Configuration"
         sessionRole:UIWindowSceneSessionRoleApplication];
    configuration.delegateClass = [LegacySceneDelegate class];
    return configuration;
}
@end

@implementation LegacySceneDelegate
- (void)scene:(UIScene *)scene
    willConnectToSession:(UISceneSession *)session
                 options:(UISceneConnectionOptions *)connectionOptions
{
    (void)session; (void)connectionOptions;
    self.window = [[UIWindow alloc] initWithWindowScene:(UIWindowScene *)scene];
    self.window.frame = [[UIScreen mainScreen] bounds];
    self.window.rootViewController = [[LegacyController alloc] init];
    [self.window makeKeyAndVisible];
}
@end

int main(int argc, char **argv)
{
    @autoreleasepool
    {
        return UIApplicationMain(argc, argv, nil, @"LegacyAppDelegate");
    }
}
