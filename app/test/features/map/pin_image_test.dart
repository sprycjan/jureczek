import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jureczek/features/map/domain/pin_color.dart';
import 'package:jureczek/features/map/domain/pin_kind.dart';
import 'package:jureczek/features/map/presentation/pin_image.dart';
import 'package:jureczek/features/places/domain/place_type.dart';
import 'package:jureczek/features/places/presentation/place_icons.dart';

Future<(int, int, ByteData)> _decode(Uint8List png) async {
  final codec = await ui.instantiateImageCodec(png);
  final image = (await codec.getNextFrame()).image;
  final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
  final result = (image.width, image.height, data!);
  image.dispose();
  return result;
}

ui.Color _pixel((int, int, ByteData) png, int x, int y) {
  final i = (y * png.$1 + x) * 4;
  final d = png.$3;
  return ui.Color.fromARGB(
    d.getUint8(i + 3),
    d.getUint8(i),
    d.getUint8(i + 1),
    d.getUint8(i + 2),
  );
}

/// Kolor piksela w środku główki pinezki typu (obok symbolu – lewa część główki).
ui.Color _headColor((int, int, ByteData) png, {required bool selected}) {
  final g = PlacePinGeometry.of(selected: selected);
  final x = ((PlacePinGeometry.pinOffset.dx + g.pinSize.width * 0.12) * 3)
      .round();
  final y = ((PlacePinGeometry.pinOffset.dy + g.pinSize.width / 2) * 3).round();
  return _pixel(png, x, y);
}

void _expectClose(ui.Color actual, ui.Color expected) {
  for (final (a, e) in [
    (actual.r, expected.r),
    (actual.g, expected.g),
    (actual.b, expected.b),
  ]) {
    expect((a - e).abs(), lessThan(3 / 255), reason: '$actual ≠ $expected');
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('zielona pinezka w kolorze ma rozmiar oryginału', (tester) async {
    await tester.runAsync(() async {
      for (final selected in [false, true]) {
        final original = await _decode(
          await renderPinPng(rootBundle, PinKind.standard, selected: selected),
        );
        final composed = await _decode(
          await renderPinPng(
            rootBundle,
            PinKind.standard,
            selected: selected,
            color: PinColor.red,
          ),
        );
        expect((composed.$1, composed.$2), (original.$1, original.$2));
      }
    });
  });

  for (final kind in [PinKind.standard, const PinKind(PlaceType.castle)]) {
    for (final selected in [false, true]) {
      testWidgets(
        'odwiedzona ${kind.key}${selected ? ' (zaznaczona)' : ''}: znaczek '
        'w ramce, reszta obrazka bez zmian',
        (tester) async {
          await tester.runAsync(() async {
            final plain = await _decode(
              await renderPinPng(rootBundle, kind, selected: selected),
            );
            final visited = await _decode(
              await renderPinPng(
                rootBundle,
                kind,
                selected: selected,
                visited: true,
              ),
            );
            expect((visited.$1, visited.$2), (plain.$1, plain.$2));

            final badge = visitedBadge(kind, selected: selected);
            final center = badge.center * pinImageScale;
            final radius = badge.radius * pinImageScale;
            expect(center.dx + radius, lessThanOrEqualTo(plain.$1));
            expect(center.dy - radius, greaterThanOrEqualTo(0));

            // Skraj znaczka to biała obwódka, a jego wnętrze jest ciemne.
            final ring = _pixel(
              visited,
              center.dx.round(),
              (center.dy - radius + 2).round(),
            );
            expect((ring.r, ring.g, ring.b, ring.a), (1, 1, 1, 1));
            final inner = _pixel(
              visited,
              center.dx.round(),
              (center.dy - radius * 0.75).round(),
            );
            expect(inner.computeLuminance(), lessThan(0.1));
            // Poza znaczkiem (dolna część z czubkiem) piksele są identyczne.
            for (var y = (center.dy + radius).ceil() + 1; y < plain.$2; y++) {
              for (var x = 0; x < plain.$1; x += 3) {
                expect(_pixel(visited, x, y), _pixel(plain, x, y));
              }
            }
          });
        },
      );
    }
  }

  for (final selected in [false, true]) {
    testWidgets(
      'pinezka typu${selected ? ' (zaznaczona)' : ''}: kolor kategorii '
      'albo własny',
      (tester) async {
        await tester.runAsync(() async {
          const kind = PinKind(PlaceType.castle);
          final plain = await _decode(
            await renderPinPng(rootBundle, kind, selected: selected),
          );
          final g = PlacePinGeometry.of(selected: selected);
          expect(plain.$1, (g.viewBox.width * pinImageScale).round());
          expect(plain.$2, (g.tipY * pinImageScale).round());
          _expectClose(
            _headColor(plain, selected: selected),
            PlaceType.castle.category.primary,
          );

          final gold = await _decode(
            await renderPinPng(
              rootBundle,
              kind,
              selected: selected,
              color: PinColor.gold,
            ),
          );
          expect((gold.$1, gold.$2), (plain.$1, plain.$2));
          _expectClose(
            _headColor(gold, selected: selected),
            PinColor.gold.color,
          );
        });
      },
    );
  }
}
