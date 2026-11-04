import 'place_pin.dart';

/// Adres, pod którym Google Maps pokaże pinezkę (v19).
///
/// Oryginalny link Google trafia w kartę miejsca. POI bez niego szukamy po nazwie
/// z adresem, bo Mapbox nie daje `place_id` Google. Sprawdzone na telefonie:
/// sama nazwa, nawet ze współrzędnymi, potrafi otworzyć miejsce o tej nazwie
/// koło użytkownika (bazylika z Krakowa w Gdańsku), więc bez adresu zostają
/// współrzędne.
Uri googleMapsUri(PlacePin pin) {
  final source = pin.sourceUrl == null ? null : Uri.tryParse(pin.sourceUrl!);
  if (source != null && (source.isScheme('https') || source.isScheme('http'))) {
    return source;
  }
  final (poiName, address) = (pin.poiName, pin.address);
  if (poiName != null && address != null) {
    final query = Uri.encodeComponent('$poiName, $address');
    return Uri.parse(
      'https://www.google.com/maps/search/$query/@${pin.lat},${pin.lng},17z',
    );
  }
  return Uri.parse(
    'https://www.google.com/maps/search/?api=1&query=${pin.lat},${pin.lng}',
  );
}
