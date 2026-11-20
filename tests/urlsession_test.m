/* NSURLSession over the loader's host HTTP client. The test harness starts a
 * loopback HTTP server and passes its port as argv[1]. */
#include "foundation_lite.h"

extern int printf(const char *fmt, ...);
extern int usleep(unsigned int usec);

static volatile int finished;

int main(int argc, char **argv)
{
    if (argc < 2)
        return 2;
    int port = 0;
    const char *p = argv[1];
    while (*p >= '0' && *p <= '9')
        port = port * 10 + (*p++ - '0');

    NSString *address = [NSString stringWithFormat:@"http://127.0.0.1:%d/hello.txt",
                                                  port];
    NSURL *url = [NSURL URLWithString:address];
    NSURLSessionDataTask *task =
        [[NSURLSession sharedSession] dataTaskWithURL:url
                              completionHandler:^(NSData *data,
                                                  NSURLResponse *response,
                                                  NSError *error) {
        printf("[http] status %ld\n", [response statusCode]);
        printf("[http] body %.*s", (int)[data length], (const char *)[data bytes]);
        NSDictionary *headers = [response allHeaderFields];
        printf("[http] header %s\n",
               [[headers objectForKey:@"Content-type"] UTF8String]);
        (void)error;
        finished = 1;
    }];
    [task resume];
    for (int i = 0; i < 500 && !finished; i++)
        usleep(10000);
    printf("[http] done %d\n", finished);

    if (argc > 2)
    {
        int tls_port = 0;
        const char *tls_p = argv[2];
        while (*tls_p >= '0' && *tls_p <= '9')
            tls_port = tls_port * 10 + (*tls_p++ - '0');
        finished = 0;
        NSString *tls_address = [NSString stringWithFormat:
            @"https://127.0.0.1:%d/hello.txt", tls_port];
        NSURL *tls_url = [NSURL URLWithString:tls_address];
        NSURLSessionDataTask *tls_task =
            [[NSURLSession sharedSession] dataTaskWithURL:tls_url
                                  completionHandler:^(NSData *data,
                                                      NSURLResponse *response,
                                                      NSError *error) {
            printf("[https] status %ld\n", [response statusCode]);
            printf("[https] body %.*s", (int)[data length],
                   (const char *)[data bytes]);
            if (error)
                printf("[https] error %ld %s\n", [error code],
                       [[error localizedDescription] UTF8String]);
            finished = 1;
        }];
        [tls_task resume];
        for (int i = 0; i < 500 && !finished; i++)
            usleep(10000);
        printf("[https] done %d\n", finished);
    }

    finished = 0;
    NSURL *bad = [NSURL URLWithString:@"ftp://127.0.0.1/secret"];
    NSURLSessionDataTask *badTask =
        [[NSURLSession sharedSession] dataTaskWithURL:bad
                              completionHandler:^(NSData *data,
                                                  NSURLResponse *response,
                                                  NSError *error) {
        (void)data;
        (void)response;
        printf("[http] error %ld\n", [error code]);
        finished = 1;
    }];
    [badTask resume];
    for (int i = 0; i < 500 && !finished; i++)
        usleep(10000);
    printf("[http] done %d\n", finished);
    return 0;
}
