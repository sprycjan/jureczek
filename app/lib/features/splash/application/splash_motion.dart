import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import '../data/splash_art_loader.dart';
import '../domain/splash_config.dart';

/// Kamyk na drodze, w układzie związanym z miejscem jazdy kampera.
class SplashPebble {
  /// Czas najazdu przedniego koła, w sekundach od początku animacji.
  double frontContact = double.nan;

  /// Odległość przed przednim kołem w jednostkach sceny; ujemna, gdy kamyk je minął.
  double ahead = double.nan;

  /// Wielkość: skaluje rysunek i uniesienie koła.
  double scale = 1;

  bool get visible => !ahead.isNaN;
}

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

  /// Uniesienie środka nadwozia w jednostkach sceny; ujemne, gdy siada.
  double bodyLift = 0;

  /// Przechył nadwozia w radianach; dodatni: przód wyżej, tył siada.
  double bodyPitch = 0;

  /// Uniesienie kół nad drogą w jednostkach sceny.
  double frontLift = 0;
  double rearLift = 0;

  final pebbles = List<SplashPebble>.generate(3, (_) => SplashPebble());

  void update() => notifyListeners();
}

/// A: kamper wjeżdża, B: jedzie w miejscu, C: przyspiesza i odjeżdża.
enum SplashPhase { entering, driving, leaving }

/// Ruch sceny: czysta matematyka bez zegara, kolejne kroki podaje widget.
///
/// Zawieszenie to dwa końce nadwozia na sprężynach, oparte o koła, które same są
/// sprężynami na drodze. Przyspieszanie, hamowanie i kamyki są tylko siłami w tym modelu,
/// więc przechył, odbicie i kołysanie nie są klatkowane ręcznie.
class SplashMotion {
  SplashMotion(this.config, this.frame, {math.Random? random})
    : _random = random ?? math.Random();

  /// Krok fizyki: sprężyna koła jest sztywna, a klatka bywa dłuższa niż zwykle.
  static const _step = 1 / 240;

  /// Kamyk daleko za kamperem przestaje być rysowany i wraca jako następny.
  static const _pebbleGone = -1000.0;

  final SplashConfig config;
  final SplashFrame frame;
  final math.Random _random;

  /// Radiany obrotu kół na sekundę jazdy: droga przesuwa się pod nimi bez poślizgu.
  double wheelRate = 0;

  /// Prędkość drogi i rozstaw osi, w jednostkach sceny.
  double roadSpeed = 0;
  double wheelbase = 1;

  SplashPhase _phase = SplashPhase.entering;
  double _time = 0;
  double _enterTime = 0;
  double _leaveTime = 0;
  double _lastContact = 0;

  // Uniesienie i prędkość: koła oraz końce nadwozia.
  double _frontWheel = 0, _frontWheelV = 0;
  double _rearWheel = 0, _rearWheelV = 0;
  double _front = 0, _frontV = 0;
  double _rear = 0, _rearV = 0;

  SplashPhase get phase => _phase;

  /// Czas od początku odjazdu, w sekundach.
  double get leaveTime => _leaveTime;

  /// Parametry pojazdu z wczytanej sceny. Koła toczą się po drodze: to przedostatnia
  /// warstwa, ostatnia to pierwszy plan.
  void attach(SplashArt art) {
    final manifest = art.manifest;
    final camper = manifest.camper;
    roadSpeed = art.layers[art.layers.length - 2].spec.speed;
    wheelRate = roadSpeed / (camper.radius * manifest.camperScale);
    wheelbase =
        (camper.wheels.last.dx - camper.wheels.first.dx) * manifest.camperScale;
  }

  void begin() {
    frame
      ..enter = 0
      ..exit = 0
      ..dustTime = 0;
    _lastContact = _between(config.pebbleFirst);
    _schedule(frame.pebbles.first, _lastContact);
    for (final pebble in frame.pebbles.skip(1)) {
      _lastContact += _between(config.pebbleEvery);
      _schedule(pebble, _lastContact);
    }
  }

  void leave() => _phase = SplashPhase.leaving;

  void advance(double seconds) {
    final enterSeconds = _seconds(config.enterDuration);
    var accel = 0.0;
    switch (_phase) {
      case SplashPhase.entering:
        _enterTime += seconds;
        if (_enterTime >= enterSeconds) _phase = SplashPhase.driving;
        final t = math.min(1.0, _enterTime / enterSeconds);
        // Równe hamowanie: nos nurkuje przez cały wjazd i odbija, gdy kamper staje.
        final left = 1 - t;
        frame.enter = 1 - left * left;
        accel = _phase == SplashPhase.entering ? -1 : 0;
      case SplashPhase.driving:
        frame.enter = 1;
      case SplashPhase.leaving:
        // Stuknięcie w fazie A: `enter` zostaje i kamper rusza z bieżącego miejsca.
        _leaveTime += seconds;
        final t = math.min(1.0, _leaveTime / _seconds(config.driveOffDuration));
        frame.exit = t * t * t;
        accel = t;
    }

    final steps = math.max(1, (seconds / _step).ceil());
    final dt = seconds / steps;
    for (var i = 0; i < steps; i++) {
      _time += dt;
      _physics(dt, accel);
    }

    _updatePebbles();
    final run = seconds * config.speedScale;
    frame
      ..scroll += run
      ..wheelAngle +=
          wheelRate * run * (1 + config.driveOffWheelBoost * frame.exit)
      ..dustTime = _time
      ..frontLift = _frontWheel
      ..rearLift = _rearWheel
      ..bodyLift = (_front + _rear) / 2
      ..bodyPitch = math.atan2(_front - _rear, wheelbase);
  }

  void _physics(double dt, double accel) {
    // Koła: sztywna sprężyna ciągnie je do profilu drogi, a droga nie puszcza ich w dół.
    final wheelW = 2 * math.pi * config.wheelHz;
    final wheelC = 2 * config.wheelDamping * wheelW;
    final frontRoad = _road(0);
    final rearRoad = _road(_wheelbaseTime);
    _frontWheelV +=
        (wheelW * wheelW * (frontRoad - _frontWheel) - wheelC * _frontWheelV) *
        dt;
    _rearWheelV +=
        (wheelW * wheelW * (rearRoad - _rearWheel) - wheelC * _rearWheelV) * dt;
    _frontWheel += _frontWheelV * dt;
    _rearWheel += _rearWheelV * dt;
    if (_frontWheel < 0) {
      _frontWheel = 0;
      _frontWheelV = 0;
    }
    if (_rearWheel < 0) {
      _rearWheel = 0;
      _rearWheelV = 0;
    }

    // Nadwozie: każda oś opiera się na swoim kole, a siła na jednej trochę przechyla drugą.
    final w = 2 * math.pi * config.suspensionHz;
    final c = 2 * config.suspensionDamping * w;
    final frontForce =
        w * w * (_frontWheel - _front) + c * (_frontWheelV - _frontV);
    final rearForce = w * w * (_rearWheel - _rear) + c * (_rearWheelV - _rearV);
    final pitchForce = accel * config.squat * w * w;
    final coupling = config.suspensionCoupling;
    _frontV += (frontForce - coupling * rearForce + pitchForce) * dt;
    _rearV += (rearForce - coupling * frontForce - pitchForce) * dt;
    _front += _frontV * dt;
    _rear += _rearV * dt;
  }

  /// Wysokość drogi pod kołem, które wjeżdża na kamyk o [delay] później niż przednie.
  double _road(double delay) {
    // Odjazd: kamper zmienia prędkość, więc czasy najazdu przestają obowiązywać.
    if (_phase == SplashPhase.leaving) return 0;
    final contact = config.pebbleContact / _speed;
    var height = 0.0;
    for (final pebble in frame.pebbles) {
      final u = (_time - pebble.frontContact - delay) / contact + 0.5;
      if (u > 0 && u < 1) {
        final s = math.sin(math.pi * u);
        height = math.max(height, config.pebbleLift * pebble.scale * s * s);
      }
    }
    return height;
  }

  void _updatePebbles() {
    for (final pebble in frame.pebbles) {
      if (pebble.frontContact.isNaN) continue;
      pebble.ahead = (pebble.frontContact - _time) * _speed;
      if (pebble.ahead < _pebbleGone && _phase != SplashPhase.leaving) {
        _lastContact += _between(config.pebbleEvery);
        _schedule(pebble, _lastContact);
      }
    }
  }

  void _schedule(SplashPebble pebble, double contact) {
    pebble
      ..frontContact = contact
      ..scale = 0.8 + 0.5 * _random.nextDouble()
      ..ahead = double.nan;
  }

  double _between((double, double) range) =>
      range.$1 + (range.$2 - range.$1) * _random.nextDouble();

  double get _speed => math.max(1, roadSpeed * config.speedScale);
  double get _wheelbaseTime => wheelbase / _speed;

  static double _seconds(Duration d) => d.inMicroseconds / 1e6;
}
