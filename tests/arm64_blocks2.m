/* Native frameworks invoke arm64 blocks that return objects and blocks
 * with four arguments: a diffable table data source cell provider, an
 * alert action handler, and activity view controller completions. */
#include "UIKitStub.h"

extern int printf(const char *fmt, ...);
extern int fflush(void *stream);
extern void exit(int status);
extern char *getenv(const char *name);
extern int open(const char *path, int flags, ...);
extern long write(int fd, const void *buf, unsigned long count);
extern int snprintf(char *buf, unsigned long size, const char *fmt, ...);
extern unsigned long long dispatch_time(unsigned long long when,
                                        long long delta);
extern void dispatch_after(unsigned long long when, void *queue,
                           void (^block)(void));
extern void *dispatch_get_main_queue(void);

static int event_fd = -1;

static void send_tap_px(int x, int y)
{
    const char *path = getenv("IOSIM_EVENT_FIFO");
    if (!path || !*path)
        return;
    if (event_fd < 0)
        event_fd = open(path, 1);
    if (event_fd < 0)
        return;
    char line[64];
    snprintf(line, sizeof(line), "tap %d %d\n", x, y);
    unsigned long length = 0;
    while (line[length])
        length++;
    write(event_fd, line, length);
}

@interface Blocks2SceneDelegate : UIResponder <UIWindowSceneDelegate>
@property(nonatomic, retain) UIWindow *window;
@end

@implementation Blocks2SceneDelegate

- (void)scene:(UIScene *)scene
    willConnectToSession:(UISceneSession *)session
                 options:(UISceneConnectionOptions *)connectionOptions
{
    (void)session;
    (void)connectionOptions;
    CGRect screen = [[UIScreen mainScreen] bounds];

    self.window = [[UIWindow alloc] initWithWindowScene:(UIWindowScene *)scene];
    self.window.frame = screen;
    UIViewController *root = [[UIViewController alloc] init];
    UIView *content = [[UIView alloc] initWithFrame:screen];
    content.backgroundColor =
        [UIColor colorWithRed:0.10 green:0.70 blue:0.30 alpha:1.0];
    root.view = content;
    self.window.rootViewController = root;
    [self.window makeKeyAndVisible];

    UITableView *table = [[UITableView alloc]
        initWithFrame:CGRectMake(20, 80, screen.size.width - 40, 200)
                style:UITableViewStylePlain];
    [content addSubview:table];

    NSDiffableDataSourceSnapshot *snapshot =
        [[NSDiffableDataSourceSnapshot alloc] init];
    [snapshot appendSectionsWithIdentifiers:[NSArray arrayWithObject:@"S"]];
    [snapshot appendItemsWithIdentifiers:@[@"alpha", @"beta"]
               intoSectionWithIdentifier:@"S"];
    UITableViewDiffableDataSource *source =
        [[UITableViewDiffableDataSource alloc]
            initWithTableView:table
                 cellProvider:^id(UITableView *view, NSIndexPath *indexPath,
                                  id item) {
        UITableViewCell *cell =
            [view dequeueReusableCellWithIdentifier:@"blocks2"];
        if (!cell)
            cell = [[UITableViewCell alloc]
                initWithStyle:UITableViewCellStyleDefault
              reuseIdentifier:@"blocks2"];
        cell.textLabel.text = item;
        printf("[blocks2] provider %ld %s\n", (long)[indexPath row],
               [(NSString *)item UTF8String]);
        fflush(0);
        return cell;
    }];
    table.dataSource = source;
    [source applySnapshot:snapshot animatingDifferences:NO];
    UITableViewCell *cell = [source tableView:table
                        cellForRowAtIndexPath:[NSIndexPath indexPathForRow:1
                                                               inSection:0]];
    printf("[blocks2] cell %s\n",
           cell && cell.textLabel.text ? [cell.textLabel.text UTF8String]
                                       : "(nil)");
    fflush(0);

    UIView *box = [[UIView alloc] initWithFrame:CGRectMake(20, 320, 80, 80)];
    box.backgroundColor = [UIColor redColor];
    [content addSubview:box];
    UIViewPropertyAnimator *animator = [[UIViewPropertyAnimator alloc]
        initWithDuration:0.3
                   curve:UIViewAnimationCurveEaseInOut
              animations:^{
        box.alpha = 0.5;
    }];
    [animator addCompletion:^(long position) {
        printf("[blocks2] animator %ld %d\n", position,
               (int)(box.alpha * 100));
        fflush(0);
    }];
    [animator startAnimation];

    dispatch_after(dispatch_time(0, 300 * 1000000LL),
                   dispatch_get_main_queue(), ^{
        UIAlertController *alert = [UIAlertController
            alertControllerWithTitle:nil
                             message:nil
                      preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"One"
            style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            (void)action;
            printf("[blocks2] alert one\n");
            fflush(0);
        }]];
        [alert addAction:[UIAlertAction actionWithTitle:@"Two"
            style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            (void)action;
            printf("[blocks2] alert two\n");
            fflush(0);
        }]];
        [alert addAction:[UIAlertAction actionWithTitle:@"Three"
            style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            (void)action;
            printf("[blocks2] alert three\n");
            fflush(0);
        }]];
        [root presentViewController:alert animated:NO completion:nil];
    });
    dispatch_after(dispatch_time(0, 700 * 1000000LL),
                   dispatch_get_main_queue(), ^{
        send_tap_px(603, 1556);
    });
    dispatch_after(dispatch_time(0, 1000 * 1000000LL),
                   dispatch_get_main_queue(), ^{
        UIActivityViewController *sheet = [[UIActivityViewController alloc]
            initWithActivityItems:[NSArray arrayWithObject:@"arm64 blocks"]
            applicationActivities:nil];
        [sheet setCompletionWithItemsHandler:^(
            UIActivityType type, BOOL completed, NSArray *items,
            NSError *error) {
            (void)type;
            (void)error;
            printf("[blocks2] items %d %d\n", completed ? 1 : 0,
                   items != nil ? 1 : 0);
            fflush(0);
        }];
        [root presentViewController:sheet animated:YES completion:nil];
    });
    dispatch_after(dispatch_time(0, 1700 * 1000000LL),
                   dispatch_get_main_queue(), ^{
        send_tap_px(201, 300);
    });
    dispatch_after(dispatch_time(0, 2000 * 1000000LL),
                   dispatch_get_main_queue(), ^{
        UIActivityViewController *sheet = [[UIActivityViewController alloc]
            initWithActivityItems:[NSArray arrayWithObject:@"hidden"]
            applicationActivities:nil];
        [sheet setCompletionWithItemsHandler:nil];
        [sheet setCompletionHandler:^(UIActivityType type, BOOL completed) {
            (void)type;
            printf("[blocks2] completion %d\n", completed ? 1 : 0);
            fflush(0);
        }];
        [root presentViewController:sheet animated:YES completion:nil];
    });
    dispatch_after(dispatch_time(0, 2700 * 1000000LL),
                   dispatch_get_main_queue(), ^{
        send_tap_px(201, 300);
    });
    dispatch_after(dispatch_time(0, 3200 * 1000000LL),
                   dispatch_get_main_queue(), ^{
        printf("[blocks2] done\n");
        fflush(0);
        exit(0);
    });
}

@end

@interface Blocks2AppDelegate : UIResponder <UIApplicationDelegate>
@end

@implementation Blocks2AppDelegate

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
    configuration.delegateClass = [Blocks2SceneDelegate class];
    return configuration;
}

@end

int main(int argc, char **argv)
{
    return UIApplicationMain(argc, argv, nil, @"Blocks2AppDelegate");
}
