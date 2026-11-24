/* One UIKit fixture source built for both architectures. The scene
 * delegate, view hierarchy and delayed capture block are arm64 app code
 * running on the interpreter and block translator while UIKit,
 * QuartzCore and libdispatch stay native x86_64 and call back through
 * the reverse bridge. The x86_64 build of this same file must render the
 * same scene. */
#include "UIKitStub.h"

extern int printf(const char *fmt, ...);
extern int fflush(void *stream);
extern void exit(int status);
extern int iosim_fb_present(const char *path);
extern char *getenv(const char *name);
extern unsigned long long dispatch_time(unsigned long long when,
                                        long long delta);
extern void dispatch_after(unsigned long long when, void *queue,
                           void (^block)(void));
extern void *dispatch_get_main_queue(void);

@interface Arm64SceneDelegate : UIResponder <UIWindowSceneDelegate>
@property(nonatomic, retain) UIWindow *window;
@end

@implementation Arm64SceneDelegate

- (void)scene:(UIScene *)scene
    willConnectToSession:(UISceneSession *)session
                 options:(UISceneConnectionOptions *)connectionOptions
{
    (void)session;
    (void)connectionOptions;
    CGRect screen = [[UIScreen mainScreen] bounds];
    double width = screen.size.width;

    self.window = [[UIWindow alloc] initWithWindowScene:(UIWindowScene *)scene];
    self.window.frame = screen;
    self.window.backgroundColor = [UIColor blackColor];

    UIView *red = [[UIView alloc] initWithFrame:CGRectMake(40, 100, 120, 80)];
    red.backgroundColor = [UIColor redColor];
    [self.window addSubview:red];

    UIView *green =
        [[UIView alloc] initWithFrame:CGRectMake(40, 220, 120, 80)];
    green.backgroundColor = [UIColor greenColor];
    [self.window addSubview:green];

    UIView *blue = [[UIView alloc] initWithFrame:CGRectMake(40, 340, 120, 80)];
    blue.backgroundColor = [UIColor blueColor];
    [self.window addSubview:blue];

    UILabel *label =
        [[UILabel alloc] initWithFrame:CGRectMake(40, 480, width - 80, 48)];
    label.text = @"arm64 UIKit";
    label.textColor = [UIColor whiteColor];
    label.font = [UIFont boldSystemFontOfSize:34];
    [self.window addSubview:label];

    [self.window makeKeyAndVisible];

    dispatch_after(dispatch_time(0, 400 * 1000000LL),
                   dispatch_get_main_queue(), ^{
        const char *path = getenv("IOSIM_TEST_PNG");
        if (path)
            iosim_fb_present(path);
        printf("[arm64uikit] ready\n");
        fflush(0);
        exit(0);
    });
}

@end

@interface Arm64AppDelegate : UIResponder <UIApplicationDelegate>
@end

@implementation Arm64AppDelegate

- (UISceneConfiguration *)application:(UIApplication *)application
    configurationForConnectingSceneSession:(UISceneSession *)session
    options:(UISceneConnectionOptions *)options
{
    (void)application;
    (void)session;
    (void)options;
    UISceneConfiguration *configuration = [[UISceneConfiguration alloc]
        initWithName:@"Default Configuration"
         sessionRole:UIWindowSceneSessionRoleApplication];
    configuration.delegateClass = [Arm64SceneDelegate class];
    return configuration;
}

@end

int main(int argc, char **argv)
{
    return UIApplicationMain(argc, argv, nil, @"Arm64AppDelegate");
}
