#include "core/doc_model.h"

#include <sstream>

namespace abzar {
namespace {
void append_block(const Block& block, std::ostringstream& out) {
  for (const auto& run : block.runs) out << run.text;
  if (block.table) {
    for (const auto& row : block.table->rows) {
      bool first = true;
      for (const auto& cell : row.cells) {
        if (!first) out << '\t';
        for (const auto& nested : cell.blocks) append_block(nested, out);
        first = false;
      }
      out << '\n';
    }
  }
  if (block.sheet) {
    for (const auto& [row_index, row] : block.sheet->cells) {
      (void)row_index;
      bool first = true;
      for (const auto& [column_index, cell] : row) {
        (void)column_index;
        if (!first) out << '\t';
        out << (cell.type == CellType::kNumber ? std::to_string(cell.number) : cell.text);
        first = false;
      }
      out << '\n';
    }
  }
  if (!block.runs.empty()) out << '\n';
}
}  // namespace

bool Document::empty() const {
  for (const auto& section : sections)
    for (const auto& page : section.pages)
      if (!page.blocks.empty()) return false;
  return true;
}

std::size_t Document::page_count() const {
  std::size_t count = 0;
  for (const auto& section : sections) count += section.pages.size();
  return count;
}

std::string Document::plain_text() const {
  std::ostringstream out;
  for (const auto& section : sections)
    for (const auto& page : section.pages)
      for (const auto& block : page.blocks) append_block(block, out);
  return out.str();
}

Page& Document::ensure_page() {
  if (sections.empty()) sections.emplace_back();
  if (sections.front().pages.empty()) sections.front().pages.emplace_back();
  return sections.front().pages.front();
}

}  // namespace abzar
