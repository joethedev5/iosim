/* Background task bookkeeping: begin returns a nonzero token, the active
 * app reports no remaining window, and ending the task clears it. */
#include "UIKitStub.h"
extern int printf(const char *fmt, ...);
extern int fflush(void *stream);

int main(void)
{
    @autoreleasepool
    {
        UIApplication *app = [UIApplication sharedApplication];
        __block int expired = 0;
        unsigned long task = [app beginBackgroundTaskWithExpirationHandler:^{
            expired = 1;
        }];
        printf("[bg] token %d remaining %.0f\n", task != 0,
               [app backgroundTimeRemaining]);
        [app endBackgroundTask:task];
        printf("[bg] ended %.0f expired %d\n",
               [app backgroundTimeRemaining], expired);
        fflush(0);
    }
    return 0;
}
