#if __has_include(<UIKit/UIKit.h>)
#import <UIKit/UIKit.h>
#else
#import "UIKitStub.h"
#endif

/* A fixture that uses only Auto Layout for geometry: anchor constraints
 * against a superview, the safe-area guide, sibling edges and intrinsic
 * content sizes, plus a multiline label whose height follows its width. */

@interface RootViewController : UIViewController
@end

@implementation RootViewController
- (void)viewDidLoad
{
    [super viewDidLoad];
    self.view.backgroundColor =
        [UIColor colorWithRed:0.043 green:0.055 blue:0.102 alpha:1.0];
    UILayoutGuide *safe = self.view.safeAreaLayoutGuide;

    UILabel *eyebrow = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 0, 0)];
    eyebrow.text = @"AUTO LAYOUT";
    eyebrow.font = [UIFont systemFontOfSize:12];
    eyebrow.textColor = [UIColor colorWithRed:0.36 green:0.78 blue:1.0
                                         alpha:1.0];
    eyebrow.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:eyebrow];

    UILabel *title = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 0, 0)];
    title.text = @"Constraints, solved.";
    title.font = [UIFont boldSystemFontOfSize:30];
    title.textColor = [UIColor whiteColor];
    title.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:title];

    UILabel *body = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 0, 0)];
    body.numberOfLines = 0;
    body.text = @"Anchors pin every view: leading, trailing, top and bottom. "
                @"The engine solves the system, then wraps this paragraph "
                @"inside the width it was given.";
    body.font = [UIFont systemFontOfSize:16];
    body.textColor = [UIColor colorWithRed:0.60 green:0.66 blue:0.76
                                      alpha:1.0];
    body.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:body];

    UIView *card = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 0, 0)];
    card.backgroundColor = [UIColor colorWithRed:0.076 green:0.106 blue:0.184
                                            alpha:1.0];
    card.layer.cornerRadius = 18;
    card.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:card];

    UIView *badge = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 0, 0)];
    badge.backgroundColor = [UIColor systemBlueColor];
    badge.layer.cornerRadius = 14;
    badge.translatesAutoresizingMaskIntoConstraints = NO;
    [card addSubview:badge];

    UILabel *cardTitle = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 0, 0)];
    cardTitle.text = @"Auto Layout";
    cardTitle.font = [UIFont boldSystemFontOfSize:18];
    cardTitle.textColor = [UIColor whiteColor];
    cardTitle.translatesAutoresizingMaskIntoConstraints = NO;
    [card addSubview:cardTitle];

    UILabel *cardSub = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 0, 0)];
    cardSub.text = @"NSLayoutConstraint \xc2\xb7 NSLayoutAnchor";
    cardSub.font = [UIFont systemFontOfSize:13];
    cardSub.textColor = [UIColor colorWithRed:0.55 green:0.61 blue:0.71
                                        alpha:1.0];
    cardSub.translatesAutoresizingMaskIntoConstraints = NO;
    [card addSubview:cardSub];

    UIView *divider = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 0, 0)];
    divider.backgroundColor = [UIColor colorWithRed:0.16 green:0.20 blue:0.29
                                               alpha:1.0];
    divider.translatesAutoresizingMaskIntoConstraints = NO;
    [card addSubview:divider];

    UILabel *foot = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 0, 0)];
    foot.text = @"Solved in 240 relaxation passes";
    foot.font = [UIFont systemFontOfSize:12];
    foot.textColor = [UIColor colorWithRed:0.45 green:0.51 blue:0.61
                                     alpha:1.0];
    foot.translatesAutoresizingMaskIntoConstraints = NO;
    [card addSubview:foot];

    UILabel *priority = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 0, 0)];
    priority.text = @"1000";
    priority.font = [UIFont boldSystemFontOfSize:12];
    priority.textAlignment = 1;
    priority.textColor = [UIColor whiteColor];
    priority.backgroundColor = [UIColor colorWithRed:0.10 green:0.30 blue:0.62
                                                alpha:1.0];
    priority.layer.cornerRadius = 6;
    priority.translatesAutoresizingMaskIntoConstraints = NO;
    [card addSubview:priority];

    UIButton *run = [UIButton buttonWithType:UIButtonTypeSystem];
    [run setTitle:@"Run layout pass" forState:UIControlStateNormal];
    [run setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    run.titleLabel.font = [UIFont systemFontOfSize:17];
    run.backgroundColor = [UIColor systemBlueColor];
    run.layer.cornerRadius = 14;
    run.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:run];

    UILabel *caption = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 0, 0)];
    caption.text = @"safeAreaLayoutGuide \xc2\xb7 priority 750";
    caption.font = [UIFont systemFontOfSize:12];
    caption.textAlignment = 1;
    caption.textColor = [UIColor colorWithRed:0.39 green:0.45 blue:0.55
                                        alpha:1.0];
    caption.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:caption];

    [NSLayoutConstraint activateConstraints:@[
        [eyebrow.leadingAnchor constraintEqualToAnchor:safe.leadingAnchor
                                              constant:24],
        [eyebrow.topAnchor constraintEqualToAnchor:safe.topAnchor
                                          constant:24],

        [title.leadingAnchor constraintEqualToAnchor:safe.leadingAnchor
                                            constant:24],
        [title.trailingAnchor constraintEqualToAnchor:safe.trailingAnchor
                                             constant:-24],
        [title.topAnchor constraintEqualToAnchor:eyebrow.bottomAnchor
                                        constant:10],

        [body.leadingAnchor constraintEqualToAnchor:safe.leadingAnchor
                                           constant:24],
        [body.trailingAnchor constraintEqualToAnchor:safe.trailingAnchor
                                            constant:-24],
        [body.topAnchor constraintEqualToAnchor:title.bottomAnchor
                                       constant:12],

        [card.leadingAnchor constraintEqualToAnchor:safe.leadingAnchor
                                           constant:24],
        [card.trailingAnchor constraintEqualToAnchor:safe.trailingAnchor
                                            constant:-24],
        [card.topAnchor constraintEqualToAnchor:body.bottomAnchor
                                       constant:24],
        [card.heightAnchor constraintEqualToConstant:158],

        [badge.leadingAnchor constraintEqualToAnchor:card.leadingAnchor
                                            constant:18],
        [badge.topAnchor constraintEqualToAnchor:card.topAnchor constant:18],
        [badge.widthAnchor constraintEqualToConstant:52],
        [badge.heightAnchor constraintEqualToConstant:52],

        [cardTitle.leadingAnchor constraintEqualToAnchor:badge.trailingAnchor
                                                constant:14],
        [cardTitle.topAnchor constraintEqualToAnchor:card.topAnchor
                                            constant:20],
        [cardTitle.trailingAnchor constraintEqualToAnchor:card.trailingAnchor
                                                 constant:-18],

        [cardSub.leadingAnchor constraintEqualToAnchor:cardTitle.leadingAnchor],
        [cardSub.topAnchor constraintEqualToAnchor:cardTitle.bottomAnchor
                                          constant:4],
        [cardSub.trailingAnchor constraintEqualToAnchor:card.trailingAnchor
                                               constant:-18],

        [priority.trailingAnchor constraintEqualToAnchor:card.trailingAnchor
                                                constant:-18],
        [priority.centerYAnchor constraintEqualToAnchor:cardTitle.centerYAnchor],
        [priority.widthAnchor constraintEqualToConstant:58],
        [priority.heightAnchor constraintEqualToConstant:24],

        [divider.leadingAnchor constraintEqualToAnchor:card.leadingAnchor
                                              constant:18],
        [divider.trailingAnchor constraintEqualToAnchor:card.trailingAnchor
                                               constant:-18],
        [divider.topAnchor constraintEqualToAnchor:badge.bottomAnchor
                                          constant:18],
        [divider.heightAnchor constraintEqualToConstant:1],

        [foot.leadingAnchor constraintEqualToAnchor:card.leadingAnchor
                                           constant:18],
        [foot.topAnchor constraintEqualToAnchor:divider.bottomAnchor
                                       constant:10],

        [run.leadingAnchor constraintEqualToAnchor:safe.leadingAnchor
                                          constant:24],
        [run.trailingAnchor constraintEqualToAnchor:safe.trailingAnchor
                                           constant:-24],
        [run.heightAnchor constraintEqualToConstant:52],
        [run.bottomAnchor constraintEqualToAnchor:safe.bottomAnchor
                                        constant:-24],

        [caption.centerXAnchor constraintEqualToAnchor:safe.centerXAnchor],
        [caption.bottomAnchor constraintEqualToAnchor:run.topAnchor
                                            constant:-14]
    ]];
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
{    (void)session; (void)connectionOptions;
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
