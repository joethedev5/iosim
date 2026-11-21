/* CALayer.transform: the 2D part of CATransform3D rotates, scales and
 * translates a layer through the offscreen composite path. Samples verify
 * rotated corners disappear, scaled extents grow and translation moves the
 * whole layer. */
#include "UIKitStub.h"

extern int printf(const char *fmt, ...);
extern int fflush(void *stream);
extern int iosim_fb_present(const char *path);
extern char *getenv(const char *name);
extern void exit(int status);

@interface TransformCaptureView : UIView
@end

@implementation TransformCaptureView
- (void)drawRect:(CGRect)rect
{
    (void)rect;
    const char *path = getenv("IOSIM_TEST_PNG");
    if (!path)
        return;
    iosim_fb_present(path);
    printf("[tf] png written\n");
    fflush(0);
    exit(0);
}
@end

@interface TransformController : UIViewController
@end

@implementation TransformController
- (void)loadView
{
    UIView *root =
        [[UIView alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    root.backgroundColor =
        [UIColor colorWithRed:0.04 green:0.06 blue:0.12 alpha:1.0];

    CATransform3D rotation = CATransform3DMakeRotation(
        0.7853981633974483, 0, 0, 1);
    CATransform3D translation = CATransform3DMakeTranslation(10, 20, 0);
    CATransform3D identity = CATransform3DIdentityValue();
    CATransform3D concat = CATransform3DConcat(rotation, translation);
    printf("[tf] identity %d rot %d translate %d concat %d\n",
           CATransform3DIsIdentity(identity),
           rotation.m11 > 0.70 && rotation.m11 < 0.72 &&
               rotation.m12 > 0.70 && rotation.m12 < 0.72,
           translation.m41 == 10 && translation.m42 == 20,
           concat.m41 == 10 && concat.m42 == 20);

    CALayer *rotated = [[CALayer alloc] init];
    rotated.frame = CGRectMake(60, 100, 120, 120);
    rotated.backgroundColor =
        [UIColor colorWithRed:1.0 green:0.0 blue:0.0 alpha:1.0];
    rotated.transform = CATransform3DMakeRotation(0.7853981633974483, 0, 0, 1);
    [root.layer addSublayer:rotated];

    CALayer *scaled = [[CALayer alloc] init];
    scaled.frame = CGRectMake(60, 300, 100, 60);
    scaled.backgroundColor =
        [UIColor colorWithRed:0.0 green:0.2 blue:1.0 alpha:1.0];
    scaled.transform = CATransform3DMakeScale(2.0, 1.0, 1.0);
    [root.layer addSublayer:scaled];

    CALayer *plain = [[CALayer alloc] init];
    plain.frame = CGRectMake(60, 480, 100, 60);
    plain.backgroundColor =
        [UIColor colorWithRed:0.0 green:1.0 blue:0.0 alpha:1.0];
    plain.transform = identity;
    [root.layer addSublayer:plain];

    CATransform3D perspective = CATransform3DIdentityValue();
    perspective.m34 = -1.0 / 300.0;
    perspective = CATransform3DRotate(perspective, 0.6, 0, 1, 0);
    CALayer *tilted = [[CALayer alloc] init];
    tilted.frame = CGRectMake(140, 700, 100, 60);
    tilted.backgroundColor =
        [UIColor colorWithRed:1.0 green:0.0 blue:1.0 alpha:1.0];
    tilted.transform = perspective;
    [root.layer addSublayer:tilted];

    CALayer *moved = [[CALayer alloc] init];
    moved.frame = CGRectMake(60, 600, 80, 40);
    moved.backgroundColor =
        [UIColor colorWithRed:1.0 green:1.0 blue:0.0 alpha:1.0];
    moved.transform = CATransform3DMakeTranslation(40, 20, 0);
    [root.layer addSublayer:moved];

    TransformCaptureView *capture = [[TransformCaptureView alloc]
        initWithFrame:[[UIScreen mainScreen] bounds]];
    capture.backgroundColor = [UIColor clearColor];
    [root addSubview:capture];
    self.view = root;
}
@end

@interface TransformSceneDelegate : UIResponder <UIWindowSceneDelegate>
@property(nonatomic, retain) UIWindow *window;
@end

@interface TransformAppDelegate : UIResponder <UIApplicationDelegate>
@end

@implementation TransformAppDelegate
- (UISceneConfiguration *)application:(UIApplication *)application
    configurationForConnectingSceneSession:(UISceneSession *)session
    options:(UISceneConnectionOptions *)options
{
    (void)application; (void)session; (void)options;
    UISceneConfiguration *configuration = [[UISceneConfiguration alloc]
        initWithName:@"Default Configuration"
         sessionRole:UIWindowSceneSessionRoleApplication];
    configuration.delegateClass = [TransformSceneDelegate class];
    return configuration;
}
@end

@implementation TransformSceneDelegate
- (void)scene:(UIScene *)scene
    willConnectToSession:(UISceneSession *)session
                 options:(UISceneConnectionOptions *)connectionOptions
{
    (void)session; (void)connectionOptions;
    self.window = [[UIWindow alloc] initWithWindowScene:(UIWindowScene *)scene];
    self.window.frame = [[UIScreen mainScreen] bounds];
    self.window.rootViewController = [[TransformController alloc] init];
    [self.window makeKeyAndVisible];
}
@end

int main(int argc, char **argv)
{
    @autoreleasepool
    {
        return UIApplicationMain(argc, argv, nil, @"TransformAppDelegate");
    }
}
