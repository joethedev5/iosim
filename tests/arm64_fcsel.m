/* Conditional selects in both register banks, plus negation. A delegate
 * style chooser picks between two doubles with FCSEL (which the
 * translator used to reject); signed negation becomes a shifted-register
 * SUB with XZR as the first operand. The inputs are volatile so the
 * compiler cannot fold the selects away. */
#include "UIKitStub.h"

extern int printf(const char *fmt, ...);

static double row_height(long section)
{
    return section == 0 ? 44.0 : 50.0;
}

static float opacity(int enabled)
{
    return enabled ? 0.75f : 0.25f;
}

static int negate_when_positive(int value)
{
    return value > 0 ? -value : value;
}

int main(void)
{
    volatile long sections[3] = { 0, 1, 9 };
    volatile int values[2] = { 7, -3 };
    volatile double sums[2] = { 1.25, 2.5 };
    volatile double *cursor = sums;
    double total = *cursor++;
    total += *cursor;
    printf("fcsel %.1f %.1f %.1f\n", row_height(sections[0]),
           row_height(sections[1]), row_height(sections[2]));
    printf("fcsel32 %.2f %.2f\n", (double)opacity(values[0] > 0),
           (double)opacity(values[1] > 0));
    printf("neg %d %d %d\n", -values[0], negate_when_positive(values[0]),
           negate_when_positive(values[1]));
    printf("fpseq %.2f\n", total);
    return 0;
}
