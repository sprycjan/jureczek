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
