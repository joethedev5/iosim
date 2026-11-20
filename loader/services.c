/* Host implementations of the Darwin service substrate used by simulator
 * binaries: libdispatch, Mach ports/messages, bootstrap registration and a
 * minimal XPC transport. All queues are process-local, which is enough for
 * an app and a service hosted by the same iosim process. */
#define _GNU_SOURCE
#include <pthread.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include <unistd.h>
#include "services.h"

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
    double when;
};
static struct mainq_item mainq[MAINQ_CAP];
static int mainq_head, mainq_tail;
static pthread_mutex_t mainq_lock = PTHREAD_MUTEX_INITIALIZER;

struct dispatch_queue_s {
    int is_main;
};
struct dispatch_queue_s main_queue = { 1 }, global_queue = { 0 };
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
    return calloc(1, sizeof(struct dispatch_queue_s));
}
void dispatch_release(void *queue) { (void)queue; }
void dispatch_retain(void *queue) { (void)queue; }

static void mainq_push(void *block, double when)
{
    if (getenv("IOSIM_DEBUG_DISPATCH"))
        fprintf(stderr, "[dispatch] enqueue %p when %.3f now %.3f\n", block,
                when, now_seconds());
    pthread_mutex_lock(&mainq_lock);
    int next = (mainq_tail + 1) % MAINQ_CAP;
    if (next != mainq_head)
    {
        mainq[mainq_tail].block = block;
        mainq[mainq_tail].when = when;
        mainq_tail = next;
    }
    pthread_mutex_unlock(&mainq_lock);
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

void dispatch_async_f(void *queue, void *context, void (*function)(void *))
{
    (void)queue; (void)context; (void)function;
}

void dispatch_sync(void *queue, void *block)
{
    (void)queue;
    call_block(block);
}
void dispatch_sync_f(void *queue, void *context, void (*function)(void *))
{
    (void)queue; (void)function; (void)context;
}

typedef uint64_t dispatch_time_t;
dispatch_time_t dispatch_time(dispatch_time_t base, int64_t delta)
{
    (void)base;
    return (dispatch_time_t)(now_seconds() * 1e9 + delta);
}
void dispatch_after(dispatch_time_t when, void *queue, void *block)
{
    double t = (double)when / 1e9;
    if (!block)
        return;
    if (queue == &main_queue || queue == NULL)
        mainq_push(_Block_copy(block), t);
    else
        dispatch_async(queue, block);
}
void dispatch_after_f(dispatch_time_t when, void *queue, void *context,
                      void (*function)(void *))
{
    (void)when; (void)queue; (void)context; (void)function;
}
void dispatch_after_f_np(dispatch_time_t when, void *queue, void *context,
                         void (*function)(void *))
{
    (void)when; (void)queue; (void)context; (void)function;
}

int iosim_dispatch_drain_main(void)
{
    int ran = 0;
    double now = now_seconds();
    for (;;)
    {
        void *block = NULL;
        pthread_mutex_lock(&mainq_lock);
        if (mainq_head != mainq_tail && mainq[mainq_head].when <= now)
        {
            block = mainq[mainq_head].block;
            mainq_head = (mainq_head + 1) % MAINQ_CAP;
        }
        pthread_mutex_unlock(&mainq_lock);
        if (!block)
            break;
        if (getenv("IOSIM_DEBUG_DISPATCH"))
            fprintf(stderr, "[dispatch] run %p at %.3f\n", block,
                    now_seconds());
        call_block(block);
        _Block_release(block);
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
const char *dispatch_queue_get_label(void *queue) { return queue == &main_queue ? "com.apple.main-thread" : "iosim.queue"; }
void dispatch_queue_set_specific(void *queue, const void *key, void *context, void (*destructor)(void *))
{ (void)queue; (void)key; (void)context; (void)destructor; }
void *dispatch_get_specific(const void *key) { (void)key; return NULL; }
void dispatch_barrier_async(void *queue, void *block) { dispatch_async(queue, block); }
void dispatch_barrier_sync(void *queue, void *block) { dispatch_sync(queue, block); }
void dispatch_apply(long iterations, void *queue, void *block)
{
    (void)queue;
    if (!block) return;
    for (long i = 0; i < iterations; i++)
        ((void (*)(void *, long))((struct block_layout *)block)->invoke)(block, i);
}

typedef long dispatch_once_t;
void dispatch_once(dispatch_once_t *predicate, void *block)
{
    if (predicate && __sync_bool_compare_and_swap(predicate, 0, 1))
        call_block(block);
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
void dispatch_group_async(void *group, void *queue, void *block)
{
    dispatch_group_enter(group);
    mainq_push(block, 0.0);
    dispatch_group_leave(group);
    (void)queue;
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

int mach_port_allocate(uint32_t task, uint32_t right, uint32_t *name)
{
    (void)task; (void)right;
    pthread_mutex_lock(&ports_lock);
    if (port_counter >= MAX_PORTS)
        port_counter = 2;
    uint32_t p = port_counter++;
    ports[p].used = 1;
    ports[p].head = ports[p].tail = NULL;
    pthread_mutex_init(&ports[p].lock, NULL);
    pthread_cond_init(&ports[p].cond, NULL);
    pthread_mutex_unlock(&ports_lock);
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

/* Service registry (the bootstrap namespace). */
struct service { char name[128]; uint32_t port; };
static struct service services[128];
static int service_count;
static pthread_mutex_t services_lock = PTHREAD_MUTEX_INITIALIZER;

int bootstrap_register(uint32_t bp, const char *name, uint32_t port)
{
    (void)bp;
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
    return 1102; /* BOOTSTRAP_UNKNOWN_SERVICE */
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

struct xpc_connection {
    char *name;
    void *handler;
};
static struct xpc_connection *connections[64];
static int connection_count;

static struct xpc_connection *find_connection(const char *name)
{
    for (int i = 0; i < connection_count; i++)
        if (connections[i] && strcmp(connections[i]->name, name) == 0)
            return connections[i];
    return NULL;
}
void *xpc_connection_create_mach_service(const char *name, void *queue, unsigned long flags)
{
    (void)queue; (void)flags;
    struct xpc_connection *c = calloc(1, sizeof(*c));
    c->name = strdup(name ? name : "");
    if (connection_count < 64)
        connections[connection_count++] = c;
    return c;
}
void *xpc_connection_create(const char *name, void *queue)
{
    (void)queue;
    struct xpc_connection *c = calloc(1, sizeof(*c));
    c->name = strdup(name ? name : "");
    if (connection_count < 64)
        connections[connection_count++] = c;
    return c;
}
void xpc_connection_set_event_handler(void *conn, void *handler)
{
    ((struct xpc_connection *)conn)->handler = handler;
}
void xpc_connection_set_target_queue(void *conn, void *queue) { (void)conn; (void)queue; }
void xpc_connection_resume(void *conn) { (void)conn; }
void xpc_connection_suspend(void *conn) { (void)conn; }
void xpc_connection_cancel(void *conn) { (void)conn; }
void xpc_connection_send_message(void *conn, void *message)
{
    struct xpc_connection *c = conn;
    if (!c) return;
    for (int i = 0; i < connection_count; i++)
    {
        struct xpc_connection *peer = connections[i];
        if (peer && peer != c && peer->handler &&
            strcmp(peer->name, c->name) == 0)
        {
            call_block(peer->handler);
            break;
        }
    }
    (void)message;
}
void xpc_connection_send_message_with_reply(void *conn, void *message, void *queue, void *handler)
{
    (void)conn; (void)message; (void)queue; (void)handler;
}
void xpc_connection_send_barrier(void *conn, void *block) { (void)conn; call_block(block); }
int xpc_connection_get_pid(void *conn) { (void)conn; return getpid(); }
void xpc_main(void (*handler)(void *)) { (void)handler; }

int launch_activate_socket(const char *name, int *fds, size_t *count)
{
    (void)name;
    if (fds) fds[0] = -1;
    if (count) *count = 0;
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

/* xpc_get_type returns the shared type constants so app comparisons work. */
struct xpc_object *xpc_get_type(void *obj)
{
    struct xpc_object *o = obj;
    if (!o) return (struct xpc_object *)&xpc_type_error_obj;
    switch (o->type)
    {
    case XPC_DICT: return (struct xpc_object *)&xpc_type_dictionary_obj;
    case XPC_STRING: return (struct xpc_object *)&xpc_type_string_obj;
    case XPC_INT: return (struct xpc_object *)&xpc_type_int64_obj;
    case XPC_BOOL: return (struct xpc_object *)&xpc_type_bool_obj;
    case XPC_DATA: return (struct xpc_object *)&xpc_type_data_obj;
    case XPC_ARRAY: return (struct xpc_object *)&xpc_type_array_obj;
    case XPC_CONNECTION: return (struct xpc_object *)&xpc_type_connection_obj;
    default: return (struct xpc_object *)&xpc_type_error_obj;
    }
}

static int shim_pthread_mutex_init(void *m, const void *attr) { (void)attr; *(int *)m = 0; return 0; }
static int shim_pthread_mutex_lock(void *m) { while (__sync_lock_test_and_set((int *)m, 1)) usleep(50); return 0; }
static int shim_pthread_mutex_unlock(void *m) { __sync_lock_release((int *)m); return 0; }
static int shim_pthread_mutex_destroy(void *m) { (void)m; return 0; }
static void shim_os_unfair_lock_lock(void *l) { (void)l; }
static void shim_os_unfair_lock_unlock(void *l) { (void)l; }

struct service_symbol { const char *name; void *addr; };

#define SVC(fn) { #fn, (void *)(uintptr_t)&fn }
#define SVCD(nm, obj) { nm, (void *)(uintptr_t)&obj }

static const struct service_symbol service_symbols[] = {
    SVC(dispatch_get_main_queue), SVC(dispatch_get_global_queue),
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
    SVC(mach_port_allocate), SVC(mach_port_deallocate), SVC(mach_port_mod_refs),
    SVC(mach_port_insert_right), SVC(mach_port_destroy), SVC(mach_task_self),
    SVC(mach_host_self), SVC(mach_msg), SVC(mach_msg_send), SVC(mach_msg_receive),
    SVC(bootstrap_register), SVC(bootstrap_look_up),
    SVC(xpc_connection_create_mach_service), SVC(xpc_connection_create),
    SVC(xpc_connection_set_event_handler), SVC(xpc_connection_set_target_queue),
    SVC(xpc_connection_resume), SVC(xpc_connection_suspend), SVC(xpc_connection_cancel),
    SVC(xpc_connection_send_message), SVC(xpc_connection_send_message_with_reply),
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
