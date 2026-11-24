/* A single-line UILabel whose attributed string carries per-run fonts,
 * colors and an underline: Red (24 pt), Green (32 pt), Blue (24 pt). */
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

static int g_attributed_capture_ready;

@interface AttributedCapture : UIView
@end

@implementation AttributedCapture
- (void)drawRect:(CGRect)rect
{
    (void)rect;
    if (!g_attributed_capture_ready)
        return;
    const char *path = getenv("IOSIM_TEST_PNG");
    if (!path)
        return;
    iosim_fb_present(path);
    printf("[alabel] png written\n");
    fflush(0);
    exit(0);
}
@end

@interface AttributedController : UIViewController
@end

@implementation AttributedController
- (void)loadView
{
    UIView *root =
        [[UIView alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    root.backgroundColor = [UIColor blackColor];
    self.view = root;

    UILabel *label = [[UILabel alloc]
        initWithFrame:CGRectMake(20, 200, 360, 60)];
    label.backgroundColor = [UIColor clearColor];
    label.textAlignment = 1;

    NSMutableAttributedString *text = [[NSMutableAttributedString alloc]
        initWithString:@"RedGreenBlue"];
    [text addAttribute:NSForegroundColorAttributeName
                 value:[UIColor redColor]
                 range:NSMakeRange(0, 3)];
    [text addAttribute:NSFontAttributeName
                 value:[UIFont boldSystemFontOfSize:24]
                 range:NSMakeRange(0, 3)];
    [text addAttribute:NSForegroundColorAttributeName
                 value:[UIColor greenColor]
                 range:NSMakeRange(3, 5)];
    [text addAttribute:NSFontAttributeName
                 value:[UIFont boldSystemFontOfSize:32]
                 range:NSMakeRange(3, 5)];
    [text addAttribute:NSForegroundColorAttributeName
                 value:[UIColor blueColor]
                 range:NSMakeRange(8, 4)];
    [text addAttribute:NSFontAttributeName
                 value:[UIFont boldSystemFontOfSize:24]
                 range:NSMakeRange(8, 4)];
    [text addAttribute:NSUnderlineStyleAttributeName
                 value:[NSNumber numberWithInt:1]
                 range:NSMakeRange(8, 4)];
    label.attributedText = text;
    [root addSubview:label];

    AttributedCapture *capture =
        [[AttributedCapture alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    capture.backgroundColor = [UIColor clearColor];
    [root addSubview:capture];

    printf("[alabel] ready\n");
    fflush(0);
    dispatch_after(dispatch_time(0, 200 * 1000000LL),
                   dispatch_get_main_queue(), ^{
        printf("[alabel] done\n");
        fflush(0);
        g_attributed_capture_ready = 1;
        [label setNeedsDisplay];
        [capture setNeedsDisplay];
    });
}
@end

@interface AttributedSceneDelegate : UIResponder <UIWindowSceneDelegate>
@property(nonatomic, retain) UIWindow *window;
@end

@interface AttributedAppDelegate : UIResponder <UIApplicationDelegate>
@end

@implementation AttributedAppDelegate
- (UISceneConfiguration *)application:(UIApplication *)application
    configurationForConnectingSceneSession:(UISceneSession *)session
    options:(UISceneConnectionOptions *)connectionOptions
{
    (void)application; (void)session; (void)connectionOptions;
    UISceneConfiguration *configuration = [[UISceneConfiguration alloc]
        initWithName:@"Default Configuration"
         sessionRole:UIWindowSceneSessionRoleApplication];
    configuration.delegateClass = [AttributedSceneDelegate class];
    return configuration;
}
@end

@implementation AttributedSceneDelegate
- (void)scene:(UIScene *)scene
    willConnectToSession:(UISceneSession *)session
                 options:(UISceneConnectionOptions *)connectionOptions
{
    (void)session; (void)connectionOptions;
    self.window = [[UIWindow alloc] initWithWindowScene:(UIWindowScene *)scene];
    self.window.frame = [[UIScreen mainScreen] bounds];
    self.window.rootViewController = [[AttributedController alloc] init];
    [self.window makeKeyAndVisible];
}
@end

int main(int argc, char **argv)
{
    @autoreleasepool
    {
        return UIApplicationMain(argc, argv, nil, @"AttributedAppDelegate");
    }
}
