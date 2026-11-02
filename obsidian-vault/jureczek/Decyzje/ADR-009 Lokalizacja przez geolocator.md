---
tags: [jureczek, adr, lokalizacja]
status: przyjęta
data: 2026-11-02
---
# ADR-009: Lokalizacja przez geolocator

## Kontekst
Przycisk „Moja lokalizacja” ([[v14 – lokalizacja, ikony POI i kolor pinezki]]) potrzebuje zgody systemu, sprawdzenia, czy lokalizacja jest włączona, i bieżącej pozycji. Mapbox Flutter rysuje kropkę położenia, ale o zgodę nie pyta (dokumentacja odsyła do `permission_handler`) i nie podaje pozycji do kodu.

## Rozważane opcje
- `permission_handler` + kropka Mapbox + `ViewportController.moveTo(FollowPuckViewportState)` – zgoda w jednej bibliotece, przelot przez API viewportu; miesza się z naszym `flyTo`/`setCamera` i nie daje pozycji.
- **`geolocator`** – zgoda, stan usługi, ostatnia znana i bieżąca pozycja, otwieranie ustawień w jednym pakiecie; kropka nadal z Mapbox.
- Sama kropka Mapbox bez przycisku – brak obsługi odmowy.

## Decyzja
`geolocator` za cienką klasą `UserLocationService` (provider, podmieniany w testach przez `GeolocatorPlatform.instance`). Kropka: `map.location.updateSettings(LocationComponentSettings(enabled: true, …))`. Przelot zwykłym `flyTo`.

## Konsekwencje
- Jedna zależność, logika zgody testowana jednostkowo bez telefonu.
- Pozycję czytają dwa źródła (geolocator i Mapbox) – mogą się chwilę różnić.
- Bez śledzenia kamery za kropką (follow puck); w razie potrzeby da się dodać `ViewportController`.

## Powiązane
[[v14 – lokalizacja, ikony POI i kolor pinezki]], [[Mapbox Flutter]], [[00 Jureczek – przegląd]]
