---
tags: [jureczek, adr]
status: przyjęta
data: 2026-10-25
---
# ADR-002: Riverpod 3 do zarządzania stanem + struktura feature-first

## Decyzja
- `flutter_riverpod` 3.x, **bez** generowania kodu: `Notifier<T>` + `NotifierProvider(X.new)`.
- Logika w `build()` i metodach notifiera, nigdy w konstruktorze.
- Struktura katalogów:
  - `lib/core/`: konfiguracja (np. token)
  - `lib/features/<feature>/{domain,application,presentation,data}`
  - `lib/l10n/`: teksty ARB (tylko polski)

## Uzasadnienie
Wprowadzenie Riverpoda przy prostej liście pinezek kosztuje niewiele, a w v2 (baza, repozytorium, async) wpasuje się bez przebudowy. Notifiery łatwo testować przez `ProviderContainer`.

## Alternatywy
Bloc/Cubit (więcej ceremonii) albo `setState` (refaktor przy v2). `riverpod_generator` można dołożyć później.

Powiązane: [[v1 – mapa i pinezki]]
