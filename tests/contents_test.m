/* CALayer contentsGravity and contentsRect: a 2:1 red/blue image is
 * aspect-fitted into a square layer and cropped to its blue half in another. */
#include "UIKitStub.h"

extern int printf(const char *fmt, ...);
extern int fflush(void *stream);

@interface ContentsController : UIViewController
@end

@implementation ContentsController
- (void)loadView
{
    UIView *root =
        [[UIView alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    root.backgroundColor = [UIColor blackColor];

    UIGraphicsImageRendererFormat *format =
        [UIGraphicsImageRendererFormat defaultFormat];
    format.scale = 1.0;
    format.opaque = YES;
    UIGraphicsImageRenderer *renderer =
        [[UIGraphicsImageRenderer alloc] initWithSize:CGSizeMake(40, 20)
                                               format:format];
    UIImage *image = [renderer imageWithActions:^(
        UIGraphicsImageRendererContext *context) {
        CGContextRef ctx = [context CGContext];
        CGContextSetRGBFillColor(ctx, 1.0, 0.0, 0.0, 1.0);
        CGContextFillRect(ctx, CGRectMake(0, 0, 20, 20));
        CGContextSetRGBFillColor(ctx, 0.0, 0.0, 1.0, 1.0);
        CGContextFillRect(ctx, CGRectMake(20, 0, 20, 20));
    }];

    CALayer *aspect = [[CALayer alloc] init];
    aspect.frame = CGRectMake(100, 300, 100, 100);
    aspect.contents = image;
    aspect.contentsGravity = @"resizeAspect";
    [root.layer addSublayer:aspect];

    CALayer *crop = [[CALayer alloc] init];
    crop.frame = CGRectMake(100, 450, 100, 100);
    crop.contents = image;
    crop.contentsRect = CGRectMake(0.5, 0.0, 0.5, 1.0);
    crop.contentsGravity = @"resize";
    [root.layer addSublayer:crop];

    self.view = root;

    UIEdgeInsets insets = root.safeAreaInsets;
    printf("[contents] safe %.0f %.0f\n", insets.top, insets.bottom);

    UIImpactFeedbackGenerator *impact =
        [[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleMedium];
    [impact prepare];
    [impact impactOccurred];
    UISelectionFeedbackGenerator *selection =
        [[UISelectionFeedbackGenerator alloc] init];
    [selection selectionChanged];
    UINotificationFeedbackGenerator *notification =
        [[UINotificationFeedbackGenerator alloc] init];
    [notification notificationOccurred:UINotificationFeedbackTypeSuccess];
    printf("[contents] haptics ok\n");

    UIScreen *screen = [UIScreen mainScreen];
    CGRect native = [screen nativeBounds];
    printf("[contents] screen %.0f %.0f %.0f %.0f\n", native.size.width,
           native.size.height, [screen nativeScale], [screen brightness]);

    UIApplication *app = [UIApplication sharedApplication];
    app.idleTimerDisabled = YES;
    printf("[contents] idle %d\n", app.idleTimerDisabled ? 1 : 0);
    printf("[contents] canopen %d\n", [app canOpenURL:@"https://example.com"] ? 1 : 0);
    [app openURL:@"https://example.com" options:nil
        completionHandler:^(BOOL success) {
            printf("[contents] open %d\n", success ? 1 : 0);
            fflush(0);
        }];

    printf("[contents] ready\n");
    fflush(0);
}
@end

@interface ContentsSceneDelegate : UIResponder <UIWindowSceneDelegate>
@property(nonatomic, retain) UIWindow *window;
@end

@interface ContentsAppDelegate : UIResponder <UIApplicationDelegate>
@end

@implementation ContentsAppDelegate
- (UISceneConfiguration *)application:(UIApplication *)application
    configurationForConnectingSceneSession:(UISceneSession *)session
    options:(UISceneConnectionOptions *)connectionOptions
{
    (void)application; (void)session; (void)connectionOptions;
    UISceneConfiguration *configuration = [[UISceneConfiguration alloc]
        initWithName:@"Default Configuration"
         sessionRole:UIWindowSceneSessionRoleApplication];
    configuration.delegateClass = [ContentsSceneDelegate class];
    return configuration;
}
@end

@implementation ContentsSceneDelegate
- (void)scene:(UIScene *)scene
    willConnectToSession:(UISceneSession *)session
                 options:(UISceneConnectionOptions *)connectionOptions
{
    (void)session; (void)connectionOptions;
    self.window = [[UIWindow alloc] initWithWindowScene:(UIWindowScene *)scene];
    self.window.frame = [[UIScreen mainScreen] bounds];
    self.window.rootViewController = [[ContentsController alloc] init];
    [self.window makeKeyAndVisible];
}
@end

int main(int argc, char **argv)
{
    @autoreleasepool
    {
        return UIApplicationMain(argc, argv, nil, @"ContentsAppDelegate");
    }
}
