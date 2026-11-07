import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import '../features/home/domain/landscape.dart';
import '../features/splash/application/splash_motion.dart';
import '../features/splash/data/splash_art_loader.dart';
import '../features/splash/domain/splash_config.dart';
import '../features/splash/presentation/splash_scene_painter.dart';

/// Podgląd grafik ekranu powitalnego (v24) – osobny punkt wejścia, aplikacja go nie używa:
/// `flutter run -d <telefon> -t lib/dev/splash_main.dart`
/// Stuknięcie: następna pora dnia; przytrzymanie: następna scena. Scena jedzie w pętli,
/// a w logu są czasy klatek: pomiar wydajności wymaga trybu `--profile`.
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  runApp(const MaterialApp(home: _Preview()));
}

class _Preview extends StatefulWidget {
  const _Preview();

  @override
  State<_Preview> createState() => _PreviewState();
}

class _PreviewState extends State<_Preview>
    with SingleTickerProviderStateMixin {
  final _frame = SplashFrame();
  late final _motion = SplashMotion(const SplashConfig(), _frame);
  late final Ticker _ticker;
  Duration _last = Duration.zero;
  final _builds = <double>[];
  final _rasters = <double>[];
  SplashArt? _art;
  int _period = 2;
  int _scene = 0;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker((elapsed) {
      final step = (elapsed - _last).inMicroseconds / 1e6;
      _last = elapsed;
      _motion.advance(math.min(step, 1 / 15));
      _frame.update();
    });
    SchedulerBinding.instance.addTimingsCallback(_onTimings);
    _load();
  }

  void _onTimings(List<FrameTiming> timings) {
    for (final t in timings) {
      _builds.add(t.buildDuration.inMicroseconds / 1000);
      _rasters.add(t.rasterDuration.inMicroseconds / 1000);
    }
    if (_rasters.length < 180) return;
    String stats(List<double> v) {
      v.sort();
      double at(double q) => v[(v.length * q).floor()];
      return 'p50 ${at(.5).toStringAsFixed(1)} p90 ${at(.9).toStringAsFixed(1)} '
          'p99 ${at(.99).toStringAsFixed(1)} ms';
    }

    final late = _rasters.where((r) => r > 16.7).length;
    debugPrint(
      'Klatki ${_rasters.length}, ponad 16,7 ms: $late; '
      'build ${stats(_builds)}; raster ${stats(_rasters)}',
    );
    _builds.clear();
    _rasters.clear();
  }

  @override
  void dispose() {
    _ticker.dispose();
    _frame.dispose();
    SchedulerBinding.instance.removeTimingsCallback(_onTimings);
    super.dispose();
  }

  Future<void> _load() async {
    final manifest = await loadSplashManifest();
    final stopwatch = Stopwatch()..start();
    final art = await loadSplashArt(
      manifest: manifest,
      sceneIndex: _scene % manifest.scenes.length,
      period: Landscape.values[_period % Landscape.values.length],
    );
    debugPrint('Scena wczytana w ${stopwatch.elapsedMilliseconds} ms');
    if (!mounted) return;
    setState(() => _art = art);
    _motion.wheelRate =
        art.layers[art.layers.length - 2].spec.speed /
        (manifest.camper.radius * manifest.camperScale);
    if (!_ticker.isActive) {
      _motion.begin();
      _ticker.start();
    }
  }

  @override
  Widget build(BuildContext context) {
    final art = _art;
    return GestureDetector(
      onTap: () {
        _period++;
        _load();
      },
      onLongPress: () {
        _scene++;
        _load();
      },
      child: art == null
          ? const ColoredBox(color: Colors.black)
          : CustomPaint(
              size: Size.infinite,
              painter: SplashScenePainter(art: art, frame: _frame),
            ),
    );
  }
}
