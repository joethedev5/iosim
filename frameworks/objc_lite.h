#ifndef IOSIM_OBJC_LITE_H
#define IOSIM_OBJC_LITE_H

#ifndef YES
typedef signed char BOOL;
#define YES ((BOOL)1)
#define NO  ((BOOL)0)
#endif
#ifndef nil
#define nil ((id)0)
#endif

typedef struct { double a, b, c, d; double tx, ty; } CGAffineTransform;

static inline CGAffineTransform CGAffineTransformMake(double a, double b,
                                                      double c, double d,
                                                      double tx, double ty)
{
    CGAffineTransform t;
    t.a = a; t.b = b; t.c = c; t.d = d; t.tx = tx; t.ty = ty;
    return t;
}

static inline CGAffineTransform CGAffineTransformMakeTranslation(double tx,
                                                                 double ty)
{
    return CGAffineTransformMake(1, 0, 0, 1, tx, ty);
}

static inline CGAffineTransform CGAffineTransformMakeScale(double sx,
                                                           double sy)
{
    return CGAffineTransformMake(sx, 0, 0, sy, 0, 0);
}

static inline CGAffineTransform CGAffineTransformMakeRotation(double angle)
{
    extern double cos(double);
    extern double sin(double);
    double c = cos(angle), s = sin(angle);
    return CGAffineTransformMake(c, s, -s, c, 0, 0);
}

static inline CGAffineTransform CGAffineTransformConcat(CGAffineTransform t1,
                                                        CGAffineTransform t2)
{
    CGAffineTransform r;
    r.a = t1.a * t2.a + t1.b * t2.c;
    r.b = t1.a * t2.b + t1.b * t2.d;
    r.c = t1.c * t2.a + t1.d * t2.c;
    r.d = t1.c * t2.b + t1.d * t2.d;
    r.tx = t1.a * t2.tx + t1.b * t2.ty + t1.tx;
    r.ty = t1.c * t2.tx + t1.d * t2.ty + t1.ty;
    return r;
}

static inline CGAffineTransform CGAffineTransformIdentityValue(void)
{
    return CGAffineTransformMake(1, 0, 0, 1, 0, 0);
}

typedef struct { double x; double y; } CGPoint;
typedef struct { double width; double height; } CGSize;
typedef struct { CGPoint origin; CGSize size; } CGRect;

static inline CGPoint CGPointMake(double x, double y)
{
    CGPoint p;
    p.x = x;
    p.y = y;
    return p;
}

static inline CGSize CGSizeMake(double width, double height)
{
    CGSize s;
    s.width = width;
    s.height = height;
    return s;
}

static inline CGRect CGRectMake(double x, double y, double width, double height)
{
    CGRect r;
    r.origin.x = x;
    r.origin.y = y;
    r.size.width = width;
    r.size.height = height;
    return r;
}

static inline CGRect CGRectZero(void)
{
    return CGRectMake(0, 0, 0, 0);
}

#endif
