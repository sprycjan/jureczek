---
tags: [jureczek, wersja, pinezki, baza, mapbox]
wersja: v22
status: zaimplementowana – sprawdzona przez adb, czeka na potwierdzenie użytkownika
data: 2026-11-04
---
# v22 – pinezka z gwiazdką

Prośba użytkownika z 2026-11-04: obok kciuka z [[v21 – pinezka odwiedzona]] ma być gwiazdka, która oznacza miejsce o wyższym priorytecie, czyli główny punkt wycieczki. Można ją ustawić też w formularzu dodawania. Gdy pinezka ma kilka ikonek, stoją obok niej jedna pod drugą, w jednej kolumnie.

## Zakres
- **Arkusz pinezki:** układ `[typ] … ⭐ 👍`. Kontur oznacza brak, złote wypełnienie oznaczenie. Tapnięcie zapisuje od razu.
- **Formularz nowej pinezki:** gwiazdka na końcu wiersza z nagłówkiem, zapis dopiero po „Zapisz”.
- **Mapa:** złota pięcioramienna gwiazdka na ciemnym kółku z białą obwódką. Kolumna przy prawym skraju główki, gwiazdka nad kciukiem, odstęp 1 dp.
- **Kolejność rysowania:** od góry zaznaczona, z gwiazdką, pozostałe. W tej samej grupie południowe przykrywają północne.
- **Baza:** kolumna `starred` (schemat 10).

## Decyzje
| # | Decyzja | Wybór |
|---|---|---|
| 1 | Położenie kolumny | prawy skraj główki, styka się z pinezką, nie zasłania symbolu |
| 2 | Kolejność znaczków | gwiazdka na górze; pojedynczy znaczek na górnym miejscu |
| 3 | Wygląd | złota pięcioramienna gwiazdka na ciemnym kółku z białą obwódką |
| 4 | Liczba gwiazdek | dowolna w folderze |
| 5 | Zapis | tak/nie, bez daty |
| 6 | Arkusz | ikonka przed kciukiem, zachowanie jak kciuk, tylko w podglądzie |
| 7 | Kolejność folderów | gwiazdka podnosi folder na górę, jak kciuk |
| 8 | Zakres | rysowanie nad innymi teraz; filtr i wyróżnienie na folderze w [[Backlog]] |
| 9 | Formularz nowej pinezki | ikonka w wierszu nagłówka, zapis po „Zapisz”, „Anuluj” ją porzuca |
| 10 | Formularz edycji | bez gwiazdki |
| 11 | Animacja spadania | pinezka spada już z gwiazdką |
| 12 | Kciuk w formularzu nowej pinezki | nie |
| 13 | Nakładanie | jawnie włączone (`iconAllowOverlap`, `iconIgnorePlacement`), żadna pinezka się nie chowa |
| 14 | Kolejność rysowania | zaznaczona > z gwiazdką > pozostałe |

## Pliki
- `lib/features/map/data/pins_table.dart`, `lib/core/database/app_database.dart`: kolumna `starred`, schemat 10, migracja.
- `lib/features/map/domain/place_pin.dart`: pole `starred`.
- `lib/features/map/domain/pin_sort_key.dart`: nowy, `pinSortKey`.
- `lib/features/map/data/pins_repository.dart`, `lib/features/map/application/pins_providers.dart`: `setStarred`, zapis w `insert` i `add`.
- `lib/features/map/presentation/pin_image.dart`: `PinMark`, `pinStarColor`, `pinBadges`, `pinBadgeFramePadding` zamiast `visitedBadge`.
- `lib/features/map/presentation/map_screen.dart`: `_PinLook` jako rekord nazwany, nakładanie, `symbolSortKey`, `_setPinStarred`, obrazek spadania z gwiazdką.
- `lib/features/map/presentation/pin_form_fields.dart`: `PinStarButton`, pole `starred` w `PinDetailsInput`.
- `lib/features/map/presentation/pin_details_sheet.dart`, `new_pin_sheet.dart`: przełącznik gwiazdki.
- `lib/l10n/app_pl.arb`: `pinMarkStarred`, `pinUnmarkStarred`.
- **Testy:** migracja 9 → 10, repozytorium, kontroler, arkusz, formularz, klucz sortowania, obraz pinezki (znaczki oraz symbol wszystkich 81 typów niezasłonięty).

## Pułapki
- Zaznaczona pinezka typu ma symbol tak blisko skraju, że znaczek zasłaniał kilka pikseli w `waterfall`, `campingGround` i `festivalEvent`. Dlatego kolumna stoi o 1 dp dalej, a ramka tego wariantu jest szersza o 1 dp z każdej strony. Poszerzenie musi być symetryczne, bo kotwica `BOTTOM` to środek dolnej krawędzi.
- `symbolSortKey` wyłącza układanie według pozycji na ekranie, więc klucz zawiera `-lat`. Po obróceniu mapy kolejność w grupie nie musi już zgadzać się z ekranem.
- Przy wyłączonym nakładaniu niższy klucz wygrywa miejsce, a przy włączonym wyższy rysuje się na wierzchu. Bez jawnego włączenia wysoki klucz mógłby chować gwiazdkę. Zob. [[Mapbox Flutter]].
- Tapnięcie obejmuje całą ramkę obrazka z przezroczystym marginesem. Tuż obok pinezki z gwiazdką tap może więc otworzyć ją, a nie sąsiednią, nawet jeśli palec nie trafił w jej rysunek.
- W testach czcionka ikon nie jest załadowana, więc znaczki nie mają symbolu. `pin_image_test` ładuje `MaterialIcons` w `setUpAll`.
- `updateDetails` zapisuje `null` w pominiętych polach tekstowych, więc gwiazdka ma osobną metodę, jak kciuk. Zapis edycji pomija pole `starred`.

## Checklista weryfikacji
- [x] `flutter analyze`: 0 issues
- [x] `flutter test`: 290/290
- [x] P30 przez adb: migracja na istniejącej bazie, schemat 10, wszystkie 11 pinezek i 2 odwiedzone zachowane, 0 gwiazdek.
- [x] P30 przez adb: gwiazdka i kciuk w kolumnie na zaznaczonej i zwykłej pinezce typu; sama gwiazdka na zaznaczonej i zwykłej zielonej w kolorze.
- [x] P30 przez adb: gwiazdka w formularzu nowej pinezki, zapis w bazie, spadanie z gwiazdką bez przeskoku.
- [x] P30 przez adb: pinezka z gwiazdką rysuje się nad zwykłą leżącą na południe od niej, tap w miejsce nakładania otwiera pinezkę z gwiazdką.
- [x] P30 przez adb: zaznaczona zwykła pinezka wychodzi nad pinezkę z gwiazdką.
- [x] P30 przez adb: zdjęcie gwiazdki usuwa znaczek od razu.
- [ ] Stan po ponownym uruchomieniu aplikacji na telefonie (zapis pokryty testami repozytorium, a odczyt z bazy sprawdzony w pliku bazy).
- [ ] „Cofnij” po usunięciu pinezki z gwiazdką na telefonie (tylko test kontrolera).
- [ ] Błąd zapisu gwiazdki na telefonie (tylko test arkusza).
- [ ] Użytkownik: czytelność znaczków, także w stylach Teren i 3D.
- [ ] Użytkownik: czy po włączeniu nakładania mapa nie jest zbyt gęsta przy oddaleniu.

## Otwarte
- Domyślnej wartości `iconAllowOverlap` w SDK nie ustalono, a na telefonie nie porównywano gęstego widoku przed i po zmianie. W folderze Portugalia pinezki są daleko od siebie, a nakładanie sprawdzono tylko na dwóch testowych.
- Mapbox sortuje symbole w obrębie kafelka, więc pinezki na granicy kafelków mogą układać się inaczej. Nie sprawdzano tego.
- Po testach na telefonie usunięto dwie pinezki testowe i zdjęto gwiazdki. Baza: 11 pinezek, 0 gwiazdek, 2 odwiedzone, kolejność folderów bez zmian.

Powiązane: [[00 Jureczek – przegląd]], [[v21 – pinezka odwiedzona]], [[v16 – typy miejsc w pinezkach]], [[v18 – filtr kategorii pinezek]], [[Mapbox Flutter]], [[Backlog]]
