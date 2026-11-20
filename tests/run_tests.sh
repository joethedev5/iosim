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
"$ROOT/tools/iosimctl" ui "$UDID" switcher >/dev/null
if wait_log "app switcher opened (1 suspended)"; then
    echo "ok   app switcher lists the suspended app"
else
    echo "FAIL app switcher"; fails=$((fails+1))
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
if [ "$opened_now" -gt "$opened_before" ] &&
    grep -Fq -- "app switcher opened (1 suspended)" "$SBLOG"; then
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
if not any(v < 0.40 for v in dots):
    raise SystemExit('no keyframe opacity sample: %r' % dots)
print('ok   presentation layer interpolates frame and keyframe opacity')
PY
)"; then
    echo "$out"
else
    echo "FAIL presentation values"; echo "$out"; fails=$((fails+1))
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
# An XPC listener registers its Mach service; a client in another process
# sends a dictionary, which arrives as a rebuilt XPC object.
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
out="$("$ROOT/tools/iosimctl" spawn "$UDID" "$T/xpc_cross" client 2>&1 | tail -1)"
check "xpc client: sent" "$out" "an XPC client sends a dictionary by name"
i=0
while [ "$i" -lt 50 ]; do
    grep -Fq -- "xpc service: received" "$XLOG" 2>/dev/null && break
    sleep 0.1
    i=$((i+1))
done
check "xpc service: received kind=ping seq=7 flag=1 blob=4" "$(cat "$XLOG")" \
    "the dictionary arrives as a rebuilt XPC object in the other process"
wait "$xpc_job" 2>/dev/null || true

"$ROOT/tools/iosimctl" shutdown "$UDID" >/dev/null

if [ "$fails" -ne 0 ]; then
    echo "$fails test(s) failed" >&2
    exit 1
fi
echo "all tests passed"
