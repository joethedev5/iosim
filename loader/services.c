/* Host implementations of the Darwin service substrate used by simulator
 * binaries: libdispatch, Mach ports/messages, the launchd bootstrap namespace
 * and a minimal XPC transport. Dispatch queues are process-local; bootstrap
 * names and Mach messages are shared across guest processes through launchd
 * and abstract Unix sockets. */
#define _GNU_SOURCE
#include <errno.h>
#include <fcntl.h>
#include <netdb.h>
#include <netinet/in.h>
#include <poll.h>
#include <pthread.h>
#include <regex.h>
#include <stddef.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/socket.h>
#include <sys/time.h>
#include <sys/un.h>
#include <time.h>
#include <unistd.h>
#include "services.h"

#ifdef IOSIM_HAVE_OPENSSL
#include <openssl/ssl.h>
#include <openssl/err.h>
#endif

extern void *_Block_copy(void *block);
extern void _Block_release(void *block);

/* ----------------------------------------------------------------- blocks */

struct block_layout {
    void *isa;
    int flags;
    int reserved;
    void *invoke;
    void *descriptor;
};

static void call_block(void *block)
{
    if (!block)
        return;
    struct block_layout *b = block;
    if (b->invoke)
        ((void (*)(void *))b->invoke)(block);
}

/* XPC and dispatch handlers take one argument (the event/message object). */
static void call_block_arg(void *block, void *arg)
{
    if (!block)
        return;
    struct block_layout *b = block;
    if (b->invoke)
        ((void (*)(void *, void *))b->invoke)(block, arg);
}

static double now_seconds(void)
{
    struct timespec ts;
    clock_gettime(CLOCK_MONOTONIC, &ts);
    return (double)ts.tv_sec + ts.tv_nsec / 1e9;
}

/* --------------------------------------------------------------- dispatch */

#define MAINQ_CAP 512
struct mainq_item {
    void *block;
    void (*function)(void *);
    void *context;
    double when;
};
static struct mainq_item mainq[MAINQ_CAP];
static int mainq_head, mainq_tail;
static pthread_mutex_t mainq_lock = PTHREAD_MUTEX_INITIALIZER;

#define DISPATCH_OBJECT_MAGIC 0x4453504fU
enum { DISPATCH_KIND_QUEUE = 1, DISPATCH_KIND_SOURCE = 2 };
struct dispatch_object_header {
    unsigned magic;
    int kind;
    void *context;
};
struct dispatch_queue_s {
    struct dispatch_object_header hdr;
    int is_main;
};
struct dispatch_queue_s main_queue = {
    { DISPATCH_OBJECT_MAGIC, DISPATCH_KIND_QUEUE, NULL }, 1
};
struct dispatch_queue_s global_queue = {
    { DISPATCH_OBJECT_MAGIC, DISPATCH_KIND_QUEUE, NULL }, 0
};
char dispatch_main_q_storage[64];

void *dispatch_get_main_queue(void) { return &main_queue; }
void *dispatch_get_global_queue(long identifier, unsigned long flags)
{
    (void)identifier; (void)flags;
    return &global_queue;
}
void *dispatch_queue_create(const char *label, void *attr)
{
    (void)label; (void)attr;
    struct dispatch_queue_s *queue = calloc(1, sizeof(*queue));
    if (queue)
    {
        queue->hdr.magic = DISPATCH_OBJECT_MAGIC;
        queue->hdr.kind = DISPATCH_KIND_QUEUE;
    }
    return queue;
}
void dispatch_release(void *queue) { (void)queue; }
void dispatch_retain(void *queue) { (void)queue; }

static void mainq_push_item(void *block, void (*function)(void *),
                            void *context, double when)
{
    if (getenv("IOSIM_DEBUG_DISPATCH"))
        fprintf(stderr, "[dispatch] enqueue %p/%p when %.3f now %.3f\n",
                block, (void *)function, when, now_seconds());
    pthread_mutex_lock(&mainq_lock);
    int next = (mainq_tail + 1) % MAINQ_CAP;
    if (next != mainq_head)
    {
        mainq[mainq_tail].block = block;
        mainq[mainq_tail].function = function;
        mainq[mainq_tail].context = context;
        mainq[mainq_tail].when = when;
        mainq_tail = next;
    }
    pthread_mutex_unlock(&mainq_lock);
}

static void mainq_push(void *block, double when)
{
    mainq_push_item(block, NULL, NULL, when);
}

static void global_invoke(void *arg)
{
    call_block(arg);
    _Block_release(arg);
}

void dispatch_async(void *queue, void *block)
{
    if (!block)
        return;
    block = _Block_copy(block);
    if (queue == &main_queue || queue == NULL)
    {
        mainq_push(block, 0.0);
        return;
    }
    pthread_t thread;
    if (pthread_create(&thread, NULL, (void *(*)(void *))global_invoke, block) == 0)
        pthread_detach(thread);
    else
    {
        call_block(block);
        _Block_release(block);
    }
}

struct fn_call {
    void (*function)(void *);
    void *context;
};

static void *fn_invoke(void *arg)
{
    struct fn_call *call = arg;
    if (call->function)
        call->function(call->context);
    free(call);
    return NULL;
}

struct delayed_call {
    struct fn_call call;
    double when;
};

static void delay_until(double when)
{
    double delta = when - now_seconds();
    if (delta <= 0)
        return;
    struct timespec ts;
    ts.tv_sec = (time_t)delta;
    ts.tv_nsec = (long)((delta - (double)ts.tv_sec) * 1e9);
    while (nanosleep(&ts, &ts) != 0 && errno == EINTR)
        ;
}

static void *delayed_invoke(void *arg)
{
    struct delayed_call *call = arg;
    delay_until(call->when);
    if (call->call.function)
        call->call.function(call->call.context);
    free(call);
    return NULL;
}

void dispatch_async_f(void *queue, void *context, void (*function)(void *))
{
    if (!function)
        return;
    if (queue == &main_queue || queue == NULL)
    {
        mainq_push_item(NULL, function, context, 0.0);
        return;
    }
    struct fn_call *call = malloc(sizeof(*call));
    if (!call)
    {
        function(context);
        return;
    }
    call->function = function;
    call->context = context;
    pthread_t thread;
    if (pthread_create(&thread, NULL, fn_invoke, call) == 0)
        pthread_detach(thread);
    else
    {
        function(context);
        free(call);
    }
}

void dispatch_sync(void *queue, void *block)
{
    (void)queue;
    call_block(block);
}
void dispatch_sync_f(void *queue, void *context, void (*function)(void *))
{
    (void)queue;
    if (function)
        function(context);
}

typedef uint64_t dispatch_time_t;
dispatch_time_t dispatch_time(dispatch_time_t base, int64_t delta)
{
    (void)base;
    return (dispatch_time_t)(now_seconds() * 1e9 + delta);
}

struct delayed_block {
    void *block;
    double when;
};

static void *delayed_block_invoke(void *arg)
{
    struct delayed_block *call = arg;
    delay_until(call->when);
    call_block(call->block);
    _Block_release(call->block);
    free(call);
    return NULL;
}

void dispatch_after(dispatch_time_t when, void *queue, void *block)
{
    double t = (double)when / 1e9;
    if (!block)
        return;
    if (queue == &main_queue || queue == NULL)
    {
        mainq_push(_Block_copy(block), t);
        return;
    }
    struct delayed_block *call = malloc(sizeof(*call));
    if (!call)
    {
        call_block(block);
        return;
    }
    call->block = _Block_copy(block);
    call->when = t;
    pthread_t thread;
    if (pthread_create(&thread, NULL, delayed_block_invoke, call) == 0)
        pthread_detach(thread);
    else
    {
        call_block(call->block);
        _Block_release(call->block);
        free(call);
    }
}
void dispatch_after_f(dispatch_time_t when, void *queue, void *context,
                      void (*function)(void *))
{
    if (!function)
        return;
    double t = (double)when / 1e9;
    if (queue == &main_queue || queue == NULL)
    {
        mainq_push_item(NULL, function, context, t);
        return;
    }
    struct delayed_call *call = malloc(sizeof(*call));
    if (!call)
    {
        function(context);
        return;
    }
    call->call.function = function;
    call->call.context = context;
    call->when = t;
    pthread_t thread;
    if (pthread_create(&thread, NULL, delayed_invoke, call) == 0)
        pthread_detach(thread);
    else
    {
        function(context);
        free(call);
    }
}
void dispatch_after_f_np(dispatch_time_t when, void *queue, void *context,
                         void (*function)(void *))
{
    dispatch_after_f(when, queue, context, function);
}

int iosim_dispatch_drain_main(void)
{
    int ran = 0;
    for (;;)
    {
        void *block = NULL;
        void (*function)(void *) = NULL;
        void *context = NULL;
        double now = now_seconds();
        pthread_mutex_lock(&mainq_lock);
        if (mainq_head != mainq_tail && mainq[mainq_head].when <= now)
        {
            block = mainq[mainq_head].block;
            function = mainq[mainq_head].function;
            context = mainq[mainq_head].context;
            mainq_head = (mainq_head + 1) % MAINQ_CAP;
        }
        pthread_mutex_unlock(&mainq_lock);
        if (!block && !function)
            break;
        if (getenv("IOSIM_DEBUG_DISPATCH"))
            fprintf(stderr, "[dispatch] run %p/%p at %.3f\n", block,
                    (void *)function, now_seconds());
        if (block)
        {
            call_block(block);
            _Block_release(block);
        }
        else
        {
            function(context);
        }
        ran++;
    }
    return ran;
}

void dispatch_main(void)
{
    /* Darwin declares dispatch_main noreturn; callers may have optimized away
     * everything after the call. Drain due work, then keep the main thread
     * alive. */
    for (;;)
    {
        iosim_dispatch_drain_main();
        usleep(1000);
    }
}
void *dispatch_get_current_queue(void) { return &main_queue; }
const char *dispatch_queue_get_label(void *queue)
{
    return queue == &main_queue ? "com.apple.main-thread" : "iosim.queue";
}
void dispatch_queue_set_specific(void *queue, const void *key, void *context,
                                 void (*destructor)(void *))
{
    (void)queue; (void)key; (void)context; (void)destructor;
}
void *dispatch_get_specific(const void *key) { (void)key; return NULL; }
void dispatch_barrier_async(void *queue, void *block)
{
    dispatch_async(queue, block);
}
void dispatch_barrier_sync(void *queue, void *block)
{
    dispatch_sync(queue, block);
}
void dispatch_apply(long iterations, void *queue, void *block)
{
    (void)queue;
    if (!block)
        return;
    for (long i = 0; i < iterations; i++)
        ((void (*)(void *, long))((struct block_layout *)block)->invoke)(block, i);
}

typedef long dispatch_once_t;
void dispatch_once(dispatch_once_t *predicate, void *block)
{
    if (predicate && __sync_bool_compare_and_swap(predicate, 0, 1))
        call_block(block);
}

/* ------------------------------------------------------- dispatch_data */

struct dispatch_data_s {
    const void *buffer;
    size_t size;
};

void *dispatch_data_create(const void *buffer, size_t size, void *queue,
                           void *destructor)
{
    (void)queue;
    (void)destructor; /* data outlives the guest's buffers in this runtime */
    struct dispatch_data_s *data = calloc(1, sizeof(*data));
    if (!data)
        return NULL;
    data->buffer = buffer;
    data->size = size;
    return data;
}

size_t dispatch_data_get_size(void *data)
{
    return data ? ((struct dispatch_data_s *)data)->size : 0;
}

int dispatch_data_apply(void *data, void *applier)
{
    struct dispatch_data_s *d = data;
    if (!d || !applier)
        return 0;
    struct block_layout *b = applier;
    if (!b->invoke)
        return 0;
    return ((int (*)(void *, void *, size_t, const void *, size_t))b->invoke)(
               applier, data, 0, d->buffer, d->size) != 0;
}

void *dispatch_data_create_concat(void *first, void *second)
{
    struct dispatch_data_s *a = first, *b = second;
    size_t as = a ? a->size : 0, bs = b ? b->size : 0;
    unsigned char *buf = malloc(as + bs ? as + bs : 1);
    if (!buf)
        return NULL;
    if (as)
        memcpy(buf, a->buffer, as);
    if (bs)
        memcpy(buf + as, b->buffer, bs);
    return dispatch_data_create(buf, as + bs, NULL, NULL);
}

void *dispatch_data_create_subrange(void *data, size_t offset, size_t length)
{
    struct dispatch_data_s *d = data;
    if (!d || offset > d->size)
        return NULL;
    if (length > d->size - offset)
        length = d->size - offset;
    unsigned char *buf = malloc(length ? length : 1);
    if (!buf)
        return NULL;
    memcpy(buf, (const unsigned char *)d->buffer + offset, length);
    return dispatch_data_create(buf, length, NULL, NULL);
}

void *dispatch_data_create_map(void *data, const void **buffer_ptr,
                               size_t *size_ptr)
{
    struct dispatch_data_s *d = data;
    if (!d)
        return NULL;
    if (buffer_ptr)
        *buffer_ptr = d->buffer;
    if (size_ptr)
        *size_ptr = d->size;
    return data;
}

struct dispatch_group_s { long count; };
void *dispatch_group_create(void) { return calloc(1, sizeof(struct dispatch_group_s)); }
void dispatch_group_enter(void *group)
{
    if (group) __sync_add_and_fetch(&((struct dispatch_group_s *)group)->count, 1);
}
void dispatch_group_leave(void *group)
{
    if (group) __sync_sub_and_fetch(&((struct dispatch_group_s *)group)->count, 1);
}
long dispatch_group_wait(void *group, dispatch_time_t timeout)
{
    (void)timeout;
    while (group && ((struct dispatch_group_s *)group)->count > 0)
        usleep(1000);
    return 0;
}
void dispatch_group_notify(void *group, void *queue, void *block)
{
    dispatch_group_wait(group, 0);
    dispatch_async(queue, block);
}
struct group_async_ctx {
    void *group;
    void *block;
};

static void *group_async_invoke(void *arg)
{
    struct group_async_ctx *ctx = arg;
    call_block(ctx->block);
    _Block_release(ctx->block);
    dispatch_group_leave(ctx->group);
    free(ctx);
    return NULL;
}

void dispatch_group_async(void *group, void *queue, void *block)
{
    if (!group || !block)
    {
        dispatch_async(queue, block);
        return;
    }
    if (queue == &main_queue || queue == NULL)
    {
        /* The main queue is drained by the host event loop; the block still
         * runs there, and it is counted as scheduled for the group. */
        dispatch_group_enter(group);
        dispatch_async(queue, block);
        dispatch_group_leave(group);
        return;
    }
    dispatch_group_enter(group);
    struct group_async_ctx *ctx = malloc(sizeof(*ctx));
    if (!ctx)
    {
        dispatch_async(queue, block);
        dispatch_group_leave(group);
        return;
    }
    ctx->group = group;
    ctx->block = _Block_copy(block);
    pthread_t thread;
    if (pthread_create(&thread, NULL, group_async_invoke, ctx) == 0)
        pthread_detach(thread);
    else
        group_async_invoke(ctx);
}

struct dispatch_semaphore_s {
    pthread_mutex_t lock;
    pthread_cond_t cond;
    long value;
};
void *dispatch_semaphore_create(long value)
{
    struct dispatch_semaphore_s *s = calloc(1, sizeof(*s));
    pthread_mutex_init(&s->lock, NULL);
    pthread_cond_init(&s->cond, NULL);
    s->value = value;
    return s;
}
long dispatch_semaphore_wait(void *sem, dispatch_time_t timeout)
{
    (void)timeout;
    struct dispatch_semaphore_s *s = sem;
    if (!s) return 1;
    pthread_mutex_lock(&s->lock);
    while (s->value <= 0)
        pthread_cond_wait(&s->cond, &s->lock);
    s->value--;
    pthread_mutex_unlock(&s->lock);
    return 0;
}
long dispatch_semaphore_signal(void *sem)
{
    struct dispatch_semaphore_s *s = sem;
    if (!s) return 0;
    pthread_mutex_lock(&s->lock);
    s->value++;
    pthread_cond_signal(&s->cond);
    pthread_mutex_unlock(&s->lock);
    return 0;
}

/* ---------------------------------------------------------- Mach ports */

#define MAX_PORTS 256
#define MAX_MSGS 64
struct mach_msg_node {
    void *data;
    uint32_t size;
    struct mach_msg_node *next;
};
struct mach_port_s {
    int used;
    struct mach_msg_node *head, *tail;
    pthread_mutex_t lock;
    pthread_cond_t cond;
    /* Cross-process rights: a service receive port owns a listening Unix
     * socket; a send port obtained from bootstrap_look_up owns a connected
     * one. -1 means the port is process-local only. */
    int listen_fd;
    int peer_fd;
    char service[96];
    /* An XPC listener's accepted clients become peer connections instead of
     * Mach message sources. */
    int xpc_listener;
};
static struct mach_port_s ports[MAX_PORTS];
static int port_counter = 2;
static pthread_mutex_t ports_lock = PTHREAD_MUTEX_INITIALIZER;
uint32_t bootstrap_port_value = 1;
uint32_t mach_task_self_value = 1;

static struct mach_port_s *port_get(uint32_t name)
{
    if (name == 0 || name >= MAX_PORTS)
        return NULL;
    if (!ports[name].used)
        return NULL;
    return &ports[name];
}

/* Allocate a fresh local port name, optionally backed by a connected peer
 * socket. Caller holds no locks; the name space is process-local. */
static uint32_t port_new(int peer_fd)
{
    pthread_mutex_lock(&ports_lock);
    if (port_counter >= MAX_PORTS)
        port_counter = 2;
    uint32_t p = port_counter++;
    ports[p].used = 1;
    ports[p].head = ports[p].tail = NULL;
    pthread_mutex_init(&ports[p].lock, NULL);
    pthread_cond_init(&ports[p].cond, NULL);
    ports[p].listen_fd = -1;
    ports[p].peer_fd = peer_fd;
    ports[p].service[0] = 0;
    ports[p].xpc_listener = 0;
    pthread_mutex_unlock(&ports_lock);
    return p;
}

int mach_port_allocate(uint32_t task, uint32_t right, uint32_t *name)
{
    (void)task; (void)right;
    uint32_t p = port_new(-1);
    if (name)
        *name = p;
    return 0;
}
int mach_port_deallocate(uint32_t task, uint32_t name) { (void)task; (void)name; return 0; }
int mach_port_mod_refs(uint32_t task, uint32_t name, int right, int delta)
{
    (void)task; (void)name; (void)right; (void)delta;
    return 0;
}
int mach_port_insert_right(uint32_t task, uint32_t name, uint32_t poly, uint32_t poly_poly)
{
    (void)task; (void)name; (void)poly; (void)poly_poly;
    return 0;
}
int mach_port_destroy(uint32_t task, uint32_t name) { (void)task; (void)name; return 0; }
uint32_t mach_task_self(void) { return 1; }
uint32_t mach_host_self(void) { return 1; }

typedef struct {
    uint32_t msgh_bits;
    uint32_t msgh_size;
    uint32_t msgh_remote_port;
    uint32_t msgh_local_port;
    uint32_t msgh_voucher_port;
    int32_t msgh_id;
} mach_msg_header_t;

#define MACH_SEND_MSG 0x1
#define MACH_RCV_MSG 0x2
#define MACH_RCV_TIMEOUT 0x100

int mach_msg(mach_msg_header_t *msg, uint32_t option, uint32_t send_size,
             uint32_t rcv_size, uint32_t rcv_name, uint32_t timeout,
             uint32_t notify)
{
    (void)notify;
    if (option & MACH_SEND_MSG)
    {
        struct mach_port_s *p = port_get(msg->msgh_remote_port);
        if (!p)
            return 0x10000002; /* MACH_SEND_INVALID_DEST */
        if (p->peer_fd >= 0)
        {
            /* The destination lives in another guest process: the message
             * travels as one datagram on a connected Unix socket. */
            ssize_t n = send(p->peer_fd, msg, send_size, MSG_NOSIGNAL);
            if (n != (ssize_t)send_size)
                return 0x10000002;
            return 0;
        }
        struct mach_msg_node *node = calloc(1, sizeof(*node));
        node->data = malloc(send_size);
        memcpy(node->data, msg, send_size);
        node->size = send_size;
        pthread_mutex_lock(&p->lock);
        if (p->tail) p->tail->next = node; else p->head = node;
        p->tail = node;
        pthread_cond_broadcast(&p->cond);
        pthread_mutex_unlock(&p->lock);
    }
    if (option & MACH_RCV_MSG)
    {
        struct mach_port_s *p = port_get(rcv_name);
        if (!p)
            return 0x10004002; /* MACH_RCV_INVALID_NAME */
        pthread_mutex_lock(&p->lock);
        if ((option & MACH_RCV_TIMEOUT) && timeout > 0)
        {
            struct timespec deadline;
            clock_gettime(CLOCK_REALTIME, &deadline);
            deadline.tv_sec += timeout / 1000;
            deadline.tv_nsec += (long)(timeout % 1000) * 1000000L;
            if (deadline.tv_nsec >= 1000000000L)
            {
                deadline.tv_sec += 1;
                deadline.tv_nsec -= 1000000000L;
            }
            while (!p->head)
            {
                if (pthread_cond_timedwait(&p->cond, &p->lock, &deadline) ==
                    ETIMEDOUT)
                    break;
            }
            if (!p->head)
            {
                pthread_mutex_unlock(&p->lock);
                return 0x10004003; /* MACH_RCV_TIMED_OUT */
            }
        }
        else
            while (!p->head)
                pthread_cond_wait(&p->cond, &p->lock);
        struct mach_msg_node *node = p->head;
        p->head = node->next;
        if (!p->head) p->tail = NULL;
        pthread_mutex_unlock(&p->lock);
        uint32_t n = node->size < rcv_size ? node->size : rcv_size;
        memcpy(msg, node->data, n);
        free(node->data);
        free(node);
    }
    return 0;
}

int mach_msg_send(mach_msg_header_t *msg) { return mach_msg(msg, MACH_SEND_MSG, msg->msgh_size, 0, 0, 0, 0); }
int mach_msg_receive(mach_msg_header_t *msg)
{
    return mach_msg(msg, MACH_RCV_MSG, 0, msg->msgh_size, msg->msgh_local_port, 0, 0);
}

/* ------------------------------------------------------ bootstrap namespace
 *
 * launchd_sim owns the namespace: a registration is a name and the pid that
 * registered it. On top of that, each registered Mach receive port owns an
 * abstract-namespace Unix socket (Linux) whose address both processes derive
 * from the device UDID and the service name. A lookup in another process
 * connects to that socket and returns a send port; mach_msg on it writes one
 * datagram, which a reader thread in the service process turns back into a
 * message on the registered port's queue.
 *
 * When no launchd is reachable (a direct iosim-run invocation), registration
 * and lookup fall back to a process-local registry. */

#define SVC_NAME_MAX 88
#define SVC_ADDR_MAX 108
#define SVC_FRAME_MAX 65536
#define SVC_MAX_CLIENTS 32

struct service { char name[128]; uint32_t port; };
static struct service services[128];
static int service_count;
static pthread_mutex_t services_lock = PTHREAD_MUTEX_INITIALIZER;

static uint32_t fnv1a32(const char *s)
{
    uint32_t h = 2166136261u;
    while (*s)
    {
        h ^= (unsigned char)*s++;
        h *= 16777619u;
    }
    return h;
}

static const char *simulator_udid(void)
{
    const char *u = getenv("SIMULATOR_UDID");
    return u && *u ? u : NULL;
}

/* Abstract socket address shared by every process on the same device. */
static int service_address(const char *name, char *out, size_t cap)
{
    const char *udid = simulator_udid();
    if (!udid || !name || strlen(name) > SVC_NAME_MAX || cap < SVC_ADDR_MAX)
        return -1;
    snprintf(out, cap, "iosim-svc:%08x:%s", fnv1a32(udid), name);
    return 0;
}

static socklen_t service_sockaddr(const char *address, struct sockaddr_un *sun)
{
    size_t len = strlen(address);
    memset(sun, 0, sizeof(*sun));
    sun->sun_family = AF_UNIX;
    sun->sun_path[0] = 0; /* abstract namespace */
    memcpy(sun->sun_path + 1, address, len);
    return (socklen_t)(offsetof(struct sockaddr_un, sun_path) + 1 + len);
}

static int launchd_call(const char *request, char *reply, size_t cap)
{
    const char *udid = simulator_udid();
    if (!udid)
        return -1;
    char path[128];
    snprintf(path, sizeof(path), "/tmp/iosim-launchd-%s.sock", udid);
    int fd = socket(AF_UNIX, SOCK_STREAM, 0);
    if (fd < 0)
        return -1;
    struct sockaddr_un sun;
    if (strlen(path) >= sizeof(sun.sun_path))
    {
        close(fd);
        return -1;
    }
    memset(&sun, 0, sizeof(sun));
    sun.sun_family = AF_UNIX;
    strcpy(sun.sun_path, path);
    if (connect(fd, (struct sockaddr *)&sun, sizeof(sun)) != 0)
    {
        close(fd);
        return -1;
    }
    size_t len = strlen(request);
    if (write(fd, request, len) != (ssize_t)len)
    {
        close(fd);
        return -1;
    }
    size_t used = 0;
    while (used + 1 < cap)
    {
        ssize_t n = read(fd, reply + used, cap - 1 - used);
        if (n <= 0)
            break;
        used += (size_t)n;
        if (memchr(reply, '\n', used))
            break;
    }
    close(fd);
    reply[used] = 0;
    return 0;
}

/* Service names come from apps, so the JSON request must stay well formed. */
static void json_escape(const char *in, char *out, size_t cap)
{
    size_t o = 0;
    for (const char *p = in; *p && o + 7 < cap; p++)
    {
        unsigned char c = (unsigned char)*p;
        if (c == '"' || c == '\\')
        {
            out[o++] = '\\';
            out[o++] = (char)c;
        }
        else if (c < 0x20)
            o += (size_t)snprintf(out + o, cap - o, "\\u%04x", c);
        else
            out[o++] = (char)c;
    }
    out[o] = 0;
}

/* 0 registered, 1103 service active, 1 no launchd, -1 protocol error. */
static int launchd_register_service(const char *name)
{
    char esc[256];
    char req[512], reply[512];
    json_escape(name, esc, sizeof(esc));
    snprintf(req, sizeof(req),
             "{\"cmd\": \"service_register\", \"name\": \"%s\", \"pid\": %d}\n",
             esc, (int)getpid());
    if (launchd_call(req, reply, sizeof(reply)) != 0)
        return 1;
    if (strstr(reply, "\"ok\": true"))
        return 0;
    if (strstr(reply, "active"))
        return 1103; /* BOOTSTRAP_SERVICE_ACTIVE */
    return -1;
}

/* 0 known, 1102 unknown, -1 no launchd. A LaunchDaemon job whose
 * MachServices name is looked up starts on demand; launchd reports
 * "starting" until the job's process has registered the name, so retry
 * across that window (the lookup blocks like the real bootstrap server). */
static int launchd_lookup_service(const char *name)
{
    char esc[256];
    char req[512], reply[512];
    json_escape(name, esc, sizeof(esc));
    snprintf(req, sizeof(req),
             "{\"cmd\": \"service_lookup\", \"name\": \"%s\"}\n", esc);
    for (int attempt = 0; attempt < 120; attempt++)
    {
        if (launchd_call(req, reply, sizeof(reply)) != 0)
            return -1;
        if (strstr(reply, "\"ok\": true"))
            return 0;
        if (!strstr(reply, "starting"))
            return 1102;
        usleep(50000);
    }
    return 1102;
}

static void mach_port_enqueue(uint32_t name, const void *bytes, uint32_t size)
{
    struct mach_msg_node *node = calloc(1, sizeof(*node));
    if (!node)
        return;
    node->data = malloc(size ? size : 1);
    if (!node->data)
    {
        free(node);
        return;
    }
    memcpy(node->data, bytes, size);
    node->size = size;
    struct mach_port_s *p = &ports[name];
    pthread_mutex_lock(&p->lock);
    if (p->tail)
        p->tail->next = node;
    else
        p->head = node;
    p->tail = node;
    pthread_cond_broadcast(&p->cond);
    pthread_mutex_unlock(&p->lock);
}

/* Defined with the XPC transport below; an XPC listener hands each accepted
 * client socket to it so the connection becomes a peer connection. */
void xpc_accept_fd(uint32_t listener_port, int fd);

/* Accepts connections from senders in other processes and turns each
 * datagram into a queued Mach message on the service port. */
static void *service_reader(void *arg)
{
    uint32_t name = (uint32_t)(uintptr_t)arg;
    struct mach_port_s *p = &ports[name];
    int clients[SVC_MAX_CLIENTS];
    int nclients = 0;
    struct pollfd fds[SVC_MAX_CLIENTS + 1];
    unsigned char frame[SVC_FRAME_MAX];

    for (;;)
    {
        fds[0].fd = p->listen_fd;
        fds[0].events = POLLIN;
        for (int i = 0; i < nclients; i++)
        {
            fds[i + 1].fd = clients[i];
            fds[i + 1].events = POLLIN;
        }
        if (poll(fds, (nfds_t)(nclients + 1), -1) < 0)
        {
            if (errno == EINTR)
                continue;
            return NULL;
        }
        if (fds[0].revents & POLLIN)
        {
            for (;;)
            {
                int c = accept(p->listen_fd, NULL, NULL);
                if (c < 0)
                    break;
                if (p->xpc_listener)
                {
                    xpc_accept_fd(name, c);
                    continue;
                }
                if (nclients < SVC_MAX_CLIENTS)
                {
                    int fl = fcntl(c, F_GETFL, 0);
                    fcntl(c, F_SETFL, fl | O_NONBLOCK);
                    clients[nclients++] = c;
                }
                else
                    close(c);
            }
        }
        for (int i = 0; i < nclients; i++)
        {
            if (!(fds[i + 1].revents & (POLLIN | POLLHUP | POLLERR)))
                continue;
            int removed = 0;
            for (;;)
            {
                ssize_t r = recv(clients[i], frame, sizeof(frame), MSG_DONTWAIT);
                if (r > 0)
                    mach_port_enqueue(name, frame, (uint32_t)r);
                else if (r < 0 && (errno == EAGAIN || errno == EWOULDBLOCK))
                    break;
                else
                {
                    close(clients[i]);
                    clients[i] = clients[--nclients];
                    removed = 1;
                    break;
                }
            }
            if (removed)
                i--;
        }
    }
    return NULL;
}

/* Turn an existing local port into a registered service endpoint. */
static int port_listen(uint32_t name, const char *service)
{
    char address[SVC_ADDR_MAX];
    if (service_address(service, address, sizeof(address)) != 0)
        return -1;
    int fd = socket(AF_UNIX, SOCK_SEQPACKET, 0);
    if (fd < 0)
        return -1;
    struct sockaddr_un sun;
    socklen_t slen = service_sockaddr(address, &sun);
    fcntl(fd, F_SETFL, fcntl(fd, F_GETFL, 0) | O_NONBLOCK);
    if (bind(fd, (struct sockaddr *)&sun, slen) != 0)
    {
        int e = errno;
        close(fd);
        return e == EADDRINUSE ? 1103 : -1;
    }
    if (listen(fd, 8) != 0)
    {
        close(fd);
        return -1;
    }
    struct mach_port_s *p = port_get(name);
    if (!p)
    {
        close(fd);
        return -1;
    }
    pthread_mutex_lock(&ports_lock);
    p->listen_fd = fd;
    snprintf(p->service, sizeof(p->service), "%s", service);
    pthread_mutex_unlock(&ports_lock);
    pthread_t thread;
    if (pthread_create(&thread, NULL, service_reader,
                       (void *)(uintptr_t)name) != 0)
        return -1;
    pthread_detach(thread);
    return 0;
}

/* Connect to another process's service and return a send port for it. */
static int port_connect(const char *service, uint32_t *out)
{
    char address[SVC_ADDR_MAX];
    if (service_address(service, address, sizeof(address)) != 0)
        return 1102;
    int fd = socket(AF_UNIX, SOCK_SEQPACKET, 0);
    if (fd < 0)
        return 1102;
    struct sockaddr_un sun;
    socklen_t slen = service_sockaddr(address, &sun);
    if (connect(fd, (struct sockaddr *)&sun, slen) != 0)
    {
        close(fd);
        return 1102;
    }
    *out = port_new(fd);
    return 0;
}

int bootstrap_register(uint32_t bp, const char *name, uint32_t port)
{
    (void)bp;
    if (!name || !port || strlen(name) > SVC_NAME_MAX)
        return 1102;
    int launched = launchd_register_service(name);
    if (launched == 1103)
        return 1103;
    if (launched == 0)
    {
        int lr = port_listen(port, name);
        if (lr == 1103)
            return 1103;
    }
    pthread_mutex_lock(&services_lock);
    if (service_count < 128)
    {
        snprintf(services[service_count].name, sizeof(services[service_count].name), "%s", name);
        services[service_count].port = port;
        service_count++;
    }
    pthread_mutex_unlock(&services_lock);
    return 0;
}

int bootstrap_look_up(uint32_t bp, const char *name, uint32_t *port)
{
    (void)bp;
    if (!name || !port || strlen(name) > SVC_NAME_MAX)
        return 1102;
    pthread_mutex_lock(&services_lock);
    for (int i = 0; i < service_count; i++)
    {
        if (strcmp(services[i].name, name) == 0)
        {
            *port = services[i].port;
            pthread_mutex_unlock(&services_lock);
            return 0;
        }
    }
    pthread_mutex_unlock(&services_lock);
    /* Another process may have registered it with launchd. */
    if (launchd_lookup_service(name) != 0)
        return 1102; /* BOOTSTRAP_UNKNOWN_SERVICE */
    /* The registration is recorded before the service socket is bound, so a
     * freshly started job may need a moment before connect succeeds. */
    for (int attempt = 0; attempt < 100; attempt++)
    {
        if (port_connect(name, port) == 0)
            return 0;
        usleep(20000);
    }
    return 1102;
}

/* ---------------------------------------------------------------- XPC */

enum { XPC_DICT = 1, XPC_STRING = 2, XPC_INT = 3, XPC_BOOL = 4,
       XPC_DATA = 5, XPC_ARRAY = 6, XPC_ERROR = 7, XPC_CONNECTION = 8 };

struct xpc_object {
    int type;
    long refs;
    char *str;
    int64_t i64;
    void *data;
    size_t data_len;
    void *items[64];
    char *keys[64];
    int count;
    /* XPC_CONNECTION objects delivered to a listener wrap a peer. */
    void *conn;
};

static struct xpc_object *xpc_new(int type)
{
    struct xpc_object *o = calloc(1, sizeof(*o));
    o->type = type;
    o->refs = 1;
    return o;
}
void *xpc_retain(void *obj) { if (obj) ((struct xpc_object *)obj)->refs++; return obj; }
void xpc_release(void *obj)
{
    if (!obj) return;
    struct xpc_object *o = obj;
    if (--o->refs <= 0) free(o);
}
void *xpc_dictionary_create(const void *keys, const void *values, unsigned long count)
{
    (void)keys; (void)values; (void)count;
    return xpc_new(XPC_DICT);
}
void *xpc_dictionary_create_empty(void) { return xpc_new(XPC_DICT); }
void *xpc_array_create(const void **objects, unsigned long count)
{
    struct xpc_object *a = xpc_new(XPC_ARRAY);
    for (unsigned long i = 0; i < count && i < 64; i++)
        a->items[a->count++] = (void *)objects[i];
    return a;
}
void *xpc_string_create(const char *s)
{
    struct xpc_object *o = xpc_new(XPC_STRING);
    o->str = strdup(s ? s : "");
    return o;
}
void *xpc_int64_create(int64_t v) { struct xpc_object *o = xpc_new(XPC_INT); o->i64 = v; return o; }
void *xpc_bool_create(int v) { struct xpc_object *o = xpc_new(XPC_BOOL); o->i64 = v ? 1 : 0; return o; }
void *xpc_data_create(const void *bytes, unsigned long length)
{
    struct xpc_object *o = xpc_new(XPC_DATA);
    o->data = malloc(length);
    memcpy(o->data, bytes, length);
    o->data_len = length;
    return o;
}
void *xpc_null_create(void) { return xpc_new(XPC_STRING); }

void xpc_dictionary_set_value(void *dict, const char *key, void *value)
{
    struct xpc_object *d = dict;
    if (!d || d->type != XPC_DICT || d->count >= 64) return;
    d->keys[d->count] = strdup(key);
    d->items[d->count] = value;
    d->count++;
}
void *xpc_dictionary_get_value(void *dict, const char *key)
{
    struct xpc_object *d = dict;
    if (!d || d->type != XPC_DICT) return NULL;
    for (int i = 0; i < d->count; i++)
        if (strcmp(d->keys[i], key) == 0)
            return d->items[i];
    return NULL;
}
void xpc_dictionary_set_string(void *dict, const char *key, const char *value)
{ xpc_dictionary_set_value(dict, key, xpc_string_create(value)); }
void xpc_dictionary_set_int64(void *dict, const char *key, int64_t value)
{ xpc_dictionary_set_value(dict, key, xpc_int64_create(value)); }
void xpc_dictionary_set_bool(void *dict, const char *key, int value)
{ xpc_dictionary_set_value(dict, key, xpc_bool_create(value)); }
void xpc_dictionary_set_data(void *dict, const char *key, const void *bytes, unsigned long length)
{ xpc_dictionary_set_value(dict, key, xpc_data_create(bytes, length)); }
const char *xpc_dictionary_get_string(void *dict, const char *key)
{ struct xpc_object *o = xpc_dictionary_get_value(dict, key); return o && o->type == XPC_STRING ? o->str : NULL; }
int64_t xpc_dictionary_get_int64(void *dict, const char *key)
{ struct xpc_object *o = xpc_dictionary_get_value(dict, key); return o ? o->i64 : 0; }
int xpc_bool_get_value(void *obj) { struct xpc_object *o = obj; return o && o->i64; }
const char *xpc_string_get_string_ptr(void *obj) { struct xpc_object *o = obj; return o ? o->str : NULL; }
const void *xpc_data_get_bytes_ptr(void *obj) { struct xpc_object *o = obj; return o ? o->data : NULL; }
size_t xpc_data_get_length(void *obj) { struct xpc_object *o = obj; return o ? o->data_len : 0; }
const char *xpc_copy_description(void *obj) { (void)obj; return "xpc-object"; }

/* Serialized XPC messages: one tagged object tree per Mach datagram. The
 * frame travels on the bootstrap service's socket; the receiving process
 * rebuilds the object graph and hands it to the listener's event handler. */
#define XPC_FRAME_MAGIC 0x58504331u /* "XPC1" */
#define XPC_PAYLOAD_MAX 60000
#define XPC_DEPTH_MAX 16

enum { XPC_KIND_MESSAGE = 0, XPC_KIND_REQUEST = 1, XPC_KIND_REPLY = 2 };

typedef struct {
    mach_msg_header_t header;
    uint32_t magic;
    uint32_t length;
    int32_t sender;
    uint32_t kind;
    uint32_t reserved;
    uint64_t request_id;
    unsigned char payload[XPC_PAYLOAD_MAX];
} xpc_frame;

#define XPC_FRAME_HEADER offsetof(xpc_frame, payload)

static int xpc_encode_into(struct xpc_object *o, unsigned char *buf, size_t cap,
                           size_t *pos, int depth)
{
    if (depth > XPC_DEPTH_MAX || *pos + 1 > cap)
        return -1;
    if (!o)
    {
        buf[(*pos)++] = 0; /* null */
        return 0;
    }
    buf[(*pos)++] = (unsigned char)o->type;
    switch (o->type)
    {
    case XPC_DICT:
    {
        uint32_t n = (uint32_t)o->count;
        if (*pos + 4 > cap)
            return -1;
        memcpy(buf + *pos, &n, 4);
        *pos += 4;
        for (int i = 0; i < o->count; i++)
        {
            const char *key = o->keys[i] ? o->keys[i] : "";
            uint32_t kl = (uint32_t)strlen(key);
            if (*pos + 4 + kl > cap)
                return -1;
            memcpy(buf + *pos, &kl, 4);
            *pos += 4;
            memcpy(buf + *pos, key, kl);
            *pos += kl;
            if (xpc_encode_into(o->items[i], buf, cap, pos, depth + 1) != 0)
                return -1;
        }
        return 0;
    }
    case XPC_ARRAY:
    {
        uint32_t n = (uint32_t)o->count;
        if (*pos + 4 > cap)
            return -1;
        memcpy(buf + *pos, &n, 4);
        *pos += 4;
        for (int i = 0; i < o->count; i++)
            if (xpc_encode_into(o->items[i], buf, cap, pos, depth + 1) != 0)
                return -1;
        return 0;
    }
    case XPC_STRING:
    {
        const char *str = o->str ? o->str : "";
        uint32_t l = (uint32_t)strlen(str);
        if (*pos + 4 + l > cap)
            return -1;
        memcpy(buf + *pos, &l, 4);
        *pos += 4;
        memcpy(buf + *pos, str, l);
        *pos += l;
        return 0;
    }
    case XPC_INT:
        if (*pos + 8 > cap)
            return -1;
        memcpy(buf + *pos, &o->i64, 8);
        *pos += 8;
        return 0;
    case XPC_BOOL:
        if (*pos + 1 > cap)
            return -1;
        buf[(*pos)++] = o->i64 ? 1 : 0;
        return 0;
    case XPC_DATA:
    {
        uint32_t l = (uint32_t)o->data_len;
        if (*pos + 4 + l > cap)
            return -1;
        memcpy(buf + *pos, &l, 4);
        *pos += 4;
        if (l)
            memcpy(buf + *pos, o->data, l);
        *pos += l;
        return 0;
    }
    default:
        return -1;
    }
}

static int xpc_take(const unsigned char *buf, size_t len, size_t *pos,
                    void *out, size_t n)
{
    if (*pos + n > len)
        return -1;
    memcpy(out, buf + *pos, n);
    *pos += n;
    return 0;
}

static struct xpc_object *xpc_decode(const unsigned char *buf, size_t len,
                                     size_t *pos, int depth)
{
    if (depth > XPC_DEPTH_MAX || *pos >= len)
        return NULL;
    unsigned char type = buf[(*pos)++];
    if (type == 0)
        return xpc_new(XPC_STRING);
    if (type != XPC_DICT && type != XPC_ARRAY && type != XPC_STRING &&
        type != XPC_INT && type != XPC_BOOL && type != XPC_DATA)
        return NULL;
    struct xpc_object *o = xpc_new(type);
    switch (type)
    {
    case XPC_DICT:
    {
        uint32_t n = 0;
        if (xpc_take(buf, len, pos, &n, 4) != 0 || n > 64)
            return NULL;
        for (uint32_t i = 0; i < n; i++)
        {
            uint32_t kl = 0;
            if (xpc_take(buf, len, pos, &kl, 4) != 0 || kl > 4096 ||
                *pos + kl > len)
                return NULL;
            char *key = malloc(kl + 1);
            if (!key)
                return NULL;
            memcpy(key, buf + *pos, kl);
            key[kl] = 0;
            *pos += kl;
            struct xpc_object *value = xpc_decode(buf, len, pos, depth + 1);
            if (!value)
                return NULL;
            o->keys[o->count] = key;
            o->items[o->count] = value;
            o->count++;
        }
        return o;
    }
    case XPC_ARRAY:
    {
        uint32_t n = 0;
        if (xpc_take(buf, len, pos, &n, 4) != 0 || n > 64)
            return NULL;
        for (uint32_t i = 0; i < n; i++)
        {
            struct xpc_object *value = xpc_decode(buf, len, pos, depth + 1);
            if (!value)
                return NULL;
            o->items[o->count++] = value;
        }
        return o;
    }
    case XPC_STRING:
    {
        uint32_t l = 0;
        if (xpc_take(buf, len, pos, &l, 4) != 0 || *pos + l > len)
            return NULL;
        o->str = malloc(l + 1);
        if (!o->str)
            return NULL;
        memcpy(o->str, buf + *pos, l);
        o->str[l] = 0;
        *pos += l;
        return o;
    }
    case XPC_INT:
        if (xpc_take(buf, len, pos, &o->i64, 8) != 0)
            return NULL;
        return o;
    case XPC_BOOL:
        if (*pos + 1 > len)
            return NULL;
        o->i64 = buf[(*pos)++] != 0;
        return o;
    default: /* XPC_DATA */
    {
        uint32_t l = 0;
        if (xpc_take(buf, len, pos, &l, 4) != 0 || *pos + l > len)
            return NULL;
        o->data = malloc(l ? l : 1);
        if (!o->data)
            return NULL;
        memcpy(o->data, buf + *pos, l);
        o->data_len = l;
        *pos += l;
        return o;
    }
    }
}

struct xpc_connection {
    char *name;
    void *handler;
    unsigned long flags;
    uint32_t port;
    uint32_t listener_port;
    int started;
    int listener;
    /* xpc_connection_create() connections keep the in-process shortcut used
     * by unit fixtures; mach-service connections speak the socket protocol. */
    int convenience;
    /* A peer is the listener-side object for one accepted client socket. */
    int peer;
    int fd;
    int reader_started;
    uint64_t current_request;
    int peer_pid;
};
static struct xpc_connection *connections[64];
static int connection_count;

static void register_connection(struct xpc_connection *c)
{
    if (connection_count < 64)
        connections[connection_count++] = c;
}

static struct xpc_connection *connection_from_object(void *obj)
{
    if (!obj)
        return NULL;
    struct xpc_object *o = obj;
    if (o->type == XPC_CONNECTION && o->conn)
        return (struct xpc_connection *)o->conn;
    return (struct xpc_connection *)obj;
}

static void *xpc_connection_object(struct xpc_connection *c)
{
    struct xpc_object *o = xpc_new(XPC_CONNECTION);
    o->conn = c;
    return o;
}

void *xpc_connection_create_mach_service(const char *name, void *queue, unsigned long flags)
{
    (void)queue;
    struct xpc_connection *c = calloc(1, sizeof(*c));
    c->name = strdup(name ? name : "");
    c->flags = flags;
    /* XPC_CONNECTION_MACH_SERVICE_LISTENER = 1 */
    c->listener = (flags & 1) != 0;
    c->fd = -1;
    register_connection(c);
    return c;
}
void *xpc_connection_create(const char *name, void *queue)
{
    (void)queue;
    struct xpc_connection *c = calloc(1, sizeof(*c));
    c->name = strdup(name ? name : "");
    c->convenience = 1;
    c->fd = -1;
    register_connection(c);
    return c;
}
void xpc_connection_set_event_handler(void *conn, void *handler)
{
    struct xpc_connection *c = connection_from_object(conn);
    if (!c)
        return;
    /* Handlers may be stack blocks; the connection owns a heap copy. */
    if (c->handler)
        _Block_release(c->handler);
    c->handler = handler ? _Block_copy(handler) : NULL;
}
void xpc_connection_set_target_queue(void *conn, void *queue)
{
    (void)conn;
    (void)queue;
}

/* --------------------------------------------------- request/reply slots */

struct xpc_reply_slot {
    struct xpc_reply_slot *next;
    uint64_t id;
    void *handler;
    int sync;
    int done;
    void *reply;
    pthread_mutex_t lock;
    pthread_cond_t cond;
};
static struct xpc_reply_slot *reply_slots;
static pthread_mutex_t reply_lock = PTHREAD_MUTEX_INITIALIZER;
static uint64_t request_counter = 1;

static uint64_t xpc_next_request(void)
{
    pthread_mutex_lock(&reply_lock);
    uint64_t id = request_counter++;
    pthread_mutex_unlock(&reply_lock);
    return id;
}

static struct xpc_reply_slot *xpc_register_slot(uint64_t id, void *handler,
                                                int sync)
{
    struct xpc_reply_slot *slot = calloc(1, sizeof(*slot));
    if (!slot)
        return NULL;
    slot->id = id;
    slot->handler = handler ? _Block_copy(handler) : NULL;
    slot->sync = sync;
    pthread_mutex_init(&slot->lock, NULL);
    pthread_cond_init(&slot->cond, NULL);
    pthread_mutex_lock(&reply_lock);
    slot->next = reply_slots;
    reply_slots = slot;
    pthread_mutex_unlock(&reply_lock);
    return slot;
}

static void xpc_unlink_slot(struct xpc_reply_slot *slot)
{
    pthread_mutex_lock(&reply_lock);
    for (struct xpc_reply_slot **link = &reply_slots; *link;
         link = &(*link)->next)
        if (*link == slot)
        {
            *link = slot->next;
            break;
        }
    pthread_mutex_unlock(&reply_lock);
}

static void xpc_free_slot(struct xpc_reply_slot *slot)
{
    pthread_mutex_destroy(&slot->lock);
    pthread_cond_destroy(&slot->cond);
    if (slot->handler)
        _Block_release(slot->handler);
    free(slot);
}

static void xpc_deliver_reply(uint64_t id, void *event)
{
    struct xpc_reply_slot *slot = NULL;
    pthread_mutex_lock(&reply_lock);
    for (struct xpc_reply_slot **link = &reply_slots; *link;
         link = &(*link)->next)
        if ((*link)->id == id)
        {
            slot = *link;
            *link = slot->next;
            break;
        }
    pthread_mutex_unlock(&reply_lock);
    if (!slot)
        return;
    if (slot->sync)
    {
        pthread_mutex_lock(&slot->lock);
        slot->reply = event;
        slot->done = 1;
        pthread_cond_broadcast(&slot->cond);
        pthread_mutex_unlock(&slot->lock);
        return;
    }
    if (slot->handler)
        call_block_arg(slot->handler, event);
    xpc_free_slot(slot);
}

/* --------------------------------------------------------- socket readers */

/* One thread per connection socket. On a peer, frames are requests or
 * messages from the client and the handler's send becomes the reply. On a
 * client, reply frames are matched to pending request slots and everything
 * else goes to the connection's event handler. */
static void *xpc_reader_main(void *arg)
{
    struct xpc_connection *c = arg;
    xpc_frame *frame = calloc(1, sizeof(*frame));
    if (!frame)
        return NULL;
    for (;;)
    {
        ssize_t r = recv(c->fd, frame, sizeof(*frame), 0);
        if (r <= 0)
            break;
        if ((size_t)r < XPC_FRAME_HEADER)
            continue;
        if (frame->magic != XPC_FRAME_MAGIC ||
            frame->length > XPC_PAYLOAD_MAX)
            continue;
        size_t pos = 0;
        struct xpc_object *event =
            xpc_decode(frame->payload, frame->length, &pos, 0);
        if (!event)
            continue;
        if (c->peer)
        {
            c->peer_pid = frame->sender;
            uint64_t saved = c->current_request;
            c->current_request =
                frame->kind == XPC_KIND_REQUEST ? frame->request_id : 0;
            if (c->handler)
                call_block_arg(c->handler, event);
            c->current_request = saved;
        }
        else if (frame->kind == XPC_KIND_REPLY)
            xpc_deliver_reply(frame->request_id, event);
        else if (c->handler)
            call_block_arg(c->handler, event);
    }
    free(frame);
    return NULL;
}

static void xpc_start_reader(struct xpc_connection *c)
{
    if (c->reader_started || c->fd < 0)
        return;
    c->reader_started = 1;
    pthread_t thread;
    if (pthread_create(&thread, NULL, xpc_reader_main, c) == 0)
        pthread_detach(thread);
}

/* Resolve the bootstrap name to a connected socket, once per connection. */
static int xpc_ensure_fd(struct xpc_connection *c)
{
    if (c->fd >= 0)
    {
        xpc_start_reader(c);
        return 0;
    }
    if (c->port == 0)
    {
        uint32_t port = 0;
        if (bootstrap_look_up(bootstrap_port_value, c->name, &port) != 0)
            return -1;
        c->port = port;
    }
    struct mach_port_s *p = port_get(c->port);
    if (!p || p->peer_fd < 0)
        return -1;
    c->fd = p->peer_fd;
    xpc_start_reader(c);
    return 0;
}

static int xpc_write_frame(struct xpc_connection *c, uint32_t kind,
                           uint64_t request_id, void *message)
{
    if (c->fd < 0 || !message)
        return -1;
    unsigned char *payload = malloc(XPC_PAYLOAD_MAX);
    if (!payload)
        return -1;
    size_t plen = 0;
    if (xpc_encode_into(message, payload, XPC_PAYLOAD_MAX, &plen, 0) != 0 ||
        plen == 0)
    {
        free(payload);
        return -1;
    }
    size_t total = XPC_FRAME_HEADER + plen;
    xpc_frame *frame = calloc(1, total);
    if (!frame)
    {
        free(payload);
        return -1;
    }
    frame->magic = XPC_FRAME_MAGIC;
    frame->length = (uint32_t)plen;
    frame->sender = (int32_t)getpid();
    frame->kind = kind;
    frame->request_id = request_id;
    memcpy(frame->payload, payload, plen);
    ssize_t n = send(c->fd, frame, total, MSG_NOSIGNAL);
    free(frame);
    free(payload);
    return n == (ssize_t)total ? 0 : -1;
}

/* ------------------------------------------------------------ listener API */

/* Register the listener by name and mark its receive port so that accepted
 * client sockets become peer connections rather than Mach message sources. */
static int xpc_register_listener(struct xpc_connection *c)
{
    uint32_t port = port_new(-1);
    int launched = launchd_register_service(c->name);
    if (launched == 1103)
        return 1103;
    if (launched == 0)
    {
        struct mach_port_s *p = port_get(port);
        if (p)
            p->xpc_listener = 1;
        if (port_listen(port, c->name) != 0)
            return -1;
    }
    c->port = port;
    c->listener_port = port;
    return 0;
}

/* Called from the service accept loop for every incoming XPC client. */
void xpc_accept_fd(uint32_t listener_port, int fd)
{
    struct xpc_connection *listener = NULL;
    for (int i = 0; i < connection_count; i++)
    {
        struct xpc_connection *c = connections[i];
        if (c && c->listener && c->started && c->listener_port == listener_port)
        {
            listener = c;
            break;
        }
    }
    if (!listener || !listener->handler)
    {
        close(fd);
        return;
    }
    struct xpc_connection *peer = calloc(1, sizeof(*peer));
    if (!peer)
    {
        close(fd);
        return;
    }
    peer->name = strdup(listener->name);
    peer->fd = fd;
    peer->peer = 1;
    register_connection(peer);
    call_block_arg(listener->handler, xpc_connection_object(peer));
}

void xpc_connection_resume(void *conn)
{
    struct xpc_connection *c = connection_from_object(conn);
    if (!c || c->started)
        return;
    c->started = 1;
    if (c->listener)
    {
        xpc_register_listener(c);
        return;
    }
    if (c->peer)
        xpc_start_reader(c);
    /* Clients connect lazily on their first send. */
}
void xpc_connection_suspend(void *conn) { (void)conn; }
void xpc_connection_cancel(void *conn) { (void)conn; }

/* -------------------------------------------------------------- send side */

void xpc_connection_send_message(void *conn, void *message)
{
    struct xpc_connection *c = connection_from_object(conn);
    if (!c || !message)
        return;
    if (c->convenience)
    {
        /* In-process convenience connections deliver to a same-named local
         * connection's handler, which is their only transport. */
        for (int i = 0; i < connection_count; i++)
        {
            struct xpc_connection *peer = connections[i];
            if (peer && peer != c && peer->handler &&
                strcmp(peer->name, c->name) == 0)
            {
                call_block_arg(peer->handler, message);
                return;
            }
        }
    }
    if (xpc_ensure_fd(c) != 0)
        return;
    if (c->current_request)
    {
        uint64_t request = c->current_request;
        c->current_request = 0;
        xpc_write_frame(c, XPC_KIND_REPLY, request, message);
    }
    else
        xpc_write_frame(c, XPC_KIND_MESSAGE, 0, message);
}

void xpc_connection_send_message_with_reply(void *conn, void *message,
                                            void *queue, void *handler)
{
    (void)queue;
    struct xpc_connection *c = connection_from_object(conn);
    if (!c)
        return;
    if (c->convenience || xpc_ensure_fd(c) != 0 || !message)
    {
        if (handler)
            call_block_arg(handler, xpc_new(XPC_ERROR));
        return;
    }
    uint64_t id = xpc_next_request();
    if (!xpc_register_slot(id, handler, 0))
    {
        if (handler)
            call_block_arg(handler, xpc_new(XPC_ERROR));
        return;
    }
    if (xpc_write_frame(c, XPC_KIND_REQUEST, id, message) != 0 && handler)
        call_block_arg(handler, xpc_new(XPC_ERROR));
}

void *xpc_connection_send_message_with_reply_sync(void *conn, void *message)
{
    struct xpc_connection *c = connection_from_object(conn);
    if (!c || c->convenience || xpc_ensure_fd(c) != 0 || !message)
        return xpc_new(XPC_ERROR);
    uint64_t id = xpc_next_request();
    struct xpc_reply_slot *slot = xpc_register_slot(id, NULL, 1);
    if (!slot)
        return xpc_new(XPC_ERROR);
    void *reply = NULL;
    if (xpc_write_frame(c, XPC_KIND_REQUEST, id, message) == 0)
    {
        pthread_mutex_lock(&slot->lock);
        while (!slot->done)
            pthread_cond_wait(&slot->cond, &slot->lock);
        reply = slot->reply;
        pthread_mutex_unlock(&slot->lock);
    }
    else
        xpc_unlink_slot(slot);
    xpc_free_slot(slot);
    return reply ? reply : xpc_new(XPC_ERROR);
}

void xpc_connection_send_barrier(void *conn, void *block)
{
    (void)conn;
    call_block(block);
}
int xpc_connection_get_pid(void *conn)
{
    struct xpc_connection *c = connection_from_object(conn);
    if (c && c->peer_pid > 0)
        return c->peer_pid;
    return getpid();
}
void xpc_main(void (*handler)(void *)) { (void)handler; }

/* liblaunch's socket activation entry point. launchd_sim keeps the listening
 * sockets and passes their descriptors to the started job through
 * IOSIM_ACTIVATED_SOCKET_FDS ("name=fd[,name=fd]"), the same handoff contract
 * the real launchd expresses with its check-in protocol. */
int launch_activate_socket(const char *name, int **fds, size_t *count)
{
    if (!name || !fds || !count)
        return EINVAL;
    *fds = NULL;
    *count = 0;
    const char *env = getenv("IOSIM_ACTIVATED_SOCKET_FDS");
    if (!env || !*env)
        return ENOENT;
    size_t nlen = strlen(name);
    int found = 0;
    const char *p = env;
    while (*p)
    {
        const char *eq = strchr(p, '=');
        if (!eq)
            break;
        const char *end = strchr(p, ',');
        if (!end)
            end = p + strlen(p);
        if ((size_t)(eq - p) == nlen && strncmp(p, name, nlen) == 0)
            found++;
        p = *end ? end + 1 : end;
    }
    if (!found)
        return ENOENT;
    int *arr = malloc((size_t)found * sizeof(int));
    if (!arr)
        return ENOMEM;
    int k = 0;
    p = env;
    while (*p && k < found)
    {
        const char *eq = strchr(p, '=');
        if (!eq)
            break;
        const char *end = strchr(p, ',');
        if (!end)
            end = p + strlen(p);
        if ((size_t)(eq - p) == nlen && strncmp(p, name, nlen) == 0)
            arr[k++] = atoi(eq + 1);
        p = *end ? end + 1 : end;
    }
    *fds = arr;
    *count = (size_t)k;
    return 0;
}
int launch_msg(void *msg) { (void)msg; return 0; }


/* ------------------------------------------------------- symbol lookup */

struct xpc_type_storage { int type; long refs; };
struct xpc_type_storage xpc_type_dictionary_obj = { XPC_DICT, 1 };
struct xpc_type_storage xpc_type_string_obj = { XPC_STRING, 1 };
struct xpc_type_storage xpc_type_int64_obj = { XPC_INT, 1 };
struct xpc_type_storage xpc_type_bool_obj = { XPC_BOOL, 1 };
struct xpc_type_storage xpc_type_data_obj = { XPC_DATA, 1 };
struct xpc_type_storage xpc_type_array_obj = { XPC_ARRAY, 1 };
struct xpc_type_storage xpc_type_error_obj = { XPC_ERROR, 1 };
struct xpc_type_storage xpc_type_connection_obj = { XPC_CONNECTION, 1 };
char xpc_type_dictionary_storage[64];
char xpc_type_string_storage[64];
char xpc_type_int64_storage[64];
char xpc_type_bool_storage[64];
char xpc_type_data_storage[64];
char xpc_type_array_storage[64];
char xpc_type_error_storage[64];
char xpc_type_connection_storage[64];

/* xpc_get_type returns the address of the exported type symbol, so an app's
 * `xpc_get_type(event) == XPC_TYPE_CONNECTION` comparison works. */
struct xpc_object *xpc_get_type(void *obj)
{
    struct xpc_object *o = obj;
    if (!o) return (struct xpc_object *)xpc_type_error_storage;
    switch (o->type)
    {
    case XPC_DICT: return (struct xpc_object *)xpc_type_dictionary_storage;
    case XPC_STRING: return (struct xpc_object *)xpc_type_string_storage;
    case XPC_INT: return (struct xpc_object *)xpc_type_int64_storage;
    case XPC_BOOL: return (struct xpc_object *)xpc_type_bool_storage;
    case XPC_DATA: return (struct xpc_object *)xpc_type_data_storage;
    case XPC_ARRAY: return (struct xpc_object *)xpc_type_array_storage;
    case XPC_CONNECTION:
        return (struct xpc_object *)xpc_type_connection_storage;
    default: return (struct xpc_object *)xpc_type_error_storage;
    }
}

static int shim_pthread_mutex_init(void *m, const void *attr)
{
    int type = 0;
    if (attr && *(const int *)attr >= 0 && *(const int *)attr <= 3)
        type = *(const int *)attr;
    pthread_mutexattr_t a;
    pthread_mutexattr_init(&a);
    if (type)
        pthread_mutexattr_settype(&a, type);
    pthread_mutex_init((pthread_mutex_t *)m, &a);
    pthread_mutexattr_destroy(&a);
    return 0;
}

/* Darwin static mutex initializers embed a signature; translate one on first
 * use for objects that were not in a load-time data section. */
static int darwin_mutex_type(unsigned long sig)
{
    switch (sig)
    {
    case 0x32AAABA7UL: return 0;
    case 0x32AAABA1UL: return PTHREAD_MUTEX_ERRORCHECK;
    case 0x32AAABA2UL: return PTHREAD_MUTEX_RECURSIVE;
    case 0x32AAABA3UL: return 0;
    default: return -1;
    }
}

static void shim_pthread_mutex_ensure(void *m)
{
    unsigned long sig = *(volatile unsigned long *)m;
    int type = darwin_mutex_type(sig);
    if (type >= 0)
        shim_pthread_mutex_init(m, &type);
}

static int shim_pthread_mutex_lock(void *m)
{
    shim_pthread_mutex_ensure(m);
    return pthread_mutex_lock((pthread_mutex_t *)m);
}
static int shim_pthread_mutex_unlock(void *m)
{
    return pthread_mutex_unlock((pthread_mutex_t *)m);
}
static int shim_pthread_mutex_destroy(void *m)
{
    return pthread_mutex_destroy((pthread_mutex_t *)m);
}
static void shim_os_unfair_lock_lock(void *l) { (void)l; }
static void shim_os_unfair_lock_unlock(void *l) { (void)l; }

static int shim_pthread_mutexattr_init(void *attr)
{
    *(int *)attr = 0;
    return 0;
}
static int shim_pthread_mutexattr_destroy(void *attr) { (void)attr; return 0; }
static int shim_pthread_mutexattr_settype(void *attr, int type)
{
    int host = PTHREAD_MUTEX_NORMAL;
    switch (type)
    {
    case 0: host = PTHREAD_MUTEX_NORMAL; break;
    case 1: host = PTHREAD_MUTEX_ERRORCHECK; break;
    case 2: host = PTHREAD_MUTEX_RECURSIVE; break;
    case 3: host = PTHREAD_MUTEX_DEFAULT; break;
    }
    *(int *)attr = host;
    return 0;
}
static int shim_pthread_mutexattr_gettype(const void *attr, int *type)
{
    int host = *(const int *)attr;
    if (type)
    {
        if (host == PTHREAD_MUTEX_ERRORCHECK)
            *type = 1;
        else if (host == PTHREAD_MUTEX_RECURSIVE)
            *type = 2;
        else
            *type = 0;
    }
    return 0;
}


/* ------------------------------------------------------- dispatch sources */

enum {
    DS_TIMER = 1,
    DS_DATA_ADD,
    DS_DATA_OR,
    DS_DATA_REPLACE,
    DS_READ,
    DS_WRITE
};

/* Apple's headers declare these as structs and take their address:
 * DISPATCH_SOURCE_TYPE_TIMER expands to (&_dispatch_source_type_timer).
 * The loader's symbol resolver strips one Mach-O underscore, so the C names
 * below appear as _dispatch_source_type_timer in the service table. The
 * unadorned pointer aliases keep the fixture header convenient. */
struct dispatch_source_type_s { int kind; };
const struct dispatch_source_type_s _dispatch_source_type_timer = { DS_TIMER };
const struct dispatch_source_type_s _dispatch_source_type_data_add = { DS_DATA_ADD };
const struct dispatch_source_type_s _dispatch_source_type_data_or = { DS_DATA_OR };
const struct dispatch_source_type_s _dispatch_source_type_data_replace = { DS_DATA_REPLACE };
const struct dispatch_source_type_s _dispatch_source_type_read = { DS_READ };
const struct dispatch_source_type_s _dispatch_source_type_write = { DS_WRITE };

static char ds_type_timer_storage;
static char ds_type_data_add_storage;
static char ds_type_data_or_storage;
static char ds_type_data_replace_storage;
static char ds_type_read_storage;
static char ds_type_write_storage;
void *dispatch_source_type_timer = &ds_type_timer_storage;
void *dispatch_source_type_data_add = &ds_type_data_add_storage;
void *dispatch_source_type_data_or = &ds_type_data_or_storage;
void *dispatch_source_type_data_replace = &ds_type_data_replace_storage;
void *dispatch_source_type_read = &ds_type_read_storage;
void *dispatch_source_type_write = &ds_type_write_storage;

struct dispatch_source_s {
    struct dispatch_object_header hdr;
    int type;
    uintptr_t handle;
    unsigned long mask;
    void *queue;
    void *event_block;
    void (*event_fn)(void *);
    void *event_ctx;
    void *cancel_block;
    void (*cancel_fn)(void *);
    void *cancel_ctx;
    void *registration_block;
    void (*registration_fn)(void *);
    void *registration_ctx;
    void *context;
    int canceled;
    int suspend_count;
    int pending;
    int scheduled;
    int registered;
    int poll_started;
    double next_fire;
    uint64_t timer_start_ns;
    uint64_t timer_interval_ns;
    uint64_t timer_leeway_ns;
    unsigned long data;
    struct dispatch_source_s *next;
};

static pthread_mutex_t ds_lock = PTHREAD_MUTEX_INITIALIZER;
static pthread_cond_t ds_cond;
static pthread_once_t ds_once = PTHREAD_ONCE_INIT;
static struct dispatch_source_s *ds_list;

static void ds_wake(void)
{
    pthread_cond_broadcast(&ds_cond);
}

static void ds_deliver(void *ctx)
{
    struct dispatch_source_s *s = ctx;
    void *block;
    void (*fn)(void *);
    void *fn_ctx;
    pthread_mutex_lock(&ds_lock);
    s->pending = 0;
    if (s->canceled)
    {
        pthread_mutex_unlock(&ds_lock);
        return;
    }
    block = s->event_block;
    fn = s->event_fn;
    fn_ctx = s->event_ctx;
    pthread_mutex_unlock(&ds_lock);
    if (block)
        call_block(block);
    else if (fn)
        fn(fn_ctx);
}

static void ds_cancel_deliver(void *ctx)
{
    struct dispatch_source_s *s = ctx;
    void *block;
    void (*fn)(void *);
    void *fn_ctx;
    pthread_mutex_lock(&ds_lock);
    block = s->cancel_block;
    fn = s->cancel_fn;
    fn_ctx = s->cancel_ctx;
    pthread_mutex_unlock(&ds_lock);
    if (block)
        call_block(block);
    else if (fn)
        fn(fn_ctx);
}

static void ds_trigger(struct dispatch_source_s *s)
{
    int fire = 0;
    pthread_mutex_lock(&ds_lock);
    if (!s->canceled && s->suspend_count == 0 && !s->pending)
    {
        s->pending = 1;
        fire = 1;
    }
    pthread_mutex_unlock(&ds_lock);
    if (fire)
        dispatch_async_f(s->queue, s, ds_deliver);
}

static void *ds_poll_thread(void *arg)
{
    struct dispatch_source_s *s = arg;
    short events = s->type == DS_READ ? POLLIN : POLLOUT;
    for (;;)
    {
        struct pollfd pfd;
        pfd.fd = (int)s->handle;
        pfd.events = events;
        pfd.revents = 0;
        int ready = poll(&pfd, 1, 50);
        pthread_mutex_lock(&ds_lock);
        int stop = s->canceled;
        int suspended = s->suspend_count > 0;
        pthread_mutex_unlock(&ds_lock);
        if (stop)
            break;
        if (ready > 0 && !suspended)
            ds_trigger(s);
    }
    return NULL;
}

static void ds_scheduler(void)
{
    for (;;)
    {
        struct dispatch_source_s *due[64];
        int ndue = 0;
        int have_next = 0;
        double next = 0;
        double now = now_seconds();

        pthread_mutex_lock(&ds_lock);
        for (struct dispatch_source_s *s = ds_list; s; s = s->next)
        {
            if (s->type != DS_TIMER || s->canceled ||
                s->suspend_count > 0 || !s->scheduled)
                continue;
            if (s->next_fire <= now)
            {
                if (s->pending)
                {
                    if (s->timer_interval_ns)
                        s->next_fire = now +
                            (double)s->timer_interval_ns / 1e9;
                    else
                        s->scheduled = 0;
                    continue;
                }
                s->pending = 1;
                if (s->timer_interval_ns)
                {
                    double interval = (double)s->timer_interval_ns / 1e9;
                    s->next_fire += interval;
                    if (s->next_fire < now)
                        s->next_fire = now + interval;
                }
                else
                    s->scheduled = 0;
                if (ndue < (int)(sizeof(due) / sizeof(due[0])))
                    due[ndue++] = s;
            }
            else if (!have_next || s->next_fire < next)
            {
                next = s->next_fire;
                have_next = 1;
            }
        }
        if (ndue == 0)
        {
            if (have_next)
            {
                struct timespec ts;
                double wait = next - now;
                if (wait < 0)
                    wait = 0;
                (void)wait;
                /* ds_cond uses CLOCK_MONOTONIC, so the deadline is the
                 * absolute monotonic second count of the next fire. */
                ts.tv_sec = (time_t)next;
                ts.tv_nsec = (long)((next - (double)ts.tv_sec) * 1e9);
                pthread_cond_timedwait(&ds_cond, &ds_lock, &ts);
            }
            else
                pthread_cond_wait(&ds_cond, &ds_lock);
        }
        pthread_mutex_unlock(&ds_lock);
        for (int i = 0; i < ndue; i++)
            dispatch_async_f(due[i]->queue, due[i], ds_deliver);
    }
}

static void ds_initialize(void)
{
    pthread_condattr_t attr;
    pthread_condattr_init(&attr);
    pthread_condattr_setclock(&attr, CLOCK_MONOTONIC);
    pthread_cond_init(&ds_cond, &attr);
    pthread_condattr_destroy(&attr);
    pthread_t thread;
    if (pthread_create(&thread, NULL, (void *(*)(void *))ds_scheduler, NULL) == 0)
        pthread_detach(thread);
}

static int ds_type_from_pointer(void *type)
{
    if (type == &_dispatch_source_type_timer ||
        type == &ds_type_timer_storage) return DS_TIMER;
    if (type == &_dispatch_source_type_data_add ||
        type == &ds_type_data_add_storage) return DS_DATA_ADD;
    if (type == &_dispatch_source_type_data_or ||
        type == &ds_type_data_or_storage) return DS_DATA_OR;
    if (type == &_dispatch_source_type_data_replace ||
        type == &ds_type_data_replace_storage) return DS_DATA_REPLACE;
    if (type == &_dispatch_source_type_read ||
        type == &ds_type_read_storage) return DS_READ;
    if (type == &_dispatch_source_type_write ||
        type == &ds_type_write_storage) return DS_WRITE;
    return 0;
}

void *dispatch_source_create(void *type, uintptr_t handle,
                             unsigned long mask, void *queue)
{
    int kind = ds_type_from_pointer(type);
    if (!kind)
        return NULL;
    struct dispatch_source_s *s = calloc(1, sizeof(*s));
    if (!s)
        return NULL;
    s->hdr.magic = DISPATCH_OBJECT_MAGIC;
    s->hdr.kind = DISPATCH_KIND_SOURCE;
    s->type = kind;
    s->handle = handle;
    s->mask = mask;
    s->queue = queue ? queue : &main_queue;
    s->suspend_count = 1; /* libdispatch sources start suspended */
    pthread_once(&ds_once, ds_initialize);
    pthread_mutex_lock(&ds_lock);
    s->next = ds_list;
    ds_list = s;
    pthread_mutex_unlock(&ds_lock);
    return s;
}

void dispatch_source_set_event_handler(void *source, void *block)
{
    struct dispatch_source_s *s = source;
    if (!s)
        return;
    void *copy = block ? _Block_copy(block) : NULL;
    pthread_mutex_lock(&ds_lock);
    void *old = s->event_block;
    s->event_block = copy;
    s->event_fn = NULL;
    s->event_ctx = NULL;
    pthread_mutex_unlock(&ds_lock);
    if (old)
        _Block_release(old);
}

void dispatch_source_set_event_handler_f(void *source,
                                         void (*function)(void *))
{
    struct dispatch_source_s *s = source;
    if (!s)
        return;
    pthread_mutex_lock(&ds_lock);
    s->event_block = NULL;
    s->event_fn = function;
    s->event_ctx = s->hdr.context;
    pthread_mutex_unlock(&ds_lock);
}

void dispatch_source_set_cancel_handler(void *source, void *block)
{
    struct dispatch_source_s *s = source;
    if (!s)
        return;
    void *copy = block ? _Block_copy(block) : NULL;
    pthread_mutex_lock(&ds_lock);
    void *old = s->cancel_block;
    s->cancel_block = copy;
    s->cancel_fn = NULL;
    s->cancel_ctx = NULL;
    pthread_mutex_unlock(&ds_lock);
    if (old)
        _Block_release(old);
}

void dispatch_source_set_cancel_handler_f(void *source,
                                          void (*function)(void *))
{
    struct dispatch_source_s *s = source;
    if (!s)
        return;
    pthread_mutex_lock(&ds_lock);
    s->cancel_block = NULL;
    s->cancel_fn = function;
    s->cancel_ctx = s->hdr.context;
    pthread_mutex_unlock(&ds_lock);
}

void dispatch_source_set_registration_handler(void *source, void *block)
{
    struct dispatch_source_s *s = source;
    if (!s)
        return;
    s->registration_block = block ? _Block_copy(block) : NULL;
    s->registration_fn = NULL;
    s->registration_ctx = NULL;
}

void dispatch_source_set_registration_handler_f(void *source,
                                                void (*function)(void *))
{
    struct dispatch_source_s *s = source;
    if (!s)
        return;
    s->registration_block = NULL;
    s->registration_fn = function;
    s->registration_ctx = s->hdr.context;
}

void dispatch_set_context(void *object, void *context)
{
    struct dispatch_object_header *hdr = object;
    if (hdr && hdr->magic == DISPATCH_OBJECT_MAGIC)
        hdr->context = context;
}

void *dispatch_get_context(void *object)
{
    struct dispatch_object_header *hdr = object;
    return hdr && hdr->magic == DISPATCH_OBJECT_MAGIC ? hdr->context : NULL;
}

void dispatch_source_set_timer(void *source, uint64_t start,
                               uint64_t interval, uint64_t leeway)
{
    struct dispatch_source_s *s = source;
    if (!s || s->type != DS_TIMER)
        return;
    pthread_mutex_lock(&ds_lock);
    s->timer_start_ns = start;
    s->timer_interval_ns = interval;
    s->timer_leeway_ns = leeway;
    if (!s->canceled && s->suspend_count == 0)
    {
        double fire = start ? (double)start / 1e9 : now_seconds();
        if (fire < now_seconds() && interval)
            fire = now_seconds();
        s->next_fire = fire;
        s->scheduled = 1;
    }
    ds_wake();
    pthread_mutex_unlock(&ds_lock);
}

void dispatch_source_set_target_queue(void *source, void *queue)
{
    struct dispatch_source_s *s = source;
    if (!s || !queue)
        return;
    pthread_mutex_lock(&ds_lock);
    if (!s->scheduled && !s->pending)
        s->queue = queue;
    pthread_mutex_unlock(&ds_lock);
}

void dispatch_resume(void *object)
{
    struct dispatch_source_s *s = object;
    if (!s || s->hdr.magic != DISPATCH_OBJECT_MAGIC ||
        s->hdr.kind != DISPATCH_KIND_SOURCE)
        return;
    int start_poll = 0;
    int trigger = 0;
    void *registration_block = NULL;
    void (*registration_fn)(void *) = NULL;
    void *registration_ctx = NULL;
    pthread_mutex_lock(&ds_lock);
    if (s->suspend_count > 0)
        s->suspend_count--;
    if (s->suspend_count == 0 && !s->canceled)
    {
        if (s->type == DS_TIMER)
        {
            double fire = s->timer_start_ns
                              ? (double)s->timer_start_ns / 1e9
                              : now_seconds();
            if (fire < now_seconds() && s->timer_interval_ns)
                fire = now_seconds();
            s->next_fire = fire;
            s->scheduled = 1;
        }
        else if (s->type == DS_DATA_ADD || s->type == DS_DATA_OR ||
                 s->type == DS_DATA_REPLACE)
        {
            trigger = s->data != 0;
        }
        else if ((s->type == DS_READ || s->type == DS_WRITE) &&
                 !s->poll_started)
        {
            s->poll_started = 1;
            start_poll = 1;
        }
        if (!s->registered)
        {
            s->registered = 1;
            registration_block = s->registration_block;
            registration_fn = s->registration_fn;
            registration_ctx = s->registration_ctx;
        }
    }
    ds_wake();
    pthread_mutex_unlock(&ds_lock);
    if (registration_block)
        call_block(registration_block);
    else if (registration_fn)
        registration_fn(registration_ctx);
    if (start_poll)
    {
        pthread_t thread;
        if (pthread_create(&thread, NULL, ds_poll_thread, s) == 0)
            pthread_detach(thread);
    }
    if (trigger)
        ds_trigger(s);
}

void dispatch_suspend(void *object)
{
    struct dispatch_source_s *s = object;
    if (!s || s->hdr.magic != DISPATCH_OBJECT_MAGIC ||
        s->hdr.kind != DISPATCH_KIND_SOURCE)
        return;
    pthread_mutex_lock(&ds_lock);
    s->suspend_count++;
    pthread_mutex_unlock(&ds_lock);
}

void dispatch_activate(void *object)
{
    dispatch_resume(object);
}

void dispatch_source_cancel(void *source)
{
    struct dispatch_source_s *s = source;
    if (!s)
        return;
    int notify = 0;
    pthread_mutex_lock(&ds_lock);
    if (!s->canceled)
    {
        s->canceled = 1;
        s->scheduled = 0;
        notify = s->cancel_block || s->cancel_fn;
    }
    ds_wake();
    pthread_mutex_unlock(&ds_lock);
    if (notify)
        dispatch_async_f(s->queue, s, ds_cancel_deliver);
}

int dispatch_source_testcancel(void *source)
{
    struct dispatch_source_s *s = source;
    if (!s)
        return 0;
    return s->canceled;
}

uintptr_t dispatch_source_get_handle(void *source)
{
    struct dispatch_source_s *s = source;
    return s ? s->handle : 0;
}

unsigned long dispatch_source_get_mask(void *source)
{
    struct dispatch_source_s *s = source;
    return s ? s->mask : 0;
}

unsigned long dispatch_source_get_data(void *source)
{
    struct dispatch_source_s *s = source;
    if (!s)
        return 0;
    pthread_mutex_lock(&ds_lock);
    unsigned long value = s->data;
    s->data = 0;
    pthread_mutex_unlock(&ds_lock);
    return value;
}

void dispatch_source_merge_data(void *source, unsigned long value)
{
    struct dispatch_source_s *s = source;
    if (!s)
        return;
    pthread_mutex_lock(&ds_lock);
    switch (s->type)
    {
    case DS_DATA_ADD:
        s->data += value;
        break;
    case DS_DATA_OR:
        s->data |= value;
        break;
    case DS_DATA_REPLACE:
    default:
        s->data = value;
        break;
    }
    pthread_mutex_unlock(&ds_lock);
    ds_trigger(s);
}

/* Minimal host HTTP client used by Foundation's NSURLSession.  The guest
 * passes a URL, method, extra headers and an optional body; the loader owns
 * the host socket, DNS lookup and response parsing. */

static void http_set_error(char **out_error, const char *message)
{
    if (out_error && !*out_error)
        *out_error = strdup(message);
}

static int http_split_url(const char *url, char *host, size_t host_cap,
                          char *port, size_t port_cap, char *path,
                          size_t path_cap, int *out_tls, char **out_error)
{
    int tls = 0;
    if (!url)
    {
        http_set_error(out_error, "unsupported URL scheme");
        return -1;
    }
    const char *authority = NULL;
    if (strncmp(url, "http://", 7) == 0)
        authority = url + 7;
    else if (strncmp(url, "https://", 8) == 0)
    {
        authority = url + 8;
        tls = 1;
    }
    if (!authority)
    {
        http_set_error(out_error, "unsupported URL scheme");
        return -1;
    }
    const char *slash = strchr(authority, '/');
    const char *authority_end = slash ? slash : authority + strlen(authority);
    size_t authority_len = (size_t)(authority_end - authority);
    if (authority_len == 0)
    {
        http_set_error(out_error, "URL has no host");
        return -1;
    }
    const char *colon = memchr(authority, ':', authority_len);
    size_t host_len = colon ? (size_t)(colon - authority) : authority_len;
    if (host_len == 0 || host_len >= host_cap)
    {
        http_set_error(out_error, "URL host is too long");
        return -1;
    }
    memcpy(host, authority, host_len);
    host[host_len] = 0;
    if (colon)
    {
        size_t port_len = authority_len - host_len - 1;
        if (port_len == 0 || port_len >= port_cap)
        {
            http_set_error(out_error, "URL port is invalid");
            return -1;
        }
        memcpy(port, colon + 1, port_len);
        port[port_len] = 0;
    }
    else
    {
        snprintf(port, port_cap, "%s", tls ? "443" : "80");
    }
    if (out_tls)
        *out_tls = tls;
    const char *path_start = slash ? slash : "/";
    size_t path_len = strlen(path_start);
    if (path_len == 0)
        path_start = "/", path_len = 1;
    if (path_len >= path_cap)
    {
        http_set_error(out_error, "URL path is too long");
        return -1;
    }
    memcpy(path, path_start, path_len);
    path[path_len] = 0;
    return 0;
}

static int http_send_all(int fd, void *tls, const char *data, size_t length)
{
    while (length)
    {
#ifdef IOSIM_HAVE_OPENSSL
        if (tls)
        {
            int n = SSL_write((SSL *)tls, data, (int)length);
            if (n <= 0)
            {
                int err = SSL_get_error((SSL *)tls, n);
                if (err == SSL_ERROR_WANT_READ || err == SSL_ERROR_WANT_WRITE)
                    continue;
                return -1;
            }
            data += n;
            length -= (size_t)n;
            continue;
        }
#endif
        ssize_t n = send(fd, data, length, 0);
        if (n < 0)
        {
            if (errno == EINTR)
                continue;
            return -1;
        }
        data += n;
        length -= (size_t)n;
    }
    return 0;
}

int iosim_http_request(const char *url, const char *method,
                       const char *extra_headers, const void *body,
                       size_t body_len, unsigned char **out_data,
                       size_t *out_len, int *out_status,
                       char **out_headers, char **out_error)
{
    char host[256], port[16], path[2048];
    int fd = -1, status = 0, rc = -1;
    int tls = 0;
#ifdef IOSIM_HAVE_OPENSSL
    SSL_CTX *ssl_ctx = NULL;
    SSL *ssl = NULL;
#endif
    unsigned char *reply = NULL;
    char *headers = NULL, *error = NULL;
    if (out_data)
        *out_data = NULL;
    if (out_len)
        *out_len = 0;
    if (out_status)
        *out_status = 0;
    if (out_headers)
        *out_headers = NULL;
    if (out_error)
        *out_error = NULL;
    if (http_split_url(url, host, sizeof(host), port, sizeof(port), path,
                       sizeof(path), &tls, &error) != 0)
        goto done;

    struct addrinfo hints, *addresses = NULL;
    memset(&hints, 0, sizeof(hints));
    hints.ai_family = AF_UNSPEC;
    hints.ai_socktype = SOCK_STREAM;
    if (getaddrinfo(host, port, &hints, &addresses) != 0)
    {
        http_set_error(&error, "could not resolve host");
        goto done;
    }
    for (struct addrinfo *a = addresses; a; a = a->ai_next)
    {
        fd = socket(a->ai_family, a->ai_socktype, a->ai_protocol);
        if (fd < 0)
            continue;
        if (connect(fd, a->ai_addr, a->ai_addrlen) == 0)
            break;
        close(fd);
        fd = -1;
    }
    freeaddrinfo(addresses);
    if (fd < 0)
    {
        http_set_error(&error, "could not connect to host");
        goto done;
    }
    struct timeval timeout = { 15, 0 };
    setsockopt(fd, SOL_SOCKET, SO_RCVTIMEO, &timeout, sizeof(timeout));
    setsockopt(fd, SOL_SOCKET, SO_SNDTIMEO, &timeout, sizeof(timeout));

    if (tls)
    {
#ifdef IOSIM_HAVE_OPENSSL
        ssl_ctx = SSL_CTX_new(TLS_client_method());
        if (!ssl_ctx)
        {
            http_set_error(&error, "could not create TLS context");
            goto done;
        }
        const char *insecure = getenv("IOSIM_TLS_INSECURE");
        if (insecure && insecure[0] == '1')
        {
            SSL_CTX_set_verify(ssl_ctx, SSL_VERIFY_NONE, NULL);
        }
        else
        {
            SSL_CTX_set_default_verify_paths(ssl_ctx);
            SSL_CTX_set_verify(ssl_ctx, SSL_VERIFY_PEER, NULL);
        }
        SSL_CTX_set_options(ssl_ctx, SSL_OP_IGNORE_UNEXPECTED_EOF);
        ssl = SSL_new(ssl_ctx);
        if (!ssl)
        {
            http_set_error(&error, "could not create TLS session");
            goto done;
        }
        SSL_set_fd(ssl, fd);
        SSL_set_tlsext_host_name(ssl, host);
        if (!(insecure && insecure[0] == '1'))
            SSL_set1_host(ssl, host);
        if (SSL_connect(ssl) != 1)
        {
            http_set_error(&error, "TLS handshake failed");
            goto done;
        }
#else
        http_set_error(&error, "HTTPS support is not built in");
        goto done;
#endif
    }

    const char *verb = method && method[0] ? method : "GET";
    size_t extra_len = extra_headers ? strlen(extra_headers) : 0;
    size_t request_cap = strlen(verb) + strlen(path) + strlen(host) +
                         extra_len + body_len + 512;
    char *request = malloc(request_cap);
    if (!request)
    {
        http_set_error(&error, "out of memory");
        goto done;
    }
    int n = snprintf(request, request_cap,
                     "%s %s HTTP/1.0\r\nHost: %s\r\nConnection: close\r\n"
                     "User-Agent: iosim/1.0\r\n", verb, path, host);
    if (extra_len)
        n += snprintf(request + n, request_cap - (size_t)n, "%s", extra_headers);
    if (body_len)
        n += snprintf(request + n, request_cap - (size_t)n,
                      "Content-Length: %lu\r\n", (unsigned long)body_len);
    n += snprintf(request + n, request_cap - (size_t)n, "\r\n");
    if (body_len && (size_t)n + body_len < request_cap)
        memcpy(request + n, body, body_len), n += (int)body_len;
    int sent = http_send_all(fd,
#ifdef IOSIM_HAVE_OPENSSL
                             ssl,
#else
                             NULL,
#endif
                             request, (size_t)n);
    free(request);
    if (sent != 0)
    {
        http_set_error(&error, "could not send request");
        goto done;
    }

    size_t length = 0, capacity = 0;
    char chunk[8192];
    for (;;)
    {
        ssize_t got = 0;
#ifdef IOSIM_HAVE_OPENSSL
        if (ssl)
        {
            int n = SSL_read(ssl, chunk, (int)sizeof(chunk));
            if (n <= 0)
            {
                int err = SSL_get_error(ssl, n);
                if (err == SSL_ERROR_WANT_READ || err == SSL_ERROR_WANT_WRITE)
                    continue;
                if (err == SSL_ERROR_ZERO_RETURN)
                    break;
                http_set_error(&error, "could not read TLS response");
                goto done;
            }
            got = n;
        }
        else
#endif
        {
            got = recv(fd, chunk, sizeof(chunk), 0);
            if (got < 0)
            {
                if (errno == EINTR)
                    continue;
                http_set_error(&error, "could not read response");
                goto done;
            }
            if (got == 0)
                break;
        }
        if (length + (size_t)got + 1 > capacity)
        {
            size_t want = capacity ? capacity * 2 : 16384;
            while (want < length + (size_t)got + 1)
                want *= 2;
            unsigned char *grown = realloc(reply, want);
            if (!grown)
            {
                http_set_error(&error, "out of memory");
                goto done;
            }
            reply = grown;
            capacity = want;
        }
        memcpy(reply + length, chunk, (size_t)got);
        length += (size_t)got;
    }
    if (reply)
        reply[length] = 0;
    if (!reply || length < 12)
    {
        http_set_error(&error, "empty response");
        goto done;
    }

    char *header_end = strstr((char *)reply, "\r\n\r\n");
    if (!header_end)
    {
        http_set_error(&error, "malformed response headers");
        goto done;
    }
    char *status_space = strchr((char *)reply, ' ');
    if (!status_space || status_space > header_end)
    {
        http_set_error(&error, "malformed status line");
        goto done;
    }
    status = atoi(status_space + 1);
    char *header_start = strchr((char *)reply, '\n');
    size_t header_len = 0;
    if (header_start && header_start + 1 <= header_end)
        header_len = (size_t)(header_end - (header_start + 1));
    headers = malloc(header_len + 1);
    if (headers)
    {
        if (header_len)
            memcpy(headers, header_start + 1, header_len);
        headers[header_len] = 0;
    }
    size_t body_start = (size_t)(header_end - (char *)reply) + 4;
    size_t body_size = length - body_start;
    unsigned char *body_copy = NULL;
    if (body_size)
    {
        body_copy = malloc(body_size + 1);
        if (!body_copy)
        {
            http_set_error(&error, "out of memory");
            goto done;
        }
        memcpy(body_copy, reply + body_start, body_size);
        body_copy[body_size] = 0;
    }
    if (out_data)
        *out_data = body_copy;
    else
        free(body_copy);
    if (out_len)
        *out_len = body_size;
    if (out_status)
        *out_status = status;
    if (out_headers)
    {
        *out_headers = headers;
        headers = NULL;
    }
    rc = 0;

done:
#ifdef IOSIM_HAVE_OPENSSL
    if (ssl)
        SSL_free(ssl);
    if (ssl_ctx)
        SSL_CTX_free(ssl_ctx);
#endif
    if (fd >= 0)
        close(fd);
    free(reply);
    free(headers);
    if (error)
    {
        if (out_error)
            *out_error = error;
        else
            free(error);
    }
    return rc;
}

void iosim_http_free(void *pointer)
{
    free(pointer);
}

/* Host POSIX regex used by Foundation's NSRegularExpression.  Patterns are
 * translated from the common ICU spelling (\d, \w, \s, non-capturing groups
 * and lazy quantifiers) to POSIX ERE before compilation. */

static char *regex_translate_pattern(const char *pattern)
{
    size_t capacity = strlen(pattern) * 6 + 16;
    char *out = malloc(capacity);
    size_t length = 0;
    if (!out)
        return NULL;
    for (const char *p = pattern; *p; )
    {
        const char *insert = NULL;
        size_t skip = 0;
        if (p[0] == '\\' && p[1])
        {
            if (p[1] == 'd')
                insert = "[0-9]";
            else if (p[1] == 'w')
                insert = "[A-Za-z0-9_]";
            else if (p[1] == 's')
                insert = "[ \t\r\n]";
            else if (p[1] == 'D')
                insert = "[^0-9]";
            else if (p[1] == 'W')
                insert = "[^A-Za-z0-9_]";
            else if (p[1] == 'S')
                insert = "[^ \t\r\n]";
            if (insert)
                skip = 2;
        }
        else if (p[0] == '(' && p[1] == '?' && p[2] == ':')
        {
            insert = "(";
            skip = 3;
        }
        else if ((p[0] == '*' || p[0] == '+' || p[0] == '?') &&
                 p[1] == '?')
        {
            insert = NULL;
            skip = 2;
        }
        if (insert || skip)
        {
            const char *text = insert ? insert : p;
            size_t n = insert ? strlen(insert) : 1;
            if (length + n + 1 >= capacity)
            {
                capacity = (length + n + 1) * 2;
                char *grown = realloc(out, capacity);
                if (!grown)
                {
                    free(out);
                    return NULL;
                }
                out = grown;
            }
            memcpy(out + length, text, n);
            length += n;
            p += skip;
            continue;
        }
        if (length + 2 >= capacity)
        {
            capacity *= 2;
            char *grown = realloc(out, capacity);
            if (!grown)
            {
                free(out);
                return NULL;
            }
            out = grown;
        }
        out[length++] = *p++;
    }
    out[length] = 0;
    return out;
}

int iosim_regex_search(const char *pattern, const char *text, int options,
                       unsigned long **out_ranges,
                       unsigned long *out_matches,
                       unsigned long *out_groups, char **out_error)
{
    if (out_ranges)
        *out_ranges = NULL;
    if (out_matches)
        *out_matches = 0;
    if (out_groups)
        *out_groups = 0;
    if (out_error)
        *out_error = NULL;
    if (!pattern || !text)
        return -1;
    char *translated = regex_translate_pattern(pattern);
    if (!translated)
    {
        if (out_error)
            *out_error = strdup("out of memory");
        return -1;
    }
    regex_t regex;
    int flags = REG_EXTENDED;
    if (options & 1)
        flags |= REG_ICASE;
    int compiled = regcomp(&regex, translated, flags);
    free(translated);
    if (compiled != 0)
    {
        char message[256];
        regerror(compiled, &regex, message, sizeof(message));
        if (out_error)
            *out_error = strdup(message);
        return -1;
    }
    size_t groups = regex.re_nsub + 1;
    if (groups > 16)
        groups = 16;
    regmatch_t matches[16];
    unsigned long *ranges = NULL;
    size_t range_count = 0, range_capacity = 0;
    unsigned long match_count = 0;
    size_t offset = 0;
    size_t text_length = strlen(text);
    while (offset <= text_length)
    {
        int result = regexec(&regex, text + offset, groups, matches, 0);
        if (result != 0)
            break;
        if ((size_t)matches[0].rm_so == (size_t)-1)
            break;
        if (range_count + groups * 2 > range_capacity)
        {
            size_t want = range_capacity ? range_capacity * 2 : 64;
            while (want < range_count + groups * 2)
                want *= 2;
            unsigned long *grown = realloc(ranges, want * sizeof(unsigned long));
            if (!grown)
            {
                free(ranges);
                regfree(&regex);
                if (out_error)
                    *out_error = strdup("out of memory");
                return -1;
            }
            ranges = grown;
            range_capacity = want;
        }
        for (size_t g = 0; g < groups; g++)
        {
            if (matches[g].rm_so < 0)
            {
                ranges[range_count++] = (unsigned long)-1;
                ranges[range_count++] = 0;
            }
            else
            {
                ranges[range_count++] = offset + (size_t)matches[g].rm_so;
                ranges[range_count++] = (size_t)(matches[g].rm_eo -
                                                 matches[g].rm_so);
            }
        }
        match_count++;
        size_t advance = (size_t)matches[0].rm_eo;
        if (advance == 0)
            advance = 1;
        offset += advance;
    }
    regfree(&regex);
    if (out_ranges)
        *out_ranges = ranges;
    else
        free(ranges);
    if (out_matches)
        *out_matches = match_count;
    if (out_groups)
        *out_groups = groups;
    return 0;
}

void iosim_regex_free(void *pointer)
{
    free(pointer);
}

struct service_symbol { const char *name; void *addr; };

#define SVC(fn) { #fn, (void *)(uintptr_t)&fn }
#define SVCD(nm, obj) { nm, (void *)(uintptr_t)&obj }

static const struct service_symbol service_symbols[] = {
    SVC(dispatch_get_main_queue), SVC(dispatch_get_global_queue),
    SVC(iosim_http_request), SVC(iosim_http_free),
    SVC(iosim_regex_search), SVC(iosim_regex_free),
    SVC(dispatch_queue_create), SVC(dispatch_release), SVC(dispatch_retain),
    SVC(dispatch_async), SVC(dispatch_async_f), SVC(dispatch_sync), SVC(dispatch_sync_f),
    SVC(dispatch_after), SVC(dispatch_after_f), SVC(dispatch_after_f_np),
    SVC(dispatch_time), SVC(dispatch_once), SVC(dispatch_main),
    SVC(dispatch_get_current_queue), SVC(dispatch_queue_get_label),
    SVC(dispatch_queue_set_specific), SVC(dispatch_get_specific),
    SVC(dispatch_barrier_async), SVC(dispatch_barrier_sync), SVC(dispatch_apply),
    SVC(dispatch_group_create), SVC(dispatch_group_enter), SVC(dispatch_group_leave),
    SVC(dispatch_group_wait), SVC(dispatch_group_notify), SVC(dispatch_group_async),
    SVC(dispatch_semaphore_create), SVC(dispatch_semaphore_wait), SVC(dispatch_semaphore_signal),
    SVC(dispatch_data_create), SVC(dispatch_data_get_size),
    SVC(dispatch_data_apply), SVC(dispatch_data_create_concat),
    SVC(dispatch_data_create_subrange), SVC(dispatch_data_create_map),
    SVC(dispatch_source_create), SVC(dispatch_source_set_event_handler),
    SVC(dispatch_source_set_event_handler_f),
    SVC(dispatch_source_set_cancel_handler),
    SVC(dispatch_source_set_cancel_handler_f),
    SVC(dispatch_source_set_registration_handler),
    SVC(dispatch_source_set_registration_handler_f),
    SVC(dispatch_source_set_timer), SVC(dispatch_source_set_target_queue),
    SVC(dispatch_source_cancel), SVC(dispatch_source_testcancel),
    SVC(dispatch_source_get_handle), SVC(dispatch_source_get_mask),
    SVC(dispatch_source_get_data), SVC(dispatch_source_merge_data),
    SVC(dispatch_set_context), SVC(dispatch_get_context),
    SVC(dispatch_resume), SVC(dispatch_suspend), SVC(dispatch_activate),
    SVC(mach_port_allocate), SVC(mach_port_deallocate), SVC(mach_port_mod_refs),
    SVC(mach_port_insert_right), SVC(mach_port_destroy), SVC(mach_task_self),
    SVC(mach_host_self), SVC(mach_msg), SVC(mach_msg_send), SVC(mach_msg_receive),
    SVC(bootstrap_register), SVC(bootstrap_look_up),
    SVC(xpc_connection_create_mach_service), SVC(xpc_connection_create),
    SVC(xpc_connection_set_event_handler), SVC(xpc_connection_set_target_queue),
    SVC(xpc_connection_resume), SVC(xpc_connection_suspend), SVC(xpc_connection_cancel),
    SVC(xpc_connection_send_message), SVC(xpc_connection_send_message_with_reply),
    SVC(xpc_connection_send_message_with_reply_sync),
    SVC(xpc_connection_send_barrier), SVC(xpc_connection_get_pid), SVC(xpc_main),
    SVC(xpc_dictionary_create), SVC(xpc_dictionary_create_empty),
    SVC(xpc_dictionary_set_value), SVC(xpc_dictionary_get_value),
    SVC(xpc_dictionary_set_string), SVC(xpc_dictionary_get_string),
    SVC(xpc_dictionary_set_int64), SVC(xpc_dictionary_get_int64),
    SVC(xpc_dictionary_set_bool), SVC(xpc_dictionary_set_data),
    SVC(xpc_string_create), SVC(xpc_string_get_string_ptr), SVC(xpc_int64_create),
    SVC(xpc_bool_create), SVC(xpc_bool_get_value), SVC(xpc_data_create),
    SVC(xpc_data_get_bytes_ptr), SVC(xpc_data_get_length), SVC(xpc_array_create),
    SVC(xpc_retain), SVC(xpc_release), SVC(xpc_copy_description), SVC(xpc_get_type),
    SVC(xpc_null_create), SVC(launch_activate_socket), SVC(launch_msg),
    SVCD("bootstrap_port", bootstrap_port_value),
    SVCD("mach_task_self_", mach_task_self_value),
    SVCD("dispatch_main_q", dispatch_main_q_storage),
    SVCD("dispatch_source_type_timer", dispatch_source_type_timer),
    SVCD("dispatch_source_type_data_add", dispatch_source_type_data_add),
    SVCD("dispatch_source_type_data_or", dispatch_source_type_data_or),
    SVCD("dispatch_source_type_data_replace", dispatch_source_type_data_replace),
    SVCD("dispatch_source_type_read", dispatch_source_type_read),
    SVCD("dispatch_source_type_write", dispatch_source_type_write),
    SVCD("_dispatch_source_type_timer", _dispatch_source_type_timer),
    SVCD("_dispatch_source_type_data_add", _dispatch_source_type_data_add),
    SVCD("_dispatch_source_type_data_or", _dispatch_source_type_data_or),
    SVCD("_dispatch_source_type_data_replace", _dispatch_source_type_data_replace),
    SVCD("_dispatch_source_type_read", _dispatch_source_type_read),
    SVCD("_dispatch_source_type_write", _dispatch_source_type_write),
    SVCD("xpc_type_dictionary", xpc_type_dictionary_storage),
    SVCD("xpc_type_string", xpc_type_string_storage),
    SVCD("xpc_type_int64", xpc_type_int64_storage),
    SVCD("xpc_type_bool", xpc_type_bool_storage),
    SVCD("xpc_type_data", xpc_type_data_storage),
    SVCD("xpc_type_array", xpc_type_array_storage),
    SVCD("xpc_type_error", xpc_type_error_storage),
    SVCD("xpc_type_connection", xpc_type_connection_storage),
    { "pthread_mutex_init", (void *)(uintptr_t)&shim_pthread_mutex_init },
    { "pthread_mutex_lock", (void *)(uintptr_t)&shim_pthread_mutex_lock },
    { "pthread_mutex_unlock", (void *)(uintptr_t)&shim_pthread_mutex_unlock },
    { "pthread_mutex_destroy", (void *)(uintptr_t)&shim_pthread_mutex_destroy },
    { "pthread_mutexattr_init", (void *)(uintptr_t)&shim_pthread_mutexattr_init },
    { "pthread_mutexattr_destroy", (void *)(uintptr_t)&shim_pthread_mutexattr_destroy },
    { "pthread_mutexattr_settype", (void *)(uintptr_t)&shim_pthread_mutexattr_settype },
    { "pthread_mutexattr_gettype", (void *)(uintptr_t)&shim_pthread_mutexattr_gettype },
    { "os_unfair_lock_lock", (void *)(uintptr_t)&shim_os_unfair_lock_lock },
    { "os_unfair_lock_unlock", (void *)(uintptr_t)&shim_os_unfair_lock_unlock },
};

void *iosim_services_lookup(const char *name)
{
    if (!name) return NULL;
    for (size_t i = 0; i < sizeof(service_symbols) / sizeof(service_symbols[0]); i++)
        if (strcmp(service_symbols[i].name, name) == 0)
            return service_symbols[i].addr;
    return NULL;
}
