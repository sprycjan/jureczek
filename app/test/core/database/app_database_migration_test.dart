import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jureczek/core/database/app_database.dart';
import 'package:jureczek/features/map/data/pins_repository.dart';
import 'package:jureczek/features/map/domain/pin_category.dart';
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
          id: 'nowa',
          lat: 50.06,
          lng: 19.94,
          createdAt: DateTime(2026, 11, 1),
          category: PinCategory.nature,
        ),
      );
      expect(
        (await repository.findById('nowa'))?.category,
        PinCategory.nature,
      );
    },
  );
}
