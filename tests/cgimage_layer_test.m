/* CALayer contents: a layer whose contents is a CGImage renders the image
 * through the software framebuffer, then a capture view writes a PNG. */
#include "UIKitStub.h"

extern int printf(const char *fmt, ...);
extern int fflush(void *stream);
extern int iosim_fb_present(const char *path);
extern char *getenv(const char *name);
extern void exit(int status);

@interface LayerImageView : UIView
@end

@implementation LayerImageView
@end

@interface CaptureView : UIView
@end

@implementation CaptureView
- (void)drawRect:(CGRect)rect
{
    (void)rect;
    const char *path = getenv("IOSIM_TEST_PNG");
    if (!path)
        return;
    iosim_fb_present(path);
    printf("[cg] layer png written\n");
    fflush(0);
    exit(0);
}
@end

@interface LayerController : UIViewController
@end

@implementation LayerController
- (void)loadView
{
    UIView *root =
        [[UIView alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    root.backgroundColor =
        [UIColor colorWithRed:0.04 green:0.06 blue:0.12 alpha:1.0];

    unsigned char cyan[2 * 2 * 4];
    for (int i = 0; i < 4; i++)
    {
        cyan[i * 4 + 0] = 0;
        cyan[i * 4 + 1] = 255;
        cyan[i * 4 + 2] = 255;
        cyan[i * 4 + 3] = 255;
    }
    CGImageRef image = CGImageCreateWithRGBA(cyan, 2, 2);

    UIView *image_view =
        [[LayerImageView alloc] initWithFrame:CGRectMake(40, 100, 200, 120)];
    image_view.layer.contents = (id)image;
    printf("[cg] layer image %d %d valid %d contents %d frame %.0f %.0f %.0f %.0f\n",
           CGImageGetWidth(image), CGImageGetHeight(image),
           iosim_cgimage_is_valid(image),
           iosim_cgimage_is_valid(image_view.layer.contents),
           image_view.frame.origin.x, image_view.frame.origin.y,
           image_view.frame.size.width, image_view.frame.size.height);
    [root addSubview:image_view];

    CaptureView *capture =
        [[CaptureView alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    capture.backgroundColor = [UIColor clearColor];
    [root addSubview:capture];
    self.view = root;
}
@end

@interface SceneDelegate : UIResponder <UIWindowSceneDelegate>
@property(nonatomic, retain) UIWindow *window;
@end

@interface AppDelegate : UIResponder <UIApplicationDelegate>
@end

@implementation AppDelegate
- (UISceneConfiguration *)application:(UIApplication *)application
    configurationForConnectingSceneSession:(UISceneSession *)session
    options:(UISceneConnectionOptions *)options
{
    (void)application; (void)session; (void)options;
    UISceneConfiguration *configuration = [[UISceneConfiguration alloc]
        initWithName:@"Default Configuration"
         sessionRole:UIWindowSceneSessionRoleApplication];
    configuration.delegateClass = [SceneDelegate class];
    return configuration;
}
@end

@implementation SceneDelegate
- (void)scene:(UIScene *)scene
    willConnectToSession:(UISceneSession *)session
                 options:(UISceneConnectionOptions *)connectionOptions
{
    (void)session; (void)connectionOptions;
    self.window = [[UIWindow alloc] initWithWindowScene:(UIWindowScene *)scene];
    self.window.frame = [[UIScreen mainScreen] bounds];
    self.window.rootViewController = [[LayerController alloc] init];
    [self.window makeKeyAndVisible];
}
@end

int main(int argc, char **argv)
{
    @autoreleasepool
    {
        return UIApplicationMain(argc, argv, nil, @"AppDelegate");
    }
}
