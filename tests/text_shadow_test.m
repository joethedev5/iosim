/* UILabel text shadows: a plain label with a red offset shadow and an
 * attributed label whose NSShadow run carries a blurred, left-shifted blue
 * shadow. */
#include "UIKitStub.h"

extern int printf(const char *fmt, ...);
extern int fflush(void *stream);
extern void exit(int status);
extern int iosim_fb_present(const char *path);
extern char *getenv(const char *name);
extern unsigned long long dispatch_time(unsigned long long when,
                                        long long delta);
extern void dispatch_after(unsigned long long when, void *queue,
                           void (^block)(void));
extern void *dispatch_get_main_queue(void);

static int g_shadow_capture_ready;

@interface ShadowCapture : UIView
@end

@implementation ShadowCapture
- (void)drawRect:(CGRect)rect
{
    (void)rect;
    if (!g_shadow_capture_ready)
        return;
    const char *path = getenv("IOSIM_TEST_PNG");
    if (!path)
        return;
    iosim_fb_present(path);
    printf("[shadow] png written\n");
    fflush(0);
    exit(0);
}
@end

@interface ShadowController : UIViewController
@end

@implementation ShadowController
- (void)loadView
{
    UIView *root =
        [[UIView alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    root.backgroundColor = [UIColor blackColor];
    self.view = root;

    UILabel *plain = [[UILabel alloc]
        initWithFrame:CGRectMake(20, 160, 362, 80)];
    plain.backgroundColor = [UIColor clearColor];
    plain.textAlignment = 1;
    plain.text = @"SHADOW";
    plain.font = [UIFont boldSystemFontOfSize:40];
    plain.textColor = [UIColor whiteColor];
    plain.shadowColor = [UIColor redColor];
    plain.shadowOffset = CGSizeMake(3, 3);
    [root addSubview:plain];

    UILabel *attributed = [[UILabel alloc]
        initWithFrame:CGRectMake(20, 320, 362, 80)];
    attributed.backgroundColor = [UIColor clearColor];
    attributed.textAlignment = 1;
    attributed.textColor = [UIColor whiteColor];
    NSMutableAttributedString *text = [[NSMutableAttributedString alloc]
        initWithString:@"SHADOW"];
    [text addAttribute:NSFontAttributeName
                 value:[UIFont boldSystemFontOfSize:40]
                 range:NSMakeRange(0, 6)];
    NSShadow *shadow = [[NSShadow alloc] init];
    shadow.shadowOffset = CGSizeMake(-3, 3);
    shadow.shadowBlurRadius = 2;
    shadow.shadowColor = [UIColor blueColor];
    [text addAttribute:NSShadowAttributeName
                 value:shadow
                 range:NSMakeRange(0, 6)];
    attributed.attributedText = text;
    [root addSubview:attributed];

    ShadowCapture *capture = [[ShadowCapture alloc]
        initWithFrame:[[UIScreen mainScreen] bounds]];
    capture.backgroundColor = [UIColor clearColor];
    [root addSubview:capture];

    printf("[shadow] ready\n");
    fflush(0);
    dispatch_after(dispatch_time(0, 200 * 1000000LL),
                   dispatch_get_main_queue(), ^{
        printf("[shadow] done\n");
        fflush(0);
        g_shadow_capture_ready = 1;
        [plain setNeedsDisplay];
        [attributed setNeedsDisplay];
        [capture setNeedsDisplay];
    });
}
@end

@interface ShadowSceneDelegate : UIResponder <UIWindowSceneDelegate>
@property(nonatomic, retain) UIWindow *window;
@end

@interface ShadowAppDelegate : UIResponder <UIApplicationDelegate>
@end

@implementation ShadowAppDelegate
- (UISceneConfiguration *)application:(UIApplication *)application
    configurationForConnectingSceneSession:(UISceneSession *)session
    options:(UISceneConnectionOptions *)connectionOptions
{
    (void)application; (void)session; (void)connectionOptions;
    UISceneConfiguration *configuration = [[UISceneConfiguration alloc]
        initWithName:@"Default Configuration"
         sessionRole:UIWindowSceneSessionRoleApplication];
    configuration.delegateClass = [ShadowSceneDelegate class];
    return configuration;
}
@end

@implementation ShadowSceneDelegate
- (void)scene:(UIScene *)scene
    willConnectToSession:(UISceneSession *)session
                 options:(UISceneConnectionOptions *)connectionOptions
{
    (void)session; (void)connectionOptions;
    self.window = [[UIWindow alloc] initWithWindowScene:(UIWindowScene *)scene];
    self.window.frame = [[UIScreen mainScreen] bounds];
    self.window.rootViewController = [[ShadowController alloc] init];
    [self.window makeKeyAndVisible];
}
@end

int main(int argc, char **argv)
{
    @autoreleasepool
    {
        return UIApplicationMain(argc, argv, nil, @"ShadowAppDelegate");
    }
}
