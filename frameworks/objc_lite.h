#ifndef IOSIM_OBJC_LITE_H
#define IOSIM_OBJC_LITE_H

/* Associated objects. The policy is pointer-sized, matching objc4. */
typedef unsigned long objc_AssociationPolicy;
enum {
    OBJC_ASSOCIATION_ASSIGN = 0,
    OBJC_ASSOCIATION_RETAIN_NONATOMIC = 1,
    OBJC_ASSOCIATION_COPY_NONATOMIC = 2,
    OBJC_ASSOCIATION_RETAIN = 3,
    OBJC_ASSOCIATION_COPY = 4
};
void objc_setAssociatedObject(id object, const void *key, id value,
                              objc_AssociationPolicy policy);
id objc_getAssociatedObject(id object, const void *key);
void objc_removeAssociatedObjects(id object);

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

/* QuartzCore-style 4x4 transform. Points are row vectors, so the first two
 * columns map x/y exactly like CGAffineTransform's a/b/c/d; the renderer
 * uses the 2D submatrix plus m41/m42 translation, and projects m13/m23/m31/
 * m32/m33/m34/m43 into a homography when a 3D transform is present. */
typedef struct CATransform3D {
    double m11, m12, m13, m14;
    double m21, m22, m23, m24;
    double m31, m32, m33, m34;
    double m41, m42, m43, m44;
} CATransform3D;

static inline CATransform3D CATransform3DIdentityValue(void)
{
    CATransform3D t;
    t.m11 = 1; t.m12 = 0; t.m13 = 0; t.m14 = 0;
    t.m21 = 0; t.m22 = 1; t.m23 = 0; t.m24 = 0;
    t.m31 = 0; t.m32 = 0; t.m33 = 1; t.m34 = 0;
    t.m41 = 0; t.m42 = 0; t.m43 = 0; t.m44 = 1;
    return t;
}

static inline CATransform3D CATransform3DMake(double m11, double m12,
                                              double m13, double m14,
                                              double m21, double m22,
                                              double m23, double m24,
                                              double m31, double m32,
                                              double m33, double m34,
                                              double m41, double m42,
                                              double m43, double m44)
{
    CATransform3D t;
    t.m11 = m11; t.m12 = m12; t.m13 = m13; t.m14 = m14;
    t.m21 = m21; t.m22 = m22; t.m23 = m23; t.m24 = m24;
    t.m31 = m31; t.m32 = m32; t.m33 = m33; t.m34 = m34;
    t.m41 = m41; t.m42 = m42; t.m43 = m43; t.m44 = m44;
    return t;
}

static inline CATransform3D CATransform3DMakeTranslation(double tx, double ty,
                                                         double tz)
{
    CATransform3D t = CATransform3DIdentityValue();
    t.m41 = tx;
    t.m42 = ty;
    t.m43 = tz;
    return t;
}

static inline CATransform3D CATransform3DMakeScale(double sx, double sy,
                                                   double sz)
{
    CATransform3D t = CATransform3DIdentityValue();
    t.m11 = sx;
    t.m22 = sy;
    t.m33 = sz;
    return t;
}

static inline CATransform3D CATransform3DMakeRotation(double angle, double x,
                                                      double y, double z)
{
    extern double cos(double);
    extern double sin(double);
    extern double sqrt(double);
    CATransform3D t = CATransform3DIdentityValue();
    double len = sqrt(x * x + y * y + z * z);
    if (len < 1e-12)
        return t;
    x /= len;
    y /= len;
    z /= len;
    double c = cos(angle), s = sin(angle), ic = 1.0 - c;
    t.m11 = ic * x * x + c;
    t.m12 = ic * x * y + s * z;
    t.m13 = ic * x * z - s * y;
    t.m21 = ic * x * y - s * z;
    t.m22 = ic * y * y + c;
    t.m23 = ic * y * z + s * x;
    t.m31 = ic * x * z + s * y;
    t.m32 = ic * y * z - s * x;
    t.m33 = ic * z * z + c;
    return t;
}

static inline CATransform3D CATransform3DConcat(CATransform3D a,
                                                CATransform3D b)
{
    double av[16] = {
        a.m11, a.m12, a.m13, a.m14, a.m21, a.m22, a.m23, a.m24,
        a.m31, a.m32, a.m33, a.m34, a.m41, a.m42, a.m43, a.m44
    };
    double bv[16] = {
        b.m11, b.m12, b.m13, b.m14, b.m21, b.m22, b.m23, b.m24,
        b.m31, b.m32, b.m33, b.m34, b.m41, b.m42, b.m43, b.m44
    };
    double out[16];
    for (int row = 0; row < 4; row++)
        for (int col = 0; col < 4; col++)
        {
            double sum = 0;
            for (int k = 0; k < 4; k++)
                sum += av[row * 4 + k] * bv[k * 4 + col];
            out[row * 4 + col] = sum;
        }
    return CATransform3DMake(out[0], out[1], out[2], out[3],
                             out[4], out[5], out[6], out[7],
                             out[8], out[9], out[10], out[11],
                             out[12], out[13], out[14], out[15]);
}

static inline CATransform3D CATransform3DTranslate(CATransform3D t, double tx,
                                                   double ty, double tz)
{
    return CATransform3DConcat(t, CATransform3DMakeTranslation(tx, ty, tz));
}

static inline CATransform3D CATransform3DScale(CATransform3D t, double sx,
                                               double sy, double sz)
{
    return CATransform3DConcat(t, CATransform3DMakeScale(sx, sy, sz));
}

static inline CATransform3D CATransform3DRotate(CATransform3D t, double angle,
                                                double x, double y, double z)
{
    return CATransform3DConcat(t, CATransform3DMakeRotation(angle, x, y, z));
}

static inline BOOL CATransform3DIsIdentity(CATransform3D t)
{
    return t.m11 == 1 && t.m12 == 0 && t.m13 == 0 && t.m14 == 0 &&
           t.m21 == 0 && t.m22 == 1 && t.m23 == 0 && t.m24 == 0 &&
           t.m31 == 0 && t.m32 == 0 && t.m33 == 1 && t.m34 == 0 &&
           t.m41 == 0 && t.m42 == 0 && t.m43 == 0 && t.m44 == 1;
}

typedef struct { double x; double y; } CGPoint;
typedef struct { double width; double height; } CGSize;
typedef struct { double dx; double dy; } CGVector;
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

static inline CGVector CGVectorMake(double dx, double dy)
{
    CGVector v;
    v.dx = dx;
    v.dy = dy;
    return v;
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

typedef struct {
    double top;
    double left;
    double bottom;
    double right;
} UIEdgeInsets;

static inline UIEdgeInsets UIEdgeInsetsMake(double top, double left,
                                            double bottom, double right)
{
    UIEdgeInsets insets;
    insets.top = top;
    insets.left = left;
    insets.bottom = bottom;
    insets.right = right;
    return insets;
}

#endif
