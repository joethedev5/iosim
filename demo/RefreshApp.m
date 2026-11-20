#if __has_include(<UIKit/UIKit.h>)
#import <UIKit/UIKit.h>
#else
#import "UIKitStub.h"
#endif

extern int printf(const char *fmt, ...);
extern int fflush(void *stream);

/* Pull-to-refresh fixture: a twelve-row table with a UIRefreshControl. A pull
 * past the threshold sends ValueChanged; the handler logs it and ends the
 * refresh automatically after a short delay. */

@interface RefreshDataSource : NSObject <UITableViewDataSource>
@end

@interface RefreshViewController : UIViewController
@property(nonatomic, retain) UITableView *table;
@property(nonatomic, retain) UIRefreshControl *refresh;
@end

@interface SceneDelegate : UIResponder <UIWindowSceneDelegate>
@property(nonatomic, retain) UIWindow *window;
@end

@interface AppDelegate : UIResponder <UIApplicationDelegate>
@end

@implementation RefreshDataSource
- (long)tableView:(UITableView *)tableView numberOfRowsInSection:(long)section
{
    (void)tableView;
    (void)section;
    return 12;
}
- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell =
        [tableView dequeueReusableCellWithIdentifier:@"row"];
    if (!cell)
        cell = [[UITableViewCell alloc] initWithStyle:0
                                      reuseIdentifier:@"row"];
    cell.textLabel.text =
        [NSString stringWithFormat:@"Row %ld", (long)[indexPath row]];
    return cell;
}
@end

@implementation RefreshViewController
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
    self.table = [[UITableView alloc]
        initWithFrame:CGRectMake(0, 60, 402, 814) style:0];
    self.table.dataSource = [[RefreshDataSource alloc] init];
    self.table.rowHeight = 56;
    [self.view addSubview:self.table];

    self.refresh = [[UIRefreshControl alloc] init];
    [self.refresh addTarget:self
                     action:@selector(refreshPulled:)
           forControlEvents:UIControlEventValueChanged];
    self.table.refreshControl = self.refresh;
    [self.table reloadData];
    printf("[refresh] ready rows=12\n");
    fflush(0);
}
- (void)refreshPulled:(id)sender
{
    (void)sender;
    printf("[refresh] pulled\n");
    fflush(0);
    [NSTimer scheduledTimerWithTimeInterval:0.8
                                     target:self
                                   selector:@selector(refreshDone:)
                                   userInfo:nil
                                    repeats:NO];
}
- (void)refreshDone:(id)timer
{
    (void)timer;
    [self.refresh endRefreshing];
    printf("[refresh] done\n");
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
    self.window.rootViewController = [[RefreshViewController alloc] init];
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
