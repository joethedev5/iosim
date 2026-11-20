#!/bin/sh
# Build a guest x86_64 iOS Simulator binary with Zig's bundled clang and
# linker. No Apple SDK is needed: Zig supplies the Darwin target, libc headers
# and Mach-O linker. The default build still uses clang + ld64.lld; this path
# is optional and only needs a Zig 0.17+ installation.
#
# usage: ZIG=/path/to/zig tools/build_app_zig.sh app.m build/app
set -eu

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ZIG="${ZIG:-zig}"
if ! command -v "$ZIG" >/dev/null 2>&1; then
    echo "build_app_zig: Zig not found; set ZIG=/path/to/zig" >&2
    exit 1
fi

if [ "$#" -lt 2 ]; then
    echo "usage: ZIG=/path/to/zig tools/build_app_zig.sh source.m output" >&2
    exit 1
fi
SRC="$1"
OUT="$2"
shift 2

FOUNDATION="$ROOT/runtime/System/Library/Frameworks/Foundation.framework/Foundation"
if [ ! -f "$FOUNDATION" ]; then
    echo "build_app_zig: build the runtime first with tools/build_runtime.sh" >&2
    exit 1
fi

# Zig's linker decides input format by extension; the runtime's canonical
# simulator path has none, so hand it a .dylib symlink.
STAGE="$ROOT/build/zig"
mkdir -p "$STAGE"
ln -sf "$FOUNDATION" "$STAGE/Foundation.dylib"

mkdir -p "$(dirname "$OUT")"
exec "$ZIG" cc -target x86_64-ios-simulator \
    -fobjc-runtime=ios-18.0 -fno-objc-arc -ffreestanding -O1 \
    -I "$ROOT/frameworks" "$SRC" "$STAGE/Foundation.dylib" \
    -o "$OUT" -undefined dynamic_lookup -Wl,-e,_main "$@"
