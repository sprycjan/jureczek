import 'place_suggestion.dart';

/// Miejsce z klikniętego POI stylu Standard.
///
/// Współrzędne czytamy wprost z GeoJSON-a: getter `coordinate` w pluginie 3.33
/// rzutuje listę `[lng, lat]` na `Point` i rzuca wyjątek, który ginie po cichu.
PlaceResult? placeFromPoi({
  required String? name,
  required Map<String?, Object?> geometry,
}) {
  final coordinates = geometry['coordinates'];
  if (coordinates is! List || coordinates.length < 2) return null;
  final [lng, lat, ...] = coordinates;
  if (lng is! num || lat is! num) return null;
  return PlaceResult(name: name, lat: lat.toDouble(), lng: lng.toDouble());
}
