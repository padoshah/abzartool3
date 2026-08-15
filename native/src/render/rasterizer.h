#pragma once
#include <cstdint>
#include <vector>
#include "core/doc_model.h"
namespace abzar {
struct RasterPage { std::uint32_t width; std::uint32_t height; std::vector<std::uint8_t> rgb; };
RasterPage rasterize_page(const Page& page, int dpi);
}  // namespace abzar
