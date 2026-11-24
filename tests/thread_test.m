/* NSThread start, detach and state: a target thread runs on a real pthread,
 * signals a condition, and reports its executing/finished state back. */
#include "foundation_lite.h"

extern int printf(const char *fmt, ...);
extern int fflush(void *stream);
extern int usleep(unsigned int usec);

static NSCondition *g_cond;
static int g_worker_done;
static int g_worker_main;
static int g_print_current;

@interface Worker : NSObject
- (void)run:(id)argument;
@end

@implementation Worker
- (void)run:(id)argument
{
    (void)argument;
    if (g_print_current)
        printf("[thread] current %d\n", [[NSThread currentThread] isMainThread]);
    g_worker_main = [NSThread isMainThread];
    [g_cond lock];
    g_worker_done = 1;
    [g_cond signal];
    [g_cond unlock];
}
@end

int main(void)
{
    g_cond = [[NSCondition alloc] init];
    Worker *worker = [[Worker alloc] init];
    printf("[thread] main %d\n", [NSThread isMainThread]);
    NSThread *thread = [[NSThread alloc] initWithTarget:worker
                                                selector:@selector(run:)
                                                  object:nil];
    [thread setName:@"Worker"];
    printf("[thread] name %s\n", [[thread name] UTF8String]);
    printf("[thread] before %d %d\n", [thread isExecuting],
           [thread isFinished]);
    g_print_current = 1;
    [thread start];
    printf("[thread] started %d\n", [thread isExecuting]);
    [g_cond lock];
    while (!g_worker_done)
        [g_cond wait];
    [g_cond unlock];
    printf("[thread] worker done %d main %d\n", g_worker_done,
           g_worker_main);
    int spins = 0;
    while (![thread isFinished] && spins < 200)
    {
        usleep(5000);
        spins++;
    }
    printf("[thread] finished %d %d\n", [thread isFinished],
           [thread isExecuting]);
    printf("[thread] priority %.1f\n", [thread threadPriority]);

    g_worker_done = 0;
    g_print_current = 0;
    [NSThread detachNewThreadSelector:@selector(run:)
                             toTarget:worker
                           withObject:nil];
    [g_cond lock];
    while (!g_worker_done)
        [g_cond wait];
    [g_cond unlock];
    printf("[thread] detached %d\n", g_worker_done);

    NSThread *cancelled = [[NSThread alloc] initWithTarget:worker
                                                  selector:@selector(run:)
                                                    object:nil];
    [cancelled cancel];
    printf("[thread] cancelled %d\n", [cancelled isCancelled]);
    fflush(0);
    return 0;
}
