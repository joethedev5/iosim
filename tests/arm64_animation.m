/* Native framework code invokes app blocks directly. UIView runs the
 * animation and completion blocks, Foundation runs the index-set
 * enumerator, and UserNotifications runs the authorization completion;
 * all of them are arm64 blocks reached through the loader's block-call
 * bridge. */
#include "UIKitStub.h"

extern int printf(const char *fmt, ...);
extern int fflush(void *stream);
extern void exit(int status);

@interface Arm64AnimSceneDelegate : UIResponder <UIWindowSceneDelegate>
@property(nonatomic, retain) UIWindow *window;
@end

@implementation Arm64AnimSceneDelegate

- (void)scene:(UIScene *)scene
    willConnectToSession:(UISceneSession *)session
                 options:(UISceneConnectionOptions *)connectionOptions
{
    (void)session;
    (void)connectionOptions;
    CGRect screen = [[UIScreen mainScreen] bounds];

    self.window = [[UIWindow alloc] initWithWindowScene:(UIWindowScene *)scene];
    self.window.frame = screen;
    self.window.backgroundColor = [UIColor blackColor];

    UIView *box = [[UIView alloc] initWithFrame:CGRectMake(40, 100, 120, 80)];
    box.backgroundColor = [UIColor redColor];
    [self.window addSubview:box];
    [self.window makeKeyAndVisible];

    NSMutableIndexSet *set = [[NSMutableIndexSet alloc] init];
    [set addIndex:1];
    [set addIndex:3];
    [set addIndex:5];
    __block int total = 0;
    [set enumerateIndexesUsingBlock:^(unsigned long index, BOOL *stop) {
        total += (int)index;
        if (index == 3)
            *stop = YES;
    }];
    printf("[arm64anim] indexes %d\n", total);

    UNUserNotificationCenter *center =
        [UNUserNotificationCenter currentNotificationCenter];
    [center requestAuthorizationWithOptions:3
                          completionHandler:^(BOOL granted, id error) {
        printf("[arm64anim] auth %d %d\n", (int)granted,
               error != nil ? 1 : 0);
    }];

    printf("[arm64anim] start %d\n", (int)(box.alpha * 100));
    fflush(0);
    [UIView animateWithDuration:0.2
                     animations:^{
        box.alpha = 0.5;
    }
                     completion:^(BOOL finished) {
        printf("[arm64anim] completion %d %d\n", (int)finished,
               (int)(box.alpha * 100));
        fflush(0);
        exit(0);
    }];
}

@end

@interface Arm64AnimAppDelegate : UIResponder <UIApplicationDelegate>
@end

@implementation Arm64AnimAppDelegate

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
    configuration.delegateClass = [Arm64AnimSceneDelegate class];
    return configuration;
}

@end

int main(int argc, char **argv)
{
    return UIApplicationMain(argc, argv, nil, @"Arm64AnimAppDelegate");
}
