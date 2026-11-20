#ifndef IOSIM_FOUNDATION_LITE_H
#define IOSIM_FOUNDATION_LITE_H

#include "objc_lite.h"

__attribute__((objc_root_class))
@interface NSObject {
    Class isa;
}
+ (id)alloc;
+ (id)new;
+ (Class)class;
- (id)init;
- (void)dealloc;
- (id)retain;
- (void)release;
- (id)autorelease;
- (unsigned long)retainCount;
- (Class)class;
- (Class)superclass;
- (BOOL)isKindOfClass:(Class)cls;
- (BOOL)isMemberOfClass:(Class)cls;
- (BOOL)respondsToSelector:(SEL)sel;
@end

#endif
