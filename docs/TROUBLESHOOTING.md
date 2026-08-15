# Troubleshooting

## Flutter cannot find generated localizations
Run `flutter pub get && flutter gen-l10n`. Generated localization Dart is intentionally produced by Flutter.

## `libabzar_core.so` or `abzar_core.dll` cannot be loaded
Build through Flutter rather than copying only the Dart bundle. On Windows verify `abzar_core.dll` is beside `abzarfile.exe`; on Android inspect APK `lib/<abi>/libabzar_core.so` entries.

## CMake cannot find zlib
Install zlib development headers or configure with `-DABZAR_USE_SYSTEM_ZLIB=OFF` to use pinned FetchContent. Confirm Actions/network policy permits GitHub dependency retrieval.

## Android CMake/NDK mismatch
Install CMake 3.22.1 and the NDK selected by pinned Flutter. Remove stale `build/` and `.cxx/`, then rebuild. Do not change ABI filters: all three are release requirements.

## Release APK is unsigned or debug-signed
Confirm all four Android organization secrets are visible to the repository. Check base64 encoding represents the binary keystore and alias/passwords match. The workflow deliberately fails at `apksigner` verification.

## Windows signing fails
Confirm both Windows organization secrets are available, the PFX contains a code-signing private key, the password matches, and the timestamp host is reachable. Both app and installer must pass `signtool verify /pa /v`.

## Inno cannot find build files
Run `flutter build windows --release`; `installer/abzarfile.iss` expects `build/windows/x64/runner/Release`.

## Android update refuses installation
The APK must have package `com.padoshah.abzarfile`, the same signing identity, and a higher formula-derived versionCode. Grant “Install unknown apps” to AbzarFile when prompted.

## Windows updater rejects setup
Download both setup and `checksums-windows.txt` from the same release. A checksum mismatch or invalid Authenticode chain is a hard failure. Check system time and certificate trust.

## OOXML opens with a repair warning
Run native structural tests and inspect required parts with `unzip -l`. Never work around the failure by renaming an existing file. Add the missing relationship/content-type part and a regression fixture.
