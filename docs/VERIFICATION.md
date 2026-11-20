# Same-app parity check: real simulator vs iosim

The strongest check we have is one unmodified app source compiled by Apple's
toolchain, run twice:

1. **arm64** app on the real iPhone 18 Pro / iOS 27.2 simulator, via the
   `same-app` GitHub Actions workflow on an `xcode-27` runner.
2. **x86_64** slice from the *same Apple clang invocation* on `demo/HelloSimApp.m`,
   run natively under `iosim` on Linux with `DYLD_ROOT_PATH` pointing at our
   reimplemented UIKit/Foundation.

No source or layout difference exists between the two; only the CPU
architecture and the framework provider differ.

## Reproduce

On the runner (`.github/workflows/same-app.yml`):

```sh
SDK=$(xcrun --sdk iphonesimulator --show-sdk-path)
CFLAGS="-mios-simulator-version-min=18.0 -isysroot $SDK -O1 -fno-objc-arc \
        -Wno-deprecated-declarations -I demo"
xcrun clang -arch arm64  $CFLAGS -framework UIKit -framework Foundation \
    demo/HelloSimApp.m -o HelloSim_arm64
xcrun clang -arch x86_64 $CFLAGS -framework UIKit -framework Foundation \
    demo/HelloSimApp.m -o HelloSim_x86_64
```

The workflow installs `HelloSim_arm64` in a `HelloSim.app` bundle, launches it,
and saves `real-sim.png` (1206×2622). It also uploads `HelloSim_x86_64`, the
runtime font files, and logs.

Locally:

```sh
./tools/build_runtime.sh
# fonts extracted from the iOS 27 runtime (not redistributed here)
export IOSIM_FONT_DIR=$PWD/build/fonts/ios
DYLD_ROOT_PATH=$PWD/runtime IOSIM_FONT_DIR=$PWD/build/fonts/ios \
  SIMULATOR_MAINSCREEN_WIDTH=1206 SIMULATOR_MAINSCREEN_HEIGHT=2622 \
  SIMULATOR_MAINSCREEN_SCALE=3.0 IOSIM_SCREENSHOT_PATH=$PWD/build/iosim.png \
  ./build/iosim-run path/to/HelloSim_x86_64
```

## Result

Measured over the full 1206×2622 frame:

| Metric | Value |
|---|---|
| Mean absolute channel error | **0.79 / 255** |
| Pixels with max-channel error > 8 | **0.82 %** |
| Pixels with max-channel error > 24 | **0.66 %** |
| Layout bounding boxes | equal within 1 px (text baselines, card, button, rows) |
| Background / card / subtitle / footer colors | byte-identical |
| `systemBlue` in iOS 27 dark mode | `(0, 145, 255)` — matched |

The remaining difference is confined to glyph-edge anti-aliasing and the
sub-pixel shape of the Wi-Fi/battery status icons, plus a one-pixel baseline
offset on one label.

## What made the match possible

- **Mach-O / dyld**: the x86_64 slice still uses chained fixups, `LC_LOAD_DYLIB`
  references to `UIKit.framework` / `Foundation.framework`, libSystem and
  libobjc; `DYLD_ROOT_PATH` substitutes our dylibs at the canonical paths.
- **Objective-C**: classes, protocols and categories emitted by Apple clang are
  registered from `__objc_classlist`; `class_ro_t`, property setters
  (`objc_setProperty_nonatomic`), `objc_opt_class`, ivar offset realization and
  the `objc_msgSend` trampolines all had to match Apple's ABI.
- **Scene lifecycle**: iOS 27 no longer tolerates a legacy `UIApplicationMain`
  app delegate window. It traps in
  `UIApplicationEvaluateRuntimeIssueForNoSceneLifecycleAdoption`. The app now
  declares a `UIApplicationSceneManifest`, a `SceneDelegate`, and a
  configuration method; UIKit-lite creates `UIWindowScene`, `UISceneSession`
  and drives `scene:willConnectToSession:options:`.
- **Text**: the runtime ships `SFUI.ttf`, a variable font with `wght`, `opsz`,
  `wdth` and `GRAD` axes. `iosim` loads it with FreeType, sets those axes per
  label, applies system-font tracking measured against UIKit, and draws into
  the software framebuffer at 3×.
- **Colors and chrome**: UIKit's dark `systemBlue` and the status bar
  (time, cellular placeholders, Wi-Fi, battery) were measured from the real
  screenshot. The captured frame contains no Dynamic Island or home indicator,
  so iosim does not draw them either.

## Beyond the first app

Three more fixtures use the same build path — one source, Apple clang, arm64 for
the simulator and x86_64 for iosim.

### Rendering: gradients, paths and images

`demo/GraphicsApp.m` draws a two-stop `CAGradientLayer`, a filled and stroked
`CAShapeLayer` chart built from `UIBezierPath`, and a PNG loaded through
`UIImage imageNamed:` into a `UIImageView`. It links `QuartzCore` on both
platforms; iosim supplies an empty framework anchor and exports the classes
from UIKit.

| Metric | Value |
|---|---|
| Mean absolute channel error | **3.71 / 255** |
| Pixels with max-channel error > 24 | **3.33 %** |
| Geometry | layer frames, gradient direction, path vertices equal |
| Remaining difference | glyph edges and the live status-bar clock when unpinned |

The simulator capture pins the status bar to 9:41 with `simctl status_bar`, so
the two frames share the same chrome.

### UIKit: table views and interaction

`demo/ListApp.m` uses a real `UITableView` data source and delegate: eight
subtitle cells, disclosure accessories, row separators and selection. Under
iosim, taps arrive through `IOSIM_EVENT_FIFO`; the window hit-tests the table,
routes the tap to the row, the delegate replaces the status label, and the next
frame renders the highlight.

| Metric | Value |
|---|---|
| Mean absolute channel error | **4.85 / 255** |
| Pixels with max-channel error > 24 | **3.55 %** |
| Text | same SFUI outlines, same per-size tracking, same cell metrics |

### UIKit layout: navigation and stack views

`demo/NavApp.m` builds a `UINavigationController` around two view controllers.
The root content is a vertical `UIStackView` containing labels, a horizontal
equal-width stack and a button; arranged subviews resolve their frames from
intrinsic content sizes during layout. Tapping the button pushes a detail
controller, updates the title bar, and a second tap pops back. Both transitions
were driven through `IOSIM_EVENT_FIFO` and captured in
`build/nav-root.png` / `build/nav-pushed.png`.

### UIKit layout: Auto Layout constraints and anchors

`demo/AutoLayoutApp.m` positions every view with `NSLayoutAnchor` constraints:
edges against the superview and the safe-area layout guide, sibling chains, a
fixed-size card, intrinsic label heights and a multiline body label whose
height follows its wrapped width. No view uses `setFrame:` for layout.

| Metric | Value |
|---|---|
| Mean absolute channel error | **3.05 / 255** |
| Pixels with max-channel error > 24 | **2.70 %** |
| Best residual alignment | 1 px horizontal, 1 px vertical |
| Safe-area top inset (iPhone 18 Pro, iOS 27.2) | 62 pt, matched |

The same Apple-clang x86_64 binary (`AutoLayoutApp_x86_64`) is loaded by iosim;
the runtime solves the constraint system with a projection solver over x, y,
width and height, locks dimensions that are intrinsic rather than constrained,
and writes the resulting frames before rendering.

### Text input and the software keyboard

`demo/TextInputApp.m` creates a `UITextField`, focuses it in `viewDidAppear`,
and lets the runtime build the keyboard. iosim draws the QWERTY layout (letter
rows, shift, delete, numeric layer, space and return) or a numeric keypad when
the field's `keyboardType` selects one, with the same framebuffer primitives as
app content. Tapping a key inserts text; `key`/`backspace` records on the event
FIFO do the same without a keyboard.

The reference capture disables the simulator's one-time slide-to-type tutorial
with a keyboard preference before launch. Measured over the full 1206×2622
frame:

| Metric | Value |
|---|---|
| Mean absolute channel error | **2.01 / 255** |
| Pixels with max-channel error > 24 | **1.86 %** |
| App content above the keyboard | **1.93 / 255** mean, 1.65 % over 24 |
| Key background / keyboard background | `#444448` / `#202025` (sampled) |

The keyboard geometry was measured key by key against the iPhone 18 Pro
capture: a 324 pt panel with 26 pt top corners, a 24 pt predictive bar with
1 pt dividers inset one point from each third, 43 pt key rows on an 11 pt
gap, 33.2 pt letters (32.2 pt on the shift row), 44.7 pt shift/delete keys and
92.7/191.3/92.7 pt bottom keys. Labels sit 1.2 pt above the geometric centre.
The return key uses the measured `↵` glyph (18 pt shaft, left arrowhead, right
riser and top hook); shift, delete, emoji and mic are drawn from measured
glyph bounds as well. The residual is concentrated on glyph antialiasing and
the sub-pixel key edges.

### Modal presentation: UIAlertController

`demo/AlertApp.m` presents a two-action `UIAlertController` from
`viewDidAppear`, and its Delete handler (a block copied to the heap by
`_Block_copy`) updates the status label and dismisses the modal. iOS 26 draws
alert-style controllers as a bottom-biased floating card rather than the
classic centred dialog, so iosim draws that measured design: a 320×151.7 pt
card at `#23242d` with 33.7 pt corners, left-aligned 17 pt bold title and 15 pt
`#71727a` message, and two 140×47 pt pill buttons at `#404149` with white and
`#ff6b6f` labels. The dimming view uses the measured 0.47 black, and the
status bar is redrawn above it exactly as on the reference.

| Metric | Value |
|---|---|
| Mean absolute channel error | **0.75 / 255** |
| Pixels with max-channel error > 24 | **0.77 %** |
| Best residual alignment | 0 px, 0 px |

Tapping Delete through the event FIFO runs the handler and dismisses the
alert; the post-action capture shows the updated "Deleted" label.

### Services: dispatch, Mach, bootstrap and XPC

`tests/services_test.m` is an Apple-clang x86_64 executable with no UI. It
exercises:

- `dispatch_async` on the main and global queues, `dispatch_after`, a
  semaphore, a group and `dispatch_main`;
- `mach_port_allocate`, a Mach message send/receive round trip;
- `bootstrap_register` / `bootstrap_look_up` for a named port;
- an XPC dictionary sent from a client connection to a listener.

Captured output:

```
services: start
dispatch: main queue block
dispatch: delayed main block
dispatch: global queue block
dispatch: semaphore returned
mach: alloc=0 send=0 recv=0 id=0x1234 value=77 text=hello mach
group: count=1
bootstrap: register=0 lookup=0 port=0x2 same=1
xpc: listener event
xpc: sent kind=ping seq=7 events=1
dispatch: main blocks ran, hits=11 group=1
services: done
```

`dispatch_main` follows Darwin's `noreturn` contract: our implementation never
returns to the caller, because callers are allowed to have optimized away the
code after it.

### System UI: a SpringBoard-like shell

`IOSIM_SHELL=1` switches `UIApplicationMain` to a home screen rendered with the
same framebuffer primitives: wallpaper gradients, a 4×3 icon grid, a weather
widget, search pill, page dots, a dock and the status bar. Tap events launch a
placeholder overlay and a second tap returns. This is a system-UI
reimplementation, not a launcher for separate app processes.

## Limitations

The framework surface is still a subset. Auto Layout supports equality and
inequality anchors with priorities evaluated by relaxation, intrinsic sizing
and guides, but not the full Cassowary solver or every UIKit layout API.
Text input is a single-line `UITextField` with a QWERTY keyboard; UITextView,
multitap gestures and selection handles are not implemented. Multi-process app
launch and cross-process Mach ports remain out of scope for the current
single-process substrate. CoreText shaping is limited to the glyphs in SFUI;
right-to-left and complex scripts are not shaped. `UIView.transform` applies
translation and scale, not arbitrary rotation. XPC is an in-process transport.
Metal and video remain unimplemented.
