#include "ooxml/opc_package.h"
#include "core/error.h"
#include "ooxml/content_types.h"
#include "ooxml/xml_utils.h"
namespace abzar::ooxml {
OpcPackage OpcPackage::open(const std::filesystem::path& path){auto zip=ZipArchive::open(path);if(!zip.contains("[Content_Types].xml"))throw Error(ABZ_ERROR_CORRUPT_INPUT,"OPC package has no content types");const auto types=zip.text("[Content_Types].xml");if(!is_well_formed_xml(types)||parse_content_types(types).empty())throw Error(ABZ_ERROR_CORRUPT_INPUT,"OPC content types are malformed");return OpcPackage(std::move(zip));}
std::string OpcPackage::required_xml(const std::string& part)const{const auto value=archive_.text(part);if(value.find('<')==std::string::npos)throw Error(ABZ_ERROR_CORRUPT_INPUT,"OPC XML part is malformed: "+part);return value;}
}  // namespace abzar::ooxml
