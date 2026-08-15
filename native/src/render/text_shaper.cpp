#include "render/text_shaper.h"

#include <algorithm>

#include "core/error.h"

#ifdef ABZAR_HAS_HARFBUZZ
#include <hb.h>
#include <hb-ot.h>
#endif

namespace abzar {
std::vector<ShapedGlyph> shape_utf8(std::string_view text,double size,bool rtl){std::vector<ShapedGlyph> result;for(std::size_t i=0;i<text.size();){const auto cluster=static_cast<std::uint32_t>(i);const auto lead=static_cast<unsigned char>(text[i]);std::uint32_t cp=0;std::size_t count=1;if((lead&0x80)==0)cp=lead;else if((lead&0xe0)==0xc0&&i+1<text.size()){cp=lead&0x1f;count=2;}else if((lead&0xf0)==0xe0&&i+2<text.size()){cp=lead&0x0f;count=3;}else if((lead&0xf8)==0xf0&&i+3<text.size()){cp=lead&7;count=4;}else{cp=0xfffd;}for(std::size_t j=1;j<count;++j)cp=(cp<<6)|(static_cast<unsigned char>(text[i+j])&0x3f);const bool wide=(cp>=0x600&&cp<=0x6ff)||(cp>=0x4e00&&cp<=0x9fff);result.push_back({cp,size*(wide?0.72:0.58),cluster});i+=count;}if(rtl)std::reverse(result.begin(),result.end());return result;}

std::vector<ShapedGlyph> shape_with_font(const std::filesystem::path& font_path,
                                         std::string_view text,
                                         double font_size,
                                         bool right_to_left) {
#ifndef ABZAR_HAS_HARFBUZZ
  (void)font_path;
  return shape_utf8(text, font_size, right_to_left);
#else
  auto path = font_path.string();
  hb_blob_t* blob = hb_blob_create_from_file(path.c_str());
  if (!blob || hb_blob_get_length(blob) == 0) {
    if (blob) hb_blob_destroy(blob);
    throw Error(ABZ_ERROR_IO, "Unable to load font for text shaping");
  }
  hb_face_t* face = hb_face_create(blob, 0);
  hb_font_t* font = hb_font_create(face);
  hb_ot_font_set_funcs(font);
  const auto units = hb_face_get_upem(face);
  hb_font_set_scale(font, static_cast<int>(units), static_cast<int>(units));
  hb_buffer_t* buffer = hb_buffer_create();
  hb_buffer_add_utf8(buffer, text.data(), static_cast<int>(text.size()), 0,
                     static_cast<int>(text.size()));
  hb_buffer_guess_segment_properties(buffer);
  hb_buffer_set_direction(buffer, right_to_left ? HB_DIRECTION_RTL
                                                : HB_DIRECTION_LTR);
  hb_shape(font, buffer, nullptr, 0);
  unsigned count = 0;
  const auto* info = hb_buffer_get_glyph_infos(buffer, &count);
  const auto* positions = hb_buffer_get_glyph_positions(buffer, &count);
  const double scale = units == 0 ? 0 : font_size / static_cast<double>(units);
  std::vector<ShapedGlyph> result;
  result.reserve(count);
  for (unsigned index = 0; index < count; ++index) {
    result.push_back({info[index].codepoint,
                      positions[index].x_advance * scale,
                      info[index].cluster,
                      positions[index].x_offset * scale,
                      positions[index].y_offset * scale});
  }
  hb_buffer_destroy(buffer);
  hb_font_destroy(font);
  hb_face_destroy(face);
  hb_blob_destroy(blob);
  return result;
#endif
}
}  // namespace abzar
