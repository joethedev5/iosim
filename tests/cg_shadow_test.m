/* CGContext shadows: a white rect with a red hard offset shadow and a white
 * ellipse path with a blurred, left-shifted blue shadow. */
#include "UIKitStub.h"

extern int printf(const char *fmt, ...);
extern int fflush(void *stream);
extern void exit(int status);
extern int iosim_fb_present(const char *path);
extern char *getenv(const char *name);
extern unsigned long long dispatch_time(unsigned long long when,
                                        long long delta);
extern void dispatch_after(unsigned long long when, void *queue,
                           void (^block)(void));
extern void *dispatch_get_main_queue(void);

static int g_cg_shadow_ready;

@interface ShadowShapes : UIView
@end

@implementation ShadowShapes
- (void)drawRect:(CGRect)rect
{
    (void)rect;
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    if (!ctx)
        return;
    CGColorRef red = CGColorCreateGenericRGB(1, 0, 0, 1);
    CGColorRef blue = CGColorCreateGenericRGB(0, 0, 1, 1);
    CGContextSetShadowWithColor(ctx, CGSizeMake(4, 4), 0, red);
    CGContextSetRGBFillColor(ctx, 1, 1, 1, 1);
    CGContextFillRect(ctx, CGRectMake(40, 120, 120, 80));
    CGContextSetShadowWithColor(ctx, CGSizeMake(-4, 4), 3, blue);
    CGContextAddEllipseInRect(ctx, CGRectMake(220, 130, 120, 80));
    CGContextSetRGBFillColor(ctx, 1, 1, 1, 1);
    CGContextFillPath(ctx);
    CGColorRelease(red);
    CGColorRelease(blue);
}
@end

@interface ShadowCapture : UIView
@end

@implementation ShadowCapture
- (void)drawRect:(CGRect)rect
{
    (void)rect;
    if (!g_cg_shadow_ready)
        return;
    const char *path = getenv("IOSIM_TEST_PNG");
    if (!path)
        return;
    iosim_fb_present(path);
    printf("[cgshadow] png written\n");
    fflush(0);
    exit(0);
}
@end

@interface CGShadowController : UIViewController
@end

@implementation CGShadowController
- (void)loadView
{
    UIView *root =
        [[UIView alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    root.backgroundColor = [UIColor blackColor];
    self.view = root;

    ShadowShapes *shapes =
        [[ShadowShapes alloc] initWithFrame:root.bounds];
    shapes.backgroundColor = [UIColor clearColor];
    [root addSubview:shapes];

    ShadowCapture *capture =
        [[ShadowCapture alloc] initWithFrame:root.bounds];
    capture.backgroundColor = [UIColor clearColor];
    [root addSubview:capture];

    printf("[cgshadow] ready\n");
    fflush(0);
    dispatch_after(dispatch_time(0, 200 * 1000000LL),
                   dispatch_get_main_queue(), ^{
        printf("[cgshadow] done\n");
        fflush(0);
        g_cg_shadow_ready = 1;
        [shapes setNeedsDisplay];
        [capture setNeedsDisplay];
    });
}
@end

@interface CGShadowSceneDelegate : UIResponder <UIWindowSceneDelegate>
@property(nonatomic, retain) UIWindow *window;
@end

@interface CGShadowAppDelegate : UIResponder <UIApplicationDelegate>
@end

@implementation CGShadowAppDelegate
- (UISceneConfiguration *)application:(UIApplication *)application
    configurationForConnectingSceneSession:(UISceneSession *)session
    options:(UISceneConnectionOptions *)connectionOptions
{
    (void)application; (void)session; (void)connectionOptions;
    UISceneConfiguration *configuration = [[UISceneConfiguration alloc]
        initWithName:@"Default Configuration"
         sessionRole:UIWindowSceneSessionRoleApplication];
    configuration.delegateClass = [CGShadowSceneDelegate class];
    return configuration;
}
@end

@implementation CGShadowSceneDelegate
- (void)scene:(UIScene *)scene
    willConnectToSession:(UISceneSession *)session
                 options:(UISceneConnectionOptions *)connectionOptions
{
    (void)session; (void)connectionOptions;
    self.window = [[UIWindow alloc] initWithWindowScene:(UIWindowScene *)scene];
    self.window.frame = [[UIScreen mainScreen] bounds];
    self.window.rootViewController = [[CGShadowController alloc] init];
    [self.window makeKeyAndVisible];
}
@end

int main(int argc, char **argv)
{
    @autoreleasepool
    {
        return UIApplicationMain(argc, argv, nil, @"CGShadowAppDelegate");
    }
}
