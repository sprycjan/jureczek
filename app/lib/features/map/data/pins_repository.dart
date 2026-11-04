import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../domain/pin_kind.dart';
import '../domain/pin_color.dart';
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

  /// Zapisuje pinezkę i podnosi jej folder na górę listy.
  Future<void> insert(PlacePin pin) {
    return _db.transaction(() async {
      await _db
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
              poiName: Value(pin.poiName),
              category: Value(pin.kind.key),
              color: Value(pin.color?.key),
              folderId: pin.folderId,
              visitedAtMs: Value(pin.visitedAt?.millisecondsSinceEpoch),
              starred: Value(pin.starred),
            ),
          );
      await _touchFolder(pin.folderId, DateTime.now());
    });
  }

  /// Zapisuje dane pinezki; [kind] i [folderId] tylko gdy podane.
  /// Kolor idzie razem z typem (wygląd pinezki): przy podanym [kind]
  /// zapisywany jest też [color], a `null` przywraca kolor kategorii.
  /// Folder przed i po zmianie idzie na górę listy, docelowy najwyżej.
  Future<void> updateDetails(
    String id, {
    String? name,
    String? note,
    String? address,
    PinKind? kind,
    PinColor? color,
    String? folderId,
  }) {
    return _db.transaction(() async {
      final before = await findById(id);
      if (before == null) return;
      await (_db.update(_db.pins)..where((t) => t.id.equals(id))).write(
        PinsCompanion(
          name: Value(name),
          note: Value(note),
          address: Value(address),
          category: kind == null ? const Value.absent() : Value(kind.key),
          color: kind == null ? const Value.absent() : Value(color?.key),
          folderId: folderId == null ? const Value.absent() : Value(folderId),
        ),
      );
      final now = DateTime.now();
      await _touchFolder(before.folderId, now);
      if (folderId != null && folderId != before.folderId) {
        await _touchFolder(folderId, now.add(const Duration(milliseconds: 1)));
      }
    });
  }

  /// Oznacza pinezkę jako odwiedzoną w chwili [at]; `null` zdejmuje oznaczenie.
  /// Folder pinezki idzie na górę listy.
  Future<void> setVisitedAt(String id, DateTime? at) {
    return _db.transaction(() async {
      final pin = await findById(id);
      if (pin == null) return;
      await (_db.update(_db.pins)..where((t) => t.id.equals(id))).write(
        PinsCompanion(visitedAtMs: Value(at?.millisecondsSinceEpoch)),
      );
      await _touchFolder(pin.folderId, DateTime.now());
    });
  }

  /// Ustawia albo zdejmuje gwiazdkę. Folder pinezki idzie na górę listy.
  Future<void> setStarred(String id, {required bool starred}) {
    return _db.transaction(() async {
      final pin = await findById(id);
      if (pin == null) return;
      await (_db.update(_db.pins)..where((t) => t.id.equals(id))).write(
        PinsCompanion(starred: Value(starred)),
      );
      await _touchFolder(pin.folderId, DateTime.now());
    });
  }

  Future<void> _touchFolder(String id, DateTime at) {
    return (_db.update(_db.folders)..where((t) => t.id.equals(id))).write(
      FoldersCompanion(updatedAtMs: Value(at.millisecondsSinceEpoch)),
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
    folderId: row.folderId,
    name: row.name,
    note: row.note,
    address: row.address,
    sourceUrl: row.sourceUrl,
    poiName: row.poiName,
    kind: PinKind.fromKey(row.category),
    color: PinColor.fromKey(row.color),
    visitedAt: row.visitedAtMs == null
        ? null
        : DateTime.fromMillisecondsSinceEpoch(row.visitedAtMs!),
    starred: row.starred,
  );
}

final pinsRepositoryProvider = Provider<PinsRepository>(
  (ref) => PinsRepository(ref.watch(appDatabaseProvider)),
);
