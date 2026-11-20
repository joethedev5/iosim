#if __has_include(<UIKit/UIKit.h>)
#import <UIKit/UIKit.h>
#else
#import "UIKitStub.h"
#endif

@interface DetailViewController : UIViewController
@end

@implementation DetailViewController
- (void)viewDidLoad
{
    [super viewDidLoad];
    self.title = @"Now Playing";
    CGRect bounds = self.view.bounds;
    UILabel *label = [[UILabel alloc]
        initWithFrame:CGRectMake(24, 24, bounds.size.width - 48, 32)];
    label.text = @"A pushed view controller";
    label.textColor = [UIColor whiteColor];
    label.font = [UIFont boldSystemFontOfSize:22];
    [self.view addSubview:label];

    UILabel *sub = [[UILabel alloc]
        initWithFrame:CGRectMake(24, 64, bounds.size.width - 48, 24)];
    sub.text = @"UINavigationController · UIStackView";
    sub.textColor = [UIColor colorWithRed:0.58 green:0.64 blue:0.72 alpha:1.0];
    sub.font = [UIFont systemFontOfSize:15];
    [self.view addSubview:sub];

    UIButton *back = [UIButton buttonWithType:UIButtonTypeSystem];
    back.frame = CGRectMake(24, 120, bounds.size.width - 48, 52);
    back.backgroundColor = [UIColor colorWithRed:0.10 green:0.14 blue:0.25
                                            alpha:1.0];
    back.layer.cornerRadius = 14;
    [back setTitle:@"Back to Library" forState:UIControlStateNormal];
    [back setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [back addTarget:self action:@selector(goBack)
        forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:back];
}
- (void)goBack { [self.navigationController popViewControllerAnimated:YES]; }
@end

@interface RootViewController : UIViewController
@end

@implementation RootViewController
- (void)viewDidLoad
{
    [super viewDidLoad];
    self.title = @"Library";
    CGRect bounds = self.view.bounds;
    double width = bounds.size.width - 48;

    UILabel *head = [[UILabel alloc] initWithFrame:CGRectMake(24, 20, width, 34)];
    head.text = @"Navigation and stacks";
    head.textColor = [UIColor whiteColor];
    head.font = [UIFont boldSystemFontOfSize:26];
    [self.view addSubview:head];

    UIStackView *vertical = [[UIStackView alloc]
        initWithFrame:CGRectMake(24, 76, width, 300)];
    vertical.axis = 1;
    vertical.spacing = 10;
    vertical.alignment = 0;

    UILabel *a = [[UILabel alloc] initWithFrame:CGRectZero];
    a.text = @"UIStackView lays out arranged subviews.";
    a.textColor = [UIColor colorWithRed:0.75 green:0.80 blue:0.90 alpha:1.0];
    a.font = [UIFont systemFontOfSize:15];
    [vertical addArrangedSubview:a];

    UIStackView *horizontal = [[UIStackView alloc]
        initWithFrame:CGRectMake(0, 0, width, 44)];
    horizontal.axis = 0;
    horizontal.spacing = 8;
    horizontal.distribution = 1;
    for (int i = 0; i < 3; i++)
    {
        UILabel *pill = [[UILabel alloc] initWithFrame:CGRectZero];
        pill.text = i == 0 ? @"One" : (i == 1 ? @"Two" : @"Three");
        pill.textAlignment = 1;
        pill.textColor = [UIColor whiteColor];
        pill.font = [UIFont boldSystemFontOfSize:15];
        pill.backgroundColor = [UIColor colorWithRed:0.10 + i * 0.08
                                                green:0.22 + i * 0.05
                                                blue:0.46 alpha:1.0];
        pill.layer.cornerRadius = 12;
        [horizontal addArrangedSubview:pill];
    }
    [vertical addArrangedSubview:horizontal];

    UIButton *open = [UIButton buttonWithType:UIButtonTypeSystem];
    open.frame = CGRectZero;
    [open setTitle:@"Open detail" forState:UIControlStateNormal];
    [open setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    open.backgroundColor = [UIColor systemBlueColor];
    open.layer.cornerRadius = 14;
    [open addTarget:self action:@selector(openDetail)
        forControlEvents:UIControlEventTouchUpInside];
    [vertical addArrangedSubview:open];

    [self.view addSubview:vertical];

    UILabel *note = [[UILabel alloc]
        initWithFrame:CGRectMake(24, 400, width, 22)];
    note.text = @"Frames are resolved by the stack before rendering.";
    note.textColor = [UIColor colorWithRed:0.39 green:0.45 blue:0.55 alpha:1.0];
    note.font = [UIFont systemFontOfSize:13];
    [self.view addSubview:note];
}
- (void)openDetail
{
    DetailViewController *detail = [[DetailViewController alloc] init];
    [self.navigationController pushViewController:detail animated:YES];
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
        [UIColor colorWithRed:0.035 green:0.047 blue:0.098 alpha:1.0];
    RootViewController *root = [[RootViewController alloc] init];
    UINavigationController *nav = [[UINavigationController alloc]
        initWithRootViewController:root];
    self.window.rootViewController = nav;
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
