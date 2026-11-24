/* UIGraphicsImageRenderer + drawViewHierarchyInRect: captures a rounded
 * view subtree into the image context, which is then displayed. */
#include "UIKitStub.h"

extern int printf(const char *fmt, ...);
extern int fflush(void *stream);
extern int iosim_fb_present(const char *path);
extern char *getenv(const char *name);
extern void exit(int status);

@interface HierarchyCapture : UIView
@end

@implementation HierarchyCapture
- (void)drawRect:(CGRect)rect
{
    (void)rect;
    const char *path = getenv("IOSIM_TEST_PNG");
    if (!path)
        return;
    iosim_fb_present(path);
    printf("[hd] png written\n");
    fflush(0);
    exit(0);
}
@end

@interface HierarchyController : UIViewController
@end

@implementation HierarchyController
- (void)loadView
{
    UIView *root = [[UIView alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    root.backgroundColor = [UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:1];
    self.view = root;
    CGRect screen = [[UIScreen mainScreen] bounds];

    UIView *source = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 100, 80)];
    source.backgroundColor =
        [UIColor colorWithRed:1.0 green:0.0 blue:0.0 alpha:1];
    source.layer.cornerRadius = 12;
    source.clipsToBounds = YES;
    UIView *chip = [[UIView alloc] initWithFrame:CGRectMake(20, 10, 30, 30)];
    chip.backgroundColor =
        [UIColor colorWithRed:1.0 green:0.9 blue:0.0 alpha:1];
    [source addSubview:chip];

    UIGraphicsImageRenderer *renderer =
        [[UIGraphicsImageRenderer alloc] initWithSize:CGSizeMake(100, 80)];
    UIImage *image = [renderer imageWithActions:
        ^(UIGraphicsImageRendererContext *context) {
        (void)context;
        BOOL drew = [source drawViewHierarchyInRect:CGRectMake(0, 0, 100, 80)
                                 afterScreenUpdates:YES];
        printf("[hd] drew %d\n", drew);
        fflush(0);
    }];

    UIImageView *shown = [[UIImageView alloc] initWithImage:image];
    shown.frame = CGRectMake(40, 100, 100, 80);
    [root addSubview:shown];

    HierarchyCapture *capture = [[HierarchyCapture alloc] initWithFrame:screen];
    capture.backgroundColor = [UIColor clearColor];
    [root addSubview:capture];
    self.view = root;
}
@end

@interface HierarchySceneDelegate : UIResponder <UIWindowSceneDelegate>
@property(nonatomic, retain) UIWindow *window;
@end

@interface HierarchyAppDelegate : UIResponder <UIApplicationDelegate>
@end

@implementation HierarchyAppDelegate
- (UISceneConfiguration *)application:(UIApplication *)application
    configurationForConnectingSceneSession:(UISceneSession *)session
    options:(UISceneConnectionOptions *)connectionOptions
{
    (void)application; (void)session; (void)connectionOptions;
    UISceneConfiguration *configuration = [[UISceneConfiguration alloc]
        initWithName:@"Default Configuration"
         sessionRole:UIWindowSceneSessionRoleApplication];
    configuration.delegateClass = [HierarchySceneDelegate class];
    return configuration;
}
@end

@implementation HierarchySceneDelegate
- (void)scene:(UIScene *)scene
    willConnectToSession:(UISceneSession *)session
                 options:(UISceneConnectionOptions *)connectionOptions
{
    (void)session; (void)connectionOptions;
    self.window = [[UIWindow alloc] initWithWindowScene:(UIWindowScene *)scene];
    self.window.frame = [[UIScreen mainScreen] bounds];
    self.window.rootViewController = [[HierarchyController alloc] init];
    [self.window makeKeyAndVisible];
}
@end

int main(int argc, char **argv)
{
    @autoreleasepool
    {
        return UIApplicationMain(argc, argv, nil, @"HierarchyAppDelegate");
    }
}
