/* UIScrollView momentum and animated content offsets. Drives the window's
 * synthetic touch path directly, then advances the UI tick by hand. */
#include "UIKitStub.h"

extern int printf(const char *fmt, ...);
extern int usleep(unsigned int usec);
extern int iosim_scroll_tick(void);

static int scroll_callbacks;
static int end_decelerating_callbacks;
static int end_animation_callbacks;
static int will_decelerate;

@interface ScrollRecorder : NSObject
@end

@implementation ScrollRecorder
- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    (void)scrollView;
    scroll_callbacks++;
}
- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView
                  willDecelerate:(BOOL)decelerate
{
    (void)scrollView;
    will_decelerate = decelerate ? 1 : 0;
}
- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    (void)scrollView;
    end_decelerating_callbacks++;
}
- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView
{
    (void)scrollView;
    end_animation_callbacks++;
}
@end

int main(void)
{
    double scale = [[UIScreen mainScreen] scale];
    if (scale <= 0)
        scale = 3.0;
    UIWindow *window = [[UIWindow alloc]
        initWithFrame:CGRectMake(0, 0, 320, 480)];
    UIScrollView *scroll = [[UIScrollView alloc]
        initWithFrame:CGRectMake(0, 0, 320, 480)];
    ScrollRecorder *recorder = [[ScrollRecorder alloc] init];
    scroll.contentSize = CGSizeMake(320, 2000);
    scroll.delegate = recorder;
    [window addSubview:scroll];

    [window dispatchTouchDownX:(int)(160 * scale) y:(int)(400 * scale)];
    for (int i = 1; i <= 12; i++)
    {
        double y = 400 - i * 25;
        [window dispatchTouchMoveX:(int)(160 * scale) y:(int)(y * scale)];
        usleep(20000);
    }
    [window dispatchTouchUpX:(int)(160 * scale) y:(int)(100 * scale)];
    BOOL released_decelerating = [scroll isDecelerating];
    double released_offset = scroll.contentOffset.y;
    printf("[scroll] released decel=%d will=%d offset=%.0f\n",
           released_decelerating, will_decelerate, released_offset);

    for (int i = 0; i < 150; i++)
    {
        iosim_scroll_tick();
        usleep(16000);
    }
    double stopped_offset = scroll.contentOffset.y;
    printf("[scroll] decelerated end=%d moved=%d stopped=%.0f callbacks=%d\n",
           end_decelerating_callbacks > 0, stopped_offset > released_offset,
           stopped_offset, scroll_callbacks);

    [scroll setContentOffset:CGPointMake(0, 0) animated:NO];
    scroll_callbacks = 0;
    [scroll setContentOffset:CGPointMake(0, 200) animated:YES];
    iosim_scroll_tick();
    double mid = scroll.contentOffset.y;
    for (int i = 0; i < 40; i++)
    {
        iosim_scroll_tick();
        usleep(16000);
    }
    printf("[scroll] animating mid=%d end=%d offset=%.0f animend=%d\n",
           mid > 0 && mid < 200, scroll.contentOffset.y == 200,
           scroll.contentOffset.y, end_animation_callbacks);
    return 0;
}
