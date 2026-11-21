/* Collection supplementary views: a flow layout's header and footer sizes
 * place reusable header/footer views around each section and the content
 * size accounts for them. */
#include "UIKitStub.h"

extern int printf(const char *fmt, ...);
extern int fflush(void *stream);

@interface SuppHeader : UICollectionReusableView
@end
@implementation SuppHeader
@end

@interface SuppFooter : UICollectionReusableView
@end
@implementation SuppFooter
@end

@interface SuppSource : NSObject <UICollectionViewDataSource> {
@public
    UICollectionReusableView *_header;
    UICollectionReusableView *_footer;
    long _headerSection;
    long _footerSection;
}
@end

@implementation SuppSource
- (long)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    (void)collectionView;
    return 1;
}
- (long)collectionView:(UICollectionView *)collectionView
    numberOfItemsInSection:(long)section
{
    (void)collectionView;
    (void)section;
    return 2;
}
- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView
            cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    UICollectionViewCell *cell = [collectionView
        dequeueReusableCellWithReuseIdentifier:@"cell"
                              forIndexPath:indexPath];
    cell.contentView.backgroundColor =
        [UIColor colorWithRed:0.8 green:0.2 blue:0.2 alpha:1.0];
    return cell;
}
- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView
    viewForSupplementaryElementOfKind:(id)kind
                          atIndexPath:(NSIndexPath *)indexPath
{
    if (kind == UICollectionElementKindSectionHeader)
    {
        SuppHeader *header = [collectionView
            dequeueReusableSupplementaryViewOfKind:kind
                               withReuseIdentifier:@"header"
                                      forIndexPath:indexPath];
        header.backgroundColor =
            [UIColor colorWithRed:0.2 green:0.8 blue:0.2 alpha:1.0];
        _header = header;
        _headerSection = [indexPath section];
        return header;
    }
    SuppFooter *footer = [collectionView
        dequeueReusableSupplementaryViewOfKind:kind
                           withReuseIdentifier:@"footer"
                                  forIndexPath:indexPath];
    footer.backgroundColor =
        [UIColor colorWithRed:0.2 green:0.2 blue:0.8 alpha:1.0];
    _footer = footer;
    _footerSection = [indexPath section];
    return footer;
}
@end

int main(void)
{
    @autoreleasepool
    {
        UICollectionViewFlowLayout *layout =
            [[UICollectionViewFlowLayout alloc] init];
        layout.itemSize = CGSizeMake(80, 80);
        layout.minimumInteritemSpacing = 10;
        layout.minimumLineSpacing = 10;
        layout.sectionInset = UIEdgeInsetsMake(10, 10, 10, 10);
        layout.headerReferenceSize = CGSizeMake(0, 40);
        layout.footerReferenceSize = CGSizeMake(0, 30);

        UICollectionView *collection = [[UICollectionView alloc]
            initWithFrame:CGRectMake(0, 0, 390, 600)
            collectionViewLayout:layout];
        SuppSource *source = [[SuppSource alloc] init];
        collection.dataSource = source;
        [collection registerClass:[UICollectionViewCell class]
            forCellWithReuseIdentifier:@"cell"];
        [collection registerClass:[SuppHeader class]
            forSupplementaryViewOfKind:UICollectionElementKindSectionHeader
                   withReuseIdentifier:@"header"];
        [collection registerClass:[SuppFooter class]
            forSupplementaryViewOfKind:UICollectionElementKindSectionFooter
                   withReuseIdentifier:@"footer"];
        [collection reloadData];

        CGRect header = [source->_header frame];
        CGRect footer = [source->_footer frame];
        printf("[supp] frames %.0f %.0f %.0f %.0f %.0f %.0f %.0f %.0f\n",
               header.origin.x, header.origin.y, header.size.width,
               header.size.height, footer.origin.x, footer.origin.y,
               footer.size.width, footer.size.height);
        printf("[supp] sections %ld %ld content %.0f subviews %lu\n",
               source->_headerSection, source->_footerSection,
               [collection contentSize].height,
               (unsigned long)[[collection subviews] count]);
        printf("[supp] classes %d %d\n",
               [source->_header isKindOfClass:[SuppHeader class]],
               [source->_footer isKindOfClass:[SuppFooter class]]);
        fflush(0);
    }
    return 0;
}
