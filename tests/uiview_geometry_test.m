/* UIView geometry fixture: center, bounds size, and point/rect conversion
 * through nested superviews and a scroll ancestor's contentOffset. */
#import "UIKitStub.h"

extern int printf(const char *fmt, ...);

int main(void)
{
    UIView *root = [[UIView alloc]
        initWithFrame:CGRectMake(0, 0, 400, 800)];
    UIView *parent = [[UIView alloc]
        initWithFrame:CGRectMake(20, 30, 300, 400)];
    UIView *child = [[UIView alloc]
        initWithFrame:CGRectMake(10, 20, 100, 50)];
    [root addSubview:parent];
    [parent addSubview:child];

    CGPoint center = [child center];
    printf("[geo] center %.0f %.0f\n", center.x, center.y);

    [child setCenter:CGPointMake(100, 100)];
    CGRect frame = [child frame];
    printf("[geo] centered %.0f %.0f\n", frame.origin.x, frame.origin.y);

    [child setBounds:CGRectMake(0, 0, 120, 60)];
    frame = [child frame];
    center = [child center];
    printf("[geo] bounds %.0f %.0f %.0f %.0f center %.0f %.0f\n",
           frame.origin.x, frame.origin.y, frame.size.width,
           frame.size.height, center.x, center.y);

    CGPoint p = [child convertPoint:CGPointMake(5, 5) toView:parent];
    printf("[geo] to parent %.0f %.0f\n", p.x, p.y);
    p = [child convertPoint:CGPointMake(5, 5) toView:root];
    printf("[geo] to root %.0f %.0f\n", p.x, p.y);
    p = [child convertPoint:CGPointMake(35, 55) fromView:root];
    printf("[geo] from root %.0f %.0f\n", p.x, p.y);
    CGRect r = [child convertRect:CGRectMake(5, 5, 100, 50) toView:root];
    printf("[geo] rect %.0f %.0f %.0f %.0f\n", r.origin.x, r.origin.y,
           r.size.width, r.size.height);

    UIScrollView *scroll = [[UIScrollView alloc]
        initWithFrame:CGRectMake(0, 100, 200, 100)];
    [scroll setContentOffset:CGPointMake(10, 20)];
    UIView *item = [[UIView alloc]
        initWithFrame:CGRectMake(5, 6, 30, 30)];
    [scroll addSubview:item];
    [root addSubview:scroll];
    p = [item convertPoint:CGPointMake(1, 1) toView:scroll];
    printf("[geo] scroll %.0f %.0f\n", p.x, p.y);
    p = [item convertPoint:CGPointMake(1, 1) toView:root];
    printf("[geo] scroll root %.0f %.0f\n", p.x, p.y);
    return 0;
}
