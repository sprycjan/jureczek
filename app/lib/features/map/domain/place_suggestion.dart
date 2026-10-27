import 'package:flutter/foundation.dart';

/// Punkt na mapie w stopniach.
typedef LatLng = ({double lat, double lng});

/// Podpowiedź z wyszukiwarki – jeszcze bez współrzędnych.
@immutable
class PlaceSuggestion {
  const PlaceSuggestion({
    required this.mapboxId,
    required this.name,
    this.address,
    this.featureType,
  });

  final String mapboxId;
  final String name;

  /// Druga linia podpowiedzi; `null`, gdy Mapbox jej nie podał.
  final String? address;

  /// Typ obiektu z Mapboxa, np. `poi`, `address`, `street`.
  final String? featureType;
}

/// Wybrane miejsce ze współrzędnymi, gotowe do postawienia pinezki
/// (z wyszukiwarki albo z udostępnienia).
@immutable
class PlaceResult {
  const PlaceResult({
    required this.name,
    required this.lat,
    required this.lng,
    this.address,
    this.sourceUrl,
    this.approximate = false,
  });

  /// `null`, gdy miejsce nie ma nazwy.
  final String? name;
  final String? address;
  final double lat;
  final double lng;

  /// Link, z którego udostępniono miejsce.
  final String? sourceUrl;

  /// Położenie wyznaczone geokodowaniem nazwy lub adresu – może być obok.
  final bool approximate;

  /// Ten sam wynik w poprawionym miejscu.
  PlaceResult movedTo(LatLng point) => PlaceResult(
    name: name,
    lat: point.lat,
    lng: point.lng,
    address: address,
    sourceUrl: sourceUrl,
  );
}
