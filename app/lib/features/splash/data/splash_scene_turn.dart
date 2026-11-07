import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

const _channel = MethodChannel('pl.mc.jureczek/splash');

/// Numer sceny do pokazania teraz: kolejne uruchomienia idą po kolei przez wszystkie.
/// Licznik trzyma Android, bo trzeba go znać zaraz po starcie, zanim wstanie baza.
/// Bez licznika zostaje pierwsza scena: rotacja nie może zatrzymać startu.
Future<int> nextSplashScene(int sceneCount) async {
  try {
    final turn = await _channel.invokeMethod<int>('nextSceneTurn') ?? 0;
    return turn % sceneCount;
  } catch (e) {
    debugPrint('Ekran powitalny bez licznika scen: ${e.runtimeType}');
    return 0;
  }
}
