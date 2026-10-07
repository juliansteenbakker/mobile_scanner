#include <flutter/encodable_value.h>
#include <gtest/gtest.h>

#include <string>

#include "vcard_parser.h"

namespace mobile_scanner {
namespace test {

namespace {

using flutter::EncodableList;
using flutter::EncodableMap;
using flutter::EncodableValue;

const EncodableMap& Map(const EncodableMap& map, const char* key) {
  return std::get<EncodableMap>(map.at(EncodableValue(key)));
}

const EncodableList& List(const EncodableMap& map, const char* key) {
  return std::get<EncodableList>(map.at(EncodableValue(key)));
}

std::string String(const EncodableMap& map, const char* key) {
  return std::get<std::string>(map.at(EncodableValue(key)));
}

int32_t Int(const EncodableMap& map, const char* key) {
  return std::get<int32_t>(map.at(EncodableValue(key)));
}

bool IsNull(const EncodableMap& map, const char* key) {
  auto it = map.find(EncodableValue(key));
  return it == map.end() || it->second.IsNull();
}

}  // namespace

TEST(ParseVCard, Version3) {
  const auto contact = ParseVCard(
      "BEGIN:VCARD\r\n"
      "VERSION:3.0\r\n"
      "N:Doe;Jane;Q.;Dr.;PhD\r\n"
      "FN:Dr. Jane Q. Doe\\, PhD\r\n"
      "ORG:Acme Inc.;Research\r\n"
      "TITLE:Chief Scientist\r\n"
      "TEL;TYPE=work,voice:+31 20 123\r\n"
      "TEL;TYPE=CELL:+31 6 1234\r\n"
      "TEL;TYPE=fax:+31 20 999\r\n"
      "EMAIL;TYPE=home:jane@example.com\r\n"
      "ADR;TYPE=work:;Suite 5;Main St 1\\nBuilding B;Amsterdam;NH;1011AB;"
      "Netherlands\r\n"
      "URL:https://example.com\r\n"
      "END:VCARD\r\n");
  ASSERT_TRUE(contact);

  const EncodableMap& name = Map(*contact, "name");
  EXPECT_EQ(String(name, "formattedName"), "Dr. Jane Q. Doe, PhD");
  EXPECT_EQ(String(name, "last"), "Doe");
  EXPECT_EQ(String(name, "first"), "Jane");
  EXPECT_EQ(String(name, "middle"), "Q.");
  EXPECT_EQ(String(name, "prefix"), "Dr.");
  EXPECT_EQ(String(name, "suffix"), "PhD");

  EXPECT_EQ(String(*contact, "organization"), "Acme Inc., Research");
  EXPECT_EQ(String(*contact, "title"), "Chief Scientist");

  const EncodableList& phones = List(*contact, "phones");
  ASSERT_EQ(phones.size(), 3u);
  EXPECT_EQ(String(std::get<EncodableMap>(phones[0]), "number"), "+31 20 123");
  EXPECT_EQ(Int(std::get<EncodableMap>(phones[0]), "type"), 1);  // work
  EXPECT_EQ(Int(std::get<EncodableMap>(phones[1]), "type"), 4);  // mobile
  EXPECT_EQ(Int(std::get<EncodableMap>(phones[2]), "type"), 3);  // fax

  const EncodableList& emails = List(*contact, "emails");
  ASSERT_EQ(emails.size(), 1u);
  EXPECT_EQ(String(std::get<EncodableMap>(emails[0]), "address"),
            "jane@example.com");
  EXPECT_EQ(Int(std::get<EncodableMap>(emails[0]), "type"), 2);  // home

  const EncodableList& addresses = List(*contact, "addresses");
  ASSERT_EQ(addresses.size(), 1u);
  const auto& address = std::get<EncodableMap>(addresses[0]);
  EXPECT_EQ(Int(address, "type"), 1);  // work
  EXPECT_EQ(List(address, "addressLines"),
            (EncodableList{EncodableValue("Suite 5"), EncodableValue("Main St 1"),
                           EncodableValue("Building B"),
                           EncodableValue("Amsterdam, NH 1011AB"),
                           EncodableValue("Netherlands")}));

  EXPECT_EQ(List(*contact, "urls"),
            (EncodableList{EncodableValue("https://example.com")}));
}

TEST(ParseVCard, Version21WithQuotedPrintableAndBareTypes) {
  const auto contact = ParseVCard(
      "BEGIN:VCARD\n"
      "VERSION:2.1\n"
      "N;CHARSET=UTF-8;ENCODING=QUOTED-PRINTABLE:M=C3=BCller;J=C3=BCrgen\n"
      "FN;ENCODING=QUOTED-PRINTABLE:J=C3=BCrgen =\n"
      "M=C3=BCller\n"
      "TEL;WORK;VOICE:123\n"
      "TEL;HOME:456\n"
      "END:VCARD");
  ASSERT_TRUE(contact);

  const EncodableMap& name = Map(*contact, "name");
  EXPECT_EQ(String(name, "last"), "M\xC3\xBCller");
  EXPECT_EQ(String(name, "first"), "J\xC3\xBCrgen");
  EXPECT_EQ(String(name, "formattedName"), "J\xC3\xBCrgen M\xC3\xBCller");

  const EncodableList& phones = List(*contact, "phones");
  ASSERT_EQ(phones.size(), 2u);
  EXPECT_EQ(Int(std::get<EncodableMap>(phones[0]), "type"), 1);  // work
  EXPECT_EQ(Int(std::get<EncodableMap>(phones[1]), "type"), 2);  // home
}

TEST(ParseVCard, QuotedPrintableLatin1IsConvertedToUtf8) {
  const auto contact = ParseVCard(
      "BEGIN:VCARD\nFN;CHARSET=ISO-8859-1;QUOTED-PRINTABLE:M=FCller\n"
      "END:VCARD");
  ASSERT_TRUE(contact);
  EXPECT_EQ(String(Map(*contact, "name"), "formattedName"), "M\xC3\xBCller");
}

TEST(ParseVCard, Version4FoldedLinesGroupsAndUris) {
  const auto contact = ParseVCard(
      "BEGIN:VCARD\r\n"
      "VERSION:4.0\r\n"
      "FN:Jane\r\n"
      " Doe\r\n"
      "item1.TEL;VALUE=uri;TYPE=\"voice,cell\":tel:+31-6-1234\r\n"
      "EMAIL;PREF=1:mailto:jane@example.com\r\n"
      "X-PHONETIC-FIRST-NAME:Jein\r\n"
      "END:VCARD\r\n");
  ASSERT_TRUE(contact);

  const EncodableMap& name = Map(*contact, "name");
  EXPECT_EQ(String(name, "formattedName"), "JaneDoe");
  EXPECT_EQ(String(name, "pronunciation"), "Jein");

  const auto& phone = std::get<EncodableMap>(List(*contact, "phones")[0]);
  EXPECT_EQ(String(phone, "number"), "+31-6-1234");
  EXPECT_EQ(Int(phone, "type"), 4);  // mobile

  const auto& email = std::get<EncodableMap>(List(*contact, "emails")[0]);
  EXPECT_EQ(String(email, "address"), "jane@example.com");
  EXPECT_EQ(Int(email, "type"), 0);  // unknown
}

TEST(ParseVCard, EmptyCardHasEmptyLists) {
  const auto contact = ParseVCard("BEGIN:VCARD\nEND:VCARD");
  ASSERT_TRUE(contact);
  EXPECT_TRUE(IsNull(*contact, "name"));
  EXPECT_TRUE(IsNull(*contact, "organization"));
  EXPECT_TRUE(List(*contact, "phones").empty());
  EXPECT_TRUE(List(*contact, "emails").empty());
  EXPECT_TRUE(List(*contact, "addresses").empty());
  EXPECT_TRUE(List(*contact, "urls").empty());
}

TEST(ParseVEvent, InsideVCalendar) {
  const auto event = ParseVEvent(
      "BEGIN:VCALENDAR\r\n"
      "VERSION:2.0\r\n"
      "BEGIN:VEVENT\r\n"
      "SUMMARY:Team lunch\\, Friday\r\n"
      "DESCRIPTION:Line one\\nLine two\r\n"
      "LOCATION:Cafe\\; Main St\r\n"
      "ORGANIZER;CN=\"Doe: Jane\":mailto:jane@example.com\r\n"
      "STATUS:CONFIRMED\r\n"
      "DTSTART:20261007T120000Z\r\n"
      "DTEND;TZID=Europe/Amsterdam:20261007T140000\r\n"
      "BEGIN:VALARM\r\n"
      "DESCRIPTION:Reminder\r\n"
      "END:VALARM\r\n"
      "END:VEVENT\r\n"
      "END:VCALENDAR\r\n");
  ASSERT_TRUE(event);
  EXPECT_EQ(String(*event, "summary"), "Team lunch, Friday");
  // The VALARM description must not replace the event's.
  EXPECT_EQ(String(*event, "description"), "Line one\nLine two");
  EXPECT_EQ(String(*event, "location"), "Cafe; Main St");
  EXPECT_EQ(String(*event, "organizer"), "jane@example.com");
  EXPECT_EQ(String(*event, "status"), "CONFIRMED");
  EXPECT_EQ(String(*event, "start"), "20261007T120000Z");
  EXPECT_EQ(String(*event, "end"), "20261007T140000");
}

TEST(ParseVEvent, BareEventWithAllDayDates) {
  const auto event = ParseVEvent(
      "BEGIN:VEVENT\nSUMMARY:Holiday\nDTSTART;VALUE=DATE:20261224\n"
      "DTEND;VALUE=DATE:20261227\nEND:VEVENT");
  ASSERT_TRUE(event);
  EXPECT_EQ(String(*event, "summary"), "Holiday");
  EXPECT_EQ(String(*event, "start"), "20261224");
  EXPECT_EQ(String(*event, "end"), "20261227");
  EXPECT_TRUE(IsNull(*event, "location"));
}

TEST(ParseVEvent, NoEventReturnsNothing) {
  EXPECT_FALSE(ParseVEvent("BEGIN:VCALENDAR\nVERSION:2.0\nEND:VCALENDAR"));
}

}  // namespace test
}  // namespace mobile_scanner
