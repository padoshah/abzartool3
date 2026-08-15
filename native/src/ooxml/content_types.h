#pragma once
#include <map>
#include <string>
#include <string_view>
namespace abzar::ooxml { std::map<std::string,std::string> parse_content_types(std::string_view xml); }
