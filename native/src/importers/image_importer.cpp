#include "importers/importer.h"
#include "util/fs.h"
#include "util/image_io.h"
namespace abzar {
Document import_image_document(const std::filesystem::path& path,const std::string& format){Document d;d.source_format=format;Block b;b.kind=Block::Kind::kImage;b.image=images::decode(fs::read_bytes(path),format);auto& page=d.ensure_page();page.geometry.width_points=b.image->width*72.0/96.0;page.geometry.height_points=b.image->height*72.0/96.0;page.blocks.push_back(std::move(b));return d;}
}  // namespace abzar
