#include "ops/file_operations.h"

#include <filesystem>
#include <vector>

#include "core/error.h"
#include "exporters/exporter.h"
#include "importers/importer.h"

namespace abzar {
void merge_documents(const std::vector<std::filesystem::path>& inputs,
                     const std::filesystem::path& output,
                     const std::string& source_format,
                     const std::string& target_format) {
  if (inputs.size() < 2) {
    throw Error(ABZ_ERROR_INVALID_ARGUMENT, "At least two merge inputs are required");
  }
  if (source_format == "pdf" && target_format == "pdf") {
    merge_pdf_files(inputs, output);
    return;
  }
  Document merged;
  merged.source_format = source_format;
  for (const auto& path : inputs) {
    auto input_format = source_format;
    if (input_format == "auto") {
      input_format = path.extension().string();
      if (!input_format.empty() && input_format.front() == '.') input_format.erase(input_format.begin());
    }
    auto part = import_document(path, input_format);
    for (auto& section : part.sections) merged.sections.push_back(std::move(section));
    merged.warnings.insert(merged.warnings.end(), part.warnings.begin(), part.warnings.end());
  }
  export_document(merged, output, target_format, {});
}
}  // namespace abzar
