/* NSOperationQueue fixture: block operations run on dispatch queues and
 * waitUntilAllOperationsAreFinished joins them. */
#include "foundation_lite.h"

extern int printf(const char *fmt, ...);
extern int fflush(void *stream);

static long g_blocks;

int main(void)
{
    NSOperationQueue *queue = [[NSOperationQueue alloc] init];
    for (int i = 0; i < 3; i++)
    {
        [queue addOperationWithBlock:^{
            g_blocks++;
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
