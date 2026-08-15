#pragma once
#include <filesystem>
#include <string>
#include "core/doc_model.h"
namespace abzar {
struct ExportOptions { int dpi{150}; int quality{90}; bool stitch_pages{false}; bool embed_images{true}; };
void export_document(const Document& document, const std::filesystem::path& path, const std::string& format, const ExportOptions& options);
}  // namespace abzar
