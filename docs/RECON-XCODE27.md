# Recon: Xcode 27.1 on GitHub Actions

All facts below were measured on GitHub-hosted `xcode-27` runners (image
`xcode-27-arm64/20261119.0378`) on 2026-11-20, using the workflows in
`recon-runner/.github/workflows/`. Nothing in this document comes from a local
macOS install.

## Host and toolchain

```
macOS 27.0.1 (build 26A434), Darwin 27.0.0 (xnu-13432.1.9~1, RELEASE_ARM64_VMAPPLE)
Xcode 27.1 (build 27A9275)
xcode-select: /Applications/Xcode_27.1.app/Contents/Developer
CPU: Apple M2 Pro (Virtual), arm64
```

`simctl` reports CoreSimulator **1207**.

## Installed simulator runtimes

11 disk images (62 GB) are installed; iOS entries:

| Runtime | Build | Supported architectures | Size |
|---|---|---|---|
| iOS 27.0 | 24A434 | `arm64` | 8.07 GB |
| iOS 27.1 | 24A94425 | `arm64` | 7.87 GB |
| iOS 27.2 | 24B8117 | `arm64` | 8.32 GB |
| iOS 27.2 (iPhone19,4 variant) | 24B91016s | `arm64` | 8.34 GB |

The runtime bundle is a cryptex mount, e.g.:

```
/private/var/run/com.apple.security.cryptexd/mnt/
  com.apple.iPhoneOS.SimulatorRuntime-v24.2.91016.19.NHyATx/
  Library/Developer/CoreSimulator/Profiles/Runtimes/iOS 27.2.simruntime
    Contents/Resources/RuntimeRoot
```

**Every runtime reports `supportedArchitectures: ["arm64"]`.** Inspected
binaries inside the runtime root:

```
usr/lib/dyld_sim            Mach-O 64-bit dynamic linker arm64
sbin/launchd_sim            Mach-O 64-bit executable arm64
usr/libexec/backboardd      Mach-O 64-bit executable arm64
SpringBoard.app/SpringBoard Mach-O 64-bit executable arm64
usr/lib/system/host/liblaunch_sim.dylib
                            universal: arm64, arm64e, arm64e.x1
```

Shared cache:

```
System/Library/Caches/com.apple.dyld/
  dyld_sim_shared_cache_arm64        2,030,977,024 bytes
  dyld_sim_shared_cache_arm64.01     1,718,566,912 bytes
  dyld_sim_shared_cache_arm64.atlas        611,180 bytes
  dyld_sim_shared_cache_arm64.map          448,413 bytes
```

`launchd_sim` identifies itself as `launchd_sim` from
`libxpc_executables_Sim-3298.0.28~11`, Darwin Bootstrapper 7.0.0.

## dyld_sim contract

Strings extracted from the iOS runtime's `dyld_sim` include:

```
DYLD_ROOT_PATH
DYLD_FALLBACK_FRAMEWORK_PATH
DYLD_FALLBACK_LIBRARY_PATH
DYLD_SHARED_CACHE_DIR
DYLD_INSERT_LIBRARIES
DYLD_IMAGE_SUFFIX
DYLD_JUST_BUILD_CLOSURE
DYLD_OVERLAY_PATH
DYLD_PRINT_APIS / BINDINGS / ENV / INITIALIZERS / LIBRARIES / ...
SIMULATOR_* (host integration strings)
```

`launchd_sim` strings include `DYLD_ROOT_PATH`,
`IOS_SIMULATOR_SYSLOG_SOCKET`, and a family of `launchd_*` tuning variables.

## SDK behavior for x86_64

SDK: `/Applications/Xcode_27.1.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator27.1.sdk`

Apple clang 27.1 still cross-compiles x86_64 simulator binaries from an arm64
runner. Verified successful builds:

```
hello_x86_64           Mach-O 64-bit executable x86_64   (printf/getpid)
hello_objc_x86_64      Mach-O 64-bit executable x86_64   (Foundation, NSLog)
hello_uikit_x86_64     Mach-O 64-bit executable x86_64   (UIKit, UIApplicationMain)
hello_uikit_arm64      Mach-O 64-bit executable arm64
```

A first attempt that wrapped `UIApplicationMain` in `@autoreleasepool` failed
at link time with missing `_objc_autoreleasePoolPush`/`Pop`; removing the
explicit pool made the x86_64 UIKit link succeed. This is a link-time symbol
availability detail, not an architecture rejection. The important result is
that **x86_64 simulator apps can still be built**, even though no x86_64
runtime ships.

The UIKit x86_64 binary links:

```
/System/Library/Frameworks/UIKit.framework/UIKit
/usr/lib/libSystem.B.dylib
```

and imports only `_UIApplicationMain`.

The Foundation x86_64 binary links Foundation, libSystem, CoreFoundation and
libobjc.A, and imports `_NSLog`, `___CFConstantStringClassReference`,
`_objc_autoreleasePoolPush` and `_objc_autoreleasePoolPop`.

## Boot and app launch

An iOS 27.0 iPhone 18 Pro device booted in ~44 seconds (including data
migration). `simctl` found a display and captured a screenshot. The system
launchd domain contained daemons such as:

```
com.apple.logd, com.apple.logd_helper, com.apple.diagnosticd
com.apple.containermanagerd.system
com.apple.deviceconfigurationd (+ consumer/provider/publisher endpoints)
com.apple.notifyd
com.apple.cfprefsd.xpc.daemon.system
```

`simctl spawn <udid> env` failed because the runtime has no `/usr/bin/env`
(ENOENT), but `launchctl print system` works. A minimal app bundle
(`com.iosim.recon`) installed and launched successfully; it printed
`Version 27.0 (Build 24A434)` through Foundation's `NSProcessInfo`.

### Captured application environment (selected)

```
SIMULATOR_UDID=9139BB0D-9F45-4B54-BC82-32B67D0BA26E
SIMULATOR_DEVICE_NAME=iPhone 18 Pro
SIMULATOR_MODEL_IDENTIFIER=iPhone19,2
SIMULATOR_PRODUCT_CLASS=V63
SIMULATOR_RUNTIME_VERSION=27.0
SIMULATOR_RUNTIME_BUILD_VERSION=24A434
SIMULATOR_ARCHS=arm64
SIMULATOR_VERSION_INFO=CoreSimulator 1207 - Device: iPhone 18 Pro (9139...) - Runtime: iOS 27.0 (24A434) - DeviceType: iPhone 18 Pro
SIMULATOR_ROOT=<RuntimeRoot>
IPHONE_SIMULATOR_ROOT=<RuntimeRoot>
DYLD_ROOT_PATH=<RuntimeRoot>
DYLD_FALLBACK_FRAMEWORK_PATH=<RuntimeRoot>/System/Library/Frameworks
DYLD_FALLBACK_LIBRARY_PATH=<RuntimeRoot>/usr/lib
DYLD_SHARED_CACHE_DIR=/Library/Developer/CoreSimulator/Caches/dyld/26B123/com.apple.CoreSimulator.SimRuntime.iOS-27-0.24A434/
SIMULATOR_SHARED_RESOURCES_DIRECTORY=<device>/data
IPHONE_SHARED_RESOURCES_DIRECTORY=<device>/data
SIMULATOR_MAINSCREEN_WIDTH=1206
SIMULATOR_MAINSCREEN_HEIGHT=2622
SIMULATOR_MAINSCREEN_SCALE=3.000000
SIMULATOR_MAINSCREEN_PITCH=460.000000
SIMULATOR_LOG_ROOT=~/Library/Logs/CoreSimulator/<udid>
SIMULATOR_HOST_HOME=/Users/runner
SIMULATOR_HID_SYSTEM_MANAGER=/Library/Developer/PrivateFrameworks/CoreSimulator.framework/Resources/Platforms/iphoneos/Library/Frameworks/SimulatorHID.framework
SIMULATOR_FRAMEBUFFER_FRAMEWORK=/Library/Developer/PrivateFrameworks/CoreSimulator.framework/Resources/Platforms/iphoneos/Library/PrivateFrameworks/SimFramebuffer.framework/SimFramebuffer
SIMULATOR_AUDIO_DEVICES_PLIST_PATH=<device>/data/var/run/com.apple.coresimulator.audio.plist
SIMULATOR_AUDIO_SETTINGS_PATH=<device>/data/var/run/simulatoraudio/audiosettings.plist
SIMULATOR_MEMORY_WARNINGS=<device>/data/var/run/memory_warning_simulation
SIMULATOR_CAPABILITIES=/Library/Developer/CoreSimulator/Profiles/DeviceTypes/iPhone 18 Pro.simdevicetype/Contents/Resources/capabilities.plist
SIMULATOR_BOOT_TIME=1795184971
IOS_SIMULATOR_SYSLOG_SOCKET=/private/var/tmp/com.apple.CoreSimulator.SimDevice.<udid>/syslogsock
XPC_SIMULATOR_LAUNCHD_NAME=com.apple.CoreSimulator.SimDevice.<udid>
XPC_SERVICE_NAME=UIKitApplication:com.iosim.recon[d982][rb-legacy]
XPC_FLAGS=0x0
HOME=<device>/data/Containers/Data/Application/<app-uuid>
TMPDIR=<device>/data/Containers/Data/Application/<app-uuid>/tmp
CFFIXED_USER_HOME=<device>/data/Containers/Data/Application/<app-uuid>
_DYLD_CLOSURE_HOME=<device>/data/Containers/Data/Application/<app-uuid>
PATH=<RuntimeRoot>/usr/bin:<RuntimeRoot>/bin:<RuntimeRoot>/usr/sbin:<RuntimeRoot>/sbin:<RuntimeRoot>/usr/local/bin
```

`simctl launch --help` documents `--arch x86_64|arm64`, `--console`,
`--console-pty`, `--stdout/--stderr`, and `SIMCTL_CHILD_*` environment
forwarding. The latter is mirrored by `iosimctl`.

## Host framework locations

`CoreSimulator.framework` is not inside Xcode; it is a system private
framework referenced by the environment:

```
/Library/Developer/PrivateFrameworks/CoreSimulator.framework/
  Resources/Platforms/iphoneos/Library/Frameworks/SimulatorHID.framework
  Resources/Platforms/iphoneos/Library/PrivateFrameworks/SimFramebuffer.framework
/Library/Developer/CoreSimulator/Profiles/DeviceTypes/*.simdevicetype
/Library/Developer/CoreSimulator/Devices/<udid>/data
```

`SimulatorKit.framework` was found inside Xcode:

```
/Applications/Xcode_27.app/Contents/SharedFrameworks/SimulatorKit.framework/Versions/A/SimulatorKit
  Mach-O 64-bit dynamically linked shared library arm64e
```

(Note the runner image carries both `Xcode_27.app` and `Xcode_27.1.app`;
`xcode-select` points at 27.1.)

## Reproducing

The workflows are `workflow_dispatch` only and upload a tarball artifact:

- `recon-runner/.github/workflows/recon.yml` — runtime/toolchain inventory and
  test-binary builds (first pass, watchOS runtime by accident).
- `recon-runner/.github/workflows/recon-ios.yml` — targets the iOS runtime by
  parsing `simctl runtime list -j`, boots an iOS device, installs and launches
  a Foundation app, and captures the environment/process/service state.

Run artifacts from this session:

- `ios-sim-recon` run `44753098912`
- `ios-sim-recon-ios` run `44753759820`
