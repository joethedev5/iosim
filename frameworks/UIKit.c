/* UIKit-lite: the first reimplemented iOS Simulator framework.
 * Built as an x86_64 Mach-O dylib with the canonical install name, loaded
 * from the iosim runtime root exactly like Apple's UIKit would be. */
extern int printf(const char *fmt, ...);

typedef int (*UIApplicationMainFn)(int, char **, void *, void *);

int UIApplicationMain(int argc, char **argv, void *principalClass,
                      void *delegateClassName)
{
    printf("[UIKit-lite] UIApplicationMain argc=%d principal=%p delegate=%p\n",
           argc, principalClass, delegateClassName);
    printf("[UIKit-lite] no window server attached yet; returning.\n");
    return 0;
}
