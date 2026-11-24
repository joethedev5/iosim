/* Eight orange dots around a ring: one white sublayer replicated with a 45
 * degree instance transform and an orange instance color. */
#include "UIKitStub.h"

extern int printf(const char *fmt, ...);
extern int fflush(void *stream);

@interface ReplicatorController : UIViewController
@end

@implementation ReplicatorController
- (void)loadView
{
    UIView *root =
        [[UIView alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    root.backgroundColor = [UIColor blackColor];

    CAReplicatorLayer *rep = [[CAReplicatorLayer alloc] init];
    rep.frame = CGRectMake(101, 337, 200, 200);
    rep.instanceCount = 8;
    rep.instanceTransform = CATransform3DMakeRotation(
        0.7853981633974483, 0, 0, 1);
    rep.instanceColor =
        [UIColor colorWithRed:1.0 green:0.5 blue:0.0 alpha:1.0];

    CALayer *dot = [[CALayer alloc] init];
    dot.frame = CGRectMake(90, 0, 20, 20);
    dot.backgroundColor = [UIColor whiteColor];
    dot.cornerRadius = 10;
    [rep addSublayer:dot];
    [root.layer addSublayer:rep];

    /* A translated row where each copy shifts one channel further. */
    CAReplicatorLayer *row = [[CAReplicatorLayer alloc] init];
    row.frame = CGRectMake(60, 600, 240, 40);
    row.instanceCount = 4;
    row.instanceTransform = CATransform3DMakeTranslation(60, 0, 0);
    row.instanceColor =
        [UIColor colorWithRed:1.0 green:0.0 blue:0.0 alpha:1.0];
    row.instanceBlueOffset = 0.15;
    CALayer *bar = [[CALayer alloc] init];
    bar.frame = CGRectMake(0, 10, 20, 20);
    bar.backgroundColor = [UIColor whiteColor];
    bar.cornerRadius = 10;
    [row addSublayer:bar];
    [root.layer addSublayer:row];

    /* A staggered row: three copies of one bar, each 2.5 s behind the last,
     * with a six-second fade so the copies show different phases. */
    CAReplicatorLayer *delayRow = [[CAReplicatorLayer alloc] init];
    delayRow.frame = CGRectMake(60, 700, 240, 60);
    delayRow.instanceCount = 3;
    delayRow.instanceDelay = 2.5;
    delayRow.instanceTransform = CATransform3DMakeTranslation(70, 0, 0);
    CALayer *pulse = [[CALayer alloc] init];
    pulse.frame = CGRectMake(10, 10, 30, 40);
    pulse.backgroundColor = [UIColor whiteColor];
    pulse.cornerRadius = 6;
    CABasicAnimation *fade =
        [CABasicAnimation animationWithKeyPath:@"opacity"];
    fade.fromValue = [NSNumber numberWithDouble:0.0];
    fade.toValue = [NSNumber numberWithDouble:1.0];
    fade.duration = 6.0;
    fade.fillMode = @"backwards";
    fade.removedOnCompletion = NO;
    [pulse addAnimation:fade forKey:@"fade"];
    [delayRow addSublayer:pulse];
    [root.layer addSublayer:delayRow];

    self.view = root;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    printf("[replicator] ready\n");
    fflush(0);
}
@end

@interface ReplicatorSceneDelegate : UIResponder <UIWindowSceneDelegate>
@property(nonatomic, retain) UIWindow *window;
@end

@interface ReplicatorAppDelegate : UIResponder <UIApplicationDelegate>
@end

@implementation ReplicatorAppDelegate
- (UISceneConfiguration *)application:(UIApplication *)application
    configurationForConnectingSceneSession:(UISceneSession *)session
    options:(UISceneConnectionOptions *)connectionOptions
{
    (void)application; (void)session; (void)connectionOptions;
    UISceneConfiguration *configuration = [[UISceneConfiguration alloc]
        initWithName:@"Default Configuration"
         sessionRole:UIWindowSceneSessionRoleApplication];
    configuration.delegateClass = [ReplicatorSceneDelegate class];
    return configuration;
}
@end

@implementation ReplicatorSceneDelegate
- (void)scene:(UIScene *)scene
    willConnectToSession:(UISceneSession *)session
                 options:(UISceneConnectionOptions *)connectionOptions
{
    (void)session; (void)connectionOptions;
    self.window = [[UIWindow alloc] initWithWindowScene:(UIWindowScene *)scene];
    self.window.frame = [[UIScreen mainScreen] bounds];
    self.window.rootViewController = [[ReplicatorController alloc] init];
    [self.window makeKeyAndVisible];
}
@end

int main(int argc, char **argv)
{
    @autoreleasepool
    {
        return UIApplicationMain(argc, argv, nil,
                                 @"ReplicatorAppDelegate");
    }
}
