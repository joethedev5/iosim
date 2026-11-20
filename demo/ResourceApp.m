#if __has_include(<UIKit/UIKit.h>)
#import <UIKit/UIKit.h>
#else
#import "UIKitStub.h"
#endif

extern int printf(const char *fmt, ...);
extern int fflush(void *stream);
extern char *getenv(const char *name);

/* Bundle resources: UIImage imageNamed: and NSBundle pathForResource:
 * resolve against the .app directory the loader exports. */

@interface SceneDelegate : UIResponder <UIWindowSceneDelegate>
@property(nonatomic, retain) UIWindow *window;
@end

@interface AppDelegate : UIResponder <UIApplicationDelegate>
@end

@implementation AppDelegate
- (UISceneConfiguration *)application:(UIApplication *)application
    configurationForConnectingSceneSession:(UISceneSession *)session
    options:(UISceneConnectionOptions *)options
{
    (void)application; (void)session; (void)options;
    UISceneConfiguration *configuration = [[UISceneConfiguration alloc]
        initWithName:@"Default Configuration"
         sessionRole:UIWindowSceneSessionRoleApplication];
    configuration.delegateClass = [SceneDelegate class];
    return configuration;
}
@end

@interface ResourceViewController : UIViewController
@end

@implementation ResourceViewController
- (void)loadView
{
    UIView *view =
        [[UIView alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    view.backgroundColor =
        [UIColor colorWithRed:0.043 green:0.063 blue:0.125 alpha:1.0];
    self.view = view;
}
- (void)viewDidLoad
{
    [super viewDidLoad];

    const char *bundleDir = getenv("IOSIM_BUNDLE_DIR");
    printf("[res] bundle %s\n", bundleDir ? bundleDir : "(unset)");
    UIImage *dot = [UIImage imageNamed:@"dot"];
    printf("[res] image %d %d\n", dot ? [dot width] : -1,
           dot ? [dot height] : -1);
    if (dot)
    {
        UIImageView *imageView = [[UIImageView alloc] initWithImage:dot];
        imageView.frame = CGRectMake(100, 300, 100, 100);
        [self.view addSubview:imageView];
    }

    NSString *notePath =
        [[NSBundle mainBundle] pathForResource:@"note" ofType:@"txt"];
    NSString *note = nil;
    if (notePath)
    {
        NSData *data = [NSData dataWithContentsOfFile:notePath];
        if (data)
            note = [[NSString alloc] initWithData:data encoding:4];
    }
    printf("[res] note %s\n", note ? [note UTF8String] : "(missing)");
    printf("[res] app ready\n");
    fflush(0);
}
@end

@implementation SceneDelegate
- (void)scene:(UIScene *)scene
    willConnectToSession:(UISceneSession *)session
                 options:(UISceneConnectionOptions *)connectionOptions
{
    (void)session; (void)connectionOptions;
    self.window = [[UIWindow alloc] initWithWindowScene:(UIWindowScene *)scene];
    self.window.frame = [[UIScreen mainScreen] bounds];
    self.window.backgroundColor =
        [UIColor colorWithRed:0.043 green:0.063 blue:0.125 alpha:1.0];
    self.window.rootViewController = [[ResourceViewController alloc] init];
    [self.window makeKeyAndVisible];
}
@end

int main(int argc, char **argv)
{
    @autoreleasepool { return UIApplicationMain(argc, argv, nil, @"AppDelegate"); }
}
