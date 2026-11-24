/* NSCache count and cost limits, replacement, removal and the eviction
 * delegate callback. */
#include "foundation_lite.h"

extern int printf(const char *fmt, ...);

@interface CacheWatcher : NSObject {
@public
    int evicted;
}
@end

@implementation CacheWatcher
- (void)cache:(id)cache willEvictObject:(id)obj
{
    (void)cache;
    (void)obj;
    evicted++;
}
@end

int main(void)
{
    NSCache *cache = [[NSCache alloc] init];
    [cache setCountLimit:2];
    [cache setObject:@"a" forKey:@"a"];
    [cache setObject:@"b" forKey:@"b"];
    printf("[cache] two %d %d\n",
           [cache objectForKey:@"a"] != nil,
           [cache objectForKey:@"b"] != nil);

    [cache setObject:@"c" forKey:@"c"];
    printf("[cache] evict %d %d %d\n",
           [cache objectForKey:@"a"] == nil,
           [cache objectForKey:@"b"] != nil,
           [cache objectForKey:@"c"] != nil);

    [cache setObject:@"b2" forKey:@"b"];
    [cache setObject:@"d" forKey:@"d"];
    printf("[cache] refresh %d %d %d\n",
           [cache objectForKey:@"c"] == nil,
           [cache objectForKey:@"b"] != nil,
           [cache objectForKey:@"d"] != nil);

    [cache removeAllObjects];
    printf("[cache] clear %d\n", [cache objectForKey:@"b"] == nil);

    NSCache *cost = [[NSCache alloc] init];
    [cost setTotalCostLimit:5];
    [cost setObject:@"x" forKey:@"x" cost:3];
    [cost setObject:@"y" forKey:@"y" cost:4];
    printf("[cache] cost %d %d\n",
           [cost objectForKey:@"x"] == nil,
           [cost objectForKey:@"y"] != nil);

    [cost setObject:@"z" forKey:@"y" cost:1];
    printf("[cache] replace %d\n",
           [[cost objectForKey:@"y"] isEqual:@"z"]);
    [cost setName:@"costs"];
    printf("[cache] name %s\n", [[cost name] UTF8String]);

    CacheWatcher *watcher = [[CacheWatcher alloc] init];
    [cache setDelegate:watcher];
    [cache setCountLimit:1];
    [cache setObject:@"e" forKey:@"e"];
    [cache setObject:@"f" forKey:@"f"];
    printf("[cache] delegate %d\n", watcher->evicted > 0);
    return 0;
}
