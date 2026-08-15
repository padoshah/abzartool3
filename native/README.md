# Native engine

The C++20 engine owns parsing, the canonical document model, rendering, and format output. `include/` is the stable C ABI; `src/` is private implementation; `tests/` contains structural tests; `third_party/` contains dependency glue and licenses. Exceptions are caught before the ABI, outputs are atomic, and importers/exporters communicate only through `DocModel`.
