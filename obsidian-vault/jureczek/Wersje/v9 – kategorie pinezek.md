---
tags: [jureczek, wersja, mapbox, pinezki, drift]
wersja: v9
status: zaimplementowana – sprawdzona przez adb, czeka na potwierdzenie użytkownika
data: 2026-11-01
---
# v9 – kategorie pinezek

## Zakres
- 8 typów pinezek zamiast czerwonej: **domyślna zielona** (`resorces/default_pin`) i 7 kategorii ze Stitch: gastronomia, miejsca i zabytki, natura i widoki, aktywności i szlaki, podróż i baza vana, rozrywka i kultura, punkty praktyczne.
- Wariant **zaznaczony** (biała obwódka, większy, mocniejszy cień), gdy otwarty jest arkusz pinezki.
- Long-tap na mapie i na POI **zawsze otwiera formularz** „Nowa pinezka” z wyborem typu; pinezka spada po „Zapisz” (animacja z [[v7 – animacja spadania pinezki]] bez zmian, spada od razu wybrany typ).
- Typ widać w arkuszu pinezki i można go zmienić w edycji.
- **Reset bazy**: aktualizacja ze schematu < 4 kasuje dane (decyzja użytkownika – start od pustej bazy).

## Decyzje
| # | Decyzja | Wybór |
|---|---|---|
| 1 | Pinezka domyślna | `default_pin` jako 8. typ (`standard`), „Punkty praktyczne” zostają kategorią |
| 2 | Selected dla domyślnej | wygenerowany wg specyfikacji (obwódka 2.8 przeliczona ×48/36, cień selected) |
| 3 | Kiedy „selected” | tylko przy otwartym arkuszu pinezki |
| 4 | Long-tap | zawsze formularz z wyborem typu (też na POI, z nazwą POI) |
| 5 | Rozmiar | korpus 36 dp (selected 42 dp) wg specyfikacji |
| 6 | SVG → PNG | Chrome headless (`app/tool/render_pins.py`), bo `flutter_svg` nie obsługuje `feDropShadow`; PNG 3x przycięte tak, że czubek leży na dolnej krawędzi (kotwica `BOTTOM` bez offsetu) |
| 7 | Baza | schemat 4: kolumna `category` (text, domyślnie `standard`), `from < 4` → drop + `createAll`; stare migracje i ich testy usunięte |

## Pliki
- `app/assets/markers/{typ}_{default|selected}.png` (16), źródła `app/assets/markers/src/*.svg`, generator `app/tool/render_pins.py`; usunięty `pin.png`
- `app/lib/features/map/domain/pin_category.dart`: nowy – enum `PinCategory` (klucz w bazie, `asset()`, `fromKey` z fallbackiem), `pinImageScale`
- `app/lib/features/map/data/pins_table.dart`, `app/lib/core/database/app_database.dart`: `category`, schemat 4, reset
- `place_pin.dart`, `pins_repository.dart`, `pins_providers.dart`: typ w zapisie i `updateDetails`
- `app/lib/features/map/presentation/pin_category_picker.dart`: nowy – `PinCategoryPicker`, `PinCategoryImage`, etykiety
- `new_pin_sheet.dart`, `pin_details_sheet.dart`, `pin_form_fields.dart` (`PinDetailsInput.category`)
- `map_screen.dart`: obrazki per wygląd (`_PinLook` = typ × zaznaczenie) jako wspólne obrazy stylu (`iconImage` id), `iconSize = dpr / 3`, podmiana obrazka przy zmianie typu/zaznaczenia, `_selectPin`, long-tap → `_addResultPin`, spadająca nakładka z obrazkiem typu
- `app/lib/l10n/app_pl.arb`: nazwy typów
- Testy: migracja 3 → 4 (reset), repozytorium (typ, nieznany klucz), kontroler, `new_pin_sheet_test`, `pin_details_sheet_test`

## Pułapki
- `PointAnnotationOptions(image:, iconImage: 'id')`: z `iconImage` plugin dodaje obraz do stylu raz i współdzieli go; bez niego każda adnotacja ma własną bitmapę. Podmiana: `annotation..image = bytes..iconImage = id` + `manager.update`.
- Mapbox rysuje obrazek w pikselach fizycznych → przy PNG 3x `iconSize = devicePixelRatio / 3`; nakładka spadania ma rozmiar PNG / 3 w dp.
- Zrzut zaraz po „Zapisz” łapie pinezkę w locie (80 px wyżej) – nie mylić z błędem kotwicy.

## Checklista weryfikacji
- [x] `flutter analyze`: 0 issues
- [x] `flutter test`: 131/131
- [x] P30 przez adb: po instalacji baza pusta (stare pinezki zniknęły)
- [x] P30 przez adb: long-tap → formularz z 8 typami → „Gastronomia” → pinezka spada i ląduje czubkiem w punkcie long-tapu
- [x] P30 przez adb: tap w pinezkę → wariant zaznaczony + typ w arkuszu
- [ ] Użytkownik: wygląd i rozmiar pinezek, zmiana typu w edycji, long-tap na POI

## Otwarte
- Foldery – [[00 Jureczek – przegląd]] (v10).

Powiązane: [[00 Jureczek – przegląd]], [[v8 – styl Nocturnal Expedition]], [[v7 – animacja spadania pinezki]], [[ADR-005 Drift jako baza lokalna]], [[Mapbox Flutter]]
