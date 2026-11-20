#if __has_include(<UIKit/UIKit.h>)
#import <UIKit/UIKit.h>
#else
#import "UIKitStub.h"
#endif

extern int printf(const char *fmt, ...);
extern int fflush(void *stream);

/* Picker fixture: two wheel components, a data source for rows and a
 * delegate for titles and selection reporting. The second component is
 * chosen by tapping; the first by dragging the wheel. */

@interface PickerViewController : UIViewController
    <UIPickerViewDataSource, UIPickerViewDelegate> {
    UIPickerView *_picker;
    UILabel *_status;
}
@end

@implementation PickerViewController
- (void)loadView
{
    UIView *view =
        [[UIView alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    view.backgroundColor =
        [UIColor colorWithRed:0.055 green:0.075 blue:0.14 alpha:1.0];

    UILabel *title = [[UILabel alloc] initWithFrame:CGRectMake(24, 70, 354, 32)];
    title.text = @"Picker";
    title.textColor = [UIColor whiteColor];
    title.font = [UIFont boldSystemFontOfSize:24];
    [view addSubview:title];

    _picker = [[UIPickerView alloc]
        initWithFrame:CGRectMake(24, 140, 354, 216)];
    _picker.dataSource = self;
    _picker.delegate = self;
    [view addSubview:_picker];

    _status = [[UILabel alloc] initWithFrame:CGRectMake(24, 380, 354, 28)];
    _status.text = @"none";
    _status.textColor =
        [UIColor colorWithRed:0.60 green:0.70 blue:0.90 alpha:1.0];
    _status.font = [UIFont systemFontOfSize:17];
    [view addSubview:_status];

    self.view = view;
}
- (void)viewDidLoad
{
    [super viewDidLoad];
    [_picker selectRow:0 inComponent:0 animated:NO];
    [_picker selectRow:0 inComponent:1 animated:NO];
    [_picker reloadAllComponents];
    printf("[picker] ready\n");
    fflush(0);
}
- (long)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
    (void)pickerView;
    return 2;
}
- (long)pickerView:(UIPickerView *)pickerView
    numberOfRowsInComponent:(long)component
{
    (void)pickerView;
    return component == 0 ? 5 : 3;
}
- (id)pickerView:(UIPickerView *)pickerView titleForRow:(long)row
    forComponent:(long)component
{
    (void)pickerView;
    static const char *countries[5] = {
        "Alpha", "Bravo", "Charlie", "Delta", "Echo"
    };
    static const char *colors[3] = { "Red", "Green", "Blue" };
    if (component == 0)
        return row >= 0 && row < 5
                   ? [NSString stringWithUTF8String:countries[row]]
                   : nil;
    return row >= 0 && row < 3
               ? [NSString stringWithUTF8String:colors[row]]
               : nil;
}
- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(long)row
    inComponent:(long)component
{
    (void)pickerView;
    printf("[picker] selected %ld:%ld\n", (long)component, (long)row);
    fflush(0);
    _status.text = [NSString stringWithFormat:@"%ld:%ld",
        (long)component, (long)row];
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
        [[PickerViewController alloc] init];
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
