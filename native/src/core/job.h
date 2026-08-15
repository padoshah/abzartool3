#pragma once
#include <atomic>
#include <chrono>
#include <cstdint>
#include <filesystem>
#include <mutex>
#include <string>
#include "abzar/abzar_api.h"
#include "exporters/exporter.h"
namespace abzar {
struct JobSpec { std::filesystem::path input_path; std::filesystem::path output_path; std::string source_format; std::string target_format; ExportOptions options{}; Style default_style{}; bool apply_default_style{false}; };
class Job final {
 public:
  explicit Job(JobSpec specification);
  int run(AbzProgressCallback callback, void* user_data) noexcept;
  void cancel() noexcept { cancelled_.store(true); }
  [[nodiscard]] AbzJobReport report() const;
  [[nodiscard]] std::string error_message() const;
  [[nodiscard]] const char* report_json();
 private:
  void update(double value,const char* stage,AbzProgressCallback callback,void* user_data);
  JobSpec spec_; std::atomic_bool cancelled_{false}; mutable std::mutex mutex_; AbzJobReport report_{}; std::string error_; std::string report_json_;
};
JobSpec parse_job_spec(const std::string& json);
}  // namespace abzar
