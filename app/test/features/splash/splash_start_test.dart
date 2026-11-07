import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jureczek/features/splash/application/splash_start.dart';
import 'package:jureczek/features/splash/data/splash_art_loader.dart';

void main() {
  const limit = Duration(seconds: 1);

  void run(
    void Function(
      FakeAsync time,
      SplashStart start,
      int Function() deferred,
      int Function() allowed,
    )
    body, {
    Future<SplashArt>? art,
  }) {
    fakeAsync((time) {
      var deferred = 0;
      var allowed = 0;
      final start = SplashStart(
        art: art ?? Completer<SplashArt>().future,
        deferFirstFrame: () => deferred++,
        allowFirstFrame: () => allowed++,
        limit: limit,
      );
      body(time, start, () => deferred, () => allowed);
    });
  }

  test('wstrzymuje pierwszą klatkę od razu i zwalnia ją na żądanie', () {
    run((time, start, deferred, allowed) {
      expect(deferred(), 1);
      expect(allowed(), 0);
      time.elapse(const Duration(milliseconds: 200));
      expect(allowed(), 0);
      start.releaseFirstFrame();
      expect(allowed(), 1);
    });
  });

  test('zawieszone wczytywanie: limit zwalnia pierwszą klatkę', () {
    run((time, start, deferred, allowed) {
      time.elapse(limit - const Duration(milliseconds: 1));
      expect(allowed(), 0);
      time.elapse(const Duration(milliseconds: 1));
      expect(allowed(), 1);
    });
  });

  test('zwolnienie działa raz, także po limicie i przed nim', () {
    run((time, start, deferred, allowed) {
      start.releaseFirstFrame();
      start.releaseFirstFrame();
      time.elapse(limit * 2);
      expect(allowed(), 1);
    });
    run((time, start, deferred, allowed) {
      time.elapse(limit);
      start.releaseFirstFrame();
      expect(allowed(), 1);
    });
  });

  test('błąd wczytywania nie jest zgłaszany jako nieobsłużony', () {
    final errors = <Object>[];
    runZonedGuarded(() {
      fakeAsync((time) {
        final failed = Completer<SplashArt>();
        SplashStart(
          art: failed.future,
          deferFirstFrame: () {},
          allowFirstFrame: () {},
          limit: limit,
        );
        failed.completeError(StateError('brak pliku'));
        time.flushMicrotasks();
        time.elapse(limit);
      });
    }, (error, _) => errors.add(error));
    expect(errors, isEmpty);
  });
}
