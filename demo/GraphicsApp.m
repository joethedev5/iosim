#if __has_include(<UIKit/UIKit.h>)
#import <UIKit/UIKit.h>
#else
#import "UIKitStub.h"
#endif

@interface SceneDelegate : UIResponder <UIWindowSceneDelegate>
@property (nonatomic, retain) UIWindow *window;
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
    CGRect screen = [[UIScreen mainScreen] bounds];
    double width = screen.size.width;

    self.window = [[UIWindow alloc] initWithWindowScene:(UIWindowScene *)scene];
    self.window.frame = screen;
    self.window.backgroundColor =
        [UIColor colorWithRed:0.035 green:0.047 blue:0.098 alpha:1.0];

    UILabel *title =
        [[UILabel alloc] initWithFrame:CGRectMake(24, 76, width - 48, 40)];
    title.text = @"Drawn natively";
    title.textColor = [UIColor whiteColor];
    title.font = [UIFont boldSystemFontOfSize:30];
    [self.window addSubview:title];

    UILabel *subtitle =
        [[UILabel alloc] initWithFrame:CGRectMake(24, 120, width - 48, 24)];
    subtitle.text = @"CoreAnimation layers, paths and images";
    subtitle.textColor =
        [UIColor colorWithRed:0.58 green:0.64 blue:0.72 alpha:1.0];
    subtitle.font = [UIFont systemFontOfSize:16];
    [self.window addSubview:subtitle];

    UIView *hero =
        [[UIView alloc] initWithFrame:CGRectMake(24, 164, width - 48, 150)];
    hero.layer.cornerRadius = 20;
    CAGradientLayer *gradient = [[CAGradientLayer alloc] init];
    gradient.frame = CGRectMake(0, 0, width - 48, 150);
    gradient.cornerRadius = 20;
    gradient.colors = @[
        (id)[UIColor colorWithRed:0.10 green:0.36 blue:0.98 alpha:1.0].CGColor,
        (id)[UIColor colorWithRed:0.55 green:0.20 blue:0.86 alpha:1.0].CGColor,
    ];
    gradient.startPoint = CGPointMake(0, 0);
    gradient.endPoint = CGPointMake(1, 1);
    [hero.layer addSublayer:gradient];
    [self.window addSubview:hero];

    UILabel *heroTitle =
        [[UILabel alloc] initWithFrame:CGRectMake(20, 26, width - 88, 30)];
    heroTitle.text = @"CAGradientLayer";
    heroTitle.textColor = [UIColor whiteColor];
    heroTitle.font = [UIFont boldSystemFontOfSize:20];
    [hero addSubview:heroTitle];

    UILabel *heroSub =
        [[UILabel alloc] initWithFrame:CGRectMake(20, 60, width - 88, 24)];
    heroSub.text = @"two stops · 45°";
    heroSub.textColor =
        [UIColor colorWithRed:0.86 green:0.90 blue:1.0 alpha:1.0];
    heroSub.font = [UIFont systemFontOfSize:14];
    [hero addSubview:heroSub];

    UIView *chart =
        [[UIView alloc] initWithFrame:CGRectMake(24, 334, width - 48, 210)];
    chart.backgroundColor =
        [UIColor colorWithRed:0.078 green:0.106 blue:0.184 alpha:1.0];
    chart.layer.cornerRadius = 18;
    [self.window addSubview:chart];

    UILabel *chartTitle =
        [[UILabel alloc] initWithFrame:CGRectMake(18, 16, width - 84, 24)];
    chartTitle.text = @"CAShapeLayer";
    chartTitle.textColor = [UIColor whiteColor];
    chartTitle.font = [UIFont boldSystemFontOfSize:17];
    [chart addSubview:chartTitle];

    double plotW = width - 84;
    UIBezierPath *line = [UIBezierPath bezierPath];
    double values[8] = {0.55, 0.68, 0.42, 0.74, 0.60, 0.88, 0.72, 0.95};
    for (int i = 0; i < 8; i++)
    {
        double px = 18 + plotW * i / 7.0;
        double py = 168 - values[i] * 100;
        if (i == 0)
            [line moveToPoint:CGPointMake(px, py)];
        else
            [line addLineToPoint:CGPointMake(px, py)];
    }
    UIBezierPath *area = [UIBezierPath bezierPath];
    [area moveToPoint:CGPointMake(18, 168)];
    for (int i = 0; i < 8; i++)
    {
        double px = 18 + plotW * i / 7.0;
        double py = 168 - values[i] * 100;
        [area addLineToPoint:CGPointMake(px, py)];
    }
    [area addLineToPoint:CGPointMake(18 + plotW, 168)];
    CAShapeLayer *fill = [[CAShapeLayer alloc] init];
    fill.frame = CGRectMake(0, 0, width - 48, 210);
    fill.path = area.CGPath;
    fill.fillColor =
        (id)[UIColor colorWithRed:0.10 green:0.20 blue:0.40 alpha:1.0].CGColor;
    fill.strokeColor = nil;
    [chart.layer addSublayer:fill];

    CAShapeLayer *stroke = [[CAShapeLayer alloc] init];
    stroke.frame = CGRectMake(0, 0, width - 48, 210);
    stroke.path = line.CGPath;
    stroke.strokeColor =
        (id)[UIColor colorWithRed:0.30 green:0.82 blue:1.0 alpha:1.0].CGColor;
    stroke.fillColor = nil;
    stroke.lineWidth = 4;
    [chart.layer addSublayer:stroke];

    UIImageView *badge = [[UIImageView alloc]
        initWithImage:[UIImage imageNamed:@"badge"]];
    badge.frame = CGRectMake(width - 48 - 62, 14, 44, 44);
    badge.contentMode = 1;
    [chart addSubview:badge];

    UILabel *foot =
        [[UILabel alloc] initWithFrame:CGRectMake(24, 570, width - 48, 22)];
    foot.text = @"paths · gradients · RGBA images";
    foot.textColor =
        [UIColor colorWithRed:0.39 green:0.45 blue:0.55 alpha:1.0];
    foot.font = [UIFont systemFontOfSize:13];
    [self.window addSubview:foot];

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
