#include "importers/importer.h"

#include <algorithm>
#include <regex>

#include "core/error.h"
#include "util/fs.h"
#include "util/string.h"
#include "util/zip.h"

namespace abzar {
namespace {
std::vector<std::string> ordered(const ZipArchive& zip,
                                 const std::string& prefix,
                                 const std::string& suffix) {
  std::vector<std::string> result;
  for (const auto& name : zip.names()) {
    if (name.starts_with(prefix) && name.ends_with(suffix)) result.push_back(name);
  }
  std::sort(result.begin(), result.end(), [](const auto& left, const auto& right) {
    const auto number = [](const std::string& value) { std::smatch match; return std::regex_search(value, match, std::regex("([0-9]+)\\.xml$")) ? std::stoi(match[1]) : 0; };
    return number(left) < number(right);
  });
  return result;
}

void append_xml_text(Page& page, const std::string& xml) {
  const auto text = strings::strip_xml(xml);
  for (const auto& line : strings::split_lines(text)) {
    if (line.empty()) continue;
    Block block; block.kind = Block::Kind::kParagraph;
    block.runs.emplace_back(line); page.blocks.push_back(std::move(block));
  }
}

void import_docx_body(Page& page, const std::string& xml) {
  const std::regex paragraph_pattern("<w:p(?:\\s[^>]*)?>([\\s\\S]*?)</w:p>");
  const std::regex run_pattern("<w:r(?:\\s[^>]*)?>([\\s\\S]*?)</w:r>");
  const std::regex text_pattern("<w:t(?:\\s[^>]*)?>([\\s\\S]*?)</w:t>");
  for (std::sregex_iterator paragraph(xml.begin(), xml.end(), paragraph_pattern), end;
       paragraph != end; ++paragraph) {
    const auto body = (*paragraph)[1].str();
    Block block;
    block.kind = body.find("<w:numPr") != std::string::npos
                     ? Block::Kind::kListItem
                     : body.find("w:pStyle w:val=\"Heading") != std::string::npos
                           ? Block::Kind::kHeading
                           : Block::Kind::kParagraph;
    for (std::sregex_iterator run(body.begin(), body.end(), run_pattern), run_end;
         run != run_end; ++run) {
      const auto run_xml = (*run)[1].str();
      std::string value;
      for (std::sregex_iterator text(run_xml.begin(), run_xml.end(), text_pattern), text_end;
           text != text_end; ++text) value += strings::strip_xml((*text)[1].str());
      if (value.empty() && run_xml.find("<w:tab") != std::string::npos) value = "\t";
      if (value.empty()) continue;
      Run styled(value);
      styled.style.font_weight = run_xml.find("<w:b") != std::string::npos ? 700 : 400;
      styled.style.italic = run_xml.find("<w:i") != std::string::npos;
      styled.style.underline = run_xml.find("<w:u") != std::string::npos;
      styled.style.strike = run_xml.find("<w:strike") != std::string::npos;
      std::smatch match;
      if (std::regex_search(run_xml, match, std::regex("<w:sz[^>]*w:val=\"([0-9]+)\""))) styled.style.font_size_points = std::stod(match[1].str()) / 2.0;
      if (std::regex_search(run_xml, match, std::regex("<w:rFonts[^>]*(?:w:ascii|w:hAnsi)=\"([^\"]+)\""))) styled.style.font_family = match[1].str();
      if (std::regex_search(run_xml, match, std::regex("<w:color[^>]*w:val=\"([0-9A-Fa-f]{6})\""))) { const auto color = std::stoul(match[1].str(), nullptr, 16); styled.style.foreground = {static_cast<std::uint8_t>(color >> 16), static_cast<std::uint8_t>(color >> 8), static_cast<std::uint8_t>(color), 255}; }
      block.runs.push_back(std::move(styled));
    }
    if (!block.runs.empty()) page.blocks.push_back(std::move(block));
  }
}

std::pair<std::uint32_t, std::uint32_t> cell_position(const std::string& attributes,
                                                       std::uint32_t fallback_row,
                                                       std::uint32_t fallback_column) {
  std::smatch match;
  if (!std::regex_search(attributes, match, std::regex("r=\"([A-Z]+)([0-9]+)\""))) return {fallback_row, fallback_column};
  std::uint32_t column = 0;
  for (const char letter : match[1].str()) column = column * 26 + static_cast<std::uint32_t>(letter - 'A' + 1);
  return {static_cast<std::uint32_t>(std::stoul(match[2].str()) - 1), column - 1};
}
}  // namespace

Document import_ooxml_document(const std::filesystem::path& path,
                               const std::string& format) {
  auto zip = ZipArchive::open(path);
  if (!zip.contains("[Content_Types].xml")) throw Error(ABZ_ERROR_CORRUPT_INPUT, "OOXML content types are missing");
  Document document; document.source_format = format; document.original_package = fs::read_bytes(path);
  if (format == "docx") {
    if (!zip.contains("word/document.xml")) throw Error(ABZ_ERROR_CORRUPT_INPUT, "DOCX document part is missing");
    import_docx_body(document.ensure_page(), zip.text("word/document.xml"));
  } else if (format == "pptx") {
    const auto slides = ordered(zip, "ppt/slides/slide", ".xml");
    if (slides.empty()) throw Error(ABZ_ERROR_CORRUPT_INPUT, "PPTX has no slides");
    document.sections.emplace_back();
    for (const auto& name : slides) { Page page; append_xml_text(page, zip.text(name)); document.sections.front().pages.push_back(std::move(page)); }
  } else if (format == "xlsx") {
    std::vector<std::string> shared;
    if (zip.contains("xl/sharedStrings.xml")) {
      const auto xml = zip.text("xl/sharedStrings.xml");
      const std::regex item("<si[^>]*>([\\s\\S]*?)</si>");
      for (std::sregex_iterator value(xml.begin(), xml.end(), item), end; value != end; ++value) shared.push_back(strings::strip_xml((*value)[1].str()));
    }
    std::vector<std::string> sheet_names;
    if(zip.contains("xl/workbook.xml")){const auto workbook=zip.text("xl/workbook.xml");const std::regex sheet_tag("<sheet[^>]*name=\"([^\"]+)\"");for(std::sregex_iterator item(workbook.begin(),workbook.end(),sheet_tag),end;item!=end;++item)sheet_names.push_back((*item)[1].str());}
    const auto sheets = ordered(zip, "xl/worksheets/sheet", ".xml");
    if (sheets.empty()) throw Error(ABZ_ERROR_CORRUPT_INPUT, "XLSX has no worksheets");
    auto& page = document.ensure_page();
    for (const auto& sheet_name : sheets) {
      Block block; block.kind = Block::Kind::kSheet; block.sheet = SheetData{}; block.sheet->name = page.blocks.size()<sheet_names.size()?sheet_names[page.blocks.size()]:"Sheet" + std::to_string(page.blocks.size() + 1);
      const auto xml = zip.text(sheet_name);
      const std::regex cell("<c([^>]*)>([\\s\\S]*?)</c>");
      std::uint32_t fallback_row = 0, fallback_column = 0;
      for (std::sregex_iterator item(xml.begin(), xml.end(), cell), end; item != end; ++item) {
        const auto attributes = (*item)[1].str(); const auto body = (*item)[2].str();
        const auto [row, column] = cell_position(attributes, fallback_row, fallback_column++);
        std::smatch match; std::string value;
        if (std::regex_search(body, match, std::regex("<v[^>]*>([^<]*)</v>"))) value = match[1].str();
        else if (std::regex_search(body, match, std::regex("<t[^>]*>([\\s\\S]*?)</t>"))) value = strings::strip_xml(match[1].str());
        CellValue cell_value;
        if (std::regex_search(body, match, std::regex("<f[^>]*>([\\s\\S]*?)</f>"))) { cell_value.type = CellType::kFormula; cell_value.text = match[1].str(); }
        else if (attributes.find("t=\"s\"") != std::string::npos) { cell_value.type = CellType::kString; try { const auto index = std::stoul(value); cell_value.text = index < shared.size() ? shared[index] : value; } catch (...) { cell_value.text = value; } }
        else { cell_value.type = CellType::kNumber; try { cell_value.number = std::stod(value); } catch (...) { cell_value.type = CellType::kString; cell_value.text = value; } }
        block.sheet->cells[row][column] = std::move(cell_value); fallback_row = row;
      }
      page.blocks.push_back(std::move(block));
    }
  }
  if (document.empty()) throw Error(ABZ_ERROR_CORRUPT_INPUT, "OOXML document has no readable content");
  return document;
}
}  // namespace abzar
