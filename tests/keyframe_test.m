/* UIView keyframes: move right, pause, then move down. */
#include "UIKitStub.h"

extern int printf(const char *fmt, ...);
extern int fflush(void *stream);

@interface KeyframeController : UIViewController {
@public
    UIView *_box;
}
@end

@implementation KeyframeController
- (void)loadView
{
    UIView *root =
        [[UIView alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    root.backgroundColor = [UIColor blackColor];
    _box = [[UIView alloc] initWithFrame:CGRectMake(100, 300, 100, 100)];
    _box.backgroundColor = [UIColor whiteColor];
    [root addSubview:_box];
    self.view = root;

    [UIView animateKeyframesWithDuration:1.0 delay:0.0 options:0
        animations:^{
            [UIView addKeyframeWithRelativeStartTime:0.0
                relativeDuration:0.25 animations:^{
                    _box.frame = CGRectMake(100, 300, 100, 100);
                }];
            [UIView addKeyframeWithRelativeStartTime:0.25
                relativeDuration:0.25 animations:^{
                    _box.frame = CGRectMake(200, 300, 100, 100);
                }];
            [UIView addKeyframeWithRelativeStartTime:0.5
                relativeDuration:0.5 animations:^{
                    _box.frame = CGRectMake(200, 500, 100, 100);
                }];
        }
        completion:^(BOOL finished) {
            printf("[keyframe] done %d\n", finished ? 1 : 0);
            fflush(0);
        }];

    [NSTimer scheduledTimerWithTimeInterval:0.35 target:self
        selector:@selector(checkMove:) userInfo:nil repeats:NO];
    [NSTimer scheduledTimerWithTimeInterval:0.6 target:self
        selector:@selector(checkTurn:) userInfo:nil repeats:NO];
    [NSTimer scheduledTimerWithTimeInterval:1.2 target:self
        selector:@selector(checkDone:) userInfo:nil repeats:NO];
    printf("[keyframe] ready\n");
    fflush(0);
}

- (void)checkMove:(NSTimer *)timer
{
    (void)timer;
    CALayer *presentation = [[_box layer] presentationLayer];
    printf("[keyframe] move %.0f %.0f\n", presentation.frame.origin.x,
           presentation.frame.origin.y);
    fflush(0);
}
- (void)checkTurn:(NSTimer *)timer
{
    (void)timer;
    CALayer *presentation = [[_box layer] presentationLayer];
    printf("[keyframe] turn %.0f %.0f\n", presentation.frame.origin.x,
           presentation.frame.origin.y);
    fflush(0);
}
- (void)checkDone:(NSTimer *)timer
{
    (void)timer;
    CALayer *presentation = [[_box layer] presentationLayer];
    printf("[keyframe] end %.0f %.0f\n", presentation.frame.origin.x,
           presentation.frame.origin.y);
    fflush(0);
}
@end

@interface KeyframeSceneDelegate : UIResponder <UIWindowSceneDelegate>
@property(nonatomic, retain) UIWindow *window;
@end

@interface KeyframeAppDelegate : UIResponder <UIApplicationDelegate>
@end

@implementation KeyframeAppDelegate
- (UISceneConfiguration *)application:(UIApplication *)application
    configurationForConnectingSceneSession:(UISceneSession *)session
    options:(UISceneConnectionOptions *)connectionOptions
{
    (void)application; (void)session; (void)connectionOptions;
    UISceneConfiguration *configuration = [[UISceneConfiguration alloc]
        initWithName:@"Default Configuration"
         sessionRole:UIWindowSceneSessionRoleApplication];
    configuration.delegateClass = [KeyframeSceneDelegate class];
    return configuration;
}
@end

@implementation KeyframeSceneDelegate
- (void)scene:(UIScene *)scene
    willConnectToSession:(UISceneSession *)session
                 options:(UISceneConnectionOptions *)connectionOptions
{
    (void)session; (void)connectionOptions;
    self.window = [[UIWindow alloc] initWithWindowScene:(UIWindowScene *)scene];
    self.window.frame = [[UIScreen mainScreen] bounds];
    self.window.rootViewController = [[KeyframeController alloc] init];
    [self.window makeKeyAndVisible];
}
@end

int main(int argc, char **argv)
{
    @autoreleasepool
    {
        return UIApplicationMain(argc, argv, nil, @"KeyframeAppDelegate");
    }
}
