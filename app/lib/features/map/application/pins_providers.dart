import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../data/pins_repository.dart';
import '../domain/place_pin.dart';

/// Pinezki z bazy – jedyne źródło prawdy dla mapy.
final pinsProvider = StreamProvider<List<PlacePin>>(
  (ref) => ref.watch(pinsRepositoryProvider).watchAll(),
);

/// Akcje na pinezkach. Zmiany wracają do UI przez [pinsProvider].
class PinsController {
  PinsController(this._repository);

  final PinsRepository _repository;
  static const _uuid = Uuid();

  /// Teksty jak w [updateDetails]: obcięte, puste to `null`.
  Future<void> add({
    required double lat,
    required double lng,
    String? name,
    String? note,
    String? address,
    String? sourceUrl,
  }) {
    return _repository.insert(
      PlacePin(
        id: _uuid.v4(),
        lat: lat,
        lng: lng,
        createdAt: DateTime.now(),
        name: _normalize(name),
        note: _normalize(note),
        address: _normalize(address),
        sourceUrl: _normalize(sourceUrl),
      ),
    );
  }

  /// Usuwa pinezkę i zwraca ją, żeby dało się cofnąć przez [restore].
  Future<PlacePin?> remove(String id) async {
    final pin = await _repository.findById(id);
    if (pin == null) return null;
    await _repository.delete(id);
    return pin;
  }

  Future<void> restore(PlacePin pin) => _repository.insert(pin);

  /// Zapisuje nazwę, notatkę i adres; białe znaki na brzegach są obcinane, a pusty tekst to `null`.
  Future<void> updateDetails(
    String id, {
    String? name,
    String? note,
    String? address,
  }) {
    return _repository.updateDetails(
      id,
      name: _normalize(name),
      note: _normalize(note),
      address: _normalize(address),
    );
  }

  static String? _normalize(String? text) {
    final trimmed = text?.trim();
    return (trimmed == null || trimmed.isEmpty) ? null : trimmed;
  }
}

final pinsControllerProvider = Provider<PinsController>(
  (ref) => PinsController(ref.watch(pinsRepositoryProvider)),
);
