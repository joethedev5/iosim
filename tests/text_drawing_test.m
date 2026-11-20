/* NSString drawing: sizeWithAttributes and drawAtPoint render text through
 * the UIKit font surface into the current drawRect: context. */
#include "UIKitStub.h"

extern int printf(const char *fmt, ...);
extern int fflush(void *stream);
extern int iosim_fb_present(const char *path);
extern char *getenv(const char *name);
extern void exit(int status);

@interface TextDrawView : UIView
@end

@implementation TextDrawView
- (void)drawRect:(CGRect)rect
{
    (void)rect;
    NSDictionary *attributes = [NSDictionary dictionaryWithObjectsAndKeys:
        [UIFont boldSystemFontOfSize:32], NSFontAttributeName,
        [UIColor whiteColor], NSForegroundColorAttributeName, nil];
    CGSize size = [@"iosim" sizeWithAttributes:attributes];
    printf("[text] size %d %d\n", size.width > 10, size.height > 10);
    [@"iosim" drawAtPoint:CGPointMake(40, 200)
           withAttributes:attributes];
    NSString *long_text = @"the quick brown fox jumps over the lazy dog";
    CGRect bounds = [long_text boundingRectWithSize:CGSizeMake(160, 160)
                                            options:0
                                         attributes:attributes
                                            context:nil];
    printf("[text] bounds %d %d\n", bounds.size.width > 10,
           bounds.size.height > 20);
    [long_text drawInRect:CGRectMake(40, 280, 160, 160)
           withAttributes:attributes];
    printf("[text] drawn\n");
    fflush(0);
    const char *path = getenv("IOSIM_TEST_PNG");
    if (path)
    {
        iosim_fb_present(path);
        printf("[text] wrote png\n");
        fflush(0);
        exit(0);
    }
}
@end

@interface TextController : UIViewController
@end

@implementation TextController
- (void)loadView
{
    TextDrawView *view =
        [[TextDrawView alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    view.backgroundColor =
        [UIColor colorWithRed:0.04 green:0.06 blue:0.12 alpha:1.0];
    self.view = view;
}
@end

@interface TextSceneDelegate : UIResponder <UIWindowSceneDelegate>
@property(nonatomic, retain) UIWindow *window;
@end

@interface TextAppDelegate : UIResponder <UIApplicationDelegate>
@end

@implementation TextAppDelegate
- (UISceneConfiguration *)application:(UIApplication *)application
    configurationForConnectingSceneSession:(UISceneSession *)session
    options:(UISceneConnectionOptions *)options
{
    (void)application; (void)session; (void)options;
    UISceneConfiguration *configuration = [[UISceneConfiguration alloc]
        initWithName:@"Default Configuration"
         sessionRole:UIWindowSceneSessionRoleApplication];
    configuration.delegateClass = [TextSceneDelegate class];
    return configuration;
}
@end

@implementation TextSceneDelegate
- (void)scene:(UIScene *)scene
    willConnectToSession:(UISceneSession *)session
                 options:(UISceneConnectionOptions *)connectionOptions
{
    (void)session; (void)connectionOptions;
    self.window = [[UIWindow alloc] initWithWindowScene:(UIWindowScene *)scene];
    self.window.frame = [[UIScreen mainScreen] bounds];
    self.window.rootViewController = [[TextController alloc] init];
    [self.window makeKeyAndVisible];
}
@end

int main(int argc, char **argv)
{
    @autoreleasepool
    {
        return UIApplicationMain(argc, argv, nil, @"TextAppDelegate");
    }
}
