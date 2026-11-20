#ifndef IOSIM_UIKIT_STUB_H
#define IOSIM_UIKIT_STUB_H

#include "../frameworks/objc_lite.h"

__attribute__((objc_root_class))
@interface NSObject
+ (id)alloc;
+ (Class)class;
- (id)init;
- (id)retain;
- (void)release;
- (id)autorelease;
@end

@interface UIResponder : NSObject
@end

@class UIApplication;
@class UISceneConfiguration;
@class UISceneSession;
@class UISceneConnectionOptions;
@class UIScene;
@class UIWindowScene;

@protocol UIApplicationDelegate
@optional
- (UISceneConfiguration *)application:(UIApplication *)application
    configurationForConnectingSceneSession:(UISceneSession *)session
    options:(UISceneConnectionOptions *)options;
@end

@protocol UIWindowSceneDelegate
@optional
- (void)scene:(UIScene *)scene
    willConnectToSession:(UISceneSession *)session
    options:(UISceneConnectionOptions *)connectionOptions;
@end

@interface CALayer : NSObject
@property CGRect frame;
@property double cornerRadius;
@property double opacity;
- (void)addSublayer:(CALayer *)layer;
@end

@interface UIColor : NSObject
+ (UIColor *)colorWithRed:(double)r green:(double)g blue:(double)b
                    alpha:(double)a;
+ (UIColor *)whiteColor;
+ (UIColor *)blackColor;
+ (UIColor *)systemBlueColor;
@property(readonly) id CGColor;
@end

@interface UIFont : NSObject
+ (UIFont *)systemFontOfSize:(double)size;
+ (UIFont *)boldSystemFontOfSize:(double)size;
@end

@interface UIScreen : NSObject
+ (UIScreen *)mainScreen;
- (CGRect)bounds;
@end

@class NSArray;
@class NSString;
@class NSLayoutConstraint;
@class NSLayoutAnchor;
@class NSLayoutDimension;
@class UILayoutGuide;

@interface NSLayoutConstraint : NSObject
+ (id)constraintWithItem:(id)firstItem attribute:(long)firstAttribute
                relatedBy:(long)relation toItem:(id)secondItem
               attribute:(long)secondAttribute multiplier:(double)multiplier
                constant:(double)constant;
+ (void)activateConstraints:(NSArray *)constraints;
- (void)setActive:(BOOL)active;
- (void)setPriority:(double)priority;
@end

@interface NSLayoutAnchor : NSObject
- (NSLayoutConstraint *)constraintEqualToAnchor:(NSLayoutAnchor *)anchor;
- (NSLayoutConstraint *)constraintEqualToAnchor:(NSLayoutAnchor *)anchor
                                       constant:(double)c;
- (NSLayoutConstraint *)constraintGreaterThanOrEqualToAnchor:
    (NSLayoutAnchor *)anchor;
- (NSLayoutConstraint *)constraintLessThanOrEqualToAnchor:
    (NSLayoutAnchor *)anchor;
@end

@interface NSLayoutDimension : NSLayoutAnchor
- (NSLayoutConstraint *)constraintEqualToConstant:(double)c;
- (NSLayoutConstraint *)constraintGreaterThanOrEqualToConstant:(double)c;
@end

@interface UILayoutGuide : NSObject
@property(readonly) NSLayoutAnchor *leadingAnchor;
@property(readonly) NSLayoutAnchor *trailingAnchor;
@property(readonly) NSLayoutAnchor *topAnchor;
@property(readonly) NSLayoutAnchor *bottomAnchor;
@property(readonly) NSLayoutAnchor *centerXAnchor;
@property(readonly) NSLayoutAnchor *centerYAnchor;
@end

@interface UIView : UIResponder
- (id)initWithFrame:(CGRect)frame;
- (CGRect)bounds;
@property CGRect frame;
@property double alpha;
@property(nonatomic, retain) UIColor *backgroundColor;
@property(readonly) CALayer *layer;
- (void)addSubview:(UIView *)view;
@property BOOL translatesAutoresizingMaskIntoConstraints;
@property(readonly) NSLayoutAnchor *leadingAnchor;
@property(readonly) NSLayoutAnchor *trailingAnchor;
@property(readonly) NSLayoutAnchor *topAnchor;
@property(readonly) NSLayoutAnchor *bottomAnchor;
@property(readonly) NSLayoutAnchor *centerXAnchor;
@property(readonly) NSLayoutAnchor *centerYAnchor;
@property(readonly) NSLayoutDimension *widthAnchor;
@property(readonly) NSLayoutDimension *heightAnchor;
@property(readonly) UILayoutGuide *safeAreaLayoutGuide;
+ (void)animateWithDuration:(double)duration animations:(void (^)(void))animations;
@end

@interface UITextField : UIView
@property(nonatomic, retain) id text;
@property(nonatomic, retain) id placeholder;
@property(nonatomic, retain) UIColor *textColor;
@property(nonatomic, retain) UIFont *font;
@property int keyboardType;
- (BOOL)becomeFirstResponder;
- (BOOL)resignFirstResponder;
@end

@interface UILabel : UIView
@property(nonatomic, retain) id text;
@property(nonatomic, retain) UIColor *textColor;
@property(nonatomic, retain) UIFont *font;
@property int textAlignment;
@property int numberOfLines;
@end

@interface UIViewController : NSObject
- (id)init;
@property(nonatomic, retain) UIView *view;
@property(nonatomic, retain) id title;
@property(readonly) id navigationController;
- (void)loadView;
- (void)viewDidLoad;
- (void)presentViewController:(UIViewController *)controller animated:(BOOL)animated
                   completion:(void (^)(void))completion;
- (void)dismissViewControllerAnimated:(BOOL)animated
                           completion:(void (^)(void))completion;
@end

enum {
    UIControlStateNormal = 0,
    UIControlStateHighlighted = 1
};
enum {
    UIControlEventTouchUpInside = 1 << 6
};
enum {
    UIButtonTypeSystem = 1
};

@interface UIControl : UIView
- (void)addTarget:(id)target action:(SEL)action
    forControlEvents:(unsigned long)events;
@end

@interface UIButton : UIControl
+ (id)buttonWithType:(int)type;
- (void)setTitle:(id)title forState:(unsigned long)state;
- (void)setTitleColor:(UIColor *)color forState:(unsigned long)state;
@property(readonly) UILabel *titleLabel;
@end

@class UIAlertAction;

@interface UIAlertAction : NSObject
+ (id)actionWithTitle:(id)title style:(long)style
              handler:(void (^)(UIAlertAction *action))handler;
@end

@interface UIAlertController : UIViewController
+ (id)alertControllerWithTitle:(id)title message:(id)message
                 preferredStyle:(long)style;
- (void)addAction:(UIAlertAction *)action;
@end

enum { UIAlertControllerStyleActionSheet = 0, UIAlertControllerStyleAlert = 1 };
enum { UIAlertActionStyleDefault = 0, UIAlertActionStyleCancel = 1,
       UIAlertActionStyleDestructive = 2 };

@interface UIActivityIndicatorView : UIView
- (id)initWithActivityIndicatorStyle:(long)style;
- (void)startAnimating;
- (void)stopAnimating;
@end

@interface UIPageControl : UIView
- (void)setNumberOfPages:(long)pages;
- (void)setCurrentPage:(long)page;
@end

@interface UISegmentedControl : UIView
- (id)initWithItems:(NSArray *)items;
- (void)setSelectedSegmentIndex:(long)index;
- (long)selectedSegmentIndex;
@end

@interface UISwitch : UIView
- (void)setOn:(BOOL)on animated:(BOOL)animated;
@end

@interface UISlider : UIView
- (void)setValue:(double)value animated:(BOOL)animated;
@end

@interface UIProgressView : UIView
- (void)setProgress:(double)progress animated:(BOOL)animated;
@end

@interface UIScene : NSObject
@end

@interface UIWindowScene : UIScene
@end

@interface UISceneSession : NSObject
@end

@interface UISceneConnectionOptions : NSObject
@end

@interface UISceneConfiguration : NSObject
- (id)initWithName:(id)name sessionRole:(id)role;
@property(nonatomic) Class delegateClass;
@end

extern id UIWindowSceneSessionRoleApplication;

@interface UIWindow : UIView
@property(nonatomic, retain) UIViewController *rootViewController;
- (id)initWithWindowScene:(UIWindowScene *)scene;
- (void)makeKeyAndVisible;
@end

@interface UIApplication : UIResponder
@end

extern int UIApplicationMain(int argc, char **argv, id principal,
                             id delegateName);

@interface UIBezierPath : NSObject
+ (instancetype)bezierPath;
- (void)moveToPoint:(CGPoint)point;
- (void)addLineToPoint:(CGPoint)point;
@property(readonly) id CGPath;
@end

@interface CAShapeLayer : CALayer
@property(nonatomic, retain) id path;
@property(nonatomic, retain) id fillColor;
@property(nonatomic, retain) id strokeColor;
@property double lineWidth;
@end

@interface CAGradientLayer : CALayer
@property(nonatomic, retain) id colors;
@property CGPoint startPoint;
@property CGPoint endPoint;
@end

@interface UIImage : NSObject
+ (UIImage *)imageNamed:(NSString *)name;
@end

@interface NSArray : NSObject
+ (id)arrayWithObjects:(const id *)objects count:(unsigned long)count;
@property(readonly) unsigned long count;
- (id)objectAtIndex:(unsigned long)index;
@end

@class UITableView, UITableViewCell, NSIndexPath;

@protocol UITableViewDataSource
- (long)tableView:(UITableView *)tableView numberOfRowsInSection:(long)section;
- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath;
@end

@protocol UITableViewDelegate
- (void)tableView:(UITableView *)tableView
    didSelectRowAtIndexPath:(NSIndexPath *)indexPath;
@end

enum {
    UITableViewCellStyleDefault = 0,
    UITableViewCellStyleValue1 = 1,
    UITableViewCellStyleValue2 = 2,
    UITableViewCellStyleSubtitle = 3,
    UITableViewCellAccessoryNone = 0,
    UITableViewCellAccessoryDisclosureIndicator = 1,
    UITableViewCellAccessoryDetailDisclosureButton = 2,
    UITableViewCellAccessoryCheckmark = 3,
    UITableViewStylePlain = 0
};

@interface NSIndexPath : NSObject
+ (id)indexPathForRow:(long)row inSection:(long)section;
@property(readonly) long row;
@property(readonly) long section;
@end

@interface UITableViewCell : UIView
- (id)initWithStyle:(long)style reuseIdentifier:(id)identifier;
@property(readonly) UILabel *textLabel;
@property(readonly) UILabel *detailTextLabel;
@property long accessoryType;
@end

@interface UITableView : UIView
- (id)initWithFrame:(CGRect)frame style:(long)style;
@property(nonatomic, retain) id dataSource;
@property(nonatomic, retain) id delegate;
@property double rowHeight;
@property CGPoint contentOffset;
@property CGSize contentSize;
- (void)reloadData;
- (id)dequeueReusableCellWithIdentifier:(id)identifier;
@end

@interface UIImageView : UIView
- (instancetype)initWithImage:(UIImage *)image;
@property(nonatomic, retain) UIImage *image;
@property int contentMode;
@end


@interface UIStackView : UIView
- (id)initWithArrangedSubviews:(NSArray *)views;
- (void)addArrangedSubview:(UIView *)view;
@property long axis;
@property double spacing;
@property long distribution;
@property long alignment;
@end

@interface UINavigationController : UIViewController
- (id)initWithRootViewController:(UIViewController *)root;
- (void)pushViewController:(UIViewController *)controller animated:(BOOL)animated;
- (UIViewController *)popViewControllerAnimated:(BOOL)animated;
@end

#define CGRectZero CGRectMake(0, 0, 0, 0)

#endif
