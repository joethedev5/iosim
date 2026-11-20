#if __has_include(<UIKit/UIKit.h>)
#import <UIKit/UIKit.h>
#else
#import "UIKitStub.h"
#endif

@class SceneDelegate;

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

@interface SceneDelegate : UIResponder <UIWindowSceneDelegate>
@property(nonatomic, retain) UIWindow *window;
@end

@interface AnimationViewController : UIViewController
@property(nonatomic, retain) UIView *box;
@end

@implementation AnimationViewController
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
    CGRect screen = [[UIScreen mainScreen] bounds];
    double width = screen.size.width;
    UILabel *title =
        [[UILabel alloc] initWithFrame:CGRectMake(24, 120, width - 48, 48)];
    title.text = @"Core Animation";
    title.textColor = [UIColor whiteColor];
    title.font = [UIFont boldSystemFontOfSize:34];
    [self.view addSubview:title];

    self.box = [[UIView alloc] initWithFrame:CGRectMake(24, 300, width - 48, 120)];
    self.box.backgroundColor = [UIColor systemBlueColor];
    self.box.layer.cornerRadius = 22;
    [self.view addSubview:self.box];

    UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
    button.frame = CGRectMake(24, 600, width - 48, 56);
    button.backgroundColor =
        [UIColor colorWithRed:0.106 green:0.141 blue:0.251 alpha:1.0];
    button.layer.cornerRadius = 16;
    [button setTitle:@"Animate" forState:UIControlStateNormal];
    [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [button addTarget:self action:@selector(animate:)
        forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:button];
}
- (void)animate:(id)sender
{
    (void)sender;
    [UIView animateWithDuration:1.0 animations:^{
        self.box.alpha = 0.15;
        self.box.frame = CGRectMake(24, 470, 354, 120);
    }];
}
@end

@implementation SceneDelegate
- (void)scene:(UIScene *)scene
    willConnectToSession:(UISceneSession *)session
                 options:(UISceneConnectionOptions *)connectionOptions
{
    (void)session; (void)connectionOptions;
    self.window = [[UIWindow alloc] initWithWindowScene:(UIWindowScene *)scene];
    self.window.frame = [[UIScreen mainScreen] bounds];
    self.window.backgroundColor =
        [UIColor colorWithRed:0.043 green:0.063 blue:0.125 alpha:1.0];
    self.window.rootViewController = [[AnimationViewController alloc] init];
    [self.window makeKeyAndVisible];
}
@end

int main(int argc, char **argv)
{
    @autoreleasepool { return UIApplicationMain(argc, argv, nil, @"AppDelegate"); }
}
