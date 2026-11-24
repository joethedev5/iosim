/* Horizontal UICollectionView flow layout: items fill a column then wrap to
 * the next column, the content grows along x, and hit-testing and rendering
 * follow the scrolled content offset. */
#include "UIKitStub.h"

extern int printf(const char *fmt, ...);
extern int fflush(void *stream);
extern void exit(int status);
extern int iosim_fb_present(const char *path);
extern char *getenv(const char *name);
extern unsigned long long dispatch_time(unsigned long long when,
                                        long long delta);
extern void dispatch_after(unsigned long long when, void *queue,
                           void (^block)(void));
extern void *dispatch_get_main_queue(void);

static int g_hcap_ready;

@interface HCapture : UIView
@end

@implementation HCapture
- (void)drawRect:(CGRect)rect
{
    (void)rect;
    if (!g_hcap_ready)
        return;
    const char *path = getenv("IOSIM_TEST_PNG");
    if (!path)
        return;
    iosim_fb_present(path);
    printf("[hflow] png written\n");
    fflush(0);
    exit(0);
}
@end

@interface HDataSource : NSObject <UICollectionViewDataSource>
@end

@implementation HDataSource
- (long)collectionView:(UICollectionView *)collectionView
    numberOfItemsInSection:(long)section
{
    (void)collectionView;
    (void)section;
    return 10;
}
- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView
            cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    UICollectionViewCell *cell = [collectionView
        dequeueReusableCellWithReuseIdentifier:@"cell"
                              forIndexPath:indexPath];
    [cell.contentView setBackgroundColor:[UIColor whiteColor]];
    return cell;
}
@end

@interface HDelegate : NSObject <UICollectionViewDelegate> {
@public
    long _section;
    long _item;
}
@end

@implementation HDelegate
- (void)collectionView:(UICollectionView *)collectionView
    didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    (void)collectionView;
    _section = [indexPath section];
    _item = [indexPath row];
    printf("[hflow] tap %ld %ld\n", _section, _item);
    fflush(0);
}
@end

@interface HController : UIViewController {
@public
    UICollectionView *_collection;
    HCapture *_capture;
}
@end

@implementation HController
- (void)loadView
{
    UIView *root =
        [[UIView alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    root.backgroundColor = [UIColor blackColor];
    self.view = root;

    UICollectionViewFlowLayout *layout =
        [[UICollectionViewFlowLayout alloc] init];
    layout.itemSize = CGSizeMake(90.0, 60.0);
    layout.minimumInteritemSpacing = 10.0;
    layout.minimumLineSpacing = 5.0;
    layout.sectionInset = UIEdgeInsetsMake(20.0, 10.0, 20.0, 10.0);
    layout.scrollDirection = UICollectionViewScrollDirectionHorizontal;

    _collection = [[UICollectionView alloc] initWithFrame:
        CGRectMake(0, 300, [[UIScreen mainScreen] bounds].size.width, 200)
        collectionViewLayout:layout];
    [_collection registerClass:[UICollectionViewCell class]
        forCellWithReuseIdentifier:@"cell"];
    [_collection setDataSource:[[HDataSource alloc] init]];
    HDelegate *delegate = [[HDelegate alloc] init];
    delegate->_section = -1;
    delegate->_item = -1;
    [_collection setDelegate:delegate];
    [_collection reloadData];
    [root addSubview:_collection];

    NSArray *cells = [_collection visibleCells];
    for (int i = 0; i < (int)[cells count]; i++)
    {
        if (i != 0 && i != 1 && i != 2 && i != 3 && i != 9)
            continue;
        CGRect frame = [(UICollectionViewCell *)[cells objectAtIndex:i] frame];
        printf("[hflow] cell %d %.1f %.1f %.1f %.1f\n", i, frame.origin.x,
               frame.origin.y, frame.size.width, frame.size.height);
    }
    CGSize size = [_collection contentSize];
    printf("[hflow] size %.1f %.1f\n", size.width, size.height);

    [_collection handleTapAtPoint:CGPointMake(155.0, 50.0)];
    printf("[hflow] tapstate %ld %ld\n", delegate->_section, delegate->_item);

    _collection.contentOffset = CGPointMake(60.0, 0.0);
    printf("[hflow] offset %.1f\n", [_collection contentOffset].x);

    _capture = [[HCapture alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    _capture.backgroundColor = [UIColor clearColor];
    [root addSubview:_capture];

    printf("[hflow] ready\n");
    fflush(0);
    dispatch_after(dispatch_time(0, 200 * 1000000LL),
                   dispatch_get_main_queue(), ^{
        printf("[hflow] done\n");
        fflush(0);
        g_hcap_ready = 1;
        [_collection setNeedsDisplay];
        [_capture setNeedsDisplay];
    });
}
@end

@interface HSceneDelegate : UIResponder <UIWindowSceneDelegate>
@property(nonatomic, retain) UIWindow *window;
@end

@interface HAppDelegate : UIResponder <UIApplicationDelegate>
@end

@implementation HAppDelegate
- (UISceneConfiguration *)application:(UIApplication *)application
    configurationForConnectingSceneSession:(UISceneSession *)session
    options:(UISceneConnectionOptions *)connectionOptions
{
    (void)application; (void)session; (void)connectionOptions;
    UISceneConfiguration *configuration = [[UISceneConfiguration alloc]
        initWithName:@"Default Configuration"
         sessionRole:UIWindowSceneSessionRoleApplication];
    configuration.delegateClass = [HSceneDelegate class];
    return configuration;
}
@end

@implementation HSceneDelegate
- (void)scene:(UIScene *)scene
    willConnectToSession:(UISceneSession *)session
                 options:(UISceneConnectionOptions *)connectionOptions
{
    (void)session; (void)connectionOptions;
    self.window = [[UIWindow alloc] initWithWindowScene:(UIWindowScene *)scene];
    self.window.frame = [[UIScreen mainScreen] bounds];
    self.window.rootViewController = [[HController alloc] init];
    [self.window makeKeyAndVisible];
}
@end

int main(int argc, char **argv)
{
    @autoreleasepool
    {
        return UIApplicationMain(argc, argv, nil, @"HAppDelegate");
    }
}
