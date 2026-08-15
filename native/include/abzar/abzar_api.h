#ifndef ABZAR_ABZAR_API_H_
#define ABZAR_ABZAR_API_H_

#include <stdint.h>

#if defined(_WIN32)
#  if defined(ABZAR_CORE_EXPORTS)
#    define ABZAR_API __declspec(dllexport)
#  else
#    define ABZAR_API __declspec(dllimport)
#  endif
#else
#  define ABZAR_API __attribute__((visibility("default")))
#endif

#ifdef __cplusplus
extern "C" {
#endif

#define ABZAR_ABI_VERSION 1u

typedef enum AbzErrorCode {
  ABZ_OK = 0,
  ABZ_ERROR_INVALID_ARGUMENT = 1,
  ABZ_ERROR_IO = 2,
  ABZ_ERROR_UNSUPPORTED_FORMAT = 3,
  ABZ_ERROR_CORRUPT_INPUT = 4,
  ABZ_ERROR_PASSWORD_REQUIRED = 5,
  ABZ_ERROR_WRONG_PASSWORD = 6,
  ABZ_ERROR_OCR_UNAVAILABLE = 7,
  ABZ_ERROR_CANCELLED = 8,
  ABZ_ERROR_OUT_OF_MEMORY = 9,
  ABZ_ERROR_INTERNAL = 10,
  ABZ_ERROR_VALIDATION = 11
} AbzErrorCode;

typedef enum AbzJobState {
  ABZ_JOB_CREATED = 0,
  ABZ_JOB_RUNNING = 1,
  ABZ_JOB_SUCCEEDED = 2,
  ABZ_JOB_FAILED = 3,
  ABZ_JOB_CANCELLED = 4
} AbzJobState;

typedef struct AbzJob AbzJob;

typedef struct AbzJobReport {
  uint32_t struct_size;
  int32_t error_code;
  int32_t state;
  uint64_t input_bytes;
  uint64_t output_bytes;
  uint64_t duration_ms;
  uint32_t page_count;
  uint32_t warning_count;
} AbzJobReport;

typedef void (*AbzProgressCallback)(void* user_data,
                                    double progress,
                                    const char* stage_utf8);

ABZAR_API uint32_t abz_abi_version(void);
ABZAR_API const char* abz_engine_version(void);
ABZAR_API const char* abz_build_features(void);
ABZAR_API int32_t abz_is_format_supported(const char* extension_utf8,
                                          int32_t for_export);

/* JSON must contain inputPath, outputPath, sourceFormat and targetFormat.
 * Optional keys include dpi, quality, stitchPages and embedImages. */
ABZAR_API AbzJob* abz_job_create(const char* specification_json_utf8);
ABZAR_API int32_t abz_job_run(AbzJob* job,
                              AbzProgressCallback callback,
                              void* user_data);
ABZAR_API void abz_job_cancel(AbzJob* job);
ABZAR_API int32_t abz_job_report(const AbzJob* job, AbzJobReport* report);
ABZAR_API const char* abz_job_error_message(const AbzJob* job);
ABZAR_API const char* abz_job_report_json(const AbzJob* job);
ABZAR_API void abz_job_destroy(AbzJob* job);

/* Convenience synchronous API. Error text is allocated by the engine. */
ABZAR_API int32_t abz_convert_file(const char* input_path_utf8,
                                   const char* output_path_utf8,
                                   const char* source_format_utf8,
                                   const char* target_format_utf8,
                                   const char* options_json_utf8,
                                   char** error_utf8);

/* Document operations use JSON arrays for paths/ranges so the ABI remains
 * append-only while options evolve. Every operation preserves its inputs. */
ABZAR_API int32_t abz_compress_file(const char* input_path_utf8,
                                    const char* output_path_utf8,
                                    const char* format_utf8,
                                    int32_t level,
                                    char** error_utf8);
ABZAR_API int32_t abz_merge_files(const char* input_paths_json_utf8,
                                  const char* output_path_utf8,
                                  const char* source_format_utf8,
                                  const char* target_format_utf8,
                                  char** error_utf8);
ABZAR_API int32_t abz_split_file(const char* input_path_utf8,
                                 const char* output_directory_utf8,
                                 const char* format_utf8,
                                 const char* ranges_json_utf8,
                                 char** outputs_json_utf8,
                                 char** error_utf8);
ABZAR_API int32_t abz_extract_text(const char* input_path_utf8,
                                   const char* source_format_utf8,
                                   char** text_utf8,
                                   char** error_utf8);
ABZAR_API int32_t abz_encrypt_container(const char* input_path_utf8,
                                        const char* output_path_utf8,
                                        const char* password_utf8,
                                        char** error_utf8);
ABZAR_API int32_t abz_decrypt_container(const char* input_path_utf8,
                                        const char* output_path_utf8,
                                        const char* password_utf8,
                                        char** error_utf8);
ABZAR_API int32_t abz_pdf_replace_text(const char* input_path_utf8,
                                       const char* output_path_utf8,
                                       const char* search_utf8,
                                       const char* replacement_utf8,
                                       int32_t page_index,
                                       char** error_utf8);
ABZAR_API int32_t abz_pdf_delete_image(const char* input_path_utf8,
                                       const char* output_path_utf8,
                                       int32_t page_index,
                                       const char* object_name_utf8,
                                       char** error_utf8);
ABZAR_API int32_t abz_pdf_add_image(const char* input_path_utf8,
                                    const char* output_path_utf8,
                                    int32_t page_index,
                                    const char* image_path_utf8,
                                    const char* image_format_utf8,
                                    double x, double y,
                                    double width, double height,
                                    char** error_utf8);
ABZAR_API int32_t abz_pdf_replace_image(const char* input_path_utf8,
                                        const char* output_path_utf8,
                                        int32_t page_index,
                                        const char* object_name_utf8,
                                        const char* replacement_path_utf8,
                                        const char* replacement_format_utf8,
                                        char** error_utf8);
ABZAR_API int32_t abz_pdf_flatten(const char* input_path_utf8,
                                  const char* output_path_utf8,
                                  char** error_utf8);
ABZAR_API int32_t abz_pdf_add_bookmark(const char* input_path_utf8,
                                       const char* output_path_utf8,
                                       int32_t page_index,
                                       const char* title_utf8,
                                       char** error_utf8);
ABZAR_API int32_t abz_pdf_add_annotation(const char* input_path_utf8,
                                         const char* output_path_utf8,
                                         int32_t page_index,
                                         const char* text_utf8,
                                         double x, double y,
                                         char** error_utf8);
ABZAR_API int32_t abz_pdf_repair(const char* input_path_utf8,
                                 const char* output_path_utf8,
                                 char** error_utf8);
ABZAR_API int32_t abz_pdf_set_password(const char* input_path_utf8,
                                       const char* output_path_utf8,
                                       const char* user_password_utf8,
                                       const char* owner_password_utf8,
                                       int32_t allow_print,
                                       int32_t allow_copy,
                                       int32_t allow_modify,
                                       int32_t allow_annotate,
                                       char** error_utf8);
ABZAR_API int32_t abz_pdf_remove_password(const char* input_path_utf8,
                                          const char* output_path_utf8,
                                          const char* password_utf8,
                                          char** error_utf8);
ABZAR_API int32_t abz_process_scan_image(const char* input_path_utf8,
                                         const char* output_path_utf8,
                                         const char* format_utf8,
                                         int32_t perspective,
                                         int32_t filter,
                                         double brightness,
                                         double contrast,
                                         char** error_utf8);
ABZAR_API void abz_free(void* memory);

#ifdef __cplusplus
}  /* extern "C" */
#endif

#endif  /* ABZAR_ABZAR_API_H_ */
