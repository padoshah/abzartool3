#include "ops/document_ops.h"
namespace abzar::ops {
void add_annotation(Page& page,const std::string& text){Block b;b.kind=Block::Kind::kAnnotation;b.runs.push_back(Run{text});b.metadata="sticky-note";page.blocks.push_back(std::move(b));}
}  // namespace abzar::ops
