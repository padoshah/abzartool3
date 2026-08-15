# Contributing

Read `AGENTS.md`, `docs/ARCHITECTURE.md`, and `docs/BUILD.md` first. Keep importers isolated from exporters through `DocModel`; never implement conversion as extension renaming. Add a fixture and structural test with every format change.

Before submitting changes run:

```bash
dart format --set-exit-if-changed .
flutter analyze
flutter test
cmake -S native -B native/build -DABZAR_BUILD_TESTS=ON
cmake --build native/build
ctest --test-dir native/build --output-on-failure
```

Never include credentials, signing files, user documents, generated build output, or dependencies without their license notice.
