/* Aggregates crossing the arm64-to-native bridge in both directions.
 * -rangeOfString: returns a sixteen-byte integer NSRange in x0/x1 and
 * -substringWithRange: takes one in x2/x3.
 * -setCenter:/ -center pass a sixteen-byte CGPoint HFA in d2/d3 and d0/d1.
 * -initWithFrame: takes a thirty-two-byte CGRect HFA on the stack while
 * -frame returns one in d0-d3.
 * A forty-eight-byte CGAffineTransform is not an HFA: it goes by pointer
 * and comes back through the x8 result buffer. Exits 93 when every value
 * survives the trip. */
typedef struct { double x, y; } CGPoint;
typedef struct { double width, height; } CGSize;
typedef struct { CGPoint origin; CGSize size; } CGRect;
typedef struct { unsigned long location, length; } NSRange;
typedef struct { double a, b, c, d, tx, ty; } CGAffineTransform;

extern void *objc_getClass(const char *name);
extern int printf(const char *fmt, ...);

@interface NSObject
+ (id)alloc;
- (id)init;
@end
@interface NSString : NSObject
+ (id)stringWithUTF8String:(const char *)s;
- (NSRange)rangeOfString:(id)needle;
- (id)substringWithRange:(NSRange)r;
- (const char *)UTF8String;
@end
@interface NSValue : NSObject
+ (id)valueWithCGAffineTransform:(CGAffineTransform)t;
- (CGAffineTransform)CGAffineTransformValue;
@end
@interface UIView : NSObject
- (id)initWithFrame:(CGRect)frame;
- (CGRect)frame;
- (void)setCenter:(CGPoint)c;
- (CGPoint)center;
@end

int main(void)
{
    id s = [(id)objc_getClass("NSString") stringWithUTF8String:"hello world"];
    id needle = [(id)objc_getClass("NSString") stringWithUTF8String:"world"];
    NSRange r = [(NSString *)s rangeOfString:needle];
    id sub = [(NSString *)s substringWithRange:r];
    const char *sc = [(NSString *)sub UTF8String];
    printf("sub=%s range=%lu,%lu\n", sc, r.location, r.length);

    id v = [[(id)objc_getClass("UIView") alloc] init];
    CGPoint p = {12.5, 34.5};
    [(UIView *)v setCenter:p];
    CGPoint ctr = [(UIView *)v center];
    CGRect rect = {{10, 20}, {100, 50}};
    id u = [[(id)objc_getClass("UIView") alloc] initWithFrame:rect];
    CGRect got = [(UIView *)u frame];
    printf("center=%.1f,%.1f frame=%.0f,%.0f,%.0f,%.0f\n", ctr.x, ctr.y,
           got.origin.x, got.origin.y, got.size.width, got.size.height);

    CGAffineTransform t = {1, 2, 3, 4, 5, 6};
    id nv = [(id)objc_getClass("NSValue") valueWithCGAffineTransform:t];
    CGAffineTransform back = [(NSValue *)nv CGAffineTransformValue];
    printf("transform=%.0f,%.0f,%.0f,%.0f,%.0f,%.0f\n", back.a, back.b,
           back.c, back.d, back.tx, back.ty);

    int ok = r.location == 6 && r.length == 5 && sc && sc[0] == 'w' &&
             ctr.x == 12.5 && ctr.y == 34.5 && got.origin.x == 10 &&
             got.origin.y == 20 && got.size.width == 100 &&
             got.size.height == 50 && back.a == 1 && back.b == 2 &&
             back.c == 3 && back.d == 4 && back.tx == 5 && back.ty == 6;
    return ok ? 93 : 19;
}
