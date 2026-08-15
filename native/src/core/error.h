#pragma once
#include <stdexcept>
#include <string>
#include "abzar/abzar_api.h"
namespace abzar {
class Error final : public std::runtime_error {
 public:
  Error(AbzErrorCode code, const std::string& message) : std::runtime_error(message), code_(code) {}
  [[nodiscard]] AbzErrorCode code() const noexcept { return code_; }
 private:
  AbzErrorCode code_;
};
}  // namespace abzar
