---
tags: [jureczek, adr]
status: przyjęta
data: 2026-10-25
---
# ADR-005: Drift (SQLite) jako baza lokalna

## Kontekst
W v2 pinezki muszą przetrwać restart aplikacji. Z [[Backlog]] wynika, że dojdą kolejne dane: nazwa i notatka, kategorie, wyjazdy jako kontener na miejsca, a potem synchronizacja z chmurą.

## Rozważane opcje
- **drift**: SQLite z typowanymi zapytaniami, migracjami schematu i reaktywnym `watch()`. Wymaga codegenu (`build_runner`).
- **sqflite**: SQLite bez codegenu, ale z ręcznym SQL, mapowaniem i migracjami.
- **shared_preferences + JSON**: najprostsze, ale nie skaluje się do relacji.
- **Isar/Hive**: NoSQL o niepewnym utrzymaniu.

## Decyzja
drift (`drift` 2.34, `drift_flutter` 0.3, `drift_dev` i `build_runner` w dev).
- Baza: `lib/core/database/app_database.dart` (`AppDatabase`, plik `jureczek` przez `driftDatabase(name:)`), wspólna dla wszystkich feature'ów.
- Tabele są w feature'ach, np. `lib/features/map/data/pins_table.dart`. Wiersz `PinRow` mapuje repozytorium na model domenowy `PlacePin`.
- Baza jest jedynym źródłem prawdy: `StreamProvider` nad `repository.watchAll()`. Zapisy idą przez kontroler, a UI reaguje na strumień.
- Id to UUID v4 (`uuid`), żeby „Cofnij” przywracał to samo id i żeby przyszła synchronizacja nie miała kolizji.

## Konsekwencje
- Po zmianie tabel trzeba uruchomić `dart run build_runner build`. Plik `*.g.dart` jest generowany i nie edytujemy go ręcznie.
- Każda zmiana schematu oznacza podbicie `schemaVersion` i `MigrationStrategy` w `AppDatabase`. v2 startuje od wersji 1.
- Historia schematu: **1** (v2: `id`, `lat`, `lng`, `created_at`), **2** (v3: + `name`, `note` przez `addColumn`).
- Migracje piszemy ręcznie (`if (from < N)` w `onUpgrade`). Każda ma test, który buduje bazę w starym schemacie surowym SQL i `PRAGMA user_version` (`test/core/database/app_database_migration_test.dart`). Przy większej liczbie wersji warto przejść na `drift_dev make-migrations` / `stepByStep`.
- Testy działają na `AppDatabase(NativeDatabase.memory())` bez urządzenia.

Powiązane: [[v2 – trwałe pinezki i usuwanie]], [[ADR-002 Riverpod]]
