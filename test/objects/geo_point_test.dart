import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_scanner/src/objects/geo_point.dart';

void main() {
  group('$GeoPoint tests', () {
    group('constructor', () {
      test('creates instance with required values', () {
        const geoPoint = GeoPoint(latitude: 37.7749, longitude: -122.4194);

        expect(geoPoint.latitude, 37.7749);
        expect(geoPoint.longitude, -122.4194);
      });

      test('creates instance with zero values', () {
        const geoPoint = GeoPoint(latitude: 0, longitude: 0);

        expect(geoPoint.latitude, 0);
        expect(geoPoint.longitude, 0);
      });

      test('creates instance with negative values', () {
        const geoPoint = GeoPoint(latitude: -33.8688, longitude: -151.2093);

        expect(geoPoint.latitude, -33.8688);
        expect(geoPoint.longitude, -151.2093);
      });
    });

    group('fromNative', () {
      test('creates instance with valid coordinates', () {
        final geoPoint = GeoPoint.fromNative(<Object?, Object?>{
          'latitude': 37.7749,
          'longitude': -122.4194,
        });

        expect(geoPoint.latitude, 37.7749);
        expect(geoPoint.longitude, -122.4194);
      });

      test('returns fallback when latitude is null', () {
        final geoPoint = GeoPoint.fromNative(<Object?, Object?>{
          'latitude': null,
          'longitude': -122.4194,
        });

        expect(geoPoint.latitude, 0);
        expect(geoPoint.longitude, 0);
      });

      test('returns fallback when longitude is null', () {
        final geoPoint = GeoPoint.fromNative(<Object?, Object?>{
          'latitude': 37.7749,
          'longitude': null,
        });

        expect(geoPoint.latitude, 0);
        expect(geoPoint.longitude, 0);
      });

      test('returns fallback when both are null', () {
        final geoPoint = GeoPoint.fromNative(<Object?, Object?>{
          'latitude': null,
          'longitude': null,
        });

        expect(geoPoint.latitude, 0);
        expect(geoPoint.longitude, 0);
      });

      test('returns fallback with empty map', () {
        final geoPoint = GeoPoint.fromNative(<Object?, Object?>{});

        expect(geoPoint.latitude, 0);
        expect(geoPoint.longitude, 0);
      });

      test('creates instance with extreme values', () {
        final geoPoint = GeoPoint.fromNative(<Object?, Object?>{
          'latitude': 90.0,
          'longitude': 180.0,
        });

        expect(geoPoint.latitude, 90.0);
        expect(geoPoint.longitude, 180.0);
      });

      test('creates instance with negative extreme values', () {
        final geoPoint = GeoPoint.fromNative(<Object?, Object?>{
          'latitude': -90.0,
          'longitude': -180.0,
        });

        expect(geoPoint.latitude, -90.0);
        expect(geoPoint.longitude, -180.0);
      });
    });
  });
}
