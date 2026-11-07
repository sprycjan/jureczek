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

    _paintDust(canvas, left + camper.wheels.first.dx * k, manifest.ground);
    piece(art.camperUnder);
    for (final wheel in camper.wheels) {
      canvas.save();
      canvas.translate(left + wheel.dx * k, top + wheel.dy * k);
      canvas.rotate(frame.wheelAngle);
      canvas.scale(k);
      canvas.translate(-art.wheel.size.width / 2, -art.wheel.size.height / 2);
      canvas.drawPicture(art.wheel.picture);
      canvas.restore();
    }
    piece(art.camperBody);
    piece(art.camperNight, camper.nightPad);
  }

  /// Obłoki bez przezroczystości: rosną i maleją do zera, bo każdy `saveLayer` w klatce
  /// kosztuje. Pozycję wyznacza sam czas, więc nie ma listy cząstek do utrzymywania.
  void _paintDust(Canvas canvas, double wheelX, double ground) {
    if (frame.dustTime < 0) return;
    final picture = art.dust;
    final k = art.manifest.camperScale;
    final life = config.dustLife.inMicroseconds / 1e6;
    final count = config.dustPuffs;
    for (var i = 0; i < count; i++) {
      final age = (frame.dustTime / life + i / count) % 1;
      // Złoty podział rozrzuca obłoki bez generatora losowego.
      final variation = (i * 0.618) % 1;
      final scale =
          config.dustSize *
          k *
          (0.55 + 0.45 * variation) *
          math.sin(math.pi * age);
      if (scale <= 0) continue;
      canvas.save();
      canvas.translate(
        wheelX - config.dustDrift * age * (0.8 + 0.4 * variation),
        ground - config.dustRise * age,
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
