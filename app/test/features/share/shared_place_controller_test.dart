import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jureczek/features/map/data/place_search_client.dart';
import 'package:jureczek/features/map/domain/place_suggestion.dart';
import 'package:jureczek/features/share/application/shared_place_controller.dart';
import 'package:jureczek/features/share/data/geocoding_client.dart';
import 'package:jureczek/features/share/data/google_link_resolver.dart';
import 'package:jureczek/features/share/data/share_channel.dart';
import 'package:jureczek/features/share/domain/shared_place.dart';

class _FakeChannel implements ShareChannel {
  SharedText? initial;
  final controller = StreamController<SharedText>.broadcast();

  @override
  Stream<SharedText> get shares => controller.stream;

  @override
  Future<SharedText?> initialShare() async => initial;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeResolver implements GoogleLinkResolver {
  final redirects = <String, String>{};
  Completer<void>? gate;

  @override
  Future<String> resolve(String shortUrl) async {
    await gate?.future;
    final target = redirects[shortUrl];
    if (target == null) throw const GoogleLinkException('HTTP 404');
    return target;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeGeocoding implements GeocodingClient {
  final forwardResults = <String, GeocodedPlace>{};
  GeocodedPlace? reverseResult;
  final calls = <String>[];

  @override
  Future<GeocodedPlace?> forward(String query) async {
    calls.add('forward $query');
    return forwardResults[query];
  }

  @override
  Future<GeocodedPlace?> reverse(LatLng point) async {
    calls.add('reverse');
    return reverseResult;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeSearch implements PlaceSearchClient {
  List<PlaceSuggestion> suggestions = const [];
  LatLng retrievePoint = (lat: 0, lng: 0);
  final queries = <(String, LatLng?)>[];
  final countries = <String?>[];

  @override
  Future<List<PlaceSuggestion>> suggest(
    String query, {
    required String sessionToken,
    LatLng? proximity,
    String? country,
  }) async {
    queries.add((query, proximity));
    countries.add(country);
    return suggestions;
  }

  @override
  Future<PlaceResult> retrieve(
    PlaceSuggestion suggestion, {
    required String sessionToken,
  }) async => PlaceResult(
    name: suggestion.name,
    lat: retrievePoint.lat,
    lng: retrievePoint.lng,
  );

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late _FakeChannel channel;
  late _FakeResolver resolver;
  late _FakeGeocoding geocoding;
  late _FakeSearch search;
  late ProviderContainer container;

  const parkLink = 'https://maps.app.goo.gl/park';
  const mallLink = 'https://maps.app.goo.gl/mall';
  const pinLink = 'https://maps.app.goo.gl/pin';
  const balcoesLink = 'https://maps.app.goo.gl/balcoes';
  const balcoesPlusCodeLink = 'https://maps.app.goo.gl/balcoes-kod';
  // Ulica z geokodowania „Ribeiro Frio, Portugalia”, ~12 km od Balcões.
  const ribeiroFrio = GeocodedPlace(
    point: (lat: 32.70346, lng: -17.020455),
    featureType: 'street',
    countryCode: 'pt',
  );
  const gdansk = (lat: 54.35, lng: 18.65);
  const balcoes = (lat: 32.7415548, lng: -16.8902850);
  const portugal = GeocodedPlace(
    point: (lat: 39.600995, lng: -8.562731),
    featureType: 'country',
    countryCode: 'pt',
    bbox: (
      minLng: -31.334986,
      minLat: 29.961324,
      maxLng: -6.189178,
      maxLat: 42.154227,
    ),
  );
  const balcoesPoi = PlaceSuggestion(
    mapboxId: 'b',
    name: 'Miradouro dos Balcões',
    featureType: 'poi',
  );

  setUp(() {
    channel = _FakeChannel();
    resolver = _FakeResolver()
      ..redirects.addAll({
        parkLink:
            'https://www.google.com/maps/place/Park+Ja%C5%9Bkowej+Doliny,+Gda%C5%84sk/data=!4m2!3m1!1s0x1:0x2',
        mallLink:
            'https://www.google.com/maps/place/Galeria+Metropolia,+Jana+Kili%C5%84skiego+4,+80-452+Gda%C5%84sk/data=!4m2!3m1!1s0x1:0x2',
        pinLink:
            'https://www.google.com/maps/place/Klonowa+01,+80-264+Gda%C5%84sk/data=!8m2!3d54.3799662!4d18.6029747',
        balcoesLink:
            'https://www.google.com/maps/place/Miradouro+dos+Balc%C3%B5es,+Portugalia/data=!4m2!3m1!1s0xc6067be7149a0a1:0xe1a2be98d1fa9c7d!18m1!1e1?utm_source=mstt_1&entry=gps',
        balcoesPlusCodeLink:
            'https://www.google.com/maps/place/P4R5%2BJV+Miradouro+dos+Balc%C3%B5es,+Ribeiro+Frio,+Portugalia/data=!4m2!3m1!1s0xc6067be7149a0a1:0xe1a2be98d1fa9c7d!18m1!1e1?utm_source=mstt_1&entry=gps',
      });
    geocoding = _FakeGeocoding();
    search = _FakeSearch();
  });
  tearDown(() => container.dispose());

  void start() {
    container = ProviderContainer(
      overrides: [
        shareChannelProvider.overrideWithValue(channel),
        googleLinkResolverProvider.overrideWithValue(resolver),
        geocodingClientProvider.overrideWithValue(geocoding),
        placeSearchClientProvider.overrideWithValue(search),
      ],
    );
    container.listen(sharedPlaceControllerProvider, (_, _) {});
  }

  SharedPlaceController controller() =>
      container.read(sharedPlaceControllerProvider.notifier);
  SharedPlaceState state() => container.read(sharedPlaceControllerProvider);
  PlaceResult place() => (state() as SharedPlaceReady).place;

  test(
    'upuszczona pinezka: dokładne współrzędne, nazwa i adres z linku',
    () async {
      start();
      await controller().handle((text: pinLink, subject: 'Klonowa 01'));

      expect(place().lat, 54.3799662);
      expect(place().lng, 18.6029747);
      expect(place().name, 'Klonowa 01');
      expect(place().address, 'Klonowa 01, 80-264 Gdańsk');
      expect(place().sourceUrl, pinLink);
      expect(place().approximate, isFalse);
      expect(geocoding.calls, isEmpty);
    },
  );

  test('POI z adresem: położenie z geokodowania adresu, przybliżone', () async {
    geocoding.forwardResults['Jana Kilińskiego 4, 80-452 Gdańsk'] =
        const GeocodedPlace(
          point: (lat: 54.3825, lng: 18.6052),
          featureType: 'address',
        );
    start();
    await controller().handle((text: mallLink, subject: 'Galeria Metropolia'));

    expect(place().lat, 54.3825);
    expect(place().name, 'Galeria Metropolia');
    expect(place().address, 'Jana Kilińskiego 4, 80-452 Gdańsk');
    expect(place().approximate, isTrue);
    expect(search.queries, isEmpty);
  });

  test(
    'POI z samą miejscowością: Search Box szuka POI w jej okolicy',
    () async {
      geocoding.forwardResults['Gdańsk'] = const GeocodedPlace(
        point: gdansk,
        featureType: 'place',
      );
      search
        ..suggestions = const [
          PlaceSuggestion(
            mapboxId: 's',
            name: 'Jaśkowa Dolina',
            featureType: 'street',
          ),
          PlaceSuggestion(mapboxId: 'p', name: 'Park', featureType: 'poi'),
        ]
        ..retrievePoint = (lat: 54.3724, lng: 18.5926);
      start();
      await controller().handle((
        text: parkLink,
        subject: 'Park Jaśkowej Doliny',
      ));

      expect(search.queries.single, ('Park Jaśkowej Doliny', gdansk));
      expect(place().lat, 54.3724);
      expect(place().name, 'Park Jaśkowej Doliny');
      expect(place().approximate, isTrue);
    },
  );

  test(
    'POI daleko od miasta jest pomijane – zamiast środka miasta NeedsSearch',
    () async {
      geocoding.forwardResults['Gdańsk'] = const GeocodedPlace(
        point: gdansk,
        featureType: 'place',
      );
      search
        ..suggestions = const [
          PlaceSuggestion(mapboxId: 'p', name: 'Park', featureType: 'poi'),
        ]
        ..retrievePoint = (lat: 50.06, lng: 19.94);
      start();
      await controller().handle((
        text: parkLink,
        subject: 'Park Jaśkowej Doliny',
      ));

      expect((state() as SharedPlaceNeedsSearch).name, 'Park Jaśkowej Doliny');
    },
  );

  test('brak POI w mniejszej miejscowości: zostaje jej środek', () async {
    geocoding.forwardResults['Gdańsk'] = const GeocodedPlace(
      point: gdansk,
      featureType: 'locality',
    );
    start();
    await controller().handle((
      text: parkLink,
      subject: 'Park Jaśkowej Doliny',
    ));

    expect(place().lat, gdansk.lat);
    expect(place().approximate, isTrue);
  });

  test(
    'pełny link /search/ bez adresu: reverse geocoding uzupełnia nazwę i adres',
    () async {
      geocoding.reverseResult = const GeocodedPlace(
        point: (lat: 54.3686, lng: 18.5713),
        featureType: 'address',
        name: 'Klonowa 1',
        fullAddress: 'Klonowa 1, 80-264 Gdańsk, Polska',
      );
      start();
      await controller().handle((
        text:
            'https://www.google.com/maps/search/54.368639,+18.571369?entry=tts',
        subject: null,
      ));

      expect(place().lat, 54.368639);
      expect(place().name, 'Klonowa 1');
      expect(place().address, 'Klonowa 1, 80-264 Gdańsk, Polska');
    },
  );

  test('zwykły tekst to nie miejsce', () async {
    start();
    await controller().handle((
      text: 'https://example.com/artykul',
      subject: 'Artykuł',
    ));

    expect(state(), isA<SharedPlaceNotAPlace>());
  });

  test('błąd rozwijania linku kończy się SharedPlaceFailed', () async {
    start();
    await controller().handle((
      text: 'https://maps.app.goo.gl/nieznany',
      subject: null,
    ));

    expect(state(), isA<SharedPlaceFailed>());
  });

  test(
    'adres to sam kraj: POI szukane w całym kraju, bez proximity i limitu 30 km',
    () async {
      geocoding.forwardResults['Portugalia'] = portugal;
      search
        ..suggestions = const [balcoesPoi]
        ..retrievePoint = balcoes;
      start();
      await controller().handle((text: balcoesLink, subject: null));

      expect(search.queries.single, ('Miradouro dos Balcões', null));
      expect(search.countries.single, 'pt');
      expect(place().lat, balcoes.lat);
      expect(place().lng, balcoes.lng);
      expect(place().name, 'Miradouro dos Balcões');
      expect(place().approximate, isTrue);
    },
  );

  group('Plus Code', () {
    void expectGoogleBalcoes() {
      expect(place().lat, closeTo(32.74156, 0.0001));
      expect(place().lng, closeTo(-16.89031, 0.0001));
    }

    test('potwierdzony przez POI: dokładny punkt Google', () async {
      geocoding.forwardResults['Ribeiro Frio, Portugalia'] = ribeiroFrio;
      search
        ..suggestions = const [balcoesPoi]
        ..retrievePoint = balcoes;
      start();
      await controller().handle((
        text: balcoesPlusCodeLink,
        subject: 'Miradouro dos Balcões',
      ));

      expectGoogleBalcoes();
      expect(place().name, 'Miradouro dos Balcões');
      expect(place().address, 'Ribeiro Frio, Portugalia');
      expect(place().approximate, isFalse);
      expect(search.queries.single, (
        'Miradouro dos Balcões',
        ribeiroFrio.point,
      ));
    });

    test(
      'złe geokodowanie adresu nie przeszkadza, gdy POI potwierdza kod',
      () async {
        geocoding.forwardResults['Ribeiro Frio, Portugalia'] =
            const GeocodedPlace(
              point: (lat: 41.355923, lng: -8.556117),
              featureType: 'place',
              countryCode: 'pt',
            );
        search
          ..suggestions = const [balcoesPoi]
          ..retrievePoint = balcoes;
        start();
        await controller().handle((text: balcoesPlusCodeLink, subject: null));

        expectGoogleBalcoes();
        expect(place().approximate, isFalse);
      },
    );

    test('bez POI: odniesieniem jest adres, wynik przybliżony', () async {
      geocoding.forwardResults['Ribeiro Frio, Portugalia'] = ribeiroFrio;
      start();
      await controller().handle((text: balcoesPlusCodeLink, subject: null));

      expectGoogleBalcoes();
      expect(place().approximate, isTrue);
    });

    test(
      'odniesienie niezgodne z kodem jest pomijane – bez POI NeedsSearch',
      () async {
        // Ribeirão: odzyskany punkt wypada ~50 km od niego.
        geocoding.forwardResults['Ribeiro Frio, Portugalia'] =
            const GeocodedPlace(
              point: (lat: 41.355923, lng: -8.556117),
              featureType: 'place',
            );
        start();
        await controller().handle((text: balcoesPlusCodeLink, subject: null));

        expect(state(), isA<SharedPlaceNeedsSearch>());
      },
    );
  });

  test('adres to sam kraj, POI poza jego zasięgiem: NeedsSearch', () async {
    geocoding.forwardResults['Portugalia'] = portugal;
    search
      ..suggestions = const [balcoesPoi]
      ..retrievePoint = (lat: 50.06, lng: 19.94);
    start();
    await controller().handle((text: balcoesLink, subject: null));

    expect(
      state(),
      isA<SharedPlaceNeedsSearch>().having(
        (s) => s.name,
        'name',
        'Miradouro dos Balcões',
      ),
    );
  });

  test(
    'adres to sam kraj, brak POI: NeedsSearch zamiast środka kraju',
    () async {
      geocoding.forwardResults['Portugalia'] = portugal;
      start();
      await controller().handle((text: balcoesLink, subject: null));

      expect(state(), isA<SharedPlaceNeedsSearch>());
    },
  );

  test(
    'sama nazwa bez POI: NeedsSearch, bez geokodowania samej nazwy',
    () async {
      start();
      await controller().handle((
        text: 'geo:0,0?q=Miradouro%20dos%20Balc%C3%B5es',
        subject: null,
      ));

      expect(search.queries.single, ('Miradouro dos Balcões', null));
      expect(search.countries.single, isNull);
      expect(geocoding.calls, isEmpty);
      expect(state(), isA<SharedPlaceNeedsSearch>());
    },
  );

  test('nieznany adres i brak POI: NeedsSearch', () async {
    start();
    await controller().handle((
      text: parkLink,
      subject: 'Park Jaśkowej Doliny',
    ));

    expect((state() as SharedPlaceNeedsSearch).name, 'Park Jaśkowej Doliny');
  });

  test('bez nazwy i adresu: SharedPlaceFailed', () async {
    start();
    await controller().handle((text: 'geo:0,0?q=', subject: null));

    expect(state(), isA<SharedPlaceFailed>());
  });

  test('udostępnienie przy zimnym starcie jest obsługiwane od razu', () async {
    channel.initial = (text: pinLink, subject: 'Klonowa 01');
    start();
    await pumpEventQueue();

    expect(place().name, 'Klonowa 01');
  });

  test('kolejne udostępnienia przychodzą strumieniem z kanału', () async {
    start();
    channel.controller.add((text: pinLink, subject: 'Klonowa 01'));
    await pumpEventQueue();

    expect(place().name, 'Klonowa 01');
  });

  test(
    'w trakcie odczytu stan to Loading; cancel odrzuca spóźniony wynik',
    () async {
      resolver.gate = Completer();
      start();
      final pending = controller().handle((
        text: pinLink,
        subject: 'Klonowa 01',
      ));

      expect(state(), isA<SharedPlaceLoading>());
      controller().cancel();
      resolver.gate!.complete();
      await pending;

      expect(state(), isA<SharedPlaceIdle>());
    },
  );
}
