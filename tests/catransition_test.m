/* CATransition: properties round-trip, and a fade transition animates the
 * layer's opacity from transparent to opaque before settling on the model
 * value. Other transition types are stored but do not fade. */
#import "UIKitStub.h"

extern int printf(const char *fmt, ...);
extern int fflush(void *stream);
extern int usleep(unsigned int usec);
extern id kCATransitionFade;
extern id kCATransitionPush;
extern id kCATransitionFromLeft;

int main(void)
{
    CALayer *layer = [[CALayer alloc] init];
    layer.frame = CGRectMake(0, 0, 100, 100);
    layer.opacity = 1.0;

    CATransition *fade = [CATransition animation];
    fade.type = kCATransitionFade;
    fade.subtype = kCATransitionFromLeft;
    fade.duration = 0.8;
    fade.startProgress = 0.2f;
    fade.endProgress = 0.8f;
    printf("[ctrans] props %s %s %.2f %.2f\n",
           [[fade type] UTF8String], [[fade subtype] UTF8String],
           fade.startProgress, fade.endProgress);
    [layer addAnimation:fade forKey:@"fade"];
    usleep(300000);
    printf("[ctrans] early %.2f\n", [[layer presentationLayer] opacity]);
    usleep(900000);
    printf("[ctrans] late %.2f\n", [[layer presentationLayer] opacity]);

    CATransition *push = [CATransition animation];
    push.type = kCATransitionPush;
    push.duration = 0.5;
    [layer addAnimation:push forKey:@"push"];
    usleep(200000);
    printf("[ctrans] push %.2f\n", [[layer presentationLayer] opacity]);
    printf("[ctrans] done\n");
    fflush(0);
    return 0;
}
