/* An arm64 guest class with several ivars on a native superclass. The
 * runtime lays out the ivar offsets and writes them into the image's
 * 32-bit ivar-offset globals. A class with one ivar can hide a layout
 * bug that corrupts the following global; this fixture reads every ivar
 * back after storing all of them. */
#include "UIKitStub.h"

extern int printf(const char *fmt, ...);

@interface IvarBox : UIResponder {
    id _one;
    id _two;
    id _three;
    id _four;
}
- (void)fill;
- (void)report;
@end

@implementation IvarBox

- (void)fill
{
    _one = @"one";
    _two = @"two";
    _three = @"three";
    _four = @"four";
}

- (void)report
{
    printf("ivars %s %s %s %s\n", [_one UTF8String], [_two UTF8String],
           [_three UTF8String], [_four UTF8String]);
}

@end

int main(void)
{
    IvarBox *box = [[IvarBox alloc] init];
    [box fill];
    [box report];
    return 0;
}
