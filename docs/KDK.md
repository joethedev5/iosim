# Kernel Debug Kit: unpacking and full symbolication

Apple publishes Kernel Debug Kits as a compressed DMG containing a flat
package. The package is not redistributed with iosim; place the DMG outside
version control (the repository ignores `third_party/`) and follow these steps
locally. The extracted kernel is an x86_64 Mach-O — the same user/kernel ABI
the native simulator mirrors — and its dSYM carries every local function that
the release kernel strips.

## 1. Unpack the DMG and package

```sh
sudo apt install 7zip xar cpio

# list the DMG, then extract the flat package
7z l Kernel_Debug_Kit_27.0.1_build_26A434.dmg
7z x -o/tmp/kdk Kernel_Debug_Kit_27.0.1_build_26A434.dmg \
    "Kernel Debug Kit/KernelDebugKit.pkg"

# xar reads the package's TOC and writes the payload unchanged
cd /tmp/kdk/"Kernel Debug Kit"
xar -x -f KernelDebugKit.pkg KDK.pkg/Payload

# the payload is a pbzx container; the tool streams it to cpio
mkdir -p /tmp/kdk/root && cd /tmp/kdk/root
python3 /path/to/iosim/tools/pbzx.py ../KDK.pkg/Payload |
    cpio -idm --no-absolute-filenames
```

`KDK_SDK.pkg/Payload` unpacks the same way. It is small (35 files) and holds
only `Kernel.framework` platform headers and static libraries (SPTM, TrustCache,
CodeSignature, CoreEntitlements); the main `KDK.pkg` payload is the useful one:
`System/Library/Kernels/kernel*`, their dSYMs, `System/Library/Extensions` kexts
and kext dSYMs, and the kernel-collection manifests.

A pbzx chunk header is a pair of big-endian 64-bit lengths (decompressed,
stored); equal lengths mean the chunk is raw, otherwise it is an xz stream.
KDK 27 payloads use both forms: 328 chunks total, 325 xz and 3 raw
16 MiB chunks. The unpacked tree is about 5.2 GiB and the release kernel's
dSYM is 70 MiB.

## 2. Symbolicate the kernel

`tools/kernel_symbols.py` parses Mach-O headers, segments, sections and the
symbol table directly (no debugger or SDK needed), merges a dSYM's local
symbol table with the release binary's exported symbols, and bounds each
function by the next text symbol in its section. `--source` asks
`llvm-dwarfdump` for the DWARF subprogram and line-table entry at an address.

```sh
K=/tmp/kdk/root/System/Library/Kernels
python3 tools/kernel_symbols.py --binary $K/kernel \
    --dsym $K/kernel.dSYM/Contents/Resources/DWARF/kernel \
    --summary --write-map build/kernel.symbols

printf '0xffffff80003e0a00\n' | python3 tools/kernel_symbols.py \
    --binary $K/kernel --dsym $K/kernel.dSYM/Contents/Resources/DWARF/kernel \
    --stdin --source
# 0xffffff80003e0a00  _mach_call_munger + 0x30  [__TEXT,__text]
#     at bsd_i386.c:506 (mach_call_munger)
```

`--mach-traps` and `--syscalls` decode the two XNU dispatch tables using their
symbols (`_mach_trap_table`, `_mach_trap_count`, `_sysent`, `_nsysent`) and
auto-detect the entry layout by checking which candidate function offset lands
on real text symbols.

## 3. Measured results (KDK 27.0.1, build 26A434)

- Release kernel: `x86_64` Mach-O, file type 22, UUID
  `8f0fa4f88dc23768a7eb04e58c6d1b88`, 24,379 symbols in the binary.
- dSYM: 50,898 symbols, of which 27,546 are text functions (19,187 external,
  8,359 local). The merged symbol map covers **99.275 %** of executable bytes
  (9,480,623 of 9,549,866); the uncovered remainder is `__KLD,__text` startup
  code with no dSYM symbols, not missing functions.
- Mach traps: `_mach_trap_count = 128`; entries are 24 bytes —
  `{ arg_info at +0, handler at +8, argument-munge at +16 }`. The low byte of
  `arg_info` is the argument count. Trap 31 is `_mach_msg_trap` (7 arguments),
  trap 26 `_mach_reply_port`, trap 45 `_task_for_pid`.
- BSD syscalls: `_nsysent = 558`; entries are 24 bytes —
  `{ sy_call +0, sy_arg_munge32 +8, return type +16, narg +20, arg bytes +22 }`.
  Syscall 0 is `_nosys`, 1 `_exit`, 3 `_read` (narg 3), 4 `_write`, 5 `_open`.
- The dispatch code confirms the same strides: `_mach_call_munger64` computes
  `table + index*24` and calls `*(entry+8)`; `_unix_syscall64` computes
  `index*24`, calls `*(entry+0)`, and reads narg from `entry+0x14`.

These tables are the ground truth for the Mach trap and BSD syscall numbers
that the simulator's services layer mirrors. The tool itself is tested without
a KDK: `tests/kernel_symbols_fixture.c` is a small non-PIE Mach-O with a
two-entry trap table and a two-entry syscall table, and the suite asserts the
layout detection, handler names, argument counts, source map and address
lookup against it.
