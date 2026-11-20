#if __has_include(<UIKit/UIKit.h>)
#import <UIKit/UIKit.h>
#else
#import "UIKitStub.h"
#endif

/* Alert fixture: presents a two-action UIAlertController as soon as the
 * scene appears, so the alert can be captured without synthetic taps. */

@interface RootViewController : UIViewController
@property (nonatomic, retain) UILabel *statusLabel;
@property (nonatomic) BOOL presented;
@end

@implementation RootViewController
- (void)viewDidLoad
{
    [super viewDidLoad];
    self.view.backgroundColor =
        [UIColor colorWithRed:0.043 green:0.055 blue:0.102 alpha:1.0];
    CGRect bounds = self.view.bounds;
    double width = bounds.size.width - 48;

    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(24, 120, width, 30)];
    label.text = @"No choice yet";
    label.textColor = [UIColor whiteColor];
    label.font = [UIFont systemFontOfSize:18];
    [self.view addSubview:label];
    self.statusLabel = label;

    UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
    button.frame = CGRectMake(24, 190, width, 52);
    button.backgroundColor = [UIColor systemBlueColor];
    button.layer.cornerRadius = 14;
    [button setTitle:@"Delete project" forState:UIControlStateNormal];
    [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [button addTarget:self action:@selector(showAlert)
     forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:button];
}
- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    if (!self.presented)
    {
        self.presented = YES;
        [self showAlert];
    }
}
- (void)showAlert
{
    UIAlertController *alert = [UIAlertController
        alertControllerWithTitle:@"Delete project?"
                         message:@"This cannot be undone."
                  preferredStyle:UIAlertControllerStyleAlert];
    UILabel *status = self.statusLabel;
    [alert addAction:[UIAlertAction actionWithTitle:@"Cancel"
                                             style:UIAlertActionStyleCancel
                                           handler:^(UIAlertAction *action) {
        (void)action;
    }]];
    [alert addAction:[UIAlertAction actionWithTitle:@"Delete"
                                             style:UIAlertActionStyleDestructive
                                           handler:^(UIAlertAction *action) {
        (void)action;
        status.text = @"Deleted";
    }]];
    [self presentViewController:alert animated:YES completion:nil];
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
