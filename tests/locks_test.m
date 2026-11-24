/* NSLock, NSRecursiveLock, NSCondition and one condition-lock round trip,
 * including a worker thread waiting on the condition. */
#include "foundation_lite.h"

extern int printf(const char *fmt, ...);
extern int fflush(void *stream);
extern int usleep(unsigned int usec);
extern int pthread_create(unsigned long *thread, const void *attr,
                          void *(*fn)(void *), void *arg);
extern int pthread_join(unsigned long thread, void **retval);

static NSCondition *g_cond;
static int g_stage;

static void *condition_worker(void *unused)
{
    (void)unused;
    [g_cond lock];
    g_stage = 1;
    [g_cond signal];
    while (g_stage != 2)
        [g_cond wait];
    g_stage = 3;
    [g_cond broadcast];
    [g_cond unlock];
    return 0;
}

int main(void)
{
    NSLock *lock = [[NSLock alloc] init];
    printf("[lock] try0 %d\n", [lock tryLock]);
    printf("[lock] try1 %d\n", [lock tryLock]);
    [lock unlock];
    printf("[lock] try2 %d\n", [lock tryLock]);
    printf("[lock] past %d\n", [lock lockBeforeDate:
        [NSDate dateWithTimeIntervalSinceNow:-0.05]]);
    [lock unlock];
    printf("[lock] future %d\n", [lock lockBeforeDate:
        [NSDate dateWithTimeIntervalSinceNow:0.2]]);
    [lock unlock];
    [lock setName:@"L"];
    printf("[lock] name %s\n", [[lock name] UTF8String]);
    fflush(0);

    NSRecursiveLock *recursive = [[NSRecursiveLock alloc] init];
    [recursive lock];
    [recursive lock];
    printf("[recursive] depth %d\n", [recursive tryLock]);
    [recursive unlock];
    [recursive unlock];
    [recursive unlock];
    printf("[recursive] free %d\n", [recursive tryLock]);
    [recursive unlock];
    fflush(0);

    NSCondition *condition = [[NSCondition alloc] init];
    [condition lock];
    printf("[condition] timeout %d\n", [condition waitUntilDate:
        [NSDate dateWithTimeIntervalSinceNow:0.05]]);
    [condition unlock];
    g_cond = condition;
    g_stage = 0;
    unsigned long worker = 0;
    pthread_create(&worker, 0, condition_worker, 0);
    [condition lock];
    while (g_stage != 1)
        [condition wait];
    printf("[condition] started %d\n", g_stage);
    g_stage = 2;
    [condition signal];
    while (g_stage != 3)
        [condition wait];
    printf("[condition] finished %d\n", g_stage);
    [condition unlock];
    pthread_join(worker, 0);
    fflush(0);

    NSConditionLock *condlock =
        [[NSConditionLock alloc] initWithCondition:0];
    printf("[condlock] init %ld\n", [condlock condition]);
    printf("[condlock] wrong %d\n", [condlock tryLockWhenCondition:1]);
    printf("[condlock] right %d\n", [condlock tryLockWhenCondition:0]);
    [condlock unlockWithCondition:2];
    printf("[condlock] now %ld\n", [condlock condition]);
    [condlock lockWhenCondition:2];
    printf("[condlock] locked %ld\n", [condlock condition]);
    printf("[condlock] past %d\n", [condlock lockBeforeDate:
        [NSDate dateWithTimeIntervalSinceNow:-0.05]]);
    [condlock unlock];
    printf("[condlock] future %d\n", [condlock lockBeforeDate:
        [NSDate dateWithTimeIntervalSinceNow:0.2]]);
    [condlock unlock];
    fflush(0);
    return 0;
}
