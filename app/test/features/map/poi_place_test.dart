import 'package:flutter_test/flutter_test.dart';
import 'package:jureczek/features/map/domain/poi_place.dart';

void main() {
  test('czyta nazwę i współrzędne [lng, lat] z GeoJSON-a', () {
    final place = placeFromPoi(
      name: 'Miradouro do Pico da Caldeira',
      geometry: {
        'type': 'Point',
        'coordinates': [-16.8833, 32.8065],
      },
    );

    expect(place?.name, 'Miradouro do Pico da Caldeira');
    expect(place?.lat, 32.8065);
    expect(place?.lng, -16.8833);
    expect(place?.approximate, isFalse);
  });

  test('POI bez nazwy też jest miejscem', () {
    final place = placeFromPoi(
      name: null,
      geometry: {
        'coordinates': [19, 52],
      },
    );

    expect(place?.name, isNull);
    expect(place?.lat, 52.0);
    expect(place?.lng, 19.0);
  });

  test('brak lub zła geometria to null', () {
    expect(placeFromPoi(name: 'x', geometry: {}), isNull);
    expect(
      placeFromPoi(
        name: 'x',
        geometry: {
          'coordinates': [1],
        },
      ),
      isNull,
    );
    expect(
      placeFromPoi(
        name: 'x',
        geometry: {
          'coordinates': ['a', 'b'],
        },
      ),
      isNull,
    );
  });
}
