#ifndef IOSIM_EVENTS_H
#define IOSIM_EVENTS_H

/* Returns 0 on the explicit quit record, 1 for an event, 2 when idle.
 * type 1 = tap, 2 = down, 3 = move, 4 = up, 5 = key, 6 = backspace,
 * 7 = home/suspend, 8 = apps changed, 9 = switcher, 12-14 = pinch
 * begin/move/end, 15-17 = rotate begin/move/end, 20-23 = per-finger
 * down/move/up/cancel. x/y are device pixels and carry the centroid;
 * iosim_event_second_point returns the other finger, and
 * iosim_event_touch_id returns the finger of a 20-23 record. */
int iosim_event_open(void);
int iosim_event_next(int *type, int *x, int *y);
void iosim_event_second_point(int *x, int *y);
int iosim_event_touch_id(void);
void iosim_event_close(void);

#endif
