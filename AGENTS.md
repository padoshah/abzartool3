# AGENTS.md — AbzarFile repository handover

This file is the primary operating manual for any AI coding agent working in this repository. Read it before editing code. The repository is authoritative; do not infer behavior from product aspirations or old conversations.

## 1. Project overview and current status

AbzarFile is an offline-first Flutter application for Android and Windows. It presents conversion, compression, merge/split, text extraction, scanning, visible PDF signatures, PDF object/security tools, format-specific editing screens, history, settings, and a consent-based GitHub Releases updater.

The heavy conversion layer is C++20 behind a pure C ABI and `dart:ffi`. Its central design is importer → `Document` model → exporter. The product does not use a cloud conversion API and has no user authentication. The only HTTP integration in the Dart code is the update endpoint in `lib/features/updater/update_service.dart`.

Supported application platforms in the checkout:

- Android: package `com.padoshah.abzarfile`, minSdk 23, ABIs `armeabi-v7a`, `arm64-v8a`, and `x86_64`.
- Windows: x64 Flutter runner, executable `abzarfile.exe`, native library `abzar_core.dll`, Windows 10/11 installer.
- Linux: no Flutter host is present; Linux is used only as a native-engine development/test host.

Current version: `1.0.0+10000` in `pubspec.yaml`.

**Status warning:** this is a broad development repository, not a proven production release. `pubspec.lock` and generated localization output are absent. The complete Flutter/Android/Windows build has not been demonstrated in this checkout. Many UI and native paths exist, but capability entries and screens are not proof of full fidelity. Report tests honestly and do not tag a release merely because CMake/workflow wiring exists.

## 2. Start every request with this workflow

```text
USER REQUEST
    ↓
Read AGENTS.md and git status
    ↓
Search the actual route/feature/service/native symbols
    ↓
Read the relevant implementation and tests
    ↓
Identify generated files and platform impact
    ↓
Write a small implementation plan
    ↓
Make the smallest focused change
    ↓
Format → analyze → unit/native tests → affected platform build
    ↓
Review git diff and secret scan
    ↓
Report changed files, commands run, failures, and unverified behavior
```

Never begin by replacing an implementation you have not inspected.

## 3. Architecture and placement

### Flutter layers

- `lib/main.dart`: Flutter binding initialization, seven-day temporary-file cleanup, root `ProviderScope`, and guarded error zone.
- `lib/app/app.dart`: `MaterialApp.router`, dynamic color, settings-driven theme/locale, update bootstrap, and OS-open bootstrap.
- `lib/app/router.dart`: the single `GoRouter` route table. Add routes here; do not introduce a second router.
- `lib/app/l10n/`: English and Persian ARB sources. `app_localizations.dart` is generated and currently absent.
- `lib/app/theme/`: Material 3 theme primitives. `AppTheme` uses Noto Sans, Noto Sans Arabic fallback, dynamic color, and compact Windows density.
- `lib/core/models/`: immutable Dart boundary models (`FileEntry`, `JobSpec`, `JobReport`, format/capability models).
- `lib/core/services/`: file selection/open/share, capability registry, Drift-backed history, shared-preference settings, temporary storage, OS-open handling, and basic permission queries.
- `lib/core/native/`: generated bindings, native library loader, typed errors, isolate execution, FFI memory handling, and direct native operation wrappers.
- `lib/features/<feature>/`: navigable workflows. Most screens use local `StatefulWidget` state; converter/settings/format registry use Riverpod.
- `lib/features/viewers/<format>/`: separate PDF, DOCX, XLSX, PPTX, TXT, JSON, HTML, and image screens.
- `lib/shared/widgets/`: reusable shell/scaffold/card presentation only.

### State and dependency patterns

The repository uses Riverpod, not Bloc:

- `settingsProvider`: `AsyncNotifierProvider` in `lib/core/services/settings_service.dart`.
- `formatRegistryProvider`: `FutureProvider` in `lib/core/services/format_registry.dart`.
- `convertControllerProvider`: `StateNotifierProvider` in `lib/features/convert/convert_controller.dart`.

Most other screens instantiate stateless service objects directly and keep transient UI state in their widget state. Follow the local feature pattern; do not introduce a new global state framework to “clean up” one feature.

There is no general dependency-injection container beyond Riverpod. Services such as `FileService`, `StorageService`, `HistoryService`, and `UpdateService` are created directly where used.

### Native layers

- `native/include/abzar/abzar_api.h`: only public ABI. Symbols are prefixed `abz_`; errors are numeric; jobs are opaque.
- `native/src/api/`: exception-catching C ABI adapter.
- `native/src/core/doc_model.h`: canonical `Document → Section → Page → Block` model and style/image/sheet types.
- `native/src/importers/importer.cpp`: input dispatch.
- `native/src/exporters/exporter.cpp`: output dispatch.
- `native/src/ooxml/`: OPC content types, relationships, XML checks, and package handling.
- `native/src/render/`: canvas, layout/rasterization, font lookup, HarfBuzz shaping, and subsetting.
- `native/src/ops/`: conversion, compression, merge/split, OCR/scan, encryption, and PDF operations.
- `native/src/util/`: atomic filesystem writes, image codecs, strings, and ZIP.
- `native/CMakeLists.txt`: shared native build for Linux tests, Android NDK, and Windows MSVC.
- `native/tests/core_tests.cpp`: dependency-aware structural native test executable.

Importers produce `Document`; exporters consume it. Keep format-specific parsing out of widgets and keep UI types out of native code.

### Data flow

```text
Screen / ConvertController
    → FileService + StorageService
    → JobSpec JSON
    → JobIsolate (SendPort progress and cancellation)
    → abzar_api.h C ABI
    → importer → Document → layout/exporter
    → atomic output + JobReport
    → UI result + Drift history
```

Direct document tools use `NativeOperations`, which executes synchronous FFI calls inside `Isolate.run`.

### Storage and network

- History: SQLite at the platform application-support path through Drift (`HistoryService`). The table is created in `beforeOpen`; no generated Drift schema exists.
- Trivial settings: `shared_preferences` (`SettingsController` and update snooze/skip flags).
- Job output/temp: `StorageService`, under the platform temporary directory unless the user selected an output directory.
- Update network: hardcoded latest-release endpoint in `UpdateService.endpoint`; assets are resumed/retried and SHA-256 checked.
- Authentication: none. Do not add login/token flows unless explicitly requested.

## 4. Development conventions

- Dart files: `lower_snake_case.dart`; types: `UpperCamelCase`; members: `lowerCamelCase`.
- C++ files: `snake_case.{h,cpp}`; C ABI symbols: `abz_*`; C++ standard: C++20.
- Put feature UI/state in its existing `lib/features/<feature>` folder.
- Put cross-feature models/services in `lib/core`, and format-neutral widgets in `lib/shared/widgets`.
- Use the existing `GoRouter` and Riverpod providers. Do not add another router/state library casually.
- All user-facing UI strings belong in both `lib/app/l10n/app_en.arb` and `app_fa.arb`. Preserve RTL behavior.
- Use `AppTheme` and shared widgets before creating one-off design constants.
- Native errors must become `AbzErrorCode`, then `NativeException`; update `error_localizer.dart` for user-facing handling.
- Never let a C++ exception, STL type, or allocator ownership cross the ABI. Engine allocations are freed with `abz_free`.
- Long native work must stay off the UI isolate. Preserve cancellation/progress behavior in `job_isolate.dart`.
- Never modify the source document during conversion/tool operations. Native output goes through `native/src/util/fs.cpp` atomic writes.
- Preserve unknown OOXML parts and same-format package bytes where the current model does so; do not silently lower fidelity.
- Check `assets/config/conversion_matrix.json` before advertising a format. It currently has 21 sources × 9 targets and all entries enabled, including 30 OCR-gated entries; this is a declared capability set, not proof that every pair is fully tested.

The repository has strict analyzer settings in `analysis_options.yaml`. Existing Dart formatting is inconsistent in places; new or touched Dart code should still be formatted normally rather than copying compressed one-line style.

## 5. Adding a feature

1. Inspect similar screens and native operations with `rg`/`grep`.
2. Add the screen/controller under `lib/features/<feature>/`.
3. Add immutable shared models under `lib/core/models` only if multiple layers need them.
4. Add reusable I/O in `lib/core/services`; keep feature-specific orchestration in the feature.
5. Add the route to `lib/app/router.dart` and navigation entry to the relevant home/toolbox screen.
6. Add every visible string to both ARB files and run `flutter gen-l10n`.
7. For native work, append ABI declarations to `abzar_api.h`, catch failures in `abzar_api.cpp`, regenerate bindings, and add an isolate-safe wrapper in `NativeOperations` or `FfiBridge`.
8. Reuse `FeatureScaffold`, `FeatureCard`, `EditorControls`, theme values, `FileService`, and `StorageService` where applicable.
9. Add Dart tests in `test/`; add C++ structural tests in `native/tests/core_tests.cpp`; use `integration_test/` for plugin/platform flows.
10. Test Android and Windows when the change touches FFI, file picking, intents, camera, updater, installer, or desktop behavior.

### Adding a format

A format is not complete until all applicable items exist:

1. Importer and exporter dispatch.
2. `Document` mapping and typed errors.
3. Matrix format/pair entries and options.
4. MIME/Android intent/Windows association updates.
5. Fixture(s), semantic expectations, corrupt-input test, structural validator.
6. CMake dependency plus complete license notice where needed.
7. UI labels/options and docs updates.
8. Tests that open the output as the target format; never accept extension renaming.

## 6. Modifying an existing feature safely

- Read the screen, controller/provider, service, native wrapper, ABI entry, implementation, and test before editing.
- Trace all call sites with repository search.
- Preserve public ABI ordering/ownership and existing route paths.
- Do not alter conversion-matrix fidelity or enablement without matching implementation and tests.
- Keep storage migrations backward-compatible; history JSON must remain readable when `JobSpec` evolves.
- Treat Android manifest/Gradle, Windows CMake/runner resources, Inno AppId, update filenames, and workflow secrets as coupled contracts.
- Make one behavioral change at a time, review `git diff`, and do not overwrite unrelated working-tree changes.

## 7. Dependency management

Add Flutter packages to `pubspec.yaml`, run `flutter pub get`, and review/commit the resulting `pubspec.lock` for this application repository. The lockfile is currently absent; do not pretend dependency resolution is reproducible until it is generated and reviewed.

Important dependencies that should not be replaced casually:

- `flutter_riverpod`: application state.
- `go_router`: route table.
- `drift` + `sqlite3_flutter_libs`: history persistence.
- `ffi` + `ffigen`: C ABI.
- `file_picker`, `path_provider`, `open_filex`, `share_plus`: file lifecycle.
- `camera`/`image_picker` and `image`: scan/image workflows.
- `http`, `crypto`, `package_info_plus`: updater.
- `desktop_drop`, `dynamic_color`: Windows drop and adaptive theme.

Native dependencies are resolved in `native/CMakeLists.txt`: zlib, Mbed TLS, FreeType, HarfBuzz, OpenCV, PDFium binaries, qpdf, Tesseract (only when `ABZAR_ENABLE_OCR=ON` and discoverable), libwebp, libtiff, and vendored stb. Preserve pinned versions and `docs/THIRD_PARTY.md`/license files. Evaluate Android ABI support, Windows runtime packaging, license, binary size, and CI duration before upgrades.

## 8. Testing and build commands

From the repository root:

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
```

Configuration/output contract:

```bash
dart run tool/verify_outputs.dart
```

Android:

```bash
flutter build apk --debug
flutter build apk --release
flutter build apk --release --split-per-abi
```

Windows (VS 2022 developer shell):

```powershell
flutter config --enable-windows-desktop
flutter build windows --release
```

Known testing limitations are detailed in `DEVELOPMENT.md`. Do not claim Android/Windows success from a Linux fallback compile.

## 9. Git workflow for agents

1. Run `git status --short` and `git branch --show-current`.
2. Fetch/pull only when allowed by the host environment; respect any session-fixed branch.
3. Read implementation and tests before planning.
4. Create a focused branch when normal repository policy permits it.
5. Preserve unrelated local changes.
6. Make the smallest safe patch.
7. Run formatter, analyzer, relevant unit/native tests, and affected platform build.
8. Review `git diff --check`, `git diff`, and `git status`.
9. Scan for secrets and generated/build artifacts.
10. Commit with a specific message; create a PR where applicable.
11. Report exact commands and distinguish passed, failed, and not run.

## 10. Safety rules

- Never delete or replace functionality without explicit justification.
- Never perform broad architecture rewrites for a narrow request.
- Never replace dependencies merely because a newer alternative exists.
- Never expose or commit API keys, tokens, passwords, signing files, certificates, private keys, `.env`, or `key.properties`.
- Never print signing environment values in CI.
- Never change the permanent Inno AppId `7F452E1A-24D8-4E36-AE2C-8CD6E2280B31` casually.
- Never change Android package ID, release asset names, updater endpoint, ABI list, or signing scheme without tracing every coupled file.
- Never hand-edit generated localization output or `lib/core/native/abzar_bindings.g.dart`; regenerate it.
- Never claim a screen, dependency block, or workflow proves a feature works.
- Never tag a production release while CI/platform builds are red or unverified.

## 11. Generated files and ignored outputs

Normally generated; do not hand-edit:

- `lib/app/l10n/app_localizations.dart` and related localization output (`flutter gen-l10n`); currently absent.
- `lib/core/native/abzar_bindings.g.dart` (`./tool/gen_bindings.sh`); tracked.
- `windows/flutter/ephemeral/`, generated plugin registrants, Android/Windows build trees.
- `.dart_tool/`, `build/`, coverage, CMake build directories, installer `Output/`, APK/EXE/DLL/SO artifacts.
- `android/local.properties`, `android/key.properties`, and root `key.properties`.
- `abzarfile-v*-source.zip` from `tool/package_zip.sh`.

`pubspec.lock` is generated by `flutter pub get`, but for this application it should normally be reviewed and committed. It is currently missing.

## 12. Discovered technical risks

- Windows CMake includes custom native-engine installation and runner mutex behavior. The stale Flutter mustache hook was removed, but a successful Windows CI run is still required before treating the host as verified.
- Full Flutter analysis and platform builds are not evidenced in the checkout. CI now regenerates ffigen output and rejects a stale tracked binding.
- CMake fetches/builds a large dependency graph and downloads architecture-specific PDFium binaries; network availability, upstream packaging, CI time, and 32-bit Android compatibility are high risk.
- OCR defaults OFF in CMake. Linux CI explicitly enables it; Android/Windows builds do not currently prove Tesseract is linked or trained-data lookup works.
- `UpdateService.endpoint` is hardcoded to `padoshah/abzartool3`; forks or organization moves must update and test it together with release assets.
- The capability matrix enables every declared pair; many pairs are OCR-gated or fidelity-limited, and tests do not cover all 189 pairs with fixtures.
- Fixtures cover only TXT, CSV, JSON, HTML, and PNG—not every importer.
- PDFium/qpdf/OpenCV/HarfBuzz code is capability-gated; a fallback build may return typed unsupported errors while still compiling.
- Android release installs NDK `27.0.12077973`, but Gradle uses `flutter.ndkVersion`; verify they resolve to the same NDK for the pinned Flutter version.
- Native job cancellation crosses isolate boundaries by pointer address. Preserve handle lifetime and do not free jobs before cancellation messages settle.
- History deserialization explicitly reconstructs older `JobSpec` fields; new required fields need backward-compatible defaults.
- The Windows updater compares the candidate signer subject with the installed executable. Unsigned development builds cannot validate production updates.
- The repository contains no iOS, macOS, web, or Flutter Linux host; do not document or release those platforms.
