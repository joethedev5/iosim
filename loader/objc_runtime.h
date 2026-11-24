#ifndef IOSIM_OBJC_RUNTIME_H
#define IOSIM_OBJC_RUNTIME_H

#include <stdint.h>

struct iosim_image;

void iosim_objc_register_image(struct iosim_image *img);
void iosim_objc_dump(void);

void *objc_lookup_imp(void *obj, void *sel);
const char *objc_lookup_method_types(void *obj, void *sel);
void *objc_msgSend_lookup(void *obj, void *sel, void **receiver_out,
                          void *frame, void *result_out);

/* Set by the arm64 runtime. When a native x86_64 message send resolves to
 * an arm64 IMP, the hook runs it on the interpreter, writes the scalar
 * result into the trampoline's result buffer and returns nonzero. */
extern int (*iosim_arm64_msg_hook)(void *imp, void *self, void *sel,
                                   void *frame, void *result);
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

/* ARC entry points; retain and release are no-ops, so ownership-preserving
 * calls return their argument and weak slots are plain pointers. */
void *objc_retainAutoreleasedReturnValue(void *obj);
void *objc_autoreleaseReturnValue(void *obj);
void *objc_claimAutoreleasedReturnValue(void *obj);
void *objc_unsafeClaimAutoreleasedReturnValue(void *obj);
void *objc_retainAutorelease(void *obj);
void *objc_retainAutoreleaseReturnValue(void *obj);
void *objc_retainBlock(void *block);
void  objc_storeStrong(void **location, void *obj);
void *objc_storeWeak(void **location, void *obj);
void *objc_loadWeak(void **location);
void *objc_loadWeakRetained(void **location);
void *objc_initWeak(void **location, void *obj);
void  objc_destroyWeak(void **location);
void  objc_moveWeak(void **dest, void **src);
void  objc_copyWeak(void **dest, void **src);
int   objc_opt_isKindOfClass(void *obj, void *cls);
int   objc_opt_respondsToSelector(void *obj, void *sel);
void *objc_opt_self(void *obj);
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
void *class_getClassMethod(void *cls, void *sel);
void *class_replaceMethod(void *cls, void *sel, void *imp, const char *types);
void method_exchangeImplementations(void *first, void *second);
int   class_respondsToSelector(void *cls, void *sel);
void **class_copyMethodList(void *cls, unsigned int *out_count);
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
