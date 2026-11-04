import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_theme.dart';
import '../../places/presentation/place_icons.dart';
import '../domain/pin_color.dart';
import '../domain/pin_kind.dart';

/// Gęstość pikseli, w jakiej powstają PNG pinezek (gotowe i składane).
const pinImageScale = 3.0;

/// Zielona „Pinezka” bez typu (v9): PNG 3x przycięty tak, że czubek leży na
/// dolnej krawędzi (źródło i generator: `assets/markers/src/`, `tool/render_pins.py`).
const standardPinAsset = 'assets/markers/standard_default.png';
const standardSelectedPinAsset = 'assets/markers/standard_selected.png';

/// Warstwy zielonej pinezki do barwienia (v14), z `tool/render_pins.py`:
/// korpus na biało (mnożony przez kolor), nakładka bez zmian (biały symbol,
/// obwódka, tarcza) i kolorowa kropka nad tarczą.
enum PinLayer {
  body(tinted: true),
  overlay(tinted: false),
  accent(tinted: true);

  const PinLayer({required this.tinted});

  final bool tinted;

  String asset({required bool selected}) =>
      'assets/markers/tint/standard_${selected ? 'selected' : 'default'}_$name.png';
}

/// PNG 3x pinezki danego typu (v16) – dla Mapbox i animacji spadania.
/// Zielona z gotowego PNG albo z warstw w [color]; typ miejsca z SVG (z cieniem).
/// Czubek zawsze na dolnej krawędzi (kotwica `BOTTOM`). Odwiedzona (v21) ma
/// w prawym górnym rogu znaczek kciuka; rozmiar obrazka się nie zmienia.
Future<Uint8List> renderPinPng(
  AssetBundle bundle,
  PinKind kind, {
  bool selected = false,
  PinColor? color,
  bool visited = false,
}) async {
  final png = await _renderBasePng(
    bundle,
    kind,
    selected: selected,
    color: color,
  );
  if (!visited) return png;
  return _addVisitedBadge(png, visitedBadge(kind, selected: selected));
}

/// Znaczek odwiedzonej pinezki w dp obrazka: środek i promień z obwódką.
/// Leży na prawym górnym skraju główki i mieści się w ramce PNG (typy miejsc:
/// [PlacePinGeometry]; zielona: 54 × 56 i 63 × 65 dp, główka od y = 2).
({Offset center, double radius}) visitedBadge(
  PinKind kind, {
  required bool selected,
}) => switch ((kind.type != null, selected)) {
  (true, false) => (center: const Offset(41, 7), radius: 7),
  (true, true) => (center: const Offset(46, 8), radius: 8),
  (false, false) => (center: const Offset(44, 7), radius: 7),
  (false, true) => (center: const Offset(51, 8), radius: 8),
};

/// Obwódka znaczka i wielkość kciuka względem promienia.
const _badgeBorderPerRadius = 0.14;
const _badgeIconPerRadius = 1.2;

Future<Uint8List> _addVisitedBadge(
  Uint8List png,
  ({Offset center, double radius}) badge,
) async {
  final codec = await ui.instantiateImageCodec(png);
  final base = (await codec.getNextFrame()).image;
  codec.dispose();
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder)..drawImage(base, Offset.zero, Paint());
  final width = base.width;
  final height = base.height;
  base.dispose();

  final center = badge.center * pinImageScale;
  final radius = badge.radius * pinImageScale;
  final border = radius * _badgeBorderPerRadius;
  canvas
    ..drawCircle(center, radius, Paint()..color = Colors.white)
    ..drawCircle(
      center,
      radius - border,
      Paint()..color = Nocturnal.surfaceContainerLowest,
    );
  final icon = TextPainter(
    textDirection: TextDirection.ltr,
    text: TextSpan(
      text: String.fromCharCode(Icons.thumb_up.codePoint),
      style: TextStyle(
        color: Colors.white,
        fontFamily: Icons.thumb_up.fontFamily,
        fontSize: radius * _badgeIconPerRadius,
        height: 1,
      ),
    ),
  )..layout();
  icon.paint(canvas, center - Offset(icon.width / 2, icon.height / 2));
  icon.dispose();

  final picture = recorder.endRecording();
  final image = await picture.toImage(width, height);
  picture.dispose();
  final result = await image.toByteData(format: ui.ImageByteFormat.png);
  image.dispose();
  return result!.buffer.asUint8List();
}

Future<Uint8List> _renderBasePng(
  AssetBundle bundle,
  PinKind kind, {
  required bool selected,
  PinColor? color,
}) {
  final type = kind.type;
  if (type != null) {
    return renderPlacePinPng(
      type,
      selected: selected,
      pixelRatio: pinImageScale,
      color: color?.color,
      bundle: bundle,
    );
  }
  return _renderStandardPng(bundle, selected: selected, color: color);
}

Future<Uint8List> _renderStandardPng(
  AssetBundle bundle, {
  required bool selected,
  PinColor? color,
}) async {
  if (color == null) {
    final data = await bundle.load(
      selected ? standardSelectedPinAsset : standardPinAsset,
    );
    return data.buffer.asUint8List();
  }
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  var width = 0;
  var height = 0;
  for (final layer in PinLayer.values) {
    final data = await bundle.load(layer.asset(selected: selected));
    final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
    final image = (await codec.getNextFrame()).image;
    width = image.width;
    height = image.height;
    canvas.drawImage(
      image,
      Offset.zero,
      Paint()
        ..colorFilter = layer.tinted
            ? ColorFilter.mode(color.color, BlendMode.modulate)
            : null,
    );
    image.dispose();
  }
  final picture = recorder.endRecording();
  final image = await picture.toImage(width, height);
  picture.dispose();
  final png = await image.toByteData(format: ui.ImageByteFormat.png);
  image.dispose();
  return png!.buffer.asUint8List();
}

/// Proporcje PNG zielonej pinezki (54 × 56 dp, korpus 36 dp) – `render_pins.py`.
const _standardFrameAspect = 54 / 56;
const _standardBodyPerHeight = 36 / 56;

/// Pinezka danego typu i koloru w interfejsie (formularz, arkusz) o wysokości [height].
class PinImage extends StatelessWidget {
  const PinImage(this.kind, {super.key, this.color, this.height = 32});

  final PinKind kind;
  final PinColor? color;
  final double height;

  @override
  Widget build(BuildContext context) {
    final type = kind.type;
    final color = this.color;
    if (type != null) {
      // Korpus tej samej szerokości co zielona przy tej samej wysokości:
      // PNG zielonej ma 36 dp korpusu w ramce 56 dp (do czubka).
      return SizedBox(
        height: height,
        width: height * _standardFrameAspect,
        child: Align(
          alignment: Alignment.bottomCenter,
          child: PlacePin(
            type,
            width: height * _standardBodyPerHeight,
            color: color?.color,
          ),
        ),
      );
    }
    if (color == null) {
      return Image.asset(
        standardPinAsset,
        height: height,
        fit: BoxFit.contain,
        excludeFromSemantics: true,
      );
    }
    return Stack(
      alignment: Alignment.center,
      children: [
        for (final layer in PinLayer.values)
          Image.asset(
            layer.asset(selected: false),
            height: height,
            fit: BoxFit.contain,
            excludeFromSemantics: true,
            color: layer.tinted ? color.color : null,
            colorBlendMode: layer.tinted ? BlendMode.modulate : null,
          ),
      ],
    );
  }
}
