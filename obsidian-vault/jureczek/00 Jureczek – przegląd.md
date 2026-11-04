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
| v18+ | Patrz [[Backlog]] | — |

## Inne
- [[Środowisko dev]] – jak uruchomić projekt
- Dokumentację bibliotek sprawdzamy w Context7 (`ctx7`)
