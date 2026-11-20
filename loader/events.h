#ifndef IOSIM_EVENTS_H
#define IOSIM_EVENTS_H

/* Returns 0 when the event stream closes, 1 for an event.
 * type 1 = tap, x/y are device pixels. */
int iosim_event_open(void);
int iosim_event_next(int *type, int *x, int *y);
void iosim_event_close(void);

#endif
