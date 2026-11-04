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

/// Białe piksele symbolu w kole [radius] wokół [head] (dp, obrazek bez znaczków)
/// leżą poza obiema pozycjami kolumny znaczków.
void _expectSymbolClear(
  (int, int, ByteData) png,
  PinKind kind, {
  required bool selected,
  required Offset head,
  required double radius,
}) {
  final padding = pinBadgeFramePadding(kind, selected: selected);
  final badges = pinBadges(kind, selected: selected, count: 2);
  var symbolPixels = 0;
  for (var y = 0; y < png.$2; y++) {
    for (var x = 0; x < png.$1; x++) {
      final dp = Offset(x / pinImageScale, y / pinImageScale);
      if ((dp - head).distance > radius) continue;
      final color = _pixel(png, x, y);
      if (color.r < 0.92 || color.g < 0.92 || color.b < 0.92) continue;
      symbolPixels++;
      for (final badge in badges) {
        expect(
          (dp + Offset(padding, 0) - badge.center).distance,
          greaterThan(badge.radius),
          reason: '${kind.key}: znaczek zasłania symbol w $dp',
        );
      }
    }
  }
  expect(symbolPixels, greaterThan(0), reason: kind.key);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Bez prawdziwej czcionki ikon test nie narysowałby gwiazdki ani kciuka.
  setUpAll(() async {
    final font = FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await font.load();
  });

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
      final name = '${kind.key}${selected ? ' (zaznaczona)' : ''}';

      /// Znaczek [index]: biała obwódka, ciemne wnętrze, w środku symbol [color].
      void expectBadge(
        (int, int, ByteData) png,
        int index, {
        required int count,
        required ui.Color color,
      }) {
        final badge = pinBadges(kind, selected: selected, count: count)[index];
        final center = badge.center * pinImageScale;
        final radius = badge.radius * pinImageScale;
        expect(center.dx + radius, lessThanOrEqualTo(png.$1));
        expect(center.dy - radius, greaterThanOrEqualTo(0));
        final ring = _pixel(
          png,
          center.dx.round(),
          (center.dy - radius + 2).round(),
        );
        expect((ring.r, ring.g, ring.b, ring.a), (1, 1, 1, 1));
        final inner = _pixel(
          png,
          center.dx.round(),
          (center.dy - radius * 0.75).round(),
        );
        expect(inner.computeLuminance(), lessThan(0.1));
        _expectClose(_pixel(png, center.dx.round(), center.dy.round()), color);
      }

      testWidgets('$name: gwiazdka nad kciukiem, reszta obrazka bez zmian', (
        tester,
      ) async {
        await tester.runAsync(() async {
          final padding =
              (pinBadgeFramePadding(kind, selected: selected) * pinImageScale)
                  .round();
          final plain = await _decode(
            await renderPinPng(rootBundle, kind, selected: selected),
          );
          final both = await _decode(
            await renderPinPng(
              rootBundle,
              kind,
              selected: selected,
              starred: true,
              visited: true,
            ),
          );
          expect((both.$1, both.$2), (plain.$1 + 2 * padding, plain.$2));
          expectBadge(both, 0, count: 2, color: pinStarColor);
          expectBadge(both, 1, count: 2, color: const ui.Color(0xFFFFFFFF));

          // Stykające się z główką znaczki leżą jeden pod drugim, w jednej kolumnie.
          final column = pinBadges(kind, selected: selected, count: 2);
          expect(column[0].center.dx, column[1].center.dx);
          expect(
            column[1].center.dy - column[0].center.dy,
            2 * column[0].radius + 1,
          );

          // Poza kolumną (dolna część z czubkiem) piksele są identyczne.
          final bottom =
              ((column[1].center.dy + column[1].radius) * pinImageScale)
                  .ceil() +
              1;
          for (var y = bottom; y < plain.$2; y++) {
            for (var x = 0; x < plain.$1; x += 3) {
              expect(_pixel(both, x + padding, y), _pixel(plain, x, y));
            }
          }
        });
      });

      for (final (label, starred, visited, color) in [
        ('gwiazdka', true, false, pinStarColor),
        ('kciuk', false, true, const ui.Color(0xFFFFFFFF)),
      ]) {
        testWidgets('$name: tylko $label, na górnym miejscu', (tester) async {
          await tester.runAsync(() async {
            final png = await _decode(
              await renderPinPng(
                rootBundle,
                kind,
                selected: selected,
                starred: starred,
                visited: visited,
              ),
            );
            expectBadge(png, 0, count: 1, color: color);
          });
        });
      }
    }
  }

  for (final selected in [false, true]) {
    testWidgets('kolumna znaczków nie zasłania symbolu żadnego typu'
        '${selected ? ' (zaznaczona)' : ''}', (tester) async {
      await tester.runAsync(() async {
        final g = PlacePinGeometry.of(selected: selected);
        final head = Offset(
          PlacePinGeometry.pinOffset.dx + g.pinSize.width / 2,
          PlacePinGeometry.pinOffset.dy + g.pinSize.width / 2,
        );
        // Bez białego pierścienia zaznaczonej pinezki.
        final radius = g.pinSize.width / 2 - (selected ? 3.5 : 1);
        for (final type in PlaceType.values) {
          final kind = PinKind(type);
          final png = await _decode(
            await renderPinPng(rootBundle, kind, selected: selected),
          );
          _expectSymbolClear(
            png,
            kind,
            selected: selected,
            head: head,
            radius: radius,
          );
        }
      });
    }, timeout: const Timeout(Duration(minutes: 1)));
  }

  for (final (selected, head, radius) in [
    (false, const Offset(27, 20), 14.0),
    (true, const Offset(31.3, 24), 17.0),
  ]) {
    testWidgets('kolumna znaczków nie zasłania symbolu zielonej'
        '${selected ? ' (zaznaczona)' : ''}', (tester) async {
      await tester.runAsync(() async {
        final png = await _decode(
          await renderPinPng(rootBundle, PinKind.standard, selected: selected),
        );
        _expectSymbolClear(
          png,
          PinKind.standard,
          selected: selected,
          head: head,
          radius: radius,
        );
      });
    });
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
