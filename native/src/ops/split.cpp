#include "ops/file_operations.h"

#include <algorithm>
#include <filesystem>
#include <set>
#include <vector>

#include "core/error.h"
#include "exporters/exporter.h"
#include "importers/importer.h"

namespace abzar {
namespace {
std::vector<Page> flatten_pages(const Document& source) {
  std::vector<Page> pages;
  for (const auto& section : source.sections) {
    pages.insert(pages.end(), section.pages.begin(), section.pages.end());
  }
  return pages;
}
std::set<std::size_t> parse_selection(const std::vector<std::string>& ranges,
                                      std::size_t page_count) {
  std::set<std::size_t> selected;
  if (ranges.empty()) {
    for (std::size_t page = 0; page < page_count; ++page) selected.insert(page);
    return selected;
  }
  for (const auto& range : ranges) {
    const auto dash = range.find('-');
    try {
      const auto first = static_cast<std::size_t>(std::stoul(range.substr(0, dash)));
      const auto last = dash == std::string::npos
                            ? first
                            : static_cast<std::size_t>(std::stoul(range.substr(dash + 1)));
      if (first == 0 || last < first || last > page_count) {
        throw Error(ABZ_ERROR_INVALID_ARGUMENT, "A page range is outside the document");
      }
      for (auto page = first; page <= last; ++page) selected.insert(page - 1);
    } catch (const Error&) {
      throw;
    } catch (...) {
      throw Error(ABZ_ERROR_INVALID_ARGUMENT, "Invalid page range: " + range);
    }
  }
  return selected;
}
}  // namespace

std::vector<std::filesystem::path> split_document(
    const std::filesystem::path& input,
    const std::filesystem::path& directory,
    const std::string& format,
    const std::vector<std::string>& ranges) {
  auto source = import_document(input, format);
  if (format == "xlsx") {
    std::filesystem::create_directories(directory);
    std::vector<std::filesystem::path> outputs;
    std::size_t sheet_number = 0;
    for (const auto& section : source.sections) for (const auto& page : section.pages) for (const auto& block : page.blocks) {
      if (!block.sheet) continue;
      Document part; part.source_format = "generated"; part.sections.emplace_back(); part.sections.front().pages.emplace_back(); part.sections.front().pages.front().blocks.push_back(block);
      const auto output = directory / (input.stem().string() + "-sheet-" + std::to_string(++sheet_number) + ".xlsx");
      export_document(part, output, "xlsx", {}); outputs.push_back(output);
    }
    if (outputs.empty()) throw Error(ABZ_ERROR_VALIDATION, "Workbook has no sheets to split");
    return outputs;
  }
  const auto pages = flatten_pages(source);
  if (pages.empty()) throw Error(ABZ_ERROR_VALIDATION, "Document has no pages to split");
  const auto selected = parse_selection(ranges, pages.size());
  std::filesystem::create_directories(directory);
  std::vector<std::filesystem::path> outputs;
  for (const auto page_index : selected) {
    Document part;
    part.source_format = format;
    part.sections.emplace_back();
    part.sections.front().pages.push_back(pages[page_index]);
    const auto output = directory /
        (input.stem().string() + "-page-" + std::to_string(page_index + 1) + "." + format);
    if (format == "pdf") extract_pdf_pages(input, output, std::to_string(page_index + 1));
    else export_document(part, output, format, {});
    outputs.push_back(output);
  }
  return outputs;
}

std::string extract_document_text(const std::filesystem::path& input,
                                  const std::string& format) {
  auto document = import_document(input, format);
  const auto text = document.plain_text();
  if (text.empty()) {
    throw Error(ABZ_ERROR_OCR_UNAVAILABLE,
                "No text was found; OCR is required for this document");
  }
  return text;
}
}  // namespace abzar
