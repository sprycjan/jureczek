import '../../map/domain/place_suggestion.dart';

/// Plus Code (Open Location Code) – Google dopisuje go do nazwy POI bez adresu,
/// np. „P4R5+JV Miradouro dos Balcões, Ribeiro Frio”. Obsługujemy tylko to, czego
/// potrzebujemy: dekodowanie i odzyskanie krótkiego kodu z punktu odniesienia
/// (algorytm `recoverNearest` ze specyfikacji
/// https://github.com/google/open-location-code/blob/main/Documentation/Specification/specification.md).
class PlusCode {
  PlusCode._(this.code);

  static const _alphabet = '23456789CFGHJMPQRVWX';
  static const _separatorPosition = 8;

  /// Rozdzielczość kolejnych par cyfr w stopniach: 20°, 1°, 0,05°, 0,0025°, 0,000125°.
  static const _pairResolutions = [20.0, 1.0, 0.05, 0.0025, 0.000125];

  static final _pattern = RegExp(
    '^([$_alphabet]{2,8})\\+([$_alphabet]{2,3})\$',
    caseSensitive: false,
  );

  /// Kod wielkimi literami, z `+`.
  final String code;

  /// `null`, gdy tekst nie jest kodem (albo ma dopełnienie `0`, którego nie obsługujemy).
  static PlusCode? tryParse(String text) {
    final match = _pattern.firstMatch(text.trim());
    if (match == null) return null;
    final prefix = match[1]!;
    if (prefix.length.isOdd) return null;
    return PlusCode._(text.trim().toUpperCase());
  }

  /// Pełny kod (8 znaków przed `+`) da się zdekodować bez punktu odniesienia.
  bool get isFull => code.indexOf('+') == _separatorPosition;

  /// Środek obszaru pełnego kodu (~14 m przy 10 znakach).
  LatLng decode() {
    assert(isFull, 'Krótki kod wymaga punktu odniesienia');
    final digits = code.replaceFirst('+', '');
    var lat = -90.0;
    var lng = -180.0;
    var resolution = _pairResolutions.first;
    for (var i = 0; i + 1 < digits.length && i < 10; i += 2) {
      resolution = _pairResolutions[i ~/ 2];
      lat += _alphabet.indexOf(digits[i]) * resolution;
      lng += _alphabet.indexOf(digits[i + 1]) * resolution;
    }
    return (lat: lat + resolution / 2, lng: lng + resolution / 2);
  }

  /// Punkt krótkiego kodu najbliższy [reference]. Wynik leży zawsze w odległości
  /// pół komórki (dla 4 znaków przed `+` to ±0,5°) od odniesienia – nawet gdy
  /// odniesienie jest złe, więc wynik trzeba sprawdzić.
  LatLng recoverNearest(LatLng reference) {
    if (isFull) return decode();
    final padding = _separatorPosition - code.indexOf('+');
    final resolution = _pairResolutions[padding ~/ 2 - 1];
    final half = resolution / 2;

    final full = PlusCode._(_prefix(reference, padding) + code);
    var (:lat, :lng) = full.decode();
    if (reference.lat + half < lat && lat - resolution >= -90) {
      lat -= resolution;
    } else if (reference.lat - half > lat && lat + resolution <= 90) {
      lat += resolution;
    }
    if (reference.lng + half < lng) {
      lng -= resolution;
    } else if (reference.lng - half > lng) {
      lng += resolution;
    }
    return (lat: lat, lng: lng);
  }

  /// Pierwsze [length] znaków kodu punktu.
  static String _prefix(LatLng point, int length) {
    var lat = (point.lat.clamp(-90.0, 90.0) + 90).clamp(0.0, 179.999999);
    var lng = (point.lng + 180) % 360;
    final buffer = StringBuffer();
    for (var i = 0; i < length ~/ 2; i++) {
      final resolution = _pairResolutions[i];
      final latDigit = (lat / resolution).floor().clamp(0, 19);
      final lngDigit = (lng / resolution).floor().clamp(0, 19);
      buffer
        ..write(_alphabet[latDigit])
        ..write(_alphabet[lngDigit]);
      lat -= latDigit * resolution;
      lng -= lngDigit * resolution;
    }
    return buffer.toString();
  }
}
