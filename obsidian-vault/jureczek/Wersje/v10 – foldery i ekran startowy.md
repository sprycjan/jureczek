---
tags: [jureczek, wersja, foldery, drift, ui]
wersja: v10
status: zaimplementowana – sprawdzona przez adb, czeka na potwierdzenie użytkownika
data: 2026-11-01
---
# v10 – foldery i ekran startowy

## Zakres
- **Foldery pinezek** – podróż albo wspólny mianownik („Portugalia”, „Ciekawe miejsca”). Każda pinezka należy do dokładnie jednego folderu – [[ADR-007 Foldery pinezek]].
- **Ekran startowy** zamiast mapy:
  - pejzaż Alp według pory dnia (świt 5–8, dzień 8–18, zachód 18–21, noc), płynne przejście;
  - „Cześć Podróżniku!”;
  - przycisk „Mapa – wszystkie pinezki” i przycisk nowego folderu;
  - karty folderów (ikona w kolorze akcentu, nazwa, opis, „N miejsc”, ⋮ → „Edytuj”), od ostatnio zmienionego;
  - bez folderów zachęta „Utwórz pierwszy folder”.
- **Ekran „Nowy folder / Edytuj folder”** (makieta `resorces/nowa_lista.png`):
  - podgląd na żywo z nocną okładką;
  - nazwa* (45 znaków), opis (120), 7 ikon, 5 kolorów;
  - X, „Anuluj / Utwórz” (w edycji „Zapisz”);
  - duży „Utwórz folder i dodaj pierwsze pinezki” tylko przy tworzeniu – otwiera mapę folderu.
- **Mapa w folderze:** tylko jego pinezki, chip „← ikona + nazwa” w lewym górnym rogu, nowe pinezki trafiają do niego (formularz bez wyboru folderu).
- **Mapa wszystkich pinezek:**
  - chip „← Wszystkie pinezki”;
  - formularz z wyborem folderu: domyślnie „Pinezki”, tworzony leniwie przy pierwszym zapisie;
  - „+ Nowy folder” otwiera dialog z samą nazwą.
- W edycji pinezki można przenieść ją do innego folderu.
- Udostępnienie z Google Maps zawsze otwiera mapę wszystkich pinezek (z każdego miejsca aplikacji).
- Folderów się nie usuwa (tylko edycja; „Pinezki” też).

## Decyzje
| # | Decyzja | Wybór |
|---|---|---|
| 1 | Przynależność | obowiązkowa, jeden folder na pinezkę |
| 2 | „Pinezki” vs zachęta | „Pinezki” powstaje leniwie (zapis bez innego wyboru albo migracja z pinezkami) → zachęta widoczna, dopóki nie ma folderów |
| 3 | Usuwanie folderów | brak |
| 4 | Kolejność | `updated_at_ms` malejąco; odświeża edycja folderu, dodanie/edycja/przeniesienie pinezki (docelowy folder +1 ms, żeby był wyżej) |
| 5 | `updatedAt` | `IntColumn` w ms, bo `dateTime()` drifta ma dokładność do sekundy (remisy) |
| 6 | Kolory akcentu | szmaragd `#85d7a9`, bursztyn `#ffb876`, lodowy `#9ecedf`, wrzos `#CE93D8`, malina `#F48FB1` (makieta miała dubel `#ffb876`) |
| 7 | Ikony | Material: `rv_hookup`, `terrain`, `beach_access`, `festival` (brak `camping` we Flutterze), `hiking`, `local_cafe`, `explore` |
| 8 | Obrazki | pobrane z googleusercontent w pełnej rozdzielczości (`=s0`, 1376×768), przycięte z ramek, w `app/assets/landscapes/` |
| 9 | Brak tokenu Mapbox | `MissingTokenView` od razu zamiast ekranu startowego |
| 10 | Chip „Wszystkie pinezki” | też w trybie wszystkich pinezek (powrót do startu) – poza planem, dla spójności |

## Pliki
- `app/lib/features/folders/`: `data/folders_table.dart`, `data/folders_repository.dart` (lista z `pin_count`), `domain/trip_folder.dart` (`TripFolder`, `FolderIcon`, `FolderColor`), `application/folders_providers.dart` (`foldersProvider`, `FoldersController.create/update/ensureDefault`), `presentation/folder_form_screen.dart`, `folder_picker.dart`, `folder_badge.dart`, `folder_labels.dart`
- `app/lib/features/home/`: `domain/landscape.dart`, `presentation/home_screen.dart`
- `app/lib/core/database/app_database.dart`: schemat 5, `_addFolders` (createTable + „Pinezki” gdy są pinezki + `alterTable` z `folder_id`)
- `app/lib/features/map/`: `folderId` w `PlacePin`, `pins_table.dart`, repozytorium (transakcje + podbijanie folderu), kontroler; `map_screen.dart` (`folderId`, filtr, `_MapModeChip`, udostępnienia przez `listenManual` tylko w trybie wszystkich); `new_pin_sheet.dart` (`chooseFolder`), `pin_details_sheet.dart` (`canMoveFolder`)
- `app/lib/app.dart` (`HomeScreen`), `app/lib/core/theme/app_theme.dart` (`chipTheme`), `app/lib/l10n/app_pl.arb`, `app/pubspec.yaml` (`assets/landscapes/`)
- Testy: `test/features/folders/{folders,folder_form_screen,folder_picker}_test.dart`, `test/features/home/{home_screen,landscape}_test.dart`, migracja 4 → 5 (z pinezkami i bez)

## Pułapki
- `dateTime()` w drifcie = sekundy → do sortowania po „ostatniej zmianie” trzymać ms w `IntColumn`.
- `NOT NULL` kolumny nie da się dodać `addColumn` bez domyślnej wartości → `m.alterTable(TableMigration(..., newColumns:, columnTransformer:))`.
- Testy widżetów z drift: strumienie dochodzą poza fake async → `tester.runAsync(() => Future.delayed(50 ms))` + `pump`; tap tuż po `scrollUntilVisible` tylko zatrzymuje listę → najpierw `pumpAndSettle`; `scrollUntilVisible` przy kilku `Scrollable` (TextField) wymaga `scrollable:`.
- Debug build na P30 startuje ~20–30 s po instalacji; tapnięcia adb wcześniej giną.

## Checklista weryfikacji
- [x] `flutter analyze`: 0 issues
- [x] `flutter test`: 150/150
- [x] P30 przez adb: migracja 4 → 5 na podstawionej bazie (pinezka → „Pinezki”, karta „1 miejsce”)
- [x] P30 przez adb: ekran startowy (nocny pejzaż o 21:29), zachęta przy pustej bazie
- [x] P30 przez adb: folder → mapa z chipem, long-tap → formularz bez wyboru folderu → zapis → „2 miejsca”
- [x] P30 przez adb: „Nowy folder” → Portugalia, plaża, bursztyn → duży przycisk → mapa folderu; lista: Portugalia nad Pinezki
- [x] P30 przez adb: mapa wszystkich → long-tap → wybór folderu z „Pinezki” zaznaczonym
- [ ] Użytkownik: udostępnienie z Google Maps z ekranu startowego i z folderu
- [ ] Użytkownik: przeniesienie pinezki do innego folderu w edycji, „+ Nowy folder” z formularza
- [ ] Użytkownik: pejzaże o innych porach dnia

## Poprawki po teście
- **Kamera po otwarciu mapy obejmuje pinezki** (zgłoszenie użytkownika z 2026-11-02: mapa folderu „Portugalia” zawsze startowała nad Polską). `_placeCamera` w `map_screen.dart` działa raz, gdy gotowe są mapa, obrazki pinezek i pierwsza lista z bazy. Liczy kamerę przez `map.cameraForCoordinatesPadding(punkty, CameraOptions(), padding, maxZoom 12, null)` i ustawia ją `setCamera`, bez animacji.
  - Padding: u góry pasek statusu + narzędzia + wysokość pinezki (pinezka stoi czubkiem na punkcie), po bokach 48 dp, na dole 48 dp + dolny inset.
  - `maxZoom 12`: jedna pinezka pokazuje się z okolicą (miasteczko i sąsiednie wsie), a nie ulicę.
  - Działa też na mapie wszystkich pinezek. Przy pustym folderze albo przy udostępnieniu (wynik leci do miejsca) zostaje widok Polski.
  - Zasłona w kolorze tła schodzi dopiero po wczytaniu stylu **i** ustawieniu kamery, dzięki czemu Polska nie miga przed przeskokiem. Awaryjny timer 1,5 s zostaje.
- [x] `flutter analyze`: 0 issues, `flutter test`: 153/153
- [x] P30 przez adb: „Portugalia” (1 pinezka) → mapa wyśrodkowana na Sernancelhe, zoom 12
- [x] P30 przez adb: „Pinezki” (5) → wszystkie widoczne, od Konina do Bochni, z marginesem od narzędzi
- [ ] Użytkownik: wejście w folder bez mignięcia Polski

## Otwarte
- Pinezka postawiona w teście v9 zniknęła przy instalacji v10 (baza miała schemat 5, zero pinezek, brak błędów w logach). Migracja 4 → 5 sprawdzona osobno – działa. Podobne zniknięcie było 2026-10-26 – [[Backlog]].
- Snackbar „Dodano pinezkę” zostaje widoczny po powrocie na ekran startowy (wspólny `ScaffoldMessenger`).

Powiązane: [[00 Jureczek – przegląd]], [[ADR-007 Foldery pinezek]], [[v9 – kategorie pinezek]], [[v8 – styl Nocturnal Expedition]], [[ADR-005 Drift jako baza lokalna]]
