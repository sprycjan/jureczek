import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jureczek/features/folders/application/folders_providers.dart';
import 'package:jureczek/features/folders/domain/trip_folder.dart';
import 'package:jureczek/features/home/domain/landscape.dart';
import 'package:jureczek/features/share/application/shared_place_controller.dart';
import 'package:jureczek/features/splash/data/splash_art_loader.dart';
import 'package:jureczek/features/splash/domain/splash_config.dart';
import 'package:jureczek/features/splash/presentation/splash_overlay.dart';

const _config = SplashConfig();

final _overlay = find.byType(AnnotatedRegion<SystemUiOverlayStyle>);

class _FakeShared extends SharedPlaceController {
  @override
  SharedPlaceState build() => const SharedPlaceIdle();

  void start() => state = const SharedPlaceLoading();
}

class _Home extends StatefulWidget {
  const _Home();

  static int created = 0;

  @override
  State<_Home> createState() => _HomeState();
}

class _HomeState extends State<_Home> {
  @override
  void initState() {
    super.initState();
    _Home.created++;
  }

  @override
  Widget build(BuildContext context) => const Text('ekran startowy');
}

void main() {
  late StreamController<List<TripFolder>> folders;
  late ProviderContainer container;

  setUp(() {
    _Home.created = 0;
    folders = StreamController<List<TripFolder>>();
    container = ProviderContainer(
      overrides: [
        foldersProvider.overrideWith((ref) => folders.stream),
        sharedPlaceControllerProvider.overrideWith(_FakeShared.new),
      ],
    );
  });
  tearDown(() async {
    container.dispose();
    await folders.close();
  });

  /// Grafiki domyślnie nigdy nie docierają: w teście liczy się tylko bramka i przenikanie.
  Future<void> pump(
    WidgetTester tester, {
    SplashArtSource? loadArt,
    Completer<void>? header,
    bool disableAnimations = false,
    VoidCallback? onArtSettled,
  }) async {
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MediaQuery(
          data: MediaQueryData(disableAnimations: disableAnimations),
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: SplashOverlay(
              loadArt: loadArt ?? (_) => Completer<SplashArt>().future,
              precacheHeader: (_, _) => header?.future ?? Future<void>.value(),
              onArtSettled: onArtSettled,
              child: const _Home(),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  Future<void> ready(WidgetTester tester) async {
    folders.add(const []);
    await tester.pump();
  }

  Future<void> finishFade(WidgetTester tester) async {
    await tester.pump();
    // Animacja kończy się dopiero po przekroczeniu swojej długości.
    await tester.pump(_config.fadeDuration + const Duration(milliseconds: 20));
    await tester.pump();
  }

  testWidgets('trzyma do minimum, potem znika, a ekran startowy zostaje', (
    tester,
  ) async {
    await pump(tester);
    await ready(tester);
    expect(_overlay, findsOneWidget);

    await tester.pump(
      _config.minimumDuration - const Duration(milliseconds: 1),
    );
    expect(_overlay, findsOneWidget);
    await tester.pump(const Duration(milliseconds: 1));
    await finishFade(tester);

    expect(_overlay, findsNothing);
    expect(find.text('ekran startowy'), findsOneWidget);
    expect(
      _Home.created,
      1,
      reason: 'ekran startowy nie może powstać drugi raz',
    );
  });

  testWidgets('błąd bazy też kończy czekanie', (tester) async {
    await pump(tester);
    folders.addError(StateError('baza'));
    await tester.pump();
    await tester.pump(_config.minimumDuration);
    await finishFade(tester);
    expect(_overlay, findsNothing);
  });

  testWidgets('bez gotowości znika po limicie', (tester) async {
    await pump(tester);
    await tester.pump(_config.readinessLimit - const Duration(milliseconds: 1));
    expect(_overlay, findsOneWidget);
    await tester.pump(const Duration(milliseconds: 1));
    await finishFade(tester);
    expect(_overlay, findsNothing);
  });

  testWidgets('czeka też na obraz nagłówka', (tester) async {
    final header = Completer<void>();
    await pump(tester, header: header);
    await ready(tester);
    await tester.pump(_config.minimumDuration);
    await finishFade(tester);
    expect(_overlay, findsOneWidget);

    header.complete();
    await tester.pump();
    await finishFade(tester);
    expect(_overlay, findsNothing);
  });

  testWidgets('stuknięcie po gotowości kończy od razu', (tester) async {
    await pump(tester);
    await ready(tester);
    await tester.tap(_overlay, warnIfMissed: false);
    await finishFade(tester);
    expect(_overlay, findsNothing);
  });

  testWidgets('stuknięcie przed gotowością jest zapamiętane', (tester) async {
    await pump(tester);
    await tester.tap(_overlay, warnIfMissed: false);
    await finishFade(tester);
    expect(_overlay, findsOneWidget);

    await ready(tester);
    await finishFade(tester);
    expect(_overlay, findsNothing);
  });

  testWidgets('udostępnienie pomija minimum', (tester) async {
    await pump(tester);
    await ready(tester);
    (container.read(sharedPlaceControllerProvider.notifier) as _FakeShared)
        .start();
    await tester.pump();
    await finishFade(tester);
    expect(_overlay, findsNothing);
  });

  testWidgets('nieudane wczytanie grafik pomija minimum i nie blokuje startu', (
    tester,
  ) async {
    await pump(tester, loadArt: (_) async => throw StateError('brak pliku'));
    await ready(tester);
    await finishFade(tester);
    expect(_overlay, findsNothing);
    expect(find.text('ekran startowy'), findsOneWidget);
  });

  testWidgets('scena gotowa przed pierwszą klatką: bez zasłony z gradientu', (
    tester,
  ) async {
    final art = await tester.runAsync(() async {
      return loadSplashArt(
        manifest: await loadSplashManifest(rootBundle),
        sceneIndex: 0,
        period: Landscape.day,
        bundle: rootBundle,
      );
    });
    addTearDown(tester.binding.allowFirstFrame);
    tester.binding
      ..resetFirstFrameSent()
      ..deferFirstFrame();
    var settled = 0;

    await pump(
      tester,
      loadArt: (_) async => art!,
      onArtSettled: () => settled++,
    );

    expect(settled, 1);
    final curtain = tester.widget<FadeTransition>(
      find
          .ancestor(
            of: find.byType(DecoratedBox),
            matching: find.byType(FadeTransition),
          )
          .first,
    );
    expect(curtain.opacity.value, 0);
    expect(find.byType(CustomPaint), findsWidgets);
  });

  testWidgets('scena spóźniona na pierwszą klatkę: gradient przenika w scenę', (
    tester,
  ) async {
    final art = await tester.runAsync(() async {
      return loadSplashArt(
        manifest: await loadSplashManifest(rootBundle),
        sceneIndex: 0,
        period: Landscape.day,
        bundle: rootBundle,
      );
    });
    final late_ = Completer<SplashArt>();
    await pump(tester, loadArt: (_) => late_.future);
    FadeTransition curtain() => tester.widget<FadeTransition>(
      find
          .ancestor(
            of: find.byType(DecoratedBox),
            matching: find.byType(FadeTransition),
          )
          .first,
    );
    expect(curtain().opacity.value, 1);

    late_.complete(art);
    // Pierwszy pump dostarcza scenę, drugi to pierwszy takt przenikania.
    await tester.pump();
    await tester.pump();
    expect(curtain().opacity.value, 1);
    await tester.pump(_config.launchFade ~/ 2);
    expect(curtain().opacity.value, closeTo(0.5, 0.05));
    await tester.pump(_config.launchFade);
    expect(curtain().opacity.value, 0);
  });

  testWidgets('nieudane wczytanie też zwalnia pierwszą klatkę', (tester) async {
    var settled = 0;
    await pump(
      tester,
      loadArt: (_) async => throw StateError('brak pliku'),
      onArtSettled: () => settled++,
    );
    expect(settled, 1);
  });

  testWidgets('przebudowa nie zaczyna minimum od nowa', (tester) async {
    await pump(tester);
    await ready(tester);
    await tester.pump(const Duration(seconds: 3));
    // Obrót ekranu: inne wymiary, ten sam stan.
    tester.view.physicalSize = const Size(2340, 1080);
    addTearDown(tester.view.reset);
    await pump(tester);
    await tester.pump(const Duration(milliseconds: 500));
    await finishFade(tester);
    expect(_overlay, findsNothing);
    expect(_Home.created, 1);
  });
}
