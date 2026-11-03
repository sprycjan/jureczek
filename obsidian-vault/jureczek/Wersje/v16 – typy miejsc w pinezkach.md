---
tags: [jureczek, wersja, pinezki, drift, mapbox]
wersja: v16
status: zaimplementowana – sprawdzona przez adb, czeka na potwierdzenie użytkownika
data: 2026-11-03
---
# v16 – typy miejsc w pinezkach

Prośba użytkownika z 2026-11-03: „zaimplementuj teraz te pinezki w aplikacji” – biblioteka z [[v15 – biblioteka ikon miejsc]] trafia do mapy, formularza i arkusza. Plan doprecyzowany w trzech rundach pytań (grill-plan).

## Zakres
- **81 typów:** 74 z v15 i 7 typów „inne” (po jednym na kategorię, ogólne symbole):

  | Kategoria | Symbol „inne” |
  |---|---|
  | gastronomia | talerz z kopułą |
  | miejsca | flaga |
  | natura | liść |
  | aktywności | szczyt z flagą |
  | podróż | walizka |
  | rozrywka | gwiazdka |
  | praktyczne | klucz i śrubokręt |

  Bez typu zostaje zielona „Pinezka”.
- **Wybór typu w dwóch krokach:**
  - rząd 8 pozycji: zielona i 7 pinezek „inne” jako znaki kategorii;
  - tap w kategorię otwiera siatkę jej typów (pinezka + nazwa), a wybór zmienia dopiero tap w typ;
  - w edycji siatka jest od razu otwarta na kategorii zapisanego typu;
  - nad rzędem nazwa wybranego typu, np. „Muzeum · Miejsca i atrakcje”.
- **Mapa, spadanie, arkusz:** pinezki SVG z cieniem. Własny kolor działa przez podmianę koloru kategorii w wektorze (`PinColorMapper`). Nagłówek arkusza to „Typ · Kategoria”.
- **Podpowiedź typu z `maki`:** long-tap na POI, karta POI i wyniki wyszukiwarki (`properties.maki` z retrieve, zapas z suggest). Nieznane `maki` daje zieloną. Tabela jest w `maki_place_type.dart`.
- **Migracja (schemat 7):** pinezki kategorii v9 dostają typ „inne” swojej kategorii, a kolor zostaje.

## Decyzje
| # | Decyzja | Wybór |
|---|---|---|
| 1 | Typ a kategorie v9 | typ zastępuje kategorię; zostaje zielona bez typu – [[ADR-012 Typ miejsca jako typ pinezki]] |
| 2 | Wybór typu | dwa kroki: rząd kategorii → siatka typów |
| 3 | Własny kolor | działa dla SVG (`ColorMapper`) |
| 4 | Podpowiedź z `maki` | teraz |
| 5 | Migracja v9 | 7 typów „inne” |
| 6 | Zapis | kolumna `category` = klucz typu albo `standard`; schemat 7 = `UPDATE` |
| 7 | Zachowanie wyboru | tap w kategorię nie zmienia wyboru; zielona pierwsza; edycja otwiera kategorię typu |
| 8 | Gdzie podpowiedź | long-tap POI, karta POI, wyszukiwarka |
| 9 | Stare PNG v9 | usunięte (zostaje zielona) |
| 10 | Symbol „inne” | 7 nowych ogólnych symboli |
| 11 | Rząd kategorii | pinezki „inne” |
| 12 | Nagłówek arkusza | pinezka + „Typ · Kategoria” |

## Pliki
- **Generator i assety:** `tool/place_icons.py` (7 symboli „inne”), `assets/place_icons/*` (243 SVG).
- **Domena typów miejsc:**
  - `lib/features/places/domain/place_type.dart`: 7 typów `*Other`, `isOther`, `PlaceCategory.otherType`;
  - `maki_place_type.dart` (nowy);
  - `place_labels.dart`: „Inne”, `fullLabel`;
  - `place_icons.dart`: `PinColorMapper`, `PlacePin(color:)`, `renderPlacePinPng(color:)`.
- **Domena mapy:**
  - `lib/features/map/domain/pin_kind.dart` (nowy, zastępuje `pin_category.dart`, który jest usunięty);
  - `place_pin.dart` (`kind`), `place_suggestion.dart` (`suggestedType`), `poi_place.dart` (`maki`).
- **Baza i dane:**
  - `lib/core/database/app_database.dart`: schemat 7;
  - `pins_table.dart` (komentarz), `pins_repository.dart`, `pins_providers.dart`, `place_search_client.dart` (`maki`).
- **Prezentacja:**
  - `pin_type_picker.dart` (nowy, zastępuje `pin_category_picker.dart`);
  - `pin_image.dart`: zielona z warstw, typ z SVG, `renderPinPng(PinKind)`;
  - `new_pin_sheet.dart`, `pin_details_sheet.dart`, `pin_form_fields.dart`;
  - `map_screen.dart`: wygląd `(PinKind, zaznaczona, kolor)`, `maki` z POI.
- **Sprzątanie:** usunięte `assets/markers/{7 kategorii}_*.png`, `src/*.svg`, `tint/*`; `tool/render_pins.py` obsługuje tylko zieloną.
- **Testy:**
  - migracja 6 → 7, repozytorium, kontroler;
  - `pin_image_test` (typ w kolorze kategorii i własnym);
  - arkusze (dwa kroki, podpowiedź, nagłówek);
  - `poi_place_test`, `place_search_client_test` (`maki`), `place_icons_test` (81 / 243).

## Pułapki
- `ColorMapper` wchodzi do klucza cache `flutter_svg`, więc `PinColorMapper` musi mieć `==` i `hashCode`. Bez tego każde rysowanie byłoby nowym parsowaniem.
- PNG zielonej ma większe marginesy (korpus 36 dp w ramce 54 × 56 dp). `PinImage` typu przyjmuje te same proporcje, żeby korpusy w rzędzie były równe.
- Baza na telefonie leży w `app_flutter/jureczek.sqlite`, nie w `databases/`. Kopia przez `adb exec-out run-as pl.mc.jureczek cat app_flutter/jureczek.sqlite`.
- `StandardPOIs` (styl 3D) ma getter `poi.maki`. W `poi-label` własnego stylu `maki` jest w `poi.properties['maki']`.

## Checklista weryfikacji
- [x] `flutter analyze`: 0 issues
- [x] `flutter test`: 191/191
- [x] P30 przez adb: migracja 6 → 7 na prawdziwej bazie. Przed: gastronomy 2, places 3, nature 1, activities 1, entertainment 1, standard (czarna) 1. Po: te same liczby jako `*_other`, a czarna zielona bez zmian. 9 pinezek (kopia w scratchpadzie sesji).
- [x] P30 przez adb: mapa „Wszystkie pinezki” – migrowane pinezki ze znakami „inne”.
- [x] P30 przez adb: wyszukiwarka → „Muzeum Narodowe w Krakowie” → formularz z „Muzeum · Miejsca i atrakcje” i otwartą siatką.
- [x] P30 przez adb: złoty kolor zmienia pinezki w wyborze; po „Zapisz” złota pinezka muzeum spada i ląduje czubkiem w punkcie; tap pokazuje zaznaczoną i arkusz „Muzeum · Miejsca i atrakcje”.
- [x] P30 przez adb: long-tap na POI „Teatr Groteska” → „Teatr · Rozrywka i kultura”.
- [x] Pinezki testowe usunięte (w bazie znowu 9).
- [ ] Użytkownik: wygodę wyboru w dwóch krokach, wysokość formularza, symbole „inne”, trafność podpowiedzi `maki`.

## Otwarte
- Formularz z otwartą siatką jest wysoki (siatka + 24 kolory). Jeśli przeszkadza, można zwijać kolory (uwaga z v14).
- `poi_category_ids` z wyszukiwarki dałoby więcej trafień niż samo `maki` (np. `winery`, `brewery`), ale wymaga drugiej tabeli.
- Zielona „Pinezka” jest jedyna w PNG – mogłaby przejść na SVG, gdyby kiedyś trzeba było ją zmieniać.

Powiązane: [[00 Jureczek – przegląd]], [[ADR-012 Typ miejsca jako typ pinezki]], [[v15 – biblioteka ikon miejsc]], [[ADR-011 Biblioteka ikon miejsc w SVG]], [[ADR-010 Kolor pinezki z warstw]], [[Backlog]]
