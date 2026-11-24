/* Associated objects: per-object keyed storage survives other objects,
 * overwrites and clears, RETAIN keeps the pointer while COPY stores a copy,
 * and removeAssociatedObjects only drops the receiver's entries. */
#include "foundation_lite.h"

extern int printf(const char *fmt, ...);
extern int fflush(void *stream);

static char kAlpha, kBeta, kGamma;

@interface AssocBox : NSObject {
@public
    int value;
}
- (int)value;
- (void)setValue:(int)newValue;
- (id)copy;
@end

@implementation AssocBox
- (int)value { return value; }
- (void)setValue:(int)newValue { value = newValue; }
- (id)copy
{
    AssocBox *box = [[AssocBox alloc] init];
    box->value = value;
    return box;
}
@end

int main(void)
{
    AssocBox *one = [[AssocBox alloc] init];
    AssocBox *two = [[AssocBox alloc] init];
    NSString *alpha = [NSString stringWithUTF8String:"alpha"];
    NSString *beta = [NSString stringWithUTF8String:"beta"];
    NSString *other = [NSString stringWithUTF8String:"other"];

    objc_setAssociatedObject(one, &kAlpha, alpha,
                             OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    objc_setAssociatedObject(one, &kBeta, beta,
                             OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    objc_setAssociatedObject(two, &kAlpha, other,
                             OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    printf("[assoc] one %s %s two %s\n",
           [(NSString *)objc_getAssociatedObject(one, &kAlpha) UTF8String],
           [(NSString *)objc_getAssociatedObject(one, &kBeta) UTF8String],
           [(NSString *)objc_getAssociatedObject(two, &kAlpha) UTF8String]);

    objc_setAssociatedObject(one, &kAlpha,
                             [NSString stringWithUTF8String:"gamma"],
                             OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    printf("[assoc] replaced %s\n",
           [(NSString *)objc_getAssociatedObject(one, &kAlpha) UTF8String]);

    objc_setAssociatedObject(one, &kBeta, nil,
                             OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    printf("[assoc] cleared %d\n",
           objc_getAssociatedObject(one, &kBeta) == nil);

    AssocBox *box = [[AssocBox alloc] init];
    [box setValue:7];
    objc_setAssociatedObject(one, &kGamma, box,
                             OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    [box setValue:9];
    AssocBox *stored = (AssocBox *)objc_getAssociatedObject(one, &kGamma);
    printf("[assoc] retain same %d %d\n", stored == box, [stored value]);

    AssocBox *source = [[AssocBox alloc] init];
    [source setValue:11];
    objc_setAssociatedObject(two, &kGamma, source,
                             OBJC_ASSOCIATION_COPY_NONATOMIC);
    [source setValue:13];
    AssocBox *copied = (AssocBox *)objc_getAssociatedObject(two, &kGamma);
    printf("[assoc] copy isolated %d %d\n", [copied value], [source value]);

    NSMutableString *text = [NSMutableString stringWithString:@"copy"];
    objc_setAssociatedObject(two, &kBeta, text,
                             OBJC_ASSOCIATION_COPY_NONATOMIC);
    [text appendString:@"!"];
    printf("[assoc] string copy %s %s\n",
           [(NSString *)objc_getAssociatedObject(two, &kBeta) UTF8String],
           [text UTF8String]);

    objc_removeAssociatedObjects(one);
    printf("[assoc] removed %d %s\n",
           objc_getAssociatedObject(one, &kAlpha) == nil,
           [(NSString *)objc_getAssociatedObject(two, &kAlpha) UTF8String]);
    printf("[assoc] done\n");
    fflush(0);
    return 0;
}
