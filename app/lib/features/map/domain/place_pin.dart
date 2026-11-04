import 'package:flutter/foundation.dart';

import 'pin_kind.dart';
import 'pin_color.dart';

/// Miejsce zaznaczone na mapie: pozycja, data dodania, nazwa, notatka,
/// adres i link źródłowy (v5), typ pinezki (v9, typy miejsc od v16), folder (v10), kolor (v14).
@immutable
class PlacePin {
  const PlacePin({
    required this.id,
    required this.lat,
    required this.lng,
    required this.createdAt,
    required this.folderId,
    this.name,
    this.note,
    this.address,
    this.sourceUrl,
    this.poiName,
    this.kind = PinKind.standard,
    this.color,
  });

  final String id;
  final double lat;
  final double lng;
  final DateTime createdAt;

  /// Folder pinezki (v10) – każda pinezka należy do dokładnie jednego.
  final String folderId;

  /// Opcjonalne; `null` oznacza brak (nigdy pusty tekst).
  final String? name;
  final String? note;
  final String? address;

  /// Link, z którego udostępniono miejsce (np. `maps.app.goo.gl`); tylko do odczytu.
  final String? sourceUrl;

  /// Oryginalna nazwa POI (v19) do wyszukania w Google Maps; nie zmienia się
  /// razem z [name]. `null` – pinezka nie pochodzi z POI.
  final String? poiName;

  /// Typ (v16): zielona „Pinezka” albo typ miejsca.
  final PinKind kind;

  /// Własny kolor (v14); `null` – kolor typu.
  final PinColor? color;

  static const maxNameLength = 80;
  static const maxNoteLength = 1000;
  static const maxAddressLength = 200;
}
