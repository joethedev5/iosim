#if __has_include(<UIKit/UIKit.h>)
#import <UIKit/UIKit.h>
#else
#import "UIKitStub.h"
#endif

extern int printf(const char *fmt, ...);
extern int fflush(void *stream);
extern const char *iosim_string_cstr(id string);

/* UISearchBar fixture: the bar's inner text field drives the software
 * keyboard and hardware keys, and its delegate reports edits, Return and
 * Cancel. */

@interface SearchViewController : UIViewController {
    UISearchBar *_bar;
    UILabel *_status;
}
@end

@implementation SearchViewController
- (void)loadView
{
    UIView *view =
        [[UIView alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    view.backgroundColor =
        [UIColor colorWithRed:0.043 green:0.063 blue:0.125 alpha:1.0];

    _bar = [[UISearchBar alloc] initWithFrame:CGRectMake(16, 140, 370, 44)];
    _bar.placeholder = @"Find";
    _bar.delegate = self;
    [_bar setShowsCancelButton:YES animated:NO];
    [view addSubview:_bar];

    _status = [[UILabel alloc] initWithFrame:CGRectMake(16, 200, 370, 32)];
    _status.text = @"query:";
    _status.textColor = [UIColor whiteColor];
    _status.font = [UIFont systemFontOfSize:18];
    [view addSubview:_status];
    self.view = view;
}
- (void)viewDidLoad
{
    [super viewDidLoad];
    printf("[searchbar] ready\n");
    fflush(0);
}
- (void)searchBar:(UISearchBar *)bar textDidChange:(id)text
{
    (void)bar;
    printf("[searchbar] q=%s\n", iosim_string_cstr(text));
    fflush(0);
    _status.text = [NSString stringWithFormat:@"query: %s",
                                             iosim_string_cstr(text)];
}
- (void)searchBarSearchButtonClicked:(UISearchBar *)bar
{
    printf("[searchbar] go %s\n", iosim_string_cstr([bar text]));
    fflush(0);
}
- (void)searchBarCancelButtonClicked:(UISearchBar *)bar
{
    (void)bar;
    printf("[searchbar] cancel\n");
    fflush(0);
}
@end

@interface SearchSceneDelegate : UIResponder <UIWindowSceneDelegate>
@property(nonatomic, retain) UIWindow *window;
@end

@interface SearchAppDelegate : UIResponder <UIApplicationDelegate>
@end

@implementation SearchAppDelegate
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
    configuration.delegateClass = [SearchSceneDelegate class];
    return configuration;
}
@end

@implementation SearchSceneDelegate
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
    self.window.rootViewController = [[SearchViewController alloc] init];
    [self.window makeKeyAndVisible];
}
@end

int main(int argc, char **argv)
{
    @autoreleasepool
    {
        return UIApplicationMain(argc, argv, nil, @"SearchAppDelegate");
    }
}
