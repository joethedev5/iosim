# Running arm64 app binaries

Status: **milestones 0-2 implemented in a first form.** The loader accepts
arm64 images (`--arm64`), registers their Objective-C metadata, and runs
them on the scalar interpreter with native framework calls (the
type-encoding message bridge, `objc_msgSendSuper2`, a generic C shim gate,
native-to-guest calls for block copy/byref helpers, a callback bridge
used by `qsort`/`bsearch` comparators, and an address map for C functions
exported by the preloaded native framework dylibs). A lazy block translator compiles
basic blocks of the scalar subset to x86_64, caches them by guest address,
and falls back to single-step interpretation for instructions without an
inline form; `IOSIM_ARM64_NOJIT=1` selects the interpreter, and scalar
native-to-guest ObjC message dispatches re-enter it through the reverse
bridge. Atomics (LSE read-modify-write/CAS, LDAPR/LDAR/STLR, barriers and
LDXR/STXR exclusives) and 128-bit SIMD literal loads are implemented.
Aggregates cross the bridge in both directions: type encodings are
measured recursively, sixteen-byte integer structs use GP registers,
HFAs (up to four same-type fields) use d0-d3 even when larger than
sixteen bytes, and other large structs pass by pointer and return
through x8/hidden buffers, with stack arguments on a dedicated call
gate. Runtime-generated code pages are translated as well: a guest mmap
or mprotect that grants PROT_EXEC registers the range, so branches into
it run through the interpreter and block translator, and re-protecting
a page drops the translations that started in it. Native code can call
arm64 blocks back through the callback bridge, so libdispatch timers
and queues run app blocks, and the call gate recognizes the loader's
service symbols by address. A UIKit app compiled once for each
architecture renders the same pixels. An app bundle whose executable is
thin arm64 starts through the normal device-manager path too: a launch
that names no frameworks gets Foundation, UIKit, QuartzCore and
UserNotifications preloaded from the runtime root, and the scene renders
into the device framebuffer. Translated image blocks can be
persisted in a directory named by `IOSIM_ARM64_CACHE_DIR`, keyed by
image UUID and image-relative pc, with guest addresses and helper calls
recorded as fixups and rebound by slide when the file is loaded, so a
second launch skips translation. Framework code that invokes an app
block — UIView animations and completions, Foundation index-set
enumeration, NSOperation and URLSession handlers, UserNotifications
completions — calls it through the block-call bridge, which runs an
arm64 invoke pointer on the interpreter. Blocks with four arguments and
blocks that return objects are bridged as well (activity completions,
cell and menu providers, preview providers). The printf-family gates now cover
fprintf, sprintf, snprintf and NSLog, including %@ through the object's
description, and AdvSIMD coverage includes shifts by immediate, integer
add/sub/mul/mla in every lane size, signed and unsigned min/max,
compares, float max/min/div/sqrt/abs/neg, integer/float conversions,
pairwise adds, horizontal reductions, element moves and zip/uzp/trn
permutations; LD1/ST1 single-structure loads and stores cover one to
four consecutive registers with no offset or a post-index. Interleaved
LD2/LD3/LD4 structures, widening and narrowing arithmetic, saturating
add/sub, TBL/TBX and EXT, floating-point rounding and compares, and
pairwise floating-point operations are covered too. This document records the method and
the milestones that prove it.

## The constraint and the reframing

An x86_64 CPU cannot execute AArch64 instructions. If "no CPU emulation"
means "no instruction translation anywhere", the only remaining option is
ARM64 hardware, and the rest of this note does not apply. If it means "do
not emulate the system", there is a much smaller problem to solve.

At runtime an app spends most of its time in UIKit, Foundation,
CoreAnimation, CoreGraphics, libdispatch, XPC and libSystem. In iosim every
one of those is already native x86_64 code implemented in this repository.
The only artifact that is still arm64 is the app's own image — typically a
few hundred methods and a few megabytes of `__TEXT`. So the execution can be
partitioned:

- **native x86_64**: our frameworks, loader, ObjC runtime, launchd,
  SpringBoard;
- **translated**: the app image's own functions and methods;
- **boundary**: Objective-C message sends and imported C symbols.

We never translate Apple's arm64 system libraries, because we do not run
them. That is the central difference from Rosetta- or qemu-user-style
systems, which translate whole processes including their frameworks.

## Translation trigger: lazy per-IMP recompilation

Objective-C dispatch is a natural translation boundary and cache key. The
loader parses class and method metadata normally; those structures are
architecture-independent 64-bit data, and only the IMP addresses inside
`__TEXT` are arm64 code. The plan:

1. Map the arm64 image and build the usual class list. Method lists are
   recorded as arm64 code addresses, not executed.
2. The first time a selector resolves to an arm64 IMP, translate **that
   function only** to x86_64 and install the translated address in the
   existing method-override/injection table (the same pointer-keyed table
   used for swizzling in `loader/objc_runtime.c`). Untaken methods are never
   translated.
3. Calls between app functions are resolved to translated addresses as they
   are first needed; calls to framework symbols go through thunks to our
   native x86_64 implementations.
4. Translations are cached by image UUID and original offset, so a second
   launch skips translation entirely. The cache can be written at install
   time (`iosimctl install`) or filled lazily on first run; either way the
   steady state is native x86_64 code.
5. Runtime-generated code (JavaScriptCore and other JITs) is the exception:
   executable pages written at runtime are translated on demand and added to
   the same cache.

This "translate on dispatch" design also keeps startup honest: methods that
are never called cost nothing, and translation can be profiled and grown
from real fixtures rather than from an instruction-set checklist.

## The ABI bridge

The x86_64 `objc_msgSend` trampoline in `loader/start.S` saves its argument
registers and calls the architecture-neutral dispatcher. An arm64 app needs
the analogous entry: a thunk that receives `x0` = receiver and `x1` =
selector, saves the arm64 argument registers and stack, and calls the same
dispatcher. The dispatcher then has two ways to run a resolved method:

- a **native** method: marshal arguments into the x86_64 SysV convention
  and call the existing implementation;
- a **translated** app method: call the translated function using the
  translator's internal convention.

Return values are marshalled back (`x0`/`d0` for scalars, `x8` for indirect
struct returns). The arm64 details that matter:

- integer arguments in `x0`–`x7`, floating in `d0`–`d7`, the rest on the
  16-byte-aligned stack;
- `x8` holds the address of an indirect (large struct) result; HFAs
  return in `d0`-`d3` instead, even above sixteen bytes, while x86_64
  would use a hidden buffer, so oversized HFAs are copied through a
  temporary;
- `x29` frame pointer, `x30` link register, `sp` 16-byte aligned;
- Darwin passes variadic arguments on the stack. A local probe with our
  `clang -target arm64-apple-ios18.0-simulator` emitted exactly that shape
  (arguments stored at `[sp]` before `bl _printf`), and method encodings and
  NSInvocation type strings already describe the arguments in an
  architecture-independent form.

Because translated functions share one internal convention, only
app-to-framework and framework-to-app transitions need ABI marshalling.
That is deliberately the smallest possible number of crossings: a
translated app method that sends messages spends its framework time in
native code.

## Loader integration

The arm64 path reuses most of the loader:

- **Mach-O**: the header check in `loader/macho.c` becomes an architecture
  switch. Chained fixups use the same pointer formats as x86_64 for plain
  arm64 (`DYLD_CHAINED_PTR_64`); `loader/fixups.c` already recognizes the
  arm64e authenticated forms (and rejects them for x86_64 images).
- **Objective-C metadata**: class/ro/method/category/ivar parsing is
  pointer-width and layout independent. The runtime's lookup, resolution,
  forwarding and override logic are shared; only IMP invocation differs.
- **Symbols**: imported framework symbols bind to native x86_64 thunks.
  Exported app symbols bind to translation stubs that translate on first
  call.
- **Code cache**: translated blocks are written to an executable mapping
  owned by the loader (already needed for JIT pages), with per-image
  bookkeeping and an optional on-disk cache keyed by UUID.
- **Trampolines**: an arm64 `objc_msgSend` entry parallels `start.S`; the
  dispatcher remains one implementation.

Plain arm64 (cputype `0x100000c`) is what third-party apps ship. A local
probe with our clang/`ld64.lld` produced that CPU type and no PAC
instructions. arm64e images use `pac*`/`aut*` and pointer authentication;
they can be rejected at first, or their PAC instructions treated as
no-ops behind a per-image flag once the rest works.

## Instruction coverage

Start with the scalar subset clang emits for ordinary C and Objective-C:
loads/stores, integer arithmetic and shifts, comparisons and branches,
`adrp`/`add` addressing, calls and returns, and the floating-point
equivalents. Then add, driven by failing fixtures:

- **NEON/AdvSIMD**: the long pole. Map the common vector operations to SSE
  and grow coverage from real app code; do not attempt a complete
  instruction-set implementation up front.
- **Atomics and barriers**: `ldxr`/`stxr`/`ldaxr`/`stlxr` and compare-and-swap
  map to host atomics. x86's TSO is stronger than ARM's model, so most
  barriers become no-ops.
- **Variadic calls and indirect struct returns**, per the ABI section.
- **Unwind tables**: only needed if exceptions are implemented; iosim does
  not support them today, so translation can inherit that limit.
- **Tagged pointers**: arm64 app code may embed tagged NSNumber/NSString
  pointers that x86_64 builds would not. Our Foundation needs to recognize
  such pointers (or the runtime must ensure app literals do not create
  them), and this deserves a fixture of its own.

## Milestones

**0 — map, do not run.** Accept an arm64 Mach-O, parse classes, categories,
method lists and fixups, and expose IMP offsets. No execution. This alone
lets us inventory the real instruction and metadata shapes.

**1 — interpreter and bridges.** A scalar interpreter plus the arm64
`objc_msgSend` thunk and native call gates. Run a C "hello" and an ObjC
fixture built for arm64. The goal is ABI correctness, not speed.

**2 — block translator and lazy cache.** Translate basic blocks to
x86_64, cache per IMP, and rerun the same fixtures. Compare output against
their x86_64 builds.

**3 — coverage and persistence.** NEON, atomics, varargs, struct returns,
JIT-page translation, and the on-disk translation cache.

**4 — the suite in both architectures.** The existing fixtures are built
for x86_64 and arm64; logs and framebuffer captures are compared. The arm64
translation sections stay feature-gated so a tree without the translator
still passes today's suite.

## Fixture plan

- `tests/arm64/smoke.c`: integer and floating arithmetic, a variadic
  `printf`, a function pointer, a small struct passed and returned.
- `tests/arm64/objc.m`: classes, subclasses, categories, dynamic
  resolution, `forwardingTargetForSelector:`, `NSInvocation` delivery.
- Both are built twice with the same clang driver
  (`-target arm64-apple-ios18.0-simulator` and
  `-target x86_64-apple-ios18.0-simulator`) and their output compared. A
  `tools/build_app.sh` `--arch` option or a sibling script can keep the
  arm64 build out of the existing fixtures' compile lines.
- A later fixture exercises a NEON-heavy loop and a JIT-like executable
  page written at runtime.

## Risks

- NEON and floating-point semantics are where correctness bugs will
  concentrate.
- JIT code generation breaks the ahead-of-time assumption; it needs
  executable-page interception.
- ObjC IMPs are not the only code pointers: C function pointers, blocks,
  C++ vtables and `objc_msgSend` itself are all arm64 addresses that must
  be translated or thunked.
- Translated code must be careful with the stack: guest stack frames and
  native frames interleave at every framework call.
- The translator becomes security-sensitive: it executes foreign machine
  code, so its decoder must fail closed on malformed input.
- A correct full implementation is a months-scale project. The partition
  above is what makes it tractable, not small.

## Alternatives considered

- **Rosetta**: translates x86_64 to arm64, the wrong direction, and is
  proprietary.
- **Box64/FEX-Emu**: x86_64 on ARM64, also the wrong direction.
- **KVM/Xen**: there is no ARM virtualization on x86_64 hosts.
- **qemu-user or full-system QEMU**: works, but is precisely CPU emulation,
  translates our frameworks too, and is slow.
- **ARM64 hardware offload**: run the app on an ARM64 host and stream the
  framebuffer and events. The only translation-free path, but it needs ARM
  hardware and defeats the local-simulator premise.

The method worth building is the hybrid: **ObjC dispatch as the ISA
boundary, application code translated lazily and cached, and every
framework call native**.
