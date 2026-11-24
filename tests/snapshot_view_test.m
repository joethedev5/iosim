/* snapshotViewAfterScreenUpdates: captures a view (including its rounded
 * clipping) so the snapshot keeps the old colors after the source changes. */
#include "UIKitStub.h"

extern int printf(const char *fmt, ...);
extern int fflush(void *stream);
extern int iosim_fb_present(const char *path);
extern char *getenv(const char *name);
extern void exit(int status);

@interface SnapshotCapture : UIView
@end

@implementation SnapshotCapture
- (void)drawRect:(CGRect)rect
{
    (void)rect;
    const char *path = getenv("IOSIM_TEST_PNG");
    if (!path)
        return;
    iosim_fb_present(path);
    printf("[snap] png written\n");
    fflush(0);
    exit(0);
}
@end

@interface SnapshotController : UIViewController
@end

@implementation SnapshotController
- (void)loadView
{
    UIView *root = [[UIView alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    root.backgroundColor = [UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:1];
    self.view = root;
    CGRect screen = [[UIScreen mainScreen] bounds];

    UIView *source = [[UIView alloc] initWithFrame:CGRectMake(40, 100, 100, 80)];
    source.backgroundColor =
        [UIColor colorWithRed:1.0 green:0.0 blue:0.0 alpha:1];
    source.layer.cornerRadius = 12;
    source.clipsToBounds = YES;
    UIView *chip = [[UIView alloc] initWithFrame:CGRectMake(20, 10, 30, 30)];
    chip.backgroundColor =
        [UIColor colorWithRed:1.0 green:0.9 blue:0.0 alpha:1];
    [source addSubview:chip];
    [root addSubview:source];

    UIView *snapshot = [source snapshotViewAfterScreenUpdates:NO];
    snapshot.frame = CGRectMake(200, 300, 100, 80);
    [root addSubview:snapshot];

    source.backgroundColor =
        [UIColor colorWithRed:0.0 green:0.0 blue:1.0 alpha:1];
    chip.backgroundColor =
        [UIColor colorWithRed:0.0 green:1.0 blue:0.0 alpha:1];

    printf("[snap] size %.1f %.1f\n", snapshot.frame.size.width,
           snapshot.frame.size.height);

    SnapshotCapture *capture = [[SnapshotCapture alloc] initWithFrame:screen];
    capture.backgroundColor = [UIColor clearColor];
    [root addSubview:capture];
    self.view = root;
}
@end

@interface SnapshotSceneDelegate : UIResponder <UIWindowSceneDelegate>
@property(nonatomic, retain) UIWindow *window;
@end

@interface SnapshotAppDelegate : UIResponder <UIApplicationDelegate>
@end

@implementation SnapshotAppDelegate
- (UISceneConfiguration *)application:(UIApplication *)application
    configurationForConnectingSceneSession:(UISceneSession *)session
    options:(UISceneConnectionOptions *)connectionOptions
{
    (void)application; (void)session; (void)connectionOptions;
    UISceneConfiguration *configuration = [[UISceneConfiguration alloc]
        initWithName:@"Default Configuration"
         sessionRole:UIWindowSceneSessionRoleApplication];
    configuration.delegateClass = [SnapshotSceneDelegate class];
    return configuration;
}
@end

@implementation SnapshotSceneDelegate
- (void)scene:(UIScene *)scene
    willConnectToSession:(UISceneSession *)session
                 options:(UISceneConnectionOptions *)connectionOptions
{
    (void)session; (void)connectionOptions;
    self.window = [[UIWindow alloc] initWithWindowScene:(UIWindowScene *)scene];
    self.window.frame = [[UIScreen mainScreen] bounds];
    self.window.rootViewController = [[SnapshotController alloc] init];
    [self.window makeKeyAndVisible];
}
@end

int main(int argc, char **argv)
{
    @autoreleasepool
    {
        return UIApplicationMain(argc, argv, nil, @"SnapshotAppDelegate");
    }
}
