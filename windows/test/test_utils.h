#ifndef FLUTTER_PLUGIN_MOBILE_SCANNER_TEST_UTILS_H_
#define FLUTTER_PLUGIN_MOBILE_SCANNER_TEST_UTILS_H_

#include <flutter/encodable_value.h>

#include <cstdint>
#include <string>

namespace mobile_scanner {
namespace test {

// Accessors for the values in an encoded barcode map. They throw if the key
// is missing or holds another type, which fails the test.

inline const flutter::EncodableMap& Map(const flutter::EncodableMap& map,
                                        const char* key) {
  return std::get<flutter::EncodableMap>(map.at(flutter::EncodableValue(key)));
}

inline const flutter::EncodableList& List(const flutter::EncodableMap& map,
                                          const char* key) {
  return std::get<flutter::EncodableList>(
      map.at(flutter::EncodableValue(key)));
}

inline std::string String(const flutter::EncodableMap& map, const char* key) {
  return std::get<std::string>(map.at(flutter::EncodableValue(key)));
}

inline int32_t Int(const flutter::EncodableMap& map, const char* key) {
  return std::get<int32_t>(map.at(flutter::EncodableValue(key)));
}

// Whether `key` is missing or null.
inline bool IsNull(const flutter::EncodableMap& map, const char* key) {
  auto it = map.find(flutter::EncodableValue(key));
  return it == map.end() || it->second.IsNull();
}

}  // namespace test
}  // namespace mobile_scanner

#endif  // FLUTTER_PLUGIN_MOBILE_SCANNER_TEST_UTILS_H_
