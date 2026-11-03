import 'dart:ui';

/// Kategoria miejsca (v15) – 7 głównych kategorii ze specyfikacji Stitch
/// (`resorces/…/specyfikacja_systemu_ikon_i_pinezek_vanventure_android.md`).
///
/// Jedyne miejsce z tokenami kolorów kategorii w aplikacji. [primary] musi być
/// równy kolorowi w `tool/place_icons.py` (pilnuje `place_icons_test.dart`).
/// [key] to nazwa katalogu w `assets/place_icons/` i klucz zgodny z `PinCategory`.
enum PlaceCategory {
  gastronomy(
    'gastronomy',
    primary: Color(0xFFE65100),
    lightContainer: Color(0xFFFFF3E0),
    darkContainer: Color(0xFFFFB74D),
    onDarkContainer: Color(0xFF2D1600),
  ),
  places(
    'places',
    primary: Color(0xFF1565C0),
    lightContainer: Color(0xFFE3F2FD),
    darkContainer: Color(0xFF90CAF9),
    onDarkContainer: Color(0xFF001E3D),
  ),
  nature(
    'nature',
    primary: Color(0xFF2E7D32),
    lightContainer: Color(0xFFE8F5E9),
    darkContainer: Color(0xFF81C784),
    onDarkContainer: Color(0xFF052E0B),
  ),
  activities(
    'activities',
    primary: Color(0xFF7B1FA2),
    lightContainer: Color(0xFFF3E5F5),
    darkContainer: Color(0xFFCE93D8),
    onDarkContainer: Color(0xFF2A003D),
  ),
  travel(
    'travel',
    primary: Color(0xFF455A64),
    lightContainer: Color(0xFFECEFF1),
    darkContainer: Color(0xFFB0BEC5),
    onDarkContainer: Color(0xFF1A2328),
  ),
  entertainment(
    'entertainment',
    primary: Color(0xFFC2185B),
    lightContainer: Color(0xFFFCE4EC),
    darkContainer: Color(0xFFF48FB1),
    onDarkContainer: Color(0xFF380017),
  ),
  practical(
    'practical',
    primary: Color(0xFF00838F),
    lightContainer: Color(0xFFE0F7FA),
    darkContainer: Color(0xFF4DD0E1),
    onDarkContainer: Color(0xFF00282C),
  );

  const PlaceCategory(
    this.key, {
    required this.primary,
    required this.lightContainer,
    required this.darkContainer,
    required this.onDarkContainer,
  });

  final String key;

  /// Kolor pinezki i samodzielnej ikony.
  final Color primary;

  /// Tło ikony w jasnym motywie (ikona w [primary]).
  final Color lightContainer;

  /// Tło ikony w ciemnym motywie (ikona w [onDarkContainer]).
  final Color darkContainer;
  final Color onDarkContainer;
}
