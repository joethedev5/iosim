/* NSFileHandle fixture: write, read back, seek, truncate and update one file
 * through a shared descriptor, then confirm the final bytes with NSData. */
#include "foundation_lite.h"

extern int printf(const char *fmt, ...);
extern int fflush(void *stream);
extern char *getenv(const char *name);

int main(void)
{
    const char *home = getenv("HOME");
    NSString *path =
        [NSString stringWithFormat:@"%s/fh.txt", home ? home : "."];

    NSFileHandle *w = [NSFileHandle fileHandleForWritingAtPath:path];
    if (!w)
    {
        printf("[fh] open-write failed\n");
        return 1;
    }
    [w writeData:[NSData dataWithBytes:"hello file handle" length:17]];
    [w seekToFileOffset:0];
    [w closeFile];

    NSFileHandle *r = [NSFileHandle fileHandleForReadingAtPath:path];
    if (!r)
    {
        printf("[fh] open-read failed\n");
        return 1;
    }
    NSData *all = [r readDataToEndOfFile];
    printf("[fh] read %lu\n", (unsigned long)[all length]);
    printf("[fh] text %.*s\n", (int)[all length], (const char *)[all bytes]);
    [r seekToFileOffset:6];
    NSData *mid = [r readDataOfLength:4];
    printf("[fh] mid %.*s\n", (int)[mid length], (const char *)[mid bytes]);
    printf("[fh] offset %lu\n", (unsigned long)[r offsetInFile]);
    printf("[fh] end %lu\n", (unsigned long)[r seekToEndOfFile]);
    [r closeFile];

    NSFileHandle *u = [NSFileHandle fileHandleForUpdatingAtPath:path];
    if (!u)
    {
        printf("[fh] open-update failed\n");
        return 1;
    }
    /* ftruncate needs a writable descriptor, as on Darwin. */
    [u truncateFileAtOffset:10];
    [u synchronizeFile];
    [u seekToEndOfFile];
    [u writeData:[NSData dataWithBytes:"!" length:1]];
    [u closeFile];

    NSData *check = [NSData dataWithContentsOfFile:path];
    printf("[fh] final %.*s\n", (int)[check length],
           (const char *)[check bytes]);
    fflush(0);
    return 0;
}
