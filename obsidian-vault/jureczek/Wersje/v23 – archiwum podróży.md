---
tags: [jureczek, wersja, foldery, baza, ekran-startowy]
wersja: v23
status: zaimplementowana – sprawdzona przez adb, czeka na potwierdzenie użytkownika
data: 2026-11-05
---
# v23 – archiwum podróży

Prośba użytkownika z 2026-11-05: foldery z pinezkami można archiwizować, a na dole ekranu startowego jest belka z bieżącymi podróżami i archiwum. Widok archiwum jest na razie taki sam jak ekran startowy, tylko z wyszarzonym obrazkiem. Pinezki z archiwum widać tylko po wybraniu ich folderu z archiwum, a takiego folderu nie można edytować. Decyzja: [[ADR-015 Archiwizowanie folderów]].

## Zakres
- **Belka:** dwie zakładki, „Podróże” i „Archiwum”. Start zawsze na „Podróże”, Wstecz z archiwum wraca do „Podróże”.
- **Archiwum:** szary pejzaż, powitanie, tytuł „Archiwum podróży”, lista, bez przycisków mapy i nowego folderu. Puste archiwum pokazuje krótki tekst.
- **Archiwizowanie i przywracanie:** przesunięcie karty w obie strony albo menu folderu. Akcja od razu, snackbar z „Cofnij” przez 4 s.
- **Mapa wszystkich pinezek:** bez pinezek z archiwum, także w filtrze, kamerze, duplikatach i przy udostępnieniu.
- **Mapa folderu z archiwum:** tylko podgląd, zob. decyzje 9–11.
- **Baza:** kolumna `folders.archived_at_ms` (schemat 11).

## Decyzje
| # | Decyzja | Wybór |
|---|---|---|
| 1 | Co znaczy „nie można edytować” | cały folder z zawartością: bez dodawania, edycji, usuwania, kciuka i gwiazdki; link do Google Maps zostaje |
| 2 | Zarchiwizowany folder „Pinezki” | powstaje nowy „Pinezki”; dwa o tej samej nazwie są dopuszczalne |
| 3 | Belka | ikona + podpis: „Podróże” (kompas), „Archiwum” (pudełko) |
| 4 | Przyciski w archiwum | bez mapy i „Nowy folder”; puste archiwum bez przycisku |
| 5 | Gest i cofanie | przesunięcie w obie strony albo menu; od razu, z „Cofnij”, bez potwierdzenia |
| 6 | Kolejność | archiwum od ostatnio zarchiwizowanego; przywrócony na górę listy; „Cofnij” na dawne miejsce |
| 7 | Wstecz i start | Wstecz z archiwum do „Podróże”; start zawsze na „Podróże” |
| 8 | Skutki ukrycia | bez archiwum w wyborze folderu; brak wykrywania duplikatów względem archiwum |
| 9 | Lupa i POI w archiwum | znikają; zostają pinezki, filtr, style, zoom, „Moja lokalizacja” |
| 10 | Sygnał „tylko podgląd” | ikona archiwum przy nazwie folderu + snackbar po przytrzymaniu |
| 11 | Arkusz w archiwum | bez „Edytuj”/„Usuń”; gwiazdka i kciuk tylko przy ustawionym stanie, nieklikalne |
| 12 | Wygląd kart w archiwum | kolorowe, szary jest tylko obrazek |
| 13 | Przywracanie | tylko z listy, nie z mapy |
| 14 | Pusta lista „Podróże”, gdy wszystko jest w archiwum | „Nie masz bieżących podróży” i przycisk „Nowy folder” |

## Pliki
- `lib/features/folders/data/folders_table.dart`, `lib/core/database/app_database.dart`: kolumna `archivedAtMs`, schemat 11, migracja.
- `lib/features/folders/domain/trip_folder.dart`: `archivedAt`, `isArchived`.
- `lib/features/folders/data/folders_repository.dart`: `findActiveByName` zamiast `findByName`, `setArchiveState`.
- `lib/features/folders/application/folders_providers.dart`: `activeFoldersProvider`, `archive`, `restore`, `undoArchiveChange`.
- `lib/features/folders/presentation/folder_picker.dart`: tylko foldery bieżące.
- `lib/features/map/data/pins_repository.dart`, `lib/features/map/application/pins_providers.dart`: `watchActive`, `activePinsProvider`.
- `lib/features/home/presentation/home_screen.dart`: belka, `PopScope`, `_pendingMoves`, `Dismissible`, szary pejzaż, menu zależne od zakładki.
- `lib/features/map/presentation/map_screen.dart`: `readOnly`, `_pinsSource`, przesunięte panele, ikona archiwum przy nazwie folderu.
- `lib/features/map/presentation/pin_details_sheet.dart`: `readOnly`.
- `lib/l10n/app_pl.arb`: teksty archiwum.
- **Testy:** migracja 10 → 11, kontroler folderów, `watchActive`, wybór folderu, arkusz, ekran startowy (gest w obie strony, „Cofnij”, menu, Wstecz, kolejność, błąd zapisu).

## Pułapki
- `Dismissible` wymaga zniknięcia karty z drzewa zaraz po `onDismissed`, a strumień z bazy dociera później. Dlatego listy liczy `_pendingMoves` (id → stan docelowy), a wpis znika, gdy baza potwierdzi stan.
- Gdy zapis nie uda się od razu, karta wracała w tej samej klatce z dawnym stanem przesuniętego `Dismissible` i leciał wyjątek. Przed jej przywróceniem trzeba poczekać na `endOfFrame`. Błąd wykrył test ekranu startowego.
- Ścieżka migracji `from < 5` tworzy tabelę folderów od razu w bieżącej postaci, więc `addColumn` jest tylko w gałęzi dla schematu 5 i wyższych.
- `watchActive` używa `NOT IN`, a nie złączenia, żeby pinezka bez wiersza folderu nie zniknęła po cichu.
- Mapa czyta pinezki przez `_pinsSource`. Nowy odczyt pinezek na mapie ma iść przez ten getter, nie przez `pinsProvider`, bo inaczej archiwum wróci na mapę wszystkich.

## Checklista weryfikacji
- [x] `flutter analyze`: 0 issues
- [x] `flutter test`: 310/310
- [x] P30 przez adb: migracja na istniejącej bazie, schemat 11, 2 foldery i 14 pinezek zachowane, oba foldery bieżące.
- [x] P30 przez adb: przesunięcie w lewo archiwizuje, w prawo przywraca; tło „Archiwizuj” widoczne pod kartą; „Cofnij” przywraca wcześniejsze `updated_at_ms`.
- [x] P30 przez adb: menu „Edytuj” + „Archiwizuj” na liście, tylko „Przywróć” w archiwum, obie akcje działają.
- [x] P30 przez adb: szary pejzaż, puste archiwum, Wstecz z archiwum wraca do „Podróże”.
- [x] P30 przez adb: mapa wszystkich bez Portugalii, wybór folderu bez Portugalii, udostępnione miejsce w Lizbonie otwiera mapę wszystkich z kartą wyniku.
- [x] P30 przez adb: mapa folderu z archiwum: pinezki widoczne, brak lupy, ikona przy nazwie, stuknięcie w POI bez karty, snackbar po przytrzymaniu mapy i POI, panele stylów i filtra przy swoich przyciskach.
- [x] P30 przez adb: arkusz pinezki bez „Edytuj”/„Usuń”, gwiazdka i kciuk nieklikalne.
- [ ] Osobne przewinięcie zakładek na telefonie: przy 2 folderach lista się nie przewija.
- [ ] Błąd zapisu na telefonie (tylko test ekranu startowego).
- [ ] Użytkownik: odczucie gestu i wygląd tła pod kartą.
- [ ] Użytkownik: czy nazwy i ikony belki pasują.

## Poprawki po teście
- Ikona „Podróże”: walizka wyglądała jak śmietnik (uwaga użytkownika), teraz kompas (`Icons.explore`).

## Otwarte
- Snackbar „W archiwum nie można dodawać pinezek” na chwilę zasłania logo Mapbox, jak pozostałe snackbary mapy.
- Po testach na telefonie Portugalia i Pinezki są bieżące, jest 14 pinezek. Zmieniło się tylko `updated_at_ms` Portugalii, kolejność listy bez zmian.

Powiązane: [[00 Jureczek – przegląd]], [[ADR-015 Archiwizowanie folderów]], [[ADR-007 Foldery pinezek]], [[v10 – foldery i ekran startowy]], [[v22 – pinezka z gwiazdką]], [[Backlog]]
