---
tags: [jureczek, adr, pinezki]
status: przyjęta
data: 2026-11-02
---
# ADR-010: Kolor pinezki z warstw

## Kontekst
Własny kolor pinezki: 24 kolory × 8 typów × 2 stany (zwykła, zaznaczona). Mapbox potrzebuje bitmap PNG ([[Mapbox Flutter]]), a pinezki to SVG z cieniem (`feDropShadow`) renderowane przez `render_pins.py`.

## Rozważane opcje
- Gotowe PNG dla każdej kombinacji – 384 pliki, każdy nowy kolor to nowy render.
- SVG w aplikacji (np. `flutter_svg`) z podmianą koloru – brak filtrów, czyli brak cienia.
- Rysowanie kształtu w Dart – dwa różne kształty, ręczny cień, rozjazd z SVG.
- **Warstwy z `render_pins.py` barwione w aplikacji.**

## Decyzja
Skrypt rozbija każde SVG na warstwy: korpus na biało z cieniem (`body`), elementy bez zmian (`overlay`: biały symbol, obwódka zaznaczenia, tarcza) i kolorową kropkę pinezki domyślnej (`accent`). Aplikacja (`renderPinPng`) składa je na `Canvas`, barwiąc `body` i `accent` przez `BlendMode.modulate`, i cache'uje PNG dla wyglądu. Bez własnego koloru używany jest gotowy PNG kategorii.

## Konsekwencje
- 34 małe PNG zamiast 384; nowy kolor to jedna linia w `PinColor`.
- Pinezka domyślna w kolorze ma przybliżony gradient (biały → szary × kolor).
- Test porównuje złożenie w kolorze z SVG z gotowym PNG – pilnuje zgodności skryptu i aplikacji.
- Zmiana SVG wymaga ponownego `render_pins.py` (ok. 4 min).

## Powiązane
[[v14 – lokalizacja, ikony POI i kolor pinezki]], [[v9 – kategorie pinezek]], [[00 Jureczek – przegląd]]
