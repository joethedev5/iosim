#ifndef IOSIM_OBJC_RUNTIME_H
#define IOSIM_OBJC_RUNTIME_H

#include <stdint.h>

struct iosim_image;

void iosim_objc_register_image(struct iosim_image *img);
void iosim_objc_dump(void);

void *objc_lookup_imp(void *obj, void *sel);
void *objc_msgSend(void *self, void *sel, ...);
void *objc_alloc_init(void *cls);
void *objc_alloc(void *cls);
void *objc_autoreleasePoolPush(void);
void  objc_autoreleasePoolPop(void *pool);
void *objc_retain(void *obj);
void  objc_release(void *obj);
void *objc_getClass(const char *name);
const char *class_getName(void *cls);
const char *object_getClassName(void *obj);
void *sel_registerName(const char *name);
const char *sel_getName(void *sel);

extern char _objc_empty_cache[32];

#endif
