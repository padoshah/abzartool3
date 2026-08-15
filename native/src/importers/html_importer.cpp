#include "importers/importer.h"
#include "util/fs.h"
#include "util/string.h"
namespace abzar {
Document import_html_document(const std::filesystem::path& path){Document d;d.source_format="html";auto& page=d.ensure_page();const auto text=strings::strip_html(fs::read_text(path));for(const auto& line:strings::split_lines(text)){Block b;b.kind=Block::Kind::kParagraph;b.runs.push_back(Run{line});page.blocks.push_back(std::move(b));}return d;}
}  // namespace abzar
