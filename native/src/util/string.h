#pragma once
#include <string>
#include <string_view>
#include <vector>
namespace abzar::strings {
std::string lower(std::string value);
std::string trim(std::string value);
std::string xml_escape(std::string_view value);
std::string html_escape(std::string_view value);
std::string json_escape(std::string_view value);
std::string strip_xml(std::string_view xml);
std::string strip_html(std::string_view html);
std::vector<std::string> split_lines(std::string_view value);
std::string normalize_text_encoding(const std::vector<unsigned char>& bytes);
std::string json_string(std::string_view json, std::string_view key);
int json_integer(std::string_view json, std::string_view key, int fallback);
bool json_boolean(std::string_view json, std::string_view key, bool fallback);
std::vector<std::string> json_string_array(std::string_view json);
}  // namespace abzar::strings
