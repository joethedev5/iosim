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
tap, clamps programmatic selectedRange and replaces/removes selected ranges;
the renderer paints the selection highlight. CGContextClip rasterizes path
masks and intersects active masks; framebuffer fills, strokes, glyphs and
image blits honor them. Quadratic/cubic CGPath and CGContext curves flatten
into 24/32 line segments; UIBezierPath exposes the same methods. CGGradient
stores multiple stops and CGContextDrawLinearGradient interpolates them
per-pixel through clip and mask. Still missing: color management and adaptive
curve subdivision.

## Open directions

- `metal-cpp` + macOS SDK Metal headers make it possible to implement a
  Metal.framework surface with ABI-correct selectors; shader execution is
  the hard part (no MSL compiler on Linux).
- UI-kit keyboard glyphs can drive pixel-accurate keyboard rendering; extract
  metrics/colors rather than committing Apple assets.
- Apple `libdispatch`/`libpthread` sources in apple-oss-distributions are the
  reference for deeper dispatch and pthread fidelity (dispatch_source is
  still missing in the loader services layer).
