#include "render/font_manager.h"
#include <utility>
#include "core/error.h"
#include "util/string.h"
namespace abzar {
FontManager::FontManager(std::vector<std::filesystem::path> roots):roots_(std::move(roots)){}
std::filesystem::path FontManager::resolve(const std::string& family,bool bold,bool italic)const{const auto requested=strings::lower(family);for(const auto& root:roots_){std::error_code error;if(!std::filesystem::exists(root,error))continue;for(const auto& item:std::filesystem::directory_iterator(root,error)){if(error)break;const auto name=strings::lower(item.path().filename().string());if(name.find(requested)!=std::string::npos&&(!bold||name.find("bold")!=std::string::npos)&&(!italic||name.find("italic")!=std::string::npos))return item.path();}}for(const auto& root:roots_){for(const auto fallback:{"NotoSansArabic-Variable.ttf","NotoSans-Variable.ttf"}){const auto path=root/fallback;if(std::filesystem::exists(path))return path;}}throw Error(ABZ_ERROR_IO,"No suitable document font was found");}
}  // namespace abzar
