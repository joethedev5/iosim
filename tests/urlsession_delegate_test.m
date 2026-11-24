/* URLSession delegate callbacks: a data task and a download task report
 * received data, download progress, the finished temp file and completion
 * to a session delegate instead of completion handlers. */
#include "foundation_lite.h"

extern int printf(const char *fmt, ...);
extern int fflush(void *stream);
extern int usleep(unsigned int usec);

static volatile int g_done;

@interface Delegate : NSObject
@end

@implementation Delegate
- (void)URLSession:(NSURLSession *)session
          dataTask:(NSURLSessionDataTask *)task
    didReceiveData:(NSData *)data
{
    (void)session;
    printf("[delegate] data %lu %lu %.*s\n", [task taskIdentifier],
           [data length], [data length], (const char *)[data bytes]);
    fflush(0);
}
- (void)URLSession:(NSURLSession *)session
      downloadTask:(NSURLSessionDownloadTask *)task
    didWriteData:(long long)bytesWritten
    totalBytesWritten:(long long)totalBytesWritten
    totalBytesExpectedToWrite:(long long)totalBytesExpectedToWrite
{
    (void)session;
    (void)bytesWritten;
    printf("[delegate] progress %lu %lld %lld\n", [task taskIdentifier],
           totalBytesWritten, totalBytesExpectedToWrite);
    fflush(0);
}
- (void)URLSession:(NSURLSession *)session
      downloadTask:(NSURLSessionDownloadTask *)task
    didFinishDownloadingToURL:(NSURL *)location
{
    (void)session;
    NSData *body = [NSData dataWithContentsOfFile:[location path]];
    printf("[delegate] file %lu %d %lu %.*s\n", [task taskIdentifier],
           location != nil, body ? [body length] : 0,
           body ? (int)[body length] : 0,
           body ? (const char *)[body bytes] : "");
    fflush(0);
}
- (void)URLSession:(NSURLSession *)session
               task:(NSURLSessionDataTask *)task
    didCompleteWithError:(NSError *)error
{
    (void)session;
    printf("[delegate] complete %lu %ld\n", [task taskIdentifier],
           error ? [error code] : 0);
    fflush(0);
    g_done++;
}
@end

int main(int argc, char **argv)
{
    if (argc < 2)
        return 2;
    int port = 0;
    const char *p = argv[1];
    while (*p >= '0' && *p <= '9')
        port = port * 10 + (*p++ - '0');
    NSString *base = [NSString stringWithFormat:@"http://127.0.0.1:%d", port];

    NSURLSessionConfiguration *config =
        [NSURLSessionConfiguration defaultSessionConfiguration];
    Delegate *delegate = [[Delegate alloc] init];
    NSURLSession *session =
        [NSURLSession sessionWithConfiguration:config
                                     delegate:delegate
                                delegateQueue:nil];
    NSURL *url = [NSURL URLWithString:[base stringByAppendingString:@"/file"]];
    g_done = 0;
    NSURLSessionDataTask *data =
        [session dataTaskWithURL:url completionHandler:nil];
    [data resume];
    NSURLSessionDownloadTask *download =
        [session downloadTaskWithURL:url completionHandler:nil];
    [download resume];
    for (int i = 0; i < 500 && g_done < 2; i++)
        usleep(10000);
    printf("[delegate] done %d\n", g_done);
    fflush(0);
    return 0;
}
