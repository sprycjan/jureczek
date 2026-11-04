---
tags: [jureczek, wersja, pinezki, ui]
wersja: v17
status: zaimplementowana – sprawdzona przez adb, czeka na potwierdzenie użytkownika
data: 2026-11-04
---
# v17 – krótszy formularz pinezki

Prośba użytkownika z 2026-11-04: po dodaniu większej liczby pinezek ([[v16 – typy miejsc w pinezkach]]) formularz dodawania i edycji jest za duży. Ikon nie pomniejszać, typy ułożyć np. w select boxach, kolory w jednej przewijanej linii ze strzałkami. Plan doprecyzowany w dwóch rundach pytań (grill-plan).

## Zakres
- **Typ:** dwa select boxy obok siebie, „Kategoria” i „Typ”, zamiast rzędu kategorii i siatki typów.
  - Nowa kategoria od razu ustawia swój typ „Inne” i sama otwiera listę typów. Zamknięcie listy bez wyboru zostawia „Inne”.
  - Ponowny wybór tej samej kategorii nie kasuje typu, tylko otwiera listę.
  - Zielona „Pinezka” jest pierwsza na liście kategorii. „Typ” jest wtedy wyszarzony i pokazuje „—”.
  - Lista ma szerokość formularza, pinezki 32 dp w wybranym kolorze, bieżąca pozycja jest podświetlona i przewinięta w widok.
- **Kolory:** jedna przewijana linia 24 kółek po 40 dp, strzałki po bokach przewijają o szerokość widocznej części, a na końcu paska się wyszarzają. Przy edycji pasek centruje zapisany kolor. Nagłówek „Kolor: Złoty [Domyślny]” zostaje.
- **Folder:** select box na całą szerokość zamiast zawijanych chipów, z pozycją „Nowy folder” na liście.
- **Pola tekstowe:** licznik znaków od 80% limitu, notatka od 1 linii, gęstsze pola.
- **Edycja:** bez autofocusu, więc klawiatura nie zasłania formularza.
- **Bez zmian:** podgląd pinezki, mapa, baza danych, sposób zapisu typu i koloru, kolejność pól.

Efekt na P30: cały formularz mieści się na ekranie bez przewijania, a mapa nad nim jest nadal widoczna. Z klawiaturą też widać wszystkie pola i przyciski.

## Decyzje
| # | Decyzja | Wybór |
|---|---|---|
| 1 | Wybór typu | dwa select boxy obok siebie |
| 2 | Linia kolorów | 40 dp, strzałki wyszarzane na końcach, przewijanie o widoczną część |
| 3 | Nagłówek koloru | zostaje z przyciskiem „Domyślny” |
| 4 | Folder | select box z „Nowy folder” na liście |
| 5 | Pola tekstowe | licznik przy końcu limitu, notatka od 1 linii, `isDense` |
| 6 | Autofocus w edycji | usunięty |
| 7 | Zmiana kategorii | ustawia „Inne” i otwiera listę typów; zastępuje decyzję 7 z [[v16 – typy miejsc w pinezkach]] |
| 8 | Zielona „Pinezka” | pierwsza na liście kategorii, „Typ” wyszarzony |
| 9 | Rozwijana lista | przy polu, na szerokość formularza; 8 wierszy zamiast planowanych 7, żeby wszystkie kategorie mieściły się bez przewijania |
| 10 | Kolejność pól | bez zmian |
| 11 | Lista typów przy „Inne” | zaczyna od góry zamiast przewijać do „Inne” na końcu; wynikło z testu |

## Pliki
- `lib/core/widgets/select_field.dart` (nowy): `SelectField` i `SelectOption` na `MenuAnchor`, wspólne dla typu i folderu.
- `lib/features/map/presentation/pin_type_picker.dart`: przebudowa na dwa pola, bez `_TypeGrid` i `_Choice`.
- `lib/features/map/presentation/pin_color_picker.dart`: `StatefulWidget` z paskiem, `_ScrollArrow`, mniejsze marginesy kółek.
- `lib/features/folders/presentation/folder_picker.dart`: `SelectField` zamiast chipów.
- `lib/features/map/presentation/pin_form_fields.dart`: `_counter`, `_decoration`, bez parametru `autofocus`.
- `lib/features/map/presentation/pin_details_sheet.dart`: bez `autofocus`.
- `lib/features/map/domain/pin_color.dart`: komentarz.
- `lib/l10n/app_pl.arb`: `pinCategoryField`, `pinTypeField`, `pinTypeNone`, `pinColorScrollBack`, `pinColorScrollForward`; usunięty `pinCategoryLabel`.
- **Testy:** `new_pin_sheet_test`, `pin_details_sheet_test`, `folder_picker_test`. Nowe przypadki: „Inne” po zmianie kategorii i po zamknięciu listy, ta sama kategoria, wyszarzony „Typ”, strzałki, licznik, przewinięcie do zapisanego koloru, długa nazwa folderu.

## Pułapki
- `MenuAnchor` zamyka się przy przewinięciu przodka, a jego lista jest w `OverlayPortal`, więc `Scrollable.ensureVisible` przewinęłoby też arkusz pod spodem. Dlatego `Scrollable.of(...).position.ensureVisible(...)`, które rusza tylko listę.
- `MenuStyle.minimumSize` nie rozciąga listy: szerokość wynika z wierszy. Każdy wiersz ma `SizedBox(width: menuWidth)`.
- Etykieta `MenuItemButton` dostaje nieograniczoną szerokość, więc sam `overflow: ellipsis` nie działa. Tekst potrzebuje `SizedBox`, inaczej długa nazwa folderu wychodzi poza wiersz.
- `onPressed` w `MenuItemButton` odpala się po klatce, po zamknięciu listy. Otwarcie listy typów idzie więc jeszcze jednym `addPostFrameCallback`, gdy ma już typy nowej kategorii.
- Własny `border:` w `InputDecoration` nadpisuje motyw i daje jasną ramkę wyszarzonemu polu. `SelectField` go nie ustawia.
- P30 ma nadpisaną gęstość 408 (`wm density`), czyli ok. 423 dp szerokości, a nie 360 dp jak zakładają komentarze w testach.

## Checklista weryfikacji
- [x] `flutter analyze`: 0 issues
- [x] `flutter test`: 197/197
- [x] P30 przez adb: nowa pinezka long-tapem mieści się bez przewijania; „Typ” wyszarzony przy zielonej.
- [x] P30 przez adb: Natura → lista typów otwiera się sama od góry → Wodospad.
- [x] P30 przez adb: strzałki przewijają kolory; wybór Granatowego barwi pinezki w polach i na listach.
- [x] P30 przez adb: lista kategorii otwarta przy klawiaturze chowa klawiaturę i zostaje otwarta.
- [x] P30 przez adb: zapis pinezki z typem, kolorem i folderem; poprawny nagłówek „Wodospad · Natura i widoki”.
- [x] P30 przez adb: edycja bez klawiatury (`mInputShown=false`), kolor wycentrowany, typ i folder poprawne.
- [x] P30 przez adb: wyszukiwarka → „Muzeum Narodowe w Krakowie” → pola z „Miejsca i atrakcje” i „Muzeum”, lista typów przewinięta do Muzeum.
- [x] P30 przez adb: „Nowy folder” z listy otwiera dialog. Dialog anulowany, bo aplikacja nie ma usuwania folderów; samo utworzenie sprawdza `folder_picker_test`.
- [x] Pinezka testowa usunięta.
- [ ] Użytkownik: wygoda list, liczba wierszy, rozmiar kółek.

## Otwarte
- Liczba wierszy listy (`SelectField.menuMaxHeight`) i rozmiar kółek (`_swatchSize`) to stałe do łatwej zmiany po uwagach użytkownika.

Powiązane: [[00 Jureczek – przegląd]], [[v16 – typy miejsc w pinezkach]], [[v14 – lokalizacja, ikony POI i kolor pinezki]], [[v10 – foldery i ekran startowy]], [[Backlog]]
