/* Exercises the host service substrate: libdispatch, Mach messages,
 * bootstrap registration and XPC. Run under iosim (dispatch_main drains the
 * main queue and returns instead of blocking forever). */
#import <dispatch/dispatch.h>
#import <mach/mach.h>
#import <xpc/xpc.h>
#include <stdio.h>
#include <string.h>

extern kern_return_t bootstrap_register(mach_port_t bp, const char *name, mach_port_t port);
extern kern_return_t bootstrap_look_up(mach_port_t bp, const char *name, mach_port_t *port);
extern mach_port_t bootstrap_port;

static volatile int g_main_hits;
static volatile int g_group_hits;
static volatile int g_xpc_events;

typedef struct {
    mach_msg_header_t header;
    int32_t value;
    char text[32];
} ping_msg;

int main(void)
{
    printf("services: start\n");

    dispatch_async(dispatch_get_main_queue(), ^{
        g_main_hits += 1;
        printf("dispatch: main queue block\n");
    });
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 2 * NSEC_PER_MSEC),
                   dispatch_get_main_queue(), ^{
        g_main_hits += 10;
        printf("dispatch: delayed main block\n");
    });

    dispatch_semaphore_t sem = dispatch_semaphore_create(0);
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        printf("dispatch: global queue block\n");
        dispatch_semaphore_signal(sem);
    });
    dispatch_semaphore_wait(sem, DISPATCH_TIME_FOREVER);
    printf("dispatch: semaphore returned\n");

    dispatch_group_t group = dispatch_group_create();
    dispatch_group_enter(group);
    dispatch_async(dispatch_get_main_queue(), ^{
        g_group_hits += 1;
        dispatch_group_leave(group);
    });
    dispatch_async(dispatch_get_main_queue(), ^{
        printf("group: count=%d\n", g_group_hits);
    });

    mach_port_t port = MACH_PORT_NULL;
    kern_return_t kr = mach_port_allocate(mach_task_self(), MACH_PORT_RIGHT_RECEIVE, &port);
    ping_msg msg;
    memset(&msg, 0, sizeof(msg));
    msg.header.msgh_bits = MACH_MSGH_BITS(MACH_MSG_TYPE_MAKE_SEND, 0);
    msg.header.msgh_size = sizeof(msg);
    msg.header.msgh_remote_port = port;
    msg.header.msgh_local_port = MACH_PORT_NULL;
    msg.header.msgh_id = 0x1234;
    msg.value = 77;
    strcpy(msg.text, "hello mach");
    kern_return_t sent = mach_msg_send(&msg.header);

    ping_msg recv;
    memset(&recv, 0, sizeof(recv));
    recv.header.msgh_local_port = port;
    kern_return_t got = mach_msg(&recv.header, MACH_RCV_MSG, 0, sizeof(recv),
                                 port, 1000, MACH_PORT_NULL);
    printf("mach: alloc=%d send=%d recv=%d id=%#x value=%d text=%s\n",
           kr, sent, got, recv.header.msgh_id, recv.value, recv.text);

    kern_return_t reg = bootstrap_register(bootstrap_port, "com.iosim.echo.mach", port);
    mach_port_t looked = MACH_PORT_NULL;
    kern_return_t lk = bootstrap_look_up(bootstrap_port, "com.iosim.echo.mach", &looked);
    printf("bootstrap: register=%d lookup=%d port=%#x same=%d\n",
           reg, lk, looked, looked == port);

    xpc_connection_t listener =
        xpc_connection_create_mach_service("com.iosim.echo", NULL, 0);
    xpc_connection_set_event_handler(listener, ^(xpc_object_t event) {
        (void)event;
        g_xpc_events++;
        printf("xpc: listener event\n");
    });
    xpc_connection_resume(listener);

    xpc_connection_t client = xpc_connection_create("com.iosim.echo", NULL);
    xpc_connection_set_event_handler(client, ^(xpc_object_t event) { (void)event; });
    xpc_connection_resume(client);

    xpc_object_t dict = xpc_dictionary_create(NULL, NULL, 0);
    xpc_dictionary_set_string(dict, "kind", "ping");
    xpc_dictionary_set_int64(dict, "seq", 7);
    xpc_connection_send_message(client, dict);
    printf("xpc: sent kind=%s seq=%lld events=%d\n",
           xpc_dictionary_get_string(dict, "kind"),
           (long long)xpc_dictionary_get_int64(dict, "seq"), g_xpc_events);

    dispatch_main();
    printf("dispatch: main blocks ran, hits=%d group=%d\n", g_main_hits, g_group_hits);
    printf("services: done\n");
    return 0;
}
