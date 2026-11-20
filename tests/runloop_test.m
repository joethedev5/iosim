/* Run loop fixture: delayed performSelector, NSTimer repeats, an idle
 * runMode: beforeDate: wait and NSThread's main-thread/sleep behavior. */
#include "foundation_lite.h"

extern int printf(const char *fmt, ...);
extern int fflush(void *stream);

static int g_cancelled_fired;

@interface Runner : NSObject
- (void)hello:(id)argument;
- (void)cancelMe:(id)argument;
- (void)tick:(NSTimer *)timer;
@end

@implementation Runner
- (void)hello:(id)argument
{
    printf("runloop: perform %s\n", iosim_string_cstr(argument));
    fflush(0);
}
- (void)cancelMe:(id)argument
{
    (void)argument;
    g_cancelled_fired = 1;
    printf("runloop: cancelled fired\n");
    fflush(0);
}
- (void)tick:(NSTimer *)timer
{
    static int ticks;
    ticks++;
    printf("runloop: tick %d\n", ticks);
    fflush(0);
    if (ticks >= 2)
        [timer invalidate];
}
@end

int main(void)
{
    Runner *runner = [[Runner alloc] init];
    printf("runloop: mainthread=%d\n", (int)[NSThread isMainThread]);
    [runner performSelector:@selector(hello:) withObject:@"now"];

    NSDate *idleStart = [NSDate date];
    BOOL idle = [[NSRunLoop currentRunLoop]
        runMode:NSDefaultRunLoopMode
        beforeDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
    double idleMs = ([idleStart timeIntervalSinceNow] * -1000.0);
    printf("runloop: idle=%d waited=%d\n", (int)idle,
           idleMs >= 60 && idleMs <= 500);

    [runner performSelector:@selector(hello:) withObject:@"later"
                 afterDelay:0.15];
    [runner performSelector:@selector(cancelMe:) withObject:nil
                 afterDelay:0.2];
    [NSObject cancelPreviousPerformRequestsWithTarget:runner
                                             selector:@selector(cancelMe:)
                                               object:nil];
    NSDate *start = [NSDate date];
    BOOL fired = [[NSRunLoop currentRunLoop]
        runMode:NSDefaultRunLoopMode
        beforeDate:[NSDate dateWithTimeIntervalSinceNow:1.0]];
    double elapsedMs = ([start timeIntervalSinceNow] * -1000.0);
    printf("runloop: fired=%d timing=%d\n", (int)fired,
           elapsedMs >= 100 && elapsedMs <= 500);

    [NSTimer scheduledTimerWithTimeInterval:0.05
                                     target:runner
                                   selector:@selector(tick:)
                                   userInfo:nil
                                    repeats:YES];
    [[NSRunLoop currentRunLoop]
        runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.4]];

    NSDate *sleepStart = [NSDate date];
    [NSThread sleepForTimeInterval:0.05];
    double sleepMs = ([sleepStart timeIntervalSinceNow] * -1000.0);
    printf("runloop: sleeping=%d cancelled=%d\n",
           sleepMs >= 40 && sleepMs <= 500, g_cancelled_fired);
    return 0;
}
