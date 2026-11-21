/* UIGraphicsImageRenderer draws a blue field with a red square, shows it in
 * a UIImageView, and writes a green PNG to disk. */
#include "UIKitStub.h"

extern int printf(const char *fmt, ...);
extern int fflush(void *stream);

@interface RendererController : UIViewController
@end

@implementation RendererController
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
        [[UIGraphicsImageRenderer alloc] initWithSize:CGSizeMake(100, 60)
                                               format:format];
    UIImage *image = [renderer imageWithActions:^(
        UIGraphicsImageRendererContext *context) {
        CGContextRef ctx = [context CGContext];
        CGContextSetRGBFillColor(ctx, 0.0, 0.0, 1.0, 1.0);
        CGContextFillRect(ctx, CGRectMake(0, 0, 100, 60));
        CGContextSetRGBFillColor(ctx, 1.0, 0.0, 0.0, 1.0);
        CGContextFillRect(ctx, CGRectMake(10, 10, 40, 40));
    }];
    UIImageView *view = [[UIImageView alloc] initWithImage:image];
    view.frame = CGRectMake(100, 300, 100, 60);
    [root addSubview:view];
    self.view = root;

    UIGraphicsImageRenderer *small =
        [[UIGraphicsImageRenderer alloc] initWithSize:CGSizeMake(40, 40)
                                               format:format];
    NSData *png = [small PNGDataWithActions:^(
        UIGraphicsImageRendererContext *context) {
        CGContextRef ctx = [context CGContext];
        CGContextSetRGBFillColor(ctx, 0.0, 1.0, 0.0, 1.0);
        CGContextFillRect(ctx, CGRectMake(0, 0, 40, 40));
    }];
    BOOL written = png ? [png writeToFile:@"/tmp/iosim-image-renderer.png"
                               atomically:YES] : NO;
    printf("[renderer] png %lu written %d\n",
           png ? [png length] : 0UL, written ? 1 : 0);
    printf("[renderer] ready\n");
    fflush(0);
}
@end

@interface RendererSceneDelegate : UIResponder <UIWindowSceneDelegate>
@property(nonatomic, retain) UIWindow *window;
@end

@interface RendererAppDelegate : UIResponder <UIApplicationDelegate>
@end

@implementation RendererAppDelegate
- (UISceneConfiguration *)application:(UIApplication *)application
    configurationForConnectingSceneSession:(UISceneSession *)session
    options:(UISceneConnectionOptions *)connectionOptions
{
    (void)application; (void)session; (void)connectionOptions;
    UISceneConfiguration *configuration = [[UISceneConfiguration alloc]
        initWithName:@"Default Configuration"
         sessionRole:UIWindowSceneSessionRoleApplication];
    configuration.delegateClass = [RendererSceneDelegate class];
    return configuration;
}
@end

@implementation RendererSceneDelegate
- (void)scene:(UIScene *)scene
    willConnectToSession:(UISceneSession *)session
                 options:(UISceneConnectionOptions *)connectionOptions
{
    (void)session; (void)connectionOptions;
    self.window = [[UIWindow alloc] initWithWindowScene:(UIWindowScene *)scene];
    self.window.frame = [[UIScreen mainScreen] bounds];
    self.window.rootViewController = [[RendererController alloc] init];
    [self.window makeKeyAndVisible];
}
@end

int main(int argc, char **argv)
{
    @autoreleasepool
    {
        return UIApplicationMain(argc, argv, nil, @"RendererAppDelegate");
    }
}
