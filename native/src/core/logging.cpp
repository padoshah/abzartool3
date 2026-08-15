#include "core/logging.h"
namespace abzar {
void log_event(std::string_view category, std::string_view message) {
  // Deliberately no default sink: file names, file contents, and passwords are
  // never emitted. Platform hosts may install a metadata-only sink later.
  (void)category; (void)message;
}
}  // namespace abzar
