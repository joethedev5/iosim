/* UICollectionViewCompositionalLayout: a repeating two-column group, a
 * nested two-column grid and a section provider. Frames are read from the
 * cells; a tap checks that hit-testing uses the same geometry. */
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

static int g_comp_capture_ready;

@interface CompCapture : UIView
@end

@implementation CompCapture
- (void)drawRect:(CGRect)rect
{
    (void)rect;
    if (!g_comp_capture_ready)
        return;
    const char *path = getenv("IOSIM_TEST_PNG");
    if (!path)
        return;
    iosim_fb_present(path);
    printf("[comp] png written\n");
    fflush(0);
    exit(0);
}
@end

@interface CompDataSource : NSObject <UICollectionViewDataSource> {
@public
    long _count;
    long _sections;
}
@end

@implementation CompDataSource
- (long)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    (void)collectionView;
    return _sections;
}
- (long)collectionView:(UICollectionView *)collectionView
    numberOfItemsInSection:(long)section
{
    (void)collectionView;
    (void)section;
    return _count;
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

@interface CompDelegate : NSObject <UICollectionViewDelegate> {
@public
    long _section;
    long _item;
}
@end

@implementation CompDelegate
- (void)collectionView:(UICollectionView *)collectionView
    didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    (void)collectionView;
    _section = [indexPath section];
    _item = [indexPath row];
    printf("[comp] tap %ld %ld\n", _section, _item);
    fflush(0);
}
@end

@interface CompController : UIViewController {
@public
    UICollectionView *_simple;
    UICollectionView *_nested;
    UICollectionView *_provider;
    CompDelegate *_delegate;
    NSCollectionLayoutSection *_providerSection;
    CompCapture *_capture;
}
@end

@implementation CompController
- (NSCollectionLayoutSize *)fractionalSizeWithWidth:(double)width
                                             height:(double)height
{
    return [NSCollectionLayoutSize
        sizeWithWidthDimension:
            [NSCollectionLayoutDimension fractionalWidthDimension:width]
               heightDimension:
            [NSCollectionLayoutDimension fractionalHeightDimension:height]];
}

- (NSCollectionLayoutSize *)fullWidthSizeWithHeight:(double)height
{
    return [NSCollectionLayoutSize
        sizeWithWidthDimension:
            [NSCollectionLayoutDimension fractionalWidthDimension:1.0]
               heightDimension:
            [NSCollectionLayoutDimension absoluteDimension:height]];
}

- (NSCollectionLayoutSection *)twoColumnSection
{
    NSCollectionLayoutItem *item = [NSCollectionLayoutItem
        itemWithLayoutSize:[self fractionalSizeWithWidth:1.0 height:1.0]];
    NSCollectionLayoutGroup *group = [NSCollectionLayoutGroup
        horizontalGroupWithLayoutSize:[self fullWidthSizeWithHeight:80.0]
                    repeatingSubitem:item
                                count:2];
    [group setInterItemSpacing:[NSCollectionLayoutSpacing fixedSpacing:10.0]];
    NSCollectionLayoutSection *section =
        [NSCollectionLayoutSection sectionWithGroup:group];
    [section setInterGroupSpacing:10.0];
    [section setContentInsets:UIEdgeInsetsMake(15.0, 20.0, 15.0, 20.0)];
    return section;
}

- (NSCollectionLayoutSection *)nestedSection
{
    NSCollectionLayoutItem *item = [NSCollectionLayoutItem
        itemWithLayoutSize:[self fractionalSizeWithWidth:1.0 height:0.5]];
    NSCollectionLayoutGroup *column = [NSCollectionLayoutGroup
        verticalGroupWithLayoutSize:[self fractionalSizeWithWidth:0.5
                                                            height:1.0]
                           subitems:@[item, item]];
    NSCollectionLayoutGroup *group = [NSCollectionLayoutGroup
        horizontalGroupWithLayoutSize:[self fullWidthSizeWithHeight:200.0]
                             subitems:@[column, column]];
    NSCollectionLayoutSection *section =
        [NSCollectionLayoutSection sectionWithGroup:group];
    [section setInterGroupSpacing:10.0];
    [section setContentInsets:UIEdgeInsetsMake(15.0, 20.0, 15.0, 20.0)];
    return section;
}

- (UICollectionView *)collectionAtY:(double)y
                             layout:(UICollectionViewLayout *)layout
                             source:(CompDataSource *)source
{
    UICollectionView *collection = [[UICollectionView alloc]
        initWithFrame:CGRectMake(0, y,
                                 [[UIScreen mainScreen] bounds].size.width,
                                 500)
     collectionViewLayout:layout];
    [collection registerClass:[UICollectionViewCell class]
        forCellWithReuseIdentifier:@"cell"];
    [collection setDataSource:source];
    [collection reloadData];
    [self.view addSubview:collection];
    return collection;
}

- (void)printCells:(const char *)name
        collection:(UICollectionView *)collection
             index:(long)index
{
    NSArray *cells = [collection visibleCells];
    if (index < 0 || index >= (long)[cells count])
    {
        printf("[comp] %s %ld missing\n", name, index);
        fflush(0);
        return;
    }
    CGRect frame =
        [(UICollectionViewCell *)[cells objectAtIndex:(unsigned long)index]
            frame];
    printf("[comp] %s %ld %.1f %.1f %.1f %.1f\n", name, index,
           frame.origin.x, frame.origin.y, frame.size.width,
           frame.size.height);
    fflush(0);
}

- (void)printSize:(const char *)name collection:(UICollectionView *)collection
{
    CGSize size = [collection contentSize];
    printf("[comp] %s size %.1f %.1f\n", name, size.width, size.height);
    fflush(0);
}

- (void)loadView
{
    UIView *root =
        [[UIView alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    root.backgroundColor = [UIColor blackColor];
    self.view = root;

    CompDataSource *simpleSource = [[CompDataSource alloc] init];
    simpleSource->_count = 10;
    simpleSource->_sections = 1;
    UICollectionViewCompositionalLayout *simpleLayout =
        [[UICollectionViewCompositionalLayout alloc]
            initWithSection:[self twoColumnSection]];
    _simple = [self collectionAtY:100
                           layout:simpleLayout
                           source:simpleSource];

    CompDataSource *nestedSource = [[CompDataSource alloc] init];
    nestedSource->_count = 8;
    nestedSource->_sections = 1;
    UICollectionViewCompositionalLayout *nestedLayout =
        [[UICollectionViewCompositionalLayout alloc]
            initWithSection:[self nestedSection]];
    _nested = [self collectionAtY:620
                           layout:nestedLayout
                           source:nestedSource];

    _providerSection = [self twoColumnSection];
    CompDataSource *providerSource = [[CompDataSource alloc] init];
    providerSource->_count = 10;
    providerSource->_sections = 2;
    UICollectionViewCompositionalLayout *providerLayout =
        [[UICollectionViewCompositionalLayout alloc]
            initWithSectionProvider:^id(long index) {
                (void)index;
                return _providerSection;
            }];
    _provider = [self collectionAtY:1140
                             layout:providerLayout
                             source:providerSource];

    _delegate = [[CompDelegate alloc] init];
    _delegate->_section = -1;
    _delegate->_item = -1;
    [_simple setDelegate:_delegate];

    printf("[comp] width %.1f\n", [[UIScreen mainScreen] bounds].size.width);
    [self printCells:"simple" collection:_simple index:0];
    [self printCells:"simple" collection:_simple index:1];
    [self printCells:"simple" collection:_simple index:2];
    [self printCells:"simple" collection:_simple index:9];
    [self printSize:"simple" collection:_simple];
    [self printCells:"nested" collection:_nested index:0];
    [self printCells:"nested" collection:_nested index:1];
    [self printCells:"nested" collection:_nested index:2];
    [self printCells:"nested" collection:_nested index:3];
    [self printCells:"nested" collection:_nested index:7];
    [self printSize:"nested" collection:_nested];
    [self printCells:"provider" collection:_provider index:0];
    [self printCells:"provider" collection:_provider index:10];
    [self printCells:"provider" collection:_provider index:19];
    [self printSize:"provider" collection:_provider];

    [_simple handleTapAtPoint:CGPointMake(100.0, 145.0)];
    printf("[comp] tapstate %ld %ld\n", _delegate->_section, _delegate->_item);
    fflush(0);

    _capture = [[CompCapture alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    _capture.backgroundColor = [UIColor clearColor];
    [root addSubview:_capture];

    printf("[comp] ready\n");
    fflush(0);
    dispatch_after(dispatch_time(0, 200 * 1000000LL),
                   dispatch_get_main_queue(), ^{
        printf("[comp] done\n");
        fflush(0);
        g_comp_capture_ready = 1;
        [_capture setNeedsDisplay];
    });
}
@end

@interface CompSceneDelegate : UIResponder <UIWindowSceneDelegate>
@property(nonatomic, retain) UIWindow *window;
@end

@interface CompAppDelegate : UIResponder <UIApplicationDelegate>
@end

@implementation CompAppDelegate
- (UISceneConfiguration *)application:(UIApplication *)application
    configurationForConnectingSceneSession:(UISceneSession *)session
    options:(UISceneConnectionOptions *)connectionOptions
{
    (void)application; (void)session; (void)connectionOptions;
    UISceneConfiguration *configuration = [[UISceneConfiguration alloc]
        initWithName:@"Default Configuration"
         sessionRole:UIWindowSceneSessionRoleApplication];
    configuration.delegateClass = [CompSceneDelegate class];
    return configuration;
}
@end

@implementation CompSceneDelegate
- (void)scene:(UIScene *)scene
    willConnectToSession:(UISceneSession *)session
                 options:(UISceneConnectionOptions *)connectionOptions
{
    (void)session; (void)connectionOptions;
    self.window = [[UIWindow alloc] initWithWindowScene:(UIWindowScene *)scene];
    self.window.frame = [[UIScreen mainScreen] bounds];
    self.window.rootViewController = [[CompController alloc] init];
    [self.window makeKeyAndVisible];
}
@end

int main(int argc, char **argv)
{
    @autoreleasepool
    {
        return UIApplicationMain(argc, argv, nil, @"CompAppDelegate");
    }
}
