#include "ops/file_operations.h"

#include <filesystem>
#include <string>

#include "core/error.h"
#include "util/fs.h"

#ifdef ABZAR_HAS_QPDF
#include <qpdf/Constants.h>
#include <qpdf/QPDF.hh>
#include <qpdf/QPDFObjectHandle.hh>
#include <qpdf/QPDFPageDocumentHelper.hh>
#include <qpdf/QPDFPageObjectHelper.hh>
#include <qpdf/QPDFWriter.hh>
#endif

namespace abzar {
#ifdef ABZAR_HAS_QPDF
namespace {
void write_document(QPDF& pdf,const std::filesystem::path& output){auto temporary=output;temporary+=".structure-tmp";QPDFWriter writer(pdf,temporary.string().c_str());writer.setStreamDataMode(qpdf_s_compress);writer.write();fs::write_bytes_atomic(output,fs::read_bytes(temporary));std::error_code ignored;std::filesystem::remove(temporary,ignored);}
QPDFPageObjectHelper selected_page(QPDF& pdf,int page_index){auto pages=QPDFPageDocumentHelper(pdf).getAllPages();if(page_index<0||page_index>=static_cast<int>(pages.size()))throw Error(ABZ_ERROR_INVALID_ARGUMENT,"PDF page index is out of range");return pages[static_cast<std::size_t>(page_index)];}
}
#endif

void add_pdf_bookmark(const std::filesystem::path& input,
                      const std::filesystem::path& output,
                      int page_index,const std::string& title){
  if(title.empty())throw Error(ABZ_ERROR_INVALID_ARGUMENT,"Bookmark title is required");
#ifndef ABZAR_HAS_QPDF
  (void)input;(void)output;(void)page_index;
  throw Error(ABZ_ERROR_UNSUPPORTED_FORMAT,"QPDF outline editing is not compiled into this build");
#else
  QPDF pdf;pdf.processFile(input.string().c_str());auto page=selected_page(pdf,page_index);auto catalog=pdf.getRoot();QPDFObjectHandle outlines;
  if(catalog.hasKey("/Outlines")&&catalog.getKey("/Outlines").isDictionary())outlines=catalog.getKey("/Outlines");else{outlines=pdf.makeIndirectObject(QPDFObjectHandle::newDictionary());outlines.replaceKey("/Type",QPDFObjectHandle::newName("/Outlines"));outlines.replaceKey("/Count",QPDFObjectHandle::newInteger(0));catalog.replaceKey("/Outlines",outlines);}
  auto item=pdf.makeIndirectObject(QPDFObjectHandle::newDictionary());item.replaceKey("/Title",QPDFObjectHandle::newUnicodeString(title));item.replaceKey("/Parent",outlines);auto destination=QPDFObjectHandle::newArray();destination.appendItem(page.getObjectHandle());destination.appendItem(QPDFObjectHandle::newName("/Fit"));item.replaceKey("/Dest",destination);
  if(outlines.hasKey("/Last")){auto last=outlines.getKey("/Last");last.replaceKey("/Next",item);item.replaceKey("/Prev",last);}else outlines.replaceKey("/First",item);outlines.replaceKey("/Last",item);long long count=0;if(outlines.hasKey("/Count")&&outlines.getKey("/Count").isInteger())count=outlines.getKey("/Count").getIntValue();outlines.replaceKey("/Count",QPDFObjectHandle::newInteger(count+1));write_document(pdf,output);
#endif
}

void add_pdf_text_annotation(const std::filesystem::path& input,
                             const std::filesystem::path& output,
                             int page_index,const std::string& text,
                             double x,double y){
  if(text.empty())throw Error(ABZ_ERROR_INVALID_ARGUMENT,"Annotation text is required");
#ifndef ABZAR_HAS_QPDF
  (void)input;(void)output;(void)page_index;(void)x;(void)y;
  throw Error(ABZ_ERROR_UNSUPPORTED_FORMAT,"QPDF annotation editing is not compiled into this build");
#else
  QPDF pdf;pdf.processFile(input.string().c_str());auto page=selected_page(pdf,page_index);auto annotation=QPDFObjectHandle::newDictionary();annotation.replaceKey("/Type",QPDFObjectHandle::newName("/Annot"));annotation.replaceKey("/Subtype",QPDFObjectHandle::newName("/Text"));annotation.replaceKey("/Contents",QPDFObjectHandle::newUnicodeString(text));annotation.replaceKey("/T",QPDFObjectHandle::newUnicodeString("AbzarFile"));annotation.replaceKey("/Rect",QPDFObjectHandle::parse("["+std::to_string(x)+" "+std::to_string(y)+" "+std::to_string(x+24)+" "+std::to_string(y+24)+"]"));annotation.replaceKey("/C",QPDFObjectHandle::parse("[1 0.82 0]"));annotation.replaceKey("/Open",QPDFObjectHandle::newBool(false));annotation=pdf.makeIndirectObject(annotation);auto page_object=page.getObjectHandle();QPDFObjectHandle annotations;if(page_object.hasKey("/Annots"))annotations=page_object.getKey("/Annots");else{annotations=QPDFObjectHandle::newArray();page_object.replaceKey("/Annots",annotations);}if(!annotations.isArray())throw Error(ABZ_ERROR_CORRUPT_INPUT,"PDF annotation array is invalid");annotations.appendItem(annotation);write_document(pdf,output);
#endif
}
}  // namespace abzar
