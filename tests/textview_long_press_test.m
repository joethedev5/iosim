/* UITextView long press: a held touch promotes to a word selection after
 * 0.5 s through the UI loop tick. A dispatch_after block checks the range,
 * captures the frame and exits. */
#include "UIKitStub.h"

extern int printf(const char *fmt, ...);
extern int fflush(void *stream);
extern int iosim_fb_present(const char *path);
extern char *getenv(const char *name);
extern void exit(int status);
extern int iosim_fb_font_text_width(const char *text, int style,
                                    double size_pt, double scale);
extern unsigned long long dispatch_time(unsigned long long when,
                                        long long delta);
extern void dispatch_after(unsigned long long when, void *queue,
                           void (^block)(void));
extern void *dispatch_get_main_queue(void);

@interface PressController : UIViewController
@end

@implementation PressController
- (void)loadView
{
    UIView *root =
        [[UIView alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    root.backgroundColor =
        [UIColor colorWithRed:0.043 green:0.055 blue:0.102 alpha:1.0];

    UITextView *editor = [[UITextView alloc]
        initWithFrame:CGRectMake(24, 100, 320, 160)];
    editor.backgroundColor =
        [UIColor colorWithRed:0.09 green:0.12 blue:0.21 alpha:1.0];
    editor.textColor = [UIColor whiteColor];
    editor.font = [UIFont systemFontOfSize:24];
    editor.text = @"hello world";
    [root addSubview:editor];

    double scale = [[UIScreen mainScreen] scale];
    if (scale <= 0)
        scale = 1.0;
    double tap_x = 24.0 + 12.0 +
        iosim_fb_font_text_width("hello w", 0, 24.0, scale) / scale + 2.0;
    UITouch *touch = [[UITouch alloc] init];
    touch->_location = CGPointMake(tap_x, 120.0);
    touch->_previousLocation = touch->_location;
    touch->_phase = UITouchPhaseBegan;
    [editor touchesBegan:[NSSet setWithObject:touch] withEvent:nil];

    dispatch_after(dispatch_time(0, 900 * 1000000LL),
                   dispatch_get_main_queue(), ^{
        NSRange range = [editor selectedRange];
        printf("[press] long %d range %lu %lu\n",
               range.location == 6 && range.length == 5, range.location,
               range.length);
        const char *path = getenv("IOSIM_TEST_PNG");
        if (path)
            iosim_fb_present(path);
        printf("[press] png written\n");
        fflush(0);
        exit(0);
    });

    self.view = root;
}
@end

@interface PressSceneDelegate : UIResponder <UIWindowSceneDelegate>
@property(nonatomic, retain) UIWindow *window;
@end

@interface PressAppDelegate : UIResponder <UIApplicationDelegate>
@end

@implementation PressAppDelegate
- (UISceneConfiguration *)application:(UIApplication *)application
    configurationForConnectingSceneSession:(UISceneSession *)session
    options:(UISceneConnectionOptions *)connectionOptions
{
    (void)application; (void)session; (void)connectionOptions;
    UISceneConfiguration *configuration = [[UISceneConfiguration alloc]
        initWithName:@"Default Configuration"
         sessionRole:UIWindowSceneSessionRoleApplication];
    configuration.delegateClass = [PressSceneDelegate class];
    return configuration;
}
@end

@implementation PressSceneDelegate
- (void)scene:(UIScene *)scene
    willConnectToSession:(UISceneSession *)session
                 options:(UISceneConnectionOptions *)connectionOptions
{
    (void)session; (void)connectionOptions;
    self.window = [[UIWindow alloc] initWithWindowScene:(UIWindowScene *)scene];
    self.window.frame = [[UIScreen mainScreen] bounds];
    self.window.rootViewController = [[PressController alloc] init];
    [self.window makeKeyAndVisible];
}
@end

int main(int argc, char **argv)
{
    @autoreleasepool
    {
        return UIApplicationMain(argc, argv, nil, @"PressAppDelegate");
    }
}
