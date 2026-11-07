import 'dart:ui';

/// Warstwa paralaksy: kafel o szerokości [period] przesuwany z prędkością [speed]
/// jednostek sceny na sekundę; [start] to punkt warstwy na środku pierwszego kadru.
class SplashLayerSpec {
  const SplashLayerSpec({
    required this.file,
    required this.period,
    required this.speed,
    required this.start,
  });

  factory SplashLayerSpec.fromJson(Map<String, dynamic> json) =>
      SplashLayerSpec(
        file: json['file'] as String,
        period: (json['period'] as num).toDouble(),
        speed: (json['speed'] as num).toDouble(),
        start: (json['start'] as num).toDouble(),
      );

  final String file;
  final double period;
  final double speed;
  final double start;
}

class SplashSceneSpec {
  const SplashSceneSpec({required this.key, required this.layers});

  factory SplashSceneSpec.fromJson(Map<String, dynamic> json) =>
      SplashSceneSpec(
        key: json['key'] as String,
        layers: [
          for (final layer in json['layers'] as List)
            SplashLayerSpec.fromJson(layer as Map<String, dynamic>),
        ],
      );

  final String key;

  /// Od najdalszej; ostatnia (pierwszy plan) leży przed kamperem.
  final List<SplashLayerSpec> layers;
}

/// Wymiary kampera w układzie rysunku (`tool/splash_art.py`).
class SplashCamperSpec {
  const SplashCamperSpec({
    required this.box,
    required this.wheels,
    required this.radius,
    required this.ground,
    required this.centerX,
    required this.nightPad,
  });

  factory SplashCamperSpec.fromJson(Map<String, dynamic> json) {
    final (x, y, w, h) = (
      (json['x'] as num).toDouble(),
      (json['y'] as num).toDouble(),
      (json['w'] as num).toDouble(),
      (json['h'] as num).toDouble(),
    );
    return SplashCamperSpec(
      box: Rect.fromLTWH(x, y, w, h),
      wheels: [
        for (final wheel in json['wheels'] as List)
          Offset(
            ((wheel as List)[0] as num).toDouble(),
            (wheel[1] as num).toDouble(),
          ),
      ],
      radius: (json['radius'] as num).toDouble(),
      ground: (json['ground'] as num).toDouble(),
      centerX: (json['centerX'] as num).toDouble(),
      nightPad: (json['nightPad'] as num).toDouble(),
    );
  }

  final Rect box;
  final List<Offset> wheels;
  final double radius;
  final double ground;
  final double centerX;

  /// O tyle obraz nocny wystaje z lewej: poświata tylnej lampy.
  final double nightPad;
}

/// Opis grafik z `assets/splash/manifest.json`.
class SplashManifest {
  const SplashManifest({
    required this.sceneHeight,
    required this.ground,
    required this.skyWidth,
    required this.camperScale,
    required this.camper,
    required this.scenes,
  });

  factory SplashManifest.fromJson(Map<String, dynamic> json) => SplashManifest(
    sceneHeight: (json['sceneHeight'] as num).toDouble(),
    ground: (json['ground'] as num).toDouble(),
    skyWidth: (json['skyWidth'] as num).toDouble(),
    camperScale: (json['camperScale'] as num).toDouble(),
    camper: SplashCamperSpec.fromJson(json['camper'] as Map<String, dynamic>),
    scenes: [
      for (final scene in json['scenes'] as List)
        SplashSceneSpec.fromJson(scene as Map<String, dynamic>),
    ],
  );

  final double sceneHeight;
  final double ground;
  final double skyWidth;
  final double camperScale;
  final SplashCamperSpec camper;
  final List<SplashSceneSpec> scenes;
}
