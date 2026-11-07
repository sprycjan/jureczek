import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../folders/application/folders_providers.dart';
import '../../home/domain/landscape.dart';
import '../../share/application/shared_place_controller.dart';
import '../application/splash_motion.dart';
import '../data/splash_art_loader.dart';
import '../data/splash_scene_turn.dart';
import '../domain/splash_config.dart';
import '../domain/splash_gate.dart';
import 'splash_scene_painter.dart';

/// Wczytuje scenę do pokazania. Podmieniane w testach, które nie parsują SVG.
typedef SplashArtSource = Future<SplashArt> Function(Landscape period);

/// Wczytuje obraz nagłówka ekranu startowego. Podmieniane w testach, bo dekodowanie
/// obrazu nie działa w czasie udawanym.
typedef SplashImagePrecache =
    Future<void> Function(BuildContext context, Landscape period);

Future<void> _precacheHeader(BuildContext context, Landscape period) =>
    // `precacheImage` nie rzuca: brak obrazu nie może zatrzymać startu.
    precacheImage(AssetImage(period.asset), context);

/// Następna scena z manifestu, po kolei; wczytywana jest tylko ona.
Future<SplashArt> loadNextSplashArt(Landscape period) async {
  final manifest = await loadSplashManifest();
  return loadSplashArt(
    manifest: manifest,
    sceneIndex: await nextSplashScene(manifest.scenes.length),
    period: period,
  );
}

/// Ekran powitalny nad całą aplikacją. Ekran startowy jest już zbudowany pod spodem,
/// a po przenikaniu nakładka znika z drzewa i zwalnia grafiki.
class SplashOverlay extends ConsumerStatefulWidget {
  const SplashOverlay({
    super.key,
    required this.child,
    this.config = const SplashConfig(),
    this.loadArt = loadNextSplashArt,
    this.precacheHeader = _precacheHeader,
    this.onArtSettled,
  });

  final Widget child;
  final SplashConfig config;
  final SplashArtSource loadArt;
  final SplashImagePrecache precacheHeader;

  /// Scena jest gotowa do rysowania albo jej nie będzie: można pokazać pierwszą klatkę.
  final VoidCallback? onArtSettled;

  @override
  ConsumerState<SplashOverlay> createState() => _SplashOverlayState();
}

class _SplashOverlayState extends ConsumerState<SplashOverlay>
    with TickerProviderStateMixin {
  /// Po wyjściu ze snu krok jest przycinany: kamper nie przeskakuje całej drogi.
  static const _maxStep = 1 / 15;

  /// Domyślny pasek stanu Fluttera na Androidzie: wraca, gdy nakładka znika.
  static const _appStatusBar = SystemUiOverlayStyle(
    statusBarColor: Color(0x40000000),
    statusBarIconBrightness: Brightness.light,
    statusBarBrightness: Brightness.dark,
  );
  static const _splashStatusBar = SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    statusBarBrightness: Brightness.dark,
  );

  SplashConfig get _config => widget.config;

  late final SplashGate _gate = SplashGate(
    minimum: _config.minimumDuration,
    limit: _config.readinessLimit,
    onExit: _leave,
  );
  final _frame = SplashFrame();
  late final SplashMotion _motion = SplashMotion(_config, _frame);
  late final Ticker _ticker;
  late final AnimationController _launch = AnimationController(
    vsync: this,
    duration: _config.launchFade,
    value: 1,
  );
  late final AnimationController _fade = AnimationController(
    vsync: this,
    duration: _config.fadeDuration,
    value: 1,
  )..addStatusListener(_onFadeStatus);

  SplashArt? _art;
  Duration _lastTick = Duration.zero;
  bool _foldersReady = false;
  bool _imageReady = false;
  bool _imageRequested = false;
  bool _leaving = false;
  bool _fadeStarted = false;
  bool _done = false;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_tick);
    _gate.start();
    ref.listenManual(foldersProvider, (_, next) {
      if (next.hasValue || next.hasError) {
        _foldersReady = true;
        _checkReady();
      }
    }, fireImmediately: true);
    ref.listenManual(sharedPlaceControllerProvider, (_, next) {
      if (next is! SharedPlaceIdle) _gate.skipMinimum();
    }, fireImmediately: true);
    _load();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_imageRequested) return;
    _imageRequested = true;
    widget.precacheHeader(context, Landscape.at(DateTime.now())).whenComplete(
      () {
        _imageReady = true;
        _checkReady();
      },
    );
  }

  void _checkReady() {
    if (_foldersReady && _imageReady) _gate.markReady();
  }

  Future<void> _load() async {
    try {
      final art = await widget.loadArt(Landscape.at(DateTime.now()));
      if (!mounted || _done) {
        art.dispose();
        return;
      }
      setState(() => _art = art);
      if (_leaving) return;
      // Scena zdążyła na pierwszą klatkę: gradientu nigdy nie było widać, więc nie ma
      // czego przenikać. Bez tego różowa zasłona zostawała jeszcze 0,4 s.
      if (RendererBinding.instance.sendFramesToEngine) {
        _launch.reverse();
      } else {
        _launch.value = 0;
      }
      if (!_still) {
        _motion
          ..attach(art)
          ..begin();
        _frame.update();
        _ticker.start();
      }
    } catch (e) {
      // Grafika jest ozdobą: bez niej zostaje gradient, a aplikacja startuje normalnie.
      debugPrint('Ekran powitalny bez grafiki: ${e.runtimeType}');
      if (mounted) _gate.skipMinimum();
    } finally {
      widget.onArtSettled?.call();
    }
  }

  /// „Usuń animacje” w systemie: nieruchoma scena, a na koniec samo przenikanie.
  bool get _still => MediaQuery.disableAnimationsOf(context);

  void _tick(Duration elapsed) {
    final step = (elapsed - _lastTick).inMicroseconds / 1e6;
    _lastTick = elapsed;
    _motion.advance(math.min(step, _maxStep));
    _frame.update();
    if (_leaving &&
        !_fadeStarted &&
        _motion.leaveTime >= _config.fadeDelay.inMicroseconds / 1e6) {
      _startFade();
    }
  }

  void _leave() {
    if (!mounted) return;
    _leaving = true;
    if (_ticker.isActive) {
      _motion.leave();
    } else {
      _startFade();
    }
  }

  void _startFade() {
    _fadeStarted = true;
    _fade.reverse();
  }

  void _onFadeStatus(AnimationStatus status) {
    if (status != AnimationStatus.dismissed || _done) return;
    _ticker.stop();
    setState(() => _done = true);
    SystemChrome.setSystemUIOverlayStyle(_appStatusBar);
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _art?.dispose();
      _art = null;
    });
  }

  @override
  void dispose() {
    _gate.dispose();
    _ticker.dispose();
    _launch.dispose();
    _fade.dispose();
    _frame.dispose();
    _art?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final art = _art;
    return Stack(
      fit: StackFit.expand,
      alignment: Alignment.topLeft,
      children: [
        // Zawsze pierwsze dziecko: ekran startowy nie jest budowany od nowa po zniknięciu nakładki.
        widget.child,
        if (!_done)
          AnnotatedRegion<SystemUiOverlayStyle>(
            value: _splashStatusBar,
            child: RepaintBoundary(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _gate.skipMinimum,
                child: ExcludeSemantics(
                  child: FadeTransition(
                    opacity: _fade,
                    child: Stack(
                      fit: StackFit.expand,
                      alignment: Alignment.topLeft,
                      children: [
                        if (art != null)
                          CustomPaint(
                            painter: SplashScenePainter(
                              art: art,
                              frame: _frame,
                              config: _config,
                            ),
                          ),
                        FadeTransition(
                          opacity: _launch,
                          child: const DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: SplashConfig.launchSky,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
