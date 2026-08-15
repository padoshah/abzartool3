#pragma once
#include <cstdint>
#include <filesystem>
#include <string_view>
#include <vector>
namespace abzar {
struct ShapedGlyph { std::uint32_t codepoint; double advance; std::uint32_t cluster; double offset_x{0}; double offset_y{0}; };
std::vector<ShapedGlyph> shape_utf8(std::string_view text,double font_size,bool right_to_left);
std::vector<ShapedGlyph> shape_with_font(const std::filesystem::path& font_path,
                                         std::string_view text,
                                         double font_size,
                                         bool right_to_left);
}  // namespace abzar
