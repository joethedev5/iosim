#if __has_include(<UIKit/UIKit.h>)
#import <UIKit/UIKit.h>
#else
#import "UIKitStub.h"
#endif

extern int printf(const char *fmt, ...);
extern int fflush(void *stream);

/* Date picker fixture: a date-mode wheel set and a time-mode wheel set, both
 * initialized to 2024-02-29 12:34:00 UTC. ValueChanged prints the resulting
 * epoch seconds so wheel edits can be checked exactly. */

@interface DatePickerViewController : UIViewController {
    UIDatePicker *_datePicker;
    UIDatePicker *_timePicker;
}
@end

@implementation DatePickerViewController
- (void)loadView
{
    UIView *view =
        [[UIView alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    view.backgroundColor =
        [UIColor colorWithRed:0.055 green:0.075 blue:0.14 alpha:1.0];

    NSDate *initial =
        [NSDate dateWithTimeIntervalSince1970:1709210040.0];

    _datePicker = [[UIDatePicker alloc]
        initWithFrame:CGRectMake(24, 80, 354, 160)];
    _datePicker.datePickerMode = UIDatePickerModeDate;
    [_datePicker setDate:initial animated:NO];
    [_datePicker addTarget:self action:@selector(dateChanged)
         forControlEvents:UIControlEventValueChanged];
    [view addSubview:_datePicker];

    _timePicker = [[UIDatePicker alloc]
        initWithFrame:CGRectMake(24, 280, 354, 140)];
    _timePicker.datePickerMode = UIDatePickerModeTime;
    [_timePicker setDate:initial animated:NO];
    [_timePicker addTarget:self action:@selector(timeChanged)
         forControlEvents:UIControlEventValueChanged];
    [view addSubview:_timePicker];

    self.view = view;
}
- (void)viewDidLoad
{
    [super viewDidLoad];
    printf("[datepicker] ready\n");
    fflush(0);
}
- (void)dateChanged
{
    printf("[datepicker] date %lld\n",
           (long long)[_datePicker.date timeIntervalSince1970]);
    fflush(0);
}
- (void)timeChanged
{
    printf("[datepicker] time %lld\n",
           (long long)[_timePicker.date timeIntervalSince1970]);
    fflush(0);
}
@end

@interface SceneDelegate : UIResponder <UIWindowSceneDelegate>
@property(nonatomic, retain) UIWindow *window;
@end

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
        [UIColor colorWithRed:0.055 green:0.075 blue:0.14 alpha:1.0];
    self.window.rootViewController =
        [[DatePickerViewController alloc] init];
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
