---
tags: [jureczek, backlog]
---
# Backlog

Pomysły i świadomie odłożone rzeczy po [[v1 – mapa i pinezki]], [[v2 – trwałe pinezki i usuwanie]] i [[v3 – nazwa i notatka]], [[v4 – wyszukiwarka miejsc]], [[v5 – kompas i skala]], [[v6 – klikalne POI]], [[v7 – animacja spadania pinezki]], [[v8 – styl Nocturnal Expedition]], [[v9 – kategorie pinezek]], [[v10 – foldery i ekran startowy]], [[v11 – poprawki wyglądu]], [[v12 – własny styl mapy]], [[v13 – przełącznik stylów mapy]], [[v14 – lokalizacja, ikony POI i kolor pinezki]], [[v15 – biblioteka ikon miejsc]], [[v16 – typy miejsc w pinezkach]], [[v17 – krótszy formularz pinezki]], [[v18 – filtr kategorii pinezek]], [[v19 – odnośnik do Google Maps]], [[v20 – polskie nazwy na mapie]], [[v21 – pinezka odwiedzona]], [[v22 – pinezka z gwiazdką]].

## Miejsca / pinezki
- [x] Oznaczenie pinezki jako odwiedzonej – v21, [[v21 – pinezka odwiedzona]]
- [x] Oznaczenie pinezki gwiazdką jako głównego punktu wycieczki, rysowanie nad zwykłymi – v22, [[v22 – pinezka z gwiazdką]]
- [ ] Filtr „tylko z gwiazdką” w panelu z lejkiem – [[v22 – pinezka z gwiazdką]]
- [ ] Filtr „odwiedzone / nieodwiedzone” w panelu z lejkiem – [[v21 – pinezka odwiedzona]]
- [ ] Przygaszanie odwiedzonych pinezek na mapie – [[v21 – pinezka odwiedzona]]
- [ ] Pokazanie daty odwiedzenia w arkuszu, np. „Odwiedzono 3 lis 2026” (data jest już w bazie od v21)
- [x] Trwałość: drift/SQLite za repozytorium (v2, [[ADR-005 Drift jako baza lokalna]])
- [x] Nazwa i notatka miejsca (v3, [[v3 – nazwa i notatka]])
- [x] Formularz od razu po long-tapie (v9: wybór typu, nazwa, notatka)
- [x] Tapnięcie w pinezkę otwiera podgląd i edycję (v2 + v3)
- [x] Usuwanie pinezek z „Cofnij” (v2)
- [x] Kategorie z różnymi ikonami (v9, [[v9 – kategorie pinezek]])
- [x] Animacja spadania nowej pinezki z wibracją (v7)
- [x] Pinezka z klikniętego POI mapy, z nazwą (v6, [[v6 – klikalne POI]])
- [ ] Chowanie ikony POI pod pinezką (`StandardPOIsState(hide: true)` + `setFeatureState`)
- [x] Podpowiedź typu pinezki z `maki` (POI i wyszukiwarka) – v16
- [ ] Podpowiedź z `poi_category_ids` wyszukiwarki (więcej trafień niż `maki`, np. winnica, browar)
- [x] Krótszy formularz pinezki: select boxy i linia kolorów zamiast zwijanej siatki – v17, [[v17 – krótszy formularz pinezki]]
- [x] Biblioteka ikon 74 typów miejsc (v15, [[v15 – biblioteka ikon miejsc]])
- [x] Typ miejsca w pinezce: wybór kategoria → typ, pinezki SVG na mapie, własny kolor dla SVG – v16, [[v16 – typy miejsc w pinezkach]]
- [x] Filtr kategorii pinezek na mapie – v18, [[v18 – filtr kategorii pinezek]]
- [x] Odnośnik do Google Maps przy każdej pinezce – v19, [[v19 – odnośnik do Google Maps]]
- [ ] Wybór podpowiedzi czasem zamyka listę bez wyniku; dwa razy w sesji `--no-resident`, po powrocie przez `am start`. Przy powtórce sprawdzić logi – [[v19 – odnośnik do Google Maps]]
- [ ] Etykiety z nazwą na mapie (`textField`; przy edycji nazwy `manager.update`)

## Mapa
- [x] Polskie nazwy bez cyrylicy i pisma arabskiego w stylach Domyślny i Teren – v20, [[ADR-014 Polskie nazwy na mapie]]
- [ ] Cyrylica w stylu 3D: warstw Standard nie da się zmienić. Pomysł: wyłączyć etykiety Standard (`show*Labels`) i dodać własne warstwy – [[v20 – polskie nazwy na mapie]]
- [ ] Transliteracja cyrylicy zamiast ukrywania nazw („Маслов переулок” → „Masłow pierieułok”) – [[ADR-014 Polskie nazwy na mapie]]
- [ ] Adresy z Search Box bywają częściowo po arabsku – [[v20 – polskie nazwy na mapie]]
- [ ] Sprawdzić odnośnik Google Maps dla POI z przetłumaczoną nazwą – [[v19 – odnośnik do Google Maps]]
- [x] Lokalizacja użytkownika i przycisk „moja lokalizacja” z obsługą odmowy (v14, [[ADR-009 Lokalizacja przez geolocator]])
- [ ] Śledzenie kamery za kropką położenia (follow puck)
- [ ] Zapamiętywanie ostatniej pozycji kamery
- [x] Przełącznik stylów (własny / Outdoors / Satelita / Faded 3D) – v13, [[v13 – przełącznik stylów mapy]]
- [ ] Widok satelity – usunięty w v13 na życzenie użytkownika (kafelki `mapbox.satellite` dawały 429); wrócić, jeśli konto Mapbox pozwoli
- [ ] 3D przy małym zoomie pokazuje kosmos – mniejsze pochylenie albo przybliżenie
- [ ] Zapamiętywanie wybranego stylu mapy (na razie świadomie bez)
- [x] Przyciski przybliżania i oddalania (v13)
- [x] Własna paleta mapy w stylu aplikacji (v8)
- [x] Własny ciemny styl mapy z assetu (v12, [[v12 – własny styl mapy]])
- [x] Ikony POI w stylu (sprite `dark-v11`, `maki`) – v14
- [x] Mniej etykiet miejscowości przy małym zoomie (`symbolrank`) – v14; progi do oceny użytkownika
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
- [x] Mapa folderu: kamera dopasowana do jego pinezek zamiast widoku Polski ([[v10 – foldery i ekran startowy]], poprawki po teście)
- [ ] Elementy makiety startowej pominięte w v10: pogoda, dzwonek, wyszukiwarka list, chipy filtrów (kraje), tagi, „Ostatnio zapisane miejsca”, dolna nawigacja
- [ ] Wybór okładki folderu (dziś stała nocna)
- [ ] Synchronizacja z chmurą / backend

- ~~Licznik „odwiedzone X z Y” na folderze~~ – odrzucone 2026-11-04, zob. „Porzucone” niżej – [[v21 – pinezka odwiedzona]]
- [ ] Wyróżnienie pinezek z gwiazdką na liście lub liczniku folderu – [[v22 – pinezka z gwiazdką]]

Pomysły odłożone przy kartach podróży (bez wymogu liczenia postępu):
- [ ] Linia łącząca miejsca wyjazdu i ręczne ustawianie ich kolejności, pierwszy krok do planu dnia
- [ ] Odległość od mojej lokalizacji przy miejscu (zgoda na lokalizację już jest)
- [ ] Automatyczny przelot kamerą po miejscach wyjazdu, dla przyjemności oglądania
- [ ] Układ miejsc rysowany na karcie folderu z samych współrzędnych, bez płatnego API
- [ ] Lista miejsc wyjazdu do przeglądania, bez postępu i bez odhaczania

## Porzucone
- **Karty podróży** (z `/make-it-better`, 2026-11-04): karuzela kart na dole mapy zsynchronizowana z pinezkami, przelot kamery po przesunięciu karty, karta podsumowania z pierścieniem „odwiedzone 3/4”. Powód użytkownika: wyjazd nie ma być listą do wbicia na 100%, „to nie są zawody ani check lista, tylko wakacje”, odpoczynek od wbijania achievementów. Wniosek: żadnych pierścieni postępu, liczników „X z Y” ani procentów. Sprawdzone działanie kamery zostało w [[Mapbox Flutter]].

## Infrastruktura
- [x] Repozytorium git na GitHubie (sprycjan/jureczek) – [[ADR-004 Struktura repo (app)]]
- [ ] iOS (`flutter create --platforms ios .`)
- [ ] CI: `flutter analyze` + `flutter test`
- [ ] Uprawnienie `INTERNET` w `android/app/src/main/AndroidManifest.xml`. Teraz jest tylko w `src/debug/` i `src/profile/`, więc build release prawdopodobnie nie ma sieci (kafelki mapy, wyszukiwarka). Wykryte 2026-10-26.
- [ ] Eksport / kopia zapasowa bazy (po niewyjaśnionej utracie pinezek testowych na telefonie 2026-10-26 – [[v3 – nazwa i notatka]])
- [ ] Zbadać znikanie pinezek: znowu 2026-11-01 między instalacją v9 i v10 (baza po migracji pusta, migracja 4 → 5 sama działa) – [[v10 – foldery i ekran startowy]]
- [x] Snackbary mapy zostają widoczne po powrocie na ekran startowy – v14 (własny `ScaffoldMessenger`)

## Moje uwagi
Rozpisane 2026-11-02 na v11–v13 – [[v11 – poprawki wyglądu]], [[v12 – własny styl mapy]].
- [ ] Dolne menu – decyzja: na razie brak, wraca, gdy pojawi się treść (np. „Ostatnio zapisane”, ustawienia)
- [x] Mapa: biała obwódka wokół nazw miejscowości i POI – rozwiązane własnym stylem z ciemną obwódką (v12)
- [x] Przełącznik stylów mapy: własny / Outdoors / Satelita / Faded 3D z nachyleniem – v13
- [x] Zmiana tekstów na ekranach (v11: „Cześć!”, bez podtytułu i zastępczego opisu)
- [ ] Dodanie większej ilości pinezek (Google Stitch) – czeka na grafiki od użytkownika
- [x] Wybór koloru pinezki (24 opcje, nie pełny color picker) – v14, [[ADR-010 Kolor pinezki z warstw]]
- [x] Arkusz nowej pinezki za długi – rozwiązane linią kolorów i select boxami (v17)
- [ ] Pigułka zoomu i przycisk lokalizacji zasłaniają pinezki przy prawej krawędzi
- [ ] Mruganie mapy i płynność przejścia do mapy (v11: zasłona + TLHC/TextureView) – czeka na potwierdzenie użytkownika
- [x] Zaznaczona pinezka pokazywała się z opóźnieniem o krok (klatka TLHC) – `triggerRepaint` po zmianie wyglądu, [[v11 – poprawki wyglądu]]
- [x] Nowa pinezka znikała po wylądowaniu do czasu ruszenia mapy (ta sama klatka TLHC)
- [x] Więcej ikon kategorii i kolorów akcentów folderów (v11: 15 ikon, 9 kolorów)
- [x] Obrazek przy dodawaniu folderu usunięty (v11), później dodamy coś innego
- [ ] Coś zamiast obrazka w formularzu folderu (pomysł użytkownika na później)
- [x] Łagodne przejście między pejzażem a listą (v11)
- [x] Pole wyszukiwarki z kanciastą obwódką (v11)

Powiązane: [[00 Jureczek – przegląd]]
