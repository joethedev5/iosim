#include "foundation_lite.h"

extern int printf(const char *fmt, ...);
extern int fflush(void *stream);

/* Notification fixture: one selector observer and one block observer, both
 * filtered by name and both receiving userInfo. Removing the block token
 * stops its deliveries. */

@interface NotifyWatcher : NSObject
- (void)note:(NSNotification *)notification;
@end

@implementation NotifyWatcher
- (void)note:(NSNotification *)notification
{
    NSDictionary *info = [notification userInfo];
    NSString *value = [info objectForKey:@"k"];
    printf("notify selector %s user=%s\n",
           iosim_string_cstr([notification name]),
           value ? iosim_string_cstr(value) : "(null)");
    fflush(0);
}
@end

int main(void)
{
    @autoreleasepool
    {
        NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
        NotifyWatcher *watcher = [[NotifyWatcher alloc] init];
        [center addObserver:watcher selector:@selector(note:)
                       name:@"TestNote" object:nil];
        id token = [center addObserverForName:@"BlockNote" object:nil
                                        queue:nil
                                   usingBlock:^(NSNotification *notification) {
            NSDictionary *info = [notification userInfo];
            NSString *value = [info objectForKey:@"k"];
            printf("notify block %s user=%s\n",
                   iosim_string_cstr([notification name]),
                   value ? iosim_string_cstr(value) : "(null)");
            fflush(0);
        }];

        NSMutableDictionary *info = [NSMutableDictionary dictionary];
        [info setObject:@"v" forKey:@"k"];
        [center postNotificationName:@"TestNote" object:nil userInfo:info];
        [center postNotificationName:@"BlockNote" object:nil userInfo:info];
        [center removeObserver:token];
        [center postNotificationName:@"BlockNote" object:nil userInfo:info];
        printf("notify done\n");
        fflush(0);
    }
    return 0;
}
