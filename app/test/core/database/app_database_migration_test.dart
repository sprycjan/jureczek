import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jureczek/core/database/app_database.dart';
import 'package:jureczek/features/map/data/pins_repository.dart';

void main() {
  test(
    'migracja 1 → 2 zachowuje pinezki i dodaje puste nazwę i notatkę',
    () async {
      // Baza w stanie z v2 aplikacji (schemat 1): bez kolumn name i note.
      final db = AppDatabase(
        NativeDatabase.memory(
          setup: (raw) {
            raw.execute('''
            CREATE TABLE pins (
              id TEXT NOT NULL,
              lat REAL NOT NULL,
              lng REAL NOT NULL,
              created_at INTEGER NOT NULL,
              PRIMARY KEY (id)
            )
          ''');
            raw.execute(
              "INSERT INTO pins VALUES ('stara', 50.06, 19.94, 1792886400)",
            );
            raw.execute('PRAGMA user_version = 1');
          },
        ),
      );
      addTearDown(db.close);
      final repository = PinsRepository(db);

      final old = await repository.findById('stara');
      expect(old?.lat, 50.06);
      expect(
        old?.createdAt,
        DateTime.fromMillisecondsSinceEpoch(1792886400000),
      );
      expect(old?.name, isNull);
      expect(old?.note, isNull);

      await repository.updateDetails('stara', name: 'Wawel', note: 'Bilety');
      expect((await repository.findById('stara'))?.name, 'Wawel');
    },
  );

  test('migracja 2 → 3 zachowuje pinezki i dodaje pusty adres i link', () async {
    // Baza w stanie z v3–v4 aplikacji (schemat 2): bez kolumn address i source_url.
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
              PRIMARY KEY (id)
            )
          ''');
          raw.execute(
            "INSERT INTO pins VALUES ('stara', 50.06, 19.94, 1792886400, 'Wawel', 'Bilety')",
          );
          raw.execute('PRAGMA user_version = 2');
        },
      ),
    );
    addTearDown(db.close);
    final repository = PinsRepository(db);

    final old = await repository.findById('stara');
    expect(old?.name, 'Wawel');
    expect(old?.note, 'Bilety');
    expect(old?.address, isNull);
    expect(old?.sourceUrl, isNull);

    await repository.updateDetails(
      'stara',
      name: 'Wawel',
      note: 'Bilety',
      address: 'Wawel 5, Kraków',
    );
    expect((await repository.findById('stara'))?.address, 'Wawel 5, Kraków');
  });
}
