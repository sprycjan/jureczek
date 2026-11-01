import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Wibracja przez `MainActivity.kt`. [HapticFeedback] Fluttera milczy,
/// gdy w systemie wyłączono wibracje dotykowe (domyślnie np. na EMUI).
class Haptics {
  const Haptics([
    this._channel = const MethodChannel('pl.mc.jureczek/haptics'),
  ]);

  final MethodChannel _channel;

  /// Krótkie stuknięcie; brak wibracji to nie błąd.
  Future<void> tap() async {
    try {
      await _channel.invokeMethod<void>('tap');
    } on PlatformException catch (e) {
      debugPrint('Wibracja nie powiodła się: ${e.message}');
    } on MissingPluginException {
      // Poza Androidem nie ma kanału.
    }
  }
}

final hapticsProvider = Provider<Haptics>((ref) => const Haptics());
