/* libdispatch source fixture: a repeating main-queue timer, manual cancel
 * with a cancel handler, and data sources that coalesce merged values until
 * the event handler reads them. The Foundation run loop drains the main
 * queue, as the real main run loop does. */
#include "foundation_lite.h"
#include <stdint.h>

extern int printf(const char *fmt, ...);

typedef uint64_t dispatch_time_t;
typedef void *dispatch_queue_t;
typedef void *dispatch_source_t;
typedef void *dispatch_source_type_t;

extern dispatch_queue_t dispatch_get_main_queue(void);
struct dispatch_source_type_s;
extern const struct dispatch_source_type_s _dispatch_source_type_timer;
extern const struct dispatch_source_type_s _dispatch_source_type_data_add;
extern dispatch_source_t dispatch_source_create(dispatch_source_type_t type,
                                                 uintptr_t handle,
                                                 unsigned long mask,
                                                 dispatch_queue_t queue);
extern void dispatch_source_set_event_handler_f(dispatch_source_t source,
                                                 void (*function)(void *));
extern void dispatch_source_set_cancel_handler_f(dispatch_source_t source,
                                                  void (*function)(void *));
extern void dispatch_set_context(dispatch_source_t source, void *context);
extern void dispatch_source_set_timer(dispatch_source_t source,
                                      dispatch_time_t start,
                                      uint64_t interval, uint64_t leeway);
extern dispatch_time_t dispatch_time(dispatch_time_t base, int64_t delta);
extern void dispatch_resume(dispatch_source_t source);
extern void dispatch_source_cancel(dispatch_source_t source);
extern int dispatch_source_testcancel(dispatch_source_t source);
extern unsigned long dispatch_source_get_data(dispatch_source_t source);
extern void dispatch_source_merge_data(dispatch_source_t source,
                                       unsigned long value);

static int g_timer_fires;
static long g_context_seen;
static int g_data_fires;
static int g_cancel_fires;
static unsigned long g_data_last;
static dispatch_source_t g_data_source;

static void timer_handler(void *context)
{
    g_context_seen = (long)context;
    g_timer_fires++;
}

static void data_handler(void *context)
{
    (void)context;
    g_data_fires++;
    g_data_last = dispatch_source_get_data(g_data_source);
}

static void cancel_handler(void *context)
{
    (void)context;
    g_cancel_fires++;
}

int main(void)
{
    dispatch_queue_t main_queue = dispatch_get_main_queue();
    dispatch_source_t timer =
        dispatch_source_create(
            (dispatch_source_type_t)&_dispatch_source_type_timer,
            0, 0, main_queue);
    dispatch_set_context(timer, (void *)7L);
    dispatch_source_set_event_handler_f(timer, timer_handler);
    dispatch_source_set_cancel_handler_f(timer, cancel_handler);
    dispatch_source_set_timer(timer,
                              dispatch_time(0, 10ULL * 1000000ULL),
                              20ULL * 1000000ULL, 0);
    dispatch_resume(timer);
    [[NSRunLoop currentRunLoop]
        runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.12]];
    printf("[src] timer %s %d\n",
           (g_timer_fires >= 3 && g_timer_fires <= 7) ? "ok" : "bad",
           g_timer_fires);

    int before = g_timer_fires;
    dispatch_source_cancel(timer);
    [[NSRunLoop currentRunLoop]
        runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.05]];
    printf("[src] canceled %d %d %d\n",
           dispatch_source_testcancel(timer), g_timer_fires == before,
           g_cancel_fires);
    printf("[src] context %ld\n", g_context_seen);

    dispatch_source_t data =
        dispatch_source_create(
            (dispatch_source_type_t)&_dispatch_source_type_data_add,
            0, 0, main_queue);
    g_data_source = data;
    dispatch_source_set_event_handler_f(data, data_handler);
    dispatch_resume(data);
    dispatch_source_merge_data(data, 3);
    dispatch_source_merge_data(data, 4);
    [[NSRunLoop currentRunLoop]
        runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.05]];
    printf("[src] data %d %lu\n", g_data_fires, g_data_last);
    dispatch_source_merge_data(data, 5);
    dispatch_source_merge_data(data, 2);
    [[NSRunLoop currentRunLoop]
        runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.05]];
    printf("[src] data %d %lu\n", g_data_fires, g_data_last);
    dispatch_source_cancel(data);
    return 0;
}
