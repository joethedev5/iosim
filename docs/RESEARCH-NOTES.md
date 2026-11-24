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

## 2026-11-23: Mutable URL requests and POST

- `NSMutableURLRequest` is an empty subclass of `NSURLRequest`; the base
  class's setters are already public and its `requestWithURL:` uses
  `[[self alloc] init]`, so the subclass factory returns the right type.
  The new `setValue:forHTTPHeaderField:` creates the header dictionary on
  first use, and `addValue:forHTTPHeaderField:` appends `", "` plus the new
  value when the field already exists.
- The loader's HTTP client adds `Content-Length` for the body it streams and
  emits every header from `allHTTPHeaderFields`, so a mutable request's
  method, body and custom fields reach the server without further plumbing.
- The suite's POST echo server is a small `socketserver.TCPServer` bound to
  port 0 that prints its port and replies with
  `"<method> <body> <X-Test header>"`. Header lookup in the runtime is exact
  (case-sensitive), unlike real HTTP, so the fixture uses the same spelling
  on both sides.

## 2026-11-23: Locales and time zones

- `NSLocale` keeps one identifier string. Language and country split at the
  first `_` or `-`, and `objectForKey:` compares against three exported
  string constants (`NSLocaleIdentifier`, `NSLocaleLanguageCode`,
  `NSLocaleCountryCode`), which the Foundation constructor initializes like
  the empty collection literal globals.
- `NSTimeZone` is a name plus a standard offset. The named table covers UTC,
  GMT, Los Angeles, New York, London, Berlin, Tokyo and Sydney with fixed
  offsets; `timeZoneForSecondsFromGMT:` builds a name from the offset in
  hours (`%+ld`), and `systemTimeZone` reads `TZ` (stripping a leading colon)
  before falling back to GMT. Daylight saving is always off.

## 2026-11-23: NSCache

- `NSCache` is a dictionary of objects, a dictionary of per-key costs and an
  array of insertion order. Writing an existing key first removes it, so the
  key moves to the end of the order and its old cost is subtracted.
- Eviction is deterministic FIFO: while the order count exceeds
  `countLimit` or the summed cost exceeds `totalCostLimit`, the first key is
  removed. A zero limit disables that limit. The optional
  `cache:willEvictObject:` delegate fires before each removal, and explicit
  removal does not call it.
- There is no thread synchronization; real NSCache is thread-safe, but every
  current caller uses it from the main thread.

## 2026-11-24: Rounded subtree clipping

- `render_view` wraps a clipping view with a corner radius in an offscreen
  pass: render the subtree at local coordinates, apply
  `iosim_fb_mask_round_rect`, then blit the buffer back at the view's screen
  origin. The wrapper is placed after the transform handling so a
  transformed view is rounded first and transformed afterwards.
- The recursive render passes the original parent alpha and the blit uses
  opacity 1.0, so the subtree's alpha is applied exactly once. A per-view
  guard pointer skips the wrapper on that recursive render, but child views
  with their own clipped corners still take the wrapper.
- `clipsToBounds`, `layer.masksToBounds` and scroll views all trigger the
  clipping path. The loader's `iosim_fb_mask_round_rect_corners` applies the
  signed-distance corner cutoff only in the bits selected by
  `layer.maskedCorners` (1 top-left, 2 top-right, 4 bottom-left, 8
  bottom-right); unselected corners keep square alpha. CALayer defaults
  `maskedCorners` to all four corners, so a plain corner radius still rounds
  every corner.
- The top-only card in the fixture confirms that a selected top-left and
  top-right corner are cut while the bottom corners remain green squares.

## 2026-11-24: CADisplayLink preferred frame rate

- The display-link tick already compared `iosim_now()` against
  `targetTimestamp`; the rate work is only duration bookkeeping.
  `preferredFramesPerSecond` clamps to 0..60 and sets the duration to
  `1 / rate` (0 restores 1/60), while `frameInterval` sets
  `interval / 60`. Each fire advances the target from the current time, so a
  slow machine coalesces rather than bursts.
- The fixture's 800 ms window yields about 8 slow and 46 fast callbacks; the
  assertion requires at least four slow fires and a fast-to-slow ratio above
  three, which tolerates scheduling jitter.

## 2026-11-24: View snapshots

- `snapshotViewAfterScreenUpdates:` uses the normal renderer: begin an
  offscreen of the view's bounds, call `render_view(view, -frame.origin.x,
  -frame.origin.y, scale, 1.0)`, then convert the 0xAARRGGBB buffer into RGBA
  and a CGImage. `UIImage imageWithCGImage:` copies the pixels, so the
  CGImage can be released immediately.
- The returned non-interactive UIImageView has the source's point size and
  a layer contentsScale equal to the screen scale. Rendering the snapshot as
  an image means rounded clipping and subview composition are already baked
  into the pixels; changing the source afterwards does not affect it.
- The `afterScreenUpdates` argument is accepted but ignored: the snapshot is
  taken from the current model state rather than waiting for a commit.

## 2026-11-24: Drawing a hierarchy into an image context

- `drawViewHierarchyInRect:afterScreenUpdates:` reuses the snapshot
  offscreen pass, converts the pixels to a CGImage and calls
  `CGContextDrawImage` on `iosim_cg_current()`. Without a current image or
  view context it returns NO.
- The draw happens while the image context is current; the nested offscreen
  pass saves and restores that context's buffer, clip, opacity and masks, so
  the destination context is intact when the image is drawn into it. The
  destination rectangle can be any size, letting CoreGraphics scale the
  captured hierarchy.

## 2026-11-24: Custom timing functions

- Named `CAMediaTimingFunction` objects now store the two control points
  Apple documents (linear 0/0 and 1/1, ease-in 0.42/0 and 1/1, ease-out 0/0
  and 0.58/1, ease-in-ease-out 0.42/0 and 0.58/1) so
  `getControlPointAtIndex:values:` can return them. Evaluation for named
  functions keeps the existing cheap formulas, so animation output does not
  change.
- `functionWithControlPoints::::` marks the function custom. `evaluate:`
  clamps the control x values into 0..1 and runs 30 bisection steps on the
  cubic x(t) to find the parameter for the requested progress, then evaluates
  y(t). For (0.42,0,0.58,1) this gives 0.13, 0.50 and 0.87 at 0.25, 0.5 and
  0.75.

## 2026-11-24: Single-line label fitting

- Auto-shrink is opt-in. `adjustsFontSizeToFitWidth` defaults to NO, so a
  label that overflows now truncates instead of silently shrinking; the old
  renderer shrank every single-line label down to 8 pt.
- The shrink loop lowers the point size by 0.5 until the measured width fits
  or `minimumScaleFactor * baseSize` is reached. A `minimumScaleFactor` of
  zero means no explicit floor, so the loop stops at 1 pt; values above one
  are clamped to one. The effective size is used for both the metrics and the
  glyph draw, so line height scales with the text.
- Truncation uses the FreeType advances at the effective point size.
  Word/character wrapping on a single line and truncating tail keep a leading
  prefix and append `...`; truncating head prepends `...` and keeps a suffix;
  truncating middle keeps both ends around a middle `...`; clipping emits the
  entire string. UTF-8 continuation bytes are never split.
- `textRectForBounds:limitedToNumberOfLines:` returns the fitted text's
  advance width and line height in points (or the wrapped size for multiple
  lines), so callers see the same shrink/truncate decision as the renderer.
  UILabel now defaults to `NSLineBreakByTruncatingTail` (4), matching UIKit.

## 2026-11-24: Keyframe calculation modes

- `CAKeyframeAnimation.calculationMode` is read at animation time and
  defaults to `linear`. `discrete` returns the segment's starting value and
  advances only when progress reaches the next key time. `paced` ignores
  keyTimes and timing functions, accumulates the absolute distance between
  consecutive values and maps progress into that cumulative length;
  `cubicPaced` currently paces the same chord lengths linearly.
- `cubic` treats the values as a Catmull-Rom spline: interior tangents are
  half the difference of the neighbors and the endpoints use their one-sided
  differences, evaluated with Hermite basis functions on the segment-local
  fraction.
- `timingFunctions` supplies one function per segment (clamped to the last
  entry when short). It applies after the segment fraction is computed in
  linear and cubic modes, and is ignored for paced modes as Apple documents.
- The stored animation entry now keeps the calculation mode and the timing
  function array alongside values and keyTimes, so presentation layers
  evaluate the same policy as the renderer.

## 2026-11-24: Byte and date component formatters

- `NSByteCountFormatter` uses 1000 for the file and decimal styles and 1024
  for memory and binary. The exponent grows while the count reaches the base,
  up to EB. `allowedUnits` is checked with one bit per exponent; when the
  natural unit is excluded the formatter promotes to the next allowed larger
  unit (and falls back to the next smaller one when none is larger).
- Counts above the byte unit print one fraction digit below ten and round to
  integers otherwise. `zeroPadsFractionDigits` keeps the `.0`;
  `includesUnit`/`includesCount` select the parts, and
  `includesActualByteCount` appends `(N bytes)` for scaled units.
- `NSDateComponentsFormatter` first decomposes an interval into clock fields;
  when second, minute or hour units are excluded their values fold into the
  next smaller unit or are dropped, and when day-or-larger units are absent a
  day's worth of hours folds into the hour field. Years use 365 days, months
  30 days and weeks 7 days, with remainders dropped below a disallowed day.
- Unit styles emit positional colons with zero padding down to the smallest
  allowed unit, abbreviated suffixes, short labels, full singular/plural
  words or spelled-out numbers. `maximumUnitCount` keeps the largest nonzero
  fields, and the approximation/time-remaining phrases wrap the result.
  `NSDate timeIntervalSinceDate:` supplies the signed interval for date-pair
  formatting.

## 2026-11-24: Layer position animations

- A layer animation whose key path is `position` can carry CGPoint `NSValue`
  endpoints (`CABasicAnimation`) or a CGPoint `values` array
  (`CAKeyframeAnimation`). The keyframe evaluator reads `CGPointValue` and
  interpolates both components with key times and per-segment timing
  functions; basic animations evaluate the animation's timing function once.
- `layer_progress` reproduces the scalar key path's fill-mode, delay, speed,
  repeat-count and autoreverse rules, so point animations share the same
  clock. Its duration falls back to 0.25 s when unset.
- `current_frame` converts the animated anchor-relative position back into a
  frame origin using the layer's anchor point. Because rendering, hit-testing
  and `presentationLayer` all call `current_frame`, a direct layer position
  animation moves the drawn view and the reported geometry together. A
  standalone layer's `presentationLayer` applies the same conversion without
  an owning view.
- A keyframe position animation can carry a CGPath instead of values.
  `layer_path_point` collects the path through `CGPathApply`; the CGPath
  store flattens quad and cubic curves into line segments at construction
  time, so accumulating segment lengths already measures the drawn geometry.
  The sampler accumulates total length, maps the animation fraction into that
  length and interpolates on the containing segment, which gives constant
  speed along the path. Curves are handled defensively in the applier too.

## 2026-11-24: UIView spring animations

- `animateWithDuration:delay:usingSpringWithDamping:initialSpringVelocity:options:animations:completion:`
  records the damping ratio and initial velocity in the same globals that
  frame/alpha/transform setters snapshot into each view's animation state.
- Animation progress is a damped harmonic around the target: with normalized
  time t, damping zeta and fixed natural frequency 10, the eased fraction is
  `1 - exp(-zeta*10*t) * (cos(wd*t) + ((zeta*10 - v0)/wd)*sin(wd*t))`, with
  the critically damped limit `1 - exp(-10*t)*(1 + (10 - v0)*t)`. The initial
  velocity is scaled by the duration, matching UIKit's fraction-per-second
  meaning. Soft springs overshoot; damping 1 approaches from below.
- Spring and curve animations share the per-view frame, alpha and transform
  interpolation; only the easing function changes, so delays, autoreverse,
  repeat and completion callbacks keep their existing behavior.

## 2026-11-24: UIView cross-dissolve transitions

- `transitionWithView:duration:options:animations:completion:` takes a
  snapshot of the view with `snapshotViewAfterScreenUpdates:NO`, inserts it
  as a non-interactive subview with the same bounds, runs the animations
  block (the model state changes immediately), then fades the snapshot's
  alpha to zero over the duration with the requested curve. Its completion
  removes the overlay before calling the caller's completion.
- `transitionFromView:toView:` snapshots the outgoing view, swaps the model
  hierarchy and fades the snapshot over the parent in the same way.
- Only the cross-dissolve style is modeled. Flip and curl option bits are
  accepted but use the same fade, since the renderer has no 3D transition
  geometry.
- A transition with no transition option, disabled animations, zero duration
  or empty bounds runs the animations block synchronously and completes
  immediately, preserving the previous behavior.

## 2026-11-24: Animation completion and fill modes

- Each layer animation entry now records `removedOnCompletion`. Once the
  active span (`duration * max(repeatCount, 1)`, never for an infinite
  repeat) has elapsed, a default animation clears its slot: `animationForKey:`
  returns nil and presentation values fall back to the layer's model.
- With `removedOnCompletion` disabled, fill modes decide the presentation:
  `forwards` and `both` keep evaluating the animation at its end value, while
  `removed` and `backwards` stop affecting the value outside the active span.
  The same rule covers scalar key paths, layer position/value keyframes and
  CGPath paths.
- The fill mode constants are exported as `forwards`, `backwards`, `both`
  and `removed`; substring checks distinguish backward fill before the start
  from forward fill after the end.

## 2026-11-24: UIViewPropertyAnimator timing parameters

- `UICubicTimingParameters` stores either an animation-curve preset or two
  custom control points; `cubicTimingParameters` returns itself and
  `springTimingParameters` returns nil. The control points feed the same
  bisection cubic-Bezier solver used by `CAMediaTimingFunction`.
- `UISpringTimingParameters` stores mass, stiffness, damping and damping
  ratio. `initWithDampingRatio:` uses the UIKit defaults mass 1 and stiffness
  100 (natural frequency 10), deriving damping `2*zeta*sqrt(k*m)`. Its
  `settlingDuration` is `ln(1000)/(zeta*w0)` for an underdamped spring and
  `7/w0` otherwise.
- `UIViewPropertyAnimator initWithDuration:timingParameters:]` records the
  parameter object. `startAnimation` routes spring parameters through
  `animateWithDuration:...usingSpringWithDamping:initialSpringVelocity:` and
  cubic parameters through the global cubic control-point fields that
  `setFrame:`/`setAlpha:`/`setTransform:` copy into each view's animation
  state. The vector initial velocity prefers dx and falls back to dy because
  the view engine carries one scalar velocity.
- `initWithDuration:dampingRatio:animations:` and
  `initWithDuration:controlPoint1:controlPoint2:animations:` now build the
  corresponding parameter object instead of ignoring their arguments.
  `continueAnimationWithTimingParameters:durationFactor:` swaps the timing
  parameters and scales the animator's duration.

## 2026-11-24: UICollectionView compositional layouts

- The layout object graph mirrors UIKit's: `NSCollectionLayoutDimension`
  (fractional, absolute, estimated), `NSCollectionLayoutSize`,
  `NSCollectionLayoutItem`, `NSCollectionLayoutGroup` and
  `NSCollectionLayoutSection`. Spacing objects (fixed/flexible) and edge
  spacing are stored; edge spacing is accepted but not applied yet.
- Size resolution: fractional dimensions are fractions of the parent slot,
  absolute ones are points. A section group resolves against the section's
  content width and the collection view's height. A repeating group divides
  its main axis into equal slots (minus fixed spacing) before placing copies;
  a plain group places explicitly sized subitems sequentially and centers
  them on the cross axis. Nested groups recurse and leaf items apply their
  content insets.
- `cl_place_section` returns the cursor below a section and fills leaf frames
  in data-source order. `reloadData` and `handleTapAtPoint:` both use it, so
  rendered cells and hit-testing cannot diverge. Section providers are
  invoked with the section index; `initWithSection:` reuses one section
  object for every section.
- Orthogonal scrolling behaviors are recorded but not acted on: groups still
  stack vertically, and the collection view only scrolls vertically. That is
  the main documented gap of this subset.

## 2026-11-24: CGContext blend modes

- `CGContextSetBlendMode` records a `CGBlendMode` in the saved graphics
  state. Every fill and stroke calls `cg_apply_opacity`, which now also
  installs the mode into the loader's framebuffer; gradients do the same
  before their per-pixel loop. Text and image blits reset the mode to
  Normal so a previous fill cannot tint them, and a new context starts in
  Normal.
- The framebuffer keeps `fb_blend_mode` and routes rect fills, polygon and
  ellipse fills, stroked polylines, round/squircle fills and gradients
  through `fb_blend_color`. Normal mode preserves the previous pixel math
  exactly; other modes compute the PDF blend function and lerp it over the
  destination by the effective coverage.
- The separable modes (multiply through exclusion) and the non-separable
  hue/saturation/color/luminosity set use the PDF definitions with
  clip-color, set-luminosity and set-saturation helpers. Clear and SourceOut
  fade the destination, DestinationOver/Atop leave it, DestinationIn/Out and
  XOR scale it, Copy behaves as source-over on the opaque framebuffer, and
  PlusLighter/PlusDarker clamp the sum.
- The test fills a 50% gray field with red under each mode and reads the
  framebuffer PNG: multiply/darken read 128,0,0, screen/lighten/plus-lighter
  read 255,128,128, difference reads 127,128,128, copy reads pure red, clear
  and destination-out read black, and a path-filled multiply box matches the
  rect-filled one.

## 2026-11-24: Horizontal collection flow layouts

- `UICollectionViewFlowLayout` now honors
  `UICollectionViewScrollDirectionHorizontal`. The row count comes from the
  height left after the section's top/bottom insets; each column holds that
  many items, and items wrap into the next column. The main axis advances by
  the item width plus inter-item spacing, sections add their left/right inset
  and one inter-item gap, and the content size becomes the total width by
  the collection view's height. Vertical layouts keep the previous column
  fill and content-height sizing.
- Header and footer reference sizes are ignored in horizontal layouts;
  vertical sections still place them. The shared hit-testing branch mirrors
  the frame loop and uses `collection_select_item`, so selection and delegate
  callbacks behave identically in both directions.
- The fixture uses ten 90x60 items on a 402 pt-wide, 200 pt-tall collection:
  two rows per column give five 90 pt columns plus four 10 pt gaps and 20 pt
  of insets, for a 510 pt content width. A 60 pt horizontal content offset
  shifts the rendered cells, confirmed from the captured framebuffer.

## 2026-11-24: NSMeasurement units and formatting

- `NSUnit` carries a symbol plus singular and plural names; `NSDimension`
  adds a coefficient and offset to its base unit and a family id. Length
  converts through meters, mass through kilograms, temperature through
  kelvin (with an affine offset for Celsius and Fahrenheit), duration through
  seconds, speed through meters per second and volume through liters.
  Accessors return per-class singletons and register them in a per-family
  list used by natural-scale formatting.
- `NSMeasurement` converts by mapping through the base unit, compares two
  compatible measurements after converting to the receiver's unit, and adds
  or subtracts similarly. Incompatible dimensions return nil rather than
  raising, matching the runtime's exception-free foundation subset.
- `NSMeasurementFormatter` defaults to the medium style and natural scale.
  Natural scale keeps an original value already between 1 and 1000,
  otherwise chooses the largest-coefficient family unit landing in that
  range, and falls back to the smallest unit for very small values. Short
  style uses symbols; medium and long use singular for 1 and the plural
  otherwise. Provided-unit skips scaling and the temperature-without-unit
  option omits the unit text.

## 2026-11-24: Blend modes on text and images

- `iosim_cg_draw_text` and `iosim_cg_draw_image` stop forcing Normal: both
  install `context->state.blend_mode` into the framebuffer. The `CGImage`
  path keeps its scaled RGBA sampler; the FreeType glyph path keeps the
  coverage from the rasterized slot.
- The framebuffer's glyph compositor blends the text color against the
  destination with `fb_blend_color` when a mode is installed, using the
  coverage-times-opacity fraction. Scaled RGBA blits do the same with the
  interpolated source color. Normal mode keeps the previous per-channel
  source-over math byte for byte.
- The fixture blends a red image and red bold text over 50% gray. Multiply
  reads (128,0,0); screen reads (255,128,128). Text pixels are scanned
  because glyph antialiasing varies, while the image centers are sampled
  directly.

## 2026-11-24: Diffable data sources

- `NSDiffableDataSourceSnapshot` is a model object: ordered section
  identifiers and a parallel array of item arrays. Appends skip duplicate
  identifiers; inserts before/after locate the target item's section;
  delete, move and reload update the same storage. `reload*` is a no-op
  because the adapters reload the whole view when a snapshot is applied.
- `UITableViewDiffableDataSource` and `UICollectionViewDiffableDataSource`
  conform to their data source protocols, keep the snapshot and a
  `_Block_copy` of the cell provider, map index paths to identifiers and
  back, and reload the view on `applySnapshot:animatingDifferences:`
  (the flag is accepted; the reload is immediate).
- The fixture round-trips a mutated snapshot through a table (one section,
  two rows, cell text `a1`) and a collection (one section, three items,
  0:2 -> `g3`, registered reuse identifier present).

## 2026-11-24: Attributed string attribute runs

- `NSAttributedString` now carries a run list in `_runs`: each run is a
  mutable dictionary with a location, length and attribute dictionary. The
  immutable single-dictionary form stays as the fallback when no runs exist.
- Ranged `addAttribute:value:range:`, `addAttributes:range:` and
  `setAttributes:range:` split partially covered runs into prefix, merged
  (or replaced) overlap and suffix pieces. Additions merge into the existing
  run attributes; set replaces them.
- Character replacement rebuilds the run list over the new length: surviving
  prefixes and suffixes keep their attributes, inserted characters inherit
  the attributes at the replacement start, and later runs shift by the length
  delta. Appending copies the other string's runs with a shifted location, or
  extends a single attribute dictionary across the appended text.
- `UILabel` still renders the plain string with the first run's font and
  color; per-run drawing in the label renderer remains future work.

## 2026-11-24: Attributed label runs

- A single-line `UILabel` with attributed text now draws run by run. Each
  run contributes its own `UIFont` (size and weight), foreground color,
  background color rectangle and `NSUnderlineStyleAttributeName` line;
  widths are summed and aligned by the label's `textAlignment`.
- The path is ASCII-only and requires every run to fit the label width;
  otherwise the renderer falls back to the plain-string fitting code, which
  keeps the first run's font/color and its ellipsis behavior. Wrapping
  labels remain on that plain path.
- The fixture centers red 24 pt, green 32 pt and underlined blue 24 pt runs.
  The PNG reads three colors, green glyphs are 71 px tall against red's
  54 px, the blue underline row spans all 179 px of its run, and the block
  centers at 200.8 pt in the 360 pt label.

## 2026-11-24: Paragraph styles in attributed labels

- `NSParagraphStyle`/`NSMutableParagraphStyle` store alignment, line and
  paragraph spacing, paragraph spacing before, first-line/head/tail indents,
  line-break mode and minimum/maximum line heights. The mutable subclass
  fills setters; the default style is a shared zeroed instance.
- A multiline attributed label reuses `wrap_text_lines` with its base font,
  finds each printed line back in the source string, and draws the matching
  run range segment by segment. The paragraph style at the line start
  supplies alignment and `lineSpacing` (scaled to pixels); run fonts, colors,
  backgrounds and underlines still come from each run.
- The fixture uses `Red\nGreen` with centered paragraph alignment, 10 pt
  line spacing and a left-aligned label. Red and green pixels center at
  600.5 and 599.5 px, and the 57 px gap matches two line heights plus the
  spacing.

## 2026-11-24: Attributed text in UITextView

- The UITextView renderer walks each wrapped line's source byte range and
  calls the shared run compositor with `runFonts` disabled, so runs keep
  their foreground/background colors and underlines but use the text view's
  base font. The plain-text line layout, selection highlight widths and
  caret offsets therefore remain exact.
- Line offsets follow the existing `line_start = line_end + 1` bookkeeping
  used by the selection code; attributed drawing only starts when the
  attributed string is ASCII and its length matches the editor text.
- The fixture shows red, blue and green runs in order; the blue underline
  spans its 128 px run and sits 8 px below the red baseline.

## 2026-11-24: HTTP cookie storage

- `NSHTTPCookie` keeps name/value/domain/path/expiry/secure/HTTP-only from a
  properties dictionary and serializes them back. Class helpers build a
  request `Cookie` header and parse response header fields.
- `NSHTTPCookieStorage` is a shared ordered array: `setCookie:` replaces a
  cookie with the same name, domain and path, and `cookiesForURL:` filters by
  host suffix, path prefix and the secure scheme.
- `NSURLSessionDataTask.resume` appends matching cookies as a `Cookie`
  header before dispatching. The loader response path scans every raw
  `Set-Cookie` line (not the collapsed header dictionary, which keeps only
  the last duplicate) and stores each parsed cookie before the completion
  handler runs.
- The fixture reads back two cookies set by the loopback server, and the next
  request carries both in insertion order.

## 2026-11-24: NSURLCache response caching

- `NSCachedURLResponse` holds a response, data, user info and storage
  policy. `NSURLCache` keeps a shared in-memory dictionary keyed by the
  absolute URL string of GET requests, with methods to look up, store,
  remove one response and clear all of them.
- `NSURLRequest` gained a cache policy; `URLSessionDataTask.resume` consults
  the shared cache unless the policy is
  `NSURLRequestReloadIgnoringLocalCacheData`, and the task context carries
  the cached response into the same completion path. Successful network GET
  responses are stored before the completion handler runs.
- The fixture repeats a GET through the loopback counter server: the second
  response repeats the first body, clearing the cache or asking for a reload
  advances the server counter.

## 2026-11-24: autoreverse spans two durations

- `autoreverses` previously folded the return pass into the same `duration`
  as the forward pass, halving both. Core Animation's `duration` covers the
  forward pass only; with autoreverses the total cycle is twice the
  duration, repeated by `repeatCount`, and the delegate stop fires at the end
  of the reverse pass. `layer_progress`, the scalar `layer_key_value` path,
  the delegate schedule and the active-animation window now all use the
  doubled cycle.
- The timing fixture samples the reverse fade four times and the suite now
  derives the expected opacity from each sample's measured elapsed time
  instead of fixed timer positions, then requires a fourth sample after the
  full two-second cycle at the start value.

## 2026-11-24: context menu submenu pages

- A `UIMenu` without `UIMenuOptionsDisplayInline` no longer flattens into
  the parent card. It draws as one row with its title and a right chevron;
  inline menus still flatten without their title.
- Opening a submenu pushes it on a four-deep stack and rebuilds the entry
  list as a return row (left chevron, the page title) followed by the
  submenu's children, so the card grows and its geometry is recomputed.
  The return row pops the stack and restores the parent rows. Tap routing
  rebuilds row rectangles for submenu and return rows as it does for
  actions.
- The fixture's plain-view menu gained a Share submenu with Copy Link and
  Email. The suite captures the root card, the opened page, the card after
  the return row and the restored view after Email.

## 2026-11-24: context menu action state

- `UIMenuElementStateOff/On/Mixed` now exist. An action in the on state draws
  a trailing checkmark in its row, and the title's ellipsis width reserves
  space for it.
- `UIMenuElementAttributesKeepsMenuPresented` actions run their handler
  without calling `context_menu_dismiss`, so the redraw shows state changes
  such as a toggled checkmark while the page stays presented.
- A page carrying `UIMenuOptionsSingleSelection` clears the state of its
  actions and checks the tapped one before the handler runs; the fixture sets
  keeps-presented on the sort actions so the moved checkmark is visible. The
  fixture also drives every step from framebuffer state, like the submenu
  timeline.

## 2026-11-24: launchd StartInterval jobs

- `parse_job` reads `StartInterval` and initializes the job's `lastStart` at
  load time, so the first launch happens one interval later. `prune_jobs`,
  now called every main-loop iteration, starts an idle job once the interval
  since its previous start has passed, in addition to restarting KeepAlive
  jobs. A running job is not overlapped: the next launch waits for its exit.
- `iosimctl launchd-unload <device> <label>` sends a `job_unload` request and
  removes the installed plist; launchd_sim terminates the job's process
  group, closes its listeners and unlinks its sockets.
- `tests/launchd_job_test.c interval` prints one line and exits; the suite
  loads a plist with `StartInterval = 1` and no RunAtLoad, waits for two log
  lines, unloads the job and verifies the count stops growing.

## 2026-11-24: context menu palettes

- A root menu with `UIMenuOptionsDisplayAsPalette` and only action children
  draws as a 92 pt horizontal card. Its width is 76 pt per action plus 16 pt
  of padding, clamped to the screen; each column centers a 24 pt image above
  a 12 pt title, honors destructive and disabled colors, and registers one
  hit rectangle for the whole column. Menus with headers or submenus fall
  back to the vertical card.
- The fixture builds three solid 24 pt icons through
  `UIGraphicsImageRenderer`; the suite samples the icon centers and taps the
  middle column to run its action.

## 2026-11-24: bitmap contexts and tiled images

- `CGBitmapContextCreate` returns an image context backed by the loader's
  offscreen framebuffer; only 8-bit components are accepted. `CGBitmapContextGetData`
  copies the current pixels into the caller's rows as RGBA on demand, and
  `CGBitmapContextCreateImage` snapshots them through `CGImageCreateWithRGBA`.
  Width and height accessors report the context size.
- `CGContextDrawTiledImage` repeats an image from the rect origin at one image
  pixel per user point, using the context transform for the tile size, and
  clips the loop to the rect and any existing clip. The fixture checks the
  four tile colors, rect edges, an intersecting clip, and a bitmap context's
  data and image round trip.

## 2026-11-24: URLSession upload and download tasks

- `NSURLSessionUploadTask` and `NSURLSessionDownloadTask` subclass the data
  task. An upload task carries its `fromData:` body into the existing request
  path when the request has no body of its own.
- A download task marks its context; after the transfer the body is written
  to `$TMPDIR/iosim-download-<task>` and the completion handler receives the
  `file://` URL rather than the data. Errors keep the location nil.
- The fixture runs both against a loopback server that serves a file and
  echoes a POST body.

## 2026-11-24: input and output streams

- `NSStream` carries a status and a property dictionary. `NSInputStream`
  reads from memory data (a file input stream loads its file at open),
  advancing an offset and reporting `NSStreamStatusAtEnd` when exhausted;
  reads before opening return -1.
- `NSOutputStream` collects memory output and exposes it through
  `NSStreamDataWrittenToMemoryStreamKey`; a file output stream truncates on
  open unless appending, writes on close, and append mode prepends the
  existing file contents.
- The fixture covers chunked reads, status transitions, the memory property,
  file writing and append.

## 2026-11-24: home-screen icon drag across pages

- A held drag lifts the icon into a 108 % ghost that follows the finger and
  leaves its tile out of the grid.
- Holding the ghost inside a 30 pt screen-edge strip turns one page per edge
  entry; dropping on an empty slot moves the icon to that linear grid
  position and shifts the entries between the old and new slots.
- The grid order persists in `Library/SpringBoard/home_order.txt` as one key
  per line (bundle id, `name:<stock>` or `folder:<name>`) and is replayed by
  every grid computation, so the layout survives a boot.
- Folder creation and extension update the saved order by replacing the
  first member's key with the folder key and dropping folded apps.

## 2026-11-24: replicator instance delays

- `CAReplicatorLayer.instanceDelay` staggers the animations of the copies:
  each copy renders in its own offscreen pass with a render-time offset of
  `index * instanceDelay` applied by `layer_progress` and `layer_key_value`.
- Copies without a delay keep the single shared offscreen pass; the tint and
  channel-shift helpers are shared by both paths.
- The replicator fixture gains a three-copy row with a six-second fade and a
  2.5 s delay; a later screenshot reads decreasing brightness across the
  copies.

## 2026-11-24: label and attributed text shadows

- `NSShadow` carries an offset, blur radius and color and can be attached to
  attributed runs with `NSShadowAttributeName`; `UILabel` exposes the plain
  `shadowColor`/`shadowOffset` pair.
- A shadow draws the glyphs a second time at the offset; a blur radius adds
  four ring positions at reduced opacity and relies on coverage accumulation
  in the framebuffer. The shadow color alpha scales the current framebuffer
  opacity through a new `iosim_fb_get_opacity` shim and restores it.
- Attributed label runs, single-line and multiline labels, and attributed
  text views share the pass.

## 2026-11-24: CGContext shadows

- `CGContextSetShadowWithColor` and `CGContextSetShadow` store an offset,
  blur radius and color in the graphics state, so save/restore carries them.
- Fills, ellipse fills, paths and strokes paint the shifted geometry behind
  the shape; a blur radius adds four ring positions at reduced opacity, and
  both the shadow color alpha and the shape alpha scale the framebuffer
  opacity, which is restored afterwards.
- Image blits take the same shadow pass: the image alpha is tinted with the
  shadow color, then blitted at the offset and blur rings. View and text
  shadows are separate passes (`CALayer.shadow*`, `UILabel.shadow*`,
  `NSShadow`).

## 2026-11-24: folder rename

- A long press on the open folder's title opens a rename mode: a UITextField
  takes the keyboard and the title becomes an editable pill with a caret.
- Key events edit the field; Return trims and commits the name, rewrites the
  folder record, rekeys any saved `folder:` order entry, and redraws the
  overlay. Tapping on the software keyboard inserts its characters; tapping
  outside the field commits, and closing the folder clears a stale rename.

## 2026-11-24: URLSession delegate callbacks

- `NSURLSessionConfiguration` carries a request timeout, additional headers
  and `waitsForConnectivity`; delegate sessions keep the configuration,
  delegate and queue, and every task records its session and identifier.
- A task with no completion block hands its body, download progress, finished
  temp file and completion error to the session delegate; optional callbacks
  are probe-checked with `respondsToSelector:`, and the temp download file is
  removed after the delegate callback.

## 2026-11-24: CGContext image shadows

- `CGContextDrawImage` now casts the graphics state's shadow: the image's
  alpha channel is tinted with the shadow color, then blitted at the offset
  and four blur ring positions before the image itself.

## 2026-11-24: home-screen page slide

- A horizontal page swipe no longer swaps the grid instantly: the old page
  moves off by a eased fraction of the screen while the new page enters from
  the other side. The loop tick drives the 0.28 s slide and logs the new page
  only after the final frame, so screenshots after the log show the settled
  page.
- Edge-of-screen page turns during an icon drag stay instantaneous.

## 2026-11-24: locks and conditions

- `NSLock` and `NSRecursiveLock` wrap a normal or recursive host pthread
  mutex; `tryLock` is `pthread_mutex_trylock` and the before-date variants
  poll it until the deadline.
- `NSCondition` pairs a mutex with a condition variable (`waitUntilDate:`
  uses `pthread_cond_timedwait`); `NSConditionLock` layers a condition value
  and waiting locks on top, including timed condition waits.

## 2026-11-24: NSThread start, detach and state

- `initWithTarget:selector:object:` and `detachNewThreadSelector:` start a
  real pthread; the trampoline runs `main` and flips executing to finished.
- `currentThread` is a per-pthread object from a pthread key, `mainThread` is
  the shared first-thread object, and cancel/name/priority are recorded.

## 2026-11-24: operation state, priority and waiting

- An `NSOperation` marks `isExecuting` around `main` and exposes
  `waitUntilFinished`, which polls the finished/cancelled flags.
- `queuePriority` is stored on the operation, and `NSOperationQueue.operations`
  returns only the operations that are still unfinished and uncancelled.

## 2026-11-24: switcher card strip slide

- The app switcher's card strip has a fractional centre: a horizontal swipe
  eases it to the neighbouring card over 0.22 s, driven by the event-loop
  tick, and the `switcher card <name>` log follows the final frame.
- Every card intersecting the viewport is drawn, with the centred card full
  size and neighbours at 92% size and 75% opacity, so the entering card shows
  during the slide.

## 2026-11-24: app launch zoom

- A resumed app zooms its cached last frame from its home-screen icon (or
  switcher card) to the full screen over 0.24 s while the process is still
  stopped, then logs the completed zoom and resumes the process.
- First launches have no cached frame and start without a zoom.

## 2026-11-24: URLSession redirects

- URLSession tasks follow 301, 302, 303, 307 and 308 responses with a
  Location header, resolving absolute, scheme-relative, absolute-path and
  path-relative references against the current URL.
- A 303 (or a 301/302 on a non-GET) rewrites the request to a body-less GET;
  307/308 keep the method and body. More than ten hops fail with
  NSURLErrorHTTPTooManyRedirects (-1007), and the final response carries the
  final URL.

## 2026-11-24: URLSession redirect delegate decisions

- A session delegate implementing
  `URLSession:task:willPerformHTTPRedirection:newRequest:completionHandler:`
  receives the redirect response and the proposed request. Returning that
  request follows the redirect with its URL/method/body/headers; returning
  nil delivers the redirect response itself.
- The callback is expected to call its completion handler synchronously; if
  it has not been called when the delegate method returns, the task follows
  the redirect automatically.

## 2026-11-24: serial dispatch queues

- `dispatch_queue_create` now gives a serial queue a lock-protected FIFO and a
  single worker thread, so its blocks run one at a time in submission order.
  `dispatch_sync` on such a queue enqueues and waits for the earlier blocks
  instead of running immediately, and `dispatch_barrier_async`/`_sync` take
  their FIFO place. The global queue keeps the one-thread-per-block pool.

## 2026-11-24: CATransition fade

- `CATransition` is part of the layer animation slot machinery. A fade
  (type `fade` or unset) is translated into an opacity animation from 0 to 1
  over the transition's duration, so the presentation layer fades in and the
  model value returns afterwards. `moveIn`, `push` and `reveal` are stored
  with their type/subtype/progress/filter but do not stage old content, so
  they do not change the rendered frame.
- The `kCATransition*` type and subtype constants are exported.

## 2026-11-24: UIView flip transitions

- `transitionWithView:` and `transitionFromView:toView:` now stage
  `FlipFromLeft`/`FlipFromRight` as a horizontal squash and
  `FlipFromTop`/`FlipFromBottom` as a vertical one: the old snapshot scales
  along the axis from 1 to 0.01 over the first half of the duration, then the
  new snapshot scales from 0.01 back to 1 over the second half.
- An opaque cover sampled from the first opaque superview background sits
  under the snapshots, so the real content does not leak through while a
  snapshot is edge-on. Cross-dissolve keeps the single fade, and the curl
  styles still fall back to it.

## 2026-11-24: launchd KeepAlive throttling

- `ThrottleInterval` is parsed for LaunchDaemon jobs (ten seconds by
  default, with a one-second floor) and a KeepAlive job is restarted no
  sooner than that interval after its previous start. The fixture starts and
  exits immediately, the suite observes three starts at least 1.6 s apart,
  and unloading the job stops further starts.
- The known-limitations list no longer claims that socket activation, job
  throttling or binary property-list parsing are absent; all three are
  implemented and tested.

## 2026-11-24: Legacy UIView animation blocks

- `beginAnimations:context:`/`commitAnimations` capture the first pre-change
  frame, alpha and transform of every view touched between them and turn
  those captures into the existing per-view animation slots at commit.
  `setAnimationDuration:`, `setAnimationDelay:`, `setAnimationCurve:`,
  `setAnimationRepeatCount:` (with autoreverse) and the will-start/did-stop
  delegate selectors drive the group; a repeat count adds finite cycles to
  `view_animation_progress` through the new `_animRepeatCycles` field.
- `setAnimationTransition:forView:cache:` snapshots the view when called and
  stages a flip at commit for the FlipFromLeft/FlipFromRight types; the curl
  types fade, matching the block-based transition subset.
- Discovered while testing: a view that carries both a non-identity transform
  and alpha below one composites its alpha more than once (the offscreen
  transform pass stores an alpha-attenuated image and the affine blit applies
  the composed alpha again). The fixture therefore fades an untransformed
  view; fixing transformed-alpha compositing is queued as its own batch.

## 2026-11-24: Transformed-view alpha compositing

- The UIView transform path and the CALayer transform path now render their
  offscreen content at full opacity and let the affine (or homography) blit
  apply the composed alpha exactly once. Previously the offscreen pass stored
  alpha-attenuated pixels and the blit applied the composed alpha again, so a
  transformed view or layer with opacity below one rendered at roughly alpha
  cubed: a red view at alpha 0.5 read (42,11,17) instead of (134,7,11).
- `tests/alpha_transform_test.m` compares a plain view, a transformed view, a
  transformed view with layer opacity and a standalone transformed sublayer;
  all four centres now match and the transformed extents remain scaled.

## 2026-11-24: launchd KeepAlive SuccessfulExit dictionaries

- `KeepAlive` accepts the dictionary form; `SuccessfulExit = true` restarts
  the job only when it exited with status zero, `SuccessfulExit = false`
  restarts only on a non-zero status, and a dictionary without that key
  restarts regardless. Restarts still respect `ThrottleInterval`.
- The fixture's `keepalive-exit <code>` mode exits with the given status; the
  suite loads a zero-exit job under each SuccessfulExit value and counts
  starts: the true job restarts, the false job stays stopped.

## 2026-11-24: Associated objects

- The loader now implements `objc_setAssociatedObject`,
  `objc_getAssociatedObject` and `objc_removeAssociatedObjects` over a per
  object association list. Assign/retain policies store the given pointer;
  copy policies send `-copy` through the loader's dispatch and store the
  result; setting nil removes one key and removing all drops the receiver's
  entries only.
- `NSString` copies return the receiver and `NSMutableString` copies
  allocate an immutable snapshot, so COPY associations on strings behave like
  the real ones.
- The fixture exercises key isolation, replacement, nil clearing, retain
  identity under mutation, copy isolation for a custom object and for a
  mutable string.

## 2026-11-24: Masks on transformed content

- A mask on a view or standalone layer that is rendered through the transform
  offscreen path is already applied inside that pass: the recursive render
  pushes the mask before drawing contents and sublayers. The fixture masks a
  red 1.2x view and layer with a left-half mask and samples both sides of the
  transformed centre.
- The architecture note claiming such masks were not folded was stale and has
  been corrected.

## 2026-11-24: Dynamic method resolution and forwarding targets

- Selector lookup now gives `+resolveInstanceMethod:` and
  `+resolveClassMethod:` one chance per class/selector pair (negative results
  are remembered), then the `objc_msgSend` trampoline asks for a receiver
  through the new `objc_msgSend_lookup`. A non-nil, different
  `-forwardingTargetForSelector:` result replaces the receiver and lookup
  continues on the target, following chains up to four hops.
- `class_addMethod` now also accepts loaded classes: `class_addMethod(cls,
  ...)` installs an instance method and `class_addMethod(object_getClass(cls),
  ...)` a class method, both kept in an injection list that lookup checks
  per class before the image method lists.
- `-doesNotRecognizeSelector:` is called for a selector that survives both
  stages. Foundation's NSObject implements it with the real runtime's
  `NSInvalidArgumentException` termination message; NSObject also provides
  the default NO resolvers and a nil forwarding target. A custom override may
  return, in which case the send yields zero.
- `forwardInvocation:`/`NSInvocation` forwarding remains unimplemented and
  is documented as such.

## 2026-11-24: ARC entry points

- The runtime exports the ownership entry points ARC codegen uses:
  `objc_retainAutoreleasedReturnValue`, `objc_autoreleaseReturnValue`,
  `objc_claimAutoreleasedReturnValue`,
  `objc_unsafeClaimAutoreleasedReturnValue`, `objc_retainAutorelease`,
  `objc_retainAutoreleaseReturnValue`, `objc_retainBlock`,
  `objc_storeStrong`, the weak family and `objc_opt_isKindOfClass` /
  `objc_opt_respondsToSelector` / `objc_opt_self`. Retain and release remain
  no-ops, so the weak family stores plain pointers and a slot clears only
  when assigned nil.
- `Foundation-lite` object-pointer ivars and fields carry
  `__unsafe_unretained` so the header compiles under ARC.
- ARC code carries DWARF unwind metadata for `@autoreleasepool` cleanup; the
  loader resolves `__objc_personality_v0` to a personality that returns
  `_URC_CONTINUE_UNWIND` and `__Unwind_Resume` to a reporter that aborts.
  Exceptions themselves remain unsupported.
- `tests/arc_test.m` compiles with `-fobjc-arc` and covers strong and weak
  properties, an autoreleased return, a `__block` capture shared by two
  blocks, and `__bridge` casts.

## 2026-11-24: Runtime swizzling

- clang emits method lists in read-only sections for these binaries, so
  `method_setImplementation`, `method_exchangeImplementations` and
  `class_replaceMethod` cannot write the `method_t` in place. They record an
  override keyed by the method pointer, and lookup resolves the effective
  implementation through the override list. This applies to class methods,
  instance methods, category methods and runtime-injected methods alike.
- `class_getClassMethod` walks the metaclass chain, `class_replaceMethod`
  adds an override when the class does not implement the selector (including
  a subclass that inherits it), `class_respondsToSelector` consults dynamic
  resolution, and `class_copyMethodList` returns the class's own methods plus
  category and injected methods.
- NSObject gains `+instancesRespondToSelector:`.

## 2026-11-24: NSMethodSignature and NSInvocation

- `NSMethodSignature` parses a compiler method type encoding into the return
  type and a list of argument type strings and sizes, skipping frame-offset
  digits and handling object, block, pointer, qualifier, bitfield, array and
  struct tokens.
- `NSInvocation` stores arguments by index (0 target, 1 selector) and the
  return value, with `retainArguments`, `getArgument:atIndex:` and
  `getReturnValue:`/`setReturnValue:`.
- `frameworks/invoke_x86_64.s` provides `iosim_dynamic_invoke`, which loads
  rdx/rcx/r8/r9 and xmm0..7 from the invocation's storage, calls the
  implementation and stores rax plus the 16 bytes of xmm0 for the return.
  Struct/array arguments, more than four integer or eight floating arguments
  (stack arguments) and struct returns are rejected with a diagnostic.
- NSObject answers `-methodSignatureForSelector:` and
  `+instanceMethodSignatureForSelector:` from runtime type encodings and
  implements the default `-forwardInvocation:` by forwarding to
  `doesNotRecognizeSelector:`.
- Delivering `-forwardInvocation:` from the msgSend trampoline is the next
  step; the invocation object itself is complete for direct use.

## 2026-11-24: forwardInvocation delivery

- The objc_msgSend trampoline now passes its saved register frame and a
  result buffer to `objc_msgSend_lookup`. When resolution and a
  `-forwardingTargetForSelector:` target both fail, the runtime asks
  `-methodSignatureForSelector:`; a non-nil signature is turned into an
  NSInvocation with the captured arguments (four GP registers, eight SSE
  registers, then stack slots), and the receiver's `-forwardInvocation:` is
  called. `getReturnValue:` fills the result buffer, which the trampoline
  loads into rax/xmm0 through a sentinel IMP check.
- Struct and array arguments and struct returns are not captured and fall
  back to doesNotRecognizeSelector:. Exceptions remain unsupported.

## 2026-11-24: NSProxy

- Foundation now provides `NSProxy` as a second root class with its own isa
  layout, allocation, class/member checks, `isProxy`, forwarding hooks and a
  proxy-specific `doesNotRecognizeSelector:` message. It is not an NSObject
  subclass, matching real Foundation.
- With `-forwardInvocation:` delivery in place, an NSProxy subclass that
  answers `-methodSignatureForSelector:` receives absent selectors through
  `-forwardInvocation:` and supplies return values via its NSInvocation.

## 2026-11-24: Folder pagination

- An open folder holds up to 24 members and shows twelve slots (four columns
  by three rows) per page. `g_folder_page` limits drawing and hit testing to
  the current page; opening a folder resets to page one.
- With more than one page, pagination dots are drawn near the card's bottom
  edge (selected white, others gray), and a horizontal swipe in the folder
  overlay changes the page and logs `folder page N of M`.
- A folder's grid tile occupies its first member's entry: the Tools folder's
  first member by install order is `com.iosim.fixture`, so the tile is page 1
  row 1 column 3 (339.8333, 222.1667), not the page a previous folder test
  left open. A thirteen-member folder also collapses twelve grid slots, so
  the test saves and restores `folders.txt`, reboots and returns to the third
  home page; later sections tap fixed slots computed from that layout.

## 2026-11-24: Folder page turns live in the folder-open up block

- The SpringBoard up handler has an early `if (g_open_folder >= 0)` block
  that consumes every up event; branches placed after it never run while a
  folder is open. Folder page turning therefore belongs inside that block:
  a horizontal swipe that starts on the card (24..W-24, 120..452) changes
  `g_folder_page`, logs `folder page N of M` and repaints. The first
  placement after the search branch was dead code and the suite caught it
  (suite215: page 1 opened and drew, the swipe did nothing).

## 2026-11-24: Shutdown cleanup

- `iosimctl shutdown` only sent SIGTERM to launchd_sim, and launchd did not
  terminate its children: SpringBoards and apps accumulated across suite
  runs, some eventually zombifying. Shutdown now scans `/proc/*/environ`
  for `SIMULATOR_UDID=<udid>` and SIGKILLs any remaining guest process.
- The environment match identifies a device's processes exactly, so a
  shutdown never touches another device's guests or the host harness.

## 2026-11-24: arm64 image mapping (milestone 0)

- `iosim_image_load` now accepts `CPU_TYPE_ARM64` and records `is_arm64`;
  `--arm64` selects the arm64 slice of a fat main executable while dylibs
  keep the x86_64 slice (the reimplemented frameworks are x86_64).
- arm64 initializers are skipped by `run_initializers`; TLV setup is skipped
  for arm64 images. `--inspect` maps, fixes up and registers ObjC classes,
  then exits without execution. A self-contained arm64 root-class fixture
  (`tests/arm64_probe.m`) verifies the mapping and `objc: class Arm64Probe`.
- Next: the AArch64 interpreter and the `objc_msgSend` bridge.

## 2026-11-24: arm64 interpreter (milestone 1)

- `loader/arm64.c` is a scalar AArch64 interpreter: x0-x30/sp/pc/nzcv,
  movz/movn/movk, add/sub (immediate, shifted, extended), logical ops,
  bitfield moves (LSL/LSR/ASR/UXT/SXT), branches, CSEL/CSINC, MADD/MSUB,
  long multiplies, LDR/STR (unsigned, unscaled, pre/post), LDP/STP,
  ADR/ADRP and LDR literal.
- The loader calls `arm64_run_main` with the Darwin argument registers.
  A branch that leaves every arm64 image is checked against a native gate
  table; `objc_msgSend` reads x0/x1, resolves the IMP with the shared
  runtime and enters an arm64 IMP with the original registers and return
  address. Native IMPs and most C entry points still report unsupported.
- Fixtures: `tests/arm64_exec.c` returns 46 through a loop and call;
  `tests/arm64_msg_send.m` returns 42 from an arm64 class method reached by
  objc_msgSend.

## 2026-11-24: arm64 native method bridge

- `objc_lookup_method_types` exposes the type encoding of the method that
  would answer a selector. The interpreter parses it (return type, self,
  _cmd, argument types with frame offsets) and maps each argument to the
  arm64 GP/SSE registers, then calls `iosim_arm64_native_invoke` in
  `loader/start.S`: a copy of the NSInvocation call gate that invokes a
  native x86_64 IMP with rdi/rsi plus four GP and eight SSE registers.
  rax/xmm0 return into x0/d0.
- C gates now include objc_getClass and sel_registerName, and
  `--load-dylib` preloads an x86 runtime framework for an arm64 main linked
  with dynamic lookup. `tests/arm64_native.m` calls native NSString and
  returns the string's length (5).
- Still pending: stack arguments and aggregate (struct) arguments,
  `objc_msgSendSuper2`, floating-point instruction coverage and the block
  translator.

## 2026-11-24: arm64 interpreter coverage and the callback bridge

- Instruction coverage grew from Foundation stress fixtures. FMOV (immediate)
  (`1e66b000`), the MOVI zero idiom (`0f/2f/4f/6f00e400`), 128-bit Q
  register pairs in LDP/STP, and register-offset LDR/STR (including SXTW
  index scaling) all execute now. LDRSB/LDRSH had their sign-extend
  destination reversed (opc 2 extends to X, opc 3 to W); both the
  unsigned-offset and unscaled forms are corrected, and integer stores use
  XZR for Rt 31.
- CBZ/CBNZ branched on the opposite condition: `(zero != nz)` was used as
  the "don't branch" test, so every CBZ taken path and CBNZ fallthrough
  were swapped. This is why the fast-enumeration loop in the Foundation
  fixture was skipped. Fixed in `loader/arm64.c`.
- `objc_msgSendSuper2` from arm64 enters the base-class IMP through
  `objc_lookup_super_imp` (receiver in x0, original argument registers
  untouched), and native IMPs through the same type-encoding bridge.
- Native calls without a dedicated gate now go through a generic shim call:
  `iosim_shim_lookup_addr` finds the shim for the resolved address and the
  six-GP/eight-SSE `iosim_arm64_native_invoke` gate runs it. This makes the
  ARC entry points, `_Block_copy`, byref helpers, `calloc`, `strtod`
  (double return) and other plain C shims callable from arm64 code.
- The reverse direction got its first bridge: block copy/dispose and
  byref keep/destroy helpers are function pointers into the arm64 image,
  so `_Block_copy`/`_Block_object_assign`/`_Block_object_dispose` now ask
  `iosim_arm64_call_guest` to run them on a nested interpreter context
  (fresh 8 MB stack, x0/x1 from the helper signature, x30 = 0 sentinel).
  The interpreter also ends when any path returns to the sentinel, not
  only when a RET does (a block helper tail-branches to
  `_Block_object_dispose`).
- Verified manually: an arm64 Foundation fixture parsing JSON and doubling
  NSNumber values returns 28; fast enumeration over 4 NSNumbers plus a
  directly invoked block returns 447; a super-call fixture returns 26
  (`9 + 8 + 4 + 0 + 5`); an ARC fixture with `@autoreleasepool`, a copied
  NSString, `__block` capture and a block copy returns 244. These should
  become suite fixtures after the current suite finishes.

## 2026-11-24: arm64 lazy block translator (milestone 2)

- `loader/arm64_jit.c` translates a guest basic block into x86_64 in an
  executable arena and caches it by guest address. The generated function
  takes the shared `struct a64_cpu` in rdi, keeps it in rbx, and edits
  register fields in place. Inline coverage: RET, B/BL, B.cond, CBZ/CBNZ,
  TBZ/TBNZ, BR/BLR, MOVZ/MOVN/MOVK, ADR/ADRP, ADD/SUB immediate and
  shifted/extended (flagless), logical shifted (flagless), UBFM/SBFM,
  LDR/STR unsigned and unscaled/pre/post, LDP/STP, LDR literal, NOP, MOVI
  zero, FMOV immediate/registers, FP LDR/STR unsigned, and FP arithmetic
  (through helpers).
- Flag-setting arithmetic, multiply, divide, CSEL, bitfield moves and FP
  operations call C helpers that reuse the interpreter's decoding, so the
  two paths cannot disagree about an instruction's meaning. Helper calls
  are absolute indirect calls because the arena and the executable can be
  more than 2 GB apart (a rel32 call cannot reach).
- Anything else - NEON, atomics, aggregates - ends the block at that
  instruction; the driver single-steps it with the interpreter and resumes
  translating at the next address. `IOSIM_ARM64_NOJIT=1` forces pure
  interpretation, and `IOSIM_ARM64_JIT_TRACE` prints translated blocks.
- Bugs found and fixed while validating the translator against the
  fixtures: the prologue copied rdi from rbx instead of rbx from rdi, the
  arena was mapped without PROT_EXEC, B.cond passed the condition in edx
  while the helper reads it from esi (so every conditional branch used the
  NZCV word as its condition), and a store helper had been left
  self-recursive by a mechanical edit.
- The suite arm64 fixtures (mapping, message sends, native method bridge,
  printf/FP, super sends, Foundation JSON, fast enumeration/blocks, ARC)
  pass through the translator, and `tests/arm64_super.m` also runs with
  `IOSIM_ARM64_NOJIT=1` so interpreter and translated output are compared.

## 2026-11-24: 128-bit vector registers and a NEON subset

- `struct a64_cpu` gained `dhi[32]`, the high 64 bits of each vector
  register, so Q registers have a real 128-bit model while the scalar code
  keeps using `d[]`. Every scalar FP write (FMOV, FP loads, arithmetic,
  conversions, immediate forms) clears the high half, matching AArch64's
  zeroing of the upper bits on a scalar write.
- The interpreter now implements the AdvSIMD modified-immediate family
  (MOVI with 8/16/32/64-bit lanes and vector FMOV immediates), vector ORR
  (mov.16b / orr.8b), 4S floating-point FMLA/FADD/FSUB/FMUL, element
  extraction (`mov s/d/h/b, v[n]`), and Q forms of LDR/STR and LDP/STP.
- A clang -O2 vectorized float loop (sixteen elements, arrays far enough
  apart to bypass the aliasing check) exercises that path and returns 288;
  the x86_64 build of the same source returns 288 as well, and the arm64
  run agrees with `IOSIM_ARM64_NOJIT=1`. The fixture also covers the
  translator's fallback: NEON instructions end a translated block and are
  single-stepped until vector code gets its own emitters.
- Foundation containers got their own arm64 fixture: building a
  mutable dictionary, enumerating `allKeys` with fast enumeration,
  looking values up by key and appending to a mutable string returns 65
  with `total=6 len=5`.

## 2026-11-24: native-to-guest message bridge

- A native x86_64 message send that resolves to an arm64 IMP cannot jump
  to it. `objc_msgSend_lookup` now calls `iosim_arm64_msg_hook` before
  returning an IMP; the hook checks that the IMP is in the arm64 image,
  parses the method type encoding, and reconstructs the arm64 argument
  registers from the trampoline's saved frame (rdi/rsi/rdx/rcx/r8/r9 at
  frame[5..0], xmm0..7 at frame+0x30), then runs the IMP on a nested
  interpreter context and writes x0/d0 into the trampoline's result
  buffer as the forwarded-result sentinel expects.
- Only scalar arguments and returns are marshalled; aggregate arguments or
  returns fail with an explanatory message instead of jumping into arm64
  code. The x86 frame provides at most four integer argument registers
  beyond self/_cmd, so wider sends are rejected the same way.
- `tests/arm64_reverse.m` (prepared for the suite) has an arm64 object
  inheriting NSObject; native `-performSelector:withObject:` and
  `-[NSMutableArray containsObject:]` send `hit:` and `isEqual:` back into
  it. The fixture prints `c=1 hit=42` and exits 77 with and without the
  block translator.

## 2026-11-24: integer vector operations

- A clang -O2 integer scaling loop vectorizes to `movi.4s`, `mla.4s`,
  `add.4s`, `addv.4s` and horizontal reduce. The interpreter now handles
  4S integer add/sub/mul/mla, ADDV to a scalar, and bitwise
  AND/EOR/BIC/ORN over 16-byte registers (with Q=0 zeroing the upper half).
  The arm64 run, its x86_64 build and `IOSIM_ARM64_NOJIT=1` all return the
  same 424 (status 168).

## 2026-11-24: atomics, SIMD literal loads and native C callbacks

- Clang's default arm64-apple-ios18.0-simulator target emits LSE atomics
  for the `__atomic` builtins: `ldaddal`/`ldclral`/`ldeoral`/`ldsetal`/
  `swpal`/`casal` (with byte and halfword forms), `ldapr` for acquire
  loads, `stlr`/`stlrb` for release stores and `dmb ish` fences.
  `-march=armv8-a` still selects LSE for this triple, so the fixture
  drives `ldxr`/`stxr` and `ldaxr`/`stlxr` through inline asm.
- Interpreter decode: LSE family `0x3f200c00 == 0x38200000` (o3=1, opc=0
  is SWP), CAS `0x3fa07c00 == 0x08a07c00`, LDAPR `0x3ffffc00 ==
  0x38bfc000` (the base has bits 29-27 set, unlike the first guess),
  LDXR/LDAXR `0x085f7c00`/`0x085ffc00`, STXR/STLXR `0x3fe0fc00 ==
  0x08007c00`/`0x0800fc00`, LDAR/STLR `0x08dffc00`/`0x089ffc00`, and
  barriers `0xfffff09f == 0xd503309f`. The guest is single-threaded under
  the interpreter, so the operations are plain read-modify-write;
  LDXR/STXR use a per-cpu monitor.
- Logical immediates were missing entirely. `a64_bitmask_imm` implements
  DecodeBitMasks (N:immr:imms, ROR within the element, replication) for
  the 32- and 64-bit AND/ORR/EOR/ANDS forms; the atomics fixture needed
  `and`/`eor #1` for boolean normalization.
- A 128-bit SIMD literal load (`ldr q0, label`) appeared in a -O1
  fixture initializing an int array; the FP literal handler now fills
  both vector halves.
- The FP unsigned-offset handler used `imm12 << size`, but the Q forms
  encode the immediate scaled by 16 while their size field is 0. `ldr
  q0, [sp, #0x30]` therefore read from `sp+3` and corrupted a printf
  argument area; the scale is now 4 for the Q forms.
- `qsort`/`bsearch` are shim entries backed by `iosim_qsort`/
  `iosim_bsearch`; an arm64 comparator is called through a new
  `iosim_arm64_call_guest_ret` (eight GP and eight FP arguments, x0/d0
  results). The string comparator calls native `strcmp` from inside the
  bridged call.
- The arm64 printf gate now renders floating-point conversions from
  their 8-byte Darwin stack slots, reusing the caller's flags and
  precision.
- Guest-internal struct ABI works without bridge changes: `{int,int}`
  and an HFA `{float,float}` return in registers, and `{long,long,long}`
  returns through the x8 result pointer. Cross-bridge struct returns
  remain unsupported on both sides.

## 2026-11-24: a real arm64 demo app

- `demo/HelloSimApp.m` compiles with the arm64 simulator target and runs
  with `--arm64` plus `--load-dylib` for Foundation, UIKit and QuartzCore.
  It reached `UIApplicationMain`, but framework C exports are not loader
  shims, so the call gate rejected the resolved address. Imports resolved
  from native framework images (and the dlsym fallback) are now recorded in
  an address map; the generic call gate calls them with the
  six-GP/eight-SSE convention. `tests/arm64_framework_calls.c` exercises
  `CACurrentMediaTime` (double return) and the accessibility queries.
- The demo app then crashes when UIKit sends `-scale` to a corrupted
  receiver: `[[UIScreen mainScreen] bounds]` returns a `CGRect`. The
  arm64-to-x86_64 message bridge does not marshal aggregate returns (arm64
  passes the buffer in x8; x86_64 uses a hidden pointer and shifts self/sel
  into the next registers), so the call corrupts state and later sends see
  a bogus isa. Cross-bridge struct returns are the next milestone needed
  for real apps; guest-internal struct ABI already works.

## 2026-11-24: cross-bridge aggregate ABI

- The bridge measures an argument or return type from its encoding with a
  recursive `a64_measure_type` (`{...}`, `(...)`, `[nT]`, `^`, `bN`, `@`,
  quoted types, `c/C/B`, `s/S`, `i/I`, `l/L/q/Q`, `f`, `d`, `v`). A type
  is an HFA when every leaf is the same floating-point type and it has
  one to four fields. On arm64 an HFA returns in d0-d3 regardless of
  size, while x86_64 returns anything over sixteen bytes through a
  hidden pointer.
- Returns: sixteen-byte integer aggregates come back in x0/x1 (rax/rdx);
  HFA returns read d0/d1 for doubles and the two floats packed in each
  of d0/d1 for float HFAs; non-HFA aggregates over sixteen bytes use a
  native `..._stret` gate whose hidden pointer precedes self/selector;
  HFAs over sixteen bytes are copied through a temporary buffer and then
  unpacked into d0-d3.
- Arguments: HFAs fill SSE slots from d registers (two floats per xmm),
  large HFAs are copied to the stack gate as doubles, and non-HFA large
  aggregates are copied from their pointer argument. A new
  `iosim_arm64_native_invoke_stack` gate allocates a rounded stack area,
  `rep movsb`s the blocks into place (the count is rcx, not rdx) and
  calls with self and selector first.
- The SSE gates previously loaded 16 bytes per slot with `movdqu`, which
  packed d0/d1 into xmm0 and left xmm1 zero; CGPoint arguments and
  returns lost their y field. Each slot is now loaded with `movq`.
- The stack gate's args pointer arrives in r9, and the size and retbuf
  words sit at 48/56 after the five pushes; the first version read the
  count from the wrong slot and crashed with rsp near -0xe0.
- `fcmp d8, #0.0` needed a mask without bit 3 (`0xff20fc07`), and
  `ccmp`/`ccmn` gained a handler (`0x3fe00410 == 0x3a400000`) that
  computes the flags or installs the immediate NZCV when the condition
  fails.
- `+[NSValue valueWithCGAffineTransform:]` and
  `-[NSValue CGAffineTransformValue]` round-trip a forty-eight-byte
  non-HFA transform on arm64 and x86_64; `tests/arm64_aggregate.m` also
  covers NSRange, CGPoint and CGRect. The arm64 aggregate fixture exits
  93 under the translator, the interpreter and the x86_64 build.
- With aggregate returns in place, the arm64 `demo/HelloSimApp.m` build
  runs through `UIApplicationMain` until the timeout with no bridge
  errors; bringing up the device and framebuffer path is separate work.

## 2026-11-24: runtime-generated arm64 code pages

- The interpreter and the block driver treated every branch target
  outside the image as a native function, so an app JIT that builds
  arm64 code at runtime would be rejected. A small registry in
  `loader/arm64.c` now records guest executable ranges, and
  `in_any_arm64_image`, `iosim_arm64_pc_in_image`,
  `iosim_arm64_is_guest_code` and the driver's boundary check consult it.
- `mmap` and `mprotect` gained static gates. The mmap gate translates
  Darwin flags (MAP_ANON 0x1000 to Linux MAP_ANONYMOUS 0x20,
  MAP_NORESERVE 0x40 to 0x4000, MAP_JIT dropped) and registers
  PROT_EXEC results. The mprotect gate registers ranges that gain
  PROT_EXEC and calls `a64_jit_invalidate_range`, so a rewritten page is
  translated again; the arena is not reclaimed, which keeps a block that
  is executing the mprotect call valid.
- `tests/arm64_jitpage.c` hand-embeds clang's -O1 code for a mix
  function (`add`, `subs`, `csel`, `add lsl`, `add`, `ret`), maps it RWX
  and calls it. A second page starts read-write, is made executable with
  mprotect and called, and the first page is then rewritten and
  re-protected to prove invalidation. It prints
  `jit=61,127 mprotect=61 reprotect=62` and exits 96;
  `IOSIM_ARM64_JIT_TRACE` shows `jit block 0x<page>..`, which the suite
  greps.

## 2026-11-24: an arm64 UIKit app renders through native frameworks

- A guest that called a loader *service* symbol (`dispatch_time`,
  `dispatch_after`, ...) was rejected: services resolve by name through
  `iosim_lookup_shim`, but the arm64 call gate looked addresses up only
  in the shim table. `iosim_services_lookup_addr` adds the reverse
  lookup and `iosim_shim_lookup_addr` consults it.
- Native code invoking an arm64 block (a `dispatch_after` timer, an XPC
  handler, ...) jumped straight into arm64 code. `call_guest_block` in
  services.c routes such blocks through `iosim_arm64_call_guest_ret`
  with the block in x0 and up to seven further arguments; the x86 path
  is unchanged. This covers dispatch timers, async and global queues,
  `dispatch_apply` and `dispatch_data_apply`. Framework code that invokes
  a block pointer directly (for example a UIKit animation completion)
  would still jump into arm64 code; routing every native block call site
  through the bridge is a separate step.
- `tests/arm64_uikit.m` is a plain UIKit fixture built for both
  architectures. The arm64 scene delegate builds the window, three
  colored views and a label; UIView, UILabel and libdispatch stay
  native; the delayed capture block runs back in the interpreter. The
  arm64 translator, the arm64 interpreter (`IOSIM_ARM64_NOJIT`) and the
  x86_64 build produced byte-identical PNGs (equal md5) in a manual
  comparison; the suite asserts equal sample pixels and a white-pixel
  count for the label.

## 2026-11-24: persistent block cache

- Translated blocks embed absolute immediates for guest addresses (branch
  targets, literal addresses, return pcs) and helper pointers. The
  translator now records every such immediate as a fixup (guest address or
  helper index) while emitting; plain constants (masks, floating-point
  bits) are not recorded. A block with an unknown helper call is marked
  non-cacheable.
- With `IOSIM_ARM64_CACHE_DIR` set, each translated image block is
  appended to `<dir>/<uuid>.blocks`: a record holds the image-relative
  pc, the emitted bytes, the emitting slide and the fixups. Keys are
  relative to the slide so ASLR does not defeat matching. On the next
  launch the file is loaded, guest fixups are rebased from the record's
  slide to the current one, helper fixups are rebound to this process and
  a hit is copied into the arena without decoding arm64. Runtime-
  generated pages are never written.
- The writer stores the fixup array before the code; the first loader
  read them in the other order and silently dropped every record. A
  truncated tail (from a killed process) is dropped on load before
  appending; a record with an out-of-image pc or a bad fixup stops the
  load at that point. The cache version constant covers emitter and
  `a64_cpu` layout changes, and the helper table is append-only.
- `tests/arm64_struct` run twice against one cache directory: the first
  run prints `jit block` traces and writes the file, the second prints
  `jit cached` and no `jit block` lines with the same output and status.

## 2026-11-24: an arm64 app bundle through the device path

- The device manager starts an app with `iosim-run` and only
  `--dylib-path <runtime>/System/Library/Frameworks`; it never passes
  `--load-dylib`. A thin arm64 fixture linked with
  `-undefined dynamic_lookup` carries no `LC_LOAD_DYLIB` entries, so
  nothing loaded UIKit and its `UIApplicationMain`, class and method
  symbols stayed unresolved.
- `iosim_context_preload_frameworks` (context.c) now opens Foundation,
  UIKit, QuartzCore and UserNotifications by appending their canonical
  install names to `DYLD_ROOT_PATH`; missing files are skipped and
  `find_loaded` checks the install name so an image loaded through a
  load command is not duplicated. main.c calls it only for an arm64 main
  with no explicit `--load-dylib` list; an explicit list stays
  authoritative. Every existing arm64 fixture run without `--load-dylib`
  now preloads the frameworks too, with unchanged output.
- `tests/arm64_device_app.m` is a thin arm64 bundle with the dual-
  architecture fixture's scene. It prints `[arm64device] ready` and
  renders through native UIKit. A launch without `IOSIM_EVENT_FIFO`
  renders one frame, presents and returns; a SpringBoard repaint queued
  by the install can then overwrite the device framebuffer before a
  screenshot. The suite waits 0.5 s for that repaint, gives the app its
  own event-stream FIFO via `SIMCTL_CHILD_IOSIM_EVENT_FIFO` so it stays
  foreground, waits for the framebuffer's mtime to pass a marker, then
  copies and samples it: red (100,140), green (100,260), blue (100,380),
  black (350,800) and at least 200 white label pixels.
- The same bundle then launches from its SpringBoard icon (grid slot 7
  on the otherwise empty device at 339.8333,222.1667). SpringBoard spawns
  the loader with no `--dylib-path` at all, so this path depends on the
  preload as well; the app's stdout goes to `springboard.log`, the
  capture shows the same scene, and a `home` event suspends it. A manual
  run of the same binary directly under `build/iosim-run` with only
  `DYLD_ROOT_PATH` (no `--load-dylib`) produced a byte-identical PNG.

## 2026-11-24: variadic gates and broader AdvSIMD

- A variadic native call cannot go through the ordinary call gate:
  arm64 passes anonymous arguments on the stack, one eight-byte slot
  each. The printf formatter became `a64_render_format`, and gates for
  `fprintf` (stream, format), `sprintf` (dest, format), `snprintf` (dest,
  size, format) and `NSLog` run it with the right fixed arguments and
  return each function's own result. NSLog's format is an NSString; its
  `%@` arguments use the constant-string layout when present and
  `-description`/`-UTF8String` otherwise. Messaging a constant string's
  shim isa crashes (its method list is a placeholder), so constants must
  bypass the object path.
- NSLog resolved to Foundation's exported NSLog when the framework image
  was preloaded instead of to the loader shim, so the address-keyed gate
  missed it. The native dispatcher now routes the five printf-family
  names by symbol name as well, covering shim and image addresses.
- AdvSIMD: the shift-by-immediate encodings share the modified-immediate
  group's mask, so they are decoded before MOVI. Masks were derived from
  llvm-mc encodings rather than guessed. Added shl/ushr/sshr, integer
  add/sub/mul/mla in 8/16/32/64-bit lanes, signed and unsigned min/max,
  4S float max/min/div/sqrt/abs/neg, cmeq/cmgt/cmge/cmhi/cmhs and
  cmeq #0, addp, horizontal reductions
  (smaxv/sminv/umaxv/uminv/fmaxv/fminv), dup/ins element moves,
  zip/uzp/trn permutations, scvtf/fcvtzs and LD1R. Scalar FCVT between
  single and double precision was missing and broke float printf
  arguments compiled at -O0. `tests/arm64_neon.c` is the coverage
  fixture; the translator and the interpreter produce identical output.

## 2026-11-24: framework code invoking app blocks

- Native framework code that stores an app block cannot jump to an
  arm64 block's invoke pointer: it is guest code. UIView animations and
  completions, NSIndexSet enumeration, NSOperation, URLSession handlers
  and UserNotifications completions now call the block through
  `iosim_block_call` / `iosim_block_call1/2/3`, which read the block
  layout and route an arm64 invoke pointer through
  `iosim_arm64_call_guest_ret` with the block itself in x0 and up to
  three arguments in x1-x3; an x86 block keeps the direct call path.
- The call sites had called the invoke pointer directly before, which
  crashed under arm64 but was correct for x86. Blocks that return a
  value (view-controller completions with items, collection view data
  source providers) are not bridged yet and still call the pointer
  directly.
- A fixture with all three frameworks running arm64 blocks produces the
  same four lines with `IOSIM_ARM64_NOJIT=1`, and `exit(0)` from the
  animation completion terminates the loader with status zero.

## 2026-11-24: widening, rounding and interleaved structures

- clang lowers `vaddl` to SSHLL plus ADD rather than SADDL, so the
  long-shift family is required for generated code. Its shift amount is
  immh:immb minus the source element width (8, 16 or 32 bits), and the
  destination width comes from the highest set bit of immh.
- Base constants for mask-based decoders must be written with the Rm
  field cleared. Encodings sampled with `v2` left bit 17 set in several
  bases for SQADD, the FP compares and the pairwise FP operations, so
  every instruction with a different Rm missed. The masks clear bits
  20-16, so bases belong at `...0...` there.
- The greater-than families (FCMGT, FACGT, FMINP, FRINTP/FRINTZ) encode
  4S and 2D in size fields 2 and 3, while the equality and
  greater-or-equal forms plus FADDP/FMAXP and FRINTA/N/X use 0 and 1.
  Lane selection has to come from the matched opcode, not one size rule.
- At -O0 the compiler materializes constants element by element
  (MOV element, i.e. INS with a vector source) and loads them one lane
  at a time with LD1 single-lane. Both are decoded now. Single-lane
  size and index share bits 15-10, with Q as the top index bit:
  8-bit lanes use bits 12-10, 16-bit use bit 14 and bits 12-11, 32-bit
  bit 15 and bit 12, 64-bit bit 15 with Q as the index.
- TBL's length sits in bits 14-13 and EXT's immediate in bits 14-11,
  so a mask that keeps them rejects encodings whose register numbers set
  the overlapping bit. TBL with Q=0 uses its own base and zeroes the
  upper half; TBX keeps the destination element.
- LD2/LD3/LD4 de-interleave with `Vr[i] = mem[nregs*i + r]`; stores
  interleave with the inverse. The list mask must exclude the length
  bits 15-14.
