/* CADisplayLink.preferredFramesPerSecond lowers the callback rate while a
 * default link keeps firing every display tick. */
#include "UIKitStub.h"

extern int printf(const char *fmt, ...);
extern int fflush(void *stream);
extern void exit(int status);
extern unsigned long long dispatch_time(unsigned long long when,
                                        long long delta);
extern void dispatch_after(unsigned long long when, void *queue,
                           void (^block)(void));
extern void *dispatch_get_main_queue(void);

@interface RateProbe : NSObject {
@public
    int slowCount;
    int fastCount;
}
@end

@implementation RateProbe
- (void)slowTick:(CADisplayLink *)link
{
    (void)link;
    slowCount++;
}
- (void)fastTick:(CADisplayLink *)link
{
    (void)link;
    fastCount++;
}
@end

@interface RateController : UIViewController
@end

@implementation RateController
- (void)loadView
{
    UIView *root = [[UIView alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    root.backgroundColor = [UIColor colorWithRed:0.1 green:0.1 blue:0.15 alpha:1];
    self.view = root;

    RateProbe *probe = [[RateProbe alloc] init];
    CADisplayLink *slow = [CADisplayLink displayLinkWithTarget:probe
                                                      selector:@selector(slowTick:)];
    [slow setPreferredFramesPerSecond:10];
    [slow addToRunLoop:nil forMode:nil];
    CADisplayLink *fast = [CADisplayLink displayLinkWithTarget:probe
                                                      selector:@selector(fastTick:)];
    [fast addToRunLoop:nil forMode:nil];
    printf("[dlink] duration %.4f %.4f\n", [slow duration], [fast duration]);
    fflush(0);

    dispatch_after(dispatch_time(0, 800 * 1000000LL),
                   dispatch_get_main_queue(), ^{
        printf("[dlink] rates %d %d\n",
               probe->slowCount >= 4,
               probe->fastCount > probe->slowCount * 3);
        printf("[dlink] done %d %d\n", probe->slowCount, probe->fastCount);
        fflush(0);
        exit(0);
    });
}
@end

@interface RateSceneDelegate : UIResponder <UIWindowSceneDelegate>
@property(nonatomic, retain) UIWindow *window;
@end

@interface RateAppDelegate : UIResponder <UIApplicationDelegate>
@end

@implementation RateAppDelegate
- (UISceneConfiguration *)application:(UIApplication *)application
    configurationForConnectingSceneSession:(UISceneSession *)session
    options:(UISceneConnectionOptions *)connectionOptions
{
    (void)application; (void)session; (void)connectionOptions;
    UISceneConfiguration *configuration = [[UISceneConfiguration alloc]
        initWithName:@"Default Configuration"
         sessionRole:UIWindowSceneSessionRoleApplication];
    configuration.delegateClass = [RateSceneDelegate class];
    return configuration;
}
@end

@implementation RateSceneDelegate
- (void)scene:(UIScene *)scene
    willConnectToSession:(UISceneSession *)session
                 options:(UISceneConnectionOptions *)connectionOptions
{
    (void)session; (void)connectionOptions;
    self.window = [[UIWindow alloc] initWithWindowScene:(UIWindowScene *)scene];
    self.window.frame = [[UIScreen mainScreen] bounds];
    self.window.rootViewController = [[RateController alloc] init];
    [self.window makeKeyAndVisible];
}
@end

int main(int argc, char **argv)
{
    @autoreleasepool
    {
        return UIApplicationMain(argc, argv, nil, @"RateAppDelegate");
    }
}
