/* Context menus: a long press on a table row lifts the row over a blurred
 * backdrop and shows a two-action menu; tapping Favorite runs its handler
 * and dismisses. A second row checks the destructive item and an outside
 * tap dismissal. A plain view with a UIContextMenuInteraction shows a
 * snapshot preview and runs its single action. */
#include "UIKitStub.h"

extern int printf(const char *fmt, ...);
extern int fflush(void *stream);
extern int iosim_fb_present(const char *path);
extern void iosim_fb_capture(int x, int y, int w, int h, unsigned *out);
extern char *getenv(const char *name);
extern void exit(int status);
extern int open(const char *path, int flags, ...);
extern long write(int fd, const void *buf, unsigned long count);
extern int snprintf(char *buf, unsigned long size, const char *fmt, ...);
extern unsigned long long dispatch_time(unsigned long long when,
                                        long long delta);
extern void dispatch_after(unsigned long long when, void *queue,
                           void (^block)(void));
extern void *dispatch_get_main_queue(void);

static int event_fd = -1;

static void send_event(const char *line)
{
    const char *path = getenv("IOSIM_EVENT_FIFO");
    if (!path || !*path)
        return;
    if (event_fd < 0)
        event_fd = open(path, 1);
    if (event_fd < 0)
        return;
    unsigned long length = 0;
    while (line[length])
        length++;
    write(event_fd, line, length);
}

static void send_touch(const char *kind, double x, double y)
{
    char line[96];
    snprintf(line, sizeof(line), "%s %d %d\n", kind, (int)(x * 3.0 + 0.5),
             (int)(y * 3.0 + 0.5));
    send_event(line);
}

static void capture(const char *variable)
{
    const char *path = getenv(variable);
    if (path)
        iosim_fb_present(path);
    fflush(0);
}

static int after_attempts;

static int backdrop_green(void)
{
    unsigned pixel = 0;
    iosim_fb_capture(201 * 3, 300 * 3, 1, 1, &pixel);
    unsigned r = (pixel >> 16) & 255, g = (pixel >> 8) & 255,
             b = pixel & 255;
    return r < 80 && g > 170 && b < 130;
}

/* The tap and the screenshot timer can be drained in the same event-loop
 * iteration, before the dismissal is redrawn. Poll the framebuffer until
 * the backdrop is revealed again, then capture. */
static void capture_after_restore(const char *variable)
{
    if (!backdrop_green() && after_attempts < 4)
    {
        after_attempts++;
        dispatch_after(dispatch_time(0, 50 * 1000000LL),
                       dispatch_get_main_queue(), ^{
            capture_after_restore(variable);
        });
        return;
    }
    capture(variable);
}

static int g_last_row;

@interface MenuController : UIViewController <UITableViewDataSource,
                                              UITableViewDelegate,
                                              UIContextMenuInteractionDelegate>
@end

@implementation MenuController
- (UIMenu *)menu
{
    UIAction *favorite = [UIAction actionWithTitle:@"Favorite"
                                            image:nil
                                       identifier:nil
                                          handler:^(UIAction *action) {
        (void)action;
        printf("[menu] favorite %d\n", g_last_row);
        fflush(0);
    }];
    UIAction *remove = [UIAction actionWithTitle:@"Delete"
                                           image:nil
                                      identifier:nil
                                         handler:^(UIAction *action) {
        (void)action;
        printf("[menu] delete\n");
        fflush(0);
    }];
    [remove setAttributes:UIMenuElementAttributesDestructive];
    id children[2] = { favorite, remove };
    return [UIMenu menuWithTitle:nil
                        children:[NSArray arrayWithObjects:children count:2]];
}

- (UIMenu *)pingMenu
{
    UIAction *ping = [UIAction actionWithTitle:@"Ping"
                                         image:nil
                                    identifier:nil
                                       handler:^(UIAction *action) {
        (void)action;
        printf("[menu] ping\n");
        fflush(0);
    }];
    id children[1] = { ping };
    return [UIMenu menuWithTitle:nil
                        children:[NSArray arrayWithObjects:children count:1]];
}

- (void)loadView
{
    UIView *root =
        [[UIView alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    root.backgroundColor =
        [UIColor colorWithRed:0.10 green:0.80 blue:0.30 alpha:1.0];
    self.view = root;

    UITableView *table = [[UITableView alloc]
        initWithFrame:[[UIScreen mainScreen] bounds]
                style:UITableViewStylePlain];
    table.dataSource = self;
    table.delegate = self;
    table.rowHeight = 44.0;
    table.backgroundColor =
        [UIColor colorWithRed:0.10 green:0.80 blue:0.30 alpha:1.0];
    [root addSubview:table];

    UIView *orange = [[UIView alloc] initWithFrame:CGRectMake(30, 400, 120, 80)];
    orange.backgroundColor =
        [UIColor colorWithRed:0.90 green:0.40 blue:0.10 alpha:1.0];
    [root addSubview:orange];
    UIContextMenuInteraction *interaction =
        [[UIContextMenuInteraction alloc] initWithDelegate:self];
    [orange addInteraction:interaction];

    UICollectionViewFlowLayout *layout =
        [[UICollectionViewFlowLayout alloc] init];
    layout.itemSize = CGSizeMake(100, 100);
    layout.minimumInteritemSpacing = 10;
    layout.minimumLineSpacing = 10;
    layout.sectionInset = UIEdgeInsetsMake(20, 20, 20, 20);
    UICollectionView *collection = [[UICollectionView alloc]
        initWithFrame:CGRectMake(0, 600, 402, 200)
 collectionViewLayout:layout];
    collection.dataSource = self;
    collection.delegate = self;
    collection.backgroundColor =
        [UIColor colorWithRed:0.05 green:0.05 blue:0.08 alpha:1.0];
    [collection reloadData];
    [root addSubview:collection];

    dispatch_after(dispatch_time(0, 150 * 1000000LL),
                   dispatch_get_main_queue(), ^{
        send_touch("down", 201, 66);
    });
    dispatch_after(dispatch_time(0, 800 * 1000000LL),
                   dispatch_get_main_queue(), ^{
        send_touch("up", 201, 66);
    });
    dispatch_after(dispatch_time(0, 900 * 1000000LL),
                   dispatch_get_main_queue(), ^{
        capture("IOSIM_TEST_PNG_MENU");
    });
    dispatch_after(dispatch_time(0, 1000 * 1000000LL),
                   dispatch_get_main_queue(), ^{
        send_event("tap 603 450\n");
    });
    dispatch_after(dispatch_time(0, 1300 * 1000000LL),
                   dispatch_get_main_queue(), ^{
        capture_after_restore("IOSIM_TEST_PNG_AFTER");
    });

    dispatch_after(dispatch_time(0, 1450 * 1000000LL),
                   dispatch_get_main_queue(), ^{
        send_touch("down", 201, 110);
    });
    dispatch_after(dispatch_time(0, 2100 * 1000000LL),
                   dispatch_get_main_queue(), ^{
        send_touch("up", 201, 110);
    });
    dispatch_after(dispatch_time(0, 2200 * 1000000LL),
                   dispatch_get_main_queue(), ^{
        capture("IOSIM_TEST_PNG_MENU2");
    });
    dispatch_after(dispatch_time(0, 2300 * 1000000LL),
                   dispatch_get_main_queue(), ^{
        send_event("tap 603 2100\n");
    });
    dispatch_after(dispatch_time(0, 2600 * 1000000LL),
                   dispatch_get_main_queue(), ^{
        capture("IOSIM_TEST_PNG_END");
    });

    dispatch_after(dispatch_time(0, 2750 * 1000000LL),
                   dispatch_get_main_queue(), ^{
        send_touch("down", 90, 440);
    });
    dispatch_after(dispatch_time(0, 3400 * 1000000LL),
                   dispatch_get_main_queue(), ^{
        send_touch("up", 90, 440);
    });
    dispatch_after(dispatch_time(0, 3500 * 1000000LL),
                   dispatch_get_main_queue(), ^{
        capture("IOSIM_TEST_PNG_GEN");
    });
    dispatch_after(dispatch_time(0, 3600 * 1000000LL),
                   dispatch_get_main_queue(), ^{
        send_event("tap 600 1560\n");
    });
    dispatch_after(dispatch_time(0, 3900 * 1000000LL),
                   dispatch_get_main_queue(), ^{
        capture("IOSIM_TEST_PNG_GENEND");
    });

    dispatch_after(dispatch_time(0, 4100 * 1000000LL),
                   dispatch_get_main_queue(), ^{
        send_touch("down", 70, 670);
    });
    dispatch_after(dispatch_time(0, 4750 * 1000000LL),
                   dispatch_get_main_queue(), ^{
        send_touch("up", 70, 670);
    });
    dispatch_after(dispatch_time(0, 4850 * 1000000LL),
                   dispatch_get_main_queue(), ^{
        capture("IOSIM_TEST_PNG_COL");
    });
    dispatch_after(dispatch_time(0, 4950 * 1000000LL),
                   dispatch_get_main_queue(), ^{
        send_event("tap 603 2280\n");
    });
    dispatch_after(dispatch_time(0, 5250 * 1000000LL),
                   dispatch_get_main_queue(), ^{
        capture("IOSIM_TEST_PNG_COLEND");
    });
    dispatch_after(dispatch_time(0, 5400 * 1000000LL),
                   dispatch_get_main_queue(), ^{
        printf("[menu] png written\n");
        fflush(0);
        exit(0);
    });
}

- (long)tableView:(UITableView *)tableView numberOfRowsInSection:(long)section
{
    (void)tableView;
    (void)section;
    return 12;
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    (void)tableView;
    UITableViewCell *cell =
        [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                               reuseIdentifier:nil];
    long row = [indexPath row];
    const char *names[3] = { "Alpha", "Bravo", "Charlie" };
    cell.textLabel.text = [NSString stringWithUTF8String:names[row % 3]];
    if (row == 1)
        cell.backgroundColor =
            [UIColor colorWithRed:0.15 green:0.20 blue:0.35 alpha:1.0];
    else if (row == 2)
        cell.backgroundColor =
            [UIColor colorWithRed:0.35 green:0.15 blue:0.45 alpha:1.0];
    return cell;
}

- (UIContextMenuConfiguration *)tableView:(UITableView *)tableView
    contextMenuConfigurationForRowAtIndexPath:(NSIndexPath *)indexPath
                                        point:(CGPoint)point
{
    (void)tableView;
    (void)point;
    g_last_row = (int)[indexPath row];
    printf("[menu] config %d\n", g_last_row);
    fflush(0);
    return [UIContextMenuConfiguration
        configurationWithIdentifier:nil
                    previewProvider:nil
                     actionProvider:^UIMenu *(NSArray *suggested) {
        (void)suggested;
        return [self menu];
    }];
}

- (long)collectionView:(UICollectionView *)collectionView
    numberOfItemsInSection:(long)section
{
    (void)collectionView;
    (void)section;
    return 4;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView
            cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    (void)collectionView;
    (void)indexPath;
    UICollectionViewCell *cell = [[UICollectionViewCell alloc]
        initWithFrame:CGRectMake(0, 0, 100, 100)];
    cell.backgroundColor =
        [UIColor colorWithRed:0.10 green:0.60 blue:0.70 alpha:1.0];
    return cell;
}

- (UIContextMenuConfiguration *)collectionView:(UICollectionView *)collectionView
    contextMenuConfigurationForItemAtIndexPath:(NSIndexPath *)indexPath
                                        point:(CGPoint)point
{
    (void)collectionView;
    (void)point;
    printf("[menu] config item %d\n", (int)[indexPath row]);
    fflush(0);
    return [UIContextMenuConfiguration
        configurationWithIdentifier:nil
                    previewProvider:nil
                     actionProvider:^UIMenu *(NSArray *suggested) {
        (void)suggested;
        UIAction *tag = [UIAction actionWithTitle:@"Tag"
                                           image:nil
                                      identifier:nil
                                         handler:^(UIAction *action) {
            (void)action;
            printf("[menu] tag\n");
            fflush(0);
        }];
        id children[1] = { tag };
        return [UIMenu menuWithTitle:nil
                            children:[NSArray arrayWithObjects:children
                                                           count:1]];
    }];
}

- (UIContextMenuConfiguration *)contextMenuInteraction:
    (UIContextMenuInteraction *)interaction
    configurationForMenuAtLocation:(CGPoint)location
{
    (void)interaction;
    (void)location;
    printf("[menu] config generic\n");
    fflush(0);
    return [UIContextMenuConfiguration
        configurationWithIdentifier:nil
                    previewProvider:nil
                     actionProvider:^UIMenu *(NSArray *suggested) {
        (void)suggested;
        return [self pingMenu];
    }];
}
@end

@interface MenuSceneDelegate : UIResponder <UIWindowSceneDelegate>
@property(nonatomic, retain) UIWindow *window;
@end

@interface MenuAppDelegate : UIResponder <UIApplicationDelegate>
@end

@implementation MenuAppDelegate
- (UISceneConfiguration *)application:(UIApplication *)application
    configurationForConnectingSceneSession:(UISceneSession *)session
    options:(UISceneConnectionOptions *)connectionOptions
{
    (void)application; (void)session; (void)connectionOptions;
    UISceneConfiguration *configuration = [[UISceneConfiguration alloc]
        initWithName:@"Default Configuration"
         sessionRole:UIWindowSceneSessionRoleApplication];
    configuration.delegateClass = [MenuSceneDelegate class];
    return configuration;
}
@end

@implementation MenuSceneDelegate
- (void)scene:(UIScene *)scene
    willConnectToSession:(UISceneSession *)session
                 options:(UISceneConnectionOptions *)connectionOptions
{
    (void)session; (void)connectionOptions;
    self.window = [[UIWindow alloc] initWithWindowScene:(UIWindowScene *)scene];
    self.window.frame = [[UIScreen mainScreen] bounds];
    self.window.rootViewController = [[MenuController alloc] init];
    [self.window makeKeyAndVisible];
}
@end

int main(int argc, char **argv)
{
    @autoreleasepool
    {
        return UIApplicationMain(argc, argv, nil, @"MenuAppDelegate");
    }
}
