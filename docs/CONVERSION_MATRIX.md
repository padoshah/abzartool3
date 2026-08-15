# Conversion capabilities

`assets/config/conversion_matrix.json` is authoritative. The UI never hardcodes a format list. This document explains fidelity values and the currently implemented codec boundary.

| Fidelity | Meaning |
|---|---|
| LOSSLESS | Semantic model and target permit the represented content to round-trip. |
| HIGH | Real target structure is produced with small layout/style differences possible. |
| TEXT_ONLY | Text/tables are recovered; binary layout or unsupported objects may be lost. |
| RASTER | Every modeled page is rendered into real image pixels. |

## Writable targets in the current native build

| Target | Implementation and validation |
|---|---|
| TXT | UTF-8 plain text with paragraph and sheet row separation. |
| HTML | Semantic HTML5, escaped text, tables, CSS, UTF-8 metadata. |
| PDF | PDF 1.7 objects, page tree, xref/trailer, selectable text, JPEG/decoded PNG image XObjects. |
| DOCX | OPC ZIP with content types, relationships, WordprocessingML body and styles. |
| XLSX | OPC ZIP with workbook, typed numeric/shared-string cells, sheet, strings, and styles. |
| PPTX | OPC ZIP with presentation, slides, relationships, master, layout, and theme. |
| PNG | Layout rasterization and standards-compliant compressed RGB PNG per page. |
| JPG | Layout rasterization through a standards-compliant quality-controlled JPEG encoder. |
| WEBP | Layout rasterization through libwebp with configurable quality. |

## Main matrix

`✓` means enabled; `OCR` means selectable but returns a typed localized unavailable result unless OCR is compiled; `—` means disabled.

| Source ↓ / Target → | DOCX | XLSX | PPTX | PDF | HTML | TXT | PNG | JPG | WEBP |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| DOCX | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| XLSX | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| PPTX | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| PDF | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| HTML | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| TXT | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| PNG | OCR | OCR | OCR | ✓ | OCR | OCR | ✓ | ✓ | ✓ |
| JPG | OCR | OCR | OCR | ✓ | OCR | OCR | ✓ | ✓ | ✓ |

CSV, Markdown, and JSON use the text/sheet pipeline. DOC/XLS/PPT/RTF/ODT/EPUB have best-effort read-only text recovery and typed failure when no readable content is found. JPEG/BMP/GIF use stb codecs, WebP uses libwebp, and TIFF uses libtiff. OCR pairs are capability-gated and cannot produce empty files.

## Adding an enabled cell

An enabled pair requires importer coverage, exporter coverage, options, a fixture, semantic expected content, structural output validation, corrupt input coverage, UI behavior, MIME associations, and documentation. Merely adding JSON is not sufficient.
