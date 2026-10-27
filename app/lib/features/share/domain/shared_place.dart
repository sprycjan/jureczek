import 'package:flutter/foundation.dart';

import '../../map/domain/place_suggestion.dart';
import 'plus_code.dart';

/// Tekst udostępniony z innej aplikacji (`EXTRA_TEXT` i `EXTRA_SUBJECT`).
typedef SharedText = ({String text, String? subject});

/// To, co da się odczytać z udostępnienia bez sieci (albo po rozwinięciu linku).
@immutable
class SharedPlaceInfo {
  const SharedPlaceInfo({this.point, this.name, this.address, this.plusCode});

  /// `null`, gdy link go nie zawiera (udostępnienie POI z aplikacji Google Maps).
  final LatLng? point;
  final String? name;
  final String? address;

  /// Krótki Plus Code sprzed nazwy POI; punkt da się z niego odzyskać, mając
  /// odniesienie w promieniu ~50 km. Pełny kod trafia od razu do [point].
  final PlusCode? plusCode;
}

final _googleMapsLink = RegExp(
  r'https?://(?:maps\.app\.goo\.gl|goo\.gl/maps|(?:www\.)?google\.[a-z.]+/maps|maps\.google\.[a-z.]+)\S*',
);
final _geoUri = RegExp(
  r'geo:(-?\d+(?:\.\d+)?),(-?\d+(?:\.\d+)?)(?:\?q=([^\s]*))?',
);
final _rawCoordinates = RegExp(
  r'^\s*(-?\d{1,2}\.\d+)\s*,\s*(-?\d{1,3}\.\d+)\s*$',
);

/// Pierwszy link Google Maps w tekście albo `null`.
String? findGoogleMapsLink(String text) => _googleMapsLink.firstMatch(text)?[0];

/// Krótkie linki trzeba rozwinąć przekierowaniem, pełne da się parsować od razu.
bool isShortGoogleLink(String url) {
  final host = Uri.tryParse(url)?.host;
  return host == 'maps.app.goo.gl' || host == 'goo.gl';
}

/// `geo:lat,lng?q=…` albo sam tekst „lat, lng”; `null`, gdy to nie to.
SharedPlaceInfo? parseCoordinatesText(String text) {
  final geo = _geoUri.firstMatch(text);
  if (geo != null) {
    final point = _point(geo[1]!, geo[2]!);
    if (point == null) return null;
    // `geo:0,0?q=…` to samo zapytanie bez pozycji.
    final query = geo[3] == null ? null : Uri.decodeQueryComponent(geo[3]!);
    final hasPoint = point.lat != 0 || point.lng != 0;
    return SharedPlaceInfo(
      point: hasPoint ? point : null,
      name: _geoLabel(query),
    );
  }
  final raw = _rawCoordinates.firstMatch(text);
  if (raw != null) {
    final point = _point(raw[1]!, raw[2]!);
    return point == null ? null : SharedPlaceInfo(point: point);
  }
  return null;
}

/// `50.05,19.93(Wawel)` albo `Wawel` → „Wawel”.
String? _geoLabel(String? query) {
  if (query == null) return null;
  final label = query.replaceFirst(RegExp(r'^\s*-?[\d.]+\s*,\s*-?[\d.]+'), '');
  return _nonEmpty(label.replaceAll(RegExp(r'^\s*\(|\)\s*$'), ''));
}

/// Pełny link Google Maps. Współrzędne miejsca są w `!3d…!4d…` albo w `/search/lat,lng`;
/// `@lat,lng` to pozycja kamery, więc ją pomijamy. `/place/<nazwa, adres>/` daje nazwę i adres,
/// czasem poprzedzone Plus Code (`/place/P4R5+JV Miradouro dos Balcões, Ribeiro Frio, …`).
/// [subject] to nazwa, którą Google Maps wysyła w `EXTRA_SUBJECT`.
SharedPlaceInfo parseGoogleMapsUrl(String url, {String? subject}) {
  final placeData = RegExp(r'!3d(-?\d+\.\d+)!4d(-?\d+\.\d+)').firstMatch(url);
  final search = RegExp(
    r'/maps/search/(-?\d+\.\d+),(?:\+|%20|\s)*(-?\d+\.\d+)',
  ).firstMatch(url);
  final query = Uri.tryParse(url)?.queryParameters['q'];
  final queryPoint = query == null ? null : _rawCoordinates.firstMatch(query);

  final point = placeData != null
      ? _point(placeData[1]!, placeData[2]!)
      : search != null
      ? _point(search[1]!, search[2]!)
      : queryPoint != null
      ? _point(queryPoint[1]!, queryPoint[2]!)
      : null;

  final placeSegment = RegExp(r'/maps/place/([^/?]+)').firstMatch(url)?[1];
  var placeText = placeSegment == null
      ? null
      : _nonEmpty(Uri.decodeQueryComponent(placeSegment));

  PlusCode? plusCode;
  final codeMatch = placeText == null
      ? null
      : RegExp(r'^(\S+\+\S*)(?:\s+|$)').firstMatch(placeText);
  if (codeMatch != null) {
    plusCode = PlusCode.tryParse(codeMatch[1]!);
    if (plusCode != null) {
      placeText = _nonEmpty(placeText!.substring(codeMatch.end));
    }
  }
  final codePoint = plusCode != null && plusCode.isFull
      ? plusCode.decode()
      : null;

  final name = _nonEmpty(subject) ?? placeText?.split(',').first.trim();
  return SharedPlaceInfo(
    point: point ?? codePoint,
    name: name,
    address: placeText == null || name == null
        ? null
        : _addressFrom(placeText, name),
    plusCode: point == null && codePoint == null ? plusCode : null,
  );
}

/// „Galeria Metropolia, Jana Kilińskiego 4, Gdańsk” → reszta po nazwie.
/// Gdy nazwa sama jest adresem (upuszczona pinezka, „Klonowa 01”), adresem jest cały tekst.
String? _addressFrom(String placeText, String name) {
  if (!placeText.startsWith(name)) return placeText;
  final rest = _nonEmpty(
    placeText.substring(name.length).replaceFirst(RegExp(r'^\s*,\s*'), ''),
  );
  if (rest == null) return null;
  return name.contains(RegExp(r'\d')) ? placeText : rest;
}

LatLng? _point(String lat, String lng) {
  final la = double.tryParse(lat);
  final ln = double.tryParse(lng);
  if (la == null || ln == null || la.abs() > 90 || ln.abs() > 180) return null;
  return (lat: la, lng: ln);
}

String? _nonEmpty(String? text) {
  final trimmed = text?.trim();
  return (trimmed == null || trimmed.isEmpty) ? null : trimmed;
}
