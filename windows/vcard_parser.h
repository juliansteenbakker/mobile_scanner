#ifndef FLUTTER_PLUGIN_MOBILE_SCANNER_VCARD_PARSER_H_
#define FLUTTER_PLUGIN_MOBILE_SCANNER_VCARD_PARSER_H_

#include <flutter/encodable_value.h>

#include <optional>
#include <string>

namespace mobile_scanner {

// Parsers for vCard (RFC 2426 / RFC 6350, and vCard 2.1) and iCalendar
// (RFC 5545) payloads. Both formats share the same content line syntax:
// folded lines, `NAME;PARAM=VALUE:value` properties and backslash escapes.

// Parses a vCard into the map that `ContactInfo.fromNative` expects.
std::optional<flutter::EncodableMap> ParseVCard(const std::string& text);

// Parses the first VEVENT of an iCalendar payload (with or without the
// VCALENDAR wrapper) into the map that `CalendarEvent.fromNative` expects.
// `start` and `end` are the raw iCalendar date-time values, like on Android.
std::optional<flutter::EncodableMap> ParseVEvent(const std::string& text);

}  // namespace mobile_scanner

#endif  // FLUTTER_PLUGIN_MOBILE_SCANNER_VCARD_PARSER_H_
