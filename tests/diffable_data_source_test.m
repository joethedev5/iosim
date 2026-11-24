/* NSDiffableDataSourceSnapshot section/item bookkeeping and mutation, and
 * the table/collection diffable data sources driving cell providers. */
#include "UIKitStub.h"

extern int printf(const char *fmt, ...);
extern int fflush(void *stream);

static void print_id(const char *label, id value)
{
    printf("[diff] %s %s\n", label,
           value ? [value UTF8String] : "(nil)");
    fflush(0);
}

int main(void)
{
    NSDiffableDataSourceSnapshot *snapshot =
        [[NSDiffableDataSourceSnapshot alloc] init];
    [snapshot appendSectionsWithIdentifiers:@[@"S1", @"S2"]];
    [snapshot appendItemsWithIdentifiers:@[@"a1", @"a2"]
           intoSectionWithIdentifier:@"S1"];
    [snapshot appendItemsWithIdentifiers:@[@"b1"]
           intoSectionWithIdentifier:@"S2"];
    printf("[diff] snapshot %ld %ld\n", [snapshot numberOfSections],
           [snapshot numberOfItems]);
    printf("[diff] s1 %ld\n", [snapshot numberOfItemsInSection:@"S1"]);
    printf("[diff] index b1 %ld\n", [snapshot indexOfItemIdentifier:@"b1"]);
    print_id("section a2",
             [snapshot sectionIdentifierForSectionContainingItemIdentifier:
                           @"a2"]);

    [snapshot insertItemsWithIdentifiers:@[@"c1"]
              afterItemWithIdentifier:@"a1"];
    [snapshot insertItemsWithIdentifiers:@[@"c2"]
             beforeItemWithIdentifier:@"b1"];
    [snapshot deleteItemsWithIdentifiers:@[@"a2"]];
    [snapshot moveItemWithIdentifier:@"c1" beforeItemWithIdentifier:@"a1"];
    [snapshot appendItemsWithIdentifiers:@[@"d1"]
           intoSectionWithIdentifier:@"S2"];
    [snapshot reloadItemsWithIdentifiers:@[@"a1"]];
    [snapshot deleteSectionsWithIdentifiers:@[@"S2"]];
    printf("[diff] final %ld %ld\n", [snapshot numberOfSections],
           [snapshot numberOfItems]);
    NSArray *finalItems =
        [snapshot itemIdentifiersInSectionWithIdentifier:@"S1"];
    for (unsigned long i = 0; i < [finalItems count]; i++)
        printf("[diff] finalitem %ld %s\n", (long)i,
               [[finalItems objectAtIndex:i] UTF8String]);
    fflush(0);

    UITableView *table =
        [[UITableView alloc] initWithFrame:CGRectMake(0, 0, 320, 400)
                                      style:UITableViewStylePlain];
    UITableViewDiffableDataSource *tableSource =
        [[UITableViewDiffableDataSource alloc]
            initWithTableView:table
                 cellProvider:^id(UITableView *tableView,
                                  NSIndexPath *indexPath, id item) {
        (void)indexPath;
        UITableViewCell *cell =
            [tableView dequeueReusableCellWithIdentifier:@"diff"];
        if (!cell)
            cell = [[UITableViewCell alloc]
                initWithStyle:UITableViewCellStyleDefault
              reuseIdentifier:@"diff"];
        cell.textLabel.text = item;
        return cell;
    }];
    table.dataSource = tableSource;
    [tableSource applySnapshot:snapshot animatingDifferences:NO];
    printf("[diff] table %ld %ld\n",
           [tableSource numberOfSectionsInTableView:table],
           [tableSource tableView:table numberOfRowsInSection:0]);
    NSIndexPath *path = [NSIndexPath indexPathForRow:1 inSection:0];
    print_id("table id", [tableSource itemIdentifierForIndexPath:path]);
    NSIndexPath *tableFound = [tableSource indexPathForItemIdentifier:@"c1"];
    printf("[diff] table path %ld %ld\n",
           tableFound ? [tableFound row] : -1,
           tableFound ? [tableFound section] : -1);
    UITableViewCell *cell =
        [tableSource tableView:table cellForRowAtIndexPath:path];
    id cellText = cell ? cell.textLabel.text : nil;
    printf("[diff] table cell %s\n",
           cellText ? [cellText UTF8String] : "(nil)");

    UICollectionViewFlowLayout *layout =
        [[UICollectionViewFlowLayout alloc] init];
    layout.itemSize = CGSizeMake(60, 60);
    UICollectionView *collection =
        [[UICollectionView alloc] initWithFrame:CGRectMake(0, 0, 320, 400)
                  collectionViewLayout:layout];
    [collection registerClass:[UICollectionViewCell class]
        forCellWithReuseIdentifier:@"diffcell"];
    UICollectionViewDiffableDataSource *collectionSource =
        [[UICollectionViewDiffableDataSource alloc]
            initWithCollectionView:collection
                     cellProvider:^id(UICollectionView *view,
                                      NSIndexPath *indexPath, id item) {
        (void)item;
        return [view dequeueReusableCellWithReuseIdentifier:@"diffcell"
                                               forIndexPath:indexPath];
    }];
    collection.dataSource = collectionSource;
    NSDiffableDataSourceSnapshot *grid =
        [[NSDiffableDataSourceSnapshot alloc] init];
    [grid appendSectionsWithIdentifiers:@[@"G1"]];
    [grid appendItemsWithIdentifiers:@[@"g1", @"g2", @"g3"]];
    [collectionSource applySnapshot:grid animatingDifferences:YES];
    printf("[diff] collection %ld %ld\n",
           [collectionSource numberOfSectionsInCollectionView:collection],
           [collectionSource collectionView:collection
                     numberOfItemsInSection:0]);
    NSIndexPath *itemPath = [NSIndexPath indexPathForItem:2 inSection:0];
    print_id("collection id",
             [collectionSource itemIdentifierForIndexPath:itemPath]);
    NSIndexPath *collectionFound =
        [collectionSource indexPathForItemIdentifier:@"g1"];
    printf("[diff] collection path %ld %ld\n",
           collectionFound ? [collectionFound item] : -1,
           collectionFound ? [collectionFound section] : -1);
    UICollectionViewCell *collectionCell =
        [collectionSource collectionView:collection
                   cellForItemAtIndexPath:itemPath];
    printf("[diff] collection cell %d\n",
           collectionCell != nil && collectionCell.reuseIdentifier != nil);
    fflush(0);
    printf("[diff] done\n");
    fflush(0);
    return 0;
}
