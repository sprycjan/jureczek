---
tags: [jureczek, wersja, ui, mapbox]
wersja: v11
status: zaimplementowana – sprawdzona przez adb, czeka na potwierdzenie użytkownika
data: 2026-11-02
---
# v11 – poprawki wyglądu

Pierwsza z trzech wersji po uwagach użytkownika z [[Backlog]] („Moje uwagi”). Kolejne: v12 – przełącznik stylów mapy, v13 – własny kolor pinezki (plan w sekcji „Otwarte”).

## Zakres
- **Teksty:**
  - „Cześć Podróżniku!” → „Cześć!”;
  - usunięty podtytuł „Dokąd ruszamy kamperem…”;
  - usunięty zastępczy opis „Dzikie postoje…” w podglądzie folderu. Pusty opis = sama nazwa, podpowiedzi w polach zostają.
- **Podgląd folderu bez obrazka:** karta z odznaką, nazwą i opisem, jak na liście. Usunięty `assets/landscapes/cover.jpg`; „coś innego” dodamy później.
- **Pejzaż na starcie:**
  - wypełnia cały nagłówek (320 dp) i długim gradientem przechodzi w tło, jak w makiecie Stitcha;
  - „Cześć!” leży na dolnej części obrazka.
- **Wyszukiwarka:** ramka po dotknięciu jest zaokrąglona tak samo jak pole (24) i ma zieloną linię.
- **Bez mrugania przy wejściu na mapę:** zasłona w kolorze tła do nałożenia palety, potem odsłonięcie 200 ms.
- **Foldery:** 15 ikon (nowe: las, miasto, zamek, jedzenie, wino, rower, kajak, narty) i 9 kolorów (nowe: szafir `#90CAF9`, łąka `#81C784`, laguna `#4DD0E1`, łupek `#B0BEC5`). Wybór w poziomo przewijanych rzędach.
- **Spike obwódki napisów na mapie:** wynik negatywny, zmiana cofnięta (patrz „Pułapki”).

## Decyzje
| # | Decyzja | Wybór |
|---|---|---|
| 1 | Podział uwag | v11 poprawki wyglądu, v12 style mapy, v13 kolor pinezki |
| 2 | Dolne menu | na razie brak – 2 cele nawigacji, puste zakładki wyglądałyby na niedokończone |
| 3 | Mruganie mapy | zasłona do `onStyleLoaded` + `applyMapPalette`, zabezpieczenie: timer 1,5 s (np. brak sieci) |
| 4 | Ikony i kolory folderów | klucze tekstowe → bez migracji; nieznany klucz nadal daje wartość domyślną |
| 5 | Kolory etykiet mapy | zostają ciemne (v8) – jasne z wymuszoną jasną obwódką są nieczytelne |

## Pliki
- `app/lib/features/home/presentation/home_screen.dart`: `_Header(greeting:)`, `AnimatedSwitcher.layoutBuilder` ze `StackFit.expand`, gradient 6 przystanków
- `app/lib/features/home/domain/landscape.dart`: bez `folderCoverAsset`
- `app/lib/features/folders/presentation/folder_form_screen.dart`: `_Preview` bez obrazka, `ListView` poziome (`folder-icons`, `folder-colors`)
- `app/lib/features/folders/domain/trip_folder.dart`, `folder_labels.dart`: nowe ikony i kolory
- `app/lib/features/map/presentation/map_screen.dart`: `_styleReady`, `_curtainFallback`, `_onStyleLoaded`
- `app/lib/features/map/presentation/place_search_field.dart`: `_border()` z promieniem 24
- `app/lib/l10n/app_pl.arb`: teksty, etykiety ikon i kolorów
- Testy: `home_screen_test` (powitanie), `folder_form_screen_test` (podgląd bez obrazka, przewijanie do `ski` i `slate`), `folders_test` (klucze enumów)

## Pułapki
- `AnimatedSwitcher` domyślnie układa dzieci w `Stack` bez rozciągania. `Image` z `BoxFit.cover` miał więc swój naturalny rozmiar (ok. 229 dp) na środku nagłówka. Stąd pusty pas u góry i twarda dolna krawędź, a gradient wypadał poniżej obrazka. Poprawka: `layoutBuilder` ze `StackFit.expand`.
- `InputDecoration(border: InputBorder.none)` nie nadpisuje `enabledBorder` ani `focusedBorder` z motywu. Trzeba je ustawić jawnie.
- Standard zawsze rysuje etykietom **jasną** obwódkę, także przy jasnym tekście (`colorPlaceLabels: #dce5de` na P30 → biały tekst w białej obwódce). Konfiguracji obwódki nie ma – [[Mapbox Flutter]].
- P30 ma gęstość 2,625 (nie 3) – przeliczając zrzuty adb na dp, trzeba to uwzględnić.

## Checklista weryfikacji
- [x] `flutter analyze`: 0 issues
- [x] `flutter test`: 153/153
- [x] P30 przez adb: start – „Cześć!” na pejzażu, łagodne przejście, bez podtytułu
- [x] P30 przez adb: „Nowy folder” – podgląd bez obrazka, przewijane ikony i kolory
- [x] P30 przez adb: wejście na mapę – seria zrzutów bez jasnego Standardu (zasłona schodzi na mapę z paletą)
- [x] P30 przez adb: wyszukiwarka – zaokrąglona zielona ramka
- [ ] Użytkownik: brak mrugania przy wejściu na mapę (zrzuty co ok. 0,5 s mogą przegapić klatkę)
- [ ] Użytkownik: nowe ikony i kolory, zapis folderu
- [ ] Użytkownik: wygląd nagłówka o innych porach dnia

## Poprawki po teście
- **Mapa nadal migała, a przejście nie było płynne** (użytkownik, 2026-11-02). Przyczyna: `MapWidget` domyślnie osadza mapę jako `SurfaceView` w Hybrid Composition. Taka natywna powierzchnia nie bierze udziału w animacji trasy Fluttera: wskakuje od razu w pełnym rozmiarze i może pokazać pustą klatkę, więc zasłona z v11 jej nie maskuje. Poprawka: `textureView: true` + `androidHostingMode: TLHC_HC` (Texture Layer Hybrid Composition). Flutter składa mapę jak zwykły widżet, więc działa animacja i zasłona. API jest `@experimental` → `// ignore: experimental_member_use`.
- [x] P30 przez adb: mapa renderuje się w TLHC, przesuwanie działa
- [ ] Użytkownik: płynność przejścia i brak mignięcia po zmianie TLHC
- Huawei P30 nie ma `screenrecord` – płynności nie da się nagrać przez adb, ocenia użytkownik.

## Otwarte
- **Obwódka napisów** – odłożone przez użytkownika (2026-11-02). Można spróbować `lightPreset: dusk/night` (cała mapa nocna, jasne napisy z ciemną obwódką) albo przejść na własny styl z Mapbox Studio (pełna kontrola `text-halo-color`, ale bez łatwej palety).
- **v12 – style mapy:**
  - jeden przycisk „warstwy” rozwija 4 style: Standard z paletą, Outdoors (bez klikalnych POI), `STANDARD_SATELLITE`, Faded 3D (`theme: faded`, `show3dObjects`, nachylenie ok. 60°);
  - bez zapamiętywania wyboru, wyjście z 3D prostuje kamerę;
  - spike: czy anotacje przetrwają `setStyleURI`.
- **v13 – kolor pinezki:**
  - 24 kolory w siatce 6×4, domyślnie kolor kategorii (`color` = null, „Przywróć domyślny”);
  - wybór w formularzu i w edycji;
  - kolumna w bazie (schemat 6);
  - pinezka rysowana w aplikacji: kształt w kolorze + biały symbol z `render_pins.py`.
- Nowe typy pinezek czekają na grafiki ze Stitcha od użytkownika.

Powiązane: [[00 Jureczek – przegląd]], [[v10 – foldery i ekran startowy]], [[v8 – styl Nocturnal Expedition]], [[Backlog]], [[Mapbox Flutter]]
