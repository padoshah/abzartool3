# Windows installer

`abzarfile.iss` packages the x64 Flutter Release bundle and permanent `abzar_core.dll` into an in-place-upgrade Inno Setup installer. The AppId GUID must never change. CI injects `MyAppVersion`, signs the application before packaging, signs the final setup, verifies both, and publishes it. Local unsigned packages are development-only.
