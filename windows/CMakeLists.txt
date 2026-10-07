# The Flutter tooling requires that developers have a version of Visual Studio
# installed that includes CMake 3.14 or later. You should not increase this
# version, as doing so will cause the plugin to fail to compile for some
# customers of the plugin.
cmake_minimum_required(VERSION 3.14)

# Project-level configuration.
set(PROJECT_NAME "mobile_scanner")
project(${PROJECT_NAME} LANGUAGES CXX)

# Explicitly opt in to modern CMake behaviors to avoid warnings with recent
# versions of CMake.
cmake_policy(VERSION 3.14...3.25)

# This value is used when generating builds using this plugin, so it must
# not be changed
set(PLUGIN_NAME "mobile_scanner_plugin")

# === zxing-cpp ===
# Barcode decoding is done with zxing-cpp, which is built as a static library
# and linked into the plugin DLL, so there is nothing extra to bundle.
#
# It is added with EXCLUDE_FROM_ALL so that its install rules (headers, static
# library, CMake package files) do not run as part of the app's install step.
# FetchContent_Declare(EXCLUDE_FROM_ALL) would be simpler, but needs CMake 3.28.
include(FetchContent)
if(POLICY CMP0169)
  cmake_policy(SET CMP0169 OLD)
endif()
FetchContent_Declare(
  zxing-cpp
  URL https://github.com/zxing-cpp/zxing-cpp/archive/refs/tags/v2.3.0.tar.gz
  URL_HASH SHA256=64e4139103fdbc57752698ee15b5f0b0f7af9a0331ecbdc492047e0772c417ba
)
set(BUILD_SHARED_LIBS OFF)
set(ZXING_READERS ON CACHE BOOL "" FORCE)
set(ZXING_WRITERS OFF CACHE STRING "" FORCE)
set(ZXING_C_API OFF CACHE BOOL "" FORCE)
set(ZXING_EXAMPLES OFF CACHE BOOL "" FORCE)
set(ZXING_BLACKBOX_TESTS OFF CACHE BOOL "" FORCE)
set(ZXING_UNIT_TESTS OFF CACHE BOOL "" FORCE)
set(ZXING_PYTHON_MODULE OFF CACHE BOOL "" FORCE)
FetchContent_GetProperties(zxing-cpp)
if(NOT zxing-cpp_POPULATED)
  FetchContent_Populate(zxing-cpp)
  add_subdirectory(${zxing-cpp_SOURCE_DIR} ${zxing-cpp_BINARY_DIR}
    EXCLUDE_FROM_ALL)
endif()

# Any new source files that you add to the plugin should be added here.
list(APPEND PLUGIN_SOURCES
  "barcode_decoder.cpp"
  "barcode_decoder.h"
  "barcode_payload.cpp"
  "barcode_payload.h"
  "camera_capture.cpp"
  "camera_capture.h"
  "image_utils.cpp"
  "image_utils.h"
  "mobile_scanner_plugin.cpp"
  "mobile_scanner_plugin.h"
  "vcard_parser.cpp"
  "vcard_parser.h"
  "worker_thread.cpp"
  "worker_thread.h"
)

# Define the plugin library target. Its name must not be changed (see comment
# on PLUGIN_NAME above).
add_library(${PLUGIN_NAME} SHARED
  "include/mobile_scanner/mobile_scanner_plugin_c_api.h"
  "mobile_scanner_plugin_c_api.cpp"
  ${PLUGIN_SOURCES}
)

# Apply a standard set of build settings that are configured in the
# application-level CMakeLists.txt. This can be removed for plugins that want
# full control over build settings.
apply_standard_settings(${PLUGIN_NAME})

# Symbols are hidden by default to reduce the chance of accidental conflicts
# between plugins. This should not be removed; any symbols that should be
# exported should be explicitly exported with the FLUTTER_PLUGIN_EXPORT macro.
set_target_properties(${PLUGIN_NAME} PROPERTIES
  CXX_VISIBILITY_PRESET hidden)
target_compile_definitions(${PLUGIN_NAME} PRIVATE FLUTTER_PLUGIN_IMPL)

# Source include directories and library dependencies. Add any plugin-specific
# dependencies here.
target_include_directories(${PLUGIN_NAME} INTERFACE
  "${CMAKE_CURRENT_SOURCE_DIR}/include")
target_link_libraries(${PLUGIN_NAME} PRIVATE
  flutter
  flutter_wrapper_plugin
  ZXing::ZXing
  cfgmgr32
  mf
  mfplat
  mfreadwrite
  mfuuid
  windowscodecs
)

# List of absolute paths to libraries that should be bundled with the plugin.
# This list could contain prebuilt libraries, or libraries created by an
# external build triggered from this build file.
set(mobile_scanner_bundled_libraries
  ""
  PARENT_SCOPE
)

# === Tests ===
# These unit tests can be run from a terminal after building the example, or
# from Visual Studio after opening the generated solution file.

# Only enable test builds when building the example (which sets this variable)
# so that plugin clients aren't building the tests.
if (${include_${PROJECT_NAME}_tests})
set(TEST_RUNNER "${PROJECT_NAME}_test")
enable_testing()

# Add the Google Test dependency.
FetchContent_Declare(
  googletest
  URL https://github.com/google/googletest/archive/refs/tags/v1.15.2.tar.gz
  URL_HASH SHA256=7b42b4d6ed48810c5362c265a17faebe90dc2373c885e5216439d37927f02926
)
# Prevent overriding the parent project's compiler/linker settings
set(gtest_force_shared_crt ON CACHE BOOL "" FORCE)
# Disable install commands for gtest so it doesn't end up in the bundle.
set(INSTALL_GTEST OFF CACHE BOOL "Disable installation of googletest" FORCE)
FetchContent_MakeAvailable(googletest)

# The tests cover the payload parsers, which do not depend on the camera,
# Media Foundation or zxing-cpp, so only those sources are built in.
add_executable(${TEST_RUNNER}
  test/barcode_payload_test.cpp
  test/vcard_parser_test.cpp
  "barcode_payload.cpp"
  "barcode_payload.h"
  "vcard_parser.cpp"
  "vcard_parser.h"
)
apply_standard_settings(${TEST_RUNNER})
target_include_directories(${TEST_RUNNER} PRIVATE "${CMAKE_CURRENT_SOURCE_DIR}")
target_link_libraries(${TEST_RUNNER} PRIVATE flutter_wrapper_plugin)
target_link_libraries(${TEST_RUNNER} PRIVATE gtest_main gmock)
# flutter_wrapper_plugin has link dependencies on the Flutter DLL.
add_custom_command(TARGET ${TEST_RUNNER} POST_BUILD
  COMMAND ${CMAKE_COMMAND} -E copy_if_different
  "${FLUTTER_LIBRARY}" $<TARGET_FILE_DIR:${TEST_RUNNER}>
)

# Enable automatic test discovery.
include(GoogleTest)
gtest_discover_tests(${TEST_RUNNER})
endif()
