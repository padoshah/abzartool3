#pragma once

#include <cstdint>
#include <map>
#include <optional>
#include <string>
#include <utility>
#include <variant>
#include <vector>

#include "core/page.h"
#include "core/style.h"

namespace abzar {

struct Run {
  Run() = default;
  explicit Run(std::string value) : text(std::move(value)) {}
  std::string text;
  Style style{};
  std::optional<std::string> hyperlink;
};

enum class CellType { kBlank, kString, kNumber, kFormula, kDate, kBoolean };
struct CellValue {
  CellType type{CellType::kBlank};
  std::string text;
  double number{0};
  Style style{};
};

struct ImageData {
  std::string mime_type;
  std::vector<std::uint8_t> encoded;
  std::vector<std::uint8_t> rgba;
  std::uint32_t width{0};
  std::uint32_t height{0};
  double x{0};
  double y{0};
  double display_width{0};
  double display_height{0};
};

struct ShapeData {
  std::string kind{"rectangle"};
  double x{0};
  double y{0};
  double width{0};
  double height{0};
  Style style{};
};

struct Block;
struct TableCell { std::vector<Block> blocks; std::size_t column_span{1}; std::size_t row_span{1}; };
struct TableRow { std::vector<TableCell> cells; };
struct TableData { std::vector<TableRow> rows; Style style{}; };
struct SheetData {
  std::string name{"Sheet1"};
  std::map<std::uint32_t, std::map<std::uint32_t, CellValue>> cells;
  std::uint32_t frozen_rows{0};
  std::uint32_t frozen_columns{0};
};

struct Block {
  enum class Kind {
    kParagraph, kHeading, kListItem, kTable, kImage, kShape, kTextBox,
    kSlide, kSheet, kPageBreak, kHeader, kFooter, kAnnotation, kHyperlink
  };
  Kind kind{Kind::kParagraph};
  std::vector<Run> runs;
  std::optional<TableData> table;
  std::optional<ImageData> image;
  std::optional<ShapeData> shape;
  std::optional<SheetData> sheet;
  Style style{};
  std::int32_t level{0};
  std::string metadata;
};

struct Page {
  PageGeometry geometry{};
  std::vector<Block> blocks;
};
struct Section { std::vector<Page> pages; PageGeometry geometry{}; };
struct Document {
  std::vector<Section> sections;
  std::map<std::string, std::string> metadata;
  std::vector<std::string> warnings;
  std::string source_format;
  // Exact source bytes are retained for lossless same-format round trips. They
  // are never modified and are discarded when exporting to another format.
  std::vector<std::uint8_t> original_package;

  [[nodiscard]] bool empty() const;
  [[nodiscard]] std::size_t page_count() const;
  [[nodiscard]] std::string plain_text() const;
  Page& ensure_page();
};

}  // namespace abzar
