---
tags: [jureczek, wersja, pinezki, baza]
wersja: v21
status: zaimplementowana – sprawdzona przez adb, czeka na potwierdzenie użytkownika
data: 2026-11-04
---
# v21 – pinezka odwiedzona

Prośba użytkownika z 2026-11-04: pinezkę można oznaczyć jako odwiedzoną małą ikonką kciuka w górę na panelu, a na mapie taka pinezka ma mały kciuk w prawym górnym rogu.

## Zakres
- **Arkusz pinezki:** ikonka kciuka po prawej stronie wiersza z typem. Kontur oznacza „nieodwiedzona”, wypełnienie „odwiedzona”. Tapnięcie zapisuje od razu, bez „Edytuj”.
- **Mapa:** odwiedzona pinezka ma biały kciuk na ciemnym kółku z białą obwódką (14 dp, na zaznaczonej 16 dp).
- **Baza:** kolumna `visited_at_ms` z datą oznaczenia (schemat 9). Data nie jest na razie nigdzie pokazywana.

## Decyzje
| # | Decyzja | Wybór |
|---|---|---|
| 1 | Kontrolka w arkuszu | ikonka w wierszu typu, zapis od razu |
| 2 | Znaczek na mapie | biały kciuk na ciemnym kółku z białą obwódką, bo kontrastuje z każdym z 24 kolorów pinezki |
| 3 | Co zapisujemy | data oznaczenia, bo później nie dałoby się jej odtworzyć |
| 4 | Kolejność folderów | oznaczenie podnosi folder na górę, jak inne zmiany pinezki |
| 5 | Zakres | tylko oznaczenie i znaczek; filtr, licznik i przygaszanie w [[Backlog]] |
| 6 | Odznaczenie | kasuje datę; ponowne oznaczenie zapisuje nową |
| 7 | Zaznaczona pinezka | też ma znaczek, proporcjonalnie większy |
| 8 | Miniatura typu w arkuszu | bez znaczka, bo stan pokazuje przycisk obok |
| 9 | Edycja i „Cofnij” | edycja nie zmienia oznaczenia; „Cofnij” po usunięciu je przywraca |
| 10 | Tryb edycji | ikonka tylko w podglądzie |
| 11 | Błąd zapisu | ikonka wraca do poprzedniego stanu, a arkusz pokazuje `pinsSaveError`; w trakcie zapisu ikonka jest nieaktywna |
| 12 | Nowa pinezka | zawsze nieodwiedzona, animacja spadania bez zmian |

## Pliki
- `lib/features/map/data/pins_table.dart`, `lib/core/database/app_database.dart`: kolumna `visitedAtMs`, schemat 9, migracja.
- `lib/features/map/domain/place_pin.dart`: `visitedAt` i `visited`.
- `lib/features/map/data/pins_repository.dart`: `setVisitedAt`, zapis daty w `insert`.
- `lib/features/map/application/pins_providers.dart`: `PinsController.setVisited`.
- `lib/features/map/presentation/pin_image.dart`: parametr `visited` w `renderPinPng`, `visitedBadge`, rysowanie znaczka.
- `lib/features/map/presentation/map_screen.dart`: czwarte pole w `_PinLook`, sufiks `-visited` w id obrazka, `_setPinVisited`.
- `lib/features/map/presentation/pin_details_sheet.dart`: ikonka i `onSetVisited`.
- `lib/l10n/app_pl.arb`: `pinMarkVisited`, `pinUnmarkVisited`.
- **Testy:** migracja 8 → 9, repozytorium, kontroler, arkusz i obraz pinezki.

## Pułapki
- `updateDetails` zapisuje `null` w pominiętych polach nazwy, notatki i adresu, więc oznaczenie ma osobną metodę `setVisitedAt`.
- Migracja z `from < 5` buduje tabelę od razu w bieżącym schemacie, dlatego nowa kolumna jest też w `newColumns` i `columnTransformer` w `_addFolders`.
- Pozycje znaczka są osobno dla czterech wariantów, bo ramki PNG się różnią: typy 48 i 54 dp, zielona 54 i 63 dp. Zielona nie ma opisu w `PlacePinGeometry`, więc jej główkę zmierzono z PNG.
- Wysokość arkusza zależy od adresu i notatki, więc ikonka nie ma stałej pozycji na ekranie. Przy testach przez adb trzeba to uwzględnić.

## Checklista weryfikacji
- [x] `flutter analyze`: 0 issues
- [x] `flutter test`: 261/261
- [x] P30 przez adb: migracja na istniejącej bazie, schemat 9, wszystkie 11 pinezek zachowane, żadna nieoznaczona błędnie.
- [x] P30 przez adb: oznaczenie zielonej w kolorze (czarnej) i pinezki typu; znaczek pojawia się od razu.
- [x] P30 przez adb: znaczek na zaznaczonej zielonej, widoczny pod przyciemnieniem arkusza.
- [x] P30 przez adb: stan zostaje po ponownym uruchomieniu aplikacji; folder przechodzi na górę listy.
- [x] P30 przez adb: usunięcie i „Cofnij” przywracają tę samą datę oznaczenia.
- [x] P30 przez adb: odznaczenie obu pinezek kasuje datę i zdejmuje znaczek.
- [ ] Znaczek na zaznaczonej pinezce typu na telefonie (tylko test obrazu).
- [ ] Przeniesienie oznaczonej pinezki do innego folderu na telefonie (ten sam zapis co edycja, pokryty testem repozytorium).
- [ ] Błąd zapisu oznaczenia na telefonie (tylko test arkusza).
- [ ] Użytkownik: czytelność i rozmiar znaczka na mapie, także w stylach Teren i 3D.

## Otwarte
- Po testach na telefonie folder Portugalia jest nad folderem Pinezki, bo oznaczanie podniosło go na górę. Oznaczenia zostały zdjęte.
- Data oznaczenia jest zapisywana, ale nigdzie niepokazywana.

Powiązane: [[00 Jureczek – przegląd]], [[v14 – lokalizacja, ikony POI i kolor pinezki]], [[v16 – typy miejsc w pinezkach]], [[v19 – odnośnik do Google Maps]], [[Backlog]]
