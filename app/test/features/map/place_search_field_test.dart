import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jureczek/features/map/application/place_search_controller.dart';
import 'package:jureczek/features/map/domain/place_suggestion.dart';
import 'package:jureczek/features/map/presentation/place_search_field.dart';
import 'package:jureczek/l10n/app_localizations.dart';

void main() {
  const wawel = PlaceSuggestion(
    mapboxId: 'a',
    name: 'Wawel',
    address: 'Wawel 5, Kraków',
  );

  late FocusNode focusNode;
  late TextEditingController controller;

  setUp(() {
    focusNode = FocusNode();
    controller = TextEditingController();
  });
  tearDown(() {
    focusNode.dispose();
    controller.dispose();
  });

  Future<void> pumpField(
    WidgetTester tester, {
    required PlaceSearchState state,
    ValueChanged<String>? onChanged,
    ValueChanged<PlaceSuggestion>? onSelected,
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
          body: PlaceSearchField(
            controller: controller,
            focusNode: focusNode,
            state: state,
            onChanged: onChanged ?? (_) {},
            onSelected: onSelected ?? (_) {},
          ),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('dostaje fokus i przekazuje wpisany tekst', (tester) async {
    String? typed;
    await pumpField(
      tester,
      state: const PlaceSearchIdle(),
      onChanged: (text) => typed = text,
    );

    expect(focusNode.hasFocus, isTrue);
    expect(find.text('Szukaj miejsca'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'Waw');
    expect(typed, 'Waw');
  });

  testWidgets('pokazuje podpowiedzi z adresem i woła onSelected', (
    tester,
  ) async {
    PlaceSuggestion? selected;
    await pumpField(
      tester,
      state: const PlaceSearchSuggestions([wawel]),
      onSelected: (s) => selected = s,
    );

    expect(find.text('Wawel'), findsOneWidget);
    expect(find.text('Wawel 5, Kraków'), findsOneWidget);

    await tester.tap(find.text('Wawel'));
    expect(selected, wawel);
  });

  testWidgets('pokazuje brak wyników i błąd', (tester) async {
    await pumpField(tester, state: const PlaceSearchEmpty());
    expect(find.text('Brak wyników'), findsOneWidget);

    await pumpField(tester, state: const PlaceSearchError());
    expect(
      find.text('Nie udało się wyszukać – sprawdź połączenie'),
      findsOneWidget,
    );
  });

  testWidgets('w trakcie ładowania zostawia poprzednie podpowiedzi', (
    tester,
  ) async {
    await pumpField(tester, state: const PlaceSearchLoading([wawel]));

    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    expect(find.text('Wawel'), findsOneWidget);
  });

  testWidgets('bez fokusu lista jest schowana, tekst zostaje', (tester) async {
    await pumpField(tester, state: const PlaceSearchSuggestions([wawel]));
    await tester.enterText(find.byType(TextField), 'Wawel');

    focusNode.unfocus();
    await tester.pump();

    expect(find.byType(ListTile), findsNothing);
    expect(controller.text, 'Wawel');
  });
}
