/* UILabel and UIButton attributed strings. */
#include "UIKitStub.h"

extern int printf(const char *fmt, ...);
extern int fflush(void *stream);

@interface AttributedController : UIViewController
@end

@implementation AttributedController
- (void)loadView
{
    UIView *root =
        [[UIView alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    root.backgroundColor = [UIColor whiteColor];

    NSMutableDictionary *attributes = [NSMutableDictionary dictionary];
    [attributes setObject:[UIFont boldSystemFontOfSize:22]
                   forKey:NSFontAttributeName];
    [attributes setObject:[UIColor redColor]
                   forKey:NSForegroundColorAttributeName];
    NSAttributedString *text = [[NSAttributedString alloc]
        initWithString:@"Hello" attributes:attributes];
    UILabel *label =
        [[UILabel alloc] initWithFrame:CGRectMake(40, 300, 300, 40)];
    label.attributedText = text;
    [root addSubview:label];
    printf("[attr] label %s %lu %.0f\n", [label.text UTF8String],
           [label.attributedText length], [label.font pointSize]);

    NSMutableAttributedString *mutable =
        [[NSMutableAttributedString alloc] initWithString:@"Go"];
    [mutable addAttribute:NSForegroundColorAttributeName
                    value:[UIColor blueColor]
                    range:NSMakeRange(0, 2)];
    [mutable appendAttributedString:[[NSAttributedString alloc]
        initWithString:@"!"]];
    [mutable replaceCharactersInRange:NSMakeRange(0, 1)
                           withString:@"W"];
    UIButton *button = [UIButton buttonWithType:0];
    button.frame = CGRectMake(40, 380, 200, 44);
    [button setAttributedTitle:mutable forState:0];
    [root addSubview:button];
    printf("[attr] button %s %lu %d\n", [[[button titleLabel] text] UTF8String],
           [mutable length],
           [button attributedTitleForState:0] == mutable);

    UITextView *textView =
        [[UITextView alloc] initWithFrame:CGRectMake(40, 460, 300, 60)];
    textView.attributedText = text;
    [root addSubview:textView];
    printf("[attr] textview %s %lu\n", [[textView text] UTF8String],
           [textView.attributedText length]);

    self.view = root;
    printf("[attr] ready\n");
    fflush(0);
}
@end

@interface AttributedSceneDelegate : UIResponder <UIWindowSceneDelegate>
@property(nonatomic, retain) UIWindow *window;
@end

@interface AttributedAppDelegate : UIResponder <UIApplicationDelegate>
@end

@implementation AttributedAppDelegate
- (UISceneConfiguration *)application:(UIApplication *)application
    configurationForConnectingSceneSession:(UISceneSession *)session
    options:(UISceneConnectionOptions *)connectionOptions
{
    (void)application; (void)session; (void)connectionOptions;
    UISceneConfiguration *configuration = [[UISceneConfiguration alloc]
        initWithName:@"Default Configuration"
         sessionRole:UIWindowSceneSessionRoleApplication];
    configuration.delegateClass = [AttributedSceneDelegate class];
    return configuration;
}
@end

@implementation AttributedSceneDelegate
- (void)scene:(UIScene *)scene
    willConnectToSession:(UISceneSession *)session
                 options:(UISceneConnectionOptions *)connectionOptions
{
    (void)session; (void)connectionOptions;
    self.window = [[UIWindow alloc] initWithWindowScene:(UIWindowScene *)scene];
    self.window.frame = [[UIScreen mainScreen] bounds];
    self.window.rootViewController = [[AttributedController alloc] init];
    [self.window makeKeyAndVisible];
}
@end

int main(int argc, char **argv)
{
    @autoreleasepool
    {
        return UIApplicationMain(argc, argv, nil, @"AttributedAppDelegate");
    }
}
