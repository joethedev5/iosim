/* UITextView selection: setting a range, replacing it with inserted text and
 * deleting a selected range update the text and collapse the selection. */
#include "UIKitStub.h"

extern int printf(const char *fmt, ...);

static void print_text(NSString *text)
{
    printf("%s", text ? [text UTF8String] : "");
}

int main(void)
{
    UITextView *view =
        [[UITextView alloc] initWithFrame:CGRectMake(0, 0, 300, 200)];
    [view setText:@"hello world"];
    NSRange range = [view selectedRange];
    printf("[sel] initial %lu %lu\n", range.location, range.length);

    [view setSelectedRange:NSMakeRange(6, 5)];
    range = [view selectedRange];
    printf("[sel] set %lu %lu\n", range.location, range.length);
    [view insertText:@"there"];
    printf("[sel] replaced ");
    print_text([view text]);
    range = [view selectedRange];
    printf(" %lu %lu\n", range.location, range.length);

    [view setSelectedRange:NSMakeRange(0, 6)];
    [view deleteBackward];
    printf("[sel] deleted ");
    print_text([view text]);
    range = [view selectedRange];
    printf(" %lu %lu\n", range.location, range.length);

    [view setSelectedRange:NSMakeRange(99, 5)];
    range = [view selectedRange];
    printf("[sel] clamped %lu %lu\n", range.location, range.length);
    return 0;
}
