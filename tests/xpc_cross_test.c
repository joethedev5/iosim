/* Cross-process XPC fixture.
 *
 *   xpc_cross service   registers a Mach service as an XPC listener; the
 *                       listener handler receives each client as a peer
 *                       connection, installs a message handler on it and
 *                       replies with a pong dictionary
 *   xpc_cross client    connects by bootstrap name, sends a dictionary with
 *                       an async reply handler, then one with the synchronous
 *                       reply API, and prints both replies
 *
 * Built with -fblocks; the XPC types and entry points are declared here so
 * the fixture builds without an Apple SDK. */
extern int printf(const char *fmt, ...);
extern int fflush(void *stream);
extern int strcmp(const char *a, const char *b);
extern void exit(int status);
extern unsigned int sleep(unsigned int seconds);
extern int usleep(unsigned int microseconds);

typedef void *xpc_connection_t;
typedef void *xpc_object_t;
typedef void *xpc_type_t;

extern xpc_connection_t xpc_connection_create_mach_service(const char *name,
                                                           void *queue,
                                                           unsigned long flags);
extern void xpc_connection_set_event_handler(xpc_connection_t conn,
                                             void (^handler)(xpc_object_t));
extern void xpc_connection_resume(xpc_connection_t conn);
extern void xpc_connection_send_message(xpc_connection_t conn,
                                        xpc_object_t message);
extern void xpc_connection_send_message_with_reply(
    xpc_connection_t conn, xpc_object_t message, void *queue,
    void (^handler)(xpc_object_t reply));
extern xpc_object_t xpc_connection_send_message_with_reply_sync(
    xpc_connection_t conn, xpc_object_t message);
extern xpc_object_t xpc_dictionary_create(const void *keys, const void *values,
                                          unsigned long count);
extern void xpc_dictionary_set_string(xpc_object_t dict, const char *key,
                                      const char *value);
extern void xpc_dictionary_set_int64(xpc_object_t dict, const char *key,
                                     long long value);
extern void xpc_dictionary_set_bool(xpc_object_t dict, const char *key,
                                    int value);
extern void xpc_dictionary_set_data(xpc_object_t dict, const char *key,
                                    const void *bytes, unsigned long length);
extern xpc_object_t xpc_dictionary_get_value(xpc_object_t dict,
                                             const char *key);
extern int xpc_bool_get_value(xpc_object_t object);
extern unsigned long xpc_data_get_length(xpc_object_t object);
extern const char *xpc_dictionary_get_string(xpc_object_t dict,
                                             const char *key);
extern long long xpc_dictionary_get_int64(xpc_object_t dict, const char *key);
extern xpc_type_t xpc_get_type(xpc_object_t object);
extern char xpc_type_connection[];

#define XPC_CONNECTION_MACH_SERVICE_LISTENER 1
#define XPC_SERVICE_NAME "com.iosim.cross.xpc"

static volatile int g_replied;
static volatile int g_service_messages;

static xpc_object_t make_ping(void)
{
    xpc_object_t dict = xpc_dictionary_create(0, 0, 0);
    xpc_dictionary_set_string(dict, "kind", "ping");
    xpc_dictionary_set_int64(dict, "seq", 7);
    xpc_dictionary_set_bool(dict, "flag", 1);
    xpc_dictionary_set_data(dict, "blob", "abcd", 4);
    return dict;
}

static void xpc_service(void)
{
    xpc_connection_t listener = xpc_connection_create_mach_service(
        XPC_SERVICE_NAME, 0, XPC_CONNECTION_MACH_SERVICE_LISTENER);
    xpc_connection_set_event_handler(listener, ^(xpc_object_t event) {
        if (xpc_get_type(event) != (xpc_type_t)xpc_type_connection)
            return;
        xpc_connection_set_event_handler(event, ^(xpc_object_t message) {
            const char *kind = xpc_dictionary_get_string(message, "kind");
            long long seq = xpc_dictionary_get_int64(message, "seq");
            xpc_object_t flag = xpc_dictionary_get_value(message, "flag");
            xpc_object_t blob = xpc_dictionary_get_value(message, "blob");
            printf("xpc service: received kind=%s seq=%lld flag=%d blob=%lu\n",
                   kind ? kind : "(null)", seq,
                   flag ? xpc_bool_get_value(flag) : 0,
                   blob ? xpc_data_get_length(blob) : 0);
            fflush(0);

            xpc_object_t reply = xpc_dictionary_create(0, 0, 0);
            xpc_dictionary_set_string(reply, "kind", "pong");
            xpc_dictionary_set_int64(reply, "seq", seq + 1);
            xpc_dictionary_set_bool(reply, "ok", 1);
            xpc_connection_send_message(event, reply);

            if (++g_service_messages >= 2)
                exit(0);
        });
        xpc_connection_resume(event);
    });
    xpc_connection_resume(listener);
    printf("xpc service: ready\n");
    fflush(0);
    for (int i = 0; i < 20; i++)
        sleep(1);
    printf("xpc service: timed out\n");
    fflush(0);
    exit(1);
}

static void xpc_client(void)
{
    xpc_connection_t client = xpc_connection_create_mach_service(
        XPC_SERVICE_NAME, 0, 0);
    xpc_connection_set_event_handler(client, ^(xpc_object_t event) {
        (void)event;
    });
    xpc_connection_resume(client);

    xpc_object_t dict = make_ping();
    xpc_connection_send_message_with_reply(
        client, dict, 0, ^(xpc_object_t reply) {
            const char *kind = xpc_dictionary_get_string(reply, "kind");
            long long seq = xpc_dictionary_get_int64(reply, "seq");
            printf("xpc client: reply kind=%s seq=%lld\n",
                   kind ? kind : "(null)", seq);
            fflush(0);
            g_replied = 1;
        });
    for (int i = 0; i < 100 && !g_replied; i++)
        usleep(100000);

    xpc_object_t reply = xpc_connection_send_message_with_reply_sync(
        client, make_ping());
    const char *kind = xpc_dictionary_get_string(reply, "kind");
    long long seq = xpc_dictionary_get_int64(reply, "seq");
    printf("xpc client: sync reply kind=%s seq=%lld\n",
           kind ? kind : "(null)", seq);
    fflush(0);
}

int main(int argc, char **argv)
{
    const char *role = argc > 1 ? argv[1] : "";

    if (strcmp(role, "service") == 0)
    {
        xpc_service();
        return 1;
    }
    if (strcmp(role, "client") == 0)
    {
        xpc_client();
        return g_replied ? 0 : 1;
    }

    printf("usage: xpc_cross service|client\n");
    return 2;
}
