# AbzarFile architecture

This document describes the architecture present in the current repository. It does not assert that every declared conversion or tool has production fidelity.

## 1. System overview

```text
┌──────────────────────────────── Flutter ────────────────────────────────┐
│ Material 3 screens                                                     │
│   │                                                                    │
│   ├─ local StatefulWidget state                                        │
│   └─ Riverpod: settings, format registry, conversion queue             │
│             │                                                          │
│             ├─ file/storage/history/update services                    │
│             └─ JobSpec / direct operation arguments                    │
└─────────────┬───────────────────────────────────────────────────────────┘
              │ isolate + dart:ffi
┌─────────────▼──────────────────── native C ABI ─────────────────────────┐
│ abzar_api.h → guarded C++ API → job/operation                           │
│                                 │                                       │
│             importer → canonical Document → layout → exporter          │
│                                 │                                       │
│                  QPDF/PDFium/OCR/image/OOXML utilities                  │
└─────────────────────────────────┬───────────────────────────────────────┘
                                  ▼
                         atomic local output
```

The application is offline for document processing. Its only Dart HTTP client is the GitHub Releases updater.

## 2. Directory map

| Path | Actual responsibility |
|---|---|
| `lib/main.dart` | Startup guard, Flutter initialization, stale temp cleanup, root Riverpod scope. |
| `lib/app/` | App composition, routes, localization source, and theme. |
| `lib/core/models/` | Dart file/job/report/format values crossing feature/service boundaries. |
| `lib/core/services/` | File lifecycle, storage, history, settings, format registry, OS-open integration. |
| `lib/core/native/` | Dynamic library loading, generated ABI binding, isolate execution, native wrappers/errors. |
| `lib/features/` | User-facing workflows and their local state. |
| `lib/features/viewers/` | Eight separate format editor/viewer screens plus shared editor controls. |
| `lib/shared/widgets/` | App shell and reusable feature presentation. |
| `native/include/abzar/` | Public, versioned C ABI only. |
| `native/src/core/` | Canonical document model, styles, pages, job/report/error/memory/logging. |
| `native/src/importers/` | Source-file dispatch and parsers. |
| `native/src/exporters/` | Canonical-model serializers. |
| `native/src/ooxml/` | OPC ZIP/content types/relationships/XML support. |
| `native/src/render/` | Layout/raster canvas, font lookup, HarfBuzz shaping/subsetting. |
| `native/src/ops/` | Convert/compress/merge/split, PDF, scan/OCR, signature, annotation and security operations. |
| `native/src/util/` | Atomic files, ZIP, encoding/string and image codecs. |
| `native/tests/` | Native ABI/format structural executable test. |
| `native/third_party/` | Vendored stb/zlib compatibility headers and license notices. |
| `assets/config/` | Runtime conversion matrix loaded by Flutter. |
| `assets/fonts/`, `assets/ocr/` | Bundled font and Tesseract data assets. |
| `android/` | Android host, NDK/CMake/signing, intents, FileProvider and Kotlin channels. |
| `windows/` | Flutter Win32 runner and native CMake inclusion. |
| `installer/` | Inno Setup packaging, file associations and fixed upgrade identity. |
| `.github/workflows/` | Linux CI and separate signed Android/Windows tag workflows. |
| `tool/` | Version, binding, structural validation and source archive scripts. |
| `test/`, `integration_test/`, `fixtures/` | Dart contract tests, one app launch integration test, limited fixtures. |

## 3. Application startup

```text
main()
  → WidgetsFlutterBinding.ensureInitialized()
  → StorageService.cleanOldTemporaryFiles()
  → ProviderScope(AbzarFileApp)
  → settingsProvider read
  → DynamicColorBuilder
  → MaterialApp.router(appRouter)
       ├─ UpdateBootstrap: lifecycle/24-hour update check
       └─ OpenIntentBootstrap: Android method channel / Windows command line
```

`runZonedGuarded` reports uncaught startup/runtime errors to `FlutterError.reportError`; there is no telemetry backend.

### Update bootstrap

`UpdateBootstrap` reads the `updates` and `lastUpdateCheck` shared-preference keys. Background failures are intentionally silent. A found release opens consent UI; skip state is persisted as `skippedUpdateVersion`.

### Open-file bootstrap

- Android: `MainActivity` copies `content://` input into application cache and sends its path over `com.padoshah.abzarfile/open_file`.
- Windows: `Platform.executableArguments` is searched for an existing file.
- Both routes load paths into `ConvertController` and navigate to `/convert`.

## 4. Navigation

`lib/app/router.dart` owns one `GoRouter`.

Shell routes (`AppShell` navigation rail/bar):

- `/` home
- `/convert`
- `/toolbox`
- `/history`
- `/settings`

Standalone routes cover compression, annotation, merge/split, extraction, scan, visible signature, security, PDF tools/repair/object/structure operations, updates, and eight `/viewer/*` screens.

`AppShell` also wraps the UI in `desktop_drop.DropTarget`; dropped paths are passed to `ConvertController`.

## 5. Flutter state flow

### Riverpod state

```text
settingsProvider (AsyncNotifier<AppSettings>)
    ↔ SharedPreferences

formatRegistryProvider (FutureProvider<FormatRegistry>)
    ← assets/config/conversion_matrix.json

convertControllerProvider (StateNotifier<ConvertState>)
    → FileService / StorageService / JobIsolate / HistoryService
```

Most other features intentionally use local widget state and direct service construction. This is the current architecture, not a fully centralized DI design.

### Conversion queue

`ConvertController` maintains immutable `ConvertState`/`QueueItem` values. It selects output paths, constructs a `JobSpec`, starts a `JobExecution`, consumes progress, stores a successful `JobReport`, and exposes cancel/retry. The current loop processes queue items sequentially even though native work is isolated.

### Models

- `FileEntry`: local path/name/extension/size.
- `JobSpec`: paths, formats, raster options and optional default rich style; serialized as JSON for C++.
- `JobReport`: error, byte sizes, duration, pages and warning count.
- `FormatInfo`/`ConversionCapability`/`ConversionOption`: decoded runtime matrix.

## 6. Native boundary and threading

`lib/core/native/native_library.dart` loads:

- Android: `libabzar_core.so`
- Windows: `abzar_core.dll`
- Linux native development: `libabzar_core.so`

It rejects an ABI version other than `1`.

`JobIsolate` spawns an isolate, creates an opaque native job, sends its pointer address to the owner for cancellation, and forwards native callback progress through a `SendPort`. `NativeOperations` wraps one-shot native operations in `Isolate.run` and owns UTF-8/native error allocation cleanup.

The generated binding source is `lib/core/native/abzar_bindings.g.dart`; `ffigen.yaml` reads `native/include/abzar/abzar_api.h`.

C ABI rules:

- fixed-width values, pointers and opaque handles only;
- no exception crosses `extern "C"`;
- allocated strings use `abz_free`;
- error codes map to `NativeErrorCode`/`NativeException`.

## 7. Canonical document pipeline

`native/src/core/doc_model.h` defines:

```text
Document
  └─ Section[]
      └─ Page[]
          └─ Block[]
              ├─ styled Run[]
              ├─ TableData
              ├─ SheetData with typed CellValue
              ├─ ImageData
              └─ ShapeData / metadata
```

Import dispatch is in `native/src/importers/importer.cpp`; export dispatch is in `native/src/exporters/exporter.cpp`.

Importers currently cover text/Markdown/JSON/CSV, HTML, raster images, OOXML, PDF, and legacy/RTF/ODT/EPUB recovery. Exporters produce TXT, HTML, PNG, JPEG, WebP, PDF, DOCX, XLSX and PPTX. Same-format OOXML source bytes can be retained in `Document.original_package` for exact pass-through round trips.

PDF and advanced operations use separate native operation paths where canonical conversion would lose object fidelity. QPDF handles security/page/object/annotation operations; PDFium is used for text/page render import when linked.

## 8. Native dependencies and feature gates

`native/CMakeLists.txt` builds `abzar_core` and resolves:

- zlib 1.3.1
- Mbed TLS 3.6.2
- FreeType 2.13.3
- HarfBuzz 10.2.0
- OpenCV 4.11.0 minimal core/imgproc
- PDFium Chromium 7999 binary package selected by platform/ABI
- qpdf 12.2.0
- Tesseract/Leptonica only when OCR is enabled and discoverable
- libwebp 1.5.0
- libtiff 4.7.0
- vendored stb image headers

`abz_build_features()` reports linked optional features. The implementation deliberately returns typed unsupported/OCR errors when a gated backend is absent.

## 9. Persistence

### History

`HistoryService` uses a background Drift `NativeDatabase` executor over `abzarfile.sqlite` in application support. It manually creates `job_history` with `created_at`, `spec_json`, and `report_json`; there is no generated Drift table or migration class.

### Settings

`SettingsController` stores theme, locale, DPI, quality, output directory and update-check preference in shared preferences. Update bootstrap additionally stores last check and skipped release version.

### Temporary files

`StorageService` uses `<temporary>/abzarfile/jobs`, reserves collision-free outputs and removes entries older than seven days at startup. Native `native/src/util/fs.cpp` writes a temporary sibling then renames it.

## 10. Platform architecture

### Android

`android/app/build.gradle` configures package ID, minSdk 23, Java 17, three ABIs, external native CMake, release shrinking and optional signing from ignored properties/environment. `MainActivity.kt` implements:

- app launch/open intents;
- SAF `content://` materialization into cache;
- APK FileProvider installation;
- unknown-app-source settings deep link.

Manifest permissions are camera, Internet (updater), and package installation. There is no broad external-storage permission.

### Windows

`windows/CMakeLists.txt` includes Flutter, `../native`, and runner targets; it installs `abzar_core` with the Flutter bundle. `windows/runner/main.cpp` creates `AbzarFileSingleInstanceMutex`. Inno Setup packages the release folder, preserves application data outside the install directory, and registers file associations.

The stale Flutter platform-hook template block has been removed from `windows/CMakeLists.txt`. A non-signing Windows CI job now configures, analyzes, tests and builds the debug bundle; treat the host as unverified until that job completes successfully.

## 11. Updater and release data flow

```text
GitHub latest-release endpoint
  → semver comparison
  → exact platform asset + checksum asset
  → resumable download / retry
  → SHA-256
  ├─ Windows: installed/candidate Authenticode signer subject match
  └─ Android: FileProvider + system package installer
```

The endpoint is currently hardcoded to `https://api.github.com/repos/padoshah/abzartool3/releases/latest`.

Expected release assets are defined jointly by updater tests and workflows. See `RELEASE.md`.

## 12. Authentication and security boundaries

There is no account authentication or application API key. Document passwords are passed to native operations and native/Dart buffers attempt explicit clearing. Signing credentials are CI-only organization secrets; they must never enter source control.

PDF security is qpdf-gated. Other-file ABZE encryption is Mbed TLS-gated. Office Agile Encryption is not represented as completed merely because a security screen exists.

## 13. Test architecture and observed coverage

- `test/job_spec_test.dart`: JSON option contract.
- `test/native_error_test.dart`: native numeric error stability.
- `test/version_contract_test.dart`: updater/workflow filename agreement.
- `integration_test/app_test.dart`: one dashboard launch assertion.
- `native/tests/core_tests.cpp`: ABI feature manifest, basic conversions, structural signatures, compression ordering, selected PDF/OOXML operations and an 8-source/8-target subset.
- `tool/verify_outputs.dart`: configuration contract plus validators for selected generated output paths.

Coverage is not equivalent to all 189 matrix pairs. Fixtures currently exist only for TXT, CSV, JSON, HTML and PNG.

## 14. Important component relationships

- `pubspec.yaml.version` → `tool/set_version.dart` → Windows resource fallback + Inno default; Flutter supplies Gradle version fields.
- Workflow artifact names ↔ `UpdateService` exact filename selection ↔ `test/version_contract_test.dart`.
- Android package ID/signing/versionCode must remain stable for in-place APK updates.
- Inno `AppId`, app mutex, executable name and updater installer flags form the Windows upgrade contract.
- `abzar_api.h` ↔ ffigen output ↔ `FfiBridge`/`JobIsolate`/`NativeOperations` must change together.
- Conversion matrix ↔ importer/exporter dispatch ↔ UI target choices ↔ fixtures/validators must change together.
