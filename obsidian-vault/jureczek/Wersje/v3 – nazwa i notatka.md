---
tags: [jureczek, wersja]
wersja: v3
status: zaimplementowana – działa na telefonie
data: 2026-10-26
---
# v3 – nazwa i notatka

## Zakres
- Pinezka ma opcjonalną **nazwę** (1 linia, maks. 80 znaków) i **notatkę** (wiele linii, maks. 1000).
- Arkusz po tapnięciu: „Miejsce”, nazwa albo „Bez nazwy”, notatka (jeśli jest), współrzędne, data, „Edytuj” i „Usuń”.
- „Edytuj” przełącza arkusz na pola tekstowe z „Zapisz” i „Anuluj”. Po zapisie arkusz wraca do podglądu z nowymi danymi. Błąd zapisu pokazuje się w arkuszu, bo snackbar byłby pod nim niewidoczny.
- Białe znaki na brzegach są obcinane, a pusty tekst zapisuje się jako `null`.
- „Cofnij” po usunięciu przywraca też nazwę i notatkę.
- Baza: schemat 1 → 2 (`addColumn` dla `name` i `note`). Istniejące pinezki dostają puste pola.

## Decyzje
| # | Decyzja | Wybór |
|---|---|---|
| 1 | Kiedy nadać nazwę | później, przez tap → arkusz → „Edytuj” (postawienie pinezki bez zmian) |
| 2 | Edycja | tryb podglądu + „Edytuj” → pola z „Zapisz”/„Anuluj” |
| 3 | Reguły pól | oba opcjonalne, „Bez nazwy”, nazwa ≤ 80, notatka ≤ 1000, trim, pusty = `null` |
| 4 | Nazwa na mapie | nie teraz, zostaje w [[Backlog]] |
| 5 | Wersja | v3 |

## Pliki
- `app/lib/features/map/data/pins_table.dart`: kolumny `name`, `note` (nullable)
- `app/lib/core/database/app_database.dart`: `schemaVersion = 2`, `migration` z `addColumn`
- `app/lib/features/map/domain/place_pin.dart`: `name`, `note`, `maxNameLength`, `maxNoteLength`
- `app/lib/features/map/data/pins_repository.dart`: `updateDetails`, zapis i odczyt nowych pól
- `app/lib/features/map/application/pins_providers.dart`: `PinsController.updateDetails` (normalizacja)
- `app/lib/features/map/presentation/pin_details_sheet.dart`: `StatefulWidget` z trybem podglądu i edycji, `SavePinDetails`
- `app/lib/features/map/presentation/map_screen.dart`: `isScrollControlled: true`, `_savePinDetails`
- `app/lib/l10n/app_pl.arb`: `pinUnnamed`, `pinNameLabel`, `pinNoteLabel`, `pinEdit`, `pinSave`, `pinCancel`
- Testy: `test/core/database/app_database_migration_test.dart` (nowy), rozszerzone testy repozytorium, kontrolera i arkusza

## Pułapki
- **Utrata pinezek testowych na telefonie (niewyjaśniona).** Przed pierwszym startem v3 plik `app_flutter/jureczek.sqlite` już nie istniał: v3 utworzyło bazę od zera (`name` i `note` w `CREATE TABLE` przed `PRIMARY KEY`, a nie dopisane przez `ALTER`). Aplikacja nie była odinstalowana (`firstInstallTime` bez zmian), a `shared_prefs` i `cache` zostały. W międzyczasie telefon był odłączany, raz zainstalowano na nim APK x86_64 (crash przed startem Dart) i raz `flutter run` przerwano. Przyczyny nie ustalono. **Migracja nie jest winna**: wgrana baza w schemacie 1 przeszła na telefonie do schematu 2 z zachowaniem danych. Pomysł: eksport/kopia zapasowa w [[Backlog]].
- APK z emulatora (x86_64) nie działa na telefonie – [[Środowisko dev]].

## Checklista weryfikacji
- [x] `flutter analyze`: 0 issues
- [x] `flutter test`: 26/26 (w tym test migracji 1 → 2)
- [x] Telefon: baza w schemacie 1 (wgrana ręcznie) po starcie v3 ma `user_version = 2`, pinezki zostały, `name`/`note` puste
- [x] Telefon: arkusz pokazuje „Bez nazwy”, „Edytuj” i „Usuń”
- [x] Telefon: przy edycji arkusz unosi się nad klawiaturę, oba pola są widoczne
- [x] Telefon: „Zapisz” → podgląd z nową nazwą i notatką
- [x] Telefon: „Anuluj” nie zapisuje zmian
- [x] Telefon: nazwa i notatka przetrwały restart aplikacji
- [x] Telefon: „Usuń” → „Cofnij” przywraca pinezkę z nazwą i notatką

## Otwarte
- Przyczyna zniknięcia bazy na telefonie przed v3 – obserwować. Jeśli się powtórzy, zebrać `adb logcat` od momentu instalacji.

Powiązane: [[00 Jureczek – przegląd]], [[v2 – trwałe pinezki i usuwanie]], [[ADR-005 Drift jako baza lokalna]]
