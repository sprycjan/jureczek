import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jureczek/features/map/domain/place_pin.dart';
import 'package:jureczek/features/map/presentation/pin_details_sheet.dart';
import 'package:jureczek/features/map/presentation/pin_form_fields.dart';
import 'package:jureczek/l10n/app_localizations.dart';

void main() {
  PlacePin pin({
    String? name,
    String? note,
    String? address,
    String? sourceUrl,
  }) => PlacePin(
    id: 'a',
    lat: 50.061389,
    lng: 19.938333,
    createdAt: DateTime(2026, 10, 25),
    name: name,
    note: note,
    address: address,
    sourceUrl: sourceUrl,
  );

  Future<void> pumpSheet(
    WidgetTester tester, {
    required PlacePin pin,
    VoidCallback? onDelete,
    SavePinDetails? onSave,
    String? notice,
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
          body: PinDetailsSheet(
            pin: pin,
            onDelete: onDelete ?? () {},
            notice: notice,
            onSave: onSave ?? (_) async => true,
          ),
        ),
      ),
    );
  }

  testWidgets('pokazuje współrzędne i datę dodania', (tester) async {
    await pumpSheet(tester, pin: pin());

    expect(find.text('Miejsce'), findsOneWidget);
    expect(find.text('50.0614, 19.9383'), findsOneWidget);
    expect(find.textContaining('Dodano'), findsOneWidget);
    expect(find.textContaining('2026'), findsOneWidget);
  });

  testWidgets('pinezka bez nazwy pokazuje „Bez nazwy”', (tester) async {
    await pumpSheet(tester, pin: pin());

    expect(find.text('Bez nazwy'), findsOneWidget);
  });

  testWidgets('pokazuje nazwę i notatkę', (tester) async {
    await pumpSheet(
      tester,
      pin: pin(name: 'Wawel', note: 'Bilety online'),
    );

    expect(find.text('Wawel'), findsOneWidget);
    expect(find.text('Bilety online'), findsOneWidget);
  });

  testWidgets('„Usuń” woła onDelete', (tester) async {
    var deleted = false;
    await pumpSheet(tester, pin: pin(), onDelete: () => deleted = true);

    await tester.tap(find.text('Usuń'));

    expect(deleted, isTrue);
  });

  testWidgets('„Zapisz” przekazuje wpisane teksty i wraca do podglądu', (
    tester,
  ) async {
    PinDetailsInput? saved;
    await pumpSheet(
      tester,
      pin: pin(name: 'Stara'),
      onSave: (details) async {
        saved = details;
        return true;
      },
    );

    await tester.tap(find.text('Edytuj'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(TextField, 'Stara'), findsOneWidget);

    await tester.enterText(find.byType(TextField).at(0), '  Wawel ');
    await tester.enterText(find.byType(TextField).at(1), 'Wawel 5, Kraków');
    await tester.enterText(find.byType(TextField).at(2), 'Bilety online');
    await tester.tap(find.text('Zapisz'));
    await tester.pumpAndSettle();

    expect(saved?.name, '  Wawel ');
    expect(saved?.address, 'Wawel 5, Kraków');
    expect(saved?.note, 'Bilety online');
    expect(find.byType(TextField), findsNothing);
    expect(find.text('Wawel'), findsOneWidget);
    expect(find.text('Wawel 5, Kraków'), findsOneWidget);
    expect(find.text('Bilety online'), findsOneWidget);
  });

  testWidgets('„Anuluj” wraca do podglądu bez zapisu', (tester) async {
    var saved = false;
    await pumpSheet(
      tester,
      pin: pin(name: 'Wawel'),
      onSave: (_) async => saved = true,
    );

    await tester.tap(find.text('Edytuj'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).at(0), 'Inna');
    await tester.tap(find.text('Anuluj'));
    await tester.pumpAndSettle();

    expect(saved, isFalse);
    expect(find.text('Wawel'), findsOneWidget);
  });

  testWidgets('nieudany zapis zostawia edycję i pokazuje błąd', (tester) async {
    await pumpSheet(tester, pin: pin(), onSave: (_) async => false);

    await tester.tap(find.text('Edytuj'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Zapisz'));
    await tester.pumpAndSettle();

    expect(find.byType(TextField), findsNWidgets(3));
    expect(find.text('Nie udało się zapisać pinezki'), findsOneWidget);
  });

  testWidgets('pokazuje adres, a przy linku źródłowym przycisk Google Maps', (
    tester,
  ) async {
    await pumpSheet(
      tester,
      pin: pin(
        address: 'Jana Kilińskiego 4, 80-452 Gdańsk',
        sourceUrl: 'https://maps.app.goo.gl/abc',
      ),
    );

    expect(find.text('Jana Kilińskiego 4, 80-452 Gdańsk'), findsOneWidget);
    expect(find.text('Otwórz w Google Maps'), findsOneWidget);
  });

  testWidgets('bez linku źródłowego nie ma przycisku Google Maps', (
    tester,
  ) async {
    await pumpSheet(tester, pin: pin());

    expect(find.text('Otwórz w Google Maps'), findsNothing);
  });

  testWidgets('edycja wypełnia pole adresu', (tester) async {
    await pumpSheet(tester, pin: pin(address: 'Klonowa 01, 80-264 Gdańsk'));

    await tester.tap(find.text('Edytuj'));
    await tester.pumpAndSettle();

    expect(
      find.widgetWithText(TextField, 'Klonowa 01, 80-264 Gdańsk'),
      findsOneWidget,
    );
  });

  testWidgets('pokazuje komunikat o duplikacie', (tester) async {
    await pumpSheet(tester, pin: pin(), notice: 'Ta pinezka już jest');

    expect(find.text('Ta pinezka już jest'), findsOneWidget);
  });
}
