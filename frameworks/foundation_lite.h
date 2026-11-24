#ifndef IOSIM_FOUNDATION_LITE_H
#define IOSIM_FOUNDATION_LITE_H

#include "objc_lite.h"

typedef struct {
    unsigned long location;
    unsigned long length;
} NSRange;

#define NSNotFound ((unsigned long)-1)

static inline NSRange NSMakeRange(unsigned long location,
                                  unsigned long length)
{
    NSRange range;
    range.location = location;
    range.length = length;
    return range;
}

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

@class NSString;
@class NSArray;
@class NSDictionary;

typedef unsigned long NSKeyValueObservingOptions;
enum {
    NSKeyValueObservingOptionNew     = 0x01,
    NSKeyValueObservingOptionOld     = 0x02,
    NSKeyValueObservingOptionInitial = 0x04,
    NSKeyValueObservingOptionPrior   = 0x08
};

typedef unsigned long NSKeyValueChange;
enum {
    NSKeyValueChangeSetting    = 1,
    NSKeyValueChangeInsertion  = 2,
    NSKeyValueChangeRemoval    = 3,
    NSKeyValueChangeReplacement = 4
};

extern id NSKeyValueChangeKindKey;
extern id NSKeyValueChangeNewKey;
extern id NSKeyValueChangeOldKey;
extern id NSKeyValueChangeIndexesKey;
extern id NSKeyValueChangeNotificationIsPriorKey;

__attribute__((objc_root_class))
@interface NSObject {
    Class isa;
}
+ (id)alloc;
+ (id)new;
+ (Class)class;
- (id)init;
- (void)dealloc;
- (id)retain;
- (void)release;
- (id)autorelease;
- (unsigned long)retainCount;
- (Class)class;
- (Class)superclass;
- (BOOL)isKindOfClass:(Class)cls;
- (BOOL)isMemberOfClass:(Class)cls;
- (BOOL)respondsToSelector:(SEL)sel;
+ (BOOL)resolveInstanceMethod:(SEL)sel;
+ (BOOL)resolveClassMethod:(SEL)sel;
- (id)forwardingTargetForSelector:(SEL)sel;
- (void)doesNotRecognizeSelector:(SEL)sel;
- (BOOL)isEqual:(id)other;
- (unsigned long)hash;
- (id)description;
- (void)performSelector:(SEL)selector withObject:(id)argument;
- (void)performSelector:(SEL)selector withObject:(id)argument
             afterDelay:(double)delay;
+ (void)cancelPreviousPerformRequestsWithTarget:(id)target;
+ (void)cancelPreviousPerformRequestsWithTarget:(id)target
                                       selector:(SEL)selector
                                         object:(id)argument;

/* Key-value coding. Accessor lookup follows KVC's get<Key>, <key>, is<Key>
 * order for reads and set<Key>:, _set<Key>: for writes; key paths walk the
 * dot-separated components. */
- (id)valueForKey:(NSString *)key;
- (void)setValue:(id)value forKey:(NSString *)key;
- (id)valueForKeyPath:(NSString *)keyPath;
- (void)setValue:(id)value forKeyPath:(NSString *)keyPath;
- (id)dictionaryWithValuesForKeys:(NSArray *)keys;
- (void)setValuesForKeysWithDictionary:(NSDictionary *)keyedValues;

/* Key-value observing. addObserver: installs an NSKVONotifying_ subclass and
 * wraps the key's setter so changes notify automatically. */
- (void)addObserver:(NSObject *)observer forKeyPath:(NSString *)keyPath
            options:(NSKeyValueObservingOptions)options context:(void *)context;
- (void)removeObserver:(NSObject *)observer forKeyPath:(NSString *)keyPath;
- (void)removeObserver:(NSObject *)observer forKeyPath:(NSString *)keyPath
               context:(void *)context;
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object
                        change:(NSDictionary *)change context:(void *)context;
- (void)willChangeValueForKey:(NSString *)key;
- (void)didChangeValueForKey:(NSString *)key;
+ (BOOL)automaticallyNotifiesObserversForKey:(NSString *)key;
@end

@class NSString;

typedef enum {
    NSOrderedAscending = -1,
    NSOrderedSame = 0,
    NSOrderedDescending = 1
} NSComparisonResult;

@class NSCharacterSet;

extern id NSFontAttributeName;
extern id NSForegroundColorAttributeName;
extern id NSBackgroundColorAttributeName;
extern id NSUnderlineStyleAttributeName;
extern id NSParagraphStyleAttributeName;
extern id NSShadowAttributeName;

@interface NSShadow : NSObject {
@public
    CGSize _shadowOffset;
    double _shadowBlurRadius;
    id _shadowColor;
}
- (CGSize)shadowOffset;
- (void)setShadowOffset:(CGSize)offset;
- (double)shadowBlurRadius;
- (void)setShadowBlurRadius:(double)radius;
- (id)shadowColor;
- (void)setShadowColor:(id)color;
@end

@interface NSString : NSObject {
@public
    char *_cstr;
    unsigned long _length;
}
+ (id)stringWithUTF8String:(const char *)s;
+ (id)stringWithFormat:(id)format, ...;
+ (id)stringWithString:(id)other;
- (id)copy;
- (id)initWithUTF8String:(const char *)s;
- (id)initWithFormat:(id)format, ...;
- (const char *)UTF8String;
- (unsigned long)length;
- (unsigned short)characterAtIndex:(unsigned long)index;
- (BOOL)isEqualToString:(id)other;
- (long)compare:(NSString *)other;
- (long)caseInsensitiveCompare:(NSString *)other;
- (id)stringByAppendingString:(id)other;
- (id)uppercaseString;
- (id)lowercaseString;
- (id)substringToIndex:(unsigned long)index;
- (id)substringFromIndex:(unsigned long)index;
- (id)substringWithRange:(NSRange)range;
- (BOOL)hasPrefix:(id)prefix;
- (BOOL)hasSuffix:(id)suffix;
- (id)componentsSeparatedByString:(id)separator;
- (id)stringByReplacingOccurrencesOfString:(id)target withString:(id)replacement;
- (id)stringByAppendingPathComponent:(id)component;
- (id)stringByAppendingPathExtension:(id)extension;
- (id)lastPathComponent;
- (id)pathExtension;
- (id)stringByDeletingLastPathComponent;
- (id)stringByDeletingPathExtension;
- (id)dataUsingEncoding:(unsigned long)encoding;
- (id)initWithData:(id)data encoding:(unsigned long)encoding;
- (BOOL)containsString:(id)needle;
- (id)stringByTrimmingCharactersInSet:(NSCharacterSet *)set;
- (id)stringByReplacingCharactersInRange:(NSRange)range withString:(id)replacement;
- (NSRange)rangeOfString:(id)needle;
- (id)capitalizedString;
- (id)stringByRemovingPercentEncoding;
- (id)stringByAddingPercentEncodingWithAllowedCharacters:
    (NSCharacterSet *)allowedCharacters;
- (id)stringByAddingPercentEscapesUsingEncoding:(unsigned long)encoding;
- (id)stringByReplacingPercentEscapesUsingEncoding:(unsigned long)encoding;
- (long)integerValue;
- (int)intValue;
- (double)doubleValue;
- (float)floatValue;
- (BOOL)boolValue;
@end

@interface NSAttributedString : NSObject {
@public
    id _string;
    id _attributes;
    id _runs;
}
- (id)initWithString:(id)string;
- (id)initWithString:(id)string attributes:(id)attributes;
- (id)initWithAttributedString:(id)other;
- (id)string;
- (unsigned long)length;
- (id)attributesAtIndex:(unsigned long)index
         effectiveRange:(NSRange *)range;
- (id)attribute:(id)name atIndex:(unsigned long)index
    effectiveRange:(NSRange *)range;
@end

@interface NSMutableAttributedString : NSAttributedString
- (id)initWithString:(id)string;
- (id)initWithString:(id)string attributes:(id)attributes;
- (void)addAttribute:(id)name value:(id)value range:(NSRange)range;
- (void)addAttributes:(id)attributes range:(NSRange)range;
- (void)setAttributes:(id)attributes range:(NSRange)range;
- (void)replaceCharactersInRange:(NSRange)range withString:(id)string;
- (void)appendAttributedString:(id)other;
@end

@interface NSParagraphStyle : NSObject {
@public
    long _alignment;
    double _lineSpacing;
    double _paragraphSpacing;
    double _paragraphSpacingBefore;
    double _firstLineHeadIndent;
    double _headIndent;
    double _tailIndent;
    long _lineBreakMode;
    double _minimumLineHeight;
    double _maximumLineHeight;
}
+ (id)defaultParagraphStyle;
- (long)alignment;
- (double)lineSpacing;
- (double)paragraphSpacing;
- (double)paragraphSpacingBefore;
- (double)firstLineHeadIndent;
- (double)headIndent;
- (double)tailIndent;
- (long)lineBreakMode;
- (double)minimumLineHeight;
- (double)maximumLineHeight;
@end

@interface NSMutableParagraphStyle : NSParagraphStyle
- (void)setAlignment:(long)alignment;
- (void)setLineSpacing:(double)spacing;
- (void)setParagraphSpacing:(double)spacing;
- (void)setParagraphSpacingBefore:(double)spacing;
- (void)setFirstLineHeadIndent:(double)indent;
- (void)setHeadIndent:(double)indent;
- (void)setTailIndent:(double)indent;
- (void)setLineBreakMode:(long)mode;
- (void)setMinimumLineHeight:(double)height;
- (void)setMaximumLineHeight:(double)height;
@end

@interface NSCharacterSet : NSObject {
@public
    char *_cstr;
    unsigned long _length;
}
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

enum {
    NSRegularExpressionCaseInsensitive = 1 << 0,
    NSRegularExpressionAllowCommentsAndWhitespace = 1 << 1,
    NSRegularExpressionIgnoreMetaCharacters = 1 << 2,
    NSRegularExpressionUseUnixLineSeparators = 1 << 3,
    NSRegularExpressionUseUnicodeWordBoundaries = 1 << 4
};

@interface NSTextCheckingResult : NSObject {
@public
    NSRange *_ranges;
    unsigned long _rangeCount;
}
- (NSRange)range;
- (NSRange)rangeAtIndex:(unsigned long)index;
- (unsigned long)numberOfRanges;
@end

@interface NSRegularExpression : NSObject {
@public
    id _pattern;
    unsigned long _options;
    unsigned long _groups;
}
+ (id)regularExpressionWithPattern:(id)pattern options:(unsigned long)options
                             error:(id *)error;
- (id)initWithPattern:(id)pattern options:(unsigned long)options
                error:(id *)error;
- (id)pattern;
- (unsigned long)options;
- (unsigned long)numberOfCaptureGroups;
- (id)matchesInString:(id)string options:(unsigned long)options
                range:(NSRange)range;
- (id)firstMatchInString:(id)string options:(unsigned long)options
                   range:(NSRange)range;
- (id)stringByReplacingMatchesInString:(id)string options:(unsigned long)options
                                 range:(NSRange)range
                          withTemplate:(id)template;
@end

@interface NSPredicate : NSObject {
@public
    id _format;
}
+ (id)predicateWithFormat:(id)format, ...;
+ (id)predicateWithValue:(BOOL)value;
- (BOOL)evaluateWithObject:(id)object;
- (id)predicateFormat;
@end

@interface NSScanner : NSObject {
@public
    id _string;
    unsigned long _location;
    BOOL _caseSensitive;
    BOOL _skipsWhitespace;
}
+ (id)scannerWithString:(id)string;
- (id)initWithString:(id)string;
- (id)string;
- (unsigned long)scanLocation;
- (void)setScanLocation:(unsigned long)location;
- (BOOL)isAtEnd;
- (BOOL)scanString:(id)string intoString:(id *)result;
- (BOOL)scanInt:(int *)result;
- (BOOL)scanLongLong:(long long *)result;
- (BOOL)scanDouble:(double *)result;
- (BOOL)scanUpToString:(id)stop intoString:(id *)result;
@end

@interface NSMutableString : NSString
+ (id)string;
- (void)appendString:(id)string;
- (void)setString:(id)string;
@end

@interface NSIndexPath : NSObject {
@public
    long _row;
    long _section;
    long _indexes[8];
    int _length;
}
+ (id)indexPathForRow:(long)row inSection:(long)section;
+ (id)indexPathForItem:(long)item inSection:(long)section;
- (long)row;
- (long)section;
- (long)item;
- (long)length;
- (long)indexAtPosition:(unsigned long)position;
- (id)indexPathByAddingIndex:(long)index;
- (id)indexPathByRemovingLastIndex;
- (long)compare:(NSIndexPath *)other;
- (void)getIndexes:(long *)indexes;
@end

@interface NSNumber : NSObject {
@public
    long long _ival;
    double _dval;
    int _kind; /* 0 int, 1 double, 2 bool */
}
+ (id)numberWithInt:(int)value;
+ (id)numberWithInteger:(long)value;
+ (id)numberWithLongLong:(long long)value;
+ (id)numberWithBool:(BOOL)value;
+ (id)numberWithFloat:(float)value;
+ (id)numberWithDouble:(double)value;
- (int)intValue;
- (long)integerValue;
- (long long)longLongValue;
- (BOOL)boolValue;
- (float)floatValue;
- (double)doubleValue;
- (id)stringValue;
@end

@interface NSSortDescriptor : NSObject {
@public
    id _key;
    BOOL _ascending;
    SEL _selector;
}
+ (id)sortDescriptorWithKey:(id)key ascending:(BOOL)ascending;
+ (id)sortDescriptorWithKey:(id)key ascending:(BOOL)ascending
                   selector:(SEL)selector;
- (id)initWithKey:(id)key ascending:(BOOL)ascending;
- (id)key;
- (BOOL)ascending;
- (SEL)selector;
- (long)compareObject:(id)first toObject:(id)second;
@end

@interface NSArray : NSObject <NSFastEnumeration> {
@public
    id *_items;
    unsigned long _count;
}
+ (id)array;
+ (id)arrayWithObjects:(id)first, ...;
+ (id)arrayWithObjects:(const id *)objects count:(unsigned long)count;
+ (id)arrayWithObject:(id)object;
+ (id)arrayWithArray:(id)array;
- (id)initWithObjects:(id)first, ...;
- (unsigned long)count;
- (id)objectAtIndex:(unsigned long)index;
- (id)firstObject;
- (id)lastObject;
- (BOOL)containsObject:(id)object;
- (unsigned long)indexOfObject:(id)object;
- (id)objectAtIndexedSubscript:(unsigned long)index;
- (unsigned long)countByEnumeratingWithState:(NSFastEnumerationState *)state
                                     objects:(id *)buffer
                                       count:(unsigned long)len;
- (id)sortedArrayUsingDescriptors:(id)descriptors;
- (id)sortedArrayUsingSelector:(SEL)selector;
- (id)filteredArrayUsingPredicate:(id)predicate;
@end

@interface NSMutableArray : NSArray
+ (id)array;
- (void)addObject:(id)object;
- (void)insertObject:(id)object atIndex:(unsigned long)index;
- (void)removeObjectAtIndex:(unsigned long)index;
- (void)removeAllObjects;
- (void)removeObject:(id)object;
- (void)setObject:(id)object atIndexedSubscript:(unsigned long)index;
- (void)sortUsingDescriptors:(id)descriptors;
- (void)sortUsingSelector:(SEL)selector;
- (void)filterUsingPredicate:(id)predicate;
- (void)exchangeObjectAtIndex:(unsigned long)first
        withObjectAtIndex:(unsigned long)second;
@end

@interface NSSet : NSObject <NSFastEnumeration> {
@public
    id *_items;
    unsigned long _count;
}
+ (id)set;
+ (id)setWithObject:(id)object;
+ (id)setWithObjects:(id)first, ...;
+ (id)setWithObjects:(const id *)objects count:(unsigned long)count;
+ (id)setWithArray:(id)array;
- (unsigned long)count;
- (id)anyObject;
- (id)allObjects;
- (BOOL)containsObject:(id)object;
- (id)member:(id)object;
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

@interface NSCountedSet : NSMutableSet {
@public
    unsigned long *_counts;
}
+ (id)countedSetWithArray:(id)array;
- (unsigned long)countForObject:(id)object;
@end

@interface NSOrderedSet : NSObject <NSFastEnumeration> {
@public
    id *_items;
    unsigned long _count;
}
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

@interface NSDictionary : NSObject <NSFastEnumeration> {
@public
    id *_keys;
    id *_values;
    unsigned long _count;
}
+ (id)dictionary;
+ (id)dictionaryWithObject:(id)object forKey:(id)key;
+ (id)dictionaryWithObjects:(id)firstObject forKeys:(id)firstKey, ...;
+ (id)dictionaryWithObjectsAndKeys:(id)firstObject, ...;
+ (id)dictionaryWithObjects:(const id *)objects
                    forKeys:(const id *)keys
                      count:(unsigned long)count;
- (unsigned long)count;
- (id)objectForKey:(id)key;
- (id)allKeys;
- (id)allValues;
- (id)objectForKeyedSubscript:(id)key;
- (unsigned long)countByEnumeratingWithState:(NSFastEnumerationState *)state
                                     objects:(id *)buffer
                                       count:(unsigned long)len;
@end

@interface NSMutableDictionary : NSDictionary
+ (id)dictionary;
- (void)setObject:(id)object forKey:(id)key;
- (void)removeObjectForKey:(id)key;
- (void)removeAllObjects;
- (void)setObject:(id)object forKeyedSubscript:(id)key;
@end

@interface NSBundle : NSObject {
@public
    id _infoDictionary;
}
+ (NSBundle *)mainBundle;
- (id)resourcePath;
- (id)bundlePath;
- (id)infoDictionary;
- (id)bundleIdentifier;
- (id)pathForResource:(id)name ofType:(id)type;
@end

@protocol NSCacheDelegate
@optional
- (void)cache:(id)cache willEvictObject:(id)obj;
@end

@interface NSCache : NSObject {
@public
    id _objects;
    id _costs;
    id _order;
    unsigned long _countLimit;
    unsigned long _totalCostLimit;
    unsigned long _totalCost;
    id _delegate;
    id _name;
}
@property unsigned long countLimit;
@property unsigned long totalCostLimit;
@property(assign) id delegate;
@property(retain) id name;
- (id)objectForKey:(id)key;
- (void)setObject:(id)object forKey:(id)key;
- (void)setObject:(id)object forKey:(id)key cost:(unsigned long)cost;
- (void)removeObjectForKey:(id)key;
- (void)removeAllObjects;
@end

@interface NSUserDefaults : NSObject {
@public
    id _store;
}
+ (NSUserDefaults *)standardUserDefaults;
- (void)setObject:(id)value forKey:(id)key;
- (id)objectForKey:(id)key;
- (void)removeObjectForKey:(id)key;
- (id)stringForKey:(id)key;
- (BOOL)boolForKey:(id)key;
- (long)integerForKey:(id)key;
- (void)synchronize;
@end

/* XML property lists (the format cfprefsd writes on the simulator). */
#define NSPropertyListXMLFormat_v1_0 100UL
#define NSPropertyListBinaryFormat_v1_0 200UL

@interface NSPropertyListSerialization : NSObject
+ (id)dataWithPropertyList:(id)plist format:(unsigned long)format
                   options:(unsigned long)options error:(id *)error;
+ (id)propertyListWithData:(id)data options:(unsigned long)options
                    format:(unsigned long *)format error:(id *)error;
@end

@interface NSValue : NSObject {
@public
    unsigned char _storage[64];
    unsigned long _size;
    char _type[16];
}
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

@interface NSIndexSet : NSObject {
@public
    unsigned long *_indexes;
    unsigned long _count;
    unsigned long _capacity;
}
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

@interface NSData : NSObject {
@public
    void *_bytes;
    unsigned long _length;
}
+ (id)dataWithBytes:(const void *)bytes length:(unsigned long)length;
+ (id)data;
+ (id)dataWithContentsOfFile:(id)path;
+ (id)dataWithContentsOfURL:(id)url;
- (id)initWithBytes:(const void *)bytes length:(unsigned long)length;
- (id)initWithContentsOfFile:(id)path;
- (const void *)bytes;
- (unsigned long)length;
- (BOOL)writeToFile:(id)path atomically:(BOOL)atomically;
- (BOOL)writeToURL:(id)url atomically:(BOOL)atomically;
- (id)subdataWithRange:(NSRange)range;
- (BOOL)isEqualToData:(id)other;
- (id)base64EncodedStringWithOptions:(unsigned long)options;
- (id)initWithBase64EncodedString:(id)string options:(unsigned long)options;
@end

@interface NSMutableData : NSData {
@public
    unsigned long _capacity;
}
+ (id)dataWithCapacity:(unsigned long)capacity;
- (id)initWithCapacity:(unsigned long)capacity;
- (void)appendBytes:(const void *)bytes length:(unsigned long)length;
- (void)appendData:(id)data;
- (void *)mutableBytes;
- (void)setLength:(unsigned long)length;
@end

enum {
    NSStreamStatusNotOpen = 0,
    NSStreamStatusOpening = 1,
    NSStreamStatusOpen = 2,
    NSStreamStatusReading = 3,
    NSStreamStatusWriting = 4,
    NSStreamStatusAtEnd = 5,
    NSStreamStatusClosed = 6,
    NSStreamStatusError = 7
};

extern id NSStreamDataWrittenToMemoryStreamKey;

@interface NSStream : NSObject {
@public
    long _status;
    id _streamError;
    id _properties;
}
- (void)open;
- (void)close;
- (long)streamStatus;
- (id)streamError;
- (id)propertyForKey:(id)key;
- (BOOL)setProperty:(id)property forKey:(id)key;
@end

@interface NSInputStream : NSStream {
@public
    id _streamData;
    unsigned long _streamOffset;
}
+ (id)inputStreamWithData:(id)data;
+ (id)inputStreamWithFileAtPath:(id)path;
- (long)read:(unsigned char *)buffer maxLength:(unsigned long)length;
- (BOOL)hasBytesAvailable;
@end

@interface NSOutputStream : NSStream {
@public
    id _streamData;
    id _streamPath;
    BOOL _streamAppend;
    BOOL _streamMemory;
}
+ (id)outputStreamToMemory;
+ (id)outputStreamToFileAtPath:(id)path append:(BOOL)append;
- (long)write:(const unsigned char *)buffer maxLength:(unsigned long)length;
- (BOOL)hasSpaceAvailable;
@end

@interface NSFileHandle : NSObject {
@public
    int _fd;
    BOOL _closed;
}
+ (id)fileHandleForReadingAtPath:(NSString *)path;
+ (id)fileHandleForWritingAtPath:(NSString *)path;
+ (id)fileHandleForUpdatingAtPath:(NSString *)path;
+ (id)fileHandleWithStandardInput;
+ (id)fileHandleWithStandardOutput;
+ (id)fileHandleWithStandardError;
+ (id)fileHandleWithNullDevice;
- (NSData *)readDataToEndOfFile;
- (NSData *)readDataOfLength:(unsigned long)length;
- (void)writeData:(NSData *)data;
- (unsigned long long)offsetInFile;
- (unsigned long long)seekToEndOfFile;
- (void)seekToFileOffset:(unsigned long long)offset;
- (void)truncateFileAtOffset:(unsigned long long)offset;
- (void)synchronizeFile;
- (int)fileDescriptor;
- (void)closeFile;
@end

@interface NSProgress : NSObject {
@public
    long long _totalUnitCount;
    long long _completedUnitCount;
    BOOL _cancelled;
    BOOL _paused;
    id _kind;
    id _localizedDescription;
    id _cancellationHandler;
    id _pausingHandler;
    id _resumingHandler;
    id _userInfo;
}
+ (NSProgress *)progressWithTotalUnitCount:(long long)total;
+ (NSProgress *)discreteProgressWithTotalUnitCount:(long long)total;
+ (NSProgress *)progressWithTotalUnitCount:(long long)total
                                    parent:(NSProgress *)parent
                          pendingUnitCount:(long long)pending;
- (long long)totalUnitCount;
- (void)setTotalUnitCount:(long long)total;
- (long long)completedUnitCount;
- (void)setCompletedUnitCount:(long long)completed;
- (double)fractionCompleted;
- (BOOL)isCancelled;
- (BOOL)isPaused;
- (id)kind;
- (void)setKind:(id)kind;
- (id)localizedDescription;
- (void)setLocalizedDescription:(id)description;
- (void (^)(void))cancellationHandler;
- (void)setCancellationHandler:(void (^)(void))handler;
- (void (^)(void))pausingHandler;
- (void)setPausingHandler:(void (^)(void))handler;
- (void (^)(void))resumingHandler;
- (void)setResumingHandler:(void (^)(void))handler;
- (void)becomeCurrentWithPendingUnitCount:(long long)unitCount;
- (void)resignCurrent;
- (void)addChild:(NSProgress *)child withPendingUnitCount:(long long)unitCount;
- (void)cancel;
- (void)pause;
- (void)resume;
- (void)publish;
- (void)unpublish;
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

@interface NSUUID : NSObject {
@public
    unsigned char _bytes[16];
}
+ (id)UUID;
- (id)initWithUUIDString:(id)string;
- (id)UUIDString;
@end

@interface NSURL : NSObject {
@public
    id _string;
    id _path;
    id _scheme;
    id _host;
    id _query;
    int _port;
    BOOL _fileURL;
}
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
- (id)lastPathComponent;
- (id)pathExtension;
- (id)URLByAppendingPathComponent:(id)component;
- (id)URLByAppendingPathComponent:(id)component isDirectory:(BOOL)isDirectory;
- (id)URLByDeletingLastPathComponent;
- (id)URLByAppendingPathExtension:(id)extension;
- (id)URLByDeletingPathExtension;
- (id)URLByStandardizingPath;
- (id)URLByResolvingSymlinksInPath;
- (NSArray *)pathComponents;
@end

#ifdef __BLOCKS__
typedef void (^NSURLSessionCompletionHandler)(id data, id response,
                                              id error);
typedef void (^NSURLSessionDownloadCompletionHandler)(id location,
                                                      id response,
                                                      id error);
#else
typedef void *NSURLSessionCompletionHandler;
typedef void *NSURLSessionDownloadCompletionHandler;
#endif

@interface NSURLSessionConfiguration : NSObject {
@public
    double _timeoutIntervalForRequest;
    id _HTTPAdditionalHeaders;
    BOOL _waitsForConnectivity;
}
+ (id)defaultSessionConfiguration;
+ (id)ephemeralSessionConfiguration;
- (double)timeoutIntervalForRequest;
- (void)setTimeoutIntervalForRequest:(double)interval;
- (id)HTTPAdditionalHeaders;
- (void)setHTTPAdditionalHeaders:(id)headers;
- (BOOL)waitsForConnectivity;
- (void)setWaitsForConnectivity:(BOOL)waits;
@end

@protocol NSURLSessionDelegate
@optional
- (void)URLSession:(id)session didBecomeInvalidWithError:(id)error;
@end

@protocol NSURLSessionTaskDelegate <NSURLSessionDelegate>
@optional
- (void)URLSession:(id)session task:(id)task
    didCompleteWithError:(id)error;
#ifdef __BLOCKS__
- (void)URLSession:(id)session task:(id)task
    willPerformHTTPRedirection:(id)response
                    newRequest:(id)request
             completionHandler:(void (^)(id request))completionHandler;
#endif
@end

@protocol NSURLSessionDataDelegate <NSURLSessionTaskDelegate>
@optional
- (void)URLSession:(id)session dataTask:(id)task didReceiveData:(id)data;
@end

@protocol NSURLSessionDownloadDelegate <NSURLSessionTaskDelegate>
@optional
- (void)URLSession:(id)session downloadTask:(id)task
    didFinishDownloadingToURL:(id)location;
- (void)URLSession:(id)session downloadTask:(id)task didWriteData:(long long)
    bytesWritten totalBytesWritten:(long long)totalBytesWritten
    totalBytesExpectedToWrite:(long long)totalBytesExpectedToWrite;
@end

@interface NSURLQueryItem : NSObject {
@public
    id _name;
    id _value;
}
+ (id)queryItemWithName:(id)name value:(id)value;
- (id)initWithName:(id)name value:(id)value;
- (id)name;
- (id)value;
@end

@interface NSURLComponents : NSObject {
@public
    id _scheme;
    id _host;
    id _path;
    id _query;
    id _fragment;
    int _port;
}
+ (id)componentsWithString:(id)string;
+ (id)componentsWithURL:(id)url resolvingAgainstBaseURL:(BOOL)resolve;
- (id)string;
- (NSURL *)URL;
- (id)scheme;
- (void)setScheme:(id)scheme;
- (id)host;
- (void)setHost:(id)host;
- (id)path;
- (void)setPath:(id)path;
- (id)query;
- (void)setQuery:(id)query;
- (NSArray *)queryItems;
- (void)setQueryItems:(NSArray *)items;
- (id)percentEncodedQuery;
- (void)setPercentEncodedQuery:(id)query;
- (id)percentEncodedPath;
- (void)setPercentEncodedPath:(id)path;
- (id)fragment;
- (void)setFragment:(id)fragment;
- (int)port;
- (void)setPort:(int)port;
@end

extern id NSHTTPCookieName;
extern id NSHTTPCookieValue;
extern id NSHTTPCookieDomain;
extern id NSHTTPCookiePath;
extern id NSHTTPCookieSecure;
extern id NSHTTPCookieExpires;
extern id NSHTTPCookieHTTPOnly;

@interface NSHTTPCookie : NSObject {
@public
    id _name;
    id _value;
    id _domain;
    id _path;
    id _expiresDate;
    id _properties;
    BOOL _secure;
    BOOL _httpOnly;
}
+ (id)cookieWithProperties:(NSDictionary *)properties;
- (id)initWithProperties:(NSDictionary *)properties;
- (id)name;
- (id)value;
- (id)domain;
- (id)path;
- (id)expiresDate;
- (BOOL)isSecure;
- (BOOL)isHTTPOnly;
- (NSDictionary *)properties;
+ (NSDictionary *)requestHeaderFieldsWithCookies:(NSArray *)cookies;
+ (NSArray *)cookiesWithResponseHeaderFields:(NSDictionary *)headerFields
                                      forURL:(NSURL *)URL;
@end

@interface NSHTTPCookieStorage : NSObject {
@public
    NSMutableArray *_cookies;
}
+ (id)sharedHTTPCookieStorage;
- (NSArray *)cookies;
- (void)setCookie:(NSHTTPCookie *)cookie;
- (void)deleteCookie:(NSHTTPCookie *)cookie;
- (NSArray *)cookiesForURL:(NSURL *)URL;
@end

enum {
    NSURLRequestUseProtocolCachePolicy = 0,
    NSURLRequestReloadIgnoringLocalCacheData = 1,
    NSURLRequestReturnCacheDataElseLoad = 2,
    NSURLRequestReturnCacheDataDontLoad = 3
};

enum {
    NSURLCacheStorageAllowed = 0,
    NSURLCacheStorageAllowedInMemoryOnly = 1,
    NSURLCacheStorageNotAllowed = 2
};

@interface NSCachedURLResponse : NSObject {
@public
    id _response;
    id _data;
    id _userInfo;
    long _storagePolicy;
}
- (id)initWithResponse:(id)response data:(id)data;
- (id)initWithResponse:(id)response data:(id)data userInfo:(id)userInfo
         storagePolicy:(long)storagePolicy;
- (id)response;
- (id)data;
- (id)userInfo;
- (long)storagePolicy;
@end

@interface NSURLCache : NSObject {
@public
    unsigned long _memoryCapacity;
    unsigned long _diskCapacity;
    id _storage;
}
+ (id)sharedURLCache;
- (id)initWithMemoryCapacity:(unsigned long)memoryCapacity
                diskCapacity:(unsigned long)diskCapacity
                    diskPath:(id)diskPath;
- (id)cachedResponseForRequest:(id)request;
- (void)storeCachedResponse:(NSCachedURLResponse *)cachedResponse
                 forRequest:(id)request;
- (void)removeCachedResponseForRequest:(id)request;
- (void)removeAllCachedResponses;
- (unsigned long)memoryCapacity;
- (unsigned long)diskCapacity;
@end

@interface NSURLRequest : NSObject {
@public
    id _URL;
    double _timeoutInterval;
    id _HTTPMethod;
    id _HTTPBody;
    id _allHTTPHeaderFields;
    long _cachePolicy;
}
+ (id)requestWithURL:(id)url;
- (id)URL;
- (void)setURL:(id)url;
- (double)timeoutInterval;
- (void)setTimeoutInterval:(double)timeout;
- (id)HTTPMethod;
- (void)setHTTPMethod:(id)method;
- (id)HTTPBody;
- (void)setHTTPBody:(id)body;
- (long)cachePolicy;
- (void)setCachePolicy:(long)policy;
- (id)allHTTPHeaderFields;
- (void)setAllHTTPHeaderFields:(id)fields;
- (id)valueForHTTPHeaderField:(id)field;
- (void)setValue:(id)value forHTTPHeaderField:(id)field;
- (void)addValue:(id)value forHTTPHeaderField:(id)field;
@end

@interface NSMutableURLRequest : NSURLRequest
@end

@interface NSURLResponse : NSObject {
@public
    id _URL;
    long _statusCode;
    id _allHeaderFields;
}
- (id)initWithURL:(id)url statusCode:(long)status headers:(id)headers;
- (id)URL;
- (long)statusCode;
- (id)allHeaderFields;
@end

@interface NSHTTPURLResponse : NSURLResponse
@end

@interface NSURLSessionDataTask : NSObject {
@public
    id _request;
    void *_completion;
    volatile int _canceled;
    int _resumed;
    void *_context;
    id _uploadData;
    int _download;
    id _session;
    unsigned long _identifier;
}
- (void)resume;
- (void)cancel;
- (unsigned long)taskIdentifier;
@end

@interface NSURLSessionUploadTask : NSURLSessionDataTask
@end

@interface NSURLSessionDownloadTask : NSURLSessionDataTask
@end

@interface NSURLSession : NSObject {
@public
    id _configuration;
    id _delegate;
    id _delegateQueue;
    int _invalid;
}
+ (id)sharedSession;
+ (id)sessionWithConfiguration:(id)configuration
                      delegate:(id)delegate
                 delegateQueue:(id)queue;
- (id)configuration;
- (id)delegate;
- (id)delegateQueue;
- (void)invalidateAndCancel;
- (void)finishTasksAndInvalidate;
- (NSURLSessionDataTask *)dataTaskWithURL:(id)url
                        completionHandler:(NSURLSessionCompletionHandler)handler;
- (NSURLSessionDataTask *)dataTaskWithRequest:(id)request
                            completionHandler:(NSURLSessionCompletionHandler)handler;
- (NSURLSessionUploadTask *)uploadTaskWithRequest:(id)request
                                         fromData:(id)body
                                completionHandler:(NSURLSessionCompletionHandler)handler;
- (NSURLSessionDownloadTask *)downloadTaskWithURL:(id)url
                                completionHandler:(NSURLSessionDownloadCompletionHandler)handler;
- (NSURLSessionDownloadTask *)downloadTaskWithRequest:(id)request
                                    completionHandler:(NSURLSessionDownloadCompletionHandler)handler;
@end

@interface NSFileManager : NSObject
+ (NSFileManager *)defaultManager;
- (BOOL)fileExistsAtPath:(id)path;
- (BOOL)fileExistsAtPath:(id)path isDirectory:(BOOL *)isDirectory;
- (BOOL)createDirectoryAtPath:(id)path
    withIntermediateDirectories:(BOOL)createIntermediates
                     attributes:(id)attributes error:(id *)error;
- (id)contentsOfDirectoryAtPath:(id)path error:(id *)error;
- (BOOL)removeItemAtPath:(id)path error:(id *)error;
- (BOOL)moveItemAtPath:(id)fromPath toPath:(id)toPath error:(id *)error;
- (BOOL)copyItemAtPath:(id)fromPath toPath:(id)toPath error:(id *)error;
- (id)contentsAtPath:(id)path;
- (BOOL)createFileAtPath:(id)path contents:(id)contents attributes:(id)attributes;
- (id)currentDirectoryPath;
@end

enum {
    NSJSONReadingMutableContainers = 1 << 0,
    NSJSONReadingMutableLeaves = 1 << 1,
    NSJSONReadingAllowFragments = 1 << 2,
    NSJSONWritingPrettyPrinted = 1 << 0,
    NSJSONWritingSortedKeys = 1 << 1
};

@interface NSJSONSerialization : NSObject
+ (BOOL)isValidJSONObject:(id)object;
+ (id)dataWithJSONObject:(id)object options:(unsigned long)options
                   error:(id *)error;
+ (id)JSONObjectWithData:(id)data options:(unsigned long)options
                   error:(id *)error;
@end

@interface NSNotification : NSObject {
@public
    id _name;
    id _object;
    id _userInfo;
}
+ (id)notificationWithName:(id)name object:(id)object;
+ (id)notificationWithName:(id)name object:(id)object userInfo:(id)userInfo;
- (id)name;
- (id)object;
- (id)userInfo;
@end

@interface NSNotificationCenter : NSObject {
@public
    id _observers[64];
    id _names[64];
    id _objects[64];
    SEL _selectors[64];
    int _count;
}
+ (id)defaultCenter;
- (void)addObserver:(id)observer selector:(SEL)selector
               name:(id)name object:(id)object;
- (id)addObserverForName:(id)name object:(id)object queue:(id)queue
              usingBlock:(void (^)(NSNotification *note))block;
- (void)removeObserver:(id)observer;
- (void)removeObserver:(id)observer name:(id)name object:(id)object;
- (void)postNotification:(NSNotification *)notification;
- (void)postNotificationName:(id)name object:(id)object;
- (void)postNotificationName:(id)name object:(id)object userInfo:(id)userInfo;
@end

@interface NSTimer : NSObject {
@public
    double _interval;
    id _target;
    SEL _selector;
    id _userInfo;
    BOOL _repeats;
    double _nextFire;
    BOOL _valid;
    id _performArgument;
    BOOL _isPerform;
}
+ (id)scheduledTimerWithTimeInterval:(double)interval target:(id)target
    selector:(SEL)selector userInfo:(id)userInfo repeats:(BOOL)repeats;
- (void)invalidate;
- (void)fire;
@end

@class NSDate;

extern id NSDefaultRunLoopMode;

@interface NSRunLoop : NSObject
+ (NSRunLoop *)currentRunLoop;
+ (NSRunLoop *)mainRunLoop;
- (void)addTimer:(NSTimer *)timer forMode:(id)mode;
- (BOOL)runMode:(id)mode beforeDate:(NSDate *)limitDate;
- (void)runUntilDate:(NSDate *)limitDate;
- (void)run;
@end

@interface NSThread : NSObject {
@public
    id _target;
    SEL _selector;
    id _argument;
    unsigned long _thread;
    int _started;
    int _executing;
    int _finished;
    int _cancelled;
    int _isMain;
    id _name;
    double _priority;
}
+ (NSThread *)currentThread;
+ (NSThread *)mainThread;
+ (BOOL)isMainThread;
+ (void)sleepForTimeInterval:(double)interval;
+ (void)detachNewThreadSelector:(SEL)selector
                       toTarget:(id)target
                     withObject:(id)argument;
- (id)initWithTarget:(id)target selector:(SEL)selector object:(id)argument;
- (void)start;
- (void)main;
- (void)cancel;
- (BOOL)isExecuting;
- (BOOL)isFinished;
- (BOOL)isCancelled;
- (BOOL)isMainThread;
- (id)name;
- (void)setName:(id)name;
- (double)threadPriority;
- (void)setThreadPriority:(double)priority;
@end

@protocol NSLocking
- (void)lock;
- (void)unlock;
@end

@interface NSLock : NSObject <NSLocking> {
@public
    unsigned char _mutex[64];
    id _name;
}
- (BOOL)tryLock;
- (BOOL)lockBeforeDate:(NSDate *)limit;
- (id)name;
- (void)setName:(id)name;
@end

@interface NSRecursiveLock : NSObject <NSLocking> {
@public
    unsigned char _mutex[64];
    id _name;
}
- (BOOL)tryLock;
- (BOOL)lockBeforeDate:(NSDate *)limit;
- (id)name;
- (void)setName:(id)name;
@end

@interface NSCondition : NSObject <NSLocking> {
@public
    unsigned char _mutex[64];
    unsigned char _cond[48];
    id _name;
}
- (void)wait;
- (BOOL)waitUntilDate:(NSDate *)limit;
- (void)signal;
- (void)broadcast;
- (id)name;
- (void)setName:(id)name;
@end

@interface NSConditionLock : NSObject <NSLocking> {
@public
    NSCondition *_condition;
    long _conditionValue;
}
- (id)initWithCondition:(long)condition;
- (long)condition;
- (BOOL)tryLock;
- (BOOL)tryLockWhenCondition:(long)condition;
- (void)lockWhenCondition:(long)condition;
- (void)unlockWithCondition:(long)condition;
- (BOOL)lockBeforeDate:(NSDate *)limit;
- (BOOL)lockWhenCondition:(long)condition beforeDate:(NSDate *)limit;
@end

@interface NSOperation : NSObject {
@public
    BOOL _cancelled;
    BOOL _finished;
    BOOL _executing;
    BOOL _dispatched;
    long _priority;
    id _completionBlock;
    id _dependencies;
    id _name;
}
- (void)start;
- (void)main;
- (void)cancel;
- (void)waitUntilFinished;
- (BOOL)isCancelled;
- (BOOL)isFinished;
- (BOOL)isExecuting;
- (BOOL)isReady;
- (long)queuePriority;
- (void)setQueuePriority:(long)priority;
- (void)addDependency:(NSOperation *)operation;
- (void)removeDependency:(NSOperation *)operation;
- (NSArray *)dependencies;
- (id)name;
- (void)setName:(id)name;
- (void)setCompletionBlock:(void (^)(void))block;
@end

@interface NSBlockOperation : NSOperation {
@public
    id _blocks;
}
+ (id)blockOperationWithBlock:(void (^)(void))block;
- (void)addExecutionBlock:(void (^)(void))block;
@end

@interface NSOperationQueue : NSObject {
@public
    id _group;
    id _queue;
    id _operations;
    long _running;
    long _maxConcurrent;
    BOOL _suspended;
}
+ (NSOperationQueue *)mainQueue;
- (id)init;
- (void)addOperation:(NSOperation *)operation;
- (void)addOperationWithBlock:(void (^)(void))block;
- (void)waitUntilAllOperationsAreFinished;
- (long)operationCount;
- (NSArray *)operations;
- (void)setMaxConcurrentOperationCount:(long)count;
- (long)maxConcurrentOperationCount;
- (void)setSuspended:(BOOL)suspended;
- (BOOL)isSuspended;
- (void)cancelAllOperations;
@end

@interface NSDate : NSObject {
@public
    double _timeIntervalSince1970;
}
+ (id)date;
+ (id)dateWithTimeIntervalSince1970:(double)interval;
+ (id)dateWithTimeIntervalSinceNow:(double)interval;
- (id)initWithTimeIntervalSince1970:(double)interval;
- (double)timeIntervalSince1970;
- (double)timeIntervalSinceNow;
- (double)timeIntervalSinceDate:(NSDate *)date;
@end

@interface NSDateFormatter : NSObject {
@public
    id _dateFormat;
}
- (void)setDateFormat:(id)format;
- (id)dateFormat;
- (id)stringFromDate:(NSDate *)date;
- (NSDate *)dateFromString:(id)string;
@end

@interface NSISO8601DateFormatter : NSObject {
@public
    unsigned long _formatOptions;
    id _timeZone;
}
- (unsigned long)formatOptions;
- (void)setFormatOptions:(unsigned long)options;
- (id)timeZone;
- (void)setTimeZone:(id)zone;
- (id)stringFromDate:(NSDate *)date;
- (NSDate *)dateFromString:(id)string;
@end

enum {
    NSNumberFormatterNoStyle = 0,
    NSNumberFormatterDecimalStyle = 1,
    NSNumberFormatterCurrencyStyle = 2,
    NSNumberFormatterPercentStyle = 3
};

@interface NSNumberFormatter : NSObject {
@public
    long _numberStyle;
    long _maximumFractionDigits;
    long _minimumFractionDigits;
    BOOL _usesGroupingSeparator;
    id _currencySymbol;
    id _decimalSeparator;
    id _groupingSeparator;
}
- (void)setNumberStyle:(long)style;
- (long)numberStyle;
- (void)setMaximumFractionDigits:(long)digits;
- (long)maximumFractionDigits;
- (void)setMinimumFractionDigits:(long)digits;
- (long)minimumFractionDigits;
- (void)setUsesGroupingSeparator:(BOOL)uses;
- (BOOL)usesGroupingSeparator;
- (void)setCurrencySymbol:(id)symbol;
- (id)currencySymbol;
- (id)stringFromNumber:(NSNumber *)number;
- (NSNumber *)numberFromString:(NSString *)string;
@end

enum {
    NSCalendarUnitEra = 1 << 1,
    NSCalendarUnitYear = 1 << 2,
    NSCalendarUnitMonth = 1 << 3,
    NSCalendarUnitDay = 1 << 4,
    NSCalendarUnitHour = 1 << 5,
    NSCalendarUnitMinute = 1 << 6,
    NSCalendarUnitSecond = 1 << 7,
    NSCalendarUnitWeekday = 1 << 9,
    NSCalendarUnitWeekOfYear = 1 << 13,
    NSCalendarUnitYearForWeekOfYear = 1 << 14,
    NSCalendarUnitNanosecond = 1 << 15
};

extern id NSCalendarIdentifierGregorian;

@interface NSDateComponents : NSObject {
@public
    long _era;
    long _year;
    long _month;
    long _day;
    long _hour;
    long _minute;
    long _second;
    long _nanosecond;
    long _weekday;
    long _weekOfYear;
}
- (long)era;
- (void)setEra:(long)value;
- (long)year;
- (void)setYear:(long)value;
- (long)month;
- (void)setMonth:(long)value;
- (long)day;
- (void)setDay:(long)value;
- (long)hour;
- (void)setHour:(long)value;
- (long)minute;
- (void)setMinute:(long)value;
- (long)second;
- (void)setSecond:(long)value;
- (long)nanosecond;
- (void)setNanosecond:(long)value;
- (long)weekday;
- (void)setWeekday:(long)value;
- (long)weekOfYear;
- (void)setWeekOfYear:(long)value;
@end

@interface NSCalendar : NSObject {
@public
    id _identifier;
}
+ (NSCalendar *)currentCalendar;
+ (NSCalendar *)calendarWithIdentifier:(id)identifier;
- (id)initWithCalendarIdentifier:(id)identifier;
- (id)calendarIdentifier;
- (NSDateComponents *)components:(unsigned long)unitFlags
                        fromDate:(NSDate *)date;
- (NSDate *)dateFromComponents:(NSDateComponents *)components;
@end

enum {
    NSByteCountFormatterCountStyleFile = 0,
    NSByteCountFormatterCountStyleMemory = 1,
    NSByteCountFormatterCountStyleDecimal = 2,
    NSByteCountFormatterCountStyleBinary = 3
};

enum {
    NSByteCountFormatterUseDefault = 0,
    NSByteCountFormatterUseBytes = 1UL << 0,
    NSByteCountFormatterUseKB = 1UL << 1,
    NSByteCountFormatterUseMB = 1UL << 2,
    NSByteCountFormatterUseGB = 1UL << 3,
    NSByteCountFormatterUseTB = 1UL << 4,
    NSByteCountFormatterUsePB = 1UL << 5,
    NSByteCountFormatterUseEB = 1UL << 6,
    NSByteCountFormatterUseAll = 0xFFFFUL
};

@interface NSByteCountFormatter : NSObject {
@public
    long _countStyle;
    unsigned long _allowedUnits;
    BOOL _includesUnit;
    BOOL _includesCount;
    BOOL _includesActualByteCount;
    BOOL _adaptive;
    BOOL _allowsNonnumericFormatting;
    BOOL _zeroPadsFractionDigits;
    long _formattingContext;
}
+ (id)stringFromByteCount:(long long)byteCount countStyle:(long)countStyle;
- (id)stringFromByteCount:(long long)byteCount;
- (long)countStyle;
- (void)setCountStyle:(long)style;
- (unsigned long)allowedUnits;
- (void)setAllowedUnits:(unsigned long)units;
- (BOOL)includesUnit;
- (void)setIncludesUnit:(BOOL)includes;
- (BOOL)includesCount;
- (void)setIncludesCount:(BOOL)includes;
- (BOOL)includesActualByteCount;
- (void)setIncludesActualByteCount:(BOOL)includes;
- (BOOL)isAdaptive;
- (void)setAdaptive:(BOOL)adaptive;
- (BOOL)allowsNonnumericFormatting;
- (void)setAllowsNonnumericFormatting:(BOOL)allows;
- (BOOL)zeroPadsFractionDigits;
- (void)setZeroPadsFractionDigits:(BOOL)pads;
- (long)formattingContext;
- (void)setFormattingContext:(long)context;
@end

enum {
    NSDateComponentsFormatterUnitsStylePositional = 0,
    NSDateComponentsFormatterUnitsStyleAbbreviated = 1,
    NSDateComponentsFormatterUnitsStyleShort = 2,
    NSDateComponentsFormatterUnitsStyleFull = 3,
    NSDateComponentsFormatterUnitsStyleSpellOut = 4
};

enum {
    NSDateComponentsFormatterZeroFormattingBehaviorNone = 0,
    NSDateComponentsFormatterZeroFormattingBehaviorDefault = 1 << 0,
    NSDateComponentsFormatterZeroFormattingBehaviorDropLeading = 1 << 1,
    NSDateComponentsFormatterZeroFormattingBehaviorDropMiddle = 1 << 2,
    NSDateComponentsFormatterZeroFormattingBehaviorDropTrailing = 1 << 3,
    NSDateComponentsFormatterZeroFormattingBehaviorDropAll =
        (1 << 1) | (1 << 2) | (1 << 3),
    NSDateComponentsFormatterZeroFormattingBehaviorPad = 1 << 16
};

@interface NSDateComponentsFormatter : NSObject {
@public
    long _unitsStyle;
    unsigned long _allowedUnits;
    long _maximumUnitCount;
    long _zeroFormattingBehavior;
    BOOL _includesApproximationPhrase;
    BOOL _includesTimeRemainingPhrase;
    BOOL _allowsFractionalUnits;
    BOOL _collapsesLargestUnit;
    long _formattingContext;
    id _calendar;
}
+ (id)stringFromTimeInterval:(double)interval;
- (id)stringFromTimeInterval:(double)interval;
- (id)stringFromDateComponents:(NSDateComponents *)components;
- (id)stringFromDate:(NSDate *)startDate toDate:(NSDate *)endDate;
- (long)unitsStyle;
- (void)setUnitsStyle:(long)style;
- (unsigned long)allowedUnits;
- (void)setAllowedUnits:(unsigned long)units;
- (long)maximumUnitCount;
- (void)setMaximumUnitCount:(long)count;
- (long)zeroFormattingBehavior;
- (void)setZeroFormattingBehavior:(long)behavior;
- (BOOL)includesApproximationPhrase;
- (void)setIncludesApproximationPhrase:(BOOL)includes;
- (BOOL)includesTimeRemainingPhrase;
- (void)setIncludesTimeRemainingPhrase:(BOOL)includes;
- (BOOL)allowsFractionalUnits;
- (void)setAllowsFractionalUnits:(BOOL)allows;
- (BOOL)collapsesLargestUnit;
- (void)setCollapsesLargestUnit:(BOOL)collapses;
- (long)formattingContext;
- (void)setFormattingContext:(long)context;
- (NSCalendar *)calendar;
- (void)setCalendar:(NSCalendar *)calendar;
@end

@interface NSUnit : NSObject {
@public
    id _symbol;
    id _name;
    id _pluralName;
}
- (id)symbol;
@end

@interface NSDimension : NSUnit {
@public
    double _coefficient;
    double _offset;
    int _family;
}
+ (id)baseUnit;
@end

@interface NSUnitLength : NSDimension
+ (id)meters;
+ (id)kilometers;
+ (id)centimeters;
+ (id)millimeters;
+ (id)miles;
+ (id)yards;
+ (id)feet;
+ (id)inches;
+ (id)nauticalMiles;
+ (NSArray *)iosimUnits;
@end

@interface NSUnitMass : NSDimension
+ (id)kilograms;
+ (id)grams;
+ (id)milligrams;
+ (id)pounds;
+ (id)ounces;
+ (id)stones;
+ (id)metricTons;
+ (NSArray *)iosimUnits;
@end

@interface NSUnitTemperature : NSDimension
+ (id)kelvin;
+ (id)celsius;
+ (id)fahrenheit;
+ (NSArray *)iosimUnits;
@end

@interface NSUnitDuration : NSDimension
+ (id)seconds;
+ (id)milliseconds;
+ (id)minutes;
+ (id)hours;
+ (id)days;
+ (NSArray *)iosimUnits;
@end

@interface NSUnitSpeed : NSDimension
+ (id)metersPerSecond;
+ (id)kilometersPerHour;
+ (id)milesPerHour;
+ (id)knots;
+ (NSArray *)iosimUnits;
@end

@interface NSUnitVolume : NSDimension
+ (id)liters;
+ (id)milliliters;
+ (id)gallons;
+ (id)quarts;
+ (id)pints;
+ (id)cups;
+ (id)fluidOunces;
+ (NSArray *)iosimUnits;
@end

@interface NSMeasurement : NSObject {
@public
    double _doubleValue;
    NSUnit *_unit;
}
- (id)initWithDoubleValue:(double)value unit:(NSUnit *)unit;
- (double)doubleValue;
- (NSUnit *)unit;
- (NSMeasurement *)measurementByConvertingToUnit:(NSUnit *)unit;
- (BOOL)isEqualToMeasurement:(NSMeasurement *)other;
- (NSMeasurement *)measurementByAddingMeasurement:(NSMeasurement *)other;
- (NSMeasurement *)measurementBySubtractingMeasurement:(NSMeasurement *)other;
@end

enum {
    NSFormattingUnitStyleShort = 1,
    NSFormattingUnitStyleMedium = 2,
    NSFormattingUnitStyleLong = 3
};

enum {
    NSMeasurementFormatterUnitOptionsProvidedUnit = 1UL << 0,
    NSMeasurementFormatterUnitOptionsNaturalScale = 1UL << 1,
    NSMeasurementFormatterUnitOptionsTemperatureWithoutUnit = 1UL << 2
};

@interface NSMeasurementFormatter : NSObject {
@public
    long _unitStyle;
    unsigned long _unitOptions;
    id _numberFormatter;
}
- (long)unitStyle;
- (void)setUnitStyle:(long)style;
- (unsigned long)unitOptions;
- (void)setUnitOptions:(unsigned long)options;
- (NSNumberFormatter *)numberFormatter;
- (void)setNumberFormatter:(NSNumberFormatter *)formatter;
- (NSString *)stringFromMeasurement:(NSMeasurement *)measurement;
- (NSString *)stringFromUnit:(NSUnit *)unit;
@end

@interface NSError : NSObject {
@public
    id _domain;
    long _code;
    id _userInfo;
}
+ (id)errorWithDomain:(id)domain code:(long)code userInfo:(id)userInfo;
- (id)domain;
- (long)code;
- (id)userInfo;
- (id)localizedDescription;
@end

@interface NSNull : NSObject
+ (id)null;
@end

/* Keyed archiving. The archive is an XML property list shaped like
 * Foundation's: $archiver, $version, $top and a $objects table of values,
 * class descriptions and object dictionaries that refer to each other by
 * CF$UID entries. Custom classes take part by implementing NSCoding. */

@class NSCoder;

@protocol NSCoding
- (void)encodeWithCoder:(NSCoder *)coder;
- (id)initWithCoder:(NSCoder *)coder;
@end

@protocol NSSecureCoding <NSCoding>
+ (BOOL)supportsSecureCoding;
@end

@interface NSCoder : NSObject
- (void)encodeObject:(id)object forKey:(id)key;
- (void)encodeInteger:(long)value forKey:(id)key;
- (void)encodeInt:(int)value forKey:(id)key;
- (void)encodeBool:(BOOL)value forKey:(id)key;
- (void)encodeFloat:(float)value forKey:(id)key;
- (void)encodeDouble:(double)value forKey:(id)key;
- (BOOL)containsValueForKey:(id)key;
- (id)decodeObjectForKey:(id)key;
- (long)decodeIntegerForKey:(id)key;
- (int)decodeIntForKey:(id)key;
- (BOOL)decodeBoolForKey:(id)key;
- (float)decodeFloatForKey:(id)key;
- (double)decodeDoubleForKey:(id)key;
@end

@interface NSKeyedArchiver : NSCoder {
@public
    id _objects;
    id _top;
    id _current;
    id _out;
    id _classMap;
}
+ (id)archivedDataWithRootObject:(id)rootObject;
+ (id)archivedDataWithRootObject:(id)rootObject
             requiringSecureCoding:(BOOL)requiringSecureCoding
                             error:(id *)error;
+ (BOOL)archiveRootObject:(id)rootObject toFile:(id)path;
- (id)initForWritingWithMutableData:(id)data;
- (void)finishEncoding;
@end

@interface NSKeyedUnarchiver : NSCoder {
@public
    id _objects;
    id _top;
    id _current;
    id *_resolved;
    unsigned char *_state;
    unsigned long _objectCount;
}
+ (id)unarchiveObjectWithData:(id)data;
+ (id)unarchiveObjectWithFile:(id)path;
+ (id)unarchivedObjectOfClass:(Class)cls fromData:(id)data
                        error:(id *)error;
- (id)initForReadingWithData:(id)data;
- (void)finishDecoding;
@end

@interface NSTimeZone : NSObject {
@public
    id _name;
    long _secondsFromGMT;
}
+ (id)systemTimeZone;
+ (id)localTimeZone;
+ (id)timeZoneWithName:(id)name;
+ (id)timeZoneForSecondsFromGMT:(long)seconds;
+ (id)knownTimeZoneNames;
- (id)name;
- (long)secondsFromGMT;
- (BOOL)isDaylightSavingTime;
@end

@interface NSLocale : NSObject {
@public
    id _identifier;
}
+ (id)currentLocale;
+ (id)localeWithLocaleIdentifier:(id)identifier;
- (id)localeIdentifier;
- (id)languageCode;
- (id)countryCode;
- (id)objectForKey:(id)key;
@end

extern id NSLocaleIdentifier;
extern id NSLocaleLanguageCode;
extern id NSLocaleCountryCode;

void NSLog(id format, ...);

const char *iosim_string_cstr(id string);
int iosim_foundation_tick(void);

#endif
