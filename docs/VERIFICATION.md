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

### UIKit: table swipe-to-delete

`demo/TableEditApp.m` shows a four-row table whose data source implements
`canEditRowAtIndexPath:` and `commitEditingStyle:forRowAtIndexPath:`. The
suite swipes row 1 from (300, 164) to (180, 164) pt: the table records the
open swipe and prints `[table] delete revealed 1`; the screenshot reads the
revealed control at (360, 164) pt as #ff3b30. Tapping that point calls the
data source, which prints `[edit] deleted 1 name=Green` and `[edit] items=3`,
and the next screenshot reads the same pixel as the row background, so the
button and row really went away.

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
100 pt drag with momentum then scrolls the content: the scroll delegate
reports a positive final content offset and the post-scroll capture differs
from the initial frame, so the tap frame math, the cell subview frames and the
scroll offset all agree.

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

### UIKit: collection supplementary views

`tests/collection_supplementary_test.m` gives a one-section flow layout a
40 pt header and 30 pt footer and registers `SuppHeader`/`SuppFooter` reusable
classes. The data source returns them from
`collectionView:viewForSupplementaryElementOfKind:atIndexPath:`; after
`reloadData`, the header frame is (0, 10, 390, 40) and the footer is
(0, 130, 390, 30), the content height is 170 pt and the collection holds four
subviews (header, two cells, footer). The suite checks all three lines, so
supplementary registration, dequeue, placement and content sizing agree.

### UIKit: compositional collection layouts

`tests/collection_compositional_test.m` builds three collections on the
402 pt-wide screen. A repeating horizontal group of two 176x80 items with
10 pt inter-item spacing and 20/15 pt section insets places item frames at
(20,15), (206,15), (20,105) and (206,375) with a 470 pt content height; the
tap at (100,145) reports section 0 item 2. A nested layout (two vertical
groups of two 181x100 items) reaches (201,325) for item 7 with a 440 pt
content height. A section provider runs the two-column section twice, so its
second section starts at y=470 and item 19 is (206,845), for a 940 pt content
height. Captured pixels are white at cell centers and black at the 10 pt gap
between the two columns, so rendering uses the same frames as hit-testing.

### UIKit: horizontal collection flow layout

`tests/horizontal_collection_test.m` gives a 402x200 collection a 90x60 item
size, 10 pt inter-item and 5 pt line spacing, 20/10 pt section insets and a
horizontal scroll direction. Ten items wrap after two rows, so cells sit at
(10,20), (10,85), (110,20), (110,85) and (410,85), the content size is
510x200, and a tap at (155,50) reports section 0 item 2. After setting a
60 pt content offset, captured pixels read white at the second and fourth
column centers and black in the 10 pt gap, so rendering follows the offset.

### UIKit: diffable data sources

`tests/diffable_data_source_test.m` builds a two-section snapshot, appends
items, inserts before and after an item, deletes an item, moves one to the
front and deletes the second section. It prints `[diff] snapshot 2 3`,
`[diff] final 1 2` and the surviving `c1`, `a1` order. A table data source
then reports one section and two rows, maps index path 0:1 to `a1` and back,
and produces a cell whose text is `a1`; a collection data source with a
registered cell class reports one section and three items and resolves
0:2 to `g3`.

### UIKit: split-view columns

`tests/foundation_extra_test.m` lays out a 1024 pt double-column split view and
prints `[fnd] split 0 2 307 307 717 2 1`: primary width 307 pt, secondary at
x=307 with width 717, two children and the primary column lookup returning the
left controller. A triple-column split view with a 200 pt supplementary column
prints `[fnd] triple 307 307 200 507 517 3 1`: the supplementary controller
sits between primary and secondary, the secondary starts at x=507 with width
517, all three are children, and the supplementary column lookup returns its
controller.

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

### UIKit: standalone navigation bar and toolbar

`tests/bars_test.m` places a `UINavigationBar` at (0,60) with a "Photos" item
and a "Done" right button, and a `UIToolbar` at the bottom with Bold, Italic
and Share items. It first pushes a "Detail" item and pops it, printing
`[bars] items 1 1`. At 800 ms it injects four taps through the event FIFO:
the three toolbar item centers and the navigation bar's Done center. The app
reports `[bars] nav 1 tool 3`, so every bar item fired its target through the
normal control path. The captured frame samples 16839 navigation-bar and
18288 toolbar background pixels at the expected positions.

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

### Text input: UITextView selection

`tests/textview_selection_test.m` starts with `hello world`: `setText:`
leaves the caret at 11, `setSelectedRange:{6,5}` stores `6 5`, and inserting
`there` replaces `world` to produce `hello there` with the caret at 11.
Selecting `{0,6}` and deleting leaves `there` with caret 0; setting `{99,5}`
clamps to `5 0`. `tests/textview_selection_visual_test.m` places a 24 pt
`hello world` view with `{6,5}` selected, captures a PNG through a later
sibling view and the suite finds 12960 pixels of the `#33507a` selection
highlight in the text region. `tests/textview_drag_selection_test.m`
synthesizes touches on a 24 pt editor: dragging from the left inset to past
the right edge selects `0 11`, and a second drag leaves a non-empty partial
selection. The capture (caret dropped after resigning) counts 25723
highlight pixels and 1404 `#426bf2` handle pixels, proving both selection
endpoints draw stems and knobs. `tests/textview_handle_drag_test.m` computes
the end knob from the font metrics, drags it 20 points right (the selection
grows past five characters but stays inside `hello world`), then grabs the
new start knob and pulls it right; the selection start moves to 3 with a
3-character span. This covers knob hit testing and per-endpoint dragging.
`tests/textview_long_press_test.m` starts with a synthetic touch inside
`world` and runs the real event-loop path through a FIFO: a `dispatch_after`
block at 900 ms observes `{6,5}`, captures the frame and exits. The PNG holds
12976 highlight pixels and 1908 blue handle/caret pixels, proving the
per-frame long-press tick selected the word and marked it with handles.
`tests/textview_edit_menu_test.m` extends that run: the 900 ms block sees
`UIMenuController` visible, captures the menu above the selection, and writes
a `tap` for the Copy item's center into the FIFO. The event loop consumes the
tap, invokes `copy:` on the first responder and hides the menu; at 1500 ms
the app reports the pasteboard now holds `world` and the menu is hidden. The
first PNG carries 17896 menu-panel and 1365 label pixels; after the tap the
same region has none.

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

### Modal presentation: animated page sheet

`tests/modal_animation_test.m` presents a green `SheetController` from a dark
parent at 150 ms and dismisses it at 900 ms. Four timed captures prove the
motion: at 250 ms the bottom band is green while the top is dimmed parent
(`#0a0d17`), at 700 ms the sheet covers the full frame, at 1000 ms the sheet
has slid back down so the top is dimmed parent and the middle is green, and
at 1400 ms the sheet is gone and the parent's `#0b0e1a` is restored
everywhere. The renderer slides the sheet by the remaining fraction of the
screen height and scales the 0.47 dim with progress; no frames are captured
from a static state.

### Share sheet: UIActivityViewController

`tests/activity_sheet_test.m` presents a share sheet with one string item
over a green parent, taps its Copy row through the event FIFO, then presents
a second sheet with `UIActivityTypeCopyToPasteboard` excluded and cancels it
by tapping the dim. The captures measure: at 250 ms the sheet's top edge is
~778 pt down and the parent above it reads dim green `#16a940`; the settled
one-row sheet is 240 pt tall (top edge 626 pt) with the card at `#23242d`,
dim green `#0e6c29` at (201,450) and the body at (201,760); the rowless
secondary sheet is 182 pt tall with a 684 pt top edge; after Copy the
parent is the exact `#1acc4d` at top and bottom, and cancel restores the
same. Copy places "Hello share sheet" on the general pasteboard, and the
completion handler receives `com.apple.UIKit.activity.CopyToPasteboard` with
`completed = YES`; cancelling receives a nil activity and `completed = NO`.
The suite accepts a settled top edge within 600–660 pt and the rowless sheet
within 660–710 pt.

### Context menus

`tests/context_menu_test.m` holds a first table row for half a second and
captures the lifted menu: the row's blue cell (`#263359`) renders as the
preview at (201,90), the action card (`#23242d`) sits at (201,150), and the
backdrop is the blurred, dimmed table green `#149f3c` rather than the crisp
`#1acc4d`. Tapping Favorite runs its handler and restores the table (blue
cell at (201,66), exact green at (201,600)). A second row shows its purple
cell (`#592673`) and dismisses from an outside tap. A plain orange view
(120x80 at 30,400) with a `UIContextMenuInteraction` produces a snapshot
preview at (201,440) and a one-action Ping card at (201,510); Ping restores
the view at (90,440). A collection item at (70,670) renders its cyan cell
(`#1a99b3`) as the preview and its Tag card at (201,760); Tag restores the
item and the collection background (`#0d0d14`). The suite checks all six
captures against those colors. A final sequence reopens the plain view's
menu, which now also holds a Share submenu: the Share row `#23242d` at
(201,567) carries a right chevron, tapping it redraws the card with a return
row (left chevron at about (96,521)) and Copy Link/Email actions below the
root rows, tapping the return row restores the root card, and tapping Email
prints `[menu] email` and restores the green background and orange view.

### Context menu action state

`tests/menu_state_test.m` raises a menu with a Pin action and a Sort
single-selection submenu. Pin carries `UIMenuElementAttributesKeepsMenuPresented`
and toggles its own state; the captures show its row checkmark appearing at
about (300,521) after the first tap and gone after the second, with the menu
still presented. Sort Name starts checked; tapping Sort Date prints
`[state] sort date name=0 date=1` and the capture moves the checkmark from the
Sort Name row to the Sort Date row without dismissing. The back row restores
the root card and an outside tap dismisses to the green background.

### Context menu palettes

`tests/palette_menu_test.m` raises a root menu with
`UIMenuOptionsDisplayAsPalette` and Red/Green/Blue actions whose 24 pt icons
are solid fills. The capture shows three 76 pt columns: red at (125,512),
green at (201,512) and blue at (277,512) inside a 92 pt card. Tapping the
green column prints `[palette] green` and restores the green background.

### Action sheets

`tests/alert_sheet_test.m` presents a `UIAlertControllerStyleActionSheet`
titled `Choose` with Share, Delete and Cancel actions. The capture is the
group card colour `#23242d` at (380,640), the Share pill `#404149` at
(60,720), the dimmed background `#0e6c29` in the 8 pt gap at (201,813), and
the separate Cancel pill at (60,840). Tapping the destructive row at
(201,777) prints `[sheet] delete 1` and the next capture is the restored
green background. A three-action alert is then presented and a tap on the
third stacked row runs `Three` (`[alert] three`), proving every stacked row
is hit-tested rather than only the bottom one.

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

### Graphics: view snapshots

`tests/snapshot_view_test.m` builds a red 100x80 source with a yellow chip
and a 12 pt rounded clip, snapshots it, places the snapshot at (200,300) and
recolors the source blue/green. The captured frame shows a blue source with a
rounded corner, while the snapshot keeps its red background, yellow chip and
rounded corner. The fixture reports `[snap] size 100.0 80.0` and prints
`ok   a view snapshot keeps old colors and rounded corners` after checking
those five pixels.

### Graphics: drawing a hierarchy into an image

`tests/hierarchy_draw_test.m` calls `drawViewHierarchyInRect:` on a rounded
red view with a yellow chip from inside a `UIGraphicsImageRenderer` action
block, reports `[hd] drew 1`, and displays the resulting image. The captured
frame shows the rendered red field, yellow chip and black rounded corner, and
the fixture prints `ok   drawViewHierarchyInRect captures a rounded
hierarchy`.

### Graphics: CGContext blend modes

`tests/blend_mode_test.m` fills a 360x240 view with 50% gray and paints red
boxes under different `CGContextSetBlendMode` values. The captured frame
reads (128,0,0) for multiply and darken, (255,128,128) for screen, lighten
and plus-lighter, (127,128,128) for difference, pure red for copy, black for
clear and destination-out, and (128,0,0) for plus-darker. A path-filled box
under multiply matches the rect-filled one. The suite samples those eleven
points with a tolerance of four levels per channel.

`tests/blend_text_image_test.m` draws a red 2x2 `CGImage` and red bold
`MMMM` text over the same gray field. Under multiply the image center reads
(128,0,0) and under screen (255,128,128); the suite also scans the two text
rows for at least twenty pixels at those values, so glyph coverage
interpolates the blend result while empty pixels keep the gray field.

### Graphics: bitmap contexts and tiled images

`tests/bitmap_tiled_test.m` draws a 2x2 red/green/blue/yellow `CGImage` as
tiles into a 60 pt rect on a (26,26,26) field. Samples at (20,20), (21,20),
(20,21) and (21,21) read the four tile colors, (79,79) reads yellow while
(80,20) keeps the field, proving the rect boundary. A second tiled rect under
a 30x60 clip paints at (125,25) but not at (155,25). An 8x8 bitmap context
fills red, then a 4x4 green square at (2,2); `CGBitmapContextCreateImage`
reports 8x8, `CGBitmapContextGetData` returns the caller's buffer with red at
(0,0) and green at (2,2), and drawing that image at 16x16 onto the
framebuffer reads red at (22,122) and green at (26,126).

### Graphics: rounded subtree clipping

`tests/rounded_clip_test.m` stacks three cards. The first clips to bounds
with a 20 pt corner radius and a red subview filling it: the center is red,
the corner is black and a point inside the arc is red. The second sets
`layer.masksToBounds` instead and behaves the same with a yellow subview. The
third has a corner radius but does not clip, so its orange subview covers the
corner and keeps the square silhouette. A fourth green card selects only
`UIRectCornerTopLeft | UIRectCornerTopRight`: both top corners are cut while
both bottom corners stay square. The fixture prints
`ok   rounded clipping masks a subtree, clipsToBounds and maskedCorners`
after checking those thirteen pixels.

### Touch: multiple fingers

`tests/multitouch_test.m` is a standalone app with two `TouchView`s at
opposite corners. It injects per-finger records into its own event FIFO:
`touch 0 down 90 90`, `touch 1 down 300 300`, `touch 0 move 120 100`, then
`touch 0 up` and `touch 1 up`. Each view logs the changed and all-touch
counts, and the output is

```
[mt] a began changed=1 all=1 fv=1/0
[mt] b began changed=1 all=2 fv=1/1
[mt] a moved changed=1 all=2 at 120.0 100.0 prev 90.0 90.0
[mt] a ended changed=1 all=2
[mt] b ended changed=1 all=1
[mt] done
```

so the second finger begins on its own hit view with one changed touch while
`allTouches` holds both; `touchesForView:` partitions them; a move carries the
view-local point and previous point; and lifting a finger removes only that
touch. `iosimctl ui <device> touch <id> <phase> <x> <y>` emits the same records
to a booted device's foreground app.

### Animation: timing functions

`tests/timing_function_test.m` reads the control points of the named
ease-in-ease-out function (`[timing] points 0.42 0.00 0.58 1.00`), evaluates
the named smoothstep curve (`[timing] ease 0.16 0.50 0.84`), evaluates a
custom cubic-Bezier built with `functionWithControlPoints::::`
(`[timing] custom 0.13 0.50 0.87`) and checks the linear function
(`[timing] linear 0.50 0.25`).

### Animation timeline and display link

`tests/display_link_rate_test.m` schedules one link at 10 fps and one at the
default rate. It reports `[dlink] duration 0.1000 0.0167`, then after 800 ms
`[dlink] rates 1 1` when the slow link fired at least four times and the fast
link fired more than three times as often (a representative run is 8 slow and
46 fast callbacks), and exits itself.

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

### Core Animation: CAAnimationGroup

`demo/AnimationGroupApp.m` adds a single `CAAnimationGroup` holding an opacity
animation (1.0 → 0.2) and a corner-radius animation (0 → 30 pt), both over two
seconds. A timer samples `layer.presentationLayer` halfway through and prints
`[group] mid opacity=0.59 radius=15.30`; the suite accepts 0.45–0.75 and
11–19 pt to allow for timer scheduling jitter. The end sample is exact:
`[group] end opacity=0.20 radius=30.00`, so both children advanced together
and held their end values. Both child animations set `removedOnCompletion` to
NO and fill mode forwards, so the completed group keeps applying its end
values until it is removed. The screenshot taken then reads the layer centre at
(201, 300) pt as `#3c1923` — 0.2 alpha red over the dark backdrop — and a
point 4 pt inside the top-left corner as the backdrop itself, so the 30 pt
corner radius is really rendered. `removeAnimationForKey:@"group"` then logs
`[group] removed opacity=1.00 radius=0.00`, and the next screenshot reads pure
`#ff3b30` at both points: the group's `key:index` children were all cleared,
not just the first slot.

### Core Animation: CASpringAnimation

`tests/spring_animation_test.m` animates a layer's opacity from 0 to 1 with
mass 1, stiffness 200 and damping 15 over 0.4 s. The derived settling duration
is 0.53 s; after 120 ms the presentation layer reports an opacity strictly
between 0.05 and 1.20, and after another 380 ms it has settled between 0.90
and 1.10. This exercises the spring branch instead of timing-function
interpolation.

### UIKit: NSString drawing

`tests/text_drawing_test.m` measures `iosim` in a 32 pt bold system font
(both width and height exceed 10 pt), draws it white at `(40,200)` inside a
real `drawRect:` and writes a PNG. It also draws the 43-character pangram into
a 160x160 rect: `boundingRectWithSize:` reports non-zero width and more than
20 pt height (several wrapped lines). The suite scans both regions at device
scale and requires at least 100/1000 light pixels; the fixture produces 9123
for the single line and 36674 for the wrapped paragraph, so measurement,
word wrapping and drawing all reach the font rasterizer through the CGContext
text bridge.

### UIKit: Single-line label fitting

`tests/label_fit_test.m` stacks three 40 pt labels of forty W characters in
100 pt-wide frames. The first enables auto-shrink with a 0.5 minimum, the
second leaves it off, and the third enables it with a 0.9 minimum. A fresh
label reports `[lfit] default 0 4`, so auto-shrink starts off and the default
line-break mode is truncating tail. `textRectForBounds:limitedToNumberOfLines:`
returns within-bounds rects of 93.0x23.7, 72.3x47.0 and 65.0x42.3 pt: the first
line height is 50.4% of the base and the third is exactly 90%. The capture
scan measures 43, 87 and 78 device pixels of ink height for the three bands,
matching those ratios, and no ink crosses the 140 pt frame edge even though
the untruncated string is far wider. This covers the opt-in shrink gate, the
minimum-scale floor, tail ellipsis truncation and text measurement.

### Graphics: UIVisualEffectView backdrop blur

`demo/BlurApp.m` draws sixteen 25.125 pt black/white stripes and puts a dark
`UIVisualEffectView` card with a 28 pt corner radius over them. The card's
render pass captures its backdrop, box-blurs the RGB channels twice with a
24 pt radius, tints the result and composites it inside the rounded-rect
coverage mask. The suite's screenshot reads the sharp stripes outside the card
at (12, 420) and (37, 420) pt as `#ffffff` and `#000000`, while the same two
stripe positions inside the card, (60, 420) and (85, 420) pt, read `#48484a`
and `#4c4d4e`: the alternating stripes have become the same dark gray average,
with every channel within 30 of its pair. A point 4 pt inside the card's
top-left corner is still `#000000` (the unblurred stripe), proving the rounded
mask, and more than 3 000 near-white pixels in the label band show the
"Vibrancy" label drawn on the contentView above the glass.

### UIKit: scroll-view insets, paging and delegate callbacks

`tests/scroll_view_test.m` builds a real `UIWindow` and a `UIScrollView`
(300×200 points, 900-point content) with 10-point insets, paging enabled and a
delegate. Synthesized touches are delivered through the window's touch path:
down at x=250, moves to 180 and 50, then up. The delegate's
`scrollViewWillEndDragging:withVelocity:targetContentOffset:` sees the paged
target `310 0`; after the snap the offset is 310 and `isDragging` is false.
The begin, did-scroll, will-end and did-end counts are `1 3 1 1` (two moves
plus the final snap each produce a scroll callback).

A second, unpaged scroll view has 50-point top and 20-point bottom insets and
1000 points of content in a 200-point frame. Dragging far past the end clamps
to 820 (1000 − 200 + 20), and `contentInset.top` reads back as 50. The test
runs directly under `iosim-run` with a 1× main screen, so it exercises the
same window hit-testing and clamping code as SpringBoard-driven apps.

### UIKit: text-field delegate and view geometry

`tests/textfield_delegate_test.m` installs a `UITextFieldDelegate`, focuses a
field, inserts `a` and `b`, offers `x` (vetoed by
`textField:shouldChangeCharactersInRange:replacementString:`), deletes the
last character and sends Return. It reports
`[tf] text [a] began 1 ended 1 changes 4 returns 1`: the veto kept `x` out,
the delete removed `b`, Return called the delegate and did not append a
newline, and begin/end fired once each.

`tests/uiview_geometry_test.m` checks the view coordinate system. A child at
(10,20,100,50) reports center (60,45); `setCenter:(100,100)` moves its origin
to (50,75); `setBounds:` with 120×60 keeps that origin and moves the center to
(110,105). Converted points are 55,80 in the parent and 75,110 in the root;
the inverse from root (35,55) is −35,−50; a 100×50 rect keeps its size. A
child inside a scroll view with contentOffset (10,20) maps its point (1,1) to
−4,−13 in the scroll and −4,87 in the root, proving the offset is applied in
the same direction as hit-testing.

### Core Animation: layer position, anchor and bounds

`tests/calayer_geometry_test.m` starts a layer at (10,20,100,50): its
position is 60,45 with the default 0.5/0.5 anchor. `setPosition:(100,100)`
moves the frame origin to 50,75. Changing the anchor to 0,0 preserves the
position and recomputes the origin to 100,100, and `setBounds:` to 120×60
keeps position at 100,100 with the new size. A UIImage assigned to
`contents` is drawn into the layer's frame by the renderer after the
background fill.

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

### Foundation: NSFileHandle

`tests/filehandle_test.m` writes `hello file handle` through a writing
`NSFileHandle`, reads all 17 bytes back, seeks to offset 6 and reads `file`,
then checks `offsetInFile` (10) and `seekToEndOfFile` (17). It closes that
read-only handle, opens an updating handle, truncates the file to 10 bytes
(ftruncate needs a writable descriptor, matching Darwin), seeks to the end and
appends `!`. `NSData` then reads the final file as `hello file!`. The output
lines are asserted individually, and the descriptor really is shared between
the seek, read, truncate and write calls because each step observes the
previous step's offset and length.

### Foundation: input and output streams

`tests/streams_test.m` reads `streamed text` through an input stream: the
status starts at 0, `hasBytesAvailable` is 1 after opening, a 4-byte read
returns `stre` and the rest comes back as `amed text`, after which the status
is 5 (at end) and a further read returns 0; closing reports 6. A file input
stream reads `hello from a file`. A memory output stream's
`NSStreamDataWrittenToMemoryStreamKey` property returns the 12 bytes
`hello stream`. A file output stream writes `file output`, and reopening it
with `append:YES` and writing `!` leaves `file output!`.

### Foundation: fast enumeration and subscripting

`tests/fastenum_test.m` joins an array with `for (NSString *s in array)`
(producing `alphabetagamma`), sums four boxed numbers to 10 with a typed
for-in, walks set members as `xyz`, and enumerates a dictionary's keys as
`k1k2k3`. Subscripting then reads `arr[0]`/`arr[2]`, replaces through
`arr[1] = @"BETA"`, appends by assigning at `count`, reads `d[@"k1"]`,
updates through `d[@"k2"] = @"TWO"`, removes with `d[@"k2"] = nil` (leaving two
keys) and confirms a missing keyed subscript returns nil. The fixture links
`objc_enumerationMutation` through ordinary for-in codegen, so the loader's
exported no-op is part of what the test proves.

### Foundation: key-value coding and automatic KVO

`tests/kvc_kvo_test.m` defines `Person` (`NSString *name`, `int age`,
`Address *address`) and reads through `valueForKey:`, which returns the name
and the boxed integer 30. `setValue:forKey:` writes `bob` and 41, and the
test confirms the ordinary getters observe both writes. A key path sets and
reads `address.street` as `Main`, and `dictionaryWithValuesForKeys:` returns
`bob` and `41` for its two keys.

For observation, a `Recorder` registers for `name` with `New|Old`; direct
`setName:@"carol"` reports `old=bob new=carol`, and a KVC
`setValue:@"dave"` reports `old=carol new=dave`, proving both entry points
reach the wrapped setter. A second recorder observes `age` with `Initial|New`:
it receives the current value 41 immediately and then `old=unset new=42`
after a direct `setAge:42` (no Old option was requested, so old is absent).
Counts are exactly `2` and `2`; after `removeObserver:` the next
`setName:@"erin"` produces no notification while the getter returns `erin`.
The suite asserts all ten lines.

### UIKit: CoreGraphics drawRect:

`tests/coregraphics_test.m` draws a red rect, green ellipse, blue stroked
rect, yellow filled triangle, a translated blue rect and a magenta CGPath
rectangle into a captured framebuffer and checks the sampled pixels.
`CGPathApply` visits five elements for the rectangle (move, three lines,
close) and `CGPathRelease` invalidates it. A `UIColor` at half red, full blue
reports alpha 1.00, equality with itself and red component 0.5 through its
`CGColor`; `CGContextSetFillColorWithColor` fills an `0x8000ff` pixel. Clipping a
full-surface green fill to a `240,10 50x40` rectangle leaves an outside red
pixel unchanged, shows green inside the clip, and a blue fill after
`CGContextRestoreGState` paints outside the old clip, proving clip removal.
Device RGB reports model 1 and device gray model 0; `CGColorCreate` with
components 0.25/0.50/0.75/1.0 returns a color whose components and alpha
match and whose space is the same object. A rectangle `CGPath` reports
bounding box `10,10 20x20`, contains `(15,15)`, rejects `(100,100)`, and a
copy contains `(20,20)`. A triangle path used as `CGContextClip` admits a
green fill at `(60,270)` inside the triangle while `(50,50)` outside stays
the earlier red, proving the even-odd mask rather than a bounding rectangle.
A cubic `CGPathAddCurveToPoint` from `(10,10)` to `(90,10)` with control
points `(30,0)` and `(70,60)` produces 20 elements (move plus 19 adaptive
lines); sampling 201 points on the true curve against the flattened polyline
keeps the maximum deviation inside the 0.25-point tolerance. A quadratic
produces 6 elements, a quadratic whose control point lies on the straight
line collapses to one line (2 elements), and a large S-curve produces 55
elements, showing the segment count follows curvature rather than a fixed
constant. A
red-to-blue two-stop `CGGradient` drawn into a 100x20 image context is red at
the left edge and approximately `0x7e0081` at the midpoint, so per-pixel stop
interpolation runs through the offscreen context. A second gradient whose
alpha falls from 1 to 0 is drawn over a white rectangle: the left pixel stays
red because the first stop is opaque, while the right pixel is white again
(`[cg] gradient fade 1 1`), proving alpha is interpolated per stop rather than
ignored. Arc coverage draws a right half-disc with `CGContextAddArc` and
checks that (90,60) is red while (20,60) and (60,15) stay clear
(`[cg] arc fill 1 0 0`); an `AddArcToPoint` rounded rectangle fills its
arc-side interior but not the cut sharp corner (`[cg] arcto fill 1 1 0`);
`CGPathAddArc` reports `[cg] path arc 1 0 bbox 20 50 60 30`;
`CGPathAddArcToPoint` reports `[cg] path arcto 1 0`; and UIBezierPath's
clockwise and counterclockwise quarter arcs select the short and long sweeps
(`[cg] ui arc cw 1 0`, `[cg] ui arc ccw 1 0`).
Line styles are sampled from a fresh region: a white 6-pixel line with a
`10,10` dash pattern is `ffffff` at `(15,226)` and background at `(25,226)`;
an 8-pixel red line with a square cap covers `(37,205)`, while the butt-capped
green line below it leaves `(37,215)` background; a 10-pixel miter L fills its
outer corner at `(93,262)` while the bevel L leaves `(193,262)` background.
`CGContextGetLineCap`/`CGContextGetLineJoin` report the last styles set
(`[cg] lineprops 0 2`).
A 2x2 yellow `CGImage` reports its dimensions and draws scaled into a 40x40
rectangle whose center samples `ffff00`. `UIImage CGImage` and
`imageWithCGImage:` round-trip the 20x20 red image without changing its
center pixel. `tests/cgimage_layer_test.m` runs a scene whose view layer has
a cyan `CGImage` as contents; the captured PNG is cyan inside the layer frame
and keeps the dark background outside it.
`tests/calayer_mask_test.m` masks a red standalone layer with a left-half
rectangle, a blue view backing layer with an oval `CAShapeLayer`, and another
red layer with a 50 percent white mask. The captured PNG is red at `(90,170)`
and background at `(190,170)` across the rectangle mask, blue at `(140,350)`
and background at `(48,306)` across the oval, and `0x85070f` (a half blend of
red over the `0x0a0f1f` background) at `(140,530)` for the partial-alpha
mask, proving mask geometry, subtree clipping and coverage multiplication.
`tests/cagradient_test.m` renders three `CAGradientLayer`s: an explicit
red/green/blue gradient with locations 0/0.25/1 (green at `(115,130)`), the
same colors with default even spacing vertically (yellow at `(180,285)`), and
a rounded 30-point layer. The PNG is green at the rounded layer's center and
keeps the background outside its corner, proving multi-stop interpolation,
both location modes, `CGColorRef` entries and the offscreen rounded path. A
fourth layer is masked by a gradient fading from opaque black to transparent:
the PNG is red at `(45,550)`, a `0x840810` half blend at `(150,550)` and
background at `(255,550)`, proving gradient alpha drives the layer mask.
`tests/calayer_transform_test.m` builds a 45-degree rotation, a 2x horizontal
scale, an identity layer and a `(40,20)` translation. The capture is red at
the rotated center and at `(120,80)` above the old top edge, background at
the old square corner `(70,110)`, blue across `(30,330)` to `(200,330)` but
not at `(5,330)`, green at the identity layer and yellow at the translated
position `(110,630)` with background at its old position, proving the
offscreen layer transform path.
`tests/shape_stroke_test.m` draws a 200-point line with `strokeStart` 0.25,
`strokeEnd` 0.75 and round caps (green at 110,100, caps reaching 87 and 193,
background at 70 and 230), an oval stroked only halfway (blue at the bottom
200,340 and both right/left endpoints, background on top), and a rounded
rectangle stroked halfway (top and right-upper orange, bottom and bottom-left
corner background), proving arc-length trimming across all shape kinds. A
fourth layer with a 12-point on/off dash pattern is yellow at `(45,560)` and
background at `(58,560)`, and reports the stored pattern count and join
style (`[stroke] dashprops 2 0`).
`tests/draw_rect_test.m` runs a real `UIApplicationMain` scene with a custom
`DrawView`; its `drawRect:`paints four shapes, writes a PNG and exits. The suite samples the PNG at
`(60,180)` red, `(250,190)` green, `(20,300)` blue stroke and `(90,455)`
yellow path, proving the renderer-to-CGContext bridge and device scale.

### UIKit: UIGraphics image contexts

`tests/uigraphics_test.m` begins a 10x10 image context at scale 2, fills it
red, and extracts a 20x20 `UIImage` whose center pixel is 255,0,0,255. It then
begins a scale-1 blue context, draws the red image with `drawInRect:` and
extracts it again, sampling red at the center to prove context compositing and
image extraction. A nested image context restores its parent on end; pushing
the outer context reports it current, fills it red, extracts red from that
context while the inner context still exists, and popping returns to the
inner context.

### Foundation: NSRegularExpression

`tests/regex_test.m` matches `([A-Za-z]+) (\\d+)` against
`abc 123 xyz 45`: two matches, two capture groups, first whole range `0 7`
with captures `abc` and `123`, second capture `xyz`. A `\\d+` expression
finds three runs and the third range is `8,3` in `a1 b22 c333`; a
case-insensitive expression matches `ABC`; and replacing `([0-9]+)` in
`a1b22` with `<$1>` yields `a<1>b<22>`.

### Foundation: NSPredicate

`tests/predicate_test.m` builds three records (`Amy 25`, `Bob 10`, `Cara 5`)
and filters them with a `price < 20 AND name CONTAINS 'o'` predicate (1
match), `NOT (price < 10) OR name == 'Cara'` (3), `name LIKE 'A*'` (1), a
two-sided numeric range (2), `name IN {'Amy', 'Cara'}` (2) and `name != nil`
(3). It also filters strings with `SELF BEGINSWITH 'p'` (1), compacts a
mutable copy with `filterUsingPredicate:` (1), and checks
`predicateWithValue:YES/NO`.

### Foundation: NSScanner

`tests/scanner_test.m` scans `42 -3.5 name=value rest`: `scanInt:` returns 1
for 42 and leaves the location at 2, `scanDouble:` returns -3.5,
`scanUpToString:@"="` yields `name`, two `scanString:` calls consume `=` and
`value`, and a final scan-up-to-`!` yields `rest` with `isAtEnd` true.

### Foundation: sorting

`tests/sorting_test.m` sorts `pear, apple, fig` with the `compare:` selector
to `apple, fig, pear`, sorts `3, 1, 2` through a key-less ascending
`NSSortDescriptor`, orders dictionary records by `name` and then by descending
`price` (`Amy 25`, `Bob 10`, `Cara 5`), and sorts custom `Person` objects with
a `compareAge:` selector (`18 30 41`). `exchangeObjectAtIndex:` swaps `1 2`
to `2 1`, and `caseInsensitiveCompare:` returns 0 for `hello` and `HELLO`.

### UIKit: scroll momentum and animated offsets

`tests/scroll_deceleration_test.m` builds an off-screen window and scroll
view, feeds twelve 25-point upward moves through the window's synthetic touch
path at 20 ms intervals, and releases. The fixture asserts the release offset
of 300 points, that `isDecelerating` and `willDecelerate:YES` are set, that
the offset advances beyond the release point, and that the momentum finishes
with `scrollViewDidEndDecelerating:`. It then sets the offset back to zero,
calls `setContentOffset:animated:YES` to 200, observes an intermediate value
after one tick and exactly 200 after 40 ticks, with
`scrollViewDidEndScrollingAnimation:` delivered.

### UIKit: scroll-view zoom, pinch and rotation

`tests/zoom_pinch_test.m` puts a 400×400 content view with a centered 20 pt
magenta marker inside a 402×400 scroll view. `setZoomScale:2` reports
`[zoom] programmatic 1 1` (zoomScale 2, content transform scale 2), and
`zoomToRect:` on a centered 100×100 rect reports `[zoom] rect 1 1 1` (scale
4, centered offsets). The fixture then writes `pinch1`/`pinch2`/`pinch3`
records moving two fingers from 80 pt apart to 160 pt through the event
FIFO: `UIPinchGestureRecognizer` ends at 2.00 and the scroll view's own
zoomScale follows to 2.00 with `scrollViewDidZoom:` delivered. Rotating the
fingers from 0° to 90° ends `UIRotationGestureRecognizer` at 90°, and
`[zoom] done 1 1` confirms both endpoints. The first capture counts 3600
magenta marker pixels; after the pinch the marker is twice as wide and
counts 13924.

### UIKit: animated UIView transforms

`tests/transform_animation_test.m` animates a 100×100 green square from
identity to scale 2 and a 120×20 green bar from 0° to 90° in one linear
0.8 s `animateWithDuration:delay:options:animations:completion:` block, then
captures the framebuffer at 450 ms and 1200 ms. At the midpoint the square
must cover x 126–276 (progress 0.5 → scale 1.5): the sample at (133,220) is
green while (120,220) is still background, which fails both when the
transform snaps to its final value and when it does not animate at all. The
bar at 45° covers (229,648) on the diagonal and has left (150,620); the final
capture has the square covering (120,220) but not (95,220) and the bar
vertical so both diagonal samples are background. At 1 s the fixture also
calls `hitTest:` at (110,220), inside the final 2x bounds but outside the
model frame, and at (95,220): `[tx] hit 1 1` proves touch conversion follows
the animated transform.

### UIKit: interactive navigation pop

`tests/nav_edge_pop_test.m` puts a green root controller inside a
`UINavigationController` and pushes a magenta detail. It reports
`[nav] gesture 1` for `interactivePopGestureRecognizer`, then injects a
left-edge drag at y=437: down at x=2, moves to 100, 150 and 240, a capture,
and an up at x=260. The capture shows the incoming root view along the left
under a dimmed strip (17–18/131–143/50–54 for the sampled green), the detail
magenta from a measured boundary column (148 pt in the recorded run) with a
darker shadow column just left of it (green channel 122 vs 143), and magenta
at the right edge. Lifting past halfway commits: `[nav] popped 1` and the
final capture is the exact green 26/204/77 across the row, with the dim and
detail gone. A second push is dragged only to 100 pt and released after a
pause so the pan velocity has decayed to zero: `[nav] cancel 1` and the
cancel capture is magenta across the row, proving the views animated back and
the stack kept the detail. The suite accepts any revealed boundary between 80
and 330 pt and requires at least an 8-level shadow drop. The navigation bar's
title and buttons stay on the outgoing controller until the transition
settles; only the content views animate.

### Foundation: NSURLSession

The suite starts `python -m http.server` on a loopback ephemeral port and a
second Python server wrapped in TLS with a freshly generated self-signed
certificate, then a guest builds `http://127.0.0.1:<port>/hello.txt` and asks
the shared `NSURLSession` for a data task. The completion handler reports
status 200, the body `hello over http`, and `Content-type: text/plain` from
`allHeaderFields`, proving the loader's host socket client, response parsing
and the background completion dispatch. The same guest requests the HTTPS
server: TLS handshake, SNI and SSL_read/write deliver status 200 and the same
body, and both `done 1` lines print. The server uses a self-signed
certificate, so the fixture runs with `IOSIM_TLS_INSECURE=1`; normal requests
verify certificates and hostnames against the system trust store. A third
task with an `ftp://` URL completes with `NSError` code -1004 (request failed
/ unsupported scheme).
A fourth request uses `NSMutableURLRequest` against a Python POST echo server:
the method is `POST`, the body is `ping`, and the header `X-Test: yes` is set
with `setValue:forHTTPHeaderField:`. The server answers
`POST ping yes`; the fixture prints `[post] status 200`,
`[post] body POST ping yes` and `[post] done 1`, proving the mutable request,
custom headers, request body and `dataTaskWithRequest:` path.

`tests/cookies_test.m` builds a cookie for `example.com`, prints its name and
value with the generated `Cookie: a=1` header, and parses `manual=yes; Path=/`
through `cookiesWithResponseHeaderFields:forURL:`. Against
`tests/cookie_http_server.py`, a GET to `/set` returns two `Set-Cookie`
headers; the guest then reads two URL-matched cookies from the shared
storage, and a GET to `/echo` sends `Cookie: session=abc123; theme=dark`,
which the server echoes back.

`tests/urlcache_test.m` points the shared cache at
`tests/cache_http_server.py`, whose `/count` response increments a counter.
The first GET reads `count 1`; a second GET of the same URL reads `count 1`
again from the cache. After `removeAllCachedResponses`, a third GET reads
`count 2`, and a request with
`NSURLRequestReloadIgnoringLocalCacheData` reads `count 3`, proving the
policy bypass. A manually stored `NSCachedURLResponse` reads back with its
`manual` data.

### Foundation: URLSession upload and download tasks

`tests/urlsession_tasks_test.m` points `downloadTaskWithURL:` at
`tests/tasks_http_server.py`, whose `/file` response is `downloaded bytes`.
The completion handler receives a temp file URL, reads 16 bytes back and
prints `[tasks] download 200 1 16 downloaded bytes`; it then removes the
file. `uploadTaskWithRequest:fromData:` posts `upload payload` to `/echo`,
and the echoed body comes back as `[tasks] upload 200 14 upload payload`.

### Foundation: KVC collection operators

`tests/kvc_operators_test.m` runs the operators over an array of boxed
numbers: count 4, sum 10, average 2.5, max 4 and min 1. An array of
dictionaries with `price` and `category` yields sum 40, average 13.3, max 25
and min 5 for `@sum.price` and friends; `@distinctUnionOfObjects.category`
returns two values in first-seen order (`a`, `b`). Two arrays [1,2] and
[2,3] flatten to four elements with `@unionOfArrays` and three with
`@distinctUnionOfArrays`. Finally `valueForKey:@"price"` on a dictionary
returns 10, proving the NSDictionary override maps to `objectForKey:`.

### libdispatch: timer and data sources

`tests/dispatch_source_test.m` creates a main-queue timer with a 10 ms start
and a 20 ms interval, resumes it and lets `NSRunLoop` run for 120 ms. The
fixture reports `[src] timer ok 6` (the check accepts 3–7 fires, since host
scheduling can move the edges). `dispatch_source_cancel` then reports
`[src] canceled 1 1 1`: the source is cancelled, its count has not grown after
another 50 ms of draining, and the cancel handler ran exactly once. The
handler is installed with the real two-argument `dispatch_function_t` ABI and
reads its `dispatch_set_context` value, reporting `[src] context 7`.

A data source on the same queue receives two `dispatch_source_merge_data`
calls, 3 and 4, before the loop runs. Its handler reports one event with
`dispatch_source_get_data` equal to 7, proving coalescing; a second pair of
merges (5 and 2) produces one more event that again reads 7, proving
`get_data` cleared the previous value. The run loop drains the main queue
because `NSRunLoop` now calls the same `iosim_dispatch_drain_main` entry as
UIKit.

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
arrays, strings, integers, reals, booleans, data and dates in XML and binary
formats. Strings are XML-escaped on the way out and unescaped on the way in;
the parser bounds nesting depth and only accepts well-formed tags.
`tests/binary_plist_test.m` writes a dictionary holding ASCII and UTF-16
strings, an integer, a boolean, a real, data, an array and a date with
`NSPropertyListBinaryFormat_v1_0`, checks the `bplist00` header and a trailer
larger than 40 bytes, then parses it back and reports
`[bplist] dict Hello 42 1 2.5 3 2`, `[bplist] array 3 4`,
`[bplist] unicode 1`, and `[bplist] date 1700000000 format 200`.

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

### Foundation: locales and time zones

`tests/locale_test.m` prints the current locale as
`[locale] current en_US en US`, splits `fr_FR` into `fr`/`FR`, reads the three
language, country and identifier keys with `objectForKey:`
(`[locale] keys fr FR fr_FR`), and accepts a dashed `pt-BR` identifier
(`[locale] dash pt BR`). With `TZ=UTC` it reports
`[tz] system UTC 0 0`, a named `America/Los_Angeles` zone at `-28800`, nil
for `Mars/Olympus`, `[tz] fixed GMT+1 5400` for a fixed offset, and eight
entries from `knownTimeZoneNames`.

### Foundation: NSCache

`tests/cache_test.m` fills an `NSCache` with a `countLimit` of two:
`[cache] two 1 1` shows both objects, adding a third reports
`[cache] evict 1 1 1` (the oldest key is gone, the other two remain), and
replacing `b` then adding `d` evicts `c` instead of `b` (`[cache] refresh
1 1 1`). `removeAllObjects` yields `[cache] clear 1`. A second cache with a
`totalCostLimit` of 5 and costs 3 and 4 evicts the first entry
(`[cache] cost 1 1`); replacing the survivor with cost 1 reports
`[cache] replace 1`, and the cache keeps its name (`[cache] name costs`).
Setting countLimit to 1 and adding two objects reports
`[cache] delegate 1` from a delegate implementing
`cache:willEvictObject:`.

### Foundation: operation queues

`tests/operation_test.m` adds three `addOperationWithBlock:` closures that
print 0, 1 and 2 and increment a shared counter, plus an `NSBlockOperation`
with two execution blocks and a completion block. It then calls
`waitUntilAllOperationsAreFinished`. All seven lines appear, the final
report is `blocks=3 pending=0 max=-1`, and the captured loop indexes are the
real 0/1/2 (the blocks are copied when added, so a stack literal cannot
observe the loop's final value). The group wait is a real join: the final
line is printed only after every worker has returned. An unlimited queue runs
the same three 30 ms blocks and reports `[fnd] freepeak 1` (peak concurrency
exceeded one, proving the blocks really overlap). A queue limited to one
concurrent operation then reports `[fnd] limit 1 0`: the observed peak
concurrency is one and the finished operations no longer count, so
`maxConcurrentOperationCount` gates dispatch rather than being stored only.

### Foundation: notifications with userInfo and blocks

`tests/notification_test.m` registers a selector observer and a block
observer for separate notification names, posts a notification carrying
`userInfo = {k: v}` to each, removes the block token, and posts again. The
output is `notify selector TestNote user=v`, `notify block BlockNote user=v`,
then `notify done`: both delivery styles see the userInfo, and the block is
not called after its token is removed.

### Foundation: date parsing and number formatting

`tests/format_test.m` parses `2024-02-29 12:34:56` with
`yyyy-MM-dd HH:mm:ss`, prints `parsed 1709210096`, formats the result with
the same formatter and re-parses it to the identical epoch (`roundtrip
1709210096`), and confirms a non-date string returns nil (`invalid no`). The
number formatters print `decimal 1,234.5` (grouping, max two fraction digits
with the trailing zero trimmed), `parsed number 1234.5` for
`numberFromString:@"1,234.50"`, `currency $99.50` and `percent 25.6%`.

### Foundation: byte and time formatters

`tests/formatter_test.m` prints byte counts under both count styles and
restricted unit masks. 999 file-style bytes stay `999 bytes`, 1000 becomes
`1 KB`, 1536 reads `1.5 KB`, 1500000 reads `1.5 MB`, and 1048576 memory-style
bytes read `1 MB`. Restricting allowedUnits to KB turns 1500000 into
`1500 KB`; turning off includesUnit reads `1.5`, turning off includesCount
reads `KB`, and includesActualByteCount reads `1.5 KB (1536 bytes)`.
zeroPadsFractionDigits turns 2048 into `2.0 KB`, and zero prints `0 bytes`.

The same fixture formats 3661 seconds as `1:01:01`, 61 as `1:01` and 3600 as
`1:00:00` in positional style; abbreviated reads `1h 1m 1s`; 90061 in short
style reads `1 day, 1 hr, 1 min, 1 sec`, in full style
`1 day, 1 hour, 1 minute, 1 second`, and with maximumUnitCount 2
`1 day, 1 hour`. Restricting units to hour/minute/second folds the day into
`25 hr, 1 min, 1 sec`. The phrase options produce
`1 hr, 1 min remaining` and `About 1 hr, 1 min`; date components format as
`2 hr, 5 min`; `stringFromDate:toDate:` reads `1:01:01`; and
`timeIntervalSinceDate:` reports 3661.

### Foundation: measurement units

`tests/measurement_test.m` converts 1.5 km to 1500 m, 1609.344 m to one
mile, 32 °F to 0 °C, 300 K to 26.85 °C, 1.5 hours to 5400 seconds, 100 km/h
to 27.7778 m/s and one US gallon to 3.7854 liters. Adding 50 cm to 1 m gives
1.5 m, and 1000 m compares equal to 1 km but not to 1 mile. The formatter
prints 1500 m as `1.5 kilometers` naturally and `1.5 km` in short style,
keeps `1500 meters` with the provided-unit option, prints `kilometers` for
the unit alone, `32 degrees Fahrenheit` for the temperature and `32` with
the temperature-without-unit option, and natural-scales 0.02 m to
`2 centimeters` while leaving 500 g as `500 grams`.

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
`tests/pasteboard_types_test.m` stores two strings, two URLs and a color and
reports `[pb] strings 2 one 1`, `[pb] urls 2 https://example.com/b 1`,
`[pb] color 1.00 0.50 0.25 0.75` and `[pb] types 1 1`: `strings`, `URLs`,
`colors`, `types` and `containsPasteboardTypes:` read back the typed item
values, and color components survive as a 32-byte data value in the plist.
`tests/pasteboard_image_test.m` reads `demo/Assets/badge.png` into `NSData`,
decodes it with `UIImage imageWithData:` (in-memory libpng) and reports
`[pbimg] decode 1 132 132`; a `setImage:`/`image` round trip reports
`[pbimg] image 1 132 132 1`, and `setImages:` with two images reports
`[pbimg] images 2 1` with `public.png` present. `tests/pasteboard_watch_test.m`
runs a UIKit app against a device, arms the general pasteboard, and waits
for `UIPasteboardChangedNotification`. While it runs, `iosimctl pbcopy
<device> "from the cli"` rewrites the device plist; the app receives the
notification, reads the new string and prints `[pastewatch] changed from
the cli`, and `iosimctl pbpaste` returns the same text. The watcher is
given an `IOSIM_EVENT_FIFO` FIFO so `UIApplicationMain` stays in its
ticking loop.

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
`tests/mach_port_lifecycle_test.c` exercises local port rights in one
process: an allocated receive port accepts a sent message and returns its
payload; `mach_port_insert_right` followed by one `mach_port_mod_refs(-1)`
keeps the port alive for a second round-trip; a further
`mach_port_mod_refs(-1)` releases the name, after which `mach_msg_send`
returns `MACH_SEND_INVALID_DEST` and `mach_msg_receive` returns
`MACH_RCV_INVALID_NAME`; `mach_port_deallocate` releases a second port the
same way (`[mach] lifecycle 1 1 1 1 1 1`).

XPC rides on the same namespace. `tests/xpc_cross_test.c` is built with
`-fblocks`; its service creates a mach-service listener
(`XPC_CONNECTION_MACH_SERVICE_LISTENER`) and resumes it, registering
`com.iosim.cross.xpc` and marking the service socket as an XPC endpoint. Every
accepted client socket is delivered to the listener handler as a connection
object (checked with `xpc_get_type(event) == xpc_type_connection`); the service
installs a message handler on that peer and resumes it. The client sends a
dictionary with a string, an int64, a bool and a 4-byte data value through
`xpc_connection_send_message_with_reply`; the peer handler prints
`xpc service: received kind=ping seq=7 flag=1 blob=4` and sends a pong
dictionary back as the reply. The client prints
`xpc client: reply kind=pong seq=8`, repeats the exchange through
`xpc_connection_send_message_with_reply_sync`, and prints
`xpc client: sync reply kind=pong seq=8`. The encoder emits a tagged tree; the
decoder bounds depth, dictionary counts, key and value lengths before
allocating, because the bytes cross a process boundary.

### Services: launchd on-demand jobs

`tests/launchd_job_test.c` is both the job and the client. The suite writes
two LaunchDaemon plists through `iosimctl launchd-load`: one with
`RunAtLoad = false` and `MachServices = {com.iosim.launchd.echo}`, and one
with `RunAtLoad = true`. The on-demand job has no log before a client looks
the name up; the client's XPC request then starts the job, which registers
the service and prints `launchd job: ready
name=com.iosim.launchd.echo`, receives `kind=ping seq=41`, replies, and
exits. The client prints `launchd client: reply kind=pong seq=42`. The
RunAtLoad job is already serving when launchd loads it and answers the same
exchange. This exercises the plist job model, on-demand MachServices
naming, and the XPC reply transport together. A third plist with
`StartInterval = 1` and no RunAtLoad starts by itself: the job's log gains
two `launchd job: interval` lines about a second apart. After
`iosimctl launchd-unload`, the line count stays put.

### Services: launchd socket activation

`tests/launchd_socket_test.c` is a job with no Mach service: its plist carries
`Sockets = {MySock = {SockPathName, SockType = stream}}`. After
`iosimctl launchd-load`, launchd_sim has bound the socket but the job has not
started (its log is empty). Connecting a Python `AF_UNIX` client and sending
`ping` makes the listener readable; launchd_sim starts the job with the
listening descriptor inherited and `IOSIM_ACTIVATED_SOCKET_FDS` set. The job's
`launch_activate_socket("MySock", ...)` returns `rc=0 cnt=1`, `accept`
returns the queued connection, and it reads `ping` and writes
`pong from socket job`; the client reads that reply and the job log records
both `[sockjob] activated rc=0 cnt=1` and `[sockjob] got ping`. A second
client gets another `pong`, and the log then holds two activation lines with
different pids: the exited job was reaped and a new process was started by the
next connection, which is launchd's on-demand socket behavior.

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

Control Center is another real surface over the same event stream. The suite
drags down from (350, 20) to (350, 240) pt and reads
`[SpringBoard] control center opened`; the screenshot's Wi-Fi toggle pixel at
(78, 232) pt is the blue on state. Tapping the toggle at (60, 232) pt logs
`control center wifi off`, and a second screenshot reads the same pixel as the
gray off state. Tapping Bluetooth logs `control center bluetooth on`, so
independent controls keep independent state, and a swipe up from the bottom
logs `control center closed`.

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

### Home-screen folders

`ui drag` holds the finger still for 0.5 s before moving, the same long press a
person uses to pick up an icon; a plain `ui swipe` starts moving after 20 ms and
pages instead, even when it begins on an icon. Dragging the Picker icon at
(62.1667, 121.8333) pt onto the DatePicker icon at (154.7222, 121.8333) pt logs
`[SpringBoard] folder created name=Folder (2 apps)`. The screenshot taken after
the drop reads the top centre of the former Picker slot, (62, 92) pt, as
`#3a3a3c` — the folder tile with its 22.37 % corner radius and mini icons.
Tapping the tile logs `folder opened name=Folder (2 apps)`; in the overlay
screenshot the background pixel at (201, 600) pt is at most half the brightness
of the same pixel on the home screen (the 58 % black dim), and the title's y
band contains more than 60 near-white pixels. Tapping the second member at
(156.75, 190) pt resumes the suspended Picker process
(`[SpringBoard] resuming Picker (pid ...)`) rather than starting a new one, so
the member mapping and the launch path are both real. Tapping outside at
(201, 700) pt logs `folder closed`. The test then reads
`data/Library/SpringBoard/folders.txt` for the
`Folder|com.iosim.datepicker,com.iosim.picker` line, shuts the device down,
boots it again, swipes to page 3 and reads the same `#3a3a3c` tile pixel: the
folder was restored from disk, not kept only in SpringBoard's memory.

### Home-screen icon drag and layout persistence

A fresh grid phone installs `Grid01`–`Grid20`, giving two pages. `ui down` on
the Fitness icon at (62.1667, 121.8333) pt, a 0.5 s hold and `ui move` to
(200, 560) pt lift the icon: the box around the finger has vivid ring pixels
(max channel spread 510, against 58 on the wallpaper beneath it), drawn at
108 %, while the tile's old slot is left out of the grid. Moving to
(392, 222.1667) pt enters the 30 pt right-edge strip, which logs
`home page 2 of 2`; the `ui up` there logs
`[SpringBoard] moved Fitness to page 2 slot 8`. The screenshot then reads the
Fitness ring colors in the second page's fourth column at (339.8333,
222.1667) pt and the active second page dot. Line 24 of
`data/Library/SpringBoard/home_order.txt` is `name:Fitness`. After a shutdown
and boot, swiping to page 2 shows the same rings in the same slot, so the
saved order, not the manifest order, drives the grid.

### Lock screen

Locking is a real system event, not a drawn overlay the test triggers directly.
From the home screen, `ui lock` logs `[SpringBoard] locked`; the screenshot then
shows more than 20 000 pure-white pixels in the big clock band (110–290 pt by
115–195 pt), more than 3 000 in the date band, the camera glyph at (333, 783) pt
as `#ffffff`, and *no* pure white in the status-bar time band (55–105 pt by
18–48 pt) — the lock screen suppresses the status clock because the time is at
display size. A swipe up from (200, 830) to (200, 600) pt logs
`[SpringBoard] unlocked`, and a screenshot again finds the status-bar clock
(greater than 500 white pixels), so the real home screen is back.

The app-lock path is asserted through lifecycle order. The suite installs
`demo/LockApp.m` (a scene app that prints its state at every transition), taps
its third-page icon and waits for `[lockapp] ready state=0`. Sending `lock`
then produces `[lockapp] resign state=1`, `[lockapp] background state=2`, and a
lock screen screenshot with the same big-clock pixel count. Unlocking logs
`[SpringBoard] resuming LockApp (pid ...)` followed by
`[lockapp] foreground state=1` and `[lockapp] active state=0`: the same stopped
process continued, and its view controller was never recreated.

### System notifications

`UserNotifications.framework` is exercised first in-process by
`tests/notifications_test.m`: authorization grants alert/sound/badge, settings
report authorized, a time-interval request is accepted and written to the
shared schedule, a foreground request reaches the delegate, a one-shot request
leaves both the pending list and the shared schedule, a repeating request fires
again, and removing pending identifiers stops it and clears delivered entries —
with no schedule files left behind. The suite also runs
`tests/notification_app_test.m` through the real system UI. The fixture
schedules "Lunch" at 2 s; sending home suspends it, and SpringBoard logs
`[SpringBoard] notification banner Lunch`. A screenshot 0.6 s later samples the
banner card at (201, 100) pt as `#35353e` and its icon at (46, 84) pt as white,
while (201, 300) pt remains wallpaper — a real card, not a full-screen overlay.
Tapping the banner logs `[SpringBoard] notification opened Lunch` and
`[notifyapp] didReceive first Lunch` after the same stopped process resumes; the
response delegate schedules "Meeting" at 4 s. Home again, and the background
request banners; a swipe up logs
`[SpringBoard] notification banner dismissed`. A top-edge drag opens
Notification Center, where a screenshot finds the delivered card at
(201, 240) pt and the big clock's white pixels, and tapping the card logs
`[SpringBoard] notification opened Meeting` and
`[notifyapp] didReceive second Meeting` — the response file handoff reaches the
app after its second suspension.

The fixture also attaches badge 3 to "Lunch": the banner screenshot counts red
badge pixels in the icon's top-right corner, and after the response clears the
badge through `applicationIconBadgeNumber`, a second screenshot taken while
"Meeting" banners finds no red there. `tests/notification_actions_test.m`
registers category "lunch" with Snooze and Delete and schedules "Dinner" at
2 s. A 0.6 s long press logs `[SpringBoard] notification actions Dinner`; the
expanded card grows two 44 pt rows, and a screenshot finds card fill at
(201, 160) pt plus blue and red action-title pixels. Tapping the first row logs
`[SpringBoard] notification action snooze (Dinner)` and
`[actions] didReceive actionable Dinner action=snooze`, and the delegate
schedules "Dinner 2". That request is dismissed, its card is long-pressed in
Notification Center, the action sheet below it is sampled at (201, 310) pt,
and tapping the destructive row logs `[SpringBoard] notification action delete
(Dinner 2)` and `[actions] didReceive actionable2 Dinner 2 action=delete`. A
request written directly to the shared schedule as "Locked" banners, is
dismissed, and remains as a lock-screen card; the screenshot samples the card
at (201, 500) pt and its white title pixels, and tapping it logs
`[SpringBoard] unlocked`, `[SpringBoard] notification opened Locked` and
`[notifyapp] didReceive locked Locked`.

### CoreAnimation: replicator layer

`tests/replicator_test.m` adds one white 20 pt dot to a `CAReplicatorLayer`
with `instanceCount = 8`, a 45-degree `instanceTransform` and an orange
`instanceColor`. A second replicator translates four copies 60 pt apart and
adds 0.15 to the blue channel per copy. The suite screenshots the frame and
samples the eight 45-degree positions at radius 90 pt around (201, 437):
every sample must be orange, and the center must stay black. It also samples
the translated row at (70, 620), (130, 620), (190, 620) and (250, 620): all
red, with blue rising roughly 0, 38, 76 and 114. A third replicator holds one
white bar with `instanceCount = 3`, a 70 pt translation, an
`instanceDelay` of 2.5 s and a six-second opacity fade from 0 to 1 with
backwards fill. Three seconds after the first screenshot, (85, 730) pt is
bright, (155, 730) pt is dimmer by at least 40 levels, and (225, 730) pt is
still black, so each copy evaluates the animation at its own delayed phase.

### CoreAnimation: emitter layer

`tests/emitter_test.m` centers a `CAEmitterLayer` on a black screen with one
orange cell (`birthRate 30`, `lifetime 2`, `velocity 120` plus range,
`emissionRange` 2 pi, scale/range and `alphaSpeed`). The suite waits for
`[emitter] ready`, screenshots, and counts orange samples on a 2-pixel grid:
more than 1000 overall and at least 100 in each screen quadrant, proving the
particles are spread around the emitter rather than stacked at its origin.

### CoreAnimation: animation timing and transactions

`tests/animation_timing_test.m` drives four opacity animations and samples
`presentationLayer.opacity` from timers. A fade with `beginTime` 0.5 s in the
future and `fillMode = @"backwards"` samples 1.0 before its start, about 0.75
midway and 0.0 after it ends; the fixture commits the layer's model opacity
to 0 after adding the animation, so the default-removed animation falls back
to 0.0 when its active span ends. An `autoreverses` fade runs forward over
its one-second duration and back over a second second: each sample is checked
against the opacity implied by its measured elapsed time (0.75 at quarter
time, 0.25 at three-quarter time, 0.15 again partway through the reverse pass)
and the fourth sample after two seconds reads the start value 1.0. A `speed = 2` fade
samples about 0.4 at 0.3 s, and a `timeOffset = 0.5` fade samples the same.
The fixture also requires `[CATransaction animationDuration]` to be 0.50, its
completion block to run, `performWithoutAnimation:` to complete its inner
animation block immediately, and `areAnimationsEnabled` to stay true.

### UIView keyframes

`tests/keyframe_test.m` moves a white box with three keyframes over one
second: hold at x=100, slide to x=200, then slide down to y=500. Timers log
`[keyframe] move <x> <y>` at 0.35 s (x between 120 and 190, y still 300),
`[keyframe] turn <x> <y>` at 0.6 s (x 200, y between 320 and 480) and
`[keyframe] end <x> <y>` at 1.2 s (200, 500). The completion block must log
`[keyframe] done 1`.

### UIView spring animations

`tests/spring_ui_test.m` animates two white boxes from x=40 to x=240 over one
second with `animateWithDuration:delay:usingSpringWithDamping:initialSpringVelocity:options:animations:completion:`.
The first uses damping 0.5 and the second damping 1.0. At 0.25 s the soft
spring's presentation origin is 250.9 (past the 240 target) while the
critically damped box is at 187.3, approaching from below. At 0.75 s the
soft spring has returned to 235.0 and the critical one has reached 239.2, so
the damping ratio changes both the overshoot and the settle path.

### UIView cross-dissolve transitions

`tests/transition_test.m` puts a red 200x120 view with a yellow chip at
(40,280) and runs `transitionWithView:duration:options:animations:completion:`
with `UIViewAnimationOptionTransitionCrossDissolve` for 0.6 s, changing the
background to blue and the chip to green. At 0.3 s the captured background is
(118,0,137), a roughly even blend of the old red snapshot and the new blue;
the chip reads (118,255,0), the yellow snapshot over the new green. Outside
the view stays black. At 0.9 s the frame is pure blue (0,0,255) with a green
chip (0,255,0), and the transition logged `[trans] done 1`, so the snapshot
overlay is removed after the fade.

### CoreAnimation: completion and fill modes

`tests/animation_removal_test.m` starts three 0.5 s opacity animations from
1.0 to 0.25 on separate layer-backed views. The first leaves
`removedOnCompletion` at its default YES, the second disables removal and
sets fill mode forwards, and the third disables removal without a fill mode.
At 0.25 s all three presentation opacities read 0.62. At 0.8 s the removed
animation is back at the model value 1.00 and `animationForKey:` returns nil;
the forwards animation still reads 0.25 and remains attached; the unfilled
animation is back at 1.00 but still attached. The suite checks those values
and the (0,1,1) membership flags.

### UIViewPropertyAnimator timing parameters

`tests/property_animator_test.m` builds two animators over one-second frame
moves from x=40 to x=240. The first takes `UICubicTimingParameters` with
control points (0.42, 0) and (0.58, 1); the second takes
`UISpringTimingParameters` with damping ratio 0.5 initialized through
`initWithDuration:timingParameters:`. The fixture prints `[pram] timing
0.58 0.50 1.38`, confirming the control point, the damping ratio and the
computed settling duration `ln(1000)/(zeta*10)`. At 0.25 s the cubic
animator is at about x=67 and the spring at about x=250: the Bezier eases
slowly below the linear midpoint, while the underdamped spring overshoots
the target before settling. At 1.2 s both presentation frames report 240.0
and both animator states are inactive. The suite checks the printed
parameters, the mid-sample ranges and separation, and the settled end
state.

### CoreAnimation: keyframe calculation modes

`tests/keyframe_modes_test.m` starts five 2 s opacity keyframe animations at
once and samples each presentation layer 0.25 s later, when progress is about
0.13. With values 0, 0.9, 1 at key times 0, 0.5, 1, linear interpolation reads
0.239, discrete holds the first value at 0.000, and paced timing spaces the
progress by distance so the sample is 0.133. A 0, 1, 0 spline in cubic mode
reads 0.317 (the Catmull-Rom curve is above the 0.25 linear value), and the
same values with an ease-in timing function read 0.071 (below linear). The
fixture exits after printing `[kfmode] done`; the suite parses the five
samples and checks those relationships with timing-tolerant ranges.

### CoreAnimation: layer position animations

`tests/layer_position_test.m` animates two white 40 pt boxes for two seconds
with animations added directly to their backing layers. The first uses a
`CABasicAnimation` from position (60,300) to (260,300); the second uses a
`CAKeyframeAnimation` with CGPoint values (60,500), (260,500), (160,500) at
key times 0, 0.5 and 1. At 0.25 s the presentation frames report origins
65.1,280 and 90.3,480, both moved from their base x of 40. The capture's white
ink spans 65.3–105.0 and 90.7–130.3 pt, so the renderer moved the views, and
the sample points (83,300) and (108,500) are white while (50,300) and
(55,500) are black. The same `current_frame` path feeds hit-testing and
`presentationLayer`, keeping rendering and reported geometry consistent.

`tests/layer_path_test.m` gives one box a straight CGPath from (60,300) to
(260,300) over two seconds and another a quadratic path from (60,500) through
control point (160,450) to (260,500) over half a second. At 0.25 s the
presentation origins are 66.5,280 (moved along the line) and 146.1,455.3 (the
curve's center sits at about 475 pt, near the apex). The captured white ink
spans 66.7–106.3 and 146.7–186.3 pt; (83,300) and (160,475) are white while
(50,300) and (55,500) remain black, so both the line and curve paths move the
rendered views by arc length.

### Image renderer and PNG output

`tests/image_renderer_test.m` uses `UIGraphicsImageRenderer` at scale 1 to
draw a blue 100x60 field with a red square, shows it in a `UIImageView`, and
uses `PNGDataWithActions:` to write a 40x40 green PNG to
`/tmp/iosim-image-renderer.png`. The suite waits for `[renderer] ready`,
checks the log's `written 1`, samples the image view for blue and red pixels,
then loads the PNG file with Python and requires its center pixel to be green.

### Attributed strings

`tests/attributed_test.m` assigns an attributed string with a bold 22pt red
font to a label, a mutated attributed string to a button, and an attributed
string to a text view. It also gives a button a rendered magenta image, gives
another a filled `UIButtonConfiguration` with a green capsule background, and
sets a rounded-rect border on a text field. The suite requires
`[attr] label Hello 5 22`, `[attr] button Wo! 3 1`,
`[attr] textview Hello 5`, `[attr] image 1 1`, `[attr] config Cfg 1` and
`[attr] field 3`, `[attr] textlayer M 30`, `[attr] transition 1 1`,
`[attr] bar 1 1`, `[attr] vc 1 1 30`, `[attr] access 1 Acc 64` and
`[attr] gestures 1 3 2 1 1`, `[attr] frame 0 0 80 20`,
`[attr] fieldvalue Hello`, `[attr] table 0 1 60`,
`[attr] collection 1 1 0` and `[attr] scroll 1 2 0`, then samples the
screenshot for the
magenta image, green configuration background, dark field background and the
white pixels of the text layer's string.

### Foundation: attributed string attribute runs

`tests/attributed_runs_test.m` colors `HelloWorld` red through index 4 and
blue from index 5, then adds a bold 20 pt font over indices 2-5. The added
attributes split the red run into `(0,2)` and `(2,3)` and the blue run into
`(6,4)`; the fixture prints those effective ranges and the surviving colors.
A green `setAttributes:` over indices 8-9 produces `(8,2)`. Replacing
characters 2-5 with `XY` yields `HeXYorld`, keeps the inserted text's red
font attributes, and shifts the later runs; appending a two-character blue
attributed string extends the text to length 10 with a `(8,2)` blue tail, and
an immutable copy reports the same runs.

### UIKit: attributed label runs

`tests/attributed_label_test.m` centers a `RedGreenBlue` attributed label
with a red 24 pt run, a green 32 pt run and an underlined blue 24 pt run.
The captured frame has all three colors; the green run's glyph height is
71 px against the red run's 54 px, so the per-run font sizes reach the
renderer. The blue run is 179 px wide and its widest row is 179 px, the
underline spanning the run below the glyph baseline, and the overall run
block centers at 200.8 pt in the 360 pt-wide, centered label.

### UIKit: paragraph styles in attributed labels

`tests/paragraph_style_test.m` gives a multiline label the attributed string
`Red\nGreen` with a mutable paragraph style that centers each line and adds
10 pt of line spacing, while the label itself is left-aligned. The captured
frame reads red line pixels centered at 600.5 px and green line pixels at
599.5 px, both on the label's 600 px center line, and the green line starts
57 px below the red line's last glyph row, matching the 10 pt spacing.

### UIKit: attributed text views

`tests/textview_attributed_test.m` puts `Red Blue Green` into a 20 pt
UITextView with red, blue and green runs and an underline on the blue run.
The frame reads the runs left to right, and the blue run's 128 px wide row
is its underline, which extends 8 px below the red run's baseline. The text
view keeps its base font metrics, so this color pass does not disturb
selection or caret geometry.

### Page view controllers

`tests/pageview_test.m` installs a scroll-style horizontal page controller as a
child of the root controller, sets a red page, then replaces it with a green
one. The suite requires `[page] pages 1 children 1 parent 1 root 1`,
`[page] next 1 super 1 done 1` and a green center pixel.

### Foundation helpers

`tests/foundation_extra_test.m` exercises `NSCharacterSet` trimming, numeric
string conversion, capitalization, percent decoding, mutable character sets,
range replacement and lookup, and UIFont weights. The suite requires every
logged result, including `[fnd] trim 'Hello World'`,
`[fnd] font 14 System 20`, `[fnd] color 1 0 0 1.0 0.1 0.4 1.0 0.25`,
`[fnd] desc 17 17`, `[fnd] readable 16 0 370 874`,
`[fnd] props 1 0 1 3`, `[fnd] url https example.com 8080 /a/b x=1`,
`[fnd] comp https://example.com:8080/a?q=2#top example.com`,
`[fnd] pfont 17`, `[fnd] present 7 1 2 2 0`, `[fnd] value 3 4 2 5 1`,
`[fnd] idx 4 2 11 1 28`, `[fnd] scene 1 0 iosim-scene-session`,
`[fnd] qitems 2 a two`, `[fnd] qbuild k=v`,
`[fnd] device iPhone 18.0 0 1`, `[fnd] process iosim 4 4`,
`[fnd] uuid 36 1`, `[fnd] affine 7 9`,
`[fnd] vcprops 15 1 0 320 480`, `[fnd] searchupdate 1`,
`[fnd] search 1 1 0`, `[fnd] vendor 1`, `[fnd] idxmore 10 5 10`,
`[fnd] b64 aGVsbG8= 5`, `[fnd] urlappend /tmp/a/b`,
`[fnd] axel E 1 3 4`, `[fnd] pct a%20b&c`, `[fnd] hue 0 1 1 1`,
`[fnd] alert 1 1 0 1`, `[fnd] viewwin 1 0`, `[fnd] appext a.txt /tmp/a.txt`
and `[fnd] scene2 1 1`. The alert line adds a text field through the
configuration handler, disables the preferred action and checks that the
controller keeps both. The view line runs after the window is key, so the
root view must find its window through the superview chain. The presentation
line configures a
popover source view, two sheet detents, a large-title mode and an empty
bar-button array, so the presentation controllers and the `__NSArray0__`
literal path are exercised too.

### Mask views and interaction

`tests/mask_interaction_test.m` overlays a disabled red view on a green view
and masks a blue view with a white half-width view. The suite requires the
hit test to return the green view with `[mask] hit 1 enabled 0`, the red
overlay to still draw, the masked view blue on the covered half and black on
the other.

### Radial gradients

`tests/radial_gradient_test.m` draws a red-to-blue radial layer and a rounded
yellow-to-purple one. The suite requires a red center and blue edge on the
first, a yellow center, black rounded corner and blended top edge on the
second, and the log line
`[radial] scene 1 windows 1 key 1 scenes 1 level 2000` from the window/scene
APIs.

### Layout margins

`tests/layout_margins_test.m` gives a 200x200 container 20-point margins and
pins a green child to all four edges of its `layoutMarginsGuide`. The suite
requires the log lines `[margins] edges 20 20 20 20` and
`[margins] guide 20 20 160 160`, a dark-gray margin band at (60, 310) and
(60, 490), green through the child's inset rectangle, and black outside the
container. The controller then adds 10/12 points of
`additionalSafeAreaInsets`; the suite requires `[margins] safe 72 46`,
`[margins] safeguide 0 72 402 756`, and `[margins] color 1 255 128 0 1 0.25`
from the UIColor getters.

### Custom backing layers

`tests/layer_custom_test.m` subclasses `UIView` and returns
`[CAGradientLayer class]` from `+layerClass`, then sets a red-to-blue horizontal
gradient on the view's own layer. The suite screenshots and requires red at
(60, 350), blue at (240, 350), a blended purple midpoint, black outside the
frame and a green sibling view. The fixture also adds two keyed animations and
logs `[layer] keys 2 1`, then calls `removeAllAnimations` and logs
`[layer] after 0 1`.

### Animation delegate callbacks

`tests/animation_delegate_test.m` adds three opacity animations with a shared
delegate: a 0.3 s fade, a 2 s fade and an infinite repeat. At 0.1 s it removes
the two long-running animations. The suite requires exactly three start
callbacks, one `animationDidStop:finished:YES` (the fade) and two
`finished:NO` (the removals), and the fixture's final counts line to read
`[delegate] counts 3 3`.

### Layer contents, safe areas and small APIs

`tests/contents_test.m` renders a 40x20 red/blue image and puts it in two
square layers: one with `contentsGravity = resizeAspect` (letterboxed to
100x50) and one with `contentsRect` covering the right half (stretched blue).
The suite screenshots and requires red at (120, 350), blue at (180, 350),
black at (150, 310), blue across the cropped layer, and black outside it. The
fixture also logs `[contents] safe 62 34` from `safeAreaInsets`,
`[contents] screen 1206 2622 3 1` from the screen's native bounds/scale and
brightness, `[contents] idle 1` after setting `idleTimerDisabled`, exercises
every feedback generator, and requires `canOpenURL:` true plus an `openURL:`
completion reporting false.

### Tint colors

`tests/tint_test.m` puts three 320x120 buttons on a white screen. The first
two sit in containers with explicit red and green tints and no custom title
colors; the third inherits the window's default blue. The fixture logs
`[tint] inherited 1 1` when each button's `tintColor` is the same object as
its container's, and the suite screenshots the three button rectangles:
mostly red samples in the first, green in the second and blue in the third.

### Appearance

`tests/appearance_test.m` draws its background with `systemBackgroundColor`
and its label with `labelColor`, logs `[appearance] initial <style>` from
`viewDidLoad` and `[appearance] style <style>` from
`traitCollectionDidChange:`. The suite launches it on a fresh device, waits
for `initial 1`, and a screenshot samples (201, 300) pt as white with the
label box black-on-white. `iosimctl ui <device> appearance dark` logs
`style 2`; the next screenshot samples the background as black and the label
box white-on-black. Switching back logs `style 1` and restores the light
pixels. Sending the app home and switching to dark logs
`[SpringBoard] appearance dark` and leaves `appearance.txt` containing
`dark`; the suite switches back to light and waits for SpringBoard's light
log. The fixture's `preferredStatusBarStyle` returns light content in dark
appearance and dark content in light; the suite counts dark time glyphs in
the light screenshot and light glyphs in the dark one. Home-screen
screenshots after each SpringBoard switch sample the search glass at
(170, 718) pt: dark below 80 and light above 90. A second fixture,
`tests/blur_material_test.m`, puts a system-material card over a uniform
gray field and logs `[blur-material] style <style>` from
`traitCollectionDidChange:`; the suite samples the card at (60, 420) pt:
above 140 in light appearance and below 110 after the dark switch, while the
backdrop outside stays near 128. `tests/statusbar_test.m` has a button that
toggles `prefersStatusBarHidden` and calls
`setNeedsStatusBarAppearanceUpdate`; the suite counts dark time glyphs before
the tap, after hiding, and after showing again. `tests/statusbar_plist_test.m`
sets `UIViewControllerBasedStatusBarAppearance=NO` and
`UIStatusBarStyle=UIStatusBarStyleLightContent` in its Info.plist over a gray
background, and the suite checks for white time glyphs.

### UIKit: pull-to-refresh

`demo/RefreshApp.m` attaches a `UIRefreshControl` to a twelve-row table. The
suite drags from (200, 120) to (200, 300) pt, which the scroll view clamps to
its refresh overscroll, and waits for `[refresh] pulled`: `beginRefreshing`
snapped the offset to `-60 pt` and sent `ValueChanged`. A screenshot taken
while the timer-delayed refresh is still running counts 1 800+ bright pixels in
the spinner box (176–226 pt by 62–118 pt); the fixture's `endRefreshing` then
logs `[refresh] done`, and a second screenshot counts no bright pixels in that
box — the spinner stopped its infinite animation and the content returned to
offset zero. The control is a real subview positioned by the scroll view, and
its spinner shares the activity indicator's blade renderer. The table's
`refreshControl` setter delegates to `UIScrollView`, which installs the control
as a subview; assigning the inherited ivar alone leaves the spinner invisible
even though `isRefreshing` is true.

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
The fixture also begins a background task from `applicationDidEnterBackground:`
and runs 300 ms of work on an `NSOperationQueue`. The suite observes
`bg began 1 remaining`, then `bg work`, `background task window closed` and
only then `backgrounded by the system; suspending`: the process stays live
until the task ends instead of stopping immediately. A separate fixture checks
that `beginBackgroundTaskWithExpirationHandler:` returns token 1 while the app
is active, that `backgroundTimeRemaining` is 0 outside a window, and that
ending the task clears it without invoking the expiration handler.

### Kernel symbolication and XNU dispatch tables

The suite builds `tests/kernel_symbols_fixture.c` as a non-PIE x86_64 Mach-O
with a two-entry mach trap table (`{arg_info, handler, munge}` at 24 bytes) and
a two-entry syscall table (`{call, munge, return type, narg, arg bytes}`).
`tools/kernel_symbols.py` reports 8 symbols with 100.000 % executable-byte
coverage, detects both tables at stride 24, resolves trap 0/1 to `_trap_alpha`
and `_trap_beta` with argument counts 2 and 1, resolves syscall 1 to
`_trap_beta` with narg 2, writes an address-ordered map containing the local
`t` symbols, and prints `_trap_beta` for an exact address and
`_trap_beta + 0x8` for an interior one.

Run against the locally supplied Kernel Debug Kit 27.0.1 (build 26A434), the
release kernel is x86_64 with UUID `8f0fa4f88dc23768a7eb04e58c6d1b88`.
Merging the binary's 24,379 symbols with the dSYM's 50,898 (27,546 text)
yields 99.275 % coverage of executable bytes (9,480,623/9,549,866); the residue
is `__KLD,__text` boot code absent from the dSYM, not unidentified functions.
An address inside `_mach_call_munger` prints
`0xffffff80003e0a00  _mach_call_munger + 0x30  [__TEXT,__text]` and resolves
through DWARF to `bsd_i386.c:506`.

The decoded `_mach_trap_table` holds 128 entries: trap 0–9 are `_kern_invalid`,
10 `__kernelrpc_mach_vm_allocate_trap` (4 arguments), 26 `_mach_reply_port`,
31 `_mach_msg_trap` (7), 45 `_task_for_pid` (3), 100
`_iokit_user_client_trap` (8). `_sysent` holds 558 entries: 0 `_nosys`,
1 `_exit` (narg 1), 2 `_fork`, 3 `_read` (narg 3), 4 `_write` (narg 3),
5 `_open` (narg 3), 6 `_sys_close`, 7 `_wait4` (narg 4), each with its
`_munge_*` argument munger resolved. The dispatch routines agree:
`_mach_call_munger64` indexes at `index*24` and calls `*(entry+8)`, and
`_unix_syscall64` indexes at `index*24`, calls `*(entry+0)` and reads narg at
`entry+0x14`. `docs/KDK.md` records the unpacking steps and full measurements.

### Loader: initializers, thread-locals, pthread objects and Darwin ABI shims

`tests/loader_runtime_test.c` is an x86_64 Mach-O linked with
`__TEXT,__init_offsets`, `__thread_vars` and a nonzero `__thread_data`. Its
constructor increments a `__thread int` initialized to 41, records whether a
static `PTHREAD_MUTEX_INITIALIZER` was normalized, and the program then proves
each subsystem:

- `[lrt] ctor 1 tls 42`: the image-base-relative constructor ran before
  `main`, and the thread-local copy carried the 41 from `__thread_data`.
- `[lrt] mutex normalized`: the load-time scan replaced the Darwin signature
  `0x32AAABA7` with a host mutex before the constructor observed it;
  `[lrt] lock 0 0` locks and unlocks through the guest pthread symbols.
- `[lrt] sha256 ba7816bf…` and `[lrt] md5 90015098…`: the loader's CommonCrypto
  implementation matches the standard `abc` vectors.
- `[lrt] data 13 1 13`: `dispatch_data_create` reports the payload size, the
  applier block runs once and receives all 13 bytes.
- `[lrt] sigmask 0 old 0`: Darwin's `SIG_SETMASK` value 3 is translated to the
  host mask operation and the 32-bit Darwin sigset round-trips.
- `[lrt] stat 0 1 3`: `open` with Darwin `O_CREAT|O_RDWR|O_TRUNC` creates the
  file, `fstat` fills the 144-byte Darwin `struct stat`, the mode reads back as
  a regular file and the size as the three written bytes.

### Optional Zig toolchain and inline-assembly getter

With Zig 0.17.1, `zig cc -target x86_64-ios-simulator` emits Mach-O objects
whose `LC_BUILD_VERSION` names `iossimulator` with minimum iOS 18.0. The
optional `tools/build_app_zig.sh` links Foundation and produces a PIE
executable without an Apple SDK; `tests/fastenum_test.m` and
`tests/kvc_kvo_test.m` both build and reproduce their full output under
`iosim-run`. The executable carries the normal Foundation and libSystem
dependencies.

`loader/tlv.zig` is an instruction-for-instruction inline-assembly version of
the TLV getter, selected by `-DIOSIM_USE_ZIG_ASM=ON`. It preserves the padding
`rax` slot, the caller-saved GPRs and all sixteen XMM registers around the C
slow path, discards the saved `rax`, and returns the address in `rax`.
Building with the option and running `tests/run_tests.sh` through
`IOSIM_RUN=build-zig/iosim-run` keeps the `[lrt] ctor 1 tls 42` thread-local
check green, so the two spellings are behaviorally equivalent for the fixture.
The default build remains C plus GNU assembly.

### Running Apple's Metal Shader Converter natively

Unpacked locally (not redistributed), the macOS x86_64
`metal-shaderconverter` 4.0.3 runs under `iosim-run` through the opt-in host
symbol bridge. `--version` prints `metal-irconverter version: 4.0.3` and
`Default triple: air64-apple-macosx15.0.0`; `--help` lists the full option
table only after the loader executes the binary's 242 `__init_offsets`
constructors (before that, only LLVM's generic options exist).

A DXIL pixel shader compiled by Microsoft's Linux `dxc` (`ps_6_0`, entry
`main`) converts end to end:

```
tools/host-run.sh …/metal-shaderconverter shader.dxil -o=shader.metallib
→ exit 0, shader.metallib 4512 bytes
```

The output starts with `MTLB` and its container strings include `NAME`,
`main`, `TYPE`, `HASH`, `VERS`, `UUID` and `ENDTRLST`. Getting there required
Darwin pthread static-initializer normalization (the initial attempt deadlocked
in `DXIL2AIR::assemble` on the global assemble mutex), thread-local thunk
support (`llvm::ThisThreadsStreamIDToken` and the TimeTrace profiler),
CommonCrypto, `dispatch_data`, and Darwin signal/stat/open translation.
`docs/METAL-SHADER-CONVERTER.md` records the unpacking and run steps; the
converter itself is a DXIL→Metal IR tool and does not compile Metal source or
render anything, so this proves the loader/ABI path rather than a Metal
framework.

## Limitations

The framework surface is still a subset. Auto Layout supports equality and
inequality anchors with priorities evaluated by relaxation, intrinsic sizing
and guides, but not the full Cassowary solver or every UIKit layout API.
`NSUserDefaults` persists XML property lists under the app's
`Library/Preferences`, while `NSPropertyListSerialization` also reads and
writes binary property lists. JSON covers
Foundation objects without comments, streaming or fragments unless enabled.
Text input is `UITextField` and an append-only `UITextView` with a QWERTY
keyboard; text selection, multitap gestures and selection handles are not
implemented. Touch input delivers per-finger
down/move/up records with their own hit view and `allTouches`, but fingers
landing together arrive as separate events; there is no touch prediction or
pressure. Controls, scroll views and gesture recognizers still track the
primary touch, and SpringBoard's own UI remains single-touch. Mach
messages, the bootstrap namespace and serialized XPC dictionaries are shared
across guest processes. SpringBoard pages in groups of 16 without a sliding
page animation, and the switcher shows at most three cards with no scrolling
animation; stock system apps have no executables in this runtime. Home-screen
folders group apps by bundle identifier and persist; they cannot be renamed or
nested, and the grid compacts entries when a folder forms. Icons can be
reordered by dragging them to empty slots, including across pages, with the
layout persisted in `home_order.txt`; folder tiles themselves are not
draggable. The lock screen has no passcode, Face ID, notifications or
widgets; unlocking is the swipe-up/home gesture.
Backgrounded apps are suspended in place (SIGSTOP) and resumed from their icon
or switcher card, with no memory-pressure termination policy.
`UIApplication` tracks active/inactive/background state and posts the
lifecycle notifications. `beginBackgroundTaskWithExpirationHandler:` returns a
live token and opens a five-second execution window before suspension; ending
all tasks closes the window early, and tasks still active at the deadline get
their expiration handlers before the process stops. CoreText shaping is limited to the glyphs in SFUI;
right-to-left and complex scripts are not shaped. `UIView.transform` applies a
full 2D affine transform (translation, scale and rotation) through an offscreen
composite; animating one interpolates decomposed rotation, scale and
translation, and touch conversion and hit-testing invert the transform, but
skewed transforms interpolate as their nearest rotation plus scale.
`UISplitViewController` supports double- and triple-column layouts with an
optional supplementary column, its compact collapse, column width controls and
the supplementary-column lookup; column-level delegate customization is not
modeled. `CATransform3D` layers project through a homography when the
perspective terms are set; 3D rotation, scale and translation render, but
the layer's offscreen is still its untransformed size, so extreme perspective
can clip. Core Animation keeps four
explicit animation slots per layer. `CADisplayLink` honors
`preferredFramesPerSecond` but not `CAFrameRateRange`. XPC carries dictionaries
and value objects between processes but not connections, file descriptors or
reply ports. The pasteboard shares strings, URLs, colors and PNG images but has no
item providers or removal notifications. Metal and video
remain unimplemented. The kernel symbolication tool handles one Mach-O image
and its dSYM; kext dSYMs are not merged into one address space because their
load addresses are only known from a kernel collection. Running macOS
command-line tools relies on the opt-in `IOSIM_HOST_SYMBOLS` bridge and on
host libc++/libarchive/libbz2 being installed; guest processes under the
normal simulator path do not use it. There is no Metal framework or Metal
shader compiler: the Metal Shader Converter accepts DXIL and emits Metal IR,
but the runtime cannot yet execute that IR.
