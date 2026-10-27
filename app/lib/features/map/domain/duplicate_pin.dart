import 'dart:math';

import 'place_pin.dart';
import 'place_suggestion.dart';

/// Promień ikony pinezki na ekranie; bliżej to „to samo miejsce”.
const _duplicateRadiusPx = 24.0;

/// Górny limit progu, żeby przy oddalonej mapie nie łączyć różnych miejsc.
const maxDuplicateMeters = 30.0;

/// Metry na piksel logiczny w Mapboxie (kafel 512 px) przy danym zoomie i szerokości.
double metersPerPixel(double lat, double zoom) =>
    78271.517 * cos(lat * pi / 180) / pow(2, zoom);

/// Próg duplikatu: [_duplicateRadiusPx] w metrach przy [zoom], najwyżej [maxDuplicateMeters].
double duplicateThresholdMeters(double lat, double zoom) =>
    min(_duplicateRadiusPx * metersPerPixel(lat, zoom), maxDuplicateMeters);

/// Odległość po kuli (wzór haversine'a) w metrach.
double distanceMeters(LatLng a, LatLng b) {
  const earthRadius = 6371000.0;
  double rad(double deg) => deg * pi / 180;
  final dLat = rad(b.lat - a.lat);
  final dLng = rad(b.lng - a.lng);
  final h =
      pow(sin(dLat / 2), 2) +
      cos(rad(a.lat)) * cos(rad(b.lat)) * pow(sin(dLng / 2), 2);
  return 2 * earthRadius * asin(sqrt(h));
}

/// Najbliższa pinezka nie dalej niż [maxMeters] od [point] albo `null`.
PlacePin? nearestPinWithin(
  Iterable<PlacePin> pins,
  LatLng point,
  double maxMeters,
) {
  PlacePin? nearest;
  var best = double.infinity;
  for (final pin in pins) {
    final d = distanceMeters(point, (lat: pin.lat, lng: pin.lng));
    if (d <= maxMeters && d < best) {
      best = d;
      nearest = pin;
    }
  }
  return nearest;
}
