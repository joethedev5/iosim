/* atexit handlers in an arm64 image. The host must not jump to an arm64
 * handler, so the loader's atexit gate collects guest handlers and runs
 * them from one native handler in reverse registration order. */
extern int printf(const char *fmt, ...);
extern int atexit(void (*fn)(void));

static int order[2];
static int n;

static void report(void)
{
    printf("atexit %d %d\n", order[0], order[1]);
}

static void first(void)
{
    order[n++] = 1;
}

static void second(void)
{
    order[n++] = 2;
}

int main(void)
{
    atexit(report);
    atexit(first);
    atexit(second);
    printf("main done\n");
    return 0;
}
