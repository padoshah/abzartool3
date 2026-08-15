# AbzarFile release guide

This is the canonical release handover for the current repository. Do not tag a production release until CI, Android, Windows, signing, installer and updater checks are green.

## 1. Platforms and artifacts

The repository releases only:

- Android: one universal APK plus `armeabi-v7a`, `arm64-v8a`, and `x86_64` split APKs.
- Windows: one x64 Inno Setup executable for Windows 10/11.

There are no iOS, web, macOS, Linux application, AAB or Microsoft Store release workflows.

Expected tag `vX.Y.Z` assets:

```text
AbzarFile-vX.Y.Z-android-universal.apk
AbzarFile-vX.Y.Z-android-armeabi-v7a.apk
AbzarFile-vX.Y.Z-android-arm64-v8a.apk
AbzarFile-vX.Y.Z-android-x86_64.apk
checksums-android.txt
AbzarFile-vX.Y.Z-windows-x64-setup.exe
checksums-windows.txt
```

`UpdateService`, release workflows, `tool/verify_outputs.dart`, and `test/version_contract_test.dart` depend on these exact names.

## 2. Version source and update tool

`pubspec.yaml` is the source version:

```yaml
version: X.Y.Z+BUILD
```

Build number formula implemented by `tool/set_version.dart`:

```text
BUILD = X * 10000 + Y * 100 + Z
v1.2.3 → 10203
```

Run:

```bash
dart run tool/set_version.dart vX.Y.Z
```

The tool updates:

- `pubspec.yaml`
- fallback numeric/string values in `windows/runner/Runner.rc`
- default `MyAppVersion` in `installer/abzarfile.iss`

Android Gradle reads `flutter.versionCode`/`flutter.versionName`, which Flutter derives from pubspec. Review every changed file. The script does not edit a literal Gradle version field.

Current repository version is `1.0.0+10000`.

## 3. Required GitHub repository configuration

- GitHub Actions enabled.
- Workflow permissions allow contents write for release workflows.
- Organization/repository secrets are available to the repository.
- Marketplace actions used by the workflows are allowed.
- Tag actor is allowed by repository/tag protection.

The workflows request `contents: write` themselves. No PAT is required; release commands use `github.token`.

### Secret names only

Android organization secrets:

- `ANDROID_KEYSTORE_BASE64`: binary release keystore encoded as Base64.
- `ANDROID_KEYSTORE_PASSWORD`: keystore password.
- `ANDROID_KEY_ALIAS`: release key alias.
- `ANDROID_KEY_PASSWORD`: release key password.

Windows organization secrets:

- `WINDOWS_SIGNING_CERTIFICATE_BASE64`: code-signing PFX bytes encoded as Base64.
- `WINDOWS_SIGNING_CERTIFICATE_PASSWORD`: PFX password.

Never write values into source, issues, logs or documentation. Signing files are decoded under `RUNNER_TEMP` and removed by always-run cleanup.

## 4. Pre-release checks

From a clean checkout with pinned Flutter 3.29.3:

```bash
flutter pub get
flutter gen-l10n
./tool/gen_bindings.sh
dart format --set-exit-if-changed lib test integration_test tool
flutter analyze
flutter test
cmake -S native -B native/build-release -DABZAR_BUILD_TESTS=ON -DABZAR_ENABLE_OCR=ON
cmake --build native/build-release --config Release
ABZAR_REQUIRE_FULL_FEATURES=1 ctest --test-dir native/build-release -C Release --output-on-failure
dart run tool/verify_outputs.dart
```

Also require:

- Android debug and unsigned/signed release builds on all three ABIs.
- Windows x64 release build and Inno compilation on a Windows runner.
- updater filename/checksum contract tests.
- no uncommitted generated binding/localization/lockfile changes.
- no credential-like or build-output files in Git.
- changelog entry for the version.

The stale Windows Flutter template-hook markers have been removed, but a successful pinned-Flutter Windows CI and release dry run must still be demonstrated before release.

## 5. CI workflow

`.github/workflows/ci.yml` runs on pushes and pull requests:

1. Flutter 3.29.3 setup.
2. Linux native package installation.
3. `flutter pub get`, localization generation, ffigen regeneration and a tracked-binding diff check.
4. Dart format parse, analysis and Flutter tests.
5. native CMake build with OCR enabled and required-feature CTest.
6. output/update contract verification.
7. Android debug APK build.

CI also has a non-signing `windows-latest` job that enables Windows desktop, resolves generated sources, analyzes/tests, and builds a debug Windows bundle. The signed tag workflow remains the Release/MSVC/Inno gate.

## 6. Android release workflow

`.github/workflows/android-release.yml` triggers on `v*.*.*` tags and manual dispatch.

Key behavior:

1. Resolve tag/manual version and run `tool/set_version.dart`.
2. Install Flutter, Java 17, Android CMake/NDK/build tools.
3. Resolve packages, generate localization/bindings, analyze and test.
4. Build external native Release for configured ABIs.
5. Require all four Android signing secrets.
6. Decode keystore into `RUNNER_TEMP`; write ignored `android/key.properties`.
7. Build universal then split release APKs.
8. Verify every APK with `apksigner` and reject “Android Debug”.
9. Rename, hash and upload artifacts.
10. Create/find the tag release and upload with `--clobber`.
11. Always shred/remove temporary signing material.

Android identity contract:

- package: `com.padoshah.abzarfile`
- minSdk: 23
- same release signing identity across updates
- increasing versionCode
- universal asset required by in-app updater

The workflow installs NDK 27.0.12077973, while Gradle declares `ndkVersion flutter.ndkVersion`. Verify those match for the pinned Flutter SDK.

## 7. Windows release workflow

`.github/workflows/windows-release.yml` runs on the same tag/manual version using `windows-latest`:

1. Resolve version and run version tool.
2. Enable Flutter Windows; generate bindings/localization; analyze/test.
3. Build/test native x64 Release.
4. Build Flutter Windows Release.
5. Require/decode temporary Windows certificate.
6. Locate `signtool`, sign and verify `abzarfile.exe`.
7. Install Inno Setup and compile `installer/abzarfile.iss`.
8. Sign and verify final setup.
9. Rename/hash/upload assets and update the same GitHub release.
10. Always delete temporary PFX.

Permanent Windows upgrade contract:

```text
AppId: {7F452E1A-24D8-4E36-AE2C-8CD6E2280B31}
Executable: abzarfile.exe
Mutex: AbzarFileSingleInstanceMutex
Install directory: {autopf}\AbzarFile
Privileges: admin / machine-wide
```

Do not change AppId or installation scope without an explicit migration plan.

The Inno script packages `build/windows/x64/runner/Release/*`, registers associations and leaves `%LOCALAPPDATA%\AbzarFile`/`%APPDATA%\AbzarFile` outside the installation tree.

## 8. Tag and publish

Only after pre-release checks and both platform dry runs pass:

```bash
dart run tool/set_version.dart vX.Y.Z
# update CHANGELOG.md

git add pubspec.yaml windows/runner/Runner.rc installer/abzarfile.iss CHANGELOG.md
git commit -m "release: vX.Y.Z"
git tag vX.Y.Z
git push origin <release-branch>
git push origin vX.Y.Z
```

Both platform workflows independently create/find the same release and upload assets idempotently. Do not manually upload a differently named asset; the updater will ignore it.

After workflows complete, verify:

```bash
gh release view vX.Y.Z
gh release download vX.Y.Z --dir release-check
sha256sum -c release-check/checksums-android.txt
sha256sum -c release-check/checksums-windows.txt
```

Use the Windows equivalent (`Get-FileHash`) when appropriate, and independently verify APK/Authenticode signatures.

## 9. In-app update release contract

The updater queries:

```text
https://api.github.com/repos/padoshah/abzartool3/releases/latest
```

If the project is moved/forked, this endpoint must be deliberately updated and tested before release.

Windows verification:

- checksum from the same release;
- candidate Authenticode status valid;
- installed and candidate signer certificate subjects equal;
- launch Inno with `/SILENT /CLOSEAPPLICATIONS /RESTARTAPPLICATIONS /NORESTART`.

Android verification:

- checksum from the same release;
- FileProvider URI;
- system installer and unknown-source consent;
- Android enforces package/signing/version identity.

## 10. Release rollback and failure handling

- Never replace an already installed release with a lower Android versionCode.
- Do not reuse/move a published tag.
- If one platform fails, do not describe the release as complete; fix on a new commit/tag according to repository policy.
- Workflows use `--clobber`; rerunning can replace same-named release assets. Confirm the tag still points to the intended commit.
- If signing cleanup fails, cancel exposure immediately and rotate/revoke through the organization’s secure process; never diagnose by printing secret values.

## 11. Current release readiness

The files describe a release process, but the checkout itself does not prove it. Missing `pubspec.lock`, absent generated localization, unresolved Windows template syntax, limited fixtures and unverified full dependency/platform builds must be resolved before declaring `v1.0.0` production-ready.
