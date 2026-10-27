---
tags: [jureczek, wersja, mapbox]
wersja: v6
status: zaimplementowana – sprawdzona na telefonie przez adb, czeka na potwierdzenie
data: 2026-10-27
---
# v6 – klikalne POI

## Zakres
- POI ze stylu Mapbox Standard (punkty widokowe, kąpieliska, szczyty, kawiarnie…) da się klikać.
- **Tap w POI** pokazuje tę samą kartę co wynik wyszukiwania: nazwa POI, „Dodaj pinezkę” (formularz z wpisaną nazwą), „Popraw położenie”. Gdy w pobliżu stoi już pinezka, otwiera się jej arkusz z komunikatem o duplikacie (jak w [[v4 – wyszukiwarka miejsc]]).
- **Long-tap w POI** od razu stawia pinezkę z nazwą POI we współrzędnych POI, a nie pod palcem.
- Long-tap w puste miejsce działa jak dotąd (pinezka bez nazwy).
- Nic nie kosztuje: dane pochodzą z kafelków mapy, bez zapytań do Search Box.

## Decyzje
| # | Decyzja | Wybór |
|---|---|---|
| 1 | Gest na POI | tap → karta wyniku; long-tap → pinezka od razu (spójne z long-tapem na mapie) |
| 2 | Karta dla POI | ponowne użycie `PlaceResult` + `SearchResultCard` + `_showResult(fly: false)`; bez przelotu, bo POI jest już na ekranie |
| 3 | Adres POI | brak (featureset `poi` go nie ma); bez reverse geocodingu, żeby nie wołać API |
| 4 | Pozycja pinezki | współrzędne POI z `geometry`, nie punkt dotyku |

## Pliki
- `app/lib/features/map/domain/poi_place.dart`: nowy, `placeFromPoi(name, geometry)` czyta `[lng, lat]` z GeoJSON-a
- `app/lib/features/map/presentation/map_screen.dart`: `TapInteraction(StandardPOIs(), …)` i `LongTapInteraction(StandardPOIs(), …)` w `_onMapCreated`
- `app/test/features/map/poi_place_test.dart`: nowy, 3 testy

## Pułapki
- **Błąd w pluginie 3.33:** getter `StandardPOIsFeature.coordinate` robi `geometry["coordinates"] as Point?`, a to jest lista `[lng, lat]`, więc rzuca `TypeError`. Pigeon połyka wyjątek z handlera po cichu, a natywna interakcja i tak zatrzymuje propagację. Efekt: tap w POI „nic nie robi”, bez żadnego logu. Obejście: czytać `poi.geometry['coordinates']`. Szczegóły w [[Mapbox Flutter]].
- Diagnostyka, która to znalazła: `debugPrint` w `TapInteraction.onMap` dochodził tylko z pustego morza, a z POI nie. Zatem POI łapała interakcja na featuresecie, a handler padał.

## Checklista weryfikacji
- [x] `flutter analyze`: 0 issues
- [x] `flutter test`: 120/120
- [x] Telefon przez adb (Claude, screenshoty): tap w POI kąpieliska → karta z nazwą, znacznik na ikonie POI
- [x] Telefon przez adb: long-tap w ikonę szczytu → jedna pinezka dokładnie na ikonie (POI bez nazwy → „Bez nazwy”)
- [x] Telefon przez adb: tap w pinezkę stojącą na POI → jeden arkusz (jedno „wstecz” zamyka)
- [ ] Użytkownik: Miradouro do Pico da Caldeira – tap i long-tap

## Poprawki po teście
- Pierwsza wersja używała `poi.coordinate` i na telefonie nic się nie działo (zgłoszenie użytkownika). Poprawione na odczyt z `geometry`.

## Otwarte
- Ikona POI zostaje widoczna pod pinezką. Można ją chować przez `StandardPOIsState(hide: true)` i `setFeatureState` – [[Backlog]].

Powiązane: [[00 Jureczek – przegląd]], [[v5 – kompas i skala]], [[v4 – wyszukiwarka miejsc]], [[Mapbox Flutter]]
