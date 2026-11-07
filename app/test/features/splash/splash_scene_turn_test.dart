import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jureczek/features/splash/data/splash_scene_turn.dart';

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
}
