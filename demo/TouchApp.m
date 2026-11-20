#if __has_include(<UIKit/UIKit.h>)
#import <UIKit/UIKit.h>
#else
#import "UIKitStub.h"
#endif

extern int printf(const char *fmt, ...);
extern int fflush(void *stream);

/* Touch fixture: proves the UITouch/UIEvent responder pipeline, live control
 * tracking (slider, switch, segmented control) and drag events. It prints a
 * line for every phase so a headless run can assert the delivery order. */

@interface TrailView : UIView {
    int _dots;
}
@end

@implementation TrailView
- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
        self.backgroundColor =
            [UIColor colorWithRed:0.07 green:0.08 blue:0.13 alpha:1.0];
    return self;
}
- (void)trace:(const char *)phase point:(CGPoint)point
{
    printf("[touch] %s %.1f %.1f\n", phase, point.x, point.y);
    fflush(0);
}
- (void)dotAtPoint:(CGPoint)point
{
    if (_dots >= 64)
        return;
    UIView *dot = [[UIView alloc]
        initWithFrame:CGRectMake(point.x - 8, point.y - 8, 16, 16)];
    dot.backgroundColor =
        [UIColor colorWithRed:0.15 green:0.55 blue:1.0 alpha:1.0];
    dot.layer.cornerRadius = 8;
    [self addSubview:dot];
    _dots++;
}
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    (void)event;
    UITouch *touch = [touches anyObject];
    CGPoint point = [touch locationInView:self];
    [self trace:"began" point:point];
    [self dotAtPoint:point];
}
- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    (void)event;
    UITouch *touch = [touches anyObject];
    CGPoint point = [touch locationInView:self];
    [self trace:"moved" point:point];
    [self dotAtPoint:point];
}
- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    (void)event;
    UITouch *touch = [touches anyObject];
    CGPoint point = [touch locationInView:self];
    [self trace:"ended" point:point];
}
- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    (void)event;
    [self trace:"cancelled" point:CGPointMake(0, 0)];
}
@end

@class RootViewController;

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
    (void)application;
    (void)session;
    (void)options;
    UISceneConfiguration *configuration = [[UISceneConfiguration alloc]
        initWithName:@"Default Configuration"
         sessionRole:UIWindowSceneSessionRoleApplication];
    configuration.delegateClass = [SceneDelegate class];
    return configuration;
}
@end

@interface RootViewController : UIViewController {
    UILabel *_valueLabel;
}
@end

@implementation RootViewController
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
    double width = screen.size.width;

    UILabel *title =
        [[UILabel alloc] initWithFrame:CGRectMake(24, 96, width - 48, 48)];
    title.text = @"Touch";
    title.textColor = [UIColor whiteColor];
    title.font = [UIFont boldSystemFontOfSize:34];
    [self.view addSubview:title];

    UILabel *hint =
        [[UILabel alloc] initWithFrame:CGRectMake(24, 150, width - 48, 24)];
    hint.text = @"Drag across the panel, then the slider";
    hint.textColor = [UIColor colorWithRed:0.6 green:0.63 blue:0.72 alpha:1.0];
    hint.font = [UIFont systemFontOfSize:15];
    [self.view addSubview:hint];

    TrailView *trail = [[TrailView alloc]
        initWithFrame:CGRectMake(24, 196, width - 48, 260)];
    trail.layer.cornerRadius = 18;
    [self.view addSubview:trail];

    UISlider *slider = [[UISlider alloc]
        initWithFrame:CGRectMake(24, 510, width - 48, 31)];
    [slider addTarget:self action:@selector(sliderChanged:)
        forControlEvents:UIControlEventValueChanged];
    [self.view addSubview:slider];

    _valueLabel = [[UILabel alloc]
        initWithFrame:CGRectMake(24, 548, width - 48, 24)];
    _valueLabel.text = @"value 0.000";
    _valueLabel.textColor = [UIColor whiteColor];
    _valueLabel.font = [UIFont systemFontOfSize:15];
    [self.view addSubview:_valueLabel];

    UISwitch *toggle = [[UISwitch alloc]
        initWithFrame:CGRectMake(24, 600, 63, 28)];
    [toggle setOn:NO];
    [toggle addTarget:self action:@selector(switchChanged:)
        forControlEvents:UIControlEventValueChanged];
    [self.view addSubview:toggle];

    UILabel *switchLabel =
        [[UILabel alloc] initWithFrame:CGRectMake(104, 602, 160, 24)];
    switchLabel.text = @"Switch";
    switchLabel.textColor = [UIColor whiteColor];
    switchLabel.font = [UIFont systemFontOfSize:16];
    [self.view addSubview:switchLabel];

    UISegmentedControl *segments = [[UISegmentedControl alloc]
        initWithItems:[NSArray arrayWithObjects:(const id[]){@"One", @"Two",
                                                            @"Three"}
                                           count:3]];
    segments.frame = CGRectMake(24, 664, width - 48, 32);
    [segments setSelectedSegmentIndex:0];
    [segments addTarget:self action:@selector(segmentChanged:)
        forControlEvents:UIControlEventValueChanged];
    [self.view addSubview:segments];

    UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
    button.frame = CGRectMake(24, 732, width - 48, 52);
    button.backgroundColor =
        [UIColor colorWithRed:0.106 green:0.141 blue:0.251 alpha:1.0];
    button.layer.cornerRadius = 16;
    [button setTitle:@"Press" forState:UIControlStateNormal];
    [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [button addTarget:self action:@selector(pressed:)
        forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:button];

    printf("[touch] app ready\n");
    fflush(0);
}
- (void)sliderChanged:(UISlider *)slider
{
    double value = [slider value];
    printf("[slider] %.3f\n", value);
    fflush(0);
    _valueLabel.text =
        [NSString stringWithFormat:@"value %.3f", value];
}
- (void)switchChanged:(UISwitch *)sender
{
    printf("[switch] %d\n", [sender isOn] ? 1 : 0);
    fflush(0);
}
- (void)segmentChanged:(UISegmentedControl *)sender
{
    printf("[segment] %ld\n", [sender selectedSegmentIndex]);
    fflush(0);
}
- (void)pressed:(id)sender
{
    (void)sender;
    printf("[button] pressed\n");
    fflush(0);
}
@end

@implementation SceneDelegate
- (void)scene:(UIScene *)scene
    willConnectToSession:(UISceneSession *)session
                 options:(UISceneConnectionOptions *)connectionOptions
{
    (void)session;
    (void)connectionOptions;
    self.window = [[UIWindow alloc] initWithWindowScene:(UIWindowScene *)scene];
    self.window.frame = [[UIScreen mainScreen] bounds];
    self.window.backgroundColor =
        [UIColor colorWithRed:0.043 green:0.055 blue:0.102 alpha:1.0];
    self.window.rootViewController = [[RootViewController alloc] init];
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
