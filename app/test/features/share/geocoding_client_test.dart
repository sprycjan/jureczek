import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:jureczek/features/share/data/geocoding_client.dart';

void main() {
  late Uri lastRequest;

  GeocodingClient client(int status, Object body) => GeocodingClient(
    MockClient((request) async {
      lastRequest = request.url;
      return http.Response(
        jsonEncode(body),
        status,
        headers: {'content-type': 'application/json; charset=utf-8'},
      );
    }),
    'pk.test',
  );

  const kilinskiego = {
    'features': [
      {
        'geometry': {
          'coordinates': [18.6052, 54.3825],
        },
        'properties': {
          'feature_type': 'address',
          'name': 'Jana Kilińskiego 4',
          'full_address': 'Jana Kilińskiego 4, 80-452 Gdańsk, Polska',
        },
      },
    ],
  };

  test('forward wysyła zapytanie i parsuje pierwszy wynik', () async {
    final place = await client(200, kilinskiego).forward('Jana Kilińskiego 4');

    expect(lastRequest.path, '/search/geocode/v6/forward');
    expect(lastRequest.queryParameters, {
      'q': 'Jana Kilińskiego 4',
      'language': 'pl',
      'limit': '1',
      'access_token': 'pk.test',
    });
    expect(place?.point, (lat: 54.3825, lng: 18.6052));
    expect(place?.featureType, 'address');
    expect(place?.name, 'Jana Kilińskiego 4');
    expect(place?.fullAddress, 'Jana Kilińskiego 4, 80-452 Gdańsk, Polska');
  });

  test('parsuje kod kraju i zasięg obszaru', () async {
    final place = await client(200, {
      'features': [
        {
          'geometry': {
            'coordinates': [-8.562731, 39.600995],
          },
          'properties': {
            'feature_type': 'country',
            'name': 'Portugalia',
            'bbox': [-31.334986, 29.961324, -6.189178, 42.154227],
            'context': {
              'country': {'name': 'Portugalia', 'country_code': 'PT'},
            },
          },
        },
      ],
    }).forward('Portugalia');

    expect(place?.countryCode, 'pt');
    expect(place?.bbox, (
      minLng: -31.334986,
      minLat: 29.961324,
      maxLng: -6.189178,
      maxLat: 42.154227,
    ));
    // Madera leży w zasięgu Portugalii, Kraków nie.
    expect(place!.bbox!.contains((lat: 32.74, lng: -16.89)), isTrue);
    expect(place.bbox!.contains((lat: 50.06, lng: 19.94)), isFalse);
  });

  test('bez kontekstu i bbox pola są puste', () async {
    final place = await client(200, kilinskiego).forward('Jana Kilińskiego 4');

    expect(place?.countryCode, isNull);
    expect(place?.bbox, isNull);
  });

  test('reverse wysyła lng i lat osobno, tylko adresy', () async {
    await client(200, kilinskiego).reverse((lat: 54.3825, lng: 18.6052));

    expect(lastRequest.path, '/search/geocode/v6/reverse');
    expect(lastRequest.queryParameters['longitude'], '18.6052');
    expect(lastRequest.queryParameters['latitude'], '54.3825');
    expect(lastRequest.queryParameters['types'], 'address');
  });

  test('brak wyników to null', () async {
    expect(await client(200, {'features': []}).forward('xyz'), isNull);
  });

  test('błąd HTTP rzuca GeocodingException bez tokenu', () {
    expect(
      client(401, {}).forward('x'),
      throwsA(
        isA<GeocodingException>().having(
          (e) => e.message,
          'message',
          isNot(contains('pk.test')),
        ),
      ),
    );
  });
}
