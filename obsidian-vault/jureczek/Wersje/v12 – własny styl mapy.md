---
tags: [jureczek, wersja, mapbox, styl]
wersja: v12
status: zaimplementowana – sprawdzona przez adb, czeka na potwierdzenie użytkownika
data: 2026-11-02
---
# v12 – własny styl mapy

Użytkownik dostarczył gotowy styl Mapbox GL „VanVenture – Nocturnal Expedition Dark” (JSON, styl klasyczny na `mapbox-streets-v8`). Zastępuje Standard z paletą z [[v8 – styl Nocturnal Expedition]] – [[ADR-008 Własny klasyczny styl mapy]]. Przełącznik stylów przesunięty na v13, kolor pinezki na v14.

## Zakres
- Mapa ciemna: tło `#0d1511`, lasy i zarośla w odcieniach zieleni, ciemna woda z „poświatą” brzegu, szmaragdowe przerywane ścieżki, ciemne drogi z obrysem, jasne etykiety miast z **ciemną** obwódką (koniec problemu białej obwódki z [[v11 – poprawki wyglądu]]).
- Styl leży w `app/assets/map/vanventure_dark.json`, ładowany przez `styleUri` z `asset://` – bez sieci do samego stylu (kafelki i fonty nadal z Mapboxa).
- Paleta Standard (`map_palette.dart`) usunięta.
- Klikalne POI ([[v6 – klikalne POI]]) działają dalej – przez własną warstwę `poi-label` zamiast featuresetu `StandardPOIs`.

## Poprawki względem dostarczonego JSON-a
Bez nich część warstw nic by nie rysowała albo styl nie załadowałby napisów:
| Warstwa | Problem | Poprawka |
|---|---|---|
| fonty | `Epilogue *` nie ma na serwerze fontów Mapbox → brak glifów | `DIN Pro *` + `Arial Unicode MS *` (Epilogue zostaje w UI aplikacji) |
| `place-label-*` | w Streets v8 `class` to `settlement`/`country`…; `town`, `city` są w polu `type` | filtry po `type` (`city`; `suburb`/`town`/`village`) |
| `national-park` | `national_park` jest w `landuse_overlay`, nie `landuse` | zmieniona `source-layer` |
| drogi | brak `street_limited`, `service`, łączników `*_link` | dopisane do klas |
| `admin-boundary` | rysowałby granice morskie i powiaty | tylko `admin_level ≤ 1`, bez `maritime` |
| — | brak etykiet ulic, POI, krajów | dodane `road-label` (z13+), `poi-label` (z12+, `filterrank` zależny od zoomu), `country-label` (do z8) |
Filtry przepisane ze starej składni (`["in", …]`) na wyrażenia (`match`, `get`). Kolory z JSON-a bez zmian; nowe warstwy w tej samej palecie.

## Decyzje
| # | Decyzja | Wybór |
|---|---|---|
| 1 | Gdzie styl | asset w aplikacji (`asset://flutter_assets/…`), nie Mapbox Studio – wersjonowany w repo, bez konta Studio |
| 2 | Fonty | DIN Pro (dostępne w Mapbox), bez wgrywania Epilogue do Studio |
| 3 | POI | własna warstwa `poi-label` + `FeaturesetDescriptor(layerId:)`; nazwa z `properties['name']` |
| 4 | Numeracja | v12 = własny styl; przełącznik stylów → v13, kolor pinezki → v14 |

## Pliki
- `app/assets/map/vanventure_dark.json`: styl (nowy)
- `app/pubspec.yaml`: asset `assets/map/`
- `app/lib/features/map/presentation/map_style.dart`: `mapStyleUri`, `poiLabelLayerId` (nowy)
- `app/lib/features/map/presentation/map_palette.dart`: usunięty
- `app/lib/features/map/presentation/map_screen.dart`: `styleUri: mapStyleUri`, `_onStyleLoaded` tylko zdejmuje zasłonę, interakcje POI na warstwie `poi-label`

## Pułapki
- `asset://` w `styleUri` na Androidzie czyta z katalogu assetów APK; assety Fluttera są pod `flutter_assets/`, więc pełna ścieżka to `asset://flutter_assets/assets/map/…`. (Plugin ma też `MapboxMapsOptions.getFlutterAssetPath`, ale jest asynchroniczny.)
- Styl klasyczny nie ma importu `basemap` → `StandardPOIs()` i `setStyleImportConfigProperties` nic nie robią.
- Styl z zewnątrz trzeba sprawdzić z polami [Streets v8](https://docs.mapbox.com/data/tilesets/reference/mapbox-streets-v8/) – złe pole w filtrze nie daje błędu, warstwa jest po prostu pusta.
- Etykiety są w języku lokalnym (`name`); Streets v8 nie ma `name_pl`.
- `adb shell input tap` dwa razy pod rząd nie daje podwójnego tapnięcia (za wolno) – do przybliżenia użyć wyszukiwarki.

## Checklista weryfikacji
- [x] `flutter analyze`: 0 issues
- [x] `flutter test`: 153/153
- [x] P30 przez adb: mapa Polski w nowym stylu – miasta, kraje, rzeki, granice, drogi
- [x] P30 przez adb: zbliżenie na Rynek Główny – ulice z nazwami, budynki, ścieżki, etykiety POI
- [x] P30 przez adb: tap w POI „Pałac Sztuki” → karta z „Dodaj pinezkę”
- [ ] Użytkownik: ogólna ocena wyglądu, czytelność etykiet
- [ ] Użytkownik: long-tap w POI stawia pinezkę z nazwą

## Otwarte
- Gęstość etykiet miejscowości przy małym zoomie (dziś bez `symbolrank`) – do oceny przez użytkownika.
- Ikony POI (sprite `maki`) – dziś same napisy.
- Przełącznik stylów (v13) musi teraz uwzględnić ten styl jako domyślny.

Powiązane: [[00 Jureczek – przegląd]], [[v11 – poprawki wyglądu]], [[v8 – styl Nocturnal Expedition]], [[v6 – klikalne POI]], [[ADR-008 Własny klasyczny styl mapy]], [[Mapbox Flutter]], [[Backlog]]
