#if __has_include(<UIKit/UIKit.h>)
#import <UIKit/UIKit.h>
#else
#import "UIKitStub.h"
#endif

/* Controls fixture: one of every native control at a fixed frame, so the
 * runtime's control rendering can be measured against the simulator's. */

@interface RootViewController : UIViewController
@end

@implementation RootViewController
- (void)viewDidLoad
{
    [super viewDidLoad];
    self.view.backgroundColor =
        [UIColor colorWithRed:0.043 green:0.055 blue:0.102 alpha:1.0];
    double width = self.view.bounds.size.width - 48;

    UILabel *eyebrow = [[UILabel alloc] initWithFrame:CGRectMake(24, 84, width, 16)];
    eyebrow.text = @"CONTROLS";
    eyebrow.font = [UIFont systemFontOfSize:12];
    eyebrow.textColor = [UIColor colorWithRed:0.36 green:0.78 blue:1.0
                                        alpha:1.0];
    [self.view addSubview:eyebrow];

    UILabel *title = [[UILabel alloc] initWithFrame:CGRectMake(24, 106, width, 40)];
    title.text = @"Standard controls.";
    title.font = [UIFont boldSystemFontOfSize:30];
    title.textColor = [UIColor whiteColor];
    [self.view addSubview:title];

    UISwitch *on = [[UISwitch alloc] initWithFrame:CGRectMake(24, 168, 51, 31)];
    [on setOn:YES animated:NO];
    [self.view addSubview:on];

    UISwitch *off = [[UISwitch alloc] initWithFrame:CGRectMake(92, 168, 51, 31)];
    [off setOn:NO animated:NO];
    [self.view addSubview:off];

    UISlider *slider = [[UISlider alloc] initWithFrame:CGRectMake(24, 222, width, 31)];
    [slider setValue:0.64 animated:NO];
    [self.view addSubview:slider];

    UISegmentedControl *segmented = [[UISegmentedControl alloc] initWithItems:
        [NSArray arrayWithObjects:(const id[]){@"Day", @"Week", @"Month"} count:3]];
    segmented.frame = CGRectMake(24, 276, width, 32);
    segmented.selectedSegmentIndex = 1;
    [self.view addSubview:segmented];

    UIProgressView *progress = [[UIProgressView alloc]
        initWithFrame:CGRectMake(24, 332, width, 8)];
    [progress setProgress:0.35 animated:NO];
    [self.view addSubview:progress];

    UIPageControl *pages = [[UIPageControl alloc]
        initWithFrame:CGRectMake(24, 352, width, 26)];
    [pages setNumberOfPages:5];
    [pages setCurrentPage:2];
    [self.view addSubview:pages];

    UIActivityIndicatorView *spinner = [[UIActivityIndicatorView alloc]
        initWithActivityIndicatorStyle:2];
    spinner.frame = CGRectMake(24, 404, 37, 37);
    [spinner startAnimating];
    [self.view addSubview:spinner];
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
