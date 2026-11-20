#if __has_include(<UIKit/UIKit.h>)
#import <UIKit/UIKit.h>
#else
#import "UIKitStub.h"
#endif

extern int printf(const char *fmt, ...);
extern int fflush(void *stream);

/* CAAnimationGroup fixture: opacity and corner radius are expanded from one
 * group and sampled through the presentation layer at the midpoint, at the
 * end, and after removeAnimationForKey: clears every child slot. */

@interface GroupViewController : UIViewController {
    CALayer *_box;
}
@end

@interface SceneDelegate : UIResponder <UIWindowSceneDelegate>
@property(nonatomic, retain) UIWindow *window;
@end

@interface AppDelegate : UIResponder <UIApplicationDelegate>
@end

@implementation GroupViewController
- (void)loadView
{
    UIView *view =
        [[UIView alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    view.backgroundColor =
        [UIColor colorWithRed:0.043 green:0.063 blue:0.125 alpha:1.0];
    self.view = view;
}
- (void)viewDidLoad
{
    [super viewDidLoad];
    _box = [[CALayer alloc] init];
    _box.frame = CGRectMake(101, 200, 200, 200);
    _box.backgroundColor =
        [UIColor colorWithRed:1.0 green:0.2314 blue:0.1882 alpha:1.0];
    _box.opacity = 1.0;
    _box.cornerRadius = 0.0;
    [self.view.layer addSublayer:_box];

    CABasicAnimation *fade =
        [CABasicAnimation animationWithKeyPath:@"opacity"];
    fade.fromValue = [NSNumber numberWithDouble:1.0];
    fade.toValue = [NSNumber numberWithDouble:0.2];
    fade.duration = 2.0;

    CABasicAnimation *corner =
        [CABasicAnimation animationWithKeyPath:@"cornerRadius"];
    corner.fromValue = [NSNumber numberWithDouble:0.0];
    corner.toValue = [NSNumber numberWithDouble:30.0];
    corner.duration = 2.0;

    CAAnimationGroup *group = [[CAAnimationGroup alloc] init];
    group.duration = 2.0;
    [group setAnimations:[NSArray arrayWithObjects:(const id[]){fade, corner}
                                               count:2]];
    [_box addAnimation:group forKey:@"group"];

    [NSTimer scheduledTimerWithTimeInterval:1.0
                                     target:self
                                   selector:@selector(midpoint:)
                                   userInfo:nil
                                    repeats:NO];
    [NSTimer scheduledTimerWithTimeInterval:2.3
                                     target:self
                                   selector:@selector(finished:)
                                   userInfo:nil
                                    repeats:NO];
    [NSTimer scheduledTimerWithTimeInterval:3.8
                                     target:self
                                   selector:@selector(removeGroup:)
                                   userInfo:nil
                                    repeats:NO];
    printf("[group] started\n");
    fflush(0);
}
- (void)midpoint:(id)timer
{
    (void)timer;
    CALayer *p = [_box presentationLayer];
    printf("[group] mid opacity=%.2f radius=%.2f\n", p.opacity,
           p.cornerRadius);
    fflush(0);
}
- (void)finished:(id)timer
{
    (void)timer;
    CALayer *p = [_box presentationLayer];
    printf("[group] end opacity=%.2f radius=%.2f\n", p.opacity,
           p.cornerRadius);
    fflush(0);
}
- (void)removeGroup:(id)timer
{
    (void)timer;
    [_box removeAnimationForKey:@"group"];
    CALayer *p = [_box presentationLayer];
    printf("[group] removed opacity=%.2f radius=%.2f\n", p.opacity,
           p.cornerRadius);
    fflush(0);
}
@end

@implementation SceneDelegate
- (void)scene:(UIScene *)scene
    willConnectToSession:(UISceneSession *)session
                 options:(UISceneConnectionOptions *)connectionOptions
{
    (void)session;
    (void)connectionOptions;
    self.window = [[UIWindow alloc] initWithWindowScene:(UIWindowScene *)scene];
    self.window.frame = [[UIScreen mainScreen] bounds];
    self.window.backgroundColor =
        [UIColor colorWithRed:0.043 green:0.063 blue:0.125 alpha:1.0];
    self.window.rootViewController = [[GroupViewController alloc] init];
    [self.window makeKeyAndVisible];
}
@end

@implementation AppDelegate
- (UISceneConfiguration *)application:(UIApplication *)application
    configurationForConnectingSceneSession:(UISceneSession *)session
    options:(UISceneConnectionOptions *)options
{
    (void)application;
    (void)session;
    (void)options;
    UISceneConfiguration *configuration = [[UISceneConfiguration alloc]
        initWithName:@"Default Configuration"
         sessionRole:UIWindowSceneSessionRoleApplication];
    configuration.delegateClass = [SceneDelegate class];
    return configuration;
}
@end

int main(int argc, char **argv)
{
    @autoreleasepool
    {
        return UIApplicationMain(argc, argv, nil, @"AppDelegate");
    }
}
