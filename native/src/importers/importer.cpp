#include "importers/importer.h"
#include "core/error.h"
#include "util/string.h"
namespace abzar {
Document import_text_document(const std::filesystem::path&,const std::string&);
Document import_html_document(const std::filesystem::path&);
Document import_image_document(const std::filesystem::path&,const std::string&);
Document import_ooxml_document(const std::filesystem::path&,const std::string&);
Document import_pdf_document(const std::filesystem::path&);
Document import_legacy_document(const std::filesystem::path&,const std::string&);
Document import_document(const std::filesystem::path& path,const std::string& raw){const auto f=strings::lower(raw);if(f=="txt"||f=="md"||f=="json"||f=="csv")return import_text_document(path,f);if(f=="html"||f=="htm")return import_html_document(path);if(f=="png"||f=="jpg"||f=="jpeg"||f=="bmp"||f=="gif"||f=="webp"||f=="tiff"||f=="tif")return import_image_document(path,f);if(f=="docx"||f=="xlsx"||f=="pptx")return import_ooxml_document(path,f);if(f=="pdf")return import_pdf_document(path);if(f=="doc"||f=="xls"||f=="ppt"||f=="rtf"||f=="odt"||f=="epub")return import_legacy_document(path,f);throw Error(ABZ_ERROR_UNSUPPORTED_FORMAT,"Unsupported input format: "+f);}
}  // namespace abzar
