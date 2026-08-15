#include "ops/document_ops.h"
namespace abzar::ops {
void place_signature(Page& page,ImageData image,double x,double y,double width,double height){image.x=x;image.y=y;image.display_width=width;image.display_height=height;Block b;b.kind=Block::Kind::kImage;b.image=std::move(image);b.metadata="flattened-visible-signature";page.blocks.push_back(std::move(b));}
}  // namespace abzar::ops
