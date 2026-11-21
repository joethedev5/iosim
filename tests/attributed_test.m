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

    UIGraphicsImageRenderer *renderer =
        [[UIGraphicsImageRenderer alloc] initWithSize:CGSizeMake(30, 30)];
    UIImage *icon = [renderer imageWithActions:^(UIGraphicsImageRendererContext *ctx) {
        CGContextSetRGBFillColor([ctx CGContext], 1, 0, 1, 1);
        CGContextFillRect([ctx CGContext], CGRectMake(0, 0, 30, 30));
    }];
    UIButton *imageButton = [UIButton buttonWithType:0];
    imageButton.frame = CGRectMake(40, 560, 60, 60);
    [imageButton setImage:icon forState:0];
    [root addSubview:imageButton];
    printf("[attr] image %d %d\n", [imageButton imageForState:0] == icon,
           [imageButton imageView] != nil);

    UIButtonConfiguration *configuration =
        [UIButtonConfiguration filledButtonConfiguration];
    configuration.title = @"Cfg";
    configuration.baseBackgroundColor = [UIColor greenColor];
    configuration.cornerStyle = UIButtonConfigurationCornerStyleCapsule;
    UIButton *configButton = [UIButton buttonWithType:0];
    configButton.frame = CGRectMake(140, 560, 120, 44);
    configButton.configuration = configuration;
    [root addSubview:configButton];
    printf("[attr] config %s %d\n",
           [[[configButton titleLabel] text] UTF8String],
           [configButton configuration] == configuration);

    UITextField *field =
        [[UITextField alloc] initWithFrame:CGRectMake(40, 700, 200, 44)];
    field.borderStyle = 3;
    field.text = @"Hello";
    [root addSubview:field];
    printf("[attr] field %d\n", [field borderStyle]);

    CATextLayer *textLayer = [[CATextLayer alloc] init];
    textLayer.frame = CGRectMake(40, 760, 120, 40);
    textLayer.backgroundColor = [UIColor blackColor];
    textLayer.string = @"M";
    textLayer.fontSize = 30;
    textLayer.foregroundColor = [UIColor whiteColor];
    [[root layer] addSublayer:textLayer];
    printf("[attr] textlayer %s %.0f\n", [[textLayer string] UTF8String],
           [textLayer fontSize]);

    UIView *fromView = [[UIView alloc] initWithFrame:CGRectMake(200, 700, 40, 40)];
    fromView.backgroundColor = [UIColor redColor];
    [root addSubview:fromView];
    UIView *toView = [[UIView alloc] initWithFrame:CGRectMake(200, 700, 40, 40)];
    toView.backgroundColor = [UIColor blueColor];
    [UIView transitionFromView:fromView toView:toView duration:0.2 options:0
                    completion:^(BOOL finished) {
        printf("[attr] transition %d %d\n", finished,
               [toView superview] != nil);
    }];

    UIBarButtonItem *barItem = [[UIBarButtonItem alloc] initWithImage:icon
        style:0 target:nil action:0];
    printf("[attr] bar %d %d\n", [barItem image] == icon,
           [barItem customView] == nil);

    UIViewController *plain = [[UIViewController alloc] init];
    [plain loadViewIfNeeded];
    printf("[attr] vc %d %d %lu\n", [plain isViewLoaded],
           [plain shouldAutorotate], [plain supportedInterfaceOrientations]);

    UILabel *accessLabel = [[UILabel alloc] initWithFrame:
        CGRectMake(0, 0, 80, 20)];
    accessLabel.text = @"Acc";
    printf("[attr] access %d %s %llu\n",
           [accessLabel isAccessibilityElement],
           [[accessLabel accessibilityLabel] UTF8String],
           [accessLabel accessibilityTraits]);

    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc]
        initWithTarget:nil action:0];
    tap.numberOfTouchesRequired = 2;
    UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc]
        initWithTarget:nil action:0];
    pan.maximumNumberOfTouches = 3;
    UISwipeGestureRecognizer *swipe = [[UISwipeGestureRecognizer alloc]
        initWithTarget:nil action:0];
    swipe.numberOfTouchesRequired = 2;
    printf("[attr] gestures %d %lu %d %d %d\n",
           [tap numberOfTapsRequired], [pan maximumNumberOfTouches],
           [swipe numberOfTouchesRequired], [tap delaysTouchesBegan],
           [tap cancelsTouchesInView]);

    printf("[attr] frame %.0f %.0f %.0f %.0f\n",
           [accessLabel accessibilityFrame].origin.x,
           [accessLabel accessibilityFrame].origin.y,
           [accessLabel accessibilityFrame].size.width,
           [accessLabel accessibilityFrame].size.height);
    printf("[attr] fieldvalue %s\n", [[field accessibilityValue] UTF8String]);

    UITableView *table = [[UITableView alloc] initWithFrame:
        CGRectMake(0, 0, 100, 100) style:0];
    table.separatorStyle = 0;
    table.allowsMultipleSelection = YES;
    table.estimatedRowHeight = 60;
    printf("[attr] table %ld %d %.0f\n", [table separatorStyle],
           [table allowsMultipleSelection], [table estimatedRowHeight]);

    UICollectionViewFlowLayout *flow =
        [[UICollectionViewFlowLayout alloc] init];
    UICollectionView *collection = [[UICollectionView alloc]
        initWithFrame:CGRectMake(0, 0, 100, 100) collectionViewLayout:flow];
    collection.allowsMultipleSelection = YES;
    printf("[attr] collection %d %ld %lu\n",
           [collection allowsMultipleSelection], [collection numberOfSections],
           [[collection visibleCells] count]);

    UIScrollView *scroll = [[UIScrollView alloc] initWithFrame:
        CGRectMake(0, 0, 100, 100)];
    scroll.keyboardDismissMode = 1;
    scroll.indicatorStyle = 2;
    scroll.scrollsToTop = NO;
    printf("[attr] scroll %ld %ld %d\n", [scroll keyboardDismissMode],
           [scroll indicatorStyle], [scroll scrollsToTop]);

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
