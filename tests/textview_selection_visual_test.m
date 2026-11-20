/* UITextView selection rendering: a programmatic selectedRange is drawn as a
 * highlight behind the text; a capture view writes the frame to PNG. */
#include "UIKitStub.h"

extern int printf(const char *fmt, ...);
extern int fflush(void *stream);
extern int iosim_fb_present(const char *path);
extern char *getenv(const char *name);
extern void exit(int status);

@interface SelectionCaptureView : UIView
@end

@implementation SelectionCaptureView
- (void)drawRect:(CGRect)rect
{
    (void)rect;
    const char *path = getenv("IOSIM_TEST_PNG");
    if (!path)
        return;
    iosim_fb_present(path);
    printf("[sel] png written\n");
    fflush(0);
    exit(0);
}
@end

@interface SelectionController : UIViewController
@end

@implementation SelectionController
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
    editor.selectedRange = NSMakeRange(6, 5);
    [root addSubview:editor];
    printf("[sel] range %lu %lu\n", [editor selectedRange].location,
           [editor selectedRange].length);

    SelectionCaptureView *capture = [[SelectionCaptureView alloc]
        initWithFrame:[[UIScreen mainScreen] bounds]];
    capture.backgroundColor = [UIColor clearColor];
    [root addSubview:capture];
    self.view = root;
}
@end

@interface SelectionSceneDelegate : UIResponder <UIWindowSceneDelegate>
@property(nonatomic, retain) UIWindow *window;
@end

@interface SelectionAppDelegate : UIResponder <UIApplicationDelegate>
@end

@implementation SelectionAppDelegate
- (UISceneConfiguration *)application:(UIApplication *)application
    configurationForConnectingSceneSession:(UISceneSession *)session
    options:(UISceneConnectionOptions *)options
{
    (void)application; (void)session; (void)options;
    UISceneConfiguration *configuration = [[UISceneConfiguration alloc]
        initWithName:@"Default Configuration"
         sessionRole:UIWindowSceneSessionRoleApplication];
    configuration.delegateClass = [SelectionSceneDelegate class];
    return configuration;
}
@end

@implementation SelectionSceneDelegate
- (void)scene:(UIScene *)scene
    willConnectToSession:(UISceneSession *)session
                 options:(UISceneConnectionOptions *)connectionOptions
{
    (void)session; (void)connectionOptions;
    self.window = [[UIWindow alloc] initWithWindowScene:(UIWindowScene *)scene];
    self.window.frame = [[UIScreen mainScreen] bounds];
    self.window.rootViewController = [[SelectionController alloc] init];
    [self.window makeKeyAndVisible];
}
@end

int main(int argc, char **argv)
{
    @autoreleasepool
    {
        return UIApplicationMain(argc, argv, nil, @"SelectionAppDelegate");
    }
}
