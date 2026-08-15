#include "util/fs.h"
#include <chrono>
#include <fstream>
#include <random>
#include "core/error.h"
namespace abzar::fs {
std::vector<std::uint8_t> read_bytes(const std::filesystem::path& path) {
  std::ifstream stream(path, std::ios::binary | std::ios::ate);
  if (!stream) throw Error(ABZ_ERROR_IO, "Unable to open input file");
  const auto end = stream.tellg();
  if (end < 0) throw Error(ABZ_ERROR_IO, "Unable to determine input size");
  std::vector<std::uint8_t> bytes(static_cast<std::size_t>(end));
  stream.seekg(0);
  if (!bytes.empty() && !stream.read(reinterpret_cast<char*>(bytes.data()), end))
    throw Error(ABZ_ERROR_IO, "Unable to read input file");
  return bytes;
}
std::string read_text(const std::filesystem::path& path) {
  const auto bytes = read_bytes(path);
  return {reinterpret_cast<const char*>(bytes.data()), bytes.size()};
}
void write_bytes_atomic(const std::filesystem::path& path, const std::vector<std::uint8_t>& bytes) {
  if (path.has_parent_path()) std::filesystem::create_directories(path.parent_path());
  auto temporary = path;
  temporary += ".abzar-tmp-" + std::to_string(std::chrono::steady_clock::now().time_since_epoch().count());
  {
    std::ofstream stream(temporary, std::ios::binary | std::ios::trunc);
    if (!stream || (!bytes.empty() && !stream.write(reinterpret_cast<const char*>(bytes.data()), static_cast<std::streamsize>(bytes.size())))) {
      std::error_code ignored; std::filesystem::remove(temporary, ignored);
      throw Error(ABZ_ERROR_IO, "Unable to write output file");
    }
    stream.flush();
    if (!stream) throw Error(ABZ_ERROR_IO, "Unable to flush output file");
  }
  std::error_code error;
  std::filesystem::rename(temporary, path, error);
  if (error) {
    std::filesystem::remove(path, error); error.clear();
    std::filesystem::rename(temporary, path, error);
  }
  if (error) { std::filesystem::remove(temporary); throw Error(ABZ_ERROR_IO, "Unable to finalize output file"); }
}
void write_text_atomic(const std::filesystem::path& path, const std::string& text) {
  write_bytes_atomic(path, {text.begin(), text.end()});
}
std::uint64_t file_size(const std::filesystem::path& path) {
  std::error_code error; const auto size = std::filesystem::file_size(path, error);
  if (error) throw Error(ABZ_ERROR_IO, "Unable to inspect file size");
  return size;
}
}  // namespace abzar::fs
