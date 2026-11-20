#ifndef IOSIM_FOUNDATION_LITE_H
#define IOSIM_FOUNDATION_LITE_H

#include "objc_lite.h"

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
@end

@class NSString;

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
- (id)stringByAppendingString:(id)other;
- (id)uppercaseString;
- (id)lowercaseString;
- (id)substringToIndex:(unsigned long)index;
- (id)substringFromIndex:(unsigned long)index;
- (BOOL)hasPrefix:(id)prefix;
- (BOOL)hasSuffix:(id)suffix;
- (id)componentsSeparatedByString:(id)separator;
- (id)stringByReplacingOccurrencesOfString:(id)target withString:(id)replacement;
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

@interface NSArray : NSObject {
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
@end

@interface NSMutableArray : NSArray
+ (id)array;
- (void)addObject:(id)object;
- (void)insertObject:(id)object atIndex:(unsigned long)index;
- (void)removeObjectAtIndex:(unsigned long)index;
- (void)removeAllObjects;
- (void)removeObject:(id)object;
@end

@interface NSDictionary : NSObject {
@public
    id *_keys;
    id *_values;
    unsigned long _count;
}
+ (id)dictionary;
+ (id)dictionaryWithObjects:(id)firstObject forKeys:(id)firstKey, ...;
+ (id)dictionaryWithObjects:(const id *)objects
                    forKeys:(const id *)keys
                      count:(unsigned long)count;
- (unsigned long)count;
- (id)objectForKey:(id)key;
- (id)allKeys;
- (id)allValues;
@end

@interface NSMutableDictionary : NSDictionary
+ (id)dictionary;
- (void)setObject:(id)object forKey:(id)key;
- (void)removeObjectForKey:(id)key;
- (void)removeAllObjects;
@end

@interface NSData : NSObject {
@public
    void *_bytes;
    unsigned long _length;
}
+ (id)dataWithBytes:(const void *)bytes length:(unsigned long)length;
+ (id)data;
- (const void *)bytes;
- (unsigned long)length;
@end

@interface NSNotification : NSObject {
@public
    id _name;
    id _object;
}
+ (id)notificationWithName:(id)name object:(id)object;
- (id)name;
- (id)object;
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
- (void)removeObserver:(id)observer;
- (void)postNotificationName:(id)name object:(id)object;
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
}
+ (id)scheduledTimerWithTimeInterval:(double)interval target:(id)target
    selector:(SEL)selector userInfo:(id)userInfo repeats:(BOOL)repeats;
- (void)invalidate;
- (void)fire;
@end

void NSLog(id format, ...);

const char *iosim_string_cstr(id string);
int iosim_foundation_tick(void);

#endif
