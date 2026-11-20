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
extern double iosim_wall_time(void);
extern int usleep(unsigned int usec);
extern int pthread_main_np(void);
extern void *_Block_copy(void *block);
extern void _Block_release(void *block);
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
extern int   open(const char *path, int flags, ...);
extern long  read(int fd, void *buf, unsigned long count);
extern long  write(int fd, const void *buf, unsigned long count);
extern long long lseek(int fd, long long offset, int whence);
extern int   close(int fd);
extern int   fsync(int fd);
extern int   ftruncate(int fd, long long length);
extern unsigned long strlen(const char *s);
extern int   strcmp(const char *a, const char *b);
extern int   strncmp(const char *a, const char *b, unsigned long n);
extern char *strchr(const char *s, int c);
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
extern const char *class_getName(void *cls);
extern char *getenv(const char *name);

static NSTimer *g_timers[64];
static int g_timer_count;


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
- (void)performSelector:(SEL)selector withObject:(id)argument
{
    if (!selector)
        return;
    ((void (*)(id, SEL, id))objc_msgSend)(self, selector, argument);
}
- (void)performSelector:(SEL)selector withObject:(id)argument
             afterDelay:(double)delay
{
    if (!selector)
        return;
    NSTimer *timer = [NSTimer scheduledTimerWithTimeInterval:delay
                                                      target:self
                                                    selector:selector
                                                    userInfo:nil
                                                     repeats:NO];
    timer->_isPerform = YES;
    timer->_performArgument = argument;
}
+ (void)cancelPreviousPerformRequestsWithTarget:(id)target
                                       selector:(SEL)selector
                                         object:(id)argument
{
    for (int i = 0; i < g_timer_count; i++)
    {
        NSTimer *timer = g_timers[i];
        if (!timer || !timer->_isPerform || timer->_target != target)
            continue;
        if (selector && timer->_selector != selector)
            continue;
        if (argument && timer->_performArgument != argument)
            continue;
        [timer invalidate];
    }
}
+ (void)cancelPreviousPerformRequestsWithTarget:(id)target
{
    [self cancelPreviousPerformRequestsWithTarget:target
                                         selector:0
                                           object:0];
}
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
    if (iosim_fs_exists(buf) != 1)
        return nil;
    return [NSString stringWithUTF8String:buf];
}
@end

/* ---------------------------------------------------------- user defaults */

/* Preference domain: the app's bundle id from XPC_SERVICE_NAME when the
 * system UI launched it, otherwise the launchd spawn domain. Apps see their
 * domain through $HOME/Library/Preferences/<domain>.plist, which is where
 * cfprefsd keeps them on the simulator. */
static void defaults_path(char *out, unsigned long cap)
{
    const char *home = getenv("HOME");
    if (!home || !*home)
        home = "/tmp";
    char domain[128];
    snprintf(domain, sizeof(domain), "%s", "com.iosim.defaults");
    const char *service = getenv("XPC_SERVICE_NAME");
    if (service && *service)
    {
        const char *colon = 0;
        const char *bracket = 0;
        for (const char *q = service; *q; q++)
        {
            if (*q == ':' && !colon)
                colon = q;
            if (*q == '[' && colon)
            {
                bracket = q;
                break;
            }
        }
        if (colon)
        {
            const char *begin = colon + 1;
            const char *end = bracket ? bracket : begin + strlen(begin);
            unsigned long n = (unsigned long)(end - begin);
            if (n > 0 && n < sizeof(domain))
            {
                memcpy(domain, begin, n);
                domain[n] = 0;
            }
        }
    }
    snprintf(out, cap, "%s/Library/Preferences/%s.plist", home, domain);
}

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
    {
        _store = [NSMutableDictionary dictionary];
        char path[1024];
        defaults_path(path, sizeof(path));
        unsigned char *bytes = 0;
        unsigned long length = 0;
        if (iosim_fs_read(path, &bytes, &length) == 0)
        {
            NSData *data = [[NSData alloc] initWithBytes:bytes length:length];
            id plist = [NSPropertyListSerialization
                propertyListWithData:data options:0 format:0 error:0];
            if (plist && [plist isKindOfClass:[NSDictionary class]])
            {
                NSArray *keys = [plist allKeys];
                for (unsigned long i = 0; i < [keys count]; i++)
                {
                    id key = [keys objectAtIndex:i];
                    [_store setObject:[plist objectForKey:key] forKey:key];
                }
            }
            free(bytes);
        }
    }
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
    [self synchronize];
}
- (id)objectForKey:(id)key { return key ? [_store objectForKey:key] : nil; }
- (void)removeObjectForKey:(id)key
{
    if (!key)
        return;
    [_store removeObjectForKey:key];
    [self synchronize];
}
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
- (void)synchronize
{
    char path[1024];
    defaults_path(path, sizeof(path));
    char dir[1024];
    snprintf(dir, sizeof(dir), "%s", path);
    char *slash = 0;
    for (char *q = dir; *q; q++)
        if (*q == '/')
            slash = q;
    if (slash)
    {
        *slash = 0;
        iosim_fs_mkdir(dir, 1);
    }
    NSData *data = [NSPropertyListSerialization
        dataWithPropertyList:_store format:NSPropertyListXMLFormat_v1_0
        options:0 error:0];
    if (data)
        [data writeToFile:[NSString stringWithUTF8String:path] atomically:YES];
}
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

@implementation NSMutableData
+ (id)dataWithCapacity:(unsigned long)capacity
{
    return [[self alloc] initWithCapacity:capacity];
}
- (id)initWithCapacity:(unsigned long)capacity
{
    self = [super init];
    if (self)
    {
        _capacity = capacity < 16 ? 16 : capacity;
        _bytes = malloc(_capacity + 1);
        if (!_bytes)
            _capacity = 0;
        else
            ((char *)_bytes)[0] = 0;
    }
    return self;
}
- (void)appendBytes:(const void *)bytes length:(unsigned long)length
{
    if (!bytes || !length)
        return;
    if (_length + length > _capacity)
    {
        unsigned long capacity = _capacity ? _capacity : 16;
        while (capacity < _length + length)
            capacity *= 2;
        void *grown = realloc(_bytes, capacity + 1);
        if (!grown)
            return;
        _bytes = grown;
        _capacity = capacity;
    }
    memcpy((char *)_bytes + _length, bytes, length);
    _length += length;
    ((char *)_bytes)[_length] = 0;
}
- (void)appendData:(id)data
{
    if (data)
        [self appendBytes:[data bytes] length:[data length]];
}
- (void *)mutableBytes { return _bytes; }
- (void)setLength:(unsigned long)length
{
    if (length > _capacity)
    {
        unsigned long capacity = _capacity ? _capacity : 16;
        while (capacity < length)
            capacity *= 2;
        void *grown = realloc(_bytes, capacity + 1);
        if (!grown)
            return;
        _bytes = grown;
        _capacity = capacity;
    }
    if (_bytes && length > _length)
        memset((char *)_bytes + _length, 0, length - _length);
    _length = length;
    if (_bytes)
        ((char *)_bytes)[_length] = 0;
}
@end

/* ---------------------------------------------------------- files & URLs */

/* NSFileHandle sits on real host descriptors so reads, writes, seeks and
 * truncation share one offset. The open flags are the host's (Linux) values,
 * since the descriptor crosses into the host through the symbol fallback. */
#define FHO_RDONLY 0
#define FHO_WRONLY 1
#define FHO_RDWR   2
#define FHO_CREAT  64
#define FHO_TRUNC  512

@implementation NSFileHandle
- (id)initWithFileDescriptor:(int)fd
{
    self = [super init];
    if (self)
    {
        _fd = fd;
        _closed = fd < 0;
    }
    return self;
}
+ (id)fileHandleForReadingAtPath:(NSString *)path
{
    int fd = open(iosim_string_cstr(path), FHO_RDONLY);
    if (fd < 0)
        return nil;
    return [[self alloc] initWithFileDescriptor:fd];
}
+ (id)fileHandleForWritingAtPath:(NSString *)path
{
    int fd = open(iosim_string_cstr(path),
                  FHO_WRONLY | FHO_CREAT | FHO_TRUNC, 0666);
    if (fd < 0)
        return nil;
    return [[self alloc] initWithFileDescriptor:fd];
}
+ (id)fileHandleForUpdatingAtPath:(NSString *)path
{
    int fd = open(iosim_string_cstr(path), FHO_RDWR | FHO_CREAT);
    if (fd < 0)
        return nil;
    return [[self alloc] initWithFileDescriptor:fd];
}
+ (id)fileHandleWithStandardInput
{
    return [[self alloc] initWithFileDescriptor:0];
}
+ (id)fileHandleWithStandardOutput
{
    return [[self alloc] initWithFileDescriptor:1];
}
+ (id)fileHandleWithStandardError
{
    return [[self alloc] initWithFileDescriptor:2];
}
+ (id)fileHandleWithNullDevice
{
    int fd = open("/dev/null", FHO_RDWR);
    if (fd < 0)
        return nil;
    return [[self alloc] initWithFileDescriptor:fd];
}
- (NSData *)readDataOfLength:(unsigned long)length
{
    if (_closed || _fd < 0 || length == 0)
        return [NSData data];
    unsigned char *buf = malloc(length);
    if (!buf)
        return [NSData data];
    unsigned long got = 0;
    while (got < length)
    {
        long n = read(_fd, buf + got, length - got);
        if (n <= 0)
            break;
        got += (unsigned long)n;
    }
    NSData *data = [NSData dataWithBytes:buf length:got];
    free(buf);
    return data;
}
- (NSData *)readDataToEndOfFile
{
    if (_closed || _fd < 0)
        return [NSData data];
    unsigned long cap = 4096, len = 0;
    unsigned char *buf = malloc(cap);
    if (!buf)
        return [NSData data];
    for (;;)
    {
        if (len == cap)
        {
            unsigned long grown = cap * 2;
            unsigned char *next = realloc(buf, grown);
            if (!next)
                break;
            buf = next;
            cap = grown;
        }
        long n = read(_fd, buf + len, cap - len);
        if (n <= 0)
            break;
        len += (unsigned long)n;
    }
    NSData *data = [NSData dataWithBytes:buf length:len];
    free(buf);
    return data;
}
- (void)writeData:(NSData *)data
{
    if (_closed || _fd < 0 || !data)
        return;
    const unsigned char *bytes = (const unsigned char *)data->_bytes;
    unsigned long len = data->_length;
    unsigned long put = 0;
    while (put < len)
    {
        long n = write(_fd, bytes + put, len - put);
        if (n <= 0)
            break;
        put += (unsigned long)n;
    }
}
- (unsigned long long)offsetInFile
{
    if (_closed || _fd < 0)
        return 0;
    long long off = lseek(_fd, 0, 1);
    return off < 0 ? 0 : (unsigned long long)off;
}
- (unsigned long long)seekToEndOfFile
{
    if (_closed || _fd < 0)
        return 0;
    long long off = lseek(_fd, 0, 2);
    return off < 0 ? 0 : (unsigned long long)off;
}
- (void)seekToFileOffset:(unsigned long long)offset
{
    if (_closed || _fd < 0)
        return;
    lseek(_fd, (long long)offset, 0);
}
- (void)truncateFileAtOffset:(unsigned long long)offset
{
    if (_closed || _fd < 0)
        return;
    ftruncate(_fd, (long long)offset);
}
- (void)synchronizeFile
{
    if (_closed || _fd < 0)
        return;
    fsync(_fd);
}
- (int)fileDescriptor { return _closed ? -1 : _fd; }
- (void)closeFile
{
    if (!_closed && _fd >= 0)
        close(_fd);
    _closed = YES;
}
@end

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

/* A block observer is stored in the center's table with a nil selector; the
 * token keeps the heap-copied block and doubles as the removal handle. */
@interface NSNotificationBlockToken : NSObject {
@public
    void *_block;
}
@end

@implementation NSNotificationBlockToken
@end

@implementation NSNotification
+ (id)notificationWithName:(id)name object:(id)object
{
    return [self notificationWithName:name object:object userInfo:nil];
}
+ (id)notificationWithName:(id)name object:(id)object userInfo:(id)userInfo
{
    NSNotification *n = [[self alloc] init];
    n->_name = name;
    n->_object = object;
    n->_userInfo = userInfo;
    return n;
}
- (id)name { return _name; }
- (id)object { return _object; }
- (id)userInfo { return _userInfo; }
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
- (id)addObserverForName:(id)name object:(id)object queue:(id)queue
              usingBlock:(void (^)(NSNotification *note))block
{
    (void)queue;
    if (_count >= 64 || !block)
        return nil;
    NSNotificationBlockToken *token =
        [[NSNotificationBlockToken alloc] init];
    token->_block = _Block_copy((void *)block);
    _observers[_count] = token;
    _selectors[_count] = (SEL)0;
    _names[_count] = name;
    _objects[_count] = object;
    _count++;
    return token;
}
static void notification_center_remove(NSNotificationCenter *center, int i)
{
    for (int j = i; j + 1 < center->_count; j++)
    {
        center->_observers[j] = center->_observers[j + 1];
        center->_selectors[j] = center->_selectors[j + 1];
        center->_names[j] = center->_names[j + 1];
        center->_objects[j] = center->_objects[j + 1];
    }
    center->_count--;
}
- (void)removeObserver:(id)observer
{
    for (int i = 0; i < _count; i++)
        if (_observers[i] == observer)
        {
            notification_center_remove(self, i);
            i--;
        }
}
- (void)removeObserver:(id)observer name:(id)name object:(id)object
{
    for (int i = 0; i < _count; i++)
    {
        if (observer && _observers[i] != observer)
            continue;
        if (name && !(_names[i] && objects_equal(_names[i], name)))
            continue;
        if (object && _objects[i] != object)
            continue;
        notification_center_remove(self, i);
        i--;
    }
}
- (void)postNotification:(NSNotification *)note
{
    if (!note)
        return;
    id name = note->_name, object = note->_object;
    for (int i = 0; i < _count; i++)
    {
        if (_names[i] && !objects_equal(_names[i], name))
            continue;
        if (_objects[i] && _objects[i] != object)
            continue;
        if (_selectors[i])
        {
            void (*imp)(id, SEL, id) = (void (*)(id, SEL, id))objc_msgSend;
            imp(_observers[i], _selectors[i], note);
        }
        else
        {
            NSNotificationBlockToken *token = _observers[i];
            if (token && token->_block)
                ((void (^)(id))token->_block)(note);
        }
    }
}
- (void)postNotificationName:(id)name object:(id)object
{
    [self postNotificationName:name object:object userInfo:nil];
}
- (void)postNotificationName:(id)name object:(id)object userInfo:(id)userInfo
{
    [self postNotification:
        [NSNotification notificationWithName:name object:object
                                    userInfo:userInfo]];
}
@end

/* ---------------------------------------------------------------- Timer */

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
    if (_isPerform)
        imp(_target, _selector, _performArgument);
    else
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

/* ------------------------------------------------------- run loop & threads */

id NSDefaultRunLoopMode = @"NSDefaultRunLoopMode";

@implementation NSRunLoop
+ (NSRunLoop *)currentRunLoop
{
    static NSRunLoop *loop;
    if (!loop)
        loop = [[self alloc] init];
    return loop;
}
+ (NSRunLoop *)mainRunLoop { return [self currentRunLoop]; }
- (void)addTimer:(NSTimer *)timer forMode:(id)mode
{
    (void)timer;
    (void)mode;
}
- (BOOL)runMode:(id)mode beforeDate:(NSDate *)limitDate
{
    (void)mode;
    double limit = limitDate ? [limitDate timeIntervalSince1970]
                             : iosim_wall_time() + 1.0;
    while (iosim_wall_time() < limit)
    {
        if (iosim_foundation_tick() > 0)
            return YES;
        usleep(2000);
    }
    return NO;
}
- (void)runUntilDate:(NSDate *)limitDate
{
    double limit = limitDate ? [limitDate timeIntervalSince1970]
                             : iosim_wall_time();
    while (iosim_wall_time() < limit)
    {
        iosim_foundation_tick();
        usleep(2000);
    }
}
- (void)run
{
    for (;;)
    {
        iosim_foundation_tick();
        usleep(2000);
    }
}
@end

@implementation NSThread
+ (NSThread *)currentThread
{
    static NSThread *thread;
    if (!thread)
        thread = [[self alloc] init];
    return thread;
}
+ (NSThread *)mainThread { return [self currentThread]; }
+ (BOOL)isMainThread { return pthread_main_np() ? YES : NO; }
+ (void)sleepForTimeInterval:(double)interval
{
    if (interval > 0)
        usleep((unsigned int)(interval * 1000000.0));
}
@end

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
+ (id)dateWithTimeIntervalSinceNow:(double)interval
{
    return [[self alloc] initWithTimeIntervalSince1970:
                iosim_wall_time() + interval];
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

static long long days_from_civil(long long y, int m, int d);

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
- (NSDate *)dateFromString:(id)string
{
    const char *fmt = iosim_string_cstr(_dateFormat);
    const char *text = iosim_string_cstr(string);
    if (!fmt || !text)
        return nil;
    int year = 1970, month = 1, day = 1;
    int hour = 0, minute = 0, second = 0;
    int i = 0, p = 0;
    while (fmt[i])
    {
        char c = fmt[i];
        int run = 1;
        while (fmt[i + run] == c)
            run++;
        if (c == 'y' || c == 'M' || c == 'd' || c == 'H' || c == 'm' ||
            c == 's')
        {
            int value = 0, digits = 0;
            int limit = run >= 4 ? 4 : 2;
            while (text[p] >= '0' && text[p] <= '9' && digits < limit)
            {
                value = value * 10 + (text[p] - '0');
                p++;
                digits++;
            }
            if (digits == 0)
                return nil;
            if (c == 'y')
            {
                if (run == 2)
                    year = value < 69 ? 2000 + value : 1900 + value;
                else
                    year = value;
            }
            else if (c == 'M')
                month = value;
            else if (c == 'd')
                day = value;
            else if (c == 'H')
                hour = value;
            else if (c == 'm')
                minute = value;
            else
                second = value;
        }
        else if (c == ' ')
        {
            while (text[p] == ' ')
                p++;
        }
        else
        {
            while (text[p] == ' ')
                p++;
            if (text[p] == c)
                p++;
            else if (text[p] && strchr("/-:.", c) &&
                     strchr("/-:.", text[p]))
                p++;
            else if (text[p] != 0)
                return nil;
        }
        i += run;
    }
    if (month < 1 || month > 12 || day < 1 || day > 31 || hour > 23 ||
        minute > 59 || second > 59)
        return nil;
    long long seconds = days_from_civil(year, month, day) * 86400 +
                        (long long)hour * 3600 + minute * 60 + second;
    return [NSDate dateWithTimeIntervalSince1970:(double)seconds];
}
@end

static double number_formatter_pow10(int digits)
{
    double value = 1.0;
    for (int i = 0; i < digits; i++)
        value *= 10.0;
    return value;
}

@implementation NSNumberFormatter
- (id)init
{
    self = [super init];
    if (self)
    {
        _numberStyle = NSNumberFormatterNoStyle;
        _maximumFractionDigits = 3;
        _minimumFractionDigits = 0;
        _usesGroupingSeparator = YES;
    }
    return self;
}
- (void)setNumberStyle:(long)style { _numberStyle = style; }
- (long)numberStyle { return _numberStyle; }
- (void)setMaximumFractionDigits:(long)digits
{
    _maximumFractionDigits = digits > 0 ? digits : 0;
}
- (long)maximumFractionDigits { return _maximumFractionDigits; }
- (void)setMinimumFractionDigits:(long)digits
{
    _minimumFractionDigits = digits > 0 ? digits : 0;
}
- (long)minimumFractionDigits { return _minimumFractionDigits; }
- (void)setUsesGroupingSeparator:(BOOL)uses
{
    _usesGroupingSeparator = uses ? YES : NO;
}
- (BOOL)usesGroupingSeparator { return _usesGroupingSeparator; }
- (void)setCurrencySymbol:(id)symbol { _currencySymbol = symbol; }
- (id)currencySymbol { return _currencySymbol ? _currencySymbol : @"$"; }
- (id)stringFromNumber:(NSNumber *)number
{
    if (!number)
        return @"";
    double value = [number doubleValue];
    long maxDigits = _maximumFractionDigits;
    long minDigits = _minimumFractionDigits;
    if (_numberStyle == NSNumberFormatterCurrencyStyle)
    {
        if (maxDigits <= 0)
            maxDigits = 2;
        if (minDigits <= 0)
            minDigits = 2;
    }
    else if (_numberStyle == NSNumberFormatterPercentStyle)
        value *= 100.0;
    else if (_numberStyle == NSNumberFormatterNoStyle)
    {
        maxDigits = 0;
        minDigits = 0;
    }
    if (maxDigits > 9)
        maxDigits = 9;
    if (minDigits > maxDigits)
        minDigits = maxDigits;
    int negative = value < 0;
    if (negative)
        value = -value;
    double intPart = __builtin_floor(value);
    double frac = value - intPart;
    long long scaled =
        (long long)(frac * number_formatter_pow10((int)maxDigits) + 0.5);
    if (scaled >= (long long)number_formatter_pow10((int)maxDigits))
    {
        intPart += 1;
        scaled = 0;
    }
    unsigned long long ip = (unsigned long long)intPart;
    char intStr[32];
    int ilen = 0;
    if (ip == 0)
        intStr[ilen++] = '0';
    while (ip && ilen < 31)
    {
        intStr[ilen++] = (char)('0' + (int)(ip % 10));
        ip /= 10;
    }
    for (int i = 0; i < ilen / 2; i++)
    {
        char tmp = intStr[i];
        intStr[i] = intStr[ilen - 1 - i];
        intStr[ilen - 1 - i] = tmp;
    }
    int fracDigits = (int)maxDigits;
    while (fracDigits > minDigits && fracDigits > 0 && scaled % 10 == 0)
    {
        scaled /= 10;
        fracDigits--;
    }
    char out[96];
    int o = 0;
    if (negative)
        out[o++] = '-';
    if (_numberStyle == NSNumberFormatterCurrencyStyle)
    {
        const char *symbol = iosim_string_cstr(self.currencySymbol);
        for (int i = 0; symbol && symbol[i] && o < 88; i++)
            out[o++] = symbol[i];
    }
    for (int i = 0; i < ilen && o < 88; i++)
    {
        if (_usesGroupingSeparator &&
            _numberStyle != NSNumberFormatterNoStyle && i > 0 &&
            (ilen - i) % 3 == 0)
            out[o++] = ',';
        out[o++] = intStr[i];
    }
    if (fracDigits > 0 && o < 88)
    {
        char fbuf[16];
        snprintf(fbuf, sizeof fbuf, "%0*lld", fracDigits, scaled);
        out[o++] = '.';
        for (int i = 0; fbuf[i] && o < 92; i++)
            out[o++] = fbuf[i];
    }
    if (_numberStyle == NSNumberFormatterPercentStyle && o < 94)
        out[o++] = '%';
    out[o] = 0;
    return [NSString stringWithUTF8String:out];
}
- (NSNumber *)numberFromString:(NSString *)string
{
    const char *s = iosim_string_cstr(string);
    if (!s)
        return nil;
    int negative = 0;
    int seen = 0, fracDigits = 0, inFrac = 0;
    double value = 0;
    const char *p = s;
    while (*p == ' ' || *p == '$')
        p++;
    if (*p == '-')
    {
        negative = 1;
        p++;
    }
    else if (*p == '+')
        p++;
    for (; *p; p++)
    {
        if (*p >= '0' && *p <= '9')
        {
            seen = 1;
            value = value * 10 + (*p - '0');
            if (inFrac)
                fracDigits++;
        }
        else if (*p == '.')
            inFrac = 1;
        else if (*p == ',' || *p == ' ')
            continue;
        else if (*p == '%' || *p == '$')
            continue;
        else
            return nil;
    }
    if (!seen)
        return nil;
    while (fracDigits-- > 0)
        value /= 10.0;
    if (_numberStyle == NSNumberFormatterPercentStyle)
        value /= 100.0;
    if (negative)
        value = -value;
    return [NSNumber numberWithDouble:value];
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

/* ------------------------------------------------- xml property lists */

static void plist_write_escaped(NSMutableString *out, const char *text)
{
    if (!text)
        text = "";
    char chunk[64];
    int used = 0;
    for (const char *p = text; ; p++)
    {
        char c = *p;
        if (c == 0 || c == '&' || c == '<' || c == '>' || c == '"' || c == '\'')
        {
            if (used)
            {
                chunk[used] = 0;
                [out appendString:[NSString stringWithUTF8String:chunk]];
                used = 0;
            }
            if (c == 0)
                break;
            if (c == '&') [out appendString:@"&amp;"];
            else if (c == '<') [out appendString:@"&lt;"];
            else if (c == '>') [out appendString:@"&gt;"];
            else if (c == '"') [out appendString:@"&quot;"];
            else [out appendString:@"&apos;"];
            continue;
        }
        chunk[used++] = c;
        if (used == (int)sizeof(chunk) - 1)
        {
            chunk[used] = 0;
            [out appendString:[NSString stringWithUTF8String:chunk]];
            used = 0;
        }
    }
}

static void plist_indent(NSMutableString *out, int depth)
{
    [out appendString:@"\n"];
    for (int i = 0; i < depth; i++)
        [out appendString:@"\t"];
}

static void civil_from_days(long long z, long long *out_year, int *out_month,
                            int *out_day)
{
    z += 719468;
    long long era = (z >= 0 ? z : z - 146096) / 146097;
    unsigned long doe = (unsigned long)(z - era * 146097);
    unsigned long yoe = (doe - doe / 1460 + doe / 36524 - doe / 146096) / 365;
    long long year = (long long)yoe + era * 400;
    unsigned long doy = doe - (365 * yoe + yoe / 4 - yoe / 100);
    unsigned long mp = (5 * doy + 2) / 153;
    unsigned long day = doy - (153 * mp + 2) / 5 + 1;
    unsigned long month = mp + (mp < 10 ? 3 : (unsigned long)-9);
    year += (month <= 2);
    *out_year = year;
    *out_month = (int)month;
    *out_day = (int)day;
}

static long long days_from_civil(long long y, int m, int d)
{
    y -= m <= 2;
    long long era = (y >= 0 ? y : y - 399) / 400;
    unsigned long yoe = (unsigned long)(y - era * 400);
    unsigned long doy =
        (unsigned long)((153 * (m + (m > 2 ? -3 : 9)) + 2) / 5 + d - 1);
    unsigned long doe = yoe * 365 + yoe / 4 - yoe / 100 + doy;
    return era * 146097 + (long long)doe - 719468;
}

static const char base64_chars[] =
    "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

static void plist_write_base64(NSMutableString *out, const unsigned char *bytes,
                               unsigned long length)
{
    char quad[5];
    for (unsigned long i = 0; i < length; i += 3)
    {
        unsigned long v = (unsigned long)bytes[i] << 16;
        if (i + 1 < length)
            v |= (unsigned long)bytes[i + 1] << 8;
        if (i + 2 < length)
            v |= bytes[i + 2];
        quad[0] = base64_chars[(v >> 18) & 63];
        quad[1] = base64_chars[(v >> 12) & 63];
        quad[2] = i + 1 < length ? base64_chars[(v >> 6) & 63] : '=';
        quad[3] = i + 2 < length ? base64_chars[v & 63] : '=';
        quad[4] = 0;
        [out appendString:[NSString stringWithUTF8String:quad]];
    }
}

static BOOL plist_write_value(NSMutableString *out, id value, int depth)
{
    if (!value || [value isKindOfClass:[NSNull class]])
        return NO;
    if ([value isKindOfClass:[NSString class]])
    {
        [out appendString:@"<string>"];
        plist_write_escaped(out, iosim_string_cstr(value));
        [out appendString:@"</string>"];
        return YES;
    }
    if ([value isKindOfClass:[NSNumber class]])
    {
        NSNumber *number = (NSNumber *)value;
        char buf[64];
        if (number->_kind == 2)
            [out appendString:number->_ival ? @"<true/>" : @"<false/>"];
        else if (number->_kind == 1)
        {
            snprintf(buf, sizeof(buf), "<real>%.15g</real>", number->_dval);
            [out appendString:[NSString stringWithUTF8String:buf]];
        }
        else
        {
            snprintf(buf, sizeof(buf), "<integer>%lld</integer>",
                     number->_ival);
            [out appendString:[NSString stringWithUTF8String:buf]];
        }
        return YES;
    }
    if ([value isKindOfClass:[NSDate class]])
    {
        double interval = [(NSDate *)value timeIntervalSince1970];
        long long secs = (long long)interval;
        if (secs < 0)
            secs = 0;
        long long days = secs / 86400;
        long long rem = secs % 86400;
        long long year;
        int month, day;
        civil_from_days(days, &year, &month, &day);
        char buf[64];
        snprintf(buf, sizeof(buf), "<date>%04lld-%02d-%02dT%02lld:%02lld:%02lldZ</date>",
                 year, month, day, rem / 3600, (rem / 60) % 60, rem % 60);
        [out appendString:[NSString stringWithUTF8String:buf]];
        return YES;
    }
    if ([value isKindOfClass:[NSData class]])
    {
        NSData *data = (NSData *)value;
        [out appendString:@"<data>"];
        plist_write_base64(out, (const unsigned char *)[data bytes],
                           [data length]);
        [out appendString:@"</data>"];
        return YES;
    }
    if ([value isKindOfClass:[NSArray class]])
    {
        NSArray *array = (NSArray *)value;
        unsigned long count = [array count];
        if (count == 0)
        {
            [out appendString:@"<array/>"];
            return YES;
        }
        [out appendString:@"<array>"];
        for (unsigned long i = 0; i < count; i++)
        {
            plist_indent(out, depth + 1);
            if (!plist_write_value(out, [array objectAtIndex:i], depth + 1))
                return NO;
        }
        plist_indent(out, depth);
        [out appendString:@"</array>"];
        return YES;
    }
    if ([value isKindOfClass:[NSDictionary class]])
    {
        NSDictionary *dict = (NSDictionary *)value;
        NSArray *keys = [dict allKeys];
        unsigned long count = [keys count];
        if (count == 0)
        {
            [out appendString:@"<dict/>"];
            return YES;
        }
        [out appendString:@"<dict>"];
        for (unsigned long i = 0; i < count; i++)
        {
            id key = [keys objectAtIndex:i];
            if (![key isKindOfClass:[NSString class]])
                return NO;
            plist_indent(out, depth + 1);
            [out appendString:@"<key>"];
            plist_write_escaped(out, iosim_string_cstr(key));
            [out appendString:@"</key>"];
            plist_indent(out, depth + 1);
            if (!plist_write_value(out, [dict objectForKey:key], depth + 1))
                return NO;
        }
        plist_indent(out, depth);
        [out appendString:@"</dict>"];
        return YES;
    }
    return NO;
}

struct plist_state {
    const char *s;
    unsigned long i;
    unsigned long n;
    int error;
};

static int plist_has(struct plist_state *p, const char *tag)
{
    unsigned long len = strlen(tag);
    if (p->i + len > p->n)
        return 0;
    return memcmp(p->s + p->i, tag, len) == 0;
}

static void plist_skip_misc(struct plist_state *p)
{
    for (;;)
    {
        while (p->i < p->n)
        {
            char c = p->s[p->i];
            if (c != ' ' && c != '\t' && c != '\n' && c != '\r')
                break;
            p->i++;
        }
        if (p->i + 2 <= p->n && p->s[p->i] == '<' && p->s[p->i + 1] == '?')
        {
            while (p->i + 1 < p->n &&
                   !(p->s[p->i] == '?' && p->s[p->i + 1] == '>'))
                p->i++;
            p->i += 2;
            continue;
        }
        if (p->i + 4 <= p->n && memcmp(p->s + p->i, "<!--", 4) == 0)
        {
            while (p->i + 2 < p->n &&
                   !(p->s[p->i] == '-' && p->s[p->i + 1] == '-' &&
                     p->s[p->i + 2] == '>'))
                p->i++;
            p->i += 3;
            continue;
        }
        if (p->i + 9 <= p->n && memcmp(p->s + p->i, "<!DOCTYPE", 9) == 0)
        {
            while (p->i < p->n && p->s[p->i] != '>')
                p->i++;
            if (p->i < p->n)
                p->i++;
            continue;
        }
        break;
    }
}

static NSString *plist_unescape(const char *s, unsigned long len)
{
    char *buf = malloc(len + 1);
    if (!buf)
        return nil;
    unsigned long o = 0;
    for (unsigned long i = 0; i < len; i++)
    {
        if (s[i] != '&')
        {
            buf[o++] = s[i];
            continue;
        }
        if (i + 5 <= len && memcmp(s + i, "&amp;", 5) == 0)
        {
            buf[o++] = '&';
            i += 4;
        }
        else if (i + 4 <= len && memcmp(s + i, "&lt;", 4) == 0)
        {
            buf[o++] = '<';
            i += 3;
        }
        else if (i + 4 <= len && memcmp(s + i, "&gt;", 4) == 0)
        {
            buf[o++] = '>';
            i += 3;
        }
        else if (i + 6 <= len && memcmp(s + i, "&quot;", 6) == 0)
        {
            buf[o++] = '"';
            i += 5;
        }
        else if (i + 6 <= len && memcmp(s + i, "&apos;", 6) == 0)
        {
            buf[o++] = '\'';
            i += 5;
        }
        else
            buf[o++] = '&';
    }
    buf[o] = 0;
    NSString *text = [NSString stringWithUTF8String:buf];
    free(buf);
    return text;
}

static int plist_raw_until(struct plist_state *p, const char *close,
                           const char **out, unsigned long *out_len)
{
    unsigned long clen = strlen(close);
    unsigned long start = p->i;
    while (p->i + clen <= p->n && memcmp(p->s + p->i, close, clen) != 0)
        p->i++;
    if (p->i + clen > p->n)
    {
        p->error = 1;
        return -1;
    }
    *out = p->s + start;
    *out_len = p->i - start;
    p->i += clen;
    return 0;
}

static long long plist_parse_integer(const char *s, unsigned long len)
{
    unsigned long i = 0;
    int negative = 0;
    long long value = 0;
    while (i < len && (s[i] == ' ' || s[i] == '\t' || s[i] == '\n'))
        i++;
    if (i < len && (s[i] == '-' || s[i] == '+'))
    {
        negative = s[i] == '-';
        i++;
    }
    while (i < len && s[i] >= '0' && s[i] <= '9')
    {
        value = value * 10 + (s[i] - '0');
        i++;
    }
    return negative ? -value : value;
}

static double plist_parse_date(const char *s, unsigned long len)
{
    if (len < 19)
        return 0;
    long long year = plist_parse_integer(s, 4);
    int month = (int)plist_parse_integer(s + 5, 2);
    int day = (int)plist_parse_integer(s + 8, 2);
    int hour = (int)plist_parse_integer(s + 11, 2);
    int minute = (int)plist_parse_integer(s + 14, 2);
    int second = (int)plist_parse_integer(s + 17, 2);
    if (year < 1 || month < 1 || month > 12 || day < 1 || day > 31)
        return 0;
    return (double)(days_from_civil(year, month, day) * 86400 +
                    hour * 3600 + minute * 60 + second);
}

static int base64_value(char c)
{
    if (c >= 'A' && c <= 'Z') return c - 'A';
    if (c >= 'a' && c <= 'z') return c - 'a' + 26;
    if (c >= '0' && c <= '9') return c - '0' + 52;
    if (c == '+') return 62;
    if (c == '/') return 63;
    return -1;
}

static NSData *plist_base64_decode(const char *s, unsigned long len)
{
    unsigned char *bytes = malloc(len / 4 * 3 + 4);
    if (!bytes)
        return nil;
    unsigned long o = 0;
    int quad[4];
    int q = 0, pad = 0;
    for (unsigned long i = 0; i < len; i++)
    {
        char c = s[i];
        if (c == ' ' || c == '\t' || c == '\n' || c == '\r')
            continue;
        if (c == '=')
        {
            quad[q++] = -2;
            pad++;
        }
        else
        {
            int v = base64_value(c);
            if (v < 0)
            {
                free(bytes);
                return nil;
            }
            quad[q++] = v;
        }
        if (q == 4)
        {
            long v = ((long)quad[0] << 18) | ((long)quad[1] << 12) |
                     ((long)(quad[2] < 0 ? 0 : quad[2]) << 6) |
                     (long)(quad[3] < 0 ? 0 : quad[3]);
            bytes[o++] = (unsigned char)((v >> 16) & 255);
            if (pad < 2)
                bytes[o++] = (unsigned char)((v >> 8) & 255);
            if (pad < 1)
                bytes[o++] = (unsigned char)(v & 255);
            q = 0;
            pad = 0;
        }
    }
    NSData *data = [[NSData alloc] initWithBytes:bytes length:o];
    free(bytes);
    return data;
}

static id plist_parse_value(struct plist_state *p, int depth)
{
    if (depth > 64)
    {
        p->error = 1;
        return nil;
    }
    plist_skip_misc(p);
    if (plist_has(p, "<dict/>"))
    {
        p->i += 7;
        return [NSMutableDictionary dictionary];
    }
    if (plist_has(p, "<dict>"))
    {
        p->i += 6;
        NSMutableDictionary *dict = [NSMutableDictionary dictionary];
        for (;;)
        {
            plist_skip_misc(p);
            if (plist_has(p, "</dict>"))
            {
                p->i += 7;
                return dict;
            }
            if (!plist_has(p, "<key>"))
            {
                p->error = 1;
                return nil;
            }
            p->i += 5;
            const char *raw = 0;
            unsigned long raw_len = 0;
            if (plist_raw_until(p, "</key>", &raw, &raw_len) != 0)
                return nil;
            NSString *key = plist_unescape(raw, raw_len);
            id value = plist_parse_value(p, depth + 1);
            if (!key || !value)
                return nil;
            [dict setObject:value forKey:key];
        }
    }
    if (plist_has(p, "<array/>"))
    {
        p->i += 8;
        return [NSMutableArray array];
    }
    if (plist_has(p, "<array>"))
    {
        p->i += 7;
        NSMutableArray *array = [NSMutableArray array];
        for (;;)
        {
            plist_skip_misc(p);
            if (plist_has(p, "</array>"))
            {
                p->i += 8;
                return array;
            }
            id value = plist_parse_value(p, depth + 1);
            if (!value)
                return nil;
            [array addObject:value];
        }
    }
    if (plist_has(p, "<string/>"))
    {
        p->i += 9;
        return [NSString stringWithUTF8String:""];
    }
    if (plist_has(p, "<string>"))
    {
        p->i += 8;
        const char *raw = 0;
        unsigned long raw_len = 0;
        if (plist_raw_until(p, "</string>", &raw, &raw_len) != 0)
            return nil;
        return plist_unescape(raw, raw_len);
    }
    if (plist_has(p, "<integer>"))
    {
        p->i += 9;
        const char *raw = 0;
        unsigned long raw_len = 0;
        if (plist_raw_until(p, "</integer>", &raw, &raw_len) != 0)
            return nil;
        return [NSNumber numberWithLongLong:plist_parse_integer(raw, raw_len)];
    }
    if (plist_has(p, "<real>"))
    {
        p->i += 6;
        const char *raw = 0;
        unsigned long raw_len = 0;
        if (plist_raw_until(p, "</real>", &raw, &raw_len) != 0)
            return nil;
        char buf[64];
        unsigned long n = raw_len < sizeof(buf) - 1 ? raw_len : sizeof(buf) - 1;
        memcpy(buf, raw, n);
        buf[n] = 0;
        return [NSNumber numberWithDouble:strtod(buf, 0)];
    }
    if (plist_has(p, "<true/>"))
    {
        p->i += 7;
        return [NSNumber numberWithBool:YES];
    }
    if (plist_has(p, "<false/>"))
    {
        p->i += 8;
        return [NSNumber numberWithBool:NO];
    }
    if (plist_has(p, "<true>"))
    {
        p->i += 6;
        if (!plist_has(p, "</true>"))
        {
            p->error = 1;
            return nil;
        }
        p->i += 7;
        return [NSNumber numberWithBool:YES];
    }
    if (plist_has(p, "<false>"))
    {
        p->i += 7;
        if (!plist_has(p, "</false>"))
        {
            p->error = 1;
            return nil;
        }
        p->i += 8;
        return [NSNumber numberWithBool:NO];
    }
    if (plist_has(p, "<data>"))
    {
        p->i += 6;
        const char *raw = 0;
        unsigned long raw_len = 0;
        if (plist_raw_until(p, "</data>", &raw, &raw_len) != 0)
            return nil;
        return plist_base64_decode(raw, raw_len);
    }
    if (plist_has(p, "<date>"))
    {
        p->i += 6;
        const char *raw = 0;
        unsigned long raw_len = 0;
        if (plist_raw_until(p, "</date>", &raw, &raw_len) != 0)
            return nil;
        return [NSDate dateWithTimeIntervalSince1970:
                    plist_parse_date(raw, raw_len)];
    }
    p->error = 1;
    return nil;
}

@implementation NSPropertyListSerialization
+ (id)dataWithPropertyList:(id)plist format:(unsigned long)format
                   options:(unsigned long)options error:(id *)error
{
    (void)format;
    (void)options;
    NSMutableString *text = [NSMutableString string];
    [text appendString:
        @"<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n"
        @"<!DOCTYPE plist PUBLIC \"-//Apple//DTD PLIST 1.0//EN\" "
        @"\"http://www.apple.com/DTDs/PropertyList-1.0.dtd\">\n"
        @"<plist version=\"1.0\">"];
    if (!plist)
    {
        if (error)
            *error = [NSError errorWithDomain:@"NSCocoaErrorDomain" code:3840
                                       userInfo:nil];
        return nil;
    }
    [text appendString:@"\n"];
    if (!plist_write_value(text, plist, 0))
    {
        if (error)
            *error = [NSError errorWithDomain:@"NSCocoaErrorDomain" code:3840
                                       userInfo:nil];
        return nil;
    }
    [text appendString:@"\n</plist>\n"];
    return [text dataUsingEncoding:4];
}
+ (id)propertyListWithData:(id)data options:(unsigned long)options
                    format:(unsigned long *)format error:(id *)error
{
    (void)options;
    if (!data || [data length] == 0)
    {
        if (error)
            *error = [NSError errorWithDomain:@"NSCocoaErrorDomain" code:3840
                                       userInfo:nil];
        return nil;
    }
    struct plist_state p;
    p.s = (const char *)[data bytes];
    p.i = 0;
    p.n = [data length];
    p.error = 0;
    plist_skip_misc(&p);
    if (!plist_has(&p, "<plist"))
    {
        if (error)
            *error = [NSError errorWithDomain:@"NSCocoaErrorDomain" code:3840
                                       userInfo:nil];
        return nil;
    }
    while (p.i < p.n && p.s[p.i] != '>')
        p.i++;
    if (p.i < p.n)
        p.i++;
    id value = plist_parse_value(&p, 0);
    plist_skip_misc(&p);
    if (!value || p.error || !plist_has(&p, "</plist>"))
    {
        if (error)
            *error = [NSError errorWithDomain:@"NSCocoaErrorDomain" code:3840
                                       userInfo:nil];
        return nil;
    }
    if (format)
        *format = NSPropertyListXMLFormat_v1_0;
    return value;
}
@end

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

/* ------------------------------------------------------ keyed archiving */

@implementation NSCoder
- (void)encodeObject:(id)object forKey:(id)key { (void)object; (void)key; }
- (void)encodeInteger:(long)value forKey:(id)key { (void)value; (void)key; }
- (void)encodeInt:(int)value forKey:(id)key { (void)value; (void)key; }
- (void)encodeBool:(BOOL)value forKey:(id)key { (void)value; (void)key; }
- (void)encodeFloat:(float)value forKey:(id)key { (void)value; (void)key; }
- (void)encodeDouble:(double)value forKey:(id)key { (void)value; (void)key; }
- (BOOL)containsValueForKey:(id)key { (void)key; return NO; }
- (id)decodeObjectForKey:(id)key { (void)key; return nil; }
- (long)decodeIntegerForKey:(id)key { (void)key; return 0; }
- (int)decodeIntForKey:(id)key { (void)key; return 0; }
- (BOOL)decodeBoolForKey:(id)key { (void)key; return NO; }
- (float)decodeFloatForKey:(id)key { (void)key; return 0; }
- (double)decodeDoubleForKey:(id)key { (void)key; return 0; }
@end

/* A UID reference in the archive plist: <dict><key>CF$UID</key><integer>N
 * </integer></dict>, the same shape Foundation writes. */
static id keyed_uid(long index)
{
    NSMutableDictionary *ref = [NSMutableDictionary dictionary];
    [ref setObject:[NSNumber numberWithInteger:index] forKey:@"CF$UID"];
    return ref;
}

static long keyed_uid_value(id value)
{
    if (!value || ![value isKindOfClass:[NSDictionary class]])
        return -1;
    NSDictionary *ref = (NSDictionary *)value;
    if ([ref count] != 1)
        return -1;
    id index = [ref objectForKey:@"CF$UID"];
    if (!index || ![index isKindOfClass:[NSNumber class]])
        return -1;
    return [index integerValue];
}

/* Append a class description ("$classname" plus its "$classes" chain) to
 * $objects once per name and return its index. */
static long keyed_class(NSKeyedArchiver *archiver, const char *name,
                        const char *superName)
{
    NSString *key = [NSString stringWithUTF8String:name];
    id known = [archiver->_classMap objectForKey:key];
    if (known)
        return [known integerValue];
    NSMutableArray *chain = [NSMutableArray array];
    [chain addObject:key];
    if (superName && *superName && strcmp(superName, name) != 0 &&
        strcmp(superName, "NSObject") != 0)
        [chain addObject:[NSString stringWithUTF8String:superName]];
    [chain addObject:@"NSObject"];
    NSMutableDictionary *entry = [NSMutableDictionary dictionary];
    [entry setObject:key forKey:@"$classname"];
    [entry setObject:chain forKey:@"$classes"];
    long index = (long)[archiver->_objects count];
    [archiver->_objects addObject:entry];
    [archiver->_classMap setObject:[NSNumber numberWithInteger:index]
                            forKey:key];
    return index;
}

static id keyed_archive_object(NSKeyedArchiver *archiver, id object);
static long keyed_find(NSKeyedArchiver *archiver, id object)
{
    unsigned long count = [archiver->_objects count];
    for (unsigned long i = 1; i < count; i++)
        if ([archiver->_objects objectAtIndex:i] == object)
            return (long)i;
    return -1;
}

static id keyed_append(NSKeyedArchiver *archiver, id entry)
{
    long index = (long)[archiver->_objects count];
    [archiver->_objects addObject:entry];
    return keyed_uid(index);
}

static id keyed_archive_object(NSKeyedArchiver *archiver, id object)
{
    if (!object)
        return keyed_uid(0);
    long found = keyed_find(archiver, object);
    if (found >= 0)
        return keyed_uid(found);

    /* Strings, numbers, data and dates live directly in $objects. */
    if ([object isKindOfClass:[NSString class]] ||
        [object isKindOfClass:[NSNumber class]] ||
        [object isKindOfClass:[NSData class]] ||
        [object isKindOfClass:[NSDate class]])
        return keyed_append(archiver, object);

    if ([object isKindOfClass:[NSNull class]])
    {
        NSMutableDictionary *entry = [NSMutableDictionary dictionary];
        [entry setObject:keyed_uid(keyed_class(archiver, "NSNull", "NSObject"))
                  forKey:@"$class"];
        return keyed_append(archiver, entry);
    }

    if ([object isKindOfClass:[NSArray class]])
    {
        const char *name =
            [object isKindOfClass:[NSMutableArray class]] ? "NSMutableArray"
                                                          : "NSArray";
        NSMutableDictionary *entry = [NSMutableDictionary dictionary];
        [entry setObject:keyed_uid(keyed_class(archiver, name, "NSArray"))
                  forKey:@"$class"];
        NSMutableArray *refs = [NSMutableArray array];
        [entry setObject:refs forKey:@"NS.objects"];
        /* Reserve the entry before encoding children so cycles resolve. */
        id ref = keyed_append(archiver, entry);
        NSArray *array = (NSArray *)object;
        for (unsigned long i = 0; i < [array count]; i++)
            [refs addObject:keyed_archive_object(archiver,
                                                 [array objectAtIndex:i])];
        return ref;
    }

    if ([object isKindOfClass:[NSDictionary class]])
    {
        const char *name = [object isKindOfClass:[NSMutableDictionary class]]
                               ? "NSMutableDictionary"
                               : "NSDictionary";
        NSMutableDictionary *entry = [NSMutableDictionary dictionary];
        [entry setObject:keyed_uid(keyed_class(archiver, name, "NSDictionary"))
                  forKey:@"$class"];
        NSMutableArray *keyRefs = [NSMutableArray array];
        NSMutableArray *valueRefs = [NSMutableArray array];
        [entry setObject:keyRefs forKey:@"NS.keys"];
        [entry setObject:valueRefs forKey:@"NS.objects"];
        id ref = keyed_append(archiver, entry);
        NSDictionary *dict = (NSDictionary *)object;
        NSArray *keys = [dict allKeys];
        for (unsigned long i = 0; i < [keys count]; i++)
        {
            id key = [keys objectAtIndex:i];
            [keyRefs addObject:keyed_archive_object(archiver, key)];
            [valueRefs addObject:keyed_archive_object(
                                     archiver, [dict objectForKey:key])];
        }
        return ref;
    }

    if ([object isKindOfClass:[NSSet class]])
    {
        const char *name = [object isKindOfClass:[NSMutableSet class]]
                               ? "NSMutableSet"
                               : "NSSet";
        NSMutableDictionary *entry = [NSMutableDictionary dictionary];
        [entry setObject:keyed_uid(keyed_class(archiver, name, "NSSet"))
                  forKey:@"$class"];
        NSMutableArray *refs = [NSMutableArray array];
        [entry setObject:refs forKey:@"NS.objects"];
        id ref = keyed_append(archiver, entry);
        NSArray *items = [(NSSet *)object allObjects];
        for (unsigned long i = 0; i < [items count]; i++)
            [refs addObject:keyed_archive_object(archiver,
                                                 [items objectAtIndex:i])];
        return ref;
    }

    /* Any other object encodes through NSCoding: the entry collects the
     * keys encodeWithCoder: writes while it is the current container. */
    void *cls = iosim_objc_class_of(object);
    const char *name = cls ? class_getName(cls) : 0;
    if (!name || !*name)
        return keyed_uid(0);
    void *super = iosim_objc_superclass(cls);
    const char *superName = super ? class_getName(super) : 0;
    NSMutableDictionary *entry = [NSMutableDictionary dictionary];
    [entry setObject:keyed_uid(keyed_class(archiver, name, superName))
              forKey:@"$class"];
    id ref = keyed_append(archiver, entry);
    if ([object respondsToSelector:@selector(encodeWithCoder:)])
    {
        id saved = archiver->_current;
        archiver->_current = entry;
        [object encodeWithCoder:archiver];
        archiver->_current = saved;
    }
    return ref;
}

@implementation NSKeyedArchiver
- (id)initForWritingWithMutableData:(id)data
{
    self = [super init];
    if (self)
    {
        _out = data;
        _objects = [NSMutableArray array];
        [_objects addObject:@"$null"];
        _top = [NSMutableDictionary dictionary];
        _classMap = [NSMutableDictionary dictionary];
    }
    return self;
}
- (id)init
{
    return [self initForWritingWithMutableData:[NSMutableData data]];
}
- (void)encodeObject:(id)object forKey:(id)key
{
    if (!key)
        return;
    id target = _current ? _current : _top;
    [target setObject:keyed_archive_object(self, object) forKey:key];
}
- (void)encodeInteger:(long)value forKey:(id)key
{
    if (key)
        [(id)(_current ? _current : _top)
            setObject:[NSNumber numberWithInteger:value]
            forKey:key];
}
- (void)encodeInt:(int)value forKey:(id)key
{
    [self encodeInteger:(long)value forKey:key];
}
- (void)encodeBool:(BOOL)value forKey:(id)key
{
    if (key)
        [(id)(_current ? _current : _top)
            setObject:[NSNumber numberWithBool:value]
            forKey:key];
}
- (void)encodeFloat:(float)value forKey:(id)key
{
    [self encodeDouble:(double)value forKey:key];
}
- (void)encodeDouble:(double)value forKey:(id)key
{
    if (key)
        [(id)(_current ? _current : _top)
            setObject:[NSNumber numberWithDouble:value]
            forKey:key];
}
- (void)finishEncoding
{
    NSMutableDictionary *archive = [NSMutableDictionary dictionary];
    [archive setObject:@"NSKeyedArchiver" forKey:@"$archiver"];
    [archive setObject:[NSNumber numberWithInteger:100000] forKey:@"$version"];
    [archive setObject:_top ? _top : [NSMutableDictionary dictionary]
                forKey:@"$top"];
    [archive setObject:_objects ? _objects : [NSMutableArray array]
                forKey:@"$objects"];
    id data = [NSPropertyListSerialization
        dataWithPropertyList:archive format:NSPropertyListXMLFormat_v1_0
        options:0 error:0];
    if (!data)
        return;
    if (_out)
        [_out appendData:data];
    else
        _out = data;
}
+ (id)archivedDataWithRootObject:(id)rootObject
{
    NSMutableData *out = [NSMutableData data];
    NSKeyedArchiver *archiver =
        [[self alloc] initForWritingWithMutableData:out];
    [archiver encodeObject:rootObject forKey:@"root"];
    [archiver finishEncoding];
    return out;
}
+ (id)archivedDataWithRootObject:(id)rootObject
             requiringSecureCoding:(BOOL)requiringSecureCoding
                             error:(id *)error
{
    (void)requiringSecureCoding;
    (void)error;
    return [self archivedDataWithRootObject:rootObject];
}
+ (BOOL)archiveRootObject:(id)rootObject toFile:(id)path
{
    id data = [self archivedDataWithRootObject:rootObject];
    return data ? [data writeToFile:path atomically:YES] : NO;
}
@end

static id keyed_resolve(NSKeyedUnarchiver *unarchiver, long index)
{
    if (index <= 0 || (unsigned long)index >= unarchiver->_objectCount)
        return nil;
    if (unarchiver->_state[index] == 2)
        return unarchiver->_resolved[index];
    if (unarchiver->_state[index] == 1)
        return unarchiver->_resolved[index];

    id entry = [unarchiver->_objects objectAtIndex:(unsigned long)index];
    if (!entry)
        return nil;
    if ([entry isKindOfClass:[NSString class]] ||
        [entry isKindOfClass:[NSNumber class]] ||
        [entry isKindOfClass:[NSData class]] ||
        [entry isKindOfClass:[NSDate class]])
    {
        unarchiver->_state[index] = 2;
        unarchiver->_resolved[index] = entry;
        return entry;
    }
    if (![entry isKindOfClass:[NSDictionary class]])
    {
        unarchiver->_state[index] = 2;
        unarchiver->_resolved[index] = entry;
        return entry;
    }

    long indirect = keyed_uid_value(entry);
    if (indirect >= 0)
    {
        id value = keyed_resolve(unarchiver, indirect);
        unarchiver->_state[index] = 2;
        unarchiver->_resolved[index] = value;
        return value;
    }

    long classIndex = keyed_uid_value([entry objectForKey:@"$class"]);
    id classEntry =
        classIndex > 0 && (unsigned long)classIndex < unarchiver->_objectCount
            ? [unarchiver->_objects objectAtIndex:(unsigned long)classIndex]
            : nil;
    id className = [classEntry isKindOfClass:[NSDictionary class]]
                       ? [(NSDictionary *)classEntry objectForKey:@"$classname"]
                       : nil;
    const char *name = iosim_string_cstr(className);

    if (strcmp(name, "NSNull") == 0)
    {
        id value = [NSNull null];
        unarchiver->_state[index] = 2;
        unarchiver->_resolved[index] = value;
        return value;
    }
    if (strcmp(name, "NSArray") == 0 || strcmp(name, "NSMutableArray") == 0)
    {
        NSMutableArray *array = [NSMutableArray array];
        unarchiver->_state[index] = 1;
        unarchiver->_resolved[index] = array;
        id refs = [entry objectForKey:@"NS.objects"];
        for (unsigned long i = 0; refs && i < [refs count]; i++)
        {
            long ref = keyed_uid_value([refs objectAtIndex:i]);
            id value = ref >= 0 ? keyed_resolve(unarchiver, ref)
                                : [refs objectAtIndex:i];
            [array addObject:value ? value : [NSNull null]];
        }
        unarchiver->_state[index] = 2;
        return array;
    }
    if (strcmp(name, "NSDictionary") == 0 ||
        strcmp(name, "NSMutableDictionary") == 0)
    {
        NSMutableDictionary *dict = [NSMutableDictionary dictionary];
        unarchiver->_state[index] = 1;
        unarchiver->_resolved[index] = dict;
        id keyRefs = [entry objectForKey:@"NS.keys"];
        id valueRefs = [entry objectForKey:@"NS.objects"];
        for (unsigned long i = 0; keyRefs && valueRefs && i < [keyRefs count] &&
                                   i < [valueRefs count]; i++)
        {
            long keyRef = keyed_uid_value([keyRefs objectAtIndex:i]);
            long valueRef = keyed_uid_value([valueRefs objectAtIndex:i]);
            id key = keyRef >= 0 ? keyed_resolve(unarchiver, keyRef)
                                 : [keyRefs objectAtIndex:i];
            id value = valueRef >= 0 ? keyed_resolve(unarchiver, valueRef)
                                     : [valueRefs objectAtIndex:i];
            if (key)
                [dict setObject:value ? value : [NSNull null] forKey:key];
        }
        unarchiver->_state[index] = 2;
        return dict;
    }
    if (strcmp(name, "NSSet") == 0 || strcmp(name, "NSMutableSet") == 0)
    {
        NSMutableSet *set = [NSMutableSet set];
        unarchiver->_state[index] = 1;
        unarchiver->_resolved[index] = set;
        id refs = [entry objectForKey:@"NS.objects"];
        for (unsigned long i = 0; refs && i < [refs count]; i++)
        {
            long ref = keyed_uid_value([refs objectAtIndex:i]);
            id value = ref >= 0 ? keyed_resolve(unarchiver, ref)
                                : [refs objectAtIndex:i];
            if (value)
                [set addObject:value];
        }
        unarchiver->_state[index] = 2;
        return set;
    }

    Class cls = (Class)objc_getClass(name);
    if (!cls)
        return nil;
    id object = [cls alloc];
    unarchiver->_state[index] = 1;
    unarchiver->_resolved[index] = object;
    if ([object respondsToSelector:@selector(initWithCoder:)])
    {
        id saved = unarchiver->_current;
        unarchiver->_current = entry;
        id decoded = [object initWithCoder:unarchiver];
        unarchiver->_current = saved;
        if (decoded)
            object = decoded;
    }
    unarchiver->_state[index] = 2;
    unarchiver->_resolved[index] = object;
    return object;
}

@implementation NSKeyedUnarchiver
- (id)initForReadingWithData:(id)data
{
    self = [super init];
    if (!self)
        return nil;
    id plist = [NSPropertyListSerialization
        propertyListWithData:data options:0 format:0 error:0];
    if (!plist || ![plist isKindOfClass:[NSDictionary class]])
        return nil;
    id objects = [plist objectForKey:@"$objects"];
    if (!objects || ![objects isKindOfClass:[NSArray class]])
        return nil;
    _objects = objects;
    _top = [plist objectForKey:@"$top"];
    _objectCount = [objects count];
    _resolved = calloc(_objectCount ? _objectCount : 1, sizeof(id));
    _state = calloc(_objectCount ? _objectCount : 1, 1);
    if (!_resolved || !_state)
        return nil;
    return self;
}
- (BOOL)containsValueForKey:(id)key
{
    id container = _current ? _current : _top;
    return key && container &&
           [(NSDictionary *)container objectForKey:key] != nil;
}
- (id)decodeObjectForKey:(id)key
{
    id container = _current ? _current : _top;
    if (!key || !container)
        return nil;
    id value = [(NSDictionary *)container objectForKey:key];
    if (!value)
        return nil;
    long ref = keyed_uid_value(value);
    if (ref >= 0)
        return keyed_resolve(self, ref);
    return value;
}
- (long)decodeIntegerForKey:(id)key
{
    id value = [self decodeObjectForKey:key];
    return value && [value respondsToSelector:@selector(integerValue)]
               ? [value integerValue]
               : 0;
}
- (int)decodeIntForKey:(id)key
{
    return (int)[self decodeIntegerForKey:key];
}
- (BOOL)decodeBoolForKey:(id)key
{
    id value = [self decodeObjectForKey:key];
    return value && [value respondsToSelector:@selector(boolValue)]
               ? [value boolValue]
               : NO;
}
- (float)decodeFloatForKey:(id)key
{
    return (float)[self decodeDoubleForKey:key];
}
- (double)decodeDoubleForKey:(id)key
{
    id value = [self decodeObjectForKey:key];
    return value && [value respondsToSelector:@selector(doubleValue)]
               ? [value doubleValue]
               : 0;
}
- (void)finishDecoding { }
+ (id)unarchiveObjectWithData:(id)data
{
    if (!data)
        return nil;
    NSKeyedUnarchiver *unarchiver =
        [[self alloc] initForReadingWithData:data];
    if (!unarchiver)
        return nil;
    id object = [unarchiver decodeObjectForKey:@"root"];
    [unarchiver finishDecoding];
    return object;
}
+ (id)unarchiveObjectWithFile:(id)path
{
    return [self unarchiveObjectWithData:[NSData dataWithContentsOfFile:path]];
}
+ (id)unarchivedObjectOfClass:(Class)cls fromData:(id)data error:(id *)error
{
    id object = [self unarchiveObjectWithData:data];
    if (cls && object && ![object isKindOfClass:cls])
    {
        if (error)
            *error = [NSError errorWithDomain:@"NSCocoaErrorDomain" code:4864
                                       userInfo:nil];
        return nil;
    }
    return object;
}
@end

/* ------------------------------------------------------------ calendars */

id NSCalendarIdentifierGregorian = @"NSCalendarIdentifierGregorian";

@implementation NSDateComponents
- (long)era { return _era; }
- (void)setEra:(long)value { _era = value; }
- (long)year { return _year; }
- (void)setYear:(long)value { _year = value; }
- (long)month { return _month; }
- (void)setMonth:(long)value { _month = value; }
- (long)day { return _day; }
- (void)setDay:(long)value { _day = value; }
- (long)hour { return _hour; }
- (void)setHour:(long)value { _hour = value; }
- (long)minute { return _minute; }
- (void)setMinute:(long)value { _minute = value; }
- (long)second { return _second; }
- (void)setSecond:(long)value { _second = value; }
- (long)nanosecond { return _nanosecond; }
- (void)setNanosecond:(long)value { _nanosecond = value; }
- (long)weekday { return _weekday; }
- (void)setWeekday:(long)value { _weekday = value; }
- (long)weekOfYear { return _weekOfYear; }
- (void)setWeekOfYear:(long)value { _weekOfYear = value; }
@end

@implementation NSCalendar
+ (NSCalendar *)currentCalendar
{
    static NSCalendar *calendar;
    if (!calendar)
        calendar = [[self alloc]
            initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
    return calendar;
}
+ (NSCalendar *)calendarWithIdentifier:(id)identifier
{
    return [[self alloc] initWithCalendarIdentifier:identifier];
}
- (id)initWithCalendarIdentifier:(id)identifier
{
    self = [super init];
    if (self)
        _identifier = identifier;
    return self;
}
- (id)calendarIdentifier { return _identifier; }
- (NSDateComponents *)components:(unsigned long)unitFlags
                        fromDate:(NSDate *)date
{
    NSDateComponents *components = [[NSDateComponents alloc] init];
    if (!date)
        return components;
    double seconds = [date timeIntervalSince1970];
    long long whole = (long long)seconds;
    if (seconds < 0 && seconds != (double)whole)
        whole--;
    long long days = whole / 86400;
    long long sod = whole % 86400;
    if (sod < 0)
    {
        sod += 86400;
        days--;
    }
    long long year;
    int month, day;
    civil_from_days(days, &year, &month, &day);
    long long weekday = ((days % 7) + 7 + 4) % 7 + 1;
    if (unitFlags & NSCalendarUnitEra)
        components->_era = 1;
    if (unitFlags & NSCalendarUnitYear)
        components->_year = (long)year;
    if (unitFlags & NSCalendarUnitMonth)
        components->_month = month;
    if (unitFlags & NSCalendarUnitDay)
        components->_day = day;
    if (unitFlags & NSCalendarUnitHour)
        components->_hour = (long)(sod / 3600);
    if (unitFlags & NSCalendarUnitMinute)
        components->_minute = (long)((sod / 60) % 60);
    if (unitFlags & NSCalendarUnitSecond)
        components->_second = (long)(sod % 60);
    if (unitFlags & NSCalendarUnitWeekday)
        components->_weekday = (long)weekday;
    if (unitFlags & NSCalendarUnitWeekOfYear)
    {
        long long iso = (weekday + 5) % 7 + 1; /* Monday = 1 */
        components->_weekOfYear = (long)((days - iso + 10) / 7);
    }
    if (unitFlags & NSCalendarUnitNanosecond)
    {
        double fraction = seconds - (double)whole;
        if (fraction < 0)
            fraction += 1.0;
        components->_nanosecond = (long)(fraction * 1e9);
    }
    return components;
}
- (NSDate *)dateFromComponents:(NSDateComponents *)components
{
    if (!components)
        return nil;
    long long year = components->_year ? components->_year : 1970;
    int month = components->_month > 0 ? (int)components->_month : 1;
    int day = components->_day > 0 ? (int)components->_day : 1;
    long long seconds = days_from_civil(year, month, day) * 86400 +
                        (long long)components->_hour * 3600 +
                        (long long)components->_minute * 60 +
                        components->_second;
    double value = (double)seconds;
    if (components->_nanosecond > 0)
        value += components->_nanosecond / 1e9;
    return [NSDate dateWithTimeIntervalSince1970:value];
}
@end

/* ----------------------------------------------------------- operations */

extern void *dispatch_get_global_queue(long identifier, unsigned long flags);
extern void *dispatch_get_main_queue(void);
extern void *dispatch_group_create(void);
extern void dispatch_group_async(void *group, void *queue, void *block);
extern long dispatch_group_wait(void *group, unsigned long long timeout);

@implementation NSOperation
- (void)start
{
    if (_cancelled || _finished)
        return;
    [self main];
    _finished = YES;
    if (_completionBlock)
        ((void (^)(void))_completionBlock)();
}
- (void)main { }
- (void)cancel { _cancelled = YES; }
- (BOOL)isCancelled { return _cancelled; }
- (BOOL)isFinished { return _finished; }
- (void)setCompletionBlock:(void (^)(void))block
{
    _completionBlock = block ? (id)_Block_copy((void *)block) : nil;
}
@end

@implementation NSBlockOperation
+ (id)blockOperationWithBlock:(void (^)(void))block
{
    NSBlockOperation *operation = [[self alloc] init];
    operation->_blocks = [NSMutableArray array];
    if (block)
        [(NSMutableArray *)operation->_blocks
            addObject:(id)_Block_copy((void *)block)];
    return operation;
}
- (void)addExecutionBlock:(void (^)(void))block
{
    if (!_blocks)
        _blocks = [NSMutableArray array];
    if (block)
        [(NSMutableArray *)_blocks addObject:(id)_Block_copy((void *)block)];
}
- (void)main
{
    if (!_blocks)
        return;
    for (unsigned long i = 0; i < [(NSArray *)_blocks count]; i++)
    {
        if (_cancelled)
            return;
        void (^block)(void) =
            (void (^)(void))[(NSArray *)_blocks objectAtIndex:i];
        block();
    }
}
@end

@implementation NSOperationQueue
+ (NSOperationQueue *)mainQueue
{
    static NSOperationQueue *queue;
    if (!queue)
    {
        queue = [[self alloc] init];
        queue->_queue = dispatch_get_main_queue();
    }
    return queue;
}
- (id)init
{
    self = [super init];
    if (self)
    {
        _group = dispatch_group_create();
        _queue = dispatch_get_global_queue(0, 0);
        _operations = [NSMutableArray array];
        _maxConcurrent = -1;
    }
    return self;
}
- (void)dispatchOperation:(NSOperation *)operation
{
    if (!operation || operation->_dispatched)
        return;
    operation->_dispatched = YES;
    _pending++;
    void (^run)(void) = ^{
        [operation start];
        _pending--;
    };
    dispatch_group_async(_group, _queue, (void *)run);
}
- (void)addOperation:(NSOperation *)operation
{
    if (!operation)
        return;
    [(NSMutableArray *)_operations addObject:operation];
    if (!_suspended)
        [self dispatchOperation:operation];
}
- (void)addOperationWithBlock:(void (^)(void))block
{
    [self addOperation:[NSBlockOperation blockOperationWithBlock:block]];
}
- (void)waitUntilAllOperationsAreFinished
{
    dispatch_group_wait(_group, ~0UL);
}
- (long)operationCount { return _pending; }
- (void)setMaxConcurrentOperationCount:(long)count { _maxConcurrent = count; }
- (long)maxConcurrentOperationCount { return _maxConcurrent; }
- (void)setSuspended:(BOOL)suspended
{
    _suspended = suspended;
    if (suspended)
        return;
    for (unsigned long i = 0; i < [(NSArray *)_operations count]; i++)
        [self dispatchOperation:
            (NSOperation *)[(NSArray *)_operations objectAtIndex:i]];
}
- (BOOL)isSuspended { return _suspended; }
- (void)cancelAllOperations
{
    for (unsigned long i = 0; i < [(NSArray *)_operations count]; i++)
        [(NSOperation *)[(NSArray *)_operations objectAtIndex:i] cancel];
}
@end
