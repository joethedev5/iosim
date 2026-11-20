#if __has_include(<UIKit/UIKit.h>)
#import <UIKit/UIKit.h>
#else
#import "UIKitStub.h"
#endif

extern int printf(const char *fmt, ...);
extern int fflush(void *stream);

/* Blur fixture: sixteen black/white stripes fill the screen, and a dark
 * UIVisualEffectView card with a rounded 28 pt corner sits over them. The
 * card captures and blurs its backdrop, so stripes outside stay sharp while
 * the same stripe positions inside become the blurred average. */

@interface BlurViewController : UIViewController
@end

@interface SceneDelegate : UIResponder <UIWindowSceneDelegate>
@property(nonatomic, retain) UIWindow *window;
@end

@interface AppDelegate : UIResponder <UIApplicationDelegate>
@end

@implementation BlurViewController
- (void)loadView
{
    UIView *view =
        [[UIView alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    view.backgroundColor =
        [UIColor colorWithRed:0.043 green:0.063 blue:0.125 alpha:1.0];

    for (int i = 0; i < 16; i++)
    {
        UIView *stripe = [[UIView alloc]
            initWithFrame:CGRectMake(i * 25.125, 100, 25.125, 600)];
        if (i % 2 == 0)
            stripe.backgroundColor = [UIColor whiteColor];
        else
            stripe.backgroundColor = [UIColor blackColor];
        [view addSubview:stripe];
    }

    UIVisualEffectView *card = [[UIVisualEffectView alloc]
        initWithEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleDark]];
    card.frame = CGRectMake(40, 250, 322, 200);
    card.layer.cornerRadius = 28;
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(60, 85, 202, 30)];
    label.text = @"Vibrancy";
    label.textColor = [UIColor whiteColor];
    label.textAlignment = 1;
    label.font = [UIFont systemFontOfSize:22];
    [card.contentView addSubview:label];
    [view addSubview:card];

    self.view = view;
}
- (void)viewDidLoad
{
    [super viewDidLoad];
    printf("[blur] ready stripes=16\n");
    fflush(0);
}
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
    self.window.rootViewController = [[BlurViewController alloc] init];
    [self.window makeKeyAndVisible];
}
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

int main(int argc, char **argv)
{
    @autoreleasepool
    {
        return UIApplicationMain(argc, argv, nil, @"AppDelegate");
    }
}
