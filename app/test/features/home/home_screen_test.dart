import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jureczek/core/database/app_database.dart';
import 'package:jureczek/features/folders/application/folders_providers.dart';
import 'package:jureczek/features/folders/data/folders_repository.dart';
import 'package:jureczek/features/folders/presentation/folder_form_screen.dart';
import 'package:jureczek/features/home/presentation/home_screen.dart';
import 'package:jureczek/features/map/application/pins_providers.dart';
import 'package:jureczek/features/map/presentation/map_screen.dart';
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

  Future<void> pumpHome(WidgetTester tester, {String token = 'pk.test'}) async {
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
          home: HomeScreen(accessToken: token),
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

    expect(find.text('Cześć!'), findsOneWidget);
    expect(find.textContaining('Dokąd ruszamy'), findsNothing);
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

  testWidgets('snackbar z mapy znika po powrocie na ekran startowy', (
    tester,
  ) async {
    // Bez tokenu mapa to sam komunikat – wystarczy, żeby sprawdzić trasę.
    await pumpHome(tester, token: '');
    await tester.tap(find.text('Mapa – wszystkie pinezki'));
    await tester.pumpAndSettle();

    final mapContext = tester.element(find.byType(MissingTokenView));
    ScaffoldMessenger.of(
      mapContext,
    ).showSnackBar(const SnackBar(content: Text('Dodano pinezkę')));
    await tester.pump();
    expect(find.text('Dodano pinezkę'), findsOneWidget);

    Navigator.of(mapContext).pop();
    await tester.pumpAndSettle();

    expect(find.byType(MissingTokenView), findsNothing);
    expect(find.text('Dodano pinezkę'), findsNothing);
  });

  group('archiwum (v23)', () {
    /// Zapis i strumień bazy idą poza fake async testu.
    Future<void> settle(WidgetTester tester) async {
      await tester.pumpAndSettle();
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await tester.pumpAndSettle();
    }

    Future<String> createFolder(WidgetTester tester, String name) async {
      final id = await tester.runAsync(
        () => container.read(foldersControllerProvider).create(name: name),
      );
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 5)),
      );
      return id!;
    }

    Future<void> archiveInDb(WidgetTester tester, String id, int at) async {
      await tester.runAsync(
        () => container
            .read(foldersRepositoryProvider)
            .setArchiveState(
              id,
              archivedAt: DateTime.fromMillisecondsSinceEpoch(at),
              updatedAt: DateTime.fromMillisecondsSinceEpoch(at),
            ),
      );
    }

    Future<void> openArchive(WidgetTester tester) async {
      await tester.tap(find.text('Archiwum'));
      await tester.pumpAndSettle();
    }

    Future<void> openMenu(WidgetTester tester) async {
      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();
    }

    testWidgets('pusta zakładka: szary pejzaż, bez mapy i nowego folderu', (
      tester,
    ) async {
      await pumpHome(tester);
      expect(find.byType(ColorFiltered), findsNothing);
      expect(find.text('Mapa – wszystkie pinezki'), findsOneWidget);

      await openArchive(tester);

      expect(find.byType(ColorFiltered), findsOneWidget);
      expect(find.text('Cześć!'), findsOneWidget);
      expect(find.text('Archiwum podróży'), findsOneWidget);
      expect(find.text('Nic tu jeszcze nie ma'), findsOneWidget);
      expect(find.text('Mapa – wszystkie pinezki'), findsNothing);
      expect(find.byTooltip('Nowy folder'), findsNothing);
      expect(find.text('Utwórz pierwszy folder'), findsNothing);
    });

    testWidgets('Wstecz z archiwum wraca do podróży', (tester) async {
      await pumpHome(tester);
      await openArchive(tester);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      expect(find.text('Moje listy podróży'), findsOneWidget);
      expect(find.byType(ColorFiltered), findsNothing);
    });

    testWidgets('przesunięcie w lewo archiwizuje, w prawo przywraca', (
      tester,
    ) async {
      await createFolder(tester, 'Portugalia');
      await pumpHome(tester);

      await tester.drag(find.text('Portugalia'), const Offset(-600, 0));
      await settle(tester);

      expect(tester.takeException(), isNull);
      expect(find.text('Portugalia'), findsNothing);
      expect(find.text('Przeniesiono do archiwum'), findsOneWidget);
      // Foldery są, tylko w archiwum – to nie „pierwszy folder”.
      expect(find.text('Nie masz bieżących podróży'), findsOneWidget);
      expect(find.text('Nie masz jeszcze żadnego folderu'), findsNothing);

      await openArchive(tester);
      expect(find.text('Portugalia'), findsOneWidget);

      await tester.drag(find.text('Portugalia'), const Offset(600, 0));
      await settle(tester);

      expect(tester.takeException(), isNull);
      expect(find.text('Portugalia'), findsNothing);
      expect(find.text('Przywrócono z archiwum'), findsOneWidget);
      final folders = await tester.runAsync(
        () => container.read(foldersProvider.future),
      );
      expect(folders!.single.isArchived, isFalse);
    });

    testWidgets('„Cofnij” wraca na dawne miejsce listy', (tester) async {
      final older = await createFolder(tester, 'Portugalia');
      await createFolder(tester, 'Bałkany');
      await tester.runAsync(
        () => container
            .read(pinsControllerProvider)
            .add(folderId: older, lat: 38.7, lng: -9.1),
      );
      await pumpHome(tester);
      expect(
        tester.getTopLeft(find.text('Portugalia')).dy,
        lessThan(tester.getTopLeft(find.text('Bałkany')).dy),
      );

      await tester.drag(find.text('Portugalia'), const Offset(-600, 0));
      await settle(tester);
      expect(find.text('Portugalia'), findsNothing);

      await tester.tap(find.text('Cofnij'));
      await settle(tester);

      expect(
        tester.getTopLeft(find.text('Portugalia')).dy,
        lessThan(tester.getTopLeft(find.text('Bałkany')).dy),
      );
      final folders = await tester.runAsync(
        () => container.read(foldersProvider.future),
      );
      expect(folders!.every((f) => !f.isArchived), isTrue);
    });

    testWidgets('menu: bieżący archiwizuje, w archiwum tylko „Przywróć”', (
      tester,
    ) async {
      await createFolder(tester, 'Portugalia');
      await pumpHome(tester);

      await openMenu(tester);
      expect(find.text('Edytuj'), findsOneWidget);
      await tester.tap(find.text('Archiwizuj'));
      await settle(tester);
      expect(find.text('Portugalia'), findsNothing);

      await openArchive(tester);
      await openMenu(tester);
      expect(find.text('Edytuj'), findsNothing);
      expect(find.text('Archiwizuj'), findsNothing);
      await tester.tap(find.text('Przywróć'));
      await settle(tester);

      expect(find.text('Portugalia'), findsNothing);
      await tester.tap(find.text('Podróże'));
      await tester.pumpAndSettle();
      expect(find.text('Portugalia'), findsOneWidget);
    });

    testWidgets('archiwum: od ostatnio zarchiwizowanego, mapa tylko podgląd', (
      tester,
    ) async {
      final older = await createFolder(tester, 'Portugalia');
      final newer = await createFolder(tester, 'Bałkany');
      await archiveInDb(tester, newer, 2000);
      await archiveInDb(tester, older, 3000);
      await pumpHome(tester, token: '');

      await openArchive(tester);
      expect(
        tester.getTopLeft(find.text('Portugalia')).dy,
        lessThan(tester.getTopLeft(find.text('Bałkany')).dy),
      );

      await tester.tap(find.text('Bałkany'));
      await tester.pumpAndSettle();

      final map = tester.widget<MapScreen>(find.byType(MapScreen));
      expect(map.folderId, newer);
      expect(map.readOnly, isTrue);
    });

    testWidgets('folder bieżący otwiera zwykłą mapę', (tester) async {
      await createFolder(tester, 'Portugalia');
      await pumpHome(tester, token: '');

      await tester.tap(find.text('Portugalia'));
      await tester.pumpAndSettle();

      expect(
        tester.widget<MapScreen>(find.byType(MapScreen)).readOnly,
        isFalse,
      );
    });

    testWidgets('nieudany zapis przywraca kartę i pokazuje błąd', (
      tester,
    ) async {
      container.dispose();
      container = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          foldersRepositoryProvider.overrideWithValue(_FailingRepository(db)),
        ],
      );
      await createFolder(tester, 'Portugalia');
      await pumpHome(tester);

      await tester.drag(find.text('Portugalia'), const Offset(-600, 0));
      await settle(tester);

      expect(tester.takeException(), isNull);
      expect(find.text('Portugalia'), findsOneWidget);
      expect(find.text('Nie udało się zapisać folderu'), findsOneWidget);
      expect(find.text('Przeniesiono do archiwum'), findsNothing);
    });
  });
}

class _FailingRepository extends FoldersRepository {
  _FailingRepository(super.db);

  @override
  Future<void> setArchiveState(
    String id, {
    required DateTime? archivedAt,
    required DateTime updatedAt,
  }) => Future.error(StateError('zapis nie działa'));
}
