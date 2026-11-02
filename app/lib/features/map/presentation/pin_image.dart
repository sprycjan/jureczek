import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../domain/pin_category.dart';
import '../domain/pin_color.dart';

/// Warstwy pinezki do barwienia (v14), z `tool/render_pins.py`:
/// korpus na biało (mnożony przez kolor), nakładka bez zmian (biały symbol,
/// obwódka) i – tylko w pinezce domyślnej – kolorowa kropka nad tarczą.
enum PinLayer {
  body(tinted: true),
  overlay(tinted: false),
  accent(tinted: true);

  const PinLayer({required this.tinted});

  final bool tinted;

  static List<PinLayer> of(PinCategory category) => [
    body,
    overlay,
    if (category == PinCategory.standard) accent,
  ];

  String asset(PinCategory category, {required bool selected}) =>
      'assets/markers/tint/${category.key}_${selected ? 'selected' : 'default'}_$name.png';
}

/// PNG 3x pinezki: bez [color] gotowy obrazek kategorii, z kolorem złożony
/// z warstw – ten sam rozmiar i czubek na dolnej krawędzi.
Future<Uint8List> renderPinPng(
  AssetBundle bundle,
  PinCategory category, {
  bool selected = false,
  PinColor? color,
}) async {
  if (color == null) {
    final data = await bundle.load(category.asset(selected: selected));
    return data.buffer.asUint8List();
  }
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  var width = 0;
  var height = 0;
  for (final layer in PinLayer.of(category)) {
    final data = await bundle.load(layer.asset(category, selected: selected));
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

/// Pinezka danego typu i koloru w interfejsie (formularz, arkusz).
class PinImage extends StatelessWidget {
  const PinImage(this.category, {super.key, this.color, this.height = 32});

  final PinCategory category;
  final PinColor? color;
  final double height;

  @override
  Widget build(BuildContext context) {
    final color = this.color;
    if (color == null) {
      return Image.asset(
        category.asset(),
        height: height,
        fit: BoxFit.contain,
        excludeFromSemantics: true,
      );
    }
    return Stack(
      alignment: Alignment.center,
      children: [
        for (final layer in PinLayer.of(category))
          Image.asset(
            layer.asset(category, selected: false),
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
