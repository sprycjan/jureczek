import 'package:flutter_test/flutter_test.dart';
import 'package:jureczek/features/splash/application/splash_motion.dart';
import 'package:jureczek/features/splash/domain/splash_config.dart';

void main() {
  const config = SplashConfig();
  late SplashFrame frame;
  late SplashMotion motion;

  setUp(() {
    frame = SplashFrame();
    motion = SplashMotion(config, frame)
      ..wheelRate = 7
      ..begin();
  });
  tearDown(() => frame.dispose());

  void run(double seconds) {
    for (var t = 0.0; t < seconds; t += 1 / 60) {
      motion.advance(1 / 60);
    }
  }

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
    final fast = SplashMotion(const SplashConfig(speedScale: 2), fastFrame)
      ..begin();
    run(1);
    for (var t = 0.0; t < 1; t += 1 / 60) {
      fast.advance(1 / 60);
    }
    expect(fastFrame.scroll, closeTo(frame.scroll * 2, 0.05));
  });
}
