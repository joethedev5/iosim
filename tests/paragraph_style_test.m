/* NSParagraphStyle alignment and line spacing in a two-line attributed
 * label with a red first line and a green second line. */
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

static int g_paragraph_capture_ready;

@interface ParagraphCapture : UIView
@end

@implementation ParagraphCapture
- (void)drawRect:(CGRect)rect
{
    (void)rect;
    if (!g_paragraph_capture_ready)
        return;
    const char *path = getenv("IOSIM_TEST_PNG");
    if (!path)
        return;
    iosim_fb_present(path);
    printf("[para] png written\n");
    fflush(0);
    exit(0);
}
@end

@interface ParagraphController : UIViewController
@end

@implementation ParagraphController
- (void)loadView
{
    UIView *root =
        [[UIView alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    root.backgroundColor = [UIColor blackColor];
    self.view = root;

    UILabel *label =
        [[UILabel alloc] initWithFrame:CGRectMake(20, 200, 360, 160)];
    label.backgroundColor = [UIColor clearColor];
    label.numberOfLines = 0;
    label.textAlignment = 0;

    NSMutableParagraphStyle *style =
        [[NSMutableParagraphStyle alloc] init];
    style.alignment = 1;
    style.lineSpacing = 10;

    NSMutableAttributedString *text = [[NSMutableAttributedString alloc]
        initWithString:@"Red\nGreen"];
    [text addAttribute:NSParagraphStyleAttributeName
                 value:style
                 range:NSMakeRange(0, 9)];
    [text addAttribute:NSForegroundColorAttributeName
                 value:[UIColor redColor]
                 range:NSMakeRange(0, 3)];
    [text addAttribute:NSForegroundColorAttributeName
                 value:[UIColor greenColor]
                 range:NSMakeRange(4, 5)];
    [text addAttribute:NSFontAttributeName
                 value:[UIFont boldSystemFontOfSize:20]
                 range:NSMakeRange(0, 9)];
    label.attributedText = text;
    [root addSubview:label];

    ParagraphCapture *capture =
        [[ParagraphCapture alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    capture.backgroundColor = [UIColor clearColor];
    [root addSubview:capture];

    printf("[para] ready\n");
    fflush(0);
    dispatch_after(dispatch_time(0, 200 * 1000000LL),
                   dispatch_get_main_queue(), ^{
        printf("[para] done\n");
        fflush(0);
        g_paragraph_capture_ready = 1;
        [label setNeedsDisplay];
        [capture setNeedsDisplay];
    });
}
@end

@interface ParagraphSceneDelegate : UIResponder <UIWindowSceneDelegate>
@property(nonatomic, retain) UIWindow *window;
@end

@interface ParagraphAppDelegate : UIResponder <UIApplicationDelegate>
@end

@implementation ParagraphAppDelegate
- (UISceneConfiguration *)application:(UIApplication *)application
    configurationForConnectingSceneSession:(UISceneSession *)session
    options:(UISceneConnectionOptions *)connectionOptions
{
    (void)application; (void)session; (void)connectionOptions;
    UISceneConfiguration *configuration = [[UISceneConfiguration alloc]
        initWithName:@"Default Configuration"
         sessionRole:UIWindowSceneSessionRoleApplication];
    configuration.delegateClass = [ParagraphSceneDelegate class];
    return configuration;
}
@end

@implementation ParagraphSceneDelegate
- (void)scene:(UIScene *)scene
    willConnectToSession:(UISceneSession *)session
                 options:(UISceneConnectionOptions *)connectionOptions
{
    (void)session; (void)connectionOptions;
    self.window = [[UIWindow alloc] initWithWindowScene:(UIWindowScene *)scene];
    self.window.frame = [[UIScreen mainScreen] bounds];
    self.window.rootViewController = [[ParagraphController alloc] init];
    [self.window makeKeyAndVisible];
}
@end

int main(int argc, char **argv)
{
    @autoreleasepool
    {
        return UIApplicationMain(argc, argv, nil, @"ParagraphAppDelegate");
    }
}
