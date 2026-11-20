/* Key-value coding and automatic key-value observing fixture. Exercises
 * getter/setter discovery, scalar boxing, key paths, isa-swizzled KVO
 * subclasses for object and scalar setters, initial notifications and
 * removal. */
#include "foundation_lite.h"

extern int printf(const char *fmt, ...);

@interface Address : NSObject {
    NSString *_street;
}
- (NSString *)street;
- (void)setStreet:(NSString *)value;
@end

@implementation Address
- (NSString *)street { return _street; }
- (void)setStreet:(NSString *)value { _street = value; }
@end

@interface Person : NSObject {
    NSString *_name;
    int _age;
    Address *_address;
}
- (NSString *)name;
- (void)setName:(NSString *)value;
- (int)age;
- (void)setAge:(int)value;
- (Address *)address;
- (void)setAddress:(Address *)value;
@end

@implementation Person
- (NSString *)name { return _name; }
- (void)setName:(NSString *)value { _name = value; }
- (int)age { return _age; }
- (void)setAge:(int)value { _age = value; }
- (Address *)address { return _address; }
- (void)setAddress:(Address *)value { _address = value; }
@end

@interface Recorder : NSObject {
    int _count;
}
- (int)count;
@end

@implementation Recorder
- (int)count { return _count; }
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object
                        change:(NSDictionary *)change context:(void *)context
{
    (void)object;
    (void)context;
    _count++;
    id oldValue = [change objectForKey:NSKeyValueChangeOldKey];
    id newValue = [change objectForKey:NSKeyValueChangeNewKey];
    printf("[kvo] %s old=%s new=%s\n", [keyPath UTF8String],
           oldValue ? [[oldValue description] UTF8String] : "unset",
           newValue ? [[newValue description] UTF8String] : "unset");
}
@end

int main(void)
{
    Person *p = [[Person alloc] init];
    [p setName:@"alice"];
    [p setAge:30];

    printf("[kvc] get %s %d\n",
           [[p valueForKey:@"name"] UTF8String],
           [[p valueForKey:@"age"] intValue]);
    [p setValue:@"bob" forKey:@"name"];
    [p setValue:[NSNumber numberWithInt:41] forKey:@"age"];
    printf("[kvc] set %s %d\n", [[p name] UTF8String], [p age]);

    Address *a = [[Address alloc] init];
    [p setAddress:a];
    [p setValue:@"Main" forKeyPath:@"address.street"];
    printf("[kvc] path %s\n",
           [[p valueForKeyPath:@"address.street"] UTF8String]);

    NSArray *keys = [NSArray arrayWithObjects:@"name", @"age", nil];
    NSDictionary *values = [p dictionaryWithValuesForKeys:keys];
    printf("[kvc] dict %s %s\n",
           [[values objectForKey:@"name"] UTF8String],
           [[[values objectForKey:@"age"] description] UTF8String]);

    Recorder *r = [[Recorder alloc] init];
    [p addObserver:r forKeyPath:@"name"
           options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld
           context:0];
    [p setName:@"carol"];
    [p setValue:@"dave" forKey:@"name"];

    Recorder *initial = [[Recorder alloc] init];
    [p addObserver:initial forKeyPath:@"age"
           options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew
           context:0];
    [p setAge:42];

    printf("[kvo] count %d initial %d\n", [r count], [initial count]);
    [p removeObserver:r forKeyPath:@"name"];
    [p setName:@"erin"];
    printf("[kvo] after-remove count %d name %s\n", [r count],
           [[p name] UTF8String]);
    return 0;
}
