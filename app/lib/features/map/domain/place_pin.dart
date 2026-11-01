import 'package:flutter/foundation.dart';

import 'pin_category.dart';

/// Miejsce zaznaczone na mapie: pozycja, data dodania, nazwa, notatka,
/// adres i link źródłowy (v5), typ pinezki (v9).
@immutable
class PlacePin {
  const PlacePin({
    required this.id,
    required this.lat,
    required this.lng,
    required this.createdAt,
    this.name,
    this.note,
    this.address,
    this.sourceUrl,
    this.category = PinCategory.fallback,
  });

  final String id;
  final double lat;
  final double lng;
  final DateTime createdAt;

  /// Opcjonalne; `null` oznacza brak (nigdy pusty tekst).
  final String? name;
  final String? note;
  final String? address;

  /// Link, z którego udostępniono miejsce (np. `maps.app.goo.gl`); tylko do odczytu.
  final String? sourceUrl;

  final PinCategory category;

  static const maxNameLength = 80;
  static const maxNoteLength = 1000;
  static const maxAddressLength = 200;
}
