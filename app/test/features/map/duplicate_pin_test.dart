import 'package:flutter_test/flutter_test.dart';
import 'package:jureczek/features/map/domain/duplicate_pin.dart';
import 'package:jureczek/features/map/domain/place_pin.dart';

void main() {
  PlacePin pin(String id, double lat, double lng) =>
      PlacePin(id: id, lat: lat, lng: lng, createdAt: DateTime(2026));

  group('duplicateThresholdMeters', () {
    test('przy zoomie 15 obcięty do 30 m', () {
      expect(duplicateThresholdMeters(54.38, 15), maxDuplicateMeters);
    });

    test('przy większym zoomie maleje: ~8 m przy 17, ~2 m przy 19', () {
      expect(duplicateThresholdMeters(54.38, 17), closeTo(8.4, 0.3));
      expect(duplicateThresholdMeters(54.38, 19), closeTo(2.1, 0.1));
    });
  });

  test('distanceMeters: 0,001° szerokości to ~111 m', () {
    expect(
      distanceMeters((lat: 54.0, lng: 18.0), (lat: 54.001, lng: 18.0)),
      closeTo(111.2, 0.5),
    );
  });

  group('nearestPinWithin', () {
    final pins = [
      pin('daleko', 54.3810, 18.6030),
      pin('blisko', 54.38012, 18.6030),
      pin('najbliżej', 54.38005, 18.6030),
    ];

    test('wybiera najbliższą w progu', () {
      expect(
        nearestPinWithin(pins, (lat: 54.3800, lng: 18.6030), 30)?.id,
        'najbliżej',
      );
    });

    test('nic w progu to null', () {
      expect(nearestPinWithin(pins, (lat: 54.3700, lng: 18.6030), 30), isNull);
    });
  });
}
