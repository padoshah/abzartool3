#pragma once
#include <cstdint>
#include <filesystem>
#include <string>
#include <vector>
namespace abzar::fs {
std::vector<std::uint8_t> read_bytes(const std::filesystem::path& path);
std::string read_text(const std::filesystem::path& path);
void write_bytes_atomic(const std::filesystem::path& path, const std::vector<std::uint8_t>& bytes);
void write_text_atomic(const std::filesystem::path& path, const std::string& text);
std::uint64_t file_size(const std::filesystem::path& path);
}  // namespace abzar::fs
