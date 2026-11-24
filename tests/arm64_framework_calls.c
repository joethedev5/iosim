/* Calls C functions exported by the native framework dylibs directly from
 * arm64 code: QuartzCore's CACurrentMediaTime (double result) and UIKit's
 * accessibility queries (integer results). Exits 64 when the values are
 * plausible. */
extern double CACurrentMediaTime(void);
extern int UIAccessibilityIsReduceMotionEnabled(void);
extern int UIAccessibilityIsVoiceOverRunning(void);
extern int printf(const char *fmt, ...);

int main(void)
{
    double t = CACurrentMediaTime();
    int motion = UIAccessibilityIsReduceMotionEnabled();
    int voice = UIAccessibilityIsVoiceOverRunning();
    printf("t=%.1f motion=%d voice=%d\n", t, motion, voice);
    return (t > 0.0 && (motion == 0 || motion == 1) &&
            (voice == 0 || voice == 1)) ? 64 : 12;
}
