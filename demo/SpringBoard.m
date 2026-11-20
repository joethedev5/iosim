/* SpringBoard: the system UI process.
 *
 * This is a real app in the runtime: the boot loader starts it with
 * IOSIM_SHELL set, UIApplicationMain enters the shell, and the home screen
 * enumerates the apps installed on the device. Tapping an icon spawns that
 * app through the loader; the app runs its own scene lifecycle and renders
 * the shared framebuffer, and the home gesture returns here.
 */
#import "UIKitStub.h"

int main(int argc, char **argv)
{
    @autoreleasepool
    {
        return UIApplicationMain(argc, argv, nil, nil);
    }
}
