---
tags: [jureczek, mapbox, flutter]
---
# Mapbox Maps Flutter (v3)

- Pakiet: `mapbox_maps_flutter` **3.33.0**, sfederowany (`_mobile`, `_web`, `_platform_interface`).
- Wymagania: Flutter ≥ 3.38.1, Dart ≥ 3.10, Android minSdk 21, compileSdk 36.
- Docs: Context7 `/mapbox/mapbox-maps-flutter`; źródła w `~/.pub-cache/hosted/pub.dev/mapbox_maps_flutter*-3.33.0/`.

## Setup
```dart
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  MapboxOptions.setAccessToken(mapboxAccessToken); // przed pierwszym MapWidget
  runApp(const ProviderScope(child: JureczekApp()));
}
```
Token: [[ADR-003 Token Mapbox]].

## ⚠️ Zmiany w v3 (stare przykłady z internetu nie działają!)
| v2 | v3 |
|---|---|
| `MapWidget(cameraOptions: CameraOptions(...))` | `MapWidget(viewport: CameraViewportState(center:, zoom:))` |
| `MapWidget(onTapListener:/onLongTapListener:)` | `map.addInteraction(TapInteraction.onMap(...) / LongTapInteraction.onMap(...))` w `onMapCreated` |

## Kamera startowa (Polska)
```dart
final _polandViewport = CameraViewportState(
  center: Point(coordinates: Position(19.4, 52.0)), // Position(lng, lat)!
  zoom: 5.3,
);
```

## Ornamenty (kompas, skala)
- Domyślnie kompas jest w prawym górnym rogu, a skala w lewym górnym. Przy mapie pełnoekranowej oba chowają się pod paskiem statusu.
- Ustawia się je w `onMapCreated`: `map.compass.updateSettings(CompassSettings(position: OrnamentPosition.TOP_RIGHT, marginTop: …))` oraz `map.scaleBar.updateSettings(ScaleBarSettings(…))`.
- Marginesy podaje się w **dp**, bo plugin na Androidzie sam robi `toDevicePixels` (`mapping/CompassMappings.kt`). Wysokość paska statusu bierze się z `MediaQuery.paddingOf(context).top`.
- Logo i atrybucja są w lewym dolnym rogu i muszą zostać widoczne (licencja), więc skala stoi w prawym dolnym. Zob. [[v5 – kompas i skala]].

## Długie przytrzymanie → pinezka
```dart
map.addInteraction(
  LongTapInteraction.onMap((context) {      // MapContentGestureContext
    final p = context.point.coordinates;    // p.lat, p.lng (num)
    ref.read(pinsProvider.notifier).add(lat: p.lat.toDouble(), lng: p.lng.toDouble());
  }),
);
```

## Pinezki (annotations)
- `PointAnnotation` **nie ma domyślnej ikony**: trzeba podać `image: Uint8List` (asset PNG) albo `iconImage` ze stylu.
- `iconAnchor: IconAnchor.BOTTOM`, żeby czubek „łezki” wskazywał miejsce.
- Asset: `app/assets/markers/pin.png` (96×128, wygenerowany skryptem); na mapie skala `iconSize: 0.6`.
```dart
final manager = await map.annotations.createPointAnnotationManager();
await manager.create(PointAnnotationOptions(
  geometry: Point(coordinates: Position(lng, lat)),
  image: pinBytes, iconAnchor: IconAnchor.BOTTOM, iconSize: 0.6,
));
```
- `manager.create` zwraca `PointAnnotation` z własnym `id` (innym niż nasze id pinezki). Do usunięcia potrzebny jest ten obiekt: `manager.delete(annotation)`.
- Tapnięcie: `final c = manager.tapEvents(onTap: (PointAnnotation a) {...})` zwraca `Cancelable`, które trzeba anulować w `dispose` (`c.cancel()`).
- `manager.id` to id warstwy annotacji (Android: `AnnotationConfig(belowLayerId, id, id)`). Dzięki temu można zrobić interakcję tylko na pinezkach: `LongTapInteraction(FeaturesetDescriptor(layerId: manager.id), …, stopPropagation: true)`. Ma ona pierwszeństwo przed `LongTapInteraction.onMap` (sprawdzone na telefonie), więc tak blokujemy dublowanie pinezek.
- Na przyszłość: `longPressEvents`, `dragEvents` na managerze; `textField` do etykiet; `CircleAnnotation` to prosta alternatywa bez assetu.

## Wzorzec w aplikacji (v2)
Baza jest jedynym źródłem prawdy ([[ADR-005 Drift jako baza lokalna]]). Gesty wołają tylko `PinsController` (`add` / `remove` / `restore`), a `ref.listen(pinsProvider)` (strumień z drifta) uruchamia `_syncPins`:
- diff mapy `_annotationsByPinId` (id pinezki → `PointAnnotation`) ze stanem: zbędne usuwa, brakujące tworzy,
- odwrotna mapa `_pinIdByAnnotationId` tłumaczy tapnięcie na id pinezki,
- synchronizacje idą w łańcuchu `Future`, żeby szybkie zmiany się nie przeplatały.

Plik: `app/lib/features/map/presentation/map_screen.dart`.

## Wyszukiwanie miejsc (v4)
Plugin `mapbox_maps_flutter` **nie ma wyszukiwarki**, więc wołamy REST **Search Box API** (`api.mapbox.com/search/searchbox/v1`) tym samym publicznym tokenem.
- `GET /suggest?q&session_token&language=pl&limit=6&proximity=lng,lat` zwraca `suggestions[]` z polami `name`, `mapbox_id`, `full_address`/`place_formatted` i `feature_type`. Odpowiedź **nie zawiera współrzędnych**.
- `GET /retrieve/{mapbox_id}?session_token` zwraca GeoJSON `FeatureCollection` z `geometry.coordinates = [lng, lat]`.
- Rozliczenie idzie za **sesję**: to samo `session_token` (UUID) w `suggest…` i `retrieve`. Sesja kończy się na `retrieve`, po 180 s bez niego albo po 50 zapytaniach `suggest`. Darmowe jest 500 sesji miesięcznie.
- Geocoding v6 (`/search/geocode/v6/forward`) jest tańszy (100 tys. zapytań miesięcznie gratis), ale **nie zwraca POI**.
- Tymczasowy znacznik wyniku to `CircleAnnotationManager` utworzony po managerze pinezek, więc leży nad nimi. `circleColor`/`circleStrokeColor` to `int` (`Colors.blue.toARGB32()`).
- Przelot: `map.flyTo(CameraOptions(center: point, zoom: 15), MapAnimationOptions(duration: 1500))`. Działa obok `viewport:` w `MapWidget`, bo stała `_polandViewport` się nie zmienia i nie jest stosowana ponownie.
- Środek mapy do `proximity`: `(await map.getCameraState()).center.coordinates`.
- Tap w mapę: `TapInteraction.onMap(..., stopPropagation: false)`.

## Klikalne POI (v6)
Styl Standard ma featureset `poi` (import `basemap`), więc nie trzeba żadnych zapytań do API:
```dart
map.addInteraction(TapInteraction(StandardPOIs(), (poi, context) {
  poi.name;                       // String?
  poi.geometry['coordinates'];    // [lng, lat] – NIE używać poi.coordinate!
}));
```
- ⚠️ **Błąd w pluginie 3.33:** `poi.coordinate` robi `geometry["coordinates"] as Point?` na liście → `TypeError`. Wyjątek z handlera ginie w pigeonie bez logu, a natywna interakcja (domyślnie `stopPropagation: true`) i tak zjada tap. Objaw: „tap w POI nic nie robi”. Obejście: `placeFromPoi` w `domain/poi_place.dart`.
- Ogólnie: wyjątek w handlerze `addInteraction` jest niewidoczny. Przy dziwnym „nic się nie dzieje” owinąć handler w `try/catch` + `debugPrint`.
- Interakcja na featuresecie ma pierwszeństwo przed `TapInteraction.onMap`. Tap w pinezkę stojącą na POI otwiera tylko arkusz pinezki (sprawdzone przez adb).
- Inne pola: `group`, `category` (`class`), `maki`; stan `StandardPOIsState(hide:)` do chowania ikony.

## Własny styl z assetu (v12)
Od [[v12 – własny styl mapy]] mapa nie używa Standardu, tylko klasycznego stylu JSON z assetów:
```dart
const mapStyleUri = 'asset://flutter_assets/assets/map/vanventure_dark.json';
MapWidget(styleUri: mapStyleUri, …)
```
- Android: `asset://` czyta z assetów APK, assety Fluttera są pod `flutter_assets/`.
- Fonty tylko z serwera Mapbox (np. `DIN Pro Medium`, `Arial Unicode MS Regular`); nieistniejący font = brak napisów.
- Pola Streets v8: `place_label.type` (city/town/village), `class` (country/settlement…); park narodowy w `landuse_overlay`; POI w `poi_label` (`name`, `maki`, `filterrank`).
- Klikalne POI bez Standardu: `TapInteraction(FeaturesetDescriptor(layerId: 'poi-label'), (f, _) => f.properties['name'] …)`.
- Kolor zasłony przed wczytaniem stylu = `background-color` stylu (`mapBackgroundColor`); przy zmianie tła w JSON-ie zmienić też stałą.
- `StandardPOIs()` i `setStyleImportConfigProperties` nie działają w stylu klasycznym (brak importu `basemap`).

## Własna paleta Standard (v8, zastąpiona w v12)
Standard ładowany przez `styleUri: MapboxStyles.STANDARD` ma import `basemap`. Kolory zmienia się w kodzie, bez Mapbox Studio:
```dart
await map.setStyleImportConfigProperties('basemap', {
  'colorLand': '#465249', 'colorWater': '#4d7480', 'colorGreenspace': '#3b5245',
  'colorRoads': '#89938b', 'colorTrunks': '#bec9c0', 'colorMotorways': '#b8875a',
  'colorPlaceLabels': '#0d1511', 'colorRoadLabels': '#151d19',
  'colorPointOfInterestLabels': '#0d1511', 'colorAdminBoundaries': '#2e3732',
});
```
- Wołać w `MapWidget(onStyleLoadedListener: …)` – po każdym załadowaniu stylu.
- `map.style.*` jest deprecated; metody są na `MapboxMap`.
- Etykiety mają automatyczną obwódkę kontrastową: ciemny tekst dostaje jasną obwódkę. Jasny tekst **też** dostaje jasną obwódkę (spike v11 na P30) – Standard nie ma konfiguracji obwódki, więc jasne etykiety na ciemnej mapie są nieczytelne.
- Paleta nakładana w `onStyleLoaded` → przez chwilę widać domyślny Standard. W v11 zasłona w kolorze tła do nałożenia palety – [[v11 – poprawki wyglądu]].

## Obrazki pinezek (v9)
- `PointAnnotationOptions(image: pngBytes, iconImage: 'pin-gastronomy-default', iconAnchor: IconAnchor.BOTTOM, iconSize: dpr / 3)` – z `iconImage` obraz trafia do stylu raz i jest współdzielony.
- Zmiana wyglądu: `annotation..image = bytes..iconImage = id; await manager.update(annotation)` (Android: `updateAnnotation` dodaje obraz do stylu, jeśli go nie ma).
- PNG ma czubek na dolnej krawędzi – kotwica `BOTTOM` bez `iconOffset`.

Powiązane: [[v9 – kategorie pinezek]], [[v8 – styl Nocturnal Expedition]], [[v6 – klikalne POI]], [[v1 – mapa i pinezki]], [[v2 – trwałe pinezki i usuwanie]], [[v4 – wyszukiwarka miejsc]], [[ADR-001 Flutter]]

## Osadzenie widoku na Androidzie (v11)
- Domyślnie `MapWidget` = Hybrid Composition + `SurfaceView`. Szybkie, ale nie animuje się z trasą Fluttera i miga przy wejściu na ekran.
- `textureView: true` + `androidHostingMode: AndroidPlatformViewHostingMode.TLHC_HC` → mapa jako tekstura w drzewie Fluttera (płynne przejścia, nakładki działają). API `@experimental`. Koszt: kopia `SurfaceTexture` na klatkę – [[v11 – poprawki wyglądu]].
