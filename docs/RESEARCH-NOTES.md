# Research notes and working plans

Running notes for artifacts and findings that are easy to lose between
sessions. Measurements that belong in a shipped feature also land in
`ARCHITECTURE.md`/`VERIFICATION.md`; this file keeps the raw trail.

## 2026-11-20: Kernel Debug Kit 27.0.1

- Release kernel is **x86_64** Mach-O, UUID `8f0fa4f8…`, 24,379 exported
  symbols; dSYM has 50,898 (27,546 text). Merged coverage 99.275 % of
  executable bytes (`__KLD` code has no dSYM symbols).
- `_mach_trap_table`: 128 entries, 24-byte rows,
  `{arg_info @+0, handler @+8, munge @+16}`; low byte is arg count.
- `_sysent`: 558 entries, 24-byte rows,
  `{call @+0, arg_munge @+8, return type @+16, narg @+20, arg bytes @+22}`.
- `_mach_call_munger64` and `_unix_syscall64` confirm both strides in code.
- Tooling: `tools/kernel_symbols.py`, `tools/pbzx.py`; write-up in
  `docs/KDK.md`.

## 2026-11-20: Apple artifacts added to third_party

- `Metal_Shader_Converter_4.0_beta_3.pkg` (47 MB): DXIL → Metal IR converter.
  macOS x86_64+arm64 CLI and `libmetalirconverter.dylib`, iOS arm64 dylib,
  headers under `usr/local/include/metal_irconverter*`, manual under
  `opt/metal-shaderconverter/docs`. It does **not** compile MSL; it needs
  DXIL input and targets Metal.
- `Command_Line_Tools_27.dmg` (500 MB): macOS 27.0 SDK. Has full
  `Metal.framework` headers and `Metal.tbd`, 6,839 `.tbd` stubs, Apple clang
  21 and Swift. **No `metal` compiler binary** — only MetalCompiler.xcspec
  build-system specs.
- `apple-ios-27-ui-kit_assets_2026-10-27_v32.zip` (6.5 MB): 151 official UI
  assets — keyboard key glyphs (light/dark, iPhone/iPad/Duo), example
  keyboard/color-picker/edit-menu/lock-widget screenshots. Copyrighted design
  resources; use for measurements, do not redistribute.
- apple GitHub org: `metal-cpp` is the ABI-level C++ Metal interface
  (macOS/iOS 27 headers); `apple-oss-distributions` mirrors xnu, libdispatch,
  libpthread, etc.

## 2026-11-20: Running the Metal Shader Converter natively

- `metal-shaderconverter --version` and `--help` now run under
  `iosim-run`; the full option table appears only after the loader executes
  Mach-O initializers.
- Loader support added: `__TEXT,__init_offsets` (32-bit, image-base-relative
  constructors) and `__DATA,__mod_init_func`; opt-in host-symbol bridge
  (`IOSIM_HOST_SYMBOLS`, `IOSIM_HOST_LIBS`) for libc++/libarchive/libbz2;
  Darwin `stat$INODE64`/`fstat$INODE64`/`open` translation; `___chkstk_darwin`.
- Real conversion (`shader.dxil -o=shader.metallib`) deadlocked inside
  `DXIL2AIR::assemble`: it locks a global mutex whose bytes are Darwin's
  `PTHREAD_MUTEX_INITIALIZER` signature `0x32AAABA7`. glibc treats that
  non-zero word as a locked futex. Manual zeroing let it proceed and then it
  hit `__tlv_bootstrap`.
- Fixes planned/under way:
  1. Darwin pthread shims that translate static-initializer signatures and
     opaque sizes: mutex 64 B, cond 48 B, once 16 B, rwlock 200 B. Signature
     values from the macOS 27 SDK: mutex 0x32AAABA7, recursive 0x32AAABA2,
     errorcheck 0x32AAABA1, firstfit 0x32AAABA3, cond 0x3CB0B1BB, once
     0x30B1BCBA, rwlock 0x2DA8B3B4.
  2. TLV support: the loader must process `__DATA,__thread_vars` thunks
     (24 bytes: func, key/offset, ...), combine `__thread_data` +
     `__thread_bss` initial content per image, allocate lazily per thread,
     and return base+offset. The getter must preserve all registers
     (`no_caller_saved_registers`).
- After that, re-test the real DXIL→metallib conversion and add a test that
  runs it without a KDK.

**Update: conversion succeeds.** With initializers, pthread normalization,
TLV, CommonCrypto, dispatch_data and Darwin signal translation in place,
`metal-shaderconverter shader.dxil -o=shader.metallib` exits 0 and emits a
4512-byte `MTLB` container listing `NAME main`. Recorded in
`docs/METAL-SHADER-CONVERTER.md` and `docs/VERIFICATION.md`. The self-contained
regression fixture is `tests/loader_runtime_test.c` (suite section 21).

## 2026-11-20: Key-value coding and automatic KVO

- The loader runtime now supports runtime class creation
  (`objc_allocateClassPair`, `class_addMethod`, `object_setClass`) and
  selector interning. Selector interning was required: the old
  `sel_registerName` returned the caller's pointer, so KVC's stack-built
  setter names dangled by the next call.
- KVO is implemented with `NSKVONotifying_<Class>` and type-specific setter
  trampolines (object/int/long long/bool/float/double/CGPoint/CGSize/CGRect).
  Wrappers call the public `willChangeValueForKey:`/`didChangeValueForKey:`
  so manual notification and automatic notification share one path.
- Fixture: `tests/kvc_kvo_test.m` (suite section 22); all ten checks pass.

## 2026-11-20: Zig 0.17.1 can build and link simulator guests

Measured with `zig-x86_64-linux-0.17.1` from ziglang.org:

- `zig build-obj` emits x86_64 ELF; a `callconv(.naked)` function with an
  inline-asm body assembles and runs. Clobbers use a struct in 0.17:
  `: .{ .rax = true, .memory = true }` (the old `: "rax", ...` form is
  rejected).
- `zig cc -target x86_64-ios-simulator` produces a Mach-O object with
  `LC_BUILD_VERSION platform iossimulator, minos 18.0` and compiles
  Objective-C through its bundled clang, with no Apple SDK present.
- `zig cc ... tests/fastenum_test.m Foundation.dylib -o app
  -undefined dynamic_lookup -Wl,-e,_main` links a full PIE Mach-O
  executable. It lists `/System/Library/Frameworks/Foundation.framework/Foundation`
  and `/usr/lib/libSystem.B.dylib`, and all eleven `[fe]` lines run under
  `iosim-run`.
- Caveat: passing our extensionless `Foundation` binary to `zig cc` fails
  with "unrecognized file extension"; a `.dylib` symlink works.
- Inline asm is viable for the loader's existing hand-written trampolines
  (`objc_msgSend`, `objc_msgSendSuper2`, `objc_msgSend_stret`, the TLV
  getter) but buys little over the current `.S` files unless we want to
  generate variants at comptime. The bigger win is Zig as an
  SDK-independent guest toolchain; keep it optional so the default build has
  no Zig dependency.
- Adopted as options: `tools/build_app_zig.sh` (guest build) and
  `loader/tlv.zig` with `-DIOSIM_USE_ZIG_ASM=ON` (instruction-identical TLV
  getter). `tests/run_tests.sh` now honors `IOSIM_RUN` so the suite can be
  pointed at a Zig-built loader. The full suite passed against
  `build-zig/iosim-run` (through the KVC/KVO section), and the dispatch-source
  section was added afterward. Defaults unchanged. See `docs/ZIG.md`.

## 2026-11-20: libdispatch sources

- `dispatch_source_create` supports timer, data add/or/replace and read/write
  types. Sources start suspended. A single scheduler thread owns timer
  deadlines on `CLOCK_MONOTONIC`; read/write sources use a poll thread.
- Event delivery is coalesced through a `pending` flag and `dispatch_async_f`,
  which was previously a no-op. `dispatch_after` on non-main queues now
  really delays instead of dispatching immediately.
- `NSRunLoop` drains the main dispatch queue, so plain Foundation processes
  can test main-queue sources (previously only UIKit did).
- Fixture `tests/dispatch_source_test.m` (section 23): six timer fires in
  120 ms, cancel with a once-only cancel handler, and 3+4/5+2 data merges
  both observed as one event with value 7.

## 2026-11-20: UIScrollView insets, paging and delegate

- `contentInset`, `pagingEnabled`, always-bounce flags, dragging/tracking
  state and the six drag delegate callbacks are implemented.
- Paging snaps before `scrollViewWillEndDragging...`, and the delegate can
  adjust the target pointer; the runtime clamps the result to inset bounds.
- `demo/UIKitStub.h` now declares `UIScrollView` and, importantly, gives
  `NSObject` its `isa` ivar. Without that, clang hard-coded custom ivars at
  offset 0, so a delegate's first BOOL/int write corrupted the object's isa.
  Any future stub-only guest class with ivars depends on this.
- Fixture `tests/scroll_view_test.m` (section 24) drives a real UIWindow:
  page 310, delegate counts 1/3/1/1, vertical clamp 820 with top inset 50.

## 2026-11-20: UITextFieldDelegate and UIView geometry

- `UITextField` now calls should-begin/did-begin, should-end/did-end,
  should-change-characters and should-return; software and hardware Return
  share `handleReturnKey`, and `UISearchBarField` overrides it to run search.
- `UIView` has center, setCenter:, setBounds: (size) and point/rect conversion.
  Conversion is translation-only and composes ancestor frames plus scroll
  `contentOffset`; view transforms are still not folded in.
- Fixtures `tests/textfield_delegate_test.m` and
  `tests/uiview_geometry_test.m` (section 25).

## 2026-11-20: CALayer geometry and contents

- `position`, `anchorPoint` and `bounds` are derived from `_frame` so the
  existing renderer needed no layout change; setters preserve position using
  anchorPoint * size.
- `contents` accepts a UIImage and the renderer blits it scaled into the layer
  frame after background and before gradient/shape/sublayers.
- Fixture `tests/calayer_geometry_test.m` (section 26).

## 2026-11-20: KVC collection operators

- `@count`, `@sum`, `@avg`, `@max`, `@min`, `@distinctUnionOfObjects`,
  `@unionOfArrays` and `@distinctUnionOfArrays` run over fast enumeration and
  apply a trailing key path per element.
- `NSDictionary valueForKey:` now maps ordinary keys to `objectForKey:`.
- Fixture `tests/kvc_operators_test.m` (section 27).

## 2026-11-20: NSURLSession and host HTTP

- The loader exports `iosim_http_request`/`iosim_http_free` in the service
  symbol table; it performs DNS, connect, request streaming and response
  splitting in the host process.
- Foundation's `NSURLSessionDataTask` copies the completion block and uses
  `dispatch_async_f` on the global queue; `NSHTTPURLResponse` carries the
  parsed status and headers.
- HTTPS now uses OpenSSL when libssl-dev is present: SNI, TLS handshake and
  SSL_read/write on the connected socket. Certificate and hostname
  verification use the system trust store by default; the self-signed
  loopback fixture sets `IOSIM_TLS_INSECURE=1`. OpenSSL 3's unexpected-EOF
  handling is relaxed so a peer close without close_notify ends the body
  cleanly.
- Fixture `tests/urlsession_test.m` (section 28) uses loopback Python HTTP and
  HTTPS servers; the TLS server is `tests/tls_http_server.py`.

## 2026-11-20: scroll momentum

- Recent-move velocity (70/30 smoothing) feeds `willEndDragging` and
  deceleration; the old whole-gesture average is gone.
- `iosim_scroll_tick` owns momentum and animated content offsets, integrated
  per UI loop with the 0.998/ms decay and a 25 pt/s stop threshold.
- Paging snaps toward the projected offset (`offset + velocity * 0.25`), and
  delegate target offsets act as hard deceleration endpoints.
- Fixture `tests/scroll_deceleration_test.m` (section 29).

## 2026-11-20: sorting

- Stable insertion sort backs `sortedArrayUsingDescriptors:` and in-place
  `sortUsingDescriptors:`; descriptors compare strings, numbers, or a custom
  selector, then apply ascending/descending.
- `NSString` gains `compare:`/`caseInsensitiveCompare:`.
- Fixture `tests/sorting_test.m` (section 30).

## 2026-11-20: NSScanner

- Byte-oriented scanner over NSString UTF8 storage: int/long long/double,
  literal string matching, scan-up-to and clamped scan locations.
- Fixture `tests/scanner_test.m` (section 31).

## 2026-11-20: NSPredicate

- Recursive-descent format parser (NOT > AND > OR) over comparisons,
  CONTAINS/BEGINSWITH/ENDSWITH/LIKE/IN, key paths, SELF, literals and array
  literals; evaluates per object and filters arrays.
- Fixture `tests/predicate_test.m` (section 32).

## 2026-11-20: NSRegularExpression

- Loader exports `iosim_regex_search` over host POSIX `regcomp`/`regexec`,
  translating `\d`, `\w`, `\s`, non-capturing groups and lazy quantifiers
  to ERE.
- Foundation wraps it in NSRegularExpression/NSTextCheckingResult with
  capture ranges, case-insensitive matching and `$n` replacement templates.
- Fixture `tests/regex_test.m` (section 33).

## 2026-11-20: CoreGraphics plan

UIKit apps still cannot draw into their own views: there is no `drawRect:`
bridge, `CGContext` or `UIGraphics*` image context. The next graphics slice is
a real CoreGraphics surface, not more renderer special cases:

- Build `CoreGraphics.framework/CoreGraphics` at the canonical install name,
  exporting `CGContextRef`, `CGPathRef`, `CGColorRef`, affine transforms,
  fill/stroke colors, line width and the common fill/stroke rect/ellipse/path
  entry points. Own an ARGB8888 buffer with a saved graphics-state stack.
- Add a `UIView` display path: when a subclass overrides `drawRect:`, the
  renderer allocates a view-sized surface, makes it the current context, calls
  `drawRect:` with the view bounds, then blits the surface after background
  and before subviews. `setNeedsDisplay` marks the view dirty.
- Add `UIGraphicsBeginImageContextWithOptions`, `UIGraphicsGetCurrentContext`,
  `UIGraphicsGetImageFromCurrentImageContext` and `UIGraphicsEndImageContext`
  as the same surface implementation, so offscreen image drawing works.
- Flatten `UIBezierPath`/`CGPath` elements (move, line, quad/cubic curve,
  close) into the same scan converter used by `CAShapeLayer` where practical.
- Verify with a custom view fixture that fills a rect, strokes a path and
  draws an offscreen image, then sample framebuffer pixels.

CoreGraphics MVP status: `CoreGraphics.framework` now exports a
direct-framebuffer CGContext and UIKit calls `drawRect:` between background
and sublayers. Fixtures cover fills/strokes/ellipses/paths and a full app
frame. UIGraphics image contexts now render into the loader's offscreen
framebuffer and produce RGBA-backed UIImage objects; `UIImage drawInRect:`
draws into the current context. Mutable CGPath objects record elements,
`CGPathApply` walks them, `CGContextAddPath` flattens them, `UIBezierPath
CGPath` returns a real path, and `CAShapeLayer` accepts CGPath or
UIBezierPath. `UIColor CGColor` returns a refcounted color whose component
layout matches UIColor, and UIGraphics push/pop restores nested contexts
(including the context a nested image context had replaced). `CGContextClipToRect`
clips drawing through the framebuffer clip stack and save/restore manages the
clip depth. Refcounted CGImage objects own RGBA pixels, CGContextDrawImage
blits one with scaling, UIImage exposes CGImage and converts back through
imageWithCGImage:, and CALayer contents accepts CGImage or UIImage on both
sublayers and view backing layers. CASpringAnimation evaluates mass/stiffness/
damping/initialVelocity and reports settlingDuration. ObjC categories are
resolved from `__objc_catlist` by category symbol name, and NSString
sizeWithAttributes:/drawAtPoint: renders through the CGContext text bridge,
and drawInRect:/boundingRectWithSize: word-wrap paragraphs. Device RGB/gray
color spaces, CGColorCreate, CGPath bounding boxes, containment and copies
are covered. UITextView maps taps to byte indices, selects words on a second
tap or a half-second press, extends the selection while dragging, clamps
programmatic selectedRange and replaces/removes selected ranges; the renderer
paints the selection highlight and draggable end handles. CGContextClip rasterizes path
masks and intersects active masks; framebuffer fills, strokes, glyphs and
image blits honor them. Quadratic/cubic CGPath, CGContext and UIBezierPath
curves flatten adaptively from the second-derivative bound (1 to 128
segments). CGGradient
stores multiple stops with alpha and CGContextDrawLinearGradient interpolates
them per-pixel through clip and mask; CALayer masks push 8-bit coverage for
whole layer trees; CAGradientLayer interpolates multiple stops with explicit
or even locations, including clear-to-opaque fade masks. Display-P3 colors
are now converted to sRGB for framebuffer rendering (linear P3 -> linear sRGB
matrix plus the sRGB transfer curve), while `getRed:` keeps the original P3
components.

## 2026-11-20: CALayer masks

- The framebuffer clip masks are now 8-bit coverage, not just 0/255:
  `iosim_fb_push_clip_alpha` builds a full-target mask from an alpha buffer
  at an offset and multiplies it into any active mask. Every fill, stroke,
  glyph, gradient and RGBA/affine blit scales its coverage by the mask value,
  so partial alpha and nested masks both accumulate.
- `CALayer.mask` renders the mask layer into a w×h offscreen pass (alpha
  channel only), pushes that coverage at the masked layer's screen origin,
  renders the layer and its sublayers normally, and pops. Mask-layer
  coordinates are relative to the masked layer's top-left. `render_view`
  applies the same pass around the whole view, so `view.layer.mask` covers
  backgrounds, contents, `drawRect:` output and subviews.
- Fixture `tests/calayer_mask_test.m`: rect mask, oval shape mask on a view
  backing layer, and a 50 percent alpha mask that blends red to `0x85070f`.

## 2026-11-20: multi-stop CAGradientLayer

- `CAGradientLayer.locations` is stored; colors accept `CGColorRef` (the
  documented API, and what `.CGColor` produces) or `UIColor` for fixture
  convenience. Up to 32 stops feed `iosim_fb_fill_gradient_stops`; missing or
  mismatched locations fall back to even spacing.
- Rounded gradient layers render into an offscreen, apply
  `iosim_fb_mask_round_rect`, and composite with `blit_affine`, reusing the
  springboard icon path and keeping layer alpha. Non-rounded layers fill
  directly with the absolute gradient axis.
- Fixture `tests/cagradient_test.m` checks the 0.25 explicit stop, even
  spacing, and a 30-point rounded layer's clipped corner.

## 2026-11-20: adaptive curve subdivision

- Curve flattening moved from fixed 24/32 samples to the standard
  second-derivative bound: a curve rendered with n lines deviates by at most
  `max|B''| / (8 n^2)`, with `max|B''| = 6L` for cubics and `2L` for
  quadratics (L is the larger second difference). At 0.25 points that gives
  `n = ceil(sqrt(3L))` and `n = ceil(sqrt(L))` respectively, clamped to
  [1, 128]. Collinear control points collapse to a single segment.
- The shared inline helpers live in `coregraphics_lite.h` and are used by
  `CGPathAddQuadCurveToPoint`/`CGPathAddCurveToPoint`,
  `CGContextAddQuadCurveToPoint`/`CGContextAddCurveToPoint` and
  `UIBezierPath`'s two curve methods, so every consumer flattens alike.
- Fixture numbers: the 80x20-point cubic gives 20 elements, its measured
  deviation stays inside 0.25, the quadratic gives 6, a straight quadratic
  gives 2, and a 300x900 S-curve gives 55.

## 2026-11-20: gradient alpha stops and soft masks

- `iosim_fb_fill_gradient_stops_alpha` interpolates an 8-bit alpha per stop
  alongside the color and blends each pixel with that coverage, multiplying
  into the layer opacity and active clip mask. The old opaque entry point
  forwards with a NULL alpha array.
- `CGContextDrawLinearGradient` now passes the alpha component of each
  `CGGradient` stop through; `CAGradientLayer` reads alpha from `CGColorRef`
  or `UIColor` entries, so a clear-to-opaque gradient works both as a visible
  fade and as a mask (the mask pass copies the offscreen alpha channel).
- Fixtures: `[cg] gradient fade 1 1` (opaque red to white backdrop) and the
  cagradient fade-mask layer (red, half blend `0x840810`, background).

## 2026-11-20: UITextView drag selection and handles

- `touchesBegan:` records the tapped byte index as the drag anchor (the
  word's start after a double tap). `touchesMoved:` maps the moving touch to
  a new index and selects the span between anchor and index; returning to the
  anchor collapses to a caret. `touchesEnded:` clears the dragging flag.
- The renderer computes the pixel position of any byte index on its wrapped
  line and, when the selection is non-empty, paints a 2 px stem plus a
  round knob in `#426bf2` below each end line.
- Fixture `tests/textview_drag_selection_test.m` synthesizes UITouch
  objects (the stub now exposes the touch ivars), drags across the text and
  captures the frame: 25723 highlight pixels and 1404 handle pixels.
- Handle dragging: a touch within 14 points of a drawn knob sets a handle
  mode; touchesMoved samples the index at the knob's line (the knob sits
  below the text, where a raw lookup would clamp to the text end) and moves
  the corresponding endpoint. Fixture `tests/textview_handle_drag_test.m`.
- Long press: touchesBegan arms a pending press with its index and time; the
  UI loop calls `iosim_text_press_tick`, which selects the word once 0.5 s
  have passed. A move past 10 points or a touch end cancels it. The fixture
  runs through a real event FIFO and checks the selection plus captured
  handles.
- Edit menu: UIMenuController stores a target rect and items. The renderer
  lays out a dark panel above the selection; menu taps are consumed before
  the view hit-test and send the item action to the first responder.
  UITextView implements copy:/paste: over the shared pasteboard.
- Standalone bars: UINavigationBar tracks items with push/pop and rebuilds
  its title and left/right controls on layout; UIToolbar centers up to 16
  items as UIControls with 24 pt padding and 16 pt gaps. Both use 17 pt
  labels and draw translucent dark backgrounds with hairlines.
- Modal presentation: non-alert controllers slide up over a dimming layer
  driven by a UI-loop tick (0.35 s), and dismissal slides them back down from
  a dismissing slot after they leave the presentation stack.
- Zoom and two-finger gestures: pinchN/rotateN event records carry two
  points; the window sends pinch/rotation recognizer actions from the
  centroid chain and lets a zooming scroll view follow the distance ratio.
  UIScrollView applies a scale transform to the delegate zoom view and keeps
  the center content point fixed; the renderer now composites any
  non-identity view transform, not only rotations.
- Remaining text-selection gaps: multi-line drag affordances beyond the
  single active touch.

## 2026-11-20: CALayer.transform (2D CATransform3D)

- `objc_lite.h` now defines CATransform3D with identity/make/translate/
  scale/rotate(axis)/concat/is-identity helpers using the row-vector layout,
  so the first two columns match CGAffineTransform's a/b/c/d.
- `CALayer.transform` defaults to identity. A non-identity 2D matrix makes
  the renderer draw the layer into a w×h offscreen pass and composite it with
  `blit_affine`, using m11/m12/m21/m22 and m41/m42 around the layer center.
  A `g_no_transform_layer` guard prevents recursion. Masks keep working
  because the recursive pass applies their coverage inside the offscreen.
- Perspective (m34 etc.), out-of-plane 3D rotation and transform animation
  interpolation are not rendered yet.
- Fixture `tests/calayer_transform_test.m`: 45-degree rotation cuts the old
  corner and extends past the top edge, 2x scale widens both sides, identity
  is unchanged and translation moves the layer without leaving a copy.

## 2026-11-20: CAShapeLayer stroke trimming

- `strokeStart`/`strokeEnd` trim by arc length along the outline, and
  `lineCap == 1` draws round caps at the trimmed ends. A shared
  `stroke_polyline_trimmed` walks segment lengths, draws the covered pieces
  and, for closed outlines, includes the closing segment.
- Rectangles become 5-point loops, rounded rectangles an 8-step-per-corner
  loop, ovals 64 samples and arbitrary paths their stored points. Fill still
  uses the untrimmed shape.
- Trim values are read through `layer_key_value`, so strokeEnd animations
  update the drawn ring. Line joins and dash patterns remain unsupported.
- Fixture `tests/shape_stroke_test.m` covers a trimmed capped line, a
  half-stroked oval and a half-stroked rounded rectangle.

## 2026-11-20: Mach port lifecycle

- `mach_port_s` gained refs and dead flags. `mach_port_allocate` starts at
  one right; `mach_port_insert_right` adds one; `mach_port_mod_refs` applies
  the delta and releases the port at zero; `mach_port_deallocate` and
  `mach_port_destroy` release unconditionally.
- Releasing frees every queued message, closes the listening or peer socket
  and broadcasts the port condition. A timed or blocking `mach_msg` receive
  that wakes with no message returns `MACH_RCV_INVALID_NAME` when the port
  died (otherwise `MACH_RCV_TIMED_OUT`), and later sends return
  `MACH_SEND_INVALID_DEST`.
- Fixture `tests/mach_port_lifecycle_test.c` covers refcounted survival,
  payload delivery and both post-release error codes.

## 2026-11-21: animated UIView transforms

- `UIView` transform changes inside an animation block are captured like
  frame and alpha (`_animatingTransform` plus from/to matrices) and sampled
  by `current_transform`, which the renderer now reads instead of the model
  ivar. Interpolation decomposes each endpoint into rotation (atan2 of the
  first column), x/y scale and translation, takes the shorter arc for the
  angle and rebuilds the matrix. Linear coefficient blending was rejected:
  a 0→180° rotation would collapse through zero scale at the midpoint.
- `setCenter:` now routes through `setFrame:`, so animated center moves
  share the frame path (previously the origin was written directly and
  snapped).
- Touch conversion descends the view chain applying frame origin, inverse
  transform around the box center and scroll offset in render order;
  `hitTest:` inverts its own transform before `pointInside:`, and the alpha
  gate samples the animated value. A scaled/rotated view is now hittable
  over the area it paints.
- Skew cannot be represented by the decomposition and resolves to the
  nearest rotation plus scale; that limitation is documented.
- Fixture `tests/transform_animation_test.m`: a square scaling 1→2 and a bar
  rotating 0→90° under one linear animation; midpoint and end captures check
  interpolated extents (not snap), and `hitTest:` at (110,220) proves the
  final 2x touch extent.

## 2026-11-21: interactive navigation pop

- `UIScreenEdgePanGestureRecognizer` is a `UIPanGestureRecognizer` plus
  `UIRectEdge` bits. The window pre-scans the ancestor chain at touch-down:
  a matching edge pan (start within 20 pt of an enabled screen edge) shadows
  ordinary pans and the scroll view for that touch. It remains possible
  until the finger moves 10 pt; a horizontal-dominant move sends Began then
  Changed with the real translation, while a vertical-dominant move fails it
  and hands the touch back to scrolling.
- `UIPanGestureRecognizer.velocityInView:` now returns smoothed finger
  velocity (the window previously computed only the scroll-signed velocity
  and returned zero from the recognizer). Lift with no move for 100 ms
  zeroes it, so a paused release does not count as a flick.
- Interactive pop keeps both controllers' views in the nav hierarchy during
  the gesture: the previous view is inserted below the bar under a 0.47
  black dim that fades with progress, its left inset follows
  `-0.3 * width * (1 - progress)`; the outgoing view moves to
  `width * progress` and carries a left layer shadow. Release commits above
  0.5 progress or 500 pt/s; the remaining distance of a 0.35 s transition is
  animated ease-out, then the stack pops or the views are removed.
- Test timing note: a 3x software frame takes ~100–150 ms to render, and a
  `dispatch_after` capture runs during the drain before the same iteration's
  render, so captures can reflect a frame from one or two moves earlier.
  Fixtures keep ~300 ms between the last state change and a capture.
- Fixture `tests/nav_edge_pop_test.m` commits one drag and cancels another,
  sampling the revealed boundary, dimmed green, shadow and both end states.
- The bar's title and buttons do not animate during the drag yet; they switch
  when the transition settles.

## 2026-11-21: UIActivityViewController share sheet

- API surface: `initWithActivityItems:applicationActivities:`,
  `activityItems`, `applicationActivities`, `excludedActivityTypes`, the
  modern `completionWithItemsHandler` (activityType, completed,
  returnedItems, error) and the deprecated `completionHandler`. Activity
  type constants are the `com.apple.UIKit.activity.*` strings
  (`CopyToPasteboard`, `Mail`, `Message`, `Print`, `SaveToCameraRoll`, ...).
  `UIActivity` subclasses override type/title/image and
  `canPerformWithActivityItems:`, receive `prepareWithActivityItems:` before
  `performActivity`, and report through `activityDidFinish:`.
  `UIActivityItemSource` supplies a placeholder for the header and a
  per-activity item through `itemForActivityType:`.
- Sheet geometry on the 402x874 screen: floating card inset 8 pt on the
  sides and bottom with 34 pt corners; 240 pt tall for one row, 182 pt with
  no rows, each additional row adding 58 pt. The header block is 30 pt top
  padding plus 64 pt with a 44 pt preview tile, a 17 pt bold title and a
  13 pt type subtitle; rows start at +106 pt with a 32 pt icon; Cancel is a
  50 pt pill inset 16 pt from the card sides.
- The activity list is computed once per configuration: application
  activities that accept the items (and are not excluded) first, then Copy
  unless excluded. Copy asks an item source for the CopyToPasteboard item,
  falls back to the first item, and writes the string, absoluteString or
  description to the general pasteboard.
- Completion semantics reproduced: a completed activity receives its type
  and `completed = YES`; Cancel, the close button and a tap on the dim
  receive nil with `completed = NO`. `UIActivity.activityDidFinish:` reaches
  the controller through a global active-controller pointer, so custom
  asynchronous activities can finish after the tap.
- Layout happens at draw time and its rectangles feed the next tap (same
  model as the edit menu and alerts); the sheet slides on the modal progress
  and the 0.47 dim scales with it.
- Fixture `tests/activity_sheet_test.m`: a Copy row tap checks the
  pasteboard and the reported completion type; a second sheet excludes Copy
  and lays out rowless; a tap on the dim cancels. Captures: mid-slide top
  ~778 pt, settled 626 pt, rowless 684 pt, exact green after both
  dismissals.

## 2026-11-21: context menus

- API surface: `UIContextMenuInteraction` delegates return a
  `UIContextMenuConfiguration`; its previewProvider supplies the lifted view
  controller and actionProvider returns a `UIMenu` of `UIAction`s. Menus can
  nest and mark children inline; action attributes carry Destructive and
  Disabled. The `UITableViewDelegate`/`UICollectionViewDelegate` convenience
  selectors are asked when no view interaction matches.
- Trigger: a stationary touch held for 0.5 s; movement past 10 pt cancels
  the candidate, and a firing `UILongPressGestureRecognizer` takes priority.
  The lift that ends the opening press must not dismiss the menu (the window
  remembers that one up).
- Presentation: snapshot the crisp frame, box-blur (radius 20 pt, two
  passes), dim 22 %, redraw the status bar, then draw the preview and the
  menu card. Re-rendered table/collection cell previews have square
  backgrounds, so the draw pass clears pixels outside a rounded-rect
  distance test back to the saved blurred backdrop.
- Layout: preview width is the source width capped to `W - 24`, menu width is
  `max(250, preview width)`, action rows are 46 pt, headers 28 pt, vertical
  padding 8 pt. The stack is centered on the touch and clamped between 70 pt
  and `H - 48`.
- Fixture `tests/context_menu_test.m` covers a table row (Favorite/Delete,
  outside-tap cancel), a plain view (snapshot + Ping) and a collection item
  (Tag), sampling preview, card and backdrop colors in six captures.
- Known limitation: nested non-inline menus are flattened under their title
  rather than opening a submenu, and menu dismissal is immediate (no return
  animation yet).

## UserNotifications and the system notification UI

- `UserNotifications.framework` is a canonical runtime dylib, like UIKit and
  QuartzCore. The center keeps pending and delivered arrays in the app and
  writes each scheduled request to a shared escaped-text file
  (`bundle, id, fire epoch, repeats, interval, title, subtitle, body, category,
  badge`) under
  `Library/SpringBoard/notifications/` in the shared resources directory. A
  main-queue timer fires due requests; it skips a request whose file has
  disappeared, because SpringBoard removes the file when it takes ownership.
- SpringBoard scans that directory every 200 ms. A due request is added to the
  delivered list and shown as a banner: capture the screen under the banner
  rect, box-blur, tint a `#35353e` card at (8, 58) pt with a 38 pt icon, app
  name, "now", title and body. The banner auto-dismisses at 5 s; a swipe up
  inside it dismisses early.
- The shell draws only in response to events, so the 0.28 s slide-in is driven
  by the notification tick returning "redraw" while the banner is young. A full
  redraw costs tens of milliseconds, which paces the animation at a handful of
  frames; without this the banner froze at whatever fraction it had on the
  first draw.
- A top-edge drag left of the top-right corner opens Notification Center: a
  full-screen blurred capture under a 42 % dim, a 62 pt clock and real date,
  and delivered cards from y = 198 pt. Tapping a banner or card writes
  `Library/SpringBoard/notification-response.txt`, removes that delivered
  entry, and launches or resumes the app. The app polls the response file
  every 250 ms and calls
  `userNotificationCenter:didReceiveNotificationResponse:withCompletionHandler:`
  once its delegate exists, so a tap while the app was stopped still arrives
  after resume.
- Dispatch main-queue bug found by the notification fixture: the ring drain
  broke at the first not-due head, so a block enqueued later but due earlier
  (a 0.25 s response poll behind a longer timer) starved until the head fired.
  The drain now scans the ring for the earliest due entry, removes it by
  shifting the rest, and leaves the others in order.

- Categories and actions are mirrored to
  `Library/SpringBoard/notification-categories.txt` (`category=`, one
  `action=id|title|options` per action, `end`), which SpringBoard reloads with
  each schedule scan. A banner naming a category expands by 44 pt per action
  after a 0.45 s long press without movement; a tap in a row writes that
  action identifier to the response file and launches the app. Notification
  Center cards expand the same way into a dark action sheet below the card,
  with destructive titles in red.
- Badge counts ride in the request file. Delivery rewrites
  `Library/SpringBoard/badges.txt` (`bundle|count`) and updates the home icon's
  red count badge; `applicationIconBadgeNumber` writes the same store, so the
  response delegate can clear it. The badge is drawn inside the icon's
  top-right corner and clears on the next home redraw after the app stops.
- Delivered notifications are also drawn on the lock screen from y = 470 pt,
  above the flashlight and camera controls. Tapping one unlocks and opens the
  app through the same response handoff; launching from a banner or card now
  also clears the Notification Center flag, which otherwise reopened an empty
  center on the next redraw.

## Appearance and dynamic colors

- `UIColor` now carries light and dark components. `ui_components:` resolves
  them through the process-wide `g_ui_style`, and `CGColor`, `text_color_rgb`
  and `color_rgb` all go through it, so view and layer backgrounds and text
  follow the current appearance. The palette covers system backgrounds,
  labels, separators, link and the system hues.
- `UITraitCollection` carries user interface style, display scale and size
  classes. `UIView` and `UIViewController` expose `traitCollection`,
  `overrideUserInterfaceStyle` and `traitCollectionDidChange:`;
  `ui_trait_children` walks the subtree and leaves children with their own
  override alone.
- Appearance is device-wide through
  `Library/SpringBoard/appearance.txt`. SpringBoard handles type-18 events at
  home; the foreground app handles type 18 itself, writes the file, applies
  the style and notifies its window tree, and SpringBoard reloads the file
  when it regains the screen. Apps resolve the file before building views, so
  a cold launch starts in the stored style.
- `iosimctl ui <device> appearance light|dark` sends the event; `events.c`
  parses `appearance N` as type 18. The loader is built by CMake, not by
  `tools/build_runtime.sh`, so loader changes need `cmake --build build`
  before the next boot.
- The status bar is style-aware: `UIApplication setStatusBarStyle:animated:`
  overrides the root controller's `preferredStatusBarStyle`; the default
  style resolves to black or white from the root view's background. The time
  and every status glyph share that color. SpringBoard's dock and search
  glass take a dark translucent overlay in dark appearance. System material
  blur styles (3-7) tint dark in dark appearance and light in light, with
  thickness increasing the tint alpha.
- Status bar hiding and child-controller resolution: `prefersStatusBarHidden`,
  `childForStatusBarStyle/Hidden`, navigation/tab traversal,
  `setStatusBarHidden:animated:`, and Info.plist `UIStatusBarHidden`,
  `UIViewControllerBasedStatusBarAppearance` and `UIStatusBarStyle`. The
  plist is applied before the scene connects so controller/app calls still
  override it. `UIButton initWithFrame:` now creates its title label; before,
  `setTitle:forState:` on a frame-initialized button dereferenced nil.

## Open directions

- `metal-cpp` + macOS SDK Metal headers make it possible to implement a
  Metal.framework surface with ABI-correct selectors; shader execution is
  the hard part (no MSL compiler on Linux).
- UI-kit keyboard glyphs can drive pixel-accurate keyboard rendering; extract
  metrics/colors rather than committing Apple assets.
- Apple `libdispatch`/`libpthread` sources in apple-oss-distributions are the
  reference for deeper dispatch and pthread fidelity; `dispatch_source`
  (timer, data add/or/replace, read/write) is already implemented and
  covered by section 23.
- `CAReplicatorLayer` is implemented by rendering the replicator's sublayers
  once into an offscreen XRGB buffer, then blitting `instanceCount` copies
  with the accumulated `instanceTransform` around the layer's center.
  `instanceColor` tints the copies and per-instance RGB/alpha offsets shift
  each successive copy; `instanceDelay` is accepted but copies render in the
  same animation phase. A ring-of-dots fixture verifies it.
- Offscreen layer passes use the offscreen buffer's local coordinates: child
  layers must be rendered from parent origin (0,0), not the host layer's
  frame origin. Using `-frame.origin` made every replicator child land outside
  the buffer, so the buffer came back with zero alpha.
- `CAAnimation` timing now covers `beginTime` (absolute media time, converted
  to a start delay at add time), `speed`, `timeOffset`, `autoreverses`
  (triangular progress that ends at the start value) and backwards/both
  `fillMode`. `CATransaction` tracks begin/commit nesting and runs a
  completion block on the outermost commit; `performWithoutAnimation:` and
  `setAnimationsEnabled:` execute animation blocks immediately.
- `CAEmitterLayer` uses a repeating lifetime ring per cell instead of
  retained particle state: particle `i` of `n = birthRate * lifetime` sits at
  phase `i / n`, and its age is `(now - epoch + phase * lifetime) mod
  lifetime`. A small LCG derives angle, velocity, scale and RGBA variation
  from the emitter seed and indices, so screenshots are stable.
- UIView keyframe animations are queued by relative start time and applied by
  the run-loop tick as ordinary UIView animation blocks. Sampling the model
  frame during the animation shows the final value immediately; tests must
  read `[[view layer] presentationLayer].frame` instead.
- Tint colors inherit through the superview chain and end at
  `UIColor.tintColor` (system blue). `setTintColor:` and `addSubview:` call
  `tintColorDidChange`; UIButton tracks whether a title color was set
  explicitly and otherwise repaints its title with the inherited tint.
- `+[UIView layerClass]` is consulted once in `initWithFrame:`; a custom
  backing layer still has its frame/owner fields set by UIView. The view
  renderer draws the backing layer's background/contents itself, so custom
  layer types need an explicit branch there — CAGradientLayer shares
  `render_gradient_layer` between the view and sublayer paths.
- `UIView.subviews` was missing even though the renderer walks `_subviews`
  directly; adding it unblocked container code that rebuilds pages.
- `UIViewController` containment is a child array with parent back-links.
  `UIPageViewController` installs its current page as a child when its view
  loads and swaps pages by removing and re-adding subviews.
  `UISplitViewController` keeps primary, optional supplementary and secondary
  controllers, installs them as children, and lays them out side by side when
  the view is at least 700pt wide; narrower widths collapse to the secondary
  controller. The display mode, primary width fraction/min/max,
  supplementary width and delegate will-change callback are modeled.
- `NSAttributedString` stores one attribute dictionary; labels/buttons read
  `NSFontAttributeName` and `NSForegroundColorAttributeName` from it and
  render the plain string. Attribute-name symbols live in UIKit, not as
  macros, because UIKit already defines them as globals.
- Multi-touch needs identity in the event protocol. Today `down`/`move`/`up`
  carry one point and UIWindow keeps a single `_touch`; pinch and rotate
  records only deliver a second point as a derived two-finger gesture. A
  minimal extension is `touch <id> down|move|up <x> <y>` records, a UIWindow
  table of active touches, and a UIEvent carrying the changed set plus all
  active touches. Single-touch consumers can keep reading
  `[touches anyObject]`; controls and recognizers keep tracking their primary
  touch. `iosimctl ui` would grow `touch <id> <action> x y` and a two-finger
  tap convenience.
- Empty Objective-C collection literals do not send a factory message:
  clang emits a load of the `__NSArray0__`/`__NSDictionary0__` globals and
  dereferences the object pointer stored there. Foundation must export those
  globals and initialize them (a constructor works); without them an app
  crashes at the first `@[]` even though non-empty literals use
  `arrayWithObjects:count:` and work.
- `UIButtonConfiguration` is plain data in this runtime. Assigning one applies
  its title, image, foreground/background colors and corner style to the
  button; `contentInsets` insets the title label and a capsule style uses
  half the current height as the corner radius. Button images are real
  `UIImageView` subviews positioned beside the title, so the normal image
  renderer handles them.
- `UITextField.borderStyle` is a renderer branch, not a background view: the
  rounded-rect style paints `0x1c1c1e` behind the field and shifts the text
  origin right by 8pt. The field still has no text-selection or clear-button
  behavior behind the other styles.
- Empty array literals were only one half of the literal surface: Foundation
  also exports `__NSDictionary0__` for `@{}`. Both are ordinary objects, not
  classes, and the compiler dereferences the global before sending `count`.
- `CATextLayer` has no backing view, so its string has to be drawn in
  `render_layer` after the contents blit. Its baseline starts at the layer's
  top edge plus the font ascent; alignment 1 is right and 2 is center.
- `UIView.transitionFromView:toView:` is a structural swap here: it moves the
  destination into the source's superview at the same frame. Cross-dissolve
  compositing is not animated, but the completion runs with `finished:YES`.
- `NSValue` stores bytes and a type string; the factory for a struct must
  count scalar fields in the type encoding to know how many bytes to copy.
  `NSIndexSet` is a sorted dynamic array so `firstIndex`/`lastIndex` are O(1)
  and enumeration is ascending without a sort step.
- `NSURLQueryItem` values are not percent-decoded by `queryItems`; keeping the
  raw substring preserves round-tripping through `setQueryItems:`, which only
  joins names and values with `&` and `=`.
- `NSUUID` bytes need RFC 4122 version/variant bits (`0x40` in byte 6 and
  `0x80` in byte 8) or Foundation's `UUIDString` shape checks reject it even
  when the hyphenation is right.
- `NSProcessInfo.processInfo` is a singleton but not a constant: the
  environment and argument arrays can be empty objects, while
  `globallyUniqueString` still has to look like a UUID string.
- `UIAccessibility*` symbols are C functions, not class methods; apps link
  them by name, so the runtime exports them even though VoiceOver is off.
- Gesture defaults are part of the contract: tap has one tap and one touch,
  pan has minimum one and maximum two touches, swipe has one touch, and all
  recognizers delay touches and cancel touches in view until configured
  otherwise.
- Base64 decoding must drop every non-alphabet character before grouping, or
  newlines in wrapped payloads shift the six-bit window and corrupt the tail.
  The encoder pads a one- or two-byte tail with `=` rather than emitting a
  partial quartet.
- `NSIndexSet.enumerateRangesUsingBlock:` is the only place a run length is
  needed; grouping adjacent indexes on the fly avoids materializing a second
  range array for sets that are already sorted.
- `UIAccessibilityElement` is not a view, so its frame is absolute; a UIView's
  default accessibility frame has to be walked up the superview chain, which
  is why an explicitly assigned frame wins over the computed one.
- `UITableView` and `UICollectionView` configuration properties are stored even
  when the renderer ignores them. Apps set dozens in `viewDidLoad`, and an
  unimplemented setter crashes the app before a single cell is asked for.
- `NSURL` parsing splits scheme at the first colon, authority at `//`, user
  info at `@`, host/port at the last colon in the authority, then path at the
  first `/` and query at `?`. `NSURLComponents` rebuilds its string from the
  parts and only inserts `//` when a host exists.
- CAAnimationDelegate is a queued event, not a per-frame callback: start is
  due at `now + delay`, stop at `now + delay + duration * repeatCount`, and
  removal/replacement of the same key fires `finished:NO` immediately. An
  infinite animation is only stopped by removal. `[UIColor redColor]` and
  the other fixed palette colors are plain constants; only `system*` colors
  carry light/dark variants.
- `UITableView` must not reimplement `refreshControl` storage: the spinner is
  a real subview installed by `UIScrollView.setRefreshControl:`. Overriding the
  setter in the table and assigning the ivar alone leaves the control out of
  the subview tree, so the renderer draws no spinner even though `isRefreshing`
  is true. The table override delegates to super.
- A view's `window` is not stored: walk the superview chain and return the
  first `UIWindow`. A root view only has a window after `setRootViewController:`
  attaches it, so code that reads `view.window` inside `loadView` sees nil.
- `UIAlertController` text fields are ordinary `UITextField` objects created by
  the configuration-handler API; the handler runs before the field is added, so
  a nil handler still appends a default 240x30 field. `preferredAction` is just
  a stored reference, not a replacement for the action list.
- Percent encoding is byte-oriented: encode every byte outside the allowed set
  as `%HH` with uppercase hex, and leave allowed ASCII bytes alone. A UTF-8
  continuation byte is encoded as its own `%HH`, which is what URL consumers
  expect.
- `UIColor.getHue:saturation:brightness:alpha:` is a pure RGB-to-HSV
  conversion; hue is zero for gray, saturation is zero at black, and the
  returned values are normalized to 0..1. The fixed palette colors have no
  separate hue storage.
- `CATransformLayer` and `CATransition` can be API-complete without renderer
  support: the former inherits CALayer drawing, and the latter only stores its
  type/subtype/progress/filter fields for apps that configure and enqueue it.
- `UINavigationController.navigationBar` can return the controller's own bar
  when that bar is allocated as a `UINavigationBar`; the controller still owns
  its separate title label and content view, and the bar's default empty title
  label draws nothing, so appearance APIs work without a second bar.
- `UINavigationController` delegate callbacks are paired around installation:
  `willShowViewController:` runs before the new stack is installed and
  `didShowViewController:` after the appearing controller's appearance
  callbacks. The navigation toolbar is a real `UIToolbar` pinned to the
  bottom; installation copies the top controller's `toolbarItems`, subtracts
  its 49pt height from the content view and keeps it hidden by default.
  `UIRefreshControl.attributedTitle` is stored but the spinner is still drawn
  by the blade renderer, not by a label.
- `UIViewPropertyAnimator` reuses the UIView animation engine: it runs its
  animation blocks through `animateWithDuration:`, reports the end position to
  completion handlers and keeps pause/stop/finish as state transitions over
  that single engine. Async completions exposed a block-runtime gap: the
  loader's `_Block_object_assign` was a no-op, so `__block` storage stayed on
  the creating stack frame. The runtime now promotes byref storage to a
  refcounted heap copy, copies captured blocks, and treats object fields as
  objects; an early attempt crashed because the field-kind test used bitwise
  overlap (`flags & 3` matching 7), so it must compare the exact
  object/block/byref kind.
- Custom view-controller transitions use the same modal presentation path as
  the built-in page sheet, but when the presented controller has a
  `transitioningDelegate` that returns an animator, the runtime builds a
  `UIViewControllerContextTransitioning` context over the presenting view and
  hands it to `animateTransition:`. The animator owns the animation and calls
  `completeTransition:`; the runtime then runs the appearance callbacks and
  user completion. `isBeingPresented`/`isBeingDismissed` are true only for the
  duration of that handoff, including the synchronous case.
- A transitioning delegate can also supply the `UIPresentationController`.
  The runtime installs it with the presenting view as container, lets it
  choose `frameOfPresentedViewInContainerView`, and sends the presentation
  and dismissal will/did callbacks around the animator handoff. Its
  `presentedView` defaults to the presented controller's view; a subclass can
  override it or the frame.
- Presentation and dismissal also ask the transitioning delegate for an
  interactive driver (`interactionControllerForPresentation:` /
  `interactionControllerForDismissal:`). When one is returned the runtime
  calls `startInteractiveTransition:` with the same context instead of
  `animateTransition:`; the driver owns when to complete, so a percent-driven
  driver can settle the context itself.
- `NSOrderedSet`/`NSMutableOrderedSet` keep insertion order with set-style
  uniqueness: a dynamic array plus linear membership checks, with ordered-set
  construction from arrays and sets, index lookup, subscript replacement and
  conversion back to `NSArray`/`NSSet`.
- `UIViewController` conforms to `UIContentContainer`: changing a child's
  `preferredContentSize` forwards `preferredContentSizeDidChangeForChildContentContainer:`
  to its parent, and the default parent callback is a no-op. Container size
  fitting notifications are exposed as no-op hooks for now.
- `UIViewController` tracks its last laid-out size; when `viewWillLayoutSubviews`
  sees a new non-zero size it builds a `UIViewControllerTransitionCoordinator`
  and calls `viewWillTransitionToSize:withTransitionCoordinator:`. The default
  implementation forwards to children, and the coordinator runs
  alongside/completion blocks synchronously with its container view and
  animated/duration state.
- `NSIndexPath` stores up to eight indexes and exposes both row/section and
  item/section constructors, positional access, `indexPathByAddingIndex:`,
  `indexPathByRemovingLastIndex`, `compare:` and `getIndexes:`. Table and
  collection views keep using the same two-index representation.
- `NSCountedSet` subclasses `NSMutableSet` with a parallel count vector:
  adding an existing member increments its count, removing decrements it and
  drops the member at zero, and `countForObject:` returns the multiplicity.
- `NSProgress` tracks total/completed unit counts and derives
  `fractionCompleted`; cancellation and pause/resume flip flags and invoke the
  copied handlers synchronously. Parent/child registration and publish are
  accepted no-ops for now.
- `NSOperation` dependencies are a stored array; `isReady` is true once every
  dependency is finished or cancelled. A queued operation polls `isReady`
  before starting, so adding a dependent before its dependency still runs in
  order. `name` is stored; queue priority and QoS are not modeled yet.
- `CATransform3D` layer rendering now includes the perspective terms. With a
  non-2D matrix, the renderer builds a homography from the row-vector
  transform (`X=m11x+m21y+m41`, `Y=m12x+m22y+m42`,
  `W=(m14+m34*m13)x+(m24+m34*m23)y+...`) and calls a projective blit that
  inverse-maps each destination pixel. Pure 2D matrices keep the affine blit.
- Collection supplementary views use a kind-keyed class registry and a
  per-section data-source callback. The flow layout reserves header and footer
  heights around each section, adds the returned views as subviews, and
  includes those heights in content size and tap cursor math. Reuse is
  allocate-per-reload, like cells.
- A background task is a token plus a copied expiration handler. The first
  task begun while backgrounded opens a five-second deadline; the suspend path
  waits for the task list to empty (or the deadline), calls remaining
  expiration handlers, then stops the process. Active-app tasks get a token but
  no window.
- Binary property lists are parsed from the `bplist00` trailer: offset size,
  object-ref size, object count, top object and offset table. Object markers
  cover null/bool, 1/2/4/8-byte integers, 4/8-byte reals, dates, data, ASCII
  and UTF-16BE strings, UIDs, arrays/sets and dictionaries, with extended
  lengths stored as inline int objects. The writer flattens unique objects,
  emits refs of the minimum width and writes the same trailer.
- Pasteboard items stay one dictionary per item; rich properties are views
  over the same storage: strings use the plain-text key, URLs the public.url
  key, and colors a 32-byte big-endian-agnostic native double array under
  com.apple.uikit.color. Type queries union the item keys in order.
- `UIImage imageWithData:` decodes PNG bytes through libpng's
  `png_image_begin_read_from_memory`, keeping image decoding in the loader.
  Pasteboard images are PNG data under `public.png`, so `setImage:`/`image`
  and `setImages:`/`images` round-trip decoded pixels.
- `NSOperationQueue` workers spin on suspension and on `isReady` before
  claiming a concurrency slot, so a dependency still sitting in the same
  queue can run; the slot claim is an atomic compare-and-swap on `_running`,
  and `operationCount` scans for unfinished, uncancelled operations rather
  than only not-yet-started ones.

## 2026-11-22: Stroke caps, joins and dashes

- `iosim_fb_stroke_polyline` is the shared stroker. It builds one quad per
  segment and fills it through `iosim_fb_fill_polygon` (4x supersampled), then
  fills caps and joins separately: butt/round/square caps, and miter/round/
  bevel joins with a miter-limit fallback to bevel. Round caps and joins are
  polygon discs rather than integer-radius circles.
- Trim is expressed as fractional arc-length endpoints on the polyline, so
  CAShapeLayer's `strokeStart`/`strokeEnd` and CGContext's full-path stroke
  share the same walker. A closed full-length stroke keeps its closing join;
  trimmed pieces are open polylines with caps.
- Dashes walk the on/off pattern from `dashPhase`; odd-length patterns are
  doubled, zero-length on intervals draw a round dot, and each on interval is
  stroked as its own open piece. CAShapeLayer dash lengths and phase are in
  points and are multiplied by the device scale before stroking.
- `CGContext` gained `SetLineCap`/`GetLineCap`, `SetLineJoin`/`GetLineJoin`,
  `SetMiterLimit` and `SetLineDash`; context defaults are butt caps, miter
  joins and a miter limit of 10 to match CoreGraphics. `CGContextStrokeRect`,
  `CGContextStrokeEllipseInRect` and `CGContextStrokePath` now share the
  stroker instead of drawing per-segment round-capped lines, which slightly
  changes the sampled anti-aliased edge in the old `stroke` check (now a
  fully covered `0000ff` pixel).
- `tests/coregraphics_test.m` checks a dash-on and dash-off pixel, square cap
  extension vs a butt cap, and a miter-filled vs bevel-clipped outer corner.
  `tests/shape_stroke_test.m` adds a dashed CAShapeLayer (yellow on, background
  in the gap) and asserts the stored pattern/join properties.

## 2026-11-22: Action sheet layout and stacked alert hit testing

- `alert_compute_layout` builds the card, the title/message heights and one
  row rectangle per action; `draw_alert` and `alert_handle_tap` consume the
  same struct. The old hit test only matched a single row at the bottom, so
  three-plus-action alerts always ran action 0 regardless of the tapped row.
- Action sheets use a width of screen minus 16 pt (capped at 500), a group
  card padded 16/14 around the text block and 8 pt around its rows, and a
  `Cancel` action drawn as its own 47 pt card 8 pt below the group. The sheet
  sits 10 pt above the bottom edge.
- Alert rows keep the measured form: two actions side by side with an 8.3 pt
  gap, otherwise 47 pt rows with 8 pt gaps stacked bottom-up.
- Fixture `tests/alert_sheet_test.m` presents a Share/Delete/Cancel sheet,
  taps Delete, captures the group card, gap and cancel card, then presents a
  three-action alert and taps its third row. Both handlers run and the sheet
  dismissal restores the green background.

## 2026-11-23: Collection scroll asserted by offset

- The collection scroll check sampled (294,262) and expected the blue item
  after a 100 pt drag plus momentum. Depending on the fling distance that
  point can land in the 12 pt gap between rows, so the check failed while
  scrolling had worked (seen locally once and in CI once; reruns passed).
- `demo/CollectionApp.m` now implements `scrollViewDidEndDragging:...` and
  `scrollViewDidEndDecelerating:` and prints `[collection] scrolled <y>`.
  The suite takes the last value and requires y > 10, plus a post-scroll
  capture that differs from the initial frame.

## 2026-11-23: Host pasteboard writes and change notifications

- `iosimctl pbcopy` and `pbpaste` read and write the device pasteboard
  property list from the host side. `pbcopy` replaces the items with a single
  `public.utf8-plain-text` entry and increments `changeCount`; `pbpaste`
  prints the first plain-text item without a trailing newline.
- The general pasteboard primes a change sentinel when it first loads.
  `iosim_pasteboard_tick` compares the reloaded count against that sentinel on
  each main-loop pass and posts `UIPasteboardChangedNotification` with the
  board as the object when it moves. Same-process writes update the sentinel
  directly so the app does not notify itself.
- `UIApplicationMain` only enters its ticking loop when `IOSIM_EVENT_FIFO`
  names an existing FIFO. A test that expects dispatch timers or pasteboard
  notifications from a plain app must create the FIFO and pass the variable,
  even if it never writes an event.

## 2026-11-23: Per-finger touch records

- `touch <id> down|move|up|cancel <x> <y>` event records set types 20-23 and
  store the finger id, exposed through `iosim_event_touch_id`. The existing
  `iosim_event_next` signature is unchanged, so older guests and the
  single-touch path keep working.
- `UIEvent` now owns an array of touches plus a changed set. `allTouches`
  returns the array as a set and `touchesForView:`/`touchesForWindow:` filter
  it. `initWithTouch:` seeds the array with the one touch, so every existing
  single-touch consumer sees the same sets as before.
- `UIWindow` keeps per-finger touches in a dictionary and hit-tests each down
  separately; only the changed touch is passed to `touchesBegan:`/`Moved:`/
  `Ended:`. Fingers landing together arrive as separate records, so they
  produce separate callbacks rather than one batched event. Controls, scroll
  views and gesture recognizers still follow the primary path.
- `iosimctl ui touch` writes the same records to the device FIFO. SpringBoard
  closes its event fd while an app runs, so the foreground app reads them
  directly. When the shell owns the stream the records still create touches
  on its window, but its icon taps are handled in the event loop rather than
  by view touch callbacks, so they have no shell effect.

## 2026-11-23: CoreGraphics arcs

- Arc angles use the view coordinate system: x right, y down, so increasing
  angles turn clockwise on screen. A clockwise arc normalizes its delta into
  (0, 2*pi]; a counterclockwise arc into [-2*pi, 0). Both endpoints are
  included, and the step count grows with the swept arc length
  (`|delta| * radius / 2`, clamped to 4..256) so small radii stay cheap and
  large ones stay smooth.
- `CGContextAddArc`/`CGPathAddArc` connect from the current point with a line
  before laying down the arc. `CGContextAddArcToPoint`/`CGPathAddArcToPoint`
  derive the tangent distance `r / tan(theta/2)` and the center along the
  angle bisector at `r / sin(theta/2)`. A negative cross product of the two
  rays is a screen-clockwise turn, so it maps to increasing angles.
- UIBezierPath's arc method previously ignored `clockwise` and always walked
  the same direction with 64 fixed steps. It now shares the delta
  normalization and adaptive step count, and connects the arc from the
  current point.
- An undeclared class method compiles with C default argument promotions.
  `shape_stroke_test.m` called `bezierPathWithRoundedRect:cornerRadius:24`
  while the stub omitted that factory, so the integer 24 went to the callee
  in an integer register and the double parameter read whatever XMM0 held.
  Adding the declaration to the stub made the call pass 24.0 and exposed the
  fixture's boundary sample on the path's butt cap. Pass double literals for
  floating parameters even when the compiler accepts an implicit method, and
  sample at least one pixel inside a cap.
