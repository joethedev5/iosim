/* A thin arm64 app bundle for the device path. iosimctl install/launch
 * start the loader with only a framework search directory, so a main
 * executable linked with -undefined dynamic_lookup has no load commands
 * naming UIKit; the loader preloads the standard frameworks from the
 * runtime root. The scene delegate and its views are arm64 app code on
 * the interpreter and block translator, while UIKit stays native and
 * calls back through the reverse bridge. The app renders once and returns
 * from UIApplicationMain, like any app launched without an event stream. */
#include "UIKitStub.h"

extern int printf(const char *fmt, ...);
extern int fflush(void *stream);

@interface Arm64DeviceSceneDelegate : UIResponder <UIWindowSceneDelegate>
@property(nonatomic, retain) UIWindow *window;
@end

@implementation Arm64DeviceSceneDelegate

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
    label.text = @"arm64 device";
    label.textColor = [UIColor whiteColor];
    label.font = [UIFont boldSystemFontOfSize:34];
    [self.window addSubview:label];

    [self.window makeKeyAndVisible];
    printf("[arm64device] ready\n");
    fflush(0);
}

@end

@interface Arm64DeviceAppDelegate : UIResponder <UIApplicationDelegate>
@end

@implementation Arm64DeviceAppDelegate

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
    configuration.delegateClass = [Arm64DeviceSceneDelegate class];
    return configuration;
}

@end

int main(int argc, char **argv)
{
    return UIApplicationMain(argc, argv, nil, @"Arm64DeviceAppDelegate");
}
