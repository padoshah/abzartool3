#pragma once
#include <cstdint>
#include <filesystem>
#include <vector>
namespace abzar {
std::vector<std::uint8_t> subset_font(const std::filesystem::path& font_path,
                                      const std::vector<std::uint32_t>& codepoints);
}  // namespace abzar
