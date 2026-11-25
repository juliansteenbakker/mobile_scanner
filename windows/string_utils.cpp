#include "string_utils.h"

#include <algorithm>
#include <cctype>

namespace mobile_scanner {

namespace {

bool IsSpace(char c) { return std::isspace(static_cast<unsigned char>(c)); }

}  // namespace

std::string Trim(const std::string& value) {
  const auto begin = std::find_if_not(value.begin(), value.end(), IsSpace);
  const auto end =
      std::find_if_not(value.rbegin(), value.rend(), IsSpace).base();
  return begin < end ? std::string(begin, end) : std::string();
}

std::string ToUpper(std::string value) {
  std::transform(value.begin(), value.end(), value.begin(), [](char c) {
    return static_cast<char>(std::toupper(static_cast<unsigned char>(c)));
  });
  return value;
}

bool StartsWith(const std::string& value, const std::string& prefix) {
  return value.compare(0, prefix.size(), prefix) == 0;
}

bool StartsWithIgnoreCase(const std::string& value, const std::string& prefix) {
  return ToUpper(value.substr(0, prefix.size())) == ToUpper(prefix);
}

flutter::EncodableValue OptionalString(const std::string& value) {
  return value.empty() ? flutter::EncodableValue()
                       : flutter::EncodableValue(value);
}

flutter::EncodableValue OptionalString(
    const std::optional<std::string>& value) {
  return value ? flutter::EncodableValue(*value) : flutter::EncodableValue();
}

}  // namespace mobile_scanner
