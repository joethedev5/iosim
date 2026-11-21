/* Animated modal presentation: a page sheet slides up over a dimmed parent
 * and slides back down on dismissal. Timed captures sample both phases. */
#include "UIKitStub.h"

extern int printf(const char *fmt, ...);
extern int fflush(void *stream);
extern int iosim_fb_present(const char *path);
extern char *getenv(const char *name);
extern void exit(int status);
extern unsigned long long dispatch_time(unsigned long long when,
                                        long long delta);
extern void dispatch_after(unsigned long long when, void *queue,
                           void (^block)(void));
extern void *dispatch_get_main_queue(void);

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
}
@end

@interface ModalController : UIViewController
@end

@implementation ModalController
- (void)loadView
{
    UIView *root =
        [[UIView alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    root.backgroundColor =
        [UIColor colorWithRed:0.043 green:0.055 blue:0.102 alpha:1.0];
    self.view = root;

    dispatch_after(dispatch_time(0, 150 * 1000000LL),
                   dispatch_get_main_queue(), ^{
        SheetController *sheet = [[SheetController alloc] init];
        [self presentViewController:sheet animated:YES completion:nil];
        printf("[modal] presented\n");
        fflush(0);
    });

    dispatch_after(dispatch_time(0, 250 * 1000000LL),
                   dispatch_get_main_queue(), ^{
        const char *path = getenv("IOSIM_TEST_PNG_MID1");
        if (path)
            iosim_fb_present(path);
        fflush(0);
    });

    dispatch_after(dispatch_time(0, 700 * 1000000LL),
                   dispatch_get_main_queue(), ^{
        const char *path = getenv("IOSIM_TEST_PNG_FULL");
        if (path)
            iosim_fb_present(path);
        fflush(0);
    });

    dispatch_after(dispatch_time(0, 900 * 1000000LL),
                   dispatch_get_main_queue(), ^{
        [self dismissViewControllerAnimated:YES completion:nil];
        printf("[modal] dismissed\n");
        fflush(0);
    });

    dispatch_after(dispatch_time(0, 1000 * 1000000LL),
                   dispatch_get_main_queue(), ^{
        const char *path = getenv("IOSIM_TEST_PNG_MID2");
        if (path)
            iosim_fb_present(path);
        fflush(0);
    });

    dispatch_after(dispatch_time(0, 1400 * 1000000LL),
                   dispatch_get_main_queue(), ^{
        const char *path = getenv("IOSIM_TEST_PNG_END");
        if (path)
            iosim_fb_present(path);
        printf("[modal] png written\n");
        fflush(0);
        exit(0);
    });
}
@end

@interface ModalSceneDelegate : UIResponder <UIWindowSceneDelegate>
@property(nonatomic, retain) UIWindow *window;
@end

@interface ModalAppDelegate : UIResponder <UIApplicationDelegate>
@end

@implementation ModalAppDelegate
- (UISceneConfiguration *)application:(UIApplication *)application
    configurationForConnectingSceneSession:(UISceneSession *)session
    options:(UISceneConnectionOptions *)connectionOptions
{
    (void)application; (void)session; (void)connectionOptions;
    UISceneConfiguration *configuration = [[UISceneConfiguration alloc]
        initWithName:@"Default Configuration"
         sessionRole:UIWindowSceneSessionRoleApplication];
    configuration.delegateClass = [ModalSceneDelegate class];
    return configuration;
}
@end

@implementation ModalSceneDelegate
- (void)scene:(UIScene *)scene
    willConnectToSession:(UISceneSession *)session
                 options:(UISceneConnectionOptions *)connectionOptions
{
    (void)session; (void)connectionOptions;
    self.window = [[UIWindow alloc] initWithWindowScene:(UIWindowScene *)scene];
    self.window.frame = [[UIScreen mainScreen] bounds];
    self.window.rootViewController = [[ModalController alloc] init];
    [self.window makeKeyAndVisible];
}
@end

int main(int argc, char **argv)
{
    @autoreleasepool
    {
        return UIApplicationMain(argc, argv, nil, @"ModalAppDelegate");
    }
}
