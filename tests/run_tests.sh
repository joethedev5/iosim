#!/bin/sh
# End-to-end tests for the iosim native x86_64 simulator runtime.
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
T="$ROOT/build/test-fixtures"
RUN="$ROOT/build/iosim-run"
TARGET="x86_64-apple-ios18.0-simulator"
PLATFORM="ios-simulator 18.0 18.0"
fails=0

if [ ! -x "$RUN" ]; then
    echo "build the loader first: cmake -S . -B build && cmake --build build" >&2
    exit 1
fi
mkdir -p "$T"

check() {
    needle="$1"; haystack="$2"; what="$3"
    case "$haystack" in
        *"$needle"*) echo "ok   $what" ;;
        *) echo "FAIL $what"; echo "     expected: $needle"; echo "     got: $haystack"; fails=$((fails+1)) ;;
    esac
}

obj() { "$CC" -target "$TARGET" -ffreestanding -fPIC -O1 -c "$1" -o "$2"; }
exe() { out="$1"; shift; "$LD64" -arch x86_64 -platform_version $PLATFORM -e _main -o "$out" "$@" -undefined dynamic_lookup; }
dylib() { out="$1"; install="$2"; shift 2; "$LD64" -arch x86_64 -platform_version $PLATFORM -dylib -install_name "$install" -o "$out" "$@" -undefined dynamic_lookup; }

# ---------- 1. chained-fixup executable ----------
cat > "$T/hello.c" <<'EOF'
extern int printf(const char *fmt, ...);
extern int getpid(void);
int main(void)
{
    printf("hello from iosim fixture pid=%d\n", getpid());
    return 0;
}
EOF
obj "$T/hello.c" "$T/hello.o"
exe "$T/hello" "$T/hello.o"
out="$("$RUN" "$T/hello")"
check "hello from iosim fixture" "$out" "Mach-O executable with chained fixups"

# ---------- 2. dyld-style dylib loading ----------
cat > "$T/greet.c" <<'EOF'
extern int printf(const char *fmt, ...);
int greet(const char *who)
{
    printf("dylib greet %s\n", who);
    return 42;
}
EOF
cat > "$T/usedylib.c" <<'EOF'
extern int printf(const char *fmt, ...);
extern int greet(const char *who);
int main(void)
{
    printf("main calls dylib\n");
    int rc = greet("linux");
    printf("dylib returned %d\n", rc);
    return rc == 42 ? 0 : 1;
}
EOF
obj "$T/greet.c" "$T/greet.o"
dylib "$T/libgreet.dylib" libgreet.dylib "$T/greet.o"
obj "$T/usedylib.c" "$T/usedylib.o"
exe "$T/hello_dylib" "$T/usedylib.o" "$T/libgreet.dylib"
out="$("$RUN" --dylib-path "$T" "$T/hello_dylib")"
check "main calls dylib" "$out" "multi-image load"
check "dylib greet linux" "$out" "cross-image symbol binding"
check "dylib returned 42" "$out" "cross-image return value"

# ---------- 3. Objective-C runtime ----------
cat > "$T/objc_test.m" <<'EOF'
extern int printf(const char *fmt, ...);
extern void *calloc(unsigned long n, unsigned long size);

__attribute__((objc_root_class))
@interface Greeter
{
    int _count;
}
+ (id)alloc;
- (id)init;
- (void)greet:(const char *)name;
@end

@implementation Greeter
+ (id)alloc { return calloc(1, 32); }
- (id)init { _count = 7; return self; }
- (void)greet:(const char *)name { printf("objc greet %s count=%d\n", name, _count); }
@end

int main(void)
{
    Greeter *g = [[Greeter alloc] init];
    [g greet:"world"];
    return 0;
}
EOF
"$CC" -target "$TARGET" -fobjc-runtime=ios-18.0 -fno-objc-arc -ffreestanding -O1 -c "$T/objc_test.m" -o "$T/objc_test.o"
exe "$T/objc_test" "$T/objc_test.o"
out="$("$RUN" "$T/objc_test")"
check "objc greet world count=7" "$out" "ObjC class registration, ivar layout and msgSend"

# ---------- 4. Foundation-lite at the runtime root ----------
cat > "$T/nslog_test.m" <<'EOF'
extern void NSLog(void *format, ...);
int main(void)
{
    NSLog(@"foundation lite works");
    return 0;
}
EOF
"$CC" -target "$TARGET" -fobjc-runtime=ios-18.0 -fno-objc-arc -ffreestanding -O1 -c "$T/nslog_test.m" -o "$T/nslog_test.o"
exe "$T/nslog_test" "$T/nslog_test.o"
out="$(DYLD_ROOT_PATH="$ROOT/runtime" "$RUN" "$T/nslog_test" 2>&1)"
check "foundation lite works" "$out" "Foundation.framework substitution and constant CFString"

cat > "$T/date_test.m" <<'EOF'
#include "foundation_lite.h"
int main(void)
{
    @autoreleasepool
    {
        NSDate *epoch = [NSDate dateWithTimeIntervalSince1970:0];
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        [formatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
        NSLog(@"date=%@", [formatter stringFromDate:epoch]);
        NSError *error = [NSError errorWithDomain:@"Test"
                                             code:42 userInfo:nil];
        NSLog(@"error domain=%@ code=%ld", [error domain], [error code]);
    }
    return 0;
}
EOF
"$CC" -target "$TARGET" -fobjc-runtime=ios-18.0 -fno-objc-arc -ffreestanding -O1 -I "$ROOT/frameworks" -c "$T/date_test.m" -o "$T/date_test.o"
"$LD64" -arch x86_64 -platform_version $PLATFORM -o "$T/date_test" "$T/date_test.o" "$ROOT/runtime/System/Library/Frameworks/Foundation.framework/Foundation" -undefined dynamic_lookup
out="$(DYLD_ROOT_PATH="$ROOT/runtime" "$RUN" "$T/date_test" 2>&1)"
check "date=1970-01-01 00:00:00" "$out" "NSDate/NSDateFormatter"
check "error domain=Test code=42" "$out" "NSError"

# ---------- 5. UIKit-lite framework dylib ----------
cat > "$T/uikit_app.c" <<'EOF'
extern int printf(const char *fmt, ...);
extern int UIApplicationMain(int argc, char **argv, void *principal, void *delegate);
int main(void)
{
    printf("app: before UIApplicationMain\n");
    return UIApplicationMain(1, 0, 0, 0);
}
EOF
obj "$T/uikit_app.c" "$T/uikit_app.o"
exe "$T/uikit_app" "$T/uikit_app.o" "$ROOT/runtime/System/Library/Frameworks/UIKit.framework/UIKit"
out="$(DYLD_ROOT_PATH="$ROOT/runtime" "$RUN" "$T/uikit_app")"
check "app: before UIApplicationMain" "$out" "UIKit-linked app"
check "UIApplicationMain argc=1" "$out" "UIKit.framework substitution"

# ---------- 6. Device lifecycle / simctl surface ----------
export IOSIM_HOME="$ROOT/build/test-home"
export IOSIM_RUNTIME_ROOT="$ROOT/runtime"
rm -rf "$IOSIM_HOME"
UDID="$("$ROOT/tools/iosimctl" create "Test iPhone" com.iosim.SimDeviceType.iPhone-18-Pro)"
"$ROOT/tools/iosimctl" boot "$UDID" >/dev/null
mkdir -p "$T/TestApp.app"
cp "$T/hello" "$T/TestApp.app/TestApp"
python3 - "$T/TestApp.app/Info.plist" <<'PY'
import plistlib, sys
with open(sys.argv[1], "wb") as f:
    plistlib.dump({
        "CFBundleIdentifier": "com.iosim.fixture",
        "CFBundleExecutable": "TestApp",
        "CFBundleName": "TestApp",
        "CFBundlePackageType": "APPL",
        "CFBundleVersion": "1",
        "CFBundleShortVersionString": "1.0",
    }, f)
PY
"$ROOT/tools/iosimctl" install "$UDID" "$T/TestApp.app" >/dev/null
out="$("$ROOT/tools/iosimctl" launch --console "$UDID" com.iosim.fixture)"
check "hello from iosim fixture" "$out" "install + launch through iosimctl"

# Framebuffer rendering + io screenshot through the device manager.
mkdir -p "$T/UIKitApp.app"
cp "$T/uikit_app" "$T/UIKitApp.app/UIKitApp"
python3 - "$T/UIKitApp.app/Info.plist" <<'PY'
import plistlib, sys
with open(sys.argv[1], "wb") as f:
    plistlib.dump({
        "CFBundleIdentifier": "com.iosim.uikit",
        "CFBundleExecutable": "UIKitApp",
        "CFBundleName": "UIKitApp",
        "CFBundlePackageType": "APPL",
        "CFBundleVersion": "1",
        "CFBundleShortVersionString": "1.0",
    }, f)
PY
"$ROOT/tools/iosimctl" install "$UDID" "$T/UIKitApp.app" >/dev/null
out="$("$ROOT/tools/iosimctl" launch --console "$UDID" com.iosim.uikit 2>&1)"
check "UIApplicationMain argc=1" "$out" "UIKit app renders through iosimctl"
"$ROOT/tools/iosimctl" io "$UDID" screenshot "$T/screen.png" >/dev/null
python3 - "$T/screen.png" <<'PY'
import struct, sys
data = open(sys.argv[1], "rb").read()
assert data[:8] == b"\x89PNG\r\n\x1a\n", "not a PNG"
w, h = struct.unpack(">II", data[16:24])
assert (w, h) == (1206, 2622), (w, h)
print(f"ok   framebuffer screenshot {w}x{h}")
PY
out="$(SIMCTL_CHILD_IOSIM_TEST=1 "$ROOT/tools/iosimctl" spawn "$UDID" "$T/objc_test")"
check "objc greet world count=7" "$out" "simctl spawn equivalent"
"$ROOT/tools/iosimctl" shutdown "$UDID" >/dev/null

if [ "$fails" -ne 0 ]; then
    echo "$fails test(s) failed" >&2
    exit 1
fi
echo "all tests passed"
