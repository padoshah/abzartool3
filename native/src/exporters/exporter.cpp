#include "exporters/exporter.h"
#include "core/error.h"
#include "util/string.h"
namespace abzar {
void export_text(const Document&,const std::filesystem::path&);
void export_html(const Document&,const std::filesystem::path&);
void export_png(const Document&,const std::filesystem::path&,const ExportOptions&);
void export_jpeg(const Document&,const std::filesystem::path&,const ExportOptions&);
void export_webp(const Document&,const std::filesystem::path&,const ExportOptions&);
void export_pdf(const Document&,const std::filesystem::path&);
void export_docx(const Document&,const std::filesystem::path&);
void export_xlsx(const Document&,const std::filesystem::path&);
void export_pptx(const Document&,const std::filesystem::path&);
void export_document(const Document& d,const std::filesystem::path& path,const std::string& raw,const ExportOptions& o){const auto f=strings::lower(raw);if(f=="txt")return export_text(d,path);if(f=="html")return export_html(d,path);if(f=="png")return export_png(d,path,o);if(f=="jpg"||f=="jpeg")return export_jpeg(d,path,o);if(f=="pdf")return export_pdf(d,path);if(f=="docx")return export_docx(d,path);if(f=="xlsx")return export_xlsx(d,path);if(f=="pptx")return export_pptx(d,path);if(f=="webp")return export_webp(d,path,o);throw Error(ABZ_ERROR_UNSUPPORTED_FORMAT,"Unsupported output format: "+f);}
}  // namespace abzar
