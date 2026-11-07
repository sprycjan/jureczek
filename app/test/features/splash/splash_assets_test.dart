import 'dart:convert';
import 'dart:io';

import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jureczek/features/home/domain/landscape.dart';
import 'package:jureczek/features/splash/domain/splash_config.dart';
import 'package:jureczek/features/splash/domain/splash_manifest.dart';

const _root = 'assets/splash';

String _hex(Color c) =>
    '#${(c.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';

void main() {
  final json =
      jsonDecode(File('$_root/manifest.json').readAsStringSync())
          as Map<String, dynamic>;
  final manifest = SplashManifest.fromJson(json);
  final palette =
      jsonDecode(File('$_root/palettes.json').readAsStringSync())
          as Map<String, dynamic>;

  List<String> svgs() => [
    for (final file in [
      'camper_shadow',
      'camper_under',
      'pebble',
      'camper_body',
      'camper_wheel',
      'camper_night',
      'dust',
    ])
      '$file.svg',
    for (final period in Landscape.values) 'sky_${period.name}.svg',
    for (final scene in manifest.scenes) ...scene.layers.map((l) => l.file),
  ];

  test(
    'każda warstwa sceny istnieje, a ostatnia to pierwszy plan i droga przed nią',
    () {
      expect(manifest.scenes, isNotEmpty);
      for (final scene in manifest.scenes) {
        expect(scene.layers.length, greaterThanOrEqualTo(3));
        expect(
          scene.layers[scene.layers.length - 2].file,
          endsWith('road.svg'),
        );
        expect(scene.layers.last.file, endsWith('front.svg'));
        for (final layer in scene.layers) {
          expect(layer.speed, greaterThan(0));
          expect(layer.period, greaterThan(0));
        }
      }
    },
  );

  test(
    'warstwy są szersze od okresu o zakładkę, żeby na szwie nie było szczeliny',
    () {
      for (final scene in manifest.scenes) {
        for (final layer in scene.layers) {
          final svg = File('$_root/${layer.file}').readAsStringSync();
          final width = double.parse(
            RegExp(r'width="([\d.]+)"').firstMatch(svg)!.group(1)!,
          );
          expect(width, greaterThan(layer.period), reason: layer.file);
        }
      }
    },
  );

  test('każdy kolor w SVG jest tokenem palety', () {
    final color = RegExp(r'#[0-9A-Fa-f]{6}\b');
    for (final file in svgs()) {
      final svg = File('$_root/$file').readAsStringSync();
      for (final match in color.allMatches(svg)) {
        expect(
          palette,
          contains(match.group(0)),
          reason: '$file: ${match.group(0)}',
        );
      }
    }
  });

  test('każdy token ma kolor we wszystkich porach dnia', () {
    for (final entry in palette.entries) {
      final colors = entry.value as Map<String, dynamic>;
      for (final period in Landscape.values) {
        expect(colors, contains(period.name), reason: entry.key);
      }
    }
  });

  test(
    'natywne tło startowe i pierwsza klatka Fluttera mają ten sam gradient',
    () {
      final colors = SplashConfig.launchSky.map(_hex).toList();
      expect(json['launchSky'], colors);
      for (final folder in ['drawable', 'drawable-v21']) {
        final xml = File(
          'android/app/src/main/res/$folder/launch_background.xml',
        ).readAsStringSync();
        expect(xml, contains('android:startColor="${colors[0]}"'));
        expect(xml, contains('android:centerColor="${colors[1]}"'));
        expect(xml, contains('android:endColor="${colors[2]}"'));
      }
    },
  );
}
