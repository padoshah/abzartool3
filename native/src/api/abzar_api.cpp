#include "abzar/abzar_api.h"
#include <cstdlib>
#include <cstring>
#include <filesystem>
#include <new>
#include <string>
#include <vector>
#include "core/error.h"
#include "core/job.h"
#include "ops/file_operations.h"
#include "util/string.h"
struct AbzJob { abzar::Job implementation; explicit AbzJob(abzar::JobSpec s):implementation(std::move(s)){} };
namespace {
void set_string(char** target,const std::string& value){if(!target)return;*target=static_cast<char*>(std::malloc(value.size()+1));if(*target)std::memcpy(*target,value.c_str(),value.size()+1);}
void set_error(char** target,const std::string& message){set_string(target,message);}
template <typename Operation>
int32_t guard_operation(char** error,Operation operation){if(error)*error=nullptr;try{operation();return ABZ_OK;}catch(const abzar::Error& e){set_error(error,e.what());return e.code();}catch(const std::bad_alloc&){set_error(error,"Not enough memory");return ABZ_ERROR_OUT_OF_MEMORY;}catch(const std::exception& e){set_error(error,e.what());return ABZ_ERROR_INTERNAL;}catch(...){set_error(error,"Unknown native failure");return ABZ_ERROR_INTERNAL;}}
}
extern "C" {
uint32_t abz_abi_version(void){return ABZAR_ABI_VERSION;}
const char* abz_engine_version(void){return "1.0.0";}
const char* abz_build_features(void){
#ifdef ABZAR_HAS_PDFIUM
#define ABZ_PDFIUM "true"
#else
#define ABZ_PDFIUM "false"
#endif
#ifdef ABZAR_HAS_QPDF
#define ABZ_QPDF "true"
#else
#define ABZ_QPDF "false"
#endif
#ifdef ABZAR_HAS_TESSERACT
#define ABZ_OCR "true"
#else
#define ABZ_OCR "false"
#endif
#ifdef ABZAR_HAS_OPENCV
#define ABZ_OPENCV "true"
#else
#define ABZ_OPENCV "false"
#endif
#ifdef ABZAR_HAS_HARFBUZZ
#define ABZ_SHAPING "true"
#else
#define ABZ_SHAPING "false"
#endif
#ifdef ABZAR_HAS_HARFBUZZ_SUBSET
#define ABZ_SUBSET "true"
#else
#define ABZ_SUBSET "false"
#endif
  return "{\"pdfium\":" ABZ_PDFIUM ",\"qpdf\":" ABZ_QPDF ",\"ocr\":" ABZ_OCR ",\"opencv\":" ABZ_OPENCV ",\"textShaping\":" ABZ_SHAPING ",\"fontSubsetting\":" ABZ_SUBSET "}";
}
int32_t abz_is_format_supported(const char* ext,int32_t output){if(!ext)return 0;const auto f=abzar::strings::lower(ext);if(output)return f=="docx"||f=="xlsx"||f=="pptx"||f=="pdf"||f=="html"||f=="txt"||f=="png"||f=="jpg"||f=="webp";return f=="docx"||f=="xlsx"||f=="pptx"||f=="pdf"||f=="html"||f=="txt"||f=="png"||f=="jpg"||f=="csv"||f=="md"||f=="json"||f=="doc"||f=="xls"||f=="ppt"||f=="rtf"||f=="odt"||f=="epub"||f=="bmp"||f=="gif"||f=="webp"||f=="tiff"||f=="tif";}
AbzJob* abz_job_create(const char* json){if(!json)return nullptr;try{return new AbzJob(abzar::parse_job_spec(json));}catch(...){return nullptr;}}
int32_t abz_job_run(AbzJob* job,AbzProgressCallback cb,void* data){return job?job->implementation.run(cb,data):ABZ_ERROR_INVALID_ARGUMENT;}
void abz_job_cancel(AbzJob* job){if(job)job->implementation.cancel();}
int32_t abz_job_report(const AbzJob* job,AbzJobReport* report){if(!job||!report||report->struct_size<sizeof(AbzJobReport))return ABZ_ERROR_INVALID_ARGUMENT;*report=job->implementation.report();return ABZ_OK;}
const char* abz_job_error_message(const AbzJob* job){if(!job)return "Invalid job";thread_local std::string message;message=job->implementation.error_message();return message.c_str();}
const char* abz_job_report_json(const AbzJob* job){return job?const_cast<AbzJob*>(job)->implementation.report_json():"{}";}
void abz_job_destroy(AbzJob* job){delete job;}
int32_t abz_convert_file(const char* in,const char* out,const char* source,const char* target,const char* options,char** error){if(error)*error=nullptr;if(!in||!out||!source||!target){set_error(error,"Invalid conversion argument");return ABZ_ERROR_INVALID_ARGUMENT;}try{std::string json="{\"inputPath\":\""+abzar::strings::json_escape(in)+"\",\"outputPath\":\""+abzar::strings::json_escape(out)+"\",\"sourceFormat\":\""+abzar::strings::json_escape(source)+"\",\"targetFormat\":\""+abzar::strings::json_escape(target)+"\"";if(options&&std::strlen(options)>2)json+=","+std::string(options+1,std::strlen(options)-2);json+="}";AbzJob job(abzar::parse_job_spec(json));const int result=job.implementation.run(nullptr,nullptr);if(result!=ABZ_OK)set_error(error,job.implementation.error_message());return result;}catch(const abzar::Error& e){set_error(error,e.what());return e.code();}catch(const std::exception& e){set_error(error,e.what());return ABZ_ERROR_INTERNAL;}catch(...){set_error(error,"Unknown conversion failure");return ABZ_ERROR_INTERNAL;}}
int32_t abz_compress_file(const char* input,const char* output,const char* format,int32_t level,char** error){if(!input||!output||!format){set_error(error,"Invalid compression argument");return ABZ_ERROR_INVALID_ARGUMENT;}return guard_operation(error,[&]{abzar::compress_file(input,output,format,level);});}
int32_t abz_merge_files(const char* paths_json,const char* output,const char* source,const char* target,char** error){if(!paths_json||!output||!source||!target){set_error(error,"Invalid merge argument");return ABZ_ERROR_INVALID_ARGUMENT;}return guard_operation(error,[&]{std::vector<std::filesystem::path> paths;for(const auto& value:abzar::strings::json_string_array(paths_json))paths.emplace_back(value);abzar::merge_documents(paths,output,source,target);});}
int32_t abz_split_file(const char* input,const char* directory,const char* format,const char* ranges_json,char** outputs_json,char** error){if(outputs_json)*outputs_json=nullptr;if(!input||!directory||!format){set_error(error,"Invalid split argument");return ABZ_ERROR_INVALID_ARGUMENT;}return guard_operation(error,[&]{const auto ranges=ranges_json?abzar::strings::json_string_array(ranges_json):std::vector<std::string>{};const auto outputs=abzar::split_document(input,directory,format,ranges);std::string json="[";for(std::size_t i=0;i<outputs.size();++i){if(i)json+=",";json+="\""+abzar::strings::json_escape(outputs[i].string())+"\"";}json+="]";set_string(outputs_json,json);});}
int32_t abz_extract_text(const char* input,const char* format,char** text,char** error){if(text)*text=nullptr;if(!input||!format){set_error(error,"Invalid extraction argument");return ABZ_ERROR_INVALID_ARGUMENT;}return guard_operation(error,[&]{set_string(text,abzar::extract_document_text(input,format));});}
int32_t abz_encrypt_container(const char* input,const char* output,const char* password,char** error){if(!input||!output||!password){set_error(error,"Invalid encryption argument");return ABZ_ERROR_INVALID_ARGUMENT;}return guard_operation(error,[&]{abzar::encrypt_container(input,output,password);});}
int32_t abz_decrypt_container(const char* input,const char* output,const char* password,char** error){if(!input||!output||!password){set_error(error,"Invalid decryption argument");return ABZ_ERROR_INVALID_ARGUMENT;}return guard_operation(error,[&]{abzar::decrypt_container(input,output,password);});}
int32_t abz_pdf_replace_text(const char* input,const char* output,const char* search,const char* replacement,int32_t page_index,char** error){if(!input||!output||!search||!replacement){set_error(error,"Invalid PDF text-edit argument");return ABZ_ERROR_INVALID_ARGUMENT;}return guard_operation(error,[&]{abzar::replace_pdf_text_objects(input,output,search,replacement,page_index);});}
int32_t abz_pdf_delete_image(const char* input,const char* output,int32_t page_index,const char* object_name,char** error){if(!input||!output||!object_name){set_error(error,"Invalid PDF delete-image argument");return ABZ_ERROR_INVALID_ARGUMENT;}return guard_operation(error,[&]{abzar::delete_pdf_image_object(input,output,page_index,object_name);});}
int32_t abz_pdf_add_image(const char* input,const char* output,int32_t page_index,const char* image_path,const char* image_format,double x,double y,double width,double height,char** error){if(!input||!output||!image_path||!image_format){set_error(error,"Invalid PDF add-image argument");return ABZ_ERROR_INVALID_ARGUMENT;}return guard_operation(error,[&]{abzar::add_pdf_image_object(input,output,page_index,image_path,image_format,x,y,width,height);});}
int32_t abz_pdf_replace_image(const char* input,const char* output,int32_t page_index,const char* object_name,const char* replacement_path,const char* replacement_format,char** error){if(!input||!output||!object_name||!replacement_path||!replacement_format){set_error(error,"Invalid PDF image-edit argument");return ABZ_ERROR_INVALID_ARGUMENT;}return guard_operation(error,[&]{abzar::replace_pdf_image_object(input,output,page_index,object_name,replacement_path,replacement_format);});}
int32_t abz_pdf_flatten(const char* input,const char* output,char** error){if(!input||!output){set_error(error,"Invalid PDF flatten argument");return ABZ_ERROR_INVALID_ARGUMENT;}return guard_operation(error,[&]{abzar::flatten_pdf(input,output);});}
int32_t abz_pdf_add_bookmark(const char* input,const char* output,int32_t page_index,const char* title,char** error){if(!input||!output||!title){set_error(error,"Invalid PDF bookmark argument");return ABZ_ERROR_INVALID_ARGUMENT;}return guard_operation(error,[&]{abzar::add_pdf_bookmark(input,output,page_index,title);});}
int32_t abz_pdf_add_annotation(const char* input,const char* output,int32_t page_index,const char* text,double x,double y,char** error){if(!input||!output||!text){set_error(error,"Invalid PDF annotation argument");return ABZ_ERROR_INVALID_ARGUMENT;}return guard_operation(error,[&]{abzar::add_pdf_text_annotation(input,output,page_index,text,x,y);});}
int32_t abz_pdf_repair(const char* input,const char* output,char** error){if(!input||!output){set_error(error,"Invalid PDF repair argument");return ABZ_ERROR_INVALID_ARGUMENT;}return guard_operation(error,[&]{abzar::repair_pdf(input,output);});}
int32_t abz_pdf_set_password(const char* input,const char* output,const char* user_password,const char* owner_password,int32_t allow_print,int32_t allow_copy,int32_t allow_modify,int32_t allow_annotate,char** error){if(!input||!output||!user_password||!owner_password){set_error(error,"Invalid PDF encryption argument");return ABZ_ERROR_INVALID_ARGUMENT;}return guard_operation(error,[&]{abzar::protect_pdf(input,output,user_password,owner_password,allow_print!=0,allow_copy!=0,allow_modify!=0,allow_annotate!=0);});}
int32_t abz_pdf_remove_password(const char* input,const char* output,const char* password,char** error){if(!input||!output||!password){set_error(error,"Invalid PDF decryption argument");return ABZ_ERROR_INVALID_ARGUMENT;}return guard_operation(error,[&]{abzar::unprotect_pdf(input,output,password);});}
int32_t abz_process_scan_image(const char* input,const char* output,const char* format,int32_t perspective,int32_t filter,double brightness,double contrast,char** error){if(!input||!output||!format){set_error(error,"Invalid scan argument");return ABZ_ERROR_INVALID_ARGUMENT;}return guard_operation(error,[&]{abzar::process_scan_image(input,output,format,perspective!=0,filter,brightness,contrast);});}
void abz_free(void* memory){std::free(memory);}
}
