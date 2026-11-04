import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:jureczek/features/map/presentation/map_labels.dart';

void main() {
  group('isLatinText', () {
    test('przepuszcza polskie i inne łacińskie nazwy z interpunkcją', () {
      for (final name in [
        'Kraków',
        'Żółć',
        'Staroměstské náměstí',
        'Hà Nội',
        'Keshavarz – Park Laleh',
        'Saint Andrew’s Church',
        '5th Avenue',
        '',
      ]) {
        expect(isLatinText(name), isTrue, reason: name);
      }
    });

    test('odrzuca obce alfabety, także w środku nazwy', () {
      for (final name in [
        'Москва',
        'القاهرة',
        'دانشگاه تهران',
        '東京',
        'Αθήνα',
        '1-я улица',
        'до T.REX car wash',
      ]) {
        expect(isLatinText(name), isFalse, reason: name);
      }
    });
  });

  group('poiLabelName', () {
    test(
      'łaciński oryginał ma pierwszeństwo przed angielskim tłumaczeniem',
      () {
        expect(
          poiLabelName({
            'name': 'Episcopal Palace',
            'name_local': 'Pałac Biskupi',
          }),
          'Pałac Biskupi',
        );
      },
    );

    test('obcy alfabet ustępuje przetłumaczonej nazwie', () {
      expect(
        poiLabelName({
          'name': 'Plac Czerwony',
          'name_local': 'Красная площадь',
        }),
        'Plac Czerwony',
      );
    });

    test('bez name_local zostaje name', () {
      expect(poiLabelName({'name': 'Arsenał'}), 'Arsenał');
    });
  });

  group('mapLabelPatches', () {
    Map<String, Object> patchOf(Map<String, Object?> layer) {
      final patches = mapLabelPatches(
        jsonEncode({
          'layers': [layer],
        }),
      );
      expect(patches, hasLength(1));
      return patches.single.properties;
    }

    test('etykieta miejsca dostaje filtr, a tekst zostaje bez zmian', () {
      final properties = patchOf({
        'id': 'place',
        'type': 'symbol',
        'source-layer': 'place_label',
        'layout': {
          'text-field': ['get', 'name'],
        },
      });
      expect(properties.keys, ['filter']);
    });

    test('dotychczasowy filtr zostaje w koniunkcji', () {
      final filter = [
        '==',
        ['get', 'class'],
        'country',
      ];
      final properties = patchOf({
        'id': 'country',
        'type': 'symbol',
        'source-layer': 'place_label',
        'filter': filter,
        'layout': {
          'text-field': ['get', 'name'],
        },
      });
      final patched = properties['filter']! as List;
      expect(patched.first, 'all');
      expect(patched[1], filter);
    });

    test('POI i drogi dostają nazwę lokalną, także w coalesce z name_en', () {
      final properties = patchOf({
        'id': 'road',
        'type': 'symbol',
        'source-layer': 'road',
        'layout': {
          'text-field': [
            'coalesce',
            ['get', 'name_en'],
            ['get', 'name'],
          ],
        },
      });
      final text = jsonEncode(properties['text-field']);
      expect(text, contains('name_local'));
      expect(text, isNot(contains('name_en')));
    });

    test('reszta złożonego tekstu zostaje, np. kod lotniska', () {
      final properties = patchOf({
        'id': 'airport',
        'type': 'symbol',
        'source-layer': 'airport_label',
        'layout': {
          'text-field': [
            'concat',
            ['get', 'ref'],
            ' -\n',
            ['get', 'name'],
          ],
        },
      });
      final text = properties['text-field']! as List;
      expect(text.take(3), [
        'concat',
        ['get', 'ref'],
        ' -\n',
      ]);
      expect(jsonEncode(text.last), contains('name_local'));
    });

    test('pomija warstwy bez nazwy i inne niż symbol', () {
      final patches = mapLabelPatches(
        jsonEncode({
          'layers': [
            {
              'id': 'shield',
              'type': 'symbol',
              'source-layer': 'road',
              'layout': {
                'text-field': ['get', 'ref'],
              },
            },
            {'id': 'road-line', 'type': 'line', 'source-layer': 'road'},
            {
              'id': 'contour',
              'type': 'symbol',
              'source-layer': 'contour',
              'layout': {
                'text-field': ['get', 'ele'],
              },
            },
          ],
        }),
      );
      expect(patches, isEmpty);
    });

    test('wyrażenie Latin nie wymaga dolnej granicy pierwszego zakresu', () {
      // „slice” poza końcem nazwy daje pusty napis, a ten jest mniejszy od
      // U+0000 – z dolną granicą znikały wszystkie krótkie nazwy.
      final properties = patchOf({
        'id': 'place',
        'type': 'symbol',
        'source-layer': 'place_label',
        'layout': {
          'text-field': ['get', 'name'],
        },
      });
      expect(jsonEncode(properties['filter']), isNot(contains(r'\u0000')));
    });

    test('własny styl: wszystkie warstwy z nazwami są poprawione', () {
      final style = File('assets/map/vanventure_dark.json').readAsStringSync();
      expect(mapLabelPatches(style).map((p) => p.layerId), {
        'road-label',
        'poi-label',
        'natural-point-label',
        'place-label-town',
        'place-label-city',
        'country-label',
      });
    });
  });
}
