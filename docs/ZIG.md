# Zig as a guest toolchain and inline-assembly source

The default build uses the system C compiler, clang for guests and
`ld64.lld` for Mach-O. Zig is an optional addition, measured here with
**Zig 0.17.1**. Nothing in the default build requires it.

## SDK-independent guest builds

Zig ships Darwin target definitions plus a Mach-O linker and can drive its
bundled clang front end. A simulator-target object carries the right load
command:

```sh
zig cc -target x86_64-ios-simulator -c app.m -o app.o
# LC_BUILD_VERSION platform iossimulator, minos 18.0
```

A full link against the runtime's Foundation works too. Zig infers the input
format from the file extension, so the extensionless canonical simulator path
needs a `.dylib` symlink:

```sh
ZIG=/path/to/zig ./tools/build_app_zig.sh tests/fastenum_test.m build/fastenum-zig
DYLD_ROOT_PATH=$PWD/runtime ./build/iosim-run build/fastenum-zig
```

Verified results:

- `tests/fastenum_test.m` builds and runs all eleven `[fe]` lines.
- `tests/kvc_kvo_test.m` builds and runs the full KVC/KVO output, including
  automatic `NSKVONotifying_` setters.
- The linked executable depends on
  `/System/Library/Frameworks/Foundation.framework/Foundation` and
  `/usr/lib/libSystem.B.dylib`; the runtime provides both.
- Objective-C is still compiled by clang's front end inside `zig cc`. Zig
  does not add an Objective-C compiler of its own.

The wrapper always links Foundation. UIKit guests also need UIKit passed as
an input (with a `.dylib` symlink); the default `tools/build_app.sh` remains
the simpler path for app fixtures.

## Inline assembly

Zig's `callconv(.naked)` plus `asm volatile` can express the loader's
register-preserving trampolines. The TLV getter is available as an alternate
source:

```sh
cmake -S . -B build-zig -G Ninja \
  -DIOSIM_USE_ZIG_ASM=ON -DZIG_EXECUTABLE=/path/to/zig
cmake --build build-zig
IOSIM_RUN=$PWD/build-zig/iosim-run ./tests/run_tests.sh
```

`loader/tlv.zig` mirrors `loader/tlv.S` instruction for instruction: it saves
`rax` as padding, the caller-saved GPRs and all sixteen XMM registers, calls
`iosim_tlv_get_addr_slow`, restores everything except `rax`, and returns the
address. The fixture's `[lrt] ctor 1 tls 42` line is the behavioral check.

Zig 0.17 uses structured clobbers:

```zig
asm volatile ("..." : : : .{ .rax = true, .memory = true });
```

The older `: "rax", ...` string form is rejected by 0.17. Naked-function ABI
support and assembly syntax have changed across Zig releases, so pin the
compiler version when enabling this option.

## Where Zig helps and where it does not

- **Useful:** SDK-free guest object/executable builds; an alternate checked
  spelling of the naked trampolines; compile-time generation of typed stubs
  if the set grows.
- **Not worthwhile:** rewriting the C loader in Zig, or replacing the stable
  `start.S`/`tlv.S` sources by default. The trampoline set is small and
  already covered by the loader-runtime fixture.
- Runtime code generation (JIT trampolines) is outside what Zig inline asm
  offers; that still requires emitting machine code at run time in C.
