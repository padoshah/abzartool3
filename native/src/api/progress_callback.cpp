#include <atomic>
namespace abzar {
class CancellationToken final {
 public:
  void cancel() noexcept { cancelled_.store(true); }
  [[nodiscard]] bool cancelled() const noexcept { return cancelled_.load(); }
 private:
  std::atomic_bool cancelled_{false};
};
}  // namespace abzar
