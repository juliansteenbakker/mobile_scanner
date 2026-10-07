#include <flutter/encodable_value.h>
#include <gtest/gtest.h>

#include <string>

#include "barcode_payload.h"

namespace mobile_scanner {
namespace test {

namespace {

using flutter::EncodableList;
using flutter::EncodableMap;
using flutter::EncodableValue;

// `BarcodeType.rawValue` values from lib/src/enums/barcode_type.dart.
constexpr int32_t kUnknown = 0;
constexpr int32_t kContactInfo = 1;
constexpr int32_t kEmail = 2;
constexpr int32_t kIsbn = 3;
constexpr int32_t kPhone = 4;
constexpr int32_t kProduct = 5;
constexpr int32_t kSms = 6;
constexpr int32_t kText = 7;
constexpr int32_t kUrl = 8;
constexpr int32_t kWifi = 9;
constexpr int32_t kGeo = 10;
constexpr int32_t kCalendarEvent = 11;

// Detects the type of `text` and returns the barcode map with its payload.
EncodableMap Parse(const std::string& text) {
  EncodableMap barcode;
  AddBarcodePayload(DetectBarcodeType(text), text, barcode);
  return barcode;
}

const EncodableMap& Map(const EncodableMap& map, const char* key) {
  return std::get<EncodableMap>(map.at(EncodableValue(key)));
}

const EncodableList& List(const EncodableMap& map, const char* key) {
  return std::get<EncodableList>(map.at(EncodableValue(key)));
}

std::string String(const EncodableMap& map, const char* key) {
  return std::get<std::string>(map.at(EncodableValue(key)));
}

bool IsNull(const EncodableMap& map, const char* key) {
  auto it = map.find(EncodableValue(key));
  return it == map.end() || it->second.IsNull();
}

}  // namespace

TEST(DetectBarcodeType, MatchesBarcodeTypeDetectorSwift) {
  EXPECT_EQ(DetectBarcodeType(""), kUnknown);
  EXPECT_EQ(DetectBarcodeType("   "), kUnknown);
  EXPECT_EQ(DetectBarcodeType("BEGIN:VCARD\nEND:VCARD"), kContactInfo);
  EXPECT_EQ(DetectBarcodeType("begin:vcalendar\nEND:VCALENDAR"),
            kCalendarEvent);
  EXPECT_EQ(DetectBarcodeType("WIFI:S:Net;;"), kWifi);
  EXPECT_EQ(DetectBarcodeType("mailto:a@b.c"), kEmail);
  EXPECT_EQ(DetectBarcodeType("tel:123"), kPhone);
  EXPECT_EQ(DetectBarcodeType("SMS:123:hi"), kSms);
  EXPECT_EQ(DetectBarcodeType("geo:1,2"), kGeo);
  EXPECT_EQ(DetectBarcodeType("MEBKM:URL:x;;"), kUrl);
  EXPECT_EQ(DetectBarcodeType("https://example.com"), kUrl);
  EXPECT_EQ(DetectBarcodeType("  http://example.com  "), kUrl);
  EXPECT_EQ(DetectBarcodeType("978-3-16-148410-0"), kIsbn);
  EXPECT_EQ(DetectBarcodeType("ISBN 0-306-40615-2"), kIsbn);
  EXPECT_EQ(DetectBarcodeType("4006381333931"), kProduct);
  EXPECT_EQ(DetectBarcodeType("12345678"), kProduct);
  EXPECT_EQ(DetectBarcodeType("Hello"), kText);
}

TEST(DetectBarcodeType, RecognizesMecardAndBareVevent) {
  EXPECT_EQ(DetectBarcodeType("MECARD:N:Doe,Jane;;"), kContactInfo);
  EXPECT_EQ(DetectBarcodeType("BEGIN:VEVENT\nEND:VEVENT"), kCalendarEvent);
}

TEST(AddBarcodePayload, Url) {
  const EncodableMap url = Map(Parse("https://example.com/a?b=c"), "url");
  EXPECT_EQ(String(url, "url"), "https://example.com/a?b=c");
  EXPECT_TRUE(IsNull(url, "title"));
}

TEST(AddBarcodePayload, MebkmBookmarkUnescapesFields) {
  const EncodableMap url =
      Map(Parse("MEBKM:TITLE:My\\;Site;URL:https\\://example.com;;"), "url");
  EXPECT_EQ(String(url, "title"), "My;Site");
  EXPECT_EQ(String(url, "url"), "https://example.com");
}

TEST(AddBarcodePayload, Wifi) {
  const EncodableMap wifi =
      Map(Parse("WIFI:T:WPA;S:My Network;P:p\\;ss;;"), "wifi");
  EXPECT_EQ(String(wifi, "ssid"), "My Network");
  EXPECT_EQ(String(wifi, "password"), "p;ss");
  EXPECT_EQ(std::get<int32_t>(wifi.at(EncodableValue("encryptionType"))), 2);

  const EncodableMap wep = Map(Parse("WIFI:T:WEP;S:Old;P:x;;"), "wifi");
  EXPECT_EQ(std::get<int32_t>(wep.at(EncodableValue("encryptionType"))), 3);

  const EncodableMap open = Map(Parse("WIFI:T:nopass;S:Guest;;"), "wifi");
  EXPECT_EQ(std::get<int32_t>(open.at(EncodableValue("encryptionType"))), 1);
  EXPECT_TRUE(IsNull(open, "password"));
}

TEST(AddBarcodePayload, EmailDecodesQuery) {
  const EncodableMap email =
      Map(Parse("mailto:a%40b@example.com?subject=Hi%20there&body=x+y"),
          "email");
  EXPECT_EQ(String(email, "address"), "a@b@example.com");
  EXPECT_EQ(String(email, "subject"), "Hi there");
  EXPECT_EQ(String(email, "body"), "x y");
}

TEST(AddBarcodePayload, Phone) {
  EXPECT_EQ(String(Map(Parse("TEL:+31 6 1234"), "phone"), "number"),
            "+31 6 1234");
}

TEST(AddBarcodePayload, SmsBothForms) {
  const EncodableMap colon = Map(Parse("SMS:+316:Hello: world"), "sms");
  EXPECT_EQ(String(colon, "phoneNumber"), "+316");
  EXPECT_EQ(String(colon, "message"), "Hello: world");

  const EncodableMap query = Map(Parse("sms:+316?body=Yo%21"), "sms");
  EXPECT_EQ(String(query, "phoneNumber"), "+316");
  EXPECT_EQ(String(query, "message"), "Yo!");
}

TEST(AddBarcodePayload, Geo) {
  const EncodableMap geo = Map(Parse("geo:52.3676,-4.9041,10?q=x"), "geoPoint");
  EXPECT_DOUBLE_EQ(std::get<double>(geo.at(EncodableValue("latitude"))),
                   52.3676);
  EXPECT_DOUBLE_EQ(std::get<double>(geo.at(EncodableValue("longitude"))),
                   -4.9041);

  // Malformed coordinates do not produce a geo point.
  EXPECT_TRUE(IsNull(Parse("geo:abc"), "geoPoint"));
}

TEST(AddBarcodePayload, Mecard) {
  const EncodableMap contact = Map(
      Parse("MECARD:N:Doe,Jane;SOUND:doo,jein;TEL:+3161;TEL:+3162;"
            "EMAIL:jane@example.com;ADR:,,Main St 1,Amsterdam,,1011AB,NL;"
            "URL:https\\://example.com;ORG:Acme;;"),
      "contactInfo");

  const EncodableMap& name = Map(contact, "name");
  EXPECT_EQ(String(name, "first"), "Jane");
  EXPECT_EQ(String(name, "last"), "Doe");
  EXPECT_EQ(String(name, "formattedName"), "Jane Doe");
  EXPECT_EQ(String(name, "pronunciation"), "doo,jein");

  const EncodableList& phones = List(contact, "phones");
  ASSERT_EQ(phones.size(), 2u);
  EXPECT_EQ(String(std::get<EncodableMap>(phones[1]), "number"), "+3162");

  const EncodableList& emails = List(contact, "emails");
  ASSERT_EQ(emails.size(), 1u);
  EXPECT_EQ(String(std::get<EncodableMap>(emails[0]), "address"),
            "jane@example.com");

  const EncodableList& addresses = List(contact, "addresses");
  ASSERT_EQ(addresses.size(), 1u);
  EXPECT_EQ(List(std::get<EncodableMap>(addresses[0]), "addressLines"),
            (EncodableList{EncodableValue("Main St 1"),
                           EncodableValue("Amsterdam"),
                           EncodableValue("1011AB"), EncodableValue("NL")}));

  EXPECT_EQ(List(contact, "urls"),
            (EncodableList{EncodableValue("https://example.com")}));
  EXPECT_EQ(String(contact, "organization"), "Acme");
}

TEST(AddBarcodePayload, VCardAndVEventAreParsed) {
  EXPECT_EQ(String(Map(Map(Parse("BEGIN:VCARD\nFN:Jane\nEND:VCARD"),
                           "contactInfo"),
                       "name"),
                   "formattedName"),
            "Jane");
  EXPECT_EQ(String(Map(Parse("BEGIN:VEVENT\nSUMMARY:Lunch\nEND:VEVENT"),
                       "calendarEvent"),
                   "summary"),
            "Lunch");
}

TEST(AddBarcodePayload, TextHasNoPayload) {
  EXPECT_TRUE(Parse("Hello").empty());
}

}  // namespace test
}  // namespace mobile_scanner
