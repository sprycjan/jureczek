import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:jureczek/features/map/data/place_search_client.dart';
import 'package:jureczek/features/map/domain/place_suggestion.dart';

void main() {
  late Uri lastRequest;

  PlaceSearchClient client(int status, Object body) {
    return PlaceSearchClient(
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
  }

  const wawel = PlaceSuggestion(
    mapboxId: 'dXJu',
    name: 'Wawel',
    address: 'Wawel 5, 31-001 Kraków, Polska',
  );

  group('suggest', () {
    test('wysyła token, sesję, język, limit i proximity', () async {
      await client(200, {'suggestions': []}).suggest(
        'Waw',
        sessionToken: 'sesja-1',
        proximity: (lat: 50.06, lng: 19.94),
      );

      expect(lastRequest.host, 'api.mapbox.com');
      expect(lastRequest.path, '/search/searchbox/v1/suggest');
      expect(lastRequest.queryParameters, {
        'q': 'Waw',
        'session_token': 'sesja-1',
        'language': 'pl',
        'limit': '6',
        'proximity': '19.94,50.06',
        'access_token': 'pk.test',
      });
    });

    test('bez proximity nie wysyła tego parametru', () async {
      await client(200, {'suggestions': []}).suggest('Waw', sessionToken: 's');

      expect(lastRequest.queryParameters, isNot(contains('proximity')));
      expect(lastRequest.queryParameters, isNot(contains('country')));
    });

    test('country zawęża wyniki do kraju', () async {
      await client(200, {
        'suggestions': [],
      }).suggest('Miradouro dos Balcões', sessionToken: 's', country: 'pt');

      expect(lastRequest.queryParameters['country'], 'pt');
    });

    test('parsuje nazwę i adres, z place_formatted jako zapasem', () async {
      final suggestions = await client(200, {
        'suggestions': [
          {
            'mapbox_id': 'a',
            'name': 'Wawel',
            'full_address': 'Wawel 5, Kraków',
            'place_formatted': 'Kraków',
          },
          {'mapbox_id': 'b', 'name': 'Warszawa', 'place_formatted': 'Polska'},
          {'mapbox_id': 'c', 'name': 'Bez adresu', 'full_address': ''},
        ],
      }).suggest('Wa', sessionToken: 's');

      expect(suggestions.map((s) => s.mapboxId), ['a', 'b', 'c']);
      expect(suggestions.map((s) => s.address), [
        'Wawel 5, Kraków',
        'Polska',
        null,
      ]);
    });

    test('błąd HTTP to PlaceSearchException', () {
      expect(
        client(401, {
          'message': 'Not Authorized',
        }).suggest('Waw', sessionToken: 's'),
        throwsA(isA<PlaceSearchException>()),
      );
    });

    test('błąd sieci to PlaceSearchException', () {
      final failing = PlaceSearchClient(
        MockClient((r) => throw http.ClientException('offline', r.url)),
        'pk.test',
      );

      expect(
        failing.suggest('Waw', sessionToken: 's'),
        throwsA(
          isA<PlaceSearchException>().having(
            (e) => e.message,
            'message',
            isNot(contains('pk.test')),
          ),
        ),
      );
    });
  });

  group('retrieve', () {
    test('woła retrieve z id i sesją, zwraca współrzędne [lng, lat]', () async {
      final result = await client(200, {
        'type': 'FeatureCollection',
        'features': [
          {
            'type': 'Feature',
            'geometry': {
              'type': 'Point',
              'coordinates': [19.9354, 50.0541],
            },
            'properties': {'name': 'Wawel'},
          },
        ],
      }).retrieve(wawel, sessionToken: 'sesja-1');

      expect(lastRequest.path, '/search/searchbox/v1/retrieve/dXJu');
      expect(lastRequest.queryParameters['session_token'], 'sesja-1');
      expect(result.name, 'Wawel');
      expect(result.address, wawel.address);
      expect(result.lat, 50.0541);
      expect(result.lng, 19.9354);
    });

    test('pusta odpowiedź to PlaceSearchException', () {
      expect(
        client(200, {'features': []}).retrieve(wawel, sessionToken: 's'),
        throwsA(isA<PlaceSearchException>()),
      );
    });
  });
}
