import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import '../domain/splash_config.dart';

/// Stan jednej klatki; obiekt jest współdzielony, żeby klatka niczego nie alokowała.
class SplashFrame extends ChangeNotifier {
  /// Czas jazdy w sekundach: mnożony przez prędkości warstw daje ich przesunięcie.
  double scroll = 0;

  /// Postęp wjazdu: 0 za lewą krawędzią, 1 na miejscu.
  double enter = 1;

  /// Postęp odjazdu: 0 na miejscu wjazdu, 1 za prawą krawędzią.
  double exit = 0;

  /// Obrót kół w radianach.
  double wheelAngle = 0;

  /// Czas animacji kurzu w sekundach; ujemny, gdy kurzu nie ma.
  double dustTime = -1;

  void update() => notifyListeners();
}

/// A: kamper wjeżdża, B: jedzie w miejscu, C: przyspiesza i odjeżdża.
enum SplashPhase { entering, driving, leaving }

/// Ruch sceny: czysta matematyka bez zegara, kolejne kroki podaje widget.
class SplashMotion {
  SplashMotion(this.config, this.frame);

  final SplashConfig config;
  final SplashFrame frame;

  /// Radiany obrotu kół na sekundę jazdy: droga przesuwa się pod nimi bez poślizgu.
  double wheelRate = 0;

  SplashPhase _phase = SplashPhase.entering;
  double _time = 0;
  double _enterTime = 0;
  double _leaveTime = 0;

  SplashPhase get phase => _phase;

  /// Czas od początku odjazdu, w sekundach.
  double get leaveTime => _leaveTime;

  void begin() {
    frame
      ..enter = 0
      ..exit = 0
      ..dustTime = 0;
  }

  void leave() => _phase = SplashPhase.leaving;

  void advance(double seconds) {
    _time += seconds;
    final enterSeconds = _seconds(config.enterDuration);
    switch (_phase) {
      case SplashPhase.entering:
        _enterTime += seconds;
        if (_enterTime >= enterSeconds) _phase = SplashPhase.driving;
        final t = math.min(1.0, _enterTime / enterSeconds);
        frame.enter = 1 - math.pow(1 - t, 3).toDouble();
      case SplashPhase.driving:
        frame.enter = 1;
      case SplashPhase.leaving:
        // Stuknięcie w fazie A: `enter` zostaje i kamper rusza z bieżącego miejsca.
        _leaveTime += seconds;
        final t = math.min(1.0, _leaveTime / _seconds(config.driveOffDuration));
        frame.exit = t * t * t;
    }
    final run = seconds * config.speedScale;
    frame
      ..scroll += run
      ..wheelAngle +=
          wheelRate * run * (1 + config.driveOffWheelBoost * frame.exit)
      ..dustTime = _time;
  }

  static double _seconds(Duration d) => d.inMicroseconds / 1e6;
}
