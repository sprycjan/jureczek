import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../domain/place_pin.dart';

/// Zapis i odczyt pinezek z lokalnej bazy.
class PinsRepository {
  PinsRepository(this._db);

  final AppDatabase _db;

  /// Wszystkie pinezki od najstarszej; emituje po każdej zmianie.
  Stream<List<PlacePin>> watchAll() {
    final query = _db.select(_db.pins)
      ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]);
    return query.watch().map((rows) => rows.map(_toDomain).toList());
  }

  Future<PlacePin?> findById(String id) async {
    final query = _db.select(_db.pins)..where((t) => t.id.equals(id));
    final row = await query.getSingleOrNull();
    return row == null ? null : _toDomain(row);
  }

  Future<void> insert(PlacePin pin) {
    return _db
        .into(_db.pins)
        .insert(
          PinsCompanion.insert(
            id: pin.id,
            lat: pin.lat,
            lng: pin.lng,
            createdAt: pin.createdAt,
            name: Value(pin.name),
            note: Value(pin.note),
            address: Value(pin.address),
            sourceUrl: Value(pin.sourceUrl),
          ),
        );
  }

  Future<void> updateDetails(
    String id, {
    String? name,
    String? note,
    String? address,
  }) {
    return (_db.update(_db.pins)..where((t) => t.id.equals(id))).write(
      PinsCompanion(
        name: Value(name),
        note: Value(note),
        address: Value(address),
      ),
    );
  }

  Future<void> delete(String id) {
    return (_db.delete(_db.pins)..where((t) => t.id.equals(id))).go();
  }

  static PlacePin _toDomain(PinRow row) => PlacePin(
    id: row.id,
    lat: row.lat,
    lng: row.lng,
    createdAt: row.createdAt,
    name: row.name,
    note: row.note,
    address: row.address,
    sourceUrl: row.sourceUrl,
  );
}

final pinsRepositoryProvider = Provider<PinsRepository>(
  (ref) => PinsRepository(ref.watch(appDatabaseProvider)),
);
