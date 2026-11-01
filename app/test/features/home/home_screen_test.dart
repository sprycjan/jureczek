import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jureczek/core/database/app_database.dart';
import 'package:jureczek/features/folders/application/folders_providers.dart';
import 'package:jureczek/features/folders/presentation/folder_form_screen.dart';
import 'package:jureczek/features/home/presentation/home_screen.dart';
import 'package:jureczek/features/map/application/pins_providers.dart';
import 'package:jureczek/l10n/app_localizations.dart';

void main() {
  late AppDatabase db;
  late ProviderContainer container;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    container = ProviderContainer(
      overrides: [appDatabaseProvider.overrideWithValue(db)],
    );
  });
  tearDown(() async {
    container.dispose();
    await db.close();
  });

  Future<void> pumpHome(WidgetTester tester) async {
    // Ekran jak P30: 1080×2340 px, 3x.
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          locale: const Locale('pl'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            ...GlobalMaterialLocalizations.delegates,
          ],
          home: const HomeScreen(accessToken: 'pk.test'),
        ),
      ),
    );
    // Strumień drift dochodzi asynchronicznie, poza fake async testu.
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pump();
  }

  testWidgets('bez folderów pokazuje zachętę, przycisk otwiera formularz', (
    tester,
  ) async {
    await pumpHome(tester);

    expect(find.text('Cześć Podróżniku!'), findsOneWidget);
    expect(find.text('Nie masz jeszcze żadnego folderu'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Utwórz pierwszy folder'),
      100,
      scrollable: find.byType(Scrollable).first,
    );
    // Tap w trakcie wyhamowywania listy tylko by ją zatrzymał.
    await tester.pumpAndSettle();
    await tester.tap(find.text('Utwórz pierwszy folder'));
    await tester.pumpAndSettle();

    expect(find.byType(FolderFormScreen), findsOneWidget);
  });

  testWidgets('pokazuje foldery z liczbą miejsc, ostatnio zmieniony na górze', (
    tester,
  ) async {
    await tester.runAsync(() async {
      final folders = container.read(foldersControllerProvider);
      final pins = container.read(pinsControllerProvider);
      final a = await folders.create(name: 'Portugalia', description: 'Klify');
      await Future<void>.delayed(const Duration(milliseconds: 5));
      await folders.create(name: 'Bałkany');
      await Future<void>.delayed(const Duration(milliseconds: 5));
      await pins.add(folderId: a, lat: 38.7, lng: -9.1);
      await pins.add(folderId: a, lat: 38.8, lng: -9.2);
    });
    await pumpHome(tester);

    expect(find.text('Nie masz jeszcze żadnego folderu'), findsNothing);
    expect(find.text('Klify'), findsOneWidget);
    expect(find.text('2 miejsca'), findsOneWidget);
    expect(find.text('Brak miejsc'), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('Portugalia')).dy,
      lessThan(tester.getTopLeft(find.text('Bałkany')).dy),
    );
  });
}
