/* An arm64 main that builds an NSMutableArray, walks it with fast
 * enumeration (a native method taking a pointer to a state struct), and
 * invokes an arm64 block directly. Prints "n=4 total=47" and
 * "block=1", then returns 447. */
@protocol ArrCalls
+ (id)array;
+ (id)numberWithInt:(int)v;
- (void)addObject:(id)obj;
- (unsigned long)count;
- (int)intValue;
- (unsigned long)countByEnumeratingWithState:(void *)state
                                     objects:(id *)buf
                                       count:(unsigned long)len;
@end

typedef struct {
    unsigned long state;
    id *itemsPtr;
    unsigned long *mutationsPtr;
    unsigned long extra[5];
} EnumState;

extern void *objc_getClass(const char *name);
extern int printf(const char *fmt, ...);

int main(void)
{
    id arrCls = (id)objc_getClass("NSMutableArray");
    id numCls = (id)objc_getClass("NSNumber");
    id arr = [(id<ArrCalls>)arrCls array];

    for (int i = 0; i < 4; i++)
        [(id<ArrCalls>)arr
            addObject:[(id<ArrCalls>)numCls numberWithInt:i + 10]];

    unsigned long n = [(id<ArrCalls>)arr count];
    EnumState st = {0};
    unsigned long total = 0;
    unsigned long got;
    while ((got = [(id<ArrCalls>)arr countByEnumeratingWithState:&st
                                                         objects:(id *)0
                                                           count:16]) != 0)
    {
        for (unsigned long i = 0; i < got; i++)
            total += [(id<ArrCalls>)st.itemsPtr[i] intValue];
    }

    int (^inc)(int) = ^(int x) { return x + 1; };
    total += (unsigned long)inc(0);
    printf("n=%lu total=%lu\n", n, total);
    return (int)(n * 100 + total); /* 400 + 47 = 447 */
}
