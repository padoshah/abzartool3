#include "render/rasterizer.h"
#include <algorithm>
#include <array>
#include <cmath>
#include "core/error.h"
namespace abzar {
namespace {
class Canvas {
 public:
  Canvas(std::uint32_t w,std::uint32_t h):w_(w),h_(h),rgb_(std::size_t(w)*h*3,255){}
  void pixel(int x,int y,std::array<unsigned char,3> c){if(x<0||y<0||x>=int(w_)||y>=int(h_))return;const auto p=(std::size_t(y)*w_+x)*3;rgb_[p]=c[0];rgb_[p+1]=c[1];rgb_[p+2]=c[2];}
  void rect(int x,int y,int w,int h,std::array<unsigned char,3> c){for(int yy=std::max(0,y);yy<std::min(int(h_),y+h);++yy)for(int xx=std::max(0,x);xx<std::min(int(w_),x+w);++xx)pixel(xx,yy,c);}
  void glyph(int x,int y,unsigned char ch,int scale,std::array<unsigned char,3> c){if(ch==' ')return;/* Deterministic 5x7 compact glyph: border plus character-bit strokes. */for(int row=0;row<7;++row)for(int col=0;col<5;++col){const bool edge=(row==0||row==6)&&(col>0&&col<4);const bool stem=(col==0&&(row>0&&row<6));const bool bit=((ch>>((row+col)%7))&1)!=0; if(edge||stem||(bit&&row>1&&col>1))rect(x+col*scale,y+row*scale,scale,scale,c);}}
  void text(int x,int& y,const std::string& text,int scale,std::array<unsigned char,3> c){const int advance=6*scale,line=9*scale;int cx=x;for(unsigned char ch:text){if(ch=='\n'||cx+advance>=int(w_)-x){y+=line;cx=x;if(ch=='\n')continue;}glyph(cx,y,ch,scale,c);cx+=advance;}}
  std::vector<std::uint8_t> take(){return std::move(rgb_);} private:std::uint32_t w_,h_;std::vector<std::uint8_t> rgb_;
};
}
RasterPage rasterize_page(const Page& page,int dpi){dpi=std::clamp(dpi,72,600);const auto w=static_cast<std::uint32_t>(std::max(1.0,page.geometry.width_points*dpi/72.0));const auto h=static_cast<std::uint32_t>(std::max(1.0,page.geometry.height_points*dpi/72.0));if(std::uint64_t(w)*h>150000000)throw Error(ABZ_ERROR_OUT_OF_MEMORY,"Requested raster page is too large");Canvas c(w,h);int y=static_cast<int>(page.geometry.margin_top*dpi/72.0);const int x=static_cast<int>(page.geometry.margin_left*dpi/72.0);for(const auto& block:page.blocks){if(block.image&&block.image->rgba.size()==std::size_t(block.image->width)*block.image->height*4){const auto& im=*block.image;const int dw=std::min<int>(w-2*x,im.width),dh=std::min<int>(h-y-x,im.height);for(int yy=0;yy<dh;++yy)for(int xx=0;xx<dw;++xx){const auto p=(std::size_t(yy)*im.width+xx)*4;const auto a=im.rgba[p+3];const std::array<unsigned char,3> col={static_cast<unsigned char>((im.rgba[p]*a+255*(255-a))/255),static_cast<unsigned char>((im.rgba[p+1]*a+255*(255-a))/255),static_cast<unsigned char>((im.rgba[p+2]*a+255*(255-a))/255)};c.pixel(x+xx,y+yy,col);}y+=dh+12;}for(const auto& run:block.runs){const int scale=std::max(1,static_cast<int>(std::round(run.style.font_size_points*dpi/72.0/7.0)));c.text(x,y,run.text,scale,{run.style.foreground.red,run.style.foreground.green,run.style.foreground.blue});}if(!block.runs.empty())y+=std::max(12,dpi/6);if(block.sheet){for(const auto& [ri,row]:block.sheet->cells){(void)ri;std::string line;for(const auto& [ci,cell]:row){(void)ci;if(!line.empty())line+=" | ";line+=cell.type==CellType::kNumber?std::to_string(cell.number):cell.text;}c.text(x,y,line,std::max(1,dpi/144),{0,0,0});y+=std::max(12,dpi/6);}}if(y>=int(h)-x)break;}return {w,h,c.take()};}
}  // namespace abzar
