import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../data/folders_repository.dart';
import '../domain/trip_folder.dart';

/// Wszystkie foldery, także z archiwum, od ostatnio zmienionego, z liczbą pinezek.
final foldersProvider = StreamProvider<List<TripFolder>>(
  (ref) => ref.watch(foldersRepositoryProvider).watchAll(),
);

/// Foldery bieżące w kolejności [foldersProvider].
final activeFoldersProvider = Provider<AsyncValue<List<TripFolder>>>(
  (ref) => ref
      .watch(foldersProvider)
      .whenData((all) => [...all.where((f) => !f.isArchived)]),
);

/// Akcje na folderach. Folderów się nie usuwa (decyzja v10), można je zarchiwizować (v23).
class FoldersController {
  FoldersController(this._repository);

  final FoldersRepository _repository;
  static const _uuid = Uuid();

  /// Zwraca id nowego folderu. Nazwa jest obcinana; opis pusty to `null`.
  Future<String> create({
    required String name,
    String? description,
    FolderIcon icon = FolderIcon.camper,
    FolderColor color = FolderColor.emerald,
  }) async {
    final id = _uuid.v4();
    final now = DateTime.now();
    await _repository.insert(
      TripFolder(
        id: id,
        name: _name(name),
        description: _normalize(description),
        icon: icon,
        color: color,
        createdAt: now,
        updatedAt: now,
      ),
    );
    return id;
  }

  Future<void> update(
    TripFolder folder, {
    required String name,
    String? description,
    required FolderIcon icon,
    required FolderColor color,
  }) {
    return _repository.update(
      TripFolder(
        id: folder.id,
        name: _name(name),
        description: _normalize(description),
        icon: icon,
        color: color,
        createdAt: folder.createdAt,
        updatedAt: DateTime.now(),
      ),
    );
  }

  /// Id bieżącego folderu „Pinezki”; tworzy go przy pierwszym użyciu (v10,
  /// leniwie) i gdy dotychczasowy jest w archiwum (v23).
  Future<String> ensureDefault() async {
    final existing = await _repository.findActiveByName(TripFolder.defaultName);
    return existing?.id ?? create(name: TripFolder.defaultName);
  }

  /// Przenosi folder do archiwum; miejsce na liście bieżącej zostaje na „Cofnij”.
  Future<void> archive(TripFolder folder) {
    return _repository.setArchiveState(
      folder.id,
      archivedAt: DateTime.now(),
      updatedAt: folder.updatedAt,
    );
  }

  /// Przywraca folder z archiwum na górę listy bieżącej.
  Future<void> restore(TripFolder folder) {
    return _repository.setArchiveState(
      folder.id,
      archivedAt: null,
      updatedAt: DateTime.now(),
    );
  }

  /// „Cofnij”: wraca do stanu archiwum i miejsca na liście sprzed zmiany.
  Future<void> undoArchiveChange(TripFolder before) {
    return _repository.setArchiveState(
      before.id,
      archivedAt: before.archivedAt,
      updatedAt: before.updatedAt,
    );
  }

  static String _name(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) throw ArgumentError.value(name, 'name', 'pusta');
    return trimmed;
  }

  static String? _normalize(String? text) {
    final trimmed = text?.trim();
    return (trimmed == null || trimmed.isEmpty) ? null : trimmed;
  }
}

final foldersControllerProvider = Provider<FoldersController>(
  (ref) => FoldersController(ref.watch(foldersRepositoryProvider)),
);
