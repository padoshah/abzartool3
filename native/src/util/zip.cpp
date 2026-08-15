#include "util/zip.h"

#include <algorithm>
#include <cstddef>
#include <cstring>
#include <limits>
#include <utility>

#include "core/error.h"
#include "util/fs.h"
#include <zlib.h>

namespace abzar {
namespace {
std::uint16_t u16(const std::vector<std::uint8_t>& bytes, std::size_t offset) {
  if (offset + 2 > bytes.size()) throw Error(ABZ_ERROR_CORRUPT_INPUT, "Truncated ZIP");
  return static_cast<std::uint16_t>(bytes[offset] | (bytes[offset + 1] << 8));
}
std::uint32_t u32(const std::vector<std::uint8_t>& bytes, std::size_t offset) {
  if (offset + 4 > bytes.size()) throw Error(ABZ_ERROR_CORRUPT_INPUT, "Truncated ZIP");
  return std::uint32_t(bytes[offset]) | (std::uint32_t(bytes[offset + 1]) << 8) |
         (std::uint32_t(bytes[offset + 2]) << 16) | (std::uint32_t(bytes[offset + 3]) << 24);
}
void p16(std::vector<std::uint8_t>& bytes, std::uint16_t value) {
  bytes.push_back(static_cast<std::uint8_t>(value & 255));
  bytes.push_back(static_cast<std::uint8_t>((value >> 8) & 255));
}
void p32(std::vector<std::uint8_t>& bytes, std::uint32_t value) {
  for (int shift = 0; shift < 4; ++shift) bytes.push_back(static_cast<std::uint8_t>((value >> (8 * shift)) & 255));
}
void append(std::vector<std::uint8_t>& bytes, const std::string& value) { bytes.insert(bytes.end(), value.begin(), value.end()); }

std::vector<std::uint8_t> inflate_raw(const std::uint8_t* input,
                                      std::size_t input_size,
                                      std::size_t output_size) {
  std::vector<std::uint8_t> output(output_size);
  z_stream stream{};
  stream.next_in = const_cast<Bytef*>(input);
  stream.avail_in = static_cast<uInt>(input_size);
  stream.next_out = output.data();
  stream.avail_out = static_cast<uInt>(output.size());
  if (inflateInit2(&stream, -MAX_WBITS) != Z_OK) throw Error(ABZ_ERROR_CORRUPT_INPUT, "Cannot initialize ZIP decompressor");
  const int result = inflate(&stream, Z_FINISH);
  inflateEnd(&stream);
  if (result != Z_STREAM_END || stream.total_out != output_size) throw Error(ABZ_ERROR_CORRUPT_INPUT, "Invalid deflated ZIP entry");
  return output;
}

std::vector<std::uint8_t> deflate_raw(const std::vector<std::uint8_t>& input,
                                      int level) {
  if (input.empty()) return {};
  std::vector<std::uint8_t> output(compressBound(input.size()));
  z_stream stream{};
  stream.next_in = const_cast<Bytef*>(input.data());
  stream.avail_in = static_cast<uInt>(input.size());
  stream.next_out = output.data();
  stream.avail_out = static_cast<uInt>(output.size());
  if (deflateInit2(&stream, std::clamp(level, 0, 9), Z_DEFLATED, -MAX_WBITS, 8,
                   Z_DEFAULT_STRATEGY) != Z_OK) {
    throw Error(ABZ_ERROR_INTERNAL, "Cannot initialize ZIP compressor");
  }
  const int result = deflate(&stream, Z_FINISH);
  deflateEnd(&stream);
  if (result != Z_STREAM_END) throw Error(ABZ_ERROR_INTERNAL, "ZIP compression failed");
  output.resize(stream.total_out);
  return output;
}

struct Meta {
  std::string name;
  std::uint32_t crc{0};
  std::uint32_t size{0};
  std::uint32_t packed_size{0};
  std::uint32_t offset{0};
  std::uint16_t method{0};
  std::vector<std::uint8_t> packed;
};
}  // namespace

ZipArchive ZipArchive::open(const std::filesystem::path& path) {
  const auto bytes = fs::read_bytes(path);
  if (bytes.size() < 22) throw Error(ABZ_ERROR_CORRUPT_INPUT, "ZIP is too small");
  std::size_t eocd = bytes.size() - 22;
  const auto floor = bytes.size() > 65557 ? bytes.size() - 65557 : 0;
  while (eocd > floor && u32(bytes, eocd) != 0x06054b50) --eocd;
  if (u32(bytes, eocd) != 0x06054b50) throw Error(ABZ_ERROR_CORRUPT_INPUT, "ZIP directory not found");
  const auto count = u16(bytes, eocd + 10);
  std::size_t position = u32(bytes, eocd + 16);
  ZipArchive archive;
  for (unsigned index = 0; index < count; ++index) {
    if (u32(bytes, position) != 0x02014b50) throw Error(ABZ_ERROR_CORRUPT_INPUT, "Invalid ZIP directory");
    const auto method = u16(bytes, position + 10);
    const auto packed = u32(bytes, position + 20);
    const auto unpacked = u32(bytes, position + 24);
    const auto name_length = u16(bytes, position + 28);
    const auto extra_length = u16(bytes, position + 30);
    const auto comment_length = u16(bytes, position + 32);
    const auto local = u32(bytes, position + 42);
    if (position + 46 + name_length + extra_length + comment_length > bytes.size()) throw Error(ABZ_ERROR_CORRUPT_INPUT, "Truncated ZIP name");
    std::string name(reinterpret_cast<const char*>(bytes.data() + position + 46), name_length);
    if (name.find("..") != std::string::npos || (!name.empty() && (name[0] == '/' || name[0] == '\\'))) throw Error(ABZ_ERROR_CORRUPT_INPUT, "Unsafe ZIP path");
    if (u32(bytes, local) != 0x04034b50) throw Error(ABZ_ERROR_CORRUPT_INPUT, "Invalid ZIP local header");
    const auto local_name = u16(bytes, local + 26);
    const auto local_extra = u16(bytes, local + 28);
    const auto data = static_cast<std::size_t>(local) + 30 + local_name + local_extra;
    if (data + packed > bytes.size()) throw Error(ABZ_ERROR_CORRUPT_INPUT, "Truncated ZIP entry");
    if (!name.empty() && name.back() != '/') {
      if (method == 0) archive.entries_[name] = {bytes.begin() + static_cast<std::ptrdiff_t>(data), bytes.begin() + static_cast<std::ptrdiff_t>(data + packed)};
      else if (method == 8) archive.entries_[name] = inflate_raw(bytes.data() + data, packed, unpacked);
      else throw Error(ABZ_ERROR_UNSUPPORTED_FORMAT, "Unsupported ZIP compression method");
    }
    position += 46 + name_length + extra_length + comment_length;
  }
  return archive;
}

void ZipArchive::add(std::string name, std::string text) { entries_[std::move(name)] = {text.begin(), text.end()}; }
void ZipArchive::add(std::string name, std::vector<std::uint8_t> bytes) { entries_[std::move(name)] = std::move(bytes); }
bool ZipArchive::contains(const std::string& name) const { return entries_.contains(name); }
const std::vector<std::uint8_t>& ZipArchive::at(const std::string& name) const { const auto item = entries_.find(name); if (item == entries_.end()) throw Error(ABZ_ERROR_CORRUPT_INPUT, "Required ZIP part is missing: " + name); return item->second; }
std::string ZipArchive::text(const std::string& name) const { const auto& bytes = at(name); return {reinterpret_cast<const char*>(bytes.data()), bytes.size()}; }
std::vector<std::string> ZipArchive::names() const { std::vector<std::string> result; for (const auto& [name, bytes] : entries_) { (void)bytes; result.push_back(name); } return result; }

void ZipArchive::write(const std::filesystem::path& path, int compression_level) const {
  if (entries_.size() > std::numeric_limits<std::uint16_t>::max()) throw Error(ABZ_ERROR_VALIDATION, "ZIP has too many entries");
  std::vector<std::uint8_t> output;
  std::vector<Meta> metadata;
  for (const auto& [name, data] : entries_) {
    if (name.size() > std::numeric_limits<std::uint16_t>::max() || data.size() > std::numeric_limits<std::uint32_t>::max()) throw Error(ABZ_ERROR_VALIDATION, "ZIP entry is too large");
    Meta item;
    item.name = name;
    item.crc = static_cast<std::uint32_t>(crc32(0, data.data(), static_cast<uInt>(data.size())));
    item.size = static_cast<std::uint32_t>(data.size());
    item.offset = static_cast<std::uint32_t>(output.size());
    item.method = compression_level > 0 && !data.empty() ? 8 : 0;
    item.packed = item.method == 8 ? deflate_raw(data, compression_level) : data;
    item.packed_size = static_cast<std::uint32_t>(item.packed.size());
    p32(output, 0x04034b50); p16(output, 20); p16(output, 0x0800); p16(output, item.method);
    p16(output, 0); p16(output, 0); p32(output, item.crc); p32(output, item.packed_size); p32(output, item.size);
    p16(output, static_cast<std::uint16_t>(name.size())); p16(output, 0); append(output, name);
    output.insert(output.end(), item.packed.begin(), item.packed.end());
    metadata.push_back(std::move(item));
  }
  const auto central = static_cast<std::uint32_t>(output.size());
  for (const auto& item : metadata) {
    p32(output, 0x02014b50); p16(output, 20); p16(output, 20); p16(output, 0x0800); p16(output, item.method);
    p16(output, 0); p16(output, 0); p32(output, item.crc); p32(output, item.packed_size); p32(output, item.size);
    p16(output, static_cast<std::uint16_t>(item.name.size())); p16(output, 0); p16(output, 0); p16(output, 0); p16(output, 0);
    p32(output, 0); p32(output, item.offset); append(output, item.name);
  }
  const auto central_size = static_cast<std::uint32_t>(output.size()) - central;
  p32(output, 0x06054b50); p16(output, 0); p16(output, 0);
  p16(output, static_cast<std::uint16_t>(metadata.size())); p16(output, static_cast<std::uint16_t>(metadata.size()));
  p32(output, central_size); p32(output, central); p16(output, 0);
  fs::write_bytes_atomic(path, output);
}
}  // namespace abzar
