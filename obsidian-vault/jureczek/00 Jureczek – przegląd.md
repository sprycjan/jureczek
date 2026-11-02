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
| v13 | Przełącznik stylów mapy: Nocna wyprawa / Teren / Satelita / 3D | 🧪 sprawdzone przez adb (satelita bez zdjęć – 429 z Mapboxa), czeka na potwierdzenie – [[v13 – przełącznik stylów mapy]] |
| v14 | Własny kolor pinezki (24 opcje, schemat 6) | 📋 zaplanowane – [[v11 – poprawki wyglądu]] |
| v15+ | Patrz [[Backlog]] | — |

## Inne
- [[Środowisko dev]] – jak uruchomić projekt
- Dokumentację bibliotek sprawdzamy w Context7 (`ctx7`)
