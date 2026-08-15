# Architecture documentation

The canonical repository architecture handover is [`../ARCHITECTURE.md`](../ARCHITECTURE.md). It describes the actual startup, route, Riverpod/local state, service, storage, FFI, canonical document, native dependency and platform flows.

Architecture decisions are recorded in [`DECISIONS.md`](DECISIONS.md). Conversion-specific behavior is documented in [`CONVERSION_MATRIX.md`](CONVERSION_MATRIX.md).

Keep the root architecture document synchronized with source changes to `lib/app`, `lib/core`, `native/include/abzar/abzar_api.h`, `native/src`, Android method channels, Windows runner integration, persistence, updater or workflows.
