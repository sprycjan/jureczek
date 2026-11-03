import 'package:flutter_test/flutter_test.dart';
import 'package:jureczek/features/map/domain/poi_place.dart';
import 'package:jureczek/features/places/domain/maki_place_type.dart';
import 'package:jureczek/features/places/domain/place_type.dart';

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

  test('maki POI podpowiada typ pinezki (v16)', () {
    PlaceType? typeOf(Object? maki) => placeFromPoi(
      name: 'x',
      geometry: {
        'coordinates': [19, 52],
      },
      maki: maki,
    )?.suggestedType;

    expect(typeOf('restaurant'), PlaceType.restaurant);
    expect(typeOf('religious-christian'), PlaceType.church);
    expect(typeOf('park'), PlaceType.natureOther);
    expect(typeOf('marker'), isNull);
    expect(typeOf(null), isNull);
    expect(typeOf(7), isNull);
  });

  test('mapowanie maki nie gubi typów, ich kategoria się zgadza', () {
    expect(placeTypeFromMaki('cafe')?.key, 'cafe');
    expect(placeTypeFromMaki('ice-cream'), PlaceType.iceCreamShop);
    expect(placeTypeFromMaki('charging-station'), PlaceType.evCharging);
    expect(placeTypeFromMaki('stadium'), PlaceType.entertainmentOther);
  });
}
