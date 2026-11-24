/* NSAttributedString attribute runs: ranged adds, run splitting, effective
 * ranges, replacement, appending and immutable copies. */
#include "UIKitStub.h"

extern int printf(const char *fmt, ...);
extern int fflush(void *stream);

int main(void)
{
    NSMutableAttributedString *text = [[NSMutableAttributedString alloc]
        initWithString:@"HelloWorld"];
    id red = [UIColor redColor];
    id blue = [UIColor blueColor];
    id green = [UIColor greenColor];
    UIFont *font = [UIFont boldSystemFontOfSize:20];
    [text addAttribute:NSForegroundColorAttributeName value:red
                  range:NSMakeRange(0, 5)];
    [text addAttribute:NSForegroundColorAttributeName value:blue
                  range:NSMakeRange(5, 5)];
    NSRange range;
    id attrs = [text attributesAtIndex:1 effectiveRange:&range];
    printf("[arun] first %lu %lu %d\n", range.location, range.length,
           [attrs objectForKey:NSForegroundColorAttributeName] == red);
    attrs = [text attributesAtIndex:7 effectiveRange:&range];
    printf("[arun] second %lu %lu %d\n", range.location, range.length,
           [attrs objectForKey:NSForegroundColorAttributeName] == blue);

    [text addAttributes:[NSDictionary dictionaryWithObjectsAndKeys:
                             font, NSFontAttributeName, nil]
                   range:NSMakeRange(2, 4)];
    attrs = [text attributesAtIndex:1 effectiveRange:&range];
    printf("[arun] split1 %lu %lu %d\n", range.location, range.length,
           [attrs objectForKey:NSForegroundColorAttributeName] == red &&
           [attrs objectForKey:NSFontAttributeName] == nil);
    attrs = [text attributesAtIndex:3 effectiveRange:&range];
    printf("[arun] split2 %lu %lu %d\n", range.location, range.length,
           [attrs objectForKey:NSForegroundColorAttributeName] == red &&
           [attrs objectForKey:NSFontAttributeName] == font);
    attrs = [text attributesAtIndex:7 effectiveRange:&range];
    printf("[arun] split3 %lu %lu %d %d\n", range.location, range.length,
           [attrs objectForKey:NSForegroundColorAttributeName] == blue,
           [attrs objectForKey:NSFontAttributeName] == nil);

    [text setAttributes:[NSDictionary dictionaryWithObjectsAndKeys:
                             green, NSForegroundColorAttributeName, nil]
                   range:NSMakeRange(8, 2)];
    attrs = [text attributesAtIndex:9 effectiveRange:&range];
    printf("[arun] replaced %lu %lu %d\n", range.location, range.length,
           [attrs objectForKey:NSForegroundColorAttributeName] == green);

    [text replaceCharactersInRange:NSMakeRange(2, 4) withString:@"XY"];
    printf("[arun] length %lu\n", [text length]);
    printf("[arun] string %s\n", [[text string] UTF8String]);
    attrs = [text attributesAtIndex:1 effectiveRange:&range];
    printf("[arun] edit1 %lu %lu %d\n", range.location, range.length,
           [attrs objectForKey:NSForegroundColorAttributeName] == red);
    attrs = [text attributesAtIndex:2 effectiveRange:&range];
    printf("[arun] edit2 %d %d\n",
           [attrs objectForKey:NSForegroundColorAttributeName] == red,
           [attrs objectForKey:NSFontAttributeName] == font);
    attrs = [text attributesAtIndex:6 effectiveRange:&range];
    printf("[arun] edit3 %d\n",
           [attrs objectForKey:NSForegroundColorAttributeName] == green);

    NSAttributedString *tail = [[NSAttributedString alloc]
        initWithString:@"!!"
          attributes:[NSDictionary dictionaryWithObjectsAndKeys:
                          blue, NSForegroundColorAttributeName, nil]];
    [text appendAttributedString:tail];
    printf("[arun] append %lu %s\n", [text length],
           [[text string] UTF8String]);
    attrs = [text attributesAtIndex:9 effectiveRange:&range];
    printf("[arun] tail %lu %lu %d\n", range.location, range.length,
           [attrs objectForKey:NSForegroundColorAttributeName] == blue);

    NSAttributedString *copy = [[NSAttributedString alloc]
        initWithAttributedString:text];
    attrs = [copy attributesAtIndex:4 effectiveRange:&range];
    printf("[arun] copy %lu %lu %d\n", range.location, range.length,
           [attrs objectForKey:NSForegroundColorAttributeName] == blue);
    NSAttributedString *plain = [[NSAttributedString alloc]
        initWithString:@"abc"
          attributes:[NSDictionary dictionaryWithObjectsAndKeys:
                          green, NSForegroundColorAttributeName, nil]];
    NSRange whole;
    attrs = [plain attributesAtIndex:1 effectiveRange:&whole];
    printf("[arun] immutable %lu %lu %d\n", whole.location, whole.length,
           [attrs objectForKey:NSForegroundColorAttributeName] == green);
    printf("[arun] done\n");
    fflush(0);
    return 0;
}
