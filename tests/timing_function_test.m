/* CAMediaTimingFunction control-point round trip and custom cubic-Bezier
 * easing values. */
#include "UIKitStub.h"

extern int printf(const char *fmt, ...);

int main(void)
{
    CAMediaTimingFunction *ease =
        [CAMediaTimingFunction functionWithName:@"easeInEaseOut"];
    float first[2];
    float second[2];
    [ease getControlPointAtIndex:1 values:first];
    [ease getControlPointAtIndex:2 values:second];
    printf("[timing] points %.2f %.2f %.2f %.2f\n",
           first[0], first[1], second[0], second[1]);
    printf("[timing] ease %.2f %.2f %.2f\n",
           [ease evaluate:0.25], [ease evaluate:0.5], [ease evaluate:0.75]);

    CAMediaTimingFunction *custom =
        [CAMediaTimingFunction functionWithControlPoints:0.42
                                                         :0.0
                                                         :0.58
                                                         :1.0];
    printf("[timing] custom %.2f %.2f %.2f\n",
           [custom evaluate:0.25], [custom evaluate:0.5],
           [custom evaluate:0.75]);

    CAMediaTimingFunction *linear =
        [CAMediaTimingFunction functionWithName:@"linear"];
    printf("[timing] linear %.2f %.2f\n",
           [linear evaluate:0.5], [linear evaluate:0.25]);
    return 0;
}
