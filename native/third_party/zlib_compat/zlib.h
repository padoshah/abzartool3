/* Minimal compile-time declarations for zlib's stable C ABI.
 * Used only in constrained development sandboxes that provide libz without
 * headers. Production CMake uses upstream zlib and its full zlib.h.
 * zlib itself is Copyright (C) 1995-2024 Jean-loup Gailly and Mark Adler,
 * under the zlib license; see native/third_party/LICENSES/ZLIB.txt. */
#ifndef ABZAR_ZLIB_COMPAT_H
#define ABZAR_ZLIB_COMPAT_H
#include <stddef.h>
#ifdef __cplusplus
extern "C" {
#endif
typedef unsigned char Byte;
typedef unsigned char Bytef;
typedef unsigned int uInt;
typedef unsigned long uLong;
typedef unsigned long uLongf;
typedef void* voidpf;
typedef void* (*alloc_func)(voidpf, uInt, uInt);
typedef void (*free_func)(voidpf, voidpf);
struct internal_state;
typedef struct z_stream_s {
 Bytef* next_in; uInt avail_in; uLong total_in;
 Bytef* next_out; uInt avail_out; uLong total_out;
 char* msg; struct internal_state* state;
 alloc_func zalloc; free_func zfree; voidpf opaque;
 int data_type; uLong adler; uLong reserved;
} z_stream;
typedef z_stream* z_streamp;
#define Z_NO_FLUSH 0
#define Z_FINISH 4
#define Z_OK 0
#define Z_STREAM_END 1
#define Z_BUF_ERROR (-5)
#define Z_DEFLATED 8
#define Z_DEFAULT_STRATEGY 0
#define Z_DEFAULT_COMPRESSION (-1)
#define MAX_WBITS 15
#define ZLIB_VERSION "1.2.13"
const char* zlibVersion(void);
int inflateInit2_(z_streamp, int, const char*, int);
int inflate(z_streamp, int);
int inflateEnd(z_streamp);
int deflateInit2_(z_streamp, int, int, int, int, int, const char*, int);
int deflate(z_streamp, int);
int deflateEnd(z_streamp);
int compress2(Bytef*, uLongf*, const Bytef*, uLong, int);
int uncompress(Bytef*, uLongf*, const Bytef*, uLong);
uLong compressBound(uLong);
uLong crc32(uLong, const Bytef*, uInt);
#define inflateInit2(strm, bits) inflateInit2_((strm),(bits),zlibVersion(),(int)sizeof(z_stream))
#define deflateInit2(strm,level,method,bits,mem,strategy) deflateInit2_((strm),(level),(method),(bits),(mem),(strategy),zlibVersion(),(int)sizeof(z_stream))
#ifdef __cplusplus
}
#endif
#endif
