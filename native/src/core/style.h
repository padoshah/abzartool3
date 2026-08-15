#pragma once

#include <cstdint>
#include <string>

namespace abzar {

enum class Alignment { kStart, kCenter, kEnd, kJustify };

struct Color {
  std::uint8_t red{0};
  std::uint8_t green{0};
  std::uint8_t blue{0};
  std::uint8_t alpha{255};
};

struct EdgeInsets {
  double left{0};
  double top{0};
  double right{0};
  double bottom{0};
};

struct Border {
  double width{0};
  Color color{};
  std::string style{"none"};
};

struct Style {
  std::string font_family{"sans-serif"};
  double font_size_points{11};
  std::int32_t font_weight{400};
  bool italic{false};
  bool underline{false};
  bool strike{false};
  Color foreground{};
  Color background{255, 255, 255, 0};
  Alignment alignment{Alignment::kStart};
  double line_height{1.2};
  EdgeInsets margin{};
  EdgeInsets padding{};
  Border border{};
  std::string number_format{"General"};
};

}  // namespace abzar
