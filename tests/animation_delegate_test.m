/* CAAnimationDelegate: start callbacks for every animation, finished=YES
 * when the duration elapses, finished=NO when removed early. */
#include "UIKitStub.h"

extern int printf(const char *fmt, ...);
extern int fflush(void *stream);

@interface DelegateController : UIViewController <CAAnimationDelegate> {
@public
    UIView *_box;
    int _started;
    int _stopped;
}
- (void)phaseOne;
- (void)phaseTwo;
@end

@implementation DelegateController
- (void)loadView
{
    UIView *root =
        [[UIView alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    root.backgroundColor = [UIColor blackColor];
    _box = [[UIView alloc] initWithFrame:CGRectMake(100, 300, 120, 120)];
    _box.backgroundColor = [UIColor orangeColor];
    [root addSubview:_box];
    self.view = root;

    CAAnimation *fade = [CABasicAnimation animationWithKeyPath:@"opacity"];
    fade.duration = 0.3;
    fade.fromValue = [NSNumber numberWithDouble:1.0];
    fade.toValue = [NSNumber numberWithDouble:0.2];
    fade.delegate = self;
    [_box.layer addAnimation:fade forKey:@"fade"];

    CAAnimation *longFade = [CABasicAnimation animationWithKeyPath:@"opacity"];
    longFade.duration = 2.0;
    longFade.fromValue = [NSNumber numberWithDouble:1.0];
    longFade.toValue = [NSNumber numberWithDouble:0.0];
    longFade.delegate = self;
    [_box.layer addAnimation:longFade forKey:@"long"];

    CAAnimation *forever = [CABasicAnimation animationWithKeyPath:@"opacity"];
    forever.duration = 0.5;
    forever.repeatCount = -1;
    forever.fromValue = [NSNumber numberWithDouble:1.0];
    forever.toValue = [NSNumber numberWithDouble:0.5];
    forever.delegate = self;
    [_box.layer addAnimation:forever forKey:@"forever"];

    [NSTimer scheduledTimerWithTimeInterval:0.1 target:self
        selector:@selector(phaseOne) userInfo:nil repeats:NO];
    [NSTimer scheduledTimerWithTimeInterval:0.7 target:self
        selector:@selector(phaseTwo) userInfo:nil repeats:NO];
    printf("[delegate] begin\n");
    fflush(0);
}

- (void)phaseOne
{
    [_box.layer removeAnimationForKey:@"long"];
    [_box.layer removeAnimationForKey:@"forever"];
}

- (void)phaseTwo
{
    printf("[delegate] counts %d %d\n", _started, _stopped);
    printf("[delegate] done\n");
    fflush(0);
}

- (void)animationDidStart:(CAAnimation *)anim
{
    (void)anim;
    _started++;
    printf("[delegate] start %d\n", _started);
    fflush(0);
}

- (void)animationDidStop:(CAAnimation *)anim finished:(BOOL)finished
{
    (void)anim;
    _stopped++;
    printf("[delegate] stop %d\n", finished ? 1 : 0);
    fflush(0);
}
@end

@interface DelegateSceneDelegate : UIResponder <UIWindowSceneDelegate>
@property(nonatomic, retain) UIWindow *window;
@end

@interface DelegateAppDelegate : UIResponder <UIApplicationDelegate>
@end

@implementation DelegateAppDelegate
- (UISceneConfiguration *)application:(UIApplication *)application
    configurationForConnectingSceneSession:(UISceneSession *)session
    options:(UISceneConnectionOptions *)connectionOptions
{
    (void)application; (void)session; (void)connectionOptions;
    UISceneConfiguration *configuration = [[UISceneConfiguration alloc]
        initWithName:@"Default Configuration"
         sessionRole:UIWindowSceneSessionRoleApplication];
    configuration.delegateClass = [DelegateSceneDelegate class];
    return configuration;
}
@end

@implementation DelegateSceneDelegate
- (void)scene:(UIScene *)scene
    willConnectToSession:(UISceneSession *)session
                 options:(UISceneConnectionOptions *)connectionOptions
{
    (void)session; (void)connectionOptions;
    self.window = [[UIWindow alloc] initWithWindowScene:(UIWindowScene *)scene];
    self.window.frame = [[UIScreen mainScreen] bounds];
    self.window.rootViewController = [[DelegateController alloc] init];
    [self.window makeKeyAndVisible];
}
@end

int main(int argc, char **argv)
{
    @autoreleasepool
    {
        return UIApplicationMain(argc, argv, nil, @"DelegateAppDelegate");
    }
}
