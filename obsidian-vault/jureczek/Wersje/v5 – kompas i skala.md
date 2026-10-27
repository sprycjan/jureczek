---
tags: [jureczek, wersja, mapbox]
wersja: v5
status: zaimplementowana – kompas do sprawdzenia na telefonie
data: 2026-10-27
---
# v5 – kompas i skala

## Zakres
- Mapa nadal zajmuje cały ekran, pod przezroczystym paskiem statusu Androida.
- **Kompas** (pojawia się po obróceniu mapy) jest teraz pod lupą, w kolumnie narzędzi. Wcześniej stał w prawym górnym rogu pod paskiem statusu i częściowo zasłaniała go lupa.
- **Skala** jest teraz na dole po prawej, w jednym rzędzie z logo Mapbox. Wcześniej była w lewym górnym rogu pod ikonami powiadomień.

## Decyzje
| # | Decyzja | Wybór |
|---|---|---|
| 1 | Mapa pełnoekranowa czy pod paskiem statusu | pełnoekranowa; przesuwamy tylko ornamenty |
| 2 | Kompas | `TOP_RIGHT`, pod lupą: `marginTop = insets.top + 16 + 48 + 12`, `marginRight = 20` (wyśrodkowany względem przycisku 48 dp) |
| 3 | Skala | `BOTTOM_RIGHT`, `marginBottom = insets.bottom + 8`, `marginRight = 16`; lewy dół zajmuje logo i atrybucja Mapbox |

## Pliki
- `app/lib/features/map/presentation/map_screen.dart`: `_placeOrnaments` wywoływane na początku `_onMapCreated` (`map.compass` / `map.scaleBar` `.updateSettings`), stałe `_toolsPadding` i `_toolSize`

## Pułapki
- Marginesy ornamentów w pluginie Flutter podaje się w **dp**, bo plugin na Androidzie sam przelicza je przez `toDevicePixels`. Szczegóły w [[Mapbox Flutter]].
- Kompasu nie da się sprawdzić przez adb, bo obrót wymaga gestu dwoma palcami.
- Gdy otwarta jest karta wyniku (40 dp od dołu), może zasłaniać skalę. Na razie to nie przeszkadza.

## Checklista weryfikacji
- [x] `flutter analyze`: 0 issues
- [x] `flutter test`: 117/117
- [x] Telefon (screenshot): skala na dole po prawej, w rzędzie z logo, niczym niezasłonięta
- [ ] Telefon: po obróceniu mapy kompas jest pod lupą i nie chowa się pod paskiem statusu

## Otwarte
- Potwierdzić położenie kompasu na P30.

Powiązane: [[00 Jureczek – przegląd]], [[v4 – wyszukiwarka miejsc]], [[Mapbox Flutter]]
