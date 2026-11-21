/* A notification app for the system UI: schedules a request, receives the
 * tapped response after SpringBoard resumes it, and schedules a second
 * request from the delegate so Notification Center has two entries. */
#include "UIKitStub.h"

extern int printf(const char *fmt, ...);
extern int fflush(void *stream);
extern int strcmp(const char *a, const char *b);

static void schedule(const char *identifier, const char *title,
                     const char *body, double interval)
{
    UNMutableNotificationContent *content =
        [[UNMutableNotificationContent alloc] init];
    [content setTitle:[NSString stringWithUTF8String:title]];
    [content setBody:[NSString stringWithUTF8String:body]];
    UNNotificationRequest *request = [UNNotificationRequest
        requestWithIdentifier:[NSString stringWithUTF8String:identifier]
                      content:content
                      trigger:[UNTimeIntervalNotificationTrigger
                                  triggerWithTimeInterval:interval
                                                  repeats:NO]];
    [[UNUserNotificationCenter currentNotificationCenter]
        addNotificationRequest:request
         withCompletionHandler:^(id error) {
        printf("[notifyapp] scheduled %s %d\n", identifier,
               error ? 0 : 1);
        fflush(0);
    }];
}

@interface NotifyAppController : UIViewController <UNUserNotificationCenterDelegate>
@end

@implementation NotifyAppController
- (void)userNotificationCenter:(id)center
       willPresentNotification:(id)notification
         withCompletionHandler:(void (^)(unsigned long))completionHandler
{
    (void)center;
    printf("[notifyapp] willPresent %s\n",
           [[[notification request] identifier] UTF8String]);
    fflush(0);
    if (completionHandler)
        completionHandler(UNNotificationPresentationOptionList);
}

- (void)userNotificationCenter:(id)center
    didReceiveNotificationResponse:(id)response
             withCompletionHandler:(void (^)(void))completionHandler
{
    (void)center;
    UNNotificationRequest *request = [[response notification] request];
    printf("[notifyapp] didReceive %s %s\n",
           [[request identifier] UTF8String],
           [[[request content] title] UTF8String]);
    fflush(0);
    if (strcmp([[request identifier] UTF8String], "first") == 0)
    {
        schedule("second", "Meeting", "Room 4 at 3", 4.0);
    }
    if (completionHandler)
        completionHandler();
}

- (void)loadView
{
    UIView *root =
        [[UIView alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    root.backgroundColor =
        [UIColor colorWithRed:0.15 green:0.35 blue:0.75 alpha:1.0];
    self.view = root;
    UILabel *label =
        [[UILabel alloc] initWithFrame:CGRectMake(40, 120, 320, 40)];
    [label setText:@"Notify"];
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
    NotifyAppController *controller = [[NotifyAppController alloc] init];
    self.window.rootViewController = controller;
    [self.window makeKeyAndVisible];

    UNUserNotificationCenter *center =
        [UNUserNotificationCenter currentNotificationCenter];
    [center setDelegate:controller];
    [center requestAuthorizationWithOptions:
                (UNAuthorizationOptionAlert | UNAuthorizationOptionSound)
        completionHandler:^(BOOL granted, id error) {
        (void)error;
        printf("[notifyapp] granted %d\n", granted ? 1 : 0);
        fflush(0);
    }];
    schedule("first", "Lunch", "Tacos at noon", 2.0);
}
@end

int main(int argc, char **argv)
{
    @autoreleasepool
    {
        return UIApplicationMain(argc, argv, nil, @"NotifyAppDelegate");
    }
}
