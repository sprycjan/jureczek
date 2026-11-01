---
tags: [jureczek, wersja, mapbox, animacja]
wersja: v7
status: zaimplementowana – działa na telefonie
data: 2026-11-01
---
# v7 – animacja spadania pinezki

## Zakres
- Nowa pinezka (long-tap na mapie lub POI, „Zapisz” w formularzu wyniku/udostępnienia) **spada** na mapę: start 80 px nad punktem, jedno odbicie na 14 px, razem 450 ms.
- W momencie uderzenia telefon **stuka wibracją** (40 ms).
- Przy formularzu pinezka spada dopiero po zamknięciu arkusza (250 ms), żeby było ją widać.

## Decyzje
| # | Decyzja | Wybór |
|---|---|---|
| 1 | Jak animować | Flutterowa nakładka `PinDrop` nad mapą (Stack), a pinezka Mapbox jest niewidoczna (`iconOpacity: 0`) do wylądowania; Mapbox nie animuje `PointAnnotation` |
| 2 | Podmiana nakładki na pinezkę Mapbox | najpierw `iconOpacity: 1`, potem 150 ms zapasu na render, dopiero potem znika nakładka – bez migania |
| 3 | Wibracja | własny kanał `pl.mc.jureczek/haptics` (`MainActivity.kt`, `Vibrator`), bo `HapticFeedback` Fluttera milczy przy wyłączonych wibracjach dotykowych (domyślnie na EMUI) |

## Pliki
- `app/lib/features/map/presentation/pin_drop.dart`: nowy, widget `PinDrop` (TweenSequence spadek/odbicie, `onImpact`, `onLanded`)
- `app/lib/features/map/presentation/map_screen.dart`: `_addPinAt`, `_holdPin`, `_dropPin`, `_landPin`, `_setPinOpacity`, nakładki w `ValueListenableBuilder`, precache obrazka
- `app/lib/features/map/application/pins_providers.dart`: `PinsController.add` zwraca id
- `app/lib/core/haptics/haptics.dart`: nowy, `Haptics.tap()` + `hapticsProvider`
- `app/android/app/src/main/kotlin/pl/mc/jureczek/MainActivity.kt`: kanał haptics, `VibrationEffect.createOneShot`
- `app/android/app/src/main/AndroidManifest.xml`: uprawnienie `VIBRATE`
- Testy: `test/features/map/pin_drop_test.dart`, `test/core/haptics_test.dart`, `pins_controller_test.dart` (+1)

## Pułapki
- Mapbox rysuje obrazek w pikselach fizycznych, więc rozmiar nakładki = rozmiar PNG × `iconSize` / `devicePixelRatio`.
- Obrazek nakładki musi być zdekodowany zawczasu (`precacheImage`), inaczej pierwsze klatki spadania są puste.
- `mapbox_maps_flutter` eksportuje własne `Size` – import z `hide Size`.

## Checklista weryfikacji
- [x] `flutter analyze`: 0 issues
- [x] `flutter test`: 126/126
- [x] Telefon (użytkownik): animacja działa

## Otwarte
- brak

Powiązane: [[00 Jureczek – przegląd]], [[v6 – klikalne POI]], [[Mapbox Flutter]]
