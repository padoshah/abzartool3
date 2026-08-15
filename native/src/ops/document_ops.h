#pragma once
#include <cstddef>
#include <string>
#include <vector>
#include "core/doc_model.h"
namespace abzar::ops {
void delete_page(Document& document,std::size_t index);
void reorder_pages(Document& document,const std::vector<std::size_t>& order);
void rotate_page(Document& document,std::size_t index);
std::size_t remove_images(Document& document);
std::size_t replace_text(Document& document,const std::string& before,const std::string& after);
void add_watermark(Document& document,const std::string& text);
void add_annotation(Page& page,const std::string& text);
void place_signature(Page& page,ImageData signature,double x,double y,double width,double height);
void grayscale(ImageData& image);
void magic_scan(ImageData& image);
void adjust_image(ImageData& image, double brightness, double contrast,
                  bool black_and_white);
std::string extract_text_or_throw(const Document& document);
void apply_ocr(Document& document, const std::string& data_path = {});
}  // namespace abzar::ops
