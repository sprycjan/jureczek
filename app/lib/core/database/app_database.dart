import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../features/folders/data/folders_table.dart';
import '../../features/folders/domain/trip_folder.dart';
import '../../features/map/data/pins_table.dart';

part 'app_database.g.dart';

/// Lokalna baza aplikacji (SQLite przez drift) – ADR-005.
@DriftDatabase(tables: [Pins, Folders])
class AppDatabase extends _$AppDatabase {
  /// Do testów, np. `AppDatabase(NativeDatabase.memory())`.
  AppDatabase(super.e);

  AppDatabase.defaults() : super(driftDatabase(name: 'jureczek'));

  @override
  int get schemaVersion => 9;

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
        return;
      }
      if (from < 5) {
        // Przebudowa tabeli w _addFolders tworzy ją od razu w bieżącym
        // schemacie, razem z kolumnami koloru (6), nazwy POI (8) i odwiedzenia (9).
        await _addFolders(m);
      } else {
        if (from < 6) await m.addColumn(pins, pins.color);
        if (from < 8) await m.addColumn(pins, pins.poiName);
        if (from < 9) await m.addColumn(pins, pins.visitedAtMs);
      }
      if (from < 7) {
        // v16: typy miejsc zamiast kategorii v9 – pinezka kategorii dostaje
        // typ „inne” tej kategorii (np. `gastronomy` → `gastronomy_other`).
        await customStatement(
          "UPDATE pins SET category = category || '_other' "
          'WHERE category IN ($_v9Categories)',
        );
      }
    },
  );

  /// Klucze 7 kategorii v9 (bez `standard`) jako lista SQL.
  static const _v9Categories =
      "'gastronomy', 'places', 'nature', 'activities', 'travel', "
      "'entertainment', 'practical'";

  /// v10: tabela folderów i obowiązkowe `folder_id` w pinezkach. Istniejące
  /// pinezki trafiają do folderu „Pinezki”, tworzonego tylko wtedy, gdy jakieś są.
  Future<void> _addFolders(Migrator m) async {
    await m.createTable(folders);
    final count = await customSelect(
      'SELECT COUNT(*) AS c FROM pins',
    ).map((row) => row.read<int>('c')).getSingle();
    var folderId = '';
    if (count > 0) {
      folderId = const Uuid().v4();
      final now = DateTime.now();
      await into(folders).insert(
        FoldersCompanion.insert(
          id: folderId,
          name: TripFolder.defaultName,
          icon: FolderIcon.camper.key,
          color: FolderColor.emerald.key,
          createdAt: now,
          updatedAtMs: now.millisecondsSinceEpoch,
        ),
      );
    }
    await m.alterTable(
      TableMigration(
        pins,
        newColumns: [pins.folderId, pins.color, pins.poiName, pins.visitedAtMs],
        columnTransformer: {
          pins.folderId: Constant(folderId),
          pins.color: const Constant<String>(null),
          pins.poiName: const Constant<String>(null),
          pins.visitedAtMs: const Constant<int>(null),
        },
      ),
    );
  }
}

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase.defaults();
  ref.onDispose(db.close);
  return db;
});
