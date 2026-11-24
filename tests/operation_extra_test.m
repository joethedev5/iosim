/* NSOperation state: a queued block is observed running through isExecuting,
 * held on a condition, then joined with waitUntilFinished. */
#include "foundation_lite.h"

extern int printf(const char *fmt, ...);
extern int fflush(void *stream);

static NSCondition *g_cond;
static int g_started;
static int g_release;

int main(void)
{
    g_cond = [[NSCondition alloc] init];
    g_started = 0;
    g_release = 0;
    NSOperationQueue *queue = [[NSOperationQueue alloc] init];
    NSBlockOperation *operation = [NSBlockOperation blockOperationWithBlock:^{
        [g_cond lock];
        g_started = 1;
        [g_cond signal];
        while (!g_release)
            [g_cond wait];
        [g_cond unlock];
    }];
    [operation setName:@"Worker"];
    [operation setQueuePriority:1];
    printf("[op] name %s\n", [[operation name] UTF8String]);
    printf("[op] priority %ld\n", [operation queuePriority]);
    printf("[op] before %d %d\n", [operation isExecuting],
           [operation isReady]);
    [queue addOperation:operation];
    [g_cond lock];
    while (!g_started)
        [g_cond wait];
    [g_cond unlock];
    printf("[op] running %d\n", [operation isExecuting]);
    printf("[op] operations %lu\n", [[queue operations] count]);
    [g_cond lock];
    g_release = 1;
    [g_cond signal];
    [g_cond unlock];
    [operation waitUntilFinished];
    printf("[op] finished %d %d\n", [operation isFinished],
           [operation isExecuting]);
    printf("[op] count %ld\n", [queue operationCount]);
    fflush(0);
    return 0;
}
