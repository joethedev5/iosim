/* Context menu palette: a root menu with UIMenuOptionsDisplayAsPalette draws
 * three icon columns; tapping the green column runs its action and dismisses. */
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

static int palette_card(void)
{
    unsigned pixel = 0;
    iosim_fb_capture(120 * 3, 565 * 3, 1, 1, &pixel);
    unsigned r = (pixel >> 16) & 255, g = (pixel >> 8) & 255,
             b = pixel & 255;
    return r > 25 && r < 60 && g > 25 && g < 60 && b > 35 && b < 75;
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

static UIImage *make_icon(double red, double green, double blue)
{
    UIGraphicsImageRenderer *renderer =
        [[UIGraphicsImageRenderer alloc] initWithSize:CGSizeMake(24, 24)];
    return [renderer imageWithActions:^(
        UIGraphicsImageRendererContext *ctx) {
        CGContextSetRGBFillColor([ctx CGContext], red, green, blue, 1);
        CGContextFillRect([ctx CGContext], CGRectMake(0, 0, 24, 24));
    }];
}

@interface PaletteController : UIViewController
    <UIContextMenuInteractionDelegate>
@end

@implementation PaletteController
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
        capture_when("IOSIM_TEST_PNG_PALETTE", palette_card, 80, ^{
            dispatch_after(dispatch_time(0, 100 * 1000000LL),
                           dispatch_get_main_queue(), ^{
                send_event("tap 603 1620\n");
                capture_when("IOSIM_TEST_PNG_END", backdrop_green, 80, ^{
                    printf("[palette] png written\n");
                    fflush(0);
                    exit(0);
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
        UIAction *red = [UIAction actionWithTitle:@"Red"
                                           image:make_icon(1, 0, 0)
                                      identifier:nil
                                         handler:^(UIAction *action) {
            (void)action;
            printf("[palette] red\n");
            fflush(0);
        }];
        UIAction *green = [UIAction actionWithTitle:@"Green"
                                             image:make_icon(0, 1, 0)
                                        identifier:nil
                                           handler:^(UIAction *action) {
            (void)action;
            printf("[palette] green\n");
            fflush(0);
        }];
        UIAction *blue = [UIAction actionWithTitle:@"Blue"
                                            image:make_icon(0, 0, 1)
                                       identifier:nil
                                          handler:^(UIAction *action) {
            (void)action;
            printf("[palette] blue\n");
            fflush(0);
        }];
        id children[3] = { red, green, blue };
        return [UIMenu
            menuWithTitle:nil
                    image:nil
               identifier:nil
                  options:UIMenuOptionsDisplayAsPalette
                 children:[NSArray arrayWithObjects:children count:3]];
    }];
}
@end

@interface PaletteSceneDelegate : UIResponder <UIWindowSceneDelegate>
@property(nonatomic, retain) UIWindow *window;
@end

@interface PaletteAppDelegate : UIResponder <UIApplicationDelegate>
@end

@implementation PaletteAppDelegate
- (UISceneConfiguration *)application:(UIApplication *)application
    configurationForConnectingSceneSession:(UISceneSession *)session
    options:(UISceneConnectionOptions *)connectionOptions
{
    (void)application; (void)session; (void)connectionOptions;
    UISceneConfiguration *configuration = [[UISceneConfiguration alloc]
        initWithName:@"Default Configuration"
         sessionRole:UIWindowSceneSessionRoleApplication];
    configuration.delegateClass = [PaletteSceneDelegate class];
    return configuration;
}
@end

@implementation PaletteSceneDelegate
- (void)scene:(UIScene *)scene
    willConnectToSession:(UISceneSession *)session
                 options:(UISceneConnectionOptions *)connectionOptions
{
    (void)session; (void)connectionOptions;
    self.window = [[UIWindow alloc] initWithWindowScene:(UIWindowScene *)scene];
    self.window.frame = [[UIScreen mainScreen] bounds];
    self.window.rootViewController = [[PaletteController alloc] init];
    [self.window makeKeyAndVisible];
}
@end

int main(int argc, char **argv)
{
    @autoreleasepool
    {
        return UIApplicationMain(argc, argv, nil, @"PaletteAppDelegate");
    }
}
