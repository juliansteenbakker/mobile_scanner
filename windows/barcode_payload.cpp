#include "barcode_payload.h"

#include <algorithm>
#include <cctype>
#include <cstdlib>
#include <optional>
#include <vector>

#include "vcard_parser.h"

namespace mobile_scanner {

namespace {

using flutter::EncodableList;
using flutter::EncodableMap;
using flutter::EncodableValue;

// `BarcodeType.rawValue` values from lib/src/enums/barcode_type.dart.
constexpr int32_t kTypeUnknown = 0;
constexpr int32_t kTypeContactInfo = 1;
constexpr int32_t kTypeEmail = 2;
constexpr int32_t kTypeIsbn = 3;
constexpr int32_t kTypePhone = 4;
constexpr int32_t kTypeProduct = 5;
constexpr int32_t kTypeSms = 6;
constexpr int32_t kTypeText = 7;
constexpr int32_t kTypeUrl = 8;
constexpr int32_t kTypeWifi = 9;
constexpr int32_t kTypeGeo = 10;
constexpr int32_t kTypeCalendarEvent = 11;

// `EncryptionType.rawValue` values from lib/src/enums/encryption_type.dart.
constexpr int32_t kEncryptionOpen = 1;
constexpr int32_t kEncryptionWpa = 2;
constexpr int32_t kEncryptionWep = 3;

bool IsSpace(char c) { return std::isspace(static_cast<unsigned char>(c)); }
bool IsDigit(char c) { return std::isdigit(static_cast<unsigned char>(c)); }

std::string Trim(const std::string& value) {
  const auto begin = std::find_if_not(value.begin(), value.end(), IsSpace);
  const auto end = std::find_if_not(value.rbegin(), value.rend(), IsSpace).base();
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

bool AllDigits(const std::string& value) {
  return !value.empty() && std::all_of(value.begin(), value.end(), IsDigit);
}

// ISBN-10 (10 digits) or ISBN-13 (13 digits starting with 978 or 979),
// ignoring hyphens, spaces and an "ISBN" label.
bool IsIsbn(const std::string& text) {
  std::string digits = ToUpper(text);
  for (const std::string removed : {"-", " ", "ISBN"}) {
    for (size_t pos; (pos = digits.find(removed)) != std::string::npos;) {
      digits.erase(pos, removed.size());
    }
  }
  digits = Trim(digits);
  if (!AllDigits(digits)) {
    return false;
  }
  return digits.size() == 10 ||
         (digits.size() == 13 &&
          (StartsWith(digits, "978") || StartsWith(digits, "979")));
}

// EAN-8, UPC-A or EAN-13, counting only the digits.
bool IsProductCode(const std::string& text) {
  const auto digits = std::count_if(text.begin(), text.end(), IsDigit);
  return digits == 8 || digits == 12 || digits == 13;
}

std::string PercentDecode(const std::string& value) {
  std::string decoded;
  for (size_t i = 0; i < value.size(); i++) {
    if (value[i] == '%' && i + 2 < value.size() &&
        std::isxdigit(static_cast<unsigned char>(value[i + 1])) &&
        std::isxdigit(static_cast<unsigned char>(value[i + 2]))) {
      decoded += static_cast<char>(
          std::strtol(value.substr(i + 1, 2).c_str(), nullptr, 16));
      i += 2;
    } else if (value[i] == '+') {
      decoded += ' ';
    } else {
      decoded += value[i];
    }
  }
  return decoded;
}

// Returns the value of `name` in a `key=value&key=value` query string.
std::optional<std::string> QueryParameter(const std::string& query,
                                          const std::string& name) {
  size_t start = 0;
  while (start <= query.size()) {
    size_t end = query.find('&', start);
    if (end == std::string::npos) {
      end = query.size();
    }
    const std::string pair = query.substr(start, end - start);
    const size_t equals = pair.find('=');
    if (equals != std::string::npos &&
        ToUpper(pair.substr(0, equals)) == ToUpper(name)) {
      return PercentDecode(pair.substr(equals + 1));
    }
    start = end + 1;
  }
  return std::nullopt;
}

// Splits a MECARD-style payload (`KEY:value;KEY:value;;`) into its fields,
// honoring backslash escapes.
std::vector<std::pair<std::string, std::string>> ParseMecardFields(
    const std::string& body) {
  std::vector<std::pair<std::string, std::string>> fields;
  std::string field;
  auto add_field = [&]() {
    const size_t colon = field.find(':');
    if (colon != std::string::npos) {
      fields.emplace_back(ToUpper(field.substr(0, colon)),
                          field.substr(colon + 1));
    }
    field.clear();
  };
  for (size_t i = 0; i < body.size(); i++) {
    if (body[i] == '\\' && i + 1 < body.size()) {
      field += body[++i];
    } else if (body[i] == ';') {
      add_field();
    } else {
      field += body[i];
    }
  }
  add_field();
  return fields;
}

std::optional<std::string> MecardField(
    const std::vector<std::pair<std::string, std::string>>& fields,
    const std::string& key) {
  for (const auto& [name, value] : fields) {
    if (name == key) {
      return value;
    }
  }
  return std::nullopt;
}

std::vector<std::string> MecardFields(
    const std::vector<std::pair<std::string, std::string>>& fields,
    const std::string& key) {
  std::vector<std::string> values;
  for (const auto& [name, value] : fields) {
    if (name == key && !Trim(value).empty()) {
      values.push_back(Trim(value));
    }
  }
  return values;
}

EncodableValue OptionalString(const std::optional<std::string>& value) {
  return value ? EncodableValue(*value) : EncodableValue();
}

// `MECARD:N:Doe,Jane;TEL:...;EMAIL:...;ADR:...;;`, the contact format used
// by many phone QR code generators.
EncodableMap ParseMecard(const std::string& text) {
  const auto fields = ParseMecardFields(text.substr(text.find(':') + 1));

  EncodableMap name;
  if (const auto full_name = MecardField(fields, "N")) {
    // "Last,First"
    const size_t comma = full_name->find(',');
    const std::string last = Trim(full_name->substr(0, comma));
    const std::string first =
        comma == std::string::npos ? "" : Trim(full_name->substr(comma + 1));
    name[EncodableValue("last")] =
        last.empty() ? EncodableValue() : EncodableValue(last);
    name[EncodableValue("first")] =
        first.empty() ? EncodableValue() : EncodableValue(first);
    name[EncodableValue("formattedName")] = EncodableValue(
        first.empty() || last.empty() ? first + last : first + " " + last);
  }
  if (const auto sound = MecardField(fields, "SOUND")) {
    name[EncodableValue("pronunciation")] = EncodableValue(Trim(*sound));
  }

  EncodableList phones;
  for (const std::string& number : MecardFields(fields, "TEL")) {
    phones.emplace_back(
        EncodableMap{{EncodableValue("number"), EncodableValue(number)}});
  }
  EncodableList emails;
  for (const std::string& address : MecardFields(fields, "EMAIL")) {
    emails.emplace_back(
        EncodableMap{{EncodableValue("address"), EncodableValue(address)}});
  }
  // ADR is "PO box,room,street,city,region,postal code,country".
  EncodableList addresses;
  for (const std::string& address : MecardFields(fields, "ADR")) {
    EncodableList lines;
    size_t start = 0;
    while (start <= address.size()) {
      size_t end = address.find(',', start);
      if (end == std::string::npos) {
        end = address.size();
      }
      const std::string line = Trim(address.substr(start, end - start));
      if (!line.empty()) {
        lines.emplace_back(line);
      }
      start = end + 1;
    }
    addresses.emplace_back(EncodableMap{
        {EncodableValue("addressLines"), EncodableValue(std::move(lines))}});
  }
  EncodableList urls;
  for (const std::string& url : MecardFields(fields, "URL")) {
    urls.emplace_back(url);
  }

  EncodableMap contact{
      {EncodableValue("addresses"), EncodableValue(std::move(addresses))},
      {EncodableValue("emails"), EncodableValue(std::move(emails))},
      {EncodableValue("organization"), OptionalString(MecardField(fields, "ORG"))},
      {EncodableValue("phones"), EncodableValue(std::move(phones))},
      {EncodableValue("title"), OptionalString(MecardField(fields, "TITLE"))},
      {EncodableValue("urls"), EncodableValue(std::move(urls))},
  };
  if (!name.empty()) {
    contact[EncodableValue("name")] = EncodableValue(std::move(name));
  }
  return contact;
}

// The text after the `scheme:` prefix.
std::string AfterScheme(const std::string& text) {
  return text.substr(text.find(':') + 1);
}

EncodableMap ParseUrl(const std::string& text) {
  if (StartsWith(ToUpper(text), "MEBKM:")) {
    const auto fields = ParseMecardFields(AfterScheme(text));
    return EncodableMap{
        {EncodableValue("title"), OptionalString(MecardField(fields, "TITLE"))},
        {EncodableValue("url"),
         EncodableValue(MecardField(fields, "URL").value_or(""))},
    };
  }
  return EncodableMap{{EncodableValue("url"), EncodableValue(text)}};
}

EncodableMap ParseWifi(const std::string& text) {
  const auto fields = ParseMecardFields(AfterScheme(text));
  const std::string security = ToUpper(MecardField(fields, "T").value_or(""));

  int32_t encryption = kEncryptionOpen;
  if (security == "WEP") {
    encryption = kEncryptionWep;
  } else if (StartsWith(security, "WPA") || security == "SAE") {
    encryption = kEncryptionWpa;
  }

  return EncodableMap{
      {EncodableValue("encryptionType"), EncodableValue(encryption)},
      {EncodableValue("ssid"), OptionalString(MecardField(fields, "S"))},
      {EncodableValue("password"), OptionalString(MecardField(fields, "P"))},
  };
}

EncodableMap ParseEmail(const std::string& text) {
  const std::string body = AfterScheme(text);
  const size_t question = body.find('?');
  const std::string query =
      question == std::string::npos ? "" : body.substr(question + 1);
  return EncodableMap{
      {EncodableValue("address"),
       EncodableValue(PercentDecode(body.substr(0, question)))},
      {EncodableValue("subject"),
       OptionalString(QueryParameter(query, "subject"))},
      {EncodableValue("body"), OptionalString(QueryParameter(query, "body"))},
  };
}

EncodableMap ParsePhone(const std::string& text) {
  return EncodableMap{
      {EncodableValue("number"), EncodableValue(Trim(AfterScheme(text)))},
  };
}

// Supports both `SMS:number:message` and `sms:number?body=message`.
EncodableMap ParseSms(const std::string& text) {
  std::string number = AfterScheme(text);
  std::optional<std::string> message;
  if (const size_t colon = number.find(':'); colon != std::string::npos) {
    message = number.substr(colon + 1);
    number = number.substr(0, colon);
  } else if (const size_t question = number.find('?');
             question != std::string::npos) {
    message = QueryParameter(number.substr(question + 1), "body");
    number = number.substr(0, question);
  }
  return EncodableMap{
      {EncodableValue("phoneNumber"), EncodableValue(Trim(number))},
      {EncodableValue("message"), OptionalString(message)},
  };
}

// `GEO:latitude,longitude[,altitude][?query]`.
std::optional<EncodableMap> ParseGeo(const std::string& text) {
  std::string coordinates = AfterScheme(text);
  coordinates = coordinates.substr(0, coordinates.find('?'));
  const size_t comma = coordinates.find(',');
  if (comma == std::string::npos) {
    return std::nullopt;
  }

  char* end = nullptr;
  const std::string latitude_text = coordinates.substr(0, comma);
  const double latitude = std::strtod(latitude_text.c_str(), &end);
  if (end == latitude_text.c_str()) {
    return std::nullopt;
  }
  const std::string longitude_text = coordinates.substr(comma + 1);
  const double longitude = std::strtod(longitude_text.c_str(), &end);
  if (end == longitude_text.c_str()) {
    return std::nullopt;
  }

  return EncodableMap{
      {EncodableValue("latitude"), EncodableValue(latitude)},
      {EncodableValue("longitude"), EncodableValue(longitude)},
  };
}

}  // namespace

int32_t DetectBarcodeType(const std::string& text) {
  const std::string trimmed = Trim(text);
  if (trimmed.empty()) {
    return kTypeUnknown;
  }

  // More specific patterns are checked first.
  const std::string upper = ToUpper(trimmed);
  if (StartsWith(upper, "BEGIN:VCARD") || StartsWith(upper, "MECARD:")) {
    return kTypeContactInfo;
  }
  if (StartsWith(upper, "BEGIN:VCALENDAR") || StartsWith(upper, "BEGIN:VEVENT")) {
    return kTypeCalendarEvent;
  }
  if (StartsWith(upper, "WIFI:")) {
    return kTypeWifi;
  }
  if (StartsWith(upper, "MAILTO:")) {
    return kTypeEmail;
  }
  if (StartsWith(upper, "TEL:")) {
    return kTypePhone;
  }
  if (StartsWith(upper, "SMS:")) {
    return kTypeSms;
  }
  if (StartsWith(upper, "GEO:")) {
    return kTypeGeo;
  }
  if (StartsWith(upper, "MEBKM:") || StartsWith(upper, "HTTP://") ||
      StartsWith(upper, "HTTPS://")) {
    return kTypeUrl;
  }
  if (IsIsbn(trimmed)) {
    return kTypeIsbn;
  }
  if (IsProductCode(trimmed)) {
    return kTypeProduct;
  }
  return kTypeText;
}

void AddBarcodePayload(int32_t type, const std::string& text,
                       EncodableMap& barcode) {
  const std::string trimmed = Trim(text);
  switch (type) {
    case kTypeUrl:
      barcode[EncodableValue("url")] = EncodableValue(ParseUrl(trimmed));
      break;
    case kTypeWifi:
      barcode[EncodableValue("wifi")] = EncodableValue(ParseWifi(trimmed));
      break;
    case kTypeEmail:
      barcode[EncodableValue("email")] = EncodableValue(ParseEmail(trimmed));
      break;
    case kTypePhone:
      barcode[EncodableValue("phone")] = EncodableValue(ParsePhone(trimmed));
      break;
    case kTypeSms:
      barcode[EncodableValue("sms")] = EncodableValue(ParseSms(trimmed));
      break;
    case kTypeContactInfo:
      if (StartsWith(ToUpper(trimmed), "MECARD:")) {
        barcode[EncodableValue("contactInfo")] =
            EncodableValue(ParseMecard(trimmed));
      } else if (auto contact = ParseVCard(trimmed)) {
        barcode[EncodableValue("contactInfo")] =
            EncodableValue(std::move(*contact));
      }
      break;
    case kTypeCalendarEvent:
      if (auto event = ParseVEvent(trimmed)) {
        barcode[EncodableValue("calendarEvent")] =
            EncodableValue(std::move(*event));
      }
      break;
    case kTypeGeo:
      if (auto geo = ParseGeo(trimmed)) {
        barcode[EncodableValue("geoPoint")] = EncodableValue(std::move(*geo));
      }
      break;
    default:
      break;
  }
}

}  // namespace mobile_scanner
