#pragma once
#include <algorithm>
#include <cstddef>
#include <vector>
namespace abzar {
inline void secure_zero(void* pointer, std::size_t size) {
  volatile unsigned char* bytes = static_cast<volatile unsigned char*>(pointer);
  while (size-- > 0) *bytes++ = 0;
}
class SecureBuffer {
 public:
  explicit SecureBuffer(std::size_t size = 0) : bytes_(size) {}
  ~SecureBuffer() { secure_zero(bytes_.data(), bytes_.size()); }
  SecureBuffer(const SecureBuffer&) = delete;
  SecureBuffer& operator=(const SecureBuffer&) = delete;
  std::vector<unsigned char>& bytes() { return bytes_; }
 private:
  std::vector<unsigned char> bytes_;
};
}  // namespace abzar
