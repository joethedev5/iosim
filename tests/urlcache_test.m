/* NSURLCache and NSURLSession: a second GET is served from the shared
 * cache, removing responses forces a new network fetch, and a reload
 * cache policy bypasses a stored response. */
#include "foundation_lite.h"

extern int printf(const char *fmt, ...);
extern int fflush(void *stream);
extern int usleep(unsigned int usec);

static volatile int g_done;

static void run_request(NSURLRequest *request, const char *label)
{
    g_done = 0;
    NSURLSessionDataTask *task =
        [[NSURLSession sharedSession] dataTaskWithRequest:request
                              completionHandler:^(NSData *data,
                                                  NSURLResponse *response,
                                                  NSError *error) {
        printf("[cache] %s %ld %.*s\n", label, [response statusCode],
               data ? (int)[data length] : 0,
               data ? (const char *)[data bytes] : "");
        if (error)
            printf("[cache] %s error %ld\n", label, [error code]);
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

    NSString *address = [NSString stringWithFormat:
                            @"http://127.0.0.1:%d/count", port];
    NSURL *url = [NSURL URLWithString:address];
    NSURLCache *cache = [NSURLCache sharedURLCache];
    [cache removeAllCachedResponses];
    printf("[cache] capacity %lu\n", [cache memoryCapacity]);

    NSURLRequest *first = [NSURLRequest requestWithURL:url];
    run_request(first, "first");
    NSURLRequest *second = [NSURLRequest requestWithURL:url];
    run_request(second, "second");

    [cache removeAllCachedResponses];
    NSURLRequest *third = [NSURLRequest requestWithURL:url];
    run_request(third, "third");

    NSMutableURLRequest *reload = [NSMutableURLRequest requestWithURL:url];
    [reload setCachePolicy:NSURLRequestReloadIgnoringLocalCacheData];
    run_request(reload, "reload");

    NSHTTPURLResponse *manualResponse = [[NSHTTPURLResponse alloc]
        initWithURL:url
         statusCode:200
            headers:[NSDictionary dictionaryWithObject:@"1" forKey:@"X"]];
    NSData *manualData = [NSData dataWithBytes:"manual" length:6];
    NSCachedURLResponse *manual = [[NSCachedURLResponse alloc]
        initWithResponse:manualResponse
                    data:manualData];
    NSURLRequest *manualRequest = [NSURLRequest requestWithURL:url];
    [cache storeCachedResponse:manual forRequest:manualRequest];
    NSCachedURLResponse *readBack =
        [cache cachedResponseForRequest:manualRequest];
    id readData = readBack ? [readBack data] : nil;
    printf("[cache] manual %d %.*s\n", readBack != nil && readData != nil,
           readData ? (int)[readData length] : 0,
           readData ? (const char *)[readData bytes] : "");
    printf("[cache] done\n");
    fflush(0);
    return 0;
}
