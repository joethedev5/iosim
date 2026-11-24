/* Menu action state: a Pin action with UIMenuElementAttributesKeepsMenuPresented
 * toggles its own checkmark without dismissing, and a single-selection Sort
 * submenu moves its checkmark to the tapped action while staying presented. */
#include "UIKitStub.h"

extern int printf(const char *fmt, ...);
extern int fflush(void *stream);
extern int iosim_fb_present(const char *path);
extern void iosim_fb_capture(int x, int y, int w, int h, unsigned *out);
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

static void send_touch(const char *kind, double x, double y)
{
    char line[96];
    snprintf(line, sizeof(line), "%s %d %d\n", kind, (int)(x * 3.0 + 0.5),
             (int)(y * 3.0 + 0.5));
    send_event(line);
}

static void capture(const char *variable)
{
    const char *path = getenv(variable);
    if (path)
        iosim_fb_present(path);
    fflush(0);
}

static int menu_page_pixel(int x, int y)
{
    unsigned pixel = 0;
    iosim_fb_capture(x * 3, y * 3, 1, 1, &pixel);
    unsigned r = (pixel >> 16) & 255, g = (pixel >> 8) & 255,
             b = pixel & 255;
    return r > 25 && r < 60 && g > 25 && g < 60 && b > 35 && b < 75;
}

static int region_has_light(int x0, int y0, int x1, int y1)
{
    unsigned pixels[40 * 40 * 9];
    int w = x1 - x0, h = y1 - y0;
    if (w <= 0 || h <= 0 || w > 40 || h > 40)
        return 0;
    iosim_fb_capture(x0 * 3, y0 * 3, w * 3, h * 3, pixels);
    for (int i = 0; i < w * h * 9; i++)
    {
        unsigned p = pixels[i];
        unsigned r = (p >> 16) & 255, g = (p >> 8) & 255, b = p & 255;
        if (r > 110 && g > 110 && b > 110)
            return 1;
    }
    return 0;
}

static int backdrop_green(void)
{
    unsigned pixel = 0;
    iosim_fb_capture(201 * 3, 300 * 3, 1, 1, &pixel);
    unsigned r = (pixel >> 16) & 255, g = (pixel >> 8) & 255,
             b = pixel & 255;
    return r < 80 && g > 170 && b < 130;
}

static void capture_when(const char *variable, int (*ready)(void),
                         int attempts, void (^then)(void))
{
    if (!ready() && attempts > 0)
    {
        dispatch_after(dispatch_time(0, 50 * 1000000LL),
                       dispatch_get_main_queue(), ^{
            capture_when(variable, ready, attempts - 1, then);
        });
        return;
    }
    if (variable)
        capture(variable);
    if (then)
        then();
}

static UIAction *g_pin;
static UIAction *g_sortName;
static UIAction *g_sortDate;

static int root_ready(void)
{
    return region_has_light(286, 552, 320, 582) && !menu_page_pixel(201, 620);
}

static int pin_checked(void)
{
    return region_has_light(288, 506, 316, 536);
}

static int pin_clear(void)
{
    return !region_has_light(288, 506, 316, 536);
}

static int sort_page_ready(void)
{
    return menu_page_pixel(201, 620) &&
           region_has_light(288, 552, 316, 582);
}

static int sort_date_ready(void)
{
    return menu_page_pixel(201, 620) &&
           region_has_light(288, 598, 316, 628) &&
           !region_has_light(288, 552, 316, 582);
}

@interface StateController : UIViewController <UIContextMenuInteractionDelegate>
@end

@implementation StateController
- (void)loadView
{
    UIView *root =
        [[UIView alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    root.backgroundColor =
        [UIColor colorWithRed:0.10 green:0.80 blue:0.30 alpha:1.0];
    self.view = root;

    UIView *orange = [[UIView alloc] initWithFrame:CGRectMake(30, 400, 120, 80)];
    orange.backgroundColor =
        [UIColor colorWithRed:0.90 green:0.40 blue:0.10 alpha:1.0];
    [root addSubview:orange];
    UIContextMenuInteraction *interaction =
        [[UIContextMenuInteraction alloc] initWithDelegate:self];
    [orange addInteraction:interaction];

    dispatch_after(dispatch_time(0, 150 * 1000000LL),
                   dispatch_get_main_queue(), ^{
        send_touch("down", 90, 440);
    });
    dispatch_after(dispatch_time(0, 800 * 1000000LL),
                   dispatch_get_main_queue(), ^{
        send_touch("up", 90, 440);
        capture_when("IOSIM_TEST_PNG_STATE", root_ready, 80, ^{
            dispatch_after(dispatch_time(0, 100 * 1000000LL),
                           dispatch_get_main_queue(), ^{
                send_event("tap 603 1560\n");
                capture_when("IOSIM_TEST_PNG_PINON", pin_checked, 80, ^{
                    dispatch_after(dispatch_time(0, 100 * 1000000LL),
                                   dispatch_get_main_queue(), ^{
                        send_event("tap 603 1560\n");
                        capture_when("IOSIM_TEST_PNG_PINOFF", pin_clear, 80, ^{
                            dispatch_after(
                                dispatch_time(0, 100 * 1000000LL),
                                dispatch_get_main_queue(), ^{
                                send_event("tap 603 1701\n");
                                capture_when("IOSIM_TEST_PNG_SORT",
                                             sort_page_ready, 80, ^{
                                    dispatch_after(
                                        dispatch_time(0, 100 * 1000000LL),
                                        dispatch_get_main_queue(), ^{
                                        send_event("tap 603 1839\n");
                                        capture_when(
                                            "IOSIM_TEST_PNG_SORT2",
                                            sort_date_ready, 80, ^{
                                            dispatch_after(
                                                dispatch_time(
                                                    0, 100 * 1000000LL),
                                                dispatch_get_main_queue(), ^{
                                                send_event("tap 603 1560\n");
                                                capture_when(
                                                    "IOSIM_TEST_PNG_BACK",
                                                    root_ready, 80, ^{
                                                    dispatch_after(
                                                        dispatch_time(
                                                            0,
                                                            100 * 1000000LL),
                                                        dispatch_get_main_queue(),
                                                        ^{
                                                        send_event(
                                                            "tap 60 900\n");
                                                        capture_when(
                                                            "IOSIM_TEST_PNG_END",
                                                            backdrop_green,
                                                            80, ^{
                                                            printf("[state] "
                                                                   "png "
                                                                   "written\n");
                                                            fflush(0);
                                                            exit(0);
                                                        });
                                                    });
                                                });
                                            });
                                        });
                                    });
                                });
                            });
                        });
                    });
                });
            });
        });
    });
}

- (UIContextMenuConfiguration *)contextMenuInteraction:
    (UIContextMenuInteraction *)interaction
    configurationForMenuAtLocation:(CGPoint)location
{
    (void)interaction;
    (void)location;
    return [UIContextMenuConfiguration
        configurationWithIdentifier:nil
                    previewProvider:nil
                     actionProvider:^UIMenu *(NSArray *suggested) {
        (void)suggested;
        UIAction *pin = [UIAction actionWithTitle:@"Pin"
                                           image:nil
                                      identifier:nil
                                         handler:^(UIAction *action) {
            (void)action;
            [g_pin setState:([g_pin state] == UIMenuElementStateOn
                                 ? UIMenuElementStateOff
                                 : UIMenuElementStateOn)];
            printf("[state] pin %ld\n", [g_pin state]);
            fflush(0);
        }];
        [pin setAttributes:UIMenuElementAttributesKeepsMenuPresented];
        UIAction *byName = [UIAction actionWithTitle:@"Sort Name"
                                              image:nil
                                         identifier:nil
                                            handler:^(UIAction *action) {
            (void)action;
            printf("[state] sort name=%ld date=%ld\n",
                   [g_sortName state], [g_sortDate state]);
            fflush(0);
        }];
        UIAction *byDate = [UIAction actionWithTitle:@"Sort Date"
                                              image:nil
                                         identifier:nil
                                            handler:^(UIAction *action) {
            (void)action;
            printf("[state] sort date name=%ld date=%ld\n",
                   [g_sortName state], [g_sortDate state]);
            fflush(0);
        }];
        [byName setState:UIMenuElementStateOn];
        [byName setAttributes:UIMenuElementAttributesKeepsMenuPresented];
        [byDate setAttributes:UIMenuElementAttributesKeepsMenuPresented];
        g_pin = pin;
        g_sortName = byName;
        g_sortDate = byDate;
        id sortChildren[2] = { byName, byDate };
        UIMenu *sort = [UIMenu
            menuWithTitle:@"Sort"
                    image:nil
               identifier:nil
                  options:UIMenuOptionsSingleSelection
                 children:[NSArray arrayWithObjects:sortChildren count:2]];
        id children[2] = { pin, sort };
        return [UIMenu menuWithTitle:nil
                            children:[NSArray arrayWithObjects:children
                                                           count:2]];
    }];
}
@end

@interface StateSceneDelegate : UIResponder <UIWindowSceneDelegate>
@property(nonatomic, retain) UIWindow *window;
@end

@interface StateAppDelegate : UIResponder <UIApplicationDelegate>
@end

@implementation StateAppDelegate
- (UISceneConfiguration *)application:(UIApplication *)application
    configurationForConnectingSceneSession:(UISceneSession *)session
    options:(UISceneConnectionOptions *)connectionOptions
{
    (void)application; (void)session; (void)connectionOptions;
    UISceneConfiguration *configuration = [[UISceneConfiguration alloc]
        initWithName:@"Default Configuration"
         sessionRole:UIWindowSceneSessionRoleApplication];
    configuration.delegateClass = [StateSceneDelegate class];
    return configuration;
}
@end

@implementation StateSceneDelegate
- (void)scene:(UIScene *)scene
    willConnectToSession:(UISceneSession *)session
                 options:(UISceneConnectionOptions *)connectionOptions
{
    (void)session; (void)connectionOptions;
    self.window = [[UIWindow alloc] initWithWindowScene:(UIWindowScene *)scene];
    self.window.frame = [[UIScreen mainScreen] bounds];
    self.window.rootViewController = [[StateController alloc] init];
    [self.window makeKeyAndVisible];
}
@end

int main(int argc, char **argv)
{
    @autoreleasepool
    {
        return UIApplicationMain(argc, argv, nil, @"StateAppDelegate");
    }
}
