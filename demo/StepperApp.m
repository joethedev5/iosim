#if __has_include(<UIKit/UIKit.h>)
#import <UIKit/UIKit.h>
#else
#import "UIKitStub.h"
#endif

extern int printf(const char *fmt, ...);
extern int fflush(void *stream);

/* UIStepper fixture: the plus and minus halves are real UIControls that
 * change the value and send ValueChanged. */

@interface StepperViewController : UIViewController {
    UIStepper *_stepper;
    UILabel *_valueLabel;
}
@end

@implementation StepperViewController
- (void)loadView
{
    UIView *view =
        [[UIView alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    view.backgroundColor =
        [UIColor colorWithRed:0.043 green:0.063 blue:0.125 alpha:1.0];

    _stepper = [[UIStepper alloc] initWithFrame:CGRectMake(154, 300, 94, 32)];
    _stepper.minimumValue = 0;
    _stepper.maximumValue = 10;
    _stepper.stepValue = 1;
    [_stepper addTarget:self action:@selector(stepChanged)
      forControlEvents:UIControlEventValueChanged];
    [view addSubview:_stepper];

    _valueLabel = [[UILabel alloc]
        initWithFrame:CGRectMake(154, 350, 120, 32)];
    _valueLabel.text = @"value: 0";
    _valueLabel.textColor = [UIColor whiteColor];
    _valueLabel.font = [UIFont systemFontOfSize:20];
    [view addSubview:_valueLabel];
    self.view = view;
}
- (void)viewDidLoad
{
    [super viewDidLoad];
    printf("[stepper] ready\n");
    fflush(0);
}
- (void)stepChanged
{
    printf("[stepper] value=%.0f\n", [_stepper value]);
    fflush(0);
    _valueLabel.text = [NSString stringWithFormat:@"value: %.0f",
                                                  [_stepper value]];
}
@end

@interface StepperSceneDelegate : UIResponder <UIWindowSceneDelegate>
@property(nonatomic, retain) UIWindow *window;
@end

@interface StepperAppDelegate : UIResponder <UIApplicationDelegate>
@end

@implementation StepperAppDelegate
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
    configuration.delegateClass = [StepperSceneDelegate class];
    return configuration;
}
@end

@implementation StepperSceneDelegate
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
    self.window.rootViewController = [[StepperViewController alloc] init];
    [self.window makeKeyAndVisible];
}
@end

int main(int argc, char **argv)
{
    @autoreleasepool
    {
        return UIApplicationMain(argc, argv, nil, @"StepperAppDelegate");
    }
}
