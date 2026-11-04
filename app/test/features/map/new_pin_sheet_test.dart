import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jureczek/features/map/domain/pin_kind.dart';
import 'package:jureczek/features/places/domain/place_type.dart';
import 'package:jureczek/features/map/domain/pin_color.dart';
import 'package:jureczek/features/map/domain/place_pin.dart';
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

  Future<void> openCategories(WidgetTester tester) async {
    await tester.tap(find.byKey(const ValueKey('pin-category-field')));
    await tester.pumpAndSettle();
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
      await openCategories(tester);
      await tester.tap(find.byKey(const ValueKey('pin-category-practical')));
      await tester.pumpAndSettle();
      // Kategoria sama otwiera listę typów.
      await tester.tap(find.byKey(const ValueKey('pin-type-pharmacy')));
      await tester.pumpAndSettle();
      expect(find.text('Punkty praktyczne'), findsOneWidget);
      expect(find.text('Apteka'), findsOneWidget);

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

      expect(find.text('Muzeum'), findsOneWidget);
      expect(find.text('Miejsca i atrakcje'), findsOneWidget);

      // Zielona nie ma typów: pole „Typ” jest wyszarzone i się nie otwiera.
      await openCategories(tester);
      await tester.tap(find.byKey(const ValueKey('pin-category-standard')));
      await tester.pumpAndSettle();
      expect(find.text('—'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('pin-type-field')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('pin-type-castle')), findsNothing);

      await tester.ensureVisible(find.text('Zapisz'));
      await tester.tap(find.text('Zapisz'));
      await tester.pumpAndSettle();
      expect(saved?.kind, PinKind.standard);
    });

    testWidgets('nowa kategoria ustawia „Inne” i zostaje po zamknięciu listy', (
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

      await openCategories(tester);
      await tester.tap(find.byKey(const ValueKey('pin-category-nature')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('pin-type-lake')), findsOneWidget);

      // Tap obok zamyka listę bez wyboru.
      await tester.tapAt(const Offset(180, 880));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('pin-type-lake')), findsNothing);

      await tester.ensureVisible(find.text('Zapisz'));
      await tester.tap(find.text('Zapisz'));
      await tester.pumpAndSettle();
      expect(saved?.kind, const PinKind(PlaceType.natureOther));
    });

    testWidgets('ta sama kategoria nie kasuje wybranego typu', (tester) async {
      await pump(
        tester,
        NewPinSheet(
          place: const PlaceResult(
            name: 'Muzeum Narodowe',
            lat: 50.06,
            lng: 19.92,
            suggestedType: PlaceType.museum,
          ),
          onSave: (_) async => true,
        ),
      );

      await openCategories(tester);
      await tester.tap(find.byKey(const ValueKey('pin-category-places')));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('pin-type-castle')), findsOneWidget);
      expect(find.text('Inne'), findsOneWidget); // tylko na liście typów
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

      await tester.ensureVisible(find.byKey(const ValueKey('pin-color-gold')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('pin-color-gold')));
      await tester.pumpAndSettle();
      expect(find.text('Złoty'), findsOneWidget);

      await tester.tap(find.text('Domyślny'));
      await tester.pumpAndSettle();
      expect(find.text('Kolor typu'), findsOneWidget);

      await tester.ensureVisible(find.byKey(const ValueKey('pin-color-navy')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('pin-color-navy')));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Zapisz'));
      await tester.tap(find.text('Zapisz'));
      await tester.pumpAndSettle();

      expect(saved?.color, PinColor.navy);
    });

    testWidgets('strzałki przewijają kolory i wyszarzają się na końcach', (
      tester,
    ) async {
      await pump(tester, NewPinSheet(place: mall, onSave: (_) async => true));
      await tester.pumpAndSettle();

      IconButton arrow(String key) => tester.widget<IconButton>(
        find.descendant(
          of: find.byKey(ValueKey(key)),
          matching: find.byType(IconButton),
        ),
      );
      const back = 'pin-color-scroll-back';
      const forward = 'pin-color-scroll-forward';
      double firstSwatchX() =>
          tester.getTopLeft(find.byKey(const ValueKey('pin-color-red'))).dx;

      expect(arrow(back).onPressed, isNull);
      expect(arrow(forward).onPressed, isNotNull);

      final startX = firstSwatchX();
      await tester.tap(find.byKey(const ValueKey(forward)));
      await tester.pumpAndSettle();
      expect(firstSwatchX(), lessThan(startX));
      expect(arrow(back).onPressed, isNotNull);

      for (var i = 0; i < 10 && arrow(forward).onPressed != null; i++) {
        await tester.tap(find.byKey(const ValueKey(forward)));
        await tester.pumpAndSettle();
      }
      expect(arrow(forward).onPressed, isNull);
      expect(arrow(back).onPressed, isNotNull);
    });

    testWidgets('licznik znaków pojawia się dopiero przy końcu limitu', (
      tester,
    ) async {
      await pump(tester, NewPinSheet(place: mall, onSave: (_) async => true));

      expect(find.textContaining(RegExp(r'^\d+/\d+$')), findsNothing);

      await tester.enterText(
        find.byType(TextField).at(0),
        'x' * PlacePin.maxNameLength,
      );
      await tester.pump();
      expect(
        find.text('${PlacePin.maxNameLength}/${PlacePin.maxNameLength}'),
        findsOneWidget,
      );
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
