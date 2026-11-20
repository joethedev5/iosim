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
    (void)application;
    (void)session;
    (void)options;
    UISceneConfiguration *configuration = [[UISceneConfiguration alloc]
        initWithName:@"Default Configuration"
         sessionRole:UIWindowSceneSessionRoleApplication];
    configuration.delegateClass = [SceneDelegate class];
    return configuration;
}
@end

@interface CounterViewController : UIViewController
@property(nonatomic) int count;
@property(nonatomic, retain) UILabel *counterLabel;
@end

@implementation CounterViewController
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
    title.text = @"Counter";
    title.textColor = [UIColor whiteColor];
    title.font = [UIFont boldSystemFontOfSize:34];
    [self.view addSubview:title];

    self.counterLabel =
        [[UILabel alloc] initWithFrame:CGRectMake(24, 200, width - 48, 30)];
    self.counterLabel.text = @"Taps: 0";
    self.counterLabel.textColor =
        [UIColor colorWithRed:0.58 green:0.64 blue:0.72 alpha:1.0];
    self.counterLabel.font = [UIFont systemFontOfSize:17];
    [self.view addSubview:self.counterLabel];

    UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
    button.frame = CGRectMake(24, 440, width - 48, 56);
    button.backgroundColor = [UIColor systemBlueColor];
    button.layer.cornerRadius = 16;
    [button setTitle:@"Tap me" forState:UIControlStateNormal];
    [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [button addTarget:self
                  action:@selector(tap:)
        forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:button];
}

- (void)tap:(id)sender
{
    (void)sender;
    self.count = self.count + 1;
    if (self.count == 1)
        self.counterLabel.text = @"Taps: 1";
    else if (self.count == 2)
        self.counterLabel.text = @"Taps: 2";
    else
        self.counterLabel.text = @"Taps: 3+";
}
@end

@interface SceneDelegate : UIResponder <UIWindowSceneDelegate>
@property(nonatomic, retain) UIWindow *window;
@end

@implementation SceneDelegate
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
    CounterViewController *controller = [[CounterViewController alloc] init];
    self.window.rootViewController = controller;
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
