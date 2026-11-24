/* An arm64 ObjC image: main sends a class method to a root class. The
 * interpreter dispatches objc_msgSend to the arm64 IMP and returns 42. */
__attribute__((objc_root_class))
@interface Arm64Calc {
    Class isa;
}
+ (int)answer;
- (int)value;
@end

@implementation Arm64Calc
+ (int)answer
{
    return 42;
}
- (int)value
{
    return 7;
}
@end

int main(void)
{
    return (int)[Arm64Calc answer];
}
