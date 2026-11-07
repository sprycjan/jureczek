import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../home/domain/landscape.dart';
import '../domain/splash_manifest.dart';

const _root = 'assets/splash';

/// Podstawia kolory pory dnia pod tokeny z SVG (`tool/splash_art.py`). Kolor spoza
/// palety zostaje bez zmian; test grafik pilnuje, że takich nie ma.
class SplashPaletteMapper extends ColorMapper {
  const SplashPaletteMapper(this.key, this.colors);

  /// Nazwa pory dnia: tylko ona różni mapery, więc wystarcza do klucza pamięci podręcznej.
  final String key;
  final Map<int, Color> colors;

  @override
  Color substitute(
    String? id,
    String elementName,
    String attributeName,
    Color color,
  ) => colors[color.toARGB32()] ?? color;

  @override
  bool operator ==(Object other) =>
      other is SplashPaletteMapper && other.key == key;

  @override
  int get hashCode => key.hashCode;
}

/// Kolory jednej pory z `palettes.json`: token → kolor.
Map<int, Color> parseSplashPalette(String json, String period) {
  final palette = jsonDecode(json) as Map<String, dynamic>;
  int argb(String hex) => 0xFF000000 | int.parse(hex.substring(1), radix: 16);
  return {
    for (final entry in palette.entries)
      argb(entry.key): Color(
        argb((entry.value as Map<String, dynamic>)[period] as String),
      ),
  };
}

class SplashLayerArt {
  const SplashLayerArt(this.spec, this.picture);

  final SplashLayerSpec spec;
  final PictureInfo picture;
}

/// Gotowe obrazy wylosowanej sceny w jednej porze dnia.
class SplashArt {
  SplashArt({
    required this.manifest,
    required this.sky,
    required this.layers,
    required this.camperShadow,
    required this.camperUnder,
    required this.camperBody,
    required this.wheel,
    required this.dust,
    required this.pebble,
    required this.camperNight,
  });

  final SplashManifest manifest;
  final PictureInfo sky;
  final List<SplashLayerArt> layers;
  final PictureInfo camperShadow;
  final PictureInfo camperUnder;
  final PictureInfo camperBody;
  final PictureInfo wheel;
  final PictureInfo dust;
  final PictureInfo pebble;

  /// Świecące okna i reflektor, tylko w nocy.
  final PictureInfo? camperNight;

  void dispose() {
    for (final info in [
      sky,
      camperShadow,
      camperUnder,
      camperBody,
      wheel,
      dust,
      pebble,
      ?camperNight,
      for (final layer in layers) layer.picture,
    ]) {
      info.picture.dispose();
    }
  }
}

Future<SplashManifest> loadSplashManifest([AssetBundle? bundle]) async {
  final text = await (bundle ?? rootBundle).loadString('$_root/manifest.json');
  return SplashManifest.fromJson(jsonDecode(text) as Map<String, dynamic>);
}

/// Wczytuje tylko jedną scenę, więc liczba krajobrazów nie wydłuża startu.
Future<SplashArt> loadSplashArt({
  required SplashManifest manifest,
  required int sceneIndex,
  required Landscape period,
  AssetBundle? bundle,
}) async {
  final assets = bundle ?? rootBundle;
  final colors = parseSplashPalette(
    await assets.loadString('$_root/palettes.json'),
    period.name,
  );
  final mapper = SplashPaletteMapper(period.name, colors);

  Future<PictureInfo> load(String file) => vg.loadPicture(
    // Bundle tylko z testów: rootBundle nie przejdzie do izolatu parsującego SVG.
    SvgAssetLoader('$_root/$file', assetBundle: bundle, colorMapper: mapper),
    null,
  );

  final scene = manifest.scenes[sceneIndex];
  final night = period == Landscape.night;
  final common = await Future.wait([
    load('sky_${period.name}.svg'),
    load('camper_under.svg'),
    load('camper_body.svg'),
    load('camper_wheel.svg'),
    load('dust.svg'),
    load('camper_shadow.svg'),
    load('pebble.svg'),
    if (night) load('camper_night.svg'),
  ]);
  final layers = await Future.wait(scene.layers.map((l) => load(l.file)));
  return SplashArt(
    manifest: manifest,
    sky: common[0],
    camperUnder: common[1],
    camperBody: common[2],
    wheel: common[3],
    dust: common[4],
    camperShadow: common[5],
    pebble: common[6],
    camperNight: night ? common[7] : null,
    layers: [
      for (final (i, spec) in scene.layers.indexed)
        SplashLayerArt(spec, layers[i]),
    ],
  );
}
