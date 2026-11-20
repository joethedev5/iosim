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
