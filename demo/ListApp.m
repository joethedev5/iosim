#if __has_include(<UIKit/UIKit.h>)
#import <UIKit/UIKit.h>
#else
#import "UIKitStub.h"
#endif

static NSString *nameForRow(long row)
{
    switch (row)
    {
    case 0: return @"Amelia Hart";
    case 1: return @"Ben Okafor";
    case 2: return @"Chloé Martin";
    case 3: return @"Daniel Reyes";
    case 4: return @"Elena Petrova";
    case 5: return @"Farah Nasser";
    case 6: return @"Grace Kim";
    case 7: return @"Hugo Lindqvist";
    }
    return @"—";
}

static NSString *roleForRow(long row)
{
    switch (row)
    {
    case 0: return @"Design lead";
    case 1: return @"Rendering engineer";
    case 2: return @"Runtime engineer";
    case 3: return @"QA";
    case 4: return @"Fonts";
    case 5: return @"Services";
    case 6: return @"UIKit";
    case 7: return @"Graphics";
    }
    return @"";
}

@interface SceneDelegate : UIResponder <UIWindowSceneDelegate, UITableViewDataSource,
                                       UITableViewDelegate>
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

@implementation SceneDelegate {
    UITableView *_table;
    UILabel *_status;
    long _selected;
}

- (long)tableView:(UITableView *)tableView numberOfRowsInSection:(long)section
{
    (void)tableView; (void)section;
    return 8;
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell =
        [tableView dequeueReusableCellWithIdentifier:@"person"];
    if (!cell)
        cell = [[UITableViewCell alloc]
            initWithStyle:UITableViewCellStyleSubtitle
          reuseIdentifier:@"person"];
    cell.backgroundColor =
        [UIColor colorWithRed:0.078 green:0.106 blue:0.184 alpha:1.0];
    cell.textLabel.text = nameForRow(indexPath.row);
    cell.detailTextLabel.text = roleForRow(indexPath.row);
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    return cell;
}

- (void)tableView:(UITableView *)tableView
    didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    (void)tableView;
    _selected = indexPath.row;
    _status.text = [NSString stringWithFormat:@"Selected: %@",
                                              nameForRow(indexPath.row)];
}

- (void)scene:(UIScene *)scene
    willConnectToSession:(UISceneSession *)session
                 options:(UISceneConnectionOptions *)connectionOptions
{
    (void)session; (void)connectionOptions;
    CGRect screen = [[UIScreen mainScreen] bounds];
    double width = screen.size.width;

    self.window = [[UIWindow alloc] initWithWindowScene:(UIWindowScene *)scene];
    self.window.frame = screen;
    self.window.backgroundColor =
        [UIColor colorWithRed:0.035 green:0.047 blue:0.098 alpha:1.0];

    UILabel *title =
        [[UILabel alloc] initWithFrame:CGRectMake(24, 76, width - 48, 40)];
    title.text = @"Team";
    title.textColor = [UIColor whiteColor];
    title.font = [UIFont boldSystemFontOfSize:32];
    [self.window addSubview:title];

    UILabel *sub =
        [[UILabel alloc] initWithFrame:CGRectMake(24, 120, width - 48, 22)];
    sub.text = @"UITableView · reusable cells · selection";
    sub.textColor = [UIColor colorWithRed:0.58 green:0.64 blue:0.72 alpha:1.0];
    sub.font = [UIFont systemFontOfSize:14];
    [self.window addSubview:sub];

    UIView *card =
        [[UIView alloc] initWithFrame:CGRectMake(20, 166, width - 40, 8 * 58 + 8)];
    card.backgroundColor =
        [UIColor colorWithRed:0.078 green:0.106 blue:0.184 alpha:1.0];
    card.layer.cornerRadius = 18;
    [self.window addSubview:card];

    _table = [[UITableView alloc] initWithFrame:CGRectMake(0, 4, width - 40,
                                                           8 * 58)
                                            style:UITableViewStylePlain];
    _table.backgroundColor =
        [UIColor colorWithRed:0.078 green:0.106 blue:0.184 alpha:1.0];
    _table.rowHeight = 58;
    _table.dataSource = self;
    _table.delegate = self;
    [_table reloadData];
    [card addSubview:_table];

    _status = [[UILabel alloc]
        initWithFrame:CGRectMake(24, 650, width - 48, 24)];
    _status.text = @"Selected: none";
    _status.textColor = [UIColor colorWithRed:0.39 green:0.45 blue:0.55 alpha:1.0];
    _status.font = [UIFont systemFontOfSize:14];
    [self.window addSubview:_status];

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
