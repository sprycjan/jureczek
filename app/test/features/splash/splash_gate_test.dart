import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jureczek/features/splash/domain/splash_gate.dart';

void main() {
  const minimum = Duration(milliseconds: 3500);
  const limit = Duration(seconds: 10);

  /// Uruchamia bramkę i podaje liczbę wyjść do sprawdzenia w dowolnej chwili.
  void run(
    void Function(FakeAsync time, SplashGate gate, int Function() exits) body,
  ) {
    fakeAsync((time) {
      var count = 0;
      final gate = SplashGate(
        minimum: minimum,
        limit: limit,
        onExit: () => count++,
      )..start();
      body(time, gate, () => count);
      gate.dispose();
    });
  }

  for (final seconds in [1, 3]) {
    test('gotowość po $seconds s: wyjście dopiero po minimum', () {
      run((time, gate, exits) {
        time.elapse(Duration(seconds: seconds));
        gate.markReady();
        expect(exits(), 0);
        time.elapse(
          minimum -
              Duration(seconds: seconds) -
              const Duration(milliseconds: 1),
        );
        expect(exits(), 0);
        time.elapse(const Duration(milliseconds: 1));
        expect(exits(), 1);
      });
    });
  }

  for (final seconds in [5, 8]) {
    test('gotowość po $seconds s: wyjście od razu', () {
      run((time, gate, exits) {
        time.elapse(
          Duration(seconds: seconds) - const Duration(milliseconds: 1),
        );
        expect(exits(), 0);
        time.elapse(const Duration(milliseconds: 1));
        gate.markReady();
        expect(exits(), 1);
      });
    });
  }

  test('bez gotowości wyjście po limicie', () {
    run((time, gate, exits) {
      time.elapse(limit - const Duration(milliseconds: 1));
      expect(exits(), 0);
      time.elapse(const Duration(milliseconds: 1));
      expect(exits(), 1);
    });
  });

  test('stuknięcie po gotowości: od razu, bez czekania na minimum', () {
    run((time, gate, exits) {
      gate.markReady();
      time.elapse(const Duration(seconds: 1));
      gate.skipMinimum();
      expect(exits(), 1);
    });
  });

  test('stuknięcie przed gotowością jest zapamiętane', () {
    run((time, gate, exits) {
      gate.skipMinimum();
      expect(exits(), 0);
      time.elapse(const Duration(seconds: 1));
      gate.markReady();
      expect(exits(), 1);
    });
  });

  test('wyjście jest tylko jedno, cokolwiek przyjdzie później', () {
    run((time, gate, exits) {
      gate.markReady();
      time.elapse(minimum);
      gate
        ..markReady()
        ..skipMinimum()
        ..start();
      time.elapse(limit * 2);
      expect(exits(), 1);
    });
  });

  test('ponowny start nie liczy minimum od nowa', () {
    run((time, gate, exits) {
      time.elapse(const Duration(seconds: 3));
      gate
        ..start()
        ..markReady();
      time.elapse(const Duration(milliseconds: 500));
      expect(exits(), 1);
    });
  });
}
