import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jureczek/features/map/presentation/map_style.dart';
import 'package:jureczek/features/map/presentation/map_style_picker.dart';
import 'package:jureczek/l10n/app_localizations.dart';

void main() {
  Future<void> pumpPicker(
    WidgetTester tester, {
    MapStyleOption selected = MapStyleOption.vanventure,
    ValueChanged<MapStyleOption>? onSelected,
  }) {
    return tester.pumpWidget(
      MaterialApp(
        locale: const Locale('pl'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          ...GlobalMaterialLocalizations.delegates,
        ],
        home: Scaffold(
          body: Center(
            child: MapStylePicker(
              selected: selected,
              onSelected: onSelected ?? (_) {},
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('pokazuje cztery style z etykietami', (tester) async {
    await pumpPicker(tester);
    for (final label in ['Nocna wyprawa', 'Teren', 'Satelita', '3D']) {
      expect(find.text(label), findsOneWidget);
    }
  });

  testWidgets('tap w styl zwraca go przez onSelected', (tester) async {
    MapStyleOption? chosen;
    await pumpPicker(tester, onSelected: (style) => chosen = style);
    await tester.tap(find.text('Satelita'));
    expect(chosen, MapStyleOption.satellite);
  });

  testWidgets('wybrany styl jest w kolorze akcentu', (tester) async {
    await pumpPicker(tester, selected: MapStyleOption.outdoors);
    final context = tester.element(find.byType(MapStylePicker));
    final primary = Theme.of(context).colorScheme.primary;
    Color? colorOf(String label) =>
        tester.widget<Text>(find.text(label)).style?.color;
    expect(colorOf('Teren'), primary);
    expect(colorOf('Satelita'), isNot(primary));
  });

  test('tylko 3D pochyla kamerę i ustawia motyw faded', () {
    for (final style in MapStyleOption.values) {
      expect(style.pitch, style == MapStyleOption.faded3d ? 60 : 0);
    }
    expect(MapStyleOption.faded3d.basemapConfig['theme'], 'faded');
    expect(MapStyleOption.vanventure.uri, mapStyleUri);
  });
}
