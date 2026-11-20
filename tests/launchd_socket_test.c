/* launchd socket-activation fixture: the job is not running until a client
 * connects to the socket launchd created. It fetches the listening descriptor
 * through launch_activate_socket, accepts one pending connection, answers it
 * and exits, so the next connection exercises on-demand restart. */
#include <stddef.h>

extern int printf(const char *fmt, ...);
extern int fflush(void *stream);
extern int launch_activate_socket(const char *name, int **fds, size_t *cnt);
extern int accept(int fd, void *addr, unsigned int *len);
extern long read(int fd, void *buf, unsigned long count);
extern long write(int fd, const void *buf, unsigned long count);
extern int close(int fd);
extern unsigned long strlen(const char *s);

int main(void)
{
    int *fds = 0;
    size_t cnt = 0;
    int rc = launch_activate_socket("MySock", &fds, &cnt);
    printf("[sockjob] activated rc=%d cnt=%lu\n", rc, (unsigned long)cnt);
    fflush(0);
    if (rc != 0 || cnt < 1 || !fds)
        return 1;

    int conn = accept(fds[0], 0, 0);
    printf("[sockjob] accepted=%d\n", conn);
    fflush(0);
    if (conn < 0)
        return 1;

    char buf[64];
    long n = read(conn, buf, sizeof buf - 1);
    if (n > 0)
    {
        buf[n] = 0;
        printf("[sockjob] got %s\n", buf);
        fflush(0);
        const char *reply = "pong from socket job";
        write(conn, reply, strlen(reply));
    }
    close(conn);
    return 0;
}
