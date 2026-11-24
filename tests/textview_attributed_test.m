/* UITextView renders an attributed string with per-run colors and an
 * underline while keeping the base font metrics for selection and caret. */
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

static int g_tv_capture_ready;

@interface TextViewCapture : UIView
@end

@implementation TextViewCapture
- (void)drawRect:(CGRect)rect
{
    (void)rect;
    if (!g_tv_capture_ready)
        return;
    const char *path = getenv("IOSIM_TEST_PNG");
    if (!path)
        return;
    iosim_fb_present(path);
    printf("[tvattr] png written\n");
    fflush(0);
    exit(0);
}
@end

@interface TextViewController : UIViewController
@end

@implementation TextViewController
- (void)loadView
{
    UIView *root =
        [[UIView alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    root.backgroundColor = [UIColor blackColor];
    self.view = root;

    UITextView *editor =
        [[UITextView alloc] initWithFrame:CGRectMake(20, 200, 360, 120)];
    editor.backgroundColor = [UIColor colorWithRed:0.05 green:0.05
                                              blue:0.08 alpha:1.0];
    [editor setFont:[UIFont systemFontOfSize:20]];
    [editor setTextColor:[UIColor whiteColor]];

    NSMutableAttributedString *text = [[NSMutableAttributedString alloc]
        initWithString:@"Red Blue Green"];
    [text addAttribute:NSForegroundColorAttributeName
                 value:[UIColor redColor]
                 range:NSMakeRange(0, 3)];
    [text addAttribute:NSForegroundColorAttributeName
                 value:[UIColor blueColor]
                 range:NSMakeRange(4, 4)];
    [text addAttribute:NSUnderlineStyleAttributeName
                 value:[NSNumber numberWithInt:1]
                 range:NSMakeRange(4, 4)];
    [text addAttribute:NSForegroundColorAttributeName
                 value:[UIColor greenColor]
                 range:NSMakeRange(9, 5)];
    editor.attributedText = text;
    [root addSubview:editor];

    TextViewCapture *capture =
        [[TextViewCapture alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    capture.backgroundColor = [UIColor clearColor];
    [root addSubview:capture];

    printf("[tvattr] ready\n");
    fflush(0);
    dispatch_after(dispatch_time(0, 200 * 1000000LL),
                   dispatch_get_main_queue(), ^{
        printf("[tvattr] done\n");
        fflush(0);
        g_tv_capture_ready = 1;
        [editor setNeedsDisplay];
        [capture setNeedsDisplay];
    });
}
@end

@interface TextViewSceneDelegate : UIResponder <UIWindowSceneDelegate>
@property(nonatomic, retain) UIWindow *window;
@end

@interface TextViewAppDelegate : UIResponder <UIApplicationDelegate>
@end

@implementation TextViewAppDelegate
- (UISceneConfiguration *)application:(UIApplication *)application
    configurationForConnectingSceneSession:(UISceneSession *)session
    options:(UISceneConnectionOptions *)connectionOptions
{
    (void)application; (void)session; (void)connectionOptions;
    UISceneConfiguration *configuration = [[UISceneConfiguration alloc]
        initWithName:@"Default Configuration"
         sessionRole:UIWindowSceneSessionRoleApplication];
    configuration.delegateClass = [TextViewSceneDelegate class];
    return configuration;
}
@end

@implementation TextViewSceneDelegate
- (void)scene:(UIScene *)scene
    willConnectToSession:(UISceneSession *)session
                 options:(UISceneConnectionOptions *)connectionOptions
{
    (void)session; (void)connectionOptions;
    self.window = [[UIWindow alloc] initWithWindowScene:(UIWindowScene *)scene];
    self.window.frame = [[UIScreen mainScreen] bounds];
    self.window.rootViewController = [[TextViewController alloc] init];
    [self.window makeKeyAndVisible];
}
@end

int main(int argc, char **argv)
{
    @autoreleasepool
    {
        return UIApplicationMain(argc, argv, nil, @"TextViewAppDelegate");
    }
}
