import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_scanner/src/objects/calendar_event.dart';

void main() {
  group('$CalendarEvent tests', () {
    group('constructor', () {
      test('creates instance with default null values', () {
        const event = CalendarEvent();

        expect(event.description, isNull);
        expect(event.start, isNull);
        expect(event.end, isNull);
        expect(event.location, isNull);
        expect(event.organizer, isNull);
        expect(event.status, isNull);
        expect(event.summary, isNull);
      });

      test('creates instance with all values provided', () {
        final start = DateTime(2024, 1, 15, 10);
        final end = DateTime(2024, 1, 15, 11);

        final event = CalendarEvent(
          description: 'Team meeting',
          start: start,
          end: end,
          location: 'Conference Room A',
          organizer: 'john@example.com',
          status: 'CONFIRMED',
          summary: 'Weekly standup',
        );

        expect(event.description, 'Team meeting');
        expect(event.start, start);
        expect(event.end, end);
        expect(event.location, 'Conference Room A');
        expect(event.organizer, 'john@example.com');
        expect(event.status, 'CONFIRMED');
        expect(event.summary, 'Weekly standup');
      });
    });

    group('fromNative', () {
      test('creates instance with all null values', () {
        final event = CalendarEvent.fromNative(<Object?, Object?>{});

        expect(event.description, isNull);
        expect(event.start, isNull);
        expect(event.end, isNull);
        expect(event.location, isNull);
        expect(event.organizer, isNull);
        expect(event.status, isNull);
        expect(event.summary, isNull);
      });

      test('creates instance with all values provided', () {
        final event = CalendarEvent.fromNative(<Object?, Object?>{
          'description': 'Team meeting',
          'start': '2024-01-15T10:00:00',
          'end': '2024-01-15T11:00:00',
          'location': 'Conference Room A',
          'organizer': 'john@example.com',
          'status': 'CONFIRMED',
          'summary': 'Weekly standup',
        });

        expect(event.description, 'Team meeting');
        expect(event.start, DateTime(2024, 1, 15, 10));
        expect(event.end, DateTime(2024, 1, 15, 11));
        expect(event.location, 'Conference Room A');
        expect(event.organizer, 'john@example.com');
        expect(event.status, 'CONFIRMED');
        expect(event.summary, 'Weekly standup');
      });

      test('creates instance with invalid start date', () {
        final event = CalendarEvent.fromNative(<Object?, Object?>{
          'start': 'invalid-date',
        });

        expect(event.start, isNull);
      });

      test('creates instance with invalid end date', () {
        final event = CalendarEvent.fromNative(<Object?, Object?>{
          'end': 'not-a-date',
        });

        expect(event.end, isNull);
      });

      test('creates instance with empty string dates', () {
        final event = CalendarEvent.fromNative(<Object?, Object?>{
          'start': '',
          'end': '',
        });

        expect(event.start, isNull);
        expect(event.end, isNull);
      });

      test('creates instance with null string values', () {
        final event = CalendarEvent.fromNative(<Object?, Object?>{
          'description': null,
          'start': null,
          'end': null,
          'location': null,
          'organizer': null,
          'status': null,
          'summary': null,
        });

        expect(event.description, isNull);
        expect(event.start, isNull);
        expect(event.end, isNull);
        expect(event.location, isNull);
        expect(event.organizer, isNull);
        expect(event.status, isNull);
        expect(event.summary, isNull);
      });

      test('creates instance with date including timezone', () {
        final event = CalendarEvent.fromNative(<Object?, Object?>{
          'start': '2024-01-15T10:00:00Z',
          'end': '2024-01-15T11:00:00Z',
        });

        expect(event.start, DateTime.utc(2024, 1, 15, 10));
        expect(event.end, DateTime.utc(2024, 1, 15, 11));
      });

      test('creates instance with date only (no time)', () {
        final event = CalendarEvent.fromNative(<Object?, Object?>{
          'start': '2024-01-15',
        });

        expect(event.start, DateTime(2024, 1, 15));
      });

      test('creates instance with special characters in text fields', () {
        final event = CalendarEvent.fromNative(<Object?, Object?>{
          'description': 'Meeting & Discussion: Q1 Goals',
          'location': 'Room #42 (2nd Floor)',
          'organizer': 'john.doe@example.com',
          'summary': 'Team Meeting - "Quarterly Review"',
        });

        expect(event.description, 'Meeting & Discussion: Q1 Goals');
        expect(event.location, 'Room #42 (2nd Floor)');
        expect(event.organizer, 'john.doe@example.com');
        expect(event.summary, 'Team Meeting - "Quarterly Review"');
      });

      test('creates instance with Unicode characters', () {
        final event = CalendarEvent.fromNative(<Object?, Object?>{
          'description': '会議の説明',
          'location': 'Büro München',
          'summary': "Réunion d'équipe",
        });

        expect(event.description, '会議の説明');
        expect(event.location, 'Büro München');
        expect(event.summary, "Réunion d'équipe");
      });

      test('creates instance with very long description', () {
        final longDescription = 'A' * 5000;
        final event = CalendarEvent.fromNative(<Object?, Object?>{
          'description': longDescription,
        });

        expect(event.description?.length, 5000);
      });

      test('handles partial date string gracefully', () {
        final event = CalendarEvent.fromNative(<Object?, Object?>{
          'start': '2024-01',
        });

        expect(event.start, isNull);
      });
    });
  });
}
