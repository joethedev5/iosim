#if __has_include(<UIKit/UIKit.h>)
#import <UIKit/UIKit.h>
#else
#import "UIKitStub.h"
#endif

extern int printf(const char *fmt, ...);
extern int fflush(void *stream);

/* Multiline editing: a UITextView takes focus, hardware key events append
 * text, the return key starts a new line and backspace deletes. */

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

@interface EditorViewController : UIViewController {
    int _ticks;
    id _last;
}
@property(nonatomic, retain) UITextView *editor;
@property(nonatomic, retain) CADisplayLink *link;
@end

@implementation EditorViewController
- (void)loadView
{
    UIView *view =
        [[UIView alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    view.backgroundColor =
        [UIColor colorWithRed:0.043 green:0.055 blue:0.102 alpha:1.0];
    self.view = view;
}
- (void)viewDidLoad
{
    [super viewDidLoad];
    CGRect screen = [[UIScreen mainScreen] bounds];
    UILabel *title = [[UILabel alloc]
        initWithFrame:CGRectMake(24, 90, screen.size.width - 48, 40)];
    title.text = @"Notes";
    title.font = [UIFont boldSystemFontOfSize:30];
    title.textColor = [UIColor whiteColor];
    [self.view addSubview:title];

    self.editor = [[UITextView alloc]
        initWithFrame:CGRectMake(24, 170, screen.size.width - 48, 300)];
    self.editor.backgroundColor =
        [UIColor colorWithRed:0.09 green:0.12 blue:0.21 alpha:1.0];
    self.editor.layer.cornerRadius = 14;
    self.editor.textColor = [UIColor whiteColor];
    self.editor.font = [UIFont systemFontOfSize:17];
    self.editor.text = @"";
    [self.view addSubview:self.editor];

    self.link = [CADisplayLink displayLinkWithTarget:self
                                            selector:@selector(step:)];
    [self.link addToRunLoop:nil forMode:nil];
    printf("[textview] ready\n");
    fflush(0);
}
- (void)step:(CADisplayLink *)link
{
    (void)link;
    _ticks++;
    if (!_last || ![_last isEqual:self.editor.text])
    {
        _last = self.editor.text;
        const char *text = [self.editor.text UTF8String];
        char flat[256];
        int n = 0, lines = 1;
        for (const char *p = text; p && *p && n < 200; p++)
        {
            if (*p == '\n')
            {
                flat[n++] = '|';
                lines++;
            }
            else
                flat[n++] = *p;
        }
        flat[n] = 0;
        printf("[textview] lines=%d text=%s\n", lines, flat);
        fflush(0);
    }
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
    self.window.rootViewController = [[EditorViewController alloc] init];
    [self.window makeKeyAndVisible];
}
@end

int main(int argc, char **argv)
{
    @autoreleasepool { return UIApplicationMain(argc, argv, nil, @"AppDelegate"); }
}
