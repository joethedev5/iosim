#ifndef IOSIM_UIKIT_STUB_H
#define IOSIM_UIKIT_STUB_H

#include "../frameworks/objc_lite.h"
#include "../frameworks/coregraphics_lite.h"

double CACurrentMediaTime(void);

typedef struct {
    unsigned long location;
    unsigned long length;
} NSRange;

#define NSNotFound ((unsigned long)-1)

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

@class NSCharacterSet;

@interface NSString : NSObject
+ (id)stringWithFormat:(id)format, ...;
+ (id)stringWithUTF8String:(const char *)string;
- (const char *)UTF8String;
- (unsigned long)length;
- (id)initWithData:(id)data encoding:(unsigned long)encoding;
- (id)stringByTrimmingCharactersInSet:(id)set;
- (id)stringByReplacingCharactersInRange:(NSRange)range withString:(id)string;
- (NSRange)rangeOfString:(id)string;
- (id)capitalizedString;
- (id)stringByRemovingPercentEncoding;
- (id)stringByAppendingPathExtension:(id)extension;
- (id)stringByAddingPercentEncodingWithAllowedCharacters:
    (NSCharacterSet *)allowedCharacters;
- (id)stringByAddingPercentEscapesUsingEncoding:(unsigned long)encoding;
- (id)stringByReplacingPercentEscapesUsingEncoding:(unsigned long)encoding;
- (long)integerValue;
- (double)doubleValue;
- (BOOL)boolValue;
@end

@interface NSCharacterSet : NSObject
+ (id)whitespaceCharacterSet;
+ (id)whitespaceAndNewlineCharacterSet;
+ (id)newlineCharacterSet;
+ (id)alphanumericCharacterSet;
+ (id)decimalDigitCharacterSet;
+ (id)letterCharacterSet;
+ (id)characterSetWithCharactersInString:(id)string;
+ (id)URLQueryAllowedCharacterSet;
+ (id)URLPathAllowedCharacterSet;
+ (id)URLHostAllowedCharacterSet;
+ (id)URLFragmentAllowedCharacterSet;
+ (id)URLUserAllowedCharacterSet;
+ (id)URLPasswordAllowedCharacterSet;
- (BOOL)characterIsMember:(unsigned short)character;
- (id)mutableCopy;
@end

@interface NSMutableCharacterSet : NSCharacterSet
- (void)addCharactersInString:(id)string;
- (void)removeCharactersInString:(id)string;
@end

@interface NSAttributedString : NSObject
- (id)initWithString:(id)string;
- (id)initWithString:(id)string attributes:(id)attributes;
- (id)string;
- (unsigned long)length;
- (id)attributesAtIndex:(unsigned long)index effectiveRange:(NSRange *)range;
@end

@interface NSMutableAttributedString : NSAttributedString
- (id)initWithString:(id)string;
- (void)addAttribute:(id)name value:(id)value range:(NSRange)range;
- (void)addAttributes:(id)attributes range:(NSRange)range;
- (void)setAttributes:(id)attributes range:(NSRange)range;
- (void)replaceCharactersInRange:(NSRange)range withString:(id)string;
- (void)appendAttributedString:(id)other;
@end

@interface NSData : NSObject
+ (NSData *)dataWithBytes:(const void *)bytes length:(unsigned long)length;
+ (NSData *)dataWithContentsOfFile:(NSString *)path;
- (const void *)bytes;
- (unsigned long)length;
- (BOOL)writeToFile:(NSString *)path atomically:(BOOL)atomically;
- (id)base64EncodedStringWithOptions:(unsigned long)options;
- (id)initWithBase64EncodedString:(id)string options:(unsigned long)options;
@end

#define NSPropertyListXMLFormat_v1_0 100UL
#define NSPropertyListBinaryFormat_v1_0 200UL

@interface NSPropertyListSerialization : NSObject
+ (id)dataWithPropertyList:(id)plist format:(unsigned long)format
                   options:(unsigned long)options error:(id *)error;
+ (id)propertyListWithData:(id)data options:(unsigned long)options
                    format:(unsigned long *)format error:(id *)error;
@end

@class NSArray;
@class NSDictionary;

@interface NSUUID : NSObject
+ (id)UUID;
- (id)initWithUUIDString:(id)string;
- (id)UUIDString;
@end

@interface NSProgress : NSObject
+ (NSProgress *)progressWithTotalUnitCount:(long long)total;
+ (NSProgress *)discreteProgressWithTotalUnitCount:(long long)total;
+ (NSProgress *)progressWithTotalUnitCount:(long long)total
                                    parent:(NSProgress *)parent
                          pendingUnitCount:(long long)pending;
@property long long totalUnitCount;
@property long long completedUnitCount;
@property(readonly) double fractionCompleted;
@property(readonly, getter=isCancelled) BOOL cancelled;
@property(readonly, getter=isPaused) BOOL paused;
@property(copy) id kind;
@property(copy) id localizedDescription;
@property(copy) void (^cancellationHandler)(void);
@property(copy) void (^pausingHandler)(void);
@property(copy) void (^resumingHandler)(void);
- (void)becomeCurrentWithPendingUnitCount:(long long)unitCount;
- (void)resignCurrent;
- (void)addChild:(NSProgress *)child withPendingUnitCount:(long long)unitCount;
- (void)cancel;
- (void)pause;
- (void)resume;
- (void)publish;
- (void)unpublish;
@end

@interface NSOperation : NSObject
- (void)start;
- (void)main;
- (void)cancel;
- (BOOL)isCancelled;
- (BOOL)isFinished;
- (BOOL)isReady;
- (void)addDependency:(NSOperation *)operation;
- (void)removeDependency:(NSOperation *)operation;
- (NSArray *)dependencies;
- (id)name;
- (void)setName:(id)name;
- (void)setCompletionBlock:(void (^)(void))block;
@end

@interface NSBlockOperation : NSOperation
+ (id)blockOperationWithBlock:(void (^)(void))block;
- (void)addExecutionBlock:(void (^)(void))block;
@end

@interface NSOperationQueue : NSObject
+ (NSOperationQueue *)mainQueue;
- (void)addOperation:(NSOperation *)operation;
- (void)addOperationWithBlock:(void (^)(void))block;
- (void)waitUntilAllOperationsAreFinished;
- (long)operationCount;
- (void)setMaxConcurrentOperationCount:(long)count;
- (long)maxConcurrentOperationCount;
- (void)setSuspended:(BOOL)suspended;
- (BOOL)isSuspended;
- (void)cancelAllOperations;
@end

@interface NSProcessInfo : NSObject
+ (NSProcessInfo *)processInfo;
- (NSDictionary *)environment;
- (NSArray *)arguments;
- (id)processName;
- (id)globallyUniqueString;
- (id)operatingSystemVersionString;
- (unsigned long long)physicalMemory;
- (unsigned long)processorCount;
- (unsigned long)activeProcessorCount;
- (double)systemUptime;
- (id)hostName;
- (BOOL)isLowPowerModeEnabled;
@end

@interface NSURL : NSObject
+ (id)fileURLWithPath:(id)path;
+ (id)URLWithString:(id)string;
- (id)path;
- (id)absolutePath;
- (id)scheme;
- (id)host;
- (id)query;
- (int)port;
- (id)absoluteString;
- (BOOL)isFileURL;
- (id)URLByAppendingPathComponent:(id)component;
- (id)URLByAppendingPathComponent:(id)component isDirectory:(BOOL)isDirectory;
- (id)URLByDeletingLastPathComponent;
- (id)URLByAppendingPathExtension:(id)extension;
- (id)URLByDeletingPathExtension;
- (id)URLByStandardizingPath;
- (id)URLByResolvingSymlinksInPath;
- (NSArray *)pathComponents;
@end

@class NSArray;

@interface NSURLQueryItem : NSObject
+ (id)queryItemWithName:(id)name value:(id)value;
- (id)initWithName:(id)name value:(id)value;
@property(readonly) id name;
@property(readonly) id value;
@end

@interface NSURLComponents : NSObject
+ (id)componentsWithString:(id)string;
+ (id)componentsWithURL:(id)url resolvingAgainstBaseURL:(BOOL)resolve;
- (id)string;
@property(readonly) NSURL *URL;
@property(nonatomic, retain) id scheme;
@property(nonatomic, retain) id host;
@property(nonatomic, retain) id path;
@property(nonatomic, retain) id query;
@property(nonatomic, retain) NSArray *queryItems;
@property(nonatomic, retain) id percentEncodedQuery;
@property(nonatomic, retain) id percentEncodedPath;
@property(nonatomic, retain) id fragment;
@property int port;
@end

@interface NSIndexSet : NSObject
+ (id)indexSet;
+ (id)indexSetWithIndex:(unsigned long)index;
+ (id)indexSetWithIndexesInRange:(NSRange)range;
- (unsigned long)count;
- (unsigned long)firstIndex;
- (unsigned long)lastIndex;
- (BOOL)containsIndex:(unsigned long)index;
- (unsigned long)indexGreaterThanIndex:(unsigned long)index;
- (unsigned long)indexLessThanIndex:(unsigned long)index;
- (unsigned long)indexGreaterThanOrEqualToIndex:(unsigned long)index;
- (void)enumerateIndexesUsingBlock:(void (^)(unsigned long index, BOOL *stop))block;
- (void)enumerateRangesUsingBlock:(void (^)(NSRange range, BOOL *stop))block;
@end

@interface NSMutableIndexSet : NSIndexSet
- (void)addIndex:(unsigned long)index;
- (void)addIndexesInRange:(NSRange)range;
- (void)removeIndex:(unsigned long)index;
- (void)removeAllIndexes;
@end

@interface NSValue : NSObject
+ (id)valueWithBytes:(const void *)value objCType:(const char *)type;
+ (id)value:(const void *)value withObjCType:(const char *)type;
+ (id)valueWithCGPoint:(CGPoint)point;
+ (id)valueWithCGSize:(CGSize)size;
+ (id)valueWithCGRect:(CGRect)rect;
+ (id)valueWithCGAffineTransform:(CGAffineTransform)transform;
+ (id)valueWithCATransform3D:(CATransform3D)transform;
+ (id)valueWithUIEdgeInsets:(UIEdgeInsets)insets;
+ (id)valueWithRange:(NSRange)range;
+ (id)valueWithNonretainedObject:(id)object;
+ (id)valueWithPointer:(const void *)pointer;
- (void)getValue:(void *)value size:(unsigned long)size;
- (const char *)objCType;
- (CGPoint)CGPointValue;
- (CGSize)CGSizeValue;
- (CGRect)CGRectValue;
- (CGAffineTransform)CGAffineTransformValue;
- (CATransform3D)CATransform3DValue;
- (UIEdgeInsets)UIEdgeInsetsValue;
- (NSRange)rangeValue;
- (id)nonretainedObjectValue;
- (void *)pointerValue;
- (BOOL)isEqualToValue:(id)other;
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
+ (id)numberWithInt:(int)value;
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
+ (id)setWithObject:(id)object;
- (unsigned long)count;
- (id)anyObject;
- (id)allObjects;
- (BOOL)containsObject:(id)object;
- (unsigned long)countByEnumeratingWithState:(NSFastEnumerationState *)state
                                     objects:(id *)buffer
                                       count:(unsigned long)len;
@end

@interface NSMutableSet : NSSet
+ (id)set;
- (void)addObject:(id)object;
- (void)removeObject:(id)object;
- (void)removeAllObjects;
@end

@interface NSCountedSet : NSMutableSet
+ (id)countedSetWithArray:(id)array;
- (unsigned long)countForObject:(id)object;
@end

@interface NSOrderedSet : NSObject <NSFastEnumeration>
+ (id)orderedSet;
+ (id)orderedSetWithObject:(id)object;
+ (id)orderedSetWithObjects:(const id *)objects count:(unsigned long)count;
+ (id)orderedSetWithObjects:(id)first, ...;
+ (id)orderedSetWithArray:(id)array;
+ (id)orderedSetWithSet:(id)set;
- (unsigned long)count;
- (id)objectAtIndex:(unsigned long)index;
- (id)firstObject;
- (id)lastObject;
- (unsigned long)indexOfObject:(id)object;
- (BOOL)containsObject:(id)object;
- (id)array;
- (id)set;
- (unsigned long)countByEnumeratingWithState:(NSFastEnumerationState *)state
                                     objects:(id *)buffer
                                       count:(unsigned long)len;
@end

@interface NSMutableOrderedSet : NSOrderedSet
+ (id)orderedSet;
- (void)addObject:(id)object;
- (void)insertObject:(id)object atIndex:(unsigned long)index;
- (void)removeObject:(id)object;
- (void)removeObjectAtIndex:(unsigned long)index;
- (void)replaceObjectAtIndex:(unsigned long)index withObject:(id)object;
- (void)setObject:(id)object atIndexedSubscript:(unsigned long)index;
- (void)removeAllObjects;
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
@class CAAnimation;

@interface CALayer : NSObject
@property CGRect frame;
@property CGRect bounds;
@property CGPoint position;
@property CGPoint anchorPoint;
@property(nonatomic, retain) id contents;
@property double cornerRadius;
@property BOOL masksToBounds;
@property double opacity;
@property(nonatomic, retain) id backgroundColor;
@property(nonatomic, retain) CALayer *mask;
@property CATransform3D transform;
@property CGRect contentsRect;
@property(nonatomic, retain) id contentsGravity;
@property double contentsScale;
@property(nonatomic, retain) id shadowPath;
@property BOOL shouldRasterize;
@property double rasterizationScale;
@property(nonatomic, retain) id cornerCurve;
@property unsigned long maskedCorners;
@property double speed;
@property double timeOffset;
@property double beginTime;
@property(nonatomic, retain) id name;
- (void)addSublayer:(CALayer *)layer;
- (void)addAnimation:(id)animation forKey:(id)key;
- (void)removeAnimationForKey:(id)key;
- (void)removeAllAnimations;
- (id)animationKeys;
- (CAAnimation *)animationForKey:(id)key;
- (CALayer *)presentationLayer;
@end

@interface CAReplicatorLayer : CALayer
@property long instanceCount;
@property double instanceDelay;
@property CATransform3D instanceTransform;
@property(nonatomic, retain) id instanceColor;
@property float instanceRedOffset;
@property float instanceGreenOffset;
@property float instanceBlueOffset;
@property float instanceAlphaOffset;
@property BOOL preservesDepth;
@end

@class NSArray;

@interface CAEmitterCell : NSObject
@property(nonatomic, retain) id contents;
@property(nonatomic, retain) id color;
@property float birthRate;
@property float lifetime;
@property float velocity;
@property float velocityRange;
@property float emissionRange;
@property float scale;
@property float scaleRange;
@property float spin;
@property float spinRange;
@property float alphaSpeed;
@property float alphaRange;
@property float redSpeed;
@property float greenSpeed;
@property float blueSpeed;
@property float redRange;
@property float greenRange;
@property float blueRange;
@property float xAcceleration;
@property float yAcceleration;
@property(getter=isEnabled) BOOL enabled;
@property(nonatomic, retain) id name;
@end

@interface CAEmitterLayer : CALayer
@property(nonatomic, retain) NSArray *emitterCells;
@property float birthRate;
@property float lifetime;
@property CGPoint emitterPosition;
@property CGSize emitterSize;
@property(nonatomic, retain) id emitterShape;
@property(nonatomic, retain) id renderMode;
@property unsigned seed;
@property float scale;
@property float velocity;
@property float spin;
@end

@class NSArray;

@class CAAnimation;
@protocol CAAnimationDelegate
@optional
- (void)animationDidStart:(CAAnimation *)anim;
- (void)animationDidStop:(CAAnimation *)anim finished:(BOOL)finished;
@end

@interface CAAnimation : NSObject
+ (id)animationWithKeyPath:(id)path;
- (void)setFromValue:(id)value;
- (void)setToValue:(id)value;
- (void)setDuration:(double)duration;
- (double)duration;
- (void)setRepeatCount:(double)count;
- (double)repeatCount;
- (void)setTimingFunction:(id)function;
- (id)timingFunction;
- (id)fromValue;
- (id)toValue;
- (void)setBeginTime:(double)time;
- (double)beginTime;
- (void)setSpeed:(double)speed;
- (double)speed;
- (void)setTimeOffset:(double)offset;
- (double)timeOffset;
- (void)setAutoreverses:(BOOL)autoreverses;
- (BOOL)autoreverses;
- (void)setRemovedOnCompletion:(BOOL)removed;
- (BOOL)removedOnCompletion;
- (void)setFillMode:(id)fillMode;
- (id)fillMode;
@property(nonatomic, assign) id<CAAnimationDelegate> delegate;
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

@interface CATransaction : NSObject
+ (void)begin;
+ (void)commit;
+ (void)flush;
+ (void)setAnimationDuration:(double)duration;
+ (double)animationDuration;
+ (void)setDisableActions:(BOOL)disable;
+ (BOOL)disableActions;
+ (void)setCompletionBlock:(void (^)(void))block;
+ (void (^)(void))completionBlock;
+ (void)lock;
+ (void)unlock;
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

enum {
    UIUserInterfaceStyleUnspecified = 0,
    UIUserInterfaceStyleLight = 1,
    UIUserInterfaceStyleDark = 2
};

enum {
    UIUserInterfaceSizeClassUnspecified = 0,
    UIUserInterfaceSizeClassCompact = 1,
    UIUserInterfaceSizeClassRegular = 2
};

@interface UITraitCollection : NSObject
@property(readonly) long userInterfaceStyle;
@property(readonly) double displayScale;
@property(readonly) long horizontalSizeClass;
@property(readonly) long verticalSizeClass;
@end

@interface UIColor : NSObject
+ (UIColor *)colorWithRed:(double)r green:(double)g blue:(double)b
                    alpha:(double)a;
+ (UIColor *)colorWithWhite:(double)white alpha:(double)alpha;
+ (UIColor *)colorWithHue:(double)hue saturation:(double)saturation
               brightness:(double)brightness alpha:(double)alpha;
+ (UIColor *)colorWithDisplayP3Red:(double)r green:(double)g blue:(double)b
                             alpha:(double)a;
- (UIColor *)colorWithAlphaComponent:(double)alpha;
- (BOOL)getRed:(double *)red green:(double *)green blue:(double *)blue
         alpha:(double *)alpha;
- (BOOL)getWhite:(double *)white alpha:(double *)alpha;
- (BOOL)getHue:(double *)hue saturation:(double *)saturation
    brightness:(double *)brightness alpha:(double *)alpha;
+ (UIColor *)whiteColor;
+ (UIColor *)blackColor;
+ (UIColor *)clearColor;
+ (UIColor *)redColor;
+ (UIColor *)greenColor;
+ (UIColor *)blueColor;
+ (UIColor *)orangeColor;
+ (UIColor *)yellowColor;
+ (UIColor *)purpleColor;
+ (UIColor *)brownColor;
+ (UIColor *)cyanColor;
+ (UIColor *)magentaColor;
+ (UIColor *)grayColor;
+ (UIColor *)darkGrayColor;
+ (UIColor *)lightGrayColor;
+ (UIColor *)systemBlueColor;
+ (UIColor *)tintColor;
+ (UIColor *)systemRedColor;
+ (UIColor *)systemGreenColor;
+ (UIColor *)systemOrangeColor;
+ (UIColor *)systemYellowColor;
+ (UIColor *)systemPurpleColor;
+ (UIColor *)systemPinkColor;
+ (UIColor *)systemTealColor;
+ (UIColor *)systemIndigoColor;
+ (UIColor *)systemGrayColor;
+ (UIColor *)systemBackgroundColor;
+ (UIColor *)secondarySystemBackgroundColor;
+ (UIColor *)systemGroupedBackgroundColor;
+ (UIColor *)labelColor;
+ (UIColor *)secondaryLabelColor;
+ (UIColor *)tertiaryLabelColor;
+ (UIColor *)separatorColor;
+ (UIColor *)opaqueSeparatorColor;
+ (UIColor *)linkColor;
- (UIColor *)resolvedColorWithTraitCollection:(UITraitCollection *)traits;
@property(readonly) id CGColor;
@end

#define UIFontWeightUltraLight (-0.8)
#define UIFontWeightThin (-0.6)
#define UIFontWeightLight (-0.4)
#define UIFontWeightRegular (0.0)
#define UIFontWeightMedium (0.23)
#define UIFontWeightSemibold (0.3)
#define UIFontWeightBold (0.4)
#define UIFontWeightHeavy (0.56)
#define UIFontWeightBlack (0.62)

#define UIFontTextStyleBody ((id)@"UICTFontTextStyleBody")
#define UIFontTextStyleHeadline ((id)@"UICTFontTextStyleHeadline")
#define UIFontTextStyleCaption1 ((id)@"UICTFontTextStyleCaption1")
#define UIFontTextStyleFootnote ((id)@"UICTFontTextStyleFootnote")
#define UIFontTextStyleTitle1 ((id)@"UICTFontTextStyleTitle1")
#define UIFontTextStyleTitle2 ((id)@"UICTFontTextStyleTitle2")

@class UIFontDescriptor;

@interface UIFont : NSObject
+ (UIFont *)systemFontOfSize:(double)size;
+ (UIFont *)systemFontOfSize:(double)size weight:(double)weight;
+ (UIFont *)boldSystemFontOfSize:(double)size;
+ (UIFont *)italicSystemFontOfSize:(double)size;
+ (UIFont *)monospacedSystemFontOfSize:(double)size weight:(double)weight;
+ (UIFont *)fontWithName:(id)name size:(double)size;
- (double)pointSize;
- (id)fontName;
- (id)familyName;
- (UIFont *)fontWithSize:(double)size;
+ (UIFont *)fontWithDescriptor:(UIFontDescriptor *)descriptor
                          size:(double)size;
+ (UIFont *)preferredFontForTextStyle:(id)style;
+ (UIFont *)preferredFontForTextStyle:(id)style
              compatibleWithTraitCollection:(UITraitCollection *)traits;
- (UIFontDescriptor *)fontDescriptor;
@end

@interface UIFontDescriptor : NSObject
+ (UIFontDescriptor *)preferredFontDescriptorWithTextStyle:(id)style;
- (UIFontDescriptor *)fontDescriptorWithSize:(double)size;
- (UIFontDescriptor *)fontDescriptorWithSymbolicTraits:(unsigned long)traits;
- (double)pointSize;
- (id)fontAttributes;
@end

@interface UIScreen : NSObject
+ (UIScreen *)mainScreen;
- (CGRect)bounds;
- (CGRect)nativeBounds;
- (double)scale;
- (double)nativeScale;
@property double brightness;
@property(readonly) BOOL captured;
@end

extern NSString *UIDeviceOrientationDidChangeNotification;

@interface UIDevice : NSObject
+ (UIDevice *)currentDevice;
@property(readonly) NSString *name;
@property(readonly) NSString *model;
@property(readonly) NSString *localizedModel;
@property(readonly) NSString *systemName;
@property(readonly) NSString *systemVersion;
@property(readonly) NSUUID *identifierForVendor;
@property(readonly) long userInterfaceIdiom;
@property long orientation;
@property(readonly) long batteryState;
@property(readonly) double batteryLevel;
@property BOOL proximityMonitoringEnabled;
@property(readonly) BOOL multitaskingSupported;
@property(readonly) BOOL generatingDeviceOrientationNotifications;
- (void)beginGeneratingDeviceOrientationNotifications;
- (void)endGeneratingDeviceOrientationNotifications;
- (void)playInputClick;
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
@property(nonatomic, retain) id identifier;
@property(readonly) NSLayoutAnchor *leadingAnchor;
@property(readonly) NSLayoutAnchor *trailingAnchor;
@property(readonly) NSLayoutAnchor *topAnchor;
@property(readonly) NSLayoutAnchor *bottomAnchor;
@property(readonly) NSLayoutAnchor *centerXAnchor;
@property(readonly) NSLayoutAnchor *centerYAnchor;
@property(readonly) double layoutFrameX;
@property(readonly) double layoutFrameY;
@property(readonly) double layoutFrameWidth;
@property(readonly) double layoutFrameHeight;
@end

enum {
    UIViewTintAdjustmentModeNormal = 0,
    UIViewTintAdjustmentModeDimmed = 1,
    UIViewTintAdjustmentModeAutomatic = 2
};

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

enum {
    UIViewContentModeScaleToFill = 0,
    UIViewContentModeScaleAspectFit = 1,
    UIViewContentModeScaleAspectFill = 2,
    UIViewContentModeRedraw = 3,
    UIViewContentModeCenter = 4,
    UIViewContentModeTop = 5,
    UIViewContentModeBottom = 6,
    UIViewContentModeLeft = 7,
    UIViewContentModeRight = 8,
    UIViewContentModeTopLeft = 9,
    UIViewContentModeTopRight = 10,
    UIViewContentModeBottomLeft = 11,
    UIViewContentModeBottomRight = 12
};

enum {
    UIViewAutoresizingNone = 0,
    UIViewAutoresizingFlexibleLeftMargin = 1 << 0,
    UIViewAutoresizingFlexibleWidth = 1 << 1,
    UIViewAutoresizingFlexibleRightMargin = 1 << 2,
    UIViewAutoresizingFlexibleTopMargin = 1 << 3,
    UIViewAutoresizingFlexibleHeight = 1 << 4,
    UIViewAutoresizingFlexibleBottomMargin = 1 << 5
};

@interface UIView : UIResponder
- (id)initWithFrame:(CGRect)frame;
- (CGRect)bounds;
- (void)setBounds:(CGRect)bounds;
@property CGRect frame;
@property CGPoint center;
@property(readonly) UIView *superview;
@property(readonly) UIWindow *window;
@property(readonly) NSArray *subviews;
@property long semanticContentAttribute;
+ (long)userInterfaceLayoutDirectionForSemanticContentAttribute:(long)attribute;
@property(readonly) long effectiveUserInterfaceLayoutDirection;
- (void)setNeedsDisplay;
- (void)setNeedsDisplayInRect:(CGRect)rect;
- (void)didAddSubview:(UIView *)subview;
- (void)willRemoveSubview:(UIView *)subview;
- (void)willMoveToSuperview:(UIView *)newSuperview;
- (void)didMoveToSuperview;
- (void)willMoveToWindow:(id)window;
- (void)didMoveToWindow;
- (CGPoint)convertPoint:(CGPoint)point toView:(UIView *)view;
- (CGPoint)convertPoint:(CGPoint)point fromView:(UIView *)view;
- (CGRect)convertRect:(CGRect)rect toView:(UIView *)view;
- (CGRect)convertRect:(CGRect)rect fromView:(UIView *)view;
@property double alpha;
@property CGAffineTransform transform;
@property(nonatomic, retain) UIColor *backgroundColor;
@property BOOL clipsToBounds;
@property(nonatomic, getter=isUserInteractionEnabled) BOOL userInteractionEnabled;
@property(nonatomic, getter=isOpaque) BOOL opaque;
@property long contentMode;
@property BOOL clearsContextBeforeDrawing;
@property(nonatomic, getter=isExclusiveTouch) BOOL exclusiveTouch;
@property(nonatomic, getter=isMultipleTouchEnabled) BOOL multipleTouchEnabled;
@property BOOL autoresizesSubviews;
@property unsigned long autoresizingMask;
@property double contentScaleFactor;
@property(nonatomic, retain) UIView *maskView;
@property(readonly) UITraitCollection *traitCollection;
@property(nonatomic) long overrideUserInterfaceStyle;
- (void)traitCollectionDidChange:(UITraitCollection *)previous;
+ (Class)layerClass;
@property(readonly) CALayer *layer;
- (void)drawRect:(CGRect)rect;
- (void)addSubview:(UIView *)view;
- (void)addGestureRecognizer:(id)recognizer;
- (void)addInteraction:(id)interaction;
- (void)removeInteraction:(id)interaction;
- (NSArray *)interactions;
@property(nonatomic, getter=isAccessibilityElement) BOOL accessibilityElement;
@property(nonatomic, retain) id accessibilityLabel;
@property(nonatomic, retain) id accessibilityIdentifier;
@property(nonatomic, retain) id accessibilityHint;
@property(nonatomic, retain) id accessibilityValue;
@property unsigned long long accessibilityTraits;
@property BOOL accessibilityElementsHidden;
@property BOOL accessibilityViewIsModal;
@property BOOL shouldGroupAccessibilityChildren;
@property(nonatomic, retain) NSArray *accessibilityElements;
@property CGRect accessibilityFrame;
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
@property UIEdgeInsets layoutMargins;
@property(readonly) UILayoutGuide *layoutMarginsGuide;
@property(readonly) UILayoutGuide *readableContentGuide;
@property BOOL preservesSuperviewLayoutMargins;
+ (void)animateWithDuration:(double)duration animations:(void (^)(void))animations;
+ (void)animateWithDuration:(double)duration animations:(void (^)(void))animations
                 completion:(void (^)(BOOL finished))completion;
+ (void)animateWithDuration:(double)duration delay:(double)delay
                    options:(unsigned long)options
                 animations:(void (^)(void))animations
                 completion:(void (^)(BOOL finished))completion;
+ (BOOL)areAnimationsEnabled;
+ (void)setAnimationsEnabled:(BOOL)enabled;
+ (void)performWithoutAnimation:(void (^)(void))actionsWithoutAnimation;
+ (void)animateKeyframesWithDuration:(double)duration delay:(double)delay
                             options:(unsigned long)options
                          animations:(void (^)(void))animations
                          completion:(void (^)(BOOL finished))completion;
+ (void)addKeyframeWithRelativeStartTime:(double)start
                        relativeDuration:(double)duration
                              animations:(void (^)(void))animations;
+ (void)transitionWithView:(UIView *)view duration:(double)duration
                   options:(unsigned long)options
                animations:(void (^)(void))animations
                completion:(void (^)(BOOL finished))completion;
+ (void)transitionFromView:(UIView *)fromView toView:(UIView *)toView
                  duration:(double)duration
                   options:(unsigned long)options
                completion:(void (^)(BOOL finished))completion;
@property(nonatomic, retain) UIColor *tintColor;
- (void)tintColorDidChange;
@property long tintAdjustmentMode;
@property(readonly) UIEdgeInsets safeAreaInsets;
- (void)safeAreaInsetsDidChange;
@end

enum {
    UIViewAnimatingStateInactive = 0,
    UIViewAnimatingStateActive = 1,
    UIViewAnimatingStateStopped = 2
};

enum {
    UIViewAnimatingPositionEnd = 0,
    UIViewAnimatingPositionStart = 1,
    UIViewAnimatingPositionCurrent = 2
};

enum {
    UIViewAnimationCurveEaseInOut = 0,
    UIViewAnimationCurveEaseIn = 1,
    UIViewAnimationCurveEaseOut = 2,
    UIViewAnimationCurveLinear = 3
};

@interface UIViewPropertyAnimator : NSObject
- (id)initWithDuration:(double)duration
                 curve:(long)curve
            animations:(void (^)(void))animations;
- (id)initWithDuration:(double)duration
          dampingRatio:(double)ratio
            animations:(void (^)(void))animations;
- (id)initWithDuration:(double)duration
         controlPoint1:(CGPoint)point1
         controlPoint2:(CGPoint)point2
            animations:(void (^)(void))animations;
@property(readonly) double duration;
@property double fractionComplete;
@property(getter=isReversed) BOOL reversed;
@property(readonly) long state;
@property(readonly, getter=isRunning) BOOL running;
@property(getter=isInterruptible) BOOL interruptible;
@property(getter=isUserInteractionEnabled) BOOL userInteractionEnabled;
@property BOOL scrubsLinearly;
@property BOOL pausesOnCompletion;
- (void)addAnimations:(void (^)(void))animations;
- (void)addAnimations:(void (^)(void))animations delayFactor:(double)factor;
- (void)addCompletion:(void (^)(long position))completion;
- (void)startAnimation;
- (void)startAnimationAfterDelay:(double)delay;
- (void)pauseAnimation;
- (void)stopAnimation:(BOOL)withoutFinishing;
- (void)finishAnimationAtPosition:(long)position;
- (void)continueAnimationWithTimingParameters:(id)parameters
                                durationFactor:(double)factor;
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
@property int borderStyle;
@property BOOL clearsOnBeginEditing;
@property(nonatomic, retain) id leftView;
@property(nonatomic, retain) id rightView;
@property long leftViewMode;
@property long rightViewMode;
@property long clearButtonMode;
@property(nonatomic, assign) id delegate;
- (BOOL)becomeFirstResponder;
- (BOOL)resignFirstResponder;
- (void)insertText:(id)text;
- (void)deleteBackward;
- (void)handleReturnKey;
@end

@interface UITextView : UIView
@property(nonatomic, retain) id text;
@property(nonatomic, retain) NSAttributedString *attributedText;
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
@property(nonatomic, retain) NSArray *scopeButtonTitles;
@property long selectedScopeButtonIndex;
@property BOOL showsScopeBar;
@property(nonatomic, retain) UIColor *barTintColor;
@property long searchBarStyle;
@property(nonatomic, retain) UIImage *backgroundImage;
@end

@interface UIAccessibilityElement : NSObject
- (id)initWithAccessibilityContainer:(id)container;
@property(readonly) id accessibilityContainer;
@property(nonatomic, getter=isAccessibilityElement) BOOL accessibilityElement;
@property(nonatomic, retain) id accessibilityLabel;
@property(nonatomic, retain) id accessibilityIdentifier;
@property(nonatomic, retain) id accessibilityHint;
@property(nonatomic, retain) id accessibilityValue;
@property unsigned long long accessibilityTraits;
@property CGRect accessibilityFrame;
@end

@interface UILabel : UIView
@property(nonatomic, retain) id text;
@property(nonatomic, retain) NSAttributedString *attributedText;
@property(nonatomic, retain) UIColor *textColor;
@property(nonatomic, retain) UIFont *font;
@property int textAlignment;
@property int numberOfLines;
@property long lineBreakMode;
@property double preferredMaxLayoutWidth;
@property BOOL adjustsFontSizeToFitWidth;
@property double minimumScaleFactor;
@end

@class UINavigationItem;

enum {
    UIModalPresentationFullScreen = 0,
    UIModalPresentationPageSheet = 1,
    UIModalPresentationFormSheet = 2,
    UIModalPresentationCurrentContext = 3,
    UIModalPresentationCustom = 4,
    UIModalPresentationOverFullScreen = 5,
    UIModalPresentationOverCurrentContext = 6,
    UIModalPresentationPopover = 7,
    UIModalPresentationBlurOverFullScreen = 8,
    UIModalPresentationNone = -1,
    UIModalPresentationAutomatic = -2
};

@class UIViewController;

@interface UIPresentationController : NSObject
@property(readonly) UIViewController *presentedViewController;
@property(readonly) UIViewController *presentingViewController;
@property(readonly) UIView *containerView;
@property(readonly) UIView *presentedView;
@property(readonly) CGRect frameOfPresentedViewInContainerView;
@property(readonly) long presentationStyle;
- (void)presentationTransitionWillBegin;
- (void)presentationTransitionDidEnd:(BOOL)completed;
- (void)dismissalTransitionWillBegin;
- (void)dismissalTransitionDidEnd:(BOOL)completed;
- (void)containerViewWillLayoutSubviews;
- (void)containerViewDidLayoutSubviews;
@property(readonly) BOOL shouldRemovePresentersView;
@property(readonly) BOOL shouldPresentInFullscreen;
@end

extern NSString *const UITransitionContextFromViewControllerKey;
extern NSString *const UITransitionContextToViewControllerKey;
extern NSString *const UITransitionContextFromViewKey;
extern NSString *const UITransitionContextToViewKey;

@protocol UIViewControllerContextTransitioning
- (UIView *)containerView;
- (UIViewController *)viewControllerForKey:(NSString *)key;
- (UIView *)viewForKey:(NSString *)key;
- (CGRect)initialFrameForViewController:(UIViewController *)controller;
- (CGRect)finalFrameForViewController:(UIViewController *)controller;
- (BOOL)isAnimated;
- (BOOL)isInteractive;
- (long)presentationStyle;
- (BOOL)transitionWasCancelled;
- (void)completeTransition:(BOOL)didComplete;
- (void)updateInteractiveTransition:(double)percentComplete;
- (void)finishInteractiveTransition;
- (void)cancelInteractiveTransition;
- (void)pauseInteractiveTransition;
@end

@protocol UIViewControllerAnimatedTransitioning
- (double)transitionDuration:
    (id<UIViewControllerContextTransitioning>)context;
- (void)animateTransition:
    (id<UIViewControllerContextTransitioning>)context;
@optional
- (void)animationEnded:(BOOL)transitionCompleted;
@end

@protocol UIViewControllerInteractiveTransitioning
- (void)startInteractiveTransition:
    (id<UIViewControllerContextTransitioning>)context;
@optional
- (double)completionSpeed;
- (long)completionCurve;
@end

@protocol UIViewControllerTransitioningDelegate
@optional
- (id<UIViewControllerAnimatedTransitioning>)
    animationControllerForPresentedController:(UIViewController *)presented
                         presentingController:(UIViewController *)presenting
                             sourceController:(UIViewController *)source;
- (id<UIViewControllerAnimatedTransitioning>)
    animationControllerForDismissedController:(UIViewController *)dismissed;
- (id<UIViewControllerInteractiveTransitioning>)
    interactionControllerForPresentation:
        (id<UIViewControllerAnimatedTransitioning>)animator;
- (id<UIViewControllerInteractiveTransitioning>)
    interactionControllerForDismissal:
        (id<UIViewControllerAnimatedTransitioning>)animator;
- (UIPresentationController *)
    presentationControllerForPresentedViewController:(UIViewController *)presented
                            presentingViewController:(UIViewController *)presenting
                                sourceViewController:(UIViewController *)source;
@end

@interface UIPercentDrivenInteractiveTransition : NSObject
    <UIViewControllerInteractiveTransitioning>
@property(nonatomic) double percentComplete;
@property(nonatomic) double completionSpeed;
@property(nonatomic) long completionCurve;
- (void)updateInteractiveTransition:(double)percentComplete;
- (void)cancelInteractiveTransition;
- (void)finishInteractiveTransition;
- (void)pauseInteractiveTransition;
@end

@interface UIPopoverPresentationController : UIPresentationController
@property(nonatomic, retain) UIView *sourceView;
@property(nonatomic) CGRect sourceRect;
@property(nonatomic, retain) id barButtonItem;
@property(nonatomic) long permittedArrowDirections;
@property(nonatomic, assign) id delegate;
@property(nonatomic) UIEdgeInsets popoverLayoutMargins;
@end

@interface UISheetPresentationControllerDetent : NSObject
+ (id)mediumDetent;
+ (id)largeDetent;
+ (id)customDetentWithIdentifier:(id)identifier
                        resolver:(double (^)(id))resolver;
@property(readonly) id identifier;
@end

@interface UISheetPresentationController : UIPresentationController
@property(nonatomic, retain) NSArray *detents;
@property(nonatomic) BOOL prefersGrabberVisible;
@property(nonatomic) double preferredCornerRadius;
@property(nonatomic, retain) id largestUndimmedDetentIdentifier;
@property(nonatomic) BOOL prefersScrollingExpandsWhenScrolledToEdge;
@end

@protocol UIContentContainer
- (CGSize)preferredContentSize;
- (void)preferredContentSizeDidChangeForChildContentContainer:
    (id<UIContentContainer>)container;
- (void)systemLayoutFittingSizeDidChangeForChildContentContainer:
    (id<UIContentContainer>)container;
@end

@protocol UIViewControllerTransitionCoordinatorContext
- (BOOL)isAnimated;
- (BOOL)isInteractive;
- (BOOL)isCancelled;
- (double)transitionDuration;
- (double)percentComplete;
- (long)completionCurve;
- (double)completionVelocity;
- (UIView *)containerView;
- (UIViewController *)viewControllerForKey:(NSString *)key;
- (UIView *)viewForKey:(NSString *)key;
- (CGAffineTransform)targetTransform;
- (long)presentationStyle;
@end

@protocol UIViewControllerTransitionCoordinator
    <UIViewControllerTransitionCoordinatorContext>
- (BOOL)animateAlongsideTransition:
    (void (^)(id<UIViewControllerTransitionCoordinatorContext> context))animation
                       completion:
    (void (^)(id<UIViewControllerTransitionCoordinatorContext> context))completion;
- (BOOL)animateAlongsideTransitionInView:(UIView *)view
                               animation:
    (void (^)(id<UIViewControllerTransitionCoordinatorContext> context))animation
                              completion:
    (void (^)(id<UIViewControllerTransitionCoordinatorContext> context))completion;
- (void)notifyWhenInteractionChangesUsingBlock:
    (void (^)(id<UIViewControllerTransitionCoordinatorContext> context))handler;
- (void)notifyWhenInteractionEndsUsingBlock:
    (void (^)(id<UIViewControllerTransitionCoordinatorContext> context))handler;
@end

@interface UIViewController : NSObject <UIContentContainer>
- (id)init;
@property(nonatomic) long modalPresentationStyle;
@property unsigned long edgesForExtendedLayout;
@property BOOL extendedLayoutIncludesOpaqueBars;
@property BOOL automaticallyAdjustsScrollViewInsets;
@property BOOL definesPresentationContext;
@property(getter=isModalInPresentation) BOOL modalInPresentation;
@property(nonatomic, retain) id restorationIdentifier;
@property long modalTransitionStyle;
@property(nonatomic, assign) id<UIViewControllerTransitioningDelegate> transitioningDelegate;
@property BOOL modalPresentationCapturesStatusBarAppearance;
@property BOOL hidesBottomBarWhenPushed;
@property(copy) NSArray *toolbarItems;
- (void)setToolbarItems:(NSArray *)items animated:(BOOL)animated;
@property CGSize preferredContentSize;
- (void)preferredContentSizeDidChangeForChildContentContainer:
    (id<UIContentContainer>)container;
- (void)systemLayoutFittingSizeDidChangeForChildContentContainer:
    (id<UIContentContainer>)container;
@property(readonly) id<UIViewControllerTransitionCoordinator> transitionCoordinator;
- (void)viewWillTransitionToSize:(CGSize)size
       withTransitionCoordinator:
    (id<UIViewControllerTransitionCoordinator>)coordinator;
- (void)willTransitionToTraitCollection:(UITraitCollection *)newCollection
              withTransitionCoordinator:
    (id<UIViewControllerTransitionCoordinator>)coordinator;
@property(readonly) UIPopoverPresentationController *popoverPresentationController;
@property(readonly) UISheetPresentationController *sheetPresentationController;
@property(readonly) UIPresentationController *presentationController;
@property(nonatomic, retain) UIView *view;
@property(readonly) UIView *viewIfLoaded;
@property(readonly, getter=isViewLoaded) BOOL viewLoaded;
- (void)loadViewIfNeeded;
@property(readonly) BOOL isBeingPresented;
@property(readonly) BOOL isBeingDismissed;
@property(readonly) BOOL isMovingFromParentViewController;
@property(readonly) BOOL isMovingToParentViewController;
@property(readonly) BOOL shouldAutorotate;
@property(readonly) unsigned long supportedInterfaceOrientations;
@property(readonly) UIViewController *parentViewController;
@property(readonly) NSArray *children;
- (void)addChildViewController:(UIViewController *)controller;
- (void)removeFromParentViewController;
- (void)willMoveToParentViewController:(UIViewController *)parent;
- (void)didMoveToParentViewController:(UIViewController *)parent;
- (void)transitionFromViewController:(UIViewController *)fromViewController
                    toViewController:(UIViewController *)toViewController
                            duration:(double)duration
                             options:(unsigned long)options
                          animations:(void (^)(void))animations
                          completion:(void (^)(BOOL finished))completion;
@property(readonly) UITraitCollection *traitCollection;
@property(nonatomic) long overrideUserInterfaceStyle;
- (void)traitCollectionDidChange:(UITraitCollection *)previous;
@property UIEdgeInsets additionalSafeAreaInsets;
- (void)viewSafeAreaInsetsDidChange;
- (long)preferredStatusBarStyle;
- (BOOL)prefersStatusBarHidden;
- (UIViewController *)childForStatusBarStyle;
- (UIViewController *)childForStatusBarHidden;
- (void)setNeedsStatusBarAppearanceUpdate;
@property(nonatomic, retain) id title;
@property(readonly) id navigationController;
@property(readonly) id tabBarController;
@property(readonly) UINavigationItem *navigationItem;
@property(nonatomic, retain) id tabBarItem;
- (void)loadView;
- (void)viewDidLoad;
- (void)presentViewController:(UIViewController *)controller animated:(BOOL)animated
                   completion:(void (^)(void))completion;
- (void)showViewController:(UIViewController *)controller sender:(id)sender;
- (void)showDetailViewController:(UIViewController *)controller sender:(id)sender;
- (void)dismissViewControllerAnimated:(BOOL)animated
                           completion:(void (^)(void))completion;
@end

@class UISearchController;
@protocol UISearchResultsUpdating
- (void)updateSearchResultsForSearchController:
    (UISearchController *)searchController;
@end

@interface UISearchController : UIViewController
- (id)initWithSearchResultsController:(UIViewController *)controller;
@property(readonly) UISearchBar *searchBar;
@property(nonatomic, retain) id searchResultsUpdater;
@property(nonatomic, retain) id delegate;
@property(readonly) UIViewController *searchResultsController;
@property BOOL active;
@property BOOL obscuresBackgroundDuringPresentation;
@property BOOL dimsBackgroundDuringPresentation;
@property BOOL hidesNavigationBarDuringPresentation;
- (void)setActive:(BOOL)active animated:(BOOL)animated;
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
@property(nonatomic, retain) id attributedTitle;
- (BOOL)isRefreshing;
- (void)beginRefreshing;
- (void)endRefreshing;
@end

@class UIImageView;

enum {
    UIButtonConfigurationCornerStyleFixed = 0,
    UIButtonConfigurationCornerStyleDynamic = 1,
    UIButtonConfigurationCornerStyleCapsule = 2,
    UIButtonConfigurationCornerStyleLarge = 3
};

@interface UIButtonConfiguration : NSObject
+ (id)plainButtonConfiguration;
+ (id)filledButtonConfiguration;
+ (id)grayButtonConfiguration;
+ (id)tintedButtonConfiguration;
+ (id)borderedButtonConfiguration;
+ (id)borderlessButtonConfiguration;
+ (id)configurationWithTitle:(id)title;
@property(nonatomic, retain) id title;
@property(nonatomic, retain) id subtitle;
@property(nonatomic, retain) UIImage *image;
@property(nonatomic, retain) UIColor *baseForegroundColor;
@property(nonatomic, retain) UIColor *baseBackgroundColor;
@property long cornerStyle;
@property UIEdgeInsets contentInsets;
@property double imagePadding;
@end

@interface UIButton : UIControl
+ (id)buttonWithType:(int)type;
@property(nonatomic, retain) UIButtonConfiguration *configuration;
- (void)setNeedsUpdateConfiguration;
- (void)updateConfiguration;
- (void)setImage:(UIImage *)image forState:(unsigned long)state;
- (UIImage *)imageForState:(unsigned long)state;
@property(readonly) UIImageView *imageView;
- (void)setTitle:(id)title forState:(unsigned long)state;
- (void)setAttributedTitle:(NSAttributedString *)title
                  forState:(unsigned long)state;
- (NSAttributedString *)attributedTitleForState:(unsigned long)state;
- (void)setTitleColor:(UIColor *)color forState:(unsigned long)state;
@property UIEdgeInsets contentEdgeInsets;
@property UIEdgeInsets titleEdgeInsets;
@property UIEdgeInsets imageEdgeInsets;
@property(readonly) UILabel *titleLabel;
@end

@class UIAlertAction;

@interface UIAlertAction : NSObject
+ (id)actionWithTitle:(id)title style:(long)style
              handler:(void (^)(UIAlertAction *action))handler;
@property(nonatomic, retain) UIImage *image;
@property(nonatomic, getter=isEnabled) BOOL enabled;
@end

@interface UIAlertController : UIViewController
+ (id)alertControllerWithTitle:(id)title message:(id)message
                 preferredStyle:(long)style;
- (void)addAction:(UIAlertAction *)action;
@property(readonly) NSArray *textFields;
- (void)addTextFieldWithConfigurationHandler:
    (void (^)(UITextField *textField))configurationHandler;
@property(nonatomic, retain) UIAlertAction *preferredAction;
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

enum {
    UIImpactFeedbackStyleLight = 0,
    UIImpactFeedbackStyleMedium = 1,
    UIImpactFeedbackStyleHeavy = 2,
    UIImpactFeedbackStyleSoft = 3,
    UIImpactFeedbackStyleRigid = 4
};

enum {
    UINotificationFeedbackTypeSuccess = 0,
    UINotificationFeedbackTypeWarning = 1,
    UINotificationFeedbackTypeError = 2
};

@interface UIFeedbackGenerator : NSObject
- (void)prepare;
@end

@interface UIImpactFeedbackGenerator : UIFeedbackGenerator
- (id)initWithStyle:(long)style;
- (void)impactOccurred;
- (void)impactOccurredWithIntensity:(double)intensity;
@end

@interface UISelectionFeedbackGenerator : UIFeedbackGenerator
- (void)selectionChanged;
@end

@interface UINotificationFeedbackGenerator : UIFeedbackGenerator
- (void)notificationOccurred:(long)type;
@end

@interface UIPageControl : UIView
- (void)setNumberOfPages:(long)pages;
- (void)setCurrentPage:(long)page;
- (void)addTarget:(id)target action:(SEL)action
    forControlEvents:(unsigned long)events;
@end

enum {
    UIPageViewControllerNavigationDirectionForward = 0,
    UIPageViewControllerNavigationDirectionReverse = 1
};

enum {
    UIPageViewControllerTransitionStylePageCurl = 0,
    UIPageViewControllerTransitionStyleScroll = 1
};

enum {
    UIPageViewControllerNavigationOrientationHorizontal = 0,
    UIPageViewControllerNavigationOrientationVertical = 1
};

@class UIPageViewController;

@protocol UIPageViewControllerDelegate
@optional
- (void)pageViewController:(UIPageViewController *)pageViewController
    didFinishAnimating:(BOOL)finished
   previousViewControllers:(NSArray *)previousViewControllers
       transitionCompleted:(BOOL)completed;
@end

@protocol UIPageViewControllerDataSource
- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController
      viewControllerBeforeViewController:(UIViewController *)viewController;
- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController
       viewControllerAfterViewController:(UIViewController *)viewController;
@end

@interface UIPageViewController : UIViewController
- (id)initWithTransitionStyle:(long)style
        navigationOrientation:(long)orientation
                      options:(id)options;
- (void)setViewControllers:(NSArray *)viewControllers
                 direction:(long)direction
                  animated:(BOOL)animated
                completion:(void (^)(BOOL finished))completion;
@property(readonly) NSArray *viewControllers;
@property(nonatomic, assign) id<UIPageViewControllerDelegate> delegate;
@property(nonatomic, assign) id<UIPageViewControllerDataSource> dataSource;
@property(readonly) long transitionStyle;
@property(readonly) long navigationOrientation;
@property(getter=isDoubleSided) BOOL doubleSided;
@end

enum {
    UISplitViewControllerStyleAutomatic = 0,
    UISplitViewControllerStyleDoubleColumn = 1,
    UISplitViewControllerStyleTripleColumn = 2
};

enum {
    UISplitViewControllerColumnPrimary = 0,
    UISplitViewControllerColumnSupplementary = 1,
    UISplitViewControllerColumnSecondary = 2,
    UISplitViewControllerColumnCompact = 3
};

enum {
    UISplitViewControllerDisplayModeAutomatic = 0,
    UISplitViewControllerDisplayModeSecondaryOnly = 1,
    UISplitViewControllerDisplayModePrimaryHidden = 1,
    UISplitViewControllerDisplayModeOneBesideSecondary = 2,
    UISplitViewControllerDisplayModeAllVisible = 2,
    UISplitViewControllerDisplayModeOneOverSecondary = 3,
    UISplitViewControllerDisplayModePrimaryOverlay = 3,
    UISplitViewControllerDisplayModeTwoBesideSecondary = 4,
    UISplitViewControllerDisplayModeTwoOverSecondary = 5,
    UISplitViewControllerDisplayModeTwoDisplaceSecondary = 6
};

@class UISplitViewController;

@protocol UISplitViewControllerDelegate
@optional
- (BOOL)splitViewController:(UISplitViewController *)splitViewController
    collapseSecondaryViewController:(UIViewController *)secondaryViewController
        ontoPrimaryViewController:(UIViewController *)primaryViewController;
- (void)splitViewController:(UISplitViewController *)splitViewController
       willChangeToDisplayMode:(long)displayMode;
@end

@interface UISplitViewController : UIViewController
- (id)initWithStyle:(long)style;
@property(copy) NSArray *viewControllers;
@property(nonatomic, assign) id<UISplitViewControllerDelegate> delegate;
@property(readonly) long style;
@property long preferredDisplayMode;
@property(readonly) long displayMode;
@property(getter=isCollapsed, readonly) BOOL collapsed;
@property(readonly) UIViewController *primaryViewController;
@property(readonly) UIViewController *secondaryViewController;
- (void)setViewController:(UIViewController *)viewController
                 forColumn:(long)column;
- (UIViewController *)viewControllerForColumn:(long)column;
@property double preferredPrimaryColumnWidthFraction;
@property(readonly) double primaryColumnWidth;
@property double minimumPrimaryColumnWidth;
@property double maximumPrimaryColumnWidth;
@property double supplementaryColumnWidth;
- (void)toggleMasterVisible:(id)sender;
- (void)viewWillLayoutSubviews;
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

@class UIWindow, UISceneSession;

@interface UIScene : NSObject
@property(nonatomic, assign) id delegate;
@property(readonly) UISceneSession *session;
@property(readonly) long activationState;
@end

@interface UIWindowScene : UIScene
@property(readonly) NSArray *windows;
@property(readonly) UIWindow *keyWindow;
@property(readonly) UIScreen *screen;
@property(readonly) long interfaceOrientation;
@end

@interface UISceneSession : NSObject
@property(readonly) id persistentIdentifier;
@property(readonly) id role;
@property(nonatomic, retain) id configuration;
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
@property long keyboardDismissMode;
@property long indicatorStyle;
@property BOOL scrollsToTop;
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

enum {
    UIWindowLevelNormal = 0,
    UIWindowLevelStatusBar = 1000,
    UIWindowLevelAlert = 2000
};

@interface UIWindow : UIView
+ (UIWindow *)keyWindow;
@property(nonatomic, retain) UIViewController *rootViewController;
@property(readonly) UIWindowScene *windowScene;
@property double windowLevel;
@property(readonly, getter=isKeyWindow) BOOL keyWindow;
- (void)makeKeyWindow;
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

enum {
    UIStatusBarStyleDefault = 0,
    UIStatusBarStyleLightContent = 1,
    UIStatusBarStyleDarkContent = 3
};

@interface UIApplication : UIResponder
+ (UIApplication *)sharedApplication;
- (long)applicationState;
- (long)statusBarStyle;
- (void)setStatusBarStyle:(long)style animated:(BOOL)animated;
- (BOOL)isStatusBarHidden;
- (void)setStatusBarHidden:(BOOL)hidden animated:(BOOL)animated;
- (double)backgroundTimeRemaining;
- (unsigned long)beginBackgroundTaskWithExpirationHandler:(void (^)(void))handler;
- (void)endBackgroundTask:(unsigned long)task;
@property(nonatomic) long applicationIconBadgeNumber;
- (BOOL)canOpenURL:(id)url;
- (BOOL)openURL:(id)url;
- (void)openURL:(id)url options:(id)options
    completionHandler:(void (^)(BOOL success))completion;
@property(nonatomic, getter=isIdleTimerDisabled) BOOL idleTimerDisabled;
- (void)registerForRemoteNotifications;
- (void)unregisterForRemoteNotifications;
- (BOOL)isRegisteredForRemoteNotifications;
@property(readonly) NSArray *windows;
@property(readonly) UIWindow *keyWindow;
@property(readonly) NSArray *connectedScenes;
@end

extern id UIPasteboardTypeListString;
extern id UIPasteboardTypeListImage;
extern id UIPasteboardTypeListURL;
extern id UIPasteboardTypeListColor;

extern id UIPasteboardChangedNotification;
extern id UIPasteboardRemovedNotification;

@interface UIPasteboard : NSObject
+ (UIPasteboard *)generalPasteboard;
@property(nonatomic, retain) id string;
@property(nonatomic, retain) NSArray *strings;
@property(nonatomic, retain) UIImage *image;
@property(nonatomic, retain) NSArray *images;
@property(readonly) BOOL hasImages;
@property(nonatomic, retain) NSURL *URL;
@property(nonatomic, retain) NSArray *URLs;
@property(nonatomic, retain) UIColor *color;
@property(nonatomic, retain) NSArray *colors;
@property(readonly) NSArray *types;
@property(readonly) long changeCount;
- (BOOL)hasStrings;
- (BOOL)containsPasteboardTypes:(NSArray *)types;
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
+ (instancetype)bezierPathWithRect:(CGRect)rect;
+ (instancetype)bezierPathWithRoundedRect:(CGRect)rect
                             cornerRadius:(double)radius;
+ (instancetype)bezierPathWithOvalInRect:(CGRect)rect;
- (void)moveToPoint:(CGPoint)point;
- (void)addLineToPoint:(CGPoint)point;
- (void)addArcWithCenter:(CGPoint)center radius:(double)radius
              startAngle:(double)startAngle endAngle:(double)endAngle
               clockwise:(BOOL)clockwise;
- (void)addOvalInRect:(CGRect)rect;
- (void)addRect:(CGRect)rect;
- (void)addRoundedRect:(CGRect)rect cornerRadius:(double)radius;
- (void)addQuadCurveToPoint:(CGPoint)point controlPoint:(CGPoint)control;
- (void)addCurveToPoint:(CGPoint)point controlPoint1:(CGPoint)control1
           controlPoint2:(CGPoint)control2;
- (void)closePath;
- (void)appendPath:(UIBezierPath *)path;
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
@property(nonatomic, retain) NSArray *lineDashPattern;
@property double lineDashPhase;
@property double miterLimit;
@end

@interface CAGradientLayer : CALayer
@property(nonatomic, retain) id colors;
@property(nonatomic, retain) id locations;
@property CGPoint startPoint;
@property CGPoint endPoint;
@property(nonatomic, retain) id type;
@end

@interface CATextLayer : CALayer
@property(nonatomic, retain) id string;
@property(nonatomic, retain) id font;
@property double fontSize;
@property(nonatomic, retain) id foregroundColor;
@property long alignmentMode;
@property(getter=isWrapped) BOOL wrapped;
@end

@interface UIImage : NSObject {
@public
    unsigned char *_rgba;
    int _width;
    int _height;
}
+ (UIImage *)imageNamed:(NSString *)name;
+ (UIImage *)imageWithData:(NSData *)data;
+ (UIImage *)imageWithCGImage:(CGImageRef)image;
- (int)width;
- (int)height;
- (CGImageRef)CGImage;
@end

@interface UITabBarItem : NSObject
- (id)initWithTitle:(NSString *)title image:(UIImage *)image tag:(long)tag;
@end

@interface UITabBarController : UIViewController
@property(nonatomic, retain) id delegate;
- (void)setViewControllers:(NSArray *)controllers;
- (void)setViewControllers:(NSArray *)controllers animated:(BOOL)animated;
- (NSArray *)viewControllers;
- (void)setSelectedIndex:(int)index;
- (int)selectedIndex;
- (UIViewController *)selectedViewController;
@end

@interface NSArray : NSObject <NSFastEnumeration>
+ (id)arrayWithObjects:(id)first, ...;
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
+ (id)indexPathForItem:(long)item inSection:(long)section;
@property(readonly) long row;
@property(readonly) long section;
@property(readonly) long item;
@property(readonly) long length;
- (long)indexAtPosition:(unsigned long)position;
- (id)indexPathByAddingIndex:(long)index;
- (id)indexPathByRemovingLastIndex;
- (long)compare:(NSIndexPath *)other;
- (void)getIndexes:(long *)indexes;
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
extern id UICollectionElementKindSectionHeader;
extern id UICollectionElementKindSectionFooter;

@interface UICollectionViewLayout : NSObject
@end

@interface UICollectionViewFlowLayout : UICollectionViewLayout
@property CGSize itemSize;
@property double minimumInteritemSpacing;
@property double minimumLineSpacing;
@property UIEdgeInsets sectionInset;
@property long scrollDirection;
@property CGSize headerReferenceSize;
@property CGSize footerReferenceSize;
@end

@interface UICollectionReusableView : UIView
@property(readonly) id reuseIdentifier;
- (void)prepareForReuse;
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
- (void)registerClass:(Class)viewClass
    forSupplementaryViewOfKind:(id)kind
           withReuseIdentifier:(id)identifier;
- (id)dequeueReusableSupplementaryViewOfKind:(id)kind
                         withReuseIdentifier:(id)identifier
                                forIndexPath:(NSIndexPath *)indexPath;
- (void)reloadData;
@property(nonatomic, retain) id prefetchDataSource;
@property(nonatomic, retain) id dragDelegate;
@property(nonatomic, retain) id dropDelegate;
@property(nonatomic, retain) UIView *backgroundView;
@property BOOL allowsSelection;
@property BOOL allowsMultipleSelection;
@property BOOL dragInteractionEnabled;
@property(readonly) NSArray *visibleCells;
@property(readonly) NSArray *indexPathsForVisibleItems;
@property(readonly) long numberOfSections;
- (long)numberOfItemsInSection:(long)section;
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
@property long separatorStyle;
@property(nonatomic, retain) UIColor *separatorColor;
@property UIEdgeInsets separatorInset;
@property(nonatomic, retain) UIView *tableHeaderView;
@property(nonatomic, retain) UIView *tableFooterView;
@property(nonatomic, retain) UIView *backgroundView;
@property(nonatomic, retain) id prefetchDataSource;
@property(nonatomic, retain) id dragDelegate;
@property(nonatomic, retain) id dropDelegate;
@property BOOL allowsSelection;
@property BOOL allowsMultipleSelection;
@property BOOL allowsSelectionDuringEditing;
@property BOOL allowsMultipleSelectionDuringEditing;
@property BOOL dragInteractionEnabled;
@property BOOL cellLayoutMarginsFollowReadableWidth;
@property BOOL insetsContentViewsToSafeArea;
@property double estimatedRowHeight;
@property double estimatedSectionHeaderHeight;
@property double estimatedSectionFooterHeight;
@property double sectionHeaderHeight;
@property double sectionFooterHeight;
@end

void UIGraphicsBeginImageContextWithOptions(CGSize size, BOOL opaque,
                                            double scale);
void UIGraphicsBeginImageContext(CGSize size);
CGContextRef UIGraphicsGetCurrentContext(void);
void UIGraphicsPushContext(CGContextRef context);
void UIGraphicsPopContext(void);
UIImage *UIGraphicsGetImageFromCurrentImageContext(void);
void UIGraphicsEndImageContext(void);
NSData *UIImagePNGRepresentation(UIImage *image);

@interface UIGraphicsImageRendererFormat : NSObject
+ (id)defaultFormat;
@property double scale;
@property BOOL opaque;
@end

@interface UIGraphicsImageRendererContext : NSObject
@property(readonly) CGContextRef CGContext;
@end

@interface UIGraphicsImageRenderer : NSObject
- (id)initWithSize:(CGSize)size;
- (id)initWithSize:(CGSize)size
            format:(UIGraphicsImageRendererFormat *)format;
- (UIImage *)imageWithActions:(void (^)(UIGraphicsImageRendererContext *context))actions;
- (NSData *)PNGDataWithActions:(void (^)(UIGraphicsImageRendererContext *context))actions;
@end

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
- (id)initWithImage:(UIImage *)image style:(long)style target:(id)target
             action:(SEL)action;
- (id)initWithCustomView:(UIView *)view;
@property(nonatomic, retain) id title;
@property(nonatomic, retain) UIImage *image;
@property(nonatomic, retain) UIColor *tintColor;
@property(nonatomic, readonly) UIView *customView;
@property double width;
@end

@interface UINavigationItem : NSObject
- (id)initWithTitle:(id)title;
@property(nonatomic, retain) id title;
@property(nonatomic, retain) UIBarButtonItem *leftBarButtonItem;
@property(nonatomic, retain) UIBarButtonItem *rightBarButtonItem;
@property(nonatomic, retain) UIBarButtonItem *backBarButtonItem;
@property(nonatomic, retain) id backButtonTitle;
@property(nonatomic, retain) NSArray *leftBarButtonItems;
@property(nonatomic, retain) NSArray *rightBarButtonItems;
- (void)setLeftBarButtonItems:(NSArray *)items animated:(BOOL)animated;
- (void)setRightBarButtonItems:(NSArray *)items animated:(BOOL)animated;
@property(nonatomic, retain) id prompt;
@property(nonatomic, retain) UISearchController *searchController;
@property long largeTitleDisplayMode;
@property BOOL hidesBackButton;
@end

@interface UINavigationBar : UIView
- (void)setItems:(NSArray *)items animated:(BOOL)animated;
- (NSArray *)items;
- (UINavigationItem *)topItem;
- (void)pushNavigationItem:(UINavigationItem *)item animated:(BOOL)animated;
- (UINavigationItem *)popNavigationItemAnimated:(BOOL)animated;
@property(nonatomic, retain) UIColor *barTintColor;
@property long barStyle;
@property BOOL prefersLargeTitles;
@property(getter=isTranslucent) BOOL translucent;
@property(nonatomic, retain) id titleTextAttributes;
@property(nonatomic, retain) id largeTitleTextAttributes;
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
@property(nonatomic, retain) id delegate;
- (id)initWithRootViewController:(UIViewController *)root;
@property(readonly) UINavigationBar *navigationBar;
@property(getter=isNavigationBarHidden) BOOL navigationBarHidden;
@property(readonly) UIToolbar *toolbar;
- (void)setToolbarHidden:(BOOL)hidden animated:(BOOL)animated;
@property(getter=isToolbarHidden) BOOL toolbarHidden;
- (void)pushViewController:(UIViewController *)controller animated:(BOOL)animated;
- (UIViewController *)popViewControllerAnimated:(BOOL)animated;
- (NSArray *)viewControllers;
- (void)setViewControllers:(NSArray *)controllers animated:(BOOL)animated;
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
@property(getter=isEnabled) BOOL enabled;
@property(nonatomic, assign) id delegate;
@property(readonly) unsigned long numberOfTouches;
@property BOOL delaysTouchesBegan;
@property BOOL delaysTouchesEnded;
@property BOOL cancelsTouchesInView;
@property(nonatomic, retain) NSArray *allowedTouchTypes;
- (void)requireGestureRecognizerToFail:(UIGestureRecognizer *)other;
@end

@interface UITapGestureRecognizer : UIGestureRecognizer
@property int numberOfTapsRequired;
@property int numberOfTouchesRequired;
@end

@interface UIPanGestureRecognizer : UIGestureRecognizer
- (CGPoint)translationInView:(UIView *)view;
- (CGPoint)velocityInView:(UIView *)view;
- (void)setTranslation:(CGPoint)translation inView:(UIView *)view;
@property unsigned long minimumNumberOfTouches;
@property unsigned long maximumNumberOfTouches;
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

@interface UISwipeGestureRecognizer : UIGestureRecognizer
@property long direction;
@property int numberOfTouchesRequired;
@end

#define CGRectZero CGRectMake(0, 0, 0, 0)

/* ------------------------------------------- UserNotifications.framework */

enum {
    UNAuthorizationStatusNotDetermined = 0,
    UNAuthorizationStatusDenied = 1,
    UNAuthorizationStatusAuthorized = 2,
    UNAuthorizationStatusProvisional = 3,
    UNAuthorizationStatusEphemeral = 4
};

enum {
    UNAuthorizationOptionBadge = 1,
    UNAuthorizationOptionSound = 2,
    UNAuthorizationOptionAlert = 4,
    UNAuthorizationOptionCarPlay = 8,
    UNAuthorizationOptionCriticalAlert = 16,
    UNAuthorizationOptionProvisional = 32,
    UNAuthorizationOptionProvidesAppNotificationSettings = 64
};

enum {
    UNNotificationSettingNotSupported = 0,
    UNNotificationSettingDisabled = 1,
    UNNotificationSettingEnabled = 2
};

enum {
    UNNotificationPresentationOptionBadge = 1,
    UNNotificationPresentationOptionSound = 2,
    UNNotificationPresentationOptionAlert = 4,
    UNNotificationPresentationOptionList = 8,
    UNNotificationPresentationOptionBanner = 16
};

@protocol UNUserNotificationCenterDelegate
- (void)userNotificationCenter:(id)center
       willPresentNotification:(id)notification
         withCompletionHandler:(void (^)(unsigned long options))completionHandler;
- (void)userNotificationCenter:(id)center
    didReceiveNotificationResponse:(id)response
             withCompletionHandler:(void (^)(void))completionHandler;
@end

@interface UNNotificationContent : NSObject
- (id)title;
- (void)setTitle:(id)title;
- (id)subtitle;
- (void)setSubtitle:(id)subtitle;
- (id)body;
- (void)setBody:(id)body;
- (id)sound;
- (void)setSound:(id)sound;
- (id)badge;
- (void)setBadge:(id)badge;
- (id)categoryIdentifier;
- (void)setCategoryIdentifier:(id)identifier;
- (id)threadIdentifier;
- (void)setThreadIdentifier:(id)identifier;
- (id)userInfo;
- (void)setUserInfo:(id)userInfo;
- (unsigned long)summaryArgumentCount;
- (void)setSummaryArgumentCount:(unsigned long)count;
- (id)summaryArgument;
- (void)setSummaryArgument:(id)argument;
@end

@interface UNMutableNotificationContent : UNNotificationContent
@end

@interface UNNotificationSound : NSObject
+ (id)defaultSound;
+ (id)soundNamed:(id)name;
- (id)name;
@end

enum {
    UNNotificationActionOptionAuthenticationRequired = 1,
    UNNotificationActionOptionDestructive = 2,
    UNNotificationActionOptionForeground = 4
};

@interface UNNotificationAction : NSObject
+ (id)actionWithIdentifier:(id)identifier title:(id)title
                   options:(unsigned long)options;
- (id)identifier;
- (id)title;
- (unsigned long)options;
@end

enum {
    UNNotificationCategoryOptionCustomDismissAction = 1,
    UNNotificationCategoryOptionAllowInCarPlay = 2
};

@interface UNNotificationCategory : NSObject
+ (id)categoryWithIdentifier:(id)identifier actions:(id)actions
            intentIdentifiers:(id)intentIdentifiers
                      options:(unsigned long)options;
- (id)identifier;
- (id)actions;
- (id)intentIdentifiers;
- (unsigned long)options;
@end

@interface UNNotificationTrigger : NSObject
- (BOOL)repeats;
@end

@interface UNTimeIntervalNotificationTrigger : UNNotificationTrigger
+ (id)triggerWithTimeInterval:(double)interval repeats:(BOOL)repeats;
- (double)timeInterval;
- (id)nextTriggerDate;
@end

@interface UNNotificationRequest : NSObject
+ (id)requestWithIdentifier:(id)identifier content:(id)content
                    trigger:(id)trigger;
- (id)identifier;
- (id)content;
- (id)trigger;
@end

@interface UNNotification : NSObject
- (id)request;
- (id)date;
@end

@interface UNNotificationResponse : NSObject
- (id)notification;
- (id)actionIdentifier;
- (id)userInfo;
@end

@interface UNNotificationSettings : NSObject
- (long)authorizationStatus;
- (long)alertSetting;
- (long)soundSetting;
- (long)badgeSetting;
- (long)notificationCenterSetting;
- (long)lockScreenSetting;
- (long)criticalAlertSetting;
@end

@interface UNUserNotificationCenter : NSObject
+ (id)currentNotificationCenter;
- (id)delegate;
- (void)setDelegate:(id)delegate;
- (void)requestAuthorizationWithOptions:(unsigned long)options
                      completionHandler:(void (^)(BOOL granted, id error))completion;
- (void)getNotificationSettingsWithCompletionHandler:
    (void (^)(id settings))completion;
- (void)addNotificationRequest:(UNNotificationRequest *)request
          withCompletionHandler:(void (^)(id error))completion;
- (void)removePendingNotificationRequestsWithIdentifiers:(id)identifiers;
- (void)removeAllPendingNotificationRequests;
- (void)getPendingNotificationRequestsWithCompletionHandler:
    (void (^)(id requests))completion;
- (void)getDeliveredNotificationsWithCompletionHandler:
    (void (^)(id notifications))completion;
- (void)removeDeliveredNotificationsWithIdentifiers:(id)identifiers;
- (void)removeAllDeliveredNotifications;
- (void)setNotificationCategories:(id)categories;
- (void)getNotificationCategoriesWithCompletionHandler:
    (void (^)(id categories))completion;
@end

extern NSString *const UNNotificationDefaultActionIdentifier;

enum {
    UIAccessibilityTraitNone = 0,
    UIAccessibilityTraitButton = 1,
    UIAccessibilityTraitLink = 2,
    UIAccessibilityTraitSearchField = 4,
    UIAccessibilityTraitImage = 8,
    UIAccessibilityTraitSelected = 16,
    UIAccessibilityTraitPlaysSound = 32,
    UIAccessibilityTraitStaticText = 64,
    UIAccessibilityTraitSummaryElement = 128,
    UIAccessibilityTraitNotEnabled = 256,
    UIAccessibilityTraitUpdatesFrequently = 512,
    UIAccessibilityTraitHeader = 1024,
    UIAccessibilityTraitAdjustable = 2048
};
void UIAccessibilityPostNotification(unsigned int notification, id argument);
BOOL UIAccessibilityIsVoiceOverRunning(void);
BOOL UIAccessibilityIsReduceMotionEnabled(void);
BOOL UIAccessibilityIsReduceTransparencyEnabled(void);
BOOL UIAccessibilityIsSwitchControlRunning(void);
BOOL UIAccessibilityIsBoldTextEnabled(void);
BOOL UIAccessibilityIsInvertColorsEnabled(void);
BOOL UIAccessibilityIsGrayscaleEnabled(void);

#endif
