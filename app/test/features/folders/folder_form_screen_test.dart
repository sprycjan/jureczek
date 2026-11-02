import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jureczek/core/database/app_database.dart';
import 'package:jureczek/features/folders/data/folders_repository.dart';
import 'package:jureczek/features/folders/domain/trip_folder.dart';
import 'package:jureczek/features/folders/presentation/folder_form_screen.dart';
import 'package:jureczek/l10n/app_localizations.dart';

void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  /// Otwiera formularz przyciskiem, żeby dało się odczytać wynik `pop`.
  Future<List<FolderFormResult?>> pumpForm(
    WidgetTester tester, {
    TripFolder? folder,
  }) async {
    final results = <FolderFormResult?>[];
    // Ekran jak P30: 1080×2340 px, 3x.
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
        child: MaterialApp(
          locale: const Locale('pl'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            ...GlobalMaterialLocalizations.delegates,
          ],
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () async => results.add(
                await Navigator.of(context).push(
                  MaterialPageRoute<FolderFormResult>(
                    builder: (_) => FolderFormScreen(folder: folder),
                  ),
                ),
              ),
              child: const Text('otwórz'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('otwórz'));
    await tester.pumpAndSettle();
    return results;
  }

  /// Dolny pasek jest zawsze widoczny; duży przycisk trzeba przewinąć.
  Future<void> saveVia(WidgetTester tester, Finder button) async {
    if (button.evaluate().isEmpty) {
      await tester.scrollUntilVisible(
        button,
        100,
        scrollable: find.byType(Scrollable).first,
      );
    }
    await tester.ensureVisible(button);
    await tester.tap(button);
    // Zapis do drift idzie poza fake async.
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('bez nazwy nie zapisuje i pokazuje błąd', (tester) async {
    final results = await pumpForm(tester);

    await saveVia(tester, find.byKey(const ValueKey('folder-save')));

    expect(find.text('Podaj nazwę folderu'), findsOneWidget);
    expect(results, isEmpty);
  });

  testWidgets('podgląd pokazuje wpisaną nazwę', (tester) async {
    await pumpForm(tester);
    expect(find.text('Nowa lista'), findsOneWidget);

    await tester.enterText(find.byType(TextField).first, 'Portugalia');
    await tester.pump();

    expect(find.text('Portugalia'), findsNWidgets(2));
  });

  testWidgets('podgląd bez obrazka i bez zastępczego opisu', (tester) async {
    await pumpForm(tester);

    expect(find.byType(Image), findsNothing);
    expect(find.textContaining('Dzikie postoje'), findsNothing);

    await tester.enterText(find.byType(TextField).at(1), 'Klify i plaże');
    await tester.pump();

    expect(find.text('Klify i plaże'), findsNWidgets(2));
  });

  testWidgets('ikony i kolory spoza ekranu dostępne po przewinięciu rzędu', (
    tester,
  ) async {
    final results = await pumpForm(tester);
    await tester.enterText(find.byType(TextField).first, 'Alpy zimą');
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('folder-colors')),
      100,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('folder-icon-ski')),
      100,
      scrollable: find.descendant(
        of: find.byKey(const ValueKey('folder-icons')),
        matching: find.byType(Scrollable),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('folder-icon-ski')));
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('folder-color-slate')),
      100,
      scrollable: find.descendant(
        of: find.byKey(const ValueKey('folder-colors')),
        matching: find.byType(Scrollable),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('folder-color-slate')));
    await tester.pump();

    await saveVia(tester, find.byKey(const ValueKey('folder-save')));

    final saved = await tester.runAsync(
      () => FoldersRepository(db).findById(results.single!.folderId),
    );
    expect(saved?.icon, FolderIcon.ski);
    expect(saved?.color, FolderColor.slate);
  });

  testWidgets('„Utwórz” zapisuje ikonę i kolor i wraca bez mapy', (
    tester,
  ) async {
    final results = await pumpForm(tester);
    await tester.enterText(find.byType(TextField).first, 'Portugalia');
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('folder-color-amber')),
      100,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.byKey(const ValueKey('folder-icon-beach')));
    await tester.tap(find.byKey(const ValueKey('folder-color-amber')));
    await tester.pump();

    await saveVia(tester, find.byKey(const ValueKey('folder-save')));

    expect(results.single?.openMap, isFalse);
    final saved = await tester.runAsync(
      () => FoldersRepository(db).findById(results.single!.folderId),
    );
    expect(saved?.name, 'Portugalia');
    expect(saved?.icon, FolderIcon.beach);
    expect(saved?.color, FolderColor.amber);
  });

  testWidgets('duży przycisk tworzy folder i prosi o mapę', (tester) async {
    final results = await pumpForm(tester);
    await tester.enterText(find.byType(TextField).first, 'Bałkany');

    await saveVia(tester, find.text('Utwórz folder i dodaj pierwsze pinezki'));

    expect(results.single?.openMap, isTrue);
  });

  testWidgets('edycja: pola wypełnione, „Zapisz”, bez dużego przycisku', (
    tester,
  ) async {
    final folder = TripFolder(
      id: 'f',
      name: 'Pinezki',
      description: 'Różne',
      icon: FolderIcon.compass,
      createdAt: DateTime(2026, 11, 1),
      updatedAt: DateTime(2026, 11, 1),
    );
    await tester.runAsync(() => FoldersRepository(db).insert(folder));
    final results = await pumpForm(tester, folder: folder);

    expect(find.text('Edytuj folder'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'Różne'), findsOneWidget);
    expect(find.text('Utwórz folder i dodaj pierwsze pinezki'), findsNothing);

    await tester.enterText(find.byType(TextField).first, 'Moje miejsca');
    await saveVia(tester, find.byKey(const ValueKey('folder-save')));

    expect(results.single?.folderId, 'f');
    final saved = await tester.runAsync(
      () => FoldersRepository(db).findById('f'),
    );
    expect(saved?.name, 'Moje miejsca');
    expect(saved?.icon, FolderIcon.compass);
  });
}
