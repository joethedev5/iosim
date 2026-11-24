/* CGContext blend modes apply to image blits and to text, not only fills:
 * a red image and red bold text over a 50% gray field blend channel-wise. */
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

static int g_blend2_capture_ready;

@interface Blend2Capture : UIView
@end

@implementation Blend2Capture
- (void)drawRect:(CGRect)rect
{
    (void)rect;
    if (!g_blend2_capture_ready)
        return;
    const char *path = getenv("IOSIM_TEST_PNG");
    if (!path)
        return;
    iosim_fb_present(path);
    printf("[blend2] png written\n");
    fflush(0);
    exit(0);
}
@end

@interface Blend2View : UIView
@end

@implementation Blend2View
- (void)drawRect:(CGRect)rect
{
    (void)rect;
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetRGBFillColor(context, 0.5, 0.5, 0.5, 1.0);
    CGContextFillRect(context, CGRectMake(0, 0, 360, 240));

    unsigned char red[2 * 2 * 4];
    for (int i = 0; i < 4; i++)
    {
        red[i * 4 + 0] = 255;
        red[i * 4 + 1] = 0;
        red[i * 4 + 2] = 0;
        red[i * 4 + 3] = 255;
    }
    CGImageRef image = CGImageCreateWithRGBA(red, 2, 2);

    CGContextSetBlendMode(context, kCGBlendModeMultiply);
    CGContextDrawImage(context, CGRectMake(12, 20, 44, 44), image);
    CGContextSetBlendMode(context, kCGBlendModeScreen);
    CGContextDrawImage(context, CGRectMake(64, 20, 44, 44), image);
    CGImageRelease(image);

    NSDictionary *attributes = [NSDictionary dictionaryWithObjectsAndKeys:
        [UIFont boldSystemFontOfSize:40], NSFontAttributeName,
        [UIColor redColor], NSForegroundColorAttributeName, nil];
    CGContextSetBlendMode(context, kCGBlendModeMultiply);
    [@"MMMM" drawAtPoint:CGPointMake(12, 120) withAttributes:attributes];
    CGContextSetBlendMode(context, kCGBlendModeScreen);
    [@"MMMM" drawAtPoint:CGPointMake(12, 180) withAttributes:attributes];

    CGContextSetBlendMode(context, kCGBlendModeNormal);
}
@end

@interface Blend2Controller : UIViewController {
@public
    Blend2View *_blend;
    Blend2Capture *_capture;
}
@end

@implementation Blend2Controller
- (void)loadView
{
    UIView *root =
        [[UIView alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    root.backgroundColor = [UIColor blackColor];
    self.view = root;

    _blend = [[Blend2View alloc] initWithFrame:CGRectMake(20, 100, 360, 240)];
    _blend.backgroundColor = [UIColor clearColor];
    [root addSubview:_blend];

    _capture = [[Blend2Capture alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    _capture.backgroundColor = [UIColor clearColor];
    [root addSubview:_capture];

    printf("[blend2] ready\n");
    fflush(0);
    dispatch_after(dispatch_time(0, 200 * 1000000LL),
                   dispatch_get_main_queue(), ^{
        printf("[blend2] done\n");
        fflush(0);
        g_blend2_capture_ready = 1;
        [_blend setNeedsDisplay];
        [_capture setNeedsDisplay];
    });
}
@end

@interface Blend2SceneDelegate : UIResponder <UIWindowSceneDelegate>
@property(nonatomic, retain) UIWindow *window;
@end

@interface Blend2AppDelegate : UIResponder <UIApplicationDelegate>
@end

@implementation Blend2AppDelegate
- (UISceneConfiguration *)application:(UIApplication *)application
    configurationForConnectingSceneSession:(UISceneSession *)session
    options:(UISceneConnectionOptions *)connectionOptions
{
    (void)application; (void)session; (void)connectionOptions;
    UISceneConfiguration *configuration = [[UISceneConfiguration alloc]
        initWithName:@"Default Configuration"
         sessionRole:UIWindowSceneSessionRoleApplication];
    configuration.delegateClass = [Blend2SceneDelegate class];
    return configuration;
}
@end

@implementation Blend2SceneDelegate
- (void)scene:(UIScene *)scene
    willConnectToSession:(UISceneSession *)session
                 options:(UISceneConnectionOptions *)connectionOptions
{
    (void)session; (void)connectionOptions;
    self.window = [[UIWindow alloc] initWithWindowScene:(UIWindowScene *)scene];
    self.window.frame = [[UIScreen mainScreen] bounds];
    self.window.rootViewController = [[Blend2Controller alloc] init];
    [self.window makeKeyAndVisible];
}
@end

int main(int argc, char **argv)
{
    @autoreleasepool
    {
        return UIApplicationMain(argc, argv, nil, @"Blend2AppDelegate");
    }
}
