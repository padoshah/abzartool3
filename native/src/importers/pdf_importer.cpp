#include "importers/importer.h"

#include <algorithm>
#include <cctype>
#include <mutex>

#include "core/error.h"
#include "util/fs.h"

#ifdef ABZAR_HAS_PDFIUM
#include <fpdf_text.h>
#include <fpdfview.h>
#endif

namespace abzar {
namespace {
#ifdef ABZAR_HAS_PDFIUM
void append_utf8(std::string& output, std::uint32_t codepoint) {
  if (codepoint < 0x80) output.push_back(static_cast<char>(codepoint));
  else if (codepoint < 0x800) { output.push_back(static_cast<char>(0xc0 | (codepoint >> 6))); output.push_back(static_cast<char>(0x80 | (codepoint & 63))); }
  else if (codepoint < 0x10000) { output.push_back(static_cast<char>(0xe0 | (codepoint >> 12))); output.push_back(static_cast<char>(0x80 | ((codepoint >> 6) & 63))); output.push_back(static_cast<char>(0x80 | (codepoint & 63))); }
  else { output.push_back(static_cast<char>(0xf0 | (codepoint >> 18))); output.push_back(static_cast<char>(0x80 | ((codepoint >> 12) & 63))); output.push_back(static_cast<char>(0x80 | ((codepoint >> 6) & 63))); output.push_back(static_cast<char>(0x80 | (codepoint & 63))); }
}
Document import_with_pdfium(const std::vector<std::uint8_t>& bytes) {
  static std::once_flag initialized;
  std::call_once(initialized, [] { FPDF_InitLibrary(); });
  FPDF_DOCUMENT pdf = FPDF_LoadMemDocument64(bytes.data(), bytes.size(), nullptr);
  if (!pdf) throw Error(ABZ_ERROR_CORRUPT_INPUT, "PDFium could not open the PDF");
  Document document; document.source_format = "pdf"; document.sections.emplace_back();
  const int count = FPDF_GetPageCount(pdf);
  for (int page_index = 0; page_index < count; ++page_index) {
    FPDF_PAGE source = FPDF_LoadPage(pdf, page_index);
    if (!source) continue;
    Page page; page.geometry.width_points = FPDF_GetPageWidthF(source); page.geometry.height_points = FPDF_GetPageHeightF(source);
    FPDF_TEXTPAGE text_page = FPDFText_LoadPage(source);
    if (text_page) {
      std::string text; const int characters = FPDFText_CountChars(text_page);
      for (int index = 0; index < characters; ++index) append_utf8(text, FPDFText_GetUnicode(text_page, index));
      if (!text.empty()) { Block block; block.kind = Block::Kind::kParagraph; block.runs.emplace_back(std::move(text)); page.blocks.push_back(std::move(block)); }
      FPDFText_ClosePage(text_page);
    }
    const int width = std::max(1, static_cast<int>(page.geometry.width_points * 2));
    const int height = std::max(1, static_cast<int>(page.geometry.height_points * 2));
    FPDF_BITMAP bitmap = FPDFBitmap_Create(width, height, 1);
    if (bitmap) {
      FPDFBitmap_FillRect(bitmap, 0, 0, width, height, 0xffffffff);
      FPDF_RenderPageBitmap(bitmap, source, 0, 0, width, height, 0, FPDF_ANNOT);
      const auto* bgra = static_cast<const std::uint8_t*>(FPDFBitmap_GetBuffer(bitmap));
      const int stride = FPDFBitmap_GetStride(bitmap);
      ImageData image; image.mime_type = "image/raw-rgba"; image.width = static_cast<std::uint32_t>(width); image.height = static_cast<std::uint32_t>(height); image.rgba.resize(static_cast<std::size_t>(width) * height * 4);
      for (int y = 0; y < height; ++y) for (int x = 0; x < width; ++x) { const auto from = static_cast<std::size_t>(y) * stride + static_cast<std::size_t>(x) * 4; const auto to = (static_cast<std::size_t>(y) * width + x) * 4; image.rgba[to] = bgra[from + 2]; image.rgba[to + 1] = bgra[from + 1]; image.rgba[to + 2] = bgra[from]; image.rgba[to + 3] = bgra[from + 3]; }
      Block raster; raster.kind = Block::Kind::kImage; raster.image = std::move(image); raster.metadata = "pdf-page-raster-fallback"; page.blocks.push_back(std::move(raster));
      FPDFBitmap_Destroy(bitmap);
    }
    FPDF_ClosePage(source); document.sections.front().pages.push_back(std::move(page));
  }
  FPDF_CloseDocument(pdf);
  if (document.sections.front().pages.empty()) throw Error(ABZ_ERROR_CORRUPT_INPUT, "PDF has no readable pages");
  return document;
}
#endif
}  // namespace

Document import_pdf_document(const std::filesystem::path& path) {
  const auto bytes = fs::read_bytes(path);
  if (bytes.size() < 8 || std::string(reinterpret_cast<const char*>(bytes.data()), 5) != "%PDF-") throw Error(ABZ_ERROR_CORRUPT_INPUT, "Invalid PDF header");
#ifdef ABZAR_HAS_PDFIUM
  return import_with_pdfium(bytes);
#else
  const std::string pdf(reinterpret_cast<const char*>(bytes.data()), bytes.size());
  Document document; document.source_format = "pdf";
  std::size_t pages = 0, position = 0;
  while ((position = pdf.find("/Type /Page", position)) != std::string::npos) { if (position + 11 >= pdf.size() || pdf[position + 11] != 's') ++pages; position += 10; }
  pages = std::max<std::size_t>(1, pages); document.sections.emplace_back();
  std::string extracted;
  for (std::size_t index = 0; index < pdf.size(); ++index) {
    if (pdf[index] != '(') continue;
    std::string value;
    for (++index; index < pdf.size(); ++index) { const char character = pdf[index]; if (character == '\\' && index + 1 < pdf.size()) { const char escaped = pdf[++index]; value += escaped == 'n' ? '\n' : escaped == 'r' ? '\r' : escaped == 't' ? '\t' : escaped; continue; } if (character == ')') break; if (static_cast<unsigned char>(character) >= 32 || character == '\n') value += character; }
    if (!value.empty()) extracted += value + '\n';
  }
  for (std::size_t index = 0; index < pages; ++index) document.sections.front().pages.emplace_back();
  Block block; block.kind = Block::Kind::kParagraph; block.runs.emplace_back(extracted.empty() ? "[Raster or encoded PDF page]" : extracted); document.sections.front().pages.front().blocks.push_back(std::move(block));
  if (extracted.empty()) document.warnings.push_back("PDFium is unavailable; no directly extractable text was found");
  return document;
#endif
}
}  // namespace abzar
