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

## Open directions

- `metal-cpp` + macOS SDK Metal headers make it possible to implement a
  Metal.framework surface with ABI-correct selectors; shader execution is
  the hard part (no MSL compiler on Linux).
- UI-kit keyboard glyphs can drive pixel-accurate keyboard rendering; extract
  metrics/colors rather than committing Apple assets.
- Apple `libdispatch`/`libpthread` sources in apple-oss-distributions are the
  reference for deeper dispatch and pthread fidelity (dispatch_source is
  still missing in the loader services layer).
