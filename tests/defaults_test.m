/* NSUserDefaults persistence fixture: writes a domain to disk in one process
 * and reads it back in another. Built like the Foundation IO fixture. */
#include "foundation_lite.h"

extern int printf(const char *fmt, ...);

int main(int argc, char **argv)
{
    NSString *mode = argc > 1 ? [NSString stringWithUTF8String:argv[1]]
                              : [NSString stringWithUTF8String:"read"];
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

    if ([mode isEqualToString:@"write"])
    {
        [defaults setObject:[NSString stringWithUTF8String:"dark"]
                     forKey:[NSString stringWithUTF8String:"theme"]];
        [defaults setObject:[NSNumber numberWithBool:YES]
                     forKey:[NSString stringWithUTF8String:"seen"]];
        [defaults setObject:[NSNumber numberWithInteger:42]
                     forKey:[NSString stringWithUTF8String:"launchCount"]];
        [defaults setObject:[NSArray arrayWithObjects:(const id[]){
                         [NSString stringWithUTF8String:"a"],
                         [NSString stringWithUTF8String:"b"]} count:2]
                     forKey:[NSString stringWithUTF8String:"recent"]];
        [defaults setObject:[NSData dataWithBytes:"abcd" length:4]
                     forKey:[NSString stringWithUTF8String:"blob"]];
        [defaults synchronize];
        printf("defaults: wrote theme=%s seen=%d count=%ld\n",
               [[defaults stringForKey:[NSString stringWithUTF8String:"theme"]]
                   UTF8String],
               (int)[defaults boolForKey:[NSString stringWithUTF8String:"seen"]],
               [defaults integerForKey:[NSString stringWithUTF8String:
                                                   "launchCount"]]);
        return 0;
    }

    NSArray *recent = [defaults objectForKey:[NSString stringWithUTF8String:
                                                          "recent"]];
    NSData *blob = [defaults objectForKey:[NSString stringWithUTF8String:
                                                        "blob"]];
    printf("defaults: theme=%s seen=%d count=%ld recent=%lu blob=%lu\n",
           [[defaults stringForKey:[NSString stringWithUTF8String:"theme"]]
               UTF8String],
           (int)[defaults boolForKey:[NSString stringWithUTF8String:"seen"]],
           [defaults integerForKey:[NSString stringWithUTF8String:"launchCount"]],
           recent ? [recent count] : 0,
           blob ? [blob length] : 0);
    return 0;
}
