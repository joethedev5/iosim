/* NSHTTPCookie and NSHTTPCookieStorage over the loader's HTTP client: a
 * response's Set-Cookie headers are stored and replayed on the next
 * request. The harness passes the loopback cookie server's port. */
#include "foundation_lite.h"

extern int printf(const char *fmt, ...);
extern int fflush(void *stream);
extern int usleep(unsigned int usec);

static volatile int g_done;

static void run_get(NSString *urlString, const char *label)
{
    g_done = 0;
    NSURL *url = [NSURL URLWithString:urlString];
    NSURLSessionDataTask *task =
        [[NSURLSession sharedSession] dataTaskWithURL:url
                              completionHandler:^(NSData *data,
                                                  NSURLResponse *response,
                                                  NSError *error) {
        printf("[cookie] %s %ld\n", label, [response statusCode]);
        if (data)
            printf("[cookie] %s body %.*s\n", label, (int)[data length],
                   (const char *)[data bytes]);
        if (error)
            printf("[cookie] %s error %ld\n", label, [error code]);
        g_done = 1;
    }];
    [task resume];
    for (int i = 0; i < 500 && !g_done; i++)
        usleep(10000);
}

int main(int argc, char **argv)
{
    if (argc < 2)
        return 2;
    int port = 0;
    const char *p = argv[1];
    while (*p >= '0' && *p <= '9')
        port = port * 10 + (*p++ - '0');

    NSHTTPCookieStorage *storage =
        [NSHTTPCookieStorage sharedHTTPCookieStorage];
    NSArray *existing = [storage cookies];
    for (unsigned long i = 0; i < [existing count]; i++)
        [storage deleteCookie:[existing objectAtIndex:i]];

    NSMutableDictionary *properties = [NSMutableDictionary dictionary];
    [properties setObject:@"a" forKey:NSHTTPCookieName];
    [properties setObject:@"1" forKey:NSHTTPCookieValue];
    [properties setObject:@"example.com" forKey:NSHTTPCookieDomain];
    [properties setObject:@"/" forKey:NSHTTPCookiePath];
    NSHTTPCookie *manualCookie =
        [NSHTTPCookie cookieWithProperties:properties];
    printf("[cookie] direct %s %s\n",
           [[manualCookie name] UTF8String],
           [[manualCookie value] UTF8String]);
    NSDictionary *fields = [NSHTTPCookie requestHeaderFieldsWithCookies:
                                [NSArray arrayWithObject:manualCookie]];
    printf("[cookie] header %s\n",
           [[fields objectForKey:@"Cookie"] UTF8String]);

    NSURL *manualURL =
        [NSURL URLWithString:@"http://example.com/path/page"];
    NSDictionary *responseFields = [NSDictionary
        dictionaryWithObjectsAndKeys:@"manual=yes; Path=/", @"Set-Cookie",
                                     nil];
    NSArray *parsed = [NSHTTPCookie cookiesWithResponseHeaderFields:
                           responseFields forURL:manualURL];
    printf("[cookie] manual %lu %s %s\n", [parsed count],
           [[(NSHTTPCookie *)[parsed firstObject] name] UTF8String],
           [[(NSHTTPCookie *)[parsed firstObject] value] UTF8String]);

    NSString *address = [NSString stringWithFormat:
                            @"http://127.0.0.1:%d/set", port];
    run_get(address, "set");
    NSURL *setURL = [NSURL URLWithString:address];
    NSArray *stored = [storage cookiesForURL:setURL];
    printf("[cookie] stored %lu\n", [stored count]);

    NSString *echoAddress = [NSString stringWithFormat:
                                @"http://127.0.0.1:%d/echo", port];
    run_get(echoAddress, "echo");
    printf("[cookie] done\n");
    fflush(0);
    return 0;
}
