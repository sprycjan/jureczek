---
tags: [jureczek, adr, mapbox, lokalizacja]
status: przyjęta
data: 2026-11-04
---
# ADR-014 Polskie nazwy na mapie

## Kontekst
Etykiety były w lokalnym alfabecie: cyrylica, pismo arabskie. Użytkownik chce wszystkie nazwy polskim alfabetem. Tileset Streets v8 nie ma pola `name_pl`, więc `localizeLabels('pl')` nie wchodzi w grę. Mapbox nie ma też transliteracji na polski.

## Pomiary
Kafelki z 2026-11-04, zoom 14, liczba nazw nieczytelnych bez znajomości alfabetu:

| Miasto | warstwa | bez języka zapasowego (`pl`) | `pl,en` |
|---|---|---|---|
| Moskwa | ulice | 100/101 | 28/101 |
| Moskwa | POI | 167/222 | 103/222 |
| Kair | ulice | 623/623 | 0/623 |
| Kair | POI | 97/149 | 18/149 |
| Teheran | ulice | 651/651 | 462/651 |
| Kijów | ulice | 89/123 | 7/123 |

Dodanie kolejnych języków (`de,fr,es,it,pt`) prawie nic nie daje. `pl,en` w krajach łacińskich tłumaczy jednak na angielski część nazw: w Pradze 68/393 POI, w Krakowie 8/336 POI.

## Rozważane opcje
1. **Samo `language=pl`:** dobre egzonimy, ale większość ulic i POI zostaje w oryginale.
2. **Samo `language=pl,en`:** dużo lepsze pokrycie, ale „Pałac Biskupi” → „Episcopal Palace”.
3. **`pl,en` + `name_local` + filtr:** kafelki z `pl,en`, łaciński oryginał ma pierwszeństwo na POI i drogach, reszta nazw bez łacinki ukryta.
4. **Dwa źródła kafelków (`pl` i `pl,en`):** zachowują „Plac Wacława”, ale podwajają pobieranie i komplikują styl.
5. **Własna transliteracja w wyrażeniach stylu:** możliwa dla cyrylicy (`slice` + `match`), ale duże wyrażenia, a pismo arabskie bez samogłosek daje nieczytelny wynik.

## Decyzja
Opcja 3. Warstwy poprawiamy w czasie działania (`getStyleJSON` → `setStyleLayerProperties`), bo ta sama logika obsługuje własny styl i Outdoors, a jest testowalna bez telefonu. Styl Standard jest pominięty, bo warstw z importu nie da się zmieniać.

## Konsekwencje
- Domyślny i Teren nie pokazują obcych alfabetów w pierwszych 24 znakach nazwy.
- Część nazw jest po angielsku, nie po polsku, a w miejscach bez łacinki (Teheran) etykiet jest wyraźnie mniej.
- POI i ulice w krajach łacińskich są w oryginale, bez polskich egzonimów.
- Styl 3D ma tylko język kafelków: cyrylica zostaje tam, gdzie nie ma tłumaczenia.
- Wyrażenie jest długie (24 znaki × 3 zakresy), ale poprawki 20 warstw trwają około 0,3 s.
- Bez zmian w kosztach: kafelki w planie darmowym.

## Powiązane
[[v20 – polskie nazwy na mapie]], [[ADR-008 Własny klasyczny styl mapy]], [[Mapbox Flutter]]
