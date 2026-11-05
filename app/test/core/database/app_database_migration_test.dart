import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jureczek/core/database/app_database.dart';
import 'package:jureczek/features/folders/data/folders_repository.dart';
import 'package:jureczek/features/folders/domain/trip_folder.dart';
import 'package:jureczek/features/map/data/pins_repository.dart';
import 'package:jureczek/features/map/domain/pin_kind.dart';
import 'package:jureczek/features/map/domain/pin_color.dart';
import 'package:jureczek/features/map/domain/place_pin.dart';
import 'package:jureczek/features/places/domain/place_type.dart';

void main() {
  test(
    'aktualizacja ze schematu 3 kasuje stare dane i tworzy schemat 4 (v9)',
    () async {
      // Baza w stanie z v5–v8 aplikacji (schemat 3), z jedną pinezką.
      final db = AppDatabase(
        NativeDatabase.memory(
          setup: (raw) {
            raw.execute('''
              CREATE TABLE pins (
                id TEXT NOT NULL,
                lat REAL NOT NULL,
                lng REAL NOT NULL,
                created_at INTEGER NOT NULL,
                name TEXT NULL,
                note TEXT NULL,
                address TEXT NULL,
                source_url TEXT NULL,
                PRIMARY KEY (id)
              )
            ''');
            raw.execute(
              "INSERT INTO pins VALUES ('stara', 50.06, 19.94, 1792886400, 'Wawel', NULL, NULL, NULL)",
            );
            raw.execute('PRAGMA user_version = 3');
          },
        ),
      );
      addTearDown(db.close);
      final repository = PinsRepository(db);

      expect(await repository.findById('stara'), isNull);
      expect(await repository.watchAll().first, isEmpty);

      await repository.insert(
        PlacePin(
          folderId: 'f',
          id: 'nowa',
          lat: 50.06,
          lng: 19.94,
          createdAt: DateTime(2026, 11, 1),
          kind: const PinKind(PlaceType.lake),
        ),
      );
      expect(
        (await repository.findById('nowa'))?.kind,
        const PinKind(PlaceType.lake),
      );
    },
  );

  /// Baza w stanie z v9 (schemat 4): pinezki z typem, bez folderów.
  AppDatabase schema4({required bool withPin}) => AppDatabase(
    NativeDatabase.memory(
      setup: (raw) {
        raw.execute('''
          CREATE TABLE pins (
            id TEXT NOT NULL,
            lat REAL NOT NULL,
            lng REAL NOT NULL,
            created_at INTEGER NOT NULL,
            name TEXT NULL,
            note TEXT NULL,
            address TEXT NULL,
            source_url TEXT NULL,
            category TEXT NOT NULL DEFAULT 'standard',
            PRIMARY KEY (id)
          )
        ''');
        if (withPin) {
          raw.execute(
            "INSERT INTO pins VALUES ('p1', 50.06, 19.94, 1792886400, 'Wawel', NULL, NULL, NULL, 'places')",
          );
        }
        raw.execute('PRAGMA user_version = 4');
      },
    ),
  );

  test('migracja 4 → 5 przenosi pinezki do folderu „Pinezki”', () async {
    final db = schema4(withPin: true);
    addTearDown(db.close);

    final folders = await FoldersRepository(db).watchAll().first;
    expect(folders.single.name, TripFolder.defaultName);
    expect(folders.single.pinCount, 1);

    final pin = await PinsRepository(db).findById('p1');
    expect(pin?.name, 'Wawel');
    // Przez wszystkie migracje do 7: kategoria v9 → typ „inne”.
    expect(pin?.kind, const PinKind(PlaceType.placesOther));
    expect(pin?.folderId, folders.single.id);
    expect(pin?.visitedAt, isNull);
    expect(pin?.starred, isFalse);
    // Tabela tworzona w tej migracji ma już kolumnę archiwum (schemat 11).
    expect(folders.single.isArchived, isFalse);
  });

  test('migracja 4 → 5 bez pinezek nie tworzy folderu', () async {
    final db = schema4(withPin: false);
    addTearDown(db.close);

    expect(await FoldersRepository(db).watchAll().first, isEmpty);
  });

  test('migracja 5 → 6 dodaje kolor pinezki, stare bez koloru (v14)', () async {
    // Baza w stanie z v10–v13 (schemat 5): foldery, pinezki bez koloru.
    final db = AppDatabase(
      NativeDatabase.memory(
        setup: (raw) {
          raw.execute('''
            CREATE TABLE folders (
              id TEXT NOT NULL,
              name TEXT NOT NULL,
              description TEXT NULL,
              icon TEXT NOT NULL,
              color TEXT NOT NULL,
              created_at INTEGER NOT NULL,
              updated_at_ms INTEGER NOT NULL,
              PRIMARY KEY (id)
            )
          ''');
          raw.execute(
            "INSERT INTO folders VALUES ('f1', 'Kraków', NULL, 'camper', 'emerald', 1792886400, 1792886400000)",
          );
          raw.execute('''
            CREATE TABLE pins (
              id TEXT NOT NULL,
              lat REAL NOT NULL,
              lng REAL NOT NULL,
              created_at INTEGER NOT NULL,
              name TEXT NULL,
              note TEXT NULL,
              address TEXT NULL,
              source_url TEXT NULL,
              category TEXT NOT NULL DEFAULT 'standard',
              folder_id TEXT NOT NULL,
              PRIMARY KEY (id)
            )
          ''');
          raw.execute(
            "INSERT INTO pins VALUES ('p1', 50.06, 19.94, 1792886400, 'Wawel', NULL, NULL, NULL, 'places', 'f1')",
          );
          raw.execute('PRAGMA user_version = 5');
        },
      ),
    );
    addTearDown(db.close);
    final repository = PinsRepository(db);

    final old = await repository.findById('p1');
    expect(old?.name, 'Wawel');
    expect(old?.kind, const PinKind(PlaceType.placesOther));
    expect(old?.color, isNull);

    await repository.updateDetails(
      'p1',
      name: 'Wawel',
      kind: const PinKind(PlaceType.castle),
      color: PinColor.gold,
    );
    expect((await repository.findById('p1'))?.color, PinColor.gold);
  });

  test('migracja 6 → 7 zamienia kategorie v9 na typy „inne” (v16)', () async {
    // Baza w stanie z v14–v15 (schemat 6): kategorie v9 i kolor.
    final db = AppDatabase(
      NativeDatabase.memory(
        setup: (raw) {
          raw.execute('''
            CREATE TABLE folders (
              id TEXT NOT NULL,
              name TEXT NOT NULL,
              description TEXT NULL,
              icon TEXT NOT NULL,
              color TEXT NOT NULL,
              created_at INTEGER NOT NULL,
              updated_at_ms INTEGER NOT NULL,
              PRIMARY KEY (id)
            )
          ''');
          raw.execute(
            "INSERT INTO folders VALUES ('f1', 'Kraków', NULL, 'camper', 'emerald', 1792886400, 1792886400000)",
          );
          raw.execute('''
            CREATE TABLE pins (
              id TEXT NOT NULL,
              lat REAL NOT NULL,
              lng REAL NOT NULL,
              created_at INTEGER NOT NULL,
              name TEXT NULL,
              note TEXT NULL,
              address TEXT NULL,
              source_url TEXT NULL,
              category TEXT NOT NULL DEFAULT 'standard',
              folder_id TEXT NOT NULL,
              color TEXT NULL,
              PRIMARY KEY (id)
            )
          ''');
          for (final (id, category, color) in [
            ('g', 'gastronomy', 'gold'),
            ('p', 'places', null),
            ('n', 'nature', null),
            ('a', 'activities', null),
            ('t', 'travel', null),
            ('e', 'entertainment', null),
            ('r', 'practical', null),
            ('s', 'standard', 'red'),
          ]) {
            raw.execute(
              "INSERT INTO pins VALUES ('$id', 50.06, 19.94, 1792886400, NULL, NULL, NULL, NULL, "
              "'$category', 'f1', ${color == null ? 'NULL' : "'$color'"})",
            );
          }
          raw.execute('PRAGMA user_version = 6');
        },
      ),
    );
    addTearDown(db.close);
    final pins = {
      for (final pin in await PinsRepository(db).watchAll().first) pin.id: pin,
    };
    expect(pins, hasLength(8));
    expect(pins['g']?.kind, const PinKind(PlaceType.gastronomyOther));
    expect(pins['g']?.color, PinColor.gold);
    expect(pins['p']?.kind, const PinKind(PlaceType.placesOther));
    expect(pins['n']?.kind, const PinKind(PlaceType.natureOther));
    expect(pins['a']?.kind, const PinKind(PlaceType.activitiesOther));
    expect(pins['t']?.kind, const PinKind(PlaceType.travelOther));
    expect(pins['e']?.kind, const PinKind(PlaceType.entertainmentOther));
    expect(pins['r']?.kind, const PinKind(PlaceType.practicalOther));
    expect(pins['s']?.kind, PinKind.standard);
    expect(pins['s']?.color, PinColor.red);
    expect(pins['s']?.poiName, isNull);
  });

  test('aktualizacja ze schematu 7 dodaje pustą nazwę POI (v19)', () async {
    final db = AppDatabase(
      NativeDatabase.memory(
        setup: (raw) {
          raw.execute('''
            CREATE TABLE folders (
              id TEXT NOT NULL,
              name TEXT NOT NULL,
              description TEXT NULL,
              icon TEXT NOT NULL,
              color TEXT NOT NULL,
              created_at INTEGER NOT NULL,
              updated_at_ms INTEGER NOT NULL,
              PRIMARY KEY (id)
            )
          ''');
          raw.execute(
            "INSERT INTO folders VALUES ('f1', 'Kraków', NULL, 'camper', 'emerald', 1792886400, 1792886400000)",
          );
          raw.execute('''
            CREATE TABLE pins (
              id TEXT NOT NULL,
              lat REAL NOT NULL,
              lng REAL NOT NULL,
              created_at INTEGER NOT NULL,
              name TEXT NULL,
              note TEXT NULL,
              address TEXT NULL,
              source_url TEXT NULL,
              category TEXT NOT NULL DEFAULT 'standard',
              folder_id TEXT NOT NULL,
              color TEXT NULL,
              PRIMARY KEY (id)
            )
          ''');
          raw.execute(
            "INSERT INTO pins VALUES ('a', 50.06, 19.94, 1792886400, 'Wawel', NULL, NULL, "
            "'https://maps.app.goo.gl/abc', 'castle', 'f1', 'red')",
          );
          raw.execute('PRAGMA user_version = 7');
        },
      ),
    );
    addTearDown(db.close);

    final pin = await PinsRepository(db).findById('a');
    expect(pin?.name, 'Wawel');
    expect(pin?.sourceUrl, 'https://maps.app.goo.gl/abc');
    expect(pin?.kind, const PinKind(PlaceType.castle));
    expect(pin?.color, PinColor.red);
    expect(pin?.poiName, isNull);
  });

  test(
    'aktualizacja ze schematu 8 dodaje oznaczenie „nieodwiedzona” (v21)',
    () async {
      final db = AppDatabase(
        NativeDatabase.memory(
          setup: (raw) {
            raw.execute('''
            CREATE TABLE folders (
              id TEXT NOT NULL,
              name TEXT NOT NULL,
              description TEXT NULL,
              icon TEXT NOT NULL,
              color TEXT NOT NULL,
              created_at INTEGER NOT NULL,
              updated_at_ms INTEGER NOT NULL,
              PRIMARY KEY (id)
            )
          ''');
            raw.execute(
              "INSERT INTO folders VALUES ('f1', 'Kraków', NULL, 'camper', 'emerald', 1792886400, 1792886400000)",
            );
            raw.execute('''
            CREATE TABLE pins (
              id TEXT NOT NULL,
              lat REAL NOT NULL,
              lng REAL NOT NULL,
              created_at INTEGER NOT NULL,
              name TEXT NULL,
              note TEXT NULL,
              address TEXT NULL,
              source_url TEXT NULL,
              category TEXT NOT NULL DEFAULT 'standard',
              folder_id TEXT NOT NULL,
              color TEXT NULL,
              poi_name TEXT NULL,
              PRIMARY KEY (id)
            )
          ''');
            raw.execute(
              "INSERT INTO pins VALUES ('a', 50.06, 19.94, 1792886400, 'Wawel', NULL, NULL, "
              "NULL, 'castle', 'f1', 'red', 'Wawel Royal Castle')",
            );
            raw.execute('PRAGMA user_version = 8');
          },
        ),
      );
      addTearDown(db.close);

      final repository = PinsRepository(db);
      final pin = await repository.findById('a');
      expect(pin?.name, 'Wawel');
      expect(pin?.poiName, 'Wawel Royal Castle');
      expect(pin?.visitedAt, isNull);

      final at = DateTime(2026, 11, 4, 12, 30);
      await repository.setVisitedAt('a', at);
      expect((await repository.findById('a'))?.visitedAt, at);
    },
  );

  test('aktualizacja ze schematu 9 dodaje pinezki bez gwiazdki (v22)', () async {
    final db = AppDatabase(
      NativeDatabase.memory(
        setup: (raw) {
          raw.execute('''
            CREATE TABLE folders (
              id TEXT NOT NULL,
              name TEXT NOT NULL,
              description TEXT NULL,
              icon TEXT NOT NULL,
              color TEXT NOT NULL,
              created_at INTEGER NOT NULL,
              updated_at_ms INTEGER NOT NULL,
              PRIMARY KEY (id)
            )
          ''');
          raw.execute(
            "INSERT INTO folders VALUES ('f1', 'Kraków', NULL, 'camper', 'emerald', 1792886400, 1792886400000)",
          );
          raw.execute('''
            CREATE TABLE pins (
              id TEXT NOT NULL,
              lat REAL NOT NULL,
              lng REAL NOT NULL,
              created_at INTEGER NOT NULL,
              name TEXT NULL,
              note TEXT NULL,
              address TEXT NULL,
              source_url TEXT NULL,
              category TEXT NOT NULL DEFAULT 'standard',
              folder_id TEXT NOT NULL,
              color TEXT NULL,
              poi_name TEXT NULL,
              visited_at_ms INTEGER NULL,
              PRIMARY KEY (id)
            )
          ''');
          raw.execute(
            "INSERT INTO pins VALUES ('a', 50.06, 19.94, 1792886400, 'Wawel', NULL, NULL, "
            "NULL, 'castle', 'f1', 'red', 'Wawel Royal Castle', 1792886400000)",
          );
          raw.execute('PRAGMA user_version = 9');
        },
      ),
    );
    addTearDown(db.close);

    final repository = PinsRepository(db);
    final pin = await repository.findById('a');
    expect(pin?.name, 'Wawel');
    expect(pin?.visited, isTrue);
    expect(pin?.starred, isFalse);

    await repository.setStarred('a', starred: true);
    expect((await repository.findById('a'))?.starred, isTrue);
  });

  test('aktualizacja ze schematu 10 zostawia foldery bieżące (v23)', () async {
    final db = AppDatabase(
      NativeDatabase.memory(
        setup: (raw) {
          raw.execute('''
            CREATE TABLE folders (
              id TEXT NOT NULL,
              name TEXT NOT NULL,
              description TEXT NULL,
              icon TEXT NOT NULL,
              color TEXT NOT NULL,
              created_at INTEGER NOT NULL,
              updated_at_ms INTEGER NOT NULL,
              PRIMARY KEY (id)
            )
          ''');
          raw.execute(
            "INSERT INTO folders VALUES ('f1', 'Kraków', 'Opis', 'castle', 'amber', 1792886400, 1792886400000)",
          );
          raw.execute('''
            CREATE TABLE pins (
              id TEXT NOT NULL,
              lat REAL NOT NULL,
              lng REAL NOT NULL,
              created_at INTEGER NOT NULL,
              name TEXT NULL,
              note TEXT NULL,
              address TEXT NULL,
              source_url TEXT NULL,
              category TEXT NOT NULL DEFAULT 'standard',
              folder_id TEXT NOT NULL,
              color TEXT NULL,
              poi_name TEXT NULL,
              visited_at_ms INTEGER NULL,
              starred INTEGER NOT NULL DEFAULT 0,
              PRIMARY KEY (id)
            )
          ''');
          raw.execute(
            "INSERT INTO pins VALUES ('a', 50.06, 19.94, 1792886400, 'Wawel', NULL, NULL, "
            "NULL, 'castle', 'f1', NULL, NULL, NULL, 1)",
          );
          raw.execute('PRAGMA user_version = 10');
        },
      ),
    );
    addTearDown(db.close);

    final folders = FoldersRepository(db);
    final folder = (await folders.watchAll().first).single;
    expect(folder.name, 'Kraków');
    expect(folder.description, 'Opis');
    expect(folder.pinCount, 1);
    expect(folder.isArchived, isFalse);
    expect((await PinsRepository(db).watchActive().first).single.name, 'Wawel');

    final at = DateTime.fromMillisecondsSinceEpoch(1792886500000);
    await folders.setArchiveState('f1', archivedAt: at, updatedAt: at);
    expect((await folders.findById('f1'))?.archivedAt, at);
  });
}
