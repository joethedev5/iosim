/* Interactive navigation pop: a left-edge pan drags the pushed detail to the
 * right, revealing the root view under a fading dim with an edge shadow.
 * Releasing past halfway pops; a short drag released in place snaps back.
 * Timed captures measure both outcomes. */
#include "UIKitStub.h"

extern int printf(const char *fmt, ...);
extern int fflush(void *stream);
extern int iosim_fb_present(const char *path);
extern char *getenv(const char *name);
extern void exit(int status);
extern int open(const char *path, int flags, ...);
extern long write(int fd, const void *buf, unsigned long count);
extern int snprintf(char *buf, unsigned long size, const char *fmt, ...);
extern unsigned long long dispatch_time(unsigned long long when,
                                        long long delta);
extern void dispatch_after(unsigned long long when, void *queue,
                           void (^block)(void));
extern void *dispatch_get_main_queue(void);

static int event_fd = -1;

static void send_event(const char *line)
{
    const char *path = getenv("IOSIM_EVENT_FIFO");
    if (!path || !*path)
        return;
    if (event_fd < 0)
        event_fd = open(path, 1);
    if (event_fd < 0)
        return;
    unsigned long length = 0;
    while (line[length])
        length++;
    write(event_fd, line, length);
}

static void send_touch(const char *kind, double x, double y, double scale)
{
    char line[96];
    snprintf(line, sizeof(line), "%s %d %d\n", kind,
             (int)(x * scale + 0.5), (int)(y * scale + 0.5));
    send_event(line);
}

static void capture(const char *variable)
{
    const char *path = getenv(variable);
    if (path)
        iosim_fb_present(path);
    fflush(0);
}

@interface RootController : UIViewController
@end

@implementation RootController
- (void)loadView
{
    UIView *root =
        [[UIView alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    root.backgroundColor =
        [UIColor colorWithRed:0.10 green:0.80 blue:0.30 alpha:1.0];
    self.view = root;
}
@end

@interface DetailController : UIViewController
@end

@implementation DetailController
- (void)loadView
{
    UIView *root =
        [[UIView alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    root.backgroundColor =
        [UIColor colorWithRed:0.90 green:0.10 blue:0.60 alpha:1.0];
    self.view = root;
}
@end

@interface NavSceneDelegate : UIResponder <UIWindowSceneDelegate>
@property(nonatomic, retain) UIWindow *window;
@end

@interface NavAppDelegate : UIResponder <UIApplicationDelegate>
@end

@implementation NavAppDelegate
- (UISceneConfiguration *)application:(UIApplication *)application
    configurationForConnectingSceneSession:(UISceneSession *)session
    options:(UISceneConnectionOptions *)connectionOptions
{
    (void)application; (void)session; (void)connectionOptions;
    UISceneConfiguration *configuration = [[UISceneConfiguration alloc]
        initWithName:@"Default Configuration"
         sessionRole:UIWindowSceneSessionRoleApplication];
    configuration.delegateClass = [NavSceneDelegate class];
    return configuration;
}
@end

@implementation NavSceneDelegate
- (void)scene:(UIScene *)scene
    willConnectToSession:(UISceneSession *)session
                 options:(UISceneConnectionOptions *)connectionOptions
{
    (void)session; (void)connectionOptions;
    self.window = [[UIWindow alloc] initWithWindowScene:(UIWindowScene *)scene];
    self.window.frame = [[UIScreen mainScreen] bounds];
    UINavigationController *nav = [[UINavigationController alloc]
        initWithRootViewController:[[RootController alloc] init]];
    self.window.rootViewController = nav;
    [self.window makeKeyAndVisible];
    printf("[nav] gesture %d\n",
           [nav interactivePopGestureRecognizer] != nil);
    fflush(0);

    double scale = [[UIScreen mainScreen] scale];
    if (scale <= 0)
        scale = 1.0;

    dispatch_after(dispatch_time(0, 100 * 1000000LL),
                   dispatch_get_main_queue(), ^{
        DetailController *detail = [[DetailController alloc] init];
        detail.title = @"Detail";
        [nav pushViewController:detail animated:NO];
        printf("[nav] pushed\n");
        fflush(0);
    });

    dispatch_after(dispatch_time(0, 500 * 1000000LL),
                   dispatch_get_main_queue(), ^{
        capture("IOSIM_TEST_PNG_BASE");
    });

    /* Drag well past halfway, then lift: the pop commits. */
    dispatch_after(dispatch_time(0, 600 * 1000000LL),
                   dispatch_get_main_queue(), ^{
        send_touch("down", 2, 437, scale);
    });
    dispatch_after(dispatch_time(0, 650 * 1000000LL),
                   dispatch_get_main_queue(), ^{
        send_touch("move", 100, 437, scale);
    });
    dispatch_after(dispatch_time(0, 700 * 1000000LL),
                   dispatch_get_main_queue(), ^{
        send_touch("move", 150, 437, scale);
    });
    dispatch_after(dispatch_time(0, 800 * 1000000LL),
                   dispatch_get_main_queue(), ^{
        send_touch("move", 240, 437, scale);
    });
    dispatch_after(dispatch_time(0, 1100 * 1000000LL),
                   dispatch_get_main_queue(), ^{
        capture("IOSIM_TEST_PNG_MID");
    });
    dispatch_after(dispatch_time(0, 1200 * 1000000LL),
                   dispatch_get_main_queue(), ^{
        send_touch("up", 260, 437, scale);
    });
    dispatch_after(dispatch_time(0, 2000 * 1000000LL),
                   dispatch_get_main_queue(), ^{
        printf("[nav] popped %d\n", [nav viewControllers].count == 1);
        capture("IOSIM_TEST_PNG_END");
    });

    /* Push again, drag only a quarter and pause before lifting: snap back. */
    dispatch_after(dispatch_time(0, 2200 * 1000000LL),
                   dispatch_get_main_queue(), ^{
        DetailController *detail = [[DetailController alloc] init];
        detail.title = @"Detail";
        [nav pushViewController:detail animated:NO];
        printf("[nav] repushed\n");
        fflush(0);
    });
    dispatch_after(dispatch_time(0, 2400 * 1000000LL),
                   dispatch_get_main_queue(), ^{
        send_touch("down", 2, 437, scale);
    });
    dispatch_after(dispatch_time(0, 2450 * 1000000LL),
                   dispatch_get_main_queue(), ^{
        send_touch("move", 60, 437, scale);
    });
    dispatch_after(dispatch_time(0, 2500 * 1000000LL),
                   dispatch_get_main_queue(), ^{
        send_touch("move", 100, 437, scale);
    });
    dispatch_after(dispatch_time(0, 2850 * 1000000LL),
                   dispatch_get_main_queue(), ^{
        send_touch("up", 100, 437, scale);
    });
    dispatch_after(dispatch_time(0, 3600 * 1000000LL),
                   dispatch_get_main_queue(), ^{
        printf("[nav] cancel %d\n", [nav viewControllers].count == 2);
        capture("IOSIM_TEST_PNG_CANCEL");
    });
    dispatch_after(dispatch_time(0, 3900 * 1000000LL),
                   dispatch_get_main_queue(), ^{
        printf("[nav] png written\n");
        fflush(0);
        exit(0);
    });
}
@end

int main(int argc, char **argv)
{
    @autoreleasepool
    {
        return UIApplicationMain(argc, argv, nil, @"NavAppDelegate");
    }
}
