#include "ops/document_ops.h"
namespace abzar::ops {
void add_watermark(Document& d,const std::string& text){for(auto& s:d.sections)for(auto& p:s.pages){Block b;b.kind=Block::Kind::kAnnotation;Run r;r.text=text;r.style.font_size_points=36;r.style.foreground={128,128,128,100};b.runs.push_back(std::move(r));b.metadata="watermark";p.blocks.push_back(std::move(b));}}
}  // namespace abzar::ops
