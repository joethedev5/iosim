/* An arm64 main that uses native Foundation through the message bridge:
 * NSString, NSData, NSJSONSerialization, NSDictionary and NSNumber, with
 * double arguments and a double return. Returns 7 + 21 = 28. */
@protocol FndCalls
+ (id)stringWithUTF8String:(const char *)s;
- (id)dataUsingEncoding:(unsigned long)encoding;
+ (id)JSONObjectWithData:(id)data options:(unsigned long)options
                   error:(id *)error;
- (id)objectForKey:(id)key;
+ (id)numberWithDouble:(double)value;
- (double)doubleValue;
@end

extern void *objc_getClass(const char *name);

int main(void)
{
    id strCls = (id)objc_getClass("NSString");
    id jsonCls = (id)objc_getClass("NSJSONSerialization");
    id numCls = (id)objc_getClass("NSNumber");

    id str = [(id<FndCalls>)strCls stringWithUTF8String:"{\"a\": 7}"];
    id data = [(id<FndCalls>)str dataUsingEncoding:4];
    id obj = [(id<FndCalls>)jsonCls JSONObjectWithData:data options:0
                                                error:0];
    id key = [(id<FndCalls>)strCls stringWithUTF8String:"a"];
    id val = [(id<FndCalls>)obj objectForKey:key];
    double d = [(id<FndCalls>)val doubleValue];

    id num = [(id<FndCalls>)numCls numberWithDouble:21.0];
    double d2 = [(id<FndCalls>)num doubleValue];
    return (int)(d + d2);
}
