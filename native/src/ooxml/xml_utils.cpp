#include "ooxml/xml_utils.h"
#include <string>
#include <vector>
namespace abzar::ooxml {
bool is_well_formed_xml(std::string_view xml){std::vector<std::string> stack;for(std::size_t at=0;(at=xml.find('<',at))!=xml.npos;){const auto end=xml.find('>',at+1);if(end==xml.npos)return false;if(at+1<xml.size()&&(xml[at+1]=='?'||xml[at+1]=='!')){at=end+1;continue;}const bool closing=xml[at+1]=='/';const bool empty=end>at&&xml[end-1]=='/';auto begin=at+(closing?2:1);auto finish=xml.find_first_of(" \t\r\n/",begin);if(finish==xml.npos||finish>end)finish=end;const std::string name(xml.substr(begin,finish-begin));if(name.empty())return false;if(closing){if(stack.empty()||stack.back()!=name)return false;stack.pop_back();}else if(!empty)stack.push_back(name);at=end+1;}return stack.empty();}
}  // namespace abzar::ooxml
