/* Direct CALayer position animations: a CABasicAnimation from/to pair and a
 * CAKeyframeAnimation through NSValue points move their views on screen. */
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

static int g_capture_ready;

@interface PositionCapture : UIView
@end

@implementation PositionCapture
- (void)drawRect:(CGRect)rect
{
    (void)rect;
    if (!g_capture_ready)
        return;
    const char *path = getenv("IOSIM_TEST_PNG");
    if (!path)
        return;
    iosim_fb_present(path);
    printf("[lpos] png written\n");
    fflush(0);
    exit(0);
}
@end

@interface PositionController : UIViewController {
@public
    UIView *_basic;
    UIView *_keyed;
    PositionCapture *_capture;
}
@end

@implementation PositionController
- (UIView *)boxAt:(CGRect)frame
{
    UIView *box = [[UIView alloc] initWithFrame:frame];
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

    _basic = [self boxAt:CGRectMake(40, 280, 40, 40)];
    _keyed = [self boxAt:CGRectMake(40, 480, 40, 40)];

    CABasicAnimation *basic =
        [CABasicAnimation animationWithKeyPath:@"position"];
    basic.duration = 2.0;
    basic.fromValue = [NSValue valueWithCGPoint:CGPointMake(60, 300)];
    basic.toValue = [NSValue valueWithCGPoint:CGPointMake(260, 300)];
    [_basic.layer addAnimation:basic forKey:@"move"];

    CAKeyframeAnimation *keyed =
        [CAKeyframeAnimation animationWithKeyPath:@"position"];
    keyed.duration = 2.0;
    id points[3] = {
        [NSValue valueWithCGPoint:CGPointMake(60, 500)],
        [NSValue valueWithCGPoint:CGPointMake(260, 500)],
        [NSValue valueWithCGPoint:CGPointMake(160, 500)]
    };
    id times[3] = { [NSNumber numberWithDouble:0.0],
                    [NSNumber numberWithDouble:0.5],
                    [NSNumber numberWithDouble:1.0] };
    [keyed setValues:[NSArray arrayWithObjects:points count:3]];
    [keyed setKeyTimes:[NSArray arrayWithObjects:times count:3]];
    [_keyed.layer addAnimation:keyed forKey:@"step"];

    CGRect screen = [[UIScreen mainScreen] bounds];
    _capture = [[PositionCapture alloc] initWithFrame:screen];
    _capture.backgroundColor = [UIColor clearColor];
    [root addSubview:_capture];

    printf("[lpos] ready\n");
    fflush(0);
    dispatch_after(dispatch_time(0, 250 * 1000000LL),
                   dispatch_get_main_queue(), ^{
        CGRect basicFrame = [[_basic layer] presentationLayer].frame;
        CGRect keyedFrame = [[_keyed layer] presentationLayer].frame;
        printf("[lpos] basic %.1f %.1f\n", basicFrame.origin.x,
               basicFrame.origin.y);
        printf("[lpos] key %.1f %.1f\n", keyedFrame.origin.x,
               keyedFrame.origin.y);
        fflush(0);
        g_capture_ready = 1;
        [_capture setNeedsDisplay];
    });
}
@end

@interface PositionSceneDelegate : UIResponder <UIWindowSceneDelegate>
@property(nonatomic, retain) UIWindow *window;
@end

@interface PositionAppDelegate : UIResponder <UIApplicationDelegate>
@end

@implementation PositionAppDelegate
- (UISceneConfiguration *)application:(UIApplication *)application
    configurationForConnectingSceneSession:(UISceneSession *)session
    options:(UISceneConnectionOptions *)connectionOptions
{
    (void)application; (void)session; (void)connectionOptions;
    UISceneConfiguration *configuration = [[UISceneConfiguration alloc]
        initWithName:@"Default Configuration"
         sessionRole:UIWindowSceneSessionRoleApplication];
    configuration.delegateClass = [PositionSceneDelegate class];
    return configuration;
}
@end

@implementation PositionSceneDelegate
- (void)scene:(UIScene *)scene
    willConnectToSession:(UISceneSession *)session
                 options:(UISceneConnectionOptions *)connectionOptions
{
    (void)session; (void)connectionOptions;
    self.window = [[UIWindow alloc] initWithWindowScene:(UIWindowScene *)scene];
    self.window.frame = [[UIScreen mainScreen] bounds];
    self.window.rootViewController = [[PositionController alloc] init];
    [self.window makeKeyAndVisible];
}
@end

int main(int argc, char **argv)
{
    @autoreleasepool
    {
        return UIApplicationMain(argc, argv, nil, @"PositionAppDelegate");
    }
}
