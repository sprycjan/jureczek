import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jureczek/features/map/domain/pin_category_filter.dart';
import 'package:jureczek/features/map/domain/pin_kind.dart';
import 'package:jureczek/features/map/domain/place_pin.dart';
import 'package:jureczek/features/map/presentation/map_tools.dart';
import 'package:jureczek/features/map/presentation/pin_category_filter_panel.dart';
import 'package:jureczek/features/places/domain/place_category.dart';
import 'package:jureczek/features/places/domain/place_type.dart';
import 'package:jureczek/l10n/app_localizations.dart';

PlacePin _pin(String id, PinKind kind) => PlacePin(
  id: id,
  lat: 50,
  lng: 20,
  createdAt: DateTime(2026),
  folderId: 'f',
  kind: kind,
);

void main() {
  final pins = [
    _pin('a', PinKind.standard),
    _pin('b', const PinKind(PlaceType.cafe)),
    _pin('c', const PinKind(PlaceType.restaurant)),
  ];

  Future<void> pumpPanel(
    WidgetTester tester, {
    PinCategoryFilter filter = PinCategoryFilter.all,
    ValueChanged<PinCategoryFilter>? onChanged,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('pl'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          ...GlobalMaterialLocalizations.delegates,
        ],
        home: Scaffold(
          body: Center(
            child: PinCategoryFilterPanel(
              pins: pins,
              filter: filter,
              onChanged: onChanged ?? (_) {},
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  Finder row(String key) => find.byKey(ValueKey('pin-filter-$key'));

  Finder inRow(String key, Finder finder) =>
      find.descendant(of: row(key), matching: finder);

  testWidgets('pokazuje „Wszystkie”, zieloną i 7 kategorii', (tester) async {
    await pumpPanel(tester);
    expect(row('all'), findsOneWidget);
    expect(row('standard'), findsOneWidget);
    for (final category in PlaceCategory.values) {
      expect(row(category.key), findsOneWidget);
    }
  });

  testWidgets('liczby: razem, na zieloną i na kategorię; pusta to 0', (
    tester,
  ) async {
    await pumpPanel(tester);
    expect(inRow('all', find.text('3')), findsOneWidget);
    expect(inRow('standard', find.text('1')), findsOneWidget);
    expect(inRow('gastronomy', find.text('2')), findsOneWidget);
    expect(inRow('nature', find.text('0')), findsOneWidget);
  });

  testWidgets('domyślnie ptaszek jest przy wszystkich wierszach', (
    tester,
  ) async {
    await pumpPanel(tester);
    expect(find.byIcon(Icons.check), findsNWidgets(9));
  });

  testWidgets('przy aktywnym filtrze ptaszek tylko przy wybranej', (
    tester,
  ) async {
    await pumpPanel(
      tester,
      filter: PinCategoryFilter.all.toggle(PlaceCategory.nature),
    );
    expect(find.byIcon(Icons.check), findsOneWidget);
    expect(inRow('nature', find.byIcon(Icons.check)), findsOneWidget);
  });

  testWidgets('tap w kategorię i zieloną zwraca nowy filtr', (tester) async {
    PinCategoryFilter? changed;
    await pumpPanel(tester, onChanged: (filter) => changed = filter);

    await tester.tap(row('nature'));
    expect(changed!.shows(PlaceCategory.nature), isTrue);
    expect(changed!.shows(PlaceCategory.travel), isFalse);

    await tester.tap(row('standard'));
    expect(changed!.shows(null), isTrue);
    expect(changed!.shows(PlaceCategory.nature), isFalse);
  });

  testWidgets('„Wszystkie” resetuje filtr', (tester) async {
    PinCategoryFilter? changed;
    await pumpPanel(
      tester,
      filter: PinCategoryFilter.all.toggle(PlaceCategory.nature),
      onChanged: (filter) => changed = filter,
    );
    await tester.tap(row('all'));
    expect(changed, same(PinCategoryFilter.all));
  });

  testWidgets('na niskim ekranie lista się przewija zamiast wylewać', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(400, 300));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await pumpPanel(tester);
    expect(tester.takeException(), isNull);
    expect(find.byType(SingleChildScrollView), findsOneWidget);
  });

  group('MapToolButton', () {
    Future<void> pumpButton(WidgetTester tester, {required bool active}) {
      return tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MapToolButton(
              icon: Icons.filter_alt,
              tooltip: 'Filtr',
              active: active,
              onPressed: () {},
            ),
          ),
        ),
      );
    }

    testWidgets('aktywny ma ikonę w kolorze akcentu', (tester) async {
      await pumpButton(tester, active: true);
      final context = tester.element(find.byType(MapToolButton));
      final icon = tester.widget<Icon>(find.byIcon(Icons.filter_alt));
      expect(icon.color, Theme.of(context).colorScheme.primary);
    });

    testWidgets('nieaktywny ma domyślny kolor', (tester) async {
      await pumpButton(tester, active: false);
      final icon = tester.widget<Icon>(find.byIcon(Icons.filter_alt));
      expect(icon.color, isNull);
    });
  });
}
