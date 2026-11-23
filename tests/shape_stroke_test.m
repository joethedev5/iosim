/* CAShapeLayer stroke trimming: strokeStart/strokeEnd trim open lines,
 * ovals and rounded rectangles by arc length, and round caps close the
 * trimmed ends. */
#include "UIKitStub.h"

extern int printf(const char *fmt, ...);
extern int fflush(void *stream);
extern int iosim_fb_present(const char *path);
extern char *getenv(const char *name);
extern void exit(int status);

@interface StrokeCaptureView : UIView
@end

@implementation StrokeCaptureView
- (void)drawRect:(CGRect)rect
{
    (void)rect;
    const char *path = getenv("IOSIM_TEST_PNG");
    if (!path)
        return;
    iosim_fb_present(path);
    printf("[stroke] png written\n");
    fflush(0);
    exit(0);
}
@end

@interface StrokeController : UIViewController
@end

@implementation StrokeController
- (void)loadView
{
    UIView *root =
        [[UIView alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    root.backgroundColor =
        [UIColor colorWithRed:0.04 green:0.06 blue:0.12 alpha:1.0];
    CGRect screen = [[UIScreen mainScreen] bounds];

    CAShapeLayer *line = [[CAShapeLayer alloc] init];
    line.frame = screen;
    UIBezierPath *line_path = [UIBezierPath bezierPath];
    [line_path moveToPoint:CGPointMake(40, 100)];
    [line_path addLineToPoint:CGPointMake(240, 100)];
    line.path = line_path;
    line.strokeColor = [UIColor colorWithRed:0.0 green:1.0 blue:0.2
                                       alpha:1.0];
    line.lineWidth = 8.0;
    line.strokeStart = 0.25;
    line.strokeEnd = 0.75;
    line.lineCap = 1;
    [root.layer addSublayer:line];

    CAShapeLayer *ring = [[CAShapeLayer alloc] init];
    ring.frame = screen;
    ring.path = [UIBezierPath bezierPathWithOvalInRect:
                     CGRectMake(120, 180, 160, 160)];
    ring.strokeColor = [UIColor colorWithRed:0.0 green:0.3 blue:1.0
                                       alpha:1.0];
    ring.lineWidth = 10.0;
    ring.strokeStart = 0.0;
    ring.strokeEnd = 0.5;
    [root.layer addSublayer:ring];

    CAShapeLayer *round = [[CAShapeLayer alloc] init];
    round.frame = screen;
    round.path = [UIBezierPath bezierPathWithRoundedRect:
                      CGRectMake(40, 400, 160, 100) cornerRadius:24.0];
    round.strokeColor = [UIColor colorWithRed:1.0 green:0.5 blue:0.0
                                        alpha:1.0];
    round.lineWidth = 8.0;
    round.strokeStart = 0.0;
    round.strokeEnd = 0.5;
    [root.layer addSublayer:round];

    CAShapeLayer *dashed = [[CAShapeLayer alloc] init];
    dashed.frame = screen;
    UIBezierPath *dash_path = [UIBezierPath bezierPath];
    [dash_path moveToPoint:CGPointMake(40, 560)];
    [dash_path addLineToPoint:CGPointMake(360, 560)];
    dashed.path = dash_path;
    dashed.strokeColor = [UIColor colorWithRed:1.0 green:0.9 blue:0.0
                                         alpha:1.0];
    dashed.lineWidth = 8.0;
    dashed.lineCap = 0;
    dashed.lineJoin = 0;
    dashed.lineDashPattern =
        [NSArray arrayWithObjects:[NSNumber numberWithInt:12],
                                  [NSNumber numberWithInt:12], nil];
    dashed.lineDashPhase = 0;
    [root.layer addSublayer:dashed];

    printf("[stroke] props %d\n",
           line.strokeStart > 0.24 && line.strokeEnd < 0.76 &&
               line.lineCap == 1 && ring.strokeEnd < 0.51 &&
               round.lineWidth > 7.9);
    printf("[stroke] dashprops %lu %d\n",
           (unsigned long)[[dashed lineDashPattern] count], dashed.lineJoin);

    StrokeCaptureView *capture = [[StrokeCaptureView alloc]
        initWithFrame:screen];
    capture.backgroundColor = [UIColor clearColor];
    [root addSubview:capture];
    self.view = root;
}
@end

@interface StrokeSceneDelegate : UIResponder <UIWindowSceneDelegate>
@property(nonatomic, retain) UIWindow *window;
@end

@interface StrokeAppDelegate : UIResponder <UIApplicationDelegate>
@end

@implementation StrokeAppDelegate
- (UISceneConfiguration *)application:(UIApplication *)application
    configurationForConnectingSceneSession:(UISceneSession *)session
    options:(UISceneConnectionOptions *)connectionOptions
{
    (void)application; (void)session; (void)connectionOptions;
    UISceneConfiguration *configuration = [[UISceneConfiguration alloc]
        initWithName:@"Default Configuration"
         sessionRole:UIWindowSceneSessionRoleApplication];
    configuration.delegateClass = [StrokeSceneDelegate class];
    return configuration;
}
@end

@implementation StrokeSceneDelegate
- (void)scene:(UIScene *)scene
    willConnectToSession:(UISceneSession *)session
                 options:(UISceneConnectionOptions *)connectionOptions
{
    (void)session; (void)connectionOptions;
    self.window = [[UIWindow alloc] initWithWindowScene:(UIWindowScene *)scene];
    self.window.frame = [[UIScreen mainScreen] bounds];
    self.window.rootViewController = [[StrokeController alloc] init];
    [self.window makeKeyAndVisible];
}
@end

int main(int argc, char **argv)
{
    @autoreleasepool
    {
        return UIApplicationMain(argc, argv, nil, @"StrokeAppDelegate");
    }
}
