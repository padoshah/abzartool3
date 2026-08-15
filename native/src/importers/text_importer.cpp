#include "importers/importer.h"
#include <charconv>
#include "util/fs.h"
#include "util/string.h"
namespace abzar {
namespace {
std::vector<std::string> csv_row(const std::string& line){std::vector<std::string> values;std::string value;bool quoted=false;for(std::size_t i=0;i<line.size();++i){char c=line[i];if(c=='"'){if(quoted&&i+1<line.size()&&line[i+1]=='"'){value+='"';++i;}else quoted=!quoted;}else if(c==','&&!quoted){values.push_back(value);value.clear();}else value+=c;}values.push_back(value);return values;}
bool number(const std::string& text,double& value){const auto* begin=text.data();const auto* end=begin+text.size();auto result=std::from_chars(begin,end,value);return result.ec==std::errc{}&&result.ptr==end;}
}
Document import_text_document(const std::filesystem::path& path,const std::string& format){const auto bytes=fs::read_bytes(path);const auto text=strings::normalize_text_encoding(bytes);Document d;d.source_format=format;auto& page=d.ensure_page();if(format=="csv"){Block b;b.kind=Block::Kind::kSheet;b.sheet=SheetData{};std::uint32_t row=0;for(const auto& line:strings::split_lines(text)){std::uint32_t col=0;for(const auto& value:csv_row(line)){CellValue cell;double n=0;const auto normalized=strings::trim(value);if(!normalized.empty()&&normalized.front()=='='){cell.type=CellType::kFormula;cell.text=normalized.substr(1);}else if(number(normalized,n)){cell.type=CellType::kNumber;cell.number=n;}else{cell.type=CellType::kString;cell.text=value;}b.sheet->cells[row][col++]=std::move(cell);}++row;}page.blocks.push_back(std::move(b));return d;}for(const auto& line:strings::split_lines(text)){Block b;b.kind=(format=="md"&&!line.empty()&&line[0]=='#')?Block::Kind::kHeading:Block::Kind::kParagraph;Run run;run.text=line;if(b.kind==Block::Kind::kHeading){run.text=strings::trim(line.substr(line.find_first_not_of('#')));run.style.font_size_points=18;run.style.font_weight=700;}b.runs.push_back(std::move(run));page.blocks.push_back(std::move(b));}return d;}
}  // namespace abzar
