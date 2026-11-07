---
tags: [jureczek, przeglad]
---
# Jureczek – przegląd

**Jureczek** to aplikacja mobilna (Android) do planowania urlopów i wycieczek oraz zaznaczania miejsc, które chcę odwiedzić. Od v10 startuje od listy folderów (podróży), a mapa pokazuje pinezki folderu albo wszystkie. Celem jest uporządkowanie wszystkiego, co dzieje się przy planowaniu wakacji.

## Stos technologiczny
- Flutter (Dart), tylko Android – [[ADR-001 Flutter]]
- Mapy: Mapbox (`mapbox_maps_flutter` v3) – [[Mapbox Flutter]]
- Wyszukiwanie miejsc: Mapbox Search Box API przez REST (`http`) – [[v4 – wyszukiwarka miejsc]]
- Stan: Riverpod 3 – [[ADR-002 Riverpod]]
- Baza lokalna: drift (SQLite) – [[ADR-005 Drift jako baza lokalna]]
- Token Mapbox przez `--dart-define-from-file` – [[ADR-003 Token Mapbox]]
- Kod w `app/`, notatki w `obsidian-vault/` – [[ADR-004 Struktura repo (app)]]
- Foldery pinezek (każda pinezka w jednym folderze, ekran startowy z listą) – [[ADR-007 Foldery pinezek]]
- Styl: ciemny „Nocturnal Expedition”, czcionki Epilogue + Space Grotesk – [[ADR-006 Styl Nocturnal Expedition]]
- Mapa: własny klasyczny styl JSON w assetach (Streets v8) – [[ADR-008 Własny klasyczny styl mapy]]
- Lokalizacja: `geolocator` + kropka położenia Mapbox – [[ADR-009 Lokalizacja przez geolocator]]
- Kolor pinezki: warstwy z `render_pins.py` barwione w aplikacji – [[ADR-010 Kolor pinezki z warstw]]
- Ikony 74 typów miejsc: SVG z `tool/place_icons.py`, `flutter_svg`, cień malowany we Flutterze – [[ADR-011 Biblioteka ikon miejsc w SVG]]
- Typ pinezki = typ miejsca (81 z „inne”) albo zielona bez typu, w kolumnie `category` – [[ADR-012 Typ miejsca jako typ pinezki]]
- Odnośnik do Google Maps: link Google → nazwa POI z adresem → współrzędne, bez płatnego `place_id` – [[ADR-013 Odnośnik do Google Maps bez place_id]]
- Nazwy na mapie: kafelki `pl,en`, łaciński oryginał na POI i drogach, etykiety bez łacinki ukryte – [[ADR-014 Polskie nazwy na mapie]]
- Archiwum folderów: data w `folders.archived_at_ms`, mapa wszystkich bez archiwum, folder z archiwum tylko do podglądu – [[ADR-015 Archiwizowanie folderów]]
- Ekran powitalny: warstwy SVG z `tool/splash_art.py`, palety przez `ColorMapper`, nakładka nad Navigatorem – [[ADR-016 Ekran powitalny z warstw SVG]]

## Roadmapa
| Wersja | Zakres | Status |
|---|---|---|
| v1 | Mapa jako ekran główny + stawianie pinezek długim przytrzymaniem | ✅ działa na emulatorze i telefonie – [[v1 – mapa i pinezki]] |
| v2 | Pinezki zapisane w bazie + usuwanie (tap → arkusz → „Usuń” → „Cofnij”) | ✅ działa na telefonie – [[v2 – trwałe pinezki i usuwanie]] |
| v3 | Nazwa i notatka miejsca (arkusz: „Edytuj” → „Zapisz”/„Anuluj”), migracja bazy 1 → 2 | ✅ działa na telefonie – [[v3 – nazwa i notatka]] |
| v4 | Wyszukiwarka miejsc (Mapbox Search Box): lupa w kolumnie narzędzi → podpowiedzi → przelot + „Dodaj pinezkę” | ✅ działa na telefonie – [[v4 – wyszukiwarka miejsc]] |
| v5 | Kompas pod lupą, skala na dole po prawej (wcześniej pod paskiem statusu) | 🧪 skala sprawdzona, kompas do sprawdzenia na telefonie – [[v5 – kompas i skala]] |
| v6 | Klikalne POI: tap → karta „Dodaj pinezkę”, long-tap → pinezka z nazwą POI | 🧪 sprawdzone przez adb, czeka na potwierdzenie – [[v6 – klikalne POI]] |
| v7 | Animacja spadania nowej pinezki + stuknięcie wibracją | ✅ działa na telefonie – [[v7 – animacja spadania pinezki]] |
| v8 | Styl „Nocturnal Expedition” (kolory, czcionki Epilogue/Space Grotesk), paleta mapy, nowa ikona | 🧪 sprawdzone przez adb, poprawki czekają na potwierdzenie – [[v8 – styl Nocturnal Expedition]] |
| v9 | 8 typów pinezek (domyślna + 7 kategorii), wybór typu w formularzu, reset bazy (schemat 4) | 🧪 sprawdzone przez adb, czeka na potwierdzenie – [[v9 – kategorie pinezek]] |
| v10 | Foldery pinezek, ekran startowy z pejzażem, tworzenie/edycja folderu; mapa startuje dopasowana do pinezek | 🧪 sprawdzone przez adb, czeka na potwierdzenie – [[v10 – foldery i ekran startowy]] |
| v11 | Poprawki wyglądu: „Cześć!”, pejzaż z łagodnym przejściem, podgląd folderu bez obrazka, 15 ikon i 9 kolorów folderów, zaokrąglona wyszukiwarka, mapa bez mrugania | 🧪 sprawdzone przez adb, czeka na potwierdzenie – [[v11 – poprawki wyglądu]] |
| v12 | Własny ciemny styl mapy (VanVenture) z assetu zamiast Standardu z paletą; POI z warstwy `poi-label` | 🧪 sprawdzone przez adb, czeka na potwierdzenie – [[v12 – własny styl mapy]] |
| v13 | Przełącznik stylów mapy: Domyślny / Teren / 3D; przyciski + / − | 🧪 sprawdzone przez adb, czeka na potwierdzenie – [[v13 – przełącznik stylów mapy]] |
| v14 | Moja lokalizacja, ikony POI, mniej etykiet miejscowości, snackbary znikają z mapą, własny kolor pinezki (24 kolory, schemat 6) | 🧪 sprawdzone przez adb, czeka na potwierdzenie – [[v14 – lokalizacja, ikony POI i kolor pinezki]] |
| v15 | Biblioteka ikon miejsc: 74 typy × (pinezka, zaznaczona, ikona 24 dp) = 222 SVG, komponenty Flutter, galeria deweloperska z mapą | 🧪 sprawdzone przez adb, czeka na potwierdzenie – [[v15 – biblioteka ikon miejsc]] |
| v16 | Typy miejsc w pinezkach: wybór kategoria → typ, pinezki SVG na mapie, podpowiedź typu z `maki`, migracja v9 → „inne” (schemat 7) | 🧪 sprawdzone przez adb, czeka na potwierdzenie – [[v16 – typy miejsc w pinezkach]] |
| v17 | Krótszy formularz pinezki: select boxy kategorii, typu i folderu, kolory w jednej linii ze strzałkami, gęstsze pola, edycja bez autofocusu | 🧪 sprawdzone przez adb, czeka na potwierdzenie – [[v17 – krótszy formularz pinezki]] |
| v18 | Filtr kategorii pinezek na mapie: przycisk z lejkiem, panel z liczbami, działa od razu; grupowa synchronizacja pinezek | 🧪 sprawdzone przez adb, czeka na potwierdzenie – [[v18 – filtr kategorii pinezek]] |
| v19 | Odnośnik do Google Maps przy każdej pinezce: link Google, POI po nazwie z adresem albo współrzędne; adres POI z mapy zapisany przy dodaniu (schemat 8) | 🧪 sprawdzone przez adb, czeka na potwierdzenie – [[v19 – odnośnik do Google Maps]] |
| v20 | Polskie nazwy na mapie: bez cyrylicy i pisma arabskiego w stylach Domyślny i Teren; w 3D tylko język kafelków | 🧪 sprawdzone przez adb, czeka na potwierdzenie – [[v20 – polskie nazwy na mapie]] |
| v21 | Pinezka odwiedzona: kciuk w arkuszu zapisuje od razu, znaczek w rogu pinezki na mapie, data oznaczenia w bazie (schemat 9) | 🧪 sprawdzone przez adb, czeka na potwierdzenie – [[v21 – pinezka odwiedzona]] |
| v22 | Pinezka z gwiazdką: przełącznik w arkuszu i formularzu nowej pinezki, kolumna znaczków przy główce, pinezki z gwiazdką rysowane nad zwykłymi, włączone nakładanie (schemat 10) | 🧪 sprawdzone przez adb, czeka na potwierdzenie – [[v22 – pinezka z gwiazdką]] |
| v23 | Archiwum podróży: dolna belka, archiwizacja gestem i z menu z „Cofnij”, szary pejzaż, pinezki z archiwum ukryte na mapie wszystkich, folder z archiwum tylko do podglądu (schemat 11) | 🧪 sprawdzone przez adb, czeka na potwierdzenie – [[v23 – archiwum podróży]] |
| v24 | Animowany ekran powitalny: kamper z paralaksą, 8 losowanych krajobrazów, 4 pory dnia, gotowość aplikacji, natywny gradient (etap 3 z 4) | 🚧 sprawdzone przez adb, arkusz czeka na ocenę użytkownika – [[v24 – ekran powitalny]] |
| v25+ | Patrz [[Backlog]] | — |

## Inne
- [[Środowisko dev]] – jak uruchomić projekt
- Dokumentację bibliotek sprawdzamy w Context7 (`ctx7`)
