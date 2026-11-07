import 'dart:async';

/// Decyduje, kiedy ekran powitalny ma odjechać, i robi to dokładnie raz.
///
/// Warunek: aplikacja gotowa i minimum minęło, albo przekroczony limit. Minimum liczy
/// się od [start] i nie zaczyna się od nowa, cokolwiek przebuduje drzewo widgetów.
class SplashGate {
  SplashGate({required this.minimum, required this.limit, required this.onExit})
    : assert(limit >= minimum);

  final Duration minimum;
  final Duration limit;
  final void Function() onExit;

  Timer? _minimumTimer;
  Timer? _limitTimer;
  bool _ready = false;
  bool _minimumPassed = false;
  bool _timedOut = false;
  bool _exited = false;

  bool get exited => _exited;

  void start() {
    if (_limitTimer != null || _exited) return;
    _minimumTimer = Timer(minimum, () {
      _minimumPassed = true;
      _check();
    });
    _limitTimer = Timer(limit, () {
      _timedOut = true;
      _check();
    });
  }

  /// Aplikacja gotowa; błąd też się liczy, bo pokaże go ekran startowy.
  void markReady() {
    _ready = true;
    _check();
  }

  /// Bez czekania na minimum: stuknięcie, udostępnienie, nieudane wczytanie grafik.
  /// Przed gotowością zostaje zapamiętane.
  void skipMinimum() {
    _minimumPassed = true;
    _check();
  }

  void dispose() {
    _minimumTimer?.cancel();
    _limitTimer?.cancel();
  }

  void _check() {
    if (_exited || !(_timedOut || (_ready && _minimumPassed))) return;
    _exited = true;
    dispose();
    onExit();
  }
}
