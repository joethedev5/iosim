#ifndef IOSIM_OBJC_RUNTIME_H
#define IOSIM_OBJC_RUNTIME_H

#include <stdint.h>

struct iosim_image;

void iosim_objc_register_image(struct iosim_image *img);
void iosim_objc_dump(void);

void *objc_lookup_imp(void *obj, void *sel);
void *objc_msgSend(void *self, void *sel, ...);
void *objc_msgSendSuper2(void *super_ptr, void *sel, ...);
void *objc_msgSend_stret(void *stret_addr, void *self, void *sel, ...);
void *objc_lookup_super_imp(void *super_ptr, void *sel);
void *iosim_objc_alloc(void *cls);
void *iosim_objc_class_of(void *obj);
void *iosim_objc_superclass(void *cls);
int   iosim_objc_is_kind_of(void *obj, void *cls);
int   iosim_objc_responds(void *obj, void *sel);
void *iosim_objc_normalize_class(void *ptr);
void  objc_setProperty_nonatomic(void *self, void *sel, void *value, long offset);
void  objc_setProperty_nonatomic_copy(void *self, void *sel, void *value, long offset);
void  objc_setProperty_atomic(void *self, void *sel, void *value, long offset);
void  objc_setProperty_atomic_copy(void *self, void *sel, void *value, long offset);
void *objc_alloc_init(void *cls);
void *objc_alloc(void *cls);
void *objc_autoreleasePoolPush(void);
void *objc_autorelease(void *obj);
void  objc_autoreleasePoolPop(void *pool);
void *objc_retain(void *obj);
void  objc_release(void *obj);
void *objc_getClass(const char *name);
const char *class_getName(void *cls);
const char *object_getClassName(void *obj);
void *sel_registerName(const char *name);
void *sel_getUid(const char *name);
const char *sel_getName(void *sel);

/* Runtime class creation, used by KVO notifying subclasses. */
void *objc_allocateClassPair(void *superclass, const char *name,
                             unsigned long extraBytes);
void objc_registerClassPair(void *cls);
int   class_addMethod(void *cls, void *sel, void *imp, const char *types);
void *class_getInstanceMethod(void *cls, void *sel);
void *class_getMethodImplementation(void *cls, void *sel);
const char *method_getTypeEncoding(void *method);
void *method_getImplementation(void *method);
void *method_setImplementation(void *method, void *imp);
void *class_getSuperclass(void *cls);
unsigned long class_getInstanceSize(void *cls);
void *object_getClass(void *obj);
void *object_setClass(void *obj, void *cls);

/* Associated objects, stored by the loader for the life of the process. */
void  objc_setAssociatedObject(void *object, const void *key, void *value,
                               unsigned long policy);
void *objc_getAssociatedObject(void *object, const void *key);
void  objc_removeAssociatedObjects(void *object);

extern char _objc_empty_cache[32];

#endif
