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
| `objc_msgSend` ABI trampoline (integer + SSE args) | ✅ |
| Ivar layout realization (`__objc_ivar` offset variables) | ✅ |
| `objc_alloc_init`, autorelease pools, `sel_*`, `class_*` basics | ✅ |
| Reimplemented `UIKit.framework` / `Foundation.framework` in a runtime root | ✅ (lite) |
| `simctl`-style device lifecycle, boot, install, launch, spawn | ✅ |
| Scene lifecycle (`UIWindowScene`, `UISceneDelegate`) required by iOS 27 | ✅ |
| Software framebuffer, SF font rendering, UIKit view rendering | ✅ |
| Touch hit-testing, target/action, table selection, event FIFO run loop | ✅ |
| `UITouch`/`UIEvent` responder delivery, continuous control tracking | ✅ |
| Drag scrolling with rubber-band clamp, tap/pan/swipe gesture recognizers | ✅ |
| Auto Layout: NSLayoutConstraint, anchors, guides, intrinsic sizing, priorities | ✅ (subset) |
| Multiline UILabel wrapping, UITextField focus, caret and software keyboard | ✅ |
| UISwitch, UISlider, UISegmentedControl, UIPageControl, UIActivityIndicatorView, UIProgressView | ✅ |
| UIAlertController alerts, actions and modal presentation | ✅ |
| UINavigationController push/pop, UIStackView intrinsic layout, UIButton titles | ✅ |
| UIView animations (frame, alpha), CALayer backing/opacity/corner radius | ✅ |
| CoreAnimation paths, gradients, sublayers (z-ordered), PNG images | ✅ |
| Foundation collections, strings, notifications, timers, NSIndexPath | ✅ |
| libdispatch queues, groups, semaphores; main-queue drain from UIKit | ✅ |
| Mach ports/messages, bootstrap service registry, in-process XPC | ✅ |
| SpringBoard system UI: measured iOS 26 home screen, installed apps, real app launching | ✅ |
| UIView 2D affine transforms (translate/scale/rotate), layout callbacks, UIScrollView offsets | ✅ (basic) |
| Layer clipping (`clipsToBounds`/`masksToBounds`), shadows and borders | ✅ |
| Switch, slider, segmented, progress, page and activity controls in the iOS 26 glass design | ✅ |

The test suite exercises a real Apple-toolchain-built x86_64 UIKit app, a
Foundation app using `NSLog` with a constant `CFString`, an Objective-C app
with its own class, and a two-image dylib app. Three additional fixtures run
natively: a graphics app using `CAGradientLayer`, `CAShapeLayer` and
`UIImageView`; a `UITableView` app with a data source, reusable-style cells,
accessories and selection; an Auto Layout app using anchors, guides and a
multiline label; a text-input app with a software keyboard; a controls app
covering switch, slider, segmented control, progress, page control and
activity indicator; and a services test that round-trips Mach messages,
registers a bootstrap service, uses libdispatch queues/semaphores/groups and
sends an XPC dictionary between a listener and a client.

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
tools/iosimctl ui $UDID swipe 300 700 60 200 0.25  # down/moves/up in one call
tools/iosimctl ui $UDID home                     # scene backgrounds, home returns
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
sudo apt install clang lld cmake ninja-build libfreetype-dev
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
- [`docs/ROADMAP.md`](docs/ROADMAP.md) — path from this substrate to a usable
  simulator (graphics, events, services, frameworks).

## Legal / provenance

No Apple framework binaries are redistributed in this repository. The recon
workflows collect metadata and build test binaries with the public Xcode
toolchain; Apple's `dyld` source is used under its APSL license, and Darling is
referenced as GPL-3.0 prior art. The implementations here are original code
based on public interfaces and observed behavior.
