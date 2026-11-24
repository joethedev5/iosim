/* CAAnimation completion semantics: default removal restores the model
 * value, removedOnCompletion=NO keeps the animation, and fillMode forwards
 * holds its final value. */
#include "UIKitStub.h"

extern int printf(const char *fmt, ...);
extern int fflush(void *stream);
extern void exit(int status);
extern unsigned long long dispatch_time(unsigned long long when,
                                        long long delta);
extern void dispatch_after(unsigned long long when, void *queue,
                           void (^block)(void));
extern void *dispatch_get_main_queue(void);
extern id kCAFillModeForwards;

@interface RemovalController : UIViewController {
@public
    UIView *_fade;
    UIView *_hold;
    UIView *_keep;
}
@end

static void add_fade(UIView *view, BOOL removed, id fill)
{
    CABasicAnimation *anim =
        [CABasicAnimation animationWithKeyPath:@"opacity"];
    anim.duration = 0.5;
    anim.fromValue = [NSNumber numberWithDouble:1.0];
    anim.toValue = [NSNumber numberWithDouble:0.25];
    anim.removedOnCompletion = removed;
    if (fill)
        anim.fillMode = fill;
    [view.layer addAnimation:anim forKey:@"fade"];
}

@implementation RemovalController
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

    _fade = [self boxAt:280];
    _hold = [self boxAt:400];
    _keep = [self boxAt:520];
    add_fade(_fade, YES, nil);
    add_fade(_hold, NO, kCAFillModeForwards);
    add_fade(_keep, NO, nil);

    printf("[arem] ready\n");
    fflush(0);
    dispatch_after(dispatch_time(0, 250 * 1000000LL),
                   dispatch_get_main_queue(), ^{
        printf("[arem] mid %.2f %.2f %.2f\n",
               [[[_fade layer] presentationLayer] opacity],
               [[[_hold layer] presentationLayer] opacity],
               [[[_keep layer] presentationLayer] opacity]);
        fflush(0);
    });
    dispatch_after(dispatch_time(0, 800 * 1000000LL),
                   dispatch_get_main_queue(), ^{
        printf("[arem] end %.2f %.2f %.2f\n",
               [[[_fade layer] presentationLayer] opacity],
               [[[_hold layer] presentationLayer] opacity],
               [[[_keep layer] presentationLayer] opacity]);
        printf("[arem] keep %d %d %d\n",
               [[_fade layer] animationForKey:@"fade"] ? 1 : 0,
               [[_hold layer] animationForKey:@"fade"] ? 1 : 0,
               [[_keep layer] animationForKey:@"fade"] ? 1 : 0);
        printf("[arem] done\n");
        fflush(0);
        exit(0);
    });
}
@end

@interface RemovalSceneDelegate : UIResponder <UIWindowSceneDelegate>
@property(nonatomic, retain) UIWindow *window;
@end

@interface RemovalAppDelegate : UIResponder <UIApplicationDelegate>
@end

@implementation RemovalAppDelegate
- (UISceneConfiguration *)application:(UIApplication *)application
    configurationForConnectingSceneSession:(UISceneSession *)session
    options:(UISceneConnectionOptions *)connectionOptions
{
    (void)application; (void)session; (void)connectionOptions;
    UISceneConfiguration *configuration = [[UISceneConfiguration alloc]
        initWithName:@"Default Configuration"
         sessionRole:UIWindowSceneSessionRoleApplication];
    configuration.delegateClass = [RemovalSceneDelegate class];
    return configuration;
}
@end

@implementation RemovalSceneDelegate
- (void)scene:(UIScene *)scene
    willConnectToSession:(UISceneSession *)session
                 options:(UISceneConnectionOptions *)connectionOptions
{
    (void)session; (void)connectionOptions;
    self.window = [[UIWindow alloc] initWithWindowScene:(UIWindowScene *)scene];
    self.window.frame = [[UIScreen mainScreen] bounds];
    self.window.rootViewController = [[RemovalController alloc] init];
    [self.window makeKeyAndVisible];
}
@end

int main(int argc, char **argv)
{
    @autoreleasepool
    {
        return UIApplicationMain(argc, argv, nil, @"RemovalAppDelegate");
    }
}
