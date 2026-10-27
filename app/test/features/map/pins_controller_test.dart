import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jureczek/core/database/app_database.dart';
import 'package:jureczek/features/map/application/pins_providers.dart';
import 'package:jureczek/features/map/domain/place_pin.dart';

void main() {
  late ProviderContainer container;

  setUp(() {
    final db = AppDatabase(NativeDatabase.memory());
    container = ProviderContainer(
      overrides: [appDatabaseProvider.overrideWithValue(db)],
    );
    // Riverpod 3 wstrzymuje providery bez słuchaczy – trzymamy strumień aktywny.
    container.listen(pinsProvider, (_, _) {});
    addTearDown(db.close);
  });
  tearDown(() => container.dispose());

  PinsController controller() => container.read(pinsControllerProvider);

  /// Stan [pinsProvider] po dotarciu zmian z bazy.
  Future<List<PlacePin>> pins() async {
    await pumpEventQueue();
    return container.read(pinsProvider).requireValue;
  }

  Future<List<String>> pinIds() async =>
      (await pins()).map((p) => p.id).toList();

  test('na starcie nie ma pinezek', () async {
    expect(await pins(), isEmpty);
  });

  test('add zapisuje pinezkę z podanymi współrzędnymi i datą', () async {
    final before = DateTime.now();
    await controller().add(lat: 50.06, lng: 19.94);

    final pin = (await pins()).single;
    expect(pin.lat, 50.06);
    expect(pin.lng, 19.94);
    expect(pin.createdAt.difference(before).inSeconds, lessThan(5));
  });

  test('add zapisuje nazwę, obciętą; pusta nazwa to null', () async {
    await controller().add(lat: 50.05, lng: 19.93, name: ' Wawel ');
    await controller().add(lat: 52.23, lng: 21.01, name: '  ');

    final names = (await pins()).map((p) => p.name).toSet();
    expect(names, {'Wawel', null});
  });

  test('add zapisuje notatkę, adres i link; puste teksty to null', () async {
    await controller().add(
      lat: 54.38,
      lng: 18.60,
      name: 'Galeria Metropolia',
      note: '  ',
      address: ' Jana Kilińskiego 4, 80-452 Gdańsk ',
      sourceUrl: 'https://maps.app.goo.gl/abc',
    );

    final pin = (await pins()).single;
    expect(pin.note, isNull);
    expect(pin.address, 'Jana Kilińskiego 4, 80-452 Gdańsk');
    expect(pin.sourceUrl, 'https://maps.app.goo.gl/abc');
  });

  test('updateDetails zapisuje adres, a link zostaje bez zmian', () async {
    await controller().add(
      lat: 54.38,
      lng: 18.60,
      sourceUrl: 'https://maps.app.goo.gl/abc',
    );
    final id = (await pinIds()).single;

    await controller().updateDetails(id, address: ' Klonowa 01 ');

    final pin = (await pins()).single;
    expect(pin.address, 'Klonowa 01');
    expect(pin.sourceUrl, 'https://maps.app.goo.gl/abc');
  });

  test('kolejne pinezki mają unikalne id', () async {
    await controller().add(lat: 52.23, lng: 21.01);
    await controller().add(lat: 54.35, lng: 18.65);
    await controller().add(lat: 51.11, lng: 17.04);

    expect((await pinIds()).toSet(), hasLength(3));
  });

  test('remove usuwa pinezkę i ją zwraca', () async {
    await controller().add(lat: 50.06, lng: 19.94);
    final id = (await pinIds()).single;

    final removed = await controller().remove(id);

    expect(removed?.id, id);
    expect(await pinIds(), isEmpty);
  });

  test('remove nieistniejącej pinezki zwraca null', () async {
    expect(await controller().remove('brak'), isNull);
  });

  test('restore przywraca usuniętą pinezkę z tym samym id', () async {
    await controller().add(lat: 50.06, lng: 19.94);
    final id = (await pinIds()).single;
    final removed = await controller().remove(id);

    await controller().restore(removed!);

    expect(await pinIds(), [id]);
  });

  test(
    'updateDetails obcina białe znaki i zapisuje pusty tekst jako null',
    () async {
      await controller().add(lat: 50.06, lng: 19.94);
      final id = (await pinIds()).single;

      await controller().updateDetails(id, name: '  Wawel ', note: '   ');

      final pin = (await pins()).single;
      expect(pin.name, 'Wawel');
      expect(pin.note, isNull);
    },
  );

  test('restore przywraca też nazwę i notatkę', () async {
    await controller().add(lat: 50.06, lng: 19.94);
    final id = (await pinIds()).single;
    await controller().updateDetails(id, name: 'Wawel', note: 'Bilety');
    final removed = await controller().remove(id);

    await controller().restore(removed!);

    final pin = (await pins()).single;
    expect(pin.name, 'Wawel');
    expect(pin.note, 'Bilety');
  });
}
