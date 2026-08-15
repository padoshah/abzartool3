#include "ops/document_ops.h"
#include "ops/file_operations.h"

#include <filesystem>
#include <memory>
#include <string>
#include <vector>

#include "core/error.h"
#include "util/fs.h"
#include "util/image_io.h"

#ifdef ABZAR_HAS_QPDF
#include <qpdf/Constants.h>
#include <qpdf/QPDF.hh>
#include <qpdf/QPDFObjectHandle.hh>
#include <qpdf/QPDFPageDocumentHelper.hh>
#include <qpdf/QPDFPageObjectHelper.hh>
#include <qpdf/QPDFTokenizer.hh>
#include <qpdf/QPDFWriter.hh>
#endif

namespace abzar::ops {
std::size_t replace_text(Document& document, const std::string& before,
                         const std::string& after) {
  if (before.empty()) return 0;
  std::size_t count = 0;
  for (auto& section : document.sections) for (auto& page : section.pages)
    for (auto& block : page.blocks) for (auto& run : block.runs) {
      std::size_t at = 0;
      while ((at = run.text.find(before, at)) != std::string::npos) {
        run.text.replace(at, before.size(), after); at += after.size(); ++count;
      }
    }
  return count;
}
}  // namespace abzar::ops

namespace abzar {
#ifdef ABZAR_HAS_QPDF
namespace {
class TextObjectReplacer final : public QPDFObjectHandle::TokenFilter {
 public:
  TextObjectReplacer(std::string search, std::string replacement,
                     std::shared_ptr<std::size_t> count)
      : search_(std::move(search)), replacement_(std::move(replacement)),
        count_(std::move(count)) {}
  void handleToken(QPDFTokenizer::Token const& token) override {
    if (token.getType() != QPDFTokenizer::tt_string) { writeToken(token); return; }
    auto value = token.getValue();
    std::size_t position = 0;
    while ((position = value.find(search_, position)) != std::string::npos) {
      value.replace(position, search_.size(), replacement_);
      position += replacement_.size(); ++*count_;
    }
    writeToken(QPDFTokenizer::Token(QPDFTokenizer::tt_string, value));
  }
 private:
  std::string search_, replacement_;
  std::shared_ptr<std::size_t> count_;
};

class ImageInvocationRemover final : public QPDFObjectHandle::TokenFilter {
 public:
  ImageInvocationRemover(std::string name,std::shared_ptr<std::size_t> count):name_(name.starts_with('/')?std::move(name):"/"+name),count_(std::move(count)){}
  void handleToken(QPDFTokenizer::Token const& token) override {
    const auto type=token.getType();const bool ignorable=type==QPDFTokenizer::tt_space||type==QPDFTokenizer::tt_comment;
    if(!pending_){if(type==QPDFTokenizer::tt_name&&token.getValue()==name_){pending_=true;tokens_.push_back(token);}else writeToken(token);return;}
    tokens_.push_back(token);if(ignorable)return;if(token.isWord("Do")){tokens_.clear();pending_=false;++*count_;return;}for(const auto& item:tokens_)writeToken(item);tokens_.clear();pending_=false;
  }
  void handleEOF() override {for(const auto& token:tokens_)writeToken(token);tokens_.clear();}
 private:
  std::string name_;std::shared_ptr<std::size_t> count_;bool pending_{false};std::vector<QPDFTokenizer::Token> tokens_;
};

void write_pdf_atomic(QPDF& pdf, const std::filesystem::path& output) {
  auto temporary = output; temporary += ".qpdf-edit-tmp";
  QPDFWriter writer(pdf, temporary.string().c_str());
  writer.setStreamDataMode(qpdf_s_compress);
  writer.setCompressStreams(true);
  writer.write();
  const auto bytes = fs::read_bytes(temporary);
  fs::write_bytes_atomic(output, bytes);
  std::error_code ignored; std::filesystem::remove(temporary, ignored);
}
}
#endif

std::size_t replace_pdf_text_objects(const std::filesystem::path& input,
                                     const std::filesystem::path& output,
                                     const std::string& search,
                                     const std::string& replacement,
                                     int page_index) {
  if (search.empty()) throw Error(ABZ_ERROR_INVALID_ARGUMENT, "PDF search text must not be empty");
#ifndef ABZAR_HAS_QPDF
  (void)input; (void)output; (void)replacement; (void)page_index;
  throw Error(ABZ_ERROR_UNSUPPORTED_FORMAT, "QPDF text-object editing is not compiled into this build");
#else
  QPDF pdf; pdf.processFile(input.string().c_str());
  auto pages = QPDFPageDocumentHelper(pdf).getAllPages();
  if (page_index >= static_cast<int>(pages.size())) throw Error(ABZ_ERROR_INVALID_ARGUMENT, "PDF page index is out of range");
  auto count = std::make_shared<std::size_t>(0);
  for (std::size_t index = 0; index < pages.size(); ++index) {
    if (page_index >= 0 && index != static_cast<std::size_t>(page_index)) continue;
    pages[index].addContentTokenFilter(std::make_shared<TextObjectReplacer>(search, replacement, count));
  }
  write_pdf_atomic(pdf, output);
  if (*count == 0) { std::error_code ignored; std::filesystem::remove(output, ignored); throw Error(ABZ_ERROR_VALIDATION, "Text was not found in decoded PDF text objects"); }
  return *count;
#endif
}

void delete_pdf_image_object(const std::filesystem::path& input,
                             const std::filesystem::path& output,
                             int page_index,
                             const std::string& object_name) {
  if(object_name.empty())throw Error(ABZ_ERROR_INVALID_ARGUMENT,"PDF image object name is required");
#ifndef ABZAR_HAS_QPDF
  (void)input;(void)output;(void)page_index;
  throw Error(ABZ_ERROR_UNSUPPORTED_FORMAT,"QPDF image-object editing is not compiled into this build");
#else
  QPDF pdf;pdf.processFile(input.string().c_str());auto pages=QPDFPageDocumentHelper(pdf).getAllPages();if(page_index<0||page_index>=static_cast<int>(pages.size()))throw Error(ABZ_ERROR_INVALID_ARGUMENT,"PDF page index is out of range");auto& page=pages[static_cast<std::size_t>(page_index)];auto resources=page.getAttribute("/Resources",true);if(!resources.isDictionary()||!resources.hasKey("/XObject"))throw Error(ABZ_ERROR_VALIDATION,"PDF page has no image resources");auto xobjects=resources.getKey("/XObject");const auto name=object_name.starts_with('/')?object_name:"/"+object_name;if(!xobjects.hasKey(name))throw Error(ABZ_ERROR_VALIDATION,"Requested PDF image object was not found");auto object=xobjects.getKey(name);if(!object.isStream()||!object.getDict().getKey("/Subtype").isNameAndEquals("/Image"))throw Error(ABZ_ERROR_VALIDATION,"Requested PDF object is not an image");auto count=std::make_shared<std::size_t>(0);page.addContentTokenFilter(std::make_shared<ImageInvocationRemover>(name,count));xobjects.removeKey(name);write_pdf_atomic(pdf,output);if(*count==0)throw Error(ABZ_ERROR_VALIDATION,"Image resource existed but was not painted on the page");
#endif
}

void add_pdf_image_object(const std::filesystem::path& input,
                          const std::filesystem::path& output,
                          int page_index,
                          const std::filesystem::path& image_path,
                          const std::string& image_format,
                          double x, double y, double width, double height) {
#ifndef ABZAR_HAS_QPDF
  (void)input;(void)output;(void)page_index;(void)image_path;(void)image_format;(void)x;(void)y;(void)width;(void)height;
  throw Error(ABZ_ERROR_UNSUPPORTED_FORMAT,"QPDF image-object editing is not compiled into this build");
#else
  auto decoded=images::decode(fs::read_bytes(image_path),image_format);QPDF pdf;pdf.processFile(input.string().c_str());auto pages=QPDFPageDocumentHelper(pdf).getAllPages();if(page_index<0||page_index>=static_cast<int>(pages.size()))throw Error(ABZ_ERROR_INVALID_ARGUMENT,"PDF page index is out of range");
  std::string rgb;rgb.reserve(static_cast<std::size_t>(decoded.width)*decoded.height*3);for(std::size_t index=0;index<decoded.rgba.size();index+=4){const auto alpha=decoded.rgba[index+3];for(std::size_t channel=0;channel<3;++channel)rgb.push_back(static_cast<char>((decoded.rgba[index+channel]*alpha+255*(255-alpha))/255));}
  auto image=pdf.newStream(rgb);auto dictionary=image.getDict();dictionary.replaceKey("/Type",QPDFObjectHandle::newName("/XObject"));dictionary.replaceKey("/Subtype",QPDFObjectHandle::newName("/Image"));dictionary.replaceKey("/Width",QPDFObjectHandle::newInteger(decoded.width));dictionary.replaceKey("/Height",QPDFObjectHandle::newInteger(decoded.height));dictionary.replaceKey("/BitsPerComponent",QPDFObjectHandle::newInteger(8));dictionary.replaceKey("/ColorSpace",QPDFObjectHandle::newName("/DeviceRGB"));
  auto resources=pages[static_cast<std::size_t>(page_index)].getAttribute("/Resources",true);if(!resources.isDictionary())throw Error(ABZ_ERROR_CORRUPT_INPUT,"PDF page resources are invalid");QPDFObjectHandle xobjects;if(resources.hasKey("/XObject"))xobjects=resources.getKey("/XObject");else{xobjects=QPDFObjectHandle::newDictionary();resources.replaceKey("/XObject",xobjects);}int suffix=1;std::string name;do{name="/AbzarImage"+std::to_string(suffix++);}while(xobjects.hasKey(name));xobjects.replaceKey(name,image);
  if(width<=0)width=decoded.width;if(height<=0)height=decoded.height;const auto content="q "+std::to_string(width)+" 0 0 "+std::to_string(height)+" "+std::to_string(x)+" "+std::to_string(y)+" cm "+name+" Do Q\n";pages[static_cast<std::size_t>(page_index)].addPageContents(pdf.newStream(content),false);write_pdf_atomic(pdf,output);
#endif
}

void replace_pdf_image_object(const std::filesystem::path& input,
                              const std::filesystem::path& output,
                              int page_index, const std::string& object_name,
                              const std::filesystem::path& replacement_path,
                              const std::string& replacement_format) {
#ifndef ABZAR_HAS_QPDF
  (void)input; (void)output; (void)page_index; (void)object_name;
  (void)replacement_path; (void)replacement_format;
  throw Error(ABZ_ERROR_UNSUPPORTED_FORMAT, "QPDF image-object editing is not compiled into this build");
#else
  auto image = images::decode(fs::read_bytes(replacement_path), replacement_format);
  QPDF pdf; pdf.processFile(input.string().c_str());
  auto pages = QPDFPageDocumentHelper(pdf).getAllPages();
  if (page_index < 0 || page_index >= static_cast<int>(pages.size())) throw Error(ABZ_ERROR_INVALID_ARGUMENT, "PDF page index is out of range");
  auto resources = pages[static_cast<std::size_t>(page_index)].getAttribute("/Resources", true);
  if (!resources.isDictionary() || !resources.hasKey("/XObject")) throw Error(ABZ_ERROR_VALIDATION, "PDF page has no image resources");
  auto xobjects = resources.getKey("/XObject");
  bool replaced = false;
  for (const auto& name : xobjects.getKeys()) {
    if (!object_name.empty() && name != object_name && name != "/" + object_name) continue;
    auto object = xobjects.getKey(name);
    if (!object.isStream() || !object.getDict().getKey("/Subtype").isNameAndEquals("/Image")) continue;
    std::string rgb; rgb.reserve(static_cast<std::size_t>(image.width) * image.height * 3);
    for (std::size_t index = 0; index < image.rgba.size(); index += 4) {
      const auto alpha = image.rgba[index + 3];
      for (std::size_t channel = 0; channel < 3; ++channel) rgb.push_back(static_cast<char>((image.rgba[index + channel] * alpha + 255 * (255 - alpha)) / 255));
    }
    auto dictionary = object.getDict();
    dictionary.replaceKey("/Width", QPDFObjectHandle::newInteger(image.width));
    dictionary.replaceKey("/Height", QPDFObjectHandle::newInteger(image.height));
    dictionary.replaceKey("/BitsPerComponent", QPDFObjectHandle::newInteger(8));
    dictionary.replaceKey("/ColorSpace", QPDFObjectHandle::newName("/DeviceRGB"));
    object.replaceStreamData(rgb, QPDFObjectHandle::newNull(), QPDFObjectHandle::newNull());
    replaced = true; break;
  }
  if (!replaced) throw Error(ABZ_ERROR_VALIDATION, "Requested PDF image object was not found");
  write_pdf_atomic(pdf, output);
#endif
}
}  // namespace abzar
