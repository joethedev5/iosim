/* UserNotifications: authorization and settings, a one-shot time-interval
 * request delivered to the center delegate, a repeating request, pending and
 * delivered lists, removal, and the shared SpringBoard schedule file that
 * follows each request. */
#include "UIKitStub.h"

extern int printf(const char *fmt, ...);
extern int fflush(void *stream);
extern int iosim_fb_present(const char *path);
extern char *getenv(const char *name);
extern void exit(int status);
extern int snprintf(char *buf, unsigned long size, const char *fmt, ...);
extern int iosim_fs_list(const char *path, char *out, unsigned long cap);
extern unsigned long long dispatch_time(unsigned long long when,
                                        long long delta);
extern void dispatch_after(unsigned long long when, void *queue,
                           void (^block)(void));
extern void *dispatch_get_main_queue(void);

static void capture(const char *variable)
{
    const char *path = getenv(variable);
    if (path)
        iosim_fb_present(path);
    fflush(0);
}

static int store_count(void)
{
    const char *shared = getenv("SIMULATOR_SHARED_RESOURCES_DIRECTORY");
    if (!shared || !*shared)
        return -1;
    char dir[900];
    snprintf(dir, sizeof(dir), "%s/Library/SpringBoard/notifications",
             shared);
    char list[4096];
    int count = iosim_fs_list(dir, list, sizeof(list));
    return count < 0 ? 0 : count;
}

static int g_ticks;

@interface NotifyController : UIViewController <UNUserNotificationCenterDelegate>
@end

@implementation NotifyController
- (void)userNotificationCenter:(id)center
       willPresentNotification:(id)notification
         withCompletionHandler:(void (^)(unsigned long))completionHandler
{
    (void)center;
    UNNotificationRequest *request = [notification request];
    printf("[un] willPresent %s %s\n",
           [[request identifier] UTF8String],
           [[[request content] title] UTF8String]);
    fflush(0);
    if ([[request identifier] isEqual:@"tick"])
        g_ticks++;
    if (completionHandler)
        completionHandler(UNNotificationPresentationOptionBanner |
                          UNNotificationPresentationOptionList);
}

- (void)userNotificationCenter:(id)center
    didReceiveNotificationResponse:(id)response
             withCompletionHandler:(void (^)(void))completionHandler
{
    (void)center;
    printf("[un] response %s\n", [[response actionIdentifier] UTF8String]);
    fflush(0);
    if (completionHandler)
        completionHandler();
}

- (void)loadView
{
    UIView *root =
        [[UIView alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    root.backgroundColor =
        [UIColor colorWithRed:0.35 green:0.20 blue:0.55 alpha:1.0];
    self.view = root;
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(40, 120, 320, 40)];
    [label setText:@"Notifications"];
    [label setTextColor:[UIColor whiteColor]];
    [root addSubview:label];
}
@end

@interface NotifySceneDelegate : UIResponder <UIWindowSceneDelegate>
@property(nonatomic, retain) UIWindow *window;
@end

@interface NotifyAppDelegate : UIResponder <UIApplicationDelegate>
@end

@implementation NotifyAppDelegate
- (UISceneConfiguration *)application:(UIApplication *)application
    configurationForConnectingSceneSession:(UISceneSession *)session
    options:(UISceneConnectionOptions *)connectionOptions
{
    (void)application; (void)session; (void)connectionOptions;
    UISceneConfiguration *configuration = [[UISceneConfiguration alloc]
        initWithName:@"Default Configuration"
         sessionRole:UIWindowSceneSessionRoleApplication];
    configuration.delegateClass = [NotifySceneDelegate class];
    return configuration;
}
@end

@implementation NotifySceneDelegate
- (void)scene:(UIScene *)scene
    willConnectToSession:(UISceneSession *)session
                 options:(UISceneConnectionOptions *)connectionOptions
{
    (void)session; (void)connectionOptions;
    self.window = [[UIWindow alloc] initWithWindowScene:(UIWindowScene *)scene];
    self.window.frame = [[UIScreen mainScreen] bounds];
    self.window.rootViewController = [[NotifyController alloc] init];
    [self.window makeKeyAndVisible];

    UNUserNotificationCenter *center =
        [UNUserNotificationCenter currentNotificationCenter];
    [center setDelegate:self.window.rootViewController];
    [center requestAuthorizationWithOptions:
                (UNAuthorizationOptionAlert | UNAuthorizationOptionSound |
                 UNAuthorizationOptionBadge)
        completionHandler:^(BOOL granted, id error) {
        (void)error;
        printf("[un] granted %d\n", granted ? 1 : 0);
        fflush(0);
    }];
    [center getNotificationSettingsWithCompletionHandler:^(id settings) {
        printf("[un] status %ld\n", (long)[settings authorizationStatus]);
        fflush(0);
    }];

    dispatch_after(dispatch_time(0, 100 * 1000000LL),
                   dispatch_get_main_queue(), ^{
        UNMutableNotificationContent *content =
            [[UNMutableNotificationContent alloc] init];
        [content setTitle:@"Lunch"];
        [content setBody:@"Tacos at noon"];
        UNNotificationRequest *request = [UNNotificationRequest
            requestWithIdentifier:@"lunch"
                          content:content
                          trigger:[UNTimeIntervalNotificationTrigger
                                      triggerWithTimeInterval:0.6
                                                      repeats:NO]];
        [[UNUserNotificationCenter currentNotificationCenter]
            addNotificationRequest:request
             withCompletionHandler:^(id error) {
            printf("[un] added %d\n", error ? 0 : 1);
            fflush(0);
        }];
    });
    dispatch_after(dispatch_time(0, 250 * 1000000LL),
                   dispatch_get_main_queue(), ^{
        UNUserNotificationCenter *center =
            [UNUserNotificationCenter currentNotificationCenter];
        [center getPendingNotificationRequestsWithCompletionHandler:
            ^(id requests) {
            printf("[un] pending %d store %d\n", (int)[requests count],
                   store_count());
            fflush(0);
        }];
    });
    dispatch_after(dispatch_time(0, 1100 * 1000000LL),
                   dispatch_get_main_queue(), ^{
        UNUserNotificationCenter *center =
            [UNUserNotificationCenter currentNotificationCenter];
        [center getPendingNotificationRequestsWithCompletionHandler:
            ^(id requests) {
            printf("[un] after pending %d store %d\n", (int)[requests count],
                   store_count());
            fflush(0);
        }];
        [center getDeliveredNotificationsWithCompletionHandler:
            ^(id notifications) {
            printf("[un] delivered %d\n", (int)[notifications count]);
            if ([notifications count] > 0)
            {
                UNNotification *notification =
                    [notifications objectAtIndex:0];
                printf("[un] delivered title %s\n",
                       [[[[notification request] content] title] UTF8String]);
            }
            fflush(0);
        }];
        UNMutableNotificationContent *content =
            [[UNMutableNotificationContent alloc] init];
        [content setTitle:@"Tick"];
        UNNotificationRequest *repeat = [UNNotificationRequest
            requestWithIdentifier:@"tick"
                          content:content
                          trigger:[UNTimeIntervalNotificationTrigger
                                      triggerWithTimeInterval:0.35
                                                      repeats:YES]];
        [center addNotificationRequest:repeat withCompletionHandler:nil];
        printf("[un] repeat store %d\n", store_count());
        fflush(0);
    });
    dispatch_after(dispatch_time(0, 2100 * 1000000LL),
                   dispatch_get_main_queue(), ^{
        printf("[un] ticks %d\n", g_ticks);
        UNUserNotificationCenter *center =
            [UNUserNotificationCenter currentNotificationCenter];
        id identifiers[1] = { @"tick" };
        [center removePendingNotificationRequestsWithIdentifiers:
            [NSArray arrayWithObjects:identifiers count:1]];
        [center removeAllDeliveredNotifications];
        [center getPendingNotificationRequestsWithCompletionHandler:
            ^(id requests) {
            printf("[un] stopped pending %d\n", (int)[requests count]);
        }];
        [center getDeliveredNotificationsWithCompletionHandler:
            ^(id notifications) {
            printf("[un] stopped delivered %d store %d\n",
                   (int)[notifications count], store_count());
            fflush(0);
        }];
    });
    dispatch_after(dispatch_time(0, 2600 * 1000000LL),
                   dispatch_get_main_queue(), ^{
        capture("IOSIM_TEST_PNG_FINAL");
        printf("[un] png written\n");
        fflush(0);
        exit(0);
    });
}
@end

int main(int argc, char **argv)
{
    @autoreleasepool
    {
        return UIApplicationMain(argc, argv, nil, @"NotifyAppDelegate");
    }
}
