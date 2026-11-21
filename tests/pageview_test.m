/* UIPageViewController and child view controller containment. */
#include "UIKitStub.h"

extern int printf(const char *fmt, ...);
extern int fflush(void *stream);

@interface PageChildController : UIViewController
@property(nonatomic, retain) UIColor *color;
@end

@implementation PageChildController
- (void)loadView
{
    UIView *root =
        [[UIView alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    root.backgroundColor = _color;
    self.view = root;
}
@end

@interface PageController : UIViewController
@property(nonatomic, retain) UIPageViewController *pager;
@property(nonatomic, retain) PageChildController *second;
@end

@implementation PageController
- (void)loadView
{
    UIView *root =
        [[UIView alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    root.backgroundColor = [UIColor blackColor];

    PageChildController *first = [[PageChildController alloc] init];
    first.color = [UIColor redColor];
    PageChildController *second = [[PageChildController alloc] init];
    second.color = [UIColor greenColor];
    PageChildController *third = [[PageChildController alloc] init];
    third.color = [UIColor blueColor];
    self.second = second;

    self.pager = [[UIPageViewController alloc]
        initWithTransitionStyle:UIPageViewControllerTransitionStyleScroll
          navigationOrientation:
              UIPageViewControllerNavigationOrientationHorizontal
                        options:nil];
    [self addChildViewController:self.pager];
    [self.pager setViewControllers:[NSArray arrayWithObject:first]
                         direction:UIPageViewControllerNavigationDirectionForward
                          animated:NO
                        completion:nil];
    UIView *pageView = [self.pager view];
    pageView.frame = root.bounds;
    [root addSubview:pageView];

    printf("[page] pages %lu children %lu parent %d root %d\n",
           (unsigned long)[[self.pager viewControllers] count],
           (unsigned long)[[self children] count],
           [first parentViewController] == self.pager,
           [self.pager parentViewController] == self);

    self.view = root;
    [NSTimer scheduledTimerWithTimeInterval:0.2 target:self
        selector:@selector(advance) userInfo:nil repeats:NO];
    printf("[page] ready\n");
    fflush(0);
}
- (void)advance
{
    [self.pager setViewControllers:[NSArray arrayWithObject:self.second]
                         direction:UIPageViewControllerNavigationDirectionForward
                          animated:NO
                        completion:^(BOOL finished) {
        printf("[page] next %lu super %d done %d\n",
               (unsigned long)[[self.pager viewControllers] count],
               [[self.second view] superview] == [self.pager view],
               finished);
        fflush(0);
    }];
}
@end

@interface PageSceneDelegate : UIResponder <UIWindowSceneDelegate>
@property(nonatomic, retain) UIWindow *window;
@end

@interface PageAppDelegate : UIResponder <UIApplicationDelegate>
@end

@implementation PageAppDelegate
- (UISceneConfiguration *)application:(UIApplication *)application
    configurationForConnectingSceneSession:(UISceneSession *)session
    options:(UISceneConnectionOptions *)connectionOptions
{
    (void)application; (void)session; (void)connectionOptions;
    UISceneConfiguration *configuration = [[UISceneConfiguration alloc]
        initWithName:@"Default Configuration"
         sessionRole:UIWindowSceneSessionRoleApplication];
    configuration.delegateClass = [PageSceneDelegate class];
    return configuration;
}
@end

@implementation PageSceneDelegate
- (void)scene:(UIScene *)scene
    willConnectToSession:(UISceneSession *)session
                 options:(UISceneConnectionOptions *)connectionOptions
{
    (void)session; (void)connectionOptions;
    self.window = [[UIWindow alloc] initWithWindowScene:(UIWindowScene *)scene];
    self.window.frame = [[UIScreen mainScreen] bounds];
    self.window.rootViewController = [[PageController alloc] init];
    [self.window makeKeyAndVisible];
}
@end

int main(int argc, char **argv)
{
    @autoreleasepool
    {
        return UIApplicationMain(argc, argv, nil, @"PageAppDelegate");
    }
}
