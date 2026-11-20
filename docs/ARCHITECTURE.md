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
every other loaded image, the built-in Darwin shim table, then the service
layer. When `IOSIM_HOST_SYMBOLS` is set (an opt-in path for running unmodified
host-platform Darwin tools), the loader also `dlopen`s the colon-separated
`IOSIM_HOST_LIBS` and falls back to `dlsym` in its own process; ordinary
simulator guests never reach that fallback, so Darwin `open` flags and `stat`
layouts cannot accidentally meet a glibc function. Unresolved non-weak imports
get a generated trampoline that reports the missing symbol name instead of
crashing anonymously.

### 2.3 Entry and image initialization

After fixups and before entry, every image's initializers run in reverse load
order (dependencies before dependents, main last), matching dyld:

- `__DATA,__mod_init_func` is an array of 64-bit constructor pointers.
- `__TEXT,__init_offsets` is an array of 32-bit offsets relative to
  `preferred_base + slide`; modern linked executables use this form (the Metal
  Shader Converter has 242 such constructors). Without them, C++ command-line
  tools run with no static objects registered.

`LC_MAIN` then gives a file offset relative to `__TEXT`; it is converted to an
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

Two more pieces of image state are prepared before constructors:

- **Thread-local variables.** Each 24-byte thunk in `__DATA,__thread_vars`
  carries the variable's offset into the image's combined `__thread_data` +
  `__thread_bss` content. The loader keeps one pthread key per image, copies
  that initial content once per thread on first access, and replaces the thunk
  getter with a register-preserving assembly stub (all general registers and
  xmm0–15 restored, only `rax` changed), as Darwin's TLV calling convention
  requires.
- **Darwin pthread static initializers.** Darwin's opaque pthread objects embed
  signatures (`PTHREAD_MUTEX_INITIALIZER` begins with `0x32AAABA7`, conds with
  `0x3CB0B1BB`, and so on). glibc reads the signature as a locked futex and
  deadlocks host libc++. The loader scans writable data sections for those
  signatures with zeroed opaque tails and re-initializes the objects in place
  with the host pthread library, mapping recursive and error-checking mutex
  variants. Guest-facing pthread calls in the service layer also translate a
  signature on first use and use host mutexes rather than spinlocks.

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
`NSData` reads and writes files; `NSFileHandle` opens reading, writing or
updating handles on real host descriptors, so `readDataOfLength:`,
`readDataToEndOfFile`, `writeData:`, the seek family, `offsetInFile`,
`truncateFileAtOffset:` and `synchronizeFile` all share one descriptor
offset — and the standard input/output/error/null handles are real
descriptors too; `NSURL` carries file paths and path
components; and `NSJSONSerialization` is a dependency-free recursive
serializer and parser over `NSDictionary`, `NSArray`, `NSString`, `NSNumber`
and `NSNull`. Compact output is deterministic (dictionary insertion order on
this runtime) and the parser rejects truncated or malformed input.

`NSArray`, `NSSet` and `NSDictionary` adopt `NSFastEnumeration`: because their
backing stores are contiguous C arrays, `countByEnumeratingWithState:` hands
the loop `itemsPtr` straight at that storage (arrays and sets yield members,
dictionaries yield keys). Compiler-emitted for-in loops check the mutation
pointer each pass and call `objc_enumerationMutation` on a mismatch; the
runtime exports that symbol as a no-op, matching the collections' lack of a
live mutation counter. Indexed and keyed subscripting map onto the existing
primitive accessors: `array[i]` is `objectAtIndexedSubscript:`,
`array[i] = obj` is `setObject:atIndexedSubscript:` (replace, or append when
`i == count`), `dict[key]` is `objectForKeyedSubscript:`, and
`dict[key] = obj` is `setObject:forKeyedSubscript:`, where a nil value removes
the key.

Key-value coding looks accessors up the way Foundation does: `get<Key>`,
`<Key>` and `is<Key>` for reads, `set<Key>:` and `_set<Key>:` for writes.
The runtime hands out each method's type encoding, so scalar getters are
boxed (`NSNumber` for integers, floats and booleans) and `setValue:forKey:`
unboxes `NSNumber` arguments before calling the setter; object values pass
through directly. Key paths split on `.` and recurse, and `@count` applied to
a collection returns an `NSNumber`.

Automatic key-value observing uses the same isa-swizzling design as objc4.
The loader runtime now creates classes at run time
(`objc_allocateClassPair`, `class_addMethod`, `object_setClass`); the first
observation of a class builds `NSKVONotifying_<Class>`, overrides `-class` to
return the original class and wraps each observed key's setter with a
type-correct C trampoline (object, integer, boolean, float, double and the
CG geometry structs). The trampoline calls `willChangeValueForKey:`, the
original setter and `didChangeValueForKey:`; the pending-change stack keeps
the pre-change value so `NSKeyValueChangeOldKey` is real even for scalar
properties. `willChangeValueForKey:` alone supports manual notifications.
Options `New`, `Old`, `Initial` and `Prior` are honored; `removeObserver:`
stops delivery while leaving the wrapped setter in place.

`NSPropertyListSerialization` writes and reads XML property lists, and
`NSUserDefaults` persists a domain to
`$HOME/Library/Preferences/<bundle-id>.plist`.

`NSNotificationCenter` keeps selector observers and block observers in one
table; the block API copies its closure and returns a token that
`removeObserver:` accepts. Notifications carry `name`, `object` and
`userInfo`, posting filters by name and object before delivering the same
notification object to each matching observer, and
`postNotificationName:object:userInfo:` and `postNotification:` are both
available.

`NSDateFormatter` walks the same format tokens in both directions:
`stringFromDate:` decomposes the epoch into civil date fields and prints
`y/M/d/H/m/s` runs, while `dateFromString:` consumes numbers into those
fields, matches literal separators (allowing `/`, `-`, `:`, `.` and space
equivalents) and rebuilds the epoch with `days_from_civil`. `NSNumberFormatter`
formats decimals with grouping and minimum/maximum fraction digits, adds a
currency symbol or a percent suffix and scales for the style, and parses
formatted text (sign, group separators, `$`, `%`) back to an `NSNumber`.

`NSKeyedArchiver` builds the same keyed-archive structure Foundation uses: an
XML plist with `$archiver`, `$version`, `$top` and a `$objects` table, where
class descriptions record `$classname`/`$classes` and every object reference
is a `CF$UID` entry. Strings, numbers, data and dates sit directly in the
table; arrays, dictionaries and sets store reference lists; any other object
takes part through `NSCoding` (`encodeWithCoder:`/`initWithCoder:`), with its
entry reserved before its children so cycles resolve. `NSKeyedUnarchiver`
rebuilds objects lazily and allocates custom classes by name through the ObjC
runtime; `NSMutableData` backs incremental archive output.

`NSRunLoop` runs the same timer table through `runMode:beforeDate:`,
`runUntilDate:` and `run`, sleeping through the `usleep` libc shim.
`performSelector:withObject:afterDelay:` registers a one-shot timer whose
fire sends the argument instead of the timer, and the
`cancelPreviousPerformRequests...` class methods invalidate matching entries.
`NSThread` answers `isMainThread` through a `pthread_main_np` shim that
records the loader's first thread, and sleeps with the same shim.

`NSCalendar` implements the Gregorian calendar over the same civil-date
arithmetic as the property-list writer: `components:fromDate:` splits a
`timeIntervalSince1970` into year, month, day, hour, minute, second and a
Sunday-based weekday (plus ISO week and nanoseconds), and
`dateFromComponents:` runs the inverse through days-from-civil. Defaults
follow Foundation for an unset year/month/day, and
`NSCalendarIdentifierGregorian` names the calendar.

`NSOperationQueue` dispatches each `NSOperation` through a libdispatch
global queue and counts it in a dispatch group, so
`waitUntilAllOperationsAreFinished` is a real group wait; suspension defers
the dispatch until resumed. `NSBlockOperation` copies its execution blocks
with `_Block_copy` when they are added (a stack literal would otherwise die
with its loop frame), runs them in order and then the completion block.
Dispatch's group scheduling now copies the queued block, runs it on a
worker thread and leaves the group when it returns, so group waits cover
the execution rather than just the enqueue.

Bundle resources follow the executable: when a guest image lives inside
`Foo.app`, the loader exports `IOSIM_BUNDLE_DIR=Foo.app` (derived from the real
executable path, so an app launched by SpringBoard does not inherit the system
UI's bundle). `NSBundle` answers `resourcePath`/`pathForResource:ofType:` from
that directory and returns nil when the file is missing, and
`UIImage imageNamed:` tries the exact name and then `name.png`, decoding the
PNG through the framebuffer image loader.

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
  [seconds] | key <text> | backspace | home | apps` injects system UI events
  into the device event
  FIFO, in point coordinates scaled to pixels. `swipe` emits a down, an
  interpolated run of moves and an up. The frontmost process reads the stream:
  at home SpringBoard hit-tests icons, while an app receives touches, keys and
  the `home` background request. `UIApplicationMain` opens the stream before
  its first frame so events sent during scene construction are queued rather
  than lost. The stream stays open across writer gaps: a FIFO with no current
  writer (between two `ui` commands) is idle, not closed, and only the explicit
  `quit` record ends a reader loop.
- `home` is a real suspension: the app sets its `applicationState` to
  inactive, runs `applicationWillResignActive:`, posts the matching
  notification, runs `sceneWillResignActive:`, then repeats that pattern with
  background / `applicationDidEnterBackground:` / `sceneDidEnterBackground:`,
  closes the event stream and stops itself with SIGSTOP. SpringBoard's `waitpid(WUNTRACED)` sees the stop, records the PID
  on the app's icon and repaints the home screen. Tapping that icon closes
  SpringBoard's reader, sends SIGCONT and waits again; the same process
  reopens the stream, walks inactive → active through
  `applicationWillEnterForeground:`/`sceneWillEnterForeground:` and
  `applicationDidBecomeActive:`/`sceneDidBecomeActive:` with its notifications,
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
- **XPC** dictionaries, strings, integers, bools, data, arrays and connections
  are backed by a small object type. A connection created with
  `xpc_connection_create_mach_service(name, queue,
  XPC_CONNECTION_MACH_SERVICE_LISTENER)` and resumed registers the name with
  launchd and marks its service socket as an XPC endpoint. Every accepted
  client socket becomes a peer connection: the listener's handler receives it
  as an `XPC_CONNECTION` object (comparable through `xpc_get_type`), installs
  a message handler on it and resumes it, and a per-connection thread reads
  request/message frames. A send made from inside a peer handler becomes the
  reply for the current request id; the client's reader matches reply frames
  to slots registered by `xpc_connection_send_message_with_reply` and by its
  synchronous variant. Frames carry the sender pid, a kind and a request id
  around a tagged tree; the decoder bounds depth, counts and lengths because
  the bytes cross a process boundary. Plain `xpc_connection_create`
  connections keep an in-process shortcut for fixtures that wire both sides in
  one process. Handlers are heap-copied so stack blocks stay valid.
- **launchd jobs** are plists in the device's `Library/LaunchDaemons`
  (`Label`, `ProgramArguments`, `MachServices`, `RunAtLoad`, `KeepAlive`,
  `EnvironmentVariables`). launchd_sim scans them at boot and on
  `iosimctl launchd-load`, starts RunAtLoad jobs under the loader with the
  device environment, and tracks their pids. A lookup of a MachServices name
  with no live registration starts the owning job and reports `starting`; the
  guest-side lookup retries across that window, then connects to the service
  socket once the job registers it (also retrying while the socket binds).
  Dead jobs are pruned, KeepAlive jobs are restarted, and shutdown terminates
  every job. A job's `Sockets` dictionary is honored: launchd_sim binds each
  `SockPathName` (stream or datagram) when the job is loaded, keeps the
  listener, and starts the job when a connection makes it readable. The job
  inherits the listening descriptors and `IOSIM_ACTIVATED_SOCKET_FDS` names
  them; the guest-side `launch_activate_socket` liblaunch entry point parses
  that handoff and returns the fds, so the job's own `accept` consumes the
  queued connection. Jobs are reaped through their process handles, so the
  next connection starts a fresh process.
- **UIPasteboard** is a device-level service without a daemon: the general
  pasteboard is an XML property list at
  `$SIMULATOR_SHARED_RESOURCES_DIRECTORY/var/run/pasteboard.plist`, and each
  access reloads it so any guest process sees another app's latest write.
  Items are dictionaries keyed by pasteboard type; `string`/`setString:` use
  `public.utf8-plain-text` and `dataForPasteboardType:`/`setData:` handle any
  other type. Every write bumps a persisted `changeCount`.

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
  `UIScrollView` shifts child origins by `contentOffset`; `UITableView` walks
  sections and rows (applying delegate header heights, title headers and
  per-row heights), asks its data source for each cell and draws separators
  and accessories, so a tap maps back through the same section geometry.
  A leftward drag over an editable row records an open swipe: the row renders
  shifted with a red Delete control, a tap in that control calls the data
  source's `commitEditingStyle:forRowAtIndexPath:` with
  `UITableViewCellEditingStyleDelete` and reloads, and `setEditing:` shifts
  rows and draws minus controls whose taps reveal the same Delete control.
  `insertSubview:atIndex:`, `bringSubviewToFront:` and `sendSubviewToBack:`
  reorder the subview list.
- `UIRefreshControl` is owned by the scroll view (`refreshControl`), which adds
  it as a subview above the content at `-60 pt` and extends the drag clamp to
  the same distance. Pulling fills the eight-blade spinner proportionally;
  touch-up past 80 % of the height calls `beginRefreshing`, snaps the offset to
  `-60 pt` and sends `UIControlEventValueChanged`. `endRefreshing` stops the
  infinite animation and returns the offset to zero. The spinner reuses the
  activity-indicator blade model with a rotating opacity tail.
- `UIVisualEffectView` captures the framebuffer behind its frame
  (`iosim_fb_capture`), runs a two-pass separable box blur over the RGB
  channels, applies the blur effect's tint, and composites the result through
  an RGBA blit whose alpha follows the layer's rounded-rect SDF, so the corner
  radius stays sharp. Its `contentView` renders in the normal subview pass on
  top of the glass.
- `UICollectionViewFlowLayout` derives a column grid from the item size,
  interitem and line spacing and section insets; `UICollectionView` reloads
  cells as real subviews at those frames, so the scroll view's offset and clip
  move them together, and it routes taps to the item's index path and delegate.
  A data source may implement `numberOfSectionsInCollectionView:`; the reload
  and tap passes walk each section with its own running cursor (top inset,
  rows, bottom inset, then one line-space between sections), so item index
  paths carry their section and selection is tracked per section.
  `registerClass:forCellWithReuseIdentifier:` and
  `dequeueReusableCellWithReuseIdentifier:forIndexPath:` create cells the way a
  data source expects.
- `UIStepper` lays out two `UIControl` halves around a divider; each half
  steps the value within minimum/maximum (honouring stepValue and wraps) and
  sends `UIControlEventValueChanged`.
- `UIPickerView` keeps a fractional row offset per component. Rendering draws
  each wheel's titles at `center + (row - offset) * 32 pt`, fades rows toward
  the edges, and paints a centered selection band; dragging shifts the wheel's
  offset, and touch-up snaps it to the nearest row and reports
  `pickerView:didSelectRow:inComponent:`. A tap selects the row under the
  finger. Text follows the surface luminance (label color behavior), and
  `selectRow:inComponent:animated:` and the reload methods reset offsets from
  the data source.
- `UIDatePicker` embeds a `UIPickerView` and acts as its data source and
  delegate, so the wheels, band, hit-testing and snapping are the same code.
  The component layout follows `datePickerMode` (month/day/year,
  hour/minute/AM-PM, both, or a countdown), the day wheel's row count follows
  the selected month and leap year, and a month or year change reloads that
  wheel before clamping the day. Selection rebuilds the date through
  `NSCalendar`/`NSDateComponents` and sends `UIControlEventValueChanged`;
  setting the date refreshes every wheel from the calendar components.
- `UISearchBar` embeds a real `UITextField` subclass, so focusing it raises
  the software keyboard and hardware keys edit the same text. EditingChanged
  reaches `searchBar:textDidChange:`; Return is intercepted before it can
  insert a newline and calls `searchBarSearchButtonClicked:`; the Cancel
  control clears the field, resigns it and calls the delegate.
- `UINavigationController` reads each top controller's `navigationItem` and
  renders its title plus left/right `UIBarButtonItem`s as real `UIControl`s
  in the bar, so their targets fire through normal touch tracking. A pushed
  controller gets an automatic "‹ Previous" back control that pops the stack;
  an explicit left item or `hidesBackButton` replaces it.
- `UITabBarController` is a real container: it owns up to 16 view controllers,
  gives each a `UITabBarItem` (title and optional bundle image), and lays out a
  floating glass bar inset 16 pt from the sides, 64 pt tall, 12 pt above the
  home indicator. Each item is a `UIControl` with a label (and icon), so taps
  run through the normal tracking path; selecting an item swaps the content
  view behind the bar and retints the labels.
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
  A layer holds up to four explicit animations at once: adding with a key that
  is already present replaces that animation, adding without a key appends,
  and the most recently added animation for a property wins when it is
  sampled. `layer.presentationLayer` returns the values at the current
  instant, so an app can sample several animations in flight on one layer.
  `CAAnimationGroup` expands into one slot per child when added, inheriting
  the group's duration, timing function and repeat count where a child leaves
  them unset; children are keyed `key:index`, so removing the group's key
  clears every expanded child at once. A 2D affine transform is applied around
  the view center through an offscreen composite.

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
and swipe `UIGestureRecognizer` subclasses deliver target actions.
`UILongPressGestureRecognizer` records the down point and time, lets the
window's per-frame tick fire `Began` once `minimumPressDuration` elapses,
sends `Changed` with each move while the press is active, ends it on lift and
fails it if the finger moves beyond `allowableMovement` first. The
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

`UITextView` shares the first-responder role. Touching an editable text view
focuses it; `insertText:` appends at the end and `deleteBackward:` removes the
last character. The return key inserts a newline instead of ending editing,
which `UITextField` does. The renderer wraps the stored text preserving spaces
(breaking at the last space that fits) and draws a caret at the insertion
point. Hardware input reaches both views through `ui key` records, which
`iosimctl` emits per character (`key return` for a newline, `key space` for a
space) and `ui backspace`; the on-screen keyboard taps use the same edit
methods.

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
app set. A reload carries every suspended app's pid and cached frame over to
its new manifest entry (matched by bundle identifier), so installing an app
does not forget the apps already stopped; a name that disappeared from the
manifest has its process continued and terminated instead of leaking.

Stock system apps (Fitness, Watch, Reminders, Files, Preview, Utilities,
Contacts, Safari, Messages) are drawn from measured vector artwork. Their
Apple executables are not part of this runtime, so tapping one reports that no
executable is installed rather than faking a launch.

The search pill opens a Spotlight-style overlay over the dimmed wallpaper: a
34 pt title, a glass search field with a caret, matching app rows (icon and
name, up to four visible) and the same software keyboard apps use. The field
shares the runtime's first-responder path through a hidden `UITextField`, so
on-screen keyboard taps and `ui key` records edit the same query; matching is
case-insensitive substring search over the installed app names, including
stock apps. Tapping a row launches or resumes that app, and `home` closes the
overlay. Each keystroke logs the result count, which is what the tests assert
alongside the drawn row and keyboard pixels.

A downward drag that starts in the top-right corner opens the Control Center:
the sampled wallpaper dimmed under translucent modules, a 2 × 2 connectivity
tile (airplane, cellular, Wi-Fi, Bluetooth) with vector icons, a media tile,
brightness and volume sliders, and a utility row. Tapping a connectivity circle
toggles it — blue, or green for cellular, with a white glyph when on and a gray
fill with a dimmed glyph when off — redraws the panel and logs the state. A
swipe up from the bottom edge or the home event closes it. Test screenshots
sample the Wi-Fi circle before and after the tap, so the panel and its state
colors are real pixels, not a static overlay.

A held drag on the home screen picks up an icon: the finger must rest for
300 ms before its first movement, which arms the drag, so a quick swipe that
happens to start on an icon still turns the page. Dropping the icon on another
groups both into a home-screen folder, matched by bundle identifier rather than
by executable; the grid entry collapses into the first member's slot and is
drawn as a dark tile holding up to four mini icons. Dropping it on an existing
tile adds it to that folder. Tap the tile to open an overlay over the dimmed
wallpaper: the folder title at 22 pt, a rounded panel, and members in a
four-column grid. Tapping a member launches or resumes its app; tapping
outside, a vertical swipe, or the home event closes the overlay. The grouping
is written to
`Library/SpringBoard/folders.txt` under the device's shared resources directory
as `name|bundle,bundle` lines, reloaded and pruned at the next SpringBoard boot
when a member's bundle is no longer installed. Stock system apps carry no
bundle identifier and cannot be folded.

Locking draws the lock screen: the sampled wallpaper at full brightness, the
real date from `NSCalendar` and the status time at 76 pt, the flashlight and
camera glass circles, and the home indicator. The status bar shows only the
right-side icons — the time lives on the lock screen. A swipe up (or the home
event) unlocks. When an app is foreground at lock time, the app's event loop
receives the lock event, runs `applicationWillResignActive:` /
`applicationDidEnterBackground:` with the scene callbacks, signals its
SpringBoard parent with `SIGUSR2` and `SIGSTOP`s itself. SpringBoard recognizes
the pending lock request when `waitpid(WUNTRACED)` reports the stop, captures
the switcher snapshot, and draws the lock screen instead of the home screen.
Unlocking resumes that stopped process and waits on it again, so the app
returns in place with `applicationWillEnterForeground:` /
`applicationDidBecomeActive:` and its `viewDidLoad` still ran only once.

### 2.13 Kernel symbolication from a KDK

The services layer implements Mach and BSD entry points by name, so it needs
the kernel's own dispatch tables as ground truth rather than a partial memory
of them. `tools/kernel_symbols.py` parses Mach-O headers, segments, sections
and `LC_SYMTAB` directly, merges the release image's exported symbols with the
dSYM's local function symbols, and bounds each function by the next text
symbol in its section. That yields a complete address-ordered map (50,898
symbols and 99.275 % of executable bytes for the KDK 27.0.1 x86_64 kernel), and
`--source` resolves an address through DWARF to its subprogram, file and
line-table location.

The same tool decodes `_mach_trap_table` (128 entries) and `_sysent` (558
entries): both use 24-byte entries in this kernel, with the handler at `+8` and
argument info at `+0` for traps, and the handler at `+0`, munge at `+8`,
return type at `+16`, narg at `+20` and argument bytes at `+22` for syscalls.
Layout detection scores candidate strides and field offsets by whether they
land on real text symbols, so a different kernel generation is decoded by
evidence rather than a version check. `_mach_call_munger64` and
`_unix_syscall64` confirm the strides in their index computation, and the
fixture in `tests/kernel_symbols_fixture.c` exercises the same paths without a
KDK. `docs/KDK.md` records the DMG/pbzx unpacking steps and the measured
tables.

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
  sublayers with zPosition, shadows, borders, gradients, shapes, and several
  concurrent opacity, corner-radius and keyframe animations per layer. No
  render server, Metal, video or IOSurface.
- Mach messages, the bootstrap namespace and serialized XPC dictionaries cross
  guest processes through launchd-owned names and abstract Unix sockets.
  Mach port rights are per-service send sockets rather than general port right
  transfer; launchd starts LaunchDaemon plists with boolean RunAtLoad and
  KeepAlive but does not implement socket activation or job throttling.
- `libdispatch` covers main/global queues, groups, semaphores and timers.
  Foundation is a subset (strings, collections, numbers, data, notifications,
  timers, dates, errors, bundles, defaults, plists, file manager, URLs and
  JSON); it is not the full Foundation. `NSUserDefaults` persists XML property
  lists under `$HOME/Library/Preferences`; binary property lists are not
  parsed.
- Auto Layout is a relaxation solver over anchors and guides, not Cassowary;
  it does not cover every UIKit layout API or content-size class.
- Text input is `UITextField` and an append-only `UITextView`; selection
  handles, text selection and multitap gestures are absent.
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
