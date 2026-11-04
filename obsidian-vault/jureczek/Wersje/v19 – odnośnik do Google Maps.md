---
tags: [jureczek, wersja, pinezki, google-maps, drift]
wersja: v19
status: zaimplementowana – sprawdzona przez adb, czeka na potwierdzenie użytkownika
data: 2026-11-04
---
# v19 – odnośnik do Google Maps

Prośba użytkownika z 2026-11-04: w arkuszu postawionej pinezki ma być odnośnik, który otworzy dokładnie tę lokalizację albo POI w Mapach Google. Wcześniej przycisk miały tylko pinezki udostępnione z innej aplikacji. Plan doprecyzowany z użytkownikiem (grill-plan).

## Zakres
- **Przycisk:** „Otwórz w Google Maps” jest w arkuszu każdej pinezki, w tym samym miejscu co dotąd.
- **Co otwiera, w tej kolejności:**
  1. oryginalny link Google (`sourceUrl`),
  2. wyszukanie `poi_name` + aktualny adres pinezki, wokół jej współrzędnych,
  3. same współrzędne.
- **`poi_name`:** nowa kolumna (schemat 8) z oryginalną nazwą POI. Ustawiają ją POI kliknięte na mapie i wynik wyszukiwarki z `feature_type == 'poi'`. Zmiana nazwy pinezki jej nie rusza.
- **Adres POI z mapy:** pobierany w tle przy otwarciu formularza nowej pinezki (reverse geocoding, limit 3 s). Trafia do pustego pola, „Zapisz” na niego czeka, a po zapisie jest w pinezce, więc nie jest pobierany ponownie.
- **Błąd otwarcia:** krótki komunikat w arkuszu, bo snackbar byłby pod nim niewidoczny.
- **Bez zmian:** manifest (`launchUrl` nie wymaga `<queries>`), istniejące pinezki (dostają pustą kolumnę i otwierają współrzędne, chyba że mają link Google).

## Decyzje
| # | Decyzja | Wybór |
|---|---|---|
| 1 | Które pinezki | wszystkie; link Google ma pierwszeństwo |
| 2 | Pinezka bez linku Google | jeden odnośnik, automatycznie: POI albo współrzędne |
| 3 | Błąd otwarcia | komunikat w arkuszu |
| 4 | Pinezki z własną nazwą | osobna kolumna odróżnia POI; własna nazwa nigdy nie trafia do wyszukiwania |
| 5 | Co zapisać | oryginalną nazwę POI, nie znacznik tak/nie |
| 6 | Istniejące pinezki | zwykłe dodanie kolumny, bez kasowania |
| 7 | Adres POI z mapy | pobrany raz przy dodawaniu i zapisany z pinezką (uściślenie użytkownika) |
| 8 | POI bez adresu | same współrzędne, nie sama nazwa |

Uzasadnienie: [[ADR-013 Odnośnik do Google Maps bez place_id]].

## Test formatów linku
P30 w Gdańsku, Google Maps z aplikacji:

| Format | Wynik |
|---|---|
| `search/?api=1&query=nazwa lat,lng` | współrzędne traktowane jak tekst, wyniki koło użytkownika |
| `search/<nazwa>/@lat,lng,17z` | działa dla „Café Camelot”, ale „Bazylika Wniebowzięcia NMP” z Krakowa pokazuje Gdańsk |
| `geo:lat,lng?q=nazwa`, `maps?q=nazwa&ll=lat,lng` | jak wyżej, Gdańsk |
| `search/?api=1&query=nazwa near lat,lng` | karta bazyliki w Gdańsku |
| `place/<nazwa>/@lat,lng,17z` | ekran startowy Map |
| `search/<nazwa, miasto>/@lat,lng,17z` | właściwa okolica, lista z reklamami |
| **`search/<nazwa, pełny adres>/@lat,lng,17z`** | **od razu karta właściwego miejsca** |
| `search/?api=1&query=lat,lng` | dokładny znacznik (wariant dla współrzędnych) |

## Pliki
- `lib/features/map/domain/google_maps_link.dart` (nowy): `googleMapsUri(PlacePin)` z kolejnością wariantów.
- `lib/features/map/data/pins_table.dart`, `lib/core/database/app_database.dart`: kolumna `poi_name`, schemat 8, migracja.
- `lib/features/map/domain/place_pin.dart`, `place_suggestion.dart`, `poi_place.dart`: pole `poiName`.
- `lib/features/map/data/place_search_client.dart`, `pins_repository.dart`, `application/pins_providers.dart`: ustawianie i zapis `poiName`.
- `lib/features/map/presentation/new_pin_sheet.dart`: parametr `addressLookup`.
- `lib/features/map/presentation/map_screen.dart`: `_lookupAddress`, przekazanie adresu i `poiName`.
- `lib/features/map/presentation/pin_details_sheet.dart`: przycisk zawsze, `_openInGoogleMaps`, komunikat błędu.
- `lib/l10n/app_pl.arb`: `pinOpenInMapsError`.
- `pubspec.yaml`: `plugin_platform_interface` i `url_launcher_platform_interface` w `dev_dependencies` (atrapa w testach).
- **Testy:** `google_maps_link_test.dart` (nowy), `pin_details_sheet_test.dart`, `new_pin_sheet_test.dart`, `pins_controller_test.dart`, `poi_place_test.dart`, `place_search_client_test.dart`, `app_database_migration_test.dart`.

## Pułapki
- `_addFolders` przebudowuje `pins` do bieżącego schematu, ale kopiuje stare kolumny. Każda nowa kolumna musi być w `newColumns` i `columnTransformer`, a `addColumn` może działać tylko poza gałęzią `from < 5`. Pokazały to testy migracji 4 → 5.
- Mała próbka zmyliła: format z samą nazwą przeszedł na trzech miejscach, a zawiódł na bazylice. Nazwy pasujące do wielu miejsc trzeba testować z telefonem daleko od pinezki.
- Tap w mapę zamyka listę podpowiedzi i zostawia tekst w polu, więc tap przed wczytaniem listy wygląda jak zepsuty wybór.

## Checklista weryfikacji
- [x] `flutter analyze`: 0 issues
- [x] `flutter test`: 232/232
- [x] P30 przez adb: migracja ze schematu 7 zachowuje foldery i 9 pinezek.
- [x] P30 przez adb: stara pinezka bez linku otwiera dokładny znacznik.
- [x] P30 przez adb: POI z wyszukiwarki (Sukiennice) otwiera kartę właściwego miejsca, także po zmianie nazwy na „Obiad”.
- [x] P30 przez adb: POI z mapy pobiera adres do formularza i zapisuje go; Bazylika Nawiedzenia NMP i Bazylika Mariacka otwierają właściwe karty w Krakowie.
- [x] P30 przez adb: adres z wyszukiwarki (Karmelicka 10) otwiera współrzędne, nie kartę.
- [x] P30 przez adb: pinezka z testowego linku `maps/place` otwiera Google Maps. Link był zmyślony, więc Google pokazał ekran startowy.
- [x] Pinezki testowe usunięte; foldery mają znów 5 i 4 miejsca. Test zmienił kolejność folderów (ostatnio używany na górze).
- [ ] Pinezka udostępniona z Google Maps z prawdziwym linkiem `maps.app.goo.gl` (adb nie ma takiego linku).
- [ ] Komunikat błędu na telefonie: tylko test widgetu, bo na P30 otwarcie linku zawsze się udawało.
- [ ] POI z mapy bez sieci: adres pusty i otwarcie współrzędnych (sprawdzone tylko testami logiki).
- [ ] Długie tapnięcie w POI i w pusty punkt mapy z nowym odnośnikiem (ta sama ścieżka co tap w POI i stara pinezka).
- [ ] Użytkownik: trafność na własnych miejscach.

## Otwarte
- Wybór widocznej podpowiedzi dwa razy z rzędu zamknął listę bez wyniku, po powrocie do aplikacji przez `am start` w sesji `--no-resident`, więc bez logów Fluttera. Późniejsze próby w zwykłej sesji i po powrocie przez „wstecz” działały. Przyczyna nieznana; v19 nie zmienia logiki wyboru. Wpis w [[Backlog]].
- Adres z reverse geocodingu to najbliższy adres, nie zawsze adres POI. Na obu bazylikach wystarczył, ale może się zdarzyć gorsze trafienie.

Powiązane: [[00 Jureczek – przegląd]], [[ADR-013 Odnośnik do Google Maps bez place_id]], [[v18 – filtr kategorii pinezek]], [[v6 – klikalne POI]], [[v4 – wyszukiwarka miejsc]], [[Mapbox Flutter]], [[Backlog]]
