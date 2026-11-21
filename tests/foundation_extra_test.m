/* NSString trimming/number/percent helpers and NSCharacterSet. */
#include "UIKitStub.h"

extern int printf(const char *fmt, ...);
extern int fflush(void *stream);

static int g_animatorRuns;

@interface FoundationSearchUpdater : NSObject <UISearchResultsUpdating>
@end

@implementation FoundationSearchUpdater
- (void)updateSearchResultsForSearchController:
    (UISearchController *)searchController
{
    printf("[fnd] searchupdate %d\n", [searchController isActive]);
}
@end

@interface FoundationTransitionAnimator : NSObject
    <UIViewControllerAnimatedTransitioning> {
@public
    int _calls;
}
@end

@implementation FoundationTransitionAnimator
- (double)transitionDuration:
    (id<UIViewControllerContextTransitioning>)context
{
    (void)context;
    return 0.05;
}
- (void)animateTransition:
    (id<UIViewControllerContextTransitioning>)context
{
    _calls++;
    UIViewController *from = [context
        viewControllerForKey:UITransitionContextFromViewControllerKey];
    UIViewController *to = [context
        viewControllerForKey:UITransitionContextToViewControllerKey];
    printf("[fnd] trans anim %d %d %d %d %d %d\n", _calls,
           [context isAnimated], from != nil, to != nil,
           [to isBeingPresented], [from isBeingDismissed]);
    fflush(0);
    [context completeTransition:YES];
}
@end

@interface FoundationPresentationController : UIPresentationController {
@public
    int _willBegin;
    int _didEnd;
    int _dismissWillBegin;
    int _dismissDidEnd;
}
@end

@implementation FoundationPresentationController
- (void)presentationTransitionWillBegin
{
    _willBegin++;
    printf("[fnd] pres will\n");
    fflush(0);
}
- (void)presentationTransitionDidEnd:(BOOL)completed
{
    if (completed)
        _didEnd++;
    printf("[fnd] pres did %d\n", completed);
    fflush(0);
}
- (void)dismissalTransitionWillBegin
{
    _dismissWillBegin++;
    printf("[fnd] pres dismiss will\n");
    fflush(0);
}
- (void)dismissalTransitionDidEnd:(BOOL)completed
{
    if (completed)
        _dismissDidEnd++;
    printf("[fnd] pres dismiss did %d\n", completed);
    fflush(0);
}
- (CGRect)frameOfPresentedViewInContainerView
{
    return CGRectMake(10, 20, 30, 40);
}
@end

@interface FoundationTransitionDelegate : NSObject
    <UIViewControllerTransitioningDelegate> {
@public
    FoundationTransitionAnimator *_animator;
    FoundationPresentationController *_presentationController;
}
@end

@implementation FoundationTransitionDelegate
- (id<UIViewControllerAnimatedTransitioning>)
    animationControllerForPresentedController:(UIViewController *)presented
                         presentingController:(UIViewController *)presenting
                             sourceController:(UIViewController *)source
{
    (void)presented; (void)presenting; (void)source;
    return _animator;
}
- (id<UIViewControllerAnimatedTransitioning>)
    animationControllerForDismissedController:(UIViewController *)dismissed
{
    (void)dismissed;
    return _animator;
}
- (UIPresentationController *)
    presentationControllerForPresentedViewController:(UIViewController *)presented
                            presentingViewController:(UIViewController *)presenting
                                sourceViewController:(UIViewController *)source
{
    (void)presented; (void)presenting; (void)source;
    return _presentationController;
}
@end

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
    NSURL *url = [NSURL URLWithString:
        @"https://example.com:8080/a/b?x=1#frag"];
    printf("[fnd] url %s %s %d %s %s\n", [[url scheme] UTF8String],
           [[url host] UTF8String], [url port], [[url path] UTF8String],
           [[url query] UTF8String]);
    NSURLComponents *components = [NSURLComponents componentsWithString:
        @"https://example.com:8080/a?q=2"];
    components.fragment = @"top";
    printf("[fnd] comp %s %s\n", [[components string] UTF8String],
           [[components host] UTF8String]);
    printf("[fnd] pfont %.0f\n",
           [[UIFont preferredFontForTextStyle:UIFontTextStyleBody] pointSize]);

    NSURLComponents *queryComponents = [NSURLComponents componentsWithString:
        @"https://example.com/?a=1&b=two"];
    NSArray *queryItems = [queryComponents queryItems];
    printf("[fnd] qitems %lu %s %s\n", [queryItems count],
           [[[queryItems objectAtIndex:0] name] UTF8String],
           [[[queryItems objectAtIndex:1] value] UTF8String]);
    [queryComponents setQueryItems:@[
        [NSURLQueryItem queryItemWithName:@"k" value:@"v"]]];
    printf("[fnd] qbuild %s\n", [[queryComponents query] UTF8String]);

    UIDevice *device = [UIDevice currentDevice];
    printf("[fnd] device %s %s %ld %ld\n", [[device model] UTF8String],
           [[device systemVersion] UTF8String], [device userInterfaceIdiom],
           [device orientation]);
    printf("[fnd] vendor %d\n", [device identifierForVendor] != nil);
    NSProcessInfo *process = [NSProcessInfo processInfo];
    printf("[fnd] process %s %lu %lu\n", [[process processName] UTF8String],
           [process processorCount], [process activeProcessorCount]);
    NSUUID *uuid = [NSUUID UUID];
    NSString *uuidString = [uuid UUIDString];
    NSUUID *parsedUUID = [[NSUUID alloc] initWithUUIDString:uuidString];
    printf("[fnd] uuid %lu %d\n", [uuidString length],
           [uuid isEqual:parsedUUID]);

    NSValue *transformValue = [NSValue valueWithCGAffineTransform:
        CGAffineTransformMakeTranslation(7, 9)];
    CGAffineTransform transform = [transformValue CGAffineTransformValue];
    printf("[fnd] affine %.0f %.0f\n", transform.tx, transform.ty);

    UIViewController *vc = [[UIViewController alloc] init];
    vc.preferredContentSize = CGSizeMake(320, 480);
    printf("[fnd] vcprops %lu %d %d %.0f %.0f\n",
           [vc edgesForExtendedLayout],
           [vc automaticallyAdjustsScrollViewInsets],
           [vc isModalInPresentation],
           [vc preferredContentSize].width,
           [vc preferredContentSize].height);

    UISearchController *searchController = [[UISearchController alloc]
        initWithSearchResultsController:nil];
    searchController.searchResultsUpdater =
        [[FoundationSearchUpdater alloc] init];
    searchController.active = YES;
    printf("[fnd] search %d %d %lu\n", searchController.searchBar != nil,
           [searchController isActive],
           [[searchController.searchBar scopeButtonTitles] count]);

    UIViewController *controller = [[UIViewController alloc] init];
    controller.modalPresentationStyle = UIModalPresentationPopover;
    controller.popoverPresentationController.sourceView = root;
    controller.sheetPresentationController.detents = @[
        [UISheetPresentationControllerDetent mediumDetent],
        [UISheetPresentationControllerDetent largeDetent]];
    controller.navigationItem.largeTitleDisplayMode = 2;
    NSArray *emptyItems = @[];
    controller.navigationItem.leftBarButtonItems = emptyItems;
    NSValue *pointValue = [NSValue valueWithCGPoint:CGPointMake(3, 4)];
    CGPoint point = [pointValue CGPointValue];
    NSValue *rangeValue = [NSValue valueWithRange:NSMakeRange(2, 5)];
    NSRange range = [rangeValue rangeValue];
    printf("[fnd] value %.0f %.0f %lu %lu %d\n", point.x, point.y,
           range.location, range.length,
           [pointValue isEqualToValue:
               [NSValue valueWithCGPoint:CGPointMake(3, 4)]]);
    NSMutableIndexSet *indexes = [NSMutableIndexSet indexSet];
    [indexes addIndex:5];
    [indexes addIndex:2];
    [indexes addIndexesInRange:NSMakeRange(10, 2)];
    __block unsigned long indexSum = 0;
    [indexes enumerateIndexesUsingBlock:^(unsigned long index, BOOL *stop) {
        (void)stop;
        indexSum += index;
    }];
    printf("[fnd] idx %lu %lu %lu %d %lu\n", [indexes count],
           [indexes firstIndex], [indexes lastIndex],
           [indexes containsIndex:5], indexSum);
    printf("[fnd] idxmore %lu %lu %lu\n",
           [indexes indexGreaterThanIndex:5],
           [indexes indexLessThanIndex:10],
           [indexes indexGreaterThanOrEqualToIndex:10]);

    NSData *plainData = [NSData dataWithBytes:"hello" length:5];
    NSString *encodedData = [plainData base64EncodedStringWithOptions:0];
    NSData *decodedData = [[NSData alloc]
        initWithBase64EncodedString:encodedData options:0];
    printf("[fnd] b64 %s %lu\n", [encodedData UTF8String],
           [decodedData length]);

    NSURL *appendURL = [[NSURL fileURLWithPath:@"/tmp/a"]
        URLByAppendingPathComponent:@"b" isDirectory:YES];
    printf("[fnd] urlappend %s\n", [[appendURL path] UTF8String]);

    UIAccessibilityElement *element = [[UIAccessibilityElement alloc]
        initWithAccessibilityContainer:root];
    element.accessibilityLabel = @"E";
    element.accessibilityFrame = CGRectMake(1, 2, 3, 4);
    printf("[fnd] axel %s %d %.0f %.0f\n",
           [[element accessibilityLabel] UTF8String],
           [element isAccessibilityElement],
           [element accessibilityFrame].size.width,
           [element accessibilityFrame].size.height);

    printf("[fnd] present %ld %d %lu %ld %lu\n",
           [controller modalPresentationStyle],
           [controller popoverPresentationController].sourceView == root,
           [[controller sheetPresentationController].detents count],
           [controller.navigationItem largeTitleDisplayMode],
           [[controller.navigationItem leftBarButtonItems] count]);

    NSString *pct = [@"a b&c" stringByAddingPercentEncodingWithAllowedCharacters:
        [NSCharacterSet URLQueryAllowedCharacterSet]];
    printf("[fnd] pct %s\n", [pct UTF8String]);

    double hval = 0, sval = 0, bval = 0, aval = 0;
    [[UIColor redColor] getHue:&hval saturation:&sval
                    brightness:&bval alpha:&aval];
    printf("[fnd] hue %.0f %.0f %.0f %.0f\n", hval, sval, bval, aval);

    UIAlertController *alert = [UIAlertController
        alertControllerWithTitle:@"T" message:@"M"
                 preferredStyle:UIAlertControllerStyleAlert];
    __block int configured = 0;
    [alert addTextFieldWithConfigurationHandler:^(UITextField *field) {
        field.placeholder = @"P";
        configured = 1;
    }];
    UIAlertAction *preferred = [UIAlertAction
        actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil];
    preferred.enabled = NO;
    alert.preferredAction = preferred;
    printf("[fnd] alert %lu %d %d %d\n", [[alert textFields] count],
           configured, [preferred isEnabled],
           [alert preferredAction] == preferred);

    printf("[fnd] appext %s %s\n",
           [[@"a" stringByAppendingPathExtension:@"txt"] UTF8String],
           [[[[NSURL fileURLWithPath:@"/tmp/a"]
               URLByAppendingPathExtension:@"txt"] path] UTF8String]);

    UISplitViewController *split = [[UISplitViewController alloc]
        initWithStyle:UISplitViewControllerStyleDoubleColumn];
    UIViewController *left = [[UIViewController alloc] init];
    UIViewController *right = [[UIViewController alloc] init];
    left.view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 100, 100)];
    right.view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 100, 100)];
    [split setViewControllers:@[left, right]];
    UIView *splitRoot = [split view];
    splitRoot.frame = CGRectMake(0, 0, 1024, 768);
    [split viewWillLayoutSubviews];
    printf("[fnd] split %d %ld %.0f %.0f %.0f %lu %d\n",
           [split isCollapsed], [split displayMode],
           [left.view frame].size.width,
           [right.view frame].origin.x, [right.view frame].size.width,
           (unsigned long)[[split children] count],
           [split viewControllerForColumn:UISplitViewControllerColumnPrimary]
               == left);

    UIViewController *toolbarController = [[UIViewController alloc] init];
    toolbarController.modalTransitionStyle = 3;
    toolbarController.hidesBottomBarWhenPushed = YES;
    toolbarController.modalPresentationCapturesStatusBarAppearance = YES;
    UIBarButtonItem *toolbarItem = [[UIBarButtonItem alloc]
        initWithTitle:@"T" style:0 target:nil action:nil];
    [toolbarController setToolbarItems:@[toolbarItem] animated:NO];
    UINavigationController *nav = [[UINavigationController alloc]
        initWithRootViewController:toolbarController];
    [nav setToolbarHidden:NO animated:NO];
    (void)[nav view];
    printf("[fnd] navtoolbar %d %lu %.0f %ld %d %d\n",
           [nav isToolbarHidden], (unsigned long)[[[nav toolbar] items] count],
           [toolbarController.view frame].size.height,
           [toolbarController modalTransitionStyle],
           [toolbarController hidesBottomBarWhenPushed],
           [toolbarController modalPresentationCapturesStatusBarAppearance]);

    g_animatorRuns = 0;
    UIViewPropertyAnimator *animator = [[UIViewPropertyAnimator alloc]
        initWithDuration:0.1 curve:0 animations:^{
            g_animatorRuns++;
        }];
    [animator addAnimations:^{
        g_animatorRuns++;
    }];
    [animator addCompletion:^(long position) {
        printf("[fnd] animator done %ld %ld %d\n", position,
               [animator state], g_animatorRuns);
        fflush(0);
    }];
    printf("[fnd] animator start %.1f %.1f %d %ld\n", [animator duration],
           [animator fractionComplete], [animator isRunning],
           [animator state]);
    [animator startAnimation];

    FoundationTransitionAnimator *transitionAnimator =
        [[FoundationTransitionAnimator alloc] init];
    FoundationTransitionDelegate *transitionDelegate =
        [[FoundationTransitionDelegate alloc] init];
    transitionDelegate->_animator = transitionAnimator;
    FoundationPresentationController *presentationController =
        [[FoundationPresentationController alloc] init];
    transitionDelegate->_presentationController = presentationController;
    UIViewController *presented = [[UIViewController alloc] init];
    presented.view =
        [[UIView alloc] initWithFrame:CGRectMake(0, 0, 80, 80)];
    presented.transitioningDelegate = transitionDelegate;
    printf("[fnd] trans delegate %d\n",
           presented.transitioningDelegate == transitionDelegate);
    [self presentViewController:presented animated:YES completion:^{
        printf("[fnd] trans present done\n");
        fflush(0);
    }];
    printf("[fnd] pres props %d %ld\n",
           [presented presentationController] == presentationController,
           [[presented presentationController] presentationStyle]);
    [self dismissViewControllerAnimated:YES completion:^{
        printf("[fnd] trans dismiss done\n");
        fflush(0);
    }];
    printf("[fnd] pres frame %.0f %.0f %.0f %.0f\n",
           presented.view.frame.origin.x, presented.view.frame.origin.y,
           presented.view.frame.size.width, presented.view.frame.size.height);

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
    UIView *rootView = [[self.window rootViewController] view];
    printf("[fnd] viewwin %d %ld\n", rootView.window != nil,
           [rootView effectiveUserInterfaceLayoutDirection]);
    printf("[fnd] scene2 %d %ld\n",
           [(UIWindowScene *)scene screen] == [UIScreen mainScreen],
           [(UIWindowScene *)scene interfaceOrientation]);
    printf("[fnd] scene %lu %ld %s\n",
           [[(UIWindowScene *)scene windows] count],
           [(UIScene *)scene activationState],
           [[[(UIScene *)scene session] persistentIdentifier] UTF8String]);
    fflush(0);
}
@end

int main(int argc, char **argv)
{
    @autoreleasepool
    {
        return UIApplicationMain(argc, argv, nil, @"FoundationAppDelegate");
    }
}
