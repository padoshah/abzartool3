#pragma once
#include <filesystem>
#include <string>
#include "util/zip.h"
namespace abzar::ooxml {
class OpcPackage { public: static OpcPackage open(const std::filesystem::path& path); explicit OpcPackage(ZipArchive archive):archive_(std::move(archive)){} [[nodiscard]] std::string required_xml(const std::string& part)const; [[nodiscard]] const ZipArchive& archive()const{return archive_;} private:ZipArchive archive_; };
}  // namespace abzar::ooxml
