/* UITextView edit menu: a long press selects "world" and shows the
 * UIMenuController. A timed block taps the Copy item through the event
 * FIFO, then checks that the pasteboard holds the word and the menu hid. */
#include "UIKitStub.h"

extern int printf(const char *fmt, ...);
extern int fflush(void *stream);
extern int iosim_fb_present(const char *path);
extern char *getenv(const char *name);
extern void exit(int status);
extern int iosim_fb_font_text_width(const char *text, int style,
                                    double size_pt, double scale);
extern void iosim_fb_font_metrics(int style, double size_pt, double scale,
                                  int *ascent, int *descent,
                                  int *line_height);
extern int open(const char *path, int flags, ...);
extern long write(int fd, const void *buf, unsigned long count);
extern int close(int fd);
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

@interface MenuController : UIViewController
@end

@implementation MenuController
- (void)loadView
{
    UIView *root =
        [[UIView alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    root.backgroundColor =
        [UIColor colorWithRed:0.043 green:0.055 blue:0.102 alpha:1.0];

    UITextView *editor = [[UITextView alloc]
        initWithFrame:CGRectMake(24, 100, 320, 160)];
    editor.backgroundColor =
        [UIColor colorWithRed:0.09 green:0.12 blue:0.21 alpha:1.0];
    editor.textColor = [UIColor whiteColor];
    editor.font = [UIFont systemFontOfSize:24];
    editor.text = @"hello world";
    [root addSubview:editor];

    double scale = [[UIScreen mainScreen] scale];
    if (scale <= 0)
        scale = 1.0;
    double tap_x = 24.0 + 12.0 +
        iosim_fb_font_text_width("hello w", 0, 24.0, scale) / scale + 2.0;
    UITouch *touch = [[UITouch alloc] init];
    touch->_location = CGPointMake(tap_x, 120.0);
    touch->_previousLocation = touch->_location;
    touch->_phase = UITouchPhaseBegan;
    [editor touchesBegan:[NSSet setWithObject:touch] withEvent:nil];

    /* Layout the Copy item exactly as text_view_show_edit_menu and
     * draw_edit_menu do, so the injected tap lands on it. */
    int w_hello = iosim_fb_font_text_width("hello ", 0, 24.0, scale);
    int w_world = iosim_fb_font_text_width("hello world", 0, 24.0, scale);
    int w_copy = iosim_fb_font_text_width("Copy", 0, 17.0, scale);
    int w_paste = iosim_fb_font_text_width("Paste", 0, 17.0, scale);
    int ascent = 0, descent = 0, line_height = 0;
    iosim_fb_font_metrics(0, 24.0, scale, &ascent, &descent, &line_height);
    (void)ascent;
    (void)descent;
    int pad = (int)(15.0 * scale + 0.5);
    int panel_w = w_copy + 2 * pad + w_paste + 2 * pad;
    int panel_h = (int)(38.0 * scale + 0.5);
    int target_y = (int)(112.0 * scale + 0.5);
    int menu_y = target_y - (int)(8.0 * scale + 0.5) - panel_h;
    double target_center_x =
        (24.0 + 12.0) * scale + (w_hello + w_world) * 0.5;
    int menu_x = (int)(target_center_x + 0.5) - panel_w / 2;
    int copy_x = menu_x + pad + w_copy / 2;
    int copy_y = menu_y + panel_h / 2;

    dispatch_after(dispatch_time(0, 900 * 1000000LL),
                   dispatch_get_main_queue(), ^{
        printf("[menu] visible %d\n",
               [[UIMenuController sharedMenuController] isMenuVisible] ? 1 : 0);
        const char *path = getenv("IOSIM_TEST_PNG");
        if (path)
            iosim_fb_present(path);
        send_tap(copy_x, copy_y);
        printf("[menu] tapped\n");
        fflush(0);
    });

    dispatch_after(dispatch_time(0, 1500 * 1000000LL),
                   dispatch_get_main_queue(), ^{
        id string = [[UIPasteboard generalPasteboard] string];
        printf("[menu] pasteboard %d\n",
               string && [string isEqualToString:@"world"] ? 1 : 0);
        printf("[menu] hidden %d\n",
               [[UIMenuController sharedMenuController] isMenuVisible] ? 0 : 1);
        const char *path2 = getenv("IOSIM_TEST_PNG2");
        if (path2)
            iosim_fb_present(path2);
        printf("[menu] png written\n");
        fflush(0);
        exit(0);
    });

    self.view = root;
}
@end

@interface MenuSceneDelegate : UIResponder <UIWindowSceneDelegate>
@property(nonatomic, retain) UIWindow *window;
@end

@interface MenuAppDelegate : UIResponder <UIApplicationDelegate>
@end

@implementation MenuAppDelegate
- (UISceneConfiguration *)application:(UIApplication *)application
    configurationForConnectingSceneSession:(UISceneSession *)session
    options:(UISceneConnectionOptions *)connectionOptions
{
    (void)application; (void)session; (void)connectionOptions;
    UISceneConfiguration *configuration = [[UISceneConfiguration alloc]
        initWithName:@"Default Configuration"
         sessionRole:UIWindowSceneSessionRoleApplication];
    configuration.delegateClass = [MenuSceneDelegate class];
    return configuration;
}
@end

@implementation MenuSceneDelegate
- (void)scene:(UIScene *)scene
    willConnectToSession:(UISceneSession *)session
                 options:(UISceneConnectionOptions *)connectionOptions
{
    (void)session; (void)connectionOptions;
    self.window = [[UIWindow alloc] initWithWindowScene:(UIWindowScene *)scene];
    self.window.frame = [[UIScreen mainScreen] bounds];
    self.window.rootViewController = [[MenuController alloc] init];
    [self.window makeKeyAndVisible];
}
@end

int main(int argc, char **argv)
{
    @autoreleasepool
    {
        return UIApplicationMain(argc, argv, nil, @"MenuAppDelegate");
    }
}
