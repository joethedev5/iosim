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
- `__objc_catlist` entries are resolved by their category symbol name
  (`__OBJC_$_CATEGORY_Class_$_Category`), because the category's class
  reference is not a plain relocated pointer in the modern metadata. Category
  instance and class method lists are searched by class name after the class's
  own methods and before walking to the superclass, so categories behave like
  objc4 additions without rewriting read-only method lists.
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

`NSURLSession` implements data tasks: `NSURLRequest` carries the URL, method,
body and headers, `NSMutableURLRequest` subclasses it, and
`setValue:forHTTPHeaderField:`/`addValue:forHTTPHeaderField:` build the header
dictionary lazily (adding to an existing field appends a comma-separated
value). `dataTaskWithURL:` and `dataTaskWithRequest:` share the same task;
`NSURLSessionDataTask` copies the completion block and returns immediately,
dispatching the transfer to a global queue. The loader
owns a small host HTTP/1.0 client (`iosim_http_request`) that parses the URL,
resolves and connects to the host, streams the request body, reads until the
peer closes and splits status line, headers and body. The task builds
`NSData` and `NSHTTPURLResponse` with a parsed header dictionary; failures and
cancellation arrive as `NSError` in `NSURLErrorDomain`. For `https://` URLs
the same client wraps the connected socket in OpenSSL with SNI and the
system TLS stack. Certificate and hostname verification are enabled by
default through the system trust store; tests that use a self-signed loopback
certificate set `IOSIM_TLS_INSECURE=1`, and a build without OpenSSL reports an
unsupported-HTTPS error instead.

`NSRegularExpression` compiles patterns through a loader-host POSIX regex
shim: the pattern translator accepts ICU spellings for `\d`, `\w`, `\s`
(and their negations), non-capturing groups and lazy quantifiers before
`regcomp`/`regexec`. Matches carry a byte range plus one range per capture
group; `matchesInString:` returns `NSTextCheckingResult` objects,
`firstMatchInString:` returns the first, and
`stringByReplacingMatchesInString:` expands `$0`–`$9` templates. Case
insensitivity is a creation option and is merged with per-search options.

`NSPredicate` parses a Foundation format string into boolean expressions:
comparisons (`==`, `=`, `!=`, `<`, `<=`, `>`, `>=`), string operators
(`CONTAINS`, `BEGINSWITH`, `ENDSWITH`, `LIKE` with `*` and `?`), `IN` with
array literals, key paths, `SELF`, quoted strings, numbers, `nil`/`NULL`,
`YES`/`NO`, `TRUEPREDICATE`/`FALSEPREDICATE`, parentheses and `NOT`/`AND`/`OR`
with conventional precedence. `NSArray filteredArrayUsingPredicate:` and
`NSMutableArray filterUsingPredicate:` evaluate it per element; a variadic
`predicateWithFormat:` routes through the same NSString formatter.

`NSScanner` scans integers, doubles, literal strings and up-to-terminator
substrings from an `NSString`, tracking a byte scan location and skipping
whitespace between scans; `scanString:` compares case-sensitively at the
current location, and `scanUpToString:` copies the run into a fresh string.

`NSArray` and `NSMutableArray` sort stably with `NSSortDescriptor` keys
(ascending or descending, with selector comparators), with a custom selector,
or in place; `exchangeObjectAtIndex:withObjectAtIndex:` swaps storage.
`NSString` implements `compare:` and `caseInsensitiveCompare:` with
`NSComparisonResult`, so descriptor comparisons work for text and boxed
numbers alike.

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
through directly. Key paths split on `.` and recurse. Collection operators run over
the receiver's fast enumeration: `@count`, `@sum`, `@avg`, `@max`, `@min`,
`@distinctUnionOfObjects`, `@unionOfArrays` and `@distinctUnionOfArrays`,
with a trailing key path applied to every element. `NSDictionary` overrides
`valueForKey:` to return `objectForKey:` for ordinary keys.

`CoreGraphics.framework` ships a direct-framebuffer `CGContext`: fill and
stroke colors, alpha, line width, line cap/join style, miter limit, dash
pattern and phase, rect/ellipse fills and strokes, a point path with
fill/stroke/close, transform/scale and a saved graphics-state stack. Strokes
are rasterized by a shared framebuffer polyline stroker: segment quads are
filled with 4x vertical supersampling, caps and joins are filled separately,
and dashed strokes are split by walking the pattern along the arc length. `iosim_cg_begin_view` maps points through the view origin and device
scale and draws through the loader's framebuffer primitives, so clipping and
view alpha apply. The renderer calls `drawRect:` for every view after its
background and before its sublayers; plain `UIView` implements a no-op and
custom subclasses can paint immediately. `UIGraphicsBeginImageContextWithOptions`
redirects the same CGContext into a loader offscreen framebuffer; the result
is copied out as RGBA for `UIGraphicsGetImageFromCurrentImageContext`, and
`UIImage drawInRect:` blits into whichever context is current. Mutable
`CGPath` objects record move/line/close elements, `CGPathAddRect`,
`CGPathAddEllipseInRect` and `CGPathAddPath` append geometry, `CGPathApply`
walks them, and `CGContextAddPath` flattens a path into the context point
list. `UIBezierPath CGPath` builds a real path, and `CAShapeLayer` accepts
either a `UIBezierPath` or a `CGPath` and converts the latter for the
renderer. `UIColor CGColor` returns a refcounted CoreGraphics color with the
same component layout, and `UIGraphicsPushContext`/`UIGraphicsPopContext`
redirect and restore the current drawing context, including nested image
contexts. `CGContextClipToRect` intersects the framebuffer clip stack with a
transformed rectangle, `CGContextClip` rasterizes the current path into an
even-odd coverage mask that intersects any active mask, and save/restore
tracks both the rect clip and mask depths. Fills, strokes, glyphs and image
blits consult the mask. Refcounted `CGImage` objects own
RGBA pixels; `CGContextDrawImage` scales one into a rectangle, `UIImage
CGImage` exposes a cached image and `imageWithCGImage:` copies one back.
`UIGraphicsImageRenderer` wraps the image-context stack: it allocates a
bitmap at the format's scale, runs the actions block with a renderer context
exposing the current `CGContext`, and returns the captured `UIImage` or a PNG
`NSData`. `UIImagePNGRepresentation` emits a standards-compliant RGBA PNG
using stored (uncompressed) deflate blocks, so no zlib dependency is needed.
`UIViewController.additionalSafeAreaInsets` is copied onto the controller's
view, so a root view reports the device insets plus the controller's addition
and the safe-area guide uses the combined values.
`UIView.layoutMargins` defaults to 8 points on every edge (and can inherit the
superview's margins with `preservesSuperviewLayoutMargins`). The
`layoutMarginsGuide` is a `UILayoutGuide` whose insets feed the Auto Layout
linear forms, and its `layoutFrame*` accessors report the inset rectangle in
the owning view's coordinates.
`CAGradientLayer.type` selects axial (the default) or radial rendering; radial
gradients sample the stop table per pixel from `startPoint` outward to the
radius given by `endPoint`, then reuse the rounded-mask offscreen path.
`NSAttributedString` keeps its string and one attribute dictionary;
`UILabel` and `UIButton` read the font and foreground color from that
dictionary and render the plain string. `UIViewController` keeps a small
child list with parent links, and
`UIPageViewController` installs the current page as a child view when its view
loads and swaps pages by removing and adding subviews.
`UISplitViewController` installs primary and secondary controllers as
children and a container view lays them out side by side at 700pt and wider,
collapsing to the secondary controller below that width; `displayMode`,
column-width settings and the will-change delegate callback are tracked.
`NSCharacterSet` stores a byte membership table, which backs string trimming
and the mutable set operations. UIFont carries size, boldness and an optional
face name, enough for weight, italic, monospaced, named and descriptor-based
constructors. UIColor converts HSV to RGB and accepts Display P3 components as
sRGB. `readableContentGuide` reserves 16pt side margins.
`UIButton` keeps a real `UIImageView` subview for `setImage:forState:` and
positions it beside the title (or centers it when there is no title);
`UIButtonConfiguration` carries a title, image, foreground/background colors,
corner style, content insets and image padding, and assigning one applies
those values to the button, including a capsule corner radius. Content, title
and image edge insets feed the title-label frame. `UITextField.borderStyle`
paints a rounded dark field background and insets its text; the border style,
clear-on-begin-editing, left/right views and view modes are exposed.
`UIFont.preferredFontForTextStyle:` returns the 17pt body face.
`UIBarButtonItem` accepts image and custom-view initializers and draws an
image-only item as a 24pt image view. `UINavigationItem`
stores back-button titles, bar-button arrays and large-title display mode, and
`UINavigationBar` exposes bar style, large titles, translucency and title
attribute dictionaries. `UIPopoverPresentationController` and
`UISheetPresentationController` are real objects reachable from a controller:
popovers keep source view/rect, arrow directions and layout margins, and
sheets keep detents (`mediumDetent`/`largeDetent`/custom), grabber visibility
and corner radius, so configuration code runs even where the presentation is
not shown as a popover.
`CATextLayer` draws its string with the shared font renderer, honouring
`fontSize`, an optional `UIFont`, `foregroundColor` and left/center/right
alignment. `UIView.transitionFromView:toView:` swaps the two views in the
common superview, and `transitionWithView:` runs its animation block and
completion immediately. `NSValue` stores up to 64 bytes plus an Objective-C
type string and unpacks CGPoint/CGSize/CGRect/UIEdgeInsets/NSRange/pointer
values; `NSIndexSet`/`NSMutableIndexSet` keep a sorted index list with block
enumeration. `UIWindowScene.windows` tracks windows created with
`initWithWindowScene:`, and `UISceneSession` supplies a persistent identifier
and application role.
`NSProcessInfo` exposes a singleton with an empty environment and argument
list, four processors, 4 GB of physical memory and a 36-character
`NSUUID.UUIDString`; `NSUUID` stores 16 bytes and prints canonical uppercase
hyphenated text. `NSURLQueryItem` and `NSURLComponents.queryItems` parse and
rebuild `&`-separated `name=value` pairs; `NSURL` also appends/deletes path
extensions and returns path components. `NSValue` additionally packs affine
and 3D transforms. `UIDevice.currentDevice` reports an iPhone on iOS 18.0 in
portrait with unknown battery state, and posts the orientation notification
name. `UISearchController` owns a real `UISearchBar`, keeps results-updater
and delegate objects, and calls the updater when activated. UIView
accessibility label/identifier/hint/value/traits/elements storage is present,
labels default to their text with the static-text trait, buttons default to
the button trait, and the `UIAccessibility*` query functions return the
non-accessibility-enabled answers. Gesture recognizers store delegate,
enabled, delays/cancels flags, touch counts and tap/pan/swipe counts.
`NSData` encodes and decodes base64 with padding, `NSIndexSet` answers
greater/less-than queries and enumerates consecutive runs as ranges, and
`NSURL` accepts a directory flag when appending a path component.
`UIAccessibilityElement` is a standalone element with container, label,
identifier, hint, value, traits and frame. `UITableView` stores separator,
header/footer, background, selection, drag/drop, prefetch and estimated-height
configuration; `UICollectionView` stores prefetch, drag/drop, background and
selection state and answers `visibleCells`, `numberOfSections` and
`numberOfItemsInSection:`. `UIScrollView` stores keyboard-dismiss mode,
indicator style and `scrollsToTop`.
`NSURL` parses scheme, host, port, path and query from its string;
`NSURLComponents` reads those parts from a URL and rebuilds a string from its
scheme, host, port, path, query and fragment. Empty collection literals
(`@[]`, `@{}`) resolve through the `__NSArray0__`/`__NSDictionary0__` globals
that Foundation exports.
`UIView.maskView` hands the mask view's layer to the target layer's mask slot
and mirrors the mask view's background onto that layer, since masks are
rendered from layers rather than views. Hit testing stops at a view with
`userInteractionEnabled = NO`, so touches fall through to what is behind it.
`UIWindow` records its scene, and `UIApplication` exposes the key window and
the list of connected scenes created by `UIApplicationMain`.
A view's backing layer comes from `+[UIView layerClass]`, so a subclass can
return `CAGradientLayer` (or another layer type) and have the renderer draw it;
the view path invokes the same gradient helper as standalone sublayers.
`animationKeys`, `animationForKey:` and `removeAllAnimations` expose the
per-layer animation slots.
Layer animations queue their `CAAnimationDelegate` in a small event table at
add time; the run-loop animation tick calls `animationDidStart:` at the
begin time and `animationDidStop:finished:` after the duration (or with
`finished:NO` when the animation is removed or replaced early).
`CALayer.contents` accepts a `CGImage` or `UIImage`; the renderer crops it to
`contentsRect` and honors `contentsGravity` (`resize`, `resizeAspect`,
`resizeAspectFill` and `center`), blitting for both standalone sublayers and a
view's backing layer. `UIView.safeAreaInsets` reports the device top/bottom
insets for a root view (overridable through `IOSIM_SAFE_TOP`/`_BOTTOM`), and
the feedback generators are accepted no-ops because the framebuffer has no
haptic device. `CAReplicatorLayer`
renders its sublayers once into an offscreen buffer, then blits
`instanceCount` copies with the accumulated `instanceTransform` around the
layer's center; `instanceColor` tints the copies and the per-channel offsets
shift each successive copy. `CAEmitterLayer` renders a steady particle field:
each cell's particles sit on a repeating lifetime ring (`birthRate` times
`lifetime` slots), with deterministic per-particle angle (`emissionRange`),
velocity/range, acceleration, scale/range and RGBA speed/range variation from
a small LCG. Particles are clipped to the emitter frame and drawn as tinted
round dots, so no per-frame particle state has to be retained. Device RGB and gray
color spaces are singletons; `CGColorCreate` converts gray components to RGB
and `CGColorGetColorSpace` reports the originating space. Appearance is
device-wide: `UITraitCollection` carries the user interface style, display
scale and size classes; tint colors inherit down the view tree (a view with
no explicit tint asks its superview, ending at `UIColor.tintColor`), and
`setTintColor:`/`addSubview:` notify `tintColorDidChange` so controls such as
`UIButton` update their title color. `UIView` and `UIViewController` expose
`traitCollection`, `overrideUserInterfaceStyle` and
`traitCollectionDidChange:`, and an override applies to the view subtree.
`UIColor` supports dynamic colors (a provider block plus the system palette:
backgrounds, labels, separators, link and the system hues) whose components
resolve at draw time through a process-wide style, so `CGColor`, view and
layer backgrounds and text drawing all follow the current appearance.
SpringBoard owns `Library/SpringBoard/appearance.txt`; `iosimctl ui <device>
appearance light|dark` sends a type-18 event to whichever process is
foreground, which writes the file and updates its window tree, and
SpringBoard reloads the file when it regains the screen. Apps resolve the
file before building views, so a cold launch starts in the stored appearance.
The app status bar follows `UIApplication setStatusBarStyle:animated:` or the
deepest controller's `preferredStatusBarStyle`, walking
`childForStatusBarStyle` and navigation/tab children; a plain default style
picks black or white from the root view's background. `prefersStatusBarHidden`
(with `childForStatusBarHidden`), `setStatusBarHidden:animated:` and
Info.plist `UIStatusBarHidden` hide the time and glyphs, and
`UIViewControllerBasedStatusBarAppearance=NO` lets Info.plist
`UIStatusBarStyle` set the application-wide style before any controller.
SpringBoard's dock and search glass darken with the device appearance, and
`UIVisualEffectView`'s system material styles switch between light and dark
tints (thicker materials tint more strongly).
Paths support
bounding boxes, even-odd point containment, copies and rectangle
constructors. Quadratic and cubic curve entry points flatten adaptively:
the helper shared with UIBezierPath bounds the error by `max|B''| / (8 n^2)`
and picks `n` from the curve's second differences for a 0.25-point flatness
tolerance, collapsing straight curves to one segment and capping sharp ones
at 128. `CGPathApply`, `CGContextAddPath`, `CAShapeLayer` and UIBezierPath
all consume the same flattened points.
`CGGradient` keeps color components, locations and alpha per stop;
`CGContextDrawLinearGradient` projects each pixel onto the axis and
interpolates the surrounding stops, including their alpha, before blending
through the clip and mask. `CALayer.mask` renders the mask
layer into an offscreen pass, copies its alpha channel into an 8-bit
coverage mask positioned at the masked layer's origin, and pushes it onto the
framebuffer mask stack for the duration of the layer (or view) render, so
sublayers, contents, gradients, shapes and blended pixels all pick up the
mask. Coverage masks multiply with any active polygon or alpha mask, giving
nested masks and partial-alpha masks their expected cumulative effect.
Masks on standalone layers and on view backing layers are applied; a mask on
a view that is also rendered through the rotation offscreen path is not
folded into the rotated composite. `CAGradientLayer` carries the full color
array plus optional `locations`; the renderer builds stop values and alpha
from `CGColorRef` or `UIColor` entries, spaces them evenly when locations are
absent, and fills through the same multi-stop path CoreGraphics uses. A
gradient whose stops fade to transparent therefore works as a soft mask over
the layer tree, not just as a visible fill. Rounded
gradient layers render into an offscreen pass, mask their corners, and
composite back, so corner radii and layer alpha stay antialiased. A layer
`transform` (CATransform3D) uses the 2D submatrix m11/m12/m21/m22 plus the
m41/m42 translation: the layer is rendered into an offscreen pass and
composited with `blit_affine` around its center, so rotation, scale and
translation match the view-transform path. Perspective terms render through a
homography. `CAShapeLayer` strokes honor `strokeStart`/`strokeEnd` as
fractions of the outline's arc length: rectangles, rounded rectangles, ovals
and arbitrary paths are flattened to polylines and stroked by the shared
polyline helper, with `lineCap` selecting butt/round/square ends and
`lineJoin` selecting miter/round/bevel corners. `lineDashPattern` and
`lineDashPhase` (in points, scaled to device pixels) split the outline into
dashes; closed paths include their closing segment, and the trim values read
through `layer_key_value` so they can be animated. Path clipping is supported
through even-odd masks; P3 colors are converted to sRGB for rendering.

UIScrollView tracks recent pointer velocity while dragging instead of
averaging the whole gesture. A release above 50 pt/s records the deceleration
velocity, target and start time and adds the view to a small animation
registry; `iosim_scroll_tick` runs once per UI loop, integrates velocity over
the elapsed time, applies the 0.998-per-millisecond decay, clamps to the
scrollable bounds, honors paging/delegate targets and calls
`scrollViewDidScroll:` each step. It finishes at 25 pt/s, when a target is
reached, or after five seconds, then reports `scrollViewDidEndDecelerating:`.
The same registry eases `setContentOffset:animated:` over 300 ms with a
smoothstep curve and reports `scrollViewDidEndScrollingAnimation:`; setting
the offset directly cancels any running animation, and a new touch stops
momentum before recording the drag origin.

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

`NSLocale` stores its identifier and derives the language and country by
splitting at `_` or `-`; `objectForKey:` answers the identifier, language and
country constants, and `currentLocale` is `en_US`. `NSTimeZone` supports a
fixed table of eight zone names with their standard offsets plus
`timeZoneForSecondsFromGMT:` (named `GMT+1`, `GMT-8`, and so on).
`systemTimeZone` and `localTimeZone` read `TZ` and fall back to `GMT`;
daylight saving always reports off.

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

- **libdispatch** has a main queue drained from UIKit's run loop and from
  `NSRunLoop` (`iosim_dispatch_drain_main`), global queues backed by detached
  pthreads, groups, semaphores, `dispatch_once`, `dispatch_after` and its
  function variants, and a `dispatch_main` that honours Darwin's `noreturn`
  contract. Blocks are heap-copied when queued, so stack blocks stay valid
  after their frame returns.
  Dispatch sources start suspended, as on Darwin. Timer sources run from a
  monotonic-clock scheduler that coalesces a pending event and advances the
  next fire by the interval; data sources accumulate `ADD`, `OR` or
  `REPLACE` values until the handler's `dispatch_source_get_data` consumes
  them; read/write sources poll their descriptor on a dedicated thread.
  Cancelling stops scheduling, drops a queued event at delivery time and
  enqueues the cancel handler once. Event, cancel and registration handlers
  have both block and `_f` forms.
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
  other type. Every write bumps a persisted `changeCount`. `iosimctl
  pbcopy`/`pbpaste` read and write the same file from the host side. A
  running app polls the count on every main-loop tick and posts
  `UIPasteboardChangedNotification` when it moves, so a write from another
  process reaches live observers.

`tools/iosim-launchd` is the per-device boot anchor, state owner and bootstrap
namespace server.

### 2.10 Graphics and UIKit rendering

`loader/framebuffer.c` owns a 32-bit software framebuffer at the device's pixel
size. The renderer composites straight-alpha fills, SDF rounded rectangles,
circles and ellipses, anti-aliased scanline polygons, line strokes, linear
gradients (optionally rounded), and bilinear-scaled RGBA images. PNG files are
decoded with libpng in `loader/image.c`.

`frameworks/UIKit.m` maps the object model onto those primitives:

- `UIView` renders its background, its `CALayer` sublayers, then its subviews.
  `CALayer` derives `position` from the frame and `anchorPoint` (default
  0.5,0.5); `setPosition:`, `setAnchorPoint:` and `setBounds:` keep the
  position anchored, and a `UIImage` in `contents` is blit into the layer
  frame after its background and before its sublayers.
  `center` is derived from the frame, `setCenter:` moves the origin,
  `setBounds:` changes the size, and `convertPoint:/convertRect:` walk the
  superview chain adding frame origins and subtracting a scroll ancestor's
  content offset in both directions;
  `UIScrollView` shifts child origins by `contentOffset` after applying
  `contentInset`-based bounds; `UITableView` walks
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
  an explicit left item or `hidesBackButton` replaces it. A real `UIToolbar`
  at the bottom shows the top controller's `toolbarItems` when toolbar hiding
  is turned off, and its 49pt band is subtracted from the content view. The
  controller also
  vends a left-edge `UIScreenEdgePanGestureRecognizer` as
  `interactivePopGestureRecognizer` (disabled at depth one and when the bar is
  hidden). During a drag both the outgoing and previous controller's views
  stay in the hierarchy: the previous view slides in from a 30% left parallax
  under a 0.47 black overlay that fades with progress, while the outgoing view
  tracks the finger with a left-edge layer shadow. Releasing past halfway or
  with a rightward flick animates to a committed pop over the remaining
  fraction of 0.35 s; otherwise it animates back and leaves the stack alone.
- `UINavigationBar` and `UIToolbar` also stand alone as real views. The bar
  lays out the top item's title and left/right buttons across its own bounds
  and rebuilds them in `layoutSubviews`: `setItems:`, `pushNavigationItem:`
  and `popNavigationItemAnimated:` change the top item. The toolbar centers
  its items using 17 pt label widths plus 24 pt padding and 16 pt gaps, each
  item a `UIControl` that fires its `UIBarButtonItem` target. Both paint a
  translucent dark background with a one-pixel hairline in `drawRect:`.
- `UITabBarController` is a real container: it owns up to 16 view controllers,
  gives each a `UITabBarItem` (title and optional bundle image), and lays out a
  floating glass bar inset 16 pt from the sides, 64 pt tall, 12 pt above the
  home indicator. Each item is a `UIControl` with a label (and icon), so taps
  run through the normal tracking path; selecting an item swaps the content
  view behind the bar and retints the labels.
- `CAShapeLayer` stores a `UIBezierPath` (via `CGPath`) and draws its fill and
  stroke; `CAGradientLayer` interpolates up to two color stops; `UIImageView`
  blits a decoded image with aspect-fit or centered content modes.
- `CGContextAddArc`, `CGContextAddArcToPoint`, `CGPathAddArc` and
  `CGPathAddArcToPoint` tessellate arcs into line segments with a step count
  derived from the swept angle and radius. Angles follow the view coordinate
  system (x right, y down), so a clockwise arc sweeps through increasing
  angles; an arc connects a line from the current point to its start. The
  arc-to variant computes the two tangent points and the corner center from
  the incoming and outgoing rays, then sweeps the interior arc. UIBezierPath
  routes its arc method through the same normalization, so its `clockwise`
  flag now selects the short or long sweep instead of being ignored.
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
  clears every expanded child at once. `CASpringAnimation` evaluates a damped
  spring (`mass`, `stiffness`, `damping`, `initialVelocity`) and reports a
  settling duration derived from the damping ratio and natural frequency.
  `CAAnimation` also honors `beginTime` (an absolute media time that becomes
  a start delay), `speed`, `timeOffset`, `autoreverses` (a triangular sweep
  that ends at the start value) and a backwards/both `fillMode` that shows the
  start value during the delay. `CACurrentMediaTime` returns the runtime
  clock. `CATransaction` tracks begin/commit nesting and runs its completion
  block on the outermost commit; `UIView performWithoutAnimation:` and
  `setAnimationsEnabled:` execute animation blocks immediately with their
  completion handlers. `UIView animateKeyframesWithDuration:` queues each
  `addKeyframeWithRelativeStartTime:relativeDuration:animations:` block at
  its start time; the run loop executes it as an ordinary UIView animation,
  so each segment interpolates from the previous segment's settled values and
  the keyframe completion block fires after the total duration. A 2D
  affine transform is applied around the view center through an offscreen
  composite. UIView transform changes inside an animation block are captured
  like frame and alpha and interpolated by decomposing both endpoints into
  rotation, x/y scale and translation, sweeping the angle along the shorter
  arc (CoreAnimation's behavior) instead of blending matrix coefficients.
  `setCenter:` routes through `setFrame:` so center animations share the same
  path and completion accounting.

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
coordinates, descending from the window and removing each frame origin,
inverting each animating transform around its box center and adding scroll
offsets. `hitTest:` performs the same transform inversion on the point it
receives, so a rotated or scaled view is touchable over the area it paints
rather than its untransformed frame.

Records of the form `touch <id> down|move|up|cancel <x> <y>` carry a finger
identity. `UIWindow` keeps those touches in a dictionary, hit-tests each
finger separately and delivers a `UIEvent` whose `allTouches` contains every
live touch while the changed set holds only that finger.
`touchesForView:`/`touchesForWindow:` partition the live set. The single-touch
`down`/`move`/`up` records continue to drive gesture recognizers, controls and
scrolling through the primary-touch path.

`UIControl` tracks the touch: it highlights on down, sends `TouchDown`,
reports `TouchDragInside`/`TouchDragOutside` (and enter/exit transitions) as
the finger moves, then sends `TouchUpInside` or `TouchUpOutside` on release.
`UISlider` maps every down/move/up to its track, `UISwitch` toggles on release,
`UISegmentedControl` and `UIPageControl` select the segment or dot under the
release point, and `UITextField` becomes first responder on down.
`UIScrollView` drags update `contentOffset` with a rubber-band clamp derived
from `contentInset` (and the always-bounce flags); the same bounds feed
`setContentOffset:` and the touch-up snap. With `pagingEnabled`, release snaps
to the nearest page on the scrollable axis before the delegate's
`scrollViewWillEndDragging:withVelocity:targetContentOffset:` sees the target.
The drag delegate also receives begin, scroll and end callbacks, and
`isDragging`/`isDecelerating`/`isTracking` report state. Tap, pan, swipe,
pinch and rotation `UIGestureRecognizer` subclasses deliver target actions.
A `UIScreenEdgePanGestureRecognizer` is chosen before ordinary pans when the
touch begins inside the 20 pt strip along one of its screen edges. It stays
possible until the finger moves 10 pt, then wins over the scroll view's drag
for that touch and reports real finger velocity through
`velocityInView:`; a mostly vertical first move fails it and lets scrolling
proceed.
Two-finger `pinchN`/`rotateN` FIFO records carry both finger points (the
centroid in x/y, the other finger through `iosim_event_second_point`). The
window hit-tests the centroid, sends `Began`/`Changed`/`Ended` to every
pinch and rotation recognizer on the ancestor chain with the measured
distance ratio and angle delta, and lets a zooming `UIScrollView` on that
chain follow the same scale. `UIScrollView` zooming applies a scale
transform to the delegate's `viewForZoomingInScrollView:` view, resizes
`contentSize`, and keeps the content point under the bounds center fixed
across `setZoomScale:`, `zoomToRect:` and interactive pinches; the renderer
composites any non-identity view transform (rotation, scale or translation)
through an offscreen pass.
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
keyboard taps or `key`/`backspace` FIFO records. `UITextFieldDelegate`
receives should-begin/did-begin, should-end/did-end and
`textField:shouldChangeCharactersInRange:replacementString:` around every
mutation, and Return asks `textFieldShouldReturn:` before sending
`EditingDidEndOnExit` instead of inserting a newline. When a field is first
responder, `UIApplicationMain` paints a QWERTY keyboard over the app frame
with the same framebuffer primitives used for everything else. The keyboard
uses measured iOS 26 geometry: a 324 pt panel with 26 pt top corners, 43 pt
key rows on an 11 pt gap, 33.2 pt letters (32.2 pt on the shift row), 44.7 pt
shift/delete keys, a 24 pt predictive bar and measured return, shift, delete,
emoji and mic artwork.

`UITextView` shares the first-responder role. Touching an editable text view
focuses it and maps the touch to a byte index in the wrapped text; a second
tap within 350 ms selects the word under the finger. A touch held for half a
second without moving 10 points promotes to the same word selection through a
per-frame UI-loop tick, so no timer thread is involved. A drag continues from
the initial index (or from the selected word's start after a double tap or
long press):
`touchesMoved:` recomputes the index under the finger and selects the span
between it and the anchor, collapsing back to a caret when the finger
returns to the anchor, and `touchesEnded:` closes the drag.
`selectedRange` can be
set programmatically and is clamped to the text length. `insertText:`
replaces the selected range and `deleteBackward:` removes it (or the
character before a collapsed caret). The return key inserts a newline instead
of ending editing, which `UITextField` does. The renderer wraps the stored
text preserving spaces (breaking at the last space that fits), paints a
selected-range highlight behind the text, draws the caret at the selection
end and, for a non-empty selection, draws the two handle stems and knobs at
the span's start and end lines. A touch that lands within 14 points of a knob
grabs it: dragging the start knob moves the selection start and dragging the
end knob extends or shrinks the end, sampling the index on the handle's line
rather than under the knob itself. A double tap or long press also raises the
`UIMenuController` edit menu: the controller stores a target rect in the text
view, the renderer lays out a 38 pt dark panel above the selection with a
Copy and a Paste item, and a tap on the panel is consumed before the view
hit-test, invokes the item's action on the first responder, and hides the
menu. `copy:` writes the selected bytes to the shared pasteboard and
`paste:` inserts its string. Hardware input reaches both views through
`ui key` records, which
`iosimctl` emits per character (`key return` for a newline, `key space` for a
space) and `ui backspace`; the on-screen keyboard taps use the same edit
methods.

`UIAlertController` presents alert-style modals in the iOS 26 form measured
from the reference capture: a bottom-biased 320 pt floating card with 33.7 pt
corners, left-aligned title and message, and side-by-side pill actions. The
dimming view is painted at the measured 0.47 black and the status bar is
redrawn above it, matching the reference. Action blocks are copied to the heap
with `_Block_copy`, run on tap, then the modal dismisses through the same
presentation stack as any other controller. A shared layout pass computes the
card and one rectangle per action for both drawing and hit testing: alerts
keep the side-by-side pair or stack every row bottom-aligned, so three or
more actions are all tappable, while
`UIAlertControllerStyleActionSheet` anchors a full-width card above the home
indicator, uses stacked rows and renders the `Cancel`-style action as a
separate card 8 pt below the group; a tap outside the sheet dismisses it. Non-alert controllers present as
page sheets: `presentViewController:animated:` records a 0.35 s start time and
the renderer slides the controller up from the bottom over a 0.47 black dim
while `iosim_modal_tick` keeps the loop redrawing; `dismiss...Animated:` keeps
the controller in a dismissing slot and slides it back down before clearing
it. `modalPresentationStyle` can request full-screen presentation, which
skips the dim. Alerts keep their measured form and their own dim.

`UIActivityViewController` draws the share sheet as a floating bottom card
over the same 0.47 dim: a 34 pt rounded card inset 8 pt from the screen
sides and bottom, a grabber, a 44 pt content preview (a text page, a URL
page or the item's image) with a bold title and a type subtitle, a circular
close button, one 58 pt row per available activity with a 32 pt icon and a
separator, and a pill Cancel button. The list is built once from application
activities that accept the items plus the built-in Copy action, filtered by
`excludedActivityTypes`; Copy resolves an `UIActivityItemSource` through
`itemForActivityType:` before writing the general pasteboard. The sheet
slides on the modal progress, lays its rows out at draw time, and routes
taps through the drawn rectangles: a row calls
`prepareWithActivityItems:`/`performActivity`, `activityDidFinish:` reports
the activity type and completion to `completionWithItemsHandler`, the close
and Cancel buttons report a nil activity with `completed = NO`, and a tap on
the dimmed area cancels.

`UIContextMenuInteraction` (with `UIContextMenuConfiguration`, `UIMenu` and
`UIAction`) adds context menus. A stationary touch held for 0.5 s asks the hit
view's interactions first, then a table row or collection item delegate, for
a configuration. When one is returned the framebuffer behind is captured,
box-blurred and dimmed 22 %, the source row, item or view is re-rendered or
snapshotted as a lifted 14 pt-corner preview with a shadow, and the menu's
actions (with section headers, destructive red and disabled gray) draw in a
22 pt rounded card below it. Tap routing uses the draw-time row rectangles,
runs the action handler and dismisses; a tap outside or a new touch dismisses
without running anything. The lift that ends the opening long press keeps the
menu open.

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

Notification requests cross the process boundary through the shared device
data, because SpringBoard must show them while the app that scheduled them is
suspended. `UserNotifications.framework` keeps the center's pending and
delivered lists in the app process and writes one escaped text file per request
under
`Library/SpringBoard/notifications/` in the shared resources directory
(bundle, identifier, fire epoch, repeats, interval, title, subtitle, body).
A main-queue timer fires due requests in the app: it checks that the file still
exists (SpringBoard removes it when it takes ownership), re-arms a repeating
request by rewriting its fire time, and calls the delegate's
`willPresentNotification:` with the presentation options. SpringBoard scans the
same directory every 200 ms from its event loop. A due request becomes a
delivered entry (newest first, capped at 16) and a banner: a blurred capture of
the screen under the banner rect, a dark tinted card at (8, 58) pt with the
app's icon, name, relative time, title and body, and a 0.28 s ease-out slide
driven by the tick, since the shell otherwise draws only for events. The banner
auto-dismisses after 5 s; a swipe up inside it dismisses it early. A top-edge
drag left of the top-right corner opens Notification Center instead: a
full-screen blurred capture under a 42 % black dim, the 62 pt clock and real
date, and the delivered cards from y = 198 pt. Tapping a banner or card writes
`Library/SpringBoard/notification-response.txt` (bundle, identifier, action,
title, body), removes that entry from the delivered list, and launches or
resumes the app. The app's center polls the response file every 250 ms and calls
`userNotificationCenter:didReceiveNotificationResponse:withCompletionHandler:`
once its delegate exists, which is how a tap that happened while the process
was stopped still reaches the app after it resumes.

Categories registered with `setNotificationCategories:` are mirrored to
`Library/SpringBoard/notification-categories.txt`: a `category=` line, then one
`action=identifier|title|options` line per action and an `end` terminator, with
`|` and newlines escaped. SpringBoard reloads that file with every schedule
scan. A banner whose request names a registered category grows one 44 pt row
per action when it is long-pressed (0.45 s without movement); tapping a row
writes that action identifier into the response file instead of the default
action identifier, and destructive actions are drawn in red. Notification
Center cards expand the same way into a dark action sheet below the card. A
request can also carry a badge count: delivery rewrites
`Library/SpringBoard/badges.txt` (`bundle|count` lines) and updates the home
icon's red count badge, and the `applicationIconBadgeNumber` setter writes the
same store, so a response delegate can clear the badge from inside the app.
Delivered notifications are also drawn on the lock screen as cards from
y = 470 pt; tapping one unlocks the phone and opens its app through the same
response handoff.

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
- `libdispatch` covers main/global queues, groups, semaphores, timers and
  read/write/data sources. Foundation is a subset (strings, collections,
  sorting, predicates, scanner, regex, numbers, data, notifications, timers,
  dates, errors, bundles, defaults, plists, file manager, URLs, JSON and
  HTTP/HTTPS NSURLSession); it is not the full Foundation. HTTPS requires an
  OpenSSL build and verifies certificates through the system trust store;
  regexes are POSIX ERE with common ICU escapes translated, not
  full ICU syntax. `NSUserDefaults` persists XML property lists under
  `$HOME/Library/Preferences`; binary property lists are not parsed.
- Auto Layout is a relaxation solver over anchors and guides, not Cassowary;
  it does not cover every UIKit layout API or content-size class.
- Text input is `UITextField` and `UITextView` with caret positioning,
  programmatic/double-tap selection and selected-range editing; selection
  handles, drag selection and the full multitap gesture set are absent.
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
`UIViewPropertyAnimator` is a thin state machine over the existing UIView
animation engine: `startAnimation` schedules the animation blocks and a
completion, `finishAnimationAtPosition:` settles immediately, and pause/stop
only change the reported state. Block copy promotes `__block` storage to a
refcounted heap byref, so asynchronous blocks keep their captured state after
the creating frame returns.
Custom modal transitions are a small context object plus delegate dispatch:
`presentViewController:` and `dismissViewControllerAnimated:` ask the
transitioning delegate for an animator, build a
`_UIViewControllerTransitionContext` with the from/to controllers and the
presenting view as container, and let the animator call
`completeTransition:`. The standard page-sheet path remains the fallback.
`UIPresentationController` owns the container/presented views and the
presentation-style query; custom transitions ask the transitioning delegate
for one, set its container and controller pointers, and bracket the animator
with the four transition lifecycle methods. The default `presentedView` is the
presented controller's view.
If the transitioning delegate returns an interactive driver, the transition
context goes to `startInteractiveTransition:` rather than directly to the
animator; the driver is responsible for driving and completing it.
`NSOrderedSet` is an insertion-ordered array with unique membership; its
mutable subclass adds insert/remove/replace and indexed subscripting.
`UIViewController` implements `UIContentContainer`; preferred-content-size
changes propagate upward through the parent controller chain.
Size transitions are detected in `viewWillLayoutSubviews` by comparing the
view size to the last one; a `_UIViewControllerTransitionCoordinator` carries
the container, controllers and duration, and the default
`viewWillTransitionToSize:` fans out to child controllers.
`NSIndexPath` holds a small fixed index vector with row/section and
item/section constructors; equality and ordering compare the vector
lexicographically.
Display-P3 colors carry a flag on `UIColor`; `ui_components:` converts their
RGB to sRGB through the linear P3→sRGB matrix and the sRGB transfer curve, so
every framebuffer/CGColor path renders in the software framebuffer's sRGB
space while `getRed:` still reports the original components.
`NSCountedSet` keeps a count beside each unique member in the inherited set
array.
`NSProgress` is a unit-count state object with copied cancellation, pausing
and resuming handlers; hierarchy registration and publishing are no-ops.
`NSOperationQueue` dispatches each operation into its dispatch group; the
operation's block waits on `isReady` (all dependencies finished or cancelled)
before calling `start`, which marks it finished and runs its completion.
A 3D `CALayer.transform` builds a 3x3 homography from the row-vector
CATransform3D, including the m34 perspective term applied to the rotated z
coordinate, and renders through `iosim_fb_blit_homography`; 2D-only matrices
stay on `iosim_fb_blit_affine`.
`UICollectionView` registers supplementary classes by element kind, asks its
data source for a header/footer view at the section's zero item path, and
places it at the flow layout's `headerReferenceSize`/`footerReferenceSize`
band while accumulating the same cursor used by hit testing.
`UIApplication` stores background tasks as `[token, handler]` pairs. Entering
the background sets a five-second deadline and polls the task list while
worker queues run; `endBackgroundTask:` releases the handler and removes the
pair, and any pair left at the deadline has its handler invoked before
`iosim_suspend_self`.
`UISplitViewController` installs up to three column controllers (primary,
supplementary, secondary). Layout gives the primary its configured width, the
supplementary its own width clamped to the remainder, and the secondary
everything left; collapsed and secondary-only modes hide the extra columns.
Binary plists share the `NSPropertyListSerialization` entry points: the writer
flattens objects into a unique table, emits markers and refs, then an offset
table and 32-byte trailer; the reader trusts only the trailer's sizes, resolves
object refs through the offset table, and caps recursion depth.
`UIPasteboard.strings`, `URLs` and `colors` build items with their public type
keys and parse them back from the shared plist; `types` unions item keys and
`containsPasteboardTypes:` checks the union.
The loader exports both file and memory PNG decoders; UIKit's
`UIImage imageWithData:` uses the memory entry point, and the pasteboard
stores image items as `public.png` data.
Operation queue workers gate on `_suspended`, wait for `isReady`, then claim a
slot with an atomic compare-and-swap on `_running < _maxConcurrent`; the
unfinished-operation scan keeps `operationCount` accurate after work starts.
