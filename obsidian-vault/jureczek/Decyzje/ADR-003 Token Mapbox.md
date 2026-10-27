---
tags: [jureczek, adr, mapbox]
status: przyjęta
data: 2026-10-25
---
# ADR-003: Przekazywanie tokenu Mapbox

## Decyzja
- Publiczny token (`pk.…`) w `app/env/dev.json` → `{"ACCESS_TOKEN": "pk..."}`.
- W repo jest tylko wzór `app/env/dev.example.json`. `app/.gitignore` wyklucza `env/*.json` poza `*.example.json`.
- Uruchamianie: `flutter run --dart-define-from-file=env/dev.json`.
- W kodzie: `const mapboxAccessToken = String.fromEnvironment('ACCESS_TOKEN');` (`lib/core/config/app_config.dart`), ustawiany w `main()` przez `MapboxOptions.setAccessToken`.
- Pusty token oznacza, że aplikacja pokazuje komunikat „Brak tokenu Mapbox” zamiast pustej mapy.

## Uwaga
Token publiczny i tak trafia do APK. Warto w panelu Mapbox ograniczyć go do potrzebnych scope'ów. Tajny token do pobierania SDK nie jest potrzebny w v3.

Powiązane: [[Mapbox Flutter]], [[Środowisko dev]]
