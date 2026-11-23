/* UIAlertController action sheets: bottom-anchored card, separated cancel
 * action, destructive styling, and stacked alert rows that all hit-test. */
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

static void send_tap_px(int x, int y)
{
    char line[64];
    snprintf(line, sizeof(line), "tap %d %d\n", x, y);
    send_event(line);
}

static void capture(const char *variable)
{
    const char *path = getenv(variable);
    if (path)
        iosim_fb_present(path);
    fflush(0);
}

@interface SheetController : UIViewController
@end

@implementation SheetController
- (void)loadView
{
    UIView *root =
        [[UIView alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    root.backgroundColor =
        [UIColor colorWithRed:0.10 green:0.80 blue:0.30 alpha:1.0];
    self.view = root;

    dispatch_after(dispatch_time(0, 150 * 1000000LL),
                   dispatch_get_main_queue(), ^{
        UIAlertController *sheet = [UIAlertController
            alertControllerWithTitle:@"Choose"
                             message:@"Pick a row"
                      preferredStyle:UIAlertControllerStyleActionSheet];
        [sheet addAction:[UIAlertAction
            actionWithTitle:@"Share"
                      style:UIAlertActionStyleDefault
                    handler:^(UIAlertAction *action) {
            (void)action;
            printf("[sheet] share\n");
            fflush(0);
        }]];
        [sheet addAction:[UIAlertAction
            actionWithTitle:@"Delete"
                      style:UIAlertActionStyleDestructive
                    handler:^(UIAlertAction *action) {
            (void)action;
            printf("[sheet] delete 1\n");
            fflush(0);
        }]];
        [sheet addAction:[UIAlertAction
            actionWithTitle:@"Cancel"
                      style:UIAlertActionStyleCancel
                    handler:^(UIAlertAction *action) {
            (void)action;
            printf("[sheet] cancel\n");
            fflush(0);
        }]];
        [self presentViewController:sheet animated:NO completion:nil];
    });
    dispatch_after(dispatch_time(0, 600 * 1000000LL),
                   dispatch_get_main_queue(), ^{
        capture("IOSIM_TEST_PNG_SHEET");
    });
    dispatch_after(dispatch_time(0, 700 * 1000000LL),
                   dispatch_get_main_queue(), ^{
        /* Center of the destructive row in device pixels. */
        send_tap_px(603, 2332);
    });
    dispatch_after(dispatch_time(0, 1000 * 1000000LL),
                   dispatch_get_main_queue(), ^{
        capture("IOSIM_TEST_PNG_RESTORED");
    });

    dispatch_after(dispatch_time(0, 1100 * 1000000LL),
                   dispatch_get_main_queue(), ^{
        UIAlertController *alert = [UIAlertController
            alertControllerWithTitle:nil
                             message:nil
                      preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction
            actionWithTitle:@"One"
                      style:UIAlertActionStyleDefault
                    handler:^(UIAlertAction *action) {
            (void)action;
            printf("[alert] one\n");
            fflush(0);
        }]];
        [alert addAction:[UIAlertAction
            actionWithTitle:@"Two"
                      style:UIAlertActionStyleDefault
                    handler:^(UIAlertAction *action) {
            (void)action;
            printf("[alert] two\n");
            fflush(0);
        }]];
        [alert addAction:[UIAlertAction
            actionWithTitle:@"Three"
                      style:UIAlertActionStyleDefault
                    handler:^(UIAlertAction *action) {
            (void)action;
            printf("[alert] three\n");
            fflush(0);
        }]];
        [self presentViewController:alert animated:NO completion:nil];
    });
    dispatch_after(dispatch_time(0, 1400 * 1000000LL),
                   dispatch_get_main_queue(), ^{
        /* Center of the third stacked alert row in device pixels. */
        send_tap_px(603, 1556);
    });
    dispatch_after(dispatch_time(0, 1700 * 1000000LL),
                   dispatch_get_main_queue(), ^{
        printf("[alert] done\n");
        fflush(0);
        exit(0);
    });
}
@end

@interface SheetSceneDelegate : UIResponder <UIWindowSceneDelegate>
@property(nonatomic, retain) UIWindow *window;
@end

@interface SheetAppDelegate : UIResponder <UIApplicationDelegate>
@end

@implementation SheetAppDelegate
- (UISceneConfiguration *)application:(UIApplication *)application
    configurationForConnectingSceneSession:(UISceneSession *)session
    options:(UISceneConnectionOptions *)connectionOptions
{
    (void)application; (void)session; (void)connectionOptions;
    UISceneConfiguration *configuration = [[UISceneConfiguration alloc]
        initWithName:@"Default Configuration"
         sessionRole:UIWindowSceneSessionRoleApplication];
    configuration.delegateClass = [SheetSceneDelegate class];
    return configuration;
}
@end

@implementation SheetSceneDelegate
- (void)scene:(UIScene *)scene
    willConnectToSession:(UISceneSession *)session
                 options:(UISceneConnectionOptions *)connectionOptions
{
    (void)session; (void)connectionOptions;
    self.window = [[UIWindow alloc] initWithWindowScene:(UIWindowScene *)scene];
    self.window.frame = [[UIScreen mainScreen] bounds];
    self.window.rootViewController = [[SheetController alloc] init];
    [self.window makeKeyAndVisible];
}
@end

int main(int argc, char **argv)
{
    @autoreleasepool
    {
        return UIApplicationMain(argc, argv, nil, @"SheetAppDelegate");
    }
}
