/* Foundation-lite: the collection, string, notification and timer surface
 * used by simulator apps. Built as an x86_64 Mach-O dylib at the canonical
 * install name. */

#include "foundation_lite.h"
#include <stdarg.h>

extern void *iosim_objc_alloc(void *cls);
extern void *iosim_objc_class_of(void *obj);
extern void *iosim_objc_superclass(void *cls);
extern int   iosim_objc_is_kind_of(void *obj, void *cls);
extern int   iosim_objc_responds(void *obj, void *sel);
extern void  iosim_nslog(const char *message);
extern double iosim_now(void);
extern void *objc_msgSend(void *self, void *sel, ...);
extern void *objc_getClass(const char *name);

extern void *malloc(unsigned long size);
extern void *calloc(unsigned long n, unsigned long size);
extern void *realloc(void *ptr, unsigned long size);
extern void  free(void *ptr);
extern int   snprintf(char *buf, unsigned long size, const char *fmt, ...);
extern unsigned long strlen(const char *s);
extern int   strcmp(const char *a, const char *b);
extern int   strncmp(const char *a, const char *b, unsigned long n);
extern void *memcpy(void *dst, const void *src, unsigned long n);
extern void *memset(void *dst, int c, unsigned long n);

struct cf_constant_string {
    void *isa;
    unsigned int flags;
    unsigned int pad;
    const char *cstr;
    unsigned long length;
};

extern void *objc_getClass(const char *name);

const char *iosim_string_cstr(id string)
{
    if (!string)
        return "";
    struct cf_constant_string *cs = (struct cf_constant_string *)string;
    if (cs->flags == 0x7c8 && cs->cstr)
        return cs->cstr;
    if (((Class)iosim_objc_class_of(string)) &&
        iosim_objc_is_kind_of(string, objc_getClass("NSString")))
    {
        NSString *s = (NSString *)string;
        return s->_cstr ? s->_cstr : "";
    }
    return "";
}

static const char *obj_cstr(id obj)
{
    if (!obj)
        return "(null)";
    struct cf_constant_string *cs = (struct cf_constant_string *)obj;
    if (cs->flags == 0x7c8 && cs->cstr)
        return cs->cstr;
    if (iosim_objc_is_kind_of(obj, objc_getClass("NSString")))
        return ((NSString *)obj)->_cstr ? ((NSString *)obj)->_cstr : "";
    id desc = [obj description];
    if (desc && desc != obj)
        return obj_cstr(desc);
    return "?";
}

static int objects_equal(id a, id b)
{
    if (a == b)
        return 1;
    if (!a || !b)
        return 0;
    struct cf_constant_string *ca = (struct cf_constant_string *)a;
    struct cf_constant_string *cb = (struct cf_constant_string *)b;
    if (ca->flags == 0x7c8 && cb->flags == 0x7c8)
        return strcmp(ca->cstr, cb->cstr) == 0;
    if (iosim_objc_is_kind_of(a, objc_getClass("NSString")) ||
        iosim_objc_is_kind_of(b, objc_getClass("NSString")))
        return strcmp(iosim_string_cstr(a), iosim_string_cstr(b)) == 0;
    return [a isEqual:b] ? 1 : 0;
}

/* ------------------------------------------------------------- NSObject */

@implementation NSObject

+ (id)alloc { return iosim_objc_alloc(self); }
+ (id)new { return [[self alloc] init]; }
+ (Class)class { return self; }
- (id)init { return self; }
- (void)dealloc { }
- (id)retain { return self; }
- (void)release { }
- (id)autorelease { return self; }
- (unsigned long)retainCount { return 1; }
- (Class)class { return iosim_objc_class_of(self); }
- (Class)superclass { return iosim_objc_superclass(iosim_objc_class_of(self)); }
- (BOOL)isKindOfClass:(Class)cls { return (BOOL)iosim_objc_is_kind_of(self, cls); }
- (BOOL)isMemberOfClass:(Class)cls { return iosim_objc_class_of(self) == cls; }
- (BOOL)respondsToSelector:(SEL)sel { return (BOOL)iosim_objc_responds(self, sel); }
- (BOOL)isEqual:(id)other { return self == other; }
- (unsigned long)hash { return (unsigned long)(long)self; }
- (id)description { return [NSString stringWithUTF8String:"<NSObject>"]; }
@end

/* ------------------------------------------------------------- NSString */

static char *copy_cstr(const char *s, unsigned long *length)
{
    if (!s)
        s = "";
    unsigned long n = strlen(s);
    char *out = malloc(n + 1);
    if (!out)
        return 0;
    memcpy(out, s, n + 1);
    if (length)
        *length = n;
    return out;
}

static void append_bytes(char **buf, unsigned long *cap, unsigned long *len,
                         const char *s, unsigned long n)
{
    if (*len + n + 1 > *cap)
    {
        unsigned long next = *cap ? *cap : 128;
        while (next < *len + n + 1)
            next *= 2;
        char *grown = realloc(*buf, next);
        if (!grown)
            return;
        *buf = grown;
        *cap = next;
    }
    memcpy(*buf + *len, s, n);
    *len += n;
    (*buf)[*len] = 0;
}

static char *format_va(const char *fmt, va_list ap)
{
    char *out = 0;
    unsigned long cap = 0, len = 0;
    append_bytes(&out, &cap, &len, "", 0);
    const char *p = fmt;
    while (*p)
    {
        if (*p != '%')
        {
            append_bytes(&out, &cap, &len, p, 1);
            p++;
            continue;
        }
        if (p[1] == '%')
        {
            append_bytes(&out, &cap, &len, "%", 1);
            p += 2;
            continue;
        }
        const char *start = p;
        p++;
        while (*p && !( *p == '@' || *p == 's' || *p == 'd' || *p == 'i' ||
                        *p == 'u' || *p == 'o' || *p == 'x' || *p == 'X' ||
                        *p == 'f' || *p == 'e' || *p == 'g' || *p == 'c' ||
                        *p == 'p'))
            p++;
        char conv = *p ? *p : 'd';
        if (*p)
            p++;
        char spec[32];
        unsigned long sn = (unsigned long)(p - start);
        if (sn >= sizeof(spec))
            sn = sizeof(spec) - 1;
        memcpy(spec, start, sn);
        spec[sn] = 0;
        char tmp[256];
        tmp[0] = 0;
        if (conv == '@')
        {
            id obj = va_arg(ap, id);
            const char *s = obj_cstr(obj);
            append_bytes(&out, &cap, &len, s, strlen(s));
        }
        else if (conv == 's')
        {
            const char *s = va_arg(ap, const char *);
            snprintf(tmp, sizeof(tmp), "%s", s ? s : "(null)");
            append_bytes(&out, &cap, &len, tmp, strlen(tmp));
        }
        else if (conv == 'd' || conv == 'i')
        {
            if (spec[sn - 1] == 'd' || spec[sn - 1] == 'i')
            {
                /* pick the argument type from the length modifier */
            }
            long long v;
            if (strncmp(spec, "%%lld", 5) == 0 || strncmp(spec, "%lld", 4) == 0)
                v = va_arg(ap, long long);
            else if (spec[1] == 'l')
                v = va_arg(ap, long);
            else
                v = va_arg(ap, int);
            snprintf(tmp, sizeof(tmp), spec, v);
            append_bytes(&out, &cap, &len, tmp, strlen(tmp));
        }
        else if (conv == 'f' || conv == 'e' || conv == 'g')
        {
            double v = va_arg(ap, double);
            snprintf(tmp, sizeof(tmp), spec, v);
            append_bytes(&out, &cap, &len, tmp, strlen(tmp));
        }
        else if (conv == 'c')
        {
            int v = va_arg(ap, int);
            snprintf(tmp, sizeof(tmp), spec, v);
            append_bytes(&out, &cap, &len, tmp, strlen(tmp));
        }
        else
        {
            void *v = va_arg(ap, void *);
            snprintf(tmp, sizeof(tmp), spec, v);
            append_bytes(&out, &cap, &len, tmp, strlen(tmp));
        }
    }
    return out;
}

@implementation NSString
+ (id)stringWithUTF8String:(const char *)s
{
    return [[[self alloc] initWithUTF8String:s] autorelease];
}
+ (id)stringWithString:(id)other
{
    return [[[self alloc] initWithUTF8String:iosim_string_cstr(other)] autorelease];
}
+ (id)stringWithFormat:(id)format, ...
{
    va_list ap;
    va_start(ap, format);
    char *buf = format_va(iosim_string_cstr(format), ap);
    va_end(ap);
    NSString *s = [[self alloc] initWithUTF8String:buf ? buf : ""];
    free(buf);
    return s;
}
- (id)initWithUTF8String:(const char *)s
{
    self = [super init];
    if (self)
        _cstr = copy_cstr(s, &_length);
    return self;
}
- (id)initWithFormat:(id)format, ...
{
    va_list ap;
    va_start(ap, format);
    char *buf = format_va(iosim_string_cstr(format), ap);
    va_end(ap);
    self = [self initWithUTF8String:buf ? buf : ""];
    free(buf);
    return self;
}
- (const char *)UTF8String { return _cstr ? _cstr : ""; }
- (unsigned long)length { return _length; }
- (unsigned short)characterAtIndex:(unsigned long)index
{
    if (!_cstr || index >= _length)
        return 0;
    return (unsigned short)(unsigned char)_cstr[index];
}
- (BOOL)isEqual:(id)other
{
    if (other == self)
        return YES;
    if (!other)
        return NO;
    return (BOOL)(strcmp(iosim_string_cstr(self), iosim_string_cstr(other)) == 0);
}
- (BOOL)isEqualToString:(id)other { return [self isEqual:other]; }
- (unsigned long)hash
{
    unsigned long h = 5381;
    for (unsigned long i = 0; i < _length; i++)
        h = (h * 33) + (unsigned char)_cstr[i];
    return h;
}
- (id)description { return self; }
- (id)stringByAppendingString:(id)other
{
    const char *a = iosim_string_cstr(self);
    const char *b = iosim_string_cstr(other);
    unsigned long na = strlen(a), nb = strlen(b);
    char *buf = malloc(na + nb + 1);
    if (!buf)
        return [NSString stringWithUTF8String:a];
    memcpy(buf, a, na);
    memcpy(buf + na, b, nb + 1);
    NSString *s = [[NSString alloc] initWithUTF8String:buf];
    free(buf);
    return s;
}
- (id)uppercaseString
{
    char *buf = copy_cstr(_cstr ? _cstr : "", 0);
    if (!buf)
        return self;
    for (char *p = buf; *p; p++)
        if (*p >= 'a' && *p <= 'z')
            *p -= 32;
    return [[[NSString alloc] initWithUTF8String:buf] autorelease];
}
- (id)lowercaseString
{
    char *buf = copy_cstr(_cstr ? _cstr : "", 0);
    if (!buf)
        return self;
    for (char *p = buf; *p; p++)
        if (*p >= 'A' && *p <= 'Z')
            *p += 32;
    return [[[NSString alloc] initWithUTF8String:buf] autorelease];
}
- (id)substringToIndex:(unsigned long)index
{
    if (index > _length)
        index = _length;
    char *buf = malloc(index + 1);
    if (!buf)
        return self;
    memcpy(buf, _cstr, index);
    buf[index] = 0;
    NSString *s = [[NSString alloc] initWithUTF8String:buf];
    free(buf);
    return s;
}
- (id)substringFromIndex:(unsigned long)index
{
    if (index > _length)
        index = _length;
    return [NSString stringWithUTF8String:_cstr + index];
}
- (BOOL)hasPrefix:(id)prefix
{
    const char *p = iosim_string_cstr(prefix);
    unsigned long n = strlen(p);
    return (BOOL)(n <= _length && strncmp(_cstr, p, n) == 0);
}
- (BOOL)hasSuffix:(id)suffix
{
    const char *s = iosim_string_cstr(suffix);
    unsigned long n = strlen(s);
    return (BOOL)(n <= _length && strcmp(_cstr + _length - n, s) == 0);
}
- (id)componentsSeparatedByString:(id)separator
{
    const char *sep = iosim_string_cstr(separator);
    unsigned long sn = strlen(sep);
    NSMutableArray *result = [NSMutableArray array];
    if (!sn)
    {
        [result addObject:self];
        return result;
    }
    const char *start = _cstr;
    for (const char *p = _cstr; ; p++)
    {
        if (strncmp(p, sep, sn) == 0)
        {
            unsigned long n = (unsigned long)(p - start);
            char *tmp = malloc(n + 1);
            memcpy(tmp, start, n);
            tmp[n] = 0;
            NSString *piece = [[NSString alloc] initWithUTF8String:tmp];
            free(tmp);
            [result addObject:piece];
            start = p + sn;
            p += sn - 1;
        }
        else if (!*p)
        {
            [result addObject:[NSString stringWithUTF8String:start]];
            break;
        }
    }
    return result;
}
- (id)stringByReplacingOccurrencesOfString:(id)target withString:(id)replacement
{
    const char *t = iosim_string_cstr(target);
    const char *r = iosim_string_cstr(replacement);
    unsigned long tn = strlen(t), rn = strlen(r);
    if (!tn)
        return self;
    char *out = 0;
    unsigned long cap = 0, len = 0;
    const char *p = _cstr;
    while (*p)
    {
        if (strncmp(p, t, tn) == 0)
        {
            append_bytes(&out, &cap, &len, r, rn);
            p += tn;
        }
        else
        {
            append_bytes(&out, &cap, &len, p, 1);
            p++;
        }
    }
    NSString *s = [[NSString alloc] initWithUTF8String:out ? out : ""];
    free(out);
    return s;
}
@end

@implementation NSMutableString
+ (id)string { return [[[self alloc] init] autorelease]; }
- (void)appendString:(id)string
{
    const char *s = iosim_string_cstr(string);
    unsigned long n = strlen(s);
    char *buf = malloc(_length + n + 1);
    memcpy(buf, _cstr ? _cstr : "", _length);
    memcpy(buf + _length, s, n + 1);
    free(_cstr);
    _cstr = buf;
    _length += n;
}
- (void)setString:(id)string
{
    free(_cstr);
    _cstr = copy_cstr(iosim_string_cstr(string), &_length);
}
@end

/* ------------------------------------------------------------- NSNumber */

@implementation NSIndexPath
+ (id)indexPathForRow:(long)row inSection:(long)section
{
    NSIndexPath *path = [[self alloc] init];
    path->_row = row;
    path->_section = section;
    return path;
}
- (long)row { return _row; }
- (long)section { return _section; }
- (id)description
{
    return [NSString stringWithFormat:@"<NSIndexPath: %p> {length = 2, path = %ld - %ld}",
            self, _section, _row];
}
@end

@implementation NSNumber
+ (id)numberWithInt:(int)value { return [self numberWithLongLong:value]; }
+ (id)numberWithInteger:(long)value { return [self numberWithLongLong:value]; }
+ (id)numberWithLongLong:(long long)value
{
    NSNumber *n = [[self alloc] init];
    n->_ival = value;
    n->_kind = 0;
    return n;
}
+ (id)numberWithBool:(BOOL)value
{
    NSNumber *n = [[self alloc] init];
    n->_ival = value ? 1 : 0;
    n->_kind = 2;
    return n;
}
+ (id)numberWithFloat:(float)value { return [self numberWithDouble:value]; }
+ (id)numberWithDouble:(double)value
{
    NSNumber *n = [[self alloc] init];
    n->_dval = value;
    n->_kind = 1;
    return n;
}
- (int)intValue { return self->_kind == 1 ? (int)_dval : (int)_ival; }
- (long)integerValue { return self->_kind == 1 ? (long)_dval : (long)_ival; }
- (long long)longLongValue { return self->_kind == 1 ? (long long)_dval : _ival; }
- (BOOL)boolValue { return [self intValue] != 0; }
- (float)floatValue { return self->_kind == 1 ? (float)_dval : (float)_ival; }
- (double)doubleValue { return self->_kind == 1 ? _dval : (double)_ival; }
- (id)stringValue
{
    char buf[64];
    if (_kind == 1)
        snprintf(buf, sizeof(buf), "%g", _dval);
    else
        snprintf(buf, sizeof(buf), "%lld", _ival);
    return [NSString stringWithUTF8String:buf];
}
- (id)description { return [self stringValue]; }
- (BOOL)isEqual:(id)other
{
    if (!other || ![other isKindOfClass:[NSNumber class]])
        return NO;
    return ((NSNumber *)other)->_kind == 1 ? [self doubleValue] == [(NSNumber *)other doubleValue]
                                           : [self longLongValue] == [(NSNumber *)other longLongValue];
}
- (unsigned long)hash { return (unsigned long)[self longLongValue]; }
@end

/* -------------------------------------------------------------- NSArray */

@implementation NSArray
+ (id)array { return [[[self alloc] init] autorelease]; }
+ (id)arrayWithObject:(id)object
{
    NSMutableArray *a = [NSMutableArray array];
    [a addObject:object];
    return a;
}
+ (id)arrayWithArray:(id)array
{
    NSMutableArray *a = [NSMutableArray array];
    for (unsigned long i = 0; i < [array count]; i++)
        [a addObject:[array objectAtIndex:i]];
    return a;
}
+ (id)arrayWithObjects:(const id *)objects count:(unsigned long)count
{
    NSMutableArray *a = [NSMutableArray array];
    for (unsigned long i = 0; i < count; i++)
        [a addObject:objects[i]];
    return a;
}
+ (id)arrayWithObjects:(id)first, ...
{
    NSMutableArray *a = [NSMutableArray array];
    va_list ap;
    va_start(ap, first);
    id obj = first;
    while (obj)
    {
        [a addObject:obj];
        obj = va_arg(ap, id);
    }
    va_end(ap);
    return a;
}
- (id)initWithObjects:(id)first, ...
{
    self = [super init];
    if (self)
    {
        va_list ap;
        va_start(ap, first);
        id obj = first;
        while (obj)
        {
            id *items = realloc(_items, (_count + 1) * sizeof(id));
            if (!items)
                break;
            _items = items;
            _items[_count++] = obj;
            obj = va_arg(ap, id);
        }
        va_end(ap);
    }
    return self;
}
- (unsigned long)count { return _count; }
- (id)objectAtIndex:(unsigned long)index
{
    if (index >= _count)
        return nil;
    return _items[index];
}
- (id)firstObject { return _count ? _items[0] : nil; }
- (id)lastObject { return _count ? _items[_count - 1] : nil; }
- (BOOL)containsObject:(id)object { return [self indexOfObject:object] != (unsigned long)-1; }
- (unsigned long)indexOfObject:(id)object
{
    for (unsigned long i = 0; i < _count; i++)
        if (objects_equal(_items[i], object))
            return i;
    return (unsigned long)-1;
}
- (id)description
{
    NSMutableString *s = [NSMutableString string];
    [s appendString:@"("];
    for (unsigned long i = 0; i < _count; i++)
    {
        if (i)
            [s appendString:@", "];
        [s appendString:[NSString stringWithUTF8String:obj_cstr(_items[i])]];
    }
    [s appendString:@")"];
    return s;
}
@end

@implementation NSMutableArray
+ (id)array { return [[[self alloc] init] autorelease]; }
- (void)addObject:(id)object
{
    if (!object)
        return;
    id *items = realloc(_items, (_count + 1) * sizeof(id));
    if (!items)
        return;
    _items = items;
    _items[_count++] = object;
}
- (void)insertObject:(id)object atIndex:(unsigned long)index
{
    if (index > _count)
        index = _count;
    id *items = realloc(_items, (_count + 1) * sizeof(id));
    if (!items)
        return;
    _items = items;
    for (unsigned long i = _count; i > index; i--)
        _items[i] = _items[i - 1];
    _items[index] = object;
    _count++;
}
- (void)removeObjectAtIndex:(unsigned long)index
{
    if (index >= _count)
        return;
    for (unsigned long i = index; i + 1 < _count; i++)
        _items[i] = _items[i + 1];
    _count--;
}
- (void)removeAllObjects { _count = 0; }
- (void)removeObject:(id)object
{
    unsigned long i = [self indexOfObject:object];
    if (i != (unsigned long)-1)
        [self removeObjectAtIndex:i];
}
@end

/* --------------------------------------------------------- NSDictionary */

@implementation NSDictionary
+ (id)dictionary { return [[[self alloc] init] autorelease]; }
+ (id)dictionaryWithObjects:(const id *)objects
                    forKeys:(const id *)keys
                      count:(unsigned long)count
{
    NSMutableDictionary *d = [NSMutableDictionary dictionary];
    for (unsigned long i = 0; i < count; i++)
        [d setObject:objects[i] forKey:keys[i]];
    return d;
}
+ (id)dictionaryWithObjects:(id)firstObject forKeys:(id)firstKey, ...
{
    NSMutableDictionary *d = [NSMutableDictionary dictionary];
    va_list ap;
    va_start(ap, firstKey);
    id obj = firstObject, key = firstKey;
    while (obj && key)
    {
        [d setObject:obj forKey:key];
        obj = va_arg(ap, id);
        key = va_arg(ap, id);
    }
    va_end(ap);
    return d;
}
- (unsigned long)count { return _count; }
- (id)objectForKey:(id)key
{
    for (unsigned long i = 0; i < _count; i++)
        if (objects_equal(_keys[i], key))
            return _values[i];
    return nil;
}
- (id)allKeys
{
    NSMutableArray *a = [NSMutableArray array];
    for (unsigned long i = 0; i < _count; i++)
        [a addObject:_keys[i]];
    return a;
}
- (id)allValues
{
    NSMutableArray *a = [NSMutableArray array];
    for (unsigned long i = 0; i < _count; i++)
        [a addObject:_values[i]];
    return a;
}
@end

@implementation NSMutableDictionary
+ (id)dictionary { return [[[self alloc] init] autorelease]; }
- (void)setObject:(id)object forKey:(id)key
{
    if (!object || !key)
        return;
    for (unsigned long i = 0; i < _count; i++)
    {
        if (objects_equal(_keys[i], key))
        {
            _values[i] = object;
            return;
        }
    }
    id *keys = realloc(_keys, (_count + 1) * sizeof(id));
    id *values = realloc(_values, (_count + 1) * sizeof(id));
    if (!keys || !values)
        return;
    _keys = keys;
    _values = values;
    _keys[_count] = key;
    _values[_count] = object;
    _count++;
}
- (void)removeObjectForKey:(id)key
{
    for (unsigned long i = 0; i < _count; i++)
    {
        if (objects_equal(_keys[i], key))
        {
            for (unsigned long j = i; j + 1 < _count; j++)
            {
                _keys[j] = _keys[j + 1];
                _values[j] = _values[j + 1];
            }
            _count--;
            return;
        }
    }
}
- (void)removeAllObjects { _count = 0; }
@end

/* --------------------------------------------------------------- NSData */

@implementation NSData
+ (id)data { return [[[self alloc] init] autorelease]; }
+ (id)dataWithBytes:(const void *)bytes length:(unsigned long)length
{
    NSData *d = [[self alloc] init];
    if (d)
    {
        d->_bytes = malloc(length);
        if (d->_bytes)
            memcpy(d->_bytes, bytes, length);
        d->_length = length;
    }
    return d;
}
- (const void *)bytes { return _bytes; }
- (unsigned long)length { return _length; }
@end

/* ------------------------------------------------------- Notifications */

@implementation NSNotification
+ (id)notificationWithName:(id)name object:(id)object
{
    NSNotification *n = [[self alloc] init];
    n->_name = name;
    n->_object = object;
    return n;
}
- (id)name { return _name; }
- (id)object { return _object; }
@end

@implementation NSNotificationCenter
+ (id)defaultCenter
{
    static NSNotificationCenter *center;
    if (!center)
        center = [[self alloc] init];
    return center;
}
- (void)addObserver:(id)observer selector:(SEL)selector
               name:(id)name object:(id)object
{
    if (_count >= 64)
        return;
    _observers[_count] = observer;
    _selectors[_count] = selector;
    _names[_count] = name;
    _objects[_count] = object;
    _count++;
}
- (void)removeObserver:(id)observer
{
    for (int i = 0; i < _count; i++)
    {
        if (_observers[i] == observer)
        {
            for (int j = i; j + 1 < _count; j++)
            {
                _observers[j] = _observers[j + 1];
                _selectors[j] = _selectors[j + 1];
                _names[j] = _names[j + 1];
                _objects[j] = _objects[j + 1];
            }
            _count--;
            i--;
        }
    }
}
- (void)postNotificationName:(id)name object:(id)object
{
    NSNotification *note = [NSNotification notificationWithName:name object:object];
    for (int i = 0; i < _count; i++)
    {
        if (_names[i] && !objects_equal(_names[i], name))
            continue;
        if (_objects[i] && _objects[i] != object)
            continue;
        void (*imp)(id, SEL, id) = (void (*)(id, SEL, id))objc_msgSend;
        imp(_observers[i], _selectors[i], note);
    }
}
@end

/* ---------------------------------------------------------------- Timer */

static NSTimer *g_timers[64];
static int g_timer_count;

@implementation NSTimer
+ (id)scheduledTimerWithTimeInterval:(double)interval target:(id)target
    selector:(SEL)selector userInfo:(id)userInfo repeats:(BOOL)repeats
{
    NSTimer *timer = [[self alloc] init];
    timer->_interval = interval;
    timer->_target = target;
    timer->_selector = selector;
    timer->_userInfo = userInfo;
    timer->_repeats = repeats;
    timer->_valid = YES;
    timer->_nextFire = iosim_now() + interval;
    if (g_timer_count < 64)
        g_timers[g_timer_count++] = timer;
    return timer;
}
- (void)invalidate { _valid = NO; }
- (void)fire
{
    if (!_valid || !_target)
        return;
    void (*imp)(id, SEL, id) = (void (*)(id, SEL, id))objc_msgSend;
    imp(_target, _selector, self);
    if (_repeats)
        _nextFire = iosim_now() + _interval;
    else
        _valid = NO;
}
@end

int iosim_foundation_tick(void)
{
    double now = iosim_now();
    int fired = 0;
    for (int i = 0; i < g_timer_count; i++)
    {
        NSTimer *timer = g_timers[i];
        if (timer && timer->_valid && now >= timer->_nextFire)
        {
            [timer fire];
            fired++;
        }
    }
    return fired;
}

/* ---------------------------------------------------------------- NSLog */

void NSLog(id format, ...)
{
    const char *fmt = iosim_string_cstr(format);
    va_list ap;
    va_start(ap, format);
    char *text = format_va(fmt, ap);
    va_end(ap);
    iosim_nslog(text ? text : "(null)");
    free(text);
}
