import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_scanner/src/objects/url_bookmark.dart';

void main() {
  group('$UrlBookmark tests', () {
    group('constructor', () {
      test('creates instance with required url', () {
        const bookmark = UrlBookmark(url: 'https://example.com');

        expect(bookmark.url, 'https://example.com');
        expect(bookmark.title, isNull);
      });

      test('creates instance with url and title', () {
        const bookmark = UrlBookmark(
          url: 'https://example.com',
          title: 'Example Website',
        );

        expect(bookmark.url, 'https://example.com');
        expect(bookmark.title, 'Example Website');
      });

      test('creates instance with empty url', () {
        const bookmark = UrlBookmark(url: '');

        expect(bookmark.url, '');
        expect(bookmark.title, isNull);
      });
    });

    group('fromNative', () {
      test('creates instance with empty map', () {
        final bookmark = UrlBookmark.fromNative(<Object?, Object?>{});

        expect(bookmark.url, '');
        expect(bookmark.title, isNull);
      });

      test('creates instance with all values', () {
        final bookmark = UrlBookmark.fromNative(<Object?, Object?>{
          'url': 'https://example.com',
          'title': 'Example Website',
        });

        expect(bookmark.url, 'https://example.com');
        expect(bookmark.title, 'Example Website');
      });

      test('creates instance with null url defaults to empty string', () {
        final bookmark = UrlBookmark.fromNative(<Object?, Object?>{
          'url': null,
          'title': 'Example Website',
        });

        expect(bookmark.url, '');
        expect(bookmark.title, 'Example Website');
      });

      test('creates instance with null title', () {
        final bookmark = UrlBookmark.fromNative(<Object?, Object?>{
          'url': 'https://example.com',
          'title': null,
        });

        expect(bookmark.url, 'https://example.com');
        expect(bookmark.title, isNull);
      });

      test('creates instance with missing url defaults to empty', () {
        final bookmark = UrlBookmark.fromNative(<Object?, Object?>{
          'title': 'Example Website',
        });

        expect(bookmark.url, '');
        expect(bookmark.title, 'Example Website');
      });
    });
  });
}
