---
tags: [jureczek, adr, mapbox, styl]
status: przyjęta
data: 2026-11-02
---
# ADR-008: Własny klasyczny styl mapy

## Kontekst
Od v8 mapa to Standard z paletą przez config properties ([[ADR-006 Styl Nocturnal Expedition]]). Standard nie pozwala ustawić obwódki napisów (zawsze jasna), więc jasne etykiety na ciemnej mapie były nieczytelne ([[v11 – poprawki wyglądu]]). Użytkownik dostarczył gotowy ciemny styl Mapbox GL (JSON, Streets v8).

## Rozważane opcje
- Standard z paletą (bez zmian) – brak kontroli obwódki i szczegółów.
- Standard `lightPreset: night` – nocna mapa, ale nie w palecie aplikacji.
- Styl wgrany do Mapbox Studio (`mapbox://styles/…`) – wymaga konta Studio, poza repo.
- **Styl JSON jako asset aplikacji** (`asset://`).

## Decyzja
Styl klasyczny jako asset `app/assets/map/vanventure_dark.json`, ładowany przez `MapWidget(styleUri: mapStyleUri)`. Fonty Mapbox (DIN Pro). Klikalne POI z własnej warstwy `poi-label`.

## Konsekwencje
- Pełna kontrola wyglądu w repo (kolory, obwódki, które warstwy są widoczne).
- Tracimy funkcje Standardu: featureset `StandardPOIs` i `StandardPOIsState(hide:)`, 3D, `lightPreset`, ikony POI, automatyczne aktualizacje stylu od Mapbox.
- Nowe warstwy trzeba dopisywać ręcznie, z polami Streets v8.
- Paleta w kodzie (`map_palette.dart`) usunięta; [[ADR-006 Styl Nocturnal Expedition]] w części „mapa” zastąpiony.

## Powiązane
[[v12 – własny styl mapy]], [[ADR-006 Styl Nocturnal Expedition]], [[Mapbox Flutter]], [[00 Jureczek – przegląd]]
