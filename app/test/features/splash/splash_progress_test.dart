import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jureczek/features/splash/data/splash_progress.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('pl.mc.jureczek/splash');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  tearDown(() => messenger.setMockMethodCallHandler(channel, null));

  test(
    'kolejne uruchomienia idą po kolei przez wszystkie sceny i wracają',
    () async {
      var turn = 0;
      messenger.setMockMethodCallHandler(channel, (call) async {
        expect(call.method, 'nextSceneTurn');
        return turn++;
      });

      final scenes = [for (var i = 0; i < 17; i++) await nextSplashScene(8)];

      expect(scenes, [0, 1, 2, 3, 4, 5, 6, 7, 0, 1, 2, 3, 4, 5, 6, 7, 0]);
    },
  );

  test(
    'mniej scen niż licznik po aktualizacji: numer zostaje w zakresie',
    () async {
      messenger.setMockMethodCallHandler(channel, (_) async => 1234);
      expect(await nextSplashScene(8), 1234 % 8);
    },
  );

  test('błąd licznika daje pierwszą scenę, a nie zatrzymuje startu', () async {
    messenger.setMockMethodCallHandler(
      channel,
      (_) async => throw PlatformException(code: 'brak'),
    );
    expect(await nextSplashScene(8), 0);
  });

  test('brak kanału daje pierwszą scenę', () async {
    expect(await nextSplashScene(8), 0);
  });

  test('pusta odpowiedź daje pierwszą scenę', () async {
    messenger.setMockMethodCallHandler(channel, (_) async => null);
    expect(await nextSplashScene(8), 0);
  });

  test('miejsce sceny: odczyt i zapis osobno dla każdej sceny', () async {
    final saved = <String, double>{};
    messenger.setMockMethodCallHandler(channel, (call) async {
      final args = call.arguments as Map<Object?, Object?>;
      final scene = args['scene']! as String;
      if (call.method == 'saveSceneScroll') {
        saved[scene] = args['scroll']! as double;
        return null;
      }
      expect(call.method, 'sceneScroll');
      return saved[scene] ?? 0.0;
    });

    expect(await readSplashScroll('alps'), 0);
    await saveSplashScroll('alps', 12.5);
    await saveSplashScroll('fjord', 3);
    expect(await readSplashScroll('alps'), 12.5);
    expect(await readSplashScroll('fjord'), 3);
    expect(await readSplashScroll('pass'), 0);
  });

  test('brak zapisu i błędy: scena od początku, bez wyjątku', () async {
    expect(await readSplashScroll('alps'), 0);
    await saveSplashScroll('alps', 5);

    messenger.setMockMethodCallHandler(
      channel,
      (_) async => throw PlatformException(code: 'brak'),
    );
    expect(await readSplashScroll('alps'), 0);
    await saveSplashScroll('alps', 5);

    messenger.setMockMethodCallHandler(channel, (_) async => null);
    expect(await readSplashScroll('alps'), 0);
  });
}
