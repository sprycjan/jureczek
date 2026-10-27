---
tags: [jureczek, przeglad]
---
# Jureczek – przegląd

**Jureczek** to aplikacja mobilna (Android) do planowania urlopów i wycieczek oraz zaznaczania miejsc, które chcę odwiedzić. Celem jest uporządkowanie wszystkiego, co dzieje się przy planowaniu wakacji.

## Stos technologiczny
- Flutter (Dart), tylko Android – [[ADR-001 Flutter]]
- Mapy: Mapbox (`mapbox_maps_flutter` v3) – [[Mapbox Flutter]]
- Wyszukiwanie miejsc: Mapbox Search Box API przez REST (`http`) – [[v4 – wyszukiwarka miejsc]]
- Stan: Riverpod 3 – [[ADR-002 Riverpod]]
- Baza lokalna: drift (SQLite) – [[ADR-005 Drift jako baza lokalna]]
- Token Mapbox przez `--dart-define-from-file` – [[ADR-003 Token Mapbox]]
- Kod w `app/`, notatki w `obsidian-vault/` – [[ADR-004 Struktura repo (app)]]

## Roadmapa
| Wersja | Zakres | Status |
|---|---|---|
| v1 | Mapa jako ekran główny + stawianie pinezek długim przytrzymaniem | ✅ działa na emulatorze i telefonie – [[v1 – mapa i pinezki]] |
| v2 | Pinezki zapisane w bazie + usuwanie (tap → arkusz → „Usuń” → „Cofnij”) | ✅ działa na telefonie – [[v2 – trwałe pinezki i usuwanie]] |
| v3 | Nazwa i notatka miejsca (arkusz: „Edytuj” → „Zapisz”/„Anuluj”), migracja bazy 1 → 2 | ✅ działa na telefonie – [[v3 – nazwa i notatka]] |
| v4 | Wyszukiwarka miejsc (Mapbox Search Box): lupa w kolumnie narzędzi → podpowiedzi → przelot + „Dodaj pinezkę” | ✅ działa na telefonie – [[v4 – wyszukiwarka miejsc]] |
| v5+ | Patrz [[Backlog]] | — |

## Inne
- [[Środowisko dev]] – jak uruchomić projekt
- Dokumentację bibliotek sprawdzamy w Context7 (`ctx7`)
