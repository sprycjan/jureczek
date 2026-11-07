---
tags: [jureczek, wersja, ekran-powitalny, animacja, svg]
wersja: v24
status: zaimplementowana – działa na telefonie
data: 2026-11-07
---
# v24 – ekran powitalny

Prośba użytkownika z 2026-11-07: zamiast ciemnego tła przy starcie animowany ekran powitalny. Wektorowy kamper z boku jedzie z lewej do prawej przez góry z paralaksą, jak początek ilustrowanej gry przygodowej. Decyzja: [[ADR-016 Ekran powitalny z warstw SVG]].

Praca jest podzielona na przystanki: styl (etap 1), animacja na jednej scenie (etap 2), pozostałe 7 scen (etap 3), dokończenie (etap 4). Ta notatka opisuje stan po etapie 4, czyli wersję skończoną.

## Zakres
- **Fazy:** A wjazd kampera, B jazda z paralaksą, C przyspieszenie i odjazd, a na końcu przenikanie do ekranu startowego.
- **Czas:** minimum 3,5 s, ale bez blokowania startu. Faza C rusza raz, gdy aplikacja jest gotowa i minimum minęło.
- **Gotowość:** pierwszy wynik `foldersProvider` (dane albo błąd) i obraz nagłówka. Limit 10 s.
- **Pory dnia:** 4 palety wg `Landscape.at()`. W nocy świecą okna, przednia szyba, namiot i reflektor, a tylna lampa ma czerwoną poświatę.
- **Natywne tło:** neutralny gradient zmierzchu tylko do pierwszej klatki Fluttera, a ta jest już sceną z ruszającym kamperem. Gradient we Flutterze i 0,4 s przejścia to zapas na scenę spóźnioną ponad limit 1 s.
- **Rysunki:** `tool/splash_art.py` generuje kampera, kamyk, 4 nieba i 8 scen po 7 warstw: Alpy, dolina z turkusowym jeziorem, łąki z krętą drogą, wąwóz z rzeką i wiaduktem, złoty las modrzewiowy, czerwone skały i stoliwa, fiord, wysoka przełęcz z głazami i wodospadem.
- **Zawieszenie:** dwa końce nadwozia na sprężynach, oparte o koła na własnych, sztywniejszych sprężynach. Nadwozie i nadkola się przechylają, a koła i cień zostają na drodze.

## Decyzje
| # | Decyzja | Wybór |
|---|---|---|
| 1 | Użycie `bgs.png` | tylko styl i paleta; własna kompozycja, bez logo i odrysowywania |
| 2 | Wierność kampera | wszystko z `screen.png` (dach, deska, bagaże, lusterko) + kurz spod obu osi; najpierw bez podskoków, potem zawieszenie i kamyki na prośbę użytkownika (decyzja 14) |
| 3 | Zimny start z udostępnienia | bez minimum, faza C od razu po gotowości |
| 4 | Pominięcie stuknięciem | tak; przed gotowością zapamiętane, w fazie C ignorowane, w fazie A kamper rusza z bieżącego miejsca |
| 5 | Zawieszona gotowość | limit 10 s, potem ekran startowy z własnym stanem ładowania |
| 6 | Pierwsza klatka | okno Androida: fiołkowy zmierzch, bo zasób nie zależy od godziny. Flutter: wstrzymana do gotowej sceny, bez zasłony (po uwadze użytkownika) |
| 7 | Wyjście | około 1,1 s: odjazd 0,7 s, przenikanie 0,5 s od 0,6 s; razem około 4,6 s |
| 8 | Różnorodność | 8 krajobrazów, czysty los przy każdym uruchomieniu, bez zapisu (etap 3) |
| 9 | „Usuń animacje” w systemie | nieruchoma scena 3,5 s, potem przenikanie |
| 10 | Napis | brak |
| 11 | Chmury | wspólny kłębiasty kontur z pasami światła; świadome odejście od referencji (brązowe kopuły, grube pasy, drobiny), która w pionowym kadrze wyglądała jak bąble |
| 12 | Góry | różne sylwetki; pierwszy kadr ułożony tak, by w pionie było widać różne kształty, bo dalekie warstwy prawie się nie przesuwają |
| 13 | Rysowanie | same `Picture`, bez rasteryzacji warstw, zob. pomiar niżej |
| 14 | Życie kampera | fizyka zamiast ręcznych klatek: hamowanie na wjeździe siada na przód, przyspieszanie na odjeździe na tył, po zatrzymaniu nadwozie odbija; kamyk unosi kolejno przednie i tylne koło |
| 15 | Kamyki | pierwszy najazd 1,7–2,2 s, kolejne co 3–5 s, różna wielkość; podczas odjazdu bez najazdów, bo kamper zmienia prędkość |
| 16 | Sceny 2–8 | te same klocki co w Alpach, własne okresy warstw i pierwszy kadr ułożony pod pion; kolory pierwszego planu różne tylko tam, gdzie zielony by nie pasował (modrzewie, stoliwa, przełęcz) |
| 17 | Wąwóz | most kończy się za ścianami skalnymi, żeby przy przewijaniu nie było widać urwanego końca |
| 18 | Start od kliknięcia | scena wczytywana od `main()`, pierwsza klatka czeka na nią najwyżej 1 s; minimum 3,5 s i tempo wyjścia bez zmian |

## Pliki
- `tool/splash_art.py`: generator SVG, palet i manifestu. SVG się nie edytuje.
- `assets/splash/`: wyjście generatora (67 SVG, 3,5 MB, 406 tokenów kolorów).
- `lib/features/splash/domain/splash_config.dart`: wszystkie parametry w jednym miejscu.
- `lib/features/splash/domain/splash_gate.dart`: czysta bramka gotowości, jedno wyzwolenie.
- `lib/features/splash/domain/splash_manifest.dart`: opis grafik.
- `lib/features/splash/application/splash_motion.dart`: `SplashFrame`, fazy A/B/C, zawieszenie i kamyki, bez zegara.
- `lib/features/splash/application/splash_start.dart`: scena wczytywana przed `runApp`, wstrzymanie pierwszej klatki i limit.
- `lib/main.dart`: tworzy `SplashStart`, gdy jest token.
- `lib/features/splash/data/splash_art_loader.dart`: `ColorMapper` palety, wczytanie tylko wybranej sceny.
- `lib/features/splash/presentation/splash_scene_painter.dart`: paralaksa, kamper na zawieszeniu, kurz, kamyki.
- `lib/features/splash/presentation/splash_overlay.dart`: nakładka, gotowość, cykl życia.
- `lib/app.dart`: `MaterialApp.builder` z nakładką, parametr `showSplash`.
- `lib/dev/splash_main.dart`: podgląd z pomiarem klatek, poza aplikacją.
- `android/app/src/main/res/drawable*/launch_background.xml`: gradient zmierzchu.
- `pubspec.yaml`: katalogi grafik.
- **Testy:** `test/features/splash/` (bramka, ruch, nakładka, spójność grafik).

## Pomiar na P30
Tryb `--profile`, rysowanie przez Impeller na OpenGLES, 7 warstw na scenie:
- około 60 klatek/s (180 klatek na 3 s), także w nocy;
- build około 2,3 ms; raster p50 15,4 ms, p90 około 16,5 ms, p99 18–24 ms;
- 3–15% klatek przekracza 16,7 ms rastra;
- wczytanie sceny około 140 ms.

Zapas jest mały: **sceny 2–8 nie mogą być cięższe od „Alp”**. Płynności w samej aplikacji nie zmierzyłem osobno, ten sam malarz działał w podglądzie. Pomiar jest sprzed zawieszenia, kurzu spod przedniej osi i kamyków.

Pomiar po etapie 3, ze wszystkimi 8 scenami, zawieszeniem, kurzem i kamykami (podgląd, `--profile`, pora zachodu, okna po około 3 s):
- około 60 klatek/s w każdej scenie, raster p50 13,8–16,0 ms, wczytanie sceny 69–145 ms;
- **pierwsze okno po wczytaniu sceny jest najgorsze:** 8–42 ze 180 klatek ponad 16,7 ms rastra, p99 do około 36 ms; to właśnie okno widać przy starcie, a kolejne mają 1–26 takich klatek;
- budżet: Alpy pozostają najcięższe (1657 ścieżek, 44 933 odcinki). Modrzewie miały 1664 ścieżki i wypadały najsłabiej, więc po przerzedzeniu lasu w warstwie bliskiej mają 1430 ścieżek i 36 574 odcinki;
- modrzewie po przerzedzeniu, próba kontrolna z Alpami przed nimi i po nich: po pierwszym oknie 4–14 klatek ponad 16,7 ms, Alpy 5–21;
- jeden przebieg tego samego dnia dał raster p50 20–27 ms w scenie modrzewi, a czas build wzrósł dwukrotnie. Nie powtórzył się przy kolejnym przebiegu i przyczyny nie ustaliłem; bateria miała wtedy 27–28 °C, ale temperatury nie mierzyłem w trakcie tamtego przebiegu.

Najgorsze pierwsze okno miały łąki, jedna z lżejszych scen, więc koszt prawdopodobnie wynika ze zmiany sceny w podglądzie, a nie z rysunku. Ten pomiar dotyczy podglądu, zimny start zmierzony jest niżej.

Zimny start w prawdziwej aplikacji, z tymczasowym logiem `FrameTiming` usuniętym po pomiarze, pierwsze 4,7 s od pierwszej klatki:
- 14 startów na losowych scenach i 10 z wymuszoną sceną (Alpy, modrzewie); 4 z nich to pierwsze starty po instalacji, opisane osobno;
- pozostałe 20 startów: około 275 klatek, czyli około 58 na sekundę; raster p50 13,6–15,3 ms, a limit 16,7 ms przekracza 5–32 klatek z około 275;
- przerwy ponad 25 ms przypadają na pierwszą sekundę, gdy wczytuje się scena; najdłuższa ma 99 ms. Po pierwszej sekundzie przerw nie ma, wyjątkiem jest jeden start z dwiema (łąki);
- **pierwszy start po instalacji** (4 próby: Alpy trzy razy, modrzewie raz) ma przerwę około 900 ms i około 222 klatek, także w lżejszej scenie, więc wynika z instalacji, a nie z rysunku. Kolejne starty tej samej wersji jej nie mają.

## Pomiar czasu startu na P30
Od `START u0` w logcacie, 6 zimnych startów na build, pierwszy start po instalacji odrzucony. Znaczniki były tymczasowe.

| Moment | `release` przed | `release` po | `profile` po |
|---|---|---|---|
| `main()` | 166–190 ms | 160–203 ms | 625–658 ms |
| Foldery i obraz nagłówka gotowe | 307–399 ms | 300–351 ms | 784–869 ms |
| Pierwsza klatka Fluttera | 256–291 ms, gradient | 337–430 ms, scena | 861–910 ms, scena |
| Scena w pełni widoczna | około 760–840 ms | 337–430 ms | 861–910 ms |
| „Displayed” | 309–336 ms | 358–453 ms | 879–934 ms |

Wiersz „Scena w pełni widoczna” przed zmianą to czas wczytania sceny plus 400 ms przenikania, wyliczony, a nie zmierzony. Sama `profile` przed zmianą: „Displayed” 779–812 ms. Różnicę między `profile` a `release` daje prawie w całości czas do `main()`.

**Aplikacja jest gotowa około 0,35 s po kliknięciu (`release`), więc ekran powitalny nie przykrywa długiego ładowania.** Dalsze około 3,3 s to wybrane minimum. Mapa nie wchodzi w ten czas, bo wczytuje się dopiero po wejściu na nią.

## Pułapki
- `SvgAssetLoader` z `assetBundle: rootBundle` nie przejdzie do izolatu („object is unsendable”), gdy wcześniej ktoś wywołał `rootBundle.loadString`, bo pamięć podręczna trzyma wtedy `Future`. **W `flutter test` tego błędu nie widać**, nawet po `loadString`, więc test nie zastąpi sprawdzenia na telefonie. Bundle podajemy tylko w testach sceny, a `renderPlacePinPng` nie ma już takiego parametru.
- `allowFirstFrame` musi mieć dokładnie jedną parę z `deferFirstFrame`, dlatego wstrzymanie jest w `main()`, a nie w nakładce: testy i `showSplash: false` go nie dotykają.
- Kontynuacja po `await` wykonuje się w teście po klatce, więc pierwszy takt animacji uruchomionej po dostarczeniu sceny przypada na kolejny `pump`.
- Nocna nakładka leży nad całym nadwoziem, więc przykrywa wszystko, co w dzień jest nad szybą. Podziałka i lusterko są wspólnymi elementami i są rysowane w obu wersjach.
- Cień kampera leży na drodze, a nadkola należą do nadwozia, dlatego `camper_under.svg` rozdzielono na cień i nadkola.
- Fizyka liczy się krokiem 1/240 s: sprężyna koła jest sztywna, a krok równy klatce mógłby ją rozhuśtać.
- Przezroczystość na `Picture` wymaga `saveLayer`, dlatego kurz rośnie i maleje do zera zamiast wygasać.
- Nakładka musi być zawsze drugim dzieckiem tego samego `Stack`, inaczej zniknięcie przebudowałoby ekran startowy.
- `AnnotatedRegion` po zniknięciu nie przywraca paska stanu, więc robi to `SystemChrome.setSystemUIOverlayStyle`.
- Rendering Fluttera nie trafia do `gfxinfo`, a Huawei nie ma `screenrecord`. Czasy klatek mierzy `FrameTiming` w podglądzie.
- `flutter run --no-resident ... | tail` potrafi wisieć ponad godzinę i nie zbudować nowej wersji. Pewniej: `flutter build apk --profile`, potem `adb install -r`. Warto sprawdzić, co jest w APK, przez `unzip -p`.
- `pumpAndSettle` wisi przy zapętlonej animacji, dlatego przy pustym tokenie i z `showSplash: false` nakładki nie ma.
- W teście animacja kończy się dopiero po przekroczeniu swojej długości: `pump(500 ms)` przy 500 ms nie wystarczy.
- Tokeny kolorów numeruje kolejność pierwszego użycia, więc nowe kolory na poziomie modułu generatora zmieniają pliki wszystkich scen. Rysunek zostaje ten sam; sprawdzone porównaniem SVG po podstawieniu palety.
- Warstwa daleka musi schodzić poniżej najwyższego punktu wzgórz, inaczej u stóp gór prześwituje niebo. Stąd woda rysowana 90 jednostek poniżej końca gradientu i niższa podstawa gór w stoliwach i na przełęczy.
- Wolna warstwa przesuwa się w lewo, więc to, co leży na lewo od pierwszego kadru, nigdy się nie pokaże. Elementy dla oka trzeba kłaść w kadrze albo na prawo od niego.
- Pierwszy start po instalacji jest o około 900 ms wolniejszy niezależnie od sceny; do pomiaru płynności trzeba go odrzucić.
- Wodospad zaczyna się na `Massif.sky_y(x)`, a nie na stałej wysokości, bo inaczej spada z nieba.

## Checklista weryfikacji
- [x] `flutter analyze`: 0 issues
- [x] `flutter test`: 349/349 (test grafik wymaga teraz dokładnie 8 scen)
- [x] P30 przez adb: natywny gradient, przejście w niebo, wjazd, jazda z paralaksą, odjazd, ekran startowy
- [x] P30 przez adb: stuknięcie po gotowości daje odjazd i przenikanie
- [x] P30 przez adb: zimny start z udostępnienia, mapa z wynikiem po około 1,5 s (bez wcześniejszego zrzutu samej nakładki)
- [x] P30 przez adb: „Usuń animacje” (`animator_duration_scale` 0) daje nieruchomą scenę i przenikanie; ustawienie przywrócone
- [x] P30: 4 palety, tylna lampa, nocna przednia szyba, podziałka i lusterko
- [x] Użytkownik: tempo wyjścia na telefonie
- [x] P30 przez adb: przechył przy hamowaniu na wjeździe, kamyk na linii kół, kurz przy obu osiach (zrzuty; samego podskoku koła zrzuty nie złapały, sprawdzają go testy)
- [x] Użytkownik: kurz, przechył i podskok na kamyku
- [x] Chrome: pierwszy kadr 8 scen w 4 porach (32 kombinacje), kadry po 4,6 s i 10 s jazdy, układ poziomy o zachodzie
- [x] P30 przez adb: każda z 8 scen wczytuje się i jedzie (zrzuty o zachodzie), czasy klatek jak wyżej
- [x] P30 przez adb: zwykła aplikacja po etapie 3, losowa scena, potem ekran startowy
- [x] Użytkownik: arkusz 32 kombinacji przyjęty bez uwag („ok, przechodzimy do etapu 4”)
- [x] P30 przez adb: obrót w trakcie jazdy, także kilkukrotny: ta sama scena, bez restartu, jedno wyjście, kamper w środku kadru. Ustawienia obrotu przywrócone
- [x] Chrome: szew pętli wszystkich 56 warstw, pomiar różnicy kolumn na granicy kafelków i oględziny powiększeń; bez nieciągłości i bez podwójnego rysowania na zakładce. Na P30 sprawdzony na zrzucie w poziomie, gdzie granica kafelków drogi jest w kadrze stale (okres 1240 przy widoku 1400): bez śladu. Dalekich warstw telefon nie przewinął do szwu, bo przy prędkości 5–12 j./s trwałoby to minuty
- [x] P30 przez adb: zimny start z udostępnienia przy 8 scenach, mapa z kartą miejsca około 2,6 s od wysłania linku, bez minimum 3,5 s
- [x] P30: płynność przy zimnym starcie, pomiar wyżej
- [x] Po poprawce startu: `flutter analyze` 0 issues, `flutter test` 356/356
- [x] P30 przez adb, `release`: serią zrzutów gradient tylko w rozwijanym oknie systemu, następny zrzut to już scena z kamperem; zrzuty mają około 0,45 s odstępu, więc pojedynczych klatek nie widać
- [x] P30 przez adb: scena gotowa przed pierwszą klatką we wszystkich 12 mierzonych startach (6 `release`, 6 `profile`)
- [x] P30 przez adb, `release`: mapa z kafelkami i pinezkami; na czystym commicie 0f78d2c błąd izolatu w logu i pusta mapa, po poprawce bez błędu i z pinezkami
- [x] P30 przez adb, `release`: zimny start z udostępnienia kończy się mapą z kartą miejsca
- [ ] Użytkownik: start z ikony na telefonie, czy nadal wygląda jak ekran ładowania
- [ ] P30: płynność pierwszej sekundy po tej zmianie nie była mierzona osobno
- [ ] Ścieżka limitu 1 s na telefonie: nie wystąpiła w pomiarach, sprawdzają ją testy `SplashStart` i przenikania

## Poprawki po teście
- Chmury narysowane od nowa po uwadze „wyglądają jak bąble”.
- Różne sylwetki gór po uwadze „nie muszą być wszystkie spiczaste”.
- Tylne światło na czerwono w nocy (prośba użytkownika).
- Noc: świeci przednia szyba, lusterko nie jest zasłonięte, podziałka szyby kabiny wróciła (uwaga użytkownika).
- Kurz także za przednimi kołami, zawieszenie reagujące na przyspieszanie i hamowanie, kamyki na drodze (prośba użytkownika).
- **Start od kliknięcia:** użytkownik zauważył, że różowy ekran wygląda jak ładowanie, a animacja jak dodatek po nim. Pomiar przyznał mu rację: gotowość przychodziła przed animacją, a Flutter sam rysował różowe klatki i jeszcze 0,4 s zanikania. Teraz scena wczytuje się od `main()`, pierwsza klatka na nią czeka, a zasłony nie ma. Na telefonie był też build `profile`, wolniejszy o około 0,5 s; teraz jest `release`.
- **Regresja v24, pinezki znikały z mapy:** ekran powitalny czyta `manifest.json` i `palettes.json` przez `rootBundle.loadString`, a potem pinezka typu wysyłała `rootBundle` do izolatu. Wyjątek przerywał całą synchronizację, więc mapa była pusta. Sprawdzone na czystym 0f78d2c. Wykryte przy tej poprawce; zapisane pinezki nie były zagrożone.
- Etap 3, własny przegląd arkusza przed pokazaniem: filary mostu i rzeka wisiały w powietrzu, fiord nie miał stromych ścian, pod wodą i u stóp gór prześwitywało niebo, wodospad na przełęczy zaczynał się w powietrzu, chmura zasłaniała słońce na łąkach.

## Otwarte
- Okno Androida nadal ma gradient przez około 0,4 s (`release`), także w animacji rozwijania z ikony. Nie da się w nim losować sceny ani pory dnia; opcja w [[Backlog]].
- Czy minimum 3,5 s zostaje, skoro aplikacja jest gotowa po około 0,35 s: decyzja użytkownika.
- Kosmetyka rysunków w [[Backlog]].
- Skała jest bardziej kanciasta niż na referencji; użytkownik zaakceptował styl z 2026-11-07.
- `resorces/bgs.png` nie jest w repo: to cudza ilustracja, służy tylko jako referencja.

Powiązane: [[00 Jureczek – przegląd]], [[ADR-016 Ekran powitalny z warstw SVG]], [[ADR-011 Biblioteka ikon miejsc w SVG]], [[v10 – foldery i ekran startowy]], [[Backlog]]
