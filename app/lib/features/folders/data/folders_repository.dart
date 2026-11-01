import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../domain/trip_folder.dart';

/// Zapis i odczyt folderów z lokalnej bazy.
class FoldersRepository {
  FoldersRepository(this._db);

  final AppDatabase _db;

  /// Foldery od ostatnio zmienionego, z liczbą pinezek; emituje po zmianie folderów lub pinezek.
  Stream<List<TripFolder>> watchAll() {
    return _db
        .customSelect(
          'SELECT f.*, '
          '(SELECT COUNT(*) FROM pins p WHERE p.folder_id = f.id) AS pin_count '
          'FROM folders f ORDER BY f.updated_at_ms DESC',
          readsFrom: {_db.folders, _db.pins},
        )
        .watch()
        .map(
          (rows) => [
            for (final row in rows)
              _toDomain(
                _db.folders.map(row.data),
                pinCount: row.read<int>('pin_count'),
              ),
          ],
        );
  }

  Future<TripFolder?> findById(String id) async {
    final query = _db.select(_db.folders)..where((t) => t.id.equals(id));
    final row = await query.getSingleOrNull();
    return row == null ? null : _toDomain(row);
  }

  Future<TripFolder?> findByName(String name) async {
    final query = _db.select(_db.folders)
      ..where((t) => t.name.equals(name))
      ..orderBy([(t) => OrderingTerm.asc(t.createdAt)])
      ..limit(1);
    final row = await query.getSingleOrNull();
    return row == null ? null : _toDomain(row);
  }

  Future<void> insert(TripFolder folder) {
    return _db
        .into(_db.folders)
        .insert(
          FoldersCompanion.insert(
            id: folder.id,
            name: folder.name,
            description: Value(folder.description),
            icon: folder.icon.key,
            color: folder.color.key,
            createdAt: folder.createdAt,
            updatedAtMs: folder.updatedAt.millisecondsSinceEpoch,
          ),
        );
  }

  Future<void> update(TripFolder folder) {
    return (_db.update(
      _db.folders,
    )..where((t) => t.id.equals(folder.id))).write(
      FoldersCompanion(
        name: Value(folder.name),
        description: Value(folder.description),
        icon: Value(folder.icon.key),
        color: Value(folder.color.key),
        updatedAtMs: Value(folder.updatedAt.millisecondsSinceEpoch),
      ),
    );
  }

  static TripFolder _toDomain(FolderRow row, {int pinCount = 0}) => TripFolder(
    id: row.id,
    name: row.name,
    description: row.description,
    icon: FolderIcon.fromKey(row.icon),
    color: FolderColor.fromKey(row.color),
    createdAt: row.createdAt,
    updatedAt: DateTime.fromMillisecondsSinceEpoch(row.updatedAtMs),
    pinCount: pinCount,
  );
}

final foldersRepositoryProvider = Provider<FoldersRepository>(
  (ref) => FoldersRepository(ref.watch(appDatabaseProvider)),
);
