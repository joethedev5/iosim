/* UILabel single-line fitting: adjustsFontSizeToFitWidth shrinks down to
 * minimumScaleFactor, and non-shrinking labels truncate with the default
 * tail ellipsis instead of overflowing. */
#include "UIKitStub.h"

extern int printf(const char *fmt, ...);
extern int fflush(void *stream);
extern int iosim_fb_present(const char *path);
extern char *getenv(const char *name);
extern void exit(int status);

@interface LabelFitCapture : UIView
@end

@implementation LabelFitCapture
- (void)drawRect:(CGRect)rect
{
    (void)rect;
    const char *path = getenv("IOSIM_TEST_PNG");
    if (!path)
        return;
    iosim_fb_present(path);
    printf("[lfit] png written\n");
    fflush(0);
    exit(0);
}
@end

static UILabel *fit_label(const char *text, CGRect frame, BOOL shrink,
                          double minScale)
{
    UILabel *label = [[UILabel alloc] initWithFrame:frame];
    label.text = [NSString stringWithUTF8String:text];
    label.font = [UIFont systemFontOfSize:40];
    label.textColor = [UIColor whiteColor];
    label.adjustsFontSizeToFitWidth = shrink;
    label.minimumScaleFactor = minScale;
    return label;
}

@interface LabelFitController : UIViewController
@end

@implementation LabelFitController
- (void)loadView
{
    UIView *root = [[UIView alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    root.backgroundColor = [UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:1];
    self.view = root;
    CGRect screen = [[UIScreen mainScreen] bounds];

    const char *word =
        "WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW";
    UILabel *shrunk = fit_label(word, CGRectMake(40, 80, 100, 60), YES, 0.5);
    [root addSubview:shrunk];
    UILabel *plain = fit_label(word, CGRectMake(40, 180, 100, 60), NO, 0.0);
    [root addSubview:plain];
    UILabel *limited = fit_label(word, CGRectMake(40, 280, 100, 60), YES, 0.9);
    [root addSubview:limited];

    UILabel *fresh = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 10, 10)];
    printf("[lfit] default %d %ld\n", [fresh adjustsFontSizeToFitWidth],
           [fresh lineBreakMode]);

    CGRect rb = [plain textRectForBounds:CGRectMake(0, 0, 100, 60)
                   limitedToNumberOfLines:1];
    CGRect ra = [shrunk textRectForBounds:CGRectMake(0, 0, 100, 60)
                    limitedToNumberOfLines:1];
    CGRect rc = [limited textRectForBounds:CGRectMake(0, 0, 100, 60)
                     limitedToNumberOfLines:1];
    printf("[lfit] bounds %d %d\n",
           ra.size.width > 0 && ra.size.width <= 120 &&
               rc.size.width > 0 && rc.size.width <= 120,
           ra.size.height > 0 && ra.size.height <= 60);
    printf("[lfit] shrink %d %d\n", ra.size.height < rb.size.height,
           rc.size.height > ra.size.height);
    printf("[lfit] rects %.1f %.1f %.1f %.1f %.1f %.1f\n", ra.size.width,
           ra.size.height, rb.size.width, rb.size.height, rc.size.width,
           rc.size.height);
    printf("[lfit] ratios %d %d\n",
           ra.size.height < rb.size.height * 0.6 &&
               ra.size.height > rb.size.height * 0.4,
           rc.size.height > rb.size.height * 0.85 &&
               rc.size.height < rb.size.height * 0.95);

    LabelFitCapture *capture = [[LabelFitCapture alloc] initWithFrame:screen];
    capture.backgroundColor = [UIColor clearColor];
    [root addSubview:capture];
    self.view = root;
}
@end

@interface LabelFitSceneDelegate : UIResponder <UIWindowSceneDelegate>
@property(nonatomic, retain) UIWindow *window;
@end

@interface LabelFitAppDelegate : UIResponder <UIApplicationDelegate>
@end

@implementation LabelFitAppDelegate
- (UISceneConfiguration *)application:(UIApplication *)application
    configurationForConnectingSceneSession:(UISceneSession *)session
    options:(UISceneConnectionOptions *)connectionOptions
{
    (void)application; (void)session; (void)connectionOptions;
    UISceneConfiguration *configuration = [[UISceneConfiguration alloc]
        initWithName:@"Default Configuration"
         sessionRole:UIWindowSceneSessionRoleApplication];
    configuration.delegateClass = [LabelFitSceneDelegate class];
    return configuration;
}
@end

@implementation LabelFitSceneDelegate
- (void)scene:(UIScene *)scene
    willConnectToSession:(UISceneSession *)session
                 options:(UISceneConnectionOptions *)connectionOptions
{
    (void)session; (void)connectionOptions;
    self.window = [[UIWindow alloc] initWithWindowScene:(UIWindowScene *)scene];
    self.window.frame = [[UIScreen mainScreen] bounds];
    self.window.rootViewController = [[LabelFitController alloc] init];
    [self.window makeKeyAndVisible];
}
@end

int main(int argc, char **argv)
{
    @autoreleasepool
    {
        return UIApplicationMain(argc, argv, nil, @"LabelFitAppDelegate");
    }
}
