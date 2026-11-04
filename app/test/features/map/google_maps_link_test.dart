import 'package:flutter_test/flutter_test.dart';
import 'package:jureczek/features/map/domain/google_maps_link.dart';
import 'package:jureczek/features/map/domain/place_pin.dart';

void main() {
  const coordinates =
      'https://www.google.com/maps/search/?api=1&query=50.0628,19.9377';

  PlacePin pin({
    String? name,
    String? address,
    String? sourceUrl,
    String? poiName,
  }) => PlacePin(
    id: 'a',
    folderId: 'f',
    lat: 50.0628,
    lng: 19.9377,
    createdAt: DateTime(2026, 11, 4),
    name: name,
    address: address,
    sourceUrl: sourceUrl,
    poiName: poiName,
  );

  test('link Google ma pierwszeństwo przed POI', () {
    final uri = googleMapsUri(
      pin(
        sourceUrl: 'https://maps.app.goo.gl/abc',
        poiName: 'Wawel',
        address: 'Wawel 5, Kraków',
      ),
    );

    expect(uri.toString(), 'https://maps.app.goo.gl/abc');
  });

  test('POI szuka nazwy z adresem w okolicy pinezki', () {
    final uri = googleMapsUri(
      pin(poiName: 'Wawel', address: 'Wawel 5, Kraków'),
    );

    expect(uri.pathSegments[2], 'Wawel, Wawel 5, Kraków');
    expect(uri.pathSegments[3], '@50.0628,19.9377,17z');
  });

  test('zakodowana nazwa POI nie psuje adresu', () {
    final uri = googleMapsUri(
      pin(poiName: 'Zażółć & gęś/1 ?#', address: 'Rynek 1'),
    );

    expect(uri.pathSegments[2], 'Zażółć & gęś/1 ?#, Rynek 1');
    expect(uri.pathSegments[3], '@50.0628,19.9377,17z');
    expect(uri.hasQuery, isFalse);
    expect(uri.hasFragment, isFalse);
  });

  test('po zmianie nazwy pinezki szuka oryginalnej nazwy POI', () {
    final uri = googleMapsUri(
      pin(
        name: 'Obiad',
        poiName: 'Café Camelot',
        address: 'Świętego Tomasza 17',
      ),
    );

    expect(uri.pathSegments[2], 'Café Camelot, Świętego Tomasza 17');
  });

  test('POI bez adresu otwiera współrzędne, nie samą nazwę', () {
    expect(googleMapsUri(pin(poiName: 'Wawel')).toString(), coordinates);
  });

  test('pinezka spoza POI otwiera współrzędne, nawet z nazwą i adresem', () {
    expect(googleMapsUri(pin()).toString(), coordinates);
    expect(
      googleMapsUri(pin(name: 'Parking', address: 'Rynek 1')).toString(),
      coordinates,
    );
  });

  test('błędny link źródłowy przechodzi do kolejnego wariantu', () {
    for (final broken in ['bez schematu', 'http://[', 'ftp://example.com']) {
      expect(
        googleMapsUri(
          pin(sourceUrl: broken, poiName: 'Wawel', address: 'Wawel 5'),
        ).pathSegments[2],
        'Wawel, Wawel 5',
        reason: broken,
      );
    }
  });
}
