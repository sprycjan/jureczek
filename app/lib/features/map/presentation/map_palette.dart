import 'package:flutter/foundation.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

/// Import stylu Mapbox Standard ładowanego bezpośrednio przez `styleUri`.
const _standardImportId = 'basemap';

/// Paleta mapy w stylu „Nocturnal Expedition”: przygaszona, ciemniejsza
/// szałwia i lodowa woda, ale nie nocna mapa (v8, spike do oceny na telefonie).
const mapPalette = <String, Object>{
  'colorLand': '#465249',
  'colorGreenspace': '#3b5245',
  'colorWater': '#4d7480',
  'colorRoads': '#89938b',
  'colorTrunks': '#bec9c0',
  'colorMotorways': '#b8875a',
  // Jasne etykiety i granice źle wyglądały na ciemniejszej mapie (ocena na P30).
  'colorPlaceLabels': '#0d1511',
  'colorRoadLabels': '#151d19',
  'colorPointOfInterestLabels': '#0d1511',
  'colorAdminBoundaries': '#2e3732',
};

/// Nakłada [mapPalette] na Standard; błąd nie psuje mapy, zostaje domyślny wygląd.
Future<void> applyMapPalette(MapboxMap map) async {
  try {
    await map.setStyleImportConfigProperties(
      _standardImportId,
      mapPalette,
    );
  } catch (e) {
    debugPrint('Paleta mapy nie została nałożona: $e');
  }
}
