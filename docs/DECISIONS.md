# Architecture decisions

## ADR-001 — Riverpod only
Riverpod provides explicit dependency lifetimes, testable controllers, and isolate-friendly immutable state. Bloc is not mixed into the repository.

## ADR-002 — Drift-backed SQLite without generated tables
History uses Drift's executor with versioned SQL created by the service. This avoids generated schema files at the current small schema size while retaining SQLite portability and a migration path.

## ADR-003 — Stable pure C ABI
Dart never links C++ symbols. Opaque handles, fixed-width fields, explicit ownership, ABI versioning, JSON job specifications, and caught exceptions preserve compiler/platform independence.

## ADR-004 — Canonical model rather than N×N conversion code
Every source has one importer and every target one exporter. Fidelity loss is explicit in warnings and the capability matrix.

## ADR-005 — Capability-gated native dependency graph
The native build resolves pinned zlib, Mbed TLS, FreeType, HarfBuzz, PDFium, qpdf, OpenCV, libwebp and libtiff plus vendored stb. Tesseract is enabled only when requested and discoverable. `abz_build_features()` exposes the linked capabilities, and unavailable operations return typed errors. A configured or fetched dependency is not considered verified until its platform build/tests pass.

## ADR-006 — Deterministic OPC ZIP handling
The in-tree ZIP layer reads stored/deflated entries and can write level-controlled deflate streams. Same-format Office imports retain original package bytes for exact round trips; generated DOCX/XLSX/PPTX packages are compressed by the exporter. Importer/exporter contracts must not depend on the compression method.

## ADR-007 — Atomic source safety
Every writer creates a temporary file and renames it only after successful serialization. No operation receives write access to its source path.

## ADR-008 — Administrative Windows install identity
The fixed AppId is `{7F452E1A-24D8-4E36-AE2C-8CD6E2280B31}` and installation remains machine-wide under `{autopf}\AbzarFile`. Changing AppId or privilege scope would break upgrade continuity and is forbidden.

## ADR-009 — Release API is the only runtime network destination
No telemetry, cloud conversion, ads, or remote fonts. Update checks target the public release API. Downloads require user action, matching checksums, and platform signature validation.

## ADR-010 — Matrix declaration and runtime capability are separate
`assets/config/conversion_matrix.json` currently enables all 189 declared pairs, including 30 marked `requiresOcr`. The UI uses this declaration for target choices. Native feature gates and typed errors remain authoritative at runtime; an enabled matrix entry must not be presented in documentation as tested unless fixtures and structural/semantic tests exist.
