import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jureczek/core/database/app_database.dart';
import 'package:jureczek/features/folders/data/folders_repository.dart';
import 'package:jureczek/features/folders/domain/trip_folder.dart';
import 'package:jureczek/features/map/data/pins_repository.dart';
import 'package:jureczek/features/map/domain/pin_kind.dart';
import 'package:jureczek/features/places/domain/place_type.dart';
import 'package:jureczek/features/map/domain/pin_color.dart';
import 'package:jureczek/features/map/domain/place_pin.dart';

void main() {
  late AppDatabase db;
  late PinsRepository repository;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repository = PinsRepository(db);
  });
  tearDown(() => db.close());

  PlacePin pin(String id, DateTime createdAt) => PlacePin(
    folderId: 'f',
    id: id,
    lat: 50.06,
    lng: 19.94,
    createdAt: createdAt,
  );

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
    expect(saved.kind, PinKind.standard);
  });

  group('odwiedzona (v21)', () {
    final at = DateTime(2026, 11, 4, 12, 30, 15, 250);

    test('nowa pinezka jest nieodwiedzona', () async {
      await repository.insert(pin('a', DateTime(2026, 11, 1)));

      final saved = await repository.findById('a');
      expect(saved?.visitedAt, isNull);
      expect(saved?.visited, isFalse);
    });

    test(
      'oznaczenie zapisuje datę co do ms, a odznaczenie ją kasuje',
      () async {
        await repository.insert(pin('a', DateTime(2026, 11, 1)));

        await repository.setVisitedAt('a', at);
        final visited = await repository.findById('a');
        expect(visited?.visitedAt, at);
        expect(visited?.visited, isTrue);

        await repository.setVisitedAt('a', null);
        expect((await repository.findById('a'))?.visitedAt, isNull);
      },
    );

    test('oznaczenie nie zmienia pozostałych danych pinezki', () async {
      await repository.insert(pin('a', DateTime(2026, 11, 1)));
      await repository.updateDetails('a', name: 'Wawel', note: 'Bilety');

      await repository.setVisitedAt('a', at);

      final saved = await repository.findById('a');
      expect(saved?.name, 'Wawel');
      expect(saved?.note, 'Bilety');
    });

    test('updateDetails zachowuje oznaczenie', () async {
      await repository.insert(pin('a', DateTime(2026, 11, 1)));
      await repository.setVisitedAt('a', at);

      await repository.updateDetails('a', name: 'Wawel');

      expect((await repository.findById('a'))?.visitedAt, at);
    });

    test('oznaczenie podnosi folder pinezki na górę listy', () async {
      final folders = FoldersRepository(db);
      await db
          .into(db.folders)
          .insert(
            FoldersCompanion.insert(
              id: 'f',
              name: 'Kraków',
              icon: FolderIcon.camper.key,
              color: FolderColor.emerald.key,
              createdAt: DateTime(2026, 1, 1),
              updatedAtMs: 1,
            ),
          );
      await db
          .into(db.folders)
          .insert(
            FoldersCompanion.insert(
              id: 'g',
              name: 'Gdańsk',
              icon: FolderIcon.camper.key,
              color: FolderColor.emerald.key,
              createdAt: DateTime(2026, 1, 1),
              updatedAtMs: 2,
            ),
          );
      await repository.insert(pin('a', DateTime(2026, 11, 1)));
      await db
          .update(db.folders)
          .write(const FoldersCompanion(updatedAtMs: Value(1)));
      await (db.update(db.folders)..where((t) => t.id.equals('g'))).write(
        const FoldersCompanion(updatedAtMs: Value(2)),
      );
      expect((await folders.watchAll().first).first.id, 'g');

      await repository.setVisitedAt('a', at);

      expect((await folders.watchAll().first).first.id, 'f');
    });
  });

  group('gwiazdka (v22)', () {
    test('nowa pinezka domyślnie jej nie ma, a insert ją zapisuje', () async {
      await repository.insert(pin('a', DateTime(2026, 11, 1)));
      await repository.insert(
        PlacePin(
          folderId: 'f',
          id: 'b',
          lat: 50.06,
          lng: 19.94,
          createdAt: DateTime(2026, 11, 2),
          starred: true,
        ),
      );

      expect((await repository.findById('a'))?.starred, isFalse);
      expect((await repository.findById('b'))?.starred, isTrue);
    });

    test('setStarred ustawia i zdejmuje gwiazdkę bez zmiany reszty', () async {
      await repository.insert(pin('a', DateTime(2026, 11, 1)));
      await repository.updateDetails('a', name: 'Wawel', note: 'Bilety');
      final visitedAt = DateTime(2026, 11, 3, 12, 30);
      await repository.setVisitedAt('a', visitedAt);

      await repository.setStarred('a', starred: true);
      final starred = await repository.findById('a');
      expect(starred?.starred, isTrue);
      expect(starred?.name, 'Wawel');
      expect(starred?.note, 'Bilety');
      expect(starred?.visitedAt, visitedAt);

      await repository.setStarred('a', starred: false);
      expect((await repository.findById('a'))?.starred, isFalse);
    });

    test('updateDetails zachowuje gwiazdkę', () async {
      await repository.insert(pin('a', DateTime(2026, 11, 1)));
      await repository.setStarred('a', starred: true);

      await repository.updateDetails('a', name: 'Wawel');

      expect((await repository.findById('a'))?.starred, isTrue);
    });

    test('podnosi folder pinezki na górę listy', () async {
      final folders = FoldersRepository(db);
      for (final (id, updatedAtMs) in [('f', 1), ('g', 2)]) {
        await db
            .into(db.folders)
            .insert(
              FoldersCompanion.insert(
                id: id,
                name: id,
                icon: FolderIcon.camper.key,
                color: FolderColor.emerald.key,
                createdAt: DateTime(2026, 1, 1),
                updatedAtMs: updatedAtMs,
              ),
            );
      }
      await repository.insert(pin('a', DateTime(2026, 11, 1)));
      await db
          .update(db.folders)
          .write(const FoldersCompanion(updatedAtMs: Value(1)));
      await (db.update(db.folders)..where((t) => t.id.equals('g'))).write(
        const FoldersCompanion(updatedAtMs: Value(2)),
      );
      expect((await folders.watchAll().first).first.id, 'g');

      await repository.setStarred('a', starred: true);

      expect((await folders.watchAll().first).first.id, 'f');
    });
  });

  test('updateDetails zmienia typ; bez typu zostawia dotychczasowy', () async {
    await repository.insert(pin('a', DateTime(2026, 11, 1)));

    await repository.updateDetails('a', kind: const PinKind(PlaceType.hotel));
    expect(
      (await repository.findById('a'))?.kind,
      const PinKind(PlaceType.hotel),
    );

    await repository.updateDetails('a', name: 'Postój');
    expect(
      (await repository.findById('a'))?.kind,
      const PinKind(PlaceType.hotel),
    );

    await repository.updateDetails('a', kind: PinKind.standard);
    expect((await repository.findById('a'))?.kind, PinKind.standard);
  });

  test(
    'kolor: zapis, zmiana razem z typem, null przywraca kolor typu',
    () async {
      await repository.insert(
        PlacePin(
          folderId: 'f',
          id: 'a',
          lat: 50.06,
          lng: 19.94,
          createdAt: DateTime(2026, 11, 2),
          color: PinColor.teal,
        ),
      );
      expect((await repository.findById('a'))?.color, PinColor.teal);

      // Bez typu kolor zostaje.
      await repository.updateDetails('a', name: 'Postój');
      expect((await repository.findById('a'))?.color, PinColor.teal);

      await repository.updateDetails(
        'a',
        kind: const PinKind(PlaceType.lake),
        color: PinColor.black,
      );
      expect((await repository.findById('a'))?.color, PinColor.black);

      await repository.updateDetails('a', kind: const PinKind(PlaceType.lake));
      expect((await repository.findById('a'))?.color, isNull);
    },
  );

  test('nieznany kolor w bazie to kolor typu', () async {
    await repository.insert(pin('a', DateTime(2026, 11, 1)));
    await db.customStatement("UPDATE pins SET color = 'tęcza'");

    expect((await repository.findById('a'))?.color, isNull);
  });

  test('nieznany typ w bazie to domyślna pinezka', () async {
    await repository.insert(pin('a', DateTime(2026, 11, 1)));
    await db.customStatement("UPDATE pins SET category = 'kosmos'");

    expect((await repository.findById('a'))?.kind, PinKind.standard);
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
        folderId: 'f',
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

  group('watchActive (v23)', () {
    Future<void> folder(String id) => db
        .into(db.folders)
        .insert(
          FoldersCompanion.insert(
            id: id,
            name: id,
            icon: FolderIcon.camper.key,
            color: FolderColor.emerald.key,
            createdAt: DateTime(2026, 1, 1),
            updatedAtMs: 1,
          ),
        );

    test('pomija pinezki z archiwum, watchAll zostawia wszystkie', () async {
      final folders = FoldersRepository(db);
      await folder('f');
      await folder('g');
      await repository.insert(
        PlacePin(
          id: 'b',
          folderId: 'g',
          lat: 1,
          lng: 2,
          createdAt: DateTime(2026, 10, 26),
        ),
      );
      await repository.insert(pin('a', DateTime(2026, 10, 25)));
      await folders.setArchiveState(
        'g',
        archivedAt: DateTime(2026, 11, 1),
        updatedAt: DateTime(2026, 11, 1),
      );

      expect((await repository.watchActive().first).map((p) => p.id), ['a']);
      expect((await repository.watchAll().first).map((p) => p.id), ['a', 'b']);
    });

    test('emituje po samej zmianie stanu folderu', () async {
      final folders = FoldersRepository(db);
      await folder('f');
      await repository.insert(pin('a', DateTime(2026, 10, 25)));

      final done = expectLater(
        repository.watchActive().map((pins) => pins.length),
        emitsInOrder([1, 0, 1]),
      );
      await Future<void>.delayed(const Duration(milliseconds: 20));
      await folders.setArchiveState(
        'f',
        archivedAt: DateTime(2026, 11, 1),
        updatedAt: DateTime(2026, 11, 1),
      );
      await Future<void>.delayed(const Duration(milliseconds: 20));
      await folders.setArchiveState(
        'f',
        archivedAt: null,
        updatedAt: DateTime(2026, 11, 2),
      );
      await done;
    });
  });
}
