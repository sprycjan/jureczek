---
tags: [jureczek, adr, pinezki, google-maps]
status: przyjęta
data: 2026-11-04
---
# ADR-013: Odnośnik do Google Maps bez place_id

## Kontekst
Każda pinezka ma otwierać swoje miejsce w Mapach Google. Pewnie trafia tylko `place_id` Google albo oryginalny link. Mapbox go nie daje, a Places API jest płatne, więc odpada ([[v19 – odnośnik do Google Maps]]). POI trzeba wyszukać tak, żeby nie otworzyć podobnego miejsca w innym mieście.

## Rozważane opcje
- Zawsze współrzędne: pewny punkt, ale bez karty miejsca.
- Dwa odnośniki, „punkt” i „szukaj”: dodatkowy wybór przy każdym otwarciu.
- Wyszukanie aktualnej nazwy pinezki: własna nazwa typu „Parking koło Ani” daje zły wynik.
- Nazwa POI ze współrzędnymi: test na P30 pokazał bazylikę z Krakowa w Gdańsku, koło użytkownika.
- **Oryginalna nazwa POI z adresem; bez adresu współrzędne.**

## Decyzja
- Kolejność: `sourceUrl`, potem `search/<poi_name, adres>/@lat,lng,17z`, potem `search/?api=1&query=lat,lng`.
- Kolumna `poi_name` (schemat 8) trzyma nazwę POI ze źródła i nie zmienia się z nazwą pinezki.
- POI z mapy nie ma adresu, więc formularz pobiera go raz przez Geocoding v6 `reverse` i zapisuje z pinezką.
- Bez adresu otwieramy współrzędne: lepszy właściwy punkt bez karty niż wiarygodnie wyglądająca karta złego miejsca.

## Konsekwencje
- Większość POI otwiera od razu kartę, bez płatnego API. Pewności jak z `place_id` nie ma.
- Jedno zapytanie geokodowania na dodane POI z mapy (100 tys. miesięcznie gratis), bez zapytań przy otwieraniu.
- Format `/search/<tekst>/@…` nie należy do udokumentowanego `api=1`, więc Google może go zmienić. Zmiana dotyczy jednego pliku: `google_maps_link.dart`.
- Zmieniony przez użytkownika adres trafia do wyszukiwania, bo używamy adresu pinezki.
- Pinezki sprzed v19 mają puste `poi_name` i otwierają współrzędne.

## Powiązane
[[v19 – odnośnik do Google Maps]], [[ADR-012 Typ miejsca jako typ pinezki]], [[ADR-005 Drift jako baza lokalna]], [[Mapbox Flutter]]
