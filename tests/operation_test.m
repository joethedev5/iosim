/* NSOperationQueue fixture: block operations run on dispatch queues and
 * waitUntilAllOperationsAreFinished joins them. */
#include "foundation_lite.h"

extern int printf(const char *fmt, ...);
extern int fflush(void *stream);

/* The three blocks run concurrently, so the counter must be updated
 * atomically: a plain ++ loses increments when two blocks race. */
static long g_blocks;

int main(void)
{
    NSOperationQueue *queue = [[NSOperationQueue alloc] init];
    for (int i = 0; i < 3; i++)
    {
        [queue addOperationWithBlock:^{
            __atomic_fetch_add(&g_blocks, 1, __ATOMIC_SEQ_CST);
            printf("[op] block %d\n", i);
            fflush(0);
        }];
    }
    NSBlockOperation *multi = [NSBlockOperation blockOperationWithBlock:^{
        printf("[op] multi one\n");
        fflush(0);
    }];
    [multi addExecutionBlock:^{
        printf("[op] multi two\n");
        fflush(0);
    }];
    [multi setCompletionBlock:^{
        printf("[op] completion\n");
        fflush(0);
    }];
    [queue addOperation:multi];
    [queue waitUntilAllOperationsAreFinished];
    printf("[op] blocks=%ld pending=%ld max=%ld\n", g_blocks,
           (long)[queue operationCount],
           (long)[queue maxConcurrentOperationCount]);
    return 0;
}
