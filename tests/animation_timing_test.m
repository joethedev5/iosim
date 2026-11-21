/* Samples CAAnimation timing properties through presentation layers and
 * checks CATransaction / performWithoutAnimation: behavior. */
#include "UIKitStub.h"

extern int printf(const char *fmt, ...);
extern int fflush(void *stream);

@interface TimingController : UIViewController {
@public
    CALayer *_fill;
    CALayer *_reverse;
    CALayer *_speed;
    CALayer *_offset;
}
@end

@implementation TimingController
- (CALayer *)boxAtX:(double)x
{
    CALayer *box = [[CALayer alloc] init];
    box.frame = CGRectMake(x, 100, 80, 80);
    box.backgroundColor = [UIColor whiteColor];
    [self.view.layer addSublayer:box];
    return box;
}

- (void)loadView
{
    UIView *root =
        [[UIView alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    root.backgroundColor = [UIColor blackColor];
    self.view = root;

    _fill = [self boxAtX:40];
    CABasicAnimation *fill =
        [CABasicAnimation animationWithKeyPath:@"opacity"];
    fill.fromValue = [NSNumber numberWithDouble:1.0];
    fill.toValue = [NSNumber numberWithDouble:0.0];
    fill.duration = 1.0;
    fill.beginTime = CACurrentMediaTime() + 0.5;
    fill.fillMode = @"backwards";
    [_fill addAnimation:fill forKey:@"fill"];

    _reverse = [self boxAtX:160];
    CABasicAnimation *reverse =
        [CABasicAnimation animationWithKeyPath:@"opacity"];
    reverse.fromValue = [NSNumber numberWithDouble:1.0];
    reverse.toValue = [NSNumber numberWithDouble:0.0];
    reverse.duration = 1.0;
    reverse.autoreverses = YES;
    [_reverse addAnimation:reverse forKey:@"reverse"];

    _speed = [self boxAtX:280];
    CABasicAnimation *speed =
        [CABasicAnimation animationWithKeyPath:@"opacity"];
    speed.fromValue = [NSNumber numberWithDouble:1.0];
    speed.toValue = [NSNumber numberWithDouble:0.0];
    speed.duration = 1.0;
    speed.speed = 2.0;
    [_speed addAnimation:speed forKey:@"speed"];

    _offset = [self boxAtX:400];
    CABasicAnimation *offset =
        [CABasicAnimation animationWithKeyPath:@"opacity"];
    offset.fromValue = [NSNumber numberWithDouble:1.0];
    offset.toValue = [NSNumber numberWithDouble:0.0];
    offset.duration = 1.0;
    offset.timeOffset = 0.5;
    [_offset addAnimation:offset forKey:@"offset"];

    [CATransaction begin];
    [CATransaction setAnimationDuration:0.5];
    [CATransaction setCompletionBlock:^{
        printf("[timing] transaction done\n");
        fflush(0);
    }];
    [CATransaction commit];
    printf("[timing] transaction duration %.2f\n",
           [CATransaction animationDuration]);
    fflush(0);

    [UIView performWithoutAnimation:^{
        [UIView animateWithDuration:5.0 animations:^{
            _speed.opacity = 0.9;
        } completion:^(BOOL finished) {
            printf("[timing] no-anim completion %d\n", finished ? 1 : 0);
            fflush(0);
        }];
    }];

    [NSTimer scheduledTimerWithTimeInterval:0.2 target:self
        selector:@selector(checkFillEarly:) userInfo:nil repeats:NO];
    [NSTimer scheduledTimerWithTimeInterval:0.75 target:self
        selector:@selector(checkFillMid:) userInfo:nil repeats:NO];
    [NSTimer scheduledTimerWithTimeInterval:1.7 target:self
        selector:@selector(checkFillDone:) userInfo:nil repeats:NO];
    [NSTimer scheduledTimerWithTimeInterval:0.25 target:self
        selector:@selector(checkReverseEarly:) userInfo:nil repeats:NO];
    [NSTimer scheduledTimerWithTimeInterval:0.75 target:self
        selector:@selector(checkReverseMid:) userInfo:nil repeats:NO];
    [NSTimer scheduledTimerWithTimeInterval:1.15 target:self
        selector:@selector(checkReverseDone:) userInfo:nil repeats:NO];
    [NSTimer scheduledTimerWithTimeInterval:0.3 target:self
        selector:@selector(checkSpeed:) userInfo:nil repeats:NO];
    [NSTimer scheduledTimerWithTimeInterval:0.1 target:self
        selector:@selector(checkOffset:) userInfo:nil repeats:NO];

    printf("[timing] animations enabled %d\n",
           [UIView areAnimationsEnabled] ? 1 : 0);
    printf("[timing] ready\n");
    fflush(0);
}

- (void)checkFillEarly:(NSTimer *)timer
{
    (void)timer;
    printf("[timing] fill %.2f\n", [[_fill presentationLayer] opacity]);
    fflush(0);
}
- (void)checkFillMid:(NSTimer *)timer
{
    (void)timer;
    printf("[timing] fill %.2f\n", [[_fill presentationLayer] opacity]);
    fflush(0);
}
- (void)checkFillDone:(NSTimer *)timer
{
    (void)timer;
    printf("[timing] fill %.2f\n", [[_fill presentationLayer] opacity]);
    fflush(0);
}
- (void)checkReverseEarly:(NSTimer *)timer
{
    (void)timer;
    printf("[timing] reverse %.2f\n", [[_reverse presentationLayer] opacity]);
    fflush(0);
}
- (void)checkReverseMid:(NSTimer *)timer
{
    (void)timer;
    printf("[timing] reverse %.2f\n", [[_reverse presentationLayer] opacity]);
    fflush(0);
}
- (void)checkReverseDone:(NSTimer *)timer
{
    (void)timer;
    printf("[timing] reverse %.2f\n", [[_reverse presentationLayer] opacity]);
    fflush(0);
}
- (void)checkSpeed:(NSTimer *)timer
{
    (void)timer;
    printf("[timing] speed %.2f\n", [[_speed presentationLayer] opacity]);
    fflush(0);
}
- (void)checkOffset:(NSTimer *)timer
{
    (void)timer;
    printf("[timing] offset %.2f\n", [[_offset presentationLayer] opacity]);
    fflush(0);
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
