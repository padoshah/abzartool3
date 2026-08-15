# AbzarFile development guide

This guide documents commands and constraints present in the current repository. Run commands from the repository root unless noted.

## 1. Supported development targets

- Flutter application: Android and Windows.
- Native engine host tests: Linux and Windows.
- No iOS, macOS, web or Flutter Linux host exists in this checkout.

## 2. Toolchain versions

Repository constraints and CI pins:

- Flutter CI pin: **3.29.3** (`.github/workflows/*.yml`).
- `pubspec.yaml`: Flutter `>=3.24.0`; Dart `>=3.5.0 <4.0.0`.
- Java: 17.
- Android Gradle Plugin: 8.7.3.
- Kotlin plugin: 2.1.0.
- Gradle distribution: 8.10.2.
- Android release workflow installs CMake 3.22.1, NDK 27.0.12077973 and build-tools 35.0.0.
- Native CMake minimum: 3.22; C++20.
- Windows: Visual Studio 2022 C++ desktop workload and Windows SDK.
- Inno Setup 6 for installer packaging.

Use Flutter 3.29.3 when reproducing CI. A newer stable Flutter may change Gradle, generated Windows files, plugins or analyzer output.

## 3. Initial setup

```bash
flutter --version
flutter doctor -v
flutter pub get
flutter gen-l10n
./tool/gen_bindings.sh
```

Important current-state notes:

- `pubspec.lock` is absent. `flutter pub get` will create it. Because this is an application, review and commit it once dependency resolution is known-good.
- `lib/app/l10n/app_localizations.dart` is absent until `flutter gen-l10n` runs.
- ffigen rewrites tracked `lib/core/native/abzar_bindings.g.dart`; review that diff with every ABI change. Linux CI regenerates it and fails when the tracked file is stale.

There is no `.env` configuration and no application API key. Never create a committed secret file.

## 4. Native prerequisites

Ubuntu CI installs:

```bash
sudo apt-get update
sudo apt-get install -y \
  cmake ninja-build zlib1g-dev \
  libtesseract-dev libleptonica-dev tesseract-ocr-eng tesseract-ocr-fas \
  libopencv-core-dev libopencv-imgproc-dev libqpdf-dev \
  libfreetype-dev libharfbuzz-dev
```

CMake can fetch several dependencies when system packages are absent. This requires access to GitHub/release assets and can consume significant time/disk. See `native/CMakeLists.txt` and `docs/THIRD_PARTY.md` for exact versions.

Native feature options:

```text
ABZAR_BUILD_TESTS=ON
ABZAR_ENABLE_OCR=OFF          # Linux CI explicitly sets ON
ABZAR_ENABLE_CRYPTO=ON
ABZAR_ENABLE_WEBP=ON
ABZAR_ENABLE_TIFF=ON
ABZAR_ENABLE_OPENCV=ON
ABZAR_ENABLE_TEXT_SHAPING=ON
ABZAR_USE_SYSTEM_ZLIB=ON
```

## 5. Generate sources

Localization:

```bash
flutter gen-l10n
```

Inputs are `lib/app/l10n/app_en.arb` and `app_fa.arb`; generated output is configured by `l10n.yaml`.

FFI:

```bash
./tool/gen_bindings.sh
# equivalent: dart run ffigen --config ffigen.yaml
```

Never manually patch generated binding signatures. Change `native/include/abzar/abzar_api.h`, regenerate, then update wrappers/tests.

## 6. Run and debug

### Android

Create/let Flutter create `android/local.properties` with local SDK/Flutter paths; it is local-only.

```bash
flutter devices
flutter run -d <android-device-id>
```

The app uses external native CMake. First builds may fetch and compile large dependencies for the selected ABI.

Useful inspection:

```bash
flutter run --verbose
./android/gradlew -p android app:externalNativeBuildDebug --info
```

Test all release ABIs before release, not just the attached device.

### Windows

Use a Visual Studio 2022 Developer PowerShell:

```powershell
flutter config --enable-windows-desktop
flutter devices
flutter run -d windows
```

`windows/CMakeLists.txt` has AbzarFile-specific native subdirectory/install logic and the runner has mutex/icon/version customization. A non-signing Windows CI job now exercises the host; compare against Flutter 3.29.3 templates before changing generated runner structure.

### Native engine only

```bash
cmake -S native -B native/build -G Ninja -DABZAR_BUILD_TESTS=ON
cmake --build native/build --config Release
ctest --test-dir native/build -C Release --output-on-failure
```

To require optional Linux features as CI does:

```bash
cmake -S native -B native/build-ci -G Ninja \
  -DABZAR_BUILD_TESTS=ON -DABZAR_ENABLE_OCR=ON
cmake --build native/build-ci
ABZAR_REQUIRE_FULL_FEATURES=1 \
  ctest --test-dir native/build-ci --output-on-failure
```

For FFI loading in an ad-hoc Linux Flutter/Dart process, ensure `libabzar_core.so` is discoverable (for example via the process library path). There is no Flutter Linux runner in this repo.

## 7. Formatting and static analysis

```bash
dart format --set-exit-if-changed lib test integration_test tool
flutter analyze
```

`analysis_options.yaml` enables strict casts/inference/raw types and additional style rules. The current code contains compressed one-line files; formatting may produce a large first diff. Keep formatting changes isolated from behavior when possible.

CI currently runs `dart format --output=none ...`, which parses/formats to no output but does not enforce a clean formatting diff. Treat local `--set-exit-if-changed` as the stronger check.

## 8. Tests

Dart tests:

```bash
flutter test
```

Integration test on a configured device/platform:

```bash
flutter test integration_test/app_test.dart -d <device-id>
```

Native:

```bash
ctest --test-dir native/build --output-on-failure
```

Configuration/output validator:

```bash
dart run tool/verify_outputs.dart
# Add generated paths to structurally inspect outputs:
dart run tool/verify_outputs.dart path/to/file.pdf path/to/file.docx
```

Existing coverage is limited. The conversion matrix has 189 enabled pairs, while native tests cover a smaller generated subset and skip OCR-required image-to-text pairs in the matrix loop. Add fixtures before claiming broad fidelity.

## 9. Build commands

### Android debug

```bash
flutter build apk --debug
```

### Android release development build

A signed production release requires ignored local signing properties or CI secrets. Do not create a test keystore in the repository.

```bash
flutter build apk --release
flutter build apk --release --split-per-abi
```

Primary expected output before CI renaming is `build/app/outputs/flutter-apk/app-release.apk`. Split names are consumed by `.github/workflows/android-release.yml`.

### Windows release

```powershell
flutter build windows --release
```

Expected bundle directory used by Inno Setup:

```text
build/windows/x64/runner/Release/
```

Compile installer after a successful Windows build:

```powershell
& "${env:ProgramFiles(x86)}\Inno Setup 6\ISCC.exe" "/DMyAppVersion=1.0.0" installer\abzarfile.iss
```

Unsigned local builds are development artifacts only.

## 10. Environment and signing configuration

Local Android signing can be provided through ignored `android/key.properties`/root `key.properties` or these environment names read by Gradle:

- `ANDROID_KEYSTORE_PATH`
- `ANDROID_KEYSTORE_PASSWORD`
- `ANDROID_KEY_ALIAS`
- `ANDROID_KEY_PASSWORD`

GitHub release workflows use organization secrets documented in `RELEASE.md`; never put values in source or docs.

No Windows signing file belongs in the repository. CI decodes a temporary PFX under `RUNNER_TEMP`.

## 11. Debugging data flows

### Conversion failure

1. Check `QueueItem.error` and `NativeException.code`.
2. Trace `JobSpec.encode()` → `JobIsolate._entry()` → `abz_job_run`.
3. Check importer/exporter dispatch for the extension.
4. Inspect `abz_build_features()` if behavior depends on PDFium/qpdf/OCR/OpenCV/HarfBuzz.
5. Reproduce with `native/tests/core_tests.cpp` or a small native test before changing UI.

### Platform-open failure

- Android: inspect `MainActivity.materializeIntent`, URI permission, cache copy and method channel.
- Windows: inspect command-line arguments and Inno association command.

### Update failure

- Confirm `UpdateService.endpoint` points to the actual release repository.
- Confirm workflow and updater asset names match `test/version_contract_test.dart`.
- Verify checksum file and platform signature separately.

## 12. Common problems

### Missing localization class

```bash
flutter gen-l10n
```

### ffigen changes break wrappers

Regenerate after changing `abzar_api.h`, then update `FfiBridge`, `JobIsolate`, and `NativeOperations` to the generated signatures. Never preserve stale hand-written bindings.

### Native library cannot be loaded

- Android: inspect APK `lib/<abi>/libabzar_core.so` entries.
- Windows: confirm `abzar_core.dll` and PDFium runtime dependencies are next to `abzarfile.exe`.
- Linux test process: configure runtime library path.

### OCR returns unavailable

OCR is compile-gated. `assets/ocr` data alone does not prove Tesseract linkage or runtime data discovery. Confirm CMake feature output and trained-data path on the target platform.

### Long/failed native configure

CMake downloads PDFium binaries and may source-build qpdf, OpenCV, Mbed TLS, FreeType, HarfBuzz, libwebp, libtiff and zlib. Check network policy, disk, architecture selection and upstream archive availability.

### Windows CMake diverges from the Flutter template

The stale mustache hook was removed, but the file also contains required AbzarFile native-engine installation. If Windows configuration fails, compare against a temporary Flutter 3.29.3 generated project and apply only the necessary template delta; preserve the native subdirectory, DLL installation, runner identity and mutex.

### History rows fail after `JobSpec` changes

`HistoryService.list` reconstructs a subset of JSON fields. Add optional/default handling for old rows before making a new field required.

More operational symptoms are listed in `docs/TROUBLESHOOTING.md`.

## 13. Before reporting completion

```bash
git diff --check
git status --short
git diff
```

Then report separately:

- commands that passed;
- commands that failed and their exact failure class;
- commands not run due to missing toolchain/platform;
- behavior still capability-gated or untested.

Do not use the existence of a screen, CMake target, workflow, or conversion-matrix entry as test evidence.
