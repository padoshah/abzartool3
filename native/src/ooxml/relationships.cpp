#include "ooxml/relationships.h"
#include <regex>
#include <utility>
namespace abzar::ooxml {
std::vector<Relationship> parse_relationships(std::string_view value){const std::string xml(value);std::vector<Relationship> result;const std::regex tag("<Relationship\\s+([^>]*)/?>");const std::regex attr("([A-Za-z]+)=\"([^\"]*)\"");for(std::sregex_iterator i(xml.begin(),xml.end(),tag),end;i!=end;++i){Relationship relationship;const auto attributes=(*i)[1].str();for(std::sregex_iterator a(attributes.begin(),attributes.end(),attr),ae;a!=ae;++a){const auto name=(*a)[1].str(),content=(*a)[2].str();if(name=="Id")relationship.id=content;else if(name=="Type")relationship.type=content;else if(name=="Target")relationship.target=content;else if(name=="TargetMode")relationship.external=content=="External";}if(!relationship.id.empty()&&!relationship.target.empty())result.push_back(std::move(relationship));}return result;}
}  // namespace abzar::ooxml
