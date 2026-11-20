# Running Apple's Metal Shader Converter natively

The Metal Shader Converter package contains a macOS x86_64/arm64 command-line
tool and `libmetalirconverter.dylib`. It converts **DXIL to Metal IR**
(`.metallib`); it does not compile Metal source. This document records how to
unpack it and run the x86_64 CLI under `iosim-run`, which executes the Apple
Mach-O natively on Linux.

The package is Apple-licensed and is not redistributed here. Keep it under
`third_party/` (ignored by git) or elsewhere outside version control.

## 1. Unpack the package

```sh
7z x Metal_Shader_Converter_4.0_beta_3.pkg \
    MetalShaderConverter.pkg/Payload MetalShaderConverter.pkg/PackageInfo
mkdir -p root && cd root
gzip -dc ../MetalShaderConverter.pkg/Payload | cpio -idm --no-absolute-filenames
```

The tree installs:

```
usr/local/bin/metal-shaderconverter            59 MB, x86_64 + arm64
usr/local/lib/libmetalirconverter.dylib        58 MB, macOS
usr/local/lib_iOS/libmetalirconverter.dylib    29 MB, arm64 iOS
usr/local/include/metal_irconverter/*.h        C API and enums
opt/metal-shaderconverter/docs/UserManual.md
```

## 2. Host libraries

The CLI imports libc++, libarchive, libbz2 and CommonCrypto (via libSystem),
and links CoreFoundation. Install the host equivalents of the first three:

```sh
sudo apt install libc++1-19 libc++abi1-19 libarchive13t64 libbz2-1.0
```

`tools/build_runtime.sh` creates empty Mach-O anchors at the canonical Darwin
paths (`/usr/lib/libc++.1.dylib`, `libarchive.2.dylib`, `libbz2.1.0.dylib`)
and a `CoreFoundation.framework/Versions/A/CoreFoundation` symlink, so the
guest loader finds every LC_LOAD_DYLIB. Their symbols are supplied by the
loader's own shims or, for libc++, by the host process bridge.

## 3. Run it

```sh
tools/host-run.sh /path/to/root/usr/local/bin/metal-shaderconverter --version
# metal-irconverter version: 4.0.3
# Default triple: air64-apple-macosx15.0.0
```

`tools/host-run.sh` sets:

- `DYLD_ROOT_PATH` to the generated runtime root,
- `IOSIM_HOST_SYMBOLS=1`, enabling the opt-in host-symbol fallback,
- `IOSIM_HOST_LIBS`, a colon-separated list of host libraries to `dlopen`
  into the loader process (`libc++.so.1`, `libc++abi.so.1`, `libarchive.so.13`,
  `libbz2.so.1.0`, `libcrypto.so.3` by default).

The fallback is off unless `IOSIM_HOST_SYMBOLS` is set, so ordinary simulator
guests keep the closed shim namespace and never pass Darwin `open` flags to a
glibc function by accident.

## 4. Convert a DXIL shader

Generate a DXIL test input with Microsoft's Linux `dxc` (not part of the
package):

```sh
cat > shader.hlsl <<'EOF'
float4 main(float4 pos : SV_Position) : SV_Target
{
    return float4(0.25, 0.5, 0.75, 1.0);
}
EOF
dxc -T ps_6_0 -E main -Fo shader.dxil shader.hlsl

tools/host-run.sh /path/to/root/usr/local/bin/metal-shaderconverter \
    shader.dxil -o=shader.metallib
```

Expected result: exit status 0 and a 4.5 KB `shader.metallib` beginning with
`MTLB`. `strings` shows the container trail (`NAME`, `main`, `TYPE`, `HASH`,
`VERS`, `UUID`, `ENDTRLST`), and the function name is the HLSL entry point.

Note the option syntax: `-o=<file>` must carry the equals sign; a bare
`shader.dxil` is the positional DXIL input.

## 5. What the loader had to provide

`--version` and `--help` already exercise most of the C++ runtime. A real
conversion needed:

- **Mach-O initializers**: the CLI registers its LLVM options through 242
  `__TEXT,__init_offsets` constructors (32-bit offsets relative to the image
  base), and the loader also handles `__DATA,__mod_init_func` pointer arrays.
  Without these, `--help` showed only LLVM's built-in generic options.
- **Darwin pthread static initializers**: `PTHREAD_MUTEX_INITIALIZER` embeds
  `0x32AAABA7`, which glibc interprets as a locked futex. The loader scans
  writable data sections for the documented signatures (mutex, recursive,
  errorcheck, cond, once, rwlock), verifies the opaque tail is zero, and
  re-initializes those objects with the host pthread library. This removed a
  deadlock in `DXIL2AIR::assemble`.
- **Thread-local variables**: two `__DATA,__thread_vars` thunks (LLVM's
  stream-ID token and TimeTrace profiler) use `__DATA,__thread_bss` offsets.
  The loader installs its own register-preserving getter, one pthread key per
  image, and lazily copies the combined `__thread_data`/`__thread_bss`
  initial content for each thread.
- **CommonCrypto**: `CC_MD5_*` and `CC_SHA256_*` are implemented in
  `loader/ccrypto.c` and verified against the standard `abc` vectors.
- **dispatch_data**: create/size/apply/concat/subrange/map over a simple
  byte-buffer object.
- **Darwin signals**: `sigprocmask`'s how values (1/2/3) and the 32-bit
  `sigset_t`, plus signal numbers and `struct sigaction` (16 bytes), are
  translated to glibc equivalents.
- **Darwin stat/open**: `stat$INODE64`, `fstat$INODE64`, `lstat$INODE64`,
  `fstatat$INODE64` fill the 144-byte Darwin `struct stat`, and `open` maps
  Darwin flag bits.

`tests/loader_runtime_test.c` exercises all of these without the Apple tool:
constructors, nonzero `__thread_data`, mutex normalization, both digests,
dispatch_data application, `SIG_SETMASK`, and a stat/open file round trip.
