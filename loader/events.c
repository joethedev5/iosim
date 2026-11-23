#define _GNU_SOURCE
#include "events.h"

#include <fcntl.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <poll.h>
#include <time.h>
#include <errno.h>

static int event_fd = -1;
static int second_x;
static int second_y;
static int last_touch_id;

/* The finger id of the most recent per-touch record. */
int iosim_event_touch_id(void)
{
    return last_touch_id;
}

/* The second finger of the last pinch/rotate record, in device pixels. */
void iosim_event_second_point(int *x, int *y)
{
    if (x)
        *x = second_x;
    if (y)
        *y = second_y;
}

/* A FIFO with no current writer is not a closed event stream: the device
 * manager opens it per event. Treat transient HUP/EOF as idle time. */
static void event_idle(void)
{
    struct timespec ts;
    ts.tv_sec = 0;
    ts.tv_nsec = 16 * 1000 * 1000;
    nanosleep(&ts, NULL);
}

void iosim_event_close(void)
{
    if (event_fd >= 0)
    {
        close(event_fd);
        event_fd = -1;
    }
}

int iosim_event_open(void)
{
    if (event_fd >= 0)
        return 1;
    const char *path = getenv("IOSIM_EVENT_FIFO");
    if (!path || !*path)
        return 0;
    event_fd = open(path, O_RDWR);
    return event_fd >= 0;
}

int iosim_event_next(int *type, int *x, int *y)
{
    if (event_fd < 0 && !iosim_event_open())
        return 0;

    struct pollfd pfd;
    pfd.fd = event_fd;
    pfd.events = POLLIN;
    int pr = poll(&pfd, 1, 16);
    if (pr == 0)
        return 2;
    if (pr < 0)
    {
        if (errno == EINTR)
            return 2;
        event_idle();
        return 2;
    }
    if (!(pfd.revents & POLLIN))
    {
        /* POLLHUP or POLLERR with no data queued: the last writer closed
         * between events. Idle until the next writer arrives. */
        event_idle();
        return 2;
    }

    char line[128];
    size_t len = 0;
    while (len + 1 < sizeof(line))
    {
        char c;
        ssize_t n = read(event_fd, &c, 1);
        if (n < 0)
        {
            if (errno == EINTR)
                continue;
            event_idle();
            return 2;
        }
        if (n == 0)
        {
            event_idle();
            return 2;
        }
        if (c == '\n')
            break;
        line[len++] = c;
    }
    line[len] = 0;

    int px, py;
    if (strncmp(line, "quit", 4) == 0)
        return 0;
    if (strncmp(line, "home", 4) == 0)
    {
        *type = 7;
        *x = 0;
        *y = 0;
        return 1;
    }
    if (strncmp(line, "apps", 4) == 0)
    {
        *type = 8;
        *x = 0;
        *y = 0;
        return 1;
    }
    if (strncmp(line, "switcher", 8) == 0)
    {
        *type = 9;
        *x = 0;
        *y = 0;
        return 1;
    }
    if (strncmp(line, "lock", 4) == 0)
    {
        *type = 10;
        *x = 0;
        *y = 0;
        return 1;
    }
    if (strncmp(line, "unlock", 6) == 0)
    {
        *type = 11;
        *x = 0;
        *y = 0;
        return 1;
    }
    if (strncmp(line, "appearance", 10) == 0)
    {
        *type = 18;
        *x = line[11] == '1' ? 1 : 0;
        *y = 0;
        return 1;
    }
    if (sscanf(line, "tap %d %d", &px, &py) == 2)
    {
        *type = 1;
        *x = px;
        *y = py;
        return 1;
    }
    if (sscanf(line, "down %d %d", &px, &py) == 2)
    {
        *type = 2;
        *x = px;
        *y = py;
        return 1;
    }
    if (sscanf(line, "move %d %d", &px, &py) == 2)
    {
        *type = 3;
        *x = px;
        *y = py;
        return 1;
    }
    if (sscanf(line, "up %d %d", &px, &py) == 2)
    {
        *type = 4;
        *x = px;
        *y = py;
        return 1;
    }
    if (sscanf(line, "key %d", &px) == 1)
    {
        *type = 5;
        *x = px;
        *y = 0;
        return 1;
    }
    {
        int tid, tx, ty;
        char action[16];
        if (sscanf(line, "touch %d %15s %d %d", &tid, action, &tx, &ty) == 4)
        {
            int touch_type = 0;
            if (strcmp(action, "down") == 0)
                touch_type = 20;
            else if (strcmp(action, "move") == 0)
                touch_type = 21;
            else if (strcmp(action, "up") == 0)
                touch_type = 22;
            else if (strcmp(action, "cancel") == 0)
                touch_type = 23;
            if (touch_type)
            {
                last_touch_id = tid;
                *type = touch_type;
                *x = tx;
                *y = ty;
                return 1;
            }
        }
    }
    {
        int x1, y1, x2, y2;
        int pinch_type = 0;
        if (sscanf(line, "pinch1 %d %d %d %d", &x1, &y1, &x2, &y2) == 4)
            pinch_type = 12;
        else if (sscanf(line, "pinch2 %d %d %d %d", &x1, &y1, &x2, &y2) == 4)
            pinch_type = 13;
        else if (sscanf(line, "pinch3 %d %d %d %d", &x1, &y1, &x2, &y2) == 4)
            pinch_type = 14;
        else if (sscanf(line, "rotate1 %d %d %d %d", &x1, &y1, &x2, &y2) == 4)
            pinch_type = 15;
        else if (sscanf(line, "rotate2 %d %d %d %d", &x1, &y1, &x2, &y2) == 4)
            pinch_type = 16;
        else if (sscanf(line, "rotate3 %d %d %d %d", &x1, &y1, &x2, &y2) == 4)
            pinch_type = 17;
        if (pinch_type)
        {
            second_x = x2;
            second_y = y2;
            *type = pinch_type;
            *x = (x1 + x2) / 2;
            *y = (y1 + y2) / 2;
            return 1;
        }
    }
    if (strncmp(line, "backspace", 9) == 0)
    {
        *type = 6;
        *x = 0;
        *y = 0;
        return 1;
    }
    return iosim_event_next(type, x, y);
}
