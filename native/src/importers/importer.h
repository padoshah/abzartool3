#pragma once
#include <filesystem>
#include <string>
#include "core/doc_model.h"
namespace abzar { Document import_document(const std::filesystem::path& path, const std::string& format); }
