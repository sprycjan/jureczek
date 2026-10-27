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
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        await m.addColumn(pins, pins.name);
        await m.addColumn(pins, pins.note);
      }
      if (from < 3) {
        await m.addColumn(pins, pins.address);
        await m.addColumn(pins, pins.sourceUrl);
      }
    },
  );
}

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase.defaults();
  ref.onDispose(db.close);
  return db;
});
