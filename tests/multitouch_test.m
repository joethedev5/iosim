/* Two fingers land on different views. Each view receives its own changed
 * touch, while UIEvent.allTouches carries both live touches until they end. */
#include "UIKitStub.h"

extern int printf(const char *fmt, ...);
extern int fflush(void *stream);
extern void exit(int status);
extern char *getenv(const char *name);
extern int open(const char *path, int flags, ...);
extern long write(int fd, const void *buf, unsigned long count);
extern int snprintf(char *buf, unsigned long size, const char *fmt, ...);
extern unsigned long long dispatch_time(unsigned long long when,
                                        long long delta);
extern void dispatch_after(unsigned long long when, void *queue,
                           void (^block)(void));
extern void *dispatch_get_main_queue(void);

static int event_fd = -1;

@interface TouchView : UIView {
@public
    const char *tag;
}
@end

static TouchView *gLeft;
static TouchView *gRight;

static void send_touch(int ident, const char *action, double x, double y)
{
    const char *path = getenv("IOSIM_EVENT_FIFO");
    if (!path || !*path)
        return;
    if (event_fd < 0)
        event_fd = open(path, 1);
    if (event_fd < 0)
        return;
    double scale = [[UIScreen mainScreen] scale];
    if (scale <= 0)
        scale = 1.0;
    char line[80];
    int n = snprintf(line, sizeof(line), "touch %d %s %.0f %.0f\n",
                     ident, action, x * scale, y * scale);
    if (n > 0)
        write(event_fd, line, (unsigned long)n);
}

@implementation TouchView
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    NSSet *all = [event allTouches];
    printf("[mt] %s began changed=%lu all=%lu fv=%lu/%lu\n", tag,
           [touches count], [all count],
           [[event touchesForView:gLeft] count],
           [[event touchesForView:gRight] count]);
    fflush(0);
}
- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *touch = [touches anyObject];
    CGPoint at = [touch locationInView:self];
    CGPoint previous = [touch previousLocationInView:self];
    printf("[mt] %s moved changed=%lu all=%lu at %.1f %.1f prev %.1f %.1f\n",
           tag, [touches count], [[event allTouches] count],
           at.x, at.y, previous.x, previous.y);
    fflush(0);
}
- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    NSSet *all = [event allTouches];
    printf("[mt] %s ended changed=%lu all=%lu\n", tag,
           [touches count], [all count]);
    fflush(0);
    if (self == gRight)
    {
        printf("[mt] done\n");
        fflush(0);
        exit(0);
    }
}
@end

@interface MultiController : UIViewController
@end

@implementation MultiController
- (void)loadView
{
    UIView *root = [[UIView alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    root.backgroundColor = [UIColor colorWithRed:0.15 green:0.15 blue:0.2 alpha:1];
    self.view = root;

    gLeft = [[TouchView alloc] initWithFrame:CGRectMake(0, 0, 180, 180)];
    gLeft->tag = "a";
    gLeft.backgroundColor = [UIColor colorWithRed:0.2 green:0.4 blue:0.7 alpha:1];
    [root addSubview:gLeft];

    gRight = [[TouchView alloc] initWithFrame:CGRectMake(200, 200, 180, 180)];
    gRight->tag = "b";
    gRight.backgroundColor = [UIColor colorWithRed:0.7 green:0.4 blue:0.2 alpha:1];
    [root addSubview:gRight];

    dispatch_after(dispatch_time(0, 300 * 1000000LL),
                   dispatch_get_main_queue(), ^{
        send_touch(0, "down", 90, 90);
    });
    dispatch_after(dispatch_time(0, 600 * 1000000LL),
                   dispatch_get_main_queue(), ^{
        send_touch(1, "down", 300, 300);
    });
    dispatch_after(dispatch_time(0, 900 * 1000000LL),
                   dispatch_get_main_queue(), ^{
        send_touch(0, "move", 120, 100);
    });
    dispatch_after(dispatch_time(0, 1200 * 1000000LL),
                   dispatch_get_main_queue(), ^{
        send_touch(0, "up", 120, 100);
    });
    dispatch_after(dispatch_time(0, 1500 * 1000000LL),
                   dispatch_get_main_queue(), ^{
        send_touch(1, "up", 300, 300);
    });
}
@end

@interface MultiSceneDelegate : UIResponder <UIWindowSceneDelegate>
@property(nonatomic, retain) UIWindow *window;
@end

@interface MultiAppDelegate : UIResponder <UIApplicationDelegate>
@end

@implementation MultiAppDelegate
- (UISceneConfiguration *)application:(UIApplication *)application
    configurationForConnectingSceneSession:(UISceneSession *)session
    options:(UISceneConnectionOptions *)connectionOptions
{
    (void)application; (void)session; (void)connectionOptions;
    UISceneConfiguration *configuration = [[UISceneConfiguration alloc]
        initWithName:@"Default Configuration"
         sessionRole:UIWindowSceneSessionRoleApplication];
    configuration.delegateClass = [MultiSceneDelegate class];
    return configuration;
}
@end

@implementation MultiSceneDelegate
- (void)scene:(UIScene *)scene
    willConnectToSession:(UISceneSession *)session
                 options:(UISceneConnectionOptions *)connectionOptions
{
    (void)session; (void)connectionOptions;
    self.window = [[UIWindow alloc] initWithWindowScene:(UIWindowScene *)scene];
    self.window.frame = [[UIScreen mainScreen] bounds];
    self.window.rootViewController = [[MultiController alloc] init];
    [self.window makeKeyAndVisible];
}
@end

int main(int argc, char **argv)
{
    @autoreleasepool
    {
        return UIApplicationMain(argc, argv, nil, @"MultiAppDelegate");
    }
}
