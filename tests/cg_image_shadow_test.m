/* CGContext image shadows: a red image with a hard blue offset shadow and a
 * green image with a blurred black shadow, both drawn over white. */
#include "UIKitStub.h"

extern int printf(const char *fmt, ...);
extern int fflush(void *stream);
extern void exit(int status);
extern int iosim_fb_present(const char *path);
extern char *getenv(const char *name);
extern unsigned long long dispatch_time(unsigned long long when,
                                        long long delta);
extern void dispatch_after(unsigned long long when, void *queue,
                           void (^block)(void));
extern void *dispatch_get_main_queue(void);

static int g_cg_image_shadow_ready;

@interface ShadowImages : UIView
@end

@implementation ShadowImages
- (void)drawRect:(CGRect)rect
{
    (void)rect;
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    if (!ctx)
        return;
    unsigned char pixels[16 * 16 * 4];
    CGColorRef blue = CGColorCreateGenericRGB(0, 0, 1, 1);
    CGColorRef green = CGColorCreateGenericRGB(0, 1, 0, 1);
    CGColorRef black = CGColorCreateGenericRGB(0, 0, 0, 1);
    for (int i = 0; i < 16 * 16; i++)
    {
        pixels[i * 4 + 0] = 255;
        pixels[i * 4 + 1] = 0;
        pixels[i * 4 + 2] = 0;
        pixels[i * 4 + 3] = 255;
    }
    CGImageRef red_image = CGImageCreateWithRGBA(pixels, 16, 16);
    CGContextSetShadowWithColor(ctx, CGSizeMake(6, 6), 0, blue);
    CGContextDrawImage(ctx, CGRectMake(60, 120, 60, 60), red_image);
    CGImageRelease(red_image);
    for (int i = 0; i < 16 * 16; i++)
    {
        pixels[i * 4 + 0] = 0;
        pixels[i * 4 + 1] = 255;
        pixels[i * 4 + 2] = 0;
        pixels[i * 4 + 3] = 255;
    }
    CGImageRef green_image = CGImageCreateWithRGBA(pixels, 16, 16);
    CGContextSetShadowWithColor(ctx, CGSizeMake(0, 6), 4, black);
    CGContextDrawImage(ctx, CGRectMake(240, 120, 60, 60), green_image);
    CGImageRelease(green_image);
    CGColorRelease(blue);
    CGColorRelease(green);
    CGColorRelease(black);
}
@end

@interface ShadowImageCapture : UIView
@end

@implementation ShadowImageCapture
- (void)drawRect:(CGRect)rect
{
    (void)rect;
    if (!g_cg_image_shadow_ready)
        return;
    const char *path = getenv("IOSIM_TEST_PNG");
    if (!path)
        return;
    iosim_fb_present(path);
    printf("[cgimage] png written\n");
    fflush(0);
    exit(0);
}
@end

@interface CGImageShadowController : UIViewController
@end

@implementation CGImageShadowController
- (void)loadView
{
    UIView *root =
        [[UIView alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    root.backgroundColor = [UIColor whiteColor];
    self.view = root;

    ShadowImages *images =
        [[ShadowImages alloc] initWithFrame:root.bounds];
    images.backgroundColor = [UIColor clearColor];
    [root addSubview:images];

    ShadowImageCapture *capture =
        [[ShadowImageCapture alloc] initWithFrame:root.bounds];
    capture.backgroundColor = [UIColor clearColor];
    [root addSubview:capture];

    printf("[cgimage] ready\n");
    fflush(0);
    dispatch_after(dispatch_time(0, 200 * 1000000LL),
                   dispatch_get_main_queue(), ^{
        printf("[cgimage] done\n");
        fflush(0);
        g_cg_image_shadow_ready = 1;
        [images setNeedsDisplay];
        [capture setNeedsDisplay];
    });
}
@end

@interface CGImageShadowSceneDelegate : UIResponder <UIWindowSceneDelegate>
@property(nonatomic, retain) UIWindow *window;
@end

@interface CGImageShadowAppDelegate : UIResponder <UIApplicationDelegate>
@end

@implementation CGImageShadowAppDelegate
- (UISceneConfiguration *)application:(UIApplication *)application
    configurationForConnectingSceneSession:(UISceneSession *)session
    options:(UISceneConnectionOptions *)connectionOptions
{
    (void)application; (void)session; (void)connectionOptions;
    UISceneConfiguration *configuration = [[UISceneConfiguration alloc]
        initWithName:@"Default Configuration"
         sessionRole:UIWindowSceneSessionRoleApplication];
    configuration.delegateClass = [CGImageShadowSceneDelegate class];
    return configuration;
}
@end

@implementation CGImageShadowSceneDelegate
- (void)scene:(UIScene *)scene
    willConnectToSession:(UISceneSession *)session
                 options:(UISceneConnectionOptions *)connectionOptions
{
    (void)session; (void)connectionOptions;
    self.window = [[UIWindow alloc] initWithWindowScene:(UIWindowScene *)scene];
    self.window.frame = [[UIScreen mainScreen] bounds];
    self.window.rootViewController = [[CGImageShadowController alloc] init];
    [self.window makeKeyAndVisible];
}
@end

int main(int argc, char **argv)
{
    @autoreleasepool
    {
        return UIApplicationMain(argc, argv, nil, @"CGImageShadowAppDelegate");
    }
}
