/* launchd on-demand job fixture.
 *
 *   launchd_job_test job <service>   registers <service> as an XPC listener,
 *                                    replies pong to the first request and
 *                                    exits
 *   launchd_job_test client <service> sends one request with a reply handler
 *                                    and prints the reply
 *   launchd_job_test interval         prints one line and exits, so a
 *                                    StartInterval plist repeats it
 *   launchd_job_test keepalive        prints one line and exits, so a
 *                                    KeepAlive plist restarts it
 *
 * The job is installed as a LaunchDaemon plist with MachServices = <service>
 * and RunAtLoad = false, so the service only starts when a client looks the
 * name up. */
extern int printf(const char *fmt, ...);
extern int fflush(void *stream);
extern int strcmp(const char *a, const char *b);
extern int usleep(unsigned int microseconds);
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
extern void xpc_connection_send_message(xpc_connection_t conn,
                                        xpc_object_t message);
extern void xpc_connection_send_message_with_reply(
    xpc_connection_t conn, xpc_object_t message, void *queue,
    void (^handler)(xpc_object_t reply));
extern xpc_object_t xpc_dictionary_create(const void *keys, const void *values,
                                          unsigned long count);
extern void xpc_dictionary_set_string(xpc_object_t dict, const char *key,
                                      const char *value);
extern void xpc_dictionary_set_int64(xpc_object_t dict, const char *key,
                                     long long value);
extern const char *xpc_dictionary_get_string(xpc_object_t dict,
                                             const char *key);
extern long long xpc_dictionary_get_int64(xpc_object_t dict, const char *key);

#define XPC_CONNECTION_MACH_SERVICE_LISTENER 1

static volatile int g_replied;

static void run_job(const char *service)
{
    xpc_connection_t listener = xpc_connection_create_mach_service(
        service, 0, XPC_CONNECTION_MACH_SERVICE_LISTENER);
    xpc_connection_set_event_handler(listener, ^(xpc_object_t event) {
        xpc_connection_set_event_handler(event, ^(xpc_object_t message) {
            const char *kind = xpc_dictionary_get_string(message, "kind");
            long long seq = xpc_dictionary_get_int64(message, "seq");
            printf("launchd job: received kind=%s seq=%lld\n",
                   kind ? kind : "(null)", seq);
            fflush(0);

            xpc_object_t reply = xpc_dictionary_create(0, 0, 0);
            xpc_dictionary_set_string(reply, "kind", "pong");
            xpc_dictionary_set_int64(reply, "seq", seq + 1);
            xpc_connection_send_message(event, reply);
            printf("launchd job: replied\n");
            fflush(0);
            exit(0);
        });
        xpc_connection_resume(event);
    });
    xpc_connection_resume(listener);
    printf("launchd job: ready name=%s\n", service);
    fflush(0);
    for (int i = 0; i < 20; i++)
        sleep(1);
    printf("launchd job: timed out\n");
    fflush(0);
    exit(1);
}

static void run_client(const char *service)
{
    xpc_connection_t client = xpc_connection_create_mach_service(
        service, 0, 0);
    xpc_connection_set_event_handler(client, ^(xpc_object_t event) {
        (void)event;
    });
    xpc_connection_resume(client);

    xpc_object_t dict = xpc_dictionary_create(0, 0, 0);
    xpc_dictionary_set_string(dict, "kind", "ping");
    xpc_dictionary_set_int64(dict, "seq", 41);
    xpc_connection_send_message_with_reply(
        client, dict, 0, ^(xpc_object_t reply) {
            const char *kind = xpc_dictionary_get_string(reply, "kind");
            long long seq = xpc_dictionary_get_int64(reply, "seq");
            printf("launchd client: reply kind=%s seq=%lld\n",
                   kind ? kind : "(null)", seq);
            fflush(0);
            g_replied = 1;
        });
    for (int i = 0; i < 150 && !g_replied; i++)
        usleep(100000);
    if (!g_replied)
    {
        printf("launchd client: no reply\n");
        fflush(0);
        exit(1);
    }
}

int main(int argc, char **argv)
{
    if (argc > 1 && strcmp(argv[1], "job") == 0 && argc > 2)
    {
        run_job(argv[2]);
        return 1;
    }
    if (argc > 1 && strcmp(argv[1], "client") == 0 && argc > 2)
    {
        run_client(argv[2]);
        return 0;
    }
    if (argc > 1 && strcmp(argv[1], "interval") == 0)
    {
        printf("launchd job: interval\n");
        fflush(0);
        return 0;
    }
    if (argc > 1 && strcmp(argv[1], "keepalive") == 0)
    {
        printf("launchd job: keepalive\n");
        fflush(0);
        return 0;
    }
    printf("usage: launchd_job_test job|client <service> | interval\n");
    return 2;
}
