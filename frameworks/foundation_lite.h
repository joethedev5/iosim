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

@interface NSString : NSObject {
@public
    char *_cstr;
    unsigned long _length;
}
+ (id)stringWithUTF8String:(const char *)s;
+ (id)stringWithFormat:(id)format, ...;
+ (id)stringWithString:(id)other;
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
}
- (id)initWithString:(id)string;
- (id)initWithString:(id)string attributes:(id)attributes;
- (id)string;
- (unsigned long)length;
- (id)attributesAtIndex:(unsigned long)index
         effectiveRange:(NSRange *)range;
@end

@interface NSMutableAttributedString : NSAttributedString
- (id)initWithString:(id)string;
- (void)addAttribute:(id)name value:(id)value range:(NSRange)range;
- (void)addAttributes:(id)attributes range:(NSRange)range;
- (void)setAttributes:(id)attributes range:(NSRange)range;
- (void)replaceCharactersInRange:(NSRange)range withString:(id)string;
- (void)appendAttributedString:(id)other;
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
}
+ (id)indexPathForRow:(long)row inSection:(long)section;
- (long)row;
- (long)section;
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
#else
typedef void *NSURLSessionCompletionHandler;
#endif

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

@interface NSURLRequest : NSObject {
@public
    id _URL;
    double _timeoutInterval;
    id _HTTPMethod;
    id _HTTPBody;
    id _allHTTPHeaderFields;
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
- (id)allHTTPHeaderFields;
- (void)setAllHTTPHeaderFields:(id)fields;
- (id)valueForHTTPHeaderField:(id)field;
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
}
- (void)resume;
- (void)cancel;
@end

@interface NSURLSession : NSObject
+ (id)sharedSession;
- (NSURLSessionDataTask *)dataTaskWithURL:(id)url
                        completionHandler:(NSURLSessionCompletionHandler)handler;
- (NSURLSessionDataTask *)dataTaskWithRequest:(id)request
                            completionHandler:(NSURLSessionCompletionHandler)handler;
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

@interface NSThread : NSObject
+ (NSThread *)currentThread;
+ (NSThread *)mainThread;
+ (BOOL)isMainThread;
+ (void)sleepForTimeInterval:(double)interval;
@end

@interface NSOperation : NSObject {
@public
    BOOL _cancelled;
    BOOL _finished;
    BOOL _dispatched;
    id _completionBlock;
}
- (void)start;
- (void)main;
- (void)cancel;
- (BOOL)isCancelled;
- (BOOL)isFinished;
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
    long _pending;
    long _maxConcurrent;
    BOOL _suspended;
}
+ (NSOperationQueue *)mainQueue;
- (id)init;
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

void NSLog(id format, ...);

const char *iosim_string_cstr(id string);
int iosim_foundation_tick(void);

#endif
