#include "ops/document_ops.h"
#include "core/error.h"
namespace abzar::ops {
namespace { std::vector<Page*> pages(Document& d){std::vector<Page*> out;for(auto& s:d.sections)for(auto& p:s.pages)out.push_back(&p);return out;} }
void delete_page(Document& d,std::size_t index){std::size_t current=0;for(auto& section:d.sections)for(auto it=section.pages.begin();it!=section.pages.end();++it,++current)if(current==index){section.pages.erase(it);return;}throw Error(ABZ_ERROR_INVALID_ARGUMENT,"Page index is out of range");}
void reorder_pages(Document& d,const std::vector<std::size_t>& order){auto original=pages(d);if(order.size()!=original.size())throw Error(ABZ_ERROR_INVALID_ARGUMENT,"Page order must contain every page");std::vector<bool> seen(order.size());Section result;for(auto index:order){if(index>=original.size()||seen[index])throw Error(ABZ_ERROR_INVALID_ARGUMENT,"Page order is not a permutation");seen[index]=true;result.pages.push_back(*original[index]);}d.sections.clear();d.sections.push_back(std::move(result));}
void rotate_page(Document& d,std::size_t index){auto all=pages(d);if(index>=all.size())throw Error(ABZ_ERROR_INVALID_ARGUMENT,"Page index is out of range");std::swap(all[index]->geometry.width_points,all[index]->geometry.height_points);all[index]->geometry.margin_left=all[index]->geometry.margin_top;}
}  // namespace abzar::ops
