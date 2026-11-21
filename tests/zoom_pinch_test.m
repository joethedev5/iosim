/* UIScrollView zoom and two-finger gestures: programmatic zoomScale and
 * zoomToRect, then injected pinch and rotate records through the event FIFO
 * drive UIPinchGestureRecognizer/UIRotationGestureRecognizer and the scroll
 * view's own zooming. */
#include "UIKitStub.h"

extern int printf(const char *fmt, ...);
extern int fflush(void *stream);
extern int iosim_fb_present(const char *path);
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

@interface ZoomController : UIViewController <UIScrollViewDelegate> {
@public
    UIScrollView *_scroll;
    UIView *_content;
    double _lastPinch;
    double _lastRotation;
    int _zoomEvents;
}
@end

@implementation ZoomController
- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView
{
    (void)scrollView;
    return _content;
}
- (void)scrollViewDidZoom:(UIScrollView *)scrollView
{
    (void)scrollView;
    _zoomEvents++;
}
- (void)pinch:(UIPinchGestureRecognizer *)gesture
{
    if (gesture.state == UIGestureRecognizerStateEnded)
    {
        _lastPinch = gesture.scale;
        printf("[zoom] pinch %.2f\n", gesture.scale);
        fflush(0);
    }
}
- (void)rotate:(UIRotationGestureRecognizer *)gesture
{
    if (gesture.state == UIGestureRecognizerStateEnded)
    {
        _lastRotation = gesture.rotation;
        printf("[zoom] rotation %d\n",
               (int)(gesture.rotation * 180.0 / 3.14159265 + 0.5));
        fflush(0);
    }
}
- (void)loadView
{
    UIView *root =
        [[UIView alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    root.backgroundColor =
        [UIColor colorWithRed:0.043 green:0.055 blue:0.102 alpha:1.0];

    UIScrollView *scroll =
        [[UIScrollView alloc] initWithFrame:CGRectMake(0, 100, 402, 400)];
    scroll.backgroundColor =
        [UIColor colorWithRed:0.05 green:0.25 blue:0.12 alpha:1.0];
    scroll.delegate = self;
    scroll.minimumZoomScale = 0.5;
    scroll.maximumZoomScale = 4.0;

    UIView *content =
        [[UIView alloc] initWithFrame:CGRectMake(0, 0, 400, 400)];
    content.backgroundColor =
        [UIColor colorWithRed:0.05 green:0.25 blue:0.12 alpha:1.0];
    UIView *marker =
        [[UIView alloc] initWithFrame:CGRectMake(190, 190, 20, 20)];
    marker.backgroundColor =
        [UIColor colorWithRed:0.90 green:0.10 blue:0.60 alpha:1.0];
    [content addSubview:marker];
    [scroll addSubview:content];
    scroll.contentSize = CGSizeMake(400, 400);
    [root addSubview:scroll];
    _scroll = scroll;
    _content = content;

    UIPinchGestureRecognizer *pinch = [[UIPinchGestureRecognizer alloc]
        initWithTarget:self action:@selector(pinch:)];
    [scroll addGestureRecognizer:pinch];
    UIRotationGestureRecognizer *rotate = [[UIRotationGestureRecognizer alloc]
        initWithTarget:self action:@selector(rotate:)];
    [scroll addGestureRecognizer:rotate];

    [scroll setZoomScale:2.0 animated:NO];
    printf("[zoom] programmatic %d %d\n", scroll.zoomScale == 2.0,
           content.transform.a == 2.0 && content.transform.d == 2.0);
    [scroll zoomToRect:CGRectMake(150, 150, 100, 100) animated:NO];
    printf("[zoom] rect %d %d %d\n", scroll.zoomScale == 4.0,
           (int)(scroll.contentOffset.x + 0.5) == 0,
           (int)(scroll.contentOffset.y + 0.5) == 0);
    [scroll setZoomScale:1.0 animated:NO];
    [scroll setContentOffset:CGPointMake(0, 0)];

    double scale = [[UIScreen mainScreen] scale];
    if (scale <= 0)
        scale = 1.0;
    dispatch_after(dispatch_time(0, 400 * 1000000LL),
                   dispatch_get_main_queue(), ^{
        const char *path = getenv("IOSIM_TEST_PNG1");
        if (path)
            iosim_fb_present(path);
        fflush(0);
    });

    dispatch_after(dispatch_time(0, 500 * 1000000LL),
                   dispatch_get_main_queue(), ^{
        char line[96];
        int px = (int)(200 * scale + 0.5);
        int py = (int)(300 * scale + 0.5);
        int r = (int)(40 * scale + 0.5);
        snprintf(line, sizeof(line), "pinch1 %d %d %d %d\n", px - r, py,
                 px + r, py);
        send_event(line);
        r = (int)(60 * scale + 0.5);
        snprintf(line, sizeof(line), "pinch2 %d %d %d %d\n", px - r, py,
                 px + r, py);
        send_event(line);
        r = (int)(80 * scale + 0.5);
        snprintf(line, sizeof(line), "pinch3 %d %d %d %d\n", px - r, py,
                 px + r, py);
        send_event(line);
        printf("[zoom] pinched\n");
        fflush(0);
    });

    dispatch_after(dispatch_time(0, 900 * 1000000LL),
                   dispatch_get_main_queue(), ^{
        printf("[zoom] scroll %.2f\n", _scroll.zoomScale);
        printf("[zoom] didzoom %d\n", _zoomEvents > 0 ? 1 : 0);
        const char *path = getenv("IOSIM_TEST_PNG2");
        if (path)
            iosim_fb_present(path);
        fflush(0);
    });

    dispatch_after(dispatch_time(0, 1000 * 1000000LL),
                   dispatch_get_main_queue(), ^{
        char line[96];
        int px = (int)(200 * scale + 0.5);
        int py = (int)(300 * scale + 0.5);
        int r = (int)(40 * scale + 0.5);
        int a45x = (int)(r * 0.7071 + 0.5);
        int a45y = a45x;
        snprintf(line, sizeof(line), "rotate1 %d %d %d %d\n", px - r, py,
                 px + r, py);
        send_event(line);
        snprintf(line, sizeof(line), "rotate2 %d %d %d %d\n", px - a45x,
                 py - a45y, px + a45x, py + a45y);
        send_event(line);
        snprintf(line, sizeof(line), "rotate3 %d %d %d %d\n", px, py - r,
                 px, py + r);
        send_event(line);
        printf("[zoom] rotated\n");
        fflush(0);
    });

    dispatch_after(dispatch_time(0, 1300 * 1000000LL),
                   dispatch_get_main_queue(), ^{
        printf("[zoom] done %d %d\n", _lastPinch > 1.9 && _lastPinch < 2.1,
               _lastRotation > 1.5 && _lastRotation < 1.65);
        printf("[zoom] png written\n");
        fflush(0);
        exit(0);
    });

    self.view = root;
}
@end

@interface ZoomSceneDelegate : UIResponder <UIWindowSceneDelegate>
@property(nonatomic, retain) UIWindow *window;
@end

@interface ZoomAppDelegate : UIResponder <UIApplicationDelegate>
@end

@implementation ZoomAppDelegate
- (UISceneConfiguration *)application:(UIApplication *)application
    configurationForConnectingSceneSession:(UISceneSession *)session
    options:(UISceneConnectionOptions *)connectionOptions
{
    (void)application; (void)session; (void)connectionOptions;
    UISceneConfiguration *configuration = [[UISceneConfiguration alloc]
        initWithName:@"Default Configuration"
         sessionRole:UIWindowSceneSessionRoleApplication];
    configuration.delegateClass = [ZoomSceneDelegate class];
    return configuration;
}
@end

@implementation ZoomSceneDelegate
- (void)scene:(UIScene *)scene
    willConnectToSession:(UISceneSession *)session
                 options:(UISceneConnectionOptions *)connectionOptions
{
    (void)session; (void)connectionOptions;
    self.window = [[UIWindow alloc] initWithWindowScene:(UIWindowScene *)scene];
    self.window.frame = [[UIScreen mainScreen] bounds];
    self.window.rootViewController = [[ZoomController alloc] init];
    [self.window makeKeyAndVisible];
}
@end

int main(int argc, char **argv)
{
    @autoreleasepool
    {
        return UIApplicationMain(argc, argv, nil, @"ZoomAppDelegate");
    }
}
