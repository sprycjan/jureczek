import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Postęp ekranu powitalnego między uruchomieniami. Trzyma go Android, bo trzeba go znać
/// zaraz po starcie, zanim wstanie baza. Błąd nigdy nie zatrzymuje startu: scena jest
/// ozdobą, więc bez zapisu po prostu zaczyna od początku.
const _channel = MethodChannel('pl.mc.jureczek/splash');

/// Numer sceny do pokazania teraz: kolejne uruchomienia idą po kolei przez wszystkie.
Future<int> nextSplashScene(int sceneCount) async {
  try {
    final turn = await _channel.invokeMethod<int>('nextSceneTurn') ?? 0;
    return turn % sceneCount;
  } catch (e) {
    debugPrint('Ekran powitalny bez licznika scen: ${e.runtimeType}');
    return 0;
  }
}

/// Miejsce, w którym kamper ostatnio odjechał z tej sceny; 0 przy pierwszym pokazaniu.
Future<double> readSplashScroll(String scene) async {
  try {
    return await _channel.invokeMethod<double>('sceneScroll', {
          'scene': scene,
        }) ??
        0;
  } catch (e) {
    debugPrint('Ekran powitalny bez zapisanego miejsca: ${e.runtimeType}');
    return 0;
  }
}

Future<void> saveSplashScroll(String scene, double scroll) async {
  try {
    await _channel.invokeMethod<void>('saveSceneScroll', {
      'scene': scene,
      'scroll': scroll,
    });
  } catch (e) {
    debugPrint('Ekran powitalny bez zapisu miejsca: ${e.runtimeType}');
  }
}
