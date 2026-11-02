import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jureczek/core/database/app_database.dart';
import 'package:jureczek/features/folders/data/folders_repository.dart';
import 'package:jureczek/features/folders/domain/trip_folder.dart';
import 'package:jureczek/features/map/data/pins_repository.dart';
import 'package:jureczek/features/map/domain/pin_category.dart';
import 'package:jureczek/features/map/domain/pin_color.dart';
import 'package:jureczek/features/map/domain/place_pin.dart';

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
          category: PinCategory.nature,
        ),
      );
      expect((await repository.findById('nowa'))?.category, PinCategory.nature);
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
    expect(pin?.category, PinCategory.places);
    expect(pin?.folderId, folders.single.id);
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
    expect(old?.category, PinCategory.places);
    expect(old?.color, isNull);

    await repository.updateDetails(
      'p1',
      name: 'Wawel',
      category: PinCategory.places,
      color: PinColor.gold,
    );
    expect((await repository.findById('p1'))?.color, PinColor.gold);
  });
}
