/* UIPasteboard fixture: separate processes write and read the system
 * pasteboard through the device's shared resources directory. */
#include "foundation_lite.h"

extern int printf(const char *fmt, ...);
extern int strcmp(const char *a, const char *b);

/* Declared here instead of UIKitStub.h so the file can use the full
 * Foundation-lite collection and data APIs. */
@interface UIPasteboard : NSObject
+ (UIPasteboard *)generalPasteboard;
- (id)string;
- (void)setString:(id)string;
- (BOOL)hasStrings;
- (id)dataForPasteboardType:(id)type;
- (void)setData:(id)data forPasteboardType:(id)type;
- (long)changeCount;
@end

int main(int argc, char **argv)
{
    UIPasteboard *board = [UIPasteboard generalPasteboard];
    const char *mode = argc > 1 ? argv[1] : "read";

    if (strcmp(mode, "write") == 0)
    {
        [board setString:@"hello pasteboard"];
        printf("[paste] wrote %s change=%ld\n",
               [[board string] UTF8String], [board changeCount]);
        return 0;
    }
    if (strcmp(mode, "write-data") == 0)
    {
        [board setData:[NSData dataWithBytes:"\x01\x02\x03" length:3]
      forPasteboardType:@"com.iosim.demo"];
        NSData *data = [board dataForPasteboardType:@"com.iosim.demo"];
        printf("[paste] wrote-data len=%lu change=%ld\n",
               (unsigned long)[data length], [board changeCount]);
        return 0;
    }
    if (strcmp(mode, "read-data") == 0)
    {
        NSData *data = [board dataForPasteboardType:@"com.iosim.demo"];
        const unsigned char *bytes = data ? [data bytes] : 0;
        printf("[paste] data=%lu/%d change=%ld\n",
               (unsigned long)(data ? [data length] : 0),
               bytes ? bytes[0] : -1, [board changeCount]);
        return 0;
    }

    printf("[paste] read=%s change=%ld strings=%d\n",
           iosim_string_cstr([board string]), [board changeCount],
           (int)[board hasStrings]);
    return 0;
}
