#include "ooxml/content_types.h"
#include <regex>
namespace abzar::ooxml {
std::map<std::string,std::string> parse_content_types(std::string_view value){const std::string xml(value);std::map<std::string,std::string> result;const std::regex part("<(?:Override|Default)[^>]*(?:PartName|Extension)=\"([^\"]+)\"[^>]*ContentType=\"([^\"]+)\"[^>]*/?>");for(std::sregex_iterator i(xml.begin(),xml.end(),part),end;i!=end;++i)result[(*i)[1].str()]=(*i)[2].str();return result;}
}  // namespace abzar::ooxml
