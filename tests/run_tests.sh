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
RUN="${IOSIM_RUN:-$ROOT/build/iosim-run}"
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

# ---------- 4j. date parsing and number formatting ----------
"$CC" -target "$TARGET" -fobjc-runtime=ios-18.0 -fno-objc-arc -fblocks \
    -ffreestanding -O1 -I "$ROOT/frameworks" \
    -c "$ROOT/tests/format_test.m" -o "$T/format_test.o"
"$LD64" -arch x86_64 -platform_version $PLATFORM -e _main \
    -o "$T/format_test" "$T/format_test.o" \
    "$ROOT/runtime/System/Library/Frameworks/Foundation.framework/Foundation" \
    -undefined dynamic_lookup
out="$(DYLD_ROOT_PATH="$ROOT/runtime" "$RUN" "$T/format_test" 2>&1)"
check "parsed 1709210096" "$out" \
    "NSDateFormatter parses yyyy-MM-dd HH:mm:ss into the right instant"
check "roundtrip 1709210096" "$out" \
    "a parsed date prints and re-parses to the same instant"
check "invalid no" "$out" "unparseable date strings return nil"
check "decimal 1,234.5" "$out" \
    "NSNumberFormatter groups and trims fraction digits"
check "parsed number 1234.5" "$out" \
    "NSNumberFormatter parses grouped decimal text back to a number"
check "currency \$99.50" "$out" \
    "the currency style adds a symbol and two fraction digits"
check "percent 25.6%" "$out" \
    "the percent style scales the value and appends a sign"

# ---------- 4k. NSFileHandle read/write/seek/truncate ----------
"$CC" -target "$TARGET" -fobjc-runtime=ios-18.0 -fno-objc-arc \
    -ffreestanding -O1 -I "$ROOT/frameworks" \
    -c "$ROOT/tests/filehandle_test.m" -o "$T/filehandle_test.o"
"$LD64" -arch x86_64 -platform_version $PLATFORM -e _main \
    -o "$T/filehandle_test" "$T/filehandle_test.o" \
    "$ROOT/runtime/System/Library/Frameworks/Foundation.framework/Foundation" \
    -undefined dynamic_lookup
FH_HOME="$T/filehandle-home"
rm -rf "$FH_HOME"
mkdir -p "$FH_HOME"
out="$(HOME="$FH_HOME" DYLD_ROOT_PATH="$ROOT/runtime" "$RUN" "$T/filehandle_test" 2>&1)"
check "[fh] read 17" "$out" \
    "NSFileHandle reads a written file back to the end"
check "[fh] text hello file handle" "$out" \
    "writeData: stores the bytes in order"
check "[fh] mid file" "$out" \
    "seekToFileOffset: positions readDataOfLength:"
check "[fh] offset 10" "$out" "offsetInFile tracks the shared descriptor"
check "[fh] end 17" "$out" "seekToEndOfFile returns the file length"
check "[fh] final hello file!" "$out" \
    "truncateFileAtOffset: and an updating handle append correctly"

# ---------- 4l. Foundation fast enumeration and subscripting ----------
"$CC" -target "$TARGET" -fobjc-runtime=ios-18.0 -fno-objc-arc \
    -ffreestanding -O1 -I "$ROOT/frameworks" \
    -c "$ROOT/tests/fastenum_test.m" -o "$T/fastenum_test.o"
"$LD64" -arch x86_64 -platform_version $PLATFORM -e _main \
    -o "$T/fastenum_test" "$T/fastenum_test.o" \
    "$ROOT/runtime/System/Library/Frameworks/Foundation.framework/Foundation" \
    -undefined dynamic_lookup
out="$(DYLD_ROOT_PATH="$ROOT/runtime" "$RUN" "$T/fastenum_test" 2>&1)"
check "[fe] array alphabetagamma" "$out" \
    "for-in over NSArray enumerates in storage order"
check "[fe] sum 10" "$out" \
    "fast enumeration over NSNumber objects boxes and unboxes values"
check "[fe] set xyz" "$out" "for-in over NSSet walks members"
check "[fe] dict k1k2k3" "$out" \
    "for-in over NSDictionary enumerates its keys"
check "[fe] sub alpha gamma" "$out" \
    "indexed subscripting reads NSArray elements"
check "[fe] replace BETA" "$out" \
    "setObject:atIndexedSubscript: replaces an element"
check "[fe] append delta" "$out" \
    "setting the end subscript appends to a mutable array"
check "[fe] dsub one three" "$out" \
    "keyed subscripting reads NSDictionary values"
check "[fe] dset TWO" "$out" \
    "setObject:forKeyedSubscript: updates a dictionary value"
check "[fe] dremove 2" "$out" \
    "setting nil through a keyed subscript removes the key"
check "[fe] dmiss nil" "$out" \
    "a missing keyed subscript returns nil"

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
sleep 0.3
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
"$ROOT/tools/iosimctl" ui "$UDID" swipe 200 500 200 400 0.4 >/dev/null
sleep 1.5
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
sleep 0.3
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
sleep 0.3
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

# ---------- 9p. UITableView swipe-to-delete ----------
"$ROOT/tools/build_app.sh" "$ROOT/demo/TableEditApp.m" "$T/TableEditApp" >/dev/null
mkdir -p "$T/TableEditApp.app"
cp "$T/TableEditApp" "$T/TableEditApp.app/TableEditApp"
python3 - "$T/TableEditApp.app/Info.plist" <<'PY'
import plistlib, sys
with open(sys.argv[1], "wb") as f:
    plistlib.dump({
        "CFBundleIdentifier": "com.iosim.tableedit",
        "CFBundleExecutable": "TableEditApp",
        "CFBundleName": "TableEdit",
        "CFBundlePackageType": "APPL",
        "CFBundleVersion": "1",
        "CFBundleShortVersionString": "1.0",
    }, f)
PY
"$ROOT/tools/iosimctl" install "$UDID" "$T/TableEditApp.app" >/dev/null
sleep 0.5
# Twenty-eighth installed app: third page row 0 column 2.
"$ROOT/tools/iosimctl" ui "$UDID" tap 247.2778 121.8333 >/dev/null
if wait_log "[edit] ready items=4"; then
    echo "ok   SpringBoard launches the editable table fixture"
else
    echo "FAIL table edit launch"; fails=$((fails+1))
fi
"$ROOT/tools/iosimctl" ui "$UDID" swipe 300 164 180 164 0.3 >/dev/null
if wait_log "[table] delete revealed 1"; then
    echo "ok   swiping a row left reveals its Delete control"
else
    echo "FAIL table swipe reveal"; fails=$((fails+1))
fi
sleep 0.2
"$ROOT/tools/iosimctl" io "$UDID" screenshot "$T/table-edit.png" >/dev/null
if out="$(python3 - "$ROOT/tools" "$T/table-edit.png" <<'PY'
import sys
sys.path.insert(0, sys.argv[1])
import pngpixel
w, h, bpp, rows = pngpixel.load(sys.argv[2])
c = pngpixel.px(rows, bpp, 330 * 3, 164 * 3)
r, g, b = (c >> 16) & 255, (c >> 8) & 255, c & 255
if not (r > 200 and g < 120 and b < 120):
    raise SystemExit("delete control not red: %06x" % c)
print("ok   the revealed Delete control is drawn in row 1")
PY
)"; then
    echo "$out"
else
    echo "FAIL table delete rendering"; echo "$out"; fails=$((fails+1))
fi
"$ROOT/tools/iosimctl" ui "$UDID" tap 360 164 >/dev/null
if wait_log "[edit] deleted 1 name=Green" &&
    wait_log "[edit] items=3"; then
    echo "ok   tapping Delete commits the edit and removes the row"
else
    echo "FAIL table edit commit"; fails=$((fails+1))
fi
sleep 0.3
"$ROOT/tools/iosimctl" io "$UDID" screenshot "$T/table-edit-after.png" >/dev/null
if out="$(python3 - "$ROOT/tools" "$T/table-edit-after.png" <<'PY'
import sys
sys.path.insert(0, sys.argv[1])
import pngpixel
w, h, bpp, rows = pngpixel.load(sys.argv[2])
c = pngpixel.px(rows, bpp, 330 * 3, 164 * 3)
r, g, b = (c >> 16) & 255, (c >> 8) & 255, c & 255
if r > 180 and g < 130 and b < 130:
    raise SystemExit("delete control still visible: %06x" % c)
print("ok   the committed row is gone and the button is cleared")
PY
)"; then
    echo "$out"
else
    echo "FAIL table delete clearing"; echo "$out"; fails=$((fails+1))
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

# ---------- 14. home-screen folders ----------
# Dragging one home-screen icon onto another groups them into a folder; the
# folder opens on tap, its members launch their apps, and the grouping is
# persisted and restored on the next boot.
"$ROOT/tools/iosimctl" ui "$UDID" drag 62.1667 121.8333 154.7222 121.8333 >/dev/null
if wait_log "[SpringBoard] folder created name=Folder (2 apps)"; then
    echo "ok   dragging one icon onto another creates a folder"
else
    echo "FAIL folder creation"; fails=$((fails+1))
fi
sleep 0.4
"$ROOT/tools/iosimctl" io "$UDID" screenshot "$T/folder-home.png" >/dev/null
if out="$(python3 - "$ROOT/tools" "$T/folder-home.png" <<'PY'
import sys
sys.path.insert(0, sys.argv[1])
import pngpixel
w, h, bpp, rows = pngpixel.load(sys.argv[2])
c = pngpixel.px(rows, bpp, 62 * 3, 92 * 3)
r, g, b = (c >> 16) & 255, (c >> 8) & 255, c & 255
if not (48 <= r <= 70 and 48 <= g <= 70 and 50 <= b <= 72):
    raise SystemExit("folder tile not drawn: %06x" % c)
print("ok   the home screen draws a folder tile in the first page-3 slot")
PY
)"; then
    echo "$out"
else
    echo "FAIL folder tile rendering"; echo "$out"; fails=$((fails+1))
fi
"$ROOT/tools/iosimctl" ui "$UDID" tap 62.1667 121.8333 >/dev/null
if wait_log "[SpringBoard] folder opened name=Folder (2 apps)"; then
    echo "ok   tapping the folder opens it over a dimmed home screen"
else
    echo "FAIL folder open"; fails=$((fails+1))
fi
sleep 0.4
"$ROOT/tools/iosimctl" io "$UDID" screenshot "$T/folder-overlay.png" >/dev/null
if out="$(python3 - "$ROOT/tools" "$T/folder-home.png" "$T/folder-overlay.png" <<'PY'
import sys
sys.path.insert(0, sys.argv[1])
import pngpixel

def px(path, x, y):
    w, h, bpp, rows = pngpixel.load(path)
    return pngpixel.px(rows, bpp, x * 3, y * 3)

home = px(sys.argv[2], 201, 600)
opened = px(sys.argv[3], 201, 600)
hr, hg, hb = (home >> 16) & 255, (home >> 8) & 255, home & 255
or_, og, ob = (opened >> 16) & 255, (opened >> 8) & 255, opened & 255
if not (or_ * 2 <= hr + 8 and og * 2 <= hg + 8 and ob * 2 <= hb + 8):
    raise SystemExit("background not dimmed: %06x -> %06x" % (home, opened))
w, h, bpp, rows = pngpixel.load(sys.argv[3])
white = 0
for y in range(66 * 3, 100 * 3):
    for x in range(120 * 3, 282 * 3):
        c = pngpixel.px(rows, bpp, x, y)
        if ((c >> 16) & 255) > 225 and ((c >> 8) & 255) > 225 and (c & 255) > 225:
            white += 1
if white < 60:
    raise SystemExit("folder title not drawn: %d white pixels" % white)
print("ok   the overlay dims the home screen and titles the folder")
PY
)"; then
    echo "$out"
else
    echo "FAIL folder overlay rendering"; echo "$out"; fails=$((fails+1))
fi
"$ROOT/tools/iosimctl" ui "$UDID" tap 156.75 190 >/dev/null
if wait_log "[SpringBoard] resuming Picker (pid"; then
    echo "ok   tapping a folder member resumes that app"
else
    echo "FAIL folder member launch"; fails=$((fails+1))
fi
"$ROOT/tools/iosimctl" ui "$UDID" home >/dev/null
sleep 0.4
"$ROOT/tools/iosimctl" ui "$UDID" tap 62.1667 121.8333 >/dev/null
sleep 0.3
"$ROOT/tools/iosimctl" ui "$UDID" tap 201 700 >/dev/null
if wait_log "[SpringBoard] folder closed"; then
    echo "ok   tapping outside the folder returns to the home screen"
else
    echo "FAIL folder close"; fails=$((fails+1))
fi
if grep -Fq -- "Folder|com.iosim.datepicker,com.iosim.picker" \
    "$IOSIM_HOME/Devices/$UDID/data/Library/SpringBoard/folders.txt" \
    2>/dev/null; then
    echo "ok   the folder grouping is persisted to folders.txt"
else
    echo "FAIL folder persistence file"; fails=$((fails+1))
fi
"$ROOT/tools/iosimctl" shutdown "$UDID" >/dev/null
"$ROOT/tools/iosimctl" boot "$UDID" >/dev/null
sleep 1
"$ROOT/tools/iosimctl" ui "$UDID" swipe 350 400 50 400 0.3 >/dev/null
sleep 0.4
"$ROOT/tools/iosimctl" ui "$UDID" swipe 350 400 50 400 0.3 >/dev/null
sleep 0.4
"$ROOT/tools/iosimctl" io "$UDID" screenshot "$T/folder-reboot.png" >/dev/null
if out="$(python3 - "$ROOT/tools" "$T/folder-reboot.png" <<'PY'
import sys
sys.path.insert(0, sys.argv[1])
import pngpixel
w, h, bpp, rows = pngpixel.load(sys.argv[2])
c = pngpixel.px(rows, bpp, 62 * 3, 92 * 3)
r, g, b = (c >> 16) & 255, (c >> 8) & 255, c & 255
if not (48 <= r <= 70 and 48 <= g <= 70 and 50 <= b <= 72):
    raise SystemExit("folder tile not restored: %06x" % c)
print("ok   the saved folder is restored on the next boot")
PY
)"; then
    echo "$out"
else
    echo "FAIL folder restore"; echo "$out"; fails=$((fails+1))
fi

# ---------- 15. lock screen ----------
# Locking draws the lock screen over the wallpaper; swiping up unlocks. An
# app that is foreground when the device locks backgrounds, and the unlock
# resumes the same process.
"$ROOT/tools/iosimctl" ui "$UDID" lock >/dev/null
if wait_log "[SpringBoard] locked"; then
    echo "ok   the lock event shows the lock screen"
else
    echo "FAIL lock from home"; fails=$((fails+1))
fi
sleep 0.4
"$ROOT/tools/iosimctl" io "$UDID" screenshot "$T/lock-home.png" >/dev/null
if out="$(python3 - "$ROOT/tools" "$T/lock-home.png" <<'PY'
import sys
sys.path.insert(0, sys.argv[1])
import pngpixel
w, h, bpp, rows = pngpixel.load(sys.argv[2])

def count(x0, x1, y0, y1):
    n = 0
    for y in range(y0 * 3, y1 * 3):
        for x in range(x0 * 3, x1 * 3):
            c = pngpixel.px(rows, bpp, x, y)
            if ((c >> 16) & 255) > 245 and ((c >> 8) & 255) > 245 and \
                    (c & 255) > 245:
                n += 1
    return n

big = count(110, 290, 115, 195)
date = count(120, 282, 62, 85)
status = count(55, 105, 18, 48)
if big < 20000 or date < 3000:
    raise SystemExit("lock clock missing: big=%d date=%d" % (big, date))
if status > 50:
    raise SystemExit("status-bar time still drawn: %d px" % status)
cam = pngpixel.px(rows, bpp, 333 * 3, 783 * 3)
if cam != 0xffffff:
    raise SystemExit("camera glyph not drawn: %06x" % cam)
print("ok   the lock screen draws the date, big clock and utility glass")
PY
)"; then
    echo "$out"
else
    echo "FAIL lock screen rendering"; echo "$out"; fails=$((fails+1))
fi
"$ROOT/tools/iosimctl" ui "$UDID" swipe 200 830 200 600 0.3 >/dev/null
if wait_log "[SpringBoard] unlocked"; then
    echo "ok   swiping up on the lock screen unlocks"
else
    echo "FAIL lock swipe unlock"; fails=$((fails+1))
fi
sleep 0.4
"$ROOT/tools/iosimctl" io "$UDID" screenshot "$T/unlock-home.png" >/dev/null
if out="$(python3 - "$ROOT/tools" "$T/unlock-home.png" <<'PY'
import sys
sys.path.insert(0, sys.argv[1])
import pngpixel
w, h, bpp, rows = pngpixel.load(sys.argv[2])
n = 0
for y in range(18 * 3, 48 * 3):
    for x in range(55 * 3, 105 * 3):
        c = pngpixel.px(rows, bpp, x, y)
        if ((c >> 16) & 255) > 245 and ((c >> 8) & 255) > 245 and \
                (c & 255) > 245:
            n += 1
if n < 500:
    raise SystemExit("home screen status time not restored: %d px" % n)
print("ok   the unlocked device returns to the home screen")
PY
)"; then
    echo "$out"
else
    echo "FAIL unlock home rendering"; echo "$out"; fails=$((fails+1))
fi
"$ROOT/tools/build_app.sh" "$ROOT/demo/LockApp.m" "$T/LockApp" >/dev/null
mkdir -p "$T/LockApp.app"
cp "$T/LockApp" "$T/LockApp.app/LockApp"
python3 - "$T/LockApp.app/Info.plist" <<'PY'
import plistlib, sys
with open(sys.argv[1], "wb") as f:
    plistlib.dump({
        "CFBundleIdentifier": "com.iosim.lockapp",
        "CFBundleExecutable": "LockApp",
        "CFBundleName": "LockApp",
        "CFBundlePackageType": "APPL",
        "CFBundleVersion": "1",
        "CFBundleShortVersionString": "1.0",
    }, f)
PY
"$ROOT/tools/iosimctl" install "$UDID" "$T/LockApp.app" >/dev/null
sleep 0.5
# Twenty-ninth installed app: third page row 0 column 2.
"$ROOT/tools/iosimctl" ui "$UDID" tap 247.2778 121.8333 >/dev/null
if wait_log "[lockapp] ready state=0"; then
    echo "ok   SpringBoard launches the lock fixture"
else
    echo "FAIL lock fixture launch"; fails=$((fails+1))
fi
"$ROOT/tools/iosimctl" ui "$UDID" lock >/dev/null
if wait_log "[lockapp] background state=2"; then
    echo "ok   locking with an app foreground backgrounds the app"
else
    echo "FAIL lock background app"; fails=$((fails+1))
fi
sleep 0.5
"$ROOT/tools/iosimctl" io "$UDID" screenshot "$T/lock-app.png" >/dev/null
if out="$(python3 - "$ROOT/tools" "$T/lock-app.png" <<'PY'
import sys
sys.path.insert(0, sys.argv[1])
import pngpixel
w, h, bpp, rows = pngpixel.load(sys.argv[2])
n = 0
for y in range(115 * 3, 195 * 3):
    for x in range(110 * 3, 290 * 3):
        c = pngpixel.px(rows, bpp, x, y)
        if ((c >> 16) & 255) > 245 and ((c >> 8) & 255) > 245 and \
                (c & 255) > 245:
            n += 1
if n < 20000:
    raise SystemExit("lock clock missing after app lock: %d px" % n)
print("ok   the app-originated lock draws the same lock screen")
PY
)"; then
    echo "$out"
else
    echo "FAIL app lock screen rendering"; echo "$out"; fails=$((fails+1))
fi
"$ROOT/tools/iosimctl" ui "$UDID" unlock >/dev/null
if wait_log "[SpringBoard] resuming LockApp (pid" &&
    wait_log "[lockapp] foreground state=1"; then
    echo "ok   unlocking resumes the same app process"
else
    echo "FAIL unlock app resume"; fails=$((fails+1))
fi
"$ROOT/tools/iosimctl" ui "$UDID" home >/dev/null
sleep 0.4

# ---------- 16. UIRefreshControl pull-to-refresh ----------
# A pull past the threshold over the table arms the refresh control, sends
# ValueChanged, and the spinner stays until the app ends the refresh.
"$ROOT/tools/build_app.sh" "$ROOT/demo/RefreshApp.m" "$T/RefreshApp" >/dev/null
mkdir -p "$T/RefreshApp.app"
cp "$T/RefreshApp" "$T/RefreshApp.app/RefreshApp"
python3 - "$T/RefreshApp.app/Info.plist" <<'PY'
import plistlib, sys
with open(sys.argv[1], "wb") as f:
    plistlib.dump({
        "CFBundleIdentifier": "com.iosim.refresh",
        "CFBundleExecutable": "RefreshApp",
        "CFBundleName": "Refresh",
        "CFBundlePackageType": "APPL",
        "CFBundleVersion": "1",
        "CFBundleShortVersionString": "1.0",
    }, f)
PY
"$ROOT/tools/iosimctl" install "$UDID" "$T/RefreshApp.app" >/dev/null
sleep 0.5
# Thirtieth installed app: third page row 0 column 3.
"$ROOT/tools/iosimctl" ui "$UDID" tap 339.8333 121.8333 >/dev/null
if wait_log "[refresh] ready rows=12"; then
    echo "ok   SpringBoard launches the refresh fixture"
else
    echo "FAIL refresh fixture launch"; fails=$((fails+1))
fi
sleep 0.3
"$ROOT/tools/iosimctl" ui "$UDID" swipe 200 120 200 300 0.4 >/dev/null
if wait_log "[refresh] pulled"; then
    echo "ok   pulling the table past the threshold sends ValueChanged"
else
    echo "FAIL refresh pull"; fails=$((fails+1))
fi
sleep 0.2
"$ROOT/tools/iosimctl" io "$UDID" screenshot "$T/refresh-spinner.png" >/dev/null
if out="$(python3 - "$ROOT/tools" "$T/refresh-spinner.png" <<'PY'
import sys
sys.path.insert(0, sys.argv[1])
import pngpixel
w, h, bpp, rows = pngpixel.load(sys.argv[2])
n = 0
for y in range(62 * 3, 118 * 3):
    for x in range(176 * 3, 226 * 3):
        c = pngpixel.px(rows, bpp, x, y)
        r, g, b = (c >> 16) & 255, (c >> 8) & 255, c & 255
        if r > 60 and g > 60 and b > 60:
            n += 1
if n < 100:
    raise SystemExit("refresh spinner not drawn: %d px" % n)
print("ok   the refresh spinner is drawn while refreshing")
PY
)"; then
    echo "$out"
else
    echo "FAIL refresh spinner rendering"; echo "$out"; fails=$((fails+1))
fi
if wait_log "[refresh] done"; then
    echo "ok   endRefreshing ends the spinner and reports done"
else
    echo "FAIL refresh end"; fails=$((fails+1))
fi
sleep 0.3
"$ROOT/tools/iosimctl" io "$UDID" screenshot "$T/refresh-after.png" >/dev/null
if out="$(python3 - "$ROOT/tools" "$T/refresh-after.png" <<'PY'
import sys
sys.path.insert(0, sys.argv[1])
import pngpixel
w, h, bpp, rows = pngpixel.load(sys.argv[2])
n = 0
for y in range(62 * 3, 118 * 3):
    for x in range(176 * 3, 226 * 3):
        c = pngpixel.px(rows, bpp, x, y)
        r, g, b = (c >> 16) & 255, (c >> 8) & 255, c & 255
        if r > 60 and g > 60 and b > 60:
            n += 1
if n > 10:
    raise SystemExit("spinner still drawn after refresh: %d px" % n)
print("ok   the spinner clears and the table returns to the top")
PY
)"; then
    echo "$out"
else
    echo "FAIL refresh clearing"; echo "$out"; fails=$((fails+1))
fi
"$ROOT/tools/iosimctl" ui "$UDID" home >/dev/null
sleep 0.4

# ---------- 17. launchd socket activation ----------
# A LaunchDaemon with a Sockets dictionary is not started until a client
# connects; launchd keeps the listener and hands its descriptor to the job,
# which fetches it with launch_activate_socket.
obj "$ROOT/tests/launchd_socket_test.c" "$T/launchd_socket.o"
exe "$T/launchd_socket" "$T/launchd_socket.o"
SOCKPATH="/tmp/iosim-sockjob-$UDID.sock"
python3 - "$T/SocketJob.plist" "$T/launchd_socket" "$SOCKPATH" <<'PY'
import plistlib, sys
with open(sys.argv[1], "wb") as f:
    plistlib.dump({
        "Label": "com.iosim.socketjob",
        "ProgramArguments": [sys.argv[2]],
        "Sockets": {
            "MySock": {
                "SockPathName": sys.argv[3],
                "SockType": "stream",
                "SockPassive": True,
            }
        },
    }, f)
PY
"$ROOT/tools/iosimctl" launchd-load "$UDID" "$T/SocketJob.plist" >/dev/null
sleep 0.3
if out="$(python3 - "$SOCKPATH" <<'PY'
import socket, sys
s = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
s.settimeout(10)
s.connect(sys.argv[1])
s.sendall(b"ping")
print(s.recv(64).decode(), end="")
PY
)"; then
    check "pong from socket job" "$out" \
        "a socket connection starts the on-demand job"
else
    echo "FAIL socket activation client"; fails=$((fails+1))
fi
JOBLOG="$IOSIM_HOME/Devices/$UDID/logs/com.iosim.socketjob.log"
if grep -Fq -- "[sockjob] activated rc=0 cnt=1" "$JOBLOG" 2>/dev/null; then
    echo "ok   launch_activate_socket hands the listening descriptor over"
else
    echo "FAIL socket descriptor handoff"; cat "$JOBLOG" 2>/dev/null || true
    fails=$((fails+1))
fi
if grep -Fq -- "[sockjob] got ping" "$JOBLOG" 2>/dev/null; then
    echo "ok   the job reads the request over the inherited socket"
else
    echo "FAIL socket job request"; fails=$((fails+1))
fi
out="$(python3 - "$SOCKPATH" <<'PY'
import socket, sys
s = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
s.settimeout(10)
s.connect(sys.argv[1])
s.sendall(b"ping")
print(s.recv(64).decode(), end="")
PY
)"
check "pong from socket job" "$out" \
    "a second connection reaches a freshly started job"
i=0
while [ "$i" -lt 50 ]; do
    [ "$(grep -Fc -- '[sockjob] activated rc=0 cnt=1' "$JOBLOG" \
        2>/dev/null || echo 0)" -ge 2 ] && break
    sleep 0.1
    i=$((i+1))
done
if [ "$(grep -Fc -- '[sockjob] activated rc=0 cnt=1' "$JOBLOG" \
    2>/dev/null || echo 0)" -ge 2 ]; then
    echo "ok   the next connection starts a new job process"
else
    echo "FAIL socket job restart"; cat "$JOBLOG" 2>/dev/null || true
    fails=$((fails+1))
fi

# ---------- 18. CAAnimationGroup ----------
# One group carries an opacity and a corner-radius animation; the presentation
# layer shows both interpolating together, both hold the end values and
# removeAnimationForKey: clears every expanded child.
"$ROOT/tools/build_app.sh" "$ROOT/demo/AnimationGroupApp.m" \
    "$T/AnimationGroupApp" >/dev/null
mkdir -p "$T/AnimationGroupApp.app"
cp "$T/AnimationGroupApp" "$T/AnimationGroupApp.app/AnimationGroupApp"
python3 - "$T/AnimationGroupApp.app/Info.plist" <<'PY'
import plistlib, sys
with open(sys.argv[1], "wb") as f:
    plistlib.dump({
        "CFBundleIdentifier": "com.iosim.animgroup",
        "CFBundleExecutable": "AnimationGroupApp",
        "CFBundleName": "AnimGroup",
        "CFBundlePackageType": "APPL",
        "CFBundleVersion": "1",
        "CFBundleShortVersionString": "1.0",
    }, f)
PY
"$ROOT/tools/iosimctl" install "$UDID" "$T/AnimationGroupApp.app" >/dev/null
sleep 0.5
# Thirty-first installed app: third page row 1 column 0.
"$ROOT/tools/iosimctl" ui "$UDID" tap 62.1667 222.1667 >/dev/null
if wait_log "[group] started"; then
    echo "ok   SpringBoard launches the animation group fixture"
else
    echo "FAIL animation group launch"; fails=$((fails+1))
fi
if wait_log "[group] mid"; then
    line="$(grep -F -- '[group] mid' "$SBLOG" | tail -1)"
    if out="$(python3 - "$line" <<'PY'
import re, sys
m = re.search(r"opacity=([0-9.]+) radius=([0-9.]+)", sys.argv[1])
if not m:
    raise SystemExit("unparsable midpoint: %s" % sys.argv[1])
op, rad = float(m.group(1)), float(m.group(2))
if not (0.45 <= op <= 0.75):
    raise SystemExit("midpoint opacity out of range: %.2f" % op)
if not (11.0 <= rad <= 19.0):
    raise SystemExit("midpoint radius out of range: %.2f" % rad)
print("ok   the group animates opacity and corner radius together")
PY
)"; then
        echo "$out"
    else
        echo "FAIL animation group midpoint"; echo "$out"; fails=$((fails+1))
    fi
else
    echo "FAIL animation group midpoint log"; fails=$((fails+1))
fi
if wait_log "[group] end" &&
    grep -Fq -- "[group] end opacity=0.20 radius=30.00" "$SBLOG"; then
    echo "ok   both group children hold their end values"
else
    echo "FAIL animation group end"; fails=$((fails+1))
fi
sleep 0.2
"$ROOT/tools/iosimctl" io "$UDID" screenshot "$T/group-end.png" >/dev/null
if out="$(python3 - "$ROOT/tools" "$T/group-end.png" <<'PY'
import sys
sys.path.insert(0, sys.argv[1])
import pngpixel
w, h, bpp, rows = pngpixel.load(sys.argv[2])
center = pngpixel.px(rows, bpp, 201 * 3, 300 * 3)
corner = pngpixel.px(rows, bpp, 105 * 3, 205 * 3)
r, g, b = (center >> 16) & 255, (center >> 8) & 255, center & 255
if not (40 <= r <= 90 and 10 <= g <= 45 and 15 <= b <= 60):
    raise SystemExit("layer end alpha not blended: %06x" % center)
cr, cg, cb = (corner >> 16) & 255, (corner >> 8) & 255, corner & 255
if not (cr < 30 and cg < 35 and cb < 60):
    raise SystemExit("corner still square: %06x" % corner)
print("ok   the rendered layer is dimmed and rounded")
PY
)"; then
    echo "$out"
else
    echo "FAIL animation group rendering"; echo "$out"; fails=$((fails+1))
fi
if wait_log "[group] removed" &&
    grep -Fq -- "[group] removed opacity=1.00 radius=0.00" "$SBLOG"; then
    echo "ok   removeAnimationForKey: clears every group child"
else
    echo "FAIL animation group removal"; fails=$((fails+1))
fi
sleep 0.3
"$ROOT/tools/iosimctl" io "$UDID" screenshot "$T/group-removed.png" >/dev/null
if out="$(python3 - "$ROOT/tools" "$T/group-removed.png" <<'PY'
import sys
sys.path.insert(0, sys.argv[1])
import pngpixel
w, h, bpp, rows = pngpixel.load(sys.argv[2])
center = pngpixel.px(rows, bpp, 201 * 3, 300 * 3)
corner = pngpixel.px(rows, bpp, 105 * 3, 205 * 3)
for name, c in (("center", center), ("corner", corner)):
    r, g, b = (c >> 16) & 255, (c >> 8) & 255, c & 255
    if not (r > 220 and g < 90 and b < 80):
        raise SystemExit("%s not full red after removal: %06x" %
                         (name, c))
print("ok   the layer returns to its model color and square corners")
PY
)"; then
    echo "$out"
else
    echo "FAIL animation group revert"; echo "$out"; fails=$((fails+1))
fi
"$ROOT/tools/iosimctl" ui "$UDID" home >/dev/null
sleep 0.4

# ---------- 19. UIVisualEffectView backdrop blur ----------
# A blur card over black/white stripes captures its backdrop, box-blurs it
# with a dark tint, keeps the rounded corners sharp and draws its content on
# top.
"$ROOT/tools/build_app.sh" "$ROOT/demo/BlurApp.m" "$T/BlurApp" >/dev/null
mkdir -p "$T/BlurApp.app"
cp "$T/BlurApp" "$T/BlurApp.app/BlurApp"
python3 - "$T/BlurApp.app/Info.plist" <<'PY'
import plistlib, sys
with open(sys.argv[1], "wb") as f:
    plistlib.dump({
        "CFBundleIdentifier": "com.iosim.blur",
        "CFBundleExecutable": "BlurApp",
        "CFBundleName": "Blur",
        "CFBundlePackageType": "APPL",
        "CFBundleVersion": "1",
        "CFBundleShortVersionString": "1.0",
    }, f)
PY
"$ROOT/tools/iosimctl" install "$UDID" "$T/BlurApp.app" >/dev/null
sleep 0.5
# Thirty-second installed app: third page row 1 column 1.
"$ROOT/tools/iosimctl" ui "$UDID" tap 154.7222 222.1667 >/dev/null
if wait_log "[blur] ready stripes=16"; then
    echo "ok   SpringBoard launches the blur fixture"
else
    echo "FAIL blur fixture launch"; fails=$((fails+1))
fi
sleep 0.4
"$ROOT/tools/iosimctl" io "$UDID" screenshot "$T/blur.png" >/dev/null
if out="$(python3 - "$ROOT/tools" "$T/blur.png" <<'PY'
import sys
sys.path.insert(0, sys.argv[1])
import pngpixel
w, h, bpp, rows = pngpixel.load(sys.argv[2])

def px(x, y):
    return pngpixel.px(rows, bpp, x * 3, y * 3)

def channels(c):
    return ((c >> 16) & 255, (c >> 8) & 255, c & 255)

white_out = channels(px(12, 420))
black_out = channels(px(37, 420))
if not all(v > 230 for v in white_out):
    raise SystemExit("sharp white stripe missing: %r" % (white_out,))
if not all(v < 30 for v in black_out):
    raise SystemExit("sharp black stripe missing: %r" % (black_out,))
a = channels(px(60, 420))
b = channels(px(85, 420))
for name, c in (("a", a), ("b", b)):
    if not all(40 <= v <= 130 for v in c):
        raise SystemExit("blurred stripe %s out of range: %r" % (name, c))
if any(abs(a[i] - b[i]) > 30 for i in range(3)):
    raise SystemExit("blurred stripes not blended: %r vs %r" % (a, b))
corner = channels(px(46, 256))
if not all(v < 30 for v in corner):
    raise SystemExit("rounded corner not left sharp: %r" % (corner,))
label = 0
for y in range(332 * 3, 368 * 3):
    for x in range(120 * 3, 282 * 3):
        c = pngpixel.px(rows, bpp, x, y)
        if ((c >> 16) & 255) > 245 and ((c >> 8) & 255) > 245 and \
                (c & 255) > 245:
            label += 1
if label < 200:
    raise SystemExit("vibrancy label not over the blur: %d px" % label)
print("ok   the card blurs its backdrop and draws its content above it")
PY
)"; then
    echo "$out"
else
    echo "FAIL blur rendering"; echo "$out"; fails=$((fails+1))
fi
"$ROOT/tools/iosimctl" ui "$UDID" home >/dev/null
sleep 0.4

"$ROOT/tools/iosimctl" shutdown "$UDID" >/dev/null

# ---------- 20. kernel symbolication tool ----------
"$CC" -target "$TARGET" -ffreestanding -O1 \
    -c "$ROOT/tests/kernel_symbols_fixture.c" -o "$T/ks_fixture.o"
"$LD64" -arch x86_64 -platform_version $PLATFORM -no_pie -e _main \
    -o "$T/ks_fixture" "$T/ks_fixture.o"
KS="$ROOT/tools/kernel_symbols.py"
summary="$(python3 -I "$KS" --binary "$T/ks_fixture" --summary)"
check "symbols       8 binary" "$summary" \
    "the Mach-O reader inventories exported and local symbols"
check "text coverage 100.000%" "$summary" \
    "merged text symbols cover the executable section"
traps="$(python3 -I "$KS" --binary "$T/ks_fixture" --mach-traps)"
check "mach traps: 2 entries, layout stride 24" "$traps" \
    "the mach trap table layout is detected"
check "  0  _trap_alpha" "$traps" "trap 0 resolves to its handler"
check "args=2" "$traps" "trap argument count comes from the info word"
check "  1  _trap_beta" "$traps" "trap 1 resolves to its handler"
syscalls="$(python3 -I "$KS" --binary "$T/ks_fixture" --syscalls)"
check "syscalls: 2 entries, layout stride 24" "$syscalls" \
    "the syscall table layout is detected"
check "  1  _trap_beta" "$syscalls" "syscall 1 resolves to its handler"
check "narg=2" "$syscalls" "syscall argument count is read from the entry"
python3 -I "$KS" --binary "$T/ks_fixture" --write-map "$T/ks.symbols"
map="$(cat "$T/ks.symbols")"
check " T _main" "$map" "--write-map emits a complete address-ordered map"
check " t _trap_alpha" "$map" "local text symbols are in the map"
ADDR="$(awk '$3=="_trap_beta"{print $1; exit}' "$T/ks.symbols")"
sym="$(python3 -I "$KS" --binary "$T/ks_fixture" \
    --symbolize "0x$ADDR" "0x$(printf '%x' $((0x$ADDR + 8)))")"
check "_trap_beta  [" "$sym" "an exact address prints its symbol"
check "_trap_beta + 0x8" "$sym" "an interior address prints a relative offset"

# ---------- 21. loader runtime: initializers, TLV, pthread, crypto, signals ----------
"$CC" -target "$TARGET" -ffreestanding -fblocks -O1 \
    -c "$ROOT/tests/loader_runtime_test.c" -o "$T/loader_runtime.o"
"$LD64" -arch x86_64 -platform_version $PLATFORM -e _main \
    -o "$T/loader_runtime" "$T/loader_runtime.o" -undefined dynamic_lookup
rm -f "$T/loader-stat-file"
out="$(DYLD_ROOT_PATH="$ROOT/runtime" "$RUN" "$T/loader_runtime" \
    "$T/loader-stat-file" 2>&1)"
check "[lrt] ctor 1 tls 42" "$out" \
    "__init_offsets constructors run and __thread_data is copied per thread"
check "[lrt] mutex normalized" "$out" \
    "a Darwin PTHREAD_MUTEX_INITIALIZER is host-normalized at load"
check "[lrt] lock 0 0" "$out" \
    "the normalized static mutex locks and unlocks through the guest API"
check "[lrt] sha256 ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad" \
    "$out" "CommonCrypto SHA-256 matches the abc vector"
check "[lrt] md5 900150983cd24fb0d6963f7d28e17f72" "$out" \
    "CommonCrypto MD5 matches the abc vector"
check "[lrt] data 13 1 13" "$out" \
    "dispatch_data size and block application report the payload"
check "[lrt] sigmask 0 old 0" "$out" \
    "Darwin SIG_SETMASK value is translated for pthread_sigmask"
check "[lrt] stat 0 1 3" "$out" \
    'Darwin stat$INODE64 layout reports mode and size of a written file'

# ---------- 22. key-value coding and automatic key-value observing ----------
"$CC" -target "$TARGET" -fobjc-runtime=ios-18.0 -fno-objc-arc \
    -ffreestanding -O1 -I "$ROOT/frameworks" \
    -c "$ROOT/tests/kvc_kvo_test.m" -o "$T/kvc_kvo_test.o"
"$LD64" -arch x86_64 -platform_version $PLATFORM -e _main \
    -o "$T/kvc_kvo_test" "$T/kvc_kvo_test.o" \
    "$ROOT/runtime/System/Library/Frameworks/Foundation.framework/Foundation" \
    -undefined dynamic_lookup
out="$(DYLD_ROOT_PATH="$ROOT/runtime" "$RUN" "$T/kvc_kvo_test" 2>&1)"
check "[kvc] get alice 30" "$out" \
    "valueForKey: finds getters and boxes scalar returns"
check "[kvc] set bob 41" "$out" \
    "setValue:forKey: finds setters and unboxes NSNumber arguments"
check "[kvc] path Main" "$out" \
    "key paths traverse object properties"
check "[kvc] dict bob 41" "$out" \
    "dictionaryWithValuesForKeys: returns one value per key"
check "[kvo] name old=bob new=carol" "$out" \
    "automatic KVO wraps an object setter and reports old and new"
check "[kvo] name old=carol new=dave" "$out" \
    "KVC writes go through the KVO setter as well"
check "[kvo] age old=unset new=41" "$out" \
    "initial observations fire with the current scalar value"
check "[kvo] age old=unset new=42" "$out" \
    "automatic KVO wraps an int setter"
check "[kvo] count 2 initial 2" "$out" \
    "each observer receives exactly its own notifications"
check "[kvo] after-remove count 2 name erin" "$out" \
    "removeObserver: stops notifications but setters still work"

# ---------- 23. libdispatch source timers and data ----------
"$CC" -target "$TARGET" -fobjc-runtime=ios-18.0 -fno-objc-arc \
    -ffreestanding -O1 -I "$ROOT/frameworks" \
    -c "$ROOT/tests/dispatch_source_test.m" -o "$T/dispatch_source_test.o"
"$LD64" -arch x86_64 -platform_version $PLATFORM -e _main \
    -o "$T/dispatch_source_test" "$T/dispatch_source_test.o" \
    "$ROOT/runtime/System/Library/Frameworks/Foundation.framework/Foundation" \
    -undefined dynamic_lookup
out="$(DYLD_ROOT_PATH="$ROOT/runtime" "$RUN" "$T/dispatch_source_test" 2>&1)"
check "[src] timer ok" "$out" \
    "a repeating timer source fires on the main queue while the run loop runs"
check "[src] canceled 1 1 1" "$out" \
    "cancel stops the timer and runs the cancel handler exactly once"
check "[src] context 7" "$out" \
    "dispatch_set_context reaches a 2-argument source handler"
check "[src] data 1 7" "$out" \
    "two merged data-add values coalesce into one event"
check "[src] data 2 7" "$out" \
    "dispatch_source_get_data clears the merged value for the next event"

# ---------- 24. UIScrollView insets, paging and delegate callbacks ----------
"$ROOT/tools/build_app.sh" "$ROOT/tests/scroll_view_test.m" \
    "$T/scroll_view_test" >/dev/null
out="$(DYLD_ROOT_PATH="$ROOT/runtime" SIMULATOR_MAINSCREEN_WIDTH=390 \
    SIMULATOR_MAINSCREEN_HEIGHT=844 SIMULATOR_MAINSCREEN_SCALE=1 \
    "$RUN" "$T/scroll_view_test" 2>&1)"
check "[scroll] target 310 0" "$out" \
    "the delegate sees the paged target offset before the drag ends"
check "[scroll] page 310 dragging 0" "$out" \
    "paging snaps to the nearest page and clears the dragging state"
check "[scroll] delegate 1 3 1 1" "$out" \
    "begin, scroll, will-end and did-end callbacks each fire"
check "[scroll] vertical 820 top 50" "$out" \
    "contentInset bounds the vertical offset and reads back to the delegate"

# ---------- 25. UITextField delegates and UIView geometry ----------
"$ROOT/tools/build_app.sh" "$ROOT/tests/textfield_delegate_test.m" \
    "$T/textfield_delegate_test" >/dev/null
out="$(DYLD_ROOT_PATH="$ROOT/runtime" "$RUN" "$T/textfield_delegate_test" 2>&1)"
check "[tf] text [a] began 1 ended 1 changes 4 returns 1" "$out" \
    "text field begin/end and change veto callbacks drive editing and Return"

"$ROOT/tools/build_app.sh" "$ROOT/tests/uiview_geometry_test.m" \
    "$T/uiview_geometry_test" >/dev/null
out="$(DYLD_ROOT_PATH="$ROOT/runtime" "$RUN" "$T/uiview_geometry_test" 2>&1)"
check "[geo] center 60 45" "$out" \
    "UIView center derives from the frame"
check "[geo] centered 50 75" "$out" \
    "setCenter moves the frame origin"
check "[geo] bounds 50 75 120 60 center 110 105" "$out" \
    "setBounds changes the size while keeping the origin"
check "[geo] to parent 55 80" "$out" \
    "convertPoint:toView: crosses one superview"
check "[geo] to root 75 110" "$out" \
    "convertPoint:toView: crosses two superviews"
check "[geo] from root -35 -50" "$out" \
    "convertPoint:fromView: is the inverse translation"
check "[geo] rect 75 110 100 50" "$out" \
    "convertRect:toView: converts the origin and keeps the size"
check "[geo] scroll -4 -13" "$out" \
    "conversion subtracts a scroll ancestor contentOffset"
check "[geo] scroll root -4 87" "$out" \
    "conversion composes scroll offset and frame origins"

# ---------- 26. CALayer position, anchorPoint and bounds ----------
"$ROOT/tools/build_app.sh" "$ROOT/tests/calayer_geometry_test.m" \
    "$T/calayer_geometry_test" >/dev/null
out="$(DYLD_ROOT_PATH="$ROOT/runtime" "$RUN" "$T/calayer_geometry_test" 2>&1)"
check "[layer] position 60 45" "$out" \
    "CALayer position is the frame origin plus the default anchor"
check "[layer] setposition 50 75" "$out" \
    "setPosition moves the frame origin"
check "[layer] anchor 100 100 pos 100 100" "$out" \
    "setAnchorPoint preserves position and recomputes the frame"
check "[layer] bounds 100 100 120 60 pos 100 100" "$out" \
    "setBounds changes size around the anchor"

# ---------- 27. KVC collection operators ----------
"$CC" -target "$TARGET" -fobjc-runtime=ios-18.0 -fno-objc-arc \
    -ffreestanding -O1 -I "$ROOT/frameworks" \
    -c "$ROOT/tests/kvc_operators_test.m" -o "$T/kvc_operators_test.o"
"$LD64" -arch x86_64 -platform_version $PLATFORM -e _main \
    -o "$T/kvc_operators_test" "$T/kvc_operators_test.o" \
    "$ROOT/runtime/System/Library/Frameworks/Foundation.framework/Foundation" \
    -undefined dynamic_lookup
out="$(DYLD_ROOT_PATH="$ROOT/runtime" "$RUN" "$T/kvc_operators_test" 2>&1)"
check "[kvcop] numbers 4 10 2.5 4 1" "$out" \
    "@count/@sum/@avg/@max/@min over boxed numbers"
check "[kvcop] prices 40 13.3 25 5" "$out" \
    "collection operators apply the trailing key path to each object"
check "[kvcop] categories 2 a b" "$out" \
    "@distinctUnionOfObjects.category keeps first-seen order"
check "[kvcop] union 4 distinct 3" "$out" \
    "@unionOfArrays flattens while @distinctUnionOfArrays removes duplicates"
check "[kvcop] dict 10" "$out" \
    "NSDictionary valueForKey: maps to objectForKey:"

# ---------- 28. NSURLSession over the host HTTP client ----------
HTTP_ROOT="$T/http-root"
mkdir -p "$HTTP_ROOT"
printf 'hello over http\n' > "$HTTP_ROOT/hello.txt"
python3 -u -m http.server 0 --bind 127.0.0.1 --directory "$HTTP_ROOT" \
    > "$T/http.log" 2>&1 &
HTTP_PID=$!
HTTP_PORT=""
i=0
while [ "$i" -lt 100 ]; do
    HTTP_PORT=$(sed -n 's/.*port \([0-9][0-9]*\).*/\1/p' "$T/http.log" | head -1)
    [ -n "$HTTP_PORT" ] && break
    i=$((i + 1))
    sleep 0.05
done
openssl req -x509 -newkey rsa:2048 -nodes -keyout "$T/tls-key.pem" \
    -out "$T/tls-cert.pem" -days 1 -subj /CN=127.0.0.1 >/dev/null 2>&1
python3 -u "$ROOT/tests/tls_http_server.py" "$HTTP_ROOT" \
    "$T/tls-cert.pem" "$T/tls-key.pem" > "$T/tls.log" 2>&1 &
TLS_PID=$!
TLS_PORT=""
i=0
while [ "$i" -lt 100 ]; do
    TLS_PORT=$(sed -n 's/.*port \([0-9][0-9]*\).*/\1/p' "$T/tls.log" | head -1)
    [ -n "$TLS_PORT" ] && break
    i=$((i + 1))
    sleep 0.05
done
if [ -z "$HTTP_PORT" ] || [ -z "$TLS_PORT" ]; then
    echo "FAIL loopback HTTP/TLS servers did not start"
    fails=$((fails + 1))
else
    "$CC" -target "$TARGET" -fobjc-runtime=ios-18.0 -fno-objc-arc \
        -fblocks -ffreestanding -O1 -I "$ROOT/frameworks" \
        -c "$ROOT/tests/urlsession_test.m" -o "$T/urlsession_test.o"
    "$LD64" -arch x86_64 -platform_version $PLATFORM -e _main \
        -o "$T/urlsession_test" "$T/urlsession_test.o" \
        "$ROOT/runtime/System/Library/Frameworks/Foundation.framework/Foundation" \
        -undefined dynamic_lookup
    out="$(IOSIM_TLS_INSECURE=1 DYLD_ROOT_PATH="$ROOT/runtime" \
        "$RUN" "$T/urlsession_test" \
        "$HTTP_PORT" "$TLS_PORT" 2>&1)"
    check "[http] status 200" "$out" \
        "NSURLSessionDataTask completes with the HTTP status"
    check "[http] body hello over http" "$out" \
        "the response body is delivered as NSData"
    check "[http] header text/plain" "$out" \
        "response headers populate allHeaderFields"
    check "[https] status 200" "$out" \
        "NSURLSession completes an HTTPS request over TLS"
    check "[https] body hello over http" "$out" \
        "the HTTPS response body is delivered as NSData"
    check "[https] done 1" "$out" \
        "the HTTPS completion handler runs"
    check "[http] error -1004" "$out" \
        "an unsupported scheme completes with an NSError"
    check "[http] done 1" "$out" \
        "the completion handler runs on a background queue"
fi
kill "$HTTP_PID" "$TLS_PID" 2>/dev/null || true
wait "$HTTP_PID" "$TLS_PID" 2>/dev/null || true

# ---------- 29. UIScrollView momentum and animated offsets ----------
"$ROOT/tools/build_app.sh" "$ROOT/tests/scroll_deceleration_test.m" \
    "$T/scroll_deceleration_test" >/dev/null
out="$(DYLD_ROOT_PATH="$ROOT/runtime" "$RUN" \
    "$T/scroll_deceleration_test" 2>&1)"
check "[scroll] released decel=1 will=1 offset=300" "$out" \
    "a fast release starts deceleration and reports willDecelerate:YES"
check "[scroll] decelerated end=1 moved=1" "$out" \
    "momentum advances the offset and ends with didEndDecelerating"
check "[scroll] animating mid=1 end=1 offset=200 animend=1" "$out" \
    "setContentOffset:animated: eases to its target and reports completion"

# ---------- 30. NSSortDescriptor and array sorting ----------
"$CC" -target "$TARGET" -fobjc-runtime=ios-18.0 -fno-objc-arc \
    -ffreestanding -O1 -I "$ROOT/frameworks" \
    -c "$ROOT/tests/sorting_test.m" -o "$T/sorting_test.o"
"$LD64" -arch x86_64 -platform_version $PLATFORM -e _main \
    -o "$T/sorting_test" "$T/sorting_test.o" \
    "$ROOT/runtime/System/Library/Frameworks/Foundation.framework/Foundation" \
    -undefined dynamic_lookup
out="$(DYLD_ROOT_PATH="$ROOT/runtime" "$RUN" "$T/sorting_test" 2>&1)"
check "[sort] strings apple fig pear" "$out" \
    "sortedArrayUsingSelector: orders strings with compare:"
check "[sort] numbers 1 2 3" "$out" \
    "a key-less descriptor sorts boxed numbers"
check "[sort] names Amy Bob Cara prices 25 10 5" "$out" \
    "descriptors sort dictionaries by key with a descending tie-breaker"
check "[sort] ages 18 30 41" "$out" \
    "a custom selector comparator sorts model objects"
check "[sort] swapped 2 1" "$out" \
    "exchangeObjectAtIndex:withObjectAtIndex: swaps in place"
check "[sort] ci 0" "$out" \
    "caseInsensitiveCompare: folds ASCII case"

# ---------- 31. NSScanner ----------
"$CC" -target "$TARGET" -fobjc-runtime=ios-18.0 -fno-objc-arc \
    -ffreestanding -O1 -I "$ROOT/frameworks" \
    -c "$ROOT/tests/scanner_test.m" -o "$T/scanner_test.o"
"$LD64" -arch x86_64 -platform_version $PLATFORM -e _main \
    -o "$T/scanner_test" "$T/scanner_test.o" \
    "$ROOT/runtime/System/Library/Frameworks/Foundation.framework/Foundation" \
    -undefined dynamic_lookup
out="$(DYLD_ROOT_PATH="$ROOT/runtime" "$RUN" "$T/scanner_test" 2>&1)"
check "[scan] int=1 value=42 at=2" "$out" \
    "scanInt: parses a number and advances the scan location"
check "[scan] double=1 value=-3.5" "$out" \
    "scanDouble: parses signed fractions"
check "[scan] up=1 word=name" "$out" \
    "scanUpToString: stops before the terminator"
check "[scan] equals=1" "$out" \
    "scanString: matches literal text"
check "[scan] value=1" "$out" \
    "scanString: advances past the matched text"
check "[scan] rest=1 string=rest end=1" "$out" \
    "scanning to the end reports isAtEnd"

# ---------- 32. NSPredicate and array filtering ----------
"$CC" -target "$TARGET" -fobjc-runtime=ios-18.0 -fno-objc-arc \
    -ffreestanding -O1 -I "$ROOT/frameworks" \
    -c "$ROOT/tests/predicate_test.m" -o "$T/predicate_test.o"
"$LD64" -arch x86_64 -platform_version $PLATFORM -e _main \
    -o "$T/predicate_test" "$T/predicate_test.o" \
    "$ROOT/runtime/System/Library/Frameworks/Foundation.framework/Foundation" \
    -undefined dynamic_lookup
out="$(DYLD_ROOT_PATH="$ROOT/runtime" "$RUN" "$T/predicate_test" 2>&1)"
check "[pred] contains=1" "$out" \
    "NSPredicate evaluates AND plus CONTAINS on key paths"
check "[pred] notor=3" "$out" \
    "NOT and OR compose with correct precedence"
check "[pred] like=1" "$out" \
    "LIKE matches wildcard patterns"
check "[pred] range=2" "$out" \
    "numeric range comparisons filter records"
check "[pred] in=2" "$out" \
    "IN matches against an array literal"
check "[pred] nonnil=3" "$out" \
    "comparison against nil uses key-path existence"
check "[pred] self=1" "$out" \
    "SELF binds the evaluated object"
check "[pred] filtered=1" "$out" \
    "filterUsingPredicate: compacts a mutable array in place"
check "[pred] true=1 false=0" "$out" \
    "predicateWithValue: creates constant predicates"

# ---------- 33. NSRegularExpression ----------
"$CC" -target "$TARGET" -fobjc-runtime=ios-18.0 -fno-objc-arc \
    -ffreestanding -O1 -I "$ROOT/frameworks" \
    -c "$ROOT/tests/regex_test.m" -o "$T/regex_test.o"
"$LD64" -arch x86_64 -platform_version $PLATFORM -e _main \
    -o "$T/regex_test" "$T/regex_test.o" \
    "$ROOT/runtime/System/Library/Frameworks/Foundation.framework/Foundation" \
    -undefined dynamic_lookup
out="$(DYLD_ROOT_PATH="$ROOT/runtime" "$RUN" "$T/regex_test" 2>&1)"
check "[regex] matches=2 groups=2" "$out" \
    "matchesInString: returns every match and captures groups"
check "[regex] first 0 7 abc 123" "$out" \
    "the whole match and capture ranges slice the source string"
check "[regex] second xyz" "$out" \
    "subsequent matches retain their own capture groups"
check "[regex] digits=3 third=8,3" "$out" \
    "a digit escape matches all number runs with byte ranges"
check "[regex] ci=1" "$out" \
    "NSRegularExpressionCaseInsensitive folds case at creation"
check "[regex] replace=a<1>b<22>" "$out" \
    "template replacement expands \$1 capture references"

# ---------- 34. CoreGraphics and the UIView drawRect: bridge ----------
"$ROOT/tools/build_app.sh" "$ROOT/tests/coregraphics_test.m" \
    "$T/coregraphics_test" >/dev/null
out="$(DYLD_ROOT_PATH="$ROOT/runtime" "$RUN" "$T/coregraphics_test" 2>&1)"
check "[cg] rect ff0000" "$out" \
    "CGContextFillRect paints a rectangle"
check "[cg] ellipse 00ff00" "$out" \
    "CGContextFillEllipseInRect paints an ellipse"
check "[cg] stroke 0000f4" "$out" \
    "CGContextStrokeRect strokes with the stroke color"
check "[cg] path ffff00" "$out" \
    "a move/line path fills as a polygon"
check "[cg] translate 0000ff" "$out" \
    "graphics-state translation moves subsequent drawing"
check "[cg] cgpath ff00ff" "$out" \
    "CGContextAddPath fills a CGPath rectangle"
check "[cg] cgpath elements 5" "$out" \
    "CGPathApply visits a move, three lines and a close"
check "[cg] released 0" "$out" \
    "CGPathRelease invalidates the path"
check "[cg] cgcolor alpha 1.00 equal 1 red 0.5 valid 1" "$out" \
    "UIColor CGColor round-trips components through CoreGraphics"
check "[cg] uicolor 8000ff" "$out" \
    "CGContextSetFillColorWithColor fills with a UIColor-derived color"
check "[cg] cgimage 2 2 valid 1" "$out" \
    "CGImageCreateWithRGBA reports its dimensions"
check "[cg] cgimage draw ffff00" "$out" \
    "CGContextDrawImage scales a CGImage into a rectangle"
check "[cg] clip 00ff00" "$out" \
    "CGContextClipToRect limits fills to the clip rectangle"
check "[cg] clip outside ff0000" "$out" \
    "pixels outside the clip rectangle keep their earlier color"
check "[cg] clip restored 0000ff" "$out" \
    "restoring the graphics state removes the clip"

"$ROOT/tools/build_app.sh" "$ROOT/tests/cgimage_layer_test.m" \
    "$T/cgimage_layer_test" >/dev/null
out="$(IOSIM_TEST_PNG="$T/cgimage_layer.png" DYLD_ROOT_PATH="$ROOT/runtime" \
    "$RUN" "$T/cgimage_layer_test" 2>&1)"
check "[cg] layer png written" "$out" \
    "a CALayer with CGImage contents renders and captures a frame"
if out="$(python3 - "$ROOT/tools" "$T/cgimage_layer.png" <<'PY'
import sys
sys.path.insert(0, sys.argv[1])
import pngpixel
w, h, bpp, rows = pngpixel.load(sys.argv[2])

def px(x, y):
    return pngpixel.px(rows, bpp, x * 3, y * 3)

r, g, b = (lambda c: ((c >> 16) & 255, (c >> 8) & 255, c & 255))(px(60, 150))
if not (g > 220 and b > 220 and r < 60):
    raise SystemExit("CGImage layer contents not visible: %02x%02x%02x" % (r, g, b))
r, g, b = (lambda c: ((c >> 16) & 255, (c >> 8) & 255, c & 255))(px(20, 20))
if not (r < 40 and g < 40 and b < 60):
    raise SystemExit("background outside layer changed: %02x%02x%02x" % (r, g, b))
print("ok   CALayer CGImage contents appear at the layer frame:")
PY
)"; then
    echo "$out"
else
    echo "FAIL CALayer CGImage contents"; echo "$out"; fails=$((fails+1))
fi

"$ROOT/tools/build_app.sh" "$ROOT/tests/draw_rect_test.m" \
    "$T/draw_rect_test" >/dev/null
out="$(IOSIM_TEST_PNG="$T/draw_rect.png" DYLD_ROOT_PATH="$ROOT/runtime" \
    "$RUN" "$T/draw_rect_test" 2>&1)"
check "[draw] rect painted" "$out" \
    "a custom UIView receives drawRect: through the renderer"
check "written to $T/draw_rect.png" "$out" \
    "the drawRect: fixture writes its framebuffer"
if out="$(python3 - "$ROOT/tools" "$T/draw_rect.png" <<'PY'
import sys
sys.path.insert(0, sys.argv[1])
import pngpixel
w, h, bpp, rows = pngpixel.load(sys.argv[2])

def px(x, y):
    return pngpixel.px(rows, bpp, x * 3, y * 3)

r, g, b = (lambda c: ((c >> 16) & 255, (c >> 8) & 255, c & 255))(px(60, 180))
if not (r > 200 and g < 80 and b < 80):
    raise SystemExit("CGContextFillRect not visible: %02x%02x%02x" % (r, g, b))
r, g, b = (lambda c: ((c >> 16) & 255, (c >> 8) & 255, c & 255))(px(250, 190))
if not (g > 180 and r < 80):
    raise SystemExit("CGContextFillEllipseInRect not visible: %02x%02x%02x" % (r, g, b))
r, g, b = (lambda c: ((c >> 16) & 255, (c >> 8) & 255, c & 255))(px(20, 300))
if not (b > 220 and r < 80):
    raise SystemExit("CGContextStrokeRect not visible: %02x%02x%02x" % (r, g, b))
r, g, b = (lambda c: ((c >> 16) & 255, (c >> 8) & 255, c & 255))(px(90, 455))
if not (r > 240 and g > 180 and b < 60):
    raise SystemExit("CGContextFillPath not visible: %02x%02x%02x" % (r, g, b))
print("ok   CoreGraphics fills, strokes and paths render through drawRect:")
PY
)"; then
    echo "$out"
else
    echo "FAIL CoreGraphics drawRect"; echo "$out"; fails=$((fails+1))
fi

# ---------- 35. UIGraphics image contexts ----------
"$ROOT/tools/build_app.sh" "$ROOT/tests/uigraphics_test.m" \
    "$T/uigraphics_test" >/dev/null
out="$(DYLD_ROOT_PATH="$ROOT/runtime" "$RUN" "$T/uigraphics_test" 2>&1)"
check "[uig] size 20 20 red 255 0 0 255" "$out" \
    "UIGraphicsBeginImageContextWithOptions renders at the requested scale"
check "[uig] drawn 255 0 0 255" "$out" \
    "UIImage drawInRect: composites into another image context"
check "[uig] cgimage 20 20 255 0 0 255" "$out" \
    "UIImage CGImage and imageWithCGImage: round-trip pixels"
check "[uig] restored 1" "$out" \
    "ending a nested image context restores the previous context"
check "[uig] pushed 1" "$out" \
    "UIGraphicsPushContext makes a requested context current"
check "[uig] pushed image 255 0 0 255" "$out" \
    "drawing through a pushed context extracts that context's image"
check "[uig] popped 1" "$out" \
    "UIGraphicsPopContext restores the replaced context"

# ---------- 36. CASpringAnimation ----------
"$ROOT/tools/build_app.sh" "$ROOT/tests/spring_animation_test.m" \
    "$T/spring_animation_test" >/dev/null
out="$(DYLD_ROOT_PATH="$ROOT/runtime" "$RUN" "$T/spring_animation_test" 2>&1)"
check "[spring] settling 0.53" "$out" \
    "CASpringAnimation derives a settling duration from its spring constants"
check "[spring] early 1 late 1" "$out" \
    "a spring animates the layer through intermediate values and settles"

# ---------- 37. NSString drawing ----------
"$ROOT/tools/build_app.sh" "$ROOT/tests/text_drawing_test.m" \
    "$T/text_drawing_test" >/dev/null
out="$(IOSIM_TEST_PNG="$T/text_drawing.png" DYLD_ROOT_PATH="$ROOT/runtime" \
    "$RUN" "$T/text_drawing_test" 2>&1)"
check "[text] size 1 1" "$out" \
    "NSString sizeWithAttributes: measures a bold system-font string"
check "[text] bounds 1 1" "$out" \
    "NSString boundingRectWithSize: measures a wrapped paragraph"
check "[text] wrote png" "$out" \
    "NSString drawAtPoint: renders through the drawRect: context"
if out="$(python3 - "$ROOT/tools" "$T/text_drawing.png" <<'PY'
import sys
sys.path.insert(0, sys.argv[1])
import pngpixel
w, h, bpp, rows = pngpixel.load(sys.argv[2])

def light_pixels(x0, x1, y0, y1):
    count = 0
    for y in range(y0 * 3, y1 * 3):
        for x in range(x0 * 3, x1 * 3):
            c = pngpixel.px(rows, bpp, x, y)
            r, g, b = ((c >> 16) & 255), ((c >> 8) & 255), (c & 255)
            if r > 100 and g > 100 and b > 100:
                count += 1
    return count

single = light_pixels(40, 300, 200, 240)
wrapped = light_pixels(40, 300, 280, 440)
if single < 100:
    raise SystemExit("text pixels not visible: %d" % single)
if wrapped < 1000:
    raise SystemExit("wrapped text pixels not visible: %d" % wrapped)
print("ok   NSString drawAtPoint:/drawInRect: paint %d/%d light pixels:"
      % (single, wrapped))
PY
)"; then
    echo "$out"
else
    echo "FAIL NSString drawing"; echo "$out"; fails=$((fails+1))
fi

if [ "$fails" -ne 0 ]; then
    echo "$fails test(s) failed" >&2
    exit 1
fi
echo "all tests passed"
