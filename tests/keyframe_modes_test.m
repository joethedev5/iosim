/* CAKeyframeAnimation calculation modes and per-segment timing functions:
 * five 2-second opacity animations sampled at 0.25 s. */
#include "UIKitStub.h"

extern int printf(const char *fmt, ...);
extern int fflush(void *stream);
extern void exit(int status);
extern unsigned long long dispatch_time(unsigned long long when,
                                        long long delta);
extern void dispatch_after(unsigned long long when, void *queue,
                           void (^block)(void));
extern void *dispatch_get_main_queue(void);

@interface KeyframeModesController : UIViewController {
@public
    UIView *_linear;
    UIView *_discrete;
    UIView *_paced;
    UIView *_cubic;
    UIView *_eased;
}
@end

static void add_keyframes(UIView *view, id *values, id *times, int count,
                          NSString *mode, id timing)
{
    CAKeyframeAnimation *anim =
        [CAKeyframeAnimation animationWithKeyPath:@"opacity"];
    [anim setDuration:2.0];
    [anim setValues:[NSArray arrayWithObjects:values count:(unsigned long)count]];
    [anim setKeyTimes:[NSArray arrayWithObjects:times count:(unsigned long)count]];
    [anim setCalculationMode:mode];
    if (timing)
        [anim setTimingFunctions:[NSArray arrayWithObjects:&timing count:1]];
    [view.layer addAnimation:anim forKey:nil];
}

@implementation KeyframeModesController
- (UIView *)boxAt:(double)x
{
    UIView *box = [[UIView alloc] initWithFrame:CGRectMake(x, 100, 60, 60)];
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

    _linear = [self boxAt:20];
    _discrete = [self boxAt:100];
    _paced = [self boxAt:180];
    _cubic = [self boxAt:260];
    _eased = [self boxAt:340];

    id vals[3] = { [NSNumber numberWithDouble:0.0],
                   [NSNumber numberWithDouble:0.9],
                   [NSNumber numberWithDouble:1.0] };
    id times[3] = { [NSNumber numberWithDouble:0.0],
                    [NSNumber numberWithDouble:0.5],
                    [NSNumber numberWithDouble:1.0] };
    add_keyframes(_linear, vals, times, 3, @"linear", nil);
    add_keyframes(_discrete, vals, times, 3, @"discrete", nil);
    add_keyframes(_paced, vals, times, 3, @"paced", nil);

    id curve[3] = { [NSNumber numberWithDouble:0.0],
                    [NSNumber numberWithDouble:1.0],
                    [NSNumber numberWithDouble:0.0] };
    add_keyframes(_cubic, curve, times, 3, @"cubic", nil);
    add_keyframes(_eased, curve, times, 3, @"linear",
                  [CAMediaTimingFunction functionWithName:
                                             kCAMediaTimingFunctionEaseIn]);

    printf("[kfmode] ready\n");
    fflush(0);
    dispatch_after(dispatch_time(0, 250 * 1000000LL),
                   dispatch_get_main_queue(), ^{
        printf("[kfmode] linear %.3f\n",
               [[[_linear layer] presentationLayer] opacity]);
        printf("[kfmode] discrete %.3f\n",
               [[[_discrete layer] presentationLayer] opacity]);
        printf("[kfmode] paced %.3f\n",
               [[[_paced layer] presentationLayer] opacity]);
        printf("[kfmode] cubic %.3f\n",
               [[[_cubic layer] presentationLayer] opacity]);
        printf("[kfmode] eased %.3f\n",
               [[[_eased layer] presentationLayer] opacity]);
        printf("[kfmode] done\n");
        fflush(0);
        exit(0);
    });
}
@end

@interface KeyframeModesSceneDelegate : UIResponder <UIWindowSceneDelegate>
@property(nonatomic, retain) UIWindow *window;
@end

@interface KeyframeModesAppDelegate : UIResponder <UIApplicationDelegate>
@end

@implementation KeyframeModesAppDelegate
- (UISceneConfiguration *)application:(UIApplication *)application
    configurationForConnectingSceneSession:(UISceneSession *)session
    options:(UISceneConnectionOptions *)connectionOptions
{
    (void)application; (void)session; (void)connectionOptions;
    UISceneConfiguration *configuration = [[UISceneConfiguration alloc]
        initWithName:@"Default Configuration"
         sessionRole:UIWindowSceneSessionRoleApplication];
    configuration.delegateClass = [KeyframeModesSceneDelegate class];
    return configuration;
}
@end

@implementation KeyframeModesSceneDelegate
- (void)scene:(UIScene *)scene
    willConnectToSession:(UISceneSession *)session
                 options:(UISceneConnectionOptions *)connectionOptions
{
    (void)session; (void)connectionOptions;
    self.window = [[UIWindow alloc] initWithWindowScene:(UIWindowScene *)scene];
    self.window.frame = [[UIScreen mainScreen] bounds];
    self.window.rootViewController = [[KeyframeModesController alloc] init];
    [self.window makeKeyAndVisible];
}
@end

int main(int argc, char **argv)
{
    @autoreleasepool
    {
        return UIApplicationMain(argc, argv, nil, @"KeyframeModesAppDelegate");
    }
}
