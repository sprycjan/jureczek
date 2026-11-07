import 'dart:async';
import 'dart:ui' show VoidCallback;

import '../data/splash_art_loader.dart';

/// Początek ekranu powitalnego, jeszcze przed `runApp`: scena wczytuje się od razu,
/// a Flutter nie pokazuje niczego, dopóki nie ma czego pokazać. Dzięki temu pierwsza
/// klatka to już krajobraz, a nie zasłona z gradientem.
class SplashStart {
  /// [limit] pilnuje, żeby wolne wczytywanie nie zostawiło telefonu na natywnym tle.
  SplashStart({
    required this.art,
    required void Function() deferFirstFrame,
    required VoidCallback allowFirstFrame,
    required Duration limit,
  }) : _allowFirstFrame = allowFirstFrame {
    // Błąd obsługuje nakładka; tu tylko nie może zostać zgłoszony jako nieobsłużony.
    art.ignore();
    deferFirstFrame();
    _limit = Timer(limit, releaseFirstFrame);
  }

  final Future<SplashArt> art;
  final VoidCallback _allowFirstFrame;
  late final Timer _limit;
  bool _released = false;

  /// Wywoływane wiele razy (limit, koniec wczytywania), działa raz, bo
  /// `allowFirstFrame` musi mieć dokładnie jedną parę z `deferFirstFrame`.
  void releaseFirstFrame() {
    if (_released) return;
    _released = true;
    _limit.cancel();
    _allowFirstFrame();
  }
}
