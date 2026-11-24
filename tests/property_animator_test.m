/* UIViewPropertyAnimator timing parameters: a custom cubic Bezier eases
 * slowly, while a 0.5 damping-ratio spring overshoots its target. */
#include "UIKitStub.h"

extern int printf(const char *fmt, ...);
extern int fflush(void *stream);
extern void exit(int status);
extern unsigned long long dispatch_time(unsigned long long when,
                                        long long delta);
extern void dispatch_after(unsigned long long when, void *queue,
                           void (^block)(void));
extern void *dispatch_get_main_queue(void);

@interface TimingController : UIViewController {
@public
    UIView *_cubic;
    UIView *_spring;
}
@end

@implementation TimingController
- (UIView *)boxAt:(double)y
{
    UIView *box = [[UIView alloc] initWithFrame:CGRectMake(40, y, 80, 80)];
    box.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:box];
    return box;
}
- (void)loadView
{
    UIView *root =
        [[UIView alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    root.backgroundColor = [UIColor blackColor];
    self.view = root;

    _cubic = [self boxAt:280];
    _spring = [self boxAt:480];

    UICubicTimingParameters *cubic =
        [[UICubicTimingParameters alloc] initWithControlPoint1:
            CGPointMake(0.42, 0.0) controlPoint2:CGPointMake(0.58, 1.0)];
    UISpringTimingParameters *spring =
        [[UISpringTimingParameters alloc] initWithDampingRatio:0.5];
    CGPoint second = [cubic controlPoint2];
    printf("[pram] timing %.2f %.2f %.2f\n", second.x,
           [spring dampingRatio], [spring settlingDuration]);
    fflush(0);

    UIViewPropertyAnimator *cubicAnimator =
        [[UIViewPropertyAnimator alloc] initWithDuration:1.0
                                         timingParameters:cubic];
    [cubicAnimator addAnimations:^{
        _cubic.frame = CGRectMake(240, 280, 80, 80);
    }];
    UIViewPropertyAnimator *springAnimator =
        [[UIViewPropertyAnimator alloc] initWithDuration:1.0
                                         timingParameters:spring];
    [springAnimator addAnimations:^{
        _spring.frame = CGRectMake(240, 480, 80, 80);
    }];
    [cubicAnimator startAnimation];
    [springAnimator startAnimation];

    printf("[pram] ready\n");
    fflush(0);
    dispatch_after(dispatch_time(0, 250 * 1000000LL),
                   dispatch_get_main_queue(), ^{
        CGRect a = [[_cubic layer] presentationLayer].frame;
        CGRect b = [[_spring layer] presentationLayer].frame;
        printf("[pram] mid %.1f %.1f\n", a.origin.x, b.origin.x);
        fflush(0);
    });
    dispatch_after(dispatch_time(0, 1200 * 1000000LL),
                   dispatch_get_main_queue(), ^{
        CGRect a = [[_cubic layer] presentationLayer].frame;
        CGRect b = [[_spring layer] presentationLayer].frame;
        printf("[pram] end %.1f %.1f %ld %ld\n", a.origin.x, b.origin.x,
               [cubicAnimator state], [springAnimator state]);
        printf("[pram] done\n");
        fflush(0);
        exit(0);
    });
}
@end

@interface TimingSceneDelegate : UIResponder <UIWindowSceneDelegate>
@property(nonatomic, retain) UIWindow *window;
@end

@interface TimingAppDelegate : UIResponder <UIApplicationDelegate>
@end

@implementation TimingAppDelegate
- (UISceneConfiguration *)application:(UIApplication *)application
    configurationForConnectingSceneSession:(UISceneSession *)session
    options:(UISceneConnectionOptions *)connectionOptions
{
    (void)application; (void)session; (void)connectionOptions;
    UISceneConfiguration *configuration = [[UISceneConfiguration alloc]
        initWithName:@"Default Configuration"
         sessionRole:UIWindowSceneSessionRoleApplication];
    configuration.delegateClass = [TimingSceneDelegate class];
    return configuration;
}
@end

@implementation TimingSceneDelegate
- (void)scene:(UIScene *)scene
    willConnectToSession:(UISceneSession *)session
                 options:(UISceneConnectionOptions *)connectionOptions
{
    (void)session; (void)connectionOptions;
    self.window = [[UIWindow alloc] initWithWindowScene:(UIWindowScene *)scene];
    self.window.frame = [[UIScreen mainScreen] bounds];
    self.window.rootViewController = [[TimingController alloc] init];
    [self.window makeKeyAndVisible];
}
@end

int main(int argc, char **argv)
{
    @autoreleasepool
    {
        return UIApplicationMain(argc, argv, nil, @"TimingAppDelegate");
    }
}
