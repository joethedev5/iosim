/* An arm64 class inheriting NSObject whose methods are reached from
 * native x86_64 code. -performSelector: and NSArray's -isEqual: comparison
 * both run in Foundation and send a message back into the arm64 image;
 * the reverse bridge marshals the saved x86 registers per the method type
 * encoding and returns the scalar result. The isEqual: method itself calls
 * a native method, so the bridge is re-entered in both directions.
 * Prints "c=1 hit=42" and exits 77. */
extern void *objc_getClass(const char *name);
extern char *sel_registerName(const char *name);
extern int printf(const char *fmt, ...);
typedef int BOOL;

@interface NSObject {
    Class isa;
}
+ (id)alloc;
- (id)init;
- (id)performSelector:(SEL)s withObject:(id)o;
- (BOOL)isEqual:(id)other;
- (id)description;
@end

@interface NSMutableArray : NSObject
+ (id)array;
- (void)addObject:(id)o;
- (BOOL)containsObject:(id)o;
@end

static id g_want;
static int g_hit;

@interface Rev : NSObject
@end

@implementation Rev
- (void)hit:(id)x { g_hit = (x == g_want) ? 42 : 41; }
- (BOOL)isEqual:(id)other
{
    if (other != g_want)
        return 0;
    /* A native method reached from inside the reverse-dispatched IMP. */
    return [other description] != 0;
}
@end

int main(void)
{
    id revCls = (id)objc_getClass("Rev");
    id r1 = [[revCls alloc] init];
    id r2 = [[revCls alloc] init];
    g_want = r2;
    id arr = [(id)objc_getClass("NSMutableArray") array];
    [arr addObject:r1];
    int c = [arr containsObject:r2] ? 1 : 0;
    [r1 performSelector:(SEL)sel_registerName("hit:") withObject:r2];
    printf("c=%d hit=%d\n", c, g_hit);
    return (c == 1 && g_hit == 42) ? 77 : 66;
}
