import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
/// Czubek zawsze na dolnej krawędzi (kotwica `BOTTOM`).
Future<Uint8List> renderPinPng(
  AssetBundle bundle,
  PinKind kind, {
  bool selected = false,
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
