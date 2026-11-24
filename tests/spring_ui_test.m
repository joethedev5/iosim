/* UIView spring animations: a soft spring overshoots its destination early
 * and settles, while a critically damped spring approaches it from below. */
#include "UIKitStub.h"

extern int printf(const char *fmt, ...);
extern int fflush(void *stream);
extern void exit(int status);
extern unsigned long long dispatch_time(unsigned long long when,
                                        long long delta);
extern void dispatch_after(unsigned long long when, void *queue,
                           void (^block)(void));
extern void *dispatch_get_main_queue(void);

@interface SpringController : UIViewController {
@public
    UIView *_soft;
    UIView *_critical;
}
@end

@implementation SpringController
- (void)loadView
{
    UIView *root =
        [[UIView alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    root.backgroundColor = [UIColor blackColor];
    self.view = root;

    _soft = [[UIView alloc] initWithFrame:CGRectMake(40, 280, 100, 100)];
    _soft.backgroundColor = [UIColor whiteColor];
    [root addSubview:_soft];
    _critical = [[UIView alloc] initWithFrame:CGRectMake(40, 480, 100, 100)];
    _critical.backgroundColor = [UIColor whiteColor];
    [root addSubview:_critical];

    printf("[springui] ready\n");
    fflush(0);
    [UIView animateWithDuration:1.0 delay:0.0
        usingSpringWithDamping:0.5 initialSpringVelocity:0.0 options:0
        animations:^{
            _soft.frame = CGRectMake(240, 280, 100, 100);
        }
        completion:^(BOOL finished) {
            (void)finished;
        }];
    [UIView animateWithDuration:1.0 delay:0.0
        usingSpringWithDamping:1.0 initialSpringVelocity:0.0 options:0
        animations:^{
            _critical.frame = CGRectMake(240, 480, 100, 100);
        }
        completion:^(BOOL finished) {
            (void)finished;
        }];

    dispatch_after(dispatch_time(0, 250 * 1000000LL),
                   dispatch_get_main_queue(), ^{
        CGRect a = [[_soft layer] presentationLayer].frame;
        CGRect b = [[_critical layer] presentationLayer].frame;
        printf("[springui] early %.1f %.1f\n", a.origin.x, b.origin.x);
        fflush(0);
    });
    dispatch_after(dispatch_time(0, 750 * 1000000LL),
                   dispatch_get_main_queue(), ^{
        CGRect a = [[_soft layer] presentationLayer].frame;
        CGRect b = [[_critical layer] presentationLayer].frame;
        printf("[springui] late %.1f %.1f\n", a.origin.x, b.origin.x);
        printf("[springui] done\n");
        fflush(0);
        exit(0);
    });
}
@end

@interface SpringSceneDelegate : UIResponder <UIWindowSceneDelegate>
@property(nonatomic, retain) UIWindow *window;
@end

@interface SpringAppDelegate : UIResponder <UIApplicationDelegate>
@end

@implementation SpringAppDelegate
- (UISceneConfiguration *)application:(UIApplication *)application
    configurationForConnectingSceneSession:(UISceneSession *)session
    options:(UISceneConnectionOptions *)connectionOptions
{
    (void)application; (void)session; (void)connectionOptions;
    UISceneConfiguration *configuration = [[UISceneConfiguration alloc]
        initWithName:@"Default Configuration"
         sessionRole:UIWindowSceneSessionRoleApplication];
    configuration.delegateClass = [SpringSceneDelegate class];
    return configuration;
}
@end

@implementation SpringSceneDelegate
- (void)scene:(UIScene *)scene
    willConnectToSession:(UISceneSession *)session
                 options:(UISceneConnectionOptions *)connectionOptions
{
    (void)session; (void)connectionOptions;
    self.window = [[UIWindow alloc] initWithWindowScene:(UIWindowScene *)scene];
    self.window.frame = [[UIScreen mainScreen] bounds];
    self.window.rootViewController = [[SpringController alloc] init];
    [self.window makeKeyAndVisible];
}
@end

int main(int argc, char **argv)
{
    @autoreleasepool
    {
        return UIApplicationMain(argc, argv, nil, @"SpringAppDelegate");
    }
}
