import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jureczek/core/haptics/haptics.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('pl.mc.jureczek/haptics');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  tearDown(() => messenger.setMockMethodCallHandler(channel, null));

  test('tap woła natywne „tap”', () async {
    final calls = <String>[];
    messenger.setMockMethodCallHandler(channel, (call) async {
      calls.add(call.method);
      return null;
    });

    await const Haptics(channel).tap();

    expect(calls, ['tap']);
  });

  test('błąd po stronie Androida nie wychodzi poza tap', () async {
    messenger.setMockMethodCallHandler(
      channel,
      (_) async => throw PlatformException(code: 'x'),
    );

    await expectLater(const Haptics(channel).tap(), completes);
  });

  test('brak kanału (poza Androidem) nie jest błędem', () async {
    await expectLater(const Haptics(channel).tap(), completes);
  });
}
