#if __has_include(<UIKit/UIKit.h>)
#import <UIKit/UIKit.h>
#else
#import "UIKitStub.h"
#endif

extern int printf(const char *fmt, ...);
extern int fflush(void *stream);

/* Navigation bar fixture: a right bar button item, a pushed detail
 * controller and the automatic back button that pops it. */

@interface DetailViewController : UIViewController
@end

@interface RootViewController : UIViewController
@end

@implementation RootViewController
- (void)loadView
{
    UIView *view =
        [[UIView alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    view.backgroundColor =
        [UIColor colorWithRed:0.043 green:0.063 blue:0.125 alpha:1.0];
    self.view = view;
}
- (void)viewDidLoad
{
    [super viewDidLoad];
    self.title = @"Library";
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc]
        initWithTitle:@"Add"
                style:UIBarButtonItemStylePlain
               target:self
               action:@selector(addTapped:)];
    UIButton *open = [UIButton buttonWithType:UIButtonTypeSystem];
    open.frame = CGRectMake(24, 200, 354, 52);
    open.backgroundColor =
        [UIColor colorWithRed:0.10 green:0.14 blue:0.25 alpha:1.0];
    open.layer.cornerRadius = 14;
    [open setTitle:@"Open Detail" forState:UIControlStateNormal];
    [open setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [open addTarget:self action:@selector(pushDetail)
        forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:open];
    printf("[nav] ready root\n");
    fflush(0);
}
- (void)viewWillAppear:(BOOL)animated
{
    (void)animated;
    printf("[nav] root appeared\n");
    fflush(0);
}
- (void)addTapped:(id)sender
{
    (void)sender;
    printf("[nav] add\n");
    fflush(0);
}
- (void)pushDetail
{
    [self.navigationController pushViewController:
        [[DetailViewController alloc] init] animated:YES];
}
@end

@implementation DetailViewController
- (void)loadView

{
    UIView *view =
        [[UIView alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    view.backgroundColor =
        [UIColor colorWithRed:0.043 green:0.063 blue:0.125 alpha:1.0];
    self.view = view;
}
- (void)viewDidLoad
{
    [super viewDidLoad];
    self.title = @"Detail";
    UILabel *label = [[UILabel alloc]
        initWithFrame:CGRectMake(24, 24, 354, 32)];
    label.text = @"Pushed detail";
    label.textColor = [UIColor whiteColor];
    label.font = [UIFont boldSystemFontOfSize:22];
    [self.view addSubview:label];
    printf("[nav] detail appeared\n");
    fflush(0);
}
@end

@interface NavBarSceneDelegate : UIResponder <UIWindowSceneDelegate>
@property(nonatomic, retain) UIWindow *window;
@end

@interface NavBarAppDelegate : UIResponder <UIApplicationDelegate>
@end

@implementation NavBarAppDelegate
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
    configuration.delegateClass = [NavBarSceneDelegate class];
    return configuration;
}
@end

@implementation NavBarSceneDelegate
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
    UINavigationController *nav = [[UINavigationController alloc]
        initWithRootViewController:[[RootViewController alloc] init]];
    self.window.rootViewController = nav;
    [self.window makeKeyAndVisible];
}
@end

int main(int argc, char **argv)
{
    @autoreleasepool
    {
        return UIApplicationMain(argc, argv, nil, @"NavBarAppDelegate");
    }
}
