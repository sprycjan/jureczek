---
tags: [jureczek, wersja, mapbox]
wersja: v4
status: zaimplementowana – działa na telefonie
data: 2026-10-26
---
# v4 – wyszukiwarka miejsc

## Zakres
- Przy prawej krawędzi, u góry, jest **kolumna narzędzi** (okrągłe przyciski). Na razie jest w niej tylko lupa.
- Lupa wysuwa w lewo **pole wyszukiwania** z fokusem i klawiaturą. W tym czasie lupa zmienia się w ✕, a ✕ czyści tekst i zwija pole.
- **Podpowiedzi** pojawiają się od 3 znaków, po 300 ms przerwy w pisaniu: maksymalnie 6, nazwa plus adres w drugiej linii, wyniki uprzywilejowane względem środka mapy, po polsku, bez ograniczenia do kraju. W trakcie ładowania widać poprzednie podpowiedzi i cienki pasek postępu.
- Zamiast listy może się pojawić komunikat: „Brak wyników” albo „Nie udało się wyszukać – sprawdź połączenie”.
- Tap w mapę chowa listę i klawiaturę, tekst zostaje (fokus wraca po tapnięciu w pole). Long-tap dalej dodaje pinezkę.
- **Wybór podpowiedzi** zwija pole, kamera przelatuje do miejsca (zoom 15), a w miejscu pojawia się tymczasowy **niebieski znacznik** (kółko z białą obwódką). Na dole wyświetla się karta z nazwą, adresem, przyciskiem „Dodaj pinezkę” i ✕.
- „Dodaj pinezkę” tworzy pinezkę z **nazwą z wyniku** (notatka zostaje pusta), zamyka kartę, usuwa znacznik i pokazuje snackbar „Dodano pinezkę”.
- Tap w istniejącą pinezkę zamyka kartę wyniku i otwiera arkusz pinezki. Przesuwanie i przybliżanie mapy nie zamyka karty.
- Przycisk „Wstecz” w Androidzie najpierw zamyka wyszukiwanie lub kartę, dopiero potem aplikację.
- Klawiatura nie zmienia rozmiaru mapy (`resizeToAvoidBottomInset: false`). Lista podpowiedzi kończy się nad klawiaturą i w razie potrzeby się przewija.

## Decyzje
| # | Decyzja | Wybór |
|---|---|---|
| 1 | API | Mapbox **Search Box** (`/suggest` + `/retrieve`), bo znajduje POI; Geocoding v6 ich nie zwraca |
| 2 | Forma UI | stała kolumna narzędzi z prawej (na razie lupa); prawdziwa wysuwana szuflada dopiero przy większej liczbie narzędzi |
| 3 | Pozycja | prawa góra, pole wysuwa się z lupy w lewo |
| 4 | Podpowiedzi | ≥ 3 znaki, debounce 300 ms, limit 6 |
| 5 | Po wyborze | przelot + tymczasowy znacznik + karta „Dodaj pinezkę” |
| 6 | Dane pinezki | nazwa z wyniku, bez notatki |
| 7 | Zawężanie | `language=pl`, `proximity` = środek kamery, bez `country` (wyjazdy zagraniczne) |
| 8 | Błędy | komunikat w miejscu listy, nie snackbar (klawiatura go zasłania) |
| 9 | Testy | unit (klient, kontroler, `add` z nazwą) + widget (pole) + ręcznie na P30 |

## Pliki
- `app/pubspec.yaml`: `http`, dev: `fake_async`
- `app/lib/features/map/domain/place_suggestion.dart`: `LatLng`, `PlaceSuggestion`, `PlaceResult`
- `app/lib/features/map/data/place_search_client.dart`: `PlaceSearchClient` (REST), `PlaceSearchException`, `placeSearchClientProvider`
- `app/lib/features/map/application/place_search_controller.dart`: `PlaceSearchController` (Notifier: debounce, próg, sesja, odrzucanie spóźnionych odpowiedzi), stany `Idle/Loading/Suggestions/Empty/Error`
- `app/lib/features/map/application/pins_providers.dart`: `add(..., name:)`
- `app/lib/features/map/presentation/map_tools.dart`: `MapTools`, `MapToolButton`
- `app/lib/features/map/presentation/place_search_field.dart`: pole i lista podpowiedzi
- `app/lib/features/map/presentation/search_result_card.dart`: karta wyniku
- `app/lib/features/map/presentation/map_screen.dart`: `Stack` z mapą, narzędziami, polem i kartą, `CircleAnnotationManager` na znacznik, `flyTo`, `TapInteraction.onMap`, `PopScope`
- `app/lib/l10n/app_pl.arb`: `pinAdded`, `searchOpen`, `searchClose`, `searchHint`, `searchError`, `searchNoResults`, `searchAddPin`, `searchResultClose`
- Testy: `place_search_client_test.dart`, `place_search_controller_test.dart`, `place_search_field_test.dart` (nowe), `pins_controller_test.dart` (`add` z nazwą)

## Koszty
Search Box liczy **sesje**: wiele `/suggest` z jednym `session_token` plus `/retrieve`. Sesja kończy się też po 180 s bez `retrieve` albo po 50 zapytaniach `suggest`. Darmowe jest 500 sesji miesięcznie, potem 3 $ za 1000. Sesję zaczynamy od nowa po wyborze wyniku i po zamknięciu pola – szczegóły w [[Mapbox Flutter]].

## Checklista weryfikacji
- [x] `flutter analyze`: 0 issues
- [x] `flutter test`: 47/47
- [x] Telefon: token `pk.` ma dostęp do Search API (HTTP 200, bez zmian w panelu)
- [x] Telefon: lupa → pole z klawiaturą, lupa zmienia się w ✕; „Wawel” → 6 podpowiedzi z adresami
- [x] Telefon: wybór → przelot, niebieskie kółko, karta; „Dodaj pinezkę” → pinezka z nazwą wyniku (sprawdzone w arkuszu i w bazie), snackbar
- [x] Telefon: bez sieci (`svc wifi/data disable`) → „Nie udało się wyszukać – sprawdź połączenie”; po powrocie sieci i zmianie tekstu wyniki wracają
- [x] Telefon: bzdura → „Brak wyników”
- [x] Telefon: tap w mapę chowa listę, tekst zostaje; „Wstecz” najpierw chowa klawiaturę (standard Androida), kolejne zwija pole
- [x] Telefon: long-tap przy otwartej karcie stawia pinezkę, karta zostaje; tap w pinezkę zamyka kartę i usuwa znacznik

## Poprawki po teście na telefonie
- **Token w logach:** `ClientException.toString()` dokleja `uri`, a w nim `access_token`. Teraz do wyjątku trafia tylko `e.message`, a test to sprawdza.
- **Karta zasłaniała logo i atrybucję Mapbox** (licencja wymaga, żeby były widoczne). Karta ma teraz 40 px marginesu od dołu.

## Pułapki
- **Ranking Search Box słabo radzi sobie ze sławnymi miejscami przy oddalonej mapie.** Przy widoku całej Polski (`proximity` ≈ Łódź) „Wawel” daje Wąwelno, sklep „Wawel” w Łodzi i Wawel w Grenadzie, a „Sukiennice” dają Brzeg. Bez `proximity` Mapbox bierze lokalizację z IP (Gdańsk), co nie jest lepsze. Przy mapie przybliżonej na Kraków „Wawel” jest wysoko. „Krakow Wawel” zwraca głównie hotele i apartamenty. To cecha danych i rankingu Mapbox, a nie błąd w kodzie. **Decyzja (2026-10-26):** na razie zostawiamy, bez płatnych API. Pomysły w [[Backlog]].

Powiązane: [[00 Jureczek – przegląd]], [[v3 – nazwa i notatka]], [[Mapbox Flutter]]
