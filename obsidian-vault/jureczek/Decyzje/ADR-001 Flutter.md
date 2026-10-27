---
tags: [jureczek, adr]
status: przyjęta
data: 2026-10-25
---
# ADR-001: Flutter jako technologia aplikacji

## Kontekst
Aplikacja na Androida z mapą Mapbox jako sercem. Ma być rozwijana w kolejnych wersjach (wyjazdy, trwałość, może iOS i synchronizacja).

## Rozważane opcje
- **Flutter + `mapbox_maps_flutter`**: oficjalny SDK Mapboxa, aktywnie rozwijany (v3, 2026).
- **Kotlin + Jetpack Compose + Mapbox Maps SDK for Android**: najlepsza integracja, ale tylko Android.
- **React Native + `@rnmapbox/maps`**: biblioteka społeczności, nie Mapboxa.

## Decyzja
Flutter. Biblioteka Mapbox jest oficjalna, Flutter był już zainstalowany, a iOS i web dostaniemy w przyszłości z jednego kodu.

## Konsekwencje
- Projekt generowany z `--platforms android`; `ios/` można dodać później przez `flutter create --platforms ios .`.
- `MapWidget` to natywny widok, więc nie testuje się go w `flutter test`.

Powiązane: [[00 Jureczek – przegląd]], [[Mapbox Flutter]]
