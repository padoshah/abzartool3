#pragma once

#include <filesystem>
#include <string>
#include <vector>

namespace abzar {
void compress_file(const std::filesystem::path& input,
                   const std::filesystem::path& output,
                   const std::string& format,
                   int level);
void merge_documents(const std::vector<std::filesystem::path>& inputs,
                     const std::filesystem::path& output,
                     const std::string& source_format,
                     const std::string& target_format);
std::vector<std::filesystem::path> split_document(
    const std::filesystem::path& input,
    const std::filesystem::path& output_directory,
    const std::string& format,
    const std::vector<std::string>& ranges);
std::string extract_document_text(const std::filesystem::path& input,
                                  const std::string& format);
void encrypt_container(const std::filesystem::path& input,
                       const std::filesystem::path& output,
                       std::string password);
void decrypt_container(const std::filesystem::path& input,
                       const std::filesystem::path& output,
                       std::string password);
void protect_pdf(const std::filesystem::path& input,
                 const std::filesystem::path& output,
                 std::string user_password, std::string owner_password,
                 bool allow_print, bool allow_copy, bool allow_modify,
                 bool allow_annotate);
std::size_t replace_pdf_text_objects(const std::filesystem::path& input,
                                     const std::filesystem::path& output,
                                     const std::string& search,
                                     const std::string& replacement,
                                     int page_index);
void delete_pdf_image_object(const std::filesystem::path& input,
                             const std::filesystem::path& output,
                             int page_index,
                             const std::string& object_name);
void add_pdf_image_object(const std::filesystem::path& input,
                          const std::filesystem::path& output,
                          int page_index,
                          const std::filesystem::path& image_path,
                          const std::string& image_format,
                          double x, double y, double width, double height);
void replace_pdf_image_object(const std::filesystem::path& input,
                              const std::filesystem::path& output,
                              int page_index, const std::string& object_name,
                              const std::filesystem::path& replacement_path,
                              const std::string& replacement_format);
void optimize_pdf(const std::filesystem::path& input,
                  const std::filesystem::path& output, int level);
void extract_pdf_pages(const std::filesystem::path& input,
                       const std::filesystem::path& output,
                       const std::string& range);
void merge_pdf_files(const std::vector<std::filesystem::path>& inputs,
                     const std::filesystem::path& output);
void repair_pdf(const std::filesystem::path& input,
                const std::filesystem::path& output);
void flatten_pdf(const std::filesystem::path& input,
                 const std::filesystem::path& output);
void add_pdf_bookmark(const std::filesystem::path& input,
                      const std::filesystem::path& output,
                      int page_index, const std::string& title);
void add_pdf_text_annotation(const std::filesystem::path& input,
                             const std::filesystem::path& output,
                             int page_index, const std::string& text,
                             double x, double y);
void unprotect_pdf(const std::filesystem::path& input,
                   const std::filesystem::path& output,
                   std::string password);
void process_scan_image(const std::filesystem::path& input,
                        const std::filesystem::path& output,
                        const std::string& format, bool perspective,
                        int filter, double brightness, double contrast);
}  // namespace abzar
