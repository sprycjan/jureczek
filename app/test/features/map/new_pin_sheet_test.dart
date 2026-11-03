import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jureczek/features/map/domain/pin_kind.dart';
import 'package:jureczek/features/places/domain/place_type.dart';
import 'package:jureczek/features/map/domain/pin_color.dart';
import 'package:jureczek/features/map/domain/place_suggestion.dart';
import 'package:jureczek/features/map/presentation/new_pin_sheet.dart';
import 'package:jureczek/features/map/presentation/pin_form_fields.dart';
import 'package:jureczek/features/map/presentation/search_result_card.dart';
import 'package:jureczek/l10n/app_localizations.dart';

void main() {
  Future<void> pump(WidgetTester tester, Widget child) {
    // Wysoki ekran (jak P30, 360×780 dp, z zapasem) – arkusz z wyborem koloru (v14)
    // nie mieści się w domyślnym 800×600 px.
    tester.view.physicalSize = const Size(1080, 2700);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
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
      expect(saved?.kind, PinKind.standard);
    });

    testWidgets('wybrany typ pinezki trafia do zapisu', (tester) async {
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

      expect(find.text('Pinezka'), findsOneWidget);
      expect(find.byKey(const ValueKey('pin-type-pharmacy')), findsNothing);
      await tester.tap(find.byKey(const ValueKey('pin-category-practical')));
      await tester.pump();
      // Kategoria otwiera siatkę, ale typ zostaje.
      expect(find.text('Pinezka'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('pin-type-pharmacy')));
      await tester.pump();
      expect(find.text('Apteka · Punkty praktyczne'), findsOneWidget);

      await tester.ensureVisible(find.text('Zapisz'));
      await tester.tap(find.text('Zapisz'));
      await tester.pumpAndSettle();

      expect(saved?.kind, const PinKind(PlaceType.pharmacy));
    });

    testWidgets('podpowiedź typu z maki jest wybrana od razu', (tester) async {
      PinDetailsInput? saved;
      await pump(
        tester,
        NewPinSheet(
          place: const PlaceResult(
            name: 'Muzeum Narodowe',
            lat: 50.06,
            lng: 19.92,
            suggestedType: PlaceType.museum,
          ),
          onSave: (details) async {
            saved = details;
            return true;
          },
        ),
      );

      expect(find.text('Muzeum · Miejsca i atrakcje'), findsOneWidget);
      expect(find.byKey(const ValueKey('pin-type-castle')), findsOneWidget);

      // Powrót do zielonej zamyka siatkę.
      await tester.tap(find.byKey(const ValueKey('pin-category-standard')));
      await tester.pump();
      expect(find.byKey(const ValueKey('pin-type-castle')), findsNothing);
      await tester.ensureVisible(find.text('Zapisz'));
      await tester.tap(find.text('Zapisz'));
      await tester.pumpAndSettle();
      expect(saved?.kind, PinKind.standard);
    });

    testWidgets('kolor: domyślnie kolor typu, wybór i powrót do domyślnego', (
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

      expect(find.text('Kolor typu'), findsOneWidget);
      expect(find.text('Domyślny'), findsNothing);
      expect(find.byKey(const ValueKey('pin-color-black')), findsOneWidget);
      expect(
        find.byWidgetPredicate(
          (w) => w is InkWell && '${w.key}'.contains('pin-color-'),
        ),
        findsNWidgets(24),
      );

      await tester.tap(find.byKey(const ValueKey('pin-color-gold')));
      await tester.pump();
      expect(find.text('Złoty'), findsOneWidget);

      await tester.tap(find.text('Domyślny'));
      await tester.pump();
      expect(find.text('Kolor typu'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('pin-color-navy')));
      await tester.pump();
      await tester.ensureVisible(find.text('Zapisz'));
      await tester.tap(find.text('Zapisz'));
      await tester.pumpAndSettle();

      expect(saved?.color, PinColor.navy);
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
