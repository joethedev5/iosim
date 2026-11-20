#if __has_include(<UIKit/UIKit.h>)
#import <UIKit/UIKit.h>
#else
#import "UIKitStub.h"
#endif

extern int printf(const char *fmt, ...);
extern int fflush(void *stream);

/* Collection view fixture: a three-column flow layout with reusable cells,
 * tap selection through the delegate, and scrolling content. */

@interface CollectionViewController : UIViewController
    <UICollectionViewDataSource, UICollectionViewDelegate> {
    UICollectionView *_collection;
}
@end

@implementation CollectionViewController
- (void)loadView
{
    UIView *view =
        [[UIView alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    view.backgroundColor =
        [UIColor colorWithRed:0.043 green:0.063 blue:0.125 alpha:1.0];

    UICollectionViewFlowLayout *layout =
        [[UICollectionViewFlowLayout alloc] init];
    layout.itemSize = CGSizeMake(100, 100);
    layout.minimumInteritemSpacing = 12;
    layout.minimumLineSpacing = 12;
    layout.sectionInset = UIEdgeInsetsMake(20, 20, 20, 20);

    _collection = [[UICollectionView alloc]
        initWithFrame:CGRectMake(0, 80, view.frame.size.width, 500)
        collectionViewLayout:layout];
    _collection.dataSource = self;
    _collection.delegate = self;
    [_collection registerClass:[UICollectionViewCell class]
        forCellWithReuseIdentifier:@"cell"];
    [view addSubview:_collection];
    /* Assigning view runs viewDidLoad synchronously, so the collection must
     * already be in the hierarchy when the data source reload happens. */
    self.view = view;
}
- (void)viewDidLoad
{
    [super viewDidLoad];
    [_collection reloadData];
    printf("[collection] ready\n");
    fflush(0);
}
- (long)collectionView:(UICollectionView *)collectionView
    numberOfItemsInSection:(long)section
{
    (void)collectionView;
    (void)section;
    return 20;
}
- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView
            cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    UICollectionViewCell *cell = [collectionView
        dequeueReusableCellWithReuseIdentifier:@"cell"
                              forIndexPath:indexPath];
    double colors[4][3] = {
        { 0.90, 0.30, 0.26 },
        { 0.95, 0.62, 0.20 },
        { 0.30, 0.70, 0.35 },
        { 0.20, 0.55, 0.90 },
    };
    long slot = [indexPath row] % 4;
    cell.contentView.backgroundColor =
        [UIColor colorWithRed:colors[slot][0] green:colors[slot][1]
                        blue:colors[slot][2] alpha:1.0];

    UILabel *label =
        [[UILabel alloc] initWithFrame:CGRectMake(8, 8, 60, 24)];
    label.text = [NSString stringWithFormat:@"%ld", [indexPath row]];
    label.textColor = [UIColor whiteColor];
    label.font = [UIFont systemFontOfSize:16];
    [cell.contentView addSubview:label];
    return cell;
}
- (void)collectionView:(UICollectionView *)collectionView
    didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    (void)collectionView;
    printf("[collection] selected %ld\n", [indexPath row]);
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
        [[CollectionViewController alloc] init];
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
