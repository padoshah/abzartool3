#include "ops/document_ops.h"

#include <iterator>
#include <memory>
#include <string>
#include <utility>
#include <vector>

#include "core/error.h"
#include "util/string.h"

#ifdef ABZAR_HAS_TESSERACT
#include <tesseract/baseapi.h>
#endif

namespace abzar::ops {
void apply_ocr(Document& document, const std::string& data_path) {
#ifdef ABZAR_HAS_TESSERACT
  tesseract::TessBaseAPI engine;
  const char* data = data_path.empty() ? nullptr : data_path.c_str();
  if (engine.Init(data, "eng+fas", tesseract::OEM_LSTM_ONLY) != 0) {
    throw Error(ABZ_ERROR_OCR_UNAVAILABLE,
                "Tesseract could not load eng and fas trained data");
  }
  bool recognized = false;
  for (auto& section : document.sections) {
    for (auto& page : section.pages) {
      std::vector<Block> recognized_blocks;
      for (const auto& block : page.blocks) {
        if (!block.image || block.image->rgba.empty()) continue;
        const auto& image = *block.image;
        engine.SetImage(image.rgba.data(), static_cast<int>(image.width),
                        static_cast<int>(image.height), 4,
                        static_cast<int>(image.width * 4));
        std::unique_ptr<char[]> raw(engine.GetUTF8Text());
        if (!raw) continue;
        auto text = strings::trim(raw.get());
        if (text.empty()) continue;
        Block paragraph;
        paragraph.kind = Block::Kind::kParagraph;
        paragraph.runs.emplace_back(std::move(text));
        paragraph.metadata = "ocr-text-layer";
        recognized_blocks.push_back(std::move(paragraph));
        recognized = true;
      }
      page.blocks.insert(page.blocks.end(),
                         std::make_move_iterator(recognized_blocks.begin()),
                         std::make_move_iterator(recognized_blocks.end()));
    }
  }
  engine.End();
  if (!recognized) {
    throw Error(ABZ_ERROR_OCR_UNAVAILABLE,
                "OCR completed but no text was recognized");
  }
#else
  (void)document;
  (void)data_path;
  throw Error(ABZ_ERROR_OCR_UNAVAILABLE, "OCR is not compiled into this build");
#endif
}

std::string extract_text_or_throw(const Document& document) {
  const auto text = document.plain_text();
  if (!text.empty()) return text;
  throw Error(ABZ_ERROR_OCR_UNAVAILABLE,
              "OCR is required because the document has no text layer");
}
}  // namespace abzar::ops
