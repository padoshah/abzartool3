#include "exporters/exporter.h"

#include "core/error.h"
#include "render/rasterizer.h"
#include "util/fs.h"
#include "util/image_io.h"

namespace abzar {
namespace {
template <typename Encoder>
void export_pages(const Document& document,
                  const std::filesystem::path& path,
                  int dpi,
                  Encoder encoder) {
  std::size_t index = 0;
  for (const auto& section : document.sections) {
    for (const auto& page : section.pages) {
      const auto raster = rasterize_page(page, dpi);
      auto output = path;
      if (index > 0) {
        output = path.parent_path() /
            (path.stem().string() + "-" + std::to_string(index + 1) + path.extension().string());
      }
      fs::write_bytes_atomic(output, encoder(raster));
      ++index;
    }
  }
  if (index == 0) throw Error(ABZ_ERROR_VALIDATION, "Document has no pages to rasterize");
}
}  // namespace

void export_png(const Document& document,
                const std::filesystem::path& path,
                const ExportOptions& options) {
  export_pages(document, path, options.dpi, [](const RasterPage& page) {
    return images::encode_png(page.rgb, page.width, page.height, 9);
  });
}

void export_jpeg(const Document& document,
                 const std::filesystem::path& path,
                 const ExportOptions& options) {
  export_pages(document, path, options.dpi, [&](const RasterPage& page) {
    return images::encode_jpeg(page.rgb, page.width, page.height, options.quality);
  });
}
void export_webp(const Document& document,
                 const std::filesystem::path& path,
                 const ExportOptions& options) {
  export_pages(document, path, options.dpi, [&](const RasterPage& page) {
    return images::encode_webp(page.rgb, page.width, page.height, options.quality);
  });
}
}  // namespace abzar
