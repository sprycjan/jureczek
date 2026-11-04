import 'dart:convert';

/// Język kafelków: nazwa polska, a gdy jej nie ma – angielska (zwykle
/// transliteracja). Bez nazwy w żadnym z nich zostaje nazwa oryginalna.
const mapLabelLanguage = 'pl,en';

/// Warstwy źródłowe z nazwami, które w kafelkach bywają w obcym alfabecie.
const _namedSourceLayers = {
  'place_label',
  'natural_label',
  'poi_label',
  'road',
  'transit_stop_label',
  'airport_label',
};

/// Warstwy, w których `name` przy braku polskiej nazwy tłumaczy się na
/// angielski także z łaciny („Pałac Biskupi” → „Episcopal Palace”), więc
/// łacińskiemu oryginałowi dajemy pierwszeństwo.
const _preferLocalSourceLayers = {
  'poi_label',
  'road',
  'transit_stop_label',
  'airport_label',
};

/// Tyle pierwszych znaków nazwy sprawdza wyrażenie w stylu. Wyrażenia nie mają
/// pętli, a każdy znak to kolejne porównania.
const _checkedCharacters = 24;

/// Zakresy Unicode bez obcych alfabetów: łacina z rozszerzeniami i znaki
/// przestankowe (półpauza, cudzysłowy). Końce zakresów są wyłączne.
const _latinRanges = [(0x0000, 0x0370), (0x1E00, 0x1F00), (0x2000, 0x2C00)];

/// Czy tekst da się przeczytać bez znajomości obcego alfabetu.
bool isLatinText(String text) => text.runes.every(
  (rune) => _latinRanges.any((range) => rune >= range.$1 && rune < range.$2),
);

/// Nazwa POI jak na etykiecie mapy: [_labelExpression] w wersji dla Darta.
String? poiLabelName(Map<String?, Object?> properties) {
  final name = properties['name'] as String?;
  final local = properties['name_local'] as String?;
  return local != null && isLatinText(local) ? local : name;
}

/// Zmiana właściwości jednej warstwy etykiet.
typedef MapLabelPatch = ({String layerId, Map<String, Object> properties});

/// Zmiany warstw etykiet w stylu [styleJson], po których na mapie zostają
/// tylko nazwy łacińskie.
List<MapLabelPatch> mapLabelPatches(String styleJson) {
  final style = jsonDecode(styleJson) as Map<String, dynamic>;
  final layers = (style['layers'] as List?) ?? const [];
  return [
    for (final layer in layers.cast<Map<String, dynamic>>()) ?_patchFor(layer),
  ];
}

MapLabelPatch? _patchFor(Map<String, dynamic> layer) {
  final sourceLayer = layer['source-layer'];
  if (layer['type'] != 'symbol' || !_namedSourceLayers.contains(sourceLayer)) {
    return null;
  }
  final textField = (layer['layout'] as Map?)?['text-field'];
  if (textField == null || !_mentionsName(textField)) return null;

  final filter = layer['filter'];
  final latinOnly = _isLatinExpression(_getName);
  return (
    layerId: layer['id'] as String,
    properties: {
      'filter': filter == null ? latinOnly : ['all', filter, latinOnly],
      if (_preferLocalSourceLayers.contains(sourceLayer))
        'text-field': _withLabelName(textField)!,
    },
  );
}

const _getName = ['get', 'name'];
const _getNameEn = ['get', 'name_en'];

/// `name_local`, gdy jest łaciński, a w przeciwnym razie przetłumaczone `name`.
const _localOrName = [
  'coalesce',
  ['get', 'name_local'],
  _getName,
];

Object get _labelExpression => [
  'case',
  _isLatinExpression(_localOrName),
  ['to-string', _localOrName],
  _getName,
];

/// Prawda, gdy pierwsze [_checkedCharacters] znaków leży w [_latinRanges].
/// Porównanie napisów idzie po punktach kodowych, a `slice` poza końcem daje
/// pusty napis, który mieści się w pierwszym zakresie.
Object _isLatinExpression(Object value) => [
  'all',
  for (var i = 0; i < _checkedCharacters; i++)
    ['any', for (final range in _latinRanges) _inRange(value, i, range)],
];

Object _inRange(Object value, int index, (int, int) range) {
  final char = [
    'slice',
    ['to-string', value],
    index,
    index + 1,
  ];
  final below = ['<', char, String.fromCharCode(range.$2)];
  // Pusty napis jest mniejszy od każdego znaku, także od U+0000, więc pierwszy
  // zakres nie może mieć dolnej granicy.
  if (range.$1 == 0) return below;
  return [
    'all',
    ['>=', char, String.fromCharCode(range.$1)],
    below,
  ];
}

bool _mentionsName(Object? node) => switch (node) {
  final List<dynamic> list => _isNameLookup(list) || list.any(_mentionsName),
  _ => false,
};

/// Podmienia odwołania do nazwy, a resztę wyrażenia (np. kod lotniska) zostawia.
Object? _withLabelName(Object? node) => switch (node) {
  final List<dynamic> list when _isNameLookup(list) => _labelExpression,
  final List<dynamic> list => [for (final item in list) _withLabelName(item)],
  _ => node,
};

/// `["get", "name"]` albo klasyczne `["coalesce", ["get", "name_en"], …]`.
bool _isNameLookup(List<dynamic> node) {
  final json = jsonEncode(node);
  return json == jsonEncode(_getName) ||
      json == jsonEncode(['coalesce', _getNameEn, _getName]);
}
