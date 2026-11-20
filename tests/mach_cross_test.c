/* Cross-process Mach messaging fixture.
 *
 *   mach_cross service   registers a bootstrap service and receives one
 *                        message over its receive port
 *   mach_cross client    looks the service up in another process, sends a
 *                        message and prints the send result
 *   mach_cross probe     looks up a name nobody registered
 *
 * The Mach ABI structs are declared here so the fixture builds without an
 * Apple SDK; the layouts match x86_64 Darwin. */
extern int printf(const char *fmt, ...);
extern int fflush(void *stream);
extern int strcmp(const char *a, const char *b);
extern int usleep(unsigned int usec);

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
extern mach_port_t bootstrap_port;
extern kern_return_t mach_port_allocate(mach_port_t task, int right,
                                        mach_port_t *name);
extern kern_return_t mach_msg(mach_msg_header_t *msg, unsigned option,
                              unsigned send_size, unsigned rcv_size,
                              mach_port_t rcv_name, unsigned timeout,
                              mach_port_t notify);
extern kern_return_t mach_msg_send(mach_msg_header_t *msg);
extern kern_return_t bootstrap_register(mach_port_t bp, const char *name,
                                        mach_port_t port);
extern kern_return_t bootstrap_look_up(mach_port_t bp, const char *name,
                                       mach_port_t *port);

#define MACH_RCV_MSG 0x2
#define MACH_RCV_TIMEOUT 0x100
#define MACH_PORT_RIGHT_RECEIVE 1

typedef struct {
    mach_msg_header_t header;
    int value;
    char text[32];
} ping_msg;

int main(int argc, char **argv)
{
    const char *role = argc > 1 ? argv[1] : "";

    if (strcmp(role, "service") == 0)
    {
        mach_port_t port = 0;
        kern_return_t kr =
            mach_port_allocate(mach_task_self(), MACH_PORT_RIGHT_RECEIVE,
                               &port);
        if (kr != 0)
        {
            printf("service: alloc=%d\n", kr);
            fflush(0);
            return 1;
        }
        kr = bootstrap_register(bootstrap_port, "com.iosim.cross.mach", port);
        printf("service: registered=%d port=%#x\n", kr, port);
        fflush(0);
        if (kr != 0)
            return 1;

        ping_msg recv;
        recv.header.msgh_size = sizeof(recv);
        recv.header.msgh_local_port = port;
        kr = mach_msg(&recv.header, MACH_RCV_MSG | MACH_RCV_TIMEOUT, 0,
                      sizeof(recv), port, 10000, 0);
        if (kr != 0)
        {
            printf("service: receive=%d\n", kr);
            fflush(0);
            return 1;
        }
        printf("service: received id=%#x value=%d text=%s bits=%#x\n",
               recv.header.msgh_id, recv.value, recv.text,
               recv.header.msgh_bits);
        fflush(0);
        return 0;
    }

    if (strcmp(role, "client") == 0)
    {
        mach_port_t port = 0;
        kern_return_t kr = 1102;
        for (int i = 0; i < 50; i++)
        {
            kr = bootstrap_look_up(bootstrap_port, "com.iosim.cross.mach",
                                   &port);
            if (kr == 0)
                break;
            usleep(50000);
        }
        if (kr != 0)
        {
            printf("client: lookup=%d\n", kr);
            fflush(0);
            return 1;
        }
        ping_msg msg;
        msg.header.msgh_bits = 0;
        msg.header.msgh_size = sizeof(msg);
        msg.header.msgh_remote_port = port;
        msg.header.msgh_local_port = 0;
        msg.header.msgh_voucher_port = 0;
        msg.header.msgh_id = 0x1234;
        msg.value = 91;
        const char *text = "hello across processes";
        int i = 0;
        for (; text[i] && i < 31; i++)
            msg.text[i] = text[i];
        msg.text[i] = 0;
        kr = mach_msg_send(&msg.header);
        printf("client: sent=%d port=%#x\n", kr, port);
        fflush(0);
        return kr == 0 ? 0 : 1;
    }

    if (strcmp(role, "probe") == 0)
    {
        mach_port_t port = 0;
        kern_return_t kr = bootstrap_look_up(
            bootstrap_port, "com.iosim.cross.missing", &port);
        printf("probe: unknown lookup=%d\n", kr);
        fflush(0);
        return kr == 1102 ? 0 : 1;
    }

    if (strcmp(role, "register") == 0)
    {
        mach_port_t port = 0;
        kern_return_t kr =
            mach_port_allocate(mach_task_self(), MACH_PORT_RIGHT_RECEIVE,
                               &port);
        if (kr == 0)
            kr = bootstrap_register(bootstrap_port, "com.iosim.cross.mach",
                                    port);
        printf("register: result=%d\n", kr);
        fflush(0);
        return kr == 0 ? 0 : 1;
    }

    if (strcmp(role, "conflict") == 0)
    {
        mach_port_t port = 0;
        kern_return_t kr =
            mach_port_allocate(mach_task_self(), MACH_PORT_RIGHT_RECEIVE,
                               &port);
        if (kr == 0)
            kr = bootstrap_register(bootstrap_port, "com.iosim.cross.mach",
                                    port);
        printf("conflict: result=%d\n", kr);
        fflush(0);
        return kr == 1103 ? 0 : 1;
    }

    printf("usage: mach_cross service|client|probe|register|conflict\n");
    return 2;
}
