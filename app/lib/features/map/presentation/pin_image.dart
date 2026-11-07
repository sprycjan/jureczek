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

/// Znaczek przy pinezce; kolejność wartości to kolejność w kolumnie, od góry.
enum PinMark {
  star(Icons.star, pinStarColor),
  visited(Icons.thumb_up, Colors.white);

  const PinMark(this.icon, this.color);

  final IconData icon;
  final Color color;
}

/// Kolor gwiazdki (v22): znaczek na mapie i wypełniona ikonka w arkuszach.
const pinStarColor = Color(0xFFFFC107);

/// PNG 3x pinezki danego typu (v16) – dla Mapbox i animacji spadania.
/// Zielona z gotowego PNG albo z warstw w [color]; typ miejsca z SVG (z cieniem).
/// Czubek zawsze na dolnej krawędzi (kotwica `BOTTOM`). Gwiazdka (v22) i kciuk
/// odwiedzenia (v21) stoją w kolumnie przy główce – patrz [pinBadgeFramePadding].
Future<Uint8List> renderPinPng(
  AssetBundle bundle,
  PinKind kind, {
  bool selected = false,
  PinColor? color,
  bool visited = false,
  bool starred = false,
}) async {
  final png = await _renderBasePng(
    bundle,
    kind,
    selected: selected,
    color: color,
  );
  final marks = [if (starred) PinMark.star, if (visited) PinMark.visited];
  if (marks.isEmpty) return png;
  return _addBadges(
    png,
    marks,
    pinBadges(kind, selected: selected, count: marks.length),
    framePadding: pinBadgeFramePadding(kind, selected: selected),
  );
}

/// O tyle dp z każdej strony rośnie ramka obrazka ze znaczkami: zaznaczona pinezka
/// typu ma symbol tak blisko skraju, że kolumna musi stać o 1 dp dalej, niż pozwala
/// ramka. Poszerzenie jest symetryczne, bo kotwica `BOTTOM` to środek dolnej krawędzi.
double pinBadgeFramePadding(PinKind kind, {required bool selected}) =>
    kind.type != null && selected ? 1 : 0;

/// Kolumna znaczków w dp obrazka (z [pinBadgeFramePadding]): środki i promienie
/// z obwódką, od góry. Styka się z prawym skrajem główki i nie zasłania symbolu
/// (typy miejsc: [PlacePinGeometry]; zielona: 54 × 56 i 63 × 65 dp).
List<({Offset center, double radius})> pinBadges(
  PinKind kind, {
  required bool selected,
  required int count,
}) {
  final (x, radius) = switch ((kind.type != null, selected)) {
    (true, false) => (41.0, 7.0),
    (true, true) => (48.0, 8.0),
    (false, false) => (44.0, 7.0),
    (false, true) => (51.0, 8.0),
  };
  return [
    for (var i = 0; i < count; i++)
      (
        center: Offset(x, radius + i * (2 * radius + _badgeGap)),
        radius: radius,
      ),
  ];
}

/// Odstęp między znaczkami w kolumnie, w dp.
const _badgeGap = 1.0;

/// Obwódka znaczka i wielkość symbolu względem promienia.
const _badgeBorderPerRadius = 0.14;
const _badgeIconPerRadius = 1.2;

Future<Uint8List> _addBadges(
  Uint8List png,
  List<PinMark> marks,
  List<({Offset center, double radius})> badges, {
  required double framePadding,
}) async {
  final codec = await ui.instantiateImageCodec(png);
  final base = (await codec.getNextFrame()).image;
  codec.dispose();
  final recorder = ui.PictureRecorder();
  final padding = (framePadding * pinImageScale).round();
  final canvas = Canvas(recorder)
    ..drawImage(base, Offset(padding.toDouble(), 0), Paint());
  final width = base.width + 2 * padding;
  final height = base.height;
  base.dispose();

  for (final (index, mark) in marks.indexed) {
    _paintBadge(canvas, mark, badges[index]);
  }

  final picture = recorder.endRecording();
  final image = await picture.toImage(width, height);
  picture.dispose();
  final result = await image.toByteData(format: ui.ImageByteFormat.png);
  image.dispose();
  return result!.buffer.asUint8List();
}

void _paintBadge(
  Canvas canvas,
  PinMark mark,
  ({Offset center, double radius}) badge,
) {
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
      text: String.fromCharCode(mark.icon.codePoint),
      style: TextStyle(
        color: mark.color,
        fontFamily: mark.icon.fontFamily,
        fontSize: radius * _badgeIconPerRadius,
        height: 1,
      ),
    ),
  )..layout();
  icon.paint(canvas, center - Offset(icon.width / 2, icon.height / 2));
  icon.dispose();
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
