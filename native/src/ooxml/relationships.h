#pragma once
#include <string>
#include <string_view>
#include <vector>
namespace abzar::ooxml { struct Relationship{std::string id,type,target;bool external{false};};std::vector<Relationship> parse_relationships(std::string_view xml); }
