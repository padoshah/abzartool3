#pragma once
#include <cstdint>
#include <filesystem>
#include <map>
#include <string>
#include <vector>
namespace abzar {
class ZipArchive {
 public:
  static ZipArchive open(const std::filesystem::path& path);
  void add(std::string name, std::string text);
  void add(std::string name, std::vector<std::uint8_t> bytes);
  [[nodiscard]] bool contains(const std::string& name) const;
  [[nodiscard]] const std::vector<std::uint8_t>& at(const std::string& name) const;
  [[nodiscard]] std::string text(const std::string& name) const;
  [[nodiscard]] std::vector<std::string> names() const;
  void write(const std::filesystem::path& path, int compression_level = 0) const;
 private:
  std::map<std::string, std::vector<std::uint8_t>> entries_;
};
}  // namespace abzar
