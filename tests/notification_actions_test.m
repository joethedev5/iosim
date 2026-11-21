/* A notification app with a category: its banner can be long-pressed to
 * reveal Snooze and Delete, and the chosen action comes back through the
 * response file. */
#include "UIKitStub.h"

extern int printf(const char *fmt, ...);
extern int fflush(void *stream);
extern int strcmp(const char *a, const char *b);

static void schedule(const char *identifier, const char *title,
                     const char *body)
{
    UNMutableNotificationContent *content =
        [[UNMutableNotificationContent alloc] init];
    [content setTitle:[NSString stringWithUTF8String:title]];
    [content setBody:[NSString stringWithUTF8String:body]];
    [content setCategoryIdentifier:@"lunch"];
    UNNotificationRequest *request = [UNNotificationRequest
        requestWithIdentifier:[NSString stringWithUTF8String:identifier]
                      content:content
                      trigger:[UNTimeIntervalNotificationTrigger
                                  triggerWithTimeInterval:2.0
                                                  repeats:NO]];
    [[UNUserNotificationCenter currentNotificationCenter]
        addNotificationRequest:request
         withCompletionHandler:^(id error) {
        printf("[actions] scheduled %s %d\n", identifier,
               error ? 0 : 1);
        fflush(0);
    }];
}

@interface ActionsAppController : UIViewController <UNUserNotificationCenterDelegate>
@end

@implementation ActionsAppController
- (void)userNotificationCenter:(id)center
       willPresentNotification:(id)notification
         withCompletionHandler:(void (^)(unsigned long))completionHandler
{
    (void)center;
    printf("[actions] willPresent %s\n",
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
    printf("[actions] didReceive %s %s action=%s\n",
           [[request identifier] UTF8String],
           [[[request content] title] UTF8String],
           [[response actionIdentifier] UTF8String]);
    fflush(0);
    if (strcmp([[request identifier] UTF8String], "actionable") == 0)
        schedule("actionable2", "Dinner 2", "Second action test");
    if (completionHandler)
        completionHandler();
}

- (void)loadView
{
    UIView *root =
        [[UIView alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    root.backgroundColor =
        [UIColor colorWithRed:0.8 green:0.4 blue:0.1 alpha:1.0];
    self.view = root;
    UILabel *label =
        [[UILabel alloc] initWithFrame:CGRectMake(40, 120, 320, 40)];
    [label setText:@"Actions"];
    [label setTextColor:[UIColor whiteColor]];
    [root addSubview:label];
}
@end

@interface ActionsSceneDelegate : UIResponder <UIWindowSceneDelegate>
@property(nonatomic, retain) UIWindow *window;
@end

@interface ActionsAppDelegate : UIResponder <UIApplicationDelegate>
@end

@implementation ActionsAppDelegate
- (UISceneConfiguration *)application:(UIApplication *)application
    configurationForConnectingSceneSession:(UISceneSession *)session
    options:(UISceneConnectionOptions *)connectionOptions
{
    (void)application; (void)session; (void)connectionOptions;
    UISceneConfiguration *configuration = [[UISceneConfiguration alloc]
        initWithName:@"Default Configuration"
         sessionRole:UIWindowSceneSessionRoleApplication];
    configuration.delegateClass = [ActionsSceneDelegate class];
    return configuration;
}
@end

@implementation ActionsSceneDelegate
- (void)scene:(UIScene *)scene
    willConnectToSession:(UISceneSession *)session
                 options:(UISceneConnectionOptions *)connectionOptions
{
    (void)session; (void)connectionOptions;
    self.window = [[UIWindow alloc] initWithWindowScene:(UIWindowScene *)scene];
    self.window.frame = [[UIScreen mainScreen] bounds];
    ActionsAppController *controller = [[ActionsAppController alloc] init];
    self.window.rootViewController = controller;
    [self.window makeKeyAndVisible];

    UNUserNotificationCenter *center =
        [UNUserNotificationCenter currentNotificationCenter];
    [center setDelegate:controller];
    [center requestAuthorizationWithOptions:
                (UNAuthorizationOptionAlert | UNAuthorizationOptionSound)
        completionHandler:^(BOOL granted, id error) {
        (void)error;
        printf("[actions] granted %d\n", granted ? 1 : 0);
        fflush(0);
    }];
    UNNotificationAction *snooze = [UNNotificationAction
        actionWithIdentifier:@"snooze"
                       title:@"Snooze"
                     options:0];
    UNNotificationAction *remove = [UNNotificationAction
        actionWithIdentifier:@"delete"
                       title:@"Delete"
                     options:UNNotificationActionOptionDestructive];
    UNNotificationCategory *category = [UNNotificationCategory
        categoryWithIdentifier:@"lunch"
                       actions:[NSArray arrayWithObjects:snooze, remove, nil]
             intentIdentifiers:nil
                       options:0];
    [center setNotificationCategories:[NSSet setWithObject:category]];
    schedule("actionable", "Dinner", "Tap or hold");
}
@end

int main(int argc, char **argv)
{
    @autoreleasepool
    {
        return UIApplicationMain(argc, argv, nil, @"ActionsAppDelegate");
    }
}
