# Same-app parity check: real simulator vs iosim

The strongest check we have is one unmodified app source compiled by Apple's
toolchain, run twice:

1. **arm64** app on the real iPhone 18 Pro / iOS 27.2 simulator, via the
   `same-app` GitHub Actions workflow on an `xcode-27` runner.
2. **x86_64** slice from the *same Apple clang invocation* on `demo/HelloSimApp.m`,
   run natively under `iosim` on Linux with `DYLD_ROOT_PATH` pointing at our
   reimplemented UIKit/Foundation.

No source or layout difference exists between the two; only the CPU
architecture and the framework provider differ.

## Reproduce

On the runner (`.github/workflows/same-app.yml`):

```sh
SDK=$(xcrun --sdk iphonesimulator --show-sdk-path)
CFLAGS="-mios-simulator-version-min=18.0 -isysroot $SDK -O1 -fno-objc-arc \
        -Wno-deprecated-declarations -I demo"
xcrun clang -arch arm64  $CFLAGS -framework UIKit -framework Foundation \
    demo/HelloSimApp.m -o HelloSim_arm64
xcrun clang -arch x86_64 $CFLAGS -framework UIKit -framework Foundation \
    demo/HelloSimApp.m -o HelloSim_x86_64
```

The workflow installs `HelloSim_arm64` in a `HelloSim.app` bundle, launches it,
and saves `real-sim.png` (1206×2622). It also uploads `HelloSim_x86_64`, the
runtime font files, and logs.

Locally:

```sh
./tools/build_runtime.sh
# fonts extracted from the iOS 27 runtime (not redistributed here)
export IOSIM_FONT_DIR=$PWD/build/fonts/ios
DYLD_ROOT_PATH=$PWD/runtime IOSIM_FONT_DIR=$PWD/build/fonts/ios \
  SIMULATOR_MAINSCREEN_WIDTH=1206 SIMULATOR_MAINSCREEN_HEIGHT=2622 \
  SIMULATOR_MAINSCREEN_SCALE=3.0 IOSIM_SCREENSHOT_PATH=$PWD/build/iosim.png \
  ./build/iosim-run path/to/HelloSim_x86_64
```

## Result

Measured over the full 1206×2622 frame:

| Metric | Value |
|---|---|
| Mean absolute channel error | **0.79 / 255** |
| Pixels with max-channel error > 8 | **0.82 %** |
| Pixels with max-channel error > 24 | **0.66 %** |
| Layout bounding boxes | equal within 1 px (text baselines, card, button, rows) |
| Background / card / subtitle / footer colors | byte-identical |
| `systemBlue` in iOS 27 dark mode | `(0, 145, 255)` — matched |

The remaining difference is confined to glyph-edge anti-aliasing and the
sub-pixel shape of the Wi-Fi/battery status icons, plus a one-pixel baseline
offset on one label.

## What made the match possible

- **Mach-O / dyld**: the x86_64 slice still uses chained fixups, `LC_LOAD_DYLIB`
  references to `UIKit.framework` / `Foundation.framework`, libSystem and
  libobjc; `DYLD_ROOT_PATH` substitutes our dylibs at the canonical paths.
- **Objective-C**: classes, protocols and categories emitted by Apple clang are
  registered from `__objc_classlist`; `class_ro_t`, property setters
  (`objc_setProperty_nonatomic`), `objc_opt_class`, ivar offset realization and
  the `objc_msgSend` trampolines all had to match Apple's ABI.
- **Scene lifecycle**: iOS 27 no longer tolerates a legacy `UIApplicationMain`
  app delegate window. It traps in
  `UIApplicationEvaluateRuntimeIssueForNoSceneLifecycleAdoption`. The app now
  declares a `UIApplicationSceneManifest`, a `SceneDelegate`, and a
  configuration method; UIKit-lite creates `UIWindowScene`, `UISceneSession`
  and drives `scene:willConnectToSession:options:`.
- **Text**: the runtime ships `SFUI.ttf`, a variable font with `wght`, `opsz`,
  `wdth` and `GRAD` axes. `iosim` loads it with FreeType, sets those axes per
  label, applies system-font tracking measured against UIKit, and draws into
  the software framebuffer at 3×.
- **Colors and chrome**: UIKit's dark `systemBlue` and the status bar
  (time, cellular placeholders, Wi-Fi, battery) were measured from the real
  screenshot. The captured frame contains no Dynamic Island or home indicator,
  so iosim does not draw them either.

## Limitations

This is parity for one app and the UIKit subset it uses: `UIView`, `UILabel`,
`UIWindow`, `UIWindowScene`, `UISceneConfiguration`, `UIColor`, `UIFont`,
`UIScreen`, `CALayer.cornerRadius`, `UIApplication` and `UIApplicationMain`.
Scrolling, layout constraints, touch/event routing, CoreAnimation beyond a
corner radius, CoreText shaping beyond Latin text, and the rest of the
framework surface remain roadmap work.
