---
tags: [jureczek, wersja, pinezki, ui, mapbox]
wersja: v18
status: zaimplementowana – sprawdzona przez adb, czeka na potwierdzenie użytkownika
data: 2026-11-04
---
# v18 – filtr kategorii pinezek

Prośba użytkownika z 2026-11-04: po [[v16 – typy miejsc w pinezkach]] pinezek jest dużo, więc mapa potrzebuje przycisku z filtrem kategorii. Domyślnie widać wszystkie, pierwszy wybór zostawia jedną kategorię, kolejne dodają następne, a filtrowanie działa od razu, bez potwierdzania. Plan doprecyzowany z użytkownikiem (grill-plan).

## Zakres
- **Przycisk:** trzeci w górnej kolumnie narzędzi, pod stylami, na obu mapach. Przy aktywnym filtrze ma pełny lejek w kolorze akcentu, także przy zamkniętym panelu. Kompas zszedł o jeden przycisk niżej.
- **Panel:** rozwijany obok przycisku, w stylu listy stylów mapy. Wiersze: „Wszystkie”, zielona „Pinezka”, 7 kategorii. Każdy ma ikonę, nazwę, liczbę pinezek w tym widoku i ptaszek. Pozycja ukryta ma przygaszoną ikonę. Panel przewija się na niskim ekranie.
- **Zaznaczanie:** domyślnie wszystkie wiersze z ptaszkiem. Pierwszy tap zostawia wskazaną pozycję, kolejne dodają następne, tap w zaznaczoną ją odznacza. Odznaczenie ostatniej, ręczne zaznaczenie wszystkich 8 i wiersz „Wszystkie” przywracają stan domyślny.
- **Zamykanie panelu:** krzyżyk, tap w mapę, POI lub pinezkę, „wstecz”, otwarcie wyszukiwarki lub stylów.
- **Synchronizacja mapy:** `_syncPins` usuwa i tworzy anotacje grupowo, więc wiele pinezek zmienia się naraz.
- **Bez zmian:** baza danych, kamera po zmianie filtra, własny kolor pinezki (nie wpływa na kategorię).

## Decyzje
| # | Decyzja | Wybór |
|---|---|---|
| 1 | Przycisk i panel | trzeci przycisk w kolumnie, panel obok, zostaje otwarty przy zaznaczaniu |
| 2 | Zielona „Pinezka” | osobna pozycja, pierwsza wśród kategorii |
| 3 | Zaznaczanie | jak w „Zakresie”, z wierszem „Wszystkie” |
| 4 | Kategorie bez pinezek | zawsze 8 pozycji, przy każdej liczba pinezek |
| 5 | Czas życia filtra | reset po wyjściu z mapy, jak styl mapy |
| 6 | Kamera | nie rusza się po zmianie filtra |
| 7 | Pinezka spoza filtra (dodanie, zmiana typu) | jej kategoria dołącza do filtra |
| 8 | Duplikat ukryty filtrem | sprawdzanie obejmuje wszystkie pinezki widoku; otwiera się arkusz, kategoria dołącza do filtra |
| 9 | Znak aktywnego filtra | pełny lejek w kolorze akcentu |
| 10 | „Cofnij” po usunięciu | kategoria przywróconej pinezki dołącza do filtra |
| 11 | Usunięcie ostatniej pinezki wybranej kategorii | filtr bez zmian, przy kategorii 0 |
| 12 | Szybkość przy wielu pinezkach | `createMulti` i `deleteMulti` zamiast pojedynczych wywołań; wynikło z pomiaru |

## Pliki
- `lib/features/map/domain/pin_category_filter.dart` (nowy): `PinCategoryFilter` z regułami zaznaczania, `toggle`, `including`, `apply`.
- `lib/features/map/presentation/pin_category_filter_panel.dart` (nowy): panel z liczbami i ptaszkami.
- `lib/features/map/presentation/map_tools.dart`: parametr `active` w `MapToolButton`.
- `lib/features/map/presentation/map_screen.dart`: stan filtra, `_modePins` obok `_pins`, `_revealKind`, `_closePanels`, panel, przycisk, kompas, grupowy `_syncPins`.
- `lib/l10n/app_pl.arb`: `mapFilterOpen`, `mapFilterClose`, `mapFilterAll`.
- **Testy:** `pin_category_filter_test.dart`, `pin_category_filter_panel_test.dart` (w tym `MapToolButton` z `active`).

## Pułapki
- `_pins` zawiera teraz pinezki po filtrze. Wszystko, co dotyczy całego widoku, np. wykrywanie duplikatów, korzysta z `_modePins`.
- Pinezka przywracana lub dodawana przy filtrze musi dołączyć kategorię, zanim ruszy animacja: `_landPin` działa na anotacji, której przy ukrytej kategorii by nie było.
- Tap w POI i pinezkę zatrzymuje propagację, więc `TapInteraction.onMap` nie zamyka wtedy paneli. Dlatego `_closePanels` jest też w tych handlerach; przy okazji naprawia to samo dla listy stylów.
- Licznik w panelu ma własny `Consumer`, żeby zmiany w bazie nie przebudowywały całego ekranu z mapą.

## Pomiar szybkości
Debug build na P30, kopia bazy z 309 pinezkami, zmiana około 150 pinezek, zrzuty ekranu co około 0,5 s:

| Synchronizacja | Ukrycie | Pokazanie | Wygląd |
|---|---|---|---|
| Pojedyncze wywołania | 1,1–1,6 s | 1,4–3 s | pinezki zmieniają się stopniowo |
| `deleteMulti` / `createMulti` | 0,6–1 s | 0,8–1,3 s | pinezki zmieniają się naraz |

Pomiar jest przybliżony, bo wynika z odstępów między zrzutami. Builda release nie mierzono.

## Checklista weryfikacji
- [x] `flutter analyze`: 0 issues
- [x] `flutter test`: 215/215
- [x] P30 przez adb: domyślnie wszystkie → jedna kategoria → druga → odznaczanie → powrót do wszystkich.
- [x] P30 przez adb: zielona jako kategoria, lejek aktywny przy zamkniętym panelu, liczby przy wierszach.
- [x] P30 przez adb: panel zamykany krzyżykiem, tapem w mapę i pinezkę, „wstecz” oraz otwarciem stylów i wyszukiwarki. Tapu w POI nie sprawdzano.
- [x] P30 przez adb: mapa folderu z własnymi liczbami; reset filtra po wyjściu z mapy.
- [x] P30 przez adb: nowa pinezka spoza filtra spada i zostaje widoczna; zmiana typu na ukrytą kategorię dołącza ją do filtra.
- [x] P30 przez adb: „Cofnij” po ukryciu kategorii przywraca pinezkę i kategorię.
- [x] P30 przez adb: wyszukanie pinezki ukrytej filtrem otwiera jej arkusz z informacją o duplikacie i dołącza kategorię.
- [x] P30 przez adb: zmiana stylu na „Teren” przy aktywnym filtrze; lejek i pinezka z filtra zostają.
- [x] P30 przez adb: po przejściu na grupowy `_syncPins` nowa pinezka spada, a tap w nią otwiera właściwy arkusz.
- [x] Pinezki testowe usunięte, a baza z pomiaru zastąpiona oryginalną (9 pinezek, te same id).
- [ ] Kompas pod przyciskiem filtra: wyliczony margines, bez sprawdzenia na telefonie (obrót mapy wymaga dwóch palców, adb tego nie zrobi).
- [ ] Użytkownik: wygląd panelu, wyróżnienie aktywnego filtra, odczucie szybkości.

## Otwarte
- Otwarty panel zasłania środek mapy; do oceny po użyciu przez użytkownika.
- Na mapie wszystkich pinezek przycisk zoomu nadal może zasłaniać pinezkę przy prawej krawędzi (znany punkt z [[Backlog]]).

Powiązane: [[00 Jureczek – przegląd]], [[v17 – krótszy formularz pinezki]], [[v16 – typy miejsc w pinezkach]], [[v13 – przełącznik stylów mapy]], [[Mapbox Flutter]], [[Backlog]]
