#if __has_include(<UIKit/UIKit.h>)
#import <UIKit/UIKit.h>
#else
#import "UIKitStub.h"
#endif

extern int printf(const char *fmt, ...);
extern int fflush(void *stream);

/* Sectioned table fixture: two sections with headers, different row heights
 * and distinct row colors, so header offsets and tap mapping are visible. */

static const char *fruit_names[3] = { "Apple", "Banana", "Cherry" };
static const char *vegetable_names[2] = { "Carrot", "Pea" };

@interface SectionViewController : UIViewController
    <UITableViewDataSource, UITableViewDelegate> {
    UITableView *_table;
}
@end

@implementation SectionViewController
- (void)loadView
{
    UIView *view =
        [[UIView alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    view.backgroundColor =
        [UIColor colorWithRed:0.043 green:0.063 blue:0.125 alpha:1.0];

    _table = [[UITableView alloc] initWithFrame:CGRectMake(0, 100, 402, 600)
                                           style:1];
    _table.dataSource = self;
    _table.delegate = self;
    [view addSubview:_table];
    self.view = view;
}
- (void)viewDidLoad
{
    [super viewDidLoad];
    [_table reloadData];
    printf("[section] ready rows=5\n");
    fflush(0);
}
- (long)numberOfSectionsInTableView:(UITableView *)tableView
{
    (void)tableView;
    return 2;
}
- (long)tableView:(UITableView *)tableView numberOfRowsInSection:(long)section
{
    (void)tableView;
    return section == 0 ? 3 : 2;
}
- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView
        dequeueReusableCellWithIdentifier:@"cell"];
    if (!cell)
        cell = [[UITableViewCell alloc] initWithStyle:0
                                      reuseIdentifier:@"cell"];
    const char *name =
        [indexPath section] == 0 ? fruit_names[[indexPath row]]
                                 : vegetable_names[[indexPath row]];
    cell.textLabel.text = [NSString stringWithFormat:@"%s", name];
    if ([indexPath section] == 0)
        cell.backgroundColor =
            [UIColor colorWithRed:0.25 green:0.15 blue:0.35 alpha:1.0];
    else
        cell.backgroundColor =
            [UIColor colorWithRed:0.15 green:0.25 blue:0.35 alpha:1.0];
    return cell;
}
- (id)tableView:(UITableView *)tableView
    titleForHeaderInSection:(long)section
{
    (void)tableView;
    return section == 0 ? @"FRUITS" : @"VEGETABLES";
}
- (double)tableView:(UITableView *)tableView
    heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    (void)tableView;
    return [indexPath section] == 0 ? 44.0 : 50.0;
}
- (void)tableView:(UITableView *)tableView
    didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    (void)tableView;
    long section = [indexPath section], row = [indexPath row];
    const char *name = section == 0 ? fruit_names[row] : vegetable_names[row];
    printf("[section] select %ld:%ld %s\n", section, row, name);
    fflush(0);
}
@end

@interface SectionSceneDelegate : UIResponder <UIWindowSceneDelegate>
@property(nonatomic, retain) UIWindow *window;
@end

@interface SectionAppDelegate : UIResponder <UIApplicationDelegate>
@end

@implementation SectionAppDelegate
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
    configuration.delegateClass = [SectionSceneDelegate class];
    return configuration;
}
@end

@implementation SectionSceneDelegate
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
    self.window.rootViewController = [[SectionViewController alloc] init];
    [self.window makeKeyAndVisible];
}
@end

int main(int argc, char **argv)
{
    @autoreleasepool
    {
        return UIApplicationMain(argc, argv, nil, @"SectionAppDelegate");
    }
}
