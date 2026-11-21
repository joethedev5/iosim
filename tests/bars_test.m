/* Standalone UINavigationBar and UIToolbar: items lay out, taps through the
 * event FIFO reach their targets, and push/pop changes the top item. */
#include "UIKitStub.h"

extern int printf(const char *fmt, ...);
extern int fflush(void *stream);
extern int iosim_fb_present(const char *path);
extern char *getenv(const char *name);
extern void exit(int status);
extern int iosim_fb_font_text_width(const char *text, int style,
                                    double size_pt, double scale);
extern int open(const char *path, int flags, ...);
extern long write(int fd, const void *buf, unsigned long count);
extern int snprintf(char *buf, unsigned long size, const char *fmt, ...);
extern unsigned long long dispatch_time(unsigned long long when,
                                        long long delta);
extern void dispatch_after(unsigned long long when, void *queue,
                           void (^block)(void));
extern void *dispatch_get_main_queue(void);

static int event_fd = -1;

static void send_tap(int px, int py)
{
    const char *path = getenv("IOSIM_EVENT_FIFO");
    if (!path || !*path)
        return;
    if (event_fd < 0)
        event_fd = open(path, 1);
    if (event_fd < 0)
        return;
    char line[64];
    int n = snprintf(line, sizeof(line), "tap %d %d\n", px, py);
    if (n > 0)
        write(event_fd, line, (unsigned long)n);
}

@interface BarsController : UIViewController {
@public
    int _navCount;
    int _toolCount;
}
@end

@implementation BarsController
- (void)navDone:(id)sender
{
    (void)sender;
    _navCount++;
}
- (void)toolTapped:(id)sender
{
    (void)sender;
    _toolCount++;
}
- (void)loadView
{
    UIView *root =
        [[UIView alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    root.backgroundColor =
        [UIColor colorWithRed:0.043 green:0.055 blue:0.102 alpha:1.0];
    CGRect bounds = [[UIScreen mainScreen] bounds];
    double width = bounds.size.width;
    double height = bounds.size.height;

    UINavigationBar *nav =
        [[UINavigationBar alloc] initWithFrame:CGRectMake(0, 60, width, 44)];
    UINavigationItem *item = [[UINavigationItem alloc] initWithTitle:@"Photos"];
    item.rightBarButtonItem = [[UIBarButtonItem alloc]
        initWithTitle:@"Done" style:0 target:self
               action:@selector(navDone:)];
    [nav setItems:[NSArray arrayWithObject:item] animated:NO];
    [root addSubview:nav];

    UINavigationItem *second = [[UINavigationItem alloc] initWithTitle:@"Detail"];
    [nav pushNavigationItem:second animated:NO];
    BOOL pushed = [[nav topItem] title] &&
                  [[[nav topItem] title] isEqualToString:@"Detail"];
    UINavigationItem *popped = [nav popNavigationItemAnimated:NO];
    BOOL popped_ok = popped == second && [[nav topItem] title] &&
                     [[[nav topItem] title] isEqualToString:@"Photos"];
    printf("[bars] items %d %d\n", pushed ? 1 : 0, popped_ok ? 1 : 0);

    UIToolbar *toolbar = [[UIToolbar alloc]
        initWithFrame:CGRectMake(0, height - 90, width, 49)];
    UIBarButtonItem *bold = [[UIBarButtonItem alloc]
        initWithTitle:@"Bold" style:0 target:self
               action:@selector(toolTapped:)];
    UIBarButtonItem *italic = [[UIBarButtonItem alloc]
        initWithTitle:@"Italic" style:0 target:self
               action:@selector(toolTapped:)];
    UIBarButtonItem *share = [[UIBarButtonItem alloc]
        initWithTitle:@"Share" style:0 target:self
               action:@selector(toolTapped:)];
    id items[3] = { bold, italic, share };
    [toolbar setItems:[NSArray arrayWithObjects:items count:3] animated:NO];
    [root addSubview:toolbar];

    double scale = [[UIScreen mainScreen] scale];
    if (scale <= 0)
        scale = 1.0;
    int widths[3];
    int total = 0;
    int gap = (int)(16.0 * scale + 0.5);
    for (int i = 0; i < 3; i++)
    {
        UIBarButtonItem *button = (UIBarButtonItem *)items[i];
        widths[i] = iosim_fb_font_text_width(
                        [button.title UTF8String], 0, 17.0, scale) +
                    (int)(48.0 * scale + 0.5);
        total += widths[i];
        if (i > 0)
            total += gap;
    }
    int x = (int)(width * scale + 0.5) - total;
    x = x / 2;
    if (x < (int)(8 * scale))
        x = (int)(8 * scale);
    int tool_y = (int)((height - 90 + 8) * scale + 0.5) + 16;
    int nav_x = (int)((width - 68) * scale + 0.5);
    int nav_y = (int)((60 + 22) * scale + 0.5);
    int tap_x0 = x + widths[0] / 2;
    int tap_x1 = x + widths[0] + gap + widths[1] / 2;
    int tap_x2 = x + widths[0] + gap + widths[1] + gap + widths[2] / 2;

    dispatch_after(dispatch_time(0, 800 * 1000000LL),
                   dispatch_get_main_queue(), ^{
        send_tap(tap_x0, tool_y);
        send_tap(tap_x1, tool_y);
        send_tap(tap_x2, tool_y);
        send_tap(nav_x, nav_y);
        printf("[bars] tapped\n");
        fflush(0);
    });

    dispatch_after(dispatch_time(0, 1600 * 1000000LL),
                   dispatch_get_main_queue(), ^{
        printf("[bars] nav %d tool %d\n", _navCount, _toolCount);
        const char *path = getenv("IOSIM_TEST_PNG");
        if (path)
            iosim_fb_present(path);
        printf("[bars] png written\n");
        fflush(0);
        exit(0);
    });

    self.view = root;
}
@end

@interface BarsSceneDelegate : UIResponder <UIWindowSceneDelegate>
@property(nonatomic, retain) UIWindow *window;
@end

@interface BarsAppDelegate : UIResponder <UIApplicationDelegate>
@end

@implementation BarsAppDelegate
- (UISceneConfiguration *)application:(UIApplication *)application
    configurationForConnectingSceneSession:(UISceneSession *)session
    options:(UISceneConnectionOptions *)connectionOptions
{
    (void)application; (void)session; (void)connectionOptions;
    UISceneConfiguration *configuration = [[UISceneConfiguration alloc]
        initWithName:@"Default Configuration"
         sessionRole:UIWindowSceneSessionRoleApplication];
    configuration.delegateClass = [BarsSceneDelegate class];
    return configuration;
}
@end

@implementation BarsSceneDelegate
- (void)scene:(UIScene *)scene
    willConnectToSession:(UISceneSession *)session
                 options:(UISceneConnectionOptions *)connectionOptions
{
    (void)session; (void)connectionOptions;
    self.window = [[UIWindow alloc] initWithWindowScene:(UIWindowScene *)scene];
    self.window.frame = [[UIScreen mainScreen] bounds];
    self.window.rootViewController = [[BarsController alloc] init];
    [self.window makeKeyAndVisible];
}
@end

int main(int argc, char **argv)
{
    @autoreleasepool
    {
        return UIApplicationMain(argc, argv, nil, @"BarsAppDelegate");
    }
}
