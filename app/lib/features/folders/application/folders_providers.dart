import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../data/folders_repository.dart';
import '../domain/trip_folder.dart';

/// Foldery od ostatnio zmienionego, z liczbą pinezek.
final foldersProvider = StreamProvider<List<TripFolder>>(
  (ref) => ref.watch(foldersRepositoryProvider).watchAll(),
);

/// Akcje na folderach. Folderów się nie usuwa (decyzja v10).
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

  /// Id folderu „Pinezki”; tworzy go przy pierwszym użyciu (v10, leniwie).
  Future<String> ensureDefault() async {
    final existing = await _repository.findByName(TripFolder.defaultName);
    return existing?.id ?? create(name: TripFolder.defaultName);
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
