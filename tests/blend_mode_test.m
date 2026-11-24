/* CGContext blend modes: red fills over a 50% gray field show channel-wise
 * blending for the common modes, plus Copy, Clear, DestinationOut and
 * PlusDarker, and one path-filled box. */
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

static int g_blend_capture_ready;

@interface BlendCapture : UIView
@end

@implementation BlendCapture
- (void)drawRect:(CGRect)rect
{
    (void)rect;
    if (!g_blend_capture_ready)
        return;
    const char *path = getenv("IOSIM_TEST_PNG");
    if (!path)
        return;
    iosim_fb_present(path);
    printf("[blend] png written\n");
    fflush(0);
    exit(0);
}
@end

@interface BlendView : UIView
@end

@implementation BlendView
- (void)drawRect:(CGRect)rect
{
    (void)rect;
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetRGBFillColor(context, 0.5, 0.5, 0.5, 1.0);
    CGContextFillRect(context, CGRectMake(0, 0, 360, 240));

    int modes[6] = {
        kCGBlendModeMultiply, kCGBlendModeScreen, kCGBlendModeDarken,
        kCGBlendModeLighten, kCGBlendModeDifference, kCGBlendModePlusLighter
    };
    for (int i = 0; i < 6; i++)
    {
        CGContextSetBlendMode(context, modes[i]);
        CGContextSetRGBFillColor(context, 1.0, 0.0, 0.0, 1.0);
        CGContextFillRect(context, CGRectMake(12 + i * 52, 20, 44, 44));
    }

    int modes2[4] = {
        kCGBlendModeCopy, kCGBlendModeClear, kCGBlendModeDestinationOut,
        kCGBlendModePlusDarker
    };
    for (int i = 0; i < 4; i++)
    {
        CGContextSetBlendMode(context, modes2[i]);
        CGContextSetRGBFillColor(context, 1.0, 0.0, 0.0, 1.0);
        CGContextFillRect(context, CGRectMake(12 + i * 52, 90, 44, 44));
    }

    CGContextSetBlendMode(context, kCGBlendModeMultiply);
    CGContextSetRGBFillColor(context, 1.0, 0.0, 0.0, 1.0);
    CGContextBeginPath(context);
    CGContextAddRect(context, CGRectMake(220, 90, 44, 44));
    CGContextFillPath(context);
    CGContextSetBlendMode(context, kCGBlendModeNormal);
}
@end

@interface BlendController : UIViewController {
@public
    BlendView *_blend;
    BlendCapture *_capture;
}
@end

@implementation BlendController
- (void)loadView
{
    UIView *root =
        [[UIView alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    root.backgroundColor = [UIColor blackColor];
    self.view = root;

    _blend = [[BlendView alloc] initWithFrame:CGRectMake(20, 100, 360, 240)];
    _blend.backgroundColor = [UIColor clearColor];
    [root addSubview:_blend];

    _capture = [[BlendCapture alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    _capture.backgroundColor = [UIColor clearColor];
    [root addSubview:_capture];

    printf("[blend] ready\n");
    fflush(0);
    dispatch_after(dispatch_time(0, 200 * 1000000LL),
                   dispatch_get_main_queue(), ^{
        printf("[blend] done\n");
        fflush(0);
        g_blend_capture_ready = 1;
        [_blend setNeedsDisplay];
        [_capture setNeedsDisplay];
    });
}
@end

@interface BlendSceneDelegate : UIResponder <UIWindowSceneDelegate>
@property(nonatomic, retain) UIWindow *window;
@end

@interface BlendAppDelegate : UIResponder <UIApplicationDelegate>
@end

@implementation BlendAppDelegate
- (UISceneConfiguration *)application:(UIApplication *)application
    configurationForConnectingSceneSession:(UISceneSession *)session
    options:(UISceneConnectionOptions *)connectionOptions
{
    (void)application; (void)session; (void)connectionOptions;
    UISceneConfiguration *configuration = [[UISceneConfiguration alloc]
        initWithName:@"Default Configuration"
         sessionRole:UIWindowSceneSessionRoleApplication];
    configuration.delegateClass = [BlendSceneDelegate class];
    return configuration;
}
@end

@implementation BlendSceneDelegate
- (void)scene:(UIScene *)scene
    willConnectToSession:(UISceneSession *)session
                 options:(UISceneConnectionOptions *)connectionOptions
{
    (void)session; (void)connectionOptions;
    self.window = [[UIWindow alloc] initWithWindowScene:(UIWindowScene *)scene];
    self.window.frame = [[UIScreen mainScreen] bounds];
    self.window.rootViewController = [[BlendController alloc] init];
    [self.window makeKeyAndVisible];
}
@end

int main(int argc, char **argv)
{
    @autoreleasepool
    {
        return UIApplicationMain(argc, argv, nil, @"BlendAppDelegate");
    }
}
