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

### UIKit: sectioned table views

`demo/SectionApp.m` builds a grouped table with two sections: a 32 pt
"FRUITS" header over three 44 pt rows and a "VEGETABLES" header over two
50 pt rows, each section painted a different color. The suite launches it
from SpringBoard, samples the third row at (200, 242) pt (purple, so the
header offset and 44 pt rows agree), taps it and the delegate reports
`[section] select 0:2 Cherry`; the same point then reads the highlight gray.
Tapping (200, 371) pt walks past the header and the first 50 pt row and the
delegate reports `[section] select 1:1 Pea`, which also paints highlighted.
Selection therefore shares one section/header/height computation with
rendering.

### Touch: long-press recognition

`demo/LongPressApp.m` attaches a `UILongPressGestureRecognizer` (0.4 s,
10 pt tolerance) to its root view and prints every state with the location.
The suite first taps the view and confirms no `began` appears, then holds
the finger down for 0.7 s: the per-frame tick fires `began 200 400` without
another event. Moving to (220, 420) reports `changed 220 420`, and lifting
ends the gesture at the last point. A second press that moves 120 pt before
the duration is up never begins, so `allowableMovement` fails it.

### UIKit: collection views

`demo/CollectionApp.m` puts a `UICollectionView` with a flow layout (100 pt
items, 12 pt interitem and line spacing, 20 pt section insets) inside a 500 pt
tall scroll view. Its data source registers `UICollectionViewCell` for a reuse
identifier and returns twenty colored cells. The suite launches it from its
SpringBoard icon, reads the cell at (294, 262) pt as the orange palette entry,
taps that point, and the delegate reports `[collection] selected 5`. A
250 pt drag then scrolls the content: the same screen point reads the blue
fourth-row item, so the tap frame math, the cell subview frames and the scroll
offset all agree.

### UIKit: multi-section collection views

`demo/SectionCollectionApp.m` returns two sections (4 and 3 items) from
`numberOfSectionsInCollectionView:` with 80 pt items and 10 pt spacing. The
suite reads the first cell of section two at (60, 270) pt as the green palette
entry, and the band between the sections at (60, 205) pt as the background,
proving the second section starts after the first section's rows, bottom inset
and the inter-section line space. Tapping (240, 140) reports
`[sectioncollection] selected 0:2`; tapping (150, 270) reports `selected 1:1`,
so hit-testing runs over the same section geometry and index paths carry the
section.

### UIKit layout: navigation and stack views

`demo/NavApp.m` builds a `UINavigationController` around two view controllers.
The root content is a vertical `UIStackView` containing labels, a horizontal
equal-width stack and a button; arranged subviews resolve their frames from
intrinsic content sizes during layout. Tapping the button pushes a detail
controller, updates the title bar, and a second tap pops back. Both transitions
were driven through `IOSIM_EVENT_FIFO` and captured in
`build/nav-root.png` / `build/nav-pushed.png`.

### UIKit: stepper control

`demo/StepperApp.m` puts a `UIStepper` (0..10, step 1) on screen with a label
that follows its value. The suite taps the plus half at (224, 316) pt twice
and observes `value=1` and `value=2` from `ValueChanged`, then taps the
minus half at (178, 316) and the third event confirms the value dropped
again. The two halves are real `UIControl`s, so hit-testing and tracking are
the same path as other controls.

### UIKit: picker wheels

`demo/PickerApp.m` shows a two-component `UIPickerView` (five country rows and
three color rows) with a delegate that prints selections. The screenshot at
(30, 248) pt reads the translucent selection band over the app background, so
the centered band is rendered where the wheel math puts it. Tapping the second
wheel's third row at (290, 312) pt prints `selected 1:2`; a touch-down at
(100, 300), a move to (100, 236) — two rows up — and touch-up prints
`selected 0:2`, proving drag offsets are per component, clamped to the row
count and snapped on release.

### UIKit: date picker

`demo/DatePickerApp.m` places a date-mode `UIDatePicker` and a time-mode one,
both set to 2024-02-29 12:34:00 UTC, with `ValueChanged` targets that print the
resulting epoch seconds. Tapping the day wheel's 28 at (201, 128) pt prints
`date 1709123640`, one day back. Tapping March at (83, 192) pt prints
`date 1711629240`: the month wheel moved, the year wheel stayed on 2024 and
the day wheel kept 28 across the month boundary. Tapping minute 35 at
(201, 382) pt in the time wheels prints `time 1709210100`, with the hour and
AM/PM wheels unchanged.

### UIKit: search bar text input

`demo/SearchBarApp.m` places a `UISearchBar` with a visible Cancel button and
a delegate that prints edits, searches and cancellation. After focusing the
field the suite types `a` and `b` and sees `q=ab`; the screenshot at
(23, 620) pt shows the software keyboard. Return reports `go ab` without a
trailing newline in the text, and Cancel reports `cancel`, clears the field
and resigns it — the same pixel returns to the app background once the
keyboard is gone.

### UIKit: navigation bar items

`demo/NavBarApp.m` gives its root controller a right `UIBarButtonItem`
("Add") and prints its action. The suite taps the item at (341, 70) pt and
sees `[nav] add`, taps the content button to push the detail controller
(`[nav] detail appeared`), then taps the automatic "‹ Library" back control
at (68, 70) pt and sees the root's `viewWillAppear:` fire. The bar buttons
are real `UIControl`s in the navigation bar's subview hierarchy, not hit
regions checked separately.

### UIKit: tab bar container

`demo/TabApp.m` puts two controllers (red and green) inside a
`UITabBarController` with titled `UITabBarItem`s. It reports
`[tab] ready count=2 selected=0`; the floating bar is drawn 16 pt from the
sides, 64 pt tall and 12 pt above the home indicator. Tapping the second item
logs `[tab] selected 1` and the screenshot's content pixel at (201, 300) pt
changes from `#d93333` to `#33cc4d`; tapping the first item logs
`[tab] selected 0` again. The bar pixel at (201, 796) pt stays dark
(`#25202e` / `#1b2930`) in both frames, so the bar really composites over the
swapped content instead of the content covering it. The item controls use the
same `UIControl` tracking path as buttons.

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
| Mean absolute channel error | **1.84 / 255** |
| Pixels with max-channel error > 24 | **1.64 %** |
| App content above the keyboard | **1.72 / 255** mean, 1.34 % over 24 |
| Keyboard panel | **2.02 / 255** mean, 2.14 % over 24 |
| Key background / keyboard background | `#444448` / `#202025` (sampled) |

The keyboard geometry was measured key by key against the iPhone 18 Pro
capture: a 328 pt panel with 26 pt top corners, 58 pt bottom corners, a glass
edge that falls from `#3e3f45` to the `#202025` fill over 6 pt, a 24 pt
predictive bar with 1 pt dividers inset one point from each third, 43 pt key
rows on an 11 pt gap, 33.2 pt letters (33 pt on the shift row), 44.7 pt
shift/delete keys and 92.7/191.3/92.7 pt bottom keys. Labels sit 1.2 pt above
the geometric centre.
The return key uses the measured `↵` glyph (18 pt shaft, left arrowhead, right
riser and top hook); shift, delete, emoji and mic are drawn from measured
glyph bounds as well. The residual is concentrated on glyph antialiasing and
the sub-pixel key edges.

### Text input: multiline UITextView and hardware keys

`demo/TextViewApp.m` puts a multiline `UITextView` on screen and reports its
text whenever it changes. The test taps the view to focus it, checks that the
software keyboard appears (the Q key pixel at (23, 620) pt reads `#444448`),
then drives `ui key a`, `key b`, `key return`, `key c` and sees
`[textview] lines=2 text=ab|c`; a `ui backspace` followed by `key d` produces
`[textview] lines=2 text=ab|d`. The line count is computed from the newline in
the stored text, so the return key really inserted a line break; the append
and delete operations run through the same `insertText:`/`deleteBackward:`
methods the on-screen keyboard uses.

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
| Mean absolute channel error | **0.67 / 255** |
| Pixels with max-channel error > 24 | **0.72 %** |
| Best residual alignment | 0 px, 0 px |

Tapping Delete through the event FIFO runs the handler and dismisses the
alert; the post-action capture shows the updated "Deleted" label.

### Numeric keypad

`demo/NumberPadApp.m` is the text-input fixture with the number-pad trait
(`keyboardType = UIKeyboardTypeNumberPad`). The real iOS 26 phone pad draws
digit keys with letter sublabels (ABC … WXYZ), a filled `0` key, a bare
delete icon and no home indicator. iosim reproduces that measured layout:
a 302 pt panel with the same glass edge, 126.2 × 48 pt keys on a 132.5 pt
horizontal and 54 pt vertical pitch, 22 pt digits, letterspaced 10 pt
sublabels, and a 24 pt bare delete glyph.

| Metric | Value |
|---|---|
| Keyboard panel mean error | **1.22 / 255** |
| Pixels over 24 in the panel | **1.42 %** |
| Full frame (capture includes the Dynamic Island) | **1.66 / 255**, 2.24 % |

### Native controls

`demo/ControlsApp.m` places one of each standard control at a fixed frame:
a `UISwitch` in both states, a `UISlider` at 0.64, a three-item
`UISegmentedControl`, a `UIProgressView` at 0.35, a five-page
`UIPageControl` and the deprecated gray `UIActivityIndicatorView`. The iOS 26
renderings were measured from the capture rather than assumed:

- the switch is a 63 x 28 pt capsule with a 36.3 x 23.3 pt white knob inset
  2.3 pt; the on track is system green (`#30d158`) and the off track is a
  glass fill;
- the slider track is 5.7 pt tall with a `#0091ff` fill and a glass unfilled
  track; its thumb is the same 36.3 x 23.3 pt lozenge, not a circle;
- the segmented control is a glass capsule, a 10.5 % white track with a
  27.5 % white selected pill inset 2 pt from the segment bounds;
- the progress bar is 4 pt tall and pinned to the top of its bounds, with a
  slight vertical sheen in the fill and a 16 % glass track;
- page dots are 8 pt across on a 17.7 pt pitch, 45 % white when unselected;
- the gray activity indicator style is a 20 pt spinner whose ink reads as a
  translucent black on a dark surface.

Comparing the fixtures exposed a framebuffer bug: translucent rounded rects
and circles composited their interiors at full opacity and only their edges at
the requested alpha. Interiors now clamp coverage to the current opacity, so
glass fills composite correctly.

| Metric | Value |
|---|---|
| Full-frame mean error | **0.70 / 255** |
| Pixels with max-channel error > 24 | **0.50 %** |
| Switch band | 0.73 / 255 |
| Slider band | 0.52 / 255 |
| Segmented band (13 pt glyph edges inside) | 1.50 / 255 |
| Progress bar band | 0.24 / 255 |

### Touch: responder delivery and live controls

`demo/TouchApp.m` is a real app launched by SpringBoard. It puts a custom
`UIView` subclass in the middle of its screen, a slider, a switch, a segmented
control and a button. The custom view overrides `touchesBegan:withEvent:`,
`touchesMoved:withEvent:` and `touchesEnded:withEvent:`, prints the view-local
point for each phase and drops a dot at that point. The runtime turns each
event-FIFO record into a `UITouch` with a phase, timestamp, hit view and
window, wraps it in a `UIEvent`, and delivers it through the responder chain.

The test drives a drag across the custom view, a drag across the slider, a
tap on the switch and a tap on the button, then asserts on the app's own
output:

```sh
tools/iosimctl ui $UDID down 60 300
tools/iosimctl ui $UDID move 120 320
tools/iosimctl ui $UDID up 200 300
```

```
[touch] began 36.0 104.0
[touch] moved 96.0 124.0
[touch] ended 176.0 104.0
[slider] 0.497
[slider] 1.000
[switch] 1
[button] pressed
```

The view-local points are exact (the panel starts at 24,196 pt). The slider
tracks every move and reaches its maximum; the switch toggles on touch-up
inside; the button's target/action fires through `UIControl`'s tracking path.
The same synthetic tap path focuses a `UITextField` and the runtime keyboard
accepts the next tap, verified by the text-input fixture. `ui swipe` emits a
whole down/moves/up gesture in one command.

### Animation timeline and display link

`demo/AnimationApp.m` runs a `CADisplayLink` that moves a green dot every
frame, then starts `animateWithDuration:2.0 delay:0.1
options:UIViewAnimationOptionCurveEaseInOut animations:completion:` on a blue
box while a `CAKeyframeAnimation` pulses a layer's opacity from 1.0 to 0.25
and back twice and a second animation on the same layer sweeps its corner
radius from 12 to 20 pt. The app samples `layer.presentationLayer` every fifth
display link frame:

```
[anim] tick 30
[anim] present 302.2
[anim] dot 0.69
[anim] tick 40
[anim] present 390.2
[anim] dot 0.66
...
[anim] completed 1
```

The test asserts:

- the completion block runs once with `finished = YES`;
- a sampled presentation frame lies strictly between the box's start (300 pt)
  and end (470 pt) positions;
- a sampled presentation opacity drops below 0.40 (the keyframe animation);
- a sampled `[anim] tracks` line shows opacity below 0.90 and corner radius
  above 12.4 at the same instant, and the radius track later passes 15 pt —
  two animations advance together on one layer;
- the mid-flight screenshot's topmost blue pixel is between 300 and 455 pt,
  while the settled screenshot's dimmed box starts at 470 pt;
- the display-link dot is present in the lower band of the settled frame.

This exercises the run loop rather than a still image: the dot moves only
because the link ticks, the box moves because the animation timeline is
interpolated in the renderer, and the layer pulse is a keyframe animation
composited into the view's alpha.

### Foundation: files, URLs and JSON

`tests/foundation_io_test.m` is a Foundation-only executable. It creates
`Documents/IOTest` under the app's `HOME`, writes and reads a payload through
`NSData`/`NSString`, lists the directory, copies and removes an item, walks an
`NSURL`, and round-trips a dictionary through `NSJSONSerialization`:

```
mkdir 1
dir exists 1 isdir 1
write 1
read hello file
items 1 note.txt
copy 1
copy exists 1
remove 1
copy gone 1
url file://<home>/Documents/IOTest/note.txt
url path <home>/Documents/IOTest/note.txt
last note.txt
ext txt
append extra
valid 1
json {"name":"Sim","count":42,"list":[1.5,true,null]}
parsed Sim 42 1.5 1
invalid 1
```

The JSON line is exactly what the serializer emits (no spaces, insertion
order, booleans and null preserved); the parser reproduces the string, the
integer, the double and the boolean, and rejects `{oops`. These file
operations go through host-side wrappers for `fopen`, `stat`, `mkdir`,
`rename` and `readdir`, so Darwin flag values and `struct stat` layouts never
reach glibc.

### Foundation: persistent defaults and property lists

`tests/defaults_test.m` writes a domain with `NSUserDefaults` in one process
and reads it back in a second process with the same `HOME` and
`XPC_SERVICE_NAME`. The write reports `defaults: wrote theme=dark seen=1
count=42`; the read reports the string, bool, integer, a two-item array and a
four-byte data value. The domain file is
`Library/Preferences/com.iosim.defaults.plist` under the app home (the suite
name is taken from the bundle id in `XPC_SERVICE_NAME`), and Python's
`plistlib` parses it as a real XML property list containing
`<string>dark</string>`, `<true/>`, `<integer>42</integer>`, the string array
and `<data>YWJjZA==</data>`. That cross-language parse is the check that the
writer emits the actual plist format rather than an internal encoding.

`NSPropertyListSerialization` implements both directions for dictionaries,
arrays, strings, integers, reals, booleans, data and dates. Strings are
XML-escaped on the way out and unescaped on the way in; the parser bounds
nesting depth and only accepts well-formed tags.

### Foundation: keyed archives

`tests/keyed_test.m` defines a `Profile` class that implements `NSCoding` and
archives a root dictionary holding it, a string array, a boolean, four bytes
of data and a date — first in one process with `NSKeyedArchiver`, then in a
second process with `NSKeyedUnarchiver`. Both report the decoded identity:
`name=Ada age=36 score=97.5 tags=2 items=2 enabled=1 blob=4
when=1700000000 class=Profile`. The custom class was therefore rebuilt
through `initWithCoder:`, not left as a plain dictionary. Python's `plistlib`
parses the file as a genuine keyed archive: `$archiver` is `NSKeyedArchiver`,
`$version` is 100000, `$objects` holds the value table and class descriptions
(`$classname` `Profile`, `$classes` chain), and `$top`/`$objects` refer to
entries through `CF$UID` dictionaries — the shape Foundation writes.

### Foundation: run loop and delayed performs

`tests/runloop_test.m` schedules `performSelector:withObject:afterDelay:` on
an object, cancels a second request and drives `NSRunLoop` directly. It
reports `mainthread=1` from `NSThread`; an idle
`runMode:beforeDate:` returns `idle=0 waited=1` after its 100 ms deadline;
the 150 ms delayed perform then runs (`fired=1 timing=1`) and the cancelled
one never does. A repeating 50 ms timer fires twice and invalidates itself,
and `sleepForTimeInterval:` really waits (`sleeping=1 cancelled=0`).

### Foundation: calendar components

`tests/calendar_test.m` decomposes the Unix epoch and reports
`1970-01-01 00:00:00 wd=5` (Thursday under the Sunday-based weekday), builds
`2024-02-29 12:34:56` from `NSDateComponents`, and decomposes the result back
to the same fields with epoch `1709210096` — the leap day lands on the
expected Thursday and the seconds match Python's `calendar.timegm` for that
timestamp. The current calendar also reports its
`NSCalendarIdentifierGregorian` identifier.

### Foundation: operation queues

`tests/operation_test.m` adds three `addOperationWithBlock:` closures that
print 0, 1 and 2 and increment a shared counter, plus an `NSBlockOperation`
with two execution blocks and a completion block. It then calls
`waitUntilAllOperationsAreFinished`. All seven lines appear, the final
report is `blocks=3 pending=0 max=-1`, and the captured loop indexes are the
real 0/1/2 (the blocks are copied when added, so a stack literal cannot
observe the loop's final value). The group wait is a real join: the final
line is printed only after every worker has returned.

### UIKit: app bundle resources

`demo/ResourceApp.m` is installed as a real `.app` with a 4 x 4 red `dot.png`
and a `note.txt` beside its executable. The loader derives
`IOSIM_BUNDLE_DIR` from the app's own executable path, and the fixture reports
`[res] image 4 4` from `UIImage imageNamed:@"dot"`, `[res] note bundle
resource` from `NSBundle pathForResource:ofType:` plus `NSData`, and draws the
image into a 100 pt `UIImageView`. The test launches it from SpringBoard and
reads the screenshot at (150, 350) pt, which is `#ff0000` — the decoded bundle
PNG reached the framebuffer, so this is resource resolution and PNG decoding
end to end rather than a path string check. Because the directory is derived
from the executable, an app launched by SpringBoard replaces the system UI's
inherited bundle path with its own.

### Services: the system pasteboard

`tests/pasteboard_test.m` links UIKit and runs as separate processes against
one `SIMULATOR_SHARED_RESOURCES_DIRECTORY`. The writer sets the general
pasteboard string and reports `change=1`; a second process reads
`hello pasteboard` with `change=1` and `hasStrings=1`. The file at
`var/run/pasteboard.plist` is parsed by `plistlib` as a real XML plist whose
first item carries `public.utf8-plain-text`. A data write then replaces the
contents (`len=3 change=2`), and another process reads the same three bytes
back as `data=3/1 change=2`, so the pasteboard is a device service rather
than per-process state.

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

Cross-process services are verified between two independent guest processes.
`tests/mach_cross_test.c` registers `com.iosim.cross.mach` with launchd from a
service process, looks the name up from a client process and sends a
`mach_msg`. The service receives the client's `id=0x1234 value=91 text=hello
across processes`; a second process that tries to register the same live name
gets `BOOTSTRAP_SERVICE_ACTIVE` (1103); after the service exits, the name is
pruned and a fresh registration succeeds; an unregistered name returns 1102.
The transport is one `SOCK_SEQPACKET` datagram per message over a Linux
abstract-namespace socket derived from the device UDID, so no filesystem
rendezvous is needed and the name never collides with another device.

XPC rides on the same namespace. `tests/xpc_cross_test.c` is built with
`-fblocks`; its service creates a mach-service listener
(`XPC_CONNECTION_MACH_SERVICE_LISTENER`), installs an event handler and
resumes, which registers `com.iosim.cross.xpc` and starts a receiver thread.
The client process resumes a plain connection, sends a dictionary with a
string, an int64, a bool and a 4-byte data value, and the service's handler
receives a rebuilt object and prints
`xpc service: received kind=ping seq=7 flag=1 blob=4`. The encoder emits a
tagged tree; the decoder bounds depth, dictionary counts, key and value
lengths before allocating, because the bytes cross a process boundary.

### System UI: SpringBoard, measured and real

`IOSIM_SHELL=1` switches `UIApplicationMain` to the home screen, and
`tools/build_runtime.sh` builds that home screen as its own executable,
`SpringBoard.app/SpringBoard`. launchd boots it as a real process when a device
starts. The layout is measured from the iOS 27 iPhone 18 Pro home screen:

- 402 × 874 pt screen, 24 pt side margin, four columns at a 92.5556 pt pitch
  (centres 62.1667 / 154.7222 / 247.2778 / 339.8333 pt), row centres
  121.8333 / 222.1667 / 322.5 / 422.8333 pt.
- 64 pt icons, 12 pt white labels with the baseline 48.1 pt below the icon
  centre, dock at 18..384 × 761.333..850.333 pt with a 44.5 pt radius, search
  pill at 164.333..237.333 × 704..733 pt.
- The wallpaper is a 48 × 104 field sampled from a real capture with icons,
  labels, the dock, the search pill and the status bar masked out and the holes
  diffused; the dock and search glass are 8 × 3 and 4 × 2 sampled fields. The
  runtime upscales them bilinearly, so the satin folds and their blurred
  shadows come from measurement rather than a hand-painted gradient.
- Icon masks are circular rounded rects (radius 22.37 % of the side). The
  generic app icon is the measured wireframe: white face with a bottom shade,
  1 px #9a9a9a grid clipped by the face, a 2 px #cdcdcd crosshair, circles of
  36 px, 50 px and 84 px, and the square's diagonals.

Against the real simulator's home screen (same device, same installed apps,
same status bar), the full-frame parity is:

| Region | Mean error (0–255) |
|---|---|
| Whole screen | 7.03 |
| Status bar | 3.97 |
| Search pill | 4.23 |
| Placeholder app icon | 5.8 |
| Stock icons | 7.4–26.2 |
| Dock | 9.4 |

8.15 % of pixels fall outside the 24/255 tolerance. The stock artwork is
composed the way the real icons are: each icon is drawn into its own layer and
masked by the measured 43 px rounded-rect face, with measured art for the
Fitness rings (17/16/14 px strokes on 68.5/46/25 px radii with a colour ramp and
rounded caps), the Watch band (a 63 × 70 px ellipse ring with a case and crown),
the Files folder (tab, inner sheet and a blue ramp), the Safari dial (76.5 px
radius, 32 ticks, red/white needle), the Messages bubble (69.5 × 57 px ellipse,
tail and shadow), the Contacts avatar disc and colour tabs, and the Utilities
folder with its mini apps. The largest remaining icon error is Preview's
photorealistic lens (26.2); the wallpaper-only bands sit near 4/255.

The system UI is not a mock launcher. The boot flow is exercised end to end:

```sh
tools/iosimctl create "Phone" com.iosim.SimDeviceType.iPhone-18-Pro   # UDID
tools/iosimctl boot $UDID              # launchd starts SpringBoard
tools/iosimctl io $UDID screenshot home0.png
tools/iosimctl install $UDID HelloSim.app
tools/iosimctl io $UDID screenshot home1.png   # the app icon appears
tools/iosimctl ui $UDID tap 339.8 222.2        # tap the icon (points)
tools/iosimctl io $UDID screenshot app.png     # the app rendered itself
tools/iosimctl ui $UDID home
tools/iosimctl io $UDID screenshot home2.png   # back on the measured home
```

`app.png` from the SpringBoard launch matches the same app captured directly
and the real iOS capture (Controls: 0.22/255 against the direct iosim capture,
0.70/255 against the real simulator). `home2.png` is byte-identical to
`home1.png`: the app ran its scene background lifecycle and SpringBoard
repainted the same measured home screen. Installing while booted sends the
`apps` event, and the icon appears without a reboot.

Backgrounding suspends rather than terminates. The app stops itself after
`sceneDidEnterBackground:`; SpringBoard's `waitpid(WUNTRACED)` records the
stopped PID, and tapping the same icon sends SIGCONT so the process resumes
in place:

```
[UIKit-lite] backgrounded by the system; suspending
[SpringBoard] resuming TouchApp (pid 157672)
[UIKit-lite] resumed from suspension
```

The process state is `T` (stopped) while on the home screen, and its
`viewDidLoad` ran exactly once across the suspend/resume cycle — the fixture's
`[touch] app ready` line is not printed again. The test asserts the stop
message, the resume message, the foreground lifecycle and the single
`viewDidLoad`. `shutdown` continues stopped children before SIGTERM, so no
app process survives the device.

The app switcher uses the real frames, not mock cards. At suspension
SpringBoard copies `data/var/run/framebuffer.png` to
`data/var/run/switcher/com.iosim.touch.png`; the switcher dims the sampled
wallpaper and draws each suspended app as a 72%-width card (40 pt corners,
shadow, name above) scaled from that PNG. The screenshot after a drag gesture
shows the card carrying the app's live content, including the dots the drag
left in its trail view. The test asserts the switcher's log line, the cached
PNG's 1206 x 2622 dimensions, selection of the card, and a second
`resumed from suspension` — the card really continues the stopped process.
A bottom-edge swipe up opens the switcher from the home screen and a downward
swipe closes it; `ui switcher` injects the same toggle for headless tests.
The same gesture works inside a foreground app. The test resumes TouchApp from
a card, then swipes up from the bottom edge of the app itself: the app logs
`backgrounded by the system; suspending`, signals SpringBoard, and stops with
SIGSTOP; SpringBoard reports `app switcher opened (2 suspended)` (UIKitApp is
still suspended from the earlier launch) without any
`ui switcher` command, and tapping the card resumes the same process. This
exercises the runtime's nil-receiver semantics as well: the touch lands on a
view with no touch overrides, the responder chain forwards `touchesBegan:`
to `nil`, and the trampoline returns zero instead of aborting the process.

Swiping up on a switcher card force-quits the app. The test suspends TouchApp,
opens the switcher, swipes up from the card, and asserts SpringBoard's
`closed TouchApp (pid N)` line; the recorded pid no longer exists afterwards,
so the process was continued, terminated and reaped rather than left stopped.
Tapping the icon then reports a fresh launch and the fixture's `[touch] app
ready` appears again, confirming the kill really discarded the old process
state instead of resuming it.

Spotlight is driven by the same event stream. The test taps the search pill
at (201, 718.5) pt, types `t`, `a`, `b` with `ui key`, and watches the count
narrow from 5 to 2 to 1 (`[SpringBoard] search results N`). The screenshot
taken then shows the Q key pixel `#444448` (the software keyboard) and the
first result row at (201, 270) pt painted `#1a1e2a`. Tapping the row logs
`search selected Tab` and `resuming Tab (pid ...)`: search found the real
installed app and resumed its suspended process. The query is matched
case-insensitively against every installed app, so the earlier two-character
query also matched the stock Contacts app, which is correct Spotlight
behavior. The resume only succeeds because the suite installs TextViewApp
after Tab was suspended and the manifest reload keeps Tab's pid; without that
the search result would start a second process instead of continuing the
stopped one.

The home grid pages in groups of 16 once seven stock apps and nine
installed apps are present. The test installs ten extra page fixtures (21 grid apps in
all), then swipes left: SpringBoard reports `home page 2 of 2`, draws the
second page with `Page6` at the top-left slot, and the page dots swap from
white-on-the-left to white-on-the-right. A screenshot check reads the two dot
centres at x = 193 pt and 209 pt, y = 686 pt, verifying #ffffff for the active
page and #8e8e93 for the inactive one; tapping the top-left slot then launches
`Page6` and swiping right returns to page 1. The dot row's placement between
the grid and the search pill is a modeled iOS 26 relationship; the rest of the
layout (pitch, icon size, labels, dock and pill) remains the measured capture.

### App lifecycle: delegate callbacks and application state

`demo/LifecycleApp.m` prints every transition with
`[[UIApplication sharedApplication] applicationState]`. A cold launch reports
`launch state=0`, then `ready state=0` from `viewDidLoad` and
`active state=0` from `applicationDidBecomeActive:`. Sending the app home logs
`resign state=1`, `background state=2` and `scene background`: the application
delegate and notification state walk inactive → background around the scene
callbacks. Resuming from the icon logs `foreground state=1`,
`scene foreground`, `active state=0` and `scene active`, and the fixture's
`ready` line still appears only once — the same stopped process continued.
The `UIApplicationWillResignActive`/`DidEnterBackground`/`WillEnterForeground`/
`DidBecomeActive` notifications are posted alongside the delegate calls.

## Limitations

The framework surface is still a subset. Auto Layout supports equality and
inequality anchors with priorities evaluated by relaxation, intrinsic sizing
and guides, but not the full Cassowary solver or every UIKit layout API.
`NSUserDefaults` persists XML property lists under the app's
`Library/Preferences`; binary property lists are not parsed. JSON covers
Foundation objects without comments, streaming or fragments unless enabled.
Text input is `UITextField` and an append-only `UITextView` with a QWERTY
keyboard; text selection, multitap gestures and selection handles are not
implemented. Touch input is
single-finger: there is no multitouch, touch prediction or pressure. Mach
messages, the bootstrap namespace and serialized XPC dictionaries are shared
across guest processes. SpringBoard pages in groups of 16 without a sliding
page animation, and the switcher shows at most three cards with no scrolling
animation; stock system apps have no executables in this runtime.
Backgrounded apps are suspended in place (SIGSTOP) and resumed from their icon
or switcher card, with no memory-pressure termination policy.
`UIApplication` tracks active/inactive/background state and posts the
lifecycle notifications, but `beginBackgroundTaskWithExpirationHandler:`
returns 0: the model suspends the process immediately instead of granting a
background execution window. CoreText shaping is limited to the glyphs in SFUI;
right-to-left and complex scripts are not shaped. `UIView.transform` applies a
full 2D affine transform (translation, scale and rotation) through an offscreen
composite; `CATransform3D` is not supported. Core Animation keeps four
explicit animation slots per layer, and `CADisplayLink` ignores preferred
frame-rate ranges. XPC carries dictionaries
and value objects between processes but not connections, file descriptors or
reply ports. The pasteboard shares strings and data items but has no rich
pasteboard types, item providers or change notifications. Metal and video
remain unimplemented.
