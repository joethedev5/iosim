#ifndef IOSIM_UIKIT_STUB_H
#define IOSIM_UIKIT_STUB_H

#include "../frameworks/objc_lite.h"
#include "../frameworks/coregraphics_lite.h"

typedef struct {
    unsigned long location;
    unsigned long length;
} NSRange;

static inline NSRange NSMakeRange(unsigned long location,
                                  unsigned long length)
{
    NSRange range = { location, length };
    return range;
}

__attribute__((objc_root_class))
@interface NSObject {
    Class isa;
}
+ (id)alloc;
+ (Class)class;
- (Class)class;
- (id)init;
- (id)retain;
- (void)release;
- (id)autorelease;
@end

@interface NSString : NSObject
+ (id)stringWithFormat:(id)format, ...;
+ (id)stringWithUTF8String:(const char *)string;
- (const char *)UTF8String;
- (unsigned long)length;
- (id)initWithData:(id)data encoding:(unsigned long)encoding;
@end

@interface NSData : NSObject
+ (NSData *)dataWithContentsOfFile:(NSString *)path;
@end

@interface NSTimer : NSObject
+ (id)scheduledTimerWithTimeInterval:(double)interval target:(id)target
    selector:(SEL)selector userInfo:(id)userInfo repeats:(BOOL)repeats;
- (void)invalidate;
@end

@interface NSBundle : NSObject
+ (NSBundle *)mainBundle;
- (NSString *)pathForResource:(NSString *)name ofType:(NSString *)type;
@end

@interface NSNumber : NSObject
+ (id)numberWithDouble:(double)value;
- (double)doubleValue;
@end

@interface NSDate : NSObject
+ (id)date;
+ (id)dateWithTimeIntervalSince1970:(double)interval;
- (double)timeIntervalSince1970;
@end

@interface NSCalendar : NSObject
@end

typedef struct {
    unsigned long state;
    id *itemsPtr;
    unsigned long *mutationsPtr;
    unsigned long extra[5];
} NSFastEnumerationState;

@protocol NSFastEnumeration
- (unsigned long)countByEnumeratingWithState:(NSFastEnumerationState *)state
                                     objects:(id *)buffer
                                       count:(unsigned long)len;
@end

@interface NSSet : NSObject <NSFastEnumeration>
- (unsigned long)count;
- (id)anyObject;
- (id)allObjects;
- (BOOL)containsObject:(id)object;
- (unsigned long)countByEnumeratingWithState:(NSFastEnumerationState *)state
                                     objects:(id *)buffer
                                       count:(unsigned long)len;
@end

@class UIView;
@class UIWindow;

typedef enum {
    UITouchPhaseBegan = 0,
    UITouchPhaseMoved = 1,
    UITouchPhaseStationary = 2,
    UITouchPhaseEnded = 3,
    UITouchPhaseCancelled = 4
} UITouchPhase;

@interface UITouch : NSObject {
@public
    CGPoint _location;
    CGPoint _previousLocation;
    long _phase;
    double _timestamp;
    UIView *_view;
    UIWindow *_window;
    unsigned long _tapCount;
}
- (CGPoint)locationInView:(UIView *)view;
- (CGPoint)previousLocationInView:(UIView *)view;
- (long)phase;
- (double)timestamp;
- (unsigned long)tapCount;
- (UIView *)view;
- (UIWindow *)window;
@end

@interface UIEvent : NSObject
- (NSSet *)allTouches;
- (NSSet *)touchesForView:(UIView *)view;
- (NSSet *)touchesForWindow:(UIWindow *)window;
@end

@interface UIResponder : NSObject
- (UIResponder *)nextResponder;
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event;
- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event;
- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event;
- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event;
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

@class UIImage;

@interface CALayer : NSObject
@property CGRect frame;
@property CGRect bounds;
@property CGPoint position;
@property CGPoint anchorPoint;
@property(nonatomic, retain) id contents;
@property double cornerRadius;
@property double opacity;
@property(nonatomic, retain) id backgroundColor;
@property(nonatomic, retain) CALayer *mask;
@property CATransform3D transform;
- (void)addSublayer:(CALayer *)layer;
- (void)addAnimation:(id)animation forKey:(id)key;
- (void)removeAnimationForKey:(id)key;
- (CALayer *)presentationLayer;
@end

@class NSArray;

@interface CAAnimation : NSObject
+ (id)animationWithKeyPath:(id)path;
- (void)setFromValue:(id)value;
- (void)setToValue:(id)value;
- (void)setDuration:(double)duration;
- (void)setRepeatCount:(double)count;
- (void)setTimingFunction:(id)function;
@end

@interface CABasicAnimation : CAAnimation
@end

@interface CAKeyframeAnimation : CAAnimation
- (void)setValues:(id)values;
- (void)setKeyTimes:(id)keyTimes;
@end

@interface CASpringAnimation : CAAnimation
- (void)setMass:(double)mass;
- (void)setStiffness:(double)stiffness;
- (void)setDamping:(double)damping;
- (void)setInitialVelocity:(double)velocity;
- (double)settlingDuration;
@end

@interface CAAnimationGroup : CAAnimation
- (void)setAnimations:(NSArray *)animations;
- (NSArray *)animations;
@end

@interface CADisplayLink : NSObject
+ (CADisplayLink *)displayLinkWithTarget:(id)target selector:(SEL)selector;
- (void)addToRunLoop:(id)runloop forMode:(id)mode;
- (void)invalidate;
@property(readonly) double timestamp;
@property(readonly) double duration;
@property(readonly) double targetTimestamp;
@property(getter=isPaused) BOOL paused;
@property(readonly, getter=isValid) BOOL valid;
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
- (double)scale;
@end

@class NSArray;
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

enum {
    UIViewAnimationOptionLayoutSubviews = 1 << 0,
    UIViewAnimationOptionAllowUserInteraction = 1 << 1,
    UIViewAnimationOptionBeginFromCurrentState = 1 << 2,
    UIViewAnimationOptionRepeat = 1 << 3,
    UIViewAnimationOptionAutoreverse = 1 << 4,
    UIViewAnimationOptionCurveEaseInOut = 0 << 16,
    UIViewAnimationOptionCurveEaseIn = 1 << 16,
    UIViewAnimationOptionCurveEaseOut = 2 << 16,
    UIViewAnimationOptionCurveLinear = 3 << 16
};

@interface UIView : UIResponder
- (id)initWithFrame:(CGRect)frame;
- (CGRect)bounds;
- (void)setBounds:(CGRect)bounds;
@property CGRect frame;
@property CGPoint center;
- (CGPoint)convertPoint:(CGPoint)point toView:(UIView *)view;
- (CGPoint)convertPoint:(CGPoint)point fromView:(UIView *)view;
- (CGRect)convertRect:(CGRect)rect toView:(UIView *)view;
- (CGRect)convertRect:(CGRect)rect fromView:(UIView *)view;
@property double alpha;
@property CGAffineTransform transform;
@property(nonatomic, retain) UIColor *backgroundColor;
@property(readonly) CALayer *layer;
- (void)drawRect:(CGRect)rect;
- (void)addSubview:(UIView *)view;
- (void)addGestureRecognizer:(id)recognizer;
- (void)addInteraction:(id)interaction;
- (void)removeInteraction:(id)interaction;
- (NSArray *)interactions;
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
+ (void)animateWithDuration:(double)duration animations:(void (^)(void))animations
                 completion:(void (^)(BOOL finished))completion;
+ (void)animateWithDuration:(double)duration delay:(double)delay
                    options:(unsigned long)options
                 animations:(void (^)(void))animations
                 completion:(void (^)(BOOL finished))completion;
@end

@class UITextField;

@protocol UITextFieldDelegate
@optional
- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField;
- (void)textFieldDidBeginEditing:(UITextField *)textField;
- (BOOL)textFieldShouldEndEditing:(UITextField *)textField;
- (void)textFieldDidEndEditing:(UITextField *)textField;
- (BOOL)textField:(UITextField *)textField
    shouldChangeCharactersInRange:(NSRange)range
                replacementString:(NSString *)string;
- (BOOL)textFieldShouldReturn:(UITextField *)textField;
@end

@interface UITextField : UIView
@property(nonatomic, retain) id text;
@property(nonatomic, retain) id placeholder;
@property(nonatomic, retain) UIColor *textColor;
@property(nonatomic, retain) UIFont *font;
@property int keyboardType;
@property(nonatomic, assign) id delegate;
- (BOOL)becomeFirstResponder;
- (BOOL)resignFirstResponder;
- (void)insertText:(id)text;
- (void)deleteBackward;
- (void)handleReturnKey;
@end

@interface UITextView : UIView
@property(nonatomic, retain) id text;
@property(nonatomic, retain) UIColor *textColor;
@property(nonatomic, retain) UIFont *font;
@property NSRange selectedRange;
- (void)setEditable:(BOOL)editable;
- (void)insertText:(id)text;
- (void)deleteBackward;
- (BOOL)becomeFirstResponder;
- (BOOL)resignFirstResponder;
- (void)copy:(id)sender;
- (void)paste:(id)sender;
@end

@interface UISearchBar : UIView
@property(nonatomic, retain) id delegate;
@property(nonatomic, retain) id text;
@property(nonatomic, retain) id placeholder;
@property BOOL showsCancelButton;
- (void)setShowsCancelButton:(BOOL)shows animated:(BOOL)animated;
@end

@interface UILabel : UIView
@property(nonatomic, retain) id text;
@property(nonatomic, retain) UIColor *textColor;
@property(nonatomic, retain) UIFont *font;
@property int textAlignment;
@property int numberOfLines;
@end

@class UINavigationItem;

enum {
    UIModalPresentationFullScreen = 0,
    UIModalPresentationPageSheet = 1,
    UIModalPresentationFormSheet = 2,
    UIModalPresentationOverFullScreen = 5,
    UIModalPresentationAutomatic = -2
};

@interface UIViewController : NSObject
- (id)init;
@property(nonatomic) long modalPresentationStyle;
@property(nonatomic, retain) UIView *view;
@property(nonatomic, retain) id title;
@property(readonly) id navigationController;
@property(readonly) UINavigationItem *navigationItem;
@property(nonatomic, retain) id tabBarItem;
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
    UIControlEventTouchDown = 1 << 0,
    UIControlEventTouchDragInside = 1 << 2,
    UIControlEventTouchDragOutside = 1 << 3,
    UIControlEventTouchUpInside = 1 << 6,
    UIControlEventTouchUpOutside = 1 << 7,
    UIControlEventTouchCancel = 1 << 8,
    UIControlEventValueChanged = 1 << 12
};
enum {
    UIButtonTypeSystem = 1
};

@interface UIControl : UIView
- (void)addTarget:(id)target action:(SEL)action
    forControlEvents:(unsigned long)events;
- (BOOL)isHighlighted;
- (BOOL)isEnabled;
- (void)setEnabled:(BOOL)enabled;
- (unsigned long)state;
@end

@interface UIRefreshControl : UIControl
- (BOOL)isRefreshing;
- (void)beginRefreshing;
- (void)endRefreshing;
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

/* ---------------------------------------------------------- activities */

typedef NSString *UIActivityType;
extern NSString *UIActivityTypePostToFacebook;
extern NSString *UIActivityTypePostToTwitter;
extern NSString *UIActivityTypePostToWeibo;
extern NSString *UIActivityTypeMessage;
extern NSString *UIActivityTypeMail;
extern NSString *UIActivityTypePrint;
extern NSString *UIActivityTypeCopyToPasteboard;
extern NSString *UIActivityTypeAssignToContact;
extern NSString *UIActivityTypeSaveToCameraRoll;
extern NSString *UIActivityTypeAddToReadingList;
extern NSString *UIActivityTypePostToFlickr;
extern NSString *UIActivityTypePostToVimeo;
extern NSString *UIActivityTypePostToTencentWeibo;
extern NSString *UIActivityTypeAirDrop;
extern NSString *UIActivityTypeOpenIniOSApp;
extern NSString *UIActivityTypeMarkupAsPDF;

enum { UIActivityCategoryAction = 0, UIActivityCategoryShare = 1 };

@class UIImage;
@class NSError;
@class UIActivityViewController;

typedef void (^UIActivityViewControllerCompletionWithItemsHandler)(
    UIActivityType activityType, BOOL completed, NSArray *returnedItems,
    NSError *error);
typedef void (^UIActivityViewControllerCompletionHandler)(
    UIActivityType activityType, BOOL completed);

@protocol UIActivityItemSource
- (id)activityViewControllerPlaceholderItem:(UIActivityViewController *)activityViewController;
- (id)activityViewController:(UIActivityViewController *)activityViewController
        itemForActivityType:(UIActivityType)activityType;
@optional
- (id)activityViewController:(UIActivityViewController *)activityViewController
        subjectForActivityType:(UIActivityType)activityType;
- (UIImage *)activityViewController:(UIActivityViewController *)activityViewController
    thumbnailImageForActivityType:(UIActivityType)activityType
                     suggestedSize:(CGSize)size;
- (id)activityViewController:(UIActivityViewController *)activityViewController
    dataTypeIdentifierForActivityType:(UIActivityType)activityType;
@end

@interface UIActivity : NSObject
+ (long)activityCategory;
- (UIActivityType)activityType;
- (NSString *)activityTitle;
- (UIImage *)activityImage;
- (BOOL)canPerformWithActivityItems:(NSArray *)activityItems;
- (void)prepareWithActivityItems:(NSArray *)activityItems;
- (UIViewController *)activityViewController;
- (void)performActivity;
- (void)activityDidFinish:(BOOL)completed;
@end

@interface UIActivityViewController : UIViewController
- (id)initWithActivityItems:(NSArray *)activityItems
       applicationActivities:(NSArray *)applicationActivities;
- (NSArray *)activityItems;
- (NSArray *)applicationActivities;
- (void)setExcludedActivityTypes:(NSArray *)excludedActivityTypes;
- (NSArray *)excludedActivityTypes;
- (void)setCompletionWithItemsHandler:
    (UIActivityViewControllerCompletionWithItemsHandler)handler;
- (UIActivityViewControllerCompletionWithItemsHandler)completionWithItemsHandler;
- (void)setCompletionHandler:
    (UIActivityViewControllerCompletionHandler)handler;
- (UIActivityViewControllerCompletionHandler)completionHandler;
@end

/* ---------------------------------------------------- context menus */

typedef NSString *UIActionIdentifier;

enum {
    UIMenuElementAttributesDisabled = 1 << 0,
    UIMenuElementAttributesDestructive = 1 << 1,
    UIMenuElementAttributesHidden = 1 << 2,
    UIMenuElementAttributesKeepsMenuPresented = 1 << 3
};
enum {
    UIMenuOptionsDisplayInline = 1 << 0,
    UIMenuOptionsDestructive = 1 << 1,
    UIMenuOptionsSingleSelection = 1 << 2,
    UIMenuOptionsDisplayAsPalette = 1 << 3
};

@class UIMenu, UIAction, UIContextMenuConfiguration;
@class UIContextMenuInteraction;

@interface UIMenuElement : NSObject
- (NSString *)title;
- (UIImage *)image;
- (long)attributes;
@end

@interface UIAction : UIMenuElement
+ (id)actionWithTitle:(NSString *)title image:(UIImage *)image
           identifier:(UIActionIdentifier)identifier
              handler:(void (^)(UIAction *action))handler;
- (UIActionIdentifier)identifier;
- (long)state;
- (void)setState:(long)state;
- (void)setAttributes:(long)attributes;
@end

@interface UIMenu : UIMenuElement
+ (id)menuWithTitle:(NSString *)title children:(NSArray *)children;
+ (id)menuWithTitle:(NSString *)title image:(UIImage *)image
         identifier:(NSString *)identifier options:(long)options
           children:(NSArray *)children;
- (NSArray *)children;
- (NSString *)identifier;
- (long)options;
@end

@interface UIContextMenuConfiguration : NSObject
+ (id)configurationWithIdentifier:(NSString *)identifier
                  previewProvider:(UIViewController *(^)(void))previewProvider
                   actionProvider:(UIMenu *(^)(NSArray *))actionProvider;
- (NSString *)identifier;
- (UIViewController *(^)(void))previewProvider;
- (UIMenu *(^)(NSArray *))actionProvider;
@end

@interface UIContextMenuInteraction : NSObject
- (id)initWithDelegate:(id)delegate;
- (id)delegate;
- (CGPoint)locationInView:(UIView *)view;
- (UIView *)view;
@end

@protocol UIContextMenuInteractionDelegate
- (UIContextMenuConfiguration *)contextMenuInteraction:
    (UIContextMenuInteraction *)interaction
    configurationForMenuAtLocation:(CGPoint)location;
@optional
- (void)contextMenuInteraction:(UIContextMenuInteraction *)interaction
    willDisplayMenuForConfiguration:(UIContextMenuConfiguration *)configuration
                            animator:(id)animator;
- (void)contextMenuInteraction:(UIContextMenuInteraction *)interaction
    willEndForConfiguration:(UIContextMenuConfiguration *)configuration
                   animator:(id)animator;
@end

@interface UIActivityIndicatorView : UIView
- (id)initWithActivityIndicatorStyle:(long)style;
- (void)startAnimating;
- (void)stopAnimating;
@end

enum {
    UIBlurEffectStyleExtraLight = 0,
    UIBlurEffectStyleLight = 1,
    UIBlurEffectStyleDark = 2,
    UIBlurEffectStyleSystemUltraThinMaterial = 3,
    UIBlurEffectStyleSystemThinMaterial = 4,
    UIBlurEffectStyleSystemMaterial = 5,
    UIBlurEffectStyleSystemThickMaterial = 6,
    UIBlurEffectStyleSystemChromeMaterial = 7
};

@interface UIBlurEffect : NSObject
+ (UIBlurEffect *)effectWithStyle:(long)style;
@end

@interface UIVisualEffectView : UIView
- (id)initWithEffect:(UIBlurEffect *)effect;
- (UIBlurEffect *)effect;
@property(readonly) UIView *contentView;
@end

@interface UIPageControl : UIView
- (void)setNumberOfPages:(long)pages;
- (void)setCurrentPage:(long)page;
- (void)addTarget:(id)target action:(SEL)action
    forControlEvents:(unsigned long)events;
@end

@interface UISegmentedControl : UIView
- (id)initWithItems:(NSArray *)items;
- (void)setSelectedSegmentIndex:(long)index;
- (long)selectedSegmentIndex;
- (void)addTarget:(id)target action:(SEL)action
    forControlEvents:(unsigned long)events;
@end

@interface UISwitch : UIView
- (void)setOn:(BOOL)on;
- (void)setOn:(BOOL)on animated:(BOOL)animated;
- (BOOL)isOn;
- (void)addTarget:(id)target action:(SEL)action
    forControlEvents:(unsigned long)events;
@end

@interface UIStepper : UIControl
@property double value;
@property double minimumValue;
@property double maximumValue;
@property double stepValue;
@end

@interface UISlider : UIView
- (void)setValue:(double)value animated:(BOOL)animated;
- (double)value;
- (void)addTarget:(id)target action:(SEL)action
    forControlEvents:(unsigned long)events;
@end

@class UIPickerView;

@protocol UIPickerViewDataSource
- (long)numberOfComponentsInPickerView:(UIPickerView *)pickerView;
- (long)pickerView:(UIPickerView *)pickerView
    numberOfRowsInComponent:(long)component;
@end

@protocol UIPickerViewDelegate
@optional
- (id)pickerView:(UIPickerView *)pickerView titleForRow:(long)row
    forComponent:(long)component;
- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(long)row
    inComponent:(long)component;
@end

@interface UIPickerView : UIView
@property(nonatomic, retain) id dataSource;
@property(nonatomic, retain) id delegate;
- (long)numberOfComponents;
- (long)numberOfRowsInComponent:(long)component;
- (long)selectedRowInComponent:(long)component;
- (void)selectRow:(long)row inComponent:(long)component animated:(BOOL)animated;
- (void)reloadAllComponents;
- (void)reloadComponent:(long)component;
@end

enum {
    UIDatePickerModeTime = 0,
    UIDatePickerModeDate = 1,
    UIDatePickerModeDateAndTime = 2,
    UIDatePickerModeCountDownTimer = 3
};

enum {
    UIDatePickerStyleAutomatic = 0,
    UIDatePickerStyleWheels = 1,
    UIDatePickerStyleCompact = 2,
    UIDatePickerStyleInline = 3
};

@interface UIDatePicker : UIControl
@property long datePickerMode;
@property long preferredDatePickerStyle;
@property(nonatomic, retain) NSDate *date;
@property(nonatomic, retain) NSCalendar *calendar;
@property double countDownDuration;
- (void)setDate:(NSDate *)date animated:(BOOL)animated;
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

@interface UIScrollView : UIView
@property(nonatomic) CGSize contentSize;
@property(nonatomic) CGPoint contentOffset;
@property(nonatomic) UIEdgeInsets contentInset;
@property(nonatomic) BOOL pagingEnabled;
@property(nonatomic, getter=isScrollEnabled) BOOL scrollEnabled;
@property(nonatomic, readonly, getter=isDragging) BOOL dragging;
@property(nonatomic, readonly, getter=isDecelerating) BOOL decelerating;
@property(nonatomic, readonly, getter=isTracking) BOOL tracking;
@property(nonatomic) BOOL alwaysBounceVertical;
@property(nonatomic) BOOL alwaysBounceHorizontal;
@property(nonatomic) double decelerationRate;
@property(nonatomic, assign) id delegate;
@property(nonatomic) double zoomScale;
@property(nonatomic) double minimumZoomScale;
@property(nonatomic) double maximumZoomScale;
@property(nonatomic, readonly, getter=isZooming) BOOL zooming;
@property(nonatomic, readonly, getter=isZoomBouncing) BOOL zoomBouncing;
- (void)setContentOffset:(CGPoint)offset animated:(BOOL)animated;
- (void)setZoomScale:(double)scale animated:(BOOL)animated;
- (void)zoomToRect:(CGRect)rect animated:(BOOL)animated;
@end

@interface UIWindow : UIView
@property(nonatomic, retain) UIViewController *rootViewController;
- (id)initWithWindowScene:(UIWindowScene *)scene;
- (void)makeKeyAndVisible;
- (void)dispatchTouchDownX:(int)x y:(int)y;
- (void)dispatchTouchMoveX:(int)x y:(int)y;
- (void)dispatchTouchUpX:(int)x y:(int)y;
@end

@protocol UIScrollViewDelegate
@optional
- (void)scrollViewDidScroll:(UIScrollView *)scrollView;
- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView;
- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView
                  willDecelerate:(BOOL)decelerate;
- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView;
- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView;
- (void)scrollViewWillEndDragging:(UIScrollView *)scrollView
                     withVelocity:(CGPoint)velocity
              targetContentOffset:(CGPoint *)targetContentOffset;
- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView;
- (void)scrollViewDidZoom:(UIScrollView *)scrollView;
@end

enum {
    UIApplicationStateActive = 0,
    UIApplicationStateInactive = 1,
    UIApplicationStateBackground = 2
};

@interface UIApplication : UIResponder
+ (UIApplication *)sharedApplication;
- (long)applicationState;
@end

@interface UIPasteboard : NSObject
+ (UIPasteboard *)generalPasteboard;
@property(nonatomic, retain) id string;
@property(readonly) long changeCount;
- (BOOL)hasStrings;
- (id)items;
- (void)setItems:(id)items;
- (id)dataForPasteboardType:(id)type;
- (void)setData:(id)data forPasteboardType:(id)type;
@end

@interface UIMenuItem : NSObject
- (id)initWithTitle:(id)title action:(SEL)action;
- (id)title;
- (SEL)action;
@end

@interface UIMenuController : NSObject
+ (UIMenuController *)sharedMenuController;
- (void)setMenuItems:(NSArray *)items;
- (NSArray *)menuItems;
- (void)setTargetRect:(CGRect)rect inView:(UIView *)view;
- (void)setMenuVisible:(BOOL)visible;
- (void)setMenuVisible:(BOOL)visible animated:(BOOL)animated;
- (BOOL)isMenuVisible;
@end

extern int UIApplicationMain(int argc, char **argv, id principal,
                             id delegateName);

@interface UIBezierPath : NSObject
+ (instancetype)bezierPath;
+ (instancetype)bezierPathWithOvalInRect:(CGRect)rect;
- (void)moveToPoint:(CGPoint)point;
- (void)addLineToPoint:(CGPoint)point;
- (void)addOvalInRect:(CGRect)rect;
- (void)addQuadCurveToPoint:(CGPoint)point controlPoint:(CGPoint)control;
- (void)addCurveToPoint:(CGPoint)point controlPoint1:(CGPoint)control1
           controlPoint2:(CGPoint)control2;
@property(readonly) id CGPath;
@end

@interface CAShapeLayer : CALayer
@property(nonatomic, retain) id path;
@property(nonatomic, retain) id fillColor;
@property(nonatomic, retain) id strokeColor;
@property double lineWidth;
@property double strokeStart;
@property double strokeEnd;
@property int lineCap;
@property int lineJoin;
@end

@interface CAGradientLayer : CALayer
@property(nonatomic, retain) id colors;
@property(nonatomic, retain) id locations;
@property CGPoint startPoint;
@property CGPoint endPoint;
@end

@interface UIImage : NSObject {
@public
    unsigned char *_rgba;
    int _width;
    int _height;
}
+ (UIImage *)imageNamed:(NSString *)name;
+ (UIImage *)imageWithCGImage:(CGImageRef)image;
- (int)width;
- (int)height;
- (CGImageRef)CGImage;
@end

@interface UITabBarItem : NSObject
- (id)initWithTitle:(NSString *)title image:(UIImage *)image tag:(long)tag;
@end

@interface UITabBarController : UIViewController
- (void)setViewControllers:(NSArray *)controllers;
- (NSArray *)viewControllers;
- (void)setSelectedIndex:(int)index;
- (int)selectedIndex;
- (UIViewController *)selectedViewController;
@end

@interface NSArray : NSObject <NSFastEnumeration>
+ (id)arrayWithObjects:(const id *)objects count:(unsigned long)count;
+ (id)arrayWithObject:(id)object;
@property(readonly) unsigned long count;
- (id)objectAtIndex:(unsigned long)index;
- (id)objectAtIndexedSubscript:(unsigned long)index;
- (unsigned long)countByEnumeratingWithState:(NSFastEnumerationState *)state
                                     objects:(id *)buffer
                                       count:(unsigned long)len;
@end

@interface NSMutableArray : NSArray
+ (id)array;
- (void)addObject:(id)object;
- (void)removeObjectAtIndex:(unsigned long)index;
- (void)insertObject:(id)object atIndex:(unsigned long)index;
- (void)setObject:(id)object atIndexedSubscript:(unsigned long)index;
@end

@interface NSDictionary : NSObject <NSFastEnumeration>
+ (id)dictionaryWithObjectsAndKeys:(id)firstObject, ...;
@property(readonly) unsigned long count;
- (id)objectForKey:(id)key;
- (id)objectForKeyedSubscript:(id)key;
- (unsigned long)countByEnumeratingWithState:(NSFastEnumerationState *)state
                                     objects:(id *)buffer
                                       count:(unsigned long)len;
@end

@interface NSMutableDictionary : NSDictionary
+ (id)dictionary;
- (void)setObject:(id)object forKey:(id)key;
- (void)removeObjectForKey:(id)key;
- (void)setObject:(id)object forKeyedSubscript:(id)key;
@end

@class UITableView, UITableViewCell, NSIndexPath;

enum {
    UITableViewCellEditingStyleNone = 0,
    UITableViewCellEditingStyleDelete = 1,
    UITableViewCellEditingStyleInsert = 2
};

@protocol UITableViewDataSource
- (long)tableView:(UITableView *)tableView numberOfRowsInSection:(long)section;
- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath;
@optional
- (BOOL)tableView:(UITableView *)tableView
    canEditRowAtIndexPath:(NSIndexPath *)indexPath;
- (void)tableView:(UITableView *)tableView commitEditingStyle:(long)style
    forRowAtIndexPath:(NSIndexPath *)indexPath;
@end

@protocol UITableViewDelegate
@optional
- (void)tableView:(UITableView *)tableView
    didSelectRowAtIndexPath:(NSIndexPath *)indexPath;
- (id)tableView:(UITableView *)tableView
    contextMenuConfigurationForRowAtIndexPath:(NSIndexPath *)indexPath
                                        point:(CGPoint)point;
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

@class UICollectionView, UICollectionViewCell;

@protocol UICollectionViewDataSource
- (long)collectionView:(UICollectionView *)collectionView
    numberOfItemsInSection:(long)section;
- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView
            cellForItemAtIndexPath:(NSIndexPath *)indexPath;
@optional
- (long)numberOfSectionsInCollectionView:
    (UICollectionView *)collectionView;
@end

@protocol UICollectionViewDelegate
- (void)collectionView:(UICollectionView *)collectionView
    didSelectItemAtIndexPath:(NSIndexPath *)indexPath;
@optional
- (id)collectionView:(UICollectionView *)collectionView
    contextMenuConfigurationForItemAtIndexPath:(NSIndexPath *)indexPath
                                        point:(CGPoint)point;
@end

enum {
    UICollectionViewScrollDirectionVertical = 0,
    UICollectionViewScrollDirectionHorizontal = 1
};

@interface UICollectionViewLayout : NSObject
@end

@interface UICollectionViewFlowLayout : UICollectionViewLayout
@property CGSize itemSize;
@property double minimumInteritemSpacing;
@property double minimumLineSpacing;
@property UIEdgeInsets sectionInset;
@property long scrollDirection;
@end

@interface UICollectionViewCell : UIView
@property(readonly) UIView *contentView;
@property(readonly) id reuseIdentifier;
- (void)setSelected:(BOOL)selected animated:(BOOL)animated;
@end

@interface UICollectionView : UIView
@property(nonatomic, retain) id dataSource;
@property(nonatomic, retain) id delegate;
@property CGPoint contentOffset;
@property CGSize contentSize;
- (id)initWithFrame:(CGRect)frame
 collectionViewLayout:(UICollectionViewLayout *)layout;
- (void)registerClass:(Class)cellClass
    forCellWithReuseIdentifier:(id)identifier;
- (id)dequeueReusableCellWithReuseIdentifier:(id)identifier
                               forIndexPath:(NSIndexPath *)indexPath;
- (void)reloadData;
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
@property(nonatomic, retain) UIRefreshControl *refreshControl;
- (void)reloadData;
- (id)dequeueReusableCellWithIdentifier:(id)identifier;
- (void)setEditing:(BOOL)editing animated:(BOOL)animated;
- (BOOL)isEditing;
- (void)deleteRowsAtIndexPaths:(NSArray *)indexPaths
           withRowAnimation:(long)animation;
@end

void UIGraphicsBeginImageContextWithOptions(CGSize size, BOOL opaque,
                                            double scale);
void UIGraphicsBeginImageContext(CGSize size);
CGContextRef UIGraphicsGetCurrentContext(void);
void UIGraphicsPushContext(CGContextRef context);
void UIGraphicsPopContext(void);
UIImage *UIGraphicsGetImageFromCurrentImageContext(void);
void UIGraphicsEndImageContext(void);

@interface UIImage (Drawing)
- (void)drawInRect:(CGRect)rect;
- (void)drawAtPoint:(CGPoint)point;
@end

extern id NSFontAttributeName;
extern id NSForegroundColorAttributeName;
extern id NSBackgroundColorAttributeName;

@interface NSString (UIKitDrawing)
- (CGSize)sizeWithAttributes:(NSDictionary *)attributes;
- (void)drawAtPoint:(CGPoint)point withAttributes:(NSDictionary *)attributes;
- (void)drawInRect:(CGRect)rect withAttributes:(NSDictionary *)attributes;
- (CGRect)boundingRectWithSize:(CGSize)size
                       options:(unsigned long)options
                    attributes:(NSDictionary *)attributes
                       context:(id)context;
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

enum {
    UIBarButtonItemStylePlain = 0,
    UIBarButtonItemStyleBordered = 1,
    UIBarButtonItemStyleDone = 2
};

enum {
    UIBarButtonSystemItemDone = 0,
    UIBarButtonSystemItemCancel = 1,
    UIBarButtonSystemItemEdit = 2,
    UIBarButtonSystemItemSave = 3,
    UIBarButtonSystemItemAdd = 4,
    UIBarButtonSystemItemFlexibleSpace = 5,
    UIBarButtonSystemItemFixedSpace = 6,
    UIBarButtonSystemItemCompose = 7,
    UIBarButtonSystemItemReply = 8,
    UIBarButtonSystemItemSearch = 9,
    UIBarButtonSystemItemClose = 10
};

@interface UIBarButtonItem : NSObject
- (id)initWithTitle:(id)title style:(long)style target:(id)target
             action:(SEL)action;
- (id)initWithBarButtonSystemItem:(long)item target:(id)target
                           action:(SEL)action;
@property(nonatomic, retain) id title;
@end

@interface UINavigationItem : NSObject
- (id)initWithTitle:(id)title;
@property(nonatomic, retain) id title;
@property(nonatomic, retain) UIBarButtonItem *leftBarButtonItem;
@property(nonatomic, retain) UIBarButtonItem *rightBarButtonItem;
@property BOOL hidesBackButton;
@end

@interface UINavigationBar : UIView
- (void)setItems:(NSArray *)items animated:(BOOL)animated;
- (NSArray *)items;
- (UINavigationItem *)topItem;
- (void)pushNavigationItem:(UINavigationItem *)item animated:(BOOL)animated;
- (UINavigationItem *)popNavigationItemAnimated:(BOOL)animated;
@property(nonatomic, retain) UIColor *barTintColor;
@end

@interface UIToolbar : UIView
- (void)setItems:(NSArray *)items animated:(BOOL)animated;
- (NSArray *)items;
@property(nonatomic, retain) UIColor *barTintColor;
@property(nonatomic, retain) UIColor *tintColor;
@property int barStyle;
@property BOOL translucent;
@end

@class UIGestureRecognizer;

@interface UINavigationController : UIViewController
- (id)initWithRootViewController:(UIViewController *)root;
- (void)pushViewController:(UIViewController *)controller animated:(BOOL)animated;
- (UIViewController *)popViewControllerAnimated:(BOOL)animated;
- (NSArray *)viewControllers;
- (UIGestureRecognizer *)interactivePopGestureRecognizer;
@end

typedef enum {
    UIGestureRecognizerStatePossible = 0,
    UIGestureRecognizerStateBegan = 1,
    UIGestureRecognizerStateChanged = 2,
    UIGestureRecognizerStateEnded = 3,
    UIGestureRecognizerStateCancelled = 4,
    UIGestureRecognizerStateFailed = 5
} UIGestureRecognizerState;

@interface UIGestureRecognizer : NSObject
- (id)initWithTarget:(id)target action:(SEL)action;
- (long)state;
- (CGPoint)locationInView:(UIView *)view;
@end

@interface UIPanGestureRecognizer : UIGestureRecognizer
- (CGPoint)translationInView:(UIView *)view;
- (CGPoint)velocityInView:(UIView *)view;
- (void)setTranslation:(CGPoint)translation inView:(UIView *)view;
@end

typedef enum {
    UIRectEdgeNone = 0,
    UIRectEdgeTop = 1 << 0,
    UIRectEdgeLeft = 1 << 1,
    UIRectEdgeBottom = 1 << 2,
    UIRectEdgeRight = 1 << 3,
    UIRectEdgeAll = UIRectEdgeTop | UIRectEdgeLeft |
                    UIRectEdgeBottom | UIRectEdgeRight
} UIRectEdge;

@interface UIScreenEdgePanGestureRecognizer : UIPanGestureRecognizer
@property UIRectEdge edges;
@end

@interface UILongPressGestureRecognizer : UIGestureRecognizer
@property double minimumPressDuration;
@property double allowableMovement;
@end

@interface UIPinchGestureRecognizer : UIGestureRecognizer
@property double scale;
@property(readonly) double velocity;
@end

@interface UIRotationGestureRecognizer : UIGestureRecognizer
@property double rotation;
@property(readonly) double velocity;
@end

#define CGRectZero CGRectMake(0, 0, 0, 0)

#endif
