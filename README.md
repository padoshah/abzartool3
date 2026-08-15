# AbzarFile

Offline-first Flutter file conversion, document tools and format-specific editing surfaces for Android and Windows.

[![CI](https://github.com/padoshah/abzartool3/actions/workflows/ci.yml/badge.svg)](https://github.com/padoshah/abzartool3/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![Android](https://img.shields.io/badge/Android-23%2B-3DDC84)](DEVELOPMENT.md)
[![Windows](https://img.shields.io/badge/Windows-10%2F11%20x64-0078D4)](DEVELOPMENT.md)

## What is in this repository

AbzarFile combines a Material 3 Flutter UI with a C++20 native engine loaded through `dart:ffi`. The engine uses an importer → canonical `Document` → exporter pipeline; conversion is intended to transform content rather than rename extensions. Document processing is local. The only Dart HTTP integration is the consent-based GitHub Releases updater.

Current feature areas:

- matrix-driven conversion queue with progress, cancellation, retry and history;
- format-aware compression and same-type merge/split surfaces;
- text extraction and optional OCR path;
- camera/image scanner processing with native filter/perspective hooks;
- visible PDF signature capture/flattening;
- PDF repair, security, object, form/outline and annotation operations;
- dedicated PDF, DOCX, XLSX, PPTX, TXT, JSON, HTML and image screens;
- English/Persian localization, RTL, light/dark/system theme;
- Android open intents, Windows drag/drop and installer file associations;
- in-app update checks with checksums and platform signature enforcement.

The runtime matrix at `assets/config/conversion_matrix.json` declares 21 input formats and 9 output formats (189 enabled pairs, including OCR-gated pairs). **A matrix entry, screen or CMake dependency is not proof of production fidelity.** See [Current status](#current-status) and `docs/CONVERSION_MATRIX.md`.

## Supported application platforms

| Platform | Configuration |
|---|---|
| Android | minSdk 23; `armeabi-v7a`, `arm64-v8a`, `x86_64`; package `com.padoshah.abzarfile` |
| Windows | x64; Windows 10/11; `abzarfile.exe` plus `abzar_core.dll`; Inno Setup |
| Linux | Native C++ development/tests only; no Flutter Linux runner |

There are no iOS, macOS or web hosts in this repository.

## Current status

This checkout is a development implementation, not a verified production release.

Known release blockers/uncertainties:

- `pubspec.lock` has not been generated/committed.
- localization output is generated and currently absent.
- full Flutter analysis/tests and Android/Windows builds are not evidenced in the repository.
- a non-signing Windows CI build gate is configured, but no successful run is evidenced in this checkout.
- OCR defaults off outside the Linux CI configuration; trained data alone does not prove target linkage.
- fixtures and tests do not cover every declared conversion pair.
- several format/editor paths are fidelity-limited and return typed unavailable/validation errors when optional backends or encodings cannot satisfy an operation.

Do not push a production version tag until CI and both platform release builds pass.

## Quick start

Use Flutter **3.29.3** to reproduce CI. Repository constraints are Dart `>=3.5.0 <4.0.0` and Flutter `>=3.24.0`.

```bash
flutter pub get
flutter gen-l10n
./tool/gen_bindings.sh
dart format --set-exit-if-changed lib test integration_test tool
flutter analyze
flutter test
```

Native host tests:

```bash
cmake -S native -B native/build -DABZAR_BUILD_TESTS=ON
cmake --build native/build --config Release
ctest --test-dir native/build -C Release --output-on-failure
dart run tool/verify_outputs.dart
```

Android:

```bash
flutter run -d <android-device>
flutter build apk --debug
```

Windows (VS 2022 Developer PowerShell):

```powershell
flutter config --enable-windows-desktop
flutter run -d windows
flutter build windows --release
```

See `DEVELOPMENT.md` before attempting platform builds; the native dependency graph is large and Windows configuration has a known template-token risk.

## Architecture summary

```text
Flutter screen
  → local/Riverpod state
  → service + JobSpec
  → worker isolate / FFI
  → C ABI
  → importer → Document → layout/exporter
  → atomic output + JobReport → Drift history
```

Important entry points:

- `lib/main.dart`
- `lib/app/router.dart`
- `lib/features/convert/convert_controller.dart`
- `lib/core/native/job_isolate.dart`
- `native/include/abzar/abzar_api.h`
- `native/src/core/doc_model.h`
- `native/CMakeLists.txt`

Read `ARCHITECTURE.md` for the full technical map and `AGENTS.md` before making changes.

## Configuration and data

- Conversion source of truth: `assets/config/conversion_matrix.json`
- Localization sources: `lib/app/l10n/app_en.arb`, `app_fa.arb`
- Settings: shared preferences
- History: Drift/native SQLite in application support
- Temporary outputs: platform temp `abzarfile/jobs`
- Update endpoint: configured in `lib/features/updater/update_service.dart`
- Native dependencies/licenses: `docs/THIRD_PARTY.md`

No login/authentication system is present.

## CI and releases

- `.github/workflows/ci.yml`: Linux Flutter/native checks and Android debug build.
- `.github/workflows/android-release.yml`: signed universal/split APKs on `v*.*.*`.
- `.github/workflows/windows-release.yml`: signed x64 Inno installer on the same tag.

Version source is `pubspec.yaml`; use:

```bash
dart run tool/set_version.dart vX.Y.Z
```

Signing secret **names** and the exact release process are documented in `RELEASE.md`. Secret values and signing files must never be committed.

## Documentation

- [`AGENTS.md`](AGENTS.md): mandatory AI-agent workflow, conventions and safety rules
- [`ARCHITECTURE.md`](ARCHITECTURE.md): startup, navigation, state, service, native and platform architecture
- [`DEVELOPMENT.md`](DEVELOPMENT.md): prerequisites, generation, run/build/test and troubleshooting
- [`RELEASE.md`](RELEASE.md): versioning, signing, workflows, artifacts and updater contract
- [`docs/CONVERSION_MATRIX.md`](docs/CONVERSION_MATRIX.md): capability/fidelity interpretation
- [`docs/DECISIONS.md`](docs/DECISIONS.md): existing architecture decisions
- [`docs/THIRD_PARTY.md`](docs/THIRD_PARTY.md): native/Flutter dependencies and licenses
- [`SECURITY.md`](SECURITY.md): security and disclosure policy
- [`CONTRIBUTING.md`](CONTRIBUTING.md): contribution checks

## Security and privacy

Source documents are intended to remain on device. Writers use temporary output and atomic rename. Never commit signing material, document passwords, user files or environment secrets. Report vulnerabilities privately as described in `SECURITY.md`.

## License

Project source is MIT licensed. Third-party software and fonts retain their own permissive licenses; see `docs/THIRD_PARTY.md` and `native/third_party/LICENSES/`.
