/* NSKeyedArchiver/NSKeyedUnarchiver fixture: one process archives an object
 * graph that includes a custom NSCoding class, a second process reads it
 * back through the keyed-archive plist. */
#include "foundation_lite.h"

extern int printf(const char *fmt, ...);
extern char *getenv(const char *name);
extern int snprintf(char *buf, unsigned long size, const char *fmt, ...);
extern const char *class_getName(void *cls);

@interface Profile : NSObject <NSCoding> {
    id _name;
    long _age;
    double _score;
    id _tags;
}
- (id)initWithName:(id)name
               age:(long)age
             score:(double)score
              tags:(id)tags;
- (id)name;
- (long)age;
- (double)score;
- (id)tags;
@end

@implementation Profile
- (id)initWithName:(id)name
               age:(long)age
             score:(double)score
              tags:(id)tags
{
    self = [super init];
    if (self)
    {
        _name = [name retain];
        _age = age;
        _score = score;
        _tags = [tags retain];
    }
    return self;
}
- (id)name { return _name; }
- (long)age { return _age; }
- (double)score { return _score; }
- (id)tags { return _tags; }
- (void)encodeWithCoder:(NSCoder *)coder
{
    [coder encodeObject:_name forKey:@"name"];
    [coder encodeInteger:_age forKey:@"age"];
    [coder encodeDouble:_score forKey:@"score"];
    [coder encodeObject:_tags forKey:@"tags"];
}
- (id)initWithCoder:(NSCoder *)coder
{
    self = [super init];
    if (self)
    {
        _name = [[coder decodeObjectForKey:@"name"] retain];
        _age = [coder decodeIntegerForKey:@"age"];
        _score = [coder decodeDoubleForKey:@"score"];
        _tags = [[coder decodeObjectForKey:@"tags"] retain];
    }
    return self;
}
@end

static void report(const char *phase, id root)
{
    id profile = [root objectForKey:@"profile"];
    id items = [root objectForKey:@"items"];
    id enabled = [root objectForKey:@"enabled"];
    id blob = [root objectForKey:@"blob"];
    id when = [root objectForKey:@"when"];
    printf("keyed: %s name=%s age=%ld score=%.1f tags=%lu items=%lu "
           "enabled=%d blob=%lu when=%.0f class=%s\n",
           phase, iosim_string_cstr([profile name]), [profile age],
           [profile score], (unsigned long)[[profile tags] count],
           (unsigned long)[items count], (int)[enabled boolValue],
           (unsigned long)[blob length],
           [(NSDate *)when timeIntervalSince1970],
           class_getName((void *)[profile class]));
}

int main(int argc, char **argv)
{
    const char *mode = argc > 1 ? argv[1] : "read";
    const char *home = getenv("HOME");
    if (!home)
        home = ".";
    char path[1024];
    snprintf(path, sizeof(path), "%s/keyed-archive.plist", home);

    if (mode[0] == 'w')
    {
        id tags = [NSArray arrayWithObjects:@"math", @"code", nil];
        Profile *profile = [[Profile alloc] initWithName:@"Ada"
                                                    age:36
                                                  score:97.5
                                                   tags:tags];
        NSMutableDictionary *root = [NSMutableDictionary dictionary];
        [root setObject:profile forKey:@"profile"];
        [root setObject:[NSArray arrayWithObjects:@"one", @"two", nil]
                 forKey:@"items"];
        [root setObject:[NSNumber numberWithBool:YES] forKey:@"enabled"];
        [root setObject:[NSData dataWithBytes:"abcd" length:4]
                 forKey:@"blob"];
        [root setObject:[NSDate dateWithTimeIntervalSince1970:1700000000]
                 forKey:@"when"];

        if (![NSKeyedArchiver archiveRootObject:root toFile:
                    [NSString stringWithUTF8String:path]])
        {
            printf("keyed: write failed\n");
            return 1;
        }
        NSData *data = [NSData dataWithContentsOfFile:
            [NSString stringWithUTF8String:path]];
        printf("keyed: wrote %lu bytes\n", (unsigned long)[data length]);
        report("round", [NSKeyedUnarchiver unarchiveObjectWithData:data]);
        return 0;
    }

    NSData *data = [NSData dataWithContentsOfFile:
        [NSString stringWithUTF8String:path]];
    if (!data)
    {
        printf("keyed: read failed\n");
        return 1;
    }
    id root = [NSKeyedUnarchiver unarchiveObjectWithData:data];
    if (!root)
    {
        printf("keyed: unarchive failed\n");
        return 1;
    }
    report("read", root);
    return 0;
}
