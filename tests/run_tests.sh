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

# ---------- 4b. Foundation file system, URLs and JSON ----------
"$CC" -target "$TARGET" -fobjc-runtime=ios-18.0 -fno-objc-arc \
    -ffreestanding -O1 -I "$ROOT/frameworks" \
    -c "$ROOT/tests/foundation_io_test.m" -o "$T/fio.o"
"$LD64" -arch x86_64 -platform_version $PLATFORM -e _main -o "$T/fio" \
    "$T/fio.o" \
    "$ROOT/runtime/System/Library/Frameworks/Foundation.framework/Foundation" \
    -undefined dynamic_lookup
FIO_HOME="$T/fio-home"
rm -rf "$FIO_HOME"
mkdir -p "$FIO_HOME"
out="$(cd "$FIO_HOME" && HOME="$FIO_HOME" DYLD_ROOT_PATH="$ROOT/runtime" \
    "$RUN" "$T/fio" 2>&1)"
check "mkdir 1" "$out" "NSFileManager creates intermediate directories"
check "dir exists 1 isdir 1" "$out" "fileExistsAtPath:isDirectory:"
check "read hello file" "$out" "NSData/NSString file round trip"
check "items 1 note.txt" "$out" "contentsOfDirectoryAtPath:"
check "copy exists 1" "$out" "copyItemAtPath:toPath:"
check "copy gone 1" "$out" "removeItemAtPath:"
check "ext txt" "$out" "NSURL path components"
check 'json {"name":"Sim","count":42,"list":[1.5,true,null]}' "$out" \
    "NSJSONSerialization writes deterministic compact JSON"
check "parsed Sim 42 1.5 1" "$out" \
    "NSJSONSerialization parses strings, numbers, arrays, bools and null"
check "invalid 1" "$out" "malformed JSON is rejected"

# ---------- 4c. NSUserDefaults persists an XML property list ----------
"$CC" -target "$TARGET" -fobjc-runtime=ios-18.0 -fno-objc-arc \
    -ffreestanding -O1 -I "$ROOT/frameworks" \
    -c "$ROOT/tests/defaults_test.m" -o "$T/defaults.o"
"$LD64" -arch x86_64 -platform_version $PLATFORM -e _main -o "$T/defaults" \
    "$T/defaults.o" \
    "$ROOT/runtime/System/Library/Frameworks/Foundation.framework/Foundation" \
    -undefined dynamic_lookup
DEF_HOME="$T/defaults-home"
rm -rf "$DEF_HOME"
mkdir -p "$DEF_HOME"
out="$(cd "$DEF_HOME" && HOME="$DEF_HOME" \
    XPC_SERVICE_NAME='UIKitApplication:com.iosim.defaults[iosim]' \
    DYLD_ROOT_PATH="$ROOT/runtime" "$RUN" "$T/defaults" write 2>&1)"
check "defaults: wrote theme=dark seen=1 count=42" "$out" \
    "NSUserDefaults stores strings, bools and integers"
out="$(cd "$DEF_HOME" && HOME="$DEF_HOME" \
    XPC_SERVICE_NAME='UIKitApplication:com.iosim.defaults[iosim]' \
    DYLD_ROOT_PATH="$ROOT/runtime" "$RUN" "$T/defaults" read 2>&1)"
check "defaults: theme=dark seen=1 count=42 recent=2 blob=4" "$out" \
    "a second process reads the same defaults domain"
if out="$(python3 - "$DEF_HOME/Library/Preferences/com.iosim.defaults.plist" <<'PY'
import plistlib, sys
with open(sys.argv[1], "rb") as f:
    d = plistlib.load(f)
assert d["theme"] == "dark", d
assert d["seen"] is True, d
assert d["launchCount"] == 42, d
assert d["recent"] == ["a", "b"], d
assert d["blob"] == b"abcd", d
print("ok   the defaults domain is a real XML property list on disk")
PY
)"; then
    echo "$out"
else
    echo "FAIL defaults plist"; echo "$out"; fails=$((fails+1))
fi

# ---------- 4d. NSKeyedArchiver writes and reads a keyed archive ----------
"$CC" -target "$TARGET" -fobjc-runtime=ios-18.0 -fno-objc-arc \
    -ffreestanding -O1 -I "$ROOT/frameworks" \
    -c "$ROOT/tests/keyed_test.m" -o "$T/keyed.o"
"$LD64" -arch x86_64 -platform_version $PLATFORM -e _main -o "$T/keyed" \
    "$T/keyed.o" \
    "$ROOT/runtime/System/Library/Frameworks/Foundation.framework/Foundation" \
    -undefined dynamic_lookup
KEY_HOME="$T/keyed-home"
rm -rf "$KEY_HOME"
mkdir -p "$KEY_HOME"
out="$(cd "$KEY_HOME" && HOME="$KEY_HOME" DYLD_ROOT_PATH="$ROOT/runtime" \
    "$RUN" "$T/keyed" write 2>&1)"
check "keyed: round name=Ada age=36 score=97.5 tags=2 items=2 enabled=1 blob=4 when=1700000000 class=Profile" \
    "$out" "NSKeyedArchiver round-trips a custom NSCoding object"
out="$(cd "$KEY_HOME" && HOME="$KEY_HOME" DYLD_ROOT_PATH="$ROOT/runtime" \
    "$RUN" "$T/keyed" read 2>&1)"
check "keyed: read name=Ada age=36 score=97.5 tags=2 items=2 enabled=1 blob=4 when=1700000000 class=Profile" \
    "$out" "a second process decodes the keyed archive"
if out="$(python3 - "$KEY_HOME/keyed-archive.plist" <<'PY'
import plistlib, sys
with open(sys.argv[1], "rb") as f:
    d = plistlib.load(f)
assert d["$archiver"] == "NSKeyedArchiver", d.get("$archiver")
assert d["$version"] == 100000, d.get("$version")
objs = d["$objects"]
root = objs[d["$top"]["root"]["CF$UID"]]
assert isinstance(root, dict) and "$class" in root, root
classes = objs[root["$class"]["CF$UID"]]
assert classes["$classname"] == "NSMutableDictionary", classes
assert any(isinstance(o, dict) and o.get("$classname") == "Profile"
           for o in objs), "no Profile class entry"
print("ok   the archive is a keyed-archive property list with CF$UID refs")
PY
)"; then
    echo "$out"
else
    echo "FAIL keyed archive plist"; echo "$out"; fails=$((fails+1))
fi

# ---------- 4e. run loop, delayed performs and timers ----------
"$CC" -target "$TARGET" -fobjc-runtime=ios-18.0 -fno-objc-arc \
    -ffreestanding -O1 -I "$ROOT/frameworks" \
    -c "$ROOT/tests/runloop_test.m" -o "$T/runloop.o"
"$LD64" -arch x86_64 -platform_version $PLATFORM -e _main -o "$T/runloop" \
    "$T/runloop.o" \
    "$ROOT/runtime/System/Library/Frameworks/Foundation.framework/Foundation" \
    -undefined dynamic_lookup
out="$(DYLD_ROOT_PATH="$ROOT/runtime" "$RUN" "$T/runloop" 2>&1)"
check "runloop: mainthread=1" "$out" "NSThread reports the main thread"
check "runloop: perform now" "$out" \
    "performSelector:withObject: sends immediately"
check "runloop: idle=0 waited=1" "$out" \
    "runMode:beforeDate: waits for its deadline"
check "runloop: fired=1 timing=1" "$out" \
    "a delayed perform runs on the run loop"
check "runloop: tick 2" "$out" \
    "a repeating NSTimer fires and invalidates"
check "runloop: sleeping=1 cancelled=0" "$out" \
    "cancelled performs do not fire and sleeping waits"

# ---------- 4f. UIPasteboard crosses processes through the device ----------
"$CC" -target "$TARGET" -fobjc-runtime=ios-18.0 -fno-objc-arc \
    -ffreestanding -O1 -I "$ROOT/frameworks" \
    -c "$ROOT/tests/pasteboard_test.m" -o "$T/pasteboard.o"
"$LD64" -arch x86_64 -platform_version $PLATFORM -e _main \
    -o "$T/pasteboard" "$T/pasteboard.o" \
    "$ROOT/runtime/System/Library/Frameworks/UIKit.framework/UIKit" \
    "$ROOT/runtime/System/Library/Frameworks/Foundation.framework/Foundation" \
    -undefined dynamic_lookup
PB_SHARED="$T/pasteboard-shared"
rm -rf "$PB_SHARED"
mkdir -p "$PB_SHARED"
out="$(SIMULATOR_SHARED_RESOURCES_DIRECTORY="$PB_SHARED" \
    DYLD_ROOT_PATH="$ROOT/runtime" "$RUN" "$T/pasteboard" write 2>&1)"
check "[paste] wrote hello pasteboard change=1" "$out" \
    "one process writes the general pasteboard"
out="$(SIMULATOR_SHARED_RESOURCES_DIRECTORY="$PB_SHARED" \
    DYLD_ROOT_PATH="$ROOT/runtime" "$RUN" "$T/pasteboard" read 2>&1)"
check "[paste] read=hello pasteboard change=1 strings=1" "$out" \
    "a second process reads the same pasteboard string"
if out="$(python3 - "$PB_SHARED/var/run/pasteboard.plist" <<'PY'
import plistlib, sys
with open(sys.argv[1], "rb") as f:
    d = plistlib.load(f)
assert d["changeCount"] == 1, d
assert d["items"][0]["public.utf8-plain-text"] == "hello pasteboard", d
print("ok   the pasteboard is a device-level XML property list")
PY
)"; then
    echo "$out"
else
    echo "FAIL pasteboard plist"; echo "$out"; fails=$((fails+1))
fi
out="$(SIMULATOR_SHARED_RESOURCES_DIRECTORY="$PB_SHARED" \
    DYLD_ROOT_PATH="$ROOT/runtime" "$RUN" "$T/pasteboard" write-data 2>&1)"
check "[paste] wrote-data len=3 change=2" "$out" \
    "pasteboard data replaces the contents and bumps changeCount"
out="$(SIMULATOR_SHARED_RESOURCES_DIRECTORY="$PB_SHARED" \
    DYLD_ROOT_PATH="$ROOT/runtime" "$RUN" "$T/pasteboard" read-data 2>&1)"
check "[paste] data=3/1 change=2" "$out" \
    "a second process reads the typed pasteboard data"

# ---------- 4g. NSCalendar components ----------
"$CC" -target "$TARGET" -fobjc-runtime=ios-18.0 -fno-objc-arc \
    -ffreestanding -O1 -I "$ROOT/frameworks" \
    -c "$ROOT/tests/calendar_test.m" -o "$T/calendar.o"
"$LD64" -arch x86_64 -platform_version $PLATFORM -e _main -o "$T/calendar" \
    "$T/calendar.o" \
    "$ROOT/runtime/System/Library/Frameworks/Foundation.framework/Foundation" \
    -undefined dynamic_lookup
out="$(DYLD_ROOT_PATH="$ROOT/runtime" "$RUN" "$T/calendar" 2>&1)"
check "[cal] epoch 1970-01-01 00:00:00 wd=5" "$out" \
    "NSCalendar decomposes the Unix epoch with its weekday"
check "[cal] back 2024-02-29 12:34:56 wd=5 epoch=1709210096" "$out" \
    "NSDateComponents builds a leap-day date and round-trips"
check "[cal] id=NSCalendarIdentifierGregorian" "$out" \
    "the current calendar reports its identifier"

# ---------- 4h. NSOperationQueue block operations ----------
"$CC" -target "$TARGET" -fobjc-runtime=ios-18.0 -fno-objc-arc -fblocks \
    -ffreestanding -O1 -I "$ROOT/frameworks" \
    -c "$ROOT/tests/operation_test.m" -o "$T/operation.o"
"$LD64" -arch x86_64 -platform_version $PLATFORM -e _main -o "$T/operation" \
    "$T/operation.o" \
    "$ROOT/runtime/System/Library/Frameworks/Foundation.framework/Foundation" \
    -undefined dynamic_lookup
out="$(DYLD_ROOT_PATH="$ROOT/runtime" "$RUN" "$T/operation" 2>&1)"
check "[op] block 0" "$out" "the first block operation ran"
check "[op] block 1" "$out" "the second block operation ran"
check "[op] block 2" "$out" "the third block operation ran"
check "[op] multi one" "$out" "NSBlockOperation runs its first block"
check "[op] multi two" "$out" "addExecutionBlock: appends a second block"
check "[op] completion" "$out" "the operation's completion block runs"
check "[op] blocks=3 pending=0 max=-1" "$out" \
    "waitUntilAllOperationsAreFinished joins every operation"

# ---------- 4i. NSNotification userInfo and block observers ----------
"$CC" -target "$TARGET" -fobjc-runtime=ios-18.0 -fno-objc-arc -fblocks \
    -ffreestanding -O1 -I "$ROOT/frameworks" \
    -c "$ROOT/tests/notification_test.m" -o "$T/notification.o"
"$LD64" -arch x86_64 -platform_version $PLATFORM -e _main \
    -o "$T/notification" "$T/notification.o" \
    "$ROOT/runtime/System/Library/Frameworks/Foundation.framework/Foundation" \
    -undefined dynamic_lookup
out="$(DYLD_ROOT_PATH="$ROOT/runtime" "$RUN" "$T/notification" 2>&1)"
check "notify selector TestNote user=v" "$out" \
    "selector observers receive a notification with userInfo"
check "notify block BlockNote user=v" "$out" \
    "block observers receive a notification with userInfo"
block_deliveries="$(printf '%s' "$out" | grep -c 'notify block BlockNote')"
if [ "$block_deliveries" -eq 1 ]; then
    echo "ok   removing the block observer token stops deliveries"
else
    echo "FAIL block observer removal (deliveries=$block_deliveries)"
    fails=$((fails+1))
fi
check "notify done" "$out" "NSNotificationCenter completes the post cycle"

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

# The booted SpringBoard launches the installed app from its icon and returns
# home when the system asks the app to background. UIKitApp is the second
# installed app: grid slot 8, row 2 column 0 (62.1667, 322.5 pt).
SBLOG="$IOSIM_HOME/Devices/$UDID/logs/springboard.log"
"$ROOT/tools/iosimctl" ui "$UDID" tap 62.1667 322.5 >/dev/null
sleep 1
if grep -q "launching UIKitApp" "$SBLOG" 2>/dev/null; then
    echo "ok   SpringBoard launches an installed app from its icon"
else
    echo "FAIL SpringBoard launch"; fails=$((fails+1))
fi
"$ROOT/tools/iosimctl" ui "$UDID" home >/dev/null
sleep 1
if grep -q "backgrounded by the system" "$SBLOG" 2>/dev/null; then
    echo "ok   home background the app and returns to the home screen"
else
    echo "FAIL SpringBoard home"; fails=$((fails+1))
fi

# ---------- 7. UITouch delivery and control tracking ----------
wait_log() {
    needle="$1"
    i=0
    while [ "$i" -lt 50 ]; do
        if grep -Fq -- "$needle" "$SBLOG" 2>/dev/null; then
            return 0
        fi
        sleep 0.1
        i=$((i+1))
    done
    return 1
}
"$ROOT/tools/build_app.sh" "$ROOT/demo/TouchApp.m" "$T/TouchApp" >/dev/null
mkdir -p "$T/TouchApp.app"
cp "$T/TouchApp" "$T/TouchApp.app/TouchApp"
python3 - "$T/TouchApp.app/Info.plist" <<'PY'
import plistlib, sys
with open(sys.argv[1], "wb") as f:
    plistlib.dump({
        "CFBundleIdentifier": "com.iosim.touch",
        "CFBundleExecutable": "TouchApp",
        "CFBundleName": "TouchApp",
        "CFBundlePackageType": "APPL",
        "CFBundleVersion": "1",
        "CFBundleShortVersionString": "1.0",
    }, f)
PY
"$ROOT/tools/iosimctl" install "$UDID" "$T/TouchApp.app" >/dev/null
sleep 0.5
# Third installed app: grid slot 9, row 2 column 1.
"$ROOT/tools/iosimctl" ui "$UDID" tap 154.7222 322.5 >/dev/null
if wait_log "[touch] app ready"; then
    echo "ok   SpringBoard launches the touch fixture"
else
    echo "FAIL touch fixture launch"; fails=$((fails+1))
fi
# Idle gaps between the events prove the stream stays open while the last
# writer (the iosimctl process) has exited.
"$ROOT/tools/iosimctl" ui "$UDID" down 60 300 >/dev/null
sleep 0.4
"$ROOT/tools/iosimctl" ui "$UDID" move 120 320 >/dev/null
sleep 0.4
"$ROOT/tools/iosimctl" ui "$UDID" up 200 300 >/dev/null
sleep 0.3
"$ROOT/tools/iosimctl" ui "$UDID" down 40 525 >/dev/null
"$ROOT/tools/iosimctl" ui "$UDID" move 360 525 >/dev/null
"$ROOT/tools/iosimctl" ui "$UDID" up 360 525 >/dev/null
"$ROOT/tools/iosimctl" ui "$UDID" tap 55 614 >/dev/null
"$ROOT/tools/iosimctl" ui "$UDID" tap 200 758 >/dev/null
sleep 0.5
out="$(cat "$SBLOG")"
check "[touch] began 36.0 104.0" "$out" \
    "touch down hit-tests and reports view-local coordinates"
check "[touch] moved 96.0 124.0" "$out" "touch move tracks the finger"
check "[touch] ended 176.0 104.0" "$out" "touch up ends the sequence"
check "[slider] 1.000" "$out" "slider tracks a drag to its maximum"
check "[switch] 1" "$out" "switch toggles on touch up inside"
check "[button] pressed" "$out" \
    "button target/action fires from the touch pipeline"

# ---------- 7b. backgrounded apps suspend and resume in place ----------
"$ROOT/tools/iosimctl" ui "$UDID" home >/dev/null
if wait_log "[UIKit-lite] backgrounded by the system; suspending"; then
    echo "ok   home suspends the foreground app"
else
    echo "FAIL app suspension"; fails=$((fails+1))
fi
sleep 0.5
# Tapping the same icon continues the same process (grid slot 9).
"$ROOT/tools/iosimctl" ui "$UDID" tap 154.7222 322.5 >/dev/null
if wait_log "resuming TouchApp"; then
    echo "ok   SpringBoard resumes the suspended app process"
else
    echo "FAIL app resume"; fails=$((fails+1))
fi
if wait_log "[UIKit-lite] resumed from suspension"; then
    echo "ok   the app continues from sceneWillEnterForeground"
else
    echo "FAIL resume lifecycle"; fails=$((fails+1))
fi
ready_count="$(grep -Fc "[touch] app ready" "$SBLOG" 2>/dev/null || true)"
if [ "$ready_count" -eq 1 ]; then
    echo "ok   no relaunch: viewDidLoad ran once across suspend/resume"
else
    echo "FAIL state preservation (app ready count=$ready_count)"
    fails=$((fails+1))
fi

# ---------- 7c. app switcher: real snapshot, real resume ----------
"$ROOT/tools/iosimctl" ui "$UDID" home >/dev/null
sleep 0.6
swc_before="$(grep -Fc "[SpringBoard] app switcher opened" "$SBLOG" 2>/dev/null || true)"
"$ROOT/tools/iosimctl" ui "$UDID" switcher >/dev/null
swc_now="$swc_before"
i=0
while [ "$i" -lt 50 ]; do
    swc_now="$(grep -Fc "[SpringBoard] app switcher opened" "$SBLOG" 2>/dev/null || true)"
    [ "$swc_now" -gt "$swc_before" ] && break
    sleep 0.1
    i=$((i+1))
done
# Previous apps stay suspended, so the card count is not a fixed number; the
# switcher must open and report the apps it is holding suspended.
if [ "$swc_now" -gt "$swc_before" ] &&
    grep -Eq 'app switcher opened \([1-9][0-9]* suspended\)' "$SBLOG"; then
    echo "ok   app switcher lists the suspended app"
else
    echo "FAIL app switcher ($swc_before -> $swc_now)"; fails=$((fails+1))
fi
SWITCHPIC="$IOSIM_HOME/Devices/$UDID/data/var/run/switcher/com.iosim.touch.png"
if out="$(python3 - "$SWITCHPIC" <<'PY'
import struct, sys
data = open(sys.argv[1], "rb").read()
assert data[:8] == b"\x89PNG\r\n\x1a\n", "not a PNG"
w, h = struct.unpack(">II", data[16:24])
assert (w, h) == (1206, 2622), (w, h)
print("ok   the suspended app's last frame is cached as a switcher snapshot")
PY
)"; then
    echo "$out"
else
    echo "FAIL switcher snapshot"; echo "$out"; fails=$((fails+1))
fi
resumed_before="$(grep -Fc "[UIKit-lite] resumed from suspension" "$SBLOG" 2>/dev/null || true)"
"$ROOT/tools/iosimctl" ui "$UDID" tap 201 400 >/dev/null
if wait_log "switcher selected TouchApp"; then
    echo "ok   tapping a switcher card selects the suspended app"
else
    echo "FAIL switcher selection"; fails=$((fails+1))
fi
sleep 0.6
resumed_after="$(grep -Fc "[UIKit-lite] resumed from suspension" "$SBLOG" 2>/dev/null || true)"
if [ "$resumed_after" -gt "$resumed_before" ]; then
    echo "ok   the switcher card resumes the same suspended process"
else
    echo "FAIL switcher resume ($resumed_before -> $resumed_after)"
    fails=$((fails+1))
fi

# ---------- 7d. in-app bottom-edge swipe hands the switcher to SpringBoard ----------
# While an app is foreground, a swipe up from the bottom edge must background
# the app (SIGSTOP) and ask SpringBoard to show the switcher, with no separate
# `ui switcher` command involved.
sleep 0.4
opened_before="$(grep -Fc "[SpringBoard] app switcher opened" "$SBLOG" 2>/dev/null || true)"
"$ROOT/tools/iosimctl" ui "$UDID" swipe 201 860 201 400 0.25 >/dev/null
opened_now="$opened_before"
i=0
while [ "$i" -lt 50 ]; do
    opened_now="$(grep -Fc "[SpringBoard] app switcher opened" "$SBLOG" 2>/dev/null || true)"
    [ "$opened_now" -gt "$opened_before" ] && break
    sleep 0.1
    i=$((i+1))
done
opened_last="$(grep -F "[SpringBoard] app switcher opened" "$SBLOG" 2>/dev/null | tail -1)"
if [ "$opened_now" -gt "$opened_before" ] &&
    printf '%s\n' "$opened_last" | grep -Eq '\([1-9][0-9]* suspended\)'; then
    echo "ok   an in-app bottom-edge swipe suspends and opens the switcher"
else
    echo "FAIL in-app switcher gesture ($opened_before -> $opened_now)"
    fails=$((fails+1))
fi
resume_before="$(grep -Fc "[SpringBoard] resuming TouchApp" "$SBLOG" 2>/dev/null || true)"
"$ROOT/tools/iosimctl" ui "$UDID" tap 201 400 >/dev/null
i=0
while [ "$i" -lt 50 ]; do
    resume_now="$(grep -Fc "[SpringBoard] resuming TouchApp" "$SBLOG" 2>/dev/null || true)"
    [ "$resume_now" -gt "$resume_before" ] && break
    sleep 0.1
    i=$((i+1))
done
if [ "$resume_now" -gt "$resume_before" ]; then
    echo "ok   the card opened by the in-app gesture resumes the app"
else
    echo "FAIL in-app switcher resume ($resume_before -> $resume_now)"
    fails=$((fails+1))
fi
sleep 0.4

# ---------- 7e. the switcher's swipe-up force-quits a suspended app ----------
"$ROOT/tools/iosimctl" ui "$UDID" home >/dev/null
sleep 0.6
sw_before="$(grep -Fc "[SpringBoard] app switcher opened" "$SBLOG" 2>/dev/null || true)"
"$ROOT/tools/iosimctl" ui "$UDID" switcher >/dev/null
sw_now="$sw_before"
i=0
while [ "$i" -lt 50 ]; do
    sw_now="$(grep -Fc "[SpringBoard] app switcher opened" "$SBLOG" 2>/dev/null || true)"
    [ "$sw_now" -gt "$sw_before" ] && break
    sleep 0.1
    i=$((i+1))
done
"$ROOT/tools/iosimctl" ui "$UDID" swipe 201 400 201 180 0.25 >/dev/null
if wait_log "closed TouchApp (pid"; then
    echo "ok   swiping up on a switcher card closes the app"
else
    echo "FAIL switcher kill gesture"; fails=$((fails+1))
fi
sleep 0.3
closed_pid="$(sed -n 's/.*closed TouchApp (pid \([0-9][0-9]*\)).*/\1/p' "$SBLOG" 2>/dev/null | tail -1)"
if [ -n "$closed_pid" ] && ! kill -0 "$closed_pid" 2>/dev/null; then
    echo "ok   the closed app's process is terminated and reaped"
else
    echo "FAIL switcher termination (pid=$closed_pid)"; fails=$((fails+1))
fi
# The switcher stays open on the remaining suspended app's card after the
# kill, so return home before tapping the home-screen icon.
"$ROOT/tools/iosimctl" ui "$UDID" home >/dev/null
sleep 0.5
launch_before="$(grep -Fc "[SpringBoard] launching TouchApp" "$SBLOG" 2>/dev/null || true)"
"$ROOT/tools/iosimctl" ui "$UDID" tap 154.7222 322.5 >/dev/null
launch_now="$launch_before"
i=0
while [ "$i" -lt 50 ]; do
    launch_now="$(grep -Fc "[SpringBoard] launching TouchApp" "$SBLOG" 2>/dev/null || true)"
    [ "$launch_now" -gt "$launch_before" ] && break
    sleep 0.1
    i=$((i+1))
done
if [ "$launch_now" -gt "$launch_before" ]; then
    echo "ok   tapping the icon starts a fresh process after the kill"
else
    echo "FAIL relaunch after kill"; fails=$((fails+1))
fi
sleep 0.5

# ---------- 8. display link, animation timeline and presentation values ----------
"$ROOT/tools/iosimctl" ui "$UDID" home >/dev/null
sleep 0.8
"$ROOT/tools/build_app.sh" "$ROOT/demo/AnimationApp.m" "$T/AnimationApp" >/dev/null
mkdir -p "$T/AnimationApp.app"
cp "$T/AnimationApp" "$T/AnimationApp.app/AnimationApp"
python3 - "$T/AnimationApp.app/Info.plist" <<'PY'
import plistlib, sys
with open(sys.argv[1], "wb") as f:
    plistlib.dump({
        "CFBundleIdentifier": "com.iosim.animation",
        "CFBundleExecutable": "AnimationApp",
        "CFBundleName": "Animation",
        "CFBundlePackageType": "APPL",
        "CFBundleVersion": "1",
        "CFBundleShortVersionString": "1.0",
    }, f)
PY
"$ROOT/tools/iosimctl" install "$UDID" "$T/AnimationApp.app" >/dev/null
sleep 0.5
# Fourth installed app: grid slot 10, row 2 column 2.
"$ROOT/tools/iosimctl" ui "$UDID" tap 247.2778 322.5 >/dev/null
if wait_log "[anim] app ready"; then
    echo "ok   SpringBoard launches the animation fixture"
else
    echo "FAIL animation fixture launch"; fails=$((fails+1))
fi
"$ROOT/tools/iosimctl" ui "$UDID" tap 200 628 >/dev/null
sleep 0.5
"$ROOT/tools/iosimctl" io "$UDID" screenshot "$T/anim-mid.png" >/dev/null
sleep 2.0
"$ROOT/tools/iosimctl" io "$UDID" screenshot "$T/anim-end.png" >/dev/null
if wait_log "[anim] completed 1"; then
    echo "ok   UIView animation completion fires with finished=YES"
else
    echo "FAIL animation completion"; fails=$((fails+1))
fi
if out="$(python3 - "$SBLOG" <<'PY'
import sys
present = []
dots = []
for line in open(sys.argv[1], errors='replace'):
    if line.startswith('[anim] present '):
        present.append(float(line.split()[2]))
    elif line.startswith('[anim] dot '):
        dots.append(float(line.split()[2]))
if not any(305.0 < v < 465.0 for v in present):
    raise SystemExit('no in-flight presentation frame: %r' % present)
# The keyframe bottoms out at 0.4; a sample may print exactly 0.4.
if not any(v < 0.45 for v in dots):
    raise SystemExit('no keyframe opacity sample: %r' % dots)
print('ok   presentation layer interpolates frame and keyframe opacity')
PY
)"; then
    echo "$out"
else
    echo "FAIL presentation values"; echo "$out"; fails=$((fails+1))
fi
if out="$(python3 - "$SBLOG" <<'PY'
import sys
tracks = []
for line in open(sys.argv[1], errors='replace'):
    if line.startswith('[anim] tracks '):
        parts = line.split()
        tracks.append((float(parts[2]), float(parts[3])))
if not tracks:
    raise SystemExit('no concurrent track samples')
if not any(o < 0.90 and r > 12.4 for o, r in tracks):
    raise SystemExit('tracks never advanced together: %r' % tracks[:8])
if not any(r > 15.0 for o, r in tracks):
    raise SystemExit('corner radius track did not advance: %r' % tracks[:8])
print('ok   opacity and corner radius animate on one layer at the same time')
PY
)"; then
    echo "$out"
else
    echo "FAIL multiple layer animations"; echo "$out"; fails=$((fails+1))
fi
if out="$(python3 - "$ROOT/tools" "$T/anim-mid.png" "$T/anim-end.png" <<'PY'
import sys
sys.path.insert(0, sys.argv[1])
import pngpixel

def blue(c):
    r, g, b = (c >> 16) & 255, (c >> 8) & 255, c & 255
    return b > 150 and b > r + 60 and g > 60

def settled(c):
    # The completed animation leaves the box at 15% alpha over the
    # background: a dim navy rather than the background itself.
    r, g, b = (c >> 16) & 255, (c >> 8) & 255, c & 255
    return r < 40 and g > 25 and b > 50

def box_top(path, pred):
    w, h, bpp, rows = pngpixel.load(path)
    for y in range(280 * 3, 600 * 3):
        if pred(pngpixel.px(rows, bpp, 603, y)):
            return y / 3.0
    return None

mid = box_top(sys.argv[2], blue)
end = box_top(sys.argv[3], settled)
if mid is None or end is None:
    raise SystemExit('box missing (mid=%r end=%r)' % (mid, end))
if not (300.0 <= mid <= 455.0):
    raise SystemExit('mid frame box not in flight: %.1f' % mid)
if not (465.0 <= end <= 475.0):
    raise SystemExit('end frame box not settled: %.1f' % end)
w, h, bpp, rows = pngpixel.load(sys.argv[3])
dot = False
for y in range(740 * 3, 790 * 3, 3):
    for x in range(0, w, 3):
        c = pngpixel.px(rows, bpp, x, y)
        r, g, b = (c >> 16) & 255, (c >> 8) & 255, c & 255
        if g > 150 and g > r * 1.5 and g > b * 1.3:
            dot = True
            break
    if dot:
        break
if not dot:
    raise SystemExit('display-link dot missing from the end frame')
print('ok   framebuffer shows the in-flight box and the display-link dot')
PY
)"; then
    echo "$out"
else
    echo "FAIL animated frames"; echo "$out"; fails=$((fails+1))
fi

# ---------- 9. home-screen pages ----------
"$ROOT/tools/iosimctl" ui "$UDID" home >/dev/null
sleep 0.7
for i in 1 2 3 4 5 6 7 8 9 10; do
    d="$T/Page$i.app"
    rm -rf "$d"
    mkdir -p "$d"
    cp "$T/hello" "$d/Page$i"
    python3 - "$d/Info.plist" "$i" <<'PY'
import plistlib, sys
i = sys.argv[2]
with open(sys.argv[1], "wb") as f:
    plistlib.dump({
        "CFBundleIdentifier": "com.iosim.page%s" % i,
        "CFBundleExecutable": "Page%s" % i,
        "CFBundleName": "Page%s" % i,
        "CFBundlePackageType": "APPL",
        "CFBundleVersion": "1",
        "CFBundleShortVersionString": "1.0",
    }, f)
PY
    "$ROOT/tools/iosimctl" install "$UDID" "$d" >/dev/null
done
sleep 0.5
"$ROOT/tools/iosimctl" io "$UDID" screenshot "$T/page1.png" >/dev/null
"$ROOT/tools/iosimctl" ui "$UDID" swipe 350 400 50 400 0.3 >/dev/null
if wait_log "home page 2 of 2"; then
    echo "ok   horizontal swipe moves to the second home page"
else
    echo "FAIL home page swipe"; fails=$((fails+1))
fi
sleep 0.4
"$ROOT/tools/iosimctl" io "$UDID" screenshot "$T/page2.png" >/dev/null
if out="$(python3 - "$ROOT/tools" "$T/page1.png" "$T/page2.png" <<'PY'
import sys
sys.path.insert(0, sys.argv[1])
import pngpixel

def dot(path, x):
    w, h, bpp, rows = pngpixel.load(path)
    return pngpixel.px(rows, bpp, x * 3, 686 * 3)

white = lambda c: (c >> 16) & 255 > 230 and (c >> 8) & 255 > 230 and \
    (c & 255) > 230
gray = lambda c: 100 < ((c >> 16) & 255) < 180 and \
    100 < ((c >> 8) & 255) < 180 and 100 < (c & 255) < 180
first1, second1 = dot(sys.argv[2], 193), dot(sys.argv[2], 209)
first2, second2 = dot(sys.argv[3], 193), dot(sys.argv[3], 209)
if not (white(first1) and gray(second1)):
    raise SystemExit('page 1 dots wrong: %06x %06x' % (first1, second1))
if not (gray(first2) and white(second2)):
    raise SystemExit('page 2 dots wrong: %06x %06x' % (first2, second2))
print('ok   page dots mark the active home page')
PY
)"; then
    echo "$out"
else
    echo "FAIL page dots"; echo "$out"; fails=$((fails+1))
fi
# With four apps installed before the ten page fixtures, page 2 starts at
# Page6 (grid slot 16), top-left.
"$ROOT/tools/iosimctl" ui "$UDID" tap 62.1667 121.8333 >/dev/null
if wait_log "launching Page6"; then
    echo "ok   tapping a second-page icon launches that app"
else
    echo "FAIL second-page launch"; fails=$((fails+1))
fi
"$ROOT/tools/iosimctl" ui "$UDID" swipe 50 400 350 400 0.3 >/dev/null
if wait_log "home page 1 of 2"; then
    echo "ok   swiping back returns to the first page"
else
    echo "FAIL page back-swipe"; fails=$((fails+1))
fi

# ---------- 9b. app bundle resources ----------
"$ROOT/tools/build_app.sh" "$ROOT/demo/ResourceApp.m" "$T/ResourceApp" >/dev/null
mkdir -p "$T/ResourceApp.app"
cp "$T/ResourceApp" "$T/ResourceApp.app/ResourceApp"
python3 - "$T/ResourceApp.app/dot.png" <<'PY'
import struct, sys, zlib
w = h = 4
raw = b"".join(b"\x00" + b"\xff\x00\x00\xff" * w for _ in range(h))
def chunk(tag, data):
    return struct.pack(">I", len(data)) + tag + data + \
        struct.pack(">I", zlib.crc32(tag + data) & 0xffffffff)
png = b"\x89PNG\r\n\x1a\n" + \
    chunk(b"IHDR", struct.pack(">IIBBBBB", w, h, 8, 6, 0, 0, 0)) + \
    chunk(b"IDAT", zlib.compress(raw)) + chunk(b"IEND", b"")
with open(sys.argv[1], "wb") as f:
    f.write(png)
PY
printf 'bundle resource' > "$T/ResourceApp.app/note.txt"
python3 - "$T/ResourceApp.app/Info.plist" <<'PY'
import plistlib, sys
with open(sys.argv[1], "wb") as f:
    plistlib.dump({
        "CFBundleIdentifier": "com.iosim.resource",
        "CFBundleExecutable": "ResourceApp",
        "CFBundleName": "Resource",
        "CFBundlePackageType": "APPL",
        "CFBundleVersion": "1",
        "CFBundleShortVersionString": "1.0",
    }, f)
PY
"$ROOT/tools/iosimctl" install "$UDID" "$T/ResourceApp.app" >/dev/null
sleep 0.5
# Fifteenth installed app: grid slot 21, second page row 1 column 1.
"$ROOT/tools/iosimctl" ui "$UDID" swipe 350 400 50 400 0.3 >/dev/null
sleep 0.4
"$ROOT/tools/iosimctl" ui "$UDID" tap 154.7222 222.1667 >/dev/null
if wait_log "[res] app ready"; then
    echo "ok   SpringBoard launches the resource fixture"
else
    echo "FAIL resource fixture launch"; fails=$((fails+1))
fi
sleep 0.4
out="$(cat "$SBLOG")"
check "[res] image 4 4" "$out" \
    "UIImage imageNamed: loads a PNG from the app bundle"
check "[res] note bundle resource" "$out" \
    "NSBundle pathForResource: finds a bundle file"
"$ROOT/tools/iosimctl" io "$UDID" screenshot "$T/res.png" >/dev/null
if out="$(python3 - "$ROOT/tools" "$T/res.png" <<'PY'
import sys
sys.path.insert(0, sys.argv[1])
import pngpixel
w, h, bpp, rows = pngpixel.load(sys.argv[2])
c = pngpixel.px(rows, bpp, 150 * 3, 350 * 3)
r, g, b = (c >> 16) & 255, (c >> 8) & 255, c & 255
if not (r > 200 and g < 80 and b < 80):
    raise SystemExit("expected the red bundle image, got %06x" % c)
print("ok   the bundle PNG renders through UIImageView")
PY
)"; then
    echo "$out"
else
    echo "FAIL bundle image render"; echo "$out"; fails=$((fails+1))
fi
"$ROOT/tools/iosimctl" ui "$UDID" home >/dev/null
sleep 0.4

# ---------- 9c. UITabBarController ----------
"$ROOT/tools/build_app.sh" "$ROOT/demo/TabApp.m" "$T/TabApp" >/dev/null
mkdir -p "$T/TabApp.app"
cp "$T/TabApp" "$T/TabApp.app/TabApp"
python3 - "$T/TabApp.app/Info.plist" <<'PY'
import plistlib, sys
with open(sys.argv[1], "wb") as f:
    plistlib.dump({
        "CFBundleIdentifier": "com.iosim.tab",
        "CFBundleExecutable": "TabApp",
        "CFBundleName": "Tab",
        "CFBundlePackageType": "APPL",
        "CFBundleVersion": "1",
        "CFBundleShortVersionString": "1.0",
    }, f)
PY
"$ROOT/tools/iosimctl" install "$UDID" "$T/TabApp.app" >/dev/null
sleep 0.5
# Sixteenth installed app: grid slot 22, second page row 1 column 2.
"$ROOT/tools/iosimctl" ui "$UDID" tap 247.2778 222.1667 >/dev/null
if wait_log "[tab] ready count=2 selected=0"; then
    echo "ok   a tab bar controller installs two view controllers"
else
    echo "FAIL tab controller launch"; fails=$((fails+1))
fi
sleep 0.4
"$ROOT/tools/iosimctl" io "$UDID" screenshot "$T/tab-before.png" >/dev/null
"$ROOT/tools/iosimctl" ui "$UDID" tap 293.5 796 >/dev/null
if wait_log "[tab] selected 1"; then
    echo "ok   tapping the second tab selects it"
else
    echo "FAIL tab selection"; fails=$((fails+1))
fi
sleep 0.4
"$ROOT/tools/iosimctl" io "$UDID" screenshot "$T/tab-after.png" >/dev/null
"$ROOT/tools/iosimctl" ui "$UDID" tap 108.5 796 >/dev/null
if wait_log "[tab] selected 0"; then
    echo "ok   tapping the first tab switches back"
else
    echo "FAIL tab reselection"; fails=$((fails+1))
fi
if out="$(python3 - "$ROOT/tools" "$T/tab-before.png" "$T/tab-after.png" <<'PY'
import sys
sys.path.insert(0, sys.argv[1])
import pngpixel

def px(path, x, y):
    w, h, bpp, rows = pngpixel.load(path)
    return pngpixel.px(rows, bpp, x * 3, y * 3)

for path, want in ((sys.argv[2], "red"), (sys.argv[3], "green")):
    c = px(path, 201, 300)
    r, g, b = (c >> 16) & 255, (c >> 8) & 255, c & 255
    if want == "red" and not (r > 180 and g < 100 and b < 100):
        raise SystemExit("expected red tab content, got %06x" % c)
    if want == "green" and not (g > 170 and r < 100):
        raise SystemExit("expected green tab content, got %06x" % c)
    c = px(path, 201, 796)
    if ((c >> 16) & 255) >= 80:
        raise SystemExit("tab bar not drawn over the content: %06x" % c)
print("ok   the selected tab's view fills the screen under the floating bar")
PY
)"; then
    echo "$out"
else
    echo "FAIL tab content"; echo "$out"; fails=$((fails+1))
fi
"$ROOT/tools/iosimctl" ui "$UDID" home >/dev/null
sleep 0.4

# ---------- 9d. UITextView multiline editing and hardware keys ----------
"$ROOT/tools/build_app.sh" "$ROOT/demo/TextViewApp.m" "$T/TextViewApp" >/dev/null
mkdir -p "$T/TextViewApp.app"
cp "$T/TextViewApp" "$T/TextViewApp.app/TextViewApp"
python3 - "$T/TextViewApp.app/Info.plist" <<'PY'
import plistlib, sys
with open(sys.argv[1], "wb") as f:
    plistlib.dump({
        "CFBundleIdentifier": "com.iosim.textview",
        "CFBundleExecutable": "TextViewApp",
        "CFBundleName": "TextView",
        "CFBundlePackageType": "APPL",
        "CFBundleVersion": "1",
        "CFBundleShortVersionString": "1.0",
    }, f)
PY
"$ROOT/tools/iosimctl" install "$UDID" "$T/TextViewApp.app" >/dev/null
sleep 0.5
# Seventeenth installed app: grid slot 23, second page row 1 column 3.
"$ROOT/tools/iosimctl" ui "$UDID" tap 339.8333 222.1667 >/dev/null
if wait_log "[textview] ready"; then
    echo "ok   SpringBoard launches the text view fixture"
else
    echo "FAIL text view launch"; fails=$((fails+1))
fi
"$ROOT/tools/iosimctl" ui "$UDID" tap 200 300 >/dev/null
sleep 0.3
"$ROOT/tools/iosimctl" io "$UDID" screenshot "$T/tv-focused.png" >/dev/null
if out="$(python3 - "$ROOT/tools" "$T/tv-focused.png" <<'PY'
import sys
sys.path.insert(0, sys.argv[1])
import pngpixel
w, h, bpp, rows = pngpixel.load(sys.argv[2])
c = pngpixel.px(rows, bpp, 23 * 3, 620 * 3)
r, g, b = (c >> 16) & 255, (c >> 8) & 255, c & 255
if not (50 <= r <= 100 and abs(r - g) < 12 and abs(g - b) < 12):
    raise SystemExit("software keyboard not visible: %06x" % c)
print("ok   focusing the text view raises the software keyboard")
PY
)"; then
    echo "$out"
else
    echo "FAIL text view keyboard"; echo "$out"; fails=$((fails+1))
fi
"$ROOT/tools/iosimctl" ui "$UDID" key a >/dev/null
"$ROOT/tools/iosimctl" ui "$UDID" key b >/dev/null
"$ROOT/tools/iosimctl" ui "$UDID" key return >/dev/null
"$ROOT/tools/iosimctl" ui "$UDID" key c >/dev/null
if wait_log "[textview] lines=2 text=ab|c"; then
    echo "ok   hardware keys append and return starts a new line"
else
    echo "FAIL text view newline"; fails=$((fails+1))
fi
"$ROOT/tools/iosimctl" ui "$UDID" backspace >/dev/null
"$ROOT/tools/iosimctl" ui "$UDID" key d >/dev/null
if wait_log "[textview] lines=2 text=ab|d"; then
    echo "ok   backspace deletes and typing continues"
else
    echo "FAIL text view backspace"; fails=$((fails+1))
fi
"$ROOT/tools/iosimctl" ui "$UDID" home >/dev/null
sleep 0.4

# ---------- 9e. UICollectionView flow layout ----------
"$ROOT/tools/build_app.sh" "$ROOT/demo/CollectionApp.m" "$T/CollectionApp" >/dev/null
mkdir -p "$T/CollectionApp.app"
cp "$T/CollectionApp" "$T/CollectionApp.app/CollectionApp"
python3 - "$T/CollectionApp.app/Info.plist" <<'PY'
import plistlib, sys
with open(sys.argv[1], "wb") as f:
    plistlib.dump({
        "CFBundleIdentifier": "com.iosim.collection",
        "CFBundleExecutable": "CollectionApp",
        "CFBundleName": "Collection",
        "CFBundlePackageType": "APPL",
        "CFBundleVersion": "1",
        "CFBundleShortVersionString": "1.0",
    }, f)
PY
"$ROOT/tools/iosimctl" install "$UDID" "$T/CollectionApp.app" >/dev/null
sleep 0.5
# Eighteenth installed app: grid slot 24, second page row 2 column 0.
"$ROOT/tools/iosimctl" ui "$UDID" tap 62.1667 322.5 >/dev/null
if wait_log "[collection] ready"; then
    echo "ok   SpringBoard launches the collection view fixture"
else
    echo "FAIL collection fixture launch"; fails=$((fails+1))
fi
"$ROOT/tools/iosimctl" io "$UDID" screenshot "$T/collection.png" >/dev/null
if out="$(python3 - "$ROOT/tools" "$T/collection.png" <<'PY'
import sys
sys.path.insert(0, sys.argv[1])
import pngpixel
w, h, bpp, rows = pngpixel.load(sys.argv[2])
c = pngpixel.px(rows, bpp, 294 * 3, 262 * 3)
r, g, b = (c >> 16) & 255, (c >> 8) & 255, c & 255
if not (r > 200 and 120 < g < 200 and b < 90):
    raise SystemExit("collection cell not drawn: %06x" % c)
print("ok   the flow layout draws cells at the computed item frames")
PY
)"; then
    echo "$out"
else
    echo "FAIL collection rendering"; echo "$out"; fails=$((fails+1))
fi
"$ROOT/tools/iosimctl" ui "$UDID" tap 294 262 >/dev/null
if wait_log "[collection] selected 5"; then
    echo "ok   tapping a collection cell reports didSelectItemAtIndexPath"
else
    echo "FAIL collection selection"; fails=$((fails+1))
fi
"$ROOT/tools/iosimctl" ui "$UDID" swipe 200 500 200 250 0.4 >/dev/null
sleep 0.4
"$ROOT/tools/iosimctl" io "$UDID" screenshot "$T/collection-scrolled.png" >/dev/null
if out="$(python3 - "$ROOT/tools" "$T/collection-scrolled.png" <<'PY'
import sys
sys.path.insert(0, sys.argv[1])
import pngpixel
w, h, bpp, rows = pngpixel.load(sys.argv[2])
c = pngpixel.px(rows, bpp, 294 * 3, 262 * 3)
r, g, b = (c >> 16) & 255, (c >> 8) & 255, c & 255
if not (r < 100 and 100 < g < 190 and b > 190):
    raise SystemExit("collection did not scroll: %06x" % c)
print("ok   dragging scrolls the collection content by its offset")
PY
)"; then
    echo "$out"
else
    echo "FAIL collection scrolling"; echo "$out"; fails=$((fails+1))
fi
"$ROOT/tools/iosimctl" ui "$UDID" home >/dev/null
sleep 0.4

# ---------- 9f. Spotlight search over installed apps ----------
"$ROOT/tools/iosimctl" ui "$UDID" tap 201 718.5 >/dev/null
if wait_log "[SpringBoard] search opened"; then
    echo "ok   tapping the search pill opens Spotlight"
else
    echo "FAIL search open"; fails=$((fails+1))
fi
"$ROOT/tools/iosimctl" ui "$UDID" key t >/dev/null
"$ROOT/tools/iosimctl" ui "$UDID" key a >/dev/null
"$ROOT/tools/iosimctl" ui "$UDID" key b >/dev/null
if wait_log "[SpringBoard] search results 1"; then
    echo "ok   typing narrows the results to the matching app"
else
    echo "FAIL search filtering"; fails=$((fails+1))
fi
"$ROOT/tools/iosimctl" io "$UDID" screenshot "$T/search.png" >/dev/null
if out="$(python3 - "$ROOT/tools" "$T/search.png" <<'PY'
import sys
sys.path.insert(0, sys.argv[1])
import pngpixel
w, h, bpp, rows = pngpixel.load(sys.argv[2])
key = pngpixel.px(rows, bpp, 23 * 3, 620 * 3)
r, g, b = (key >> 16) & 255, (key >> 8) & 255, key & 255
if not (50 <= r <= 100 and abs(r - g) < 12 and abs(g - b) < 12):
    raise SystemExit("search keyboard not visible: %06x" % key)
row = pngpixel.px(rows, bpp, 201 * 3, 270 * 3)
r, g, b = (row >> 16) & 255, (row >> 8) & 255, row & 255
if not (r < 60 and b > 30):
    raise SystemExit("search result row not drawn: %06x" % row)
print("ok   Spotlight draws the result row and the software keyboard")
PY
)"; then
    echo "$out"
else
    echo "FAIL search rendering"; echo "$out"; fails=$((fails+1))
fi
"$ROOT/tools/iosimctl" ui "$UDID" tap 200 270 >/dev/null
if wait_log "[SpringBoard] search selected Tab"; then
    echo "ok   tapping a search result selects that app"
else
    echo "FAIL search selection"; fails=$((fails+1))
fi
if wait_log "resuming Tab (pid"; then
    echo "ok   the search result resumes the suspended app"
else
    echo "FAIL search resume"; fails=$((fails+1))
fi
"$ROOT/tools/iosimctl" ui "$UDID" home >/dev/null
sleep 0.4

# ---------- 9g. application and scene lifecycle callbacks ----------
"$ROOT/tools/build_app.sh" "$ROOT/demo/LifecycleApp.m" "$T/LifecycleApp" >/dev/null
mkdir -p "$T/LifecycleApp.app"
cp "$T/LifecycleApp" "$T/LifecycleApp.app/LifecycleApp"
python3 - "$T/LifecycleApp.app/Info.plist" <<'PY'
import plistlib, sys
with open(sys.argv[1], "wb") as f:
    plistlib.dump({
        "CFBundleIdentifier": "com.iosim.lifecycle",
        "CFBundleExecutable": "LifecycleApp",
        "CFBundleName": "Lifecycle",
        "CFBundlePackageType": "APPL",
        "CFBundleVersion": "1",
        "CFBundleShortVersionString": "1.0",
    }, f)
PY
"$ROOT/tools/iosimctl" install "$UDID" "$T/LifecycleApp.app" >/dev/null
sleep 0.5
# Settle on page 2 so the nineteenth icon's slot is visible.
"$ROOT/tools/iosimctl" ui "$UDID" swipe 50 400 350 400 0.3 >/dev/null
sleep 0.3
"$ROOT/tools/iosimctl" ui "$UDID" swipe 350 400 50 400 0.3 >/dev/null
sleep 0.4
# Nineteenth installed app: grid slot 25, second page row 2 column 1.
"$ROOT/tools/iosimctl" ui "$UDID" tap 154.7222 322.5 >/dev/null
if wait_log "[life] ready state=0"; then
    echo "ok   a cold launch reports an active application state"
else
    echo "FAIL lifecycle launch"; fails=$((fails+1))
fi
if wait_log "[life] active state=0"; then
    echo "ok   applicationDidBecomeActive runs after the scene connects"
else
    echo "FAIL lifecycle launch active"; fails=$((fails+1))
fi
sleep 0.3
active_before="$(grep -Fc "[life] active state=0" "$SBLOG" 2>/dev/null || true)"
"$ROOT/tools/iosimctl" ui "$UDID" home >/dev/null
if wait_log "[life] resign state=1" &&
    wait_log "[life] background state=2" &&
    wait_log "[life] scene background"; then
    echo "ok   backgrounding walks inactive, background, then the scene"
else
    echo "FAIL lifecycle background"; fails=$((fails+1))
fi
sleep 0.4
"$ROOT/tools/iosimctl" ui "$UDID" tap 154.7222 322.5 >/dev/null
if wait_log "[life] foreground state=1" &&
    wait_log "[life] scene foreground"; then
    echo "ok   resuming enters the foreground before reactivating"
else
    echo "FAIL lifecycle foreground"; fails=$((fails+1))
fi
active_now="$active_before"
i=0
while [ "$i" -lt 50 ]; do
    active_now="$(grep -Fc "[life] active state=0" "$SBLOG" 2>/dev/null || true)"
    [ "$active_now" -gt "$active_before" ] && break
    sleep 0.1
    i=$((i+1))
done
if [ "$active_now" -gt "$active_before" ]; then
    echo "ok   the resumed scene becomes active with the same process"
else
    echo "FAIL lifecycle resume active ($active_before -> $active_now)"
    fails=$((fails+1))
fi
ready_count="$(grep -Fc "[life] ready" "$SBLOG" 2>/dev/null || true)"
if [ "$ready_count" -eq 1 ]; then
    echo "ok   lifecycle: viewDidLoad ran once across suspend/resume"
else
    echo "FAIL lifecycle state preservation (ready=$ready_count)"
    fails=$((fails+1))
fi
"$ROOT/tools/iosimctl" ui "$UDID" home >/dev/null
sleep 0.4

# ---------- 9h. UITableView sections, headers and per-row heights ----------
"$ROOT/tools/build_app.sh" "$ROOT/demo/SectionApp.m" "$T/SectionApp" >/dev/null
mkdir -p "$T/SectionApp.app"
cp "$T/SectionApp" "$T/SectionApp.app/SectionApp"
python3 - "$T/SectionApp.app/Info.plist" <<'PY'
import plistlib, sys
with open(sys.argv[1], "wb") as f:
    plistlib.dump({
        "CFBundleIdentifier": "com.iosim.sections",
        "CFBundleExecutable": "SectionApp",
        "CFBundleName": "Sections",
        "CFBundlePackageType": "APPL",
        "CFBundleVersion": "1",
        "CFBundleShortVersionString": "1.0",
    }, f)
PY
"$ROOT/tools/iosimctl" install "$UDID" "$T/SectionApp.app" >/dev/null
sleep 0.5
# Twentieth installed app: grid slot 26, second page row 2 column 2.
"$ROOT/tools/iosimctl" ui "$UDID" tap 247.2778 322.5 >/dev/null
if wait_log "[section] ready rows=5"; then
    echo "ok   SpringBoard launches the sectioned table fixture"
else
    echo "FAIL section fixture launch"; fails=$((fails+1))
fi
"$ROOT/tools/iosimctl" io "$UDID" screenshot "$T/sections.png" >/dev/null
if out="$(python3 - "$ROOT/tools" "$T/sections.png" <<'PY'
import sys
sys.path.insert(0, sys.argv[1])
import pngpixel
w, h, bpp, rows = pngpixel.load(sys.argv[2])
c = pngpixel.px(rows, bpp, 200 * 3, 242 * 3)
r, g, b = (c >> 16) & 255, (c >> 8) & 255, c & 255
if not (40 < r < 90 and 20 < g < 60 and 70 < b < 120):
    raise SystemExit("section row not at its header offset: %06x" % c)
print("ok   section headers offset the rows below them")
PY
)"; then
    echo "$out"
else
    echo "FAIL section layout"; echo "$out"; fails=$((fails+1))
fi
"$ROOT/tools/iosimctl" ui "$UDID" tap 200 242 >/dev/null
if wait_log "[section] select 0:2 Cherry"; then
    echo "ok   tapping the third row maps through the header to 0:2"
else
    echo "FAIL section selection"; fails=$((fails+1))
fi
"$ROOT/tools/iosimctl" io "$UDID" screenshot "$T/sections-selected.png" >/dev/null
if out="$(python3 - "$ROOT/tools" "$T/sections-selected.png" <<'PY'
import sys
sys.path.insert(0, sys.argv[1])
import pngpixel
w, h, bpp, rows = pngpixel.load(sys.argv[2])
c = pngpixel.px(rows, bpp, 200 * 3, 242 * 3)
r, g, b = (c >> 16) & 255, (c >> 8) & 255, c & 255
if not (30 < r < 70 and abs(r - g) < 12 and abs(g - b) < 12):
    raise SystemExit("selected row not highlighted: %06x" % c)
print("ok   the selected row is drawn with the highlight color")
PY
)"; then
    echo "$out"
else
    echo "FAIL section highlight"; echo "$out"; fails=$((fails+1))
fi
"$ROOT/tools/iosimctl" ui "$UDID" tap 200 371 >/dev/null
if wait_log "[section] select 1:1 Pea"; then
    echo "ok   the second section's row heights resolve to 1:1"
else
    echo "FAIL second section selection"; fails=$((fails+1))
fi
"$ROOT/tools/iosimctl" io "$UDID" screenshot "$T/sections-second.png" >/dev/null
if out="$(python3 - "$ROOT/tools" "$T/sections-second.png" <<'PY'
import sys
sys.path.insert(0, sys.argv[1])
import pngpixel
w, h, bpp, rows = pngpixel.load(sys.argv[2])
c = pngpixel.px(rows, bpp, 200 * 3, 371 * 3)
r, g, b = (c >> 16) & 255, (c >> 8) & 255, c & 255
if not (30 < r < 70 and abs(r - g) < 12 and abs(g - b) < 12):
    raise SystemExit("second section row not highlighted: %06x" % c)
print("ok   the second section's selected row is highlighted too")
PY
)"; then
    echo "$out"
else
    echo "FAIL second section highlight"; echo "$out"; fails=$((fails+1))
fi
"$ROOT/tools/iosimctl" ui "$UDID" home >/dev/null
sleep 0.4

# ---------- 9i. long-press gesture recognizer ----------
"$ROOT/tools/build_app.sh" "$ROOT/demo/LongPressApp.m" "$T/LongPressApp" >/dev/null
mkdir -p "$T/LongPressApp.app"
cp "$T/LongPressApp" "$T/LongPressApp.app/LongPressApp"
python3 - "$T/LongPressApp.app/Info.plist" <<'PY'
import plistlib, sys
with open(sys.argv[1], "wb") as f:
    plistlib.dump({
        "CFBundleIdentifier": "com.iosim.longpress",
        "CFBundleExecutable": "LongPressApp",
        "CFBundleName": "LongPress",
        "CFBundlePackageType": "APPL",
        "CFBundleVersion": "1",
        "CFBundleShortVersionString": "1.0",
    }, f)
PY
"$ROOT/tools/iosimctl" install "$UDID" "$T/LongPressApp.app" >/dev/null
sleep 0.5
# Twenty-first installed app: grid slot 27, second page row 2 column 3.
"$ROOT/tools/iosimctl" ui "$UDID" tap 339.8333 322.5 >/dev/null
if wait_log "[press] ready"; then
    echo "ok   SpringBoard launches the long-press fixture"
else
    echo "FAIL long-press fixture launch"; fails=$((fails+1))
fi
"$ROOT/tools/iosimctl" ui "$UDID" tap 200 400 >/dev/null
sleep 0.6
began_count="$(grep -Fc "[press] began" "$SBLOG" 2>/dev/null || true)"
if [ "$began_count" -eq 0 ]; then
    echo "ok   a short tap does not begin a long press"
else
    echo "FAIL long press on tap ($began_count)"; fails=$((fails+1))
fi
"$ROOT/tools/iosimctl" ui "$UDID" down 200 400 >/dev/null
sleep 0.7
"$ROOT/tools/iosimctl" ui "$UDID" move 220 420 >/dev/null
"$ROOT/tools/iosimctl" ui "$UDID" up 220 420 >/dev/null
if wait_log "[press] began 200 400"; then
    echo "ok   holding past minimumPressDuration begins the gesture"
else
    echo "FAIL long press began"; fails=$((fails+1))
fi
if wait_log "[press] changed 220 420"; then
    echo "ok   moving during the press reports the changed state"
else
    echo "FAIL long press changed"; fails=$((fails+1))
fi
if wait_log "[press] ended 220 420"; then
    echo "ok   lifting the finger ends the long press at the last point"
else
    echo "FAIL long press ended"; fails=$((fails+1))
fi
before_count="$(grep -Fc "[press] began" "$SBLOG" 2>/dev/null || true)"
"$ROOT/tools/iosimctl" ui "$UDID" down 200 500 >/dev/null
"$ROOT/tools/iosimctl" ui "$UDID" move 200 620 >/dev/null
sleep 0.7
"$ROOT/tools/iosimctl" ui "$UDID" up 200 620 >/dev/null
sleep 0.2
after_count="$(grep -Fc "[press] began" "$SBLOG" 2>/dev/null || true)"
if [ "$after_count" -eq "$before_count" ]; then
    echo "ok   moving beyond allowableMovement fails the press"
else
    echo "FAIL long press movement ($before_count -> $after_count)"
    fails=$((fails+1))
fi
"$ROOT/tools/iosimctl" ui "$UDID" home >/dev/null
sleep 0.4

# ---------- 9j. navigation bar items and the automatic back button ----------
"$ROOT/tools/build_app.sh" "$ROOT/demo/NavBarApp.m" "$T/NavBarApp" >/dev/null
mkdir -p "$T/NavBarApp.app"
cp "$T/NavBarApp" "$T/NavBarApp.app/NavBarApp"
python3 - "$T/NavBarApp.app/Info.plist" <<'PY'
import plistlib, sys
with open(sys.argv[1], "wb") as f:
    plistlib.dump({
        "CFBundleIdentifier": "com.iosim.navbar",
        "CFBundleExecutable": "NavBarApp",
        "CFBundleName": "NavBar",
        "CFBundlePackageType": "APPL",
        "CFBundleVersion": "1",
        "CFBundleShortVersionString": "1.0",
    }, f)
PY
"$ROOT/tools/iosimctl" install "$UDID" "$T/NavBarApp.app" >/dev/null
sleep 0.5
# Twenty-second installed app: grid slot 28, second page row 3 column 0.
"$ROOT/tools/iosimctl" ui "$UDID" tap 62.1667 422.8333 >/dev/null
if wait_log "[nav] ready root"; then
    echo "ok   SpringBoard launches the navigation bar fixture"
else
    echo "FAIL nav bar fixture launch"; fails=$((fails+1))
fi
"$ROOT/tools/iosimctl" ui "$UDID" tap 341 70 >/dev/null
if wait_log "[nav] add"; then
    echo "ok   the right bar button item sends its target action"
else
    echo "FAIL bar button action"; fails=$((fails+1))
fi
"$ROOT/tools/iosimctl" ui "$UDID" tap 200 326 >/dev/null
if wait_log "[nav] detail appeared"; then
    echo "ok   pushing installs the detail controller under the bar"
else
    echo "FAIL nav push"; fails=$((fails+1))
fi
"$ROOT/tools/iosimctl" ui "$UDID" tap 68 70 >/dev/null
if wait_log "[nav] root appeared"; then
    echo "ok   the automatic back button pops to the previous controller"
else
    echo "FAIL nav back button"; fails=$((fails+1))
fi
"$ROOT/tools/iosimctl" ui "$UDID" home >/dev/null
sleep 0.4

# ---------- 9k. UISearchBar text editing, Return and Cancel ----------
"$ROOT/tools/build_app.sh" "$ROOT/demo/SearchBarApp.m" "$T/SearchBarApp" >/dev/null
mkdir -p "$T/SearchBarApp.app"
cp "$T/SearchBarApp" "$T/SearchBarApp.app/SearchBarApp"
python3 - "$T/SearchBarApp.app/Info.plist" <<'PY'
import plistlib, sys
with open(sys.argv[1], "wb") as f:
    plistlib.dump({
        "CFBundleIdentifier": "com.iosim.searchbar",
        "CFBundleExecutable": "SearchBarApp",
        "CFBundleName": "SearchBar",
        "CFBundlePackageType": "APPL",
        "CFBundleVersion": "1",
        "CFBundleShortVersionString": "1.0",
    }, f)
PY
"$ROOT/tools/iosimctl" install "$UDID" "$T/SearchBarApp.app" >/dev/null
sleep 0.5
# Twenty-third installed app: grid slot 29, second page row 3 column 1.
"$ROOT/tools/iosimctl" ui "$UDID" tap 154.7222 422.8333 >/dev/null
if wait_log "[searchbar] ready"; then
    echo "ok   SpringBoard launches the search bar fixture"
else
    echo "FAIL search bar fixture launch"; fails=$((fails+1))
fi
"$ROOT/tools/iosimctl" ui "$UDID" tap 120 162 >/dev/null
sleep 0.3
"$ROOT/tools/iosimctl" ui "$UDID" key a >/dev/null
"$ROOT/tools/iosimctl" ui "$UDID" key b >/dev/null
if wait_log "[searchbar] q=ab"; then
    echo "ok   typing in the search field reports textDidChange"
else
    echo "FAIL search bar editing"; fails=$((fails+1))
fi
"$ROOT/tools/iosimctl" io "$UDID" screenshot "$T/searchbar.png" >/dev/null
if out="$(python3 - "$ROOT/tools" "$T/searchbar.png" <<'PY'
import sys
sys.path.insert(0, sys.argv[1])
import pngpixel
w, h, bpp, rows = pngpixel.load(sys.argv[2])
c = pngpixel.px(rows, bpp, 23 * 3, 620 * 3)
r, g, b = (c >> 16) & 255, (c >> 8) & 255, c & 255
if not (50 <= r <= 100 and abs(r - g) < 12 and abs(g - b) < 12):
    raise SystemExit("search keyboard not visible: %06x" % c)
print("ok   focusing the search field raises the software keyboard")
PY
)"; then
    echo "$out"
else
    echo "FAIL search bar keyboard"; echo "$out"; fails=$((fails+1))
fi
"$ROOT/tools/iosimctl" ui "$UDID" key return >/dev/null
if wait_log "[searchbar] go ab"; then
    echo "ok   Return invokes the search action without a newline"
else
    echo "FAIL search bar return"; fails=$((fails+1))
fi
"$ROOT/tools/iosimctl" ui "$UDID" tap 350 162 >/dev/null
if wait_log "[searchbar] cancel"; then
    echo "ok   the cancel button reports and clears the field"
else
    echo "FAIL search bar cancel"; fails=$((fails+1))
fi
sleep 0.4
"$ROOT/tools/iosimctl" io "$UDID" screenshot "$T/searchbar-cancel.png" >/dev/null
if out="$(python3 - "$ROOT/tools" "$T/searchbar-cancel.png" <<'PY'
import sys
sys.path.insert(0, sys.argv[1])
import pngpixel
w, h, bpp, rows = pngpixel.load(sys.argv[2])
c = pngpixel.px(rows, bpp, 23 * 3, 620 * 3)
r, g, b = (c >> 16) & 255, (c >> 8) & 255, c & 255
if not (r < 30 and g < 40 and b < 70):
    raise SystemExit("keyboard still visible after cancel: %06x" % c)
print("ok   cancel resigns the field and dismisses the keyboard")
PY
)"; then
    echo "$out"
else
    echo "FAIL search bar dismiss"; echo "$out"; fails=$((fails+1))
fi
"$ROOT/tools/iosimctl" ui "$UDID" home >/dev/null
sleep 0.4

# ---------- 9l. UIStepper halves and ValueChanged ----------
"$ROOT/tools/build_app.sh" "$ROOT/demo/StepperApp.m" "$T/StepperApp" >/dev/null
mkdir -p "$T/StepperApp.app"
cp "$T/StepperApp" "$T/StepperApp.app/StepperApp"
python3 - "$T/StepperApp.app/Info.plist" <<'PY'
import plistlib, sys
with open(sys.argv[1], "wb") as f:
    plistlib.dump({
        "CFBundleIdentifier": "com.iosim.stepper",
        "CFBundleExecutable": "StepperApp",
        "CFBundleName": "Stepper",
        "CFBundlePackageType": "APPL",
        "CFBundleVersion": "1",
        "CFBundleShortVersionString": "1.0",
    }, f)
PY
"$ROOT/tools/iosimctl" install "$UDID" "$T/StepperApp.app" >/dev/null
sleep 0.5
# Twenty-fourth installed app: grid slot 30, second page row 3 column 2.
"$ROOT/tools/iosimctl" ui "$UDID" tap 247.2778 422.8333 >/dev/null
if wait_log "[stepper] ready"; then
    echo "ok   SpringBoard launches the stepper fixture"
else
    echo "FAIL stepper fixture launch"; fails=$((fails+1))
fi
"$ROOT/tools/iosimctl" ui "$UDID" tap 224 316 >/dev/null
if wait_log "[stepper] value=1"; then
    echo "ok   the plus half increments and sends ValueChanged"
else
    echo "FAIL stepper increment"; fails=$((fails+1))
fi
"$ROOT/tools/iosimctl" ui "$UDID" tap 224 316 >/dev/null
if wait_log "[stepper] value=2"; then
    echo "ok   the value tracks the step each tap"
else
    echo "FAIL stepper second increment"; fails=$((fails+1))
fi
"$ROOT/tools/iosimctl" ui "$UDID" tap 178 316 >/dev/null
sleep 0.3
value_lines="$(grep -Fc "[stepper] value=" "$SBLOG" 2>/dev/null || true)"
if [ "$value_lines" -eq 3 ]; then
    echo "ok   the minus half decrements the value again"
else
    echo "FAIL stepper decrement (events=$value_lines)"; fails=$((fails+1))
fi
"$ROOT/tools/iosimctl" ui "$UDID" home >/dev/null
sleep 0.4

# ---------- 9m. multi-section UICollectionView flow layout ----------
"$ROOT/tools/build_app.sh" "$ROOT/demo/SectionCollectionApp.m" \
    "$T/SectionCollectionApp" >/dev/null
mkdir -p "$T/SectionCollectionApp.app"
cp "$T/SectionCollectionApp" "$T/SectionCollectionApp.app/SectionCollectionApp"
python3 - "$T/SectionCollectionApp.app/Info.plist" <<'PY'
import plistlib, sys
with open(sys.argv[1], "wb") as f:
    plistlib.dump({
        "CFBundleIdentifier": "com.iosim.sectioncollection",
        "CFBundleExecutable": "SectionCollectionApp",
        "CFBundleName": "SectionCollection",
        "CFBundlePackageType": "APPL",
        "CFBundleVersion": "1",
        "CFBundleShortVersionString": "1.0",
    }, f)
PY
"$ROOT/tools/iosimctl" install "$UDID" "$T/SectionCollectionApp.app" >/dev/null
sleep 0.5
# Settle on page 2 so the twenty-fifth icon's slot is visible.
"$ROOT/tools/iosimctl" ui "$UDID" swipe 50 400 350 400 0.3 >/dev/null
sleep 0.3
"$ROOT/tools/iosimctl" ui "$UDID" swipe 350 400 50 400 0.3 >/dev/null
sleep 0.4
# Twenty-fifth installed app: grid slot 31, second page row 3 column 3.
"$ROOT/tools/iosimctl" ui "$UDID" tap 339.8333 422.8333 >/dev/null
if wait_log "[sectioncollection] ready"; then
    echo "ok   SpringBoard launches the sectioned collection fixture"
else
    echo "FAIL sectioned collection launch"; fails=$((fails+1))
fi
"$ROOT/tools/iosimctl" io "$UDID" screenshot "$T/sectioncollection.png" >/dev/null
if out="$(python3 - "$ROOT/tools" "$T/sectioncollection.png" <<'PY'
import sys
sys.path.insert(0, sys.argv[1])
import pngpixel
w, h, bpp, rows = pngpixel.load(sys.argv[2])

def px(point_x, point_y):
    return pngpixel.px(rows, bpp, point_x * 3, point_y * 3)

c = px(60, 270)
r, g, b = (c >> 16) & 255, (c >> 8) & 255, c & 255
if not (r < 130 and g > 150 and b < 170):
    raise SystemExit("second section cell not drawn: %06x" % c)
c = px(60, 205)
r, g, b = (c >> 16) & 255, (c >> 8) & 255, c & 255
if not (r < 45 and g < 50 and b < 70):
    raise SystemExit("sections not separated by a gap: %06x" % c)
print("ok   the flow layout stacks section two below section one")
PY
)"; then
    echo "$out"
else
    echo "FAIL sectioned collection rendering"; echo "$out"; fails=$((fails+1))
fi
"$ROOT/tools/iosimctl" ui "$UDID" tap 240 140 >/dev/null
if wait_log "[sectioncollection] selected 0:2"; then
    echo "ok   tapping a first-section cell reports section 0 and its row"
else
    echo "FAIL sectioned collection first selection"; fails=$((fails+1))
fi
"$ROOT/tools/iosimctl" ui "$UDID" tap 150 270 >/dev/null
if wait_log "[sectioncollection] selected 1:1"; then
    echo "ok   tapping a second-section cell reports that section and row"
else
    echo "FAIL sectioned collection second selection"; fails=$((fails+1))
fi
"$ROOT/tools/iosimctl" ui "$UDID" home >/dev/null
sleep 0.4

# ---------- 9n. UIPickerView wheels, taps and drags ----------
"$ROOT/tools/build_app.sh" "$ROOT/demo/PickerApp.m" "$T/PickerApp" >/dev/null
mkdir -p "$T/PickerApp.app"
cp "$T/PickerApp" "$T/PickerApp.app/PickerApp"
python3 - "$T/PickerApp.app/Info.plist" <<'PY'
import plistlib, sys
with open(sys.argv[1], "wb") as f:
    plistlib.dump({
        "CFBundleIdentifier": "com.iosim.picker",
        "CFBundleExecutable": "PickerApp",
        "CFBundleName": "Picker",
        "CFBundlePackageType": "APPL",
        "CFBundleVersion": "1",
        "CFBundleShortVersionString": "1.0",
    }, f)
PY
"$ROOT/tools/iosimctl" install "$UDID" "$T/PickerApp.app" >/dev/null
sleep 0.5
# Twenty-sixth installed app: first slot of the third home page.
"$ROOT/tools/iosimctl" ui "$UDID" swipe 350 400 50 400 0.3 >/dev/null
sleep 0.4
"$ROOT/tools/iosimctl" ui "$UDID" tap 62.1667 121.8333 >/dev/null
if wait_log "[picker] ready"; then
    echo "ok   SpringBoard launches the picker fixture"
else
    echo "FAIL picker fixture launch"; fails=$((fails+1))
fi
"$ROOT/tools/iosimctl" io "$UDID" screenshot "$T/picker.png" >/dev/null
if out="$(python3 - "$ROOT/tools" "$T/picker.png" <<'PY'
import sys
sys.path.insert(0, sys.argv[1])
import pngpixel
w, h, bpp, rows = pngpixel.load(sys.argv[2])
c = pngpixel.px(rows, bpp, 30 * 3, 248 * 3)
r, g, b = (c >> 16) & 255, (c >> 8) & 255, c & 255
if not (28 <= r <= 55 and 32 <= g <= 60 and 46 <= b <= 80):
    raise SystemExit("picker selection band not drawn: %06x" % c)
print("ok   the picker draws its centered selection band over two wheels")
PY
)"; then
    echo "$out"
else
    echo "FAIL picker rendering"; echo "$out"; fails=$((fails+1))
fi
"$ROOT/tools/iosimctl" ui "$UDID" tap 290 312 >/dev/null
if wait_log "[picker] selected 1:2"; then
    echo "ok   tapping a wheel row selects it in that component"
else
    echo "FAIL picker tap selection"; fails=$((fails+1))
fi
"$ROOT/tools/iosimctl" ui "$UDID" down 100 300 >/dev/null
"$ROOT/tools/iosimctl" ui "$UDID" move 100 236 >/dev/null
"$ROOT/tools/iosimctl" ui "$UDID" up 100 236 >/dev/null
if wait_log "[picker] selected 0:2"; then
    echo "ok   dragging the first wheel two rows snaps to the new selection"
else
    echo "FAIL picker drag selection"; fails=$((fails+1))
fi
"$ROOT/tools/iosimctl" ui "$UDID" home >/dev/null
sleep 0.4

# ---------- 9o. UIDatePicker date and time wheels ----------
"$ROOT/tools/build_app.sh" "$ROOT/demo/DatePickerApp.m" "$T/DatePickerApp" >/dev/null
mkdir -p "$T/DatePickerApp.app"
cp "$T/DatePickerApp" "$T/DatePickerApp.app/DatePickerApp"
python3 - "$T/DatePickerApp.app/Info.plist" <<'PY'
import plistlib, sys
with open(sys.argv[1], "wb") as f:
    plistlib.dump({
        "CFBundleIdentifier": "com.iosim.datepicker",
        "CFBundleExecutable": "DatePickerApp",
        "CFBundleName": "DatePicker",
        "CFBundlePackageType": "APPL",
        "CFBundleVersion": "1",
        "CFBundleShortVersionString": "1.0",
    }, f)
PY
"$ROOT/tools/iosimctl" install "$UDID" "$T/DatePickerApp.app" >/dev/null
sleep 0.5
# Twenty-seventh installed app: third page row 0 column 1.
"$ROOT/tools/iosimctl" ui "$UDID" tap 154.7222 121.8333 >/dev/null
if wait_log "[datepicker] ready"; then
    echo "ok   SpringBoard launches the date picker fixture"
else
    echo "FAIL date picker fixture launch"; fails=$((fails+1))
fi
"$ROOT/tools/iosimctl" ui "$UDID" tap 201 128 >/dev/null
if wait_log "[datepicker] date 1709123640"; then
    echo "ok   tapping the day wheel moves the date one day back"
else
    echo "FAIL date picker day selection"; fails=$((fails+1))
fi
"$ROOT/tools/iosimctl" ui "$UDID" tap 83 192 >/dev/null
if wait_log "[datepicker] date 1711629240"; then
    echo "ok   selecting March updates month, day and year wheels together"
else
    echo "FAIL date picker month selection"; fails=$((fails+1))
fi
"$ROOT/tools/iosimctl" ui "$UDID" tap 201 382 >/dev/null
if wait_log "[datepicker] time 1709210100"; then
    echo "ok   the time wheels edit minutes and keep the AM/PM selection"
else
    echo "FAIL date picker time selection"; fails=$((fails+1))
fi
"$ROOT/tools/iosimctl" ui "$UDID" home >/dev/null
sleep 0.4

# ---------- 10. cross-process Mach services ----------
# launchd owns the bootstrap namespace; two independent guest processes find
# each other through it and exchange a Mach message over the service port.
obj "$ROOT/tests/mach_cross_test.c" "$T/mach_cross.o"
exe "$T/mach_cross" "$T/mach_cross.o"
MSVC="$T/mach-service.log"
rm -f "$MSVC"
"$ROOT/tools/iosimctl" spawn "$UDID" "$T/mach_cross" service > "$MSVC" 2>&1 &
svc_job=$!
i=0
while [ "$i" -lt 50 ]; do
    grep -Fq -- "service: registered=" "$MSVC" 2>/dev/null && break
    sleep 0.1
    i=$((i+1))
done
if grep -Fq -- "service: registered=0" "$MSVC" 2>/dev/null; then
    echo "ok   a guest process registers a bootstrap service"
else
    echo "FAIL bootstrap registration"; cat "$MSVC"; fails=$((fails+1))
fi
out="$("$ROOT/tools/iosimctl" spawn "$UDID" "$T/mach_cross" conflict 2>&1 | tail -1)"
check "conflict: result=1103" "$out" \
    "a second registration of the same name reports service active"
out="$("$ROOT/tools/iosimctl" spawn "$UDID" "$T/mach_cross" client 2>&1)"
check "client: sent=0" "$out" \
    "a second process looks up the service and sends a message"
i=0
while [ "$i" -lt 80 ]; do
    grep -Fq -- "service: received" "$MSVC" 2>/dev/null && break
    sleep 0.1
    i=$((i+1))
done
if grep -Fq -- "service: received id=0x1234 value=91 text=hello across processes" \
    "$MSVC" 2>/dev/null; then
    echo "ok   mach_msg carries the payload across the process boundary"
else
    echo "FAIL cross-process mach_msg"; cat "$MSVC"; fails=$((fails+1))
fi
wait "$svc_job" 2>/dev/null || true
out="$("$ROOT/tools/iosimctl" spawn "$UDID" "$T/mach_cross" register 2>&1 | tail -1)"
check "register: result=0" "$out" \
    "the name is released when its registering process exits"
out="$("$ROOT/tools/iosimctl" spawn "$UDID" "$T/mach_cross" probe 2>&1 | tail -1)"
check "probe: unknown lookup=1102" "$out" \
    "an unregistered bootstrap name is unknown"
if grep -q "service com.iosim.cross.mach registered by pid" \
    "$IOSIM_HOME/Devices/$UDID/logs/launchd_sim.log" 2>/dev/null; then
    echo "ok   launchd owns the registered service name"
else
    echo "note: launchd log not captured at the expected path"
fi

# ---------- 11. cross-process XPC ----------
# An XPC listener registers its Mach service and receives each client as a
# peer connection; the peer's handler gets the rebuilt dictionary and its
# reply comes back to both the async and the synchronous client APIs.
"$CC" -target "$TARGET" -ffreestanding -fPIC -O1 -fblocks \
    -c "$ROOT/tests/xpc_cross_test.c" -o "$T/xpc_cross.o"
exe "$T/xpc_cross" "$T/xpc_cross.o"
XLOG="$T/xpc-service.log"
rm -f "$XLOG"
"$ROOT/tools/iosimctl" spawn "$UDID" "$T/xpc_cross" service > "$XLOG" 2>&1 &
xpc_job=$!
i=0
while [ "$i" -lt 50 ]; do
    grep -Fq -- "xpc service: ready" "$XLOG" 2>/dev/null && break
    sleep 0.1
    i=$((i+1))
done
if grep -Fq -- "xpc service: ready" "$XLOG" 2>/dev/null; then
    echo "ok   an XPC listener registers its Mach service"
else
    echo "FAIL XPC listener"; cat "$XLOG"; fails=$((fails+1))
fi
out="$("$ROOT/tools/iosimctl" spawn "$UDID" "$T/xpc_cross" client 2>&1)"
check "xpc client: reply kind=pong seq=8" "$out" \
    "an async XPC request receives its reply"
check "xpc client: sync reply kind=pong seq=8" "$out" \
    "a synchronous XPC request returns its reply"
i=0
while [ "$i" -lt 50 ]; do
    grep -Fq -- "xpc service: received" "$XLOG" 2>/dev/null && break
    sleep 0.1
    i=$((i+1))
done
check "xpc service: received kind=ping seq=7 flag=1 blob=4" "$(cat "$XLOG")" \
    "the dictionary arrives as a rebuilt XPC object in the other process"
wait "$xpc_job" 2>/dev/null || true

# ---------- 12. launchd on-demand and RunAtLoad jobs ----------
# A LaunchDaemon plist installs a job whose MachServices name is not running
# until a client looks it up; launchd_sim starts the job, the job registers
# its service, and the client's XPC request receives a reply.
"$CC" -target "$TARGET" -ffreestanding -fPIC -O1 -fblocks \
    -c "$ROOT/tests/launchd_job_test.c" -o "$T/launchd_job.o"
exe "$T/launchd_job" "$T/launchd_job.o"
python3 - "$T/launchd_job" "$T/ondemand.plist" com.iosim.launchd.job \
    com.iosim.launchd.echo 0 <<'PY'
import plistlib, sys
binary, out, label, service, run_at_load = sys.argv[1:6]
with open(out, "wb") as f:
    plistlib.dump({
        "Label": label,
        "ProgramArguments": [binary, "job", service],
        "MachServices": {service: True},
        "RunAtLoad": run_at_load == "1",
    }, f)
PY
"$ROOT/tools/iosimctl" launchd-load "$UDID" "$T/ondemand.plist" >/dev/null
JOBLOG="$IOSIM_HOME/Devices/$UDID/logs/com.iosim.launchd.job.log"
if [ ! -f "$JOBLOG" ] || ! grep -Fq -- "launchd job: ready" "$JOBLOG"; then
    echo "ok   an on-demand job waits until its Mach service is looked up"
else
    echo "FAIL on-demand job started early"; fails=$((fails+1))
fi
out="$("$ROOT/tools/iosimctl" spawn "$UDID" "$T/launchd_job" client \
    com.iosim.launchd.echo 2>&1)"
check "launchd client: reply kind=pong seq=42" "$out" \
    "a lookup starts the on-demand job and its XPC reply arrives"
i=0
while [ "$i" -lt 50 ]; do
    grep -Fq -- "launchd job: replied" "$JOBLOG" 2>/dev/null && break
    sleep 0.1
    i=$((i+1))
done
if grep -Fq -- "launchd job: ready name=com.iosim.launchd.echo" \
    "$JOBLOG" 2>/dev/null; then
    echo "ok   the started job registers its Mach service and serves the request"
else
    echo "FAIL launchd job log"; cat "$JOBLOG" 2>/dev/null || true
    fails=$((fails+1))
fi
python3 - "$T/launchd_job" "$T/runatload.plist" com.iosim.launchd.runjob \
    com.iosim.launchd.run 1 <<'PY'
import plistlib, sys
binary, out, label, service, run_at_load = sys.argv[1:6]
with open(out, "wb") as f:
    plistlib.dump({
        "Label": label,
        "ProgramArguments": [binary, "job", service],
        "MachServices": {service: True},
        "RunAtLoad": run_at_load == "1",
    }, f)
PY
"$ROOT/tools/iosimctl" launchd-load "$UDID" "$T/runatload.plist" >/dev/null
RUNLOG="$IOSIM_HOME/Devices/$UDID/logs/com.iosim.launchd.runjob.log"
i=0
while [ "$i" -lt 50 ]; do
    grep -Fq -- "launchd job: ready name=com.iosim.launchd.run" \
        "$RUNLOG" 2>/dev/null && break
    sleep 0.1
    i=$((i+1))
done
if grep -Fq -- "launchd job: ready name=com.iosim.launchd.run" \
    "$RUNLOG" 2>/dev/null; then
    echo "ok   a RunAtLoad job starts when launchd loads it"
else
    echo "FAIL RunAtLoad job"; cat "$RUNLOG" 2>/dev/null || true
    fails=$((fails+1))
fi
out="$("$ROOT/tools/iosimctl" spawn "$UDID" "$T/launchd_job" client \
    com.iosim.launchd.run 2>&1)"
check "launchd client: reply kind=pong seq=42" "$out" \
    "the RunAtLoad job's Mach service answers a client"

# ---------- 13. Control Center ----------
# A downward drag from the top-right corner opens the glass panel over the
# home screen; connectivity controls toggle on tap; a swipe up closes it.
"$ROOT/tools/iosimctl" ui "$UDID" swipe 350 20 350 240 0.3 >/dev/null
if wait_log "[SpringBoard] control center opened"; then
    echo "ok   a top-right downward drag opens Control Center"
else
    echo "FAIL control center open"; fails=$((fails+1))
fi
sleep 0.3
"$ROOT/tools/iosimctl" io "$UDID" screenshot "$T/control-center.png" >/dev/null
if out="$(python3 - "$ROOT/tools" "$T/control-center.png" <<'PY'
import sys
sys.path.insert(0, sys.argv[1])
import pngpixel
w, h, bpp, rows = pngpixel.load(sys.argv[2])
c = pngpixel.px(rows, bpp, 60 * 3, 210 * 3)
r, g, b = (c >> 16) & 255, (c >> 8) & 255, c & 255
if not (r < 70 and 100 < g < 180 and b > 200):
    raise SystemExit("wifi toggle not blue: %06x" % c)
print("ok   the connectivity controls render in their on state")
PY
)"; then
    echo "$out"
else
    echo "FAIL control center rendering"; echo "$out"; fails=$((fails+1))
fi
"$ROOT/tools/iosimctl" ui "$UDID" tap 60 232 >/dev/null
if wait_log "[SpringBoard] control center wifi off"; then
    echo "ok   tapping the wifi control toggles it off"
else
    echo "FAIL control center wifi toggle"; fails=$((fails+1))
fi
sleep 0.3
"$ROOT/tools/iosimctl" io "$UDID" screenshot "$T/control-center-off.png" >/dev/null
if out="$(python3 - "$ROOT/tools" "$T/control-center-off.png" <<'PY'
import sys
sys.path.insert(0, sys.argv[1])
import pngpixel
w, h, bpp, rows = pngpixel.load(sys.argv[2])
c = pngpixel.px(rows, bpp, 60 * 3, 210 * 3)
r, g, b = (c >> 16) & 255, (c >> 8) & 255, c & 255
if not (35 <= r <= 85 and abs(r - g) < 14 and 40 <= b <= 95):
    raise SystemExit("wifi toggle did not turn gray: %06x" % c)
print("ok   the toggled control redraws in its off state")
PY
)"; then
    echo "$out"
else
    echo "FAIL control center off rendering"; echo "$out"; fails=$((fails+1))
fi
"$ROOT/tools/iosimctl" ui "$UDID" tap 148 232 >/dev/null
if wait_log "[SpringBoard] control center bluetooth on"; then
    echo "ok   the bluetooth control toggles on"
else
    echo "FAIL control center bluetooth toggle"; fails=$((fails+1))
fi
"$ROOT/tools/iosimctl" ui "$UDID" swipe 200 830 200 600 0.3 >/dev/null
if wait_log "[SpringBoard] control center closed"; then
    echo "ok   a swipe up dismisses Control Center"
else
    echo "FAIL control center close"; fails=$((fails+1))
fi

"$ROOT/tools/iosimctl" shutdown "$UDID" >/dev/null

if [ "$fails" -ne 0 ]; then
    echo "$fails test(s) failed" >&2
    exit 1
fi
echo "all tests passed"
