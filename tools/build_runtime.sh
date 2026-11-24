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
  "$OUT/System/Library/Frameworks/UserNotifications.framework" \
  "$OUT/System/Library/Frameworks/Foundation.framework" \
  "$OUT/System/Library/Frameworks/CoreGraphics.framework" \
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

"$CC" -target "$SDK_TARGET" -ffreestanding -fPIC \
  -c "$ROOT/frameworks/invoke_x86_64.s" -o "$B/invoke_x86_64.o"

build_dylib "$ROOT/frameworks/Foundation.m" \
  "$OUT/System/Library/Frameworks/Foundation.framework/Foundation" \
  /System/Library/Frameworks/Foundation.framework/Foundation "" \
  "$B/invoke_x86_64.o"

"$CC" -target "$SDK_TARGET" -ffreestanding -fPIC -c "$ROOT/frameworks/protocol_export.s" -o "$B/protocol_export.o"

build_dylib "$ROOT/frameworks/CoreGraphics.m" \
  "$OUT/System/Library/Frameworks/CoreGraphics.framework/CoreGraphics" \
  /System/Library/Frameworks/CoreGraphics.framework/CoreGraphics ""

build_dylib "$ROOT/frameworks/UIKit.m" \
  "$OUT/System/Library/Frameworks/UIKit.framework/UIKit" \
  /System/Library/Frameworks/UIKit.framework/UIKit \
  "$OUT/System/Library/Frameworks/Foundation.framework/Foundation" \
  "$OUT/System/Library/Frameworks/CoreGraphics.framework/CoreGraphics" \
  "$B/protocol_export.o"

build_dylib "$ROOT/frameworks/UserNotifications.m" \
  "$OUT/System/Library/Frameworks/UserNotifications.framework/UserNotifications" \
  /System/Library/Frameworks/UserNotifications.framework/UserNotifications \
  "$OUT/System/Library/Frameworks/Foundation.framework/Foundation" \
  "$OUT/System/Library/Frameworks/UIKit.framework/UIKit"

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

# Canonical versioned paths and host-tool anchors: macOS binaries reference
# CoreFoundation through Versions/A and versioned libSystem dylibs. The loader
# resolves their imports through its shim namespace, so empty images suffice
# for dependency lookup and keep every canonical path present.
mkdir -p "$OUT/System/Library/Frameworks/CoreFoundation.framework/Versions/A"
ln -sf ../../CoreFoundation \
  "$OUT/System/Library/Frameworks/CoreFoundation.framework/Versions/A/CoreFoundation"
"$CC" -target x86_64-apple-macos27.0 -ffreestanding -fPIC \
  -c "$ROOT/frameworks/empty.c" -o "$B/empty-macos.o"
for lib in libc++.1 libarchive.2 libbz2.1.0; do
  "$LD64" -arch x86_64 -platform_version macos 27.0 27.0 \
    -dylib -install_name "/usr/lib/$lib.dylib" \
    -o "$OUT/usr/lib/$lib.dylib" "$B/empty-macos.o" -undefined dynamic_lookup
done

# SpringBoard: the system UI executable, booted by launchd.
SB_DIR="$OUT/System/Library/CoreServices/SpringBoard.app"
mkdir -p "$SB_DIR"
"$CC" -target "$SDK_TARGET" -ffreestanding -fPIC -O2 \
  -fobjc-runtime=ios-18.0 -fno-objc-arc -fblocks -I "$ROOT/demo" \
  -c "$ROOT/demo/SpringBoard.m" -o "$B/SpringBoard.o"
"$LD64" -arch x86_64 -platform_version ios-simulator 18.0 18.0 \
  -o "$SB_DIR/SpringBoard" "$B/SpringBoard.o" \
  "$OUT/System/Library/Frameworks/Foundation.framework/Foundation" \
  "$OUT/System/Library/Frameworks/UIKit.framework/UIKit" \
  "$OUT/System/Library/Frameworks/QuartzCore.framework/QuartzCore" \
  -undefined dynamic_lookup
if [ ! -f "$SB_DIR/Info.plist" ]; then
  cat > "$SB_DIR/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>CFBundleExecutable</key><string>SpringBoard</string>
  <key>CFBundleIdentifier</key><string>com.apple.springboard</string>
  <key>CFBundleName</key><string>SpringBoard</string>
  <key>CFBundlePackageType</key><string>APPL</string>
  <key>CFBundleShortVersionString</key><string>1.0</string>
  <key>CFBundleVersion</key><string>1</string>
</dict></plist>
PLIST
fi

echo "runtime root: $OUT"
find "$OUT" -type f | sort
