/* URLSession upload and download tasks: a loopback server serves a file and
 * echoes an upload body. The download completion receives a temp file URL,
 * the upload completion receives the echoed data. */
#include "foundation_lite.h"

extern int printf(const char *fmt, ...);
extern int fflush(void *stream);
extern int usleep(unsigned int usec);

static volatile int g_done;

int main(int argc, char **argv)
{
    if (argc < 2)
        return 2;
    int port = 0;
    const char *p = argv[1];
    while (*p >= '0' && *p <= '9')
        port = port * 10 + (*p++ - '0');
    NSString *base = [NSString stringWithFormat:@"http://127.0.0.1:%d", port];

    g_done = 0;
    NSURLSessionDownloadTask *download =
        [[NSURLSession sharedSession]
            downloadTaskWithURL:
                [NSURL URLWithString:[base stringByAppendingString:@"/file"]]
             completionHandler:^(NSURL *location, NSURLResponse *response,
                                 NSError *error) {
        NSData *body = location
            ? [NSData dataWithContentsOfFile:[location path]] : nil;
        printf("[tasks] download %ld %d %d %.*s\n", [response statusCode],
               location != nil, body ? (int)[body length] : 0,
               body ? (int)[body length] : 0,
               body ? (const char *)[body bytes] : "");
        if (location)
            [[NSFileManager defaultManager] removeItemAtPath:[location path]
                                                       error:0];
        if (error)
            printf("[tasks] download error %ld\n", [error code]);
        g_done = 1;
    }];
    [download resume];
    for (int i = 0; i < 500 && !g_done; i++)
        usleep(10000);

    NSMutableURLRequest *upload = [NSMutableURLRequest
        requestWithURL:[NSURL URLWithString:
            [base stringByAppendingString:@"/echo"]]];
    [upload setHTTPMethod:@"POST"];
    NSData *payload = [NSData dataWithBytes:"upload payload" length:14];
    g_done = 0;
    NSURLSessionUploadTask *task =
        [[NSURLSession sharedSession] uploadTaskWithRequest:upload
                                                   fromData:payload
                                          completionHandler:
        ^(NSData *data, NSURLResponse *response, NSError *error) {
        printf("[tasks] upload %ld %d %.*s\n", [response statusCode],
               data ? (int)[data length] : 0,
               data ? (int)[data length] : 0,
               data ? (const char *)[data bytes] : "");
        if (error)
            printf("[tasks] upload error %ld\n", [error code]);
        g_done = 1;
    }];
    [task resume];
    for (int i = 0; i < 500 && !g_done; i++)
        usleep(10000);
    printf("[tasks] done\n");
    fflush(0);
    return 0;
}
