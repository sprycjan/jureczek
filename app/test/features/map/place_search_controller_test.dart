import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jureczek/features/map/application/place_search_controller.dart';
import 'package:jureczek/features/map/data/place_search_client.dart';
import 'package:jureczek/features/map/domain/place_suggestion.dart';

/// Klient, którego odpowiedzi test kończy ręcznie.
class _FakeClient implements PlaceSearchClient {
  final queries = <String>[];
  final sessions = <String>[];
  final pending = <String, Completer<List<PlaceSuggestion>>>{};
  Object? retrieveError;

  @override
  Future<List<PlaceSuggestion>> suggest(
    String query, {
    required String sessionToken,
    LatLng? proximity,
    String? country,
  }) {
    queries.add(query);
    sessions.add(sessionToken);
    return (pending[query] = Completer()).future;
  }

  @override
  Future<PlaceResult> retrieve(
    PlaceSuggestion suggestion, {
    required String sessionToken,
  }) async {
    sessions.add(sessionToken);
    if (retrieveError != null) throw retrieveError!;
    return PlaceResult(name: suggestion.name, lat: 50, lng: 19);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late _FakeClient client;
  late ProviderContainer container;

  setUp(() {
    client = _FakeClient();
    container = ProviderContainer(
      overrides: [placeSearchClientProvider.overrideWithValue(client)],
    );
    container.listen(placeSearchControllerProvider, (_, _) {});
  });
  tearDown(() => container.dispose());

  PlaceSearchController controller() =>
      container.read(placeSearchControllerProvider.notifier);
  PlaceSearchState state() => container.read(placeSearchControllerProvider);

  const wawel = PlaceSuggestion(mapboxId: 'a', name: 'Wawel');

  test('poniżej 3 znaków nie pyta API', () {
    fakeAsync((async) {
      controller().onQueryChanged('Wa');
      async.elapse(const Duration(seconds: 1));

      expect(client.queries, isEmpty);
      expect(state(), isA<PlaceSearchIdle>());
    });
  });

  test('pyta dopiero po 300 ms przerwy i tylko o ostatni tekst', () {
    fakeAsync((async) {
      controller().onQueryChanged('Waw');
      async.elapse(const Duration(milliseconds: 200));
      controller().onQueryChanged('Wawe');
      async.elapse(const Duration(milliseconds: 299));
      expect(client.queries, isEmpty);

      async.elapse(const Duration(milliseconds: 1));
      expect(client.queries, ['Wawe']);
      expect(state(), isA<PlaceSearchLoading>());
    });
  });

  test('pokazuje podpowiedzi albo brak wyników', () {
    fakeAsync((async) {
      controller().onQueryChanged('Wawel');
      async.elapse(PlaceSearchController.debounce);
      client.pending['Wawel']!.complete([wawel]);
      async.flushMicrotasks();
      expect(
        (state() as PlaceSearchSuggestions).suggestions.single.name,
        'Wawel',
      );

      controller().onQueryChanged('Xyzzy');
      async.elapse(PlaceSearchController.debounce);
      // W trakcie ładowania zostają poprzednie podpowiedzi.
      expect((state() as PlaceSearchLoading).previous, [wawel]);
      client.pending['Xyzzy']!.complete([]);
      async.flushMicrotasks();
      expect(state(), isA<PlaceSearchEmpty>());
    });
  });

  test('błąd API daje stan błędu', () {
    fakeAsync((async) {
      controller().onQueryChanged('Wawel');
      async.elapse(PlaceSearchController.debounce);
      client.pending['Wawel']!.completeError(
        const PlaceSearchException('offline'),
      );
      async.flushMicrotasks();

      expect(state(), isA<PlaceSearchError>());
    });
  });

  test('spóźniona odpowiedź na stare zapytanie jest ignorowana', () {
    fakeAsync((async) {
      controller().onQueryChanged('Waw');
      async.elapse(PlaceSearchController.debounce);
      controller().onQueryChanged('Kra');
      async.elapse(PlaceSearchController.debounce);

      client.pending['Kra']!.complete([]);
      async.flushMicrotasks();
      client.pending['Waw']!.complete([wawel]);
      async.flushMicrotasks();

      expect(state(), isA<PlaceSearchEmpty>());
    });
  });

  test('select używa tej samej sesji i potem zaczyna nową', () {
    fakeAsync((async) {
      controller().onQueryChanged('Wawel');
      async.elapse(PlaceSearchController.debounce);
      client.pending['Wawel']!.complete([wawel]);
      async.flushMicrotasks();

      PlaceResult? result;
      controller().select(wawel).then((r) => result = r);
      async.flushMicrotasks();

      expect(result?.name, 'Wawel');
      expect(client.sessions, hasLength(2));
      expect(client.sessions[0], client.sessions[1]);
      expect(controller().sessionToken, isNot(client.sessions[0]));
      expect(state(), isA<PlaceSearchIdle>());
    });
  });

  test('błąd select zwraca null i pokazuje błąd', () async {
    client.retrieveError = const PlaceSearchException('offline');

    expect(await controller().select(wawel), isNull);
    expect(state(), isA<PlaceSearchError>());
  });

  test('reset czyści stan i zmienia sesję', () {
    final before = controller().sessionToken;
    controller().reset();

    expect(controller().sessionToken, isNot(before));
    expect(state(), isA<PlaceSearchIdle>());
  });
}
