#if __has_include(<UIKit/UIKit.h>)
#import <UIKit/UIKit.h>
#else
#import "UIKitStub.h"
#endif

extern int printf(const char *fmt, ...);
extern int fflush(void *stream);

/* Long-press fixture: reports the gesture states with the press location. */

@interface PressViewController : UIViewController
@end

@implementation PressViewController
- (void)loadView
{
    UIView *view =
        [[UIView alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    view.backgroundColor =
        [UIColor colorWithRed:0.043 green:0.063 blue:0.125 alpha:1.0];

    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(40, 200, 300, 40)];
    label.text = @"Hold anywhere";
    label.textColor = [UIColor whiteColor];
    label.font = [UIFont systemFontOfSize:22];
    [view addSubview:label];

    UILongPressGestureRecognizer *press = [[UILongPressGestureRecognizer alloc]
        initWithTarget:self action:@selector(pressed:)];
    press.minimumPressDuration = 0.4;
    press.allowableMovement = 10.0;
    [view addGestureRecognizer:press];
    self.view = view;
}
- (void)viewDidLoad
{
    [super viewDidLoad];
    printf("[press] ready\n");
    fflush(0);
}
- (void)pressed:(UILongPressGestureRecognizer *)gesture
{
    const char *state = "other";
    switch ([gesture state])
    {
    case UIGestureRecognizerStateBegan: state = "began"; break;
    case UIGestureRecognizerStateChanged: state = "changed"; break;
    case UIGestureRecognizerStateEnded: state = "ended"; break;
    case UIGestureRecognizerStateFailed: state = "failed"; break;
    }
    CGPoint point = [gesture locationInView:self.view];
    printf("[press] %s %.0f %.0f\n", state, point.x, point.y);
    fflush(0);
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
    options:(UISceneConnectionOptions *)options
{
    (void)application;
    (void)session;
    (void)options;
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
    (void)session;
    (void)connectionOptions;
    self.window = [[UIWindow alloc] initWithWindowScene:(UIWindowScene *)scene];
    self.window.frame = [[UIScreen mainScreen] bounds];
    self.window.backgroundColor =
        [UIColor colorWithRed:0.043 green:0.063 blue:0.125 alpha:1.0];
    self.window.rootViewController = [[PressViewController alloc] init];
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
