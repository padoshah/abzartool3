#include "ops/file_operations.h"

#include <array>
#include <cstdint>
#include <cstring>
#include <string_view>
#include <vector>

#include "core/error.h"
#include "core/memory.h"
#include "util/fs.h"

#ifdef ABZAR_HAS_MBEDTLS
#include <mbedtls/ctr_drbg.h>
#include <mbedtls/entropy.h>
#include <mbedtls/gcm.h>
#include <mbedtls/pkcs5.h>
#endif

namespace abzar {
namespace {
struct PasswordWiper{std::string& value;~PasswordWiper(){secure_zero(value.data(),value.size());}};
#ifdef ABZAR_HAS_MBEDTLS
constexpr std::uint32_t kIterations = 210000;
constexpr std::size_t kHeaderSize = 4 + 1 + 4 + 16 + 12 + 8;
constexpr std::size_t kTagSize = 16;

void append32(std::vector<std::uint8_t>& output, std::uint32_t value) {
  for (int shift = 0; shift < 4; ++shift) output.push_back(static_cast<std::uint8_t>(value >> (shift * 8)));
}
void append64(std::vector<std::uint8_t>& output, std::uint64_t value) {
  for (int shift = 0; shift < 8; ++shift) output.push_back(static_cast<std::uint8_t>(value >> (shift * 8)));
}
std::uint32_t read32(const std::vector<std::uint8_t>& input, std::size_t offset) {
  std::uint32_t value = 0;
  for (int shift = 0; shift < 4; ++shift) value |= std::uint32_t(input[offset + static_cast<std::size_t>(shift)]) << (shift * 8);
  return value;
}
std::uint64_t read64(const std::vector<std::uint8_t>& input, std::size_t offset) {
  std::uint64_t value = 0;
  for (int shift = 0; shift < 8; ++shift) value |= std::uint64_t(input[offset + static_cast<std::size_t>(shift)]) << (shift * 8);
  return value;
}

std::array<std::uint8_t, 32> derive_key(const std::string& password,
                                        const std::uint8_t* salt,
                                        std::size_t salt_size,
                                        std::uint32_t iterations) {
  std::array<std::uint8_t, 32> key{};
  const auto result = mbedtls_pkcs5_pbkdf2_hmac_ext(
      MBEDTLS_MD_SHA256,
      reinterpret_cast<const unsigned char*>(password.data()), password.size(),
      salt, salt_size, iterations, static_cast<std::uint32_t>(key.size()), key.data());
  if (result != 0) throw Error(ABZ_ERROR_INTERNAL, "Password key derivation failed");
  return key;
}
void random_bytes(std::uint8_t* output, std::size_t size) {
  mbedtls_entropy_context entropy;
  mbedtls_ctr_drbg_context random;
  mbedtls_entropy_init(&entropy);
  mbedtls_ctr_drbg_init(&random);
  constexpr unsigned char personalization[] = "AbzarFile ABZE1";
  int result = mbedtls_ctr_drbg_seed(&random, mbedtls_entropy_func, &entropy,
                                     personalization, sizeof(personalization) - 1);
  if (result == 0) result = mbedtls_ctr_drbg_random(&random, output, size);
  mbedtls_ctr_drbg_free(&random);
  mbedtls_entropy_free(&entropy);
  if (result != 0) throw Error(ABZ_ERROR_INTERNAL, "Secure random generation failed");
}
#endif
}  // namespace

namespace ops {
bool secure_password_equal(std::string_view a, std::string_view b) {
  const auto length = a.size() > b.size() ? a.size() : b.size();
  std::uint8_t difference = static_cast<std::uint8_t>(a.size() ^ b.size());
  for (std::size_t index = 0; index < length; ++index) {
    const auto left = index < a.size() ? static_cast<std::uint8_t>(a[index]) : 0;
    const auto right = index < b.size() ? static_cast<std::uint8_t>(b[index]) : 0;
    difference = static_cast<std::uint8_t>(difference | static_cast<std::uint8_t>(left ^ right));
  }
  return difference == 0;
}
}  // namespace ops

void encrypt_container(const std::filesystem::path& input,
                       const std::filesystem::path& output,
                       std::string password) {
  if (password.empty()) throw Error(ABZ_ERROR_INVALID_ARGUMENT, "Password must not be empty");
  PasswordWiper wipe{password};
#ifndef ABZAR_HAS_MBEDTLS
  (void)input; (void)output;
  throw Error(ABZ_ERROR_UNSUPPORTED_FORMAT, "AES support is not compiled into this build");
#else
  const auto plaintext = fs::read_bytes(input);
  std::array<std::uint8_t, 16> salt{};
  std::array<std::uint8_t, 12> nonce{};
  random_bytes(salt.data(), salt.size());
  random_bytes(nonce.data(), nonce.size());
  auto key = derive_key(password, salt.data(), salt.size(), kIterations);

  std::vector<std::uint8_t> header = {'A', 'B', 'Z', 'E', 1};
  append32(header, kIterations);
  header.insert(header.end(), salt.begin(), salt.end());
  header.insert(header.end(), nonce.begin(), nonce.end());
  append64(header, plaintext.size());
  std::array<std::uint8_t, kTagSize> tag{};
  std::vector<std::uint8_t> ciphertext(plaintext.size());
  mbedtls_gcm_context context;
  mbedtls_gcm_init(&context);
  int result = mbedtls_gcm_setkey(&context, MBEDTLS_CIPHER_ID_AES, key.data(), 256);
  if (result == 0) {
    result = mbedtls_gcm_crypt_and_tag(&context, MBEDTLS_GCM_ENCRYPT,
        plaintext.size(), nonce.data(), nonce.size(), header.data(), header.size(),
        plaintext.data(), ciphertext.data(), tag.size(), tag.data());
  }
  mbedtls_gcm_free(&context);
  secure_zero(key.data(), key.size());
  if (result != 0) throw Error(ABZ_ERROR_INTERNAL, "AES-256-GCM encryption failed");
  header.insert(header.end(), tag.begin(), tag.end());
  header.insert(header.end(), ciphertext.begin(), ciphertext.end());
  fs::write_bytes_atomic(output, header);
#endif
}

void decrypt_container(const std::filesystem::path& input,
                       const std::filesystem::path& output,
                       std::string password) {
  if (password.empty()) throw Error(ABZ_ERROR_INVALID_ARGUMENT, "Password must not be empty");
  PasswordWiper wipe{password};
#ifndef ABZAR_HAS_MBEDTLS
  (void)input; (void)output; (void)password;
  throw Error(ABZ_ERROR_UNSUPPORTED_FORMAT, "AES support is not compiled into this build");
#else
  const auto container = fs::read_bytes(input);
  if (container.size() < kHeaderSize + kTagSize ||
      std::memcmp(container.data(), "ABZE", 4) != 0 || container[4] != 1) {
    throw Error(ABZ_ERROR_CORRUPT_INPUT, "Invalid ABZE encrypted container");
  }
  const auto iterations = read32(container, 5);
  const auto* salt = container.data() + 9;
  const auto* nonce = salt + 16;
  const auto original_size = read64(container, 37);
  const auto* tag = container.data() + kHeaderSize;
  const auto* ciphertext = tag + kTagSize;
  const auto ciphertext_size = container.size() - kHeaderSize - kTagSize;
  if (original_size != ciphertext_size) throw Error(ABZ_ERROR_CORRUPT_INPUT, "Encrypted container size is invalid");
  auto key = derive_key(password, salt, 16, iterations);
  std::vector<std::uint8_t> plaintext(ciphertext_size);
  mbedtls_gcm_context context;
  mbedtls_gcm_init(&context);
  int result = mbedtls_gcm_setkey(&context, MBEDTLS_CIPHER_ID_AES, key.data(), 256);
  if (result == 0) {
    result = mbedtls_gcm_auth_decrypt(&context, ciphertext_size, nonce, 12,
        container.data(), kHeaderSize, tag, kTagSize, ciphertext, plaintext.data());
  }
  mbedtls_gcm_free(&context);
  secure_zero(key.data(), key.size());
  if (result != 0) {
    secure_zero(plaintext.data(), plaintext.size());
    throw Error(ABZ_ERROR_WRONG_PASSWORD, "Wrong password or modified encrypted container");
  }
  fs::write_bytes_atomic(output, plaintext);
  secure_zero(plaintext.data(), plaintext.size());
#endif
}
}  // namespace abzar
