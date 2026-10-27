---
tags: [jureczek, wersja]
wersja: v2
status: zaimplementowana – działa na telefonie
data: 2026-10-25
---
# v2 – trwałe pinezki i usuwanie

## Zakres
- Pinezki zapisują się w lokalnej bazie SQLite (drift) i przeżywają restart aplikacji – [[ADR-005 Drift jako baza lokalna]].
- **Tapnięcie w pinezkę** otwiera dolny arkusz: „Miejsce”, współrzędne (4 miejsca po przecinku), „Dodano 25 paź 2026”, czerwony przycisk „Usuń”.
- „Usuń” usuwa od razu i pokazuje snackbar „Usunięto pinezkę · Cofnij” na 4 s. „Cofnij” przywraca pinezkę z tym samym id i datą.
- Błąd odczytu lub zapisu bazy kończy się snackbarem i `debugPrint`.

Poza zakresem (→ [[Backlog]]): nazwa i notatka, przeciąganie, kategorie, pozycja kamery.

## Decyzje
| # | Decyzja | Wybór |
|---|---|---|
| 1 | Zakres | tylko trwałość + usuwanie |
| 2 | Zapis | drift (SQLite) – [[ADR-005 Drift jako baza lokalna]] |
| 3 | Gest usuwania | tap → bottom sheet z „Usuń” |
| 4 | Ochrona przed pomyłką | snackbar „Cofnij” (4 s, potwierdzone po testach), bez dialogu |
| 5 | Git | nadal brak (GitLab niepostawiony) |
| 6 | Dokumentacja | zawsze aktualizować vault |
| 7 | Źródło prawdy | baza: `StreamProvider` nad `watchAll()`, akcje w `PinsController` |
| 8 | Id | UUID v4 (`uuid`) |
| 9 | Pola | `id`, `lat`, `lng`, `createdAt` |
| 10 | Arkusz | tytuł, współrzędne, data, „Usuń” |
| 11 | Start / błędy | mapa od razu, pinezki ze strumienia; błąd → snackbar |
| 12 | Testy | repo + kontroler na bazie in-memory, widget test arkusza, ręcznie na telefonie |
| 13 | Long-tap na pinezce | ignorować (bez dubla) |

## Zależności (dodane)
`drift` 2.34.4, `drift_flutter` 0.3.1, `uuid` 4.6.0; dev: `drift_dev` 2.34.0, `build_runner` 2.15.1.

## Pliki
- `app/lib/core/database/app_database.dart` (+ `.g.dart`): `AppDatabase`, `appDatabaseProvider`
- `app/lib/features/map/data/pins_table.dart`: tabela `Pins` (wiersz `PinRow`)
- `app/lib/features/map/data/pins_repository.dart`: `PinsRepository` (`watchAll`, `findById`, `insert`, `delete`), `pinsRepositoryProvider`
- `app/lib/features/map/application/pins_providers.dart`: `pinsProvider` (StreamProvider), `PinsController`, `pinsControllerProvider` (zastąpił `pins_notifier.dart`)
- `app/lib/features/map/domain/place_pin.dart`: dodane `createdAt`
- `app/lib/features/map/presentation/map_screen.dart`: diff pinezek (`_syncPins`), `tapEvents`, usuwanie i cofanie
- `app/lib/features/map/presentation/pin_details_sheet.dart`: arkusz
- `app/lib/l10n/app_pl.arb`: nowe teksty
- `app/test/features/map/`: `pins_repository_test`, `pins_controller_test`, `pin_details_sheet_test`

## Pułapki napotkane przy implementacji
- **SnackBar z akcją domyślnie nie znika** w Flutter 3.41 (`persist = action != null`). Trzeba ustawić `persist: false` i `duration`.
- **Riverpod 3 wstrzymuje providery bez słuchaczy**, więc w testach `read(pinsProvider.future)` wisiał. Rozwiązanie: `container.listen` + `pumpEventQueue()` ([[Środowisko dev]]).
- `npx` (Context7) nie działa z PATH, więc docs drifta pobrałem przez HTTP API.
- Test widgetu z `locale: pl` wymaga `GlobalMaterialLocalizations.delegates` (liczba mnoga, razem z Cupertino).

## Checklista weryfikacji
- [x] `dart run build_runner build` i `flutter gen-l10n` bez błędów
- [x] `flutter analyze`: 0 issues
- [x] `flutter test`: 15/15
- [x] Telefon (Huawei P30): 3 pinezki przeżywają force-stop i ponowne uruchomienie
- [x] Telefon: tapnięcie otwiera arkusz z właściwymi współrzędnymi i datą, bez nowej pinezki
- [x] Telefon: „Usuń” zdejmuje pinezkę z mapy, „Cofnij” przywraca ją w tym samym miejscu
- [x] Telefon: usunięcie bez cofania przetrwa restart
- [x] Telefon: długie przytrzymanie na istniejącej pinezce nic nie robi, a na pustej mapie nadal stawia pinezkę

## Long-tap na pinezce (decyzja 13: ignorować)
Pierwsza wersja stawiała dubel zaraz nad pinezką, bo palec trafia w „łezkę”, a nie w czubek. Poprawka w `_onMapCreated`:
```dart
map.addInteraction(LongTapInteraction(
  FeaturesetDescriptor(layerId: manager.id), // id managera = id warstwy annotacji
  (_, _) {},
  stopPropagation: true,                     // nie dociera do LongTapInteraction.onMap
));
```
Na telefonie interakcja na warstwie ma pierwszeństwo przed `onMap`. Kolejność nie była opisana w dokumentacji, więc ustaliłem ją testem.

## Otwarte
Brak. Czas snackbara „Cofnij” (4 s) zaakceptowany przez właściciela.

Powiązane: [[00 Jureczek – przegląd]], [[v1 – mapa i pinezki]]
