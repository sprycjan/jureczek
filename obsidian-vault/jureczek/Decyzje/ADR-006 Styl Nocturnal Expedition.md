---
tags: [jureczek, adr, styl]
status: przyjęta
data: 2026-11-01
---
# ADR-006: Styl „Nocturnal Expedition”

## Kontekst
Aplikacja miała domyślny Material 3 z czerwonym seedem. Użytkownik dostarczył projekty z Google Stitch (`resorces/`): ciemny styl „Nocturnal Expedition” (kolory, Epilogue + Space Grotesk), pinezki kategorii, ekrany startowy i „Nowy folder”.

## Rozważane opcje
- Czcionki: `google_fonts` (pobiera z sieci) vs TTF w assetach.
- Mapa: jasna Standard; `lightPreset: night`; własna paleta przez config properties Standard; styl z Mapbox Studio.

## Decyzja
- Jeden ciemny `ThemeData` (`app/lib/core/theme/app_theme.dart`) z tokenami 1:1 z DESIGN.md; kolory w UI tylko z `Theme`/`Nocturnal`.
- Czcionki jako TTF w assetach (offline, bez opóźnienia).
- Mapa: Standard z paletą przez `setStyleImportConfigProperties('basemap', …)` – „ciemniejszy nocturnal”, nie nocna mapa; ciemne etykiety.

## Konsekwencje
- Brak trybu jasnego.
- Paletę mapy dostraja się w jednym pliku (`map_palette.dart`) i ocenia na telefonie.
- Kolory pinezek kategorii muszą odcinać się od szałwiowego tła ([[v9 – kategorie pinezek]]).

## Powiązane
[[v8 – styl Nocturnal Expedition]], [[00 Jureczek – przegląd]], [[Mapbox Flutter]]
