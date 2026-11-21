/* NSString trimming/number/percent helpers and NSCharacterSet. */
#include "UIKitStub.h"

extern int printf(const char *fmt, ...);
extern int fflush(void *stream);

@interface FoundationController : UIViewController
@end

@implementation FoundationController
- (void)loadView
{
    UIView *root =
        [[UIView alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    root.backgroundColor = [UIColor whiteColor];

    NSString *padded = @"  Hello World  ";
    NSCharacterSet *whitespace = [NSCharacterSet whitespaceCharacterSet];
    NSString *trimmed = [padded stringByTrimmingCharactersInSet:whitespace];
    printf("[fnd] trim '%s'\n", [trimmed UTF8String]);
    printf("[fnd] num %ld %.1f %d\n", (long)[@"42" integerValue],
           [@"3.5" doubleValue], [@"YES" boolValue]);
    printf("[fnd] cap %s\n", [[@"hello WORLD" capitalizedString] UTF8String]);
    printf("[fnd] pct %s\n",
           [[@"a%20b%2Fc" stringByRemovingPercentEncoding] UTF8String]);

    NSMutableCharacterSet *set = [[NSMutableCharacterSet alloc] init];
    [set addCharactersInString:@"abc"];
    [set removeCharactersInString:@"b"];
    printf("[fnd] set %d %d\n", [set characterIsMember:'a'],
           [set characterIsMember:'b']);

    NSString *replaced = [@"abcdef"
        stringByReplacingCharactersInRange:NSMakeRange(2, 2)
                               withString:@"XY"];
    printf("[fnd] rep %s\n", [replaced UTF8String]);

    NSRange found = [@"hello world" rangeOfString:@"world"];
    NSRange missing = [@"hello" rangeOfString:@"zz"];
    printf("[fnd] range %lu %lu %d\n", found.location, found.length,
           missing.location == NSNotFound);

    UIFont *font = [UIFont systemFontOfSize:14 weight:UIFontWeightSemibold];
    printf("[fnd] font %.0f %s %.0f\n", [font pointSize],
           [[font fontName] UTF8String], [[font fontWithSize:20] pointSize]);

    double red = 0, green = 0, blue = 0, alpha = 0;
    UIColor *hue = [UIColor colorWithHue:0 saturation:1 brightness:1 alpha:1];
    [hue getRed:&red green:&green blue:&blue alpha:&alpha];
    UIColor *p3 = [UIColor colorWithDisplayP3Red:0.1 green:0.2 blue:0.3
                                          alpha:0.4];
    double pr = 0, pg = 0, pb = 0, pa = 0;
    [p3 getRed:&pr green:&pg blue:&pb alpha:&pa];
    UIColor *dim = [[UIColor whiteColor] colorWithAlphaComponent:0.25];
    double dr = 0, dg = 0, db = 0, da = 0;
    [dim getRed:&dr green:&dg blue:&db alpha:&da];
    printf("[fnd] color %.0f %.0f %.0f %.1f %.1f %.1f %.1f %.2f\n", red,
           green, blue, alpha, pr, pa, dr, da);

    UIFontDescriptor *descriptor = [UIFontDescriptor
        preferredFontDescriptorWithTextStyle:UIFontTextStyleBody];
    UIFont *described = [UIFont fontWithDescriptor:descriptor size:0];
    printf("[fnd] desc %.0f %.0f\n", [descriptor pointSize],
           [described pointSize]);

    UILayoutGuide *readable = [root readableContentGuide];
    printf("[fnd] readable %.0f %.0f %.0f %.0f\n", [readable layoutFrameX],
           [readable layoutFrameY], [readable layoutFrameWidth],
           [readable layoutFrameHeight]);
    printf("[fnd] props %d %ld %d %.0f\n", [root isOpaque],
           [root contentMode], [root autoresizesSubviews],
           [root contentScaleFactor]);

    self.view = root;
    printf("[fnd] ready\n");
    fflush(0);
}
@end

@interface FoundationSceneDelegate : UIResponder <UIWindowSceneDelegate>
@property(nonatomic, retain) UIWindow *window;
@end

@interface FoundationAppDelegate : UIResponder <UIApplicationDelegate>
@end

@implementation FoundationAppDelegate
- (UISceneConfiguration *)application:(UIApplication *)application
    configurationForConnectingSceneSession:(UISceneSession *)session
    options:(UISceneConnectionOptions *)connectionOptions
{
    (void)application; (void)session; (void)connectionOptions;
    UISceneConfiguration *configuration = [[UISceneConfiguration alloc]
        initWithName:@"Default Configuration"
         sessionRole:UIWindowSceneSessionRoleApplication];
    configuration.delegateClass = [FoundationSceneDelegate class];
    return configuration;
}
@end

@implementation FoundationSceneDelegate
- (void)scene:(UIScene *)scene
    willConnectToSession:(UISceneSession *)session
                 options:(UISceneConnectionOptions *)connectionOptions
{
    (void)session; (void)connectionOptions;
    self.window = [[UIWindow alloc] initWithWindowScene:(UIWindowScene *)scene];
    self.window.frame = [[UIScreen mainScreen] bounds];
    self.window.rootViewController = [[FoundationController alloc] init];
    [self.window makeKeyAndVisible];
}
@end

int main(int argc, char **argv)
{
    @autoreleasepool
    {
        return UIApplicationMain(argc, argv, nil, @"FoundationAppDelegate");
    }
}
