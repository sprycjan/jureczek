---
tags: [jureczek, adr, foldery]
status: przyjęta
data: 2026-11-05
---
# ADR-015: Archiwizowanie folderów

## Kontekst
Skończone podróże zostają na ekranie startowym i na mapie wszystkich pinezek, a folderów nie da się usunąć ([[ADR-007 Foldery pinezek]]). Użytkownik chce odkładać je do archiwum i móc je przywrócić.

## Rozważane opcje
- Kolumna `is_archived` (tak/nie) albo data archiwizacji.
- Filtrowanie pinezek w kodzie mapy albo w zapytaniu do bazy.
- Archiwum z pełną edycją albo tylko do podglądu.

## Decyzja
- Folder ma kolumnę `archived_at_ms` (schemat 11): `null` to folder bieżący, a data ustala też kolejność archiwum.
- Mapa wszystkich pinezek czyta `activePinsProvider`, czyli zapytanie pomijające pinezki z folderów w archiwum. Mapa folderu czyta wszystkie pinezki i filtruje po folderze, więc działa też dla archiwum.
- `foldersProvider` zwraca wszystkie foldery, bo nazwy potrzebuje też mapa folderu z archiwum. Wybór folderu w formularzu pinezki używa `activeFoldersProvider`.
- Folder w archiwum jest tylko do podglądu razem z pinezkami. Żeby coś zmienić, trzeba go przywrócić.
- Folder „Pinezki” w archiwum nie blokuje domyślnego: `ensureDefault` tworzy nowy.

## Konsekwencje
- Archiwizacja i „Cofnij” nie zmieniają kolejności listy bieżącej, a przywrócenie podnosi folder na górę.
- Pinezka w miejscu, które jest już w archiwum, nie jest traktowana jako duplikat.
- Na liście mogą być dwa foldery „Pinezki” po przywróceniu starego.
- Dolna belka, dotąd odłożona w [[Backlog]], jest już na ekranie startowym.

## Powiązane
[[v23 – archiwum podróży]], [[ADR-007 Foldery pinezek]], [[ADR-005 Drift jako baza lokalna]], [[00 Jureczek – przegląd]]
