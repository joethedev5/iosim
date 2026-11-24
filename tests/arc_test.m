/* ARC-compiled fixture: strong and weak properties, autorelease pools,
 * blocks and autoreleased factory results exercise the runtime's ARC entry
 * points. Objects are never freed, so the weak slot clears only on assign. */
#include "foundation_lite.h"

extern int printf(const char *fmt, ...);
extern int fflush(void *stream);

@interface ArcBox : NSObject {
    NSString *_label;
}
@property(nonatomic, strong) NSString *label;
@property(nonatomic, weak) id weakLink;
- (id)makeTag;
@end

@implementation ArcBox
- (id)makeTag { return [NSString stringWithUTF8String:"tag-arc"]; }
@end

int main(void)
{
    @autoreleasepool
    {
        ArcBox *box = [[ArcBox alloc] init];
        box.label = [NSString stringWithUTF8String:"arc"];
        printf("[arc] strong %s\n", [box.label UTF8String]);

        __weak ArcBox *weakBox = box;
        box.weakLink = box;
        printf("[arc] weak %d %d\n", weakBox == box, box.weakLink == box);

        box.weakLink = nil;
        printf("[arc] weak cleared %d\n", box.weakLink == nil);

        id tag = [box makeTag];
        printf("[arc] tag %s\n", [(NSString *)tag UTF8String]);

        __block int counter = 0;
        void (^bump)(void) = ^{ counter++; };
        bump();
        bump();
        int (^adder)(int) = ^(int x) { return x + counter; };
        printf("[arc] block %d %d\n", counter, adder(40));

        void *raw = (__bridge void *)box;
        ArcBox *back = (__bridge ArcBox *)raw;
        printf("[arc] bridge %d\n", back == box);
    }
    printf("[arc] done\n");
    fflush(0);
    return 0;
}
