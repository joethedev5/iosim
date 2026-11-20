# Architecture

This document describes (a) the iOS Simulator as observed from public sources
and the Xcode 27.1 runner, and (b) how `iosim` reimplements each layer natively
on x86_64 Linux.

## 1. What the real simulator does

The iOS Simulator is not a CPU emulator. A simulator app is compiled for the
host architecture (`x86_64` on Intel Macs, `arm64` on Apple Silicon) with the
`iphonesimulator` platform, then linked against simulator variants of the iOS
system libraries. Those libraries execute on the host kernel and call Darwin
syscalls directly. The "simulation" is the device model, the root-path
substitution done by a special dynamic linker, and host integration for
graphics, input, audio and services.

The observed stack on macOS 27 / Xcode 27.1:

```
simctl / Xcode
      │  (private framework + XPC)
      ▼
CoreSimulator.framework  ──►  com.apple.CoreSimulator.CoreSimulatorService
      │  device sets, runtime cryptex mounts, device data dirs
      ▼
Simulator.app / SimulatorTrampoline / SimulatorKit
      │  window, HID, framebuffer, Metal/IOSurface, audio
      ▼
launchd_sim  (in the runtime root)
      │  bootstraps the simulated userland, sets DYLD_ROOT_PATH
      ▼
dyld_sim  ──►  app Mach-O + simulator iOS frameworks
      │         (SpringBoard, backboardd, Foundation, UIKit, ...)
      ▼
Darwin syscalls on the host kernel
```

### Runtime bundle layout

A runtime is a `.simruntime` bundle. Its `Contents/Resources/RuntimeRoot` is a
root filesystem image of the simulated OS:

```
RuntimeRoot/
  usr/lib/dyld_sim
  sbin/launchd_sim
  bin/, sbin/, usr/bin/, usr/sbin/
  System/Library/Frameworks/{Foundation,UIKit,...}.framework
  System/Library/PrivateFrameworks/...
  System/Library/CoreServices/SpringBoard.app
  usr/libexec/backboardd
  System/Library/Caches/com.apple.dyld/dyld_sim_shared_cache_<arch>(.01)
  System/Library/LaunchDaemons/*.plist       (329 daemons on iOS 27.2)
```

On the Xcode 27 runner, the iOS runtimes are cryptex mounts, e.g.:

```
/private/var/run/com.apple.security.cryptexd/mnt/
  com.apple.iPhoneOS.SimulatorRuntime-v24.2.91016.19.NHyATx/
  Library/Developer/CoreSimulator/Profiles/Runtimes/iOS 27.2.simruntime
```

### dyld_sim

`dyld_sim` is a variant of dyld built for the simulator. The captured strings
and environment show its contract:

- `DYLD_ROOT_PATH` redirects absolute install names such as
  `/System/Library/Frameworks/UIKit.framework/UIKit` into the runtime root.
- `DYLD_FALLBACK_FRAMEWORK_PATH` and `DYLD_FALLBACK_LIBRARY_PATH` point at the
  runtime root's frameworks and `usr/lib`.
- `DYLD_SHARED_CACHE_DIR` selects the per-runtime simulator shared cache.
- `DYLD_INSERT_LIBRARIES`, `DYLD_PRINT_*`, `DYLD_IMAGE_SUFFIX` and the usual
  dyld debugging knobs are present.
- The process platform is `PLATFORM_IOSSIMULATOR` (Mach-O `platform 7`).

### Boot and launch

`simctl boot` starts `launchd_sim`, which sets up the simulated launchd domain
and spawns the system daemons (`logd`, `diagnosticd`, `containermanagerd`,
`deviceconfigurationd`, `notifyd`, `cfprefsd`, `backboardd`, `SpringBoard`).
`simctl launch` asks CoreSimulator/launchd to start the app inside that
domain. The application receives a large environment (captured verbatim in
[`RECON-XCODE27.md`](RECON-XCODE27.md)), including:

```
SIMULATOR_UDID, SIMULATOR_DEVICE_NAME, SIMULATOR_MODEL_IDENTIFIER=iPhone19,2
SIMULATOR_RUNTIME_VERSION=27.0, SIMULATOR_RUNTIME_BUILD_VERSION=24A434
SIMULATOR_ROOT, IPHONE_SIMULATOR_ROOT, DYLD_ROOT_PATH=<RuntimeRoot>
SIMULATOR_SHARED_RESOURCES_DIRECTORY, IPHONE_SHARED_RESOURCES_DIRECTORY
SIMULATOR_MAINSCREEN_WIDTH=1206, HEIGHT=2622, SCALE=3.0, PITCH=460.0
SIMULATOR_ARCHS=arm64, SIMULATOR_VERSION_INFO=CoreSimulator 1207 - ...
DYLD_FALLBACK_FRAMEWORK_PATH=<RuntimeRoot>/System/Library/Frameworks
DYLD_FALLBACK_LIBRARY_PATH=<RuntimeRoot>/usr/lib
HOME, TMPDIR, CFFIXED_USER_HOME=<device>/data/Containers/Data/Application/<uuid>
XPC_SERVICE_NAME=UIKitApplication:<bundle-id>[rb-legacy]
HOME/TMPDIR point into the app's data container
```

### The arm64-only wall

Every iOS 27 runtime on the Xcode 27 runner reports
`supportedArchitectures: ["arm64"]`. `dyld_sim`, `launchd_sim`, `SpringBoard`,
`backboardd` and the shared cache (`dyld_sim_shared_cache_arm64`) are arm64
only. The SDK still *compiles and links* x86_64 simulator binaries (verified
with Apple clang 27.1), but there is no x86_64 system runtime to load them
against.

That fact is the central design constraint: **an x86_64 reimplementation cannot
reuse Apple's modern runtime binaries.** It must provide its own dynamic
linker, system libraries and frameworks. That is exactly what iosim does.

## 2. The iosim implementation

```
iosimctl (device sets, bundles, env)      iosim-launchd (boot anchor)
        │
        ▼
iosim-run (native x86_64 ELF)
  ├── Mach-O loader ................ loader/macho.c
  ├── chained/classic fixups ....... loader/fixups.c
  ├── image graph + dylib search ... loader/context.c
  ├── Objective-C runtime .......... loader/objc_runtime.c
  ├── Darwin ABI shims ............. loader/shims.c
  └── entry trampolines ............ loader/start.S
        │
        ▼
runtime/  reimplemented framework dylibs at canonical install names
  System/Library/Frameworks/UIKit.framework/UIKit
  System/Library/Frameworks/Foundation.framework/Foundation
  System/Library/Frameworks/CoreFoundation.framework/CoreFoundation
  usr/lib/libSystem.B.dylib, usr/lib/libobjc.A.dylib
```

### 2.1 Mach-O loading

- Thin and fat Mach-O; the x86_64 slice is selected from fat containers.
- `LC_SEGMENT_64` segments are mapped with `MAP_FIXED_NOREPLACE` at their
  preferred `vmaddr`, with an increasing slide fallback if the address range is
  occupied. `__PAGEZERO` stays unmapped as a guard.
- The executable normally maps at `0x100000000`. Dylibs start at `0` and get a
  slide (e.g. `0x1000000000`) chosen by the same fallback.
- File-backed bytes are copied into the mapping; `vmsize > filesize` is
  zero-filled by the anonymous mapping.
- After fixups, segments are re-protected from `initprot` (`r-x`, `r--`, `rw-`).

### 2.2 Fixups

**Chained fixups** (`LC_DYLD_CHAINED_FIXUPS`) are parsed directly from the
Apple format:

- `dyld_chained_starts_in_image` gives per-segment
  `dyld_chained_starts_in_segment` records. Chain addresses are
  `mach_header + segment_offset + page * page_size + page_start`; page starts
  with `0x8000` index the multi-start pool.
- `DYLD_CHAINED_PTR_64` (format 2): rebase target is an unslid vmaddr;
  `runtime = target + slide`, with `high8` replacing the top byte after the
  slide is added.
- `DYLD_CHAINED_PTR_64_OFFSET` (format 6): target is a vm offset;
  `runtime = preferred_base + slide + target`.
- Bind entries carry a 24-bit import ordinal and an 8-bit embedded addend.
  The final value is `resolve(import) + import.addend + embedded_addend`.
- Next-entry stride is `next * 4` for both 64-bit formats.
- Imports table formats 1 (`IMPORT`), 2 (`IMPORT_ADDEND`) and 3
  (`IMPORT_ADDEND64`) are supported; lib ordinals `-1..-3` and positive
  ordinals are honored.

**Classic fixups** (`LC_DYLD_INFO[_ONLY]`) implement the full rebase and bind
opcode sets (`SET_*`, `ADD_ADDR_*`, `DO_BIND*`, `DO_REBASE*`), including lazy
bind streams processed eagerly. Threaded binds are accepted as a no-op for
x86_64 images.

Import resolution order is: the dylib named by the ordinal, the image itself,
every other loaded image, the built-in Darwin shim table, then `dlsym` in the
Linux process. Unresolved non-weak imports get a generated trampoline that
reports the missing symbol name instead of crashing anonymously.

### 2.3 Entry

`LC_MAIN` gives a file offset relative to `__TEXT`; it is converted to an
unslid vmaddr, then a runtime address. Two entry conventions exist:

- Apple's `crt1.o` `start` routine reads `argc/argv/envp/apple` from the initial
  process stack. iosim builds that Darwin stack layout
  (`argc, argv[], NULL, envp[], NULL, apple[], NULL`), aligns it, sets argument
  registers too, and jumps.
- Binaries linked directly with `-e _main` (common for minimal tests) expect
  the SysV register convention. iosim detects an entry symbol named `_main`
  and calls it directly.

`argc`, `argv`, `environ`, the executable path and the `apple` vector are also
published to `_NSGetArgc`, `_NSGetArgv`, `_NSGetEnviron`,
`_NSGetExecutablePath` and `getprogname`.

### 2.4 Multi-image loading

`loader/context.c` implements a miniature dyld image graph:

- `LC_LOAD_DYLIB`, `LC_LOAD_WEAK_DYLIB`, `LC_REEXPORT_DYLIB`,
  `LC_LAZY_LOAD_DYLIB` and `LC_LOAD_UPWARD_DYLIB` are collected.
- Install names are resolved with `@loader_path`, `@executable_path`, `@rpath`,
  `DYLD_ROOT_PATH` (the simulator root substitution), absolute paths, the
  loading image's directory, the main executable's directory, and the
  `--dylib-path`/`IOSIM_DYLIB_PATH` search list.
- Each image is loaded once (cycles terminate), and each gets its own slide.
- Symbols are looked up in the target dylib first, then flat across all images,
  then shims/glibc.

### 2.5 Objective-C runtime

The runtime is sized to the modern non-fragile ABI emitted by Apple clang:

```
objc_class { isa, superclass, cache[2], bits }              // 40 bytes
class_ro_t { flags, instanceStart, instanceSize, reserved,
             ivarLayout, name, baseMethods, baseProtocols,
             ivars, weakIvarLayout, baseProperties }
method_list_t { entsizeAndFlags, count, method_t[] }
method_t { name, types, imp }
ivar_list_t { entsize, count, ivar_t[] }
ivar_t { offset_ptr, name, type, alignment, size }
```

- `__objc_classlist` entries are read after fixups; class names come from
  `class_ro_t::name`.
- Method dispatch compares the selector name string: Darwin `SEL` values are
  pointers to their name.
- Ivar offsets are *realized at load time* exactly like objc4's `moveIvars`:
  a root class starts at `sizeof(void *)`, each ivar is aligned per its
  alignment, its offset is written through the `OBJC_IVAR_$...` variable, and
  the instance size is rounded up. Clang emits those offset variables as zero,
  so skipping this step corrupts the first ivar write (it lands on the isa).
- `objc_msgSend` is an assembly trampoline that preserves all integer and SSE
  argument registers, asks the C runtime for the IMP, restores the arguments,
  and tail-jumps — preserving the caller's return address and Darwin's
  message-send ABI. Messaging `nil` is a no-op returning zero, exactly as in
  objc4: the lookup reports a null IMP and the trampoline returns with
  zeroed `rax`, `xmm0` and `xmm1` instead of jumping. Responder-chain
  forwarding and optional-delegate calls therefore terminate cleanly.
- `objc_alloc_init`, `objc_autoreleasePoolPush/Pop`, `objc_retain/release`,
  `objc_getClass`, `class_getName`, `object_getClassName`, `sel_registerName`
  and `sel_getName` are implemented.

### 2.6 Darwin ABI shims

The x86_64 SysV calling convention is identical on Darwin and Linux, which is
what makes native execution possible. The remaining differences are data
symbols and structure layouts. Implemented so far:

- stdio globals: `__stdoutp`, `__stderrp`, `__stdinp` map to the address of
  glibc's `stdout`/`stderr`/`stdin` variables.
- `__error` → glibc `errno`, `_NSGet*`, `getprogname`/`setprogname`.
- malloc zones (`malloc_default_zone`, `malloc_zone_*`, `malloc_size`).
- `mach_absolute_time`/`mach_timebase_info` (nanoseconds, 1/1 timebase).
- `os_log` family, `os_retain`/`os_release`.
- `sysctlbyname` for memory/CPU/version keys.
- `NSLog` with constant `CFString` decoding, `UIApplicationMain` fallback,
  the `__CFConstantStringClassReference` data symbol.
- Constant `CFString` receivers: the runtime recognises their flags word
  (`0x7c8` for ASCII, `0x7d0` for UTF-16) and routes method lookup and
  `isKindOfClass:` through `NSString`, so `[@"literal" length]` and friends
  behave like real constant strings without rewriting their read-only isa.
- Flag-free file-system helpers (`iosim_fs_*`) wrap `fopen`, `stat`, `mkdir`,
  `rename` and `readdir` on the host, so guest dylibs never pass Darwin
  `open(2)` flags or Darwin `struct stat` layouts to glibc.
- Missing symbols are bound to per-symbol stubs that print the symbol name.

The next ABI work items are general `struct stat` translation, Darwin pthread
semantics (Darwin `pthread_t` is a pointer), kqueue, Mach traps and `dispatch`.

### 2.7 Framework substitution

This is the key architectural equivalence with `dyld_sim`:

1. An app binary records an install name such as
   `/System/Library/Frameworks/UIKit.framework/UIKit`.
2. `iosim-run` sees `DYLD_ROOT_PATH=<runtime root>` and looks for
   `<root>/System/Library/Frameworks/UIKit.framework/UIKit`.
3. That file is a Mach-O dylib *we* built, with the same install name and
   exported symbols.
4. Its code is mapped, relocated and called exactly like Apple's would be.

`frameworks/UIKit.c` and `frameworks/Foundation.c` are the first
reimplementations. A genuine Apple-SDK-built x86_64 UIKit app now runs through
this path and calls our `UIApplicationMain`; a Foundation app calls our
`NSLog`. This proves the framework-replacement model end to end; filling in
the frameworks is now an application-library effort rather than a loader
effort.

The Foundation library builds on that substrate: `NSFileManager` creates,
lists, copies, moves and removes items through the flag-free host helpers;
`NSData` reads and writes files; `NSURL` carries file paths and path
components; and `NSJSONSerialization` is a dependency-free recursive
serializer and parser over `NSDictionary`, `NSArray`, `NSString`, `NSNumber`
and `NSNull`. Compact output is deterministic (dictionary insertion order on
this runtime) and the parser rejects truncated or malformed input.

### 2.8 Device lifecycle

`tools/iosimctl` mirrors the public `simctl` surface for the features that
exist: `list`, `create`, `delete`, `boot`, `bootstatus`, `shutdown`, `erase`,
`install`, `uninstall`, `launch`, `spawn`, `getenv`, `setenv`,
`get_app_container`, `listapps`.

- Device state lives in a JSON device set under `IOSIM_HOME`.
- `boot` starts `tools/iosim-launchd`, a small `launchd_sim` stand-in that owns
  the device runtime socket/state and exits on `shutdown`. It then boots the
  system UI: `runtime/System/Library/CoreServices/SpringBoard.app/SpringBoard`
  runs through the loader with the device environment, `IOSIM_SHELL=1`, the
  event FIFO and a generated app manifest. SpringBoard renders the home screen
  into the device framebuffer; `io screenshot` waits for that frame. On
  shutdown launchd terminates the SpringBoard process group.
- `install` copies an `.app` into the device bundle container, records its
  `Info.plist` metadata and install order, rewrites the SpringBoard manifest,
  and sends an `apps` event so a running home screen reloads. `uninstall`
  does the same in reverse.
- `launch` runs the app through `iosim-run` with the captured simulator
  environment, a per-app data container (`HOME`, `TMPDIR`,
  `CFFIXED_USER_HOME`, `_DYLD_CLOSURE_HOME`), `DYLD_ROOT_PATH`, screen geometry,
  model identifier and `XPC_SERVICE_NAME=UIKitApplication:...`.
- `SIMCTL_CHILD_*` variables are forwarded to the child, matching simctl.
- `ui <device> tap x y | down x y | move x y | up x y | swipe x0 y0 x1 y1
  [seconds] | home | apps` injects system UI events into the device event
  FIFO, in point coordinates scaled to pixels. `swipe` emits a down, an
  interpolated run of moves and an up. The frontmost process reads the stream:
  at home SpringBoard hit-tests icons, while an app receives touches, keys and
  the `home` background request. `UIApplicationMain` opens the stream before
  its first frame so events sent during scene construction are queued rather
  than lost. The stream stays open across writer gaps: a FIFO with no current
  writer (between two `ui` commands) is idle, not closed, and only the explicit
  `quit` record ends a reader loop.
- `home` is a real suspension: the app runs `sceneWillResignActive:` and
  `sceneDidEnterBackground:`, closes the event stream and stops itself with
  SIGSTOP. SpringBoard's `waitpid(WUNTRACED)` sees the stop, records the PID
  on the app's icon and repaints the home screen. Tapping that icon closes
  SpringBoard's reader, sends SIGCONT and waits again; the same process
  reopens the stream, runs `sceneWillEnterForeground:`/`sceneDidBecomeActive:`
  and continues from its in-memory state. `shutdown` sends SIGCONT before
  SIGTERM so stopped children terminate with the process group.
- When an app stops, SpringBoard copies the device framebuffer into
  `var/run/switcher/<bundle>.png`; that is the app's real last frame, not a
  generated thumbnail. A swipe up from the bottom edge of the home screen
  (or `ui switcher`) opens the switcher: the wallpaper dims and the suspended
  apps appear as snapshot cards with their names. Tapping a card resumes that
  process through the same SIGCONT path; a downward swipe closes the switcher.
  Cards for off-screen apps are not drawn; a horizontal swipe moves the focus
  between up to three visible cards.
- An app can ask for the switcher itself. A bottom-edge swipe inside the app
  (touch down within 45 pt of the bottom edge, release at least 100 pt higher
  and within 140 pt horizontally) runs the same background lifecycle as
  `home`, but first calls `iosim_request_switcher()`, which signals the
  SpringBoard parent with `SIGUSR1`. SpringBoard's handler sets a pending
  request; when its `waitpid(WUNTRACED)` reports the stopped child it opens
  the switcher on that app's cached frame instead of repainting the home
  screen. The app still stops itself and the same SIGCONT path resumes it,
  so a gesture-initiated switcher card behaves identically to a home-screen
  one.
- A swipe up that starts on a switcher card force-quits that app. SpringBoard
  continues the stopped process so the pending SIGTERM is delivered, waits
  for it to be reaped, drops the pid and cached frame, and repaints the
  switcher (or home, when the last card is gone). Tapping the icon then runs
  the executable from scratch, so `viewDidLoad` runs again.

### 2.9 Services: libdispatch, Mach and XPC

The service substrate lives in `loader/services.c` and is exported through the
same shim table as libSystem. Dispatch is process-local; Mach message
transport and the bootstrap namespace are shared across the device.

- **libdispatch** has a main queue drained from UIKit's run loop
  (`iosim_dispatch_drain_main`), global queues backed by detached pthreads,
  groups, semaphores, `dispatch_once`, `dispatch_after`, and a `dispatch_main`
  that honours Darwin's `noreturn` contract. Blocks are heap-copied when queued,
  so stack blocks stay valid after their frame returns.
- **Mach** ports are table entries with a mutex, condition variable and message
  list. `mach_msg` supports send, receive or both, and receive honours
  `MACH_RCV_TIMEOUT` with a real `pthread_cond_timedwait` deadline.
  `bootstrap_register` hands the name to launchd_sim, which owns the namespace:
  it records the name and the registering pid and rejects a second live
  registration with `BOOTSTRAP_SERVICE_ACTIVE` (1103); names whose process has
  exited are pruned on the next request. A registered receive port also owns a
  listening `AF_UNIX` `SOCK_SEQPACKET` socket in the Linux abstract namespace,
  addressed by `iosim-svc:<FNV-1a(UDID)>:<name>` so every process on the device
  derives the same address without a filesystem rendezvous. A per-service
  reader thread accepts senders and turns each datagram back into a message on
  the port's queue.
  `bootstrap_look_up` returns the local port when this process registered the
  name, and otherwise asks launchd, connects to the service's address and
  returns a send port backed by that connection; `mach_msg` on it writes one
  datagram, which is the send right. Unknown names return 1102.
- **XPC** dictionaries, strings, integers, bools, data and arrays are backed by
  a small object type. A connection created with
  `xpc_connection_create_mach_service(name, queue,
  XPC_CONNECTION_MACH_SERVICE_LISTENER)` and resumed registers its name as a
  Mach service and starts a receiver thread; a client connection sends a
  dictionary that is serialized as a tagged tree into one Mach datagram. The
  receiver validates the frame, rebuilds the object graph (bounded depth,
  counts and lengths, since the bytes come from another process) and invokes
  the listener's event handler with the new object. Within one process a send
  still calls the peer connection's handler directly, preserving the original
  in-process flow. Handlers are heap-copied so stack blocks stay valid.

`tools/iosim-launchd` is the per-device boot anchor, state owner and bootstrap
namespace server.

### 2.10 Graphics and UIKit rendering

`loader/framebuffer.c` owns a 32-bit software framebuffer at the device's pixel
size. The renderer composites straight-alpha fills, SDF rounded rectangles,
circles and ellipses, anti-aliased scanline polygons, line strokes, linear
gradients (optionally rounded), and bilinear-scaled RGBA images. PNG files are
decoded with libpng in `loader/image.c`.

`frameworks/UIKit.m` maps the object model onto those primitives:

- `UIView` renders its background, its `CALayer` sublayers, then its subviews;
  `UIScrollView` shifts child origins by `contentOffset`; `UITableView` asks its
  data source for cells per row and draws separators and accessories.
- `CAShapeLayer` stores a `UIBezierPath` (via `CGPath`) and draws its fill and
  stroke; `CAGradientLayer` interpolates up to two color stops; `UIImageView`
  blits a decoded image with aspect-fit or centered content modes.
- Touch events from `IOSIM_EVENT_FIFO` are converted from device pixels to
  points and delivered as `UITouch`/`UIEvent` objects through the responder
  chain. `UIControl` implements begin/continue/end tracking with highlighting,
  drag-inside/outside and touch-up actions; subclasses such as `UISlider`
  update continuously while the finger moves. A single `tap` is synthesised
  as a down/up pair through the same path, then run-loop ticks, dispatch and
  active animations decide whether to re-render.
- `UIView` animations interpolate frames and alpha with the animation's
  delay, curve, repeat and autoreverse options; completion blocks run on the
  run-loop tick that passes their deadline. `CAAnimation` key paths drive
  layer opacity and corner radius, either from/to (`CABasicAnimation`) or
  through keyframes (`CAKeyframeAnimation` with values and keyTimes), using
  the animation's timing function or Core Animation's default linear pacing.
  `layer.presentationLayer` returns the values at the current instant, so an
  app can sample an animation in flight. A 2D affine transform is applied
  around the view center through an offscreen composite.

### 2.11 Auto Layout, gestures and text input

`NSLayoutConstraint`, `NSLayoutAnchor`, `NSLayoutDimension` and layout guides
are registered by the same runtime. Before rendering, `iosim_layout_apply`
collects active constraints, expresses each anchor as a linear form over the
x/y/width/height of its view, and runs a projection (Kaczmarz) relaxation over
the system. Dimensions with no explicit size constraint are locked to the
view's intrinsic size; multiline labels recompute their wrapped height from
their solved width. Safe-area guides contribute the measured iPhone 18 Pro
insets (62 pt top, 34 pt bottom).

Touches from `IOSIM_EVENT_FIFO` include tap, down, move and up records.
`UIWindow` hit-tests on down and creates a `UITouch` (window point,
previous point, phase, timestamp, hit view). Touches are delivered as an
`UIEvent` carrying an `NSSet`: `touchesBegan:` reaches the hit view, whose
default implementation forwards up the responder chain to the superview,
view controller and window; `touchesMoved:`/`touchesEnded:` go to the same
view. `locationInView:` converts window points into any ancestor's
coordinates, including scroll offsets.

`UIControl` tracks the touch: it highlights on down, sends `TouchDown`,
reports `TouchDragInside`/`TouchDragOutside` (and enter/exit transitions) as
the finger moves, then sends `TouchUpInside` or `TouchUpOutside` on release.
`UISlider` maps every down/move/up to its track, `UISwitch` toggles on release,
`UISegmentedControl` and `UIPageControl` select the segment or dot under the
release point, and `UITextField` becomes first responder on down.
`UIScrollView` drags update `contentOffset` with a rubber-band clamp; tap, pan
and swipe `UIGestureRecognizer` subclasses deliver target actions. The
framebuffer has an intersection clip stack, used by scroll views and
`clipsToBounds`/`masksToBounds`, so content cannot paint outside its host.

While an app is foreground its run loop is `UIApplicationMain`: it wakes
every 16 ms even when the event stream is idle, drains Foundation timers and
the main dispatch queue, fires scheduled `CADisplayLink` callbacks, completes
finished animations, and re-renders when any of them changed state. A display
link keeps the loop rendering at 60 Hz until it is paused or invalidated.

`UITextField` participates in the responder chain. A focused field draws its
placeholder or text, secure bullets and a caret, and `UITextField` edits from
keyboard taps or `key`/`backspace` FIFO records. When a field is first
responder, `UIApplicationMain` paints a QWERTY keyboard over the app frame
with the same framebuffer primitives used for everything else. The keyboard
uses measured iOS 26 geometry: a 324 pt panel with 26 pt top corners, 43 pt
key rows on an 11 pt gap, 33.2 pt letters (32.2 pt on the shift row), 44.7 pt
shift/delete keys, a 24 pt predictive bar and measured return, shift, delete,
emoji and mic artwork.

`UIAlertController` presents alert-style modals in the iOS 26 form measured
from the reference capture: a bottom-biased 320 pt floating card with 33.7 pt
corners, left-aligned title and message, and side-by-side pill actions. The
dimming view is painted at the measured 0.47 black and the status bar is
redrawn above it, matching the reference. Action blocks are copied to the heap
with `_Block_copy`, run on tap, then the modal dismisses through the same
presentation stack as any other controller.

Standard controls render with the measured iOS 26 design. `UISwitch` paints
a 63 x 28 pt capsule with a 36.3 x 23.3 pt white knob; `UISlider` uses a
5.7 pt track and the same lozenge as a thumb; `UISegmentedControl`,
`UIProgressView` and `UIPageControl` use glass fills that composite at the
measured opacities. The soft fills rely on the framebuffer's opacity clamp:
for translucent rounded rects and circles, interior coverage is bounded by the
current opacity instead of taking the opaque fast path.

### 2.12 SpringBoard system UI

With `IOSIM_SHELL=1`, `UIApplicationMain` calls `run_springboard` instead of
starting the app's scene. The system UI is a real executable of its own,
`SpringBoard.app/SpringBoard`; launchd boots it with the device environment,
and it shares the framebuffer, font stack and event stream with apps.

The home screen is a measured reconstruction of the iOS 27 iPhone 18 Pro
screen, not a stylized imitation: a 402 pt wide 4×4 grid at a 92.5556 pt pitch
with 64 pt icons and 12 pt labels, the 366×89 pt dock with its two apps, the
search pill and the status bar. The wallpaper is a 48×104 color field sampled
from a real capture with the UI regions masked out and diffused, upscaled
bilinearly at draw time; the dock and search glass are sampled fields as well.
Icon masks are circular rounded rects with a 22.37 % corner radius. The generic
app icon reproduces the measured wireframe: a white face with a soft bottom
shade, a square grid of 1 px #9a9a9a hairlines clipped by the face, a 2 px
#cdcdcd crosshair, three concentric circles (the central cell's inscribed and
circumscribed circles and the square's inscribed circle) and the square's
diagonals.

App enumeration is real. `tools/iosimctl` writes a manifest of installed
bundles, in install order, with display name, executable, bundle identifier and
data container. SpringBoard loads that manifest, draws the stock system apps
plus every installed app (generic placeholder artwork until a bundle carries an
icon), and hit-tests taps against the same grid. Slots are assigned in order
and split into 16-slot pages; the first page holds seven stock apps plus the
first nine installed apps. With more than one page, page dots (3.5 pt radius,
16 pt pitch, white for the active page) sit between the grid and the search
pill, a horizontal swipe moves between pages, and hit-testing only considers
the current page. Tapping an installed app closes the UI's event stream, forks
the loader with the app executable and waits for it with `WUNTRACED`. The child
runs the app's own `main` → `UIApplicationMain` → scene lifecycle, with its
`HOME` moved to the bundle's data container and `XPC_SERVICE_NAME` set, and
writes the same shared framebuffer. `home` (type 7) makes the app run
`sceneWillResignActive:`/`sceneDidEnterBackground:`, release the stream and
SIGSTOP itself; the same process resumes from its icon or switcher card.
`apps` (type 8) reloads the manifest and redraws when an install changes the
app set.

Stock system apps (Fitness, Watch, Reminders, Files, Preview, Utilities,
Contacts, Safari, Messages) are drawn from measured vector artwork. Their
Apple executables are not part of this runtime, so tapping one reports that no
executable is installed rather than faking a launch.

## 3. Why this design

**Why not run Apple's runtime?** Because the iOS 27 simulator runtime is
arm64-only, and the goal is native x86 execution. Reusing it would require an
arm64→x86 translator, reinstating the very emulation layer we are removing.
Older runtimes do ship x86_64 slices, but they cannot host current apps or
SDKs, so they are a compatibility branch, not the architecture.

**Why reimplement frameworks?** The simulator's frameworks are ordinary
Mach-O dylibs with well-defined install names and C/Objective-C ABIs. Once the
loader and ObjC substrate exist, each framework can be implemented
incrementally, validated against the same binaries Apple's toolchain produces.

**Why the loader in C?** It must map and execute foreign Mach-O images in the
same address space with no translation; C plus a small assembly trampoline is
the smallest reliable implementation. The device manager and boot anchor are
Python for iteration speed.

## 4. Known limitations

- Rendering is a software framebuffer. CoreAnimation is a subset: layers,
  sublayers with zPosition, shadows, borders, gradients, shapes, opacity and
  corner-radius animations. No render server, Metal, video or IOSurface.
- Mach ports, bootstrap and XPC are in-process. There is no cross-process Mach
  transport, launchd job control or multi-process app launch.
- `libdispatch` covers main/global queues, groups, semaphores and timers.
  Foundation is a subset (strings, collections, numbers, data, notifications,
  timers, dates, errors, bundles, defaults, file manager, URLs and JSON); it
  is not the full Foundation. `NSUserDefaults` is still memory-only.
- Auto Layout is a relaxation solver over anchors and guides, not Cassowary;
  it does not cover every UIKit layout API or content-size class.
- Text input is a single-line `UITextField` with a QWERTY/numeric keyboard;
  UITextView, selection handles and multitap gestures are absent.
- Darwin syscall differences are hidden by glibc for simple calls, but
  `stat`, `pthread`, `kqueue`, `mmap` flags and Mach traps need explicit
  translation.
- No code signing, entitlements, sandbox or AMFI emulation.
- arm64 binaries are rejected (fat containers are accepted only for x86_64
  slices).
- The dyld shared cache is not parsed; each dylib is loaded from disk.
- Class method dispatch covers the common path; message forwarding, associated
  objects, ARC entry points and exceptions are pending.
- The SpringBoard grid pages in 16-slot pages; page changes are discrete (no
  sliding animation), and there are no folders, widgets or Today view. The
  switcher shows at most three cards and opens from the home screen, an
  in-app bottom-edge swipe, or `ui switcher`; cards have no scrolling
  animation, and a swipe up on a card force-quits its app. A backgrounded app
  is suspended in place (the process stops and the same process resumes from
  its icon), with no memory-pressure termination policy. Stock system apps are display icons
  without executables, and a directly launched app alongside a running
  SpringBoard is not coordinated through launchd.
