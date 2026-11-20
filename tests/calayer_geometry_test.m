/* CALayer geometry fixture: position/anchorPoint derive from the frame and
 * setters preserve the layer's anchor where Core Animation does. */
#import "UIKitStub.h"

extern int printf(const char *fmt, ...);

int main(void)
{
    CALayer *layer = [[CALayer alloc] init];
    [layer setFrame:CGRectMake(10, 20, 100, 50)];

    CGPoint p = [layer position];
    printf("[layer] position %.0f %.0f\n", p.x, p.y);

    [layer setPosition:CGPointMake(100, 100)];
    CGRect frame = [layer frame];
    printf("[layer] setposition %.0f %.0f\n", frame.origin.x,
           frame.origin.y);

    [layer setAnchorPoint:CGPointMake(0, 0)];
    frame = [layer frame];
    p = [layer position];
    printf("[layer] anchor %.0f %.0f pos %.0f %.0f\n", frame.origin.x,
           frame.origin.y, p.x, p.y);

    [layer setBounds:CGRectMake(0, 0, 120, 60)];
    frame = [layer frame];
    p = [layer position];
    printf("[layer] bounds %.0f %.0f %.0f %.0f pos %.0f %.0f\n",
           frame.origin.x, frame.origin.y, frame.size.width,
           frame.size.height, p.x, p.y);
    return 0;
}
