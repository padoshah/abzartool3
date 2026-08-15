#include "ops/file_operations.h"

#include <algorithm>
#include <string>
#include <utility>
#include <vector>

#include "core/error.h"
#include "core/memory.h"

#ifdef ABZAR_HAS_QPDF
#include <qpdf/qpdfjob-c.h>
#endif

namespace abzar {
namespace {
struct WipeString {
  std::string& value;
  ~WipeString() { secure_zero(value.data(), value.size()); }
};
#ifdef ABZAR_HAS_QPDF
void run_qpdf(std::vector<std::string>& arguments) {
  std::vector<const char*> argv;
  argv.reserve(arguments.size() + 1);
  for (const auto& argument : arguments) argv.push_back(argument.c_str());
  argv.push_back(nullptr);
  auto job = qpdfjob_init();
  if (!job) throw Error(ABZ_ERROR_OUT_OF_MEMORY, "Unable to create PDF security job");
  int result = qpdfjob_initialize_from_argv(job, argv.data());
  if (result == 0) result = qpdfjob_run(job);
  qpdfjob_cleanup(&job);
  if (result != 0 && result != 3) {
    throw Error(ABZ_ERROR_WRONG_PASSWORD,
                "PDF password or encryption operation was rejected");
  }
}
#endif
}  // namespace

void optimize_pdf(const std::filesystem::path& input,
                  const std::filesystem::path& output, int level) {
#ifndef ABZAR_HAS_QPDF
  (void)input; (void)output; (void)level;
  throw Error(ABZ_ERROR_UNSUPPORTED_FORMAT,
              "QPDF optimization support is not compiled into this build");
#else
  std::vector<std::string> arguments={"qpdf","--object-streams=generate","--compress-streams=y","--recompress-flate","--compression-level="+std::to_string(std::clamp(level,1,9)),input.string(),output.string()};
  run_qpdf(arguments);
#endif
}

void extract_pdf_pages(const std::filesystem::path& input,
                       const std::filesystem::path& output,
                       const std::string& range) {
#ifndef ABZAR_HAS_QPDF
  (void)input; (void)output; (void)range;
  throw Error(ABZ_ERROR_UNSUPPORTED_FORMAT,
              "QPDF page extraction support is not compiled into this build");
#else
  std::vector<std::string> arguments={"qpdf",input.string(),"--pages",".",range,"--",output.string()};
  run_qpdf(arguments);
#endif
}

void merge_pdf_files(const std::vector<std::filesystem::path>& inputs,
                     const std::filesystem::path& output) {
#ifndef ABZAR_HAS_QPDF
  (void)inputs; (void)output;
  throw Error(ABZ_ERROR_UNSUPPORTED_FORMAT,
              "QPDF page merge support is not compiled into this build");
#else
  if(inputs.size()<2)throw Error(ABZ_ERROR_INVALID_ARGUMENT,"At least two PDFs are required");
  std::vector<std::string> arguments={"qpdf","--empty","--pages"};
  for(const auto& input:inputs){arguments.push_back(input.string());arguments.push_back("1-z");}
  arguments.push_back("--");arguments.push_back(output.string());run_qpdf(arguments);
#endif
}

void flatten_pdf(const std::filesystem::path& input,
                 const std::filesystem::path& output) {
#ifndef ABZAR_HAS_QPDF
  (void)input; (void)output;
  throw Error(ABZ_ERROR_UNSUPPORTED_FORMAT,
              "QPDF form flattening is not compiled into this build");
#else
  std::vector<std::string> arguments={"qpdf","--generate-appearances","--flatten-annotations=all",input.string(),output.string()};
  run_qpdf(arguments);
#endif
}

void repair_pdf(const std::filesystem::path& input,
                const std::filesystem::path& output) {
#ifndef ABZAR_HAS_QPDF
  (void)input; (void)output;
  throw Error(ABZ_ERROR_UNSUPPORTED_FORMAT,
              "QPDF repair support is not compiled into this build");
#else
  std::vector<std::string> arguments = {"qpdf", input.string(), output.string()};
  run_qpdf(arguments);
#endif
}

void protect_pdf(const std::filesystem::path& input,
                 const std::filesystem::path& output,
                 std::string user_password, std::string owner_password,
                 bool allow_print, bool allow_copy, bool allow_modify,
                 bool allow_annotate) {
  WipeString wipe_user{user_password};
  WipeString wipe_owner{owner_password};
  if (user_password.empty() || owner_password.empty()) {
    throw Error(ABZ_ERROR_INVALID_ARGUMENT,
                "PDF user and owner passwords are required");
  }
#ifndef ABZAR_HAS_QPDF
  (void)input; (void)output; (void)allow_print; (void)allow_copy;
  (void)allow_modify; (void)allow_annotate;
  throw Error(ABZ_ERROR_UNSUPPORTED_FORMAT,
              "QPDF AES-256 security support is not compiled into this build");
#else
  std::vector<std::string> arguments = {
      "qpdf", "--encrypt", user_password, owner_password, "256",
      allow_print ? "--print=full" : "--print=none",
      allow_copy ? "--extract=y" : "--extract=n",
      allow_modify ? "--modify=all"
                   : allow_annotate ? "--modify=annotate" : "--modify=none",
      "--", input.string(), output.string()};
  run_qpdf(arguments);
  secure_zero(arguments[2].data(), arguments[2].size());
  secure_zero(arguments[3].data(), arguments[3].size());
#endif
}

void unprotect_pdf(const std::filesystem::path& input,
                   const std::filesystem::path& output,
                   std::string password) {
  WipeString wipe{password};
  if (password.empty()) throw Error(ABZ_ERROR_INVALID_ARGUMENT, "PDF password is required");
#ifndef ABZAR_HAS_QPDF
  (void)input; (void)output;
  throw Error(ABZ_ERROR_UNSUPPORTED_FORMAT,
              "QPDF AES-256 security support is not compiled into this build");
#else
  std::vector<std::string> arguments = {
      "qpdf", "--password=" + password, "--decrypt", input.string(),
      output.string()};
  run_qpdf(arguments);
  secure_zero(arguments[1].data(), arguments[1].size());
#endif
}
}  // namespace abzar
