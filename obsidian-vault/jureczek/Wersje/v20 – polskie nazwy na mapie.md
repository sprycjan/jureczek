---
tags: [jureczek, wersja, mapbox, lokalizacja]
wersja: v20
status: zaimplementowana – sprawdzona przez adb, czeka na potwierdzenie użytkownika
data: 2026-11-04
---
# v20 – polskie nazwy na mapie

Prośba użytkownika z 2026-11-04: nazwy rosyjskie były na mapie cyrylicą, a nazwy z krajów muzułmańskich pismem arabskim. Wszystkie mają być polskim alfabetem.

## Zakres
- **Język kafelków:** `MapboxMapsOptions.setLanguage('pl,en')`, czyli nazwa polska, a gdy jej nie ma, angielska (zwykle transliteracja).
- **Style Domyślny i Teren:** po wczytaniu stylu warstwy etykiet dostają dwie zmiany:
  - POI, drogi, przystanki i lotniska pokazują `name_local`, gdy jest łaciński, a w przeciwnym razie `name`.
  - Filtr ukrywa etykiety, których nazwy nie da się zapisać łacinką.
- **Karta POI i nazwa pinezki:** ta sama reguła co na etykiecie (`poiLabelName`).
- **Styl 3D (Standard):** działa tylko język kafelków, bo warstw z importu nie da się zmieniać.

## Decyzje
| # | Decyzja | Wybór |
|---|---|---|
| 1 | Skąd polskie nazwy | `language=pl,en` kafelków, bo Streets v8 nie ma pola `name_pl` |
| 2 | Tłumaczenia w krajach z łaciną | POI i drogi zostają w oryginale, miejscowości i państwa po polsku |
| 3 | Nazwa bez wersji łacińskiej | etykieta ukryta |
| 4 | Styl 3D | na razie bez zmian, decyzja użytkownika w [[Backlog]] |

Uzasadnienie i pomiary: [[ADR-014 Polskie nazwy na mapie]].

## Pliki
- `lib/features/map/presentation/map_labels.dart` (nowy): `mapLabelLanguage`, `isLatinText`, `poiLabelName`, `mapLabelPatches`.
- `lib/main.dart`: ustawienie języka przed pierwszą mapą.
- `lib/features/map/presentation/map_screen.dart`: `_applyLabelPatches` po wczytaniu stylu, przed zdjęciem zasłony; nazwa POI przez `poiLabelName`.
- `lib/features/map/presentation/map_style.dart`: `hasEditableLabels`.
- **Testy:** `test/features/map/presentation/map_labels_test.dart` (nowy, 12 testów).

## Pułapki
- Samo `pl,en` psuje nazwy łacińskie: „Pałac Biskupi” → „Episcopal Palace”, „Unter den Linden” → „Under the Lindens”.
- `slice` poza końcem nazwy daje pusty napis, a pusty napis jest mniejszy od U+0000. Warunek `>= "\u0000"` ukrył wszystkie nazwy krótsze niż 24 znaki. Pierwszy zakres nie ma więc dolnej granicy.
- Po przełączeniu na Standard `getStyleJSON` zwrócił warstwy poprzedniego stylu i poprawki kończyły się błędem `Layer ... is not in style`. Dlatego Standard jest pomijany.
- Półpauza i cudzysłowy leżą poza łaciną Unicode (U+2000+), więc są osobnym zakresem. Inaczej „Keshavarz – Park Laleh” byłoby ukryte.

## Checklista weryfikacji
- [x] `flutter analyze`: 0 issues
- [x] `flutter test`: 244/244
- [x] P30 przez adb, Europa: Paryż, Londyn, Sztokholm, Niemcy, Włochy.
- [x] P30 przez adb, Moskwa (Domyślny): Kreml moskiewski, Wielki Pałac Kremlowski, Bolshaya Nikolskaya St, bez cyrylicy.
- [x] P30 przez adb, Moskwa (Teren): bez cyrylicy.
- [x] P30 przez adb, Kair (Domyślny): Muzeum Egipskie, Al Tahrir St, bez pisma arabskiego; także po przełączeniu Teren → Domyślny.
- [x] P30 przez adb, Kraków (Domyślny): Pałac Biskupi, Kościół pw. Świętego Marka, bez angielskich tłumaczeń.
- [x] P30 przez adb, Moskwa (3D) przed dodaniem `hasEditableLabels`: **cyrylica zostaje**, np. „Манежная площадь”.
- [x] Poprawki są szybkie: 646 ms przy pierwszym stylu, 286 ms dla 20 warstw Outdoors.
- [ ] 3D po dodaniu `hasEditableLabels`: brak błędu w logu (nie powtórzono testu).
- [ ] Tapnięcie w POI na telefonie: nazwa na karcie jak na etykiecie (tylko testy logiki).
- [ ] Użytkownik: gęstość etykiet w Rosji, na Ukrainie i w Iranie po ukryciu nazw bez łacinki.

## Otwarte
- Styl 3D nadal pokazuje cyrylicę, a polskie POI bywają tam po angielsku. Wpis w [[Backlog]].
- Część nazw jest po angielsku, nie po polsku („Alexander Garden”), bo Mapbox nie ma polskiego tłumaczenia.
- W krajach łacińskich POI i ulice nie dostają polskich egzonimów: „Václavské náměstí” zamiast „Plac Wacława”.
- Teheran traci dużo etykiet: 71% ulic i 52% POI nie ma nazwy łacińskiej. W Moskwie to 28% ulic i 46% POI.
- Sprawdzanych jest 24 pierwsze znaki nazwy, więc obcy alfabet dalej w długiej nazwie przejdzie filtr.
- Adresy w wynikach wyszukiwarki bywają częściowo po arabsku („31, ناصر”). To dane Search Box, a nie etykiety mapy.
- Nowe POI z mapy zapisują `poi_name` w wersji z etykiety, więc odnośnik do Google Maps może szukać po tłumaczeniu ([[v19 – odnośnik do Google Maps]]). Nie sprawdzono trafności.

Powiązane: [[00 Jureczek – przegląd]], [[ADR-014 Polskie nazwy na mapie]], [[ADR-008 Własny klasyczny styl mapy]], [[v13 – przełącznik stylów mapy]], [[v19 – odnośnik do Google Maps]], [[Mapbox Flutter]], [[Backlog]]
