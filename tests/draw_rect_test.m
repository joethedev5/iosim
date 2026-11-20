/* UIView drawRect: bridge backed by CoreGraphics: a custom view fills and
 * strokes shapes, the run loop renders one frame, writes a PNG and exits. */
#include "UIKitStub.h"

extern int printf(const char *fmt, ...);
extern int fflush(void *stream);
extern unsigned long long dispatch_time(unsigned long long when,
                                        long long delta);
extern void dispatch_after(unsigned long long when, void *queue,
                           void (^block)(void));
extern void *dispatch_get_main_queue(void);
extern int iosim_fb_present(const char *path);
extern char *getenv(const char *name);
extern void exit(int status);

@interface DrawView : UIView
@end

@implementation DrawView
- (void)drawRect:(CGRect)rect
{
    (void)rect;
    CGContextRef context = 0;
    CGContextSetRGBFillColor(context, 0.90, 0.20, 0.20, 1);
    CGContextFillRect(context, CGRectMake(20, 150, 100, 80));
    CGContextSetRGBFillColor(context, 0.20, 0.85, 0.35, 1);
    CGContextFillEllipseInRect(context, CGRectMake(200, 150, 100, 80));
    CGContextSetRGBStrokeColor(context, 0.20, 0.55, 1.0, 1);
    CGContextSetLineWidth(context, 3);
    CGContextStrokeRect(context, CGRectMake(20, 280, 280, 80));
    CGContextSetRGBFillColor(context, 1.0, 0.80, 0.10, 1);
    CGContextBeginPath(context);
    CGContextMoveToPoint(context, 40, 420);
    CGContextAddLineToPoint(context, 140, 420);
    CGContextAddLineToPoint(context, 90, 500);
    CGContextClosePath(context);
    CGContextFillPath(context);
    printf("[draw] rect painted\n");
    fflush(0);
    const char *path = getenv("IOSIM_TEST_PNG");
    if (path)
    {
        iosim_fb_present(path);
        printf("[draw] wrote png\n");
        fflush(0);
        exit(0);
    }
}
@end

@interface DrawController : UIViewController
@end

@implementation DrawController
- (void)loadView
{
    DrawView *view =
        [[DrawView alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    view.backgroundColor =
        [UIColor colorWithRed:0.04 green:0.06 blue:0.12 alpha:1.0];
    self.view = view;
}
@end

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

@implementation SceneDelegate
- (void)scene:(UIScene *)scene
    willConnectToSession:(UISceneSession *)session
                 options:(UISceneConnectionOptions *)connectionOptions
{
    (void)session; (void)connectionOptions;
    self.window = [[UIWindow alloc] initWithWindowScene:(UIWindowScene *)scene];
    self.window.frame = [[UIScreen mainScreen] bounds];
    self.window.rootViewController = [[DrawController alloc] init];
    [self.window makeKeyAndVisible];
}
@end

int main(int argc, char **argv)
{
    @autoreleasepool
    {
        return UIApplicationMain(argc, argv, nil, @"AppDelegate");
    }
}
