/* Mach port lifecycle: refcounted rights, destroy/deallocate semantics and
 * error codes after a name is released. Single process; no launchd needed. */
extern int printf(const char *fmt, ...);
extern void *memset(void *dst, int c, unsigned long n);

typedef unsigned int mach_port_t;
typedef int kern_return_t;

typedef struct {
    unsigned int msgh_bits;
    unsigned int msgh_size;
    unsigned int msgh_remote_port;
    unsigned int msgh_local_port;
    unsigned int msgh_voucher_port;
    int msgh_id;
} mach_msg_header_t;

extern mach_port_t mach_task_self(void);
extern kern_return_t mach_port_allocate(mach_port_t task, int right,
                                        mach_port_t *name);
extern kern_return_t mach_port_deallocate(mach_port_t task, mach_port_t name);
extern kern_return_t mach_port_destroy(mach_port_t task, mach_port_t name);
extern kern_return_t mach_port_mod_refs(mach_port_t task, mach_port_t name,
                                        int right, int delta);
extern kern_return_t mach_port_insert_right(mach_port_t task, mach_port_t name,
                                            mach_port_t poly,
                                            mach_port_t poly_poly);
extern kern_return_t mach_msg_send(mach_msg_header_t *msg);
extern kern_return_t mach_msg_receive(mach_msg_header_t *msg);

#define MACH_PORT_RIGHT_SEND 0
#define MACH_PORT_RIGHT_RECEIVE 1
#define MACH_SEND_INVALID_DEST 0x10000002
#define MACH_RCV_INVALID_NAME 0x10004002

typedef struct {
    mach_msg_header_t header;
    int value;
} ping_msg;

int main(void)
{
    mach_port_t port = 0;
    mach_port_allocate(mach_task_self(), MACH_PORT_RIGHT_RECEIVE, &port);

    ping_msg message;
    memset(&message, 0, sizeof message);
    message.header.msgh_size = sizeof message;
    message.header.msgh_remote_port = port;
    message.value = 7;
    kern_return_t send1 = mach_msg_send(&message.header);

    ping_msg reply;
    memset(&reply, 0, sizeof reply);
    reply.header.msgh_size = sizeof reply;
    reply.header.msgh_local_port = port;
    kern_return_t recv1 = mach_msg_receive(&reply.header);
    int received = recv1 == 0 && reply.value == 7;

    mach_port_insert_right(mach_task_self(), port, port, 0);
    mach_port_mod_refs(mach_task_self(), port, MACH_PORT_RIGHT_SEND, -1);
    kern_return_t send2 = mach_msg_send(&message.header);
    memset(&reply, 0, sizeof reply);
    reply.header.msgh_size = sizeof reply;
    reply.header.msgh_local_port = port;
    kern_return_t recv2 = mach_msg_receive(&reply.header);
    int alive = send2 == 0 && recv2 == 0 && reply.value == 7;

    mach_port_mod_refs(mach_task_self(), port, MACH_PORT_RIGHT_RECEIVE, -1);
    kern_return_t send3 = mach_msg_send(&message.header);
    memset(&reply, 0, sizeof reply);
    reply.header.msgh_size = sizeof reply;
    reply.header.msgh_local_port = port;
    kern_return_t recv3 = mach_msg_receive(&reply.header);

    mach_port_t second = 0;
    mach_port_allocate(mach_task_self(), MACH_PORT_RIGHT_RECEIVE, &second);
    ping_msg other;
    memset(&other, 0, sizeof other);
    other.header.msgh_size = sizeof other;
    other.header.msgh_remote_port = second;
    other.value = 9;
    kern_return_t send4 = mach_msg_send(&other.header);
    mach_port_deallocate(mach_task_self(), second);
    kern_return_t send5 = mach_msg_send(&other.header);

    printf("[mach] lifecycle %d %d %d %d %d %d\n",
           send1 == 0, received, alive,
           send3 == MACH_SEND_INVALID_DEST,
           recv3 == MACH_RCV_INVALID_NAME,
           send4 == 0 && send5 == MACH_SEND_INVALID_DEST);
    return 0;
}
