#if __has_include(<UIKit/UIKit.h>)
#import <UIKit/UIKit.h>
#else
#import "UIKitStub.h"
#endif

/* Numeric-keyboard fixture: a UITextField with the number-pad trait takes
 * focus, so the runtime draws its numeric keypad over the lower half. */

@interface RootViewController : UIViewController
@property (nonatomic, retain) UITextField *field;
@end

@implementation RootViewController
- (void)viewDidLoad
{
    [super viewDidLoad];
    self.view.backgroundColor =
        [UIColor colorWithRed:0.043 green:0.055 blue:0.102 alpha:1.0];
    CGRect bounds = self.view.bounds;
    double width = bounds.size.width - 48;

    UILabel *eyebrow = [[UILabel alloc] initWithFrame:CGRectMake(24, 90, width, 16)];
    eyebrow.text = @"TEXT INPUT";
    eyebrow.font = [UIFont systemFontOfSize:12];
    eyebrow.textColor = [UIColor colorWithRed:0.36 green:0.78 blue:1.0
                                        alpha:1.0];
    [self.view addSubview:eyebrow];

    UILabel *title = [[UILabel alloc] initWithFrame:CGRectMake(24, 112, width, 40)];
    title.text = @"Say something.";
    title.font = [UIFont boldSystemFontOfSize:30];
    title.textColor = [UIColor whiteColor];
    [self.view addSubview:title];

    UILabel *body = [[UILabel alloc] initWithFrame:CGRectMake(24, 158, width, 44)];
    body.numberOfLines = 0;
    body.text = @"Taps focus the field; the keyboard is drawn by the runtime.";
    body.font = [UIFont systemFontOfSize:15];
    body.textColor = [UIColor colorWithRed:0.60 green:0.66 blue:0.76
                                     alpha:1.0];
    [self.view addSubview:body];

    UITextField *field = [[UITextField alloc]
        initWithFrame:CGRectMake(24, 226, width, 52)];
    field.backgroundColor = [UIColor colorWithRed:0.09 green:0.12 blue:0.21
                                            alpha:1.0];
    field.layer.cornerRadius = 12;
    field.textColor = [UIColor whiteColor];
    field.font = [UIFont systemFontOfSize:17];
    field.keyboardType = 4; field.placeholder = @"Type something";
    [self.view addSubview:field];
    self.field = field;
}
- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self.field becomeFirstResponder];
}
@end

@interface SceneDelegate : UIResponder <UIWindowSceneDelegate>
@property (nonatomic, retain) UIWindow *window;
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

@implementation SceneDelegate
- (void)scene:(UIScene *)scene
    willConnectToSession:(UISceneSession *)session
                 options:(UISceneConnectionOptions *)connectionOptions
{
    (void)session; (void)connectionOptions;
    CGRect screen = [[UIScreen mainScreen] bounds];
    self.window = [[UIWindow alloc] initWithWindowScene:(UIWindowScene *)scene];
    self.window.frame = screen;
    self.window.backgroundColor =
        [UIColor colorWithRed:0.043 green:0.055 blue:0.102 alpha:1.0];
    RootViewController *root = [[RootViewController alloc] init];
    self.window.rootViewController = root;
    [self.window makeKeyAndVisible];
}
@end

int main(int argc, char **argv)
{
    @autoreleasepool
    {
        return UIApplicationMain(argc, argv, nil, @"AppDelegate");
    }
}
