/* CASpringAnimation: a damped spring drives a layer's opacity from 0 to 1;
 * sampling the presentation layer over time shows progress and settling. */
#include "UIKitStub.h"

extern int printf(const char *fmt, ...);
extern int usleep(unsigned int usec);

int main(void)
{
    CALayer *layer = [[CALayer alloc] init];
    layer.opacity = 1.0;

    CASpringAnimation *spring =
        [CASpringAnimation animationWithKeyPath:@"opacity"];
    [spring setFromValue:[NSNumber numberWithDouble:0.0]];
    [spring setToValue:[NSNumber numberWithDouble:1.0]];
    [spring setDuration:0.4];
    [spring setMass:1.0];
    [spring setStiffness:200.0];
    [spring setDamping:15.0];
    [spring setInitialVelocity:0.0];
    printf("[spring] settling %.2f\n", [spring settlingDuration]);

    [layer addAnimation:spring forKey:@"spring"];
    usleep(120000);
    double early = [[layer presentationLayer] opacity];
    usleep(380000);
    double late = [[layer presentationLayer] opacity];
    printf("[spring] early %d late %d\n",
           early > 0.05 && early < 1.20, late > 0.90 && late < 1.10);
    return 0;
}
