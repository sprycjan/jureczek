---
tags: [jureczek, wersja]
wersja: v1
status: zaimplementowana – działa na emulatorze i telefonie
data: 2026-10-25
---
# v1 – mapa i pinezki

## Zakres
- Pełnoekranowa mapa Mapbox (`STANDARD`) jako ekran główny, startowy widok na całą Polskę.
- **Długie przytrzymanie** stawia pinezkę (czerwona „łezka”, czubek w miejscu palca).
- Pinezki tylko w pamięci, znikają po restarcie.
- Tapnięcie w pinezkę nic nie robi. Nie ma usuwania, nazw ani kategorii.
- Bez tokenu aplikacja pokazuje komunikat „Brak tokenu Mapbox”.

Poza zakresem → [[Backlog]].

## Decyzje
| # | Decyzja | Wybór |
|---|---|---|
| 1 | Technologia | Flutter + `mapbox_maps_flutter` v3 – [[ADR-001 Flutter]] |
| 2 | Trwałość | tylko pamięć |
| 3 | Gest | długie przytrzymanie |
| 4 | Dane miejsca | tylko pozycja |
| 5 | Token | `env/dev.json` + `--dart-define-from-file` – [[ADR-003 Token Mapbox]] |
| 6 | Testy ręczne | emulator `Pixel_8` + telefon |
| 7 | Kamera | stały widok na Polskę |
| 8 | applicationId | `pl.mc.jureczek` |
| 9 | Git | później (lokalny GitLab) |
| 10 | Język | ARB, polski |
| 12 | Pinezka | `PointAnnotation` + PNG |
| 13 | Styl | `STANDARD` |
| 14 | Stan | Riverpod 3 – [[ADR-002 Riverpod]] |
| 15 | Platformy | tylko Android |
| 16 | Struktura | `app/` – [[ADR-004 Struktura repo (app)]] |

## Pliki
- `app/lib/main.dart`: token i `ProviderScope`
- `app/lib/app.dart`: `MaterialApp`, l10n
- `app/lib/core/config/app_config.dart`: `mapboxAccessToken`
- `app/lib/features/map/domain/place_pin.dart`: model
- `app/lib/features/map/application/pins_notifier.dart`: `PinsNotifier` / `pinsProvider`
- `app/lib/features/map/presentation/map_screen.dart`: mapa, gest, rysowanie pinezek
- `app/lib/l10n/app_pl.arb`: teksty
- `app/assets/markers/pin.png`: ikona
- `app/test/…`: testy notifiera i ekranu bez tokenu

## Pułapki napotkane przy implementacji
- Gradle 8.14 z szablonu nie działa z Java 25 z Android Studio → Gradle 9.1.0 ([[Środowisko dev]]).
- `cameraOptions` i `onLongTapListener` nie istnieją w v3 → `viewport` + `addInteraction` ([[Mapbox Flutter]]).
- `flutter gen-l10n` domyślnie generuje nullowalny `AppLocalizations.of` → w `l10n.yaml` ustawić `nullable-getter: false`.
- Huawei: do `adb` potrzebne *Debugowanie USB* oraz *Zezwalaj na debugowanie ADB w trybie tylko ładowania*
- Debug build na emulatorze (Mac Intel) startuje 1–3 minuty, więc trzeba poczekać na splash.

## Checklista weryfikacji
- [x] `flutter analyze`: 0 issues
- [x] `flutter test`: 4/4
- [x] Emulator: bez tokenu wyświetla się komunikat
- [x] Emulator: mapa Standard, widok na Polskę
- [x] Emulator: długie przytrzymanie stawia pinezkę, czubek w miejscu dotyku
- [x] Emulator: wiele pinezek, przesuwanie mapy ich nie gubi
- [x] Emulator: zwykłe tapnięcie niczego nie dodaje
- [x] Telefon (Huawei P30 ELE-L29, Android 10): mapa, przesuwanie, zoom i obrót działają
- [x] Telefon: długie przytrzymanie stawia pinezki
- [ ] Ocena płynności na telefonie (subiektywnie, właściciel)

Powiązane: [[00 Jureczek – przegląd]]
