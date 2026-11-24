/* NSInputStream and NSOutputStream: memory and file input, memory and file
 * output including append mode, stream status transitions and the memory
 * stream's written-data property. */
#include "foundation_lite.h"

extern int printf(const char *fmt, ...);
extern int fflush(void *stream);
extern char *getenv(const char *name);
extern int snprintf(char *buf, unsigned long size, const char *fmt, ...);

int main(void)
{
    const char *tmp = getenv("TMPDIR");
    if (!tmp || !*tmp)
        tmp = "/tmp";
    char path[256];
    snprintf(path, sizeof(path), "%s/iosim-stream-fixture.txt", tmp);
    NSString *file = [NSString stringWithUTF8String:path];
    unsigned char buf[64];

    NSData *source = [NSData dataWithBytes:"streamed text" length:13];
    NSInputStream *in = [NSInputStream inputStreamWithData:source];
    long initial = [in streamStatus];
    [in open];
    int available = [in hasBytesAvailable];
    long first = [in read:buf maxLength:4];
    buf[first > 0 ? first : 0] = 0;
    printf("[stream] data %ld %d %ld %s", initial, available, first, buf);
    long second = [in read:buf maxLength:32];
    buf[second > 0 ? second : 0] = 0;
    printf(" %ld %s", second, buf);
    long status = [in streamStatus];
    int left = [in hasBytesAvailable];
    long extra = [in read:buf maxLength:1];
    printf(" %ld %d %ld\n", status, left, extra);
    [in close];
    printf("[stream] dataclose %ld\n", [in streamStatus]);

    NSData *fileData = [NSData dataWithBytes:"hello from a file" length:18];
    [fileData writeToFile:file atomically:NO];
    NSInputStream *fileIn = [NSInputStream inputStreamWithFileAtPath:file];
    [fileIn open];
    long fileRead = [fileIn read:buf maxLength:64];
    buf[fileRead > 0 ? fileRead : 0] = 0;
    printf("[stream] file %s\n", buf);
    [fileIn close];

    NSOutputStream *memory = [NSOutputStream outputStreamToMemory];
    [memory open];
    [memory write:(const unsigned char *)"hello " maxLength:6];
    [memory write:(const unsigned char *)"stream" maxLength:6];
    NSData *written =
        [memory propertyForKey:NSStreamDataWrittenToMemoryStreamKey];
    printf("[stream] memory %lu %.*s\n", written ? [written length] : 0,
           written ? (int)[written length] : 0,
           written ? (const char *)[written bytes] : "");
    [memory close];

    NSOutputStream *fileOut =
        [NSOutputStream outputStreamToFileAtPath:file append:NO];
    [fileOut open];
    [fileOut write:(const unsigned char *)"file output" maxLength:11];
    [fileOut close];
    NSData *back = [NSData dataWithContentsOfFile:file];
    printf("[stream] fileout %.*s %d\n",
           back ? (int)[back length] : 0,
           back ? (const char *)[back bytes] : "", back != nil);

    NSOutputStream *append =
        [NSOutputStream outputStreamToFileAtPath:file append:YES];
    [append open];
    [append write:(const unsigned char *)"!" maxLength:1];
    [append close];
    back = [NSData dataWithContentsOfFile:file];
    printf("[stream] append %.*s %d\n",
           back ? (int)[back length] : 0,
           back ? (const char *)[back bytes] : "", back != nil);

    [[NSFileManager defaultManager] removeItemAtPath:file error:0];
    fflush(0);
    return 0;
}
