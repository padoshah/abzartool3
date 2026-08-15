#include "render/canvas.h"
#include <algorithm>
namespace abzar {
CanvasBuffer::CanvasBuffer(std::uint32_t width,std::uint32_t height,std::array<std::uint8_t,3> background):width_(width),height_(height),rgb_(static_cast<std::size_t>(width)*height*3){for(std::size_t i=0;i<rgb_.size();i+=3){rgb_[i]=background[0];rgb_[i+1]=background[1];rgb_[i+2]=background[2];}}
void CanvasBuffer::set_pixel(int x,int y,std::array<std::uint8_t,3> color){if(x<0||y<0||x>=static_cast<int>(width_)||y>=static_cast<int>(height_))return;const auto offset=(static_cast<std::size_t>(y)*width_+static_cast<std::size_t>(x))*3;rgb_[offset]=color[0];rgb_[offset+1]=color[1];rgb_[offset+2]=color[2];}
void CanvasBuffer::fill_rect(int x,int y,int width,int height,std::array<std::uint8_t,3> color){for(int row=std::max(0,y);row<std::min(static_cast<int>(height_),y+height);++row)for(int column=std::max(0,x);column<std::min(static_cast<int>(width_),x+width);++column)set_pixel(column,row,color);}
}  // namespace abzar
