import 'dart:math' as math;

import 'package:flutter/rendering.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../application/splash_motion.dart';
import '../data/splash_art_loader.dart';
import '../domain/splash_config.dart';

/// Maluje całą scenę: niebo, warstwy, kampera i pierwszy plan.
class SplashScenePainter extends CustomPainter {
  SplashScenePainter({
    required this.art,
    required this.frame,
    this.config = const SplashConfig(),
    this.maxVisibleWidth = 1400,
  }) : super(repaint: frame);

  final SplashArt art;
  final SplashFrame frame;
  final SplashConfig config;

  /// Szerokość sceny widoczna na szerokim ekranie; wyżej obcinane jest niebo.
  final double maxVisibleWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final manifest = art.manifest;
    final scale = math.max(
      size.height / manifest.sceneHeight,
      size.width / maxVisibleWidth,
    );
    final viewWidth = size.width / scale;

    canvas.save();
    canvas.clipRect(Offset.zero & size);
    // Scena kotwiczona u dołu ekranu.
    canvas.translate(0, size.height - manifest.sceneHeight * scale);
    canvas.scale(scale);

    canvas.save();
    canvas.translate((viewWidth - manifest.skyWidth) / 2, 0);
    canvas.drawPicture(art.sky.picture);
    canvas.restore();

    final last = art.layers.length - 1;
    for (var i = 0; i < last; i++) {
      _paintLayer(canvas, art.layers[i], viewWidth);
    }
    _paintCamper(canvas, viewWidth);
    _paintLayer(canvas, art.layers[last], viewWidth);
    canvas.restore();
  }

  void _paintLayer(Canvas canvas, SplashLayerArt layer, double viewWidth) {
    final spec = layer.spec;
    final position = spec.start - viewWidth / 2 + spec.speed * frame.scroll;
    var tile = -(position % spec.period);
    while (tile < viewWidth) {
      canvas.save();
      canvas.translate(tile, 0);
      canvas.drawPicture(layer.picture.picture);
      canvas.restore();
      tile += spec.period;
    }
  }

  void _paintCamper(Canvas canvas, double viewWidth) {
    final manifest = art.manifest;
    final camper = manifest.camper;
    final k = manifest.camperScale;
    // Kamper zawsze zaczyna i kończy poza kadrem, także po obrocie ekranu w trakcie jazdy.
    final anchor = viewWidth * config.camperAnchor;
    final hidden = -(anchor + (camper.box.right - camper.centerX) * k);
    final gone =
        viewWidth -
        anchor +
        (camper.centerX - camper.box.left + camper.nightPad) * k;
    final rest = hidden * (1 - frame.enter);
    final center = anchor + rest + (gone - rest) * frame.exit;
    final left = center - camper.centerX * k;
    final top = manifest.ground - camper.ground * k;

    void piece(PictureInfo? info, [double pad = 0]) {
      if (info == null) return;
      canvas.save();
      canvas.translate(
        left + (camper.box.left - pad) * k,
        top + camper.box.top * k,
      );
      canvas.scale(k);
      canvas.drawPicture(info.picture);
      canvas.restore();
    }

    final rear = camper.wheels.first;
    final front = camper.wheels.last;
    final restFrontX = anchor + (front.dx - camper.centerX) * k;
    for (final pebble in frame.pebbles) {
      if (pebble.visible) {
        _paintPebble(
          canvas,
          restFrontX + pebble.ahead,
          pebble.scale,
          viewWidth,
        );
      }
    }
    piece(art.camperShadow);
    _paintDust(canvas, left + rear.dx * k, config.dustPuffs, 1, 0);
    _paintDust(
      canvas,
      left + front.dx * k,
      config.dustFrontPuffs,
      config.dustFrontSize,
      0.37,
    );

    // Nadwozie na zawieszeniu: obrót wokół środka między osiami, koła zostają na drodze.
    void body(void Function() paint) {
      canvas.save();
      canvas.translate(left + (rear.dx + front.dx) / 2 * k, top + rear.dy * k);
      canvas.translate(0, -frame.bodyLift);
      canvas.rotate(-frame.bodyPitch);
      canvas.translate(
        -(left + (rear.dx + front.dx) / 2 * k),
        -(top + rear.dy * k),
      );
      paint();
      canvas.restore();
    }

    body(() => piece(art.camperUnder));
    for (var i = 0; i < camper.wheels.length; i++) {
      final wheel = camper.wheels[i];
      final lift = i == 0 ? frame.rearLift : frame.frontLift;
      canvas.save();
      canvas.translate(left + wheel.dx * k, top + wheel.dy * k - lift);
      canvas.rotate(frame.wheelAngle);
      canvas.scale(k);
      canvas.translate(-art.wheel.size.width / 2, -art.wheel.size.height / 2);
      canvas.drawPicture(art.wheel.picture);
      canvas.restore();
    }
    body(() {
      piece(art.camperBody);
      piece(art.camperNight, camper.nightPad);
    });
  }

  void _paintPebble(Canvas canvas, double x, double scale, double viewWidth) {
    final picture = art.pebble;
    final width = picture.size.width * scale;
    if (x < -width || x > viewWidth + width) return;
    canvas.save();
    // Podstawa kamyka lekko poniżej linii styku kół: leży na drodze, a nie na jej krawędzi.
    canvas.translate(
      x - width / 2,
      art.manifest.ground + 2 - picture.size.height * scale,
    );
    canvas.scale(scale);
    canvas.drawPicture(picture.picture);
    canvas.restore();
  }

  /// Obłoki bez przezroczystości: rosną i maleją do zera, bo każdy `saveLayer` w klatce
  /// kosztuje. Pozycję wyznacza sam czas, więc nie ma listy cząstek do utrzymywania.
  void _paintDust(
    Canvas canvas,
    double wheelX,
    int count,
    double size,
    double phase,
  ) {
    if (frame.dustTime < 0) return;
    final picture = art.dust;
    final ground = art.manifest.ground;
    final k = art.manifest.camperScale;
    final life = config.dustLife.inMicroseconds / 1e6;
    for (var i = 0; i < count; i++) {
      final age = (frame.dustTime / life + phase + i / count) % 1;
      // Złoty podział rozrzuca obłoki bez generatora losowego.
      final variation = (i * 0.618 + phase) % 1;
      final scale =
          config.dustSize *
          size *
          k *
          (0.55 + 0.45 * variation) *
          math.sin(math.pi * age);
      if (scale <= 0) continue;
      canvas.save();
      canvas.translate(
        wheelX - config.dustDrift * size * age * (0.8 + 0.4 * variation),
        ground - config.dustRise * size * age,
      );
      canvas.scale(scale);
      canvas.translate(-picture.size.width / 2, -picture.size.height);
      canvas.drawPicture(picture.picture);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(SplashScenePainter oldDelegate) =>
      oldDelegate.art != art ||
      oldDelegate.frame != frame ||
      oldDelegate.config != config;
}
