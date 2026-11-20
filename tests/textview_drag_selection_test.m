/* UITextView drag selection: synthetic touches extend the selection from the
 * initial tap index, and a non-empty selection renders handle stems and
 * knobs at both ends. The caret is dropped before capture so only handles
 * contribute the handle-blue color. */
#include "UIKitStub.h"

extern int printf(const char *fmt, ...);
extern int fflush(void *stream);
extern int iosim_fb_present(const char *path);
extern char *getenv(const char *name);
extern void exit(int status);

@interface DragCaptureView : UIView
@end

@implementation DragCaptureView
- (void)drawRect:(CGRect)rect
{
    (void)rect;
    const char *path = getenv("IOSIM_TEST_PNG");
    if (!path)
        return;
    iosim_fb_present(path);
    printf("[drag] png written\n");
    fflush(0);
    exit(0);
}
@end

@interface DragController : UIViewController
@end

@implementation DragController
- (NSRange)dragEditor:(UITextView *)editor from:(CGPoint)from
                   to:(CGPoint)to
{
    UITouch *touch = [[UITouch alloc] init];
    touch->_location = from;
    touch->_previousLocation = from;
    touch->_phase = UITouchPhaseBegan;
    [editor touchesBegan:[NSSet setWithObject:touch] withEvent:nil];
    touch->_previousLocation = from;
    touch->_location = to;
    touch->_phase = UITouchPhaseMoved;
    [editor touchesMoved:[NSSet setWithObject:touch] withEvent:nil];
    touch->_phase = UITouchPhaseEnded;
    [editor touchesEnded:[NSSet setWithObject:touch] withEvent:nil];
    return [editor selectedRange];
}
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

    NSRange full = [self dragEditor:editor from:CGPointMake(30, 120)
                                 to:CGPointMake(330, 120)];
    printf("[drag] full %lu %lu\n", full.location, full.length);
    NSRange partial = [self dragEditor:editor from:CGPointMake(330, 120)
                                    to:CGPointMake(150, 120)];
    printf("[drag] partial %d\n",
           partial.length > 0 && partial.length < 11);

    [editor setSelectedRange:NSMakeRange(0, 11)];
    [editor resignFirstResponder];

    DragCaptureView *capture =
        [[DragCaptureView alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    capture.backgroundColor = [UIColor clearColor];
    [root addSubview:capture];
    self.view = root;
}
@end

@interface DragSceneDelegate : UIResponder <UIWindowSceneDelegate>
@property(nonatomic, retain) UIWindow *window;
@end

@interface DragAppDelegate : UIResponder <UIApplicationDelegate>
@end

@implementation DragAppDelegate
- (UISceneConfiguration *)application:(UIApplication *)application
    configurationForConnectingSceneSession:(UISceneSession *)session
    options:(UISceneConnectionOptions *)options
{
    (void)application; (void)session; (void)options;
    UISceneConfiguration *configuration = [[UISceneConfiguration alloc]
        initWithName:@"Default Configuration"
         sessionRole:UIWindowSceneSessionRoleApplication];
    configuration.delegateClass = [DragSceneDelegate class];
    return configuration;
}
@end

@implementation DragSceneDelegate
- (void)scene:(UIScene *)scene
    willConnectToSession:(UISceneSession *)session
                 options:(UISceneConnectionOptions *)connectionOptions
{
    (void)session; (void)connectionOptions;
    self.window = [[UIWindow alloc] initWithWindowScene:(UIWindowScene *)scene];
    self.window.frame = [[UIScreen mainScreen] bounds];
    self.window.rootViewController = [[DragController alloc] init];
    [self.window makeKeyAndVisible];
}
@end

int main(int argc, char **argv)
{
    @autoreleasepool
    {
        return UIApplicationMain(argc, argv, nil, @"DragAppDelegate");
    }
}
