---
tags: [jureczek, adr, pinezki, ikony]
status: przyjęta
data: 2026-11-03
---
# ADR-011: Biblioteka ikon miejsc w SVG

## Kontekst
Zadanie z 2026-11-03: 74 typy miejsc w 7 kategoriach (specyfikacja Stitch), każdy z pinezką zwykłą, zaznaczoną i samodzielną ikoną 24 dp. Zadanie było napisane pod Jetpack Compose i Android Vector Drawable, a aplikacja jest we Flutterze ([[ADR-001 Flutter]]). Pinezki z v9 to PNG renderowane przez Chrome ([[ADR-010 Kolor pinezki z warstw]]). Przy 222 plikach to byłoby ok. 20 min renderowania i rastrowanie bez potrzeby.

## Rozważane opcje
- PNG z Chrome jak w v9 – 222+ bitmap, wolny render, brak skalowania.
- Android Vector Drawable – Flutter ich nie używa (to zasoby natywnego Androida).
- Rysowanie symboli w Dart (`CustomPainter`) – 74 rysunki w kodzie, brak plików dla projektanta.
- **SVG generowane jednym skryptem, rysowane w aplikacji przez `flutter_svg`, cień malowany we Flutterze.**

## Decyzja
- `app/tool/place_icons.py` to jedyne źródło rysunków. Symbole są na siatce 24×24 z obrysem 1.75. Skrypt zapisuje `assets/place_icons/<kategoria>/<typ>_{icon,default,selected}.svg`.
- Aplikacja rysuje SVG przez `flutter_svg` (`PlaceIcon`, `PlaceIconBadge`, `PlacePin`).
- `flutter_svg` nie obsługuje `<filter>` (wypisuje `unhandled element <filter/>`), więc `PlacePin` i `renderPlacePinPng` malują ten sam cień sami (`PlacePinGeometry`: dy, `stdDeviation`, krycie). Test pilnuje, że te liczby są równe wartościom w SVG.
- Mapbox potrzebuje PNG, więc `renderPlacePinPng` rasteryzuje pinezkę w locie (3x, ucięta na czubku, kotwica `BOTTOM` jak w v9).
- Tokeny kolorów są w `PlaceCategory` (Dart) i `PRIMARY` (skrypt). Test sprawdza zgodność kolorów w każdym SVG.

## Konsekwencje
- Zero zasobów Android (`res/drawable`). SVG można przekonwertować na Vector Drawable bez strat poza cieniem, bo cień jest jedynym filtrem.
- W konsoli debug pojawia się ostrzeżenie `unhandled element <filter/>` przy pierwszym wczytaniu każdej pinezki. Jest spodziewane i nieszkodliwe.
- Zmiana symbolu: edycja `place_icons.py` i ponowne uruchomienie skryptu (sekunda). SVG nie edytować ręcznie.
- Stare pinezki 8 typów (v9/v14) zostają bez zmian. Podpięcie typów miejsc do bazy i formularza to osobny krok.

## Powiązane
[[v15 – biblioteka ikon miejsc]], [[ADR-010 Kolor pinezki z warstw]], [[v9 – kategorie pinezek]], [[00 Jureczek – przegląd]]
