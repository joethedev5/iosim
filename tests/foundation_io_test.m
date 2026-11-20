/* Foundation file-system, URL and JSON fixture. Run through the runtime
 * with DYLD_ROOT_PATH pointing at the built runtime root. */

#include "foundation_lite.h"

extern int printf(const char *fmt, ...);
extern char *getenv(const char *name);

int main(void)
{
    @autoreleasepool
    {
        const char *home = getenv("HOME");
        if (!home || !*home)
            home = "/tmp";
        NSString *root = [NSString stringWithUTF8String:home];
        NSString *dir =
            [root stringByAppendingPathComponent:@"Documents/IOTest"];
        NSFileManager *fm = [NSFileManager defaultManager];
        BOOL created = [fm createDirectoryAtPath:dir
                      withIntermediateDirectories:YES
                                       attributes:nil error:nil];
        printf("mkdir %d\n", created ? 1 : 0);
        BOOL isDir = NO;
        BOOL exists = [fm fileExistsAtPath:dir isDirectory:&isDir];
        printf("dir exists %d isdir %d\n", exists ? 1 : 0, isDir ? 1 : 0);

        NSData *payload = [@"hello file" dataUsingEncoding:4];
        NSString *file = [dir stringByAppendingPathComponent:@"note.txt"];
        printf("write %d\n", [payload writeToFile:file atomically:YES] ? 1 : 0);
        NSData *loaded = [NSData dataWithContentsOfFile:file];
        NSString *text = [[NSString alloc] initWithData:loaded encoding:4];
        printf("read %s\n", [text UTF8String]);

        NSArray *items = [fm contentsOfDirectoryAtPath:dir error:nil];
        printf("items %lu %s\n", [items count],
               [[items objectAtIndex:0] UTF8String]);

        NSString *copy = [dir stringByAppendingPathComponent:@"copy.txt"];
        printf("copy %d\n",
               [fm copyItemAtPath:file toPath:copy error:nil] ? 1 : 0);
        printf("copy exists %d\n", [fm fileExistsAtPath:copy] ? 1 : 0);
        printf("remove %d\n",
               [fm removeItemAtPath:copy error:nil] ? 1 : 0);
        printf("copy gone %d\n", [fm fileExistsAtPath:copy] ? 0 : 1);

        NSURL *url = [NSURL fileURLWithPath:file];
        printf("url %s\n", [[url absoluteString] UTF8String]);
        printf("url path %s\n", [[url path] UTF8String]);
        printf("last %s\n", [[url lastPathComponent] UTF8String]);
        printf("ext %s\n", [[[url path] pathExtension] UTF8String]);
        printf("append %s\n",
               [[[[url URLByAppendingPathComponent:@"extra"] path]
                   lastPathComponent] UTF8String]);

        NSMutableDictionary *object = [NSMutableDictionary dictionary];
        [object setObject:@"Sim" forKey:@"name"];
        [object setObject:[NSNumber numberWithInt:42] forKey:@"count"];
        [object setObject:[NSArray arrayWithObjects:(const id[]){
            [NSNumber numberWithDouble:1.5],
            [NSNumber numberWithBool:YES], [NSNull null]} count:3]
                   forKey:@"list"];
        printf("valid %d\n",
               [NSJSONSerialization isValidJSONObject:object] ? 1 : 0);
        NSData *json = [NSJSONSerialization dataWithJSONObject:object
                                                       options:0 error:nil];
        printf("json %s\n", [[[NSString alloc] initWithData:json
                                                   encoding:4] UTF8String]);
        id back = [NSJSONSerialization JSONObjectWithData:json options:0
                                                    error:nil];
        printf("parsed %s %ld %.1f %d\n",
               [[back objectForKey:@"name"] UTF8String],
               (long)[[back objectForKey:@"count"] integerValue],
               [[[back objectForKey:@"list"] objectAtIndex:0] doubleValue],
               [[[back objectForKey:@"list"] objectAtIndex:1] boolValue] ? 1
                                                                          : 0);
        NSData *bad = [@"{oops" dataUsingEncoding:4];
        printf("invalid %d\n",
               [NSJSONSerialization JSONObjectWithData:bad options:0
                                                 error:nil] ? 0 : 1);
    }
    return 0;
}
