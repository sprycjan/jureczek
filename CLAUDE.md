# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

Jureczek: Android-only Flutter app for planning trips by marking places on a map. Code in `app/`, docs in `obsidian-vault/jureczek/` (Polish). Git repo, remote `origin` = https://github.com/sprycjan/jureczek (branch `main`).

## Obsidian vault — project source of truth
Not loaded automatically; read on demand:
1. At session start: `00 Jureczek – przegląd.md` (overview, stack → ADR links, roadmap) and the newest note in `Wersje/`.
2. When relevant: `Środowisko dev.md` (toolchain, adb tricks), `Backlog.md`, `Technologia/Mapbox Flutter.md` (Mapbox v3 + Search Box cheat sheet), `Decyzje/ADR-*.md`.
3. Search other notes with grep; link with `[[wikilinks]]`.

After every change, update the vault without asking (use `/vault-update`): version note, ADR if a decision was made, roadmap in the overview, Backlog, tech notes.

## Commands (run in `app/`)
- Run: `flutter run -d <phone> --dart-define-from-file=env/dev.json` — without the define the app shows "Brak tokenu Mapbox". Token: `ACCESS_TOKEN` (public `pk.`) in `env/dev.json` (from `env/dev.example.json`).
- Test: `flutter test --timeout 30s` (macOS has no `timeout`; hanging tests otherwise never fail). `flutter analyze` must stay at 0 issues.
- After drift table changes: `dart run build_runner build`. Never edit `*.g.dart`. After ARB changes: `flutter gen-l10n`.

## Testing on device
- Manual tests on the Huawei P30 (Android 10), never the emulator (too slow). If the phone is disconnected, ask the user.
- Build for the phone with `flutter run -d <phone>` — an emulator APK is x86_64-only and crashes there.
- `adb` is not on PATH: `~/Library/Android/sdk/platform-tools/adb`.

## Rules
- Free tiers only — never propose paid APIs (e.g. Google Places). Mapbox Search Box: 500 free sessions/month, billed per `session_token`.
- Look up library docs with Context7 (`ctx7`); training data for Mapbox v3 / Riverpod 3 is unreliable.

## Gotchas
- Mapbox SDK v3, not v2: `viewport: CameraViewportState`; `map.addInteraction(TapInteraction.onMap / LongTapInteraction.onMap)` instead of listeners; `Position(lng, lat)` (lng first); `PointAnnotation` needs PNG bytes.
- Riverpod 3 pauses providers without listeners. In tests: `container.listen(p, (_, _) {})` → `pumpEventQueue()` → `read(p).requireValue`; `read(p.future)` hangs.
- The drift DB is the single source of truth (`StreamProvider` over `watchAll()`, writes through controllers). Ids are UUID v4.
- Schema changes: bump `schemaVersion`, hand-write `if (from < N)` in `onUpgrade`, and add a migration test that builds the old schema with raw SQL + `PRAGMA user_version` (`test/core/database/app_database_migration_test.dart`).
- Never log `ClientException.toString()` — it contains the URL with `access_token`; use `e.message`.
- Flutter 3.41: a `SnackBar` with an action needs `persist: false` or it never closes.
- Keep UI clear of the Mapbox logo/attribution (license requirement).
- Gradle wrapper is pinned to 9.1.0 on purpose (8.14 fails with the bundled Java 25).
