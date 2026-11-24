/* An arm64 main that builds an NSMutableDictionary, walks its keys with
 * fast enumeration, and appends to an NSMutableString. Returns
 * 6 * 10 + 5 = 65. */
@protocol DictCalls
+ (id)dictionary;
+ (id)stringWithUTF8String:(const char *)s;
+ (id)string;
+ (id)numberWithInt:(int)v;
- (void)setObject:(id)obj forKey:(id)key;
- (id)objectForKey:(id)key;
- (id)allKeys;
- (void)appendString:(id)s;
- (unsigned long)length;
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
    id dictCls = (id)objc_getClass("NSMutableDictionary");
    id strCls = (id)objc_getClass("NSString");
    id msCls = (id)objc_getClass("NSMutableString");
    id numCls = (id)objc_getClass("NSNumber");

    id dict = [(id<DictCalls>)dictCls dictionary];
    const char *keys[3] = {"a", "b", "c"};
    for (int i = 0; i < 3; i++)
        [(id<DictCalls>)dict
            setObject:[(id<DictCalls>)numCls numberWithInt:i + 1]
               forKey:[(id<DictCalls>)strCls
                          stringWithUTF8String:keys[i]]];

    id all = [(id<DictCalls>)dict allKeys];
    EnumState st = {0};
    unsigned long total = 0;
    unsigned long got;
    while ((got = [(id<DictCalls>)all countByEnumeratingWithState:&st
                                                          objects:(id *)0
                                                            count:16]) != 0)
    {
        for (unsigned long i = 0; i < got; i++)
        {
            id key = st.itemsPtr[i];
            id val = [(id<DictCalls>)dict objectForKey:key];
            total += (unsigned long)[(id<DictCalls>)val intValue];
        }
    }

    id ms = [(id<DictCalls>)msCls string];
    [(id<DictCalls>)ms appendString:
        [(id<DictCalls>)strCls stringWithUTF8String:"hel"]];
    [(id<DictCalls>)ms appendString:
        [(id<DictCalls>)strCls stringWithUTF8String:"lo"]];
    unsigned long len = [(id<DictCalls>)ms length];
    printf("total=%lu len=%lu\n", total, len);
    return (int)(total * 10 + len); /* 65 */
}
