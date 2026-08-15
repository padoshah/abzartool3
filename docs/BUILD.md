# Build guide

## Tool versions

- Flutter stable **3.29.3** (Dart included)
- Java 17, Android SDK, NDK 27.0.12077973, CMake 3.22.1
- Windows 10/11 x64, Visual Studio 2022 Desktop development with C++, Windows 10/11 SDK
- CMake 3.22+ and a C++20 compiler for native host tests
- Inno Setup 6 only for packaging

## Bootstrap

```bash
flutter --version
flutter pub get
flutter gen-l10n
./tool/gen_bindings.sh
dart format .
flutter analyze
flutter test
```

`ffigen` reads only `native/include/abzar/abzar_api.h`; review generated ABI changes carefully.

## Native Linux proof build

```bash
sudo apt-get install cmake ninja-build zlib1g-dev libfreetype-dev libharfbuzz-dev libqpdf-dev libopencv-core-dev libopencv-imgproc-dev libtesseract-dev libleptonica-dev
cmake -S native -B native/build -G Ninja -DABZAR_BUILD_TESTS=ON
cmake --build native/build
ctest --test-dir native/build --output-on-failure
```

If zlib is not installed, CMake fetches pinned zlib 1.3.1. Network access is required only during dependency resolution; app runtime remains offline.

## Android

Create `android/local.properties` with your SDK and Flutter paths (Flutter normally does this). Never commit it.

```bash
flutter build apk --debug
flutter build apk --release
flutter build apk --release --split-per-abi
```

Gradle invokes the one native CMake project for `armeabi-v7a`, `arm64-v8a`, and `x86_64`, and applies 16 KiB maximum page alignment. A release build needs either ignored `android/key.properties` or the four environment variables described in `SECURITY.md`.

## Windows

From a Developer PowerShell for VS 2022:

```powershell
flutter config --enable-windows-desktop
flutter pub get
flutter build windows --release
cmake -S native -B native/build-windows -A x64 -DABZAR_BUILD_TESTS=ON
cmake --build native/build-windows --config Release
ctest --test-dir native/build-windows -C Release --output-on-failure
```

The Windows top-level CMake also builds and installs `abzar_core.dll` next to `abzarfile.exe`. Do not copy a separately configured DLL over the bundle.

## Validation

```bash
dart run tool/verify_outputs.dart path/to/out.pdf path/to/out.docx
```

The validator checks PDF framing/xref/trailer, OOXML ZIP and required part names, image magic/chunks, and text/HTML encodings. Native tests execute TXT conversions and semantic OOXML round trips.

## Optional codecs

`ABZAR_ENABLE_OCR=ON` is reserved for the Tesseract/Leptonica module. English and Persian trained data is bundled. Until Tesseract/Leptonica native wiring is enabled, OCR-required pairs return `ABZ_ERROR_OCR_UNAVAILABLE` and never emit empty output.
