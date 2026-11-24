#!/bin/sh
# Build a demo app as an iOS-simulator Mach-O against the local runtime,
# without an Apple SDK. The app includes demo/UIKitStub.h when the Apple UIKit
# headers are absent.
# usage: tools/build_app.sh [--arch arm64|x86_64] demo/ListApp.m build/ListApp
set -eu
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
CC="${CC:-clang}"
LD64="${LD64:-$(command -v ld64.lld 2>/dev/null || ls /usr/lib/llvm-*/bin/ld64.lld 2>/dev/null | head -1)}"
ARCH=x86_64
if [ "${1:-}" = "--arch" ]; then
    ARCH="${2:-}"
    shift 2
fi
case "$ARCH" in
    x86_64|arm64) ;;
    *) echo "usage: $0 [--arch arm64|x86_64] source output" >&2; exit 2 ;;
esac
SRC="${1:-}"
OUT="${2:-}"
if [ -z "$SRC" ] || [ -z "$OUT" ]; then
    echo "usage: $0 [--arch arm64|x86_64] source output" >&2
    exit 2
fi
if [ -z "${LD64:-}" ] || [ ! -x "$LD64" ]; then
    echo "ld64.lld not found" >&2
    exit 1
fi
for f in UIKit Foundation QuartzCore UserNotifications; do
    if [ ! -f "$ROOT/runtime/System/Library/Frameworks/$f.framework/$f" ]; then
        echo "runtime missing $f; run tools/build_runtime.sh first" >&2
        exit 1
    fi
done
OBJ="$OUT.o"
"$CC" -target "$ARCH-apple-ios18.0-simulator" -ffreestanding \
    -fobjc-runtime=ios-18.0 -fno-objc-arc -fblocks -O1 \
    -I "$ROOT/demo" -c "$SRC" -o "$OBJ"
if [ "$ARCH" = arm64 ]; then
    "$LD64" -arch arm64 -platform_version ios-simulator 18.0 18.0 \
        -e _main -o "$OUT" "$OBJ" -undefined dynamic_lookup
else
    "$LD64" -arch x86_64 -platform_version ios-simulator 18.0 18.0 \
        -o "$OUT" "$OBJ" \
        "$ROOT/runtime/System/Library/Frameworks/Foundation.framework/Foundation" \
        "$ROOT/runtime/System/Library/Frameworks/UIKit.framework/UIKit" \
        "$ROOT/runtime/System/Library/Frameworks/QuartzCore.framework/QuartzCore" \
        "$ROOT/runtime/System/Library/Frameworks/UserNotifications.framework/UserNotifications" \
        -undefined dynamic_lookup
fi
rm -f "$OBJ"
echo "built $OUT"
