#!/bin/sh
# Build a demo app as an x86_64 iOS-simulator Mach-O against the local runtime,
# without an Apple SDK. The app includes demo/UIKitStub.h when the Apple UIKit
# headers are absent.
# usage: tools/build_app.sh demo/ListApp.m build/ListApp
set -eu
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
CC="${CC:-clang}"
LD64="${LD64:-$(command -v ld64.lld 2>/dev/null || ls /usr/lib/llvm-*/bin/ld64.lld 2>/dev/null | head -1)}"
SRC="$1"
OUT="$2"
if [ -z "${LD64:-}" ] || [ ! -x "$LD64" ]; then
    echo "ld64.lld not found" >&2
    exit 1
fi
for f in UIKit Foundation QuartzCore; do
    if [ ! -f "$ROOT/runtime/System/Library/Frameworks/$f.framework/$f" ]; then
        echo "runtime missing $f; run tools/build_runtime.sh first" >&2
        exit 1
    fi
done
OBJ="$OUT.o"
"$CC" -target x86_64-apple-ios18.0-simulator -ffreestanding \
    -fobjc-runtime=ios-18.0 -fno-objc-arc -fblocks -O1 \
    -I "$ROOT/demo" -c "$SRC" -o "$OBJ"
"$LD64" -arch x86_64 -platform_version ios-simulator 18.0 18.0 \
    -o "$OUT" "$OBJ" \
    "$ROOT/runtime/System/Library/Frameworks/Foundation.framework/Foundation" \
    "$ROOT/runtime/System/Library/Frameworks/UIKit.framework/UIKit" \
    "$ROOT/runtime/System/Library/Frameworks/QuartzCore.framework/QuartzCore" \
    -undefined dynamic_lookup
rm -f "$OBJ"
echo "built $OUT"
