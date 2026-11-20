/* CALayer mask: the mask layer's alpha channel becomes a coverage mask over
 * the masked layer and its sublayers. Covers a plain layer with a rect mask,
 * a view backing layer with an oval CAShapeLayer mask, and a half-alpha mask
 * that should blend the layer at 50 percent. */
#include "UIKitStub.h"

extern int printf(const char *fmt, ...);
extern int fflush(void *stream);
extern int iosim_fb_present(const char *path);
extern char *getenv(const char *name);
extern void exit(int status);

@interface MaskFixtureView : UIView
@end

@implementation MaskFixtureView
@end

@interface MaskCaptureView : UIView
@end

@implementation MaskCaptureView
- (void)drawRect:(CGRect)rect
{
    (void)rect;
    const char *path = getenv("IOSIM_TEST_PNG");
    if (!path)
        return;
    iosim_fb_present(path);
    printf("[mask] png written\n");
    fflush(0);
    exit(0);
}
@end

@interface MaskController : UIViewController
@end

@implementation MaskController
- (void)loadView
{
    UIView *root =
        [[UIView alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    root.backgroundColor =
        [UIColor colorWithRed:0.04 green:0.06 blue:0.12 alpha:1.0];

    /* A plain layer masked by a left-half rectangle. */
    CALayer *strip = [[CALayer alloc] init];
    strip.frame = CGRectMake(40, 120, 200, 100);
    strip.backgroundColor = [UIColor colorWithRed:1.0 green:0.0 blue:0.0
                                            alpha:1.0];
    CALayer *stripMask = [[CALayer alloc] init];
    stripMask.frame = CGRectMake(0, 0, 100, 100);
    stripMask.backgroundColor = [UIColor colorWithRed:0.0 green:1.0 blue:0.0
                                                alpha:1.0];
    strip.mask = stripMask;
    [root.layer addSublayer:strip];

    /* A view whose backing layer is masked by an oval shape layer. */
    MaskFixtureView *ovalView =
        [[MaskFixtureView alloc] initWithFrame:CGRectMake(40, 300, 200, 100)];
    ovalView.backgroundColor = [UIColor colorWithRed:0.0 green:0.2 blue:1.0
                                               alpha:1.0];
    CAShapeLayer *ovalMask = [[CAShapeLayer alloc] init];
    ovalMask.frame = CGRectMake(0, 0, 200, 100);
    ovalMask.fillColor = [UIColor whiteColor];
    ovalMask.path = [UIBezierPath bezierPathWithOvalInRect:
                         CGRectMake(0, 0, 200, 100)];
    ovalView.layer.mask = ovalMask;
    [root addSubview:ovalView];

    /* A 50 percent alpha mask: the red layer should blend with the
     * background instead of covering it or vanishing. */
    CALayer *half = [[CALayer alloc] init];
    half.frame = CGRectMake(40, 500, 200, 60);
    half.backgroundColor = [UIColor colorWithRed:1.0 green:0.0 blue:0.0
                                           alpha:1.0];
    CALayer *halfMask = [[CALayer alloc] init];
    halfMask.frame = CGRectMake(0, 0, 200, 60);
    halfMask.backgroundColor = [UIColor colorWithRed:1.0 green:1.0 blue:1.0
                                               alpha:0.5];
    half.mask = halfMask;
    [root.layer addSublayer:half];

    printf("[mask] masks %d %d %d\n", strip.mask == stripMask,
           ovalView.layer.mask == ovalMask ? 1 : 0,
           half.mask == halfMask);

    MaskCaptureView *capture =
        [[MaskCaptureView alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    capture.backgroundColor = [UIColor clearColor];
    [root addSubview:capture];
    self.view = root;
}
@end

@interface MaskSceneDelegate : UIResponder <UIWindowSceneDelegate>
@property(nonatomic, retain) UIWindow *window;
@end

@interface MaskAppDelegate : UIResponder <UIApplicationDelegate>
@end

@implementation MaskAppDelegate
- (UISceneConfiguration *)application:(UIApplication *)application
    configurationForConnectingSceneSession:(UISceneSession *)session
    options:(UISceneConnectionOptions *)options
{
    (void)application; (void)session; (void)options;
    UISceneConfiguration *configuration = [[UISceneConfiguration alloc]
        initWithName:@"Default Configuration"
         sessionRole:UIWindowSceneSessionRoleApplication];
    configuration.delegateClass = [MaskSceneDelegate class];
    return configuration;
}
@end

@implementation MaskSceneDelegate
- (void)scene:(UIScene *)scene
    willConnectToSession:(UISceneSession *)session
                 options:(UISceneConnectionOptions *)connectionOptions
{
    (void)session; (void)connectionOptions;
    self.window = [[UIWindow alloc] initWithWindowScene:(UIWindowScene *)scene];
    self.window.frame = [[UIScreen mainScreen] bounds];
    self.window.rootViewController = [[MaskController alloc] init];
    [self.window makeKeyAndVisible];
}
@end

int main(int argc, char **argv)
{
    @autoreleasepool
    {
        return UIApplicationMain(argc, argv, nil, @"MaskAppDelegate");
    }
}
