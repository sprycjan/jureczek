---
tags: [jureczek, adr, pinezki, drift]
status: przyjęta
data: 2026-11-03
---
# ADR-012: Typ miejsca jako typ pinezki

## Kontekst
v15 dała bibliotekę 74 typów miejsc ([[ADR-011 Biblioteka ikon miejsc w SVG]]), a pinezki miały 8 typów z v9: zieloną i 7 kategorii. Trzeba było zdecydować, jak typ ma się do kategorii, jak go zapisać i co zrobić ze starymi danymi.

## Rozważane opcje
- Nowa kolumna `place_type` obok `category` – dwie kolumny z tą samą informacją.
- Typ obok kategorii, stare pinezki kategorii w starym wyglądzie – dwa systemy wyglądu.
- **Typ zastępuje kategorię; kolumna `category` trzyma klucz typu albo `standard`.**

## Decyzja
- `PinKind`: zielona „Pinezka” (`type == null`, klucz `standard`) albo `PlaceType`. Kategoria wynika z typu.
- Do każdej kategorii doszedł typ „inne” (`<kategoria>_other`) z własnym, ogólnym symbolem: 81 typów.
- Schemat 7: `UPDATE pins SET category = category || '_other'` dla 7 kluczy v9. Bez przebudowy tabeli.
- Zielona zostaje jako PNG z `render_pins.py` (z barwieniem warstw). PNG i warstwy 7 kategorii v9 usunięte.
- Własny kolor typu: `PinColorMapper` (`ColorMapper` z `flutter_svg`) podmienia kolor kategorii w SVG.

## Konsekwencje
- Jedno źródło prawdy; nieznany klucz w bazie to zielona „Pinezka”.
- Nazwa kolumny `category` zostaje, choć trzyma typ – komentarz w `pins_table.dart`.
- PNG typu powstaje przy pierwszej pinezce danego wyglądu (cache w `map_screen.dart`); przed-ładowana jest tylko zielona.
- Nowe typy dopisuje się w `tool/place_icons.py` i `PlaceType`; testy pilnują kompletu SVG i unikalności symboli.

## Powiązane
[[v16 – typy miejsc w pinezkach]], [[ADR-011 Biblioteka ikon miejsc w SVG]], [[ADR-010 Kolor pinezki z warstw]], [[ADR-005 Drift jako baza lokalna]]
