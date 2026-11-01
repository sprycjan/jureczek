import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jureczek/core/database/app_database.dart';
import 'package:jureczek/features/folders/application/folders_providers.dart';
import 'package:jureczek/features/map/domain/place_suggestion.dart';
import 'package:jureczek/features/map/presentation/new_pin_sheet.dart';
import 'package:jureczek/features/map/presentation/pin_form_fields.dart';
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

  Future<void> settleDb(WidgetTester tester) async {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pump();
  }

  Future<List<PinDetailsInput>> pumpSheet(
    WidgetTester tester, {
    bool chooseFolder = true,
  }) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final saved = <PinDetailsInput>[];
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
          home: Scaffold(
            body: NewPinSheet(
              place: const PlaceResult(
                name: 'Cabo da Roca',
                lat: 38.78,
                lng: -9.5,
              ),
              chooseFolder: chooseFolder,
              onSave: (details) async {
                saved.add(details);
                return true;
              },
            ),
          ),
        ),
      ),
    );
    await settleDb(tester);
    return saved;
  }

  testWidgets('bez folderów proponuje „Pinezki” (null = utwórz przy zapisie)', (
    tester,
  ) async {
    final saved = await pumpSheet(tester);

    final chip = tester.widget<ChoiceChip>(
      find.descendant(
        of: find.byKey(const ValueKey('folder-default')),
        matching: find.byType(ChoiceChip),
      ),
    );
    expect(chip.selected, isTrue);

    await tester.tap(find.text('Zapisz'));
    await tester.pumpAndSettle();
    expect(saved.single.folderId, isNull);
  });

  testWidgets('wybrany folder trafia do zapisu', (tester) async {
    late String id;
    await tester.runAsync(() async {
      id = await container
          .read(foldersControllerProvider)
          .create(name: 'Portugalia');
    });
    final saved = await pumpSheet(tester);

    await tester.tap(find.text('Portugalia'));
    await tester.pump();
    await tester.tap(find.text('Zapisz'));
    await tester.pumpAndSettle();

    expect(saved.single.folderId, id);
  });

  testWidgets('„+ Nowy folder” tworzy folder z nazwą i go wybiera', (
    tester,
  ) async {
    final saved = await pumpSheet(tester);

    await tester.tap(find.byKey(const ValueKey('folder-new')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, 'Bałkany');
    await tester.tap(find.widgetWithText(FilledButton, 'Utwórz'));
    await tester.pumpAndSettle();
    await settleDb(tester);
    await tester.pumpAndSettle();

    expect(find.text('Bałkany'), findsOneWidget);
    await tester.tap(find.text('Zapisz'));
    await tester.pumpAndSettle();

    final folders = await tester.runAsync(
      () => container.read(foldersProvider.future),
    );
    expect(saved.single.folderId, folders!.single.id);
  });

  testWidgets('w trybie folderu nie ma wyboru folderu', (tester) async {
    await pumpSheet(tester, chooseFolder: false);

    expect(find.text('Folder'), findsNothing);
  });
}
