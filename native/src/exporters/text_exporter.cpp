#include "exporters/exporter.h"
#include <sstream>
#include "util/fs.h"
#include "util/string.h"
namespace abzar {
void export_text(const Document& d,const std::filesystem::path& path){fs::write_text_atomic(path,d.plain_text());}
void export_html(const Document& d,const std::filesystem::path& path){std::ostringstream o;o<<"<!doctype html>\n<html><head><meta charset=\"utf-8\"><meta name=\"viewport\" content=\"width=device-width\"><title>AbzarFile document</title><style>body{font-family:system-ui,sans-serif;max-width:960px;margin:2rem auto;line-height:1.5}table{border-collapse:collapse}td{border:1px solid #888;padding:.35rem}</style></head><body>\n";for(const auto& s:d.sections)for(const auto& p:s.pages)for(const auto& b:p.blocks){if(b.kind==Block::Kind::kHeading)o<<"<h2>";else o<<"<p>";for(const auto& r:b.runs)o<<strings::html_escape(r.text);if(b.kind==Block::Kind::kHeading)o<<"</h2>\n";else o<<"</p>\n";if(b.sheet){o<<"<table>\n";for(const auto& [ri,row]:b.sheet->cells){(void)ri;o<<"<tr>";for(const auto& [ci,c]:row){(void)ci;o<<"<td>"<<strings::html_escape(c.type==CellType::kNumber?std::to_string(c.number):c.text)<<"</td>";}o<<"</tr>\n";}o<<"</table>\n";}}o<<"</body></html>\n";fs::write_text_atomic(path,o.str());}
}  // namespace abzar
