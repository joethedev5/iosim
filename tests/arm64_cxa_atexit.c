/* atexit and __cxa_atexit handlers in an arm64 image share one queue, so
 * their registration order is preserved across both registration APIs.
 * A __cxa_atexit handler receives its argument in x0; an atexit handler
 * receives zero. The host must not jump to either. */
extern int printf(const char *fmt, ...);
extern int atexit(void (*fn)(void));
extern int __cxa_atexit(void (*fn)(void *), void *arg, void *dso);

static int step;

static void plain1(void)
{
    printf("mix p1 %d\n", ++step);
}

static void plain2(void)
{
    printf("mix p2 %d\n", ++step);
}

static void cxa(void *arg)
{
    printf("mix cxa %ld %d\n", (long)arg, ++step);
}

int main(void)
{
    atexit(plain1);
    __cxa_atexit(cxa, (void *)5, 0);
    atexit(plain2);
    printf("mix main\n");
    return 0;
}
