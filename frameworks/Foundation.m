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
extern char *getenv(const char *name);

extern void *malloc(unsigned long size);
extern void *calloc(unsigned long n, unsigned long size);
extern void *realloc(void *ptr, unsigned long size);
extern void  free(void *ptr);
extern int   snprintf(char *buf, unsigned long size, const char *fmt, ...);
extern double strtod(const char *s, char **end);
extern int   iosim_fs_exists(const char *path);
extern int   iosim_fs_is_dir(const char *path);
extern long  iosim_fs_size(const char *path);
extern int   iosim_fs_read(const char *path, unsigned char **out,
                           unsigned long *out_len);
extern int   iosim_fs_write(const char *path, const void *bytes,
                            unsigned long len);
extern int   iosim_fs_remove(const char *path);
extern int   iosim_fs_rename(const char *from, const char *to);
extern int   iosim_fs_mkdir(const char *path, int intermediates);
extern int   iosim_fs_list(const char *path, char *out, unsigned long cap);
extern unsigned long strlen(const char *s);
extern int   strcmp(const char *a, const char *b);
extern int   strncmp(const char *a, const char *b, unsigned long n);
extern void *memcpy(void *dst, const void *src, unsigned long n);
extern void *memset(void *dst, int c, unsigned long n);
extern int   memcmp(const void *a, const void *b, unsigned long n);
extern char *strstr(const char *haystack, const char *needle);

struct cf_constant_string {
    void *isa;
    unsigned int flags;
    unsigned int pad;
    const char *cstr;
    unsigned long length;
};

extern void *objc_getClass(const char *name);
extern char *getenv(const char *name);


static char *iosim_utf16_to_utf8(const unsigned short *s, unsigned long n)
{
    if (!s)
        return (char *)"";
    char *out = malloc(n * 4 + 1);
    if (!out)
        return (char *)"";
    char *p = out;
    for (unsigned long i = 0; i < n; i++)
    {
        unsigned int c = s[i];
        if (c >= 0xD800 && c <= 0xDBFF && i + 1 < n)
        {
            unsigned int lo = s[i + 1];
            if (lo >= 0xDC00 && lo <= 0xDFFF)
            {
                c = 0x10000 + ((c - 0xD800) << 10) + (lo - 0xDC00);
                i++;
            }
        }
        if (c < 0x80)
            *p++ = (char)c;
        else if (c < 0x800)
        {
            *p++ = (char)(0xC0 | (c >> 6));
            *p++ = (char)(0x80 | (c & 0x3F));
        }
        else if (c < 0x10000)
        {
            *p++ = (char)(0xE0 | (c >> 12));
            *p++ = (char)(0x80 | ((c >> 6) & 0x3F));
            *p++ = (char)(0x80 | (c & 0x3F));
        }
        else
        {
            *p++ = (char)(0xF0 | (c >> 18));
            *p++ = (char)(0x80 | ((c >> 12) & 0x3F));
            *p++ = (char)(0x80 | ((c >> 6) & 0x3F));
            *p++ = (char)(0x80 | (c & 0x3F));
        }
    }
    *p = 0;
    return out;
}

const char *iosim_string_cstr(id string)
{
    if (!string)
        return "";
    struct cf_constant_string *cs = (struct cf_constant_string *)string;
    if (cs->flags == 0x7c8 && cs->cstr)
        return cs->cstr;
    if (cs->flags == 0x7d0 && cs->cstr)
        return iosim_utf16_to_utf8((const unsigned short *)cs->cstr,
                                   cs->length);
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
    if (cs->flags == 0x7d0 && cs->cstr)
        return iosim_utf16_to_utf8((const unsigned short *)cs->cstr,
                                   cs->length);
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
- (const char *)UTF8String { return iosim_string_cstr(self); }
- (unsigned long)length { return strlen(iosim_string_cstr(self)); }
- (unsigned short)characterAtIndex:(unsigned long)index
{
    const char *chars = iosim_string_cstr(self);
    unsigned long len = strlen(chars);
    if (index >= len)
        return 0;
    return (unsigned short)(unsigned char)chars[index];
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
    const char *chars = iosim_string_cstr(self);
    unsigned long len = strlen(chars);
    unsigned long h = 5381;
    for (unsigned long i = 0; i < len; i++)
        h = (h * 33) + (unsigned char)chars[i];
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
    char *buf = copy_cstr(iosim_string_cstr(self), 0);
    if (!buf)
        return self;
    for (char *p = buf; *p; p++)
        if (*p >= 'a' && *p <= 'z')
            *p -= 32;
    return [[[NSString alloc] initWithUTF8String:buf] autorelease];
}
- (id)lowercaseString
{
    char *buf = copy_cstr(iosim_string_cstr(self), 0);
    if (!buf)
        return self;
    for (char *p = buf; *p; p++)
        if (*p >= 'A' && *p <= 'Z')
            *p += 32;
    return [[[NSString alloc] initWithUTF8String:buf] autorelease];
}
- (id)substringToIndex:(unsigned long)index
{
    const char *chars = iosim_string_cstr(self);
    unsigned long len = strlen(chars);
    if (index > len)
        index = len;
    char *buf = malloc(index + 1);
    if (!buf)
        return self;
    memcpy(buf, chars, index);
    buf[index] = 0;
    NSString *s = [[NSString alloc] initWithUTF8String:buf];
    free(buf);
    return s;
}
- (id)substringFromIndex:(unsigned long)index
{
    const char *chars = iosim_string_cstr(self);
    unsigned long len = strlen(chars);
    if (index > len)
        index = len;
    return [NSString stringWithUTF8String:chars + index];
}
- (BOOL)hasPrefix:(id)prefix
{
    const char *p = iosim_string_cstr(prefix);
    unsigned long n = strlen(p);
    const char *chars = iosim_string_cstr(self);
    return (BOOL)(n <= strlen(chars) && strncmp(chars, p, n) == 0);
}
- (BOOL)hasSuffix:(id)suffix
{
    const char *s = iosim_string_cstr(suffix);
    unsigned long n = strlen(s);
    const char *chars = iosim_string_cstr(self);
    unsigned long len = strlen(chars);
    return (BOOL)(n <= len && strcmp(chars + len - n, s) == 0);
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
    const char *chars = iosim_string_cstr(self);
    const char *start = chars;
    for (const char *p = chars; ; p++)
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
    const char *p = iosim_string_cstr(self);
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
- (id)stringByAppendingPathComponent:(id)component
{
    const char *base = iosim_string_cstr(self);
    const char *comp = iosim_string_cstr(component);
    unsigned long bn = strlen(base), cn = strlen(comp);
    char *buf = malloc(bn + cn + 2);
    if (!buf)
        return self;
    memcpy(buf, base, bn);
    unsigned long n = bn;
    while (n > 1 && buf[n - 1] == '/')
        n--;
    if (n && buf[n - 1] != '/')
        buf[n++] = '/';
    memcpy(buf + n, comp, cn);
    n += cn;
    buf[n] = 0;
    NSString *path = [[NSString alloc] initWithUTF8String:buf];
    free(buf);
    return path;
}
- (id)lastPathComponent
{
    const char *s = iosim_string_cstr(self);
    unsigned long n = strlen(s);
    while (n > 1 && s[n - 1] == '/')
        n--;
    unsigned long start = n;
    while (start > 0 && s[start - 1] != '/')
        start--;
    char buf[1024];
    unsigned long len = n - start;
    if (len >= sizeof(buf))
        len = sizeof(buf) - 1;
    memcpy(buf, s + start, len);
    buf[len] = 0;
    return [NSString stringWithUTF8String:buf];
}
- (id)pathExtension
{
    const char *name = iosim_string_cstr([self lastPathComponent]);
    const char *dot = 0;
    for (const char *p = name; *p; p++)
        if (*p == '.')
            dot = p;
    if (!dot || dot == name)
        return @"";
    return [NSString stringWithUTF8String:dot + 1];
}
- (id)stringByDeletingLastPathComponent
{
    const char *s = iosim_string_cstr(self);
    unsigned long n = strlen(s);
    while (n > 1 && s[n - 1] == '/')
        n--;
    while (n > 0 && s[n - 1] != '/')
        n--;
    while (n > 1 && s[n - 1] == '/')
        n--;
    char buf[1024];
    if (n >= sizeof(buf))
        n = sizeof(buf) - 1;
    memcpy(buf, s, n);
    buf[n] = 0;
    if (n == 0)
        return @"";
    return [NSString stringWithUTF8String:buf];
}
- (id)stringByDeletingPathExtension
{
    const char *s = iosim_string_cstr(self);
    unsigned long n = strlen(s);
    unsigned long slash = n;
    for (unsigned long i = n; i > 0; i--)
        if (s[i - 1] == '/')
        {
            slash = i - 1;
            break;
        }
    unsigned long dot = n;
    for (unsigned long i = n; i > slash + 1; i--)
        if (s[i - 1] == '.')
        {
            dot = i - 1;
            break;
        }
    if (dot == n)
        return self;
    char buf[1024];
    unsigned long len = dot;
    if (len >= sizeof(buf))
        len = sizeof(buf) - 1;
    memcpy(buf, s, len);
    buf[len] = 0;
    return [NSString stringWithUTF8String:buf];
}
- (id)dataUsingEncoding:(unsigned long)encoding
{
    (void)encoding;
    const char *chars = iosim_string_cstr(self);
    return [NSData dataWithBytes:chars length:strlen(chars)];
}
- (id)initWithData:(id)data encoding:(unsigned long)encoding
{
    (void)encoding;
    self = [super init];
    if (self && data)
    {
        const char *bytes = (const char *)[data bytes];
        _cstr = copy_cstr(bytes, &_length);
    }
    return self;
}
- (BOOL)containsString:(id)needle
{
    const char *n = iosim_string_cstr(needle);
    if (!n || !*n)
        return NO;
    return strstr(iosim_string_cstr(self), n) != 0;
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

/* --------------------------------------------------------------- NSSet */

@implementation NSSet
+ (id)set { return [[[self alloc] init] autorelease]; }
+ (id)setWithObject:(id)object
{
    NSMutableSet *s = [NSMutableSet set];
    [s addObject:object];
    return s;
}
+ (id)setWithObjects:(const id *)objects count:(unsigned long)count
{
    NSMutableSet *s = [NSMutableSet set];
    for (unsigned long i = 0; i < count; i++)
        [s addObject:objects[i]];
    return s;
}
+ (id)setWithObjects:(id)first, ...
{
    NSMutableSet *s = [NSMutableSet set];
    va_list ap;
    va_start(ap, first);
    id obj = first;
    while (obj)
    {
        [s addObject:obj];
        obj = va_arg(ap, id);
    }
    va_end(ap);
    return s;
}
+ (id)setWithArray:(id)array
{
    NSMutableSet *s = [NSMutableSet set];
    for (unsigned long i = 0; i < [array count]; i++)
        [s addObject:[array objectAtIndex:i]];
    return s;
}
- (unsigned long)count { return _count; }
- (id)anyObject { return _count ? _items[0] : nil; }
- (id)allObjects
{
    return [NSArray arrayWithObjects:_items count:_count];
}
- (BOOL)containsObject:(id)object
{
    return [self member:object] != nil;
}
- (id)member:(id)object
{
    for (unsigned long i = 0; i < _count; i++)
        if (objects_equal(_items[i], object))
            return _items[i];
    return nil;
}
- (id)description
{
    NSMutableString *s = [NSMutableString string];
    [s appendString:@"{("];
    for (unsigned long i = 0; i < _count; i++)
    {
        if (i)
            [s appendString:@", "];
        [s appendString:[NSString stringWithUTF8String:obj_cstr(_items[i])]];
    }
    [s appendString:@")}"];
    return s;
}
@end

@implementation NSMutableSet
+ (id)set { return [[[self alloc] init] autorelease]; }
- (void)addObject:(id)object
{
    if (!object || [self containsObject:object])
        return;
    id *items = realloc(_items, (_count + 1) * sizeof(id));
    if (!items)
        return;
    _items = items;
    _items[_count++] = object;
}
- (void)removeObject:(id)object
{
    for (unsigned long i = 0; i < _count; i++)
    {
        if (objects_equal(_items[i], object))
        {
            for (unsigned long j = i; j + 1 < _count; j++)
                _items[j] = _items[j + 1];
            _count--;
            return;
        }
    }
}
- (void)removeAllObjects { _count = 0; }
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


/* --------------------------------------------------------------- bundles */

@implementation NSBundle
+ (NSBundle *)mainBundle
{
    static NSBundle *bundle;
    if (!bundle)
        bundle = [[self alloc] init];
    return bundle;
}
- (id)resourcePath
{
    const char *dir = getenv("IOSIM_BUNDLE_DIR");
    if (!dir || !*dir)
        dir = ".";
    return [NSString stringWithUTF8String:dir];
}
- (id)bundlePath { return [self resourcePath]; }
- (id)pathForResource:(id)name ofType:(id)type
{
    const char *n = iosim_string_cstr(name);
    const char *t = iosim_string_cstr(type);
    const char *dir = getenv("IOSIM_BUNDLE_DIR");
    if (!dir || !*dir)
        dir = ".";
    char buf[1024];
    if (t && *t)
        snprintf(buf, sizeof(buf), "%s/%s.%s", dir, n, t);
    else
        snprintf(buf, sizeof(buf), "%s/%s", dir, n);
    return [NSString stringWithUTF8String:buf];
}
@end

/* ---------------------------------------------------------- user defaults */

@implementation NSUserDefaults
+ (NSUserDefaults *)standardUserDefaults
{
    static NSUserDefaults *defaults;
    if (!defaults)
        defaults = [[self alloc] init];
    return defaults;
}
- (id)init
{
    self = [super init];
    if (self)
        _store = [NSMutableDictionary dictionary];
    return self;
}
- (void)setObject:(id)value forKey:(id)key
{
    if (!key)
        return;
    if (value)
        [_store setObject:value forKey:key];
    else
        [_store removeObjectForKey:key];
}
- (id)objectForKey:(id)key { return key ? [_store objectForKey:key] : nil; }
- (void)removeObjectForKey:(id)key { if (key) [_store removeObjectForKey:key]; }
- (id)stringForKey:(id)key
{
    id value = [self objectForKey:key];
    return value && [value isKindOfClass:[NSString class]] ? value : nil;
}
- (BOOL)boolForKey:(id)key
{
    id value = [self objectForKey:key];
    return value && [value respondsToSelector:@selector(boolValue)]
               ? [value boolValue] : NO;
}
- (long)integerForKey:(id)key
{
    id value = [self objectForKey:key];
    return value && [value respondsToSelector:@selector(integerValue)]
               ? [value integerValue] : 0;
}
- (void)synchronize { }
@end

@implementation NSData
+ (id)data { return [[[self alloc] init] autorelease]; }
+ (id)dataWithBytes:(const void *)bytes length:(unsigned long)length
{
    NSData *d = [[self alloc] init];
    if (d && bytes)
    {
        d->_bytes = malloc(length + 1);
        if (d->_bytes)
        {
            memcpy(d->_bytes, bytes, length);
            ((char *)d->_bytes)[length] = 0;
        }
        d->_length = length;
    }
    return d;
}
+ (id)dataWithContentsOfFile:(id)path
{
    unsigned char *bytes = 0;
    unsigned long length = 0;
    if (iosim_fs_read(iosim_string_cstr(path), &bytes, &length) != 0)
        return nil;
    NSData *d = [[self alloc] init];
    d->_bytes = bytes;
    d->_length = length;
    return d;
}
+ (id)dataWithContentsOfURL:(id)url
{
    return [self dataWithContentsOfFile:[url path]];
}
- (id)initWithBytes:(const void *)bytes length:(unsigned long)length
{
    self = [super init];
    if (self)
    {
        _bytes = malloc(length + 1);
        if (_bytes && bytes)
        {
            memcpy(_bytes, bytes, length);
            ((char *)_bytes)[length] = 0;
        }
        _length = bytes ? length : 0;
    }
    return self;
}
- (id)initWithContentsOfFile:(id)path
{
    unsigned char *bytes = 0;
    unsigned long length = 0;
    if (iosim_fs_read(iosim_string_cstr(path), &bytes, &length) != 0)
        return nil;
    self = [super init];
    if (self)
    {
        _bytes = bytes;
        _length = length;
    }
    return self;
}
- (const void *)bytes { return _bytes; }
- (unsigned long)length { return _length; }
- (BOOL)writeToFile:(id)path atomically:(BOOL)atomically
{
    (void)atomically;
    return iosim_fs_write(iosim_string_cstr(path), _bytes, _length) == 0;
}
- (BOOL)writeToURL:(id)url atomically:(BOOL)atomically
{
    return [self writeToFile:[url path] atomically:atomically];
}
- (id)subdataWithRange:(NSRange)range
{
    if (range.location > _length)
        return [NSData data];
    unsigned long length = range.length;
    if (range.location + length > _length)
        length = _length - range.location;
    return [NSData dataWithBytes:(const char *)_bytes + range.location
                          length:length];
}
- (BOOL)isEqualToData:(id)other
{
    if (!other || ![other isKindOfClass:[NSData class]])
        return NO;
    NSData *data = (NSData *)other;
    return data->_length == _length &&
           (_length == 0 || memcmp(data->_bytes, _bytes, _length) == 0);
}
- (id)description
{
    return [NSString stringWithFormat:@"<NSData: %lu bytes>", _length];
}
@end

/* ---------------------------------------------------------- files & URLs */

@implementation NSFileManager
+ (NSFileManager *)defaultManager
{
    static NSFileManager *manager;
    if (!manager)
        manager = [[self alloc] init];
    return manager;
}
- (BOOL)fileExistsAtPath:(id)path
{
    return iosim_fs_exists(iosim_string_cstr(path));
}
- (BOOL)fileExistsAtPath:(id)path isDirectory:(BOOL *)isDirectory
{
    const char *c = iosim_string_cstr(path);
    BOOL exists = iosim_fs_exists(c);
    if (isDirectory)
        *isDirectory = exists && iosim_fs_is_dir(c);
    return exists;
}
- (BOOL)createDirectoryAtPath:(id)path
    withIntermediateDirectories:(BOOL)createIntermediates
                     attributes:(id)attributes error:(id *)error
{
    (void)attributes;
    int rc = iosim_fs_mkdir(iosim_string_cstr(path),
                            createIntermediates ? 1 : 0);
    if (rc != 0 && error)
        *error = [NSError errorWithDomain:@"NSCocoaErrorDomain" code:513
                                   userInfo:nil];
    return rc == 0;
}
- (id)contentsOfDirectoryAtPath:(id)path error:(id *)error
{
    char buf[16384];
    int n = iosim_fs_list(iosim_string_cstr(path), buf, sizeof(buf));
    if (n < 0)
    {
        if (error)
            *error = [NSError errorWithDomain:@"NSCocoaErrorDomain" code:260
                                       userInfo:nil];
        return nil;
    }
    NSMutableArray *items = [NSMutableArray array];
    char *line = buf;
    while (*line)
    {
        char *end = line;
        while (*end && *end != '\n')
            end++;
        char saved = *end;
        *end = 0;
        [items addObject:[NSString stringWithUTF8String:line]];
        *end = saved;
        line = saved ? end + 1 : end;
    }
    return items;
}
- (BOOL)removeItemAtPath:(id)path error:(id *)error
{
    int rc = iosim_fs_remove(iosim_string_cstr(path));
    if (rc != 0 && error)
        *error = [NSError errorWithDomain:@"NSCocoaErrorDomain" code:4
                                   userInfo:nil];
    return rc == 0;
}
- (BOOL)moveItemAtPath:(id)fromPath toPath:(id)toPath error:(id *)error
{
    int rc = iosim_fs_rename(iosim_string_cstr(fromPath),
                             iosim_string_cstr(toPath));
    if (rc != 0 && error)
        *error = [NSError errorWithDomain:@"NSCocoaErrorDomain" code:4
                                   userInfo:nil];
    return rc == 0;
}
- (BOOL)copyItemAtPath:(id)fromPath toPath:(id)toPath error:(id *)error
{
    NSData *data = [NSData dataWithContentsOfFile:fromPath];
    if (!data || ![data writeToFile:toPath atomically:NO])
    {
        if (error)
            *error = [NSError errorWithDomain:@"NSCocoaErrorDomain" code:4
                                       userInfo:nil];
        return NO;
    }
    return YES;
}
- (id)contentsAtPath:(id)path
{
    return [NSData dataWithContentsOfFile:path];
}
- (BOOL)createFileAtPath:(id)path contents:(id)contents attributes:(id)attrs
{
    (void)attrs;
    NSData *data = contents ? contents : [NSData data];
    return [data writeToFile:path atomically:NO];
}
- (id)currentDirectoryPath
{
    const char *home = getenv("HOME");
    return [NSString stringWithUTF8String:home && *home ? home : "."];
}
@end

@implementation NSURL
+ (id)fileURLWithPath:(id)path
{
    NSURL *url = [[self alloc] init];
    url->_path = path;
    url->_fileURL = YES;
    const char *c = iosim_string_cstr(path);
    char buf[1024];
    snprintf(buf, sizeof(buf), "file://%s", c);
    url->_string = [NSString stringWithUTF8String:buf];
    return url;
}
+ (id)URLWithString:(id)string
{
    NSURL *url = [[self alloc] init];
    url->_string = string;
    const char *c = iosim_string_cstr(string);
    url->_fileURL = strncmp(c, "file://", 7) == 0;
    url->_path = url->_fileURL
        ? [NSString stringWithUTF8String:c + 7] : nil;
    return url;
}
- (id)path { return _path; }
- (id)absoluteString { return _string; }
- (BOOL)isFileURL { return _fileURL; }
- (id)lastPathComponent { return [_path lastPathComponent]; }
- (id)pathExtension { return [_path pathExtension]; }
- (id)URLByAppendingPathComponent:(id)component
{
    return [NSURL fileURLWithPath:
        [_path stringByAppendingPathComponent:component]];
}
- (id)URLByDeletingLastPathComponent
{
    return [NSURL fileURLWithPath:[_path stringByDeletingLastPathComponent]];
}
- (id)description { return _string; }
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

/* ------------------------------------------------------------ dates */

extern double iosim_wall_time(void);

static void iosim_civil_from_days(long long z, int *year, int *month, int *day)
{
    z += 719468;
    long long era = (z >= 0 ? z : z - 146096) / 146097;
    unsigned long long doe = (unsigned long long)(z - era * 146097);
    unsigned long long yoe =
        (doe - doe / 1460 + doe / 36524 - doe / 146096) / 365;
    long long y = (long long)yoe + era * 400;
    unsigned long long doy =
        doe - (365 * yoe + yoe / 4 - yoe / 100);
    unsigned long long mp = (5 * doy + 2) / 153;
    unsigned long long d = doy - (153 * mp + 2) / 5 + 1;
    unsigned long long m = mp < 10 ? mp + 3 : mp - 9;
    *year = (int)(y + (m <= 2));
    *month = (int)m;
    *day = (int)d;
}

@implementation NSDate
+ (id)date
{
    return [[self alloc] initWithTimeIntervalSince1970:iosim_wall_time()];
}
+ (id)dateWithTimeIntervalSince1970:(double)interval
{
    return [[self alloc] initWithTimeIntervalSince1970:interval];
}
- (id)initWithTimeIntervalSince1970:(double)interval
{
    self = [super init];
    if (self)
        _timeIntervalSince1970 = interval;
    return self;
}
- (double)timeIntervalSince1970 { return _timeIntervalSince1970; }
- (double)timeIntervalSinceNow
{
    return _timeIntervalSince1970 - iosim_wall_time();
}
@end

@implementation NSDateFormatter
- (void)setDateFormat:(id)format { _dateFormat = format; }
- (id)dateFormat { return _dateFormat; }
- (id)stringFromDate:(NSDate *)date
{
    if (!date)
        return @"";
    const char *fmt = iosim_string_cstr(_dateFormat);
    if (!fmt)
        fmt = "yyyy-MM-dd HH:mm:ss";
    double seconds = date->_timeIntervalSince1970;
    long long isecs = (long long)seconds;
    if (seconds < 0 && seconds != (double)isecs)
        isecs--;
    long long days = isecs / 86400;
    long long sod = isecs % 86400;
    if (sod < 0)
    {
        sod += 86400;
        days--;
    }
    int year = 1970, month = 1, day = 1;
    iosim_civil_from_days(days, &year, &month, &day);
    int hour = (int)(sod / 3600);
    int minute = (int)((sod % 3600) / 60);
    int second = (int)(sod % 60);
    char out[192];
    int o = 0;
    for (int i = 0; fmt[i] && o < 180;)
    {
        char c = fmt[i];
        int run = 1;
        while (fmt[i + run] == c)
            run++;
        if (c == 'y')
        {
            if (run >= 4)
                o += snprintf(out + o, sizeof(out) - (unsigned long)o, "%04d",
                              year);
            else
                o += snprintf(out + o, sizeof(out) - (unsigned long)o, "%02d",
                              year % 100);
        }
        else if (c == 'M')
        {
            if (run >= 2)
                o += snprintf(out + o, sizeof(out) - (unsigned long)o, "%02d",
                              month);
            else
                o += snprintf(out + o, sizeof(out) - (unsigned long)o, "%d",
                              month);
        }
        else if (c == 'd')
        {
            if (run >= 2)
                o += snprintf(out + o, sizeof(out) - (unsigned long)o, "%02d",
                              day);
            else
                o += snprintf(out + o, sizeof(out) - (unsigned long)o, "%d",
                              day);
        }
        else if (c == 'H')
        {
            if (run >= 2)
                o += snprintf(out + o, sizeof(out) - (unsigned long)o, "%02d",
                              hour);
            else
                o += snprintf(out + o, sizeof(out) - (unsigned long)o, "%d",
                              hour);
        }
        else if (c == 'm')
        {
            if (run >= 2)
                o += snprintf(out + o, sizeof(out) - (unsigned long)o, "%02d",
                              minute);
            else
                o += snprintf(out + o, sizeof(out) - (unsigned long)o, "%d",
                              minute);
        }
        else if (c == 's')
        {
            if (run >= 2)
                o += snprintf(out + o, sizeof(out) - (unsigned long)o, "%02d",
                              second);
            else
                o += snprintf(out + o, sizeof(out) - (unsigned long)o, "%d",
                              second);
        }
        else
        {
            int n = run;
            while (n-- > 0 && o < 180)
                out[o++] = c;
        }
        i += run;
    }
    out[o] = 0;
    return [NSString stringWithUTF8String:out];
}
@end

@implementation NSError
+ (id)errorWithDomain:(id)domain code:(long)code userInfo:(id)userInfo
{
    NSError *error = [[self alloc] init];
    error->_domain = domain;
    error->_code = code;
    error->_userInfo = userInfo;
    return error;
}
- (id)domain { return _domain; }
- (long)code { return _code; }
- (id)userInfo { return _userInfo; }
- (id)localizedDescription
{
    if (_userInfo &&
        [(id)_userInfo respondsToSelector:@selector(objectForKey:)])
        return [(id)_userInfo objectForKey:@"NSLocalizedDescription"];
    return @"";
}
@end

/* ---------------------------------------------------- JSON serialization */

static BOOL json_write_indent(NSMutableString *out, BOOL pretty, int depth)
{
    if (!pretty)
        return YES;
    [out appendString:@"\n"];
    for (int i = 0; i < depth; i++)
        [out appendString:@"  "];
    return YES;
}

static void json_write_string(NSMutableString *out, const char *s)
{
    [out appendString:@"\""];
    char buf[16];
    for (const unsigned char *p = (const unsigned char *)(s ? s : ""); *p; p++)
    {
        if (*p == '"')
            [out appendString:@"\\\""];
        else if (*p == '\\')
            [out appendString:@"\\\\"];
        else if (*p == '\n')
            [out appendString:@"\\n"];
        else if (*p == '\r')
            [out appendString:@"\\r"];
        else if (*p == '\t')
            [out appendString:@"\\t"];
        else if (*p < 0x20)
        {
            snprintf(buf, sizeof(buf), "\\u%04x", *p);
            [out appendString:[NSString stringWithUTF8String:buf]];
        }
        else
        {
            char one[2] = {(char)*p, 0};
            [out appendString:[NSString stringWithUTF8String:one]];
        }
    }
    [out appendString:@"\""];
}

static BOOL json_write_value(NSMutableString *out, id value, BOOL pretty,
                             int depth)
{
    if (!value || [value isKindOfClass:[NSNull class]])
    {
        [out appendString:@"null"];
        return YES;
    }
    if ([value isKindOfClass:[NSString class]])
    {
        json_write_string(out, iosim_string_cstr(value));
        return YES;
    }
    if ([value isKindOfClass:[NSNumber class]])
    {
        NSNumber *number = (NSNumber *)value;
        char buf[64];
        if (number->_kind == 2)
            [out appendString:number->_ival ? @"true" : @"false"];
        else if (number->_kind == 1)
        {
            snprintf(buf, sizeof(buf), "%.15g", number->_dval);
            [out appendString:[NSString stringWithUTF8String:buf]];
        }
        else
        {
            snprintf(buf, sizeof(buf), "%lld", number->_ival);
            [out appendString:[NSString stringWithUTF8String:buf]];
        }
        return YES;
    }
    if ([value isKindOfClass:[NSArray class]])
    {
        NSArray *array = (NSArray *)value;
        unsigned long count = [array count];
        if (count == 0)
        {
            [out appendString:@"[]"];
            return YES;
        }
        [out appendString:@"["];
        for (unsigned long i = 0; i < count; i++)
        {
            if (i)
                [out appendString:@","];
            json_write_indent(out, pretty, depth + 1);
            if (!json_write_value(out, [array objectAtIndex:i], pretty,
                                  depth + 1))
                return NO;
        }
        json_write_indent(out, pretty, depth);
        [out appendString:@"]"];
        return YES;
    }
    if ([value isKindOfClass:[NSDictionary class]])
    {
        NSDictionary *dict = (NSDictionary *)value;
        NSArray *keys = [dict allKeys];
        unsigned long count = [keys count];
        if (count == 0)
        {
            [out appendString:@"{}"];
            return YES;
        }
        [out appendString:@"{"];
        for (unsigned long i = 0; i < count; i++)
        {
            id key = [keys objectAtIndex:i];
            if (![key isKindOfClass:[NSString class]])
                return NO;
            if (i)
                [out appendString:@","];
            json_write_indent(out, pretty, depth + 1);
            json_write_string(out, iosim_string_cstr(key));
            [out appendString:pretty ? @": " : @":"];
            if (!json_write_value(out, [dict objectForKey:key], pretty,
                                  depth + 1))
                return NO;
        }
        json_write_indent(out, pretty, depth);
        [out appendString:@"}"];
        return YES;
    }
    return NO;
}

struct json_state {
    const char *s;
    unsigned long i;
    unsigned long n;
    int error;
};

static void json_skip_ws(struct json_state *p)
{
    while (p->i < p->n)
    {
        char c = p->s[p->i];
        if (c != ' ' && c != '\t' && c != '\n' && c != '\r')
            break;
        p->i++;
    }
}

static id json_parse_string(struct json_state *p)
{
    if (p->i >= p->n || p->s[p->i] != '"')
    {
        p->error = 1;
        return nil;
    }
    p->i++;
    char *buf = malloc(p->n - p->i + 1);
    unsigned long len = 0;
    while (p->i < p->n && p->s[p->i] != '"')
    {
        unsigned char c = (unsigned char)p->s[p->i++];
        if (c == '\\')
        {
            if (p->i >= p->n)
                break;
            c = (unsigned char)p->s[p->i++];
            if (c == 'n') c = '\n';
            else if (c == 't') c = '\t';
            else if (c == 'r') c = '\r';
            else if (c == 'b') c = '\b';
            else if (c == 'f') c = '\f';
            else if (c == 'u')
            {
                unsigned int code = 0;
                for (int k = 0; k < 4; k++)
                {
                    if (p->i >= p->n)
                    {
                        p->error = 1;
                        break;
                    }
                    char h = p->s[p->i++];
                    unsigned int v = 0;
                    if (h >= '0' && h <= '9') v = (unsigned int)(h - '0');
                    else if (h >= 'a' && h <= 'f')
                        v = (unsigned int)(h - 'a' + 10);
                    else if (h >= 'A' && h <= 'F')
                        v = (unsigned int)(h - 'A' + 10);
                    else
                        p->error = 1;
                    code = code * 16 + v;
                }
                if (code < 0x80)
                    buf[len++] = (char)code;
                else if (code < 0x800)
                {
                    buf[len++] = (char)(0xC0 | (code >> 6));
                    buf[len++] = (char)(0x80 | (code & 0x3F));
                }
                else
                {
                    buf[len++] = (char)(0xE0 | (code >> 12));
                    buf[len++] = (char)(0x80 | ((code >> 6) & 0x3F));
                    buf[len++] = (char)(0x80 | (code & 0x3F));
                }
                continue;
            }
            else if (c != '"' && c != '\\' && c != '/')
            {
                p->error = 1;
                break;
            }
        }
        else if (c < 0x20)
        {
            p->error = 1;
            break;
        }
        buf[len++] = (char)c;
    }
    if (p->i >= p->n || p->s[p->i] != '"')
        p->error = 1;
    else
        p->i++;
    if (p->error)
    {
        free(buf);
        return nil;
    }
    buf[len] = 0;
    NSString *string = [NSString stringWithUTF8String:buf];
    free(buf);
    return string;
}

static id json_parse_value(struct json_state *p, int depth)
{
    if (depth > 64)
    {
        p->error = 1;
        return nil;
    }
    json_skip_ws(p);
    if (p->i >= p->n)
    {
        p->error = 1;
        return nil;
    }
    char c = p->s[p->i];
    if (c == '"')
        return json_parse_string(p);
    if (c == '{')
    {
        p->i++;
        NSMutableDictionary *dict = [NSMutableDictionary dictionary];
        json_skip_ws(p);
        if (p->i < p->n && p->s[p->i] == '}')
        {
            p->i++;
            return dict;
        }
        while (!p->error)
        {
            json_skip_ws(p);
            id key = json_parse_string(p);
            if (!key)
                break;
            json_skip_ws(p);
            if (p->i >= p->n || p->s[p->i] != ':')
            {
                p->error = 1;
                break;
            }
            p->i++;
            id value = json_parse_value(p, depth + 1);
            if (!value)
                break;
            [dict setObject:value forKey:key];
            json_skip_ws(p);
            if (p->i < p->n && p->s[p->i] == ',')
            {
                p->i++;
                continue;
            }
            if (p->i < p->n && p->s[p->i] == '}')
            {
                p->i++;
                return dict;
            }
            p->error = 1;
            break;
        }
        return nil;
    }
    if (c == '[')
    {
        p->i++;
        NSMutableArray *array = [NSMutableArray array];
        json_skip_ws(p);
        if (p->i < p->n && p->s[p->i] == ']')
        {
            p->i++;
            return array;
        }
        while (!p->error)
        {
            id value = json_parse_value(p, depth + 1);
            if (!value)
                break;
            [array addObject:value];
            json_skip_ws(p);
            if (p->i < p->n && p->s[p->i] == ',')
            {
                p->i++;
                continue;
            }
            if (p->i < p->n && p->s[p->i] == ']')
            {
                p->i++;
                return array;
            }
            p->error = 1;
            break;
        }
        return nil;
    }
    if (c == 't' && p->n - p->i >= 4 && strncmp(p->s + p->i, "true", 4) == 0)
    {
        p->i += 4;
        return [NSNumber numberWithBool:YES];
    }
    if (c == 'f' && p->n - p->i >= 5 &&
        strncmp(p->s + p->i, "false", 5) == 0)
    {
        p->i += 5;
        return [NSNumber numberWithBool:NO];
    }
    if (c == 'n' && p->n - p->i >= 4 &&
        strncmp(p->s + p->i, "null", 4) == 0)
    {
        p->i += 4;
        return [NSNull null];
    }
    if (c == '-' || (c >= '0' && c <= '9'))
    {
        char *end = 0;
        double value = strtod(p->s + p->i, &end);
        if (!end || end == p->s + p->i)
        {
            p->error = 1;
            return nil;
        }
        unsigned long start = p->i;
        int integral = 1;
        for (const char *q = p->s + start; q < end; q++)
            if (*q == '.' || *q == 'e' || *q == 'E')
                integral = 0;
        p->i = (unsigned long)(end - p->s);
        if (integral)
            return [NSNumber numberWithLongLong:(long long)value];
        return [NSNumber numberWithDouble:value];
    }
    p->error = 1;
    return nil;
}

@implementation NSJSONSerialization
+ (BOOL)isValidJSONObject:(id)object
{
    NSMutableString *scratch = [NSMutableString string];
    return object && json_write_value(scratch, object, NO, 0);
}
+ (id)dataWithJSONObject:(id)object options:(unsigned long)options
                   error:(id *)error
{
    (void)options;
    NSMutableString *text = [NSMutableString string];
    if (!object || !json_write_value(text, object, NO, 0))
    {
        if (error)
            *error = [NSError errorWithDomain:@"NSCocoaErrorDomain" code:3840
                                       userInfo:nil];
        return nil;
    }
    return [text dataUsingEncoding:4];
}
+ (id)JSONObjectWithData:(id)data options:(unsigned long)options
                   error:(id *)error
{
    (void)options;
    if (!data)
        return nil;
    struct json_state p;
    p.s = (const char *)[data bytes];
    p.i = 0;
    p.n = [data length];
    p.error = 0;
    id value = json_parse_value(&p, 0);
    json_skip_ws(&p);
    if (!value || p.error || p.i != p.n)
    {
        if (error)
            *error = [NSError errorWithDomain:@"NSCocoaErrorDomain" code:3840
                                       userInfo:nil];
        return nil;
    }
    return value;
}
@end

@implementation NSNull
+ (id)null
{
    static NSNull *null;
    if (!null)
        null = [[self alloc] init];
    return null;
}
- (BOOL)isEqual:(id)other { return other == self; }
- (unsigned long)hash { return 0; }
- (id)description { return @"<null>"; }
@end
