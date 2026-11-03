import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jureczek/features/places/domain/place_category.dart';
import 'package:jureczek/features/places/domain/place_type.dart';
import 'package:jureczek/features/places/presentation/place_icon_gallery.dart';
import 'package:jureczek/features/places/presentation/place_icons.dart';
import 'package:jureczek/l10n/app_localizations.dart';

String _hex(Color c) =>
    '#${(c.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';

/// Liczby typów z zadania (v15) + „inne” (v16) – nic nie może zniknąć po cichu.
const _expectedCounts = {
  PlaceCategory.gastronomy: 11,
  PlaceCategory.places: 13,
  PlaceCategory.nature: 14,
  PlaceCategory.activities: 11,
  PlaceCategory.travel: 12,
  PlaceCategory.entertainment: 11,
  PlaceCategory.practical: 9,
};

Future<void> _settleSvgs(WidgetTester tester) async {
  for (var i = 0; i < 5; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pump();
  }
}

Widget _app(Widget child) => MaterialApp(
  locale: const Locale('pl'),
  supportedLocales: AppLocalizations.supportedLocales,
  localizationsDelegates: const [
    AppLocalizations.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ],
  home: child,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('81 typów w 7 kategoriach, liczby jak w zadaniu, unikalne klucze', () {
    expect(PlaceType.values, hasLength(81));
    for (final MapEntry(key: category, value: count)
        in _expectedCounts.entries) {
      expect(PlaceType.of(category), hasLength(count), reason: category.key);
    }
    expect(PlaceType.values.map((t) => t.key).toSet(), hasLength(81));
    for (final type in PlaceType.values) {
      expect(
        RegExp(r'^[a-z]+(_[a-z]+)*$').hasMatch(type.key),
        isTrue,
        reason: type.key,
      );
      expect(PlaceType.fromKey(type.key), type);
    }
    expect(PlaceType.fromKey('nieznany'), isNull);
    for (final category in PlaceCategory.values) {
      expect(category.otherType.category, category);
      expect(category.otherType.isOther, isTrue);
      expect(PlaceType.of(category).last, category.otherType);
    }
  });

  test('każdy typ ma trzy SVG, a w katalogu nie ma sierot', () {
    final expected = {
      for (final t in PlaceType.values) ...[
        t.iconAsset,
        t.pinAsset(),
        t.pinAsset(selected: true),
      ],
    };
    final onDisk = Directory('assets/place_icons')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.svg'))
        .map((f) => f.path)
        .toSet();
    expect(onDisk, expected);
    expect(onDisk, hasLength(243));
  });

  test('kolory w SVG to tokeny kategorii', () {
    for (final type in PlaceType.values) {
      final primary = _hex(type.category.primary);
      final icon = File(type.iconAsset).readAsStringSync();
      expect(icon, contains('stroke="$primary"'), reason: type.key);
      expect(icon, contains('viewBox="0 0 24 24"'));
      for (final selected in [false, true]) {
        final pin = File(type.pinAsset(selected: selected)).readAsStringSync();
        expect(pin, contains('fill="$primary"'), reason: type.key);
        expect(
          pin,
          contains('stroke="#FFFFFF"'),
          reason: 'biały symbol ${type.key}',
        );
        // Żadnych innych kolorów poza kolorem kategorii, bielą i czernią cienia.
        final colors = RegExp(
          r'#[0-9A-Fa-f]{6}',
        ).allMatches(pin).map((m) => m[0]).toSet();
        expect(
          colors.difference({primary, '#FFFFFF', '#000000'}),
          isEmpty,
          reason: type.key,
        );
      }
    }
  });

  test('cień i viewBox pinezek w SVG = PlacePinGeometry', () {
    for (final selected in [false, true]) {
      final g = PlacePinGeometry.of(selected: selected);
      final pin = File(
        PlaceType.cafe.pinAsset(selected: selected),
      ).readAsStringSync();
      String num(double v) => v == v.roundToDouble() ? '${v.round()}' : '$v';
      expect(
        pin,
        contains(
          'viewBox="0 0 ${num(g.viewBox.width)} ${num(g.viewBox.height)}"',
        ),
      );
      expect(
        pin,
        contains(
          '<feDropShadow dx="0" dy="${num(g.shadowDy)}" stdDeviation="${num(g.shadowBlur)}" '
          'flood-color="#000000" flood-opacity="${g.shadowOpacity}"/>',
        ),
      );
      expect(
        pin,
        contains(
          'translate(${num(PlacePinGeometry.pinOffset.dx)} ${num(PlacePinGeometry.pinOffset.dy)})',
        ),
      );
    }
  });

  test('każdy typ ma własny symbol', () {
    final symbols = <String, String>{};
    for (final type in PlaceType.values) {
      final icon = File(type.iconAsset).readAsStringSync();
      final body = icon
          .substring(
            icon.indexOf('>', icon.indexOf('<g')) + 1,
            icon.lastIndexOf('</g>'),
          )
          .replaceAll(RegExp(r'#[0-9A-F]{6}'), '');
      final duplicate = symbols[body];
      expect(duplicate, isNull, reason: '${type.key} = $duplicate');
      symbols[body] = type.key;
    }
  });

  testWidgets('flutter_svg wczytuje wszystkie SVG bez błędów', (tester) async {
    await tester.runAsync(() async {
      for (final type in PlaceType.values) {
        for (final asset in [
          type.iconAsset,
          type.pinAsset(),
          type.pinAsset(selected: true),
        ]) {
          final info = await vg.loadPicture(SvgAssetLoader(asset), null);
          expect(info.size.isEmpty, isFalse, reason: asset);
          info.picture.dispose();
        }
      }
    });
  });

  testWidgets(
    'PlacePin ma rozmiar korpusu ze specyfikacji, a width go skaluje',
    (tester) async {
      await tester.pumpWidget(
        _app(
          const Wrap(
            children: [
              PlacePin(PlaceType.castle, key: Key('d')),
              PlacePin(PlaceType.castle, key: Key('s'), selected: true),
              PlacePin(PlaceType.castle, key: Key('w'), width: 72),
              PlaceIcon(PlaceType.castle, key: Key('i')),
              PlaceIconBadge(PlaceType.castle, key: Key('b')),
            ],
          ),
        ),
      );
      await _settleSvgs(tester);
      expect(tester.getSize(find.byKey(const Key('d'))), const Size(36, 44));
      expect(tester.getSize(find.byKey(const Key('s'))), const Size(42, 52));
      expect(tester.getSize(find.byKey(const Key('w'))), const Size(72, 88));
      expect(tester.getSize(find.byKey(const Key('i'))), const Size(24, 24));
      expect(tester.getSize(find.byKey(const Key('b'))), const Size(40, 40));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('galeria pokazuje wszystkie kategorie i typy', (tester) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(_app(const PlaceIconGallery(showMap: false)));
    await _settleSvgs(tester);
    expect(find.text('Gastronomia'), findsOneWidget);
    expect(find.text('Restauracja'), findsOneWidget);
    // Przełącznik tła (jasne tło).
    await tester.tap(find.byType(Switch));
    await tester.pump();
    final list = find.descendant(
      of: find.byType(CustomScrollView),
      matching: find.byType(Scrollable),
    );
    await tester.scrollUntilVisible(
      find.text('Pralnia samoobsługowa'),
      400,
      scrollable: list,
    );
    await _settleSvgs(tester);
    expect(find.text('Punkty praktyczne'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  for (final selected in [false, true]) {
    testWidgets(
      'PNG pinezki${selected ? ' zaznaczonej' : ''}: rozmiar, czubek na dole, cień',
      (tester) async {
        await tester.runAsync(() async {
          final png = await renderPlacePinPng(
            PlaceType.lake,
            selected: selected,
          );
          final codec = await ui.instantiateImageCodec(png);
          final image = (await codec.getNextFrame()).image;
          final g = PlacePinGeometry.of(selected: selected);
          expect(image.width, (g.viewBox.width * 3).round());
          expect(image.height, (g.tipY * 3).round());
          final rgba = (await image.toByteData(
            format: ui.ImageByteFormat.rawRgba,
          ))!;
          int alpha(int x, int y) =>
              rgba.getUint8((y * image.width + x) * 4 + 3);
          final cx = image.width ~/ 2;
          // Rożek viewBox jest pusty, środek główki – kolor kategorii, czubek tuż nad dolną krawędzią.
          expect(alpha(0, 0), 0);
          expect(alpha(cx, image.height - 4), greaterThan(200));
          // Cień: obok czubka (poza wąskim korpusem) są półprzezroczyste ciemne piksele.
          final headCenterY =
              ((PlacePinGeometry.pinOffset.dy + g.pinSize.width / 2) * 3)
                  .round();
          expect(alpha(cx, headCenterY), 255);
          final shadowAlpha = alpha(cx + 15, image.height - 3);
          expect(shadowAlpha, inInclusiveRange(1, 200));
          final shadowRed = rgba.getUint8(
            ((image.height - 3) * image.width + cx + 15) * 4,
          );
          expect(shadowRed, lessThan(10), reason: 'cień jest czarny');
          image.dispose();
        });
      },
    );
  }
}
