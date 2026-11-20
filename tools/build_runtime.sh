#!/bin/sh
# Build the iosim runtime root: reimplemented framework dylibs placed at the
# same install paths the simulator uses, so DYLD_ROOT_PATH substitution works.
set -eu
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
CC="${CC:-clang}"
LD64="${LD64:-$(command -v ld64.lld 2>/dev/null || true)}"
if [ -z "$LD64" ]; then
    LD64="$(ls /usr/lib/llvm-*/bin/ld64.lld 2>/dev/null | head -1)"
fi
if [ -z "$LD64" ] || [ ! -x "$LD64" ]; then
    echo "ld64.lld not found; install lld or set LD64" >&2
    exit 1
fi
SDK_TARGET="${SDK_TARGET:-x86_64-apple-ios18.0-simulator}"
OUT="$ROOT/runtime"
B="$ROOT/build/runtime"
mkdir -p "$B" \
  "$OUT/System/Library/Frameworks/UIKit.framework" \
  "$OUT/System/Library/Frameworks/Foundation.framework" \
  "$OUT/System/Library/Frameworks/CoreFoundation.framework" \
  "$OUT/System/Library/Frameworks/QuartzCore.framework" \
  "$OUT/System/Library/PrivateFrameworks" \
  "$OUT/usr/lib/system" \
  "$OUT/System/Library/CoreServices"

build_dylib() {
  src="$1"; out="$2"; install="$3"; shift 3
  obj="$B/$(basename "$src" | sed 's/\.[cm]$//').o"
  case "$src" in
    *.m) objcflags="-fobjc-runtime=ios-18.0 -fno-objc-arc -fblocks" ;;
    *)   objcflags="" ;;
  esac
  "$CC" -target "$SDK_TARGET" -ffreestanding -fPIC -O2 $objcflags \
    -I "$ROOT/frameworks" -c "$src" -o "$obj"
  "$LD64" -arch x86_64 -platform_version ios-simulator 18.0 18.0 \
    -dylib -install_name "$install" -o "$out" "$obj" "$@" -undefined dynamic_lookup
}

build_dylib "$ROOT/frameworks/Foundation.m" \
  "$OUT/System/Library/Frameworks/Foundation.framework/Foundation" \
  /System/Library/Frameworks/Foundation.framework/Foundation ""

"$CC" -target "$SDK_TARGET" -ffreestanding -fPIC -c "$ROOT/frameworks/protocol_export.s" -o "$B/protocol_export.o"

build_dylib "$ROOT/frameworks/UIKit.m" \
  "$OUT/System/Library/Frameworks/UIKit.framework/UIKit" \
  /System/Library/Frameworks/UIKit.framework/UIKit \
  "$OUT/System/Library/Frameworks/Foundation.framework/Foundation" "$B/protocol_export.o"

# Dependency anchors: real runtime layout, empty implementations for now.
"$CC" -target "$SDK_TARGET" -ffreestanding -fPIC -c "$ROOT/frameworks/empty.c" -o "$B/empty.o"
for spec in \
  "/usr/lib/libSystem.B.dylib:/usr/lib/libSystem.B.dylib" \
  "/usr/lib/libobjc.A.dylib:/usr/lib/libobjc.A.dylib" \
  "/System/Library/Frameworks/CoreFoundation.framework/CoreFoundation:/System/Library/Frameworks/CoreFoundation.framework/CoreFoundation" \
  "/System/Library/Frameworks/QuartzCore.framework/QuartzCore:/System/Library/Frameworks/QuartzCore.framework/QuartzCore"
do
  out="${spec%%:*}"; install="${spec##*:}"
  "$LD64" -arch x86_64 -platform_version ios-simulator 18.0 18.0 \
    -dylib -install_name "$install" -o "$OUT$out" "$B/empty.o" -undefined dynamic_lookup
done

echo "runtime root: $OUT"
find "$OUT" -type f | sort
