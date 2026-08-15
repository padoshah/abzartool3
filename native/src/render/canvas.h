#pragma once
#include <array>
#include <cstdint>
#include <vector>
namespace abzar {
class CanvasBuffer {
 public:
  CanvasBuffer(std::uint32_t width,std::uint32_t height,std::array<std::uint8_t,3> background={255,255,255});
  void set_pixel(int x,int y,std::array<std::uint8_t,3> color);
  void fill_rect(int x,int y,int width,int height,std::array<std::uint8_t,3> color);
  [[nodiscard]] std::uint32_t width()const{return width_;}
  [[nodiscard]] std::uint32_t height()const{return height_;}
  [[nodiscard]] const std::vector<std::uint8_t>& rgb()const{return rgb_;}
 private:
  std::uint32_t width_,height_;std::vector<std::uint8_t> rgb_;
};
}  // namespace abzar
