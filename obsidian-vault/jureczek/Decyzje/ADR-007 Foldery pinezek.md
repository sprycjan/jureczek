---
tags: [jureczek, adr, foldery]
status: przyjęta
data: 2026-11-01
---
# ADR-007: Foldery pinezek

## Kontekst
Pinezki trzeba grupować według podróży albo wspólnego mianownika („Portugalia”, „Ciekawe miejsca”). Aplikacja ma startować od listy takich grup, a nie od mapy.

## Rozważane opcje
- Folder opcjonalny (pinezki „bez folderu”).
- Folder obowiązkowy z domyślnym „Pinezki”.
- Relacja wiele-do-wielu (pinezka w kilku folderach).

## Decyzja
- Każda pinezka ma dokładnie jeden folder (`pins.folder_id`, NOT NULL), tabela `folders` (schemat 5).
- Domyślny folder „Pinezki” powstaje leniwie: przy zapisie pinezki bez wybranego innego folderu albo w migracji 4 → 5, gdy są pinezki.
- Folderów się nie usuwa; edycja przez ekran tworzenia.
- Kolejność listy: ostatnia zmiana folderu lub jego pinezek (`updated_at_ms`).
- Mapa ma dwa tryby: folder (tylko jego pinezki, zapis do niego) i wszystkie pinezki (wybór folderu w formularzu, udostępnienia).

## Konsekwencje
- Pusty ekran startowy pokazuje zachętę, dopóki nie powstanie pierwszy folder.
- Usuwanie folderów, daty wyjazdów czy udostępnianie folderu – osobne decyzje w przyszłości ([[Backlog]]).

## Powiązane
[[v10 – foldery i ekran startowy]], [[ADR-005 Drift jako baza lokalna]], [[ADR-015 Archiwizowanie folderów]], [[00 Jureczek – przegląd]]
