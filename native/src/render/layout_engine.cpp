#include "render/layout_engine.h"
namespace abzar {
void paginate(Document& document) { if (document.sections.empty()) document.ensure_page(); }
}  // namespace abzar
