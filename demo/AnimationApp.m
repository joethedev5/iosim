#if __has_include(<UIKit/UIKit.h>)
#import <UIKit/UIKit.h>
#else
#import "UIKitStub.h"
#endif

extern int printf(const char *fmt, ...);
extern int fflush(void *stream);

@interface SceneDelegate : UIResponder <UIWindowSceneDelegate>
@property(nonatomic, retain) UIWindow *window;
@end

@interface AppDelegate : UIResponder <UIApplicationDelegate>
@end

@implementation AppDelegate
- (UISceneConfiguration *)application:(UIApplication *)application
    configurationForConnectingSceneSession:(UISceneSession *)session
    options:(UISceneConnectionOptions *)options
{
    (void)application; (void)session; (void)options;
    UISceneConfiguration *configuration = [[UISceneConfiguration alloc]
        initWithName:@"Default Configuration"
         sessionRole:UIWindowSceneSessionRoleApplication];
    configuration.delegateClass = [SceneDelegate class];
    return configuration;
}
@end

@interface AnimationViewController : UIViewController {
    int _ticks;
    BOOL _running;
    double _pulseEnd;
}
@property(nonatomic, retain) UIView *box;
@property(nonatomic, retain) UIView *dot;
@property(nonatomic, retain) CADisplayLink *link;
@end

@implementation AnimationViewController
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
    CGRect screen = [[UIScreen mainScreen] bounds];
    double width = screen.size.width;
    UILabel *title =
        [[UILabel alloc] initWithFrame:CGRectMake(24, 120, width - 48, 48)];
    title.text = @"Core Animation";
    title.textColor = [UIColor whiteColor];
    title.font = [UIFont boldSystemFontOfSize:34];
    [self.view addSubview:title];

    self.box = [[UIView alloc] initWithFrame:CGRectMake(24, 300, width - 48, 120)];
    self.box.backgroundColor = [UIColor systemBlueColor];
    self.box.layer.cornerRadius = 22;
    [self.view addSubview:self.box];

    UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
    button.frame = CGRectMake(24, 600, width - 48, 56);
    button.backgroundColor =
        [UIColor colorWithRed:0.106 green:0.141 blue:0.251 alpha:1.0];
    button.layer.cornerRadius = 16;
    [button setTitle:@"Animate" forState:UIControlStateNormal];
    [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [button addTarget:self action:@selector(animate:)
        forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:button];

    self.dot = [[UIView alloc] initWithFrame:CGRectMake(40, 752, 24, 24)];
    self.dot.backgroundColor =
        [UIColor colorWithRed:0.35 green:0.85 blue:0.45 alpha:1.0];
    self.dot.layer.cornerRadius = 12;
    [self.view addSubview:self.dot];

    self.link = [CADisplayLink displayLinkWithTarget:self
                                            selector:@selector(step:)];
    [self.link addToRunLoop:nil forMode:nil];
    printf("[anim] app ready\n");
    fflush(0);
}
- (void)step:(CADisplayLink *)link
{
    _ticks++;
    double t = [link timestamp];
    double phase = t - (long)t;
    self.dot.frame = CGRectMake(40 + phase * 300.0, 752, 24, 24);
    if (_ticks % 10 == 0)
    {
        printf("[anim] tick %d\n", _ticks);
        if (_running)
        {
            CALayer *presentation = [self.box.layer presentationLayer];
            printf("[anim] present %.1f\n", presentation.frame.origin.y);
        }
    }
    if (_ticks % 5 == 0 && t < _pulseEnd)
    {
        CALayer *dotPresentation = [self.dot.layer presentationLayer];
        printf("[anim] dot %.2f\n", dotPresentation.opacity);
        printf("[anim] tracks %.2f %.2f\n", dotPresentation.opacity,
               dotPresentation.cornerRadius);
    }
    if (_ticks % 5 == 0)
        fflush(0);
}
- (void)animate:(id)sender
{
    (void)sender;
    _running = YES;
    _pulseEnd = [self.link timestamp] + 1.7;
    CAKeyframeAnimation *pulse =
        [CAKeyframeAnimation animationWithKeyPath:@"opacity"];
    pulse.duration = 0.8;
    pulse.repeatCount = 2.0;
    [pulse setValues:[NSArray arrayWithObjects:(const id[]){
        [NSNumber numberWithDouble:1.0], [NSNumber numberWithDouble:0.25],
        [NSNumber numberWithDouble:1.0]} count:3]];
    [pulse setKeyTimes:[NSArray arrayWithObjects:(const id[]){
        [NSNumber numberWithDouble:0.0], [NSNumber numberWithDouble:0.5],
        [NSNumber numberWithDouble:1.0]} count:3]];
    [self.dot.layer addAnimation:pulse forKey:@"pulse"];
    CAAnimation *corner = [CAAnimation animationWithKeyPath:@"cornerRadius"];
    corner.fromValue = [NSNumber numberWithDouble:12.0];
    corner.toValue = [NSNumber numberWithDouble:20.0];
    corner.duration = 2.0;
    corner.repeatCount = -1.0;
    [self.dot.layer addAnimation:corner forKey:@"corner"];
    [UIView animateWithDuration:2.0 delay:0.1
        options:UIViewAnimationOptionCurveEaseInOut
        animations:^{
            self.box.alpha = 0.15;
            self.box.frame = CGRectMake(24, 470, 354, 120);
        }
        completion:^(BOOL finished) {
            _running = NO;
            printf("[anim] completed %d\n", finished);
            fflush(0);
        }];
}
@end

@implementation SceneDelegate
- (void)scene:(UIScene *)scene
    willConnectToSession:(UISceneSession *)session
                 options:(UISceneConnectionOptions *)connectionOptions
{
    (void)session; (void)connectionOptions;
    self.window = [[UIWindow alloc] initWithWindowScene:(UIWindowScene *)scene];
    self.window.frame = [[UIScreen mainScreen] bounds];
    self.window.backgroundColor =
        [UIColor colorWithRed:0.043 green:0.063 blue:0.125 alpha:1.0];
    self.window.rootViewController = [[AnimationViewController alloc] init];
    [self.window makeKeyAndVisible];
}
@end

int main(int argc, char **argv)
{
    @autoreleasepool { return UIApplicationMain(argc, argv, nil, @"AppDelegate"); }
}
