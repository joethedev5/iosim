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
"$ROOT/tools/build_app.sh" "$ROOT/tests/pasteboard_types_test.m" \
    "$T/pasteboard_types_test" >/dev/null
out="$(SIMULATOR_SHARED_RESOURCES_DIRECTORY="$PB_SHARED" \
    DYLD_ROOT_PATH="$ROOT/runtime" "$RUN" "$T/pasteboard_types_test" 2>&1)"
check "[pb] strings 2 one 1" "$out" \
    "the pasteboard stores multiple strings under the plain-text type"
check "[pb] urls 2 https://example.com/b 1" "$out" \
    "the pasteboard stores multiple URLs under the public.url type"
check "[pb] color 1.00 0.50 0.25 0.75" "$out" \
    "the pasteboard stores UIColor components under the UIKit color type"
check "[pb] types 1 1" "$out" \
    "types and containsPasteboardTypes report the stored type"
"$ROOT/tools/build_app.sh" "$ROOT/tests/pasteboard_image_test.m" \
    "$T/pasteboard_image_test" >/dev/null
out="$(SIMULATOR_SHARED_RESOURCES_DIRECTORY="$PB_SHARED" \
    DYLD_ROOT_PATH="$ROOT/runtime" "$RUN" "$T/pasteboard_image_test" 2>&1)"
check "[pbimg] bytes 2018" "$out" \
    "the image fixture reads the bundle PNG bytes"
check "[pbimg] decode 1 132 132" "$out" \
    "UIImage imageWithData decodes PNG bytes in memory"
check "[pbimg] image 1 132 132 1" "$out" \
    "setImage/image round-trip through public.png data"
check "[pbimg] images 2 1" "$out" \
    "setImages stores multiple images under public.png"

# ---------- 4f2. Device pasteboard CLI and change notifications ----------
PB_HOME="$T/pasteboard-cli-home"
rm -rf "$PB_HOME"
mkdir -p "$PB_HOME"
IOSIM_HOME="$PB_HOME"
export IOSIM_HOME
UDID="$("$ROOT/tools/iosimctl" create "Pasteboard iPhone" \
    com.iosim.SimDeviceType.iPhone-18-Pro)"
PB_DEVICE_DATA="$IOSIM_HOME/Devices/$UDID/data"
"$ROOT/tools/build_app.sh" "$ROOT/tests/pasteboard_watch_test.m" \
    "$T/pasteboard_watch" >/dev/null
rm -f "$T/pastewatch.log" "$T/pastewatch.fifo"
mkfifo "$T/pastewatch.fifo"
SIMULATOR_SHARED_RESOURCES_DIRECTORY="$PB_DEVICE_DATA" \
    IOSIM_EVENT_FIFO="$T/pastewatch.fifo" \
    DYLD_ROOT_PATH="$ROOT/runtime" "$RUN" "$T/pasteboard_watch" \
    > "$T/pastewatch.log" 2>&1 &
WATCH_PID=$!
i=0
while [ "$i" -lt 50 ]; do
    grep -Fq "[pastewatch] ready" "$T/pastewatch.log" 2>/dev/null && break
    sleep 0.1
    i=$((i+1))
done
"$ROOT/tools/iosimctl" pbcopy "$UDID" "from the cli"
i=0
while [ "$i" -lt 50 ]; do
    grep -Fq "[pastewatch] changed from the cli" \
        "$T/pastewatch.log" 2>/dev/null && break
    sleep 0.1
    i=$((i+1))
done
if grep -Fq "[pastewatch] changed from the cli" "$T/pastewatch.log"; then
    echo "ok   iosimctl pbcopy reaches a running app's pasteboard notification"
else
    echo "FAIL pasteboard notification"
    cat "$T/pastewatch.log"
    fails=$((fails+1))
fi
kill "$WATCH_PID" 2>/dev/null || true
wait "$WATCH_PID" 2>/dev/null || true
rm -f "$T/pastewatch.fifo"
if [ "$("$ROOT/tools/iosimctl" pbpaste "$UDID")" = "from the cli" ]; then
    echo "ok   iosimctl pbpaste prints the device pasteboard text"
else
    echo "FAIL pasteboard pbpaste"
    fails=$((fails+1))
fi

# ---------- 4f3. Multi-touch delivery ----------
rm -f "$T/multi.fifo"
mkfifo "$T/multi.fifo"
"$ROOT/tools/build_app.sh" "$ROOT/tests/multitouch_test.m" \
    "$T/multitouch_test" >/dev/null
out="$(IOSIM_EVENT_FIFO="$T/multi.fifo" DYLD_ROOT_PATH="$ROOT/runtime" \
    "$RUN" "$T/multitouch_test" 2>&1)"
check "[mt] a began changed=1 all=1 fv=1/0" "$out" \
    "the first finger begins on its own hit view"
check "[mt] b began changed=1 all=2 fv=1/1" "$out" \
    "a second finger adds a touch while each view sees one"
check "[mt] a moved changed=1 all=2 at 120.0 100.0 prev 90.0 90.0" "$out" \
    "per-finger moves carry that view's coordinates"
check "[mt] a ended changed=1 all=2" "$out" \
    "lifting one finger leaves the other touch live"
check "[mt] b ended changed=1 all=1" "$out" \
    "the last finger ends with only its own touch"
check "[mt] done" "$out" \
    "both fingers end cleanly"

# ---------- 4f4. CADisplayLink preferred frame rate ----------
rm -f "$T/dlink.fifo"
mkfifo "$T/dlink.fifo"
"$ROOT/tools/build_app.sh" "$ROOT/tests/display_link_rate_test.m" \
    "$T/display_link_rate_test" >/dev/null
out="$(IOSIM_EVENT_FIFO="$T/dlink.fifo" DYLD_ROOT_PATH="$ROOT/runtime" \
    "$RUN" "$T/display_link_rate_test" 2>&1)"
check "[dlink] duration 0.1000 0.0167" "$out" \
    "preferredFramesPerSecond sets the display link duration"
check "[dlink] rates 1 1" "$out" \
    "a 10 fps link fires far less often than a default 60 fps link"
check "[dlink] done" "$out" \
    "the display-link rate fixture ends on its own"

# ---------- 4f5. CAMediaTimingFunction control points ----------
"$CC" -target "$TARGET" -fobjc-runtime=ios-18.0 -fno-objc-arc \
    -ffreestanding -O1 -I "$ROOT/demo" \
    -c "$ROOT/tests/timing_function_test.m" -o "$T/timing_function.o"
"$LD64" -arch x86_64 -platform_version $PLATFORM -e _main \
    -o "$T/timing_function_test" "$T/timing_function.o" \
    "$ROOT/runtime/System/Library/Frameworks/UIKit.framework/UIKit" \
    "$ROOT/runtime/System/Library/Frameworks/Foundation.framework/Foundation" \
    -undefined dynamic_lookup
out="$(DYLD_ROOT_PATH="$ROOT/runtime" "$RUN" "$T/timing_function_test" 2>&1)"
check "[timing] points 0.42 0.00 0.58 1.00" "$out" \
    "named timing functions expose their cubic control points"
check "[timing] ease 0.16 0.50 0.84" "$out" \
    "the named ease-in-ease-out curve evaluates its smoothstep values"
check "[timing] custom 0.13 0.50 0.87" "$out" \
    "a custom cubic-Bezier function solves for its output progress"
check "[timing] linear 0.50 0.25" "$out" \
    "the named linear function evaluates to its input"

# ---------- 4f6. CAKeyframeAnimation calculation modes ----------
rm -f "$T/kfmode.fifo"
mkfifo "$T/kfmode.fifo"
"$ROOT/tools/build_app.sh" "$ROOT/tests/keyframe_modes_test.m" \
    "$T/keyframe_modes_test" >/dev/null
out="$(IOSIM_EVENT_FIFO="$T/kfmode.fifo" DYLD_ROOT_PATH="$ROOT/runtime" \
    "$RUN" "$T/keyframe_modes_test" 2>&1)"
rm -f "$T/kfmode.fifo"
check "[kfmode] ready" "$out" \
    "the keyframe modes fixture starts"
check "[kfmode] done" "$out" \
    "the keyframe modes fixture samples all animations"
if out="$(python3 - "$out" <<'PY'
import re
import sys

vals = {}
for line in sys.argv[1].splitlines():
    m = re.match(r'\[kfmode\] (linear|discrete|paced|cubic|eased) '
                 r'([-0-9.]+)$', line)
    if m:
        vals[m.group(1)] = float(m.group(2))
for name in ('linear', 'discrete', 'paced', 'cubic', 'eased'):
    if name not in vals:
        raise SystemExit('missing %s sample: %r' % (name, vals))
if not 0.18 <= vals['linear'] <= 0.30:
    raise SystemExit('linear sample out of range: %.3f' % vals['linear'])
if vals['discrete'] > 0.01:
    raise SystemExit('discrete did not hold its first value: %.3f' %
                     vals['discrete'])
if not 0.08 <= vals['paced'] <= 0.18 or vals['paced'] >= vals['linear']:
    raise SystemExit('paced sample out of range: %.3f' % vals['paced'])
if not 0.25 <= vals['cubic'] <= 0.38 or vals['cubic'] <= vals['linear']:
    raise SystemExit('cubic sample out of range: %.3f' % vals['cubic'])
if not 0.03 <= vals['eased'] <= 0.12 or vals['eased'] >= vals['linear']:
    raise SystemExit('eased sample out of range: %.3f' % vals['eased'])
print("ok   keyframes pick discrete, paced, cubic and eased samples")
PY
)"; then
    echo "$out"
else
    echo "FAIL keyframe modes"; echo "$out"; fails=$((fails+1))
fi

# ---------- 4f7. Direct CALayer position animations ----------
rm -f "$T/lpos.fifo"
mkfifo "$T/lpos.fifo"
"$ROOT/tools/build_app.sh" "$ROOT/tests/layer_position_test.m" \
    "$T/layer_position_test" >/dev/null
out="$(IOSIM_EVENT_FIFO="$T/lpos.fifo" IOSIM_TEST_PNG="$T/layer_position.png" \
    DYLD_ROOT_PATH="$ROOT/runtime" "$RUN" "$T/layer_position_test" 2>&1)"
rm -f "$T/lpos.fifo"
check "[lpos] ready" "$out" \
    "the layer position fixture starts"
check "[lpos] png written" "$out" \
    "the layer position fixture captures a frame"
if out="$(python3 - "$out" <<'PY'
import re
import sys

vals = {}
for line in sys.argv[1].splitlines():
    m = re.match(r'\[lpos\] (basic|key) ([-0-9.]+) ([-0-9.]+)$', line)
    if m:
        vals[m.group(1)] = (float(m.group(2)), float(m.group(3)))
if 'basic' not in vals or 'key' not in vals:
    raise SystemExit('missing presentation origins: %r' % vals)
bx, by = vals['basic']
kx, ky = vals['key']
if not (55.0 <= bx <= 80.0 and abs(by - 280.0) < 0.5):
    raise SystemExit('basic position is not mid-flight: %.1f %.1f' %
                     (bx, by))
if not (80.0 <= kx <= 105.0 and abs(ky - 480.0) < 0.5):
    raise SystemExit('keyframe position is not mid-flight: %.1f %.1f' %
                     (kx, ky))
print("ok   layer position animations reach the presentation layer")
PY
)"; then
    echo "$out"
else
    echo "FAIL layer position origins"; echo "$out"; fails=$((fails+1))
fi
if out="$(python3 - "$ROOT/tools" "$T/layer_position.png" <<'PY'
import sys
sys.path.insert(0, sys.argv[1])
import pngpixel

w, h, bpp, rows = pngpixel.load(sys.argv[2])

def rgb(x, y):
    c = pngpixel.px(rows, bpp, x * 3, y * 3)
    return ((c >> 16) & 255, (c >> 8) & 255, c & 255)

def white(x, y):
    return rgb(x, y) == (255, 255, 255)

def black(x, y):
    return rgb(x, y) == (0, 0, 0)

checks = [
    ((83, 300), white(83, 300), "basic box moved onto the sample"),
    ((50, 300), black(50, 300), "basic box vacated its base origin"),
    ((108, 500), white(108, 500), "keyframe box moved onto the sample"),
    ((55, 500), black(55, 500), "keyframe box vacated its base origin"),
]
bad = [name for _pt, ok, name in checks if not ok]
if bad:
    raise SystemExit("layer position pixels failed: " + ", ".join(bad))
print("ok   renderer moves view layers along animated positions")
PY
)"; then
    echo "$out"
else
    echo "FAIL layer position pixels"; echo "$out"; fails=$((fails+1))
fi

# ---------- 4f8. CGPath-driven keyframe positions ----------
rm -f "$T/lpath.fifo"
mkfifo "$T/lpath.fifo"
"$ROOT/tools/build_app.sh" "$ROOT/tests/layer_path_test.m" \
    "$T/layer_path_test" >/dev/null
out="$(IOSIM_EVENT_FIFO="$T/lpath.fifo" IOSIM_TEST_PNG="$T/layer_path.png" \
    DYLD_ROOT_PATH="$ROOT/runtime" "$RUN" "$T/layer_path_test" 2>&1)"
rm -f "$T/lpath.fifo"
check "[lpath] ready" "$out" \
    "the path animation fixture starts"
check "[lpath] png written" "$out" \
    "the path animation fixture captures a frame"
if out="$(python3 - "$out" <<'PY'
import re
import sys

vals = {}
for line in sys.argv[1].splitlines():
    m = re.match(r'\[lpath\] (line|curve) ([-0-9.]+) ([-0-9.]+)$', line)
    if m:
        vals[m.group(1)] = (float(m.group(2)), float(m.group(3)))
if 'line' not in vals or 'curve' not in vals:
    raise SystemExit('missing path positions: %r' % vals)
lx, ly = vals['line']
cx, cy = vals['curve']
if not (55.0 <= lx <= 80.0 and abs(ly - 280.0) < 0.5):
    raise SystemExit('line path position is not mid-flight: %.1f %.1f' %
                     (lx, ly))
if not (130.0 <= cx <= 160.0 and 450.0 <= cy <= 465.0):
    raise SystemExit('quadratic path position is not near the apex: '
                     '%.1f %.1f' % (cx, cy))
print("ok   a CAKeyframeAnimation path drives the presentation position")
PY
)"; then
    echo "$out"
else
    echo "FAIL path origins"; echo "$out"; fails=$((fails+1))
fi
if out="$(python3 - "$ROOT/tools" "$T/layer_path.png" <<'PY'
import sys
sys.path.insert(0, sys.argv[1])
import pngpixel

w, h, bpp, rows = pngpixel.load(sys.argv[2])

def rgb(x, y):
    c = pngpixel.px(rows, bpp, x * 3, y * 3)
    return ((c >> 16) & 255, (c >> 8) & 255, c & 255)

checks = [
    ((83, 300), rgb(83, 300) == (255, 255, 255), "line box moved"),
    ((50, 300), rgb(50, 300) == (0, 0, 0), "line base vacated"),
    ((160, 475), rgb(160, 475) == (255, 255, 255), "curve apex covered"),
    ((55, 500), rgb(55, 500) == (0, 0, 0), "curve base vacated"),
]
bad = [name for _pt, ok, name in checks if not ok]
if bad:
    raise SystemExit("path pixels failed: " + ", ".join(bad))
print("ok   renderer follows quadratic path positions on screen")
PY
)"; then
    echo "$out"
else
    echo "FAIL path pixels"; echo "$out"; fails=$((fails+1))
fi

# ---------- 4f9. UIView spring animations ----------
rm -f "$T/springui.fifo"
mkfifo "$T/springui.fifo"
"$ROOT/tools/build_app.sh" "$ROOT/tests/spring_ui_test.m" \
    "$T/spring_ui_test" >/dev/null
out="$(IOSIM_EVENT_FIFO="$T/springui.fifo" DYLD_ROOT_PATH="$ROOT/runtime" \
    "$RUN" "$T/spring_ui_test" 2>&1)"
rm -f "$T/springui.fifo"
check "[springui] ready" "$out" \
    "the UIView spring fixture starts"
check "[springui] done" "$out" \
    "the UIView spring fixture samples both phases"
if out="$(python3 - "$out" <<'PY'
import re
import sys

vals = {}
for line in sys.argv[1].splitlines():
    m = re.match(r'\[springui\] (early|late) ([-0-9.]+) ([-0-9.]+)$',
                 line)
    if m:
        vals[m.group(1)] = (float(m.group(2)), float(m.group(3)))
if 'early' not in vals or 'late' not in vals:
    raise SystemExit('missing spring samples: %r' % vals)
se, ce = vals['early']
sl, cl = vals['late']
if not 230.0 <= se <= 265.0:
    raise SystemExit('soft spring did not overshoot early: %.1f' % se)
if not 170.0 <= ce <= 200.0:
    raise SystemExit('critical spring early sample is off: %.1f' % ce)
if se < ce + 30.0:
    raise SystemExit('spring dampings did not separate: %.1f vs %.1f' %
                     (se, ce))
if not (230.0 <= sl <= 242.0 and 230.0 <= cl <= 245.0):
    raise SystemExit('springs did not settle near the target: %.1f %.1f' %
                     (sl, cl))
if not sl < cl:
    raise SystemExit('soft spring did not return past the critical spring: '
                     '%.1f vs %.1f' % (sl, cl))
print("ok   UIView spring damping overshoots and settles")
PY
)"; then
    echo "$out"
else
    echo "FAIL UIView springs"; echo "$out"; fails=$((fails+1))
fi

# ---------- 4f10. UIView cross-dissolve transitions ----------
rm -f "$T/trans.fifo"
mkfifo "$T/trans.fifo"
"$ROOT/tools/build_app.sh" "$ROOT/tests/transition_test.m" \
    "$T/transition_test" >/dev/null
out="$(IOSIM_EVENT_FIFO="$T/trans.fifo" \
    IOSIM_TEST_PNG_MID="$T/transition_mid.png" \
    IOSIM_TEST_PNG_END="$T/transition_end.png" \
    DYLD_ROOT_PATH="$ROOT/runtime" "$RUN" "$T/transition_test" 2>&1)"
rm -f "$T/trans.fifo"
check "[trans] ready" "$out" \
    "the transition fixture starts"
check "[trans] mid" "$out" \
    "the transition fixture captures the fade midway"
check "[trans] done 1" "$out" \
    "the transition completion runs"
check "[trans] end" "$out" \
    "the transition fixture captures the settled frame"
if out="$(python3 - "$ROOT/tools" "$T/transition_mid.png" \
    "$T/transition_end.png" <<'PY'
import sys
sys.path.insert(0, sys.argv[1])
import pngpixel

def load(path):
    w, h, bpp, rows = pngpixel.load(path)
    def rgb(x, y):
        c = pngpixel.px(rows, bpp, x * 3, y * 3)
        return ((c >> 16) & 255, (c >> 8) & 255, c & 255)
    return rgb

mid = load(sys.argv[2])
end = load(sys.argv[3])
checks = [
    ("mid background", 90 <= mid(140, 340)[0] <= 160 and
     mid(140, 340)[1] < 40 and 90 <= mid(140, 340)[2] <= 160),
    ("mid chip", 90 <= mid(110, 310)[0] <= 160 and
     mid(110, 310)[1] > 220 and mid(110, 310)[2] < 40),
    ("mid outside", mid(20, 340) == (0, 0, 0)),
    ("end background", end(140, 340)[0] < 40 and end(140, 340)[1] < 40 and
     end(140, 340)[2] > 200),
    ("end chip", end(110, 310)[0] < 40 and end(110, 310)[1] > 220 and
     end(110, 310)[2] < 60),
    ("end outside", end(20, 340) == (0, 0, 0)),
]
bad = [name for name, ok in checks if not ok]
if bad:
    raise SystemExit("transition pixels failed: " + ", ".join(bad))
print("ok   a cross-dissolve blends old snapshot into new colors")
PY
)"; then
    echo "$out"
else
    echo "FAIL transition pixels"; echo "$out"; fails=$((fails+1))
fi

# ---------- 4f10b. UIView flip transitions ----------
rm -f "$T/flip.fifo"
mkfifo "$T/flip.fifo"
"$ROOT/tools/build_app.sh" "$ROOT/tests/uiview_transition_test.m" \
    "$T/uiview_transition_test" >/dev/null
out="$(IOSIM_EVENT_FIFO="$T/flip.fifo" \
    IOSIM_TEST_PNG_FIRST="$T/flip_first.png" \
    IOSIM_TEST_PNG_SECOND="$T/flip_second.png" \
    IOSIM_TEST_PNG_SWAP="$T/flip_swap.png" \
    DYLD_ROOT_PATH="$ROOT/runtime" "$RUN" \
    "$T/uiview_transition_test" 2>&1)"
rm -f "$T/flip.fifo"
check "[flip] ready" "$out" "the flip fixture starts"
check "[flip] start" "$out" "transitionWithView starts a horizontal flip"
check "[flip] first" "$out" "the old snapshot is captured mid-squash"
check "[flip] stage 3" "$out" \
    "the flip stages the backdrop and both snapshots"
check "[flip] settle 1 0 1" "$out" \
    "the horizontal flip completes and removes its snapshots"
check "[swap] start" "$out" "transitionFromView starts a vertical flip"
check "[swap] stage 4" "$out" \
    "the vertical flip stages its snapshots in the parent"
check "[swap] done 1" "$out" "the vertical flip completes"
check "[swap] settle 1 1" "$out" \
    "the swap leaves only the destination view"
fixture_out="$out"
check "[swap] end" "$out" "the flip fixture finishes"
if out="$(python3 - "$ROOT/tools" "$T/flip_first.png" "$T/flip_second.png" \
    "$T/flip_swap.png" "$fixture_out" <<'FLIPPNG'
import re
import sys
sys.path.insert(0, sys.argv[1])
import pngpixel

def load(path):
    w, h, bpp, rows = pngpixel.load(path)
    def rgb(x, y):
        c = pngpixel.px(rows, bpp, x * 3, y * 3)
        return ((c >> 16) & 255, (c >> 8) & 255, c & 255)
    return rgb

def near(got, want, tol=30):
    return all(abs(a - b) <= tol for a, b in zip(got, want))

def row(f, y, x0, x1, color):
    return sum(1 for x in range(x0, x1 + 1) if near(f(x, y), color))

def column(f, x, y0, y1, color):
    return sum(1 for y in range(y0, y1 + 1) if near(f(x, y), color))

blue = (26, 64, 230)
green = (26, 204, 77)
yellow = (242, 217, 26)
dark = (13, 15, 23)

first = load(sys.argv[2])
second = load(sys.argv[3])
swap = load(sys.argv[4])
text = sys.argv[5]

# The framebuffer holds the last rendered frame, so a capture trails its
# timer; count colors along the flip axis instead of sampling fixed points.
checks = [
    ("first old side", row(first, 437, 81, 321, blue) >= 40),
    ("first new side hidden", row(first, 437, 81, 321, green) == 0),
    ("second old side gone", row(second, 437, 81, 321, blue) == 0),
    ("second new side", row(second, 437, 81, 321, green) >= 1),
    ("second backdrop", row(second, 437, 81, 321, dark) >= 40),
    ("swap new side", column(swap, 201, 287, 587, yellow) >= 4),
    ("swap backdrop", column(swap, 201, 287, 587, dark) >= 4),
]
bad = [name for name, ok in checks if not ok]
if bad:
    raise SystemExit("flip pixels failed: " + ", ".join(bad))

m = re.search(r'\[flip\] elapsed (\d+)$', text, re.M)
if not m or not 740 <= int(m.group(1)) <= 1200:
    raise SystemExit('horizontal flip timing: %r' % (m and m.group(1),))
m = re.search(r'\[swap\] elapsed (\d+)$', text, re.M)
if not m or not 540 <= int(m.group(1)) <= 950:
    raise SystemExit('vertical flip timing: %r' % (m and m.group(1),))
print("ok   flip transitions squash the old side and open the new side")
FLIPPNG
)"; then
    echo "$out"
else
    echo "FAIL flip transitions"; echo "$out"; fails=$((fails+1))
fi

# ---------- 4f10c. Legacy UIView animation blocks ----------
rm -f "$T/legacy.fifo"
mkfifo "$T/legacy.fifo"
"$ROOT/tools/build_app.sh" "$ROOT/tests/legacy_animation_test.m" \
    "$T/legacy_animation_test" >/dev/null
out="$(IOSIM_EVENT_FIFO="$T/legacy.fifo" \
    IOSIM_TEST_PNG_MID="$T/legacy_mid.png" \
    IOSIM_TEST_PNG_END="$T/legacy_end.png" \
    IOSIM_TEST_PNG_REP1="$T/legacy_rep1.png" \
    IOSIM_TEST_PNG_REP2="$T/legacy_rep2.png" \
    DYLD_ROOT_PATH="$ROOT/runtime" "$RUN" \
    "$T/legacy_animation_test" 2>&1)"
rm -f "$T/legacy.fifo"
check "[legacy] ready" "$out" "the legacy animation fixture starts"
check "[legacy] will 7" "$out" \
    "beginAnimations runs the will-start delegate"
check "[legacy] start" "$out" \
    "commitAnimations captures the frame, alpha and transform changes"
check "[legacy] mid 1 0" "$out" \
    "hit-testing follows the interpolated legacy frame"
check "[legacy] end 1 1" "$out" \
    "the legacy frame settles at its committed value"
check "[legacy] model 140 100 120" "$out" \
    "the settled model frame and transform match the changes"
check "[legacy] fade 40" "$out" \
    "the untransformed view settles at its committed alpha"
check "[legacy] stop 7 1" "$out" \
    "the did-stop delegate reports a finished animation"
check "[legacy] did7 1" "$out" "the first legacy animation stops once"
check "[legacy] rep1" "$out" \
    "the first repeat pass reaches a mid-cycle frame"
check "[legacy] rep2" "$out" \
    "the second repeat pass reaches a mid-cycle frame"
check "[legacy] box model 200" "$out" \
    "the repeated frame settles at the committed value"
check "[legacy] stop 8 1" "$out" \
    "the repeated animation reports one finished stop"
check "[legacy] did8 1" "$out" "the repeat count adds exactly one pass"
check "[legacy] will 9" "$out" \
    "the transition block runs its will-start delegate"
check "[legacy] stage 4" "$out" \
    "setAnimationTransition stages the backdrop and both snapshots"
check "[legacy] stop 9 1" "$out" \
    "the transition completion reaches the did-stop delegate"
check "[legacy] transition end 1 1" "$out" \
    "the transition removes every staged view"
check "[legacy] done" "$out" "the legacy animation fixture finishes"
fixture_out="$out"
if out="$(python3 - "$ROOT/tools" "$T/legacy_mid.png" "$T/legacy_end.png" \
    "$T/legacy_rep1.png" "$T/legacy_rep2.png" <<'LEGACYPNG'
import sys
sys.path.insert(0, sys.argv[1])
import pngpixel

def load(path):
    w, h, bpp, rows = pngpixel.load(path)
    def rgb(x, y):
        c = pngpixel.px(rows, bpp, x * 3, y * 3)
        return ((c >> 16) & 255, (c >> 8) & 255, c & 255)
    return rgb

def near(got, want, tol=25):
    return all(abs(a - b) <= tol for a, b in zip(got, want))

mid = load(sys.argv[2])
end = load(sys.argv[3])
rep1 = load(sys.argv[4])
rep2 = load(sys.argv[5])

def red_between(c, lo, hi):
    r, g, b = c
    return lo <= r <= hi and g < 50 and b < 60

def blue_between(c, lo, hi):
    r, g, b = c
    return r < 70 and 40 <= g <= 115 and lo <= b <= hi

def box_run(f, y):
    xs = [x for x in range(0, 330) if blue_between(f(x, y), 180, 255)]
    if not xs:
        return None
    return min(xs), max(xs)

def mid_cycle(run):
    return run is not None and 60 < run[0] < 170 and \
        20 <= run[1] - run[0] <= 80

checks = [
    ("mid face", red_between(mid(215, 360), 200, 255)),
    ("mid transform edge", near(mid(375, 360), (13, 15, 23))),
    ("mid fade", blue_between(mid(330, 110), 130, 210)),
    ("rep1 mid cycle", mid_cycle(box_run(rep1, 590))),
    ("rep2 mid cycle", mid_cycle(box_run(rep2, 590))),
    ("end face", red_between(end(270, 370), 200, 255)),
    ("end transform edge", red_between(end(375, 360), 200, 255)),
    ("end fade", blue_between(end(330, 110), 80, 145)),
    ("end box settled", box_run(end, 590) is not None and
     185 < box_run(end, 590)[0] < 215),
]
bad = [name for name, ok in checks if not ok]
if bad:
    raise SystemExit("legacy animation pixels failed: " + ", ".join(bad))
print("ok   legacy animations move the transformed frame, repeat and fade")
LEGACYPNG
)"; then
    echo "$out"
else
    echo "FAIL legacy animation pixels"; echo "$out"; fails=$((fails+1))
fi

# ---------- 4f10d. Transformed and layered alpha compositing ----------
rm -f "$T/alpha.fifo"
mkfifo "$T/alpha.fifo"
"$ROOT/tools/build_app.sh" "$ROOT/tests/alpha_transform_test.m" \
    "$T/alpha_transform_test" >/dev/null
out="$(IOSIM_EVENT_FIFO="$T/alpha.fifo" \
    IOSIM_TEST_PNG="$T/alpha_transform.png" \
    DYLD_ROOT_PATH="$ROOT/runtime" "$RUN" \
    "$T/alpha_transform_test" 2>&1)"
rm -f "$T/alpha.fifo"
check "[at] ready" "$out" "the alpha compositing fixture starts"
check "[at] captured" "$out" "the fixture captures the composited frame"
check "[at] done" "$out" "the alpha compositing fixture finishes"
if out="$(python3 - "$ROOT/tools" "$T/alpha_transform.png" <<'ALPHAPNG'
import sys
sys.path.insert(0, sys.argv[1])
import pngpixel

w, h, bpp, rows = pngpixel.load(sys.argv[2])

def rgb(x, y):
    c = pngpixel.px(rows, bpp, x * 3, y * 3)
    return ((c >> 16) & 255, (c >> 8) & 255, c & 255)

def near(got, want, tol=25):
    return all(abs(a - b) <= tol for a, b in zip(got, want))

plain = rgb(90, 250)
scaled = rgb(250, 250)
layered = rgb(90, 450)
sublayer = rgb(250, 450)

def red_half(c):
    r, g, b = c
    return 100 <= r <= 170 and g < 40 and b < 50

checks = [
    ("plain", red_half(plain)),
    ("scaled", red_half(scaled)),
    ("scaled matches plain", abs(scaled[0] - plain[0]) <= 12),
    ("scaled extent", red_half(rgb(310, 250))),
    ("layered", red_half(layered)),
    ("sublayer", red_half(sublayer)),
    ("sublayer extent", red_half(rgb(310, 450))),
    ("outside", near(rgb(340, 250), (13, 15, 23))),
]
bad = [name for name, ok in checks if not ok]
if bad:
    raise SystemExit("alpha pixels failed: " + ", ".join(bad) +
                     " plain=%r scaled=%r layered=%r sublayer=%r" %
                     (plain, scaled, layered, sublayer))
print("ok   transformed and layered views composite alpha once")
ALPHAPNG
)"; then
    echo "$out"
else
    echo "FAIL transformed alpha compositing"; echo "$out"; fails=$((fails+1))
fi

# ---------- 4f10f. Associated objects ----------
"$CC" -target "$TARGET" -fobjc-runtime=ios-18.0 -fno-objc-arc \
    -ffreestanding -O1 -I "$ROOT/frameworks" \
    -c "$ROOT/tests/associated_objects_test.m" -o "$T/associated_objects_test.o"
"$LD64" -arch x86_64 -platform_version $PLATFORM -e _main \
    -o "$T/associated_objects_test" "$T/associated_objects_test.o" \
    "$ROOT/runtime/System/Library/Frameworks/Foundation.framework/Foundation" \
    -undefined dynamic_lookup
out="$(DYLD_ROOT_PATH="$ROOT/runtime" "$RUN" \
    "$T/associated_objects_test" 2>&1)"
check "[assoc] one alpha beta two other" "$out" \
    "associated values are keyed per object"
check "[assoc] replaced gamma" "$out" \
    "setting an existing key replaces its value"
check "[assoc] cleared 1" "$out" \
    "setting nil removes the association"
check "[assoc] retain same 1 9" "$out" \
    "a retain policy stores the same pointer"
check "[assoc] copy isolated 11 13" "$out" \
    "a copy policy snapshots the value against later mutation"
check "[assoc] string copy copy copy!" "$out" \
    "a copied mutable string keeps its old contents"
check "[assoc] removed 1 other" "$out" \
    "removing associations leaves another object's entries"
check "[assoc] done" "$out" "the associated-object fixture finishes"

# ---------- 4f10e. Masks on transformed content ----------
rm -f "$T/mask.fifo"
mkfifo "$T/mask.fifo"
"$ROOT/tools/build_app.sh" "$ROOT/tests/mask_transform_test.m" \
    "$T/mask_transform_test" >/dev/null
out="$(IOSIM_EVENT_FIFO="$T/mask.fifo" \
    IOSIM_TEST_PNG="$T/mask_transform.png" \
    DYLD_ROOT_PATH="$ROOT/runtime" "$RUN" \
    "$T/mask_transform_test" 2>&1)"
rm -f "$T/mask.fifo"
check "[mt] ready" "$out" "the transformed-mask fixture starts"
check "[mt] captured" "$out" "the fixture captures the masked frame"
check "[mt] done" "$out" "the transformed-mask fixture finishes"
if out="$(python3 - "$ROOT/tools" "$T/mask_transform.png" <<'MASKPNG'
import sys
sys.path.insert(0, sys.argv[1])
import pngpixel

w, h, bpp, rows = pngpixel.load(sys.argv[2])

def rgb(x, y):
    c = pngpixel.px(rows, bpp, x * 3, y * 3)
    return ((c >> 16) & 255, (c >> 8) & 255, c & 255)

def red(c):
    r, g, b = c
    return r > 200 and g < 40 and b < 40

def dark(c):
    r, g, b = c
    return abs(r - 13) <= 25 and abs(g - 15) <= 25 and abs(b - 23) <= 25

checks = [
    ("view inside", red(rgb(70, 250))),
    ("view before edge", red(rgb(85, 250))),
    ("view past edge", dark(rgb(95, 250))),
    ("view outside", dark(rgb(110, 250))),
    ("layer inside", red(rgb(270, 250))),
    ("layer before edge", red(rgb(285, 250))),
    ("layer past edge", dark(rgb(295, 250))),
    ("layer outside", dark(rgb(310, 250))),
]
bad = [name for name, ok in checks if not ok]
if bad:
    raise SystemExit("transform-mask pixels failed: " + ", ".join(bad))
print("ok   transformed view and layer masks fold into the offscreen pass")
MASKPNG
)"; then
    echo "$out"
else
    echo "FAIL transformed masks"; echo "$out"; fails=$((fails+1))
fi

# ---------- 4f10g. Dynamic resolution and forwarding ----------
"$CC" -target "$TARGET" -fobjc-runtime=ios-18.0 -fno-objc-arc \
    -ffreestanding -O1 -I "$ROOT/frameworks" \
    -c "$ROOT/tests/message_forwarding_test.m" \
    -o "$T/message_forwarding_test.o"
"$LD64" -arch x86_64 -platform_version $PLATFORM -e _main \
    -o "$T/message_forwarding_test" "$T/message_forwarding_test.o" \
    "$ROOT/runtime/System/Library/Frameworks/Foundation.framework/Foundation" \
    -undefined dynamic_lookup
out="$(DYLD_ROOT_PATH="$ROOT/runtime" "$RUN" \
    "$T/message_forwarding_test" 2>&1)"
check "[fwd] resolve 42 42 calls 1" "$out" \
    "resolveInstanceMethod: installs a missing instance method once"
check "[fwd] class resolve 77 77" "$out" \
    "resolveClassMethod: installs a missing class method"
check "[fwd] target 123 backend" "$out" \
    "forwardingTargetForSelector: re-targets the send"
check "[fwd] chain 123" "$out" \
    "forwarding targets chain to the final implementation"
check "[fwd] responds 1" "$out" \
    "respondsToSelector: sees the resolved method"
check "[fwd] dnr bogus" "$out" \
    "an unresolved selector reaches doesNotRecognizeSelector:"
check "[fwd] done" "$out" "the forwarding fixture finishes"

# ---------- 4f10h. ARC entry points ----------
"$CC" -target "$TARGET" -fobjc-runtime=ios-18.0 -fobjc-arc -fblocks \
    -ffreestanding -O1 -I "$ROOT/frameworks" \
    -c "$ROOT/tests/arc_test.m" -o "$T/arc_test.o"
"$LD64" -arch x86_64 -platform_version $PLATFORM -e _main \
    -o "$T/arc_test" "$T/arc_test.o" \
    "$ROOT/runtime/System/Library/Frameworks/Foundation.framework/Foundation" \
    -undefined dynamic_lookup
out="$(DYLD_ROOT_PATH="$ROOT/runtime" "$RUN" "$T/arc_test" 2>&1)"
check "[arc] strong arc" "$out" \
    "an ARC strong property stores through objc_storeStrong"
check "[arc] weak 1 1" "$out" \
    "ARC weak locals and properties load the stored object"
check "[arc] weak cleared 1" "$out" \
    "assigning nil clears an ARC weak slot"
check "[arc] tag tag-arc" "$out" \
    "an autoreleased return survives objc_retainAutoreleasedReturnValue"
check "[arc] block 2 42" "$out" \
    "an ARC block mutates a byref capture that a second block reads"
check "[arc] bridge 1" "$out" \
    "__bridge casts preserve object identity"
check "[arc] done" "$out" "the ARC fixture finishes"

# ---------- 4f10i. Runtime swizzling ----------
"$CC" -target "$TARGET" -fobjc-runtime=ios-18.0 -fno-objc-arc \
    -ffreestanding -O1 -I "$ROOT/frameworks" \
    -c "$ROOT/tests/runtime_swizzle_test.m" \
    -o "$T/runtime_swizzle_test.o"
"$LD64" -arch x86_64 -platform_version $PLATFORM -e _main \
    -o "$T/runtime_swizzle_test" "$T/runtime_swizzle_test.o" \
    "$ROOT/runtime/System/Library/Frameworks/Foundation.framework/Foundation" \
    -undefined dynamic_lookup
out="$(DYLD_ROOT_PATH="$ROOT/runtime" "$RUN" \
    "$T/runtime_swizzle_test" 2>&1)"
check "[sw] before 1 2" "$out" \
    "the swizzle fixture starts with the original implementations"
check "[sw] exchanged 2 1" "$out" \
    "method_exchangeImplementations swaps two instance methods"
check "[sw] replace 1 9" "$out" \
    "class_replaceMethod replaces a method and reports the old one"
check "[sw] set 1 11" "$out" \
    "method_setImplementation replaces an implementation directly"
check "[sw] override sub 12 super 11" "$out" \
    "a subclass replacement adds an override without touching the superclass"
check "[sw] target list 2 1" "$out" \
    "class_copyMethodList returns the class's own methods"
check "[sw] sub list 1 1" "$out" \
    "class_copyMethodList includes a runtime-added override"
check "[sw] class exchanged 6 5" "$out" \
    "method_exchangeImplementations swaps class methods"
check "[sw] responds 1 1 0" "$out" \
    "class_respondsToSelector and instancesRespondToSelector report matches"
check "[sw] done" "$out" "the swizzle fixture finishes"

# ---------- 4f10j. NSMethodSignature and NSInvocation ----------
"$CC" -target "$TARGET" -fobjc-runtime=ios-18.0 -fno-objc-arc \
    -ffreestanding -O1 -I "$ROOT/frameworks" \
    -c "$ROOT/tests/ns_invocation_test.m" -o "$T/ns_invocation_test.o"
"$LD64" -arch x86_64 -platform_version $PLATFORM -e _main \
    -o "$T/ns_invocation_test" "$T/ns_invocation_test.o" \
    "$ROOT/runtime/System/Library/Frameworks/Foundation.framework/Foundation" \
    -undefined dynamic_lookup
out="$(DYLD_ROOT_PATH="$ROOT/runtime" "$RUN" "$T/ns_invocation_test" 2>&1)"
check "[inv] sig 4 @ : i" "$out" \
    "methodSignatureForSelector: exposes the argument and return types"
check "[inv] add 42" "$out" \
    "NSInvocation invokes an integer method with two arguments"
check "[inv] double 10.0" "$out" \
    "NSInvocation passes and returns a double"
check "[inv] echo hello" "$out" \
    "NSInvocation passes and returns an object"
check "[inv] void 1" "$out" \
    "NSInvocation invokes a void method"
check "[inv] retained 1" "$out" \
    "retainArguments marks the invocation's arguments retained"
check "[inv] missing 0" "$out" \
    "a present selector yields a method signature"
check "[inv] done" "$out" "the invocation fixture finishes"

# ---------- 4f10k. forwardInvocation delivery ----------
"$CC" -target "$TARGET" -fobjc-runtime=ios-18.0 -fno-objc-arc \
    -ffreestanding -O1 -I "$ROOT/frameworks" \
    -c "$ROOT/tests/forward_invocation_test.m" \
    -o "$T/forward_invocation_test.o"
"$LD64" -arch x86_64 -platform_version $PLATFORM -e _main \
    -o "$T/forward_invocation_test" "$T/forward_invocation_test.o" \
    "$ROOT/runtime/System/Library/Frameworks/Foundation.framework/Foundation" \
    -undefined dynamic_lookup
out="$(DYLD_ROOT_PATH="$ROOT/runtime" "$RUN" \
    "$T/forward_invocation_test" 2>&1)"
check "[fwd2] args 19 23" "$out" \
    "forwardInvocation: receives the integer arguments"
check "[fwd2] return 42" "$out" \
    "the invocation's return value reaches the original caller"
check "[fwd2] object proxy-greeting" "$out" \
    "an object return value reaches the original caller"
check "[fwd2] done" "$out" "the forwarding fixture finishes"

# ---------- 4f10l. NSProxy forwarding ----------
"$CC" -target "$TARGET" -fobjc-runtime=ios-18.0 -fno-objc-arc \
    -ffreestanding -O1 -I "$ROOT/frameworks" \
    -c "$ROOT/tests/nsproxy_test.m" -o "$T/nsproxy_test.o"
"$LD64" -arch x86_64 -platform_version $PLATFORM -e _main \
    -o "$T/nsproxy_test" "$T/nsproxy_test.o" \
    "$ROOT/runtime/System/Library/Frameworks/Foundation.framework/Foundation" \
    -undefined dynamic_lookup
out="$(DYLD_ROOT_PATH="$ROOT/runtime" "$RUN" "$T/nsproxy_test" 2>&1)"
check "[proxy] isProxy 1" "$out" "an NSProxy answers isProxy"
check "[proxy] kind 1" "$out" \
    "an NSProxy subclass is a kind of NSProxy"
check "[proxy] forwarded value" "$out" \
    "the proxy's forwardInvocation: receives the selector"
check "[proxy] value 64" "$out" \
    "the proxy's return value reaches the caller"
check "[proxy] done" "$out" "the proxy fixture finishes"

# ---------- 4f10m. arm64 image mapping ----------
# The loader maps an arm64 Mach-O, registers the ObjC classes in it and
# reports its entry without executing arm64 instructions.
"$CC" -target arm64-apple-ios18.0-simulator -fobjc-runtime=ios-18.0 \
    -fno-objc-arc -ffreestanding -O1 \
    -c "$ROOT/tests/arm64_probe.m" -o "$T/arm64_probe.o"
"$LD64" -arch arm64 -platform_version $PLATFORM -e _main \
    -o "$T/arm64_probe" "$T/arm64_probe.o" -undefined dynamic_lookup
out="$(DYLD_ROOT_PATH="$ROOT/runtime" "$RUN" --arm64 --inspect -v \
    "$T/arm64_probe" 2>&1)"
check "arch: arm64" "$out" "the loader selects the arm64 slice"
check "objc: class Arm64Probe" "$out" \
    "the loader registers an arm64 image's ObjC class"
check "arm64 image mapped; execution pending" "$out" \
    "an inspected arm64 image is not executed"

# ---------- 4f10n. arm64 execution ----------
# The interpreter runs an arm64 main with a frame, loop and call, then an
# arm64 ObjC class method reached through objc_msgSend.
"$CC" -target arm64-apple-ios18.0-simulator -ffreestanding -O1 \
    -c "$ROOT/tests/arm64_exec.c" -o "$T/arm64_exec.o"
"$LD64" -arch arm64 -platform_version $PLATFORM -e _main \
    -o "$T/arm64_exec" "$T/arm64_exec.o" -undefined dynamic_lookup
if DYLD_ROOT_PATH="$ROOT/runtime" "$RUN" --arm64 "$T/arm64_exec"; then
    rc=0
else
    rc=$?
fi
if [ "$rc" -eq 46 ]; then
    echo "ok   the arm64 interpreter runs a frame, loop and call"
else
    echo "FAIL arm64 exec (exit $rc)"; fails=$((fails+1))
fi
"$CC" -target arm64-apple-ios18.0-simulator \
    -fobjc-runtime=ios-18.0 -fno-objc-arc -ffreestanding -O1 \
    -c "$ROOT/tests/arm64_msg_send.m" -o "$T/arm64_msg_send.o"
"$LD64" -arch arm64 -platform_version $PLATFORM -e _main \
    -o "$T/arm64_msg_send" "$T/arm64_msg_send.o" -undefined dynamic_lookup
if DYLD_ROOT_PATH="$ROOT/runtime" "$RUN" --arm64 "$T/arm64_msg_send"; then
    rc=0
else
    rc=$?
fi
if [ "$rc" -eq 42 ]; then
    echo "ok   objc_msgSend reaches an arm64 class method"
else
    echo "FAIL arm64 msgSend (exit $rc)"; fails=$((fails+1))
fi

# ---------- 4f10o. arm64 native method bridge ----------
# An arm64 main calls native Foundation: objc_getClass and
# sel_registerName are C gates, and NSString's class and instance methods
# are x86_64 IMPs whose arguments are marshalled by type encoding.
"$CC" -target arm64-apple-ios18.0-simulator -ffreestanding -O1 \
    -c "$ROOT/tests/arm64_native.m" -o "$T/arm64_native.o"
"$LD64" -arch arm64 -platform_version $PLATFORM -e _main \
    -o "$T/arm64_native" "$T/arm64_native.o" -undefined dynamic_lookup
if DYLD_ROOT_PATH="$ROOT/runtime" "$RUN" --arm64 \
    --load-dylib \
    "$ROOT/runtime/System/Library/Frameworks/Foundation.framework/Foundation" \
    "$T/arm64_native"; then
    rc=0
else
    rc=$?
fi
if [ "$rc" -eq 5 ]; then
    echo "ok   an arm64 main calls native NSString through objc_msgSend"
else
    echo "FAIL arm64 native bridge (exit $rc)"; fails=$((fails+1))
fi

# ---------- 4f10p. arm64 printf and floating point ----------
# The printf gate reads Darwin's stack variadic arguments; the FP path
# covers literal loads, FMUL, the fused multiply-add and FCVTZS.
"$CC" -target arm64-apple-ios18.0-simulator -ffreestanding -O1 \
    -c "$ROOT/tests/arm64_hello.c" -o "$T/arm64_hello.o"
"$LD64" -arch arm64 -platform_version $PLATFORM -e _main \
    -o "$T/arm64_hello" "$T/arm64_hello.o" -undefined dynamic_lookup
out="$(DYLD_ROOT_PATH="$ROOT/runtime" "$RUN" --arm64 "$T/arm64_hello")"
check "arm64 hello 42 ok" "$out" \
    "an arm64 main prints stack variadic arguments"
"$CC" -target arm64-apple-ios18.0-simulator -ffreestanding -O1 \
    -c "$ROOT/tests/arm64_float.c" -o "$T/arm64_float.o"
"$LD64" -arch arm64 -platform_version $PLATFORM -e _main \
    -o "$T/arm64_float" "$T/arm64_float.o" -undefined dynamic_lookup
if DYLD_ROOT_PATH="$ROOT/runtime" "$RUN" --arm64 "$T/arm64_float"; then
    rc=0
else
    rc=$?
fi
if [ "$rc" -eq 25 ]; then
    echo "ok   the arm64 interpreter runs floating-point arithmetic"
else
    echo "FAIL arm64 float (exit $rc)"; fails=$((fails+1))
fi

# ---------- 4f10q. arm64 super sends and native C calls ----------
# [super value] reaches GenBase through objc_msgSendSuper2, and plain C
# shims (strlen, calloc/free, strtod, strncmp) use the generic native call
# gate.
"$CC" -target arm64-apple-ios18.0-simulator -fobjc-runtime=ios-18.0 \
    -fno-objc-arc -ffreestanding -O1 \
    -c "$ROOT/tests/arm64_super.m" -o "$T/arm64_super.o"
"$LD64" -arch arm64 -platform_version $PLATFORM -e _main \
    -o "$T/arm64_super" "$T/arm64_super.o" -undefined dynamic_lookup
if out="$(DYLD_ROOT_PATH="$ROOT/runtime" "$RUN" --arm64 \
    "$T/arm64_super")"; then
    rc=0
else
    rc=$?
fi
check "a=9 b=8 n=4 d=5 cmp=0" "$out" \
    "an arm64 main calls a superclass method and C shims"
if [ "$rc" -eq 26 ]; then
    echo "ok   the arm64 super and C shim fixture returns 26"
else
    echo "FAIL arm64 super (exit $rc)"; fails=$((fails+1))
fi
if out_nj="$(IOSIM_ARM64_NOJIT=1 DYLD_ROOT_PATH="$ROOT/runtime" "$RUN" \
    --arm64 "$T/arm64_super")"; then
    rc_nj=0
else
    rc_nj=$?
fi
if [ "$rc_nj" -eq 26 ] && [ "$out_nj" = "$out" ]; then
    echo "ok   the arm64 interpreter and translated blocks agree"
else
    echo "FAIL arm64 interpreter parity (exit $rc_nj)"; fails=$((fails+1))
fi

# ---------- 4f10r. arm64 Foundation, enumeration and blocks ----------
"$CC" -target arm64-apple-ios18.0-simulator -fobjc-runtime=ios-18.0 \
    -fno-objc-arc -ffreestanding -O1 \
    -c "$ROOT/tests/arm64_foundation.m" -o "$T/arm64_foundation.o"
"$LD64" -arch arm64 -platform_version $PLATFORM -e _main \
    -o "$T/arm64_foundation" "$T/arm64_foundation.o" -undefined dynamic_lookup
"$CC" -target arm64-apple-ios18.0-simulator -fobjc-runtime=ios-18.0 \
    -fno-objc-arc -fblocks -ffreestanding -O1 \
    -c "$ROOT/tests/arm64_enum_blocks.m" -o "$T/arm64_enum_blocks.o"
"$LD64" -arch arm64 -platform_version $PLATFORM -e _main \
    -o "$T/arm64_enum_blocks" "$T/arm64_enum_blocks.o" -undefined dynamic_lookup
FOUNDATION_DYLIB="$ROOT/runtime/System/Library/Frameworks/Foundation.framework/Foundation"
if DYLD_ROOT_PATH="$ROOT/runtime" "$RUN" --arm64 --load-dylib \
    "$FOUNDATION_DYLIB" "$T/arm64_foundation"; then
    rc=0
else
    rc=$?
fi
if [ "$rc" -eq 28 ]; then
    echo "ok   an arm64 main parses JSON and doubles numbers through Foundation"
else
    echo "FAIL arm64 foundation (exit $rc)"; fails=$((fails+1))
fi
if out="$(DYLD_ROOT_PATH="$ROOT/runtime" "$RUN" --arm64 --load-dylib \
    "$FOUNDATION_DYLIB" "$T/arm64_enum_blocks")"; then
    rc=0
else
    rc=$?
fi
check "n=4 total=47" "$out" \
    "an arm64 main walks an NSArray with fast enumeration"
if [ "$rc" -eq 191 ]; then
    echo "ok   the arm64 enumeration fixture returns 447"
else
    echo "FAIL arm64 enumeration (exit $rc)"; fails=$((fails+1))
fi

# ---------- 4f10s. arm64 ARC and block copy helpers ----------
"$CC" -target arm64-apple-ios18.0-simulator -fobjc-runtime=ios-18.0 \
    -fobjc-arc -fblocks -ffreestanding -O1 \
    -c "$ROOT/tests/arm64_arc.m" -o "$T/arm64_arc.o"
"$LD64" -arch arm64 -platform_version $PLATFORM -e _main \
    -o "$T/arm64_arc" "$T/arm64_arc.o" -undefined dynamic_lookup
if out="$(DYLD_ROOT_PATH="$ROOT/runtime" "$RUN" --arm64 --load-dylib \
    "$FOUNDATION_DYLIB" "$T/arm64_arc")"; then
    rc=0
else
    rc=$?
fi
check "v=82 w=77 r=85" "$out" \
    "an ARC arm64 main retains objects and copies a __block block"
if [ "$rc" -eq 244 ]; then
    echo "ok   the arm64 ARC fixture returns 244"
else
    echo "FAIL arm64 ARC (exit $rc)"; fails=$((fails+1))
fi

# ---------- 4f10t. arm64 NEON and container round trip ----------
# A clang -O2 loop vectorizes to NEON: 128-bit registers, vector
# immediates, ORR, FMLA and element extraction. The same source is built
# for x86_64 and both exit statuses must agree.
"$CC" -target arm64-apple-ios18.0-simulator -ffreestanding -O2 \
    -c "$ROOT/tests/arm64_vector.c" -o "$T/arm64_vector.o"
"$LD64" -arch arm64 -platform_version $PLATFORM -e _main \
    -o "$T/arm64_vector" "$T/arm64_vector.o" -undefined dynamic_lookup
obj "$ROOT/tests/arm64_vector.c" "$T/arm64_vector_x.o"
exe "$T/arm64_vector_x" "$T/arm64_vector_x.o"
if DYLD_ROOT_PATH="$ROOT/runtime" "$RUN" --arm64 "$T/arm64_vector"; then
    rc_arm=0
else
    rc_arm=$?
fi
if DYLD_ROOT_PATH="$ROOT/runtime" "$RUN" "$T/arm64_vector_x"; then
    rc_x=0
else
    rc_x=$?
fi
if [ "$rc_arm" -eq "$rc_x" ] && [ "$rc_arm" -eq 32 ]; then
    echo "ok   the arm64 NEON loop agrees with its x86_64 build"
else
    echo "FAIL arm64 NEON parity (arm64 $rc_arm, x86_64 $rc_x)"
    fails=$((fails+1))
fi
if IOSIM_ARM64_NOJIT=1 DYLD_ROOT_PATH="$ROOT/runtime" "$RUN" --arm64 \
    "$T/arm64_vector"; then
    rc_nj=0
else
    rc_nj=$?
fi
if [ "$rc_nj" -eq 32 ]; then
    echo "ok   the arm64 NEON loop agrees with pure interpretation"
else
    echo "FAIL arm64 NEON interpreter (exit $rc_nj)"; fails=$((fails+1))
fi

"$CC" -target arm64-apple-ios18.0-simulator -ffreestanding -O2 \
    -c "$ROOT/tests/arm64_matrix.c" -o "$T/arm64_matrix.o"
"$LD64" -arch arm64 -platform_version $PLATFORM -e _main \
    -o "$T/arm64_matrix" "$T/arm64_matrix.o" -undefined dynamic_lookup
if DYLD_ROOT_PATH="$ROOT/runtime" "$RUN" --arm64 "$T/arm64_matrix"; then
    rc=0
else
    rc=$?
fi
if [ "$rc" -eq 43 ]; then
    echo "ok   the arm64 matrix multiply fixture returns 43"
else
    echo "FAIL arm64 matrix (exit $rc)"; fails=$((fails+1))
fi

"$CC" -target arm64-apple-ios18.0-simulator -fobjc-runtime=ios-18.0 \
    -fno-objc-arc -ffreestanding -O2 \
    -c "$ROOT/tests/arm64_dict.m" -o "$T/arm64_dict.o"
"$LD64" -arch arm64 -platform_version $PLATFORM -e _main \
    -o "$T/arm64_dict" "$T/arm64_dict.o" -undefined dynamic_lookup
if out="$(DYLD_ROOT_PATH="$ROOT/runtime" "$RUN" --arm64 --load-dylib \
    "$FOUNDATION_DYLIB" "$T/arm64_dict")"; then
    rc=0
else
    rc=$?
fi
check "total=6 len=5" "$out" \
    "an arm64 main enumerates a dictionary and builds a string"
if [ "$rc" -eq 65 ]; then
    echo "ok   the arm64 dictionary fixture returns 65"
else
    echo "FAIL arm64 dictionary (exit $rc)"; fails=$((fails+1))
fi

# ---------- 4f10u. arm64 methods reached from native code ----------
# Foundation's -performSelector: and -isEqual: run as x86_64 code and send
# messages back into the arm64 image; the reverse bridge marshals the saved
# x86 registers per the method type encoding and returns the result.
"$CC" -target arm64-apple-ios18.0-simulator -ffreestanding -O2 \
    -c "$ROOT/tests/arm64_vector_int.c" -o "$T/arm64_vector_int.o"
"$LD64" -arch arm64 -platform_version $PLATFORM -e _main \
    -o "$T/arm64_vector_int" "$T/arm64_vector_int.o" -undefined dynamic_lookup
obj "$ROOT/tests/arm64_vector_int.c" "$T/arm64_vector_int_x.o"
exe "$T/arm64_vector_int_x" "$T/arm64_vector_int_x.o"
if DYLD_ROOT_PATH="$ROOT/runtime" "$RUN" --arm64 "$T/arm64_vector_int"; then
    rc_arm=0
else
    rc_arm=$?
fi
if DYLD_ROOT_PATH="$ROOT/runtime" "$RUN" "$T/arm64_vector_int_x"; then
    rc_x=0
else
    rc_x=$?
fi
if [ "$rc_arm" -eq "$rc_x" ] && [ "$rc_arm" -eq 168 ]; then
    echo "ok   the arm64 integer vector loop agrees with its x86_64 build"
else
    echo "FAIL arm64 integer vector parity (arm64 $rc_arm, x86_64 $rc_x)"
    fails=$((fails+1))
fi

"$CC" -target arm64-apple-ios18.0-simulator -fobjc-runtime=ios-18.0 \
    -fno-objc-arc -ffreestanding -O1 \
    -c "$ROOT/tests/arm64_reverse.m" -o "$T/arm64_reverse.o"
"$LD64" -arch arm64 -platform_version $PLATFORM -e _main \
    -o "$T/arm64_reverse" "$T/arm64_reverse.o" -undefined dynamic_lookup
if out="$(DYLD_ROOT_PATH="$ROOT/runtime" "$RUN" --arm64 --load-dylib \
    "$FOUNDATION_DYLIB" "$T/arm64_reverse")"; then
    rc=0
else
    rc=$?
fi
check "c=1 hit=42" "$out" \
    "native Foundation sends messages back to an arm64 object"
if [ "$rc" -eq 77 ]; then
    echo "ok   the arm64 reverse-message fixture returns 77"
else
    echo "FAIL arm64 reverse message (exit $rc)"; fails=$((fails+1))
fi

# ---------- 4f10v. arm64 atomics ----------
# clang emits LSE read-modify-write and CAS forms, LDAPR acquire loads and
# LDAR/STLR; the baseline fixture adds LL/SC exclusives. The x86_64 build
# and pure interpretation must agree with the translated run.
"$CC" -target arm64-apple-ios18.0-simulator -ffreestanding -O2 \
    -c "$ROOT/tests/arm64_atomic.c" -o "$T/arm64_atomic.o"
"$LD64" -arch arm64 -platform_version $PLATFORM -e _main \
    -o "$T/arm64_atomic" "$T/arm64_atomic.o" -undefined dynamic_lookup
obj "$ROOT/tests/arm64_atomic.c" "$T/arm64_atomic_x.o"
exe "$T/arm64_atomic_x" "$T/arm64_atomic_x.o"
if DYLD_ROOT_PATH="$ROOT/runtime" "$RUN" --arm64 "$T/arm64_atomic"; then
    rc_arm=0
else
    rc_arm=$?
fi
if DYLD_ROOT_PATH="$ROOT/runtime" "$RUN" "$T/arm64_atomic_x"; then
    rc_x=0
else
    rc_x=$?
fi
if [ "$rc_arm" -eq "$rc_x" ] && [ "$rc_arm" -eq 107 ]; then
    echo "ok   the arm64 atomic fixture agrees with its x86_64 build"
else
    echo "FAIL arm64 atomic parity (arm64 $rc_arm, x86_64 $rc_x)"
    fails=$((fails+1))
fi
if IOSIM_ARM64_NOJIT=1 DYLD_ROOT_PATH="$ROOT/runtime" "$RUN" --arm64 \
    "$T/arm64_atomic"; then
    rc_nj=0
else
    rc_nj=$?
fi
if [ "$rc_nj" -eq 107 ]; then
    echo "ok   the arm64 atomic fixture agrees with pure interpretation"
else
    echo "FAIL arm64 atomic interpreter (exit $rc_nj)"; fails=$((fails+1))
fi

# ---------- 4f10w. native C callbacks into arm64 ----------
# qsort and bsearch run as native shims; their comparator is arm64 guest
# code called back through the callback bridge, and the string comparator
# calls the native strcmp from inside the bridged call.
"$CC" -target arm64-apple-ios18.0-simulator -ffreestanding -O1 \
    -c "$ROOT/tests/arm64_callback.c" -o "$T/arm64_callback.o"
"$LD64" -arch arm64 -platform_version $PLATFORM -e _main \
    -o "$T/arm64_callback" "$T/arm64_callback.o" -undefined dynamic_lookup
obj "$ROOT/tests/arm64_callback.c" "$T/arm64_callback_x.o"
exe "$T/arm64_callback_x" "$T/arm64_callback_x.o"
if out="$(DYLD_ROOT_PATH="$ROOT/runtime" "$RUN" --arm64 "$T/arm64_callback")"; then
    rc_arm=0
else
    rc_arm=$?
fi
check "1 2 3 4 5" "$out" "an arm64 comparator sorts integers under native qsort"
check "apple banana fig pear" "$out" \
    "an arm64 comparator sorts strings and bsearch finds a key"
if [ "$rc_arm" -eq 33 ]; then
    echo "ok   the arm64 callback fixture returns 33"
else
    echo "FAIL arm64 callback (exit $rc_arm)"; fails=$((fails+1))
fi
if DYLD_ROOT_PATH="$ROOT/runtime" "$RUN" "$T/arm64_callback_x"; then
    rc_x=0
else
    rc_x=$?
fi
if [ "$rc_x" -eq 33 ]; then
    echo "ok   the x86_64 callback fixture returns 33"
else
    echo "FAIL x86_64 callback (exit $rc_x)"; fails=$((fails+1))
fi
if IOSIM_ARM64_NOJIT=1 DYLD_ROOT_PATH="$ROOT/runtime" "$RUN" --arm64 \
    "$T/arm64_callback"; then
    rc_nj=0
else
    rc_nj=$?
fi
if [ "$rc_nj" -eq 33 ]; then
    echo "ok   the arm64 callback fixture agrees with pure interpretation"
else
    echo "FAIL arm64 callback interpreter (exit $rc_nj)"; fails=$((fails+1))
fi

# ---------- 4f10x. arm64 struct ABI and FP printf ----------
# Small aggregates return in registers, a three-long struct through the
# x8 result pointer, and an HFA of floats in d0/d1. printf renders a
# variadic double from its stack slot.
"$CC" -target arm64-apple-ios18.0-simulator -ffreestanding -O2 \
    -c "$ROOT/tests/arm64_struct.c" -o "$T/arm64_struct.o"
"$LD64" -arch arm64 -platform_version $PLATFORM -e _main \
    -o "$T/arm64_struct" "$T/arm64_struct.o" -undefined dynamic_lookup
obj "$ROOT/tests/arm64_struct.c" "$T/arm64_struct_x.o"
exe "$T/arm64_struct_x" "$T/arm64_struct_x.o"
if out="$(DYLD_ROOT_PATH="$ROOT/runtime" "$RUN" --arm64 "$T/arm64_struct")"; then
    rc_arm=0
else
    rc_arm=$?
fi
check "p=50 t=12 v=4.0" "$out" \
    "an arm64 main passes and returns structs by value"
if [ "$rc_arm" -eq 51 ]; then
    echo "ok   the arm64 struct fixture returns 51"
else
    echo "FAIL arm64 struct ABI (exit $rc_arm)"; fails=$((fails+1))
fi
if out_x="$(DYLD_ROOT_PATH="$ROOT/runtime" "$RUN" "$T/arm64_struct_x")"; then
    rc_x=0
else
    rc_x=$?
fi
check "p=50 t=12 v=4.0" "$out_x" \
    "the x86_64 struct fixture prints the same values"
if [ "$rc_x" -eq 51 ]; then
    echo "ok   the x86_64 struct fixture returns 51"
else
    echo "FAIL x86_64 struct ABI (exit $rc_x)"; fails=$((fails+1))
fi
if IOSIM_ARM64_NOJIT=1 DYLD_ROOT_PATH="$ROOT/runtime" "$RUN" --arm64 \
    "$T/arm64_struct"; then
    rc_nj=0
else
    rc_nj=$?
fi
if [ "$rc_nj" -eq 51 ]; then
    echo "ok   the arm64 struct fixture agrees with pure interpretation"
else
    echo "FAIL arm64 struct interpreter (exit $rc_nj)"; fails=$((fails+1))
fi

# ---------- 4f10y. arm64 calls framework C functions ----------
# CACurrentMediaTime and the accessibility queries are exported by the
# native framework dylibs, not loader shims; the arm64 call gate resolves
# them through the recorded native symbol map.
"$CC" -target arm64-apple-ios18.0-simulator -ffreestanding -O1 \
    -c "$ROOT/tests/arm64_framework_calls.c" -o "$T/arm64_framework_calls.o"
"$LD64" -arch arm64 -platform_version $PLATFORM -e _main \
    -o "$T/arm64_framework_calls" "$T/arm64_framework_calls.o" \
    -undefined dynamic_lookup
FW_ARGS="--load-dylib $ROOT/runtime/System/Library/Frameworks/Foundation.framework/Foundation --load-dylib $ROOT/runtime/System/Library/Frameworks/UIKit.framework/UIKit --load-dylib $ROOT/runtime/System/Library/Frameworks/QuartzCore.framework/QuartzCore"
if out="$(DYLD_ROOT_PATH="$ROOT/runtime" "$RUN" --arm64 $FW_ARGS \
    "$T/arm64_framework_calls")"; then
    rc=0
else
    rc=$?
fi
check "motion=0 voice=0" "$out" \
    "an arm64 main calls C functions exported by framework dylibs"
if [ "$rc" -eq 64 ]; then
    echo "ok   the arm64 framework-call fixture returns 64"
else
    echo "FAIL arm64 framework calls (exit $rc)"; fails=$((fails+1))
fi
if IOSIM_ARM64_NOJIT=1 DYLD_ROOT_PATH="$ROOT/runtime" "$RUN" --arm64 \
    $FW_ARGS "$T/arm64_framework_calls" >/dev/null; then
    rc_nj=0
else
    rc_nj=$?
fi
if [ "$rc_nj" -eq 64 ]; then
    echo "ok   the arm64 framework-call fixture agrees with pure interpretation"
else
    echo "FAIL arm64 framework calls interpreter (exit $rc_nj)"; fails=$((fails+1))
fi

# ---------- 4f10z. arm64 aggregates across the native bridge ----------
# Native methods return an NSRange in x0/x1 and a CGRect HFA in d0-d3, take
# a CGRect HFA on the stack and a CGAffineTransform by pointer, and hand a
# forty-eight-byte transform back through the x8 result buffer. The x86_64
# build and pure interpretation must agree with the translated run.
"$CC" -target arm64-apple-ios18.0-simulator -fobjc-runtime=ios-18.0 \
    -fno-objc-arc -ffreestanding -O1 \
    -c "$ROOT/tests/arm64_aggregate.m" -o "$T/arm64_aggregate.o"
"$LD64" -arch arm64 -platform_version $PLATFORM -e _main \
    -o "$T/arm64_aggregate" "$T/arm64_aggregate.o" -undefined dynamic_lookup
"$CC" -target x86_64-apple-ios18.0-simulator -fobjc-runtime=ios-18.0 \
    -fno-objc-arc -ffreestanding -O1 \
    -c "$ROOT/tests/arm64_aggregate.m" -o "$T/arm64_aggregate_x.o"
"$LD64" -arch x86_64 -platform_version $PLATFORM -e _main \
    -o "$T/arm64_aggregate_x" "$T/arm64_aggregate_x.o" \
    -undefined dynamic_lookup
if out="$(DYLD_ROOT_PATH="$ROOT/runtime" "$RUN" --arm64 $FW_ARGS \
    "$T/arm64_aggregate")"; then
    rc_arm=0
else
    rc_arm=$?
fi
check "sub=world range=6,5" "$out" \
    "an arm64 main receives an NSRange in x0/x1"
check "center=12.5,34.5 frame=10,20,100,50" "$out" \
    "arm64 passes a CGRect on the stack and receives one in d0-d3"
check "transform=1,2,3,4,5,6" "$out" \
    "arm64 passes a large struct by pointer and receives it through x8"
if [ "$rc_arm" -eq 93 ]; then
    echo "ok   the arm64 aggregate fixture returns 93"
else
    echo "FAIL arm64 aggregate ABI (exit $rc_arm)"; fails=$((fails+1))
fi
if out_x="$(DYLD_ROOT_PATH="$ROOT/runtime" "$RUN" $FW_ARGS \
    "$T/arm64_aggregate_x")"; then
    rc_x=0
else
    rc_x=$?
fi
check "transform=1,2,3,4,5,6" "$out_x" \
    "the x86_64 aggregate fixture prints the same values"
if [ "$rc_x" -eq 93 ]; then
    echo "ok   the x86_64 aggregate fixture returns 93"
else
    echo "FAIL x86_64 aggregate ABI (exit $rc_x)"; fails=$((fails+1))
fi
if IOSIM_ARM64_NOJIT=1 DYLD_ROOT_PATH="$ROOT/runtime" "$RUN" --arm64 \
    $FW_ARGS "$T/arm64_aggregate" >/dev/null; then
    rc_nj=0
else
    rc_nj=$?
fi
if [ "$rc_nj" -eq 93 ]; then
    echo "ok   the arm64 aggregate fixture agrees with pure interpretation"
else
    echo "FAIL arm64 aggregate ABI interpreter (exit $rc_nj)"
    fails=$((fails+1))
fi

# ---------- 4f10aa. arm64 runtime-generated code pages ----------
# A guest mmap or mprotect with PROT_EXEC registers the range as guest
# code, so a call through a pointer into the page enters the interpreter
# and the block translator. Rewriting a page and re-protecting it drops
# the cached translation; the trace check proves the translator compiled
# the page rather than only falling back to the interpreter.
"$CC" -target arm64-apple-ios18.0-simulator -ffreestanding -O1 \
    -c "$ROOT/tests/arm64_jitpage.c" -o "$T/arm64_jitpage.o"
"$LD64" -arch arm64 -platform_version $PLATFORM -e _main \
    -o "$T/arm64_jitpage" "$T/arm64_jitpage.o" -undefined dynamic_lookup
if out="$(DYLD_ROOT_PATH="$ROOT/runtime" "$RUN" --arm64 "$T/arm64_jitpage")"
then
    rc_arm=0
else
    rc_arm=$?
fi
check "jit=61,127 mprotect=61 reprotect=62" "$out" \
    "arm64 code copied into executable pages runs"
if [ "$rc_arm" -eq 96 ]; then
    echo "ok   the arm64 JIT-page fixture returns 96"
else
    echo "FAIL arm64 JIT page (exit $rc_arm)"; fails=$((fails+1))
fi
if out_t="$(IOSIM_ARM64_JIT_TRACE=1 DYLD_ROOT_PATH="$ROOT/runtime" "$RUN" \
    --arm64 "$T/arm64_jitpage" 2>&1)"; then
    rc_t=0
else
    rc_t=$?
fi
# The page address must come from the traced run itself; a separate run
# maps the page at a different address.
page=$(printf '%s\n' "$out_t" | sed -n 's/^page=//p')
if [ -n "$page" ] && printf '%s\n' "$out_t" | grep -q "jit block 0x$page"; then
    echo "ok   the block translator compiles the generated page"
else
    echo "FAIL the generated page was not translated"; fails=$((fails+1))
fi
if [ "$rc_t" -eq 96 ]; then
    echo "ok   the traced JIT-page run returns 96"
else
    echo "FAIL traced JIT-page run (exit $rc_t)"; fails=$((fails+1))
fi
if IOSIM_ARM64_NOJIT=1 DYLD_ROOT_PATH="$ROOT/runtime" "$RUN" --arm64 \
    "$T/arm64_jitpage" >/dev/null; then
    rc_nj=0
else
    rc_nj=$?
fi
if [ "$rc_nj" -eq 96 ]; then
    echo "ok   the JIT-page fixture agrees with pure interpretation"
else
    echo "FAIL JIT-page interpreter (exit $rc_nj)"; fails=$((fails+1))
fi

# ---------- 4f10ab. one UIKit source, two architectures ----------
# The scene delegate, view hierarchy and delayed capture block are arm64
# app code on the interpreter/translator; UIKit, QuartzCore and
# libdispatch stay native x86_64 and call back through the reverse bridge
# and the block bridge. The x86_64 build of the same source and the pure
# interpreter must render the same pixels.
rm -f "$T/arm64uikit.fifo"
mkfifo "$T/arm64uikit.fifo"
"$CC" -target arm64-apple-ios18.0-simulator -ffreestanding \
    -fobjc-runtime=ios-18.0 -fno-objc-arc -fblocks -O1 -I "$ROOT/demo" \
    -c "$ROOT/tests/arm64_uikit.m" -o "$T/arm64_uikit.o"
"$LD64" -arch arm64 -platform_version $PLATFORM -e _main \
    -o "$T/arm64_uikit" "$T/arm64_uikit.o" -undefined dynamic_lookup
if out="$(IOSIM_EVENT_FIFO="$T/arm64uikit.fifo" \
    IOSIM_TEST_PNG="$T/arm64_uikit.png" DYLD_ROOT_PATH="$ROOT/runtime" \
    timeout 15 "$RUN" --arm64 $FW_ARGS "$T/arm64_uikit" 2>&1)"; then
    rc=0
else
    rc=$?
fi
rm -f "$T/arm64uikit.fifo"
check "[arm64uikit] ready" "$out" \
    "an arm64 UIKit app runs its scene delegate and captures a frame"
if [ "$rc" -eq 0 ]; then
    echo "ok   the arm64 UIKit fixture exits after its capture"
else
    echo "FAIL arm64 UIKit app (exit $rc)"; fails=$((fails+1))
fi
rm -f "$T/arm64uikit_x.fifo"
mkfifo "$T/arm64uikit_x.fifo"
"$ROOT/tools/build_app.sh" "$ROOT/tests/arm64_uikit.m" \
    "$T/arm64_uikit_x" >/dev/null
if out_x="$(IOSIM_EVENT_FIFO="$T/arm64uikit_x.fifo" \
    IOSIM_TEST_PNG="$T/arm64_uikit_x.png" DYLD_ROOT_PATH="$ROOT/runtime" \
    timeout 15 "$RUN" "$T/arm64_uikit_x" 2>&1)"; then
    rc_x=0
else
    rc_x=$?
fi
rm -f "$T/arm64uikit_x.fifo"
check "[arm64uikit] ready" "$out_x" \
    "the x86_64 build of the same fixture captures the same scene"
if [ "$rc_x" -eq 0 ]; then
    echo "ok   the x86_64 UIKit fixture exits after its capture"
else
    echo "FAIL x86_64 UIKit app (exit $rc_x)"; fails=$((fails+1))
fi
rm -f "$T/arm64uikit_nj.fifo"
mkfifo "$T/arm64uikit_nj.fifo"
if out_nj="$(IOSIM_ARM64_NOJIT=1 IOSIM_EVENT_FIFO="$T/arm64uikit_nj.fifo" \
    IOSIM_TEST_PNG="$T/arm64_uikit_nj.png" DYLD_ROOT_PATH="$ROOT/runtime" \
    timeout 15 "$RUN" --arm64 $FW_ARGS "$T/arm64_uikit" 2>&1)"; then
    rc_nj=0
else
    rc_nj=$?
fi
rm -f "$T/arm64uikit_nj.fifo"
if [ "$rc_nj" -eq 0 ]; then
    echo "ok   the interpreted arm64 UIKit app exits after its capture"
else
    echo "FAIL interpreted arm64 UIKit app (exit $rc_nj)"; fails=$((fails+1))
fi
if python3 - "$ROOT/tools" "$T/arm64_uikit.png" "$T/arm64_uikit_x.png" \
    "$T/arm64_uikit_nj.png" <<'PY'
import sys
sys.path.insert(0, sys.argv[1])
import pngpixel

def sample(path):
    w, h, bpp, rows = pngpixel.load(path)
    pts = []
    for x, y in ((100, 140), (100, 260), (100, 380), (350, 800)):
        c = pngpixel.px(rows, bpp, x * 3, y * 3)
        pts.append(((c >> 16) & 255, (c >> 8) & 255, c & 255))
    white = 0
    for yy in range(480 * 3, 528 * 3):
        for xx in range(40 * 3, 360 * 3):
            c = pngpixel.px(rows, bpp, xx, yy)
            r, g, b = (c >> 16) & 255, (c >> 8) & 255, c & 255
            if r > 200 and g > 200 and b > 200:
                white += 1
    return pts, white

want = [(255, 0, 0), (0, 255, 0), (0, 0, 255), (0, 0, 0)]
seen = {}
for path, name in ((sys.argv[2], 'arm64'), (sys.argv[3], 'x86_64'),
                   (sys.argv[4], 'arm64-interpreted')):
    pts, white = sample(path)
    if pts != want:
        raise SystemExit('%s sample pixels are %r' % (name, pts))
    if white < 200:
        raise SystemExit('%s label drew only %d white pixels' %
                         (name, white))
    seen[name] = (pts, white)
if not (seen['arm64'] == seen['x86_64'] == seen['arm64-interpreted']):
    raise SystemExit('the three renders differ')
print("ok   the arm64 app, its interpreter run and the x86_64 build "
      "render the same scene")
PY
then
    :
else
    echo "FAIL dual-architecture UIKit pixels"; fails=$((fails+1))
fi

# ---------- 4f10ac. persistent block cache ----------
# With IOSIM_ARM64_CACHE_DIR set, translated image blocks are written to
# <uuid>.blocks and a second launch loads them instead of decoding the
# arm64 again; guest addresses and helper pointers are patched for the
# new slide. Runtime-generated code pages are never cached.
cache="$T/jitcache"
rm -rf "$cache"
mkdir -p "$cache"
if out1="$(IOSIM_ARM64_CACHE_DIR="$cache" IOSIM_ARM64_JIT_TRACE=1 \
    DYLD_ROOT_PATH="$ROOT/runtime" "$RUN" --arm64 "$T/arm64_struct" 2>&1)"
then
    rc1=0
else
    rc1=$?
fi
n1=$(printf '%s\n' "$out1" | grep -c "jit block" 2>/dev/null || true)
if out2="$(IOSIM_ARM64_CACHE_DIR="$cache" IOSIM_ARM64_JIT_TRACE=1 \
    DYLD_ROOT_PATH="$ROOT/runtime" "$RUN" --arm64 "$T/arm64_struct" 2>&1)"
then
    rc2=0
else
    rc2=$?
fi
n2=$(printf '%s\n' "$out2" | grep -c "jit block" 2>/dev/null || true)
nc=$(printf '%s\n' "$out2" | grep -c "jit cached" 2>/dev/null || true)
check "p=50 t=12 v=4.0" "$out2" \
    "a cached second run prints the same values"
if [ "$rc1" -eq 51 ] && [ "$rc2" -eq 51 ]; then
    echo "ok   both cached runs return 51"
else
    echo "FAIL cached runs (exit $rc1, $rc2)"; fails=$((fails+1))
fi
if ls "$cache"/*.blocks >/dev/null 2>&1; then
    echo "ok   the block cache file was written"
else
    echo "FAIL the block cache file is missing"; fails=$((fails+1))
fi
if [ "$n1" -gt 0 ] && [ "$n2" -eq 0 ] && [ "$nc" -gt 0 ]; then
    echo "ok   the second launch loads blocks from the cache"
else
    echo "FAIL block cache (translated $n1 then $n2, cached $nc)"
    fails=$((fails+1))
fi

# ---------- 4f11. CAAnimation completion and fill modes ----------
rm -f "$T/arem.fifo"
mkfifo "$T/arem.fifo"
"$ROOT/tools/build_app.sh" "$ROOT/tests/animation_removal_test.m" \
    "$T/animation_removal_test" >/dev/null
out="$(IOSIM_EVENT_FIFO="$T/arem.fifo" DYLD_ROOT_PATH="$ROOT/runtime" \
    "$RUN" "$T/animation_removal_test" 2>&1)"
rm -f "$T/arem.fifo"
check "[arem] ready" "$out" \
    "the animation removal fixture starts"
check "[arem] done" "$out" \
    "the animation removal fixture samples both phases"
if out="$(python3 - "$out" <<'PY'
import re
import sys

vals = {}
for line in sys.argv[1].splitlines():
    m = re.match(r'\[arem\] (mid|end) ([-0-9.]+) ([-0-9.]+) ([-0-9.]+)$',
                 line)
    if m:
        vals[m.group(1)] = tuple(float(m.group(i)) for i in (2, 3, 4))
    m = re.match(r'\[arem\] keep (\d) (\d) (\d)$', line)
    if m:
        vals['keep'] = tuple(int(m.group(i)) for i in (1, 2, 3))
for name in ('mid', 'end', 'keep'):
    if name not in vals:
        raise SystemExit('missing %s sample: %r' % (name, vals))
if not all(0.55 <= v <= 0.68 for v in vals['mid']):
    raise SystemExit('mid animation values are off: %r' % (vals['mid'],))
fade, hold, keep = vals['end']
if not 0.95 <= fade <= 1.05:
    raise SystemExit('removed animation did not restore the model: %.2f' %
                     fade)
if not 0.20 <= hold <= 0.30:
    raise SystemExit('forward fill did not hold the final value: %.2f' %
                     hold)
if not 0.95 <= keep <= 1.05:
    raise SystemExit('unfilled animation did not restore the model: %.2f' %
                     keep)
if vals['keep'] != (0, 1, 1):
    raise SystemExit('animationForKey membership is wrong: %r' %
                     (vals['keep'],))
print("ok   completed animations are removed or kept by fill mode")
PY
)"; then
    echo "$out"
else
    echo "FAIL animation completion"; echo "$out"; fails=$((fails+1))
fi

# ---------- 4f11b. CATransition fade ----------
"$ROOT/tools/build_app.sh" "$ROOT/tests/catransition_test.m" \
    "$T/catransition_test" >/dev/null
out="$(DYLD_ROOT_PATH="$ROOT/runtime" "$RUN" "$T/catransition_test" 2>&1)"
check "[ctrans] props fade fromLeft 0.20 0.80" "$out" \
    "CATransition stores its type, subtype and progress window"
check "[ctrans] done" "$out" "the CATransition fixture finishes"
if out="$(python3 - "$out" <<'PY'
import re
import sys

vals = {}
for line in sys.argv[1].splitlines():
    m = re.match(r'\[ctrans\] (early|late|push) ([-0-9.]+)$', line)
    if m:
        vals[m.group(1)] = float(m.group(2))
for name in ('early', 'late', 'push'):
    if name not in vals:
        raise SystemExit('missing %s sample: %r' % (name, vals))
if not 0.15 <= vals['early'] <= 0.65:
    raise SystemExit('the fade is not mid-flight: %r' % (vals['early'],))
if abs(vals['late'] - 1.0) > 0.02:
    raise SystemExit('the fade did not settle: %r' % (vals['late'],))
if abs(vals['push'] - 1.0) > 0.02:
    raise SystemExit('a push transition changed opacity: %r' % (vals['push'],))
print("ok   a CATransition fade animates the layer opacity")
PY
)"; then
    echo "$out"
else
    echo "FAIL CATransition fade"; echo "$out"; fails=$((fails+1))
fi

# ---------- 4f12. UIViewPropertyAnimator timing parameters ----------
rm -f "$T/pram.fifo"
mkfifo "$T/pram.fifo"
"$ROOT/tools/build_app.sh" "$ROOT/tests/property_animator_test.m" \
    "$T/property_animator_test" >/dev/null
out="$(IOSIM_EVENT_FIFO="$T/pram.fifo" DYLD_ROOT_PATH="$ROOT/runtime" \
    "$RUN" "$T/property_animator_test" 2>&1)"
rm -f "$T/pram.fifo"
check "[pram] ready" "$out" \
    "the property animator timing fixture starts"
check "[pram] done" "$out" \
    "the property animator fixture samples both animators"
if out="$(python3 - "$out" <<'PY'
import re
import sys

vals = {}
for line in sys.argv[1].splitlines():
    m = re.match(r'\[pram\] timing ([-0-9.]+) ([-0-9.]+) ([-0-9.]+)$', line)
    if m:
        vals['timing'] = tuple(float(m.group(i)) for i in (1, 2, 3))
    m = re.match(r'\[pram\] mid ([-0-9.]+) ([-0-9.]+)$', line)
    if m:
        vals['mid'] = (float(m.group(1)), float(m.group(2)))
    m = re.match(r'\[pram\] end ([-0-9.]+) ([-0-9.]+) (\d+) (\d+)$', line)
    if m:
        vals['end'] = (float(m.group(1)), float(m.group(2)),
                       int(m.group(3)), int(m.group(4)))
for name in ('timing', 'mid', 'end'):
    if name not in vals:
        raise SystemExit('missing %s sample: %r' % (name, vals))
x2, ratio, settling = vals['timing']
if abs(x2 - 0.58) > 0.02 or abs(ratio - 0.5) > 0.02:
    raise SystemExit('timing parameters are off: %r' % (vals['timing'],))
if not 1.30 <= settling <= 1.45:
    raise SystemExit('spring settling duration is off: %.2f' % settling)
cubic, spring = vals['mid']
if not 55.0 <= cubic <= 85.0:
    raise SystemExit('cubic Bezier did not ease slowly: %.1f' % cubic)
if not 241.0 <= spring <= 275.0:
    raise SystemExit('spring animator did not overshoot: %.1f' % spring)
if spring < cubic + 100.0:
    raise SystemExit('animator mid samples did not separate: %.1f %.1f' %
                     (cubic, spring))
end_cubic, end_spring, state_cubic, state_spring = vals['end']
if not (239.0 <= end_cubic <= 241.0 and 239.0 <= end_spring <= 241.0):
    raise SystemExit('animators did not reach the target: %r' %
                     (vals['end'],))
if state_cubic != 0 or state_spring != 0:
    raise SystemExit('animators did not return to inactive: %r' %
                     (vals['end'],))
print("ok   property animators honor cubic and spring timing parameters")
PY
)"; then
    echo "$out"
else
    echo "FAIL property animator timing"; echo "$out"; fails=$((fails+1))
fi

# ---------- 4f13. UICollectionView compositional layout ----------
rm -f "$T/comp.fifo"
mkfifo "$T/comp.fifo"
"$ROOT/tools/build_app.sh" "$ROOT/tests/collection_compositional_test.m" \
    "$T/collection_compositional_test" >/dev/null
out="$(IOSIM_EVENT_FIFO="$T/comp.fifo" IOSIM_TEST_PNG="$T/comp.png" \
    DYLD_ROOT_PATH="$ROOT/runtime" "$RUN" "$T/collection_compositional_test" \
    2>&1)"
rm -f "$T/comp.fifo"
check "[comp] ready" "$out" \
    "the compositional layout fixture starts"
check "[comp] done" "$out" \
    "the compositional layout fixture lays out its sections"
if out="$(python3 - "$out" <<'PY'
import re
import sys

frames = {}
sizes = {}
tap = None
tapstate = None
for line in sys.argv[1].splitlines():
    m = re.match(
        r'\[comp\] (simple|nested|provider) (\d+) '
        r'([-0-9.]+) ([-0-9.]+) ([-0-9.]+) ([-0-9.]+)$', line)
    if m:
        frames[(m.group(1), int(m.group(2)))] = tuple(
            float(m.group(i)) for i in (3, 4, 5, 6))
        continue
    m = re.match(r'\[comp\] (simple|nested|provider) size '
                 r'([-0-9.]+) ([-0-9.]+)$', line)
    if m:
        sizes[m.group(1)] = (float(m.group(2)), float(m.group(3)))
        continue
    m = re.match(r'\[comp\] tap (\d+) (\d+)$', line)
    if m:
        tap = (int(m.group(1)), int(m.group(2)))
    m = re.match(r'\[comp\] tapstate (\d+) (\d+)$', line)
    if m:
        tapstate = (int(m.group(1)), int(m.group(2)))

expected = {
    ('simple', 0): (20.0, 15.0, 176.0, 80.0),
    ('simple', 1): (206.0, 15.0, 176.0, 80.0),
    ('simple', 2): (20.0, 105.0, 176.0, 80.0),
    ('simple', 9): (206.0, 375.0, 176.0, 80.0),
    ('nested', 0): (20.0, 15.0, 181.0, 100.0),
    ('nested', 1): (20.0, 115.0, 181.0, 100.0),
    ('nested', 2): (201.0, 15.0, 181.0, 100.0),
    ('nested', 3): (201.0, 115.0, 181.0, 100.0),
    ('nested', 7): (201.0, 325.0, 181.0, 100.0),
    ('provider', 0): (20.0, 15.0, 176.0, 80.0),
    ('provider', 10): (20.0, 485.0, 176.0, 80.0),
    ('provider', 19): (206.0, 845.0, 176.0, 80.0),
}
for key, want in expected.items():
    if key not in frames:
        raise SystemExit('missing frame %r' % (key,))
    got = frames[key]
    for a, b in zip(got, want):
        if abs(a - b) > 0.6:
            raise SystemExit('frame %r is %r, expected %r' %
                             (key, got, want))
expected_sizes = {
    'simple': (402.0, 470.0),
    'nested': (402.0, 440.0),
    'provider': (402.0, 940.0),
}
for name, want in expected_sizes.items():
    if name not in sizes:
        raise SystemExit('missing content size for %s' % name)
    got = sizes[name]
    for a, b in zip(got, want):
        if abs(a - b) > 0.6:
            raise SystemExit('content size %s is %r, expected %r' %
                             (name, got, want))
if tap != (0, 2) or tapstate != (0, 2):
    raise SystemExit('tap hit-testing disagrees: %r %r' % (tap, tapstate))
print("ok   compositional groups, sections and hit-testing share one layout")
PY
)"; then
    echo "$out"
else
    echo "FAIL compositional layout"; echo "$out"; fails=$((fails+1))
fi
if out="$(python3 - "$ROOT/tools" "$T/comp.png" <<'PY'
import sys
sys.path.insert(0, sys.argv[1])
import pngpixel

w, h, bpp, rows = pngpixel.load(sys.argv[2])
samples = [
    ('cell', 100, 150, True),
    ('gap', 200, 150, False),
    ('cell', 250, 150, True),
    ('nested', 100, 700, True),
    ('nested', 300, 700, True),
]
for name, x, y, expect_white in samples:
    c = pngpixel.px(rows, bpp, x * 3, y * 3)
    r, g, b = (c >> 16) & 255, (c >> 8) & 255, c & 255
    white = r > 200 and g > 200 and b > 200
    dark = r < 60 and g < 60 and b < 60
    if expect_white and not white:
        raise SystemExit('%s sample at %d,%d is not white: %06x' %
                         (name, x, y, c))
    if not expect_white and not dark:
        raise SystemExit('%s sample at %d,%d is not black: %06x' %
                         (name, x, y, c))
print("ok   the renderer draws compositional cells at the computed frames")
PY
)"; then
    echo "$out"
else
    echo "FAIL compositional rendering"; echo "$out"; fails=$((fails+1))
fi

# ---------- 4f14. CoreGraphics blend modes ----------
rm -f "$T/blend.fifo"
mkfifo "$T/blend.fifo"
"$ROOT/tools/build_app.sh" "$ROOT/tests/blend_mode_test.m" \
    "$T/blend_mode_test" >/dev/null
out="$(IOSIM_EVENT_FIFO="$T/blend.fifo" IOSIM_TEST_PNG="$T/blend.png" \
    DYLD_ROOT_PATH="$ROOT/runtime" "$RUN" "$T/blend_mode_test" 2>&1)"
rm -f "$T/blend.fifo"
check "[blend] ready" "$out" \
    "the blend mode fixture starts"
check "[blend] done" "$out" \
    "the blend mode fixture draws its boxes"
if out="$(python3 - "$ROOT/tools" "$T/blend.png" <<'PY'
import sys
sys.path.insert(0, sys.argv[1])
import pngpixel

w, h, bpp, rows = pngpixel.load(sys.argv[2])
samples = [
    ('multiply', 54, 142, (128, 0, 0)),
    ('screen', 106, 142, (255, 128, 128)),
    ('darken', 158, 142, (128, 0, 0)),
    ('lighten', 210, 142, (255, 128, 128)),
    ('difference', 262, 142, (127, 128, 128)),
    ('pluslighter', 314, 142, (255, 128, 128)),
    ('copy', 54, 212, (255, 0, 0)),
    ('clear', 106, 212, (0, 0, 0)),
    ('destout', 158, 212, (0, 0, 0)),
    ('plusdarker', 210, 212, (128, 0, 0)),
    ('pathmultiply', 262, 212, (128, 0, 0)),
]
for name, x, y, want in samples:
    c = pngpixel.px(rows, bpp, x * 3, y * 3)
    got = ((c >> 16) & 255, (c >> 8) & 255, c & 255)
    for a, b in zip(got, want):
        if abs(a - b) > 4:
            raise SystemExit('%s pixel at %d,%d is %r, expected %r' %
                             (name, x, y, got, want))
print("ok   blend modes composite fills and paths channel-wise")
PY
)"; then
    echo "$out"
else
    echo "FAIL blend modes"; echo "$out"; fails=$((fails+1))
fi

# ---------- 4f15. Horizontal collection flow layout ----------
rm -f "$T/hflow.fifo"
mkfifo "$T/hflow.fifo"
"$ROOT/tools/build_app.sh" "$ROOT/tests/horizontal_collection_test.m" \
    "$T/horizontal_collection_test" >/dev/null
out="$(IOSIM_EVENT_FIFO="$T/hflow.fifo" IOSIM_TEST_PNG="$T/hflow.png" \
    DYLD_ROOT_PATH="$ROOT/runtime" "$RUN" "$T/horizontal_collection_test" \
    2>&1)"
rm -f "$T/hflow.fifo"
check "[hflow] ready" "$out" \
    "the horizontal collection fixture starts"
check "[hflow] done" "$out" \
    "the horizontal collection fixture scrolls its content"
if out="$(python3 - "$out" <<'PY'
import re
import sys

frames = {}
size = None
tap = None
tapstate = None
offset = None
for line in sys.argv[1].splitlines():
    m = re.match(r'\[hflow\] cell (\d+) '
                 r'([-0-9.]+) ([-0-9.]+) ([-0-9.]+) ([-0-9.]+)$', line)
    if m:
        frames[int(m.group(1))] = tuple(
            float(m.group(i)) for i in (2, 3, 4, 5))
        continue
    m = re.match(r'\[hflow\] size ([-0-9.]+) ([-0-9.]+)$', line)
    if m:
        size = (float(m.group(1)), float(m.group(2)))
    m = re.match(r'\[hflow\] tap (\d+) (\d+)$', line)
    if m:
        tap = (int(m.group(1)), int(m.group(2)))
    m = re.match(r'\[hflow\] tapstate (\d+) (\d+)$', line)
    if m:
        tapstate = (int(m.group(1)), int(m.group(2)))
    m = re.match(r'\[hflow\] offset ([-0-9.]+)$', line)
    if m:
        offset = float(m.group(1))

expected = {
    0: (10.0, 20.0, 90.0, 60.0),
    1: (10.0, 85.0, 90.0, 60.0),
    2: (110.0, 20.0, 90.0, 60.0),
    3: (110.0, 85.0, 90.0, 60.0),
    9: (410.0, 85.0, 90.0, 60.0),
}
for key, want in expected.items():
    if key not in frames:
        raise SystemExit('missing cell %r' % (key,))
    got = frames[key]
    for a, b in zip(got, want):
        if abs(a - b) > 0.6:
            raise SystemExit('cell %r is %r, expected %r' %
                             (key, got, want))
if size is None or abs(size[0] - 510.0) > 0.6 or abs(size[1] - 200.0) > 0.6:
    raise SystemExit('content size is %r, expected (510, 200)' % (size,))
if tap != (0, 2) or tapstate != (0, 2):
    raise SystemExit('horizontal tap disagrees: %r %r' % (tap, tapstate))
if offset is None or abs(offset - 60.0) > 0.6:
    raise SystemExit('content offset is %r, expected 60' % (offset,))
print("ok   horizontal flow layout wraps columns and shares hit-testing")
PY
)"; then
    echo "$out"
else
    echo "FAIL horizontal flow layout"; echo "$out"; fails=$((fails+1))
fi
if out="$(python3 - "$ROOT/tools" "$T/hflow.png" <<'PY'
import sys
sys.path.insert(0, sys.argv[1])
import pngpixel

w, h, bpp, rows = pngpixel.load(sys.argv[2])
samples = [
    ('item2', 95, 350, True),
    ('gap', 145, 350, False),
    ('item4', 195, 350, True),
    ('item1', 20, 415, True),
]
for name, x, y, expect_white in samples:
    c = pngpixel.px(rows, bpp, x * 3, y * 3)
    r, g, b = (c >> 16) & 255, (c >> 8) & 255, c & 255
    white = r > 200 and g > 200 and b > 200
    dark = r < 60 and g < 60 and b < 60
    if expect_white and not white:
        raise SystemExit('%s sample at %d,%d is not white: %06x' %
                         (name, x, y, c))
    if not expect_white and not dark:
        raise SystemExit('%s sample at %d,%d is not black: %06x' %
                         (name, x, y, c))
print("ok   the renderer shifts horizontal collection cells by content offset")
PY
)"; then
    echo "$out"
else
    echo "FAIL horizontal collection rendering"; echo "$out"; fails=$((fails+1))
fi

# ---------- 4f16. Blend modes on text and images ----------
rm -f "$T/blend2.fifo"
mkfifo "$T/blend2.fifo"
"$ROOT/tools/build_app.sh" "$ROOT/tests/blend_text_image_test.m" \
    "$T/blend_text_image_test" >/dev/null
out="$(IOSIM_EVENT_FIFO="$T/blend2.fifo" IOSIM_TEST_PNG="$T/blend2.png" \
    DYLD_ROOT_PATH="$ROOT/runtime" "$RUN" "$T/blend_text_image_test" 2>&1)"
rm -f "$T/blend2.fifo"
check "[blend2] ready" "$out" \
    "the text and image blend fixture starts"
check "[blend2] done" "$out" \
    "the text and image blend fixture draws"
if out="$(python3 - "$ROOT/tools" "$T/blend2.png" <<'PY'
import sys
sys.path.insert(0, sys.argv[1])
import pngpixel

w, h, bpp, rows = pngpixel.load(sys.argv[2])
samples = [
    ('image-multiply', 54, 142, (128, 0, 0)),
    ('image-screen', 106, 142, (255, 128, 128)),
]
for name, x, y, want in samples:
    c = pngpixel.px(rows, bpp, x * 3, y * 3)
    got = ((c >> 16) & 255, (c >> 8) & 255, c & 255)
    for a, b in zip(got, want):
        if abs(a - b) > 4:
            raise SystemExit('%s pixel at %d,%d is %r, expected %r' %
                             (name, x, y, got, want))
print("ok   images blend with the CGContext blend mode")
PY
)"; then
    echo "$out"
else
    echo "FAIL image blend pixels"; echo "$out"; fails=$((fails+1))
fi
if out="$(python3 - "$ROOT/tools" "$T/blend2.png" <<'PY'
import sys
sys.path.insert(0, sys.argv[1])
import pngpixel

w, h, bpp, rows = pngpixel.load(sys.argv[2])
multiply = 0
for yy in range(660, 810):
    for xx in range(96, 700):
        c = pngpixel.px(rows, bpp, xx, yy)
        r, g, b = (c >> 16) & 255, (c >> 8) & 255, c & 255
        if abs(r - 128) <= 2 and g < 50 and b < 50:
            multiply += 1
screen = 0
for yy in range(840, 990):
    for xx in range(96, 700):
        c = pngpixel.px(rows, bpp, xx, yy)
        r, g, b = (c >> 16) & 255, (c >> 8) & 255, c & 255
        if r > 250 and abs(g - 128) <= 3 and abs(b - 128) <= 3:
            screen += 1
if multiply < 20:
    raise SystemExit('multiply text has %d blended pixels' % multiply)
if screen < 20:
    raise SystemExit('screen text has %d blended pixels' % screen)
print("ok   glyph coverage blends with the CGContext blend mode")
PY
)"; then
    echo "$out"
else
    echo "FAIL text blend pixels"; echo "$out"; fails=$((fails+1))
fi

# ---------- 4f17. Diffable data sources ----------
"$ROOT/tools/build_app.sh" "$ROOT/tests/diffable_data_source_test.m" \
    "$T/diffable_test" >/dev/null
out="$(DYLD_ROOT_PATH="$ROOT/runtime" "$RUN" "$T/diffable_test" 2>&1)"
check "[diff] done" "$out" "the diffable data source fixture runs"
if report="$(python3 - "$out" <<'PY'
import re
import sys

lines = sys.argv[1].splitlines()
want = [
    r'\[diff\] snapshot 2 3',
    r'\[diff\] s1 2',
    r'\[diff\] index b1 2',
    r'\[diff\] section a2 S1',
    r'\[diff\] final 1 2',
    r'\[diff\] finalitem 0 c1',
    r'\[diff\] finalitem 1 a1',
]
for pattern in want:
    if not any(re.fullmatch(pattern, line) for line in lines):
        raise SystemExit('missing snapshot line: ' + pattern)
print("ok   snapshots track sections, items, insertions, moves and deletes")
PY
)"; then
    echo "$report"
else
    echo "FAIL diffable snapshot bookkeeping"; echo "$report"; fails=$((fails+1))
fi
if report="$(python3 - "$out" <<'PY'
import re
import sys

wanted = {
    r'\[diff\] table 1 2': 'table section/row counts',
    r'\[diff\] table id a1': 'table item at 0:1',
    r'\[diff\] table path 0 0': 'table path for c1',
    r'\[diff\] table cell a1': 'table cell text',
}
for pattern, label in wanted.items():
    if not any(re.fullmatch(pattern, line)
               for line in sys.argv[1].splitlines()):
        raise SystemExit('missing %s: %s' % (label, pattern))
print("ok   the table diffable data source drives rows and cells")
PY
)"; then
    echo "$report"
else
    echo "FAIL diffable table data source"; echo "$report"; fails=$((fails+1))
fi
if report="$(python3 - "$out" <<'PY'
import re
import sys

wanted = {
    r'\[diff\] collection 1 3': 'collection section/item counts',
    r'\[diff\] collection id g3': 'collection item at 0:2',
    r'\[diff\] collection path 0 0': 'collection path for g1',
    r'\[diff\] collection cell 1': 'collection cell reuse identity',
}
for pattern, label in wanted.items():
    if not any(re.fullmatch(pattern, line)
               for line in sys.argv[1].splitlines()):
        raise SystemExit('missing %s: %s' % (label, pattern))
print("ok   the collection diffable data source drives items and cells")
PY
)"; then
    echo "$report"
else
    echo "FAIL diffable collection data source"; echo "$report"; fails=$((fails+1))
fi

# ---------- 4f18. Attributed string attribute runs ----------
"$ROOT/tools/build_app.sh" "$ROOT/tests/attributed_runs_test.m" \
    "$T/attributed_runs_test" >/dev/null
out="$(DYLD_ROOT_PATH="$ROOT/runtime" "$RUN" "$T/attributed_runs_test" 2>&1)"
check "[arun] done" "$out" "the attributed run fixture runs"
if report="$(python3 - "$out" <<'PY'
import re
import sys

lines = sys.argv[1].splitlines()
want = [
    r'\[arun\] first 0 5 1',
    r'\[arun\] second 5 5 1',
    r'\[arun\] split1 0 2 1',
    r'\[arun\] split2 2 3 1',
    r'\[arun\] split3 6 4 1 1',
    r'\[arun\] replaced 8 2 1',
]
for pattern in want:
    if not any(re.fullmatch(pattern, line) for line in lines):
        raise SystemExit('missing attribute run line: ' + pattern)
print("ok   attribute runs split and report effective ranges")
PY
)"; then
    echo "$report"
else
    echo "FAIL attributed run ranges"; echo "$report"; fails=$((fails+1))
fi
if report="$(python3 - "$out" <<'PY'
import re
import sys

lines = sys.argv[1].splitlines()
want = [
    r'\[arun\] length 8',
    r'\[arun\] string HeXYorld',
    r'\[arun\] edit1 0 2 1',
    r'\[arun\] edit2 1 1',
    r'\[arun\] edit3 1',
    r'\[arun\] append 10 HeXYorld!!',
    r'\[arun\] tail 8 2 1',
    r'\[arun\] copy 4 2 1',
    r'\[arun\] immutable 0 3 1',
]
for pattern in want:
    if not any(re.fullmatch(pattern, line) for line in lines):
        raise SystemExit('missing attributed edit line: ' + pattern)
print("ok   replacement, appending and copies shift attribute runs")
PY
)"; then
    echo "$report"
else
    echo "FAIL attributed run edits"; echo "$report"; fails=$((fails+1))
fi

# ---------- 4f19. Attributed label runs ----------
rm -f "$T/alabel.fifo"
mkfifo "$T/alabel.fifo"
"$ROOT/tools/build_app.sh" "$ROOT/tests/attributed_label_test.m" \
    "$T/attributed_label_test" >/dev/null
out="$(IOSIM_EVENT_FIFO="$T/alabel.fifo" IOSIM_TEST_PNG="$T/alabel.png" \
    DYLD_ROOT_PATH="$ROOT/runtime" "$RUN" "$T/attributed_label_test" 2>&1)"
rm -f "$T/alabel.fifo"
check "[alabel] ready" "$out" \
    "the attributed label fixture starts"
check "[alabel] done" "$out" \
    "the attributed label fixture draws its runs"
if report="$(python3 - "$ROOT/tools" "$T/alabel.png" <<'PY'
import sys
sys.path.insert(0, sys.argv[1])
import pngpixel

w, h, bpp, rows = pngpixel.load(sys.argv[2])
stats = {}
for name in ('red', 'green', 'blue'):
    stats[name] = {'n': 0, 'minx': 10 ** 9, 'maxx': -1,
                   'miny': 10 ** 9, 'maxy': -1}
for yy in range(560, 820):
    for xx in range(40, 1160):
        c = pngpixel.px(rows, bpp, xx, yy)
        r, g, b = (c >> 16) & 255, (c >> 8) & 255, c & 255
        if r > 180 and g < 80 and b < 80:
            key = 'red'
        elif g > 150 and r < 80 and b < 80:
            key = 'green'
        elif b > 180 and r < 80 and g < 80:
            key = 'blue'
        else:
            continue
        s = stats[key]
        s['n'] += 1
        s['minx'] = min(s['minx'], xx)
        s['maxx'] = max(s['maxx'], xx)
        s['miny'] = min(s['miny'], yy)
        s['maxy'] = max(s['maxy'], yy)
for name, want in (('red', 500), ('green', 500), ('blue', 500)):
    if stats[name]['n'] < want:
        raise SystemExit('%s run has only %d pixels' %
                         (name, stats[name]['n']))
red_h = stats['red']['maxy'] - stats['red']['miny']
green_h = stats['green']['maxy'] - stats['green']['miny']
if green_h < red_h + 8:
    raise SystemExit('green run height %d is not taller than red %d' %
                     (green_h, red_h))
print("ok   attributed label runs use per-run fonts and colors")
PY
)"; then
    echo "$report"
else
    echo "FAIL attributed label runs"; echo "$report"; fails=$((fails+1))
fi
if report="$(python3 - "$ROOT/tools" "$T/alabel.png" <<'PY'
import sys
sys.path.insert(0, sys.argv[1])
import pngpixel

w, h, bpp, rows = pngpixel.load(sys.argv[2])
blue = {'n': 0, 'minx': 10 ** 9, 'maxx': -1, 'maxy': -1,
        'maxrow': 0, 'redmaxy': -1}
for yy in range(560, 820):
    count = 0
    for xx in range(40, 1160):
        c = pngpixel.px(rows, bpp, xx, yy)
        r, g, b = (c >> 16) & 255, (c >> 8) & 255, c & 255
        if r > 180 and g < 80 and b < 80 and yy > blue['redmaxy']:
            blue['redmaxy'] = yy
        if b > 180 and r < 80 and g < 80:
            blue['n'] += 1
            count += 1
            blue['minx'] = min(blue['minx'], xx)
            blue['maxx'] = max(blue['maxx'], xx)
            blue['maxy'] = max(blue['maxy'], yy)
    blue['maxrow'] = max(blue['maxrow'], count)
width = blue['maxx'] - blue['minx']
if width < 100:
    raise SystemExit('blue run is only %d pixels wide' % width)
if blue['maxrow'] < width * 0.85:
    raise SystemExit('no underline row: widest blue row %d of %d' %
                     (blue['maxrow'], width))
if blue['maxy'] < blue['redmaxy'] + 4:
    raise SystemExit('underline does not sit below the glyph baseline')
print("ok   attributed label runs draw their underline")
PY
)"; then
    echo "$report"
else
    echo "FAIL attributed label underline"; echo "$report"; fails=$((fails+1))
fi
if report="$(python3 - "$ROOT/tools" "$T/alabel.png" <<'PY'
import sys
sys.path.insert(0, sys.argv[1])
import pngpixel

w, h, bpp, rows = pngpixel.load(sys.argv[2])
minx = 10 ** 9
maxx = -1
for yy in range(560, 820):
    for xx in range(40, 1160):
        c = pngpixel.px(rows, bpp, xx, yy)
        r, g, b = (c >> 16) & 255, (c >> 8) & 255, c & 255
        if ((r > 180 and g < 80 and b < 80) or
                (g > 150 and r < 80 and b < 80) or
                (b > 180 and r < 80 and g < 80)):
            minx = min(minx, xx)
            maxx = max(maxx, xx)
if maxx < 0:
    raise SystemExit('no colored run pixels found')
center = (minx + maxx) / 2.0
if abs(center - 600.0) > 24.0:
    raise SystemExit('run block center is %.1f, expected 600' % center)
print("ok   attributed label alignment centers the run block")
PY
)"; then
    echo "$report"
else
    echo "FAIL attributed label alignment"; echo "$report"; fails=$((fails+1))
fi

# ---------- 4f20. Paragraph styles in attributed labels ----------
rm -f "$T/para.fifo"
mkfifo "$T/para.fifo"
"$ROOT/tools/build_app.sh" "$ROOT/tests/paragraph_style_test.m" \
    "$T/paragraph_style_test" >/dev/null
out="$(IOSIM_EVENT_FIFO="$T/para.fifo" IOSIM_TEST_PNG="$T/para.png" \
    DYLD_ROOT_PATH="$ROOT/runtime" "$RUN" "$T/paragraph_style_test" 2>&1)"
rm -f "$T/para.fifo"
check "[para] ready" "$out" \
    "the paragraph style fixture starts"
check "[para] done" "$out" \
    "the paragraph style fixture draws its lines"
if report="$(python3 - "$ROOT/tools" "$T/para.png" <<'PY'
import sys
sys.path.insert(0, sys.argv[1])
import pngpixel

w, h, bpp, rows = pngpixel.load(sys.argv[2])
stats = {name: {'n': 0, 'minx': 10 ** 9, 'maxx': -1}
         for name in ('red', 'green')}
for yy in range(560, 1100):
    for xx in range(40, 1160):
        c = pngpixel.px(rows, bpp, xx, yy)
        r, g, b = (c >> 16) & 255, (c >> 8) & 255, c & 255
        if r > 180 and g < 80 and b < 80:
            key = 'red'
        elif g > 150 and r < 80 and b < 80:
            key = 'green'
        else:
            continue
        s = stats[key]
        s['n'] += 1
        s['minx'] = min(s['minx'], xx)
        s['maxx'] = max(s['maxx'], xx)
for name in ('red', 'green'):
    s = stats[name]
    if s['n'] < 300:
        raise SystemExit('%s line has only %d pixels' % (name, s['n']))
    center = (s['minx'] + s['maxx']) / 2.0
    if abs(center - 600.0) > 20.0:
        raise SystemExit('%s line center is %.1f, expected 600' %
                         (name, center))
print("ok   paragraph alignment centers both attributed lines")
PY
)"; then
    echo "$report"
else
    echo "FAIL paragraph alignment"; echo "$report"; fails=$((fails+1))
fi
if report="$(python3 - "$ROOT/tools" "$T/para.png" <<'PY'
import sys
sys.path.insert(0, sys.argv[1])
import pngpixel

w, h, bpp, rows = pngpixel.load(sys.argv[2])
red_bottom = -1
green_top = 10 ** 9
for yy in range(560, 1100):
    for xx in range(40, 1160):
        c = pngpixel.px(rows, bpp, xx, yy)
        r, g, b = (c >> 16) & 255, (c >> 8) & 255, c & 255
        if r > 180 and g < 80 and b < 80 and yy > red_bottom:
            red_bottom = yy
        if g > 150 and r < 80 and b < 80 and yy < green_top:
            green_top = yy
if red_bottom < 0 or green_top >= 10 ** 9:
    raise SystemExit('one of the lines is missing')
gap = green_top - red_bottom
if gap < 45 or gap > 80:
    raise SystemExit('line gap is %d px, expected the 10 pt spacing' % gap)
print("ok   paragraph line spacing separates the attributed lines")
PY
)"; then
    echo "$report"
else
    echo "FAIL paragraph line spacing"; echo "$report"; fails=$((fails+1))
fi

# ---------- 4f21. Attributed text in UITextView ----------
rm -f "$T/tvattr.fifo"
mkfifo "$T/tvattr.fifo"
"$ROOT/tools/build_app.sh" "$ROOT/tests/textview_attributed_test.m" \
    "$T/textview_attributed_test" >/dev/null
out="$(IOSIM_EVENT_FIFO="$T/tvattr.fifo" IOSIM_TEST_PNG="$T/tvattr.png" \
    DYLD_ROOT_PATH="$ROOT/runtime" "$RUN" "$T/textview_attributed_test" 2>&1)"
rm -f "$T/tvattr.fifo"
check "[tvattr] ready" "$out" \
    "the attributed text view fixture starts"
check "[tvattr] done" "$out" \
    "the attributed text view fixture draws its text"
if report="$(python3 - "$ROOT/tools" "$T/tvattr.png" <<'PY'
import sys
sys.path.insert(0, sys.argv[1])
import pngpixel

w, h, bpp, rows = pngpixel.load(sys.argv[2])
stats = {name: {'n': 0, 'minx': 10 ** 9, 'maxx': -1}
         for name in ('red', 'blue', 'green')}
for yy in range(560, 1000):
    for xx in range(40, 1160):
        c = pngpixel.px(rows, bpp, xx, yy)
        r, g, b = (c >> 16) & 255, (c >> 8) & 255, c & 255
        if r > 180 and g < 80 and b < 80:
            key = 'red'
        elif b > 180 and r < 80 and g < 80:
            key = 'blue'
        elif g > 150 and r < 80 and b < 80:
            key = 'green'
        else:
            continue
        s = stats[key]
        s['n'] += 1
        s['minx'] = min(s['minx'], xx)
        s['maxx'] = max(s['maxx'], xx)
for name in ('red', 'blue', 'green'):
    if stats[name]['n'] < 200:
        raise SystemExit('%s run has only %d pixels' %
                         (name, stats[name]['n']))
if not (stats['red']['maxx'] < stats['blue']['minx'] <
        stats['green']['minx']):
    raise SystemExit('run order is not red, blue, green: %r' % stats)
print("ok   UITextView draws per-run colors in order")
PY
)"; then
    echo "$report"
else
    echo "FAIL text view attributed colors"; echo "$report"; fails=$((fails+1))
fi
if report="$(python3 - "$ROOT/tools" "$T/tvattr.png" <<'PY'
import sys
sys.path.insert(0, sys.argv[1])
import pngpixel

w, h, bpp, rows = pngpixel.load(sys.argv[2])
blue = {'minx': 10 ** 9, 'maxx': -1, 'maxy': -1, 'maxrow': 0}
red_bottom = -1
for yy in range(560, 1000):
    count = 0
    for xx in range(40, 1160):
        c = pngpixel.px(rows, bpp, xx, yy)
        r, g, b = (c >> 16) & 255, (c >> 8) & 255, c & 255
        if r > 180 and g < 80 and b < 80 and yy > red_bottom:
            red_bottom = yy
        if b > 180 and r < 80 and g < 80:
            count += 1
            blue['minx'] = min(blue['minx'], xx)
            blue['maxx'] = max(blue['maxx'], xx)
            blue['maxy'] = max(blue['maxy'], yy)
    blue['maxrow'] = max(blue['maxrow'], count)
width = blue['maxx'] - blue['minx']
if width < 100:
    raise SystemExit('blue run is only %d pixels wide' % width)
if blue['maxrow'] < width * 0.85:
    raise SystemExit('no underline row: widest blue row %d of %d' %
                     (blue['maxrow'], width))
if blue['maxy'] < red_bottom + 4:
    raise SystemExit('underline does not sit below the glyph baseline')
print("ok   UITextView draws the underlined run")
PY
)"; then
    echo "$report"
else
    echo "FAIL text view underline"; echo "$report"; fails=$((fails+1))
fi

# ---------- 4f22. Context menu action state ----------
rm -f "$T/state.fifo"
mkfifo "$T/state.fifo"
"$ROOT/tools/build_app.sh" "$ROOT/tests/menu_state_test.m" \
    "$T/menu_state_test" >/dev/null
out="$(IOSIM_EVENT_FIFO="$T/state.fifo" \
    IOSIM_TEST_PNG_STATE="$T/state.png" \
    IOSIM_TEST_PNG_PINON="$T/state_pinon.png" \
    IOSIM_TEST_PNG_PINOFF="$T/state_pinoff.png" \
    IOSIM_TEST_PNG_SORT="$T/state_sort.png" \
    IOSIM_TEST_PNG_SORT2="$T/state_sort2.png" \
    IOSIM_TEST_PNG_BACK="$T/state_back.png" \
    IOSIM_TEST_PNG_END="$T/state_end.png" \
    DYLD_ROOT_PATH="$ROOT/runtime" "$RUN" \
    "$T/menu_state_test" 2>&1)"
check "[state] pin 1" "$out" "a keeps-presented action stays in the menu"
check "[state] pin 0" "$out" "the action toggles its state without dismissing"
check "[state] sort date name=0 date=1" "$out" \
    "a single-selection menu moves its checkmark to the chosen action"
check "[state] png written" "$out" "the menu state fixture captures every phase"
if out="$(python3 - "$ROOT/tools" "$T" <<'STATEPNG'
import sys
sys.path.insert(0, sys.argv[1])
import pngpixel

def loader(path):
    w, h, bpp, rows = pngpixel.load(path)
    def read(x, y):
        return pngpixel.px(rows, bpp, x * 3, y * 3)
    return read

def rgb(read, x, y):
    c = read(x, y)
    return ((c >> 16) & 255, (c >> 8) & 255, c & 255)

def light(c):
    return c[0] > 110 and c[1] > 110 and c[2] > 110

def any_light(read, x0, y0, x1, y1):
    for yy in range(y0, y1):
        for xx in range(x0, x1):
            if light(rgb(read, xx, yy)):
                return True
    return False

def green(c):
    return abs(c[0] - 26) < 25 and abs(c[1] - 204) < 25 and abs(c[2] - 77) < 25

root = sys.argv[2]
state = loader(root + "/state.png")
pinon = loader(root + "/state_pinon.png")
pinoff = loader(root + "/state_pinoff.png")
sort = loader(root + "/state_sort.png")
sort2 = loader(root + "/state_sort2.png")
back = loader(root + "/state_back.png")
end = loader(root + "/state_end.png")
if any_light(state, 288, 506, 316, 536):
    raise SystemExit("the Pin action starts checked")
if not any_light(state, 286, 552, 320, 582):
    raise SystemExit("the Sort row has no chevron")
if not any_light(pinon, 288, 506, 316, 536):
    raise SystemExit("tapping Pin did not draw its checkmark")
if any_light(pinoff, 288, 506, 316, 536):
    raise SystemExit("tapping Pin again did not clear its checkmark")
if not any_light(sort, 288, 552, 316, 582):
    raise SystemExit("the selected sort action has no checkmark")
if any_light(sort, 288, 598, 316, 628):
    raise SystemExit("the unselected sort action is checked")
if not any_light(sort2, 288, 598, 316, 628):
    raise SystemExit("the sort checkmark did not move")
if any_light(sort2, 288, 552, 316, 582):
    raise SystemExit("the previous sort action kept its checkmark")
if not any_light(back, 286, 552, 320, 582):
    raise SystemExit("the back row did not restore the root menu")
if not green(rgb(end, 10, 300)):
    raise SystemExit("the menu did not dismiss")
print("ok   action checkmarks follow state and single-selection pages")
STATEPNG
)"; then
    echo "$out"
else
    echo "FAIL menu action state"; echo "$out"; fails=$((fails+1))
fi

# ---------- 4f23. Context menu palettes ----------
rm -f "$T/palette.fifo"
mkfifo "$T/palette.fifo"
"$ROOT/tools/build_app.sh" "$ROOT/tests/palette_menu_test.m" \
    "$T/palette_menu_test" >/dev/null
out="$(IOSIM_EVENT_FIFO="$T/palette.fifo" \
    IOSIM_TEST_PNG_PALETTE="$T/palette.png" \
    IOSIM_TEST_PNG_END="$T/palette_end.png" \
    DYLD_ROOT_PATH="$ROOT/runtime" "$RUN" \
    "$T/palette_menu_test" 2>&1)"
check "[palette] green" "$out" "a palette menu column runs its action"
check "[palette] png written" "$out" "the palette fixture captures every phase"
if out="$(python3 - "$ROOT/tools" "$T" <<'PALPNG'
import sys
sys.path.insert(0, sys.argv[1])
import pngpixel

def loader(path):
    w, h, bpp, rows = pngpixel.load(path)
    def read(x, y):
        return pngpixel.px(rows, bpp, x * 3, y * 3)
    return read

def rgb(read, x, y):
    c = read(x, y)
    return ((c >> 16) & 255, (c >> 8) & 255, c & 255)

def green(c):
    return abs(c[0] - 26) < 25 and abs(c[1] - 204) < 25 and abs(c[2] - 77) < 25

root = sys.argv[2]
pal = loader(root + "/palette.png")
end = loader(root + "/palette_end.png")
red = rgb(pal, 125, 512)
grn = rgb(pal, 201, 512)
blu = rgb(pal, 277, 512)
if not (red[0] > 200 and red[1] < 80 and red[2] < 80):
    raise SystemExit("the red palette icon is missing: %r" % (red,))
if not (grn[1] > 200 and grn[0] < 80 and grn[2] < 80):
    raise SystemExit("the green palette icon is missing: %r" % (grn,))
if not (blu[2] > 200 and blu[0] < 80 and blu[1] < 80):
    raise SystemExit("the blue palette icon is missing: %r" % (blu,))
if not green(rgb(end, 10, 300)):
    raise SystemExit("the palette did not dismiss")
print("ok   palette menus draw icon columns and run a column action")
PALPNG
)"; then
    echo "$out"
else
    echo "FAIL context menu palette"; echo "$out"; fails=$((fails+1))
fi

# ---------- 4f24. Bitmap contexts and tiled images ----------
"$ROOT/tools/build_app.sh" "$ROOT/tests/bitmap_tiled_test.m" \
    "$T/bitmap_tiled_test" >/dev/null
out="$(DYLD_ROOT_PATH="$ROOT/runtime" "$RUN" "$T/bitmap_tiled_test" 2>&1)"
check "[cg] tiled colors 1 1 1 1" "$out" \
    "a tiled CGImage repeats its pixels"
check "[cg] tiled edge 1 1" "$out" \
    "tiled drawing clips to its rect"
check "[cg] tiled clip 1 1" "$out" \
    "an existing clip bounds the tiles"
check "[cg] bitmap size 8 8 8 8" "$out" \
    "a bitmap context and its image are 8 x 8"
check "[cg] bitmap pixels 1 1" "$out" \
    "bitmap context data holds the drawn pixels"
check "[cg] bitmap drawn 1 1" "$out" \
    "a bitmap image draws back through the framebuffer"

# ---------- 4f25. Label and attributed text shadows ----------
rm -f "$T/shadow.fifo"
mkfifo "$T/shadow.fifo"
"$ROOT/tools/build_app.sh" "$ROOT/tests/text_shadow_test.m" \
    "$T/text_shadow_test" >/dev/null
out="$(IOSIM_EVENT_FIFO="$T/shadow.fifo" IOSIM_TEST_PNG="$T/shadow.png" \
    DYLD_ROOT_PATH="$ROOT/runtime" "$RUN" "$T/text_shadow_test" 2>&1)"
rm -f "$T/shadow.fifo"
check "[shadow] ready" "$out" "the label shadow fixture starts"
check "[shadow] done" "$out" "the label shadow fixture draws its labels"
if report="$(python3 - "$ROOT/tools" "$T/shadow.png" <<'PY'
import sys
sys.path.insert(0, sys.argv[1])
import pngpixel

w, h, bpp, rows = pngpixel.load(sys.argv[2])
def region(top, bottom):
    stats = {}
    for name in ('white', 'red', 'blue'):
        stats[name] = {'n': 0, 'minx': 10 ** 9, 'maxx': -1,
                       'miny': 10 ** 9, 'maxy': -1}
    for yy in range(top * 3, bottom * 3):
        for xx in range(40, 1160):
            c = pngpixel.px(rows, bpp, xx, yy)
            r, g, b = (c >> 16) & 255, (c >> 8) & 255, c & 255
            if min(r, g, b) > 200:
                key = 'white'
            elif r > 150 and g < 90 and b < 90:
                key = 'red'
            elif b > 100 and r < 90 and g < 90:
                key = 'blue'
            else:
                continue
            s = stats[key]
            s['n'] += 1
            s['minx'] = min(s['minx'], xx)
            s['maxx'] = max(s['maxx'], xx)
            s['miny'] = min(s['miny'], yy)
            s['maxy'] = max(s['maxy'], yy)
    return stats

plain = region(160, 240)
if plain['white']['n'] < 200 or plain['red']['n'] < 150:
    raise SystemExit('plain label pixels: white %d red %d' %
                     (plain['white']['n'], plain['red']['n']))
dx = plain['red']['maxx'] - plain['white']['maxx']
dy = plain['red']['maxy'] - plain['white']['maxy']
if not (5 <= dx <= 15 and 5 <= dy <= 15):
    raise SystemExit('plain shadow offset is %d,%d' % (dx, dy))
print("ok   a UILabel shadow draws offset from its text")
PY
)"; then
    echo "$report"
else
    echo "FAIL label shadow"; echo "$report"; fails=$((fails+1))
fi
if report="$(python3 - "$ROOT/tools" "$T/shadow.png" <<'PY'
import sys
sys.path.insert(0, sys.argv[1])
import pngpixel

w, h, bpp, rows = pngpixel.load(sys.argv[2])
def region(top, bottom):
    stats = {}
    for name in ('white', 'blue'):
        stats[name] = {'n': 0, 'minx': 10 ** 9, 'maxx': -1,
                       'miny': 10 ** 9, 'maxy': -1}
    for yy in range(top * 3, bottom * 3):
        for xx in range(40, 1160):
            c = pngpixel.px(rows, bpp, xx, yy)
            r, g, b = (c >> 16) & 255, (c >> 8) & 255, c & 255
            if min(r, g, b) > 200:
                key = 'white'
            elif b > 100 and r < 90 and g < 90:
                key = 'blue'
            else:
                continue
            s = stats[key]
            s['n'] += 1
            s['minx'] = min(s['minx'], xx)
            s['maxx'] = max(s['maxx'], xx)
            s['miny'] = min(s['miny'], yy)
            s['maxy'] = max(s['maxy'], yy)
    return stats

attributed = region(320, 400)
if attributed['white']['n'] < 200 or attributed['blue']['n'] < 150:
    raise SystemExit('attributed label pixels: white %d blue %d' %
                     (attributed['white']['n'], attributed['blue']['n']))
dx = attributed['blue']['minx'] - attributed['white']['minx']
dy = attributed['blue']['maxy'] - attributed['white']['maxy']
if not (-16 <= dx <= -3 and 4 <= dy <= 16):
    raise SystemExit('attributed shadow offset is %d,%d' % (dx, dy))
print("ok   an NSShadow attribute draws a blurred offset shadow")
PY
)"; then
    echo "$report"
else
    echo "FAIL attributed shadow"; echo "$report"; fails=$((fails+1))
fi


# ---------- 4f26. CGContext shadows ----------
rm -f "$T/cgshadow.fifo"
mkfifo "$T/cgshadow.fifo"
"$ROOT/tools/build_app.sh" "$ROOT/tests/cg_shadow_test.m" \
    "$T/cg_shadow_test" >/dev/null
out="$(IOSIM_EVENT_FIFO="$T/cgshadow.fifo" IOSIM_TEST_PNG="$T/cgshadow.png" \
    DYLD_ROOT_PATH="$ROOT/runtime" "$RUN" "$T/cg_shadow_test" 2>&1)"
rm -f "$T/cgshadow.fifo"
check "[cgshadow] ready" "$out" "the CGContext shadow fixture starts"
check "[cgshadow] done" "$out" "the CGContext shadow fixture draws its shapes"
if report="$(python3 - "$ROOT/tools" "$T/cgshadow.png" <<'PY'
import sys
sys.path.insert(0, sys.argv[1])
import pngpixel

w, h, bpp, rows = pngpixel.load(sys.argv[2])
def region(x0, x1, top, bottom):
    stats = {}
    for name in ('white', 'red', 'blue'):
        stats[name] = {'n': 0, 'minx': 10 ** 9, 'maxx': -1,
                       'miny': 10 ** 9, 'maxy': -1}
    for yy in range(top * 3, bottom * 3):
        for xx in range(x0 * 3, x1 * 3):
            c = pngpixel.px(rows, bpp, xx, yy)
            r, g, b = (c >> 16) & 255, (c >> 8) & 255, c & 255
            if min(r, g, b) > 200:
                key = 'white'
            elif r > 150 and g < 90 and b < 90:
                key = 'red'
            elif b > 100 and r < 90 and g < 90:
                key = 'blue'
            else:
                continue
            s = stats[key]
            s['n'] += 1
            s['minx'] = min(s['minx'], xx)
            s['maxx'] = max(s['maxx'], xx)
            s['miny'] = min(s['miny'], yy)
            s['maxy'] = max(s['maxy'], yy)
    return stats

rect = region(20, 190, 100, 240)
if rect['white']['n'] < 2000 or rect['red']['n'] < 500:
    raise SystemExit('rect pixels: white %d red %d' %
                     (rect['white']['n'], rect['red']['n']))
dx = rect['red']['maxx'] - rect['white']['maxx']
dy = rect['red']['maxy'] - rect['white']['maxy']
if not (9 <= dx <= 16 and 9 <= dy <= 16):
    raise SystemExit('rect shadow offset is %d,%d' % (dx, dy))
c = pngpixel.px(rows, bpp, 100 * 3, 160 * 3)
if min((c >> 16) & 255, (c >> 8) & 255, c & 255) < 200:
    raise SystemExit('the rect fill was covered by its shadow')
print("ok   a hard CGContext shadow sits behind an offset fill")
PY
)"; then
    echo "$report"
else
    echo "FAIL CGContext rect shadow"; echo "$report"; fails=$((fails+1))
fi
if report="$(python3 - "$ROOT/tools" "$T/cgshadow.png" <<'PY'
import sys
sys.path.insert(0, sys.argv[1])
import pngpixel

w, h, bpp, rows = pngpixel.load(sys.argv[2])
stats = {}
for name in ('white', 'blue'):
    stats[name] = {'n': 0, 'minx': 10 ** 9, 'maxx': -1,
                   'miny': 10 ** 9, 'maxy': -1}
for yy in range(100 * 3, 240 * 3):
    for xx in range(200 * 3, 380 * 3):
        c = pngpixel.px(rows, bpp, xx, yy)
        r, g, b = (c >> 16) & 255, (c >> 8) & 255, c & 255
        if min(r, g, b) > 200:
            key = 'white'
        elif b > 100 and r < 90 and g < 90:
            key = 'blue'
        else:
            continue
        s = stats[key]
        s['n'] += 1
        s['minx'] = min(s['minx'], xx)
        s['maxx'] = max(s['maxx'], xx)
        s['miny'] = min(s['miny'], yy)
        s['maxy'] = max(s['maxy'], yy)
if stats['white']['n'] < 2000 or stats['blue']['n'] < 500:
    raise SystemExit('ellipse pixels: white %d blue %d' %
                     (stats['white']['n'], stats['blue']['n']))
dx = stats['blue']['minx'] - stats['white']['minx']
dy = stats['blue']['maxy'] - stats['white']['maxy']
if not (-24 <= dx <= -5 and 5 <= dy <= 24):
    raise SystemExit('blurred shadow offset is %d,%d' % (dx, dy))
print("ok   a blurred CGContext shadow spreads around a path fill")
PY
)"; then
    echo "$report"
else
    echo "FAIL CGContext blurred shadow"; echo "$report"; fails=$((fails+1))
fi


# ---------- 4f27. CGContext image shadows ----------
rm -f "$T/cgimageshadow.fifo"
mkfifo "$T/cgimageshadow.fifo"
"$ROOT/tools/build_app.sh" "$ROOT/tests/cg_image_shadow_test.m" \
    "$T/cg_image_shadow_test" >/dev/null
out="$(IOSIM_EVENT_FIFO="$T/cgimageshadow.fifo" \
    IOSIM_TEST_PNG="$T/cgimageshadow.png" \
    DYLD_ROOT_PATH="$ROOT/runtime" "$RUN" "$T/cg_image_shadow_test" 2>&1)"
rm -f "$T/cgimageshadow.fifo"
check "[cgimage] ready" "$out" "the CGContext image shadow fixture starts"
check "[cgimage] done" "$out" "the fixture draws its shadowed images"
if report="$(python3 - "$ROOT/tools" "$T/cgimageshadow.png" <<'PY'
import sys
sys.path.insert(0, sys.argv[1])
import pngpixel

w, h, bpp, rows = pngpixel.load(sys.argv[2])
def px(x, y):
    c = pngpixel.px(rows, bpp, x * 3, y * 3)
    return ((c >> 16) & 255, (c >> 8) & 255, c & 255)

red = px(100, 150)
if not (red[0] > 200 and red[1] < 60 and red[2] < 60):
    raise SystemExit('the red image did not cover its shadow: %r' % (red,))
blue = px(123, 150)
if not (blue[2] > 200 and blue[0] < 60 and blue[1] < 60):
    raise SystemExit('the image hard shadow is not blue: %r' % (blue,))
blue = px(100, 183)
if not (blue[2] > 200 and blue[0] < 60 and blue[1] < 60):
    raise SystemExit('the image shadow does not extend below: %r' % (blue,))
green = px(270, 150)
if not (green[1] > 200 and green[0] < 60 and green[2] < 60):
    raise SystemExit('the green image did not cover its shadow: %r' % (green,))
gray = px(270, 183)
if not (gray[0] < 180 and max(gray) - min(gray) < 30):
    raise SystemExit('the blurred image shadow is not gray: %r' % (gray,))
white = px(270, 60)
if min(white) < 230:
    raise SystemExit('the background is not white: %r' % (white,))
print("ok   images cast hard and blurred CGContext shadows")
PY
)"; then
    echo "$report"
else
    echo "FAIL CGContext image shadow"; echo "$report"; fails=$((fails+1))
fi

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

# ---------- 4g2. NSLocale and NSTimeZone ----------
"$CC" -target "$TARGET" -fobjc-runtime=ios-18.0 -fno-objc-arc \
    -ffreestanding -O1 -I "$ROOT/frameworks" \
    -c "$ROOT/tests/locale_test.m" -o "$T/locale.o"
"$LD64" -arch x86_64 -platform_version $PLATFORM -e _main -o "$T/locale_test" \
    "$T/locale.o" \
    "$ROOT/runtime/System/Library/Frameworks/Foundation.framework/Foundation" \
    -undefined dynamic_lookup
out="$(TZ=UTC DYLD_ROOT_PATH="$ROOT/runtime" "$RUN" "$T/locale_test" 2>&1)"
check "[locale] current en_US en US" "$out" \
    "the current locale reports en_US, en and US"
check "[locale] french fr_FR fr FR" "$out" \
    "a locale identifier round-trips and splits into language and country"
check "[locale] keys fr FR fr_FR" "$out" \
    "NSLocale objectForKey reads the language, country and identifier"
check "[locale] dash pt BR" "$out" \
    "a dashed locale identifier splits at the dash"
check "[tz] system UTC 0 0" "$out" \
    "the system time zone follows TZ and reports no daylight saving"
check "[tz] la America/Los_Angeles -28800" "$out" \
    "a named time zone reports its standard offset"
check "[tz] unknown 1" "$out" \
    "an unknown time zone name returns nil"
check "[tz] fixed GMT+1 5400" "$out" \
    "a seconds-from-GMT zone keeps its offset and GMT name"
check "[tz] known 8" "$out" \
    "knownTimeZoneNames lists the supported zones"

# ---------- 4g3. NSCache limits and eviction ----------
"$CC" -target "$TARGET" -fobjc-runtime=ios-18.0 -fno-objc-arc \
    -ffreestanding -O1 -I "$ROOT/frameworks" \
    -c "$ROOT/tests/cache_test.m" -o "$T/cache_test.o"
"$LD64" -arch x86_64 -platform_version $PLATFORM -e _main -o "$T/cache_test" \
    "$T/cache_test.o" \
    "$ROOT/runtime/System/Library/Frameworks/Foundation.framework/Foundation" \
    -undefined dynamic_lookup
out="$(DYLD_ROOT_PATH="$ROOT/runtime" "$RUN" "$T/cache_test" 2>&1)"
check "[cache] two 1 1" "$out" \
    "NSCache stores two objects under its count limit"
check "[cache] evict 1 1 1" "$out" \
    "inserting past countLimit evicts the oldest object"
check "[cache] refresh 1 1 1" "$out" \
    "replacing a key refreshes its insertion order"
check "[cache] clear 1" "$out" \
    "removeAllObjects empties the cache"
check "[cache] cost 1 1" "$out" \
    "totalCostLimit evicts until the cost fits"
check "[cache] replace 1" "$out" \
    "replacing a costed object updates its stored object"
check "[cache] name costs" "$out" \
    "NSCache keeps its name"
check "[cache] delegate 1" "$out" \
    "the eviction delegate observes a count-limit eviction"

# ---------- 4g4. Byte and date component formatters ----------
"$CC" -target "$TARGET" -fobjc-runtime=ios-18.0 -fno-objc-arc \
    -ffreestanding -O1 -I "$ROOT/frameworks" \
    -c "$ROOT/tests/formatter_test.m" -o "$T/formatter.o"
"$LD64" -arch x86_64 -platform_version $PLATFORM -e _main -o "$T/formatter" \
    "$T/formatter.o" \
    "$ROOT/runtime/System/Library/Frameworks/Foundation.framework/Foundation" \
    -undefined dynamic_lookup
out="$(DYLD_ROOT_PATH="$ROOT/runtime" "$RUN" "$T/formatter" 2>&1)"
check "[bcf] file 999 bytes" "$out" \
    "file-style byte counts keep values below one thousand in bytes"
check "[bcf] kilo 1 KB" "$out" \
    "one thousand bytes becomes one file-style kilobyte"
check "[bcf] half 1.5 KB" "$out" \
    "byte counts keep one fractional digit below ten units"
check "[bcf] mega 1.5 MB" "$out" \
    "file-style byte counts step up to megabytes"
check "[bcf] memory 1 MB" "$out" \
    "memory-style byte counts divide by 1024"
check "[bcf] decimal 1.5 KB" "$out" \
    "the decimal count style matches the file style"
check "[bcf] binary 1.5 KB" "$out" \
    "the binary count style matches the memory style"
check "[bcf] mask 1500 KB" "$out" \
    "allowedUnits restricts the byte count to kilobytes"
check "[bcf] count 1.5" "$out" \
    "includesUnit NO leaves only the formatted count"
check "[bcf] unit KB" "$out" \
    "includesCount NO leaves only the unit"
check "[bcf] actual 1.5 KB (1536 bytes)" "$out" \
    "includesActualByteCount appends the exact byte count"
check "[bcf] pad 2.0 KB" "$out" \
    "zeroPadsFractionDigits keeps a trailing zero"
check "[bcf] zero 0 bytes" "$out" \
    "a zero byte count keeps the byte unit"
check "[dcf] pos 1:01:01" "$out" \
    "positional time formatting pads minutes and seconds"
check "[dcf] pos2 1:01" "$out" \
    "positional formatting drops a leading zero hour"
check "[dcf] hours 1:00:00" "$out" \
    "positional formatting pads zero minutes and seconds"
check "[dcf] abbr 1h 1m 1s" "$out" \
    "abbreviated units use short suffixes"
check "[dcf] short 1 day, 1 hr, 1 min, 1 sec" "$out" \
    "short units label days and time fields"
check "[dcf] full 1 day, 1 hour, 1 minute, 1 second" "$out" \
    "full units pluralize and separate with commas"
check "[dcf] max 1 day, 1 hour" "$out" \
    "maximumUnitCount keeps only the largest units"
check "[dcf] allhours 25 hr, 1 min, 1 sec" "$out" \
    "a missing day unit folds days into hours"
check "[dcf] remain 1 hr, 1 min remaining" "$out" \
    "includesTimeRemainingPhrase appends the remaining phrase"
check "[dcf] about About 1 hr, 1 min" "$out" \
    "includesApproximationPhrase prefixes the approximate phrase"
check "[dcf] comps 2 hr, 5 min" "$out" \
    "date components format through the same unit styles"
check "[dcf] dates 1:01:01" "$out" \
    "stringFromDate:toDate: formats the date difference"
check "[dcf] delta 3661" "$out" \
    "NSDate timeIntervalSinceDate: reports the signed interval"

# ---------- 4g5. NSMeasurement units and formatting ----------
"$CC" -target "$TARGET" -fobjc-runtime=ios-18.0 -fno-objc-arc \
    -ffreestanding -O1 -I "$ROOT/frameworks" \
    -c "$ROOT/tests/measurement_test.m" -o "$T/measurement.o"
"$LD64" -arch x86_64 -platform_version $PLATFORM -e _main \
    -o "$T/measurement" "$T/measurement.o" \
    "$ROOT/runtime/System/Library/Frameworks/Foundation.framework/Foundation" \
    -undefined dynamic_lookup
out="$(DYLD_ROOT_PATH="$ROOT/runtime" "$RUN" "$T/measurement" 2>&1)"
check "[meas] done" "$out" \
    "the measurement fixture converts, adds and formats"
if report="$(python3 - "$out" <<'PY'
import re
import sys

values = {}
flags = {}
for line in sys.argv[1].splitlines():
    m = re.match(r'\[meas\] (km-m|m-mi|f-c|k-c|h-s|kmh-ms|gal-l|add) '
                 r'([-0-9.]+)$', line)
    if m:
        values[m.group(1)] = float(m.group(2))
    m = re.match(r'\[meas\] (equal|uneq) (\d)$', line)
    if m:
        flags[m.group(1)] = int(m.group(2))
expected = {
    'km-m': 1500.0,
    'm-mi': 1.0,
    'f-c': 0.0,
    'k-c': 26.85,
    'h-s': 5400.0,
    'kmh-ms': 27.7778,
    'gal-l': 3.7854,
    'add': 1.5,
}
for key, want in expected.items():
    if key not in values:
        raise SystemExit('missing conversion %s' % key)
    if abs(values[key] - want) > 0.02:
        raise SystemExit('%s converted to %r, expected %r' %
                         (key, values[key], want))
if flags.get('equal') != 1 or flags.get('uneq') != 0:
    raise SystemExit('measurement equality is wrong: %r' % (flags,))
print("ok   measurements convert across metric and imperial units")
PY
)"; then
    echo "$report"
else
    echo "FAIL measurement conversion"; echo "$report"; fails=$((fails+1))
fi
if report="$(python3 - "$out" <<'PY'
import re
import sys

want = {
    'nat': '1.5 kilometers',
    'short': '1.5 km',
    'provided': '1500 meters',
    'unit': 'kilometers',
    'temp': '32 degrees Fahrenheit',
    'tempnounit': '32',
    'small': '2 centimeters',
    'grams': '500 grams',
}
seen = {}
for line in sys.argv[1].splitlines():
    m = re.match(r'\[meas\] ([a-z]+) (.*)$', line)
    if m and m.group(1) in want:
        seen[m.group(1)] = m.group(2)
for key, text in want.items():
    if key not in seen:
        raise SystemExit('missing format %s: %r' % (key, seen))
    if seen[key] != text:
        raise SystemExit('%s formatted as %r, expected %r' %
                         (key, seen[key], text))
print("ok   measurement formats use natural scale, styles and options")
PY
)"; then
    echo "$report"
else
    echo "FAIL measurement formatting"; echo "$report"; fails=$((fails+1))
fi

# ---------- 4g6. HTTP cookie storage ----------
python3 -u "$ROOT/tests/cookie_http_server.py" > "$T/cookie.log" 2>&1 &
COOKIE_PID=$!
COOKIE_PORT=""
i=0
while [ "$i" -lt 100 ]; do
    COOKIE_PORT=$(sed -n 's/.*port \([0-9][0-9]*\).*/\1/p' "$T/cookie.log" | head -1)
    [ -n "$COOKIE_PORT" ] && break
    i=$((i + 1))
    sleep 0.05
done
if [ -z "$COOKIE_PORT" ]; then
    echo "FAIL cookie server did not start"
    fails=$((fails + 1))
    kill "$COOKIE_PID" 2>/dev/null || true
else
    "$CC" -target "$TARGET" -fobjc-runtime=ios-18.0 -fno-objc-arc \
        -fblocks -ffreestanding -O1 -I "$ROOT/frameworks" \
        -c "$ROOT/tests/cookies_test.m" -o "$T/cookies_test.o"
    "$LD64" -arch x86_64 -platform_version $PLATFORM -e _main \
        -o "$T/cookies_test" "$T/cookies_test.o" \
        "$ROOT/runtime/System/Library/Frameworks/Foundation.framework/Foundation" \
        -undefined dynamic_lookup
    out="$(DYLD_ROOT_PATH="$ROOT/runtime" "$RUN" "$T/cookies_test" \
        "$COOKIE_PORT" 2>&1)"
    check "[cookie] done" "$out" "the cookie fixture runs"
    if report="$(python3 - "$out" <<'PY'
import re
import sys

lines = sys.argv[1].splitlines()
want = [
    r'\[cookie\] direct a 1',
    r'\[cookie\] header a=1',
    r'\[cookie\] manual 1 manual yes',
]
for pattern in want:
    if not any(re.fullmatch(pattern, line) for line in lines):
        raise SystemExit('missing cookie line: ' + pattern)
print("ok   cookie properties and header fields serialize")
PY
)"; then
        echo "$report"
    else
        echo "FAIL cookie properties"; echo "$report"; fails=$((fails+1))
    fi
    if report="$(python3 - "$out" <<'PY'
import re
import sys

lines = sys.argv[1].splitlines()
want = [r'\[cookie\] set 200', r'\[cookie\] stored 2']
for pattern in want:
    if not any(re.fullmatch(pattern, line) for line in lines):
        raise SystemExit('missing cookie storage line: ' + pattern)
print("ok   Set-Cookie responses populate the shared storage")
PY
)"; then
        echo "$report"
    else
        echo "FAIL cookie storage"; echo "$report"; fails=$((fails+1))
    fi
    if report="$(python3 - "$out" <<'PY'
import re
import sys

pattern = (r'\[cookie\] echo body '
           r'cookie session=abc123; theme=dark')
if not any(re.fullmatch(pattern, line) for line in sys.argv[1].splitlines()):
    raise SystemExit('the echoed Cookie header did not carry both cookies')
print("ok   URL requests replay stored cookies in order")
PY
)"; then
        echo "$report"
    else
        echo "FAIL cookie replay"; echo "$report"; fails=$((fails+1))
    fi
fi
kill "$COOKIE_PID" 2>/dev/null || true

# ---------- 4g7. NSURLCache response caching ----------
python3 -u "$ROOT/tests/cache_http_server.py" > "$T/cache.log" 2>&1 &
CACHE_PID=$!
CACHE_PORT=""
i=0
while [ "$i" -lt 100 ]; do
    CACHE_PORT=$(sed -n 's/.*port \([0-9][0-9]*\).*/\1/p' "$T/cache.log" | head -1)
    [ -n "$CACHE_PORT" ] && break
    i=$((i + 1))
    sleep 0.05
done
if [ -z "$CACHE_PORT" ]; then
    echo "FAIL cache server did not start"
    fails=$((fails + 1))
    kill "$CACHE_PID" 2>/dev/null || true
else
    "$CC" -target "$TARGET" -fobjc-runtime=ios-18.0 -fno-objc-arc \
        -fblocks -ffreestanding -O1 -I "$ROOT/frameworks" \
        -c "$ROOT/tests/urlcache_test.m" -o "$T/urlcache_test.o"
    "$LD64" -arch x86_64 -platform_version $PLATFORM -e _main \
        -o "$T/urlcache_test" "$T/urlcache_test.o" \
        "$ROOT/runtime/System/Library/Frameworks/Foundation.framework/Foundation" \
        -undefined dynamic_lookup
    out="$(DYLD_ROOT_PATH="$ROOT/runtime" "$RUN" "$T/urlcache_test" \
        "$CACHE_PORT" 2>&1)"
    check "[cache] done" "$out" "the URL cache fixture runs"
    if report="$(python3 - "$out" <<'PY'
import re
import sys

lines = sys.argv[1].splitlines()
want = [
    r'\[cache\] capacity 4194304',
    r'\[cache\] first 200 count 1',
    r'\[cache\] second 200 count 1',
    r'\[cache\] manual 1 manual',
]
for pattern in want:
    if not any(re.fullmatch(pattern, line) for line in lines):
        raise SystemExit('missing cache line: ' + pattern)
print("ok   a repeated GET is served from the shared cache")
PY
)"; then
        echo "$report"
    else
        echo "FAIL cache replay"; echo "$report"; fails=$((fails+1))
    fi
    if report="$(python3 - "$out" <<'PY'
import re
import sys

lines = sys.argv[1].splitlines()
want = [r'\[cache\] third 200 count 2',
        r'\[cache\] reload 200 count 3']
for pattern in want:
    if not any(re.fullmatch(pattern, line) for line in lines):
        raise SystemExit('missing cache line: ' + pattern)
print("ok   removal and a reload policy force fresh requests")
PY
)"; then
        echo "$report"
    else
        echo "FAIL cache policy"; echo "$report"; fails=$((fails+1))
    fi
fi
kill "$CACHE_PID" 2>/dev/null || true

# ---------- 4g8. NSURLSession upload and download tasks ----------
python3 -u "$ROOT/tests/tasks_http_server.py" > "$T/tasks.log" 2>&1 &
TASKS_PID=$!
TASKS_PORT=""
i=0
while [ "$i" -lt 100 ]; do
    TASKS_PORT=$(sed -n 's/.*port \([0-9][0-9]*\).*/\1/p' "$T/tasks.log" | head -1)
    [ -n "$TASKS_PORT" ] && break
    i=$((i + 1))
    sleep 0.05
done
if [ -z "$TASKS_PORT" ]; then
    echo "FAIL tasks server did not start"
    fails=$((fails + 1))
    kill "$TASKS_PID" 2>/dev/null || true
else
    "$CC" -target "$TARGET" -fobjc-runtime=ios-18.0 -fno-objc-arc \
        -fblocks -ffreestanding -O1 -I "$ROOT/frameworks" \
        -c "$ROOT/tests/urlsession_tasks_test.m" -o "$T/urlsession_tasks_test.o"
    "$LD64" -arch x86_64 -platform_version $PLATFORM -e _main \
        -o "$T/urlsession_tasks_test" "$T/urlsession_tasks_test.o" \
        "$ROOT/runtime/System/Library/Frameworks/Foundation.framework/Foundation" \
        -undefined dynamic_lookup
    out="$(DYLD_ROOT_PATH="$ROOT/runtime" "$RUN" "$T/urlsession_tasks_test" \
        "$TASKS_PORT" 2>&1)"
    check "[tasks] download 200 1 16 downloaded bytes" "$out" \
        "a download task completes with a temp file holding the body"
    check "[tasks] upload 200 14 upload payload" "$out" \
        "an upload task sends its data and receives the echo"
    check "[tasks] done" "$out" "the URLSession task fixture runs"
fi
kill "$TASKS_PID" 2>/dev/null || true

# ---------- 4g9. NSInputStream and NSOutputStream ----------
"$CC" -target "$TARGET" -fobjc-runtime=ios-18.0 -fno-objc-arc \
    -fblocks -ffreestanding -O1 -I "$ROOT/frameworks" \
    -c "$ROOT/tests/streams_test.m" -o "$T/streams_test.o"
"$LD64" -arch x86_64 -platform_version $PLATFORM -e _main \
    -o "$T/streams_test" "$T/streams_test.o" \
    "$ROOT/runtime/System/Library/Frameworks/Foundation.framework/Foundation" \
    -undefined dynamic_lookup
out="$(DYLD_ROOT_PATH="$ROOT/runtime" "$RUN" "$T/streams_test" 2>&1)"
check "[stream] data 0 1 4 stre 9 amed text 5 0 0" "$out" \
    "an input stream reads data in chunks and reaches the end"
check "[stream] dataclose 6" "$out" \
    "closing an input stream reports the closed status"
check "[stream] file hello from a file" "$out" \
    "a file input stream reads the file contents"
check "[stream] memory 12 hello stream" "$out" \
    "a memory output stream exposes its written data"
check "[stream] fileout file output 1" "$out" \
    "a file output stream writes the file"
check "[stream] append file output! 1" "$out" \
    "append mode adds to the existing file"

# ---------- 4g10. URLSession delegate callbacks ----------
python3 -u "$ROOT/tests/tasks_http_server.py" > "$T/tasks2.log" 2>&1 &
TASKS2_PID=$!
TASKS2_PORT=""
i=0
while [ "$i" -lt 100 ]; do
    TASKS2_PORT=$(sed -n 's/.*port \([0-9][0-9]*\).*/\1/p' "$T/tasks2.log" | head -1)
    [ -n "$TASKS2_PORT" ] && break
    i=$((i + 1))
    sleep 0.05
done
if [ -z "$TASKS2_PORT" ]; then
    echo "FAIL delegate server did not start"
    fails=$((fails + 1))
    kill "$TASKS2_PID" 2>/dev/null || true
else
    "$CC" -target "$TARGET" -fobjc-runtime=ios-18.0 -fno-objc-arc \
        -fblocks -ffreestanding -O1 -I "$ROOT/frameworks" \
        -c "$ROOT/tests/urlsession_delegate_test.m" \
        -o "$T/urlsession_delegate_test.o"
    "$LD64" -arch x86_64 -platform_version $PLATFORM -e _main \
        -o "$T/urlsession_delegate_test" "$T/urlsession_delegate_test.o" \
        "$ROOT/runtime/System/Library/Frameworks/Foundation.framework/Foundation" \
        -undefined dynamic_lookup
    out="$(DYLD_ROOT_PATH="$ROOT/runtime" "$RUN" "$T/urlsession_delegate_test" \
        "$TASKS2_PORT" 2>&1)"
    check "[delegate] data 1 16 downloaded bytes" "$out" \
        "a data task delivers its body to the delegate"
    check "[delegate] progress 2 16 16" "$out" \
        "a download task reports progress to the delegate"
    check "[delegate] file 2 1 16 downloaded bytes" "$out" \
        "the download delegate reads the finished temp file"
    check "[delegate] complete 1 0" "$out" \
        "the data task completes without an error"
    check "[delegate] complete 2 0" "$out" \
        "the download task completes without an error"
    check "[delegate] done 2" "$out" "the delegate fixture finishes both tasks"
fi
kill "$TASKS2_PID" 2>/dev/null || true


# ---------- 4g10b. URLSession redirect handling ----------
python3 -u "$ROOT/tests/redirect_http_server.py" > "$T/redirect.log" 2>&1 &
REDIRECT_PID=$!
REDIRECT_PORT=""
i=0
while [ "$i" -lt 100 ]; do
    REDIRECT_PORT=$(sed -n 's/.*port \([0-9][0-9]*\).*/\1/p' "$T/redirect.log" | head -1)
    [ -n "$REDIRECT_PORT" ] && break
    i=$((i + 1))
    sleep 0.05
done
if [ -z "$REDIRECT_PORT" ]; then
    echo "FAIL redirect server did not start"
    fails=$((fails + 1))
    kill "$REDIRECT_PID" 2>/dev/null || true
else
    "$CC" -target "$TARGET" -fobjc-runtime=ios-18.0 -fno-objc-arc \
        -fblocks -ffreestanding -O1 -I "$ROOT/frameworks" \
        -c "$ROOT/tests/urlsession_redirect_test.m" \
        -o "$T/urlsession_redirect_test.o"
    "$LD64" -arch x86_64 -platform_version $PLATFORM -e _main \
        -o "$T/urlsession_redirect_test" "$T/urlsession_redirect_test.o" \
        "$ROOT/runtime/System/Library/Frameworks/Foundation.framework/Foundation" \
        -undefined dynamic_lookup
    out="$(DYLD_ROOT_PATH="$ROOT/runtime" "$RUN" "$T/urlsession_redirect_test" \
        "$REDIRECT_PORT" 2>&1)"
    check "[redirect] start 200 1 15 redirected body /final" "$out" \
        "a relative Location redirect is followed to the final URL"
    check "[redirect] chain 200 1 15 redirected body /final" "$out" \
        "a redirect chain resolves each Location against the previous URL"
    check "[redirect] post 200 1 15 redirected body /final" "$out" \
        "a 303 redirect turns a POST into a GET"
    check "[redirect] kept 200 1 10 final post /final" "$out" \
        "a 307 redirect preserves the POST method and body"
    check "[redirect] loop error -1007" "$out" \
        "a redirect loop fails with NSURLErrorHTTPTooManyRedirects"
fi
kill "$REDIRECT_PID" 2>/dev/null || true

# ---------- 4g10c. URLSession redirect delegate decisions ----------
python3 -u "$ROOT/tests/redirect_http_server.py" > "$T/redirect2.log" 2>&1 &
REDIRECT2_PID=$!
REDIRECT2_PORT=""
i=0
while [ "$i" -lt 100 ]; do
    REDIRECT2_PORT=$(sed -n 's/.*port \([0-9][0-9]*\).*/\1/p' "$T/redirect2.log" | head -1)
    [ -n "$REDIRECT2_PORT" ] && break
    i=$((i + 1))
    sleep 0.05
done
if [ -z "$REDIRECT2_PORT" ]; then
    echo "FAIL redirect delegate server did not start"
    fails=$((fails + 1))
    kill "$REDIRECT2_PID" 2>/dev/null || true
else
    "$CC" -target "$TARGET" -fobjc-runtime=ios-18.0 -fno-objc-arc \
        -fblocks -ffreestanding -O1 -I "$ROOT/frameworks" \
        -c "$ROOT/tests/urlsession_redirect_delegate_test.m" \
        -o "$T/urlsession_redirect_delegate_test.o"
    "$LD64" -arch x86_64 -platform_version $PLATFORM -e _main \
        -o "$T/urlsession_redirect_delegate_test" \
        "$T/urlsession_redirect_delegate_test.o" \
        "$ROOT/runtime/System/Library/Frameworks/Foundation.framework/Foundation" \
        -undefined dynamic_lookup
    out="$(DYLD_ROOT_PATH="$ROOT/runtime" "$RUN" \
        "$T/urlsession_redirect_delegate_test" "$REDIRECT2_PORT" 2>&1)"
    check "[redirect-delegate] ask 302 /final" "$out" \
        "the redirect delegate sees the response and the proposed request"
    check "[redirect-delegate] allow" "$out" \
        "returning the proposed request lets the task follow the redirect"
    check "[redirect-delegate] final 200 1 15 redirected body /final" "$out" \
        "an allowed redirect completes on the final response"
    check "[redirect-delegate] deny" "$out" \
        "returning nil refuses the redirect"
    check "[redirect-delegate] refused 301 1 5 moved /hop" "$out" \
        "a refused redirect delivers the redirect response itself"
fi
kill "$REDIRECT2_PID" 2>/dev/null || true

# ---------- 4g11. NSLock, NSRecursiveLock and NSCondition ----------
"$CC" -target "$TARGET" -fobjc-runtime=ios-18.0 -fno-objc-arc \
    -ffreestanding -O1 -I "$ROOT/frameworks" \
    -c "$ROOT/tests/locks_test.m" -o "$T/locks_test.o"
"$LD64" -arch x86_64 -platform_version $PLATFORM -e _main \
    -o "$T/locks_test" "$T/locks_test.o" \
    "$ROOT/runtime/System/Library/Frameworks/Foundation.framework/Foundation" \
    -undefined dynamic_lookup
out="$(DYLD_ROOT_PATH="$ROOT/runtime" "$RUN" "$T/locks_test" 2>&1)"
check "[lock] try0 1" "$out" "a fresh NSLock tryLock succeeds"
check "[lock] try1 0" "$out" \
    "a non-recursive NSLock refuses a second tryLock from its owner"
check "[lock] try2 1" "$out" "an unlocked NSLock can be taken again"
check "[lock] past 0" "$out" \
    "lockBeforeDate: times out while the lock is held"
check "[lock] future 1" "$out" \
    "lockBeforeDate: takes a free lock before its deadline"
check "[lock] name L" "$out" "NSLock keeps its name"
check "[recursive] depth 1" "$out" \
    "NSRecursiveLock accepts nested tryLock from its owner"
check "[recursive] free 1" "$out" \
    "NSRecursiveLock is free after every unlock"
check "[condition] timeout 0" "$out" \
    "NSCondition waitUntilDate: returns NO on timeout"
check "[condition] started 1" "$out" \
    "a pthread worker signals the condition it waits on"
check "[condition] finished 3" "$out" \
    "the main thread wakes the worker through the same condition"
check "[condlock] init 0" "$out" \
    "NSConditionLock starts with its initial condition"
check "[condlock] wrong 0" "$out" \
    "NSConditionLock refuses a try for another condition"
check "[condlock] right 1" "$out" \
    "NSConditionLock accepts a try for the current condition"
check "[condlock] now 2" "$out" \
    "unlockWithCondition: publishes the new condition"
check "[condlock] locked 2" "$out" \
    "lockWhenCondition: acquires a matching condition"
check "[condlock] past 0" "$out" \
    "lockBeforeDate: times out while the condition lock is held"
check "[condlock] future 1" "$out" \
    "lockBeforeDate: takes a free condition lock"

# ---------- 4g12. NSThread start, detach and state ----------
"$CC" -target "$TARGET" -fobjc-runtime=ios-18.0 -fno-objc-arc \
    -ffreestanding -O1 -I "$ROOT/frameworks" \
    -c "$ROOT/tests/thread_test.m" -o "$T/thread_test.o"
"$LD64" -arch x86_64 -platform_version $PLATFORM -e _main \
    -o "$T/thread_test" "$T/thread_test.o" \
    "$ROOT/runtime/System/Library/Frameworks/Foundation.framework/Foundation" \
    -undefined dynamic_lookup
out="$(DYLD_ROOT_PATH="$ROOT/runtime" "$RUN" "$T/thread_test" 2>&1)"
check "[thread] main 1" "$out" "the main thread reports isMainThread"
check "[thread] current 0" "$out" \
    "a worker's currentThread is not the main thread"
check "[thread] name Worker" "$out" "NSThread keeps its name"
check "[thread] before 0 0" "$out" \
    "a new thread is neither executing nor finished"
check "[thread] started 1" "$out" "starting a thread marks it executing"
check "[thread] worker done 1 main 0" "$out" \
    "the worker runs its selector and signals the main thread"
check "[thread] finished 1 0" "$out" \
    "the trampoline marks the thread finished after main returns"
check "[thread] priority 0.5" "$out" \
    "a thread starts with the default 0.5 priority"
check "[thread] detached 1" "$out" \
    "detachNewThreadSelector: starts a real pthread"
check "[thread] cancelled 1" "$out" "cancel marks an unstarted thread cancelled"

# ---------- 4g13. NSOperation state, priority and waiting ----------
"$CC" -target "$TARGET" -fobjc-runtime=ios-18.0 -fno-objc-arc \
    -fblocks -ffreestanding -O1 -I "$ROOT/frameworks" \
    -c "$ROOT/tests/operation_extra_test.m" -o "$T/operation_extra_test.o"
"$LD64" -arch x86_64 -platform_version $PLATFORM -e _main \
    -o "$T/operation_extra_test" "$T/operation_extra_test.o" \
    "$ROOT/runtime/System/Library/Frameworks/Foundation.framework/Foundation" \
    -undefined dynamic_lookup
out="$(DYLD_ROOT_PATH="$ROOT/runtime" "$RUN" "$T/operation_extra_test" 2>&1)"
check "[op] name Worker" "$out" "NSOperation keeps its name"
check "[op] priority 1" "$out" "NSOperation stores its queue priority"
check "[op] before 0 1" "$out" \
    "a new operation is not executing and is ready"
check "[op] running 1" "$out" \
    "a queued operation reports isExecuting while its block runs"
check "[op] operations 1" "$out" \
    "the queue lists the running operation"
check "[op] finished 1 0" "$out" \
    "waitUntilFinished returns after the operation completes"
check "[op] count 0" "$out" \
    "the finished operation leaves the queue count"

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
# An interrupted run can leave guests recreating device directories; stop
# them before wiping the home (anchored on the loader and this home only).
for stale in $(pgrep -f "^$RUN .*$IOSIM_HOME" 2>/dev/null); do
    kill -9 "$stale" 2>/dev/null || true
done
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

# A thin arm64 app bundle starts through the same device path as any app.
# The launch passes a framework search directory but no --load-dylib, so
# the loader preloads the standard frameworks from the runtime root; the
# scene delegate, views and label are arm64 app code on the interpreter
# and block translator while UIKit stays native, and the capture lands in
# the device framebuffer. A dedicated device keeps the first device's app
# list and icon layout untouched for the touch tests below.
"$CC" -target arm64-apple-ios18.0-simulator -ffreestanding \
    -fobjc-runtime=ios-18.0 -fno-objc-arc -fblocks -O1 -I "$ROOT/demo" \
    -c "$ROOT/tests/arm64_device_app.m" -o "$T/arm64_device_app.o"
"$LD64" -arch arm64 -platform_version $PLATFORM -e _main \
    -o "$T/arm64_device_app" "$T/arm64_device_app.o" -undefined dynamic_lookup
rm -rf "$T/Arm64Device.app"
mkdir -p "$T/Arm64Device.app"
cp "$T/arm64_device_app" "$T/Arm64Device.app/Arm64Device"
python3 - "$T/Arm64Device.app/Info.plist" <<'PY'
import plistlib, sys
with open(sys.argv[1], "wb") as f:
    plistlib.dump({
        "CFBundleIdentifier": "com.iosim.arm64device",
        "CFBundleExecutable": "Arm64Device",
        "CFBundleName": "Arm64Device",
        "CFBundlePackageType": "APPL",
        "CFBundleVersion": "1",
        "CFBundleShortVersionString": "1.0",
    }, f)
PY
UDID_A64="$("$ROOT/tools/iosimctl" create "Arm64 iPhone" com.iosim.SimDeviceType.iPhone-18-Pro)"
"$ROOT/tools/iosimctl" boot "$UDID_A64" >/dev/null
"$ROOT/tools/iosimctl" install "$UDID_A64" "$T/Arm64Device.app" >/dev/null
DLOG="$IOSIM_HOME/Devices/$UDID_A64/logs/launch-com.iosim.arm64device.log"
# Let SpringBoard finish the repaint the install triggered, then keep the
# app alive on its own event stream. A launch without one returns from
# UIApplicationMain after a single frame, and a later SpringBoard repaint
# could overwrite the device framebuffer before the screenshot.
sleep 0.5
A64FIFO="$T/arm64device.fifo"
rm -f "$A64FIFO"
mkfifo "$A64FIFO"
rm -f "$T/a64fb.marker"
touch "$T/a64fb.marker"
A64FB="$IOSIM_HOME/Devices/$UDID_A64/data/var/run/framebuffer.png"
launch_out="$(SIMCTL_CHILD_IOSIM_EVENT_FIFO="$A64FIFO" \
    "$ROOT/tools/iosimctl" launch "$UDID_A64" com.iosim.arm64device)"
a64pid="${launch_out##*: }"
i=0
while [ "$i" -lt 100 ]; do
    if [ -f "$A64FB" ] && [ "$A64FB" -nt "$T/a64fb.marker" ]; then
        break
    fi
    sleep 0.1
    i=$((i+1))
done
if grep -Fq -- "[arm64device] ready" "$DLOG" 2>/dev/null; then
    echo "ok   an arm64 app bundle runs through the device launch path"
else
    echo "FAIL arm64 device app launch"
    tail -n 20 "$DLOG" 2>/dev/null || true
    fails=$((fails+1))
fi
"$ROOT/tools/iosimctl" io "$UDID_A64" screenshot "$T/arm64_device.png" >/dev/null
if out="$(python3 - "$ROOT/tools" "$T/arm64_device.png" <<'PY'
import sys
sys.path.insert(0, sys.argv[1])
import pngpixel

w, h, bpp, rows = pngpixel.load(sys.argv[2])
want = [(255, 0, 0), (0, 255, 0), (0, 0, 255), (0, 0, 0)]
pts = []
for x, y in ((100, 140), (100, 260), (100, 380), (350, 800)):
    c = pngpixel.px(rows, bpp, x * 3, y * 3)
    pts.append(((c >> 16) & 255, (c >> 8) & 255, c & 255))
if pts != want:
    raise SystemExit("device frame samples are %r" % (pts,))
white = 0
for yy in range(480 * 3, 528 * 3):
    for xx in range(40 * 3, 360 * 3):
        c = pngpixel.px(rows, bpp, xx, yy)
        r, g, b = (c >> 16) & 255, (c >> 8) & 255, c & 255
        if r > 200 and g > 200 and b > 200:
            white += 1
if white < 200:
    raise SystemExit("label drew only %d white pixels" % white)
print("ok   the arm64 app's device screenshot shows its scene")
PY
)"; then
    echo "$out"
else
    echo "FAIL arm64 device screenshot"; echo "$out"; fails=$((fails+1))
fi
# SpringBoard launches the same arm64 bundle from its home-screen icon. The
# only installed app on this device occupies grid slot 7 (row 1 column 3);
# the child inherits the device event stream, renders, and suspends on home
# like any other app. Its stdout goes to the SpringBoard log.
A64SB="$IOSIM_HOME/Devices/$UDID_A64/logs/springboard.log"
"$ROOT/tools/iosimctl" ui "$UDID_A64" tap 339.8333 222.1667 >/dev/null
i=0
while [ "$i" -lt 100 ]; do
    if grep -Fq -- "[arm64device] ready" "$A64SB" 2>/dev/null; then
        break
    fi
    sleep 0.1
    i=$((i+1))
done
if grep -Fq -- "[SpringBoard] launching Arm64Device" "$A64SB" 2>/dev/null &&
    grep -Fq -- "[arm64device] ready" "$A64SB" 2>/dev/null; then
    echo "ok   SpringBoard launches the arm64 app from its icon"
else
    echo "FAIL arm64 SpringBoard launch"
    tail -n 20 "$A64SB" 2>/dev/null || true
    fails=$((fails+1))
fi
sleep 0.4
"$ROOT/tools/iosimctl" io "$UDID_A64" screenshot "$T/arm64_device_sb.png" >/dev/null
if out="$(python3 - "$ROOT/tools" "$T/arm64_device_sb.png" <<'PY'
import sys
sys.path.insert(0, sys.argv[1])
import pngpixel

w, h, bpp, rows = pngpixel.load(sys.argv[2])
want = [(255, 0, 0), (0, 255, 0), (0, 0, 255), (0, 0, 0)]
pts = []
for x, y in ((100, 140), (100, 260), (100, 380), (350, 800)):
    c = pngpixel.px(rows, bpp, x * 3, y * 3)
    pts.append(((c >> 16) & 255, (c >> 8) & 255, c & 255))
if pts != want:
    raise SystemExit("SpringBoard frame samples are %r" % (pts,))
print("ok   the SpringBoard-launched arm64 app renders the same scene")
PY
)"; then
    echo "$out"
else
    echo "FAIL arm64 SpringBoard screenshot"; echo "$out"; fails=$((fails+1))
fi
"$ROOT/tools/iosimctl" ui "$UDID_A64" home >/dev/null
i=0
while [ "$i" -lt 100 ]; do
    if grep -Fq -- "backgrounded by the system" "$A64SB" 2>/dev/null; then
        break
    fi
    sleep 0.1
    i=$((i+1))
done
if grep -Fq -- "backgrounded by the system" "$A64SB" 2>/dev/null; then
    echo "ok   home backgrounds the arm64 app and returns to SpringBoard"
else
    echo "FAIL arm64 SpringBoard home"; fails=$((fails+1))
fi
kill "$a64pid" 2>/dev/null || true
rm -f "$A64FIFO"
"$ROOT/tools/iosimctl" uninstall "$UDID_A64" com.iosim.arm64device >/dev/null
"$ROOT/tools/iosimctl" shutdown "$UDID_A64" >/dev/null

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
    echo "missing log line: $needle" >&2
    tail -n 20 "$SBLOG" >&2
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
# Tapping the same icon continues the same process (grid slot 9). While the
# process is stopped, its cached frame zooms from the icon to full screen.
zoom_before="$(grep -Fc "[SpringBoard] launch zoom" "$SBLOG" 2>/dev/null || true)"
zoom_start=$(date +%s%N)
"$ROOT/tools/iosimctl" ui "$UDID" tap 154.7222 322.5 >/dev/null
zoom_now="$zoom_before"
i=0
while [ "$i" -lt 50 ]; do
    zoom_now="$(grep -Fc "[SpringBoard] launch zoom" "$SBLOG" 2>/dev/null || true)"
    [ "$zoom_now" -gt "$zoom_before" ] && break
    sleep 0.05
    i=$((i+1))
done
if [ "$zoom_now" -gt "$zoom_before" ] &&
    grep -Fq "[SpringBoard] launch zoom TouchApp" "$SBLOG"; then
    echo "ok   resuming an app zooms its cached frame up from the icon"
else
    echo "FAIL launch zoom ($zoom_before -> $zoom_now)"; fails=$((fails+1))
fi
zoom_ms=$(( ($(date +%s%N) - zoom_start) / 1000000 ))
if [ "$zoom_ms" -ge 150 ]; then
    echo "ok   the launch zoom animates before the app resumes"
else
    echo "FAIL launch zoom timing ($zoom_ms ms)"; fails=$((fails+1))
fi
if wait_log "resuming TouchApp"; then
    echo "ok   SpringBoard resumes the suspended app process"
else
    echo "FAIL app resume"; fails=$((fails+1))
fi
zoom_line="$(grep -n -F "[SpringBoard] launch zoom TouchApp" "$SBLOG" 2>/dev/null | tail -1 | cut -d: -f1)"
resume_line="$(grep -n -F "[SpringBoard] resuming TouchApp" "$SBLOG" 2>/dev/null | tail -1 | cut -d: -f1)"
if [ -n "$zoom_line" ] && [ -n "$resume_line" ] &&
    [ "$zoom_line" -lt "$resume_line" ]; then
    echo "ok   the zoom's final frame is drawn before the resume"
else
    echo "FAIL launch zoom order (zoom=$zoom_line resume=$resume_line)"
    fails=$((fails+1))
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
# ---------- 7c2. switcher cards slide between suspended apps ----------
# The switcher strip eases to the neighbouring card instead of jumping. The
# card log is deferred until the slide's final frame, so a waiting harness
# screenshots the settled card. This device holds two suspended apps; the
# newest (TouchApp) is centred, so a right swipe selects the older UIKitApp.
"$ROOT/tools/iosimctl" ui "$UDID" swipe 60 400 340 400 0.2 >/dev/null
slide_start=$(date +%s%N)
card_before="$(grep -Fc "[SpringBoard] switcher card" "$SBLOG" 2>/dev/null || true)"
sleep 0.10
card_mid="$(grep -Fc "[SpringBoard] switcher card" "$SBLOG" 2>/dev/null || true)"
if [ "$card_mid" -eq "$card_before" ]; then
    echo "ok   the switcher card slide is still in flight 100 ms after the swipe"
else
    echo "FAIL switcher slide timing ($card_before -> $card_mid)"; fails=$((fails+1))
fi
card_now="$card_mid"
i=0
while [ "$i" -lt 50 ]; do
    card_now="$(grep -Fc "[SpringBoard] switcher card" "$SBLOG" 2>/dev/null || true)"
    [ "$card_now" -gt "$card_before" ] && break
    sleep 0.1
    i=$((i+1))
done
card_last="$(grep -F "[SpringBoard] switcher card" "$SBLOG" 2>/dev/null | tail -1)"
if [ "$card_now" -gt "$card_before" ] &&
    printf '%s\n' "$card_last" | grep -Fq "switcher card UIKitApp"; then
    echo "ok   a right swipe slides to the older app's card"
else
    echo "FAIL switcher slide selection ($card_before -> $card_now: $card_last)"
    fails=$((fails+1))
fi
slide_ms=$(( ($(date +%s%N) - slide_start) / 1000000 ))
if [ "$slide_ms" -ge 150 ]; then
    echo "ok   the switcher slide animates before reporting the new card"
else
    echo "FAIL switcher slide duration ($slide_ms ms)"; fails=$((fails+1))
fi
# Swipe back so the existing tap below lands on the centred TouchApp card.
card_before="$card_now"
"$ROOT/tools/iosimctl" ui "$UDID" swipe 340 400 60 400 0.2 >/dev/null
card_now="$card_before"
i=0
while [ "$i" -lt 50 ]; do
    card_now="$(grep -Fc "[SpringBoard] switcher card" "$SBLOG" 2>/dev/null || true)"
    [ "$card_now" -gt "$card_before" ] && break
    sleep 0.1
    i=$((i+1))
done
card_last="$(grep -F "[SpringBoard] switcher card" "$SBLOG" 2>/dev/null | tail -1)"
if [ "$card_now" -gt "$card_before" ] &&
    printf '%s\n' "$card_last" | grep -Fq "switcher card TouchApp"; then
    echo "ok   a left swipe slides back to the newer card"
else
    echo "FAIL switcher slide back ($card_before -> $card_now: $card_last)"
    fails=$((fails+1))
fi
sleep 0.1
resumed_before="$(grep -Fc "[UIKit-lite] resumed from suspension" "$SBLOG" 2>/dev/null || true)"
swzoom_before="$(grep -Fc "[SpringBoard] launch zoom TouchApp" "$SBLOG" 2>/dev/null || true)"
"$ROOT/tools/iosimctl" ui "$UDID" tap 201 400 >/dev/null
if wait_log "switcher selected TouchApp"; then
    echo "ok   tapping a switcher card selects the suspended app"
else
    echo "FAIL switcher selection"; fails=$((fails+1))
fi
swzoom_now="$swzoom_before"
i=0
while [ "$i" -lt 50 ]; do
    swzoom_now="$(grep -Fc "[SpringBoard] launch zoom TouchApp" "$SBLOG" 2>/dev/null || true)"
    [ "$swzoom_now" -gt "$swzoom_before" ] && break
    sleep 0.05
    i=$((i+1))
done
if [ "$swzoom_now" -gt "$swzoom_before" ]; then
    echo "ok   a switcher card zooms into the resumed app"
else
    echo "FAIL switcher launch zoom ($swzoom_before -> $swzoom_now)"
    fails=$((fails+1))
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
slide_start=$(date +%s%N)
if wait_log "home page 2 of 2"; then
    echo "ok   horizontal swipe moves to the second home page"
else
    echo "FAIL home page swipe"; fails=$((fails+1))
fi
slide_ms=$(( ($(date +%s%N) - slide_start) / 1000000 ))
if [ "$slide_ms" -ge 150 ]; then
    echo "ok   the page turn slides before reporting the new page"
else
    echo "FAIL page slide timing ($slide_ms ms)"; fails=$((fails+1))
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
offset="$(grep -o '\[collection\] scrolled [0-9-]*' "$SBLOG" | tail -1 |
    sed 's/.* //')"
if [ -n "$offset" ] && [ "$offset" -gt 10 ] 2>/dev/null &&
   ! cmp -s "$T/collection.png" "$T/collection-scrolled.png"; then
    echo "ok   dragging scrolls the collection content by its offset"
else
    echo "FAIL collection scrolling (offset ${offset:-missing})"
    fails=$((fails+1))
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
if wait_log "[life] bg began 1 remaining" &&
    wait_log "[life] bg work" &&
    wait_log "background task window closed" &&
    wait_log "backgrounded by the system; suspending"; then
    echo "ok   a background task keeps the app running until its work ends"
else
    echo "FAIL lifecycle background task"; fails=$((fails+1))
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
sleep 0.3
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
sleep 0.3
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

# ---------- binary property lists ----------
"$ROOT/tools/build_app.sh" "$ROOT/tests/binary_plist_test.m" \
    "$T/binary_plist_test" >/dev/null
out="$(DYLD_ROOT_PATH="$ROOT/runtime" "$RUN" "$T/binary_plist_test" 2>&1)"
check "[bplist] header 1 1" "$out" \
    "binary property-list output carries the bplist00 header and trailer"
check "[bplist] dict Hello 42 1 2.5 3 2" "$out" \
    "binary dictionaries round-trip strings, numbers, booleans, data and arrays"
check "[bplist] array 3 4" "$out" \
    "binary arrays preserve their elements"
check "[bplist] unicode 1" "$out" \
    "binary UTF-16 strings round-trip non-ASCII text"
check "[bplist] date 1700000000 format 200" "$out" \
    "binary dates round-trip and the reader reports the binary format"

# ---------- background task bookkeeping ----------
"$ROOT/tools/build_app.sh" "$ROOT/tests/background_task_test.m" \
    "$T/background_task_test" >/dev/null
out="$(DYLD_ROOT_PATH="$ROOT/runtime" "$RUN" \
    "$T/background_task_test" 2>&1)"
check "[bg] token 1 remaining 0" "$out" \
    "beginBackgroundTask returns a token and an active app has no window"
check "[bg] ended 0 expired 0" "$out" \
    "ending a background task clears it without firing the expiration handler"

# ---------- collection supplementary header/footer views ----------
"$ROOT/tools/build_app.sh" "$ROOT/tests/collection_supplementary_test.m" \
    "$T/collection_supplementary_test" >/dev/null
out="$(DYLD_ROOT_PATH="$ROOT/runtime" "$RUN" \
    "$T/collection_supplementary_test" 2>&1)"
check "[supp] frames 0 10 390 40 0 130 390 30" "$out" \
    "flow layout places reusable headers and footers around the section"
check "[supp] sections 0 0 content 170 subviews 4" "$out" \
    "supplementary views join the collection and content size includes them"
check "[supp] classes 1 1" "$out" \
    "dequeue returns the registered header and footer classes"

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

obj "$ROOT/tests/mach_port_lifecycle_test.c" "$T/mach_port_lifecycle.o"
exe "$T/mach_port_lifecycle" "$T/mach_port_lifecycle.o"
out="$(DYLD_ROOT_PATH="$ROOT/runtime" "$RUN" "$T/mach_port_lifecycle" 2>&1)"
check "[mach] lifecycle 1 1 1 1 1 1" "$out" \
    "mach ports refcount rights, deliver messages and fail after release"

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

# A StartInterval job repeats without RunAtLoad and stops when unloaded.
python3 - "$T/launchd_job" "$T/interval.plist" com.iosim.launchd.interval <<'PY'
import plistlib, sys
binary, out, label = sys.argv[1:4]
with open(out, "wb") as f:
    plistlib.dump({
        "Label": label,
        "ProgramArguments": [binary, "interval"],
        "StartInterval": 1,
    }, f)
PY
"$ROOT/tools/iosimctl" launchd-load "$UDID" "$T/interval.plist" >/dev/null
ILOG="$IOSIM_HOME/Devices/$UDID/logs/com.iosim.launchd.interval.log"
i=0
while [ "$i" -lt 60 ]; do
    n=$(grep -c "launchd job: interval" "$ILOG" 2>/dev/null || true)
    [ "${n:-0}" -ge 2 ] && break
    sleep 0.1
    i=$((i+1))
done
n=$(grep -c "launchd job: interval" "$ILOG" 2>/dev/null || true)
if [ "${n:-0}" -ge 2 ]; then
    echo "ok   a StartInterval job repeats without RunAtLoad"
else
    echo "FAIL StartInterval job"; cat "$ILOG" 2>/dev/null || true; fails=$((fails+1))
fi
"$ROOT/tools/iosimctl" launchd-unload "$UDID" com.iosim.launchd.interval >/dev/null
before=$n
sleep 1.4
n_after=$(grep -c "launchd job: interval" "$ILOG" 2>/dev/null || true)
if [ "${n_after:-0}" -eq "${before:-0}" ]; then
    echo "ok   unloading a StartInterval job stops its repeats"
else
    echo "FAIL StartInterval unload"; fails=$((fails+1))
fi

# A KeepAlive job starts without RunAtLoad and restarts after each exit no
# sooner than its ThrottleInterval; unloading it stops the restarts.
python3 - "$T/launchd_job" "$T/keepalive.plist" \
    com.iosim.launchd.keepalive <<'PY'
import plistlib, sys
binary, out, label = sys.argv[1:4]
with open(out, "wb") as f:
    plistlib.dump({
        "Label": label,
        "ProgramArguments": [binary, "keepalive"],
        "KeepAlive": True,
        "ThrottleInterval": 2,
    }, f)
PY
"$ROOT/tools/iosimctl" launchd-load "$UDID" "$T/keepalive.plist" >/dev/null
KLOG="$IOSIM_HOME/Devices/$UDID/logs/com.iosim.launchd.keepalive.log"
if out="$(python3 - "$KLOG" <<'PY'
import sys
import time

path = sys.argv[1]
stamps = []
seen = 0
deadline = time.monotonic() + 9.0
while time.monotonic() < deadline and len(stamps) < 3:
    try:
        with open(path) as f:
            n = sum(1 for line in f if "launchd job: keepalive" in line)
    except FileNotFoundError:
        n = 0
    if n > seen:
        stamps.extend([time.monotonic()] * (n - seen))
        seen = n
    time.sleep(0.05)
if len(stamps) < 3:
    raise SystemExit("only %d starts observed" % len(stamps))
gaps = [b - a for a, b in zip(stamps, stamps[1:])]
if any(g < 1.6 for g in gaps):
    raise SystemExit("restarts are not throttled: %r" % (gaps,))
if any(g > 4.5 for g in gaps):
    raise SystemExit("restarts are too slow: %r" % (gaps,))
print("ok   a KeepAlive job restarts no sooner than ThrottleInterval")
PY
)"; then
    echo "$out"
else
    echo "FAIL KeepAlive throttle"; echo "$out"; fails=$((fails+1))
fi
"$ROOT/tools/iosimctl" launchd-unload "$UDID" \
    com.iosim.launchd.keepalive >/dev/null
before=$(grep -c "launchd job: keepalive" "$KLOG" 2>/dev/null || true)
sleep 2.5
after=$(grep -c "launchd job: keepalive" "$KLOG" 2>/dev/null || true)
if [ "${after:-0}" -eq "${before:-0}" ]; then
    echo "ok   unloading a KeepAlive job stops its restarts"
else
    echo "FAIL KeepAlive unload"; fails=$((fails+1))
fi

# A KeepAlive dictionary gates restarts on the exit status: SuccessfulExit
# true restarts after a zero exit, false keeps a zero exit stopped.
python3 - "$T/launchd_job" "$T/ka_ok.plist" com.iosim.launchd.kaok <<'PY'
import plistlib, sys
binary, out, label = sys.argv[1:4]
with open(out, "wb") as f:
    plistlib.dump({
        "Label": label,
        "ProgramArguments": [binary, "keepalive-exit", "0"],
        "KeepAlive": {"SuccessfulExit": True},
        "ThrottleInterval": 1,
        "RunAtLoad": True,
    }, f)
PY
python3 - "$T/launchd_job" "$T/ka_stop.plist" \
    com.iosim.launchd.kastop <<'PY'
import plistlib, sys
binary, out, label = sys.argv[1:4]
with open(out, "wb") as f:
    plistlib.dump({
        "Label": label,
        "ProgramArguments": [binary, "keepalive-exit", "0"],
        "KeepAlive": {"SuccessfulExit": False},
        "ThrottleInterval": 1,
        "RunAtLoad": True,
    }, f)
PY
"$ROOT/tools/iosimctl" launchd-load "$UDID" "$T/ka_ok.plist" >/dev/null
"$ROOT/tools/iosimctl" launchd-load "$UDID" "$T/ka_stop.plist" >/dev/null
sleep 3.5
AKLOG="$IOSIM_HOME/Devices/$UDID/logs/com.iosim.launchd.kaok.log"
ASLOG="$IOSIM_HOME/Devices/$UDID/logs/com.iosim.launchd.kastop.log"
a_count=$(grep -c "launchd job: keepalive 0" "$AKLOG" 2>/dev/null || true)
s_count=$(grep -c "launchd job: keepalive 0" "$ASLOG" 2>/dev/null || true)
if [ "${a_count:-0}" -ge 2 ]; then
    echo "ok   SuccessfulExit true restarts a job after a zero exit"
else
    echo "FAIL SuccessfulExit restart"; cat "$AKLOG" 2>/dev/null || true
    fails=$((fails+1))
fi
if [ "${s_count:-0}" -eq 1 ]; then
    echo "ok   SuccessfulExit false keeps a zero-exit job stopped"
else
    echo "FAIL SuccessfulExit stop"; cat "$ASLOG" 2>/dev/null || true
    fails=$((fails+1))
fi
"$ROOT/tools/iosimctl" launchd-unload "$UDID" com.iosim.launchd.kaok >/dev/null
"$ROOT/tools/iosimctl" launchd-unload "$UDID" \
    com.iosim.launchd.kastop >/dev/null


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

# ---------- 14b. home-screen icon drag between pages ----------
# A held drag lifts a stock Fitness icon into a ghost that follows the
# finger; hovering in the right-edge strip turns to the second page and the
# drop moves the icon there. The order is persisted and survives a reboot.
GRID_UDID="$("$ROOT/tools/iosimctl" create "Grid iPhone" com.iosim.SimDeviceType.iPhone-18-Pro)"
"$ROOT/tools/iosimctl" boot "$GRID_UDID" >/dev/null
SAVED_SBLOG="$SBLOG"
SBLOG="$IOSIM_HOME/Devices/$GRID_UDID/logs/springboard.log"
sleep 1
i=1
while [ "$i" -le 20 ]; do
    n="$(printf '%02d' "$i")"
    d="$T/Grid$n.app"
    rm -rf "$d"
    mkdir -p "$d"
    cp "$T/hello" "$d/GridApp"
    python3 - "$d/Info.plist" "$n" <<'PY'
import plistlib, sys
n = sys.argv[2]
with open(sys.argv[1], "wb") as f:
    plistlib.dump({
        "CFBundleIdentifier": "com.iosim.grid%s" % n,
        "CFBundleExecutable": "GridApp",
        "CFBundleName": "Grid%s" % n,
        "CFBundlePackageType": "APPL",
        "CFBundleVersion": "1",
        "CFBundleShortVersionString": "1.0",
    }, f)
PY
    "$ROOT/tools/iosimctl" install "$GRID_UDID" "$d" >/dev/null
    i=$((i + 1))
done
sleep 0.6
"$ROOT/tools/iosimctl" io "$GRID_UDID" screenshot "$T/grid-before.png" >/dev/null
"$ROOT/tools/iosimctl" ui "$GRID_UDID" down 62.1667 121.8333 >/dev/null
sleep 0.5
"$ROOT/tools/iosimctl" ui "$GRID_UDID" move 200 560 >/dev/null
sleep 0.3
"$ROOT/tools/iosimctl" io "$GRID_UDID" screenshot "$T/grid-grab.png" >/dev/null
if out="$(python3 - "$ROOT/tools" "$T/grid-before.png" "$T/grid-grab.png" <<'PY'
import sys
sys.path.insert(0, sys.argv[1])
import pngpixel

def load(path):
    w, h, bpp, rows = pngpixel.load(path)
    def px(x, y):
        c = pngpixel.px(rows, bpp, int(x * 3), int(y * 3))
        return ((c >> 16) & 255, (c >> 8) & 255, c & 255)
    return px

def colour(px, x0, y0):
    spread = 0
    count = 0
    for dy in range(-28, 29, 2):
        for dx in range(-28, 29, 2):
            r, g, b = px(x0 + dx, y0 + dy)
            s = abs(r - g) + abs(g - b) + abs(r - b)
            if s > spread:
                spread = s
            if s > 120:
                count += 1
    return spread, count

before = load(sys.argv[2])
grab = load(sys.argv[3])
wall = colour(before, 200, 560)
ghost = colour(grab, 200, 560)
if wall[0] > 120:
    raise SystemExit("the wallpaper under the ghost is too colourful: %r" %
                     (wall,))
if ghost[0] < 300 or ghost[1] < 100:
    raise SystemExit("the lifted icon ghost is missing: %r" % (ghost,))
print("ok   a held drag lifts the Fitness icon and the ghost follows the finger")
PY
)"; then
    echo "$out"
else
    echo "FAIL icon grab"; echo "$out"; fails=$((fails+1))
fi
"$ROOT/tools/iosimctl" ui "$GRID_UDID" move 392 222.1667 >/dev/null
"$ROOT/tools/iosimctl" ui "$GRID_UDID" up 392 222.1667 >/dev/null
if wait_log "[SpringBoard] moved Fitness to page 2 slot 8"; then
    echo "ok   dropping an icon at the page edge moves it to the second page"
else
    echo "FAIL icon move"; fails=$((fails+1))
fi
sleep 0.5
"$ROOT/tools/iosimctl" io "$GRID_UDID" screenshot "$T/grid-drop.png" >/dev/null
if out="$(python3 - "$ROOT/tools" "$T/grid-drop.png" <<'PY'
import sys
sys.path.insert(0, sys.argv[1])
import pngpixel

w, h, bpp, rows = pngpixel.load(sys.argv[2])
def px(x, y):
    c = pngpixel.px(rows, bpp, int(x * 3), int(y * 3))
    return ((c >> 16) & 255, (c >> 8) & 255, c & 255)

spread = 0
count = 0
for dy in range(-28, 29, 2):
    for dx in range(-28, 29, 2):
        r, g, b = px(339.8333 + dx, 222.1667 + dy)
        s = abs(r - g) + abs(g - b) + abs(r - b)
        if s > spread:
            spread = s
        if s > 120:
            count += 1
if spread < 300 or count < 100:
    raise SystemExit("Fitness did not land in the slot: %d %d" %
                     (spread, count))
white = lambda c: min(c) > 230
gray = lambda c: 100 < c[0] < 180 and abs(c[0] - c[2]) < 12
if not (gray(px(193, 686)) and white(px(209, 686))):
    raise SystemExit("the page dots do not mark the second page")
print("ok   the dropped icon lands in the second page's fourth column")
PY
)"; then
    echo "$out"
else
    echo "FAIL icon drop"; echo "$out"; fails=$((fails+1))
fi
if [ "$(sed -n '24p' \
    "$IOSIM_HOME/Devices/$GRID_UDID/data/Library/SpringBoard/home_order.txt" \
    2>/dev/null)" = "name:Fitness" ]; then
    echo "ok   the moved icon's slot is persisted to home_order.txt"
else
    echo "FAIL icon order file"; fails=$((fails+1))
fi
"$ROOT/tools/iosimctl" shutdown "$GRID_UDID" >/dev/null
"$ROOT/tools/iosimctl" boot "$GRID_UDID" >/dev/null
SBLOG="$IOSIM_HOME/Devices/$GRID_UDID/logs/springboard.log"
sleep 1
"$ROOT/tools/iosimctl" ui "$GRID_UDID" swipe 350 400 50 400 0.3 >/dev/null
sleep 0.4
"$ROOT/tools/iosimctl" io "$GRID_UDID" screenshot "$T/grid-reboot.png" >/dev/null
if out="$(python3 - "$ROOT/tools" "$T/grid-reboot.png" <<'PY'
import sys
sys.path.insert(0, sys.argv[1])
import pngpixel

w, h, bpp, rows = pngpixel.load(sys.argv[2])
def px(x, y):
    c = pngpixel.px(rows, bpp, int(x * 3), int(y * 3))
    return ((c >> 16) & 255, (c >> 8) & 255, c & 255)

spread = 0
for dy in range(-28, 29, 2):
    for dx in range(-28, 29, 2):
        r, g, b = px(339.8333 + dx, 222.1667 + dy)
        s = abs(r - g) + abs(g - b) + abs(r - b)
        if s > spread:
            spread = s
if spread < 300:
    raise SystemExit("the moved icon is not on the second page: %d" % spread)
c = px(209, 686)
if min(c) < 230:
    raise SystemExit("the second page is not active after the swipe")
print("ok   the saved home order is restored on the next boot")
PY
)"; then
    echo "$out"
else
    echo "FAIL icon restore"; echo "$out"; fails=$((fails+1))
fi
SBLOG="$SAVED_SBLOG"
"$ROOT/tools/iosimctl" shutdown "$GRID_UDID" >/dev/null || true


# ---------- 14c. folder rename ----------
# A long press on the open folder's title turns it into an editable field
# with the software keyboard. Typing edits the name, Return commits it, and
# the new name is saved to folders.txt and drawn in the overlay.
: > "$SBLOG"
"$ROOT/tools/iosimctl" ui "$UDID" tap 62.1667 121.8333 >/dev/null
if wait_log "[SpringBoard] folder opened name=Folder (2 apps)"; then
    echo "ok   the persisted folder opens for renaming"
else
    echo "FAIL folder reopen for rename"; fails=$((fails+1))
fi
sleep 0.3
"$ROOT/tools/iosimctl" ui "$UDID" down 201 92 >/dev/null
sleep 0.7
"$ROOT/tools/iosimctl" ui "$UDID" up 201 92 >/dev/null
if wait_log "[SpringBoard] renaming Folder"; then
    echo "ok   a long press on the folder title starts a rename"
else
    echo "FAIL folder rename start"; fails=$((fails+1))
fi
for c in T o o l x; do
    "$ROOT/tools/iosimctl" ui "$UDID" key "$c" >/dev/null
done
"$ROOT/tools/iosimctl" ui "$UDID" backspace >/dev/null
"$ROOT/tools/iosimctl" ui "$UDID" key s >/dev/null
sleep 0.3
"$ROOT/tools/iosimctl" io "$UDID" screenshot "$T/folder-rename.png" >/dev/null
if out="$(python3 - "$ROOT/tools" "$T/folder-rename.png" <<'PY'
import sys
sys.path.insert(0, sys.argv[1])
import pngpixel
w, h, bpp, rows = pngpixel.load(sys.argv[2])
def px(x, y):
    c = pngpixel.px(rows, bpp, x * 3, y * 3)
    return ((c >> 16) & 255, (c >> 8) & 255, c & 255)
key = px(23, 620)
if not (50 <= key[0] <= 100 and abs(key[0] - key[1]) < 12 and
        abs(key[1] - key[2]) < 12):
    raise SystemExit("rename keyboard not visible: %r" % (key,))
field = px(100, 94)
if not (20 <= field[0] <= 70 and abs(field[0] - field[2]) < 22):
    raise SystemExit("edit field not drawn: %r" % (field,))
white = 0
for yy in range(80 * 3, 112 * 3):
    for xx in range(140 * 3, 262 * 3):
        c = pngpixel.px(rows, bpp, xx, yy)
        if min((c >> 16) & 255, (c >> 8) & 255, c & 255) > 200:
            white += 1
if white < 40:
    raise SystemExit("typed folder name is not drawn: %d" % white)
print("ok   the rename field and keyboard draw the typed name")
PY
)"; then
    echo "$out"
else
    echo "FAIL folder rename editing"; echo "$out"; fails=$((fails+1))
fi
"$ROOT/tools/iosimctl" ui "$UDID" key return >/dev/null
if wait_log "[SpringBoard] folder renamed Tools (2 apps)"; then
    echo "ok   Return commits the new folder name"
else
    echo "FAIL folder rename commit"; fails=$((fails+1))
fi
sleep 0.3
"$ROOT/tools/iosimctl" io "$UDID" screenshot "$T/folder-renamed.png" >/dev/null
if out="$(python3 - "$ROOT/tools" "$T/folder-renamed.png" <<'PY'
import sys
sys.path.insert(0, sys.argv[1])
import pngpixel
w, h, bpp, rows = pngpixel.load(sys.argv[2])
def px(x, y):
    c = pngpixel.px(rows, bpp, x * 3, y * 3)
    return ((c >> 16) & 255, (c >> 8) & 255, c & 255)
key = px(23, 620)
if not (key[0] < 30 and key[1] < 40 and key[2] < 70):
    raise SystemExit("keyboard still visible after rename: %r" % (key,))
white = 0
for yy in range(78 * 3, 104 * 3):
    for xx in range(140 * 3, 262 * 3):
        c = pngpixel.px(rows, bpp, xx, yy)
        if min((c >> 16) & 255, (c >> 8) & 255, c & 255) > 200:
            white += 1
if white < 40:
    raise SystemExit("renamed title is not drawn: %d" % white)
print("ok   the overlay draws the renamed title without the keyboard")
PY
)"; then
    echo "$out"
else
    echo "FAIL folder renamed drawing"; echo "$out"; fails=$((fails+1))
fi
if grep -Fq -- "Tools|com.iosim.datepicker,com.iosim.picker" \
    "$IOSIM_HOME/Devices/$UDID/data/Library/SpringBoard/folders.txt" \
    2>/dev/null; then
    echo "ok   the new folder name is saved to folders.txt"
else
    echo "FAIL folder rename file"; fails=$((fails+1))
fi
"$ROOT/tools/iosimctl" ui "$UDID" tap 201 700 >/dev/null
if wait_log "[SpringBoard] folder closed"; then
    echo "ok   tapping outside closes the renamed folder"
else
    echo "FAIL renamed folder close"; fails=$((fails+1))
fi


# ---------- 14d. folder pagination ----------
# A folder with thirteen members shows twelve slots on its first page and a
# second page with the last member; the page dots follow, a left swipe turns
# the page and a second-page member launches. The test restores the original
# folder list afterwards, because a thirteen-member folder collapses twelve
# grid slots and later sections depend on the original layout.
: > "$SBLOG"
FOLDERS="$IOSIM_HOME/Devices/$UDID/data/Library/SpringBoard/folders.txt"
cp "$FOLDERS" "$T/folders-before-pages.txt"
cat > "$FOLDERS" <<'FOLDERLIST'
Tools|com.iosim.datepicker,com.iosim.picker,com.iosim.fixture,com.iosim.uikit,com.iosim.touch,com.iosim.animation,com.iosim.page1,com.iosim.page2,com.iosim.page3,com.iosim.page4,com.iosim.page5,com.iosim.page6,com.iosim.page7
FOLDERLIST
"$ROOT/tools/iosimctl" shutdown "$UDID" >/dev/null
"$ROOT/tools/iosimctl" boot "$UDID" >/dev/null
sleep 1
"$ROOT/tools/iosimctl" ui "$UDID" tap 339.8333 222.1667 >/dev/null
if wait_log "[SpringBoard] folder opened name=Tools (13 apps)"; then
    echo "ok   a thirteen-member folder opens on its first page"
else
    echo "FAIL paged folder open"; fails=$((fails+1))
fi
sleep 0.4
"$ROOT/tools/iosimctl" io "$UDID" screenshot "$T/folder-page1.png" >/dev/null
if out="$(python3 - "$ROOT/tools" "$T/folder-page1.png" <<'PAGE1'
import sys
sys.path.insert(0, sys.argv[1])
import pngpixel
w, h, bpp, rows = pngpixel.load(sys.argv[2])

def white(x, y):
    n = 0
    for yy in range((y - 5) * 3, (y + 5) * 3):
        for xx in range((x - 5) * 3, (x + 5) * 3):
            c = pngpixel.px(rows, bpp, xx, yy)
            if c == 0xffffff:
                n += 1
    return n

first = white(193, 444)
second = white(209, 444)
if first < 20 or second > 5:
    raise SystemExit("page dots wrong on page 1: %d %d" % (first, second))
print("ok   the folder's first page selects the first of two dots")
PAGE1
)"; then
    echo "$out"
else
    echo "FAIL folder page dots"; echo "$out"; fails=$((fails+1))
fi
"$ROOT/tools/iosimctl" ui "$UDID" swipe 350 250 60 250 0.25 >/dev/null
if wait_log "[SpringBoard] folder page 2 of 2"; then
    echo "ok   a left swipe turns to the folder's second page"
else
    echo "FAIL folder page swipe"; fails=$((fails+1))
fi
sleep 0.4
"$ROOT/tools/iosimctl" io "$UDID" screenshot "$T/folder-page2.png" >/dev/null
if out="$(python3 - "$ROOT/tools" "$T/folder-page2.png" <<'PAGE2'
import sys
sys.path.insert(0, sys.argv[1])
import pngpixel
w, h, bpp, rows = pngpixel.load(sys.argv[2])

def white(x, y):
    n = 0
    for yy in range((y - 5) * 3, (y + 5) * 3):
        for xx in range((x - 5) * 3, (x + 5) * 3):
            c = pngpixel.px(rows, bpp, xx, yy)
            if c == 0xffffff:
                n += 1
    return n

first = white(193, 444)
second = white(209, 444)
if second < 20 or first > 5:
    raise SystemExit("page dots wrong on page 2: %d %d" % (first, second))
print("ok   the second page selects the second dot")
PAGE2
)"; then
    echo "$out"
else
    echo "FAIL folder second page dots"; echo "$out"; fails=$((fails+1))
fi
"$ROOT/tools/iosimctl" ui "$UDID" tap 68.25 190 >/dev/null
if wait_log "Page7 ("; then
    echo "ok   tapping a second-page member resumes its app"
else
    echo "FAIL second-page member launch"; fails=$((fails+1))
fi
"$ROOT/tools/iosimctl" ui "$UDID" home >/dev/null
sleep 0.4
cp "$T/folders-before-pages.txt" "$FOLDERS"
"$ROOT/tools/iosimctl" shutdown "$UDID" >/dev/null
"$ROOT/tools/iosimctl" boot "$UDID" >/dev/null
sleep 1
"$ROOT/tools/iosimctl" ui "$UDID" swipe 350 400 50 400 0.3 >/dev/null
sleep 0.4
"$ROOT/tools/iosimctl" ui "$UDID" swipe 350 400 50 400 0.3 >/dev/null
if wait_log "[SpringBoard] home page 3 of 3"; then
    echo "ok   the restored layout returns to the third home page"
else
    echo "FAIL folder test cleanup"; fails=$((fails+1))
fi

# ---------- 14e. shutdown cleanup ----------
# A shutdown ends the device's guest processes instead of leaving SpringBoard
# and app processes behind; the environment of every process is checked for
# the device's SIMULATOR_UDID before and after.
CLEAN_UDID="$("$ROOT/tools/iosimctl" create "Cleanup iPhone" com.iosim.SimDeviceType.iPhone-18-Pro)"
"$ROOT/tools/iosimctl" boot "$CLEAN_UDID" >/dev/null
sleep 1
if out="$(python3 - "$CLEAN_UDID" <<'PY'
import os, sys
needle = ("SIMULATOR_UDID=%s" % sys.argv[1]).encode()
alive = 0
for name in os.listdir("/proc"):
    if not name.isdigit():
        continue
    try:
        with open("/proc/%s/environ" % name, "rb") as f:
            envi = f.read().split(b"\0")
    except OSError:
        continue
    if needle in envi:
        alive += 1
if not alive:
    raise SystemExit("no guest process was found after boot")
print("ok   a booted device runs guest processes")
PY
)"; then
    echo "$out"
else
    echo "FAIL shutdown boot"; echo "$out"; fails=$((fails+1))
fi
"$ROOT/tools/iosimctl" shutdown "$CLEAN_UDID" >/dev/null
sleep 0.3
if out="$(python3 - "$CLEAN_UDID" <<'PY'
import os, sys
needle = ("SIMULATOR_UDID=%s" % sys.argv[1]).encode()
left = []
for name in os.listdir("/proc"):
    if not name.isdigit():
        continue
    try:
        with open("/proc/%s/environ" % name, "rb") as f:
            envi = f.read().split(b"\0")
    except OSError:
        continue
    if needle in envi:
        left.append(name)
if left:
    raise SystemExit("device processes remain: %s" % " ".join(left))
print("ok   a shutdown leaves no device process behind")
PY
)"; then
    echo "$out"
else
    echo "FAIL shutdown cleanup"; echo "$out"; fails=$((fails+1))
fi
"$ROOT/tools/iosimctl" delete "$CLEAN_UDID" >/dev/null

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

# ---------- 4d2. serial dispatch queues and ordered sync ----------
"$CC" -target "$TARGET" -fobjc-runtime=ios-18.0 -fno-objc-arc \
    -fblocks -ffreestanding -O1 -I "$ROOT/frameworks" \
    -c "$ROOT/tests/dispatch_queue_test.m" -o "$T/dispatch_queue_test.o"
"$LD64" -arch x86_64 -platform_version $PLATFORM -e _main \
    -o "$T/dispatch_queue_test" "$T/dispatch_queue_test.o" \
    "$ROOT/runtime/System/Library/Frameworks/Foundation.framework/Foundation" \
    -undefined dynamic_lookup
out="$(DYLD_ROOT_PATH="$ROOT/runtime" "$RUN" "$T/dispatch_queue_test" 2>&1)"
check "[queue] order abcd" "$out" \
    "blocks on a serial queue run in submission order"
check "[queue] overlap 0" "$out" \
    "a serial queue never runs two blocks at once"
check "[queue] sync xy" "$out" \
    "dispatch_sync waits for the queue's pending blocks"
check "[queue] barrier 12B3 0" "$out" \
    "a barrier keeps its place in the serial FIFO"
check "[queue] done" "$out" "the dispatch queue fixture finishes"

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
python3 -u "$ROOT/tests/echo_http_server.py" > "$T/echo.log" 2>&1 &
ECHO_PID=$!
ECHO_PORT=""
i=0
while [ "$i" -lt 100 ]; do
    ECHO_PORT=$(sed -n 's/.*port \([0-9][0-9]*\).*/\1/p' "$T/echo.log" | head -1)
    [ -n "$ECHO_PORT" ] && break
    i=$((i + 1))
    sleep 0.05
done
if [ -z "$HTTP_PORT" ] || [ -z "$TLS_PORT" ] || [ -z "$ECHO_PORT" ]; then
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
        "$HTTP_PORT" "$TLS_PORT" "$ECHO_PORT" 2>&1)"
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
    check "[post] status 200" "$out" \
        "NSMutableURLRequest sends a POST and receives the status"
    check "[post] body POST ping yes" "$out" \
        "the request method, body and custom header reach the server"
    check "[post] done 1" "$out" \
        "the POST completion handler runs"
fi
kill "$HTTP_PID" "$TLS_PID" "$ECHO_PID" 2>/dev/null || true
wait "$HTTP_PID" "$TLS_PID" "$ECHO_PID" 2>/dev/null || true

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
check "[cg] stroke 0000ff" "$out" \
    "CGContextStrokeRect strokes with the stroke color"
check "[cg] lineprops 0 2" "$out" \
    "CGContext reports the current cap and join styles"
check "[cg] dash on ffffff" "$out" \
    "a dash pattern paints the on interval"
check "[cg] dash off 000000" "$out" \
    "a dash pattern leaves the off interval blank"
check "[cg] cap square ff0000" "$out" \
    "a square cap extends past the line endpoint"
check "[cg] cap butt 000000" "$out" \
    "a butt cap ends at the line endpoint"
check "[cg] join miter ffffff" "$out" \
    "a miter join fills the outer corner"
check "[cg] join bevel 000000" "$out" \
    "a bevel join clips the outer corner"
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
check "[cg] colorspace rgb=1 gray=0 color=1 comps 0.25 0.50 0.75 alpha 1.00 same=1" \
    "$out" "CGColorSpace models and CGColorCreate components round-trip"
check "[cg] pathbox 10 10 20 20 inside=1 outside=0" "$out" \
    "CGPathGetBoundingBox and CGPathContainsPoint locate a rect path"
check "[cg] pathcopy inside=1" "$out" \
    "CGPathCreateCopy duplicates path geometry"
check "[cg] clip path inside 00ff00 outside ff0000" "$out" \
    "CGContextClip rasterizes a non-rectangular clip mask"
check "[cg] curve elements 20" "$out" \
    "CGPathAddCurveToPoint subdivides from the second-derivative bound"
check "[cg] curve error 1" "$out" \
    "the flattened cubic stays within the 0.25-point flatness tolerance"
check "[cg] quad elements 6" "$out" \
    "CGPathAddQuadCurveToPoint adapts its segment count"
check "[cg] curve gentle 2" "$out" \
    "a straight quadratic collapses to one segment"
check "[cg] curve sharp 55" "$out" \
    "a sharp cubic subdivides far more finely than a gentle one"
check "[cg] gradient 1 1" "$out" \
    "CGContextDrawLinearGradient interpolates color stops across a context"
check "[cg] gradient fade 1 1" "$out" \
    "gradient alpha stops fade from opaque red to reveal the white backdrop"
check "[cg] arc fill 1 0 0" "$out" \
    "CGContextAddArc fills a half-disc and leaves the other half clear"
check "[cg] arcto fill 1 1 0" "$out" \
    "CGContextAddArcToPoint rounds a corner around its tangent arc"
check "[cg] path arc 1 0 bbox 20 50 60 30" "$out" \
    "CGPathAddArc fills its arc and reports the arc bounding box"
check "[cg] path arcto 1 0" "$out" \
    "CGPathAddArcToPoint cuts the sharp corner from the path"
check "[cg] ui arc cw 1 0" "$out" \
    "UIBezierPath clockwise arcs sweep the short way"
check "[cg] ui arc ccw 1 0" "$out" \
    "UIBezierPath counterclockwise arcs sweep the long way"

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

"$ROOT/tools/build_app.sh" "$ROOT/tests/calayer_mask_test.m" \
    "$T/calayer_mask_test" >/dev/null
out="$(IOSIM_TEST_PNG="$T/calayer_mask.png" DYLD_ROOT_PATH="$ROOT/runtime" \
    "$RUN" "$T/calayer_mask_test" 2>&1)"
check "[mask] masks 1 1 1" "$out" \
    "CALayer mask retains the mask layer on layers and view backing layers"
check "[mask] png written" "$out" \
    "the masked layer fixture captures a frame"
if out="$(python3 - "$ROOT/tools" "$T/calayer_mask.png" <<'PY'
import sys
sys.path.insert(0, sys.argv[1])
import pngpixel
w, h, bpp, rows = pngpixel.load(sys.argv[2])

def px(x, y):
    return pngpixel.px(rows, bpp, x * 3, y * 3)

def rgb(x, y):
    c = px(x, y)
    return ((c >> 16) & 255, (c >> 8) & 255, c & 255)

r, g, b = rgb(90, 170)
if not (r > 200 and g < 60 and b < 60):
    raise SystemExit("masked-in half of the strip is not red: %02x%02x%02x" % (r, g, b))
r, g, b = rgb(190, 170)
if not (r < 40 and g < 40 and b < 60):
    raise SystemExit("masked-out half of the strip changed: %02x%02x%02x" % (r, g, b))
r, g, b = rgb(140, 350)
if not (b > 200 and r < 60 and g < 80):
    raise SystemExit("oval mask kept the view center: %02x%02x%02x" % (r, g, b))
r, g, b = rgb(48, 306)
if not (r < 40 and g < 40 and b < 60):
    raise SystemExit("oval mask left the view corner visible: %02x%02x%02x" % (r, g, b))
r, g, b = rgb(140, 530)
if not (100 < r < 180 and g < 50 and b < 60):
    raise SystemExit("half-alpha mask did not blend: %02x%02x%02x" % (r, g, b))
print("ok   CALayer masks clip layer trees and carry partial alpha")
PY
)"; then
    echo "$out"
else
    echo "FAIL CALayer mask"; echo "$out"; fails=$((fails+1))
fi

"$ROOT/tools/build_app.sh" "$ROOT/tests/cagradient_test.m" \
    "$T/cagradient_test" >/dev/null
out="$(IOSIM_TEST_PNG="$T/cagradient.png" DYLD_ROOT_PATH="$ROOT/runtime" \
    "$RUN" "$T/cagradient_test" 2>&1)"
check "[grad] colors 3 locations 3" "$out" \
    "CAGradientLayer stores colors and explicit stop locations"
check "[grad] png written" "$out" \
    "the gradient layer fixture captures a frame"
if out="$(python3 - "$ROOT/tools" "$T/cagradient.png" <<'PY'
import sys
sys.path.insert(0, sys.argv[1])
import pngpixel
w, h, bpp, rows = pngpixel.load(sys.argv[2])

def rgb(x, y):
    c = pngpixel.px(rows, bpp, x * 3, y * 3)
    return ((c >> 16) & 255, (c >> 8) & 255, c & 255)

r, g, b = rgb(115, 130)
if not (g > 220 and r < 40 and b < 50):
    raise SystemExit("explicit stop at 0.25 is not green: %02x%02x%02x" % (r, g, b))
r, g, b = rgb(45, 130)
if not (r > 180 and 20 < g < 90 and b < 40):
    raise SystemExit("first segment does not ease red toward green: %02x%02x%02x" % (r, g, b))
r, g, b = rgb(315, 130)
if not (b > 200 and g < 50 and r < 40):
    raise SystemExit("gradient end is not blue: %02x%02x%02x" % (r, g, b))
r, g, b = rgb(180, 255)
if not (r > 200 and 40 < g < 140 and b < 40):
    raise SystemExit("even-spaced top is not red-yellow: %02x%02x%02x" % (r, g, b))
r, g, b = rgb(180, 285)
if not (r > 230 and g > 230 and b < 40):
    raise SystemExit("even-spaced middle is not yellow: %02x%02x%02x" % (r, g, b))
r, g, b = rgb(180, 320)
if not (b > 150 and r < 100):
    raise SystemExit("even-spaced bottom is not blue: %02x%02x%02x" % (r, g, b))
r, g, b = rgb(130, 430)
if not (g > 220 and r < 40 and b < 40):
    raise SystemExit("rounded gradient center is not green: %02x%02x%02x" % (r, g, b))
r, g, b = rgb(34, 384)
if not (r < 40 and g < 40 and b < 60):
    raise SystemExit("rounded gradient corner is not clipped: %02x%02x%02x" % (r, g, b))
r, g, b = rgb(45, 550)
if not (r > 200 and g < 60 and b < 60):
    raise SystemExit("fade mask start is not opaque red: %02x%02x%02x" % (r, g, b))
r, g, b = rgb(150, 550)
if not (100 < r < 180 and g < 50 and b < 60):
    raise SystemExit("fade mask midpoint is not a half blend: %02x%02x%02x" % (r, g, b))
r, g, b = rgb(255, 550)
if not (r < 40 and g < 40 and b < 60):
    raise SystemExit("fade mask end is not transparent: %02x%02x%02x" % (r, g, b))
print("ok   CAGradientLayer interpolates explicit and even-spaced stops")
PY
)"; then
    echo "$out"
else
    echo "FAIL CAGradientLayer stops"; echo "$out"; fails=$((fails+1))
fi

"$ROOT/tools/build_app.sh" "$ROOT/tests/calayer_transform_test.m" \
    "$T/calayer_transform_test" >/dev/null
out="$(IOSIM_TEST_PNG="$T/calayer_transform.png" \
    DYLD_ROOT_PATH="$ROOT/runtime" "$RUN" \
    "$T/calayer_transform_test" 2>&1)"
check "[tf] identity 1 rot 1 translate 1 concat 1" "$out" \
    "CATransform3D constructors build the expected 2D matrices"
check "[tf] png written" "$out" \
    "the transformed layer fixture captures a frame"
if out="$(python3 - "$ROOT/tools" "$T/calayer_transform.png" <<'PY'
import sys
sys.path.insert(0, sys.argv[1])
import pngpixel
w, h, bpp, rows = pngpixel.load(sys.argv[2])

def rgb(x, y):
    c = pngpixel.px(rows, bpp, x * 3, y * 3)
    return ((c >> 16) & 255, (c >> 8) & 255, c & 255)

r, g, b = rgb(120, 160)
if not (r > 200 and g < 60 and b < 60):
    raise SystemExit("rotated layer center is not red: %02x%02x%02x" % (r, g, b))
r, g, b = rgb(70, 110)
if not (r < 40 and g < 40 and b < 60):
    raise SystemExit("rotated layer kept its square corner: %02x%02x%02x" % (r, g, b))
r, g, b = rgb(120, 80)
if not (r > 200 and g < 60 and b < 60):
    raise SystemExit("rotated layer does not extend past the old top edge: %02x%02x%02x" % (r, g, b))
r, g, b = rgb(30, 330)
if not (b > 200 and r < 60):
    raise SystemExit("scaled layer does not widen left: %02x%02x%02x" % (r, g, b))
r, g, b = rgb(200, 330)
if not (b > 200 and r < 60):
    raise SystemExit("scaled layer does not widen right: %02x%02x%02x" % (r, g, b))
r, g, b = rgb(5, 330)
if not (b < 60 and r < 40):
    raise SystemExit("scaled layer overflows its 2x extent: %02x%02x%02x" % (r, g, b))
r, g, b = rgb(110, 510)
if not (g > 200 and r < 60 and b < 60):
    raise SystemExit("identity layer is not green: %02x%02x%02x" % (r, g, b))
r, g, b = rgb(250, 510)
if not (g < 60 and r < 40):
    raise SystemExit("identity layer changed size: %02x%02x%02x" % (r, g, b))
r, g, b = rgb(110, 630)
if not (r > 200 and g > 200 and b < 60):
    raise SystemExit("translated layer is not at its new position: %02x%02x%02x" % (r, g, b))
r, g, b = rgb(70, 630)
if not (r < 40 and g < 40 and b < 60):
    raise SystemExit("translated layer left a copy at its old position: %02x%02x%02x" % (r, g, b))
r, g, b = rgb(190, 730)
if not (r > 200 and g < 60 and b > 200):
    raise SystemExit("perspective layer center is not magenta: %02x%02x%02x" % (r, g, b))
r, g, b = rgb(145, 730)
if not (r < 40 and g < 40 and b < 60):
    raise SystemExit("perspective layer kept its left edge: %02x%02x%02x" % (r, g, b))
print("ok   CALayer transforms rotate, scale and translate offscreen")
PY
)"; then
    echo "$out"
else
    echo "FAIL CALayer transform"; echo "$out"; fails=$((fails+1))
fi

"$ROOT/tools/build_app.sh" "$ROOT/tests/shape_stroke_test.m" \
    "$T/shape_stroke_test" >/dev/null
out="$(IOSIM_TEST_PNG="$T/shape_stroke.png" \
    DYLD_ROOT_PATH="$ROOT/runtime" "$RUN" "$T/shape_stroke_test" 2>&1)"
check "[stroke] props 1" "$out" \
    "CAShapeLayer stores strokeStart, strokeEnd and lineCap"
check "[stroke] dashprops 2 0" "$out" \
    "CAShapeLayer stores a dash pattern and join style"
check "[stroke] png written" "$out" \
    "the stroke trimming fixture captures a frame"
if out="$(python3 - "$ROOT/tools" "$T/shape_stroke.png" <<'PY'
import sys
sys.path.insert(0, sys.argv[1])
import pngpixel
w, h, bpp, rows = pngpixel.load(sys.argv[2])

def rgb(x, y):
    c = pngpixel.px(rows, bpp, x * 3, y * 3)
    return ((c >> 16) & 255, (c >> 8) & 255, c & 255)

r, g, b = rgb(110, 100)
if not (g > 200 and r < 60):
    raise SystemExit("trimmed line is not drawn: %02x%02x%02x" % (r, g, b))
r, g, b = rgb(70, 100)
if not (r < 40 and g < 40 and b < 60):
    raise SystemExit("line start was not trimmed: %02x%02x%02x" % (r, g, b))
r, g, b = rgb(230, 100)
if not (r < 40 and g < 40 and b < 60):
    raise SystemExit("line end was not trimmed: %02x%02x%02x" % (r, g, b))
r, g, b = rgb(87, 100)
if not (g > 200 and r < 60):
    raise SystemExit("round start cap missing: %02x%02x%02x" % (r, g, b))
r, g, b = rgb(193, 100)
if not (g > 200 and r < 60):
    raise SystemExit("round end cap missing: %02x%02x%02x" % (r, g, b))
r, g, b = rgb(200, 340)
if not (b > 200 and r < 60):
    raise SystemExit("half-stroked oval bottom is not drawn: %02x%02x%02x" % (r, g, b))
r, g, b = rgb(200, 180)
if not (r < 40 and g < 40 and b < 60):
    raise SystemExit("half-stroked oval top was not trimmed: %02x%02x%02x" % (r, g, b))
r, g, b = rgb(280, 260)
if not (b > 200 and r < 60):
    raise SystemExit("oval start endpoint is missing: %02x%02x%02x" % (r, g, b))
r, g, b = rgb(120, 260)
if not (b > 200 and r < 60):
    raise SystemExit("oval half-way endpoint is missing: %02x%02x%02x" % (r, g, b))
r, g, b = rgb(120, 400)
if not (r > 200 and 60 < g < 180 and b < 60):
    raise SystemExit("rounded rect top segment is not drawn: %02x%02x%02x" % (r, g, b))
r, g, b = rgb(120, 500)
if not (r < 40 and g < 40 and b < 60):
    raise SystemExit("rounded rect bottom segment was not trimmed: %02x%02x%02x" % (r, g, b))
r, g, b = rgb(40, 423)
if not (r > 200 and 60 < g < 180 and b < 60):
    raise SystemExit("rounded rect start point is missing: %02x%02x%02x" % (r, g, b))
r, g, b = rgb(44, 496)
if not (r < 40 and g < 40 and b < 60):
    raise SystemExit("rounded rect kept its bottom-left corner: %02x%02x%02x" % (r, g, b))
r, g, b = rgb(45, 560)
if not (r > 200 and g > 170 and b < 80):
    raise SystemExit("dashed layer on interval missing: %02x%02x%02x" % (r, g, b))
r, g, b = rgb(58, 560)
if not (r < 40 and g < 40 and b < 60):
    raise SystemExit("dashed layer off interval painted: %02x%02x%02x" % (r, g, b))
print("ok   CAShapeLayer trims strokes by arc length and rounds caps")
PY
)"; then
    echo "$out"
else
    echo "FAIL CAShapeLayer stroke trimming"; echo "$out"; fails=$((fails+1))
fi

"$ROOT/tools/build_app.sh" "$ROOT/tests/rounded_clip_test.m" \
    "$T/rounded_clip_test" >/dev/null
out="$(IOSIM_TEST_PNG="$T/rounded_clip.png" DYLD_ROOT_PATH="$ROOT/runtime" \
    "$RUN" "$T/rounded_clip_test" 2>&1)"
check "[rclip] png written" "$out" \
    "the rounded clipping fixture captures a frame"
if out="$(python3 - "$ROOT/tools" "$T/rounded_clip.png" <<'PY'
import sys
sys.path.insert(0, sys.argv[1])
import pngpixel

w, h, bpp, rows = pngpixel.load(sys.argv[2])

def rgb(x, y):
    c = pngpixel.px(rows, bpp, x * 3, y * 3)
    return ((c >> 16) & 255, (c >> 8) & 255, c & 255)

def near(c, r, g, b, slack=12):
    return (abs(c[0] - r) <= slack and abs(c[1] - g) <= slack and
            abs(c[2] - b) <= slack)

checks = [
    ((140, 160), near(rgb(140, 160), 255, 0, 0), "clipped center"),
    ((42, 102), near(rgb(42, 102), 0, 0, 0), "clipped corner"),
    ((60, 120), near(rgb(60, 120), 255, 0, 0), "clipped inside"),
    ((140, 360), near(rgb(140, 360), 255, 230, 0), "masks center"),
    ((42, 302), near(rgb(42, 302), 0, 0, 0), "masks corner"),
    ((60, 320), near(rgb(60, 320), 255, 230, 0), "masks inside"),
    ((42, 502), near(rgb(42, 502), 255, 128, 0), "unclipped corner"),
    ((140, 560), near(rgb(140, 560), 255, 128, 0), "unclipped center"),
    ((42, 702), near(rgb(42, 702), 0, 0, 0), "top-left cut"),
    ((238, 702), near(rgb(238, 702), 0, 0, 0), "top-right cut"),
    ((42, 818), near(rgb(42, 818), 0, 255, 0), "bottom-left square"),
    ((238, 818), near(rgb(238, 818), 0, 255, 0), "bottom-right square"),
]
bad = [name for _pt, ok, name in checks if not ok]
if bad:
    raise SystemExit("rounded clipping failed: " + ", ".join(bad))
print("ok   rounded clipping masks a subtree, clipsToBounds and maskedCorners")
PY
)"; then
    echo "$out"
else
    echo "FAIL rounded clipping"; echo "$out"; fails=$((fails+1))
fi

"$ROOT/tools/build_app.sh" "$ROOT/tests/snapshot_view_test.m" \
    "$T/snapshot_view_test" >/dev/null
out="$(IOSIM_TEST_PNG="$T/snapshot_view.png" DYLD_ROOT_PATH="$ROOT/runtime" \
    "$RUN" "$T/snapshot_view_test" 2>&1)"
check "[snap] size 100.0 80.0" "$out" \
    "a view snapshot keeps the source bounds"
check "[snap] png written" "$out" \
    "the snapshot fixture captures a frame"
if out="$(python3 - "$ROOT/tools" "$T/snapshot_view.png" <<'PY'
import sys
sys.path.insert(0, sys.argv[1])
import pngpixel

w, h, bpp, rows = pngpixel.load(sys.argv[2])

def rgb(x, y):
    c = pngpixel.px(rows, bpp, x * 3, y * 3)
    return ((c >> 16) & 255, (c >> 8) & 255, c & 255)

def near(c, r, g, b, slack=12):
    return (abs(c[0] - r) <= slack and abs(c[1] - g) <= slack and
            abs(c[2] - b) <= slack)

checks = [
    ((90, 140), near(rgb(90, 140), 0, 0, 255), "source recolored"),
    ((42, 102), near(rgb(42, 102), 0, 0, 0), "source corner"),
    ((250, 340), near(rgb(250, 340), 255, 0, 0), "snapshot red"),
    ((230, 320), near(rgb(230, 320), 255, 230, 0), "snapshot chip"),
    ((202, 302), near(rgb(202, 302), 0, 0, 0), "snapshot corner"),
]
bad = [name for _pt, ok, name in checks if not ok]
if bad:
    raise SystemExit("snapshot pixels failed: " + ", ".join(bad))
print("ok   a view snapshot keeps old colors and rounded corners")
PY
)"; then
    echo "$out"
else
    echo "FAIL view snapshot"; echo "$out"; fails=$((fails+1))
fi

"$ROOT/tools/build_app.sh" "$ROOT/tests/hierarchy_draw_test.m" \
    "$T/hierarchy_draw_test" >/dev/null
out="$(IOSIM_TEST_PNG="$T/hierarchy_draw.png" DYLD_ROOT_PATH="$ROOT/runtime" \
    "$RUN" "$T/hierarchy_draw_test" 2>&1)"
check "[hd] drew 1" "$out" \
    "drawViewHierarchyInRect reports success inside an image renderer"
check "[hd] png written" "$out" \
    "the hierarchy draw fixture captures a frame"
if out="$(python3 - "$ROOT/tools" "$T/hierarchy_draw.png" <<'PY'
import sys
sys.path.insert(0, sys.argv[1])
import pngpixel

w, h, bpp, rows = pngpixel.load(sys.argv[2])

def rgb(x, y):
    c = pngpixel.px(rows, bpp, x * 3, y * 3)
    return ((c >> 16) & 255, (c >> 8) & 255, c & 255)

def near(c, r, g, b, slack=12):
    return (abs(c[0] - r) <= slack and abs(c[1] - g) <= slack and
            abs(c[2] - b) <= slack)

checks = [
    ((90, 140), near(rgb(90, 140), 255, 0, 0), "drawn red"),
    ((42, 102), near(rgb(42, 102), 0, 0, 0), "drawn corner"),
    ((70, 120), near(rgb(70, 120), 255, 230, 0), "drawn chip"),
]
bad = [name for _pt, ok, name in checks if not ok]
if bad:
    raise SystemExit("hierarchy draw pixels failed: " + ", ".join(bad))
print("ok   drawViewHierarchyInRect captures a rounded hierarchy")
PY
)"; then
    echo "$out"
else
    echo "FAIL hierarchy draw"; echo "$out"; fails=$((fails+1))
fi

# ---------- 4h. UILabel single-line fitting ----------
"$ROOT/tools/build_app.sh" "$ROOT/tests/label_fit_test.m" \
    "$T/label_fit_test" >/dev/null
out="$(IOSIM_TEST_PNG="$T/label_fit.png" DYLD_ROOT_PATH="$ROOT/runtime" \
    "$RUN" "$T/label_fit_test" 2>&1)"
check "[lfit] default 0 4" "$out" \
    "a plain label leaves auto-shrink off and truncates its tail"
check "[lfit] bounds 1 1" "$out" \
    "textRectForBounds:limitedToNumberOfLines: fits within the bounds"
check "[lfit] shrink 1 1" "$out" \
    "auto-shrink and minimumScaleFactor bound the effective font size"
check "[lfit] ratios 1 1" "$out" \
    "the effective sizes sit at the half and nine-tenths scale floors"
check "[lfit] png written" "$out" \
    "the label fitting fixture captures a frame"
if out="$(python3 - "$ROOT/tools" "$T/label_fit.png" <<'PY'
import sys
sys.path.insert(0, sys.argv[1])
import pngpixel

w, h, bpp, rows = pngpixel.load(sys.argv[2])

def ink(y0, y1):
    ys = []
    xs = []
    for y in range(y0 * 3, y1 * 3):
        for x in range(38 * 3, 148 * 3):
            c = pngpixel.px(rows, bpp, x, y)
            if max((c >> 16) & 255, (c >> 8) & 255, c & 255) > 60:
                ys.append(y)
                xs.append(x)
    if not ys:
        return None
    return (min(xs), max(xs), min(ys), max(ys))

a = ink(80, 140)
b = ink(180, 240)
c = ink(280, 340)
if not a or not b or not c:
    raise SystemExit("label text ink missing (a=%r b=%r c=%r)" % (a, b, c))
ha = a[3] - a[2]
hb = b[3] - b[2]
hc = c[3] - c[2]
if not (ha < hb * 0.65 and ha > hb * 0.35):
    raise SystemExit("minimum 0.5 scale not reached: %d vs %d" % (ha, hb))
if not (hc > ha * 1.4 and hc < hb * 0.97):
    raise SystemExit("minimum 0.9 scale not honored: %d vs %d" % (hc, hb))
for name, ext in (("A", a), ("B", b), ("C", c)):
    if ext[1] > 148 * 3:
        raise SystemExit("%s text overflows its frame: %d" % (name, ext[1]))
print("ok   UILabel shrinks to minimumScaleFactor and truncates the rest")
PY
)"; then
    echo "$out"
else
    echo "FAIL label fitting"; echo "$out"; fails=$((fails+1))
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

# ---------- 38. UITextView selection ----------
"$ROOT/tools/build_app.sh" "$ROOT/tests/textview_selection_test.m" \
    "$T/textview_selection_test" >/dev/null
out="$(DYLD_ROOT_PATH="$ROOT/runtime" "$RUN" \
    "$T/textview_selection_test" 2>&1)"
check "[sel] initial 11 0" "$out" \
    "setText: places the caret at the end of the text"
check "[sel] set 6 5" "$out" \
    "setSelectedRange: stores the requested range"
check "[sel] replaced hello there 11 0" "$out" \
    "insertText: replaces the selected range and collapses the caret"
check "[sel] deleted there 0 0" "$out" \
    "deleteBackward removes the selected range"
check "[sel] clamped 5 0" "$out" \
    "setSelectedRange: clamps a range past the text length"

"$ROOT/tools/build_app.sh" "$ROOT/tests/textview_selection_visual_test.m" \
    "$T/textview_selection_visual_test" >/dev/null
out="$(IOSIM_TEST_PNG="$T/textview_selection.png" \
    DYLD_ROOT_PATH="$ROOT/runtime" "$RUN" \
    "$T/textview_selection_visual_test" 2>&1)"
check "[sel] range 6 5" "$out" \
    "a UITextView carries its selectedRange into the render pass"
check "[sel] png written" "$out" \
    "the selected UITextView frame is captured"
if out="$(python3 - "$ROOT/tools" "$T/textview_selection.png" <<'PY'
import sys
sys.path.insert(0, sys.argv[1])
import pngpixel
w, h, bpp, rows = pngpixel.load(sys.argv[2])
count = 0
for y in range(100 * 3, 260 * 3):
    for x in range(24 * 3, 344 * 3):
        c = pngpixel.px(rows, bpp, x, y)
        r, g, b = ((c >> 16) & 255), ((c >> 8) & 255), (c & 255)
        if abs(r - 0x33) < 25 and abs(g - 0x50) < 25 and abs(b - 0x7a) < 25:
            count += 1
if count < 500:
    raise SystemExit("selection highlight not visible: %d" % count)
print("ok   UITextView selection paints %d highlight pixels:" % count)
PY
)"; then
    echo "$out"
else
    echo "FAIL UITextView selection rendering"; echo "$out"
    fails=$((fails+1))
fi

"$ROOT/tools/build_app.sh" "$ROOT/tests/textview_drag_selection_test.m" \
    "$T/textview_drag_selection_test" >/dev/null
out="$(IOSIM_TEST_PNG="$T/textview_drag.png" \
    DYLD_ROOT_PATH="$ROOT/runtime" "$RUN" \
    "$T/textview_drag_selection_test" 2>&1)"
check "[drag] full 0 11" "$out" \
    "dragging a touch across the text selects the whole range"
check "[drag] partial 1" "$out" \
    "a second drag leaves a non-empty partial selection"
check "[drag] png written" "$out" \
    "the drag selection fixture captures a frame"
if out="$(python3 - "$ROOT/tools" "$T/textview_drag.png" <<'PY'
import sys
sys.path.insert(0, sys.argv[1])
import pngpixel
w, h, bpp, rows = pngpixel.load(sys.argv[2])
highlight = handles = 0
for y in range(100 * 3, 260 * 3):
    for x in range(24 * 3, 344 * 3):
        c = pngpixel.px(rows, bpp, x, y)
        r, g, b = ((c >> 16) & 255), ((c >> 8) & 255), (c & 255)
        if abs(r - 0x33) < 25 and abs(g - 0x50) < 25 and abs(b - 0x7a) < 25:
            highlight += 1
        if abs(r - 0x42) < 25 and abs(g - 0x6b) < 25 and abs(b - 0xf2) < 25:
            handles += 1
if highlight < 500:
    raise SystemExit("selection highlight not visible: %d" % highlight)
if handles < 400:
    raise SystemExit("selection handles not visible: %d" % handles)
print("ok   UITextView selection paints %d highlight and %d handle pixels:" %
      (highlight, handles))
PY
)"; then
    echo "$out"
else
    echo "FAIL UITextView drag selection"; echo "$out"
    fails=$((fails+1))
fi

"$ROOT/tools/build_app.sh" "$ROOT/tests/textview_handle_drag_test.m" \
    "$T/textview_handle_drag_test" >/dev/null
out="$(DYLD_ROOT_PATH="$ROOT/runtime" "$RUN" \
    "$T/textview_handle_drag_test" 2>&1)"
check "[handle] knob 1 1" "$out" \
    "the computed selection-handle position lands inside the text view"
check "[handle] end 1 1" "$out" \
    "dragging the end handle extends the selection within the text"
check "[handle] start 1" "$out" \
    "dragging the start handle moves the selection start"

rm -f "$T/textview_press.fifo"
mkfifo "$T/textview_press.fifo"
"$ROOT/tools/build_app.sh" "$ROOT/tests/textview_long_press_test.m" \
    "$T/textview_long_press_test" >/dev/null
out="$(IOSIM_EVENT_FIFO="$T/textview_press.fifo" \
    IOSIM_TEST_PNG="$T/textview_press.png" \
    DYLD_ROOT_PATH="$ROOT/runtime" "$RUN" \
    "$T/textview_long_press_test" 2>&1)"
check "[press] long 1 range 6 5" "$out" \
    "holding a touch selects the word under the finger after 0.5s"
check "[press] png written" "$out" \
    "the long-press fixture captures the selected frame"
if out="$(python3 - "$ROOT/tools" "$T/textview_press.png" <<'PY'
import sys
sys.path.insert(0, sys.argv[1])
import pngpixel
w, h, bpp, rows = pngpixel.load(sys.argv[2])
highlight = handles = 0
for y in range(100 * 3, 260 * 3):
    for x in range(24 * 3, 344 * 3):
        c = pngpixel.px(rows, bpp, x, y)
        r, g, b = ((c >> 16) & 255), ((c >> 8) & 255), (c & 255)
        if abs(r - 0x33) < 25 and abs(g - 0x50) < 25 and abs(b - 0x7a) < 25:
            highlight += 1
        if abs(r - 0x42) < 25 and abs(g - 0x6b) < 25 and abs(b - 0xf2) < 25:
            handles += 1
if highlight < 500:
    raise SystemExit("long-press selection highlight missing: %d" % highlight)
if handles < 400:
    raise SystemExit("long-press handles missing: %d" % handles)
print("ok   long press paints %d highlight and %d handle pixels:" %
      (highlight, handles))
PY
)"; then
    echo "$out"
else
    echo "FAIL UITextView long press"; echo "$out"; fails=$((fails+1))
fi

rm -f "$T/textview_menu.fifo"
mkfifo "$T/textview_menu.fifo"
"$ROOT/tools/build_app.sh" "$ROOT/tests/textview_edit_menu_test.m" \
    "$T/textview_edit_menu_test" >/dev/null
out="$(IOSIM_EVENT_FIFO="$T/textview_menu.fifo" \
    IOSIM_TEST_PNG="$T/textview_menu.png" \
    IOSIM_TEST_PNG2="$T/textview_menu_after.png" \
    DYLD_ROOT_PATH="$ROOT/runtime" "$RUN" \
    "$T/textview_edit_menu_test" 2>&1)"
check "[menu] visible 1" "$out" \
    "a long press shows the edit menu above the selected word"
check "[menu] pasteboard 1" "$out" \
    "tapping Copy places the selected word on the pasteboard"
check "[menu] hidden 1" "$out" \
    "the edit menu hides after the Copy tap"
check "[menu] png written" "$out" \
    "the edit-menu fixture captures both frames"
if out="$(python3 - "$ROOT/tools" "$T/textview_menu.png" \
    "$T/textview_menu_after.png" <<'MENUPNG'
import sys
sys.path.insert(0, sys.argv[1])
import pngpixel

def count(path):
    w, h, bpp, rows = pngpixel.load(path)
    panel = labels = 0
    for y in range(198, 312):
        for x in range(179, 615):
            c = pngpixel.px(rows, bpp, x, y)
            r, g, b = ((c >> 16) & 255), ((c >> 8) & 255), (c & 255)
            if abs(r - 0x2c) < 6 and abs(g - 0x2c) < 6 and abs(b - 0x2e) < 6:
                panel += 1
            if r > 230 and g > 230 and b > 230:
                labels += 1
    return panel, labels

shown = count(sys.argv[2])
after = count(sys.argv[3])
if shown[0] < 5000:
    raise SystemExit("edit menu panel missing: %d" % shown[0])
if shown[1] < 400:
    raise SystemExit("edit menu labels missing: %d" % shown[1])
if after[0] > 100:
    raise SystemExit("edit menu did not clear: %d" % after[0])
print("ok   edit menu paints %d panel and %d label pixels, clears after Copy" %
      (shown[0], shown[1]))
MENUPNG
)"; then
    echo "$out"
else
    echo "FAIL UITextView edit menu"; echo "$out"; fails=$((fails+1))
fi

rm -f "$T/bars.fifo"
mkfifo "$T/bars.fifo"
"$ROOT/tools/build_app.sh" "$ROOT/tests/bars_test.m" "$T/bars_test" >/dev/null
out="$(IOSIM_EVENT_FIFO="$T/bars.fifo" IOSIM_TEST_PNG="$T/bars.png" \
    DYLD_ROOT_PATH="$ROOT/runtime" "$RUN" "$T/bars_test" 2>&1)"
check "[bars] items 1 1" "$out" \
    "standalone navigation bar push and pop change the top item"
check "[bars] nav 1 tool 3" "$out" \
    "navigation and toolbar item taps reach their targets"
check "[bars] png written" "$out" \
    "the bars fixture captures the frame"
if out="$(python3 - "$ROOT/tools" "$T/bars.png" <<'BARSPNG'
import sys
sys.path.insert(0, sys.argv[1])
import pngpixel

w, h, bpp, rows = pngpixel.load(sys.argv[2])

def count(y0, y1):
    n = 0
    for y in range(y0, y1, 3):
        for x in range(0, w, 3):
            c = pngpixel.px(rows, bpp, x, y)
            r, g, b = ((c >> 16) & 255), ((c >> 8) & 255), (c & 255)
            if abs(r - 27) < 7 and abs(g - 28) < 7 and abs(b - 29) < 7:
                n += 1
    return n

nav = count(182, 310)
tool = count(2354, 2497)
if nav < 5000:
    raise SystemExit("navigation bar background missing: %d" % nav)
if tool < 5000:
    raise SystemExit("toolbar background missing: %d" % tool)
print("ok   bars paint %d nav and %d toolbar sampled background pixels" %
      (nav, tool))
BARSPNG
)"; then
    echo "$out"
else
    echo "FAIL UINavigationBar/UIToolbar"; echo "$out"; fails=$((fails+1))
fi

rm -f "$T/modal.fifo"
mkfifo "$T/modal.fifo"
"$ROOT/tools/build_app.sh" "$ROOT/tests/modal_animation_test.m" \
    "$T/modal_animation_test" >/dev/null
out="$(IOSIM_EVENT_FIFO="$T/modal.fifo" \
    IOSIM_TEST_PNG_MID1="$T/modal_mid1.png" \
    IOSIM_TEST_PNG_FULL="$T/modal_full.png" \
    IOSIM_TEST_PNG_MID2="$T/modal_mid2.png" \
    IOSIM_TEST_PNG_END="$T/modal_end.png" \
    DYLD_ROOT_PATH="$ROOT/runtime" "$RUN" \
    "$T/modal_animation_test" 2>&1)"
check "[modal] presented" "$out" \
    "presentViewController starts an animated page sheet"
check "[modal] dismissed" "$out" \
    "dismissViewControllerAnimated starts the slide-down"
check "[modal] png written" "$out" \
    "the modal fixture captures all four phases"
if out="$(python3 - "$ROOT/tools" "$T" <<'MODALPNG'
import sys
sys.path.insert(0, sys.argv[1])
import pngpixel

def green(path, y0, y1):
    w, h, bpp, rows = pngpixel.load(path)
    n = 0
    for y in range(y0 * 3, y1 * 3, 3):
        for x in range(0, w, 3):
            c = pngpixel.px(rows, bpp, x, y)
            r, g, b = ((c >> 16) & 255), ((c >> 8) & 255), (c & 255)
            if abs(r - 26) < 20 and abs(g - 204) < 25 and abs(b - 77) < 25:
                n += 1
    return n

root = sys.argv[2]
mid1 = root + "/modal_mid1.png"
full = root + "/modal_full.png"
mid2 = root + "/modal_mid2.png"
end = root + "/modal_end.png"
if green(mid1, 650, 850) < 3000:
    raise SystemExit("mid-present sheet not at the bottom")
if green(mid1, 50, 300) > 50:
    raise SystemExit("mid-present sheet covers the top")
if green(full, 50, 300) < 3000:
    raise SystemExit("presented sheet does not cover the top")
if green(mid2, 20, 140) > 50:
    raise SystemExit("mid-dismiss sheet still covers the top")
if green(mid2, 400, 500) < 3000:
    raise SystemExit("mid-dismiss sheet missing from the middle")
if green(end, 0, 874) > 100:
    raise SystemExit("sheet still visible after dismissal")
print("ok   modal sheet slides up, covers, slides down and clears")
MODALPNG
)"; then
    echo "$out"
else
    echo "FAIL modal presentation animation"; echo "$out"; fails=$((fails+1))
fi

rm -f "$T/zoom.fifo"
mkfifo "$T/zoom.fifo"
"$ROOT/tools/build_app.sh" "$ROOT/tests/zoom_pinch_test.m" \
    "$T/zoom_pinch_test" >/dev/null
out="$(IOSIM_EVENT_FIFO="$T/zoom.fifo" \
    IOSIM_TEST_PNG1="$T/zoom1.png" IOSIM_TEST_PNG2="$T/zoom2.png" \
    DYLD_ROOT_PATH="$ROOT/runtime" "$RUN" "$T/zoom_pinch_test" 2>&1)"
check "[zoom] programmatic 1 1" "$out" \
    "setZoomScale scales the delegate's zoom view"
check "[zoom] rect 1 1 1" "$out" \
    "zoomToRect fits the rectangle and centers it"
check "[zoom] pinch 2.00" "$out" \
    "an injected pinch drives UIPinchGestureRecognizer to scale 2"
check "[zoom] scroll 2.00" "$out" \
    "the scroll view follows the pinch with its own zoomScale"
check "[zoom] didzoom 1" "$out" \
    "scrollViewDidZoom reaches the delegate"
check "[zoom] rotation 90" "$out" \
    "injected rotate records drive UIRotationGestureRecognizer to 90 degrees"
check "[zoom] done 1 1" "$out" \
    "the pinch and rotation endpoints match their inputs"
check "[zoom] png written" "$out" \
    "the zoom fixture captures both frames"
if out="$(python3 - "$ROOT/tools" "$T/zoom1.png" "$T/zoom2.png" <<'ZOOMPNG'
import sys
sys.path.insert(0, sys.argv[1])
import pngpixel

def magenta(path):
    w, h, bpp, rows = pngpixel.load(path)
    n = 0
    for y in range(240 * 3, 360 * 3):
        for x in range(140 * 3, 260 * 3):
            c = pngpixel.px(rows, bpp, x, y)
            r, g, b = ((c >> 16) & 255), ((c >> 8) & 255), (c & 255)
            if abs(r - 230) < 25 and abs(g - 26) < 25 and abs(b - 153) < 25:
                n += 1
    return n

one = magenta(sys.argv[2])
two = magenta(sys.argv[3])
if one < 2500 or one > 5000:
    raise SystemExit("unzoomed marker unexpected: %d" % one)
if two < 8000:
    raise SystemExit("zoomed marker did not scale: %d" % two)
print("ok   zoomed marker grows from %d to %d pixels" % (one, two))
ZOOMPNG
)"; then
    echo "$out"
else
    echo "FAIL UIScrollView zoom/pinch"; echo "$out"; fails=$((fails+1))
fi

rm -f "$T/tx.fifo"
mkfifo "$T/tx.fifo"
"$ROOT/tools/build_app.sh" "$ROOT/tests/transform_animation_test.m" \
    "$T/transform_animation_test" >/dev/null
out="$(IOSIM_EVENT_FIFO="$T/tx.fifo" \
    IOSIM_TEST_PNG_MID="$T/tx_mid.png" \
    IOSIM_TEST_PNG_END="$T/tx_end.png" \
    DYLD_ROOT_PATH="$ROOT/runtime" "$RUN" \
    "$T/transform_animation_test" 2>&1)"
check "[tx] started" "$out" \
    "animateWithDuration starts a transform animation"
check "[tx] hit 1 1" "$out" \
    "hit-testing follows the animated transform's extent"
check "[tx] png written" "$out" \
    "the transform fixture captures both phases"
if out="$(python3 - "$ROOT/tools" "$T/tx_mid.png" "$T/tx_end.png" <<'TXPNG'
import sys
sys.path.insert(0, sys.argv[1])
import pngpixel

def loader(path):
    w, h, bpp, rows = pngpixel.load(path)
    def read(x, y):
        return pngpixel.px(rows, bpp, x * 3, y * 3)
    return read

def green(read, x, y):
    c = read(x, y)
    r, g, b = ((c >> 16) & 255), ((c >> 8) & 255), (c & 255)
    return abs(r - 26) < 25 and abs(g - 204) < 25 and abs(b - 77) < 25

mid = loader(sys.argv[2])
end = loader(sys.argv[3])
if not green(mid, 133, 220):
    raise SystemExit("scale animation did not begin")
if green(mid, 120, 220):
    raise SystemExit("scale snapped to its final value")
if green(mid, 150, 620):
    raise SystemExit("bar did not rotate away from its start")
if not green(mid, 229, 648):
    raise SystemExit("bar is not on the 45-degree diagonal at the midpoint")
if not green(end, 120, 220):
    raise SystemExit("scale did not reach 2x")
if green(end, 95, 220):
    raise SystemExit("scale exceeded 2x")
if green(end, 229, 648):
    raise SystemExit("bar did not finish rotating")
if green(end, 150, 620):
    raise SystemExit("bar is not vertical at the end")
print("ok   scaled square and rotating bar interpolate between captures")
TXPNG
)"; then
    echo "$out"
else
    echo "FAIL animated UIView transforms"; echo "$out"; fails=$((fails+1))
fi

rm -f "$T/nav.fifo"
mkfifo "$T/nav.fifo"
"$ROOT/tools/build_app.sh" "$ROOT/tests/nav_edge_pop_test.m" \
    "$T/nav_edge_pop_test" >/dev/null
out="$(IOSIM_EVENT_FIFO="$T/nav.fifo" \
    IOSIM_TEST_PNG_BASE="$T/nav_base.png" \
    IOSIM_TEST_PNG_MID="$T/nav_mid.png" \
    IOSIM_TEST_PNG_END="$T/nav_end.png" \
    IOSIM_TEST_PNG_CANCEL="$T/nav_cancel.png" \
    DYLD_ROOT_PATH="$ROOT/runtime" "$RUN" \
    "$T/nav_edge_pop_test" 2>&1)"
check "[nav] gesture 1" "$out" \
    "the navigation controller vends a screen-edge pop recognizer"
check "[nav] pushed" "$out" \
    "the fixture pushes the detail controller"
check "[nav] popped 1" "$out" \
    "a drag past halfway commits the interactive pop"
check "[nav] repushed" "$out" \
    "the fixture pushes a second detail controller"
check "[nav] cancel 1" "$out" \
    "a short drag released in place leaves the stack untouched"
check "[nav] png written" "$out" \
    "the nav fixture captures all four phases"
if out="$(python3 - "$ROOT/tools" "$T" <<'NEDGEPNG'
import sys
sys.path.insert(0, sys.argv[1])
import pngpixel

def loader(path):
    w, h, bpp, rows = pngpixel.load(path)
    def read(x, y):
        return pngpixel.px(rows, bpp, x * 3, y * 3)
    return read

def rgb(read, x, y):
    c = read(x, y)
    return ((c >> 16) & 255, (c >> 8) & 255, c & 255)

def green(c):
    return abs(c[0] - 26) < 25 and abs(c[1] - 204) < 25 and abs(c[2] - 77) < 25

def magenta(c):
    return abs(c[0] - 230) < 25 and abs(c[1] - 26) < 25 and abs(c[2] - 153) < 25

def dim_green(c):
    return c[1] > 100 and c[1] > c[0] + 60 and c[1] > c[2] + 60

root = sys.argv[2]
base = loader(root + "/nav_base.png")
mid = loader(root + "/nav_mid.png")
end = loader(root + "/nav_end.png")
cancel = loader(root + "/nav_cancel.png")
if not (magenta(rgb(base, 10, 437)) and magenta(rgb(base, 390, 437))):
    raise SystemExit("baseline does not show the pushed detail")
left = rgb(mid, 10, 437)
if magenta(left):
    raise SystemExit("mid-gesture detail still covers the left edge")
if not dim_green(left):
    raise SystemExit("incoming view missing or not dimmed: %r" % (left,))
if not magenta(rgb(mid, 390, 437)):
    raise SystemExit("detail is not tracking the finger")
boundary = -1
for x in range(0, 402):
    if magenta(rgb(mid, x, 437)):
        boundary = x
        break
if boundary < 80 or boundary > 330:
    raise SystemExit("revealed strip has unexpected width: %d" % boundary)
shadow = rgb(mid, boundary - 15, 437)
if shadow[1] > left[1] - 8:
    raise SystemExit("no edge shadow beside the detail: %r vs %r" %
                     (shadow, left))
if not (green(rgb(end, 10, 437)) and green(rgb(end, 390, 437))):
    raise SystemExit("committed pop did not restore the root view")
if not (magenta(rgb(cancel, 10, 437)) and magenta(rgb(cancel, 390, 437))):
    raise SystemExit("cancelled pop did not restore the detail")
print("ok   edge pan reveals, pops and cancels with a dim and shadow")
NEDGEPNG
)"; then
    echo "$out"
else
    echo "FAIL interactive navigation pop"; echo "$out"; fails=$((fails+1))
fi

rm -f "$T/share.fifo"
mkfifo "$T/share.fifo"
"$ROOT/tools/build_app.sh" "$ROOT/tests/activity_sheet_test.m" \
    "$T/activity_sheet_test" >/dev/null
out="$(IOSIM_EVENT_FIFO="$T/share.fifo" \
    IOSIM_TEST_PNG_MID="$T/share_mid.png" \
    IOSIM_TEST_PNG_FULL="$T/share_full.png" \
    IOSIM_TEST_PNG_COPYGONE="$T/share_copygone.png" \
    IOSIM_TEST_PNG_EMPTY="$T/share_empty.png" \
    IOSIM_TEST_PNG_CANCEL="$T/share_cancel.png" \
    DYLD_ROOT_PATH="$ROOT/runtime" "$RUN" \
    "$T/activity_sheet_test" 2>&1)"
check "[share] presented" "$out" "a share sheet presents over the app"
check "[share] done com.apple.UIKit.activity.CopyToPasteboard 1" "$out" \
    "the Copy row reports its activity type and completion"
check "[share] paste Hello share sheet" "$out" \
    "Copy places the shared string on the pasteboard"
check "[share] excluded" "$out" "a second sheet excludes the Copy activity"
check "[share] done (null) 0" "$out" \
    "cancelling reports a nil activity without completing"
check "[share] png written" "$out" "the share fixture captures every phase"
if out="$(python3 - "$ROOT/tools" "$T" <<'SHAREPNG'
import sys
sys.path.insert(0, sys.argv[1])
import pngpixel

def loader(path):
    w, h, bpp, rows = pngpixel.load(path)
    def read(x, y):
        return pngpixel.px(rows, bpp, x * 3, y * 3)
    return read

def rgb(read, x, y):
    c = read(x, y)
    return ((c >> 16) & 255, (c >> 8) & 255, c & 255)

def green(c):
    return abs(c[0] - 26) < 25 and abs(c[1] - 204) < 25 and abs(c[2] - 77) < 25

def dim_green(c):
    return c[1] > 100 and c[1] > c[0] + 60 and c[1] > c[2] + 60

def card(c):
    return c[0] < 70 and c[1] < 70 and c[2] < 80

def boundary(read):
    for y in range(400, 874):
        if card(rgb(read, 201, y)):
            return y
    return -1

root = sys.argv[2]
mid = loader(root + "/share_mid.png")
full = loader(root + "/share_full.png")
gone = loader(root + "/share_copygone.png")
empty = loader(root + "/share_empty.png")
cancel = loader(root + "/share_cancel.png")
if not dim_green(rgb(mid, 201, 450)):
    raise SystemExit("the parent is not dimmed during the slide")
if not card(rgb(mid, 201, 860)):
    raise SystemExit("the sheet is not sliding in from the bottom")
if not dim_green(rgb(full, 201, 450)):
    raise SystemExit("the settled sheet does not dim its parent")
b = boundary(full)
if b < 600 or b > 660:
    raise SystemExit("settled share sheet top has unexpected position: %d" % b)
if not card(rgb(full, 201, 760)):
    raise SystemExit("share sheet body is not drawn")
em = boundary(empty)
if em < 660 or em > 710:
    raise SystemExit("rowless share sheet has unexpected height: %d" % em)
if not (green(rgb(gone, 201, 450)) and green(rgb(gone, 201, 860))):
    raise SystemExit("copy did not dismiss the share sheet")
if not (green(rgb(cancel, 201, 450)) and green(rgb(cancel, 201, 860))):
    raise SystemExit("cancel did not dismiss the share sheet")
print("ok   share sheet slides, copies, excludes and cancels")
SHAREPNG
)"; then
    echo "$out"
else
    echo "FAIL UIActivityViewController share sheet"; echo "$out"; fails=$((fails+1))
fi

# ---------- UserNotifications.framework ----------
rm -rf "$T/un-shared"
mkdir -p "$T/un-shared"
rm -f "$T/un.fifo"
mkfifo "$T/un.fifo"
"$ROOT/tools/build_app.sh" "$ROOT/tests/notifications_test.m" \
    "$T/notifications_test" >/dev/null
out="$(IOSIM_EVENT_FIFO="$T/un.fifo" \
    IOSIM_TEST_PNG_FINAL="$T/un_final.png" \
    SIMULATOR_SHARED_RESOURCES_DIRECTORY="$T/un-shared" \
    IOSIM_BUNDLE_ID=com.iosim.notify \
    DYLD_ROOT_PATH="$ROOT/runtime" "$RUN" \
    "$T/notifications_test" 2>&1)"
check "[un] granted 1" "$out" \
    "requestAuthorization grants alert, sound and badge"
check "[un] status 2" "$out" "notification settings report authorized"
check "[un] added 1" "$out" "a time-interval request is accepted"
check "[un] pending 1 store 1" "$out" \
    "the request is pending and written for the system UI"
check "[un] willPresent lunch Lunch" "$out" \
    "a foreground request reaches the center delegate"
check "[un] after pending 0 store 0" "$out" \
    "a one-shot request leaves the pending list and the shared schedule"
check "[un] delivered title Lunch" "$out" \
    "the delivered notification carries its content"
check "[un] ticks 2" "$out" "a repeating request fires again"
check "[un] stopped pending 0" "$out" \
    "removing pending identifiers stops the repeat"
check "[un] stopped delivered 0 store 0" "$out" \
    "delivered notifications and the shared schedule are removed"
check "[un] png written" "$out" "the notification fixture captures the frame"
if [ -z "$(ls -A "$T/un-shared/Library/SpringBoard/notifications" \
        2>/dev/null)" ]; then
    echo "ok   no notification schedule files are left behind"
else
    echo "FAIL notification schedule cleanup"; fails=$((fails+1))
fi
if out="$(python3 - "$ROOT/tools" "$T" <<'UNPNG'
import sys
sys.path.insert(0, sys.argv[1])
import pngpixel
root = sys.argv[2]
w, h, bpp, rows = pngpixel.load(root + "/un_final.png")
def rgb(x, y):
    c = pngpixel.px(rows, bpp, x * 3, y * 3)
    return ((c >> 16) & 255, (c >> 8) & 255, c & 255)
c = rgb(201, 300)
if not (abs(c[0] - 89) < 12 and abs(c[1] - 51) < 12 and
        abs(c[2] - 140) < 12):
    raise SystemExit("the notification fixture frame is missing")
print("ok   the notification fixture draws its frame")
UNPNG
)"; then
    echo "$out"
else
    echo "FAIL UserNotifications"; echo "$out"; fails=$((fails+1))
fi

rm -f "$T/ctx.fifo"
mkfifo "$T/ctx.fifo"
"$ROOT/tools/build_app.sh" "$ROOT/tests/context_menu_test.m" \
    "$T/context_menu_test" >/dev/null
out="$(IOSIM_EVENT_FIFO="$T/ctx.fifo" \
    IOSIM_TEST_PNG_MENU="$T/ctx_menu.png" \
    IOSIM_TEST_PNG_AFTER="$T/ctx_after.png" \
    IOSIM_TEST_PNG_MENU2="$T/ctx_menu2.png" \
    IOSIM_TEST_PNG_END="$T/ctx_end.png" \
    IOSIM_TEST_PNG_GEN="$T/ctx_gen.png" \
    IOSIM_TEST_PNG_GENEND="$T/ctx_genend.png" \
    IOSIM_TEST_PNG_COL="$T/ctx_col.png" \
    IOSIM_TEST_PNG_COLEND="$T/ctx_colend.png" \
    IOSIM_TEST_PNG_SUB="$T/ctx_sub.png" \
    IOSIM_TEST_PNG_SUB2="$T/ctx_sub2.png" \
    IOSIM_TEST_PNG_SUB3="$T/ctx_sub3.png" \
    IOSIM_TEST_PNG_SUBEND="$T/ctx_subend.png" \
    DYLD_ROOT_PATH="$ROOT/runtime" "$RUN" \
    "$T/context_menu_test" 2>&1)"
check "[menu] config 1" "$out" \
    "a long press asks the table delegate for a context menu"
check "[menu] favorite 1" "$out" \
    "tapping a context menu action runs its handler"
check "[menu] config 2" "$out" \
    "a second row provides its own configuration"
check "[menu] config generic" "$out" \
    "a UIContextMenuInteraction on a plain view provides a menu"
check "[menu] ping" "$out" \
    "the generic menu action runs"
check "[menu] config item 0" "$out" \
    "a collection item provides a context menu configuration"
check "[menu] tag" "$out" "the collection menu action runs"
check "[menu] email" "$out" \
    "a submenu action runs after navigating into its menu"
check "[menu] png written" "$out" "the context menu fixture captures every phase"
if out="$(python3 - "$ROOT/tools" "$T" <<'CTXPNG'
import sys
sys.path.insert(0, sys.argv[1])
import pngpixel

def loader(path):
    w, h, bpp, rows = pngpixel.load(path)
    def read(x, y):
        return pngpixel.px(rows, bpp, x * 3, y * 3)
    return read

def rgb(read, x, y):
    c = read(x, y)
    return ((c >> 16) & 255, (c >> 8) & 255, c & 255)

def blue(c):
    return c[2] > 60 and c[2] > c[0] + 30 and c[1] < 80

def purple(c):
    return c[0] > 60 and c[2] > 90 and c[1] < 70

def orange(c):
    return c[0] > 170 and 65 < c[1] < 150 and c[2] < 80

def green(c):
    return abs(c[0] - 26) < 25 and abs(c[1] - 204) < 25 and abs(c[2] - 77) < 25

def dim_green(c):
    return c[1] > 120 and c[1] < 190 and c[1] > c[0] + 80 and c[1] > c[2] + 80

def card(c):
    return c[0] < 60 and c[1] < 60 and c[2] < 75

def cyan(c):
    return abs(c[0] - 26) < 25 and abs(c[1] - 153) < 30 and abs(c[2] - 179) < 30

def light(c):
    return c[0] > 110 and c[1] > 110 and c[2] > 110

def any_light(read, x0, y0, x1, y1):
    for yy in range(y0, y1):
        for xx in range(x0, x1):
            if light(rgb(read, xx, yy)):
                return True
    return False

root = sys.argv[2]
menu = loader(root + "/ctx_menu.png")
after = loader(root + "/ctx_after.png")
menu2 = loader(root + "/ctx_menu2.png")
end = loader(root + "/ctx_end.png")
gen = loader(root + "/ctx_gen.png")
genend = loader(root + "/ctx_genend.png")
col = loader(root + "/ctx_col.png")
colend = loader(root + "/ctx_colend.png")
sub = loader(root + "/ctx_sub.png")
sub2 = loader(root + "/ctx_sub2.png")
sub3 = loader(root + "/ctx_sub3.png")
subend = loader(root + "/ctx_subend.png")
if not blue(rgb(menu, 201, 90)):
    raise SystemExit("the lifted row preview is missing")
if not card(rgb(menu, 201, 150)):
    raise SystemExit("the context menu card is not drawn under the preview")
if not dim_green(rgb(menu, 201, 300)):
    raise SystemExit("the backdrop is not blurred and dimmed")
edge = rgb(menu, 201, 590)
if not (edge[1] < 150 and edge[1] > 70):
    raise SystemExit("the backdrop has no blurred green-to-collection edge")
if not (blue(rgb(after, 201, 66)) and green(rgb(after, 201, 300))):
    raise SystemExit("the table is not restored after the action")
if not purple(rgb(menu2, 201, 90)):
    raise SystemExit("the second lifted row preview has the wrong cell")
if not card(rgb(menu2, 201, 150)):
    raise SystemExit("the second menu card is missing")
if not (purple(rgb(end, 201, 90)) and green(rgb(end, 201, 300))):
    raise SystemExit("the outside tap did not dismiss the menu")
if not orange(rgb(gen, 201, 440)):
    raise SystemExit("the generic view preview is not a snapshot")
if not card(rgb(gen, 201, 510)):
    raise SystemExit("the generic menu card is missing")
if not dim_green(rgb(gen, 10, 300)):
    raise SystemExit("the generic menu backdrop is not blurred")
if not (orange(rgb(genend, 90, 440)) and green(rgb(genend, 10, 300))):
    raise SystemExit("the generic view was not restored after Ping")
if not green(rgb(genend, 201, 510)):
    raise SystemExit("the generic menu card did not dismiss")
if not cyan(rgb(col, 201, 670)):
    raise SystemExit("the collection item preview is missing")
if not card(rgb(col, 201, 760)):
    raise SystemExit("the collection menu card is missing")
if not cyan(rgb(colend, 70, 670)):
    raise SystemExit("the collection item was not restored")
if not (green(rgb(colend, 10, 550)) and
        rgb(colend, 201, 760)[0] < 25 and rgb(colend, 201, 760)[1] < 25):
    raise SystemExit("the collection menu did not dismiss")
if not card(rgb(sub, 201, 567)):
    raise SystemExit("the submenu row is missing from the root menu")
if not any_light(sub, 286, 552, 320, 582):
    raise SystemExit("the submenu row has no chevron")
if not any_light(sub2, 90, 596, 280, 632):
    raise SystemExit("the submenu page does not show its actions")
if not any_light(sub2, 86, 506, 110, 534):
    raise SystemExit("the submenu page has no back chevron")
if any_light(sub, 90, 596, 280, 632):
    raise SystemExit("the root menu grew into the submenu page layout")
if not any_light(sub3, 286, 552, 320, 582):
    raise SystemExit("going back did not restore the root menu")
if not (green(rgb(subend, 10, 300)) and orange(rgb(subend, 90, 440))):
    raise SystemExit("the submenu action did not dismiss the menu")
print("ok   context menus lift rows, items and views, blur, run and dismiss")
print("ok   submenu rows open a page and the back row returns")
CTXPNG
)"; then
    echo "$out"
else
    echo "FAIL context menus"; echo "$out"; fails=$((fails+1))
fi

# ---------- UIAlertController action sheets ----------
rm -f "$T/alert.fifo"
mkfifo "$T/alert.fifo"
"$ROOT/tools/build_app.sh" "$ROOT/tests/alert_sheet_test.m" \
    "$T/alert_sheet_test" >/dev/null
out="$(IOSIM_EVENT_FIFO="$T/alert.fifo" \
    IOSIM_TEST_PNG_SHEET="$T/alert_sheet.png" \
    IOSIM_TEST_PNG_RESTORED="$T/alert_restored.png" \
    DYLD_ROOT_PATH="$ROOT/runtime" "$RUN" "$T/alert_sheet_test" 2>&1)"
check "[sheet] delete 1" "$out" \
    "an action sheet runs its destructive row"
check "[alert] three" "$out" \
    "the third stacked alert row runs its action"
check "[alert] done" "$out" \
    "the alert sheet fixture completes its phases"
if out="$(python3 - "$ROOT/tools" "$T" <<'SHEETPNG'
import sys
sys.path.insert(0, sys.argv[1])
import pngpixel
root = sys.argv[2]

def loader(path):
    w, h, bpp, rows = pngpixel.load(path)
    def read(x, y):
        return pngpixel.px(rows, bpp, x * 3, y * 3)
    return read

def rgb(read, x, y):
    c = read(x, y)
    return ((c >> 16) & 255, (c >> 8) & 255, c & 255)

sheet = loader(root + "/alert_sheet.png")
restored = loader(root + "/alert_restored.png")
r, g, b = rgb(sheet, 380, 640)
if not (r < 60 and g < 60 and b > 25 and b < 85):
    raise SystemExit("the action sheet group card is missing: %02x%02x%02x" % (r, g, b))
r, g, b = rgb(sheet, 60, 720)
if not (45 < r < 85 and 45 < g < 85 and 45 < b < 95):
    raise SystemExit("the share row is missing: %02x%02x%02x" % (r, g, b))
r, g, b = rgb(sheet, 201, 813)
if not (r < 60 and 70 < g < 150 and b < 95):
    raise SystemExit("the cancel card is not separated: %02x%02x%02x" % (r, g, b))
r, g, b = rgb(sheet, 60, 840)
if not (45 < r < 85 and 45 < g < 85 and 45 < b < 95):
    raise SystemExit("the cancel action card is missing: %02x%02x%02x" % (r, g, b))
r, g, b = rgb(restored, 201, 300)
if not (r < 80 and g > 170 and b < 130):
    raise SystemExit("the sheet did not dismiss: %02x%02x%02x" % (r, g, b))
print("ok   action sheets anchor at the bottom and separate cancel")
SHEETPNG
)"; then
    echo "$out"
else
    echo "FAIL UIAlertController action sheets"; echo "$out"; fails=$((fails+1))
fi

# ---------- system notifications: banners and Notification Center ----------
# The device sections above shut their phone down; notifications need a live
# SpringBoard, so boot a fresh phone for this block.
UDID="$("$ROOT/tools/iosimctl" create "Notify iPhone" com.iosim.SimDeviceType.iPhone-18-Pro)"
"$ROOT/tools/iosimctl" boot "$UDID" >/dev/null
SBLOG="$IOSIM_HOME/Devices/$UDID/logs/springboard.log"
sleep 0.6
"$ROOT/tools/build_app.sh" "$ROOT/tests/notification_app_test.m" \
    "$T/NotifyApp" >/dev/null
mkdir -p "$T/NotifyApp.app"
cp "$T/NotifyApp" "$T/NotifyApp.app/NotifyApp"
python3 - "$T/NotifyApp.app/Info.plist" <<'PY'
import plistlib, sys
with open(sys.argv[1], "wb") as f:
    plistlib.dump({
        "CFBundleIdentifier": "com.iosim.notifyapp",
        "CFBundleExecutable": "NotifyApp",
        "CFBundleName": "Notify",
        "CFBundlePackageType": "APPL",
        "CFBundleVersion": "1",
        "CFBundleShortVersionString": "1.0",
    }, f)
PY
"$ROOT/tools/iosimctl" install "$UDID" "$T/NotifyApp.app" >/dev/null
sleep 0.6
"$ROOT/tools/iosimctl" ui "$UDID" tap 201 718.5 >/dev/null
if wait_log "[SpringBoard] search opened"; then
    echo "ok   Spotlight opens for the notification fixture"
else
    echo "FAIL notification search open"; fails=$((fails+1))
fi
for c in n o t i f y; do
    "$ROOT/tools/iosimctl" ui "$UDID" key "$c" >/dev/null
done
if wait_log "[SpringBoard] search results 1"; then
    echo "ok   the notification app is found in Spotlight"
else
    echo "FAIL notification search"; fails=$((fails+1))
fi
"$ROOT/tools/iosimctl" ui "$UDID" tap 200 270 >/dev/null
if wait_log "[notifyapp] scheduled first 1"; then
    echo "ok   the app schedules a request through UserNotifications"
else
    echo "FAIL notification scheduling"; fails=$((fails+1))
fi
sleep 0.4
"$ROOT/tools/iosimctl" ui "$UDID" home >/dev/null
if wait_log "[SpringBoard] notification banner Lunch"; then
    echo "ok   a due request appears as a system banner"
else
    echo "FAIL notification banner"; fails=$((fails+1))
fi
sleep 0.6
"$ROOT/tools/iosimctl" io "$UDID" screenshot "$T/nbanner.png" >/dev/null
if out="$(python3 - "$ROOT/tools" "$T" <<'NBANPNG'
import sys
sys.path.insert(0, sys.argv[1])
import pngpixel
root = sys.argv[2]
w, h, bpp, rows = pngpixel.load(root + "/nbanner.png")
def rgb(x, y):
    c = pngpixel.px(rows, bpp, x * 3, y * 3)
    return ((c >> 16) & 255, (c >> 8) & 255, c & 255)
card = rgb(201, 100)
if not (abs(card[0] - 53) < 16 and abs(card[1] - 53) < 16 and
        abs(card[2] - 62) < 16):
    raise SystemExit("banner card not drawn: %06x" % (card[0] << 16 |
                     card[1] << 8 | card[2]))
icon = rgb(46, 84)
if not (icon[0] > 200 and icon[1] > 200 and icon[2] > 200):
    raise SystemExit("banner icon not drawn: %06x" % (icon[0] << 16 |
                     icon[1] << 8 | icon[2]))
red = 0
for y in range(180, 208):
    for x in range(352, 384):
        c = rgb(x, y)
        if c[0] > 180 and c[1] < 110 and c[2] < 110:
            red += 1
if red < 80:
    raise SystemExit("icon badge not drawn on the home icon")
outside = rgb(201, 300)
if (abs(outside[0] - card[0]) < 12 and abs(outside[1] - card[1]) < 12 and
        abs(outside[2] - card[2]) < 12):
    raise SystemExit("banner fills the whole screen")
print("ok   the banner slides in with its app icon and card")
NBANPNG
)"; then
    echo "$out"
else
    echo "FAIL notification banner rendering"; echo "$out"; fails=$((fails+1))
fi
"$ROOT/tools/iosimctl" ui "$UDID" tap 201 100 >/dev/null
if wait_log "[SpringBoard] notification opened Lunch"; then
    echo "ok   tapping the banner opens its notification"
else
    echo "FAIL notification banner tap"; fails=$((fails+1))
fi
if wait_log "[notifyapp] didReceive first Lunch"; then
    echo "ok   the resumed app receives the tapped response"
else
    echo "FAIL notification response"; fails=$((fails+1))
fi
if wait_log "[notifyapp] scheduled second 1"; then
    echo "ok   the response delegate schedules a second request"
else
    echo "FAIL notification rescheduling"; fails=$((fails+1))
fi
sleep 0.5
"$ROOT/tools/iosimctl" ui "$UDID" home >/dev/null
if wait_log "[SpringBoard] notification banner Meeting"; then
    echo "ok   a background request banners after the app is suspended"
else
    echo "FAIL background notification banner"; fails=$((fails+1))
fi
sleep 0.6
"$ROOT/tools/iosimctl" io "$UDID" screenshot "$T/nbadgeoff.png" >/dev/null
if out="$(python3 - "$ROOT/tools" "$T" <<'NBADGEOFF'
import sys
sys.path.insert(0, sys.argv[1])
import pngpixel
root = sys.argv[2]
w, h, bpp, rows = pngpixel.load(root + "/nbadgeoff.png")
def rgb(x, y):
    c = pngpixel.px(rows, bpp, x * 3, y * 3)
    return ((c >> 16) & 255, (c >> 8) & 255, c & 255)
red = 0
for y in range(180, 208):
    for x in range(352, 384):
        c = rgb(x, y)
        if c[0] > 180 and c[1] < 110 and c[2] < 110:
            red += 1
if red > 20:
    raise SystemExit("the icon badge was not cleared by the response")
print("ok   the response clears the icon badge")
NBADGEOFF
)"; then
    echo "$out"
else
    echo "FAIL icon badge clearing"; echo "$out"; fails=$((fails+1))
fi
"$ROOT/tools/iosimctl" ui "$UDID" swipe 201 120 201 30 0.2 >/dev/null
if wait_log "[SpringBoard] notification banner dismissed"; then
    echo "ok   swiping the banner up dismisses it"
else
    echo "FAIL notification banner swipe"; fails=$((fails+1))
fi
"$ROOT/tools/iosimctl" ui "$UDID" swipe 120 30 120 500 0.3 >/dev/null
if wait_log "[SpringBoard] notification center opened"; then
    echo "ok   a top-edge drag opens Notification Center"
else
    echo "FAIL notification center open"; fails=$((fails+1))
fi
sleep 0.5
"$ROOT/tools/iosimctl" io "$UDID" screenshot "$T/ncenter.png" >/dev/null
if out="$(python3 - "$ROOT/tools" "$T" <<'NCPNG'
import sys
sys.path.insert(0, sys.argv[1])
import pngpixel
root = sys.argv[2]
w, h, bpp, rows = pngpixel.load(root + "/ncenter.png")
def rgb(x, y):
    c = pngpixel.px(rows, bpp, x * 3, y * 3)
    return ((c >> 16) & 255, (c >> 8) & 255, c & 255)
card = rgb(201, 240)
if not (abs(card[0] - 53) < 18 and abs(card[1] - 53) < 18 and
        abs(card[2] - 62) < 18):
    raise SystemExit("delivered notification card not drawn: %06x" %
                     (card[0] << 16 | card[1] << 8 | card[2]))
white = 0
for y in range(122, 190, 4):
    for x in range(24, 200, 4):
        c = rgb(x, y)
        if c[0] > 230 and c[1] > 230 and c[2] > 230:
            white += 1
if white < 3:
    raise SystemExit("Notification Center clock not drawn")
print("ok   Notification Center draws the clock and the delivered card")
NCPNG
)"; then
    echo "$out"
else
    echo "FAIL notification center rendering"; echo "$out"
    fails=$((fails+1))
fi
"$ROOT/tools/iosimctl" ui "$UDID" tap 201 240 >/dev/null
if wait_log "[SpringBoard] notification opened Meeting"; then
    echo "ok   tapping the Notification Center card opens it"
else
    echo "FAIL notification center tap"; fails=$((fails+1))
fi
if wait_log "[notifyapp] didReceive second Meeting"; then
    echo "ok   the app receives the Notification Center response"
else
    echo "FAIL notification center response"; fails=$((fails+1))
fi
"$ROOT/tools/iosimctl" ui "$UDID" home >/dev/null
sleep 0.4

# ---------- notification actions and the lock screen ----------
# Start a clean log so the second Spotlight search and the action titles
# cannot match lines left by the banner block above.
: > "$SBLOG"
"$ROOT/tools/build_app.sh" "$ROOT/tests/notification_actions_test.m" \
    "$T/ActionsApp" >/dev/null
mkdir -p "$T/ActionsApp.app"
cp "$T/ActionsApp" "$T/ActionsApp.app/ActionsApp"
python3 - "$T/ActionsApp.app/Info.plist" <<'PY'
import plistlib, sys
with open(sys.argv[1], "wb") as f:
    plistlib.dump({
        "CFBundleIdentifier": "com.iosim.notifyactions",
        "CFBundleExecutable": "ActionsApp",
        "CFBundleName": "Actions",
        "CFBundlePackageType": "APPL",
        "CFBundleVersion": "1",
        "CFBundleShortVersionString": "1.0",
    }, f)
PY
"$ROOT/tools/iosimctl" install "$UDID" "$T/ActionsApp.app" >/dev/null
sleep 0.6
"$ROOT/tools/iosimctl" ui "$UDID" tap 201 718.5 >/dev/null
if wait_log "[SpringBoard] search opened"; then
    echo "ok   Spotlight opens for the action fixture"
else
    echo "FAIL action search open"; fails=$((fails+1))
fi
for c in a c t i o n s; do
    "$ROOT/tools/iosimctl" ui "$UDID" key "$c" >/dev/null
done
if wait_log "[SpringBoard] search results 1"; then
    echo "ok   the action fixture is found in Spotlight"
else
    echo "FAIL action search"; fails=$((fails+1))
fi
"$ROOT/tools/iosimctl" ui "$UDID" tap 200 270 >/dev/null
if wait_log "[actions] scheduled actionable 1"; then
    echo "ok   the app registers a category and schedules a request"
else
    echo "FAIL action scheduling"; fails=$((fails+1))
fi
sleep 0.4
"$ROOT/tools/iosimctl" ui "$UDID" home >/dev/null
if wait_log "[SpringBoard] notification banner Dinner"; then
    echo "ok   the categorized request banners"
else
    echo "FAIL action banner"; fails=$((fails+1))
fi
sleep 0.6
"$ROOT/tools/iosimctl" ui "$UDID" down 201 100 >/dev/null
sleep 0.6
"$ROOT/tools/iosimctl" ui "$UDID" up 201 100 >/dev/null
if wait_log "[SpringBoard] notification actions Dinner"; then
    echo "ok   a long press expands the banner actions"
else
    echo "FAIL action expansion"; fails=$((fails+1))
fi
sleep 0.3
"$ROOT/tools/iosimctl" io "$UDID" screenshot "$T/nactions.png" >/dev/null
if out="$(python3 - "$ROOT/tools" "$T" <<'NABANPNG'
import sys
sys.path.insert(0, sys.argv[1])
import pngpixel
root = sys.argv[2]
w, h, bpp, rows = pngpixel.load(root + "/nactions.png")
def rgb(x, y):
    c = pngpixel.px(rows, bpp, x * 3, y * 3)
    return ((c >> 16) & 255, (c >> 8) & 255, c & 255)
card = rgb(201, 160)
if not (abs(card[0] - 53) < 16 and abs(card[1] - 53) < 16 and
        abs(card[2] - 62) < 16):
    raise SystemExit("the expanded action area is missing: %06x" %
                     (card[0] << 16 | card[1] << 8 | card[2]))
blue = red = 0
for y in range(152, 238, 2):
    for x in range(80, 320, 2):
        c = rgb(x, y)
        if c[2] > 150 and c[0] < 90 and c[1] < 170:
            blue += 1
        if c[0] > 180 and c[1] < 110 and c[2] < 110:
            red += 1
if blue < 30 or red < 30:
    raise SystemExit("the action titles are not drawn (blue %d, red %d)" %
                     (blue, red))
print("ok   the expanded banner draws the action rows")
NABANPNG
)"; then
    echo "$out"
else
    echo "FAIL action rows"; echo "$out"; fails=$((fails+1))
fi
"$ROOT/tools/iosimctl" ui "$UDID" tap 201 172 >/dev/null
if wait_log "[SpringBoard] notification action snooze (Dinner)"; then
    echo "ok   tapping an action row runs that action"
else
    echo "FAIL action tap"; fails=$((fails+1))
fi
if wait_log "[actions] didReceive actionable Dinner action=snooze"; then
    echo "ok   the app receives the chosen action identifier"
else
    echo "FAIL action response"; fails=$((fails+1))
fi
if wait_log "[actions] scheduled actionable2 1"; then
    echo "ok   the action response schedules the next request"
else
    echo "FAIL action rescheduling"; fails=$((fails+1))
fi
sleep 0.3
"$ROOT/tools/iosimctl" ui "$UDID" home >/dev/null
if wait_log "[SpringBoard] notification banner Dinner 2"; then
    echo "ok   the next categorized request banners"
else
    echo "FAIL second action banner"; fails=$((fails+1))
fi
sleep 0.6
"$ROOT/tools/iosimctl" ui "$UDID" swipe 201 120 201 30 0.2 >/dev/null
if wait_log "[SpringBoard] notification banner dismissed"; then
    echo "ok   the second action banner is dismissed"
else
    echo "FAIL second action dismiss"; fails=$((fails+1))
fi
"$ROOT/tools/iosimctl" ui "$UDID" swipe 120 30 120 500 0.3 >/dev/null
if wait_log "[SpringBoard] notification center opened"; then
    echo "ok   Notification Center opens over the action card"
else
    echo "FAIL action center open"; fails=$((fails+1))
fi
sleep 0.5
"$ROOT/tools/iosimctl" ui "$UDID" down 201 240 >/dev/null
sleep 0.6
"$ROOT/tools/iosimctl" ui "$UDID" up 201 240 >/dev/null
if wait_log "[SpringBoard] notification actions Dinner 2"; then
    echo "ok   a long press expands the Notification Center card"
else
    echo "FAIL center action expansion"; fails=$((fails+1))
fi
sleep 0.3
"$ROOT/tools/iosimctl" io "$UDID" screenshot "$T/ncactions.png" >/dev/null
if out="$(python3 - "$ROOT/tools" "$T" <<'NCAPNG'
import sys
sys.path.insert(0, sys.argv[1])
import pngpixel
root = sys.argv[2]
w, h, bpp, rows = pngpixel.load(root + "/ncactions.png")
def rgb(x, y):
    c = pngpixel.px(rows, bpp, x * 3, y * 3)
    return ((c >> 16) & 255, (c >> 8) & 255, c & 255)
sheet = rgb(201, 310)
if not (abs(sheet[0] - 53) < 18 and abs(sheet[1] - 53) < 18 and
        abs(sheet[2] - 62) < 18):
    raise SystemExit("the action sheet is missing: %06x" %
                     (sheet[0] << 16 | sheet[1] << 8 | sheet[2]))
blue = red = 0
for y in range(294, 378, 2):
    for x in range(80, 320, 2):
        c = rgb(x, y)
        if c[2] > 150 and c[0] < 90 and c[1] < 170:
            blue += 1
        if c[0] > 180 and c[1] < 110 and c[2] < 110:
            red += 1
if blue < 30 or red < 30:
    raise SystemExit("the sheet titles are not drawn (blue %d, red %d)" %
                     (blue, red))
print("ok   the Notification Center action sheet draws both actions")
NCAPNG
)"; then
    echo "$out"
else
    echo "FAIL center action sheet"; echo "$out"; fails=$((fails+1))
fi
"$ROOT/tools/iosimctl" ui "$UDID" tap 201 358 >/dev/null
if wait_log "[SpringBoard] notification action delete (Dinner 2)"; then
    echo "ok   tapping the destructive row runs it"
else
    echo "FAIL center action tap"; fails=$((fails+1))
fi
if wait_log "[actions] didReceive actionable2 Dinner 2 action=delete"; then
    echo "ok   the app receives the destructive action identifier"
else
    echo "FAIL center action response"; fails=$((fails+1))
fi
"$ROOT/tools/iosimctl" ui "$UDID" home >/dev/null
sleep 0.6

# A delivered notification left on the lock screen is tapped to unlock and
# open the app, exercising the same response handoff from the lock UI.
python3 - "$IOSIM_HOME/Devices/$UDID/data/Library/SpringBoard/notifications" <<'PY'
import os, sys, time
directory = sys.argv[1]
os.makedirs(directory, exist_ok=True)
fire = time.time() + 0.8
with open(os.path.join(directory, "locked.notif"), "w") as f:
    f.write("bundle=com.iosim.notifyapp\nid=locked\nfire=%.6f\n"
            "repeats=0\ninterval=0\ntitle=Locked\nsubtitle=\n"
            "body=Tap to open\ncategory=\nbadge=\n" % fire)
PY
if wait_log "[SpringBoard] notification banner Locked"; then
    echo "ok   the injected request banners before locking"
else
    echo "FAIL lock banner"; fails=$((fails+1))
fi
sleep 0.6
"$ROOT/tools/iosimctl" ui "$UDID" swipe 201 120 201 30 0.2 >/dev/null
sleep 0.4
"$ROOT/tools/iosimctl" ui "$UDID" lock >/dev/null
if wait_log "[SpringBoard] locked"; then
    echo "ok   the lock screen shows the delivered notification"
else
    echo "FAIL lock screen"; fails=$((fails+1))
fi
sleep 0.5
"$ROOT/tools/iosimctl" io "$UDID" screenshot "$T/nlock.png" >/dev/null
if out="$(python3 - "$ROOT/tools" "$T" <<'NLOCKPNG'
import sys
sys.path.insert(0, sys.argv[1])
import pngpixel
root = sys.argv[2]
w, h, bpp, rows = pngpixel.load(root + "/nlock.png")
def rgb(x, y):
    c = pngpixel.px(rows, bpp, x * 3, y * 3)
    return ((c >> 16) & 255, (c >> 8) & 255, c & 255)
card = rgb(201, 500)
if not (abs(card[0] - 53) < 18 and abs(card[1] - 53) < 18 and
        abs(card[2] - 62) < 18):
    raise SystemExit("the lock screen card is missing: %06x" %
                     (card[0] << 16 | card[1] << 8 | card[2]))
white = 0
for y in range(510, 530, 2):
    for x in range(80, 320, 2):
        c = rgb(x, y)
        if c[0] > 200 and c[1] > 200 and c[2] > 200:
            white += 1
if white < 10:
    raise SystemExit("the lock screen card title is not drawn")
print("ok   the lock screen draws the delivered card")
NLOCKPNG
)"; then
    echo "$out"
else
    echo "FAIL lock card"; echo "$out"; fails=$((fails+1))
fi
"$ROOT/tools/iosimctl" ui "$UDID" tap 201 500 >/dev/null
if wait_log "[SpringBoard] unlocked"; then
    echo "ok   tapping the lock card unlocks the phone"
else
    echo "FAIL lock unlock"; fails=$((fails+1))
fi
if wait_log "[SpringBoard] notification opened Locked"; then
    echo "ok   the lock card opens its notification"
else
    echo "FAIL lock open"; fails=$((fails+1))
fi
if wait_log "[notifyapp] didReceive locked Locked"; then
    echo "ok   the app receives the lock screen response"
else
    echo "FAIL lock response"; fails=$((fails+1))
fi

# ---------- appearance: UITraitCollection and dynamic system colors ----------
UDID="$("$ROOT/tools/iosimctl" create "Appearance iPhone" com.iosim.SimDeviceType.iPhone-18-Pro)"
"$ROOT/tools/iosimctl" boot "$UDID" >/dev/null
SBLOG="$IOSIM_HOME/Devices/$UDID/logs/springboard.log"
sleep 0.6
"$ROOT/tools/build_app.sh" "$ROOT/tests/appearance_test.m" \
    "$T/AppearanceApp" >/dev/null
mkdir -p "$T/AppearanceApp.app"
cp "$T/AppearanceApp" "$T/AppearanceApp.app/AppearanceApp"
python3 - "$T/AppearanceApp.app/Info.plist" <<'PY'
import plistlib, sys
with open(sys.argv[1], "wb") as f:
    plistlib.dump({
        "CFBundleIdentifier": "com.iosim.appearance",
        "CFBundleExecutable": "AppearanceApp",
        "CFBundleName": "Appearance",
        "CFBundlePackageType": "APPL",
        "CFBundleVersion": "1",
        "CFBundleShortVersionString": "1.0",
    }, f)
PY
"$ROOT/tools/iosimctl" install "$UDID" "$T/AppearanceApp.app" >/dev/null
sleep 0.6
"$ROOT/tools/iosimctl" ui "$UDID" tap 201 718.5 >/dev/null
if wait_log "[SpringBoard] search opened"; then
    echo "ok   Spotlight opens for the appearance fixture"
else
    echo "FAIL appearance search open"; fails=$((fails+1))
fi
for c in a p p e a r a n c e; do
    "$ROOT/tools/iosimctl" ui "$UDID" key "$c" >/dev/null
done
if wait_log "[SpringBoard] search results 1"; then
    echo "ok   the appearance fixture is found in Spotlight"
else
    echo "FAIL appearance search"; fails=$((fails+1))
fi
"$ROOT/tools/iosimctl" ui "$UDID" tap 200 270 >/dev/null
if wait_log "[appearance] initial 1"; then
    echo "ok   a new app starts in light appearance"
else
    echo "FAIL appearance initial"; fails=$((fails+1))
fi
sleep 0.4
"$ROOT/tools/iosimctl" io "$UDID" screenshot "$T/aplight.png" >/dev/null
"$ROOT/tools/iosimctl" ui "$UDID" appearance dark >/dev/null
if wait_log "[appearance] style 2"; then
    echo "ok   the foreground app receives a dark trait change"
else
    echo "FAIL appearance dark trait"; fails=$((fails+1))
fi
sleep 0.4
"$ROOT/tools/iosimctl" io "$UDID" screenshot "$T/apdark.png" >/dev/null
"$ROOT/tools/iosimctl" ui "$UDID" appearance light >/dev/null
if wait_log "[appearance] style 1"; then
    echo "ok   the app receives the light trait change again"
else
    echo "FAIL appearance light trait"; fails=$((fails+1))
fi
sleep 0.4
"$ROOT/tools/iosimctl" io "$UDID" screenshot "$T/aplight2.png" >/dev/null
if out="$(python3 - "$ROOT/tools" "$T" <<'APPNG'
import sys
sys.path.insert(0, sys.argv[1])
import pngpixel
root = sys.argv[2]
def load(name):
    w, h, bpp, rows = pngpixel.load(root + "/" + name)
    def rgb(x, y):
        c = pngpixel.px(rows, bpp, x * 3, y * 3)
        return ((c >> 16) & 255, (c >> 8) & 255, c & 255)
    return rgb
def counts(rgb):
    black = white = 0
    for y in range(350, 445, 2):
        for x in range(60, 340, 2):
            c = rgb(x, y)
            if c[0] < 40 and c[1] < 40 and c[2] < 40:
                black += 1
            if c[0] > 220 and c[1] > 220 and c[2] > 220:
                white += 1
    return black, white
def time_counts(rgb):
    dark = white = 0
    for y in range(24, 48):
        for x in range(55, 106):
            c = rgb(x, y)
            if c[0] < 80 and c[1] < 80 and c[2] < 80:
                dark += 1
            if c[0] > 200 and c[1] > 200 and c[2] > 200:
                white += 1
    return dark, white
light = load("aplight.png")
dark = load("apdark.png")
light2 = load("aplight2.png")
lb, lw = counts(light)
db, dw = counts(dark)
l2b, l2w = counts(light2)
ltd, ltw = time_counts(light)
dtd, dtw = time_counts(dark)
l2td, l2tw = time_counts(light2)
if light(201, 300)[0] < 240:
    raise SystemExit("the light system background is not white")
if dark(201, 300)[0] > 10:
    raise SystemExit("the dark system background is not black")
if lb < 10 or lw < 3000:
    raise SystemExit("light label/background pixels are wrong")
if dw < 10 or db < 3000:
    raise SystemExit("dark label/background pixels are wrong")
if l2b < 10 or l2w < 3000:
    raise SystemExit("the app did not return to light appearance")
if ltd < 20 or l2td < 20:
    raise SystemExit("the light status bar is not dark content")
if dtw < 20:
    raise SystemExit("the dark status bar is not light content")
print("ok   system colors follow the device appearance")
print("ok   the status bar style follows the appearance")
APPNG
)"; then
    echo "$out"
else
    echo "FAIL appearance colors"; echo "$out"; fails=$((fails+1))
fi
"$ROOT/tools/iosimctl" ui "$UDID" home >/dev/null
sleep 0.6
"$ROOT/tools/build_app.sh" "$ROOT/tests/blur_material_test.m" \
    "$T/BlurMaterialApp" >/dev/null
mkdir -p "$T/BlurMaterialApp.app"
cp "$T/BlurMaterialApp" "$T/BlurMaterialApp.app/BlurMaterialApp"
python3 - "$T/BlurMaterialApp.app/Info.plist" <<'PY'
import plistlib, sys
with open(sys.argv[1], "wb") as f:
    plistlib.dump({
        "CFBundleIdentifier": "com.iosim.blurmaterial",
        "CFBundleExecutable": "BlurMaterialApp",
        "CFBundleName": "BlurMaterial",
        "CFBundlePackageType": "APPL",
        "CFBundleVersion": "1",
        "CFBundleShortVersionString": "1.0",
    }, f)
PY
"$ROOT/tools/iosimctl" install "$UDID" "$T/BlurMaterialApp.app" >/dev/null
sleep 0.5
: > "$SBLOG"
"$ROOT/tools/iosimctl" ui "$UDID" tap 201 718.5 >/dev/null
if wait_log "[SpringBoard] search opened"; then
    echo "ok   Spotlight opens for the material fixture"
else
    echo "FAIL material search open"; fails=$((fails+1))
fi
for c in b l u r m a t e r i a l; do
    "$ROOT/tools/iosimctl" ui "$UDID" key "$c" >/dev/null
done
if wait_log "[SpringBoard] search results 1"; then
    echo "ok   the material fixture is found in Spotlight"
else
    echo "FAIL material search"; fails=$((fails+1))
fi
"$ROOT/tools/iosimctl" ui "$UDID" tap 200 270 >/dev/null
if wait_log "[blur-material] ready"; then
    echo "ok   the material fixture launches"
else
    echo "FAIL material launch"; fails=$((fails+1))
fi
sleep 0.4
"$ROOT/tools/iosimctl" io "$UDID" screenshot "$T/apblurlight.png" >/dev/null
"$ROOT/tools/iosimctl" ui "$UDID" appearance dark >/dev/null
if wait_log "[blur-material] style 2"; then
    echo "ok   the material fixture receives the dark trait"
else
    echo "FAIL material trait"; fails=$((fails+1))
fi
sleep 0.4
"$ROOT/tools/iosimctl" io "$UDID" screenshot "$T/apblurdark.png" >/dev/null
if out="$(python3 - "$ROOT/tools" "$T" <<'MATPNG'
import sys
sys.path.insert(0, sys.argv[1])
import pngpixel
root = sys.argv[2]
def load(name):
    w, h, bpp, rows = pngpixel.load(root + "/" + name)
    def rgb(x, y):
        c = pngpixel.px(rows, bpp, x * 3, y * 3)
        return ((c >> 16) & 255, (c >> 8) & 255, c & 255)
    return rgb
light = load("apblurlight.png")
dark = load("apblurdark.png")
if light(60, 420)[0] < 140:
    raise SystemExit("the light system material is too dark")
if dark(60, 420)[0] > 110:
    raise SystemExit("the dark system material is still light")
if abs(light(20, 420)[0] - 128) > 12 or abs(dark(20, 420)[0] - 128) > 12:
    raise SystemExit("the material changed its backdrop")
print("ok   system material blur follows the appearance")
MATPNG
)"; then
    echo "$out"
else
    echo "FAIL material appearance"; echo "$out"; fails=$((fails+1))
fi
"$ROOT/tools/iosimctl" ui "$UDID" home >/dev/null
sleep 0.6
"$ROOT/tools/build_app.sh" "$ROOT/tests/statusbar_test.m" \
    "$T/StatusBarApp" >/dev/null
mkdir -p "$T/StatusBarApp.app"
cp "$T/StatusBarApp" "$T/StatusBarApp.app/StatusBarApp"
python3 - "$T/StatusBarApp.app/Info.plist" <<'PY'
import plistlib, sys
with open(sys.argv[1], "wb") as f:
    plistlib.dump({
        "CFBundleIdentifier": "com.iosim.statusbar",
        "CFBundleExecutable": "StatusBarApp",
        "CFBundleName": "StatusBar",
        "CFBundlePackageType": "APPL",
        "CFBundleVersion": "1",
        "CFBundleShortVersionString": "1.0",
    }, f)
PY
"$ROOT/tools/iosimctl" install "$UDID" "$T/StatusBarApp.app" >/dev/null
sleep 0.4
"$ROOT/tools/iosimctl" ui "$UDID" tap 201 718.5 >/dev/null
sleep 0.5
for c in s t a t u s b a r; do
    "$ROOT/tools/iosimctl" ui "$UDID" key "$c" >/dev/null
done
sleep 0.7
"$ROOT/tools/iosimctl" ui "$UDID" tap 200 270 >/dev/null
if wait_log "[statusbar] ready"; then
    echo "ok   the status bar fixture launches"
else
    echo "FAIL status bar launch"; fails=$((fails+1))
fi
sleep 0.4
"$ROOT/tools/iosimctl" io "$UDID" screenshot "$T/apstatus-on.png" >/dev/null
"$ROOT/tools/iosimctl" ui "$UDID" tap 200 340 >/dev/null
if wait_log "[statusbar] hidden 1"; then
    echo "ok   prefersStatusBarHidden hides the status bar"
else
    echo "FAIL status bar hide"; fails=$((fails+1))
fi
sleep 0.4
"$ROOT/tools/iosimctl" io "$UDID" screenshot "$T/apstatus-off.png" >/dev/null
"$ROOT/tools/iosimctl" ui "$UDID" tap 200 340 >/dev/null
if wait_log "[statusbar] hidden 0"; then
    echo "ok   the status bar returns"
else
    echo "FAIL status bar show"; fails=$((fails+1))
fi
sleep 0.4
"$ROOT/tools/iosimctl" io "$UDID" screenshot "$T/apstatus-on2.png" >/dev/null
if out="$(python3 - "$ROOT/tools" "$T" <<'STPNG'
import sys
sys.path.insert(0, sys.argv[1])
import pngpixel
root = sys.argv[2]
def load(name):
    w, h, bpp, rows = pngpixel.load(root + "/" + name)
    def rgb(x, y):
        c = pngpixel.px(rows, bpp, x * 3, y * 3)
        return ((c >> 16) & 255, (c >> 8) & 255, c & 255)
    return rgb
def dark_time(rgb):
    n = 0
    for y in range(24, 48):
        for x in range(55, 106):
            if max(rgb(x, y)) < 80:
                n += 1
    return n
on = dark_time(load("apstatus-on.png"))
off = dark_time(load("apstatus-off.png"))
on2 = dark_time(load("apstatus-on2.png"))
if on < 20 or on2 < 20:
    raise SystemExit("the status bar time is missing when visible")
if off > 5:
    raise SystemExit("the status bar time is still drawn when hidden")
print("ok   the status bar hides and returns")
STPNG
)"; then
    echo "$out"
else
    echo "FAIL status bar pixels"; echo "$out"; fails=$((fails+1))
fi
"$ROOT/tools/iosimctl" ui "$UDID" home >/dev/null
sleep 0.6
"$ROOT/tools/build_app.sh" "$ROOT/tests/statusbar_plist_test.m" \
    "$T/StatusBarPlistApp" >/dev/null
mkdir -p "$T/StatusBarPlistApp.app"
cp "$T/StatusBarPlistApp" "$T/StatusBarPlistApp.app/StatusBarPlistApp"
python3 - "$T/StatusBarPlistApp.app/Info.plist" <<'PY'
import plistlib, sys
with open(sys.argv[1], "wb") as f:
    plistlib.dump({
        "CFBundleIdentifier": "com.iosim.statusbarplist",
        "CFBundleExecutable": "StatusBarPlistApp",
        "CFBundleName": "StatusBarPlist",
        "CFBundlePackageType": "APPL",
        "CFBundleVersion": "1",
        "CFBundleShortVersionString": "1.0",
        "UIViewControllerBasedStatusBarAppearance": False,
        "UIStatusBarStyle": "UIStatusBarStyleLightContent",
    }, f)
PY
"$ROOT/tools/iosimctl" install "$UDID" "$T/StatusBarPlistApp.app" >/dev/null
sleep 0.4
"$ROOT/tools/iosimctl" ui "$UDID" tap 201 718.5 >/dev/null
sleep 0.5
for c in s t a t u s b a r p l i s t; do
    "$ROOT/tools/iosimctl" ui "$UDID" key "$c" >/dev/null
done
sleep 0.7
"$ROOT/tools/iosimctl" ui "$UDID" tap 200 270 >/dev/null
if wait_log "[statusbar-plist] ready"; then
    echo "ok   the plist status bar fixture launches"
else
    echo "FAIL plist status bar launch"; fails=$((fails+1))
fi
sleep 0.4
"$ROOT/tools/iosimctl" io "$UDID" screenshot "$T/apstatusplist.png" >/dev/null
if out="$(python3 - "$ROOT/tools" "$T" <<'PLPNG'
import sys
sys.path.insert(0, sys.argv[1])
import pngpixel
root = sys.argv[2]
w, h, bpp, rows = pngpixel.load(root + "/apstatusplist.png")
def rgb(x, y):
    c = pngpixel.px(rows, bpp, x * 3, y * 3)
    return ((c >> 16) & 255, (c >> 8) & 255, c & 255)
white = dark = 0
for y in range(24, 48):
    for x in range(55, 106):
        c = rgb(x, y)
        if min(c) > 200:
            white += 1
        if max(c) < 80:
            dark += 1
if white < 20:
    raise SystemExit("the plist light status bar is not white")
if dark > 5:
    raise SystemExit("the plist light status bar still draws dark glyphs")
if abs(rgb(200, 200)[0] - 128) > 12:
    raise SystemExit("the plist fixture background changed")
print("ok   UIStatusBarStyle in Info.plist overrides the controller")
PLPNG
)"; then
    echo "$out"
else
    echo "FAIL plist status bar pixels"; echo "$out"; fails=$((fails+1))
fi
"$ROOT/tools/iosimctl" ui "$UDID" home >/dev/null
sleep 0.6
"$ROOT/tools/iosimctl" ui "$UDID" appearance dark >/dev/null
if wait_log "[SpringBoard] appearance dark"; then
    echo "ok   SpringBoard records a dark appearance at the home screen"
else
    echo "FAIL appearance SpringBoard"; fails=$((fails+1))
fi
sleep 0.3
"$ROOT/tools/iosimctl" io "$UDID" screenshot "$T/aphomedark.png" >/dev/null
if [ "$(cat "$IOSIM_HOME/Devices/$UDID/data/Library/SpringBoard/appearance.txt" 2>/dev/null)" = "dark" ]; then
    echo "ok   the appearance is stored for the next app launch"
else
    echo "FAIL appearance store"; fails=$((fails+1))
fi
"$ROOT/tools/iosimctl" ui "$UDID" appearance light >/dev/null
if wait_log "[SpringBoard] appearance light"; then
    echo "ok   SpringBoard switches back to light"
else
    echo "FAIL appearance light store"; fails=$((fails+1))
fi
sleep 0.3
"$ROOT/tools/iosimctl" io "$UDID" screenshot "$T/aphomelight.png" >/dev/null
if out="$(python3 - "$ROOT/tools" "$T" <<'HOMEPNG'
import sys
sys.path.insert(0, sys.argv[1])
import pngpixel
root = sys.argv[2]
def load(name):
    w, h, bpp, rows = pngpixel.load(root + "/" + name)
    def rgb(x, y):
        c = pngpixel.px(rows, bpp, x * 3, y * 3)
        return ((c >> 16) & 255, (c >> 8) & 255, c & 255)
    return rgb
dark = load("aphomedark.png")
light = load("aphomelight.png")
if dark(170, 718)[0] > 80:
    raise SystemExit("the dark search glass is still light")
if light(170, 718)[0] < 90:
    raise SystemExit("the light search glass is still dark")
print("ok   home screen glass follows the appearance")
HOMEPNG
)"; then
    echo "$out"
else
    echo "FAIL appearance home glass"; echo "$out"; fails=$((fails+1))
fi

# ---------- CAReplicatorLayer ----------
"$ROOT/tools/build_app.sh" "$ROOT/tests/replicator_test.m" \
    "$T/ReplicatorApp" >/dev/null
mkdir -p "$T/ReplicatorApp.app"
cp "$T/ReplicatorApp" "$T/ReplicatorApp.app/ReplicatorApp"
python3 - "$T/ReplicatorApp.app/Info.plist" <<'PY'
import plistlib, sys
with open(sys.argv[1], "wb") as f:
    plistlib.dump({
        "CFBundleIdentifier": "com.iosim.replicator",
        "CFBundleExecutable": "ReplicatorApp",
        "CFBundleName": "Replicator",
        "CFBundlePackageType": "APPL",
        "CFBundleVersion": "1",
        "CFBundleShortVersionString": "1.0",
    }, f)
PY
"$ROOT/tools/iosimctl" install "$UDID" "$T/ReplicatorApp.app" >/dev/null
sleep 0.4
"$ROOT/tools/iosimctl" ui "$UDID" tap 201 718.5 >/dev/null
sleep 0.5
for c in r e p l i c a t o r; do
    "$ROOT/tools/iosimctl" ui "$UDID" key "$c" >/dev/null
done
sleep 0.7
"$ROOT/tools/iosimctl" ui "$UDID" tap 200 270 >/dev/null
if wait_log "[replicator] ready"; then
    echo "ok   the replicator fixture launches"
else
    echo "FAIL replicator launch"; fails=$((fails+1))
fi
sleep 0.4
"$ROOT/tools/iosimctl" io "$UDID" screenshot "$T/replicator.png" >/dev/null
if out="$(python3 - "$ROOT/tools" "$T" <<'REPPNG'
import sys, math
sys.path.insert(0, sys.argv[1])
import pngpixel
root = sys.argv[2]
w, h, bpp, rows = pngpixel.load(root + "/replicator.png")
def rgb(x, y):
    c = pngpixel.px(rows, bpp, int(round(x * 3)), int(round(y * 3)))
    return ((c >> 16) & 255, (c >> 8) & 255, c & 255)
if max(rgb(201, 437)) > 10:
    raise SystemExit("the replicator center is not empty")
for k in range(8):
    a = k * math.pi / 4
    c = rgb(201 + 90 * math.cos(a), 437 + 90 * math.sin(a))
    if c[0] < 200 or not (80 < c[1] < 180) or c[2] > 80:
        raise SystemExit("ring dot %d is wrong: %r" % (k, c))
blues = [rgb(x, 620)[2] for x in (70, 130, 190, 250)]
for x, b in zip((70, 130, 190, 250), blues):
    c = rgb(x, 620)
    if c[0] < 200 or c[1] > 30:
        raise SystemExit("row dot at %d is not red: %r" % (x, c))
if not (blues[0] < 20 and 25 < blues[1] < 55 and
        60 < blues[2] < 95 and blues[3] > 95):
    raise SystemExit("row color offsets are wrong: %r" % (blues,))
print("ok   replicator copies rotate, translate and shift color")
REPPNG
)"; then
    echo "$out"
else
    echo "FAIL replicator pixels"; echo "$out"; fails=$((fails+1))
fi
sleep 3
"$ROOT/tools/iosimctl" io "$UDID" screenshot "$T/replicator-delay.png" >/dev/null
if out="$(python3 - "$ROOT/tools" "$T/replicator.png" \
    "$T/replicator-delay.png" <<'REPDELAY'
import sys
sys.path.insert(0, sys.argv[1])
import pngpixel

def load(path):
    w, h, bpp, rows = pngpixel.load(path)
    def red(x, y):
        return (pngpixel.px(rows, bpp, x * 3, y * 3) >> 16) & 255
    return red

early = load(sys.argv[2])
late = load(sys.argv[3])
start = early(85, 730)
first, second, third = late(85, 730), late(155, 730), late(225, 730)
if not (first > start + 20):
    raise SystemExit("the leading copy did not advance: %d -> %d" %
                     (start, first))
if not (second >= 0 and third < 30):
    raise SystemExit("staggered opacities are wrong: %d %d %d" %
                     (first, second, third))
if first - second < 25:
    raise SystemExit("the copies are not staggered: %d %d" %
                     (first, second))
print("ok   instanceDelay staggers each copy's animation")
REPDELAY
)"; then
    echo "$out"
else
    echo "FAIL replicator delay"; echo "$out"; fails=$((fails+1))
fi
"$ROOT/tools/iosimctl" ui "$UDID" home >/dev/null

# ---------- CAAnimation timing and CATransaction ----------
"$ROOT/tools/build_app.sh" "$ROOT/tests/animation_timing_test.m" \
    "$T/TimingApp" >/dev/null
mkdir -p "$T/TimingApp.app"
cp "$T/TimingApp" "$T/TimingApp.app/TimingApp"
python3 - "$T/TimingApp.app/Info.plist" <<'PY'
import plistlib, sys
with open(sys.argv[1], "wb") as f:
    plistlib.dump({
        "CFBundleIdentifier": "com.iosim.timing",
        "CFBundleExecutable": "TimingApp",
        "CFBundleName": "Timing",
        "CFBundlePackageType": "APPL",
        "CFBundleVersion": "1",
        "CFBundleShortVersionString": "1.0",
    }, f)
PY
: > "$SBLOG"
"$ROOT/tools/iosimctl" install "$UDID" "$T/TimingApp.app" >/dev/null
sleep 0.4
"$ROOT/tools/iosimctl" ui "$UDID" tap 201 718.5 >/dev/null
sleep 0.5
for c in t i m i n g; do
    "$ROOT/tools/iosimctl" ui "$UDID" key "$c" >/dev/null
done
sleep 0.7
"$ROOT/tools/iosimctl" ui "$UDID" tap 200 270 >/dev/null
if wait_log "[timing] ready"; then
    echo "ok   the animation timing fixture launches"
else
    echo "FAIL timing launch"; fails=$((fails+1))
fi
sleep 3.5
if out="$(python3 - "$SBLOG" <<'TIMINGLOG'
import sys
text = open(sys.argv[1], errors="replace").read()
def values(name):
    prefix = "[timing] %s " % name
    out = []
    for line in text.splitlines():
        if line.startswith(prefix):
            try:
                out.append(float(line[len(prefix):]))
            except ValueError:
                pass
    return out
fill = values("fill")
if len(fill) != 3:
    raise SystemExit("expected three fill samples, got %r" % (fill,))
if not (fill[0] > 0.9 and 0.55 < fill[1] < 0.9 and fill[2] < 0.1):
    raise SystemExit("fillMode backwards samples are wrong: %r" % (fill,))
reverse = []
prefix = "[timing] reverse "
for line in text.splitlines():
    if not line.startswith(prefix):
        continue
    parts = line[len(prefix):].split()
    if len(parts) == 2:
        try:
            reverse.append((float(parts[0]), float(parts[1])))
        except ValueError:
            pass
if len(reverse) != 4:
    raise SystemExit("expected four reverse samples, got %r" % (reverse,))
for value, elapsed in reverse:
    if elapsed < 1.0:
        expected = 1.0 - elapsed
    elif elapsed < 2.0:
        expected = elapsed - 1.0
    else:
        expected = 1.0
    if abs(value - expected) > 0.12:
        raise SystemExit(
            "autoreverse sample %.2f at %.2f s is not %.2f" %
            (value, elapsed, expected))
speed = values("speed")
if len(speed) != 1 or not 0.2 < speed[0] < 0.55:
    raise SystemExit("speed sample is wrong: %r" % (speed,))
offset = values("offset")
if len(offset) != 1 or not 0.2 < offset[0] < 0.55:
    raise SystemExit("timeOffset sample is wrong: %r" % (offset,))
for line in ("[timing] transaction duration 0.50",
             "[timing] transaction done",
             "[timing] no-anim completion 1",
             "[timing] animations enabled 1"):
    if line not in text:
        raise SystemExit("missing %r" % line)
print("ok   animation timing, transactions and animation toggles")
TIMINGLOG
)"; then
    echo "$out"
else
    echo "FAIL timing samples"; echo "$out"; fails=$((fails+1))
fi
"$ROOT/tools/iosimctl" ui "$UDID" home >/dev/null

# ---------- CAEmitterLayer ----------
"$ROOT/tools/build_app.sh" "$ROOT/tests/emitter_test.m" \
    "$T/EmitterApp" >/dev/null
mkdir -p "$T/EmitterApp.app"
cp "$T/EmitterApp" "$T/EmitterApp.app/EmitterApp"
python3 - "$T/EmitterApp.app/Info.plist" <<'PY'
import plistlib, sys
with open(sys.argv[1], "wb") as f:
    plistlib.dump({
        "CFBundleIdentifier": "com.iosim.emitter",
        "CFBundleExecutable": "EmitterApp",
        "CFBundleName": "Emitter",
        "CFBundlePackageType": "APPL",
        "CFBundleVersion": "1",
        "CFBundleShortVersionString": "1.0",
    }, f)
PY
"$ROOT/tools/iosimctl" install "$UDID" "$T/EmitterApp.app" >/dev/null
sleep 0.4
"$ROOT/tools/iosimctl" ui "$UDID" tap 201 718.5 >/dev/null
sleep 0.5
for c in e m i t t e r; do
    "$ROOT/tools/iosimctl" ui "$UDID" key "$c" >/dev/null
done
sleep 0.7
"$ROOT/tools/iosimctl" ui "$UDID" tap 200 270 >/dev/null
if wait_log "[emitter] ready"; then
    echo "ok   the emitter fixture launches"
else
    echo "FAIL emitter launch"; fails=$((fails+1))
fi
sleep 0.6
"$ROOT/tools/iosimctl" io "$UDID" screenshot "$T/emitter.png" >/dev/null
if out="$(python3 - "$ROOT/tools" "$T" <<'EMITPNG'
import sys
sys.path.insert(0, sys.argv[1])
import pngpixel
root = sys.argv[2]
w, h, bpp, rows = pngpixel.load(root + "/emitter.png")
orange = 0
quadrants = [0, 0, 0, 0]
for y in range(0, h, 2):
    for x in range(0, w, 2):
        c = pngpixel.px(rows, bpp, x, y)
        r = (c >> 16) & 255
        g = (c >> 8) & 255
        b = c & 255
        if r > 180 and 50 < g < 190 and b < 90:
            orange += 1
            quadrants[(0 if x < w // 2 else 1) +
                      (0 if y < h // 2 else 2)] += 1
if orange < 1000:
    raise SystemExit("too few particles: %d" % orange)
if min(quadrants) < 100:
    raise SystemExit("particles are not spread around: %r" % (quadrants,))
print("ok   emitter particles spread across the screen")
EMITPNG
)"; then
    echo "$out"
else
    echo "FAIL emitter pixels"; echo "$out"; fails=$((fails+1))
fi
"$ROOT/tools/iosimctl" ui "$UDID" home >/dev/null

# ---------- UIView keyframe animations ----------
"$ROOT/tools/build_app.sh" "$ROOT/tests/keyframe_test.m" \
    "$T/KeyframeApp" >/dev/null
mkdir -p "$T/KeyframeApp.app"
cp "$T/KeyframeApp" "$T/KeyframeApp.app/KeyframeApp"
python3 - "$T/KeyframeApp.app/Info.plist" <<'PY'
import plistlib, sys
with open(sys.argv[1], "wb") as f:
    plistlib.dump({
        "CFBundleIdentifier": "com.iosim.keyframe",
        "CFBundleExecutable": "KeyframeApp",
        "CFBundleName": "Keyframe",
        "CFBundlePackageType": "APPL",
        "CFBundleVersion": "1",
        "CFBundleShortVersionString": "1.0",
    }, f)
PY
: > "$SBLOG"
"$ROOT/tools/iosimctl" install "$UDID" "$T/KeyframeApp.app" >/dev/null
sleep 0.4
"$ROOT/tools/iosimctl" ui "$UDID" tap 201 718.5 >/dev/null
sleep 0.5
for c in k e y f r a m e; do
    "$ROOT/tools/iosimctl" ui "$UDID" key "$c" >/dev/null
done
sleep 0.7
"$ROOT/tools/iosimctl" ui "$UDID" tap 200 270 >/dev/null
if wait_log "[keyframe] ready"; then
    echo "ok   the keyframe fixture launches"
else
    echo "FAIL keyframe launch"; fails=$((fails+1))
fi
sleep 1.6
if out="$(python3 - "$SBLOG" <<'KEYFRAMELOG'
import sys
text = open(sys.argv[1], errors="replace").read()
def point(name):
    for line in text.splitlines():
        prefix = "[keyframe] %s " % name
        if line.startswith(prefix):
            parts = line[len(prefix):].split()
            if len(parts) == 2:
                return float(parts[0]), float(parts[1])
    return None
move = point("move")
turn = point("turn")
end = point("end")
if not move or not turn or not end:
    raise SystemExit("missing keyframe samples: %r %r %r" %
                     (move, turn, end))
if not (105 <= move[0] <= 200 and move[1] == 300):
    raise SystemExit("first keyframe segment is wrong: %r" % (move,))
if not (turn[0] == 200 and 300 <= turn[1] <= 485):
    raise SystemExit("second keyframe segment is wrong: %r" % (turn,))
if end != (200, 500):
    raise SystemExit("final keyframe position is wrong: %r" % (end,))
if "[keyframe] done 1" not in text:
    raise SystemExit("keyframe completion did not run")
print("ok   keyframe segments interpolate and finish")
KEYFRAMELOG
)"; then
    echo "$out"
else
    echo "FAIL keyframe samples"; echo "$out"; fails=$((fails+1))
fi
"$ROOT/tools/iosimctl" ui "$UDID" home >/dev/null

# ---------- tint colors ----------
"$ROOT/tools/build_app.sh" "$ROOT/tests/tint_test.m" \
    "$T/TintApp" >/dev/null
mkdir -p "$T/TintApp.app"
cp "$T/TintApp" "$T/TintApp.app/TintApp"
python3 - "$T/TintApp.app/Info.plist" <<'PY'
import plistlib, sys
with open(sys.argv[1], "wb") as f:
    plistlib.dump({
        "CFBundleIdentifier": "com.iosim.tint",
        "CFBundleExecutable": "TintApp",
        "CFBundleName": "Tint",
        "CFBundlePackageType": "APPL",
        "CFBundleVersion": "1",
        "CFBundleShortVersionString": "1.0",
    }, f)
PY
"$ROOT/tools/iosimctl" install "$UDID" "$T/TintApp.app" >/dev/null
sleep 0.4
"$ROOT/tools/iosimctl" ui "$UDID" tap 201 718.5 >/dev/null
sleep 0.5
for c in t i n t; do
    "$ROOT/tools/iosimctl" ui "$UDID" key "$c" >/dev/null
done
sleep 0.7
"$ROOT/tools/iosimctl" ui "$UDID" tap 200 270 >/dev/null
if wait_log "[tint] ready"; then
    echo "ok   the tint fixture launches"
else
    echo "FAIL tint launch"; fails=$((fails+1))
fi
sleep 0.4
"$ROOT/tools/iosimctl" io "$UDID" screenshot "$T/tint.png" >/dev/null
if out="$(python3 - "$ROOT/tools" "$T" "$SBLOG" <<'TINTPNG'
import sys
sys.path.insert(0, sys.argv[1])
import pngpixel
root = sys.argv[2]
text = open(sys.argv[3], errors="replace").read()
if "[tint] inherited 1 1" not in text:
    raise SystemExit("button tint did not inherit from its container")
w, h, bpp, rows = pngpixel.load(root + "/tint.png")
def counts(y0, y1):
    red = green = blue = 0
    for y in range(y0 * 3, y1 * 3, 2):
        for x in range(40 * 3, 360 * 3, 2):
            c = pngpixel.px(rows, bpp, x, y)
            r = (c >> 16) & 255
            g = (c >> 8) & 255
            b = c & 255
            if r > 150 and g < 100 and b < 100:
                red += 1
            if g > 120 and r < 120 and b < 120:
                green += 1
            if b > 150 and r < 100 and g > 40:
                blue += 1
    return red, green, blue
red = counts(180, 300)
green = counts(380, 500)
blue = counts(580, 700)
if not (red[0] > 500 and green[1] > 500 and blue[2] > 500):
    raise SystemExit("tinted titles are missing: %r %r %r" %
                     (red, green, blue))
if red[1] + red[2] > 200 or green[0] + green[2] > 200:
    raise SystemExit("tinted titles leaked another color: %r %r" %
                     (red, green))
print("ok   button titles follow inherited tint colors")
TINTPNG
)"; then
    echo "$out"
else
    echo "FAIL tint pixels"; echo "$out"; fails=$((fails+1))
fi
"$ROOT/tools/iosimctl" ui "$UDID" home >/dev/null

# ---------- image renderer and PNG output ----------
rm -f /tmp/iosim-image-renderer.png
"$ROOT/tools/build_app.sh" "$ROOT/tests/image_renderer_test.m" \
    "$T/RendererApp" >/dev/null
mkdir -p "$T/RendererApp.app"
cp "$T/RendererApp" "$T/RendererApp.app/RendererApp"
python3 - "$T/RendererApp.app/Info.plist" <<'PY'
import plistlib, sys
with open(sys.argv[1], "wb") as f:
    plistlib.dump({
        "CFBundleIdentifier": "com.iosim.renderer",
        "CFBundleExecutable": "RendererApp",
        "CFBundleName": "Renderer",
        "CFBundlePackageType": "APPL",
        "CFBundleVersion": "1",
        "CFBundleShortVersionString": "1.0",
    }, f)
PY
: > "$SBLOG"
"$ROOT/tools/iosimctl" install "$UDID" "$T/RendererApp.app" >/dev/null
sleep 0.4
"$ROOT/tools/iosimctl" ui "$UDID" tap 201 718.5 >/dev/null
sleep 0.5
for c in r e n d e r e r; do
    "$ROOT/tools/iosimctl" ui "$UDID" key "$c" >/dev/null
done
sleep 0.7
"$ROOT/tools/iosimctl" ui "$UDID" tap 200 270 >/dev/null
if wait_log "[renderer] ready"; then
    echo "ok   the image renderer fixture launches"
else
    echo "FAIL renderer launch"; fails=$((fails+1))
fi
sleep 0.4
"$ROOT/tools/iosimctl" io "$UDID" screenshot "$T/renderer.png" >/dev/null
if out="$(python3 - "$ROOT/tools" "$T" "$SBLOG" <<'RENDERPNG'
import sys
sys.path.insert(0, sys.argv[1])
import pngpixel
root = sys.argv[2]
text = open(sys.argv[3], errors="replace").read()
if "written 1" not in text:
    raise SystemExit("the PNG data was not written")
w, h, bpp, rows = pngpixel.load(root + "/renderer.png")
def rgb(x, y):
    c = pngpixel.px(rows, bpp, int(x * 3), int(y * 3))
    return ((c >> 16) & 255, (c >> 8) & 255, c & 255)
if rgb(190, 340) != (0, 0, 255):
    raise SystemExit("image view background is %r" % (rgb(190, 340),))
if rgb(120, 320) != (255, 0, 0):
    raise SystemExit("image view square is %r" % (rgb(120, 320),))
w, h, bpp, rows = pngpixel.load("/tmp/iosim-image-renderer.png")
if (w, h) != (40, 40):
    raise SystemExit("PNG size is %dx%d" % (w, h))
c = pngpixel.px(rows, bpp, 20, 20)
if ((c >> 16) & 255, (c >> 8) & 255, c & 255) != (0, 255, 0):
    raise SystemExit("PNG center is not green")
print("ok   image renderer draws and encodes a PNG")
RENDERPNG
)"; then
    echo "$out"
else
    echo "FAIL renderer pixels"; echo "$out"; fails=$((fails+1))
fi
rm -f /tmp/iosim-image-renderer.png
"$ROOT/tools/iosimctl" ui "$UDID" home >/dev/null

# ---------- layer contents and small UIKit APIs ----------
"$ROOT/tools/build_app.sh" "$ROOT/tests/contents_test.m" \
    "$T/ContentsApp" >/dev/null
mkdir -p "$T/ContentsApp.app"
cp "$T/ContentsApp" "$T/ContentsApp.app/ContentsApp"
python3 - "$T/ContentsApp.app/Info.plist" <<'PY'
import plistlib, sys
with open(sys.argv[1], "wb") as f:
    plistlib.dump({
        "CFBundleIdentifier": "com.iosim.contents",
        "CFBundleExecutable": "ContentsApp",
        "CFBundleName": "Contents",
        "CFBundlePackageType": "APPL",
        "CFBundleVersion": "1",
        "CFBundleShortVersionString": "1.0",
    }, f)
PY
: > "$SBLOG"
"$ROOT/tools/iosimctl" install "$UDID" "$T/ContentsApp.app" >/dev/null
sleep 0.4
"$ROOT/tools/iosimctl" ui "$UDID" tap 201 718.5 >/dev/null
sleep 0.5
for c in c o n t e n t s; do
    "$ROOT/tools/iosimctl" ui "$UDID" key "$c" >/dev/null
done
sleep 0.7
"$ROOT/tools/iosimctl" ui "$UDID" tap 200 270 >/dev/null
if wait_log "[contents] ready"; then
    echo "ok   the layer contents fixture launches"
else
    echo "FAIL contents launch"; fails=$((fails+1))
fi
sleep 0.4
"$ROOT/tools/iosimctl" io "$UDID" screenshot "$T/contents.png" >/dev/null
if out="$(python3 - "$ROOT/tools" "$T" "$SBLOG" <<'CONTENTSPNG'
import sys
sys.path.insert(0, sys.argv[1])
import pngpixel
root = sys.argv[2]
text = open(sys.argv[3], errors="replace").read()
for line in ("[contents] safe 62 34", "[contents] haptics ok",
             "[contents] screen 1206 2622 3 1", "[contents] idle 1",
             "[contents] canopen 1", "[contents] open 0"):
    if line not in text:
        raise SystemExit("missing %r" % line)
w, h, bpp, rows = pngpixel.load(root + "/contents.png")
def rgb(x, y):
    c = pngpixel.px(rows, bpp, int(x * 3), int(y * 3))
    return ((c >> 16) & 255, (c >> 8) & 255, c & 255)
if rgb(120, 350) != (255, 0, 0) or rgb(180, 350) != (0, 0, 255):
    raise SystemExit("aspect fit did not letterbox the image")
if rgb(150, 310) != (0, 0, 0):
    raise SystemExit("aspect fit filled the letterbox")
if rgb(120, 470) != (0, 0, 255) or rgb(180, 470) != (0, 0, 255):
    raise SystemExit("contentsRect did not crop to the blue half")
if rgb(150, 430) != (0, 0, 0):
    raise SystemExit("contents crop escaped its layer")
print("ok   layer contents gravity, safe areas and small UIKit APIs")
CONTENTSPNG
)"; then
    echo "$out"
else
    echo "FAIL contents pixels"; echo "$out"; fails=$((fails+1))
fi
"$ROOT/tools/iosimctl" ui "$UDID" home >/dev/null

# ---------- CAAnimationDelegate ----------
"$ROOT/tools/build_app.sh" "$ROOT/tests/animation_delegate_test.m" \
    "$T/DelegateApp" >/dev/null
mkdir -p "$T/DelegateApp.app"
cp "$T/DelegateApp" "$T/DelegateApp.app/DelegateApp"
python3 - "$T/DelegateApp.app/Info.plist" <<'PY'
import plistlib, sys
with open(sys.argv[1], "wb") as f:
    plistlib.dump({
        "CFBundleIdentifier": "com.iosim.delegate",
        "CFBundleExecutable": "DelegateApp",
        "CFBundleName": "Delegate",
        "CFBundlePackageType": "APPL",
        "CFBundleVersion": "1",
        "CFBundleShortVersionString": "1.0",
    }, f)
PY
: > "$SBLOG"
"$ROOT/tools/iosimctl" install "$UDID" "$T/DelegateApp.app" >/dev/null
sleep 0.4
"$ROOT/tools/iosimctl" ui "$UDID" tap 201 718.5 >/dev/null
sleep 0.5
for c in d e l e g a t e; do
    "$ROOT/tools/iosimctl" ui "$UDID" key "$c" >/dev/null
done
sleep 0.7
"$ROOT/tools/iosimctl" ui "$UDID" tap 200 270 >/dev/null
if wait_log "[delegate] done"; then
    echo "ok   the animation delegate fixture launches"
else
    echo "FAIL delegate launch"; fails=$((fails+1))
fi
if out="$(python3 - "$SBLOG" <<'DELEGATELOG'
import sys
text = open(sys.argv[1], errors="replace").read()
if text.count("[delegate] start ") != 3:
    raise SystemExit("expected three start callbacks")
if text.count("[delegate] stop 0") != 2:
    raise SystemExit("expected two unfinished stops")
if text.count("[delegate] stop 1") != 1:
    raise SystemExit("expected one finished stop")
if "[delegate] counts 3 3" not in text:
    raise SystemExit("delegate counts were wrong")
print("ok   animation delegate start and stop callbacks")
DELEGATELOG
)"; then
    echo "$out"
else
    echo "FAIL delegate callbacks"; echo "$out"; fails=$((fails+1))
fi
"$ROOT/tools/iosimctl" ui "$UDID" home >/dev/null

# ---------- custom backing layers and animation key APIs ----------
"$ROOT/tools/build_app.sh" "$ROOT/tests/layer_custom_test.m" \
    "$T/CustomLayerApp" >/dev/null
mkdir -p "$T/CustomLayerApp.app"
cp "$T/CustomLayerApp" "$T/CustomLayerApp.app/CustomLayerApp"
python3 - "$T/CustomLayerApp.app/Info.plist" <<'PY'
import plistlib, sys
with open(sys.argv[1], "wb") as f:
    plistlib.dump({
        "CFBundleIdentifier": "com.iosim.customlayer",
        "CFBundleExecutable": "CustomLayerApp",
        "CFBundleName": "CustomLayer",
        "CFBundlePackageType": "APPL",
        "CFBundleVersion": "1",
        "CFBundleShortVersionString": "1.0",
    }, f)
PY
: > "$SBLOG"
"$ROOT/tools/iosimctl" install "$UDID" "$T/CustomLayerApp.app" >/dev/null
sleep 0.4
"$ROOT/tools/iosimctl" ui "$UDID" tap 201 718.5 >/dev/null
sleep 0.5
for c in c u s t o m l a y e r; do
    "$ROOT/tools/iosimctl" ui "$UDID" key "$c" >/dev/null
done
sleep 0.7
"$ROOT/tools/iosimctl" ui "$UDID" tap 200 270 >/dev/null
if wait_log "[layer] ready"; then
    echo "ok   the custom layer fixture launches"
else
    echo "FAIL custom layer launch"; fails=$((fails+1))
fi
sleep 0.4
"$ROOT/tools/iosimctl" io "$UDID" screenshot "$T/customlayer.png" >/dev/null
if out="$(python3 - "$ROOT/tools" "$T" "$SBLOG" <<'CUSTOMLAYER'
import sys
sys.path.insert(0, sys.argv[1])
import pngpixel
root = sys.argv[2]
text = open(sys.argv[3], errors="replace").read()
for line in ("[layer] custom 1 colors 2", "[layer] keys 2 1",
             "[layer] after 0 1"):
    if line not in text:
        raise SystemExit("missing %r" % line)
w, h, bpp, rows = pngpixel.load(root + "/customlayer.png")
def rgb(x, y):
    c = pngpixel.px(rows, bpp, int(x * 3), int(y * 3))
    return ((c >> 16) & 255, (c >> 8) & 255, c & 255)
left = rgb(60, 350)
mid = rgb(150, 350)
right = rgb(240, 350)
if not (left[0] > 200 and left[2] < 40):
    raise SystemExit("gradient left stop is not red: %r" % (left,))
if not (right[2] > 200 and right[0] < 40):
    raise SystemExit("gradient right stop is not blue: %r" % (right,))
if not (mid[0] > 80 and mid[2] > 80):
    raise SystemExit("gradient midpoint did not blend: %r" % (mid,))
if rgb(150, 280) != (0, 0, 0):
    raise SystemExit("gradient escaped the view frame")
if rgb(60, 470) != (0, 255, 0):
    raise SystemExit("sibling view did not draw")
print("ok   layerClass gradient backing and animation key APIs")
CUSTOMLAYER
)"; then
    echo "$out"
else
    echo "FAIL custom layer pixels"; echo "$out"; fails=$((fails+1))
fi
"$ROOT/tools/iosimctl" ui "$UDID" home >/dev/null

# ---------- layout margins ----------
"$ROOT/tools/build_app.sh" "$ROOT/tests/layout_margins_test.m" \
    "$T/MarginsApp" >/dev/null
mkdir -p "$T/MarginsApp.app"
cp "$T/MarginsApp" "$T/MarginsApp.app/MarginsApp"
python3 - "$T/MarginsApp.app/Info.plist" <<'PY'
import plistlib, sys
with open(sys.argv[1], "wb") as f:
    plistlib.dump({
        "CFBundleIdentifier": "com.iosim.margins",
        "CFBundleExecutable": "MarginsApp",
        "CFBundleName": "Margins",
        "CFBundlePackageType": "APPL",
        "CFBundleVersion": "1",
        "CFBundleShortVersionString": "1.0",
    }, f)
PY
: > "$SBLOG"
"$ROOT/tools/iosimctl" install "$UDID" "$T/MarginsApp.app" >/dev/null
sleep 0.4
"$ROOT/tools/iosimctl" ui "$UDID" tap 201 718.5 >/dev/null
sleep 0.5
for c in m a r g i n s; do
    "$ROOT/tools/iosimctl" ui "$UDID" key "$c" >/dev/null
done
sleep 0.7
"$ROOT/tools/iosimctl" ui "$UDID" tap 200 270 >/dev/null
if wait_log "[margins] ready"; then
    echo "ok   the layout margins fixture launches"
else
    echo "FAIL margins launch"; fails=$((fails+1))
fi
sleep 0.5
"$ROOT/tools/iosimctl" io "$UDID" screenshot "$T/margins.png" >/dev/null
if out="$(python3 - "$ROOT/tools" "$T" "$SBLOG" <<'MARGINS'
import sys
sys.path.insert(0, sys.argv[1])
import pngpixel
root = sys.argv[2]
text = open(sys.argv[3], errors="replace").read()
for line in ("[margins] edges 20 20 20 20",
             "[margins] guide 20 20 160 160",
             "[margins] safe 72 46",
             "[margins] safeguide 0 72 402 756",
             "[margins] color 1 255 128 0 1 0.25"):
    if line not in text:
        raise SystemExit("missing %r" % line)
w, h, bpp, rows = pngpixel.load(root + "/margins.png")
def rgb(x, y):
    c = pngpixel.px(rows, bpp, int(x * 3), int(y * 3))
    return ((c >> 16) & 255, (c >> 8) & 255, c & 255)
if rgb(60, 310) != (85, 85, 85):
    raise SystemExit("container margin band is wrong")
if rgb(100, 350) != (0, 255, 0) or rgb(220, 470) != (0, 255, 0):
    raise SystemExit("child did not fill the margins guide")
if rgb(60, 490) != (85, 85, 85):
    raise SystemExit("bottom margin band is wrong")
if rgb(300, 350) != (0, 0, 0):
    raise SystemExit("container escaped its frame")
print("ok   layout margins inset the guide and pinned child")
MARGINS
)"; then
    echo "$out"
else
    echo "FAIL margins pixels"; echo "$out"; fails=$((fails+1))
fi
"$ROOT/tools/iosimctl" ui "$UDID" home >/dev/null

# ---------- radial gradients and window/scene APIs ----------
"$ROOT/tools/build_app.sh" "$ROOT/tests/radial_gradient_test.m" \
    "$T/RadialApp" >/dev/null
mkdir -p "$T/RadialApp.app"
cp "$T/RadialApp" "$T/RadialApp.app/RadialApp"
python3 - "$T/RadialApp.app/Info.plist" <<'PY'
import plistlib, sys
with open(sys.argv[1], "wb") as f:
    plistlib.dump({
        "CFBundleIdentifier": "com.iosim.radial",
        "CFBundleExecutable": "RadialApp",
        "CFBundleName": "Radial",
        "CFBundlePackageType": "APPL",
        "CFBundleVersion": "1",
        "CFBundleShortVersionString": "1.0",
    }, f)
PY
: > "$SBLOG"
"$ROOT/tools/iosimctl" install "$UDID" "$T/RadialApp.app" >/dev/null
sleep 0.4
"$ROOT/tools/iosimctl" ui "$UDID" tap 201 718.5 >/dev/null
sleep 0.5
for c in r a d i a l; do
    "$ROOT/tools/iosimctl" ui "$UDID" key "$c" >/dev/null
done
sleep 0.7
"$ROOT/tools/iosimctl" ui "$UDID" tap 200 270 >/dev/null
if wait_log "[radial] scene 1 windows 1 key 1 scenes 1 level 2000"; then
    echo "ok   the radial gradient fixture launches"
else
    echo "FAIL radial launch"; fails=$((fails+1))
fi
sleep 0.4
"$ROOT/tools/iosimctl" io "$UDID" screenshot "$T/radial.png" >/dev/null
if out="$(python3 - "$ROOT/tools" "$T" <<'RADIAL'
import sys
sys.path.insert(0, sys.argv[1])
import pngpixel
root = sys.argv[2]
w, h, bpp, rows = pngpixel.load(root + "/radial.png")
def rgb(x, y):
    c = pngpixel.px(rows, bpp, int(x * 3), int(y * 3))
    return ((c >> 16) & 255, (c >> 8) & 255, c & 255)
center = rgb(200, 400)
edge = rgb(295, 400)
if not (center[0] > 240 and center[2] < 20):
    raise SystemExit("radial center is not red: %r" % (center,))
if not (edge[2] > 200 and edge[0] < 40):
    raise SystemExit("radial edge is not blue: %r" % (edge,))
if rgb(50, 400) != (0, 0, 0):
    raise SystemExit("radial escaped its frame")
rounded = rgb(200, 650)
corner = rgb(110, 560)
if not (rounded[0] > 240 and rounded[1] > 240 and rounded[2] < 20):
    raise SystemExit("rounded radial center is not yellow: %r" % (rounded,))
if corner != (0, 0, 0):
    raise SystemExit("rounded radial did not mask its corner")
top = rgb(200, 560)
if not (top[0] > 80 and top[2] > 60):
    raise SystemExit("rounded radial did not blend at the edge: %r" % (top,))
print("ok   radial gradients, rounding and window/scene APIs")
RADIAL
)"; then
    echo "$out"
else
    echo "FAIL radial pixels"; echo "$out"; fails=$((fails+1))
fi
"$ROOT/tools/iosimctl" ui "$UDID" home >/dev/null

# ---------- UIView maskView and hit testing ----------
"$ROOT/tools/build_app.sh" "$ROOT/tests/mask_interaction_test.m" \
    "$T/MaskApp" >/dev/null
mkdir -p "$T/MaskApp.app"
cp "$T/MaskApp" "$T/MaskApp.app/MaskApp"
python3 - "$T/MaskApp.app/Info.plist" <<'PY'
import plistlib, sys
with open(sys.argv[1], "wb") as f:
    plistlib.dump({
        "CFBundleIdentifier": "com.iosim.mask",
        "CFBundleExecutable": "MaskApp",
        "CFBundleName": "Mask",
        "CFBundlePackageType": "APPL",
        "CFBundleVersion": "1",
        "CFBundleShortVersionString": "1.0",
    }, f)
PY
: > "$SBLOG"
"$ROOT/tools/iosimctl" install "$UDID" "$T/MaskApp.app" >/dev/null
sleep 0.4
"$ROOT/tools/iosimctl" ui "$UDID" tap 201 718.5 >/dev/null
sleep 0.5
for c in m a s k; do
    "$ROOT/tools/iosimctl" ui "$UDID" key "$c" >/dev/null
done
sleep 0.7
"$ROOT/tools/iosimctl" ui "$UDID" tap 200 270 >/dev/null
if wait_log "[mask] hit 1 enabled 0"; then
    echo "ok   the mask fixture launches"
else
    echo "FAIL mask launch"; fails=$((fails+1))
fi
sleep 0.4
"$ROOT/tools/iosimctl" io "$UDID" screenshot "$T/mask.png" >/dev/null
if out="$(python3 - "$ROOT/tools" "$T" <<'MASK'
import sys
sys.path.insert(0, sys.argv[1])
import pngpixel
root = sys.argv[2]
w, h, bpp, rows = pngpixel.load(root + "/mask.png")
def rgb(x, y):
    c = pngpixel.px(rows, bpp, int(x * 3), int(y * 3))
    return ((c >> 16) & 255, (c >> 8) & 255, c & 255)
if rgb(200, 350) != (255, 0, 0):
    raise SystemExit("disabled view did not draw")
left = rgb(150, 500)
if not (left[2] > 240 and left[0] < 20):
    raise SystemExit("maskView did not keep the covered half: %r" % (left,))
if rgb(250, 500) != (0, 0, 0):
    raise SystemExit("maskView did not clip the uncovered half")
print("ok   maskView clips and disabled views pass hit tests through")
MASK
)"; then
    echo "$out"
else
    echo "FAIL mask pixels"; echo "$out"; fails=$((fails+1))
fi
"$ROOT/tools/iosimctl" ui "$UDID" home >/dev/null

# ---------- Foundation string helpers and fonts ----------
"$ROOT/tools/build_app.sh" "$ROOT/tests/foundation_extra_test.m" \
    "$T/FoundationApp" >/dev/null
mkdir -p "$T/FoundationApp.app"
cp "$T/FoundationApp" "$T/FoundationApp.app/FoundationApp"
python3 - "$T/FoundationApp.app/Info.plist" <<'PY'
import plistlib, sys
with open(sys.argv[1], "wb") as f:
    plistlib.dump({
        "CFBundleIdentifier": "com.iosim.fnd",
        "CFBundleExecutable": "FoundationApp",
        "CFBundleName": "Foundation",
        "CFBundlePackageType": "APPL",
        "CFBundleVersion": "1",
        "CFBundleShortVersionString": "1.0",
    }, f)
PY
: > "$SBLOG"
"$ROOT/tools/iosimctl" install "$UDID" "$T/FoundationApp.app" >/dev/null
sleep 0.4
"$ROOT/tools/iosimctl" ui "$UDID" tap 201 718.5 >/dev/null
sleep 0.5
for c in f o u; do
    "$ROOT/tools/iosimctl" ui "$UDID" key "$c" >/dev/null
done
sleep 0.7
"$ROOT/tools/iosimctl" ui "$UDID" tap 200 270 >/dev/null
if wait_log "[fnd] trim 'Hello World'" &&
   wait_log "[fnd] num 42 3.5 1" &&
   wait_log "[fnd] cap Hello World" &&
   wait_log "[fnd] pct a b/c" &&
   wait_log "[fnd] set 1 0" &&
   wait_log "[fnd] rep abXYef" &&
   wait_log "[fnd] range 6 5 1" &&
   wait_log "[fnd] font 14 System 20" &&
   wait_log "[fnd] p3srgb 0.06 0.20 0.31 0.4" &&
   wait_log "[fnd] color 1 0 0 1.0 0.1 0.4 1.0 0.25" &&
   wait_log "[fnd] desc 17 17" &&
   wait_log "[fnd] readable 16 0 370 874" &&
   wait_log "[fnd] props 1 0 1 3" &&
   wait_log "[fnd] url https example.com 8080 /a/b x=1" &&
   wait_log "[fnd] comp https://example.com:8080/a?q=2#top example.com" &&
   wait_log "[fnd] pfont 17" &&
   wait_log "[fnd] present 7 1 2 2 0" &&
   wait_log "[fnd] value 3 4 2 5 1" &&
   wait_log "[fnd] idx 4 2 11 1 28" &&
   wait_log "[fnd] scene 1 0 iosim-scene-session" &&
   wait_log "[fnd] qitems 2 a two" &&
   wait_log "[fnd] qbuild k=v" &&
   wait_log "[fnd] device iPhone 18.0 0 1" &&
   wait_log "[fnd] process iosim 4 4" &&
   wait_log "[fnd] uuid 36 1" &&
   wait_log "[fnd] affine 7 9" &&
   wait_log "[fnd] vcprops 15 1 0 320 480" &&
   wait_log "[fnd] searchupdate 1" &&
   wait_log "[fnd] search 1 1 0" &&
   wait_log "[fnd] vendor 1" &&
   wait_log "[fnd] idxmore 10 5 10" &&
   wait_log "[fnd] b64 aGVsbG8= 5" &&
   wait_log "[fnd] urlappend /tmp/a/b" &&
   wait_log "[fnd] axel E 1 3 4" &&
   wait_log "[fnd] pct a%20b&c" &&
   wait_log "[fnd] hue 0 1 1 1" &&
   wait_log "[fnd] alert 1 1 0 1" &&
   wait_log "[fnd] viewwin 1 0" &&
   wait_log "[fnd] appext a.txt /tmp/a.txt" &&
   wait_log "[fnd] scene2 1 1" &&
   wait_log "[fnd] split 0 2 307 307 717 2 1" &&
   wait_log "[fnd] triple 307 307 200 507 517 3 1" &&
   wait_log "[fnd] navtoolbar 0 1 725 3 1 1" &&
   wait_log "[fnd] animator start 0.1 0.0 0 0" &&
   wait_log "[fnd] animator done 0 0 2" &&
   wait_log "[fnd] deps 1 1" &&
   wait_log "[fnd] deps done 1 1" &&
   wait_log "[fnd] freepeak 1" &&
   wait_log "[fnd] limit 1 0" &&
   wait_log "[fnd] byref 42" &&
   wait_log "[fnd] progress 0.4 0 0" &&
   wait_log "[fnd] progress2 1 1" &&
   wait_log "[fnd] counted 2 2 2" &&
   wait_log "[fnd] idxpath 3 2 3 2 3 7 2 -1" &&
   wait_log "[fnd] sizetrans 1 400 500 0 1" &&
   wait_log "[fnd] sizetrans alongside 0" &&
   wait_log "[fnd] sizetrans done 0" &&
   wait_log "[fnd] sizetrans count 1 400 500" &&
   wait_log "[fnd] sizechild 1 123" &&
   wait_log "[fnd] sizechildcount 1 123" &&
   wait_log "[fnd] ordered 2 a d a 1 0 2" &&
   wait_log "[fnd] trans delegate 1" &&
   wait_log "[fnd] pres will" &&
   wait_log "[fnd] inter start 1" &&
   wait_log "[fnd] trans anim 1 1 1 1 1 0" &&
   wait_log "[fnd] pres did 1" &&
   wait_log "[fnd] trans present done" &&
   wait_log "[fnd] pres props 1 -2" &&
   wait_log "[fnd] pres dismiss will" &&
   wait_log "[fnd] inter start 2" &&
   wait_log "[fnd] trans anim 2 1 1 1 0 1" &&
   wait_log "[fnd] pres dismiss did 1" &&
   wait_log "[fnd] trans dismiss done" &&
   wait_log "[fnd] pres frame 10 20 30 40"; then
    echo "ok   Foundation helpers, colors, fonts and readable guides"
else
    echo "FAIL Foundation helpers"; fails=$((fails+1))
fi
"$ROOT/tools/iosimctl" ui "$UDID" home >/dev/null

# ---------- page view controller and containment ----------
"$ROOT/tools/build_app.sh" "$ROOT/tests/pageview_test.m" \
    "$T/PageApp" >/dev/null
mkdir -p "$T/PageApp.app"
cp "$T/PageApp" "$T/PageApp.app/PageApp"
python3 - "$T/PageApp.app/Info.plist" <<'PY'
import plistlib, sys
with open(sys.argv[1], "wb") as f:
    plistlib.dump({
        "CFBundleIdentifier": "com.iosim.page",
        "CFBundleExecutable": "PageApp",
        "CFBundleName": "Page",
        "CFBundlePackageType": "APPL",
        "CFBundleVersion": "1",
        "CFBundleShortVersionString": "1.0",
    }, f)
PY
: > "$SBLOG"
"$ROOT/tools/iosimctl" install "$UDID" "$T/PageApp.app" >/dev/null
sleep 0.4
"$ROOT/tools/iosimctl" ui "$UDID" tap 201 718.5 >/dev/null
sleep 0.5
for c in p a g e; do
    "$ROOT/tools/iosimctl" ui "$UDID" key "$c" >/dev/null
done
sleep 0.7
"$ROOT/tools/iosimctl" ui "$UDID" tap 200 270 >/dev/null
if wait_log "[page] pages 1 children 1 parent 1 root 1" &&
   wait_log "[page] next 1 super 1 done 1"; then
    echo "ok   page view controller installs and replaces child pages"
else
    echo "FAIL page view controller"; fails=$((fails+1))
fi
sleep 0.4
"$ROOT/tools/iosimctl" io "$UDID" screenshot "$T/page.png" >/dev/null
if out="$(python3 - "$ROOT/tools" "$T" <<'PAGE'
import sys
sys.path.insert(0, sys.argv[1])
import pngpixel
root = sys.argv[2]
w, h, bpp, rows = pngpixel.load(root + "/page.png")
c = pngpixel.px(rows, bpp, 600, 1500)
if ((c >> 16) & 255, (c >> 8) & 255, c & 255) != (0, 255, 0):
    raise SystemExit("the second page did not fill the screen")
print("ok   the current page fills the page controller")
PAGE
)"; then
    echo "$out"
else
    echo "FAIL page pixels"; echo "$out"; fails=$((fails+1))
fi
"$ROOT/tools/iosimctl" ui "$UDID" home >/dev/null

# ---------- attributed strings ----------
"$ROOT/tools/build_app.sh" "$ROOT/tests/attributed_test.m" \
    "$T/AttributedApp" >/dev/null
mkdir -p "$T/AttributedApp.app"
cp "$T/AttributedApp" "$T/AttributedApp.app/AttributedApp"
python3 - "$T/AttributedApp.app/Info.plist" <<'PY'
import plistlib, sys
with open(sys.argv[1], "wb") as f:
    plistlib.dump({
        "CFBundleIdentifier": "com.iosim.attr",
        "CFBundleExecutable": "AttributedApp",
        "CFBundleName": "Attributed",
        "CFBundlePackageType": "APPL",
        "CFBundleVersion": "1",
        "CFBundleShortVersionString": "1.0",
    }, f)
PY
: > "$SBLOG"
"$ROOT/tools/iosimctl" install "$UDID" "$T/AttributedApp.app" >/dev/null
sleep 0.4
"$ROOT/tools/iosimctl" ui "$UDID" tap 201 718.5 >/dev/null
sleep 0.5
for c in a t t r; do
    "$ROOT/tools/iosimctl" ui "$UDID" key "$c" >/dev/null
done
sleep 0.7
"$ROOT/tools/iosimctl" ui "$UDID" tap 200 270 >/dev/null
if wait_log "[attr] label Hello 5 22" &&
   wait_log "[attr] button Wo! 3 1" &&
   wait_log "[attr] textview Hello 5" &&
   wait_log "[attr] image 1 1" &&
   wait_log "[attr] config Cfg 1" &&
   wait_log "[attr] field 3" &&
   wait_log "[attr] textlayer M 30" &&
   wait_log "[attr] transition 1 1" &&
   wait_log "[attr] bar 1 1" &&
   wait_log "[attr] vc 1 1 30" &&
   wait_log "[attr] access 1 Acc 64" &&
   wait_log "[attr] gestures 1 3 2 1 1" &&
   wait_log "[attr] frame 0 0 80 20" &&
   wait_log "[attr] fieldvalue Hello" &&
   wait_log "[attr] table 0 1 60" &&
   wait_log "[attr] collection 1 1 0" &&
   wait_log "[attr] scroll 1 2 0"; then
    echo "ok   attributed strings drive label and button text"
else
    echo "FAIL attributed strings"; fails=$((fails+1))
fi
sleep 0.4
"$ROOT/tools/iosimctl" io "$UDID" screenshot "$T/attr.png" >/dev/null
if out="$(python3 - "$ROOT/tools" "$T" <<'ATTR'
import sys
sys.path.insert(0, sys.argv[1])
import pngpixel
root = sys.argv[2]
w, h, bpp, rows = pngpixel.load(root + "/attr.png")
c = pngpixel.px(rows, bpp, 210, 1770)
if ((c >> 16) & 255, (c >> 8) & 255, c & 255) != (255, 0, 255):
    raise SystemExit("the button image did not draw")
c = pngpixel.px(rows, bpp, 435, 1746)
if ((c >> 16) & 255, (c >> 8) & 255, c & 255) != (0, 255, 0):
    raise SystemExit("the button configuration background did not draw")
c = pngpixel.px(rows, bpp, 135, 2166)
if ((c >> 16) & 255, (c >> 8) & 255, c & 255) != (28, 28, 30):
    raise SystemExit("the text field border background did not draw")
white = 0
for yy in range(760, 800):
    for xx in range(40, 160):
        c = pngpixel.px(rows, bpp, xx * 3, yy * 3)
        if ((c >> 16) & 255, (c >> 8) & 255, c & 255) == (255, 255, 255):
            white += 1
if white < 20:
    raise SystemExit("the text layer did not draw its string")
print("ok   a button image view draws its image")
ATTR
)"; then
    echo "$out"
else
    echo "FAIL button image pixels"; echo "$out"; fails=$((fails+1))
fi
"$ROOT/tools/iosimctl" ui "$UDID" home >/dev/null

if [ "$fails" -ne 0 ]; then
    echo "$fails test(s) failed" >&2
    exit 1
fi
echo "all tests passed"
