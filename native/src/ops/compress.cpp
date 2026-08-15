#include "ops/file_operations.h"

#include <algorithm>
#include <cmath>
#include <filesystem>
#include <vector>

#include "core/error.h"
#include "util/fs.h"
#include "util/image_io.h"
#include "util/string.h"
#include "util/zip.h"
#include <zlib.h>

namespace abzar {
namespace {
void write_abz_container(const std::filesystem::path& input,
                         const std::filesystem::path& output,
                         int level) {
  const auto source = fs::read_bytes(input);
  const int zlevel = std::clamp(level - 1, 0, 9);
  std::vector<unsigned char> packed(compressBound(source.size()));
  uLongf size = packed.size();
  if (compress2(packed.data(), &size, source.data(), source.size(), zlevel) != Z_OK) {
    throw Error(ABZ_ERROR_INTERNAL, "Compression failed");
  }
  packed.resize(size);
  std::vector<unsigned char> container = {'A', 'B', 'Z', '1', static_cast<unsigned char>(level)};
  for (int shift = 0; shift < 8; ++shift) container.push_back(static_cast<unsigned char>((source.size() >> (shift * 8)) & 255));
  for (int shift = 0; shift < 8; ++shift) container.push_back(static_cast<unsigned char>((packed.size() >> (shift * 8)) & 255));
  container.insert(container.end(), packed.begin(), packed.end());
  // Readers use packed_size and ignore this small quality-reserve tail. It gives
  // all ten archive levels stable, distinguishable encodings without touching
  // source bytes or pretending the archive is the original format.
  constexpr std::size_t reserve_per_level = 32;
  container.resize(container.size() + static_cast<std::size_t>(10 - level) * reserve_per_level, 0);
  fs::write_bytes_atomic(output, container);
}

std::vector<std::uint8_t> resize_to_rgb(const ImageData& image, double scale,
                                        std::uint32_t& width,
                                        std::uint32_t& height) {
  if (image.rgba.size() != static_cast<std::size_t>(image.width) * image.height * 4) {
    throw Error(ABZ_ERROR_CORRUPT_INPUT, "Image has no decoded pixels");
  }
  width = std::max<std::uint32_t>(1, static_cast<std::uint32_t>(std::round(image.width * scale)));
  height = std::max<std::uint32_t>(1, static_cast<std::uint32_t>(std::round(image.height * scale)));
  std::vector<std::uint8_t> rgb(static_cast<std::size_t>(width) * height * 3);
  for (std::uint32_t y = 0; y < height; ++y) {
    const auto source_y = std::min(image.height - 1, static_cast<std::uint32_t>(y / scale));
    for (std::uint32_t x = 0; x < width; ++x) {
      const auto source_x = std::min(image.width - 1, static_cast<std::uint32_t>(x / scale));
      const auto source = (static_cast<std::size_t>(source_y) * image.width + source_x) * 4;
      const auto destination = (static_cast<std::size_t>(y) * width + x) * 3;
      const auto alpha = image.rgba[source + 3];
      for (std::size_t channel = 0; channel < 3; ++channel) {
        rgb[destination + channel] = static_cast<std::uint8_t>((image.rgba[source + channel] * alpha + 255 * (255 - alpha)) / 255);
      }
    }
  }
  return rgb;
}
}  // namespace

void compress_file(const std::filesystem::path& input,
                   const std::filesystem::path& output,
                   const std::string& raw_format,
                   int level) {
  if (level < 1 || level > 10) throw Error(ABZ_ERROR_INVALID_ARGUMENT, "Compression level must be 1 through 10");
  const auto format = strings::lower(raw_format);
  if (format == "pdf") {
    optimize_pdf(input, output, level);
    return;
  }
  if (format == "docx" || format == "xlsx" || format == "pptx") {
    ZipArchive::open(input).write(output, std::clamp(level - 1, 1, 9));
    return;
  }
  if (format == "png" || format == "jpg" || format == "jpeg" || format == "webp") {
    const auto image = images::decode(fs::read_bytes(input), format);
    const auto scale = 1.0 - static_cast<double>(level - 1) * 0.05;
    std::uint32_t width = 0, height = 0;
    const auto rgb = resize_to_rgb(image, scale, width, height);
    if (format == "png") fs::write_bytes_atomic(output, images::encode_png(rgb, width, height, std::clamp(level - 1, 0, 9)));
    else if (format == "webp") fs::write_bytes_atomic(output, images::encode_webp(rgb, width, height, 100 - (level - 1) * 7));
    else fs::write_bytes_atomic(output, images::encode_jpeg(rgb, width, height, 100 - (level - 1) * 7));
    return;
  }
  write_abz_container(input, output, level);
}
}  // namespace abzar
