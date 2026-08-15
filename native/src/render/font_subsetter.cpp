#include "render/font_subsetter.h"
#include "core/error.h"
#ifdef ABZAR_HAS_HARFBUZZ_SUBSET
#include <hb.h>
#include <hb-subset.h>
#endif
namespace abzar {
std::vector<std::uint8_t> subset_font(const std::filesystem::path& font_path,const std::vector<std::uint32_t>& codepoints){
#ifndef ABZAR_HAS_HARFBUZZ_SUBSET
  (void)font_path;(void)codepoints;throw Error(ABZ_ERROR_UNSUPPORTED_FORMAT,"HarfBuzz font subsetting is not compiled into this build");
#else
  const auto path=font_path.string();hb_blob_t* blob=hb_blob_create_from_file(path.c_str());if(!blob||hb_blob_get_length(blob)==0){if(blob)hb_blob_destroy(blob);throw Error(ABZ_ERROR_IO,"Unable to load font for subsetting");}hb_face_t* face=hb_face_create(blob,0);hb_subset_input_t* input=hb_subset_input_create_or_fail();if(!input){hb_face_destroy(face);hb_blob_destroy(blob);throw Error(ABZ_ERROR_OUT_OF_MEMORY,"Unable to allocate font subset request");}hb_set_t* unicodes=hb_subset_input_unicode_set(input);for(const auto codepoint:codepoints)hb_set_add(unicodes,codepoint);hb_subset_input_set_flags(input,static_cast<hb_subset_flags_t>(HB_SUBSET_FLAGS_RETAIN_GIDS|HB_SUBSET_FLAGS_PASSTHROUGH_UNRECOGNIZED));hb_face_t* subset=hb_subset_or_fail(face,input);hb_subset_input_destroy(input);hb_face_destroy(face);hb_blob_destroy(blob);if(!subset)throw Error(ABZ_ERROR_VALIDATION,"Font could not be subset for requested glyphs");hb_blob_t* result=hb_face_reference_blob(subset);unsigned length=0;const char* data=hb_blob_get_data(result,&length);std::vector<std::uint8_t> bytes(data,data+length);hb_blob_destroy(result);hb_face_destroy(subset);return bytes;
#endif
}
}  // namespace abzar
