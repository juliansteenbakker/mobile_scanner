#ifndef FLUTTER_PLUGIN_MOBILE_SCANNER_STRING_UTILS_H_
#define FLUTTER_PLUGIN_MOBILE_SCANNER_STRING_UTILS_H_

#include <flutter/encodable_value.h>

#include <optional>
#include <string>

namespace mobile_scanner {

// Removes leading and trailing whitespace.
std::string Trim(const std::string& value);

std::string ToUpper(std::string value);

bool StartsWith(const std::string& value, const std::string& prefix);

bool StartsWithIgnoreCase(const std::string& value, const std::string& prefix);

// Returns null for an empty string.
flutter::EncodableValue OptionalString(const std::string& value);

// Returns null for a missing value; an empty string is kept.
flutter::EncodableValue OptionalString(const std::optional<std::string>& value);

}  // namespace mobile_scanner

#endif  // FLUTTER_PLUGIN_MOBILE_SCANNER_STRING_UTILS_H_
