/* An arm64 ObjC image used to exercise mapping and metadata registration.
 * It defines a root class so it needs no framework dylibs. */
__attribute__((objc_root_class))
@interface Arm64Probe {
    Class isa;
}
+ (int)value;
@end

@implementation Arm64Probe
+ (int)value
{
    return 7;
}
@end

int main(void)
{
    return 0;
}
