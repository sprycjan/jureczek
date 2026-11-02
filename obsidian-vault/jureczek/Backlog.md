---
tags: [jureczek, backlog]
---
# Backlog

Pomysły i świadomie odłożone rzeczy po [[v1 – mapa i pinezki]], [[v2 – trwałe pinezki i usuwanie]] i [[v3 – nazwa i notatka]], [[v4 – wyszukiwarka miejsc]], [[v5 – kompas i skala]], [[v6 – klikalne POI]], [[v7 – animacja spadania pinezki]], [[v8 – styl Nocturnal Expedition]], [[v9 – kategorie pinezek]], [[v10 – foldery i ekran startowy]].

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
- [ ] Przełącznik stylów (Standard / Outdoors / Satellite)
- [x] Własna paleta mapy w stylu aplikacji (v8)
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
- [ ] Dolne menu, zdecydowac czy jest tam coś do wrzucenia
- [ ] Mapa: do usunięcia biała obwódka wokół nazw miejscowości i POI i ewentualne dopasowanie koloru tekstu
- [ ] Przełącznik na mapie do trybu 3D w odpowiednim stylu
- [ ] Zmiana tekstów na ekranach
- [ ] Dodanie większej ilości pinezek (Google Stitch)
- [ ] Dodanie wyboru koloru pinezki
- [ ] Mruganie mapy podczas przełączania ekranu głównego do mapy
- [ ] Więcej ikon kategorii i kolorów akcentów
- [ ] Poprawić obrazek przy dodawaniu folderu, możeusunąć
- [ ] Na ekranie folderów zrobić łagodne przejście między obrazkiem, a listą, jak na screenie z Google Stitch
- [ ] Poprawić pole wyszukiwarki, obramówka jest kanciasta, a pole zaokrąglone

Powiązane: [[00 Jureczek – przegląd]]
