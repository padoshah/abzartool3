#pragma once
#include <cstdint>
#include <vector>
#include "core/doc_model.h"
namespace abzar::images {
ImageData decode(const std::vector<std::uint8_t>& encoded, const std::string& format);
std::vector<std::uint8_t> encode_png(const std::vector<std::uint8_t>& rgb, std::uint32_t width, std::uint32_t height, int compression_level = 6);
std::vector<std::uint8_t> encode_jpeg(const std::vector<std::uint8_t>& rgb, std::uint32_t width, std::uint32_t height, int quality = 90);
std::vector<std::uint8_t> encode_webp(const std::vector<std::uint8_t>& rgb, std::uint32_t width, std::uint32_t height, int quality = 90);
std::pair<std::uint32_t,std::uint32_t> jpeg_dimensions(const std::vector<std::uint8_t>& encoded);
}  // namespace abzar::images
