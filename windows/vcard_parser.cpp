#include "vcard_parser.h"

#include <algorithm>
#include <cctype>
#include <cstdlib>
#include <vector>

namespace mobile_scanner {

namespace {

using flutter::EncodableList;
using flutter::EncodableMap;
using flutter::EncodableValue;

// `PhoneType.rawValue` values from lib/src/enums/phone_type.dart.
constexpr int32_t kPhoneTypeUnknown = 0;
constexpr int32_t kPhoneTypeWork = 1;
constexpr int32_t kPhoneTypeHome = 2;
constexpr int32_t kPhoneTypeFax = 3;
constexpr int32_t kPhoneTypeMobile = 4;

// `EmailType` and `AddressType` share these values.
constexpr int32_t kTypeUnknown = 0;
constexpr int32_t kTypeWork = 1;
constexpr int32_t kTypeHome = 2;

struct ContentLine {
  // Upper case, without a group prefix (`item1.TEL` becomes `TEL`).
  std::string name;
  // Upper case parameter values, including vCard 2.1 bare parameters
  // (`TEL;WORK;VOICE` and `TEL;TYPE=work,voice` both give WORK and VOICE).
  std::vector<std::string> types;
  // The raw (still escaped) value.
  std::string value;
};

std::string ToUpper(std::string value) {
  std::transform(value.begin(), value.end(), value.begin(), [](char c) {
    return static_cast<char>(std::toupper(static_cast<unsigned char>(c)));
  });
  return value;
}

std::string Trim(const std::string& value) {
  auto is_space = [](char c) {
    return std::isspace(static_cast<unsigned char>(c)) != 0;
  };
  const auto begin = std::find_if_not(value.begin(), value.end(), is_space);
  const auto end =
      std::find_if_not(value.rbegin(), value.rend(), is_space).base();
  return begin < end ? std::string(begin, end) : std::string();
}

bool StartsWithIgnoreCase(const std::string& value, const std::string& prefix) {
  return ToUpper(value.substr(0, prefix.size())) == ToUpper(prefix);
}

// Splits `value` on `separator`, ignoring separators escaped with a
// backslash or inside double quotes. Escapes are kept.
std::vector<std::string> SplitUnescaped(const std::string& value,
                                        char separator) {
  std::vector<std::string> parts(1);
  bool quoted = false;
  for (size_t i = 0; i < value.size(); i++) {
    const char c = value[i];
    if (c == '\\' && i + 1 < value.size()) {
      parts.back() += c;
      parts.back() += value[++i];
    } else if (c == '"') {
      quoted = !quoted;
      parts.back() += c;
    } else if (c == separator && !quoted) {
      parts.emplace_back();
    } else {
      parts.back() += c;
    }
  }
  return parts;
}

std::string Unescape(const std::string& value) {
  std::string result;
  for (size_t i = 0; i < value.size(); i++) {
    if (value[i] == '\\' && i + 1 < value.size()) {
      const char next = value[++i];
      result += (next == 'n' || next == 'N') ? '\n' : next;
    } else {
      result += value[i];
    }
  }
  return result;
}

bool IsValidUtf8(const std::string& value) {
  size_t i = 0;
  while (i < value.size()) {
    const auto c = static_cast<unsigned char>(value[i]);
    const size_t length = c < 0x80 ? 1
                          : (c >> 5) == 0x6 ? 2
                          : (c >> 4) == 0xE ? 3
                          : (c >> 3) == 0x1E ? 4
                                             : 0;
    if (length == 0 || i + length > value.size()) {
      return false;
    }
    for (size_t j = 1; j < length; j++) {
      if ((static_cast<unsigned char>(value[i + j]) >> 6) != 0x2) {
        return false;
      }
    }
    i += length;
  }
  return true;
}

std::string Latin1ToUtf8(const std::string& value) {
  std::string result;
  for (const char c : value) {
    const auto byte = static_cast<unsigned char>(c);
    if (byte < 0x80) {
      result += c;
    } else {
      result += static_cast<char>(0xC0 | (byte >> 6));
      result += static_cast<char>(0x80 | (byte & 0x3F));
    }
  }
  return result;
}

// Decodes a vCard 2.1 QUOTED-PRINTABLE value. The charset is usually UTF-8;
// anything that does not decode as UTF-8 is treated as Latin-1, so that only
// valid UTF-8 is sent to Dart.
std::string DecodeQuotedPrintable(const std::string& value) {
  std::string decoded;
  for (size_t i = 0; i < value.size(); i++) {
    if (value[i] == '=' && i + 2 < value.size() &&
        std::isxdigit(static_cast<unsigned char>(value[i + 1])) &&
        std::isxdigit(static_cast<unsigned char>(value[i + 2]))) {
      decoded += static_cast<char>(
          std::strtol(value.substr(i + 1, 2).c_str(), nullptr, 16));
      i += 2;
    } else {
      decoded += value[i];
    }
  }
  return IsValidUtf8(decoded) ? decoded : Latin1ToUtf8(decoded);
}

// Splits the payload into content lines: unfolds continuation lines, joins
// quoted-printable soft line breaks and separates names, parameters and
// values.
std::vector<ContentLine> ParseContentLines(const std::string& text) {
  std::vector<std::string> physical_lines;
  std::string line;
  for (size_t i = 0; i <= text.size(); i++) {
    if (i == text.size() || text[i] == '\n' || text[i] == '\r') {
      physical_lines.push_back(line);
      line.clear();
      if (i + 1 < text.size() && text[i] == '\r' && text[i + 1] == '\n') {
        i++;
      }
    } else {
      line += text[i];
    }
  }

  std::vector<std::string> logical_lines;
  for (const std::string& physical : physical_lines) {
    if (!logical_lines.empty() && !physical.empty() &&
        (physical[0] == ' ' || physical[0] == '\t')) {
      // RFC folding: a line starting with whitespace continues the previous.
      logical_lines.back() += physical.substr(1);
    } else if (!logical_lines.empty() && !logical_lines.back().empty() &&
               logical_lines.back().back() == '=' &&
               ToUpper(logical_lines.back()).find("QUOTED-PRINTABLE") !=
                   std::string::npos) {
      // Quoted-printable soft line break.
      logical_lines.back().pop_back();
      logical_lines.back() += physical;
    } else if (!Trim(physical).empty()) {
      logical_lines.push_back(physical);
    }
  }

  std::vector<ContentLine> content_lines;
  for (const std::string& logical : logical_lines) {
    // The value starts at the first colon outside a quoted parameter value.
    size_t colon = std::string::npos;
    bool quoted = false;
    for (size_t i = 0; i < logical.size(); i++) {
      if (logical[i] == '"') {
        quoted = !quoted;
      } else if (logical[i] == ':' && !quoted) {
        colon = i;
        break;
      }
    }
    if (colon == std::string::npos) {
      continue;
    }

    ContentLine content_line;
    content_line.value = logical.substr(colon + 1);
    const std::vector<std::string> name_and_params =
        SplitUnescaped(logical.substr(0, colon), ';');

    content_line.name = ToUpper(Trim(name_and_params[0]));
    if (const size_t dot = content_line.name.find('.');
        dot != std::string::npos) {
      content_line.name = content_line.name.substr(dot + 1);
    }

    bool quoted_printable = false;
    for (size_t i = 1; i < name_and_params.size(); i++) {
      std::string param = ToUpper(Trim(name_and_params[i]));
      std::string param_value = param;
      if (const size_t equals = param.find('='); equals != std::string::npos) {
        const std::string param_name = param.substr(0, equals);
        param_value = param.substr(equals + 1);
        if (param_name == "ENCODING" && param_value == "QUOTED-PRINTABLE") {
          quoted_printable = true;
        }
        if (param_name != "TYPE") {
          continue;
        }
      } else if (param == "QUOTED-PRINTABLE") {
        quoted_printable = true;
        continue;
      }
      param_value.erase(
          std::remove(param_value.begin(), param_value.end(), '"'),
          param_value.end());
      for (const std::string& type : SplitUnescaped(param_value, ',')) {
        content_line.types.push_back(Trim(type));
      }
    }

    if (quoted_printable) {
      content_line.value = DecodeQuotedPrintable(content_line.value);
    }
    content_lines.push_back(std::move(content_line));
  }
  return content_lines;
}

bool HasType(const ContentLine& line, const char* type) {
  return std::find(line.types.begin(), line.types.end(), type) !=
         line.types.end();
}

int32_t WorkOrHomeType(const ContentLine& line) {
  if (HasType(line, "WORK")) {
    return kTypeWork;
  }
  if (HasType(line, "HOME")) {
    return kTypeHome;
  }
  return kTypeUnknown;
}

int32_t PhoneType(const ContentLine& line) {
  if (HasType(line, "FAX")) {
    return kPhoneTypeFax;
  }
  if (HasType(line, "CELL")) {
    return kPhoneTypeMobile;
  }
  if (HasType(line, "WORK")) {
    return kPhoneTypeWork;
  }
  if (HasType(line, "HOME")) {
    return kPhoneTypeHome;
  }
  return kPhoneTypeUnknown;
}

// Removes a URI scheme such as `tel:` or `mailto:` from a value.
std::string StripScheme(const std::string& value, const char* scheme) {
  return StartsWithIgnoreCase(value, scheme)
             ? value.substr(std::char_traits<char>::length(scheme))
             : value;
}

// The unescaped components of a structured value such as N or ADR.
std::vector<std::string> Components(const std::string& value) {
  std::vector<std::string> components;
  for (const std::string& component : SplitUnescaped(value, ';')) {
    components.push_back(Trim(Unescape(component)));
  }
  return components;
}

EncodableValue OptionalString(const std::string& value) {
  return value.empty() ? EncodableValue() : EncodableValue(value);
}

// Formats an ADR value (PO box; extended; street; locality; region; postal
// code; country) as address lines.
EncodableList AddressLines(const std::string& value) {
  std::vector<std::string> parts = Components(value);
  parts.resize(7);
  const std::string& po_box = parts[0];
  const std::string& extended = parts[1];
  const std::string& street = parts[2];
  const std::string& locality = parts[3];
  const std::string& region = parts[4];
  const std::string& postal_code = parts[5];
  const std::string& country = parts[6];

  EncodableList lines;
  for (const std::string& part : {po_box, extended}) {
    if (!part.empty()) {
      lines.emplace_back(part);
    }
  }
  // A street may span several lines.
  for (const std::string& street_line : SplitUnescaped(street, '\n')) {
    if (!Trim(street_line).empty()) {
      lines.emplace_back(Trim(street_line));
    }
  }

  // "Locality, Region PostalCode"
  std::string city_line = locality;
  if (!region.empty()) {
    city_line += (city_line.empty() ? "" : ", ") + region;
  }
  if (!postal_code.empty()) {
    city_line += (city_line.empty() ? "" : " ") + postal_code;
  }
  if (!city_line.empty()) {
    lines.emplace_back(city_line);
  }
  if (!country.empty()) {
    lines.emplace_back(country);
  }
  return lines;
}

}  // namespace

std::optional<EncodableMap> ParseVCard(const std::string& text) {
  EncodableMap name;
  EncodableList phones;
  EncodableList emails;
  EncodableList addresses;
  EncodableList urls;
  std::string organization;
  std::string title;
  std::string pronunciation;

  for (const ContentLine& line : ParseContentLines(text)) {
    if (line.name == "FN") {
      name[EncodableValue("formattedName")] =
          OptionalString(Trim(Unescape(line.value)));
    } else if (line.name == "N") {
      std::vector<std::string> parts = Components(line.value);
      parts.resize(5);
      name[EncodableValue("last")] = OptionalString(parts[0]);
      name[EncodableValue("first")] = OptionalString(parts[1]);
      name[EncodableValue("middle")] = OptionalString(parts[2]);
      name[EncodableValue("prefix")] = OptionalString(parts[3]);
      name[EncodableValue("suffix")] = OptionalString(parts[4]);
    } else if (line.name == "X-PHONETIC-FIRST-NAME" ||
               line.name == "X-PHONETIC-MIDDLE-NAME" ||
               line.name == "X-PHONETIC-LAST-NAME" ||
               line.name == "SORT-STRING") {
      const std::string value = Trim(Unescape(line.value));
      if (!value.empty()) {
        pronunciation += (pronunciation.empty() ? "" : " ") + value;
      }
    } else if (line.name == "TEL") {
      const std::string number =
          Trim(StripScheme(Unescape(line.value), "tel:"));
      if (!number.empty()) {
        phones.emplace_back(EncodableMap{
            {EncodableValue("number"), EncodableValue(number)},
            {EncodableValue("type"), EncodableValue(PhoneType(line))},
        });
      }
    } else if (line.name == "EMAIL") {
      const std::string address =
          Trim(StripScheme(Unescape(line.value), "mailto:"));
      if (!address.empty()) {
        emails.emplace_back(EncodableMap{
            {EncodableValue("address"), EncodableValue(address)},
            {EncodableValue("type"), EncodableValue(WorkOrHomeType(line))},
        });
      }
    } else if (line.name == "ADR") {
      addresses.emplace_back(EncodableMap{
          {EncodableValue("addressLines"),
           EncodableValue(AddressLines(line.value))},
          {EncodableValue("type"), EncodableValue(WorkOrHomeType(line))},
      });
    } else if (line.name == "URL") {
      const std::string url = Trim(Unescape(line.value));
      if (!url.empty()) {
        urls.emplace_back(url);
      }
    } else if (line.name == "ORG") {
      // "Company;Department" becomes "Company, Department".
      for (const std::string& unit : Components(line.value)) {
        if (!unit.empty()) {
          organization += (organization.empty() ? "" : ", ") + unit;
        }
      }
    } else if (line.name == "TITLE") {
      title = Trim(Unescape(line.value));
    }
  }

  if (!pronunciation.empty()) {
    name[EncodableValue("pronunciation")] = EncodableValue(pronunciation);
  }

  EncodableMap contact{
      {EncodableValue("addresses"), EncodableValue(std::move(addresses))},
      {EncodableValue("emails"), EncodableValue(std::move(emails))},
      {EncodableValue("organization"), OptionalString(organization)},
      {EncodableValue("phones"), EncodableValue(std::move(phones))},
      {EncodableValue("title"), OptionalString(title)},
      {EncodableValue("urls"), EncodableValue(std::move(urls))},
  };
  if (!name.empty()) {
    contact[EncodableValue("name")] = EncodableValue(std::move(name));
  }
  return contact;
}

std::optional<EncodableMap> ParseVEvent(const std::string& text) {
  EncodableMap event;
  bool in_event = false;
  bool found_event = false;
  // Nested components (like VALARM) have their own properties, which must
  // not override the event's.
  int nested_depth = 0;

  for (const ContentLine& line : ParseContentLines(text)) {
    const std::string value = Trim(line.value);
    if (line.name == "BEGIN") {
      if (!in_event && ToUpper(value) == "VEVENT") {
        in_event = true;
        found_event = true;
      } else if (in_event) {
        nested_depth++;
      }
      continue;
    }
    if (line.name == "END") {
      if (in_event && nested_depth > 0) {
        nested_depth--;
      } else if (in_event && ToUpper(value) == "VEVENT") {
        break;
      }
      continue;
    }
    if (!in_event || nested_depth > 0) {
      continue;
    }

    if (line.name == "SUMMARY") {
      event[EncodableValue("summary")] = OptionalString(Trim(Unescape(value)));
    } else if (line.name == "DESCRIPTION") {
      event[EncodableValue("description")] =
          OptionalString(Trim(Unescape(value)));
    } else if (line.name == "LOCATION") {
      event[EncodableValue("location")] =
          OptionalString(Trim(Unescape(value)));
    } else if (line.name == "ORGANIZER") {
      event[EncodableValue("organizer")] =
          OptionalString(Trim(StripScheme(Unescape(value), "mailto:")));
    } else if (line.name == "STATUS") {
      event[EncodableValue("status")] = OptionalString(value);
    } else if (line.name == "DTSTART") {
      event[EncodableValue("start")] = OptionalString(value);
    } else if (line.name == "DTEND") {
      event[EncodableValue("end")] = OptionalString(value);
    }
  }

  if (!found_event) {
    return std::nullopt;
  }
  return event;
}

}  // namespace mobile_scanner
