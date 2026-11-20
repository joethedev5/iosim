/* UIScrollView fixture: content insets, horizontal paging, and the drag
 * delegate callbacks. A real UIWindow receives synthesized touches, so the
 * same hit-testing and clamping code the simulator UI uses is exercised. */
#import "UIKitStub.h"

extern int printf(const char *fmt, ...);

@interface UIWindow (IOSIMTouchTest)
- (void)dispatchTouchDownX:(int)x y:(int)y;
- (void)dispatchTouchMoveX:(int)x y:(int)y;
- (void)dispatchTouchUpX:(int)x y:(int)y;
@end

@interface ScrollDelegate : NSObject {
@public
    int began;
    int scrolled;
    int will_end;
    int did_end;
}
@end

@implementation ScrollDelegate
- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    (void)scrollView;
    began++;
}
- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    (void)scrollView;
    scrolled++;
}
- (void)scrollViewWillEndDragging:(UIScrollView *)scrollView
                     withVelocity:(CGPoint)velocity
              targetContentOffset:(CGPoint *)targetContentOffset
{
    (void)scrollView;
    (void)velocity;
    will_end++;
    printf("[scroll] target %.0f %.0f\n",
           targetContentOffset->x, targetContentOffset->y);
}
- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView
                  willDecelerate:(BOOL)decelerate
{
    (void)scrollView;
    (void)decelerate;
    did_end++;
}
@end

static int px(double points)
{
    double scale = [[UIScreen mainScreen] scale];
    if (scale <= 0)
        scale = 1.0;
    return (int)(points * scale);
}

int main(void)
{
    UIWindow *window = [[UIWindow alloc]
        initWithFrame:CGRectMake(0, 0, 390, 844)];

    UIScrollView *pages = [[UIScrollView alloc]
        initWithFrame:CGRectMake(0, 100, 300, 200)];
    [pages setContentSize:CGSizeMake(900, 200)];
    [pages setContentInset:UIEdgeInsetsMake(10, 10, 10, 10)];
    [pages setPagingEnabled:YES];
    ScrollDelegate *delegate = [[ScrollDelegate alloc] init];
    [pages setDelegate:delegate];
    [window addSubview:pages];

    [window dispatchTouchDownX:px(250) y:px(200)];
    [window dispatchTouchMoveX:px(180) y:px(200)];
    [window dispatchTouchMoveX:px(50) y:px(200)];
    [window dispatchTouchUpX:px(50) y:px(200)];
    CGPoint pageOffset = [pages contentOffset];
    printf("[scroll] page %.0f dragging %d\n",
           pageOffset.x, [pages isDragging]);
    printf("[scroll] delegate %d %d %d %d\n", delegate->began,
           delegate->scrolled, delegate->will_end, delegate->did_end);

    UIScrollView *vertical = [[UIScrollView alloc]
        initWithFrame:CGRectMake(0, 400, 300, 200)];
    [vertical setContentSize:CGSizeMake(300, 1000)];
    [vertical setContentInset:UIEdgeInsetsMake(50, 0, 20, 0)];
    [window addSubview:vertical];

    [window dispatchTouchDownX:px(150) y:px(500)];
    [window dispatchTouchMoveX:px(150) y:px(-600)];
    [window dispatchTouchUpX:px(150) y:px(-600)];
    CGPoint verticalOffset = [vertical contentOffset];
    UIEdgeInsets insets = [vertical contentInset];
    printf("[scroll] vertical %.0f top %.0f\n",
           verticalOffset.y, insets.top);
    return 0;
}
