cmake_minimum_required(VERSION 3.24) # OVERRIDE_FIND_PACKAGE (used below for zlib) needs >=3.24
project(abzar_core VERSION 1.0.0 LANGUAGES C CXX)

option(ABZAR_BUILD_TESTS "Build native structural tests" ON)
option(ABZAR_ENABLE_OCR "Build Tesseract/Leptonica OCR module" OFF)
option(ABZAR_ENABLE_CRYPTO "Build AES-256 authenticated container support" ON)
option(ABZAR_ENABLE_WEBP "Build WebP decode/encode support" ON)
option(ABZAR_ENABLE_TIFF "Build TIFF decode support" ON)
option(ABZAR_ENABLE_OPENCV "Build scanner edge detection and perspective correction" ON)
option(ABZAR_ENABLE_TEXT_SHAPING "Build FreeType and HarfBuzz shaping/subsetting" ON)
option(ABZAR_USE_SYSTEM_ZLIB "Prefer a system zlib" ON)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)
set(CMAKE_POSITION_INDEPENDENT_CODE ON)

if(ABZAR_USE_SYSTEM_ZLIB)
  find_package(ZLIB QUIET)
endif()
if(NOT ZLIB_FOUND)
  include(FetchContent)
  set(ZLIB_BUILD_EXAMPLES OFF CACHE BOOL "" FORCE)
  # OVERRIDE_FIND_PACKAGE (CMake >=3.24) makes every later find_package(ZLIB)
  # call anywhere in this build -- including inside nested FetchContent
  # subbuilds like OpenCV's -- resolve to this fetched zlib instead of doing
  # its own search. Without this, OpenCV's own find_package(ZLIB) also fails
  # (no system zlib on this runner either) and it falls through to its own
  # bundled 3rdparty/zlib, which unconditionally add_library(zlib ...)s and
  # collides with the target we create below (confirmed via real CI: "add_library
  # cannot create target 'zlib' because another target with the same name
  # already exists"). With the override, OpenCV's own detection succeeds and
  # it never reaches that vendoring path, so there's only ever one zlib.
  FetchContent_Declare(zlib
    GIT_REPOSITORY https://github.com/madler/zlib.git
    GIT_TAG v1.3.1
    GIT_SHALLOW TRUE
    OVERRIDE_FIND_PACKAGE)
  FetchContent_MakeAvailable(zlib)
  if(TARGET zlibstatic)
    add_library(ZLIB::ZLIB ALIAS zlibstatic)
  elseif(TARGET zlib)
    add_library(ZLIB::ZLIB ALIAS zlib)
  endif()
endif()

if(ABZAR_ENABLE_CRYPTO)
  include(FetchContent)
  set(ENABLE_PROGRAMS OFF CACHE BOOL "" FORCE)
  set(ENABLE_TESTING OFF CACHE BOOL "" FORCE)
  set(MBEDTLS_FATAL_WARNINGS OFF CACHE BOOL "" FORCE)
  FetchContent_Declare(mbedtls
    GIT_REPOSITORY https://github.com/Mbed-TLS/mbedtls.git
    GIT_TAG mbedtls-3.6.2
    GIT_SHALLOW TRUE)
  FetchContent_MakeAvailable(mbedtls)
endif()

if(ABZAR_ENABLE_TEXT_SHAPING)
  find_package(Freetype QUIET)
  if(NOT Freetype_FOUND)
    include(FetchContent)
    set(FT_DISABLE_BROTLI ON CACHE BOOL "" FORCE)
    set(FT_DISABLE_BZIP2 ON CACHE BOOL "" FORCE)
    set(FT_DISABLE_HARFBUZZ ON CACHE BOOL "" FORCE)
    set(FT_DISABLE_PNG ON CACHE BOOL "" FORCE)
    set(FT_DISABLE_ZLIB OFF CACHE BOOL "" FORCE)
    FetchContent_Declare(freetype_source
      GIT_REPOSITORY https://github.com/freetype/freetype.git
      GIT_TAG VER-2-13-3
      GIT_SHALLOW TRUE)
    FetchContent_MakeAvailable(freetype_source)
  endif()
  find_package(harfbuzz CONFIG QUIET)
  if(harfbuzz_FOUND AND NOT TARGET harfbuzz::subset)
    find_library(HARFBUZZ_SUBSET_LIBRARY NAMES harfbuzz-subset)
    if(HARFBUZZ_SUBSET_LIBRARY)
      add_library(abzar_harfbuzz_subset UNKNOWN IMPORTED)
      set_target_properties(abzar_harfbuzz_subset PROPERTIES IMPORTED_LOCATION "${HARFBUZZ_SUBSET_LIBRARY}")
    endif()
  endif()
  if(NOT harfbuzz_FOUND AND NOT TARGET harfbuzz)
    include(FetchContent)
    set(HB_BUILD_UTILS OFF CACHE BOOL "" FORCE)
    set(HB_BUILD_TESTS OFF CACHE BOOL "" FORCE)
    set(HB_BUILD_SUBSET ON CACHE BOOL "" FORCE)
    set(HB_HAVE_FREETYPE ON CACHE BOOL "" FORCE)
    FetchContent_Declare(harfbuzz_source
      GIT_REPOSITORY https://github.com/harfbuzz/harfbuzz.git
      GIT_TAG 10.2.0
      GIT_SHALLOW TRUE)
    FetchContent_MakeAvailable(harfbuzz_source)
  endif()
endif()

if(ABZAR_ENABLE_OPENCV)
  find_package(OpenCV QUIET COMPONENTS core imgproc)
  if(NOT OpenCV_FOUND)
    include(FetchContent)
    set(BUILD_LIST core,imgproc CACHE STRING "" FORCE)
    set(BUILD_TESTS OFF CACHE BOOL "" FORCE)
    set(BUILD_PERF_TESTS OFF CACHE BOOL "" FORCE)
    set(BUILD_EXAMPLES OFF CACHE BOOL "" FORCE)
    set(BUILD_opencv_apps OFF CACHE BOOL "" FORCE)
    set(BUILD_JAVA OFF CACHE BOOL "" FORCE)
    set(BUILD_ANDROID_PROJECTS OFF CACHE BOOL "" FORCE)
    set(WITH_FFMPEG OFF CACHE BOOL "" FORCE)
    set(WITH_GSTREAMER OFF CACHE BOOL "" FORCE)
    set(WITH_IPP OFF CACHE BOOL "" FORCE)
    set(WITH_OPENCL OFF CACHE BOOL "" FORCE)
    # OpenCV's 3rdparty deps (zlib included) are controlled by these BUILD_*
    # options, which default to "always vendor our own copy" regardless of
    # what's externally available -- OVERRIDE_FIND_PACKAGE on our own zlib
    # FetchContent (above) has no effect here, since OpenCV's zlib detection
    # doesn't go through a plain find_package(ZLIB) call at all. Confirmed via
    # real CI: without this, OpenCV's bundled 3rdparty/zlib/CMakeLists.txt
    # unconditionally add_library(zlib ...)s and collides with the zlib
    # target we already created above.
    set(BUILD_ZLIB OFF CACHE BOOL "" FORCE)
    FetchContent_Declare(opencv
      GIT_REPOSITORY https://github.com/opencv/opencv.git
      GIT_TAG 4.11.0
      GIT_SHALLOW TRUE)
    FetchContent_MakeAvailable(opencv)
    # FetchContent does not always include OpenCVGenHeaders.cmake when OpenCV
    # is embedded. Generate the same public module header explicitly.
    set(OPENCV_CONFIG_FILE_INCLUDE_DIR "${opencv_BINARY_DIR}")
    include("${opencv_SOURCE_DIR}/cmake/OpenCVGenHeaders.cmake")
    set(OpenCV_FOUND TRUE)
    set(OpenCV_LIBS opencv_core opencv_imgproc)
    set(OpenCV_INCLUDE_DIRS "${opencv_SOURCE_DIR}/modules/core/include;${opencv_SOURCE_DIR}/modules/imgproc/include;${opencv_BINARY_DIR}")
  endif()
endif()
find_package(PDFium CONFIG QUIET)
if(NOT PDFium_FOUND)
  set(PDFIUM_ARCHIVE "")
  if(ANDROID)
    if(ANDROID_ABI STREQUAL "armeabi-v7a")
      set(PDFIUM_ARCHIVE "pdfium-android-arm.tgz")
    elseif(ANDROID_ABI STREQUAL "arm64-v8a")
      set(PDFIUM_ARCHIVE "pdfium-android-arm64.tgz")
    elseif(ANDROID_ABI STREQUAL "x86_64")
      set(PDFIUM_ARCHIVE "pdfium-android-x64.tgz")
    endif()
  elseif(WIN32 AND CMAKE_SIZEOF_VOID_P EQUAL 8)
    set(PDFIUM_ARCHIVE "pdfium-win-x64.tgz")
  elseif(UNIX AND CMAKE_SYSTEM_PROCESSOR MATCHES "x86_64|AMD64")
    set(PDFIUM_ARCHIVE "pdfium-linux-x64.tgz")
  endif()
  if(PDFIUM_ARCHIVE)
    include(FetchContent)
    FetchContent_Declare(pdfium_binary
      URL "https://github.com/bblanchon/pdfium-binaries/releases/download/chromium/7999/${PDFIUM_ARCHIVE}")
    FetchContent_GetProperties(pdfium_binary)
    if(NOT pdfium_binary_POPULATED)
      FetchContent_Populate(pdfium_binary)
    endif()
    find_package(PDFium CONFIG REQUIRED PATHS "${pdfium_binary_SOURCE_DIR}" NO_DEFAULT_PATH)
  endif()
endif()
find_package(qpdf CONFIG QUIET)
if(NOT qpdf_FOUND)
  find_package(PkgConfig QUIET)
  if(PkgConfig_FOUND)
    pkg_check_modules(QPDF IMPORTED_TARGET libqpdf)
  endif()
endif()
if(NOT TARGET qpdf::libqpdf AND NOT TARGET PkgConfig::QPDF)
  include(FetchContent)
  set(BUILD_DOC OFF CACHE BOOL "" FORCE)
  set(BUILD_SHARED_LIBS OFF CACHE BOOL "" FORCE)
  set(BUILD_STATIC_LIBS ON CACHE BOOL "" FORCE)
  # qpdf otherwise disables all providers when its dependent options are
  # evaluated inside FetchContent. Explicitly enable CI mode and native
  # fallback so Windows builds remain portable when OpenSSL is unavailable;
  # Linux can still select system OpenSSL when it is discoverable.
  set(CI_MODE ON CACHE BOOL "" FORCE)
  set(REQUIRE_CRYPTO_NATIVE ON CACHE BOOL "" FORCE)
  set(ALLOW_CRYPTO_NATIVE ON CACHE BOOL "" FORCE)
  set(USE_IMPLICIT_CRYPTO ON CACHE BOOL "" FORCE)
  FetchContent_Declare(qpdf_source
    GIT_REPOSITORY https://github.com/qpdf/qpdf.git
    GIT_TAG v12.2.0
    GIT_SHALLOW TRUE)
  FetchContent_MakeAvailable(qpdf_source)
  if(WIN32)
    # qpdf 12.2.0 passes a narrow string to GetEnvironmentVariableW when
    # the Windows desktop toolchain defines UNICODE. qpdf's documented
    # compile guard keeps this optional lookup portable on MSVC. The source
    # is compiled by libqpdf_object, so define it on that target as well as
    # the final library target when present.
    if(TARGET libqpdf_object)
      target_compile_definitions(libqpdf_object PRIVATE NO_GET_ENVIRONMENT=1 AVOID_WINDOWS_HANDLE=1)
    endif()
    if(TARGET libqpdf)
      target_compile_definitions(libqpdf PRIVATE NO_GET_ENVIRONMENT=1 AVOID_WINDOWS_HANDLE=1)
    endif()
  endif()
endif()

if(ABZAR_ENABLE_OCR)
  find_package(Tesseract CONFIG QUIET)
  if(NOT Tesseract_FOUND)
    find_package(PkgConfig QUIET)
    if(PkgConfig_FOUND)
      pkg_check_modules(TESSERACT IMPORTED_TARGET tesseract)
    endif()
  endif()
endif()

if(ABZAR_ENABLE_WEBP)
  include(FetchContent)
  set(WEBP_BUILD_ANIM_UTILS OFF CACHE BOOL "" FORCE)
  set(WEBP_BUILD_CWEBP OFF CACHE BOOL "" FORCE)
  set(WEBP_BUILD_DWEBP OFF CACHE BOOL "" FORCE)
  set(WEBP_BUILD_EXTRAS OFF CACHE BOOL "" FORCE)
  set(WEBP_BUILD_GIF2WEBP OFF CACHE BOOL "" FORCE)
  set(WEBP_BUILD_IMG2WEBP OFF CACHE BOOL "" FORCE)
  set(WEBP_BUILD_VWEBP OFF CACHE BOOL "" FORCE)
  set(WEBP_BUILD_WEBPINFO OFF CACHE BOOL "" FORCE)
  FetchContent_Declare(libwebp
    GIT_REPOSITORY https://github.com/webmproject/libwebp.git
    GIT_TAG v1.5.0
    GIT_SHALLOW TRUE)
  FetchContent_MakeAvailable(libwebp)
endif()

if(ABZAR_ENABLE_TIFF)
  include(FetchContent)
  set(tiff-tools OFF CACHE BOOL "" FORCE)
  set(tiff-tests OFF CACHE BOOL "" FORCE)
  set(tiff-contrib OFF CACHE BOOL "" FORCE)
  set(tiff-docs OFF CACHE BOOL "" FORCE)
  FetchContent_Declare(libtiff
    GIT_REPOSITORY https://github.com/libsdl-org/libtiff.git
    GIT_TAG v4.7.0
    GIT_SHALLOW TRUE)
  FetchContent_MakeAvailable(libtiff)
endif()

set(ABZAR_SOURCES
  src/api/abzar_api.cpp
  src/api/progress_callback.cpp
  src/core/doc_model.cpp
  src/core/error.cpp
  src/core/job.cpp
  src/core/logging.cpp
  src/core/memory.cpp
  src/core/page.cpp
  src/core/style.cpp
  src/importers/importer.cpp
  src/importers/text_importer.cpp
  src/importers/html_importer.cpp
  src/importers/image_importer.cpp
  src/importers/ooxml_importer.cpp
  src/importers/pdf_importer.cpp
  src/importers/legacy_importer.cpp
  src/exporters/exporter.cpp
  src/exporters/text_exporter.cpp
  src/exporters/image_exporter.cpp
  src/exporters/ooxml_exporter.cpp
  src/exporters/pdf_exporter.cpp
  src/render/layout_engine.cpp
  src/render/rasterizer.cpp
  src/render/canvas.cpp
  src/render/text_shaper.cpp
  src/render/font_manager.cpp
  src/render/font_subsetter.cpp
  src/ops/convert.cpp
  src/ops/compress.cpp
  src/ops/merge.cpp
  src/ops/split.cpp
  src/ops/pdf_pages.cpp
  src/ops/pdf_images.cpp
  src/ops/pdf_text_edit.cpp
  src/ops/watermark.cpp
  src/ops/encrypt.cpp
  src/ops/pdf_security.cpp
  src/ops/pdf_annotations.cpp
  src/ops/annotate.cpp
  src/ops/esign.cpp
  src/ops/scan.cpp
  src/ops/ocr.cpp
  src/ooxml/opc_package.cpp
  src/ooxml/content_types.cpp
  src/ooxml/relationships.cpp
  src/ooxml/xml_utils.cpp
  src/util/fs.cpp
  src/util/image_io.cpp
  src/util/string.cpp
  src/util/zip.cpp
  src/util/stb_impl.cpp)

add_library(abzar_core SHARED ${ABZAR_SOURCES})
target_compile_definitions(abzar_core PRIVATE ABZAR_CORE_EXPORTS)
target_include_directories(abzar_core PUBLIC include PRIVATE src third_party)
target_link_libraries(abzar_core PRIVATE ZLIB::ZLIB)
if(ABZAR_ENABLE_CRYPTO)
  target_compile_definitions(abzar_core PRIVATE ABZAR_HAS_MBEDTLS=1)
  target_link_libraries(abzar_core PRIVATE MbedTLS::mbedcrypto)
endif()
if(ABZAR_ENABLE_TEXT_SHAPING)
  if(TARGET harfbuzz::harfbuzz)
    target_compile_definitions(abzar_core PRIVATE ABZAR_HAS_HARFBUZZ=1)
    target_link_libraries(abzar_core PRIVATE harfbuzz::harfbuzz)
    if(TARGET harfbuzz::subset)
      target_compile_definitions(abzar_core PRIVATE ABZAR_HAS_HARFBUZZ_SUBSET=1)
      target_link_libraries(abzar_core PRIVATE harfbuzz::subset)
    elseif(TARGET abzar_harfbuzz_subset)
      target_compile_definitions(abzar_core PRIVATE ABZAR_HAS_HARFBUZZ_SUBSET=1)
      target_link_libraries(abzar_core PRIVATE abzar_harfbuzz_subset)
    endif()
  elseif(TARGET harfbuzz)
    target_compile_definitions(abzar_core PRIVATE ABZAR_HAS_HARFBUZZ=1)
    target_link_libraries(abzar_core PRIVATE harfbuzz)
    if(TARGET harfbuzz-subset)
      target_compile_definitions(abzar_core PRIVATE ABZAR_HAS_HARFBUZZ_SUBSET=1)
      target_link_libraries(abzar_core PRIVATE harfbuzz-subset)
    endif()
  endif()
  if(TARGET Freetype::Freetype)
    target_compile_definitions(abzar_core PRIVATE ABZAR_HAS_FREETYPE=1)
    target_link_libraries(abzar_core PRIVATE Freetype::Freetype)
  elseif(TARGET freetype)
    target_compile_definitions(abzar_core PRIVATE ABZAR_HAS_FREETYPE=1)
    target_link_libraries(abzar_core PRIVATE freetype)
  endif()
endif()
if(ABZAR_ENABLE_OPENCV AND OpenCV_FOUND)
  target_compile_definitions(abzar_core PRIVATE ABZAR_HAS_OPENCV=1)
  target_include_directories(abzar_core PRIVATE ${OpenCV_INCLUDE_DIRS})
  target_link_libraries(abzar_core PRIVATE ${OpenCV_LIBS})
  # OpenCV generates opencv_modules.hpp as part of its module targets. Make
  # that generation an explicit prerequisite so parallel Ninja builds cannot
  # compile scan.cpp before the generated header exists.
  if(TARGET opencv_modules)
    add_dependencies(abzar_core opencv_modules)
  endif()
  if(TARGET opencv_core)
    add_dependencies(abzar_core opencv_core)
  endif()
  if(TARGET opencv_imgproc)
    add_dependencies(abzar_core opencv_imgproc)
  endif()
endif()
if(TARGET PDFium::pdfium)
  target_compile_definitions(abzar_core PRIVATE ABZAR_HAS_PDFIUM=1)
  target_link_libraries(abzar_core PRIVATE PDFium::pdfium)
  if(WIN32)
    install(FILES "$<TARGET_FILE:PDFium::pdfium>" DESTINATION . COMPONENT Runtime)
  endif()
elseif(TARGET pdfium)
  target_compile_definitions(abzar_core PRIVATE ABZAR_HAS_PDFIUM=1)
  target_link_libraries(abzar_core PRIVATE pdfium)
  if(WIN32)
    install(FILES "$<TARGET_FILE:pdfium>" DESTINATION . COMPONENT Runtime)
  endif()
endif()
if(TARGET qpdf::libqpdf)
  target_compile_definitions(abzar_core PRIVATE ABZAR_HAS_QPDF=1)
  target_link_libraries(abzar_core PRIVATE qpdf::libqpdf)
elseif(TARGET PkgConfig::QPDF)
  target_compile_definitions(abzar_core PRIVATE ABZAR_HAS_QPDF=1)
  target_link_libraries(abzar_core PRIVATE PkgConfig::QPDF)
elseif(TARGET libqpdf)
  target_compile_definitions(abzar_core PRIVATE ABZAR_HAS_QPDF=1)
  target_link_libraries(abzar_core PRIVATE libqpdf)
endif()
if(ABZAR_ENABLE_OCR)
  if(TARGET Tesseract::libtesseract)
    target_compile_definitions(abzar_core PRIVATE ABZAR_HAS_TESSERACT=1)
    target_link_libraries(abzar_core PRIVATE Tesseract::libtesseract)
  elseif(TARGET libtesseract)
    target_compile_definitions(abzar_core PRIVATE ABZAR_HAS_TESSERACT=1)
    target_link_libraries(abzar_core PRIVATE libtesseract)
  elseif(TARGET PkgConfig::TESSERACT)
    target_compile_definitions(abzar_core PRIVATE ABZAR_HAS_TESSERACT=1)
    target_link_libraries(abzar_core PRIVATE PkgConfig::TESSERACT)
  else()
    message(WARNING "ABZAR_ENABLE_OCR requested but Tesseract was not found; runtime returns ABZ_ERROR_OCR_UNAVAILABLE")
  endif()
endif()
if(ABZAR_ENABLE_WEBP)
  target_compile_definitions(abzar_core PRIVATE ABZAR_HAS_WEBP=1)
  target_link_libraries(abzar_core PRIVATE webp)
endif()
if(ABZAR_ENABLE_TIFF)
  target_compile_definitions(abzar_core PRIVATE ABZAR_HAS_TIFF=1)
  if(TARGET TIFF::tiff)
    target_link_libraries(abzar_core PRIVATE TIFF::tiff)
  else()
    target_link_libraries(abzar_core PRIVATE tiff)
  endif()
endif()
set_target_properties(abzar_core PROPERTIES
  OUTPUT_NAME abzar_core
  CXX_VISIBILITY_PRESET hidden
  VISIBILITY_INLINES_HIDDEN YES)
if(MSVC)
  target_compile_options(abzar_core PRIVATE /W4 /permissive- /EHsc /utf-8)
else()
  target_compile_options(abzar_core PRIVATE -Wall -Wextra -Wpedantic -Wconversion -Wshadow)
endif()
if(ANDROID)
  target_link_options(abzar_core PRIVATE "-Wl,-z,max-page-size=16384")
endif()

if(ABZAR_BUILD_TESTS AND NOT ANDROID)
  enable_testing()
  add_executable(abzar_core_tests tests/core_tests.cpp)
  target_include_directories(abzar_core_tests PRIVATE include src)
  target_link_libraries(abzar_core_tests PRIVATE abzar_core ZLIB::ZLIB)
  add_test(NAME abzar_core_structural_tests COMMAND abzar_core_tests)
endif()
