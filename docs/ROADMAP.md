# Roadmap

The current tree is a working substrate: loader, dyld fixups, image graph,
Objective-C runtime, device lifecycle and framework substitution. The path to a
usable simulator is ordered by dependency, not by visible payoff.

## Milestone A — Darwin userspace ABI (next)

- `stat`/`fstat`/`lstat`/`fstatat` translation between Darwin and Linux
  `struct stat` (and `dirent`, `statfs`, `rlimit`, `rusage`).
- Darwin pthreads: pointer `pthread_t`, attributes, mutex/cond, `pthread_key_t`,
  thread-local destructors, `pthread_getname_np`.
- `mmap` flags, `madvise`, `msync`, `shm_open`, `kqueue`/`kevent`.
- Mach traps and traps used by libSystem: `mach_msg_trap`, `mach_absolute_time`,
  `mach_vm_*`, `task_*`, `thread_*`, `semaphore_*`, ports and port sets.
- `libdispatch`: queues, `dispatch_once`, `dispatch_sync/async`, timers and
  sources on top of a Linux event loop.
- `os_log`/`os_signpost` proper payload decoding.
- `libxpc` + bootstrap namespace, then a `launchd_sim` that actually manages
  jobs over a Mach/XPC transport. *(Progress: `launchd_sim` owns the bootstrap
  namespace and Mach messages cross guest processes; XPC object transport and
  launchd job management remain.)*

Exit criterion: a Darwin `Foundation` binary linked against our
`libsystem_kernel` and `libdispatch` can create threads, synchronize, read
files with correct struct layouts, and talk over a bootstrap port.

## Milestone B — Objective-C and CoreFoundation

- Categories, protocols, class properties, `+initialize`, `+load`.
- Message forwarding (`forwardInvocation:`, `methodSignatureForSelector:`),
  `NSInvocation`, `NSMethodSignature`.
- `objc_setAssociatedObject`, weak references, ARC entry points (`objc_storeStrong`,
  `objc_autoreleaseReturnValue`, ...), exceptions (`@try/@catch` personality).
- `Blocks`: `_NSConcreteStackBlock`, `Block_copy`/`Block_release`, `__block`.
- CoreFoundation object model, CFString/CFArray/CFDictionary/CFRunLoop,
  toll-free bridging with a Foundation-lite.
- Foundation: NSString, NSArray, NSDictionary, NSNumber, NSURL, NSFileManager,
  NSNotificationCenter, NSRunLoop, NSThread, NSJSONSerialization.

Exit criterion: a command-line Foundation program compiled from the iOS
simulator SDK runs unmodified against the reimplemented stack.

## Milestone C — Graphics and UIKit

- Shared-memory framebuffer (`SimFramebuffer` equivalent) and a host window
  backend (X11/Wayland, optionally SDL) with the device's native scale.
- CoreGraphics software rasterizer for the primitives UIKit needs.
- CoreAnimation transaction/render-server model: layer tree, commit, display
  link, animations.
- UIKit-lite: `UIApplication`, `UIApplicationDelegate`, `UIWindow`,
  `UIView`, `UIViewController`, `UILabel`, `UIButton`, `UIImageView`,
  `UIScreen`, `UIColor`, `UIFont`, autoresizing/constraint layout basics.
- Event loop integrated with `CFRunLoop`; touch/keyboard input from the host
  window mapped to `UIEvent`/`UITouch`.
- `UIApplicationMain` creates the application, loads the main nib/storyboard
  or delegate, runs the loop and exits cleanly.

Exit criterion: a storyboard-free UIKit hello-world app renders and responds to
touch in a host window.

## Milestone D — System services and device model

- Launch services (`LSApplicationWorkspace`), bundle installation and
  container layout matching the captured environment.
- `frontboard`/`backboardd`-style system app coordination, or a simplified
  in-process SpringBoard replacement.
- Status bar/home screen (SpringBoard-lite), app switching.
- Audio (host audio device enumeration, AudioToolbox/CoreAudio subset).
- Location, sensors, clipboard, keyboard, accessibility.
- `simctl` parity: `io screenshot`, `io recordVideo`, `push`, `pbcopy/pbpaste`,
  `openurl`, `status_bar`, `ui`, `privacy`, `spawn` service management,
  `diagnose`.
- Runtime/device-type metadata matching Xcode's, so existing Xcode workflows
  can target iosim.

Exit criterion: Xcode's simulator device list can be driven by iosim, and a
typical UIKit app can be installed, launched, interacted with and terminated
through `iosimctl`.

## Milestone E — Fidelity and scale

- Parse the dyld shared cache (v1 format) so system dylibs do not need to be
  loaded from disk; support closures (`.dyld` closures) and prebuilt loaders.
- Full `dyld_sim` environment surface (`DYLD_PRINT_*`, insert libraries,
  image suffixes, `DYLD_ROOT_PATH` edge cases).
- Code signing/entitlement checks as advisory metadata, with a permissive
  simulator policy mirroring the real simulator's `get-task-allow` behavior.
- Swift runtime support (embedded Swift, Concurrency, Foundation overlays).
- 32-bit? Not required for modern iOS; x86_64 only.
- Optional arm64 user-mode translation branch for running Apple's arm64-only
  runtime images when fidelity matters more than native x86 execution.

## Test strategy

- Golden binaries built by Apple's clang/ld on `xcode-27` runners (kept as
  artifacts, not redistributed) exercised by `tests/run_tests.sh`.
- ABI conformance tests for every translated struct and syscall.
- Differential tests against the real simulator: run the same app on an
  `xcode-27` runner and under iosim, compare stdout/logs and screenshots for
  the same UI.
- Fuzz the Mach-O parser and chained-fixup walker with malformed images.

## Non-goals

- Redistributing Apple runtime binaries or SDK content.
- A cycle-accurate CPU emulator. Native x86_64 execution is the point.
- macOS app compatibility; Darling covers that. iosim uses the same public
  loader/ABI techniques but targets the simulator's iOS userland.
