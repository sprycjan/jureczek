---
tags: [jureczek, wersja, mapbox, styl, lokalizacja]
wersja: v14
status: zaimplementowana – sprawdzona przez adb, czeka na potwierdzenie użytkownika
data: 2026-11-02
---
# v14 – lokalizacja, ikony POI i kolor pinezki

Pięć pozycji z [[Backlog]] naraz (prośba użytkownika z 2026-11-02): „moja lokalizacja”, ikony POI, mniej etykiet miejscowości, snackbary po wyjściu z mapy, własny kolor pinezki (plan z [[v11 – poprawki wyglądu]]).

## Zakres
- **Moja lokalizacja:** okrągły przycisk (ikona celownika) pod pigułką + / − przy prawej krawędzi. Tap: sprawdza, czy lokalizacja w telefonie jest włączona, pyta o zgodę (tylko tu, nie przy starcie), pokazuje niebieską kropkę Mapbox (pulsowanie, pierścień dokładności) i przelatuje do położenia (zoom co najmniej 14, bliższy zostaje). Gdy zgoda była już dana wcześniej, kropka pojawia się od razu po wejściu na mapę.
  | Sytuacja | Komunikat (snackbar) | Akcja |
  |---|---|---|
  | lokalizacja wyłączona | „Lokalizacja w telefonie jest wyłączona” | „Włącz” → ustawienia lokalizacji |
  | odmowa | „Bez zgody na lokalizację nie pokażę, gdzie jesteś” | – (następny tap zapyta znowu) |
  | odmowa na stałe | „Dostęp do lokalizacji jest zablokowany – włącz go w ustawieniach aplikacji” | „Ustawienia” → ustawienia aplikacji |
  | brak pozycji (15 s) | „Nie udało się ustalić położenia” | – |
- **Ikony POI:** styl ma sprite `mapbox://sprites/mapbox/dark-v11`, a `poi-label` rysuje ikonę `maki` (zapas: `marker`) z nazwą pod spodem. Szare ikony nie konkurują z kolorowymi pinezkami.
- **Mniej etykiet miejscowości:** filtry po `symbolrank` zależne od zoomu i `symbol-sort-key: symbolrank` (ważniejsze wygrywają kolizje).
  | Warstwa | do z5 | z5–7 | z7–9 | z9–11 | od z11 |
  |---|---|---|---|---|---|
  | `place-label-city` | ≤ 9 | ≤ 11 | wszystkie | wszystkie | wszystkie |
  | `place-label-town` | ≤ 12, bez dzielnic | ≤ 12 | ≤ 14 | ≤ 16 | wszystkie z dzielnicami |
  Przykładowe `symbolrank`: Warszawa 7, Kraków 8, Poznań 9, Tarnów 11, Myślenice 13, dzielnice 12–18.
- **Snackbary:** mapa ma własny `ScaffoldMessenger` (w trasie z ekranu startowego), więc „Dodano pinezkę” / „Cofnij” znikają razem z mapą.
- **Kolor pinezki:** w formularzu nowej pinezki i w edycji, pod wyborem typu: „Kolor” + nazwa (albo „Kolor typu”), siatka 6×4 kółek, przycisk „Domyślny” wraca do koloru typu. Rząd typów od razu pokazuje pinezki w wybranym kolorze. Na mapie, w spadaniu i w nagłówku arkusza pinezka ma swój kolor.
  24 kolory (klucz → nazwa): red Czerwony, raspberry Malinowy, rose Różowy, coral Koralowy, orange Pomarańczowy, amber Bursztynowy, gold Złoty, olive Oliwkowy, lime Limonkowy, green Zielony, mint Miętowy, teal Morski, cyan Turkusowy, sky Błękitny, blue Niebieski, navy Granatowy, violet Fioletowy, purple Purpurowy, orchid Liliowy, brown Brązowy, sand Piaskowy, slate Łupkowy, graphite Grafitowy, black Czarny. Wszystkie 8 kolorów kategorii jest wśród nich.

## Decyzje
| # | Decyzja | Wybór |
|---|---|---|
| 1 | Pozycja i zgoda | `geolocator` (zgoda + pozycja) + kropka Mapbox (`location.updateSettings`) – [[ADR-009 Lokalizacja przez geolocator]] |
| 2 | Kiedy pytać o zgodę | dopiero po tapnięciu przycisku |
| 3 | Która pozycja | ostatnia znana, jeśli młodsza niż 2 min; inaczej bieżąca (do 15 s); bez sygnału – jednak stara ostatnia znana |
| 4 | Przycisk | pod + / −, nie w kolumnie u góry (kompas zostaje, gdzie był) |
| 5 | Sprite POI | `dark-v11` (szare, monochromatyczne) zamiast kolorowych kółek `streets-v12`/`outdoors-v12` |
| 6 | Snackbary | `ScaffoldMessenger` w trasie mapy zamiast czyszczenia przy wyjściu |
| 7 | Rysowanie kolorowych pinezek | warstwy z `render_pins.py` barwione w aplikacji – [[ADR-010 Kolor pinezki z warstw]] |
| 8 | Kolor bez wyboru | `null` = kolor typu, gotowy PNG bez zmian |
| 9 | Kolor a typ w bazie | zapisywane razem (wygląd); `updateDetails` z typem zawsze zapisuje też kolor |

## Zależności
- `geolocator: ^14.1.2` (dev: `geolocator_platform_interface` do testów).
- `AndroidManifest.xml` (main): `ACCESS_FINE_LOCATION`, `ACCESS_COARSE_LOCATION`.

## Pliki
- `app/lib/core/location/user_location.dart`: `UserLocationService` (`hasPermission`, `locate`, ustawienia), wyniki `UserLocation*` (nowy)
- `app/lib/features/map/presentation/map_screen.dart`: `_goToMyLocation`, `_showUserPuck`, przycisk pod zoomem, `_showError(action:)`; wygląd pinezki `(typ, zaznaczona, kolor)`, `_pinImage`/`_dropImage` składane na żądanie
- `app/lib/features/home/presentation/home_screen.dart`: `ScaffoldMessenger` wokół `MapScreen`
- `app/assets/map/vanventure_dark.json`: `sprite`, ikony w `poi-label`, filtry `symbolrank` i `symbol-sort-key` w etykietach miejscowości
- `app/lib/features/map/domain/pin_color.dart`: enum `PinColor` (nowy)
- `app/lib/features/map/presentation/pin_image.dart`: `PinLayer`, `renderPinPng`, widżet `PinImage` (nowy)
- `app/lib/features/map/presentation/pin_color_picker.dart`: `PinColorPicker`, nazwy kolorów (nowy)
- `app/lib/features/map/presentation/pin_category_picker.dart`: podgląd w kolorze, `PinCategoryImage` → `PinImage`, nazwa typu z wielokropkiem
- `new_pin_sheet.dart`, `pin_details_sheet.dart`, `pin_form_fields.dart` (`PinDetailsInput.color`)
- Baza: `pins_table.dart` (kolumna `color`), `app_database.dart` (schemat 6), `pins_repository.dart`, `pins_providers.dart`, `place_pin.dart`
- `app/tool/render_pins.py`: warstwy `tint/<nazwa>_body|overlay|accent.png`; `app/assets/markers/tint/` (34 PNG, nowe); `pubspec.yaml`
- `app/lib/l10n/app_pl.arb`: lokalizacja, kolory
- Testy: `test/core/location/user_location_test.dart` (nowy), `test/features/map/pin_image_test.dart` (nowy), migracja 5 → 6, repozytorium (kolor), arkusze (kolor), `home_screen_test` (snackbar po powrocie)

## Pułapki
- **Migracja 4 → 5 a nowa kolumna:** `TableMigration` przebudowuje tabelę wg **bieżącego** schematu, więc po dodaniu `color` migracja 4 → 5 też musi ją znać (`newColumns: [folderId, color]`), a `addColumn` tylko dla `from == 5`. Każda nowa kolumna `pins` wymaga tego samego.
- `ColorFilter.mode(kolor, BlendMode.modulate)` na białym korpusie daje dokładnie kolor; czarny cień zostaje czarny. Biała obwódka zaznaczenia musi być w nakładce, bo w korpusie też by się zabarwiła.
- Test `pin_image_test` składa warstwy w kolorze z SVG i porównuje z gotowym PNG (średnia różnica kanału < 2) – pilnuje, że skrypt i aplikacja są zgodne.
- `render_pins.py` trwa ok. 4 min (ok. 50 uruchomień Chrome). Gotowe PNG wychodzą bajt w bajt takie same.
- Arkusz z kolorem jest wyższy niż ekran testowy 800×600 – testy arkuszy ustawiają ekran P30 i `ensureVisible('Zapisz')`. Czcionka testowa ma szerokie znaki, stąd `Expanded` + wielokropek w rzędach z etykietami.
- Snackbar z akcją potrzebuje `persist: false` (Flutter 3.41) – `_showError` ustawia to sam.
- adb: „Wstecz” na ekranie startowym zamyka aplikację; długie przytrzymanie trafia wtedy w pulpit telefonu (tryb edycji).

## Checklista weryfikacji
- [x] `flutter analyze`: 0 issues
- [x] `flutter test`: 187/187
- [x] P30 przez adb: migracja 5 → 6 na prawdziwej bazie – 9 pinezek zostało (kopia przed instalacją w scratchpadzie sesji)
- [x] P30 przez adb: Europa – tylko większe miasta
- [x] P30 przez adb: lokalizacja – pytanie systemu, „Odmów” → komunikat, „Odmów i nie pytaj ponownie” → komunikat z „Ustawienia”, zgoda → niebieska kropka i przelot (Gdańsk)
- [x] P30 przez adb: ikony POI (cmentarz, sklepy, szkoła, punkt widokowy) nad nazwami
- [x] P30 przez adb: snackbar mapy nie został na ekranie startowym
- [x] P30 przez adb: złota pinezka „Gastronomia” – podgląd w formularzu, spadanie, wersja zaznaczona, arkusz; w bazie `gold` (pinezka testowa usunięta)
- [ ] P30: przycisk „Ustawienia” / „Włącz” otwiera ustawienia (snackbar zniknął przed tapnięciem przez adb)
- [ ] Użytkownik: ogólna ocena, paleta i nazwy kolorów, gęstość etykiet, wygląd ikon POI

## Poprawki po teście
- Czarne i grafitowe kółko ginęło na ciemnym tle – każde kółko ma cienką obwódkę `outlineVariant`. Sprawdzone przez adb.

## Otwarte
- Arkusz nowej pinezki z wyborem folderu jest prawie na cały ekran – jeśli przeszkadza, siatkę kolorów można zwijać.
- Pigułka zoomu i przycisk lokalizacji zasłaniają pinezki przy prawej krawędzi.

Powiązane: [[00 Jureczek – przegląd]], [[v13 – przełącznik stylów mapy]], [[v12 – własny styl mapy]], [[v11 – poprawki wyglądu]], [[v9 – kategorie pinezek]], [[ADR-009 Lokalizacja przez geolocator]], [[ADR-010 Kolor pinezki z warstw]], [[Mapbox Flutter]], [[Backlog]]
