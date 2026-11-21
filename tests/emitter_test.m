/* A steady particle fountain: orange cells emitted in all directions from
 * the middle of the screen. */
#include "UIKitStub.h"

extern int printf(const char *fmt, ...);
extern int fflush(void *stream);

@interface EmitterController : UIViewController
@end

@implementation EmitterController
- (void)loadView
{
    UIView *root =
        [[UIView alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    root.backgroundColor = [UIColor blackColor];

    CAEmitterLayer *emitter = [[CAEmitterLayer alloc] init];
    emitter.frame = root.bounds;
    emitter.emitterPosition = CGPointMake(201, 437);
    emitter.birthRate = 1.0;
    emitter.lifetime = 2.0;

    CAEmitterCell *cell = [[CAEmitterCell alloc] init];
    cell.color = [UIColor colorWithRed:1.0 green:0.5 blue:0.0 alpha:1.0];
    cell.birthRate = 30.0;
    cell.lifetime = 2.0;
    cell.velocity = 120.0;
    cell.velocityRange = 40.0;
    cell.emissionRange = 6.283185307179586;
    cell.scale = 0.8;
    cell.scaleRange = 0.4;
    cell.alphaSpeed = -0.3;
    cell.yAcceleration = 40.0;
    emitter.emitterCells = [NSArray arrayWithObject:cell];
    [root.layer addSublayer:emitter];

    self.view = root;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    printf("[emitter] ready\n");
    fflush(0);
}
@end

@interface EmitterSceneDelegate : UIResponder <UIWindowSceneDelegate>
@property(nonatomic, retain) UIWindow *window;
@end

@interface EmitterAppDelegate : UIResponder <UIApplicationDelegate>
@end

@implementation EmitterAppDelegate
- (UISceneConfiguration *)application:(UIApplication *)application
    configurationForConnectingSceneSession:(UISceneSession *)session
    options:(UISceneConnectionOptions *)connectionOptions
{
    (void)application; (void)session; (void)connectionOptions;
    UISceneConfiguration *configuration = [[UISceneConfiguration alloc]
        initWithName:@"Default Configuration"
         sessionRole:UIWindowSceneSessionRoleApplication];
    configuration.delegateClass = [EmitterSceneDelegate class];
    return configuration;
}
@end

@implementation EmitterSceneDelegate
- (void)scene:(UIScene *)scene
    willConnectToSession:(UISceneSession *)session
                 options:(UISceneConnectionOptions *)connectionOptions
{
    (void)session; (void)connectionOptions;
    self.window = [[UIWindow alloc] initWithWindowScene:(UIWindowScene *)scene];
    self.window.frame = [[UIScreen mainScreen] bounds];
    self.window.rootViewController = [[EmitterController alloc] init];
    [self.window makeKeyAndVisible];
}
@end

int main(int argc, char **argv)
{
    @autoreleasepool
    {
        return UIApplicationMain(argc, argv, nil, @"EmitterAppDelegate");
    }
}
