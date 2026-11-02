import 'dart:ui';

/// Własny, klasyczny styl mapy (v12) – plik JSON w assetach aplikacji.
///
/// Na Androidzie assety Fluttera leżą w APK pod `flutter_assets/`, a Mapbox
/// czyta `asset://` z katalogu assetów APK. Styl jest od razu właściwy,
/// więc nie ma czego nakładać po wczytaniu (jak paleta Standardu w v8).
const mapStyleUri = 'asset://flutter_assets/assets/map/vanventure_dark.json';

/// Warstwa etykiet POI w [mapStyleUri] – cel tapnięć i long-tapów (v6).
const poiLabelLayerId = 'poi-label';

/// Kolor warstwy `background` w [mapStyleUri] – zasłona przed wczytaniem
/// stylu ma ten sam kolor, więc odsłonięcie mapy nie mruga.
const mapBackgroundColor = Color(0xFF315041);

/// Style mapy do wyboru przyciskiem „warstwy” (v13). Wybór nie jest
/// zapamiętywany – mapa zawsze startuje w [MapStyleOption.vanventure].
enum MapStyleOption {
  /// Własny ciemny styl z assetu (v12).
  vanventure(mapStyleUri),

  /// Mapbox Outdoors – szlaki, poziomice, cieniowanie terenu.
  outdoors('mapbox://styles/mapbox/outdoors-v12'),

  /// Standard w wyblakłym motywie z budynkami 3D, kamera pochylona.
  faded3d('mapbox://styles/mapbox/standard');

  const MapStyleOption(this.uri);

  final String uri;

  /// Nachylenie kamery po włączeniu stylu – 3D widać dopiero pod kątem.
  double get pitch => this == faded3d ? 60 : 0;

  /// Konfiguracja importu `basemap` nakładana po wczytaniu stylu.
  Map<String, Object> get basemapConfig => switch (this) {
    faded3d => const {'theme': 'faded', 'show3dObjects': true},
    _ => const {},
  };
}
