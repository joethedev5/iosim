/* pthread_create from an arm64 image. The start routines are guest code,
 * so the host cannot call them directly: the loader wraps each in a
 * native trampoline that runs a fresh guest cpu on the new host thread,
 * returns the routine's x0 to a joining thread, and gives each worker its
 * own thread-local block. Two workers start before either is joined, so
 * the block table and its translator see concurrent lookups. */
extern int printf(const char *fmt, ...);

typedef unsigned long pthread_t;
extern int pthread_create(pthread_t *thread, const void *attr,
                          void *(*start)(void *), void *arg);
extern int pthread_join(pthread_t thread, void **retval);
extern int atexit(void (*fn)(void));

static _Thread_local int tls_value = 1;
static int worker_tls[2];
static int worker_exits;

static void worker_exit(void)
{
    worker_exits++;
}

static void summary(void)
{
    printf("thread atexit=%d\n", worker_exits);
}

static void *worker(void *arg)
{
    long index = (long)arg;
    atexit(worker_exit);
    tls_value += 40 + (int)index;
    worker_tls[index] = tls_value;
    return (void *)(long)(100 + index);
}

int main(void)
{
    pthread_t thread[2];
    void *joined[2] = {0, 0};
    int created[2];
    int waited[2];
    atexit(summary);
    for (int i = 0; i < 2; i++)
        created[i] = pthread_create(&thread[i], 0, worker,
                                    (void *)(long)i);
    for (int i = 0; i < 2; i++)
        waited[i] = created[i] ? -1 : pthread_join(thread[i], &joined[i]);
    printf("thread create=%d,%d join=%d,%d main=%d workers=%d,%d "
           "ret=%ld,%ld\n", created[0], created[1], waited[0], waited[1],
           tls_value, worker_tls[0], worker_tls[1], (long)joined[0],
           (long)joined[1]);
    return 0;
}
