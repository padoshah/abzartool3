#include "core/job.h"

#include <sstream>

#include "core/error.h"
#include "importers/importer.h"
#include "ops/document_ops.h"
#include "render/layout_engine.h"
#include "util/fs.h"
#include "util/string.h"

namespace abzar {
JobSpec parse_job_spec(const std::string& json) {
  JobSpec specification;
  specification.input_path = strings::json_string(json, "inputPath");
  specification.output_path = strings::json_string(json, "outputPath");
  specification.source_format = strings::lower(strings::json_string(json, "sourceFormat"));
  specification.target_format = strings::lower(strings::json_string(json, "targetFormat"));
  specification.options.dpi = strings::json_integer(json, "dpi", 150);
  specification.options.quality = strings::json_integer(json, "quality", 90);
  specification.options.stitch_pages = strings::json_boolean(json, "stitchPages", false);
  specification.options.embed_images = strings::json_boolean(json, "embedImages", true);
  specification.apply_default_style = strings::json_boolean(json, "applyDefaultStyle", false);
  specification.default_style.font_family = strings::json_string(json, "fontFamily");
  if(specification.default_style.font_family.empty()) specification.default_style.font_family="Noto Sans";
  specification.default_style.font_size_points = strings::json_integer(json, "fontSize", 11);
  specification.default_style.font_weight = strings::json_boolean(json, "bold", false) ? 700 : 400;
  specification.default_style.italic = strings::json_boolean(json, "italic", false);
  specification.default_style.underline = strings::json_boolean(json, "underline", false);
  if (specification.input_path.empty() || specification.output_path.empty() ||
      specification.source_format.empty() || specification.target_format.empty()) {
    throw Error(ABZ_ERROR_INVALID_ARGUMENT,
                "Job specification is missing a required field");
  }
  return specification;
}

Job::Job(JobSpec specification) : spec_(std::move(specification)) {
  report_.struct_size = sizeof(report_);
  report_.state = ABZ_JOB_CREATED;
}

void Job::update(double value, const char* stage, AbzProgressCallback callback,
                 void* data) {
  if (cancelled_) throw Error(ABZ_ERROR_CANCELLED, "Conversion cancelled");
  if (callback) callback(data, value, stage);
}

int Job::run(AbzProgressCallback callback, void* data) noexcept {
  const auto start = std::chrono::steady_clock::now();
  try {
    {
      std::lock_guard lock(mutex_);
      report_.state = ABZ_JOB_RUNNING;
      report_.input_bytes = fs::file_size(spec_.input_path);
    }
    const bool raster_source =
        spec_.source_format == "png" || spec_.source_format == "jpg" ||
        spec_.source_format == "jpeg" || spec_.source_format == "webp" ||
        spec_.source_format == "bmp" || spec_.source_format == "gif" ||
        spec_.source_format == "tiff";
    const bool text_target =
        spec_.target_format == "txt" || spec_.target_format == "docx" ||
        spec_.target_format == "xlsx" || spec_.target_format == "pptx" ||
        spec_.target_format == "html";
    update(.05, "import", callback, data);
    auto document = import_document(spec_.input_path, spec_.source_format);
    if(spec_.apply_default_style){for(auto& section:document.sections)for(auto& page:section.pages)for(auto& block:page.blocks){block.style=spec_.default_style;for(auto& run:block.runs)run.style=spec_.default_style;}}
    if (raster_source && text_target) {
      update(.35, "ocr", callback, data);
      ops::apply_ocr(document);
    }
    update(.45, "layout", callback, data);
    paginate(document);
    update(.60, "export", callback, data);
    export_document(document, spec_.output_path, spec_.target_format,
                    spec_.options);
    update(.95, "validate", callback, data);
    const auto output = fs::file_size(spec_.output_path);
    {
      std::lock_guard lock(mutex_);
      report_.state = ABZ_JOB_SUCCEEDED;
      report_.error_code = ABZ_OK;
      report_.output_bytes = output;
      report_.page_count = static_cast<std::uint32_t>(document.page_count());
      report_.warning_count =
          static_cast<std::uint32_t>(document.warnings.size());
    }
    update(1.0, "done", callback, data);
  } catch (const Error& error) {
    std::lock_guard lock(mutex_);
    report_.error_code = error.code();
    report_.state = error.code() == ABZ_ERROR_CANCELLED ? ABZ_JOB_CANCELLED
                                                        : ABZ_JOB_FAILED;
    error_ = error.what();
  } catch (const std::bad_alloc&) {
    std::lock_guard lock(mutex_);
    report_.error_code = ABZ_ERROR_OUT_OF_MEMORY;
    report_.state = ABZ_JOB_FAILED;
    error_ = "Not enough memory";
  } catch (const std::exception& error) {
    std::lock_guard lock(mutex_);
    report_.error_code = ABZ_ERROR_INTERNAL;
    report_.state = ABZ_JOB_FAILED;
    error_ = error.what();
  } catch (...) {
    std::lock_guard lock(mutex_);
    report_.error_code = ABZ_ERROR_INTERNAL;
    report_.state = ABZ_JOB_FAILED;
    error_ = "Unknown native failure";
  }
  const auto elapsed = std::chrono::duration_cast<std::chrono::milliseconds>(
                           std::chrono::steady_clock::now() - start)
                           .count();
  {
    std::lock_guard lock(mutex_);
    report_.duration_ms = static_cast<std::uint64_t>(elapsed);
  }
  return report_.error_code;
}

AbzJobReport Job::report() const {
  std::lock_guard lock(mutex_);
  return report_;
}
std::string Job::error_message() const {
  std::lock_guard lock(mutex_);
  return error_;
}
const char* Job::report_json() {
  std::lock_guard lock(mutex_);
  std::ostringstream output;
  output << "{\"errorCode\":" << report_.error_code
         << ",\"state\":" << report_.state
         << ",\"inputBytes\":" << report_.input_bytes
         << ",\"outputBytes\":" << report_.output_bytes
         << ",\"durationMs\":" << report_.duration_ms
         << ",\"pageCount\":" << report_.page_count
         << ",\"warningCount\":" << report_.warning_count
         << ",\"error\":\"" << strings::json_escape(error_) << "\"}";
  report_json_ = output.str();
  return report_json_.c_str();
}
}  // namespace abzar
