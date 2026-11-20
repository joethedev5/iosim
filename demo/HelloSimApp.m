#if __has_include(<UIKit/UIKit.h>)
#import <UIKit/UIKit.h>
#else
#import "UIKitStub.h"
#endif

@interface AppDelegate : UIResponder <UIApplicationDelegate>
@property (nonatomic, retain) UIWindow *window;
@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application
    didFinishLaunchingWithOptions:(id)launchOptions
{
    (void)launchOptions;

    CGRect screen = [[UIScreen mainScreen] bounds];
    double width = screen.size.width;

    self.window = [[UIWindow alloc] initWithFrame:screen];
    self.window.backgroundColor =
        [UIColor colorWithRed:0.043 green:0.063 blue:0.125 alpha:1.0];

    UILabel *title =
        [[UILabel alloc] initWithFrame:CGRectMake(24, 80, width - 48, 48)];
    title.text = @"Hello from iOS";
    title.textColor = [UIColor whiteColor];
    title.font = [UIFont boldSystemFontOfSize:34];
    [self.window addSubview:title];

    UILabel *subtitle =
        [[UILabel alloc] initWithFrame:CGRectMake(24, 138, width - 48, 26)];
    subtitle.text = @"Same source. Two runtimes.";
    subtitle.textColor =
        [UIColor colorWithRed:0.58 green:0.64 blue:0.72 alpha:1.0];
    subtitle.font = [UIFont systemFontOfSize:17];
    [self.window addSubview:subtitle];

    UIView *card =
        [[UIView alloc] initWithFrame:CGRectMake(24, 190, width - 48, 220)];
    card.backgroundColor =
        [UIColor colorWithRed:0.106 green:0.141 blue:0.251 alpha:1.0];
    card.layer.cornerRadius = 18;
    [self.window addSubview:card];

    UILabel *row1 =
        [[UILabel alloc] initWithFrame:CGRectMake(18, 22, width - 84, 30)];
    row1.text = @"Mach-O loader: OK";
    row1.textColor = [UIColor whiteColor];
    row1.font = [UIFont systemFontOfSize:16];
    [card addSubview:row1];

    UILabel *row2 =
        [[UILabel alloc] initWithFrame:CGRectMake(18, 62, width - 84, 30)];
    row2.text = @"chained fixups: OK";
    row2.textColor = [UIColor whiteColor];
    row2.font = [UIFont systemFontOfSize:16];
    [card addSubview:row2];

    UILabel *row3 =
        [[UILabel alloc] initWithFrame:CGRectMake(18, 102, width - 84, 30)];
    row3.text = @"objc_msgSend: OK";
    row3.textColor = [UIColor whiteColor];
    row3.font = [UIFont systemFontOfSize:16];
    [card addSubview:row3];

    UILabel *row4 =
        [[UILabel alloc] initWithFrame:CGRectMake(18, 142, width - 84, 30)];
    row4.text = @"UIKit.framework: OK";
    row4.textColor = [UIColor whiteColor];
    row4.font = [UIFont systemFontOfSize:16];
    [card addSubview:row4];

    UIView *button =
        [[UIView alloc] initWithFrame:CGRectMake(24, 440, width - 48, 56)];
    button.backgroundColor = [UIColor systemBlueColor];
    button.layer.cornerRadius = 16;
    [self.window addSubview:button];

    UILabel *buttonLabel = [[UILabel alloc]
        initWithFrame:CGRectMake(0, 14, width - 48, 28)];
    buttonLabel.text = @"Continue";
    buttonLabel.textColor = [UIColor whiteColor];
    buttonLabel.font = [UIFont boldSystemFontOfSize:18];
    buttonLabel.textAlignment = 1;
    [button addSubview:buttonLabel];

    UILabel *footer =
        [[UILabel alloc] initWithFrame:CGRectMake(24, 560, width - 48, 24)];
    footer.text = @"iosim x86_64";
    footer.textColor =
        [UIColor colorWithRed:0.39 green:0.45 blue:0.55 alpha:1.0];
    footer.font = [UIFont systemFontOfSize:14];
    [self.window addSubview:footer];

    [self.window makeKeyAndVisible];
    return YES;
}

@end

int main(int argc, char **argv)
{
    @autoreleasepool
    {
        return UIApplicationMain(argc, argv, nil, @"AppDelegate");
    }
}
