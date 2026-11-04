import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jureczek/features/map/domain/pin_kind.dart';
import 'package:jureczek/features/places/domain/place_type.dart';
import 'package:jureczek/features/map/domain/pin_color.dart';
import 'package:jureczek/features/map/domain/place_pin.dart';
import 'package:jureczek/features/map/presentation/pin_details_sheet.dart';
import 'package:jureczek/features/map/presentation/pin_form_fields.dart';
import 'package:jureczek/features/map/presentation/pin_image.dart';
import 'package:jureczek/l10n/app_localizations.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';

class _FakeLauncher extends Fake
    with MockPlatformInterfaceMixin
    implements UrlLauncherPlatform {
  _FakeLauncher({this.result = true, this.error});

  final bool result;
  final Object? error;
  final urls = <String>[];
  final modes = <PreferredLaunchMode>[];

  @override
  Future<bool> launchUrl(String url, LaunchOptions options) async {
    urls.add(url);
    modes.add(options.mode);
    if (error != null) throw error!;
    return result;
  }
}

void main() {
  PlacePin pin({
    String? name,
    String? note,
    String? address,
    String? sourceUrl,
    PinKind kind = PinKind.standard,
    PinColor? color,
    DateTime? visitedAt,
    bool starred = false,
  }) => PlacePin(
    folderId: 'f',
    id: 'a',
    lat: 50.061389,
    lng: 19.938333,
    createdAt: DateTime(2026, 10, 25),
    name: name,
    note: note,
    address: address,
    sourceUrl: sourceUrl,
    kind: kind,
    color: color,
    visitedAt: visitedAt,
    starred: starred,
  );

  Future<void> pumpSheet(
    WidgetTester tester, {
    required PlacePin pin,
    VoidCallback? onDelete,
    SavePinDetails? onSave,
    Future<bool> Function(bool visited)? onSetVisited,
    Future<bool> Function(bool starred)? onSetStarred,
    String? notice,
  }) {
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
        home: Scaffold(
          body: PinDetailsSheet(
            pin: pin,
            onDelete: onDelete ?? () {},
            notice: notice,
            onSave: onSave ?? (_) async => true,
            onSetVisited: onSetVisited ?? (_) async => true,
            onSetStarred: onSetStarred ?? (_) async => true,
          ),
        ),
      ),
    );
  }

  testWidgets('pokazuje współrzędne i datę dodania', (tester) async {
    await pumpSheet(tester, pin: pin());

    expect(find.text('Pinezka'), findsOneWidget);
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

  testWidgets('bez linku źródłowego też jest przycisk Google Maps (v19)', (
    tester,
  ) async {
    await pumpSheet(tester, pin: pin());

    expect(find.text('Otwórz w Google Maps'), findsOneWidget);
    expect(find.text('Nie udało się otworzyć Google Maps'), findsNothing);
  });

  group('otwieranie Google Maps (v19)', () {
    final original = UrlLauncherPlatform.instance;
    tearDown(() => UrlLauncherPlatform.instance = original);

    testWidgets('otwiera link pinezki w aplikacji zewnętrznej', (tester) async {
      final launcher = _FakeLauncher(result: true);
      UrlLauncherPlatform.instance = launcher;
      await pumpSheet(
        tester,
        pin: pin(sourceUrl: 'https://maps.app.goo.gl/abc'),
      );

      await tester.tap(find.text('Otwórz w Google Maps'));
      await tester.pump();

      expect(launcher.urls, ['https://maps.app.goo.gl/abc']);
      expect(launcher.modes, [PreferredLaunchMode.externalApplication]);
      expect(find.text('Nie udało się otworzyć Google Maps'), findsNothing);
    });

    testWidgets('gdy link się nie otworzy, arkusz pokazuje błąd', (
      tester,
    ) async {
      UrlLauncherPlatform.instance = _FakeLauncher(result: false);
      await pumpSheet(tester, pin: pin());

      await tester.tap(find.text('Otwórz w Google Maps'));
      await tester.pump();

      expect(find.text('Nie udało się otworzyć Google Maps'), findsOneWidget);
    });

    testWidgets('wyjątek platformy też pokazuje błąd', (tester) async {
      UrlLauncherPlatform.instance = _FakeLauncher(
        error: PlatformException(code: 'ACTIVITY_NOT_FOUND'),
      );
      await pumpSheet(tester, pin: pin());

      await tester.tap(find.text('Otwórz w Google Maps'));
      await tester.pump();

      expect(find.text('Nie udało się otworzyć Google Maps'), findsOneWidget);
    });
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

  group('odwiedzona (v21)', () {
    final button = find.byKey(const ValueKey('pin-visited-button'));

    testWidgets('kontur przed oznaczeniem, wypełnienie po nim', (tester) async {
      final calls = <bool>[];
      await pumpSheet(
        tester,
        pin: pin(),
        onSetVisited: (visited) async {
          calls.add(visited);
          return true;
        },
      );
      expect(find.byIcon(Icons.thumb_up_outlined), findsOneWidget);
      expect(find.byTooltip('Oznacz jako odwiedzone'), findsOneWidget);

      await tester.tap(button);
      await tester.pump();

      expect(calls, [true]);
      expect(find.byIcon(Icons.thumb_up), findsOneWidget);
      expect(find.byTooltip('Cofnij oznaczenie odwiedzenia'), findsOneWidget);
    });

    testWidgets('odwiedzona startuje z wypełnieniem i można ją odznaczyć', (
      tester,
    ) async {
      final calls = <bool>[];
      await pumpSheet(
        tester,
        pin: pin(visitedAt: DateTime(2026, 11, 3)),
        onSetVisited: (visited) async {
          calls.add(visited);
          return true;
        },
      );
      expect(find.byIcon(Icons.thumb_up), findsOneWidget);

      await tester.tap(button);
      await tester.pump();

      expect(calls, [false]);
      expect(find.byIcon(Icons.thumb_up_outlined), findsOneWidget);
    });

    testWidgets('nieudany zapis cofa ikonkę i pokazuje błąd', (tester) async {
      await pumpSheet(tester, pin: pin(), onSetVisited: (_) async => false);

      await tester.tap(button);
      await tester.pump();

      expect(find.byIcon(Icons.thumb_up_outlined), findsOneWidget);
      expect(find.text('Nie udało się zapisać pinezki'), findsOneWidget);
    });

    testWidgets('w trakcie zapisu kolejne tapnięcie nic nie wysyła', (
      tester,
    ) async {
      final pending = Completer<bool>();
      var calls = 0;
      await pumpSheet(
        tester,
        pin: pin(),
        onSetVisited: (_) {
          calls++;
          return pending.future;
        },
      );

      await tester.tap(button);
      await tester.pump();
      await tester.tap(button, warnIfMissed: false);
      await tester.pump();
      expect(calls, 1);

      pending.complete(true);
      await tester.pump();
      expect(tester.widget<IconButton>(button).onPressed, isNotNull);
    });

    testWidgets('w trybie edycji nie ma ikonki', (tester) async {
      await pumpSheet(tester, pin: pin());

      await tester.tap(find.text('Edytuj'));
      await tester.pumpAndSettle();

      expect(button, findsNothing);
    });
  });

  group('gwiazdka (v22)', () {
    final button = find.byKey(const ValueKey('pin-starred-button'));

    testWidgets('stoi przed kciukiem; kontur przed oznaczeniem, potem złota', (
      tester,
    ) async {
      final calls = <bool>[];
      await pumpSheet(
        tester,
        pin: pin(),
        onSetStarred: (starred) async {
          calls.add(starred);
          return true;
        },
      );
      expect(find.byIcon(Icons.star_border), findsOneWidget);
      expect(find.byTooltip('Oznacz jako główny punkt'), findsOneWidget);
      expect(
        tester.getCenter(button).dx,
        lessThan(
          tester.getCenter(find.byKey(const ValueKey('pin-visited-button'))).dx,
        ),
      );

      await tester.tap(button);
      await tester.pump();

      expect(calls, [true]);
      expect(tester.widget<Icon>(find.byIcon(Icons.star)).color, pinStarColor);
      expect(
        find.byTooltip('Cofnij oznaczenie głównego punktu'),
        findsOneWidget,
      );
    });

    testWidgets('z gwiazdką startuje wypełniona i można ją zdjąć', (
      tester,
    ) async {
      final calls = <bool>[];
      await pumpSheet(
        tester,
        pin: pin(starred: true),
        onSetStarred: (starred) async {
          calls.add(starred);
          return true;
        },
      );
      expect(find.byIcon(Icons.star), findsOneWidget);

      await tester.tap(button);
      await tester.pump();

      expect(calls, [false]);
      expect(find.byIcon(Icons.star_border), findsOneWidget);
    });

    testWidgets('błąd zapisu cofa ikonkę i pokazuje komunikat', (tester) async {
      await pumpSheet(tester, pin: pin(), onSetStarred: (_) async => false);

      await tester.tap(button);
      await tester.pump();

      expect(find.byIcon(Icons.star_border), findsOneWidget);
      expect(find.text('Nie udało się zapisać pinezki'), findsOneWidget);
    });

    testWidgets('w trakcie zapisu kolejne tapnięcie nic nie wysyła', (
      tester,
    ) async {
      final pending = Completer<bool>();
      var calls = 0;
      await pumpSheet(
        tester,
        pin: pin(),
        onSetStarred: (_) {
          calls++;
          return pending.future;
        },
      );

      await tester.tap(button);
      await tester.pump();
      await tester.tap(button, warnIfMissed: false);
      await tester.pump();
      expect(calls, 1);

      pending.complete(true);
      await tester.pump();
      expect(tester.widget<IconButton>(button).onPressed, isNotNull);
    });

    testWidgets('w trybie edycji nie ma ikonki', (tester) async {
      await pumpSheet(tester, pin: pin(starred: true));

      await tester.tap(find.text('Edytuj'));
      await tester.pumpAndSettle();

      expect(button, findsNothing);
    });
  });

  testWidgets('pokazuje komunikat o duplikacie', (tester) async {
    await pumpSheet(tester, pin: pin(), notice: 'Ta pinezka już jest');

    expect(find.text('Ta pinezka już jest'), findsOneWidget);
  });

  testWidgets('pokazuje typ pinezki z kategorią', (tester) async {
    await pumpSheet(tester, pin: pin(kind: const PinKind(PlaceType.lake)));

    expect(find.text('Jezioro · Natura i widoki'), findsOneWidget);
  });

  testWidgets('w edycji zmienia typ i przekazuje go do zapisu', (tester) async {
    PinDetailsInput? saved;
    await pumpSheet(
      tester,
      pin: pin(kind: const PinKind(PlaceType.lake)),
      onSave: (details) async {
        saved = details;
        return true;
      },
    );

    await tester.tap(find.text('Edytuj'));
    await tester.pumpAndSettle();
    // Pola od razu pokazują zapisany typ, a klawiatura nie wyskakuje sama.
    expect(find.text('Jezioro'), findsOneWidget);
    expect(find.text('Natura i widoki'), findsOneWidget);
    expect(
      FocusManager.instance.primaryFocus?.context?.widget,
      isNot(isA<EditableText>()),
    );

    await tester.tap(find.byKey(const ValueKey('pin-category-field')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('pin-category-gastronomy')));
    await tester.pumpAndSettle();
    // Kategoria otwiera listę typów.
    await tester.tap(find.byKey(const ValueKey('pin-type-cafe')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Zapisz'));
    await tester.tap(find.text('Zapisz'));
    await tester.pumpAndSettle();

    expect(saved?.kind, const PinKind(PlaceType.cafe));
    expect(find.text('Kawiarnia · Gastronomia'), findsOneWidget);
  });

  testWidgets('w edycji pokazuje zapisany kolor i przywraca domyślny', (
    tester,
  ) async {
    PinDetailsInput? saved;
    await pumpSheet(
      tester,
      pin: pin(kind: const PinKind(PlaceType.lake), color: PinColor.coral),
      onSave: (details) async {
        saved = details;
        return true;
      },
    );

    await tester.tap(find.text('Edytuj'));
    await tester.pumpAndSettle();
    expect(find.text('Koralowy'), findsOneWidget);

    await tester.tap(find.text('Domyślny'));
    await tester.pump();
    await tester.ensureVisible(find.text('Zapisz'));
    await tester.tap(find.text('Zapisz'));
    await tester.pumpAndSettle();

    expect(saved?.kind, const PinKind(PlaceType.lake));
    expect(saved?.color, isNull);
  });

  testWidgets('w edycji zmienia kolor', (tester) async {
    PinDetailsInput? saved;
    await pumpSheet(
      tester,
      pin: pin(),
      onSave: (details) async {
        saved = details;
        return true;
      },
    );

    await tester.tap(find.text('Edytuj'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const ValueKey('pin-color-sky')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('pin-color-sky')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Zapisz'));
    await tester.tap(find.text('Zapisz'));
    await tester.pumpAndSettle();

    expect(saved?.color, PinColor.sky);
  });

  testWidgets('w edycji pasek przewija się do zapisanego koloru', (
    tester,
  ) async {
    await pumpSheet(
      tester,
      pin: pin(color: PinColor.black),
      onSave: (_) async => true,
    );

    await tester.tap(find.text('Edytuj'));
    await tester.pumpAndSettle();

    final swatch = tester.getRect(
      find.byKey(const ValueKey('pin-color-black')),
    );
    final bar = tester.getRect(
      find
          .ancestor(
            of: find.byKey(const ValueKey('pin-color-black')),
            matching: find.byType(SingleChildScrollView),
          )
          .first,
    );
    expect(swatch.right, lessThanOrEqualTo(bar.right));
    expect(swatch.left, greaterThanOrEqualTo(bar.left));
  });
}
