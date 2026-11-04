import 'dart:ui';

/// Własny kolor pinezki (v14): 24 gotowe kolory. Bez koloru (`null` w
/// [PlacePin.color]) pinezka ma kolor swojej kategorii.
///
/// [key] trafia do bazy – nie zmieniać istniejących wartości.
enum PinColor {
  red('red', Color(0xFFD32F2F)),
  raspberry('raspberry', Color(0xFFC2185B)),
  rose('rose', Color(0xFFEC407A)),
  coral('coral', Color(0xFFFF7043)),
  orange('orange', Color(0xFFE65100)),
  amber('amber', Color(0xFFFF8F00)),
  gold('gold', Color(0xFFF9A825)),
  olive('olive', Color(0xFF827717)),
  lime('lime', Color(0xFF7CB342)),
  green('green', Color(0xFF2E7D32)),
  mint('mint', Color(0xFF52A378)),
  teal('teal', Color(0xFF00897B)),
  cyan('cyan', Color(0xFF00838F)),
  sky('sky', Color(0xFF039BE5)),
  blue('blue', Color(0xFF1565C0)),
  navy('navy', Color(0xFF283593)),
  violet('violet', Color(0xFF5E35B1)),
  purple('purple', Color(0xFF7B1FA2)),
  orchid('orchid', Color(0xFFAB47BC)),
  brown('brown', Color(0xFF6D4C41)),
  sand('sand', Color(0xFFA1887F)),
  slate('slate', Color(0xFF455A64)),
  graphite('graphite', Color(0xFF616161)),
  black('black', Color(0xFF212121));

  const PinColor(this.key, this.color);

  final String key;
  final Color color;

  /// Nieznany klucz to brak własnego koloru, a nie błąd.
  static PinColor? fromKey(String? key) {
    for (final value in values) {
      if (value.key == key) return value;
    }
    return null;
  }
}
