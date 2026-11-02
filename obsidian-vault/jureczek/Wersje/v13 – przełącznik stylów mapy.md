---
tags: [jureczek, wersja, mapbox, styl]
wersja: v13
status: zaimplementowana – sprawdzona przez adb, czeka na potwierdzenie użytkownika
data: 2026-11-02
---
# v13 – przełącznik stylów mapy

Plan z [[v11 – poprawki wyglądu]] („Otwarte”), po [[v12 – własny styl mapy]] domyślnym stylem jest własny VanVenture.

## Zakres
- Pod lupą drugi okrągły przycisk **„Style mapy”** (ikona warstw). Tap rozwija na lewo od niego panel z 4 stylami, wybrany jest w kolorze akcentu:
  | Etykieta | Styl | Uwagi |
  |---|---|---|
  | Nocna wyprawa | własny `vanventure_dark.json` (asset) | domyślny |
  | Teren | `mapbox://styles/mapbox/outdoors-v12` | szlaki, cieniowanie terenu; POI z warstwy `poi-label` |
  | Satelita | `mapbox://styles/mapbox/standard-satellite` | POI z featuresetu `StandardPOIs` |
  | 3D | `mapbox://styles/mapbox/standard` + `theme: faded`, `show3dObjects: true` | kamera pochyla się do 60° |
- Wybór zamyka panel. Panel zamyka też tap w mapę, ponowny tap w przycisk (ikona ✕), otwarcie wyszukiwarki i „Wstecz”.
- Wyjście ze stylu 3D prostuje kamerę (pitch 0, animacja 800 ms). Wybór nie jest zapamiętywany.
- Kompas zszedł pod drugi przycisk.

## Decyzje
| # | Decyzja | Wybór |
|---|---|---|
| 1 | Wygląd przełącznika | przycisk w kolumnie narzędzi + panel z ikoną i nazwą (lista pionowa – 4 kafelki w poziomie nie mieszczą się na 360 dp) |
| 2 | Pinezki po zmianie stylu | `deleteAll()` + ponowna synchronizacja z bazy – obrazki pinezek są obrazkami stylu i nowy styl ich nie ma |
| 3 | POI na wszystkich stylach | dwie pary interakcji: `layerId: 'poi-label'` (własny, Outdoors) i `StandardPOIs()` (satelita, 3D); nieaktywna para nic nie robi |
| 4 | Zapamiętywanie stylu | brak (jak w planie) |
| 5 | Nazwy | „Nocna wyprawa”, „Teren”, „Satelita”, „3D” |

## Pliki
- `app/lib/features/map/presentation/map_style.dart`: enum `MapStyleOption` (`uri`, `pitch`, `basemapConfig`)
- `app/lib/features/map/presentation/map_style_picker.dart`: panel `MapStylePicker`, ikony i etykiety (nowy)
- `app/lib/features/map/presentation/map_screen.dart`: `_style`, `_stylesOpen`, `_selectStyle`, `_onStyleSwitched`, przycisk stylów, interakcje `StandardPOIs`, kompas niżej
- `app/lib/l10n/app_pl.arb`: `mapStylesOpen`, `mapStylesClose`, `mapStyle*`
- Testy: `test/features/map/map_style_picker_test.dart` (4 style, wybór, kolor zaznaczenia, pitch/konfiguracja)

## Pułapki
- `onStyleLoadedListener` odpala się przy każdym `setStyleURI` – pierwszy raz zdejmuje zasłonę, kolejne to zmiana stylu (`_onStyleSwitched`).
- Annotacje (manager, warstwa) przetrwają `setStyleURI`, ale **obrazki** z `PointAnnotationOptions(image:, iconImage:)` są w stylu i giną → pinezki niewidoczne. Plugin dodaje obrazek tylko przy `create`/`update`, gdy `!hasStyleImage`, więc najprościej usunąć i utworzyć annotacje od nowa.
- Konfigurację `basemap` (`theme`) ustawia się po wczytaniu Standardu; Standard ładowany wprost przez URI i tak ma import `basemap`.
- **Satelita bez zdjęć:** kafelki `mapbox.satellite` zwracają HTTP 429 z `x-rate-limit-limit: -1` dla naszego tokenu (vector tiles, fonty i Search Box – 200). Mapa pokazuje wtedy tylko drogi, granice i etykiety na jasnym tle. To ograniczenie konta/tokenu, nie kodu – do sprawdzenia na koncie Mapbox.
- 3D przy małym zoomie (cały kraj) z pochyleniem 60° pokazuje horyzont i kosmos.

## Checklista weryfikacji
- [x] `flutter analyze`: 0 issues
- [x] `flutter test`: 157/157
- [x] P30 przez adb: panel stylów, zaznaczony styl
- [x] P30 przez adb: Teren – pinezki zostają po zmianie stylu
- [x] P30 przez adb: 3D – kamera pochylona, tap w POI (Torre de Belém) pokazuje kartę
- [x] P30 przez adb: powrót do „Nocnej wyprawy” – kamera prosta, znacznik wyniku zostaje
- [ ] Satelita ze zdjęciami (blokuje 429 z Mapboxa)
- [ ] Użytkownik: ogólna ocena, nazwy stylów

## Poprawki po teście
- **„Nocna wyprawa” → „Domyślny”** (użytkownik, 2026-11-02).
- **Satelita usunięty** (użytkownik, 2026-11-02) – zdjęcia i tak się nie ładowały (429). Zostają 3 style: Domyślny / Teren / 3D. Interakcje `StandardPOIs` zostają dla 3D.
- [x] `flutter analyze`: 0 issues, `flutter test`: 157/157
- [x] P30 przez adb: panel z 3 stylami, „Domyślny” zaznaczony
- **Przyciski + i −** (użytkownik, 2026-11-02): pionowa „pigułka” `MapZoomButtons` (`map_tools.dart`) przy prawej krawędzi, na środku wysokości – z dala od narzędzi u góry, karty wyniku i skali na dole. Tap = `easeTo(zoom ± 1)`, 300 ms. Podpowiedzi „Przybliż” / „Oddal” (`mapZoomIn`, `mapZoomOut`).
- [x] `flutter analyze`: 0 issues, `flutter test`: 158/158 (nowy `map_zoom_buttons_test`)
- [x] P30 przez adb: 2× „+” – skala 500 km → 100 km; „−” – 200 km
- [ ] Użytkownik: położenie przycisków

## Otwarte
- 3D: mniejsze pochylenie przy małym zoomie albo przybliżenie przy włączaniu.

Powiązane: [[00 Jureczek – przegląd]], [[v12 – własny styl mapy]], [[v11 – poprawki wyglądu]], [[v6 – klikalne POI]], [[Mapbox Flutter]], [[Backlog]]
