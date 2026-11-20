/* Cross-process XPC fixture.
 *
 *   xpc_cross service   registers a Mach service as an XPC listener, installs
 *                       an event handler and exits when a message arrives
 *   xpc_cross client    connects to the listener by bootstrap name and sends
 *                       a dictionary over XPC
 *
 * Built with -fblocks; the XPC types and entry points are declared here so
 * the fixture builds without an Apple SDK. */
extern int printf(const char *fmt, ...);
extern int fflush(void *stream);
extern int strcmp(const char *a, const char *b);
extern void exit(int status);
extern unsigned int sleep(unsigned int seconds);

typedef void *xpc_connection_t;
typedef void *xpc_object_t;

extern xpc_connection_t xpc_connection_create_mach_service(const char *name,
                                                           void *queue,
                                                           unsigned long flags);
extern void xpc_connection_set_event_handler(xpc_connection_t conn,
                                             void (^handler)(xpc_object_t));
extern void xpc_connection_resume(xpc_connection_t conn);
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
extern void xpc_connection_send_message(xpc_connection_t conn,
                                        xpc_object_t message);

#define XPC_CONNECTION_MACH_SERVICE_LISTENER 1

int main(int argc, char **argv)
{
    const char *role = argc > 1 ? argv[1] : "";

    if (strcmp(role, "service") == 0)
    {
        xpc_connection_t listener = xpc_connection_create_mach_service(
            "com.iosim.cross.xpc", 0, XPC_CONNECTION_MACH_SERVICE_LISTENER);
        xpc_connection_set_event_handler(listener, ^(xpc_object_t event) {
            const char *kind = xpc_dictionary_get_string(event, "kind");
            long long seq = xpc_dictionary_get_int64(event, "seq");
            xpc_object_t flag = xpc_dictionary_get_value(event, "flag");
            xpc_object_t blob = xpc_dictionary_get_value(event, "blob");
            printf("xpc service: received kind=%s seq=%lld flag=%d blob=%lu\n",
                   kind ? kind : "(null)", seq,
                   flag ? xpc_bool_get_value(flag) : 0,
                   blob ? xpc_data_get_length(blob) : 0);
            fflush(0);
            exit(0);
        });
        xpc_connection_resume(listener);
        printf("xpc service: ready\n");
        fflush(0);
        for (int i = 0; i < 20; i++)
            sleep(1);
        printf("xpc service: timed out\n");
        fflush(0);
        return 1;
    }

    if (strcmp(role, "client") == 0)
    {
        xpc_connection_t client = xpc_connection_create_mach_service(
            "com.iosim.cross.xpc", 0, 0);
        xpc_connection_set_event_handler(client, ^(xpc_object_t event) {
            (void)event;
        });
        xpc_connection_resume(client);
        xpc_object_t dict = xpc_dictionary_create(0, 0, 0);
        xpc_dictionary_set_string(dict, "kind", "ping");
        xpc_dictionary_set_int64(dict, "seq", 7);
        xpc_dictionary_set_bool(dict, "flag", 1);
        xpc_dictionary_set_data(dict, "blob", "abcd", 4);
        xpc_connection_send_message(client, dict);
        printf("xpc client: sent\n");
        fflush(0);
        return 0;
    }

    printf("usage: xpc_cross service|client\n");
    return 2;
}
