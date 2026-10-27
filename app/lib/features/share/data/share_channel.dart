import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/shared_place.dart';

/// Udostępnienia z Androida (`MainActivity.kt`): to, z którym uruchomiono
/// aplikację, i kolejne, gdy już działa.
class ShareChannel {
  ShareChannel([this._channel = const MethodChannel('pl.mc.jureczek/share')]) {
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'onShare') {
        final share = _parse(call.arguments);
        if (share != null) _shares.add(share);
      }
    });
  }

  final MethodChannel _channel;
  final _shares = StreamController<SharedText>.broadcast();

  Stream<SharedText> get shares => _shares.stream;

  /// Udostępnienie przy zimnym starcie; Android oddaje je tylko raz.
  Future<SharedText?> initialShare() async =>
      _parse(await _channel.invokeMethod<Object?>('getInitialShare'));

  void dispose() {
    _channel.setMethodCallHandler(null);
    _shares.close();
  }

  static SharedText? _parse(Object? arguments) {
    if (arguments is! Map) return null;
    final text = arguments['text'];
    if (text is! String) return null;
    final subject = arguments['subject'];
    return (text: text, subject: subject is String ? subject : null);
  }
}

final shareChannelProvider = Provider<ShareChannel>((ref) {
  final channel = ShareChannel();
  ref.onDispose(channel.dispose);
  return channel;
});
