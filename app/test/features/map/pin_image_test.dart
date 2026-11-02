import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jureczek/features/map/domain/pin_category.dart';
import 'package:jureczek/features/map/domain/pin_color.dart';
import 'package:jureczek/features/map/presentation/pin_image.dart';

/// Kolor korpusu w SVG kategorii (`assets/markers/src`) – jest wśród 24 kolorów.
const _svgColors = {
  PinCategory.gastronomy: PinColor.orange,
  PinCategory.places: PinColor.blue,
  PinCategory.nature: PinColor.green,
  PinCategory.activities: PinColor.purple,
  PinCategory.travel: PinColor.slate,
  PinCategory.entertainment: PinColor.raspberry,
  PinCategory.practical: PinColor.cyan,
};

Future<(int, int, Uint8List)> _decode(Uint8List png) async {
  final codec = await ui.instantiateImageCodec(png);
  final image = (await codec.getNextFrame()).image;
  final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
  return (image.width, image.height, data!.buffer.asUint8List());
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  for (final MapEntry(key: category, value: color) in _svgColors.entries) {
    for (final selected in [false, true]) {
      testWidgets('warstwy ${category.key}${selected ? ' (zaznaczona)' : ''} '
          'w kolorze z SVG dają gotową pinezkę', (tester) async {
        await tester.runAsync(() async {
          final original = await _decode(
            await renderPinPng(rootBundle, category, selected: selected),
          );
          final composed = await _decode(
            await renderPinPng(
              rootBundle,
              category,
              selected: selected,
              color: color,
            ),
          );
          expect((composed.$1, composed.$2), (original.$1, original.$2));

          var sum = 0;
          for (var i = 0; i < original.$3.length; i++) {
            sum += (original.$3[i] - composed.$3[i]).abs();
          }
          // Średnia różnica kanału – zaokrąglenia mnożenia i krawędzie.
          expect(sum / original.$3.length, lessThan(2));
        });
      });
    }
  }

  testWidgets('pinezka domyślna w kolorze ma rozmiar oryginału', (
    tester,
  ) async {
    await tester.runAsync(() async {
      for (final selected in [false, true]) {
        final original = await _decode(
          await renderPinPng(
            rootBundle,
            PinCategory.standard,
            selected: selected,
          ),
        );
        final composed = await _decode(
          await renderPinPng(
            rootBundle,
            PinCategory.standard,
            selected: selected,
            color: PinColor.red,
          ),
        );
        expect((composed.$1, composed.$2), (original.$1, original.$2));
      }
    });
  });
}
