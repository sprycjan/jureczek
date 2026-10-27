import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jureczek/features/map/domain/place_suggestion.dart';
import 'package:jureczek/features/map/presentation/new_pin_sheet.dart';
import 'package:jureczek/features/map/presentation/pin_form_fields.dart';
import 'package:jureczek/features/map/presentation/search_result_card.dart';
import 'package:jureczek/l10n/app_localizations.dart';

void main() {
  Future<void> pump(WidgetTester tester, Widget child) {
    return tester.pumpWidget(
      MaterialApp(
        locale: const Locale('pl'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          ...GlobalMaterialLocalizations.delegates,
        ],
        home: Scaffold(body: child),
      ),
    );
  }

  const mall = PlaceResult(
    name: 'Galeria Metropolia',
    address: 'Jana Kilińskiego 4, 80-452 Gdańsk',
    lat: 54.38,
    lng: 18.60,
    approximate: true,
  );

  group('NewPinSheet', () {
    testWidgets('wypełnia nazwę i adres, a „Zapisz” przekazuje poprawki', (
      tester,
    ) async {
      PinDetailsInput? saved;
      await pump(
        tester,
        NewPinSheet(
          place: mall,
          onSave: (details) async {
            saved = details;
            return true;
          },
        ),
      );

      expect(find.text('Nowa pinezka'), findsOneWidget);
      expect(
        find.widgetWithText(TextField, 'Galeria Metropolia'),
        findsOneWidget,
      );
      expect(
        find.widgetWithText(TextField, 'Jana Kilińskiego 4, 80-452 Gdańsk'),
        findsOneWidget,
      );

      await tester.enterText(find.byType(TextField).at(0), 'Metropolia');
      await tester.enterText(find.byType(TextField).at(2), 'Kino');
      await tester.tap(find.text('Zapisz'));
      await tester.pumpAndSettle();

      expect(saved?.name, 'Metropolia');
      expect(saved?.address, 'Jana Kilińskiego 4, 80-452 Gdańsk');
      expect(saved?.note, 'Kino');
    });

    testWidgets('nieudany zapis pokazuje błąd', (tester) async {
      await pump(tester, NewPinSheet(place: mall, onSave: (_) async => false));

      await tester.tap(find.text('Zapisz'));
      await tester.pumpAndSettle();

      expect(find.text('Nie udało się zapisać pinezki'), findsOneWidget);
    });
  });

  group('SearchResultCard', () {
    testWidgets('w trakcie odczytu pokazuje „Odczytuję miejsce…” i pasek', (
      tester,
    ) async {
      await pump(tester, SearchResultCard.loading(onClose: () {}));

      expect(find.text('Odczytuję miejsce…'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
      expect(find.text('Dodaj pinezkę'), findsNothing);
    });

    testWidgets('przybliżone położenie ma ostrzeżenie i „Popraw położenie”', (
      tester,
    ) async {
      var adjusted = false;
      await pump(
        tester,
        SearchResultCard(
          result: mall,
          onAddPin: () {},
          onAdjust: () => adjusted = true,
          onClose: () {},
        ),
      );

      expect(find.textContaining('Położenie przybliżone'), findsOneWidget);
      await tester.tap(find.text('Popraw położenie'));
      expect(adjusted, isTrue);
    });

    testWidgets('miejsce bez nazwy to „Bez nazwy”, dokładne bez ostrzeżenia', (
      tester,
    ) async {
      await pump(
        tester,
        SearchResultCard(
          result: const PlaceResult(name: null, lat: 54, lng: 18),
          onAddPin: () {},
          onAdjust: () {},
          onClose: () {},
        ),
      );

      expect(find.text('Bez nazwy'), findsOneWidget);
      expect(find.textContaining('Położenie przybliżone'), findsNothing);
    });
  });
}
