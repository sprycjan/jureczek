import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:jureczek/features/splash/application/splash_motion.dart';
import 'package:jureczek/features/splash/domain/splash_config.dart';

void main() {
  const config = SplashConfig();
  late SplashFrame frame;
  late SplashMotion motion;

  SplashMotion make(SplashConfig c, SplashFrame f) =>
      SplashMotion(c, f, random: math.Random(1))
        ..wheelRate = 7
        ..roadSpeed = 170
        ..wheelbase = 149
        ..begin();

  setUp(() {
    frame = SplashFrame();
    motion = make(config, frame);
  });
  tearDown(() => frame.dispose());

  void run(double seconds, [void Function()? each]) {
    final frames = (seconds * 60).round();
    for (var i = 0; i < frames; i++) {
      motion.advance(1 / 60);
      each?.call();
    }
  }

  /// Jazda bez kamyków: pierwszy najazd poza zasięgiem testu.
  const calm = SplashConfig(pebbleFirst: (100, 100), pebbleEvery: (100, 100));

  test('faza A kończy się na miejscu i przechodzi w jazdę', () {
    expect(frame.enter, 0);
    run(0.5);
    expect(motion.phase, SplashPhase.entering);
    expect(frame.enter, inExclusiveRange(0, 1));
    run(1.0);
    expect(motion.phase, SplashPhase.driving);
    expect(frame.enter, 1);
    expect(frame.exit, 0);
  });

  test('w fazie B krajobraz i koła nie stają', () {
    run(2);
    final (scroll, wheel) = (frame.scroll, frame.wheelAngle);
    run(1);
    expect(frame.scroll, greaterThan(scroll));
    expect(frame.wheelAngle, greaterThan(wheel));
    expect(frame.enter, 1);
  });

  test('faza C przyspiesza i kończy się za krawędzią', () {
    run(2);
    motion.leave();
    run(0.1);
    final early = frame.exit;
    run(0.1);
    final next = frame.exit;
    expect(next - early, greaterThan(early));
    run(1);
    expect(frame.exit, 1);
    expect(motion.leaveTime, greaterThan(0.7));
  });

  test('odjazd w trakcie wjazdu rusza z bieżącego miejsca', () {
    run(0.3);
    final position = frame.enter;
    motion.leave();
    run(0.5);
    expect(frame.enter, position);
    expect(frame.exit, greaterThan(0));
  });

  test('tempo zmienia się jednym mnożnikiem', () {
    final fastFrame = SplashFrame();
    addTearDown(fastFrame.dispose);
    final fast = make(const SplashConfig(speedScale: 2), fastFrame);
    run(1);
    for (var i = 0; i < 60; i++) {
      fast.advance(1 / 60);
    }
    expect(fastFrame.scroll, closeTo(frame.scroll * 2, 0.05));
  });

  group('zawieszenie', () {
    setUp(() => motion = make(calm, frame));

    test('hamowanie przy wjeździe: przód siada, tył się unosi', () {
      run(0.6);
      expect(frame.bodyPitch, lessThan(-0.01));
    });

    test('po zatrzymaniu odbija w drugą stronę i się uspokaja', () {
      var rebound = 0.0;
      run(2, () => rebound = math.max(rebound, frame.bodyPitch));
      expect(rebound, greaterThan(0));
      run(3);
      expect(frame.bodyPitch.abs(), lessThan(0.001));
    });

    test('przyspieszanie przy odjeździe: tył siada', () {
      run(5);
      motion.leave();
      run(0.5);
      expect(frame.bodyPitch, greaterThan(0.01));
    });

    test('przechył jest lekki', () {
      var biggest = 0.0;
      run(3, () => biggest = math.max(biggest, frame.bodyPitch.abs()));
      motion.leave();
      run(1, () => biggest = math.max(biggest, frame.bodyPitch.abs()));
      expect(biggest, lessThan(math.pi / 180 * 3.5));
    });

    test('bez kamyka koła zostają na drodze', () {
      run(5, () {
        expect(frame.frontLift, 0);
        expect(frame.rearLift, 0);
      });
    });
  });

  group('kamyk', () {
    double firstContact() => frame.pebbles.first.frontContact;

    // Przy minimum 2 s tylna oś trafia na kamyk już w odjeździe, więc podskakuje tylko
    // przednia: wcześniej kamper jeszcze wjeżdża i koło minęłoby się z kamykiem.
    test('pierwszy trafia przednie koło po wjeździe, a przed odjazdem', () {
      const config = SplashConfig();
      final entered = config.enterDuration.inMilliseconds / 1000;
      final leaving = config.minimumDuration.inMilliseconds / 1000;
      expect(firstContact(), greaterThan(entered));
      expect(firstContact(), lessThan(leaving - 0.3));
    });

    test('najpierw podskakuje przednie koło, potem tylne', () {
      var frontPeak = 0.0, rearPeak = 0.0;
      var frontAt = 0.0, rearAt = 0.0;
      var t = 0.0;
      run(4, () {
        t += 1 / 60;
        if (frame.frontLift > frontPeak) {
          frontPeak = frame.frontLift;
          frontAt = t;
        }
        if (frame.rearLift > rearPeak) {
          rearPeak = frame.rearLift;
          rearAt = t;
        }
      });
      expect(frontPeak, greaterThan(2));
      expect(rearPeak, greaterThan(2));
      expect(rearAt - frontAt, closeTo(149 / 170, 0.05));
    });

    test('nadwozie reaguje: przód w górę po najeździe przedniego koła', () {
      run(firstContact() - 0.2);
      final before = frame.bodyPitch;
      var biggest = before;
      run(0.45, () => biggest = math.max(biggest, frame.bodyPitch));
      expect(biggest, greaterThan(before + 0.005));
    });

    test('kamyk jedzie z drogą i mija koło w chwili najazdu', () {
      run(1);
      final pebble = frame.pebbles.first;
      final before = pebble.ahead;
      run(0.5);
      expect(before - pebble.ahead, closeTo(170 * 0.5, 2));
      run(firstContact() - 1.5);
      expect(pebble.ahead.abs(), lessThan(4));
    });

    test('po odjeździe nie ma już najazdów', () {
      run(firstContact() - 0.3);
      motion.leave();
      run(2, () {});
      expect(frame.frontLift, lessThan(0.01));
      expect(frame.rearLift, lessThan(0.01));
    });

    test('kolejne kamyki przychodzą w zadanych odstępach', () {
      final contacts = [for (final p in frame.pebbles) p.frontContact]..sort();
      for (var i = 1; i < contacts.length; i++) {
        expect(contacts[i] - contacts[i - 1], inInclusiveRange(3, 5));
      }
    });
  });
}
