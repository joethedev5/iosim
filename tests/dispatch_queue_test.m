/* Serial dispatch queues: blocks run one at a time in submission order,
 * dispatch_sync waits for the pending work, and a barrier keeps its FIFO
 * place. */
#include "foundation_lite.h"

extern int printf(const char *fmt, ...);
extern int fflush(void *stream);
extern int usleep(unsigned int usec);

typedef void *dispatch_queue_t;
extern dispatch_queue_t dispatch_queue_create(const char *label, void *attr);
extern void dispatch_async(dispatch_queue_t queue, void (^block)(void));
extern void dispatch_sync(dispatch_queue_t queue, void (^block)(void));
extern void dispatch_barrier_async(dispatch_queue_t queue, void (^block)(void));

static volatile int g_running;
static volatile int g_overlap;
static volatile int g_done;
static volatile int g_barrier_overlap;
static char g_order[32];
static int g_length;

static void append(char c)
{
    if (g_length < 30)
    {
        g_order[g_length++] = c;
        g_order[g_length] = 0;
    }
}

static void work(char c)
{
    if (g_running)
        g_overlap = 1;
    g_running = 1;
    usleep(15000);
    append(c);
    g_running = 0;
    g_done++;
}

int main(void)
{
    dispatch_queue_t queue =
        dispatch_queue_create("com.iosim.serial", 0);
    g_done = 0;
    dispatch_async(queue, ^{ work('a'); });
    dispatch_async(queue, ^{ work('b'); });
    dispatch_async(queue, ^{ work('c'); });
    dispatch_async(queue, ^{ work('d'); });
    for (int i = 0; i < 500 && g_done < 4; i++)
        usleep(10000);
    printf("[queue] order %s\n", g_order);
    printf("[queue] overlap %d\n", g_overlap);

    g_length = 0;
    g_order[0] = 0;
    g_done = 0;
    dispatch_async(queue, ^{
        usleep(20000);
        append('x');
        g_done++;
    });
    dispatch_sync(queue, ^{ append('y'); });
    for (int i = 0; i < 500 && g_done < 1; i++)
        usleep(10000);
    printf("[queue] sync %s\n", g_order);

    g_length = 0;
    g_order[0] = 0;
    g_done = 0;
    dispatch_async(queue, ^{ work('1'); });
    dispatch_async(queue, ^{ work('2'); });
    dispatch_barrier_async(queue, ^{
        if (g_running)
            g_barrier_overlap = 1;
        append('B');
        g_done++;
    });
    dispatch_async(queue, ^{ work('3'); });
    for (int i = 0; i < 500 && g_done < 4; i++)
        usleep(10000);
    printf("[queue] barrier %s %d\n", g_order, g_barrier_overlap);
    printf("[queue] done\n");
    fflush(0);
    return 0;
}
