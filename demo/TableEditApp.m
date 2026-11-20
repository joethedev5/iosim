#if __has_include(<UIKit/UIKit.h>)
#import <UIKit/UIKit.h>
#else
#import "UIKitStub.h"
#endif

extern int printf(const char *fmt, ...);
extern int fflush(void *stream);
extern const char *iosim_string_cstr(id string);

/* Editable table fixture: a flat list whose rows can be swiped left to
 * reveal a Delete control; committing removes the item from the model. */

@interface TableEditViewController : UIViewController
    <UITableViewDataSource, UITableViewDelegate> {
    UITableView *_table;
    NSMutableArray *_items;
}
@end

@implementation TableEditViewController
- (void)loadView
{
    UIView *view =
        [[UIView alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    view.backgroundColor =
        [UIColor colorWithRed:0.043 green:0.063 blue:0.125 alpha:1.0];

    _items = [NSMutableArray array];
    [_items addObject:@"Red"];
    [_items addObject:@"Green"];
    [_items addObject:@"Blue"];
    [_items addObject:@"Yellow"];

    _table = [[UITableView alloc] initWithFrame:CGRectMake(0, 80, 402, 420)
                                           style:0];
    _table.dataSource = self;
    _table.delegate = self;
    _table.rowHeight = 56;
    [view addSubview:_table];
    self.view = view;
}
- (void)viewDidLoad
{
    [super viewDidLoad];
    [_table reloadData];
    printf("[edit] ready items=%lu\n", [_items count]);
    fflush(0);
}
- (long)tableView:(UITableView *)tableView numberOfRowsInSection:(long)section
{
    (void)tableView;
    (void)section;
    return (long)[_items count];
}
- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView
        dequeueReusableCellWithIdentifier:@"cell"];
    if (!cell)
        cell = [[UITableViewCell alloc] initWithStyle:0
                                      reuseIdentifier:@"cell"];
    long row = [indexPath row];
    cell.textLabel.text = row < (long)[_items count]
                              ? [_items objectAtIndex:(unsigned long)row]
                              : @"";
    cell.textLabel.textColor = [UIColor whiteColor];
    cell.backgroundColor =
        [UIColor colorWithRed:0.11 green:0.12 blue:0.16 alpha:1.0];
    return cell;
}
- (BOOL)tableView:(UITableView *)tableView
    canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    (void)tableView;
    (void)indexPath;
    return YES;
}
- (void)tableView:(UITableView *)tableView commitEditingStyle:(long)style
    forRowAtIndexPath:(NSIndexPath *)indexPath
{
    (void)tableView;
    if (style != UITableViewCellEditingStyleDelete)
        return;
    long row = [indexPath row];
    if (row < 0 || row >= (long)[_items count])
        return;
    NSString *name = [_items objectAtIndex:(unsigned long)row];
    printf("[edit] deleted %ld name=%s\n", row,
           iosim_string_cstr(name));
    [_items removeObjectAtIndex:(unsigned long)row];
    printf("[edit] items=%lu\n", [_items count]);
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
        [UIColor colorWithRed:0.043 green:0.063 blue:0.125 alpha:1.0];
    self.window.rootViewController =
        [[TableEditViewController alloc] init];
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
