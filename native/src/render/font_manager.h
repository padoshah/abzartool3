#pragma once
#include <filesystem>
#include <string>
#include <vector>
namespace abzar {
class FontManager { public: explicit FontManager(std::vector<std::filesystem::path> search_roots); [[nodiscard]] std::filesystem::path resolve(const std::string& family,bool bold,bool italic)const; private:std::vector<std::filesystem::path> roots_; };
}  // namespace abzar
