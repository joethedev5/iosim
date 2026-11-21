/* Share sheet: a UIActivityViewController slides up over a dimmed parent,
 * copies its string item to the pasteboard from the Copy row, reports the
 * completion type, and dismisses. A second sheet excludes Copy, lays out
 * without rows, and cancels from a tap on the dimmed area. Timed captures
 * sample the slide, the settled sheets and both dismissals. */
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

static void send_tap(double x, double y, double scale)
{
    char line[96];
    snprintf(line, sizeof(line), "tap %d %d\n", (int)(x * scale + 0.5),
             (int)(y * scale + 0.5));
    send_event(line);
}

static void capture(const char *variable)
{
    const char *path = getenv(variable);
    if (path)
        iosim_fb_present(path);
    fflush(0);
}

static void (^g_done)(UIActivityType, BOOL, NSArray *, NSError *) =
    ^(UIActivityType type, BOOL completed, NSArray *items, NSError *error) {
        (void)items;
        (void)error;
        const char *name = type ? [type UTF8String] : "(null)";
        printf("[share] done %s %d\n", name, completed ? 1 : 0);
        fflush(0);
    };

@interface ShareController : UIViewController
@end

@implementation ShareController
- (void)loadView
{
    UIView *root =
        [[UIView alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    root.backgroundColor =
        [UIColor colorWithRed:0.10 green:0.80 blue:0.30 alpha:1.0];
    self.view = root;

    dispatch_after(dispatch_time(0, 100 * 1000000LL),
                   dispatch_get_main_queue(), ^{
        UIActivityViewController *sheet = [[UIActivityViewController alloc]
            initWithActivityItems:[NSArray arrayWithObject:
                @"Hello share sheet"]
            applicationActivities:nil];
        [sheet setCompletionWithItemsHandler:g_done];
        [self presentViewController:sheet animated:YES completion:nil];
        printf("[share] presented\n");
        fflush(0);
    });

    dispatch_after(dispatch_time(0, 250 * 1000000LL),
                   dispatch_get_main_queue(), ^{
        capture("IOSIM_TEST_PNG_MID");
    });

    dispatch_after(dispatch_time(0, 600 * 1000000LL),
                   dispatch_get_main_queue(), ^{
        capture("IOSIM_TEST_PNG_FULL");
    });

    dispatch_after(dispatch_time(0, 700 * 1000000LL),
                   dispatch_get_main_queue(), ^{
        /* The Copy row: the one-row sheet is 240 pt tall, so its row sits
         * from 732 to 790 pt on the 402x874 screen. */
        send_tap(201, 761, 3.0);
        fflush(0);
    });

    dispatch_after(dispatch_time(0, 800 * 1000000LL),
                   dispatch_get_main_queue(), ^{
        id pasted = [[UIPasteboard generalPasteboard] string];
        printf("[share] paste %s\n", pasted ? [pasted UTF8String] : "(nil)");
        fflush(0);
    });

    dispatch_after(dispatch_time(0, 1250 * 1000000LL),
                   dispatch_get_main_queue(), ^{
        capture("IOSIM_TEST_PNG_COPYGONE");
    });

    dispatch_after(dispatch_time(0, 1400 * 1000000LL),
                   dispatch_get_main_queue(), ^{
        UIActivityViewController *sheet = [[UIActivityViewController alloc]
            initWithActivityItems:[NSArray arrayWithObject:@"Hidden copy"]
            applicationActivities:nil];
        [sheet setCompletionWithItemsHandler:g_done];
        [sheet setExcludedActivityTypes:[NSArray arrayWithObject:
            UIActivityTypeCopyToPasteboard]];
        [self presentViewController:sheet animated:YES completion:nil];
        printf("[share] excluded\n");
        fflush(0);
    });

    dispatch_after(dispatch_time(0, 1800 * 1000000LL),
                   dispatch_get_main_queue(), ^{
        capture("IOSIM_TEST_PNG_EMPTY");
    });

    dispatch_after(dispatch_time(0, 1900 * 1000000LL),
                   dispatch_get_main_queue(), ^{
        /* A tap above the sheet (top 684 pt when it has no rows) cancels. */
        send_tap(201, 300, 3.0);
        fflush(0);
    });

    dispatch_after(dispatch_time(0, 2400 * 1000000LL),
                   dispatch_get_main_queue(), ^{
        capture("IOSIM_TEST_PNG_CANCEL");
    });

    dispatch_after(dispatch_time(0, 2600 * 1000000LL),
                   dispatch_get_main_queue(), ^{
        capture("IOSIM_TEST_PNG_CANCEL");
        printf("[share] png written\n");
        fflush(0);
        exit(0);
    });
}
@end

@interface ShareSceneDelegate : UIResponder <UIWindowSceneDelegate>
@property(nonatomic, retain) UIWindow *window;
@end

@interface ShareAppDelegate : UIResponder <UIApplicationDelegate>
@end

@implementation ShareAppDelegate
- (UISceneConfiguration *)application:(UIApplication *)application
    configurationForConnectingSceneSession:(UISceneSession *)session
    options:(UISceneConnectionOptions *)connectionOptions
{
    (void)application; (void)session; (void)connectionOptions;
    UISceneConfiguration *configuration = [[UISceneConfiguration alloc]
        initWithName:@"Default Configuration"
         sessionRole:UIWindowSceneSessionRoleApplication];
    configuration.delegateClass = [ShareSceneDelegate class];
    return configuration;
}
@end

@implementation ShareSceneDelegate
- (void)scene:(UIScene *)scene
    willConnectToSession:(UISceneSession *)session
                 options:(UISceneConnectionOptions *)connectionOptions
{
    (void)session; (void)connectionOptions;
    self.window = [[UIWindow alloc] initWithWindowScene:(UIWindowScene *)scene];
    self.window.frame = [[UIScreen mainScreen] bounds];
    self.window.rootViewController = [[ShareController alloc] init];
    [self.window makeKeyAndVisible];
}
@end

int main(int argc, char **argv)
{
    @autoreleasepool
    {
        return UIApplicationMain(argc, argv, nil, @"ShareAppDelegate");
    }
}
