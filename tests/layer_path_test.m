/* CAKeyframeAnimation.path: a straight line and a quadratic curve move
 * their views along the path by arc length. */
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

@interface PathCapture : UIView
@end

@implementation PathCapture
- (void)drawRect:(CGRect)rect
{
    (void)rect;
    if (!g_capture_ready)
        return;
    const char *path = getenv("IOSIM_TEST_PNG");
    if (!path)
        return;
    iosim_fb_present(path);
    printf("[lpath] png written\n");
    fflush(0);
    exit(0);
}
@end

@interface PathController : UIViewController {
@public
    UIView *_line;
    UIView *_curve;
    PathCapture *_capture;
}
@end

@implementation PathController
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

    _line = [self boxAt:CGRectMake(40, 280, 40, 40)];
    _curve = [self boxAt:CGRectMake(40, 480, 40, 40)];

    CGPathRef line = CGPathCreateMutable();
    CGPathMoveToPoint(line, 0, 60, 300);
    CGPathAddLineToPoint(line, 0, 260, 300);
    CAKeyframeAnimation *lineAnim =
        [CAKeyframeAnimation animationWithKeyPath:@"position"];
    [lineAnim setDuration:2.0];
    [lineAnim setPath:line];
    [_line.layer addAnimation:lineAnim forKey:@"line"];

    CGPathRef curve = CGPathCreateMutable();
    CGPathMoveToPoint(curve, 0, 60, 500);
    CGPathAddQuadCurveToPoint(curve, 0, 160, 450, 260, 500);
    CAKeyframeAnimation *curveAnim =
        [CAKeyframeAnimation animationWithKeyPath:@"position"];
    [curveAnim setDuration:0.5];
    [curveAnim setPath:curve];
    [_curve.layer addAnimation:curveAnim forKey:@"curve"];

    CGRect screen = [[UIScreen mainScreen] bounds];
    _capture = [[PathCapture alloc] initWithFrame:screen];
    _capture.backgroundColor = [UIColor clearColor];
    [root addSubview:_capture];

    printf("[lpath] ready\n");
    fflush(0);
    dispatch_after(dispatch_time(0, 250 * 1000000LL),
                   dispatch_get_main_queue(), ^{
        CGRect lineFrame = [[_line layer] presentationLayer].frame;
        CGRect curveFrame = [[_curve layer] presentationLayer].frame;
        printf("[lpath] line %.1f %.1f\n", lineFrame.origin.x,
               lineFrame.origin.y);
        printf("[lpath] curve %.1f %.1f\n", curveFrame.origin.x,
               curveFrame.origin.y);
        fflush(0);
        g_capture_ready = 1;
        [_capture setNeedsDisplay];
    });
}
@end

@interface PathSceneDelegate : UIResponder <UIWindowSceneDelegate>
@property(nonatomic, retain) UIWindow *window;
@end

@interface PathAppDelegate : UIResponder <UIApplicationDelegate>
@end

@implementation PathAppDelegate
- (UISceneConfiguration *)application:(UIApplication *)application
    configurationForConnectingSceneSession:(UISceneSession *)session
    options:(UISceneConnectionOptions *)connectionOptions
{
    (void)application; (void)session; (void)connectionOptions;
    UISceneConfiguration *configuration = [[UISceneConfiguration alloc]
        initWithName:@"Default Configuration"
         sessionRole:UIWindowSceneSessionRoleApplication];
    configuration.delegateClass = [PathSceneDelegate class];
    return configuration;
}
@end

@implementation PathSceneDelegate
- (void)scene:(UIScene *)scene
    willConnectToSession:(UISceneSession *)session
                 options:(UISceneConnectionOptions *)connectionOptions
{
    (void)session; (void)connectionOptions;
    self.window = [[UIWindow alloc] initWithWindowScene:(UIWindowScene *)scene];
    self.window.frame = [[UIScreen mainScreen] bounds];
    self.window.rootViewController = [[PathController alloc] init];
    [self.window makeKeyAndVisible];
}
@end

int main(int argc, char **argv)
{
    @autoreleasepool
    {
        return UIApplicationMain(argc, argv, nil, @"PathAppDelegate");
    }
}
