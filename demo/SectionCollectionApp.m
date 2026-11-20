#if __has_include(<UIKit/UIKit.h>)
#import <UIKit/UIKit.h>
#else
#import "UIKitStub.h"
#endif

extern int printf(const char *fmt, ...);
extern int fflush(void *stream);

/* Collection view fixture with two sections: the flow layout must stack the
 * second section below the first, one line-space apart, and selection must
 * report the section along with the row. */

@interface SectionCollectionViewController : UIViewController
    <UICollectionViewDataSource, UICollectionViewDelegate> {
    UICollectionView *_collection;
}
@end

@implementation SectionCollectionViewController
- (void)loadView
{
    UIView *view =
        [[UIView alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    view.backgroundColor =
        [UIColor colorWithRed:0.055 green:0.075 blue:0.14 alpha:1.0];

    UICollectionViewFlowLayout *layout =
        [[UICollectionViewFlowLayout alloc] init];
    layout.itemSize = CGSizeMake(80, 80);
    layout.minimumInteritemSpacing = 10;
    layout.minimumLineSpacing = 10;
    layout.sectionInset = UIEdgeInsetsMake(20, 20, 20, 20);

    _collection = [[UICollectionView alloc]
        initWithFrame:CGRectMake(0, 80, view.frame.size.width, 500)
        collectionViewLayout:layout];
    _collection.dataSource = self;
    _collection.delegate = self;
    [_collection registerClass:[UICollectionViewCell class]
        forCellWithReuseIdentifier:@"cell"];
    [view addSubview:_collection];
    self.view = view;
}
- (void)viewDidLoad
{
    [super viewDidLoad];
    [_collection reloadData];
    printf("[sectioncollection] ready\n");
    fflush(0);
}
- (long)numberOfSectionsInCollectionView:
    (UICollectionView *)collectionView
{
    (void)collectionView;
    return 2;
}
- (long)collectionView:(UICollectionView *)collectionView
    numberOfItemsInSection:(long)section
{
    (void)collectionView;
    return section == 0 ? 4 : 3;
}
- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView
            cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    UICollectionViewCell *cell = [collectionView
        dequeueReusableCellWithReuseIdentifier:@"cell"
                              forIndexPath:indexPath];
    if ([indexPath section] == 0)
        cell.contentView.backgroundColor =
            [UIColor colorWithRed:0.90 green:0.45 blue:0.20 alpha:1.0];
    else
        cell.contentView.backgroundColor =
            [UIColor colorWithRed:0.25 green:0.75 blue:0.45 alpha:1.0];

    UILabel *label =
        [[UILabel alloc] initWithFrame:CGRectMake(6, 6, 60, 24)];
    label.text = [NSString stringWithFormat:@"%ld/%ld",
        (long)[indexPath section], (long)[indexPath row]];
    label.textColor = [UIColor whiteColor];
    label.font = [UIFont systemFontOfSize:15];
    [cell.contentView addSubview:label];
    return cell;
}
- (void)collectionView:(UICollectionView *)collectionView
    didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    (void)collectionView;
    printf("[sectioncollection] selected %ld:%ld\n",
        (long)[indexPath section], (long)[indexPath row]);
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
        [UIColor colorWithRed:0.055 green:0.075 blue:0.14 alpha:1.0];
    self.window.rootViewController =
        [[SectionCollectionViewController alloc] init];
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
