# iosim — a native x86_64 reimplementation of the iOS Simulator runtime

`iosim` runs iOS Simulator binaries natively on x86_64 Linux, without a CPU
emulator. It reimplements the pieces that make the simulator a simulator — the
Mach-O dyld layer, the Objective-C runtime substrate, the device lifecycle, and
the framework substitution model — rather than running Apple's arm64 runtime
under translation.

This repository is the result of reverse-engineering the public iOS Simulator
architecture and validating it against **Xcode 27.1 on GitHub's `xcode-27`
runners**, combined with the public Darling and Apple dyld sources.

## What works today

| Capability | Status |
|---|---|
| x86_64 iOS-simulator Mach-O executables (Apple clang/ld output) | ✅ runs natively |
| `LC_DYLD_CHAINED_FIXUPS` (PTR_64 / PTR_64_OFFSET, imports formats 1–3) | ✅ |
| Classic `LC_DYLD_INFO` rebase/bind opcode streams | ✅ |
| Fat binaries (x86_64 slice extraction) | ✅ |
| Recursive `LC_LOAD_DYLIB` loading, per-image slides, cross-image symbols | ✅ |
| `@loader_path`, `@executable_path`, `@rpath`, `DYLD_ROOT_PATH` substitution | ✅ |
| Darwin initial process stack / `LC_MAIN` crt entry | ✅ |
| Objective-C class metadata, `class_ro_t`, method lists | ✅ |
| `objc_msgSend` ABI trampoline (integer + SSE args), nil-receiver zero return | ✅ |
| Ivar layout realization (`__objc_ivar` offset variables) | ✅ |
| `objc_alloc_init`, autorelease pools, `sel_*`, `class_*` basics | ✅ |
| Reimplemented `UIKit` / `Foundation` / `QuartzCore` / `UserNotifications` frameworks in a runtime root | ✅ (lite) |
| `simctl`-style device lifecycle, boot, install, launch, spawn | ✅ |
| Scene lifecycle (`UIWindowScene`, `UISceneDelegate`) required by iOS 27 | ✅ |
| Software framebuffer, SF font rendering, UIKit view rendering | ✅ |
| Touch hit-testing, target/action, table selection, event FIFO run loop | ✅ |
| `UITouch`/`UIEvent` responder delivery, continuous control tracking | ✅ |
| Drag scrolling with rubber-band clamp, tap/pan/swipe/pinch/rotation/screen-edge gesture recognizers with pan velocity | ✅ |
| Auto Layout: NSLayoutConstraint, anchors, guides, intrinsic sizing, priorities, `layoutMargins`/`layoutMarginsGuide` with inset guide frames | ✅ (subset) |
| Appearance: `UITraitCollection`, `overrideUserInterfaceStyle`, `traitCollectionDidChange:`, dynamic system colors resolved at draw time, the fixed UIColor palette plus `getRed:green:blue:alpha:`/`getWhite:alpha:`, tint-color inheritance and `tintColorDidChange`, status bar styles and hiding (including Info.plist), appearance-aware system material blur, and device-wide light/dark switching that also darkens SpringBoard's glass | ✅ |
| Multiline UILabel wrapping, UITextField/UITextView editing and delegates, UITextView drag selection, long press, draggable handles and a Copy/Paste edit menu, software keyboard | ✅ |
| UISwitch, UISlider, UISegmentedControl, UIPageControl, UIActivityIndicatorView, UIProgressView | ✅ |
| UIAlertController alerts and actions with text fields and preferred actions, UIActivityViewController share sheet with Copy and application activities, animated page-sheet modal presentation and dismissal | ✅ |
| UINavigationController push/pop and interactive edge-pan pop transition, UITabBarController, UIStackView, standalone UINavigationBar/UIToolbar with item targets/images/custom views, UIButton titles/images, `UIButtonConfiguration`, button content/title/image edge insets, UITextField border styles and left/right views, navigation large-title/bar-button array properties | ✅ |
| UIView animations (frame, alpha, transform), delay/curve/repeat options, completion blocks | ✅ |
| `CADisplayLink`, presentation layers, multiple concurrent layer animations | ✅ |
| `CAAnimationGroup`: grouped opacity/corner animations, group removal clears children | ✅ |
| `CASpringAnimation`: mass/stiffness/damping/initial velocity, settling duration | ✅ |
| CAAnimation timing (`beginTime`, `speed`, `timeOffset`, `autoreverses`, `fillMode`) and value getters, `CAAnimationDelegate` start/stop callbacks, `animationKeys`/`animationForKey:`/`removeAllAnimations`, `CACurrentMediaTime`, `CATransaction` completion, `performWithoutAnimation:` | ✅ |
| UIView keyframe animations: relative start/duration segments and a completion block | ✅ |
| `NSString` `sizeWithAttributes:`, `boundingRectWithSize:`, `drawAtPoint:`/`drawInRect:` wrapping through CGContext | ✅ (subset) |
| ObjC categories from `__objc_catlist`, resolved by category symbol name | ✅ |
| CoreAnimation paths, multi-stop axial/radial gradients (including custom `+[UIView layerClass]` backing), layer geometry/contents (`contentsGravity` aspect fit/fill/center, `contentsRect` cropping), CALayer masks, 2D CATransform3D layer transforms, shape stroke trimming and round caps, sublayers (z-ordered), PNG images, `CAReplicatorLayer` copies with instance transforms/colors, `CAEmitterLayer` steady particle fields with emission/velocity/scale/color ranges | ✅ |
| CoreGraphics `CGContext` fills, strokes, ellipses, paths, adaptively flattened quadratic/cubic curves, mutable `CGPath` (bounding box/contains/copies), `CGColor`, device RGB/gray `CGColorSpace`, multi-stop `CGGradient` linear fills with alpha stops, `CGImage`, rect and polygon clipping, push/pop contexts, state stack, UIView `drawRect:` and `UIGraphics` image contexts | ✅ (subset) |
| `UIGraphicsImageRenderer` with format scale/opaque, `imageWithActions:`, `PNGDataWithActions:`, and `UIImagePNGRepresentation` using stored-deflate PNG output | ✅ |
| `UIViewPropertyAnimator` with duration, state, fraction, added animations/completions and start/stop/finish control, `NSAttributedString`/`NSMutableAttributedString` with `UILabel.attributedText` and `UIButton` attributed titles, view controller containment (`addChildViewController:`, `children`, `parentViewController`), `UIPageViewController` page replacement, `UISplitViewController` double-column layout with collapse, display modes and delegate callbacks, navigation-controller toolbar with `toolbarItems`, modal transition style and bottom-bar hiding properties, `UIView.maskView` (masked by the view's layer alpha), `userInteractionEnabled` hit-test passthrough, `safeAreaInsets` with controller `additionalSafeAreaInsets`, `UIScreen` native bounds/scale/brightness, `idleTimerDisabled`, UIFeedbackGenerator family (no-op haptics), `UIApplication` `canOpenURL:`/`openURL:options:completionHandler:`, `windows`/`keyWindow`/`connectedScenes`, `UIWindow.windowScene`/`windowLevel`, `UIPopoverPresentationController`/`UISheetPresentationController` configuration objects, `UISceneSession` and `UIWindowScene.windows`, UIView transition helpers | ✅ |
| Foundation collections, sorting, NSPredicate filtering, NSRegularExpression, NSScanner, notifications, timers, `NSCharacterSet` with string trimming/number/percent/range helpers, UIFont weights/named fonts/descriptors/preferred text styles, UIColor HSV/P3/alpha constructors, NSURL scheme/host/port/path/query parsing and NSURLComponents/NSURLQueryItem, NSValue (points, sizes, rects, transforms, ranges, pointers), NSIndexSet/NSMutableIndexSet with range enumeration, NSData base64, NSUUID, NSProcessInfo, percent encoding/decoding, ISO-8601 date formatting, empty `@[]`/`@{}` literals, readable content guides and UIView layout properties | ✅ |
| Foundation fast enumeration (`for-in`) and indexed/keyed collection subscripting | ✅ |
| `NSURLSession` data tasks with headers, bodies, status and response headers over a host HTTP/1.0 client, including HTTPS via OpenSSL | ✅ |
| Key-value coding (accessors, boxing, key paths, collection operators) and automatic KVO | ✅ |
| NSDateFormatter parse/print round trip, NSNumberFormatter decimal/currency/percent | ✅ |
| KDK kernel symbolication: full local+global maps, Mach trap and BSD syscall tables | ✅ |
| `NSFileManager`, `NSData` file I/O, `NSFileHandle` read/write/seek/truncate, `NSURL`, `NSJSONSerialization` | ✅ |
| `NSPropertyListSerialization` and persistent `NSUserDefaults` domains | ✅ |
| `NSKeyedArchiver`/`NSKeyedUnarchiver` keyed archives with custom `NSCoding` classes | ✅ |
| NSRunLoop timers and delayed performs, NSThread main-thread check and sleep | ✅ |
| NSCalendar/NSDateComponents Gregorian decomposition and construction | ✅ |
| NSOperationQueue/NSBlockOperation over dispatch groups | ✅ |
| App bundle resources: `NSBundle` lookup and `UIImage imageNamed:` PNGs | ✅ |
| libdispatch queues, groups, semaphores, timer/data sources; UIKit and run-loop drain | ✅ |
| Mach ports/messages with refcounted rights, launchd bootstrap namespace, cross-process messaging | ✅ |
| Mach-O initializers (`__init_offsets`, `__mod_init_func`), thread-local variables, Darwin pthread normalization | ✅ |
| Darwin ABI translation: `stat$INODE64`, `open` flags, signals, CommonCrypto, `dispatch_data` | ✅ |
| Unmodified macOS x86_64 CLIs: Apple Metal Shader Converter DXIL→metallib, end to end | ✅ |
| XPC peer connections, async/sync request-reply and serialized dictionaries across processes | ✅ |
| launchd_sim LaunchDaemon plists: RunAtLoad, on-demand MachServices jobs, KeepAlive | ✅ |
| launchd socket activation: `Sockets` listeners, `launch_activate_socket`, on-demand restart | ✅ |
| UIPasteboard general pasteboard shared across processes, with changeCount | ✅ |
| SpringBoard system UI: measured iOS 26 home screen, installed apps, real app launching | ✅ |
| Real app suspension: home stops the process, the icon resumes it in place | ✅ |
| Application/scene lifecycle callbacks, notifications and UIApplication state | ✅ |
| App switcher: bottom-edge gestures, cached frames, resume, swipe-up kill | ✅ |
| Multi-page home screen: 16-slot pages, page dots, horizontal swipe paging | ✅ |
| Home-screen folders: drag to group apps, member launch, persisted across boots | ✅ |
| Lock screen: date and clock, lock/unlock, apps suspend on lock and resume in place | ✅ |
| Spotlight search: pill opens a keyboard-driven search over installed apps | ✅ |
| Control Center: top-right drag, connectivity toggles, media, brightness/volume and utilities | ✅ |
| `UserNotifications.framework`: authorization and settings, time-interval requests and repeats, foreground delivery and delegate callbacks | ✅ |
| System notification banners: due-request scanning, blurred card with app icon, slide-in, auto-dismiss and swipe-up dismissal | ✅ |
| Notification Center: top-edge drag, blurred backdrop, clock and date, delivered cards, tap-to-open response handoff | ✅ |
| Notification actions: `UNNotificationAction`/`UNNotificationCategory`, long-press expanded banners and Notification Center action sheets, destructive styling and action identifiers in the response | ✅ |
| Icon badges: `applicationIconBadgeNumber`, shared badge store, red count badge on the home icon, cleared by the response | ✅ |
| Lock screen notifications: delivered cards above the controls, tap unlocks and opens the notification's app | ✅ |
| UIView 2D transforms (rotation and scale) with decomposed animation interpolation and transform-aware hit-testing/location conversion, center/bounds/point conversion, UIScrollView insets/paging/zoom/delegate, momentum and animated offsets | ✅ |
| Layer clipping (`clipsToBounds`/`masksToBounds`), shadows and borders | ✅ |
| UIVisualEffectView backdrop blur: capture, box blur, tint, rounded mask, contentView | ✅ |
| Switch, slider, segmented, progress, page and activity controls in the iOS 26 glass design | ✅ |
| Floating glass tab bar with per-item targets and content swapping | ✅ |
| UICollectionView flow layout, multiple sections, reusable cells, selection, drag scrolling, prefetch/drag/drop configuration, visible-cell queries | ✅ |
| UITableView sections, headers, per-row heights, selection, swipe-to-delete and editing mode, separator/background/refresh configuration and estimated heights | ✅ |
| UILongPressGestureRecognizer duration, movement tolerance and state changes | ✅ |
| UIContextMenuInteraction context menus on table rows, collection items and views: blurred backdrop, lifted preview, action menus | ✅ |
| UIBarButtonItem/UINavigationItem, right bar buttons and automatic back button | ✅ |
| UISearchBar with delegate edits, Return action, Cancel and keyboard focus; UISearchController with results updater, active state and scope properties | ✅ |
| UIDevice model/system/orientation/battery surface, UIAccessibility element storage and query functions, gesture recognizer delegate/touch/delay properties | ✅ |
| UIStepper plus/minus halves, stepping, limits and ValueChanged | ✅ |
| UIPickerView wheels: data source components, titles, tap/drag selection with snapping | ✅ |
| UIDatePicker date, time and combined wheels with calendar-accurate dates | ✅ |
| UIRefreshControl pull-to-refresh with a spinning control and ValueChanged | ✅ |

The test suite exercises a real Apple-toolchain-built x86_64 UIKit app, a
Foundation app using `NSLog` with a constant `CFString`, a Foundation
file/URL/JSON app that creates directories, round-trips files and parses
compact JSON, an Objective-C app with its own class, and a two-image dylib
app. Three additional fixtures run
natively: a graphics app using `CAGradientLayer`, `CAShapeLayer` and
`UIImageView`; a `UITableView` app with a data source, reusable-style cells,
accessories and selection; an Auto Layout app using anchors, guides and a
multiline label; a text-input app with a software keyboard; a controls app
covering switch, slider, segmented control, progress, page control and
activity indicator; a touch fixture that drives `UITouch` through a custom
view, slider, switch and button from injected gestures; an animation fixture
whose `CADisplayLink` moves a view while a delayed UIView animation runs and
a keyframe animation pulses a layer; and a services test that round-trips Mach
messages, registers a bootstrap service, uses libdispatch
queues/semaphores/groups and sends an XPC dictionary between a listener and a
client; a cross-process fixture where XPC clients reach a listener peer and
receive both an async and a synchronous reply; launchd jobs installed from
LaunchDaemon plists, one started on demand by a MachServices lookup and one
on RunAtLoad, both answering XPC clients; and another where one guest process
registers a Mach service with launchd and another looks it up and delivers a
message over it.

```sh
DYLD_ROOT_PATH=$PWD/runtime ./build/iosim-run build/binaries/services_test_x86_64
# dispatch, Mach, bootstrap and XPC lines, then: services: done

# The system UI is a real process: launchd boots SpringBoard, SpringBoard
# enumerates the apps installed on the device and launches them on tap.
tools/iosimctl create "Phone" com.iosim.SimDeviceType.iPhone-18-Pro   # -> UDID
tools/iosimctl boot $UDID
tools/iosimctl install $UDID MyApp.app
tools/iosimctl io $UDID screenshot home.png      # SpringBoard home screen
tools/iosimctl ui $UDID tap 339.8 222.2          # point coordinates
tools/iosimctl io $UDID screenshot app.png       # the app's own frame
tools/iosimctl ui $UDID down 40 525              # finger down, in points
tools/iosimctl ui $UDID move 360 525             # moves track the finger
tools/iosimctl ui $UDID up 360 525               # up completes the touch
tools/iosimctl ui $UDID key a                    # hardware key, appends to the text view
tools/iosimctl ui $UDID backspace                # deletes backward
tools/iosimctl ui $UDID swipe 300 700 60 200 0.25  # down/moves/up in one call
tools/iosimctl ui $UDID drag 339.8 222.2 62.2 322.5 # long-press then drag an icon
tools/iosimctl ui $UDID home                     # scene backgrounds, home returns
tools/iosimctl ui $UDID lock                     # lock screen; apps suspend
tools/iosimctl ui $UDID unlock                   # resume the foreground app
tools/iosimctl launchd-load $UDID MyJob.plist    # install + load a LaunchDaemon job
tools/iosimctl shutdown $UDID

# The same SpringBoard binary can be run directly for UI work:
IOSIM_SHELL=1 DYLD_ROOT_PATH=$PWD/runtime IOSIM_FONT_DIR=$PWD/build/fonts/ios \
  SIMULATOR_MAINSCREEN_WIDTH=1206 SIMULATOR_MAINSCREEN_HEIGHT=2622 \
  ./build/iosim-run runtime/System/Library/CoreServices/SpringBoard.app/SpringBoard
```

**Same-app parity:** one `HelloSimApp.m` compiled by Apple clang, run on the
real iPhone 18 Pro simulator (arm64) and natively under iosim (x86_64). The
full-screen screenshots differ by a mean of 0.79/255 per channel, with 99.34 %
of pixels inside a 24/255 tolerance. See
[`docs/VERIFICATION.md`](docs/VERIFICATION.md).

## Quick start

```sh
sudo apt install clang lld cmake ninja-build libfreetype-dev libssl-dev
cmake -S . -B build -G Ninja
cmake --build build
./tools/build_runtime.sh     # builds UIKit/Foundation-lite into ./runtime
./tests/run_tests.sh
```

Build a demo without an Apple SDK, using the stub UIKit header and the same
Mach-O toolchain as the runtime:

```sh
./tools/build_app.sh demo/ListApp.m build/ListApp
DYLD_ROOT_PATH=$PWD/runtime IOSIM_FONT_DIR=$PWD/build/fonts/ios \
  SIMULATOR_MAINSCREEN_WIDTH=1206 SIMULATOR_MAINSCREEN_HEIGHT=2622 \
  SIMULATOR_MAINSCREEN_SCALE=3.0 IOSIM_SCREENSHOT_PATH=$PWD/build/list.png \
  ./build/iosim-run build/ListApp
```

With a Zig 0.17+ installation, the bundled clang and Mach-O linker can build
Foundation guests without an Apple SDK:

```sh
ZIG=/path/to/zig ./tools/build_app_zig.sh tests/fastenum_test.m build/fastenum-zig
DYLD_ROOT_PATH=$PWD/runtime ./build/iosim-run build/fastenum-zig
```

Run any binary directly:

```sh
DYLD_ROOT_PATH=$PWD/runtime ./build/iosim-run -v path/to/AppBinary
```

Drive a simulated device:

```sh
export IOSIM_HOME=$HOME/.iosim
export IOSIM_RUNTIME_ROOT=$PWD/runtime
UDID=$(./tools/iosimctl create "iPhone" com.iosim.SimDeviceType.iPhone-18-Pro)
./tools/iosimctl boot $UDID
./tools/iosimctl install $UDID MyApp.app
./tools/iosimctl launch --console $UDID com.example.myapp
./tools/iosimctl shutdown $UDID
```

## Layout

```
loader/            native ELF Mach-O loader and runtime substrate
  macho.c          Mach-O/fat parsing, mapping, slides
  fixups.c         chained fixups + classic dyld opcodes
  context.c        recursive dylib loading and cross-image resolution
  objc_runtime.c   class registration, ivar layout, dispatch
  start.S          Darwin stack entry + objc_msgSend trampoline
  shims.c          libSystem/Foundation/UIKit Darwin-ABI shims
frameworks/        reimplemented UIKit/Foundation sources
runtime/           generated runtime root (canonical simulator paths)
tools/             iosimctl, iosim-launchd, runtime builder
recon-runner/      GitHub Actions workflows used against Xcode 27 runners
docs/              architecture, recon evidence and roadmap
tests/             end-to-end tests
```

## Documentation

- [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md) — how the real simulator is
  built, and how iosim mirrors it.
- [`docs/RECON-XCODE27.md`](docs/RECON-XCODE27.md) — measured facts from the
  Xcode 27.1 runners, including the full captured simulator environment.
- [`docs/VERIFICATION.md`](docs/VERIFICATION.md) — same-app parity against the
  real iOS 27 simulator, with pixel measurements.
- [`docs/KDK.md`](docs/KDK.md) — unpacking a Kernel Debug Kit and fully
  symbolicating its x86_64 kernel, including the XNU trap and syscall tables.
- [`docs/METAL-SHADER-CONVERTER.md`](docs/METAL-SHADER-CONVERTER.md) — running
  Apple's x86_64 Metal Shader Converter natively, from DXIL to a `.metallib`.
- [`docs/RESEARCH-NOTES.md`](docs/RESEARCH-NOTES.md) — running notes for
  artifacts, measurements and open directions.
- [`docs/ZIG.md`](docs/ZIG.md) — optional Zig guest toolchain and the
  alternate Zig inline-assembly TLV getter.
- [`docs/ROADMAP.md`](docs/ROADMAP.md) — path from this substrate to a usable
  simulator (graphics, events, services, frameworks).

## Legal / provenance

No Apple framework binaries are redistributed in this repository. The recon
workflows collect metadata and build test binaries with the public Xcode
toolchain; Apple's `dyld` source is used under its APSL license, and Darling is
referenced as GPL-3.0 prior art. The implementations here are original code
based on public interfaces and observed behavior.
