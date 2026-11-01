import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/map/data/pins_table.dart';

part 'app_database.g.dart';

/// Lokalna baza aplikacji (SQLite przez drift) – ADR-005.
@DriftDatabase(tables: [Pins])
class AppDatabase extends _$AppDatabase {
  /// Do testów, np. `AppDatabase(NativeDatabase.memory())`.
  AppDatabase(super.e);

  AppDatabase.defaults() : super(driftDatabase(name: 'jureczek'));

  @override
  int get schemaVersion => 4;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onUpgrade: (m, from, to) async {
      // v9: świadomy reset – dane testowe sprzed schematu 4 są kasowane
      // (decyzja użytkownika, start od pustej bazy). Od 4 w górę zwykłe migracje.
      if (from < 4) {
        for (final table in allTables) {
          await m.deleteTable(table.actualTableName);
        }
        await m.createAll();
      }
    },
  );
}

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase.defaults();
  ref.onDispose(db.close);
  return db;
});
