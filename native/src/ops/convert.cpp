#include "exporters/exporter.h"
#include "importers/importer.h"
namespace abzar {
void convert_pipeline(const std::filesystem::path& input,const std::filesystem::path& output,const std::string& source,const std::string& target,const ExportOptions& options){const auto document=import_document(input,source);export_document(document,output,target,options);}
}  // namespace abzar
