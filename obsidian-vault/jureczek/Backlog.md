---
tags: [jureczek, backlog]
---
# Backlog

Pomysły i świadomie odłożone rzeczy po [[v1 – mapa i pinezki]], [[v2 – trwałe pinezki i usuwanie]] i [[v3 – nazwa i notatka]], [[v4 – wyszukiwarka miejsc]], [[v5 – kompas i skala]], [[v6 – klikalne POI]], [[v7 – animacja spadania pinezki]], [[v8 – styl Nocturnal Expedition]], [[v9 – kategorie pinezek]], [[v10 – foldery i ekran startowy]], [[v11 – poprawki wyglądu]], [[v12 – własny styl mapy]].

## Miejsca / pinezki
- [x] Trwałość: drift/SQLite za repozytorium (v2, [[ADR-005 Drift jako baza lokalna]])
- [x] Nazwa i notatka miejsca (v3, [[v3 – nazwa i notatka]])
- [x] Formularz od razu po long-tapie (v9: wybór typu, nazwa, notatka)
- [x] Tapnięcie w pinezkę otwiera podgląd i edycję (v2 + v3)
- [x] Usuwanie pinezek z „Cofnij” (v2)
- [x] Kategorie z różnymi ikonami (v9, [[v9 – kategorie pinezek]])
- [x] Animacja spadania nowej pinezki z wibracją (v7)
- [x] Pinezka z klikniętego POI mapy, z nazwą (v6, [[v6 – klikalne POI]])
- [ ] Chowanie ikony POI pod pinezką (`StandardPOIsState(hide: true)` + `setFeatureState`)
- [ ] Podpowiedź typu pinezki z POI (`maki`, `class`) – kategorie są od v9
- [ ] Etykiety z nazwą na mapie (`textField`; przy edycji nazwy `manager.update`)

## Mapa
- [ ] Lokalizacja użytkownika i przycisk „moja lokalizacja” (uprawnienia `ACCESS_FINE/COARSE_LOCATION`, obsługa odmowy)
- [ ] Zapamiętywanie ostatniej pozycji kamery
- [ ] Przełącznik stylów (własny / Outdoors / Satelita / Faded 3D) – zaplanowany jako v13, [[v11 – poprawki wyglądu]]
- [x] Własna paleta mapy w stylu aplikacji (v8)
- [x] Własny ciemny styl mapy z assetu (v12, [[v12 – własny styl mapy]])
- [ ] Ikony POI w stylu (sprite `maki`) – v12 ma same napisy
- [ ] Mniej etykiet miejscowości przy małym zoomie (`symbolrank`), jeśli będzie za gęsto
- [ ] Generator ikony aplikacji w repo (skrypt), dziś tylko opis w [[v8 – styl Nocturnal Expedition]]
- [x] Wyszukiwanie miejsc (Mapbox Search Box, v4, [[v4 – wyszukiwarka miejsc]])
- [ ] Lepsze trafianie w sławne miejsca w wyszukiwarce, np. `proximity` tylko przy przybliżonej mapie – [[v4 – wyszukiwarka miejsc]]. Na razie zostaje jak jest (decyzja z 2026-10-26); płatne API, np. Google Places, odpada.
- [ ] Ponowienie wyszukiwania po błędzie bez zmiany tekstu (np. tap w komunikat)
- [x] Kompas i skala niezasłonięte przez pasek statusu (v5, [[v5 – kompas i skala]])
- [ ] Prawdziwa wysuwana szuflada narzędzi, gdy narzędzi będzie więcej (v4 ma stałą kolumnę)

## Planowanie
- [x] Foldery jako kontener na miejsca (v10, [[ADR-007 Foldery pinezek]])
- [ ] Daty wyjazdu w folderze
- [ ] Usuwanie folderu (świadomie pominięte w v10 – trzeba zdecydować, co z pinezkami)
- [ ] Mapa folderu: kamera dopasowana do jego pinezek zamiast widoku Polski
- [ ] Elementy makiety startowej pominięte w v10: pogoda, dzwonek, wyszukiwarka list, chipy filtrów (kraje), tagi, licznik „odwiedzonych”, „Ostatnio zapisane miejsca”, dolna nawigacja
- [ ] Wybór okładki folderu (dziś stała nocna)
- [ ] Synchronizacja z chmurą / backend

## Infrastruktura
- [x] Repozytorium git na GitHubie (sprycjan/jureczek) – [[ADR-004 Struktura repo (app)]]
- [ ] iOS (`flutter create --platforms ios .`)
- [ ] CI: `flutter analyze` + `flutter test`
- [ ] Uprawnienie `INTERNET` w `android/app/src/main/AndroidManifest.xml`. Teraz jest tylko w `src/debug/` i `src/profile/`, więc build release prawdopodobnie nie ma sieci (kafelki mapy, wyszukiwarka). Wykryte 2026-10-26.
- [ ] Eksport / kopia zapasowa bazy (po niewyjaśnionej utracie pinezek testowych na telefonie 2026-10-26 – [[v3 – nazwa i notatka]])
- [ ] Zbadać znikanie pinezek: znowu 2026-11-01 między instalacją v9 i v10 (baza po migracji pusta, migracja 4 → 5 sama działa) – [[v10 – foldery i ekran startowy]]
- [ ] Snackbary mapy zostają widoczne po powrocie na ekran startowy

## Moje uwagi
Rozpisane 2026-11-02 na v11–v13 – [[v11 – poprawki wyglądu]], [[v12 – własny styl mapy]].
- [ ] Dolne menu – decyzja: na razie brak, wraca, gdy pojawi się treść (np. „Ostatnio zapisane”, ustawienia)
- [x] Mapa: biała obwódka wokół nazw miejscowości i POI – rozwiązane własnym stylem z ciemną obwódką (v12)
- [ ] Przełącznik stylów mapy: własny / Outdoors / Satelita / Faded 3D z nachyleniem – v13
- [x] Zmiana tekstów na ekranach (v11: „Cześć!”, bez podtytułu i zastępczego opisu)
- [ ] Dodanie większej ilości pinezek (Google Stitch) – czeka na grafiki od użytkownika
- [ ] Wybór koloru pinezki (24 opcje, nie pełny color picker) – v14
- [ ] Mruganie mapy i płynność przejścia do mapy (v11: zasłona + TLHC/TextureView) – czeka na potwierdzenie użytkownika
- [x] Zaznaczona pinezka pokazywała się z opóźnieniem o krok (klatka TLHC) – `triggerRepaint` po zmianie wyglądu, [[v11 – poprawki wyglądu]]
- [x] Nowa pinezka znikała po wylądowaniu do czasu ruszenia mapy (ta sama klatka TLHC)
- [x] Więcej ikon kategorii i kolorów akcentów folderów (v11: 15 ikon, 9 kolorów)
- [x] Obrazek przy dodawaniu folderu usunięty (v11), później dodamy coś innego
- [ ] Coś zamiast obrazka w formularzu folderu (pomysł użytkownika na później)
- [x] Łagodne przejście między pejzażem a listą (v11)
- [x] Pole wyszukiwarki z kanciastą obwódką (v11)

Powiązane: [[00 Jureczek – przegląd]]
