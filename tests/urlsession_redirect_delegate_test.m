/* URLSession redirect delegate decisions: the delegate allows /start by
 * returning the proposed request and refuses /hop by returning nil, so the
 * completion receives the final body or the 301 response itself. */
#include "foundation_lite.h"

extern int printf(const char *fmt, ...);
extern int fflush(void *stream);
extern int usleep(unsigned int usec);

static volatile int g_done;

@interface RedirectDelegate : NSObject <NSURLSessionTaskDelegate>
@end

@implementation RedirectDelegate
- (void)URLSession:(NSURLSession *)session task:(NSURLSessionDataTask *)task
    willPerformHTTPRedirection:(NSHTTPURLResponse *)response
                    newRequest:(NSURLRequest *)request
             completionHandler:(void (^)(id))completionHandler
{
    (void)session;
    (void)task;
    id fromPath = [[response URL] path];
    id toPath = [[request URL] path];
    printf("[redirect-delegate] ask %ld %s\n", [response statusCode],
           toPath ? (const char *)[toPath UTF8String] : "-");
    if (fromPath && [fromPath isEqual:@"/hop"])
    {
        printf("[redirect-delegate] deny\n");
        completionHandler(nil);
    }
    else
    {
        printf("[redirect-delegate] allow\n");
        completionHandler(request);
    }
    fflush(0);
}
@end

static void run_get(NSURLSession *session, NSString *urlString, const char *tag)
{
    g_done = 0;
    NSURLSessionDataTask *task = [session
        dataTaskWithURL:[NSURL URLWithString:urlString]
      completionHandler:^(NSData *data, NSURLResponse *response,
                          NSError *error) {
        id path = [[response URL] path];
        printf("[redirect-delegate] %s %ld %d %d %.*s %s\n", tag,
               [response statusCode], data != nil,
               data ? (int)[data length] : 0,
               data ? (int)[data length] : 0,
               data ? (const char *)[data bytes] : "",
               path ? (const char *)[path UTF8String] : "-");
        if (error)
            printf("[redirect-delegate] %s error %ld\n", tag, [error code]);
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
    NSString *base = [NSString stringWithFormat:@"http://127.0.0.1:%d", port];
    RedirectDelegate *delegate = [[RedirectDelegate alloc] init];
    NSURLSession *session = [NSURLSession
        sessionWithConfiguration:[NSURLSessionConfiguration
                                     defaultSessionConfiguration]
                        delegate:delegate
                   delegateQueue:nil];
    run_get(session, [base stringByAppendingString:@"/start"], "final");
    run_get(session, [base stringByAppendingString:@"/hop"], "refused");
    printf("[redirect-delegate] done\n");
    fflush(0);
    return 0;
}
