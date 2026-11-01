---
tags: [jureczek, wersja, styl, mapbox]
wersja: v8
status: zaimplementowana – sprawdzona przez adb, poprawki po uwagach użytkownika czekają na potwierdzenie
data: 2026-11-01
---
# v8 – styl Nocturnal Expedition

## Zakres
- Ciemny motyw całej aplikacji z tokenów „Nocturnal Expedition” (`resorces/stitch_camper_vacation_planner_ui/nocturnal_expedition/DESIGN.md`) – [[ADR-006 Styl Nocturnal Expedition]].
- Czcionki: **Epilogue** (nagłówki) i **Space Grotesk** (treść, etykiety) dołączone jako TTF.
- Mapa Mapbox Standard w „ciemniejszym nocturnalu” (nie nocna mapa): szałwiowy ląd, przygaszona lodowa woda, ciemne etykiety.
- Nowa ikona aplikacji: kamper z `resorces/screen.png`, przycięty i powiększony, na kremowym tle (adaptive icon).
- Ciemny ekran przy uruchamianiu zamiast białego; znacznik wyniku wyszukiwania w bursztynie.

## Decyzje
| # | Decyzja | Wybór |
|---|---|---|
| 1 | Czcionki | TTF w assetach (offline); statyczne grubości wycięte z fontów zmiennych (`fonttools varLib.instancer`), bo Flutter nie mapuje pewnie `fontWeight` na oś `wght` |
| 2 | Styl mapy | config properties Standard w kodzie (`setStyleImportConfigProperties('basemap', …)`), bez Mapbox Studio |
| 3 | Etykiety i granice | ciemne (`#0d1511`, `#2e3732`) – jasne źle wyglądały na ciemniejszej mapie (ocena na P30) |
| 4 | Ikona | kremowe tło `#F7F8F5`; wyśrodkowane nadwozie kampera ~54% foregroundu 108 dp, mieści się w bezpiecznym kole 66 dp; kurz z tyłu może się przyciąć |

## Pliki
- `app/lib/core/theme/app_theme.dart`: nowy – `Nocturnal` (tokeny), `appTheme` (ColorScheme, TextTheme ze skali DESIGN.md, arkusze, pola, przyciski, snackbar)
- `app/lib/features/map/presentation/map_palette.dart`: nowy – `mapPalette`, `applyMapPalette`
- `app/lib/features/map/presentation/map_screen.dart`: `onStyleLoadedListener` → paleta; kolor znacznika wyniku
- `app/lib/app.dart`: `theme: appTheme`; `app/lib/main.dart`: licencje OFL w `LicenseRegistry`
- `app/pubspec.yaml`: sekcja `fonts`, licencje w assetach; `app/assets/fonts/`: 6 TTF + 2 OFL
- `app/android/app/src/main/res/`: `mipmap-*/ic_launcher.png`, `mipmap-*/ic_launcher_foreground.png`, `mipmap-anydpi-v26/ic_launcher.xml`, `values/ic_launcher_background.xml`, `drawable*/launch_background.xml`

## Pułapki
- Pomniejszony zrzut ekranu myli przy ocenie etykiet – oceniać wycinek w pełnej rozdzielczości.
- `map.style.*` jest deprecated – wołać `map.setStyleImportConfigProperties(...)` bezpośrednio.
- Generator ikony nie jest w repo (skrypt Pillow w scratchpadzie sesji); przy zmianie: przyciąć `screen.png` do nadwozia x 238–825, y 234–692, alfa z różnicy od tła `#F7F8F5`.

## Checklista weryfikacji
- [x] `flutter analyze`: 0 issues
- [x] `flutter test`: 126/126
- [x] P30 przez adb: paleta się nakłada (kraj i zbliżenie), ciemne etykiety czytelne
- [x] Użytkownik: mapa w przybliżeniu OK
- [ ] Użytkownik: ciemne etykiety POI/miejscowości i granice po poprawce
- [ ] Użytkownik: ikona po zmniejszeniu kampera

## Poprawki po teście
- Jasne etykiety (`#dce5de`) i granice (`#9ecedf` → `#6b9aab`) słabo widoczne → ciemne etykiety i granice.
- Kamper na ikonie za duży, ucięty przód → mniejszy, wyśrodkowane nadwozie.

## Otwarte
- Pinezki nadal czerwone – [[v9 – kategorie pinezek]] (planowane).

Powiązane: [[00 Jureczek – przegląd]], [[v7 – animacja spadania pinezki]], [[ADR-006 Styl Nocturnal Expedition]], [[Mapbox Flutter]]
