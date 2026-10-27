import 'package:flutter/foundation.dart';

/// Miejsce zaznaczone na mapie: pozycja, data dodania, nazwa, notatka,
/// adres i link źródłowy (v5).
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

  static const maxNameLength = 80;
  static const maxNoteLength = 1000;
  static const maxAddressLength = 200;
}
