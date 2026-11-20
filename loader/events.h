#ifndef IOSIM_EVENTS_H
#define IOSIM_EVENTS_H

/* Returns 0 on the explicit quit record, 1 for an event, 2 when idle.
 * type 1 = tap, 2 = down, 3 = move, 4 = up, 5 = key, 6 = backspace,
 * 7 = home/suspend, 8 = apps changed, 9 = switcher. x/y are device pixels. */
int iosim_event_open(void);
int iosim_event_next(int *type, int *x, int *y);
void iosim_event_close(void);

#endif
