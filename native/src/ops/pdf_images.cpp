#include "ops/document_ops.h"
#include <algorithm>
namespace abzar::ops {
std::size_t remove_images(Document& d){std::size_t count=0;for(auto& s:d.sections)for(auto& p:s.pages){const auto before=p.blocks.size();std::erase_if(p.blocks,[](const Block& b){return b.kind==Block::Kind::kImage;});count+=before-p.blocks.size();}return count;}
}  // namespace abzar::ops
