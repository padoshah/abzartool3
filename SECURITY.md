# Security Policy

## Reporting
Report vulnerabilities privately through GitHub Security Advisories. Do not open a public issue for an unpatched vulnerability.

## Data boundary
AbzarFile processes documents locally. It has no telemetry and does not upload user files. The only intended network traffic is an explicit or scheduled GitHub Releases update check.

## Credentials
Never commit signing material or secrets. Release jobs consume only these organization secret names: `ANDROID_KEYSTORE_BASE64`, `ANDROID_KEYSTORE_PASSWORD`, `ANDROID_KEY_ALIAS`, `ANDROID_KEY_PASSWORD`, `WINDOWS_SIGNING_CERTIFICATE_BASE64`, and `WINDOWS_SIGNING_CERTIFICATE_PASSWORD`. Values exist only in runner temporary storage and are deleted by always-run cleanup steps.

Passwords supplied for document operations are never persisted or logged. Native sensitive buffers are overwritten before release.

## Supported releases
Security fixes target the latest release. Verify release checksums and platform signatures before installation.
