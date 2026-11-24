/* URLSession redirect handling: relative and absolute Location headers, a
 * redirect chain, 303 turning a POST into a GET, 307 preserving the POST,
 * and a redirect loop failing with NSURLErrorHTTPTooManyRedirects. */
#include "foundation_lite.h"

extern int printf(const char *fmt, ...);
extern int fflush(void *stream);
extern int usleep(unsigned int usec);

static volatile int g_done;

static void print_result(const char *tag, NSURLResponse *response,
                         NSData *data, NSError *error)
{
    id path = [[response URL] path];
    printf("[redirect] %s %ld %d %d %.*s %s\n", tag,
           [response statusCode], data != nil,
           data ? (int)[data length] : 0,
           data ? (int)[data length] : 0,
           data ? (const char *)[data bytes] : "",
           path ? (const char *)[path UTF8String] : "-");
    if (error)
        printf("[redirect] %s error %ld\n", tag, [error code]);
    g_done = 1;
}

static void run_get(NSString *urlString, const char *tag)
{
    g_done = 0;
    NSURLSessionDataTask *task = [[NSURLSession sharedSession]
        dataTaskWithURL:[NSURL URLWithString:urlString]
      completionHandler:^(NSData *data, NSURLResponse *response,
                          NSError *error) {
        print_result(tag, response, data, error);
    }];
    [task resume];
    for (int i = 0; i < 500 && !g_done; i++)
        usleep(10000);
}

static void run_post(NSString *urlString, const char *tag)
{
    NSMutableURLRequest *request = [NSMutableURLRequest
        requestWithURL:[NSURL URLWithString:urlString]];
    [request setHTTPMethod:@"POST"];
    [request setHTTPBody:[NSData dataWithBytes:"payload" length:7]];
    g_done = 0;
    NSURLSessionDataTask *task = [[NSURLSession sharedSession]
        dataTaskWithRequest:request
          completionHandler:^(NSData *data, NSURLResponse *response,
                              NSError *error) {
        print_result(tag, response, data, error);
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
    NSString *base = [NSString stringWithFormat:@"http://127.0.0.1:%d", port];
    run_get([base stringByAppendingString:@"/start"], "start");
    run_get([base stringByAppendingString:@"/hop"], "chain");
    run_post([base stringByAppendingString:@"/post"], "post");
    run_post([base stringByAppendingString:@"/redirect-307"], "kept");
    run_get([base stringByAppendingString:@"/loop"], "loop");
    printf("[redirect] done\n");
    fflush(0);
    return 0;
}
