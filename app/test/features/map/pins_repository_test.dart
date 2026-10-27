import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jureczek/core/database/app_database.dart';
import 'package:jureczek/features/map/data/pins_repository.dart';
import 'package:jureczek/features/map/domain/place_pin.dart';

void main() {
  late AppDatabase db;
  late PinsRepository repository;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repository = PinsRepository(db);
  });
  tearDown(() => db.close());

  PlacePin pin(String id, DateTime createdAt) =>
      PlacePin(id: id, lat: 50.06, lng: 19.94, createdAt: createdAt);

  test('na starcie baza jest pusta', () async {
    expect(await repository.watchAll().first, isEmpty);
  });

  test('insert zapisuje wszystkie pola', () async {
    final createdAt = DateTime(2026, 10, 25, 12, 30);
    await repository.insert(pin('a', createdAt));

    final saved = (await repository.watchAll().first).single;
    expect(saved.id, 'a');
    expect(saved.lat, 50.06);
    expect(saved.lng, 19.94);
    expect(saved.createdAt, createdAt);
  });

  test('watchAll zwraca pinezki od najstarszej', () async {
    await repository.insert(pin('nowa', DateTime(2026, 10, 25)));
    await repository.insert(pin('stara', DateTime(2026, 1, 1)));

    final ids = (await repository.watchAll().first).map((p) => p.id);
    expect(ids, ['stara', 'nowa']);
  });

  test('watchAll emituje po zmianie', () async {
    final emissions = repository.watchAll().map((pins) => pins.length);
    expectLater(emissions, emitsInOrder([0, 1, 0]));

    await pumpEventQueue();
    await repository.insert(pin('a', DateTime(2026, 10, 25)));
    await pumpEventQueue();
    await repository.delete('a');
  });

  test('delete usuwa tylko wskazaną pinezkę', () async {
    await repository.insert(pin('a', DateTime(2026, 10, 25)));
    await repository.insert(pin('b', DateTime(2026, 10, 26)));

    await repository.delete('a');

    final ids = (await repository.watchAll().first).map((p) => p.id);
    expect(ids, ['b']);
    expect(await repository.findById('a'), isNull);
  });

  test('ponowny insert po delete przywraca to samo id i dane', () async {
    final original = pin('a', DateTime(2026, 10, 25));
    await repository.insert(original);
    await repository.delete('a');

    await repository.insert(original);

    final restored = await repository.findById('a');
    expect(restored?.lat, original.lat);
    expect(restored?.createdAt, original.createdAt);
  });

  test('insert zapisuje nazwę i notatkę', () async {
    await repository.insert(
      PlacePin(
        id: 'a',
        lat: 50.05,
        lng: 19.93,
        createdAt: DateTime(2026, 10, 25),
        name: 'Wawel',
        note: 'Bilety online',
      ),
    );

    final saved = await repository.findById('a');
    expect(saved?.name, 'Wawel');
    expect(saved?.note, 'Bilety online');
  });

  test(
    'updateDetails zmienia tylko nazwę i notatkę wskazanej pinezki',
    () async {
      final createdAt = DateTime(2026, 10, 25);
      await repository.insert(pin('a', createdAt));
      await repository.insert(pin('b', createdAt));

      await repository.updateDetails('a', name: 'Wawel', note: 'Bilety');

      final a = await repository.findById('a');
      expect(a?.name, 'Wawel');
      expect(a?.note, 'Bilety');
      expect(a?.lat, 50.06);
      expect(a?.createdAt, createdAt);
      expect((await repository.findById('b'))?.name, isNull);
    },
  );

  test('updateDetails z null czyści nazwę i notatkę', () async {
    await repository.insert(pin('a', DateTime(2026, 10, 25)));
    await repository.updateDetails('a', name: 'Wawel', note: 'Bilety');

    await repository.updateDetails('a');

    final a = await repository.findById('a');
    expect(a?.name, isNull);
    expect(a?.note, isNull);
  });
}
