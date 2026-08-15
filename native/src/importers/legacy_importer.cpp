#include "importers/importer.h"

#include <cctype>
#include <string>

#include "core/error.h"
#include "util/fs.h"
#include "util/string.h"
#include "util/zip.h"

namespace abzar {
namespace {
std::string parse_rtf(const std::string& source) {
  std::string output;
  for (std::size_t index = 0; index < source.size();) {
    const char value = source[index++];
    if (value == '{' || value == '}') continue;
    if (value != '\\') { output += value; continue; }
    if (index >= source.size()) break;
    if (source[index] == '\\' || source[index] == '{' || source[index] == '}') { output += source[index++]; continue; }
    if (source[index] == '\'' && index + 2 < source.size()) {
      try { output += static_cast<char>(std::stoi(source.substr(index + 1, 2), nullptr, 16)); } catch (...) {}
      index += 3; continue;
    }
    const auto start = index;
    while (index < source.size() && std::isalpha(static_cast<unsigned char>(source[index]))) ++index;
    const auto word = source.substr(start, index - start);
    if (index < source.size() && (source[index] == '-' || std::isdigit(static_cast<unsigned char>(source[index])))) {
      if (source[index] == '-') ++index;
      while (index < source.size() && std::isdigit(static_cast<unsigned char>(source[index]))) ++index;
    }
    if (index < source.size() && source[index] == ' ') ++index;
    if (word == "par" || word == "line") output += '\n';
    else if (word == "tab") output += '\t';
  }
  return strings::trim(output);
}

std::string import_zip_text(const std::filesystem::path& path, const std::string& format) {
  const auto archive = ZipArchive::open(path);
  std::string output;
  for (const auto& name : archive.names()) {
    if (format == "odt" && name == "content.xml") output += strings::strip_xml(archive.text(name));
    if (format == "epub" && (name.ends_with(".xhtml") || name.ends_with(".html") || name.ends_with(".htm"))) {
      if (!output.empty()) output += '\n';
      output += strings::strip_html(archive.text(name));
    }
  }
  return strings::trim(output);
}

std::string recover_binary_text(const std::vector<std::uint8_t>& bytes) {
  std::string text, run;
  for (const unsigned char value : bytes) {
    if ((value >= 32 && value < 127) || value >= 0xc0) run += static_cast<char>(value);
    else { if (run.size() >= 4) text += run + '\n'; run.clear(); }
  }
  if (run.size() >= 4) text += run;
  return strings::trim(text);
}
}  // namespace

Document import_legacy_document(const std::filesystem::path& path,
                                const std::string& format) {
  std::string text;
  if (format == "rtf") text = parse_rtf(fs::read_text(path));
  else if (format == "odt" || format == "epub") text = import_zip_text(path, format);
  else text = recover_binary_text(fs::read_bytes(path));
  if (text.empty()) throw Error(ABZ_ERROR_CORRUPT_INPUT, "No readable content could be recovered from the legacy document");
  Document document;
  document.source_format = format;
  Block block;
  block.kind = Block::Kind::kParagraph;
  block.runs.emplace_back(text);
  document.ensure_page().blocks.push_back(std::move(block));
  if (format == "doc" || format == "xls" || format == "ppt") document.warnings.push_back("Legacy binary import uses best-effort text recovery");
  return document;
}
}  // namespace abzar
