/* A running app observes UIPasteboardChangedNotification when another
 * process (iosimctl pbcopy) rewrites the device pasteboard. */
#include "UIKitStub.h"

extern int printf(const char *fmt, ...);
extern int fflush(void *stream);
extern void exit(int status);

/* UIKitStub.h does not import the Foundation notification declarations. */
@interface NSNotificationCenter : NSObject
+ (id)defaultCenter;
- (id)addObserverForName:(id)name object:(id)object queue:(id)queue
              usingBlock:(void (^)(id notification))block;
@end

@interface PasteWatchController : UIViewController
@end

@implementation PasteWatchController
- (void)loadView
{
    UIView *root =
        [[UIView alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    root.backgroundColor =
        [UIColor colorWithRed:0.08 green:0.10 blue:0.16 alpha:1.0];
    self.view = root;
    [[NSNotificationCenter defaultCenter]
        addObserverForName:UIPasteboardChangedNotification
                    object:nil
                     queue:nil
                usingBlock:^(id note) {
        (void)note;
        id text = [[UIPasteboard generalPasteboard] string];
        printf("[pastewatch] changed %s\n",
               text ? [text UTF8String] : "(nil)");
        fflush(0);
        exit(0);
    }];
    /* Arm the watcher with the current changeCount before the test writes. */
    [[UIPasteboard generalPasteboard] changeCount];
    printf("[pastewatch] ready\n");
    fflush(0);
}
@end

@interface PasteWatchSceneDelegate : UIResponder <UIWindowSceneDelegate>
@property(nonatomic, retain) UIWindow *window;
@end

@interface PasteWatchAppDelegate : UIResponder <UIApplicationDelegate>
@end

@implementation PasteWatchAppDelegate
- (UISceneConfiguration *)application:(UIApplication *)application
    configurationForConnectingSceneSession:(UISceneSession *)session
    options:(UISceneConnectionOptions *)connectionOptions
{
    (void)application; (void)session; (void)connectionOptions;
    UISceneConfiguration *configuration = [[UISceneConfiguration alloc]
        initWithName:@"Default Configuration"
         sessionRole:UIWindowSceneSessionRoleApplication];
    configuration.delegateClass = [PasteWatchSceneDelegate class];
    return configuration;
}
@end

@implementation PasteWatchSceneDelegate
- (void)scene:(UIScene *)scene
    willConnectToSession:(UISceneSession *)session
                 options:(UISceneConnectionOptions *)connectionOptions
{
    (void)session; (void)connectionOptions;
    self.window = [[UIWindow alloc] initWithWindowScene:(UIWindowScene *)scene];
    self.window.frame = [[UIScreen mainScreen] bounds];
    self.window.rootViewController = [[PasteWatchController alloc] init];
    [self.window makeKeyAndVisible];
}
@end

int main(int argc, char **argv)
{
    @autoreleasepool
    {
        return UIApplicationMain(argc, argv, nil, @"PasteWatchAppDelegate");
    }
}
